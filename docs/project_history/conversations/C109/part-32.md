# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 32 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-31.md)
[Next part](part-33.md)

<a id="m-9940fe7c-4180-42a1-96c7-28f335d4f995"></a>
## Assistant · C109-M00690

C109-M00690 · 2026-09-02T14:09:42.070592-04:00 · active path

Preceding visible parent: [C109-M00689](part-31.md#m-cfc2ecc9-7f17-4fc3-a764-2fb9cb38e010)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — most of this **does make sense**, but the screenshot also exposes **one P03 issue we should correct**.

The key is that three different concepts are being shown together: **a candidate structure can be selected by the strategy, that selected structure can still require human authorization, and only an authorized structure should proceed to funding.** In this example, the first two happened; the third did not.

For merchant `000002 / Recession Energy`, the page is saying:

> **REVIEW — Counteroffer review**  
> “The requested structure did not meet the governed economic hurdle. An alternative structure was identified, but it requires manual authorization.”

That is coherent with the successor strategy. The engine searched for a better structure and identified one, but that structure landed on the **review-eligible frontier**, not the automatic-authority frontier. So it is perfectly legitimate for **Selected structure** to contain values even though the final disposition is REVIEW. “Selected” here means *selected by the governed search as the structure to carry forward for review*; it does **not** mean funded.

### Why can the selected amount still equal the requested amount?

Because a counteroffer/alternative structure is not necessarily an amount reduction.

The merchant requested:

- Amount: **$6,500**
- Remittance: **13.09%**
- Payoff horizon: **60 days**
- Repayment: **$7,519.99**

The selected review structure shows:

- Selected amount: **$6,500**
- Remittance: **12.83%**
- Payback multiple: **1.18**
- Horizon: **60 days**
- Repayment: **$7,670.39**

So the engine found a different **economic structure**, even though it preserved the principal amount and horizon.

That is actually one of the sophistication improvements we wanted from the remediation: **counteroffer search is multidimensional rather than “reduce the requested amount until it passes.”** The engine can modify pricing/remittance/structure terms while keeping the requested advance intact when that is the preferable candidate.

And repayment being greater than selected amount is normal. This is merchant financing; the repayment amount includes the finance charge. Roughly:

`$6,500 × ~1.18 ≈ $7,670`

So `$7,670.39` is economically consistent with the displayed payback multiple. The selected remittance rate being **12.83% instead of 13.09%** also confirms this is not simply the original request being repeated.

There is an interesting nuance in the narrative: the requested structure was below the economic hurdle, yet the alternative structure raises total repayment while slightly lowering the remittance percentage. That can improve the modeled economics without increasing the daily remittance burden proportionally. In other words, **same advance amount ≠ same structure**.

### The part that does *not* make sense: `Funding date = 7/25/2026`

That is the important finding.

For this path, the governed disposition is:

**REVIEW / Counteroffer review**

and your right-hand funded-account lifecycle is correctly blank. So the page should **not simultaneously tell the user that this review candidate was funded on 7/25/2026**.

I think we now know why this happened: we retained the old P03 `Funded`/funding-date field while rebasing the selected-structure measures. That older field is almost certainly resolving from a different/core source or at a grain that does not respect the successor scenario's final authorization state.

So I would interpret the screenshot as:

**Correct**
- REVIEW
- Counteroffer review
- selected candidate/structure populated
- amount may equal request
- different remittance/payback economics
- no account-performance lifecycle

**Incorrect**
- `Funding date = 7/25/2026`

### One terminology improvement I now recommend

This example also makes me slightly reconsider **Selected structure** as the visible heading.

Technically it is correct because the source has a governed selected candidate, but a business user could reasonably read “Selected structure” as “the deal we gave them.”

I think the cleaner P03 heading is:

**Proposed structure**

or, if we want maximum governance precision:

**Selected / proposed structure**

My preference is **Proposed structure**. Then:

- AUTHORIZED path: proposed structure became the authorized/funded structure.
- REVIEW path: proposed structure awaits authorization.
- DECLINE/no feasible structure: no proposed structure.

That makes this exact `000002` case intuitive rather than requiring the user to know what “selected” means in the strategy engine.

### What I would change now

Do **not** change any of the five R26 structure measures. They are revealing useful information correctly.

Remove the existing raw **Funding date** field from that visual now.

Then we should replace it with an authorization/funding-aware scalar measure that only displays a funding date when the selected merchant/scenario actually crossed the funding/activation boundary. For this `000002 / Recession Energy` case, the result should be blank.

So this screenshot is valuable: **it does not show a strategy contradiction. It shows that P03 is successfully exposing sophisticated review-eligible counteroffers, while also revealing that the legacy funding-date field must be rebased to the successor path.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-c8f0e4a2-8fe2-41a1-8e77-cd02930a4212"></a>
## Andrew / user · C109-M00691

C109-M00691 · 2026-09-02T14:12:30.568000-04:00 · active path

Preceding visible parent: [C109-M00690](part-32.md#m-9940fe7c-4180-42a1-96c7-28f335d4f995)

<!-- BEGIN_SOURCE_MESSAGE -->
so, the payback multiple is important to understanding the link between amount/repayment - and yet we do not see that same variable under merchant request to understand an apples to apples comparison
<!-- END_SOURCE_MESSAGE -->


<a id="m-bfac680a-e39c-4a35-a72b-67782ec1eba4"></a>
## Assistant · C109-M00692

C109-M00692 · 2026-09-02T14:12:39.467661-04:00 · active path

Preceding visible parent: [C109-M00691](part-32.md#m-c8f0e4a2-8fe2-41a1-8e77-cd02930a4212)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. **Payback multiple is the missing comparison variable.** Without it, the user sees requested amount and requested repayment on the left, then selected amount, remittance, payback multiple, horizon, and repayment on the right—but cannot immediately tell whether the economics changed because of amount, pricing, duration, or some combination.

For an apples-to-apples request-versus-proposed comparison, I would add **Requested payback multiple** to the Merchant request row.

The cleanest layout is:

| Merchant request | Proposed structure |
|---|---|
| Requested amount | Selected amount |
| Remittance | Remittance |
| **Payback multiple** | **Payback multiple** |
| Payoff days | Horizon days |
| Repayment | Repayment |

You can still keep **Application / Applied / Use / Channel** in the request block because those have no structural counterpart; but the economic terms should line up conceptually.

The requested payback multiple can be calculated directly from the request values:

```DAX
R26 P03 Requested Payback Multiple =
DIVIDE (
    [P03 Requested Repayment],
    [P03 Requested Amount]
)
```

But I would **not yet use those guessed measure names**. We should use the exact existing measures/fields behind the current `Requested` and `Repayment` cells in the Merchant request visual, just as we did with Industry.

For the example on screen:

- Requested amount: **$6,500**
- Requested repayment: **$7,519.99**
- Requested payback multiple ≈ **1.157**
- Proposed payback multiple: **1.18**

So visually the user would immediately understand: **same $6,500 principal, slightly lower remittance rate, same 60-day horizon, but a higher payback multiple and higher total repayment.** That makes the reason this is a genuine alternative structure much clearer.

I would format both request and proposed payback multiples to **2 decimals**, so this case reads approximately **1.16 → 1.18**.

One other adjustment follows from this: I now strongly prefer renaming the right block **Proposed structure** rather than `Selected structure`. For REVIEW cases like this, that is much clearer to a business user while still accurately representing the governed candidate chosen for review.
<!-- END_SOURCE_MESSAGE -->


<a id="m-723be6fe-2087-4489-8990-05a86661c54c"></a>
## Andrew / user · C109-M00693

C109-M00693 · 2026-09-02T14:14:48.988000-04:00 · active path

Preceding visible parent: [C109-M00692](part-32.md#m-bfac680a-e39c-4a35-a72b-67782ec1eba4)

<!-- BEGIN_SOURCE_MESSAGE -->
ok, please provide full updated instructions again (excluding the title / left KPI card / decision cards. i need all steps for merchant request/selected structure (or whatever you want to call it)/account performance/monitoring journey/narrative blocks/servicing & intervention/footnotes
<!-- END_SOURCE_MESSAGE -->


<a id="m-f9b64aae-a6fc-4d21-a1bd-21beb4aab512"></a>
## Assistant · C109-M00694

C109-M00694 · 2026-09-02T14:14:52.586141-04:00 · active path

Preceding visible parent: [C109-M00693](part-32.md#m-723be6fe-2087-4489-8990-05a86661c54c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Based on what we learned from `000002 / Recession Energy`, I would make one design adjustment before continuing:

**Rename `Selected structure` → `Proposed structure`.**

That is more intelligible on P03 because the governed strategy can identify/select a structure for human review without authorizing or funding it. The page can then cleanly tell the story:

**Merchant request → Proposed structure → Governed decision → funded lifecycle only if authorized/funded.**

Below is the updated implementation from **Merchant request onward**. I am excluding the title/subtitle, left merchant-profile card, and decision cards as requested.

---

# 1. Merchant request — make the economic comparison complete

The existing block is good, but it is missing **payback multiple**.

### 1A. Preserve these existing request fields

Keep:

```text
Application
Applied
Requested
Use
Channel
Remittance
Payoff days
Repayment
```

We will add:

```text
Payback multiple
```

### 1B. Create Requested Payback Multiple

We should calculate this from the **existing request amount and request repayment source**, not from the proposed structure.

Because we haven't yet established the exact physical fields behind your existing `Requested` and `Repayment` cells, do this first:

1. Click the **Merchant request** visual.
2. Go to **Build visual**.
3. Hover over `Requested`.
4. Record the exact field/measure shown.
5. Hover over `Repayment`.
6. Record that exact field/measure.

If they are existing measures, the final measure will be:

```DAX
R26 P03 Requested Payback Multiple =
DIVIDE (
    [existing requested repayment measure],
    [existing requested amount measure]
)
```

If they are physical columns, use:

```DAX
R26 P03 Requested Payback Multiple =
DIVIDE (
    SELECTEDVALUE ( 'ExactTable'[requested_repayment_field] ),
    SELECTEDVALUE ( 'ExactTable'[requested_amount_field] )
)
```

**Do not guess those field names.** This is one of the few places where we should inspect the existing working visual first.

### 1C. Reorder Merchant request

I recommend:

```text
Application | Applied | Requested | Use | Channel | Remittance | Payback multiple | Payoff days | Repayment
```

That may be slightly tight. If it becomes too compressed, use:

```text
Application | Applied | Requested | Use | Channel | Remittance | Payback | Payoff days | Repayment
```

Rename the new measure **for this visual only** to:

`Payback`

if needed.

### 1D. Format

Requested amount:

`$#,0.00`

Remittance:

`0.00%`

Payback multiple:

`0.00`

Payoff days:

`0`

Repayment:

`$#,0.00`

### 1E. Merchant-request alt text

Freeze this wording:

> **Application request details for the selected merchant and scenario, including application date, requested amount, use, channel, remittance rate, requested payback multiple, requested payoff period, and requested repayment.**

---

# 2. Rename Selected structure → Proposed structure

I now recommend **Proposed structure**.

The `000002 / Recession Energy` case demonstrates why:

```text
REVIEW
Counteroffer review
```

can legitimately coexist with a strategy-selected candidate structure.

Calling that structure "Funded terms" is wrong.

Calling it "Selected structure" is technically defensible but potentially misleading.

**Proposed structure** communicates its business meaning correctly regardless of whether it subsequently becomes authorized and funded.

Rename the heading to:

> **Proposed structure**

---

# 3. Proposed structure — rebuild as a one-row, measure-driven block

### 3A. Remove the legacy fields

Select the existing structure visual.

In **Build visual**, remove the existing raw fields for:

- Funded amount
- Funded
- Remittance
- Payback multiple
- Horizon days
- Repayment
- especially the existing raw **Funding date**

We do not want legacy columns setting the visual grain.

### 3B. Add only the R26 structure measures

Use:

```text
R26 P03 Selected Structure Amount
R26 P03 Selected Remittance Rate
R26 P03 Selected Payback Multiple
R26 P03 Selected Horizon Days
R26 P03 Selected Total Repayment
```

Rename **for this visual**:

```text
Selected Structure Amount         → Amount
Selected Remittance Rate          → Remittance
Selected Payback Multiple         → Payback multiple
Selected Horizon Days             → Horizon days
Selected Total Repayment          → Repayment
```

The visual should now be **at most one row**.

### 3C. Do not add Funding date yet

The screenshot of `000002 / Recession Energy` proved that the old funding-date field is not safe.

That application/scenario is:

`REVIEW / Counteroffer review`

and has no funded-account lifecycle, yet the old field showed:

`7/25/2026`

Therefore remove it.

We will only restore a funding date after creating a **successor-aware funded-path measure** from the actual activation source.

For now, five economic fields are better than displaying a misleading date.

### 3D. Add Candidate Search Summary

This belongs with Proposed structure because it explains how that structure was reached.

Add a small borderless card immediately below the heading or immediately above the proposed-structure values.

Field:

`R26 P03 Candidate Search Summary`

Example:

> Search: 6 evaluated • Review frontier

Formatting:

- Category label: Off
- Background: Off
- Border: Off
- Font: 8–9 pt
- muted gray
- Text wrap: On

This should remain subordinate to the actual terms.

### 3E. Proposed-structure alt text

Update the measure wording from "governed selected structure" to user-facing **proposed structure**.

I would revise the existing alt-text measure to:

```DAX
R26 P03 Selected Structure Alt Text =
VAR _Amount =
    [R26 P03 Selected Structure Amount]
RETURN
    IF (
        ISBLANK ( _Amount ),
        "No proposed structure is present for the selected application and scenario.",
        "Proposed structure. Amount "
            & FORMAT ( _Amount, "$#,0.00" )
            & ", remittance rate "
            & FORMAT ( [R26 P03 Selected Remittance Rate], "0.00%" )
            & ", payback multiple "
            & FORMAT ( [R26 P03 Selected Payback Multiple], "0.00" )
            & ", horizon "
            & FORMAT ( [R26 P03 Selected Horizon Days], "0" )
            & " days, and total repayment "
            & FORMAT ( [R26 P03 Selected Total Repayment], "$#,0.00" )
            & ". "
            & COALESCE ( [R26 P03 Candidate Search Summary], "" )
    )
```

You can retain the technical measure name. We do **not** need to rename measures just because the executive label changed.

---

# 4. Visually align Request versus Proposed structure

This is now an important P03 design principle.

The comparable economics should read:

| Request | Proposed |
|---|---|
| Requested amount | Amount |
| Remittance | Remittance |
| Payback multiple | Payback multiple |
| Payoff days | Horizon days |
| Repayment | Repayment |

This makes cases like `000002 / Recession Energy` immediately interpretable.

There, the user should be able to see approximately:

```text
REQUEST                       PROPOSED
Amount       $6,500           Amount       $6,500
Remittance   13.09%           Remittance   12.83%
Payback      ~1.16            Payback      1.18
Days         60               Horizon      60
Repayment    $7,519.99        Repayment    $7,670.39
```

That tells a much more sophisticated story than "counteroffer means lower advance."

---

# 5. Merchant operating evidence

Keep the heading:

> **Merchant operating evidence**

Replace the existing narrative source with:

`R26 P03 Evidence Narrative`

Do not rewrite or summarize the source-owned narrative.

### Formatting

- Text wrap: On
- Font: keep approximately current size
- Background: Off
- Border: Off
- Maintain your teal divider

The current visual treatment is already good.

### Alt text

If the narrative card itself is accessible, use the narrative measure itself as its dynamic alt text if Power BI accepts it.

Otherwise use:

> **Merchant operating evidence for the selected application and scenario.**

The visible narrative already supplies the substantive detail.

---

# 6. Rename Structure assessment narrative

Change:

> **Structure assessment narrative**

to:

> **Underwriting & structure assessment**

This is more executive-readable and better reflects what the narrative actually contains: capacity, modeled obligations, liquidity, integrated risk, expected loss, contribution and hurdle assessment.

Bind the narrative to:

`R26 P03 Underwriting Narrative`

Again: **source-owned text, no DAX reconstruction.**

Alt text:

> **Underwriting and structure assessment for the selected application and scenario.**

---

# 7. Rename P03 Decision Readout

Change:

> **P03 Decision Readout**

to:

> **Governed decision**

Bind it to:

`R26 P03 Decision Narrative`

That removes internal report-page terminology from the executive presentation.

For `000002 / Recession Energy`, this is exactly where:

> The requested structure did not meet the governed economic hurdle. An alternative structure was identified, but it requires manual authorization.

belongs.

Alt text:

> **Governed decision rationale for the selected application and scenario.**

---

# 8. Account performance — rebase completely to R26 monitoring

Select **Account performance**.

### 8A. X-axis

Remove the old monitoring-date field.

Add:

`R1FactDailyMonitoring[monitoring_date]`

### 8B. Primary Y-axis

Remove the old Receivable balance field.

Add:

`R26 P03 Remaining Receivable`

Rename for this visual:

> Remaining receivable

Format:

`$#,0`

### 8C. Secondary Y-axis

Remove the old Remittance pace.

Add:

`R26 P03 Remittance Pace`

Rename:

> Remittance pace

Format:

`0%` or `0.0%`

I would use **0% on the axis**, while the tooltip can show greater precision.

### 8D. Tooltip fields

Remove the legacy tooltip fields.

Use this order:

1. `R26 P03 Monitoring Status Display`
2. `R26 P03 Remitted To Date`
3. `R26 P03 Cumulative Shortfall`
4. `R26 P03 Operational Alert Families`
5. `R26 P03 Raw Alert Conditions`

Rename for this visual:

```text
Monitoring status
Remitted to date
Cumulative shortfall
Operational alert families
Raw alert conditions
```

Formats:

- Remitted to date → `$#,0.00`
- Cumulative shortfall → `$#,0.00`
- families → `0`
- raw conditions → `0`

### 8E. Subtitle

Use:

`R26 P03 Account Performance Subtitle`

Funded case:

> Funded synthetic account • deterministic synthetic-forward

Non-funded case:

> No funded-account lifecycle for this application-scenario

If dynamic subtitles are awkward in your Desktop version, use a tiny borderless card immediately beneath the heading.

### 8F. Expected behavior

For an authorized/funded path:

**chart populated**

For REVIEW, decline, or otherwise non-funded path:

**chart blank**

That blank is meaningful and correct.

Do **not** substitute proposed-structure data into this chart.

---

# 9. Account performance alt text

We did not create a dedicated measure in the first batch, so I would add one now:

```DAX
R26 P03 Account Performance Alt Text =
IF (
    [R26 P03 Funded Lifecycle Available] <> 1,
    "No funded-account performance lifecycle is available for the selected application and scenario.",
    "Account performance for the selected funded application and scenario, showing remaining receivable and remittance pace across the deterministic synthetic-forward lifecycle."
)
```

Then:

**Select chart → Format visual → General → Alt text → fx → Field value → `R26 P03 Account Performance Alt Text`.**

---

# 10. Monitoring journey — expand to the full status hierarchy

Your current chart displays only:

```text
Severe shortfall
Underperforming
Watch
Current
Paid off
```

We need the complete hierarchy:

```text
5  Dormant / no remittance
4  Severe shortfall
3  Underperforming
2  Watch
1  Current
0  Paid off
```

### 10A. X-axis

Use:

`R1FactDailyMonitoring[monitoring_date]`

### 10B. Y-axis

Use:

`R26 P03 Monitoring Status Rank`

### 10C. Axis range

Go to:

**Format visual → Y-axis → Range**

Set:

- Minimum = `0`
- Maximum = `5`

### 10D. Add Dormant / no remittance

Your existing labels appear to be manually positioned against the status levels.

Add:

> Dormant / no remittance

at level `5`.

Then align:

```text
5 Dormant / no remittance
4 Severe shortfall
3 Underperforming
2 Watch
1 Current
0 Paid off
```

If adding level 5 requires a modest vertical increase to the visual, do it. We have enough room after tightening the proposed-structure section.

### 10E. Tooltips

Use:

1. `R26 P03 Monitoring Status Display`
2. `R26 P03 Remaining Receivable`
3. `R26 P03 Remittance Pace`
4. `R26 P03 Operational Alert Families`
5. `R26 P03 Raw Alert Conditions`

Rename:

```text
Monitoring status
Remaining receivable
Remittance pace
Operational alert families
Raw alert conditions
```

This is a **single-account** page, so raw alert conditions are useful here.

### 10F. Do not use P02 portfolio measures

Do not put:

- Accounts with operational alerts
- Accounts in adverse monitoring status

on P03.

Those are portfolio/account-population measures.

P03 should tell us:

> **What happened to this specific funded account?**

---

# 11. Monitoring journey subtitle

Use:

`R26 P03 Monitoring Journey Subtitle`

Funded:

> Governed monitoring status across the funded-account lifecycle

Non-funded:

> No funded-account monitoring path for this application-scenario

Again, use a tiny borderless card if dynamic subtitle support is inconvenient.

---

# 12. Monitoring journey alt text

Create:

```DAX
R26 P03 Monitoring Journey Alt Text =
IF (
    [R26 P03 Funded Lifecycle Available] <> 1,
    "No funded-account monitoring journey is available for the selected application and scenario.",
    "Monitoring journey for the selected funded application and scenario, showing governed daily monitoring status from current through watch, underperforming, severe shortfall, dormant or no remittance, and paid off where applicable."
)
```

Bind it through:

**General → Alt text → fx → Field value.**

---

# 13. Servicing & intervention — rebase the row

Keep the heading:

> **Servicing & intervention**

Keep the five-column layout.

Remove the legacy fields.

Add:

| Measure | Rename |
|---|---|
| `R26 P03 Intervention Display` | Intervention |
| `R26 P03 Servicing Action Display` | Action |
| `R26 P03 Servicing Queue Display` | Queue |
| `R26 P03 Intervention Exposure` | Exposure |
| `R26 P03 Intervention Reason Display` | Reason |

Format Exposure:

`$#,0.00`

### Expected behavior

Funded path with closed lifecycle might show:

```text
No further action | No action — closed | Closed | $0.00 | Paid off
```

An active servicing case could show an outreach/review action.

A non-funded REVIEW/decline path should show **no row**.

That is correct.

Do not turn a blank servicing block into:

`No action`

because that would falsely imply an account existed and servicing evaluated it.

---

# 14. Servicing & intervention alt text

Use the measure already created:

`R26 P03 Servicing Alt Text`

Bind:

**General → Alt text → fx → Field value → `R26 P03 Servicing Alt Text`.**

---

# 15. Funding date — leave it out for now

This is deliberate.

We learned from `000002 / Recession Energy` that the legacy funding-date field can populate on a REVIEW path that has no funded lifecycle.

Therefore:

**remove Funding date from Proposed structure and do not replace it yet.**

Once everything else is stable, we'll identify the exact successor activation field and create a measure that can only return a date when the application/scenario actually crossed the governed funding boundary.

This is safer than retaining a misleading date merely to fill the sixth column.

And aesthetically, a five-column Proposed structure actually gives us more room for the new **Payback multiple** comparison.

---

# 16. Footer identity row

Do not manually recreate the identity row.

Copy the already-correct identity row from frozen P02.

Replace P03's stale:

```text
Source release: MSBF_PBI_SOURCE_SELECTION_R3_20260816
Model version:  PBI_A1A_MODEL_R1_20260818
```

with the current R26 identity:

```text
Run:                    M1_V0_2_BASELINE_BUILD
Source release:         Module 2 / G3 v2.1.0-rc2
Model version:          PBI_R26_PARALLEL_REFINEMENT_C1_20260902
Observed-source cutoff: 2026-07-23
```

---

# 17. P03 temporal boundary

Replace the current old boundary completely.

Use:

> **Temporal boundary:** Decision and proposed-structure evidence is fixed at the 2026-07-23 source snapshot. Funded-account lifecycle evidence is deterministic synthetic-forward through 2026-11-22.

This distinguishes the two clocks on the page:

**fixed application decision evidence** versus **forward lifecycle evidence**.

---

# 18. P03 interpretation boundary

Use:

> **Interpretation boundary:** Synthetic decision and lifecycle evidence; review or decline paths do not imply funding or account creation.

I particularly want this sentence retained because P03 uniquely exposes review candidates.

It protects the user from interpreting:

```text
REVIEW
+
Proposed structure
```

as:

```text
funded account
```

---

# 19. Visual interactions

After all fields are rebound:

Go to:

**Format ribbon → Edit interactions**

### Merchant slicer

Every substantive P03 object should show the **Filter** icon:

- Merchant request
- decision tile
<!-- END_SOURCE_MESSAGE -->


<a id="m-6df4a583-f0b8-4ae0-8c43-84094b166006"></a>
## Andrew / user · C109-M00695

C109-M00695 · 2026-09-02T14:22:41.389000-04:00 · active path

Preceding visible parent: [C109-M00694](part-32.md#m-f9b64aae-a6fc-4d21-a1bd-21beb4aab512)

<!-- BEGIN_SOURCE_MESSAGE -->
I'm not sure I need application in this version - since they all only have one application
<!-- END_SOURCE_MESSAGE -->


<a id="m-a7a55ee9-1236-419f-8c77-669adb148728"></a>
## Assistant · C109-M00696

C109-M00696 · 2026-09-02T14:22:49.857976-04:00 · active path

Preceding visible parent: [C109-M00695](part-32.md#m-6df4a583-f0b8-4ae0-8c43-84094b166006)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. If the current synthetic portfolio has **exactly one application per merchant**, showing `Application` on P03 is redundant and adds visual noise.

I would remove it from the **Merchant request** block.

That makes the request row:

**Applied | Requested | Use | Channel | Remittance | Payback | Payoff days | Repayment**

This is cleaner and puts more horizontal space into the economic fields that actually matter for the request-versus-proposed comparison.

I would also update the Merchant request alt text to:

> **Application request details for the selected merchant and scenario, including application date, requested amount, use, channel, remittance rate, requested payback multiple, requested payoff period, and requested repayment.**

No need to mention an application ID if the page does not display one and the merchant uniquely identifies the application in this portfolio.

The only caveat is future scalability: if later campaign-scale populations allow multiple applications per merchant, we would need either an Application slicer or some other application-selection control. For this current R26 page, though, removing it is the better design.
<!-- END_SOURCE_MESSAGE -->


<a id="m-be7b67ae-68f3-4c3a-ae46-d6f41d1581bb"></a>
## Andrew / user · C109-M00697

C109-M00697 · 2026-09-02T14:27:11.886000-04:00 · active path

Preceding visible parent: [C109-M00696](part-32.md#m-a7a55ee9-1236-419f-8c77-669adb148728)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: e711b070-0054-4b90-818b-1fe9e9fd005b.png

<!-- BEGIN_SOURCE_MESSAGE -->
DimApplicationScenario has requested payback multiple:
<!-- END_SOURCE_MESSAGE -->


<a id="m-3a568673-0dd6-4ede-a759-87ae7b9e7275"></a>
## Assistant · C109-M00698

C109-M00698 · 2026-09-02T14:27:19.869414-04:00 · active path

Preceding visible parent: [C109-M00697](part-32.md#m-be7b67ae-68f3-4c3a-ae46-d6f41d1581bb)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that is better. Since `DimApplicationScenario` already carries **requested payback multiple**, use that source directly rather than calculating it from requested amount and repayment.

For the **Merchant request** visual, I would now freeze the fields in this order:

**Applied | Requested | Use | Channel | Remittance | Payback multiple | Payoff days | Repayment**

Use `DimApplicationScenario[requested_payback_multiple]` for the new column and format it to **2 decimal places**.

That gives you a clean apples-to-apples comparison against the proposed/selected structure:

**Request:** amount, remittance, payback multiple, payoff days, repayment  
**Proposed structure:** amount, remittance, payback multiple, horizon days, repayment

For the example on screen, that is exactly what you want:

- Requested: **$6,500 | 13.09% | 1.16 | 60 | $7,519.99**
- Proposed: **$6,500 | 12.83% | 1.18 | 60 | $7,670.39**

So yes: **use the existing requested payback multiple field and do not create a separate calculated measure for it.**

One design note from the screenshot: the request row now looks materially better after removing `Application`. I would keep it that way.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e15dc8a3-1a59-467d-b0ac-b4667e7149bf"></a>
## Andrew / user · C109-M00699

C109-M00699 · 2026-09-02T14:30:41.890000-04:00 · active path

Preceding visible parent: [C109-M00698](part-32.md#m-3a568673-0dd6-4ede-a759-87ae7b9e7275)

<!-- BEGIN_SOURCE_MESSAGE -->
I do not understand the candidate search summary - please explain
<!-- END_SOURCE_MESSAGE -->


<a id="m-e5335e19-68c4-4ffa-a2f2-de5535efd346"></a>
## Assistant · C109-M00700

C109-M00700 · 2026-09-02T14:30:45.624611-04:00 · active path

Preceding visible parent: [C109-M00699](part-32.md#m-e15dc8a3-1a59-467d-b0ac-b4667e7149bf)

<!-- BEGIN_SOURCE_MESSAGE -->
The **Candidate Search Summary** is not another economic term like amount, remittance, or payback multiple. It is a compact explanation of **what the strategy engine had to do to arrive at the proposed structure**.

In R26, the strategy does not simply evaluate the merchant's requested structure and stop. If the requested terms do not satisfy the governed decision criteria but the application is eligible for structure remediation, the engine can search alternative structures. It evaluates candidate combinations and then selects from the appropriate governed frontier.

So for your `000002 / Recession Energy` example, the story is essentially:

**Merchant request**  
$6,500 | 13.09% | 1.16 | 60 days | $7,519.99

↓ requested structure does not satisfy the economic hurdle

**Candidate search**  
The strategy evaluates permissible alternative structures.

↓ identifies the preferred candidate under the governed selection rules

**Proposed structure**  
$6,500 | 12.83% | 1.18 | 60 days | $7,670.39

↓ but the candidate is not within automatic authorization authority

**Decision**  
`REVIEW — Counteroffer review`

That's what the candidate-search concept is telling us.

### What the `R26 P03 Candidate Search Summary` measure is for

We created it to expose a concise summary such as:

> **6 candidates evaluated • Review frontier**

or whatever the actual source-driven result is for that application/scenario.

It answers a different executive question:

**“How did the engine get from what the merchant requested to what we're proposing?”**

The proposed-structure table answers **what changed**.  
The candidate-search summary answers **how the strategy arrived there**.

### Do I think it belongs visibly on P03?

Looking at the page as it has developed, **I'm less convinced that it does.**

P03 already gives the user:

- the merchant's request;
- the governed decision;
- the proposed terms;
- operating evidence;
- underwriting/structure narrative;
- governed decision rationale;
- and, where funded, the entire downstream account lifecycle.

Putting something like `6 candidates evaluated • Review frontier` directly underneath Proposed structure introduces fairly technical strategy-engine terminology onto what is otherwise becoming a very intuitive business page.

And your `000002` example shows that a user can understand the story without it:

> Requested economics didn't clear the hurdle → an alternative structure was identified → that alternative requires review.

The **underwriting narrative and governed-decision narrative already explain why**.

### What I recommend now

**Do not add Candidate Search Summary as a visible card on P03.**

Keep `R26 P03 Candidate Search Summary` in the semantic model because it is useful evidence and can support accessibility/tooltips, but don't consume valuable visible space with it.

I would instead put it in the **tooltip for the Proposed structure visual**, if the tooltip works cleanly there. Then an interested analyst can hover and see something like:

> Candidate search: 6 candidates evaluated • Review frontier

while an executive simply sees the terms.

That gives us a good information hierarchy:

**Visible P03:** What was requested? What did we decide? What structure was proposed? Why? What happened afterward?

**Tooltip/detail:** How extensively did the governed structure-search engine search to reach that proposal?

And I would still rename **Selected structure → Proposed structure**. Your current `000002` case is probably the best demonstration we've seen of why that terminology is superior.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9f3dfcc6-fe20-4293-bd31-568ba5356dea"></a>
## Andrew / user · C109-M00701

C109-M00701 · 2026-09-02T14:32:21.343000-04:00 · active path

Preceding visible parent: [C109-M00700](part-32.md#m-e5335e19-68c4-4ffa-a2f2-de5535efd346)

<!-- BEGIN_SOURCE_MESSAGE -->
I see. That belongs with the narrative blocks. We currently have merchant operating evidence / structure assessment narrative and P03 Decision Readout - which we should adjust title naming to remove P03. This Candidate Search Summary should be incorporated into one of those or included as a fourth narrative block in that same section.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ecad0751-4f70-4c55-aea7-f593f2d6e806"></a>
## Assistant · C109-M00702

C109-M00702 · 2026-09-02T14:32:24.923496-04:00 · active path

Preceding visible parent: [C109-M00701](part-32.md#m-9f3dfcc6-fe20-4293-bd31-568ba5356dea)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I agree with that information architecture. **Candidate Search Summary belongs in the analytical narrative section, not underneath the Proposed structure terms.** The terms should remain a clean request-versus-proposal comparison.

I would also clean up all three existing narrative titles now. My preferred final narrative stack is:

| Current | Recommended |
|---|---|
| Merchant operating evidence | **Merchant operating evidence** |
| Structure assessment narrative | **Underwriting & structure assessment** |
| P03 Decision Readout | **Governed decision rationale** |
| New | **Structure search** |

### Where Candidate Search Summary belongs

I recommend making it a **fourth narrative block: `Structure search`**, rather than embedding it in another narrative.

There is a useful separation of analytical questions:

**Merchant operating evidence**  
“What do we know about this merchant's operating behavior and evidence quality?”

**Underwriting & structure assessment**  
“What do capacity, risk, loss and economics tell us about the requested structure?”

**Structure search**  
“If the requested structure wasn't the final answer, what did the governed alternative-structure search do?”

**Governed decision rationale**  
“What did the strategy ultimately decide, and why?”

That creates a strong analytical progression:

**Evidence → Assessment → Search → Decision**

For an approved-as-requested application, Structure search can simply indicate that no alternative search was required. For a counteroffer case, it becomes much more informative.

### I would not use only the terse Candidate Search Summary if we can avoid it

If the existing `R26 P03 Candidate Search Summary` returns something terse like:

> 6 candidates evaluated • Review frontier

that is useful, but visually it may look underdeveloped beside your substantive narrative blocks.

I would create a presentation measure specifically for this fourth block, **using only already-governed/source-derived search outputs**. For example, the visible result could read conceptually:

> **Alternative structure search evaluated 6 candidates. The selected candidate was identified on the review frontier and requires manual authorization.**

For an automatic counteroffer:

> **Alternative structure search evaluated 8 candidates. The selected candidate satisfied the governed authorization frontier.**

For approved-as-requested:

> **The requested structure satisfied the governed decision requirements; alternative structure search was not required.**

And for a terminal decline/no feasible structure, the wording should accurately distinguish whether search was inapplicable versus search occurred but found no feasible candidate.

We should **not invent that logic from the final decision label**, though. The presentation measure should be assembled only from the R26 search/candidate fields we have already loaded. We can inspect `R26 P03 Candidate Search Summary` and its underlying measures before deciding whether it already does enough.

### Layout

I would place the four blocks vertically where your existing three narratives are now:

**Merchant operating evidence**  
[narrative]

**Underwriting & structure assessment**  
[narrative]

**Structure search**  
[shorter narrative]

**Governed decision rationale**  
[narrative]

The Structure search block will generally be shorter, so we shouldn't allocate it equal height. Think of it as a compact bridge between assessment and decision.

I also prefer **Governed decision rationale** over my earlier suggestion of just `Governed decision`. You already have the prominent colored decision tile showing the actual decision. Calling the narrative `Governed decision` partially duplicates that. `Governed decision rationale` tells the user precisely why the text exists.

So I would freeze the narrative architecture as:

**Merchant operating evidence → Underwriting & structure assessment → Structure search → Governed decision rationale.**

And yes, absolutely remove `P03` from the visible page terminology. Page IDs belong in our internal model/evidence controls, not in the executive-facing report.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e81cc52e-eced-4377-9388-99c0fdfc9b0a"></a>
## Andrew / user · C109-M00703

C109-M00703 · 2026-09-02T14:34:47.918000-04:00 · active path

Preceding visible parent: [C109-M00702](part-32.md#m-ecad0751-4f70-4c55-aea7-f593f2d6e806)

<!-- BEGIN_SOURCE_MESSAGE -->
it seems like we have 3 blocks all discussing structure. - the assessment and decision both discuss structure
<!-- END_SOURCE_MESSAGE -->


<a id="m-3741c0c0-b615-4347-95fb-9682d9380c4b"></a>
## Assistant · C109-M00704

C109-M00704 · 2026-09-02T14:34:51.068596-04:00 · active path

Preceding visible parent: [C109-M00703](part-32.md#m-e81cc52e-eced-4377-9388-99c0fdfc9b0a)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree. **Four narrative blocks is too much, and three of them would be explaining overlapping pieces of the same underwriting/structure decision.** That would make P03 feel more like an audit workpaper than an executive application journey.

The better answer is **three narrative blocks total**, but reorganized around genuinely different questions:

1. **Merchant operating evidence**  
   Keep this distinct. It answers: *What did we observe about the merchant?*  
   This is evidence, not strategy interpretation.

2. **Decision assessment**  
   Rename the current **Structure assessment narrative** to this. It answers: *How did the strategy evaluate the request?*  
   This is where capacity, obligations, liquidity, risk tier, expected loss, risk-adjusted contribution, economic hurdle, etc. belong.

3. **Decision rationale**  
   Rename `P03 Decision Readout` to this. It answers: *What did we ultimately do and why?*  
   This is also where the **candidate-search result belongs when alternative structure search was relevant**.

That gives us a much cleaner progression:

**Evidence → Assessment → Decision**

### Where Candidate Search Summary goes

I would **incorporate it into Decision rationale**, not create a fourth block.

For your current example, the two existing pieces effectively say:

**Assessment:**
> At the requested structure, the governed capacity assessment was marginal... Comparative expected loss was 6.11%. Risk-adjusted contribution was $140 (13.1% annualized), below the governed hurdle.

**Decision:**
> The requested structure did not meet the governed economic hurdle. An alternative structure was identified, but it requires manual authorization.

The candidate-search information naturally extends the second statement:

> The requested structure did not meet the governed economic hurdle. Alternative structure search evaluated [X] candidates; the selected proposal was identified on the review frontier and requires manual authorization.

Now the three blocks have **non-overlapping jobs**.

### I would also avoid the word "structure" in all three headings

That's part of what is making the current design feel repetitive.

Freeze these visible headings:

**Merchant operating evidence**  
**Decision assessment**  
**Decision rationale**

Then let the content discuss structure where structure is substantively relevant.

And above those, the separate **Proposed structure** table shows the actual terms.

So the whole center-column story becomes:

**Merchant request** → what they asked for  
**Proposed structure** → what the strategy proposes, if different/applicable  
**Merchant operating evidence** → underlying merchant evidence  
**Decision assessment** → analytical evaluation  
**Decision rationale** → resulting decision, including alternative-search outcome when applicable

That is substantially cleaner. I would use this architecture rather than adding a fourth narrative block.
<!-- END_SOURCE_MESSAGE -->


<a id="m-59a478c8-5ad3-490f-a690-5dbd053ca759"></a>
## Andrew / user · C109-M00705

C109-M00705 · 2026-09-02T14:36:03.356000-04:00 · active path

Preceding visible parent: [C109-M00704](part-32.md#m-3741c0c0-b615-4347-95fb-9682d9380c4b)

<!-- BEGIN_SOURCE_MESSAGE -->
The titles of those blocks have Decision twice - I do not like. Otherwise, I like where this is heading.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c1ba565c-b99e-47f0-b3e6-638aef44b40e"></a>
## Assistant · C109-M00706

C109-M00706 · 2026-09-02T14:36:07.321957-04:00 · active path

Preceding visible parent: [C109-M00705](part-32.md#m-59a478c8-5ad3-490f-a690-5dbd053ca759)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. **Decision assessment → Decision rationale** sounds repetitive and makes the page feel process-heavy.

I would change the three-block architecture to:

### 1. Merchant operating evidence
Keep exactly as-is.

**Question answered:** What do we know about the merchant?

Contains operating pattern, sales behavior, balance behavior, NSF/negative-balance evidence, processor continuity, evidence quality/completeness, etc.

### 2. Risk & economics assessment
This is my preferred replacement for **Structure assessment narrative**.

**Question answered:** How did the requested terms perform analytically?

This is where the existing narrative's:
- capacity / cash-flow coverage,
- modeled obligations,
- liquidity buffer,
- integrated risk,
- comparative expected loss,
- risk-adjusted contribution,
- economic hurdle

belong.

Importantly, the heading no longer overemphasizes "structure." The narrative can still say *“At the requested structure…”* because that's analytically correct.

### 3. Recommendation rationale
This replaces **P03 Decision Readout** and absorbs the Candidate Search Summary.

**Question answered:** Given the assessment, what does the strategy recommend and how did it get there?

For your `000002 / Recession Energy` case, this is where we'd combine:

> The requested structure did not meet the governed economic hurdle. An alternative structure was identified, but it requires manual authorization.

with the relevant candidate-search result.

That produces a very clean hierarchy:

**Merchant operating evidence**  
↓  
**Risk & economics assessment**  
↓  
**Recommendation rationale**

And the colored tile above still supplies the formal governed outcome:

**REVIEW — Counteroffer review**

So we don't need another narrative heading saying "Decision." In fact, **Recommendation rationale** is better precisely because a REVIEW outcome is not itself an authorized final offer—the strategy is recommending a proposed alternative for review.

The overall P03 story then becomes:

**Merchant request** → what was requested  
**Proposed structure** → alternative terms identified, where applicable  
**REVIEW / AUTHORIZED / DECLINED tile** → governed disposition  
**Merchant operating evidence** → what we observed  
**Risk & economics assessment** → what the analysis showed  
**Recommendation rationale** → why this disposition/proposal resulted, including candidate search where relevant  
**Account performance → Monitoring journey → Servicing & intervention** → what happened afterward, only when a funded account exists

I think **Merchant operating evidence / Risk & economics assessment / Recommendation rationale** is the strongest naming set we've arrived at.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0bebe91b-c1b0-4e21-a36f-37c1d7416c72"></a>
## Andrew / user · C109-M00707

C109-M00707 · 2026-09-02T14:38:12.136000-04:00 · active path

Preceding visible parent: [C109-M00706](part-32.md#m-c1ba565c-b99e-47f0-b3e6-638aef44b40e)

<!-- BEGIN_SOURCE_MESSAGE -->
Recommendation rationale is a mouth full. I think Recommendation by itself is stronger.
<!-- END_SOURCE_MESSAGE -->


<a id="m-94d739dd-c2cb-44e7-9a09-aa53b4753814"></a>
## Assistant · C109-M00708

C109-M00708 · 2026-09-02T14:38:16.186210-04:00 · active path

Preceding visible parent: [C109-M00707](part-32.md#m-0bebe91b-c1b0-4e21-a36f-37c1d7416c72)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. **Recommendation** is stronger.

It is shorter, more executive, and the content underneath already provides the rationale—there is no need for the heading to say so.

I would freeze the three narrative headings as:

**Merchant operating evidence**  
**Risk & economics assessment**  
**Recommendation**

That gives P03 a very natural progression:

**Evidence → Assessment → Recommendation**

And it avoids repeating either *decision* or *structure* across the section.

For the `000002 / Recession Energy` example, **Recommendation** can contain the existing source-owned decision narrative plus the concise candidate-search context where relevant. That is exactly where the user should learn: the requested terms failed the economic hurdle, alternative structures were searched, a proposal was identified, and it requires manual authorization.

I think we've landed on the right naming architecture.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0f3895d9-2a21-4ba9-86b5-214fcfdd4223"></a>
## Andrew / user · C109-M00709

C109-M00709 · 2026-09-02T14:39:35.670000-04:00 · active path

Preceding visible parent: [C109-M00708](part-32.md#m-94d739dd-c2cb-44e7-9a09-aa53b4753814)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 93fc2305-9085-42a2-bf19-2f5c120b9532.png

<!-- BEGIN_SOURCE_MESSAGE -->
ok, going back to Proposed structure table - what to do about the funding date column? remove it entirely? here is what I currently have. also what is the alt text? help me finish this table.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2499572a-003f-40cf-a2bd-b917d066cb1c"></a>
## Assistant · C109-M00710

C109-M00710 · 2026-09-02T14:39:39.415259-04:00 · active path

Preceding visible parent: [C109-M00709](part-32.md#m-0f3895d9-2a21-4ba9-86b5-214fcfdd4223)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **Remove Funding date entirely from `Proposed structure`.** The `000002 / Recession Energy` case demonstrated why: this is a **REVIEW / Counteroffer review** path, so the proposed structure exists, but it has not crossed the authorization/funding boundary. A funding date in this table falsely makes the proposal look consummated.

I would finish the table as follows.

### 1. Final visible columns

Use exactly these five:

| Amount | Remittance | Payback multiple | Horizon days | Repayment |
|---|---:|---:|---:|---:|
| $6,500.00 | 12.83% | 1.18 | 60 | $7,670.39 |

This is especially strong because it now mirrors the economic fields in **Merchant request**:

**Requested:** Requested | Remittance | Payback multiple | Payoff days | Repayment  
**Proposed:** Amount | Remittance | Payback multiple | Horizon days | Repayment

I would **not replace Funding date with another sixth field**. The five-column table is analytically complete and cleaner.

### 2. Remove Funding date

1. Select the **Proposed structure** table.
2. Open **Build visual**.
3. Under **Columns**, find `Funding date`.
4. Click its **X**.
5. Do not delete its underlying field/measure from the semantic model—we are only removing it from this visual.
6. Resize/reposition the remaining five columns to use the available width.

### 3. Final formatting

I recommend:

- **Amount:** `$#,0.00`
- **Remittance:** `0.00%`
- **Payback multiple:** `0.00`
- **Horizon days:** whole number
- **Repayment:** `$#,0.00`

Keep the heading **Proposed structure**.

For the column labels, I'd keep exactly:

`Amount | Remittance | Payback multiple | Horizon days | Repayment`

Do not change `Horizon days` to `Payoff days`. The slight distinction is useful: **Payoff days** is what the merchant requested; **Horizon days** is the term selected by the strategy.

### 4. Important blank behavior

For an application where no proposed structure exists, the visual should **not manufacture zeros**.

Prefer:

- no proposed structure → blank/no row;
- proposed REVIEW structure → show proposed economics;
- authorized/funded structure → show economics;
- decline/no-feasible-structure → blank.

That's the right semantic behavior.

### 5. Alt text

I would make this dynamic rather than use generic static text.

You already have the R26 proposed/selected-structure measures. Create or update the measure as:

```DAX
R26 P03 Proposed Structure Alt Text =
VAR _Amount =
    [R26 P03 Selected Structure Amount]
RETURN
    IF (
        ISBLANK ( _Amount ),
        "No proposed structure is available for the selected merchant and scenario.",
        "Proposed structure for the selected merchant and scenario: amount "
            & FORMAT ( _Amount, "$#,0.00" )
            & ", remittance rate "
            & FORMAT ( [R26 P03 Selected Remittance Rate], "0.00%" )
            & ", payback multiple "
            & FORMAT ( [R26 P03 Selected Payback Multiple], "0.00" )
            & ", horizon "
            & FORMAT ( [R26 P03 Selected Horizon Days], "0" )
            & " days, and repayment "
            & FORMAT ( [R26 P03 Selected Total Repayment], "$#,0.00" )
            & "."
    )
```

Notice that I am **not putting Candidate Search Summary into this alt text anymore**. We have now decided that search belongs analytically with **Recommendation**, not with the terms table. Accessibility should follow that same information architecture.

### 6. Attach the alt text

1. Select the **Proposed structure** table.
2. Open **Format visual**.
3. Select **General**.
4. Expand **Alt text**.
5. Click **fx**.
6. **Format style** → `Field value`.
7. **What field should we base this on?** → `R26 P03 Proposed Structure Alt Text`.
8. Click **OK**.

### 7. One thing I would *not* do

Don't put a note underneath saying something like *“Proposed structure does not imply funding.”* We already have the page-level interpretation boundary for that purpose, and the REVIEW tile plus blank lifecycle makes the distinction visually clear. Adding another warning here would clutter an otherwise very clean comparison.

So I would freeze this component as:

**Proposed structure**  
**Amount | Remittance | Payback multiple | Horizon days | Repayment**

with dynamic alt text and **no Funding date**.

That is now a much stronger component than the original `Funded terms` table.
<!-- END_SOURCE_MESSAGE -->


<a id="m-caccb553-09cc-4ffd-91f0-39bfc07ecb5c"></a>
## Andrew / user · C109-M00711

C109-M00711 · 2026-09-02T14:40:53.245000-04:00 · active path

Preceding visible parent: [C109-M00710](part-32.md#m-2499572a-003f-40cf-a2bd-b917d066cb1c)

<!-- BEGIN_SOURCE_MESSAGE -->
what if we keep funding date but only populate if it is AUTHORIZED
<!-- END_SOURCE_MESSAGE -->


<a id="m-d35f3740-f45c-4d50-b7f5-4c6c57ee4d4c"></a>
## Assistant · C109-M00712

C109-M00712 · 2026-09-02T14:40:56.214854-04:00 · active path

Preceding visible parent: [C109-M00711](part-32.md#m-caccb553-09cc-4ffd-91f0-39bfc07ecb5c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **I prefer that to removing Funding date entirely**, provided we make it semantically strict.

It actually improves the table because Funding date then communicates whether the proposal crossed the authorization/funding boundary:

- **REVIEW / Counteroffer review** → Funding date = `--`
- **DECLINED** → Funding date = `--`
- **AUTHORIZED but not actually funded** → this is the important nuance: it should still be `--`
- **AUTHORIZED and funded/activated** → actual funding date

So I would not technically define it as **“populate if AUTHORIZED.”** I would define it as **“populate only when the selected application/scenario has an actual governed funding/activation record.”** Authorization is necessary, but funding is the event the date claims occurred.

That is safer and more precise.

### How I would implement it

Keep the sixth column:

**Amount | Remittance | Payback multiple | Horizon days | Repayment | Funding date**

But replace the current raw Funding date with a controlled measure.

First, we need to identify the exact source behind the existing `Funding date` value, because I don't want to guess its table/column after what we just discovered with the REVIEW case.

Do this:

1. Select the **Proposed structure** table.
2. Go to **Build visual**.
3. Find `Funding date` under Columns.
4. Hover over it.
5. Send me the tooltip showing the exact table/field, just like you did for Industry.

Then we'll build something conceptually like:

```DAX
R26 P03 Funding Date =
IF (
    [R26 P03 Funded Lifecycle Available] = 1,
    <exact funding-date expression>,
    BLANK ()
)
```

That `[R26 P03 Funded Lifecycle Available]` control is important. It already represents whether this application/scenario actually has a funded lifecycle. We should not infer funding merely from the decision label.

### What this does to your `000002 / Recession Energy` example

It should become:

| Amount | Remittance | Payback multiple | Horizon days | Repayment | Funding date |
|---|---:|---:|---:|---:|---|
| $6,500.00 | 12.83% | 1.18 | 60 | $7,670.39 | -- |

That is excellent storytelling:

**REVIEW — Counteroffer review**

yet

**Proposed structure:** fully populated

and

**Funding date:** `--`

The user can immediately understand that a proposal exists, but it hasn't become a funded account.

For an actually funded application, Funding date would populate.

### Alt text changes slightly

If we retain Funding date, I would also include its state dynamically:

> “Proposed structure for the selected merchant and scenario: amount $6,500.00, remittance rate 12.83%, payback multiple 1.18, horizon 60 days, repayment $7,670.39. The proposed structure has not been funded.”

For a funded path:

> “…repayment $14,179.50. Funding date July 25, 2026.”

That is better accessibility than simply omitting the date because it explicitly distinguishes **proposal** from **funding**.

So yes — **keep Funding date**, but make it a controlled funded-event field. I think that gives P03 more information with essentially no added visual complexity.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1149e19d-8a6a-40d9-a47b-721d8273799d"></a>
## Andrew / user · C109-M00713

C109-M00713 · 2026-09-02T14:41:29.969000-04:00 · active path

Preceding visible parent: [C109-M00712](part-32.md#m-d35f3740-f45c-4d50-b7f5-4c6c57ee4d4c)

<!-- BEGIN_SOURCE_MESSAGE -->
do we have AUTHORIZED but not funded? i'm not sure that exists in the population
<!-- END_SOURCE_MESSAGE -->


<a id="m-b3508afb-9260-46ba-a169-a0894a7b8767"></a>
## Assistant · C109-M00714

C109-M00714 · 2026-09-02T14:41:33.944414-04:00 · active path

Preceding visible parent: [C109-M00713](part-32.md#m-1149e19d-8a6a-40d9-a47b-721d8273799d)

<!-- BEGIN_SOURCE_MESSAGE -->
I don't think we should assume that distinction exists in this R26 population.

From what we've seen on P03, the operative lifecycle appears more likely to be:

**AUTHORIZED → funded/activated**  
**REVIEW → proposed structure may exist, but not funded**  
**DECLINED / no feasible structure / hard stop → not funded**

So my previous warning about an **AUTHORIZED-but-not-funded** state may be unnecessarily theoretical for this portfolio.

More importantly, we don't need to design around a hypothetical state. We can verify it directly from the model. If R26 has **zero AUTHORIZED paths without funding/activation**, then the clean P03 rule can simply be:

> **Funding date displays for AUTHORIZED paths and is blank for REVIEW/DECLINED paths.**

And that would make the six-column Proposed structure table excellent.

Before we build the measure, I recommend we run one very small DAX diagnostic against the current model to answer exactly this:

```text
Decision class    Paths    Funded    Not funded
AUTHORIZED
REVIEW
DECLINED
```

Particularly, we want:

```text
AUTHORIZED AND no funding/activation = ?
```

If that's **0**, we can stop worrying about the distinction and implement the simpler rule consistent with the actual R26 population.

Given how tightly governed this work has become, I'd rather verify that one population fact than add complexity to P03 for a state that may not exist.
<!-- END_SOURCE_MESSAGE -->


<a id="m-da7c391a-d7fc-4cae-acb0-6b873077c4ed"></a>
## Andrew / user · C109-M00715

C109-M00715 · 2026-09-02T14:42:24.971000-04:00 · active path

Preceding visible parent: [C109-M00714](part-32.md#m-b3508afb-9260-46ba-a169-a0894a7b8767)

<!-- BEGIN_SOURCE_MESSAGE -->
make a simple rule here - authorized - populate. else do not.
<!-- END_SOURCE_MESSAGE -->


<a id="m-52783a3c-a57a-436c-acb3-c6e46fd0a28f"></a>
## Assistant · C109-M00716

C109-M00716 · 2026-09-02T14:42:28.669052-04:00 · active path

Preceding visible parent: [C109-M00715](part-32.md#m-da7c391a-d7fc-4cae-acb0-6b873077c4ed)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. Keep it simple:

> **AUTHORIZED → show Funding date**  
> **Anything else → blank**

Use the existing governed decision-class measure rather than trying to infer authorization from funding records.

Assuming the measure we established is `R26 P03 Decision Class`, create:

```DAX
R26 P03 Funding Date Display =
IF (
    [R26 P03 Decision Class] = "AUTHORIZED",
    SELECTEDVALUE ( 'YourCurrentFundingDateTable'[funding_date] ),
    BLANK ()
)
```

The only piece we need to replace is `'YourCurrentFundingDateTable'[funding_date]` with the **exact existing field currently producing `7/25/2026`**. Hover over the current `Funding date` field in the Proposed structure visual and give me that table/field name.

Then the behavior is straightforward:

| Decision | Proposed structure | Funding date |
|---|---|---|
| AUTHORIZED | Populate | **Populate** |
| REVIEW | Populate if proposal exists | **--** |
| DECLINED | As applicable | **--** |

For your current `000002 / Recession Energy` example, the economics remain visible because they describe the **proposed structure**, while the erroneous `7/25/2026` disappears because the disposition is REVIEW.

I would keep **Funding date as the sixth column**. With this rule, it adds useful information rather than ambiguity.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9645669a-a0c3-4941-8b22-77ba884452c7"></a>
## Andrew / user · C109-M00717

C109-M00717 · 2026-09-02T14:53:18.405000-04:00 · active path

Preceding visible parent: [C109-M00716](part-32.md#m-52783a3c-a57a-436c-acb3-c6e46fd0a28f)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: f7b55236-62dd-40f1-b1d7-38a169dceeef.png

<!-- BEGIN_SOURCE_MESSAGE -->
Approved as requ gets cut off - Preferably, this should wrap (which we do have wrap on, but it is not wrapping) - I do have room to expand on this card height just a bit - but we need to solve this.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9907ad91-aa8a-464d-99ce-fb94bdda3f02"></a>
## Assistant · C109-M00718

C109-M00718 · 2026-09-02T14:53:36.674041-04:00 · alternate branch

Preceding visible parent: [C109-M00717](part-32.md#m-9645669a-a0c3-4941-8b22-77ba884452c7)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — this is fixable, and I would **not shrink the text** unless we have to. The problem is that Power BI's card visual often does **not wrap category/reference labels predictably**, even when Text wrap is enabled.

The cleanest solution is to make the lower line a **separate text/card element** instead of relying on the same card to wrap it.

For this decision tile, I would do this:

1. Keep the top card/value as `AUTHORIZED`.
2. Keep its green background and current sizing.
3. Remove the lower `Approved as requ...` field from that card.
4. Add a **second small card** directly beneath it using `R26 P03 Decision Label`.
5. Turn **Category label = Off** on that second card.
6. Turn **Text wrap = On**.
7. Set the value font to about **9–10 pt bold**.
8. Increase the total tile height slightly, as you said you have room.
9. Match the second card's background to the same dynamic decision-tile background so the two cards visually read as one object.
10. Remove borders/shadows between the two cards and align their left/right edges exactly.

Then `Approved as requested` should be able to display as:

**Approved as**  
**requested**

or, depending on width:

**Approved as requested**

The same structure will also work cleanly for:

- `Counteroffer authorized`
- `Counteroffer review`
- `Underwriting review`
- `Evidence decline`
- `No feasible structure`
- `Policy hard stop`

I would **not** widen the tile substantially, because the current width works well with the surrounding request/proposed-structure layout.

One important accessibility point: once you split the tile into two physical cards, keep the full dynamic `R26 P03 Decision Tile Alt Text` on the **top/primary card**. For the lower decision-label card, either remove it from the tab order if possible or leave its alt text blank so a screen reader does not announce the same governed decision twice.

So visually, treat it as one decision tile, but physically build it as **two stacked cards**. That is the most reliable Power BI solution here.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bad3fb09-1a20-4925-84ff-46f24d9eeadd"></a>
## Assistant · C109-M00719

C109-M00719 · 2026-09-02T14:53:38.057544-04:00 · active path

Preceding visible parent: [C109-M00717](part-32.md#m-9645669a-a0c3-4941-8b22-77ba884452c7)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — this is solvable, and I would **not reduce the font first**. Since you have a little vertical room, the better fix is to make the **decision label card taller and narrower enough to force a clean two-line wrap**, while keeping `AUTHORIZED` visually dominant.

What is happening now is that Power BI’s card text wrap is enabled, but the value is still being rendered as a single line because the visual’s internal text container is not tall/wide enough in the way the card layout expects.

For the **lower decision-label card** (`Approved as requested`), do this:

1. Select only the lower card that contains `Approved as requ...`.
2. Go to **Format visual**.
3. Stay on the **Visual** tab.
4. Under **Apply settings to**, make sure you are formatting the value/card for the decision label, not the `AUTHORIZED` card.
5. Expand **Layout**.
6. Increase the card/visual height by roughly **12–20 pixels** first. You have room, so this is preferable to shrinking the text.
7. Expand **Value**.
8. Confirm **Text wrap = On**.
9. Keep **Horizontal alignment = Center**.
10. If there is a **Vertical alignment** option, set it to **Middle**.
11. Keep the font at its current size initially.

Then test. Ideally it should become:

```text
Approved as
requested
```

That is what I want visually.

If Power BI still refuses to wrap after increasing the height, I would stop relying on automatic wrapping and make the line break explicit in the measure. That is the most reliable solution.

If your current lower-card measure is something like:

`R26 P03 Decision Label`

create a display version:

```DAX
R26 P03 Decision Label Display =
VAR _Label = [R26 P03 Decision Label]
RETURN
    SWITCH (
        _Label,
        "Approved as requested",
            "Approved as" & UNICHAR ( 10 ) & "requested",
        "Counteroffer authorized",
            "Counteroffer" & UNICHAR ( 10 ) & "authorized",
        "Counteroffer review",
            "Counteroffer" & UNICHAR ( 10 ) & "review",
        "Underwriting review",
            "Underwriting" & UNICHAR ( 10 ) & "review",
        "Evidence decline",
            "Evidence" & UNICHAR ( 10 ) & "decline",
        "No feasible structure",
            "No feasible" & UNICHAR ( 10 ) & "structure",
        "Policy hard stop",
            "Policy hard" & UNICHAR ( 10 ) & "stop",
        _Label
    )
```

Then replace the lower card’s current field with `R26 P03 Decision Label Display`.

That gives you controlled wrapping for **every possible decision label**, not just `Approved as requested`.

I actually prefer the explicit-line-break version for this tile because the decision taxonomy is fixed and we know exactly how we want each phrase to render. It prevents ugly truncation as you switch merchants/scenarios.

Keep `AUTHORIZED` on the upper card exactly as-is. The lower card should become a clean two-line descriptor beneath it.
<!-- END_SOURCE_MESSAGE -->
