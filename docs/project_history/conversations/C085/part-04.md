# WP3 Build Protocol

Part 04 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-03.md)
[Next part](part-05.md)

<a id="m-2589f651-53dc-4cc4-9daf-cbe2dee86ed7"></a>
## Assistant · C085-M00072

C085-M00072 · 2026-08-11T09:30:29.108281-04:00 · active path

Preceding visible parent: [C085-M00071](part-03.md#m-b93d65d5-291c-4383-b6c5-16bcf2aae8f3)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 222 HF9 — Bounded Correction Complete

Your **stop-and-rollback response was correct**. The controlled execution authority requires an immediate stop on any error and prohibits an ad hoc patch, rerun, recovery selection, or advance to the next program without an explicitly governed correction. [export reference: filecite | turn12file5 | L36-L50]

The attached HF8 pre-execution evidence confirms that the failure was inside Program 222 rather than in predecessor state:

- all **19 source-graph edges passed**, with one accepted-source row, one target row, matching hashes, and zero mismatch flags for every edge; [export reference: filecite | turn13file0 | L10-L29]
- all **12 stage boundaries passed**, covering 70 required and 70 physical controls with zero duplicates, missing controls, non-PASS controls, or violations; [export reference: filecite | turn13file1 | L40-L52]
- the run remained `M2_11_ACCEPTED`, the M2.12 target remained pristine, the three sequence states remained `1|true`, `1|false`, and `1|false`, and the verifier returned `READY_TO_EXECUTE_PROGRAM_222_HF8`. [export reference: filecite | turn13file2 | L63-L64]

**Do not rerun Program 222 HF8. Program 222 HF9 is the only current Program 222 retry source.**

## Downloads

### Controlled continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF9.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF9.zip`; referenced bytes not established here)
- Download the matching HF9 ZIP sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF9.zip.sha256`; referenced bytes not established here)

This is a bounded continuation package after completed Programs 220 and 221. It contains exactly one executable governed program—Program 222 HF9—and one read-only verifier. It contains no executable Program 220, 221, 223–227, or recovery source.

### Program 222 HF9

- Download Program 222 HF9 SQL (historical reference: `sandbox:[session]/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql`; referenced bytes not established here)
- Download the Program 222 HF9 SQL sidecar (historical reference: `sandbox:[session]/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql.sha256`; referenced bytes not established here)

### Mandatory pre-execution verifier

- Download the HF9 state, source-graph, and stage-boundary verifier (historical reference: `sandbox:[session]/222_HF9_pre_execution_state_source_graph_and_stage_boundary_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/222_HF9_pre_execution_state_source_graph_and_stage_boundary_verification.sql.sha256`; referenced bytes not established here)

### Operator and principal validation records

- Download the HF9 operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Download the builder-side validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the independent physical/static readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the 133-control independent readback ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)

## Reported SQLSTATE 42702 root cause

The first failing statement was governed **Statement 158**, which builds:

```text
tmp_hash_m2_12_pre_registry
```

HF8 used an unqualified predicate equivalent to:

```sql
module1_run_id = ctx.module1_run_id
```

At that query scope, multiple participating relations exposed `module1_run_id`. PostgreSQL therefore could not determine which relation owned the left-side reference and raised:

```text
SQLSTATE 42702
column reference "module1_run_id" is ambiguous
```

HF9 binds each run key explicitly to its owning alias.

# Broader Program 222 review

The correction did not stop at Statement 158. All **206 governed statements** were reviewed, including every statement reachable after the HF8 failure point.

## 1. Complete ambiguous run-key family

Four multi-source hash-stage statements contained the same ambiguous identifier class:

| Statement | Helper | HF9 correction |
|---:|---|---|
| **158** | `tmp_hash_m2_12_pre_registry` | Explicit archive/base-six run-key aliasing |
| **170** | `tmp_hash_m2_12_registry` | Explicit registry run-key alias |
| **174** | `tmp_hash_m2_12_contract` | Explicit registry and registry-hash aliases |
| **182** | `tmp_hash_m2_12_combined` | Explicit canonical-entity run-key alias |

Residual executable multi-source ambiguity in HF9:

```text
0
```

The remaining unqualified run-key occurrences are confined to Statement 51’s single-local-relation correlated subqueries, where only one local relation exposes that column. Each was individually classified and retained.

## 2. Unquoted lifecycle literals

Statements 170, 174, and 182 also used:

```sql
ctx.run_status = M2_11_ACCEPTED
```

without quoting the governed text value. PostgreSQL could interpret `M2_11_ACCEPTED` as an identifier rather than a text literal.

HF9 uses:

```sql
ctx.run_status = 'M2_11_ACCEPTED'
```

in all affected statements.

Residual unquoted lifecycle comparisons:

```text
0
```

## 3. Missing aggregate grouping

Statements 170 and 182 selected:

```sql
ctx.module1_run_id
```

beside `string_agg(...)` without an accompanying `GROUP BY`. Those queries would have encountered the same aggregate-scope class that previously caused failures in Program 220.

HF9 adds:

```sql
GROUP BY ctx.module1_run_id
```

to both helpers.

Every `string_agg`-bearing governed statement was separately reviewed:

```text
Aggregate-bearing statements reviewed    20 / 20 PASS
Grouping defects remaining                0
```

## 4. Tautological context predicate

Statement 116 contained a single-source predicate that effectively resolved to:

```sql
module1_run_id = ctx.module1_run_id
```

where the unqualified column could resolve to the context relation itself. That made the expression a meaningless self-comparison rather than a useful state constraint.

HF9 replaces it with the exact governed lifecycle assertion:

```sql
ctx.run_status = 'M2_11_ACCEPTED'
```

## 5. Later deterministic hash-preimage defect

The expanded post-failure review found another likely deterministic blocker in **Statement 191**, before runtime reached it.

The authoritative evidence-family set hash is built from:

```text
node_sequence
| evidence_family_sequence
| row_hash
```

The authoritative canonical entity key is:

```text
node_sequence
| evidence_family_sequence
```

HF8’s physical reconciliation incorrectly inserted `evidence_family_code` into both preimages:

```text
node_sequence
| evidence_family_sequence
| evidence_family_code
| row_hash
```

and:

```text
node_sequence
| evidence_family_sequence
| evidence_family_code
```

That made the physical-reconstruction preimages differ from the authoritative builders and would likely have produced later set-hash and combined-hash mismatches.

HF9 aligns Statement 191 with the authoritative preimages. All nine canonical families were then independently compared:

```text
Hash-preimage families reviewed          9 / 9 PASS
Set-hash preimage mismatches              0
Canonical entity-key mismatches           0
```

## 6. Post-failure tail review

Every statement from the first failing point through final commit was reviewed:

```text
Statements 158–206 reviewed             49 / 49 PASS
Temporary-helper scheduling gaps          0
Aggregate-scope failures                  0
Residual lifecycle-literal defects        0
Residual ambiguous multi-source keys      0
Persistent-mutation changes               0
```

# Bounded source scope

| Control | HF9 result |
|---|---:|
| Governed statements retained | **206** |
| Substantively corrected statements | **6** |
| Diagnostic-label-only changes | **16** |
| Total changed statements | **22** |
| Unchanged statement bodies | **184** |
| Persistent mutation statements changed | **0** |
| Persistent DDL changed | **0** |
| Persistent mutation targets changed | **0** |
| Transaction boundaries changed | **0** |
| Final commit changed | **0** |
| Programs 223–227 changed | **0** |
| Recovery sources changed | **0** |

Substantive corrections:

```text
116, 158, 170, 174, 182, 191
```

Diagnostic-label-only changes:

```text
44, 52, 56, 60, 64, 68, 72, 76,
80, 84, 113, 117, 121, 192, 196, 202
```

All ten persistent mutation statements remain byte-identical to HF8:

```text
91, 96, 101, 106, 111, 136, 149, 190, 199, 200
```

## Detailed review files

- Complete 206-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_FULL_PROGRAM_REVIEW.csv`; referenced bytes not established here)
- Changed-statement ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_CHANGED_STATEMENT_LEDGER.csv`; referenced bytes not established here)
- Alias and aggregate reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_ALIAS_AND_AGGREGATE_RECONCILIATION.csv`; referenced bytes not established here)
- Unqualified-identifier scope review (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_UNQUALIFIED_IDENTIFIER_SCOPE_REVIEW.csv`; referenced bytes not established here)
- Aggregate-scope review (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_AGGREGATE_SCOPE_REVIEW.csv`; referenced bytes not established here)
- Nine-family hash-preimage parity review (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_HASH_PREIMAGE_PARITY_REVIEW.csv`; referenced bytes not established here)
- Post-failure tail review (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_POST_FAILURE_TAIL_REVIEW.csv`; referenced bytes not established here)
- Runtime-risk scan (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_RUNTIME_RISK_SCAN.csv`; referenced bytes not established here)
- Persistent-mutation inventory (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF9_PERSISTENT_MUTATION_INVENTORY.csv`; referenced bytes not established here)
- HF8-to-HF9 source patch (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_TO_HF9.patch`; referenced bytes not established here)
- HF8 pre-execution evidence reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_PRE_EXECUTION_EVIDENCE_RECONCILIATION_FOR_HF9.md`; referenced bytes not established here)

