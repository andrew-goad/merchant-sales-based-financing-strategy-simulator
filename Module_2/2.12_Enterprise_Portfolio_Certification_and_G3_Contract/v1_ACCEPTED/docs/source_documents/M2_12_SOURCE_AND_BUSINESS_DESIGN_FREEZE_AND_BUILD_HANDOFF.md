# Merchant Sales-Based Financing Strategy Simulator
# M2.12 — Enterprise Portfolio Certification & Consumption Contract
## Source & Business Design Freeze — Amendment A Correction R1 Integrated and Ready for Narrow Re-Audit

## 0. Governing status

```text
Document status                         AMENDMENT A CORRECTION R1 INTEGRATED — READY FOR NARROW RE-AUDIT
M2.12 final design freeze               HOLD PENDING RE-AUDIT APPROVAL
M2.12 Work Package 1                    NOT AUTHORIZED
M2.12 SQL generated                     NO
M2.12 build artifacts generated         DESIGN ARTIFACTS ONLY
M2.12 PostgreSQL execution              NOT AUTHORIZED
M2.12 acceptance                        NOT CLAIMED
Accepted M2.11 baseline modified        NO
```

This document incorporates the bounded requirements of
`M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AMENDMENT_A.md` and the physically bounded authority corrections in
`M2_12_SOURCE_AND_BUSINESS_DESIGN_AMENDMENT_A_CORRECTION_R1.md`.

The business purpose and high-level architecture remain locked. Amendment A resolves writer ownership, hash preimages and sequence, complete source lineage, physically testable historical acceptance, evidence applicability, G3 gate atomicity, negative-control reachability, reporting cardinalities, generation-evidence expectations, and build-handoff authority. Correction R1 resolves the ten source-graph physical-authority defects and replaces the mixed-version expected-results artifact.

The separate build chat may not begin Work Package 1 until Amendment A Correction R1 receives explicit narrow re-audit approval.

---

# 1. Authoritative accepted baseline

Use this repository as the sole technical baseline:

```text
M2_11_FULL_PROJECT_ACCEPTED_20260806.zip
SHA-256
92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc

ZIP entries                         4,819
Numbered stages                        30
Final accepted stage              30_M2_11
```

Accepted M2.11 identity:

```text
Run code                           M1_V0_2_BASELINE_BUILD
Run version                        1
Run status                         M2_11_ACCEPTED
Contract status                    ACCEPTED
Acceptance gate                    PASS
Generation evidence                24 / 24 PASS
Positive controls                  120 / 120 PASS
Negative controls                  20 / 20 PASS
Acceptance prerequisites           45 / 45 PASS
Canonical families                 19
Canonical entities                 19,298
Contract set hash                  19f1a9d842c9cb35617ca03e49445aad
Combined set hash                  a67d375b9f9248b3eec8160cf3dc656d
Registry row hash                  61c22f4f3f2e99905d05958fddf80671
Governed evidence exports          38 / 38 PASS
Deterministic mismatches            0
Blocking/stage-boundary findings    0
Stress-improvement violations       0
Latest/archive mismatches           0
```

Repository integrity already accepted:

```text
Accepted predecessor stages        29 / 29 byte-identical
Embedded M2.11 stage               30_M2_11
Standalone versus embedded         BYTE-IDENTICAL
```

The separate build chat must independently calculate the attached full-project ZIP SHA-256 before beginning Work Package 1 and must fail if it differs from the frozen value.

## 1.1 Governing source precedence

```text
1. Accepted M2.11 full-project ZIP and matching accepted-package records
2. This revised M2.12 Source & Business Design Freeze
3. M2.12 Source & Business Design Freeze Amendment A
4. M2.12 Source & Business Design Amendment A Correction R1
5. Every machine-readable M2.12 design catalog listed in the delivery index
6. A later approved M2.12 Work Package 1 implementation specification
7. Approved output of the immediately preceding M2.12 work package
```

The normative design authority set includes Amendment A Correction R1 plus the source/contract inventory, corrected 19-edge source graph, 72-row evidence applicability matrix, hash-preimage specification, acceptance-write specification, capability catalog, regenerated expected-results JSON, generation-evidence catalog, positive-control allocation, negative-control execution specification, acceptance matrix, detail-report catalog, build prompts, and delivery index.

Do not use:

- a partial or failed M2.12 implementation;
- conversational memory in place of accepted physical source;
- superseded M2.11 authority records;
- copied documentation values where physical reconstruction is possible;
- a build chat missing any normative design artifact;
- invented execution results, hashes, counts, control outcomes, or acceptance states.

---

# 2. Roadmap closure decision

The early v0.1 Module 2 charter assigned the label “M2.12” to a regulatory-applicability and compliance package and described collateral, covenants, portfolio allocation, and other capabilities. The accepted as-built roadmap evolved into M2.1 through M2.11 and now explicitly names M2.12 as **Enterprise Portfolio Certification & Consumption Contract**.

The final governing decision is:

```text
Historical v0.1 charter                    PRESERVED AS DESIGN HISTORY
Accepted as-built M2.1-M2.11 chain         AUTHORITATIVE
M2.12 final function                       G3 AS-BUILT CERTIFICATION AND BUNDLE
Retroactive certification of unbuilt scope PROHIBITED
```

M2.12 must not imply that collateral/guarantee packages, covenant packages, jurisdictional or legal compliance certification, production funding allocation, accounting/CECL/capital treatment, or empirical optimization were implemented merely because they appeared in the historical charter. Those boundaries are physically recorded in the frozen 20-row capability-coverage snapshot.

---

# 3. M2.12 identity and lifecycle

```text
Module
M2.12 — Enterprise Portfolio Certification & Consumption Contract

Repository stage
31_M2_12

Methodology
M2_12_METHOD_V1

Policy
M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1

Final bundle
M2_G3_CONSUMPTION_BUNDLE

Bundle version
1

Schema
M2_G3_BUNDLE_SCHEMA_V1

Acceptance gate
G3_M2_CONTRACT
```

