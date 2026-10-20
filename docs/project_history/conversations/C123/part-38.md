# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 38 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-37.md)
[Next part](part-39.md)

<a id="m-9f7c4f59-4db0-48c9-90c5-b6873d1181bc"></a>
## Assistant · C123-M00452

C123-M00452 · 2026-10-16T08:19:35.902988-04:00 · active path

Preceding visible parent: [C123-M00451](part-37.md#m-b26e9bcb-9924-4aac-a8bd-0bb8e5137eb6)

<!-- BEGIN_SOURCE_MESSAGE -->
Now that the header and four KPI cards are established, I would organize the remainder around a **three-stage risk-management workflow: Identify → Investigate → Explain**.

This is where we can make the Tableau dashboard particularly relevant to a Bank of America Global Risk Management audience. The objective is not simply attractive visualization. It's enabling a risk manager to identify a portfolio-level issue, isolate its concentration, investigate the affected applications, and understand the underlying decision evidence.

**My recommendation is one polished, vertically scrolling dashboard with two analytical charts side by side, followed by a full-width investigation workspace.** We already have nearly all the worksheets needed.

## 1. Proposed complete dashboard layout

<box border radius="lg" padding={3} gap={3}>
  <box gap={1}>
    <title size="xl">Merchant Credit Intelligence</title>
    <text color="secondary" size="sm">Risk Decision & Scenario Review</text>
  </box>
  <grid columns={5} gap={1}>
    {#each ["Industry","Acquisition Source","Review Segment By","Narrative Detail","Application Count"] as t}
      <grid-item>
        <box background="surface-secondary" padding={2} radius="sm" align="center">
          <text size="3xs" weight="medium" textAlign="center">{t}</text>
          <icon name="chevron-down" color="tertiary" size="xs"/>
        </box>
      </grid-item>
    {/each}
  </grid>
  <grid columns={4} gap={2}>
    {#each [{v:"750",t:"Matched Applications",s:""},{v:"236",t:"Different Decisions",s:"31.5%"},{v:"103",t:"Baseline Authorized",s:"13.7%"},{v:"27",t:"Stress Authorized",s:"3.6%"}] as k}
      <grid-item>
        <box border radius="sm" padding={2} align="center" gap={1}>
          <title size="xl" tabularNums>{k.v}</title>
          <text size="3xs" weight="medium" textAlign="center">{k.t}</text>
          {#if k.s}<caption>{k.s}</caption>{/if}
        </box>
      </grid-item>
    {/each}
  </grid>
  <box background="surface-secondary" radius="sm" padding={3} gap={1}>
    <row align="center" justify="between">
      <text weight="medium" size="xs">01 / PORTFOLIO INTERPRETATION</text>
      <icon name="file-text" color="secondary"/>
    </row>
    <text size="sm">750 matched applications; 236 (31.5%) have different decision categories. Authorizations: 103 in Baseline versus 27 in Recession Energy.</text>
    <caption>Dynamic narrative, not static text</caption>
  </box>
  <grid columns={5} gap={2}>
    <grid-item span={3}>
      <box border radius="md" padding={2} gap={2} height="100%">
        <text weight="medium" size="sm">02 / Decision pairing matrix</text>
        <caption>Baseline rows × Recession Energy columns</caption>
        <grid columns={7} gap="2px">
          {#each Array.from({length:49},(_,i)=>i) as i}
            <grid-item>
              <box background={i%8===0?"#377a9c":i%5===0?"#87c2c7":"surface-tertiary"} height="22px" radius="2xs" align="center" justify="center">
                {#if i===18}<text size="3xs">88</text>{/if}
              </box>
            </grid-item>
          {/each}
        </grid>
        <caption>Select a cell to investigate the affected applications.</caption>
      </box>
    </grid-item>
    <grid-item span={2}>
      <box border radius="md" padding={2} gap={2} height="100%">
        <text weight="medium" size="sm">03 / Segment sensitivity</text>
        <caption>Authorization rates by selected grouping</caption>
        {#each [{n:"Healthcare",a:18.3,b:4.9},{n:"Professional",a:26.8,b:7.1},{n:"Digital Direct",a:11.3,b:1.3}] as d}
          <box gap={1}>
            <text size="2xs">{d.n}</text>
            <box background="surface-tertiary" height="7px" radius="full" clip>
              <box background="#4477a7" width={`${d.a/35*100}%`} height="100%" radius="full"/>
            </box>
            <box background="surface-tertiary" height="7px" radius="full" clip>
              <box background="#71b5b0" width={`${d.b/35*100}%`} height="100%" radius="full"/>
            </box>
          </box>
        {/each}
        <caption>Illustrative values; actual chart follows active filters.</caption>
      </box>
    </grid-item>
  </grid>
  <box border radius="md" padding={3} gap={2}>
    <text weight="medium" size="sm">04 / Application investigation</text>
    <table>
      <table-row><table-cell width="20%"><text size="2xs" weight="medium">Merchant</text></table-cell><table-cell><text size="2xs" weight="medium">Baseline</text></table-cell><table-cell><text size="2xs" weight="medium">Stress</text></table-cell><table-cell align="end"><text size="2xs" weight="medium">Requested</text></table-cell></table-row>
      <table-row><table-cell><text size="xs">000003</text></table-cell><table-cell><text size="xs">Counteroffer review</text></table-cell><table-cell><text size="xs">Evidence decline</text></table-cell><table-cell align="end"><text size="xs">$61,300</text></table-cell></table-row>
    </table>
    <caption>Selected matrix cell narrows the application list.</caption>
  </box>
  <box border radius="md" padding={3} gap={2}>
    <text weight="medium" size="sm">05 / Merchant evidence & decision interpretation</text>
    <text size="xs" weight="medium">Merchant 000003 · Healthcare Services · Digital Direct</text>
    <grid columns={2} gap={2}>
      <grid-item>
        <box background="surface-secondary" radius="sm" padding={2} gap={1} height="100%">
          <text weight="medium" size="xs">Baseline</text>
          <text size="xs">A $42,500 alternative is retained for specialist review. It is not an authorized offer.</text>
        </box>
      </grid-item>
      <grid-item>
        <box background="surface-secondary" radius="sm" padding={2} gap={1} height="100%">
          <text weight="medium" size="xs">Recession Energy</text>
          <text size="xs">Required sales evidence is incomplete: 28 usable days versus 30 required. Dependent assessment cannot proceed.</text>
        </box>
      </grid-item>
    </grid>
  </box>
  <caption>Conceptual layout using previously verified example values. The actual Tableau dashboard will use the existing worksheets and calculated narratives.</caption>
</box>

The key is **not adding more information for the sake of filling space**. Every region should answer a different risk-management question.

## 2. Exact order and dimensions

For the existing fixed **1400 × 1200** dashboard, I would start with these allocations:

| Region | Approximate height | Source |
|---|---:|---|
| Title, five controls, KPI cards | 215 px | Already built |
| Portfolio interpretation | 85 px | `03 — Executive Narrative` |
| Matrix and segment comparison | 385 px | `02` and `08` |
| Application investigation | 175 px | `04 — Application Detail` |
| Selected merchant context | 65 px | `05 — Selection Narrative` |
| Paired explanations | 235 px | `06` and `07` |
| Footer and spacing | Remaining | Text object |

These are layout targets rather than rigid constraints. If the scenario explanations require more space, **increase the dashboard height rather than shrink the narrative font**.

One adjustment to our earlier plan: the 1400-pixel width may be tight for a seven-category matrix beside a segment chart. If Tableau begins wrapping decision labels excessively, I would allow a **1500–1600-pixel dashboard width**, rather than accepting illegible category names.

## 3. Build the next section: portfolio interpretation

Immediately below your four KPI cards, retain the existing **03 — Executive Narrative** worksheet.

Set its displayed title to:

**Portfolio interpretation**

Keep the existing calculated narrative on Text. The text should dynamically follow Industry and Acquisition Source filters, as you've already demonstrated.

Give it approximately 80–90 pixels. This section bridges the executive metrics and the detailed analysis: the cards quantify the portfolio, while the paragraph explains what the comparison means.

Do not replace this worksheet with a static dashboard text object.

## 4. Build the side-by-side analytical row

This is the next substantial layout task.

Use **one Horizontal container** below the portfolio interpretation.

Inside it, place:

- **Left:** `02 — Decision Matrix`
- **Right:** `08 — Segment Comparison`

Start with **65% width for the matrix and 35% for the segment chart**.

In Tableau:

1. Open the dashboard in editing mode and select **Tiled** in the Objects pane.
2. Drag a **Horizontal** container immediately beneath the Executive Narrative.
3. Move the existing Decision Matrix into the left side of that container using its top-center grab handle.
4. Drag **08 — Segment Comparison** from the Sheets list into the right side of the same container.
5. Select the horizontal container in **Layout → Item hierarchy** to confirm it has exactly those two worksheets as children.
6. Resize the divider until the matrix has enough width for its category headers.

**Important:** Your current matrix may sit inside a deeply nested vertical/tiled container. Move the worksheet, not its entire parent container. If Tableau highlights a large area containing the application table and stories, cancel the drag and try again.

Do not delete the existing matrix or its dashboard filter action.

### What each chart must communicate

The matrix identifies which decisions correspond across the same applications. It should retain the 750-application total when all filters are cleared.

The segment chart shows the **Baseline and stress authorization rates** by Industry or Acquisition Source. It should follow the same portfolio filters, but should **not** be filtered by selecting a matrix cell.

This distinction is important for executive interpretation: the segment chart is portfolio context, not a description of the currently selected application.

## 5. Preserve the full-width investigation section

Below the analytical row, keep the application list and narratives exactly in their current logical order:

**Application Detail → Selection Narrative → Baseline / Recession Energy stories.**

The application table should retain its scrollable list and the Requested Amount column. If that column still lacks a header, correct it before final publication.

The selection band should identify the merchant, industry, acquisition source, and paired outcomes once. Your revised story calculations have already removed the duplicated headers.

The two narrative panels should retain the **Decision / Evidence / Structure / Source rationale** parameter behavior. They should be large enough to read the default Decision paragraphs without nested scrolling.

## 6. A critical presentation rule

We should not allow the dashboard to imply that a stress scenario is an account's later performance.

The matrix is a **paired alternative-scenario comparison**. Likewise, an application moving from counteroffer review to evidence decline is not necessarily a deterioration in creditworthiness; the latter can mean the source evidence was insufficient to complete assessment.

Keep this distinction visible near the matrix or in the footer:

> Baseline and Recession Energy are alternative synthetic scenarios, not sequential account outcomes. Review is not authorization; authorization does not establish funding.

That one sentence protects the interpretation without burdening every chart.

## 7. What comes after layout

Once the two charts and investigation area are assembled, we should run a focused quality pass: verify the five top controls, reconcile the KPI values under filters, confirm the matrix-to-application action, test the Narrative Detail selector across all four modes, and check the dashboard at realistic desktop viewing size.

Then we can add final refinements such as consistent fonts, restrained color hierarchy, useful tooltips, and an introductory source/method note. We should **not** add another analytical page until this dashboard is working end to end.

**Next action:** place `03 — Executive Narrative` directly below your KPI cards, then position `02 — Decision Matrix` and `08 — Segment Comparison` in a single horizontal container. Send a screenshot at that stage, before rearranging the lower investigation section. That is the point where we can determine whether the 65/35 split is genuinely readable or whether the matrix needs a wider layout.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0e13a74d-9781-4f39-a79c-d2f0179acf26"></a>
## Andrew / user · C123-M00453

C123-M00453 · 2026-10-16T08:26:46.748000-04:00 · active path

Preceding visible parent: [C123-M00452](part-38.md#m-9f7c4f59-4db0-48c9-90c5-b6873d1181bc)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-122636).png

<!-- BEGIN_SOURCE_MESSAGE -->
how to add this footnote?
<!-- END_SOURCE_MESSAGE -->


<a id="m-ebd07148-3f01-4fcf-b8be-5c561f375333"></a>
## Assistant · C123-M00454

C123-M00454 · 2026-10-16T08:26:59.356547-04:00 · active path

Preceding visible parent: [C123-M00453](part-38.md#m-0e13a74d-9781-4f39-a79c-d2f0179acf26)

<!-- BEGIN_SOURCE_MESSAGE -->
You can add **“Dynamic narrative, not static text”** as a small footnote directly beneath your Executive Narrative using Tableau's **Text** dashboard object.

### Step-by-step

1. Open your **Risk Decision & Scenario Review** dashboard in editing mode.
2. In the left sidebar, select **Dashboard** (not Layout).
3. Under **Objects**, find **Text**.
4. Make sure **Tiled** is selected.
5. Drag **Text** immediately beneath your **03 — Executive Narrative** worksheet. Wait until Tableau shows a thin horizontal placement indicator below the narrative, then release.
6. In the **Edit Text** window, enter:

   `Dynamic narrative · Automatically recalculates with the selected portfolio filters.`

7. Select the text and format it:
   - **Font:** Tableau Book
   - **Size:** 9 pt
   - **Color:** Medium gray
   - **Alignment:** Left
8. Click **OK**.

### Adjust the spacing

Select the new Text object, then open **Layout** in the left sidebar.

Set its height to approximately **20–25 pixels**, with minimal padding. It should sit just below the narrative without creating a large blank area.

### My recommendation

I'd use slightly more informative wording than the original footnote:

> *Portfolio interpretation updates with the selected industry and acquisition source.*

This tells executives **what the narrative does**, rather than simply saying it's dynamic.

One distinction: this footnote is a **static Tableau Text object**, while the actual Executive Narrative above it remains a calculated worksheet. That's exactly what we want—the explanation changes with filters, while the small instructional footnote stays consistent.

**Place it beneath the Executive Narrative, before the decision matrix and segment comparison.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-646923dd-1af9-4c90-be48-9bb6c09196ba"></a>
## Andrew / user · C123-M00455

C123-M00455 · 2026-10-16T08:35:55.661000-04:00 · active path

Preceding visible parent: [C123-M00454](part-38.md#m-ebd07148-3f01-4fcf-b8be-5c561f375333)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-123555).png

<!-- BEGIN_SOURCE_MESSAGE -->
Thanks for explaining that. I think this approach is tighter and make use of the white space better. thoughts?
<!-- END_SOURCE_MESSAGE -->


<a id="m-f5ffa5b2-a5bc-4221-8015-fdb7688ad349"></a>
## Assistant · C123-M00456

C123-M00456 · 2026-10-16T08:36:05.241582-04:00 · active path

Preceding visible parent: [C123-M00455](part-38.md#m-646923dd-1af9-4c90-be48-9bb6c09196ba)

<!-- BEGIN_SOURCE_MESSAGE -->
**I prefer your approach.** It's tighter, makes better use of the horizontal space, and feels more like a professional executive dashboard.

You've effectively created a compact editorial header followed immediately by the data-driven interpretation. That's better than giving the footnote its own row.

Three things work particularly well:

- **Clear hierarchy:** “01 / PORTFOLIO INTERPRETATION” establishes the section, while the smaller text explains that the narrative recalculates with portfolio filters.
- **Efficient use of space:** You've eliminated an unnecessary footnote row without sacrificing information.
- **Readable interpretation:** The actual narrative sits directly beneath its heading, and the entire section occupies relatively little vertical space.

### One small refinement

I'd make the separator slightly cleaner. Your current header reads:

**01 / PORTFOLIO INTERPRETATION / Dynamic narrative · Automatically recalculates with the selected portfolio filters.**

I would replace the second slash with an em dash or vertical separator and make the explanatory phrase smaller and gray:

**01 / PORTFOLIO INTERPRETATION** <text color="secondary" inline>— Dynamic narrative · Updates with portfolio filters</text>

This reduces the amount of instructional text competing with the section title. You don't need to explain the recalculation mechanism twice.

I'd also consider changing **“In this filtered portfolio”** to **“Across the selected portfolio”** in the calculated narrative. That reads naturally both when all 750 applications are selected and when a narrower population is filtered. It's a cosmetic change only; the numbers and calculations remain unchanged.

**Verdict: Keep this compact treatment.** I would apply the same section-heading style to the next areas:

**02 / DECISION COMPARISON** — Identify which decisions differ across scenarios.

**03 / SEGMENT SENSITIVITY** — Compare authorization rates across industries or acquisition sources.

**04 / APPLICATION INVESTIGATION** — Select an application to inspect its evidence.

**05 / DECISION EXPLANATION** — Understand the rationale under each scenario.

That will create a consistent executive-facing reading experience without consuming extra rows of white space.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2ba34be1-c1f8-4ca3-8741-717be03f221c"></a>
## Andrew / user · C123-M00457

C123-M00457 · 2026-10-16T09:08:23.077000-04:00 · active path

Preceding visible parent: [C123-M00456](part-38.md#m-f5ffa5b2-a5bc-4221-8015-fdb7688ad349)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-130820).png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3ef3ff4b-6799-4f1c-b692-eca8229b8631"></a>
## Assistant · C123-M00458

C123-M00458 · 2026-10-16T09:08:31.842987-04:00 · active path

Preceding visible parent: [C123-M00457](part-38.md#m-2ba34be1-c1f8-4ca3-8741-717be03f221c)

<!-- BEGIN_SOURCE_MESSAGE -->
**This is looking much closer to a finished executive risk dashboard.** The top controls, KPI cards, dynamic interpretation, and two-chart analytical section now form a coherent visual story. I particularly like the restrained styling and how you've incorporated the numbered section headings without wasting vertical space.

I'd give the visible upper portion an **A- for design and analytical presentation**, with a few refinements before we move to the application investigation section.

## What's working

- **Executive hierarchy:** The four KPIs immediately establish the portfolio population and the scale of scenario differences.
- **Narrative integration:** The dynamic interpretation explains the numbers and preserves the distinction between alternative scenarios and sequential account history.
- **Decision matrix:** The counts are legible, and the matrix makes the correspondence between Baseline and Recession Energy decisions visible.
- **Segment sensitivity:** The paired bars are easy to compare, and the consistent 0–100% axis avoids exaggerating differences between smaller segments.
- **Section headings:** The compact `01 / 02 / 03` structure is an improvement over large standalone titles.

The matrix and segment comparison now answer two complementary questions: **Which decisions differ?** and **Where are authorization-rate differences concentrated?**

## Four refinements I'd make

**1. Rename the segment legend.**

The upper-right legend currently says *Measure Names*, with truncated entries such as “Baseline Authorizati...”.

Change the displayed legend title to **Scenario**, and edit the legend aliases to **Baseline** and **Recession Energy** if Tableau permits those aliases without affecting the underlying calculations.

This would eliminate the truncated text and make the legend more intuitive.

**2. Give the matrix and segment headings slightly more breathing room.**

The two section headings are close together horizontally. I would introduce approximately 12–16 pixels of separation between the panels, rather than shrinking their contents.

The decision matrix needs its current width. Don't sacrifice its readability simply to make the spacing perfectly symmetrical.

**3. Consider a more useful segment ordering.**

The current alphabetical ordering is acceptable, but a risk-management reader may benefit from sorting industries by **Baseline authorization rate**, descending.

That would make Professional Services, Transportation Logistics, Healthcare Services, and other segments easier to compare by their initial authorization rates.

However, alphabetical order is defensible for consistency when switching between Industry and Acquisition Source. I would treat this as optional rather than a defect.

**4. Make the matrix interaction explicit.**

Your section heading already says “Select cells to investigate affected applications,” which is good.

I would slightly tighten it to:

**02 / DECISION MATRIX** <text color="secondary" inline>— Select a decision pairing to investigate applications.</text>

This avoids the impression that the matrix is showing chronological migration from one decision to another.

## One substantive interpretation point

The segment chart is showing **authorization rates**, not the proportion of applications whose decision category changed.

That is fine, but it means the two charts are answering different questions. A segment could have a substantial change in decision classifications without a corresponding change in authorization rates.

For a future refinement, we might introduce a parameter that switches the segment chart between **Authorization Rate** and **Different Decision Rate**. That would let risk managers examine where decision-category sensitivity is concentrated without adding another chart.

I would not implement that until the existing dashboard is complete and tested.

## What comes next

**Proceed with the full-width investigation section below these charts.** Your existing worksheets already support it:

`04 — Application Detail` → `05 — Selection Narrative` → `06 — Baseline Story` and `07 — Stress Story`.

Keep the application table approximately 160–200 pixels tall and allow its rows to scroll. Give the two story panels equal widths and enough height to display their Decision explanations without internal scrolling.

One final layout consideration: if the dashboard's fixed height of 1200 pixels becomes too restrictive, increase it rather than compressing the explanation text. This is a vertically scrolling analytical workspace, not a single-slide presentation.

**My recommendation:** make the legend-title correction, then place the investigation section beneath the two charts. Once that's done, we'll test the complete workflow from the executive KPIs to Merchant 003's evidence-backed explanation and perform the final styling pass.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5cfbdd18-5cfa-414e-9fcc-2188c4733bd4"></a>
## Andrew / user · C123-M00459

C123-M00459 · 2026-10-16T09:16:43.305000-04:00 · active path

Preceding visible parent: [C123-M00458](part-38.md#m-3ef3ff4b-6799-4f1c-b692-eca8229b8631)

<!-- BEGIN_SOURCE_MESSAGE -->
how to sort by baseline authorization rate?
<!-- END_SOURCE_MESSAGE -->


<a id="m-32200768-b59f-467b-898e-ba612576f3c4"></a>
## Assistant · C123-M00460

C123-M00460 · 2026-10-16T09:16:51.941670-04:00 · active path

Preceding visible parent: [C123-M00459](part-38.md#m-5cfbdd18-5cfa-414e-9fcc-2188c4733bd4)

<!-- BEGIN_SOURCE_MESSAGE -->
To sort your **08 — Segment Comparison** chart by **Baseline Authorization Rate, highest to lowest**, we can use Tableau's field-based sorting. This will work with your existing `Review Segment` calculation and preserve the Industry / Acquisition Source parameter switch.

### Step 1 — Open the Segment Comparison worksheet

1. Click the **08 — Segment Comparison** worksheet tab.
2. Locate the **Review Segment** pill on the **Rows** shelf.
3. Right-click the pill (or click its dropdown arrow).
4. Select **Sort…**

### Step 2 — Configure the sort

In the Sort dialog, choose:

| Setting | Selection |
|---|---|
| Sort Order | **Descending** |
| Sort By | **Field** |
| Field Name | `Baseline Authorization Rate` |
| Aggregation | **Custom** or **Minimum**, if Tableau requires one |

Because `Baseline Authorization Rate` is already an aggregate calculation, Tableau may display **Custom** rather than offering the usual SUM/AVG choices. That's expected.

Click **OK**.

### Step 3 — Verify the result

With all portfolio filters cleared and **Review Segment By = Industry**, your industries should reorder by their Baseline authorization rates.

Based on the values visible in your screenshot, the top groups should begin:

| Rank | Industry | Baseline authorization rate |
|---|---|---:|
| 1 | Professional Services | 26.8% |
| 2 | Transportation Logistics | 18.9% |
| 3 | Healthcare Services | 18.3% |
| 4 | Ecommerce Digital | 16.2% |

The remaining industries should follow in descending order.

When you switch **Review Segment By** to **Acquisition Source**, the source categories should also sort by their respective Baseline authorization rates.

### If Tableau doesn't allow that aggregate field

Tableau sometimes restricts sorting by an aggregate calculated field in a view that uses Measure Names / Measure Values.

If `Baseline Authorization Rate` is unavailable or the sort produces unexpected results, don't substitute `Baseline Authorizations`—that would sort by counts rather than rates.

Instead, tell me what options appear in your Sort dialog. We can create a dedicated segment-level sort calculation that preserves the correct rate denominator.

**One important point:** keep the sort on `Review Segment`, not on `Measure Names`. Otherwise, you may reverse the Baseline and Stress bars within each industry rather than reorder the industries themselves.
<!-- END_SOURCE_MESSAGE -->


<a id="m-113facfe-8547-4bd9-afb7-ff5176182de7"></a>
## Andrew / user · C123-M00461

C123-M00461 · 2026-10-16T09:26:05.351000-04:00 · active path

Preceding visible parent: [C123-M00460](part-38.md#m-32200768-b59f-467b-898e-ba612576f3c4)

<!-- BEGIN_SOURCE_MESSAGE -->
how to add Requested Amount column label to 04 - Application Detail
<!-- END_SOURCE_MESSAGE -->


<a id="m-0b93aa04-ef5f-4344-a111-6b6fc31fca0f"></a>
## Assistant · C123-M00462

C123-M00462 · 2026-10-16T09:26:15.397528-04:00 · active path

Preceding visible parent: [C123-M00461](part-38.md#m-113facfe-8547-4bd9-afb7-ff5176182de7)

<!-- BEGIN_SOURCE_MESSAGE -->
To add **Requested Amount** as the column header in `04 — Application Detail`, we need Tableau to treat the amount as a named measure column rather than just text displayed at the end of each row.

You can do this without changing your underlying data or dashboard filter actions.

### Step 1 — Open the Application Detail worksheet

1. Click the **04 — Application Detail** worksheet tab.
2. On the **Marks** card, locate the green `MIN(Requested Amount)` pill currently on **Text**.
3. Drag that pill off the Marks card to remove it temporarily.

Leave your existing Rows fields and `Pair Key` on Detail unchanged.

### Step 2 — Add Measure Names and Measure Values

1. In the Data pane, locate **Measure Names** and **Measure Values**. You can use the search box.
2. Drag **Measure Names** onto the **Columns** shelf, after your existing row dimensions.
3. Drag **Measure Values** onto **Text** on the Marks card.
4. On the **Measure Values** card that appears, remove every measure except **Requested Amount**.
5. Click the dropdown on the `Requested Amount` pill within Measure Values and select **Measure → Minimum**.

Your worksheet should now be configured as follows:

| Tableau location | Field |
|---|---|
| **Rows** | Merchant, Industry, Acquisition Source, Baseline Decision, Stress Decision |
| **Columns** | Measure Names |
| **Marks → Text** | Measure Values |
| **Marks → Detail** | Pair Key |
| **Measure Values** | MIN(Requested Amount) only |

### Step 3 — Show the column header

Right-click the **Measure Names** pill on Columns and confirm **Show Header** is checked.

You should now see:

| Merchant | Industry | Acquisition Source | Baseline Decision | Stress Decision | Requested Amount |
|---|---|---|---|---|---:|
| 000003 | Healthcare Services | Digital Direct | Counteroffer review required | Evidence decline | $61,300 |

If the heading says something like `Min. Requested Amount`, right-click the displayed header and choose **Edit Alias** if available, or rename the displayed measure to **Requested Amount**.

### Step 4 — Format and verify

Right-click the requested-amount values and choose **Format → Numbers → Currency (Custom)**:

- Decimal places: **0**
- Thousands separator: **On**
- Currency symbol: **$**

Then confirm that Merchant **000003** still displays **$61,300**.

### Step 5 — Check the dashboard interaction

Return to **Risk Decision & Scenario Review**.

Select the matrix cell **Counteroffer review required → Evidence decline**, then select Merchant **000003** in the application table.

The selection should still update the Baseline and Recession Energy narratives. The `Pair Key` field remains on Detail, so the existing application-selection action should continue working.

**One caution:** Tableau sometimes inserts additional measures automatically when Measure Values is first added. Make sure you remove those extras—otherwise the application table may gain unwanted columns.

Once complete, your Application Detail table will have six clearly labeled columns, with **Requested Amount** on the far right.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9366b879-ad96-45ef-80e0-38bfa284dc0e"></a>
## Andrew / user · C123-M00463

C123-M00463 · 2026-10-16T09:37:06.126000-04:00 · active path

Preceding visible parent: [C123-M00462](part-38.md#m-0b93aa04-ef5f-4344-a111-6b6fc31fca0f)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-133621).png; image(20261016-133642).png; image(20261016-133704).png

<!-- BEGIN_SOURCE_MESSAGE -->
let's work on this now. and note the final 04 section. currently we have
<!-- END_SOURCE_MESSAGE -->


<a id="m-f24ecf9e-bbc3-4c47-b77d-1afb2c4bb51e"></a>
## Assistant · C123-M00464

C123-M00464 · 2026-10-16T09:37:15.341489-04:00 · active path

Preceding visible parent: [C123-M00463](part-38.md#m-9366b879-ad96-45ef-80e0-38bfa284dc0e)

<!-- BEGIN_SOURCE_MESSAGE -->
This is the right point to refine the **application investigation and narrative section**. Your decision matrix and segment comparison are now well organized, and the Requested Amount header is fixed.

Looking at your screenshots, I see three opportunities:

1. **Section 04 is working, but only three application rows are visible.** We can make it a more useful investigation workspace.
2. **Selection Narrative is unnecessarily large when nothing is selected.** It repeats instructions and consumes valuable space.
3. **Baseline Story and Stress Story still feel like separate Tableau worksheets**, rather than a coordinated, professional decision-explanation experience.

I would consolidate the lower portion into **two numbered sections**, preserving your existing calculations and filter actions.

## 1. The target design

<box border radius="lg" padding={3} gap={3}>
  <box gap={1}>
    <row align="baseline" wrap="wrap" gap={2}>
      <text weight="medium">04 / APPLICATION INVESTIGATION</text>
      <text color="secondary" size="xs">— Select an application to inspect its decision evidence</text>
    </row>
    <table>
      <table-row>
        {#each ["Merchant","Industry","Acquisition Source","Baseline Decision","Stress Decision","Requested"] as h}
          <table-cell><text size="3xs" weight="medium">{h}</text></table-cell>
        {/each}
      </table-row>
      {#each [
        ["000003","Healthcare","Digital Direct","Counteroffer review","Evidence decline","$61,300"],
        ["000014","Construction","Strategic Partner","Counteroffer review","Evidence decline","$13,400"],
        ["000026","Ecommerce","Digital Direct","Counteroffer review","Evidence decline","$9,100"]
      ] as r,i}
        <table-row>
          {#each r as c,j}
            <table-cell>
              <text size="3xs" weight={i===0?"medium":"normal"}>{c}</text>
            </table-cell>
          {/each}
        </table-row>
      {/each}
    </table>
    <caption>Illustrative selected decision pairing. The live Tableau table remains filter-driven.</caption>
  </box>
  <divider color="subtle"/>
  <box gap={2}>
    <row align="baseline" wrap="wrap" gap={2}>
      <text weight="medium">05 / MERCHANT EVIDENCE & DECISION INTERPRETATION</text>
      <text color="secondary" size="xs">— Source-backed explanation of the selected application</text>
    </row>
    <box background="surface-secondary" padding={2} radius="sm">
      <text size="xs" weight="medium">Merchant 000003 · Healthcare Services · Digital Direct</text>
      <text size="xs" color="secondary">Baseline: Counteroffer review required · Recession Energy: Evidence decline</text>
    </box>
    <grid columns={2} gap={2}>
      <grid-item>
        <box border radius="md" padding={3} gap={2} height="100%">
          <text weight="medium" size="sm">Baseline</text>
          <text size="xs">A potentially supportable $42,500 structure is retained for specialist review. It is not an authorized offer.</text>
        </box>
      </grid-item>
      <grid-item>
        <box border radius="md" padding={3} gap={2} height="100%">
          <text weight="medium" size="sm">Recession Energy</text>
          <text size="xs">Required sales evidence is incomplete: 28 usable days versus 30 required. Dependent assessment cannot proceed.</text>
        </box>
      </grid-item>
    </grid>
  </box>
</box>

This is a conceptual layout, not a replacement for your Tableau views. It shows how I would organize the content you have already built.

## 2. Improve Section 04 — Application Investigation

Your current application table has the right six columns:

**Merchant · Industry · Acquisition Source · Baseline Decision · Stress Decision · Requested Amount**

Keep them.

The issue is height. Three visible rows make the table feel like a preview rather than an investigation tool.

### Tableau steps

1. Open **Risk Decision & Scenario Review** in dashboard editing mode.
2. Select the `04 — Application Detail` worksheet.
3. In **Layout**, locate its height.
4. Increase it from its current size to approximately **220–250 pixels**.
5. Keep **Fit → Fit Width**, allowing vertical scrolling for longer application lists.
6. Ensure the application table occupies the full available dashboard width.

This should show roughly six to eight applications, depending on your font and row height.

**Keep the existing matrix-to-application and application-to-narrative actions unchanged.** The current structure is already working.

## 3. Make Section 05 the complete explanation area

Your screenshot currently has a large heading:

**Selection Narrative**

followed by a two-line instruction, then two separately titled worksheets.

I would remove the visible *Selection Narrative* title entirely.

Instead, use a single section heading:

**05 / MERCHANT EVIDENCE & DECISION INTERPRETATION** <text color="secondary" inline>— Understand the selected application's evidence and outcome</text>

Beneath that heading, retain the `05 — Selection Narrative` worksheet as a compact context band.

### Step-by-step

1. Select `05 — Selection Narrative` on the dashboard.
2. Open its dropdown menu.
3. Uncheck **Show Title**.
4. Keep the worksheet itself—it supplies the dynamic selected-merchant information.
5. Reduce its height to approximately **55–65 pixels**.

When Merchant 000003 is selected, the band should show the merchant identity and the paired decision outcomes, as you've already demonstrated.

When nothing is selected, it should give a concise instruction rather than occupy several lines.

### Optional improvement to the unselected state

Edit your `Narrative - Investigation Header` calculation. Change only the multiple-application branch to:

```tableau
ELSE
    STR(COUNTD([Pair Key]))
    + " applications in the current investigation. "
    + "Select an application above to inspect its evidence and decision rationale."
```

This avoids repeating the different-decision count already shown in the executive KPI and narrative.

It also gives the user one clear next action.

## 4. Turn the two story worksheets into paired narrative panels

Keep `06 — Baseline Story` and `07 — Stress Story` inside their existing horizontal container.

Rename their displayed titles:

**Baseline** and **Recession Energy**

You do not need the word “Story” because the section heading already establishes that these are explanations.

### Tableau steps

For each embedded worksheet:

1. Open its dashboard dropdown.
2. Choose **Edit Title** and replace the title.
3. Set **Fit → Entire View**.
4. In **Layout**, give the worksheet approximately **180–220 pixels** of height.
5. Use consistent 12-point text, top-left aligned.
6. Set a thin light-gray border and approximately 8–10 pixels of padding.

If the Decision narratives fit without scrollbars at this height, retain it. If not, increase the overall dashboard height rather than shrinking the font.

**Do not change the underlying story calculations.** They already handle Decision, Evidence, Structure, and Source rationale appropriately.

## 5. One functional issue worth addressing

Your earlier screenshots demonstrated that selecting a matrix cell and then an application works. But in your latest screenshots, no matrix cell is selected and the investigation narrative shows all 750 applications.

That is correct behavior.

However, an executive user might not immediately understand the workflow. I would make the instruction slightly more explicit in Section 04:

> **Select a decision pairing above to narrow the applications, then select an application to inspect its evidence.**

This teaches the two-step investigation process without requiring a separate instruction panel.

Also, retain the current action boundaries: the matrix filters the investigation population, while selecting an application updates the explanation panels without changing portfolio KPIs.

## 6. What I would not change

I would preserve the following:

- Your six-column application table.
- The original matched-application identifiers and source-backed narrative data.
- The parameter-driven Decision / Evidence / Structure / Source rationale selector.
- The Baseline-versus-Recession Energy distinction.
- The existing filter actions.
- The full-width lower section.

I would **not** add another chart, a third narrative panel, or an additional dashboard page at this stage.

## Next checkpoint

Make these changes in order:

1. Increase the application table height to approximately 220–250 pixels.
2. Add the new Section 05 heading.
3. Hide the Selection Narrative worksheet title and reduce its height.
4. Rename the two story-panel titles.
5. Ensure both Decision narratives are readable without scrolling.

Then select the matrix cell **Counteroffer review required → Evidence decline** and Merchant **000003**.

Send a screenshot of the complete lower section with that selection active. We can then assess whether the narrative panels need more space for **Evidence** and **Structure** modes before the final dashboard QA pass.
<!-- END_SOURCE_MESSAGE -->


<a id="m-52f06774-39fe-459f-abdd-379e2698a4d8"></a>
## Andrew / user · C123-M00465

C123-M00465 · 2026-10-16T10:04:14.324000-04:00 · active path

Preceding visible parent: [C123-M00464](part-38.md#m-f24ecf9e-bbc3-4c47-b77d-1afb2c4bb51e)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-140358).png; image(20261016-140410).png

<!-- BEGIN_SOURCE_MESSAGE -->
I'm happy with this. Thoughts?
<!-- END_SOURCE_MESSAGE -->


<a id="m-04647b1e-3d9e-4565-a813-91963d950f07"></a>
## Assistant · C123-M00466

C123-M00466 · 2026-10-16T10:04:23.827481-04:00 · active path

Preceding visible parent: [C123-M00465](part-38.md#m-52f06774-39fe-459f-abdd-379e2698a4d8)

<!-- BEGIN_SOURCE_MESSAGE -->
**I think you've reached a very strong working dashboard. I'd grade the visual presentation A-, and the underlying analytical concept A.** More importantly, this is now a useful risk-management investigation tool, not simply a demonstration that you know how to make charts in Tableau.

The second screenshot, with Merchant 000340 selected and **Evidence** as the narrative mode, is particularly encouraging. It demonstrates the feature I wanted us to prioritize: source-backed, side-by-side explanations that change with the selected application and scenario.

## What I particularly like

**1. The executive-to-merchant workflow is coherent.** You can move from the portfolio KPIs to the decision matrix, narrow the application population, and inspect the underlying merchant evidence. The five numbered sections give readers a clear path through the analysis.

**2. The scenario explanations have real substance.** Merchant 000340 is an effective example. Baseline shows annualized eligible sales of approximately $186,333 and available liquidity of $12,584, compared with stress values of approximately $160,688 and $3,151. Both scenarios retain clear verification and 30 usable sales-history days. That immediately invites a meaningful analytical question: if the evidence remains sufficient, what explains the different financing decisions? The **Structure** and **Decision** narrative modes can answer that question.

**3. The dashboard distinguishes risk outcomes rather than collapsing everything into approval versus decline.** The matrix retains authorized, review-required, insufficient-evidence, no-feasible-structure, and hard-stop categories. That's important for a Global Risk Management audience.

**4. The layout is restrained.** No unnecessary gauges, decorative charts, or excessive color. The segment comparison is readable, the matrix is appropriately prominent, and the explanations are legible at the bottom.

## One important issue I would correct before calling it finished

<box gap={2}>
  <row align="center" gap={2}>
    <icon name="alert-triangle" color="secondary" size="lg"/>
    **Your KPI cards are responding to the individual application selection, but the executive narrative and matrix are not.**
  </row>
  <grid columns={2} gap={2}>
    <box border radius="md" padding={3} gap={1}>
      <text color="secondary" weight="medium" size="xs">KPI cards</text>
      <title size="xl">1 application</title>
      <text size="xs">1 different decision, 1 Baseline authorized, 0 stress authorized</text>
    </box>
    <box border radius="md" padding={3} gap={1}>
      <text color="secondary" weight="medium" size="xs">Executive narrative</text>
      <title size="xl">750 applications</title>
      <text size="xs">236 different decisions, 103 Baseline authorized, 27 stress authorized</text>
    </box>
  </grid>
</box>

This is a **material scope-consistency issue**, not just formatting. A risk manager could reasonably interpret the top cards as describing the portfolio while they actually describe Merchant 000340.

We intentionally designed the dashboard so that selecting an application affects only the lower investigation section.

### Fix

Open **Dashboard → Actions** and inspect the `Inspect application` action.

Its targets should be only:

- `05 — Selection Narrative`
- `06 — Baseline Story`
- `07 — Stress Story`

Likewise, the `Select decision pairing` action should target `04`, `05`, `06`, and `07`—not the KPI cards.

If the KPI sheets are already excluded, inspect **Dashboard → Actions** for an additional automatically generated filter action, or a worksheet configured with **Use as Filter**.

Once corrected, selecting Merchant 000340 should leave the four cards at **750 / 236 / 103 / 27** when no portfolio filters are applied. Industry and Acquisition Source filters should still update all four.

**I would not publish until this is resolved.**

## Two smaller refinements

The first is **making the matrix selection easier to read**. Your selected cell remains highlighted while the other cells are faded, which is normal Tableau selection behavior. For a demonstration, that's acceptable. But we should ensure the user can easily clear a selection and restore the full matrix.

The second is **the top-level Narrative Detail control**. You've correctly moved it beside Section 05. That's better: its placement makes clear that it changes the individual explanation, not the portfolio interpretation.

I would leave the overall layout alone. Further rearrangement risks sacrificing the readability we've worked to establish.

## My assessment

| Dimension | Grade |
|---|---|
| Executive layout and hierarchy | A |
| Decision comparison | A |
| Segment sensitivity | A- |
| Merchant investigation | A |
| Dynamic evidence interpretation | A |
| Filter/action consistency | **Needs correction** |
| Overall current readiness | **A- working draft** |

The remaining work should be a **focused QA and polish pass**, not another redesign.

Once the KPI selection issue is corrected, I'd test three representative cases: Merchant 000003 for insufficient evidence under stress, Merchant 000340 for authorized-to-no-feasible differences, and an unchanged-category application to ensure the narrative does not falsely imply unchanged terms or evidence.

**You have built the analytical experience we set out to create.** The next step is proving its filters, calculations, and explanations remain consistent under interaction. That's the final distinction between an attractive Tableau portfolio piece and a controlled, executive-ready risk-management dashboard.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dd45a62e-96c3-4800-8177-5836ae10ed23"></a>
## Andrew / user · C123-M00467

C123-M00467 · 2026-10-16T10:13:35.517000-04:00 · active path

Preceding visible parent: [C123-M00466](part-38.md#m-04647b1e-3d9e-4565-a813-91963d950f07)

<!-- BEGIN_SOURCE_MESSAGE -->
why are we not having the segment sensitivity chart adjust to selections? thoughts on that?
<!-- END_SOURCE_MESSAGE -->


<a id="m-e00f2ceb-3cb8-4d41-8a40-242b62866eea"></a>
## Assistant · C123-M00468

C123-M00468 · 2026-10-16T10:13:44.078909-04:00 · active path

Preceding visible parent: [C123-M00467](part-38.md#m-dd45a62e-96c3-4800-8177-5836ae10ed23)

<!-- BEGIN_SOURCE_MESSAGE -->
**I think you're right to challenge that design choice.** We deliberately kept Segment Sensitivity independent of matrix and merchant selections to preserve a stable portfolio comparison. That was defensible for the initial build, but now that the dashboard is functional, I think we can make it more analytically useful.

The key is distinguishing **which selection should affect the chart and what question the resulting chart is answering**.

## My recommendation: Make Segment Sensitivity respond to the decision matrix, but not individual merchant selections

Consider these three analytical states:

| User interaction | What Segment Sensitivity should show | Why |
|---|---|---|
| **Industry / Acquisition Source filters** | Authorization rates for the selected portfolio | Defines the population under review |
| **Select a decision-matrix cell** | The industry/source distribution of applications in that decision pairing | Identifies where that particular decision outcome is concentrated |
| **Select one merchant** | Keep the selected decision-pairing distribution | Preserves segment-level context while investigating an individual application |

This gives the chart a meaningful role in the investigation rather than leaving it as a static companion.

However, there's an important technical issue.

## We should not simply filter the existing authorization-rate chart by matrix selection

Suppose you click the matrix cell:

**Counteroffer review required → Evidence decline (88 applications).**

If we filter the current authorization-rate chart to those 88 applications, their Baseline and stress authorization rates will both be **0% by definition**.

That would be mathematically correct but analytically useless.

The same problem occurs for any decision pairing where authorization status is already determined by the selected categories.

**Instead, the chart should change its metric when the user selects a matrix cell.**

## Proposed dual-purpose Segment Sensitivity

<box border radius="lg" padding={3} gap={3}>
  <row justify="between" align="center">
    <box gap={1}>
      <title size="lg">Segment Sensitivity</title>
      <text color="secondary" size="xs">Explore portfolio authorization or the concentration of a selected decision pairing</text>
    </box>
  </row>
  {@body const [mode,setMode] = DIL.useState("pair")}
  <segmented-control size="md" block value={mode} onChange={setMode} options={[{"label":"Portfolio authorization","value":"portfolio"},{"label":"Selected pairing","value":"pair"}]}/>
  {#if mode==="portfolio"}
    <box gap={1}>
      <Chart content={{"chartType":"bar","meta":{"footer":"Illustrative full-population industry rates from your current Tableau view"},"xKey":"segment","series":[{"dataKey":"baseline","label":"Baseline","valueSuffix":"%"},{"dataKey":"stress","label":"Recession Energy","valueSuffix":"%"}],"data":[{"segment":"Professional Services","baseline":26.8,"stress":7.1},{"segment":"Transportation Logistics","baseline":18.9,"stress":7.8},{"segment":"Healthcare Services","baseline":18.3,"stress":4.9},{"segment":"Ecommerce Digital","baseline":16.2,"stress":4.4}]}}/>
    </box>
  {:else}
    <box gap={2}>
      <text size="sm" weight="medium">Counteroffer review → Evidence decline</text>
      <title size="2xl" tabularNums>88 applications</title>
      <text color="secondary" size="xs">Illustrative layout. Segment-level counts must be calculated from the selected pairing, not inferred from the existing authorization-rate chart.</text>
      <box background="surface-secondary" padding={3} radius="md" gap={2}>
        <text size="xs">Industry or acquisition-source breakdown would appear here, ranked by affected applications or within-segment incidence.</text>
      </box>
    </box>
  {/if}
</box>

The important distinction is that **the chart changes analytical purpose**, not merely its filtered population.

### Two useful measures for the selected-pairing mode

For each industry or acquisition source, we could display:

**Affected applications:** How many applications belong to the selected decision pairing?

**Within-segment incidence:** What percentage of all applications in that segment belong to the selected pairing?

For example, 10 affected Healthcare Services applications out of 82 would be **12.2%**. This is more useful for comparing concentrations across differently sized industries than counts alone.

The 10 and 82 values are already established in your current Tableau work. We should calculate the corresponding rates dynamically for every segment.

## How I would implement it

I would preserve your existing `08 — Segment Comparison` worksheet and create a second worksheet for **Selected Pairing Concentration**.

Then use Tableau's parameter and dashboard-action capabilities to switch between them, rather than trying to force two fundamentally different metrics into the same chart.

The implementation would be:

1. Keep the current authorization-rate chart as the default portfolio view.
2. Create a selected-pairing concentration chart using `Review Segment` and matched-application counts.
3. Capture the selected matrix pairing through an explicit parameter action, or an equivalent controlled selection mechanism.
4. Calculate affected counts and incidence against the correct portfolio-filtered segment denominators.
5. Allow the viewer to switch between authorization rates and selected-pairing concentration.

**One caution:** Tableau's ordinary filter actions alone will not preserve the full segment denominator after filtering to a decision pairing. We would need to design that calculation carefully, potentially using FIXED level-of-detail expressions with the appropriate context filters or a separate denominator calculation. I would not present a percentage until its filter behavior is verified.

## Why I prefer this design

It strengthens the dashboard's risk-management workflow:

**Identify:** Which decisions differ across scenarios?

**Concentrate:** Which industries or acquisition channels account for the selected difference?

**Investigate:** Which applications are affected?

**Explain:** What source evidence and decision rationale support the outcome?

That's a stronger analytical story than having the segment chart remain completely independent of the investigation.

**My recommendation is to implement this as a controlled second analytical mode, not overwrite the authorization-rate chart.** The existing chart is useful for executive portfolio review; the new concentration view would add a genuinely investigative capability.

We should first correct the KPI scope issue identified in the previous screenshot, then build the pairing-concentration worksheet. That preserves the work you've already completed while extending its analytical value.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0e9b5ae7-bb40-4ac7-9829-6106c96ba1bd"></a>
## Andrew / user · C123-M00469

C123-M00469 · 2026-10-16T10:17:24.724000-04:00 · active path

Preceding visible parent: [C123-M00468](part-38.md#m-e00f2ceb-3cb8-4d41-8a40-242b62866eea)

<!-- BEGIN_SOURCE_MESSAGE -->
I duplicated 08 - Segment Comparison and called it 13 - Selected Segment Pairing Concentration. what are the next steps?
<!-- END_SOURCE_MESSAGE -->


<a id="m-3ea772dd-22ee-42ab-8005-42ef08c950ad"></a>
## Assistant · C123-M00470

C123-M00470 · 2026-10-16T10:17:33.062584-04:00 · active path

Preceding visible parent: [C123-M00469](part-38.md#m-0e9b5ae7-bb40-4ac7-9829-6106c96ba1bd)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. Duplicating `08 — Segment Comparison` was the right starting point. It preserves your segment-switching parameter, chart formatting, and portfolio filters.

Now we'll turn `13 — Selected Segment Pairing Concentration` into a genuinely useful risk-investigation chart.

**Our objective:** When you select a decision pairing in the matrix, Tableau should show which industries or acquisition sources contribute to that pairing, how many applications are affected, and what percentage of each segment's applications they represent.

We'll build this in two stages: first the counts and interaction, then the correctly controlled percentage denominator.

## Step 1 — Create a calculated field to identify the selected pairing

We need Tableau to know which matrix pairing you selected without filtering away the applications needed for the denominator.

We'll use **two parameters**, populated by a dashboard parameter action.

Create the first parameter:

| Setting | Value |
|---|---|
| Name | `Selected Baseline Decision Code` |
| Data type | String |
| Allowable values | All |
| Current value | `ALL` |

Create the second:

| Setting | Value |
|---|---|
| Name | `Selected Stress Decision Code` |
| Data type | String |
| Allowable values | All |
| Current value | `ALL` |

**Important:** Use the exact string values from your existing decision-code fields. These parameters are intended to hold the source decision codes, not the readable labels.

## Step 2 — Create the selected-pairing indicator

Choose **Analysis → Create Calculated Field**.

Name:

`Selected Pairing Flag`

Formula:

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

This returns `1` for applications in the selected pairing and `0` otherwise.

Notice that **we are not filtering the underlying dataset to the pairing**. That's intentional. We need all applications within each segment to calculate a valid incidence rate.

## Step 3 — Create three measures

### A. `Selected Pairing Applications`

```tableau
SUM([Selected Pairing Flag])
```

### B. `Segment Applications`

```tableau
COUNTD([Pair Key])
```

### C. `Selected Pairing Incidence`

```tableau
IF [Segment Applications] > 0 THEN
    [Selected Pairing Applications] / [Segment Applications]
END
```

Format `Selected Pairing Incidence` as a percentage with one decimal place.

These measures will respond to Industry and Acquisition Source filters while retaining the full selected-segment denominator, provided we do not apply the matrix's ordinary pairing filter to worksheet 13.

## Step 4 — Reconfigure worksheet 13

Open `13 — Selected Segment Pairing Concentration`.

Remove the two authorization-rate measures from **Measure Values**.

Then configure:

| Tableau location | Field |
|---|---|
| Rows | `Review Segment` |
| Columns | `Selected Pairing Incidence` |
| Marks type | Bar |
| Color | `Selected Pairing Applications` |
| Label | `Selected Pairing Incidence` |
| Tooltip | `Selected Pairing Applications`, `Segment Applications` |

Remove **Measure Names** from Rows, Color, and Filters. You no longer need the two-measure structure.

Keep `Review Segment`, because that is what allows your existing **Review Segment By** parameter to switch between Industry and Acquisition Source.

### Sort

Sort `Review Segment` descending by `Selected Pairing Incidence`, if Tableau allows the aggregate field.

Set the horizontal axis to a fixed range of **0 to 1**, formatted as percentages.

For now, use the title:

**Selected Decision Pairing — Segment Concentration**

Subtitle:

*Affected applications as a share of each segment's matched population.*

## Step 5 — Connect the decision matrix using parameter actions

Return to your dashboard.

Choose **Dashboard → Actions → Add Action → Change Parameter**.

Configure the first action:

| Setting | Value |
|---|---|
| Name | `Set Baseline Pairing` |
| Source sheet | `02 — Decision Matrix` |
| Run action on | Select |
| Target parameter | `Selected Baseline Decision Code` |
| Source field | `Baseline Decision Code` |
| Aggregation | None |
| Clearing selection | Set value to `ALL` |

Create a second parameter action:

| Setting | Value |
|---|---|
| Name | `Set Stress Pairing` |
| Source sheet | `02 — Decision Matrix` |
| Run action on | Select |
| Target parameter | `Selected Stress Decision Code` |
| Source field | `Stress Decision Code` |
| Aggregation | None |
| Clearing selection | Set value to `ALL` |

Your decision matrix already contains both decision-code fields on Detail from our earlier work. Keep them there.

**Select one matrix cell at a time.** The parameter actions should receive one distinct Baseline and one distinct stress code.

## Step 6 — Test the calculation before replacing anything

Keep your existing `08 — Segment Comparison` on the dashboard for now.

Temporarily add worksheet `13 — Selected Segment Pairing Concentration` beneath it or open it separately after selecting a matrix cell.

Select:

**Counteroffer review required → Evidence decline**

The matrix contains **88 applications** in that pairing.

Your new chart should now display the selected-pairing incidence for each industry, while retaining all 750 matched applications as the overall comparison population.

For Healthcare Services, the expected result is:

<box border radius="lg" padding={3} gap={2}>
  <text weight="medium">Healthcare Services</text>
  <row justify="between" align="baseline">
    <title size="xl" tabularNums>12.2%</title>
    <text color="secondary" size="sm">10 of 82 applications</text>
  </row>
  <box background="surface-tertiary" height="12px" radius="full" clip>
    <box background="#438d9c" width="12.2%" height="100%" radius="full"/>
  </box>
  <caption>Selected pairing: Counteroffer review required → Evidence decline</caption>
</box>

This is an important validation case: **10 affected applications ÷ 82 Healthcare Services applications = 12.2%.**

If the chart shows 100%, its denominator has likely been restricted to the selected pairing. If it shows 0%, inspect the parameter values and source-field mappings.

## Step 7 — Keep the existing chart until the new one passes

Do not remove `08 — Segment Comparison` yet.

Once worksheet 13 correctly responds to matrix selections, we'll decide how to present both analytical modes. My preference is to let users switch between:

**Portfolio authorization rates** and **Selected-pairing incidence**.

We can do that using Tableau's dynamic zone visibility or a simple controlled dashboard layout, depending on which features your Tableau Public edition supports.

This will give Segment Sensitivity two distinct analytical purposes without forcing misleading authorization-rate calculations onto a population already defined by its decision outcome.

---

**Your immediate checkpoint:** Complete Steps 1–4, then create the two parameter actions in Step 5. Select the 88-application pairing and send a screenshot of worksheet 13 showing Healthcare Services.

We want to verify **10 affected applications, 82 segment applications, and 12.2% incidence** before introducing any additional dashboard complexity.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f0da90de-a028-4e83-8361-6d3923edcd6d"></a>
## Andrew / user · C123-M00471

C123-M00471 · 2026-10-16T12:16:43.704000-04:00 · active path

Preceding visible parent: [C123-M00470](part-38.md#m-3ea772dd-22ee-42ab-8005-42ef08c950ad)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-161640).png

<!-- BEGIN_SOURCE_MESSAGE -->
step 4, what have I done wrong?
<!-- END_SOURCE_MESSAGE -->


<a id="m-eded10f6-76d3-48a4-b63b-8a3d274a586e"></a>
## Assistant · C123-M00472

C123-M00472 · 2026-10-16T12:16:55.039821-04:00 · active path

Preceding visible parent: [C123-M00471](part-38.md#m-f0da90de-a028-4e83-8361-6d3923edcd6d)

<!-- BEGIN_SOURCE_MESSAGE -->
**You haven't made a major mistake. Your worksheet is almost correctly configured.** I can see two things to fix and one expected behavior that may be causing confusion.

Most importantly, **the 0.0% values are expected until we populate the two selected-decision parameters in Step 5.** Your `Selected Pairing Flag` deliberately returns zero when either parameter is `ALL`.

## 1. Remove the extra filter

In your screenshot, the Filters shelf contains:

- `Industry` — keep
- `Acquisition Source` — keep
- `AGG(Baseline Authorizations)` — **remove**

That third filter was carried over when you duplicated worksheet 08.

Right-click `AGG(Baseline Authorizations)` on the Filters shelf and select **Remove**.

This is important because the new chart needs to retain all applications in each segment, including those without Baseline authorization. Otherwise, its denominator could be incorrect.

## 2. Remove the redundant Marks fields

Your Marks card currently shows `Selected Pairing Applications` three times:

- Color
- Tooltip
- Tooltip

You only need one copy on Tooltip.

For the first version, I recommend this configuration:

| Location | Field |
|---|---|
| **Rows** | `Review Segment` |
| **Columns** | `Selected Pairing Incidence` |
| **Marks type** | Bar |
| **Label** | `Selected Pairing Incidence` |
| **Tooltip** | `Selected Pairing Applications` |
| **Tooltip** | `Segment Applications` |
| **Color** | No field; use one consistent teal or blue |

Remove the redundant pills and add `Segment Applications` to Tooltip.

This is a cleaner presentation and avoids implying that darker colors necessarily indicate greater risk.

## 3. Test the calculation before creating the dashboard actions

We can verify the formula immediately by temporarily entering a known decision pairing into the parameters.

First, open **02 — Decision Matrix** and hover over the cell containing **88 applications**:

**Baseline: Counteroffer review required**  
**Stress: Evidence decline**

We need the exact underlying decision codes, not their display labels.

The easiest way to see them is to temporarily edit the matrix tooltip and insert:

```text
Baseline code: <Baseline Decision Code>
Stress code: <Stress Decision Code>
```

Use Tableau's **Insert** menu to add the actual field tokens.

Then hover over the 88 cell and note the two codes.

### Enter those values into the parameters

In the Data pane, under Parameters:

1. Right-click `Selected Baseline Decision Code` → **Edit**.
2. Set **Current value** to the exact Baseline code you just identified.
3. Click **OK**.
4. Repeat for `Selected Stress Decision Code` using the stress code.

Return to worksheet **13 — Selected Segment Pairing Concentration**.

With all industries and acquisition sources selected, Healthcare Services should display:

<box border radius="lg" padding={3} gap={2}>
  <text weight="medium">Healthcare Services — selected pairing</text>
  <row align="baseline" justify="between">
    <title size="2xl">12.2%</title>
    <text color="secondary" size="sm">10 of 82 applications</text>
  </row>
  <box background="surface-tertiary" height="12px" radius="full" clip>
    <box background="#438d9c" height="100%" width="12.2%" radius="full"/>
  </box>
  <caption>Counteroffer review required → Evidence decline</caption>
</box>

If that works, the calculations are correct and we're ready to automate the parameter changes using the two dashboard actions.

## 4. Correct the worksheet title

Your duplicated worksheet still displays:

**03 / SEGMENT SENSITIVITY — Authorization Rates by selected grouping**

That describes the original authorization-rate chart, not this new one.

Change it to:

**SELECTED PAIRING CONCENTRATION** — Share of each segment in the selected decision pairing.

I would not assign it a new section number yet. It will eventually become an alternative view within Section 03.

## What I want you to do next

**Remove the `AGG(Baseline Authorizations)` filter first.** Then manually set the two decision-code parameters to the 88-application pairing.

If Healthcare Services shows **10 of 82 = 12.2%**, Step 4 passes.

After that, we'll wire the matrix parameter actions and decide how to switch between the original authorization-rate chart and this new concentration chart without cluttering the dashboard.
<!-- END_SOURCE_MESSAGE -->


<a id="m-675b942c-3429-4e06-853c-42e2b76fccb5"></a>
## Andrew / user · C123-M00473

C123-M00473 · 2026-10-16T12:23:18.323000-04:00 · active path

Preceding visible parent: [C123-M00472](part-38.md#m-eded10f6-76d3-48a4-b63b-8a3d274a586e)

**Editorial record note:** 6 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(20261016-162137).png; image(20261016-162146).png; image(20261016-162159).png; image(20261016-162208).png; image(20261016-162225).png; image(20261016-162253).png

<!-- BEGIN_SOURCE_MESSAGE -->
these are all the codes. please advise with that detail - i've done #1 and #2 already
<!-- END_SOURCE_MESSAGE -->
