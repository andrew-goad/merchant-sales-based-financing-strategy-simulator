# M2.11 Plan Review

Part 09 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-08.md)
[Next part](part-10.md)

<a id="m-fd44d678-89e1-4497-8a1d-17d3c55e49d1"></a>
## Assistant · C081-M00127

C081-M00127 · 2026-08-07T20:26:46.225661-04:00 · active path

Preceding visible parent: [C081-M00126](part-08.md#m-13bf7bcd-a5a6-4f4c-b420-87b1237a38a7)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Work Package 1 R3 complete

The R2 audit correctly retained the WP1 hold after finding four remaining implementation blockers—adapter schema/dependency closure, source-edge certification, and node-specific stage-boundary evidence—plus one physical source-authority packaging blocker. It also confirmed that the R1/R2 physical-field corrections, G3 copied-contract identity, thirteen component-reproduction methods, type/domain controls, hash dependency order, sequence recovery, Program 221 transaction model, constraints/indexes, and consumption-view joins should remain intact. [export reference: filecite | turn24file0 | L24-L50]

I produced the bounded correction:

```text
M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R3
```

```text
Correction construction                    COMPLETE
Static controls                            3,393 / 3,393 PASS
Review-bundle controls                        15 / 15 PASS
Known static failures                         0

Accepted M2.11 baseline                    LOCKED / UNCHANGED
M2.12 frozen business design               LOCKED / UNCHANGED
Frozen business-semantic changes             0

WP1 R3 final approval                      HOLD — NARROW RE-REVIEW
WP2 authorization                          NO
Program 220                                NOT STARTED
Programs 220–227                           NOT GENERATED
Recovery SQL                               NOT GENERATED
PostgreSQL                                 NOT EXECUTED
Implementation package                    NOT CREATED
Module 3                                   NOT AUTHORIZED
Production                                 NOT AUTHORIZED
```

## 1. Adapter schema and selector/join closure

The audit found 11 undeclared adapter-field pairs and 161 unresolved references affecting 127 of the 327 canonical mapping rows. It required closure across the source expression, row selector, physical join predicate, adapter expression, filter, and adapter join—not merely the mapping’s primary source expression. [export reference: filecite | turn24file0 | L91-L223]

R3 now governs:

```text
Canonical mappings                         327 / 327 PASS
Canonical mapping specificity              327 / 327 PASS
Adapter specification rows                    2,322
Unique adapter output schemas              612 / 612 PASS
Unresolved selector/join references                  0
Generic physical mapping placeholders                0
```

The corrected architecture includes:

- exact run-context attachment through a one-row `CROSS JOIN` for static design adapters;
- complete node, component, evidence, and reproduction observation keys;
- a three-stage policy construction chain:
  - `tmp_src_m2_12_policy_seed_base`;
  - `tmp_src_m2_12_policy_seed`;
  - `tmp_src_m2_12_policy_typed`;
- exact target typing before policy hashing;
- a one-row `tmp_cert_m2_12_boundary_aggregate` governing the six certification/boundary flags and capability payloads;
- complete resolution of every `alias.field` reference used by canonical mapping construction.

## 2. Internal helper and dependency closure

The audit identified four undeclared helper relations, missing internal grain fields, and ungoverned `pos`, `neg`, and `edge_src` dependencies. It required every intermediate to have an exact schema, grain, key, source, row count, construction expression, lifecycle, and type plan—or be eliminated. [export reference: filecite | turn24file0 | L225-L276]

R3 now records:

```text
Governed transaction-local helpers          40 / 40 PASS
Internal adapter dependencies               89 / 89 PASS
Temporary/helper identifiers referenced             40
Undeclared helper relations                          0
Dependencies with missing output fields              0
Dependency expected-row mismatches                    0
```

The governed helpers include the previously unresolved:

```text
tmp_src_m2_12_component_observation_base
tmp_cert_m2_12_reproduction_observation_base
tmp_latest_m2_12_g3_seed
tmp_hash_m2_12_canonical_entity_source
```

as well as exact positive- and negative-evidence aggregates, policy construction relations, source-edge physical staging, stage-boundary base/final observations, and the G3 boundary aggregate.

The final canonical-entity source is explicitly defined as a nine-family `UNION ALL` containing exactly 134 rows at:

```text
module1_run_id
+ entity_type
+ entity_key
+ row_hash
```

## 3. Executable source-edge certification

The audit determined that the R2 edge adapter did not separately establish the accepted source hash, target-recorded source hash, frozen expected hash, and source-gate status. It also established that 19 distinct physical edges correspond to 21 component-edge requirements because two M2.2 edges apply to both the request and pricing components. [export reference: filecite | turn24file0 | L278-L400]

R3 now uses two distinct governed layers:

```text
Physical edge observations                  19
Component-edge requirements                 21
```

Every one of the 19 edge observations carries:

```text
module1_run_id
edge_sequence
edge_code
target_node_code
expected_source_hash
observed_accepted_source_hash
observed_target_recorded_source_hash
source_gate_status
source_hash_mismatch_flag
target_hash_mismatch_flag
edge_status
```

Required reconciliation:

```text
accepted source hash
=
frozen expected hash
=
target registry recorded source hash

and

source acceptance gate status = PASS
```

Results:

```text
Physical edge certifications                19 / 19 PASS
Component-edge memberships                  21 / 21 PASS
Missing edge identities                              0
Duplicate component-edge keys                        0
Source/target/gate reconciliation gaps                0
```

## 4. Node-specific stage-boundary certification

The audit found that all 12 R2 `STAGE_BOUNDARY` cells effectively used the same global wildcard logic and could pass when the node-specific governing evidence was absent. It required twelve source-present, non-vacuous methods with exact evidence patterns, zero findings, accepted detail-boundary authority, and node-specific fingerprints. [export reference: filecite | turn24file0 | L402-L461]

R3 now defines one method per certification node:

```text
M1.17
M2.1
M2.2
M2.3
M2.4
M2.5
M2.6
M2.7
M2.8
M2.9
M2.10
M2.11
```

Each method includes:

- exact required evidence codes;
- exact acceptance evidence and gate identity;
- separate stage-prefixed boundary and blocking predicates;
- mandatory governing-source presence;
- exact accepted zero-row detail-report path;
- accepted report byte size and SHA-256;
- required stable header;
- zero observed boundary findings;
- deterministic node-specific evidence fingerprint;
- fail-closed behavior when evidence or report authority is absent.

```text
Node-specific methods                       12 / 12 PASS
Global unscoped methods                              0
Malformed combined wildcard patterns                 0
Vacuous absence-only certification methods           0
Missing accepted detail-report authorities           0
```

## 5. Physical source-authority paths

The R2 audit found that its path controls represented a different workspace from the submitted ZIP: 20 files existed only under attachment-added aliases and one declared R1 correction record was absent. [export reference: filecite | turn24file0 | L463-L517]

The R3 bundle now contains only clean canonical filenames:

```text
Package entries audited                    54
Clean canonical filenames                  54 / 54 PASS
Attachment-disambiguation aliases                   0
Missing declared authorities                        0
Unexpected entries                                  0
Case-insensitive duplicate paths                    0
Unsafe or traversal paths                           0
```

The retained R1 and R2 correction records are both physically present. R2 review and source-authority artifacts retained for provenance are explicitly marked noncurrent; R3 is the current source authority.

## 6. Preserved R1 and R2 controls

R3 does not reopen the areas already accepted by the R2 audit:

```text
Type/domain definitions                   1,172 / 1,172 PASS
Hash dependency DAG                        acyclic / 9 phases
Owned identity sequences                   3 / 3 governed
Program 221 transaction model              ordinary transaction;
                                           persistent-state read-only
Physical constraints/indexes               81 definitions
Consumption-view join plan                 23 joins across 7 views
Accepted physical field references         648 / 648 PASS
Component reproduction methods             13 / 13 PASS
G3 copied-contract identity                 PASS
```

No source node, component contract, source edge, evidence cell, capability status, canonical family, count, control code, acceptance phase, report cardinality, program number, recovery number, non-production boundary, or Module 3 boundary changed, as required by the audit’s bounded R3 direction. [export reference: filecite | turn24file0 | L550-L621]

# R3 review-bundle identity

```text
Package
M2_12_Build_WP1_R3.zip

Bytes
363,246

SHA-256
936118b6d39f67ff0b68d4c5599de482148b85cc0763a0733482f89320a8e7bf

ZIP entries
54

ZIP CRC
PASS

Complete extraction
PASS

Source-versus-ZIP hashes
PASS
```

## Primary delivery

- Download the M2.12 WP1 R3 review bundle (historical reference: `sandbox:[session]/M2_12_Build_WP1_R3.zip`; referenced bytes not established here)
- Download the matching SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_Build_WP1_R3.zip.sha256`; referenced bytes not established here)
- Read the R3 bundle-validation report (historical reference: `sandbox:[session]/M2_12_Build_WP1_R3_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the 15 package-validation controls (historical reference: `sandbox:[session]/M2_12_Build_WP1_R3_VALIDATION_CONTROLS.csv`; referenced bytes not established here)
- Download the machine-readable validation summary (historical reference: `sandbox:[session]/M2_12_Build_WP1_R3_VALIDATION_SUMMARY.json`; referenced bytes not established here)

The ZIP is a **static WP1 audit-review bundle**, not an implementation or ready-for-execution package.

# Current source authority

```text
WP1 Source Authority R3 SHA-256
1e84246c6da46b16269a3595e3d3490f84253958cedffd93e6d7a8ef69e22d32

WP1 R3 Source Identity SHA-256
703c3113157126f8dfd06b55f47324de07632e55292dfc62f92a75349cd664e4
```

- WP1 Source Authority R3 (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WP1_SOURCE_AUTHORITY_R3.md`; referenced bytes not established here)
- Complete R3 source-identity inventory (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WP1_R3_SOURCE_IDENTITY.csv`; referenced bytes not established here)
- Implementation Control Correction R3 (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R3.md`; referenced bytes not established here)
- WP1 R3 review (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WORK_PACKAGE_1_REVIEW.md`; referenced bytes not established here)
- Five-finding remediation matrix (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WP1_R3_FINDING_REMEDIATION_MATRIX.csv`; referenced bytes not established here)

# Core WP1 R3 deliverables

| Deliverable | File |
|---|---|
| Consolidated implementation specification | M2_12_CONSOLIDATED_IMPLEMENTATION_SPECIFICATION.md (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_CONSOLIDATED_IMPLEMENTATION_SPECIFICATION.md`; referenced bytes not established here) |
| Physical object catalog | M2_12_PHYSICAL_OBJECT_CATALOG.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_PHYSICAL_OBJECT_CATALOG.csv`; referenced bytes not established here) |
| Source-to-target mapping | M2_12_SOURCE_TO_TARGET_MAPPING.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_SOURCE_TO_TARGET_MAPPING.csv`; referenced bytes not established here) |
| Stage and contract source authority | M2_12_STAGE_AND_CONTRACT_SOURCE_AUTHORITY.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_STAGE_AND_CONTRACT_SOURCE_AUTHORITY.csv`; referenced bytes not established here) |
| Consumption-view mapping | M2_12_CONSUMPTION_VIEW_MAPPING.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_CONSUMPTION_VIEW_MAPPING.csv`; referenced bytes not established here) |
| Ordered hash specification | M2_12_ORDERED_HASH_SPECIFICATION.md (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_ORDERED_HASH_SPECIFICATION.md`; referenced bytes not established here) |
| Program responsibility matrix | M2_12_PROGRAM_RESPONSIBILITY_MATRIX.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_PROGRAM_RESPONSIBILITY_MATRIX.csv`; referenced bytes not established here) |
| Transaction and mutation matrix | M2_12_TRANSACTION_AND_MUTATION_MATRIX.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_TRANSACTION_AND_MUTATION_MATRIX.csv`; referenced bytes not established here) |
| Type and precision dictionary | M2_12_TYPE_PRECISION_DICTIONARY.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_TYPE_PRECISION_DICTIONARY.csv`; referenced bytes not established here) |
| Implementation invariants—257 controls | M2_12_IMPLEMENTATION_INVARIANTS.md (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_IMPLEMENTATION_INVARIANTS.md`; referenced bytes not established here) |

# New R3 physical-control authorities

## Adapter and helper closure

- Canonical Source Adapter Specification—2,322 rows (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_CANONICAL_SOURCE_ADAPTER_SPECIFICATION.csv`; referenced bytes not established here)
- Canonical Adapter Output Resolution Audit—327/327 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_CANONICAL_ADAPTER_OUTPUT_RESOLUTION_AUDIT.csv`; referenced bytes not established here)
- Adapter Schema Closure Audit—612/612 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_ADAPTER_SCHEMA_CLOSURE_AUDIT.csv`; referenced bytes not established here)
- Helper Temporary-Relation Specification—40 relations (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv`; referenced bytes not established here)
- Internal Adapter Dependency Specification—89 dependencies (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_INTERNAL_ADAPTER_DEPENDENCY_SPECIFICATION.csv`; referenced bytes not established here)
- Internal Adapter Dependency Audit—89/89 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_INTERNAL_ADAPTER_DEPENDENCY_AUDIT.csv`; referenced bytes not established here)
- Canonical Entity Source Specification—9 families/134 entities (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_CANONICAL_ENTITY_SOURCE_SPECIFICATION.csv`; referenced bytes not established here)

