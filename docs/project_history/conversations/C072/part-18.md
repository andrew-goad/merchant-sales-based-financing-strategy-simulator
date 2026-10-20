# PostgreSQL M1.14 Execution

Part 18 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-17.md)
[Next part](part-19.md)

<a id="m-d602c64a-749c-4997-bb08-0e160453259b"></a>
## Assistant · C072-M00246

C072-M00246 · 2026-08-07T06:30:09.821901-04:00 · active path

Preceding visible parent: [C072-M00245](part-17.md#m-fc72a75e-535d-4898-8a8c-b96621678147)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Source & Business Design audit determination

**HOLD — the M2.12 business purpose and high-level architecture are sound, but the design is not yet sufficiently complete to be treated as “FINAL AND LOCKED.” A bounded Source & Business Design Freeze Amendment A is required before Work Package 1 begins.**

```text
Accepted M2.11 baseline                    PASS / LOCKED
M2.12 business purpose                     PASS
M2.12 as-built capability boundary         PASS
M2.12 high-level object/count architecture PASS

M2.12 final design freeze                  HOLD — AMENDMENT A REQUIRED
M2.12 Work Package 1                       NOT AUTHORIZED
M2.12 SQL construction                     NOT AUTHORIZED
M2.12 PostgreSQL execution                 NOT AUTHORIZED
Module 3                                   NOT AUTHORIZED
Production deployment                      NOT AUTHORIZED
```

The hold does **not** require redesigning M2.12. It requires resolving several implementation-affecting contradictions and completing the control specifications before the implementation chat is allowed to translate the design into SQL.

## Independent artifact verification

I independently verified:

```text
Accepted M2.11 ZIP SHA-256
92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc

Sidecar reconciliation                     PASS
ZIP CRC                                     PASS
ZIP entries                                 4,819
Numbered stages                             30
Final accepted stage                        30_M2_11
```

The baseline contains the accepted M2.11 status, 19,298 canonical entities, 120 positive controls, 20 negative controls, 45 acceptance prerequisites, and the final contract, combined, and registry identities. [export reference: filecite | turn129file2 | L301-L347]

I also recalculated the hashes of all ten indexed M2.12 design deliverables and the delivery index itself. Every hash matches the published delivery record. The machine-readable catalogs reconcile mechanically:

```text
Source-contract inventory rows              13
Unique source-certification nodes           12
Capability rows                             20
Generation evidence rows                    24
Positive-control families                   10
Positive controls allocated                128
Negative controls                           20
Acceptance requirements                     48
Detailed result sets                        24

Sequence gaps                                0
Duplicate codes                              0
Component latest rows                    7,129
Component archive rows                   7,129
Stage-local canonical reference total    70,821
```

The delivery index records those same governing counts and artifact hashes. [export reference: filecite | turn120file2 | L5-L16]

## Audit disposition by area

| Review area | Result | Conclusion |
|---|---|---|
| Accepted M2.11 baseline | **PASS** | Correct accepted repository, sidecar, lifecycle, and final identities. |
| Design-delivery integrity | **PASS** | All indexed artifact hashes, catalog counts, sequences, and code uniqueness reconcile. |
| M2.12 business purpose | **PASS** | Correctly limited to as-built certification, contract reproduction, G3 publication, and downstream planning. |
| Historical-roadmap closure | **PASS** | Unbuilt collateral, covenant, regulatory, capital, and optimization capabilities are not retroactively certified. |
| Capability coverage | **PASS** | Twenty required rows; all production-action and legal-certification flags are false. |
| Source and contract inventory | **HOLD** | Contract identities are strong, but the complete physical source-edge graph and historical acceptance method are not frozen. |
| Canonical object model | **BLOCKER** | The one policy row has contradictory writer ownership across the freeze and build prompt. |
| Hash architecture | **BLOCKER** | Registry-family hashing, hash preimages, contract-set formula, and hash-construction order are incomplete or potentially circular. |
| Evidence-certification model | **HOLD** | The 72 node/family applicability rules and source-evidence methods are not explicitly frozen. |
| G3 acceptance finalizer | **BLOCKER** | Requirement 048 is self-referential unless pre-write and post-write phases are explicitly separated. |
| Negative-control design | **HOLD** | Codes exist, but exact injections, expected SQLSTATEs, isolation preconditions, and rollback fingerprints are not frozen. |
| Detailed reporting | **HOLD** | Twenty-two of 24 result sets have `VARIABLE` expected rows and several result grains remain underdefined. |
| Build-chat handoff | **HOLD** | The opening attachment list omits several normative machine-readable design catalogs. |

# Approval blockers

## 1. Canonical policy-row writer is contradictory

The persistent object model defines the policy profile as one of the nine canonical families and includes it in the exact 134-entity arithmetic:

```text
Policy                              1
Stage certification                12
Component contracts                13
Evidence certification             72
Contract reproduction              13
Capability coverage                20
Latest                              1
Archive                             1
Registry                            1
                                   ---
Canonical entities                134
```

[export reference: filecite | turn128file1 | L212-L245]

The controlling freeze then says Program 222 is the only normal writer of M2.12 canonical rows, but its explicit list is:

```text
12 + 13 + 72 + 13 + 20 + 1 + 1 + 1 = 133
```

The policy row is omitted. [export reference: filecite | turn128file3 | L600-L618]

The separate build prompt says something different:

- Program 220 installs structures and definitions only and writes no canonical certification rows.
- Program 222 persists **one policy plus the remaining 133 rows**, totaling 134. [export reference: filecite | turn132file0 | L30-L39]

### Required resolution

The design must choose one exact model. My recommendation is:

```text
Program 220
Installs structures and inserts the one approved, frozen policy row.

Program 222
Is the sole normal writer of the remaining 133 non-policy
certification/G3 canonical rows.

Existing policy row                 1
Program 222 canonical writes      133
                                  ---
Total canonical entities          134
```

That aligns with the program name, the schema/policy recovery boundary, and the established project pattern of installing governed definition/control rows before business generation.

The amendment must freeze:

- policy version;
- policy approval status;
- exact configuration payload;
- configuration-hash method;
- row-hash preimage;
- Program 220 recovery behavior;
- revised “sole writer” wording.

No count needs to change.

## 2. Hash architecture is incomplete and potentially circular

The registry is itself one of the nine canonical families. It is also defined to store all nine family set hashes, a contract-set hash, and the final combined hash. Its row hash is said to exclude mutable lifecycle fields and contract/combined hashes, but the design does not explicitly exclude the registry’s own family-set hash or the remaining derived family hashes. [export reference: filecite | turn128file2 | L428-L481]

As presently written, implementation could become circular:

```text
registry row hash
→ registry set hash
→ stored in registry
→ registry row hash
```

The design also does not freeze:

- exact physical preimage for each of the nine families;
- target-type coercion before hashing;
- latest `row_hash` versus `contract_row_hash`;
- archive payload and archive-row-hash preimage;
- exact contract-set-hash formula;
- exact registry-row-hash exclusions;
- exact order in which registry, contract, and combined identities are built.

There is also a catalog discrepancy. M2.12 has nine canonical families, but the generation-evidence catalog contains only eight family set-hash records:

```text
POLICY
STAGE_CERTIFICATION
CONTRACT_COMPONENT
EVIDENCE_CERTIFICATION
CONTRACT_REPRODUCTION
CAPABILITY_COVERAGE
LATEST
ARCHIVE
```

There is no `REGISTRY_SET_HASH` evidence row. [export reference: filecite | turn137file0 | L10-L34]

### Required resolution

Amendment A should freeze this sequence:

```text
1. Cast every canonical value to its exact target type and typmod.
2. Calculate all non-registry physical row hashes.
3. Calculate the eight non-registry family set hashes.
4. Calculate the registry row hash while excluding:
   - generated registry ID;
   - mutable lifecycle status and timestamps;
   - registry row_hash itself;
   - all derived family set hashes;
   - registry_set_hash;
   - contract_set_hash;
   - combined_set_hash.
5. Calculate registry_set_hash from the persisted registry row hash.
6. Calculate contract_set_hash under one explicit formula.
7. Calculate the ordered 134-entity combined hash.
8. Independently reconstruct all of the above before Program 222 commits.
```

The 24-row generation-evidence total can be preserved by consolidating:

```text
COMPONENT_LATEST_ROWS_TOTAL
+
COMPONENT_ARCHIVE_ROWS_TOTAL
```

into one governed evidence record carrying `7,129 / 7,129`, and using the released slot for:

```text
M2_12_REGISTRY_SET_HASH
```

The amendment may choose another explicit reallocation, but a ninth canonical-family set hash cannot remain unevidenced while the design claims nine-family deterministic certification.

## 3. Source graph is not yet lineage-complete

The design correctly identifies:

- a linear M1.17 → M2.10 chain; and
- the separate five-source M2.11 graph. [export reference: filecite | turn128file1 | L154-L190]

However, the accepted physical registries contain additional direct lineage anchors omitted from the supplied source-contract inventory.

M2.2 carries:

```text
source_m1_3_gate_id
M1_3_APPLICATION_REQUEST

source_m1_3_application_hash
01485256b9b5748fb412743d35ced602
```

[export reference: filecite | turn138file0 | L21-L24]

M2.5 carries:

```text
source_m1_6_acceptance_gate_id
M1_6_MATCHED_SCENARIO_OVERLAYS

source_m1_6_combined_hash
3f85921bf6fc30ddc6cee146085e58c5
```

[export reference: filecite | turn138file2 | L145-L172]

The current inventory identifies only the primary predecessor for those contracts. [export reference: filecite | turn133file0 | L13-L18]

At minimum, the source-edge architecture must therefore cover:

```text
Linear M1.17 → M2.10 edges               10
Auxiliary M1.3 → M2.2 edge                1
Auxiliary M1.6 → M2.5 edge                1
M2.11 five-source edges                   5
                                           --
Known required edges                     17
```

A physical inventory of every registry source-identity field should confirm whether additional accepted auxiliary anchors exist.

### Historical lifecycle issue

Acceptance Requirement 006 currently states:

> All eleven M2.1–M2.11 stage run and contract statuses are accepted.

[export reference: filecite | turn135file0 | L21-L28]

The physical project has one governed run-registry row for a run code/version and one current mutable `run_status`; it does not retain eleven simultaneously queryable historical run statuses in that row. [export reference: filecite | turn136file0 | L30-L70]

The requirement should instead freeze a physically testable rule such as:

```text
Current governed run status
M2_11_ACCEPTED

Eleven M2.1–M2.11 contract registries
ACCEPTED / exact identities

Eleven stage acceptance gates
PASS / exact review versions

Required accepted evidence/provenance
present and exact
```

M1.17 remains separately controlled by Requirement 005.

### Evidence applicability issue

The design states that all six evidence families apply to all 12 nodes, producing 72 rows, but also permits `PASS_NOT_APPLICABLE` without supplying an exact node-by-family applicability matrix. [export reference: filecite | turn131file8 | L927-L957]

Either:

- all 72 rows must be mandatory `PASS`; or
- the exact permitted `PASS_NOT_APPLICABLE` cells and their physical rationale must be frozen.

The implementation must not decide this ad hoc.

## 4. G3 gate identity and acceptance atomicity are underdefined

The exact accepted G0 gate row is:

```text
gate_id       G3_M2_CONTRACT
gate_name     Module 2 Contract
module_code   M2
severity      BLOCKING
active_flag   TRUE
description   Offer contract accepted.
```

[export reference: filecite | turn130file0 | L17-L23]

The physical gate catalog defaults `active_flag` to true and permits only `BLOCKING`, `MATERIAL`, or `ADVISORY`. [export reference: filecite | turn134file0 | L55-L67]

The M2.12 freeze currently names only the gate ID and says the row should be verified rather than redefined. The amendment should freeze the **complete exact physical identity** above and require Programs 220, 221, and 225 to verify it consistently.

The legacy description should remain unchanged because it is accepted baseline metadata. M2.12 documentation should explain that its broader as-built certification scope is governed by the M2.12 policy and acceptance evidence, not by rewriting the historical gate description.

### Requirement 048 circularity

Requirement 048 says:

> Exactly one G3 acceptance row and one acceptance evidence row are written only after all prerequisites pass.

[export reference: filecite | turn137file3 | L117-L120]

But Program 225 is simultaneously instructed to evaluate all 48 requirements before it writes those rows. That is self-referential.

The amendment should divide the fixed 48 requirements into explicit phases:

```text
Requirements 001–047
PRE_WRITE prerequisites

Requirement 048
POST_WRITE atomic checkpoint
```

Program 225 should:

1. require zero prior G3 gate rows for the governed review version;
2. require zero prior M2.12 acceptance-evidence rows;
3. pass Requirements 001–047;
4. write the gate and evidence rows atomically;
5. evaluate Requirement 048;
6. prove immutable canonical and contract hashes did not change;
7. commit only when all 48 are PASS.

The amendment must also freeze:

- `acceptance_gate_result.review_version`, preferably `1`;
- exact M2.12 acceptance evidence code;
- exact evidence segment key;
- expected result status;
- observed-value identity;
- rerun behavior.

The gate-result primary key includes `run_id + gate_id + review_version`, so review-version behavior cannot remain implicit. [export reference: filecite | turn134file5 | L435-L440]

# Other required design corrections

## 5. Negative-control catalog is not implementation-ready

The supplied negative-control design contains only:

```text
sequence
control code
PASS_EXPECTED_REJECTION
```

[export reference: filecite | turn137file1 | L45-L65]

Before WP1, each of the 20 controls should freeze:

- mutation target;
- exact injected defect;
- intended physical constraint, trigger, or assertion;
- expected SQLSTATE;
- expected message prefix;
- preconditions proving no unrelated constraint intercepts the test;
- rollback/isolation method;
- identity-sequence handling;
- required before/after canonical fingerprint;
- applicability and source authority.

The before/after postflight should cover:

```text
Nine canonical family counts
134 row-level physical identities
Nine ordered family set hashes
Latest/archive identity
Registry row hash
Contract set hash
Combined hash
All M2.12-owned identity sequences
```

The 20 codes and total can remain unchanged.

## 6. Detailed-result catalog does not freeze successful output cardinality

Twenty-two of the 24 result sets use:

```text
expected_success_rows = VARIABLE
```

Only Result Sets 23 and 24 have a fixed expectation of zero. [export reference: filecite | turn137file2 | L76-L100]

This leaves several reporting questions open:

- Is Result Set 11 all 1,500 application rows or a sample?
- If sampled, what is the exact sample size and deterministic order?
- Is the source-graph result 15, 17, or another edge count?
- Does each summary return one row, 12 rows, 13 rows, 20 rows, or 24 rows?
- What explicit header schema is required for zero-row outputs?

Amendment A should freeze for all 24 result sets:

```text
authoritative source
business grain
exact expected row count or bounded deterministic range
full detail versus governed sample
explicit projection
deterministic ORDER BY
zero-row header behavior
```

Programs 226 and 227 should also be governed as:

```text
Ordinary transaction; persistent-state read-only
```

They may create, populate, index, and analyze `tmp_report_` relations, but may perform no persistent DML or DDL. The prior accepted implementation demonstrated why PostgreSQL transaction-level `READ ONLY` is incompatible with required temporary reporting construction. [export reference: filecite | turn120file44 | L118-L124]

## 7. Build-chat attachment list omits normative artifacts

The build-chat opening currently instructs the user to attach only:

- baseline and sidecar;
- M2.11 acceptance;
- main freeze;
- source inventory;
- capability catalog;
- acceptance matrix. [export reference: filecite | turn137file4 | L132-L146]

It omits:

- `M2_12_EXPECTED_RESULTS.json`;
- generation-evidence catalog;
- positive-control family allocation;
- negative-control design catalog;
- detail-result-set catalog;
- design delivery index.

Yet the delivery index identifies these as frozen governing artifacts. [export reference: filecite | turn120file2 | L5-L16]

The revised opening should require all indexed artifacts, or one governed design-handoff ZIP containing them with a manifest and SHA-256 inventory.

## 8. Generation-evidence catalog needs expected values and sources

The generation catalog currently contains only:

```text
sequence
evidence code
unit
required status
```

[export reference: filecite | turn137file0 | L10-L34]

Each row should additionally define:

- authoritative object or calculation;
- expected value;
- comparison operator;
- ordered business key where applicable;
- observed-value representation;
- interpretation;
- blocking behavior.

This is particularly important for the source totals, view counts, mismatch controls, and the missing registry-family set hash.

# Design decisions that should remain locked

The amendment should **not** reopen:

- M2.12’s role as final as-built Module 2 certification and G3 publication;
- the `31_M2_12` stage;
- `M2_12_METHOD_V1`;
- `M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1`;
- `M2_G3_CONSUMPTION_BUNDLE v1`;
- `M2_G3_BUNDLE_SCHEMA_V1`;
- `G3_M2_CONTRACT`;
- the lifecycle ending in `M2_12_ACCEPTED`;
- 12 source-certification nodes;
- 13 component contracts;
- 20 capability rows;
- 9 canonical families;
- 134 canonical entities;
- 1,500 application rows;
- 59 operational-account rows;
- 24 strategy/scope rows;
- 128 positive controls;
- 20 negative controls;
- 48 acceptance requirements;
- 24 detailed result sets;
- Programs 220–227 and the four recovery numbers;
- the no-production, no-legal-certification, no-causal-optimization, and no-Module-3-execution boundaries.

The capability model is particularly strong: it physically distinguishes implemented, bounded, deferred, unsupported, and prohibited scope, and all production-action and legal-certification flags remain false. [export reference: filecite | turn129file1 | L172-L201]

# Exact direction to return to the M2.12 design chat

```text
M2.12 SOURCE & BUSINESS DESIGN AUDIT — HOLD

Do not begin M2.12 Work Package 1 and do not generate SQL.

Produce one bounded design correction:

M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AMENDMENT_A

Do not reopen:

- the accepted M2.11 baseline;
- M2.12 business purpose;
- stage 31_M2_12;
- methodology, policy, bundle, schema, or gate codes;
- 12 certification nodes;
- 13 component contracts;
- 20 capability rows;
- nine canonical families;
- 134 canonical entities;
- 1,500 / 59 / 24 consumption-view counts;
- 128 positive controls;
- 20 negative controls;
- 48 acceptance requirements;
- 24 detail result sets;
- Programs 220–227 or recovery numbering;
- non-production, legal/compliance, empirical-optimization, Module 3,
  and deployment boundaries.

MANDATORY AMENDMENT SUBJECTS

1. POLICY ROW WRITER

Resolve the contradiction between Program 220 and Program 222.

Preferred frozen model:

- Program 220 inserts the one approved policy canonical row.
- Program 222 is the sole normal writer of the remaining 133
  certification/G3 canonical rows.
- Existing policy 1 + Program 222 writes 133 = 134 total.
- Program 220A governs incomplete policy installation recovery.

Freeze policy version, status, configuration payload, configuration hash,
row-hash preimage, and rerun behavior.

2. HASH PREIMAGES AND CONSTRUCTION SEQUENCE

Create an authoritative field-level hash specification covering all nine
canonical families.

Freeze:

- exact target typing before every hash;
- included and excluded fields;
- latest row_hash and contract_row_hash;
- archive payload, copied contract hash and archive-row-hash preimage;
- registry-row-hash exclusions;
- exact contract-set-hash formula;
- registry-set-hash formula;
- exact ordered 134-entity combined-hash formula;
- construction and physical-reconstruction order.

Required order:

non-registry rows
→ eight non-registry set hashes
→ registry row hash
→ registry set hash
→ contract set hash
→ combined hash

Eliminate every circular dependency.

Add M2_12_REGISTRY_SET_HASH to generation evidence. Preserve the frozen
24-row evidence total through an explicit catalog reallocation, preferably
by combining component-latest and component-archive totals into one
7,129 / 7,129 evidence record.

3. COMPLETE SOURCE GRAPH

Create M2_12_SOURCE_GRAPH_EDGE_CATALOG.csv.

Enumerate every physically accepted source-identity edge from the accepted
registries. The known minimum is:

- ten linear M1.17-through-M2.10 edges;
- M1.3 → M2.2;
- M1.6 → M2.5;
- five M2.11 source edges.

Known minimum edge count = 17.

Confirm whether any additional registry source anchors exist.

Update the source inventory, expected results, Program 221/222/223
requirements, acceptance chain requirements, and Detail Result Set 06.

4. PHYSICAL HISTORICAL ACCEPTANCE METHOD

Replace the ambiguous requirement that eleven historical run statuses
simultaneously be accepted.

Freeze a physically testable method:

- one current run row = M2_11_ACCEPTED;
- eleven M2.1–M2.11 contract registries = ACCEPTED;
- eleven exact stage gates = PASS;
- required acceptance evidence/provenance present;
- M1.17 controlled separately.

5. EVIDENCE-CERTIFICATION APPLICABILITY

Create:

M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX.csv

Define all 72 node × evidence-family rows with:

- applicability;
- authoritative source relation/evidence pattern;
- expected count/status/hash;
- allowed PASS or PASS_NOT_APPLICABLE state;
- rationale.

PASS_NOT_APPLICABLE may not be chosen during implementation. If all six
families truly apply to all twelve nodes, freeze all 72 as mandatory PASS.

6. G3 GATE AND ACCEPTANCE WRITE PHASES

Freeze the exact existing G3 gate identity:

G3_M2_CONTRACT
Module 2 Contract
M2
BLOCKING
active TRUE
description preserved unchanged

Program 220 must verify rather than redefine or update it.

Classify acceptance requirements as:

001–047 PRE_WRITE
048 POST_WRITE_ATOMICITY

Freeze:

- zero-prior gate/evidence checks;
- gate review_version = 1;
- acceptance evidence code and segment key;
- observed-value identity;
- atomic write sequence;
- immutable before/after hash checkpoint;
- rerun behavior.

7. NEGATIVE-CONTROL EXECUTION SPECIFICATION

Expand all twenty negative-control rows to include:

- target;
- injected defect;
- intended physical/assertion control;
- expected SQLSTATE and message prefix;
- preconditions;
- rollback/isolation method;
- identity-sequence handling;
- before/after nine-family and 134-entity fingerprint;
- source and traceability requirement.

Do not change the twenty control codes.

8. DETAIL REPORT OPERABILITY

Replace blanket VARIABLE expectations with exact governed definitions for
all twenty-four result sets:

- source;
- grain;
- exact count or deterministic bounded range;
- full detail versus sample;
- sample size if applicable;
- explicit projection;
- ORDER BY;
- zero-row header behavior.

Freeze Programs 226–227 as ordinary transactions with persistent-state
read-only behavior and tmp_report_ objects only.

9. COMPLETE BUILD-HANDOFF ATTACHMENT SET

Revise the build-chat opening to require all indexed M2.12 design
artifacts, not only three machine-readable catalogs.

10. GENERATION-EVIDENCE EXPECTATIONS

Expand the generation-evidence catalog with authoritative source,
expected value, comparison rule, ordering, observed-value format,
interpretation and failure behavior for every row.

REQUIRED OUTPUTS

Revise:

- M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AND_BUILD_HANDOFF.md
- M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY.csv
- M2_12_EXPECTED_RESULTS.json
- M2_12_GENERATION_EVIDENCE_CATALOG.csv
- M2_12_NEGATIVE_CONTROL_CATALOG_DESIGN.csv
- M2_12_ACCEPTANCE_REQUIREMENT_MATRIX.csv
- M2_12_DETAIL_RESULT_SET_CATALOG.csv
- M2_12_BUILD_CHAT_OPENING_AND_WORK_PACKAGE_PROMPTS.md
- M2_12_DESIGN_DELIVERY_INDEX.md

Create:

- M2_12_SOURCE_GRAPH_EDGE_CATALOG.csv
- M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX.csv
- M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION.csv
- M2_12_ACCEPTANCE_WRITE_PHASE_SPECIFICATION.csv

Certify byte identity for unchanged artifacts, including the capability
catalog and positive-control family allocation if they do not require
revision.

Regenerate every design SHA-256 in the delivery index.

Do not:

- generate Programs 220–227;
- generate recovery SQL;
- create manifests or implementation ZIPs;
- modify the accepted M2.11 repository;
- authorize Work Package 1;
- authorize PostgreSQL execution;
- authorize Module 3 or production use.

Final state must remain:

ACCEPTED M2.11 BASELINE LOCKED
M2.12 BUSINESS PURPOSE LOCKED
M2.12 AMENDMENT A READY FOR AUDIT
M2.12 WP1 NOT AUTHORIZED
M2.12 SQL NOT GENERATED
POSTGRESQL NOT EXECUTED
MODULE 3 NOT AUTHORIZED
PRODUCTION NOT AUTHORIZED

Stop after Amendment A and wait for narrow audit re-review.
```

# Final audit disposition

The M2.12 design is **substantively strong and directionally correct**. It successfully prevents roadmap overclaim, preserves the accepted M2.11 boundary, separates valid business grains, and defines a coherent final Module 2 certification purpose.

The remaining gaps are concentrated in exactly the areas that caused avoidable correction cycles in M2.11:

- writer ownership;
- hash preimages and ordering;
- complete source lineage;
- physically testable acceptance;
- negative-control reachability;
- reporting operability;
- authority completeness.

Those issues should be corrected now, while they are still design artifacts rather than thousands of lines of SQL.

**M2.12 Work Package 1 should remain on hold until Amendment A is reviewed and approved.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-f888b3d0-701e-4e75-8d3a-c7cf99a259a5"></a>
## Andrew / user · C072-M00247

C072-M00247 · 2026-08-07T08:22:16.327000-04:00 · active path

Preceding visible parent: [C072-M00246](part-18.md#m-d602c64a-749c-4997-bb08-0e160453259b)

**Editorial record note:** Attachment references: M2_12_Source_&_Business_Design_After_Amendment_A.txt; M2_12_BUILD_CHAT_OPENING_AND_WORK_PACKAGE_PROMPTS(3)(1).md; M2_12_GENERATION_EVIDENCE_CATALOG(3)(1).csv; M2_12_DETAIL_RESULT_SET_CATALOG(3)(1).csv; M2_12_NEGATIVE_CONTROL_CATALOG_DESIGN(3)(1).csv; M2_12_ACCEPTANCE_REQUIREMENT_MATRIX(3)(1).csv; M2_12_ACCEPTANCE_WRITE_PHASE_SPECIFICATION(1).csv; M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX(1).csv; M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY(3)(1).csv; M2_12_SOURCE_GRAPH_EDGE_CATALOG(1).csv; M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION(1).csv; M2_12_DESIGN_DELIVERY_INDEX(3)(1).md; M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AMENDMENT_A(1).md; M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AND_BUILD_HANDOFF(3)(1).md; M2_12_DESIGN_DELIVERY_INDEX.md(1).sha256; M2_12_AMENDMENT_A_DELIVERY_VALIDATION(1).json; M2_12_AMENDMENT_A_DELIVERY_VALIDATION(1).md; M2_12_CAPABILITY_COVERAGE_CATALOG (1).csv; M2_12_POSITIVE_CONTROL_FAMILY_ALLOCATION (1).csv; M2_12_EXPECTED_RESULTS (1).json

<!-- BEGIN_SOURCE_MESSAGE -->
Audit M2.12 Source and Business Design following Amendment A. If sign off is provided, organize these artifacts and a prompt to pass to our M2.12 build chat.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bdc5f3d7-f692-4690-87be-31c14fc2a7c5"></a>
## Assistant · C072-M00248

C072-M00248 · 2026-08-07T09:09:27.960691-04:00 · active path

Preceding visible parent: [C072-M00247](part-18.md#m-f888b3d0-701e-4e75-8d3a-c7cf99a259a5)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Amendment A audit determination

**HOLD — final design signoff is not provided.**

```text
Accepted M2.11 baseline                    PASS / LOCKED
M2.12 business purpose                     PASS / LOCKED
Amendment A conceptual remediation         SUBSTANTIALLY PASS
M2.12 final design freeze                  HOLD — CORRECTION R1 REQUIRED
M2.12 Work Package 1                       NOT AUTHORIZED
M2.12 SQL construction                     NOT AUTHORIZED
PostgreSQL execution                       NOT AUTHORIZED
Module 3                                   NOT AUTHORIZED
Production deployment                      NOT AUTHORIZED
```

The accepted M2.11 baseline independently reconciles to the required SHA-256, 4,819 entries, 30 numbered stages, final stage `30_M2_11`, and accepted M2.11 state. [export reference: filecite | turn139file16 | L3-L24]

Amendment A successfully resolves nearly all of the original design concerns:

- Program 220 now owns the one policy canonical row, while Program 222 owns the remaining 133 rows.
- The registry, contract, and combined hashes now have an explicit acyclic construction sequence.
- Historical acceptance is tested through physical registries, review-version-1 gates, evidence, and reconstruction rather than impossible simultaneous historical run statuses.
- All 72 evidence-certification cells are mandatory `PASS`.
- Program 225 now separates 47 `PRE_WRITE` requirements from one `POST_WRITE_ATOMICITY` requirement.
- Negative-control isolation, sequence postflight, fixed report cardinalities, generation evidence, and the complete attachment set are materially resolved. [export reference: filecite | turn144file0 | L11-L212] [export reference: filecite | turn144file0 | L295-L424] [export reference: filecite | turn144file1 | L488-L714]

Two blocking classes remain.

## Blocker 1 — the frozen 19-edge source graph is physically inaccurate

Amendment A expressly makes the source-edge catalog authoritative for each target registry field, source gate, accepted hash, and certification method. Programs 221–223 must certify all 19 exact edges. [export reference: filecite | turn144file0 | L216-L291]

Independent parsing of the accepted M2.11 repository found:

```text
Target registry relations resolved          19 / 19
Cataloged target source fields existing     10 / 19
Cataloged source gates exact                18 / 19
Fully exact source-edge rows                 9 / 19
Defective source-edge rows                  10
```

The required corrections are:

| Edge | Cataloged value | Accepted physical value |
|---:|---|---|
| 1 | `M1_15_LATEST_ARCHIVE_CONSUMPTION_CONTRACT` | `M1_15_CONSUMPTION_CONTRACT` |
| 4 | `source_m2_1_combined_set_hash` | `source_m2_1_combined_hash` |
| 6 | `source_m2_2_combined_set_hash` | `source_m2_2_combined_hash` |
| 7 | `source_m2_3_combined_set_hash` | `source_m2_3_combined_hash` |
| 8 | `source_m2_4_combined_set_hash` | `source_m2_4_combined_hash` |
| 10 | `source_m2_5_combined_set_hash` | `source_m2_5_combined_hash` |
| 11 | `source_m2_6_combined_set_hash` | `source_combined_set_hash` |
| 12 | `source_m2_7_combined_set_hash` | `source_combined_set_hash` |
| 13 | `source_m2_8_combined_set_hash` | `source_combined_set_hash` |
| 14 | `source_m2_9_combined_set_hash` | `source_combined_set_hash` |

The defective values are present in the submitted 19-row catalog. [export reference: filecite | turn146file0 | L10-L29]

The accepted physical sources confirm, for example:

- M1.15’s gate is `M1_15_CONSUMPTION_CONTRACT`. [export reference: filecite | turn143file13 | L688-L705]
- M2.2 stores `source_m2_1_combined_hash`, not `source_m2_1_combined_set_hash`. [export reference: filecite | turn143file8 | L501-L502]
- M2.3 stores `source_m2_2_combined_hash`. [export reference: filecite | turn147file2 | L124-L176]
- M2.7 uses the generic physical field `source_combined_set_hash`. [export reference: filecite | turn143file3 | L155-L184]
- M2.10 likewise uses `source_combined_set_hash`. [export reference: filecite | turn147file0 | L24-L50]

These cannot be deferred to WP1. WP1 is permitted to map accepted physical names, but it may not correct a frozen normative catalog.

## Blocker 2 — the supplied expected-results JSON is not the indexed Amendment A artifact

The amended delivery index declares:

```text
M2_12_EXPECTED_RESULTS.json

Expected bytes
12,978

Expected SHA-256
f0bae96e36c675cec95b92ef8a9804d90d71c94b3af4bea999e05242da490477
```

[export reference: filecite | turn144file2 | L821-L839]

The supplied attachment independently calculates to:

```text
Observed bytes
2,926

Observed SHA-256
d74fdb59a66e82c7d7ebf1ad2d6d1e7dee02dad4f8e2b0270673c9ed8e629145
```

It contains the earlier basic identity, counts, programs, and boundary structure, but not the indexed Amendment A writer split, 19-edge graph, 72-cell applicability model, 27-row hash/sequence architecture, three exact sequences, 47+1 acceptance phases, or fixed report-cardinality model. [export reference: filecite | turn144file3 | L914-L1002]

The full artifact reconciliation was:

```text
Normative design artifacts supplied          15
Exact index byte/hash matches                 14
Mismatches                                     1
Design-index sidecar                         PASS
```

Therefore, the current files form a mixed-version handoff and cannot be organized as build authority.

## Delivery-validation limitation

The supplied Amendment A validation reports `85 / 85 PASS`, along with the correct catalog totals. [export reference: filecite | turn139file6 | L3-L31]

However, it did not:

- hash the actual supplied expected-results file against its index entry;
- test whether all 19 cataloged target fields physically exist; or
- test all 19 source gates against accepted authority.

That validation must be expanded and reissued as part of Correction R1.

# Audit deliverables

I did **not** create an M2.12 build-chat handoff package because the amended prompts themselves prohibit use until narrow-audit approval, and require a complete hash-reconciled attachment set. [export reference: filecite | turn139file1 | L5-L37]

Instead, I organized an audit-only package containing the full report, machine-readable findings, and a ready-to-paste bounded correction prompt:

- Complete Amendment A narrow-audit package (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_NARROW_AUDIT_PACKAGE_20260807.zip`; referenced bytes not established here)
- External package SHA-256 (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_NARROW_AUDIT_PACKAGE_20260807.zip.sha256`; referenced bytes not established here)
- Full audit report (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_NARROW_AUDIT_REPORT_20260807.md`; referenced bytes not established here)
- Machine-readable audit results (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_NARROW_AUDIT_RESULTS_20260807.json`; referenced bytes not established here)
- Finding register (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_NARROW_AUDIT_FINDINGS_20260807.csv`; referenced bytes not established here)
- Ready-to-paste Amendment A Correction R1 prompt (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_PROMPT_20260807.md`; referenced bytes not established here)
- Audit-package validation (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_NARROW_AUDIT_PACKAGE_VALIDATION_20260807.md`; referenced bytes not established here)

```text
Audit-package SHA-256
351dcffa8c4b058a17ecbf666532af4c77997a9f6b965dab7cdaa6dfd62e13fd

ZIP entries                              6
ZIP CRC                                  PASS
Complete extraction/hash parity          PASS
Duplicate paths                             0
Unsafe paths                                0
```

The next governed action is **Amendment A Correction R1 followed by narrow re-audit**. Work Package 1 remains unauthorized.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b18173f7-9daa-4ef7-8860-8bab8b0dc44e"></a>
## Andrew / user · C072-M00249

C072-M00249 · 2026-08-07T10:11:06.652000-04:00 · active path

Preceding visible parent: [C072-M00248](part-18.md#m-bdc5f3d7-f692-4690-87be-31c14fc2a7c5)

**Editorial record note:** Attachment references: M2_12 Amendment A Correction R1 completed.zip

<!-- BEGIN_SOURCE_MESSAGE -->
Perform the narrow re-audit of the Amendment A Correction R1. If sign off is given, build the package/prompt to send to the M2.12 build chat.
<!-- END_SOURCE_MESSAGE -->


<a id="m-71e5ebfa-0d8c-44cc-8816-1c7c3c16f71a"></a>
## Assistant · C072-M00250

C072-M00250 · 2026-08-07T10:33:37.210267-04:00 · active path

Preceding visible parent: [C072-M00249](part-18.md#m-b18173f7-9daa-4ef7-8860-8bab8b0dc44e)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Amendment A Correction R1 — narrow re-audit determination

**HOLD — final Source & Business Design signoff is not provided.**

The source-graph correction is correct, but the submitted Correction R1 archive remains a **mixed-version authority delivery**. Work Package 1 therefore remains unauthorized.

The audited upload is the 88,651-byte `M2_12 Amendment A Correction R1 completed.zip`. [export reference: filecite | turn150file0 | L1-L5] The accepted M2.11 baseline remains intact at SHA-256 `92f0491e...904fc`, with 4,819 files, 30 numbered stages, final stage `30_M2_11`, and all 29 predecessor stages preserved. [export reference: filecite | turn148file16 | L4-L24]

```text
Independent checks                       190
PASS                                     172
FAIL                                      17
ADVISORY                                   1

Source-graph physical reconciliation    19 / 19 PASS
Normative artifact reconciliation       15 / 16 PASS
Approval blockers                         3
```

## What passed

### Source-graph Correction R1 — PASS

All ten defects from the prior audit were corrected:

```text
Edge 01  M1_15_CONSUMPTION_CONTRACT
Edge 04  source_m2_1_combined_hash
Edge 06  source_m2_2_combined_hash
Edge 07  source_m2_3_combined_hash
Edge 08  source_m2_4_combined_hash
Edge 10  source_m2_5_combined_hash
Edges 11–14  source_combined_set_hash
```

The corrected catalog identity is:

```text
Rows
19

SHA-256
c3409c671e581648c946a083fe532722cd7856bc4f887e69d67ce5158665981a
```

I independently inspected the accepted M2.11 repository rather than merely comparing the catalog with its own validation:

```text
Target registry relations resolved             19 / 19
Target source-hash fields physically present    19 / 19
Source acceptance gates located                 19 / 19
Expected accepted source hashes located         19 / 19
Target registry/field mappings located          19 / 19
Fully reconciled physical edges                 19 / 19
```

**No further source-graph correction is required.**

The Amendment A writer split, acyclic hash design, evidence applicability, 47-plus-1 acceptance phases, report cardinalities, negative-control architecture, program boundaries, and non-production boundaries also remain substantively sound.

# Remaining blockers

## 1. The corrected expected-results authority is absent

The current Correction R1 delivery index requires:

```text
M2_12_EXPECTED_RESULTS.json

Expected bytes
32,958

Expected SHA-256
7115d1f96de6c89c630a5f209a4e6f06dddc16b7527ac788c75297c87bbbaab3
```

The submitted archive actually contains:

```text
M2_12_EXPECTED_RESULTS (2).json

Actual bytes
2,926

Actual SHA-256
d74fdb59a66e82c7d7ebf1ad2d6d1e7dee02dad4f8e2b0270673c9ed8e629145
```

That is the superseded pre-amendment JSON. It contains the basic module identity, counts, program sequence, and Module 3 boundary, but does not contain the machine-readable Correction R1 subjects. [export reference: filecite | turn148file7 | L2-L23] [export reference: filecite | turn148file7 | L25-L65]

The missing sections include:

```text
Program 220 / Program 222 writer split
Nineteen-edge physical source graph
Seventy-two-cell applicability model
Eight-phase acyclic hash sequence
Three owned identity sequences
47 PRE_WRITE + 1 POST_WRITE_ATOMICITY phases
Twenty-four fixed report cardinalities
```

The narrative says the corrected 32,958-byte file was generated, but that byte stream does not appear anywhere in the archive. A narrative description cannot substitute for a normative machine-readable authority.

## 2. The design-index sidecar is still superseded

The actual current index is:

```text
M2_12_DESIGN_DELIVERY_INDEX(4).md

Actual bytes
7,736

Actual SHA-256
2528bdeec4f6c17d6be2a186ef97f86234d39f29466a7b3062639872fe0b8e3f
```

The supplied sidecar instead contains:

```text
730fe1f3afd0ffb06231863a679d98b1a7d2c2a255f3123fcf1260872f3aff29
```

`730fe1...` is the superseded Amendment A index identity. Consequently, the claimed index-sidecar `PASS` is not supported by the actual submitted files.

## 3. The machine-readable validation is from the prior release

The human-readable validation claims:

```text
Correction R1
334 / 334 PASS
16 / 16 byte matches
16 / 16 SHA-256 matches
```

The actual machine-readable JSON reports:

```text
Design status                 AMENDMENT_A_READY_FOR_NARROW_AUDIT
Checks                        85 / 85 PASS
Normative artifacts           15
Source-graph SHA-256          e1e6b5cd...  superseded
Expected-results SHA-256      f0bae96e...  prior indexed value
Delivery-index SHA-256        730fe1f3...  superseded
```

Thus, the human and machine validation records belong to different authority generations. The machine JSON could not have validated the current source graph, current index, or declared corrected expected-results file.

## Nonblocking advisory

Two byte-identical download-named copies of the build prompt are included:

```text
M2_12_BUILD_CHAT_OPENING_AND_WORK_PACKAGE_PROMPTS(4).md
M2_12_BUILD_CHAT_OPENING_AND_WORK_PACKAGE_PROMPTS(4) (1).md
```

Both hash to:

```text
9741686799259be544d3113e48f5cbbb6322cb4c8c5379ac098270a16ec9f837
```

The next clean delivery should contain one canonical copy.

# Governing disposition

```text
Accepted M2.11 baseline                    LOCKED / PASS
M2.12 business purpose                     LOCKED
Source-graph Correction R1                 APPROVED / FIXED
Amendment A conceptual design              SUBSTANTIVELY SOUND

Expected-results delivery                  BLOCKER
Index-sidecar reconciliation               BLOCKER
Machine-readable validation                BLOCKER

M2.12 final design freeze                  HOLD
M2.12 Work Package 1                       NOT AUTHORIZED
M2.12 SQL                                  NOT GENERATED
PostgreSQL                                 NOT EXECUTED
Module 3 SQL/execution                     NOT AUTHORIZED
Production deployment                     NOT AUTHORIZED
```

A build-chat handoff package was **not** created because the build prompt itself requires explicit narrow re-audit approval and complete hash-reconciled authority. Creating that handoff now would bypass its own governance boundary.

The necessary next action is a **delivery-authority correction only**:

```text
M2_12_AMENDMENT_A_DELIVERY_AUTHORITY_CORRECTION_R2
```

No source-graph, business-design, count, control, hash-preimage, reporting, or program redesign is required.

## Audit and correction artifacts

- Full narrow re-audit report (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_NARROW_REAUDIT_REPORT_20260807.md`; referenced bytes not established here)
- All 190 machine-readable audit checks (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_NARROW_REAUDIT_RESULTS_20260807.json`; referenced bytes not established here)
- Ready-to-paste Delivery Authority Correction R2 prompt (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_DELIVERY_AUTHORITY_CORRECTION_R2_PROMPT_20260807.md`; referenced bytes not established here)
- Complete audit-only package (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_NARROW_REAUDIT_PACKAGE_20260807.zip`; referenced bytes not established here)
- Audit-package SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_NARROW_REAUDIT_PACKAGE_20260807.zip.sha256`; referenced bytes not established here)
- Audit-package validation (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_NARROW_REAUDIT_PACKAGE_VALIDATION_20260807.md`; referenced bytes not established here)

```text
Audit-package SHA-256
addba51e573dcd6a589f331bf45d9a34b993fd169c9d5dd3cbd438491a974b3c

ZIP entries
4

ZIP CRC
PASS
```

Once the exact corrected expected-results JSON, corrected index sidecar, and current machine-readable validation are supplied in one clean authority delivery, the next review can remain narrowly limited to those three delivery surfaces.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dab9499f-0cf1-4f9b-b41e-2a86ae5e7248"></a>
## Andrew / user · C072-M00251

C072-M00251 · 2026-08-07T10:58:50.217000-04:00 · active path

Preceding visible parent: [C072-M00250](part-18.md#m-71e5ebfa-0d8c-44cc-8816-1c7c3c16f71a)

**Editorial record note:** Attachment references: M_12_Source_And_Business_Design_with_Amendment_A_Correction_R1.zip

<!-- BEGIN_SOURCE_MESSAGE -->
I could have downloaded the files incorrectly. Please review the attached re-download before concluding there are blockers.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2385f773-e0db-4669-934f-c5b6a0738188"></a>
## Assistant · C072-M00252

C072-M00252 · 2026-08-07T11:15:42.371341-04:00 · active path

Preceding visible parent: [C072-M00251](part-18.md#m-dab9499f-0cf1-4f9b-b41e-2a86ae5e7248)

<!-- BEGIN_SOURCE_MESSAGE -->
# Re-download review determination

You were right to ask for a fresh review. I independently opened and audited the **new 75,391-byte re-download**, rather than carrying forward the prior result. It is a different archive from the earlier 88,651-byte submission. [export reference: filecite | turn153file0 | L1-L5]

The re-download is **not corrupted**:

```text
Current re-download
M_12_Source_And_Business_Design_with_Amendment_A_Correction_R1.zip

Bytes
75,391

SHA-256
2848f1323e6328b323bce8ccd701945d401b7a76996396031023b26e04690607

ZIP entries
19

ZIP CRC
PASS

Exact duplicate paths
0

Case-insensitive duplicate paths
0

Unsafe paths
0
```

It is cleaner than the first download: the duplicate build-prompt copy is gone and the filenames are canonical.

Unfortunately, the new archive confirms that the remaining problems are **inside the packaged content**, rather than resulting solely from my earlier review or a corrupt browser download.

```text
Source-graph Correction R1                 PASS
Normative artifacts expected               16
Normative artifacts present                15
Exact byte/hash matches                    14
Missing normative artifacts                 1
Mismatched normative artifacts              1

M2.12 final design freeze                  HOLD
M2.12 Work Package 1                       NOT AUTHORIZED
```

## What is now approved

The **19-edge source-graph correction remains approved**.

The re-download contains the corrected source graph at:

```text
SHA-256
c3409c671e581648c946a083fe532722cd7856bc4f887e69d67ce5158665981a
```

The ten previously identified gate/field corrections remain correct, and the prior independent physical inspection established:

```text
Target registry relations resolved             19 / 19
Target source-hash fields physically present    19 / 19
Source acceptance gates located                 19 / 19
Expected accepted source hashes located         19 / 19
Fully reconciled physical edges                 19 / 19
```

[export reference: filecite | turn154file8 | L668-L704]

No further source-graph correction or M2.12 business redesign is needed.

# Remaining blockers in the re-download

## 1. One normative artifact is missing

The new ZIP omits:

```text
M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX.csv
```

Required identity:

```text
Rows
72

Bytes
23,443

SHA-256
92b71ff85ffae4de9dbb1f68b8bc8942dde5d12234cc7986361ac6573f66932c
```

This is a material omission because that matrix freezes all 12 nodes × 6 evidence families as mandatory `PASS`. The build-chat attachment rules expressly require that artifact before Work Package 1 may begin. [export reference: filecite | turn151file1 | L17-L37]

This missing file is **new relative to the first Correction R1 download**. It appears that cleaning the first archive’s duplicate/download-named files inadvertently excluded the applicability matrix.

## 2. The expected-results JSON is still the superseded file

The current Correction R1 index requires:

```text
M2_12_EXPECTED_RESULTS.json

Bytes
32,958

SHA-256
7115d1f96de6c89c630a5f209a4e6f06dddc16b7527ac788c75297c87bbbaab3
```

[export reference: filecite | turn154file13 | L985-L994]

The re-download actually contains:

```text
Bytes
2,926

SHA-256
d74fdb59a66e82c7d7ebf1ad2d6d1e7dee02dad4f8e2b0270673c9ed8e629145
```

The actual file is still the short pre-amendment JSON. It contains the basic module identity, counts, program sequence, and boundaries, but not the required machine-readable:

```text
Program 220 / Program 222 writer split
Nineteen corrected source edges
Seventy-two-cell applicability architecture
Eight-phase acyclic hash construction
Nine family set hashes
Three exact owned identity sequences
47 PRE_WRITE + 1 POST_WRITE_ATOMICITY phases
Twenty-four fixed report cardinalities
```

The supplied 2,926-byte content is visible in the existing file authority. [export reference: filecite | turn156file1 | L21-L109]

## 3. The index sidecar remains stale

The actual current Correction R1 design index calculates to:

```text
2528bdeec4f6c17d6be2a186ef97f86234d39f29466a7b3062639872fe0b8e3f
```

The supplied sidecar still declares:

```text
730fe1f3afd0ffb06231863a679d98b1a7d2c2a255f3123fcf1260872f3aff29
```

That is the superseded Amendment A index identity. The supplied sidecar content confirms the old hash. [export reference: filecite | turn156file0 | L1-L10]

Required sidecar:

```text
2528bdeec4f6c17d6be2a186ef97f86234d39f29466a7b3062639872fe0b8e3f  M2_12_DESIGN_DELIVERY_INDEX.md
```

## 4. Human and machine validation records remain from different releases

The human-readable report says:

```text
334 / 334 PASS
16 / 16 artifact matches
Expected-results bytes 32,958
Expected-results hash  7115d1f...
```

[export reference: filecite | turn154file6 | L539-L558]

But the machine-readable JSON still reports:

```text
85 / 85 PASS
Design status: AMENDMENT_A_READY_FOR_NARROW_AUDIT
```

[export reference: filecite | turn151file5 | L2-L8] [export reference: filecite | turn151file5 | L18-L21]

It also carries the superseded identities:

```text
Source graph
e1e6b5cd...

Expected results
f0bae96e...

Delivery index
730fe1f3...
```

Therefore, the machine validation could not have hashed and validated the actual files inside this re-download.

# Final disposition

```text
Accepted M2.11 baseline                    LOCKED / PASS
M2.12 business purpose                     LOCKED
Amendment A conceptual remediation         PASS
Source-graph Correction R1                 APPROVED / FIXED

Evidence applicability matrix              MISSING
Expected-results authority                 BLOCKER
Index-sidecar reconciliation               BLOCKER
Human/machine validation parity            BLOCKER

M2.12 final design freeze                  HOLD
M2.12 Work Package 1                       NOT AUTHORIZED
M2.12 SQL                                  NOT GENERATED
PostgreSQL                                 NOT EXECUTED
Module 3                                   NOT AUTHORIZED
Production                                 NOT AUTHORIZED
```

So the conclusion is not that your re-download was ignored or that the same ZIP was reviewed twice. The new ZIP was independently examined and is structurally healthy. It is likely a **file-selection or package-assembly problem**, not a failed download transmission.

No M2.12 build-chat package should be created yet because the governing build prompt requires all normative artifacts and exact SHA-256 reconciliation before Work Package 1. The updated correction remains delivery-only; it does not reopen the design.

## Updated audit materials

- Full re-download re-audit report (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_REDOWNLOAD_REAUDIT_REPORT_20260807.md`; referenced bytes not established here)
- Machine-readable re-audit results (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_REDOWNLOAD_REAUDIT_RESULTS_20260807.json`; referenced bytes not established here)
- Updated ready-to-paste Delivery Authority Correction R2 prompt (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_DELIVERY_AUTHORITY_CORRECTION_R2_UPDATED_PROMPT_20260807.md`; referenced bytes not established here)
- Complete re-download audit package (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_REDOWNLOAD_REAUDIT_PACKAGE_20260807.zip`; referenced bytes not established here)
- Audit-package SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_CORRECTION_R1_REDOWNLOAD_REAUDIT_PACKAGE_20260807.zip.sha256`; referenced bytes not established here)

```text
Audit-package SHA-256
83b92d9eb10bdab8f1193659baeb506bdc16dba89bfb3984d86e59f29bee9612

ZIP CRC
PASS
```

The **updated R2 prompt** now includes the newly discovered requirement to restore the missing 72-row applicability matrix, in addition to replacing the stale expected-results JSON, sidecar, and machine-validation record.
<!-- END_SOURCE_MESSAGE -->


<a id="m-71654619-090c-4127-bdfd-55a628678b17"></a>
## Andrew / user · C072-M00253

C072-M00253 · 2026-08-07T11:34:04.900000-04:00 · active path

Preceding visible parent: [C072-M00252](part-18.md#m-2385f773-e0db-4669-934f-c5b6a0738188)

**Editorial record note:** Attachment references: M2_12_ACCEPTANCE_WRITE_PHASE_SPECIFICATION(2).csv; M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY(4).csv; M2_12_CAPABILITY_COVERAGE_CATALOG(3).csv; M2_12_DETAIL_RESULT_SET_CATALOG(4).csv; M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX(2).csv; M2_12_GENERATION_EVIDENCE_CATALOG(4).csv; M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION(2).csv; M2_12_NEGATIVE_CONTROL_CATALOG_DESIGN(4).csv; M2_12_POSITIVE_CONTROL_FAMILY_ALLOCATION(3).csv

<!-- BEGIN_SOURCE_MESSAGE -->
Are any of these the missing files?
<!-- END_SOURCE_MESSAGE -->


<a id="m-019bd866-c338-4d50-a557-fcf3177dc8a6"></a>
## Assistant · C072-M00254

C072-M00254 · 2026-08-07T11:34:43.067485-04:00 · active path

Preceding visible parent: [C072-M00253](part-18.md#m-71654619-090c-4127-bdfd-55a628678b17)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **One of these is exactly the missing file**, and I verified it byte-for-byte rather than relying on the filename.

The important result is:

```text
M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX(2).csv

Rows       72
Bytes      23,443
SHA-256    92b71ff85ffae4de9dbb1f68b8bc8942dde5d12234cc7986361ac6573f66932c

Result     EXACT MATCH
```

That is precisely the normative artifact the current design index requires: 72 rows, 23,443 bytes, and that exact SHA-256. [export reference: filecite | turn157file2 | L38-L46]

So **the missing-artifact blocker is resolved**. The `(2)` in your downloaded filename is just the browser-added duplicate suffix; the byte stream itself is the correct canonical artifact.

I also hashed all eight of the other files you just attached. They are all exact matches to their applicable Amendment A design-index authorities:

| Uploaded file | Rows | SHA-256 result |
|---|---:|---|
| `M2_12_ACCEPTANCE_WRITE_PHASE_SPECIFICATION(2).csv` | 8 | **EXACT MATCH** |
| `M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY(4).csv` | 13 | **EXACT MATCH** |
| `M2_12_CAPABILITY_COVERAGE_CATALOG(3).csv` | 20 | **EXACT MATCH** |
| `M2_12_DETAIL_RESULT_SET_CATALOG(4).csv` | 24 | **EXACT MATCH** |
| `M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX(2).csv` | 72 | **EXACT MATCH — previously missing** |
| `M2_12_GENERATION_EVIDENCE_CATALOG(4).csv` | 24 | **EXACT MATCH** |
| `M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION(2).csv` | 27 | **EXACT MATCH** |
| `M2_12_NEGATIVE_CONTROL_CATALOG_DESIGN(4).csv` | 20 | **EXACT MATCH** |
| `M2_12_POSITIVE_CONTROL_FAMILY_ALLOCATION(3).csv` | 10 | **EXACT MATCH** |

For example, the index requires the acceptance-write specification at `053ed725...`, the hash/sequence specification at `abe4b604...`, and the negative-control catalog at `b39be922...`; your copies reproduce all of those identities exactly. [export reference: filecite | turn157file2 | L45-L53]

### What this changes

Our blocker list should now be reduced:

```text
Previously:

1. Evidence applicability matrix missing       BLOCKER
2. Expected-results authority stale            BLOCKER
3. Design-index sidecar stale                  BLOCKER
4. Machine validation JSON stale               BLOCKER


Now:

1. Evidence applicability matrix               RESOLVED — EXACT AUTHORITY FOUND
2. Expected-results authority                  STILL UNRESOLVED
3. Design-index sidecar                        STILL UNRESOLVED
4. Machine validation JSON                     STILL UNRESOLVED
```

There is an important distinction on #2: **none of these nine files is the corrected `M2_12_EXPECTED_RESULTS.json`.** The expected-results file we previously found is still the old 2,926-byte version, whereas the Correction R1 authority calls for the later corrected machine-readable artifact. The old file only contains the basic identities/counts/program sequence and boundaries. [export reference: filecite | turn157file7 | L25-L65]

So this was useful: **you did have the missing 72-row matrix separately, and it is exactly correct.** I would not regenerate or alter any of these nine CSVs. They are good authority files.

If you have other loose M2.12 downloads from that build—especially anything named `M2_12_EXPECTED_RESULTS.json`, `M2_12_DESIGN_DELIVERY_INDEX.md.sha256`, or the Correction R1 validation JSON—those are the ones worth uploading next.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6079076d-ea4b-4015-876f-061112dc1e54"></a>
## Andrew / user · C072-M00255

C072-M00255 · 2026-08-07T12:08:07.608000-04:00 · active path

Preceding visible parent: [C072-M00254](part-18.md#m-019bd866-c338-4d50-a557-fcf3177dc8a6)

**Editorial record note:** Attachment references: M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY(3)(2).csv; M2_12_AMENDMENT_A_DELIVERY_VALIDATION(3)(1).md; M2_12_AMENDMENT_A_DELIVERY_VALIDATION(2).json; M2_12_CORRECTION_R1_FINAL_HASH_RECONCILIATION(1).json; M2_12_CORRECTION_R1_FINAL_HASH_RECONCILIATION(1).md; M2_12_DESIGN_DELIVERY_INDEX(5)(1).md; M2_12_EXPECTED_RESULTS(3).json; M2_12_PHYSICAL_OUTPUT_CORRECTION_R1_RECORD(1).md; M2_12_SOURCE_AND_BUSINESS_DESIGN_AMENDMENT_A_CORRECTION_R1(1)(1).md; M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AMENDMENT_A(2)(1).md; M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AND_BUILD_HANDOFF(4)(1).md; M2_12_SOURCE_GRAPH_EDGE_CATALOG(2)(1).csv

<!-- BEGIN_SOURCE_MESSAGE -->
Completed. This was handled strictly as a **physical-output reconciliation**, not as another design amendment.

The governing Correction R1 instructions specifically required the expected-results authority, index/sidecar, and delivery-validation records to be regenerated against the actual delivered files; Work Package 1 and SQL remain prohibited until re-audit approval.

## Corrected primary artifacts

- Corrected  (historical reference: `sandbox:[session]/M2_12_EXPECTED_RESULTS.json`; referenced bytes not established here)`M2_12_EXPECTED_RESULTS.json` (historical reference: `sandbox:[session]/M2_12_EXPECTED_RESULTS.json`; referenced bytes not established here)
  **236,963 bytes**
  SHA-256: `770061fb9198406eb85f8bea1c79fffd7cbcaceb362068a05191725dbeec2e23`

- Updated  (historical reference: `sandbox:[session]/M2_12_DESIGN_DELIVERY_INDEX.md`; referenced bytes not established here)`M2_12_DESIGN_DELIVERY_INDEX.md` (historical reference: `sandbox:[session]/M2_12_DESIGN_DELIVERY_INDEX.md`; referenced bytes not established here)
  **8,297 bytes**
  SHA-256: `82f9f8da97735012076eb3ea4ba63af1fcf7faa34f075220d2bb079872315c2f`

- Regenerated index SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_DESIGN_DELIVERY_INDEX.md.sha256`; referenced bytes not established here)

```text
82f9f8da97735012076eb3ea4ba63af1fcf7faa34f075220d2bb079872315c2f  M2_12_DESIGN_DELIVERY_INDEX.md
```

- Regenerated machine-readable delivery validation (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_DELIVERY_VALIDATION.json`; referenced bytes not established here)
  **99,548 bytes**
  SHA-256: `a73192f29ae9e2817a8aef5a45ca9f93c1709d722f8b7b33e771259128143cb4`

The machine JSON now actually reports:

```text
status                    PASS
checks_total              334
checks_pass               334
checks_fail               0

design_status
AMENDMENT_A_CORRECTION_R1_READY_FOR_NARROW_RE_AUDIT
```

## Related artifacts that necessarily changed

Because the current expected-results physical identity changed, I also updated the governing Correction R1 record and reissued the human validation report so no current authority points to the obsolete 32,958-byte/`7115...` identity.

- Updated Amendment A Correction R1 authority record (historical reference: `sandbox:[session]/M2_12_SOURCE_AND_BUSINESS_DESIGN_AMENDMENT_A_CORRECTION_R1.md`; referenced bytes not established here)
  SHA-256: `e7d9b33de1667d4d0f13895c72172188dceb4fc10742e3812af5a598c346d1d3`

- Reissued human-readable delivery validation (historical reference: `sandbox:[session]/M2_12_AMENDMENT_A_DELIVERY_VALIDATION.md`; referenced bytes not established here)
  SHA-256: `63f902ccc2938e09307bffd5d85c7f6c12c8d604fd4741cea666e2fbc3150a4b`

The expanded expected-results JSON now machine-readably contains the items that had previously been missing:

```text
Program 220 policy canonical rows             1
Program 222 non-policy canonical rows       133
Canonical families / entities             9 / 134

Certification nodes                          12
Component contracts                          13
Physical source edges                        19

Applicability architecture                    72
Mandatory PASS cells                          72
PASS_NOT_APPLICABLE permitted                  0

Acyclic hash phases                            8
Canonical family set hashes                    9
Hash/sequence specification rows              27
Exact owned sequences                          3

Generation evidence                           24
Positive controls                            128
Negative controls                             20

PRE_WRITE requirements                        47
POST_WRITE_ATOMICITY requirements              1

Detailed result sets                          24
VARIABLE report expectations                   0
```

## Tight independent reconciliation

I performed a second reconciliation after all final writes.

```text
Normative M2.12 design artifacts              16
Exact physical byte-count matches          16 / 16
Exact physical SHA-256 matches             16 / 16
Index sidecar                                 PASS

Independent validation checks             334 / 334 PASS

Accepted M2.11 baseline SHA-256                PASS
ZIP CRC                                        PASS
ZIP entries                              4,819 / 4,819
Numbered stages                            30 / 30
Final stage                               30_M2_11
```

The corrected source graph was also rechecked directly against the accepted M2.11 repository:

```text
Target registry relations resolved         19 / 19
Target source-hash fields present           19 / 19
Source acceptance gates exact               19 / 19
Expected accepted hashes exact              19 / 19
Fully certified physical edges              19 / 19
```

The earlier audit specifically required all 19 physical fields and gates to be validated rather than trusting catalog text alone.

## Final reconciliation records

- Human-readable final hash reconciliation (historical reference: `sandbox:[session]/M2_12_CORRECTION_R1_FINAL_HASH_RECONCILIATION.md`; referenced bytes not established here)
- Machine-readable final hash reconciliation (historical reference: `sandbox:[session]/M2_12_CORRECTION_R1_FINAL_HASH_RECONCILIATION.json`; referenced bytes not established here)
- Physical-output correction history record (historical reference: `sandbox:[session]/M2_12_PHYSICAL_OUTPUT_CORRECTION_R1_RECORD.md`; referenced bytes not established here)

The machine reconciliation concludes:

```text
status                            PASS
normative_artifacts                 16
normative_byte_matches              16
normative_sha256_matches            16
index_sidecar_status              PASS

business_design_changed           false
source_graph_changed              false
sql_generated                     false
```

## Unchanged current source/design authorities

No source/business semantics were altered. In particular, the corrected 19-edge source graph remains unchanged from the substantive Correction R1:

- Current physical source-graph authority (historical reference: `sandbox:[session]/M2_12_SOURCE_GRAPH_EDGE_CATALOG.csv`; referenced bytes not established here)
- Integrated M2.12 design freeze (historical reference: `sandbox:[session]/M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AND_BUILD_HANDOFF.md`; referenced bytes not established here)
- Amendment A (historical reference: `sandbox:[session]/M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AMENDMENT_A.md`; referenced bytes not established here)
- Accepted source/contract inventory (historical reference: `sandbox:[session]/M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY.csv`; referenced bytes not established here)

Final state:

```text
Accepted M2.11 baseline                    LOCKED / UNCHANGED
M2.12 business purpose                     LOCKED / UNCHANGED
Amendment A Correction R1                  READY FOR NARROW RE-AUDIT

Physical delivery mismatch                 RESOLVED
Normative hash reconciliation              PASS

M2.12 final design freeze                  HOLD PENDING RE-AUDIT
Work Package 1                             NOT AUTHORIZED
SQL                                        NOT GENERATED
PostgreSQL                                 NOT EXECUTED
Module 3                                   NOT AUTHORIZED
Production                                 NOT AUTHORIZED
```

No Amendment B was created, no business design was reopened, and no SQL or implementation package was produced.
<!-- END_SOURCE_MESSAGE -->
