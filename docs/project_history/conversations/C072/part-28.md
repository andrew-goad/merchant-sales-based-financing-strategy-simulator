# PostgreSQL M1.14 Execution

Part 28 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-27.md)
[Next part](part-29.md)

<a id="m-ea7541a3-f776-4ca2-908f-c42b7c440d0f"></a>
## Assistant · C072-M00343

C072-M00343 · 2026-08-12T14:14:43.756252-04:00 · active path

Preceding visible parent: [C072-M00342](part-27.md#m-2d7d40da-f3e0-4c3e-be55-d47c08ba19ac)

<!-- BEGIN_SOURCE_MESSAGE -->
# MSBF Campaign Readiness Rebase v0.2 complete

The accepted M2.12 full-project repository was used as the sole source baseline:

```text
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

ZIP entries                         5,271
Numbered stages                        31
Final stage                       31_M2_12
ZIP CRC                             PASS
```

The accepted package preserves all 30 predecessor stages with zero differences and embeds an M2.12 stage identical to the accepted standalone package. [export reference: filecite | turn189file0 | L35-L51]

## Determination

```text
READ_ONLY_REBASE_COMPLETE_WITH_BLOCKERS

SQL generated or modified                    0
PostgreSQL connections opened                0
Business SQL executions                      0
750 replay authorized                        NO
25,000 campaign authorized                   NO
```

The full rebase package passed 25/25 static validation controls, ZIP CRC, path-safety, duplicate-path and internal manifest validation.

## Exact current campaign inventory

| Area | Current result |
|---|---:|
| Normal campaign positions | **230** |
| Physical normal source files | **229** |
| Missing physical source positions | **1 — M1.17 Program 127** |
| Normal source SHA-256 mismatches | **0** |
| M1.17 campaign positions blocked | **8** |
| Recovery/contingency catalog rows | **128** |
| Normal/recovery path overlaps | **0** |
| Automatically invokable recoveries | **0** |

The former plan contained 214 positions through M2.10. The accepted M2.11 and M2.12 stages add eight normal programs each, producing the exact 230-position current plan. The prior audit had already identified Program 127 as absent and the full M1.17 clean-build chain as unconsolidated. [export reference: filecite | turn190file2 | L197-L214] [export reference: filecite | turn191file5 | L105-L124]

The **128 recovery count uses the same catalog definition as Readiness Audit v0.1**:

```text
Predecessor recovery/contingency rows       120
M2.11 current recoveries                      4
M2.12 current recoveries                      4
                                            ---
Total                                       128
```

That catalog includes recovery, repair, reconstruction and diagnostic utilities. None appears in the normal execution chain.

## Checkpoint and reporting rebase

```text
Non-report checkpoint inventory rows        174
Active checkpoint specifications            166
Existing compiled specifications            154
  Existing read-only SQL queries             127
  Existing program-output assertions          27
New M2.11/M2.12 checkpoints to compile        12
Blocked M1.17 checkpoint positions             8

Report definitions                           56
  Existing reusable definitions              52
  New M2.11/M2.12 definitions                 4

Master-report programs                       28
Detail-report programs                       28
Detailed result sets                        554
Total governed report result sets           582
New result-retention rows to compile          50
```

The prior v0.2/v0.3 compiler had 154 checkpoint definitions, 127 generated checkpoint queries, 27 program-output assertions, 52 report definitions and 506 detailed result sets. [export reference: filecite | turn190file4 | L270-L282] The v0.3 adapter remains statically valid, but its native Windows PowerShell/`psql`/PostgreSQL certification is still pending. [export reference: filecite | turn190file3 | L227-L259]

## v0.1–v0.3 reuse conclusion

| Prior asset set | Rebase disposition |
|---|---|
| Readiness Audit v0.1 | Reuse schemas, gap taxonomy and predecessor analysis; regenerate all physical counts, paths and plans from M2.12 |
| Harness v0.1 | Reuse architecture, dry-run compiler, source-hash validation and recovery-exclusion model |
| Harness v0.2 | Reuse checkpoint control language and evidence-export compiler; append 12 checkpoints, four reports and 50 result rows |
| Harness v0.3 | Reuse native read-only adapter, safety classifier, report splitter, retention policy and artifact registry; complete native certification |

Reference dry-run and static-test outputs remain historical evidence only and are not represented as current M2.12 compile results.

A nonblocking provenance note is recorded in the package: the physically available Readiness Audit v0.1 and Harness v0.1 ZIPs are CRC-valid, but their adjacent sidecars correspond to earlier package generations. The rebase used independently recalculated physical ZIP hashes and did not treat those stale sidecars as current byte authority.

## Exact M1.17 remediation surface

```text
Program 124     accepted component present
Program 125     original source only
Program 126     original source only
Program 127     physical source absent
Program 128     original source only
Program 129     accepted component present
Program 130     accepted master report present
Program 131     accepted detail report present
```

All eight campaign positions remain blocked together because the runner must consume one coherent, version-aligned source set—not a mixture of accepted components, original files and a missing validation program.

The required closure is narrowly defined:

1. Reconstruct and formally approve a campaign clean-build source set for Programs 124–131.
2. Integrate all accepted M1.17 corrections.
3. Preserve the complete original/hotfix provenance map.
4. Never label reconstructed files as the historical executed bytes.
5. Make Program 127 idempotent or fail safely after `M1_17_VALIDATED`.
6. Compile the eight M1.17 checkpoint/report definitions.
7. Prove exact accepted results during the future 750 golden replay.

## Remaining campaign-parameterization gaps

The rebase contains **20 governed gaps**:

```text
BLOCKER       2
HIGH          9
MEDIUM        7
INFO          2
```

The two blockers are:

- **CR-001:** M1.17 clean-build source closure.
- **CR-020:** no automated full-chain clean-build replay has yet reproduced the accepted 750-application result.

The principal high-priority areas are:

- campaign/run identity;
- scale-dependent cardinalities and hashes;
- deterministic dates and lifecycle windows;
- pristine-database and resume behavior;
- M2.11 strategy-simulation scaling;
- M2.12 fixed-versus-scale-dependent certification expectations;
- native adapter certification;
- strict final-source selection where accepted hotfix and superseded files coexist.

The included scale model now covers **750, 2,500 and 25,000** and adds M2.11/M2.12 estimates. These are planning estimates—not accepted expected results. CR-WP2 must freeze the governing formulas before any overlay source is produced.

## Bounded work packages before the 750 replay

```text
CR-WP1  M1.17 Governed Clean-Build Source Closure

CR-WP2  Campaign Configuration &
        Expected-Results Freeze

CR-WP3  Module 1 Campaign Source Overlay

CR-WP4  Module 2 Campaign Source Overlay

CR-WP5  Harness v0.4 Definition Rebase &
        Native Read-Only Certification

CR-WP6  Campaign Business Execution &
        Evidence Harness v1

CR-WP7  750 Golden Replay Readiness Gate
```

The 750 replay itself remains a separately authorized live action after CR-WP1–CR-WP7. A successful exact 750 replay would then permit the 2,500-application performance shakedown—not the 25,000 run immediately.

# Delivery

## Complete package

- Download MSBF Campaign Readiness Rebase v0.2 (historical reference: `sandbox:[session]/MSBF_Campaign_Readiness_Rebase_v0_2_M2_12.zip`; referenced bytes not established here)
- Download the matching SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_Campaign_Readiness_Rebase_v0_2_M2_12.zip.sha256`; referenced bytes not established here)
- Read the package-validation report (historical reference: `sandbox:[session]/MSBF_Campaign_Readiness_Rebase_v0_2_M2_12_VALIDATION_REPORT.md`; referenced bytes not established here)

```text
Package SHA-256
cb286989dfc3816d4c22238bb166d8cdf0d9db486d9dae01d7dc9aa723eb23fe

ZIP entries
38

ZIP CRC
PASS

Payload manifest
34 / 34 PASS
```

## Primary review artifacts

- Main rebase report (historical reference: `sandbox:[session]/CAMPAIGN_READINESS_REBASE_REPORT_v0_2.md`; referenced bytes not established here)
- Machine-readable summary (historical reference: `sandbox:[session]/CAMPAIGN_READINESS_REBASE_MACHINE_SUMMARY.json`; referenced bytes not established here)
- Complete 230-position execution plan (historical reference: `sandbox:[session]/CAMPAIGN_NORMAL_EXECUTION_PLAN_M2_12.csv`; referenced bytes not established here)
- Complete 128-row recovery catalog (historical reference: `sandbox:[session]/CAMPAIGN_RECOVERY_PROGRAM_CATALOG_M2_12.csv`; referenced bytes not established here)
- Checkpoint and report rebase report (historical reference: `sandbox:[session]/CAMPAIGN_CHECKPOINT_REPORT_REBASE_REPORT.md`; referenced bytes not established here)
- Harness-release reuse summary (historical reference: `sandbox:[session]/CAMPAIGN_HARNESS_RELEASE_REUSE_SUMMARY.csv`; referenced bytes not established here)
- Exact M1.17 remediation surface (historical reference: `sandbox:[session]/CAMPAIGN_M1_17_EXACT_REMEDIATION_SURFACE.csv`; referenced bytes not established here)
- M1.17 clean-build closure requirement (historical reference: `sandbox:[session]/CAMPAIGN_M1_17_GOVERNED_CLEAN_BUILD_CLOSURE_REQUIREMENT.md`; referenced bytes not established here)
- Campaign parameterization gap register (historical reference: `sandbox:[session]/CAMPAIGN_PARAMETERIZATION_GAP_REGISTER_M2_12.csv`; referenced bytes not established here)
- Seven-work-package plan (historical reference: `sandbox:[session]/CAMPAIGN_PRE_750_REPLAY_WORK_PACKAGE_PLAN.csv`; referenced bytes not established here)
- Pre-750 replay roadmap (historical reference: `sandbox:[session]/CAMPAIGN_PRE_750_REPLAY_ROADMAP.md`; referenced bytes not established here)

The clean next move is to open **CR-WP1 and CR-WP2 as separate governed work packages**. CR-WP1 resolves the sole physical source gap; CR-WP2 freezes the campaign configuration and expected-results formulas without modifying SQL.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bb58b6ad-1f21-4eba-9263-128f8b4eb4ba"></a>
## Andrew / user · C072-M00344

C072-M00344 · 2026-08-12T14:35:06.074000-04:00 · active path

Preceding visible parent: [C072-M00343](part-28.md#m-ea7541a3-f776-4ca2-908f-c42b7c440d0f)

**Editorial record note:** Attachment references: MSBF_Data_After_M2_12_Sign_Off(1).zip; MSBF_Data_After_M2_12_Sign_Off_INGESTION_SUMMARY(1).json; MSBF_Data_After_M2_12_Sign_Off_INVENTORY(2).csv; MSBF_Data_After_M2_12_Sign_Off_INGESTION_REPORT(1).md

<!-- BEGIN_SOURCE_MESSAGE -->
Thank you. I will review in a moment. In the meantime, please take a moment to ingest the database as of m2.12 sign off
<!-- END_SOURCE_MESSAGE -->


<a id="m-3920828e-04ee-4d98-a53a-d3ec180d51b1"></a>
## Assistant · C072-M00345

C072-M00345 · 2026-08-12T14:37:35.374939-04:00 · active path

Preceding visible parent: [C072-M00344](part-28.md#m-bb58b6ad-1f21-4eba-9263-128f8b4eb4ba)

<!-- BEGIN_SOURCE_MESSAGE -->
The post-M2.12 database snapshot is ingested and will be treated as the **authoritative accepted physical data-state reference** for campaign preparation.

```text
Source archive
MSBF_Data_After_M2_12_Sign_Off.zip

Bytes
159,204,509

SHA-256
25927513da1b4d4fd4fea9a35e2f3b59ea280db22b5ae4c77728e5438f94dbc3

ZIP entries
510

ZIP CRC
PASS
```

[export reference: filecite | turn193file1 | L3-L13]

## Ingested database scope

```text
Logical objects                         253
Complete CSV/SQL object pairs           253
Missing CSV files                         0
Missing SQL files                         0
CSV parse failures                        0
SQL target mismatches                     0

Total data rows                    1,115,469
Nonempty objects                        233
Empty objects                            20
```

The schema-level population is:

| Schema | Objects | Rows |
|---|---:|---:|
| `msbf_ctl` | 69 | 5,050 |
| `msbf_m1` | 52 | 1,039,364 |
| `msbf_m2` | 117 | 70,861 |
| `msbf_ref` | 15 | 194 |

[export reference: filecite | turn193file1 | L16-L35]

## Accepted M2.12 database checkpoint

```text
Run                         M1_V0_2_BASELINE_BUILD v1
Run status                  M2_12_ACCEPTED
G3 bundle                   M2_G3_CONSUMPTION_BUNDLE v1
G3 contract status          ACCEPTED
G3 gate status              PASS

Canonical families          9
Canonical entities          134
Application rows            1,500
Operational rows            59
Strategy rows               24

Positive controls           128 / 128 PASS
Negative controls           20 / 20 PASS
Generation evidence         24 / 24 PASS
Acceptance evidence         1 / 1 PASS
M2.12 evidence              173 / 173 PASS

Contract set hash
38e76e3e05f19064f2f1de41b7c33d52

Combined set hash
28d832719a63d5669a18016f15ba43fb

Registry row hash
16268274b151eeab60f4423ec094f4b5
```

[export reference: filecite | turn193file1 | L42-L62]

This also gives us a strong physical calibration point for the scale work. At the accepted 750-application baseline, the database already contains approximately **1.12 million rows**, dominated by:

```text
merchant_pos_daily_scenario          270,000
merchant_deposit_daily_scenario      270,000
merchant_pos_daily_base              135,000
merchant_deposit_daily_base          135,000
application_ead_path_value            93,720
cashflow_feature_value                54,000
```

[export reference: filecite | turn193file1 | L65-L80]

One boundary is important: this archive is a **data-state export**, with paired CSV datasets and SQL row-reload scripts. It is not by itself a complete PostgreSQL structural dump of DDL, constraints, indexes, functions, triggers, sequences, or views. The accepted M2.12 full-project repository remains the structural/source authority. [export reference: filecite | turn193file1 | L105-L109]

I will therefore use the two accepted baselines together:

```text
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip
    structural, SQL, governance and execution-plan authority

MSBF_Data_After_M2_12_Sign_Off.zip
    accepted physical data-state and row-volume authority
```

No source file or database export was modified during ingestion.
<!-- END_SOURCE_MESSAGE -->


<a id="m-72726ec1-8a06-44d0-90e8-6b872eb1ad63"></a>
## Andrew / user · C072-M00346

C072-M00346 · 2026-08-12T14:48:39.687000-04:00 · active path

Preceding visible parent: [C072-M00345](part-28.md#m-3920828e-04ee-4d98-a53a-d3ec180d51b1)

<!-- BEGIN_SOURCE_MESSAGE -->
What do you mean by: The clean next move is to open CR-WP1 and CR-WP2 as separate governed work packages. CR-WP1 resolves the sole physical source gap; CR-WP2 freezes the campaign configuration and expected-results formulas without modifying SQL.     Explain next steps in detail and explain how to carry them out. Are these chat prompts or something more? In this chat or in a new chat?
<!-- END_SOURCE_MESSAGE -->


<a id="m-187e3d09-db4e-4c83-a70f-f1685c364f65"></a>
## Assistant · C072-M00347

C072-M00347 · 2026-08-12T15:01:41.165330-04:00 · active path

Preceding visible parent: [C072-M00346](part-28.md#m-72726ec1-8a06-44d0-90e8-6b872eb1ad63)

<!-- BEGIN_SOURCE_MESSAGE -->
# What CR-WP1 and CR-WP2 actually are

They are **governed work packages**, not merely chat prompts.

A prompt is only the opening instruction that starts a work package. The complete work package includes:

```text
1. Fixed governing inputs and SHA-256 identities
2. Precisely bounded scope
3. Required deliverables
4. Prohibited actions
5. Static validation controls
6. A packaged output ZIP and sidecar
7. Independent audit in a separate chat
8. Correction rounds, if required
9. Final signoff
10. Authorization—or refusal—to begin the next package
```

That is the same control model we used for M2.11 and M2.12.

The accepted M2.12 full-project ZIP remains the immutable source baseline. It contains 31 numbered stages, including accepted stage `31_M2_12`, with all 30 predecessor stages preserved exactly. [export reference: filecite | turn193file2 | L35-L52]

The two opening packages solve different problems:

| Work package | Problem solved | Produces SQL? | Executes PostgreSQL? |
|---|---|---:|---:|
| **CR-WP1** | The complete M1.17 clean-build source chain is not physically available as one coherent set | **Yes**, but only a new external campaign clean-build replacement | **No** |
| **CR-WP2** | The future 750/2,500/25,000 campaigns do not yet have frozen identities, parameters, dates, formulas, and expected results | **No** | **No** |

The exact seven-package roadmap is in:

- Pre-750 work-package plan (historical reference: `sandbox:[session]/CAMPAIGN_PRE_750_REPLAY_WORK_PACKAGE_PLAN.csv`; referenced bytes not established here)
- Pre-750 roadmap (historical reference: `sandbox:[session]/CAMPAIGN_PRE_750_REPLAY_ROADMAP.md`; referenced bytes not established here)
- Campaign Readiness Rebase report (historical reference: `sandbox:[session]/CAMPAIGN_READINESS_REBASE_REPORT_v0_2.md`; referenced bytes not established here)

# Recommended chat structure

I recommend **three distinct chat roles**.

## This chat: campaign governance and independent audit

Keep this chat as the control room. It should:

- define the build prompts;
- determine which files each build chat receives;
- independently audit returned packages;
- issue signoff or correction instructions;
- control progression from one work package to the next.

This chat should **not** construct CR-WP1 or CR-WP2 itself. Keeping construction and audit separate prevents the build process from grading its own work and preserves the review boundary we used throughout M2.11 and M2.12.

## New Chat 1: CR-WP1 build chat

Create a dedicated chat titled approximately:

```text
MSBF Campaign Build — CR-WP1
M1.17 Governed Clean-Build Source Closure
```

That chat should do nothing outside CR-WP1.

## New Chat 2: CR-WP2 build chat

Create a second dedicated chat titled approximately:

```text
MSBF Campaign Build — CR-WP2
Campaign Configuration & Expected-Results Freeze
```

That chat should do nothing outside CR-WP2.

## Should they run in parallel?

They can be **designed** in parallel, but I recommend a controlled stagger:

```text
Start CR-WP1
      ↓
CR-WP1 establishes its exact source/provenance/interface decisions
      ↓
Start or finalize CR-WP2
```

CR-WP2 can begin preliminary work immediately—campaign identities, scale profiles, date rules, and count-formula architecture do not depend entirely on M1.17. But CR-WP2 should not receive final signoff until CR-WP1 has frozen the exact M1.17 clean-build interfaces that the expected-results formulas must reference.

That approach minimizes rework.

# CR-WP1 in detail

## Purpose

CR-WP1 closes the only missing physical normal-source position and converts the full M1.17 chain into one coherent, campaign-runnable source set.

The earlier readiness audit found:

- original source for Programs 125, 126, and 128;
- no retained final clean-build Program 127;
- accepted components for Programs 124, 129, 130, and 131;
- no consolidated pristine M1.17 source chain. [export reference: filecite | turn190file4 | L166-L185]

That means the accepted database state is valid, but a new database cannot yet be built automatically from G0 through M2.12 using one source-frozen plan.

## What CR-WP1 must produce

The work-package plan requires:

```text
Programs 124–131
8 / 8 physical clean-build source files

Source authority
Program-order authority
Historical-to-clean-build provenance matrix
Static semantic-equivalence audit
M1.17 checkpoint definitions
M1.17 report definitions
Source SHA-256 inventory
Review package
ZIP and external sidecar
```

The new files must be clearly labeled:

```text
GOVERNED CAMPAIGN CLEAN-BUILD REPLACEMENT
```

They must **not** be labeled as the historical SQL bytes originally executed in July 2026.

## CR-WP1 construction phases

### Phase 1 — freeze the inputs

The CR-WP1 chat should verify:

```text
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip
SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

MSBF_Campaign_Readiness_Rebase_v0_2_M2_12.zip
SHA-256
cb286989dfc3816d4c22238bb166d8cdf0d9db486d9dae01d7dc9aa723eb23fe
```

It should inspect the complete `19_M1_17` stage, including original sources, hotfixes, acceptance evidence, source-authority records, and reporting artifacts.

### Phase 2 — build a final-semantics matrix

Before writing SQL, the chat should document, program by program:

| Program | Required determination |
|---:|---|
| 124 | Which accepted schema, policy, trigger, function, and view changes define the clean-build version |
| 125 | Exact accepted-source and pristine-target preflight semantics |
| 126 | Exact final generation behavior, hashes, sequences, and writes |
| 127 | Complete positive-validation design and accepted control population |
| 128 | Exact isolated negative-control design |
| 129 | Final G2 acceptance-finalizer behavior |
| 130 | Final one-row master-report behavior |
| 131 | Final governed detailed-report behavior |

No source should be written until every downstream dependency and accepted correction is mapped.

### Phase 3 — construct the eight clean-build files

These are new campaign-source files located **outside** the accepted M2.12 repository.

The accepted ZIP is never edited.

Each source must have:

- elite header and purpose;
- predecessor and lifecycle requirements;
- exact read and write boundaries;
- transaction model;
- temporary-object namespaces;
- expected outputs;
- checkpoint behavior;
- recovery boundary;
- explicit statement order;
- source SHA-256.

### Phase 4 — static equivalence review

The CR-WP1 build must prove, without executing PostgreSQL:

```text
Source positions present                         8 / 8
Program 127 substantive validation authority     COMPLETE
Undefined source objects                           0
Unmapped physical fields                           0
Unresolved joins or casts                          0
Unresolved hash preimages                          0
Unresolved sequence behavior                       0
Positive-control ambiguity                         0
Negative-control ambiguity                         0
Acceptance-gate ambiguity                          0
Report projection/cardinality ambiguity            0
Historical-executed-byte claims                    0
Accepted repository files modified                 0
PostgreSQL executions                              0
```

### Phase 5 — package and stop

The build chat should issue one CR-WP1 review ZIP and sidecar and then stop.

You would bring that package back here for independent audit. This chat would approve it, identify bounded corrections, or reject it.

## What CR-WP1 does **not** prove yet

CR-WP1 does not prove that the reconstructed chain works in PostgreSQL.

That proof happens later during the fresh-database **750 golden replay**. CR-WP1 proves that the source authority is complete, deterministic, internally consistent, and ready for later execution testing.

## Files to attach to the CR-WP1 build chat

Use:

1. `M2_12_FULL_PROJECT_ACCEPTED_20260812.zip`
2. its sidecar
3. `MSBF_Campaign_Readiness_Rebase_v0_2_M2_12.zip`
4. its sidecar
5. `CAMPAIGN_M1_17_EXACT_REMEDIATION_SURFACE.csv`
6. `CAMPAIGN_M1_17_GOVERNED_CLEAN_BUILD_CLOSURE_REQUIREMENT.md`
7. `CAMPAIGN_NORMAL_EXECUTION_PLAN_M2_12.csv`

The 159 MB database-state archive is not essential to the opening CR-WP1 source reconstruction. Its summary and inventory are enough initially; the full snapshot can be supplied if a physical accepted-result comparison requires it.

# CR-WP2 in detail

## Purpose

CR-WP2 freezes the **campaign design**, not SQL.

It answers:

```text
What is the campaign identity?
How many applications are generated?
Which scenarios are used?
What dates and history windows apply?
Which deterministic seeds and key ranges apply?
Which expected counts scale?
Which counts remain fixed?
Which hashes should reproduce exactly?
Which hashes should change because the campaign identity changes?
What should every checkpoint and report expect at each scale?
```

The accepted database snapshot gives the physical calibration baseline:

```text
253 paired logical objects
1,115,469 total data rows
M2_12_ACCEPTED / ACCEPTED
128 / 128 positive controls
20 / 20 negative controls
24 / 24 generation evidence
48 / 48 acceptance requirements
```

[export reference: filecite | turn193file1 | L16-L40] [export reference: filecite | turn193file1 | L42-L62]

The snapshot is the accepted **data-state** authority, while the full-project ZIP remains the DDL, SQL, constraint, trigger, sequence, and view authority. [export reference: filecite | turn193file1 | L105-L109]

## Three campaign profiles

CR-WP2 should freeze three separate profiles.

### Profile A — 750 golden replay

Purpose:

```text
Prove that the clean-build sources and harness can reproduce
the accepted baseline from an empty disposable database.
```

I recommend that this profile preserve:

- accepted 750-application population;
- two accepted scenarios;
- accepted deterministic seed;
- accepted as-of date and 180-day history window;
- accepted parameter values;
- accepted run identity, but only inside a disposable replay database.

That gives us the strongest possible test: exact accepted counts, outcomes, controls, and—where the run identity participates in the hash preimage—exact accepted hashes.

The profile must be marked:

```text
DISPOSABLE ACCEPTED-FIDELITY REPLAY
NOT A NEW BUSINESS CAMPAIGN
```

### Profile B — 2,500-application shakedown

Purpose:

```text
Test scale, performance, storage, export size,
resume behavior, and evidence automation.
```

This profile should use a new campaign identity and new parameter-set identity. Its expected hashes will be newly derived because the run and population identities change.

### Profile C — 25,000-application full campaign

Purpose:

```text
Execute the full governed scale campaign after the
750 replay and 2,500 shakedown both pass.
```

This also receives its own run code, version, population identity, campaign code, database name, timestamps, and parameter-set hash.

## CR-WP2 must classify every expected result

Each expectation should fall into one of four classes:

| Class | Meaning | Example |
|---|---|---|
| **FIXED_INVARIANT** | Does not change with application count | number of scenarios, control definitions, capability rows |
| **SCALE_DERIVED** | Changes by a formula tied to application count | 750 applications × 2 scenarios = 1,500 application-scenario rows |
| **CAMPAIGN_IDENTITY_DERIVED** | Value changes because run/population/campaign identity changes | combined hashes containing run identity |
| **DATA_OUTCOME_DERIVED** | Must be calculated from deterministic generated outcomes | approvals, activations, strategy candidates, monitoring rows |

This prevents the dangerous approach of replacing every `750` with `25,000`.

## CR-WP2 construction phases

### Phase 1 — parameter inventory

Inventory every parameter affecting the 230-position chain:

```text
database name
run code
run version
population code/version
campaign code/version
deterministic seed/version
planned application count
scenario set
scenario codes
application as-of date
history start/end
history day count
contract versions
campaign-specific source and output paths
owned sequence starting states
evidence sampling rules
```

### Phase 2 — dependency mapping

For each parameter, identify:

```text
which programs consume it
which tables it affects
which checkpoints depend on it
which reports depend on it
which hashes include it
which row counts derive from it
```

This should cover all 230 program positions.

### Phase 3 — formula catalog

Create formula-driven expectations such as:

```text
application rows
    = application_count

application × scenario rows
    = application_count × scenario_count

base daily POS rows
    = application_count × history_days

scenario daily POS rows
    = application_count × scenario_count × history_days
```

Some downstream tables will require outcome-rate or stage-specific formulas rather than simple multiplication. Those must be explicitly identified rather than guessed.

At the accepted 750 scale, the database already contains 1,115,469 rows across the 253 exported objects, with the largest tables being the daily base and scenario histories. [export reference: filecite | turn193file1 | L65-L80] That physical state is the calibration surface for determining which relations scale linearly and which are outcome-dependent.

### Phase 4 — expected-results authorities

The work package should produce:

```text
CAMPAIGN_EXPECTED_RESULTS_750.json
CAMPAIGN_EXPECTED_RESULTS_2500.json
CAMPAIGN_EXPECTED_RESULTS_25000.json
```

Each should define:

- expected object counts;
- expected row counts or formulas;
- accepted fixed domains;
- control counts;
- evidence counts;
- checkpoint statuses;
- report cardinalities;
- hash construction rules;
- sequence expectations;
- allowable zero-row outputs;
- scale-dependent tolerances, if any.

### Phase 5 — campaign identity hashes

Each profile gets one deterministic configuration hash calculated from the complete ordered parameter set.

```text
750 replay config hash
2,500 shakedown config hash
25,000 campaign config hash
```

Once frozen, downstream source overlays and harness packages must reference those exact hashes.

### Phase 6 — review package and stop

CR-WP2 should package:

```text
Campaign configuration specification
Parameter dictionary
Three parameter sets
Count/formula catalog
230-position dependency matrix
Hash classification matrix
Sequence/date rules
Three expected-results JSON files
Static validation
Source authority
ZIP and sidecar
```

It stops without writing SQL or opening PostgreSQL.

## CR-WP2 approval standard

```text
Unresolved required parameters                      0
Unclassified expected results                       0
Unresolved count formulas                           0
Unresolved date formulas                            0
Unresolved scenario formulas                        0
Unresolved hash-preimage dependencies               0
Unresolved owned-sequence behavior                  0
Programs without parameter-impact classification    0
750 accepted-fidelity discrepancies                 0
Accepted repository files modified                  0
SQL generated                                       0
PostgreSQL executions                               0
```

## Files to attach to the CR-WP2 build chat

Use:

1. accepted M2.12 full-project ZIP and sidecar;
2. Campaign Readiness Rebase v0.2 ZIP and sidecar;
3. `MSBF_Data_After_M2_12_Sign_Off.zip`;
4. its ingestion summary, inventory, and report;
5. the campaign parameterization gap register;
6. the 230-position execution plan;
7. the CR-WP1 source/interface package once available.

# What follows CR-WP1 and CR-WP2

These two packages do not yet produce a runnable campaign.

They establish the two foundations required by everything downstream:

```text
CR-WP1
complete source chain

CR-WP2
complete campaign and expected-results definition
```

Then:

## CR-WP3 — Module 1 campaign source overlay

Generate campaign-specific versions of G1 and M1.2–M1.17 outside the accepted repository.

This resolves fixed run identities, dates, counts, and parameter references for the chosen profile.

## CR-WP4 — Module 2 campaign source overlay

Generate campaign-specific versions of M2.1–M2.12 using the frozen Module 1 output contracts.

This is where M2.11 and M2.12 fixed-versus-scale-dependent boundaries are formally implemented.

## CR-WP5 — Harness v0.4 and native read-only certification

Rebase the existing harness to:

```text
230 normal positions
166 active checkpoint specifications
56 report definitions
582 governed report outputs
```

Then certify the PowerShell/`psql` read-only adapter on a disposable Windows PostgreSQL database.

The existing harness v0.2 compiled 154 checkpoint definitions and 52 report requirements but intentionally opened no database connection and executed no business SQL. [export reference: filecite | turn190file16 | L932-L970]

## CR-WP6 — Business execution and evidence harness v1

Build the actual non-business runner:

```text
one program per invocation
source SHA-256 verification
ON_ERROR_STOP
checkpoint PASS required before release
msbf_ops execution ledger
targeted evidence export
governed resume
no automatic recovery
directed recovery authorization
final pg_dump and evidence package
```

## CR-WP7 — 750 replay readiness gate

Seal the complete 750 replay package and prove every source, configuration, checkpoint, report, environment, rollback, resume, and recovery dependency resolves.

CR-WP7 still does not execute the replay.

## Then the live sequence

```text
750 accepted-fidelity golden replay
        ↓
independent fidelity audit
        ↓
2,500-application shakedown
        ↓
performance and evidence audit
        ↓
25,000-application campaign authorization
        ↓
25,000 campaign
```

# Practical execution process

For each work package:

```text
Step 1
This chat prepares the exact opening prompt and attachment list.

Step 2
You open the dedicated build chat and attach the governed inputs.

Step 3
The build chat performs only the authorized package.

Step 4
It returns a ZIP, sidecar, validation records and review report.

Step 5
You bring those outputs back to this chat.

Step 6
This chat performs an independent audit.

Step 7
The package is approved, corrected, or rejected.

Step 8
Only an approved package can authorize the next work.
```

# Recommended order now

The most reliable route is:

```text
1. Open the CR-WP1 build chat first.
2. Complete CR-WP1 source/provenance design and construction.
3. Return CR-WP1 here for audit.
4. Open CR-WP2 once CR-WP1’s M1.17 interface authority is stable.
5. Return CR-WP2 here for audit.
```

CR-WP2 preliminary design can run in parallel, but delaying its final freeze until CR-WP1 stabilizes will reduce the likelihood of another long correction cycle.

So, in direct terms:

> **CR-WP1 and CR-WP2 are separate governed builds started by prompts, performed in separate new build chats, and independently reviewed in this chat. They are much more than prompts, and neither package executes PostgreSQL.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-3a288d77-a3ba-45fe-b76e-0501f4b289a7"></a>
## Andrew / user · C072-M00348

C072-M00348 · 2026-08-12T15:28:31.671000-04:00 · active path

Preceding visible parent: [C072-M00347](part-28.md#m-187e3d09-db4e-4c83-a70f-f1685c364f65)

<!-- BEGIN_SOURCE_MESSAGE -->
Would CR-WP1 be solved by me looking back for M1.17 sign off package? I have artifacts saved from each module sign off (zip as it was then, etc)? Why rebuild if it's a matter of just going back and locating? Let me know what to look for if so.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ef52a08e-ca9b-45fa-a03f-e2d9bf4b4bd0"></a>
## Assistant · C072-M00349

C072-M00349 · 2026-08-12T15:28:41.790303-04:00 · active path

Preceding visible parent: [C072-M00348](part-28.md#m-3a288d77-a3ba-45fe-b76e-0501f4b289a7)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **Before we rebuild anything in CR-WP1, we should absolutely look for the original M1.17 sign-off/build artifacts.** If you retained the module packages as you did for later modules, there is a meaningful chance CR-WP1 becomes primarily a **recovery/reconciliation exercise** rather than a reconstruction exercise.

The rebase finding was narrower than “M1.17 source never existed.” It was: **the accepted M2.12 repository does not currently contain one complete, coherent clean-build M1.17 source set**, and Program 127 in particular was not found as a usable source in that repository. That does **not** prove the source was never generated or that you no longer possess it.

### What to look for

Search your saved M1.17 materials, especially anything from the **final successful execution/sign-off round**, for these items:

- **Program 127 SQL** — this is the highest priority. Look for filenames beginning with `127_`, particularly anything describing M1.17 positive validation, 128 controls, G2 validation, or a final/hotfix/revision version.
- **Programs 124–131 as a complete set.** We want the final versions of `124`, `125`, `126`, `127`, `128`, `129`, `130`, and `131`, not necessarily their original versions.
- Any **M1.17 standalone accepted/final ZIP**, execution ZIP, final source ZIP, audit-handoff ZIP, sign-off ZIP, or full-project ZIP produced immediately after M1.17.
- M1.17 files named along the lines of `SOURCE_AUTHORITY`, `SOURCE_SHA256_INVENTORY`, `EXECUTION_ORDER`, `PROGRAM_RESPONSIBILITY_MATRIX`, `FINAL_SIGNOFF`, `ACCEPTANCE`, `AUDIT`, `MANIFEST`, `SHA256SUMS`, or `PACKAGE_INVENTORY`.
- Any **hotfix/correction packages** from the M1.17 execution, especially ones associated with Programs 124–131.

**Program 127 is the key discriminator.** If you find the actual final Program 127 source that produced the accepted 128-control result, plus sufficient source-authority/provenance records to establish its identity, that potentially eliminates the only literally missing normal-program source.

But I would like the **whole M1.17 sign-off package**, not just Program 127. The other seven positions have a different problem: files exist in the current repository, but some are original sources while others are later accepted components. We need to determine whether your historical sign-off package already contains the final coherent versions. If it does, there is no reason to reconstruct them.

### Best files to bring here

Don't spend time trying to decide which individual SQL file is correct. If you find candidate packages, **upload the ZIPs and their `.sha256` sidecars here intact**. Especially valuable would be anything resembling:

```text
M1_17_*FINAL*.zip
M1_17_*ACCEPTED*.zip
M1_17_*COMPLETE*.zip
M1_17_*EXECUTION*.zip
M1_17_*AUDIT*.zip
M1_17_*SIGNOFF*.zip
M1_17_*SOURCE*.zip
M1_17_*WP*.zip

MSBF_Project_v0_2_M1_17*.zip
MSBF_*M1_17*FULL_PROJECT*.zip
```

Also upload any loose final `127_*.sql` you find, even if you're uncertain what it is.

### What I would do with them

**Do not start the CR-WP1 build chat yet.** Bring the historical M1.17 material here first.

I would perform a narrow **M1.17 source-recovery reconciliation**:

```text
Historical packages
        ↓
Identify Programs 124–131
        ↓
Determine final/superseded status of each
        ↓
Recalculate physical SHA-256 identities
        ↓
Match source-authority and execution records
        ↓
Compare against current accepted repository
        ↓
Determine whether CR-WP1 reconstruction is still necessary
```

There are three possible outcomes.

**Best case:** all eight final sources are present, including Program 127, and their provenance is defensible. Then we do **not rebuild M1.17**. CR-WP1 becomes a much smaller packaging exercise: consolidate the recovered authoritative sources into a governed campaign clean-build source set and prove their provenance.

**Middle case:** Program 127 is recovered, but some of 124–131 still exist only as original + correction fragments. That's still a major improvement. We preserve recovered 127 and reconstruct only the genuinely fragmented positions.

**Worst case:** no final Program 127 or equivalent source can be found. Then the CR-WP1 reconstruction plan remains necessary.

There is no downside to checking first. The accepted M2.12 database is healthy and fully populated—253 exported objects and 1,115,469 rows with no missing CSV/SQL pairs—so we are solving a **future reproducibility/source-provenance problem**, not repairing the accepted database. [export reference: filecite | turn193file1 | L16-L40] And the accepted M2.12 repository itself is already physically validated with all 30 predecessor stages preserved exactly. [export reference: filecite | turn193file2 | L35-L52]

**So I would revise the immediate roadmap: search your archives for the M1.17 final/sign-off packages first. Upload whatever candidates you find here, and we'll determine whether CR-WP1 can be dramatically reduced—or eliminated as a reconstruction effort—before creating a new build chat.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-feb005df-e7b3-4d65-9bbf-0acac6eb68d6"></a>
## Andrew / user · C072-M00350

C072-M00350 · 2026-08-12T15:41:54.907000-04:00 · active path

Preceding visible parent: [C072-M00349](part-28.md#m-ef52a08e-ca9b-45fa-a03f-e2d9bf4b4bd0)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: MSBF_M1_17_v0_2R8_COMPLETE_FINAL(2).zip; MSBF_Project_v0_2_M1_17_COMPLETE_FINAL_Windows(2).zip; MSBF_M1_17_v0_2R8_Detail_Report_Contract_Row_Hash_Hotfix(1).zip; MSBF_M1_17_v0_2R7_Detail_Report_Scenario_Qualification_Hotfix(1).zip; MSBF_M1_17_v0_2R6_Acceptance_Evidence_Value_Contract_Hotfix(1).zip; MSBF_M1_17_v0_2R5_Revalidation_State_Recovery_Hotfix(1).zip; MSBF_M1_17_v0_2R4_PLpgSQL_Raise_Syntax_Recovery_Hotfix(1).zip; MSBF_M1_17_v0_2R3_Policy_Hash_Shape_Validation_Recovery_Hotfix(1).zip; MSBF_M1_17_v0_2R2_Gate_Predicate_Complete_Source_Recovery_Hotfix.zip; MSBF_M1_17_v0_2R1_G2_Gate_Definition_Preflight_Hotfix(1).zip; MSBF_M1_17_v0_2(2).zip; merchant_sales_based_financing_m1_17_end_to_end_qa_evidence_g2_contract_acceptance_v0_2R8_COMPLETE_FINAL(2).zip; merchant_sales_based_financing_project_delivery_v0_2_M1_17_COMPLETE_FINAL(2).zip; 04850c81-d855-47bc-bfe0-063ac4f22232.png

<!-- BEGIN_SOURCE_MESSAGE -->
These are all the M1.17 zips I see. The order of creation is: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-95be2eef-339b-4f5c-afad-c7febe2b44a1"></a>
## Assistant · C072-M00351

C072-M00351 · 2026-08-12T15:55:06.387801-04:00 · active path

Preceding visible parent: [C072-M00350](part-28.md#m-feb005df-e7b3-4d65-9bbf-0acac6eb68d6)

<!-- BEGIN_SOURCE_MESSAGE -->
This is exactly the archive set we needed. **The original CR-WP1 diagnosis changes materially.**

## The key discovery

The decisive package is:

MSBF M1.17 v0.2R2 Gate Predicate Complete Source Recovery Hotfix (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R2_Gate_Predicate_Complete_Source_Recovery_Hotfix.zip`; referenced bytes not established here)