The G3 gate already exists in the accepted G0 reference catalog and must be verified—not redefined, inserted, updated, or relabeled—using this complete physical identity:

```text
gate_id       G3_M2_CONTRACT
gate_name     Module 2 Contract
module_code   M2
severity      BLOCKING
active_flag   TRUE
description   Offer contract accepted.
```

The accepted legacy description remains unchanged. The broader M2.12 scope is governed by the M2.12 policy, capability catalog, certification evidence, and acceptance requirements.

Frozen lifecycle:

```text
M2_11_ACCEPTED
→ M2_12_GENERATED
→ M2_12_VALIDATED
→ M2_12_ACCEPTED
```

Bundle registry lifecycle:

```text
GENERATED
→ VALIDATED
→ ACCEPTED
```

Program 220 must not change run status. Program 222 may move the run only to `M2_12_GENERATED`. Program 223 may move it only to `M2_12_VALIDATED`. Program 225 may move it only to `M2_12_ACCEPTED` after every frozen prerequisite passes.

---

# 4. Frozen business question

> Does the accepted M1.17 G2 foundation and the complete accepted M2.1-M2.11 chain form a deterministic, internally consistent, lineage-complete, latest/archive-reproducible, evidence-complete, non-production Module 2 system; what exact as-built capabilities are certified or deferred; and what final composite consumption interfaces may be released for governed downstream planning?

M2.12 is an independent assurance, closure, and contract-publication stage. It is not another strategy, decision, pricing, account, payment, servicing, regulatory, or optimization engine.

---

# 5. Authorized and prohibited scope

## 5.1 M2.12 is authorized to create

- an approved M2.12 certification policy;
- one 12-row accepted source-node certification snapshot;
- one 13-row component-contract inventory snapshot;
- one 72-row stage/evidence certification snapshot;
- one 13-row latest/archive reproduction snapshot;
- one 20-row as-built capability-coverage snapshot;
- one versioned G3 bundle latest row;
- one immutable G3 bundle archive row;
- one G3 bundle registry row;
- explicit read-only application, operational-account, strategy-scope, lineage, and Power BI views;
- deterministic set hashes and a final 134-entity G3 combined hash;
- 24 generation evidence rows;
- 128 positive controls and 20 isolated negative controls;
- one final G3 acceptance evidence row and gate result;
- read-only master and 24-result-set detail reports;
- pre-execution documentation, recovery utilities, and a standalone ready-for-execution package;
- after successful live acceptance only, accepted packaging and the updated full-project repository.

## 5.2 M2.12 must not create, change, execute, or claim

- a new candidate, strategy, score, frontier, decision, offer, price, exposure, account, payment, intervention, or servicing treatment;
- recalculated PD, LGD, EAD, expected loss, economics, KPI, or M2.11 strategy result;
- a production champion or autonomous strategy recommendation;
- production booking, funding, funds movement, bank/ACH/network/processor activity, account update, accounting entry, contact, collection, legal action, notice, or adverse action;
- collateral, guarantee, covenant, regulatory, licensing, legal-form, disclosure, fair-lending, UDAAP, accounting, CECL, capital, or treasury certification;
- causal uplift, empirical optimization, calibrated treatment effect, or statistical generalization;
- Module 3 SQL, execution, acceptance, or production authority;
- mutation of any accepted M1.17 or M2.1-M2.11 business row, latest row, archive row, registry hash, evidence row, or acceptance gate.

---

# 6. Frozen accepted source graph

M2.12 certifies twelve source nodes and thirteen component contracts. It also independently certifies the complete physically accepted source-edge graph.

```text
Source-certification nodes                         12
Component contracts                                13
Required source-identity edges                     19
```

The 19 edges are:

```text
M1.15 → M1.17 component edge                        1
M1.16 → M1.17 component edge                        1
M1.17 → M2.1 through M2.9 → M2.10 linear edges     10
M1.3 → M2.2 auxiliary application edge              1
M1.6 → M2.5 auxiliary scenario edge                 1
M2.11 direct multi-source edges                      5
                                                     --
Total                                               19
```

The exact source and target registries, gates, target source fields, accepted hashes, roles, and certification methods are frozen in `M2_12_SOURCE_GRAPH_EDGE_CATALOG.csv`.

## 6.1 Component inventory

The thirteen component contracts remain frozen in `M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY.csv`. That inventory now also carries:

- exact review version;
- acceptance evidence code;
- accepted registry row hash;
- latest and archive set hashes;
- physically testable historical acceptance method;
- required source-edge codes.

Component totals remain:

```text
Latest rows total         7,129
Archive rows total        7,129
```

## 6.2 Primary linear Module 2 chain

```text
M1.17 G2  7d9e466da28cad2551aa99c4c40c912b
→ M2.1    e5ace7f32060ffb191c7bd0f8dd0c863
→ M2.2    bbe83b187b31ea561789797322031fc6
→ M2.3    bf09349b06ede7e5a2ec830c2f9ffe90
→ M2.4    117450a3eea7bb3d3c74d18cc3c8e96a
→ M2.5    18e1c444aa1b02ee5bd3539d7c477adc
→ M2.6    868125bff29270490cab4d2e55cb1388
→ M2.7    c8e3a472afd2a16b1183677324e9db98
→ M2.8    ab32d80ba20c2c8f0a6ec9ec97c2ed26
→ M2.9    6af76d0059b47623619ebc09330b15fe
→ M2.10   24fca7263a04397ebf21d30639f9069b
```

## 6.3 Auxiliary accepted anchors

```text
M1.3 → M2.2
source gate             M1_3_APPLICATION_REQUEST
source application hash 01485256b9b5748fb412743d35ced602
```

```text
M1.6 → M2.5
source gate             M1_6_MATCHED_SCENARIO_OVERLAYS
source combined hash    3f85921bf6fc30ddc6cee146085e58c5
```