# Physical delivery ledger

## Continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF9.zip` |
| Bytes | **116,275** |
| SHA-256 | `93629a84144eb6cb83fc97a3d78dff817a704796c6e7080749ef36b3ef8fcbeb` |
| ZIP entries | **30** |
| Total uncompressed bytes | **833,610** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |
| Path mismatches | **0** |
| Size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Symbolic links | **0** |
| Manifest mismatches | **0** |

The ZIP sidecar contains exactly:

```text
93629a84144eb6cb83fc97a3d78dff817a704796c6e7080749ef36b3ef8fcbeb  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF9.zip
```

## Program 222 HF9

| Attribute | Physical result |
|---|---:|
| Filename | `222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql` |
| Bytes | **560,495** |
| SHA-256 | `3674c53f4bc46222a45db8d3afa75337af921b2492485ebd2745d77ada220cab` |
| Governed statements | **206** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

The SQL sidecar contains exactly:

```text
3674c53f4bc46222a45db8d3afa75337af921b2492485ebd2745d77ada220cab  222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql
```

## HF9 verifier

| Attribute | Physical result |
|---|---:|
| Filename | `222_HF9_pre_execution_state_source_graph_and_stage_boundary_verification.sql` |
| Bytes | **104,636** |
| SHA-256 | `c1a379f311c3b5ce5111d7ce868d48181a3ca81a09de4ca9997d6efaceb23d05` |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Final transaction action | **ROLLBACK** |
| Direct verifier versus packaged verifier | **IDENTICAL** |

The verifier sidecar contains exactly:

```text
c1a379f311c3b5ce5111d7ce868d48181a3ca81a09de4ca9997d6efaceb23d05  222_HF9_pre_execution_state_source_graph_and_stage_boundary_verification.sql
```

## Independent physical/static release gate

```text
Independent controls                   133 / 133 PASS
Blocking failures                        0

Governed statements                    206 / 206 PASS
Changed-statement ledger                22 / 22
Post-failure statements                 49 / 49 PASS
Aggregate-bearing statements            20 / 20 PASS
Hash-preimage families                    9 / 9 PASS
Persistent-mutation changes               0
Package/extraction mismatches              0
```

This validates the physical package, source delta, lexical and structural controls, aggregate scope, helper dependency order, hash-preimage parity, mutation preservation, attached operator evidence, extraction, and metadata. **It does not claim that Program 222 HF9 has executed successfully against your PostgreSQL database.**

The original WP5 R1 package remains the historical approved archive with its original SHA-256, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn12file0 | L3-L12] HF9 is a bounded live-execution continuation, not a replacement for that historical archive.

# Mandatory HF9 retry sequence

## 1. Preserve the failed HF8 evidence

Keep these separately and unchanged:

```text
complete HF8 console transcript
SQLSTATE 42702 error
client/process status
STOP action
ROLLBACK response
HF8 source-graph export
HF8 stage-boundary export
HF8 state-summary export
```

Do not overwrite those records with HF9 evidence.

## 2. Execute the HF9 verifier first

Execute the complete physical file:

```text
222_HF9_pre_execution_state_source_graph_and_stage_boundary_verification.sql
```

Require SHA-256:

```text
c1a379f311c3b5ce5111d7ce868d48181a3ca81a09de4ca9997d6efaceb23d05
```

It returns three result grids.

### Grid 1 — source graph

Require:

```text
rows                              19
distinct edge sequences           19
distinct edge codes               19
source registry rows               1 for every edge
target registry rows               1 for every edge
source gate status                PASS for every edge
source mismatch flag              false for every edge
target mismatch flag              false for every edge
edge status                       PASS for every edge
```

### Grid 2 — stage boundaries

Require:

```text
rows                              12
passing rows                      12
required controls                 70
physical controls                 70
duplicate controls                 0
missing controls                   0
non-PASS controls                  0
boundary violations                0
certification status              PASS for every node
```

### Grid 3 — state summary

Require:

