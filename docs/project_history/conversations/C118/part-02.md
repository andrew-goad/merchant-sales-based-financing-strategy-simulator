# MSBF - Power BI Executive Portfolio Intelligence Part 3

Part 02 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-01.md)
[Next part](part-03.md)

<a id="m-a34d4b6e-6697-4227-8393-e2e4fab6f7b4"></a>
## Assistant · C118-M00023

C118-M00023 · 2026-09-03T11:36:40.733296-04:00 · active path

Preceding visible parent: [C118-M00022](part-01.md#m-640fb85a-32b0-4868-8acf-8fc5405e06b9)

<!-- BEGIN_SOURCE_MESSAGE -->
# Canonical recovery complete

**Disposition:** `CANONICAL_CURRENT_IMPLEMENTATION_REGISTER_ESTABLISHED`  
**Effective source of truth:** `MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903`  
**Current working project:** `MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902`  
**C3 required for current P03 work:** `NO`  
**Public supersession/publication:** `NOT AUTHORIZED`

The recovery is complete. The new register is designed to prevent exactly the failure you identified: it no longer treats a familiar visual label or likely source field as a substitute for the exact measure we already built.

R26 remains the accepted technical M2.5–M2.12/G3-v2 successor, Power BI integration remains authorized, and public supersession and publication remain outside the present authority. [export reference: filecite | turn37file9 | L818-L830]

## What is now controlled

### 1. Exact physical C1 baseline

I physically ingested and parsed the full C1 semantic model and report definition rather than relying on screenshots or summaries.

The baseline register contains:

```text
Tables                    54
Columns                1,781
Measures                 262
Relationships             54
Report pages                7
Visual containers         132
Parsed visual bindings    266
```

It includes the exact C1:

- `model.bim`;
- table, column, measure, partition, and relationship inventories;
- page and visual inventories;
- visual field-well and tooltip bindings;
- 33 predecessor P03 measure definitions with their complete DAX;
- model and report file hashes.

C1 is now explicitly classified as the **physical predecessor baseline**. It is not silently treated as current C2 authority.

### 2. Current C2 implementation overlay

The register overlays the physical C1 baseline with the current facts established after C1:

- `R1FactFundedLifecycle` added at 130 unique application-scenario rows;
- `R1FactDailyMonitoring` preserved at 15,600 rows and 47 columns;
- exact application-scenario lifecycle gating;
- current R26 P03 presentation measures;
- Editorial R3/Patch 3 installed;
- strengthened QA R1 preserved;
- post-Patch-3 QA at 2 / 0 / 1,500, all PASS;
- C2 retained as the current project;
- no C3;
- narrative rewriting complete;
- P03 page finalization still in progress.

The Part 3 source material itself identifies the accepted 47-column monitoring fact, separate 130-row lifecycle architecture, completed 2 / 0 / 1,500 QA, and remaining P03 controls. [export reference: filecite | turn37file1 | L72-L101]

### 3. Exact P03 measure register

The canonical P03 register now contains:

```text
Current P03 measure identities registered     46
Exact current expressions recovered           27
Partial expressions recovered                  1
Live-C2 expression/identity attestation gates 19
```

Most importantly, your example is now explicitly registered as an exact, owner-confirmed current measure—not merely inferred from its source field:

```DAX
R26 P03 Remaining Receivable =
    MAX (
        'R1FactDailyMonitoring'[receivable_balance_after]
    )
```

The same register distinguishes among:

- exact current, owner-confirmed formulas;
- exact formulas from controlling installed DAX;
- exact formulas recovered from the prior implementation sequence;
- current measure names proven by physical screenshots;
- current measure references proven by another exact measure;
- partial formulas;
- unresolved live-C2 expressions;
- predecessor-only measures;
- superseded or prohibited objects.

The controlling narrative layer is also carried in full: five helpers, three visible narratives, three exact technical-rationale measures, accessibility, QA status, and QA detail. That architecture preserves executive wording while retaining exact source explanations. [export reference: filecite | turn76file2 | L314-L387]

### 4. Current visual and tooltip binding register

The register does not stop at measures. It separately inventories the P03 visual bindings, including tooltips.

It contains 45 current P03 section/binding rows covering:

- Merchant and Scenario selectors;
- merchant profile and request;
- decision tile;
- proposed structure;
- the three narrative areas;
- Account performance;
- Monitoring journey;
- Servicing & intervention;
- Technical rationale tooltip;
- footer identity;
- accessibility and tab order.

For the operational visuals, it preserves the physically demonstrated field-well composition:

**Account performance**

```text
X-axis                 monitoring_date
Y-axis                 R26 P03 Remaining Receivable
Secondary Y-axis       R26 P03 Remittance Pace

Tooltips:
Monitoring status
Remitted to date
Expected to date
Cumulative shortfall
```

The prior physical field-well evidence confirms the date, receivable, pace, and monitoring-status composition. [export reference: filecite | turn29file2 | L44-L57]

**Monitoring journey**

```text
X-axis                 monitoring_date
Y-axis                 R26 P03 Monitoring Status Rank

Tooltips:
Monitoring status
Reason
Remittance pace
Daily shortfall
Cumulative shortfall
Days since remittance
```

The prior physical field-well evidence confirms the status-rank axis and P03 monitoring tooltip layer. [export reference: filecite | turn29file0 | L10-L17]

**Servicing & intervention**

```text
Intervention
Action
Queue
Exposure
Reason
```

The register keeps M2.6 intervention recommendation distinct from M2.7 operational setup, M2.8 servicing execution, M2.9 certification, and M2.10 endpoint performance. That separation is an explicit handoff control, not a cosmetic preference. [export reference: filecite | turn22file6 | L573-L617]

## The controlled remaining limitation

The physical C2 PBIP working tree was not included in the Part 3 handoff. Therefore, I have **not** claimed exact current C2 totals, report-object hashes, visual IDs, or formulas where the physical evidence does not support them.

Instead, the register identifies 19 bounded live-C2 attestation items. Examples include:

- the exact current backing for **Expected to date**;
- Monitoring Journey **Reason**, **Daily shortfall**, and **Days since remittance**;
- Servicing & Intervention **Action** and **Queue**;
- current formulas for several presentation and conditional-formatting measures;
- exact current C2 visual IDs and report-definition hashes.

These are not presented as design gaps or invitations to rebuild anything. They are explicitly marked:

```text
DO NOT INFER
DO NOT SUBSTITUTE A RAW FIELD
DO NOT RESURRECT A PREDECESSOR MEASURE
CAPTURE THE LIVE C2 OBJECT BEFORE CHANGING IT
```

The package includes a read-only PowerShell capture script and DAX metadata queries to close those physical gates efficiently when needed. This lets us continue immediately wherever the current definition is exact while failing closed wherever the definition is not yet physically established.

## Governing operating method from this point forward

For every remaining Power BI change:

1. Consult the canonical measure and visual-binding registers.
2. When the object is marked exact current, preserve and use that exact implementation.
3. When it is marked unresolved or partial, capture the live C2 expression or binding before advising a change.
4. Treat C1 objects as lineage unless the current register expressly retains them.
5. Treat withdrawn R4, superseded Patch 2, old QA queries, the C3 assumption, and predecessor-only bindings as do-not-use.
6. Update this register through a versioned successor—never by silently replacing evidence.

The register therefore controls both **what is known** and **what must not be assumed**. That is what makes it a defensible source of truth despite the missing physical C2 tree.

## Workbook

The primary workbook contains 18 structured sheets:

- Executive State
- Page Roadmap
- Source Objects
- P03 Current Measures
- P03 Visual Bindings
- P03 C1 Predecessor
- C1 Tables
- C1 Columns
- C1 Measures
- C1 Relationships
- C1 Pages
- C1 Visuals
- C1 Bindings
- C1-to-C2 Delta
- Open Gates
- Do Not Use
- Evidence
- Precedence

The workbook was validated for structural integrity and returned no spreadsheet formula errors.

## Package validation

```text
Package
MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903.zip

Bytes
1,736,049

SHA-256
c89dfdcc34e3687419dc6ba86b2cb8993ac3aa07697a4b376f0841133614c6b6

ZIP entries
89

Payload manifest rows
86

SHA256SUMS rows
87

ZIP CRC
PASS

Clean extraction
PASS

Manifest reconciliation
PASS

SHA256SUMS reconciliation
PASS

Unsafe paths
0

Duplicate paths
0

Case-fold collisions
0

Symlinks
0

Encrypted entries
0

Overall
PASS
```

## Primary deliverables

Download the complete canonical implementation package (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903.zip`; referenced bytes not established here)

Download the package SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903.zip.sha256`; referenced bytes not established here)

Open the canonical Excel implementation register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903.xlsx`; referenced bytes not established here)

Open the package start guide (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/00_START_HERE.md`; referenced bytes not established here)

