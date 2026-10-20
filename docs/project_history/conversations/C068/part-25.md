# Merchant POS Lending Simulator

Part 25 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-24.md)
[Next part](part-26.md)

<a id="m-461c7b2a-0cf1-42aa-8e73-eee0f9b96462"></a>
## Assistant · C068-M00319

C068-M00319 · 2026-07-27T13:12:33.121153-04:00 · active path

Preceding visible parent: [C068-M00318](part-24.md#m-a1680d34-dd37-4c4d-8726-5c9d6244cf31)

<!-- BEGIN_SOURCE_MESSAGE -->
# M1.15 — Latest Output, Archive, Comparison & Consumption Contract

The complete **M1.15 v0.2 governed module** is built, statically validated, integrated into the accepted M1.14 repository, and ready for controlled PostgreSQL execution.

M1.15 is **not yet live-executed or accepted**. Formal acceptance will require successful execution, structured evidence export, independent evidence review, and milestone sign-off.

## Primary deliveries

### Updated full project repository

Download MSBF Project v0.2 — M1.15 Ready for Execution (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_15_READY_FOR_EXECUTION_Windows.zip`; referenced bytes not established here)

Download the full-project SHA-256 file (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_15_READY_FOR_EXECUTION_Windows.zip.sha256`; referenced bytes not established here)

Canonical long-form copy:

Download the canonical M1.15-ready project repository (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M1_15_READY_FOR_EXECUTION.zip`; referenced bytes not established here)

The repository preserves all accepted work through **M1.14** and adds M1.15 in **Ready for Live Execution** status.

For Windows, extract near the drive root:

```text
C:\MSBF\
```

### Standalone M1.15 package

Download MSBF M1.15 v0.2 (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2.zip`; referenced bytes not established here)

Download the standalone SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2.zip.sha256`; referenced bytes not established here)

Canonical long-form copy:

Download the canonical standalone M1.15 package (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_latest_output_archive_comparison_consumption_contract_v0_2.zip`; referenced bytes not established here)

### Package index and validation records

