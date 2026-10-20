# MSBF - Power BI Executive Portfolio Intelligence Part 3

Part 06 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-05.md)
[Next part](part-07.md)

<a id="m-538eb794-c161-446d-8a71-7899ec761cba"></a>
## Assistant · C118-M00095

C118-M00095 · 2026-09-03T23:01:57.415437-04:00 · active path

Preceding visible parent: [C118-M00094](part-05.md#m-4f97dcde-cfda-48e6-9c8e-8e4c81963e72)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct — I should have provided it.

Create a second calculated column on `DimServicingQueue` for the full business-facing wording:

```DAX
P04 Servicing Queue Full Label =
VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                'DimServicingQueue'[servicing_queue_code],
                ""
            )
        )
    )
VAR _Fallback =
    SUBSTITUTE ( LOWER ( _Value ), "_", " " )
RETURN
    SWITCH (
        _Value,
        "", BLANK (),
        "NO_SERVICING_REQUIRED", "No servicing required",
        "ACTIVE_REASSESSMENT", "Active reassessment",
        "GOVERNANCE_REVIEW_HOLD", "Governance review hold",
        UPPER ( LEFT ( _Fallback, 1 ) )
            & MID ( _Fallback, 2, LEN ( _Fallback ) )
    )
```

Then use the two columns for different purposes:

- **Y-axis:** `DimServicingQueue[P04 Servicing Queue Label]`
  - No servicing
  - Reassessment
  - Review hold

- **Tooltip:** `DimServicingQueue[P04 Servicing Queue Full Label]`
  - No servicing required
  - Active reassessment
  - Governance review hold

That keeps the axis compact while preserving the full operational meaning on hover.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0becfdc2-862c-4ff9-8ec5-69385f62627c"></a>
## Andrew / user · C118-M00096

C118-M00096 · 2026-09-03T23:08:52.675000-04:00 · active path

Preceding visible parent: [C118-M00095](part-06.md#m-538eb794-c161-446d-8a71-7899ec761cba)

<!-- BEGIN_SOURCE_MESSAGE -->
The full label cannot be added to a tooltip. we need to create a measure.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dfc16854-b2df-4556-9b3a-57838b581fa5"></a>
## Assistant · C118-M00097

C118-M00097 · 2026-09-03T23:08:59.557720-04:00 · active path

Preceding visible parent: [C118-M00096](part-06.md#m-0becfdc2-862c-4ff9-8ec5-69385f62627c)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. For a tooltip field well, use a **measure**, not the calculated column.

Create this in `R1Measures` and place it in the single:

```text
P04 | Servicing & Exceptions
```

folder:

```DAX
R26 P04 Servicing Queue Tooltip =
VAR _Queue =
    SELECTEDVALUE (
        'DimServicingQueue'[servicing_queue_code]
    )

VAR _Fallback =
    SUBSTITUTE (
        LOWER ( _Queue ),
        "_",
        " "
    )

RETURN
    SWITCH (
        _Queue,

        "NO_SERVICING_REQUIRED",
            "No servicing required",

        "ACTIVE_REASSESSMENT",
            "Active reassessment",

        "GOVERNANCE_REVIEW_HOLD",
            "Governance review hold",

        IF (
            ISBLANK ( _Queue ),
            BLANK (),
            UPPER ( LEFT ( _Fallback, 1 ) )
                & MID (
                    _Fallback,
                    2,
                    LEN ( _Fallback )
                )
        )
    )
```

Then use:

- **Y-axis:** `DimServicingQueue[P04 Servicing Queue Label]`
- **Tooltip:** `[R26 P04 Servicing Queue Tooltip]`

I would also keep the other two tooltip fields we established:

```text
R26 P04 Servicing Exposure
R26 P04 Servicing Burden by Queue
```

So the final Servicing disposition tooltip stack is:

```text
Servicing queue
Certified exposure
Servicing burden
```

with the first value coming from `[R26 P04 Servicing Queue Tooltip]`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0fb4c96f-3415-46c3-8afd-a263d2476ec4"></a>
## Andrew / user · C118-M00098

C118-M00098 · 2026-09-04T00:19:24.403000-04:00 · active path

Preceding visible parent: [C118-M00097](part-06.md#m-dfc16854-b2df-4556-9b3a-57838b581fa5)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 6bd05315-f0fd-4fce-8413-b80eca80f343.png

<!-- BEGIN_SOURCE_MESSAGE -->
thoughts. one thing that seems to stick out to me is servicing burden. that 17 just sticks out like what is this and the user has no context.  also, i need alt text please for title/kpi/tables/charts
<!-- END_SOURCE_MESSAGE -->


<a id="m-c2f8b3d6-3491-4f24-9a6d-93ceef9552d1"></a>
## Assistant · C118-M00099

C118-M00099 · 2026-09-04T00:19:27.607898-04:00 · active path

Preceding visible parent: [C118-M00098](part-06.md#m-0fb4c96f-3415-46c3-8afd-a263d2476ec4)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The page is now telling the intended P04 story well. The **99 / 4 endpoint split**, **1 / 3 servicing disposition**, four-account workbench, and downstream certification detail form a coherent progression.

I agree completely about **Servicing burden = 17**. As presented, it is the weakest KPI because the reader has no natural unit of interpretation. The source defines it as `servicing_burden_units`, and the queue definitions themselves carry burden-unit weights, so 17 is a governed workload index—not 17 accounts, actions, cases, or dollars. [export reference: filecite | turn130file10 | L630-L635]

## I would change “Servicing burden”

I would **not remove the metric**, because it adds something genuinely different: operational workload intensity.

Rename the visible KPI:

> **Servicing workload**

and show:

> **17 units**

rather than simply `17`.

That immediately makes it interpretable as an index/weighted workload measure rather than a count.

If the card lets you use a subtitle, add:

> **Weighted workload**

So visually:

**Servicing workload**  
**17 units**  
*Weighted workload*

I would also make the tooltip explanatory:

> **Weighted servicing workload based on the governed burden assigned to each endpoint servicing queue.**

This is defensible because `DimServicingQueue` contains an explicit `burden_units` field alongside queue rank and manual-review status. [export reference: filecite | turn132file1 | L26-L32]

I prefer this over replacing it with another KPI. P04 already has counts, exposure, active servicing, holds, certification, and exceptions. Workload adds a different management dimension.

### One other thing I caught

Your screenshot shows:

> **Attention exposure: $0.00**

while the four workbench rows clearly contain positive attention exposures totaling **$7,823.28**.

That KPI is therefore **not correct yet**. Do not sign off P04 with `$0.00`. The row-level values demonstrate that the underlying successor data is there; the page-level aggregation measure is losing context. We should correct `R26 P04 Attention Exposure` next.

Everything else visible is directionally coherent.

---

# P04 alt text

I would use static purpose-oriented alt text for most visuals rather than mechanically reading every visible value. For the KPI stack, a dynamic summary is worthwhile.

### Page title / introductory text

> **Merchant Servicing and Exceptions. Endpoint operational view of funded synthetic accounts requiring attention, including monitoring posture, servicing disposition, intervention, payment reconciliation, and certification outcomes.**

### Scenario slicer

> **Scenario selector. Filters the P04 servicing and exceptions view between governed synthetic scenarios.**

### KPI stack

I recommend a dynamic measure because these values change with Scenario. Create `R26 P04 KPI Alt Text` in your single P04 measures folder:

```DAX
R26 P04 KPI Alt Text =
"Operational summary. "
    & FORMAT (
        COALESCE ( [R26 P04 Requiring Attention], 0 ),
        "0"
    )
    & " funded accounts require attention, representing "
    & FORMAT (
        COALESCE ( [R26 P04 Attention Exposure], 0 ),
        "$#,0.00"
    )
    & " in attention exposure. "
    & FORMAT (
        COALESCE ( [R26 P04 Active Servicing], 0 ),
        "0"
    )
    & " accounts are in active servicing and "
    & FORMAT (
        COALESCE ( [R26 P04 Review Holds], 0 ),
        "0"
    )
    & " are on review hold. Certified exposure is "
    & FORMAT (
        COALESCE ( [R26 P04 Certified Exposure], 0 ),
        "$#,0.00"
    )
    & ". Weighted servicing workload is "
    & FORMAT (
        COALESCE ( [R26 P04 Servicing Burden], 0 ),
        "0.##"
    )
    & " units. Unresolved exceptions: "
    & FORMAT (
        COALESCE ( [R26 P04 Unresolved Exceptions], 0 ),
        "0"
    )
    & "."
```

Bind the KPI card/container alt text to that measure.

Once Attention Exposure is corrected, your current Baseline result should read approximately:

> Operational summary. 4 funded accounts require attention, representing $7,823.28 in attention exposure. 1 account is in active servicing and 3 are on review hold. Certified exposure is $6,061.03. Weighted servicing workload is 17 units. Unresolved exceptions: 0.

That is much more informative than six independent card labels to a screen-reader user.

### Endpoint monitoring posture

> **Endpoint monitoring posture. Shows funded-account counts by governed monitoring status at the November 22, 2026 synthetic endpoint, from dormant and severe shortfall through paid off.**

I would keep this static. The chart's categories and values themselves remain accessible.

### Servicing disposition

> **Servicing disposition. Shows funded-account counts by governed endpoint servicing queue, including reassessment and review hold. Tooltips provide the full queue description, certified exposure, and weighted servicing workload.**

This nicely explains why the abbreviated axis labels are intentional.

### Account attention workbench

> **Account attention workbench. Lists funded accounts requiring operational attention with endpoint monitoring status, remittance pace, attention exposure, recommended intervention, operational setup state, servicing execution state, and final endpoint state.**

That captures the M2.5 → M2.6 → M2.7 → M2.8 → M2.10 progression without reading every row aloud.

### Payment & certification detail

> **Payment and certification detail. Shows servicing execution, payment-event activity, processed payments, return and retry activity, reconciliation outcome, certification date, and certified exposure for funded accounts requiring attention.**

Once we set interactions so a selected workbench row filters this table, I would slightly strengthen it to:

> **Payment and certification detail for the selected attention account. Shows servicing execution, payment-event activity, processed payments, return and retry activity, reconciliation outcome, certification date, and certified exposure.**

Use the second version **only if selection is actually required/meaningful**. Your current screenshot shows all four rows simultaneously, so the first version is presently more accurate.

---

## Where I think P04 stands visually

The page hierarchy is much stronger now than the predecessor version. In particular:

**Endpoint monitoring posture** answers *who needs attention?*  
**Servicing disposition** answers *where are those accounts operationally?*  
**Account attention workbench** answers *which accounts, why, and what happened through the servicing chain?*  
**Payment & certification detail** answers *did the downstream payment/control state reconcile and certify?*

That is a legitimate client-facing operating view rather than a collection of servicing metrics.

Before we move into final formatting/evidence, I would make only two substantive changes:

1. **Rename `Servicing burden` → `Servicing workload` and display `17 units`.**
2. **Fix Attention exposure**, because `$0.00` is currently inconsistent with the four underlying workbench rows and should be **$7,823.28** in the displayed Baseline state.

The second one is the only actual semantic defect I see in this screenshot.
<!-- END_SOURCE_MESSAGE -->


<a id="m-716f750c-d4f7-4e6f-abf5-8147df143e8c"></a>
## Andrew / user · C118-M00100

C118-M00100 · 2026-09-04T00:22:48.687000-04:00 · active path

Preceding visible parent: [C118-M00099](part-06.md#m-c2f8b3d6-3491-4f24-9a6d-93ceef9552d1)

<!-- BEGIN_SOURCE_MESSAGE -->
but what is a unit. even knowing it is 17 weighted units. i have no context anywhere else to know what that relates to. there is also no other part of the entire power bi presentation where we dive into that. it just seems like an out of left field metric thrown in.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a34aad40-f2e0-4fc2-ab4a-9024dda9a91f"></a>
## Assistant · C118-M00101

C118-M00101 · 2026-09-04T00:22:51.651452-04:00 · active path

Preceding visible parent: [C118-M00100](part-06.md#m-716f750c-d4f7-4e6f-abf5-8147df143e8c)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree. **Remove it from the KPI stack.**

My attempt to rescue it as “Servicing workload — 17 units” doesn't solve the underlying presentation problem. A client seeing **17 units** still reasonably asks: *17 units of what? How is that calculated? Is 17 high or low? What should I do with it?* P04 provides none of that context.

The source metric is legitimate, but **a legitimate model metric is not automatically a useful executive KPI**. `servicing_burden_units` is an internally governed weighted construct, with burden weights attached to servicing queues. [export reference: filecite | turn132file1 | L26-L32] Without a benchmark, scale, trend, target, or comparative interpretation elsewhere in the report, putting `17` prominently in the KPI rail makes the page less intuitive.

### What should replace it?

I would **not force a replacement just to preserve seven KPIs**. Six strong, immediately interpretable KPIs are better:

> **Requiring attention** — 4  
> **Attention exposure** — $7.82K  
> **Active servicing** — 1  
> **Review holds** — 3  
> **Certified exposure** — $6.06K  
> **Unresolved exceptions** — 0

Those form a coherent operational story:

**How many need attention? → How much exposure? → What's actively being worked? → What's held for review? → What's the certified residual exposure? → Is anything unresolved?**

That is much stronger.

I would retain `R26 P04 Servicing Burden` and `R26 P04 Servicing Burden by Queue` **in the semantic model** because they preserve the accepted M2.10 metric and could be useful in later technical analysis. But I would remove servicing burden from:

- the visible KPI stack;
- the Servicing disposition tooltip;
- the P04 KPI alt text.

For the **Servicing disposition tooltip**, I'd now use just:

> **Full servicing queue**  
> **Certified exposure**

That's enough.

And the revised KPI alt text should be:

```DAX
R26 P04 KPI Alt Text =
"Operational summary. "
    & FORMAT (
        COALESCE ( [R26 P04 Requiring Attention], 0 ),
        "0"
    )
    & " funded accounts require attention, representing "
    & FORMAT (
        COALESCE ( [R26 P04 Attention Exposure], 0 ),
        "$#,0.00"
    )
    & " in attention exposure. "
    & FORMAT (
        COALESCE ( [R26 P04 Active Servicing], 0 ),
        "0"
    )
    & " accounts are in active servicing and "
    & FORMAT (
        COALESCE ( [R26 P04 Review Holds], 0 ),
        "0"
    )
    & " are on review hold. Certified exposure is "
    & FORMAT (
        COALESCE ( [R26 P04 Certified Exposure], 0 ),
        "$#,0.00"
    )
    & ". Unresolved exceptions: "
    & FORMAT (
        COALESCE ( [R26 P04 Unresolved Exceptions], 0 ),
        "0"
    )
    & "."
```

So yes: **your instinct is correct. Drop servicing burden from the visible P04 story rather than trying to explain an isolated metric the report has no reason to teach the user how to interpret.**

We should still fix the `$0.00` Attention exposure next; that's a genuine calculation/context issue.
<!-- END_SOURCE_MESSAGE -->


<a id="m-11c994b4-56a8-43b3-90b9-bdfd1a2216fa"></a>
## Andrew / user · C118-M00102

C118-M00102 · 2026-09-04T00:25:28.377000-04:00 · active path

Preceding visible parent: [C118-M00101](part-06.md#m-a34aad40-f2e0-4fc2-ab4a-9024dda9a91f)

<!-- BEGIN_SOURCE_MESSAGE -->
why is my KPI attention exposure = $0?
<!-- END_SOURCE_MESSAGE -->


<a id="m-ee784275-9736-4b54-ba16-6efd67aa7fd1"></a>
## Assistant · C118-M00103

C118-M00103 · 2026-09-04T00:25:34.278292-04:00 · active path

Preceding visible parent: [C118-M00102](part-06.md#m-11c994b4-56a8-43b3-90b9-bdfd1a2216fa)

<!-- BEGIN_SOURCE_MESSAGE -->
The most likely reason is the same issue we just found with the servicing chart: **the KPI card is probably still bound to the old predecessor `P04 Attention Exposure` measure, not the new `R26 P04 Attention Exposure`.**

Your own page proves the successor calculation is working at row level. The workbench shows:

- 000098: **$1,720.89**
- 000112: **$763.89**
- 000312: **$639.13**
- 000749: **$4,699.37**

Those sum to **$7,823.28**. So the R26 attention population and exposure values are present and coherent.

Select the **Attention exposure** KPI card and inspect its Value field. It should be exactly:

```text
R1Measures[R26 P04 Attention Exposure]
```

not:

```text
P04 Attention Exposure
```

or another predecessor measure.

This is especially plausible because the P04 page began as an existing predecessor page, and we are rebinding visuals in place. We already found exactly that problem on **Servicing disposition**, where the old measure produced the nonsensical `44 / 44 / 44` result until the visual was pointed to the R26 measure.

If the card **already is** using `[R26 P04 Attention Exposure]`, then we have a measure-total-context defect and I will correct the DAX. But first check the card binding; based on the evidence visible on your page, I strongly suspect it is simply still using the old measure.

The expected Baseline KPI is:

> **Attention exposure: $7.82K**  
> exact value **$7,823.28**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-385ab234-f062-422f-a1a2-3d2780c9b611"></a>
## Andrew / user · C118-M00104

C118-M00104 · 2026-09-04T00:26:55.094000-04:00 · active path

Preceding visible parent: [C118-M00103](part-06.md#m-ee784275-9736-4b54-ba16-6efd67aa7fd1)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: c61621d0-3cad-474d-8e83-e1d1da7c8d43.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-bccf2057-8175-42f3-a795-028a80ba869d"></a>
## Assistant · C118-M00105

C118-M00105 · 2026-09-04T00:26:58.092650-04:00 · active path

Preceding visible parent: [C118-M00104](part-06.md#m-385ab234-f062-422f-a1a2-3d2780c9b611)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes—the screenshot confirms the card is already using **`R1Measures[R26 P04 Attention Exposure]`**. So my binding hypothesis was wrong.

The defect is in the **measure's total-context logic**.

The workbench proves the correct Baseline population and values:

- 000098 — $1,720.89
- 000112 — $763.89
- 000312 — $639.13
- 000749 — $4,699.37
- **Total — $7,823.28**

The issue in the DAX I supplied is that it iterates `R1DimApplicationScenario[ApplicationScenarioKey]`, but then evaluates the endpoint monitoring row through a combination of existing relationship context plus `TREATAS`. At individual workbench-row grain that resolves correctly; at portfolio/card grain it is not reliably isolating each R1 monitoring path before summing.

We don't need that complexity. The attention exposure is directly defined by the **endpoint rows of `R1FactDailyMonitoring` whose governed endpoint monitoring status is adverse**.

Replace `R26 P04 Attention Exposure` with this:

```DAX
R26 P04 Attention Exposure =
VAR _EndpointDate =
    [R1 P01 Evidence Max Date]

RETURN
    IF (
        ISBLANK ( _EndpointDate ),
        BLANK (),
        COALESCE (
            CALCULATE (
                SUM (
                    'R1FactDailyMonitoring'[receivable_balance_after]
                ),

                REMOVEFILTERS (
                    'R1FactDailyMonitoring'[monitoring_date]
                ),

                'R1FactDailyMonitoring'[monitoring_date]
                    = _EndpointDate,

                'R1FactDailyMonitoring'[monitoring_status_code]
                    IN {
                        "UNDERPERFORMING",
                        "SEVERE_SHORTFALL",
                        "DORMANT_NO_REMITTANCE"
                    }
            ),
            0
        )
    )
```

### Why this is better

This calculation now says exactly what the KPI means:

> **At the governed endpoint date, sum remaining receivable for funded paths in an adverse monitoring state.**

There is no need to iterate the application-scenario dimension because `R1FactDailyMonitoring` itself is already at exact application-scenario × monitoring-day grain, and the endpoint date gives us one row per funded path.

It also preserves the Scenario filter naturally.

### Expected regression

After replacing the measure:

**Baseline**

```text
Requiring attention     4
Attention exposure      $7,823.28
```

**Recession Energy**

```text
Requiring attention     0
Attention exposure      $0.00
```

And the four Baseline workbench values should remain exactly unchanged.

This is a worthwhile correction to the presentation-layer DAX handoff as well: **the original `R26 P04 Attention Exposure` formula I supplied should be considered superseded by this version.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-2b8ca852-92e4-441b-b48f-856b4c33a024"></a>
## Andrew / user · C118-M00106

C118-M00106 · 2026-09-04T00:35:09.596000-04:00 · active path

Preceding visible parent: [C118-M00105](part-06.md#m-bccf2057-8175-42f3-a795-028a80ba869d)

<!-- BEGIN_SOURCE_MESSAGE -->
ok, last thing is alt text and then we can capture P04 evidence. please advise on alt text
<!-- END_SOURCE_MESSAGE -->


<a id="m-a4366157-0acd-4a76-ac91-e23bcaebcb7c"></a>
## Assistant · C118-M00107

C118-M00107 · 2026-09-04T00:35:12.673575-04:00 · active path

Preceding visible parent: [C118-M00106](part-06.md#m-2b8ca852-92e4-441b-b48f-856b4c33a024)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. With Attention exposure corrected and Servicing burden removed from the visible story, I would make this the **final P04 accessibility pass**. No additional semantic work is needed for alt text.

For this page, I recommend mostly **static purpose-oriented alt text**, with a dynamic measure only for the KPI stack. That avoids making a screen reader repeat entire tables while still explaining what each visual represents.

| Visual | Final alt text |
|---|---|
| **Page title / introductory text** | `Merchant Servicing and Exceptions. Endpoint operational view of funded synthetic accounts, showing monitoring posture, accounts requiring attention, governed servicing disposition, intervention, payment reconciliation, and certification outcomes.` |
| **Scenario slicer** | `Scenario selector. Filters the servicing and exceptions page to the selected governed synthetic scenario.` |
| **KPI stack** | Use the **dynamic measure below**. |
| **Servicing disposition** | `Servicing disposition. Shows funded-account counts by governed endpoint servicing queue. Tooltips provide the full servicing-queue description and certified exposure.` |
| **Endpoint monitoring posture** | `Endpoint monitoring posture. Shows funded-account counts by governed monitoring status at the November 22, 2026 synthetic endpoint, from dormant and severe shortfall through paid off.` |
| **Account attention workbench** | `Account attention workbench. Lists funded accounts requiring operational attention with endpoint monitoring status, remittance pace, attention exposure, recommended intervention, operational setup state, servicing execution state, and final endpoint state.` |
| **Payment & certification detail** | `Payment and certification detail. Shows servicing execution, payment-event activity, processed payments, return and retry activity, reconciliation outcome, certification date, and certified exposure for funded accounts requiring attention.` |

### KPI-stack dynamic alt text

Create this measure in:

`P04 | Servicing & Exceptions`

```DAX
R26 P04 KPI Alt Text =
VAR _Attention =
    COALESCE ( [R26 P04 Requiring Attention], 0 )

VAR _AttentionExposure =
    COALESCE ( [R26 P04 Attention Exposure], 0 )

VAR _Active =
    COALESCE ( [R26 P04 Active Servicing], 0 )

VAR _Review =
    COALESCE ( [R26 P04 Review Holds], 0 )

VAR _CertifiedExposure =
    COALESCE ( [R26 P04 Certified Exposure], 0 )

VAR _Exceptions =
    COALESCE ( [R26 P04 Unresolved Exceptions], 0 )

RETURN
    "Operational summary. "
        & FORMAT ( _Attention, "0" )
        & IF ( _Attention = 1, " funded account requires ", " funded accounts require " )
        & "attention, representing "
        & FORMAT ( _AttentionExposure, "$#,0.00" )
        & " in attention exposure. "
        & FORMAT ( _Active, "0" )
        & IF ( _Active = 1, " account is ", " accounts are " )
        & "in active servicing, and "
        & FORMAT ( _Review, "0" )
        & IF ( _Review = 1, " account is ", " accounts are " )
        & "on review hold. Certified exposure is "
        & FORMAT ( _CertifiedExposure, "$#,0.00" )
        & ". Unresolved exceptions: "
        & FORMAT ( _Exceptions, "0" )
        & "."
```

For the current Baseline state, that should resolve to approximately:

> Operational summary. 4 funded accounts require attention, representing $7,823.28 in attention exposure. 1 account is in active servicing, and 3 accounts are on review hold. Certified exposure is $6,061.03. Unresolved exceptions: 0.

Bind the KPI visual's **Alt text → fx → Field value** to `R26 P04 KPI Alt Text`.

### A few deliberate choices

I would **not** put all four workbench rows into its alt text. The visual itself exposes the table content; the alt text should explain what the table is and how to interpret its columns.

Likewise, don't enumerate all 99 paid-off and four severe-shortfall accounts in the Endpoint monitoring posture alt text. The chart communicates the current values; the alt text establishes what those values mean.

For **Servicing disposition**, keep the full queue wording in its tooltip via `R26 P04 Servicing Queue Tooltip`, but the alt text does not need to repeat every queue. This preserves the clean short axis labels while retaining precise terminology on hover.

### Recommended tab order

Since you're doing the final accessibility pass, I would use:

1. Page title / introduction
2. Scenario slicer
3. KPI stack
4. Endpoint monitoring posture
5. Servicing disposition
6. Account attention workbench
7. Payment & certification detail
8. Footer/boundary text

I slightly prefer **Endpoint monitoring posture before Servicing disposition** in keyboard order even though Servicing disposition is physically farther left. Semantically the story is:

> **What is the endpoint monitoring condition? → What servicing disposition resulted? → Which accounts require attention? → What happened operationally and through certification?**

Once those alt texts and tab order are applied, **P04 is ready for evidence capture and QA**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9193c4b6-1843-44d3-84bc-b2c0d24527e5"></a>
## Andrew / user · C118-M00108

C118-M00108 · 2026-09-04T00:39:12.140000-04:00 · active path

Preceding visible parent: [C118-M00107](part-06.md#m-a4366157-0acd-4a76-ac91-e23bcaebcb7c)

<!-- BEGIN_SOURCE_MESSAGE -->
we have not added alt text to slicers yet and probably shouldn't start now. that also goes for the footnote/run/source release/model version/observed source cutoff
<!-- END_SOURCE_MESSAGE -->


<a id="m-0d921819-044f-4dc3-b659-88c21e7a8c8a"></a>
## Assistant · C118-M00109

C118-M00109 · 2026-09-04T00:39:15.225981-04:00 · active path

Preceding visible parent: [C118-M00108](part-06.md#m-9193c4b6-1843-44d3-84bc-b2c0d24527e5)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. We should **preserve the accessibility convention already established across P01–P03**, rather than introducing a new standard on P04.

So remove from my prior recommendation:

- **Scenario slicer alt text** — do not add.
- **Run / Source release / Model version / Observed-source cutoff** — do not add.
- **Temporal / Interpretation boundary text** — do not add separate alt text.

Those elements already contain their own readable text or native control labeling, and consistency across the report matters.

### Final P04 alt-text scope

Add alt text only to these substantive visuals:

1. **Title / introductory visual**
   > `Merchant Servicing and Exceptions. Endpoint operational view of funded synthetic accounts, showing monitoring posture, accounts requiring attention, governed servicing disposition, intervention, payment reconciliation, and certification outcomes.`

2. **KPI stack** — bind to the dynamic `R26 P04 KPI Alt Text` measure provided above.

3. **Endpoint monitoring posture**
   > `Endpoint monitoring posture. Shows funded-account counts by governed monitoring status at the November 22, 2026 synthetic endpoint, from dormant and severe shortfall through paid off.`

4. **Servicing disposition**
   > `Servicing disposition. Shows funded-account counts by governed endpoint servicing queue. Tooltips provide the full servicing-queue description and certified exposure.`

5. **Account attention workbench**
   > `Account attention workbench. Lists funded accounts requiring operational attention with endpoint monitoring status, remittance pace, attention exposure, recommended intervention, operational setup state, servicing execution state, and final endpoint state.`

6. **Payment & certification detail**
   > `Payment and certification detail. Shows servicing execution, payment-event activity, processed payments, return and retry activity, reconciliation outcome, certification date, and certified exposure for funded accounts requiring attention.`

And **nothing additional** for the slicer, footer identity fields, or boundary text.

That keeps P04 consistent with the accessibility treatment we've established elsewhere rather than expanding scope at this stage.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d69b2f84-540d-40a0-8bb7-bae307f4e9f3"></a>
## Andrew / user · C118-M00110

C118-M00110 · 2026-09-04T00:53:59.996000-04:00 · active path

Preceding visible parent: [C118-M00109](part-06.md#m-0d921819-044f-4dc3-b659-88c21e7a8c8a)

<!-- BEGIN_SOURCE_MESSAGE -->
ok, now i'm about to capture P04 evidence. you mentioned a QA I was supposed to run. can you re-provide that?
<!-- END_SOURCE_MESSAGE -->


<a id="m-8a3cb048-2270-439d-baee-010ebfa9f340"></a>
## Assistant · C118-M00111

C118-M00111 · 2026-09-04T00:54:03.000985-04:00 · active path

Preceding visible parent: [C118-M00110](part-06.md#m-d69b2f84-540d-40a0-8bb7-bae307f4e9f3)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Use the **P04 successor QA R1** that I prepared with the presentation layer.

Download the P04 successor QA DAX (historical reference: `sandbox:[session]/p04_presentation_layer/MSBF_R26_P04_PRESENTATION_QA_R1_20260903.dax`; referenced bytes not established here)

In **DAX Query View**:

1. Paste the complete query.
2. Click **Run only**.
3. **Do not click “Update model with changes.”**
4. It produces **7 result sets**.

Capture **Result 1 through Result 7**.

### Expected controls

| Result | Control | Expected |
|---|---|---|
| **1** | M2.6–M2.10 source populations | Each of Intervention, Setup, Execution, Certification and Performance = **130 rows / 130 unique ApplicationScenarioKeys** |
| **2** | M2.7 setup distribution | **126** no setup / **3** governance-review setup / **1** temporary-adjustment setup |
| **3** | M2.8 execution distribution | **126** no execution / **3** review hold / **1** active temporary processing |
| **4** | M2.9 certification distribution | **126** certified closed / **3** certified review hold / **1** reassessment-after-retry |
| **5** | M2.10 endpoint posture | **126** closed stable / **3** controlled review / **1** active reconciled; queue mapping should correspond appropriately |
| **6** | P04 page regression by scenario | Baseline should show **4 attention / $7,823.28 attention exposure / 1 active servicing / 3 review holds / $6,061.03 certified exposure / 0 unresolved exceptions**. Recession Energy should show **0 / $0 / 0 / 0 / $0 / 0**. |
| **7** | Representative account-level chain | Checks **749, 098, 112, 312, and 264 Baseline** across monitoring → intervention → setup → execution → endpoint → payment/reconciliation/certification |

One update since I originally wrote the QA: **Result 6 includes Servicing burden**, because the query predates our decision to remove that metric from the visible P04 story. That's fine. Leave it in the QA—it remains a legitimate underlying M2.10 control. We simply aren't presenting it as an executive KPI.

Also, the corrected `R26 P04 Attention Exposure` should now make Result 6 return **$7,823.28 for Baseline**. If it doesn't, stop before evidence capture.

If all seven results pass, capture them, then capture the finished P04 page in:

- **Baseline** — full page, showing the four attention accounts;
- **Recession Energy** — demonstrating the zero-attention/no-servicing state;
- **749 Baseline** — if useful through workbench selection to demonstrate the active-servicing/retry path;
- **one review-hold account**, preferably **098 Baseline**, to demonstrate the governance-review path;
- representative **Endpoint monitoring posture tooltip**;
- representative **Servicing disposition tooltip**;
- alt-text binding and tab-order evidence.

That will give us a strong P04 sign-off package without excessive screenshots.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9d70a30c-cb86-42e7-b269-cfad1a5eea84"></a>
## Andrew / user · C118-M00112

C118-M00112 · 2026-09-04T00:57:45.963000-04:00 · active path

Preceding visible parent: [C118-M00111](part-06.md#m-8a3cb048-2270-439d-baee-010ebfa9f340)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 51dd0f32-1367-4819-a8c5-4628891ba8d2.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-722c7623-61ff-4f0c-a9e6-272b065f4178"></a>
## Assistant · C118-M00113

C118-M00113 · 2026-09-04T00:58:26.954697-04:00 · active path

Preceding visible parent: [C118-M00112](part-06.md#m-9d70a30c-cb86-42e7-b269-cfad1a5eea84)

<!-- BEGIN_SOURCE_MESSAGE -->
The error is in **Result 5 of the QA query**, not in your model.

`R1FactPortfolioPerformance` does **not** contain an `unresolved_exception_count` column. The current canonical unresolved-exception logic is instead already defined by `R1 P01 Unresolved Exceptions`, which counts rows where `exception_incident_flag = "t"` and `exception_resolved_flag <> "t"`. [export reference: filecite | turn134file0 | L14-L25]

So in the QA query, replace this line in **Result 5**:

```DAX
"Unresolved exceptions",
    SUM (
        'R1FactPortfolioPerformance'[unresolved_exception_count]
    )
```

with:

```DAX
"Unresolved exceptions",
    [R1 P01 Unresolved Exceptions]
```

That is the correct fix and is preferable to recreating the logic inside the QA.

The corrected **Result 5 block** should be:

```DAX
// Result 5 — M2.10 endpoint posture and servicing queue.
// Current R26 expected total:
// 126 closed stable / 3 controlled review / 1 active reconciled.
EVALUATE
SUMMARIZECOLUMNS (
    'R1FactPortfolioPerformance'[performance_tier_code],
    'R1FactPortfolioPerformance'[servicing_queue_code],

    "Rows",
        COUNTROWS (
            'R1FactPortfolioPerformance'
        ),

    "Certified exposure",
        SUM (
            'R1FactPortfolioPerformance'[certified_exposure_amount]
        ),

    "Servicing burden",
        SUM (
            'R1FactPortfolioPerformance'[servicing_burden_units]
        ),

    "Unresolved exceptions",
        [R1 P01 Unresolved Exceptions]
)
ORDER BY
    'R1FactPortfolioPerformance'[performance_tier_code],
    'R1FactPortfolioPerformance'[servicing_queue_code]
```

This was my QA-handoff defect: I referenced a column that exists in some predecessor/endpoint structures but **not in the R1 successor `R1FactPortfolioPerformance` table**. The canonical register confirms that the R1 measure intentionally derives unresolved exceptions from the incident/resolved flags instead. [export reference: filecite | turn133file1 | L107-L118]

Make that one replacement and rerun the full query. If another compile error appears, send it before changing anything else.
<!-- END_SOURCE_MESSAGE -->


<a id="m-335d304c-f66d-4dff-b128-119b6cb6458a"></a>
## Andrew / user · C118-M00114

C118-M00114 · 2026-09-04T01:10:57.388000-04:00 · active path

Preceding visible parent: [C118-M00113](part-06.md#m-722c7623-61ff-4f0c-a9e6-272b065f4178)

**Editorial record note:** 15 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P04_Endpoint_Monitoring_Posture_Tooltip_Evidence.png; P04_Baseline_Merchant_098_Filtered.png; P04_Baseline_Merchant_749_Filtered.png; P04_Recession_Energy_Full_Page.png; P04_Baseline_Full_Page.png; P04_Presentation_QA_Result_Set_07.png; P04_Presentation_QA_Result_Set_06.png; P04_Presentation_QA_Result_Set_05.png; P04_Presentation_QA_Result_Set_04.png; P04_Presentation_QA_Result_Set_03.png; P04_Presentation_QA_Result_Set_02.png; P04_Presentation_QA_Result_Set_01.png; P04_Tab_Order.png; P04_Alt_Text.png; P04_Servicing_Disposition_Tooltip_Evidence.png

<!-- BEGIN_SOURCE_MESSAGE -->
P04 evidence for final review.
<!-- END_SOURCE_MESSAGE -->


<a id="m-efa61c7a-b311-46bf-a31b-b5d34608adc5"></a>
## Assistant · C118-M00115

C118-M00115 · 2026-09-04T01:11:03.836926-04:00 · active path

Preceding visible parent: [C118-M00114](part-06.md#m-335d304c-f66d-4dff-b128-119b6cb6458a)

<!-- BEGIN_SOURCE_MESSAGE -->
The P04 evidence is strong and the page is essentially ready for sign-off. The QA suite is clean, the visual story holds under both scenarios, the workbench-to-detail interaction works, and the successor servicing chain is now visible in a way that is much more useful than the original P04.

I have **one correction before I would freeze P04**.

Your **Servicing disposition tooltip still contains `Servicing burden`**. In the evidence capture for Reassessment, it shows:

> Servicing queue: Reassessment  
> Accounts: 1  
> Full queue: Active reassessment  
> Certified exposure: $2,937.12  
> **Servicing burden: 2**

We deliberately decided to remove that metric from the visible P04 story because a reader has no contextual basis for interpreting the unit. The same reasoning applies to the tooltip. Remove `[R26 P04 Servicing Burden by Queue]` from that tooltip. The final tooltip should contain only:

> **Servicing queue**  
> **Accounts**  
> **Full servicing queue**  
> **Certified exposure**

Then recapture **only that tooltip screenshot**. You do not need to recreate the full-page or QA evidence.

Everything else passes my review.

The QA results are particularly clean:

- **Result 1:** all five successor stages = **130 rows / 130 unique keys**.
- **Result 2:** setup = **126 no setup / 3 review required / 1 temporary adjustment ready**.
- **Result 3:** execution = **126 none / 3 review hold / 1 active temporary processing**.
- **Result 4:** certification = **126 closed / 3 review hold / 1 reassessment after retry**, with the expected exposure split.
- **Result 5:** M2.10 endpoint = **126 closed stable / 3 controlled review / 1 active reconciled**, correctly mapped to **No servicing required / Governance review hold / Active reassessment**.
- **Result 6:** Baseline = **4 attention / $7,823.28 / 1 active / 3 holds / $6,061.03 certified / 17 underlying burden / 0 unresolved**; Recession Energy = zero across the operational exception measures.
- **Result 7:** the representative account chain behaves correctly, including 264 as the paid-off/no-action control and 749 as the active temporary-processing/retry case.

The full-page evidence also demonstrates the right scenario separation. Baseline has 103 endpoint paths—99 paid off plus four severe-shortfall attention accounts—while Recession Energy shows 27 paid-off paths and no attention population. The empty workbench/detail tables under Recession Energy are therefore useful evidence, not a display defect.

The 098 and 749 captures are especially valuable because they prove the interaction behavior. Selecting 098 reduces Payment & certification detail to the review-hold account; selecting 749 isolates the active-servicing path with seven payment events, $1,762.25 processed, one return/one retry, reconciliation after retry, and $2,937.12 certified exposure.

The **Endpoint monitoring posture tooltip** is also good. For Severe shortfall it communicates four accounts, $7,823.28 exposure, and 85.6% average remittance pace. That is concise and interpretable.

### Tab order

Your current order is acceptable:

```text
Title
Scenario
KPI stack
Servicing disposition
Endpoint monitoring posture
Account attention workbench
Payment & certification detail
footer text
```

I previously preferred Endpoint posture before Servicing disposition semantically, but I would **not make you change it now**. The current order follows the visual layout from left to right and remains coherent.

### Accessibility

The KPI alt-text evidence confirms the dynamic `R26 P04 KPI Alt Text` binding. I do not need separate screenshots proving each static alt-text string; we followed the same evidence standard on P03. Likewise, no alt text is needed on the slicer or footer/boundary text.

### Final P04 disposition

Once you remove **Servicing burden** from the Servicing disposition tooltip and recapture that one hover:

```text
P04 — Merchant Servicing & Exceptions

Successor source architecture        PASS
Endpoint monitoring posture          PASS
Servicing disposition                PASS
Attention population                 PASS
Attention exposure                   PASS
Account attention workbench          PASS
Setup / execution / endpoint chain   PASS
Payment & certification detail       PASS
Workbench-detail interaction         PASS
Scenario isolation                   PASS
P04 presentation QA                  PASS — 7/7
Tooltips                             PASS after burden removal
Accessibility                        PASS
Release identity / boundaries        PASS
Page presentation                    PASS
Final persistence                    DEFERRED to portfolio-wide final gate

FINAL STATUS                         PASS / PAGE FROZEN
```

So this is **not another P04 iteration**. Make that one tooltip cleanup, retain the existing evidence, add the corrected tooltip capture, and P04 can be frozen.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9e94094f-b778-4500-9e90-8de0024c4eec"></a>
## Andrew / user · C118-M00116

C118-M00116 · 2026-09-04T01:14:11.777000-04:00 · active path

Preceding visible parent: [C118-M00115](part-06.md#m-efa61c7a-b311-46bf-a31b-b5d34608adc5)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P04_Servicing_Disposition_Tooltip_Evidence(1).png

<!-- BEGIN_SOURCE_MESSAGE -->
corrected
<!-- END_SOURCE_MESSAGE -->


<a id="m-941aa8d7-34e9-432a-9955-cd9f458d9317"></a>
## Assistant · C118-M00117

C118-M00117 · 2026-09-04T01:14:15.062892-04:00 · active path

Preceding visible parent: [C118-M00116](part-06.md#m-9e94094f-b778-4500-9e90-8de0024c4eec)

<!-- BEGIN_SOURCE_MESSAGE -->
Confirmed. The corrected tooltip now contains only:

- **Servicing queue:** Reassessment
- **Accounts:** 1
- **Full queue:** Active reassessment
- **Certified exposure:** $2,937.12

The unexplained servicing-burden metric is gone, while the abbreviated axis label remains backed by the full business-facing queue description on hover. This is the intended final treatment.

### P04 final disposition

**P04 — Merchant Servicing & Exceptions: `PASS / PAGE FROZEN`**

All page-level closeout gates are now satisfied:

```text
Successor M2.6–M2.10 architecture     PASS
130-key stage integrity               PASS
Endpoint monitoring posture           PASS
Servicing disposition                 PASS
Attention population/exposure         PASS
Account attention workbench           PASS
Setup → execution → endpoint chain    PASS
Payment & certification detail        PASS
Workbench-detail interaction          PASS
Scenario isolation                    PASS
Representative-path regression        PASS
P04 QA                                PASS — 7/7
Tooltips                              PASS
Alt text                              PASS
Tab order                             PASS
Release identity                      PASS
Temporal/interpretation boundaries    PASS
Presentation quality                  PASS
```

The only deferred control is the **portfolio-wide final persistence/nonregression gate**—refresh/save/close/reopen and final P01–P06 verification—which we intentionally agreed to perform after the entire Power BI report is complete.

I would make **no further changes to P04** unless P05/P06 integration or that final nonregression gate exposes an actual defect.

**P01–P04 are now complete at the page-production level. P05 is the next production target.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-7ffae0bd-6f11-4c18-b77a-a85e9158e6e4"></a>
## Andrew / user · C118-M00118

C118-M00118 · 2026-09-04T13:57:43.981000-04:00 · active path

Preceding visible parent: [C118-M00117](part-06.md#m-941aa8d7-34e9-432a-9955-cd9f458d9317)

**Editorial record note:** Attachment references: owner_evidence.zip; project(1).zip

<!-- BEGIN_SOURCE_MESSAGE -->
I took additional captures and organized the owner evidence folder a bit tighter, including a focused presentation folder. Begin by reviewing the additional captures. I would then like to use the information to build a comprehensive presentation about our initial 750 cohort using the Power BI visuals as evidence. This should be a detailed Cohort Overview. It should be professional (similar to our business requirements or validation artifacts) and focused on everything that our power bi analysis has taught us about this cohort. Also, attached is the project folder with the latest Power BI saved inside (MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2 - only ingest the new items from this project zip. You previously ingested much of this folder already). Use whatever you need from this and the captures to build this comprehensive, professional, elite cohort overview. Leap as far as you can in each prompt, stopping only when it makes sense so as not to overload each prompt and lead to failure. This needs done today and needs to be exceptional.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b795f5c0-aac8-4ea8-96e9-3b15dd4dba59"></a>
## Assistant · C118-M00119

C118-M00119 · 2026-09-04T14:27:53.047108-04:00 · active path

Preceding visible parent: [C118-M00118](part-06.md#m-7ffae0bd-6f11-4c18-b77a-a85e9158e6e4)

<!-- BEGIN_SOURCE_MESSAGE -->
## Evidence review completed

The tighter owner-evidence package is materially better organized and is suitable for a formal cohort presentation. I reviewed the extracted package and found **94 clean, presentation-focused Power BI captures**:

| Evidence area | Captures | Coverage |
|---|---:|---|
| Cohort Command Center | 32 | Full Baseline and Recession Energy pages, plus all seven acquisition-source cuts and all eight industry cuts under both scenarios |
| Cohort Lifecycle | 32 | Full Baseline and Recession Energy pages, plus the same acquisition-source and industry segmentation |
| Application & Account Journey | 28 | Representative authorization, review, evidence-decline, no-feasible, policy-hard-stop, stress-floor, funding, monitoring, and servicing situations |
| Servicing & Exceptions | 2 | Final Baseline and Recession Energy operating views |
| **Total** | **94** | Complete focused presentation set |

The broader owner-evidence package also retains the detailed P01-P04 QA, tooltip, interaction, alt-text, tab-order, and representative-account captures. I found no duplicate hashes within the 94-image focused presentation folder.

## Latest project delta reviewed

I compared the latest project ZIP with the previously ingested project and limited the new project review to the changed items.

The project delta is tightly bounded:

- **One client-facing PBIX was added:**  
  `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix`
- **The controlled C2 PBIX was updated.**
- **No project files were removed.**
- The client-facing PBIX is **27,635,325 bytes** with SHA-256:  
  `d3fd07497e25bb8cb2fed76cd595344dad6f482e8ef61beeac958a493b57ca36`
- The current PBIX incorporates the named P02 successor and diagnostic queries, P03 performance-monitoring patch and QA, and P04 presentation-layer and QA queries.

That confirms the new publishable identity and the completed P01-P04 analytical wave without needlessly reprocessing the unchanged project contents.

# Cohort findings driving the presentation

The evidence supports a detailed and cohesive story about the initial cohort.

### Cohort architecture

The population contains **750 fixed synthetic merchants**, evaluated under **Baseline** and **Recession Energy**, producing:

- 1,500 application-scenario paths;
- 130 physically funded scenario paths;
- 15,600 monitoring rows;
- exactly 120 monitoring days per funded path;
- 130 exact keys through each intervention, operational-setup, servicing-execution, certification, and portfolio-performance stage.

### Baseline portfolio

Baseline produces:

- 103 authorized and funded paths;
- $1,385,300 funded;
- 197 additional governed review paths;
- 300 supportable paths, or 40.0%;
- 13.7% authorized-offer rate;
- 9.4% comparative expected-loss rate;
- $147,981 in risk-adjusted contribution;
- 99.5% endpoint remittance fulfillment;
- 99 paid-off accounts;
- four severe-shortfall accounts;
- $7,823.28 in attention exposure;
- $6,061.03 in certified ending exposure;
- zero unresolved exceptions.

### Recession Energy portfolio

Recession Energy produces:

- 27 authorized and funded paths;
- $344,200 funded;
- 53 additional governed review paths;
- 80 supportable paths, or 10.7%;
- 3.6% authorized-offer rate;
- 11.4% comparative expected-loss rate;
- $30,032 in risk-adjusted contribution;
- 100.0% endpoint remittance fulfillment;
- all 27 funded paths paid off;
- no endpoint attention population;
- no ending exposure;
- no unresolved exceptions.

The stress scenario therefore reduces:

- authorized-path count by 73.8%;
- funded dollars by 75.2%;
- supportable-path rate by 29.3 percentage points;
- risk-adjusted contribution by 79.7%.

Comparative expected loss increases by approximately two percentage points.

### Scenario resilience and governance

Of the 750 merchants:

- 514, or 68.5%, retain the same governed outcome;
- 236, or 31.5%, change outcome;
- all 27 stress authorizations were already authorized in Baseline;
- 76 Baseline authorizations are no longer authorized under stress;
- zero merchants become newly authorized only under stress.

The approved non-improvement floor applies to 169 paths. It changes 166 governed outcomes and 39 candidate selections or reselections. This is a major feature of the cohort story because it demonstrates that the stress design constrains the decision frontier rather than manufacturing favorable stress-side results.

### Application and evidence profile

The population is broad but request sizes are strongly right-skewed:

- median request: $9,900;
- mean request: $25,447;
- maximum request: $150,000;
- 44.9% request 60-day structures;
- 30.0% request 90-day structures;
- 25.1% request 30-day structures.

Evidence is generally strong:

- 83.3% high data confidence;
- 81.3% complete feature evidence;
- 61.7% stable processor continuity.

But verification friction is common:

- 49.9% have a review verification disposition;
- 12.1% have insufficient evidence;
- 3.5% have a stop disposition.

That helps explain why stress evidence declines rise from 43 to 191.

### Structure search

The architecture completed every required governed search:

| Measure | Baseline | Recession Energy |
|---|---:|---:|
| Required and completed searches | 495 | 285 |
| Evaluated candidates | 4,120 | 2,399 |
| Median candidates per searched path | 7 | 7 |
| Maximum candidates | 34 | 34 |
| No-feasible outcomes with proof | 290 | 362 |

Among supportable paths, the system uses multiple remediation forms rather than treating every counteroffer as an amount reduction:

| Structure treatment | Baseline | Recession Energy |
|---|---:|---:|
| Requested structure retained | 115 | 38 |
| Amount reduction | 44 | 17 |
| Remittance adjustment | 82 | 19 |
| Combined restructure | 59 | 6 |

### Segment findings

Processor Embedded and Relationship dominate Baseline funding, jointly representing approximately 64% of funded dollars. Strategic Partner becomes the largest stress-funded source and retains a comparatively strong share of its Baseline funded dollars.

At the industry level:

- Professional Services has the highest Baseline supportable rate at 58.0%.
- Transportation & Logistics has the highest Baseline funded amount and risk-adjusted contribution.
- Healthcare Services has the lowest Baseline comparative expected-loss rate.
- Under stress, Transportation retains the largest funded amount and contribution.
- Energy Services reaches the highest stress comparative expected-loss rate at 21.6%.

### Lifecycle and servicing

Of the 130 funded scenario paths:

- 126 close with no further action;
- three require targeted outreach and remain on governed review hold;
- one enters temporary-remittance review and active synthetic servicing.

The sole active-servicing case, merchant 749, has:

- seven payment events;
- $1,762.25 processed;
- one returned event;
- one retry;
- full return/retry cure;
- $2,937.12 certified ending exposure;
- zero reconciliation variance;
- an Active Reconciled endpoint state.

The three controlled-review accounts are merchants 098, 112, and 312. Together they carry $3,123.91 of certified review-hold exposure.

# Working presentation build

I completed the first full **53-slide Cohort Overview working build**, including:

- executive readout;
- evidence and project-delta review;
- analytical scope and interpretation boundaries;
- cohort architecture;
- merchant, industry, relationship, and sourcing composition;
- request and evidence profile;
- decision architecture;
- full Baseline and Recession Energy Power BI command-center evidence;
- scenario scorecard;
- outcome distributions and transition matrix;
- stress-floor analysis;
- authorization retention;
- candidate search and structure-treatment analysis;
- acquisition-source and industry sections;
- full lifecycle evidence;
- runoff, fulfillment, monitoring, and payoff analysis;
- servicing and certification;
- merchants 738, 082, 098, and 749 as scenario case studies;
- evidence-decline and policy-hard-stop examples;
- QA and governance;
- management conclusions;
- detailed appendices and definitions.

Download the working Cohort Overview PowerPoint (historical reference: `sandbox:[session]/MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R1_20260904.pptx`; referenced bytes not established here)

Download the slide-level source register (historical reference: `sandbox:[session]/MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R1_20260904_SOURCE_REGISTER.csv`; referenced bytes not established here)

## Current completion status

The **content architecture, analytical narrative, quantitative exhibits, Power BI evidence selection, and first complete PPTX build are done**.

The current PPTX is explicitly a **working build**, not the final presentation release. I have not yet completed the mandatory render-and-inspect pass. The automated geometry review flagged several possible text overlaps and table-boundary warnings. Some are expected false positives—such as deliberate image overlays and text inside metric cards—but several slides require rendered inspection and potentially localized resizing. I have therefore not yet exported or represented a PDF as final.

The remaining production work is bounded to:

1. render all 53 slides;
2. inspect the montage and high-risk slides;
3. correct any real clipping, table overflow, or crowded callouts;
4. tighten the deck if any sections are unnecessarily repetitive;
5. export and visually verify the final PDF;
6. package the PPTX, PDF, source register, and review memorandum as the final Cohort Overview release.

The substantive cohort analysis itself is complete enough to support that finalization; the remaining work is presentation QA rather than analytical discovery.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7b44498b-ae4d-4d38-819e-be165ed2dbcc"></a>
## Andrew / user · C118-M00120

C118-M00120 · 2026-09-04T14:49:16.447000-04:00 · active path

Preceding visible parent: [C118-M00119](part-06.md#m-b795f5c0-aac8-4ea8-96e9-3b15dd4dba59)

<!-- BEGIN_SOURCE_MESSAGE -->
please produce a pdf for me to review. This is looking very nice. I will review the pdf for errors.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1e9e9ae4-5d7d-4529-b7fd-8e67c609f7e3"></a>
## Assistant · C118-M00121

C118-M00121 · 2026-09-04T14:54:02.694995-04:00 · active path

Preceding visible parent: [C118-M00120](part-06.md#m-7b44498b-ae4d-4d38-819e-be165ed2dbcc)

<!-- BEGIN_SOURCE_MESSAGE -->
The 53-page review PDF has been exported from the PowerPoint and rendered successfully for conversion verification.

Download the Initial 750-Merchant Cohort Overview — Review PDF (historical reference: `sandbox:[session]/MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R1_20260904_REVIEW.pdf`; referenced bytes not established here)
<!-- END_SOURCE_MESSAGE -->


<a id="m-702e6a39-90af-48c6-9988-d9805b834ab2"></a>
## Andrew / user · C118-M00122

C118-M00122 · 2026-09-04T15:29:10.281000-04:00 · active path

Preceding visible parent: [C118-M00121](part-06.md#m-1e9e9ae4-5d7d-4529-b7fd-8e67c609f7e3)

<!-- BEGIN_SOURCE_MESSAGE -->
Please use the zip I provided to update the canonical source of truth and output that as an artifact for our GitHub publication. Also, generate a detailed business requirements document and validation report for our power bi build. It should be detailed and cover all aspects of the build and validation. These need to be high level and ready to support the GitHub publication.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cfaa0cf4-3985-47e3-87d9-cff9087f787d"></a>
## Assistant · C118-M00123

C118-M00123 · 2026-09-04T16:29:10.641421-04:00 · active path

Preceding visible parent: [C118-M00122](part-06.md#m-702e6a39-90af-48c6-9988-d9805b834ab2)

<!-- BEGIN_SOURCE_MESSAGE -->
# GitHub publication-support package completed

I processed the latest project and owner-evidence ZIPs as a controlled update to the prior Power BI baseline. The resulting package preserves the accepted R26 authority, incorporates the current client-facing PBIX and finalized P01–P04 evidence, updates the canonical implementation state, and adds publication-grade business requirements, validation, traceability, and release-control documentation.

## Primary deliverable

Download the complete GitHub publication-support package (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R1_20260904.zip`; referenced bytes not established here)

Download the package SHA-256 sidecar (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R1_20260904.zip.sha256`; referenced bytes not established here)

Open the package README (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R1_20260904/README.md`; referenced bytes not established here)

Open the ZIP validation report (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R1_20260904_ZIP_VALIDATION_REPORT.md`; referenced bytes not established here)

Open the machine-readable ZIP validation report (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R1_20260904_ZIP_VALIDATION_REPORT.json`; referenced bytes not established here)

### Package identity

| Control | Result |
|---|---:|
| Package | `MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R1_20260904.zip` |
| Bytes | 31,021,709 |
| SHA-256 | `e83d820e89290beae306fdb2abb784ca054828dc9fce22430cdd1c39bb8574be` |
| ZIP entries | 43 |
| Payload-manifest rows | 41 |
| ZIP CRC | PASS |
| Clean extraction | PASS |
| Manifest reconciliation | PASS |
| SHA256SUMS reconciliation | PASS |
| Unsafe paths | 0 |
| Duplicate paths | 0 |
| Case-fold collisions | 0 |
| Symlinks | 0 |
| Encrypted members | 0 |
| Maximum archive path | 133 characters |
| Client-facing PBIX identity | PASS |

The package intentionally excludes the raw owner-evidence archive and internal project ZIP. It contains the public-candidate PBIX, publication documents, structured registers, manifests, and a bounded set of curated Power BI evidence.

## Canonical source of truth — R5

The prior canonical implementation register has been advanced to **R5**. It now records:

- the market-facing `MSBF Merchant Credit Intelligence` identity;
- Module 2 `v2.1.0-rc2` release scope;
- accepted R26 M2.5–M2.12/G3-v2 authority;
- the four visible report pages and hidden P02 diagnostic page;
- current physical PBIX composition;
- model, page, visual, binding, DAX, interaction, and evidence inventories;
- current R1 successor source populations;
- finalized P01–P04 implementation states;
- all owner-confirmed corrections;
- requirements and validation status;
- publication boundaries and prohibited interpretations;
- remaining persistence and publication gates.

### Canonical artifacts

Download the canonical source-of-truth workbook (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_CANONICAL_SOURCE_OF_TRUTH_R5_20260904.xlsx`; referenced bytes not established here)

Open the canonical source of truth in Markdown (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_CANONICAL_SOURCE_OF_TRUTH_R5_20260904.md`; referenced bytes not established here)

Download the machine-readable current-state record (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_CANONICAL_CURRENT_STATE_R5_20260904.json`; referenced bytes not established here)

The workbook contains the detailed registers and summary views needed for future maintenance, audit, controlled publication, and successor development. Its formula-error scan returned zero errors.

## Power BI Business Requirements Document

The BRD is a detailed, publication-ready description of the product and its governing requirements. It covers:

- business context, objectives, audiences, and success criteria;
- included and excluded release scope;
- authority and deterministic-synthetic-evidence principles;
- scenario and temporal interpretation;
- product and semantic-model architecture;
- source-population and data-quality requirements;
- page-level requirements for P01 through P04;
- interaction and narrative requirements;
- accessibility requirements;
- integrity, maintainability, usability, privacy, and security controls;
- validation and acceptance requirements;
- release and change-management requirements;
- the structured requirements baseline and current release artifacts.

### BRD downloads

Download the Business Requirements Document — PDF (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_BUSINESS_REQUIREMENTS_DOCUMENT_R1_20260904.pdf`; referenced bytes not established here)

Download the editable Business Requirements Document — DOCX (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_BUSINESS_REQUIREMENTS_DOCUMENT_R1_20260904.docx`; referenced bytes not established here)

Open the Business Requirements Document — Markdown (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_BUSINESS_REQUIREMENTS_DOCUMENT_R1_20260904.md`; referenced bytes not established here)

The final BRD PDF is 15 pages and passed document-render and PDF preflight inspection.

## Power BI Validation Report

The validation report is a detailed independent-style assessment of the current release candidate. It covers:

- validation objectives, scope, authority, and evidence hierarchy;
- exact system-under-test identity;
- physical PBIX and package-integrity validation;
- source authority and release-identity validation;
- source-population and exact-key validation;
- semantic-model and report-binding validation;
- page-level P01 and P02 validation;
- P03 narrative, lifecycle, tooltip, scenario-isolation, and operational QA;
- P04 servicing, setup, execution, reconciliation, certification, and interaction QA;
- accessibility and logical tab-order validation;
- temporal and interpretation-boundary controls;
- owner-evidence and publication-package validation;
- findings, observations, remaining gates, and release recommendation;
- the complete control summary and companion-register inventory.

### Validation-report downloads

Download the Power BI Validation Report — PDF (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_VALIDATION_REPORT_R1_20260904.pdf`; referenced bytes not established here)

Download the editable Power BI Validation Report — DOCX (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_VALIDATION_REPORT_R1_20260904.docx`; referenced bytes not established here)

Open the Power BI Validation Report — Markdown (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_VALIDATION_REPORT_R1_20260904.md`; referenced bytes not established here)

The final validation PDF is 23 pages and passed document-render and PDF preflight inspection.

## Structured requirements, validation, and traceability registers

Download the Business Requirements Register (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_BUSINESS_REQUIREMENTS_REGISTER_R1_20260904.csv`; referenced bytes not established here)

Download the Requirements Traceability Matrix (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_REQUIREMENTS_TRACEABILITY_MATRIX_R1_20260904.csv`; referenced bytes not established here)

Download the Validation Control Register (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_VALIDATION_CONTROL_REGISTER_R5_20260904.csv`; referenced bytes not established here)

Download the Release Artifact Register (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_RELEASE_ARTIFACT_REGISTER_R5_20260904.csv`; referenced bytes not established here)

Open the publication-support checksum register (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_PUBLICATION_SUPPORT_SHA256SUMS_20260904.txt`; referenced bytes not established here)

The resulting structured baseline contains:

| Register | Current state |
|---|---:|
| Business requirements | 142 |
| Verified requirements | 140 |
| Deferred requirements | 1 |
| Pending requirements | 1 |
| Validation controls | 47 |
| PASS | 45 |
| Deferred | 1 |
| Pending | 1 |

## Client-facing Power BI release candidate

Download `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix` (historical reference: `sandbox:[session]/msbf_github_publication/MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R1_20260904/release/MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix`; referenced bytes not established here)

| Identity control | Value |
|---|---|
| PBIX bytes | 27,635,325 |
| PBIX SHA-256 | `d3fd07497e25bb8cb2fed76cd595344dad6f482e8ef61beeac958a493b57ca36` |
| Visible pages | P01–P04 |
| Hidden diagnostic page | P02-DIAG |
| Total physical pages | 5 |
| Visuals | 96 |
| Report bindings | 221 |
| Current successor/shared binding coverage | 100% |
| Predecessor-fact bindings | 0 |
| Application-scenario paths | 1,500 |
| Funded paths | 130 |
| Monitoring rows | 15,600 |
| Monitoring days per funded path | 120 |
| G3-v2 certification | 70 PASS / 0 FAIL |

## Publication position

This package is **ready to support GitHub publication**, but it does not itself execute or authorize the public release. Two controlled gates remain open:

1. Complete the portfolio-wide Power BI refresh, save, close, reopen, and P01–P04 nonregression check after the report build is finalized.
2. Regenerate the final persisted PBIX hash and release manifests if that gate changes the physical file, then perform the separately authorized GitHub publication and public-supersession action.

Until those gates pass, the correct status is:

```text
Publication-support package       COMPLETE / VALIDATED
Canonical source of truth         R5 CURRENT
Business requirements             COMPLETE
Requirements traceability         COMPLETE
Validation report                 COMPLETE
P01–P04 page production           PASS / FROZEN
Final persistence gate            DEFERRED
GitHub publication                NOT YET EXECUTED
Public supersession               NOT YET ACTIVATED
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-a93b9d78-ebd5-472b-be54-763fb4c7d724"></a>
## Andrew / user · C118-M00124

C118-M00124 · 2026-09-04T16:37:00.150000-04:00 · active path

Preceding visible parent: [C118-M00123](part-06.md#m-cfaa0cf4-3985-47e3-87d9-cff9087f787d)

<!-- BEGIN_SOURCE_MESSAGE -->
The latest captures today were after save, close, reopen. Consider that closed and the current package final. If you'd like to add something to the package to that end, please update and re-provide the zip. After this, let's hand this off to the audit/publication chats.
<!-- END_SOURCE_MESSAGE -->
