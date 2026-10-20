# WP3 Build Protocol

Part 01 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Next part](part-02.md)

<a id="m-3b040465-465d-4e3f-9dce-5ff4b63c5a99"></a>
## Andrew / user · C085-M00001

C085-M00001 · 2026-08-10T08:53:24.713000-04:00 · active path

**Editorial record note:** Attachment references: M2_12_Build_WP2_R4(4).zip; AUDIT_M2_12_Build_WP2_R4(1).zip; M2_12_WP2_R4_FINAL_SIGNOFF_AND_WP3_REAUTHORIZATION_20260809(2).md; M2_12_WP3_R4_REAUTHORIZED_RESUME_PROMPT_20260809(2).md; M2_12_Build_WP1_R10(5).zip; AUDIT_M2_12_Build_WP1_R10(2).zip; M2_11_FULL_PROJECT_ACCEPTED_20260806(8).zip

<!-- BEGIN_SOURCE_MESSAGE -->
Use this as the **opening prompt in the new chat**, before the substantive WP3 authorization prompt:

```text
# M2.12 WP3 — Clean Rebuild and Physical Delivery Protocol

We are rebuilding M2.12 Work Package 3 from the approved WP2 Source R4 authority.

This chat must not reuse or promote any prior WP3 build output. Prior WP3 files are historical/diagnostic only.

The goal is not merely to reason through WP3 or create plausible filenames. The goal is to physically construct, validate, package, and successfully deliver one complete WP3 source-review package.

## Governing inputs

Use only the attached approved authorities:

- approved M2_12_Build_WP2_R4.zip and sidecar;
- final WP2 R4 independent audit/signoff;
- WP3 R4-reauthorized source-construction prompt;
- WP1 R10 build/audit package as supporting implementation authority;
- accepted M2.11 full-project baseline.

Do not reconstruct authority from memory if any governing input cannot be physically verified.

## Build only WP3

Construct only:

223 — Positive Validation, exactly 128 controls
224 — Negative Controls, exactly 20 isolated controls
223A — Failed Positive-Validation Recovery

Do not execute PostgreSQL.
Do not generate Programs 225–227.
Do not create an execution package.
Do not claim validation or acceptance.

## Mandatory clean-build process

1. Create one brand-new WP3 build workspace.
2. Create a separate brand-new extraction/validation workspace.
3. Do not use an existing WP3 output directory.
4. Do not copy prior WP3 output into the new build.
5. Verify the approved WP2 R4 ZIP, sidecar, CRC, manifest, package inventory, source identities, and all six SQL hashes before construction.

## Required physical artifact sequence

Build in this exact order:

1. Program 223 SQL
2. Program 224 SQL
3. Recovery 223A SQL
4. positive-control catalog
5. negative-control catalog
6. control-traceability matrix
7. control-family allocation and other WP3 audits
8. parser/lexical/static audits
9. mutation/isolation/recovery audits
10. SQL SHA-256 inventory
11. WP3 source identity
12. WP3 source authority
13. WP3 review
14. MANIFEST.csv
15. manifest.json
16. SHA256SUMS.txt
17. PACKAGE_INVENTORY.csv
18. package identity/validation report
19. final canonical ZIP
20. external ZIP .sha256 sidecar

Do not build manifests or package metadata before the substantive source tree physically exists.

## Hard checkpoints

Immediately after each SQL file is written:

Program 223:
- physical file exists;
- substantive nonzero size;
- reopen/readback succeeds;
- correct program identity;
- exactly 128 positive-control definitions;
- SHA-256 calculated from physical bytes.

Program 224:
- physical file exists;
- substantive nonzero size;
- reopen/readback succeeds;
- correct program identity;
- exactly 20 negative-control definitions;
- SHA-256 calculated from physical bytes.

Recovery 223A:
- physical file exists;
- substantive nonzero size;
- reopen/readback succeeds;
- recovery-only mutation boundary confirmed;
- SHA-256 calculated from physical bytes.

If any checkpoint fails: STOP FAIL-CLOSED.

## Catalog checks

Before packaging, physically reopen the CSVs and require:

positive-control catalog        128 data rows
negative-control catalog         20 data rows
traceability matrix             complete coverage of all 148 controls

Require:

missing control codes      0
duplicate control codes    0
unexpected control codes   0

Compare these catalogs to the actual Program 223/224 SQL files, not to planned or prior content.

## No self-certification

Do not accept a generated report saying PASS as proof.

Every reported control must be independently recalculated from the underlying physical files.

Reports summarize validation.
Reports do not constitute validation.

## One canonical package only

Create exactly one canonical review ZIP:

M2_12_Build_WP3_R1.zip

and one matching sidecar:

M2_12_Build_WP3_R1.zip.sha256

Do not create an additional delivery-wrapper ZIP unless explicitly requested later.

Everything required for independent WP3 review must be inside the canonical ZIP.

## Final ZIP release gate

After creating the ZIP:

1. reopen it independently;
2. CRC-test it;
3. extract it completely to the separate validation workspace;
4. compare source tree versus extracted tree by:
   - path;
   - byte size;
   - SHA-256;
5. verify required SQL/catalog/audit/governance files are physically inside;
6. verify manifests against actual extracted bytes.

Required:

ZIP CRC                                      PASS
complete extraction                          PASS
Program 223 inside ZIP                       PASS
Program 224 inside ZIP                       PASS
Recovery 223A inside ZIP                     PASS
positive catalog inside ZIP                  PASS
negative catalog inside ZIP                  PASS
traceability inside ZIP                      PASS
path mismatches                              0
size mismatches                              0
SHA-256 mismatches                           0
duplicate paths                              0
case-insensitive duplicate paths             0
unsafe paths                                 0

A very small or incomplete ZIP is a RELEASE BLOCKER.

## Sidecar release gate

Only after the final ZIP passes validation:

- calculate SHA-256 from the final ZIP bytes;
- create the .sha256 sidecar;
- reopen the sidecar;
- require exact filename and hash pairing.

Do not provide a download link unless the exact file physically exists and has passed readback.

## Final response requirements

Before claiming completion, provide a physical delivery ledger from the actual files:

Final ZIP:
- filename
- bytes
- SHA-256
- ZIP entry count
- total uncompressed bytes
- CRC result

Program 223:
- bytes
- SHA-256

Program 224:
- bytes
- SHA-256

Recovery 223A:
- bytes
- SHA-256

Positive catalog:
- 128 rows
- bytes
- SHA-256

Negative catalog:
- 20 rows
- bytes
- SHA-256

Traceability:
- 148 rows
- bytes
- SHA-256

Sidecar:
- physical existence PASS
- hash pairing PASS

Only provide links to files that physically exist and have passed these checks.

## Final governing rule

PHYSICAL ARTIFACT STATE OVERRIDES NARRATIVE STATE.

If reasoning says WP3 is complete but the filesystem does not prove it, WP3 is NOT complete.

If validation metadata says PASS but independent readback does not prove it, validation has NOT passed.

If a download path is expected but the file does not physically exist, do not provide the link.

STOP FAIL-CLOSED on any artifact-generation or delivery anomaly.

After this protocol is understood, follow the attached WP3 R4-reauthorized source-construction prompt exactly.
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-ba44e9de-b664-4afa-8a61-45af0a180e9f"></a>
## Assistant · C085-M00002

C085-M00002 · 2026-08-10T08:53:40.309654-04:00 · active path

Preceding visible parent: [C085-M00001](part-01.md#m-3b040465-465d-4e3f-9dce-5ff4b63c5a99)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll physically verify the governing WP2 R4 authority before cleanly constructing and independently validating WP3, stopping fail-closed if any required authority or file identity cannot be reconciled.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2dd86122-5542-496a-89fe-ab829ecf4ad2"></a>
## Assistant · C085-M00003

C085-M00003 · 2026-08-10T08:56:46.847879-04:00 · active path

Preceding visible parent: [C085-M00002](part-01.md#m-ba44e9de-b664-4afa-8a61-45af0a180e9f)

<!-- BEGIN_SOURCE_MESSAGE -->
The uploaded WP2 artifact is a delivery wrapper; its embedded canonical ZIP matches the approved SHA-256, its sidecar agrees, and CRC testing passes.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d475e345-61f4-4bf4-baed-0b5baabd1ac0"></a>
## Assistant · C085-M00004

C085-M00004 · 2026-08-10T09:05:52.132783-04:00 · active path

Preceding visible parent: [C085-M00003](part-01.md#m-2dd86122-5542-496a-89fe-ab829ecf4ad2)

<!-- BEGIN_SOURCE_MESSAGE -->
All six WP2 SQL identities and the M2.11 baseline are verified. Construction will use the frozen control allocations and R4-corrected negative catalog, including Control 018’s reachable rejection fixture.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fa89a0dd-829a-4565-8bba-dcabc90e7237"></a>
## Assistant · C085-M00005

C085-M00005 · 2026-08-10T09:32:55.543244-04:00 · active path

Preceding visible parent: [C085-M00004](part-01.md#m-d475e345-61f4-4bf4-baed-0b5baabd1ac0)

<!-- BEGIN_SOURCE_MESSAGE -->
Program 223 is physically written with 128 controls; Programs 224 and 223A are also read back, with 20 isolated negatives and recovery-only mutations.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5d68f4f2-3aeb-4bce-91bc-a0ad18d4c7e8"></a>
## Assistant · C085-M00006

C085-M00006 · 2026-08-10T10:14:59.242620-04:00 · active path

Preceding visible parent: [C085-M00005](part-01.md#m-fa89a0dd-829a-4565-8bba-dcabc90e7237)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 WP3 R1 — Physical Source-Review Delivery Complete

The final package was constructed from a **brand-new WP3 workspace**, independently extracted into a separate validation workspace, and released only after the physical ZIP and sidecar passed all required gates.

The governing signoff approved WP2 Source R4 and authorized source generation only for Programs 223, 224, and Recovery 223A. PostgreSQL execution, Programs 225–227, execution packaging, and any M2.12 validation or acceptance claim remain unauthorized. [export reference: filecite | turn0file0 | L5-L17] The governing WP3 prompt requires exactly 128 positive controls, exactly 20 isolated negative controls, and the bounded 223A recovery source. [export reference: filecite | turn0file1 | L29-L36]

## Downloads

- Download the canonical M2_12_Build_WP3_R1.zip (historical reference: `sandbox:[session]/M2_12_Build_WP3_R1.zip`; referenced bytes not established here)
- Download the matching M2_12_Build_WP3_R1.zip.sha256 sidecar (historical reference: `sandbox:[session]/M2_12_Build_WP3_R1.zip.sha256`; referenced bytes not established here)

No delivery-wrapper ZIP was created.

## Physical delivery ledger

### Final canonical ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_Build_WP3_R1.zip` |
| Bytes | **57,205,778** |
| SHA-256 | `5aa031b5e1dba1a92538eccb25a047e3db682357122c2f882a7736fd4b14cf26` |
| ZIP entries | **46** |
| Total uncompressed bytes | **59,952,850** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |

### Program 223 — Positive Validation

| Attribute | Physical result |
|---|---:|
| Bytes | **713,276** |
| SHA-256 | `ccb301785dc8a2a80126bc2d70c7d8dfd0db91b2d51b008fb733745ae26d7158` |
| Positive-control definitions | **128** |
| Physical readback | **PASS** |
| Program identity | **PASS** |

Program 223 reconstructs the frozen positive controls from persisted state, avoids Program 222 transaction-local helpers, and positions positive-evidence persistence and lifecycle transition after the 128-of-128 gate, consistent with the reauthorized source requirements. [export reference: filecite | turn0file1 | L39-L46]

### Program 224 — Negative Controls

| Attribute | Physical result |
|---|---:|
| Bytes | **136,668** |
| SHA-256 | `c010ed61c7f93da457235e01902f280596f706f42f232464fac546fd13dbda36` |
| Negative-control definitions | **20** |
| Exception-isolated subtransactions | **20** |
| Physical readback | **PASS** |
| Program identity | **PASS** |

All 20 controls contain independently bounded exception subtransactions and before/after canonical, stored-hash, sequence, and lifecycle fingerprint comparisons. Control 018 uses capability sequence 17, the injected `IMPLEMENTED_PRODUCTION_AUTHORIZED` status, SQLSTATE `23514`, and constraint `ck_m212_capability_status`, as required by the R4 authority. [export reference: filecite | turn0file1 | L48-L59]

### Recovery 223A

| Attribute | Physical result |
|---|---:|
| Bytes | **60,158** |
| SHA-256 | `0e65e3534440414f598a360e7fb67f1b299a4c4bc9883c80c686510af4ff6969` |
| Recovery-only mutation boundary | **PASS** |
| Physical readback | **PASS** |
| Program identity | **PASS** |

The only authorized persistent recovery mutations are:

1. Delete partial `M2_12_POS_%` evidence.
2. Restore the G3 registry’s mutable validation lifecycle to `GENERATED`.
3. Restore the governed run status to `M2_12_GENERATED`.

The source refuses complete validation, negative-control state, acceptance state, G3 gate state, and canonical/hash ambiguity, matching the bounded recovery authority. [export reference: filecite | turn0file1 | L61-L67]

## Catalog ledger

| Artifact | Rows | Bytes | SHA-256 |
|---|---:|---:|---|
| Positive-control catalog | **128** | **119,662** | `1990364fa36f68875320663ad48c7a5c106c7bc32faebaa7911eb582796fad38` |
| Negative-control catalog | **20** | **27,099** | `0af595fc079d9d6ae2a2cbbaad54a20d9376878baecec6993c6f88898b4a7baa` |
| Control-traceability matrix | **148** | **114,610** | `425f4a87ec570090dea8230bb4c6f196a48eec6837af2c731557d6f1044530f0` |

Catalog-to-SQL reconciliation:

| Control | Result |
|---|---:|
| Missing control codes | **0** |
| Duplicate control codes | **0** |
| Unexpected control codes | **0** |
| Catalog definition-hash mismatches | **0** |
| Traceability definition-hash mismatches | **0** |
| Positive-family allocation total | **128** |
| Negative-control total | **20** |

Each cataloged physical-definition byte count and SHA-256 was recalculated directly from the corresponding marker-delimited SQL block.

## Independent release gate

The final ZIP was subjected to a separate **103-check physical and static release audit**, independent of the package’s generated PASS reports.

| Release control | Result |
|---|---:|
| Independent checks passed | **103/103** |
| Source-tree versus extracted-tree path mismatches | **0** |
| Size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate ZIP paths | **0** |
| Case-insensitive duplicate ZIP paths | **0** |
| Unsafe ZIP paths | **0** |
| Manifest mismatches | **0** |
| `manifest.json` mismatches | **0** |
| `SHA256SUMS.txt` mismatches | **0** |
| Package-inventory mismatches | **0** |
| Required SQL/catalog/audit/governance files missing | **0** |
| Unauthorized SQL files | **0** |

The embedded governing inputs were also reopened and independently verified. The approved inner WP2 R4 ZIP reproduced SHA-256 `aa234e534c8dbed7cdd7ba5ed6041e498df4c9046cbac4663477a08647e73592`; its sidecar and CRC passed, its 86-row manifest and 89-row package inventory reproduced with zero mismatches, and all six approved WP2 SQL identities matched. Those are the baseline checks required before WP3 construction. [export reference: filecite | turn0file1 | L15-L27]

## Sidecar release gate

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_Build_WP3_R1.zip.sha256` |
| Bytes | **89** |
| Sidecar SHA-256 | `6cc9761dc54a413adfdae9df19bf5f8b41bde5825f72f68eda30fe54a3c3b7e7` |
| Physical existence | **PASS** |
| Readback | **PASS** |
| Exact filename/hash pairing | **PASS** |

The sidecar contains:

```text
5aa031b5e1dba1a92538eccb25a047e3db682357122c2f882a7736fd4b14cf26  M2_12_Build_WP3_R1.zip
```

## Scope determination

This delivery establishes only that the WP3 source-review package was physically constructed and passed file-level, catalog, traceability, lexical, static, mutation-boundary, isolation, recovery, packaging, extraction, and hash-verification gates.

- PostgreSQL execution: **NOT PERFORMED**
- Programs 225–227: **NOT GENERATED**
- Execution package: **NOT CREATED**
- M2.12 runtime validation: **NOT CLAIMED**
- M2.12 acceptance: **NOT CLAIMED**

The required stopping point remains independent WP3 source review. [export reference: filecite | turn0file1 | L69-L78]
<!-- END_SOURCE_MESSAGE -->


<a id="m-9c73790f-0892-4607-aeb8-c27a3ef702bd"></a>
## Andrew / user · C085-M00007

C085-M00007 · 2026-08-10T13:21:09.022000-04:00 · active path

Preceding visible parent: [C085-M00006](part-01.md#m-5d68f4f2-3aeb-4bce-91bc-a0ad18d4c7e8)

**Editorial record note:** Attachment references: M2_12_WP3_R1_RECONCILED_FINAL_INDEPENDENT_AUDIT_PACKAGE_20260810(1).zip; M2_12_WP3_R1_RECONCILED_FINAL_INDEPENDENT_AUDIT_PACKAGE_20260810.zip(1).sha256; M2_12_WP3_R1_RECONCILED_FINAL_SIGNOFF_AND_WP4_AUTHORIZATION_20260810(1).md; M2_12_WP4_AUTHORIZED_BUILD_PROMPT_20260810(1).md

<!-- BEGIN_SOURCE_MESSAGE -->
M2.12 WP3 R1 is approved. M2.12 WP4 build is authorized.
<!-- END_SOURCE_MESSAGE -->


<a id="m-006aa833-a979-43c3-a57b-4b824730ec9a"></a>
## Assistant · C085-M00008

C085-M00008 · 2026-08-10T13:21:24.964291-04:00 · active path

Preceding visible parent: [C085-M00007](part-01.md#m-9c73790f-0892-4607-aeb8-c27a3ef702bd)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m proceeding with WP4 Programs 225–227, first verifying governing WP2/WP3 packages and nine upstream SQL identities, then independently auditing and packaging one canonical review ZIP and sidecar.
<!-- END_SOURCE_MESSAGE -->


<a id="m-36251fe5-cf40-4b63-be48-bedc78762072"></a>
## Assistant · C085-M00009

C085-M00009 · 2026-08-10T13:24:29.825333-04:00 · active path

Preceding visible parent: [C085-M00008](part-01.md#m-006aa833-a979-43c3-a57b-4b824730ec9a)

<!-- BEGIN_SOURCE_MESSAGE -->
All nine upstream SQL identities now reproduce exactly. I’ve also located the frozen 48-row acceptance matrix and 24-result-set catalog and am resolving them against the physical schema.
<!-- END_SOURCE_MESSAGE -->


<a id="m-417f3e84-8d19-4f51-afc1-7bf6d59f1b39"></a>
## Assistant · C085-M00010

C085-M00010 · 2026-08-10T13:33:34.555054-04:00 · active path

Preceding visible parent: [C085-M00009](part-01.md#m-36251fe5-cf40-4b63-be48-bedc78762072)

<!-- BEGIN_SOURCE_MESSAGE -->
The remaining WP4 structure is now fixed: eight atomic write phases, exact evidence identities, and read/write boundaries. I’m constructing SQL with persistent mutations confined to Program 225.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9d05df00-3f11-45bb-807b-41b586c4517a"></a>
## Assistant · C085-M00011

C085-M00011 · 2026-08-10T14:00:39.119009-04:00 · active path

Preceding visible parent: [C085-M00010](part-01.md#m-417f3e84-8d19-4f51-afc1-7bf6d59f1b39)

<!-- BEGIN_SOURCE_MESSAGE -->
All three WP4 SQL sources now physically exist with required block counts. I corrected a master-report schema reference; lexical checks pass, and column-level authority reconciliation continues.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0518afea-ba66-41ff-894d-e22e604d0c9a"></a>
## Assistant · C085-M00012

C085-M00012 · 2026-08-10T14:50:32.652372-04:00 · active path

Preceding visible parent: [C085-M00011](part-01.md#m-9d05df00-3f11-45bb-807b-41b586c4517a)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 WP4 R1 — Physical Source-Review Delivery Complete

M2.12 WP4 R1 has been physically constructed, sealed, independently re-extracted, and reconciled. The governing signoff approved WP3 Source R1 and authorized source generation only for Programs 225, 226, and 227; PostgreSQL execution, execution packaging, runtime validation, M2.12 acceptance, Module 3, and production remain unauthorized. [export reference: filecite | turn0file0 | L5-L19]

The package preserves all six WP2 R4 and all three WP3 R1 SQL sources byte-identically, as required by the WP4 construction authority. [export reference: filecite | turn0file1 | L8-L27]

## Downloads

- Download the canonical M2_12_Build_WP4_R1.zip (historical reference: `sandbox:[session]/M2_12_Build_WP4_R1.zip`; referenced bytes not established here)
- Download the matching M2_12_Build_WP4_R1.zip.sha256 sidecar (historical reference: `sandbox:[session]/M2_12_Build_WP4_R1.zip.sha256`; referenced bytes not established here)

No delivery-wrapper ZIP was created.

## Final physical delivery ledger

### Canonical WP4 ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_Build_WP4_R1.zip` |
| Bytes | **91,288,357** |
| SHA-256 | `aa1506e932f63c350ba38b2db025f57077a6ffaa15b2437c896680aa6b4c38b6` |
| ZIP entries | **77** |
| Total uncompressed bytes | **94,454,744** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |
| Separately coded release validation | **159/159 PASS** |

