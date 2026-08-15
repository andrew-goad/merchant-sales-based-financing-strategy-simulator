/***************************************************************************************************
M2.12 PROGRAM 221 HF6 — CONTROLLED LIVE-EXECUTION HOTFIX

SUPERSESSION
This source supersedes Program 221 HF5 SHA-256
42b059a8e68a2243115377cd3839bdd1fb73d84233f9a848267cba96a4dbb933.
Do not rerun Program 220. Do not execute the original Program 221 or HF5.

HF5 RUNTIME FINDING
The source-graph helper treated the complete JSON text in the accepted M1.3 gate observed_value as
though it were the 32-character application hash. The accepted M1.3 finalizer stores that hash in the
JSON field application_set_hash. Consequently Edge 5 could not equal its frozen expected hash even
though accepted persistent state was correct.

CUMULATIVE HF6 CORRECTIONS
1. Retain the exact G3 gate scope introduced by HF5.
2. Retain HF5 accepted physical component-registry mappings.
3. Retain HF5 M1.17 bundle-status mappings.
4. Retain HF5 independent node component/edge aggregation.
5. Retain same-session result exportability through COMMIT.
6. Extract M1.3 application_set_hash from accepted gate JSON for Source Edge 5.
7. Bind all 72 ordinary registry observations to exact governed contract/bundle code and version.
8. Verify the target-recorded auxiliary gate identities for M1.3→M2.2 and M1.6→M2.5.
9. Emit complete edge-level diagnostics if any of the 19 source edges fail.
10. Fail closed unless the frozen 48-row result collection is exactly 48 PASS / 0 FAIL.

BOUNDARY
Program 221 remains persistent-state read-only. Only transaction-local temporary objects are created.
This file has received physical/static validation but has not been PostgreSQL-executed here.

COMMENT PRECEDENCE
The original R10 construction header retained below is historical traceability. This HF6 supersession
notice and the external controlled-execution authority govern the next attempt.
***************************************************************************************************/
/***************************************************************************************************
M2.12 — ENTERPRISE PORTFOLIO CERTIFICATION & CONSUMPTION CONTRACT
PROGRAM 221 — Accepted-Source and Pristine-Target Preflight

WORK PACKAGE
M2.12 Work Package 2 — SQL Source Construction R1

PROGRAM CLASS
NORMAL

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
/* R10 GOVERNED STATEMENT 0001 OF 0076
   statement_code: BEGIN
   phase_code: 00_TRANSACTION
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
BEGIN;

/* R10 GOVERNED STATEMENT 0002 OF 0076
   statement_code: SEARCH_PATH
   phase_code: 00_TRANSACTION
   statement_type: SESSION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
SET LOCAL search_path = msbf_ctl, msbf_m2, msbf_ref, public;

/* R10 GOVERNED STATEMENT 0003 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_CAPABILITY_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_capability_design ON COMMIT DROP AS
SELECT * FROM (VALUES
    (1::smallint,'M1_G2_APPLICATION_RISK_FOUNDATION'::text,'IMPLEMENTED_CERTIFIED'::text,'M1_17_G2_FOUNDATION'::text,'Accepted application, risk, economics, acquisition, evidence, and scenario foundation.'::text,false::boolean,false::boolean,'Module 2 source boundary'::text),
    (2::smallint,'ELIGIBILITY_POLICY_ROUTING'::text,'IMPLEMENTED_CERTIFIED'::text,'M2_1_ELIGIBILITY_ROUTING'::text,'Governed eligibility gates, policy results, reasons, and routing outcomes.'::text,false::boolean,false::boolean,'As-built accepted scope'::text),
    (3::smallint,'PRICING_STRUCTURE_COUNTEROFFER'::text,'IMPLEMENTED_CERTIFIED'::text,'M2_2_PRICING_STRUCTURE'::text,'Accepted request structures, finite pricing candidates, counteroffer foundations, and scenario results.'::text,false::boolean,false::boolean,'As-built accepted scope'::text),
    (4::smallint,'FINAL_OFFER_DECISION_AUTHORIZATION'::text,'IMPLEMENTED_CERTIFIED_SYNTHETIC'::text,'M2_3_FINAL_DECISION'::text,'Synthetic final offer and decision authorization evidence only.'::text,false::boolean,false::boolean,'Not a production credit decision'::text),
    (5::smallint,'BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_4_PORTFOLIO_ACTIVATION'::text,'Synthetic booking, funding, account, advance, and portfolio activation records.'::text,false::boolean,false::boolean,'No real booking or funds movement'::text),
    (6::smallint,'DAILY_REMITTANCE_EXPOSURE_MONITORING'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_5_DAILY_MONITORING'::text,'Synthetic daily remittance, exposure, monitoring, alert, and portfolio summaries.'::text,false::boolean,false::boolean,'No production ledger or processor execution'::text),
    (7::smallint,'EARLY_WARNING_INTERVENTION_SERVICING'::text,'IMPLEMENTED_BOUNDED_RECOMMENDATION'::text,'M2_6_INTERVENTION_STRATEGY'::text,'Synthetic early-warning and servicing-action recommendations.'::text,false::boolean,false::boolean,'Recommendation evidence only'::text),
    (8::smallint,'OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_7_OPERATIONAL_ACTIVATION'::text,'Synthetic operational account setup and reassessment evidence.'::text,false::boolean,false::boolean,'No external system update'::text),
    (9::smallint,'SERVICING_PAYMENT_LIFECYCLE_SIMULATION'::text,'IMPLEMENTED_BOUNDED_SYNTHETIC'::text,'M2_8_SERVICING_EXECUTION'::text,'Synthetic payment-processing events and lifecycle transitions.'::text,false::boolean,false::boolean,'No payment-network or bank-account activity'::text),
    (10::smallint,'PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION'::text,'IMPLEMENTED_CERTIFIED_SYNTHETIC'::text,'M2_9_RECONCILIATION_CERTIFICATION'::text,'Reconciled synthetic payment evidence and certified synthetic account states.'::text,false::boolean,false::boolean,'Not production accounting certification'::text),
    (11::smallint,'PORTFOLIO_KPI_SERVICING_ANALYTICS'::text,'IMPLEMENTED_CERTIFIED_ANALYTICS'::text,'M2_10_PORTFOLIO_ANALYTICS'::text,'Governed KPI, performance-tier, servicing-queue, exposure, payment, and exception analytics.'::text,false::boolean,false::boolean,'Synthetic analytics only'::text),
    (12::smallint,'PORTFOLIO_STRATEGY_FRONTIER'::text,'IMPLEMENTED_CERTIFIED_COMPARATIVE'::text,'M2_11_STRATEGY_SIMULATION'::text,'Finite deterministic strategy comparison, Pareto frontier, and governance-review priority evidence.'::text,false::boolean,false::boolean,'Not a champion or deployment decision'::text),
    (13::smallint,'COLLATERAL_GUARANTEE_PACKAGE'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'NONE'::text,'Original charter capability not implemented in the accepted M2.1-M2.11 chain.'::text,false::boolean,false::boolean,'Requires separate future design and data'::text),
    (14::smallint,'COVENANT_PACKAGE_AND_TESTING'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'NONE'::text,'Original charter capability not implemented as a governed covenant package or test framework.'::text,false::boolean,false::boolean,'Requires separate future lifecycle design'::text),
    (15::smallint,'REGULATORY_APPLICABILITY_LEGAL_COMPLIANCE'::text,'DEFERRED_NOT_CERTIFIED'::text,'NONE'::text,'No jurisdiction, licensing, disclosure, legal-form, UDAAP, fair-lending, or regulatory applicability certification.'::text,false::boolean,false::boolean,'Legal/compliance review required before production'::text),
    (16::smallint,'PORTFOLIO_FUNDING_BUDGET_ALLOCATION'::text,'DEFERRED_NOT_IMPLEMENTED'::text,'NONE'::text,'No production funding-budget, capital-allocation, or concentration-allocation engine.'::text,false::boolean,false::boolean,'Strategy exposure comparisons are not allocation authority'::text),
    (17::smallint,'PRODUCTION_DECISION_ACCOUNT_PAYMENT_EXECUTION'::text,'PROHIBITED_NOT_AUTHORIZED'::text,'NONE'::text,'No production decision, account creation, payment instruction, processor call, or funds movement.'::text,false::boolean,false::boolean,'Production execution expressly prohibited'::text),
    (18::smallint,'ACCOUNTING_CECL_CAPITAL_TREASURY'::text,'DEFERRED_NOT_CERTIFIED'::text,'NONE'::text,'No GAAP accounting, CECL reserve, economic capital, regulatory capital, or treasury certification.'::text,false::boolean,false::boolean,'Comparative expected loss and contribution are synthetic'::text),
    (19::smallint,'EMPIRICAL_CAUSAL_OPTIMIZATION_CHAMPION'::text,'NOT_SUPPORTED_NOT_AUTHORIZED'::text,'NONE'::text,'No causal uplift, calibrated treatment effect, autonomous optimization, production champion, or statistical generalization.'::text,false::boolean,false::boolean,'M2.11 priority is governance review only'::text),
    (20::smallint,'CUSTOMER_MERCHANT_NOTICE_ADVERSE_ACTION'::text,'PROHIBITED_NOT_AUTHORIZED'::text,'NONE'::text,'No merchant-facing offer, notice, adverse-action communication, collection notice, or legal communication.'::text,false::boolean,false::boolean,'Synthetic reason evidence is not customer communication'::text)) v(capability_sequence,capability_code,coverage_status_code,certifying_stage_code,claim_boundary,production_action_authorized_flag,legal_or_regulatory_certified_flag,notes);

/* R10 GOVERNED STATEMENT 0004 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_CAPABILITY_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_capability_design$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_capability_design) <> 20 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_capability_design', DETAIL='expected=20 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_capability_design)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_capability_design$;

/* R10 GOVERNED STATEMENT 0005 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_CAPABILITY_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_capability_design_a2849f2e ON tmp_preflight_m2_12_capability_design (capability_sequence);

/* R10 GOVERNED STATEMENT 0006 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_CAPABILITY_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_capability_design;

/* R10 GOVERNED STATEMENT 0007 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_COMPONENT_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_component_design ON COMMIT DROP AS
SELECT * FROM (VALUES
    (1::smallint,'M1_17_G2_FOUNDATION'::text,1::smallint,'M1_G2_CONSUMPTION_BUNDLE'::text,1::integer,'M1_G2_BUNDLE_SCHEMA_V1'::text,'M1_17_METHOD_V1'::text,'G2_M1_CONTRACT'::text,1::bigint,1::bigint,'d9cdb8309efdcc892f0a0c51b3d5fe94'::text,'7d9e466da28cad2551aa99c4c40c912b'::text,'27397e724a7d24a84601d5052f1b0c34'::text,'64250f8d027ad78650a1bf5ede7da6e5'::text,'020a5946318d6d73da58f723349ab18c'::text),
    (2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,2::smallint,'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text,1::integer,'M2_1_ROUTING_SCHEMA_V1'::text,'M2_1_METHOD_V1'::text,'M2_1_ELIGIBILITY_POLICY_ROUTING'::text,1500::bigint,1500::bigint,'5ce0574b6e27c4b94b8e65997b40f805'::text,'e5ace7f32060ffb191c7bd0f8dd0c863'::text,'e3fe1ae397c76da8f6ba88649935cfa7'::text,'f813d2d8bfa4609f83b2bfd181de3e17'::text,'13d7db24aa254d8efe69b28998d91fd4'::text),
    (3::smallint,'M2_2_PRICING_STRUCTURE'::text,3::smallint,'M2_REQUEST_STRUCTURE_CONSUMPTION'::text,1::integer,'M2_2_REQUEST_STRUCTURE_SCHEMA_V1'::text,'M2_2_METHOD_V1'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,750::bigint,750::bigint,'89d21438326f33a6df82ee667590497b'::text,'bbe83b187b31ea561789797322031fc6'::text,'32374a67d0f8ead18af4bc18139ffdd6'::text,'da27dcb509a8c0bf3bc7a046242a2c02'::text,'c397c86ab234243dc11ab84b9e98eb6f'::text),
    (3::smallint,'M2_2_PRICING_STRUCTURE'::text,4::smallint,'M2_PRICING_STRUCTURE_CONSUMPTION'::text,1::integer,'M2_2_PRICING_STRUCTURE_SCHEMA_V1'::text,'M2_2_METHOD_V1'::text,'M2_2_PRICING_STRUCTURE_COUNTEROFFER'::text,1500::bigint,1500::bigint,'e2d8c2eeaddbb1a8f7d2baa10b4cdbd3'::text,'bbe83b187b31ea561789797322031fc6'::text,'32374a67d0f8ead18af4bc18139ffdd6'::text,'a69d1fca447bb573040bf697c43ce1af'::text,'9e43326cd8f79b98c19f02f971fb077f'::text),
    (4::smallint,'M2_3_FINAL_DECISION'::text,5::smallint,'M2_FINAL_OFFER_DECISION_CONSUMPTION'::text,1::integer,'M2_3_FINAL_DECISION_SCHEMA_V1'::text,'M2_3_METHOD_V1'::text,'M2_3_FINAL_OFFER_DECISION_AUTHORIZATION'::text,1500::bigint,1500::bigint,'cbe8c4a4e5d5e4d6d084ce812a64eb84'::text,'bf09349b06ede7e5a2ec830c2f9ffe90'::text,'03ef3d5ffa4c49d982b3877c4002de2d'::text,'8f421bd27d52e18770cee8fb8a72edf1'::text,'06331f681706a5b9922865ccbe900755'::text),
    (5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,6::smallint,'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text,1::integer,'M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1'::text,'M2_4_METHOD_V1'::text,'M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION'::text,1500::bigint,1500::bigint,'fba075bfd6b24e07dc669d6ce25010f1'::text,'117450a3eea7bb3d3c74d18cc3c8e96a'::text,'879e04636699b51113638ec81d76667b'::text,'f26248c112635ebe5254d614f42332d6'::text,'bf72bbed8c76db3ecdc6936e78718e04'::text),
    (6::smallint,'M2_5_DAILY_MONITORING'::text,7::smallint,'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text,1::integer,'M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1'::text,'M2_5_METHOD_V1'::text,'M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING'::text,59::bigint,59::bigint,'decdc18973edb5f29d2e55ca8a139457'::text,'18e1c444aa1b02ee5bd3539d7c477adc'::text,'c50efd2f8ec5bf10216e5da889ff403d'::text,'ddb680b9f00e88483099d90e781337eb'::text,'c8c22762d49bbd58cf89bae187eaac9f'::text),
    (7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,8::smallint,'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text,1::integer,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_SCHEMA_V1'::text,'M2_6_METHOD_V1'::text,'M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY'::text,59::bigint,59::bigint,'5e5c05dbe9d334cd64d4c6c178a7bacf'::text,'868125bff29270490cab4d2e55cb1388'::text,'4f145d5248bbc6ed5c45b172afa4d342'::text,'f3c42642b2a22b68ff2130d7b065afcd'::text,'72f26807f4d65fa6f813502df9dde3f0'::text),
    (8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,9::smallint,'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text,1::integer,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_SCHEMA_V1'::text,'M2_7_METHOD_V1'::text,'M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP'::text,59::bigint,59::bigint,'c74d986057de7b01d95d0b92bc820d8c'::text,'c8e3a472afd2a16b1183677324e9db98'::text,'8b210c34bdb12f8fb71638b48b374c14'::text,'e1fa837647489de56d66222447420549'::text,'9980f9ff49ca53790ec9af8c6988d44a'::text),
    (9::smallint,'M2_8_SERVICING_EXECUTION'::text,10::smallint,'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text,1::integer,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_SCHEMA_V1'::text,'M2_8_METHOD_V1'::text,'M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL'::text,59::bigint,59::bigint,'37bd013240b1cd6a5db49a271c0c8cec'::text,'ab32d80ba20c2c8f0a6ec9ec97c2ed26'::text,'03b6c0ca3af4ab9d196e09cefa59be3d'::text,'9716224077ff6b7468c0b7b2fed6ab73'::text,'ea3a63d0bd9069cb5c061d09750d8d32'::text),
    (10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,11::smallint,'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text,1::integer,'M2_9_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_SCHEMA_V1'::text,'M2_9_METHOD_V1'::text,'M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION'::text,59::bigint,59::bigint,'5976e2e037a53aa184d29b7bcfeaf09e'::text,'6af76d0059b47623619ebc09330b15fe'::text,'6df16ccd5d6d7f7bffbc0ca4a2539140'::text,'e1206bb355dac10fa8d97a81637ce965'::text,'0bbe110652afd2a01378d36c596e4379'::text),
    (11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,12::smallint,'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text,1::integer,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1'::text,'M2_10_METHOD_V1'::text,'M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS'::text,59::bigint,59::bigint,'98771133c07f0bdb9828cf233f32ad2f'::text,'24fca7263a04397ebf21d30639f9069b'::text,'944d8f676a5b7fb58700b2a66309f428'::text,'c34f6721bd7a6818d2492d564611ef2a'::text,'105691ceca00acc516296b19a64a1c25'::text),
    (12::smallint,'M2_11_STRATEGY_SIMULATION'::text,13::smallint,'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text,1::integer,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1'::text,'M2_11_METHOD_V1'::text,'M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION'::text,24::bigint,24::bigint,'19f1a9d842c9cb35617ca03e49445aad'::text,'a67d375b9f9248b3eec8160cf3dc656d'::text,'61c22f4f3f2e99905d05958fddf80671'::text,'634a9894d0241505582e0d89e4c5f27b'::text,'641deff3b776faa419cc6c0489f85024'::text)) v(certification_node_sequence,stage_code,component_sequence,component_contract_code,contract_version,schema_version,methodology_version,acceptance_gate_id,expected_latest_rows,expected_archive_rows,expected_contract_set_hash,expected_stage_combined_set_hash,expected_registry_row_hash,expected_latest_set_hash,expected_archive_set_hash);

/* R10 GOVERNED STATEMENT 0008 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_COMPONENT_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_component_design$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_component_design) <> 13 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_component_design', DETAIL='expected=13 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_component_design)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_component_design$;

/* R10 GOVERNED STATEMENT 0009 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_COMPONENT_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_component_design_cd26f8fd ON tmp_preflight_m2_12_component_design (component_sequence);

/* R10 GOVERNED STATEMENT 0010 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_COMPONENT_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_component_design;

/* R10 GOVERNED STATEMENT 0011 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_EVIDENCE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_evidence_design ON COMMIT DROP AS
SELECT * FROM (VALUES
    (1::smallint,1::smallint,'M1_17_G2_FOUNDATION'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (2::smallint,1::smallint,'M1_17_G2_FOUNDATION'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (3::smallint,1::smallint,'M1_17_G2_FOUNDATION'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (4::smallint,1::smallint,'M1_17_G2_FOUNDATION'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (5::smallint,1::smallint,'M1_17_G2_FOUNDATION'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (6::smallint,1::smallint,'M1_17_G2_FOUNDATION'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (7::smallint,2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (8::smallint,2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (9::smallint,2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (10::smallint,2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (11::smallint,2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (12::smallint,2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (13::smallint,3::smallint,'M2_2_PRICING_STRUCTURE'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (14::smallint,3::smallint,'M2_2_PRICING_STRUCTURE'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (15::smallint,3::smallint,'M2_2_PRICING_STRUCTURE'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (16::smallint,3::smallint,'M2_2_PRICING_STRUCTURE'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (17::smallint,3::smallint,'M2_2_PRICING_STRUCTURE'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (18::smallint,3::smallint,'M2_2_PRICING_STRUCTURE'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (19::smallint,4::smallint,'M2_3_FINAL_DECISION'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (20::smallint,4::smallint,'M2_3_FINAL_DECISION'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (21::smallint,4::smallint,'M2_3_FINAL_DECISION'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (22::smallint,4::smallint,'M2_3_FINAL_DECISION'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (23::smallint,4::smallint,'M2_3_FINAL_DECISION'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (24::smallint,4::smallint,'M2_3_FINAL_DECISION'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (25::smallint,5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (26::smallint,5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (27::smallint,5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (28::smallint,5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (29::smallint,5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (30::smallint,5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (31::smallint,6::smallint,'M2_5_DAILY_MONITORING'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (32::smallint,6::smallint,'M2_5_DAILY_MONITORING'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (33::smallint,6::smallint,'M2_5_DAILY_MONITORING'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (34::smallint,6::smallint,'M2_5_DAILY_MONITORING'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (35::smallint,6::smallint,'M2_5_DAILY_MONITORING'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (36::smallint,6::smallint,'M2_5_DAILY_MONITORING'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (37::smallint,7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (38::smallint,7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (39::smallint,7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (40::smallint,7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (41::smallint,7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (42::smallint,7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (43::smallint,8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (44::smallint,8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (45::smallint,8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (46::smallint,8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (47::smallint,8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (48::smallint,8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (49::smallint,9::smallint,'M2_8_SERVICING_EXECUTION'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (50::smallint,9::smallint,'M2_8_SERVICING_EXECUTION'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (51::smallint,9::smallint,'M2_8_SERVICING_EXECUTION'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (52::smallint,9::smallint,'M2_8_SERVICING_EXECUTION'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (53::smallint,9::smallint,'M2_8_SERVICING_EXECUTION'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (54::smallint,9::smallint,'M2_8_SERVICING_EXECUTION'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (55::smallint,10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (56::smallint,10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (57::smallint,10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (58::smallint,10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (59::smallint,10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (60::smallint,10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (61::smallint,11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (62::smallint,11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (63::smallint,11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (64::smallint,11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (65::smallint,11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (66::smallint,11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text),
    (67::smallint,12::smallint,'M2_11_STRATEGY_SIMULATION'::text,1::smallint,'ACCEPTANCE_LIFECYCLE'::text,'MANDATORY'::text,'PASS'::text),
    (68::smallint,12::smallint,'M2_11_STRATEGY_SIMULATION'::text,2::smallint,'POSITIVE_VALIDATION'::text,'MANDATORY'::text,'PASS'::text),
    (69::smallint,12::smallint,'M2_11_STRATEGY_SIMULATION'::text,3::smallint,'NEGATIVE_CONTROLS'::text,'MANDATORY'::text,'PASS'::text),
    (70::smallint,12::smallint,'M2_11_STRATEGY_SIMULATION'::text,4::smallint,'CANONICAL_IDENTITY'::text,'MANDATORY'::text,'PASS'::text),
    (71::smallint,12::smallint,'M2_11_STRATEGY_SIMULATION'::text,5::smallint,'LATEST_ARCHIVE_REPRODUCTION'::text,'MANDATORY'::text,'PASS'::text),
    (72::smallint,12::smallint,'M2_11_STRATEGY_SIMULATION'::text,6::smallint,'STAGE_BOUNDARY'::text,'MANDATORY'::text,'PASS'::text)) v(matrix_sequence,node_sequence,stage_code,evidence_family_sequence,evidence_family_code,applicability_code,allowed_certification_status);

/* R10 GOVERNED STATEMENT 0012 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_EVIDENCE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_evidence_design$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_evidence_design) <> 72 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_evidence_design', DETAIL='expected=72 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_evidence_design)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_evidence_design$;

/* R10 GOVERNED STATEMENT 0013 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_EVIDENCE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_evidence_design_0cfa80c1 ON tmp_preflight_m2_12_evidence_design (matrix_sequence);

/* R10 GOVERNED STATEMENT 0014 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_EVIDENCE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_evidence_design;

/* R10 GOVERNED STATEMENT 0015 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_GATE_CATALOG
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_gate_catalog ON COMMIT DROP AS
(SELECT g.gate_id::text AS gate_id,
       g.gate_name::text AS gate_name,
       g.module_code::text AS module_code,
       g.severity::text AS severity,
       g.active_flag::boolean AS active_flag
FROM msbf_ref.acceptance_gate_catalog g
WHERE g.gate_id='G3_M2_CONTRACT');

/* R10 GOVERNED STATEMENT 0016 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_GATE_CATALOG
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_gate_catalog$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_gate_catalog) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_gate_catalog', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_gate_catalog)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_gate_catalog$;

/* R10 GOVERNED STATEMENT 0017 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_GATE_CATALOG
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_gate_catalog_0643caeb ON tmp_preflight_m2_12_gate_catalog (gate_id);

/* R10 GOVERNED STATEMENT 0018 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_GATE_CATALOG
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_gate_catalog;

/* R10 GOVERNED STATEMENT 0019 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_MODULE3_BOUNDARY
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_module3_boundary ON COMMIT DROP AS
SELECT count(*)::integer AS prohibited_object_count
FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid=c.relnamespace
WHERE n.nspname ~ '^msbf_m3' OR c.relname ~ '^m3_' OR c.relname ~ '^module3_';

/* R10 GOVERNED STATEMENT 0020 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_MODULE3_BOUNDARY
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_module3_boundary$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_module3_boundary) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_module3_boundary', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_module3_boundary)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_module3_boundary$;

/* R10 GOVERNED STATEMENT 0021 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_MODULE3_BOUNDARY
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_module3_boundary_0134ae46 ON tmp_preflight_m2_12_module3_boundary (prohibited_object_count);

/* R10 GOVERNED STATEMENT 0022 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_MODULE3_BOUNDARY
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_module3_boundary;

/* R10 GOVERNED STATEMENT 0023 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_node_design ON COMMIT DROP AS
SELECT * FROM (VALUES
    (1::smallint,'M1_17_G2_FOUNDATION'::text,'19_M1_17'::text,'End-to-End QA, Evidence & G2 Contract Acceptance'::text),
    (2::smallint,'M2_1_ELIGIBILITY_ROUTING'::text,'20_M2_1'::text,'Eligibility, Policy Gates & Decision Routing Foundations'::text),
    (3::smallint,'M2_2_PRICING_STRUCTURE'::text,'21_M2_2'::text,'Pricing, Structure & Counteroffer Foundations'::text),
    (4::smallint,'M2_3_FINAL_DECISION'::text,'22_M2_3'::text,'Final Offer & Decision Authorization'::text),
    (5::smallint,'M2_4_PORTFOLIO_ACTIVATION'::text,'23_M2_4'::text,'Booking, Funding & Portfolio Activation'::text),
    (6::smallint,'M2_5_DAILY_MONITORING'::text,'24_M2_5'::text,'Daily Remittance, Exposure & Portfolio Monitoring'::text),
    (7::smallint,'M2_6_INTERVENTION_STRATEGY'::text,'25_M2_6'::text,'Early Warning, Intervention & Servicing Strategy'::text),
    (8::smallint,'M2_7_OPERATIONAL_ACTIVATION'::text,'26_M2_7'::text,'Operational Activation & Account Setup'::text),
    (9::smallint,'M2_8_SERVICING_EXECUTION'::text,'27_M2_8'::text,'Servicing Execution Simulation, Payment Processing & Account Lifecycle Control'::text),
    (10::smallint,'M2_9_RECONCILIATION_CERTIFICATION'::text,'28_M2_9'::text,'Payment Reconciliation, Exception Resolution & Account State Certification'::text),
    (11::smallint,'M2_10_PORTFOLIO_ANALYTICS'::text,'29_M2_10'::text,'Portfolio Performance, KPI & Servicing Analytics'::text),
    (12::smallint,'M2_11_STRATEGY_SIMULATION'::text,'30_M2_11'::text,'Portfolio Optimization & Strategy Simulation'::text)) v(certification_node_sequence,stage_code,repository_stage,module_title);

/* R10 GOVERNED STATEMENT 0024 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_node_design$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_node_design) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_node_design', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_node_design)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_node_design$;

/* R10 GOVERNED STATEMENT 0025 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_node_design_5ce621eb ON tmp_preflight_m2_12_node_design (certification_node_sequence);

/* R10 GOVERNED STATEMENT 0026 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_node_design;

/* R10 GOVERNED STATEMENT 0027 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_RUN_CONTEXT
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_run_context ON COMMIT PRESERVE ROWS AS
SELECT rr.run_id::bigint AS module1_run_id,
       rr.run_code::text AS run_code,
       rr.run_version::integer AS run_version,
       rr.run_status::text AS run_status,
       rr.as_of_date::date AS as_of_date,
       m211.contract_set_hash::text AS accepted_m2_11_contract_set_hash,
       m211.combined_set_hash::text AS accepted_m2_11_combined_set_hash,
       m211.row_hash::text AS accepted_m2_11_registry_row_hash
FROM msbf_ctl.run_registry rr
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry m211
  ON m211.module1_run_id=rr.run_id
 AND m211.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND m211.contract_version=1
 AND m211.contract_status='ACCEPTED'
WHERE rr.run_code='M1_V0_2_BASELINE_BUILD'
  AND rr.run_version=1
  AND rr.run_status='M2_11_ACCEPTED';

/* R10 GOVERNED STATEMENT 0028 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_RUN_CONTEXT
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_run_context$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_run_context) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_run_context', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_run_context)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_run_context$;

/* R10 GOVERNED STATEMENT 0029 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_RUN_CONTEXT
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_run_context_afa305c3 ON tmp_preflight_m2_12_run_context (module1_run_id);

/* R10 GOVERNED STATEMENT 0030 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_RUN_CONTEXT
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_run_context;

/* R10 GOVERNED STATEMENT 0031 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_source_edge_design ON COMMIT DROP AS
SELECT x.edge_sequence::integer AS edge_sequence,
       x.edge_code::text AS edge_code,
       x.target_node_code::text AS target_node_code,
       x.expected_source_hash::text AS expected_source_hash
FROM jsonb_to_recordset('[{"edge_sequence":"1","edge_code":"M1_15_TO_M1_17_APPLICATION_CONTRACT","target_node_code":"M1_17_G2_FOUNDATION","expected_source_hash":"fcd2704e17ec0d2e73191ea36061d74b"},{"edge_sequence":"2","edge_code":"M1_16_TO_M1_17_ACQUISITION_CONTRACT","target_node_code":"M1_17_G2_FOUNDATION","expected_source_hash":"86df51a0ca68d84096d00ff0f1b19f33"},{"edge_sequence":"3","edge_code":"M1_17_TO_M2_1","target_node_code":"M2_1_ELIGIBILITY_ROUTING","expected_source_hash":"7d9e466da28cad2551aa99c4c40c912b"},{"edge_sequence":"4","edge_code":"M2_1_TO_M2_2","target_node_code":"M2_2_PRICING_STRUCTURE","expected_source_hash":"e5ace7f32060ffb191c7bd0f8dd0c863"},{"edge_sequence":"5","edge_code":"M1_3_TO_M2_2_REQUEST_AUTHORITY","target_node_code":"M2_2_PRICING_STRUCTURE","expected_source_hash":"01485256b9b5748fb412743d35ced602"},{"edge_sequence":"6","edge_code":"M2_2_TO_M2_3","target_node_code":"M2_3_FINAL_DECISION","expected_source_hash":"bbe83b187b31ea561789797322031fc6"},{"edge_sequence":"7","edge_code":"M2_3_TO_M2_4","target_node_code":"M2_4_PORTFOLIO_ACTIVATION","expected_source_hash":"bf09349b06ede7e5a2ec830c2f9ffe90"},{"edge_sequence":"8","edge_code":"M2_4_TO_M2_5","target_node_code":"M2_5_DAILY_MONITORING","expected_source_hash":"117450a3eea7bb3d3c74d18cc3c8e96a"},{"edge_sequence":"9","edge_code":"M1_6_TO_M2_5_SCENARIO_AUTHORITY","target_node_code":"M2_5_DAILY_MONITORING","expected_source_hash":"3f85921bf6fc30ddc6cee146085e58c5"},{"edge_sequence":"10","edge_code":"M2_5_TO_M2_6","target_node_code":"M2_6_INTERVENTION_STRATEGY","expected_source_hash":"18e1c444aa1b02ee5bd3539d7c477adc"},{"edge_sequence":"11","edge_code":"M2_6_TO_M2_7","target_node_code":"M2_7_OPERATIONAL_ACTIVATION","expected_source_hash":"868125bff29270490cab4d2e55cb1388"},{"edge_sequence":"12","edge_code":"M2_7_TO_M2_8","target_node_code":"M2_8_SERVICING_EXECUTION","expected_source_hash":"c8e3a472afd2a16b1183677324e9db98"},{"edge_sequence":"13","edge_code":"M2_8_TO_M2_9","target_node_code":"M2_9_RECONCILIATION_CERTIFICATION","expected_source_hash":"ab32d80ba20c2c8f0a6ec9ec97c2ed26"},{"edge_sequence":"14","edge_code":"M2_9_TO_M2_10","target_node_code":"M2_10_PORTFOLIO_ANALYTICS","expected_source_hash":"6af76d0059b47623619ebc09330b15fe"},{"edge_sequence":"15","edge_code":"M1_17_TO_M2_11","target_node_code":"M2_11_STRATEGY_SIMULATION","expected_source_hash":"7d9e466da28cad2551aa99c4c40c912b"},{"edge_sequence":"16","edge_code":"M2_2_TO_M2_11","target_node_code":"M2_11_STRATEGY_SIMULATION","expected_source_hash":"bbe83b187b31ea561789797322031fc6"},{"edge_sequence":"17","edge_code":"M2_4_TO_M2_11","target_node_code":"M2_11_STRATEGY_SIMULATION","expected_source_hash":"117450a3eea7bb3d3c74d18cc3c8e96a"},{"edge_sequence":"18","edge_code":"M2_7_TO_M2_11","target_node_code":"M2_11_STRATEGY_SIMULATION","expected_source_hash":"c8e3a472afd2a16b1183677324e9db98"},{"edge_sequence":"19","edge_code":"M2_10_TO_M2_11","target_node_code":"M2_11_STRATEGY_SIMULATION","expected_source_hash":"24fca7263a04397ebf21d30639f9069b"}]'::jsonb) AS x(edge_sequence integer, edge_code text, target_node_code text, expected_source_hash text);

/* R10 GOVERNED STATEMENT 0032 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_source_edge_design$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_source_edge_design) <> 19 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_source_edge_design', DETAIL='expected=19 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_source_edge_design)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_source_edge_design$;

/* R10 GOVERNED STATEMENT 0033 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_source_edge_design_f14bae53 ON tmp_preflight_m2_12_source_edge_design (edge_sequence);

/* R10 GOVERNED STATEMENT 0034 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_source_edge_design;

/* R10 GOVERNED STATEMENT 0035 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_SOURCE_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_source_node_design ON COMMIT DROP AS
SELECT x.node_sequence::integer AS node_sequence,
       x.stage_code::text AS stage_code,
       x.registry_relation::text AS registry_relation,
       x.expected_combined_hash::text AS expected_combined_hash
FROM jsonb_to_recordset('[{"node_sequence":"1","stage_code":"M1_17_G2_FOUNDATION","registry_relation":"msbf_ctl.m1_17_g2_bundle_registry","expected_combined_hash":"7d9e466da28cad2551aa99c4c40c912b"},{"node_sequence":"2","stage_code":"M2_1_ELIGIBILITY_ROUTING","registry_relation":"msbf_ctl.m2_1_strategy_contract_registry","expected_combined_hash":"e5ace7f32060ffb191c7bd0f8dd0c863"},{"node_sequence":"3","stage_code":"M2_2_PRICING_STRUCTURE","registry_relation":"msbf_ctl.m2_2_pricing_structure_contract_registry","expected_combined_hash":"bbe83b187b31ea561789797322031fc6"},{"node_sequence":"4","stage_code":"M2_3_FINAL_DECISION","registry_relation":"msbf_ctl.m2_3_final_decision_contract_registry","expected_combined_hash":"bf09349b06ede7e5a2ec830c2f9ffe90"},{"node_sequence":"5","stage_code":"M2_4_PORTFOLIO_ACTIVATION","registry_relation":"msbf_ctl.m2_4_portfolio_activation_contract_registry","expected_combined_hash":"117450a3eea7bb3d3c74d18cc3c8e96a"},{"node_sequence":"6","stage_code":"M2_5_DAILY_MONITORING","registry_relation":"msbf_ctl.m2_5_portfolio_monitoring_contract_registry","expected_combined_hash":"18e1c444aa1b02ee5bd3539d7c477adc"},{"node_sequence":"7","stage_code":"M2_6_INTERVENTION_STRATEGY","registry_relation":"msbf_ctl.m2_6_intervention_strategy_contract_registry","expected_combined_hash":"868125bff29270490cab4d2e55cb1388"},{"node_sequence":"8","stage_code":"M2_7_OPERATIONAL_ACTIVATION","registry_relation":"msbf_ctl.m2_7_operational_activation_contract_registry","expected_combined_hash":"c8e3a472afd2a16b1183677324e9db98"},{"node_sequence":"9","stage_code":"M2_8_SERVICING_EXECUTION","registry_relation":"msbf_ctl.m2_8_servicing_execution_contract_registry","expected_combined_hash":"ab32d80ba20c2c8f0a6ec9ec97c2ed26"},{"node_sequence":"10","stage_code":"M2_9_RECONCILIATION_CERTIFICATION","registry_relation":"msbf_ctl.m2_9_reconciliation_certification_contract_registry","expected_combined_hash":"6af76d0059b47623619ebc09330b15fe"},{"node_sequence":"11","stage_code":"M2_10_PORTFOLIO_ANALYTICS","registry_relation":"msbf_ctl.m2_10_portfolio_analytics_contract_registry","expected_combined_hash":"24fca7263a04397ebf21d30639f9069b"},{"node_sequence":"12","stage_code":"M2_11_STRATEGY_SIMULATION","registry_relation":"msbf_ctl.m2_11_portfolio_strategy_contract_registry","expected_combined_hash":"a67d375b9f9248b3eec8160cf3dc656d"}]'::jsonb)
     AS x(node_sequence integer,stage_code text,registry_relation text,expected_combined_hash text);

/* R10 GOVERNED STATEMENT 0036 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_SOURCE_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_source_node_design$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_source_node_design) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_source_node_design', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_source_node_design)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_source_node_design$;

/* R10 GOVERNED STATEMENT 0037 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_SOURCE_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_source_node_design_08af7afa ON tmp_preflight_m2_12_source_node_design (node_sequence);

/* R10 GOVERNED STATEMENT 0038 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_SOURCE_NODE_DESIGN
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_source_node_design;

/* R10 GOVERNED STATEMENT 0039 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_COMPONENT_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_component_assertion ON COMMIT DROP AS
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='7d9e466da28cad2551aa99c4c40c912b' AND x.observed_contract_set_hash='d9cdb8309efdcc892f0a0c51b3d5fe94' AND x.observed_latest_set_hash='64250f8d027ad78650a1bf5ede7da6e5' AND x.observed_archive_set_hash='020a5946318d6d73da58f723349ab18c' AND x.observed_registry_row_hash='27397e724a7d24a84601d5052f1b0c34' AND x.observed_latest_rows=1 AND x.observed_archive_rows=1 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       1::smallint AS certification_node_sequence,
       1::smallint AS component_sequence,
       'M1_G2_CONSUMPTION_BUNDLE'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1) AS registry_rows,
       (SELECT r.bundle_status::text FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1) AS observed_contract_status,
       (SELECT r.combined_g2_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1) AS observed_contract_set_hash,
       (SELECT r.bundle_latest_set_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1) AS observed_latest_set_hash,
       (SELECT r.bundle_archive_set_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m1_17_g2_bundle_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.bundle_code='M1_G2_CONSUMPTION_BUNDLE' AND r.bundle_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_ctl.m1_17_g2_bundle_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='G2_M1_CONTRACT' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M1_17_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='e5ace7f32060ffb191c7bd0f8dd0c863' AND x.observed_contract_set_hash='5ce0574b6e27c4b94b8e65997b40f805' AND x.observed_latest_set_hash='f813d2d8bfa4609f83b2bfd181de3e17' AND x.observed_archive_set_hash='13d7db24aa254d8efe69b28998d91fd4' AND x.observed_registry_row_hash='e3fe1ae397c76da8f6ba88649935cfa7' AND x.observed_latest_rows=1500 AND x.observed_archive_rows=1500 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       2::smallint AS certification_node_sequence,
       2::smallint AS component_sequence,
       'M2_ELIGIBILITY_ROUTING_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_1_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_1_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_1_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_ELIGIBILITY_ROUTING_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_eligibility_routing_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_1_ELIGIBILITY_POLICY_ROUTING' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_1_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='bbe83b187b31ea561789797322031fc6' AND x.observed_contract_set_hash='89d21438326f33a6df82ee667590497b' AND x.observed_latest_set_hash='da27dcb509a8c0bf3bc7a046242a2c02' AND x.observed_archive_set_hash='c397c86ab234243dc11ab84b9e98eb6f' AND x.observed_registry_row_hash='32374a67d0f8ead18af4bc18139ffdd6' AND x.observed_latest_rows=750 AND x.observed_archive_rows=750 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       3::smallint AS certification_node_sequence,
       3::smallint AS component_sequence,
       'M2_REQUEST_STRUCTURE_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.request_contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.request_contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.request_contract_version=1) AS observed_combined_hash,
       (SELECT r.request_contract_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.request_contract_version=1) AS observed_contract_set_hash,
       (SELECT r.request_latest_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.request_contract_version=1) AS observed_latest_set_hash,
       (SELECT r.request_archive_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.request_contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.request_contract_code='M2_REQUEST_STRUCTURE_CONSUMPTION' AND r.request_contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_request_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_2_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='bbe83b187b31ea561789797322031fc6' AND x.observed_contract_set_hash='e2d8c2eeaddbb1a8f7d2baa10b4cdbd3' AND x.observed_latest_set_hash='a69d1fca447bb573040bf697c43ce1af' AND x.observed_archive_set_hash='9e43326cd8f79b98c19f02f971fb077f' AND x.observed_registry_row_hash='32374a67d0f8ead18af4bc18139ffdd6' AND x.observed_latest_rows=1500 AND x.observed_archive_rows=1500 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       3::smallint AS certification_node_sequence,
       4::smallint AS component_sequence,
       'M2_PRICING_STRUCTURE_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.pricing_contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.pricing_contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.pricing_contract_version=1) AS observed_combined_hash,
       (SELECT r.pricing_contract_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.pricing_contract_version=1) AS observed_contract_set_hash,
       (SELECT r.pricing_latest_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.pricing_contract_version=1) AS observed_latest_set_hash,
       (SELECT r.pricing_archive_set_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.pricing_contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_2_pricing_structure_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.pricing_contract_code='M2_PRICING_STRUCTURE_CONSUMPTION' AND r.pricing_contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_pricing_structure_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_2_PRICING_STRUCTURE_COUNTEROFFER' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_2_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='bf09349b06ede7e5a2ec830c2f9ffe90' AND x.observed_contract_set_hash='cbe8c4a4e5d5e4d6d084ce812a64eb84' AND x.observed_latest_set_hash='8f421bd27d52e18770cee8fb8a72edf1' AND x.observed_archive_set_hash='06331f681706a5b9922865ccbe900755' AND x.observed_registry_row_hash='03ef3d5ffa4c49d982b3877c4002de2d' AND x.observed_latest_rows=1500 AND x.observed_archive_rows=1500 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       4::smallint AS certification_node_sequence,
       5::smallint AS component_sequence,
       'M2_FINAL_OFFER_DECISION_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.decision_latest_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.decision_archive_set_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_3_final_decision_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_FINAL_OFFER_DECISION_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_final_offer_decision_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_3_FINAL_OFFER_DECISION_AUTHORIZATION' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_3_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='117450a3eea7bb3d3c74d18cc3c8e96a' AND x.observed_contract_set_hash='fba075bfd6b24e07dc669d6ce25010f1' AND x.observed_latest_set_hash='f26248c112635ebe5254d614f42332d6' AND x.observed_archive_set_hash='bf72bbed8c76db3ecdc6936e78718e04' AND x.observed_registry_row_hash='879e04636699b51113638ec81d76667b' AND x.observed_latest_rows=1500 AND x.observed_archive_rows=1500 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       5::smallint AS certification_node_sequence,
       6::smallint AS component_sequence,
       'M2_PORTFOLIO_ACTIVATION_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.activation_latest_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.activation_archive_set_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_4_portfolio_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_ACTIVATION_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_booking_funding_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_4_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='18e1c444aa1b02ee5bd3539d7c477adc' AND x.observed_contract_set_hash='decdc18973edb5f29d2e55ca8a139457' AND x.observed_latest_set_hash='ddb680b9f00e88483099d90e781337eb' AND x.observed_archive_set_hash='c8c22762d49bbd58cf89bae187eaac9f' AND x.observed_registry_row_hash='c50efd2f8ec5bf10216e5da889ff403d' AND x.observed_latest_rows=59 AND x.observed_archive_rows=59 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       6::smallint AS certification_node_sequence,
       7::smallint AS component_sequence,
       'M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_5_portfolio_monitoring_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.advance_portfolio_monitoring_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_5_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='868125bff29270490cab4d2e55cb1388' AND x.observed_contract_set_hash='5e5c05dbe9d334cd64d4c6c178a7bacf' AND x.observed_latest_set_hash='f3c42642b2a22b68ff2130d7b065afcd' AND x.observed_archive_set_hash='72f26807f4d65fa6f813502df9dde3f0' AND x.observed_registry_row_hash='4f145d5248bbc6ed5c45b172afa4d342' AND x.observed_latest_rows=59 AND x.observed_archive_rows=59 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       7::smallint AS certification_node_sequence,
       8::smallint AS component_sequence,
       'M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_6_intervention_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.advance_intervention_strategy_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_6_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='c8e3a472afd2a16b1183677324e9db98' AND x.observed_contract_set_hash='c74d986057de7b01d95d0b92bc820d8c' AND x.observed_latest_set_hash='e1fa837647489de56d66222447420549' AND x.observed_archive_set_hash='9980f9ff49ca53790ec9af8c6988d44a' AND x.observed_registry_row_hash='8b210c34bdb12f8fb71638b48b374c14' AND x.observed_latest_rows=59 AND x.observed_archive_rows=59 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       8::smallint AS certification_node_sequence,
       9::smallint AS component_sequence,
       'M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_7_operational_activation_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_operational_activation_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_7_OPERATIONAL_ACTIVATION_ACCOUNT_SETUP' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_7_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='ab32d80ba20c2c8f0a6ec9ec97c2ed26' AND x.observed_contract_set_hash='37bd013240b1cd6a5db49a271c0c8cec' AND x.observed_latest_set_hash='9716224077ff6b7468c0b7b2fed6ab73' AND x.observed_archive_set_hash='ea3a63d0bd9069cb5c061d09750d8d32' AND x.observed_registry_row_hash='03b6c0ca3af4ab9d196e09cefa59be3d' AND x.observed_latest_rows=59 AND x.observed_archive_rows=59 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       9::smallint AS certification_node_sequence,
       10::smallint AS component_sequence,
       'M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_8_servicing_execution_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_8_servicing_execution_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_servicing_execution_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_8_SERVICING_EXECUTION_PAYMENT_LIFECYCLE_CONTROL' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_8_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='6af76d0059b47623619ebc09330b15fe' AND x.observed_contract_set_hash='5976e2e037a53aa184d29b7bcfeaf09e' AND x.observed_latest_set_hash='e1206bb355dac10fa8d97a81637ce965' AND x.observed_archive_set_hash='0bbe110652afd2a01378d36c596e4379' AND x.observed_registry_row_hash='6df16ccd5d6d7f7bffbc0ca4a2539140' AND x.observed_latest_rows=59 AND x.observed_archive_rows=59 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       10::smallint AS certification_node_sequence,
       11::smallint AS component_sequence,
       'M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_9_reconciliation_certification_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_payment_reconciliation_certification_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_9_PAYMENT_RECONCILIATION_EXCEPTION_RESOLUTION_ACCOUNT_STATE_CERTIFICATION' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_9_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='24fca7263a04397ebf21d30639f9069b' AND x.observed_contract_set_hash='98771133c07f0bdb9828cf233f32ad2f' AND x.observed_latest_set_hash='c34f6721bd7a6818d2492d564611ef2a' AND x.observed_archive_set_hash='105691ceca00acc516296b19a64a1c25' AND x.observed_registry_row_hash='944d8f676a5b7fb58700b2a66309f428' AND x.observed_latest_rows=59 AND x.observed_archive_rows=59 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       11::smallint AS certification_node_sequence,
       12::smallint AS component_sequence,
       'M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_10_portfolio_analytics_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.application_portfolio_performance_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_10_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x)
UNION ALL
(SELECT x.module1_run_id,
       x.certification_node_sequence,
       x.component_sequence,
       x.component_contract_code,
       x.contract_version,
       x.registry_rows,
       x.observed_contract_status,
       x.observed_combined_hash,
       x.observed_contract_set_hash,
       x.observed_latest_set_hash,
       x.observed_archive_set_hash,
       x.observed_registry_row_hash,
       x.observed_latest_rows,
       x.observed_archive_rows,
       x.gate_pass_flag,
       x.acceptance_evidence_pass_flag, CASE WHEN x.registry_rows=1 AND x.observed_contract_status='ACCEPTED' AND x.observed_combined_hash='a67d375b9f9248b3eec8160cf3dc656d' AND x.observed_contract_set_hash='19f1a9d842c9cb35617ca03e49445aad' AND x.observed_latest_set_hash='634a9894d0241505582e0d89e4c5f27b' AND x.observed_archive_set_hash='641deff3b776faa419cc6c0489f85024' AND x.observed_registry_row_hash='61c22f4f3f2e99905d05958fddf80671' AND x.observed_latest_rows=24 AND x.observed_archive_rows=24 AND x.gate_pass_flag AND x.acceptance_evidence_pass_flag THEN 'PASS'::text ELSE 'FAIL'::text END AS component_status FROM (
SELECT ctx.module1_run_id,
       12::smallint AS certification_node_sequence,
       13::smallint AS component_sequence,
       'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'::text AS component_contract_code,
       1::integer AS contract_version,
       (SELECT count(*)::bigint FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1) AS registry_rows,
       (SELECT r.contract_status::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_status,
       (SELECT r.combined_set_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1) AS observed_combined_hash,
       (SELECT r.contract_set_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1) AS observed_contract_set_hash,
       (SELECT r.latest_set_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1) AS observed_latest_set_hash,
       (SELECT r.archive_set_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1) AS observed_archive_set_hash,
       (SELECT r.row_hash::text FROM msbf_ctl.m2_11_portfolio_strategy_contract_registry r WHERE r.module1_run_id=ctx.module1_run_id AND r.contract_code='M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION' AND r.contract_version=1) AS observed_registry_row_hash,
       (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_latest l WHERE l.module1_run_id=ctx.module1_run_id) AS observed_latest_rows,
       (SELECT count(*)::bigint FROM msbf_m2.portfolio_strategy_simulation_archive a WHERE a.module1_run_id=ctx.module1_run_id) AS observed_archive_rows,
       EXISTS (SELECT 1 FROM msbf_ctl.acceptance_gate_result g WHERE g.run_id=ctx.module1_run_id AND g.gate_id='M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION' AND g.review_version=1 AND g.result_status='PASS') AS gate_pass_flag,
       EXISTS (SELECT 1 FROM msbf_ctl.run_evidence ev WHERE ev.run_id=ctx.module1_run_id AND ev.evidence_code='M2_11_ACCEPTANCE_SUMMARY' AND ev.status='PASS') AS acceptance_evidence_pass_flag
FROM tmp_preflight_m2_12_run_context ctx
) x);

/* R10 GOVERNED STATEMENT 0040 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_COMPONENT_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_component_assertion$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_component_assertion) <> 13 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_component_assertion', DETAIL='expected=13 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_component_assertion)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_component_assertion$;

/* R10 GOVERNED STATEMENT 0041 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_COMPONENT_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_component_assertion_36a60bc0 ON tmp_preflight_m2_12_component_assertion (component_sequence);

/* R10 GOVERNED STATEMENT 0042 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_COMPONENT_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_component_assertion;

/* R10 GOVERNED STATEMENT 0043 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_NONPOLICY_SCOPE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_nonpolicy_scope ON COMMIT DROP AS
SELECT ctx.module1_run_id,
 (SELECT count(*) FROM msbf_m2.module2_stage_certification_snapshot WHERE module1_run_id=ctx.module1_run_id)
+(SELECT count(*) FROM msbf_m2.module2_contract_component_snapshot WHERE module1_run_id=ctx.module1_run_id)
+(SELECT count(*) FROM msbf_m2.module2_evidence_certification_snapshot WHERE module1_run_id=ctx.module1_run_id)
+(SELECT count(*) FROM msbf_m2.module2_contract_reproduction_snapshot WHERE module1_run_id=ctx.module1_run_id)
+(SELECT count(*) FROM msbf_m2.module2_capability_coverage_snapshot WHERE module1_run_id=ctx.module1_run_id)
+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_latest WHERE module1_run_id=ctx.module1_run_id)
+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_archive WHERE module1_run_id=ctx.module1_run_id)
+(SELECT count(*) FROM msbf_ctl.m2_12_g3_bundle_registry WHERE module1_run_id=ctx.module1_run_id) AS nonpolicy_rows,
 (SELECT count(*) FROM msbf_ctl.run_evidence WHERE run_id=ctx.module1_run_id AND evidence_code LIKE 'M2_12_%') AS m2_12_evidence_rows,
 (SELECT count(*) FROM msbf_ctl.acceptance_gate_result WHERE run_id=ctx.module1_run_id AND gate_id='G3_M2_CONTRACT') AS g3_gate_rows
FROM tmp_preflight_m2_12_run_context ctx;

/* R10 GOVERNED STATEMENT 0044 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_NONPOLICY_SCOPE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_nonpolicy_scope$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_nonpolicy_scope) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_nonpolicy_scope', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_nonpolicy_scope)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_nonpolicy_scope$;

/* R10 GOVERNED STATEMENT 0045 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_NONPOLICY_SCOPE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_nonpolicy_scope_317f166f ON tmp_preflight_m2_12_nonpolicy_scope (module1_run_id);

/* R10 GOVERNED STATEMENT 0046 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_NONPOLICY_SCOPE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_nonpolicy_scope;

/* R10 GOVERNED STATEMENT 0047 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_POLICY_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_policy_assertion ON COMMIT DROP AS
SELECT ctx.module1_run_id,
       count(p.*)::integer AS policy_rows,
       count(*) FILTER (WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED' AND p.methodology_version='M2_12_METHOD_V1' AND p.bundle_code='M2_G3_CONSUMPTION_BUNDLE' AND p.bundle_version=1 AND p.schema_version='M2_G3_BUNDLE_SCHEMA_V1' AND p.acceptance_gate_id='G3_M2_CONTRACT' AND p.accepted_m2_11_project_sha256='92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc' AND p.accepted_m2_11_contract_set_hash=ctx.accepted_m2_11_contract_set_hash AND p.accepted_m2_11_combined_set_hash=ctx.accepted_m2_11_combined_set_hash AND p.accepted_m2_11_registry_row_hash=ctx.accepted_m2_11_registry_row_hash AND p.configuration_hash=md5(p.configuration_payload::text) AND p.row_hash=md5((to_jsonb(p)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))::integer AS exact_policy_rows,
       CASE WHEN count(p.*)=1 AND count(*) FILTER (WHERE p.policy_code='M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1' AND p.policy_version=1 AND p.policy_status='APPROVED' AND p.configuration_hash=md5(p.configuration_payload::text) AND p.row_hash=md5((to_jsonb(p)-'policy_profile_id'-'row_hash'-'created_at'-'updated_at')::text))=1 THEN 'PASS'::text ELSE 'FAIL'::text END AS policy_status
FROM tmp_preflight_m2_12_run_context ctx
LEFT JOIN msbf_ctl.m2_12_policy_profile p ON p.module1_run_id=ctx.module1_run_id
GROUP BY ctx.module1_run_id;

/* R10 GOVERNED STATEMENT 0048 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_POLICY_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_policy_assertion$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_policy_assertion) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_policy_assertion', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_policy_assertion)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_policy_assertion$;

/* R10 GOVERNED STATEMENT 0049 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_POLICY_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_policy_assertion_a50edb08 ON tmp_preflight_m2_12_policy_assertion (module1_run_id);

/* R10 GOVERNED STATEMENT 0050 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_POLICY_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_policy_assertion;

/* R10 GOVERNED STATEMENT 0051 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_SEQUENCE_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_sequence_state ON COMMIT DROP AS
SELECT ctx.module1_run_id,
       p.last_value::bigint AS policy_last_value, p.is_called AS policy_is_called,
       a.last_value::bigint AS archive_last_value, a.is_called AS archive_is_called,
       r.last_value::bigint AS registry_last_value, r.is_called AS registry_is_called,
       CASE WHEN p.last_value=1 AND p.is_called AND a.last_value=1 AND NOT a.is_called AND r.last_value=1 AND NOT r.is_called THEN 'PASS'::text ELSE 'FAIL'::text END AS sequence_status
FROM tmp_preflight_m2_12_run_context ctx
CROSS JOIN msbf_ctl.m2_12_policy_profile_policy_profile_id_seq p
CROSS JOIN msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq a
CROSS JOIN msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq r;

/* R10 GOVERNED STATEMENT 0052 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_SEQUENCE_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_sequence_state$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_sequence_state) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_sequence_state', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_sequence_state)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_sequence_state$;

/* R10 GOVERNED STATEMENT 0053 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_SEQUENCE_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_sequence_state_9081c085 ON tmp_preflight_m2_12_sequence_state (module1_run_id);

/* R10 GOVERNED STATEMENT 0054 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_SEQUENCE_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_sequence_state;

/* R10 GOVERNED STATEMENT 0055 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_source_edge_physical ON COMMIT DROP AS
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
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
FROM tmp_preflight_m2_12_run_context ctx
) x);

/* R10 GOVERNED STATEMENT 0056 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_source_edge_physical$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_source_edge_physical) <> 19 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_source_edge_physical', DETAIL='expected=19 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_source_edge_physical)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_source_edge_physical$;

/* R10 GOVERNED STATEMENT 0057 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_source_edge_physical_f5766619 ON tmp_preflight_m2_12_source_edge_physical (edge_sequence);

/* R10 GOVERNED STATEMENT 0058 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_SOURCE_EDGE_PHYSICAL
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_source_edge_physical;

/* R10 GOVERNED STATEMENT 0059 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_TARGET_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_target_state ON COMMIT DROP AS
SELECT q.object_name,q.observed_rows,q.required_rows,(q.observed_rows=q.required_rows)::boolean AS pristine_flag
FROM (
 SELECT 'msbf_ctl.m2_12_policy_profile'::text AS object_name,count(*)::bigint AS observed_rows,1::bigint AS required_rows FROM msbf_ctl.m2_12_policy_profile p JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=p.module1_run_id
 UNION ALL SELECT 'msbf_m2.module2_stage_certification_snapshot',count(*)::bigint,0::bigint FROM msbf_m2.module2_stage_certification_snapshot t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
 UNION ALL SELECT 'msbf_m2.module2_contract_component_snapshot',count(*)::bigint,0::bigint FROM msbf_m2.module2_contract_component_snapshot t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
 UNION ALL SELECT 'msbf_m2.module2_evidence_certification_snapshot',count(*)::bigint,0::bigint FROM msbf_m2.module2_evidence_certification_snapshot t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
 UNION ALL SELECT 'msbf_m2.module2_contract_reproduction_snapshot',count(*)::bigint,0::bigint FROM msbf_m2.module2_contract_reproduction_snapshot t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
 UNION ALL SELECT 'msbf_m2.module2_capability_coverage_snapshot',count(*)::bigint,0::bigint FROM msbf_m2.module2_capability_coverage_snapshot t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
 UNION ALL SELECT 'msbf_ctl.m2_12_g3_bundle_latest',count(*)::bigint,0::bigint FROM msbf_ctl.m2_12_g3_bundle_latest t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
 UNION ALL SELECT 'msbf_ctl.m2_12_g3_bundle_archive',count(*)::bigint,0::bigint FROM msbf_ctl.m2_12_g3_bundle_archive t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
 UNION ALL SELECT 'msbf_ctl.m2_12_g3_bundle_registry',count(*)::bigint,0::bigint FROM msbf_ctl.m2_12_g3_bundle_registry t JOIN tmp_preflight_m2_12_run_context ctx ON ctx.module1_run_id=t.module1_run_id
) q
ORDER BY q.object_name;

/* R10 GOVERNED STATEMENT 0060 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_TARGET_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_target_state$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_target_state) <> 9 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_target_state', DETAIL='expected=9 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_target_state)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_target_state$;

/* R10 GOVERNED STATEMENT 0061 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_TARGET_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_target_state_b8ba9e3a ON tmp_preflight_m2_12_target_state (object_name);

/* R10 GOVERNED STATEMENT 0062 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_TARGET_STATE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_target_state;

/* R10 GOVERNED STATEMENT 0063 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_NODE_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_node_assertion ON COMMIT DROP AS
SELECT c.module1_run_id,
       n.certification_node_sequence,
       n.stage_code,
       c.passed_component_rows,
       c.required_component_rows,
       coalesce(e.observed_source_edge_rows,0)::integer AS observed_source_edge_rows,
       coalesce(e.passed_source_edge_rows,0)::integer AS passed_source_edge_rows,
       CASE WHEN c.passed_component_rows=c.required_component_rows
                  AND coalesce(e.observed_source_edge_rows,0)=coalesce(e.passed_source_edge_rows,0)
            THEN 'PASS'::text ELSE 'FAIL'::text END AS node_status
FROM tmp_preflight_m2_12_node_design n
JOIN (
    SELECT module1_run_id,
           certification_node_sequence,
           count(*) FILTER (WHERE component_status='PASS')::integer AS passed_component_rows,
           count(*)::integer AS required_component_rows
    FROM tmp_preflight_m2_12_component_assertion
    GROUP BY module1_run_id,certification_node_sequence
) c ON c.certification_node_sequence=n.certification_node_sequence
LEFT JOIN (
    SELECT target_node_code,
           count(*)::integer AS observed_source_edge_rows,
           count(*) FILTER (WHERE edge_status='PASS')::integer AS passed_source_edge_rows
    FROM tmp_preflight_m2_12_source_edge_physical
    GROUP BY target_node_code
) e ON e.target_node_code=n.stage_code;

/* R10 GOVERNED STATEMENT 0064 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_NODE_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_node_assertion$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_node_assertion) <> 12 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_node_assertion', DETAIL='expected=12 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_node_assertion)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_node_assertion$;

/* R10 GOVERNED STATEMENT 0065 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_NODE_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_node_assertion_dd07f91b ON tmp_preflight_m2_12_node_assertion (certification_node_sequence);

/* R10 GOVERNED STATEMENT 0066 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_NODE_ASSERTION
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_node_assertion;

/* R10 GOVERNED STATEMENT 0067 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_RESULT_BASE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_result_base ON COMMIT DROP AS
SELECT
       u.assertion_sequence::smallint AS assertion_sequence,
       u.assertion_code::text AS assertion_code,
       u.observed_value::text AS observed_value,
       u.expected_value::text AS expected_value,
       u.status::text AS status
FROM (
(SELECT 1::smallint AS assertion_sequence, 'P221_001_RUN'::text AS assertion_code, ((SELECT count(*)||'|'||min(run_status) FROM tmp_preflight_m2_12_run_context))::text AS observed_value, '1|M2_11_ACCEPTED'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(run_status='M2_11_ACCEPTED') FROM tmp_preflight_m2_12_run_context)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 2::smallint AS assertion_sequence, 'P221_002_GATE'::text AS assertion_code, ((SELECT count(*)||'|'||coalesce(min(severity),'')||'|'||coalesce(bool_and(active_flag)::text,'false') FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='G3_M2_CONTRACT'))::text AS observed_value, '1|BLOCKING|true'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(module_code='M2' AND gate_name='Module 2 Contract' AND description='Offer contract accepted.' AND severity='BLOCKING' AND active_flag) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='G3_M2_CONTRACT')) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 3::smallint AS assertion_sequence, 'P221_003_POLICY_EXACT'::text AS assertion_code, ((SELECT policy_rows||'|'||exact_policy_rows||'|'||policy_status FROM tmp_preflight_m2_12_policy_assertion))::text AS observed_value, '1|1|PASS'::text AS expected_value, CASE WHEN ((SELECT policy_rows=1 AND exact_policy_rows=1 AND policy_status='PASS' FROM tmp_preflight_m2_12_policy_assertion)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 4::smallint AS assertion_sequence, 'P221_004_NONPOLICY_ABSENT'::text AS assertion_code, ((SELECT nonpolicy_rows||'|'||m2_12_evidence_rows||'|'||g3_gate_rows FROM tmp_preflight_m2_12_nonpolicy_scope))::text AS observed_value, '0|0|0'::text AS expected_value, CASE WHEN ((SELECT nonpolicy_rows=0 AND m2_12_evidence_rows=0 AND g3_gate_rows=0 FROM tmp_preflight_m2_12_nonpolicy_scope)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 5::smallint AS assertion_sequence, 'P221_005_SOURCE_NODES'::text AS assertion_code, ((SELECT count(*)||'|'||count(DISTINCT certification_node_sequence) FROM tmp_preflight_m2_12_node_design))::text AS observed_value, '12|12'::text AS expected_value, CASE WHEN ((SELECT count(*)=12 AND count(DISTINCT certification_node_sequence)=12 FROM tmp_preflight_m2_12_node_design)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 6::smallint AS assertion_sequence, 'P221_006_COMPONENTS'::text AS assertion_code, ((SELECT count(*)||'|'||count(DISTINCT component_sequence) FROM tmp_preflight_m2_12_component_design))::text AS observed_value, '13|13'::text AS expected_value, CASE WHEN ((SELECT count(*)=13 AND count(DISTINCT component_sequence)=13 FROM tmp_preflight_m2_12_component_design)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 7::smallint AS assertion_sequence, 'P221_007_EDGES'::text AS assertion_code, ((SELECT count(*)||'|'||count(*) FILTER (WHERE edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical))::text AS observed_value, '19|19'::text AS expected_value, CASE WHEN ((SELECT count(*)=19 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 8::smallint AS assertion_sequence, 'P221_008_EVIDENCE'::text AS assertion_code, ((SELECT count(*)||'|'||count(*) FILTER (WHERE applicability_code='MANDATORY' AND allowed_certification_status='PASS') FROM tmp_preflight_m2_12_evidence_design))::text AS observed_value, '72|72'::text AS expected_value, CASE WHEN ((SELECT count(*)=72 AND bool_and(applicability_code='MANDATORY' AND allowed_certification_status='PASS') FROM tmp_preflight_m2_12_evidence_design)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 9::smallint AS assertion_sequence, 'P221_009_CAPABILITIES'::text AS assertion_code, ((SELECT count(*)||'|'||count(DISTINCT capability_sequence) FROM tmp_preflight_m2_12_capability_design))::text AS observed_value, '20|20'::text AS expected_value, CASE WHEN ((SELECT count(*)=20 AND count(DISTINCT capability_sequence)=20 AND bool_and(NOT production_action_authorized_flag AND NOT legal_or_regulatory_certified_flag ) FROM tmp_preflight_m2_12_capability_design)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 10::smallint AS assertion_sequence, 'P221_010_MODULE3'::text AS assertion_code, ((SELECT prohibited_object_count FROM tmp_preflight_m2_12_module3_boundary))::text AS observed_value, '0'::text AS expected_value, CASE WHEN ((SELECT prohibited_object_count=0 FROM tmp_preflight_m2_12_module3_boundary)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 11::smallint AS assertion_sequence, 'P221_011_SEQUENCES'::text AS assertion_code, ((SELECT policy_last_value||'|'||policy_is_called||'|'||archive_last_value||'|'||archive_is_called||'|'||registry_last_value||'|'||registry_is_called FROM tmp_preflight_m2_12_sequence_state))::text AS observed_value, '1|true|1|false|1|false'::text AS expected_value, CASE WHEN ((SELECT sequence_status='PASS' FROM tmp_preflight_m2_12_sequence_state)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 12::smallint AS assertion_sequence, 'P221_012_ACCEPTED_COMPONENT_ROWS'::text AS assertion_code, ((SELECT sum(observed_latest_rows)||'|'||sum(observed_archive_rows) FROM tmp_preflight_m2_12_component_assertion))::text AS observed_value, '7129|7129'::text AS expected_value, CASE WHEN ((SELECT sum(observed_latest_rows)=7129 AND sum(observed_archive_rows)=7129 FROM tmp_preflight_m2_12_component_assertion)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 13::smallint AS assertion_sequence, 'P221_NODE_01'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=1))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=1)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 14::smallint AS assertion_sequence, 'P221_NODE_02'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=2))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=2)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 15::smallint AS assertion_sequence, 'P221_NODE_03'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=3))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=3)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 16::smallint AS assertion_sequence, 'P221_NODE_04'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=4))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=4)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 17::smallint AS assertion_sequence, 'P221_NODE_05'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=5))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=5)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 18::smallint AS assertion_sequence, 'P221_NODE_06'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=6))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=6)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 19::smallint AS assertion_sequence, 'P221_NODE_07'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=7))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=7)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 20::smallint AS assertion_sequence, 'P221_NODE_08'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=8))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=8)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 21::smallint AS assertion_sequence, 'P221_NODE_09'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=9))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=9)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 22::smallint AS assertion_sequence, 'P221_NODE_10'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=10))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=10)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 23::smallint AS assertion_sequence, 'P221_NODE_11'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=11))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=11)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 24::smallint AS assertion_sequence, 'P221_NODE_12'::text AS assertion_code, ((SELECT required_component_rows||'|'||passed_component_rows||'|'||observed_source_edge_rows||'|'||passed_source_edge_rows||'|'||node_status FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=12))::text AS observed_value, 'exact node-specific PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=12)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 25::smallint AS assertion_sequence, 'P221_COMPONENT_01'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=1))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=1)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 26::smallint AS assertion_sequence, 'P221_COMPONENT_02'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=2))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=2)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 27::smallint AS assertion_sequence, 'P221_COMPONENT_03'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=3))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=3)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 28::smallint AS assertion_sequence, 'P221_COMPONENT_04'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=4))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=4)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 29::smallint AS assertion_sequence, 'P221_COMPONENT_05'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=5))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=5)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 30::smallint AS assertion_sequence, 'P221_COMPONENT_06'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=6))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=6)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 31::smallint AS assertion_sequence, 'P221_COMPONENT_07'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=7))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=7)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 32::smallint AS assertion_sequence, 'P221_COMPONENT_08'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=8))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=8)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 33::smallint AS assertion_sequence, 'P221_COMPONENT_09'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=9))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=9)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 34::smallint AS assertion_sequence, 'P221_COMPONENT_10'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=10))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=10)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 35::smallint AS assertion_sequence, 'P221_COMPONENT_11'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=11))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=11)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 36::smallint AS assertion_sequence, 'P221_COMPONENT_12'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=12))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=12)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 37::smallint AS assertion_sequence, 'P221_COMPONENT_13'::text AS assertion_code, ((SELECT component_status||'|'||registry_rows||'|'||observed_latest_rows||'|'||observed_archive_rows FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=13))::text AS observed_value, 'PASS|1|expected|expected'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=13)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 38::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_01'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=1))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=1)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 39::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_02'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=2))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=2)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 40::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_03'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=3))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=3)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 41::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_04'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=4))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=4)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 42::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_05'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=5))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=5)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 43::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_06'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=6))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=6)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 44::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_07'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=7))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=7)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 45::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_08'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=8))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=8)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 46::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_09'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=9))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=9)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 47::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_10'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=10))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=10)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
UNION ALL
(SELECT 48::smallint AS assertion_sequence, 'P221_EDGE_DETAIL_11'::text AS assertion_code, ((SELECT edge_status||'|'||observed_accepted_source_hash||'|'||observed_target_recorded_source_hash||'|'||source_gate_status FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=11))::text AS observed_value, 'PASS|expected|expected|PASS'::text AS expected_value, CASE WHEN ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=11)) THEN 'PASS'::text ELSE 'FAIL'::text END AS status)
) u
ORDER BY u.assertion_sequence;

/* R10 GOVERNED STATEMENT 0068 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_RESULT_BASE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_result_base$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_result_base) <> 48 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_result_base', DETAIL='expected=48 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_result_base)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_result_base$;

/* R10 GOVERNED STATEMENT 0069 OF 0076
   statement_code: INDEX_TMP_PREFLIGHT_M2_12_RESULT_BASE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_INDEX
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE UNIQUE INDEX ux_preflight_m2_12_result_base_ac3ab916 ON tmp_preflight_m2_12_result_base (assertion_sequence);

/* R10 GOVERNED STATEMENT 0070 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_RESULT_BASE
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_result_base;

/* R10 GOVERNED STATEMENT 0071 OF 0076
   statement_code: CREATE_TMP_PREFLIGHT_M2_12_RESULT
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: CREATE_TEMP_TABLE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
CREATE TEMP TABLE tmp_preflight_m2_12_result ON COMMIT PRESERVE ROWS AS
SELECT count(*)::integer AS assertion_rows,
       count(*) FILTER (WHERE status='PASS')::integer AS pass_rows,
       count(*) FILTER (WHERE status<>'PASS')::integer AS fail_rows,
       bool_and(status='PASS') AS all_pass_flag
FROM tmp_preflight_m2_12_result_base;

/* R10 GOVERNED STATEMENT 0072 OF 0076
   statement_code: ASSERT_TMP_PREFLIGHT_M2_12_RESULT
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: HELPER_ROW_ASSERTION
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
DO $m212_r7_tmp_preflight_m2_12_result$ BEGIN IF (SELECT count(*) FROM tmp_preflight_m2_12_result) <> 1 THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_result', DETAIL='expected=1 observed='||(SELECT count(*) FROM tmp_preflight_m2_12_result)::text; END IF; END; $m212_r7_tmp_preflight_m2_12_result$;

/* R10 GOVERNED STATEMENT 0073 OF 0076
   statement_code: ANALYZE_TMP_PREFLIGHT_M2_12_RESULT
   phase_code: 01_PREFLIGHT_HELPERS
   statement_type: TEMP_ANALYZE
   source_authority: M2_12_HELPER_LITERAL_CREATE_STATEMENT_CATALOG.csv
*/
ANALYZE tmp_preflight_m2_12_result;