These anchors are source edges, not new certification nodes or component contracts.

## 6.4 M2.11 direct multi-source graph

M2.11 must independently reconcile all five accepted direct inputs:

```text
M1.17 G2    7d9e466da28cad2551aa99c4c40c912b
M2.2        bbe83b187b31ea561789797322031fc6
M2.4        117450a3eea7bb3d3c74d18cc3c8e96a
M2.7        c8e3a472afd2a16b1183677324e9db98
M2.10       24fca7263a04397ebf21d30639f9069b
```

Accepted M2.11 output remains:

```text
Contract set hash   19f1a9d842c9cb35617ca03e49445aad
Combined set hash   a67d375b9f9248b3eec8160cf3dc656d
Registry row hash   61c22f4f3f2e99905d05958fddf80671
```

## 6.5 Physical historical acceptance method

M2.12 does not assume eleven historical run statuses coexist in one mutable run row.

The physically testable acceptance method is:

```text
Current governed run row
M2_11_ACCEPTED

M2.1–M2.11 component registries
11 / 11 ACCEPTED with exact identities

M2.1–M2.11 gates
11 / 11 PASS at review_version 1

M2.1–M2.11 acceptance evidence/provenance
M2_1_ACCEPTANCE_SUMMARY through M2_11_ACCEPTANCE_SUMMARY present

M1.17
separately ACCEPTED registry + G2_M1_CONTRACT PASS + M1_17_ACCEPTANCE_SUMMARY
```

## 6.6 Source canonical certification method

Use the strongest physical method available:

| Source node | Frozen physical certification method |
|---|---|
| M1.17 | Reconstruct the accepted G2 hash chain from `msbf_ctl.v_m1_17_hash_chain` and the G2 registry/latest/archive |
| M2.1–M2.4 | Reconstruct registry fields and component latest/archive identities from accepted physical rows |
| M2.5–M2.10 | Reconcile each accepted canonical-hash view to its registry |
| M2.11 | Aggregate `msbf_m2.v_m2_11_canonical_entity_hash_source` in frozen business-key order and reconcile to the registry |

A copied documentation hash is never sufficient when a physical reconstruction route exists.

---

# 7. Frozen persistent M2.12 object model

## 7.1 Canonical families and writer ownership

| Object | Schema | Grain | Rows | Normal writer |
|---|---|---|---:|---|
| `m2_12_policy_profile` | `msbf_ctl` | run × policy version | 1 | Program 220 |
| `module2_stage_certification_snapshot` | `msbf_m2` | run × certification node | 12 | Program 222 |
| `module2_contract_component_snapshot` | `msbf_m2` | run × component contract | 13 | Program 222 |
| `module2_evidence_certification_snapshot` | `msbf_m2` | run × node × evidence family | 72 | Program 222 |
| `module2_contract_reproduction_snapshot` | `msbf_m2` | run × component contract | 13 | Program 222 |
| `module2_capability_coverage_snapshot` | `msbf_m2` | run × capability | 20 | Program 222 |
| `m2_12_g3_bundle_latest` | `msbf_ctl` | run | 1 | Program 222 |
| `m2_12_g3_bundle_archive` | `msbf_ctl` | run × contract version | 1 | Program 222 |
| `m2_12_g3_bundle_registry` | `msbf_ctl` | run × contract version | 1 | Program 222 |

```text
Program 220 policy writes                      1
Program 222 non-policy canonical writes      133
                                              ---
M2.12 canonical entities                    134
Canonical families                            9
```

Program 222 is the sole normal writer of M2.12 **non-policy certification and G3 canonical rows**.

## 7.2 Policy canonical row

Frozen policy identity:

```text
M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1
policy version 1
status APPROVED
```

The exact configuration payload, configuration-hash method, row-hash preimage, Program 220 rerun behavior, and Program 220A recovery boundary are controlled by Amendment A and `M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION.csv`.

## 7.3 Canonical-count exclusions

The 134 count excludes:

- generation evidence;
- positive and negative control evidence;
- acceptance evidence and gate rows;
- read-only views;
- mutable lifecycle timestamps;
- temporary report or test objects.

## 7.4 Source-scale reference totals

```text
Certified source nodes                     12
Certified component contracts              13
Source graph edges                         19
Component latest rows total             7,129
Component archive rows total            7,129
Sum of stage-local canonical counts     70,821
```

`70,821` is a non-deduplicated reference total and may not be labeled as a merchant, application, account, or strategy population.

---

# 8. Frozen evidence-certification model

Exactly six evidence families apply to every one of the twelve certification nodes:

```text
ACCEPTANCE_LIFECYCLE
POSITIVE_VALIDATION
NEGATIVE_CONTROLS
CANONICAL_IDENTITY
LATEST_ARCHIVE_REPRODUCTION
STAGE_BOUNDARY
```

```text
12 nodes × 6 families                       72
Mandatory PASS rows                         72
PASS_NOT_APPLICABLE permitted rows           0
FAIL rows permitted at G3 acceptance         0
```

Every row must retain:

- node and evidence-family identity;
- `MANDATORY` applicability;
- authoritative source locator or evidence pattern;
- expected and observed count/status;
- expected and observed hash where applicable;
- mismatch count;
- certification status;
- interpretation;
- source registry row hash;
- physical row hash.

The exact node-by-family source, expected value, and rationale are frozen in `M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX.csv`. Implementation may not decide applicability ad hoc.

---

# 9. Frozen component-contract reproduction model

One reproduction row is required for every component contract. It must contain:

- component contract identity and relation names;
- frozen business grain and key-column payload;
- expected and observed latest/archive counts;
- latest set hash and archive set hash;
- exact latest/archive payload mismatch count;
- missing-latest and missing-archive counts;
- duplicate-key counts;
- archive immutability trigger name and status;
- reproduction status;
- source registry and row hashes;
- physical row hash.

Expected component totals:

```text
Latest rows across 13 components      7,129
Archive rows across 13 components     7,129
Latest/archive mismatches                 0
Missing latest rows                       0
Missing archive rows                      0
Duplicate business keys                   0
```

The component contracts retain their own grains. M2.12 does not flatten all 7,129 rows into a new persistent mega-table.

---

# 10. Frozen capability-coverage model

The 20 capability rows are mandatory and canonical. They distinguish implemented as-built scope from deferred or prohibited scope.

| # | Capability | Coverage status | Certifying stage | Boundary |
|---:|---|---|---|---|
| 1 | `M1_G2_APPLICATION_RISK_FOUNDATION` | `IMPLEMENTED_CERTIFIED` | `M1_17_G2_FOUNDATION` | Accepted application, risk, economics, acquisition, evidence, and scenario foundation. |
| 2 | `ELIGIBILITY_POLICY_ROUTING` | `IMPLEMENTED_CERTIFIED` | `M2_1_ELIGIBILITY_ROUTING` | Governed eligibility gates, policy results, reasons, and routing outcomes. |
| 3 | `PRICING_STRUCTURE_COUNTEROFFER` | `IMPLEMENTED_CERTIFIED` | `M2_2_PRICING_STRUCTURE` | Accepted request structures, finite pricing candidates, counteroffer foundations, and scenario results. |
| 4 | `FINAL_OFFER_DECISION_AUTHORIZATION` | `IMPLEMENTED_CERTIFIED_SYNTHETIC` | `M2_3_FINAL_DECISION` | Synthetic final offer and decision authorization evidence only. |
| 5 | `BOOKING_FUNDING_PORTFOLIO_ACTIVATION` | `IMPLEMENTED_BOUNDED_SYNTHETIC` | `M2_4_PORTFOLIO_ACTIVATION` | Synthetic booking, funding, account, advance, and portfolio activation records. |
| 6 | `DAILY_REMITTANCE_EXPOSURE_MONITORING` | `IMPLEMENTED_BOUNDED_SYNTHETIC` | `M2_5_DAILY_MONITORING` | Synthetic daily remittance, exposure, monitoring, alert, and portfolio summaries. |
| 7 | `EARLY_WARNING_INTERVENTION_SERVICING` | `IMPLEMENTED_BOUNDED_RECOMMENDATION` | `M2_6_INTERVENTION_STRATEGY` | Synthetic early-warning and servicing-action recommendations. |
| 8 | `OPERATIONAL_ACTIVATION_ACCOUNT_SETUP` | `IMPLEMENTED_BOUNDED_SYNTHETIC` | `M2_7_OPERATIONAL_ACTIVATION` | Synthetic operational account setup and reassessment evidence. |
| 9 | `SERVICING_PAYMENT_LIFECYCLE_SIMULATION` | `IMPLEMENTED_BOUNDED_SYNTHETIC` | `M2_8_SERVICING_EXECUTION` | Synthetic payment-processing events and lifecycle transitions. |
| 10 | `PAYMENT_RECONCILIATION_ACCOUNT_CERTIFICATION` | `IMPLEMENTED_CERTIFIED_SYNTHETIC` | `M2_9_RECONCILIATION_CERTIFICATION` | Reconciled synthetic payment evidence and certified synthetic account states. |
| 11 | `PORTFOLIO_KPI_SERVICING_ANALYTICS` | `IMPLEMENTED_CERTIFIED_ANALYTICS` | `M2_10_PORTFOLIO_ANALYTICS` | Governed KPI, performance-tier, servicing-queue, exposure, payment, and exception analytics. |
| 12 | `PORTFOLIO_STRATEGY_FRONTIER` | `IMPLEMENTED_CERTIFIED_COMPARATIVE` | `M2_11_STRATEGY_SIMULATION` | Finite deterministic strategy comparison, Pareto frontier, and governance-review priority evidence. |
| 13 | `COLLATERAL_GUARANTEE_PACKAGE` | `DEFERRED_NOT_IMPLEMENTED` | `NONE` | Original charter capability not implemented in the accepted M2.1-M2.11 chain. |
| 14 | `COVENANT_PACKAGE_AND_TESTING` | `DEFERRED_NOT_IMPLEMENTED` | `NONE` | Original charter capability not implemented as a governed covenant package or test framework. |
| 15 | `REGULATORY_APPLICABILITY_LEGAL_COMPLIANCE` | `DEFERRED_NOT_CERTIFIED` | `NONE` | No jurisdiction, licensing, disclosure, legal-form, UDAAP, fair-lending, or regulatory applicability certification. |
| 16 | `PORTFOLIO_FUNDING_BUDGET_ALLOCATION` | `DEFERRED_NOT_IMPLEMENTED` | `NONE` | No production funding-budget, capital-allocation, or concentration-allocation engine. |
| 17 | `PRODUCTION_DECISION_ACCOUNT_PAYMENT_EXECUTION` | `PROHIBITED_NOT_AUTHORIZED` | `NONE` | No production decision, account creation, payment instruction, processor call, or funds movement. |
| 18 | `ACCOUNTING_CECL_CAPITAL_TREASURY` | `DEFERRED_NOT_CERTIFIED` | `NONE` | No GAAP accounting, CECL reserve, economic capital, regulatory capital, or treasury certification. |
| 19 | `EMPIRICAL_CAUSAL_OPTIMIZATION_CHAMPION` | `NOT_SUPPORTED_NOT_AUTHORIZED` | `NONE` | No causal uplift, calibrated treatment effect, autonomous optimization, production champion, or statistical generalization. |
| 20 | `CUSTOMER_MERCHANT_NOTICE_ADVERSE_ACTION` | `PROHIBITED_NOT_AUTHORIZED` | `NONE` | No merchant-facing offer, notice, adverse-action communication, collection notice, or legal communication. |

The machine-readable catalog is supplied as `M2_12_CAPABILITY_COVERAGE_CATALOG.csv`.