### ZIP-to-extraction reconciliation

| Release control | Result |
|---|---:|
| Path mismatches | **0** |
| Byte-size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Symbolic links | **0** |
| Missing required files | **0** |
| Unauthorized Programs 228+ | **0** |
| Execution or WP5 package artifacts | **0** |

## Authorized WP4 SQL sources

The WP4 authority requires Program 225 to enforce all 48 acceptance requirements and make only the bounded acceptance writes; Program 226 must produce a persistent-state-read-only one-row master report; and Program 227 must produce exactly 24 persistent-state-read-only governed result sets. [export reference: filecite | turn0file1 | L30-L79]

### Program 225 — Acceptance Finalizer

| Attribute | Physical result |
|---|---:|
| Filename | `225_msbf_m2_12_acceptance_finalizer_v1.sql` |
| Bytes | **196,837** |
| SHA-256 | `3769fe5c43d8d8aafe18e3e3d4538bd696dc370fd4ca080fa3fa5cfbad625119` |
| Acceptance-requirement definitions | **48** |
| Pre-write requirements | **47** |
| Post-write atomicity requirement | **1** |
| Frozen execution phases | **8** |
| Physical readback | **PASS** |
| Requirement-block byte/hash reconciliation | **48/48 PASS** |

The physical phase order is:

1. Requirements 001–047 and the hard 47-of-47 gate.
2. Formal immutable pre-write fingerprint capture.
3. One G3 acceptance-gate insert.
4. One acceptance-evidence insert.
5. Registry and run lifecycle transitions.
6. Exact `1|1|1|1` post-write atomicity check.
7. Complete post-write immutable fingerprint reconstruction.
8. Requirement 048, final 48-of-48 gate, and one commit.

The source contains exactly four authorized persistent DML operations:

| Operation | Target | Occurrences |
|---|---|---:|
| Insert | `msbf_ctl.acceptance_gate_result` | **1** |
| Insert | `msbf_ctl.run_evidence` | **1** |
| Update | `msbf_ctl.m2_12_g3_bundle_registry` | **1** |
| Update | `msbf_ctl.run_registry` | **1** |

No other persistent mutation was identified.

### Program 226 — Master Report

| Attribute | Physical result |
|---|---:|
| Filename | `226_msbf_m2_12_master_report_v1.sql` |
| Bytes | **116,188** |
| SHA-256 | `e43bab189d439f0e09ad879ea253f6162560e5b157b71f030eaa3ff16b9e3f56` |
| Governed master-report rows | **1** |
| Master-report traceability requirements | **14/14 PASS** |
| Persistent DML operations | **0** |
| Persistent object creation | **0** |
| Read-only before/after fingerprint guard | **PASS** |
| Physical readback | **PASS** |

The master report physically reconciles:

- accepted lifecycle, G3 gate, and acceptance evidence;
- the `12 / 13 / 72 / 13 / 20 / 134` certification architecture;
- `1,500 / 59 / 24` governed consumption counts;
- `7,129 / 7,129` component latest/archive totals;
- positive, negative, generation, and acceptance evidence;
- source-edge, reconstruction, deterministic-hash, boundary, and capability findings;
- M2.11 frontier and governance-review posture;
- synthetic-data, no-PII, non-production, no-deployment, no-legal-certification, and no-Module-3 boundaries.

### Program 227 — Twenty-Four Detailed Result Sets

| Attribute | Physical result |
|---|---:|
| Filename | `227_msbf_m2_12_detailed_report_24_result_sets_v1.sql` |
| Bytes | **131,787** |
| SHA-256 | `17a27cb49fe0611953d5bc499c15513d46d8768fe441ed1fd0bfb126f3300b50` |
| Governed result-set definitions | **24** |
| Projection reconciliation | **24/24 PASS** |
| Ordering reconciliation | **24/24 PASS** |
| Cardinality reconciliation | **24/24 PASS** |
| Persistent DML operations | **0** |
| Persistent object creation | **0** |
| Read-only before/after fingerprint guard | **PASS** |
| Physical readback | **PASS** |

The physically enforced successful cardinality vector is:

```text
1, 1, 1, 12, 13, 19, 72, 13, 13, 3, 1500, 3,
59, 24, 24, 3, 8, 20, 1, 1, 12, 6, 0, 0
```

Result Sets 23 and 24 preserve explicit, stable headers while requiring zero successful-state rows.

## Catalog and traceability ledger

| Artifact | Data rows | Bytes | SHA-256 |
|---|---:|---:|---|
| Acceptance-requirement traceability | **48** | **16,895** | `22af59fd2e3f20918cba0bb9cb564f378f45a9eda8afa192d03857d415e1a72a` |
| Acceptance phase-order authority | **8** | **3,608** | `99e159105c7aed5ae2665cec1e6ca938227bf21735a04a80751c18b634dbdca1` |
| Master-report traceability | **14** | **4,465** | `ff1576391ba57ef2cf848fc9073061c3569e1453f834739eb9acf5cf3d6b2f00` |
| Detailed-result-set traceability | **24** | **20,017** | `d3df95b81d762bcd0d4f15cbbded3850b609905156a8ac604074b2c61fa686ee` |
| Mutation authority | **6** | **655** | `c2cf3841786e73389ac1c7d77607a6334aacad76b07e1f095faa46cef9016737` |

Physical catalog-to-source reconciliation produced:

| Control | Result |
|---|---:|
| Missing acceptance codes | **0** |
| Duplicate acceptance codes | **0** |
| Unexpected acceptance codes | **0** |
| Acceptance block hash mismatches | **0** |
| Missing result-set sequences | **0** |
| Duplicate result-set sequences | **0** |
| Projection mismatches | **0** |
| Ordering mismatches | **0** |
| Cardinality mismatches | **0** |
| Mutation-authority mismatches | **0** |

## Upstream byte preservation

All nine upstream SQL sources reproduce their approved identities exactly:

| Program | SHA-256 reconciliation |
|---|---:|
| 220 R4 | **PASS** |
| 221 | **PASS** |
| 222 R3 | **PASS** |
| 220A | **PASS** |
| 222A | **PASS** |
| 222B | **PASS** |
| 223 | **PASS** |
| 224 | **PASS** |
| 223A | **PASS** |

The embedded governing packages also passed independent sidecar and CRC verification:

| Governing package | SHA-256 | Result |
|---|---|---:|
| `M2_12_Build_WP2_R4.zip` | `aa234e534c8dbed7cdd7ba5ed6041e498df4c9046cbac4663477a08647e73592` | **PASS** |
| `M2_12_Build_WP3_R1.zip` | `5aa031b5e1dba1a92538eccb25a047e3db682357122c2f882a7736fd4b14cf26` | **PASS** |

## Package metadata reconciliation

| Metadata artifact | Rows | Mismatches |
|---|---:|---:|
| `MANIFEST.csv` | **72** | **0** |
| `manifest.json` | **72** | **0** |
| `SHA256SUMS.txt` | **74** | **0** |
| `PACKAGE_INVENTORY.csv` | **76** | **0** |

All metadata results were recalculated from the extracted physical bytes rather than accepted from embedded PASS statements.

## Sidecar release gate

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_Build_WP4_R1.zip.sha256` |
| Bytes | **89** |
| Sidecar SHA-256 | `6b786ec41352923a616693b9724a4f74c588176bba9f3ce62e0379854506406e` |
| Physical existence | **PASS** |
| ASCII readback | **PASS** |
| Exact ZIP filename pairing | **PASS** |
| Exact ZIP hash pairing | **PASS** |

The sidecar contains:

```text
aa1506e932f63c350ba38b2db025f57077a6ffaa15b2437c896680aa6b4c38b6  M2_12_Build_WP4_R1.zip
```

## Scope determination

The required WP4 delivery consists of the three SQL sources, acceptance and reporting traceability, source-level audits, upstream preservation evidence, SQL identities, source authority, and the review bundle. The governing prompt requires stopping after source construction and independent-review packaging. [export reference: filecite | turn0file1 | L81-L106]

Accordingly:

| Boundary | Status |
|---|---:|
| PostgreSQL execution | **NOT PERFORMED** |
| Execution package | **NOT CREATED** |
| WP5 package | **NOT CREATED** |
| M2.12 runtime validation | **NOT CLAIMED** |
| M2.12 acceptance | **NOT CLAIMED** |
| Module 3 authorization | **NOT CLAIMED** |
| Production authority | **NOT CLAIMED** |

The physical stopping point is **independent WP4 source review**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0c3b3d08-c34f-4bbc-abc9-b89dbf6e95df"></a>
## Andrew / user · C085-M00013

C085-M00013 · 2026-08-10T16:13:42.532000-04:00 · active path

Preceding visible parent: [C085-M00012](part-01.md#m-0518afea-ba66-41ff-894d-e22e604d0c9a)

**Editorial record note:** Attachment references: AUDIT_M2_12_Build_WP4.zip; M2_12_WP4_R1_FINAL_SIGNOFF_AND_WP5_AUTHORIZATION_20260810(1).md; M2_12_WP5_AUTHORIZED_BUILD_PROMPT_20260810(1).md

<!-- BEGIN_SOURCE_MESSAGE -->
M2.12 WP4 is approved. M2.12 WP5 is authorized. Please proceed to build M2.12 WP5.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dae522fa-be4a-47c4-91c0-1d4e595175f8"></a>
## Assistant · C085-M00014

C085-M00014 · 2026-08-10T16:13:57.954267-04:00 · active path

Preceding visible parent: [C085-M00013](part-01.md#m-0c3b3d08-c34f-4bbc-abc9-b89dbf6e95df)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m treating approved WP4 as the sole executable-source baseline; I’ll verify its identity and twelve SQL byte streams, construct authorized WP5 deliverables, then independently extract and byte-audit them.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a87d11e0-7c91-4fb4-ad23-a4fdf6f645e0"></a>
## Assistant · C085-M00015

C085-M00015 · 2026-08-10T16:17:02.301565-04:00 · active path

Preceding visible parent: [C085-M00014](part-01.md#m-dae522fa-be4a-47c4-91c0-1d4e595175f8)

<!-- BEGIN_SOURCE_MESSAGE -->
The WP4 ZIP hash, sidecar, CRC, and 77-entry inventory reconcile. I’m now checking manifests and audit signoff in isolated workspaces before writing WP5 metadata.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7c1bae46-2e91-465b-bfb6-24f4a2236988"></a>
## Assistant · C085-M00016

C085-M00016 · 2026-08-10T16:26:07.798115-04:00 · active path

Preceding visible parent: [C085-M00015](part-01.md#m-a87d11e0-7c91-4fb4-ad23-a4fdf6f645e0)

<!-- BEGIN_SOURCE_MESSAGE -->
The substantive WP5 tree is complete with eight normal programs, four isolated recoveries, seven operator/governance guides, and 44 future evidence requirements. I’m now independently recomputing metadata and validating packaging.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e4a43ab9-fab9-4386-9762-7421111e711b"></a>
## Assistant · C085-M00017

C085-M00017 · 2026-08-10T16:38:32.812835-04:00 · active path

Preceding visible parent: [C085-M00016](part-01.md#m-7c1bae46-2e91-465b-bfb6-24f4a2236988)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 WP5 R1 — Standalone Package Complete

M2.12 WP5 has been physically constructed and packaged from the approved WP4 R1 source baseline.

The governing authorization permitted WP5 documentation and standalone ready-for-execution packaging only. PostgreSQL execution, live-evidence generation, M2.12 acceptance, accepted full-project packaging, Module 3, and production remain unauthorized. [export reference: filecite | turn0file0 | L5-L13] The authorization also requires WP5 to stop for independent review before any separate live-execution authorization. [export reference: filecite | turn0file0 | L29-L29]

## Downloads

- Download M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip`; referenced bytes not established here)
- Download the matching ZIP SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip.sha256`; referenced bytes not established here)

No additional delivery-wrapper ZIP, accepted package, full-project package, or `31_M2_12` stage was created.

## Package status

The package states exactly:

```text
READY FOR LIVE EXECUTION
NOT EXECUTED
NOT ACCEPTED
```

“Ready for live execution” identifies package completeness; it is **not** live-execution authorization. The prescribed status and the prohibition against execution, fabricated evidence, accepted packaging, Module 3 authorization, and production claims come directly from the WP5 authority. [export reference: filecite | turn0file1 | L29-L39]

## Final physical delivery ledger

### Canonical ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip` |
| Bytes | **492,278** |
| SHA-256 | `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c` |
| ZIP file entries | **98** |
| Total uncompressed bytes | **3,926,125** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |
| Separately coded release validation | **197/197 PASS** |

The comparatively small compressed ZIP size reflects compression of approximately 3.93 MB of SQL, CSV, JSON, Markdown, and text files. No large nested predecessor ZIPs were unnecessarily duplicated into the standalone execution package.

### ZIP-to-extraction reconciliation

| Release control | Result |
|---|---:|
| Build-tree versus extracted-tree path mismatches | **0** |
| Byte-size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate ZIP paths | **0** |
| Case-insensitive duplicate ZIP paths | **0** |
| Unsafe ZIP paths | **0** |
| Symbolic links | **0** |
| Missing required files | **0** |
| Unauthorized Programs 228+ | **0** |
| Nested full-project/archive artifacts | **0** |
| Runtime-result-like files | **0** |
| Live-evidence payloads | **0** |
| Execution wrapper scripts | **0** |

## Approved SQL source preservation

The WP5 authority required verification of the governing WP4 ZIP, sidecar, CRC, 77 entries, manifests, inventories, reconciled WP3 signoff, and all twelve current SQL identities, with every SQL byte stream preserved exactly. [export reference: filecite | turn0file1 | L5-L12]

Each packaged SQL file was compared directly against its physical bytes inside the approved `M2_12_Build_WP4_R1.zip`.

### Normal execution chain

| Program | Bytes | SHA-256 | Direct WP4 byte comparison |
|---|---:|---|---:|
| 220 | 759,346 | `757462b1d3c323be9cbe3a98fd5c9a822719ca6e9a15b698644c0650b5413298` | **IDENTICAL** |
| 221 | 208,547 | `774f96643c16a8f2191b057afa01f311c1b663f79e2bf353dcd0d6cd5cc6c909` | **IDENTICAL** |
| 222 | 513,019 | `6e29dba9043675094fb9c399895895b9230e1b96976e5e4af7a7a48e094d51fe` | **IDENTICAL** |
| 223 | 713,276 | `ccb301785dc8a2a80126bc2d70c7d8dfd0db91b2d51b008fb733745ae26d7158` | **IDENTICAL** |
| 224 | 136,668 | `c010ed61c7f93da457235e01902f280596f706f42f232464fac546fd13dbda36` | **IDENTICAL** |
| 225 | 196,837 | `3769fe5c43d8d8aafe18e3e3d4538bd696dc370fd4ca080fa3fa5cfbad625119` | **IDENTICAL** |
| 226 | 116,188 | `e43bab189d439f0e09ad879ea253f6162560e5b157b71f030eaa3ff16b9e3f56` | **IDENTICAL** |
| 227 | 131,787 | `17a27cb49fe0611953d5bc499c15513d46d8768fe441ed1fd0bfb126f3300b50` | **IDENTICAL** |

The physical and documented normal chain is:

```text
220 → 221 → 222 → 223 → 224 → 225 → 226 → 227
```

### Contingency-only recoveries

