# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 03 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-02.md)
[Next part](part-04.md)

<a id="m-03d7d27f-3f25-4337-a865-a31c783c0e66"></a>
## Assistant · C109-M00059

C109-M00059 · 2026-08-25T14:46:06.975012-04:00 · active path

Preceding visible parent: [C109-M00058](part-02.md#m-5209179e-ca90-4a5b-9293-9f3a1735b1c3)

<!-- BEGIN_SOURCE_MESSAGE -->
That works. **Freeze OBJ-002.** This is substantially better: all five values are visible, the exact Source release identifier is preserved, there is no clipping, and removing the tile chrome makes it read as an executive metadata strip rather than a set of mini-cards.

The header now has a good information hierarchy. I would not spend more time polishing it until whole-page UAT.

## 1. **Controlling state**

```text
P01-OBJ-001   COMPLETE
P01-OBJ-002   COMPLETE — source-owner construction
Measures      67 after P01 compatibility patch
Page          1
Containers    2 of 14
```

OBJ-002 now successfully displays:

```text
Run              M1_V0_2_BASELINE_BUILD
Source release   MSBF_PBI_SOURCE_SELECTION_R3_20260816
Model version    PBI_A1A_MODEL_R1_20260818
Source cutoff    2026-07-23
Observation as of
                 2026-11-22
```

## 2. **Action or decision — P01-OBJ-003**

Proceed to the **Scenario slicer**.

Because the header now occupies more vertical space, I'm establishing a revised slicer band beginning at **Y=124** rather than trying to preserve the obsolete Y=82 coordinate.

### Insert the slicer

1. Click blank canvas.
2. Insert the native **Slicer** visual.
3. Set:

```text
X       24
Y       124
Width   280
Height  52
```

### Add the exact field

Search the Data pane for:

```text
scenario_code
```

Add exactly:

```text
DimScenario[scenario_code]
```

to the slicer's **Field** well.

No measure and no hierarchy.

### Configure selection behavior

In **Format visual → Visual → Slicer settings / Selection**, configure:

```text
Style                 Dropdown
Single select         On
Select all            Off
Multi-select          Off
Search                Off
```

If your August 2026 build uses slightly different labels, the behavioral requirement is simple: **exactly one scenario must be selected at a time**.

### Set the slicer title

Use:

```text
Scenario
```

Do not expose the technical field name `scenario_code` as the user-facing title.

Start with approximately:

```text
Title       9–10 pt Semibold
Value       10 pt
Background  Off
Border      subtle/off
Shadow      Off
```

### Establish the required default

Select:

```text
BASELINE
```

The page's governed default requires a single `BASELINE` scenario.

### Exact alt text

Set:

```text
Scenario selector. Single-select control with BASELINE as the default scenario.
```

## 3. **Evidence**

OBJ-003 should ultimately resolve as:

```text
P01-OBJ-003
Purpose          Scenario slicer
Native type      Slicer
Field            DimScenario[scenario_code]

X                24
Y                124
W                280
H                52

Style            Dropdown
Single select    Yes
Default          BASELINE
```

Later, the interaction batch will make this slicer filter analytical objects while preserving the audit-corrected exceptions for stable governance/context elements.

## 4. **Holds and non-regression**

Don't configure **Edit interactions** yet. We'll do all four slicers together after OBJ-006 exists and then complete the broader matrix once all 14 containers exist.

Don't add page-level filters, synced slicers, bookmarks, or another scenario-control object.

The compatibility measures and header redesign are now logged deviations for the eventual Audit return; we are not reopening them during ordinary construction.

## 5. **Exact next action**

**Save the completed header first.**

Then create `P01-OBJ-003` at **24 / 124 / 280 / 52**, bind it to `DimScenario[scenario_code]`, configure it as a **single-select dropdown**, and select **BASELINE**.

Send me a screenshot of OBJ-003 once populated. We'll verify it quickly and proceed directly to **OBJ-004 — Observation-date slicer**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f528b2c8-3ecb-41cf-97cc-94b6e823e0bb"></a>
## Andrew / user · C109-M00060

C109-M00060 · 2026-08-25T14:52:55.133000-04:00 · active path

Preceding visible parent: [C109-M00059](part-03.md#m-03d7d27f-3f25-4337-a865-a31c783c0e66)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 36d5e0f5-c620-4607-a779-122e65572035.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-954136c0-e068-4ddd-b6fa-27bd2f56cf30"></a>
## Assistant · C109-M00061

C109-M00061 · 2026-08-25T14:52:55.533452-04:00 · active path

Preceding visible parent: [C109-M00060](part-03.md#m-f528b2c8-3ecb-41cf-97cc-94b6e823e0bb)

<!-- BEGIN_SOURCE_MESSAGE -->
`P01-OBJ-003` looks good. **Freeze it.** The dropdown is compact, `BASELINE` is clearly visible, the label hierarchy works, and the revised Y=124 slicer band has appropriate separation from the header.

One minor observation: OBJ-001 is selected in the screenshot, which explains its outline/visual-header controls. That's not a design issue.

## 1. **Controlling state**

```text
P01-OBJ-001    COMPLETE
P01-OBJ-002    COMPLETE
P01-OBJ-003    COMPLETE

Scenario       BASELINE
Containers     3 / 14
Measures       67
```

Proceed to `P01-OBJ-004 — Observation-date slicer`.

## 2. **Action or decision — build OBJ-004**

### Insert the slicer

Insert another native **Slicer**.

Use:

```text
X       320
Y       124
Width   280
Height  52
```

This gives us a consistent 16 px horizontal gap from OBJ-003:

```text
OBJ-003 ends at X=304
OBJ-004 begins at X=320
```

### Bind the exact field

Search for:

```text
as_of_date
```

Use exactly:

```text
DimAsOfDate[as_of_date]
```

Do **not** use `[Selected As Of Date]` here. That's the measure used for display/context; the slicer itself needs the dimension column.

If Power BI automatically creates a **Date hierarchy**, use the dropdown on the field in the slicer's field well and select the raw:

```text
as_of_date
```

rather than `Date hierarchy`.

### Configure it as a dropdown

Use the same basic style as Scenario:

```text
Style            Dropdown
Single select    On
Select all       Off
Multi-select     Off
Search           Off
```

User-facing title:

```text
Observation date
```

### Establish the governed default

Select exactly:

```text
2026-11-22
```

This is important because your header already confirms that `[Selected As Of Date]` currently evaluates to `2026-11-22`.

Once OBJ-004 is populated, changing this slicer should dynamically change the header's:

```text
Observation as of
```

value. That gives us an early functional check of the explicit context architecture.

### Date display

Prefer:

```text
2026-11-22
```

rather than a long localized date such as:

```text
Sunday, November 22, 2026
```

If Desktop automatically displays `11/22/2026`, **don't change the semantic column's formatting yet** merely for the slicer. We'll decide whether report-level formatting is sufficient.

### Alt text

Use:

```text
Observation-date selector. Single-select control with November 22, 2026 as the default observation date.
```

## 3. **Evidence**

OBJ-004 target state:

```text
P01-OBJ-004
Purpose          Observation-date slicer
Native type      Slicer
Field            DimAsOfDate[as_of_date]

X                320
Y                124
W                280
H                52

Style            Dropdown
Single select    Yes
Default          2026-11-22
```

### Quick functional test

After setting the default to `2026-11-22`, temporarily select **one different available observation date**.

Watch OBJ-002.

Expected behavior:

```text
Observation as of
→ changes to the selected date
```

Then immediately restore:

```text
2026-11-22
```

If the header changes and restores correctly, we have direct evidence that the observation-date context is functioning.

Do not test Scenario interactions yet.

## 4. **Holds and non-regression**

Do not add:

- relative-date behavior;
- between/range selection;
- date hierarchy;
- synchronized slicers;
- page filters;
- bookmarks.

Also don't configure Edit interactions yet. The final matrix specifically requires the observation-date slicer to filter OBJ-002, so its default Power BI interaction with the context card is useful for now.

## 5. **Exact next action**

Create `P01-OBJ-004` at **320 / 124 / 280 / 52**, bind raw `DimAsOfDate[as_of_date]`, configure single-select dropdown, and select **2026-11-22**.

Perform the one-date-change test against OBJ-002 and restore `2026-11-22`.

Then send me a screenshot showing **OBJ-003 + OBJ-004 and the header**. We'll proceed directly to `P01-OBJ-005 — Industry slicer`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ecc3f838-646f-498e-aac6-a0c2804fb5e4"></a>
## Andrew / user · C109-M00062

C109-M00062 · 2026-08-25T14:55:23.082000-04:00 · active path

Preceding visible parent: [C109-M00061](part-03.md#m-954136c0-e068-4ddd-b6fa-27bd2f56cf30)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 9b647eda-d616-4322-a968-efb84634d2da.png

<!-- BEGIN_SOURCE_MESSAGE -->
I do not see DimAsOfDate
<!-- END_SOURCE_MESSAGE -->


<a id="m-447b3a8e-743e-4bc1-9d7d-e78556bb1bbc"></a>
## Assistant · C109-M00063

C109-M00063 · 2026-08-25T14:55:23.575519-04:00 · active path

Preceding visible parent: [C109-M00062](part-03.md#m-ecc3f838-646f-498e-aac6-a0c2804fb5e4)

<!-- BEGIN_SOURCE_MESSAGE -->
Good catch. **Do not use either `DimApplication[as_of_date]` or `DimRunCampaign[as_of_date]` yet.** My instruction naming `DimAsOfDate` was incorrect; your physical model clearly does not expose that table.

The important question is which existing `as_of_date` the audited P01 catalog actually authorizes for OBJ-004. I should not infer that from the field names.

### Controlling state
`P01-OBJ-003` remains complete. `P01-OBJ-004` has **not** been bound to a field, so no corrective action is needed.

### Action or decision
Stop OBJ-004 at the empty-slicer stage. Do not drag either visible `as_of_date` into it yet.

Given the model structure visible in your screenshot, `DimRunCampaign[as_of_date]` is a plausible candidate because OBJ-002's governed run context includes the selected as-of date—but “plausible” is not sufficient for this controlled build.

### Evidence
Your Data pane establishes only two matching fields:

```text
DimApplication[as_of_date]
DimRunCampaign[as_of_date]
```

There is no visible `DimAsOfDate`, so my previous field specification cannot be followed as written.

### Holds and non-regression
No new date dimension, calculated column, relationship, or helper table. We already allowed narrowly justified semantic measures; there is no reason to manufacture an entire date dimension before checking the physical catalog/model.

### Exact next action
**Leave OBJ-004 empty for the moment.** I will reconcile the physical P01 field catalog/model inventory for the authorized observation-date field before we bind it.
<!-- END_SOURCE_MESSAGE -->


<a id="m-14e3b32e-8f9e-48e2-9098-5164795516b9"></a>
## Andrew / user · C109-M00064

C109-M00064 · 2026-08-25T14:56:21.714000-04:00 · active path

Preceding visible parent: [C109-M00063](part-03.md#m-447b3a8e-743e-4bc1-9d7d-e78556bb1bbc)

<!-- BEGIN_SOURCE_MESSAGE -->
reconcile the physical P01 field catalog/model inventory for the authorized observation-date field before we bind it.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-d2916726-fcf9-4252-8da3-deff33bfd451"></a>
## Assistant · C109-M00065

C109-M00065 · 2026-08-25T14:56:58.408282-04:00 · active path

Preceding visible parent: [C109-M00064](part-03.md#m-14e3b32e-8f9e-48e2-9098-5164795516b9)

<!-- BEGIN_SOURCE_MESSAGE -->
Reconciled. The physical P01 catalog and accepted A3 `model.bim` are internally consistent. **`DimAsOfDate` does exist.** The reason you did not see it is that your Data-pane search was for `as_of_date`, while the authorized column is named **`AsOfDate`**—no underscores.

I also found one earlier construction error we should correct now: **OBJ-003 is authorized against `DimScenario[ScenarioLabel]`, not `DimScenario[scenario_code]`.** My earlier instruction used the wrong scenario field.

## 1. **Controlling state**

The exact physical P01 construction worksheet specifies:

```text
P01-OBJ-003
Field: DimScenario[ScenarioLabel]
Display label: Scenario
Single select
Default: BASELINE
```

and:

```text
P01-OBJ-004
Field: DimAsOfDate[AsOfDate]
Display label: Observation as of
Single select
Default: 2026-11-22
```

The accepted A3 physical `model.bim` contains `DimAsOfDate` with these nine columns:

```text
AsOfDate
Year
Quarter
MonthNumber
MonthName
MonthYear
IsEvidenceEndpoint
IsSourceRunAsOf
IsDefaultAsOf
```

The model inventory also records `DimAsOfDate` as a nine-column A1a table. So this is **not** a missing-model-object problem.

## 2. **Action or decision**

### First, correct OBJ-003

Select the existing Scenario slicer.

Remove:

```text
DimScenario[scenario_code]
```

Search the Data pane for:

```text
ScenarioLabel
```

and bind exactly:

```text
DimScenario[ScenarioLabel]
```

Keep:

```text
Title          Scenario
Single select  On
Default        BASELINE
```

The visible result may still simply say `BASELINE`; that's fine. The important correction is the underlying field.

### Then build OBJ-004

Clear the Data-pane search completely and search:

```text
AsOfDate
```

**Do not search `as_of_date`.**

You should see:

```text
DimAsOfDate
    AsOfDate
```

Use exactly that field:

```text
DimAsOfDate[AsOfDate]
```

If checking the box causes Power BI to choose an undesirable date hierarchy, drag `AsOfDate` directly into the slicer's field well and select the raw **AsOfDate**, not Date Hierarchy.

For our revised physical layout, use:

```text
P01-OBJ-004

X       320
Y       124
Width   280
Height  52

Title          Observation as of
Style          Dropdown
Single select  On
Select all     Off
Default        2026-11-22
```

The exact authorized alt text from R12 is:

```text
Observation date slicer. Single selection required. Default is November 22, 2026.
```

## 3. **Evidence**

The reconciliation establishes three distinct date concepts in the model:

```text
DimAsOfDate[AsOfDate]
→ governed disconnected observation-date controller
→ USE FOR OBJ-004

DimRunCampaign[as_of_date]
→ run metadata
→ DO NOT substitute for OBJ-004

DimApplication[as_of_date]
→ application-grain date
→ DO NOT substitute for OBJ-004
```

That distinction matters. The source design describes `DimAsOfDate` as a **disconnected dimension generated from the source-run date through the maximum evidence date**, specifically intended as the selectable observation date and single-select controller for latest-on-or-before measures.

The R12 re-performance explicitly records:

```text
P01-OBJ-004
DimAsOfDate[AsOfDate]
PASS
```

So there is no ambiguity left.

## 4. **Holds and non-regression**

Do **not** create another date dimension or use either of the `as_of_date` columns visible in your previous search.

Also, we should correct OBJ-003 now rather than knowingly carry the wrong field farther into construction.

Our source-owner deviations remain limited to the intentional current-Card compatibility measures and physical header redesign; **OBJ-003/004 should use their exact cataloged semantic fields.**

## 5. **Exact next action**

First change OBJ-003 from:

```text
DimScenario[scenario_code]
```

to:

```text
DimScenario[ScenarioLabel]
```

Then clear the Data search and search **`AsOfDate`**. Bind `P01-OBJ-004` to:

```text
DimAsOfDate[AsOfDate]
```

Select **2026-11-22** and send me the resulting screenshot showing both slicers and the header.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5fc5e571-8416-44f9-bf30-4c2dd5a9e512"></a>
## Andrew / user · C109-M00066

C109-M00066 · 2026-08-25T15:10:25.079000-04:00 · active path

Preceding visible parent: [C109-M00065](part-03.md#m-d2916726-fcf9-4252-8da3-deff33bfd451)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 53123f5e-91b8-404e-afdc-3197051e9007.png

<!-- BEGIN_SOURCE_MESSAGE -->
do we have height and width backwards? 
<!-- END_SOURCE_MESSAGE -->


<a id="m-9fa38c36-11fe-4384-acbf-c9bae1ce6b66"></a>
## Assistant · C109-M00067

C109-M00067 · 2026-08-25T15:10:25.291168-04:00 · active path

Preceding visible parent: [C109-M00066](part-03.md#m-5fc5e571-8416-44f9-bf30-4c2dd5a9e512)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **They are backwards.** Your screenshot makes that unambiguous.

I told you:

```text
Width   280
Height   52
```

but your Properties pane currently shows:

```text
Height  280
Width    52
```

which is why OBJ-004 is a tall, narrow strip.

Correct it to:

```text
P01-OBJ-004

Horizontal / X    320
Vertical / Y      124
Width             280
Height             52
```

After that it should have the same horizontal form factor as the Scenario slicer immediately to its left.

Also, the `7/23/...` visible in the malformed slicer suggests the field is populated, but **don't worry about selecting the default until the geometry is corrected**.

### Controlling state
OBJ-001 through OBJ-003 remain intact. OBJ-004 has the correct position but transposed dimensions.

### Action or decision
Swap **Height 280 → 52** and **Width 52 → 280**. No other change.

### Evidence
Your screenshot directly confirms `Height=280`, `Width=52`, `Horizontal=320`, `Vertical=124`.

### Holds and non-regression
No semantic/model correction is implicated. This is only a visual geometry-entry error.

### Exact next action
Set **Height = 52, Width = 280**, then select **2026-11-22** in the observation-date slicer. Send the resulting screenshot; we'll verify the two-slicer row and continue to OBJ-005.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7a6b939f-4f14-480b-99fa-bdd530fef1aa"></a>
## Andrew / user · C109-M00068

C109-M00068 · 2026-08-25T15:12:02.425000-04:00 · active path

Preceding visible parent: [C109-M00067](part-03.md#m-9fa38c36-11fe-4384-acbf-c9bae1ce6b66)

<!-- BEGIN_SOURCE_MESSAGE -->
AsOfDate seems like a bad title for this - recommendations
<!-- END_SOURCE_MESSAGE -->


<a id="m-bb4b972f-0229-41e4-95f4-2cc2fa2130b2"></a>
## Assistant · C109-M00069

C109-M00069 · 2026-08-25T15:12:02.597264-04:00 · active path

Preceding visible parent: [C109-M00068](part-03.md#m-7a6b939f-4f14-480b-99fa-bdd530fef1aa)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. **`AsOfDate` is a model field name, not an executive-facing label.** We should not expose it on the page.

For this slicer, my recommendation is **Observation date**.

The alternatives I considered are:

- **Observation date** — **best choice**. Clear to an executive user and matches the page's governing language: “selected scenario and observation date.”
- **Portfolio as of** — more business-friendly, but could be mistaken for a financial reporting cutoff.
- **Evidence through** — useful governance terminology, but misleading because the selected observation date is not necessarily the source/evidence cutoff.
- **Analysis date** — understandable but less precise.
- **As of date** — common BI language, but ambiguous given that the page separately displays **Source cutoff**.
- **Observation as of** — this was the original catalog label, but I prefer it for the context card; as a slicer label it reads awkwardly.

So I recommend this deliberate presentation distinction:

```text
OBJ-002 context value:
Observation as of
2026-11-22

OBJ-004 control:
Observation date
[2026-11-22 ▼]
```

That communicates **current resulting context** versus **the control used to select it**.

You can change the slicer's visible title without renaming `DimAsOfDate[AsOfDate]` in the semantic model.

### Controlling state
OBJ-004 remains bound to the governed `DimAsOfDate[AsOfDate]`; only its executive-facing presentation label is being refined.

### Action or decision
Use **Observation date** as the slicer title. Do not expose `AsOfDate`.

### Evidence
This also aligns directly with P01's primary question and subtitle, both of which use the term **observation date**.

### Holds and non-regression
Underlying field remains `DimAsOfDate[AsOfDate]`. No semantic rename or model change.

### Exact next action
Set the OBJ-004 title to **Observation date**, retain `280 × 52` at `X=320 / Y=124`, and select **2026-11-22**. Then we can proceed to OBJ-005.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cc2270ed-dd11-4d99-81f3-b801887c00fb"></a>
## Andrew / user · C109-M00070

C109-M00070 · 2026-08-25T15:13:25.062000-04:00 · active path

Preceding visible parent: [C109-M00069](part-03.md#m-bb4b972f-0229-41e4-95f4-2cc2fa2130b2)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 0fe188a3-0566-4b59-8f6f-58fe6669984c.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-170b9d8c-53f2-4c9b-a091-16bcc4d4d3ff"></a>
## Assistant · C109-M00071

C109-M00071 · 2026-08-25T15:13:25.726878-04:00 · active path

Preceding visible parent: [C109-M00070](part-03.md#m-cc2270ed-dd11-4d99-81f3-b801887c00fb)

<!-- BEGIN_SOURCE_MESSAGE -->
The header is now strong. Scenario also looks right. **OBJ-004 needs one correction before we freeze it:** it is currently rendering as a **Between/range date slicer**, not the required single-date selector. The two boxes (`7/23/2026` and `11/22/2026`) are the range endpoints.

## 1. **Controlling state**

```text
OBJ-001   COMPLETE
OBJ-002   COMPLETE
OBJ-003   COMPLETE
OBJ-004   correct field / geometry, wrong slicer mode
```

The screenshot shows `Baseline` rather than the technical scenario code, which is consistent with our correction to `DimScenario[ScenarioLabel]`.

## 2. **Action or decision**

For OBJ-004, change the slicer from **Between** to **Dropdown**.

Select the Observation date slicer, then go to:

**Format visual → Visual → Slicer settings → Options**

Change:

```text
Style
Between → Dropdown
```

Depending on this Desktop build, you may also be able to use the slicer's visual-header menu to change the slicer type.

Then under **Selection** configure:

```text
Single select       On
Select all          Off
```

The finished control should look approximately like:

```text
Observation date
[ 11/22/2026                         ▼ ]
```

rather than:

```text
Observation date
[7/23/2026] [11/22/2026]
```

Select only **11/22/2026**.

### Date presentation

`11/22/2026` is acceptable for now. I would prefer `2026-11-22` eventually because it matches the governance context above, but **do not change the semantic column's format just for that**. We can revisit presentation during page polish.

## 3. **Evidence**

Once corrected, we have a useful functional test.

OBJ-002 currently says:

```text
Observation as of
2026-11-22
```

After OBJ-004 is a single-select dropdown:

1. choose another available date;
2. verify OBJ-002's **Observation as of** changes to that date;
3. restore `11/22/2026`;
4. verify OBJ-002 returns to `2026-11-22`.

That will establish the observation controller is actually driving the intended measure.

## 4. **Holds and non-regression**

Do not leave OBJ-004 as a range slicer. P01 is defined around **one selected observation date**, and a range would materially alter the semantics of the page.

Everything else visible in this screenshot can remain.

## 5. **Exact next action**

Change **Observation date → Dropdown + Single select**, select only **11/22/2026**, perform the one-date-change/restore test against OBJ-002, and save.

If that passes, consider **OBJ-004 complete** and proceed directly to `P01-OBJ-005 — Industry slicer`; I can give you its exact construction next.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3c2c40f4-edd3-41ce-b615-eb9f4ef6de36"></a>
## Andrew / user · C109-M00072

C109-M00072 · 2026-08-25T15:14:50.071000-04:00 · active path

Preceding visible parent: [C109-M00071](part-03.md#m-170b9d8c-53f2-4c9b-a091-16bcc4d4d3ff)

<!-- BEGIN_SOURCE_MESSAGE -->
If we use drop down, then the width probably doesn't need as much room
<!-- END_SOURCE_MESSAGE -->


<a id="m-264a2c67-6236-475d-89fe-575ed0c73b11"></a>
## Assistant · C109-M00073

C109-M00073 · 2026-08-25T15:14:50.204675-04:00 · active path

Preceding visible parent: [C109-M00072](part-03.md#m-3c2c40f4-edd3-41ce-b615-eb9f4ef6de36)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. Once OBJ-004 becomes a single-select dropdown, **280 px is unnecessarily wide**. We should use the recovered horizontal space rather than preserve a dimension designed around the original layout.

I would actually redesign the entire four-slicer row now so it is balanced before we build OBJ-005/006.

### Recommended slicer band

Use:

| Object | Control | X | Y | W | H |
|---|---|---:|---:|---:|---:|
| OBJ-003 | Scenario | 24 | 124 | **240** | 52 |
| OBJ-004 | Observation date | 280 | 124 | **200** | 52 |
| OBJ-005 | Industry | 496 | 124 | **360** | 52 |
| OBJ-006 | Acquisition source | 872 | 124 | **384** | 52 |

That gives consistent **16 px gaps** and ends at X=1256, preserving the 24 px right margin:

`24 + 240 + 16 + 200 + 16 + 360 + 16 + 384 + 24 = 1280`.

This allocation also follows the likely content requirements: Scenario and Observation date are compact single-select controls; Industry and Acquisition source get more room because their labels/values can be longer.

For OBJ-004, change it to **Dropdown**, then set:

```text
X       280
Y       124
Width   200
Height  52
```

I would also resize OBJ-003 now from 280 → **240 px** at X=24. That gives us a clean foundation for OBJ-005 and OBJ-006 instead of repeatedly moving things later.

### Controlling state
OBJ-001/002 are frozen; OBJ-003 is functionally complete; OBJ-004 has the correct field but still needs conversion from Between → single-select Dropdown.

### Action or decision
Adopt the revised **240 / 200 / 360 / 384** four-slicer layout. This is a better use of the 1280×720 canvas than retaining equal 280 px controls.

### Evidence
The current screenshot shows Scenario already has substantial unused width, while the Between-style date control consumed width only because it displayed two endpoints. A dropdown removes that requirement.

### Holds and non-regression
This is report-layout refinement only. No model/PQ change, additional container, page, or feature.

### Exact next action
Set **OBJ-003 = X24/W240** and **OBJ-004 = X280/W200**, both at `Y124/H52`; convert OBJ-004 to **Dropdown + Single select** and select `11/22/2026`.

Then we can build **OBJ-005 at X496/W360** and **OBJ-006 at X872/W384** without revisiting the slicer-row geometry.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d7a06108-54f2-44a5-be08-5b185dcf043d"></a>
## Andrew / user · C109-M00074

C109-M00074 · 2026-08-25T15:16:50.505000-04:00 · active path

Preceding visible parent: [C109-M00073](part-03.md#m-264a2c67-6236-475d-89fe-575ed0c73b11)

<!-- BEGIN_SOURCE_MESSAGE -->
data sources for industry and acquisition source?
<!-- END_SOURCE_MESSAGE -->


<a id="m-6760f99e-e2d6-4e0a-b29e-bf119218946d"></a>
## Assistant · C109-M00075

C109-M00075 · 2026-08-25T15:16:59.776995-04:00 · active path

Preceding visible parent: [C109-M00074](part-03.md#m-d7a06108-54f2-44a5-be08-5b185dcf043d)

<!-- BEGIN_SOURCE_MESSAGE -->
The exact cataloged fields are:

- **OBJ-005 — Industry:** `DimIndustry[industry_name]`
- **OBJ-006 — Acquisition source:** `DimAcquisitionSource[source_family_name]`

Both are **optional multi-select slicers with the default state clear/no selection**. The approved source propagation is `DimIndustry → DimMerchant → DimApplication` for Industry, and `DimAcquisitionSource → DimApplication` for Acquisition source. [export reference: filecite | turn0file5] [export reference: filecite | turn0file16]

For construction:

```text
P01-OBJ-005
Title        Industry
Field        DimIndustry[industry_name]
Default      Clear / no selection
Selection    Multi-select permitted
X            496
Y            124
W            360
H            52
```

```text
P01-OBJ-006
Title        Acquisition source
Field        DimAcquisitionSource[source_family_name]
Default      Clear / no selection
Selection    Multi-select permitted
X            872
Y            124
W            384
H            52
```

I recommend **Dropdown** for both, consistent with Scenario and Observation date. Unlike those first two slicers, however, **do not turn Single select on** for Industry or Acquisition source. Their governed default is clear, and users may select multiple values.

### Controlling state
Exact P01 catalog fields recovered; no inference is needed.

### Action or decision
Bind OBJ-005 to `DimIndustry[industry_name]` and OBJ-006 to `DimAcquisitionSource[source_family_name]`.

### Evidence
The P01 filter/context catalog specifies both fields, optional multi-select behavior, and default-clear state. [export reference: filecite | turn0file5]

### Holds and non-regression
Do not substitute application-level industry/source columns merely because they may also appear in the Data pane.

### Exact next action
Build **OBJ-005 and OBJ-006 together** at the coordinates above, leave both clear, and send me a screenshot of the completed four-slicer band. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-250d573e-c8cc-429e-bf4e-2f0388cc3e78"></a>
## Andrew / user · C109-M00076

C109-M00076 · 2026-08-25T15:18:28.913000-04:00 · active path

Preceding visible parent: [C109-M00075](part-03.md#m-6760f99e-e2d6-4e0a-b29e-bf119218946d)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 2b2bff1f-9347-47a5-a2e6-cbeac0d0d4b7.png

<!-- BEGIN_SOURCE_MESSAGE -->
even the longest industry name doesn't take up the whole 360 width:
<!-- END_SOURCE_MESSAGE -->


<a id="m-c792d8e0-c7e8-4d7c-9e37-62689b0b7810"></a>
## Assistant · C109-M00077

C109-M00077 · 2026-08-25T15:18:29.109251-04:00 · active path

Preceding visible parent: [C109-M00076](part-03.md#m-250d573e-c8cc-429e-bf4e-2f0388cc3e78)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. **360 px is overallocated to Industry.** The screenshot gives us physical evidence: even `Construction & Skilled Trades`, apparently the longest visible industry label, has substantial unused horizontal space.

We should reclaim it for **Acquisition source**, where longer labels are more likely, and keep the row balanced.

I recommend revising the final slicer geometry to:

| Object | Slicer | X | W |
|---|---|---:|---:|
| OBJ-003 | Scenario | 24 | 240 |
| OBJ-004 | Observation date | 280 | 200 |
| OBJ-005 | Industry | 496 | **280** |
| OBJ-006 | Acquisition source | 792 | **464** |

All remain:

```text
Y = 124
H = 52
```

This preserves 16 px gaps and the 24 px right margin exactly.

Also, your screenshot currently shows Industry **expanded** with `Construction & Skilled Trades` selected. For the finished default state, make sure:

- Style = **Dropdown**
- Default = **clear/no selection**
- Multi-select = permitted
- Visible title = **Industry**, not `industry_name`

### Controlling state
OBJ-005 is functionally bound to the correct `DimIndustry[industry_name]`; its physical test shows W360 is unnecessarily large.

### Action or decision
Reduce OBJ-005 from **W360 → W280** and move OBJ-006 to **X792 / W464**.

### Evidence
The longest visible Industry label fits comfortably within materially less than the current 360 px allocation.

### Holds and non-regression
No semantic or interaction change. Keep Industry multi-select and default-clear.

### Exact next action
Set **Industry = X496/W280** and build **Acquisition source = X792/W464**, both at `Y124/H52`. Then send me the completed four-slicer row; we'll freeze the filter band and move to **OBJ-007 — six-KPI portfolio-posture ribbon**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-289ddfc5-7003-4bbe-b4ff-0704afc4a6b0"></a>
## Andrew / user · C109-M00078

C109-M00078 · 2026-08-25T15:26:59.538000-04:00 · active path

Preceding visible parent: [C109-M00077](part-03.md#m-c792d8e0-c7e8-4d7c-9e37-62689b0b7810)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 26011212-1e07-4b81-a100-deead60a2077.png

<!-- BEGIN_SOURCE_MESSAGE -->
source family name doesn't need that much space: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-3a50834c-b41c-428f-8a16-8a1a948ebc49"></a>
## Assistant · C109-M00079

C109-M00079 · 2026-08-25T15:27:00.288047-04:00 · active path

Preceding visible parent: [C109-M00078](part-03.md#m-289ddfc5-7003-4bbe-b4ff-0704afc4a6b0)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. The physical test shows **both categorical slicers can be substantially narrower**. `Strategic Partner` and `Construction & Skilled Trades` fit comfortably, so allocating 280–464 px to them wastes prime horizontal space.

Rather than merely shrinking them and leaving dead space, I recommend making the four slicers a **balanced control strip**.

### Revised slicer band

| Object | Slicer | X | W |
|---|---|---:|---:|
| OBJ-003 | Scenario | 24 | 240 |
| OBJ-004 | Observation date | 280 | 200 |
| OBJ-005 | Industry | 496 | **280** |
| OBJ-006 | Acquisition source | 792 | **280** |

All:

```text
Y = 124
H = 52
```

This leaves **184 px intentionally unused on the right**. That's preferable to stretching controls merely to fill the canvas. The analytical visuals below can still use the full page width.

I would **not shrink Industry below 280 yet**. It needs to accommodate `Construction & Skilled Trades` plus dropdown padding and scrollbar behavior. Likewise, 280 is generous but sensible for Acquisition source.

Also correct the visible titles before freezing:

```text
industry_name       → Industry
source_family_name  → Acquisition source
```

And clear the test selections:

```text
Scenario             BASELINE
Observation date     11/22/2026
Industry             clear / no selection
Acquisition source   clear / no selection
```

Both Industry and Acquisition source should remain **Dropdown + multi-select permitted**.

### Controlling state
All four slicers now have physically tested fields and representative values. OBJ-005/006 do not require the larger speculative widths we initially reserved.

### Action or decision
Freeze Industry and Acquisition source at **280 px each**. Don't stretch the slicer band artificially across all 1280 px.

### Evidence
The screenshots demonstrate the longest/representative categorical labels fit comfortably at materially less than the earlier allocations.

### Holds and non-regression
No semantic change. Interaction configuration remains deferred until the analytical objects exist.

### Exact next action
Set **OBJ-005 = X496/W280** and **OBJ-006 = X792/W280**, title them **Industry** and **Acquisition source**, clear both test selections, collapse both dropdowns, and save.

Then send the completed four-slicer strip. We'll freeze OBJ-003–006 and move to the much more consequential **OBJ-007 six-KPI portfolio-posture ribbon**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-93d8bf51-7e82-42ff-a455-d0e3548086b9"></a>
## Andrew / user · C109-M00080

C109-M00080 · 2026-08-25T15:30:50.789000-04:00 · active path

Preceding visible parent: [C109-M00079](part-03.md#m-3a50834c-b41c-428f-8a16-8a1a948ebc49)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: fa17458f-bf6e-42c4-9654-cf8b5a570150.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e7020a06-ea74-45b5-ada1-950ff2342937"></a>
## Assistant · C109-M00081

C109-M00081 · 2026-08-25T15:30:51.193337-04:00 · active path

Preceding visible parent: [C109-M00080](part-03.md#m-93d8bf51-7e82-42ff-a455-d0e3548086b9)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a good foundation. **Freeze OBJ-003 through OBJ-006.** The row is visually coherent, and leaving the unused space at right is preferable to stretching controls unnecessarily.

One thing stands out, though: **Observation date currently displays `All`**, whereas the governed default must be one date, `2026-11-22`. Fix that before we proceed: select `11/22/2026` and confirm OBJ-002 still reads `Observation as of = 2026-11-22`.

## 1. **Controlling state**

After that correction:

```text
P01-OBJ-001   COMPLETE
P01-OBJ-002   COMPLETE
P01-OBJ-003   COMPLETE — Baseline
P01-OBJ-004   COMPLETE — 11/22/2026 single-select
P01-OBJ-005   COMPLETE — All / no industry filter
P01-OBJ-006   COMPLETE — All / no acquisition-source filter

Containers     6 / 14
Measures       67
Pages          1
```

## 2. **Action or decision — OBJ-007**

Next is the **six-KPI portfolio-posture ribbon**. This is another case where the current Card visual is actually a good fit because all six inputs are already explicit measures.

Use **one current Card visual**, not six separate cards. That preserves the 14-container architecture.

The six measures, in exact order, are:

```text
1. [Funded Account Count]
2. [Funded Amount]
3. [Current Exposure As Of]
4. [Remittance Fulfillment %]
5. [Approval Rate]
6. [Expected Loss Rate]
```

Rename for this visual exactly:

```text
Funded Account Count
→ Funded account paths

Funded Amount
→ Synthetic funded amount

Current Exposure As Of
→ Current exposure as of

Remittance Fulfillment %
→ Remittance fulfillment

Approval Rate
→ Final-offer authorization rate

Expected Loss Rate
→ Comparative expected-loss rate
```

The last two labels are particularly important. We must not present `[Approval Rate]` as a generic approval rate or `[Expected Loss Rate]` as CECL.

### Revised geometry

Because our header/filter bands now consume more vertical space, place OBJ-007 at:

```text
X       24
Y       200
Width   1232
Height  92
```

That gives us a 24 px page margin and a full-width KPI ribbon.

### Initial internal layout

Set:

```text
Multi-card layout
Style          Tiles
Arrangement    Grid
Columns        6
Rows           1
Fit to space   On
Padding        4 px
Gap            6 px
```

At 1232 px, each KPI gets roughly 195–200 px, which should be enough even for the longer governed labels.

For now, **leave the individual card borders visible** while we construct it. They make field/position verification easier. We'll remove or soften them during page polish.

Do not configure conditional formatting yet.

## 3. **Evidence**

The completed OBJ-007 must remain **one visual container containing six KPI cards**:

```text
P01-OBJ-007
Native type       Current Card
Purpose           Portfolio-posture ribbon
Container count   1
Internal cards    6

X                  24
Y                 200
W                1232
H                  92
```

We should expect the default `BASELINE / 2026-11-22 / All / All` state to populate all six values. If any one is blank, stop on that specific measure before formatting.

## 4. **Holds and non-regression**

Do not create six independent Card visuals. That would immediately break the exact container architecture.

Also do not:

- add trend/reference labels;
- add CECL wording;
- add arrows/status icons;
- add conditional colors;
- add percentage-of-total calculations;
- create new KPI measures.

The existing six accepted measures are sufficient.

## 5. **Exact next action**

First correct **Observation date from `All` → `11/22/2026`** and verify OBJ-002 remains `2026-11-22`.

Then insert **one current Card at `X24 / Y200 / W1232 / H92`** and add the six measures above to **Value** in exact order.

Stop before detailed formatting and send me a screenshot of the populated six-KPI ribbon. We'll tune its labels, number formats, typography, spacing, and accessibility from the actual rendering before moving to OBJ-008.
<!-- END_SOURCE_MESSAGE -->


<a id="m-347a466c-c41f-487c-8f00-16d9a0968182"></a>
## Andrew / user · C109-M00082

C109-M00082 · 2026-08-25T15:33:18.721000-04:00 · active path

Preceding visible parent: [C109-M00081](part-03.md#m-e7020a06-ea74-45b5-ada1-950ff2342937)

<!-- BEGIN_SOURCE_MESSAGE -->
So for Observation date, you are saying I should not have "All" be an option. how do I remove the All option?
<!-- END_SOURCE_MESSAGE -->


<a id="m-30fb0dc6-c6de-4819-bf96-35055aef6e9f"></a>
## Assistant · C109-M00083

C109-M00083 · 2026-08-25T15:33:18.890953-04:00 · active path

Preceding visible parent: [C109-M00082](part-03.md#m-347a466c-c41f-487c-8f00-16d9a0968182)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. For **Observation date**, I recommend **no usable “All” state** because this page is defined at one selected observation date. The user should always have exactly one date selected.

You do this through the slicer's **selection controls**, not by filtering out a literal `All` value.

### In Power BI Desktop

1. Select the **Observation date** slicer.
2. Open **Format visual**.
3. Stay on the **Visual** tab.
4. Expand **Slicer settings**.
5. Expand **Selection** (sometimes shown as **Selection controls**, depending on the build).
6. Configure:

```text
Single select       On
Show "Select all"   Off
```

If you see:

```text
Multi-select with CTRL
```

its setting becomes irrelevant once **Single select = On**.

Then choose:

```text
11/22/2026
```

After that, Power BI should maintain one selected date rather than allowing the slicer to return to `All`.

### Important distinction for the other slicers

We intentionally want different behavior:

```text
Scenario
Single select = On
Select all = Off
Default = Baseline

Observation date
Single select = On
Select all = Off
Default = 11/22/2026

Industry
Single select = Off
Unfiltered / All state allowed

Acquisition source
Single select = Off
Unfiltered / All state allowed
```

So **Industry** and **Acquisition source** showing `All` in your screenshot is correct. Observation date showing `All` is what we need to eliminate.

### Controlling state
OBJ-004 remains bound to `DimAsOfDate[AsOfDate]`; we're correcting only its selection behavior.

### Action or decision
Turn **Single select On** and **Show "Select all" Off**, then select `11/22/2026`.

### Evidence
Afterward, OBJ-004 should display one date and OBJ-002 should continue to show **Observation as of = 2026-11-22**.

### Holds and non-regression
Do not filter `DimAsOfDate` to remove anything and don't change the model. This is purely slicer behavior.

### Exact next action
Apply those two selection settings and select **11/22/2026**. If you don't see a **Selection** section under Slicer settings, send me a screenshot of that Format pane and I'll map it to your exact August 2026 UI.
<!-- END_SOURCE_MESSAGE -->


<a id="m-287870f7-741d-4927-bfc1-f81a88cccf08"></a>
## Andrew / user · C109-M00084

C109-M00084 · 2026-08-25T15:35:51.772000-04:00 · active path

Preceding visible parent: [C109-M00083](part-03.md#m-30fb0dc6-c6de-4819-bf96-35055aef6e9f)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: ac0cd1c9-7722-4281-b8ab-e8635ca25e97.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-61f8c2f8-7d6e-42e3-a9e5-159a3fb4be1c"></a>
## Assistant · C109-M00085

C109-M00085 · 2026-08-25T15:35:52.048486-04:00 · active path

Preceding visible parent: [C109-M00084](part-03.md#m-287870f7-741d-4927-bfc1-f81a88cccf08)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes—**this is the correct governed default state now.** Freeze the four-slicer band.

The screenshot confirms:

- **Scenario:** `Baseline`, one selection.
- **Observation date:** `11/22/2026`, one selection—no `All`.
- **Industry:** `All`, correctly meaning no industry restriction.
- **Acquisition source:** `All`, correctly meaning no acquisition-source restriction.
- OBJ-002 independently confirms **Observation as of = 2026-11-22**.

Visually, the page foundation is also becoming coherent: the header/context band and filter band have clear separation without consuming excessive vertical space.

## 1. **Controlling state**

```text
P01-OBJ-001   COMPLETE
P01-OBJ-002   COMPLETE
P01-OBJ-003   COMPLETE
P01-OBJ-004   COMPLETE
P01-OBJ-005   COMPLETE
P01-OBJ-006   COMPLETE

Containers     6 / 14
Pages          1
Measures       67
```

Default analytical state is now correctly represented.

## 2. **Action or decision**

Save now.

Then proceed with `P01-OBJ-007 — Portfolio posture`, using **one current Card visual** containing six explicit measures.

Set:

```text
X       24
Y       212
Width   1232
Height  92
```

I'm moving Y from the earlier provisional 200 to **212**. Looking at the actual page, another ~20 px beneath the slicers will produce better visual rhythm before the KPI band.

Add these six measures to **Value**, in exact order:

```text
[Funded Account Count]
[Funded Amount]
[Current Exposure As Of]
[Remittance Fulfillment %]
[Approval Rate]
[Expected Loss Rate]
```

Leave Categories empty.

Rename for this visual:

```text
Funded Account Count
→ Funded account paths

Funded Amount
→ Synthetic funded amount

Current Exposure As Of
→ Current exposure as of

Remittance Fulfillment %
→ Remittance fulfillment

Approval Rate
→ Final-offer authorization rate

Expected Loss Rate
→ Comparative expected-loss rate
```

### Initial Card layout

Use:

```text
Arrangement      Grid
Columns          6
Rows             1
Fit to space     On
Uniform padding  4 px
Uniform gaps     6 px
```

Do **not** worry about fonts, borders, number formatting or polish yet.

## 3. **Evidence**

This is an important construction checkpoint because all six measures should resolve under:

```text
Scenario             Baseline
Observation date     11/22/2026
Industry             All
Acquisition source   All
```

If all six populate, we've established that the primary executive posture layer works against the constructed filter context.

## 4. **Holds and non-regression**

Keep OBJ-007 as **one visual container**. Do not create six separate Cards.

Also don't add conditional colors, icons, targets, reference labels, sparklines or additional calculations yet. We first want to see the raw six-measure rendering.

## 5. **Exact next action**

**Save the current page.**

Then insert one current Card at **X24 / Y212 / W1232 / H92**, add the six measures in the exact order above, and send me a screenshot **before formatting**.

We'll use the physical result to make OBJ-007 genuinely executive-grade rather than guessing at Card typography and spacing.
<!-- END_SOURCE_MESSAGE -->


<a id="m-51ffc269-c661-4647-a792-14429d4d2904"></a>
## Andrew / user · C109-M00086

C109-M00086 · 2026-08-25T15:37:41.660000-04:00 · active path

Preceding visible parent: [C109-M00085](part-03.md#m-61f8c2f8-7d6e-42e3-a9e5-159a3fb4be1c)

<!-- BEGIN_SOURCE_MESSAGE -->
interesting. multi row card is now an option.it must have taken a bit for the defaults to come back.
<!-- END_SOURCE_MESSAGE -->


<a id="m-550f2d03-d9ed-4482-8d06-e4f59a2fb6ec"></a>
## Assistant · C109-M00087

C109-M00087 · 2026-08-25T15:37:41.811312-04:00 · active path

Preceding visible parent: [C109-M00086](part-03.md#m-51ffc269-c661-4647-a792-14429d4d2904)

<!-- BEGIN_SOURCE_MESSAGE -->
That is useful—and it changes the preferred implementation path.

It appears **Restore default visuals did work, but Desktop refreshed the visual gallery asynchronously**. Since the native **Multi-row card is now physically available**, we should use it wherever the R12 catalog explicitly specified it rather than carrying unnecessary compatibility deviations.

Most importantly, this gives us an opportunity to simplify **OBJ-002**.

## 1. **Controlling state**

We now physically know:

```text
Current Card           available
Legacy Multi-row Card  available after delayed default restoration
```

R12 explicitly specified Multi-row Card for OBJ-002. Therefore our seven-measure compatibility patch is no longer automatically necessary in its entirety.

## 2. **Action or decision**

**Do not change OBJ-002 immediately.** The current version works well and we have already invested in it.

Instead, before OBJ-007, let's run a very small controlled test of the restored Multi-row Card **without disturbing the existing page**:

1. Insert a temporary Multi-row Card in unused canvas space.
2. Drag `DimRunCampaign[run_code]` into it.
3. See whether it accepts the raw column.
4. If accepted, inspect whether the field menu offers **First**.

Then delete the temporary test visual regardless of outcome.

Why test? Because `DiscourageImplicitMeasures=True` may still prevent the legacy visual from generating the implicit `First` aggregation. The icon's return does not guarantee compatibility with this model.

### If the test fails

Nothing changes. Our explicit-measure/current-Card adaptation remains justified.

### If the test succeeds

Then I recommend we later replace OBJ-002 with the **exact cataloged Multi-row Card** and remove the three now-unnecessary metadata compatibility measures:

```text
[P01 Run]
[P01 Source Release]
[P01 Model Version]
```

That would reduce the semantic deviation from seven new measures to only the four potentially needed for OBJ-012—or possibly even fewer, depending on how the restored visual behaves there.

## 3. **Evidence**

This delayed appearance should be logged accurately:

```text
Initial observation:
Restore default visuals did not immediately expose Multi-row Card.

Later physical observation:
Multi-row Card subsequently appeared in the native gallery.

Interpretation:
Desktop visual-gallery restoration/refresh was delayed;
legacy visual was not actually unavailable.
```

That's better evidence than our earlier conclusion that August 2026 Desktop had removed it.

## 4. **Holds and non-regression**

Do **not** undo the current working OBJ-002 yet. First establish whether the restored visual actually works with `DiscourageImplicitMeasures=True`.

And for **OBJ-007**, we should still use the **current Card**, not Multi-row Card. R12's design intentionally distinguished the modern New Card for the KPI ribbon from Multi-row Card for governance/context objects.

## 5. **Exact next action**

Before constructing OBJ-007, insert a temporary restored **Multi-row Card**, drag only:

```text
DimRunCampaign[run_code]
```

into it, and tell me whether:

1. it accepts the field; and
2. its field dropdown offers **First**.

Then delete the temporary visual. That 30-second test will tell us whether we can eliminate part of the semantic compatibility deviation before proceeding.
<!-- END_SOURCE_MESSAGE -->


<a id="m-206f1531-bea0-4082-9838-4e0b60e5a752"></a>
## Andrew / user · C109-M00088

C109-M00088 · 2026-08-25T15:39:34.070000-04:00 · active path

Preceding visible parent: [C109-M00087](part-03.md#m-550f2d03-d9ed-4482-8d06-e4f59a2fb6ec)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 2bdf769a-8578-4e65-aeb0-516202f5e249.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->
