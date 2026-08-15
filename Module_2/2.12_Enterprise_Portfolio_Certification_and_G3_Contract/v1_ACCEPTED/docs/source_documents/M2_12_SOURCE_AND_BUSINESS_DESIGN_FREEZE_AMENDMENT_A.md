# Merchant Sales-Based Financing Strategy Simulator
# M2.12 — Enterprise Portfolio Certification & Consumption Contract
## Source & Business Design Freeze Amendment A — Correction R1 Authority Integrated

## 0. Amendment status and scope

```text
Document identity                         M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AMENDMENT_A
Amendment status                          CORRECTION R1 INTEGRATED — READY FOR NARROW RE-AUDIT
Accepted M2.11 baseline                   LOCKED / UNCHANGED
M2.12 business purpose                    LOCKED / UNCHANGED
M2.12 Work Package 1                      NOT AUTHORIZED
M2.12 SQL                                 NOT GENERATED
M2.12 PostgreSQL execution                NOT AUTHORIZED
Module 3                                  NOT AUTHORIZED
Production deployment                     NOT AUTHORIZED
```

This bounded amendment resolves the implementation-affecting gaps identified in the independent audit of the original M2.12 source and business design. It does not redesign M2.12 and does not reopen:

- the accepted M2.11 baseline;
- stage `31_M2_12`;
- `M2_12_METHOD_V1`;
- `M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1`;
- `M2_G3_CONSUMPTION_BUNDLE v1`;
- `M2_G3_BUNDLE_SCHEMA_V1`;
- `G3_M2_CONTRACT`;
- 12 certification nodes;
- 13 component contracts;
- 20 capability rows;
- nine canonical families;
- 134 canonical entities;
- 1,500 application, 59 operational-account, and 24 strategy/scope consumption rows;
- 128 positive controls;
- 20 negative controls;
- 48 acceptance requirements;
- 24 detailed result sets;
- Programs 220–227 and Recoveries 220A, 222A, 222B, and 223A;
- all non-production, no-legal-certification, no-empirical-optimization, no-Module-3-execution, and no-deployment boundaries.

The amended precedence is:

```text
1. Accepted M2.11 full-project repository and accepted-package records
2. Revised M2.12 Source & Business Design Freeze and Build Handoff
3. This Amendment A
4. M2.12 Source & Business Design Amendment A Correction R1
5. Every machine-readable M2.12 design catalog listed in the delivery index
6. A later approved Work Package 1 implementation specification
7. Approved output from the immediately preceding work package
```

No implementation work may infer a rule contrary to this amendment or fill a remaining gap ad hoc.

---

# A1. Canonical policy-row ownership

## A1.1 Frozen writer model

```text
Program 220
Installs M2.12 structures, functions, constraints, triggers, read-only views,
and the one approved M2.12 policy canonical row.

Program 222
Is the sole normal writer of the remaining 133 non-policy
certification/G3 canonical rows.

Existing policy canonical row             1
Program 222 canonical writes             133
                                         ---
Total canonical entities                 134
```

The earlier statement that Program 222 is the sole writer of all canonical rows is superseded. The controlling wording is:

> Program 222 is the sole normal writer of M2.12 **non-policy certification and G3 canonical rows**.

## A1.2 Frozen policy identity

```text
Policy code
M2_12_ENTERPRISE_PORTFOLIO_CERTIFICATION_POLICY_V1

Policy version
1

Policy status
APPROVED

Methodology
M2_12_METHOD_V1

Bundle
M2_G3_CONSUMPTION_BUNDLE v1

Schema
M2_G3_BUNDLE_SCHEMA_V1

Acceptance gate
G3_M2_CONTRACT
```

## A1.3 Exact configuration payload

The policy `configuration_payload` is a JSONB object containing exactly these governed sections:

```text
module identity
methodology, policy, bundle, version, schema, and gate identity

accepted baseline
M2.11 accepted project SHA-256
M2.11 contract set hash
M2.11 combined set hash
M2.11 registry row hash

expected design counts
12 source nodes
13 component contracts
19 source-graph edges
72 evidence-certification rows
20 capability rows
9 canonical families
134 canonical entities
1,500 application consumption rows
59 operational-account rows
24 strategy/scope rows
24 generation evidence rows
128 positive controls
20 negative controls
48 acceptance requirements
24 detailed result sets

boundary flags
synthetic only
no PII
certification only
no production action
no external-system update
no legal or regulatory certification
no empirical or causal optimization
no Module 3 SQL or execution
```

No execution-generated hash or outcome may be placed into the frozen policy payload.

## A1.4 Policy hash rules

```text
configuration_hash
=
md5(configuration_payload::jsonb::text)
```

```text
policy row_hash
=
md5(
    (
        to_jsonb(policy_row)
        - 'policy_profile_id'
        - 'row_hash'
        - 'created_at'
        - 'updated_at'
    )::text
)
```

All fields must be cast to final physical target types before the row hash is calculated.

## A1.5 Program 220 rerun and recovery

Program 220 may be idempotent only when every existing M2.12 structure and the policy row reconstruct exactly. It must fail closed on:

- conflicting policy identity;
- a different configuration payload or hash;
- an unexpected policy row count;
- any Program 222 non-policy canonical row;
- a generated or later M2.12 lifecycle.

Program 220A may repair or remove only an incomplete M2.12 structural/policy installation when:

```text
M2.12 non-policy canonical rows            0
M2.12 generation evidence rows             0
M2.12 acceptance evidence rows             0
G3 gate result rows                        0
run status                                 M2_11_ACCEPTED
```

Program 220A may never delete or change a successfully installed matching policy row merely to permit a rerun.

---

# A2. Acyclic deterministic hash architecture

## A2.1 Frozen construction sequence

Program 222 must use this exact order:

```text
1. Cast every canonical value to its exact physical target type and typmod.

2. Calculate and persist all non-registry physical row hashes:
   POLICY already exists from Program 220;
   STAGE_CERTIFICATION;
   CONTRACT_COMPONENT;
   EVIDENCE_CERTIFICATION;
   CONTRACT_REPRODUCTION;
   CAPABILITY_COVERAGE;
   LATEST;
   ARCHIVE.

3. Calculate the eight non-registry family set hashes:
   POLICY;
   STAGE_CERTIFICATION;
   CONTRACT_COMPONENT;
   EVIDENCE_CERTIFICATION;
   CONTRACT_REPRODUCTION;
   CAPABILITY_COVERAGE;
   LATEST;
   ARCHIVE.

4. Calculate the registry row hash using only stable, non-derived
   registry identity, source-authority, configuration, and count fields.

5. Calculate REGISTRY_SET_HASH from the finalized persisted registry row hash.

6. Calculate CONTRACT_SET_HASH using the exact frozen field order.

7. Calculate the ordered 134-entity COMBINED_SET_HASH.

8. Independently reconstruct all row, family, contract, and combined
   identities from persisted physical rows before generation evidence
   is inserted and before Program 222 commits.
```

No earlier preimage may depend on a value constructed in a later step.

## A2.2 Registry row-hash exclusions

The registry row hash must exclude:

```text
registry_id

contract_status
generated_at
validated_at
accepted_at
created_at
updated_at

row_hash

policy_set_hash
stage_certification_set_hash
contract_component_set_hash
evidence_certification_set_hash
contract_reproduction_set_hash
capability_coverage_set_hash
latest_set_hash
archive_set_hash
registry_set_hash

contract_set_hash
combined_set_hash
```

This eliminates the circular dependency:

```text
registry row hash
→ registry set hash
→ stored in registry
→ registry row hash
```

## A2.3 Latest and archive identities

For G3 latest:

```text
contract_row_hash
=
md5(
    (
        to_jsonb(latest)
        - 'row_hash'
        - 'contract_row_hash'
        - 'created_at'
    )::text
)
```

The preimage consists only of the fully target-typed stable G3 contract business payload.

```text
latest row_hash
=
md5(
    (
        to_jsonb(latest)
        - 'row_hash'
        - 'created_at'
    )::text
)
```

This second hash includes the finalized `contract_row_hash`.

For G3 archive:

```text
contract_payload
=
to_jsonb(latest)
- 'row_hash'
- 'created_at'
```

The archive stores:

```text
source_latest_row_hash = latest.row_hash
contract_row_hash      = latest.contract_row_hash
contract_payload       = exact payload above
```

```text
archive_row_hash
=
md5(
    (
        to_jsonb(archive)
        - 'archive_id'
        - 'archive_row_hash'
        - 'created_at'
    )::text
)
```

The archive family set hash uses `archive_row_hash`.

## A2.4 Contract-set hash

The exact preimage order is:

```text
bundle_code
bundle_version
schema_version
methodology_version
policy_configuration_hash

policy_set_hash
stage_certification_set_hash
contract_component_set_hash
evidence_certification_set_hash
contract_reproduction_set_hash
capability_coverage_set_hash
latest_set_hash
archive_set_hash
registry_set_hash

latest_contract_row_hash
archive_contract_row_hash
registry_row_hash

accepted_m2_11_contract_set_hash
accepted_m2_11_combined_set_hash
accepted_m2_11_registry_row_hash
```

Every field is formatted as target-typed text and concatenated with `|` in this exact order before MD5.

## A2.5 Combined hash

```text
combined_set_hash
=
md5(
    string_agg(
        entity_type || '|' || entity_key || '|' || row_hash,
        '|' ORDER BY entity_type, entity_key
    )
)
```

It covers exactly 134 persisted canonical rows across all nine families.

The field-level preimages, exclusions, types, ordered keys, and reconstruction requirements are frozen in:

```text
M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION.csv
```

---

# A3. Complete source graph

## A3.1 Frozen edge count

The complete physically accepted source graph contains 19 required edges:

```text
M1.15 → M1.17 direct component source                    1
M1.16 → M1.17 direct component source                    1
M1.17 → M2.1 through M2.9 → M2.10 linear edges          10
M1.3 → M2.2 auxiliary application-request authority      1
M1.6 → M2.5 auxiliary scenario authority                 1
M2.11 direct source edges                                 5
                                                           --
Total required source edges                              19
```

The 19 rows are frozen in:

```text
M2_12_SOURCE_GRAPH_EDGE_CATALOG.csv
```

Each edge defines:

- source and target nodes;
- source contract/registry/gate;
- the target registry source field;
- expected accepted source hash;
- primary, auxiliary, component, or multi-source role;
- physical certification method;
- required PASS status.

## A3.2 Auxiliary accepted anchors

The design now explicitly includes:

```text
M1.3 → M2.2

source gate
M1_3_APPLICATION_REQUEST

source application hash
01485256b9b5748fb412743d35ced602
```

```text
M1.6 → M2.5

source gate
M1_6_MATCHED_SCENARIO_OVERLAYS

source combined hash
3f85921bf6fc30ddc6cee146085e58c5
```

These are lineage anchors, not new M2.12 certification nodes or component contracts. The frozen counts remain 12 nodes and 13 component contracts.

## A3.3 Source-graph certification

Program 221 must validate all 19 physical edges.

Program 222 must persist source-graph certification outcomes within the relevant stage/component/evidence rows and generation evidence.

Program 223 must independently reconstruct all 19 edges.

Program 225 must require:

```text
14 non-M2.11 source edges          14 / 14 PASS
M2.11 direct source edges            5 / 5 PASS
Source-edge hash/status breaks             0
```

Detail Result Set 06 returns exactly 19 rows.

---

# A4. Physically testable historical acceptance

M2.12 must not assert that eleven historical run statuses are simultaneously present in one mutable run-registry row.

The accepted chain is certified through this exact physical method:

```text
Current governed run row
run_code       M1_V0_2_BASELINE_BUILD
run_version    1
run_status     M2_11_ACCEPTED
```

```text
M2.1–M2.11 contract registries
11 / 11 rows at the expected grains
11 / 11 contract_status = ACCEPTED
exact contract, schema, methodology, count, and hash identities
```

```text
M2.1–M2.11 stage gates
11 / 11 exact gate IDs
11 / 11 review_version = 1
11 / 11 result_status = PASS
```