| Recovery | Bytes | SHA-256 | Direct WP4 byte comparison |
|---|---:|---|---:|
| 220A | 21,491 | `7510697598eb033e95d4d0fb3ff540c41dd0df810577312949b8ef57f1076d93` | **IDENTICAL** |
| 222A | 22,425 | `8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627` | **IDENTICAL** |
| 222B | 118,484 | `056f277eb07ef2144cb06e6afdd0158ea5ad07b96ecc56f0e34813852c1c790a` | **IDENTICAL** |
| 223A | 60,158 | `0e65e3534440414f598a360e7fb67f1b299a4c4bc9883c80c686510af4ff6969` | **IDENTICAL** |

These four recoveries are physically separated from the normal source directory, omitted from the execution-order chain, marked as authorization-required, and governed through a four-row directed-recovery decision matrix. This separation follows the authorized normal-chain and contingency-only structure. [export reference: filecite | turn0file1 | L14-L27]

### Source-set identities

| Source set | SHA-256 |
|---|---|
| Eight-program normal chain | `6c88c593e05a8de9699e61722283b7044158bac7db4bd720156b9769b1d20bd0` |
| Four contingency recoveries | `35d81d74fa5bff735102d5dcc2f1466ab2bb55e989d3df9d46d4b032aef3262c` |
| Complete twelve-file SQL set | `20291f3740a8a1350a84a1283903c56e9b69ac4e65edee7c9028fb2e1ac9011a` |

Physical SQL files changed from approved WP4: **0**.

## Operator documentation delivered

The package contains the authorized operating documentation:

1. One-program-at-a-time execution guide.
2. Stop-on-error and rollback protocol.
3. Directed recovery guide.
4. Expected-results and checkpoint guide.
5. Evidence-capture checklist.
6. Operator pre-execution checklist.
7. Source and provenance authority.
8. Package scope and authority boundaries.
9. Post-execution handoff boundary.

The execution guide requires:

- execution only after independent WP5 approval and explicit authorization naming this ZIP and hash;
- one complete physical SQL file per invocation;
- `ON_ERROR_STOP` behavior;
- no concatenated normal-chain execution;
- no external transaction around multiple programs;
- complete console and result-set capture;
- checkpoint reconciliation before releasing the next program;
- an immediate stop on any error, ambiguity, count mismatch, lifecycle mismatch, or evidence anomaly.

No executable `.bat`, `.cmd`, `.ps1`, `.sh`, or other wrapper was created. This prevents a wrapper from silently bypassing the one-program checkpoint boundary.

## Catalog and traceability ledger

### WP5 operator catalogs

| Catalog | Data rows | Reconciliation |
|---|---:|---:|
| Normal execution order | **8** | **PASS** |
| Program checkpoint catalog | **8** | **PASS** |
| Directed-recovery decision matrix | **4** | **PASS** |
| Future evidence-capture catalog | **44** | **PASS** |
| SQL source SHA-256 inventory | **12** | **PASS** |

All 44 evidence requirements are marked as future live-execution captures. Pre-execution evidence placeholders created: **0**.

### Preserved WP3 validation authority

| Artifact | Data rows | Physical reconciliation |
|---|---:|---:|
| Positive-control catalog | **128** | **PASS** |
| Negative-control catalog | **20** | **PASS** |
| Combined control traceability | **148** | **PASS** |

Additional checks:

| Control | Result |
|---|---:|
| Positive codes missing or duplicated | **0** |
| Negative codes missing or duplicated | **0** |
| Positive SQL marker mismatches | **0** |
| Negative SQL marker mismatches | **0** |
| Combined traceability coverage gaps | **0** |

### Preserved WP4 acceptance and report authority

| Artifact | Data rows | Physical reconciliation |
|---|---:|---:|
| Acceptance-requirement traceability | **48** | **PASS** |
| Acceptance phase-order authority | **8** | **PASS** |
| Master-report traceability | **14** | **PASS** |
| Detailed result-set traceability | **24** | **PASS** |
| Mutation authority | **6** | **PASS** |

Program 225 contains all 48 physical acceptance markers. Program 227 contains all 24 governed result-set markers. Projection, ordering, cardinality, zero-row-header, and source-trace statuses reconcile with no mismatch.

## Package metadata reconciliation

| Metadata artifact | Records | Physical mismatches |
|---|---:|---:|
| `MANIFEST.csv` | **94** | **0** |
| `manifest.json` | **94** | **0** |
| `SHA256SUMS.txt` | **96** | **0** |
| `PACKAGE_INVENTORY.csv` | **97** | **0** |

The manifest, JSON manifest, checksum inventory, and package inventory were independently recalculated from the fully extracted ZIP rather than accepted from their embedded PASS statements.

## Sidecar release gate

The sidecar was created only after the canonical ZIP passed the 197-control independent release validation.

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip.sha256` |
| Bytes | **110** |
| Sidecar SHA-256 | `b71a437634a6b646f75f8068b6ee659918a1bc07c06fdb93dcf963fc03ef8fe3` |
| Physical existence | **PASS** |
| ASCII readback | **PASS** |
| Exact ZIP filename pairing | **PASS** |
| Exact ZIP hash pairing | **PASS** |

The physical sidecar contains:

```text
5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c  M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip
```

## Scope determination

| Boundary | Status |
|---|---:|
| WP5 documentation/source tree | **COMPLETE** |
| Standalone ready-for-execution ZIP | **COMPLETE** |
| External ZIP sidecar | **COMPLETE** |
| PostgreSQL execution | **NOT PERFORMED** |
| Live evidence generation | **NOT PERFORMED** |
| M2.12 runtime validation | **NOT PERFORMED** |
| M2.12 acceptance | **NOT CLAIMED** |
| Accepted/full-project packaging | **NOT CREATED** |
| Stage `31_M2_12` | **NOT CREATED** |
| Module 3 authorization | **NOT CLAIMED** |
| Production/deployment authority | **NOT CLAIMED** |

The physical stopping point is **independent WP5 package review and live-execution authorization**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e7bc8fbd-7e02-4d29-a7d7-d9d8ec811ce0"></a>
## Andrew / user · C085-M00018

C085-M00018 · 2026-08-10T18:47:44.576000-04:00 · active path

Preceding visible parent: [C085-M00017](part-01.md#m-e4a43ab9-fab9-4386-9762-7421111e711b)

**Editorial record note:** Attachment references: M2_12_STANDALONE_READY_FOR_EXECUTION_R1(2)(1).zip; M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip(2)(1).sha256; M2_12_WP5_R1_APPROVED_IDENTITY_20260810(1).txt; M2_12_WP5_R1_FINAL_AUDIT_DELIVERY_INDEX_20260810(1).md; M2_12_WP5_R1_FINAL_INDEPENDENT_AUDIT_CONTROLS_20260810(1).csv; M2_12_WP5_R1_FINAL_INDEPENDENT_AUDIT_FINDINGS_20260810(1).csv; M2_12_WP5_R1_FINAL_INDEPENDENT_AUDIT_PACKAGE_VALIDATION_REPORT_20260810(1).md; M2_12_WP5_R1_FINAL_INDEPENDENT_AUDIT_REPORT_20260810(1).md; M2_12_WP5_R1_FINAL_INDEPENDENT_AUDIT_SUMMARY_20260810(1).json; M2_12_WP5_R1_FINAL_SIGNOFF_AND_LIVE_EXECUTION_AUTHORIZATION_20260810(1).md; M2_12_LIVE_EXECUTION_AUTHORIZED_PROMPT_20260810(1).md

<!-- BEGIN_SOURCE_MESSAGE -->
M2.12 WP5 is approved. I will begin the live execution. Any guidance on the live execution?
<!-- END_SOURCE_MESSAGE -->


<a id="m-096f6da2-bb67-4589-9599-14cb1afd4832"></a>
## Assistant · C085-M00019

C085-M00019 · 2026-08-10T18:48:00.770330-04:00 · active path

Preceding visible parent: [C085-M00018](part-01.md#m-e7bc8fbd-7e02-4d29-a7d7-d9d8ec811ce0)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m grounding the guidance in the approved operator guide, checkpoint and evidence catalogs, and recovery matrix, translating them into a practical one-program-at-a-time DBeaver workflow.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d67d02f1-ceb4-4076-b4dc-aea9f9a313e0"></a>
## Assistant · C085-M00020

C085-M00020 · 2026-08-10T18:51:04.749848-04:00 · active path

Preceding visible parent: [C085-M00019](part-01.md#m-096f6da2-bb67-4589-9599-14cb1afd4832)

<!-- BEGIN_SOURCE_MESSAGE -->
Only Program 220 is currently authorized; later programs unlock only after exact checkpoint reconciliation. Execution should use `psql` one file at a time with first-error-stop behavior.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1405df57-2099-4abb-a94b-26d48c619697"></a>
## Assistant · C085-M00021

C085-M00021 · 2026-08-10T18:59:27.825757-04:00 · active path

Preceding visible parent: [C085-M00020](part-01.md#m-d67d02f1-ceb4-4076-b4dc-aea9f9a313e0)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 controlled live-execution guidance

The most important rule is: **execute Program 220 only at first. Do not batch the chain.** Program 220 is currently authorized; Programs 221–227 become authorized individually and sequentially only after the preceding program’s transcript, result sets, counts, lifecycle, hashes, sequence state, and checkpoint reconcile without ambiguity. Recoveries 220A, 222A, 222B, and 223A remain unauthorized. [export reference: filecite | turn0file5 | L34-L50]

I independently rechecked the newly uploaded copy. It reproduces the approved physical identity:

```text
M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip
Bytes:                    492,278
SHA-256:                  5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c
ZIP entries:              98
Total uncompressed bytes: 3,926,125
ZIP CRC:                  PASS
```

The internal `SHA256SUMS.txt`, manifest, package inventory, and all 12 SQL identities also reconciled with zero mismatches in my fresh readback. These values match the approved package identity. [export reference: filecite | turn0file0 | L3-L8]

## 1. Normalize the downloaded filenames

The copies uploaded here have browser-added duplicate suffixes. For the execution record, use these exact canonical local names:

```text
M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip
M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip.sha256
```

The sidecar must contain exactly:

```text
5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c  M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip
```

Renaming the files does not alter their bytes, but the canonical filename matters for an unambiguous evidence record.

Do not edit the internal package because some internal files still say `NOT EXECUTED`, `NOT ACCEPTED`, or pending live authorization. Those are correct construction-state records. The **external final signoff** now supplies the live-execution authority, while runtime validation and audit-approved M2.12 acceptance remain pending. [export reference: filecite | turn0file5 | L5-L16]

## 2. Make a clean extraction and separate evidence workspace

Use a new, empty extraction directory. Preserve the ZIP and one untouched extracted source copy.

Create a separate evidence location, outside the source package:

```text
M2_12_LIVE_EXECUTION_EVIDENCE_20260810/
├── 00_pre_execution/
├── 220/
├── 221/
├── 222/
├── 223/
├── 224/
├── 225/
├── 226/
└── 227/
```

Create directories only. Do **not** pre-create populated PASS files, expected-result CSVs, or other evidence placeholders. The authorized evidence catalog requires 44 future items and specifically prohibits fabricated pre-execution evidence. [export reference: filecite | turn0file6 | L35-L37]

Also retain the following external authorization documents with the evidence set:

```text
M2_12_WP5_R1_FINAL_SIGNOFF_AND_LIVE_EXECUTION_AUTHORIZATION_20260810.md
M2_12_LIVE_EXECUTION_AUTHORIZED_PROMPT_20260810.md
M2_12_WP5_R1_APPROVED_IDENTITY_20260810.txt
```

## 3. Complete the pre-Program-220 gate

Before Program 220, the authorization requires local verification of the ZIP, sidecar, CRC, 98 entries, 3,926,125 uncompressed bytes, internal metadata, and all 12 SQL identities. It also requires environment capture, proof of the accepted M2.11 predecessor, and a current backup or approved restore checkpoint. [export reference: filecite | turn0file6 | L11-L20]

### Package-hash and sidecar check

A basic PowerShell gate is:

```powershell
$zip = "C:\PATH\M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip"
$sidecar = "$zip.sha256"