## Source-edge certification

- Physical Source-Edge Observation Specification—19 edges (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_SOURCE_EDGE_PHYSICAL_OBSERVATION_SPECIFICATION.csv`; referenced bytes not established here)
- Source-Edge Certification Audit—19/19 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_SOURCE_EDGE_CERTIFICATION_AUDIT.csv`; referenced bytes not established here)
- Component-Edge Requirement Bridge—21 memberships (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_COMPONENT_EDGE_REQUIREMENT_BRIDGE.csv`; referenced bytes not established here)
- Component-Edge Requirement Audit—21/21 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_COMPONENT_EDGE_REQUIREMENT_AUDIT.csv`; referenced bytes not established here)

## Evidence and stage boundaries

- Evidence Aggregate Method Specification (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_EVIDENCE_AGGREGATE_METHOD_SPECIFICATION.csv`; referenced bytes not established here)
- Stage-Boundary Evidence Method Specification—12 nodes (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_STAGE_BOUNDARY_EVIDENCE_METHOD_SPECIFICATION.csv`; referenced bytes not established here)
- Stage-Boundary Evidence Audit—12/12 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_STAGE_BOUNDARY_EVIDENCE_AUDIT.csv`; referenced bytes not established here)

## Path and static controls

- Actual Package-Entry Path Audit—54/54 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_PACKAGE_ENTRY_PATH_AUDIT.csv`; referenced bytes not established here)
- Source-Authority Path Audit (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_SOURCE_AUTHORITY_PATH_AUDIT.csv`; referenced bytes not established here)
- R3 Static Audit Report—3,393/3,393 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WORK_PACKAGE_1_R3_STATIC_AUDIT.md`; referenced bytes not established here)
- Machine-Readable R3 Static Audit (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WORK_PACKAGE_1_R3_STATIC_AUDIT.json`; referenced bytes not established here)
- All 3,393 Static Controls (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_3/M2_12_WORK_PACKAGE_1_R3_STATIC_AUDIT_CONTROLS.csv`; referenced bytes not established here)