- M1.15 delivery index (historical reference: `sandbox:[session]/M1_15_DELIVERY_INDEX.md`; referenced bytes not established here)
- Complete package-build report (historical reference: `sandbox:[session]/MSBF_M1_15_PACKAGE_BUILD_REPORT.json`; referenced bytes not established here)
- Execution and validation guide (historical reference: `sandbox:[session]/M1_15_EXECUTION_AND_VALIDATION_GUIDE.md`; referenced bytes not established here)
- Validation matrix (historical reference: `sandbox:[session]/M1_15_VALIDATION_MATRIX.md`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/M1_15_PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Architecture specification (historical reference: `sandbox:[session]/M1_15_ARCHITECTURE.md`; referenced bytes not established here)
- Module manifest (historical reference: `sandbox:[session]/M1_15_MANIFEST.csv`; referenced bytes not established here)
- Machine-readable static validation (historical reference: `sandbox:[session]/M1_15_STATIC_VALIDATION.json`; referenced bytes not established here)

---

# What M1.15 creates

M1.15 converts the accepted Module 1 analytical evidence into a controlled downstream-consumption contract.

It does not recalculate any upstream analytics. It consumes the accepted, persisted M1.7–M1.14 outputs and organizes them into four governed layers.

| Governed output | Expected rows | Purpose |
|---|---:|---|
| Consumption-contract registry | 1 | Contract version, schema version, lifecycle status, lineage, and hash |
| Latest application output | 1,500 | Current scenario-aware Module 1 contract |
| Immutable application archive | 1,500 | Permanent run-versioned copy of the contract |
| Matched scenario comparison | 750 | One baseline-versus-stress comparison per application |
| **Canonical entities** | **3,751** | Combined deterministic reconciliation universe |

## Contract registry

```text
msbf_ctl.m1_15_consumption_contract_registry
```

The registry governs:

- contract code;
- contract version;
- schema version;
- source run;
- accepted scenario set;
- contract lifecycle status;
- latest, archive, and comparison counts;
- canonical set hashes;
- creation and validation lineage.

The governed contract identity is:

```text
Contract code
M1_APPLICATION_CONSUMPTION

Contract version
1

Schema version
M1_CONTRACT_SCHEMA_V1
```

## Latest output

```text
msbf_m1.application_module1_latest
```

The latest table contains one current Module 1 record for each accepted:

```text
scenario
+
merchant application
```

Expected grain:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
```

It consolidates consumption-ready evidence across:

- source quality and data confidence;
- verification and fraud;
- processor continuity;
- cash-flow features;
- obligations and residual liquidity;
- operating archetype and resilience;
- integrated merchant-risk proxy;
- EAD, recovery, LGD, and comparative loss;
- unit economics and risk-adjusted contribution;
- controlled fallback, review, and hard-stop indicators;
- source row hashes and lineage payloads.

The contract contains selected flattened analytical fields for ordinary consumption while retaining governed source payloads and hashes for deeper reconciliation.

## Immutable archive

```text
msbf_m1.application_module1_archive
```

The archive preserves the exact generated contract by:

```text
run
+ contract version
+ scenario
+ application
```

Archive controls include:

- append-only persistence;
- no update;
- no delete;
- exact latest-to-archive reproduction;
- independent row hashes;
- immutable run and contract lineage.

A database trigger rejects attempts to modify or delete accepted archive records.

## Matched scenario comparison

```text
msbf_m1.application_module1_scenario_comparison
```

The comparison table contains one record per accepted application and joins the matched:

```text
BASELINE
versus
RECESSION_ENERGY
```

evidence.

It exposes governed changes in areas such as:

- data confidence;
- operating and liquidity evidence;
- capacity;
- resilience;
- integrated risk;
- EAD and LGD;
- comparative expected loss;
- risk-adjusted contribution;
- annualized return;
- economic tier;
- review and hard-stop status.

The comparison record also preserves explicit worsening indicators rather than requiring downstream consumers to reconstruct them independently.

The economic-worsening identity evaluates all three governed paths:

```text
Risk-adjusted contribution deterioration
OR
Annualized return deterioration
OR
Economic-tier deterioration
```

---

# Governed consumption views

M1.15 publishes controlled views for downstream analytics and Power BI integration.

```text
msbf_m1.v_m1_15_latest_consumption
```

Current scenario-aware Module 1 application contract.

```text
msbf_m1.v_m1_15_scenario_comparison
```

Matched baseline-versus-stress comparison contract.

```text
msbf_m1.v_m1_15_contract_lineage
```

Contract, run, source, scenario, archive, and hash lineage.

```text
msbf_m1.v_m1_15_power_bi_contract
```

Consumption-oriented structure for executive reconciliation and reporting.

M1.15 remains a **consumption contract**, not a decision engine. It does not create:

- approval;
- counteroffer;
- manual-review decision;
- decline decision;
- price;
- factor or rate;
- final funding amount;
- adverse-action reason;
- portfolio allocation decision.

Those belong to the later strategy layer.

---

# Performance architecture

The M1.6–M1.14 performance lessons were applied before release.

## No upstream regeneration

M1.15 does not rebuild:

```text
POS history
Deposit and liquidity history
Scenario overlays
Source-quality evidence
Verification or fraud logic
Cash-flow features
Capacity
Operating resilience
Integrated risk
Exposure and LGD
Comparative loss
Unit economics
```

It reads only the accepted persisted records.

## Bounded processing path

```text
Accepted M1.7–M1.14 physical outputs
        ↓
Materialize the 1,500 scenario/application contract inputs once
        ↓
Build target-typed latest records
        ↓
Persist and index latest output
        ↓
Create immutable archive copy
        ↓
Construct 750 matched comparison records
        ↓
Index and ANALYZE
        ↓
Reconstruct physical hashes independently
        ↓
Reconcile 3,751 canonical entities once
```

## SQL safeguards

The final package was checked for the recurring defect classes identified in prior modules:

```text
Top-level invalid RAISE NOTICE statements          0
Standalone readiness-helper SELECT calls           0
Standalone validation-helper SELECT calls          0
Scalar md5 / aggregate FILTER defects               0
Unsupported Boolean max/min patterns                0
Dollar-quote or parenthesis findings                0
Broad joined CTAS alias.* projection defects        0
Global scenario-code uniqueness assumptions         0
Upstream blueprint-regeneration paths               0
```

Program 110 uses valid PL/pgSQL `PERFORM` for its readiness guard and valid `DO` blocks for execution-phase notices.

---

# Exact execution order

Run the M1.15 programs in DBeaver against:

```text
msbf_strategy
```

Use **Execute SQL Script**.

```text
108 — Schema, policy, contract-registry, and view extension
109 — Hard-stop preflight validation
110 — Latest, archive, comparison, and contract generation
111 — Positive validation
112 — Negative controls
113 — Acceptance finalizer
114 — Master report
115 — Detailed report
```

## Required program-110 checkpoint

```text
run_status                  M1_15_GENERATED

contract_registry_rows      1
latest_rows                 1,500
archive_rows                1,500
comparison_rows             750

applications                750
scenarios                   2
canonical_entities          3,751
row_level_mismatches        0

latest_set_hash             non-null
archive_set_hash            non-null
comparison_set_hash         non-null
contract_set_hash           non-null
combined_set_hash           non-null

generation_status           PASS
```

After program 110 commits successfully, **do not rerun it**.

## Required subsequent results

```text
111 positive validation
84 / 84 PASS

112 negative controls
7 / 7 PASS

113 acceptance finalizer
gate status = PASS
run status  = M1_15_ACCEPTED

114 master report
overall_m1_15_status = PASS

115 detailed report
20 result sets
```

The final deterministic-mismatch and blocking-error result sets must preserve their headers and contain zero data rows.

Program 111 uses a session-scoped validation table with:

```sql
ON COMMIT PRESERVE ROWS
```

so the 84-row result remains sortable and filterable after commit within the same DBeaver connection.

---

# Contingency programs

These are not part of the normal execution sequence.

## Program 108A — Failed-generation recovery

Use only after program 110 fails or is cancelled before commit, followed by:

```sql
ROLLBACK;
```

It verifies:

```text
run_status             M1_14_ACCEPTED
contract rows          0 or approved pre-generation registry state
latest rows            0
archive rows           0
comparison rows        0
M1.15 evidence rows    0
M1.15 gate rows        0
blocking errors        0
recovery status        PASS
```

## Program 110A — Generation-result reconstruction

Use only when program 110 committed successfully but DBeaver lost or closed the generation result tab.

It is read-only and reconstructs the governed generation checkpoint from:

- persisted latest rows;
- immutable archive rows;
- comparison rows;
- contract-registry evidence;
- physical row hashes;
- stored set hashes.

It must return:

```text
generation_reconciliation_status = PASS
```

---

# Validation framework

M1.15 includes:

```text
84 positive controls
7 negative controls
20 detailed evidence result sets
```

The positive controls cover:

- every accepted predecessor gate;
- every accepted upstream set hash;
- accepted scenario-set scoping;
- exact latest, archive, comparison, and contract counts;
- unique physical grains;
- contract-registry version and lifecycle state;
- latest-to-archive exact reproduction;
- archive immutability controls;
- baseline and stress scenario coverage;
- matched comparison coverage;
- flattened-field and source-payload lineage;
- review, hard-stop, and fallback reproduction;
- risk, loss, and economics reconciliation;
- worsening-indicator identities;
- latest, archive, comparison, contract, and combined hashes;
- downstream stage boundaries;
- zero blocking configuration errors.

The negative controls test fail-closed rejection of invalid contract and execution conditions without modifying accepted upstream evidence.

---

# Evidence to retain

Structured CSV exports are sufficient. Execution logs remain optional unless diagnosing a defect.

Retain:

```text
108 schema/policy/contract checkpoint
109 preflight result
110 generation checkpoint
111 positive-validation result
112 negative-control result
113 acceptance-finalizer result
114 one-row master report
115 all twenty detailed-report result sets
completed M1.15 acceptance milestone
```

The complete file inventory and exact governed filenames are listed in:

M1.15 delivery index (historical reference: `sandbox:[session]/M1_15_DELIVERY_INDEX.md`; referenced bytes not established here)

---

# Static and archive QA

The release candidate passed:

```text
Positive controls                         84
Negative controls                          7
Detailed-report result sets               20

Module ZIP CRC validation                PASS
Module ZIP complete extraction           PASS
Module source/archive inventory match    PASS
Module extracted hash comparison         PASS

Project ZIP CRC validation               PASS
Project ZIP complete extraction          PASS
Project source/archive inventory match   PASS
Project extracted hash comparison        PASS
```

A PostgreSQL server was not available in the artifact-build environment. Static validation cannot establish live transactional execution, actual contract distributions, or formal M1.15 acceptance.

---

# Next stage after M1.15 acceptance

The final Module 1 development stage is:

> **M1.16 — End-to-End QA, Evidence & G2 Contract Acceptance**

M1.16 will perform:

- complete Module 1 row-count and grain reconciliation;
- preservation of the full accepted hash chain;
- latest-versus-archive reconciliation;
- matched comparison completeness;
- contract-version and schema-version validation;
- reproducibility and rerun controls;
- end-to-end stage-boundary verification;
- final evidence indexing;
- formal G2 Module 1 contract acceptance.

The governed progression is now:

```text
G0 Physical Foundation
PASS

→

G1 Governed Run Control
PASS

→

M1.2–M1.14
PASS

→

M1.15 Latest Output, Archive, Comparison & Consumption Contract
READY FOR LIVE EXECUTION

→

M1.16 End-to-End QA, Evidence & G2 Contract Acceptance
PENDING M1.15 ACCEPTANCE
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-0a39ff46-b63b-41ca-95a6-afe1d4fbc846"></a>
## Andrew / user · C068-M00320

C068-M00320 · 2026-07-27T13:49:15.512000-04:00 · active path

Preceding visible parent: [C068-M00319](part-25.md#m-461c7b2a-0cf1-42aa-8e73-eee0f9b96462)

<!-- BEGIN_SOURCE_MESSAGE -->
Unfortunately the download links do not appear to be working in the last prompt response for the latest updates to the MSBF project, including M1.15 stand-alone. Please provide working links.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b9394951-258d-4b81-b06a-5280f66d6017"></a>
## Assistant · C068-M00321

C068-M00321 · 2026-07-27T14:44:09.367344-04:00 · active path

Preceding visible parent: [C068-M00320](part-25.md#m-0a39ff46-b63b-41ca-95a6-afe1d4fbc846)

<!-- BEGIN_SOURCE_MESSAGE -->
The M1.15 archives have been regenerated and validated for CRC integrity, complete extraction, source/archive inventory, extracted-file hashes, and Windows ZIP compatibility.

## Full project repository — recommended download

Download MSBF Project v0.2 — M1.15 Ready for Execution (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_15_READY_FOR_EXECUTION_Windows.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_15_READY_FOR_EXECUTION_Windows.zip.sha256`; referenced bytes not established here)

Canonical long-form copy:

Download the canonical M1.15-ready full-project repository (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M1_15_READY_FOR_EXECUTION.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M1_15_READY_FOR_EXECUTION.zip.sha256`; referenced bytes not established here)

## Standalone M1.15 package

Download MSBF M1.15 v0.2 (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2.zip.sha256`; referenced bytes not established here)

Canonical long-form copy:

Download the canonical standalone M1.15 package (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_latest_output_archive_comparison_consumption_contract_v0_2.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_latest_output_archive_comparison_consumption_contract_v0_2.zip.sha256`; referenced bytes not established here)

## Validation record and execution materials

- Regenerated-delivery validation report (historical reference: `sandbox:[session]/MSBF_M1_15_REGENERATED_DELIVERY_VALIDATION.json`; referenced bytes not established here)
- M1.15 execution and validation guide (historical reference: `sandbox:[session]/M1_15_EXECUTION_AND_VALIDATION_GUIDE.md`; referenced bytes not established here)
- M1.15 validation matrix (historical reference: `sandbox:[session]/M1_15_VALIDATION_MATRIX.md`; referenced bytes not established here)
- M1.15 package-validation report (historical reference: `sandbox:[session]/M1_15_PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)
- M1.15 architecture specification (historical reference: `sandbox:[session]/M1_15_ARCHITECTURE.md`; referenced bytes not established here)
- M1.15 delivery index (historical reference: `sandbox:[session]/M1_15_DELIVERY_INDEX.md`; referenced bytes not established here)
<!-- END_SOURCE_MESSAGE -->


<a id="m-40df32f3-2b78-452a-afe4-5bb53bcc64f8"></a>
## Andrew / user · C068-M00322

C068-M00322 · 2026-07-27T15:56:50.190000-04:00 · active path

Preceding visible parent: [C068-M00321](part-25.md#m-b9394951-258d-4b81-b06a-5280f66d6017)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(165).png

<!-- BEGIN_SOURCE_MESSAGE -->
error in script 110:
<!-- END_SOURCE_MESSAGE -->


<a id="m-7ef05c20-30d9-4b2f-9fd9-f0d77caf64ab"></a>
## Assistant · C068-M00323

C068-M00323 · 2026-07-27T16:17:16.046531-04:00 · active path

Preceding visible parent: [C068-M00322](part-25.md#m-40df32f3-2b78-452a-afe4-5bb53bcc64f8)

<!-- BEGIN_SOURCE_MESSAGE -->
# Diagnosis

This is an **ambiguous join-key defect in program 110**, not a problem with the accepted M1.14 data or the M1.15 business design.

The opening M1.15 context query effectively does this:

```sql
FROM msbf_ctl.run_registry r
JOIN msbf_m1.application_unit_economics_snapshot e
  ON e.module1_run_id = r.run_id
JOIN msbf_ctl.scenario_registry sr
  USING (scenario_id)
```

Both tables already on the left side expose a column named `scenario_id`:

```text
msbf_ctl.run_registry.scenario_id
msbf_m1.application_unit_economics_snapshot.scenario_id
```

After the first join, PostgreSQL therefore sees **two `scenario_id` columns in the left relation**. `USING (scenario_id)` cannot determine which one should join to `scenario_registry`, producing:

```text
SQLSTATE 42702
common column name "scenario_id" appears more than once in left table
```

The screenshot confirms that exact PostgreSQL error. [export reference: filecite | turn31file18]

The correct construction is explicit:

```sql
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id = e.scenario_id
```

The scenario must be attributed to the accepted M1.14 scenario-aware economics row—not the nullable scenario reference on the technical run registry.

This should have been caught in M1.15 static QA. A check for global scenario-code assumptions is not enough; the package also needed a dedicated audit for `USING` clauses applied after a multi-table join had already introduced duplicate column names.

# Immediate DBeaver action

Click **Stop**.

Do not use:

```text
Retry
Skip
Skip All
```

Then execute:

```sql
ROLLBACK;
```

The documented M1.15 execution standard is to stop on the first error and roll back a failed transactional program. [export reference: filecite | turn36file3]

Do not continue to programs 111–115.

Do not rerun program 108. Its schema and policy extension should remain committed. Program 109 can also remain as retained preflight evidence.

# Database impact

This error occurs while program 110 is creating its initial `_m1_15_ctx` temporary table, before it reaches the governed persistence stages.

After rollback, the expected state is:

```text
run_status                  M1_14_ACCEPTED

M1.15 latest rows           0
M1.15 archive rows          0
M1.15 comparison rows       0
M1.15 generation evidence   0
M1.15 acceptance gates      0
```

Therefore:

- accepted M1.14 records remain unchanged;
- no M1.15 latest output should have committed;
- no immutable archive rows should have committed;
- no comparison rows or contract hashes should have committed;
- no manual status reset should be performed.

M1.15’s intended outputs remain one contract registry row, 1,500 latest rows, 1,500 archive rows, and 750 matched comparison rows; none should be partially retained from this failed attempt. [export reference: filecite | turn36file4]

# Required source upload for the consolidated hotfix

The actual M1.15 SQL source tree is not currently mounted in this chat’s working storage. The previous regenerated links created documentation references, but the executable programs 108–115 are not available here for a responsible downstream audit.

Upload **one** of the following:

1. **Preferred:** `MSBF_M1_15_v0_2.zip`
2. **Alternative:** `110_msbf_m1_15_latest_archive_comparison_generation_v0_2.sql`

The standalone ZIP is strongly preferred because the hotfix should not be limited to this one visible join. The consolidated **M1.15 v0.2R1** review needs to inspect programs 110–115 for:

- every `USING (scenario_id)` pattern;
- ambiguous `module1_run_id`, `merchant_application_id`, contract-version, or scenario-set keys;
- joined CTAS statements with duplicate output names;
- broad `alias.*` projections;
- latest/archive/comparison hash reconstruction;
- validation and acceptance queries carrying the same ambiguity;
- report queries that might fail only after acceptance.

The resulting package should contain:

```text
108B — fail-closed post-failure recovery check
110  — corrected generation
111  — version-aligned positive validation
112  — version-aligned negative controls
113  — version-aligned acceptance finalizer
114  — version-aligned master report
115  — version-aligned detailed report
110A — corrected contingency reconstruction
```

It should also include synchronized clean-build replacements, professional documentation, static SQL audits, manifest, SHA-256 inventory, and a validated ZIP. No M1.14 rerun or upstream business regeneration should be required.

Upload `MSBF_M1_15_v0_2.zip`; that single file is sufficient for the complete consolidated repair.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3f01baac-54e9-407b-95ce-32ec63609608"></a>
## Andrew / user · C068-M00324

C068-M00324 · 2026-07-27T16:21:15.276000-04:00 · active path

Preceding visible parent: [C068-M00323](part-25.md#m-7ef05c20-30d9-4b2f-9fd9-f0d77caf64ab)

**Editorial record note:** Attachment references: MSBF_M1_15_v0_2.zip

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-1891fa28-e6de-4eeb-a497-bcf985786d18"></a>
## Assistant · C068-M00325

C068-M00325 · 2026-07-27T16:44:47.726789-04:00 · active path

Preceding visible parent: [C068-M00324](part-25.md#m-3f01baac-54e9-407b-95ce-32ec63609608)

<!-- BEGIN_SOURCE_MESSAGE -->
# M1.15 v0.2R1 consolidated hotfix completed

I audited the uploaded standalone M1.15 package from program 108 through program 115. The immediate program-110 failure was real, but the full review identified several latent downstream defects that would otherwise have produced additional execution rounds.

## Root cause of the program-110 failure

The initial context query joined:

```sql
msbf_ctl.run_registry r
```

and:

```sql
msbf_m1.application_unit_economics_snapshot e
```

Both relations exposed `scenario_id`. The next clause used:

```sql
JOIN msbf_ctl.scenario_registry sr
USING (scenario_id)
```

PostgreSQL could not determine which left-side `scenario_id` was intended.

The corrected relationship is explicit:

```sql
JOIN msbf_ctl.scenario_registry sr
  ON sr.scenario_id = e.scenario_id
```

The accepted M1.14 economics row is the authoritative source of the scenario identity.

---

# Additional defects corrected through the downstream audit

## 1. Recursive readiness function installed by program 108

The original function contained:

```sql
PERFORM msbf_m1.m1_15_assert_configuration(p_run_id);
PERFORM msbf_m1.m1_15_assert_prerequisite_status(p_run_id);
```

inside `m1_15_assert_prerequisite_status()` itself.

That was a recursive self-call rather than a legitimate validation step. The hotfix repairs the function and establishes a centralized readiness chain:

```text
Configuration validation
→ prerequisite run-status validation
→ pristine M1.15 target validation
→ generation authorization
```

## 2. Additional ambiguous `USING` joins

Program 111 contained chained joins where the accumulated left relation already carried duplicate run, application, or scenario identifiers. Those joins could have failed later in positive validation.

All operational M1.15 joins now use explicit, qualified `ON` predicates.

## 3. Latent acceptance-table duplicate columns

Program 113 previously combined broad CTE projections whose sources both exposed a field named:

```text
combined_hash
```

That could have caused a duplicate-column CTAS failure during acceptance.

The revised acceptance table gives every recomputed, stored, and registry hash a unique name, including:

```text
recomputed_combined_hash
stored_combined_set_hash
registry_latest_set_hash
registry_archive_set_hash
registry_comparison_set_hash
registry_contract_set_hash
combined_set_hash
```

The associated acceptance-summary reference was also corrected to use the governed `combined_set_hash`.

## 4. Incomplete pristine-state protection

The readiness and preflight controls now require all of the following to be empty before generation:

```text
Latest contract rows
Archive rows
Scenario-comparison rows
Contract-registry rows
M1.15 run-evidence rows
M1.15 acceptance-gate rows
Blocking configuration errors
```

This prevents accidental partial reruns or stale contract evidence.

---

# Download the final hotfix

## Recommended package

Download M1.15 v0.2R1 — Ambiguous Join & Downstream Audit Hotfix (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
8fd1d8ef0a5566a7c92203e4d91e416d6c557b2c91df5ca10c7993de0a3e2fac

Archive size
76,950 bytes

Files
31
```

Canonical long-form copy:

Download the canonical M1.15 v0.2R1 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_v0_2R1_ambiguous_join_downstream_audit_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_v0_2R1_ambiguous_join_downstream_audit_hotfix.zip.sha256`; referenced bytes not established here)

Both archives are byte-identical.

## Key files

- 108B — Recovery and readiness-function repair (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/tests/108B_msbf_m1_15_failed_ambiguous_join_recovery_and_function_repair_v0_2R1.sql`; referenced bytes not established here)
- 109 — Hard-stop preflight (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/tests/109_msbf_m1_15_preflight_validation_v0_2R1.sql`; referenced bytes not established here)
- 110 — Corrected contract generation (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/sql/110_msbf_m1_15_latest_archive_comparison_generation_v0_2R1.sql`; referenced bytes not established here)
- 111 — Corrected positive validation (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/sql/111_msbf_m1_15_consumption_contract_validation_v0_2R1.sql`; referenced bytes not established here)
- 112 — Negative controls (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/sql/112_msbf_m1_15_negative_control_tests_v0_2R1.sql`; referenced bytes not established here)
- 113 — Corrected acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/sql/113_msbf_m1_15_acceptance_finalize_v0_2R1.sql`; referenced bytes not established here)
- 114 — Master report (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/tests/114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R1.sql`; referenced bytes not established here)
- 115 — Detailed report (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/tests/115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R1.sql`; referenced bytes not established here)
- Complete execution guide (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/docs/M1_15_v0_2R1_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/docs/M1_15_v0_2R1_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Final package-validation report (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Machine-readable final validation (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_FINAL_PACKAGE_VALIDATION.json`; referenced bytes not established here)

---

# Exact recovery and execution sequence

## 1. Stop and roll back the failed program 110

In DBeaver, select:

```text
Stop
```

Do not select:

```text
Retry
Skip
Skip All
```

Then execute:

```sql
ROLLBACK;
```

The failure occurred while program 110 was creating its first temporary context table. No M1.15 latest, archive, comparison, contract, evidence, or acceptance rows should have committed.

Do **not** rerun original program 108.

## 2. Run program 108B

```text
108B_msbf_m1_15_failed_ambiguous_join_recovery_and_function_repair_v0_2R1.sql
```

Required state:

```text
prior_run_status                M1_14_ACCEPTED

latest_rows                     0
archive_rows                    0
comparison_rows                 0
contract_rows                   0
evidence_rows                   0
gate_rows                       0
blocking_errors                 0

approved_policy_rows            1
contract_registry_exists        true
latest_table_exists             true
archive_table_exists            true
comparison_table_exists         true

repaired_recursive_guard        true
centralized_readiness_guard     true
recovery_status                 PASS
```

The program repairs the installed functions but does not generate or modify M1.15 contract rows.

## 3. Run corrected program 109

```text
109_msbf_m1_15_preflight_validation_v0_2R1.sql
```

Required:

```text
run_status          M1_14_ACCEPTED
passed_gates        8
scenario_count      2
baseline_count      1
stress_count        1
scenario_set_count  1
preflight_status    PASS
```

This is a hard-stop preflight. Any failed prerequisite raises an exception.

## 4. Run corrected program 110

```text
110_msbf_m1_15_latest_archive_comparison_generation_v0_2R1.sql
```

Required checkpoint:

```text
run_status             M1_15_GENERATED

contract_registry_rows 1
latest_rows            1,500
archive_rows           1,500
comparison_rows        750

applications           750
scenarios              2
canonical_entities     3,751
row_level_mismatches   0

latest_set_hash        non-null
archive_set_hash       non-null
comparison_set_hash    non-null
contract_set_hash      non-null
combined_set_hash      non-null

generation_status      PASS
```

After program 110 commits successfully, do not rerun it.

## 5. Run corrected positive validation

```text
111_msbf_m1_15_consumption_contract_validation_v0_2R1.sql
```

Required:

```text
84 checks
84 PASS
0 FAIL
run_status = M1_15_VALIDATED
```

The validation result table uses:

```sql
ON COMMIT PRESERVE ROWS
```

so the DBeaver grid remains sortable and filterable after commit within the same session.

## 6. Run negative controls

```text
112_msbf_m1_15_negative_control_tests_v0_2R1.sql
```

Required:

```text
7 controls
7 PASS
0 FAIL
run_status = M1_15_VALIDATED
```

## 7. Finalize acceptance

```text
113_msbf_m1_15_acceptance_finalize_v0_2R1.sql
```

Required:

```text
positive validations       84 / 84 PASS
negative controls            7 / 7 PASS

latest rows                       1,500
archive rows                      1,500
comparison rows                     750
canonical entities               3,751

latest hash mismatches                0
archive mismatches                    0
comparison hash mismatches            0
contract hash mismatches              0
stored canonical mismatches           0
blocking errors                       0
legacy output rows                    0

acceptance_status                  PASS
final run status         M1_15_ACCEPTED
contract status                   ACCEPTED
gate status                       PASS
```

## 8. Run final reports

```text
114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R1.sql

115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R1.sql
```

Required master result:

```text
overall_m1_15_status = PASS
```

Program 115 must produce 20 result sets. These must retain their headers and contain zero data rows:

```text
19 — Row-Level Deterministic Mismatches
20 — Blocking Resolution Errors
```

---

# Contingency-only program

Download program 110A — Generation reconciliation reconstruction (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R1_Ambiguous_Join_Downstream_Audit_Hotfix/tests/110A_msbf_m1_15_generation_reconciliation_reconstructed_v0_2R1.sql`; referenced bytes not established here)

Do not run it during the normal sequence.

Use it only when corrected program 110 commits successfully but the DBeaver result tab is lost or closed.

---

# Business-logic preservation

The hotfix does **not** change:

- the M1.15 contract fields;
- latest or archive grains;
- archive immutability;
- contract or schema version;
- scenario-matching methodology;
- source payloads or lineage payloads;
- review, fallback, or hard-stop logic;
- capacity, resilience, risk, loss, or economics values;
- worsening-indicator definitions;
- expected row counts;
- canonical entity construction;
- row- or set-hash formulas;
- 84 positive-control requirements;
- seven negative controls;
- acceptance thresholds;
- Module 1 stage boundaries.

The changes are limited to:

```text
Explicit qualified key binding
Readiness-function repair
Pristine-state strengthening
Duplicate-column prevention
Acceptance hash-field naming
Version-aligned documentation and recovery
```

# Final package QA

```text
SQL files checked                         19
Operational USING clauses                 0
Operational alias-star projections        0
Recursive prerequisite self-calls         0
Acceptance projection collisions          0
Invalid acceptance hash references        0

Positive controls                        84
Negative controls                          7
Detailed-report result sets               20

Scalar md5/FILTER defects                  0
Unsupported max(boolean) patterns          0
Session-level random() calls               0
Lexical or delimiter findings              0
Static status                            PASS

CRC validation                           PASS
Complete extraction                      PASS
Source/archive inventory match           PASS
In-archive SHA-256 reconciliation        PASS
Extracted-file SHA-256 reconciliation    PASS
Windows ZIP metadata                     PASS
ZIP64                                Not used
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-b8bbe9aa-6619-4051-8bea-7fe11a23554f"></a>
## Andrew / user · C068-M00326

C068-M00326 · 2026-07-27T17:01:59.410000-04:00 · active path

Preceding visible parent: [C068-M00325](part-25.md#m-1891fa28-e6de-4eeb-a497-bcf985786d18)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(166).png

<!-- BEGIN_SOURCE_MESSAGE -->
when trying to run 108B, I received the following warning:
<!-- END_SOURCE_MESSAGE -->


<a id="m-2bc68a82-a60c-4213-97c6-b5fa3f57d107"></a>
## Assistant · C068-M00327

C068-M00327 · 2026-07-27T17:10:17.252573-04:00 · active path

Preceding visible parent: [C068-M00326](part-25.md#m-b8bbe9aa-6619-4051-8bea-7fe11a23554f)

<!-- BEGIN_SOURCE_MESSAGE -->
Click **OK** and allow program 108B to continue.

This is a **DBeaver client-side safety warning**, not a PostgreSQL error and not evidence of a dangerous persistent-data update.

Program 108B creates this session-temporary recovery table:

```sql
CREATE TEMP TABLE _m1_15_r1_recovery
ON COMMIT PRESERVE ROWS AS
...
```

It then intentionally updates the single recovery-result row:

```sql
UPDATE _m1_15_r1_recovery
SET
    repaired_recursive_guard = ...,
    centralized_readiness_guard = ...,
    recovery_status = 'PASS';
```

DBeaver sees an `UPDATE` without a `WHERE` clause and warns automatically. It cannot infer that:

- `_m1_15_r1_recovery` is a temporary table;
- it contains the one governed recovery row;
- the update is only annotating the recovery output;
- no accepted merchant, application, contract, archive, comparison, or M1.14 business data is being changed.

## What to select

- Click **OK**
- Leave **Do not ask me again** unchecked
- Do not select **Cancel**
- Do not disable DBeaver’s dangerous-query protection globally

After the script completes, the result should include:

```text
prior_run_status                M1_14_ACCEPTED

latest_rows                     0
archive_rows                    0
comparison_rows                 0
contract_rows                   0
evidence_rows                   0
gate_rows                       0
blocking_errors                 0

repaired_recursive_guard        true
centralized_readiness_guard     true
recovery_status                 PASS
```

No hotfix is required for the current execution. The warning is caused solely by an intentional all-row update of a session-temporary one-row diagnostic table.

If **Cancel** was already selected, run:

```sql
ROLLBACK;
```

and rerun program 108B from the beginning.
<!-- END_SOURCE_MESSAGE -->


<a id="m-414cd767-ba74-4eea-909a-91c623683358"></a>
## Andrew / user · C068-M00328

C068-M00328 · 2026-07-27T17:20:10.865000-04:00 · active path

Preceding visible parent: [C068-M00327](part-25.md#m-2bc68a82-a60c-4213-97c6-b5fa3f57d107)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(167).png; 109_msbf_m1_15_preflight_validation_v0_2R1_20260727.csv; 108B_msbf_m1_15_failed_ambiguous_join_recovery_and_function_repair_v0_2R1_results_20260727.csv

<!-- BEGIN_SOURCE_MESSAGE -->
another program 110 error:
<!-- END_SOURCE_MESSAGE -->


<a id="m-07e66166-9b4c-4b51-8e88-d24c6fee575e"></a>
## Assistant · C068-M00329

C068-M00329 · 2026-07-27T17:43:18.508302-04:00 · active path

Preceding visible parent: [C068-M00328](part-25.md#m-414cd767-ba74-4eea-909a-91c623683358)

<!-- BEGIN_SOURCE_MESSAGE -->
# M1.15 diagnosis: generation-evidence `UNION` type-resolution defect

Your submitted evidence confirms the recovery and preflight stages were successful:

```text
108B recovery status          PASS
Run status                    M1_14_ACCEPTED
Latest/archive/comparison     0 / 0 / 0
Contract/evidence/gate rows   0 / 0 / 0
Readiness functions repaired  true

109 preflight status          PASS
Accepted scenarios            2
Baseline / stress             1 / 1
```

Program 110 then failed near its final generation-evidence insert with:

```text
SQLSTATE 42804
UNION types text and bigint cannot be matched
```

## Exact root cause

Program 110 attempted to insert seven evidence records through one `UNION ALL` chain.

For the first five hash-evidence rows, `metric_value_numeric` was supplied as an untyped:

```sql
NULL
```

The sixth row supplied the canonical mismatch count as:

```sql
bigint
```

PostgreSQL resolves a `UNION`’s column types before applying the destination-table types. Because the earlier branches contained only unknown `NULL` values, the intermediate numeric column resolved to `text`. When PostgreSQL later encountered the `bigint` mismatch count, it could not combine:

```text
text
with
bigint
```

This is an evidence-persistence defect. It does not indicate a problem with the latest, archive, comparison, contract, or upstream M1.14 data.

Because program 110 is transactional, the failure also means its otherwise completed M1.15 work was not committed.

---

# M1.15 v0.2R2 consolidated hotfix

Download M1.15 v0.2R2 — Typed Evidence UNION & Downstream Audit Hotfix (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
dcf0e7bbfd9b909e200a43e69123f5d58ddeb6a8a01cb7f0a295ded2fd0b7fa

Archive size
77,903 bytes

Files
31
```

Canonical long-form copy:

Download the canonical M1.15 v0.2R2 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_v0_2R2_typed_evidence_union_downstream_audit_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_v0_2R2_typed_evidence_union_downstream_audit_hotfix.zip.sha256`; referenced bytes not established here)

Both ZIPs are byte-identical.

## Key files

- 108C — Failed evidence-UNION recovery check (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/tests/108C_msbf_m1_15_failed_evidence_union_recovery_check_v0_2R2.sql`; referenced bytes not established here)
- 109 — Version-aligned hard-stop preflight (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/tests/109_msbf_m1_15_preflight_validation_v0_2R2.sql`; referenced bytes not established here)
- 110 — Corrected generation (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/sql/110_msbf_m1_15_latest_archive_comparison_generation_v0_2R2.sql`; referenced bytes not established here)
- 111 — Positive validation (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/sql/111_msbf_m1_15_consumption_contract_validation_v0_2R2.sql`; referenced bytes not established here)
- 112 — Negative controls (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/sql/112_msbf_m1_15_negative_control_tests_v0_2R2.sql`; referenced bytes not established here)
- 113 — Acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/sql/113_msbf_m1_15_acceptance_finalize_v0_2R2.sql`; referenced bytes not established here)
- 114 — Master report (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/tests/114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R2.sql`; referenced bytes not established here)
- 115 — Detailed report (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/tests/115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R2.sql`; referenced bytes not established here)
- Complete R2 execution guide (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/docs/M1_15_v0_2R2_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/docs/M1_15_v0_2R2_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# What R2 changes

## 1. Removes the mixed-type evidence `UNION`

Program 110 now creates a target-typed temporary staging table:

```sql
CREATE TEMP TABLE _m1_15_generation_evidence
(
    run_id                bigint         NOT NULL,
    evidence_code         text           NOT NULL,
    segment_key           text           NOT NULL,
    metric_name           text           NOT NULL,
    metric_value_numeric  numeric(24,10),
    metric_value_text     text,
    unit_code             text           NOT NULL,
    status                text           NOT NULL,
    interpretation        text           NOT NULL
);
```

Each evidence record is inserted separately with explicit types:

```sql
NULL::numeric(24,10)
NULL::text
row_level_mismatches::numeric(24,10)
```

The mixed `UNION` is no longer used.

## 2. Adds a typed evidence guard

Before persistent evidence is inserted, program 110 requires:

```text
Exactly seven staged evidence rows
Exactly one populated metric-value field per row
```

## 3. Audits the remaining downstream `UNION` paths

Programs 111, 113, contingency program 110A, and report program 115 were reviewed for the same defect class.

R2 explicitly types:

- canonical entity keys as `text`;
- canonical row hashes as `text`;
- the detailed-report comparison segment-key null as `NULL::text`.

## 4. Preserves business logic

The contract-building transformation is semantically equivalent to R1 after removing redundant explicit casts.

No change was made to:

- contract fields;
- latest, archive, or comparison grain;
- source or lineage payloads;
- review, fallback, or hard-stop logic;
- risk, loss, or economics values;
- worsening indicators;
- expected cardinalities;
- canonical key definitions;
- hash formulas;
- 84 positive controls;
- seven negative controls;
- acceptance thresholds;
- stage boundaries.

---

# Exact recovery and execution sequence

## 1. Stop and roll back the failed program 110

Select **Stop** in DBeaver.

Do not select:

```text
Retry
Skip
Skip All
```

Then run:

```sql
ROLLBACK;
```

Do not rerun original program 108 or v0.2R1 program 108B. The readiness-function repair already committed successfully.

## 2. Run program 108C

```text
108C_msbf_m1_15_failed_evidence_union_recovery_check_v0_2R2.sql
```

Required result:

```text
prior_run_status            M1_14_ACCEPTED

latest_rows                 0
archive_rows                0
comparison_rows             0
contract_rows               0
evidence_rows               0
gate_rows                   0
blocking_errors             0

readiness_function_exists   true
recursive_guard_removed     true
centralized_readiness_guard true

metric_value_numeric_type   numeric(24,10)
metric_value_text_type      text

recovery_status             PASS
```

Program 108C is read-only and does not contain the one-row temporary-table update that triggered the earlier DBeaver dangerous-query warning.

## 3. Run program 109

```text
109_msbf_m1_15_preflight_validation_v0_2R2.sql
```

Required:

```text
preflight_status = PASS
```

## 4. Run corrected program 110

```text
110_msbf_m1_15_latest_archive_comparison_generation_v0_2R2.sql
```

Required checkpoint:

```text
run_status             M1_15_GENERATED

contract_registry_rows 1
latest_rows            1,500
archive_rows           1,500
comparison_rows        750

applications           750
scenarios              2
canonical_entities     3,751
row_level_mismatches   0

latest_set_hash        non-null
archive_set_hash       non-null
comparison_set_hash    non-null
contract_set_hash      non-null
combined_set_hash      non-null

generation_status      PASS
```

After program 110 commits successfully, do not rerun it.

## 5. Complete the R2 sequence

```text
111_msbf_m1_15_consumption_contract_validation_v0_2R2.sql

112_msbf_m1_15_negative_control_tests_v0_2R2.sql

113_msbf_m1_15_acceptance_finalize_v0_2R2.sql

114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R2.sql

115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R2.sql
```

Required final results:

```text
Positive validations       84 / 84 PASS
Negative controls            7 / 7 PASS
Deterministic mismatches             0
Blocking errors                      0
Acceptance gate                    PASS
Run status                M1_15_ACCEPTED
Contract status                    ACCEPTED
Master report                       PASS
```

Program 115 must produce 20 result sets. These must contain headers and zero rows:

```text
19 — Row-Level Deterministic Mismatches
20 — Blocking Resolution Errors
```

## Contingency only

Program 110A — Generation reconstruction (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R2_Typed_Evidence_Union_Downstream_Audit_Hotfix/tests/110A_msbf_m1_15_generation_reconciliation_reconstructed_v0_2R2.sql`; referenced bytes not established here) is not part of the normal sequence.

Use it only if corrected program 110 commits successfully but its DBeaver result tab is lost.

---

# Package QA

The R2 package passed:

```text
SQL files checked                              19
Positive controls                              84
Negative controls                               7
Detailed-report result sets                    20

Mixed generation-evidence UNION remaining       0
Untyped generation-evidence numeric nulls       0
Canonical mismatch count without numeric cast   0
Untyped diagnostic UNION nulls                  0
Operational USING clauses                       0
Joined alias-star projections                    0
Scalar md5/FILTER defects                        0
Unsupported Boolean max/min patterns             0
Session-level random() calls                     0
SQL lexical findings                             0

CRC validation                                PASS
Complete extraction                           PASS
Source/archive inventory match                PASS
In-archive SHA-256 reconciliation             PASS
Extracted-file SHA-256 reconciliation         PASS
Windows ZIP metadata                          PASS
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-881b47b2-8df6-4eb5-a081-82259199c65f"></a>
## Andrew / user · C068-M00330

C068-M00330 · 2026-07-27T18:00:53.414000-04:00 · active path

Preceding visible parent: [C068-M00329](part-25.md#m-07e66166-9b4c-4b51-8e88-d24c6fee575e)

**Editorial record note:** Attachment references: 109_msbf_m1_15_preflight_validation_v0_2R2_results_20260727.csv; 108C_msbf_m1_15_failed_evidence_union_recovery_check_v0_2R2_results_20260727.csv; 111_msbf_m1_15_consumption_contract_validation_v0_2R2_results_20260727.csv; 110_msbf_m1_15_latest_archive_comparison_generation_v0_2R2_results_20260727.csv

<!-- BEGIN_SOURCE_MESSAGE -->
one positive test fail: M1_15_POS_62_RESILIENCE_NONIMPROVEMENT
<!-- END_SOURCE_MESSAGE -->


<a id="m-e8b36414-4bd0-4959-9efa-f6809387657e"></a>
## Assistant · C068-M00331

C068-M00331 · 2026-07-27T18:22:53.425495-04:00 · active path

Preceding visible parent: [C068-M00330](part-25.md#m-881b47b2-8df6-4eb5-a081-82259199c65f)

<!-- BEGIN_SOURCE_MESSAGE -->
# M1.15 diagnosis: **generation passed; POS62 is a validation-specification defect**

The submitted evidence shows:

```text
Program 110 generation             PASS
Contract registry rows                1
Latest rows                        1,500
Archive rows                       1,500
Comparison rows                      750
Canonical entities                 3,751
Generation mismatches                  0

Program 111 validation             83 / 84 PASS
Sole failed control:
M1_15_POS_62_RESILIENCE_NONIMPROVEMENT

Reported apparent improvements          1
```

Every other M1.15 control passed, including:

- exact M1.11 resilience reproduction;
- resilience-score delta reconciliation;
- resilience-worsening-flag identity;
- capacity, integrated-risk, LGD, contribution, return, and economic-tier non-improvement;
- latest, archive, comparison, contract, and combined hashes;
- all physical row-hash controls.

**Do not rerun program 110 or alter the generated M1.15 records.**

## Root cause

The original POS62 control required both:

```text
No stress resilience-tier improvement
and
No continuous resilience-score increase
```

That is stricter than the formally accepted **M1.11 contract**.

Accepted M1.11 applies adverse-scenario floors to:

```text
Final resilience tier
Final archetype risk rank
```

It does **not** floor the continuous operating-resilience score. The score remains transparent descriptive evidence. A stress score may move slightly upward while the governed tier and archetype interpretation remain unchanged or worse.

The one M1.15 finding is therefore not a bad generated row. It is a valid accepted M1.11 score movement that the M1.15 validation incorrectly treated as prohibited.

The corrected POS62 requires zero:

```text
Stress resilience-tier improvements
Stress archetype-risk-rank improvements
```

It continues to report the continuous score-increase count as a **non-blocking diagnostic**.

Expected corrected evidence:

```text
tier=0
archetype=0
score_increases_diagnostic=1
status=PASS
```

This does not hide or overwrite the score movement.

---

# M1.15 v0.2R3 hotfix

## Recommended download

Download M1.15 v0.2R3 — Resilience Contract Alignment Hotfix (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix.zip`; referenced bytes not established here)

Download the ZIP SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
90e40a6156a39c74bacb3e69c6acccb406f2bb7b423902ac5e5f15b0ad5b28b4

Archive size
70,815 bytes

Files
29
```

Canonical long-form copy:

Download the canonical M1.15 v0.2R3 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_v0_2R3_resilience_contract_alignment_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_15_v0_2R3_resilience_contract_alignment_hotfix.zip.sha256`; referenced bytes not established here)

The two ZIPs are byte-identical.

## Key programs

- 108D — Governed recovery and audit-history preservation (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/tests/108D_msbf_m1_15_failed_resilience_nonimprovement_validation_recovery_v0_2R3.sql`; referenced bytes not established here)
- 111 — Corrected positive validation (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/sql/111_msbf_m1_15_consumption_contract_validation_v0_2R3.sql`; referenced bytes not established here)
- 112 — Negative controls (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/sql/112_msbf_m1_15_negative_control_tests_v0_2R3.sql`; referenced bytes not established here)
- 113 — Acceptance finalizer (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/sql/113_msbf_m1_15_acceptance_finalize_v0_2R3.sql`; referenced bytes not established here)
- 114 — Master report (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/tests/114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R3.sql`; referenced bytes not established here)
- 115 — Detailed report (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/tests/115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3.sql`; referenced bytes not established here)

## Supporting records

- Execution guide (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/docs/M1_15_v0_2R3_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and logic-alignment review (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/docs/M1_15_v0_2R3_ROOT_CAUSE_AND_LOGIC_ALIGNMENT.md`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/_build_m115_r3/MSBF_M1_15_v0_2R3_Resilience_Contract_Alignment_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Machine-readable delivery validation (historical reference: `sandbox:[session]/MSBF_M1_15_v0_2R3_DELIVERY_VALIDATION.json`; referenced bytes not established here)

---

# Exact execution sequence

Do **not** rerun:

```text
108
108B
108C
109
110
```

The v0.2R2 generation is committed, reconciled, and authoritative.

## 1. Run program 108D

```text
108D_msbf_m1_15_failed_resilience_nonimprovement_validation_recovery_v0_2R3.sql
```

The program verifies the exact live state before changing anything:

```text
Prior run status                  M1_15_FAILED
Prior contract status             GENERATED

Positive controls                 84
Positive passes                   83
Positive failures                  1
Failed code:
M1_15_POS_62_RESILIENCE_NONIMPROVEMENT

Reported POS62 value                1
Continuous score increases          1
Tier improvements                   0
Archetype improvements              0

Latest rows                     1,500
Archive rows                    1,500
Comparison rows                   750
Canonical entities              3,751

Latest hash mismatches               0
Archive mismatches                   0
Comparison hash mismatches           0
Combined hash reconciliation       PASS

Negative evidence rows               0
M1.15 gate rows                      0
Blocking errors                      0
```

It also verifies the two accepted M1.11 non-improvement controls:

```text
M1_11_POS_45_STRESS_TIER_NONIMPROVEMENT
M1_11_POS_48_STRESS_ARCHETYPE_NONIMPROVEMENT
```

The original POS62 finding is retained as superseded historical evidence. No latest, archive, comparison, contract, source, hash, or upstream business record is changed.

Required final fields:

```text
final_run_status                 M1_15_GENERATED
final_contract_status            GENERATED
remaining_positive_evidence_rows 0
preserved_history_rows           1
recovery_status                  PASS
```

Stop if `recovery_status` is not `PASS`.

## 2. Run corrected program 111

```text
111_msbf_m1_15_consumption_contract_validation_v0_2R3.sql
```

Required:

```text
84 checks
84 PASS
0 FAIL
run_status = M1_15_VALIDATED
```

POS62 should show:

```text
observed_value:
tier=0|archetype=0|score_increases_diagnostic=1

status:
PASS
```

The validation result table uses:

```sql
ON COMMIT PRESERVE ROWS
```

so it remains sortable and filterable after commit within the same DBeaver session.

## 3. Run negative controls

```text
112_msbf_m1_15_negative_control_tests_v0_2R3.sql
```

Required:

```text
7 / 7 PASS
run_status = M1_15_VALIDATED
```

## 4. Finalize acceptance

```text
113_msbf_m1_15_acceptance_finalize_v0_2R3.sql
```

Required:

```text
Positive validations       84 / 84 PASS
Negative controls            7 / 7 PASS

Latest rows                       1,500
Archive rows                      1,500
Comparison rows                     750
Canonical entities               3,751

Latest hash mismatches                0
Archive mismatches                    0
Comparison mismatches                 0
Contract hash mismatches              0
Stored canonical mismatches           0
Blocking errors                       0

acceptance_status                  PASS
final run status         M1_15_ACCEPTED
contract status                   ACCEPTED
gate status                       PASS
```

## 5. Run final reports

```text
114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R3.sql

115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3.sql
```

Required master result:

```text
overall_m1_15_status = PASS
```

Program 115 should produce 20 result sets. These must contain headers and zero data rows:

```text
19 — Row-Level Deterministic Mismatches
20 — Blocking Resolution Errors
```

---

# Logic and data preservation

The hotfix does not modify:

- the 1,500 latest rows;
- the 1,500 immutable archive rows;
- the 750 matched comparison rows;
- the contract-registry row;
- any contract payload;
- any source or lineage payload;
- any M1.11 score;
- any resilience tier or archetype;
- any review, fallback, or hard-stop result;
- any row hash or set hash;
- any generation cardinality;
- any M1.15 contract field;
- any upstream accepted record.

Programs 112–115 are executable-logic equivalent to v0.2R2 after revision comments are removed. Only program 111’s POS62 specification and supporting archetype-pair materialization changed.

## Package QA

```text
Positive controls                         84
POS62 evidence-code occurrences            1
Legacy score-blocking POS62 expressions    0
Archetype-pair validation                Present
Continuous-score diagnostic             Present
Unchanged downstream programs equivalent  PASS
Session random() calls                     0
Scalar md5/FILTER defects                  0

CRC validation                            PASS
Complete extraction                       PASS
Source/archive inventory match            PASS
In-archive SHA-256 reconciliation         PASS
Extracted-file SHA-256 reconciliation     PASS
Windows ZIP metadata                      PASS
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-91365db4-2c09-485d-b5bb-cd7b76bf62c6"></a>
## Andrew / user · C068-M00332

C068-M00332 · 2026-07-27T18:52:40.110000-04:00 · active path

Preceding visible parent: [C068-M00331](part-25.md#m-e8b36414-4bd0-4959-9efa-f6809387657e)

**Editorial record note:** Attachment references: 113_msbf_m1_15_acceptance_finalize_v0_2R3_results_20260727.csv; 112_msbf_m1_15_negative_control_tests_v0_2R3_results_20260727.csv; 111_msbf_m1_15_consumption_contract_validation_v0_2R3_results_20260727.csv; 108D_msbf_m1_15_failed_resilience_nonimprovement_validation_recovery_v0_2R3_results_20260727.csv; 111_msbf_m1_15_consumption_contract_validation_v0_2R2_results_20260727(1).csv; 110_msbf_m1_15_latest_archive_comparison_generation_v0_2R2_results_20260727(1).csv; 109_msbf_m1_15_preflight_validation_v0_2R2_results_20260727(1).csv; 108C_msbf_m1_15_failed_evidence_union_recovery_check_v0_2R2_results_20260727(1).csv; 109_msbf_m1_15_preflight_validation_v0_2R1_20260727(1).csv; 108B_msbf_m1_15_failed_ambiguous_join_recovery_and_function_repair_v0_2R1_results_20260727(1).csv; 109_msbf_m1_15_preflight_validation_v0_2_results_20260727(1).csv; 108_msbf_m1_15_schema_policy_contract_extension_v0_2_results_20260727(1).csv; MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R3_20260727.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Here is the batch 1 of 2 for M1.15 execution evidence. Do not do anything but intake at this point until after I issue batch 2 of 2 and further instructions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-db10cbd8-3da3-4618-9e8a-6d363d21e5be"></a>
## Assistant · C068-M00333

C068-M00333 · 2026-07-27T18:53:30.637450-04:00 · active path

Preceding visible parent: [C068-M00332](part-25.md#m-91365db4-2c09-485d-b5bb-cd7b76bf62c6)

<!-- BEGIN_SOURCE_MESSAGE -->
Received batch 1 of 2 for the M1.15 execution evidence, including:

- Original v0.2 schema and policy/contract extension
- Original v0.2 preflight
- v0.2R1 recovery/function-repair evidence
- v0.2R1 preflight
- v0.2R2 recovery evidence
- v0.2R2 corrected preflight
- v0.2R2 successful generation
- v0.2R2 initial 83-of-84 positive-validation result
- v0.2R3 governed recovery from the POS62 validation finding
- v0.2R3 final positive validation
- v0.2R3 negative controls
- v0.2R3 acceptance finalizer
- v0.2R3 master report

I will not analyze the evidence, determine M1.15 acceptance, or update the project repository until you provide batch 2 of 2 and further instructions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5bf4fab3-1242-4cc0-923d-342df4994a21"></a>
## Andrew / user · C068-M00334

C068-M00334 · 2026-07-27T19:04:11.308000-04:00 · active path

Preceding visible parent: [C068-M00333](part-25.md#m-db10cbd8-3da3-4618-9e8a-6d363d21e5be)

**Editorial record note:** Attachment references: MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Comparison_Evidence_Status_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Matched_Worsening_Indicators_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Matched_Scenario_Delta_Summary_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Unit_Economics_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Exposure_Recovery_LGD_And_Comparative_Loss_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Integrated_Risk_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Archetype_And_Operating_Resilience_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Capacity_And_Affordability_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Cash_Flow_And_Liquidity_Summary_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Data_Confidence_And_Verification_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Contract_Evidence_Review_And_Hard_Stop_Distribution_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Scenario_Distribution_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Entity_And_Contract_Cardinality_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Run_And_Acceptance_State_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Blocking_Resolution_Errors_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Row_Level_Deterministic_Mismatches_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Governed_M1_15_Evidence_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Sample_Matched_Application_Contracts_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Industry_Diagnostics_20260727.csv; MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3_Partner_And_Channel_Diagnostics_20260727.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Remainder of M1.15 evidence. Validate M1.15 is a success. If it is approved, sign off M1.15 and update full project zip.
<!-- END_SOURCE_MESSAGE -->