```text
state_verification_status          PASS
predecessor_rows                   1
run_code                           M1_V0_2_BASELINE_BUILD
run_version                        1
run_status                         M2_11_ACCEPTED
contract_status                    ACCEPTED
installed_top_level_objects        21
policy_rows                        1
nonpolicy_rows                     0
m2_12_evidence_rows                0
g3_result_rows                     0
gate_rows                          1
exact_gate_rows                    1
policy_sequence_state              1|true
archive_sequence_state             1|false
registry_sequence_state            1|false
source_graph_rows                  19
source_graph_pass_rows             19
stage_boundary_rows                12
stage_boundary_pass_rows           12
stage_boundary_required_controls   70
stage_boundary_physical_controls   70
disposition                        READY_TO_EXECUTE_PROGRAM_222_HF9
```

Export each visible grid using:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

Recommended filenames:

```text
222_HF9_pre_execution_source_graph_detail.csv
222_HF9_pre_execution_stage_boundary_detail.csv
222_HF9_pre_execution_state_summary.csv
```

Any error, missing grid, count mismatch, non-PASS row, or export anomaly is a hard stop.

## 3. Execute Program 222 HF9 only

After the verifier passes exactly, execute:

```text
222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql
```

Require SHA-256:

```text
3674c53f4bc46222a45db8d3afa75337af921b2492485ebd2745d77ada220cab
```

Execution boundaries:

```text
one complete physical file
one invocation
first-error stop
no outer transaction
no Program 223 concatenation
no ad hoc SQL
no recovery execution
```

The governing execution prompt requires one complete physical file per invocation, no outer transaction, no concatenation, and an immediate stop on any error or ambiguity. [export reference: filecite | turn12file6 | L24-L45]

## 4. Required Program 222 result

Require exactly one row:

```text
generation_status             PASS
final_run_status              M2_12_GENERATED
final_contract_status         GENERATED
canonical_families            9
canonical_entities            134
generation_evidence_rows      24
application_consumption_rows  1500
operational_account_rows      59
strategy_scope_rows           24
policy_identity               1
archive_identity              1
registry_identity             1
owned_sequence_states         1|true;1|true;1|true
combined_set_hash             32 lowercase hexadecimal characters
disposition                   READY_FOR_PROGRAM_223
```

Export the visible primary row immediately using **Use fetched rows**.

## 5. Stop after Program 222

Even after an exact PASS:

```text
Program 223    HELD
Program 224    HELD
Program 225    HELD
Program 226    HELD
Program 227    HELD
Recoveries     UNAUTHORIZED
```

- Download the HF9 Programs 223–227 hold notice (historical reference: `sandbox:[session]/M2_12_PROGRAMS_223_227_HOLD_NOTICE_HF9.md`; referenced bytes not established here)

Program 223 remains held until the complete HF9 verifier output, Program 222 transcript, process status, exported primary result, persistent counts, 24 generation-evidence rows, lifecycle, governed hashes, and all three owned sequence states reconcile exactly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3c68d2db-a660-42d4-a8b1-4dc9489c9610"></a>
## Andrew / user · C085-M00073

C085-M00073 · 2026-08-11T09:33:23.047000-04:00 · active path