# Final governed state

```text
M2.12 Work Package 1 R3                 COMPLETE
Static implementation-control result    PASS
Recommended audit outcome               APPROVE WP1 R3

WP1 final approval                      HOLD — NARROW RE-REVIEW
WP2                                     NOT AUTHORIZED

Program 220                             NOT STARTED
Programs 220–227                        NOT GENERATED
Recovery SQL                            NOT GENERATED
PostgreSQL                              NOT EXECUTED
Implementation manifests               NOT CREATED
Ready-for-execution package             NOT CREATED
Module 3                                NOT AUTHORIZED
Production                              NOT AUTHORIZED
```

No Work Package 2 work was started.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a127904b-9736-4d37-91e2-9c735433bbe4"></a>
## Andrew / user · C081-M00128

C081-M00128 · 2026-08-07T21:24:21.811000-04:00 · active path

Preceding visible parent: [C081-M00127](part-09.md#m-fd44d678-89e1-4497-8a1d-17d3c55e49d1)

**Editorial record note:** Attachment references: Pasted markdown(20260808-012354).md; AUDIT_M2_12_Build_WP1_R3.zip

<!-- BEGIN_SOURCE_MESSAGE -->
M2.12 WP1 R3 audit failed and identified blockers. Correct and produce M2.12 WP1 R4 and do not wait on my approval.      
<!-- END_SOURCE_MESSAGE -->


<a id="m-8ba916ab-5592-4877-a50d-ab679070d170"></a>
## Assistant · C081-M00129

C081-M00129 · 2026-08-07T22:05:16.433217-04:00 · active path

Preceding visible parent: [C081-M00128](part-09.md#m-a127904b-9736-4d37-91e2-9c735433bbe4)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Work Package 1 R4 complete

The independent R3 audit correctly retained the WP1 hold after confirming that the R3 source-edge architecture, 21-row component-edge bridge, node-specific stage-boundary methods, prior R1/R2 controls, and clean physical paths were sound, while identifying four remaining implementation blockers. [export reference: filecite | turn24file0 | L5-L22]

I produced the bounded correction:

```text
M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R4
```

```text
Correction construction                    COMPLETE
R4 static controls                         5,911 / 5,911 PASS
Review-package controls                       34 / 34 PASS
Known static failures                         0

Accepted M2.11 baseline                    LOCKED / UNCHANGED
M2.12 frozen business design               LOCKED / UNCHANGED
Frozen business-semantic changes             0

WP1 R4 final approval                      HOLD — NARROW RE-REVIEW
WP2 authorization                          NO

Program 220                                NOT STARTED
Programs 220–227                           NOT GENERATED
Recovery SQL                               NOT GENERATED
PostgreSQL                                 NOT EXECUTED
Implementation package                    NOT CREATED
Module 3                                   NOT AUTHORIZED
Production                                 NOT AUTHORIZED
```

# Corrections completed

## 1. Helper business keys and output schemas fully close

The audit identified six helpers whose declared `module1_run_id` business key was absent from their output schema, plus eight undeclared fields referenced 110 times. [export reference: filecite | turn24file0 | L107-L178]

R4 now explicitly exposes `module1_run_id` in:

```text
tmp_hash_m2_12_base_six
tmp_hash_m2_12_pre_registry
tmp_hash_m2_12_registry
tmp_hash_m2_12_contract
tmp_hash_m2_12_combined
tmp_registry_m2_12_g3_seed
```

The reproduction base now exposes:

```text
expected_latest_rows
expected_archive_rows
expected_latest_set_hash
expected_archive_set_hash
```

The stage-boundary method authority now exposes:

```text
accepted_detail_actual_rows
report_exists_status
accepted_detail_report_sha256
```

Results:

```text
Governed helper relations                         42
Helper business-key/schema PASS              42 / 42
Missing helper business-key fields                  0

Adapter rows                                   2,571
Unique adapter output schemas                    806
Adapter schema closure PASS                  806 / 806

Actual expression references                   4,552
Undeclared expression references                   0
```

The canonical nine-family union projections are also now self-contained. Each projection uses an explicit source alias and an explicit:

```sql
CROSS JOIN tmp_src_m2_12_run_context ctx
```

rather than relying on an unbound outer `ctx` reference.

## 2. Component certification expressions corrected

The audit found thirteen component certification rows whose declared source was `cob`, but whose join predicates still referenced stale `r01`–`r13` aliases. It also found thirteen component registry-hash expressions requesting a nonexistent `observed_registry_row_hash` from accepted physical registries. [export reference: filecite | turn24file0 | L180-L247]

Every component certification now uses:

```text
cob.module1_run_id
=
ctx.module1_run_id

cob.component_sequence
=
cd.component_sequence

cob.component_contract_code
=
cd.component_contract_code

cob.contract_version
=
cd.contract_version
```

Results:

```text
Component certification joins                 13 / 13 PASS
Stale r01–r13 aliases in those joins                  0
```

The accepted physical registry identity is now obtained from:

```sql
co.row_hash::text
```

R4 applies that correction to both governed reproduction layers:

```text
Reproduction-observation base rows             13
Final reproduction-observation rows            13
                                                --
Registry row-hash expressions corrected        26 / 26 PASS
```

The remaining uses of `co.observed_registry_row_hash` are confined to governed **helper aliases** such as the component-observation relation; they are not treated as physical accepted-registry fields.

## 3. Dependency authority rebuilt from actual expression use

The R3 audit found that the 89-row dependency record reflected manually declared relationships, not all dependencies present in actual expressions, selectors, filters, joins, helper construction text, or canonical union projections. [export reference: filecite | turn24file0 | L249-L283]

R4 compiles dependency authority from:

```text
physical_expression
row_selector_or_filter
join_predicate
adapter_row_selector
physical_filter
special_handling
canonical source-to-target expressions
helper construction authorities
canonical UNION projections
```

Results:

```text
Actual expression references                  4,552 / 4,552 PASS
Derived helper dependencies                     126 / 126 PASS
Missing upstream helper relations                         0
Missing upstream output fields                            0
Expected-row discrepancies                               0
```

The seven specifically identified helpers now each carry an exact dependency on:

```text
tmp_src_m2_12_run_context
```

```text
tmp_hash_m2_12_base_six
tmp_hash_m2_12_pre_registry
tmp_hash_m2_12_registry
tmp_hash_m2_12_contract
tmp_hash_m2_12_combined
tmp_hash_m2_12_canonical_entity_source
tmp_registry_m2_12_g3_seed
```

## 4. Registry, contract, and combined hashes are now persistable without updates

The audit’s most material blocker was the circular physical persistence model: the registry’s `contract_set_hash` and `combined_set_hash` are `NOT NULL`, but were derived after the phase that purported to insert the registry; meanwhile, the construction helpers read the persistent registry before those values existed. [export reference: filecite | turn24file0 | L285-L381]

R4 freezes this exact staged construction:

```text
tmp_registry_m2_12_g3_seed
→
tmp_registry_m2_12_g3_stable_typed
→
tmp_registry_m2_12_g3_prehashed
→
tmp_hash_m2_12_registry
→
tmp_hash_m2_12_contract
→
tmp_hash_m2_12_canonical_entity_source
→
tmp_hash_m2_12_combined
→
tmp_registry_m2_12_g3_typed
→
one persistent registry INSERT
→
phase-9 persistent reconstruction
```

### Stable registry construction

`tmp_registry_m2_12_g3_stable_typed` contains the exact target-typed stable registry fields while excluding:

```text
registry_id
row_hash
registry_set_hash
contract_set_hash
combined_set_hash
```

`tmp_registry_m2_12_g3_prehashed` then adds the stable registry `row_hash` using the unchanged frozen exclusions.

### Hash construction

```text
tmp_hash_m2_12_registry
    builds registry_set_hash
    from the staged prehashed registry row

tmp_hash_m2_12_contract
    builds contract_set_hash
    from staged registry/latest/archive identities

tmp_hash_m2_12_canonical_entity_source
    builds the exact nine-family, 134-entity staged union
    using the staged registry row_hash

tmp_hash_m2_12_combined
    builds the ordered combined_set_hash
```

### Final registry projection

`tmp_registry_m2_12_g3_typed` contains exactly:

```text
65 insertable target fields
```

This is an exact match to all persistent registry target fields except:

```text
registry_id
```

The identity is deliberately omitted from the explicit insert projection and supplied once by the owned registry identity sequence.

Before the one persistent insert, the projection contains:

```text
row_hash
registry_set_hash
contract_set_hash
combined_set_hash
```

Results:

```text
Final insert-field mismatches                        0
Missing required registry hashes                     0
Pre-insert persistent registry reads                 0
Persistent canonical business/hash updates           0
Persistent registry INSERT count                     1
```

Phase 9 independently reconstructs the registry row hash, registry family hash, contract set hash, combined set hash, all nine family hashes, the 134-entity count, and the owned sequence state from persisted physical state.

## 5. Canonical combined-hash source made physically explicit

The canonical source specification now uses:

```text
POLICY                  Program 220 physical policy row
STAGE_CERTIFICATION     tmp_cert_m2_12_stage_typed
CONTRACT_COMPONENT      tmp_cert_m2_12_component_typed
EVIDENCE_CERTIFICATION  tmp_cert_m2_12_evidence_typed
CONTRACT_REPRODUCTION   tmp_cert_m2_12_reproduction_typed
CAPABILITY_COVERAGE     tmp_cert_m2_12_capability_typed
LATEST                  tmp_latest_m2_12_g3_typed
ARCHIVE                 tmp_archive_m2_12_g3_typed
REGISTRY                 tmp_registry_m2_12_g3_prehashed
```

```text
Canonical families                           9
Canonical entities                         134
Duplicate family identities                  0
Unscoped canonical UNION projections          0
```

The phase-8 REGISTRY entity therefore uses the stable staged `row_hash`. The persistent registry is used only during phase-9 reconstruction.

## 6. Program and mutation boundaries aligned

Program 222 is now governed as:

```text
Sole normal writer of 133 non-policy canonical rows

Exactly one persistent registry INSERT

Zero persistent canonical business/hash UPDATE operations

Persistent registry/latest/archive reads allowed only
for phase-9 independent reconstruction

Generation evidence and GENERATED lifecycle changes
occur only after complete physical reconstruction
```

The responsibility and transaction/mutation matrices explicitly prohibit:

```text
persistent registry construction reads before final insert
placeholder hash inserts
post-insert canonical hash repair
persistent canonical business/hash updates
```

# Preserved controls

The independent audit explicitly directed the build to preserve the prior controls that had already passed. [export reference: filecite | turn24file0 | L57-L99] R4 retains:

```text
Accepted M2.11 baseline                     PASS / LOCKED
Physical source edges                       19 / 19
Component-edge requirements                 21 / 21
Node-specific stage-boundary methods        12 / 12
Type/domain definitions                  1,172 / 1,172
Accepted physical-field references         648 / 648
Component reproduction methods              13 / 13
Physical constraints/index definitions            81
Consumption-view joins                    23 across 7 views
Owned identity sequences                    3 / 3
Hash dependency plan                        9 phases / acyclic
Canonical families                          9
Canonical entities                        134
```

No source node, component contract, source edge, evidence-certification cell, capability status, count, hash preimage, ordering key, acceptance phase, report result set, program number, recovery number, Module 3 boundary, or production boundary changed.

# Static and package validation

```text
R4 static controls                       5,911 / 5,911 PASS
Review-package controls                     34 / 34 PASS
Known failures                               0

Source files                                67
Core source-identity records                63
Current authority path mismatches            0
Attachment-suffix authority paths            0

ZIP CRC                                    PASS
Complete extraction                        PASS
Source-versus-extracted mismatches            0
Exact duplicate paths                        0
Case-insensitive duplicate paths             0
Unsafe paths                                  0
External sidecar pairing                    PASS

Accepted M2.11 baseline SHA-256             PASS
92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc
```

# Primary R4 delivery

- Download the M2.12 WP1 R4 review bundle (historical reference: `sandbox:[session]/M2_12_Build_WP1_R4.zip`; referenced bytes not established here)
- Download the matching SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_Build_WP1_R4.zip.sha256`; referenced bytes not established here)
- Read the R4 bundle-validation report (historical reference: `sandbox:[session]/M2_12_Build_WP1_R4_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the 34 package-validation controls (historical reference: `sandbox:[session]/M2_12_Build_WP1_R4_VALIDATION_CONTROLS.csv`; referenced bytes not established here)
- Download the machine-readable validation summary (historical reference: `sandbox:[session]/M2_12_Build_WP1_R4_VALIDATION_SUMMARY.json`; referenced bytes not established here)

```text
Package
M2_12_Build_WP1_R4.zip

Bytes
462,060

SHA-256
890bcf4bc2fdd4c9b57e7aeb9d89ddad129213f0825a41193c1b87af145354d6

ZIP entries
67
```

This is a static WP1 audit-review bundle, not a ready-for-execution implementation package.

# Current source authority

```text
WP1 Source Authority R4 SHA-256
42c9d8ba0368bbe985607edab51a84d3080f21e0e7a4e2e9ebed28a8f4355386

WP1 R4 Core Source Identity SHA-256
da12dd01597f480e77ddfdf558481772d231af26a1a2a67ee67fe3f5f87e6cfe
```

- WP1 Source Authority R4 (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WP1_SOURCE_AUTHORITY_R4.md`; referenced bytes not established here)
- Complete R4 core source-identity inventory (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WP1_R4_SOURCE_IDENTITY.csv`; referenced bytes not established here)
- Implementation Control Correction R4 (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WORK_PACKAGE_1_IMPLEMENTATION_CONTROL_CORRECTION_R4.md`; referenced bytes not established here)
- WP1 R4 review (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WORK_PACKAGE_1_REVIEW.md`; referenced bytes not established here)
- Four-finding remediation matrix (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WP1_R4_FINDING_REMEDIATION_MATRIX.csv`; referenced bytes not established here)

# Core revised implementation authorities

| Authority | File |
|---|---|
| Consolidated specification | M2_12_CONSOLIDATED_IMPLEMENTATION_SPECIFICATION.md (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_CONSOLIDATED_IMPLEMENTATION_SPECIFICATION.md`; referenced bytes not established here) |
| Source-to-target mapping | M2_12_SOURCE_TO_TARGET_MAPPING.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_SOURCE_TO_TARGET_MAPPING.csv`; referenced bytes not established here) |
| Canonical adapter specification | M2_12_CANONICAL_SOURCE_ADAPTER_SPECIFICATION.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_CANONICAL_SOURCE_ADAPTER_SPECIFICATION.csv`; referenced bytes not established here) |
| Helper-relation specification | M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_HELPER_TEMP_RELATION_SPECIFICATION.csv`; referenced bytes not established here) |
| Canonical entity-source specification | M2_12_CANONICAL_ENTITY_SOURCE_SPECIFICATION.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_CANONICAL_ENTITY_SOURCE_SPECIFICATION.csv`; referenced bytes not established here) |
| Hash dependency phase plan | M2_12_HASH_DEPENDENCY_PHASE_PLAN.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_HASH_DEPENDENCY_PHASE_PLAN.csv`; referenced bytes not established here) |
| Hash dependency DAG | M2_12_HASH_DEPENDENCY_DAG.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_HASH_DEPENDENCY_DAG.csv`; referenced bytes not established here) |
| Ordered hash specification | M2_12_ORDERED_HASH_SPECIFICATION.md (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_ORDERED_HASH_SPECIFICATION.md`; referenced bytes not established here) |
| Program responsibility matrix | M2_12_PROGRAM_RESPONSIBILITY_MATRIX.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_PROGRAM_RESPONSIBILITY_MATRIX.csv`; referenced bytes not established here) |
| Transaction/mutation matrix | M2_12_TRANSACTION_AND_MUTATION_MATRIX.csv (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_TRANSACTION_AND_MUTATION_MATRIX.csv`; referenced bytes not established here) |
| Implementation invariants—283 | M2_12_IMPLEMENTATION_INVARIANTS.md (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_IMPLEMENTATION_INVARIANTS.md`; referenced bytes not established here) |