It contains a synchronized `clean_build` M1.17 module with the complete normal chain:

```text
124 → 125 → 126 → 127 → 128 → 129 → 130 → 131
```

Most importantly, it physically contains the previously missing source:

```text
127_msbf_m1_17_end_to_end_validation_v0_2R2.sql

Bytes
63,210

SHA-256
6bdfb68b7dbaf1909035f95559cd9c87ec0e71555c2500fa08fafc5b6bdcf599
```

Its own root-cause record explicitly says that Program 127 was absent from the original v0.2 delivery and that R2 **“supplies a synchronized clean-build module.”**

Therefore:

> **Program 127 was not permanently lost. It was absent only from the later final-packaging workspace and consequently omitted from the accepted project repository. You retained the exact R2 package that contained it.**

The final R8 package’s provenance note confirms that mechanism. It says the exact R2 source files for Programs 124C through 128 were not present in the active filesystem when final packaging occurred; they were therefore represented only by execution evidence and revision history. You have now recovered those physical files.

## Why the earlier rebase found a gap

The current accepted M2.12 repository inherited the final M1.17 package as it was assembled on July 28. That final package preserved the accepted database result and hotfix history, but its `accepted_execution` area did not contain the complete R2 clean-build source set.

That was a **packaging/source-retention omission**, not proof that Program 127 had never existed.

