# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 39 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-38.md)
[Next part](part-40.md)

<a id="m-11526322-bb9d-4cd9-bd3a-054826a4195c"></a>
## Assistant · C123-M00474

C123-M00474 · 2026-10-16T12:23:30.593894-04:00 · active path

Preceding visible parent: [C123-M00473](part-38.md#m-675b942c-3429-4e06-853c-42e2b76fccb5)

<!-- BEGIN_SOURCE_MESSAGE -->
Great. Since you've already removed the extra filter and cleaned up the Marks card, **we can proceed directly to testing the selected-pairing calculation.**

Your screenshots establish the exact decision-code format Tableau is using. We no longer need to guess at the values.

## 1. Use these exact parameter values

For our first test, we'll use the pairing containing **88 applications**:

**Counteroffer review required → Evidence decline**

Set the parameters as follows.

**Selected Baseline Decision Code**

```text
COUNTEROFFER_REVIEW_REQUIRED
```

**Selected Stress Decision Code**

```text
DECLINE_INSUFFICIENT_EVIDENCE
```

The second code is directly confirmed in your screenshot. The first is consistent with the naming convention, but **your screenshots do not actually show the Baseline code for the 88-application cell**. We should verify that code before treating the test as passed.

### How to confirm it

Return to `02 — Decision Matrix` and hover specifically over the cell containing **88**.

Its tooltip should show:

- Baseline Decision: Counteroffer review required
- Stress Decision: Evidence decline
- Baseline Decision Code: the exact code we need
- Stress Decision Code: `DECLINE_INSUFFICIENT_EVIDENCE`

Copy the Baseline code exactly as Tableau displays it.

Then:

1. Right-click `Selected Baseline Decision Code` under **Parameters** → **Edit**.
2. Enter the confirmed code in **Current value**.
3. Click **OK**.
4. Repeat for `Selected Stress Decision Code`, entering `DECLINE_INSUFFICIENT_EVIDENCE`.

Both parameters should retain **Allowable values = All**.

## 2. Return to worksheet 13

Open:

**13 — Selected Segment Pairing Concentration**

Make sure the portfolio filters include all industries and all acquisition sources.

The chart should now display nonzero incidence rates.

For **Healthcare Services**, our established control is:

<box border radius="lg" padding={3} gap={2}>
  <text weight="medium">Healthcare Services</text>
  <row align="baseline" justify="between">
    <title size="2xl" tabularNums>12.2%</title>
    <text color="secondary" size="sm">10 affected / 82 applications</text>
  </row>
  <box background="surface-tertiary" radius="full" height="12px" clip>
    <box background="#438d9c" width="12.2%" height="100%" radius="full"/>
  </box>
</box>

This test establishes that the chart is counting applications in the selected decision pairing while keeping the denominator at the full Healthcare Services population.

## 3. If Healthcare Services still shows 0.0%

Check the two parameters first. A mismatch of even one character will prevent the flag from matching.

Then verify that `Selected Pairing Flag` contains:

```tableau
IF [Selected Baseline Decision Code] = "ALL"
   OR [Selected Stress Decision Code] = "ALL" THEN
    0
ELSEIF [Baseline Decision Code] = [Selected Baseline Decision Code]
   AND [Stress Decision Code] = [Selected Stress Decision Code] THEN
    1
ELSE
    0
END
```

Your worksheet should not have a filter restricting it to the selected decision pairing, and it should not retain the old Baseline Authorizations filter.

## 4. Then automate the selection

Once the manual test passes, create the two dashboard parameter actions.

Go to **Dashboard → Actions → Add Action → Change Parameter**.

| Setting | Baseline action | Stress action |
|---|---|---|
| Name | Set Baseline Pairing | Set Stress Pairing |
| Source sheet | 02 — Decision Matrix | 02 — Decision Matrix |
| Run on | Select | Select |
| Target parameter | Selected Baseline Decision Code | Selected Stress Decision Code |
| Source field | Baseline Decision Code | Stress Decision Code |
| Aggregation | None | None |
| Clearing selection | Set value to `ALL` | Set value to `ALL` |

Keep the existing matrix-to-application filter action. The new parameter actions serve a different purpose: they transmit the selected pairing to worksheet 13 **without filtering away the denominator**.

## 5. Important next design decision

We should ultimately display the two segment analyses as alternative modes:

**Portfolio authorization rates** — the existing worksheet 08.

**Selected decision-pairing incidence** — worksheet 13.

That will preserve both capabilities without overcrowding the dashboard.

But first, we need the calculation to pass its source-data test.

**Next checkpoint:** Hover over the **88** cell, confirm its exact Baseline Decision Code, enter the two parameter values, and check whether Healthcare Services shows **12.2%** on worksheet 13.

Once that works, we're ready to connect the parameter actions and make this an interactive extension of your risk-review dashboard.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1c4e6c72-17bc-4747-afb8-889b2b4d932a"></a>
## Andrew / user · C123-M00475

C123-M00475 · 2026-10-16T12:36:15.526000-04:00 · active path

Preceding visible parent: [C123-M00474](part-39.md#m-11526322-bb9d-4cd9-bd3a-054826a4195c)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-163449).png

<!-- BEGIN_SOURCE_MESSAGE -->
I updated Selected Baseline Decision Code and Selected Stress Decision Code parameters as:  Are you now saying that I am replacing those with Set Baseline Pairing and Set Stress Pairing?
<!-- END_SOURCE_MESSAGE -->


<a id="m-f73cadf8-4e6e-433d-9fd9-5aa6542f4a9c"></a>
## Assistant · C123-M00476

C123-M00476 · 2026-10-16T12:36:24.082012-04:00 · active path

Preceding visible parent: [C123-M00475](part-39.md#m-1c4e6c72-17bc-4747-afb8-889b2b4d932a)

<!-- BEGIN_SOURCE_MESSAGE -->
**No. Keep both parameters exactly as you've created them.** You are not replacing or renaming anything.

The distinction is:

- **Parameters** store the selected decision codes.
- **Parameter actions** automatically update those parameters when you click a cell in the decision matrix.

The names `Set Baseline Pairing` and `Set Stress Pairing` are names for the **new dashboard actions**, not replacements for your existing parameters.

### How the pieces work together

<box border radius="lg" padding={3} gap={2} align="center">
  <box background="surface-secondary" radius="md" padding={3} width="100%" align="center" gap={1}>
    **02 — Decision Matrix**
    <text size="xs" textAlign="center">You click a decision pairing, such as Counteroffer review → Evidence decline</text>
  </box>
  <icon name="arrow-down" color="secondary" size="lg"/>
  <grid columns={2} gap={2}>
    <grid-item>
      <box border radius="md" padding={2} gap={1} align="center">
        <text weight="medium" size="xs" textAlign="center">Action: Set Baseline Pairing</text>
        <icon name="arrow-down" color="secondary"/>
        <text size="2xs" textAlign="center">Parameter: Selected Baseline Decision Code</text>
      </box>
    </grid-item>
    <grid-item>
      <box border radius="md" padding={2} gap={1} align="center">
        <text weight="medium" size="xs" textAlign="center">Action: Set Stress Pairing</text>
        <icon name="arrow-down" color="secondary"/>
        <text size="2xs" textAlign="center">Parameter: Selected Stress Decision Code</text>
      </box>
    </grid-item>
  </grid>
  <icon name="arrow-down" color="secondary" size="lg"/>
  <box background="surface-secondary" radius="md" padding={3} width="100%" align="center" gap={1}>
    **13 — Selected Segment Pairing Concentration**
    <text size="xs" textAlign="center">Recalculates the affected counts and within-segment incidence</text>
  </box>
</box>

### One detail in your screenshot

Your parameter currently has **Allowable values = List**, with technical codes in the **Value** column and readable decision labels in **Display As**.

That is a good setup. It lets Tableau store the exact codes while displaying readable labels.

**Keep it as List.** My earlier instructions said to use `All`, but your configured list is actually preferable because it restricts the parameter to valid decision codes.

There is just one adjustment: **add `ALL` as an allowable value to each parameter**, with `All pairings` in the Display As column. This gives the parameter actions a valid reset value when you clear the matrix selection.

Then create the two dashboard actions:

| Action name | Target parameter | Source field |
|---|---|---|
| `Set Baseline Pairing` | `Selected Baseline Decision Code` | `Baseline Decision Code` |
| `Set Stress Pairing` | `Selected Stress Decision Code` | `Stress Decision Code` |

Both actions should use **02 — Decision Matrix** as their source worksheet, run on **Select**, and reset to `ALL` when the selection is cleared.

**One more check:** Your screenshot shows the Baseline parameter's current value as *Approve as requested – authorized*. For the manual 88-application test, select *Counteroffer review required* in that dropdown, and select *Evidence decline* in the Stress parameter. The underlying values—not the displayed labels—will be compared in the calculation.

Once worksheet 13 shows the expected **10 of 82 Healthcare Services applications (12.2%)**, we can create and test the automatic actions.

**So the order is: keep your parameters → add the `ALL` reset option → verify the manual test → create the two parameter actions.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-290bcc27-44ae-494b-b612-b63b48d9a555"></a>
## Andrew / user · C123-M00477

C123-M00477 · 2026-10-16T12:44:25.029000-04:00 · active path

Preceding visible parent: [C123-M00476](part-39.md#m-f73cadf8-4e6e-433d-9fd9-5aa6542f4a9c)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-164410).png

<!-- BEGIN_SOURCE_MESSAGE -->
test passed - ready to move on to the dashboard update
<!-- END_SOURCE_MESSAGE -->


<a id="m-17a3b15e-b443-4e79-8d69-0ee30936c3d2"></a>
## Assistant · C123-M00478

C123-M00478 · 2026-10-16T12:44:34.806242-04:00 · active path

Preceding visible parent: [C123-M00477](part-39.md#m-290bcc27-44ae-494b-b612-b63b48d9a555)

<!-- BEGIN_SOURCE_MESSAGE -->
**Excellent. The manual test passes.** Your screenshot shows the correct decision pairing, nonzero segment incidence rates, and the expected **12.2% for Healthcare Services (10 of 82 applications)**.

We're ready to integrate worksheet `13 — Selected Segment Pairing Concentration` into the dashboard.

I recommend doing this without disturbing your existing authorization-rate chart or the merchant investigation workflow.

## 1. Final dashboard behavior

We want Section 03 to support two analytical views:

| Mode | What it answers |
|---|---|
| **Portfolio Authorization** | How do Baseline and Recession Energy authorization rates compare across industries or acquisition sources? |
| **Selected Pairing** | Where is the selected decision pairing concentrated, measured against each segment's full matched population? |

The second mode should update when you click a matrix cell, without altering portfolio KPIs or denominator populations.

For this build, I recommend **a user-controlled view switch**, rather than automatically changing the chart every time a matrix cell is selected. That makes the analytical context explicit.

## 2. Create the display-mode parameter

In Tableau's Data pane, right-click → **Create Parameter**.

Configure:

| Property | Value |
|---|---|
| Name | `Segment Analysis Mode` |
| Data type | String |
| Allowable values | List |
| Current value | `Portfolio Authorization` |

Add these list values:

```text
Portfolio Authorization
Selected Pairing
```

Click **OK**.

Then create two calculated fields.

**`Show Portfolio Authorization`**

```tableau
[Segment Analysis Mode] = "Portfolio Authorization"
```

**`Show Selected Pairing`**

```tableau
[Segment Analysis Mode] = "Selected Pairing"
```

These Boolean fields will control which worksheet is visible.

## 3. Connect the matrix to your decision-code parameters

Return to **Risk Decision & Scenario Review**.

Open **Dashboard → Actions → Add Action → Change Parameter**.

Create the first action:

| Setting | Value |
|---|---|
| Name | `Set Baseline Pairing` |
| Source sheet | `02 — Decision Matrix` |
| Run action on | Select |
| Target parameter | `Selected Baseline Decision Code` |
| Source field | `Baseline Decision Code` |
| Aggregation | None |
| Clearing selection | Set value to `ALL` |

Create a second action:

| Setting | Value |
|---|---|
| Name | `Set Stress Pairing` |
| Source sheet | `02 — Decision Matrix` |
| Run action on | Select |
| Target parameter | `Selected Stress Decision Code` |
| Source field | `Stress Decision Code` |
| Aggregation | None |
| Clearing selection | Set value to `ALL` |

**Important:** The parameter actions should not target the KPI sheets or the executive narrative. They update only the two parameter values; worksheet 13 responds through its calculated fields.

Your existing `Select decision pairing` filter action should remain unchanged.

### Verify the actions

Click the **88-application** matrix cell:

**Counteroffer review required → Evidence decline**

The two decision-code parameters should update to the corresponding codes.

Open worksheet 13. Its values should match your manual test.

Clear the matrix selection. Both parameters should reset to `ALL`, and worksheet 13 should show 0% across segments.

That zero state is mathematically expected, but we will make its interpretation clearer before publication.

## 4. Add both segment worksheets to Section 03

We will use Tableau's **Dynamic Zone Visibility** if your Tableau Public version supports it.

### A. Prepare the dashboard container

1. Return to the dashboard.
2. Select the existing `08 — Segment Comparison` worksheet.
3. Open **Layout → Item hierarchy** to identify its current parent.
4. Keep worksheet 08 in its existing right-side analytical panel.
5. Add worksheet `13 — Selected Segment Pairing Concentration` to the same panel.

Initially, both may be visible. That's fine—we'll configure visibility next.

### B. Configure worksheet 08 visibility

1. Select worksheet `08 — Segment Comparison` on the dashboard.
2. Open the **Layout** pane.
3. Locate **Control visibility using value**.
4. Select `Show Portfolio Authorization`.

### C. Configure worksheet 13 visibility

1. Select worksheet `13 — Selected Segment Pairing Concentration`.
2. Under **Control visibility using value**, select `Show Selected Pairing`.

Tableau should now show only the worksheet corresponding to the selected parameter value.

If your version does not expose **Control visibility using value**, stop there rather than using filters to simulate visibility. We can use a supported alternative.

### D. Add the mode selector

On the dashboard, open the dropdown for either segment worksheet and choose:

**Parameters → Segment Analysis Mode**

Place that parameter card immediately beneath your Section 03 heading, near the existing `Review Segment By` control.

You can leave `Review Segment By` in your top control bar because it applies to both segment worksheets.

The intended arrangement is:

```text
03 / SEGMENT SENSITIVITY

Analysis Mode: [Portfolio Authorization ▼]

[Authorization-rate chart]

or

Analysis Mode: [Selected Pairing ▼]

[Selected-pairing incidence chart]
```

Keep the same panel width and height in both modes.

## 5. Update worksheet 13's presentation

Before considering the build complete, make three changes.

**Title:** Replace its inherited authorization-rate title with:

**Selected Pairing Concentration**

**Subtitle:** Use:

> Share of each segment's matched applications belonging to the selected decision pairing.

**Tooltip:** Include:

```text
Segment: <Review Segment>
Affected applications: <Selected Pairing Applications>
Segment applications: <Segment Applications>
Within-segment incidence: <Selected Pairing Incidence>
```

Use Tableau's **Insert** menu for the actual field tokens.

### Optional improvement

I would keep the segment bars sorted descending by selected-pairing incidence. Your current screenshot shows the sort order inherited from the original authorization-rate chart, so this is worth checking.

## 6. Correct the empty-selection behavior

When both selected-decision parameters are `ALL`, worksheet 13 currently shows 0% across segments.

For an executive audience, that can misleadingly look like a genuine zero-incidence result.

Create:

**`Selected Pairing Status`**

```tableau
IF [Selected Baseline Decision Code] = "ALL"
   OR [Selected Stress Decision Code] = "ALL" THEN
    "Select a decision pairing in the matrix to view its segment concentration."
ELSE
    "Showing the selected decision pairing across the portfolio-filtered segment population."
END
```

Add this as a small text worksheet above the pairing chart, or use it in the chart's displayed caption.

**Do not interpret the all-zero state as evidence that no applications match a pairing.** It means no pairing has been selected.

## 7. End-to-end test

Once both segment views are available, test these states:

| Action | Expected result |
|---|---|
| Clear all portfolio filters | KPIs remain **750 / 236 / 103 / 27** |
| Portfolio Authorization mode | Original Baseline/stress authorization bars appear |
| Select 88-application matrix cell | Application list narrows to **88** |
| Switch to Selected Pairing mode | Healthcare Services shows **12.2%** |
| Select Merchant 000003 | Scenario explanations update; portfolio KPIs and pairing chart remain unchanged |
| Switch Review Segment By | Pairing chart changes between Industry and Acquisition Source |
| Clear matrix selection | Pairing parameters reset; chart displays selection guidance |
| Return to Portfolio Authorization | Original authorization-rate chart returns |

**One outstanding issue remains:** In your earlier dashboard screenshot, the KPI cards fell to **1 / 1 / 1 / 0** after selecting an application while the executive narrative still showed 750. Before publication, verify that the KPI sheets are excluded from both investigation actions and that no additional worksheet filter is reaching them.

---

**Next checkpoint:** Complete the two parameter actions first. Then confirm whether **Control visibility using value** is available in your Tableau Public Layout pane. That determines whether we can use the clean one-panel, two-mode design directly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dbf8f9d0-71b5-428f-861d-7f4e97590540"></a>
## Andrew / user · C123-M00479

C123-M00479 · 2026-10-16T12:53:49.337000-04:00 · active path

Preceding visible parent: [C123-M00478](part-39.md#m-17a3b15e-b443-4e79-8d69-0ee30936c3d2)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-165304).png; image(20261016-165317).png

<!-- BEGIN_SOURCE_MESSAGE -->
full hierarchy - please review and advise in more detail knowing this. thanks. proceed again from step 4.
<!-- END_SOURCE_MESSAGE -->


<a id="m-71ba655c-3003-4355-b2f7-48b39a041076"></a>
## Assistant · C123-M00480

C123-M00480 · 2026-10-16T12:54:04.312939-04:00 · active path

Preceding visible parent: [C123-M00479](part-39.md#m-dbf8f9d0-71b5-428f-861d-7f4e97590540)

<!-- BEGIN_SOURCE_MESSAGE -->
Your hierarchy screenshots clarify the situation considerably. **We can preserve the existing dashboard and integrate worksheet 13 without rebuilding any of the five sections.**

I also see why the earlier instructions were difficult to follow: your Tableau dashboard contains several nested tiled containers, and the two analytical charts already share a horizontal container. That gives us a specific place to make the change.

## 1. What your current hierarchy tells us

At the bottom of your second screenshot, the relevant structure is:

```text
Horizontal Container
    02 - Decision Matrix
    08 - Segment Comparison
```

**That is the exact container we want to work with.**

The rest of the dashboard is already organized:

| Existing area | Status | Action |
|---|---|---|
| Header, controls and four KPI cards | Built | Preserve |
| 01 — Portfolio Interpretation | Built | Preserve |
| 02 — Decision Matrix | Built | Preserve |
| 03 — Segment Sensitivity (`08`) | Built | Add alternate view |
| 04 — Application Investigation | Built | Preserve |
| 05 — Merchant Evidence & Decision Interpretation | Built | Preserve |

Your screenshots also confirm that `08 — Segment Comparison` is a direct child of the same horizontal container as `02 — Decision Matrix`. We should **not move the matrix or its parent container**.

The goal is to make the right-hand panel switch between worksheet 08 and worksheet 13, while the matrix remains permanently visible on the left.

## 2. Step 4 — Prepare the right-hand chart panel

We will change the structure from:

```text
Horizontal Container
    02 - Decision Matrix
    08 - Segment Comparison
```

to:

```text
Horizontal Container
    02 - Decision Matrix
    Vertical Container
        08 - Segment Comparison
        13 - Selected Segment Pairing Concentration
```

The two segment worksheets will occupy the same right-hand panel, but only one will be visible at a time.

### A. Save a recovery copy first

Choose **File → Save As** and save a new local workbook named:

`MCI_Risk_Decision_Scenario_Review_R2`

This preserves your functioning R1 layout while we configure the new visibility behavior.

### B. Add the right-hand vertical container

1. Return to the **Dashboard** tab in the left sidebar.
2. Under Objects, select **Tiled**.
3. Drag a **Vertical** container toward the existing `08 — Segment Comparison` chart.
4. Watch the placement highlight. You want the container in the right-hand analytical panel, not across the entire dashboard.
5. Release when Tableau highlights the appropriate right-hand area.

If Tableau moves or shrinks the matrix unexpectedly, press **Ctrl+Z** immediately.

### C. Move worksheet 08 inside it

Select `08 — Segment Comparison` on the dashboard. Use the gray grab handle at the top of its border to drag it into the new vertical container.

Then drag `13 — Selected Segment Pairing Concentration` from the Sheets list into the same vertical container, below worksheet 08.

Your Layout hierarchy should show:

```text
Horizontal Container
    02 - Decision Matrix
    Vertical Container
        08 - Segment Comparison
        13 - Selected Segment Pairing Concentration
```

**Stop and verify this hierarchy before proceeding.** If worksheet 13 appears underneath the entire decision matrix and application table, it was dropped into the wrong parent.

At this stage, both segment charts may appear stacked and compressed. That's temporary.

## 3. Step 5 — Configure Dynamic Zone Visibility

You already created:

- `Segment Analysis Mode`
- `Show Portfolio Authorization`
- `Show Selected Pairing`

We will now connect those calculations to the two worksheets.

### A. Configure worksheet 08

1. In **Layout → Item hierarchy**, select `08 — Segment Comparison`.
2. Find **Control visibility using value** in the Layout pane.
3. Enable that option.
4. Select `Show Portfolio Authorization`.

The calculation should be:

```tableau
[Segment Analysis Mode] = "Portfolio Authorization"
```

### B. Configure worksheet 13

Select `13 — Selected Segment Pairing Concentration` in the hierarchy.

Enable **Control visibility using value** and select:

`Show Selected Pairing`

Its calculation should be:

```tableau
[Segment Analysis Mode] = "Selected Pairing"
```

These calculations should be Boolean fields, returning True or False.

### C. Test the visibility

Temporarily show the `Segment Analysis Mode` parameter control on the dashboard.

Switch between:

- **Portfolio Authorization** — worksheet 08 appears.
- **Selected Pairing** — worksheet 13 appears.

The matrix should remain visible in both modes, and the segment chart should occupy the right-hand analytical panel.

If **Control visibility using value** is unavailable, or the two charts remain stacked, do not try to fix it by adding filters or converting the entire dashboard to Floating. Send me the Layout pane for worksheet 08. We'll use a different supported arrangement.

## 4. Step 6 — Update Section 03's heading and controls

Your current heading is:

**03 / SEGMENT SENSITIVITY — Authorization Rates by selected grouping**

That will no longer accurately describe both chart modes.

I recommend:

**03 / SEGMENT SENSITIVITY** — Compare authorization rates or investigate selected decision pairings.

This retains your established numbered-section style.

### Place the new selector

Your top control row currently contains:

- Industry
- Acquisition Source
- Review Segment By
- Matched Application Count legend
- Scenario legend

I would **not add a sixth control to that row**. It is already balanced.

Instead, place `Segment Analysis Mode` immediately beneath the Section 03 heading and above the active segment chart.

Use the parameter card's dropdown to select **Single Value (Dropdown)**.

The right-hand panel should read:

<box border radius="lg" padding={3} gap={2}>
  <text weight="medium" size="sm">03 / SEGMENT SENSITIVITY</text>
  <text color="secondary" size="xs">Compare authorization rates or investigate selected decision pairings</text>
  {@body const [mode,setMode] = DIL.useState("authorization")}
  <box gap={1}>
    <label>Analysis Mode</label>
    <segmented-control block size="md" value={mode} onChange={setMode} options={[{"label":"Portfolio Authorization","value":"authorization"},{"label":"Selected Pairing","value":"pairing"}]}/>
  </box>
  {#if mode==="authorization"}
    <text size="xs" weight="medium">Authorization rates by industry</text>
    <Chart content={{"chartType":"bar","meta":{"footer":"Illustrative subset of your verified full-population rates"},"xKey":"segment","series":[{"dataKey":"baseline","label":"Baseline","valueSuffix":"%"},{"dataKey":"stress","label":"Recession Energy","valueSuffix":"%"}],"layout":"vertical","data":[{"segment":"Professional Services","baseline":26.8,"stress":7.1},{"segment":"Healthcare Services","baseline":18.3,"stress":4.9},{"segment":"Ecommerce Digital","baseline":16.2,"stress":4.4}]}}/>
  {:else}
    <text size="xs" weight="medium">Counteroffer review → Evidence decline</text>
    <row align="baseline" justify="between">
      <title size="xl">12.2%</title>
      <text color="secondary" size="xs">Healthcare Services · 10 of 82</text>
    </row>
    <box background="surface-tertiary" radius="full" height="12px" clip>
      <box background="#438d9c" width="12.2%" height="100%"/>
    </box>
    <caption>Example of the verified selected-pairing result, not the full chart.</caption>
  {/if}
</box>

This is a conceptual illustration. In Tableau, the mode selector will be a dropdown and the existing worksheets will supply the charts.

## 5. Step 7 — Verify the matrix parameter actions

Before testing the new panel, confirm the two parameter actions exist.

Open **Dashboard → Actions**.

You should have these actions:

| Action | Source | Purpose |
|---|---|---|
| `Select decision pairing` | 02 — Decision Matrix | Filters application investigation |
| `Inspect application` | 04 — Application Detail | Filters merchant narratives |
| `Set Baseline Pairing` | 02 — Decision Matrix | Updates Baseline decision-code parameter |
| `Set Stress Pairing` | 02 — Decision Matrix | Updates stress decision-code parameter |

For the last two actions, verify:

**Set Baseline Pairing**

- Run on: Select
- Target parameter: `Selected Baseline Decision Code`
- Source field: `Baseline Decision Code`
- Clearing selection: Set value to `ALL`

**Set Stress Pairing**

- Run on: Select
- Target parameter: `Selected Stress Decision Code`
- Source field: `Stress Decision Code`
- Clearing selection: Set value to `ALL`

Keep the existing investigation filter actions. **Do not add worksheet 13 as a target of `Select decision pairing`.** Its calculations must retain the full segment population to produce meaningful incidence rates.

## 6. Step 8 — Important: correct the KPI scope issue

Before final acceptance, we still need to resolve the earlier behavior where selecting Merchant 000340 caused the four portfolio KPIs to display **1 / 1 / 1 / 0**, while the executive narrative remained at 750 applications.

This may be caused by an additional action or by worksheet filtering outside the two actions we've explicitly configured.

Open **Dashboard → Actions** and verify that neither investigation action targets the KPI worksheets `09` through `12`.

Also check that none of the KPI sheets has an unintended `Pair Key` or decision-pairing filter.

The correct behavior is:

- Portfolio filters change the KPIs.
- Matrix selections change the investigation population and selected-pairing analysis.
- Merchant selections change the individual narrative.
- Merchant selections do **not** change the portfolio KPIs.

This is a release-blocking consistency check.

## 7. Step 9 — Full interaction test

Once the visibility controls and actions are configured, test the following sequence.

| Test | Expected result |
|---|---|
| All portfolio filters cleared | KPIs: **750 / 236 / 103 / 27** |
| Portfolio Authorization mode | Original two-series authorization chart |
| Select matrix cell with 88 applications | Application list narrows to **88** |
| Switch to Selected Pairing mode | Healthcare Services shows **12.2%** |
| Change Review Segment By to Acquisition Source | Worksheet 13 groups by acquisition source |
| Select Merchant 000003 | Baseline and stress explanations update |
| Inspect portfolio KPIs | Still **750 / 236 / 103 / 27** |
| Clear the matrix selection | Pairing parameters reset to `ALL` |
| Switch back to Portfolio Authorization | Original chart returns |

One additional check: when no pairing is selected, worksheet 13 should display an instruction to select a matrix cell, not silently present its zero bars as a meaningful risk result. We can handle that as a small final presentation refinement.

---

## My recommendation for the next checkpoint

**Complete Steps 4–5 first: add the vertical container, place worksheets 08 and 13 inside it, and configure their visibility.**

Do not change the application investigation section, the narrative calculations, or the KPI formatting during this pass.

Then send two screenshots: one showing the expanded hierarchy with both segment worksheets, and another showing the **Control visibility using value** setting for worksheet 13.

That will let us verify the new panel is structurally correct before testing the full interactive workflow.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d3ed6790-2199-4b02-8ee2-1aa1f8ae379c"></a>
## Andrew / user · C123-M00481

C123-M00481 · 2026-10-16T13:41:08.916000-04:00 · active path

Preceding visible parent: [C123-M00480](part-39.md#m-71ba655c-3003-4355-b2f7-48b39a041076)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-174036).png

<!-- BEGIN_SOURCE_MESSAGE -->
any idea what could be happening to my tableau here? after taking a break, i came back and changed the title of 03 and then weird things started visually happening.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8236afab-1789-41ac-9236-dc46f64cbeb6"></a>
## Assistant · C123-M00482

C123-M00482 · 2026-10-16T13:41:17.457211-04:00 · active path

Preceding visible parent: [C123-M00481](part-39.md#m-d3ed6790-2199-4b02-8ee2-1aa1f8ae379c)

<!-- BEGIN_SOURCE_MESSAGE -->
**Yes. This looks much more like a Tableau rendering failure than a problem with your calculations, data, or dashboard design.** I would not start rebuilding anything.

There are several distinctive symptoms in your screenshot:

- The KPI numbers and labels are duplicated, inverted, or rendered upside down.
- The decision matrix contains horizontal bands of corrupted text and colored pixels.
- The executive narrative and segment chart have similar visual artifacts.
- Some elements, including the dashboard title, row headings, and filter controls, still render normally.

**That combination strongly suggests a graphics-rendering or display-cache issue.** Changing the Section 03 title may have triggered a redraw, but there's no evidence that the title change itself corrupted the workbook.

## What I recommend, in order

### 1. Save a backup without overwriting your last good version

You're currently working in `MCI_Risk_Decision_Scenario_Review_R2`.

If you have made changes you want to preserve since your last save, use **File → Save As** and create:

`MCI_Risk_Decision_Scenario_Review_R2_Render_Test`

This gives us a recovery point without sacrificing the last known-good workbook.

### 2. Test whether it's only the dashboard renderer

Click the separate worksheet tab **02 — Decision Matrix**.

Check whether the cells and labels look normal there.

Then open **08 — Segment Comparison** and one KPI worksheet, such as **09 — KPI Matched Applications**.

| What you observe | Likely implication |
|---|---|
| Worksheets normal, dashboard corrupted | Dashboard rendering, layout, or graphics-cache issue |
| Worksheets also corrupted | Broader Tableau graphics-rendering issue |
| Corruption disappears after changing tabs | Transient redraw/cache problem |
| Corruption persists after restart | Investigate graphics acceleration, display scaling, or application version |

This test is particularly useful because it does not change your workbook.

### 3. Force a clean redraw

Try these simple actions:

1. Switch from the dashboard to a worksheet and back.
2. Change the dashboard Fit setting from **Entire View** to **Standard**, then back.
3. Resize the Tableau window slightly.
4. If you're using an external monitor, try moving Tableau to your primary display.

If the issue disappears, that supports the rendering hypothesis.

### 4. Restart Tableau Public

If the corruption persists:

1. Save the recovery copy.
2. Close Tableau Public completely.
3. Reopen the application.
4. Open your saved R2 workbook.

**I would expect a restart to be a reasonable first remedy**, although I can't guarantee it will resolve the issue.

If the workbook opens normally, continue from the existing dashboard. Do not recreate any worksheets or calculations.

### 5. If the issue persists, investigate graphics acceleration

Because you're on Windows, graphics drivers, hardware acceleration, and display scaling are plausible contributors.

Check **Help → Settings and Performance**, if that menu is available in your Tableau Public version, for a hardware-acceleration setting. Don't assume the option exists in every version.

If available, try disabling hardware acceleration, restart Tableau, and compare the result.

I would not change your graphics drivers or Windows display configuration until the simpler tests establish that the problem persists.

## What I would not do

I would **not** delete Section 03, rebuild the decision matrix, recreate the KPI worksheets, or modify your SQL/CSV source.

The corrupted text patterns appear across multiple unrelated views. That points away from an isolated worksheet calculation.

Also, the screenshot still shows **750 matched applications** in Tableau's status bar. That doesn't prove every calculation is intact, but it is reassuring that the underlying data connection is still functioning.

## My recommended immediate test

**Open `02 — Decision Matrix` as a standalone worksheet and tell me whether it looks normal.**

That single observation will help us distinguish a dashboard-specific rendering problem from a broader Tableau graphics issue.

If the worksheet is normal, we'll concentrate on the dashboard renderer. If it's corrupted too, we'll prioritize restarting Tableau and checking the graphics environment before making any further layout changes.

Your analytical work is too far along to risk unnecessary reconstruction over what may simply be a display issue.
<!-- END_SOURCE_MESSAGE -->


<a id="m-aedc56fa-8913-4ec7-823b-2ddd6e966b2a"></a>
## Andrew / user · C123-M00483

C123-M00483 · 2026-10-16T13:44:18.173000-04:00 · active path

Preceding visible parent: [C123-M00482](part-39.md#m-8236afab-1789-41ac-9236-dc46f64cbeb6)

<!-- BEGIN_SOURCE_MESSAGE -->
definitely rendering. 02 - looks blank but when I hover over it says matched applications with #'s
<!-- END_SOURCE_MESSAGE -->


<a id="m-2e8bc5a6-24bb-467b-abca-43f4df58cb33"></a>
## Assistant · C123-M00484

C123-M00484 · 2026-10-16T13:44:39.256248-04:00 · active path

Preceding visible parent: [C123-M00483](part-39.md#m-aedc56fa-8913-4ec7-823b-2ddd6e966b2a)

<!-- BEGIN_SOURCE_MESSAGE -->
**That confirms the problem is almost certainly in Tableau's visual rendering layer, not the underlying data.** If hovering over apparently blank matrix cells still returns the correct application counts, Tableau is calculating the marks and maintaining their interactive positions—it simply isn't drawing them correctly.

The upside is that **we have no reason to rebuild your dashboard or redo the calculations.**

I would take the following recovery steps, in order.

### 1. Save a recovery copy and restart Tableau

1. Choose **File → Save As**.
2. Save as `MCI_Risk_Decision_Scenario_Review_R2_Render_Recovery`.
3. Close Tableau Public completely.
4. Open **Task Manager** (`Ctrl + Shift + Esc`) and confirm no Tableau processes remain running.
5. Reopen Tableau Public and load the recovery copy.

If everything renders normally, save the workbook and continue. This is the least disruptive solution.

### 2. If restarting doesn't work, test Windows display scaling

Since you're running Tableau on Windows:

1. Right-click the Windows desktop → **Display settings**.
2. Under **Scale**, note the current percentage.
3. Temporarily try **100%** if you're using 125% or 150%.
4. Close and reopen Tableau after the change.

If you use multiple monitors, also try Tableau on the primary monitor.

This is a diagnostic test, not a recommendation to permanently change your display settings.

### 3. If the problem persists, test Tableau's graphics settings

In Tableau Public, check **Help → Settings and Performance** for an option related to hardware acceleration or rendering.

If such a setting exists, change it and restart Tableau. The exact options vary by version.

If no setting is available, don't spend time hunting through unrelated preferences.

### 4. Isolate whether the R2 workbook itself is involved

Open your earlier saved **R1 workbook** in the same Tableau session.

- **R1 also renders incorrectly:** Strong evidence of an application, graphics-driver, or display-environment issue.
- **R1 renders normally but R2 does not:** The newer workbook may contain a rendering-triggering layout or worksheet state. That still does not establish data corruption.

This comparison is particularly valuable because R1 is your known-good checkpoint.

### What I would do right now

**Save the recovery copy, close Tableau completely, and reopen it.** That's the highest-value next action.

If the visual corruption disappears, we can resume integrating the selected-pairing chart exactly where we stopped.

If it persists, tell me whether R1 renders correctly. That will determine whether we troubleshoot Tableau's graphics environment or isolate an R2-specific rendering problem.

I would not touch the calculations, dashboard actions, or source data until the rendering issue is resolved.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1266e149-76d6-4ea9-b7c0-e02da7cf3131"></a>
## Andrew / user · C123-M00485

C123-M00485 · 2026-10-16T14:04:56.697000-04:00 · active path

Preceding visible parent: [C123-M00484](part-39.md#m-2e8bc5a6-24bb-467b-abca-43f4df58cb33)

<!-- BEGIN_SOURCE_MESSAGE -->
should 13 be a target sheet of any actions?
<!-- END_SOURCE_MESSAGE -->


<a id="m-f4d6914c-61d7-447d-a295-473b8f9c7b22"></a>
## Assistant · C123-M00486

C123-M00486 · 2026-10-16T14:05:06.133098-04:00 · active path

Preceding visible parent: [C123-M00485](part-39.md#m-1266e149-76d6-4ea9-b7c0-e02da7cf3131)

<!-- BEGIN_SOURCE_MESSAGE -->
**No. Worksheet `13 — Selected Segment Pairing Concentration` should NOT be a target sheet of any of your existing filter actions.**

This is intentional and important for preserving the correct denominator in your concentration calculations.

Here's the correct configuration:

| Dashboard action | Source | Target sheets / parameter |
|---|---|---|
| **Select decision pairing** (Filter) | 02 — Decision Matrix | 04, 05, 06, 07 |
| **Inspect application** (Filter) | 04 — Application Detail | 05, 06, 07 |
| **Set Baseline Pairing** (Change Parameter) | 02 — Decision Matrix | `Selected Baseline Decision Code` |
| **Set Stress Pairing** (Change Parameter) | 02 — Decision Matrix | `Selected Stress Decision Code` |

### Why worksheet 13 must remain excluded

Worksheet 13 already responds to the two decision-code parameters through its `Selected Pairing Flag` calculation.

For example, selecting:

**Counteroffer review required → Evidence decline**

should produce:

- **88 applications** in the selected pairing across the portfolio.
- **10 affected Healthcare Services applications.**
- **82 total Healthcare Services applications.**
- **12.2% within-segment incidence.**

If worksheet 13 were also targeted by the matrix's ordinary filter action, Tableau would restrict its underlying population to the selected pairing. The Healthcare Services denominator could fall from 82 to 10, producing a misleading **100% incidence**.

### What should filter worksheet 13?

Only your two portfolio filters:

- **Industry**
- **Acquisition Source**

These define the population under review and should continue applying to worksheet 13.

The `Review Segment By` parameter also controls whether it groups results by Industry or Acquisition Source, but that is a parameter-driven dimension change, not a filter action.

**Bottom line:** Worksheet 13 receives the selected decision pairing through **parameter actions**, not filter actions. Keep it excluded from the target-sheet lists.

The same principle applies to your four executive KPI worksheets: they should respond to portfolio filters, not matrix or merchant selections.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2a1f1eac-0676-48c1-842b-3b8efcdc2bf9"></a>
## Andrew / user · C123-M00487

C123-M00487 · 2026-10-16T14:10:30.378000-04:00 · active path

Preceding visible parent: [C123-M00486](part-39.md#m-f4d6914c-61d7-447d-a295-473b8f9c7b22)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-180929).png; image(20261016-180952).png; image(20261016-181005).png

<!-- BEGIN_SOURCE_MESSAGE -->
i want to sort the selected pairing better (descending %) - but aside from that, looks good
<!-- END_SOURCE_MESSAGE -->


<a id="m-8cf1a544-cf7c-4a69-a436-5ad913e02892"></a>
## Assistant · C123-M00488

C123-M00488 · 2026-10-16T14:10:40.357481-04:00 · active path

Preceding visible parent: [C123-M00487](part-39.md#m-2a1f1eac-0676-48c1-842b-3b8efcdc2bf9)

<!-- BEGIN_SOURCE_MESSAGE -->
**Agreed. The two-mode Segment Sensitivity feature is now working as intended.** Your screenshots show the 88-application pairing selected, the application table narrowed appropriately, the portfolio KPIs remaining at 750 / 236 / 103 / 27, and the segment chart switching correctly between authorization rates and pairing incidence.

The main remaining refinement is to sort worksheet **13 — Selected Segment Pairing Concentration** by its own incidence rate, rather than retaining the original authorization-rate ordering from worksheet 08.

## 1. Sort worksheet 13 by Selected Pairing Incidence

Open the standalone worksheet **13 — Selected Segment Pairing Concentration**.

On the **Rows** shelf, locate the blue `Review Segment` pill.

1. Click the dropdown arrow on `Review Segment`.
2. Select **Sort…**
3. Configure the dialog:

| Setting | Value |
|---|---|
| Sort Order | **Descending** |
| Sort By | **Field** |
| Field Name | `Selected Pairing Incidence` |
| Aggregation | **Custom**, if Tableau displays it for the aggregate calculation |

Click **OK**.

If Tableau does not offer `Selected Pairing Incidence` as a sortable field, do not substitute `Selected Pairing Applications`. Sorting by counts would answer a different question.

Instead, try selecting the `Review Segment` row header and using Tableau's descending-sort button. Verify that it sorts by the incidence measure on Columns. If neither method produces the correct result, we can build a dedicated sort calculation.

## 2. Verify the expected ordering

For your currently selected pairing:

**Counteroffer review required → Evidence decline**

The percentages visible in your screenshot imply this descending order:

| Rank | Industry | Pairing incidence |
|---|---|---:|
| 1 | General Retail | **19.2%** |
| 2 | Professional Services | **12.5%** |
| 3 | Healthcare Services | **12.2%** |
| 4 | Ecommerce Digital | **11.8%** |
| 5 | Restaurant Food Service | **10.8%** |
| 6 | Energy Services | **10.0%** |
| 7 | Construction Trades | **8.2%** |
| 8 | Transportation Logistics | **6.7%** |

These are the displayed values from your selected-pairing chart. After sorting, General Retail should move to the top and Transportation Logistics to the bottom.

The sorting should also recalculate when you select a different matrix pairing or switch `Review Segment By` to Acquisition Source.

## 3. Two final presentation refinements

**First, remove the inherited sort indicator from the chart header if possible.** Your screenshot shows `Review Segment` with a sort icon. That's normal in Tableau, but for a polished dashboard, you can hide the field label or header if doing so doesn't remove the industry names.

**Second, consider shortening the selected-pairing axis title.** Instead of `Selected Pairing Incidence`, I would use:

**% of segment applications**

That is immediately understandable to a nontechnical risk-management reader.

The chart's subtitle can explain the denominator:

> Share of applications within each segment belonging to the selected decision pairing.

This avoids confusing within-segment incidence with the percentage distribution of the 88 affected applications across industries.

## 4. My assessment of the current dashboard

I would preserve the layout. The selected-pairing mode adds an important capability without crowding the report.

The two modes now support distinct executive questions:

- **Portfolio Authorization:** How do authorization rates differ across segments and scenarios?
- **Selected Pairing:** Within each segment, how prevalent is the decision pairing under investigation?

The pairing mode is particularly useful because it distinguishes **absolute counts from normalized concentration**. A smaller segment may have a higher incidence rate even when it contributes fewer affected applications.

One remaining acceptance test is worth preserving: select an individual merchant after choosing a matrix pairing and verify that the four KPI cards and pairing-incidence chart remain unchanged. Your current screenshots establish the matrix-to-segment behavior, but not that final merchant-selection boundary.

**Otherwise, I would consider the dashboard's analytical structure complete.** Once the sort is correct, we should focus on the final interaction QA, narrative readability across all four modes, and preparing a clean Tableau Public presentation rather than adding more analytical features.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b1b4cedc-deb8-4b25-95c0-a1c13fc5f2d4"></a>
## Andrew / user · C123-M00489

C123-M00489 · 2026-10-16T14:19:00.817000-04:00 · active path

Preceding visible parent: [C123-M00488](part-39.md#m-8cf1a544-cf7c-4a69-a436-5ad913e02892)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-181604).png; image(20261016-181625).png

<!-- BEGIN_SOURCE_MESSAGE -->
I think this is good and I'm ready to save and work on publishing to github. I have saved the final version as MCI_Risk_Decision_Scenario_Review. now, let's work on any screenshots that would be helpful to add to the GitHub readme. We do not need anything too lengthy right now. I want to get this published and e-mail Bank of America interviewers by 3:30pm est.
<!-- END_SOURCE_MESSAGE -->


<a id="m-079ac109-6903-4293-b3e5-8bd65498ba54"></a>
## Assistant · C123-M00490

C123-M00490 · 2026-10-16T14:19:11.459359-04:00 · active path

Preceding visible parent: [C123-M00489](part-39.md#m-b1b4cedc-deb8-4b25-95c0-a1c13fc5f2d4)

<!-- BEGIN_SOURCE_MESSAGE -->
**I agree—this is ready to move into publication preparation.** The dashboard now demonstrates Tableau visualization, matched-scenario risk analysis, interactive investigation, segment sensitivity, and source-backed narrative interpretation. That's a compelling combination for a Bank of America Global Risk Management audience.

Given your 3:30 p.m. Eastern deadline, I would keep the GitHub update focused: **three screenshots, a concise README section, a Tableau Public link, and a short interviewer email.** No new dashboard features or redesign.

## The three screenshots I'd publish

<box gap={3}>
  <row align="start" gap={3}>
    <AsyncImage query={null} fallback={<box background="surface-secondary" radius="md" padding={2}><icon name="layout-dashboard" size="2xl" color="secondary"/></box>} width="112px"/>
    <box flex="1" gap={1}>
      **1. Executive risk overview**

      Show the complete dashboard with all portfolio filters cleared, four KPIs, decision matrix, and Portfolio Authorization mode. This establishes the overall analytical capability immediately.
    </box>
  </row>
  <divider color="subtle"/>
  <row align="start" gap={3}>
    <box width="112px" background="surface-secondary" radius="md" padding={2} align="center" justify="center">
      <icon name="chart-bar" size="2xl" color="secondary"/>
    </box>
    <box flex="1" gap={1}>
      **2. Selected decision-pairing concentration**

      Use your first screenshot, with the **88-application pairing** selected and the segment chart sorted by incidence. This demonstrates the investigative capability beyond a conventional dashboard.
    </box>
  </row>
  <divider color="subtle"/>
  <row align="start" gap={3}>
    <box width="112px" background="surface-secondary" radius="md" padding={2} align="center" justify="center">
      <icon name="file-search" size="2xl" color="secondary"/>
    </box>
    <box flex="1" gap={1}>
      **3. Merchant 000003 — Evidence-based explanation**

      Select Merchant 000003 and show the lower investigation area with Baseline and Recession Energy narratives. This is the signature feature: a decision is not just displayed; its supporting evidence is explained.
    </box>
  </row>
</box>

You already have screenshots for the first two. **Only the Merchant 000003 explanation screenshot still needs to be captured.** Select the 88-application pairing, click Merchant 000003, and choose the `Decision` narrative mode.

For that third screenshot, include Section 04 and Section 05 together, with both narrative panels visible. There's no need to capture every narrative mode.

I've packaged your two existing screenshots **without altering their pixels**:

<box gap={2}>
  <row align="center" gap={2}>
    <icon name="file-archive" color="secondary" size="lg"/>
    Download GitHub screenshot package (historical reference: `sandbox:[session]/tableau_github_screenshots.zip`; referenced bytes not established here)
  </row>
  <text size="xs" color="secondary">Contains portfolio_authorization_overview.png and selected_pairing_concentration.png.</text>
</box>

## Suggested GitHub README section

<WritingBlock id="58321" variant="document">### Tableau | Merchant Credit Intelligence — Risk Decision & Scenario Review

An interactive Tableau risk-analysis dashboard comparing **750 matched synthetic merchant-financing applications** across Baseline and Recession Energy scenarios.

The dashboard demonstrates:

- **Portfolio risk oversight:** Decision distributions, authorization rates, and dynamically generated executive interpretation.
- **Scenario sensitivity:** A matched-application decision matrix identifying where final decision categories differ.
- **Segment concentration:** Industry and acquisition-source comparisons, including within-segment incidence of selected decision pairings.
- **Application-level investigation:** Interactive drill-down from portfolio results to individual merchant evidence.
- **Explainable decisions:** Source-backed narratives covering decision rationale, operating evidence, structure assessment, and technical source explanations.

**Analytical distinction:** The scenarios are alternatives, not sequential account histories. Review does not imply authorization, and authorization does not establish funding.

Built with Tableau using deterministic synthetic data and governed decision outputs from the Merchant Credit Intelligence project.

Explore the interactive Tableau dashboard (historical reference: `INSERT_TABLEAU_PUBLIC_URL`; referenced bytes not established here)

Portfolio authorization overview (historical reference: `tableau_github_assets/portfolio_authorization_overview.png`; referenced bytes not established here)

Selected decision-pairing concentration (historical reference: `tableau_github_assets/selected_pairing_concentration.png`; referenced bytes not established here)</WritingBlock>

## Fastest publication sequence

1. **Publish the Tableau workbook:** In Tableau Public, use **Server → Tableau Public → Save to Tableau Public As**. Confirm the published view works in a browser. Tableau Public is publicly accessible, so verify the workbook contains only intended synthetic/public data.
2. **Add the screenshots:** Upload the two PNGs from the ZIP to `tableau_github_assets/` in your GitHub repository.
3. **Update the README:** Add the section above, replacing the Tableau URL placeholder with the actual published link.
4. **Capture Merchant 003:** Optional for today's deadline. It can be added after the interview follow-up rather than delaying publication.
5. **Verify:** Open the GitHub README in a private browser window, confirm both images display, and click through to Tableau.

One important point: I would **not delay your Bank of America follow-up for the third screenshot**. The two existing images already demonstrate the portfolio and interactive risk-investigation capabilities.

For the interviewer email, I'd keep the message brief and make the work relevant to the Risk Analysis Manager discussion—not present it as merely a Tableau exercise. The strongest framing is that you've built an interactive, explainable risk-analysis workflow connecting portfolio indicators, scenario sensitivity, and application-level evidence.

**The immediate next step is publishing the Tableau Public workbook and getting its URL.** Once you have that link, we can finalize the GitHub wording and interviewer message quickly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-acee2f1a-32f1-4fe2-8e77-2537e978dfc0"></a>
## Andrew / user · C123-M00491

C123-M00491 · 2026-10-16T14:21:52.413000-04:00 · active path

Preceding visible parent: [C123-M00490](part-39.md#m-079ac109-6903-4293-b3e5-8bd65498ba54)

<!-- BEGIN_SOURCE_MESSAGE -->
for the screenshots, is there a way to zoom out to show the full dashboard in these screenshots? even in presentation mode it is not capturing the full page.
<!-- END_SOURCE_MESSAGE -->


<a id="m-eb08a82f-e730-48a3-9375-4e5035805c81"></a>
## Assistant · C123-M00492

C123-M00492 · 2026-10-16T14:22:03.015816-04:00 · active path

Preceding visible parent: [C123-M00491](part-39.md#m-acee2f1a-32f1-4fe2-8e77-2537e978dfc0)

<!-- BEGIN_SOURCE_MESSAGE -->
**Yes. Tableau has a better option than trying to zoom out in Presentation Mode: export the dashboard directly as an image.** This is what I recommend for your GitHub screenshots because it can capture the full dashboard rather than just the portion visible on your monitor.

## Option 1 — Export the entire dashboard as an image (recommended)

1. Open your **Risk Decision & Scenario Review** dashboard in Tableau Public Desktop.
2. Set the desired filters, matrix selection, and Segment Analysis Mode.
3. From the top menu, select **Dashboard → Export Image**.
4. Save the image as a PNG.
5. Open the exported image and verify that Sections 01–05, including the Baseline and Recession Energy explanations, are visible.

Tableau exports the dashboard at its configured dimensions rather than relying on your screen capture.

**Important:** Your dashboard uses a fixed size and has some scrollable worksheets. The export captures the dashboard canvas, but it will not automatically expand internally scrollable application tables or text panels. Make sure the narrative paragraphs are fully visible in their allocated areas before exporting.

## Option 2 — Increase the dashboard's export resolution

If the exported PNG looks too small or text is difficult to read:

1. In Tableau, open the dashboard.
2. In the left **Dashboard** pane, locate **Size**.
3. Choose **Fixed Size**.
4. Set a larger canvas, such as:
   - Width: **1600 px**
   - Height: **1400 px**
5. Inspect the dashboard to ensure the additional space is distributed appropriately.
6. Export again using **Dashboard → Export Image**.

I would first try exporting at your current dimensions. Increasing the canvas size can introduce unwanted whitespace or affect tiled-container proportions.

## Option 3 — Zoom out temporarily for a screen capture

If you specifically want a screenshot of the Tableau application rather than a clean dashboard export, try:

- **Windows Settings → Display → Scale** and temporarily use 100% scaling.
- Maximize Tableau and use Presentation Mode.
- If viewing the published dashboard in a browser, use **Ctrl + minus (-)** to zoom out until the entire dashboard fits.

The browser method is usually more convenient than changing Windows display scaling, but it may make text too small.

## What I recommend for your GitHub README

Use **Dashboard → Export Image**, and capture these two states:

| Image | Configuration |
|---|---|
| `portfolio_authorization_overview.png` | All portfolio filters cleared; Portfolio Authorization mode; no matrix or merchant selection |
| `selected_pairing_concentration.png` | Select the 88-application pairing; Selected Pairing mode; Merchant 000003 selected if the narrative remains readable |

If the full-dashboard image makes the text too small for GitHub, that's acceptable for an overview, but I would additionally use a focused crop of the Merchant 003 narrative as a supporting image.

**My recommendation: try Dashboard → Export Image first.** It is the cleanest way to capture your full Tableau work without altering the underlying visuals or rebuilding the layout.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cf3674d5-e7f8-45ad-97a8-7fe5cd63ce69"></a>
## Andrew / user · C123-M00493

C123-M00493 · 2026-10-16T14:25:16.941000-04:00 · active path

Preceding visible parent: [C123-M00492](part-39.md#m-eb08a82f-e730-48a3-9375-4e5035805c81)

<!-- BEGIN_SOURCE_MESSAGE -->
let's do option 1 and I want the most interesting cases for a linkedin carousel focused on the tableau. I will share this with BofA as well. Please give me the 12 most powerful dashboard displays and examples that not only show off Tableau but the Merchant system that was built. please explore the data and to advise all selections for those 12 images and then the order. i will then create those 12 visuals and you can help me then turn them into a carousel.
<!-- END_SOURCE_MESSAGE -->