# New R4 audit authorities

- Helper Business-Key/Schema Audit — 42/42 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_HELPER_BUSINESS_KEY_SCHEMA_AUDIT.csv`; referenced bytes not established here)
- Actual Expression Reference Inventory — 4,552/4,552 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_ACTUAL_EXPRESSION_REFERENCE_INVENTORY.csv`; referenced bytes not established here)
- Derived Dependency Specification — 126 dependencies (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_INTERNAL_ADAPTER_DEPENDENCY_SPECIFICATION.csv`; referenced bytes not established here)
- Derived Dependency Audit — 126/126 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_INTERNAL_ADAPTER_DEPENDENCY_AUDIT.csv`; referenced bytes not established here)
- Component Certification Join Audit — 13/13 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_COMPONENT_CERTIFICATION_JOIN_AUDIT.csv`; referenced bytes not established here)
- Accepted Registry Row-Hash Audit — 26/26 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_SOURCE_REGISTRY_ROW_HASH_AUDIT.csv`; referenced bytes not established here)
- Registry Hash-Staging Specification (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_REGISTRY_HASH_STAGING_SPECIFICATION.csv`; referenced bytes not established here)
- Registry Hash-Staging Audit — 8/8 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_REGISTRY_HASH_STAGING_AUDIT.csv`; referenced bytes not established here)
- R4 Static Audit Report — 5,911/5,911 PASS (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WORK_PACKAGE_1_R4_STATIC_AUDIT.md`; referenced bytes not established here)
- Machine-Readable R4 Static Audit (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WORK_PACKAGE_1_R4_STATIC_AUDIT.json`; referenced bytes not established here)
- All 5,911 Static Controls (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_WORK_PACKAGE_1_R4_STATIC_AUDIT_CONTROLS.csv`; referenced bytes not established here)
- Package-Entry Path Audit (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_PACKAGE_ENTRY_PATH_AUDIT.csv`; referenced bytes not established here)
- Current Source-Authority Path Audit (historical reference: `sandbox:[session]/M2_12_WORK_PACKAGE_1_REVISION_4/M2_12_SOURCE_AUTHORITY_PATH_AUDIT.csv`; referenced bytes not established here)

