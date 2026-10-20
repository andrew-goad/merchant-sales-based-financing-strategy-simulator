# MSBF - Power BI Executive Portfolio Intelligence Part 3

Part 03 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-02.md)
[Next part](part-04.md)

<a id="m-9bac96be-fb5d-40e7-8920-c15c6d5fce23"></a>
## Assistant · C118-M00031

C118-M00031 · 2026-09-03T13:41:23.782228-04:00 · active path

Preceding visible parent: [C118-M00030](part-02.md#m-426452fa-287c-40da-890f-b0736e12fc93)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. That is the larger point, and your P02 example exposes exactly what I have been doing wrong.

I have been approaching P03 as though its unresolved measures need to be **individually reconstructed from source columns**. That is not the architecture of the successor Power BI model. The project already has a **measure hierarchy**, and I have been reasoning too locally instead of traversing that hierarchy before proposing changes.

The evidence is now clear.

`R1 P02 Cumulative Expected As Of` does not calculate anything itself:

```DAX
R1 P02 Cumulative Expected As Of =
    [R1 P01 Cumulative Expected As Of]
```

[export reference: filecite | turn72file0 | L9-L18]

And P02 actually uses that measure as the `Expected to date` tooltip on its Remittance fulfillment visual. [export reference: filecite | turn72file0 | L39-L47]

More importantly, the P01 measure it delegates to is already the successor-wide implementation:

```DAX
R1 P01 Cumulative Expected As Of =
IF (
    [R1 P01 As Of Evidence Status] = "VALID",
    COALESCE (
        SUMX (
            VALUES ( 'R1DimApplicationScenario'[ApplicationScenarioKey] ),
            CALCULATE ( [R1 P01 __Cumulative Expected As Of] )
        ),
        0
    )
)
```

[export reference: filecite | turn72file1 | L72-L90]

And the hidden canonical helper is already built entirely on `R1FactDailyMonitoring`:

```DAX
R1 P01 __Cumulative Expected As Of =
VAR _Actual =
    [R1 P01 __Cumulative Actual As Of]
VAR _Pace =
    [R1 P01 __Pace Ratio As Of]
VAR _Shortfall =
    [R1 P01 __Cumulative Shortfall As Of]
RETURN
    SWITCH (
        TRUE (),
        ISBLANK ( _Actual ), BLANK (),
        NOT ISBLANK ( _Pace ) && _Pace > 0,
            DIVIDE ( _Actual, _Pace ),
        NOT ISBLANK ( _Shortfall ),
            _Actual + _Shortfall,
        BLANK ()
    )
```

[export reference: filecite | turn73file1 | L402-L416]

The three helpers underneath it all read the current successor fact:

- Actual → `R1FactDailyMonitoring[cumulative_remittance_amount]`
- Pace → `R1FactDailyMonitoring[cumulative_pace_ratio]`
- Shortfall → `R1FactDailyMonitoring[cumulative_shortfall_amount]`

[export reference: filecite | turn73file1 | L360-L401]

So I should **not have proposed a new independent `R26 P03 Expected To Date` calculation.**

In fact, the R3 proposal is worse than merely redundant: I changed the branch precedence by testing shortfall before pace, whereas the existing canonical P01 implementation tests pace first. That means my proposed R3 measure could diverge from the already-established successor semantic. **That proposed R3 DAX is withdrawn.** R3 can remain evidence that we found the predecessor binding defect, but it should not be treated as implementation authority.

### The architecture I should have recognized

There is already a layering pattern in this project:

```text
SOURCE / SEMANTIC FACTS
        ↓
R1FactDailyMonitoring + other R1 successor facts
        ↓
P01 canonical successor semantic layer
        ↓
P02 page layer
    aliases P01 where semantics are identical
    adds P02-specific lifecycle/cohort calculations
        ↓
R26 P02 overlay
    adds R26 monitoring-family semantics
        ↓
P03 / P04 presentation layers
    should reuse those canonical semantics wherever possible
    and only add genuinely page-specific logic
```

P02 proves this repeatedly. It does not just alias cumulative expected:

```text
R1 P02 Current Exposure As Of
    → R1 P01 Current Exposure As Of

R1 P02 Cumulative Actual As Of
    → R1 P01 Cumulative Actual As Of

R1 P02 Cumulative Expected As Of
    → R1 P01 Cumulative Expected As Of

R1 P02 Remittance Fulfillment
    → R1 P01 Remittance Fulfillment

R1 P02 Active Alert Flags As Of
    → R1 P01 Active Alert Flags As Of

R1 P02 Paid-Off Paths As Of
    → R1 P01 Paid-Off Paths As Of
```

[export reference: filecite | turn72file0 | L9-L20]

And where R26 added new monitoring semantics, P02 again built on the P01 as-of engine rather than creating another independent date framework. `R26 P02 Operational Alert Families As Of`, for example, gets its `_LatestDate` from `[R1 P01 __Latest Monitoring Date As Of]` and then evaluates the R26 source-owned `operational_alert_family_count`. [export reference: filecite | turn74file0 | L15-L28] The R26 raw-alert measure follows the same architecture. [export reference: filecite | turn74file1 | L70-L97]

That is the pattern I should be applying to P03.

### There is one important P03 distinction

We should not blindly change P03 Expected to:

```DAX
[R1 P01 Cumulative Expected As Of]
```

because P02 and P03 currently have different date-context architectures.

P02's X-axis is:

```text
DimAsOfDate[AsOfDate]
```

[export reference: filecite | turn74file2 | L242-L250]

That is exactly what drives `[Selected As Of Date]`, the disconnected as-of controller. [export reference: filecite | turn73file0 | L71-L82]

P03's Account Performance X-axis is currently:

```text
R1FactDailyMonitoring[monitoring_date]
```

[export reference: filecite | turn72file4 | L248-L254]

So a naked P01 alias on the current P03 visual could use the default/selected `DimAsOfDate` rather than each plotted monitoring date.

That gives us **two legitimate architectural solutions**, and this is the type of choice we should evaluate instead of inventing another metric:

1. **Preferred architecture to evaluate:** make the P03 time-series use `DimAsOfDate[AsOfDate]`, as P02 does, and let P03 reuse the canonical P01/P02 as-of measures directly.

2. If retaining `R1FactDailyMonitoring[monitoring_date]` is preferable for P03 interaction behavior, create only a **context adapter** that translates the plotted monitoring date into `DimAsOfDate` context and then delegates to `[R1 P01 Cumulative Expected As Of]`. The adapter should contain no expected-remittance mathematics of its own.

That is fundamentally different from what I proposed last turn.

### And it changes how we should handle the other P03 measures

I also should **not ask you for three isolated DAX formulas** now. We already have enough evidence to know that is the wrong workflow.

For example, P02 already contains:

```DAX
R1 P02 __Monitoring Status As Of
```

which uses `[R1 P01 __Latest Monitoring Date As Of]` and then returns the current `R1FactDailyMonitoring[monitoring_status_code]`. [export reference: filecite | turn73file1 | L477-L492]

P02 also already has:

```DAX
R1 P02 __Monitoring Day Index As Of
```

built on the same P01 canonical date engine. [export reference: filecite | turn74file4 | L371-L386]

And the entire R26 monitoring-family layer already exists in P02:

- `R26 P02 Accounts with Operational Alerts As Of`
- `R26 P02 Accounts in Adverse Monitoring Status As Of`
- `R26 P02 Raw Alert Conditions As Of`
- `R26 P02 Operational Alert Families As Of`

all using the P01 as-of framework and current R26 monitoring source. [export reference: filecite | turn74file2 | L166-L180] [export reference: filecite | turn74file3 | L274-L291]

So before touching `Reason`, `Daily shortfall`, `Days since remittance`, `Monitoring Status Rank`, or frankly any other P03 performance measure, I need to determine whether its semantic already exists at one of those lower layers.

## The correct way to close my understanding gap

I think this is now clear: **stop doing P03 measure remediation until I have built the actual Power BI semantic dependency landscape.**

Not another P03 register of measure names. A dependency/ownership map of the model.

For every measure relevant to P01–P04, I need to establish:

```text
Measure
  ↓
semantic owner / canonical layer
  ↓
direct measure dependencies
  ↓
ultimate table/column dependencies
  ↓
date-context mechanism
  ↓
grain
  ↓
successor vs predecessor source boundary
  ↓
pages/visuals consuming it
  ↓
aliases/wrappers that already reuse it
  ↓
duplicate calculations elsewhere
  ↓
deprecated predecessor equivalents
```

Then classify every P03 binding as one of only four things:

```text
REUSE_CANONICAL
    Existing P01/P02/R26 semantic should be reused directly.

CONTEXT_ADAPTER_ONLY
    Existing semantic is correct but P03 needs date/grain context translated.

P03_SPECIFIC
    Truly unique Application Journey presentation/narrative logic.

DEFECT / RETIRE
    Predecessor-bound, duplicate, semantically inconsistent, or unnecessary.
```

That is the missing control.

It would also surface exactly the kind of defect you just caught: I would never have proposed another expected-remittance formula because the dependency map would have shown:

```text
P03 Expected to date
    predecessor:
        ModelParameters[P03 Cumulative Expected Remittance]
            → FactAccountDaily   ❌

canonical successor semantic:
        R1 P01 Cumulative Expected As Of
            → R1 P01 __Cumulative Expected As Of
                → R1 P01 __Cumulative Actual As Of
                → R1 P01 __Pace Ratio As Of
                → R1 P01 __Cumulative Shortfall As Of
                    → R1FactDailyMonitoring   ✓

P02 precedent:
        R1 P02 Cumulative Expected As Of
            → R1 P01 Cumulative Expected As Of   ✓
```

Once that is visible, the answer is obvious: **reuse/adapt; do not recalculate.**

I also think this needs to go beyond P03. If I only map the measures P03 happens to use, I can still miss reusable semantics living in P01, P02, or P04. The bounded scope should therefore be **the complete P01–P04 measure-and-visual dependency landscape, including R1 and R26 overlays and retained predecessor measures**, before we finish P03.

And I would treat the current R3 package as **finding evidence only, not the next implementation baseline**. The proposed Expected-to-Date patch in it is withdrawn. The next controlled revision should be built only after this dependency-landscape exercise, because otherwise we would again be patching symptoms before understanding the semantic architecture.

That is the path I think resolves the problem you are describing—not by you feeding me measures one at a time, but by me systematically reconstructing and owning the measure landscape from the project evidence we already have.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8d3ab912-b646-4e95-a9d1-53d1aaaac3cf"></a>
## Andrew / user · C118-M00032

C118-M00032 · 2026-09-03T13:45:38.004000-04:00 · active path

Preceding visible parent: [C118-M00031](part-03.md#m-9bac96be-fb5d-40e7-8920-c15c6d5fce23)

<!-- BEGIN_SOURCE_MESSAGE -->
so how do I give you what you need?
<!-- END_SOURCE_MESSAGE -->


<a id="m-b8bf94a6-bc50-4a28-a82b-ce178b6967ff"></a>
## Assistant · C118-M00033

C118-M00033 · 2026-09-03T13:45:42.431307-04:00 · active path

Preceding visible parent: [C118-M00032](part-03.md#m-8d3ab912-b646-4e95-a9d1-53d1aaaac3cf)

<!-- BEGIN_SOURCE_MESSAGE -->
The best way is to give me the **current C2 PBIP project itself**, or a read-only export of its semantic/report definitions. That closes the problem at the root.

What I need, in priority order:

1. **Best option — zip the full current project folder**
   - `MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902`
   - Include the `.pbip`, `.SemanticModel`, and `.Report` folders.
   - Attach that ZIP here.
   - You do **not** need to include caches or unrelated local files.

2. **If the full PBIP is too large**, give me these two physical definitions:
   - the current semantic model definition, especially `model.bim` or the TMDL equivalent;
   - the current report definition folder/files containing visual bindings.
   This is enough for me to recover every measure body, dependency, display folder, hidden helper, page/visual consumer, and tooltip binding.

3. **Fallback only if neither is practical:** run a full metadata export from the open C2 model and send me:
   - all measures with full DAX expressions;
   - all tables/columns;
   - relationships;
   - report visual/queryRef bindings.
   The partial screenshot-by-screenshot approach is workable, but it is exactly what has been causing the context gaps, so I do not recommend continuing that way.

Once you attach the **full C2 PBIP ZIP**, I can build the thing we actually need: a canonical P01–P04 semantic dependency map that shows each measure’s formula, direct and ultimate dependencies, semantic owner, date-context engine, grain, page/visual consumers, aliases, predecessor equivalents, and whether P03 should **reuse, context-adapt, retain as page-specific, or retire** it.

That would also let me validate the physical current state rather than reconstructing it from handoff summaries.

So the simplest answer is: **zip your current `MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902` project folder and attach it here.** You should not need to manually feed me any more DAX one measure at a time.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3966a22a-d14f-4944-8057-3ed71ad82cd9"></a>
## Andrew / user · C118-M00034

C118-M00034 · 2026-09-03T13:50:21.886000-04:00 · active path

Preceding visible parent: [C118-M00033](part-03.md#m-b8bf94a6-bc50-4a28-a82b-ce178b6967ff)

**Editorial record note:** Attachment references: project.zip

<!-- BEGIN_SOURCE_MESSAGE -->
requested zip attached. Please ingest everything you need and update our source of truth appropriately. then let's stop circling and get back to professional production on these remaining tabs.
<!-- END_SOURCE_MESSAGE -->


<a id="m-adee78c9-99bb-473d-8c13-3570dd966667"></a>
## Assistant · C118-M00035

C118-M00035 · 2026-09-03T15:15:48.028918-04:00 · active path

Preceding visible parent: [C118-M00034](part-03.md#m-3966a22a-d14f-4944-8057-3ed71ad82cd9)

<!-- BEGIN_SOURCE_MESSAGE -->
# R4 source of truth established

Complete. I ingested the attached `project.zip` as the physical project input and reconciled its semantic model, report definition, DAX-query history, current carrier data, lifecycle integration, measures, dependencies, visuals, field wells, tooltips, and page-level source bindings. [export reference: filecite | turn75file0 | L1-L9]

The gap is now closed at the **project architecture level**, not through another partial P03 inventory.

**`MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R4_20260903` now supersedes R1–R3 as the controlling implementation register.**

## Controlling physical state

The uploaded folder still carries C1 folder names, but it contains the current working C2 PBIX. The correct authority is:

```text
Current working project
MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902.pbix

PBIX SHA-256
fa2eb55fd556d12b4a4c2b6f135dc2f3f67cd5c427208560a77cae940bf5b52a

C3 required
NO

Public supersession/publication
NOT AUTHORIZED
```

The readable C1 PBIP model and report trees are retained as predecessor-readable baseline evidence only. They are not current authority. Continue working in the C2 PBIX. Synchronizing the readable PBIP representation is a later integration-audit hygiene requirement, not a blocker to present P03 production.

## Recovered current implementation landscape

| Current implementation object | Recovered |
|---|---:|
| Tables | 55 |
| Columns | 1,804 |
| Measures | 316 |
| Exact readable measure expressions | 315 |
| Direct dependency edges | 833 |
| Pure measure aliases/wrappers | 12 |
| Relationships | 55 |
| Report pages | 7 |
| Visuals | 133 |
| Current report bindings | 271 |
| Report-object field references | 347 |
| Current P03 measures | 51 |
| P03 visuals | 25 |
| P03 bindings | 53 |

The one name-only measure is an unused `R26 P03 Recommendation Narrative`; it does not prevent current production.

The register now explicitly tracks:

- each measure’s semantic owner;
- direct and ultimate dependencies;
- canonical aliases and wrappers;
- date-context mechanism;
- source grain;
- predecessor-table exposure;
- page and visual consumers;
- installed DAX overlay chronology;
- current report field wells and tooltips;
- reuse versus context-adapter versus page-specific treatment.

This captures the architecture you were pressing me to recognize. For example, P02 delegates `R1 P02 Cumulative Expected As Of` to the canonical P01 measure rather than recreating its mathematics. [export reference: filecite | turn72file0 | L9-L18] The underlying P01 helper owns the expected-remittance reconstruction from current R1 actual, pace, and shortfall measures. [export reference: filecite | turn73file1 | L402-L416]

## R3 correction

The independent calculation proposed in R3 for `R26 P03 Expected To Date` is **withdrawn and must not be installed**.

R4 instead implements the correct architecture:

```text
P03 plotted monitoring date
        ↓ context translation
DimAsOfDate[AsOfDate]
        ↓
R1 P01 __Cumulative Expected As Of
        ↓
canonical R1FactDailyMonitoring semantic engine
```

The new P03 measure is therefore a **date-context adapter only**. It does not duplicate or alter the canonical expected-remittance calculation.

# Immediate P03 production sequence

No further one-off screenshots or measure formulas are needed before completing these three displays.

## 1. Install the bounded four-measure patch

In the current C2 PBIX:

1. Save the project.
2. Open DAX Query View.
3. Open or paste the supplied successor patch.
4. Select **Run**.
5. Confirm the result reports four measures and no source mutation.
6. Select **Update model with changes** once.

The patch creates exactly:

```text
R26 P03 Expected To Date
R26 P03 Primary Alert Family Display
R26 P03 Daily Shortfall Alert Display
R26 P03 Days Since Remittance
```

It does not change:

```text
R1FactDailyMonitoring
R1FactIntervention
R1FactFundedLifecycle
relationships
strategy logic
policy logic
funding logic
Patch 3 narratives
strengthened narrative QA
```

Open the four-measure production patch (historical reference: `sandbox:[session]/MSBF_R26_P03_PERFORMANCE_MONITORING_SUCCESSOR_PATCH_R1_20260903.dax`; referenced bytes not established here)

## 2. Finalize Account performance

Keep the title:

```text
Account performance
```

Use this exact configuration:

| Role | Object | Display label |
|---|---|---|
| X-axis | `R1FactDailyMonitoring[monitoring_date]` | Monitoring date |
| Y-axis | `[R26 P03 Remaining Receivable]` | Remaining balance |
| Secondary Y-axis | `[R26 P03 Remittance Pace]` | Remittance pace |
| Tooltip 1 | `[R26 P03 Monitoring Status Display]` | Monitoring status |
| Tooltip 2 | `[R26 P03 Remitted To Date]` | Remitted to date |
| Tooltip 3 | `[R26 P03 Expected To Date]` | Expected to date |
| Tooltip 4 | `[R26 P03 Cumulative Shortfall]` | Cumulative shortfall |

Remove these two predecessor measures:

```text
ModelParameters[P03 Cumulative Expected Remittance]
ModelParameters[P03 Cumulative Shortfall]
```

Keep the current successor X-axis, Y-axis, secondary Y-axis, Monitoring status, and Remitted-to-date bindings.

## 3. Finalize Monitoring journey

Keep the title:

```text
Monitoring journey
```

Replace the current predecessor-backed visual configuration with:

| Role | Object | Display label |
|---|---|---|
| X-axis | `R1FactDailyMonitoring[monitoring_date]` | Monitoring date |
| Y-axis | `[R26 P03 Monitoring Status Rank]` | Monitoring status rank |
| Tooltip 1 | `[R26 P03 Monitoring Status Display]` | Monitoring status |
| Tooltip 2 | `[R26 P03 Primary Alert Family Display]` | Primary alert family |
| Tooltip 3 | `[R26 P03 Daily Shortfall Alert Display]` | Daily shortfall alert |
| Tooltip 4 | `[R26 P03 Remittance Pace]` | Remittance pace |
| Tooltip 5 | `[R26 P03 Cumulative Shortfall]` | Cumulative shortfall |
| Tooltip 6 | `[R26 P03 Days Since Remittance]` | Days since remittance |
| Tooltip 7 | `[R26 P03 Operational Alert Families]` | Operational alert families |
| Tooltip 8 | `[R26 P03 Raw Alert Conditions]` | Raw alert conditions |

Remove every `FactAccountDaily` and `ModelParameters[P03 ...]` binding from this visual.

The current visual already has reference lines for ranks 0–4. Add:

```text
Value: 5
Label: Dormant / no remittance
```

The controlled status ladder is:

```text
0  Paid off
1  Current
2  Watch
3  Underperforming
4  Severe shortfall
5  Dormant / no remittance
```

The old dollar-valued **Daily shortfall** tooltip is deliberately not reproduced. The curated R26 Power BI source exposes the governed `daily_shortfall_alert_flag`, while cumulative shortfall remains the amount-bearing metric. The new tooltip is therefore accurately relabeled **Daily shortfall alert** rather than presenting an unsupported reconstructed amount.

## 4. Finalize Servicing & intervention

Keep the title:

```text
Servicing & intervention
```

Keep the existing table and this exact visible order:

| Order | Current successor measure | Display label |
|---:|---|---|
| 1 | `[R26 P03 Intervention Display]` | Intervention |
| 2 | `[R26 P03 Servicing Action Display]` | Action |
| 3 | `[R26 P03 Servicing Queue Display]` | Queue |
| 4 | `[R26 P03 Intervention Exposure]` | Exposure |
| 5 | `[R26 P03 Intervention Reason Display]` | Reason |

Remove all five predecessor `FactIntervention` fields.

Do not add a separate tooltip field well. `R26 P03 Servicing Alt Text` remains reserved for the final accessibility pass.

# Required validation

After the four measures are installed and the visuals are rebound, run the supplied QA using **Run only**. Do not select **Update model with changes** for the QA query.

Open the performance/monitoring QA query (historical reference: `sandbox:[session]/MSBF_R26_P03_PERFORMANCE_MONITORING_QA_R1_20260903.dax`; referenced bytes not established here)

Required results:

| QA result | Required |
|---|---|
| Result 1 | `15,600 monitoring rows / 130 paths / 120 minimum days / 120 maximum days` |
| Result 2 | `0 rows` |
| Result 3 | Merchant 738 Baseline = 120 monitoring rows and lifecycle available; Recession Energy = 0 monitoring rows |
| Result 4 | `126 closed/no-further-action / 3 outreach-review / 1 temporary-remittance-review` |

Then perform these visual checks:

| Merchant/scenario | Required display behavior |
|---|---|
| `000082 / Baseline` | All three downstream displays blank |
| `000738 / Baseline` | Account performance and Monitoring journey populated; Servicing shows No further action |
| `000738 / Recession Energy` | All three downstream displays blank |
| `000098 / Baseline` | Targeted outreach review |
| `000749 / Baseline` | Temporary remittance review |

Continue holding the final screenshot/evidence package until all remaining P03 controls are complete.

# Remaining P03 sequence

After this right-side display pass:

1. Build the Technical rationale tooltip.
2. Correct the footer to current C2/R26 identity.
3. Validate Merchant/Scenario interactions and nonfunded blanking.
4. Complete the final page and visual alt-text/tab-order pass.
5. Refresh.
6. Save, close, and reopen C2.
7. Rerun narrative QA and operational QA.
8. Capture the representative seven-outcome evidence set.
9. Freeze P03.
10. Move directly to the P04 successor rebase.

The physical project review confirms that P04 is the next major rebase: **30 of its 31 current report bindings remain predecessor/core**, while P05 and P06 are already constructed as R1 candidate pages.

# Controlling deliverables

Download the complete R4 source-of-truth package (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R4_20260903.zip`; referenced bytes not established here)

Download the R4 SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R4_20260903.zip.sha256`; referenced bytes not established here)

Open the canonical implementation workbook (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R4_20260903.xlsx`; referenced bytes not established here)

Open the detailed P03 production instructions (historical reference: `sandbox:[session]/MSBF_P03_PRODUCTION_INSTRUCTIONS_R4_20260903.md`; referenced bytes not established here)

Open the exact P03 target binding plan (historical reference: `sandbox:[session]/_r4_user_build/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R4_20260903/registers/P03_TARGET_BINDING_PLAN.csv`; referenced bytes not established here)

Open the P01–P03 semantic reuse map (historical reference: `sandbox:[session]/_r4_user_build/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R4_20260903/registers/P01_P02_P03_SEMANTIC_REUSE_MAP.csv`; referenced bytes not established here)

Open the ZIP validation report (historical reference: `sandbox:[session]/MSBF_POWER_BI_CANONICAL_IMPLEMENTATION_REGISTER_R4_20260903_ZIP_VALIDATION_REPORT.md`; referenced bytes not established here)

```text
R4 package bytes       29,317,809
R4 package SHA-256     93373973c9248cd78ce6fc5c5687dda71025dc2514706fbef06ee0aabaa35f2f
ZIP entries            207
CRC                     PASS
Clean extraction        PASS
Manifest                PASS
SHA256SUMS              PASS
Unsafe paths            0
Duplicate paths         0
Case-fold collisions    0
Symlinks                0
Encrypted entries       0
Windows path budget     PASS
```

The next production action is the bounded four-measure patch in C2, followed by the exact three-visual rebindings above.
<!-- END_SOURCE_MESSAGE -->


<a id="m-07eb3b86-e578-420f-b42e-e76d946a5616"></a>
## Andrew / user · C118-M00036

C118-M00036 · 2026-09-03T15:31:37.480000-04:00 · active path

Preceding visible parent: [C118-M00035](part-03.md#m-adee78c9-99bb-473d-8c13-3570dd966667)

<!-- BEGIN_SOURCE_MESSAGE -->
y-axis and secondary y-axis titles for account performance chart
<!-- END_SOURCE_MESSAGE -->


<a id="m-69a4f2ce-b738-4686-a997-3dc3c957b090"></a>
## Assistant · C118-M00037

C118-M00037 · 2026-09-03T15:31:39.570657-04:00 · active path

Preceding visible parent: [C118-M00036](part-03.md#m-07eb3b86-e578-420f-b42e-e76d946a5616)

<!-- BEGIN_SOURCE_MESSAGE -->
For the **Account performance** chart, use:

- **Y-axis title:** `Remaining receivable`
- **Secondary Y-axis title:** `Remittance pace`

I prefer **Remaining receivable** over “Remaining balance” because it matches the portfolio/receivable terminology already established elsewhere in the Power BI project.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b4209df6-82f0-490a-9e7c-9b726d173b8f"></a>
## Andrew / user · C118-M00038

C118-M00038 · 2026-09-03T15:54:56.814000-04:00 · active path

Preceding visible parent: [C118-M00037](part-03.md#m-69a4f2ce-b738-4686-a997-3dc3c957b090)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 26724b14-fc39-46e2-9095-e16e2c72afce.png

<!-- BEGIN_SOURCE_MESSAGE -->
how to have the y-axis include values for 0,1,2,3,4,5 and not just 0,2,4: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-55e2713c-614e-4a05-a591-5455d58540d3"></a>
## Assistant · C118-M00039

C118-M00039 · 2026-09-03T15:54:59.453178-04:00 · active path

Preceding visible parent: [C118-M00038](part-03.md#m-b4209df6-82f0-490a-9e7c-9b726d173b8f)

<!-- BEGIN_SOURCE_MESSAGE -->
Power BI is automatically choosing a **2-unit major tick interval** because of the visual's height. There isn't normally a direct “tick interval = 1” setting for this line chart.

For this **Monitoring journey** visual, do this:

1. Select the chart.
2. Open **Format visual**.
3. Expand **Y-axis**.
4. Under **Range**, set:
   - **Minimum:** `0`
   - **Maximum:** `5`
5. Look for **Values → Density** (sometimes shown as label density) and move it to the **maximum**.

If Power BI still displays only `0, 2, 4`, that means it is suppressing alternating numeric tick labels because of the available vertical space. Increasing the visual height may make `0–5` all appear, but I **wouldn't enlarge this P03 visual just to force numeric ticks**.

More importantly, for our design, the numbers themselves are not the business meaning. Your reference-line labels already communicate the governed ladder:

```text
5  Dormant / no remittance
4  Severe shortfall
3  Underperforming
2  Watch
1  Current
0  Paid off
```

So if Power BI insists on showing only `0, 2, 4` after setting **Min = 0 / Max = 5** and maximum label density, I would **hide the numeric Y-axis labels entirely** and rely on the six labeled horizontal status lines. That would actually be cleaner and more executive-facing than having both the numeric rank and the status labels compete for attention.
<!-- END_SOURCE_MESSAGE -->


<a id="m-41abba4b-faba-406a-993e-91d06f1ba216"></a>
## Andrew / user · C118-M00040

C118-M00040 · 2026-09-03T16:13:01.346000-04:00 · active path

Preceding visible parent: [C118-M00039](part-03.md#m-55e2713c-614e-4a05-a591-5455d58540d3)

<!-- BEGIN_SOURCE_MESSAGE -->
please provide a good mix of each type of narrative in our data. I want to capture a good amount of evidence for this P03. Let's say at least 1 example for each narrative situation. can you provide a good mix of merchants that I should capture (some baseline / some recession). This should exhaust the narrative situations that we may see. I will then capture the P03 screenshots accordingly for that set of merchants. also, please supply alt text instructions for the title, left kpi card, merchant request, proposed structure, single cards for decision class and label, narratives, account performance, monitoring journey, and servicing & intervention.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9a58a7b4-a835-4748-9068-c77e2ef89aa4"></a>
## Assistant · C118-M00041

C118-M00041 · 2026-09-03T16:15:18.003513-04:00 · active path

Preceding visible parent: [C118-M00040](part-03.md#m-41abba4b-faba-406a-993e-91d06f1ba216)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Now that we have the full current narrative inventory and the exact helper branching, I would capture **more than merely seven screenshots**. The narrative system has seven governed outcomes, but review and hard-stop outcomes contain materially different explanatory branches. The controlling QA explicitly requires all seven outcomes plus a Recession Energy path affected by the Baseline non-improvement floor. [export reference: filecite | turn77file10 | L1042-L1073]

## Recommended P03 evidence population

I recommend **17 merchant/scenario screenshots**. That is enough to cover every material narrative family and the meaningful helper branches without turning the evidence package into a random sample.

| # | Merchant | Scenario | Narrative situation demonstrated | Why capture it |
|---:|---:|---|---|---|
| 1 | **738** | **Baseline** | **Approved as requested** | Canonical funded approval; also half of the critical scenario-isolation pair. It has exactly one lifecycle row and a physical funding date. [export reference: filecite | turn82file1 | L8-L14] |
| 2 | **101** | **Recession Energy** | **Counteroffer authorized** | Gives us a stress-scenario authorized counteroffer rather than making the funded evidence set Baseline-only. Current inventory identifies 101/RE as counteroffer authorized. [export reference: filecite | turn79file3 | L57-L63] |
| 3 | **082** | **Baseline** | **Counteroffer review — medium-confidence evidence** | Canonical Patch-3 regression case; exercises the corrected “evidence is usable but not strong enough...” construction. [export reference: filecite | turn82file0 | L1-L7] |
| 4 | **002** | **Baseline** | **Counteroffer review — verification + capacity** | Exercises the combined review-reason branch: verification concern **and** capacity frontier. [export reference: filecite | turn86file0 | L1-L7] |
| 5 | **051** | **Baseline** | **Counteroffer review — capacity + repayment guardrail** | Exercises the distinct combined capacity/repayment-review narrative. [export reference: filecite | turn86file2 | L15-L23] |
| 6 | **446** | **Baseline** | **Counteroffer review — processor continuity** | Exercises the processor-continuity review explanation. [export reference: filecite | turn86file1 | L8-L14] |
| 7 | **149** | **Baseline** | **Counteroffer review — verification only** | Separates the pure verification branch from merchant 002's verification-plus-capacity branch. [export reference: filecite | turn87file2 | L13-L19] |
| 8 | **003** | **Baseline** | **Counteroffer review — capacity only** | Exercises the pure capacity-frontier review wording. [export reference: filecite | turn87file1 | L5-L12] |
| 9 | **749** | **Recession Energy** | **Underwriting review — capacity/resilience + negative liquidity** | Strong manual-review example and a visually valuable stress case: negative liquidity, review-eligible structure, no funding. [export reference: filecite | turn82file2 | L15-L21] |
| 10 | **298** | **Recession Energy** | **Underwriting review — medium data confidence** | Distinct manual-review reason: evidence usable but insufficient for straight-through authorization. [export reference: filecite | turn80file2 | L34-L36] |
| 11 | **738** | **Recession Energy** | **Evidence decline** | Other half of the canonical 738 scenario-isolation pair: 28 usable days versus 30 required, no funded lifecycle. [export reference: filecite | turn82file1 | L8-L14] |
| 12 | **004** | **Baseline** | **No feasible structure — ordinary complete search** | Clean normal no-feasible case: 11 alternatives tested, complete search, no feasible candidate, no funding. [export reference: filecite | turn81file3 | L25-L32] |
| 13 | **082** | **Recession Energy** | **No feasible structure — stress-floor/non-improvement path** | Particularly valuable because the same merchant is review-eligible in Baseline but becomes governed no-feasible under Recession Energy/non-improvement-floor treatment. [export reference: filecite | turn82file0 | L1-L7] |
| 14 | **009** | **Baseline** | **Policy hard stop — elevated fraud/verification risk** | Exercises `FRAUD_TIER_3` plain-English branch. [export reference: filecite | turn88file0 | L1-L5] |
| 15 | **120** | **Baseline** | **Policy hard stop — specific verification conflict** | Exercises the distinct non-remediable verification-conflict branch. [export reference: filecite | turn88file1 | L6-L10] |
| 16 | **056** | **Baseline** | **Policy hard stop — processor continuity** | Exercises the hard-stop processor-continuity branch, distinct from processor continuity causing review. [export reference: filecite | turn88file2 | L11-L15] |
| 17 | **102** | **Baseline** | **Policy hard stop — evidence-confidence boundary** | Exercises the evidence-confidence hard-stop branch. [export reference: filecite | turn88file3 | L16-L20] |
| 18* | **018** | **Baseline** | **Policy hard stop — generic policy/verification/covenant fallback** | I recommend this final screenshot because it proves the helper's governed fallback wording as well. [export reference: filecite | turn88file4 | L21-L25] |

I would actually capture **all 18**. The first 13 give excellent outcome/strategy/scenario coverage; 14–18 exhaust the five materially different hard-stop helper outputs.

The reason this is more defensible than seven screenshots is that `R26 P03 __Review Reason Plain English` contains separate branches for verification+capacity, verification, processor continuity, medium confidence, repayment+capacity, repayment, capacity, and fallback. [export reference: filecite | turn85file0 | L62-L96] The hard-stop helper separately contains fraud-tier, verification-conflict, processor-continuity, medium-confidence, and generic-policy branches. [export reference: filecite | turn85file0 | L98-L152] We should demonstrate the branches that actually occur in the current population rather than pretending the seven final outcomes alone exhaust the visible narrative system.

**Capture the full P03 page for each case**, not cropped narrative-only screenshots. That makes each artifact simultaneously evidence for merchant/scenario selection, request, governed outcome, proposed structure behavior, narrative behavior, funded/nonfunded lifecycle behavior, monitoring, and servicing.

---

# Final P03 alt-text pass

For Power BI, go to each visual's **Format visual → General → Properties → Alt text**. Where I identify an existing dynamic measure, use **fx → Format style: Field value → R1Measures → specified measure**. Do not paste the measure name as literal text.

| Visual | Alt-text treatment |
|---|---|
| **Page title — Merchant Application & Account Journey** | **Static:** `Merchant Application and Account Journey. Interactive view of the selected synthetic merchant and scenario from application request through governed decision, funded-account monitoring, and servicing.` |
| **Left merchant-profile KPI/card area** | **Static:** `Merchant profile for the selected merchant, including industry, size tier, annual sales range, relationship stage, relationship quality, prior advances, and prior funded amount.` |
| **Merchant request** | **Static:** `Merchant request for the selected application and scenario, including application date, requested amount, use of funds, acquisition channel, requested remittance rate, payback multiple, payoff horizon, and total repayment.` |
| **Proposed structure** | **Dynamic:** bind **`R26 P03 Selected Structure Alt Text`**. This is the current accessibility measure specifically built to describe the governed selected amount, remittance rate, payback multiple, horizon, and repayment—or state that no governed selected structure exists. [export reference: filecite | turn90file2 | L139-L191] |
| **Decision class card** | **Static:** `High-level governed decision class for the selected merchant and scenario: Authorized, Review, or Declined.` |
| **Decision label card** | **Dynamic:** bind **`R26 P03 Decision Tile Alt Text`**. It reports the governed decision class and business-facing outcome label and appends the candidate-search summary where applicable. [export reference: filecite | turn90file0 | L1-L25] |
| **Narratives area** | **Dynamic:** bind **`R26 P03 Narrative Alt Text`**. Do this on the visual/container that represents the narrative section, rather than repeating it on all three narrative cards. It concatenates Merchant operating evidence, Structure assessment, and Decision rationale in screen-reader order. [export reference: filecite | turn83file3 | L265-L281] |
| **Account performance** | **Static:** `Account performance across the funded synthetic account lifecycle. The chart shows remaining receivable and remittance pace by monitoring date. Tooltips provide monitoring status, remitted to date, expected to date, and cumulative shortfall. Nonfunded application-scenarios have no account-performance series.` |
| **Monitoring journey** | **Static:** `Monitoring journey across the funded synthetic account lifecycle. The chart shows governed monitoring status by monitoring date from Paid off through Dormant or no remittance. Tooltips provide monitoring status, primary alert family, daily shortfall alert, remittance pace, cumulative shortfall, days since remittance, operational alert-family count, and raw alert-condition count. Nonfunded application-scenarios have no monitoring journey.` |
| **Servicing & intervention** | **Dynamic:** bind **`R26 P03 Servicing Alt Text`**. It is already lifecycle-aware: nonfunded paths explicitly report that no funded-account servicing/intervention evidence exists; funded paths describe intervention, action, queue, exposure, and reason. [export reference: filecite | turn90file1 | L70-L94] |

### Two accessibility details I recommend

For the **Decision class** and **Decision label** cards, don't bind `R26 P03 Decision Tile Alt Text` to both. That would make a screen reader announce substantially the same decision twice. Use the short static description on Decision class and the full dynamic measure on Decision label.

Likewise, don't bind `R26 P03 Narrative Alt Text` independently to all three narrative visuals. The measure deliberately combines all three sections in the logical order **Merchant operating evidence → Structure assessment → Decision rationale**. [export reference: filecite | turn83file3 | L265-L281] Use it once on the logical narrative group/carrier; for the individual narrative visuals, either leave redundant alt text off if Power BI permits that cleanly, or use concise static purpose descriptions rather than repeating the complete narrative three times.

This 18-case capture set plus the final accessibility pass will give P03 a much stronger evidence package than the minimum seven-outcome requirement, while still being bounded and purposeful.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c3d5b147-46fe-4f7a-8fc0-8d8601dd004c"></a>
## Andrew / user · C118-M00042

C118-M00042 · 2026-09-03T16:21:31.983000-04:00 · active path

Preceding visible parent: [C118-M00041](part-03.md#m-9a58a7b4-a835-4748-9068-c77e2ef89aa4)

<!-- BEGIN_SOURCE_MESSAGE -->
updated temporal boundary / interpretation boundary write-up for P03?
<!-- END_SOURCE_MESSAGE -->


<a id="m-935a2ed0-f0b8-407c-9b68-fea2cc68a9f4"></a>
## Assistant · C118-M00043

C118-M00043 · 2026-09-03T16:21:58.061636-04:00 · active path

Preceding visible parent: [C118-M00042](part-03.md#m-c3d5b147-46fe-4f7a-8fc0-8d8601dd004c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The old P03 boundary language should be updated now that the page is explicitly combining **decision-time application evidence with the R26 funded lifecycle, monitoring journey, and servicing evidence**. P03 still displays the source-cutoff control, but the current page can legitimately show synthetic lifecycle dates after that cutoff. [export reference: filecite | turn91file2 | L37-L47] The successor evidence also establishes that funded lifecycle exists only for authorized paths, while review/decline paths must have zero lifecycle rows. [export reference: filecite | turn83file3 | L347-L363]

I recommend replacing the existing P03 footer boundary text with this:

> **Temporal boundary:** Decision-time source evidence is anchored to the 2026-07-23 observed-source cutoff. Authorized synthetic accounts may subsequently show modeled funding, monitoring, servicing, and payoff activity through the governed lifecycle horizon ending 2026-11-22. Dates after the source cutoff are synthetic forward lifecycle evidence, not later-observed merchant facts.

> **Interpretation boundary:** Deterministic synthetic portfolio. Baseline and Recession Energy are alternative governed scenarios for the same application—not forecasts, sequential states, or actual merchant outcomes. Decisions, proposed structures, narratives, lifecycle, monitoring, and servicing reflect the certified R26 simulation; only authorized funded paths have downstream account-lifecycle evidence. Review and decline paths do not imply funding or subsequent account performance.

That is the version I would use on the physical P03 page.

A few reasons the wording is important:

- **“Observed-source cutoff” cannot mean “nothing on the page may occur after July 23.”** P03's lifecycle is intentionally synthetic-forward. For example, merchant 738 Baseline is governed approved and physically funded July 25, while its Recession Energy path is an evidence decline with no lifecycle row. [export reference: filecite | turn82file1 | L8-L14]
- The R26 QA explicitly enforces **one lifecycle row for an authorized outcome and zero lifecycle rows for a nonauthorized outcome**. [export reference: filecite | turn83file3 | L347-L363]
- The broader Power BI temporal control establishes **2026-11-22 as the evidence endpoint**, with no post-evidence carry-forward beyond it. [export reference: filecite | turn92file14 | L475-L485] [export reference: filecite | turn92file14 | L526-L541]
- The interpretation language should prevent a reader from treating **Recession Energy as “what happens later”** to the Baseline account. P03 is scenario-isolated at application-scenario grain; it must not leak Baseline facts into Recession Energy or infer funding merely from authorization. [export reference: filecite | turn77file10 | L1074-L1089]

If you need a **shortened footer version** because the current P03 text box is tight, I would use:

> **Temporal boundary:** Source evidence through 2026-07-23; later funding and account activity through 2026-11-22 are governed synthetic-forward lifecycle evidence, not later-observed merchant facts.  
> **Interpretation boundary:** Deterministic synthetic portfolio. Baseline and Recession Energy are alternative scenarios, not forecasts or sequential states; only authorized funded paths have downstream lifecycle, monitoring, and servicing evidence.

I prefer the **full version for P03** if it fits. It is materially clearer than the old generic boundary statement now that P03 tells the complete application-to-account story.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9f608bea-1d65-4f85-8857-bc2dee00bfac"></a>
## Andrew / user · C118-M00044

C118-M00044 · 2026-09-03T16:23:04.966000-04:00 · active path

Preceding visible parent: [C118-M00043](part-03.md#m-935a2ed0-f0b8-407c-9b68-fea2cc68a9f4)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: e9af2630-99c0-469f-aa67-c7bd31e0638e.png

<!-- BEGIN_SOURCE_MESSAGE -->
those are super long. we have two lines to fit both: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-88b55e39-0663-4202-a370-7de1bfbf2364"></a>
## Assistant · C118-M00045

C118-M00045 · 2026-09-03T16:23:10.756169-04:00 · active path

Preceding visible parent: [C118-M00044](part-03.md#m-9f608bea-1d65-4f85-8857-bc2dee00bfac)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. For this footer, I would compress them to:

**Temporal boundary:** Source evidence through 2026-07-23; later lifecycle activity through 2026-11-22 is governed synthetic-forward evidence, not later-observed history.  
**Interpretation boundary:** Deterministic synthetic evidence; Baseline and Recession Energy are alternative scenarios, not forecasts or sequential states.

That preserves the two most important controls without overwhelming the page.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0d5da717-c26f-4963-836b-2e69334b90f5"></a>
## Andrew / user · C118-M00046

C118-M00046 · 2026-09-03T16:29:29.579000-04:00 · active path

Preceding visible parent: [C118-M00045](part-03.md#m-88b55e39-0663-4202-a370-7de1bfbf2364)

<!-- BEGIN_SOURCE_MESSAGE -->
there is no visual container narratives section. they are three distinct tables. please provide alt text for each narrative section.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bb651034-e2e3-4d9b-975b-60a8eb1857f5"></a>
## Assistant · C118-M00047

C118-M00047 · 2026-09-03T16:29:31.746301-04:00 · active path

Preceding visible parent: [C118-M00046](part-03.md#m-0d5da717-c26f-4963-836b-2e69334b90f5)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. Since the three narratives are **three distinct table visuals**, each should have its own concise alt text describing that visual's purpose. We should **not** use the combined `R26 P03 Narrative Alt Text` on each one because that would cause substantial repetition.

Use:

- **Merchant operating evidence:**  
  `Explains the operating and verification evidence available for the selected merchant and scenario, including relevant sales, liquidity, payment, and evidence-quality observations.`

- **Risk & economics assessment:**  
  `Explains how the requested structure was evaluated for the selected merchant and scenario, including alternative structures, modeled economics, policy constraints, and the basis for the selected or supportable structure.`

- **Decision:**  
  `Explains the governed final decision for the selected merchant and scenario, including authorization, review, or decline rationale and whether funding occurred.`

These are deliberately **static purpose descriptions**, rather than repeating the visible narrative verbatim. The screen reader can then encounter the actual table content after understanding what each section represents.

I would use these three and **not bind `R26 P03 Narrative Alt Text` to any of the individual narrative tables**. The combined measure can remain in the model as an accessibility/support artifact, but the physical P03 layout is better served by distinct alt text for each actual visual.
<!-- END_SOURCE_MESSAGE -->


<a id="m-287b70f2-710a-4613-bbe2-3cb7cc4e11a2"></a>
## Andrew / user · C118-M00048

C118-M00048 · 2026-09-03T16:32:04.608000-04:00 · active path

Preceding visible parent: [C118-M00047](part-03.md#m-bb651034-e2e3-4d9b-975b-60a8eb1857f5)

<!-- BEGIN_SOURCE_MESSAGE -->
should this say proposed structure instead of selected? our subtitle ok?  Follow synthetic merchant applications from request through evidence, governed decision and selected structure; funded paths continue through performance, monitoring and servicing.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-c5a1c268-e49e-482c-b2be-b4d17e2204fe"></a>
## Assistant · C118-M00049

C118-M00049 · 2026-09-03T16:32:06.633143-04:00 · active path

Preceding visible parent: [C118-M00048](part-03.md#m-287b70f2-710a-4613-bbe2-3cb7cc4e11a2)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **“Proposed structure” is better than “selected structure” in the subtitle.**

“Selected structure” is technically meaningful inside the strategy engine, but on P03 it can imply that the structure has been authorized. That is not true for cases such as **Counteroffer review**, where P03 displays a review-eligible proposed structure that has **not** been authorized. Your 082 example demonstrates exactly that distinction.

I would use:

> **Follow synthetic merchant applications from request through evidence, governed decision and proposed structure; funded paths continue through performance, monitoring and servicing.**

I think the rest of the subtitle is strong. It accurately communicates the page's left-to-right story and, importantly, **“funded paths continue”** makes clear that downstream account performance is conditional on actual governed funding.

One tiny stylistic option is adding the Oxford comma:

> **Follow synthetic merchant applications from request through evidence, governed decision, and proposed structure; funded paths continue through performance, monitoring, and servicing.**

**I prefer this final version.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-ec198197-9f20-4674-90a3-4d0e5096882f"></a>
## Andrew / user · C118-M00050

C118-M00050 · 2026-09-03T16:38:25.255000-04:00 · active path

Preceding visible parent: [C118-M00049](part-03.md#m-c5a1c268-e49e-482c-b2be-b4d17e2204fe)

**Editorial record note:** 6 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 2dc0eba5-de3e-4b09-8db5-215db4df5576.png; 0e190743-c7cf-4cf1-8ec0-d243e77c8d52.png; 398b38f5-bc8a-4f07-afc6-867900bf2b81.png; b6f78905-d40e-499a-8a33-00a551d9b6dc.png; 63de6190-ac83-4826-8578-a9b3630102f4.png; 56398611-92e9-4bdf-b7e1-5405c12e27b4.png

<!-- BEGIN_SOURCE_MESSAGE -->
I have completed P03 and all that is left is to capture evidence. I have to run an errand. I will capture P03 evidence when I return. In the meantime, please proceed with a P04 step by step to-do list. Here is the current P04. Note, this is where we left off previously before going back to remediation/correction. When evaluating the P04 to-do. let's determine the story we have told so far and what story we want to tell on this tab. Does the current set-up accomplish that story? Do we need to alter the current set-up? Remove/add/etc. Please evaluate and provide a detailed roadmap for us to follow. Lean on our source of truth and process for this exercise.  Current P04: 
<!-- END_SOURCE_MESSAGE -->