G3 acceptance must fail if any deferred or prohibited capability is relabeled as implemented/certified or if any production-action or legal-certification flag becomes true.

---

# 11. Final consumption interfaces

M2.12 publishes multiple explicit read-only views because the accepted system contains different valid grains. It must not collapse those grains into one ambiguous table.

## 11.1 Application origination consumption

```text
msbf_m2.v_m2_12_application_origination_consumption
```

Frozen grain:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
```

Expected posture:

```text
Rows                      1,500
Distinct applications       750
BASELINE rows                750
RECESSION_ENERGY rows        750
Orphans                        0
Multiplicative joins           0
```

Use `msbf_m1.v_m1_17_g2_integrated_consumption` as the 1,500-row base. Join:

- M2.1 eligibility/routing latest filtered to accepted campaign `M2_1_CONTROLLED_ENTRY_BASELINE`, then joined on run + scenario + application;
- M2.2 request latest on run + application;
- M2.2 pricing latest on run + scenario + application;
- M2.3 final decision latest on run + scenario + application;
- M2.4 activation latest on run + scenario + application.

Explicit field groups:

1. run, population, scenario, merchant, application, and as-of identity;
2. accepted M1.17 risk, expected-loss, unit-economics, acquisition, and evidence fields needed for downstream interpretation;
3. M2.1 eligibility/routing outcome, gate posture, route, and reason evidence;
4. M2.2 request structure, pricing disposition, candidate/selected structure, counteroffer, price, burden, and contract lineage;
5. M2.3 final offer/decision outcome, authorization flags, review/decline posture, and reasons;
6. M2.4 synthetic activation, booked/funded amount, account/advance IDs, activation disposition, and non-production flags;
7. source contract codes, versions, schema versions, contract row hashes, and stage combined hashes.

Every projection must be explicit. `SELECT *` is prohibited.

## 11.2 Operational account consumption

```text
msbf_m2.v_m2_12_operational_account_consumption
```

Frozen grain:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
+ synthetic_account_id
+ synthetic_advance_id
```

Expected posture:

```text
Rows                          59
BASELINE rows                  44
RECESSION_ENERGY rows          15
Distinct operational apps      44
Orphans                         0
Multiplicative joins            0
```

Use the 59 activated M2.4 rows as the bounded account population and join M2.5 through M2.10 accepted latest contracts using the full available account/advance/application lineage. The view must expose:

- activation and funded structure;
- daily monitoring, remittance, exposure, status, and alert posture;
- early-warning/intervention outcome and recommended servicing action;
- operational setup and reassessment fields;
- servicing-execution outcome, payment-event totals, and final lifecycle state;
- reconciliation, exception-resolution, certification, and certified exposure;
- M2.10 performance tier, servicing queue, burden units, KPI posture, and contract lineage;
- every source contract row hash used in the join;
- explicit synthetic/non-production flags.

No account may be fabricated for an application that lacks an accepted operational account.

## 11.3 Strategy-scope consumption

```text
msbf_m2.v_m2_12_strategy_scope_consumption
```

Frozen grain:

```text
module1_run_id
+ strategy_profile_code
+ reporting_scope_code
```

Expected posture:

```text
Rows                         24
Strategies                    8
Scopes                        3
Frontier-eligible rows       18
Non-dominated rows           16
Frontier-rank-1 rows         16
Primary review assignments    3
Stress-improvement violations 0
```

Use `msbf_m2.portfolio_strategy_simulation_latest` as the base and append G3 certification metadata. Preserve all M2.11 strategy, objective, constraint, burden-coverage, baseline-delta, frontier, governance-priority, reason, and lineage fields.

Accepted primary governance-review assignments are source evidence to preserve:

```text
BASELINE             BALANCED_FRONTIER
RECESSION_ENERGY     PRICE_FOR_RISK
PORTFOLIO            PRICE_FOR_RISK
```

They must always be labeled governance-review priorities—not champions, approvals, or deployment decisions.

## 11.4 Lineage views

```text
msbf_ctl.v_m2_12_stage_lineage              12 rows
msbf_ctl.v_m2_12_component_contract_lineage 13 rows
msbf_ctl.v_m2_12_g3_lineage                  1 row
```

## 11.5 Power BI / executive consumption

```text
msbf_m2.v_m2_12_power_bi_enterprise_portfolio
```

Grain: 24 strategy/scope rows with G3 certification and source-boundary metadata. Application and operational-account views remain separate data sources and must not be joined into this view at incompatible grains.

---

# 12. G3 bundle latest, archive, and registry

## 12.1 Latest

```text
msbf_ctl.m2_12_g3_bundle_latest
```

Unique key:

```text
module1_run_id
```

Required contents include:

- bundle identity, schema, method, gate, run code/version/as-of date;
- accepted M1.17 G2 and M2.11 anchor identities and hashes;
- 12 source-node, 13 component, 72 evidence, 13 reproduction, and 20 capability counts;
- 1,500 application-view, 59 operational-account-view, and 24 strategy-view counts;
- 7,129 component latest and 7,129 component archive totals;
- 70,821 stage-local canonical reference total with explicit non-deduplicated label;
- all-stage, all-component, all-evidence, and all-boundary pass flags;
- as-built certification scope code;
- residual limitations and deferred-capability payload;
- no-production, no-PII, no-legal-certification, no-deployment, and no-Module-3-execution flags;
- source set hashes, row hash, and contract row hash.

## 12.2 Archive

```text
msbf_ctl.m2_12_g3_bundle_archive
```

Unique key:

```text
module1_run_id
+ contract_version
```

The archive contains the exact version-1 latest payload excluding reporting-only creation timestamps, the same contract row hash, a deterministic archive row hash, and an immutable `BEFORE UPDATE OR DELETE` trigger.

## 12.3 Registry

```text
msbf_ctl.m2_12_g3_bundle_registry
```

Unique key:

```text
module1_run_id
+ contract_version
```

The registry stores stable identity, source-authority, expected/observed count, lifecycle, and derived hash fields.