Open the mandatory pre-change operating rules (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/01_READ_BEFORE_ANY_POWER_BI_CHANGE.md`; referenced bytes not established here)

Open the machine-readable canonical current state (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/CANONICAL_CURRENT_STATE.json`; referenced bytes not established here)

## Core implementation registers

Open the current P03 measure register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/registers/P03_CURRENT_MEASURE_REGISTER.csv`; referenced bytes not established here)

Open the current P03 visual and tooltip binding register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/registers/P03_CURRENT_VISUAL_BINDING_REGISTER.csv`; referenced bytes not established here)

Open the exact physical C1 predecessor P03 measure register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/registers/P03_PREDECESSOR_C1_MEASURE_REGISTER.csv`; referenced bytes not established here)

Open the current successor-source object register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/registers/CURRENT_SUCCESSOR_SOURCE_OBJECTS.csv`; referenced bytes not established here)

Open the C1-to-C2 implementation-delta register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/registers/C1_TO_C2_IMPLEMENTATION_DELTA.csv`; referenced bytes not established here)

Open the open physical and completion gates (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/registers/OPEN_PHYSICAL_AND_COMPLETION_GATES.csv`; referenced bytes not established here)

Open the deprecated and do-not-use register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/registers/DEPRECATED_AND_DO_NOT_USE.csv`; referenced bytes not established here)

## Physical-attestation controls

Open the live C2 physical-attestation protocol (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/scripts/LIVE_C2_PHYSICAL_ATTESTATION_PROTOCOL.md`; referenced bytes not established here)

Download the read-only local C2 PBIP capture script (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/scripts/CAPTURE_LOCAL_C2_PBIP_TREE.ps1`; referenced bytes not established here)

Open the live C2 semantic-state capture query (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/dax/CAPTURE_LIVE_C2_SEMANTIC_IMPLEMENTATION_STATE.dax`; referenced bytes not established here)

## Validation

Open the ZIP validation report (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903_ZIP_VALIDATION_REPORT.md`; referenced bytes not established here)

Open the machine-readable ZIP validation report (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903_ZIP_VALIDATION_REPORT.json`; referenced bytes not established here)

This register now controls the remaining P03–P06 work and the eventual integration-audit preparation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-42d112d2-4113-4acb-9a03-8abf345620dd"></a>
## Andrew / user · C118-M00024

C118-M00024 · 2026-09-03T12:14:44.240000-04:00 · active path