/* R10 GOVERNED STATEMENT 0074 OF 0076
   statement_code: EXECUTE_48_ASSERTIONS
   phase_code: 02_ASSERTIONS
   statement_type: ASSERTION_BLOCK
   source_authority: M2_12_PROGRAM_221_ASSERTION_EXECUTION_COMPILER.csv
*/
DO $m212_p221_assertions$
BEGIN
    IF NOT ((SELECT count(*)=1 AND bool_and(run_status='M2_11_ACCEPTED') FROM tmp_preflight_m2_12_run_context)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 run prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(module_code='M2' AND gate_name='Module 2 Contract' AND description='Offer contract accepted.' AND severity='BLOCKING' AND active_flag) FROM msbf_ref.acceptance_gate_catalog WHERE gate_id='G3_M2_CONTRACT')) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 G3 gate prerequisite failed'; END IF;
    IF NOT ((SELECT policy_rows=1 AND exact_policy_rows=1 AND policy_status='PASS' FROM tmp_preflight_m2_12_policy_assertion)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 installed policy prerequisite failed'; END IF;
    IF NOT ((SELECT nonpolicy_rows=0 AND m2_12_evidence_rows=0 AND g3_gate_rows=0 FROM tmp_preflight_m2_12_nonpolicy_scope)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 nonpolicy target is not pristine'; END IF;
    IF NOT ((SELECT count(*)=12 AND count(DISTINCT certification_node_sequence)=12 FROM tmp_preflight_m2_12_node_design)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node design mismatch'; END IF;
    IF NOT ((SELECT count(*)=13 AND count(DISTINCT component_sequence)=13 FROM tmp_preflight_m2_12_component_design)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component design mismatch'; END IF;
    IF NOT ((SELECT count(*)=19 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical)) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P221 source graph mismatch',
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
                 FROM tmp_preflight_m2_12_source_edge_physical
                 WHERE edge_status IS DISTINCT FROM 'PASS'),
                'edge_rows='||(SELECT count(*) FROM tmp_preflight_m2_12_source_edge_physical)::text||' with no individually identified FAIL row'),
            HINT='Inspect the edge-level detail. Do not rerun or proceed to Program 222.';
    END IF;
    IF NOT ((SELECT count(*)=72 AND bool_and(applicability_code='MANDATORY' AND allowed_certification_status='PASS') FROM tmp_preflight_m2_12_evidence_design)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 evidence applicability mismatch'; END IF;
    IF NOT ((SELECT count(*)=20 AND count(DISTINCT capability_sequence)=20 AND bool_and(NOT production_action_authorized_flag AND NOT legal_or_regulatory_certified_flag ) FROM tmp_preflight_m2_12_capability_design)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 capability design mismatch'; END IF;
    IF NOT ((SELECT prohibited_object_count=0 FROM tmp_preflight_m2_12_module3_boundary)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 premature Module 3 object detected'; END IF;
    IF NOT ((SELECT sequence_status='PASS' FROM tmp_preflight_m2_12_sequence_state)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 sequence prerequisite failed'; END IF;
    IF NOT ((SELECT sum(observed_latest_rows)=7129 AND sum(observed_archive_rows)=7129 FROM tmp_preflight_m2_12_component_assertion)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 accepted component row totals mismatch'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=1)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 01 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=2)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 02 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=3)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 03 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=4)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 04 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=5)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 05 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=6)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 06 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=7)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 07 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=8)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 08 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=9)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 09 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=10)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 10 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=11)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 11 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(node_status='PASS' AND required_component_rows=passed_component_rows AND observed_source_edge_rows=passed_source_edge_rows) FROM tmp_preflight_m2_12_node_assertion WHERE certification_node_sequence=12)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 node 12 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=1)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 01 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=2)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 02 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=3)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 03 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=4)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 04 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=5)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 05 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=6)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 06 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=7)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 07 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=8)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 08 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=9)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 09 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=10)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 10 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=11)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 11 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=12)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 12 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(component_status='PASS') FROM tmp_preflight_m2_12_component_assertion WHERE component_sequence=13)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 component 13 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=1)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 01 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=2)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 02 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=3)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 03 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=4)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 04 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=5)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 05 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=6)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 06 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=7)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 07 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=8)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 08 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=9)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 09 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=10)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 10 prerequisite failed'; END IF;
    IF NOT ((SELECT count(*)=1 AND bool_and(edge_status='PASS') FROM tmp_preflight_m2_12_source_edge_physical WHERE edge_sequence=11)) THEN RAISE EXCEPTION USING ERRCODE='P0001', MESSAGE='M2.12 P221 edge 11 prerequisite failed'; END IF;
    IF NOT (SELECT assertion_rows=48 AND pass_rows=48 AND fail_rows=0 AND coalesce(all_pass_flag,false)
                FROM tmp_preflight_m2_12_result) THEN
        RAISE EXCEPTION USING
            ERRCODE='P0001',
            MESSAGE='M2.12 P221 final 48-of-48 assertion collection mismatch',
            DETAIL=(SELECT 'assertion_rows='||assertion_rows::text||
                           '|pass_rows='||pass_rows::text||
                           '|fail_rows='||fail_rows::text||
                           '|all_pass='||coalesce(all_pass_flag::text,'<NULL>')
                      FROM tmp_preflight_m2_12_result),
            HINT='Stop. Preserve the transcript and do not proceed to Program 222.';
    END IF;
END;
$m212_p221_assertions$;

/* R10 GOVERNED STATEMENT 0075 OF 0076
   statement_code: PRIMARY_RESULT
   phase_code: 03_RESULT
   statement_type: RESULT_SELECT
   source_authority: M2_12_PROGRAM_PRIMARY_RESULT_STATEMENT_COMPILER.csv
*/
SELECT
    'PASS'::text AS "preflight_status",
    ctx.run_code::text AS "run_code",
    ctx.run_version::integer AS "run_version",
    ctx.run_status::text AS "run_status",
    r.assertion_rows::integer AS "assertion_rows",
    r.pass_rows::integer AS "assertions_passed",
    19::integer AS "source_edges",
    13::integer AS "component_contracts",
    12::integer AS "certification_nodes",
    72::integer AS "mandatory_evidence_rows",
    20::integer AS "capability_rows",
    'AUTHORIZED_TO_EXECUTE_PROGRAM_222'::text AS "disposition"
FROM tmp_preflight_m2_12_run_context ctx
CROSS JOIN tmp_preflight_m2_12_result r;

/* R10 GOVERNED STATEMENT 0076 OF 0076
   statement_code: COMMIT
   phase_code: 04_COMMIT
   statement_type: TRANSACTION
   source_authority: M2_12_PROGRAM_TRANSACTION_SESSION_SPECIFICATION.csv
*/
COMMIT;