$expectedHash =
    "5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c"

$actualHash = (
    Get-FileHash -LiteralPath $zip -Algorithm SHA256
).Hash.ToLowerInvariant()

if ($actualHash -ne $expectedHash) {
    throw "STOP: canonical ZIP SHA-256 mismatch."
}

$expectedSidecar =
    "$expectedHash  M2_12_STANDALONE_READY_FOR_EXECUTION_R1.zip"

$actualSidecar = (
    Get-Content -LiteralPath $sidecar -Raw
).Trim()

if ($actualSidecar -ne $expectedSidecar) {
    throw "STOP: sidecar filename/hash pairing mismatch."
}

"ZIP SHA-256 and sidecar pairing PASS"
```

Run a real archive test such as 7-Zip’s **Test** operation or `7z t`, then extract to a brand-new empty directory. Recalculate all 12 SQL hashes against:

```text
04_catalogs\M2_12_SQL_SOURCE_SHA256_INVENTORY.csv
```

No SQL file should be opened and saved, reformatted, line-ending converted, or otherwise modified.

### Environment capture

Capture at least:

```sql
SELECT
    version()                                             AS postgresql_version,
    current_database()                                    AS database_name,
    current_user                                          AS database_user,
    session_user                                          AS session_user,
    inet_server_addr()::text                              AS server_address,
    inet_server_port()                                    AS server_port,
    pg_backend_pid()                                      AS backend_pid,
    current_setting('TimeZone')                           AS timezone,
    current_setting('client_encoding')                    AS client_encoding,
    current_setting('search_path')                        AS search_path,
    current_setting('statement_timeout')                  AS statement_timeout,
    current_setting('lock_timeout')                       AS lock_timeout,
    current_setting('idle_in_transaction_session_timeout') AS idle_in_transaction_timeout,
    clock_timestamp()                                     AS captured_at;
```

Also record:

```powershell
psql --version
```

Save the physical environment record as:

```text
00_execution_environment.txt
```

Do not change timeout, search-path, or session settings ad hoc simply because their values differ from what you expected. Resolve any material environment concern before Program 220.

### Predecessor checkpoint

Export this read-only result as:

```text
00_predecessor_checkpoint.csv
```

```sql
SELECT
    rr.run_id,
    rr.run_code,
    rr.run_version,
    rr.run_status,
    rr.as_of_date,
    m211.contract_code,
    m211.contract_version,
    m211.contract_status,
    m211.contract_set_hash,
    m211.combined_set_hash,
    m211.row_hash
FROM msbf_ctl.run_registry rr
JOIN msbf_ctl.m2_11_portfolio_strategy_contract_registry m211
  ON m211.module1_run_id = rr.run_id
 AND m211.contract_code =
     'M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION'
 AND m211.contract_version = 1
 AND m211.contract_status = 'ACCEPTED'
WHERE rr.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND rr.run_version = 1
  AND rr.run_status = 'M2_11_ACCEPTED'
ORDER BY rr.run_id;
```

Required result:

```text
Exactly one row
run_code       = M1_V0_2_BASELINE_BUILD
run_version    = 1
run_status     = M2_11_ACCEPTED
contract_status= ACCEPTED
```

Confirm the gate catalog separately:

```sql
SELECT
    gate_id,
    module_code,
    gate_name,
    description,
    severity,
    active_flag
FROM msbf_ref.acceptance_gate_catalog
WHERE gate_id = 'G3_M2_CONTRACT';
```

Required result:

```text
Exactly one row
gate_id      = G3_M2_CONTRACT
module_code  = M2
gate_name    = Module 2 Contract
description  = Offer contract accepted.
severity     = BLOCKING
active_flag  = true
```

### Backup or restore checkpoint

Do not begin Program 220 until a current full database backup or approved restore checkpoint exists and has been recorded. A logical backup through the project’s established `pg_dump` process is reasonable, but the governing requirement is a proven restore point—not merely a filename that has not been tested or checked.

## 4. Execute through `psql`, not ordinary editor execution

Use `psql.exe` from PowerShell, or a graphical client mode that explicitly invokes the PostgreSQL native client against the **complete unchanged physical file**. Do not paste the SQL into an editor, run a selection, or use ordinary statement-by-statement editor execution.

That distinction matters because the source set includes psql meta-commands and requires first-error-stop behavior. PostgreSQL 15 documents that `-f` reads the physical script file, `-X` prevents startup files from changing the session, and `-v` assigns psql variables. It also assigns nonzero exit statuses to client, connection, or script failures when `ON_ERROR_STOP` is active. Do **not** add `-1` or `--single-transaction`; that option creates an outer transaction, while these governed files contain their own transaction boundaries. [export reference: cite | turn952851view0]

Use a fresh `psql` process for every program. Do not use a loop.

A Program 220 template is:

```powershell
$psql = (Get-Command psql.exe -ErrorAction Stop).Source

$sourceRoot =
    "C:\PATH\M2_12_STANDALONE_READY_FOR_EXECUTION_R1"

$evidenceRoot =
    "C:\PATH\M2_12_LIVE_EXECUTION_EVIDENCE_20260810"

$dbHost = "localhost"       # Confirm the actual target
$dbPort = 5432              # Confirm the actual target
$dbName = "msbf_strategy"
$dbUser = "YOUR_DATABASE_USER"

$program = Join-Path $sourceRoot `
    "01_sql_normal\220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1.sql"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"

$log = Join-Path $evidenceRoot `
    "220\220_console_$stamp.txt"

$processStatus = Join-Path $evidenceRoot `
    "220\220_process_status_$stamp.txt"

# Reconfirm the source immediately before execution.
$programHash = (
    Get-FileHash -LiteralPath $program -Algorithm SHA256
).Hash.ToLowerInvariant()

if ($programHash -ne
    "757462b1d3c323be9cbe3a98fd5c9a822719ca6e9a15b698644c0650b5413298") {
    throw "STOP: Program 220 source hash mismatch."
}

& $psql `
    -X `
    -v ON_ERROR_STOP=1 `
    -h $dbHost `
    -p $dbPort `
    -U $dbUser `
    -d $dbName `
    -f $program `
    *> $log

$exitCode = $LASTEXITCODE

Set-Content `
    -LiteralPath $processStatus `
    -Value "psql_exit_code=$exitCode" `
    -Encoding ascii