```text
Acceptance evidence/provenance
M2_1_ACCEPTANCE_SUMMARY through M2_11_ACCEPTANCE_SUMMARY
present and exact under their accepted source authority
```

M1.17 remains separately certified by:

```text
M1.17 G2 registry ACCEPTED
G2_M1_CONTRACT review_version 1 PASS
M1_17_ACCEPTANCE_SUMMARY present
physical G2 identity reconstructed
```

This method supersedes the ambiguous phrase “all eleven stage run statuses are accepted.”

---

# A5. Evidence-certification applicability

## A5.1 Final applicability decision

All six evidence families apply to all twelve certification nodes.

```text
12 nodes × 6 evidence families = 72 rows

Mandatory PASS                         72
PASS_NOT_APPLICABLE permitted           0
FAIL permitted at G3 acceptance         0
```

The six families remain:

```text
ACCEPTANCE_LIFECYCLE
POSITIVE_VALIDATION
NEGATIVE_CONTROLS
CANONICAL_IDENTITY
LATEST_ARCHIVE_REPRODUCTION
STAGE_BOUNDARY
```

No implementation may choose `PASS_NOT_APPLICABLE`.

The exact 72-row source, pattern, expected count/status/hash, and rationale matrix is:

```text
M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX.csv
```

## A5.2 Acceptance evidence interpretation

`ACCEPTANCE_LIFECYCLE` certifies registry, gate, and acceptance evidence/provenance rather than relying on a historical mutable run status.

`LATEST_ARCHIVE_REPRODUCTION` applies to M2.2 as a node through both of its component contracts.

`STAGE_BOUNDARY` applies to every node and requires zero unresolved blocking, unauthorized-source, premature-stage, or production-action findings.

---

# A6. Exact G3 gate identity and Program 225 write phases

## A6.1 Existing gate catalog identity

Programs 220, 221, and 225 must verify and must not redefine or update this exact accepted row:

```text
gate_id       G3_M2_CONTRACT
gate_name     Module 2 Contract
module_code   M2
severity      BLOCKING
active_flag   TRUE
description   Offer contract accepted.
```

The accepted legacy description remains unchanged. The broader M2.12 scope is governed by the M2.12 policy, capability catalog, certification evidence, and acceptance requirements.

## A6.2 Acceptance requirement phases

```text
M2_12_ACC_001 through M2_12_ACC_047
PRE_WRITE

M2_12_ACC_048
POST_WRITE_ATOMICITY
```

Program 225 must:

1. require run `M2_12_VALIDATED` and registry `VALIDATED`;
2. require zero prior gate result rows for:
   ```text
   run_id + G3_M2_CONTRACT + review_version 1
   ```
3. require zero prior `M2_12_ACCEPTANCE_SUMMARY` evidence rows;
4. evaluate Requirements 001–047;
5. capture the immutable pre-write fingerprint;
6. write the gate, acceptance evidence, and lifecycle updates in one transaction;
7. evaluate Requirement 048;
8. reconstruct the immutable post-write fingerprint;
9. commit only when all 48 requirements are PASS and both fingerprints are identical.

## A6.3 Acceptance evidence identity

```text
evidence_code
M2_12_ACCEPTANCE_SUMMARY

segment_key
ENTERPRISE_PORTFOLIO_G3

metric_name
G3_ACCEPTANCE_STATUS

metric_value_text
M2_12_ACCEPTED|ACCEPTED|PASS|48/48

unit_code
ACCEPTANCE

status
PASS
```

Its interpretation must state that acceptance is limited to the as-built synthetic certification and G3 contract boundary and does not authorize production deployment or Module 3 execution.

## A6.4 Immutable pre/post fingerprint

The pre-write and post-write fingerprints cover:

```text
nine canonical family counts
134 physical row hashes
nine ordered family set hashes
G3 latest/archive exact identity
registry row hash
contract set hash
combined set hash
```

Only permitted mutable lifecycle fields and the newly written gate/evidence rows may differ.

The exact phases are frozen in:

```text
M2_12_ACCEPTANCE_WRITE_PHASE_SPECIFICATION.csv
```

