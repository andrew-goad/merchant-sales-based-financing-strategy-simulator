# MSBF - Campaign Scale 750 - 2,500 - 25,000 Part 2

Part 01 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Next part](part-02.md)

<a id="m-ddcc9be5-386a-433c-89f4-f2eaf2bc0287"></a>
## Andrew / user · C132-M00001

C132-M00001 · 2026-09-12T08:35:50.933000-04:00 · active path

**Editorial record note:** Attachment references: ARTIFACT_ATTACHMENT_REGISTER(1).csv; 00_READ_FIRST(9)(1).md; MSBF_CAMPAIGN_SCALE_PART2_HANDOFF_R1_20260912_VALIDATION(1).json; MSBF_CAMPAIGN_SCALE_PART2_HANDOFF_R1_20260912.zip(1).sha256; MSBF_CAMPAIGN_SCALE_PART2_HANDOFF_R1_20260912(1).zip; 06_REFERENCE_ENVIRONMENT_R1_RECORD(1).md

<!-- BEGIN_SOURCE_MESSAGE -->
# COPY/PASTE PROMPT — MSBF Campaign Scale Part 2

## Workstream

Continue:

```
MSBF Campaign Scale Part 2 — 750 Certification & Fresh 2,500 Campaign Execution
```

This is a continuation from Campaign Scale Part 1, not a restart. Use the attached handoff package and the retained artifacts it identifies. Do not rebuild the GitHub publication, do not reopen the accepted v2.1.0 release, do not rerun Power BI, do not restart the old Campaign Scale custody/signature path, and do not treat the historical 230-position catalog as a full executable campaign launcher.

## Core objective

Use the newly established Reference Environment R1 as the runtime comparison baseline, then build and execute the next campaign gates:

```
Reference Environment R1
    -> native Module A exports
    -> R4 strategy-wrapper parity / 20-file comparison
    -> full 750 zero-difference certification plan and execution
    -> fresh 2,500 merchant campaign shakedown
    -> 25,000 readiness determination
```

The immediate Part 2 target is **not** another restore. It is:

1. preserve and bind Reference Environment R1;
2. run native read-only Module A exports against it;
3. prove R4 output parity against retained reference outputs;
4. design and run a separate fresh 750 replay environment;
5. reconcile 750 to zero semantic differences against Reference Environment R1 / accepted reference surfaces; and
6. only after that gate passes, execute a fresh 2,500-merchant campaign.

## Established Reference Environment R1

The prior chat manually restored the exact Route-B R26 checkpoint backup into a D:-resident isolated PostgreSQL 17 cluster after wrapper failures were diagnosed. Treat these facts as starting evidence, then verify them read-only before any new execution:

```
Cluster directory:
D:\MSBF_CAMPAIGNS\pg_clusters\msbf_cs_ref750_routeb_20260912_012713

Host/port:
127.0.0.1:55432

Database:
msbf_restore_test

PostgreSQL:
17.9 on x86_64-windows

Database size:
1552 MB

Schemas:
msbf_ctl
msbf_m1
msbf_m12r1a
msbf_m12r1b_p2a_r2
msbf_m12r1b_p2b
msbf_m12r1b_p2c_supp
msbf_m12r1c
msbf_m12r1d
msbf_m12r1e
msbf_m2
msbf_ref

Key counts:
msbf_m1.merchant_master = 750
msbf_m1.merchant_application = 7147
msbf_m1.verification_result = 4500
msbf_m2.advance_portfolio_monitoring_latest = 130
msbf_m2.application_servicing_execution_latest = 130
```

The reference database is for comparison only. Do **not** run a fresh replay, update logic, drop objects, or write campaign outputs into `msbf_restore_test`.

## Why Reference Environment R1 exists

The old Campaign Scale packages were recovered and inspected. They contain useful contracts and architecture, including:

- configuration-driven profiles for 750, 2,500 and 25,000;
- `module1_run_id` as the physical lineage key;
- a 230-position ordered normal-source-plan concept;
- recovery outside normal execution;
- 172 checkpoint positions;
- 58 report positions / 607 result-set architecture;
- checkpoint/report catalogs; and
- fail-closed source/order/cardinality controls.

However, after M1/M2 were corrected and published as v2.1.0, old source identities and old business-result expectations became predecessor evidence. They must not be used as current truth without rebasing.
The prior chat constructed several harness revisions. Keep their source/evidence, but retire the cluster lifecycle wrappers:

- R1 built the harness core but held runtime because fresh-source bridges were incomplete.
- R2 built Module A file-level fresh-input adapters, cardinality bindings and wrapper parity.
- R3 added native read-only Module A export but failed because the historical subject database was not live.
- R4 added restore but first failed due wrong backup path, then failed on the default PostgreSQL service data directory due disk space.
- R5/R6 moved restore to D: and fixed port forwarding, but `pg_ctl -w start` timed out even though the isolated cluster was live.
- Manual createdb/pg\_restore proved the underlying restore is valid.

Do not continue R6 -> R7 -> R8 by adding wrapper layers. Separate infrastructure from campaign execution.

## Required source artifacts and local paths

Read `registers/ARTIFACT_ATTACHMENT_REGISTER.csv` for exact sizes/hashes. The most important retained local paths are:

```
Authoritative repo:
D:\x\m

Campaign archive root:
D:\MSBF_ARCHIVE

Route-B checkpoint carriers:
D:\MSBF_PUBRUN001_ROUTE_B_QUAL_20260909_R1\phase1_checkpoint_carriers\msbf_r1_m2_4_r6_20260830_030634.backup
D:\MSBF_PUBRUN001_ROUTE_B_QUAL_20260909_R1\phase1_checkpoint_carriers\msbf_r1_r26_g3v2_20260902_024119.backup

Reference cluster:
D:\MSBF_CAMPAIGNS\pg_clusters\msbf_cs_ref750_routeb_20260912_012713

Reference database:
msbf_restore_test on 127.0.0.1:55432
```

If an artifact is already attached in the new chat, use it. If a very large binary backup is not attached, use the local path and have Andrew verify its hash rather than requesting an upload unless inspection/restore requires it.

## Immediate Part 2 execution standard

Move in controlled leaps, not tiny prompts, but fail closed on material mismatches.
Start with one read-only binding block that verifies:

1. `D:\x\m` current Git/tag/publication identity;
2. Reference Environment R1 is reachable on `127.0.0.1:55432`;
3. key reference counts match the recorded counts;
4. source backups and included reference artifacts still hash to their locked values if used;
5. no writes are performed to `msbf_restore_test`.

Then build/run native Module A export against `msbf_restore_test` using a direct-connect/export approach. Do not use the old restore lifecycle wrapper. The export should be read-only and should produce a return package with:

- exact SQL/export queries used;
- exported CSV row counts and hashes;
- Module A input contract validation;
- R4 campaign wrapper outputs;
- 20-file parity comparison with retained R4 reference;
- zero DB mutation evidence where practical; and
- source/result manifest and checksum files.

## 750 certification rule

The 750 gate should be strict:

```
same accepted source bytes
same accepted/reference 750 population and governing configuration
same deterministic seed/date/parameters
=> zero semantic/deterministic output differences
```

Only predeclared runtime-specific metadata may be excluded or normalized. Examples: timestamps, durations, database OIDs, filesystem paths, transient log locations, local cluster directory names. Do not discover differences first and then widen the exclusion list.
The comparison should cover more than final decisions. It should include row counts, keys, lineage, Module A surfaces, strategy/R4 outputs, final decisions, candidate/structure evidence, booking/funding, monitoring, intervention/servicing, reconciliation and financial/control aggregates where source coverage supports it.

## Fresh 2,500 profile target

Only after 750 zero-difference certification passes, proceed to the fresh 2,500 shakedown.
Expected fixed input/cardinality bindings:

```
merchants = 2,500
application_scenario_rows = 5,000
verification_rows = 15,000
feature_rows = 5,000
base_history_rows = 450,000
scenario_history_rows = 900,000
```

Data-dependent results such as candidate structures, selected/funded paths, monitoring rows and servicing rows must emerge from the fresh population. Do **not** multiply the 750 results by 2,500/750 and call those expected outputs.

## Logic-change rule

Permitted without reopening strategy design:

- population size/config;
- deterministic seed;
- population/run/campaign identifiers;
- isolated database/output names;
- dates only if deliberately fixed as a campaign input;
- source path/hash rebasing;
- logging/timing/evidence paths;
- nonsemantic adapter fixes;
- environment/connection configuration.

Stop and escalate before changing:

- capacity methodology;
- evidence sufficiency rules;
- risk/economics logic;
- pricing or structure search logic;
- counteroffer policy;
- review/authorization rules;
- funding/booking semantics;
- monitoring/intervention/servicing logic;
- reconciliation tolerances;
- G3/source-certification semantics.

## Current known limitations

