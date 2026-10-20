# WP3 Build Protocol

Part 05 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-04.md)
[Next part](part-06.md)

<a id="m-9ec7a2cc-7ec9-4679-a5ad-b51775877127"></a>
## Assistant · C085-M00087

C085-M00087 · 2026-08-11T12:22:52.283173-04:00 · active path

Preceding visible parent: [C085-M00086](part-04.md#m-0f95b646-484f-4fca-8c68-f4d90979f2b3)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 223 HF11 — Hotfix Complete

Your stop-and-rollback response was correct. **Do not rerun Program 223 HF10.** Program 223 HF11 is now the only current Program 223 execution source.

## Downloads

### Controlled continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF11.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF11.zip`; referenced bytes not established here)
- Download the matching ZIP sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF11.zip.sha256`; referenced bytes not established here)

The package contains exactly one executable governed program—Program 223 HF11—and one read-only pre-execution verifier. It contains no executable Program 224–227 or recovery SQL.

### Program 223 HF11

- Download Program 223 HF11 SQL (historical reference: `sandbox:[session]/223_msbf_m2_12_positive_validation_128_controls_v1_HF11.sql`; referenced bytes not established here)
- Download the Program 223 HF11 SQL sidecar (historical reference: `sandbox:[session]/223_msbf_m2_12_positive_validation_128_controls_v1_HF11.sql.sha256`; referenced bytes not established here)

### Mandatory pre-execution verifier

- Download the Program 223 HF11 generated-checkpoint verifier (historical reference: `sandbox:[session]/223_HF11_pre_execution_generated_checkpoint_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/223_HF11_pre_execution_generated_checkpoint_verification.sql.sha256`; referenced bytes not established here)

### Principal review records

- Operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_VALIDATION_REPORT.md`; referenced bytes not established here)
- Independent physical-readback report (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- 417-control independent readback ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Machine-readable independent readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_INDEPENDENT_PHYSICAL_READBACK.json`; referenced bytes not established here)
- Complete 170-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_FULL_STATEMENT_REVIEW.csv`; referenced bytes not established here)
- Complete 128-control review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_FULL_CONTROL_REVIEW.csv`; referenced bytes not established here)
- Client/parser compatibility audit (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_CLIENT_PARSER_COMPATIBILITY_AUDIT.csv`; referenced bytes not established here)
- Known-defect-pattern scan (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_KNOWN_DEFECT_PATTERN_SCAN.csv`; referenced bytes not established here)
- HF10-to-HF11 source patch (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF10_TO_HF11.patch`; referenced bytes not established here)
- Programs 224–227 hold notice (historical reference: `sandbox:[session]/M2_12_PROGRAMS_224_227_HOLD_NOTICE_HF11.md`; referenced bytes not established here)

# Root cause

HF10 contained this line before its transaction began:

```text
\set ON_ERROR_STOP on
BEGIN;
```

`\set` is a **psql client meta-command**, not PostgreSQL SQL. DBeaver submitted it to the PostgreSQL server, which encountered the backslash and raised:

```text
SQLSTATE 42601
syntax error at or near "\"
```

The physical source contained exactly one backslash and exactly one client meta-command, both on that line.

Because the failure occurred **before `BEGIN;`**, the failed HF10 attempt could not have:

- created a Program 223 temporary relation;
- evaluated any positive control;
- inserted positive evidence;
- changed either lifecycle;
- altered canonical state;
- advanced an owned sequence.

Your `ROLLBACK` was conservative and correct, but there was no Program 223 transaction to undo. **Recovery 223A is neither indicated nor authorized.**

# HF11 correction

HF11 removes the psql-only command completely. Its executable opening is now pure PostgreSQL SQL:

```sql
-- Configure first-error-stop behavior in the database client;
-- this file contains no client meta-commands.
BEGIN;
```

First-error-stop behavior remains mandatory, but it must be configured in DBeaver or the invoking client rather than embedded as a backslash command in the governed SQL source.

HF11 contains:

```text
psql meta-command lines             0
executable backslashes              0
client variable references          0
statement-splitting errors          0
unbalanced quotes/comments/tags     0
```

# Attached pre-run evidence reconciliation

The five attached verifier exports establish the exact committed Program 222 checkpoint immediately before the HF10 parser failure:

- All **19 source edges** have one accepted-source row, one target row, matching expected/source/target hashes, false mismatch flags, and `PASS`. [export reference: filecite | turn18file3 | L88-L107]
- All **12 stage boundaries** pass with their required physical controls and zero duplicates, missing controls, non-PASS controls, or boundary violations. [export reference: filecite | turn18file2 | L65-L77]
- All **nine canonical families** reproduce their expected cardinalities and stored set hashes with zero row-hash or set-hash mismatches. [export reference: filecite | turn18file1 | L45-L54]
- All **24 generation-evidence rows** have exact expected and actual values, false mismatch flags, and `PASS`. [export reference: filecite | turn18file0 | L10-L34]
- The state summary shows `M2_12_GENERATED / GENERATED`, 134 canonical entities, 9/9 families passing, 24/24 generation-evidence rows passing, 19/19 source edges, 12/12 stage boundaries, 70/70 physical controls, no validation or acceptance evidence, all three sequences at `1|true`, and combined hash `28d832719a63d5669a18016f15ba43fb`. [export reference: filecite | turn18file4 | L118-L119]

The HF10 parser error occurred before any state-changing SQL, but the HF11 verifier must still be rerun to provide a fresh physical checkpoint immediately before the retry.

# Broader Program 223 review

The review did not stop after removing the backslash.

## Source-level scope

| Review area | HF11 result |
|---|---:|
| Top-level statements reviewed | **170/170 PASS** |
| Positive-control definitions reviewed | **128/128 PASS** |
| Control sequence coverage | **1–128 exact** |
| Distinct control codes | **128** |
| Control-definition changes from HF10 | **0** |
| PL/pgSQL blocks | **8/8 balanced** |
| Unscheduled temporary dependencies | **0** |
| Pre-create temporary references | **0** |
| Persistent mutation operations | **3 exact** |
| Persistent DELETE operations | **0** |
| Persistent DDL operations | **0** |
| Client/parser meta-command findings | **0** |
| Independent physical controls | **417/417 PASS** |

The WP3 authority requires exactly 128 persisted-state positive controls, persistence only after 128/128 PASS, a transition only to `M2_12_VALIDATED`, and preservation of canonical business and hash state. [export reference: filecite | turn17file12 | L31-L46] HF11 preserves those requirements.

## Source delta from HF10

Exactly **11 of 170 statement byte ranges** changed:

| Change class | Statements |
|---|---:|
| Substantive client-compatibility correction | **1** |
| Revision-label or diagnostic-message updates only | **10** |
| Unchanged statements | **159** |
| Changed positive-control definitions | **0** |
| Changed persistent mutations | **0** |

The one substantive change is Statement 1: removal of the psql-only meta-command and replacement with a non-executable operator comment.

The other ten changed statements contain only HF10-to-HF11 revision labels, dollar-tag labels, comments, or diagnostic messages. Their query logic and mutation behavior are unchanged.

## Additional defect classes reviewed

The source-wide scan found zero residual occurrences of:

```text
psql/client meta-commands
executable backslashes
raw M1.3 whole-JSON hash extraction
jsonb aggregate followed by text cast
incorrect evidence-family hash preimage
unquoted governed lifecycle literals
uncast pg_attribute name arrays
correlated aggregate/outer-OID pattern
residual HF10 revision labels
```

No additional Program 223 source change was indicated by the expanded review.

# Mutation boundary

HF11 retains exactly the three authorized persistent operations:

| Operation | Target | Effect |
|---|---|---|
| `INSERT` | `msbf_ctl.run_evidence` | Persist exactly 128 positive PASS rows after the hard 128/128 gate |
| `UPDATE` | `msbf_ctl.m2_12_g3_bundle_registry` | Transition `GENERATED → VALIDATED` |
| `UPDATE` | `msbf_ctl.run_registry` | Transition `M2_12_GENERATED → M2_12_VALIDATED` |

There is no persistent DELETE, persistent DDL, canonical business/hash update, or owned-sequence mutation.

# Physical delivery ledger

## Canonical continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF11.zip` |
| Bytes | **161,869** |
| SHA-256 | `1a69f61a984b44f30c667d0f639202eb4e642cc6d803870257a28ce13d4bf1ba` |
| ZIP entries | **47** |
| Total uncompressed bytes | **1,233,632** |
| ZIP CRC | **PASS** |
| Complete fresh extraction | **PASS** |
| Path mismatches | **0** |
| Byte-size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Manifest mismatches | **0** |
| JSON-manifest mismatches | **0** |
| `SHA256SUMS.txt` mismatches | **0** |
| Package-inventory mismatches | **0** |

The sidecar contains exactly:

```text
1a69f61a984b44f30c667d0f639202eb4e642cc6d803870257a28ce13d4bf1ba  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF11.zip
```

## Program 223 HF11

| Attribute | Physical result |
|---|---:|
| Filename | `223_msbf_m2_12_positive_validation_128_controls_v1_HF11.sql` |
| Bytes | **768,957** |
| SHA-256 | `0458f4d4b3096df2289222dc2d596c41e06d20b402db5168cf6151173a7f1c41` |
| Top-level statements | **170** |
| Positive controls | **128** |
| Definition changes from HF10 | **0** |
| Executable backslashes | **0** |
| Client meta-commands | **0** |

Its sidecar contains:

```text
0458f4d4b3096df2289222dc2d596c41e06d20b402db5168cf6151173a7f1c41  223_msbf_m2_12_positive_validation_128_controls_v1_HF11.sql
```

## HF11 verifier

| Attribute | Physical result |
|---|---:|
| Filename | `223_HF11_pre_execution_generated_checkpoint_verification.sql` |
| Bytes | **139,930** |
| SHA-256 | `adbdeda058adfba63fba6dec42bf90c8961d933c02296530bd5bf36011b9cc35` |
| Top-level statements | **25** |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Result grids | **5** |
| Final transaction action | **ROLLBACK** |

Its sidecar contains:

```text
adbdeda058adfba63fba6dec42bf90c8961d933c02296530bd5bf36011b9cc35  223_HF11_pre_execution_generated_checkpoint_verification.sql
```

# Mandatory retry sequence

## 1. Preserve the HF10 failure evidence

Keep these records unchanged:

```text
HF10 console transcript
SQLSTATE 42601 error
client/process status
STOP action
ROLLBACK response
five HF10 pre-execution verifier exports
```

Do not overwrite them with HF11 evidence.

## 2. Execute the HF11 verifier

Execute the complete physical file:

```text
223_HF11_pre_execution_generated_checkpoint_verification.sql
```

Require SHA-256:

```text
adbdeda058adfba63fba6dec42bf90c8961d933c02296530bd5bf36011b9cc35
```

It must produce five result grids:

1. **19 source edges**, all PASS.
2. **12 stage boundaries**, all PASS, 70/70 controls.
3. **Nine canonical families**, row vector `1,12,13,72,13,20,1,1,1`, zero mismatches.
4. **24 generation-evidence rows**, all PASS and exact.
5. One state-summary row with:

```text
run_status                         M2_12_GENERATED
contract_status                    GENERATED
canonical_entities                134
canonical_families                  9
canonical_families_pass             9
deterministic_mismatches             0
generation_evidence_rows            24
generation_evidence_pass_rows       24
source_graph_rows                   19
source_graph_pass_rows              19
stage_boundary_rows                 12
stage_boundary_pass_rows            12
stage_boundary_required_controls    70
stage_boundary_physical_controls    70
positive_rows                        0
negative_rows                        0
acceptance_rows                      0
g3_gate_rows                         0
policy_sequence_state               1|true
archive_sequence_state              1|true
registry_sequence_state             1|true
combined_set_hash                   28d832719a63d5669a18016f15ba43fb
disposition                         READY_TO_EXECUTE_PROGRAM_223_HF11
```

Export all five grids using:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

## 3. Execute Program 223 HF11 only

After the verifier passes exactly, execute:

```text
223_msbf_m2_12_positive_validation_128_controls_v1_HF11.sql
```

Require SHA-256:

```text
0458f4d4b3096df2289222dc2d596c41e06d20b402db5168cf6151173a7f1c41
```

Execution boundaries:

```text
Complete physical file       one invocation
First-error stop             configured in DBeaver/client
Outer transaction            prohibited
Program 224 concatenation    prohibited
Ad hoc SQL                   prohibited
Recovery 223A                prohibited
```

The live-execution authority requires exact sequential execution, an immediate stop on any error, and no rerun or ad hoc patching after an anomaly. [export reference: filecite | turn17file5 | L36-L50]

## 4. Required Program 223 outputs

### Grid 1 — persistence result

Require exactly one row:

```text
run_status            M2_12_VALIDATED
contract_status       VALIDATED
positive_pass         128
positive_codes        128
negative_rows         0
acceptance_rows       0
gate_rows             0
hash_compare_rows     1
hash_exact_rows       1
persistence_status    PASS
```

### Grid 2 — positive-control detail

Require:

```text
rows                   128
control sequences      1–128
distinct codes         128
status                 PASS for every row
mismatch count         0 for every row
```

Export both grids immediately using fetched rows.

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

The historical WP5 archive remains the approved baseline package with SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn17file0 | L3-L12] HF11 is a bounded live-execution continuation and does not replace that historical archive.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a1eb4cd8-1c14-4363-917d-d20557099819"></a>
## Andrew / user · C085-M00088

C085-M00088 · 2026-08-11T12:37:20.105000-04:00 · active path