The accepted M2.12 repository itself remains valid and fully preserved; it has 30/30 predecessor stages unchanged and a valid accepted `31_M2_12` stage. [export reference: filecite | turn193file2 | L35-L52] This newly recovered material affects future clean-build reproducibility, not the accepted database or prior acceptance.

# Your creation order is coherent

Reading the screenshot from the oldest item at the bottom upward, the sequence is:

```text
1. Original M1.17 v0.2
2. R1 — G2 gate-definition preflight hotfix
3. R2 — gate-predicate complete-source recovery
4. R3 — policy-hash-shape validation recovery
5. R4 — PL/pgSQL RAISE syntax recovery
6. R5 — revalidation-state recovery
7. R6 — acceptance-evidence value-contract correction
8. R7 — detail-report scenario qualification
9. R8 — detail-report contract-row-hash correction
10. Final full-project packaging
11. Final M1.17 R8 package
12. Alias/copy deliveries and sidecars
```

That chronology matches the package contents and correction dependencies.

## Duplicate final deliveries

The duplicate names are harmless aliases:

```text
MSBF_M1_17_v0_2R8_COMPLETE_FINAL.zip
merchant_sales_based_financing_m1_17_end_to_end_qa_evidence_
g2_contract_acceptance_v0_2R8_COMPLETE_FINAL.zip
```