- Reference Environment R1 is a restored accepted reference environment, not a fresh 750 replay result.
- The old Campaign Scale static work had meaningful value but no completed 750/2,500/25,000 runtime acceptance.
- The old external signer/custody path is superseded by owner-controlled local execution, but its historical files remain audit evidence.
- R26 Route B was accepted only as portable checkpoint restore + isolated retained-final M2.11/M2.12/G3-v2 replay. It is not a qualified empty-database G0->G3 rebuild, not a fresh campaign input qualification and not Module 3 authority.
- The published v2.1.0 release and PBIX should not be modified.
- Power BI refresh is out of scope for the first 750/2,500 database campaign work.

## Desired Part 2 deliverables

1. Reference Environment R1 read-only binding package.
2. Native Module A export and R4 parity package from Reference Environment R1.
3. Full 750 certification harness/package with predeclared comparison contract.
4. 750 replay return package with zero semantic differences or a precise blocker.
5. Fresh 2,500 shakedown package after 750 passes.
6. 25,000 readiness decision record.
7. Private engineering evidence package with manifests, logs, source hashes, comparison results and stop-condition handling.

Do not claim Independent Audit acceptance, public release, fresh 2,500 success or 25,000 readiness unless the corresponding physical checks have actually passed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-246c252d-2620-486f-bf4c-8224ad49013b"></a>
## Assistant · C132-M00002

C132-M00002 · 2026-09-12T08:36:05.675057-04:00 · active path