Its row hash excludes:

```text
registry_id
all lifecycle statuses and timestamps
row_hash itself
all nine family set hashes
contract_set_hash
combined_set_hash
```

Programs 223 and 225 may update only mutable lifecycle status/timestamp fields under explicit predicates. They may not change canonical counts, source identities, family hashes, registry row hash, contract set hash, combined hash, latest, or archive values.

---

# 13. Deterministic hash architecture

The complete field-level authority is `M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION.csv`.

Frozen acyclic sequence:

```text
1 target-type coercion
2 all non-registry row hashes
3 eight non-registry family set hashes
4 registry row hash
5 registry set hash
6 contract set hash
7 ordered 134-entity combined hash
8 independent physical reconstruction before commit
```

Nine canonical family ordered keys:

| Family | Ordered business key |
|---|---|
| POLICY | policy code + policy version |
| STAGE_CERTIFICATION | node sequence + stage code |
| CONTRACT_COMPONENT | component sequence + contract code + version |
| EVIDENCE_CERTIFICATION | node sequence + evidence-family sequence |
| CONTRACT_REPRODUCTION | component sequence + contract code + version |
| CAPABILITY_COVERAGE | capability sequence + capability code |
| LATEST | bundle code + version |
| ARCHIVE | bundle code + version |
| REGISTRY | bundle code + version |

Registry row-hash exclusions include the generated identity, all mutable lifecycle fields/timestamps, the registry row hash itself, all nine family set hashes, `contract_set_hash`, and `combined_set_hash`.

The frozen contract-set preimage order is:

```text
bundle identity
policy configuration hash
nine family set hashes
latest contract row hash
archive copied contract row hash
registry row hash
accepted M2.11 contract set hash
accepted M2.11 combined set hash
accepted M2.11 registry row hash
```

The final combined hash remains:

```text
md5(
  string_agg(
    entity_type || '|' || entity_key || '|' || row_hash,
    '|' ORDER BY entity_type, entity_key
  )
)
```

Database identities use lowercase 32-character MD5. File integrity uses SHA-256.

---

# 14. Generation evidence — exactly 24 rows

Program 222 writes exactly 24 passing generation-evidence rows only after physical reconciliation succeeds.

The catalog is frozen in `M2_12_GENERATION_EVIDENCE_CATALOG.csv` and includes:

```text
01–09  Nine canonical-family set hashes, including REGISTRY_SET_HASH
10     Contract set hash
11     Combined set hash
12–17  Canonical family/count controls
18     Combined component latest/archive total = 7129|7129
19     Application consumption = 1500|750|750|750
20     Operational consumption = 59|44|44|15
21     Strategy scope = 24|8|3|3
22     Source graph = 19|0
23     Deterministic mismatches = 0
24     Blocking/stage-boundary findings = 0
```

Every catalog row specifies the authoritative source, calculation, expected value, comparison operator, ordering, observed-value format, interpretation, and blocking status.

The total remains:

```text
Generation evidence      24 / 24 PASS
Acceptance evidence       1 after Program 225
```

---

# 15. Positive validation — exactly 128 controls

Program 223 must contain exactly 128 substantive controls allocated as follows:

| Control family | Controls |
|---|---:|
| Run, policy, bundle, method, schema, gate identity | 10 |
| Twelve source-node lifecycle, registry, and gate controls | 24 |
| Thirteen component-contract identity and count controls | 26 |
| Evidence-certification completeness and status | 12 |
| Thirteen latest/archive reproduction controls | 13 |
| Linear chain and M2.11 multi-source graph | 12 |
| Application, account, strategy, and lineage consumption views | 12 |
| M2.11 frontier, priority, stress, and burden-coverage boundary | 7 |
| Capability coverage, non-production, and deferred-scope boundaries | 6 |
| Canonical families, archive, registry, contract, and combined hashes | 6 |
| **Total** | **128** |

Requirements:

- reconstruct critical identities independently from persisted physical rows;
- do not simply call Program 222 helper expressions and label agreement independent;
- preserve user-facing results in a filterable `ON COMMIT PRESERVE ROWS` relation;
- persist positive evidence only after all 128 controls are internally reconciled;
- report every failed control code, observed value, threshold, and interpretation;
- transition to `M2_12_VALIDATED` only when 128/128 pass.

---

# 16. Negative controls — exactly 20

Program 224 implements exactly the same 20 frozen control codes. The controlling execution specification is `M2_12_NEGATIVE_CONTROL_CATALOG_DESIGN.csv`.

For every control the catalog freezes:

- mutation target;
- exact injected defect;
- intended physical constraint, trigger, or assertion;
- expected SQLSTATE;
- expected message prefix;
- reachability preconditions;
- rollback/isolation method;
- identity-sequence handling;
- required before/after fingerprint;
- source authority and traceability.

Allowed isolation:

```text
temporary fixture without accepted-source DML

or

BEGIN
→ SAVEPOINT
→ expected rejection
→ ROLLBACK TO SAVEPOINT
→ postflight
→ final ROLLBACK
```

Every test must leave unchanged:

```text
nine canonical family counts
134 physical row hashes
nine ordered family set hashes
latest/archive identity
registry row hash
contract set hash
combined hash
all M2.12-owned identity sequence states
```

Exactly three M2.12-owned sequences exist:

```text
msbf_ctl.m2_12_policy_profile_policy_profile_id_seq
msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq
msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq
```

The five snapshot canonical families and `msbf_ctl.m2_12_g3_bundle_latest` use composite business keys and **no sequence-backed surrogate identity**. For each negative control, the catalog must state `NO_OWNED_SEQUENCE` when its action cannot invoke one of the three sequences. Every postflight fingerprint must still reconcile `last_value` and `is_called` for all three sequences exactly.

No negative test may commit or weaken a valid control.

---

# 17. Acceptance finalizer — 48 frozen prerequisites

