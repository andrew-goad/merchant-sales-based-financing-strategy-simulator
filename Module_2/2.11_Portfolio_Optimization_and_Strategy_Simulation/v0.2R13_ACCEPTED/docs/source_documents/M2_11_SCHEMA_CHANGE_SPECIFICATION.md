# Schema change specification

The current physical catalog contains 44 governed objects: nineteen canonical families, accepted/shared sources, four read-only views, two hash helpers and two archive-immutability controls.

| # | Role | Object | Type | Governed grain | Expected rows | Writer | Mutation rule |
|---|---|---|---|---|---|---|---|
| 1 | ACCEPTED_SOURCE_AND_SHARED_GOVERNANCE | msbf_ctl.run_registry | TABLE | One governed run | 1 governed run | 214/215/217 | READ SOURCE IDENTITY; UPDATE STATUS/TIMESTAMPS ONLY AT FROZEN TRANSITIONS |
| 2 | ACCEPTED_SOURCE_AND_SHARED_GOVERNANCE | msbf_ctl.acceptance_gate_result | TABLE | Run × gate × review version | 5 accepted predecessor gate rows; 1 M2.11 row only at acceptance | 217 | PREDECESSOR ROWS READ ONLY; INSERT ONE M2.11 ACCEPTANCE ROW |
| 3 | ACCEPTED_SOURCE | msbf_ctl.m2_10_portfolio_analytics_contract_registry | TABLE | One accepted M2.10 contract per run | 1 | NONE | READ_ONLY |
| 4 | ACCEPTED_SOURCE | msbf_m2.application_portfolio_performance_latest | TABLE | Run × scenario × operational-account row | 59 | NONE | READ_ONLY |
| 5 | ACCEPTED_SOURCE | msbf_m2.portfolio_kpi_snapshot | TABLE | Run × source scope × KPI | 72 | NONE | READ_ONLY |
| 6 | ACCEPTED_SOURCE | msbf_m2.servicing_queue_analytics_snapshot | TABLE | Run × servicing queue | 3 | NONE | READ_ONLY |
| 7 | ACCEPTED_SOURCE | msbf_ctl.m1_17_g2_bundle_registry | TABLE | One accepted G2 bundle per run | 1 | NONE | READ_ONLY |
| 8 | ACCEPTED_SOURCE | msbf_m1.v_m1_17_g2_integrated_consumption | VIEW | Run × scenario × application | 1,500 | NONE | READ_ONLY |
| 9 | ACCEPTED_SOURCE | msbf_ctl.m2_2_pricing_structure_contract_registry | TABLE | One accepted M2.2 contract per run | 1 | NONE | READ_ONLY |
| 10 | ACCEPTED_SOURCE | msbf_m2.application_pricing_structure_latest | TABLE | Run × scenario × application | 1,500 | NONE | READ_ONLY |
| 11 | ACCEPTED_SOURCE | msbf_m2.application_pricing_structure_candidate | TABLE | Run × scenario × application × candidate template | 557 | NONE | READ_ONLY |
| 12 | ACCEPTED_SOURCE | msbf_ctl.m2_4_portfolio_activation_contract_registry | TABLE | One accepted M2.4 contract per run | 1 | NONE | READ_ONLY |
| 13 | ACCEPTED_SOURCE | msbf_m2.application_booking_funding_activation_latest | TABLE | Run × scenario × application | 1,500 | NONE | READ_ONLY |
| 14 | ACCEPTED_SOURCE | msbf_ctl.m2_7_operational_activation_contract_registry | TABLE | One accepted M2.7 contract per run | 1 | NONE | READ_ONLY |
| 15 | ACCEPTED_SOURCE | msbf_m2.application_operational_activation_latest | TABLE | Run × scenario × operational-account row | 59 | NONE | READ_ONLY |
| 16 | M2_11_CANONICAL | msbf_ctl.m2_11_policy_profile | TABLE | Run | 1 | 212 | INSERT ONCE INTO PRISTINE TARGET; FAIL ON EXISTING MISMATCH |
| 17 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_profile | TABLE | Run × strategy | 8 | 212 | INSERT ONCE INTO PRISTINE TARGET; FAIL ON EXISTING MISMATCH |
| 18 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_objective_definition | TABLE | Run × objective | 8 | 212 | INSERT ONCE INTO PRISTINE TARGET; FAIL ON EXISTING MISMATCH |
| 19 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_constraint_definition | TABLE | Run × constraint | 12 | 212 | INSERT ONCE INTO PRISTINE TARGET; FAIL ON EXISTING MISMATCH |
| 20 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_reason_definition | TABLE | Run × reason | 32 | 212 | INSERT ONCE INTO PRISTINE TARGET; FAIL ON EXISTING MISMATCH |
| 21 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_application_source_snapshot | TABLE | Run × scenario × application | 1,500 | 214 | INSERT ONCE; NO REGENERATION |
| 22 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_candidate_source_snapshot | TABLE | Run × scenario × application × candidate template | 557 | 214 | INSERT ONCE; NO REGENERATION |
| 23 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_account_source_snapshot | TABLE | Run × scenario × operational account | 59 | 214 | INSERT ONCE; NO REGENERATION |
| 24 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_kpi_source_snapshot | TABLE | Run × source scope × KPI | 72 | 214 | INSERT ONCE; NO REGENERATION |
| 25 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_queue_source_snapshot | TABLE | Run × servicing queue | 3 | 214 | INSERT ONCE; NO REGENERATION |
| 26 | M2_11_CANONICAL | msbf_m2.application_strategy_candidate_evaluation | TABLE | Accepted candidate source row × strategy | 4,456 | 214 | INSERT ONCE; NO REGENERATION |
| 27 | M2_11_CANONICAL | msbf_m2.application_portfolio_strategy_simulation | TABLE | Run × scenario × application × strategy | 12,000 | 214 | INSERT ONCE; NO REGENERATION |
| 28 | M2_11_CANONICAL | msbf_m2.account_servicing_strategy_simulation | TABLE | Run × scenario × operational account × strategy | 472 | 214 | INSERT ONCE; NO REGENERATION |
| 29 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_summary | TABLE | Run × strategy × reporting scope | 24 | 214 | INSERT ONCE; NO REGENERATION |
| 30 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_frontier | TABLE | Run × strategy × reporting scope | 24 | 214 | INSERT ONCE; NO REGENERATION |
| 31 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_comparison | TABLE | Run × challenger strategy × reporting scope | 21 | 214 | INSERT ONCE; NO REGENERATION |
| 32 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_simulation_latest | TABLE | Run × strategy × reporting scope | 24 | 214 | INSERT ONCE FOR VERSION 1; LATEST BUSINESS VALUES IMMUTABLE IN 215–219 |
| 33 | M2_11_CANONICAL | msbf_m2.portfolio_strategy_simulation_archive | TABLE | Run × contract version × strategy × reporting scope | 24 | 214 | INSERT ONCE; UPDATE/DELETE ALWAYS REJECTED |
| 34 | M2_11_CANONICAL | msbf_ctl.m2_11_portfolio_strategy_contract_registry | TABLE | Run × contract version | 1 | 214 | INSERT ONCE; PROGRAMS 215/217 MAY UPDATE ONLY FROZEN LIFECYCLE FIELDS/TIMESTAMPS |
| 35 | SHARED_GOVERNANCE | msbf_ref.acceptance_gate_catalog | TABLE | Gate definition | 1 M2.11 definition | 212 | INSERT ONCE OR VERIFY EXACT EXISTING DEFINITION |
| 36 | SHARED_GOVERNANCE | msbf_ctl.run_evidence | TABLE | Run × evidence code × segment key | 165 M2.11 rows: 24 + 120 + 20 + 1 | 214/215/216/217 | INSERT ONLY BY AUTHORIZED PROGRAM; NO GENERIC REPLACEMENT |
| 37 | READ_ONLY_VIEW | msbf_m2.v_m2_11_portfolio_strategy_simulation_latest | VIEW | Derived | Derived | 212 | READ_ONLY |
| 38 | READ_ONLY_VIEW | msbf_ctl.v_m2_11_portfolio_strategy_lineage | VIEW | Derived | Derived | 212 | READ_ONLY |
| 39 | READ_ONLY_VIEW | msbf_m2.v_m2_11_matched_application_stress_comparison | VIEW | Derived | Derived | 212 | READ_ONLY |
| 40 | READ_ONLY_VIEW | msbf_m2.v_m2_11_canonical_entity_hash_source | VIEW | Derived | Derived | 212 | READ_ONLY |
| 41 | DETERMINISTIC_HASH_HELPER | msbf_ctl.m2_11_hash_jsonb | FUNCTION | One jsonb payload | N/A | 212 | CREATE OR REPLACE IN 212; EXACT SIGNATURE/BODY/BEHAVIOR VERIFIED BY 213 |
| 42 | DETERMINISTIC_HASH_HELPER | msbf_ctl.m2_11_registry_row_hash | FUNCTION | One registry jsonb payload | N/A | 212 | CREATE OR REPLACE IN 212; EXACT SIGNATURE/BODY/BEHAVIOR VERIFIED BY 213 |
| 43 | IMMUTABILITY_CONTROL | msbf_ctl.m2_11_block_archive_mutation | FUNCTION | N/A | N/A | 212 | FUNCTION BODY IMMUTABLE AFTER INSTALL |
| 44 | IMMUTABILITY_CONTROL | msbf_m2.trg_m2_11_archive_immutable | TRIGGER | Per archive row | N/A | 212 | ALWAYS RAISE EXCEPTION |

The complete source of truth is `04_catalogs/schema/M2_11_PHYSICAL_OBJECT_CATALOG.csv`. The nineteen canonical families reconcile to 19,298 entities; helper functions, views, evidence and acceptance-gate rows are not added to that canonical count.