Preceding visible parent: [C085-M00072](part-04.md#m-2589f651-53dc-4cc4-9daf-cbe2dee86ed7)

<!-- BEGIN_SOURCE_MESSAGE -->
the pre-run for 222: failed: SQL Error [P0001]: ERROR: M2.12 Program 222 HF9 pre-execution verification failed: owned sequence state
  Detail: policy=1|true archive=1|true registry=1|false
  Hint: Stop. Do not reset any sequence or execute Program 221.
  Where: PL/pgSQL function inline_code_block line 68 at RAISE
  ERROR: M2.12 Program 222 HF9 pre-execution verification failed: owned sequence state
  Detail: policy=1|true archive=1|true registry=1|false
  Hint: Stop. Do not reset any sequence or execute Program 221.
  Where: PL/pgSQL function inline_code_block line 68 at RAISE
<!-- END_SOURCE_MESSAGE -->


<a id="m-c718d331-fbde-40dc-8a03-88281d9af459"></a>
## Assistant · C085-M00074

C085-M00074 · 2026-08-11T09:33:51.461375-04:00 · active path

Preceding visible parent: [C085-M00073](part-04.md#m-3c68d2db-a660-42d4-a8b1-4dc9489c9610)

<!-- BEGIN_SOURCE_MESSAGE -->
The verifier caught a real post-rollback sequence condition. I’m tracing the archive-sequence consumption, reconciling 222A/222B recovery boundaries, and reviewing Program 222 before the next bounded package.
<!-- END_SOURCE_MESSAGE -->


<a id="m-889f7600-63ba-4473-b10a-b46c37c956f6"></a>
## Assistant · C085-M00075

C085-M00075 · 2026-08-11T09:36:59.423668-04:00 · active path

Preceding visible parent: [C085-M00074](part-04.md#m-c718d331-fbde-40dc-8a03-88281d9af459)

<!-- BEGIN_SOURCE_MESSAGE -->
This matches the rollback-residue state Recovery 222A was designed for; I’m validating 222A end to end rather than weakening HF9 or resetting the sequence ad hoc.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b0761dc4-e423-4d56-a32b-f16b1e54d4d4"></a>
## Assistant · C085-M00076

C085-M00076 · 2026-08-11T09:56:32.683554-04:00 · active path

Preceding visible parent: [C085-M00075](part-04.md#m-889f7600-63ba-4473-b10a-b46c37c956f6)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Recovery 222A — Directed recovery package complete

This is **not another Program 222 source defect**. The HF9 verifier correctly detected a non-pristine owned-sequence state:

```text
policy sequence     1|true
archive sequence    1|true
registry sequence   1|false
```

The failed HF8 execution had reached the archive insert before failing later. Your rollback removed the archive row and all other transactional Program 222 changes, but the archive identity-sequence call remained. Changing HF9 to ignore that state—or manually resetting the sequence—would defeat the deterministic identity controls.

The exact state matches the approved **Recovery 222A** case:

```text
Program 222 failed before commit
No non-policy canonical state committed
No M2.12 generation evidence committed
No G3 result committed
Run remains M2_11_ACCEPTED
Archive sequence advanced
Registry sequence not advanced
```

The original approved Recovery 222A identity is 22,425 bytes with SHA-256 `8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627`. [export reference: filecite | turn14file11 | L40-L50] The governing live-execution authorization requires a state-specific authorization naming the exact recovery file and hash; it also prohibits manual sequence resets or speculative recovery selection. [export reference: filecite | turn14file5 | L44-L50]

**Program 222 HF9 remains unchanged.** Its source is still the current Program 222 retry source after recovery.

## Downloads

### Complete directed-recovery package

- Download M2_12_DIRECTED_RECOVERY_222A_R1.zip (historical reference: `sandbox:[session]/M2_12_DIRECTED_RECOVERY_222A_R1.zip`; referenced bytes not established here)
- Download the matching ZIP sidecar (historical reference: `sandbox:[session]/M2_12_DIRECTED_RECOVERY_222A_R1.zip.sha256`; referenced bytes not established here)

### Execute in this exact order

1. Download the 222A pre-recovery state verifier (historical reference: `sandbox:[session]/222A_pre_recovery_state_verification.sql`; referenced bytes not established here)
2. Download its SHA-256 sidecar (historical reference: `sandbox:[session]/222A_pre_recovery_state_verification.sql.sha256`; referenced bytes not established here)
3. Download the approved Recovery 222A SQL (historical reference: `sandbox:[session]/222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql`; referenced bytes not established here)
4. Download the Recovery 222A SQL sidecar (historical reference: `sandbox:[session]/222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql.sha256`; referenced bytes not established here)
5. Download the 222A post-recovery state verifier (historical reference: `sandbox:[session]/222A_post_recovery_state_verification.sql`; referenced bytes not established here)
6. Download its SHA-256 sidecar (historical reference: `sandbox:[session]/222A_post_recovery_state_verification.sql.sha256`; referenced bytes not established here)

### Physical validation

- Download the independent physical-readback report (historical reference: `sandbox:[session]/M2_12_222A_DIRECTED_RECOVERY_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the 45-control readback ledger (historical reference: `sandbox:[session]/M2_12_222A_DIRECTED_RECOVERY_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Download the machine-readable validation record (historical reference: `sandbox:[session]/M2_12_222A_DIRECTED_RECOVERY_INDEPENDENT_PHYSICAL_READBACK.json`; referenced bytes not established here)

## Physical delivery ledger

### Directed-recovery ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_DIRECTED_RECOVERY_222A_R1.zip` |
| Bytes | **27,258** |
| SHA-256 | `881344ff7342efa33acc1977920ab719bff7d37a44c10a5a4704abadcdb19b70` |
| ZIP entries | **19** |
| Total uncompressed bytes | **79,257** |
| ZIP CRC | **PASS** |
| Independent controls | **45/45 PASS** |
| Blocking failures | **0** |
| Path mismatches | **0** |
| Size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Manifest mismatches | **0** |

The ZIP sidecar contains:

```text
881344ff7342efa33acc1977920ab719bff7d37a44c10a5a4704abadcdb19b70  M2_12_DIRECTED_RECOVERY_222A_R1.zip
```

### Approved Recovery 222A

| Attribute | Physical result |
|---|---:|
| Bytes | **22,425** |
| SHA-256 | `8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627` |
| Approved-source byte comparison | **IDENTICAL** |
| Governed statements | **26/26 PASS** |
| Permitted sequence mutations | **2** |
| Persistent table DML | **0** |
| Persistent table DDL | **0** |

The only state-changing operations are:

```sql
setval(
  'msbf_ctl.m2_12_g3_bundle_archive_archive_id_seq',
  1,
  false
);

setval(
  'msbf_ctl.m2_12_g3_bundle_registry_registry_id_seq',
  1,
  false
);
```

Recovery 222A does not regenerate canonical rows, insert evidence, alter lifecycle, change the policy, or execute Program 222.

### Pre-recovery verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **13,883** |
| SHA-256 | `6df150b077c5f637006b3574d44a4c8181577bf9daafc3fd571b24ca0afdd5f2` |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Sequence mutations | **0** |
| Final action | **ROLLBACK** |

### Post-recovery verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **13,964** |
| SHA-256 | `bdeebfe84d67e41cf627079d018b864728ec4fc36874a2e90473bd94d754bc50` |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Sequence mutations | **0** |
| Final action | **ROLLBACK** |

## Mandatory execution sequence

### 0. Close the failed HF9-verifier transaction

The HF9 verifier raised an exception inside its transaction. If that same DBeaver session still shows an aborted transaction, execute only:

```sql
ROLLBACK;
```

Do not rerun Program 221 or manually call `setval`.

### 1. Run the pre-recovery verifier

Execute:

```text
222A_pre_recovery_state_verification.sql
```

Require SHA-256:

```text
6df150b077c5f637006b3574d44a4c8181577bf9daafc3fd571b24ca0afdd5f2
```

It must return exactly one row with:

```text
recovery_authorization_status  PASS
recovery_decision_code         RESTORE_FAILED_GENERATION_SEQUENCES
run_status                     M2_11_ACCEPTED
contract_status                ACCEPTED
installed_top_level_objects    21
policy_rows                    1
exact_policy_rows              1
nonpolicy_rows                 0
m2_12_evidence_rows            0
g3_result_rows                 0
policy_sequence_state          1|true
archive_sequence_state         1|true
registry_sequence_state        1|false
disposition                    AUTHORIZED_TO_EXECUTE_RECOVERY_222A
```

The verifier also proves exact sequence ownership, the exact installed policy and its hashes, zero archive and registry rows, zero Module 3 objects, and the complete Program 220 installation surface.

Any different value is a hard stop.

### 2. Execute approved Recovery 222A

Execute:

```text
222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql
```

Require SHA-256:

```text
8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627
```

Execution requirements:

```text
Complete physical file       one invocation
First-error stop             required
Outer transaction            prohibited
Program 222 concatenation    prohibited
Manual setval                prohibited
Other recovery               prohibited
```

Required visible result:

```text
recovery_program          222A
recovery_decision_code    RESTORE_FAILED_GENERATION_SEQUENCES
recovery_status           PASS
policy_sequence_state     1|true
archive_sequence_state    1|false
registry_sequence_state   1|false
disposition               PASS_RECOVERED
```

Export the result using:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

The approved 222A result helper drops at commit, so do not attempt to requery it afterward.

### 3. Run the post-recovery verifier

Execute:

```text
222A_post_recovery_state_verification.sql
```

Require SHA-256:

```text
bdeebfe84d67e41cf627079d018b864728ec4fc36874a2e90473bd94d754bc50
```

Required result:

```text
post_recovery_verification_status  PASS
recovery_decision_code             PRISTINE_PRE_PROGRAM_222_STATE_RESTORED
run_status                         M2_11_ACCEPTED
contract_status                    ACCEPTED
installed_top_level_objects        21
policy_rows                        1
exact_policy_rows                  1
nonpolicy_rows                     0
m2_12_evidence_rows                0
g3_result_rows                     0
policy_sequence_state              1|true
archive_sequence_state             1|false
registry_sequence_state            1|false
disposition                        READY_TO_RERUN_PROGRAM_222_HF9_VERIFIER
```

### 4. Return to the existing HF9 verifier

After the post-recovery verifier passes, rerun the existing:

```text
222_HF9_pre_execution_state_source_graph_and_stage_boundary_verification.sql
```

Its required SHA-256 remains:

```text
c1a379f311c3b5ce5111d7ce868d48181a3ca81a09de4ca9997d6efaceb23d05
```

It must again produce:

- **19/19 PASS** source edges;
- **12/12 PASS** stage boundaries;
- **70/70** physical controls;
- sequence states `1|true`, `1|false`, `1|false`;
- disposition `READY_TO_EXECUTE_PROGRAM_222_HF9`.

### 5. Execute Program 222 HF9 only after that exact PASS

Program 222 HF9 remains:

```text
222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql

SHA-256
3674c53f4bc46222a45db8d3afa75337af921b2492485ebd2745d77ada220cab
```

No HF10 source was created because the HF9 verifier is correct and HF9 itself has not yet been retried. The remedy is the approved 222A recovery, not weakening deterministic sequence enforcement.

## Current boundary

```text
Programs 220 and 221                  COMPLETE
Program 222 HF8 attempt               FAILED / ROLLED BACK
HF9 pre-execution verifier            CORRECTLY BLOCKED
Recovery decision                     222A EXACT MATCH
Recovery 222A package                 COMPLETE
Recovery 222A execution               NOT YET PERFORMED
Program 222 HF9                       RETAINED / HELD
Programs 223–227                      HELD
Recovery 222B                         NOT AUTHORIZED
M2.12 acceptance                      NOT CLAIMED
```

The historical approved WP5 package remains the governing archive with SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn14file0 | L3-L8]
<!-- END_SOURCE_MESSAGE -->


<a id="m-43a1d906-a445-4e87-b639-f5e26f88cf22"></a>
## Andrew / user · C085-M00077

C085-M00077 · 2026-08-11T10:22:35.909000-04:00 · active path

Preceding visible parent: [C085-M00076](part-04.md#m-b0761dc4-e423-4d56-a32b-f16b1e54d4d4)

**Editorial record note:** Attachment references: 222_HF9_pre_execution_state_summary_20260811.csv; 222_HF9_pre_execution_stage_boundary_detail_20260811.csv; 222_HF9_pre_execution_source_graph_detail_20260811.csv; 222A_post_recovery_state_verification_results_20260811.csv; 222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1_results_20260811.csv; 222A_pre_recovery_state_verification_results_20260811.csv; 222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9_results_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
222 results attached. perform program 223 bounded correction and review.
<!-- END_SOURCE_MESSAGE -->


<a id="m-aeeabd79-c0ab-4af1-a81b-a3e63aa88cd1"></a>
## Assistant · C085-M00078

C085-M00078 · 2026-08-11T10:23:04.999360-04:00 · active path

Preceding visible parent: [C085-M00077](part-04.md#m-43a1d906-a445-4e87-b639-f5e26f88cf22)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m reconciling the complete Program 222/222A evidence first, then reviewing all 128 Program 223 controls against HF9’s generated state before issuing a bounded continuation package.
<!-- END_SOURCE_MESSAGE -->


<a id="m-73813c58-1f08-4b4c-abb6-f062310a201b"></a>
## Assistant · C085-M00079

C085-M00079 · 2026-08-11T10:26:10.539310-04:00 · active path

Preceding visible parent: [C085-M00078](part-04.md#m-aeeabd79-c0ab-4af1-a81b-a3e63aa88cd1)

<!-- BEGIN_SOURCE_MESSAGE -->
Program 222’s final checkpoint is exact: 9 families, 134 entities, 24 generation-evidence rows, all identities at 1, and `M2_12_GENERATED / GENERATED`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c146fd24-6b5d-4ce4-9d44-7b1dedcac458"></a>
## Assistant · C085-M00080

C085-M00080 · 2026-08-11T10:35:17.939311-04:00 · active path

Preceding visible parent: [C085-M00079](part-04.md#m-73813c58-1f08-4b4c-abb6-f062310a201b)

<!-- BEGIN_SOURCE_MESSAGE -->
The directed 222A recovery trail also reconciles cleanly, confirming pristine sequence state was restored before the successful HF9 generation run.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6a9514fe-9275-45df-a368-81336c6c8eff"></a>
## Assistant · C085-M00081

C085-M00081 · 2026-08-11T11:02:23.722878-04:00 · active path

Preceding visible parent: [C085-M00080](part-04.md#m-c146fd24-6b5d-4ce4-9d44-7b1dedcac458)

<!-- BEGIN_SOURCE_MESSAGE -->
The Program 223 review exposed multiple correction families across source-edge, stage-boundary, hash-preimage, identity-keying, and JSONB aggregation logic. The corrected source is built; independent extraction validation is being rerun.
<!-- END_SOURCE_MESSAGE -->


<a id="m-707da6ed-8d8c-474c-9c20-e8a011e9ff64"></a>
## Assistant · C085-M00082

C085-M00082 · 2026-08-11T11:30:04.966937-04:00 · active path

Preceding visible parent: [C085-M00081](part-04.md#m-6a9514fe-9275-45df-a368-81336c6c8eff)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 223 HF10 — Bounded Correction and Review Complete

The supplied Program 222 evidence supports release of the bounded Program 223 correction:

- Recovery 222A was authorized against the exact failed-generation sequence signature, executed successfully, and restored the pristine pre-Program-222 sequence state. [export reference: filecite | turn15file0 | L9-L11] [export reference: filecite | turn15file1 | L20-L23] [export reference: filecite | turn15file2 | L33-L35]
- The subsequent HF9 pre-execution verification showed all 19 source edges and all 12 stage boundaries passing, with all 70 physical stage controls present. [export reference: filecite | turn16file0 | L10-L29] [export reference: filecite | turn16file1 | L40-L52]
- Program 222 HF9 then completed with `M2_12_GENERATED / GENERATED`, 9 canonical families, 134 canonical entities, 24 generation-evidence rows, all three identities equal to 1, all three owned sequences at `1|true`, combined-set hash `28d832719a63d5669a18016f15ba43fb`, and disposition `READY_FOR_PROGRAM_223`. [export reference: filecite | turn15file4 | L57-L59]

**Do not execute the original Program 223 R1 source. Program 223 HF10 is the only current Program 223 execution source.**

## Downloads

### Controlled continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF10.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF10.zip`; referenced bytes not established here)
- Download the matching ZIP SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF10.zip.sha256`; referenced bytes not established here)

The ZIP intentionally contains exactly one executable governed program—Program 223 HF10—and one read-only verifier. It contains no Program 224–227 SQL and no recovery SQL.

### Program 223 HF10

- Download Program 223 HF10 SQL (historical reference: `sandbox:[session]/223_msbf_m2_12_positive_validation_128_controls_v1_HF10.sql`; referenced bytes not established here)
- Download the Program 223 HF10 SQL sidecar (historical reference: `sandbox:[session]/223_msbf_m2_12_positive_validation_128_controls_v1_HF10.sql.sha256`; referenced bytes not established here)

### Mandatory pre-execution verifier

- Download the Program 223 HF10 generated-checkpoint verifier (historical reference: `sandbox:[session]/223_HF10_pre_execution_generated_checkpoint_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/223_HF10_pre_execution_generated_checkpoint_verification.sql.sha256`; referenced bytes not established here)

### Independent readback and operating records

- Independent physical/static readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- 274-control independent readback ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Machine-readable independent readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_INDEPENDENT_PHYSICAL_READBACK.json`; referenced bytes not established here)
- Program 223 HF10 operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Program 223 HF10 source authority (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_SOURCE_AUTHORITY.md`; referenced bytes not established here)
- Program 223 HF10 validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_VALIDATION_REPORT.md`; referenced bytes not established here)

### Detailed source-review records

- 128-row positive-control catalog (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_POSITIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Complete 128-control review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_FULL_CONTROL_REVIEW.csv`; referenced bytes not established here)
- Complete 170-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_FULL_STATEMENT_REVIEW.csv`; referenced bytes not established here)
- 30-control change ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_CHANGED_CONTROL_LEDGER.csv`; referenced bytes not established here)
- 19-edge source-graph reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_SOURCE_EDGE_RECONCILIATION.csv`; referenced bytes not established here)
- 12-node stage-boundary reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_STAGE_BOUNDARY_SOURCE_RECONCILIATION.csv`; referenced bytes not established here)
- 13-component reproduction review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_COMPONENT_REPRODUCTION_REVIEW.csv`; referenced bytes not established here)
- Nine-family hash-preimage review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_HASH_PREIMAGE_PARITY_REVIEW.csv`; referenced bytes not established here)
- Persistent-mutation inventory (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_PERSISTENT_MUTATION_INVENTORY.csv`; referenced bytes not established here)

## Governing Program 223 contract

The approved WP3 authority requires Program 223 to contain exactly 128 positive controls, independently reconstruct them from persisted state, avoid dependence on Program 222 transaction-local helpers, persist positive evidence only after 128 of 128 controls pass, transition only to `M2_12_VALIDATED`, and preserve canonical business and hash fields. [export reference: filecite | turn14file12 | L29-L46]

The original approved Program 223 identity was:

```text
Bytes
713,276

SHA-256
ccb301785dc8a2a80126bc2d70c7d8dfd0db91b2d51b008fb733745ae26d7158
```

That source remains part of the historical approved WP3 archive, but it is superseded for the next Program 223 execution attempt. The approved WP3 signoff records that original identity and the exact 128-positive/20-negative authority. [export reference: filecite | turn14file9 | L32-L54]

# Bounded corrections

The review covered all 128 control definitions and all 170 top-level SQL statements. It did not stop after locating one prospective issue.

## 1. Exact source and registry identity scope

Five controls were corrected:

```text
003  ACCEPTED_M2_11_SOURCE_ANCHORS
008  G3_LATEST_IDENTITY
009  G3_ARCHIVE_IDENTITY_AND_GUARD
110  ACCEPTED_M2_11_REGISTRY_ANCHORS
126  ACCEPTED_SOURCE_HASH_CHAIN
```

The corrected source now binds observations to the complete governed identity, including the applicable:

- `module1_run_id`;
- contract or bundle code;
- contract or bundle version;
- accepted or generated status;
- source gate identity;
- exact registry and hash fields.

The M1.3 application source hash is extracted from the governed JSON member:

```sql
(agr.observed_value::jsonb ->> 'application_set_hash')::text
```

The invalid whole-document comparison:

```sql
agr.observed_value::text
```

has zero residual executable occurrences.

## 2. Complete physical stage-boundary reconstruction

All 12 physical stage controls were corrected:

```text
012, 014, 016, 018, 020, 022,
024, 026, 028, 030, 032, 034
```

The resulting physical authority covers:

```text
12 certification nodes
70 required controls
70 physical controls
0 duplicate controls
0 missing controls
0 non-PASS controls
0 boundary violations
```

Two nonstandard sources are handled explicitly:

- Node 1, `M1_17_G2_FOUNDATION`, reconstructs its three controls from `msbf_ctl.m1_17_end_to_end_evidence_snapshot`.
- Node 4, `M2_3_FINAL_DECISION`, combines five `run_evidence` controls with an independently reconstructed physical `M2_3_POLICY_BOUNDARY` marker.

The remaining ten nodes use their governed accepted `run_evidence` sources.

## 3. All 13 component-lineage controls

The 13 lineage controls were corrected:

```text
036, 038, 040, 042, 044, 046, 048,
050, 052, 054, 056, 058, 060
```

Their business-key columns are stored as `jsonb`. PostgreSQL does not supply the intended aggregate behavior for:

```sql
min(jsonb)
```

followed by a later cast.

HF10 instead casts each value inside the aggregate:

```sql
min(latest_business_key_columns::text)
min(archive_business_key_columns::text)
```

Results:

```text
Correct latest casts            13
Correct archive casts           13
Residual min(jsonb)::text        0
Component mappings reconciled   13 / 13
```

## 4. Deterministic evidence-family hash preimages

Both the pre-write and post-write deterministic reconstruction passes now use the same evidence-certification preimages as the successfully executed Program 222 HF9.

The governed entity key is:

```text
node_sequence | evidence_family_sequence
```

The governed family set-hash preimage is:

```text
node_sequence | evidence_family_sequence | row_hash
```

The incorrect inclusion of `evidence_family_code` in either preimage has zero residual occurrences.

All nine canonical families were independently reviewed:

```text
POLICY
STAGE_CERTIFICATION
CONTRACT_COMPONENT
EVIDENCE_CERTIFICATION
CONTRACT_REPRODUCTION
CAPABILITY_COVERAGE
LATEST
ARCHIVE
REGISTRY
```

Result:

```text
Pre-write reconstruction    9 / 9 PASS
Post-write reconstruction   9 / 9 PASS
Preimage mismatches          0
```

## 5. Generated-checkpoint hardening

Before evaluating any of the 128 controls, HF10 now requires the complete persisted Program 222 checkpoint:

```text
Run lifecycle                        M2_12_GENERATED
G3 registry lifecycle                GENERATED
Canonical families                   9
Canonical entities                   134
Generation evidence                 24 / 24 PASS
Source graph                         19 / 19 PASS
Stage boundaries                     12 / 12 PASS
Physical stage controls              70 / 70
Positive evidence rows               0
Negative evidence rows               0
Acceptance evidence rows             0
G3 gate rows                         0
Policy sequence                      1|true
Archive sequence                     1|true
Registry sequence                    1|true
Combined-set hash                    exact persisted HF9 value
```

Any discrepancy blocks Program 223 before its 128-control evaluation begins.

## 6. Result exportability

The two final Program 223 result helpers use:

```sql
ON COMMIT PRESERVE ROWS
```

Therefore, after a successful commit they remain available in the **same originating database session**.

The preferred evidence method remains DBeaver’s:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

This prevents the export process from re-executing the query or opening a connection that cannot see session-local temporary relations.

# Mutation boundary

Program 223 HF10 contains exactly three authorized persistent mutation operations:

| Operation | Target | Authorized effect |
|---|---|---|
| `INSERT` | `msbf_ctl.run_evidence` | Persist exactly 128 positive PASS evidence rows after the hard 128/128 gate |
| `UPDATE` | `msbf_ctl.m2_12_g3_bundle_registry` | Transition the single G3 registry row from `GENERATED` to `VALIDATED` |
| `UPDATE` | `msbf_ctl.run_registry` | Transition the governed run from `M2_12_GENERATED` to `M2_12_VALIDATED` |

It contains:

```text
Persistent DELETE operations             0
Persistent DDL operations                0
Canonical business/hash mutations        0
Owned sequence mutations                 0
Program 224–227 source changes            0
Recovery-source changes                   0
```

Both lifecycle updates occur only after the 128-positive-evidence persistence gate, and the complete deterministic hash and sequence checkpoint is reconstructed again after those writes.

# Physical delivery ledger

## Canonical continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF10.zip` |
| Bytes | **168,627** |
| SHA-256 | `d3a3cdfee6b2167c7b148d17c51a39ac307b25c5415113bb3776d034852d65e6` |
| ZIP entries | **39** |
| Total uncompressed bytes | **1,485,037** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |
| Independent controls | **274/274 PASS** |
| Blocking failures | **0** |

The sidecar contains exactly:

```text
d3a3cdfee6b2167c7b148d17c51a39ac307b25c5415113bb3776d034852d65e6  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF10.zip
```

## Program 223 HF10

| Attribute | Physical result |
|---|---:|
| Bytes | **768,740** |
| SHA-256 | `463ad6019d414db4f1dfc036834c242d9673b00b516396285eef0b5714b56805` |
| Top-level statements | **170** |
| Positive-control definitions | **128** |
| Changed control definitions | **30** |
| Definition-identical controls | **98** |
| Direct versus packaged bytes | **IDENTICAL** |

The source sidecar contains exactly:

```text
463ad6019d414db4f1dfc036834c242d9673b00b516396285eef0b5714b56805  223_msbf_m2_12_positive_validation_128_controls_v1_HF10.sql
```

## Read-only verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **139,828** |
| SHA-256 | `b0e5a7f8d7bee6a1a477592f00321cb5fd007e53a80fe4cab89e158b6bc3d975` |
| Top-level statements | **25** |
| Result grids | **5** |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Final transaction action | **ROLLBACK** |
| Direct versus packaged bytes | **IDENTICAL** |

The verifier sidecar contains exactly:

```text
b0e5a7f8d7bee6a1a477592f00321cb5fd007e53a80fe4cab89e158b6bc3d975  223_HF10_pre_execution_generated_checkpoint_verification.sql
```

## Catalog and review artifacts

| Artifact | Rows | Bytes | SHA-256 |
|---|---:|---:|---|
| Positive-control catalog | **128** | **136,664** | `a2264486562e37c653251c66532faf91fe371549f9bb824f65cc6f084ca8cd97` |
| Full control review | **128** | **47,167** | `97a72f53e1438fe9e03e538fc16437da532aa5413569f2781bf9469eea83d667` |
| Full statement review | **170** | **17,918** | `aa2966ae8a4f1e4a7a193e49eeda92a868066836834bdc4cd4ec40780e90d1be` |
| Changed-control ledger | **30** | **12,359** | `f247ffe6d79479b1881aa4853989293f5686794054ef054c1a064c9f274984db` |
| Independent control ledger | **274** | **93,951** | `c8cbf71518d21352ced901c79672766856e8775dd333b2bbca3a98728849c22d` |

Independent package reconciliation produced:

```text
Path mismatches                    0
Byte-size mismatches               0
SHA-256 mismatches                 0
Duplicate ZIP paths                0
Case-insensitive duplicate paths   0
Unsafe paths                       0
Symbolic links                     0
MANIFEST.csv mismatches            0
manifest.json mismatches           0
SHA256SUMS.txt mismatches           0
PACKAGE_INVENTORY.csv mismatches   0
```

# Mandatory execution sequence

## 1. Preserve Program 222 evidence

Retain the complete Program 222 HF9 transcript and client status together with:

```text
222A pre-recovery result
222A recovery result
222A post-recovery result
HF9 source-graph result
HF9 stage-boundary result
HF9 state summary
HF9 Program 222 primary result
```

The supplied CSVs establish the checkpoint used for this source construction. They do not replace the eventual independent audit of the complete console transcript and process status.

## 2. Execute the HF10 verifier first

Execute the complete physical file:

```text
223_HF10_pre_execution_generated_checkpoint_verification.sql
```

Require SHA-256:

```text
b0e5a7f8d7bee6a1a477592f00321cb5fd007e53a80fe4cab89e158b6bc3d975
```

It must produce five result grids.

### Grid 1 — source graph

Require:

```text
Rows                              19
Distinct edge sequences           19
Distinct edge codes               19
Source row count                   1 for every edge
Target row count                   1 for every edge
Source gate status                PASS for every edge
Source hash mismatch              false for every edge
Target hash mismatch              false for every edge
Edge status                       PASS for every edge
```

### Grid 2 — stage boundaries

Require:

```text
Rows                              12
Passing nodes                     12
Required controls                 70
Physical controls                 70
Duplicate controls                 0
Missing controls                   0
Non-PASS controls                  0
Boundary violations                0
Certification status              PASS for every node
```

### Grid 3 — canonical families

Require nine PASS rows with this row-count vector:

```text
1, 12, 13, 72, 13, 20, 1, 1, 1
```

For every family:

```text
row_hash_mismatch_count      0
set_hash_mismatch_count      0
family_status                PASS
```

### Grid 4 — generation evidence

Require:

```text
Rows                          24
Distinct evidence codes       24
PASS rows                     24
Value mismatches               0
Evidence status               PASS for every row
```

### Grid 5 — state summary

Require:

```text
state_verification_status          PASS
run_code                           M1_V0_2_BASELINE_BUILD
run_version                        1
run_status                         M2_12_GENERATED
contract_status                    GENERATED
canonical_entities                 134
canonical_families                 9
canonical_families_pass            9
deterministic_mismatches            0
generation_evidence_rows           24
generation_evidence_pass_rows      24
source_graph_rows                  19
source_graph_pass_rows             19
stage_boundary_rows                12
stage_boundary_pass_rows           12
stage_boundary_required_controls   70
stage_boundary_physical_controls   70
positive_rows                       0
negative_rows                       0
acceptance_rows                     0
g3_gate_rows                        0
policy_sequence_state              1|true
archive_sequence_state             1|true
registry_sequence_state            1|true
combined_set_hash                  28d832719a63d5669a18016f15ba43fb
disposition                        READY_TO_EXECUTE_PROGRAM_223_HF10
```

Export all five grids immediately with fetched rows.

Recommended names:

```text
223_HF10_pre_execution_source_graph_detail.csv
223_HF10_pre_execution_stage_boundary_detail.csv
223_HF10_pre_execution_canonical_family_detail.csv
223_HF10_pre_execution_generation_evidence_detail.csv
223_HF10_pre_execution_state_summary.csv
```

Any error, missing grid, non-PASS row, count mismatch, hash mismatch, sequence mismatch, or export anomaly is a hard stop.

## 3. Execute Program 223 HF10 only

After the verifier passes exactly, execute:

```text
223_msbf_m2_12_positive_validation_128_controls_v1_HF10.sql
```

Require SHA-256:

```text
463ad6019d414db4f1dfc036834c242d9673b00b516396285eef0b5714b56805
```

Execution boundaries:

```text
One complete physical file
One invocation
First-error stop
No outer transaction
No Program 224 concatenation
No ad hoc SQL
No recovery execution
```

The governing authorization requires the exact normal order, makes every later program conditional on the preceding checkpoint, and requires an immediate stop on any error or ambiguity. [export reference: filecite | turn14file5 | L34-L50]

## 4. Required Program 223 outputs

### Grid 1 — persistence result

Require exactly one row:

```text
run_status             M2_12_VALIDATED
contract_status        VALIDATED
positive_pass          128
positive_codes         128
negative_rows          0
acceptance_rows        0
gate_rows              0
hash_compare_rows      1
hash_exact_rows        1
persistence_status     PASS
```

### Grid 2 — positive-control detail

Require:

```text
Rows                         128
Control sequences            1–128
Distinct evidence codes      128
Status                       PASS for every row
Mismatch count               0 for every row
```

Export both visible grids immediately:

```text
223_HF10_persistence_result.csv
223_HF10_positive_control_detail.csv
```

## 5. Stop after Program 223

Even after an exact PASS:

```text
Program 224        HELD
Program 225        HELD
Program 226        HELD
Program 227        HELD
Recovery 223A      UNAUTHORIZED
M2.12 acceptance   NOT CLAIMED
```

Do not execute Program 224 until the verifier outputs, complete Program 223 transcript, client/process status, persistence result, all 128 detail rows, lifecycle, hashes, evidence counts, and sequence state have reconciled exactly.

The historical WP5 package remains the approved archive with SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn14file0 | L3-L8] HF10 is a bounded continuation after completed Program 222, not a replacement for that historical archive.
<!-- END_SOURCE_MESSAGE -->


<a id="m-208dfd80-b714-4f5e-9153-3620b7fae8bc"></a>
## Andrew / user · C085-M00083

C085-M00083 · 2026-08-11T11:51:03.469000-04:00 · active path

Preceding visible parent: [C085-M00082](part-04.md#m-707da6ed-8d8c-474c-9c20-e8a011e9ff64)

**Editorial record note:** Attachment references: 223_HF10_pre_execution_generation_evidence_detail_20260811.csv; 223_HF10_pre_execution_canonical_family_detail_20260811.csv; 223_HF10_pre_execution_stage_boundary_detail_20260811.csv; 223_HF10_pre_execution_source_graph_detail_20260811.csv; 223_HF10_pre_execution_state_summary_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 223: SQL Error [42601]: ERROR: syntax error at or near "\"
  Position: 1398
  ERROR: syntax error at or near "\"
  Position: 1398            correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. when correcting error, do not correct this error and stop, review the rest of program 223 for additional, similar/noticeable errors. 223 pre-run evidence attached.      
<!-- END_SOURCE_MESSAGE -->


<a id="m-73ad723b-720c-4dbf-b570-376bc6d8ceeb"></a>
## Assistant · C085-M00084

C085-M00084 · 2026-08-11T11:51:32.388859-04:00 · active path

Preceding visible parent: [C085-M00083](part-04.md#m-208dfd80-b714-4f5e-9153-3620b7fae8bc)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m reconciling the five pre-run grids first, then isolating the parser defect and scanning all 128 controls plus the post-failure tail for related syntax issues.
<!-- END_SOURCE_MESSAGE -->


<a id="m-290b86f2-4960-46b2-b879-f1dff0bec9ea"></a>
## Assistant · C085-M00085

C085-M00085 · 2026-08-11T11:54:38.231431-04:00 · active path

Preceding visible parent: [C085-M00084](part-04.md#m-73ad723b-720c-4dbf-b570-376bc6d8ceeb)

<!-- BEGIN_SOURCE_MESSAGE -->
The immediate defect is confirmed: HF10 introduced a psql-only `\set ON_ERROR_STOP on` line that DBeaver sent to PostgreSQL as SQL; I’m removing it.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0f95b646-484f-4fca-8c68-f4d90979f2b3"></a>
## Assistant · C085-M00086

C085-M00086 · 2026-08-11T12:03:45.294076-04:00 · active path

Preceding visible parent: [C085-M00085](part-04.md#m-290b86f2-4960-46b2-b879-f1dff0bec9ea)

<!-- BEGIN_SOURCE_MESSAGE -->
Because the parser failed before `BEGIN`, no Program 223 mutation was reached; I’m continuing the full 170-statement review rather than issuing only a one-line fix.
<!-- END_SOURCE_MESSAGE -->