if ($exitCode -ne 0) {
    throw "STOP: Program 220 returned psql exit code $exitCode. Do not continue."
}
```

Do not place a database password in the command, command history, transcript, or evidence directory.

Before running Program 220, make sure the selected client path can preserve both:

1. the complete unedited console output and process exit code; and
2. the final governed result set with headers, exportable as `220_primary_result.csv`.

A transcript alone is not a substitute for the required physical result-set export.

## 5. Use this exact release ledger

The following checkpoints come from the package’s internal `M2_12_PROGRAM_CHECKPOINT_CATALOG.csv` and evidence catalog. The independent audit confirmed that the package contains eight exact program checkpoints, 44 required evidence captures, 128 positive controls, 20 negative controls, 48 acceptance requirements, and 24 detailed result sets. [export reference: filecite | turn0file3 | L41-L56]

| Program | Required physical output and release checkpoint |
|---|---|
| **220** | One primary row. `installation_status=PASS`; 21 installed top-level objects; 26 executable DDL statements; one policy row; zero non-policy rows; policy identity 1; policy sequence `1\|true`; run remains `M2_11_ACCEPTED`; disposition `READY_FOR_PROGRAM_221`. |
| **221** | One primary row. `preflight_status=PASS`; 48 assertion rows and 48 passed; 19 source edges; 13 component contracts; 12 certification nodes; 72 mandatory evidence rows; 20 capability rows; run remains `M2_11_ACCEPTED`; disposition `AUTHORIZED_TO_EXECUTE_PROGRAM_222`. No persistent state change. |
| **222** | One primary row. `generation_status=PASS`; nine canonical families; 134 canonical entities; 24 generation-evidence rows; consumption counts `1500 / 59 / 24`; policy/archive/registry identities 1; all owned sequences `1\|true`; combined-set hash is 32 lowercase hexadecimal characters; run `M2_12_GENERATED`; registry `GENERATED`; disposition `READY_FOR_PROGRAM_223`. |
| **223** | One persistence row plus exactly 128 positive-control rows. `persistence_status=PASS`; all 128 controls PASS and distinct; negative, acceptance, and gate rows remain zero; hash comparison/exact rows both 1; run `M2_12_VALIDATED`; registry `VALIDATED`. |
| **224** | One persistence row plus exactly 20 negative-control rows. `persistence_status=PASS`; all 20 controls PASS and distinct with expected rejection/isolation signatures; 128 positive rows remain; 20 negative rows persist; acceptance and gate rows remain zero; `exact_flag=true`; lifecycle remains `M2_12_VALIDATED / VALIDATED`. |
| **225** | One acceptance row. Acceptance, G3 gate, and acceptance evidence all PASS; 48/48 requirements; 128 positive controls; 20 negative controls; 134 canonical entities; run `M2_12_ACCEPTED`; registry `ACCEPTED`. The four output fields for deployment, legal/regulatory certification, autonomous champion, and Module 3 must each remain `NOT_AUTHORIZED`. |
| **226** | Exactly one master-report row with `master_report_status=PASS`; 9 families/134 entities; consumption `1500 / 59 / 24`; component latest/archive `7129 / 7129`; generation 24; positive 128; negative 20; acceptance requirements 48; zero findings. No persistent state change. |
| **227** | Exactly 24 result sets in order, with cardinalities `1,1,1,12,13,19,72,13,13,3,1500,3,59,24,24,3,8,20,1,1,12,6,0,0`. Result Sets 23 and 24 must retain their headers and contain zero data rows. No persistent state change. |

A printed `PASS` is not enough. Recalculate row counts, distinct codes, statuses, lifecycle, hashes, and sequence values from the captured physical outputs before releasing the next program.

## 6. Evidence filenames

Before Program 220:

```text
00_package_verification.txt
00_execution_environment.txt
00_predecessor_checkpoint.csv
```

Per-program console transcripts:

```text
220_console_<YYYYMMDD_HHMMSS>.txt
221_console_<YYYYMMDD_HHMMSS>.txt
222_console_<YYYYMMDD_HHMMSS>.txt
223_console_<YYYYMMDD_HHMMSS>.txt
224_console_<YYYYMMDD_HHMMSS>.txt
225_console_<YYYYMMDD_HHMMSS>.txt
226_console_<YYYYMMDD_HHMMSS>.txt
227_console_<YYYYMMDD_HHMMSS>.txt
```

Governed results:

```text
220_primary_result.csv
221_primary_result.csv
222_primary_result.csv

223_persistence_result.csv
223_positive_control_detail.csv

224_persistence_result.csv
224_negative_control_detail.csv

225_acceptance_result.csv
226_master_report.csv

227_result_set_01.csv
...
227_result_set_24.csv
```

For Program 227, do not combine the 24 result sets into one undifferentiated export. Each must remain separately identifiable and in its governed sequence. Result Sets 23 and 24 require headers even though they require zero rows. [export reference: filecite | turn0file6 | L31-L37]

## 7. Immediate stop protocol

Stop immediately upon any:

- nonzero psql exit code;
- PostgreSQL `ERROR`, `FATAL`, unexpected SQLSTATE, or fail-closed exception;
- timeout, cancellation, disconnect, or ambiguous `COMMIT`;
- missing result set or damaged export;
- unexpected row count, missing or duplicate code, or non-PASS status;
- lifecycle, hash, sequence, canonical-count, evidence-count, or gate mismatch.

Then:

1. Preserve the complete console transcript and screen state unchanged.
2. Do not run the next program.
3. Do not rerun the failed program.
4. Do not edit SQL or issue ad hoc DML/DDL.
5. Do not manually reset a sequence.
6. If the same session remains connected with an active or aborted transaction, issue only `ROLLBACK;`, capture its response, and disconnect.
7. Record whether the outcome was observed commit, explicit rollback, disconnect, or ambiguous.
8. Diagnose persistent state read-only.
9. Obtain separate authority before any recovery or rerun.

The authorization expressly prohibits rerunning, patching, choosing a recovery, or continuing after an anomaly. [export reference: filecite | turn0file5 | L44-L50]

## 8. Recovery files are not “next steps”

Do not run any of these during the normal chain:

```text
220A
222A
222B
223A
```

Even when a failure appears to match a recovery description, recovery requires:

- exact persistent-state diagnosis;
- a matching decision-matrix row;
- proof of transaction outcome;
- proof of hashes, counts, lifecycle, and relevant sequence state;
- separate authorization naming the exact recovery file and its SHA-256.

An unsupported state is not permission to select the “closest” recovery.

## 9. Preserve the broader archive

The independent audit’s single nonblocking advisory is that the standalone ZIP contains a curated design-authority extract, not the complete historical design archive. It is sufficient for execution, but it should not replace the complete final design and audit repository. Preserve that broader archive separately. [export reference: filecite | turn0file3 | L58-L66]

## 10. Required stopping point

After Program 227:

```text
STOP
```

Do not create:

```text
accepted M2.12 packaging
full-project packaging
stage 31_M2_12
Module 3 artifacts
production/deployment artifacts
```

The complete physical evidence must first receive an independent live-execution audit. [export reference: filecite | turn0file5 | L53-L55]

**Begin with Program 220 only. Before Program 221, return the three pre-execution records, the unedited Program 220 console transcript, its process-status record, and `220_primary_result.csv` for checkpoint reconciliation.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-7875c30a-28ad-4443-b073-3588daba44e1"></a>
## Andrew / user · C085-M00022

C085-M00022 · 2026-08-10T19:01:02.784000-04:00 · active path

Preceding visible parent: [C085-M00021](part-01.md#m-1405df57-2099-4abb-a94b-26d48c619697)

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 220: SQL Error [42803]: ERROR: subquery uses ungrouped column "c.oid" from outer query
  Where: PL/pgSQL function inline_code_block line 3 at IF
  ERROR: subquery uses ungrouped column "c.oid" from outer query
  Where: PL/pgSQL function inline_code_block line 3 at IF             correct error in a hotfix and do not wait for my approval. I selected stop and used rollback;
<!-- END_SOURCE_MESSAGE -->


<a id="m-fb506cf1-cccb-4f71-81d6-7e6b2c1622fb"></a>
## Assistant · C085-M00023

C085-M00023 · 2026-08-10T19:01:17.737877-04:00 · active path

Preceding visible parent: [C085-M00022](part-01.md#m-7875c30a-28ad-4443-b073-3588daba44e1)

<!-- BEGIN_SOURCE_MESSAGE -->
Rollback was the correct containment action. I’m isolating the failing Program 220 catalog query, applying the narrowest correction, and rebuilding a separately identified hotfix with fresh release checks.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e4c8e61b-f897-49cf-a933-26d4ee0dc8f0"></a>
## Assistant · C085-M00024

C085-M00024 · 2026-08-10T19:04:21.581843-04:00 · active path

Preceding visible parent: [C085-M00023](part-01.md#m-fb506cf1-cccb-4f71-81d6-7e6b2c1622fb)

<!-- BEGIN_SOURCE_MESSAGE -->
The defect spans seven adjacent view postflight checks (`P220_PF_0012`–`0018`); I’m patching all seven together while leaving DDL, transaction order, and downstream programs unchanged.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7cca05ac-07c2-4a85-b305-f6b52059dd6f"></a>
## Assistant · C085-M00025

C085-M00025 · 2026-08-10T19:19:55.109383-04:00 · active path

Preceding visible parent: [C085-M00024](part-01.md#m-e4c8e61b-f897-49cf-a933-26d4ee0dc8f0)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 220 HF1 — Hotfix complete

Your stop-and-rollback response was correct. The live-execution authority required an immediate stop on any error and prohibited continuing, rerunning, or modifying the source without a new explicit direction. [export reference: filecite | turn2file5 | L44-L50]

The original approved package remains the historical R1 identity—492,278 bytes, SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`. [export reference: filecite | turn2file0 | L3-L12] **Do not rerun its original Program 220.** Use HF1 below.

