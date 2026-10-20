# WP3 Build Protocol

Part 02 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-01.md)
[Next part](part-03.md)

<a id="m-4c4885ff-20b5-4a05-b077-cbd78c448a88"></a>
## Assistant · C085-M00030

C085-M00030 · 2026-08-10T19:40:02.147112-04:00 · active path

Preceding visible parent: [C085-M00029](part-01.md#m-34611049-85e2-4bb8-aedd-250d54272e74)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 220 HF2 — Hotfix complete

Your stop-and-rollback response was correct and preserved the required fail-closed boundary. The governing execution authorization requires stopping immediately on any error and prohibits continuing, rerunning, patching ad hoc, or selecting recovery without a new state-specific direction. [export reference: filecite | turn2file5 | L48-L50]

**Do not rerun the original Program 220 or HF1.** HF2 now supersedes both for the next controlled Program 220 attempt.

## Downloads

### Complete superseding execution package

- Download M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF2.zip (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF2.zip`; referenced bytes not established here)
- Download the matching HF2 ZIP sidecar (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF2.zip.sha256`; referenced bytes not established here)

### Corrected Program 220 HF2 directly

- Download Program 220 HF2 SQL (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF2.sql`; referenced bytes not established here)
- Download the Program 220 HF2 SQL sidecar (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF2.sql.sha256`; referenced bytes not established here)

### Mandatory rollback-state verifier

- Download the HF2 pre-rerun rollback-state verifier (historical reference: `sandbox:[session]/220_HF2_pre_rerun_rollback_state_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/220_HF2_pre_rerun_rollback_state_verification.sql.sha256`; referenced bytes not established here)

### Validation records

- Download the HF2 release-validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF2_RELEASE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the separately coded physical-readback report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF2_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the physical-readback JSON (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF2_INDEPENDENT_PHYSICAL_READBACK.json`; referenced bytes not established here)

## Root cause

The failing check was:

```text
P220_PF_0064_PERSISTENT_COLUMN
```

The physical DDL declares:

```sql
created_at timestamptz DEFAULT clock_timestamp() NOT NULL
```

But the postflight asserted:

```sql
pg_catalog.format_type(a.atttypid, a.atttypmod) = 'timestamptz'
```

`timestamptz` is a valid PostgreSQL **input alias**, but `pg_catalog.format_type(...)` returns the canonical catalog display value:

```text
timestamp with time zone
```

Therefore, the postflight incorrectly rejected a structurally matching timestamp column.

This was not isolated to Check 0064. The same latent comparison appeared in **14 timestamp-column postflights**. Patching only Check 0064 would have caused Program 220 to fail again at the next affected timestamp column.

HF2 corrects all 14 checks:

```text
P220_PF_0064_PERSISTENT_COLUMN
P220_PF_0065_PERSISTENT_COLUMN
P220_PF_0096_PERSISTENT_COLUMN
P220_PF_0142_PERSISTENT_COLUMN
P220_PF_0164_PERSISTENT_COLUMN
P220_PF_0196_PERSISTENT_COLUMN
P220_PF_0207_PERSISTENT_COLUMN
P220_PF_0270_PERSISTENT_COLUMN
P220_PF_0282_PERSISTENT_COLUMN
P220_PF_0343_PERSISTENT_COLUMN
P220_PF_0344_PERSISTENT_COLUMN
P220_PF_0345_PERSISTENT_COLUMN
P220_PF_0347_PERSISTENT_COLUMN
P220_PF_0348_PERSISTENT_COLUMN
```

Each now expects:

```sql
pg_catalog.format_type(a.atttypid, a.atttypmod)
    = 'timestamp with time zone'
```

## Scope lock

| Control | Result |
|---|---:|
| Persistent-column checks independently reconstructed | **327** |
| DDL tables reconciled | **9** |
| DDL columns reconciled | **327** |
| HF1 DDL-to-postflight type mismatches | **14** |
| HF2 DDL-to-postflight mismatches | **0** |
| Governed statements changed versus HF1 | **14** |
| Governed statements unchanged versus HF1 | **459** |
| Total governed statements retained | **473** |
| Persistent DDL changed | **0** |
| Column declarations changed | **0** |
| Nullability changed | **0** |
| Identity specifications changed | **0** |
| Default expressions changed | **0** |
| Transaction boundaries changed | **0** |
| Primary result statement changed | **0** |
| Prior seven HF1 view-postflight corrections changed | **0** |
| Programs 221–227 changed | **0** |
| Recovery sources changed | **0** |

The original WP5 R1 package remains the approved historical baseline identity—492,278 bytes, 98 entries, and SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`. [export reference: filecite | turn2file0 | L3-L8] HF2 preserves the downstream sources and recoveries while superseding Program 220 for the next attempt.

## Physical delivery ledger

### Canonical HF2 ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF2.zip` |
| Bytes | **543,808** |
| SHA-256 | `2a69b16f75ab5d5b68c970a3af24a3c54d464a7472fe2dcd545af1799115f267` |
| ZIP entries | **126** |
| Total uncompressed bytes | **4,072,463** |
| ZIP CRC | **PASS** |
| Complete fresh extraction | **PASS** |

The ZIP sidecar contains:

```text
2a69b16f75ab5d5b68c970a3af24a3c54d464a7472fe2dcd545af1799115f267  M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF2.zip
```

### Program 220 HF2

| Attribute | Physical result |
|---|---:|
| Filename | `220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF2.sql` |
| Bytes | **763,532** |
| SHA-256 | `575a80207e8347003d4147be4f243c8179ef234fbc5034b3d272837b15ebfe40` |
| Governed statements | **473** |
| Changed versus HF1 | **14** |
| Unchanged versus HF1 | **459** |
| Physical readback | **PASS** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

The SQL sidecar contains:

```text
575a80207e8347003d4147be4f243c8179ef234fbc5034b3d272837b15ebfe40  220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF2.sql
```

### Rollback-state verifier

| Attribute | Physical result |
|---|---:|
| Filename | `220_HF2_pre_rerun_rollback_state_verification.sql` |
| Bytes | **7,567** |
| SHA-256 | `dff918d14b710df9b6e53d653fe9aa4fe3daed7424f05f0758c49f9e6482f144` |
| Persistent DML | **NONE** |
| Persistent DDL | **NONE** |
| Temporary object inventory | **19 expected relations/sequences** |
| Final transaction action | **ROLLBACK** |

### Source-set identities

| Source set | SHA-256 |
|---|---|
| Eight-program normal chain with HF2 | `5d9a23aa756a7f90a1f943c9a044c0a3937c6a5e2e0dddc9e40f3233af0fd5f8` |
| Four unchanged recoveries | `35d81d74fa5bff735102d5dcc2f1466ab2bb55e989d3df9d46d4b032aef3262c` |
| Complete twelve-file SQL set | `32ee8c239b103355f50d1fd05e42818e8ccdd8052c7e8aec6092968fa71a1c9d` |

## Release validation

A second, separately coded physical readback—not merely acceptance of the generated PASS reports—produced:

```text
Independent physical controls        72 / 72 PASS
Blocking failures                     0

ZIP/extraction path mismatches         0
ZIP/extraction size mismatches         0
ZIP/extraction SHA-256 mismatches      0
Duplicate paths                        0
Case-insensitive duplicate paths       0
Unsafe paths                           0
Symbolic links                         0
Manifest mismatches                    0
manifest.json mismatches               0
SHA256SUMS mismatches                  0
Package-inventory mismatches           0
SQL-inventory mismatches               0
DDL/postflight column mismatches        0
```

## Required restart sequence

### 1. Preserve the failed HF1 evidence

Retain separately and unedited:

- the complete HF1 console transcript;
- the `P220_PF_0064_PERSISTENT_COLUMN` error;
- the client/process status;
- your stop action;
- the `ROLLBACK` response.

Do not overwrite those files with the HF2 evidence.

### 2. Use only the HF2 identities

For the next attempt, prohibited Program 220 identities are:

```text
Original
757462b1d3c323be9cbe3a98fd5c9a822719ca6e9a15b698644c0650b5413298

HF1
c6557ec52762762df556dffc935aa84792beace0d03c0da6696f5b5a152e7e7c
```

Required current identity:

```text
HF2
575a80207e8347003d4147be4f243c8179ef234fbc5034b3d272837b15ebfe40
```

### 3. Run the read-only rollback-state verifier first

Execute the entire physical file:

```text
220_HF2_pre_rerun_rollback_state_verification.sql
```

Require exactly:

```text
rollback_state_verification_status  PASS
residual_relations                  0
residual_routines                   0
residual_triggers                   0
predecessor_rows                    1
run_code                            M1_V0_2_BASELINE_BUILD
run_version                         1
run_status                          M2_11_ACCEPTED
contract_status                     ACCEPTED
disposition                         READY_TO_EXECUTE_PROGRAM_220_HF2
```

The verifier creates only transaction-local temporary state and ends with:

```sql
ROLLBACK;
```

Any other result or any exception is a hard stop.

### 4. Execute Program 220 HF2 only

After the verifier passes:

- execute the entire HF2 Program 220 file in one invocation;
- use first-error-stop behavior;
- add no outer transaction;
- do not concatenate Program 221;
- preserve the complete console transcript, process status, and primary result.

Required successful checkpoint remains:

```text
installation_status          PASS
installed_top_level_objects  21
executable_ddl_statements    26
policy_rows                  1
nonpolicy_rows               0
policy_identity              1
policy_sequence_state        1|true
run_status                   M2_11_ACCEPTED
disposition                  READY_FOR_PROGRAM_221
```

Program 221 remains conditional on exact reconciliation of this checkpoint. The governing authority retains the sequence `220 → 221 → 222 → 223 → 224 → 225 → 226 → 227`, and all recoveries remain separately controlled. [export reference: filecite | turn2file5 | L34-L46]

## Current boundary

```text
HF2 source/package construction       COMPLETE
Builder-side static validation        PASS
Separate physical readback            72 / 72 PASS
PostgreSQL execution of HF2            NOT PERFORMED HERE
Program 220 runtime success            NOT YET ESTABLISHED
Program 221 release                    NOT YET ESTABLISHED
M2.12 acceptance                       NOT CLAIMED
```

Proceed with the **HF2 rollback-state verifier first**, followed by **Program 220 HF2 only** after an exact PASS.
<!-- END_SOURCE_MESSAGE -->


<a id="m-944525a2-9c25-46d0-ad77-a4bd560d48c0"></a>
## Andrew / user · C085-M00031

C085-M00031 · 2026-08-10T21:24:54.839000-04:00 · active path

Preceding visible parent: [C085-M00030](part-02.md#m-4c4885ff-20b5-4a05-b077-cbd78c448a88)

<!-- BEGIN_SOURCE_MESSAGE -->
another error in program 220: SQL Error [42883]: ERROR: operator does not exist: name[] = text[]
  Hint: No operator matches the given name and argument types. You might need to add explicit type casts.
  Where: PL/pgSQL function inline_code_block line 3 at IF
  ERROR: operator does not exist: name[] = text[]
  Hint: No operator matches the given name and argument types. You might need to add explicit type casts.
  Where: PL/pgSQL function inline_code_block line 3 at IF          correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. 
<!-- END_SOURCE_MESSAGE -->


<a id="m-4837fdfa-0798-4a76-ace2-cddb4a2e110c"></a>
## Assistant · C085-M00032

C085-M00032 · 2026-08-10T21:25:10.491050-04:00 · active path

Preceding visible parent: [C085-M00031](part-02.md#m-944525a2-9c25-46d0-ad77-a4bd560d48c0)

<!-- BEGIN_SOURCE_MESSAGE -->
Your stop and rollback were correct. I’m scanning all HF2 catalog assertions for `name[]`/`text[]` mismatches before issuing superseding HF3 with fresh hashes and rollback-state controls.
<!-- END_SOURCE_MESSAGE -->


<a id="m-92c77db3-cf94-4ea4-8c99-bf7b543b528e"></a>
## Assistant · C085-M00033

C085-M00033 · 2026-08-10T21:28:14.698737-04:00 · active path

Preceding visible parent: [C085-M00032](part-02.md#m-4837fdfa-0798-4a76-ace2-cddb4a2e110c)

<!-- BEGIN_SOURCE_MESSAGE -->
The first failing structural postflight aggregates `pg_attribute.attname` as `name[]` against `text[]`; I found 68 affected aggregates across 38 blocks and will cast their elements to `text`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c472dc8a-e34e-452f-8fc6-1c4af9187ffd"></a>
## Assistant · C085-M00034

C085-M00034 · 2026-08-10T21:37:18.302235-04:00 · active path

Preceding visible parent: [C085-M00033](part-02.md#m-92c77db3-cf94-4ea4-8c99-bf7b543b528e)

<!-- BEGIN_SOURCE_MESSAGE -->
HF3 is physically built with Program 220 DDL and Programs 221–227 unchanged; independent package readback passed 108/108 controls. I’m completing one final catalog-type sweep before release.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c2d43633-b0b4-4565-ab29-39b85d208e26"></a>
## Assistant · C085-M00035

C085-M00035 · 2026-08-10T21:46:57.098371-04:00 · active path

Preceding visible parent: [C085-M00034](part-02.md#m-c472dc8a-e34e-452f-8fc6-1c4af9187ffd)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 220 HF3 — Hotfix complete

Your stop-and-rollback response was correct. The governing live-execution authority requires an immediate stop on any error and prohibits continuing, rerunning, issuing ad hoc SQL, or selecting a recovery without a new state-specific direction. [export reference: filecite | turn2file5 | L36-L50]

**Do not rerun the original Program 220, HF1, or HF2. HF3 supersedes all three for the next Program 220 attempt.**

## Downloads

### Superseding execution package

- Download M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF3.zip (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF3.zip`; referenced bytes not established here)
- Download the matching HF3 ZIP sidecar (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF3.zip.sha256`; referenced bytes not established here)

### Corrected Program 220 directly

- Download Program 220 HF3 SQL (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF3.sql`; referenced bytes not established here)
- Download the Program 220 HF3 SQL sidecar (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF3.sql.sha256`; referenced bytes not established here)

### Mandatory pre-rerun rollback-state verifier

- Download the HF3 rollback-state verifier (historical reference: `sandbox:[session]/220_HF3_pre_rerun_rollback_state_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/220_HF3_pre_rerun_rollback_state_verification.sql.sha256`; referenced bytes not established here)

### Validation records

- Download the HF3 release-validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF3_RELEASE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the separately coded physical-readback report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF3_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the physical-readback control record (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF3_INDEPENDENT_PHYSICAL_READBACK.json`; referenced bytes not established here)

## Root cause

The failing catalog column was:

```sql
pg_catalog.pg_attribute.attname
```

PostgreSQL defines `attname` as type `name`. Therefore, this expression:

```sql
array_agg(a.attname ORDER BY ...)
```

returns:

```text
name[]
```

The Program 220 postflight then compared that result with—or assigned it to—a `text[]` value:

```sql
ARRAY[...]::text[]
```

PostgreSQL does not provide an equality operator for:

```text
name[] = text[]
```

That caused SQLSTATE `42883`.

The first reachable affected check after the previous HF2 corrections was:

```text
P220_PF_0349_CONSTRAINT_OR_INDEX
```

## HF3 correction

HF3 changes each affected expression from:

```sql
array_agg(a.attname ORDER BY ...)
```

to:

```sql
array_agg(a.attname::text ORDER BY ...)
```

The cast is inside the aggregate, so the result is physically constructed as `text[]`. Column names and governed ordering remain unchanged.

This was not isolated to one assertion. The complete Program 220 source contained **68 affected expressions across 38 governed postflight blocks**:

| Expression family | Corrected expressions |
|---|---:|
| Constraint-key arrays | **23** |
| Index-key arrays | **21** |
| Referenced-key arrays | **10** |
| View-column arrays | **14** |
| **Total** | **68** |

A source-wide final scan produced:

```text
HF2 uncast attname aggregate expressions     68
HF3 residual uncast executable expressions    0
HF3 corrected ::text expressions             68
```

## Scope lock

| Control | Result |
|---|---:|
| Governed statements retained | **473** |
| Governed blocks changed versus HF2 | **38** |
| Governed blocks unchanged versus HF2 | **435** |
| Catalog aggregate expressions corrected | **68** |
| Persistent DDL changed | **0** |
| Table or view definitions changed | **0** |
| Constraint or index definitions changed | **0** |
| Transaction boundaries changed | **0** |
| Primary Program 220 result changed | **0** |
| HF1 view-postflight corrections retained | **PASS** |
| HF2 timestamp-type corrections retained | **PASS** |
| Programs 221–227 changed | **0** |
| Recovery sources changed | **0** |

Programs 221–227 and Recoveries 220A, 222A, 222B, and 223A remain byte-identical to HF2.

The original approved WP5 package remains the historical baseline identity—492,278 bytes, 98 entries, and SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`. [export reference: filecite | turn2file0 | L3-L8] It is no longer the executable Program 220 authority because its Program 220 source has now been superseded through HF1, HF2, and HF3.

## Physical delivery ledger

### Canonical HF3 ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF3.zip` |
| Bytes | **563,640** |
| SHA-256 | `4bffb496ec643e2e58991b709c250017ab1a5a8a203d9abdd0bc55f9b56de960` |
| ZIP file entries | **139** |
| Total uncompressed bytes | **4,223,495** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |

The ZIP sidecar contains exactly:

```text
4bffb496ec643e2e58991b709c250017ab1a5a8a203d9abdd0bc55f9b56de960  M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF3.zip
```

### Program 220 HF3

| Attribute | Physical result |
|---|---:|
| Filename | `220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF3.sql` |
| Bytes | **764,697** |
| SHA-256 | `42797c24ebd8d17b4551c26b23032b3a9433364f0a2c070cae81f9178a2f6b5a` |
| Governed statements | **473** |
| Changed blocks versus HF2 | **38** |
| Corrected expressions | **68** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

Its sidecar contains exactly:

```text
42797c24ebd8d17b4551c26b23032b3a9433364f0a2c070cae81f9178a2f6b5a  220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF3.sql
```

Inside the ZIP, the corrected source retains the canonical execution filename:

```text
01_sql_normal/
220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1.sql
```

That packaged file is byte-identical to the externally supplied `_HF3.sql` file and has the same SHA-256.

### Rollback-state verifier

| Attribute | Physical result |
|---|---:|
| Filename | `220_HF3_pre_rerun_rollback_state_verification.sql` |
| Bytes | **7,556** |
| SHA-256 | `d3d9fd88355feeae9854c7dc9893e9f6129ec588f37ad504f52cda12cee47ec1` |
| Expected Program 220 relations/sequences checked | **19** |
| Persistent CREATE operations | **0** |
| Persistent INSERT/UPDATE/DELETE operations | **0** |
| Final transaction action | **ROLLBACK** |

Its sidecar contains exactly:

```text
d3d9fd88355feeae9854c7dc9893e9f6129ec588f37ad504f52cda12cee47ec1  220_HF3_pre_rerun_rollback_state_verification.sql
```

### Updated SQL source-set identities

| Source set | SHA-256 |
|---|---|
| Eight-program normal chain with HF3 | `879fe50b81d3bc66ec4b650f3318819a7b7f1dfbefa83b1569f47b58a143525a` |
| Four unchanged recovery sources | `35d81d74fa5bff735102d5dcc2f1466ab2bb55e989d3df9d46d4b032aef3262c` |
| Complete twelve-file SQL set | `1c9e62234914b495f0fc05c8852f4e3f0334c389f0f97f2f9180c9edaf343759` |

## Independent physical/static release gate

A separately coded readback reopened the final ZIP, CRC-tested it, extracted it into a new directory, and recalculated its metadata and SQL identities.

```text
Independent controls                    108 / 108 PASS
Blocking failures                         0

Build/extraction path mismatches           0
Build/extraction size mismatches           0
Build/extraction SHA-256 mismatches        0
Duplicate ZIP paths                        0
Case-insensitive duplicate ZIP paths       0
Unsafe ZIP paths                           0
Symbolic links                             0
MANIFEST.csv mismatches                    0
manifest.json mismatches                   0
SHA256SUMS.txt mismatches                  0
PACKAGE_INVENTORY.csv mismatches           0
SQL source-inventory mismatches            0
Programs 221–227/recovery mismatches       0
Residual uncast attname expressions        0
```

Metadata record counts:

| Artifact | Records |
|---|---:|
| `MANIFEST.csv` | **135** |
| `manifest.json` | **135** |
| `SHA256SUMS.txt` | **137** |
| `PACKAGE_INVENTORY.csv` | **138** |
| SQL source inventory | **12** |

## Mandatory restart sequence

### 1. Preserve the failed HF2 evidence

Keep the following unedited and separate from HF3 evidence:

- complete HF2 console transcript;
- SQLSTATE `42883` error;
- client/process exit status;
- stop action;
- `ROLLBACK` response;
- any screenshots or result panes.

Do not overwrite the earlier original, HF1, or HF2 attempt records.

### 2. Prohibit all superseded Program 220 identities

Do not execute these Program 220 sources:

```text
Original R1
757462b1d3c323be9cbe3a98fd5c9a822719ca6e9a15b698644c0650b5413298

HF1
c6557ec52762762df556dffc935aa84792beace0d03c0da6696f5b5a152e7e7c

HF2
575a80207e8347003d4147be4f243c8179ef234fbc5034b3d272837b15ebfe40
```

The only current Program 220 identity is:

```text
HF3
42797c24ebd8d17b4551c26b23032b3a9433364f0a2c070cae81f9178a2f6b5a
```

### 3. Run the HF3 rollback-state verifier first

Execute the entire physical file:

```text
220_HF3_pre_rerun_rollback_state_verification.sql
```

Require exactly:

```text
rollback_state_verification_status  PASS
residual_relations                  0
residual_routines                   0
residual_triggers                   0
predecessor_rows                    1
run_code                            M1_V0_2_BASELINE_BUILD
run_version                         1
run_status                          M2_11_ACCEPTED
contract_status                     ACCEPTED
disposition                         READY_TO_EXECUTE_PROGRAM_220_HF3
```

The verifier ends with:

```sql
ROLLBACK;
```

Any exception, missing result, nonzero residual count, or predecessor mismatch is a hard stop.

### 4. Execute Program 220 HF3 only

After the verifier returns the exact PASS checkpoint:

1. Recalculate the SQL SHA-256 and require:

   ```text
   42797c24ebd8d17b4551c26b23032b3a9433364f0a2c070cae81f9178a2f6b5a
   ```

2. Execute the **entire HF3 Program 220 physical file** in one invocation.
3. Use first-error-stop behavior.
4. Add no outer transaction.
5. Do not concatenate or execute Program 221.
6. Preserve the complete console transcript, process status, and primary result.

Required Program 220 checkpoint remains:

```text
installation_status          PASS
installed_top_level_objects  21
executable_ddl_statements    26
policy_rows                  1
nonpolicy_rows               0
policy_identity              1
policy_sequence_state        1|true
run_status                   M2_11_ACCEPTED
disposition                  READY_FOR_PROGRAM_221
```

Program 221 remains conditionally authorized only after this complete checkpoint reconciles without ambiguity. The controlled chain remains `220 → 221 → 222 → 223 → 224 → 225 → 226 → 227`; recovery sources remain separately controlled and are not part of this restart. [export reference: filecite | turn2file5 | L36-L50]

## Current boundary

```text
HF3 source/package construction       COMPLETE
Builder static validation             PASS
Separate physical readback            108 / 108 PASS
PostgreSQL execution of HF3           NOT PERFORMED HERE
Program 220 runtime success           NOT YET ESTABLISHED
Program 221 release                   NOT YET ESTABLISHED
M2.12 acceptance                      NOT CLAIMED
```

Run the **HF3 rollback-state verifier first**, and then execute **Program 220 HF3 only** after the verifier returns the exact PASS result.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1157de89-ea1d-4b0b-96ea-f9c7fd3e7806"></a>
## Andrew / user · C085-M00036

C085-M00036 · 2026-08-10T21:51:42.513000-04:00 · active path

Preceding visible parent: [C085-M00035](part-02.md#m-c2d43633-b0b4-4565-ab29-39b85d208e26)

<!-- BEGIN_SOURCE_MESSAGE -->
another error in program 220: SQL Error [P0001]: ERROR: M2.12 Program 220 constraint structural postflight failed
  Detail: check_code=P220_STRUCT_CONSTRAINT_PK_M212_POLICY_PROFILE
  Hint: Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.
  Where: PL/pgSQL function inline_code_block line 49 at RAISE
  ERROR: M2.12 Program 220 constraint structural postflight failed
  Detail: check_code=P220_STRUCT_CONSTRAINT_PK_M212_POLICY_PROFILE
  Hint: Inspect the R9 structural postflight and diagnostic catalogs; do not compare original source spelling to PostgreSQL deparser output.
  Where: PL/pgSQL function inline_code_block line 49 at RAISE       correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. when correcting error, do not correct this error and stop, review the rest of program 220 for additional, similar/noticeable errors. 
<!-- END_SOURCE_MESSAGE -->


<a id="m-f46fb169-d2e1-4a45-aa77-930e5a85757d"></a>
## Assistant · C085-M00037

C085-M00037 · 2026-08-10T21:51:57.348885-04:00 · active path

Preceding visible parent: [C085-M00036](part-02.md#m-1157de89-ea1d-4b0b-96ea-f9c7fd3e7806)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m tracing the failing constraint postflight against PostgreSQL catalog/deparser semantics, then auditing all remaining Program 220 structural checks before issuing the superseding hotfix.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2f6ec0c3-4947-4d99-b1da-ae09918cdc9f"></a>
## Assistant · C085-M00038

C085-M00038 · 2026-08-10T21:55:00.918098-04:00 · active path

Preceding visible parent: [C085-M00037](part-02.md#m-f46fb169-d2e1-4a45-aa77-930e5a85757d)

<!-- BEGIN_SOURCE_MESSAGE -->
The audit now includes constraints, indexes, triggers, routines, sequences, and views against an actual PostgreSQL 15 catalog model before HF4 release.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3252b69a-108e-416f-95ca-940a1fb7633a"></a>
## Assistant · C085-M00039

C085-M00039 · 2026-08-10T22:38:58.589687-04:00 · active path

Preceding visible parent: [C085-M00038](part-02.md#m-2f6ec0c3-4947-4d99-b1da-ae09918cdc9f)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 220 HF4 — Hotfix complete

Your stop-and-rollback response was correct. The controlled-execution authority requires an immediate stop on any error and prohibits rerunning, ad hoc SQL changes, recovery selection, or proceeding to Program 221 until the Program 220 checkpoint is exact. [export reference: filecite | turn2file5 | L34-L50]

**Do not execute the original Program 220, HF1, HF2, or HF3 again. HF4 supersedes all four for the next Program 220 attempt.**

## Downloads

### Superseding standalone execution package

- Download M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF4.zip (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF4.zip`; referenced bytes not established here)
- Download the matching HF4 ZIP sidecar (historical reference: `sandbox:[session]/M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF4.zip.sha256`; referenced bytes not established here)

### Corrected Program 220 HF4

- Download Program 220 HF4 SQL (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql`; referenced bytes not established here)
- Download the Program 220 HF4 SQL sidecar (historical reference: `sandbox:[session]/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql.sha256`; referenced bytes not established here)

### Mandatory pre-rerun rollback-state verifier

- Download the HF4 rollback-state verifier (historical reference: `sandbox:[session]/220_HF4_pre_rerun_rollback_state_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/220_HF4_pre_rerun_rollback_state_verification.sql.sha256`; referenced bytes not established here)

### Validation and expanded review records

- Download the HF4 release-validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF4_RELEASE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the separately coded physical-readback report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF4_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the physical-readback JSON (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF4_INDEPENDENT_PHYSICAL_READBACK.json`; referenced bytes not established here)
- Download the complete 473-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF4_FULL_PROGRAM_REVIEW.csv`; referenced bytes not established here)
- Download the complete-review summary (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF4_FULL_PROGRAM_REVIEW_SUMMARY.json`; referenced bytes not established here)
- Download the expanded structural-tail review (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_HF4_EXPANDED_STRUCTURAL_REVIEW.csv`; referenced bytes not established here)

## Root cause

The failing HF3 primary-key postflight asserted:

```sql
AND bool_and(NOT c.connoinherit)
```

against the `pg_constraint` catalog row for:

```text
pk_m212_policy_profile
```

In PostgreSQL, `pg_constraint.connoinherit=true` identifies a non-inheritable constraint. PostgreSQL’s `CREATE TABLE` grammar permits an explicit `NO INHERIT` option for CHECK constraints, whereas primary-key, unique, and foreign-key constraints are structurally non-inheritable constraint types. The postflight therefore had the catalog expectation reversed for the primary key. [export reference: cite | turn290636view0 | turn290636view1]

This was **not** isolated to the named primary key. The same erroneous expectation appeared in all 23 deep structural postflights for:

| Constraint family | Corrected blocks |
|---|---:|
| Primary keys | **9** |
| Unique constraints | **4** |
| Foreign keys | **10** |
| **Total** | **23** |

HF4 changes those assertions to:

```sql
AND bool_and(c.connoinherit)
```

The 34 CHECK-constraint blocks remain:

```sql
AND bool_and(NOT c.connoinherit)
```

because their physical DDL does not specify `NO INHERIT`.

## Broader Program 220 review

The review did not stop after correcting `PK_M212_POLICY_PROFILE`.

| Review scope | Result |
|---|---:|
| Governed statements reviewed | **473 / 473 PASS** |
| Persistent DDL statements | **26 / 26 PASS** |
| Persistent tables | **9 / 9 reconciled** |
| Persistent table columns | **327 / 327 PASS** |
| Top-level object checks | **21 / 21 PASS** |
| Constraint structural checks | **57 / 57 PASS** |
| Primary keys | **9 / 9 PASS** |
| Unique constraints | **4 / 4 PASS** |
| Foreign keys | **10 / 10 PASS** |
| CHECK constraints | **34 / 34 PASS** |
| Standalone indexes | **8 / 8 PASS** |
| Identity sequences | **3 / 3 PASS** |
| Persistent views | **7 / 7 PASS** |
| Archive function | **1 / 1 PASS** |
| Archive trigger | **1 / 1 PASS** |
| Exact policy row | **1 / 1 PASS** |
| Primary result | **1 / 1 PASS** |
| Final commit | **1 / 1 PASS** |
| Additional source changes indicated | **0** |

The review also reconfirmed the earlier corrections:

- HF1’s seven view-dependency aggregation corrections remain intact.
- HF2’s 14 canonical `timestamp with time zone` catalog comparisons remain intact.
- HF3’s 68 explicit `a.attname::text` array-aggregation casts remain intact.
- Residual executable uncast `attname` aggregates: **0**.
- Residual affected false `connoinherit` assertions: **0**.

## Scope lock

| Control | Result |
|---|---:|
| Governed statements changed versus HF3 | **23** |
| Governed statements unchanged versus HF3 | **450** |
| Persistent DDL changed | **0** |
| Table definitions changed | **0** |
| Constraint definitions changed | **0** |
| Index definitions changed | **0** |
| View definitions changed | **0** |
| Policy-source or policy-insert logic changed | **0** |
| Transaction boundaries changed | **0** |
| Primary result changed | **0** |
| Programs 221–227 changed | **0** |
| Recoveries 220A, 222A, 222B, and 223A changed | **0** |

The original approved WP5 R1 ZIP remains the historical baseline with SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn2file0 | L5-L8] HF4 supersedes only its executable Program 220 authority; Programs 221–227 and all four recoveries remain preserved.

## Physical delivery ledger

### HF4 standalone ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF4.zip` |
| Bytes | **598,203** |
| SHA-256 | `8ed3c2e7c15eeefdae1aa02b87bc07c2229e0325bc6f6b04c2646532b3a01b6a` |
| ZIP entries | **155** |
| Total uncompressed bytes | **4,481,185** |
| ZIP CRC | **PASS** |
| Complete fresh extraction | **PASS** |

The external sidecar contains exactly:

```text
8ed3c2e7c15eeefdae1aa02b87bc07c2229e0325bc6f6b04c2646532b3a01b6a  M2_12_STANDALONE_READY_FOR_EXECUTION_R1_HF4.zip
```

### Program 220 HF4

| Attribute | Physical result |
|---|---:|
| Filename | `220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql` |
| Bytes | **765,772** |
| SHA-256 | `efc49c1f2c02587e03a84b46ab8c5c0b097ca28cd2682cd6f4eb477e29f508e8` |
| Governed statements | **473** |
| Changed versus HF3 | **23** |
| Unchanged versus HF3 | **450** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

Its sidecar contains exactly:

```text
efc49c1f2c02587e03a84b46ab8c5c0b097ca28cd2682cd6f4eb477e29f508e8  220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql
```

Inside the ZIP, the same bytes appear under the canonical execution path:

```text
01_sql_normal/
220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1.sql
```

### Rollback-state verifier

| Attribute | Physical result |
|---|---:|
| Filename | `220_HF4_pre_rerun_rollback_state_verification.sql` |
| Bytes | **7,556** |
| SHA-256 | `34551ac4c6549944c0bbf853913919697415f38063aec85f431259ff697594e1` |
| Expected relation/sequence inventory | **19** |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Final transaction action | **ROLLBACK** |

Its sidecar contains exactly:

```text
34551ac4c6549944c0bbf853913919697415f38063aec85f431259ff697594e1  220_HF4_pre_rerun_rollback_state_verification.sql
```

### SQL source-set identities

| Source set | SHA-256 |
|---|---|
| Eight-program normal chain with HF4 | `979785c56c6db36d6befef7b2012efc9eaf89b43c2ae1e9e7d165a2ae4f38f76` |
| Four unchanged recoveries | `35d81d74fa5bff735102d5dcc2f1466ab2bb55e989d3df9d46d4b032aef3262c` |
| Complete twelve-file SQL set | `91a748d0982f39549b60ea3202f32869be88c7d357c0c7f176a9f4ea68d7ead3` |

## Separate physical release gate

A separately coded readback reopened the final ZIP, CRC-tested it, extracted it into a new workspace, and independently recalculated the source and metadata identities:

```text
Independent controls                     246 / 246 PASS
Blocking failures                          0

Build/extraction path mismatches            0
Build/extraction size mismatches            0
Build/extraction SHA-256 mismatches         0
Duplicate ZIP paths                         0
Case-insensitive duplicate ZIP paths        0
Unsafe ZIP paths                            0
Symbolic links                              0
MANIFEST.csv mismatches                     0
manifest.json mismatches                    0
SHA256SUMS.txt mismatches                   0
PACKAGE_INVENTORY.csv mismatches            0
SQL source-inventory mismatches             0
Downstream SQL mismatches                   0
Recovery SQL mismatches                     0
Full-program review failures                0
```

Package metadata counts:

| Metadata authority | Records |
|---|---:|
| `MANIFEST.csv` | **151** |
| `manifest.json` | **151** |
| `SHA256SUMS.txt` | **153** |
| `PACKAGE_INVENTORY.csv` | **154** |

## Superseded Program 220 identities

Do not execute any of these:

```text
Original R1
757462b1d3c323be9cbe3a98fd5c9a822719ca6e9a15b698644c0650b5413298

HF1
c6557ec52762762df556dffc935aa84792beace0d03c0da6696f5b5a152e7e7c

HF2
575a80207e8347003d4147be4f243c8179ef234fbc5034b3d272837b15ebfe40

HF3
42797c24ebd8d17b4551c26b23032b3a9433364f0a2c070cae81f9178a2f6b5a
```

The only current Program 220 identity is:

```text
HF4
efc49c1f2c02587e03a84b46ab8c5c0b097ca28cd2682cd6f4eb477e29f508e8
```

## Mandatory restart sequence

### 1. Preserve the failed HF3 evidence

Keep the following unchanged and separate from the HF4 evidence:

- complete HF3 console transcript;
- SQLSTATE `P0001` error;
- failing check code;
- client/process status;
- stop action;
- `ROLLBACK` response;
- any screenshots or result panes.

### 2. Run the HF4 rollback-state verifier first

Execute the complete physical file:

```text
220_HF4_pre_rerun_rollback_state_verification.sql
```

Require exactly one result row with:

```text
rollback_state_verification_status  PASS
residual_relations                  0
residual_routines                   0
residual_triggers                   0
predecessor_rows                    1
run_code                            M1_V0_2_BASELINE_BUILD
run_version                         1
run_status                          M2_11_ACCEPTED
contract_status                     ACCEPTED
disposition                         READY_TO_EXECUTE_PROGRAM_220_HF4
```

The verifier ends with:

```sql
ROLLBACK;
```

Any exception, missing result, residual object, or predecessor mismatch is a hard stop.

### 3. Execute Program 220 HF4 only

After the verifier returns the exact PASS result:

1. Recalculate the Program 220 physical SHA-256 and require:

   ```text
   efc49c1f2c02587e03a84b46ab8c5c0b097ca28cd2682cd6f4eb477e29f508e8
   ```

2. Execute the entire HF4 Program 220 file in one invocation.
3. Use first-error-stop behavior.
4. Add no outer transaction.
5. Do not concatenate or execute Program 221.
6. Preserve the complete console transcript, client/process status, and primary result.

Required Program 220 checkpoint:

```text
installation_status          PASS
installed_top_level_objects  21
executable_ddl_statements    26
policy_rows                  1
nonpolicy_rows               0
policy_identity              1
policy_sequence_state        1|true
disposition                  READY_FOR_PROGRAM_221
```

The governed run must remain:

```text
M2_11_ACCEPTED
```

Program 221 remains conditional on exact Program 220 reconciliation. Recoveries remain outside the normal chain and unauthorized absent a separately diagnosed, named, and hashed recovery authorization.

## Current boundary

```text
HF4 construction                         COMPLETE
Broader 473-statement static review      473 / 473 PASS
Separate physical release controls       246 / 246 PASS
PostgreSQL execution of HF4              NOT PERFORMED HERE
Program 220 HF4 runtime success          NOT YET ESTABLISHED
Program 221 release                      NOT YET ESTABLISHED
M2.12 runtime validation                 NOT YET ESTABLISHED
M2.12 acceptance                         NOT CLAIMED
```

Proceed with the **HF4 rollback-state verifier first**, followed by **Program 220 HF4 only** after the verifier returns the exact required PASS checkpoint.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d48a47b5-e44d-4d4d-a3cd-5d5ea2629f57"></a>
## Andrew / user · C085-M00040

C085-M00040 · 2026-08-10T22:45:34.613000-04:00 · active path

Preceding visible parent: [C085-M00039](part-02.md#m-3252b69a-108e-416f-95ca-940a1fb7633a)

<!-- BEGIN_SOURCE_MESSAGE -->
220 ran correctly but I cannot export the results because the tmp file no longer exists...SQL Error [42P01]: ERROR: relation "tmp_install_m2_12_run_context" does not exist
  Position: 996
  ERROR: relation "tmp_install_m2_12_run_context" does not exist
  Position: 996    i do not like how you do that where you do not let me export what I can see in the results window 
<!-- END_SOURCE_MESSAGE -->


<a id="m-3542c8f7-b0ee-44d5-ae48-d166bb677ca1"></a>
## Assistant · C085-M00041

C085-M00041 · 2026-08-10T22:45:50.735116-04:00 · active path

Preceding visible parent: [C085-M00040](part-02.md#m-d48a47b5-e44d-4d4d-a3cd-5d5ea2629f57)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m checking HF4’s final-result logic now. The goal is to preserve the successful Program 220 state and recover exportable evidence without rerunning or mutating anything.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f37f7385-7d2d-4d68-8a8c-dff64bff82ec"></a>
## Assistant · C085-M00042

C085-M00042 · 2026-08-10T22:48:57.841053-04:00 · active path

Preceding visible parent: [C085-M00041](part-02.md#m-3542c8f7-b0ee-44d5-ae48-d166bb677ca1)

<!-- BEGIN_SOURCE_MESSAGE -->
The `42P01` occurred only when the post-commit export reissued a query after its `ON COMMIT DROP` helper disappeared; I’m checking Programs 221–227 for the same trap.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f8b44a42-9f97-45a8-92db-52600ff21e07"></a>
## Assistant · C085-M00043

C085-M00043 · 2026-08-10T23:00:55.257772-04:00 · active path

Preceding visible parent: [C085-M00042](part-02.md#m-f37f7385-7d2d-4d68-8a8c-dff64bff82ec)

<!-- BEGIN_SOURCE_MESSAGE -->
You are right. **The Program 220 result-delivery design was defective from an operator-evidence standpoint.**

Program 220 HF4 itself succeeded and committed. The later `42P01` was caused by trying to execute its final result query again after:

```sql
COMMIT;
```

had removed:

```sql
tmp_install_m2_12_run_context ON COMMIT DROP
```

That is an **export/requery failure**, not a Program 220 execution failure.

## Do not rerun Program 220

Do **not**:

- rerun Program 220 HF4;
- run Recovery 220A;
- interpret the later `42P01` as a failed installation;
- attempt to undo the already committed Program 220 transaction.

Preserve these as separate evidence events:

1. successful Program 220 HF4 execution and commit;
2. subsequent failed attempt to requery the destroyed temporary result source.

The original WP5 R1 baseline remains physically identified by SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 ZIP entries, and passing CRC. [export reference: filecite | turn2file0 | L5-L8] Program 220 HF4 is the superseding executed source, while Programs 221–227 remain conditional on complete prior-program evidence. [export reference: filecite | turn2file5 | L34-L50]

# First try: export the row already visible in DBeaver

If the original successful result grid is still open:

1. Right-click **inside the result grid**, not inside the SQL editor.
2. Select **Export data**.
3. Select CSV.
4. In the extraction settings, enable **Use fetched rows**.
5. Disable **Query the database**.
6. Do not enable **Open new connection(s)**.
7. Export it as:

```text
220_primary_result.csv
```

DBeaver documents that **Query the database** executes the query again, while **Use fetched rows** exports the records already loaded into the result set. That distinction is exactly what matters here. [export reference: cite | turn657365view0]

Do not use **Execute → Export from Query** for this particular result because that works from the SQL query and can reproduce the missing-temporary-table error. Export from the existing grid using fetched rows instead. [export reference: cite | turn657365view0]

# Persistent-state fallback exporter

If the original result tab is gone—or DBeaver has already replaced it with the error result—I created a read-only exporter that reconstructs the exact Program 220 primary result from persistent state.

- Download the Program 220 post-execution result exporter (historical reference: `sandbox:[session]/220_m2_12_post_execution_primary_result_export_v1.sql`; referenced bytes not established here)
- Download its SHA-256 sidecar (historical reference: `sandbox:[session]/220_m2_12_post_execution_primary_result_export_v1.sql.sha256`; referenced bytes not established here)

Physical identity:

```text
Filename:
220_m2_12_post_execution_primary_result_export_v1.sql

Bytes:
10,955

SHA-256:
56bbcc1d78f3c5fe630e75599ca853069e5f3013ca3a2e7d9d8d7950d7ddbc36
```

This exporter:

- does **not** rerun Program 220;
- references **no temporary relations**;
- creates no temporary or persistent object;
- performs no `INSERT`, `UPDATE`, `DELETE`, `MERGE`, `TRUNCATE`, DDL, or sequence reset;
- verifies the unique governed run;
- verifies the exact approved policy row;
- verifies zero nonpolicy target rows;
- verifies all three owned sequence states;
- verifies the 19 expected relations/sequences, rejection function, and archive trigger;
- fails closed unless the Program 220 post-commit checkpoint is exact;
- ends with the exact ten-column Program 220 primary-result projection.

I physically and statically validated it, but I could not execute it against your PostgreSQL database from here.

## Expected exporter result

It must return exactly one row:

```text
installation_status          PASS
run_code                     M1_V0_2_BASELINE_BUILD
run_version                  1
installed_top_level_objects  21
executable_ddl_statements    26
policy_rows                  1
nonpolicy_rows               0
policy_identity              1
policy_sequence_state        1|true
disposition                  READY_FOR_PROGRAM_221
```

Anything else is a stop condition.

# Packaged correction records

- Download the complete Program 220 export-recovery bundle (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_POST_EXECUTION_EXPORT_E1.zip`; referenced bytes not established here)
- Download the bundle sidecar (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_POST_EXECUTION_EXPORT_E1.zip.sha256`; referenced bytes not established here)
- Download the operator recovery protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_RESULT_EXPORT_RECOVERY_AND_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Download the downstream result-exportability audit (historical reference: `sandbox:[session]/M2_12_RESULT_EXPORTABILITY_AUDIT.csv`; referenced bytes not established here)
- Download the exporter validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_POST_EXECUTION_EXPORT_VALIDATION.md`; referenced bytes not established here)
- Download the machine-readable validation record (historical reference: `sandbox:[session]/M2_12_PROGRAM_220_POST_EXECUTION_EXPORT_VALIDATION.json`; referenced bytes not established here)

Bundle identity:

```text
Filename:
M2_12_PROGRAM_220_POST_EXECUTION_EXPORT_E1.zip

Bytes:
10,445

SHA-256:
b33fdc955d0ef8cab83ba39b0eea327d4c1275b586f4f6ff7d3dc316f5864f0b

ZIP entries:
14

Total uncompressed bytes:
19,547

ZIP CRC/readback:
PASS
```

# I also reviewed Programs 221–227

Your criticism exposed a broader operator-design issue:

| Program | Current result behavior |
|---|---|
| **220** | Result selected before commit from an `ON COMMIT DROP` helper; cannot be requeried afterward. |
| **221** | Same vulnerability: final row depends on `ON COMMIT DROP` temporary helpers. |
| **222** | Same vulnerability: final row depends on an `ON COMMIT DROP` persistence-result helper. |
| **223** | Results are selected after commit from session-preserved temporary tables; available only while the originating session remains alive. |
| **224** | Same session-preserved behavior. |
| **225** | Same session-preserved behavior. |
| **226** | Same session-preserved behavior. |
| **227** | Twenty-four result sets are emitted before commit and substantially depend on temporary helpers; they cannot safely be requeried after commit. |

I did **not** silently modify Programs 221–227 merely to alter export mechanics, because doing so during live execution would change their governed hashes and source authorities. Instead, for the remainder of M2.12:

```text
Export from each visible result grid.
Choose Use fetched rows.
Disable Query the database.
Do not open a new export connection.
Export before closing the result tab or database session.
```

For Program 227, export every governed result set separately before closing the session, including header-only Result Sets 23 and 24.

**Program 221 remains held until the exact Program 220 row has been exported and reconciled. Send that exported row before executing Program 221.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-f11eb414-7a19-4a27-b62f-84feee5574a9"></a>
## Andrew / user · C085-M00044

C085-M00044 · 2026-08-10T23:03:08.599000-04:00 · active path

Preceding visible parent: [C085-M00043](part-02.md#m-f8b44a42-9f97-45a8-92db-52600ff21e07)

<!-- BEGIN_SOURCE_MESSAGE -->
using fetched rows worked. thanks.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a29f4477-8f6d-4406-bbf9-4db97755d8a7"></a>
## Assistant · C085-M00045

C085-M00045 · 2026-08-10T23:03:52.982459-04:00 · active path

Preceding visible parent: [C085-M00044](part-02.md#m-f11eb414-7a19-4a27-b62f-84feee5574a9)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. That preserves the **actual successful Program 220 result without rerunning any SQL**.

Keep these together in the Program 220 evidence folder:

- the exported `220_primary_result.csv`;
- the original successful HF4 transcript and commit;
- the client/process status;
- the later `42P01` requery error, labeled as an **export-attempt anomaly after successful commit**, not a Program 220 execution failure.

Program 221 should remain paused until the exported Program 220 row is reconciled against the required checkpoint.
<!-- END_SOURCE_MESSAGE -->


<a id="m-44f11bf1-c1d3-4ab9-9808-ce4a5d16e2e4"></a>
## Andrew / user · C085-M00046

C085-M00046 · 2026-08-10T23:06:32.954000-04:00 · active path

Preceding visible parent: [C085-M00045](part-02.md#m-a29f4477-8f6d-4406-bbf9-4db97755d8a7)

**Editorial record note:** Attachment references: 220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4_results_20260810.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 221: SQL Error [P0001]: ERROR: M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_gate_catalog
  Detail: expected=1 observed=34
  Where: PL/pgSQL function inline_code_block line 1 at RAISE
  ERROR: M2.12 R7 helper row-count mismatch: tmp_preflight_m2_12_gate_catalog
  Detail: expected=1 observed=34
  Where: PL/pgSQL function inline_code_block line 1 at RAISE     correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. when correcting error, do not correct this error and stop, review the rest of program 221 for additional, similar/noticeable errors. 220 evidence attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-468df6d2-577c-4081-b17a-6f4af07fc131"></a>
## Assistant · C085-M00047

C085-M00047 · 2026-08-10T23:06:47.695702-04:00 · active path

Preceding visible parent: [C085-M00046](part-02.md#m-44f11bf1-c1d3-4ab9-9808-ce4a5d16e2e4)

<!-- BEGIN_SOURCE_MESSAGE -->
Your stop-and-rollback was correct. I’m reconciling Program 220 evidence and reviewing the entire Program 221 preflight for related helper-scope/cardinality defects before issuing a superseding hotfix.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bea6d311-04cb-4c67-939c-00b84d5f541a"></a>
## Assistant · C085-M00048

C085-M00048 · 2026-08-10T23:09:52.949746-04:00 · active path

Preceding visible parent: [C085-M00047](part-02.md#m-468df6d2-577c-4081-b17a-6f4af07fc131)

<!-- BEGIN_SOURCE_MESSAGE -->
Program 220 evidence reconciles exactly. The 221 defect is confirmed: all 34 enterprise gates populated a single-G3 helper; I’m also checking source-edge registry lookups for nonuniqueness.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e77e7702-e2c7-4072-9d01-f036dd233588"></a>
## Assistant · C085-M00049

C085-M00049 · 2026-08-10T23:18:57.669776-04:00 · active path

Preceding visible parent: [C085-M00048](part-02.md#m-bea6d311-04cb-4c67-939c-00b84d5f541a)

<!-- BEGIN_SOURCE_MESSAGE -->
The broader review found additional blockers: obsolete M1.17/M2.2 registry column names and two M2.3/M2.4 stage-specific hash-name mismatches. I’m correcting those physical mappings now.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ffad494c-7db8-4971-ae2e-30562079bd00"></a>
## Assistant · C085-M00050

C085-M00050 · 2026-08-10T23:46:04.177094-04:00 · active path

Preceding visible parent: [C085-M00049](part-02.md#m-e77e7702-e2c7-4072-9d01-f036dd233588)

<!-- BEGIN_SOURCE_MESSAGE -->
Accepted-source reconciliation now covers all 13 contracts and 19 edges, including a Cartesian-count fix. Independent readback exposed invalid PASS metadata, so I’m rebuilding its validation logic before release.
<!-- END_SOURCE_MESSAGE -->


<a id="m-25b84c16-6629-49b3-aff4-ead07516ba9e"></a>
## Assistant · C085-M00051

C085-M00051 · 2026-08-10T23:53:37.519351-04:00 · active path

Preceding visible parent: [C085-M00050](part-02.md#m-ffad494c-7db8-4971-ae2e-30562079bd00)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 221 HF5 — Hotfix complete

Your stop-and-rollback response was correct. The attached Program 220 result row reconciles exactly to the successful checkpoint: `PASS`, 21 installed objects, 26 DDL statements, one policy row, sequence state `1|true`, and `READY_FOR_PROGRAM_221`. [export reference: filecite | turn5file0 | L10-L11]

**Do not rerun Program 220. Do not rerun the original Program 221.** The governing execution authority requires an immediate stop on any error and makes each later program conditional on exact reconciliation of the preceding checkpoint. [export reference: filecite | turn2file5 | L34-L50]

## Downloads

### Superseding continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF5.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF5.zip`; referenced bytes not established here)
- Download the matching ZIP sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF5.zip.sha256`; referenced bytes not established here)

This is intentionally a **continuation package**, not another complete standalone package. It contains no executable Program 220 and no recovery SQL, reducing the chance of accidentally rerunning completed work.

### Program 221 HF5 directly

- Download Program 221 HF5 SQL (historical reference: `sandbox:[session]/221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF5.sql`; referenced bytes not established here)
- Download the Program 221 HF5 sidecar (historical reference: `sandbox:[session]/221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF5.sql.sha256`; referenced bytes not established here)

### Mandatory pre-rerun verifier

- Download the Program 221 HF5 state verifier (historical reference: `sandbox:[session]/221_HF5_pre_rerun_state_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/221_HF5_pre_rerun_state_verification.sql.sha256`; referenced bytes not established here)

### Review and validation records

- Download the HF5 validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF5_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the separate physical/static readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF5_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the 75-control readback record (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF5_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Download the complete 76-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF5_FULL_PROGRAM_REVIEW.csv`; referenced bytes not established here)
- Download the 865-reference physical-schema reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF5_PHYSICAL_SCHEMA_RECONCILIATION.csv`; referenced bytes not established here)

## Reported error and immediate correction

The superseded Program 221 constructed:

```sql
tmp_preflight_m2_12_gate_catalog
```

from the entire enterprise gate catalog without a predicate. The live database contains 34 gate rows, while the helper’s governed contract required the single G3 gate row.

HF5 adds the exact scope:

```sql
WHERE g.gate_id = 'G3_M2_CONTRACT'
```

This changes the helper from 34 rows to the required one-row contract.

## Broader Program 221 review

The review did not stop at the reported gate error.

### 1. Physical registry-column defects

The approved Program 221 contained **64 executable invalid physical-column references**. These are repeated occurrences across 24 statement/branch mappings and 15 physical relation/column pairs—not 64 unrelated business-design defects.

| Accepted registry | Invalid occurrences corrected | Physical correction |
|---|---:|---|
| M1.17 G2 bundle registry | **26** | Uses `bundle_code`, `bundle_version`, `bundle_status`, `combined_g2_hash`, `bundle_latest_set_hash`, and `bundle_archive_set_hash` |
| M2.2 pricing/request registry | **34** | Uses the separate `request_*` and `pricing_*` contract, latest, archive, and contract-set fields |
| M2.3 final-decision registry | **2** | Uses `decision_latest_set_hash` and `decision_archive_set_hash` |
| M2.4 activation registry | **2** | Uses `activation_latest_set_hash` and `activation_archive_set_hash` |
| **Total** | **64** | HF5 residual invalid references: **0** |

The physical-schema audit reviewed **865 executable reference occurrences** against the accepted source DDL and found zero unresolved references in HF5.

### 2. Node-level Cartesian multiplication

The original node helper joined component rows directly to source-edge rows before aggregation. A node with multiple components and multiple incoming edges could therefore multiply rows and inflate:

- required component counts;
- passed component counts;
- observed source-edge counts;
- passed source-edge counts.

HF5 independently aggregates components and edges first, then joins the two node-level aggregates. This preserves the intended 12-node cardinality and prevents cross-product inflation.

### 3. Result exportability

Program 221 originally had the same operator-evidence weakness exposed after Program 220: its final result dependencies were scheduled for deletion at commit.

HF5 changes exactly two temporary tables to:

```sql
ON COMMIT PRESERVE ROWS
```

Those are:

```text
tmp_preflight_m2_12_run_context
tmp_preflight_m2_12_result
```

The primary row can therefore be requeried after commit **from the same database session**. Continue using DBeaver’s **Use fetched rows** export option because a new connection still cannot see session-local temporary tables.

## Bounded source changes

Exactly six governed statement bodies changed:

| Statement | Correction |
|---:|---|
| **15** | Restrict gate helper to `G3_M2_CONTRACT` |
| **27** | Preserve final run-context dependency through commit |
| **39** | Correct all affected component-registry physical mappings |
| **55** | Correct M1.17 source-edge status mappings to `bundle_status` |
| **63** | Remove component-by-edge multiplication |
| **71** | Preserve final result helper through commit |

Results:

```text
Governed statements retained          76
Changed governed statements            6
Unchanged governed statements         70
Component branches                    13
Source-edge branches                  19
Certification nodes                   12
Result assertions                     48
Temporary tables                      18
Persistent DML operations              0
Persistent DDL operations              0
```

Programs 222–227 remain byte-identical and conditional.

## Physical delivery ledger

### Continuation ZIP

| Attribute | Result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF5.zip` |
| Bytes | **228,509** |
| SHA-256 | `9773ba2e7a90d44b205ab81e5e4b9ec2d5b458e0e59a1717e6df6ce27a790f02` |
| ZIP entries | **37** |
| Total uncompressed bytes | **2,263,499** |
| ZIP CRC | **PASS** |
| Complete fresh extraction | **PASS** |

The sidecar contains exactly:

```text
9773ba2e7a90d44b205ab81e5e4b9ec2d5b458e0e59a1717e6df6ce27a790f02  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF5.zip
```

### Program 221 HF5

| Attribute | Result |
|---|---:|
| Bytes | **210,933** |
| SHA-256 | `42b059a8e68a2243115377cd3839bdd1fb73d84233f9a848267cba96a4dbb933` |
| Governed statements | **76** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

The superseded Program 221 identity is:

```text
774f96643c16a8f2191b057afa01f311c1b663f79e2bf353dcd0d6cd5cc6c909
```

The only current Program 221 source for the next attempt is:

```text
42b059a8e68a2243115377cd3839bdd1fb73d84233f9a848267cba96a4dbb933
```

### Pre-rerun verifier

| Attribute | Result |
|---|---:|
| Bytes | **12,929** |
| SHA-256 | `06a4d9eb69e4d81df5cc2945f23b6aa94a6349fa048770d54522e59aa396fb97` |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Final transaction action | **ROLLBACK** |

### Validation

```text
Builder-side controls                 44 / 44 PASS
Separate physical/static controls     75 / 75 PASS
Blocking failures                      0

ZIP/extraction path mismatches          0
ZIP/extraction size mismatches          0
ZIP/extraction SHA-256 mismatches       0
Duplicate paths                         0
Case-insensitive duplicate paths        0
Unsafe paths                            0
Symbolic links                          0
MANIFEST.csv mismatches                 0
manifest.json mismatches                0
SHA256SUMS.txt mismatches                0
PACKAGE_INVENTORY.csv mismatches        0
```

## Mandatory restart sequence

### 1. Preserve the failed original Program 221 evidence

Retain unchanged:

```text
original Program 221 transcript
SQLSTATE P0001
expected=1 observed=34
client/process status
stop action
ROLLBACK response
```

Do not overwrite it with HF5 evidence.

### 2. Run the state verifier

Execute the complete physical file:

```text
221_HF5_pre_rerun_state_verification.sql
```

Require exactly one row with:

```text
state_verification_status       PASS
predecessor_rows                1
run_code                        M1_V0_2_BASELINE_BUILD
run_version                     1
run_status                      M2_11_ACCEPTED
contract_status                 ACCEPTED
installed_top_level_objects     21
policy_rows                     1
nonpolicy_rows                  0
m2_12_evidence_rows             0
g3_result_rows                  0
gate_rows                       1
exact_gate_rows                 1
policy_sequence_state           1|true
archive_sequence_state          1|false
registry_sequence_state         1|false
disposition                     READY_TO_EXECUTE_PROGRAM_221_HF5
```

Any difference is a hard stop.

### 3. Execute Program 221 HF5 only

After the verifier passes:

1. Recalculate the SQL SHA-256 and require:

   ```text
   42b059a8e68a2243115377cd3839bdd1fb73d84233f9a848267cba96a4dbb933
   ```

2. Execute the complete file once.
3. Use first-error-stop behavior.
4. Add no outer transaction.
5. Do not concatenate Program 222.
6. Preserve the full transcript and process status.
7. Export the visible result using **Use fetched rows**.

Required primary result:

```text
preflight_status          PASS
run_code                  M1_V0_2_BASELINE_BUILD
run_version               1
run_status                M2_11_ACCEPTED
assertion_rows            48
assertions_passed         48
source_edges              19
component_contracts       13
certification_nodes       12
mandatory_evidence_rows   72
capability_rows           20
disposition               AUTHORIZED_TO_EXECUTE_PROGRAM_222
```

Despite that final disposition, **hold Program 222 until the Program 221 transcript and exported result have been reconciled exactly**.

## Current boundary

```text
Program 220 HF4 checkpoint             PASS
Original Program 221 attempt           ROLLED BACK
Program 221 HF5 construction           COMPLETE
Broader Program 221 static review      COMPLETE
Separate physical readback             75 / 75 PASS
PostgreSQL execution of HF5            NOT PERFORMED HERE
Program 221 runtime success            NOT YET ESTABLISHED
Program 222 release                    HELD PENDING HF5 EVIDENCE
M2.12 acceptance                       NOT CLAIMED
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-d6530b25-36fa-4f9c-bfd4-dbad5d064608"></a>
## Andrew / user · C085-M00052

C085-M00052 · 2026-08-11T00:07:16.338000-04:00 · active path

Preceding visible parent: [C085-M00051](part-02.md#m-25b84c16-6629-49b3-aff4-ead07516ba9e)

**Editorial record note:** Attachment references: 221_HF5_pre_rerun_state_verification_results_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
another error in program 221: SQL Error [P0001]: ERROR: M2.12 P221 source graph mismatch
  Where: PL/pgSQL function inline_code_block line 9 at RAISE
  ERROR: M2.12 P221 source graph mismatch
  Where: PL/pgSQL function inline_code_block line 9 at RAISE     correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. when correcting error, do not correct this error and stop, review the rest of program 221 for additional, similar/noticeable errors. 221 pre-run evidence attached.   
<!-- END_SOURCE_MESSAGE -->


<a id="m-fa8ec16f-022f-46a3-b477-e95e28567b6f"></a>
## Assistant · C085-M00053

C085-M00053 · 2026-08-11T00:07:32.153210-04:00 · active path

Preceding visible parent: [C085-M00052](part-02.md#m-d6530b25-36fa-4f9c-bfd4-dbad5d064608)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m treating this as a fail-closed Program 221 hotfix: I’ll reconcile the pre-run checkpoint, isolate the source-graph defect, then audit the remaining source before packaging a superseding build.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d09359ce-03b7-4794-b72e-b6f44641b42f"></a>
## Assistant · C085-M00054

C085-M00054 · 2026-08-11T00:10:37.605006-04:00 · active path

Preceding visible parent: [C085-M00053](part-02.md#m-fa8ec16f-022f-46a3-b477-e95e28567b6f)

<!-- BEGIN_SOURCE_MESSAGE -->
The pre-run record exactly matches the required post-220 state, so the failure is inside Program 221’s source-graph reconstruction. I’m isolating the faulty predicate without weakening the graph gate.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0a4d64bc-9cc9-403a-b4d9-b7bc83c0c65b"></a>
## Assistant · C085-M00055

C085-M00055 · 2026-08-11T00:19:41.206700-04:00 · active path

Preceding visible parent: [C085-M00054](part-02.md#m-d09359ce-03b7-4794-b72e-b6f44641b42f)

<!-- BEGIN_SOURCE_MESSAGE -->
The review found Edge 5 extracting the wrong M1.3 JSON value, plus under-scoped registry lookups. HF6 will bind exact version-1 identities and add edge diagnostics and a 48/48 gate.
<!-- END_SOURCE_MESSAGE -->