Preceding visible parent: [C132-M00001](part-01.md#m-ddcc9be5-386a-433c-89f4-f2eaf2bc0287)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll verify the handoff and retained export/parity harnesses, then prepare a read-only direct-connect binding/export package. Fresh replay remains gated on reference parity.
<!-- END_SOURCE_MESSAGE -->


<a id="m-28acc579-1e50-4d75-bac6-580c7a0cedb1"></a>
## Assistant · C132-M00003

C132-M00003 · 2026-09-12T08:39:10.116466-04:00 · active path

Preceding visible parent: [C132-M00002](part-01.md#m-246c252d-2620-486f-bf4c-8224ad49013b)

<!-- BEGIN_SOURCE_MESSAGE -->
The handoff’s size/hash integrity is confirmed; live Windows checks remain outstanding. I’m tightening parity to exactly 20 files, one read-only snapshot, and unchanged retained policy bytes.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ce93f35d-390b-4861-9c68-be790f343fe3"></a>
## Assistant · C132-M00004

C132-M00004 · 2026-09-12T08:48:14.318698-04:00 · active path

Preceding visible parent: [C132-M00003](part-01.md#m-28acc579-1e50-4d75-bac6-580c7a0cedb1)

<!-- BEGIN_SOURCE_MESSAGE -->
The unchanged wrapper reproduces all 20 retained R4 files byte-for-byte in file-only testing; native DB parity remains pending. Failure packaging and fresh-750 contract captures are now included.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4d1a0dc0-27fa-4864-891b-6a8fa364e60c"></a>
## Assistant · C132-M00005

C132-M00005 · 2026-09-12T09:05:01.284515-04:00 · active path

Preceding visible parent: [C132-M00004](part-01.md#m-ce93f35d-390b-4861-9c68-be790f343fe3)

<!-- BEGIN_SOURCE_MESSAGE -->
## Part 2’s direct reference-binding/export package is ready

I built and tested a **new direct-connect package for Reference Environment R1 → native Module A export → strict R4 parity**. It does not invoke the retired restore wrappers, manage the cluster lifecycle, modify the publication, or launch a fresh campaign.

The established environment remains the read-only reference—not the fresh 750 subject—as specified in the handoff. [export reference: filecite | turn0file2 | L5-L11] [export reference: filecite | turn0file2 | L53-L55]

**Download the execution package (historical reference: `sandbox:[session]/MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip`; referenced bytes not established here)** — approximately 22 MB.

Supporting files: Engineering report (historical reference: `sandbox:[session]/MSBF_CS_PART2_ENGINEERING_REPORT_20260912.md`; referenced bytes not established here) · PowerShell run block (historical reference: `sandbox:[session]/MSBF_CS_PART2_RUN_BLOCK_20260912.txt`; referenced bytes not established here) · SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip.sha256`; referenced bytes not established here) · Package validation (historical reference: `sandbox:[session]/MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912_VALIDATION.json`; referenced bytes not established here)

### What physically passed here

| Check | Result | Evidence scope |
|---|---|---|
| Uploaded handoff integrity | **PASS** — exact size/hash; 55 files; 52 manifest entries; 14 included registered artifacts verified | Attached package bytes |
| Module A contract and retained-input comparison | **6/6 PASS** | Retained file inputs |
| Delivered R4 campaign wrapper replay | **20/20 outputs byte-identical** to the retained reference | Actual file-only engine execution |
| Unit, negative, and mock-process tests | **46 passed; zero failures or errors** | Engineering container |
| Final delivery package integrity | **PASS** — 66 files; 64 manifest entries; CRC and path checks passed | Delivered ZIP |
| Current owner-machine Git/database binding and native export | **PENDING** | Requires the command below |

**The file-based successes are not a new validation of your live PostgreSQL database and do not constitute fresh 750 certification.** The package preserves that distinction in its receipts.

## Two inherited problems corrected before native execution

**The native path regenerated the approved R4 policy file.** That added nine campaign fields and changed the file hash, which the engine incorporates into output evidence. The new reference runner passes the **original approved policy bytes unchanged**. It does not alter strategy logic or exclude policy hashes from comparison.

**The inherited comparator could pass incomplete output sets.** I reproduced PASS results for matching empty directories and matching 19-file directories. The replacement requires **exactly the 20 locked filenames**, rejects missing or extra files, and compares every file’s size and SHA-256.

The detailed reproductions, original-source locations, hashes, and test results are included in the engineering report and the package’s `review/` directory. The R6 carrier was used as retained code/evidence, consistent with its attachment-register classification—not as a lifecycle launcher. [export reference: filecite | turn1file0 | L21-L22]

## Run this one block

Save the execution ZIP in your **Downloads** folder, then paste this into PowerShell. It verifies the ZIP, extracts to a new tool directory, and runs the direct binding/export program.

```powershell
$ErrorActionPreference = 'Stop'
$Zip = Join-Path $env:USERPROFILE 'Downloads\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip'
$ExpectedSHA256 = 'db0e934b8fda2624055d76cb55664d8401c0e0b5183d42efb6ff361d91eee52e'
$Python = 'C:\Python314\python.exe'
$PgBin = 'C:\Program Files\PostgreSQL\17\bin'

if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) {
    throw "Package not found: $Zip"
}
if ((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedSHA256) {
    throw 'Package SHA-256 mismatch. Nothing has been executed.'
}
if (-not (Test-Path -LiteralPath $Python -PathType Leaf)) {
    throw "Python not found: $Python"
}
if (-not (Test-Path -LiteralPath (Join-Path $PgBin 'psql.exe') -PathType Leaf)) {
    throw "psql.exe not found under: $PgBin"
}

$ToolRoot = 'D:\MSBF_CAMPAIGNS\tools\CS_PART2_REF_AB_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
if (Test-Path -LiteralPath $ToolRoot) {
    throw "Extraction folder already exists: $ToolRoot"
}
Expand-Archive -LiteralPath $Zip -DestinationPath $ToolRoot

& $Python -B (Join-Path $ToolRoot 'reference_export.py') `
    --repo 'D:\x\m' `
    --pg-bin $PgBin `
    --out-root 'D:\MSBF_CAMPAIGNS\PART2_RETURNS'

if ($LASTEXITCODE -ne 0) {
    Write-Warning 'Stopped. Preserve the emitted return ZIP or error; do not restore, bypass checks, or advance campaigns.'
}
```

The program prompts for the PostgreSQL password without recording it. Press Enter only when local trust or the normal password file supplies authentication.

### What this execution checks

Before export, it binds the exact publication tag/commit/tree, clean working tree, **2,884 locked repository files**, packaged reference artifacts, and the original R26 backup’s size/hash. It then checks the fixed database endpoint, cluster directory, PostgreSQL 17.9 identity, eleven schemas, and five recorded counts. The required counts remain **750 / 7,147 / 4,500 / 130 / 130**. [export reference: filecite | turn0file2 | L17-L25] [export reference: filecite | turn0file2 | L43-L51]

All six Module A exports are collected in **one repeatable-read, read-only transaction**. The runner validates their keys, cardinalities, population, scenario identities, `module1_run_id`, business date, and predecessor-history coverage, then compares all keyed values with the retained inputs. There are **no metadata exclusions** in this reference gate.

After the unchanged R4 wrapper runs, the runner requires all 20 outputs to match byte-for-byte and collects a separate postflight snapshot. It also rechecks repository, package, and backup bindings.

The return contains exact SQL, exported CSVs, row counts and hashes, R4 outputs, comparison reports, inventories, logs, source snapshots, manifests, checksums, and stop-condition evidence. **No large backup upload is needed.**

The nonmutation evidence is deliberately scoped: forced read-only sessions plus before/after observations of eleven data surfaces and structural inventories. PostgreSQL’s read-only transaction mode restricts modifying SQL but does not guarantee zero internal physical disk writes, so the receipt does not overstate that assurance. [export reference: cite | turn396523view0]

## Gate disposition

A successful execution prints:

```text
PASS_REFERENCE_A_B_ONLY

REFERENCE_ENV_R1_BIND = PASS
NATIVE_MODULE_A_DB_EXPORT = PASS
MODULE_A_INPUT_CONTRACT = PASS
MODULE_A_RETAINED_INPUT_PARITY = PASS
REFERENCE_750_R4_OUTPUT_COMPARISON = PASS
REFERENCE_750_R4_FILES_COMPARED = 20
REFERENCE_NONMUTATION_OBSERVED = PASS_OBSERVED_SCOPE_ONLY

FULL_750_EXECUTION = HOLD_NOT_RUN
FULL_750_CERTIFICATE_GRANTED = false
FRESH_2500_EXECUTION = HOLD_NOT_RUN
READINESS_25000 = NOT_ESTABLISHED
```

The full-750 draft identifies three explicitly unimplemented downstream stages in the inherited plan: **`CURRENT_M2_4`, `CURRENT_R26_WAVE_A`, and `CURRENT_R26_G3`**. Fresh-prefix/configuration qualification, endogenous predecessor-history reconstruction, and the complete predeclared surface-comparison registry also remain open. Those are recorded blockers—not hidden behind a reference-parity PASS.

**Run the block and attach the emitted `_RETURN.zip`, including a stopped return.** It will be written under `D:\MSBF_CAMPAIGNS\PART2_RETURNS`; fresh 750 and 2,500 execution remain on hold.
<!-- END_SOURCE_MESSAGE -->


<a id="m-18880491-5e30-4a09-a1fc-06eaad92e620"></a>
## Andrew / user · C132-M00006

C132-M00006 · 2026-09-12T09:05:45.276000-04:00 · active path

Preceding visible parent: [C132-M00005](part-01.md#m-4d1a0dc0-27fa-4864-891b-6a8fa364e60c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I would give the new Part 2 chat a **small addendum** so it does not overfit the campaign work to the three validation sizes.

The package is already strong. The only thing missing from the handoff is the strategic clarification from these last two exchanges:

> The long-term GitHub/public-user goal is a clean start-to-finish campaign experience, and 750 / 2,500 / 25,000 are validation profiles—not fixed product limits.

Here is the exact addendum I would paste into the new chat.

---

## Addendum for Campaign Scale Part 2

Please incorporate this as a post-handoff clarification from the owner.

The eventual public GitHub goal remains that a technically capable user can go from repository intake to a working synthetic campaign through a clear, simple start-to-finish workflow. The internal engineering path may involve reference environments, restore debugging, harness validation, parity checks, and audit evidence, but the public user path should eventually be much simpler:

```text
Clone / download repository
    -> setup environment
    -> choose campaign size and configuration
    -> generate synthetic merchants
    -> run campaign
    -> review outputs / reports
    -> optionally inspect Power BI or deeper validation evidence
```

Do not design the public documentation as though ordinary users must understand the full R1–R6 harness history, Route-B infrastructure debugging, PostgreSQL lifecycle troubleshooting, or audit packaging sequence before running the project.

Important design clarification:

**750, 2,500 and 25,000 are validation profiles, not software limits.**

They were selected to prove different aspects of the infrastructure:

```text
750     reference / known-answer validation profile
2,500   medium-scale fresh-population shakedown
25,000  large-scale campaign target
```

They should not be hardcoded as the only valid campaign sizes. The long-term design goal is parameterized synthetic campaign generation where a user can request an arbitrary merchant population size, such as 63, 5,000, 63,578 or another value, subject to runtime, storage, memory, and validation constraints.

For the immediate Part 2 execution, continue using:

```text
750 zero-difference reference certification
    -> 2,500 fresh-population shakedown
```

because those are the next proof points. But implement with the future parameterized architecture in mind:

```text
population_size = user parameter
scenario set = selected configuration
seed = explicit deterministic input
expected cardinalities = derived from formulas / contracts
data-dependent outcomes = measured, not predeclared by scaling old results
```

Do not multiply old 750 outcome counts to claim expected 2,500 results. Counts like funded paths, no-feasible outcomes, counteroffers, servicing rows, monitoring rows and portfolio outcomes must emerge from the generated population and strategy logic unless a contract explicitly fixes them.

Use the three legacy Campaign Scale names as retained validation-profile labels, not as product boundaries:

```text
CS_0750_ACCEPTED_FIDELITY        -> reference validation profile
CS_2500_PERFORMANCE_SHAKEDOWN    -> medium validation profile
CS_25000_FULL_CAMPAIGN           -> large validation profile
```

Longer term, the public-facing interface should describe this as:

> Campaign scale is a runtime parameter, not a software limitation.

But until arbitrary sizes are actually executed and validated, claims should remain bounded:

Safe current phrasing:

> The campaign architecture is being rebuilt toward parameterized synthetic population generation. The retained validation profiles use 750, 2,500 and 25,000 merchants to prove reference fidelity, medium-scale execution and large-scale readiness.

Avoid overclaiming:

> Users can already run any arbitrary size end to end.

That may become true after the campaign harness and public instructions are completed, but it should not be claimed before actual execution and validation support it.

Also keep the architecture separated:

```text
Infrastructure layer
    PostgreSQL setup, isolated cluster, restore/reference environment

Campaign runtime layer
    population generation, Module 1, Module 2, evidence, comparison

Learning / documentation layer
    README, Current Use Guide, Power BI, cohort report, posters, architecture
```

Do not keep embedding PostgreSQL cluster lifecycle into the campaign harness unless necessary. The preferred public architecture should eventually assume either:

```text
A working PostgreSQL environment exists
```

or provide a separate setup script before campaign execution begins.

Immediate Part 2 priority remains:

```text
1. Bind Reference Environment R1 read-only.
2. Export Module A surfaces from Reference Environment R1.
3. Run R4 campaign-aware wrapper.
4. Confirm 20-file parity.
5. Build separate fresh 750 replay target.
6. Require zero semantic differences against the accepted reference, excluding only predeclared execution metadata.
7. Then run the fresh 2,500 profile as the first scale shakedown.
```

Do not reopen publication, Power BI, visual, résumé, or GitHub-profile work. Do not rerun R4/R5/R6 PostgreSQL lifecycle wrappers unless a specific defect requires it. Reference Environment R1 has been established and should be treated as the comparison baseline.

---

That addendum is enough. I would not rebuild the handoff package unless Part 2 explicitly asks for a new package. The new chat mainly needs the clarification that:

**we are proving with 750 / 2.5k / 25k, but designing for parameterized campaign size.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-fb7f3436-e3ae-489e-9da1-5215b51af5a5"></a>
## Assistant · C132-M00007

C132-M00007 · 2026-09-12T09:06:40.159152-04:00 · active path

Preceding visible parent: [C132-M00006](part-01.md#m-18880491-5e30-4a09-a1fc-06eaad92e620)

<!-- BEGIN_SOURCE_MESSAGE -->
Incorporated as the **governing post-handoff design clarification for Campaign Scale Part 2**:

> **We are proving with 750 / 2,500 / 25,000, but designing for parameterized campaign size.**

This supplements the handoff without replacing its source hierarchy, execution gates, or change-control boundaries. No handoff rebuild is needed.

## Implementation implications

**The reference-certification gate stays deliberately fixed.** Its population, accepted source identities, governing configuration, seed, dates, and comparison requirements must remain locked to establish known-answer fidelity. A 750-specific reference binder is appropriate; that does **not** make 750 a general runtime restriction. Reference Environment R1 remains read-only, and fresh campaigns require separate targets. [export reference: filecite | turn2file2 | L53-L55]

**The general campaign runtime should be parameter-driven.** The three named profiles are retained test configurations—not an allowlist of permissible population sizes. Population size, scenario configuration, seed, and deliberately fixed campaign dates should be explicit inputs. Expected input cardinalities should follow documented configuration-dependent formulas and contracts. Data-dependent outcomes must be measured from execution, not extrapolated from the reference population.

**Parameterization does not relax business semantics.** It remains subject to the existing stop rules for capacity, evidence sufficiency, risk, economics, structure selection, authorization, booking, monitoring, servicing, reconciliation, and source certification. A size-dependent failure must be investigated rather than concealed by changing policy or widening comparison exclusions.

## Architecture and public experience

The separation is now an explicit design requirement:

| Layer | Responsibility |
|---|---|
| **Infrastructure** | PostgreSQL prerequisites, connection configuration, isolated environments, and reference setup where needed. |
| **Campaign runtime** | Synthetic population generation, Module 1/2 execution, outputs, controls, and comparison. |
| **Learning and documentation** | A clear start-to-finish user guide, report interpretation, and optional Power BI or deeper engineering evidence. |

The eventual public workflow should require a working PostgreSQL environment—or a separate setup step—not familiarity with the historical restore wrappers, harness revisions, or audit-package sequence.

That is a **design objective**, not evidence that arbitrary population sizes already work end to end. Public capability claims must remain bounded by completed physical validation.

## Immediate execution remains unchanged

```text
Read-only Reference R1 binding
    → native Module A exports
    → R4 strict 20-file parity
    → separate fresh 750 replay and zero-difference certification
    → fresh 2,500 shakedown
    → evidence-based 25,000 readiness determination
```

The previously supplied binding/export run remains the next local action. This addendum neither advances those gates nor authorizes publication, Power BI, visual, résumé, or GitHub-profile changes. **No arbitrary-size execution success, fresh 750 certification, fresh 2,500 success, or 25,000 readiness is established by this clarification.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-0e6a115b-9f0b-4187-b5a7-312b9d8cb581"></a>
## Andrew / user · C132-M00008

C132-M00008 · 2026-09-12T09:19:54.084000-04:00 · active path

Preceding visible parent: [C132-M00007](part-01.md#m-fb7f3436-e3ae-489e-9da1-5215b51af5a5)

<!-- BEGIN_SOURCE_MESSAGE -->
Feedback from prior chat: Yes — **the new Part 2 chat is on track.** It appears to have correctly internalized the handoff, the post-handoff clarification, and the boundary we established at the end of this chat.

The strongest sign is that it is **not trying to continue the R4/R5/R6 restore-wrapper path**. It built a direct-connect package for:

```text
Reference Environment R1
    → native Module A export
    → strict R4 parity
```

and explicitly says it does **not** manage cluster lifecycle, modify the publication, or launch a fresh campaign. That is exactly the pivot we wanted.

## My assessment

### 1. Correct next step: PASS

The package’s scope is appropriate. It is not trying to jump directly into a fresh 750 or 2,500 run. It is first binding the known reference environment and proving native Module A export/R4 parity.

That is the correct next gate because we already established:

- the isolated D: PostgreSQL cluster works;
- the `msbf_restore_test` database restored successfully;
- the reference population contains 750 merchants, 7,147 applications, 4,500 verification rows, 130 monitoring rows, and 130 servicing rows.

Part 2’s package now aims to turn that restored runtime state into a repeatable export/comparison gate, which is the right progression.

### 2. It is preserving the reference/fresh-subject distinction: PASS

This line is important:

> “The established environment remains the read-only reference—not the fresh 750 subject.”

That is exactly right. The restored `msbf_restore_test` database should be used for comparison and reference exports, not as the place where a new replay is executed.

The engineering report also says the maximum result this command can grant is only `PASS_REFERENCE_A_B_ONLY`, and that full 750 certification, fresh 2,500 execution, and 25,000 readiness remain unestablished.

That avoids the biggest risk: calling a reference export a fresh campaign replay.

### 3. The two inherited defects it corrected are real and important: PASS

The new chat found and corrected two meaningful issues.

First, it caught that the native path was regenerating the R4 policy profile, which would change the policy hash and therefore break byte-exact reference parity even if the business settings were effectively the same. It corrected this by using the original approved policy bytes instead of normalizing the comparison after the fact.

Second, it found that the inherited comparator could pass incomplete output sets, including empty or 19-file directories. The replacement requires exactly the 20 locked filenames and rejects missing, extra, or altered files.

Those are exactly the kind of defects we want Part 2 to catch before runtime.

### 4. The package validation looks clean: PASS

The delivered package validation is internally consistent: 66 regular files, CRC PASS, path safety PASS, no case-fold collisions, 64 manifest rows, and package verification PASS. It also correctly labels the scope as an owner-run reference binding/export package, not a native runtime return.

The run block is also bounded: it verifies the ZIP hash, checks Python and PostgreSQL binaries, extracts to a timestamped tool folder, and runs `reference_export.py` with output under `D:\MSBF_CAMPAIGNS\PART2_RETURNS`.

### 5. Parameterized-size clarification was handled correctly: PASS

The addendum response is also on track. It treats 750, 2,500, and 25,000 as **validation profiles**, not product limits, while preserving the immediate execution sequence:

```text
750 reference certification
    → fresh 2,500 shakedown
```

That is the right balance. It supports the long-term goal of arbitrary user-requested population sizes without prematurely claiming that arbitrary-size execution already works.

## Items I would watch closely

### Watch item 1 — the run block omits the execution-policy line

The run block starts with:

```powershell
$ErrorActionPreference = 'Stop'
```

It does not include:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

That is not necessarily a blocker because the block invokes Python directly rather than executing a downloaded `.ps1`. But given our established workflow, I would add it at the top for consistency.

Use:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
```

### Watch item 2 — endpoint assumptions should be visible in the return

The command does not explicitly pass:

```text
host = 127.0.0.1
port = 55432
database = msbf_restore_test
user = postgres
```

The engineering report says the executable gate checks the fixed database endpoint, cluster directory, PostgreSQL 17.9 identity, 11 schemas, and the five protected row counts.

That is acceptable if the package hardcodes the intended reference endpoint, but the return ZIP should make the exact endpoint obvious. I would make sure the output receipt explicitly records:

```text
Reference database: msbf_restore_test
Host/port: 127.0.0.1:55432
Mode: read-only repeatable-read export
```

No need to stop the run over this; just review the return for that binding.

### Watch item 3 — “full 750 blockers” are real work

The new chat correctly identifies that full 750 certification is still blocked by three downstream stages:

- `CURRENT_M2_4`
- `CURRENT_R26_WAVE_A`
- `CURRENT_R26_G3`

and it says the full comparison registry still needs to be populated across the full campaign surface.

That is honest and useful, but it means Part 2 is not yet at “run 750 end to end.” It is still building toward that. The current package is an important gate, but not the final campaign harness.

### Watch item 4 — do not let “R4 parity” become “fresh 750 certification”

The output language already guards against this, but I would keep enforcing it. A successful run should mean:

```text
Reference A/B binding/export passed.
R4 retained-output parity passed.
```

It should **not** mean:

```text
Full 750 replay passed.
Fresh campaign path certified.
2,500 authorized automatically.
```

The package itself appears to preserve that distinction.

## My recommendation

Run the package, with the execution-policy line added at the top:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
```

Then paste/upload the emitted return ZIP from:

```text
D:\MSBF_CAMPAIGNS\PART2_RETURNS
```

Do **not** restore anything, restart the cluster, or rerun the old R6 wrapper unless Part 2 identifies a specific need.

Overall: **Part 2 is aligned.** It is doing the right thing: direct reference binding first, strict export/parity next, full 750 certification later, and 2,500 only after the zero-difference gate is genuinely earned.
<!-- END_SOURCE_MESSAGE -->


<a id="m-769d9f3a-a261-4db2-b5cb-934ad6f0e3a9"></a>
## Assistant · C132-M00009

C132-M00009 · 2026-09-12T09:20:17.916941-04:00 · active path

Preceding visible parent: [C132-M00008](part-01.md#m-0e6a115b-9f0b-4187-b5a7-312b9d8cb581)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll verify the runner’s endpoint evidence and execution-policy handling without modifying the package or advancing any campaign gates.
<!-- END_SOURCE_MESSAGE -->


<a id="m-63e36bd9-83e0-4ec7-96ed-d7e5a6e3d438"></a>
## Assistant · C132-M00010

C132-M00010 · 2026-09-12T09:22:55.457791-04:00 · active path

Preceding visible parent: [C132-M00009](part-01.md#m-769d9f3a-a261-4db2-b5cb-934ad6f0e3a9)

<!-- BEGIN_SOURCE_MESSAGE -->
**The feedback is aligned with the current scope. No replacement package or additional restore is needed.** I rechecked the delivered execution ZIP (historical reference: `sandbox:[session]/MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip`; referenced bytes not established here), including its connection arguments, transaction controls, and receipt generation. The watch items resolve as follows.

## 1. Execution policy: optional, not a missing prerequisite

The existing block invokes `python.exe` directly; it does not execute a downloaded `.ps1` file. That is how the delivered run block is written. [export reference: filecite | turn3file1 | L159-L164]

For that paste-and-run workflow, adding `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force` is **not required**. Microsoft documents that execution policy permits individual interactive commands even under `Restricted`. A process-scoped change applies to the current session and does not override Group Policy. My recommendation is to leave the existing block unchanged rather than change execution policy solely for consistency. [export reference: cite | turn661936view0]

## 2. Endpoint visibility: already present in the detailed receipts

In the ZIP’s `reference_export.py`, the host, port, and database are fixed constants. Every `psql` invocation explicitly supplies them; the database user defaults to `postgres`.

The expected connection and transaction identity is:

```text
database                  = msbf_restore_test
server_address            = 127.0.0.1
server_port               = 55432
user                      = postgres    [default connection user]
transaction_read_only     = on
transaction_isolation     = repeatable read
```

These endpoint values agree with the established Reference Environment R1 record. [export reference: filecite | turn2file2 | L17-L22]

**One useful precision point:** the top-level `RUN_RECEIPT.json` is a gate-status summary; it does not currently duplicate those connection fields. When the corresponding sessions complete, the detailed observations are written to:

```text
reference_before/identity_before.json
reference_before/identity_after.json

reference_export/identity_before.json
reference_export/identity_after.json

reference_after/identity_before.json
reference_after/identity_after.json
```

The process logs also record the explicit `psql` connection arguments. The actual connected user is recorded in the identity files; it is not a separate hardcoded username-equality gate. Thus, the endpoint is inspectable in the return without revising the package. This implements the report’s declared before/export/after identity and read-only transaction evidence. [export reference: filecite | turn3file0 | L53-L59]

These are **verified properties of the delivered code**, not observations from a new owner-machine execution.

## 3. Full-750 blockers remain substantive

The current package does not implement or qualify the missing `CURRENT_M2_4`, `CURRENT_R26_WAVE_A`, and `CURRENT_R26_G3` stages. The fresh upstream path, deterministic configuration, endogenous predecessor history, and complete comparison registry also require qualification before a fresh-750 certificate can be earned. Those remain explicit engineering work—not conditions waived by reference parity. [export reference: filecite | turn3file0 | L93-L107]

## 4. The acceptance boundary remains unchanged

The maximum successful result from this package is:

```text
PASS_REFERENCE_A_B_ONLY
```

That means reference binding, native Module A export/input comparison, strict 20-file R4 parity, and the scoped nonmutation observations passed. It does **not** establish a fresh replay or automatically advance to 2,500. The package explicitly retains:

```text
FULL_750_CERTIFICATE_GRANTED = false
FRESH_2500_EXECUTION         = HOLD_NOT_RUN
READINESS_25000              = NOT_ESTABLISHED
```

That boundary is already part of the engineering decision record. [export reference: filecite | turn3file0 | L83-L91]

The prior chat’s assessment is useful review feedback, **not an Independent Audit acceptance or a runtime return**. No owner-machine result has been supplied in this exchange.

**The next action remains the existing run block, followed by the emitted `_RETURN.zip` from `D:\MSBF_CAMPAIGNS\PART2_RETURNS`, including a stopped return.** Do not restore, restart the cluster, edit the locked package, or launch a fresh campaign in response to these watch items.
<!-- END_SOURCE_MESSAGE -->


<a id="m-abc18d73-5041-4a83-b167-aaf2336d89e8"></a>
## Andrew / user · C132-M00011

C132-M00011 · 2026-09-12T09:24:17.552000-04:00 · active path

Preceding visible parent: [C132-M00010](part-01.md#m-63e36bd9-83e0-4ec7-96ed-d7e5a6e3d438)

<!-- BEGIN_SOURCE_MESSAGE -->
it should be noted that every time i've tried to personally work in powershell with this project, I have needed this line to progress: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force  
<!-- END_SOURCE_MESSAGE -->


<a id="m-9ea3cc17-5a19-4d5c-a8d3-58a23fcee4d2"></a>
## Assistant · C132-M00012

C132-M00012 · 2026-09-12T09:24:21.053858-04:00 · active path

Preceding visible parent: [C132-M00011](part-01.md#m-abc18d73-5041-4a83-b167-aaf2336d89e8)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. That changes my recommendation.

For **your MSBF owner-machine workflow**, I will treat this as an established execution prerequisite:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

Even though the current command technically invokes Python directly, your repeated physical experience with this project is stronger operational evidence than the theoretical distinction I made. There is no benefit to omitting a process-scoped setting that has repeatedly been necessary for your environment.

So the beginning of the Part 2 run block should be:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = Join-Path $env:USERPROFILE 'Downloads\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip'
```

This **does not change the package, campaign logic, reference environment, or certification scope**. It is an owner-machine execution-environment accommodation. Reference Environment R1 remains strictly read-only and separate from future replay environments. [export reference: filecite | turn4file2 | L53-L55]

Going forward, when I provide PowerShell execution blocks for this MSBF workstream, I will include that line by default rather than asking you to discover again whether it is needed on your machine.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fb9792ac-21bd-4e11-80be-97fdfebb6fbe"></a>
## Andrew / user · C132-M00013

C132-M00013 · 2026-09-12T09:27:16.766000-04:00 · active path

Preceding visible parent: [C132-M00012](part-01.md#m-9ea3cc17-5a19-4d5c-a8d3-58a23fcee4d2)

<!-- BEGIN_SOURCE_MESSAGE -->
Also, we will not be using my download's folder. I will be saving these zips in D:\MSBF_ARCHIVE.  it should be noted that we have 5.53gb free in my SSD drive C. we have 16tb free in my HDD drive D
<!-- END_SOURCE_MESSAGE -->


<a id="m-74f87702-4aab-4657-8f91-6d873c2cbc6f"></a>
## Assistant · C132-M00014

C132-M00014 · 2026-09-12T09:27:21.588191-04:00 · active path

Preceding visible parent: [C132-M00013](part-01.md#m-fb9792ac-21bd-4e11-80be-97fdfebb6fbe)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. Both points materially affect how I should design the remaining Campaign Scale execution.

For **MSBF owner-machine work going forward**, I will use these operating assumptions:

```text
Package/archive location:
D:\MSBF_ARCHIVE

C: SSD free space:
~5.53 GB — capacity constrained

D: HDD free space:
~16 TB — primary MSBF working/storage volume
```

That reinforces the architecture already established for Reference Environment R1, whose PostgreSQL cluster is deliberately D:-resident. [export reference: filecite | turn4file2 | L15-L24]

### Storage rule going forward

I will avoid putting substantial MSBF artifacts on C: whenever we can control their location. In particular, **no new campaign PostgreSQL clusters/restores, large extractions, campaign outputs, evidence packages, or large temporary working directories should intentionally go to C:**.

D: should carry the heavy work:

```text
D:\MSBF_ARCHIVE
    Downloaded/delivered ZIP packages and retained archives

D:\MSBF_CAMPAIGNS
    Tools
    PostgreSQL clusters
    Fresh campaign databases/data
    Execution workspaces
    Returns
    Logs/evidence
    Temporary campaign artifacts
```

This is especially important before 2,500 and eventually 25,000 because we should not allow PostgreSQL or Python defaults to quietly consume the remaining 5.53 GB on C:.

### Corrected Part 2 run-block beginning

I will therefore **not use `$env:USERPROFILE\Downloads` again** for these packages. The current reference-binding command should begin:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip'
$ExpectedSHA256 = 'db0e934b8fda2624055d76cb55664d8401c0e0b5183d42efb6ff361d91eee52e'
$Python = 'C:\Python314\python.exe'
$PgBin = 'C:\Program Files\PostgreSQL\17\bin'
```

Python and the PostgreSQL binaries can remain on C:; they are existing installations. The important control is that **their data, extraction, execution, and output paths stay on D:**.

I'll apply both conventions automatically to subsequent MSBF PowerShell instructions: **process-scoped execution-policy bypass + `D:\MSBF_ARCHIVE` package source**, with C: treated as capacity-constrained.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d9ba9a45-93d2-40da-bf1f-40a3c51577b3"></a>
## Andrew / user · C132-M00015

C132-M00015 · 2026-09-12T09:33:42.911000-04:00 · active path

Preceding visible parent: [C132-M00014](part-01.md#m-74f87702-4aab-4657-8f91-6d873c2cbc6f)

**Editorial record note:** Attachment references: CS_PART2_REF_AB_20260912T132916Z_fc5a056a_RETURN.zip; CS_PART2_REF_AB_20260912T132916Z_fc5a056a_RETURN.zip.validation.json

<!-- BEGIN_SOURCE_MESSAGE -->
1/5  Binding source package, retained reference and publication.
PostgreSQL password (not logged; Enter is valid for local trust/pgpass):
2/5  Read-only binding of the existing reference; no lifecycle operations.
STOP: reference_before failed with exit 2; see D:\MSBF_CAMPAIGNS\PART2_RETURNS\CS_PART2_REF_AB_20260912T132916Z_fc5a056a\logs\reference_before.stderr.log
5/5  Collecting fresh-snapshot postflight and source nonmutation evidence.

STOP_NO_ADVANCEMENT
RETURN PACKAGE: D:\MSBF_CAMPAIGNS\PART2_RETURNS\CS_PART2_REF_AB_20260912T132916Z_fc5a056a_RETURN.zip
SHA256: 5f40a90150696922c8ed0867c72500e1037baae1aee768f12bbdd29fdb7cd7ad
Full750 remains HOLD. Fresh2500 remains HOLD. 25000 readiness is not established.
WARNING: Stopped. Preserve the emitted return ZIP or error; do not restore, bypass checks, or advance campaigns.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5ba928eb-9738-4973-a17f-7c8c0213a468"></a>
## Assistant · C132-M00016

C132-M00016 · 2026-09-12T09:33:43.914242-04:00 · active path

Preceding visible parent: [C132-M00015](part-01.md#m-d9ba9a45-93d2-40da-bf1f-40a3c51577b3)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll inspect the stopped return package directly, identify the exact `reference_before` failure, and separate an authentication/connection issue from any binding or read-only logic defect.
<!-- END_SOURCE_MESSAGE -->


<a id="m-89312236-9dfa-4c1a-94eb-55474e2dd926"></a>
## Assistant · C132-M00017

C132-M00017 · 2026-09-12T09:34:01.071047-04:00 · active path

Preceding visible parent: [C132-M00016](part-01.md#m-5ba928eb-9738-4973-a17f-7c8c0213a468)

<!-- BEGIN_SOURCE_MESSAGE -->
The stop is clean and informative: this is **not** an authentication failure, source mismatch, or SQL-contract failure. `psql` could not open TCP port **55432 at all**—the existing reference server was not listening when the gate ran.
<!-- END_SOURCE_MESSAGE -->


<a id="m-75b0041f-b686-4438-a249-e74c20c53e5c"></a>
## Assistant · C132-M00018

C132-M00018 · 2026-09-12T09:34:31.797637-04:00 · active path

Preceding visible parent: [C132-M00017](part-01.md#m-89312236-9dfa-4c1a-94eb-55474e2dd926)

<!-- BEGIN_SOURCE_MESSAGE -->
The return also confirms the rest of the preflight behaved correctly: repository identity/cleanliness passed, all **2,884** tracked-file locks passed, the R26 backup hash matched exactly, package/reference integrity passed, and **no database connection or SQL write occurred**. The failure is isolated to server availability.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6a25e3ac-e242-4088-9487-ee72689fa898"></a>
## Assistant · C132-M00019

C132-M00019 · 2026-09-12T09:34:31.797637-04:00 · active path

Preceding visible parent: [C132-M00018](part-01.md#m-75b0041f-b686-4438-a249-e74c20c53e5c)

<!-- BEGIN_SOURCE_MESSAGE -->
This return is a **clean, fail-closed infrastructure stop**, not a campaign or parity failure.

The uploaded return ZIP itself validates correctly at 765,393 bytes with SHA-256 `5f40a90150696922c8ed0867c72500e1037baae1aee768f12bbdd29fdb7cd7ad`. [export reference: filecite | turn5file0 | L2-L5]

### Exact diagnosis

`reference_before.stderr.log` says:

```text
psql: error: connection to server at "127.0.0.1", port 55432 failed:
Connection refused (0x0000274D/10061)

Is the server running on that host and accepting TCP/IP connections?
```

That occurs **before PostgreSQL authentication**. So the password you entered was not tested and is not implicated.

The attempted endpoint was exactly correct:

```text
host     = 127.0.0.1
port     = 55432
user     = postgres
database = msbf_restore_test
```

Those are the established Reference Environment R1 bindings. [export reference: filecite | turn4file2 | L15-L25]

The return also proves several useful things before it stopped:

```text
Package integrity                  PASS
Retained reference integrity       PASS
D:\x\m publication/source binding PASS
Working tree                       CLEAN
Tracked files                      2,884 / 2,884 locked
R26 backup size/hash               PASS
Database connection performed      false
SQL write operations issued        0
Restore operations                 0
Cluster lifecycle operations       0
Fresh 750                          HOLD
Fresh 2,500                        HOLD
25,000 readiness                   NOT ESTABLISHED
```

So we do **not** need another restore, another backup, a rebuilt package, or an R6 wrapper.

Also, the later `reference_after` connection refusal is not a second defect. The runner attempted its best-effort postflight after the initial exception, but the server was still offline.

## What happened

Reference Environment R1 was previously established, but an established PostgreSQL data directory does not imply that its server process remains running indefinitely. At the time of this run, nothing was accepting connections on `127.0.0.1:55432`.

This is now a specific infrastructure condition that justifies starting the **existing** cluster. That is different from going back to the abandoned R4/R5/R6 restore/lifecycle wrappers.

Because we previously saw `pg_ctl -w start` time out even when PostgreSQL subsequently became live, I do **not** want to repeat that pattern. PostgreSQL 17 supports `pg_ctl -W` / `--no-wait`; when used, the start is triggered and readiness can be checked separately. PostgreSQL also explicitly notes that an operation can continue and eventually succeed even after a wait timeout. [export reference: cite | turn761091search12]

### Step 1 — bring up the existing reference cluster only

Run this in PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$PgBin = 'C:\Program Files\PostgreSQL\17\bin'
$Data  = 'D:\MSBF_CAMPAIGNS\pg_clusters\msbf_cs_ref750_routeb_20260912_012713'
$LogDir = 'D:\MSBF_CAMPAIGNS\pg_logs'

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$PgCtl     = Join-Path $PgBin 'pg_ctl.exe'
$PgIsReady = Join-Path $PgBin 'pg_isready.exe'
$Postgres  = Join-Path $PgBin 'postgres.exe'

Write-Host ''
Write-Host 'REFERENCE ENVIRONMENT R1 — INFRASTRUCTURE CHECK'
Write-Host "Data directory: $Data"
Write-Host 'Expected endpoint: 127.0.0.1:55432'
Write-Host ''

Write-Host 'Configured port:'
& $Postgres -D $Data -C port

Write-Host 'Configured listen_addresses:'
& $Postgres -D $Data -C listen_addresses

Write-Host ''
Write-Host 'Checking endpoint...'
& $PgIsReady -h 127.0.0.1 -p 55432 -d msbf_restore_test

if ($LASTEXITCODE -ne 0) {

    Write-Host ''
    Write-Host 'Endpoint is not ready. Checking pg_ctl status...'
    & $PgCtl status -D $Data
    $StatusCode = $LASTEXITCODE

    if ($StatusCode -eq 0) {
        throw @'
STOP: pg_ctl reports this cluster is already running, but
127.0.0.1:55432 is not accepting connections.

Do NOT stop/restart it, delete postmaster.pid, restore anything,
or start another copy. Preserve this output for review.
'@
    }

    $StartLog = Join-Path $LogDir (
        'msbf_cs_ref750_routeb_start_' +
        (Get-Date -Format 'yyyyMMdd_HHmmss') +
        '.log'
    )

    Write-Host ''
    Write-Host 'Starting the EXISTING Reference Environment R1 cluster.'
    Write-Host "Server log: $StartLog"

    & $PgCtl start `
        -D $Data `
        -l $StartLog `
        -W `
        -o "-p 55432 -h 127.0.0.1"

    if ($LASTEXITCODE -ne 0) {
        throw "pg_ctl could not trigger startup. Review: $StartLog"
    }

    Write-Host ''
    Write-Host 'Waiting for 127.0.0.1:55432 to accept connections...'

    $Ready = $false

    for ($i = 1; $i -le 90; $i++) {
        Start-Sleep -Seconds 2

        & $PgIsReady `
            -h 127.0.0.1 `
            -p 55432 `
            -d msbf_restore_test *> $null

        if ($LASTEXITCODE -eq 0) {
            $Ready = $true
            break
        }
    }

    if (-not $Ready) {
        Write-Host ''
        Write-Warning 'Reference server did not become ready.'
        Write-Host "Inspect the server log: $StartLog"

        if (Test-Path -LiteralPath $StartLog) {
            Write-Host ''
            Write-Host 'LAST 80 SERVER-LOG LINES:'
            Get-Content -LiteralPath $StartLog -Tail 80
        }

        throw @'
STOP: Reference Environment R1 did not become ready.
Do NOT restore the backup, delete postmaster.pid, or rerun R6.
'@
    }
}

Write-Host ''
Write-Host 'FINAL READINESS CHECK:'
& $PgIsReady -h 127.0.0.1 -p 55432 -d msbf_restore_test

if ($LASTEXITCODE -ne 0) {
    throw 'STOP: Reference endpoint is still unavailable.'
}

Write-Host ''
Write-Host 'REFERENCE ENVIRONMENT R1 IS ACCEPTING CONNECTIONS.'
Write-Host 'No restore was performed.'
Write-Host 'No campaign execution was performed.'
```

This deliberately keeps **infrastructure bring-up separate from the campaign/reference runner**, consistent with the architecture we established. `pg_ctl` is the standard PostgreSQL utility for starting an existing server data directory, and keeping a server log is also the documented startup practice. [export reference: cite | turn168091search0 | turn761091search12]

### Important stop condition

If the block reaches:

```text
REFERENCE ENVIRONMENT R1 IS ACCEPTING CONNECTIONS.
```

then we have solved the identified blocker.

If instead it says that `pg_ctl` believes PostgreSQL is already running while `55432` is unavailable, **do not kill anything, delete `postmaster.pid`, restore the backup, or rerun R6.** Give me that output and the server-log tail.

Likewise, if startup fails, preserve the emitted log under:

```text
D:\MSBF_CAMPAIGNS\pg_logs
```

### Step 2 — only after the endpoint is ready

Then rerun the **same** reference-binding/export package from:

```text
D:\MSBF_ARCHIVE\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip
```

using the same package SHA-256 and the existing Part 2 run block, with our two established owner-machine conventions:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip'
```

There is **no reason to revise the reference runner based on this return**. It did exactly what we wanted: refused to proceed when the established comparison environment was unavailable.

The failed return should also be retained permanently as engineering evidence. Its disposition is:

```text
CS_PART2_REF_AB_20260912T132916Z_fc5a056a

RESULT:
STOP_NO_ADVANCEMENT

ROOT CAUSE:
Reference PostgreSQL endpoint unavailable /
TCP connection refused at 127.0.0.1:55432

NOT A:
source-binding failure
backup-integrity failure
authentication failure
SQL-contract failure
R4 parity failure
fresh-750 failure

DATABASE MUTATION:
None

NEXT ACTION:
Start and verify the existing Reference Environment R1;
then rerun the unchanged reference A/B gate.
```

That is a good first physical Part 2 return: the fail-closed controls worked exactly as intended.
<!-- END_SOURCE_MESSAGE -->


<a id="m-93e7520e-4157-4357-8b43-70af24ceff83"></a>
## Andrew / user · C132-M00020

C132-M00020 · 2026-09-12T09:41:39.655000-04:00 · active path

Preceding visible parent: [C132-M00019](part-01.md#m-6a25e3ac-e242-4088-9487-ee72689fa898)

**Editorial record note:** Attachment references: CS_PART2_REF_AB_20260912T133727Z_40e95779_RETURN.zip; CS_PART2_REF_AB_20260912T133727Z_40e95779_RETURN.zip.sha256; CS_PART2_REF_AB_20260912T133727Z_40e95779_RETURN.zip.validation.json

<!-- BEGIN_SOURCE_MESSAGE -->

REFERENCE ENVIRONMENT R1 — INFRASTRUCTURE CHECK
Data directory: D:\MSBF_CAMPAIGNS\pg_clusters\msbf_cs_ref750_routeb_20260912_012713
Expected endpoint: 127.0.0.1:55432

Configured port:
5432
Configured listen_addresses:
localhost

Checking endpoint...
127.0.0.1:55432 - no response

Endpoint is not ready. Checking pg_ctl status...
pg_ctl: no server running

Starting the EXISTING Reference Environment R1 cluster.
Server log: D:\MSBF_CAMPAIGNS\pg_logs\msbf_cs_ref750_routeb_start_20260912_093621.log
server starting

Waiting for 127.0.0.1:55432 to accept connections...

FINAL READINESS CHECK:
127.0.0.1:55432 - accepting connections

REFERENCE ENVIRONMENT R1 IS ACCEPTING CONNECTIONS.
No restore was performed.
No campaign execution was performed.
PS D:\x\m> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
>> $ErrorActionPreference = 'Stop'
>>
>> $Zip = 'D:\MSBF_ARCHIVE\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R1_20260912.zip'
>> $ExpectedSHA256 = 'db0e934b8fda2624055d76cb55664d8401c0e0b5183d42efb6ff361d91eee52e'
>> $Python = 'C:\Python314\python.exe'
>> $PgBin = 'C:\Program Files\PostgreSQL\17\bin'
>>
>> if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) {
>>     throw "Package not found: $Zip"
>> }
>> if ((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedSHA256) {
>>     throw 'Package SHA-256 mismatch. Nothing has been executed.'
>> }
>> if (-not (Test-Path -LiteralPath $Python -PathType Leaf)) {
>>     throw "Python not found: $Python"
>> }
>> if (-not (Test-Path -LiteralPath (Join-Path $PgBin 'psql.exe') -PathType Leaf)) {
>>     throw "psql.exe not found under: $PgBin"
>> }
>>
>> $ToolRoot = 'D:\MSBF_CAMPAIGNS\tools\CS_PART2_REF_AB_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
>> if (Test-Path -LiteralPath $ToolRoot) {
>>     throw "Extraction folder already exists: $ToolRoot"
>> }
>> Expand-Archive -LiteralPath $Zip -DestinationPath $ToolRoot
>>
>> & $Python -B (Join-Path $ToolRoot 'reference_export.py') `
>>     --repo 'D:\x\m' `
>>     --pg-bin $PgBin `
>>     --out-root 'D:\MSBF_CAMPAIGNS\PART2_RETURNS'
>>
>> if ($LASTEXITCODE -ne 0) {
>>     Write-Warning 'Stopped. Preserve the emitted return ZIP or error; do not restore, bypass checks, or advance campaigns.'
>> }
1/5  Binding source package, retained reference and publication.
PostgreSQL password (not logged; Enter is valid for local trust/pgpass):
2/5  Read-only binding of the existing reference; no lifecycle operations.
STOP: reference_before failed with exit 3; see D:\MSBF_CAMPAIGNS\PART2_RETURNS\CS_PART2_REF_AB_20260912T133727Z_40e95779\logs\reference_before.stderr.log
5/5  Collecting fresh-snapshot postflight and source nonmutation evidence.

STOP_NO_ADVANCEMENT
RETURN PACKAGE: D:\MSBF_CAMPAIGNS\PART2_RETURNS\CS_PART2_REF_AB_20260912T133727Z_40e95779_RETURN.zip
SHA256: b95b18c5111a29ed8b134b7ae07f8cf58f3db97a9aaf226d5e0a51fb328a8b6b
Full750 remains HOLD. Fresh2500 remains HOLD. 25000 readiness is not established.
WARNING: Stopped. Preserve the emitted return ZIP or error; do not restore, bypass checks, or advance campaigns.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a75d7d78-8b25-48b0-b8f4-020ee82d9b13"></a>
## Assistant · C132-M00021

C132-M00021 · 2026-09-12T09:41:40.451845-04:00 · active path

Preceding visible parent: [C132-M00020](part-01.md#m-93e7520e-4157-4357-8b43-70af24ceff83)

<!-- BEGIN_SOURCE_MESSAGE -->
The server-start step succeeded, so this second return should isolate the next defect. I’ll inspect the new return and determine whether exit 3 is authentication, SQL assertion, or a reference-binding mismatch.
<!-- END_SOURCE_MESSAGE -->


<a id="m-81dc090c-d103-45d2-b283-ba4ea175bf83"></a>
## Assistant · C132-M00022

C132-M00022 · 2026-09-12T09:42:00.262758-04:00 · active path

Preceding visible parent: [C132-M00021](part-01.md#m-a75d7d78-8b25-48b0-b8f4-020ee82d9b13)

<!-- BEGIN_SOURCE_MESSAGE -->
I found the precise defect: the database binding itself is correct. The runner compares `inet_server_addr()::text` to `127.0.0.1`, but PostgreSQL 17 renders that `inet` value as `127.0.0.1/32`. Every other protected identity/count shown in the receipt matches. This is a **nonsemantic adapter/assertion defect**, not a reference mismatch.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5c2699cc-e1e6-41a2-a8f8-49481cc1864f"></a>
## Assistant · C132-M00023

C132-M00023 · 2026-09-12T09:43:49.188049-04:00 · active path

Preceding visible parent: [C132-M00022](part-01.md#m-81dc090c-d103-45d2-b283-ba4ea175bf83)

<!-- BEGIN_SOURCE_MESSAGE -->
The first live receipt actually gave us more than just the formatting defect: it proved the correct database, user, port 55432, PostgreSQL 17.9, exact D: cluster, all 11 schemas, protected counts, repeatable-read/read-only mode, zero transaction tuple writes, and no competing active clients. I’m treating the `/32` issue as a narrowly scoped adapter correction and regression-testing it before you rerun anything.
<!-- END_SOURCE_MESSAGE -->


<a id="m-986b5452-3593-4866-b846-74fb2cf0ec54"></a>
## Assistant · C132-M00024

C132-M00024 · 2026-09-12T09:46:55.288597-04:00 · active path

Preceding visible parent: [C132-M00023](part-01.md#m-5c2699cc-e1e6-41a2-a8f8-49481cc1864f)

<!-- BEGIN_SOURCE_MESSAGE -->
This second return is much more useful: **Reference Environment R1 is healthy and correctly bound. The stop was caused by a defect in my R1 binding runner, not your PostgreSQL environment.**

The uploaded return validates as the exact 767,213-byte package with SHA-256 `b95b18c5111a29ed8b134b7ae07f8cf58f3db97a9aaf226d5e0a51fb328a8b6b`, CRC PASS. [export reference: filecite | turn6file0 | L2-L5]

## What physically passed

I inspected the return package. Before the runner deliberately stopped, PostgreSQL successfully returned:

```text
Database:              msbf_restore_test
User:                  postgres
Server address:        127.0.0.1/32
Server port:           55432
PostgreSQL:            17.9
Data directory:        D:/MSBF_CAMPAIGNS/pg_clusters/
                       msbf_cs_ref750_routeb_20260912_012713

Schemas:               all 11 expected msbf* schemas

merchant_master:       750
merchant_application:  7,147
verification_result:   4,500
monitoring_latest:     130
servicing_latest:      130

transaction_read_only: on
isolation:             repeatable read
transaction writes:    0
other active clients:  none
```

Those match the established Reference Environment R1 identity and protected counts. [export reference: filecite | turn4file2 | L15-L25] [export reference: filecite | turn4file2 | L43-L55]

Your cluster startup was therefore successful.

The fact that `postgresql.conf` reported:

```text
Configured port: 5432
```

is **not a current problem**. We deliberately started this isolated instance with the command-line override for `55432`, and PostgreSQL itself confirmed that the live server is actually listening on **55432**.

Do not later start this cluster without that override unless we deliberately reconfigure the cluster.

## Exact R1 runner defect

The SQL guard contained:

```sql
inet_server_addr()::text='127.0.0.1'
```

PostgreSQL returned its `inet` value as:

```text
127.0.0.1/32
```

So the runner evaluated an otherwise-valid reference environment as false and intentionally triggered:

```text
MSBF_REFERENCE_BIND_MISMATCH
ERROR: division by zero
```

That artificial division-by-zero is simply the fail-closed mechanism. It does **not** mean anything in your database tried to divide by zero.

There was also a second latent manifestation of the same issue: the Python identity validator expected `127.0.0.1` and would subsequently have rejected `127.0.0.1/32`.

## R2 correction

I corrected both places by canonicalizing PostgreSQL's `inet` value with:

```sql
host(inet_server_addr())
```

The required endpoint remains exactly:

```text
127.0.0.1:55432
```

This is a permitted **nonsemantic environment/adapter fix**. There are no changes to:

- repository/publication identity;
- reference data;
- protected counts;
- six Module A SQL exports;
- R4 strategy/business logic;
- approved R4 policy bytes;
- 20-file output lock;
- comparison semantics;
- fresh-750 certification requirements;
- 2,500 authorization;
- 25,000 readiness.

I added a regression test for this exact PostgreSQL CIDR-rendering behavior. The corrected package passes **47/47 offline tests**.

### Corrected package

Download R2 reference-binding package (historical reference: `sandbox:[session]/MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R2_20260912.zip`; referenced bytes not established here)

SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R2_20260912.zip.sha256`; referenced bytes not established here)

Validation record (historical reference: `sandbox:[session]/MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R2_20260912_VALIDATION.json`; referenced bytes not established here)

R2 package identity:

```text
MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R2_20260912.zip

Bytes:
22,915,641

SHA-256:
7296a169a1460bedc9d9271e2b977c17687ee8e61a4e0cdd1fa5e92fb0df3149
```

CRC, path safety, Python syntax, JSON parsing, internal manifest verification, and retained-reference ZIP CRC all passed.

**Retire R1 from execution.** Keep it and both stopped return ZIPs as engineering evidence, but do not run R1 again.

## Next command

Save the new R2 ZIP here:

```text
D:\MSBF_ARCHIVE\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R2_20260912.zip
```

Since your reference server is currently live, you do **not** need to restart or restore anything. Run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_CS_PART2_REFERENCE_BIND_EXPORT_R2_20260912.zip'
$ExpectedSHA256 = '7296a169a1460bedc9d9271e2b977c17687ee8e61a4e0cdd1fa5e92fb0df3149'
$Python = 'C:\Python314\python.exe'
$PgBin = 'C:\Program Files\PostgreSQL\17\bin'

if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) {
    throw "Package not found: $Zip"
}

$ObservedSHA256 = (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant()

if ($ObservedSHA256 -ne $ExpectedSHA256) {
    throw "Package SHA-256 mismatch. Expected $ExpectedSHA256 but observed $ObservedSHA256. Nothing has been executed."
}

if (-not (Test-Path -LiteralPath $Python -PathType Leaf)) {
    throw "Python not found: $Python"
}

if (-not (Test-Path -LiteralPath (Join-Path $PgBin 'psql.exe') -PathType Leaf)) {
    throw "psql.exe not found under: $PgBin"
}

$ToolRoot = 'D:\MSBF_CAMPAIGNS\tools\CS_PART2_REF_AB_R2_' + (Get-Date -Format 'yyyyMMdd_HHmmss')

if (Test-Path -LiteralPath $ToolRoot) {
    throw "Extraction folder already exists: $ToolRoot"
}

Expand-Archive -LiteralPath $Zip -DestinationPath $ToolRoot

& $Python -B (Join-Path $ToolRoot 'reference_export.py') `
    --repo 'D:\x\m' `
    --pg-bin $PgBin `
    --out-root 'D:\MSBF_CAMPAIGNS\PART2_RETURNS'

if ($LASTEXITCODE -ne 0) {
    Write-Warning 'Stopped. Preserve the emitted return ZIP; do not restore, bypass checks, or advance campaigns.'
}
```

### One correction to the failed return's summary

The failed R1 `RUN_RECEIPT.json` says:

```text
DATABASE_CONNECTION_PERFORMED = false
```

That flag is conservative bookkeeping: the code only flips it to `true` after the entire reference session completes.

Physically, **the database connection absolutely did occur**. We know that because PostgreSQL generated `identity_before.json` containing the live database identity, counts, cluster directory, transaction state, and endpoint. So this failure should be classified as:

```text
REFERENCE ENVIRONMENT CONNECTION       PASS
REFERENCE IDENTITY PHYSICALLY OBSERVED PASS
REFERENCE SQL GUARD                    FAIL — RUNNER DEFECT REF-04
DATABASE MUTATION                      NONE OBSERVED
MODULE A EXPORT                        NOT RUN
R4 PARITY                              NOT RUN
FULL 750                               HOLD
FRESH 2,500                            HOLD
25,000 READINESS                       NOT ESTABLISHED
```

That distinction should remain in the private engineering record.

The next meaningful evidence is the **R2 `_RETURN.zip`**. Upload it whether it passes or stops.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dc55957d-05b4-46ea-a812-2a55cfc6411d"></a>
## Andrew / user · C132-M00025

C132-M00025 · 2026-09-12T11:42:47.311000-04:00 · active path

Preceding visible parent: [C132-M00024](part-01.md#m-986b5452-3593-4866-b846-74fb2cf0ec54)

**Editorial record note:** Attachment references: CS_PART2_REF_AB_20260912T153521Z_31d25cdc_RETURN.zip; CS_PART2_REF_AB_20260912T153521Z_31d25cdc_RETURN.zip.sha256; CS_PART2_REF_AB_20260912T153521Z_31d25cdc_RETURN.zip.validation.json

<!-- BEGIN_SOURCE_MESSAGE -->
1/5  Binding source package, retained reference and publication.
PostgreSQL password (not logged; Enter is valid for local trust/pgpass):
2/5  Read-only binding of the existing reference; no lifecycle operations.
  reference_before: still running (30 seconds elapsed)
3/5  Exporting six Module A inputs in one read-only snapshot.
  reference_export: still running (30 seconds elapsed)
4/5  Running unchanged R4 campaign wrapper with exact approved policy bytes.
  r4_campaign_reference: still running (30 seconds elapsed)
STOP: Native Module A/R4 differs from the locked reference; no exclusions were widened
5/5  Collecting fresh-snapshot postflight and source nonmutation evidence.
  reference_after: still running (30 seconds elapsed)

STOP_NO_ADVANCEMENT
RETURN PACKAGE: D:\MSBF_CAMPAIGNS\PART2_RETURNS\CS_PART2_REF_AB_20260912T153521Z_31d25cdc_RETURN.zip
SHA256: 81e61ded494cec6cc8836fff63809375bab25622205c82916cb8a102b5e51b48
Full750 remains HOLD. Fresh2500 remains HOLD. 25000 readiness is not established.
WARNING: Stopped. Preserve the emitted return ZIP; do not restore, bypass checks, or advance campaigns.
<!-- END_SOURCE_MESSAGE -->


<a id="m-806df0f6-4a5b-4f99-98ad-9f5052c5afca"></a>
## Assistant · C132-M00026

C132-M00026 · 2026-09-12T11:42:49.577004-04:00 · active path

Preceding visible parent: [C132-M00025](part-01.md#m-dc55957d-05b4-46ea-a812-2a55cfc6411d)

<!-- BEGIN_SOURCE_MESSAGE -->
The R2 infrastructure and export stages got much farther, so this return should tell us whether the divergence is in the six native Module A inputs, the unchanged R4 wrapper, or only a rendering/hash surface. I’ll isolate the first differing file/value and keep the full-750/2,500 gates closed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cbcd25a3-3152-4d0a-ae7f-099ebdefd66e"></a>
## Assistant · C132-M00027

C132-M00027 · 2026-09-12T11:43:46.720620-04:00 · active path

Preceding visible parent: [C132-M00026](part-01.md#m-806df0f6-4a5b-4f99-98ad-9f5052c5afca)

<!-- BEGIN_SOURCE_MESSAGE -->
The divergence is now localized to **five of 20 R4 files**, and three are derivative duplicates/manifest effects. The two substantive files have identical byte lengths; their first mismatch is a different row appearing at the same position, which strongly points to deterministic row ordering rather than changed business values. I’m testing full row-set equality before deciding whether any correction is permissible.
<!-- END_SOURCE_MESSAGE -->
