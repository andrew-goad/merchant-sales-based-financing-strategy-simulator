# WP3 Build Protocol

Part 03 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-02.md)
[Next part](part-04.md)

<a id="m-123806fc-941b-4318-9a6d-220b5e572024"></a>
## Assistant · C085-M00056

C085-M00056 · 2026-08-11T00:49:19.942638-04:00 · active path

Preceding visible parent: [C085-M00055](part-02.md#m-0a4d64bc-9cc9-403a-b4d9-b7bc83c0c65b)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 221 HF6 — Hotfix complete

Your stop-and-rollback response was correct. The attached pre-run evidence proves that Program 220 remained complete, the accepted predecessor state was exact, no M2.12 evidence or G3 result rows existed, and all three owned sequences remained at the expected pre-Program-221 state. [export reference: filecite | turn7file0 | L9-L11]

**Do not rerun Program 220. Do not rerun Program 221 HF5. Program 221 HF6 is the only current Program 221 retry source.**

## Downloads

### Superseding continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF6.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF6.zip`; referenced bytes not established here)
- Download the matching ZIP SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF6.zip.sha256`; referenced bytes not established here)

The continuation ZIP intentionally contains:

- one read-only pre-rerun verifier;
- one executable Program 221 HF6 source;
- no executable Program 220;
- no executable Program 222;
- no recovery SQL.

### Program 221 HF6 directly

- Download Program 221 HF6 SQL (historical reference: `sandbox:[session]/221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql`; referenced bytes not established here)
- Download the Program 221 HF6 sidecar (historical reference: `sandbox:[session]/221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql.sha256`; referenced bytes not established here)

### Mandatory pre-rerun verifier

- Download the HF6 state and source-graph verifier (historical reference: `sandbox:[session]/221_HF6_pre_rerun_state_and_source_graph_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/221_HF6_pre_rerun_state_and_source_graph_verification.sql.sha256`; referenced bytes not established here)

### Review and operating records

- Download the independent 97-control physical readback (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF6_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the independent control ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF6_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Download the Program 221 HF6 operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF6_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Download the 19-edge semantic reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF6_SOURCE_EDGE_SEMANTIC_RECONCILIATION.csv`; referenced bytes not established here)
- Download the complete 76-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF6_FULL_PROGRAM_REVIEW.csv`; referenced bytes not established here)
- Download the 1,029-reference physical-schema reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF6_PHYSICAL_SCHEMA_RECONCILIATION.csv`; referenced bytes not established here)
- Download the Program 222 hold notice (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_SHARED_EDGE5_DEFECT_HOLD_NOTICE.md`; referenced bytes not established here)

## Root cause

The failing source edge was:

```text
Edge 5
M1_3_TO_M2_2_REQUEST_AUTHORITY
```

Program 221 HF5 reconstructed the accepted M1.3 source value as:

```sql
agr.observed_value::text
```

The accepted M1.3 gate does not store a bare 32-character hash in `observed_value`. It stores a JSON object whose governed application hash is the embedded:

```text
application_set_hash
```

Consequently, HF5 compared the complete JSON document to the frozen expected hash:

```text
01485256b9b5748fb412743d35ced602
```

That comparison could never pass even though the underlying accepted state was correct.

HF6 uses the correct physical extraction:

```sql
(agr.observed_value::jsonb ->> 'application_set_hash')::text
```

The same expression is used in both:

- the scalar source-hash observation; and
- its independent one-row count subquery.

## Broader Program 221 review

The correction did not stop at Edge 5.

### Source-graph reconstruction

All 19 source edges were independently reconstructed and compared with the frozen source-edge authority.

| Control | HF6 result |
|---|---:|
| Physical source-edge branches | **19** |
| Distinct edge sequences | **19** |
| Distinct edge codes | **19** |
| Frozen expected-hash mismatches | **0** |
| Scalar/count predicate mismatches | **0** |
| Raw M1.3 `observed_value::text` expressions remaining | **0** |
| Correct M1.3 `application_set_hash` extractions | **2** |
| Correct M1.6 `combined_hash` extractions | **2** |

### Registry identity hardening

The source-graph helper contained 72 ordinary registry observations. HF6 now requires every observation to be bound to the exact governed identity, including:

- `module1_run_id`;
- contract or bundle code;
- contract or bundle version;
- accepted contract or bundle status;
- both request and pricing identities for the M2.2 dual-contract registry.

Results:

```text
Registry observations reviewed          72
Exact identity scopes                    72
Missing identity predicates               0
```

HF6 also verifies that:

```text
M2.2 source_m1_3_gate_id
    = M1_3_APPLICATION_REQUEST

M2.5 source_m1_6_acceptance_gate_id
    = M1_6_MATCHED_SCENARIO_OVERLAYS
```

### Assertion and diagnostic hardening

HF6 retains all 48 frozen preflight assertions and adds a final collection gate requiring:

```text
assertion_rows = 48
pass_rows      = 48
fail_rows      = 0
all_pass_flag  = true
```

If the source graph fails again, the exception detail now identifies every failing edge with:

```text
edge sequence
edge code
expected hash
observed accepted-source hash
observed target-recorded hash
source gate status
source row count
target row count
edge status
```

This avoids another opaque `M2.12 P221 source graph mismatch` with no indication of which edge caused it.

### Full-program scope

| Review item | Result |
|---|---:|
| Governed statements reviewed | **76/76 PASS** |
| Statements changed from HF5 | **55 and 74 only** |
| Governed statements unchanged | **74** |
| Temporary helpers | **18** |
| Persistent DML operations | **0** |
| Persistent DDL operations | **0** |
| Physical-schema references reconciled | **1,029** |
| Frozen assertion predicates | **48** |
| Program 221 persistent-state behavior | **READ-ONLY** |

HF6 preserves the earlier HF5 corrections for:

- exact G3 gate selection;
- accepted physical registry column mappings;
- M1.17 bundle-status mappings;
- removal of node-level component-by-edge Cartesian multiplication;
- same-session post-commit result exportability.

## Program 222 is held

The broader review identified the same M1.3 defect in the existing Program 222 source: it also uses the complete `agr.observed_value::text` value for the M1.3 source edge.

Therefore:

```text
Program 222 execution              HELD
Programs 223–227                   HELD BEHIND PROGRAM 222
Program 222 executable SQL in ZIP  NO
```

Even if a successful Program 221 result displays:

```text
AUTHORIZED_TO_EXECUTE_PROGRAM_222
```

that is only Program 221’s governed internal disposition. It does **not** override this source-specific hold or release the known-defective Program 222.

## Physical delivery ledger

### Continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF6.zip` |
| Bytes | **80,843** |
| SHA-256 | `7585f7c3244c5cce60527169fc8f67fbc1937e37524a5c1019e11db12395d898` |
| ZIP entries | **34** |
| Total uncompressed bytes | **685,983** |
| ZIP CRC | **PASS** |
| Complete fresh extraction | **PASS** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Symbolic links | **0** |
| Build/extraction path mismatches | **0** |
| Build/extraction size mismatches | **0** |
| Build/extraction SHA-256 mismatches | **0** |

The sidecar contains exactly:

```text
7585f7c3244c5cce60527169fc8f67fbc1937e37524a5c1019e11db12395d898  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_220_HF6.zip
```

### Program 221 HF6

| Attribute | Physical result |
|---|---:|
| Bytes | **221,276** |
| SHA-256 | `97387aca692d676b74c89ab298e4e284bd862feaf289f98eba5fd91c336877d7` |
| Governed statements | **76** |
| Changed statements from HF5 | **55, 74** |
| Direct versus packaged bytes | **IDENTICAL** |

Superseded Program 221 HF5 identity:

```text
42b059a8e68a2243115377cd3839bdd1fb73d84233f9a848267cba96a4dbb933
```

Current Program 221 HF6 identity:

```text
97387aca692d676b74c89ab298e4e284bd862feaf289f98eba5fd91c336877d7
```

### Read-only verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **70,553** |
| SHA-256 | `a518ca8443825a1c7856fc9d338b9c0887b203c92927e36b792f0359b7b3842e` |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Final transaction action | **ROLLBACK** |
| Direct versus packaged bytes | **IDENTICAL** |

### Independent release validation

```text
Independent controls                  97 / 97 PASS
Blocking failures                      0
Manifest mismatches                    0
manifest.json mismatches               0
SHA256SUMS mismatches                  0
Package-inventory mismatches           0
Source-edge authority mismatches       0
Registry-scope failures                0
Scalar/count parity failures           0
Persistent mutation findings           0
```

The original WP5 R1 package remains the historical approved baseline identity and archive; this HF6 ZIP is a bounded continuation package after successful Program 220, not a replacement for that historical package. [export reference: filecite | turn6file0 | L3-L12]

# Mandatory restart sequence

## 1. Preserve the failed HF5 evidence

Retain unchanged:

```text
HF5 console transcript
P0001 source-graph error
client/process status
stop action
ROLLBACK response
HF5 pre-run verification result
```

Do not overwrite those records with HF6 evidence.

## 2. Run the HF6 verifier first

Execute the complete physical file:

```text
221_HF6_pre_rerun_state_and_source_graph_verification.sql
```

Require SHA-256:

```text
a518ca8443825a1c7856fc9d338b9c0887b203c92927e36b792f0359b7b3842e
```

It should return **two result grids**.

### Result Grid 1 — source-graph detail

Require:

```text
exactly 19 rows
edge_sequence 1–19
19 distinct edge codes
every edge_status = PASS
every source row count = 1
every target row count = 1
every source gate status = PASS
observed source hash = expected hash
observed target hash = expected hash
```

### Result Grid 2 — state summary

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
source_graph_distinct_sequences    19
source_graph_distinct_codes        19
disposition                        READY_TO_EXECUTE_PROGRAM_221_HF6
```

Any error, missing grid, row-count difference, non-PASS edge, or summary difference is a hard stop.

## 3. Export both verifier grids before leaving the session

For each visible result grid in DBeaver:

```text
Use fetched rows      ON
Query the database    OFF
Open new connection   OFF
```

Save separately:

```text
221_HF6_pre_rerun_source_graph_detail.csv
221_HF6_pre_rerun_state_summary.csv
```

This avoids losing the actual result state or accidentally rerunning a query against session-local temporary helpers.

## 4. Execute Program 221 HF6 only

After the verifier passes exactly, execute:

```text
221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql
```

Require SHA-256:

```text
97387aca692d676b74c89ab298e4e284bd862feaf289f98eba5fd91c336877d7
```

Execution requirements:

- one complete physical file;
- one invocation;
- first-error-stop behavior;
- no outer transaction;
- no concatenated Program 222;
- no ad hoc SQL or patching.

The governing live-execution authority requires this one-program-at-a-time sequence and an immediate stop on any error or ambiguity. [export reference: filecite | turn6file5 | L34-L55] The controlled prompt likewise prohibits proceeding to the next program until the current transcript, result sets, counts, lifecycle, hashes, sequence state, and checkpoint reconcile exactly. [export reference: filecite | turn6file6 | L24-L48]

Required Program 221 result:

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

Export that visible grid immediately using **Use fetched rows** as:

```text
221_HF6_primary_result.csv
```

## 5. Stop after Program 221

Even after an exact PASS:

```text
Do not execute Program 222.
Do not execute Programs 223–227.
Do not execute any recovery.
```

Program 222 now requires its own bounded correction and review before execution.

## Current boundary

```text
Program 220 HF4 runtime checkpoint       PASS
Program 221 HF5 attempt                  FAILED / ROLLED BACK
Program 221 HF6 construction             COMPLETE
Full 76-statement review                 PASS
Independent physical/static readback     97 / 97 PASS
PostgreSQL execution of HF6              NOT PERFORMED HERE
Program 221 HF6 runtime success          NOT YET ESTABLISHED
Program 222                              HELD
M2.12 acceptance                         NOT CLAIMED
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-c5da0b10-6363-4b2d-91fc-638f37e4fce2"></a>
## Andrew / user · C085-M00057

C085-M00057 · 2026-08-11T06:31:44.565000-04:00 · active path

Preceding visible parent: [C085-M00056](part-03.md#m-123806fc-941b-4318-9a6d-220b5e572024)

**Editorial record note:** Attachment references: 221_HF6_pre_rerun_source_graph_detail_20260811.csv; 221_HF6_pre_rerun_state_summary_20260811.csv; 221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6_results_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Good morning. Perform program 222 bounded correction and review. Attached are program 221 pre_rerun and program 221 results.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a0fec653-9bb0-470f-ba2b-6f9c5f8e3af9"></a>
## Assistant · C085-M00058

C085-M00058 · 2026-08-11T06:32:12.233469-04:00 · active path

Preceding visible parent: [C085-M00057](part-03.md#m-c5da0b10-6363-4b2d-91fc-638f37e4fce2)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll reconcile both Program 221 evidence exports first, then audit and correct Program 222 end-to-end before producing a bounded HF7 continuation package and execution verifier.
<!-- END_SOURCE_MESSAGE -->


<a id="m-13813171-53c2-45bd-96e2-b2d425bf36dd"></a>
## Assistant · C085-M00059

C085-M00059 · 2026-08-11T06:35:16.832009-04:00 · active path

Preceding visible parent: [C085-M00058](part-03.md#m-a0fec653-9bb0-470f-ba2b-6f9c5f8e3af9)

<!-- BEGIN_SOURCE_MESSAGE -->
Program 221 reconciles exactly and authorizes Program 222 correction. I confirmed the M1.3 JSON/hash defect and am reviewing registry mappings, cardinalities, mutation boundaries, and exportability.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8a839bcb-04e5-4964-a52e-0c9ee515f90e"></a>
## Assistant · C085-M00060

C085-M00060 · 2026-08-11T06:44:23.022245-04:00 · active path

Preceding visible parent: [C085-M00059](part-03.md#m-13813171-53c2-45bd-96e2-b2d425bf36dd)

<!-- BEGIN_SOURCE_MESSAGE -->
The broader review found two blocking component-observation defects: all 13 branches repeat Component 9, and downstream output emits only it. I’m rebuilding both statements from 13-component authority.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5f9aef5c-5471-443d-a733-7b93a20654c7"></a>
## Assistant · C085-M00061

C085-M00061 · 2026-08-11T07:11:29.962462-04:00 · active path

Preceding visible parent: [C085-M00060](part-03.md#m-8a839bcb-04e5-4964-a52e-0c9ee515f90e)

<!-- BEGIN_SOURCE_MESSAGE -->
HF7 retains all 206 governed statements, preserves persistent targets and transaction boundaries, and adds same-session result exportability. Independent ZIP readback is clean; Programs 223–227 remain held.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c6ace848-acce-4420-a932-c1238c8648da"></a>
## Assistant · C085-M00062

C085-M00062 · 2026-08-11T07:34:29.976259-04:00 · active path

Preceding visible parent: [C085-M00061](part-03.md#m-5f9aef5c-5471-443d-a733-7b93a20654c7)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 222 HF7 — Bounded Correction and Review Complete

Program 221 HF6 evidence reconciles successfully, and the bounded Program 222 correction has been completed.

The Program 221 pre-execution checkpoint shows the accepted M2.11 predecessor, complete Program 220 installation, pristine M2.12 generation state, correct sequence positions, and 19 of 19 source edges passing. [export reference: filecite | turn9file0 | L9-L11] The detailed evidence confirms that all 19 expected, accepted-source, and target-recorded hashes agree—including Edge 5, `M1_3_TO_M2_2_REQUEST_AUTHORITY`, with hash `01485256b9b5748fb412743d35ced602`. [export reference: filecite | turn9file1 | L22-L41] Program 221 itself returned `PASS`, 48 of 48 assertions, 19 source edges, 13 component contracts, 12 certification nodes, 72 mandatory evidence rows, 20 capability rows, and `AUTHORIZED_TO_EXECUTE_PROGRAM_222`. [export reference: filecite | turn9file2 | L52-L53]

## Downloads

### Controlled continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF7.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF7.zip`; referenced bytes not established here)
- Download the matching ZIP SHA-256 sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF7.zip.sha256`; referenced bytes not established here)

The continuation package contains no executable Program 220, Program 221, Program 223–227, or recovery source.

### Program 222 HF7

- Download Program 222 HF7 SQL (historical reference: `sandbox:[session]/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF7.sql`; referenced bytes not established here)
- Download the Program 222 HF7 SQL sidecar (historical reference: `sandbox:[session]/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF7.sql.sha256`; referenced bytes not established here)

### Mandatory pre-execution verifier

- Download the Program 222 HF7 state and source-graph verifier (historical reference: `sandbox:[session]/222_HF7_pre_execution_state_and_source_graph_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/222_HF7_pre_execution_state_and_source_graph_verification.sql.sha256`; referenced bytes not established here)

### Operator and review records

- Download the Program 222 HF7 operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Download the HF7 validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the independent physical-readback report (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the 17-control physical-readback ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)
- Download the 17-statement change ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_CHANGED_STATEMENT_LEDGER.csv`; referenced bytes not established here)
- Download the 13-component physical reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_COMPONENT_PHYSICAL_RECONCILIATION.csv`; referenced bytes not established here)
- Download the complete 206-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_FULL_PROGRAM_REVIEW.csv`; referenced bytes not established here)
- Download the persistent-mutation inventory (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_PERSISTENT_MUTATION_INVENTORY.csv`; referenced bytes not established here)
- Download the original-to-HF7 source patch (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_R3_TO_HF7.patch`; referenced bytes not established here)

## Program 221 evidence normalization

The two pre-run filenames were reversed relative to their physical content:

| As-received filename | Actual content |
|---|---|
| `221_HF6_pre_rerun_source_graph_detail_20260811.csv` | One-row state summary |
| `221_HF6_pre_rerun_state_summary_20260811.csv` | Nineteen-row source-edge detail |

The continuation package preserves both original files unchanged and supplies correctly named normalized copies. The Program 221 primary-result file was correctly named.

- Download the evidence-reconciliation note (historical reference: `sandbox:[session]/M2_12_PROGRAM_221_HF6_EVIDENCE_RECONCILIATION.md`; referenced bytes not established here)

# Defects identified and corrected

The review did not stop at the already-known Edge 5 defect.

## 1. M1.3 source-edge extraction

The original Program 222 source treated the full accepted M1.3 gate JSON document as the source hash:

```sql
agr.observed_value::text
```

The governed source hash is the JSON member:

```text
application_set_hash
```

HF7 now uses:

```sql
(agr.observed_value::jsonb ->> 'application_set_hash')::text
```

in both the physical hash observation and the independently calculated source-row-count path.

## 2. Collapsed 13-component observation base

The original 13-branch component-observation helper did not physically reconstruct all 13 governed components. Its branches were effectively collapsed onto the M2.7 operational-activation component.

HF7 reconstructs these exact component contracts:

1. M1 G2 consumption bundle.
2. M2.1 eligibility and routing.
3. M2.2 request structure.
4. M2.2 pricing structure.
5. M2.3 final offer decision.
6. M2.4 portfolio activation.
7. M2.5 monitoring.
8. M2.6 intervention strategy.
9. M2.7 operational activation.
10. M2.8 servicing execution.
11. M2.9 reconciliation certification.
12. M2.10 portfolio analytics.
13. M2.11 strategy simulation.

Each component now uses its own exact registry, contract or bundle identity, latest relation, archive relation, schema and methodology fields, governed hashes, acceptance gate, and acceptance evidence.

## 3. Repeated M2.7 component certification

The next original helper again used the M2.7 component rather than joining all 13 component observations to their governed specifications.

HF7 replaces that construction with an exact-key 13-row certification join covering:

- component sequence;
- certification-node sequence;
- contract identity and version;
- accepted status;
- schema version;
- methodology version;
- canonical-entity count;
- latest and archive row counts;
- positive and negative evidence counts;
- contract, combined, latest, archive, and registry-row hashes;
- required source-edge counts and statuses.

## 4. Under-scoped registry reads

Several reproduction, seed, and evidence observations relied primarily on `module1_run_id` or version predicates.

HF7 adds the exact contract or bundle code, version, and accepted-status identity wherever those fields govern uniqueness. This includes the M1.17 and M2.11 predecessor reads used to construct the G3 seed.

## 5. Cardinality-only assertions

Several helpers required only that the expected number of rows existed. A complete set of failing rows could therefore satisfy the helper cardinality.

HF7 now requires:

```text
19 / 19 source-edge certifications PASS
13 / 13 contract reproductions PASS
12 / 12 stage-boundary observations PASS
13 / 13 component certifications PASS
72 / 72 evidence certifications PASS
12 / 12 node certifications PASS
```

Diagnostic exceptions identify the individual failing edges, components, nodes, or evidence records.

## 6. Persistent-registry cross joins

The G3 seed used predecessor-registry cross joins that were not bound directly to their complete governed identities.

HF7 replaces those with exact joins to:

```text
M1_G2_CONSUMPTION_BUNDLE, version 1, ACCEPTED
M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION, version 1, ACCEPTED
```

The remaining persistent cross joins are only to the three one-row PostgreSQL sequence relations used for sequence-state reconciliation.

## 7. Result exportability

The Program 222 primary-result helper formerly used:

```sql
ON COMMIT DROP
```

HF7 changes only that result helper to:

```sql
ON COMMIT PRESERVE ROWS
```

The committed result can therefore be queried again from the **same originating database session**. Exporting the visible result grid with **Use fetched rows** remains the preferred evidence method.

# Bounded source scope

The approved historical Program 222 R3 identity was:

```text
SHA-256
6e29dba9043675094fb9c399895895b9230e1b96976e5e4af7a7a48e094d51fe
```

That identity came from the approved WP2 R4 source set. [export reference: filecite | turn8file11 | L31-L50] It is now superseded **only for the controlled Program 222 retry**.

| Control | HF7 result |
|---|---:|
| Governed statements retained | **206** |
| Changed statement bodies | **17** |
| Unchanged statement bodies | **189** |
| Persistent DDL changes | **0** |
| Persistent mutation-target changes | **0** |
| Transaction-boundary changes | **0** |
| Final commit retained | **PASS** |
| Program 223–227 changes | **0** |
| Recovery-source changes | **0** |

Changed statements:

```text
43, 44, 51, 52, 56, 64, 68, 71, 72,
75, 76, 80, 84, 120, 121, 195, 201
```

The persistent write sequence remains:

- five certification-snapshot inserts;
- G3 latest insert;
- G3 archive insert;
- G3 registry insert;
- 24 generation-evidence inserts;
- governed-run lifecycle update.

# Physical delivery ledger

## Continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF7.zip` |
| Bytes | **122,102** |
| SHA-256 | `5c93946b553958587963d62c15b6c052b9d28f521abcea46080e4a4854d8937a` |
| ZIP entries | **36** |
| Total uncompressed bytes | **955,224** |
| ZIP CRC | **PASS** |
| Complete fresh extraction | **PASS** |

The sidecar contains exactly:

```text
5c93946b553958587963d62c15b6c052b9d28f521abcea46080e4a4854d8937a  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF7.zip
```

## Program 222 HF7

| Attribute | Physical result |
|---|---:|
| Bytes | **538,780** |
| SHA-256 | `c36324490a0e63e0efdd657a2ac616853f46bccc9935bc871c6348fed547f839` |
| Governed statements | **206** |
| Changed statements | **17** |
| Unchanged statements | **189** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

The SQL sidecar contains:

```text
c36324490a0e63e0efdd657a2ac616853f46bccc9935bc871c6348fed547f839  222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF7.sql
```

## Pre-execution verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **70,650** |
| SHA-256 | `581524228eed42e62764a7969465475534f93dc851ba4baf99ae089c53b93993` |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Final action | **ROLLBACK** |
| Direct verifier versus packaged verifier | **IDENTICAL** |

The verifier sidecar contains:

```text
581524228eed42e62764a7969465475534f93dc851ba4baf99ae089c53b93993  222_HF7_pre_execution_state_and_source_graph_verification.sql
```

# Review results

## Source and semantic review

```text
Governed statement review                  206 / 206 PASS
Builder-side static controls                30 / 30 PASS
Source-edge identities                      19 / 19 PASS
Component physical mappings                 13 / 13 PASS
Certification-node authority                12 / 12 retained
Mandatory-evidence authority                72 / 72 retained
Residual raw M1.3 JSON-document extraction   0
Residual collapsed M2.7 component pattern    0
Persistent component-base cross joins        0
Executable Program 223+ sources in package   0
```

## Package readback

```text
Independent release controls               17 / 17 PASS
Path mismatches                              0
Size mismatches                              0
SHA-256 mismatches                           0
Duplicate paths                              0
Case-insensitive duplicate paths             0
Unsafe paths                                 0
Symbolic links                               0
MANIFEST.csv mismatches                      0
manifest.json mismatches                     0
SHA256SUMS.txt mismatches                    0
PACKAGE_INVENTORY.csv mismatches             0
```

This is a source, static, physical, and package review. **HF7 has not been executed against your PostgreSQL database.**

The original WP5 package remains the historical approved archive with SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn8file0 | L3-L12]

# Controlled execution protocol

The governing authorization permits one complete physical file per invocation, requires first-error-stop behavior, prohibits an outer transaction or concatenated programs, and conditions every later program on exact reconciliation of the preceding evidence. [export reference: filecite | turn8file5 | L34-L50] [export reference: filecite | turn8file6 | L22-L48]

## 1. Run the verifier first

Execute the complete physical file:

```text
222_HF7_pre_execution_state_and_source_graph_verification.sql
```

Require SHA-256:

```text
581524228eed42e62764a7969465475534f93dc851ba4baf99ae089c53b93993
```

It produces two result grids.

### Grid 1 — source-edge detail

Require:

```text
rows                                      19
distinct edge sequences                   19
distinct edge codes                       19
source registry row count                 1 for every edge
target registry row count                 1 for every edge
source gate status                        PASS for every edge
source hash mismatch                      false for every edge
target hash mismatch                      false for every edge
edge status                               PASS for every edge
```

### Grid 2 — state summary

Require:

```text
state_verification_status                 PASS
predecessor_rows                          1
run_code                                  M1_V0_2_BASELINE_BUILD
run_version                               1
run_status                                M2_11_ACCEPTED
contract_status                           ACCEPTED
installed_top_level_objects               21
policy_rows                               1
nonpolicy_rows                            0
m2_12_evidence_rows                       0
g3_result_rows                            0
gate_rows                                 1
exact_gate_rows                           1
policy_sequence_state                     1|true
archive_sequence_state                    1|false
registry_sequence_state                   1|false
source_graph_rows                         19
source_graph_pass_rows                    19
source_graph_distinct_sequences           19
source_graph_distinct_codes               19
disposition                               READY_TO_EXECUTE_PROGRAM_222_HF7
```

Export both visible grids with:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

Recommended filenames:

```text
222_HF7_pre_execution_source_graph_detail.csv
222_HF7_pre_execution_state_summary.csv
```

Any difference is a hard stop.

## 2. Execute Program 222 HF7 only

After the verifier passes exactly, execute:

```text
222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF7.sql
```

Require SHA-256:

```text
c36324490a0e63e0efdd657a2ac616853f46bccc9935bc871c6348fed547f839
```

Execution boundaries:

```text
Complete physical file       one invocation
First-error stop             required
Outer transaction            prohibited
Program 223 concatenation    prohibited
Ad hoc SQL changes           prohibited
Recovery execution           prohibited
```

## 3. Required Program 222 primary result

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

Export the visible row immediately using **Use fetched rows**.

## 4. Stop after Program 222

Even if the result says `READY_FOR_PROGRAM_223`:

```text
Program 223    HELD
Program 224    HELD
Program 225    HELD
Program 226    HELD
Program 227    HELD
Recoveries     UNAUTHORIZED
```

- Download the formal Programs 223–227 hold notice (historical reference: `sandbox:[session]/M2_12_PROGRAMS_223_227_HOLD_NOTICE.md`; referenced bytes not established here)

Program 223 remains held until the complete Program 222 transcript, process status, exported primary result, persistent row counts, lifecycle, hashes, sequence states, and 24 evidence rows reconcile exactly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-92fa0a74-a559-4e53-87e7-d2bea9c17194"></a>
## Andrew / user · C085-M00063

C085-M00063 · 2026-08-11T07:55:11.101000-04:00 · active path

Preceding visible parent: [C085-M00062](part-03.md#m-c6ace848-acce-4420-a932-c1238c8648da)

**Editorial record note:** Attachment references: 222_HF7_pre_execution_source_graph_detail_20260811.csv; 222_HF7_pre_execution_state_summary_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
program 222 error: SQL Error [P0001]: ERROR: M2.12 P222 HF7 stage-boundary certification mismatch
  Detail: node=1:M1_17_G2_FOUNDATION|status=FAIL; node=4:M2_3_FINAL_DECISION|status=FAIL
  Where: PL/pgSQL function inline_code_block line 12 at RAISE
  ERROR: M2.12 P222 HF7 stage-boundary certification mismatch
  Detail: node=1:M1_17_G2_FOUNDATION|status=FAIL; node=4:M2_3_FINAL_DECISION|status=FAIL
  Where: PL/pgSQL function inline_code_block line 12 at RAISE       correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. when correcting error, do not correct this error and stop, review the rest of program 222 for additional, similar/noticeable errors. 222 pre-run evidence attached.      
<!-- END_SOURCE_MESSAGE -->


<a id="m-fb52e531-c573-4498-b049-6e83abdba264"></a>
## Assistant · C085-M00064

C085-M00064 · 2026-08-11T07:55:27.985128-04:00 · active path

Preceding visible parent: [C085-M00063](part-03.md#m-92fa0a74-a559-4e53-87e7-d2bea9c17194)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m tracing both failed stage-boundary nodes to their physical registry fields, then auditing all remaining Program 222 stage, component, evidence, hash, and cardinality assertions before issuing the hotfix.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9deb0d4e-cce0-4994-a61f-a9d2222f498b"></a>
## Assistant · C085-M00065

C085-M00065 · 2026-08-11T07:58:34.421852-04:00 · active path

Preceding visible parent: [C085-M00064](part-03.md#m-fb52e531-c573-4498-b049-6e83abdba264)

<!-- BEGIN_SOURCE_MESSAGE -->
The pre-run state is clean with all 19 source edges passing. The defect is broader: M1.17 snapshot controls and M2.3’s policy boundary are not `run_evidence.evidence_code` values.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bb773540-d654-4554-a088-85462dad4d09"></a>
## Assistant · C085-M00066

C085-M00066 · 2026-08-11T08:07:39.804833-04:00 · active path

Preceding visible parent: [C085-M00065](part-03.md#m-9deb0d4e-cce0-4994-a61f-a9d2222f498b)

<!-- BEGIN_SOURCE_MESSAGE -->
The 70-control inventory resolves to 66 run-evidence rows, three M1.17 snapshot controls, and one M2.3 boundary reconstructed from its approved reason definition and payload coverage.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2f36902e-df8c-488c-9e23-a47afaaa56e7"></a>
## Assistant · C085-M00067

C085-M00067 · 2026-08-11T08:37:51.111418-04:00 · active path

Preceding visible parent: [C085-M00066](part-03.md#m-bb773540-d654-4554-a088-85462dad4d09)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.12 Program 222 HF8 — Bounded Correction Complete

Your **stop-and-rollback response was correct**. Controlled execution requires an immediate stop on any error and prohibits rerunning, patching ad hoc, invoking recovery, or advancing to the next program without a governed correction. [export reference: filecite | turn10file5 | L34-L50]

The attached pre-execution evidence establishes that the failure was internal to Program 222 HF7 rather than a predecessor or source-graph problem:

- all 19 source edges passed with exact accepted-source and target-recorded hashes; [export reference: filecite | turn11file0 | L10-L29]
- the run remained at `M2_11_ACCEPTED`;
- the M2.12 target was pristine;
- all three owned sequences remained at their pre-generation positions;
- the verifier disposition was `READY_TO_EXECUTE_PROGRAM_222_HF7`. [export reference: filecite | turn11file1 | L40-L41]

**Do not rerun Program 222 HF7. Program 222 HF8 is the only current Program 222 retry source.**

## Downloads

### Controlled continuation package

- Download M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF8.zip (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF8.zip`; referenced bytes not established here)
- Download the matching ZIP sidecar (historical reference: `sandbox:[session]/M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF8.zip.sha256`; referenced bytes not established here)

The continuation ZIP intentionally contains only one executable governed program—Program 222 HF8—and one read-only pre-execution verifier. It contains no executable Program 220, 221, 223–227, or recovery source.

### Program 222 HF8

- Download Program 222 HF8 SQL (historical reference: `sandbox:[session]/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF8.sql`; referenced bytes not established here)
- Download the Program 222 HF8 SQL sidecar (historical reference: `sandbox:[session]/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF8.sql.sha256`; referenced bytes not established here)

### Mandatory HF8 verifier

- Download the HF8 state, source-graph, and stage-boundary verifier (historical reference: `sandbox:[session]/222_HF8_pre_execution_state_source_graph_and_stage_boundary_verification.sql`; referenced bytes not established here)
- Download the verifier sidecar (historical reference: `sandbox:[session]/222_HF8_pre_execution_state_source_graph_and_stage_boundary_verification.sql.sha256`; referenced bytes not established here)

### Operator and validation records

- Download the HF8 operator protocol (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_OPERATOR_PROTOCOL.md`; referenced bytes not established here)
- Download the HF8 validation report (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the independent physical-readback report (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_INDEPENDENT_PHYSICAL_READBACK.md`; referenced bytes not established here)
- Download the 193-control independent readback ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_INDEPENDENT_PHYSICAL_READBACK_CONTROLS.csv`; referenced bytes not established here)

### Detailed review evidence

- Download the complete 206-statement review (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_FULL_PROGRAM_REVIEW.csv`; referenced bytes not established here)
- Download the 18-statement change ledger (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_CHANGED_STATEMENT_LEDGER.csv`; referenced bytes not established here)
- Download the stage-boundary physical-source reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_STAGE_BOUNDARY_PHYSICAL_SOURCE_RECONCILIATION.csv`; referenced bytes not established here)
- Download the 12-node stage-boundary reconciliation (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_STAGE_BOUNDARY_NODE_RECONCILIATION.csv`; referenced bytes not established here)
- Download the special-source evidence extract (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_SPECIAL_SOURCE_EVIDENCE_EXTRACT.csv`; referenced bytes not established here)
- Download the persistent-mutation inventory (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF8_PERSISTENT_MUTATION_INVENTORY.csv`; referenced bytes not established here)
- Download the HF7-to-HF8 source patch (historical reference: `sandbox:[session]/M2_12_PROGRAM_222_HF7_TO_HF8.patch`; referenced bytes not established here)

## Root cause

HF7’s stage-boundary construction incorrectly assumed that **every required stage-boundary control was a row in**:

```text
msbf_ctl.run_evidence
```

That assumption was false for both failing nodes.

### Node 1 — `M1_17_G2_FOUNDATION`

Its three required controls are:

```text
M1_17_E2E_045_BLOCKING_ERRORS
M1_17_E2E_046_MODULE2_ROWS
M1_17_E2E_047_PII_COLUMNS
```

These are not ordinary `run_evidence` codes. Their accepted physical source is:

```text
msbf_ctl.m1_17_end_to_end_evidence_snapshot
```

HF7 searched the wrong relation, observed zero qualifying controls, and failed Node 1.

HF8 reconstructs all three controls directly from the accepted M1.17 snapshot authority and requires:

```text
three physical rows
three distinct controls
all three statuses PASS
zero duplicate controls
zero missing controls
zero non-PASS controls
```

### Node 4 — `M2_3_FINAL_DECISION`

Node 4 has six required controls:

- five are ordinary positive or negative rows in `msbf_ctl.run_evidence`;
- `M2_3_POLICY_BOUNDARY` is not a `run_evidence` code.

`M2_3_POLICY_BOUNDARY` is a physical decision-governance marker. HF8 reconstructs it from the combined accepted state:

1. the exact approved reason definition in `msbf_m2.final_decision_reason_definition`;
2. the accepted M2.3 contract registry;
3. complete latest-payload coverage;
4. complete archive-payload coverage;
5. exact 1,500 latest and 1,500 archive rows containing the marker.

Node 4 now requires five qualifying `run_evidence` controls plus one independently reconstructed physical policy-boundary control.

## Full stage-boundary review

The correction was extended across the complete stage-boundary authority rather than limited to the two reported failures.

| Physical source class | Governed controls |
|---|---:|
| `msbf_ctl.run_evidence` | **66** |
| M1.17 end-to-end evidence snapshot | **3** |
| M2.3 physical policy-boundary marker | **1** |
| **Total** | **70** |

All 70 controls across all 12 certification nodes were mapped to their actual persistent source:

| Node | Stage | Required controls | Physical allocation |
|---:|---|---:|---|
| 1 | `M1_17_G2_FOUNDATION` | 3 | 3 M1.17 snapshot |
| 2 | `M2_1_ELIGIBILITY_ROUTING` | 3 | 3 run evidence |
| 3 | `M2_2_PRICING_STRUCTURE` | 3 | 3 run evidence |
| 4 | `M2_3_FINAL_DECISION` | 6 | 5 run evidence + 1 physical marker |
| 5 | `M2_4_PORTFOLIO_ACTIVATION` | 4 | 4 run evidence |
| 6 | `M2_5_DAILY_MONITORING` | 6 | 6 run evidence |
| 7 | `M2_6_INTERVENTION_STRATEGY` | 4 | 4 run evidence |
| 8 | `M2_7_OPERATIONAL_ACTIVATION` | 7 | 7 run evidence |
| 9 | `M2_8_SERVICING_EXECUTION` | 8 | 8 run evidence |
| 10 | `M2_9_RECONCILIATION_CERTIFICATION` | 10 | 10 run evidence |
| 11 | `M2_10_PORTFOLIO_ANALYTICS` | 10 | 10 run evidence |
| 12 | `M2_11_STRATEGY_SIMULATION` | 6 | 6 run evidence |

HF8 now fails closed on any:

```text
missing physical control
duplicate physical control
non-PASS control
wrong physical source
acceptance-summary mismatch
required-versus-observed count mismatch
stage-boundary violation
```

## Additional Program 222 defects corrected

The review covered all **206 governed statements** and found additional assertions that were structurally present but too weak.

### Boundary aggregate gate

HF7 verified the existence of the six boundary-aggregate rows but did not require all six governed flags to be true.

HF8 requires every aggregate boundary flag to pass before generation can continue.

### Base-family hash gate

HF7 primarily checked the six-row family cardinality. HF8 additionally requires all six base-family hashes to be valid lowercase 32-character hexadecimal hashes.

### Physical-reconciliation gate

HF7 verified physical-reconciliation row presence. HF8 now requires the reconciliation itself to report:

```text
PASS
zero path mismatches
zero row-count mismatches
zero hash mismatches
zero sequence mismatches
zero canonical-state mismatches
```

### Generation-evidence insertion gate

HF7 could reach the evidence insert after constructing 24 business-key rows even if one of those rows carried a non-PASS status.

HF8 requires:

```text
24 evidence rows
24 distinct evidence codes
24 PASS statuses
zero failing evidence rows
```

before the persistent insertion is allowed.

### Post-update checkpoint

The final lifecycle checkpoint now reports exact diagnostics for:

- run lifecycle;
- G3 registry lifecycle;
- canonical-family counts;
- canonical-entity counts;
- generation-evidence counts;
- policy, archive, and registry identities;
- all three owned sequence states;
- combined-set hash form.

## Bounded source scope

| Control | HF8 result |
|---|---:|
| Governed statements retained | **206** |
| Statements changed from HF7 | **18** |
| Substantive corrections | **9** |
| Diagnostic-label corrections | **9** |
| Statements unchanged | **188** |
| Persistent DML statements changed | **0** |
| Persistent DDL changed | **0** |
| Persistent mutation targets changed | **0** |
| Transaction boundaries changed | **0** |
| Final commit changed | **0** |
| Program 223–227 sources changed | **0** |
| Recovery sources changed | **0** |

Substantively corrected statements:

```text
59, 60, 67, 68, 113, 117, 192, 196, 202
```

Diagnostic-label-only corrections:

```text
44, 52, 56, 64, 72, 76, 80, 84, 121
```

## Physical delivery ledger

### Continuation ZIP

| Attribute | Physical result |
|---|---:|
| Filename | `M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF8.zip` |
| Bytes | **119,370** |
| SHA-256 | `4a9b30404419c07e390a62dbf4ee2eed943f0a52e4095ed70eb788cc55ca67c7` |
| ZIP entries | **28** |
| Total uncompressed bytes | **872,160** |
| ZIP CRC | **PASS** |
| Complete independent extraction | **PASS** |
| Duplicate paths | **0** |
| Case-insensitive duplicate paths | **0** |
| Unsafe paths | **0** |
| Symbolic links | **0** |
| Path mismatches | **0** |
| Size mismatches | **0** |
| SHA-256 mismatches | **0** |
| Manifest mismatches | **0** |

The ZIP sidecar contains exactly:

```text
4a9b30404419c07e390a62dbf4ee2eed943f0a52e4095ed70eb788cc55ca67c7  M2_12_LIVE_EXECUTION_CONTINUATION_AFTER_221_HF8.zip
```

### Program 222 HF8

| Attribute | Physical result |
|---|---:|
| Bytes | **560,037** |
| SHA-256 | `aa879a83a36f79f8b215110d5a349fbf0982a441cecd52284d5227ebfcc72fb9` |
| Governed statements | **206** |
| Direct SQL versus packaged SQL | **IDENTICAL** |

The SQL sidecar contains exactly:

```text
aa879a83a36f79f8b215110d5a349fbf0982a441cecd52284d5227ebfcc72fb9  222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF8.sql
```

### HF8 verifier

| Attribute | Physical result |
|---|---:|
| Bytes | **104,636** |
| SHA-256 | `aa71e83753b00fe996cc97d52d3aa168ae32b77662c9b59766eb007d681ed34c` |
| Persistent DML | **0** |
| Persistent DDL | **0** |
| Final transaction action | **ROLLBACK** |
| Direct verifier versus packaged verifier | **IDENTICAL** |

### Independent readback

```text
Independent controls                  193 / 193 PASS
Blocking failures                       0
Governed statements                   206 / 206 PASS
Stage-boundary controls                70 / 70 mapped
Temporary dependencies unscheduled      0
Persistent mutation changes              0
```

This is a static, physical, source-semantic, and package validation. **Program 222 HF8 has not been executed against your PostgreSQL database here.**

The original WP5 R1 package remains the historical approved archive with SHA-256 `5dce8642e46aa701cdbe1aaeb75eb8e0a8fd454fc000e8ec4161400a45a3a38c`, 98 entries, 3,926,125 uncompressed bytes, and passing CRC. [export reference: filecite | turn10file0 | L3-L8] HF8 is a bounded continuation authority after completed Programs 220 and 221; it does not replace that historical archive.

# Mandatory HF8 execution sequence

## 1. Preserve the failed HF7 evidence

Keep separately and unchanged:

```text
complete HF7 transcript
SQLSTATE P0001
Node 1 and Node 4 failure detail
client/process status
STOP action
ROLLBACK response
HF7 pre-execution verifier exports
```

Do not overwrite these records with HF8 evidence.

## 2. Execute the HF8 verifier first

Execute the complete physical file:

```text
222_HF8_pre_execution_state_source_graph_and_stage_boundary_verification.sql
```

Require SHA-256:

```text
aa71e83753b00fe996cc97d52d3aa168ae32b77662c9b59766eb007d681ed34c
```

It returns **three result grids**.

### Grid 1 — source-graph detail

Require:

```text
rows                              19
distinct edge sequences           19
distinct edge codes               19
source row count                   1 for every edge
target row count                   1 for every edge
source gate status                PASS for every edge
source hash mismatch              false for every edge
target hash mismatch              false for every edge
edge status                       PASS for every edge
```

### Grid 2 — stage-boundary detail

Require:

```text
rows                              12
stage rows passing                12
total required controls           70
total physical controls           70
total distinct controls           70
duplicate controls                 0
missing controls                   0
non-PASS controls                  0
boundary violations                0
stage status                      PASS for every node
```

Specifically:

```text
Node 1 physical source:
msbf_ctl.m1_17_end_to_end_evidence_snapshot

Node 4 physical sources:
msbf_ctl.run_evidence
plus the M2.3 physical policy-boundary reconstruction
```

### Grid 3 — state summary

Require:

```text
state_verification_status                 PASS
predecessor_rows                          1
run_code                                  M1_V0_2_BASELINE_BUILD
run_version                               1
run_status                                M2_11_ACCEPTED
contract_status                           ACCEPTED
installed_top_level_objects               21
policy_rows                               1
nonpolicy_rows                            0
m2_12_evidence_rows                       0
g3_result_rows                            0
gate_rows                                 1
exact_gate_rows                           1
policy_sequence_state                     1|true
archive_sequence_state                    1|false
registry_sequence_state                   1|false
source_graph_rows                         19
source_graph_pass_rows                    19
stage_boundary_rows                       12
stage_boundary_pass_rows                  12
stage_boundary_required_controls          70
stage_boundary_physical_controls          70
disposition                               READY_TO_EXECUTE_PROGRAM_222_HF8
```

Export all three visible grids with:

```text
Use fetched rows       ON
Query the database     OFF
Open new connection    OFF
```

Recommended filenames:

```text
222_HF8_pre_execution_source_graph_detail.csv
222_HF8_pre_execution_stage_boundary_detail.csv
222_HF8_pre_execution_state_summary.csv
```

Any error, missing grid, non-PASS row, count mismatch, source mismatch, or export anomaly is a hard stop.

## 3. Execute Program 222 HF8 only

After the verifier passes exactly, execute:

```text
222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF8.sql
```

Require SHA-256:

```text
aa879a83a36f79f8b215110d5a349fbf0982a441cecd52284d5227ebfcc72fb9
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

The governing authority requires one whole physical file per invocation and prohibits an outer transaction or concatenated programs. [export reference: filecite | turn10file6 | L22-L32]

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

Export the visible result immediately with **Use fetched rows**.

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

- Download the HF8 Programs 223–227 hold notice (historical reference: `sandbox:[session]/M2_12_PROGRAMS_223_227_HOLD_NOTICE_HF8.md`; referenced bytes not established here)

Program 223 remains held until the complete HF8 verifier output, Program 222 transcript, process status, primary result, persistent counts, 24 generation-evidence rows, lifecycle, hashes, and all three owned sequence states reconcile exactly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2d076202-a60b-4d4e-97ca-3fe8b797bd91"></a>
## Andrew / user · C085-M00068

C085-M00068 · 2026-08-11T08:47:00.389000-04:00 · active path

Preceding visible parent: [C085-M00067](part-03.md#m-2f36902e-df8c-488c-9e23-a47afaaa56e7)

**Editorial record note:** Attachment references: 222_HF8_pre_execution_source_graph_detail_20260811.csv; 222_HF8_pre_execution_stage_boundary_detail_20260811.csv; 222_HF8_pre_execution_state_summary_20260811.csv

<!-- BEGIN_SOURCE_MESSAGE -->
another 222 error: SQL Error [42702]: ERROR: column reference "module1_run_id" is ambiguous
  Position: 1549
  ERROR: column reference "module1_run_id" is ambiguous
  Position: 1549             correct error in a hotfix and do not wait for my approval. i selected stop and used rollback. when correcting error, do not correct this error and stop, review the rest of program 222 for additional, similar/noticeable errors. 222 pre-run evidence attached.       
<!-- END_SOURCE_MESSAGE -->


<a id="m-34c0e7f8-7ee4-493e-b672-07bf7ab96a44"></a>
## Assistant · C085-M00069

C085-M00069 · 2026-08-11T08:47:18.163022-04:00 · active path

Preceding visible parent: [C085-M00068](part-03.md#m-2d076202-a60b-4d4e-97ca-3fe8b797bd91)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll reconcile the attached verifier evidence, isolate the ambiguous reference, then scan all 206 Program 222 statements for similar aliasing and other reachable SQL defects before packaging the hotfix.
<!-- END_SOURCE_MESSAGE -->


<a id="m-15e814cf-9b88-4e3f-8f1a-dee7c21f35f2"></a>
## Assistant · C085-M00070

C085-M00070 · 2026-08-11T08:50:23.542298-04:00 · active path

Preceding visible parent: [C085-M00069](part-03.md#m-34c0e7f8-7ee4-493e-b672-07bf7ab96a44)

<!-- BEGIN_SOURCE_MESSAGE -->
The verifier is clean: all 19 source edges and 12 stage boundaries passed with a pristine target. The ambiguity recurs in later hash-staging queries, so I’m correcting that family.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b93d65d5-291c-4383-b6c5-16bcf2aae8f3"></a>
## Assistant · C085-M00071

C085-M00071 · 2026-08-11T09:17:31.055589-04:00 · active path

Preceding visible parent: [C085-M00070](part-03.md#m-15e814cf-9b88-4e3f-8f1a-dee7c21f35f2)

<!-- BEGIN_SOURCE_MESSAGE -->
The deeper review also found aggregate/grouping, unquoted-status, tautological-filter, and evidence-key parity defects; HF9 corrects them and passes a separate 133-control physical readback.
<!-- END_SOURCE_MESSAGE -->