## Downloads

### Superseding full execution package

- Download M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF1.zip (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF1.zip`; referenced bytes not established here)
- Download the matching ZIP SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF1.zip.sha256`; referenced bytes not established here)

### Corrected Program 220 directly

- Download Program 220 HF1 SQL (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF1.sql`; referenced bytes not established here)
- Download the Program 220 HF1 SQL sidecar (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF1.sql.sha256`; referenced bytes not established here)

### Validation record

- Download the HF1 release-validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF1_RELEASE_VALIDATION_REPORT.md`; referenced bytes not established here)

## Root cause and correction

The problem existed in **seven consecutive Program 220 postflight statements**:

```text
0057  P220_PF_0012_TOP_LEVEL_OBJECT
0058  P220_PF_0013_TOP_LEVEL_OBJECT
0059  P220_PF_0014_TOP_LEVEL_OBJECT
0060  P220_PF_0015_TOP_LEVEL_OBJECT
0061  P220_PF_0016_TOP_LEVEL_OBJECT
0062  P220_PF_0017_TOP_LEVEL_OBJECT
0063  P220_PF_0018_TOP_LEVEL_OBJECT
```

Each original check combined:

```sql
SELECT count(*) = 1
   AND bool_and(...)
   AND NOT EXISTS (
       ...
       WHERE r.ev_class = c.oid
   )
FROM pg_catalog.pg_class c
...
```

Because the outer query was an aggregate query, the correlated subquery’s reference to `c.oid` was treated as an ungrouped outer column, causing SQLSTATE `42803`.

HF1 rewrites each affected check into two levels:

1. An inner nonaggregate catalog query calculates `has_temporary_dependency` for each physical view OID.
2. An outer aggregate requires:
   - exactly one catalog row;
   - `relkind='v'`;
   - persistent relation status;
   - no temporary dependency.

This preserves the intended structural assertion while eliminating the illegal grouped-query reference.

## Scope lock

| Control | Result |
|---|---:|
| Affected governed statements corrected | **7** |
| Other Program 220 governed statements unchanged | **466** |
| Total governed statements retained | **473** |
| Persistent DDL literals changed | **0** |
| Policy-source or policy-insert literals changed | **0** |
| Transaction boundaries changed | **0** |
| Primary-result statement changed | **0** |
| Programs 221–227 changed | **0** |
| Recovery files changed | **0** |
| Original defective pattern occurrences | **7** |
| HF1 defective pattern occurrences | **0** |
| HF1 safe replacement occurrences | **7** |

The same invalid aggregate/correlated-subquery pattern was scanned across all twelve SQL files and no additional occurrence remains.

## Physical delivery ledger

### Full HF1 ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF1.zip` |
| Bytes | **511,970** |
| SHA-256 | `c1930650ec975d985cbccbef7144be291e4838950cb4c9027be238e5270f6a4d` |
| ZIP entries | **112** |
| Total uncompressed bytes | **3,959,759** |
| ZIP CRC | **PASS** |
| Complete second extraction | **PASS** |
| Path mismatches | **0** |
| Size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Symbolic links | **0** |
| Manifest mismatches | **0** |
| `manifest.json` mismatches | **0** |
| `SHA256SUMS.txt` mismatches | **0** |
| Package-inventory mismatches | **0** |

The ZIP sidecar contains:

```text
c1930650ec975d985cbccbef7144be291e4838950cb4c9027be238e5270f6a4d  M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF1.zip
```

### Corrected Program 220

| Attribute | Physical result |
|---|---:|
| Bytes | **762,568** |
| SHA-256 | `c6557ec52762762df556dffc935aa84792beace0d03c0da6696f5b5a152e7e7c` |
| Governed statement markers | **473** |
| HF1 static controls | **21/21 PASS** |
| Physical readback | **PASS** |
| Direct-SQL versus packaged-SQL comparison | **IDENTICAL** |

The direct SQL sidecar contains:

```text
c6557ec52762762df556dffc935aa84792beace0d03c0da6696f5b5a152e7e7c  220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF1.sql
```

### Updated source-set identities

| Source set | SHA-256 |
|---|---|
| Eight-program normal chain | `e4d6c9079b3b5c600860efbd1ac46b532563477f22abdd87ee71f83d04cf5697` |
| Four unchanged recoveries | `35d81d74fa5bff735102d5dcc2f1466ab2bb55e989d3df9d46d4b032aef3262c` |
| Complete twelve-file SQL set | `5e84111801832529a5a494462b866d29163e793e19ec1ef05c1556efe7bb4cd3` |

## Before rerunning Program 220

Open and follow:

```text
03_docs/M2_12_PROGRAM_220_HF1_RESTART_PROTOCOL.md
```

It contains read-only checks for all Program-220-created objects. The required rollback proof is:

```text
19 expected relations/sequences    all NULL
m2_12 rejection function count     0
archive immutability trigger count 0
governed run rows                  exactly 1
run_code                           M1_V0_2_BASELINE_BUILD
run_version                        1
run_status                         M2_11_ACCEPTED
```

Although you issued `ROLLBACK`, that database state still needs to be physically demonstrated. Any non-null Program 220 object or different lifecycle is a hard stop.

## Execution boundary

Once the pristine-state check passes:

1. Recalculate the HF1 Program 220 hash and require `c6557ec52762762df556dffc935aa84792beace0d03c0da6696f5b5a152e7e7c`.
2. Execute the **entire HF1 Program 220 file only**.
3. Add no outer transaction.
4. Stop at first error.
5. Capture the unedited transcript and primary result.
6. Do not execute Program 221 until Program 220 produces the exact checkpoint.

Required Program 220 result:

```text
installation_status         PASS
installed_top_level_objects 21
executable_ddl_statements   26
policy_rows                 1
nonpolicy_rows              0
policy_identity             1
policy_sequence_state       1|true
disposition                 READY_FOR_PROGRAM_221
```

The governing normal chain remains `220 → 221 → 222 → 223 → 224 → 225 → 226 → 227`, with each later program conditional on the exact prior checkpoint. [export reference: filecite | turn2file5 | L34-L41]

HF1 has passed physical and builder-side static validation, but it has **not** been PostgreSQL-executed here and is **not** being represented as an independent post-hotfix audit. After the corrected Program 220 completes, return its unedited console transcript and primary result before releasing Program 221.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0415fe0e-865c-4e3a-9a6e-d0d81e06a260"></a>
## Andrew / user · C085-M00026

C085-M00026 · 2026-08-10T19:22:49.979000-04:00 · active path

Preceding visible parent: [C085-M00025](part-01.md#m-7cca05ac-07c2-4a85-b305-f6b52059dd6f)

<!-- BEGIN_SOURCE_MESSAGE -->
another error in program 220: SQL Error [P0001]: ERROR: M2.12 Program 220 installation postflight failed: P220_PF_0064_PERSISTENT_COLUMN
  Detail: check_code=P220_PF_0064_PERSISTENT_COLUMN
  Where: PL/pgSQL function inline_code_block line 12 at RAISE
  ERROR: M2.12 Program 220 installation postflight failed: P220_PF_0064_PERSISTENT_COLUMN
  Detail: check_code=P220_PF_0064_PERSISTENT_COLUMN
  Where: PL/pgSQL function inline_code_block line 12 at RAISE     correct error in a hotfix and do not wait for my approval. i selected stop and used rollback;
<!-- END_SOURCE_MESSAGE -->


<a id="m-38ed9a0d-9d3b-4271-8321-4638d14e76ad"></a>
## Assistant · C085-M00027

C085-M00027 · 2026-08-10T19:23:06.191314-04:00 · active path

Preceding visible parent: [C085-M00026](part-01.md#m-0415fe0e-865c-4e3a-9a6e-d0d81e06a260)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m treating the rollback as preserving pre-install state while reconciling `P220_PF_0064_PERSISTENT_COLUMN` against the actual DDL. I’ll issue a superseding HF2 package rather than alter HF1.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9816073d-0e8e-474f-9f32-3837056f9645"></a>
## Assistant · C085-M00028

C085-M00028 · 2026-08-10T19:26:11.263632-04:00 · active path

Preceding visible parent: [C085-M00027](part-01.md#m-38ed9a0d-9d3b-4271-8321-4638d14e76ad)

<!-- BEGIN_SOURCE_MESSAGE -->
The failure is a catalog-name mismatch: `format_type(...)` returns `timestamp with time zone`, not alias `timestamptz`. HF2 will correct all 14 affected postflight checks.
<!-- END_SOURCE_MESSAGE -->


<a id="m-34611049-85e2-4bb8-aedd-250d54272e74"></a>
## Assistant · C085-M00029

C085-M00029 · 2026-08-10T19:35:16.053553-04:00 · active path

Preceding visible parent: [C085-M00028](part-01.md#m-9816073d-0e8e-474f-9f32-3837056f9645)

<!-- BEGIN_SOURCE_MESSAGE -->
HF2 is physically built with all 327 column postflights reconciled and no DDL or downstream SQL changes. I’m completing independent ZIP/extraction and manifest validation before sidecar release.
<!-- END_SOURCE_MESSAGE -->
