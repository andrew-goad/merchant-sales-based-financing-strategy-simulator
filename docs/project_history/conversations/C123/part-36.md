# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 36 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-35.md)
[Next part](part-37.md)

<a id="m-044ac13c-dcc5-40be-9e4d-ded8845f8bf1"></a>
## Assistant · C123-M00416

C123-M00416 · 2026-10-15T20:18:42.126987-04:00 · active path

Preceding visible parent: [C123-M00415](part-35.md#m-db035edf-d45c-45ed-bc45-5d81f5aedb5a)

<!-- BEGIN_SOURCE_MESSAGE -->
**Start by getting the prepared data into Tableau and confirming the first number: 750 matched applications.** That is our first checkpoint. No PostgreSQL connection, Python execution, or additional data joins are needed for this stage. The import file already places both scenarios and their narratives on one row per application. [export reference: filecite | turn103file0 | L23-L32]

## 1. Open Tableau Desktop Public Edition

If Tableau is already installed, go to Step 2.

Otherwise, use Tableau’s **Get Tableau Public** download page and install **Tableau Desktop Public Edition for Windows**. Choose the Public desktop application—not Tableau Reader. The Public desktop application is free and supports local workbook saves. [export reference: cite | turn229110search0 | turn229110search9]

**We will work locally. Do not publish anything to Tableau Public yet.**

## 2. Extract the complete starter package

Download this package if you have not already:

**Download the Tableau starter package** (historical reference: `sandbox:[session]/MCI_Tableau_Start_Here.zip`; referenced bytes not established here)

In Windows File Explorer, right-click the ZIP, select **Extract All**, and use this destination:

```text
D:\MSBF_TABLEAU
```

Inside the extracted folder, locate:

```text
MCI_Tableau_Narrative_R1
```

The file we will connect is:

```text
D:\MSBF_TABLEAU\MCI_Tableau_Narrative_R1\data\MCI_Matched_Applications_With_Narratives.csv
```

**Leave the CSV unchanged.** Connect it directly in Tableau rather than opening and resaving it through Excel. Keep the other package folders together; the `calculations` folder contains the narrative formulas we will use next. [export reference: filecite | turn103file0 | L19-L29]

## 3. Connect the CSV and check field types

On Tableau’s start screen, use:

**Connect → To a File → Text File**

Select `MCI_Matched_Applications_With_Narratives.csv` and click **Open**. Tableau should take you to the **Data Source** screen with a preview of the records. [export reference: cite | turn229110search2]

Rename the data source at the top to:

```text
MCI — Matched Scenario Review
```

Keep **just this one table**. Do not add the source CSVs or the QA files as additional tables; they are not needed for the dashboard model. [export reference: filecite | turn103file0 | L25-L32]

Before moving to a worksheet, check these types. Click the small type icon above a column to change it—**Abc** means text and **#** means a number. Tableau recommends correcting types before creating an extract. [export reference: cite | turn229110search7]

| Fields | Required type |
|---|---|
| **Pair Key, Module1 Run ID, Application ID, Merchant ID, Merchant** | **String** |
| Decision labels, codes, reasons, hashes, and narrative fields | **String** |
| Fields ending in **Flag, Sort, Days, Count** | **Number (whole)** |
| Amounts, repayment amounts, ratios, rates, and contributions | **Number (decimal)** |
| **Baseline Evidence Window End; Stress Evidence Window End** | **Date** |

These types follow the prepared package’s import instructions. **Preserve the existing field names**, because the supplied narrative calculations reference them. Leave unavailable selected terms as null rather than replacing them with zero. [export reference: filecite | turn103file0 | L26-L29]

Pay particular attention to **Merchant**: it should retain values such as `000003`, not become the number `3`.

## 4. Create the first validation worksheet

Click **Sheet 1** at the bottom.

Rename the sheet:

```text
00 — Population Check
```

From the top menu, choose **Analysis → Create Calculated Field**. Name the field:

```text
Matched Applications
```

Paste this formula:

```tableau
COUNTD([Pair Key])
```

Click **OK**. This counts distinct application-pair identifiers. [export reference: cite | turn415769view1 | turn415769view2]

Drag **Matched Applications** from the left-hand Data pane onto **Text** on the **Marks** card. Leave **Rows**, **Columns**, and **Filters** empty.

### Expected result

# **750**

That matches the population specified in the import package. We are expecting **750 rows containing both scenario results**, not 1,500 separate rows in this dashboard table. [export reference: filecite | turn103file0 | L14-L16] [export reference: filecite | turn103file0 | L32-L32]

Save the workbook **locally** using **File → Save As**, with a name such as:

```text
MCI_Risk_Decision_Scenario_Review_R1
```

Tableau Desktop Public Edition permits local saving without publishing the workbook or data. [export reference: cite | turn229110search9]

---

**Stop at this checkpoint and send a screenshot of the worksheet showing 750—or the screen where you encounter a problem.** The next build step is the decision matrix and executive indicators, followed by the filter-responsive narrative interpretation that makes this distinctly your portfolio work.
<!-- END_SOURCE_MESSAGE -->


<a id="m-de4393cf-8ad8-42b6-803b-1dc08920b3dc"></a>
## Andrew / user · C123-M00417

C123-M00417 · 2026-10-15T20:29:09.186000-04:00 · active path

Preceding visible parent: [C123-M00416](part-36.md#m-044ac13c-dcc5-40be-9e4d-ded8845f8bf1)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-002905).png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-b3fa4fb3-367c-4be1-85e3-fa638f829bba"></a>
## Assistant · C123-M00418

C123-M00418 · 2026-10-15T20:35:06.103034-04:00 · active path

Preceding visible parent: [C123-M00417](part-36.md#m-de4393cf-8ad8-42b6-803b-1dc08920b3dc)

<!-- BEGIN_SOURCE_MESSAGE -->
**That is the expected result: your screenshot shows 750 distinct application pairs, with no worksheet filters applied. The first Tableau checkpoint passes.**

Keep **00 — Population Check** unchanged. Next, let’s build **the comparison measures, the decision matrix, and your first data-driven narrative** in one pass.

Before starting, click **Show Me** at the upper right to close that panel. Widen the left-hand Data pane slightly so the field names are easier to distinguish.

## 1. Create the comparison measures

Use **Analysis → Create Calculated Field**, the same way you created `Matched Applications`. Create each field below separately, using the names exactly as shown. Tableau saves these calculations in the workbook for reuse across worksheets. [export reference: cite | turn123860search1]

| New calculated-field name | Formula | Expected full-population value |
|---|---|---:|
| **Different Decisions** | `SUM([Decision Changed Flag])` | **236** |
| **Baseline Authorizations** | `SUM([Baseline Authorized Flag])` | **103** |
| **Stress Authorizations** | `SUM([Stress Authorized Flag])` | **27** |

Then create one more field.

**Name**
```text
Different Decision Rate
```

**Formula**
```tableau
IF [Matched Applications] > 0 THEN
    [Different Decisions] / [Matched Applications]
END
```

Right-click **Different Decision Rate** in the Data pane and choose **Default Properties → Number Format → Percentage**, with **one decimal place**. The expected display is **31.5%**, not `31.5` entered as a percentage. These controls match the prepared package’s reference population. [export reference: cite | turn233171search9] [export reference: filecite | turn105file0 | L54-L55]

### Put the measures into a quick check sheet

Create a new worksheet using the **New Worksheet** icon immediately to the right of your existing sheet tab. Name it:

```text
01 — Scenario Controls
```

On that sheet:

1. Drag **Measure Names** to **Rows**.
2. Drag **Measure Values** to **Text** on the Marks card.
3. Drag **Measure Names** to **Filters**. In the dialog, click **None**, then check only:
   - `Matched Applications`
   - `Different Decisions`
   - `Different Decision Rate`
   - `Baseline Authorizations`
   - `Stress Authorizations`
4. Click **OK**.

`Measure Names` and `Measure Values` are Tableau’s built-in fields for displaying several measures in one table. Their use here is just a quick reconciliation view; we will turn the relevant measures into polished dashboard indicators later. [export reference: cite | turn233171search1]

You should see:

```text
Matched Applications       750
Different Decisions        236
Different Decision Rate    31.5%
Baseline Authorizations    103
Stress Authorizations       27
```

The display order is not important yet.

---

## 2. Build the Baseline-versus-stress decision matrix

Create another worksheet and name it:

```text
02 — Decision Matrix
```

### Place these exact fields

| Tableau location | Field or setting |
|---|---|
| **Rows** | `Baseline Decision` |
| **Columns** | `Stress Decision` |
| **Marks type** | Change **Automatic** to **Square** |
| **Color** | `Matched Applications` |
| **Label** | `Matched Applications` |

Drag **Matched Applications** from the Data pane twice—once onto **Color**, then again onto **Label**. Depending on the mark type, the label control may initially say **Text**.

Use the readable fields **Baseline Decision** and **Stress Decision**, **not** the corresponding `Decision Code` or `Decision Narrative` fields. This follows Tableau’s highlight-table pattern: categories on Rows and Columns, with a measure controlling color. [export reference: cite | turn233171search0]

### Give both axes the same meaningful order

Right-click the **Baseline Decision** pill on Rows and choose **Sort**:

```text
Sort order:  Ascending
Sort by:     Field
Field name:  Baseline Decision Sort
Aggregation: Minimum
```

Repeat for **Stress Decision** on Columns:

```text
Sort order:  Ascending
Sort by:     Field
Field name:  Stress Decision Sort
Aggregation: Minimum
```

Using the supplied sort fields keeps the two axes aligned rather than independently sorting their labels alphabetically or by frequency. Tableau supports these field-based sorts. [export reference: cite | turn233171search6]

The order should be:

```text
Approve as requested — authorized
Counteroffer — authorized
Counteroffer review required
Underwriting review required
Evidence decline
No feasible structure
Policy hard stop
```

### Make the matrix readable

Change the toolbar dropdown currently showing **Standard** to **Entire View**. On the Marks card, increase **Size** until the cells form readable tiles. Keep **Size** free of data fields; we want equal-size cells, with **color intensity representing application count**.

For now, use a **single-color sequential palette**, rather than red/green. Our intended encoding is “more or fewer applications,” not “good or bad credit.” Do not spend time perfecting the typography yet.

Double-click the worksheet title and use:

```text
Decision comparison: Baseline vs. Recession Energy
Rows = Baseline | Columns = Recession Energy
```

### Spot-check the populated cells

I rechecked the supplied import CSV. These are useful checks that the axes and counts are positioned correctly:

| Baseline row | Recession Energy column | Expected count |
|---|---|---:|
| Counteroffer review required | Evidence decline | **88** |
| Counteroffer review required | No feasible structure | **51** |
| Approve as requested — authorized | Evidence decline | **47** |
| No feasible structure | No feasible structure | **290** |
| Policy hard stop | Policy hard stop | **117** |

**Read the diagonal as “same final decision category,” not necessarily identical terms or reasons.** This is a comparison of alternative scenarios—not a timeline showing accounts deteriorating after origination. [export reference: filecite | turn105file0 | L70-L76]

---

## 3. Add your first live narrative now

This is the first implementation of your signature interpretation layer—not a static text box.

Create a calculated field named:

```text
Narrative - Executive Readout
```

Paste this formula. It is the same executive-readout calculation included in the starter package:

```tableau
IF COUNTD([Pair Key]) = 0 THEN
    "No matched applications in this selection. Clear a filter to continue."
ELSE
    "In this filtered portfolio of "
    + STR(COUNTD([Pair Key]))
    + " matched applications, "
    + STR(INT(SUM([Decision Changed Flag])))
    + " ("
    + STR(
        ROUND(
            100.0 * SUM([Decision Changed Flag])
            / COUNTD([Pair Key]),
            1
        )
      )
    + "%) have different final decision categories. Authorized: "
    + STR(INT(SUM([Baseline Authorized Flag])))
    + " in Baseline versus "
    + STR(INT(SUM([Stress Authorized Flag])))
    + " in Recession Energy. "
    + "These are alternative scenarios, not before/after account history."
END
```

Click **OK** after Tableau confirms that the calculation is valid. It combines aggregate calculations with text; it does not require the `Narrative Detail` parameter yet. That parameter will serve the later individual-application panels. [export reference: cite | turn123860search2] [export reference: filecite | turn105file0 | L26-L39]

### Create its worksheet

Create a new worksheet named:

```text
03 — Executive Narrative
```

Set the Marks type to **Text**, then drag **Narrative - Executive Readout** onto **Text**.

**Leave Rows, Columns, and Detail empty.** We want one paragraph describing the worksheet’s population, not one paragraph per merchant. This matches the package’s narrative setup. [export reference: filecite | turn105file0 | L27-L36]

Set the text to approximately **12–14 points**, left-aligned. Widen the text area as needed; final wrapping and placement will be handled when we assemble the dashboard.

With no filters, the paragraph should read:

> In this filtered portfolio of **750 matched applications, 236 (31.5%)** have different final decision categories. Authorized: **103 in Baseline versus 27 in Recession Energy**. These are alternative scenarios, not before/after account history.

This first paragraph establishes **what differs and the comparison basis**. The next narrative layer will explain **the selected merchant’s operating evidence, assessment, and binding decision reasons**—so the final dashboard does not stop at repeating totals.

## Checkpoint for this pass

Save the workbook locally. You should now have four worksheets:

```text
00 — Population Check
01 — Scenario Controls
02 — Decision Matrix
03 — Executive Narrative
```

**Send screenshots of the Decision Matrix and Executive Narrative, or the calculation error if Tableau flags one.** That will let us verify the core comparison and narrative before wiring the merchant-level investigation and dashboard interactions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-58f01c9f-6b6b-4261-a6df-1f1bbc59f0a5"></a>
## Andrew / user · C123-M00419

C123-M00419 · 2026-10-15T20:50:36.932000-04:00 · active path

Preceding visible parent: [C123-M00418](part-36.md#m-b3fa4fb3-367c-4be1-85e3-fa638f829bba)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-004212).png; image(20261016-005017).png; image(20261016-005030).png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-c7f51ecd-d051-4ade-92cc-43ba7676ee94"></a>
## Assistant · C123-M00420

C123-M00420 · 2026-10-15T20:51:28.527697-04:00 · active path

Preceding visible parent: [C123-M00419](part-36.md#m-58f01c9f-6b6b-4261-a6df-1f1bbc59f0a5)

<!-- BEGIN_SOURCE_MESSAGE -->
The controls, matrix, and executive narrative match expected results. Next we’ll link matrix selections to applications and paired Baseline/stress explanations for merchant-level investigation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ea72c00e-19ad-4591-9e30-b1f5f4e39e26"></a>
## Assistant · C123-M00421

C123-M00421 · 2026-10-15T20:59:13.993924-04:00 · active path

Preceding visible parent: [C123-M00420](part-36.md#m-c7f51ecd-d051-4ade-92cc-43ba7676ee94)

<!-- BEGIN_SOURCE_MESSAGE -->
**All three checkpoints pass for the unfiltered view.** Your screenshots show the expected **750 applications, 236 different decisions, 31.5%, 103 Baseline authorizations, and 27 stress authorizations**. The matrix has the expected populated cells, and the executive narrative agrees with the controls. Those values match the package’s reference checks. [export reference: filecite | turn107file0 | L37-L40]

The matrix’s blank cells are not a problem: those decision pairings have no represented applications in the current view. **We should not add artificial records just to fill the grid.**

Now let’s build the useful interaction:

> **Click a decision pairing → see the affected applications → select an application → read the Baseline and stress explanations side by side.**

This pass will produce a working investigation dashboard. We will add the segment comparison and final executive styling after the interaction works.

## 1. Make two quick presentation corrections

Your counts currently display as `103.0`, `236.0`, and so forth. In the Data pane, right-click each of these four calculated fields and choose **Default Properties → Number Format → Number (Custom) → 0 decimal places**:

`Matched Applications`, `Different Decisions`, `Baseline Authorizations`, and `Stress Authorizations`.

Leave **Different Decision Rate** as a percentage with one decimal place.

On **02 — Decision Matrix**, click **Label → Alignment**, and center the numbers horizontally and vertically. The counts currently sit toward the right edge of each tile. These are formatting changes only; do not change the calculations. Tableau permits separate control of number formatting and text alignment. [export reference: cite | turn681205search3 | turn473560view2]

## 2. Create the narrative-detail selector

This will let the reviewer choose **the decision, operating evidence, structure assessment, or technical source rationale** without cramming all four onto the dashboard simultaneously. That follows the prepared narrative design. [export reference: filecite | turn107file0 | L21-L24]

In the Data pane, right-click an empty area and select **Create Parameter**.

| Setting | Value |
|---|---|
| **Name** | `Narrative Detail` |
| **Data type** | String |
| **Allowable values** | List |
| **Values** | `Decision`, `Evidence`, `Structure`, `Source rationale` |
| **Current value** | `Decision` |

Click **OK**, then right-click the parameter and choose **Show Parameter**. A parameter changes calculations that reference it; it does not filter out applications by itself. [export reference: cite | turn473560view3]

## 3. Create three narrative calculations

These calculations **display the narrative fields already in your import**, rather than inventing a fresh explanation in Tableau. The CSV contains the comparison narrative and separate evidence, structure, and decision narratives for both scenarios. [export reference: filecite | turn108file0 | L13-L16]

Use **Analysis → Create Calculated Field** for each.

### A. `Narrative - Selected Applications`

This shows a population summary when several applications are in scope, then the comparison interpretation when exactly one application is selected.

```tableau
IF COUNTD([Pair Key]) = 0 THEN
    "No applications match the current selection. Clear the application selection or change the filters."

ELSEIF COUNTD([Pair Key]) = 1 THEN
    "Application: "
    + MIN([Application ID])
    + CHAR(10) + CHAR(10)
    + IFNULL(
        MIN([Comparison Narrative]),
        "The comparison narrative is unavailable in this source."
      )

ELSE
    STR(COUNTD([Pair Key]))
    + " applications are in the current investigation selection. "
    + STR(INT(SUM([Decision Changed Flag])))
    + " have different final decision categories across the two scenarios. "
    + "Select one application in the table to inspect its evidence and decision reasons."
END
```

### B. `Narrative - Baseline Story`

```tableau
IF COUNTD([Pair Key]) = 0 THEN
    "No application matches the current selection."

ELSEIF COUNTD([Pair Key]) > 1 THEN
    "Select one application to read its Baseline explanation."

ELSE
    "BASELINE | "
    + MIN([Baseline Decision])
    + CHAR(10)
    + "Application: " + MIN([Application ID])
    + CHAR(10) + CHAR(10)

    + IFNULL(
        CASE [Narrative Detail]
            WHEN "Decision" THEN
                MIN([Baseline Decision Narrative])

            WHEN "Evidence" THEN
                MIN([Baseline Evidence Narrative])

            WHEN "Structure" THEN
                MIN([Baseline Structure Narrative])

            WHEN "Source rationale" THEN
                "Technical source decision rationale; this may describe the independent scenario evaluation before final governance. "
                + MIN([Baseline Source Decision Why])
        END,
        "The selected narrative is unavailable in this source."
      )
END
```

### C. `Narrative - Stress Story`

```tableau
IF COUNTD([Pair Key]) = 0 THEN
    "No application matches the current selection."

ELSEIF COUNTD([Pair Key]) > 1 THEN
    "Select one application to read its Recession Energy explanation."

ELSE
    "RECESSION ENERGY | "
    + MIN([Stress Decision])
    + CHAR(10)
    + "Application: " + MIN([Application ID])
    + CHAR(10) + CHAR(10)

    + IFNULL(
        CASE [Narrative Detail]
            WHEN "Decision" THEN
                MIN([Stress Decision Narrative])

            WHEN "Evidence" THEN
                MIN([Stress Evidence Narrative])

            WHEN "Structure" THEN
                MIN([Stress Structure Narrative])

            WHEN "Source rationale" THEN
                "Technical source decision rationale; this may describe the independent scenario evaluation before final governance. "
                + MIN([Stress Source Decision Why])
        END,
        "The selected narrative is unavailable in this source."
      )
END
```

**The single-application check is important.** `MIN()` can return one string from a group, so the calculations use it for the individual narrative only after confirming that exactly one distinct `Pair Key` is present. That prevents a multi-application selection from displaying an arbitrary merchant’s explanation. [export reference: cite | turn681205search0]

The source-rationale label also matters: the package distinguishes the final governed decision from technical text that can describe an earlier independent scenario evaluation. [export reference: filecite | turn107file0 | L53-L60]

## 4. Create the application list and narrative sheets

### `04 — Application Detail`

Create a new worksheet with that name.

Drag the following fields to **Rows**, in this order:

```text
Merchant
Industry
Acquisition Source
Baseline Decision
Stress Decision
```

Then configure the Marks card:

| Location | Field |
|---|---|
| **Marks type** | Text |
| **Text** | `Requested Amount` |
| **Detail** | `Pair Key` |
| **Tooltip** | `Application ID` |
| **Tooltip** | `Baseline Selected Amount` |
| **Tooltip** | `Stress Selected Amount` |

For **Requested Amount**, use **Measure → Minimum** from the pill menu. Format it as currency with no decimal places. The worksheet is an application list, not a portfolio sum.

Keep **Pair Key** on Detail: that is the identifier we will pass to the narrative sheets when a row is selected. Use **Fit Width**, not **Entire View**—do not attempt to shrink 750 application rows onto one screen. Tableau text tables support dimensions with numeric text marks. [export reference: cite | turn681205search1]

Do not put the long narrative fields into this table. They belong in the readable panels below it.

### Create three narrative worksheets

The fastest approach is to **duplicate your existing `03 — Executive Narrative`** three times. On each duplicate, remove the executive narrative pill from Text and replace it with the corresponding calculation.

| Worksheet name | Field on Text |
|---|---|
| **05 — Selection Narrative** | `Narrative - Selected Applications` |
| **06 — Baseline Story** | `Narrative - Baseline Story` |
| **07 — Stress Story** | `Narrative - Stress Story` |

For these three sheets, leave **Rows, Columns, and Detail empty**. Keep the text left-aligned at a readable size. The intended result is one text mark describing the current selection, not one mark per application. [export reference: filecite | turn107file0 | L11-L13]

Before any actions are connected, the two scenario panels should say to select one application. **That is the correct initial behavior.**

## 5. Assemble the first working dashboard

Choose **Dashboard → New Dashboard** and name it:

```text
Risk Decision & Scenario Review
```

For this working layout, use a **Fixed size of 1300 × 1100**. This is a starting layout, not the final design.

Use **Tiled** objects. Add one **Vertical** layout container, then arrange these inside it:

| Order | Dashboard content |
|---|---|
| Top | **03 — Executive Narrative** |
| Next | **02 — Decision Matrix** |
| Next | **04 — Application Detail** |
| Next | **05 — Selection Narrative** |
| Bottom | A **Horizontal** container holding **06 — Baseline Story** and **07 — Stress Story** side by side |

Give the matrix the most space, allow the application table to scroll, and give the two narrative panels enough height to read the default Decision text. Do not reduce the narrative font to make every possible paragraph fit; the selector is there to manage detail.

Tableau’s dashboard containers let you group sheets vertically and horizontally while retaining their worksheet logic. [export reference: cite | turn473560view1]

Show the **Narrative Detail** parameter on the dashboard using the dropdown menu on the Baseline Story sheet: **Parameters → Narrative Detail**. Only one visible parameter control is needed because both calculations reference it.

Leave the population-check and scenario-controls worksheets out of the dashboard for now. Keep them as validation sheets.

## 6. Wire the two interactions deliberately

**Do not use the dashboard’s generic “Use as Filter” button here.** We want explicit targets so a merchant selection cannot silently change the portfolio narrative.

First, go back to **02 — Decision Matrix** and drag these two fields to **Detail**:

```text
Baseline Decision Code
Stress Decision Code
```

Return to the dashboard. Use **Dashboard → Actions → Add Action → Filter**. Tableau filter actions pass selected field values from a source sheet to designated target sheets. [export reference: cite | turn473560view0]

### Action 1 — Matrix selects the investigation population

| Setting | Choose |
|---|---|
| **Name** | `Select decision pairing` |
| **Source sheet** | `02 — Decision Matrix` only |
| **Run action on** | Select |
| **Target sheets** | `04 — Application Detail`, `05 — Selection Narrative`, `06 — Baseline Story`, `07 — Stress Story` |
| **Clearing the selection** | Show all values |
| **Target filters** | Selected Fields |

Add these field mappings:

```text
Baseline Decision Code → Baseline Decision Code
Stress Decision Code   → Stress Decision Code
```

**Do not target `03 — Executive Narrative`.** It should continue describing the overall portfolio while the lower section describes the selected investigation population. This separation follows the package’s intended filter design. [export reference: filecite | turn107file0 | L17-L31]

### Action 2 — Application selects its paired explanation

Create a second filter action:

| Setting | Choose |
|---|---|
| **Name** | `Inspect application` |
| **Source sheet** | `04 — Application Detail` only |
| **Run action on** | Select |
| **Target sheets** | `05 — Selection Narrative`, `06 — Baseline Story`, `07 — Stress Story` |
| **Clearing the selection** | Show all values |
| **Target filters** | Selected Fields |

Add this mapping:

```text
Pair Key → Pair Key
```

Leave **Single-select only** unchecked for this action. The calculations explicitly handle multiple applications; we want them to show the selection guidance rather than retain a previous single-application explanation.

Do not target the matrix, application list, or executive narrative with this second action. The package specifies this same application-key handoff. [export reference: filecite | turn107file0 | L29-L35]

## 7. Test the signature story

### Test A — Select the 88-application cell

Click the matrix cell at:

```text
Baseline: Counteroffer review required
Stress:   Evidence decline
```

Your screenshot shows **88** in that cell.

The application table should narrow to that pairing, and the selection narrative should report **88 applications**. The executive narrative at the top should still show **750 / 236 / 103 / 27** because you have changed the investigation selection, not the overall portfolio.

### Test B — Select Merchant 003

In the resulting application list, find Merchant **003 / 000003**, depending on its current display formatting, and click the requested-amount mark in that row.

The application identifier ends in:

```text
M000003_A01
```

With **Narrative Detail = Decision**, the panels should establish:

| Baseline | Recession Energy |
|---|---|
| A **$42,500** potentially supportable structure is retained. | The required sales window contains **28 usable days against 30 required**, including **two processor-outage days**. |
| Specialist review remains necessary near the approved capacity boundary. | The missing evidence prevents dependent assessment. |
| **This is not an authorized offer.** | **This does not prove that every alternative would fail.** |

Those are the actual narratives and values in Merchant 003’s imported record. [export reference: filecite | turn108file0 | L16-L16]

Switch **Narrative Detail** to **Structure**. Both panels should change together. Baseline should show the **$61,300 request, 11 candidate evaluations, and $42,500 selected structure**; stress should explain the blocked assessment and absence of a governed selected structure. [export reference: filecite | turn108file0 | L16-L16]

### Test C — Clear the application selection

Click blank space in the application-list pane to clear its selected mark. The scenario panels should return to the single-application guidance while the matrix selection remains in effect.

**Clear the application selection before selecting a different matrix cell.** Two active filter actions can otherwise intersect and leave no matching application. An empty result must not be mistaken for a completed explanation; the setup guide specifically identifies this as a behavior to test in Tableau. [export reference: filecite | turn107file0 | L33-L35]

---

**Save locally, then send one screenshot of the dashboard with Merchant 003 selected and Narrative Detail set to Decision.** That will establish whether the matrix, application identity, and source-backed narrative work together—the core feature that makes this more than a collection of charts.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b2b0085c-1b95-4712-8c68-e5d24588a2d2"></a>
## Andrew / user · C123-M00422

C123-M00422 · 2026-10-15T21:45:12.511000-04:00 · active path

Preceding visible parent: [C123-M00421](part-36.md#m-ea72c00e-19ad-4591-9e30-b1f5f4e39e26)

**Editorial record note:** 6 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-011753).png; image(20261016-011804).png; image(20261016-011815).png; image(20261016-011828).png; image(20261016-014452).png; image(20261016-014507).png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-9050718b-e204-4e27-b8a5-8d92280d0141"></a>
## Assistant · C123-M00423

C123-M00423 · 2026-10-15T21:51:45.344171-04:00 · active path

Preceding visible parent: [C123-M00422](part-36.md#m-b2b0085c-1b95-4712-8c68-e5d24588a2d2)

<!-- BEGIN_SOURCE_MESSAGE -->
**The core investigation is working for the path you tested.** Your dashboard screenshots show the **88-application decision pairing**, Merchant **000003** selected, and that application’s identity reaching the comparison and both scenario panels. The executive narrative correctly remains at **750 applications / 236 different decisions / 103 Baseline authorizations / 27 stress authorizations**.

**The next issue is presentation, not the data connection:** the explanations are getting trapped behind scrollbars, and the oversized tooltip obscures the reading area. I would fix that before adding another chart. The working layout I proposed needs more deliberate space allocation now that we can see the actual text.

## What your screenshots establish

| Check | What is visible |
|---|---|
| Application-level view | The original detail worksheet shows **750 marks and 750 rows**. Merchant identifiers retain leading zeros. |
| Matrix selection | The selected cell contains **88**, and the dashboard’s application list shows **88 rows** in its status bar. |
| Application selection | Merchant **000003**, requested amount **$61,300**, is selected. |
| Narrative identity | The selection, Baseline, and stress panels all identify `MSBF_POP_0001_M000003_A01`. |
| Portfolio separation | The executive narrative still describes the complete portfolio despite the application selection. |
| Full narrative readability | **Not yet established.** The scenario paragraphs are clipped in the dashboard captures. |

**Keep the existing actions and source data. We do not need to rebuild them.**

# 1. Remove the tooltip that is covering the narrative

For each of these worksheets, open **Marks → Tooltip**, clear **Show tooltips**, and click **OK**:

```text
03 — Executive Narrative
05 — Selection Narrative
06 — Baseline Story
07 — Stress Story
```

Keep tooltips enabled on the matrix and application table. They are useful there; a tooltip that repeats an entire visible narrative is not. Tableau controls tooltip visibility separately for each worksheet. [export reference: cite | turn394060view1]

# 2. Make the selection band compact—keep the detailed explanations below it

Your current **05 — Selection Narrative** repeats much of the stress explanation immediately above the stress panel. That costs valuable space.

Keep the existing `Narrative - Selected Applications` calculation, but create a new, shorter display calculation called:

```text
Narrative - Investigation Header
```

Paste:

```tableau
IF COUNTD([Pair Key]) = 0 THEN
    "No applications match the investigation selection. Clear the application selection or change the filters."

ELSEIF COUNTD([Pair Key]) = 1 THEN
    "Merchant "
    + MIN([Merchant])
    + " | "
    + MIN([Industry])
    + " | "
    + MIN([Acquisition Source])
    + CHAR(10)
    + "Baseline: "
    + MIN([Baseline Decision])
    + " | Recession Energy: "
    + MIN([Stress Decision])

ELSE
    STR(COUNTD([Pair Key]))
    + " applications in the current investigation; "
    + STR(INT(SUM([Decision Changed Flag])))
    + " have different final decision categories."
    + CHAR(10)
    + "Select one requested-amount value in the table to read both scenario explanations."
END
```

On **05 — Selection Narrative**, replace the existing field on **Text** with this new calculation. Leave **Rows, Columns, and Detail empty**.

The individual fields are still displayed only after the calculation establishes one distinct `Pair Key`; `MIN()` is not being used to choose an arbitrary application from a larger selection. [export reference: cite | turn439511view2]

For Merchant 003, the new band should read approximately:

> **Merchant 000003 | Healthcare Services | Digital Direct**  
> Baseline: Counteroffer review required | Recession Energy: Evidence decline

**This changes the display emphasis, not the source narratives.** The full comparison calculation remains in the workbook, and the Baseline/stress panels retain the detailed explanations.

# 3. Give the two scenario narratives enough space

## A. Correct the fit settings on the dashboard itself

Close the **Format Alignment** pane using its small **×** at the upper right, then return to the dashboard.

Select each embedded worksheet and use its dropdown menu’s **Fit** setting:

| Dashboard worksheet | Setting for this pass |
|---|---|
| **03 — Executive Narrative** | Entire View |
| **02 — Decision Matrix** | Entire View |
| **04 — Application Detail** | Fit Width |
| **05 — Selection Narrative** | Entire View |
| **06 — Baseline Story** | Entire View |
| **07 — Stress Story** | Entire View |

Tableau’s Fit options control how a view uses its available window. The application table should retain vertical scrolling; the single-paragraph narrative sheets should use the space allocated to them. **Entire View is not proof that all text fits—we still need to inspect the resulting paragraphs.** [export reference: cite | turn575204search1]

One useful distinction: **Format → Alignment → Wrap controls headers, not text marks.** Do not spend time toggling that setting expecting it to repair these narrative cards. The relevant adjustments are the view’s fit, its available size, and the text formatting. [export reference: cite | turn142484search0]

## B. Reallocate height rather than reducing the font

Keep the working dashboard at **1300 × 1100** for this pass. My proposed allocation is:

| Region | Approximate height |
|---|---:|
| Executive narrative and top controls | 100 px |
| Decision matrix, including its title and headers | 350 px |
| Application table, including its title | 180 px |
| Compact investigation header | 75 px |
| Baseline/stress horizontal container | **320 px** |
| Remaining space | Padding and control spacing |

These are layout targets, not exact requirements. The important change is giving the bottom comparison substantially more room.

Select the bottom **horizontal container**, not just one narrative sheet. Use its menu’s **Distribute Evenly** to give Baseline and stress equal widths. Then resize the surrounding sections using their borders or available Layout size controls. Tableau containers support this grouped resizing and equal distribution. [export reference: cite | turn584341search0 | turn394060view0]

For both scenario sheets, use approximately **12-point text**, left-aligned and top-aligned. Keep the text readable; do not shrink it to compensate for an undersized container.

**Our immediate acceptance target is that both complete Decision narratives are visible without internal scrolling.** Longer Structure or Source rationale text may need more room later.

A fixed dashboard taller than the available window will still have an outer scrollbar. That is separate from the nested worksheet scrollbars currently interrupting the explanations. [export reference: cite | turn394060view0]

# 4. Put a real header over the requested amounts

The application table’s rightmost dollar column currently lacks a header. Let’s label it properly.

On **04 — Application Detail**, retain the existing five fields on Rows and `Pair Key` on Detail. Then:

1. Remove `MIN(Requested Amount)` from **Text**.
2. Drag **Measure Values** onto **Text**.
3. Drag **Measure Names** onto **Columns**, then also onto **Filters**. In the filter, choose only **Requested Amount**.
4. On the **Measure Values** card, confirm that only Requested Amount remains and change its aggregation to **Minimum**.

This uses Tableau’s built-in measure-name headers to display **Requested Amount** above the values. Keep the currency format with zero decimal places. [export reference: cite | turn439511view0]

The `Pair Key` detail field and your existing application-selection action should remain untouched.

# 5. Clean the displayed titles without renaming the sheets

Edit the visible titles to make the dashboard read like a product rather than a workbook inventory:

| Existing visible title | Proposed display title |
|---|---|
| `03 — Executive Narrative` | **Portfolio interpretation** |
| `04 — Application Detail` | **Applications — click a requested amount to investigate** |
| `05 — Selection Narrative` | **Investigation selection** |
| `06 — Baseline Story` | **Baseline** |
| `07 — Stress Story` | **Recession Energy** |

Keep the numbered worksheet-tab names for authoring. Editing a worksheet title is separate from renaming its underlying sheet. [export reference: cite | turn584341search1]

# 6. Retest the same story after the layout changes

Use the existing **88-application** matrix cell and select Merchant **000003** again.

With **Narrative Detail = Decision**, the complete panels should establish:

| Baseline | Recession Energy |
|---|---|
| A potentially supportable **$42,500** structure is retained. | **28 usable sales days versus 30 required**, including **two disconnected processor-outage days**. |
| Review remains necessary near the approved capacity boundary. | Dependent assessment is withheld because required evidence is insufficient. |
| **The result is not an authorized offer.** | **The evidence gap does not establish that every alternative would fail.** |

Those are the values and distinctions in the imported Merchant 003 record. [export reference: filecite | turn108file0 | L16-L16]

Then switch the parameter to **Evidence**, and back to **Decision**. Both scenario panels should change together.

Finally, clear the application selection within the table. The investigation header should return to **88 applications**, and the scenario panels should return to their select-one-application guidance. The action’s **Show all values** clearing behavior removes that action’s selection restriction; the separate matrix action should still define the investigation population. [export reference: cite | turn394060view2]

---

**The foundation is now there: portfolio → decision pairing → application → explanation.** This pass makes the explanation usable—the part that will distinguish your dashboard from a matrix with a detail table.

Save locally, then send a dashboard screenshot with **Merchant 003 selected and both complete Decision paragraphs visible**. The next build pass will add the segment comparison and executive indicators without sacrificing this narrative space.
<!-- END_SOURCE_MESSAGE -->


<a id="m-25530bbd-5056-44fe-b3c1-ff0a73f13dfa"></a>
## Andrew / user · C123-M00424

C123-M00424 · 2026-10-15T22:02:41.092000-04:00 · active path

Preceding visible parent: [C123-M00423](part-36.md#m-9050718b-e204-4e27-b8a5-8d92280d0141)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-020142).png

<!-- BEGIN_SOURCE_MESSAGE -->
seems like there is still duplicative information here. Do we need to start off baseline story with BASELINE | Counteroffer review required Application: MSBF..._A01 and similarly, do we need to start off stress story in that same fashion. It seems like this information is already within the Selection Narrative.
<!-- END_SOURCE_MESSAGE -->


<a id="m-03949808-48ef-4177-9f70-df76d12a03df"></a>
## Assistant · C123-M00425

C123-M00425 · 2026-10-15T22:05:32.188933-04:00 · active path

Preceding visible parent: [C123-M00424](part-36.md#m-25530bbd-5056-44fe-b3c1-ff0a73f13dfa)

<!-- BEGIN_SOURCE_MESSAGE -->
**Yes. The repeated preambles should come out of both story panels.** The shared selection band already provides the context, and the panel titles identify the scenarios. My earlier formulas unnecessarily repeated that information before reaching the explanation.

The display should have three clear jobs:

| Element | What it should communicate |
|---|---|
| **Shared selection band** | Which merchant/application is selected and the two decision outcomes. |
| **Panel titles** | **Baseline** and **Recession Energy**. |
| **Panel bodies** | The actual explanation—decision rationale, operating evidence, or structure assessment. |

The long technical application identifier can remain in the application-table tooltip. It does not need to consume two lines across both narrative panels.

## 1. Replace the two existing story calculations

In the Data pane, right-click each calculated field below and choose **Edit**. Keep its existing name and replace its formula. Tableau updates the views using that calculation automatically; you do not need to recreate the worksheets or re-add the fields. [export reference: cite | turn457795search0]

### `Narrative - Baseline Story`

```tableau
IF COUNTD([Pair Key]) = 0 THEN
    "No application matches the current selection."

ELSEIF COUNTD([Pair Key]) > 1 THEN
    "Select one application to read its Baseline explanation."

ELSE
    IFNULL(
        CASE [Narrative Detail]
            WHEN "Decision" THEN
                MIN([Baseline Decision Narrative])

            WHEN "Evidence" THEN
                MIN([Baseline Evidence Narrative])

            WHEN "Structure" THEN
                MIN([Baseline Structure Narrative])

            WHEN "Source rationale" THEN
                "Technical source decision rationale; this may describe the independent scenario evaluation before final governance. "
                + MIN([Baseline Source Decision Why])
        END,
        "The selected narrative is unavailable in this source."
    )
END
```

### `Narrative - Stress Story`

```tableau
IF COUNTD([Pair Key]) = 0 THEN
    "No application matches the current selection."

ELSEIF COUNTD([Pair Key]) > 1 THEN
    "Select one application to read its Recession Energy explanation."

ELSE
    IFNULL(
        CASE [Narrative Detail]
            WHEN "Decision" THEN
                MIN([Stress Decision Narrative])

            WHEN "Evidence" THEN
                MIN([Stress Evidence Narrative])

            WHEN "Structure" THEN
                MIN([Stress Structure Narrative])

            WHEN "Source rationale" THEN
                "Technical source decision rationale; this may describe the independent scenario evaluation before final governance. "
                + MIN([Stress Source Decision Why])
        END,
        "The selected narrative is unavailable in this source."
    )
END
```

These replacements remove only the added scenario/status/application-ID preamble. They retain the single-application safeguard, all four **Narrative Detail** choices, the missing-narrative message, and the qualification on technical source rationale.

**Leave the selection-header calculation and dashboard actions unchanged.**

## 2. Simplify the visible panel titles

Your screenshot still shows the authoring titles. On each worksheet, right-click the displayed title and select **Edit Title**, then replace the title text with:

| Worksheet | Displayed title |
|---|---|
| `06 — Baseline Story` | **Baseline** |
| `07 — Stress Story` | **Recession Energy** |

Keep the numbered worksheet-tab names for authoring. Tableau allows the displayed title to differ from the sheet name. [export reference: cite | turn457795search6 | turn457795search7]

## What the reader should see afterward

The shared band identifies **Merchant 000003** and the two outcomes. Immediately below:

**Baseline**

> Counteroffer review required. A potentially supportable $42,500.00 structure is retained. Review remains necessary because the proposed structure sits near the approved capacity boundary. This result is not an authorized offer.

**Recession Energy**

> Declined because required decision evidence is insufficient. The required 30-day sales window has 28 usable days against 30 required, including 2 disconnected processor-outage day(s). The source withholds dependent assessment; missing evidence is not treated as zero or weak performance, and does not establish that every alternative would fail.

Those are the existing imported explanations for Merchant 003; we are changing their presentation, not their meaning. [export reference: filecite | turn108file0 | L16-L16]

I would **keep the outcome wording when it is part of the explanation itself**—such as “Counteroffer review required”—rather than mechanically stripping words from the source narrative. The unnecessary duplication is the extra header block above it.

**This gives the explanation the space currently occupied by repeated labels and identifiers, without reducing the font or losing decision context.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-97f60ee6-c372-468f-8c6a-b70dce5f1647"></a>
## Andrew / user · C123-M00426

C123-M00426 · 2026-10-15T22:19:41.309000-04:00 · active path

Preceding visible parent: [C123-M00425](part-36.md#m-03949808-48ef-4177-9f70-df76d12a03df)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-021935).png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e96d5479-d40d-4f38-a2a1-ec0233fd70cb"></a>
## Assistant · C123-M00427

C123-M00427 · 2026-10-15T22:30:26.722996-04:00 · active path

Preceding visible parent: [C123-M00426](part-36.md#m-97f60ee6-c372-468f-8c6a-b70dce5f1647)

<!-- BEGIN_SOURCE_MESSAGE -->
**That fixes the duplication. Both complete Decision narratives are now readable, and the merchant identity appears once in the shared selection band.** The screenshot also preserves the correct separation: the matrix selection is **88 applications**, Merchant **000003** is being investigated, and the executive narrative still describes the **750-application portfolio**.

For this selected application, the narrative presentation now works. **Leave those story calculations alone.**

The next useful addition is the management question:

> **Where are the Baseline-versus-stress differences concentrated—by industry or acquisition source?**

Let’s build that comparison, prepare the four executive indicators, and connect the portfolio filters. **Keep the existing dashboard arrangement for now** so we do not squeeze the narrative panels again.

## 1. Create two authorization-rate calculations

You already have the authorization counts and `Matched Applications`. These new measures divide each count by the matched population **within the current segment and filter scope**. Tableau’s aggregate calculations support this numerator/denominator pattern. [export reference: cite | turn832653view2]

Use **Analysis → Create Calculated Field**.

### `Baseline Authorization Rate`

```tableau
IF [Matched Applications] > 0 THEN
    [Baseline Authorizations] / [Matched Applications]
END
```

### `Stress Authorization Rate`

```tableau
IF [Matched Applications] > 0 THEN
    [Stress Authorizations] / [Matched Applications]
END
```

For both fields, set **Default Properties → Number Format → Percentage → 1 decimal place**. Leave the values as fractions; do not multiply the formulas by 100. Tableau’s percentage format handles that conversion. [export reference: cite | turn265860view1]

**These are authorization rates—not funding or collection rates.** The current extract does not establish cash transfers or servicing outcomes. [export reference: filecite | turn110file0 | L53-L59]

## 2. Create the industry/acquisition-source switch

Create a new parameter:

| Setting | Value |
|---|---|
| **Name** | `Review Segment By` |
| **Data type** | String |
| **Allowable values** | List |
| **Values** | `Industry`, `Acquisition Source` |
| **Current value** | `Industry` |

Then create a calculated field named **`Review Segment`**:

```tableau
CASE [Review Segment By]
    WHEN "Industry" THEN [Industry]
    WHEN "Acquisition Source" THEN [Acquisition Source]
END
```

Right-click the parameter and choose **Show Parameter**.

This switches the grouping used by the chart; it does not change the policy or remove applications. Tableau documents this parameter-plus-`CASE` approach for allowing readers to change dimensions interactively. [export reference: cite | turn265860view3]

## 3. Build `08 — Segment Comparison`

Create a **new blank worksheet**, not a duplicate of the filtered application-detail sheet. Name it:

```text
08 — Segment Comparison
```

Configure it as follows:

| Location | Field or setting |
|---|---|
| **Rows, first pill** | `Review Segment` |
| **Rows, second pill** | `Measure Names` |
| **Columns** | `Measure Values` |
| **Marks type** | Bar |
| **Color** | `Measure Names` |
| **Label** | `Measure Values` |
| **Tooltip** | `Matched Applications` |
| **Tooltip** | `Baseline Authorizations` |
| **Tooltip** | `Stress Authorizations` |

Drag **Measure Names** onto **Filters**, select **None**, and then select only:

```text
Baseline Authorization Rate
Stress Authorization Rate
```

On the **Measure Values** card, confirm that **only those two rates remain**. The result should be **two horizontal bars per segment**, sharing one rate axis—not stacked bars or two independently scaled axes. `Measure Names` and `Measure Values` are Tableau’s built-in mechanism for this multiple-measure view. [export reference: cite | turn832653view0]

Use this displayed title:

```text
Authorization rates by segment
Baseline vs. Recession Energy | Hover for application counts
```

For the initial presentation, sort segments alphabetically, use **Entire View**, and keep the shared rate axis starting at zero. Give the two scenarios distinct, restrained colors, such as navy and teal. The colors identify scenarios; they should not imply “safe” versus “unsafe.”

### What to check

I recalculated the segment totals directly from your current import CSV. These are reference checks—not values to type into the chart:

| Segment | Matched applications | Baseline authorized | Stress authorized | Baseline rate | Stress rate |
|---|---:|---:|---:|---:|---:|
| Healthcare Services | 82 | 15 | 4 | **18.3%** | **4.9%** |
| Professional Services | 112 | 30 | 8 | **26.8%** | **7.1%** |
| Digital Direct | 150 | 17 | 2 | **11.3%** | **1.3%** |

With **Review Segment By = Industry**, you should have **eight groups and sixteen bars**. Switch to **Acquisition Source**, and you should have **five groups and ten bars**.

Download the recalculated segment checks (historical reference: `sandbox:[session]/MCI_Tableau_Segment_Checks.csv`; referenced bytes not established here)

**Do not connect that check file as another Tableau table.** It is only a reconciliation reference.

## 4. Prepare four executive-indicator sheets

Use **new blank worksheets** for these, with **Text** marks and empty **Rows, Columns, and Detail**. That gives each sheet one aggregate value or value-and-rate combination. [export reference: cite | turn832653view2]

| Worksheet | Fields to place on Text | Intended display |
|---|---|---|
| **09 — KPI Matched Applications** | `Matched Applications` | **750** / Matched applications |
| **10 — KPI Different Decisions** | `Different Decisions`, `Different Decision Rate` | **236** / Different category · **31.5%** |
| **11 — KPI Baseline Authorized** | `Baseline Authorizations`, `Baseline Authorization Rate` | **103** / Baseline authorized · **13.7%** |
| **12 — KPI Stress Authorized** | `Stress Authorizations`, `Stress Authorization Rate` | **27** / Stress authorized · **3.6%** |

Use approximately **28-point text for the main number** and **11–12 points for its label**. Center each card and turn off its tooltip.

When editing the text, **retain the inserted field tokens**. Type only the descriptive labels, never the numbers. Keep counts at zero decimal places and rates at one decimal place. [export reference: cite | turn265860view1]

**Do not place these sheets on the dashboard yet.** First, we will verify that the indicators, matrix, segment chart, and narrative all respond to the same portfolio filters.

## 5. Add two shared portfolio filters

These filters define the population being reviewed. They are different from your existing matrix-cell and application-selection actions.

On **03 — Executive Narrative**:

1. Drag **Industry** to **Filters**, include all values, and select **Show Filter**.
2. Do the same for **Acquisition Source**.
3. For each filter pill, select **Apply to Worksheets → Selected Worksheets**.
4. Select **all analytical worksheets from 02 through 12**.

Leave **00 — Population Check** and **01 — Scenario Controls** unselected. Those two sheets will remain your unfiltered reference checks.

Tableau’s **Selected Worksheets** option shares a filter across explicitly chosen sheets rather than applying it indiscriminately throughout the workbook. [export reference: cite | turn265860view2]

On the dashboard, select the executive-narrative sheet’s dropdown menu and show **Filters → Industry** and **Filters → Acquisition Source**. Use dropdown filter cards to conserve space.

**Keep both existing dashboard actions unchanged.** In particular, do not add the new KPI or segment sheets as targets of the matrix or application actions. The intended behavior remains:

| Interaction | What changes |
|---|---|
| Industry or Acquisition Source filter | Portfolio indicators, executive narrative, matrix, segment chart, application list, and individual stories |
| Matrix-cell selection | Investigation population and its detail—not portfolio totals |
| Application selection | Individual comparison and story panels—not portfolio totals |

This preserves the filter separation specified in your setup guide. [export reference: filecite | turn110file0 | L17-L33]

## 6. Test the filtered portfolio before changing the layout

**Clear the selected application and matrix cell first.** Otherwise, their existing action filters may intersect with the new portfolio filters. That intersection is a known behavior to check; an empty detail area must not be mistaken for a completed narrative. [export reference: filecite | turn110file0 | L29-L35]

Then run these three checks:

| Portfolio filter | Matched applications | Different decisions | Different rate | Baseline authorized | Stress authorized |
|---|---:|---:|---:|---:|---:|
| All industries; all sources | **750** | **236** | **31.5%** | **103** | **27** |
| Healthcare Services; all sources | **82** | **29** | **35.4%** | **15** | **4** |
| Healthcare Services; Digital Direct | **18** | **7** | **38.9%** | **3** | **1** |

These filtered controls are included in the recalculated check file (historical reference: `sandbox:[session]/MCI_Tableau_Segment_Checks.csv`; referenced bytes not established here).

Under **Healthcare Services only**, the executive narrative should say:

> In this filtered portfolio of **82 matched applications, 29 (35.4%)** have different final decision categories. Authorized: **15 in Baseline versus 4 in Recession Energy**.

The corresponding KPI sheets should agree. Switching `Review Segment By` should change the grouping, **not those overall filtered totals**.

## Where this leaves the build

Your current screenshot demonstrates the **application-investigation layer**. This next pass adds the **portfolio-segmentation layer** without disturbing the readable explanations.

There is one small outstanding presentation item in the screenshot: the rightmost dollar column still needs its **Requested Amount** header. That is a labeling fix, not a reason to change the application data or selection action.

**Save locally, then send the Segment Comparison worksheet and the executive narrative with Healthcare Services selected.** Once those agree, we can place the executive indicators and segment view deliberately—without taking space back from the story panels we just fixed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fb000dd5-783c-40a1-b598-9366a0ebc10d"></a>
## Andrew / user · C123-M00428

C123-M00428 · 2026-10-15T22:39:59.533000-04:00 · active path

Preceding visible parent: [C123-M00427](part-36.md#m-e96d5479-d40d-4f38-a2a1-ec0233fd70cb)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-023935).png; image(20261016-023952).png

<!-- BEGIN_SOURCE_MESSAGE -->
have I set up these parameters correctly? it seems like nothing changes when I adjust the drop downs.
<!-- END_SOURCE_MESSAGE -->


<a id="m-61ca33b0-fee7-4039-9bb4-693d26b2ff68"></a>
## Assistant · C123-M00429

C123-M00429 · 2026-10-15T22:43:08.564511-04:00 · active path

Preceding visible parent: [C123-M00428](part-36.md#m-fb000dd5-783c-40a1-b598-9366a0ebc10d)

<!-- BEGIN_SOURCE_MESSAGE -->
**Yes—both parameter definitions are correct in your screenshots. Do not recreate them.** The question now is whether you are changing the active value and whether the displayed worksheets are using the calculations connected to that parameter.

A Tableau parameter holds a value; it does **not** automatically change a chart or narrative. The worksheet must use a calculation that references it. [export reference: cite | turn507262search0]

Here is what our two controls are intended to affect:

| Parameter | Should change | Should not change |
|---|---|---|
| **Narrative Detail** | The explanatory paragraphs in **Baseline Story** and **Stress Story**, when one application is selected. | Executive totals, matrix, application list, or selection header. |
| **Review Segment By** | The grouping in **08 — Segment Comparison**: industry versus acquisition source. | Overall portfolio totals, the decision matrix, or merchant narratives. |

## 1. First, use the parameter control—not the list in the editing window

Your screenshots show **Edit Parameter** dialogs.

The grid under **Allowable values** defines the available choices. Clicking a row there is not the same as changing the active parameter value. The active choice is shown under **Current value**—currently **Decision** and **Industry** in your screenshots.

For normal use:

1. Click **OK** to close the editing dialog.
2. In the worksheet’s Data pane, locate the parameter under **Parameters**.
3. Right-click it and select **Show Parameter**.
4. Change the selection in the small parameter card that appears beside the view.

You can also change **Current value** in the editing dialog and click **OK**, but the visible parameter card is the intended interactive control. **Leave “Fixed” selected**: it fixes the list of available options, not the user’s ability to switch between them. [export reference: cite | turn507262search0]

## 2. Test `Narrative Detail` with Merchant 000003 selected

On your dashboard, select the **88-application** matrix cell, then select Merchant **000003** in the application table, as you did successfully before.

Now use the **Narrative Detail** card to switch from **Decision** to **Structure**.

**Watch the two story paragraphs at the bottom—not the executive paragraph or selection header.** Our formulas intentionally leave those other elements unchanged.

For Merchant 000003, these choices should produce noticeably different explanations:

| Choice | Expected content |
|---|---|
| **Decision** | Baseline explains the **$42,500 review-required alternative**. Stress explains the insufficient-evidence decision. |
| **Evidence** | The paragraphs describe merchant operating facts, balances, verification, and sales-history availability. |
| **Structure** | Baseline starts with the **$61,300 request** and includes **11 candidate evaluations** and the **$42,500 selected structure**. Stress describes the blocked assessment and unavailable selected terms. |

Those distinct paragraphs are present in the imported Merchant 003 record. [export reference: filecite | turn108file0 | L16-L16]

### If the paragraphs remain identical

Open the individual worksheets and inspect **Marks → Text**:

| Worksheet | The field on Text must be |
|---|---|
| **06 — Baseline Story** | `AGG(Narrative - Baseline Story)` |
| **07 — Stress Story** | `AGG(Narrative - Stress Story)` |

They must **not** use the raw fields `Baseline Decision Narrative` or `Stress Decision Narrative` directly. Those raw fields always contain the decision paragraph; the calculated fields select the paragraph according to the parameter.

Then right-click each story calculation in the Data pane → **Edit**. Confirm it contains:

```tableau
CASE [Narrative Detail]
```

with branches for `Decision`, `Evidence`, `Structure`, and `Source rationale`. **Do not remove the existing `COUNTD([Pair Key])` safeguards.**

One important expected behavior: when multiple applications are in scope, our formulas display **“Select one application…”** regardless of the parameter choice. The detail selector only changes the story after exactly one application reaches that worksheet. The setup guide specifies this single-application interaction. [export reference: filecite | turn110file0 | L21-L24]

## 3. Test `Review Segment By` on the segment worksheet

**In the last dashboard screenshot you sent, the segment chart had not yet been added.** Changing its parameter therefore would not visibly affect that dashboard’s existing matrix or narratives.

Open **08 — Segment Comparison** directly.

Its first Rows pill must be the **calculated field `Review Segment`**, not the raw `Industry` field and not the parameter `Review Segment By`.

The calculation should be:

```tableau
CASE [Review Segment By]
    WHEN "Industry" THEN [Industry]
    WHEN "Acquisition Source" THEN [Acquisition Source]
END
```

The relevant worksheet arrangement should be:

```text
Rows:       Review Segment | Measure Names
Columns:    Measure Values
```

Show the **Review Segment By** parameter card on that worksheet and switch to **Acquisition Source**. The row labels should change from industries such as **Healthcare Services** to sources such as **Digital Direct**.

The essential connection is:

**Parameter selection → `Review Segment` calculation → field actually used on Rows.**

Creating the calculation without placing it in the view—or leaving `Industry` on Rows—does not make the chart switch. This is the same connection Tableau documents for parameter-driven dimension changes. [export reference: cite | turn507262search1]

---

**Start with the simplest test: select Merchant 000003, then change Narrative Detail to Structure using the visible dashboard control.** If its Baseline paragraph still starts “Counteroffer review required,” send the **06 — Baseline Story worksheet** with both its **Marks card and Narrative Detail control visible**. That will show whether the missing connection is the active parameter value or the field on Text.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b8aff37a-0fb8-49ba-b596-aaece8b018d7"></a>
## Andrew / user · C123-M00430

C123-M00430 · 2026-10-15T23:30:16.815000-04:00 · active path

Preceding visible parent: [C123-M00429](part-36.md#m-61ca33b0-fee7-4039-9bb4-693d26b2ff68)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-032906).png; image(20261016-032933).png; image(20261016-032949).png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->