are byte-identical:

```text
SHA-256
4d1ffd1c169ac1aa2532c9f5623d005d3e20d5f7abb292d0483ab6b62ced00b9
```

Likewise:

```text
MSBF_Project_v0_2_M1_17_COMPLETE_FINAL_Windows.zip
merchant_sales_based_financing_project_delivery_
v0_2_M1_17_COMPLETE_FINAL.zip
```

are byte-identical:

```text
SHA-256
cd89f292ee2909e60428fa507996cbd99d17aca87b49af0a62bf389cc567fa0b
```

Their supplied sidecars match. We only need one physical copy of each identity for the reconciliation.

# Does this eliminate CR-WP1?

## It eliminates the need to reconstruct M1.17 from scratch

We no longer need to invent Program 127 from catalogs, evidence and accepted database state.

We now possess:

- the complete R2 clean-build source;
- the exact Program 127 source;
- R2 execution order;
- R2 program inventory;
- 128-control catalog;
- expected-results authority;
- source manifests and hashes;
- every subsequent R3–R8 hotfix;
- final R8 evidence and provenance;
- the M1.17-era full-project repository.

That is a major closure.

## But CR-WP1 is not yet completely unnecessary

The R2 clean-build package cannot simply be executed unchanged because the live history proves later corrections were required.