Preceding visible parent: [C085-M00087](part-05.md#m-9ec7a2cc-7ec9-4679-a5ad-b51775877127)

**Editorial record note:** Attachment references: 223_HF11_pre_execution_stage_boundary_detail_20260811.csv; 223_HF11_pre_execution_canonical_family_detail_20260811.csv; 223_HF11_pre_execution_generation_evidence_detail_20260811.csv; 223_HF11_pre_execution_state_summary_20260811.csv; 223_HF11_pre_execution_source_graph_detail_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
another program 223 error: SQL Error [P0001]: ERROR: M2.12 Program 223 HF11 positive validation did not achieve 128/128 PASS
  Detail: rows=128 codes=128 failures=2 family_mismatches=0
  Where: PL/pgSQL function inline_code_block line 25 at RAISE
  ERROR: M2.12 Program 223 HF11 positive validation did not achieve 128/128 PASS
  Detail: rows=128 codes=128 failures=2 family_mismatches=0
  Where: PL/pgSQL function inline_code_block line 25 at RAISE               correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. when correcting error, do not correct this error and stop, review the rest of program 223 for additional, similar/noticeable errors. 223 pre-run evidence attached.        
<!-- END_SOURCE_MESSAGE -->


<a id="m-5a0ec94c-d60f-4bad-af81-80515cc3a6a1"></a>
## Assistant · C085-M00089

C085-M00089 · 2026-08-11T12:37:48.723835-04:00 · active path

Preceding visible parent: [C085-M00088](part-05.md#m-a1eb4cd8-1c14-4363-917d-d20557099819)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll trace the two HF11 control failures, patch the full affected defect family, then review all 128 controls plus downstream persistence/export logic before issuing HF12.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bdf05b7f-664a-41d6-a7da-61cec38141c5"></a>
## Assistant · C085-M00090

C085-M00090 · 2026-08-11T12:43:54.789102-04:00 · active path

Preceding visible parent: [C085-M00089](part-05.md#m-5a0ec94c-d60f-4bad-af81-80515cc3a6a1)

<!-- BEGIN_SOURCE_MESSAGE -->
The attached verifier confirms the committed Program 222 checkpoint is clean, so the defect is isolated to HF11’s control observations rather than persisted generation state.
<!-- END_SOURCE_MESSAGE -->


<a id="m-19cfe713-d717-447e-886a-398ce31ed4e0"></a>
## Assistant · C085-M00091

C085-M00091 · 2026-08-11T12:53:00.933671-04:00 · active path

Preceding visible parent: [C085-M00090](part-05.md#m-bdf05b7f-664a-41d6-a7da-61cec38141c5)

<!-- BEGIN_SOURCE_MESSAGE -->
Control 114 is isolated: it wrongly required 24 `PASS` strategy-evidence rows, while the accepted M2.11 contract intentionally has 24 `PARTIAL` rows with hard guards passing.
<!-- END_SOURCE_MESSAGE -->


<a id="m-85b32f9a-4795-4574-a72d-dd6da3d4b53c"></a>
## Assistant · C085-M00092

C085-M00092 · 2026-08-11T13:20:09.109137-04:00 · active path

Preceding visible parent: [C085-M00091](part-05.md#m-19cfe713-d717-447e-886a-398ce31ed4e0)

<!-- BEGIN_SOURCE_MESSAGE -->
Control 009 also wrongly removed the latest row hash when comparing archive payloads. HF12 now fixes only Controls 009/114 and adds a mutation-free 128-control diagnostic before retry.
<!-- END_SOURCE_MESSAGE -->


<a id="m-402b22de-3a9c-4ff4-9f6e-529ffd23bbba"></a>
## Assistant · C085-M00093

C085-M00093 · 2026-08-11T13:35:40.527873-04:00 · active path

Preceding visible parent: [C085-M00092](part-05.md#m-85b32f9a-4795-4574-a72d-dd6da3d4b53c)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 223 HF12 — Bounded Hotfix and Full Review Complete

Your stop-and-rollback response was correct. **Do not rerun Program 223 HF11.** Program 223 HF12 is the only current Program 223 retry source.

The attached pre-execution evidence proves that the committed Program 222 checkpoint was internally exact before the HF11 attempt:

- all 19 source-graph edges passed with exact accepted-source and target-recorded hashes; [export reference: filecite | turn18file3 | L88-L107]
- all 12 stage boundaries passed with 70 of 70 physical controls and no missing, duplicate, non-PASS, or violating controls; [export reference: filecite | turn18file2 | L65-L77]
- all nine canonical families reproduced their stored hashes and expected cardinalities; [export reference: filecite | turn18file1 | L45-L54]
- all 24 generation-evidence rows passed with exact expected values; [export reference: filecite | turn18file0 | L10-L34]
- the run remained at `M2_12_GENERATED / GENERATED`, with 134 canonical entities, zero downstream evidence, all three owned sequences at `1|true`, and combined-set hash `28d832719a63d5669a18016f15ba43fb`. [export reference: filecite | turn18file4 | L118-L119]

The defect was therefore inside the HF11 positive-control observations rather than in Program 222’s committed state.

## Downloads

### Controlled continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF12.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF12.zip`; referenced bytes not established here)
- Download the matching ZIP SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF12.zip.sha256`; referenced bytes not established here)

The ZIP contains exactly one executable governed program—Program 223 HF12—plus two read-only verifiers. It contains no Program 224–227 SQL and no recovery SQL.

### Program 223 HF12

- Download Program 223 HF12 SQL (historical reference: `sandbox:[session]/223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql`; referenced bytes not established here)
- Download the Program 223 HF12 SQL sidecar (historical reference: `sandbox:[session]/223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql.sha256`; referenced bytes not established here)

### Mandatory read-only verifiers

- Download the HF12 generated-checkpoint verifier (historical reference: `sandbox:[session]/223_HF12_pre_execution_generated_checkpoint_verification.sql`; referenced bytes not established here)
- Download its sidecar (historical reference: `sandbox:[session]/223_HF12_pre_execution_generated_checkpoint_verification.sql.sha256`; referenced bytes not established here)
- Download the new HF12 complete 128-control diagnostic (historical reference: `sandbox:[session]/223_HF12_pre_execution_positive_control_diagnostic.sql`; referenced bytes not established here)
- Download its sidecar (historical reference: `sandbox:[session]/223_HF12_pre_execution_positive_control_diagnostic.sql.sha256`; referenced bytes not established here)

### Principal review records

- HF11 failure diagnosis and HF12 correction (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_FAILURE_DIAGNOSIS_AND_HF12_CORRECTION.md`; referenced bytes not established here)
- HF12 operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- HF12 validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_VALIDATION_REPORT.md`; referenced bytes not established here)
- Independent physical/static readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- 337-control readback ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Complete 128-control review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_FULL_CONTROL_REVIEW.csv`; referenced bytes not established here)
- Complete 170-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_FULL_STATEMENT_REVIEW.csv`; referenced bytes not established here)
- Changed-control ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_CHANGED_CONTROL_LEDGER.csv`; referenced bytes not established here)
- G3 archive-payload parity review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_G3_ARCHIVE_PAYLOAD_PARITY_REVIEW.csv`; referenced bytes not established here)
- Accepted M2.11 status reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_ACCEPTED_M2_11_STATUS_RECONCILIATION.csv`; referenced bytes not established here)
- Post-gate review (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_POST_GATE_REVIEW.csv`; referenced bytes not established here)
- Known-defect-pattern scan (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF12_KNOWN_DEFECT_PATTERN_SCAN.csv`; referenced bytes not established here)
- HF11-to-HF12 source patch (historical reference: `sandbox:[session]/M2_12_PROGRAM_223_HF11_TO_HF12.patch`; referenced bytes not established here)

# The two HF11 failures

HF11 reported:

```text
rows=128
codes=128
failures=2
family_mismatches=0
```

That means 126 controls completed without a failure classification. The two deterministic failures were reconstructed from the physical HF11 source and the accepted predecessor evidence.

## Control 009 — G3 archive payload parity

Control:

```text
M2_12_POS_009_G3_ARCHIVE_IDENTITY_AND_GUARD
```

Program 222 HF9 physically built the G3 archive payload as:

```sql
(to_jsonb(lt) - 'created_at')::jsonb
```

That payload intentionally retains the latest row’s `row_hash`.

HF11 compared it to:

```sql
a.contract_payload =
    (to_jsonb(l) - 'row_hash' - 'created_at')
```

Removing `row_hash` made the validator’s reconstructed payload different from the payload Program 222 actually stored.

HF12 uses the exact builder-compatible comparison:

```sql
a.contract_payload =
    (to_jsonb(l) - 'created_at')
```

All three Control 009 comparison paths—observed count, mismatch count, and PASS predicate—were corrected.

## Control 114 — accepted M2.11 evidence posture

Control:

```text
M2_12_POS_114_STRESS_AND_IMPROVEMENT_GUARDS
```

I reopened the accepted M2.11 latest-strategy-contract export from the accepted full-project baseline. Its physical state is:

```text
Strategy rows                         24
strategy_evidence_status=PARTIAL      24
strategy_evidence_status=PASS          0
Aggregate guard-violation count        0
stress_nonimprovement_pass_flag=true  24
```

HF11 incorrectly required:

```sql
count(*) FILTER (
    WHERE strategy_evidence_status='PASS'
) = 24
```

That count was necessarily zero.

HF12 requires the exact accepted state:

```sql
count(*) FILTER (
    WHERE strategy_evidence_status='PARTIAL'
) = 24
```

It retains the other mandatory conditions:

```text
24 total strategy rows
0 aggregate guard violations
24 stress non-improvement passes
```

Thus the governed observed/expected vector remains:

```text
0|24|24
```

but the middle value now represents the exact accepted `PARTIAL` evidence posture rather than a nonexistent `PASS` posture.

# Review beyond the two reported failures

The correction did not stop after patching Controls 009 and 114.

## Complete source review

| Review scope | HF12 result |
|---|---:|
| Top-level SQL statements | **170/170 reviewed** |
| Positive-control definitions | **128/128 reviewed** |
| Control sequences | **1–128 exact** |
| Distinct control codes | **128** |
| Control definitions changed | **2** |
| Controls byte-identical to HF11 | **126** |
| Changed statement bodies | **13** |
| Substantive logic changes | **3** |
| Revision/diagnostic-label changes | **10** |
| Independent physical/static controls | **337/337 PASS** |
| Blocking findings | **0** |

The three substantive statement changes are:

1. Control 009 archive-payload parity.
2. Control 114 accepted M2.11 status.
3. The 128/128 release gate’s diagnostic detail.

## Improved failure diagnostics

HF11 reported only the number of failed controls.

HF12’s executable release gate now includes each failed control’s:

```text
control sequence
evidence code
status
mismatch count
observed value
expected value
```

A future exception would therefore identify the actual failed controls rather than return only:

```text
failures=N
```

## Complete pre-write diagnostic

A separate read-only diagnostic now evaluates the complete Program 223 control path before any persistent write.

It:

- reconstructs all 128 HF12 controls;
- creates only temporary relations;
- performs zero persistent DML;
- performs zero persistent DDL;
- changes no lifecycle;
- changes no sequence;
- ends with `ROLLBACK`.

It returns four result grids:

| Grid | Required successful result |
|---|---|
| 1 — Complete control detail | **128 rows, all PASS, all mismatch counts zero** |
| 2 — Failure-only detail | **Headers and zero data rows** |
| 3 — Family allocation | **10 rows, all PASS** |
| 4 — Diagnostic summary | **128 controls, 128 codes, 128 passes, zero failures, `PASS`, `READY_TO_EXECUTE_PROGRAM_223_HF12`** |

This means you will see any remaining control discrepancy **before** Program 223 is allowed to insert evidence or transition lifecycle.

## Post-gate review

The complete section that HF11 never reached was also reviewed.

| Post-gate control | Result |
|---|---:|
| Pre-write/post-write deterministic reconstruction parity | **PASS** |
| Persistent mutation operations | **3 exact** |
| Positive-evidence insert targets | **1 exact** |
| Lifecycle update targets | **2 exact** |
| Persistent DELETE operations | **0** |
| Persistent DDL operations | **0** |
| Owned-sequence mutations | **0** |
| Final commits | **1** |
| Post-commit result grids | **2** |
| Result helpers use `ON COMMIT PRESERVE ROWS` | **PASS** |

The WP3 authority requires exactly 128 persisted-state controls, persistence only after 128/128 PASS, transition only to `M2_12_VALIDATED`, and preservation of canonical business and hash fields. HF12 retains those boundaries. [export reference: filecite | turn19file12 | L31-L46]

# Mutation boundary

Program 223 HF12 retains exactly three authorized persistent operations:

| Operation | Target | Effect |
|---|---|---|
| `INSERT` | `msbf_ctl.run_evidence` | Insert exactly 128 positive PASS evidence rows after the hard control gate |
| `UPDATE` | `msbf_ctl.m2_12_g3_bundle_registry` | Transition `GENERATED → VALIDATED` |
| `UPDATE` | `msbf_ctl.run_registry` | Transition `M2_12_GENERATED → M2_12_VALIDATED` |

There are no changes to:

```text
canonical business rows
canonical row hashes
family set hashes
contract-set hash
combined-set hash
owned sequences
Programs 224–227
Recovery 223A
```

# Physical delivery ledger

## Continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF12.zip` |
| Bytes | **180,858** |
| SHA-256 | `57fdc4024c4b00c395f3fbcd7720046c0d9207ea95415ba6a02e2c418f573ad0` |
| ZIP entries | **32** |
| Total uncompressed bytes | **1,861,268** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |
| Manifest rows | **28** |
| Package-inventory rows | **31** |
| Path mismatches | **0** |
| Size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |

The ZIP sidecar contains exactly:

```text
57fdc4024c4b00c395f3fbcd7720046c0d9207ea95415ba6a02e2c418f573ad0  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_222_HF12.zip
```

## Program 223 HF12

| Attribute | Physical result |
|---|---:|
| Bytes | **769,374** |
| SHA-256 | `a52a2ea1fe423fae840c21a3bba6dda7ca45dea1c29531134e823a96635411fe` |
| Top-level statements | **170** |
| Positive controls | **128** |
| Changed control definitions | **2** |
| Persistent mutations | **3** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

Its sidecar contains exactly:

```text
a52a2ea1fe423fae840c21a3bba6dda7ca45dea1c29531134e823a96635411fe  223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql
```

## Generated-checkpoint verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **139,957** |
| SHA-256 | `f13eaf60dd3de48fe11afede4379505132ac9a5dfd661df6b159e8c2f93cb272` |
| Top-level statements | **25** |
| Persistent mutations | **0** |
| Final action | **ROLLBACK** |

## Complete 128-control diagnostic

| Attribute | Physical result |
|---|---:|
| Bytes | **743,579** |
| SHA-256 | `622d7d4a3aa081f2229f815320c7f59b7a8e0f269cfbd91556e7fac67d01848e` |
| Top-level statements | **165** |
| Control definitions | **128** |
| Result grids | **4** |
| Persistent mutations | **0** |
| Final action | **ROLLBACK** |

# Mandatory HF12 execution sequence

The controlled-execution authority requires one whole physical file per invocation, exact sequential checkpoints, and an immediate stop on any error or ambiguity. [export reference: filecite | turn19file5 | L34-L50]

## 1. Preserve HF11 evidence

Keep unchanged:

```text
complete HF11 console transcript
P0001 error
rows=128 / codes=128 / failures=2 / family_mismatches=0 detail
client/process status
STOP action
ROLLBACK response
five HF11 pre-execution exports
```

Do not run Recovery 223A. HF11 failed at the 128/128 gate before the persistent evidence insert or lifecycle updates, and the transaction was rolled back.

## 2. Run the HF12 generated-checkpoint verifier

Execute:

```text
223_HF12_pre_execution_generated_checkpoint_verification.sql
```

Require SHA-256:

```text
f13eaf60dd3de48fe11afede4379505132ac9a5dfd661df6b159e8c2f93cb272
```

Require the same exact five-grid checkpoint already demonstrated by the attached evidence:

```text
19/19 source edges PASS
12/12 stage boundaries PASS
70/70 physical stage controls
9/9 canonical families PASS
24/24 generation-evidence rows PASS
M2_12_GENERATED / GENERATED
134 canonical entities
zero positive, negative, acceptance, and G3-gate rows
all three owned sequences 1|true
combined hash 28d832719a63d5669a18016f15ba43fb
disposition READY_TO_EXECUTE_PROGRAM_223_HF12
```

Export all five grids using fetched rows.

## 3. Run the new 128-control diagnostic

Execute:

```text
223_HF12_pre_execution_positive_control_diagnostic.sql
```

Require SHA-256:

```text
622d7d4a3aa081f2229f815320c7f59b7a8e0f269cfbd91556e7fac67d01848e
```

Require:

```text
Grid 1: 128 rows; every status PASS; every mismatch_count 0
Grid 2: headers; zero data rows
Grid 3: 10 family rows; every family_status PASS
Grid 4:
    control_rows           128
    distinct_control_codes 128
    minimum_sequence         1
    maximum_sequence       128
    pass_rows              128
    failure_rows             0
    family_pass_rows        10
    family_failure_rows      0
    diagnostic_status      PASS
    disposition            READY_TO_EXECUTE_PROGRAM_223_HF12
```

Any failure row or different summary is a hard stop. Do not execute Program 223.

## 4. Execute Program 223 HF12 only

After both verifiers pass exactly, execute:

```text
223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql
```

Require SHA-256:

```text
a52a2ea1fe423fae840c21a3bba6dda7ca45dea1c29531134e823a96635411fe
```

Execution boundaries:

```text
One complete physical file
One invocation
First-error stop configured in DBeaver/client
No outer transaction
No Program 224 concatenation
No ad hoc SQL
No recovery execution
```

## 5. Required Program 223 outputs

### Persistence result

Require one row:

```text
run_status            M2_12_VALIDATED
contract_status       VALIDATED
positive_pass         128
positive_codes        128
negative_rows         0
acceptance_rows       0
gate_rows             0
hash_compare_rows     1
hash_exact_rows       1
persistence_status    PASS
```

### Positive-control detail

Require:

```text
Rows                   128
Control sequences      1–128
Distinct codes         128
Status                 PASS for every row
Mismatch count         0 for every row
```

Export both grids using:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

## 6. Stop after Program 223

Even after an exact PASS:

```text
Program 224        HELD
Program 225        HELD
Program 226        HELD
Program 227        HELD
Recovery 223A      UNAUTHORIZED
M2.12 acceptance   NOT CLAIMED
```

The original WP5 package remains the historical approved archive with SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn19file0 | L3-L12] HF12 is a bounded continuation after Program 222 and does not replace that archive.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e5f62f6c-49d3-4ec4-8a6e-e4c4a3f9a59f"></a>
## Andrew / user · C085-M00094

C085-M00094 · 2026-08-11T13:45:07.176000-04:00 · active path

Preceding visible parent: [C085-M00093](part-05.md#m-402b22de-3a9c-4ff4-9f6e-529ffd23bbba)

<!-- BEGIN_SOURCE_MESSAGE -->
advice on what to name the outputs of 223_HF12_pre_execution_positive_control_diagnostic.sql  ?
<!-- END_SOURCE_MESSAGE -->


<a id="m-0d81333c-6315-44e0-85f6-f614f888c2ce"></a>
## Assistant · C085-M00095

C085-M00095 · 2026-08-11T13:45:08.346014-04:00 · active path

Preceding visible parent: [C085-M00094](part-05.md#m-e5f62f6c-49d3-4ec4-8a6e-e4c4a3f9a59f)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. For `223_HF12_pre_execution_positive_control_diagnostic.sql`, I recommend **four separate CSVs matching the four result grids**:

1. `223_HF12_pre_execution_positive_control_detail.csv`  
   — Grid 1: all **128 controls**, with every control expected to be `PASS` and `mismatch_count=0`.

2. `223_HF12_pre_execution_positive_control_failures.csv`  
   — Grid 2: failure-only detail. On a clean run, preserve the **headers with zero data rows**.

3. `223_HF12_pre_execution_positive_control_family_summary.csv`  
   — Grid 3: the **10 control-family rows**, all expected `PASS`.

4. `223_HF12_pre_execution_positive_control_diagnostic_summary.csv`  
   — Grid 4: the one-row overall summary showing 128/128 PASS and `READY_TO_EXECUTE_PROGRAM_223_HF12`.

I would use those names exactly. They make the evidence purpose and sequence unambiguous and distinguish these **pre-execution diagnostic outputs** from the actual Program 223 outputs you will later capture.

For each DBeaver export, continue using:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

And **do not omit Grid 2 just because it has zero rows**. The header-only failure file is affirmative evidence that the diagnostic returned the expected empty failure result.

If all four reconcile exactly, then proceed to Program 223 HF12; otherwise stop. That preserves the governed one-program-at-a-time, checkpoint-first execution model. [export reference: filecite | turn19file5 | L36-L50]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3f826b61-14a8-4dcb-a1fd-51e7fbe5c652"></a>
## Andrew / user · C085-M00096

C085-M00096 · 2026-08-11T13:51:29.648000-04:00 · active path

Preceding visible parent: [C085-M00095](part-05.md#m-0d81333c-6315-44e0-85f6-f614f888c2ce)

**Editorial record note:** Attachment references: 223_msbf_m2_12_positive_validation_128_controls_v1_HF12_validation_persistence_results_20260811.csv; 223_HF12_pre_execution_positive_control_diagnostic_summary_20260811.csv; 223_HF12_pre_execution_positive_control_family_summary_20260811.csv; 223_HF12_pre_execution_positive_control_failures_20260811.csv; 223_HF12_pre_execution_positive_control_detail_20260811.csv; 223_HF12_pre_execution_state_summary_20260811.csv; 223_HF12_pre_execution_generation_evidence_detail_20260811.csv; 223_HF12_pre_execution_canonical_family_detail_20260811.csv; 223_HF12_pre_execution_stage_boundary_detail_20260811.csv; 223_HF12_pre_execution_source_graph_detail_20260811.csv; 223_msbf_m2_12_positive_validation_128_controls_v1_HF12_positive_results_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
223 results attached. perform program 224 bounded correction and review.
<!-- END_SOURCE_MESSAGE -->


<a id="m-81b06019-ded7-4045-9784-e10a04ca53e6"></a>
## Assistant · C085-M00097

C085-M00097 · 2026-08-11T13:51:55.274811-04:00 · active path

Preceding visible parent: [C085-M00096](part-05.md#m-3f826b61-14a8-4dcb-a1fd-51e7fbe5c652)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll reconcile the Program 223 evidence, then fully review Program 224’s 20 negative controls, isolation/fingerprints, parser compatibility, persistence, and package corrected SQL with preflight and independent audits.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a16f348c-63d2-4dce-8c5c-100062e0f89a"></a>
## Assistant · C085-M00098

C085-M00098 · 2026-08-11T13:55:01.093886-04:00 · active path

Preceding visible parent: [C085-M00097](part-05.md#m-81b06019-ded7-4045-9784-e10a04ca53e6)

<!-- BEGIN_SOURCE_MESSAGE -->
Program 223 evidence reconciles exactly: 128/128 PASS, zero diagnostic failures, all ten families PASS, and committed `M2_12_VALIDATED / VALIDATED` with 128 positive controls.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c9c6fbac-381a-4f22-9afb-1d09c5594836"></a>
## Assistant · C085-M00099

C085-M00099 · 2026-08-11T14:04:09.058002-04:00 · active path

Preceding visible parent: [C085-M00098](part-05.md#m-a16f348c-63d2-4dce-8c5c-100062e0f89a)

<!-- BEGIN_SOURCE_MESSAGE -->
Initial Program 224 defects include DBeaver-incompatible `\set`, obsolete M1.3 hash extraction, a noncanonical evidence-family key, Control 013’s inverted predicate, and overly broad `SELECT *` usage.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2c441b3a-aea4-4597-8ad2-8e671d3898ef"></a>
## Assistant · C085-M00100

C085-M00100 · 2026-08-11T14:37:17.861522-04:00 · active path

Preceding visible parent: [C085-M00099](part-05.md#m-c9c6fbac-381a-4f22-9afb-1d09c5594836)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 224 HF13 — Bounded Correction and Review Complete

The attached Program 223 HF12 evidence reconciles to the exact validated checkpoint required before Program 224:

- The pre-execution diagnostic evaluated 128 controls, 128 distinct codes, sequences 1–128, 128 PASS rows, zero failures, and all 10 control families passing. [export reference: filecite | turn20file1 | L22-L23]
- The failure-only diagnostic contains its governed headers and zero data rows. [export reference: filecite | turn20file2 | L28-L34]
- The committed Program 223 result shows `M2_12_VALIDATED / VALIDATED`, 128 persisted positive controls, zero negative, acceptance, or G3-gate rows, exact hash reconciliation, and `persistence_status=PASS`. [export reference: filecite | turn20file0 | L9-L11]

The Program 224 authority requires exactly 20 exception-isolated negative controls, exact SQLSTATE and rejection-signature validation, complete before/after canonical/hash/sequence fingerprints, persistence of only the 20 negative PASS rows, and no lifecycle change from `M2_12_VALIDATED`. [export reference: filecite | turn19file12 | L48-L59]

**Do not execute the historical Program 224 R1 source. Program 224 HF13 is the only current Program 224 execution source.**

## Downloads

### Controlled continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_223_HF13.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_223_HF13.zip`; referenced bytes not established here)
- Download the matching ZIP SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_223_HF13.zip.sha256`; referenced bytes not established here)

The package contains exactly one executable governed program—Program 224 HF13—plus two read-only verifiers. It contains no executable Program 225–227 or recovery source.

### Program 224 HF13

- Download Program 224 HF13 SQL (historical reference: `sandbox:[session]/224_msbf_m2_12_negative_controls_20_isolated_v1_HF13.sql`; referenced bytes not established here)
- Download the Program 224 HF13 SQL sidecar (historical reference: `sandbox:[session]/224_msbf_m2_12_negative_controls_20_isolated_v1_HF13.sql.sha256`; referenced bytes not established here)

### Mandatory pre-execution verifier

- Download the validated-checkpoint verifier (historical reference: `sandbox:[session]/224_HF13_pre_execution_validated_checkpoint_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/224_HF13_pre_execution_validated_checkpoint_verification.sql.sha256`; referenced bytes not established here)

### Complete 20-control diagnostic

- Download the pre-execution negative-control diagnostic (historical reference: `sandbox:[session]/224_HF13_pre_execution_negative_control_diagnostic.sql`; referenced bytes not established here)
- Download the diagnostic sidecar (historical reference: `sandbox:[session]/224_HF13_pre_execution_negative_control_diagnostic.sql.sha256`; referenced bytes not established here)

### Operator and source authority

- Program 224 HF13 operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Program 224 HF13 source authority (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_SOURCE_AUTHORITY.md`; referenced bytes not established here)
- Program 224 HF13 validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_VALIDATION_REPORT.md`; referenced bytes not established here)

### Detailed review records

- Independent physical-readback report (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- 116-control independent readback ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Machine-readable independent readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_INDEPENDENT_PHYSICAL_READBACK.json`; referenced bytes not established here)
- Twenty-control catalog (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_NEGATIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Complete 20-control review (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_FULL_CONTROL_REVIEW.csv`; referenced bytes not established here)
- Complete 47-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_FULL_STATEMENT_REVIEW.csv`; referenced bytes not established here)
- Changed-control ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_CHANGED_CONTROL_LEDGER.csv`; referenced bytes not established here)
- Known-defect-pattern scan (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_KNOWN_DEFECT_PATTERN_SCAN.csv`; referenced bytes not established here)
- Persistent-mutation inventory (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_HF13_PERSISTENT_MUTATION_INVENTORY.csv`; referenced bytes not established here)
- Original R1-to-HF13 source patch (historical reference: `sandbox:[session]/M2_12_PROGRAM_224_R1_TO_HF13.patch`; referenced bytes not established here)

# Bounded corrections

The historical Program 224 R1 source had SHA-256:

```text
c010ed61c7f93da457235e01902f280596f706f42f232464fac546fd13dbda36
```

That identity remains part of the approved historical WP3 archive. [export reference: filecite | turn19file9 | L32-L54] HF13 supersedes it only for controlled Program 224 execution.

## 1. DBeaver-incompatible client command removed

The original source still contained a psql-only:

```text
\set ON_ERROR_STOP on
```

HF13 is pure PostgreSQL SQL:

```text
psql meta-command lines    0
executable backslashes     0
```

First-error-stop behavior must be configured in DBeaver or the invoking client.

## 2. Source-graph reconstruction corrected

The original Program 224 carried a stale source-graph implementation. HF13 uses the same physically validated 19-edge authority proven during Programs 221–223, including:

- exact source and target registry identities;
- exact contract or bundle versions and statuses;
- one source and one target registry row per edge;
- exact source-gate status;
- exact expected, accepted-source, and target-recorded hashes.

For the M1.3 request-authority edge, HF13 extracts the governed hash from:

```sql
(agr.observed_value::jsonb ->> 'application_set_hash')::text
```

It no longer compares the complete JSON document as a hash.

## 3. Evidence-certification entity key aligned

The canonical evidence-certification entity key is now consistently:

```text
node_sequence | evidence_family_sequence
```

The obsolete variant that also inserted `evidence_family_code` has been removed from the negative-control fingerprint path.

## 4. Control 013 mismatch direction corrected

Control 013 is:

```text
M2_12_NEG_013_CANONICAL_COUNT_OR_SET_HASH_MISMATCH
```

The original predicate had the mismatch direction inverted. It could reject a properly changed fingerprint rather than reject failure to create a changed fingerprint.

HF13 now requires the deliberately mutated canonical fingerprint to be:

```sql
IS DISTINCT FROM
```

the baseline fingerprint before the isolation control may pass.

## 5. Control 014 rerun scope hardened

Control 014 now binds its simulated version-one rerun to the exact:

- policy code;
- policy version 1;
- policy status;
- G3 bundle code;
- G3 bundle version 1;
- registry lifecycle `VALIDATED`.

It no longer relies on a broad or incompletely identified version-one fixture.

## 6. Broad fixture projections eliminated

Controls 004, 005, 015, and 016 previously used broad temporary-fixture projections. HF13 replaces those with explicit physical columns for:

- linear source-edge hash break;
- M2.11 multisource hash break;
- application-view grain multiplication;
- operational-view orphan or duplicate detection.

No broad temporary-fixture `SELECT *` remains.

## 7. Control 018 exact authority retained

The capability-overclaim control still uses the approved physical fixture:

```text
capability_sequence                  17
injected status                      IMPLEMENTED_PRODUCTION_AUTHORIZED
production_action_authorized_flag    false
legal_regulatory_certified_flag      false
expected SQLSTATE                    23514
expected rejected constraint         ck_m212_capability_status
```

This remains bounded to the specific capability check required by the WP3 authority. [export reference: filecite | turn19file12 | L50-L58]

## 8. Failure diagnostics strengthened

The original 20-of-20 release gate primarily reported aggregate failure counts.

HF13’s gate now identifies each failing control with:

```text
control sequence
evidence code
expected SQLSTATE
observed SQLSTATE
expected constraint or trigger
observed constraint or trigger
before/after fingerprint result
status
isolation status
```

The separate read-only diagnostic exposes the complete control detail before any negative evidence can be persisted.

## 9. Final persistence postflight strengthened

HF13 proves exact totals rather than counting only PASS subsets:

```text
positive total rows       128
positive PASS rows        128
positive distinct codes   128

negative total rows        20
negative PASS rows         20
negative distinct codes    20

acceptance rows              0
G3 gate rows                 0
```

It also requires the complete before/after canonical, hash, sequence, and lifecycle fingerprint to remain exact.

## 10. Result exportability preserved

Both final Program 224 result helpers use:

```sql
ON COMMIT PRESERVE ROWS
```

They remain available after commit in the **same originating database session**. Exporting the visible DBeaver grids with fetched rows remains the preferred evidence method.

# Full review determination

| Review area | HF13 result |
|---|---:|
| Negative-control definitions | **20/20 PASS** |
| Control sequence coverage | **1–20 exact** |
| Distinct control codes | **20** |
| Top-level SQL statements | **47/47 PASS** |
| Source-graph edges | **19/19 reconciled** |
| SQLSTATE/signature authorities | **20/20 reconciled** |
| Physical relations reviewed | **34** |
| Substantively changed controls | **6** |
| Nonsemantic block-boundary normalization | **1 control** |
| Residual known-defect patterns | **0** |
| Independent package controls | **116/116 PASS** |
| Blocking findings | **0** |

The six substantively corrected controls are:

```text
004
005
013
014
015
016
```

Control 020 received only trailing block-boundary normalization; its governed behavior was not changed.

# Mutation and isolation boundary

Six controls execute persistent-table probes, but only inside exception subtransactions:

| Control | Probe | Required rollback mechanism |
|---|---|---|
| 008 | Archive `UPDATE` | Archive immutability trigger |
| 009 | Archive `DELETE` | Archive immutability trigger |
| 010 | Duplicate stage insert | Primary-key rejection |
| 011 | Duplicate component insert | Primary-key rejection |
| 018 | Capability-overclaim update | Check-constraint rejection |
| 019 | Policy production-authority update | Check-constraint rejection |

Those probe mutations must leave zero persistent effect.

The **only committed persistent mutation** is:

```text
INSERT exactly 20 M2_12_NEG_% PASS rows
into msbf_ctl.run_evidence
after the hard 20/20 gate
```

HF13 performs no:

```text
lifecycle update
canonical-row update
canonical-hash update
owned-sequence mutation
persistent DELETE
persistent DDL
Program 225–227 change
recovery-source change
```

The final lifecycle must remain:

```text
run_status       M2_12_VALIDATED
contract_status  VALIDATED
```

# Physical delivery ledger

## Continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_223_HF13.zip` |
| Bytes | **125,168** |
| SHA-256 | `d7a451c6350752150b5296497ed33106b584b0b940007e9473d895d5f16099ba` |
| ZIP entries | **42** |
| Total uncompressed bytes | **815,932** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |
| Path mismatches | **0** |
| Size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Manifest mismatches | **0** |

The ZIP sidecar contains exactly:

```text
d7a451c6350752150b5296497ed33106b584b0b940007e9473d895d5f16099ba  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_223_HF13.zip
```

## Program 224 HF13

| Attribute | Physical result |
|---|---:|
| Bytes | **152,948** |
| SHA-256 | `9639c0b1c08f7f2540ed282e819c4b81279e7944de637ad443fc049c04ad6767` |
| Top-level statements | **47** |
| Negative controls | **20** |
| Persistent committed mutation classes | **1** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

The SQL sidecar contains:

```text
9639c0b1c08f7f2540ed282e819c4b81279e7944de637ad443fc049c04ad6767  224_msbf_m2_12_negative_controls_20_isolated_v1_HF13.sql
```

## Validated-checkpoint verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **174,020** |
| SHA-256 | `e200a8ca5500fdaa55de3b8b011c1808ab6d6a3e6aff7f555db5ea2c55b566e1` |
| Result grids | **6** |
| Persistent mutation | **0** |
| Final action | **ROLLBACK** |

## Twenty-control diagnostic

| Attribute | Physical result |
|---|---:|
| Bytes | **151,055** |
| SHA-256 | `72da3a957623a3be19690c576f3fad54df2a96d6aa5d90085319accc1edcd2c1` |
| Controls evaluated | **20** |
| Result grids | **4** |
| Persistent evidence insert | **0** |
| Final action | **ROLLBACK** |

This is a source, static, isolation-boundary, physical, and packaging review. **Program 224 HF13 has not been executed against your PostgreSQL database here.**

# Mandatory execution sequence

## 1. Preserve Program 223 evidence

Retain the complete Program 223 HF12 transcript and client status with all supplied verifier, diagnostic, persistence, and positive-control exports.

## 2. Execute the validated-checkpoint verifier

Execute:

```text
224_HF13_pre_execution_validated_checkpoint_verification.sql
```

Require SHA-256:

```text
e200a8ca5500fdaa55de3b8b011c1808ab6d6a3e6aff7f555db5ea2c55b566e1
```

It produces six grids. Export them as:

```text
224_HF13_pre_execution_source_graph_detail.csv
224_HF13_pre_execution_stage_boundary_detail.csv
224_HF13_pre_execution_canonical_family_detail.csv
224_HF13_pre_execution_generation_evidence_detail.csv
224_HF13_pre_execution_positive_evidence_detail.csv
224_HF13_pre_execution_state_summary.csv
```

Required summary:

```text
run_status                         M2_12_VALIDATED
contract_status                    VALIDATED
positive total/pass/distinct       128 / 128 / 128
source graph                       19 / 19 PASS
stage boundaries                   12 / 12 PASS
physical stage controls            70 / 70
canonical families                  9 / 9 PASS
generation evidence                24 / 24 PASS
negative rows                       0
acceptance rows                     0
G3 gate rows                        0
policy sequence                     1|true
archive sequence                    1|true
registry sequence                   1|true
disposition                         READY_TO_EXECUTE_PROGRAM_224_HF13
```

Any discrepancy is a hard stop.

## 3. Execute the complete 20-control diagnostic

Execute:

```text
224_HF13_pre_execution_negative_control_diagnostic.sql
```

Require SHA-256:

```text
72da3a957623a3be19690c576f3fad54df2a96d6aa5d90085319accc1edcd2c1
```

Export its four grids as:

```text
224_HF13_pre_execution_negative_control_detail.csv
224_HF13_pre_execution_negative_control_failures.csv
224_HF13_pre_execution_negative_control_family_summary.csv
224_HF13_pre_execution_negative_control_diagnostic_summary.csv
```

Required results:

```text
control rows                20
distinct control codes      20
minimum sequence             1
maximum sequence            20
PASS controls               20
isolation PASS controls     20
failure rows                 0
family rows                 14
family PASS rows            14
diagnostic status           PASS
disposition                 READY_TO_EXECUTE_PROGRAM_224_HF13
```

The failure-only grid must retain its headers and contain zero data rows.

## 4. Execute Program 224 HF13 only

After both verifiers pass exactly, execute:

```text
224_msbf_m2_12_negative_controls_20_isolated_v1_HF13.sql
```

Require SHA-256:

```text
9639c0b1c08f7f2540ed282e819c4b81279e7944de637ad443fc049c04ad6767
```

Execution boundaries:

```text
one complete physical file
one invocation
first-error stop configured in DBeaver/client
no outer transaction
no Program 225 concatenation
no ad hoc SQL
no recovery execution
```

The controlled authority requires exact sequential execution and an immediate stop on any error, lifecycle mismatch, count mismatch, hash mismatch, or evidence anomaly. [export reference: filecite | turn19file5 | L36-L50]

## 5. Program 224 output names

Use:

```text
224_msbf_m2_12_negative_controls_20_isolated_v1_HF13_validation_persistence_results_20260811.csv

224_msbf_m2_12_negative_controls_20_isolated_v1_HF13_negative_results_20260811.csv
```

Required persistence row:

```text
run_status             M2_12_VALIDATED
contract_status        VALIDATED

positive_total_rows    128
positive_rows          128
positive_codes         128

negative_total_rows     20
negative_rows           20
negative_codes          20

acceptance_rows          0
gate_rows                0
exact_flag               true
persistence_status       PASS
```

Required negative-control detail:

```text
rows                    20
control sequences       1–20
distinct codes          20
status                   PASS for every row
isolation_status         PASS for every row
before/after canonical   exact for every row
before/after hashes      exact for every row
before/after sequences   exact for every row
before/after lifecycle   exact for every row
```

For every DBeaver export:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

## 6. Stop after Program 224

Even after an exact PASS:

```text
Program 225        HELD
Program 226        HELD
Program 227        HELD
M2.12 acceptance   NOT CLAIMED
```

Do not execute Program 225 until the complete Program 224 transcript, client status, both verifier sets, persistence result, all 20 negative-control detail rows, isolation signatures, evidence counts, lifecycle, fingerprints, and sequence states have reconciled exactly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c526f8d2-28f3-46e3-8d5d-15134f7b52e0"></a>
## Andrew / user · C085-M00101

C085-M00101 · 2026-08-11T14:48:52.499000-04:00 · active path

Preceding visible parent: [C085-M00100](part-05.md#m-2c441b3a-aea4-4597-8ad2-8e671d3898ef)

**Editorial record note:** Attachment references: 224_HF13_pre_execution_generation_evidence_detail_20260811.csv; 224_HF13_pre_execution_positive_evidence_detail_20260811.csv; 224_HF13_pre_execution_state_summary_20260811.csv; 224_HF13_pre_execution_negative_control_detail_20260811.csv; 224_HF13_pre_execution_negative_control_failures_20260811.csv; 224_HF13_pre_execution_negative_control_family_summary_20260811.csv; 224_HF13_pre_execution_negative_control_diagnostic_summary_20260811.csv; 224_HF13_pre_execution_source_graph_detail_20260811.csv; 224_HF13_pre_execution_stage_boundary_detail_20260811.csv; 224_HF13_pre_execution_canonical_family_detail_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
I negative failure exists. I ran the pre_execution programs and attached evidence. I did not run the main 224 program yet. correct in a hot fix and do not wait on my approval.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2d3ae0fa-a440-49d2-b281-72fd3f0d9a64"></a>
## Assistant · C085-M00102

C085-M00102 · 2026-08-11T14:49:09.435354-04:00 · active path

Preceding visible parent: [C085-M00101](part-05.md#m-c526f8d2-28f3-46e3-8d5d-15134f7b52e0)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m reconciling the failed HF13 diagnostic against the validated checkpoint, then I’ll patch the defect, rescan all 20 controls, and issue a superseding HF14 continuation package.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a5c0e0c1-6a89-42a7-bfc4-1e125547f37b"></a>
## Assistant · C085-M00103

C085-M00103 · 2026-08-11T14:52:14.901037-04:00 · active path

Preceding visible parent: [C085-M00102](part-05.md#m-2d3ae0fa-a440-49d2-b281-72fd3f0d9a64)

<!-- BEGIN_SOURCE_MESSAGE -->
The failure is isolated to Control 003: unqualified `contract_status` caused SQLSTATE `42702`, while isolation fingerprints remained exact. I’m also checking both pre-execution programs for related runtime hazards.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cb179992-bf1e-48c8-9694-362d6894d2b2"></a>
## Assistant · C085-M00104

C085-M00104 · 2026-08-11T15:01:22.052459-04:00 · active path

Preceding visible parent: [C085-M00103](part-05.md#m-a5c0e0c1-6a89-42a7-bfc4-1e125547f37b)

<!-- BEGIN_SOURCE_MESSAGE -->
The validated checkpoint remains pristine, so no recovery is indicated. HF14 is built with the executable and diagnostic patched; I’m completing independent ZIP, SQL-identity, delta, and persistence-tail readback.
<!-- END_SOURCE_MESSAGE -->