A committed version-1 acceptance rerun fails closed.

---

# A7. Negative-control execution specification

The 20 negative-control codes and total remain unchanged.

Each control now freezes:

- control family;
- mutation target;
- exact injected defect;
- intended physical constraint, trigger, or assertion;
- expected SQLSTATE;
- expected message prefix;
- isolation preconditions;
- rollback/isolation method;
- identity-sequence treatment;
- required before/after fingerprint;
- source-authority and traceability reference.

The authoritative specification is:

```text
M2_12_NEGATIVE_CONTROL_CATALOG_DESIGN.csv
```

## A7.1 Isolation requirements

Every control must use one of these governed boundaries:

```text
temporary fixture with no accepted-source DML

or

BEGIN
→ SAVEPOINT
→ expected rejected mutation
→ ROLLBACK TO SAVEPOINT
→ postflight fingerprint
→ final ROLLBACK
```

No test may commit.

## A7.2 Postflight fingerprint

Every negative control requires no change to:

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

M2.12 uses exactly three sequence-backed identity columns, following the accepted project pattern:

```text
msbf_ctl.m2_12_policy_profile_policy_profile_id_seq
msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq
msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq
```

The five snapshot families, G3 latest, and their composite business keys use no sequence-backed surrogate identity.

A negative control that can invoke one of the three sequences must capture:

```text
last_value
is_called
```

before the test and must restore or prove the exact same values after rollback. Controls against sequence-free tables must state `NO_OWNED_SEQUENCE`.

No sequence drift may be hidden.

---

# A8. Detailed-report operability

## A8.1 Transaction boundary

Programs 226 and 227 run in ordinary transactions with persistent-state read-only behavior.

They may:

- create, populate, index, analyze, and drop `tmp_report_` temporary objects;
- materialize an expensive reporting intermediate once per session.

They may not perform persistent DML or persistent DDL.

PostgreSQL transaction-level `READ ONLY` is not required because it would prohibit needed temporary reporting construction.

## A8.2 Frozen cardinalities

The 24 successful result-set cardinalities are:

```text
01  1
02  1
03  1
04  12
05  13
06  19
07  72
08  13
09  13
10  3
11  1,500
12  3
13  59
14  24
15  24
16  3
17  8
18  20
19  1
20  1
21  12
22  6
23  0
24  0
```

Result Set 11 is full 1,500-row detail, not a sample.

Result Set 13 is full 59-row operational-account detail.

Result Sets 23 and 24 must return zero rows on success while retaining explicit stable headers.

The authoritative source, grain, projection, order, and zero-row behavior for every result set are frozen in:

```text
M2_12_DETAIL_RESULT_SET_CATALOG.csv
```

---

# A9. Generation-evidence expectations

The total remains 24.

The revised evidence catalog now defines for every row:

- authoritative source;
- observed calculation;
- expected value;
- comparison operator;
- ordered business key;
- observed-value format;
- interpretation;
- required blocking status.

## A9.1 Registry set-hash evidence

The ninth family hash is now explicitly evidenced:

```text
M2_12_REGISTRY_SET_HASH
```

## A9.2 Evidence-slot reallocation

The former separate totals:

```text
COMPONENT_LATEST_ROWS_TOTAL
COMPONENT_ARCHIVE_ROWS_TOTAL
```

are consolidated as:

```text
M2_12_COMPONENT_LATEST_ARCHIVE_ROWS_TOTAL
expected observed value = 7129|7129
```

The released slot is used for the registry family set hash. The total remains exactly 24.

## A9.3 Source graph evidence

The source-graph generation evidence is:

```text
M2_12_SOURCE_GRAPH_EDGES
expected observed value = 19|0
```

meaning 19 required edges and zero hash/status breaks.

---

# A10. Normative build-handoff attachment set

The separate build conversation must receive all normative design artifacts, not a partial selection.

Required attachments:

```text
Accepted M2.11 full-project ZIP
Matching accepted external SHA-256 sidecar
M2.11 acceptance record

M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AND_BUILD_HANDOFF.md
M2_12_SOURCE_AND_BUSINESS_DESIGN_FREEZE_AMENDMENT_A.md
M2_12_ACCEPTED_SOURCE_AND_CONTRACT_INVENTORY.csv
M2_12_SOURCE_GRAPH_EDGE_CATALOG.csv
M2_12_EVIDENCE_CERTIFICATION_APPLICABILITY_MATRIX.csv
M2_12_HASH_PREIMAGE_AND_SEQUENCE_SPECIFICATION.csv
M2_12_ACCEPTANCE_WRITE_PHASE_SPECIFICATION.csv
M2_12_CAPABILITY_COVERAGE_CATALOG.csv
M2_12_EXPECTED_RESULTS.json
M2_12_GENERATION_EVIDENCE_CATALOG.csv
M2_12_POSITIVE_CONTROL_FAMILY_ALLOCATION.csv
M2_12_NEGATIVE_CONTROL_CATALOG_DESIGN.csv
M2_12_ACCEPTANCE_REQUIREMENT_MATRIX.csv
M2_12_DETAIL_RESULT_SET_CATALOG.csv
M2_12_BUILD_CHAT_OPENING_AND_WORK_PACKAGE_PROMPTS.md
M2_12_DESIGN_DELIVERY_INDEX.md
```

The delivery index is the authority for each artifact SHA-256.

A build conversation missing any normative artifact must stop before Work Package 1.

---

# A11. Revised program ownership and boundaries

```text
Program 220
Persistent structures, functions, constraints, triggers, views,
and exactly one approved policy canonical row.

Program 221
Persistent-state read-only preflight.
Verifies exact G3 gate identity, 19 source edges, physical historical
acceptance, 72-row applicability design, pristine targets, and no Module 3.

Program 222
Sole normal writer of 133 non-policy canonical rows.
Builds exactly:
12 stage certification
13 component contracts
72 evidence certification
13 contract reproduction
20 capability coverage
1 G3 latest
1 G3 archive
1 G3 registry
= 133

Program 223
128 independent positive controls.

Program 224
20 isolated negative controls under the expanded execution specification.

Program 225
47 PRE_WRITE requirements plus one POST_WRITE_ATOMICITY requirement.

Programs 226–227
Persistent-state read-only reporting with temporary `tmp_report_` objects only.
```

The canonical arithmetic remains:

```text
Program 220 policy canonical row        1
Program 222 non-policy canonical rows 133
                                       ---
Total                                  134
```

---

# A12. Amendment validation and disposition

The Amendment A design artifacts must mechanically reconcile to:

```text
Source-contract inventory rows                  13
Certification nodes                             12
Source-graph edges                              19
Evidence applicability rows                     72
Capability rows                                 20
Generation evidence rows                        24
Positive-control families                       10
Positive controls allocated                    128
Negative controls                               20
Acceptance requirements                         48
PRE_WRITE requirements                          47
POST_WRITE_ATOMICITY requirements                1
Detailed result sets                            24
Canonical families                               9
Canonical entities                             134
Component latest rows                        7,129
Component archive rows                       7,129
```

Unchanged artifacts must remain byte-identical:

```text
M2_12_CAPABILITY_COVERAGE_CATALOG.csv
M2_12_POSITIVE_CONTROL_FAMILY_ALLOCATION.csv
```

## Final amended state

```text
ACCEPTED M2.11 BASELINE                    LOCKED
M2.12 BUSINESS PURPOSE                     LOCKED
M2.12 HIGH-LEVEL ARCHITECTURE              LOCKED
M2.12 AMENDMENT A CORRECTION R1            READY FOR NARROW RE-AUDIT
M2.12 FINAL DESIGN FREEZE                  HOLD PENDING RE-AUDIT APPROVAL
M2.12 WORK PACKAGE 1                       NOT AUTHORIZED
M2.12 SQL                                  NOT GENERATED
POSTGRESQL                                 NOT EXECUTED
MODULE 3                                   NOT AUTHORIZED
PRODUCTION                                 NOT AUTHORIZED
```

Stop after Amendment A Correction R1 and wait for explicit narrow re-audit approval.