The important example is Program 127.

Its R2 source contains:

```sql
policy_configuration_hash ~ '^[0-9a-f]{{32}}$'
```

The valid policy hash was a lowercase 32-character hexadecimal value, but this pattern produced the false-negative:

```text
M1_17_POS_007_POLICY_HASH_SHAPE
```

R3 records that exact false negative. R4 corrected the recovery program’s PL/pgSQL syntax, and R5 restored the validated state after the noncanonical rerun. Those were recovery operations against the already committed database; they did not create a revised normal Program 127 source.

So the recovered R2 source is authentic and invaluable, but **Program 127 still needs the accepted correction integrated into a clean-build version** rather than relying on R3–R5 recovery after a predictable false failure.

Later normal-chain changes also must be selected correctly:

| Program | Provisional clean-build source |
|---:|---|
| 124 | R2 synchronized clean-build source |
| 125 | R2 synchronized preflight |
| 126 | R2 synchronized generation |
| 127 | R2 source with the accepted policy-hash validation correction integrated |
| 128 | R2 negative controls |
| 129 | R6 acceptance finalizer |
| 130 | R6 master report |
| 131 | R8 detail report |

This is a **provisional source-selection conclusion**, not final source authority. The chronology and byte differences still need one narrow reconciliation.

# What CR-WP1 becomes now