# Final governed state

```text
M2.12 Work Package 1 R4                 COMPLETE
Static implementation-control result    PASS
Recommended audit outcome               APPROVE WP1 R4

WP1 final approval                      HOLD — NARROW RE-REVIEW
WP2                                     NOT AUTHORIZED

Program 220                             NOT STARTED
Programs 220–227                        NOT GENERATED
Recovery SQL                            NOT GENERATED
PostgreSQL                              NOT EXECUTED
Implementation manifests               NOT CREATED
Ready-for-execution package             NOT CREATED
Module 3                                NOT AUTHORIZED
Production                              NOT AUTHORIZED
```

The audit required R4 to stop after correcting the implementation-control authorities and retain every no-SQL, no-execution, and no-WP2 boundary. [export reference: filecite | turn24file0 | L417-L500] No Work Package 2 work was started.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6c333886-fc63-4223-ad2e-b5c4f34b2510"></a>
## Andrew / user · C081-M00130

C081-M00130 · 2026-08-07T23:18:13.658000-04:00 · active path

Preceding visible parent: [C081-M00129](part-09.md#m-8ba916ab-5592-4877-a50d-ab679070d170)

**Editorial record note:** Attachment references: Pasted markdown(20260808-031001).md; AUDIT_M2_12_Build_WP1_R4.zip

<!-- BEGIN_SOURCE_MESSAGE -->
M2.12 WP1 R4 audit failed and identified blockers. Correct and produce M2.12 WP1 R5 and do not wait on my approval. R5 must be treated as a full WP1 implementation-closure pass, not only a remediation of the three R4 findings. After applying the corrections, prospectively simulate literal construction of Programs 220, 221, 222, 220A, 222A, and 222B using only the current WP1 authorities. Identify every point where SQL generation would require an unstated relation, alias, field, type, cast, constraint, identity clause, sequence action, join, hash preimage, construction stage, INSERT projection, mutation, transaction behavior, or recovery decision. Required implementation-time inferred decisions: 0. Expand the R5 static audit to cover this full closure before returning for re-review. Do not generate SQL.
<!-- END_SOURCE_MESSAGE -->