Program 225 implements all 48 rows in `M2_12_ACCEPTANCE_REQUIREMENT_MATRIX.csv`.

```text
Requirements 001–047    PRE_WRITE
Requirement 048         POST_WRITE_ATOMICITY
```

Pre-write requirements use physical, testable historical acceptance:

```text
current run                         M2_11_ACCEPTED
M2.1–M2.11 registries               11/11 ACCEPTED
M2.1–M2.11 gates                    11/11 PASS, review_version 1
M1.17 G2                            separately ACCEPTED/PASS
acceptance evidence/provenance      present
```

Before any write, Program 225 requires:

```text
zero prior G3 gate result rows for review_version 1
zero prior M2_12_ACCEPTANCE_SUMMARY evidence rows
47/47 PRE_WRITE requirements PASS
```

It then atomically writes:

```text
G3 gate
gate_id          G3_M2_CONTRACT
review_version   1
result_status    PASS

Acceptance evidence
evidence_code    M2_12_ACCEPTANCE_SUMMARY
segment_key      ENTERPRISE_PORTFOLIO_G3
metric_name      G3_ACCEPTANCE_STATUS
metric_value     M2_12_ACCEPTED|ACCEPTED|PASS|48/48
status           PASS
```

and performs only the permitted run/registry lifecycle transitions.

Requirement 048 then proves:

- exactly one gate and one acceptance evidence row;
- run `M2_12_ACCEPTED`;
- registry `ACCEPTED`;
- immutable pre-write and post-write fingerprints are identical.

The exact transaction phases are frozen in `M2_12_ACCEPTANCE_WRITE_PHASE_SPECIFICATION.csv`. Any failure rolls back the complete transaction. A committed version-1 rerun fails closed.

---

# 18. Program architecture

Normal chain:

```text
220  Schema, Policy, Certification Structures, G3 Bundle, Triggers and Views
221  Accepted-Source and Pristine-Target Preflight
222  End-to-End Certification Generation and Physical Reconciliation
223  Positive Validation
224  Negative Controls
225  G3 Acceptance Finalizer
226  Master Report
227  Detailed Report
```

Recovery/contingency only:

```text
220A  Failed Schema/Policy Installation Recovery
222A  Failed Pre-Commit Certification Rollback Recovery
222B  Committed Certification Checkpoint Reconstruction
223A  Failed Positive-Validation Recovery
```

## 18.1 Program 220

Program 220 may install:

- physical structures, functions, constraints, indexes, comments, assertions, archive trigger, and read-only views;
- exactly one approved policy canonical row;
- verification—not insertion or update—of the exact existing `G3_M2_CONTRACT` catalog row.

It may not write any of the remaining 133 canonical rows or change run status.

## 18.2 Program 221

Persistent-state read-only and fail-closed. It verifies:

- accepted M2.11 baseline identity;
- 12 nodes and 13 components;
- all 19 source edges;
- physically testable historical acceptance;
- all 72 mandatory evidence-certification specifications;
- exact G3 gate identity;
- latest/archive counts, grains, triggers, and hashes;
- M2.11 frontier/priority/stress/burden boundaries;
- source columns and join keys for three final consumption interfaces;
- one exact installed policy row;
- pristine non-policy targets, evidence, and gate rows;
- zero premature Module 3 objects.

A blocking failure must raise.

## 18.3 Program 222

Program 222 is the sole normal writer of 133 non-policy canonical rows:

```text
12 stage certification
13 component contracts
72 evidence certification
13 contract reproduction
20 capability coverage
1 G3 latest
1 G3 archive
1 G3 registry
= 133
```

It must:

- run atomically;
- materialize every accepted physical source object once;
- target-type, index, and analyze staged sources;
- consume staged sources only;
- certify all 19 edges;
- construct the three consumption interfaces;
- execute the acyclic hash sequence;
- independently reconstruct expected versus physical identities;
- insert 24 generation evidence rows after reconciliation;
- move lifecycle only to `M2_12_GENERATED`;
- fail closed on version-1 rerun.

## 18.4 Program 223

Reads persisted state only, independently reconstructs all 128 controls, and transitions only to `M2_12_VALIDATED` after 128/128 PASS.

## 18.5 Program 224

Executes the 20 expanded isolated negative controls and leaves lifecycle `M2_12_VALIDATED`.

## 18.6 Program 225

Executes Requirements 001–047 pre-write and Requirement 048 post-write atomically. It performs only permitted gate/evidence/lifecycle writes.

## 18.7 Programs 226 and 227

Run in ordinary transactions with persistent-state read-only behavior. They may create, populate, index, analyze, and drop only `tmp_report_` temporary objects. They may not perform persistent DML or persistent DDL.

---

# 19. Master report requirements

Program 226 must produce one concise governed row containing:

- M2.12 identity and lifecycle;
- M1.17 G2 and M2.11 final source anchors;
- 12/13/72/13/20/134 counts;
- 1,500/59/24 consumption-interface counts;
- 7,129 latest and 7,129 archive totals;
- final set hashes, contract hash, combined hash, and registry hash;
- 128/128, 20/20, 24/24, 48/48, and one acceptance row;
- zero chain, reproduction, deterministic, boundary, and capability-overclaim findings;
- M2.11 frontier/priorities as comparative governance evidence;
- capability coverage summary;
- as-built synthetic acceptance scope;
- explicit no-production, no-legal-certification, no-champion, and no-Module-3-execution boundaries.

It must not call a strategy “optimal,” “approved,” “champion,” or “deployed.”

---

# 20. Detailed report — exactly 24 result sets

Program 227 produces exactly 24 result sets with these successful row counts:

```text
01 1       02 1       03 1       04 12
05 13      06 19      07 72      08 13
09 13      10 3       11 1500    12 3
13 59      14 24      15 24      16 3
17 8       18 20      19 1       20 1
21 12      22 6       23 0       24 0
```

Result Set 11 is full 1,500-row application detail, not a sample.

Result Set 13 is full 59-row operational-account detail.