The work package changes from:

```text
Broad M1.17 source reconstruction
```

to:

```text
M1.17 recovered-source reconciliation
+ one bounded normal-source correction
+ final clean-build consolidation
```

That is substantially smaller, safer and better evidenced.

## Likely CR-WP1 scope

1. Recalculate all ZIP and source hashes.
2. Establish the exact source/hotfix chronology.
3. Designate R2 as the recovered synchronized clean-build baseline.
4. Verify Programs 124, 125, 126 and 128 need no later normal-source changes.
5. Integrate the accepted POS007 correction into Program 127.
6. Select final Program 129 R6, Program 130 R6 and Program 131 R8.
7. Keep 124A/124C/124B/124D/124E/124F/124G/126A as recovery or historical utilities—not normal-chain programs.
8. Issue one eight-program clean-build source authority.
9. Preserve every original and hotfix byte in a provenance tree.
10. Stop for audit before any PostgreSQL execution.

## What it no longer needs to do

```text
Infer Program 127 from result evidence
Recreate 128 controls from scratch
Guess Program 127 fields or joins
Reconstruct the R2 execution order
Invent M1.17 expected results
Treat the final database export as a substitute for source
```

# Recommended immediate next step

**Do not open the broad CR-WP1 build chat yet.**

The appropriate next action is a narrow review in this chat:

```text
M1.17 Historical Source Recovery
and Final-Delta Reconciliation
```

That review should produce:

```text
M1_17_PACKAGE_CHRONOLOGY.csv
M1_17_RECOVERED_SOURCE_IDENTITY.csv
M1_17_R2_TO_R8_CHANGE_MATRIX.csv
M1_17_FINAL_NORMAL_SOURCE_SELECTION.csv
M1_17_RECOVERY_AND_HISTORY_CLASSIFICATION.csv
M1_17_REMAINING_CLEAN_BUILD_CORRECTIONS.csv
M1_17_SOURCE_RECOVERY_RECONCILIATION_REPORT.md
```

Its central determination will be:

```text
Is the only remaining normal-source construction
the bounded Program 127 correction?

or

Did any other hotfix alter a normal-chain semantic
that must also be integrated?
```

Based on the initial inspection, I expect the answer to be **one bounded Program 127 correction plus final source consolidation**, but that should be proven before the build prompt is issued.

## Canonical files to retain for that review

Use these as the principal physical sources:

- Original M1.17 v0.2 (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2(2`; referenced bytes not established here).zip)
- R2 complete-source recovery package (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R2_Gate_Predicate_Complete_Source_Recovery_Hotfix.zip`; referenced bytes not established here)
- R3 policy-hash recovery (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R3_Policy_Hash_Shape_Validation_Recovery_Hotfix(1`; referenced bytes not established here).zip)
- R4 syntax-corrected recovery (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R4_PLpgSQL_Raise_Syntax_Recovery_Hotfix(1`; referenced bytes not established here).zip)
- R5 revalidation recovery (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R5_Revalidation_State_Recovery_Hotfix(1`; referenced bytes not established here).zip)
- R6 acceptance correction (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R6_Acceptance_Evidence_Value_Contract_Hotfix(1`; referenced bytes not established here).zip)
- R7 report correction (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R7_Detail_Report_Scenario_Qualification_Hotfix(1`; referenced bytes not established here).zip)
- R8 report correction (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R8_Detail_Report_Contract_Row_Hash_Hotfix(1`; referenced bytes not established here).zip)
- Final M1.17 package (historical reference: `sandbox:[session]/MSBF_M1_17_v0_2R8_COMPLETE_FINAL(2`; referenced bytes not established here).zip)
- M1.17-era full-project package (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_17_COMPLETE_FINAL_Windows(2`; referenced bytes not established here).zip)

No further archive hunting appears necessary at this point. **You found the missing R2 source package, and that likely reduces CR-WP1 from a major reconstruction into a tightly bounded recovery, correction and packaging task.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-0d459843-a0d9-4390-a4ab-d49c244b9e77"></a>
## Andrew / user · C072-M00352

C072-M00352 · 2026-08-12T16:00:31.050000-04:00 · active path

Preceding visible parent: [C072-M00351](part-28.md#m-95be2eef-339b-4f5c-afad-c7febe2b44a1)

<!-- BEGIN_SOURCE_MESSAGE -->
Perform this recommended action: Recommended immediate next step

**Do not open the broad CR-WP1 build chat yet.**

The appropriate next action is a narrow review in this chat:

```
```

```
M1.17 Historical Source Recovery
and Final-Delta Reconciliation
```

That review should produce:

```
```

```
M1_17_PACKAGE_CHRONOLOGY.csv
M1_17_RECOVERED_SOURCE_IDENTITY.csv
M1_17_R2_TO_R8_CHANGE_MATRIX.csv
M1_17_FINAL_NORMAL_SOURCE_SELECTION.csv
M1_17_RECOVERY_AND_HISTORY_CLASSIFICATION.csv
M1_17_REMAINING_CLEAN_BUILD_CORRECTIONS.csv
M1_17_SOURCE_RECOVERY_RECONCILIATION_REPORT.md
```

Its central determination will be:

```
```

```
Is the only remaining normal-source construction
the bounded Program 127 correction?

or

Did any other hotfix alter a normal-chain semantic
that must also be integrated?
```

Based on the initial inspection, I expect the answer to be **one bounded Program 127 correction plus final source consolidation**, but that should be proven before the build prompt is issued.
<!-- END_SOURCE_MESSAGE -->


<a id="m-963c4a36-dfdb-490e-bb9e-dfa95ec3a5b4"></a>
## Assistant · C072-M00353

C072-M00353 · 2026-08-12T16:31:31.241374-04:00 · active path

Preceding visible parent: [C072-M00352](part-28.md#m-0d459843-a0d9-4390-a4ab-d49c244b9e77)

<!-- BEGIN_SOURCE_MESSAGE -->
# M1.17 historical source recovery reconciliation complete

## Determination

**The historical R2 package closes the physical Program 127 source gap. Broad M1.17 reconstruction is no longer required.**

However, the detailed R2–R8 comparison did **not** confirm the preliminary expectation that Program 127 was the only source requiring bounded construction. The coherent campaign clean-build chain requires two new source identities:

```text
Program 127    bounded positive-validation and rerun-boundary correction
Program 129    bounded composition of accepted R2 and R6 corrections
```

The other six normal programs can be selected byte-for-byte from the recovered historical packages.

```text
Historical packages reviewed                  11
Packages passing ZIP CRC                  11 / 11
Recovered normal-chain positions            8 / 8
Exact normal sources ready                   6 / 8
Bounded source constructions pending         2 / 8
Recovery utilities in normal chain               0

SQL generated during this review                 0
PostgreSQL executions                             0
Accepted M1.17 database changes                   0
Accepted M1.17/M2.12 status reopened             NO
```

## Program 127 source recovered

The R2 package physically contains:

```text
127_msbf_m1_17_end_to_end_validation_v0_2R2.sql

Bytes
63,210

SHA-256
6bdfb68b7dbaf1909035f95559cd9c87ec0e71555c2500fa08fafc5b6bdcf599
```

It also contains the complete synchronized normal chain:

```text
124 → 125 → 126 → 127 → 128 → 129 → 130 → 131
```

The prior campaign-readiness finding was therefore a **later packaging-retention omission**, not permanent source loss.

## Why Program 127 still needs bounded correction

The recovered R2 source is authentic, but its positive-control implementation contains the predicate:

```sql
policy_configuration_hash ~ '^[0-9a-f]{{32}}$'
```

That produced the accepted-history false negative for:

```text
M1_17_POS_007_POLICY_HASH_SHAPE
```

The R4 recovery proves the intended validation semantics:

```text
character length                             32
octet length                                 32
lowercase hexadecimal domain               PASS
deterministic persisted-policy hash parity  PASS
```

R5 then proves a separate source-operability problem: rerunning Program 127 after validation replaced valid positive evidence with lifecycle-boundary failures. The historical authority requires the final clean-build source to **return idempotently or hard-stop before mutation** when invoked outside its initial validation boundary.

The exact guard predicate must be frozen during CR-WP1. The recommended fail-closed implementation is the exact:

```text
run lifecycle       M1_17_GENERATED
bundle lifecycle    GENERATED
```

boundary with no downstream negative, acceptance, or G2-gate state. That exact implementation detail is a future CR-WP1 decision; it is not being mislabeled as historical executed logic in this review.

## Why Program 129 also needs bounded correction

R2 corrected Program 129 by adding:

```sql
msbf_ctl.m1_17_gate_defined(
    'G2_M1_CONTRACT'
) AS g2_gate_defined
```

and requiring:

```sql
AND physical.g2_gate_defined
```

R6 later correctly fixed the acceptance-evidence value contract by staging exactly one value:

```text
metric_value_numeric    NULL
metric_value_text       combined G2 hash
```

But the physical R6 source was derived from the original v0.2 finalizer rather than the R2 finalizer. Consequently, it omitted both R2 gate-definition checks.

That omission did not invalidate the accepted historical execution—the gate had already been established and the accepted chain completed—but it would create an incomplete **from-empty-database clean-build source**.

The final campaign source must therefore:

1. use Program 129 R6 as the primary source;
2. preserve all R6 staging and exactly-one-value logic;
3. restore the R2 `g2_gate_defined` field;
4. restore the R2 `physical.g2_gate_defined` acceptance guard;
5. change nothing else.

# Final normal-source selection

| Order | Program | Clean-build disposition |
|---:|---:|---|
| 1 | 124 | Select exact recovered R2 clean-build source |
| 2 | 125 | Select exact R2 source |
| 3 | 126 | Select exact R2 source |
| 4 | 127 | Use R2 base; construct bounded corrected source |
| 5 | 128 | Select exact R2 source |
| 6 | 129 | Use R6 base; merge only the R2 gate prerequisite |
| 7 | 130 | Select exact R6 source |
| 8 | 131 | Select exact R8 source |

The six fixed source identities are:

```text
124
8e8d9058255cbfd47462592452afc5f626747181272e66785c9b5d495910c3b3

125
54892d19182d18490182d51007bcaf21cfed3873b0ada0a610c2850d5da3f620

126
16330dda3fd3f5301c4485de0a31f52fe3834cdb85059611c378aeaa696eb857

128
f49f341b42fb379b53768a0b307903ee1e1f24e7dcebd52447b72ac3221b6579

130
9761bc547d613ae5627f8c412c234de8975cc30dcfc5c2be699be2c499c93175

131
435525e2579eea716a87e0ab426b40a6cd542c1b95db3cc56ee196ff2723b703
```

Programs 127 and 129 receive new hashes only after their bounded sources are constructed and independently approved.

# Recovery and historical-source boundary

These remain outside the normal chain:

```text
124A    failed-generation diagnostic
124B    executed gate-definition recovery
124C    executed gate-predicate/function recovery
124D    failed recovery source
124E    executed POS007 recovery
124F    executed revalidation-state recovery
124G    acceptance-state diagnostic
126A    read-only generation reconstruction
```

They may be preserved as contingency, recovery, diagnostic, or execution-history authority, but they must never be invoked automatically or inserted into the normal campaign plan.

The R2 `live_recovery` copies are operational duplicates, not an independent second source authority. The R2 `clean_build` paths are the canonical recovered paths.

# Effect on CR-WP1

The broad reconstruction package proposed by the initial readiness rebase should be replaced with:

```text
CR-WP1 — M1.17 Recovered Clean-Build Consolidation

A. Construct corrected Program 127.
B. Construct merged Program 129.
C. Copy exact Programs 124, 125, 126, 128, 130, and 131.
D. Reissue the eight-program execution order.
E. Reissue source identities and SHA-256 inventories.
F. Preserve historical and recovery provenance.
G. Compile checkpoint/report authority.
H. Package for independent source review.
I. Execute no PostgreSQL.
```

The two new files must be labeled:

```text
GOVERNED CAMPAIGN CLEAN-BUILD REPLACEMENT
```

They must not be represented as historical executed bytes.

# Reconciliation package

- Download the complete M1.17 historical-source reconciliation (historical reference: `sandbox:[session]/M1_17_HISTORICAL_SOURCE_RECOVERY_AND_FINAL_DELTA_RECONCILIATION_20260812.zip`; referenced bytes not established here)
- Download the matching SHA-256 sidecar (historical reference: `sandbox:[session]/M1_17_HISTORICAL_SOURCE_RECOVERY_AND_FINAL_DELTA_RECONCILIATION_20260812.zip.sha256`; referenced bytes not established here)
- Read the package-validation report (historical reference: `sandbox:[session]/M1_17_HISTORICAL_SOURCE_RECOVERY_AND_FINAL_DELTA_RECONCILIATION_20260812_VALIDATION_REPORT.md`; referenced bytes not established here)

```text
Package
M1_17_HISTORICAL_SOURCE_RECOVERY_AND_FINAL_DELTA_RECONCILIATION_20260812.zip

Bytes
26,695

SHA-256
2be22aeafc0e5c702e7de9f398cba0ab0c2a8a99c47519f5acdf5264b85b5d85

ZIP entries
14

ZIP CRC
PASS

Metadata/path/hash mismatches
0

Input packages validated
11 / 11 PASS

Reconciliation controls
18 / 18 PASS

SQL files included
0
```

# Requested artifacts

- M1.17 package chronology (historical reference: `sandbox:[session]/M1_17_PACKAGE_CHRONOLOGY.csv`; referenced bytes not established here)
- Recovered source-identity ledger (historical reference: `sandbox:[session]/M1_17_RECOVERED_SOURCE_IDENTITY.csv`; referenced bytes not established here)
- R2-to-R8 change matrix (historical reference: `sandbox:[session]/M1_17_R2_TO_R8_CHANGE_MATRIX.csv`; referenced bytes not established here)
- Final normal-source selection (historical reference: `sandbox:[session]/M1_17_FINAL_NORMAL_SOURCE_SELECTION.csv`; referenced bytes not established here)
- Recovery and historical-source classification (historical reference: `sandbox:[session]/M1_17_RECOVERY_AND_HISTORY_CLASSIFICATION.csv`; referenced bytes not established here)
- Remaining clean-build corrections (historical reference: `sandbox:[session]/M1_17_REMAINING_CLEAN_BUILD_CORRECTIONS.csv`; referenced bytes not established here)
- Full source-recovery reconciliation report (historical reference: `sandbox:[session]/M1_17_SOURCE_RECOVERY_RECONCILIATION_REPORT.md`; referenced bytes not established here)

## Supporting records

- Reconciliation control ledger (historical reference: `sandbox:[session]/M1_17_SOURCE_RECOVERY_RECONCILIATION_CONTROLS.csv`; referenced bytes not established here)
- Machine-readable reconciliation summary (historical reference: `sandbox:[session]/M1_17_SOURCE_RECOVERY_RECONCILIATION_SUMMARY.json`; referenced bytes not established here)
- Input-package validation ledger (historical reference: `sandbox:[session]/M1_17_INPUT_PACKAGE_VALIDATION.csv`; referenced bytes not established here)

The historical search has therefore accomplished its purpose: **we recovered Program 127 and avoided a broad eight-program reconstruction. The remaining CR-WP1 build is now narrowly limited to Programs 127 and 129 plus final source consolidation.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-f98cacef-625b-41d5-883a-77bdae886a7f"></a>
## Andrew / user · C072-M00354

C072-M00354 · 2026-08-12T16:42:29.793000-04:00 · active path

Preceding visible parent: [C072-M00353](part-28.md#m-963c4a36-dfdb-490e-bb9e-dfa95ec3a5b4)

**Editorial record note:** Attachment references: Pasted markdown(20260812-204200).md

<!-- BEGIN_SOURCE_MESSAGE -->
for context, here is the full chat from our M1.17 build: 
<!-- END_SOURCE_MESSAGE -->