Preceding visible parent: [C118-M00023](part-02.md#m-a34d4b6e-6697-4227-8393-e2e4fab6f7b4)

<!-- BEGIN_SOURCE_MESSAGE -->
Thanks. Now please provide detailed instructions for completing P03 account performance / monitoring journey / servicing & intervention displays using our established governing operating method.
<!-- END_SOURCE_MESSAGE -->


<a id="m-526150d4-df6a-4f94-b191-9248bfdb575f"></a>
## Assistant · C118-M00025

C118-M00025 · 2026-09-03T12:15:36.520242-04:00 · active path

Preceding visible parent: [C118-M00024](part-02.md#m-42d112d2-4113-4acb-9a03-8abf345620dd)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The three right-side P03 displays can now be completed in a controlled way without redesigning them or reconstructing semantics from memory.

The governing rule is: **preserve every exact-current object we already know, physically attest every unresolved C2 object before touching it, and modify only the intended report binding or presentation object.** A display label is not a formula, a source column is not automatically the report binding, and tooltips are first-class bindings. [export reference: filecite | turn41file0 | L11-L41]

The current working project remains **`MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902`**. C3 is not required. R26 integration is authorized, but publication/public supersession is not. [export reference: filecite | turn41file4 | L1154-L1172]

## Exact target architecture

Before the step-by-step instructions, this is the configuration we are trying to preserve and finish.

| Display | Role | Current controlling binding |
|---|---|---|
| **Account performance** | X-axis | `R1FactDailyMonitoring[monitoring_date]` |
|  | Y-axis | `[R26 P03 Remaining Receivable]` |
|  | Secondary Y-axis | `[R26 P03 Remittance Pace]` |
|  | Tooltip 1 | `[R26 P03 Monitoring Status Display]` |
|  | Tooltip 2 | `[R26 P03 Remitted To Date]` |
|  | Tooltip 3 | **current C2 backing must be captured** — display label `Expected to date` |
|  | Tooltip 4 | `[R26 P03 Cumulative Shortfall]` |
| **Monitoring journey** | X-axis | `R1FactDailyMonitoring[monitoring_date]` |
|  | Y-axis | `[R26 P03 Monitoring Status Rank]` — **capture expression before editing** |
|  | Tooltip 1 | `[R26 P03 Monitoring Status Display]` |
|  | Tooltip 2 | **capture current C2 `Reason` backing** |
|  | Tooltip 3 | `[R26 P03 Remittance Pace]` |
|  | Tooltip 4 | **capture current C2 `Daily shortfall` backing** |
|  | Tooltip 5 | `[R26 P03 Cumulative Shortfall]` |
|  | Tooltip 6 | **capture current C2 `Days since remittance` backing** |
| **Servicing & intervention** | Column 1 | `[R26 P03 Intervention Display]` |
|  | Column 2 | **capture current C2 `Action` backing** |
|  | Column 3 | **capture current C2 `Queue` backing** |
|  | Column 4 | `[R26 P03 Intervention Exposure]` — measure name known, expression must be captured before editing |
|  | Column 5 | `[R26 P03 Intervention Reason Display]` — measure name known, expression must be captured before editing |

That mapping is now part of the canonical register. [export reference: filecite | turn41file1 | L63-L70] [export reference: filecite | turn41file1 | L79-L86] [export reference: filecite | turn41file1 | L103-L108]

## 1. Start with the mandatory read-only C2 attestation

Do **not** begin by changing the visuals. Seven pieces of these three displays remain physically unresolved, and the register expressly requires us to identify them before editing. The open gates are Account Performance `Expected to date`; Monitoring Journey `Reason`, `Daily shortfall`, and `Days since remittance`; and Servicing `Action` and `Queue`, plus the unresolved current formulas for several named presentation measures. [export reference: filecite | turn41file3 | L1131-L1137]

First, save the current C2 PBIP normally.

Then locate the exact root folder for:

```text
MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902
```

It should be the folder containing the PBIP project and its `.Report` / `.SemanticModel` folders. Do **not** point the capture script at C1 or at a ZIP.

Download/use the existing read-only capture script:

Open the C2 physical-attestation PowerShell script (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/scripts/CAPTURE_LOCAL_C2_PBIP_TREE.ps1`; referenced bytes not established here)

In PowerShell, run:

```powershell
.\CAPTURE_LOCAL_C2_PBIP_TREE.ps1 `
  -ProjectRoot "C:\<YOUR EXACT PATH>\MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902"
```

The script does not modify the PBIP. It inventories and hashes the tree, copies `model.bim` and the report definition, and exports tables, columns, measures, relationships, a capture receipt, a ZIP, and a SHA-256 sidecar. [export reference: filecite | turn42file2 | L534-L569] [export reference: filecite | turn42file2 | L606-L655]

Next, in the **same open C2 project**, go to **DAX Query View** and use:

Open the live C2 semantic-state capture query (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R1_20260903/dax/CAPTURE_LIVE_C2_SEMANTIC_IMPLEMENTATION_STATE.dax`; referenced bytes not established here)

Paste/run it using **Run only**.

Do **not** click **Update model with changes**.

It reads:

```DAX
EVALUATE INFO.VIEW.TABLES()

EVALUATE INFO.VIEW.COLUMNS()

EVALUATE INFO.VIEW.MEASURES()

EVALUATE INFO.VIEW.RELATIONSHIPS()
```

Export every result set. This is the canonical attestation protocol: save C2, capture the physical tree, run the semantic inventory read-only, export it, reconcile the unknowns, and only then edit an unresolved object. [export reference: filecite | turn42file1 | L510-L522] [export reference: filecite | turn42file3 | L667-L677]

**At this point, I recommend giving me the generated attestation ZIP.** I can reconcile the unresolved bindings against the canonical register in one pass. That is preferable to manually interpreting `visual.json` and measure-expression inventory yourself.

If you want to proceed manually, the rule is simple: whatever current C2 physically says controls. Do not recreate a measure merely because we know what source field it probably uses.

---

## 2. Complete **Account performance**

This display is almost entirely recovered already. Only **Expected to date** remains unresolved.

Select **P03 - Application Journey**, then select the existing **Account performance** visual. Do not delete it and create a new visual; the existing object carries formatting, position, size, and report behavior we want to preserve.

In **Visualizations → Build visual**, reconcile the field wells exactly to:

| Field well | Required object |
|---|---|
| X-axis | `R1FactDailyMonitoring[monitoring_date]` |
| Y-axis | `R1Measures[R26 P03 Remaining Receivable]` |
| Secondary Y-axis | `R1Measures[R26 P03 Remittance Pace]` |
| Tooltip | `R26 P03 Monitoring Status Display` |
| Tooltip | `R26 P03 Remitted To Date` |
| Tooltip | **exact live-C2 backing currently displayed as `Expected to date`** |
| Tooltip | `R26 P03 Cumulative Shortfall` |

The key distinction is important: **do not put `receivable_balance_after` directly into the Y-axis.** The exact controlling measure is:

```DAX
R26 P03 Remaining Receivable =
MAX (
    'R1FactDailyMonitoring'[receivable_balance_after]
)
```

That exact current C2 measure is owner-confirmed in the canonical register. [export reference: filecite | turn41file2 | L843-L847]

Likewise, use the measures—not their raw source columns—for the other bindings:

```DAX
R26 P03 Remittance Pace =
MAX ( 'R1FactDailyMonitoring'[cumulative_pace_ratio] )

R26 P03 Remitted To Date =
MAX ( 'R1FactDailyMonitoring'[cumulative_remittance_amount] )

R26 P03 Cumulative Shortfall =
MAX ( 'R1FactDailyMonitoring'[cumulative_shortfall_amount] )
```

Those are recovered exact-current C2 implementations. [export reference: filecite | turn41file2 | L150-L151] [export reference: filecite | turn41file2 | L843-L847]

For Monitoring status, preserve:

```DAX
R26 P03 Monitoring Status Display =
SWITCH (
    SELECTEDVALUE ( 'R1FactDailyMonitoring'[monitoring_status_code] ),
    "PAID_OFF", "Paid off",
    "CURRENT", "Current",
    "WATCH", "Watch",
    "UNDERPERFORMING", "Underperforming",
    "SEVERE_SHORTFALL", "Severe shortfall",
    "DORMANT_NO_REMITTANCE", "Dormant / no remittance",
    BLANK ()
)
```

[export reference: filecite | turn41file2 | L540-L549]

For **Expected to date**, do not type a formula and do not drag a likely cumulative-expected column into the tooltip. The current C2 report definition must identify the binding. The register specifically notes that the C1 predecessor used `P03 Cumulative Expected Remittance`, but that predecessor identity is **not permission to resurrect it**. [export reference: filecite | turn41file1 | L64-L70]

### Account-performance title/subtitle

Keep the visible heading:

```text
Account performance
```

Preserve the current subtitle carrier and bind it to:

```DAX
R26 P03 Account Performance Subtitle =
IF (
    [R26 P03 Funded Lifecycle Available] = 1,
    "Funded synthetic account • deterministic synthetic-forward",
    "No funded-account lifecycle for this application-scenario"
)
```

[export reference: filecite | turn41file2 | L123-L127]

Do not redesign the subtitle carrier merely to make it dynamic. If the current C2 page uses a separate card/text carrier, keep it. If it already uses conditional subtitle text, keep that. We are correcting semantics, not redesigning the page architecture.

### Account-performance visual behavior

Preserve the existing visual type and formatting. The desired semantic story is:

```text
receivable balance over monitoring date
+
cumulative remittance pace on the secondary scale
```

Do not add:

```text
legend
small multiples
raw status categories
alert-family fields
operational intervention fields
```

Those are not part of this visual's controlled field well.

Sort chronologically by `monitoring_date`.

Do not force data into a nonfunded scenario. A nonfunded application-scenario should naturally have no funded monitoring lifecycle; the subtitle makes that distinction explicit.

---

## 3. Complete **Monitoring journey**

Select the existing **Monitoring journey** visual.

Do not recreate it.

The controlled structure is:

| Field well | Required object |
|---|---|
| X-axis | `R1FactDailyMonitoring[monitoring_date]` |
| Y-axis | `[R26 P03 Monitoring Status Rank]` |
| Tooltip 1 | `[R26 P03 Monitoring Status Display]` |
| Tooltip 2 | **captured current C2 Reason binding** |
| Tooltip 3 | `[R26 P03 Remittance Pace]` |
| Tooltip 4 | **captured current C2 Daily shortfall binding** |
| Tooltip 5 | `[R26 P03 Cumulative Shortfall]` |
| Tooltip 6 | **captured current C2 Days since remittance binding** |

[export reference: filecite | turn41file1 | L79-L86]

### Do not touch Monitoring Status Rank until attested

This is particularly important.

`R26 P03 Monitoring Status Rank` physically exists in C2, and the current visual is known to use it, but its exact DAX expression has **not** yet been recovered. The register therefore marks it `NAME_CONFIRMED_FORMULA_NOT_RECOVERED`. [export reference: filecite | turn41file2 | L535-L550]

So:

```text
Do not replace it with SWITCH().
Do not derive a rank from monitoring_status_code yourself.
Do not copy the C1 formula.
Do not create "R26 P03 Monitoring Status Rank 2".
```

The live C2 semantic inventory should give us its exact expression.

The same fail-closed rule applies to the three unresolved tooltips:

```text
Reason
Daily shortfall
Days since remittance
```

Even though their meanings are obvious, their **current report objects are not yet physically attested**. [export reference: filecite | turn41file1 | L80-L86]

### Monitoring Journey subtitle

Preserve/bind the existing subtitle carrier to:

```DAX
R26 P03 Monitoring Journey Subtitle =
IF (
    [R26 P03 Funded Lifecycle Available] = 1,
    "Governed monitoring status across the funded-account lifecycle",
    "No funded-account monitoring path for this application-scenario"
)
```

[export reference: filecite | turn41file2 | L535-L539]

### Axis presentation

Do not change the semantic ordering of the status axis.

The existing page visually communicates a progression such as:

```text
Paid off
Current
Watch
Underperforming
Severe shortfall
```

But because the exact current rank measure is one of the open physical gates—and because the source also recognizes `DORMANT_NO_REMITTANCE`—we should **not manually rebuild or hard-code the rank scale before reading C2's current formula**.

Once that formula is physically captured, preserve its exact rank semantics and only improve labels/formatting if they do not alter those semantics.

Sort X-axis by `monitoring_date` ascending.

No legend or small multiples should be added unless the physical C2 definition proves they are already intentional.

---

## 4. Complete **Servicing & intervention**

This table is the area where it would be easiest to accidentally mix different stages of the M2.6–M2.10 chain, so keep the boundary tight.

Select the existing **Servicing & intervention** table.

Its final visible order is:

```text
Intervention | Action | Queue | Exposure | Reason
```

The required object mapping is:

| Column | Current target |
|---|---|
| Intervention | `[R26 P03 Intervention Display]` |
| Action | **live-C2 attested current backing** |
| Queue | **live-C2 attested current backing** |
| Exposure | `[R26 P03 Intervention Exposure]` |
| Reason | `[R26 P03 Intervention Reason Display]` |

[export reference: filecite | turn41file1 | L103-L108]

### Intervention is already exact

Preserve the existing measure:

```DAX
R26 P03 Intervention Display =
VAR _Code =
    SELECTEDVALUE ( 'R1FactIntervention'[strategy_outcome_code] )
RETURN
    SWITCH (
        _Code,
        "CLOSED_NO_FURTHER_ACTION", "No further action",
        "CONTINUE_STANDARD_MONITORING", "Continue monitoring",
        "TARGETED_MERCHANT_OUTREACH_REVIEW", "Targeted outreach review",
        "TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW", "Temporary remittance review",
        _Code
    )
```

[export reference: filecite | turn41file2 | L282-L292]

### Action and Queue must be physically resolved

The accepted source semantics identify:

```text
R1FactIntervention[servicing_action_code]
R1FactIntervention[servicing_queue_code]
```

but the current C2 report binding has not been recovered. The C1 predecessor used presentation fields named `P03 Servicing Action` and `P03 Servicing Queue`. Neither fact authorizes us to replace the current C2 binding with a raw column. [export reference: filecite | turn41file1 | L104-L108]

So once the C2 capture is complete:

**If the report definition points to a current measure:** use that exact measure.

**If it points directly to an R1 column:** preserve that exact column and its current display alias.

**If no current object exists:** stop. Do not invent one during visual editing. That becomes a bounded implementation correction based on the accepted source semantics.

### Exposure and Reason

The names are physically confirmed:

```text
R26 P03 Intervention Exposure
R26 P03 Intervention Reason Display
```

but the exact expressions have not yet been recovered. [export reference: filecite | turn41file2 | L293-L294]

Therefore, use those existing measures as-is if they are already present in the table. Do not rewrite them until their live expressions have been captured.

For presentation:

```text
Exposure → currency
Reason   → text wrap On
Action   → text wrap On
Queue    → text wrap On if necessary
```

Prefer sufficient column width to make the table executive-readable rather than abbreviating governed values.

### Do not add tooltips here yet

The canonical register says there are **no additional explicit tooltip fields physically confirmed** for Servicing & intervention. Do not opportunistically add status, reason codes, alert families, or monitoring values. [export reference: filecite | turn41file1 | L103-L108]

The visible five-column table should stand on its own.

### Preserve the semantic layer boundary

This is critical:

```text
M2.6 intervention recommendation
≠
M2.7 operational setup
≠
M2.8 servicing execution
≠
M2.9 certification
≠
M2.10 endpoint performance
```

Do not improve the table by reaching into a later servicing-execution fact just because its field name looks more operationally appealing. The current gate explicitly requires keeping M2.6 distinct from M2.7/M2.8. [export reference: filecite | turn41file3 | L1134-L1137]

---

## 5. Validate all three visuals together

Once the unresolved current objects have been physically reconciled and the field wells are correct, test the three displays as a single application-scenario journey—not independently.

Use the **Merchant** and **Scenario** slicers. Do not create merchant-only filtering logic or report-level workarounds.

First use an application-scenario with a funded lifecycle. Confirm simultaneously:

```text
Account performance
    populated
    receivable trajectory present
    remittance pace present
    monitoring tooltips populated

Monitoring journey
    populated
    status changes occur only for the selected application-scenario
    tooltip values correspond to the hovered monitoring date

Servicing & intervention
    contains only the selected application-scenario's governed intervention row/state
    no unrelated merchant/scenario row leaks in
```

Then perform the strongest scenario-isolation regression: **Merchant 738, Baseline versus Recession Energy**. The canonical P03 control requires application-scenario identity rather than merchant-only identity; switching Scenario must not leave Baseline lifecycle facts visible in Recession Energy.

For any nonfunded scenario, Account performance and Monitoring journey should not retain rows from the funded scenario. The servicing table must likewise reflect only the selected application-scenario or be blank if no applicable row exists. **An unchanged visual after switching scenarios is a defect to investigate, not evidence that both scenarios happen to match.**

The current open gate explicitly requires Merchant/Scenario interaction validation and no downstream leakage. [export reference: filecite | turn41file3 | L1138-L1140]

Also test at least one later-monitoring date where the status has changed. Hover the same date across both performance and monitoring visuals and make sure:

```text
Monitoring status
Remittance pace
Cumulative shortfall
```

tell a coherent story.

Do not require every measure to have the same value—only that they refer to the same selected application-scenario and monitoring date.

---

## 6. Check visual interactions explicitly

On P03:

Go to **Format → Edit interactions**.

Select the **Merchant slicer**. Verify that it filters:

```text
Account performance
Monitoring journey
Servicing & intervention
```

Then select the **Scenario slicer** and verify the same three filter icons.

Do not use **None** for any of those three.

Do not allow Account performance to filter Monitoring journey, or vice versa, merely because they share monitoring rows. The slicers should provide the controlling filter context. Preserve current inter-visual behavior unless the C2 report definition shows otherwise.

Then turn **Edit interactions** off.

---

## 7. Do a semantic regression before formatting polish

After the bindings are correct, confirm these controls before spending time on spacing, fonts, or axis appearance:

| Control | Required result |
|---|---|
| One merchant + one scenario | One exact application-scenario context |
| Funded path | Account performance and Monitoring journey can populate |
| Nonfunded path | No funded monitoring facts leak in |
| Monitoring date | Same source date drives both charts |
| Receivable balance | Uses `R26 P03 Remaining Receivable`, not raw column |
| Remittance pace | Uses `R26 P03 Remittance Pace`, not raw column |
| Monitoring status | Uses governed status/display objects |
| Intervention | Uses `R1FactIntervention` semantics |
| Servicing Action/Queue | Exact current C2 binding only |
| Tooltips | No previously present tooltip silently dropped |
| Scenario switch | No Baseline/Recession leakage |
| Source facts | Unchanged |
| R26 decision/monitoring policy | Unchanged |

The canonical operating controls specifically require fail-closed treatment of unknown current expressions and preservation of tooltips as first-class bindings. [export reference: filecite | turn41file4 | L1226-L1232]

---

## 8. Only then polish the presentation

Once semantic validation passes, keep the design consistent with the rest of P03.

For **Account performance**, the visual hierarchy should emphasize:

```text
primary series: receivable balance
secondary series: remittance pace
```

The two axes must remain visually distinguishable without relying solely on color; axis titles and tooltip labels should do the explanatory work.

For **Monitoring journey**, emphasize the sequence of governed statuses rather than treating the numeric rank as the business meaning. The end user should see **Current / Watch / Underperforming / Severe shortfall / Paid off**, not be asked to interpret 1/2/3/4.

For **Servicing & intervention**, optimize for readable text. Intervention, Action, Queue, and Reason are decision/operational descriptors, not tiny categorical codes. Give them enough width and use text wrap where appropriate. Exposure can remain compact and right-aligned.

Do **not** introduce novel icons, traffic-light rules, extra KPI cards, or status colors during this work. Those would be design changes beyond the bounded completion of the three existing displays.

---

## 9. Do not perform final accessibility yet

Do not finalize P03 alt text immediately after these three visuals.

The canonical control deliberately defers the final page/visual alt-text and tab-order pass until substantive page content has been finalized. [export reference: filecite | turn41file0 | L43-L50]

The remaining substantive P03 items after these displays include at least:

```text
Technical rationale tooltip
footer/current identity
final interaction validation
```

The open-gate register keeps accessibility after those items. [export reference: filecite | turn41file3 | L1137-L1142]

---

## 10. Persistence and evidence sequence

After these three displays and the remaining substantive P03 items are complete:

**Refresh** the project fully.

Wait for refresh to finish with no errors.

Save C2.

Close Power BI Desktop completely.

Reopen:

```text
MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902
```

Return to P03 and retest the Merchant/Scenario pair and at least one funded path.

Then rerun the existing strengthened narrative QA. These display changes must not disturb the already accepted:

```text
Query 1    2 rows
Query 2    0 rows
Query 3    1,500 rows
All QA     PASS
```

The current C2 overlay records those results as the controlling state. [export reference: filecite | turn41file4 | L1199-L1224]

Only after the save/close/reopen test should we capture final P03 screenshots and freeze evidence. Refresh/persistence and representative evidence remain explicit high-priority P03 gates. [export reference: filecite | turn41file3 | L1140-L1142]

### The most efficient next action

Before making **any** further change to these three visuals, run the two read-only C2 attestation steps above and send me the resulting **`MSBF_C2_PHYSICAL_ATTESTATION_<timestamp>.zip`**. From that package I can resolve the seven remaining backing-object questions, update the canonical register to R2, and then give you an exact field-by-field execution sequence with **no unresolved placeholders**. That is the cleanest application of the governing method and should make the actual Power BI work quite fast.
<!-- END_SOURCE_MESSAGE -->


<a id="m-30c13b55-03b4-40f7-be41-a712875abf56"></a>
## Andrew / user · C118-M00026

C118-M00026 · 2026-09-03T12:36:17.307000-04:00 · active path

Preceding visible parent: [C118-M00025](part-02.md#m-526150d4-df6a-4f94-b191-9248bfdb575f)

**Editorial record note:** 6 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: ba205b67-9887-47fe-9160-c9efc4d1ec22.png; 1142bcf7-7535-4f97-83b6-1fe1e4e3179a.png; 8664a96a-3dd1-491f-9dd6-89ba0e965c9c.png; 4be07a67-6915-47eb-a533-d9bda84f9847.png; 6fe8bebc-9720-4dfb-adeb-96f69abda6e3.png; 01270b01-37f2-4a87-9475-3190388bf48e.png

<!-- BEGIN_SOURCE_MESSAGE -->
please see all measures and clear up P03 instructions where you have items like: "current C2 backing must be captured" and other unknowns like that. Please use this information to update any gaps in our source of truth. if you need the logic behind any of these measures, let me know.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8cde2bf4-a685-4ca6-8412-918750155a8e"></a>
## Assistant · C118-M00027

C118-M00027 · 2026-09-03T12:42:30.793918-04:00 · active path

Preceding visible parent: [C118-M00026](part-02.md#m-30c13b55-03b4-40f7-be41-a712875abf56)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. These screenshots resolve a meaningful portion of the remaining P03 uncertainty, and I have updated the canonical source of truth accordingly.

The owner-confirmed current C2 `R1Measures` P03 inventory now contains **51 current `R26 P03 ...` measures**. Most importantly, we no longer have to write “current C2 backing must be captured” for the **Action** and **Queue** fields in Servicing & intervention: the current measures are definitively `R26 P03 Servicing Action Display` and `R26 P03 Servicing Queue Display`. The screenshots also establish `R26 P03 Servicing Alt Text` and correct an important register-name error: the current measure is **`R26 P03 Selected Structure Alt Text`**, not the handoff-era `R26 P03 Proposed Structure Alt Text`.

They also confirm that `R26 P03 Recommendation Narrative` and `R26 P03 Underwriting Narrative` remain physically present in C2. I am treating those as retained adapters; they do **not** replace the controlling final visible narratives unless we explicitly decide otherwise.

The governing method remains that exact current objects outrank inference, but this new evidence means we can proceed much more directly. A current measure name is now physically established even where I do not yet possess its complete DAX body. [export reference: filecite | turn41file0 | L11-L41]

# Updated P03 display instructions

## Account performance

Keep the title exactly:

**Account performance**

Keep the existing visual. Do not rebuild it.

| Visual role | Exact current object |
|---|---|
| X-axis | `R1FactDailyMonitoring[monitoring_date]` |
| Y-axis | `R26 P03 Remaining Receivable` |
| Secondary Y-axis | `R26 P03 Remittance Pace` |
| Tooltip 1 | `R26 P03 Monitoring Status Display` |
| Tooltip 2 | `R26 P03 Remitted To Date` |
| Tooltip 3 | **keep the existing field currently displayed as `Expected to date`** |
| Tooltip 4 | `R26 P03 Cumulative Shortfall` |

The three primary numerical measures are already controlled:

```DAX
R26 P03 Remaining Receivable =
    MAX (
        'R1FactDailyMonitoring'[receivable_balance_after]
    )
```

```DAX
R26 P03 Remittance Pace =
    MAX (
        'R1FactDailyMonitoring'[cumulative_pace_ratio]
    )
```

```DAX
R26 P03 Remitted To Date =
    MAX (
        'R1FactDailyMonitoring'[cumulative_remittance_amount]
    )
```

And:

```DAX
R26 P03 Cumulative Shortfall =
    MAX (
        'R1FactDailyMonitoring'[cumulative_shortfall_amount]
    )
```

Those are all current successor measures; no retargeting is required. [export reference: filecite | turn41file2 | L843-L847] [export reference: filecite | turn41file2 | L150-L151]

The Monitoring-status tooltip should remain:

`R26 P03 Monitoring Status Display`

which translates the governed R26 status codes into `Paid off`, `Current`, `Watch`, `Underperforming`, `Severe shortfall`, and `Dormant / no remittance`. [export reference: filecite | turn41file2 | L540-L549]

### One Account-performance item remains unidentified

There is **no current R26 P03 measure named `Expected to date`** anywhere in the complete 51-measure inventory you just supplied.

Therefore this is no longer a vague “maybe we missed a measure” issue. It is specifically one of these:

- a direct column or implicit aggregation from a fact table;
- a retained predecessor measure outside `R1Measures`;
- another measure whose display name was locally renamed to `Expected to date`.

**Do not replace it. Leave the current field exactly where it is for now.**

I only need its exact underlying object identity before P03 freeze. We can get that from a hover/field-pill identification without running a full physical attestation exercise.

Also preserve `R26 P03 Account Performance Subtitle` if you are using the subtitle carrier:

> Funded synthetic account • deterministic synthetic-forward

for funded paths and the corresponding no-lifecycle message for nonfunded paths. [export reference: filecite | turn41file2 | L123-L127]

---

## Monitoring journey

Keep the title exactly:

**Monitoring journey**

Keep the existing visual type and do not rebuild it.

| Visual role | Exact current object |
|---|---|
| X-axis | `R1FactDailyMonitoring[monitoring_date]` |
| Y-axis | `R26 P03 Monitoring Status Rank` |
| Tooltip 1 | `R26 P03 Monitoring Status Display` |
| Tooltip 2 | **keep the existing field displayed as `Reason`** |
| Tooltip 3 | `R26 P03 Remittance Pace` |
| Tooltip 4 | **keep the existing field displayed as `Daily shortfall`** |
| Tooltip 5 | `R26 P03 Cumulative Shortfall` |
| Tooltip 6 | **keep the existing field displayed as `Days since remittance`** |

This preserves the exact six-tooltip architecture we already established. The physical predecessor field-well evidence shows the same status/reason/pace/shortfall structure, and the current register preserves it as the intended composition. [export reference: filecite | turn43file1 | L30-L40]

### `R26 P03 Monitoring Status Rank`

We now know definitively that this **current R26 measure exists**. You should use it on Y exactly as-is.

I no longer need to tell you to capture its formula *before using it*. We already know it is the current intended P03 Y-axis measure.

I **would like its DAX for the canonical register**, however, because that will let me formula-certify the ordinal mapping. That is a source-of-truth completion item, not a blocker to using the current measure.

Do not recreate the rank with another `SWITCH`.

### Monitoring Journey `Reason`

Your measure inventory includes two current R26 monitoring-support measures:

```text
R26 P03 Operational Alert Families
R26 P03 Raw Alert Conditions
```

That is useful, but it does **not** tell me which one—if either—is currently behind the visual pill displayed as `Reason`.

So I am deliberately **not** telling you to substitute `Operational Alert Families` for `Reason`.

Keep `Reason` in place until we establish its exact current binding.

The same is true for:

```text
Daily shortfall
Days since remittance
```

Neither appears as a current `R26 P03 ...` measure name in the complete inventory.

### Monitoring Journey subtitle

Continue using:

`R26 P03 Monitoring Journey Subtitle`

which is already known to resolve through funded-lifecycle availability. [export reference: filecite | turn41file2 | L535-L539]

---

# Servicing & intervention

This area is now substantially clearer because your screenshots resolve the two most important prior unknowns.

Keep the title:

**Servicing & intervention**

Do **not** rename it `Servicing recommendation`.

Keep the visible order:

| Visible column | Exact current measure |
|---|---|
| Intervention | `R26 P03 Intervention Display` |
| Action | **`R26 P03 Servicing Action Display`** |
| Queue | **`R26 P03 Servicing Queue Display`** |
| Exposure | `R26 P03 Intervention Exposure` |
| Reason | `R26 P03 Intervention Reason Display` |

That is now the governing P03 configuration.

### Intervention

We already have its exact logic:

```DAX
R26 P03 Intervention Display =
VAR _Code =
    SELECTEDVALUE ( 'R1FactIntervention'[strategy_outcome_code] )
RETURN
    SWITCH (
        _Code,
        "CLOSED_NO_FURTHER_ACTION", "No further action",
        "CONTINUE_STANDARD_MONITORING", "Continue monitoring",
        "TARGETED_MERCHANT_OUTREACH_REVIEW", "Targeted outreach review",
        "TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW", "Temporary remittance review",
        _Code
    )
```

So `Intervention` is fully resolved and correctly successor-owned. [export reference: filecite | turn41file2 | L282-L292]

### Action

Use:

**`R26 P03 Servicing Action Display`**

Do **not** use raw:

`R1FactIntervention[servicing_action_code]`

in the visible table.

The current measure is clearly the presentation adapter created for this purpose.

### Queue

Use:

**`R26 P03 Servicing Queue Display`**

Again, do not replace it with raw:

`R1FactIntervention[servicing_queue_code]`.

### Exposure

Use:

**`R26 P03 Intervention Exposure`**

Do not use implicit `SUM(recommended_action_exposure_amount)` or drag the raw field into the table unless we later discover that the current measure itself is defective.

### Reason

Use:

**`R26 P03 Intervention Reason Display`**

This is the business-facing adapter for the intervention reason. Do not expose raw `primary_intervention_reason_code` in the visible P03 table.

The accepted source object continues to own the underlying M2.6 fields—strategy outcome, servicing action, queue, exposure, and reason—at exact application-scenario grain. [export reference: filecite | turn43file0 | L11-L19]

### Tooltips for Servicing & intervention

Your current visual screenshot showed **no explicit extra Tooltip fields**, and the current measure inventory does not change that conclusion.

So the controlled configuration is:

**No additional explicit tooltip measures.**

The table's standard hover can show its visible row values. Do not add Monitoring status, raw reason codes, operational alerts, or M2.7/M2.8 fields merely because they are available.

The newly confirmed:

`R26 P03 Servicing Alt Text`

is **not a tooltip measure**. It belongs to the final accessibility pass, which you asked us to defer until the rest of P03 is finalized.

---

# What these screenshots resolved in the canonical source of truth

The source-of-truth corrections are now:

| Prior gap | R2 status |
|---|---|
| Current P03 measure population | **Resolved — 51 measures physically confirmed** |
| Servicing `Action` backing | **Resolved → `R26 P03 Servicing Action Display`** |
| Servicing `Queue` backing | **Resolved → `R26 P03 Servicing Queue Display`** |
| Servicing alt-text measure | **Resolved → `R26 P03 Servicing Alt Text`** |
| Structure alt-text current name | **Corrected → `R26 P03 Selected Structure Alt Text`** |
| `R26 P03 Proposed Structure Alt Text` | **Not current C2 measure name** |
| Recommendation Narrative existence | **Confirmed** |
| Underwriting Narrative existence | **Confirmed** |
| Monitoring Status Rank existence | **Confirmed** |
| Operational Alert Families existence | **Confirmed** |
| Raw Alert Conditions existence | **Confirmed** |

So we should **not** run the full C2 physical-attestation workflow before doing this bounded P03 visual work. That remains valuable for final integration-audit inventory, but it is no longer a prerequisite merely to bind these visuals.

# What I still need from you

To make the source of truth **formula-complete**, rather than merely current-name-complete, I would like the DAX for these measures when convenient:

1. `R26 P03 Monitoring Status Rank`
2. `R26 P03 Operational Alert Families`
3. `R26 P03 Raw Alert Conditions`
4. `R26 P03 Intervention Exposure`
5. `R26 P03 Intervention Reason Display`
6. `R26 P03 Servicing Action Display`
7. `R26 P03 Servicing Queue Display`

For the immediate displays, **you do not need to stop and provide all seven before proceeding**. Use the existing measures exactly as named.

There are only **four visual-pill identities** I still need to close separately:

```text
Account performance:
  Expected to date

Monitoring journey:
  Reason
  Daily shortfall
  Days since remittance
```

Because none of those four labels corresponds to a current `R26 P03 ...` measure name in your complete inventory, the most useful next evidence is **not DAX**. Just hover/select those four field pills and show me the underlying object name, exactly as Power BI reports it. That will close the remaining tooltip-binding gaps without unnecessary work.

# Updated canonical register

I created an R2 successor rather than silently overwriting R1.

Download the complete R2 canonical implementation package (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903.zip`; referenced bytes not established here)

Download the R2 SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903.zip.sha256`; referenced bytes not established here)

Open the updated canonical workbook (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903.xlsx`; referenced bytes not established here)

Open the owner-confirmed 51-measure inventory (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903/registers/P03_OWNER_CONFIRMED_CURRENT_MEASURE_NAME_INVENTORY.csv`; referenced bytes not established here)

Open the updated P03 measure register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903/registers/P03_CURRENT_MEASURE_REGISTER.csv`; referenced bytes not established here)

Open the updated P03 visual-binding register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903/registers/P03_CURRENT_VISUAL_BINDING_REGISTER.csv`; referenced bytes not established here)

Open the R2 reconciliation note (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R2_20260903/docs/R2_OWNER_CURRENT_P03_MEASURE_INVENTORY_CORRECTION.md`; referenced bytes not established here)

R2 is now the controlling implementation register for our remaining Power BI work.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2bc774ff-82eb-44b7-b7e1-9ee3c9a138a8"></a>
## Andrew / user · C118-M00028

C118-M00028 · 2026-09-03T13:19:24.784000-04:00 · active path

Preceding visible parent: [C118-M00027](part-02.md#m-8cde2bf4-a685-4ca6-8412-918750155a8e)

<!-- BEGIN_SOURCE_MESSAGE -->
Here is where you are again not challenging enough and settling. The current expected to date, you did not evaluate. It is based on: P03 Cumulative Expected Remittance = 

SELECTEDVALUE (

    FactAccountDaily[cumulative_expected_remittance_amount]

)            which is not an R1 input and may miss cases that were not approved prior to the remediation and are approved after the remediation work.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8ea17639-4a28-48e6-bc19-17cc2139d605"></a>
## Assistant · C118-M00029

C118-M00029 · 2026-09-03T13:32:25.469290-04:00 · active path

Preceding visible parent: [C118-M00028](part-02.md#m-2bc774ff-82eb-44b7-b7e1-9ee3c9a138a8)

<!-- BEGIN_SOURCE_MESSAGE -->
You are correct. This is a **confirmed semantic defect**, not merely an unresolved tooltip binding, and my prior instruction to leave `Expected to date` in place pending identification was not sufficiently rigorous.

The current tooltip is:

```DAX
P03 Cumulative Expected Remittance =
SELECTEDVALUE (
    FactAccountDaily[cumulative_expected_remittance_amount]
)
```

That is physically the predecessor implementation, and the predecessor Account Performance visual bound `Expected to date` to that measure. [export reference: filecite | turn63file0 | L34-L41] [export reference: filecite | turn63file0 | L85-L96]

## The coverage problem is definite

It is stronger than “may miss cases.”

The predecessor M2.5 monitoring population was exactly **7,080 rows**, with exactly 120 monitoring days per funded source path. That means **59 funded paths**. [export reference: filecite | turn69file0 | L96-L134]

Current R1/R26 has:

```text
R1FactFundedLifecycle       130 funded ApplicationScenarioKeys
R1FactDailyMonitoring    15,600 daily rows
Monitoring days/path          120
```

[export reference: filecite | turn41file4 | L1199-L1210]

Therefore:

```text
Predecessor paths       59
Current R1 paths       130
Minimum R1 paths
absent from predecessor 71
```

Even if every one of the old 59 paths survived into R1, **at least 71 of the current 130 funded application-scenario paths cannot possibly be represented by the predecessor `FactAccountDaily` population.**

So `P03 Cumulative Expected Remittance` is **not acceptable for final R26 P03**.

## Correct treatment of Expected to date

The underlying concept—cumulative expected remittance—is legitimate. The defect is the **predecessor source population**, not the metric itself.

The clean bounded Power BI replacement is a current-R1 presentation measure built from the three already-correct successor measures:

```DAX
R26 P03 Expected To Date =
VAR _Actual =
    [R26 P03 Remitted To Date]
VAR _Pace =
    [R26 P03 Remittance Pace]
VAR _Shortfall =
    [R26 P03 Cumulative Shortfall]
VAR _Expected =
    SWITCH (
        TRUE (),
        ISBLANK ( _Actual ), BLANK (),

        NOT ISBLANK ( _Shortfall )
            && _Shortfall > 0,
            _Actual + _Shortfall,

        NOT ISBLANK ( _Pace )
            && _Pace > 0,
            DIVIDE ( _Actual, _Pace ),

        BLANK ()
    )
RETURN
    IF (
        ISBLANK ( _Expected ),
        BLANK (),
        ROUND ( _Expected, 2 )
    )
```

That is superior because every dependency is now successor-owned:

```text
R26 P03 Remitted To Date
→ R1FactDailyMonitoring[cumulative_remittance_amount]

R26 P03 Remittance Pace
→ R1FactDailyMonitoring[cumulative_pace_ratio]

R26 P03 Cumulative Shortfall
→ R1FactDailyMonitoring[cumulative_shortfall_amount]
```

The shortfall branch reconstructs expected directly when the account is behind. The pace branch handles zero-shortfall/current/overperformance states; rounding the result to two decimals restores the monetary precision. I have also prepared a QA query to reconcile the new Expected value back against both current shortfall and current pace.

I recommend **not installing this one measure by itself yet**. We should finish the bounded review immediately below and then install the complete performance/monitoring correction once.

## This exposes three sibling problems

This was the more important consequence of challenging `Expected to date`.

I re-examined the other unresolved Monitoring Journey tooltips. The physical predecessor formulas are:

| Tooltip | Predecessor implementation |
|---|---|
| **Reason** | `SELECTEDVALUE(FactAccountDaily[primary_monitoring_reason_code])` |
| **Daily shortfall** | `SUM(FactAccountDaily[daily_shortfall_amount])` |
| **Days since remittance** | `MAX(FactAccountDaily[days_since_last_positive_remittance])` |

[export reference: filecite | turn70file0 | L27-L39]

So these cannot simply be grandfathered into final P03 either.

**Reason** is especially problematic for two reasons: it has the same 59-path population limitation, and R26 materially improved monitoring semantics around raw alert conditions versus source-owned **operational alert families**. Even for an overlapping predecessor path, the old `primary_monitoring_reason_code` is not automatically the right executive explanation after R26.

**Daily shortfall** also cannot remain predecessor-backed. More importantly, I do **not** recommend casually deriving it from a change in cumulative shortfall; those concepts are not mathematically identical when an account catches up or over-remits. The current 47-column curated R1 monitoring projection does not directly carry `daily_shortfall_amount`. We need either an exact successor derivation/source adapter or to decide that Daily shortfall is redundant and remove it from the tooltip. I favor evaluating whether it adds enough business value to justify carrying another exact source metric.

**Days since remittance** cannot remain predecessor-backed either, but this one is easier: its exact source semantics can be recreated from current `R1FactDailyMonitoring[monitoring_day_index]` and `[actual_remittance_amount]`, so there is no need to retain old `FactAccountDaily`.

The old physical formulas confirm all three risks. [export reference: filecite | turn70file1 | L80-L89]

## What I need from you now

Please give me the DAX for only these **three current measures**:

1. `R26 P03 Operational Alert Families`
2. `R26 P03 Raw Alert Conditions`
3. `R26 P03 Monitoring Status Rank`

That is enough for me to finish the challenge review of the Monitoring Journey. I do **not** need you to start supplying every measure definition.

With those three formulas I can determine, in one bounded pass, whether the final Monitoring Journey should be:

```text
Monitoring status
Operational reason/family
Remittance pace
Cumulative shortfall
Days since remittance
```

with Daily shortfall removed, or whether there is a defensible successor-safe way to retain Daily shortfall.

I will also certify that `Monitoring Status Rank` correctly handles the full current R26 status vocabulary—including `DORMANT_NO_REMITTANCE`—rather than assuming its existence means its implementation is right.

## Canonical-register correction

**R2 is superseded on this issue.** It was too permissive because it categorized `Expected to date` as unresolved rather than challenging the predecessor implementation for successor-population completeness.

I created **R3** with:

- `Expected to date` recorded as a **confirmed current predecessor-bound semantic defect**;
- the 59-path versus 130-path population contradiction documented;
- `R26 P03 Expected To Date` recorded as an approved remediation design, **not yet installed**;
- Reason / Daily shortfall / Days since remittance opened as bounded sibling freeze blockers;
- the predecessor Expected measure added to the do-not-use controls for final R26 P03;
- the proposed one-measure DAX and QA query retained for the eventual bounded patch.

Download the R3 canonical implementation register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R3_20260903.zip`; referenced bytes not established here)

Open the updated canonical workbook (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R3_20260903/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R3_20260903.xlsx`; referenced bytes not established here)

Open the performance/monitoring remediation register (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R3_20260903/registers/P03_PERFORMANCE_MONITORING_SUCCESSOR_REMEDIATION_REGISTER.csv`; referenced bytes not established here)

Open the proposed successor Expected-to-Date patch (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R3_20260903/dax/PROPOSED_P03_EXPECTED_TO_DATE_SUCCESSOR_PATCH_R1_NOT_YET_INSTALLED.dax`; referenced bytes not established here)

**P03 should not freeze until this four-tooltip family has been resolved.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-426452fa-287c-40da-890f-b0736e12fc93"></a>
## Andrew / user · C118-M00030

C118-M00030 · 2026-09-03T13:40:12.571000-04:00 · active path

Preceding visible parent: [C118-M00029](part-02.md#m-8ea17639-4a28-48e6-bc19-17cc2139d605)

<!-- BEGIN_SOURCE_MESSAGE -->
you could also do what P02 did, but you aren't digging that deep still, and that is what I'm trying to solve here. You still do not have a firm grasp of the measures landscape in our Power BI project: R1 P02 Cumulative Expected As Of = 

        [R1 P01 Cumulative Expected As Of]         I do not know the correct path to resolve this gap in your understanding. each pass you are taking currently still misses the larger point.
<!-- END_SOURCE_MESSAGE -->