Result Sets 23 and 24 retain explicit stable headers and return zero rows on success.

The authoritative source, grain, projection, deterministic `ORDER BY`, and zero-row behavior for every result set are frozen in `M2_12_DETAIL_RESULT_SET_CATALOG.csv`.

---

# 21. Engineering and performance standards

The separate build chat must enforce:

- PostgreSQL `numeric`, never floating-point, for counts/rates/amounts that participate in governed identities;
- explicit physical types and typmods;
- explicit persistent `INSERT` target columns and explicit source projections;
- no persistent `SELECT *`;
- no `CREATE TABLE ... LIKE` for target-typed staging;
- one materialization per accepted source object in Program 222;
- no repeated scans of accepted source tables after staging;
- materialize expensive joins once;
- index and `ANALYZE` before downstream joins or aggregations;
- window functions instead of unnecessary self-joins;
- explicit business-key `ORDER BY` in every set/combined hash;
- no reliance on database row order;
- separate persisted generation from validation and reporting;
- elite program headers, purposes, source boundaries, writes, required results, and section navigation;
- stop at the first error, execute one program at a time, and run `ROLLBACK` before directed recovery;
- recovery programs never appear in the normal execution chain;
- successful committed upstream programs are never rerun to fix downstream-only defects.

---

# 22. Five-work-package build process

The implementation process remains divided into five explicit review boundaries:

```text
WP1  Freeze consolidation, source inspection, and implementation specification
WP2  Programs 220–222 and Recoveries 220A/222A/222B
WP3  Programs 223–224 and Recovery 223A
WP4  Programs 225–227
WP5  Documentation and standalone ready-for-execution package
```

The build chat must receive every normative artifact listed in the delivery index.

At the end of each work package, it must stop and report work, files, static validation, blockers, and whether the next package is recommended.

```text
Current authorization
WP1 NOT AUTHORIZED pending narrow re-audit approval of Amendment A Correction R1
```

No work package may begin automatically or work ahead.

---

# 23. WP1 approval standard

After Amendment A Correction R1 receives explicit narrow re-audit approval, Work Package 1 may be authorized only if all normative artifacts are attached and it proves:

```text
Accepted ZIP/sidecar mismatch                 0
Frozen business semantics changed             0
Unresolved source objects                     0
Unmapped required source fields               0
Unresolved latest/archive keys                0
Source graph edges not mapped                 0
Evidence applicability ambiguity              0
Hash preimage/order ambiguity                 0
Acceptance write-phase ambiguity              0
Negative-control reachability ambiguity       0
Reporting cardinality/projection ambiguity    0
Canonical-count discrepancy                   0
Program-boundary ambiguity                    0
Capability-coverage ambiguity                 0
```

WP1 remains implementation control, not another business-design exercise.

---

# 24. Pre-execution and post-acceptance packaging boundaries

Before live execution, Work Package 5 may produce only:

```text
M2.12 standalone execution package
READY FOR LIVE EXECUTION
NOT EXECUTED
NOT ACCEPTED
```

It must not produce:

- an updated full-project accepted ZIP;
- accepted status;
- fabricated evidence exports;
- final accepted hashes;
- Module 3 authorization;
- production deployment claims.

After successful live execution, evidence review, and formal M2.12 acceptance, accepted packaging must:

- create stage `31_M2_12`;
- preserve all 30 predecessor stages byte-for-byte;
- prove standalone/embedded M2.12 identity;
- rebuild root and stage inventories, manifests, and SHA-256 files after final writes;
- validate ZIP CRC, complete extraction, source/archive hashes, duplicates, unsafe paths, Windows-reserved paths, and path length;
- update current project status to M2.12/G3 accepted;
- retain superseded M2.12-ready next-step records as history;
- authorize Module 3 **source and business design planning only**.

---

# 25. Module 3 handoff boundary

A successful `G3_M2_CONTRACT` gate closes Module 2 only within the documented as-built synthetic governance scope.

After M2.12 acceptance:

```text
Module 3 source/business design planning   AUTHORIZED
Module 3 SQL construction                  NOT AUTHORIZED
Module 3 PostgreSQL execution              NOT AUTHORIZED
Production deployment                      NOT AUTHORIZED
```

M2.12 does not define or build the Module 3 roadmap. That requires a separately governed source/business design.

---

# 26. Final amended freeze declaration

```text
Accepted M2.11 baseline                         LOCKED
M2.12 business purpose                          LOCKED
M2.12 stage/method/policy/bundle/schema codes  LOCKED
Twelve source nodes                             LOCKED
Thirteen component contracts                    LOCKED
Nineteen source-graph edges                     LOCKED
Physical historical acceptance method          LOCKED
Nine persistent canonical families              LOCKED
Program 220 policy row                           1
Program 222 non-policy canonical rows          133
Canonical entity count                         134
Seventy-two mandatory PASS evidence rows        LOCKED
Twenty capability rows                          LOCKED
Three final consumption views                   LOCKED
Acyclic hash preimages and sequence             LOCKED
Nine family set hashes                          LOCKED
128 positive controls                           LOCKED
20 negative-control execution specifications    LOCKED
24 generation evidence rows                     LOCKED
48 phased acceptance requirements               LOCKED
24 fixed-cardinality detailed result sets       LOCKED
Programs 220–227                                LOCKED
Recovery boundaries                             LOCKED
G3 atomic write and rerun behavior              LOCKED
Non-production and no-overclaim boundary        LOCKED
Module 3 handoff                                LOCKED

Amendment A Correction R1 status                READY FOR NARROW RE-AUDIT
Final design freeze                             HOLD PENDING RE-AUDIT APPROVAL
Work Package 1                                 NOT AUTHORIZED
SQL generated                                  NO
PostgreSQL executed                            NO
Accepted baseline modified                     NO
Module 3 authorized                            NO
Production authorized                          NO
```

Stop after Amendment A Correction R1 and wait for explicit narrow re-audit approval.
