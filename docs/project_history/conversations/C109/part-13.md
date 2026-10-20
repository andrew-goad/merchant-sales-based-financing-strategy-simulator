# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 13 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-12.md)
[Next part](part-14.md)

<a id="m-483574eb-1372-4058-9274-33d0427d8ff6"></a>
## Assistant · C109-M00337

C109-M00337 · 2026-08-26T19:58:45.184591-04:00 · active path

Preceding visible parent: [C109-M00336](part-12.md#m-c8c70bb5-f6a9-4859-8259-2e7a3be34c70)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **For the slicer, a calculated column is the better object.** The measure we created for the card was appropriate because the card needed one scalar value from the current filter context. But a slicer needs a **column containing one value per merchant row**.

So I would keep the existing `P03 Merchant Name` measure for the profile card, and add a new presentation column on `DimMerchant` specifically for selection.

Use:

```DAX
P03 Merchant Label =
VAR _Merchant =
    'DimMerchant'[synthetic_business_name]
RETURN
    IF (
        ISBLANK ( _Merchant ),
        BLANK (),
        RIGHT ( _Merchant, 6 )
    )
```

That should produce:

```text
000002
000012
000221
000749
```

Then replace `synthetic_business_name` in the Merchant slicer with `P03 Merchant Label`.

After that:

1. Keep the slicer as **Dropdown**.
2. Turn **Search** on.
3. Keep **Single select = On**.
4. Keep **Select all = Off**.
5. Test by typing `749` or `000749`.

I would **not replace the card measure**. The two objects serve different purposes:

- `P03 Merchant Label` column → slicer/search/listing.
- `P03 Merchant Name` measure → scalar Merchant ID display in the profile card.

That is a clean model pattern and avoids the table-expansion problems we've already seen when measures are used where row-level attributes belong.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8f9fb24b-6225-4ed2-9fd7-0ab7f8be87c5"></a>
## Andrew / user · C109-M00338

C109-M00338 · 2026-08-26T20:07:58.452000-04:00 · active path

Preceding visible parent: [C109-M00337](part-13.md#m-483574eb-1372-4058-9274-33d0427d8ff6)

<!-- BEGIN_SOURCE_MESSAGE -->
ok, let's move on to the next visuals beyond these Merchant request & decision and Funded terms.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a0c5deab-488d-4b97-bddd-07d7112f4a5c"></a>
## Assistant · C109-M00339

C109-M00339 · 2026-08-26T20:08:05.385959-04:00 · active path

Preceding visible parent: [C109-M00338](part-13.md#m-8f9fb24b-6225-4ed2-9fd7-0ab7f8be87c5)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. At this point, **Merchant request & decision** and **Funded terms** establish the origination side of the story. The next visuals should move deliberately into **performance, servicing, and current posture** rather than adding more origination detail.

I would build the remainder of P03 in this order:

1. **Performance trajectory** — one longitudinal chart showing how the selected merchant’s funded advance behaves from funding through the selected Observation date. Start with **Current exposure** as the primary line. If the account is not funded, the visual should naturally remain blank. The X-axis should be the daily/monitoring date, and unlike P02, it should stop at the selected Observation date so P03 truly represents the merchant “as of” that date.

2. **Remittance performance** — a second lifecycle chart immediately below or beside Exposure. I would use **Remittance fulfillment / pace ratio** against a 100% reference line, because that tells a merchant-specific servicing story much better than cumulative dollars alone. We already know from P02 that this measure behaves meaningfully over time.

3. **Current account posture** — a compact selected-date card/table, not another chart. This should answer: current exposure, remittance fulfillment, days since last remittance, payoff slippage, monitoring status, active-alert count, open-servicing count, and paid-off status where applicable. This is the point-in-time complement to the two lifecycle charts.

4. **Servicing & exceptions history** — a small event-oriented table showing meaningful interventions/exceptions through the selected date. I would not try to expose every technical servicing field. The eventual columns should probably be something like event date, event/type, status, reason, and perhaps exposure or days open if available. This becomes the merchant-level precursor to the dedicated P05/P07 servicing page later.

The important structural point is that **P03 should not become another P02**. P02 compares a cohort’s aggregate lifecycle. P03 should answer, “For this merchant, what was requested, what was funded, how has that advance performed, and what operational attention has it required?”

So visually, I would now aim for this page story:

```text
Relationship profile

Merchant request & decision
Funded terms

Performance trajectory        Current account posture
Remittance performance        Servicing & exceptions
```

For the **very next build step**, create only the first chart: **Performance trajectory**.

Use the daily/account performance table that contains the merchant/account lifecycle. Set:

- **X-axis:** monitoring date / observation date
- **Y-axis:** current exposure / receivable exposure
- **Title:** `Exposure`
- Filter behavior: Merchant and Scenario should filter it.
- Observation-date slicer should define the **maximum visible date**, not select only one point.

That last point matters. If the Observation date slicer currently filters the chart down to one day, we will need a report-owned measure that preserves dates **up to** the selected observation date rather than only the selected date itself.

Build the raw Exposure line first and show me what happens when Merchant `000749`, Baseline, and 8/16/2026 are selected. From that behavior we can determine whether the existing model already gives us the correct “through selected date” trajectory or whether we need a bounded P03 lifecycle measure.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4f660a64-fe73-4b24-ae19-6c90f29b9064"></a>
## Andrew / user · C109-M00340

C109-M00340 · 2026-08-26T20:12:11.461000-04:00 · active path

Preceding visible parent: [C109-M00339](part-13.md#m-a0c5deab-488d-4b97-bddd-07d7112f4a5c)

**Editorial record note:** Attachment references: Pasted text(20260827-001156).txt

<!-- BEGIN_SOURCE_MESSAGE -->
i am not sure which dim table may have daily detail. i know we had this daily table 
<!-- END_SOURCE_MESSAGE -->


<a id="m-5f561640-ac9b-4594-85ff-1bd1f2ae5e2e"></a>
## Assistant · C109-M00341

C109-M00341 · 2026-08-26T20:12:30.510083-04:00 · active path

Preceding visible parent: [C109-M00340](part-13.md#m-4f660a64-fe73-4b24-ae19-6c90f29b9064)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **this is the daily-detail table we want**, and it is much richer than just an exposure source.

The grain is effectively **one application/account × scenario × monitoring date**. The table carries `merchant_application_id`, `merchant_id`, `synthetic_account_id`, `scenario_code`, `monitoring_day_index`, and `monitoring_date`, followed by daily sales, remittance, balance, exposure, status, alert, and payoff fields. [export reference: filecite | turn42file3 | L44-L46]

For Merchant Relationship 360, the strongest fields in it are:

- `monitoring_date` — lifecycle X-axis
- `receivable_balance_after` — best candidate for the contractual remaining receivable trajectory
- `principal_exposure_proxy` — principal-oriented exposure trajectory
- `actual_remittance_amount` and `expected_due_today_amount` — daily payment behavior
- `cumulative_remittance_amount` and `cumulative_expected_remittance_amount`
- `cumulative_pace_ratio` — very useful merchant performance indicator
- `days_since_last_positive_remittance`
- `trailing_7_day_remittance_amount` / `trailing_30_day_remittance_amount`
- `monitoring_status_code`
- the daily/cumulative pace, zero-sales, liquidity, and horizon alert flags
- `paid_off_flag`

And the data clearly does contain meaningful daily performance states rather than just static endpoint records. For example, rows can move through `CURRENT`, `WATCH`, `UNDERPERFORMING`, and more severe states as cumulative pace and shortfall conditions change. [export reference: filecite | turn42file0 | L10-L12] [export reference: filecite | turn42file2 | L32-L35]

### One correction to my prior recommendation

I would **not** start by plotting a generic existing “Current Exposure” measure. Now that we have inspected the physical daily data, we should deliberately decide which balance concept belongs on the merchant 360.

For this page I recommend the first chart be:

**`Receivable trajectory`**

with:

- **X-axis:** `monitoring_date`
- **Y-axis:** `receivable_balance_after`

That tells the cleanest intuitive story: *how much of the contractual receivable remained over time*. Then, if useful, `principal_exposure_proxy` can become either a second line or a separate compact metric because it is a different economic concept.

### But don't build it quite yet

There is one Power BI modeling issue we should solve first: your **Observation date slicer** currently represents an as-of date. If it directly filters this daily fact table, selecting `8/16/2026` will likely leave us with **only the 8/16 row**, destroying the historical line.

So the next step is very small and diagnostic.

In Power BI, find the table containing these fields. It may be named something like a monitoring/daily fact rather than a `Dim` table. You do **not** need a dimension table for the daily values themselves.

Once you find it, create a temporary line chart with:

**X-axis:** `monitoring_date`  
**Y-axis:** `receivable_balance_after`

Do **not** worry about formatting. Keep your current Merchant `000749`, Scenario `Baseline`, and Observation date `8/16/2026` selections.

Then tell me exactly what you see:

- one point on 8/16,
- a full history through 8/16,
- a full history including dates after 8/16,
- or no data.

That one empirical test will tell us precisely how to construct the bounded P03 as-of measure instead of guessing at the relationship behavior.
<!-- END_SOURCE_MESSAGE -->


<a id="m-46124838-79b4-453a-aa5e-c14c4a6928c5"></a>
## Andrew / user · C109-M00342

C109-M00342 · 2026-08-26T20:14:46.594000-04:00 · active path

Preceding visible parent: [C109-M00341](part-13.md#m-5f561640-ac9b-4594-85ff-1bd1f2ae5e2e)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: d6ca3e58-e83d-4d4a-8022-4f0579ce5ef2.png; 449373d5-18a9-4f61-835f-2f326e0d0671.png

<!-- BEGIN_SOURCE_MESSAGE -->
these are all i see pertaining to that request
<!-- END_SOURCE_MESSAGE -->


<a id="m-9da7cc5a-9aec-45be-a179-14f4b54c0a08"></a>
## Assistant · C109-M00343

C109-M00343 · 2026-08-26T20:14:49.870160-04:00 · active path

Preceding visible parent: [C109-M00342](part-13.md#m-46124838-79b4-453a-aa5e-c14c4a6928c5)

<!-- BEGIN_SOURCE_MESSAGE -->
That explains it. **The physical daily monitoring fact is not exposed in your visible Fields pane.** What you are seeing is the curated semantic layer:

- `DimAccountAdvance[monitoring_start_date]`
- `DimMonitoringStatus[...]`
- `ModelParameters → 04 Performance → [Remaining Receivable As Of]`

The daily source you pasted clearly contains `monitoring_date`, `receivable_balance_after`, `actual_remittance_amount`, `cumulative_pace_ratio`, etc., but those fields are not presently visible to you in the report model. [export reference: filecite | turn42file3 | L44-L46]

That also tells me something important: **`Remaining Receivable As Of` was almost certainly created specifically to abstract the hidden daily fact.** So I would not start unhiding things indiscriminately.

### What I want you to do next

Let's inspect what `[Remaining Receivable As Of]` actually does.

1. Click **Remaining Receivable As Of**.
2. Copy the DAX formula from the formula bar.
3. Paste it here.

That will tell me the name of the hidden daily fact table and, more importantly, how the existing model intentionally handles the Observation Date/as-of boundary.

I suspect we'll find something along the lines of a hidden `Fact...DailyMonitoring` table being filtered to the selected observation date. If so, rather than exposing the raw table, we can build the **merchant performance/lifecycle measures in `04 Performance`**, consistent with the semantic-layer pattern you've already established.

And I now think that is probably the better architecture for P03: keep the ugly physical daily fact hidden and expose a small, deliberate merchant-360 measure surface.
<!-- END_SOURCE_MESSAGE -->


<a id="m-242646aa-0a61-41e6-9bff-509f29ba8ca9"></a>
## Andrew / user · C109-M00344

C109-M00344 · 2026-08-26T20:15:42.561000-04:00 · active path

Preceding visible parent: [C109-M00343](part-13.md#m-9da7cc5a-9aec-45be-a179-14f4b54c0a08)

<!-- BEGIN_SOURCE_MESSAGE -->
why do we have so many hidden tables? i know you said there is a reason, but this is not a production environment. this is for a github portfolio and it is slowing us down and adding unnecessary duplication in having to create new columns / new measures
<!-- END_SOURCE_MESSAGE -->


<a id="m-575f653d-edf8-40cf-9443-c6b4c27f38c9"></a>
## Assistant · C109-M00345

C109-M00345 · 2026-08-26T20:15:48.315084-04:00 · active path

Preceding visible parent: [C109-M00344](part-13.md#m-242646aa-0a61-41e6-9bff-509f29ba8ca9)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree with your concern. The current level of hiding made sense when we were treating the semantic model like a tightly controlled production-facing dataset, but it is now imposing a real construction tax on a GitHub portfolio artifact.

The original rationale was sound: hide fact/bridge/technical tables so report builders use a curated semantic layer, reduce accidental misuse of grain, and avoid exposing implementation plumbing. That is useful in a production self-service model with many report authors. Here, though, **you are the only builder, the model is synthetic, and we are actively demonstrating analytical depth rather than protecting novice users from the schema**.

What we are seeing in P03 is the downside: the physical model already contains the exact daily fields we need, but because the fact is hidden we keep manufacturing `P03 ...` measures and presentation columns just to regain access to data that already exists. That adds duplication, slows iteration, increases the adapter inventory, and paradoxically makes the portfolio harder to understand.

I would therefore recalibrate now rather than keep fighting the model.

### Recommended approach: selective unhiding, not “show everything”

For the remainder of the portfolio build, I would use a **builder-accessible semantic model**:

- Keep pure technical/control tables hidden: hashes, manifests, bridge plumbing, helper/calculation tables, internal lineage tables, etc.
- Keep dimensions visible.
- **Unhide analytically meaningful fact tables needed for report construction**, including the daily monitoring/performance fact we just identified.
- Within those facts, hide genuinely technical identifiers/hash columns if they clutter the Fields pane, but expose business-meaningful fields such as `monitoring_date`, balances, remittances, pace ratios, statuses and alert flags.
- Continue creating measures when aggregation/context logic is genuinely required.
- Stop creating measures merely because an otherwise-valid column happens to be hidden.
- Continue using calculated presentation columns only where we genuinely want a cleaner label such as `Working capital`, `Processor embedded`, `Final offer`, or `A01`.

That is a much better division.

For example, this:

```text
receivable_balance_after
monitoring_date
cumulative_pace_ratio
monitoring_status_code
paid_off_flag
```

should be available to us directly for constructing merchant-level tables and charts.

Whereas something such as:

```text
Remaining Receivable As Of
```

is still useful as a measure because **“as of selected date” is actual filter-context logic**, not merely access to a hidden column.

### This does not mean abandoning governance

We would not change:

- sources,
- Power Query logic,
- relationships,
- grains,
- accepted governed-measure formulas,
- scenario interpretation,
- business methods,
- or underlying values.

We would be changing **model presentation metadata — visibility** to make the accepted model practical to build against.

That is materially different from changing the model's analytical truth.

And given Audit just ratified a build-first model specifically because physical construction was surfacing issues faster than theoretical preapproval, **this is exactly the kind of construction friction we should solve empirically rather than continue compensating for.**

### I would also stop treating every hidden-field need as a reason for another adapter

Our operating rule should become:

> **Need the actual row-level attribute? Expose the accepted field.  
> Need a calculation or context transformation? Create a measure.  
> Need human-readable categorical presentation? Create a presentation column only when necessary.**

That eliminates a lot of the duplication we've created.

For P03 specifically, I now recommend that we **unhide the daily monitoring fact** rather than build a collection of P03 measures around it. Then we can construct Exposure, remittance performance, status history, alerts, and servicing behavior directly from its real fields.

We should first identify its exact table name from `[Remaining Receivable As Of]` or from Model view, then unhide that table and decide which of its business fields should remain exposed. I would not wait for another Audit cycle to do that; log it as a **presentation-visibility correction within the authorized wave** and include it in the frozen model delta at the next combined audit gate. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-2300ea39-8b07-44b8-a9d8-206cc89271d2"></a>
## Andrew / user · C109-M00346

C109-M00346 · 2026-08-26T20:18:09.517000-04:00 · active path

Preceding visible parent: [C109-M00345](part-13.md#m-575f653d-edf8-40cf-9443-c6b4c27f38c9)

<!-- BEGIN_SOURCE_MESSAGE -->
i am unhiding factaccountdaily for this exercise
<!-- END_SOURCE_MESSAGE -->


<a id="m-8ca68cc3-5585-414e-ad67-2504c3df3fdb"></a>
## Assistant · C109-M00347

C109-M00347 · 2026-08-26T20:18:14.365295-04:00 · active path

Preceding visible parent: [C109-M00346](part-13.md#m-2300ea39-8b07-44b8-a9d8-206cc89271d2)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. For this exercise, that is the right move.

Now that `FactAccountDaily` is visible, we can stop proxying its row-level fields through extra measures and build directly from the actual daily grain.

For the next P03 visual, create a **Line chart** with:

- **X-axis:** `FactAccountDaily[monitoring_date]`
- **Y-axis:** `FactAccountDaily[receivable_balance_after]`
- **Title:** `Receivable trajectory`

Keep Merchant `000749`, Scenario `Baseline`, and Observation date `8/16/2026` selected.

The key test is the Observation-date behavior. Tell me whether the chart shows:

1. only 8/16,
2. the full history through 8/16,
3. the full history including dates after 8/16, or
4. no data.

That result will determine whether we can use the raw field directly or need one bounded “through selected date” measure.
<!-- END_SOURCE_MESSAGE -->


<a id="m-71d7f9d6-0e24-4d10-9859-ee6cc7e3bfc5"></a>
## Andrew / user · C109-M00348

C109-M00348 · 2026-08-26T20:19:33.241000-04:00 · active path

Preceding visible parent: [C109-M00347](part-13.md#m-8ca68cc3-5585-414e-ad67-2504c3df3fdb)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: a8d5e40c-913b-4fdc-8fb7-16207ecc7957.png

<!-- BEGIN_SOURCE_MESSAGE -->
receivable balance after will need a measure: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-5d589e6b-33b9-43ec-b0da-abe6b7f3de8b"></a>
## Assistant · C109-M00349

C109-M00349 · 2026-08-26T20:19:40.803453-04:00 · active path

Preceding visible parent: [C109-M00348](part-13.md#m-71d7f9d6-0e24-4d10-9859-ee6cc7e3bfc5)

<!-- BEGIN_SOURCE_MESSAGE -->
Right — because the model has **Discourage implicit measures** enabled, Power BI won’t let you drag `receivable_balance_after` directly into Values. We should create an explicit measure.

For this chart, start with the simplest correct aggregation:

```DAX
P03 Receivable Balance =
SUM (
    FactAccountDaily[receivable_balance_after]
)
```

Then build the line chart with:

- **X-axis:** `FactAccountDaily[monitoring_date]`
- **Y-axis:** `[P03 Receivable Balance]`
- **Title:** `Receivable trajectory`

Keep Merchant `000749`, Scenario `Baseline`, Observation date `8/16/2026`.

This measure is appropriate because at the selected merchant/application/scenario/date grain there should effectively be one daily row, while `SUM` also remains safe if the visual context ever spans more than one account.

Now the important part is still the Observation-date behavior. Once the chart renders, tell me whether it shows only 8/16, history through 8/16, or dates beyond 8/16. That will tell us whether we need a second bounded measure for “through selected date.”
<!-- END_SOURCE_MESSAGE -->


<a id="m-52da973d-55dd-4084-9135-0d20653a5217"></a>
## Andrew / user · C109-M00350

C109-M00350 · 2026-08-26T20:27:25.495000-04:00 · active path

Preceding visible parent: [C109-M00349](part-13.md#m-5d589e6b-33b9-43ec-b0da-abe6b7f3de8b)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 860ca349-3040-42ed-8607-d3212321af82.png

<!-- BEGIN_SOURCE_MESSAGE -->
Yes, so far it doesn't seem like observation date is very needed here.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ef33f1cb-cc53-4870-88b6-07ff53946d73"></a>
## Assistant · C109-M00351

C109-M00351 · 2026-08-26T20:27:32.240483-04:00 · active path

Preceding visible parent: [C109-M00350](part-13.md#m-52da973d-55dd-4084-9135-0d20653a5217)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree. **For this P03 design, the Observation date slicer is not earning its space right now.**

The `Receivable Trajectory` is already showing the merchant’s full lifecycle from funding through payoff, and that is arguably more useful for a Merchant 360 page than forcing the user to inspect one historical as-of state at a time.

What the screenshot suggests is a cleaner P03 contract:

- **Merchant** selects the relationship.
- **Scenario** selects the scenario-qualified path.
- The page then shows the **full available journey** for that merchant/scenario.
- The request/decision and funded-terms tables provide the fixed origination facts.
- The lifecycle visuals show the full subsequent performance history.

That is simpler and more intuitive.

I would therefore **remove Observation date from P03** unless we later build a point-in-time servicing/status panel that genuinely needs an as-of selector. We already have P01 for “what did this cohort look like on a selected date?” P03 can instead specialize in **complete merchant history**.

Your current `Receivable Trajectory` also looks good structurally. I would keep it and proceed to the second longitudinal visual:

### Next visual: Remittance performance

Use `FactAccountDaily` and create:

```DAX
P03 Cumulative Pace Ratio =
AVERAGE (
    FactAccountDaily[cumulative_pace_ratio]
)
```

Then create a line chart with:

- **X-axis:** `FactAccountDaily[monitoring_date]`
- **Y-axis:** `[P03 Cumulative Pace Ratio]`
- **Title:** `Remittance performance`
- Format as percentage.
- Add a constant/reference line at **100%**.

For a single merchant/account/day, `AVERAGE` simply returns the daily value; it also behaves sensibly if the context ever contains more than one row.

That chart answers a different question from receivable balance:

> **Is the merchant remitting ahead of, at, or behind the contractual pace?**

After that, I’d build a third visual around **Monitoring status / servicing attention**, probably as a status timeline or compact event table rather than another KPI card.

So I would make one page-level change now: **delete the Observation date slicer**, widen Merchant and Scenario slightly, and let P03 become a full-journey Merchant 360 page.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6374bef8-e6cf-4a68-9dbe-2aa7195ed8b7"></a>
## Andrew / user · C109-M00352

C109-M00352 · 2026-08-26T20:41:05.169000-04:00 · active path

Preceding visible parent: [C109-M00351](part-13.md#m-ef33f1cb-cc53-4870-88b6-07ff53946d73)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: b49998bb-007e-405e-aae4-353613c1b3ec.png

<!-- BEGIN_SOURCE_MESSAGE -->
current layout and space remaining - debating how to organize this to make the story clear and best use white space for the remaining visuals.
<!-- END_SOURCE_MESSAGE -->


<a id="m-06077f78-5dbd-4e07-9989-ff3dfd5ec22f"></a>
## Assistant · C109-M00353

C109-M00353 · 2026-08-26T20:41:08.025813-04:00 · active path

Preceding visible parent: [C109-M00352](part-13.md#m-6374bef8-e6cf-4a68-9dbe-2aa7195ed8b7)

<!-- BEGIN_SOURCE_MESSAGE -->
I would reorganize **before adding anything else**. The page is strong, but the current geometry gives the two lifecycle charts almost the entire lower half while the actual “360” operational conclusion still has nowhere obvious to live.

The clearest story is:

**Who is this merchant? → What did they request and receive? → How did the advance perform? → What happened operationally?**

I would keep the left profile rail exactly as the anchor, then make the right side three horizontal story bands.

### Recommended final P03 architecture

**Top band — Origination & funding**  
Keep **Merchant request & decision** and **Funded terms** where they are. They work very well as two compact rows. I would not make them taller.

**Middle band — Performance**  
Keep the two charts side-by-side:

**Receivable trajectory** | **Remittance performance**

But make them somewhat **shorter vertically**. They currently occupy roughly 350 px of height; I think ~230–250 px is enough. These curves are simple enough that we don't need that much plotting area.

That creates a substantial new band underneath them.

**Bottom band — Operational outcome**  
Use the reclaimed width for two complementary visuals:

**Monitoring journey** | **Servicing & exceptions**

That completes the story instead of adding more financial charts.

Conceptually:

```text
┌────────────────────────────────────────────────────────────────────┐
│ Merchant request & decision                                        │
├────────────────────────────────────────────────────────────────────┤
│ Funded terms                                                       │
├──────────────────────────────┬─────────────────────────────────────┤
│ Receivable trajectory        │ Remittance performance              │
│                              │                                     │
├──────────────────────────────┼─────────────────────────────────────┤
│ Monitoring journey           │ Servicing & exceptions              │
└──────────────────────────────┴─────────────────────────────────────┘
```

### What I want `Monitoring journey` to do

This should **not be another line chart of a number merely because we can plot one**.

`FactAccountDaily` contains `monitoring_status_code`, and the physical data shows meaningful transitions among statuses such as `CURRENT`, `WATCH`, `UNDERPERFORMING`, and `SEVERE_SHORTFALL`. [export reference: filecite | turn42file0 | L10-L12] [export reference: filecite | turn42file2 | L32-L35]

I would like this visual to answer:

> **When did this merchant move into and out of elevated monitoring states?**

A status-over-time visual could be excellent here. We need to experiment with the native Power BI choices before deciding whether that becomes a stepped line, compact status table, or something else.

### `Servicing & exceptions`

This should answer:

> **What actually required attention?**

The daily data already carries alert conditions such as daily shortfall, cumulative pace deterioration, zero-sales streak, liquidity stress, horizon overrun, and paid-off state. [export reference: filecite | turn42file3 | L44-L46]

If the model also has actual servicing-event detail elsewhere, even better—we should use that rather than pretending daily alert flags are servicing actions. This section could ultimately be a compact event table.

### I would also remove Observation date now

Seeing the page physically reinforces my earlier recommendation. It is occupying prime header space but **does not control the story you're actually presenting**. Your two lifecycle charts appropriately show the full merchant journey.

P03's contract is becoming:

> **Select Merchant + Scenario → see that merchant's complete modeled relationship and financing journey.**

That's cleaner than mixing full-lifecycle charts with an apparently operative as-of-date slicer.

Removing it also lets **Merchant** and **Scenario** breathe in the header.

### One other thing I would change now

The footer still says:

> “The selected run cohort remains fixed as observation period advances...”

That's P02 language and is now **wrong for P03**.

P03 needs merchant-specific boundary language. Eventually something closer to:

> **Temporal boundary:** Merchant lifecycle dates after 2026-07-23 reflect governed deterministic-synthetic forward monitoring through 2026-11-22, not additional realized source history; **Interpretation boundary:** Deterministic synthetic evidence.

That should be corrected before we forget.

So my next move would **not** be another measure. I would first:

1. Remove **Observation date**.
2. Shorten both lifecycle charts enough to establish a bottom operational band.
3. Update the P03 temporal-boundary footer.
4. Then build **Monitoring journey** in the lower-left space.

That gives us a deliberate four-act page rather than simply filling remaining white space.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6b0f315f-2059-4f9c-9d49-b4faf38c7962"></a>
## Andrew / user · C109-M00354

C109-M00354 · 2026-08-26T20:48:22.871000-04:00 · active path

Preceding visible parent: [C109-M00353](part-13.md#m-06077f78-5dbd-4e07-9989-ff3dfd5ec22f)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 469f4ee0-19c1-4fa5-bca3-1ed2dcedad8b.png

<!-- BEGIN_SOURCE_MESSAGE -->
how about this: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-1efce45d-5f39-4091-96eb-1b6ded91947c"></a>
## Assistant · C109-M00355

C109-M00355 · 2026-08-26T20:48:29.487374-04:00 · active path

Preceding visible parent: [C109-M00354](part-13.md#m-6b0f315f-2059-4f9c-9d49-b4faf38c7962)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **I prefer this layout.** It creates a much stronger visual hierarchy and uses the page width intelligently.

The page now reads naturally:

**Merchant context → Request/decision → Funded terms → Lifecycle performance**

And, importantly, you've created a large central/lower-left canvas for the remaining operational story without squeezing the two lifecycle charts.

A few adjustments:

- **Keep the right-side charts exactly in this stacked configuration.** Receivable Trajectory above Remittance Performance works because they share the same time axis conceptually.
- **Keep the two transaction tables where they are.** I especially like Funded terms being slightly indented beneath Request & Decision—it visually communicates progression.
- The large open center area is now an asset, not wasted space. That's where we should put **Monitoring journey** and **Servicing & exceptions**.
- I would probably add a subtle vertical divider between the central operational area and the right-hand performance charts, analogous to your divider after the Merchant profile. That will give the page three obvious zones: **Relationship | Journey/operations | Performance**.

### One change I would make to the header

Now that we've physically arranged it this way, I'm even more convinced we should remove **Observation date**.

It currently implies that `8/16/2026` governs what the user is seeing, yet both right-side charts visibly continue through November. That's an interpretation conflict.

Removing it gives you:

**Merchant 000749 | Scenario Baseline**

which accurately defines the page.

### Use the open space deliberately

I would **not** put two more large charts there.

Instead, I see the remaining center canvas roughly like this:

```text
Merchant request & decision
             Funded terms

Monitoring journey
────────────────────────────────────
[compact lifecycle/status experience]

Servicing & exceptions
────────────────────────────────────
[compact event/detail experience]
```

That asymmetry is actually desirable. The right side answers **“How did it perform quantitatively?”** while the center answers **“What happened operationally?”**

### Before building Monitoring journey

Let's fix the footer now because its current wording is inherited from P02 and no longer describes this page correctly.

I recommend:

> **Temporal boundary:** Merchant lifecycle dates after 2026-07-23 reflect governed deterministic-synthetic forward monitoring through 2026-11-22, not additional originations or realized source history; **Interpretation boundary:** Deterministic synthetic evidence

That is shorter, P03-specific, and accurately describes why a merchant selected from the 7/23 source boundary can have lifecycle observations extending into November.

Then remove Observation date, update that footer, and **we'll build Monitoring journey in the large open center space next**. I want to use the actual `FactAccountDaily` status fields for that rather than inventing another generic line chart.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b54b0502-81ec-4824-86d6-f4df71455e58"></a>
## Andrew / user · C109-M00356

C109-M00356 · 2026-08-26T20:51:42.365000-04:00 · active path

Preceding visible parent: [C109-M00355](part-13.md#m-1efce45d-5f39-4091-96eb-1b6ded91947c)

<!-- BEGIN_SOURCE_MESSAGE -->
create monitoring journey and servicing and exceptions
<!-- END_SOURCE_MESSAGE -->


<a id="m-ee5d4240-9827-4b1d-80c9-cdf0438d0178"></a>
## Assistant · C109-M00357

C109-M00357 · 2026-08-26T20:51:45.210935-04:00 · active path

Preceding visible parent: [C109-M00356](part-13.md#m-b54b0502-81ec-4824-86d6-f4df71455e58)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. With the layout you now have, I would make these **two compact operational visuals in the open center area**, rather than more large trend charts.

## 1. Monitoring journey

This should answer:

> **How did this merchant's monitoring posture change during the life of the advance?**

We already know `FactAccountDaily` contains both `monitoring_status_code` and `monitoring_status_rank`, with statuses such as CURRENT, WATCH, UNDERPERFORMING, and SEVERE_SHORTFALL. [export reference: filecite | turn42file0 | L10-L12]

### Step 1 — Create the measure

In `ModelParameters → 04 Performance`:

```DAX
P03 Monitoring Status Rank =
MAX (
    FactAccountDaily[monitoring_status_rank]
)
```

This is a legitimate measure rather than an access workaround: we need a numeric Y value to plot the categorical status through time.

### Step 2 — Create a line chart

Place it in the **upper portion of the open center area**, below Funded terms.

Use:

**X-axis**
```text
FactAccountDaily[monitoring_date]
```

**Y-axis**
```text
[P03 Monitoring Status Rank]
```

Title:

**Monitoring journey**

For now, don't worry that the Y-axis displays `1`, `2`, `3`, `4`, etc. First we want to see the physical behavior.

### Step 3 — Tooltip

Add these raw fields to the tooltip if Power BI permits them without demanding measures:

```text
FactAccountDaily[monitoring_status_code]
FactAccountDaily[primary_monitoring_reason_code]
```

If `primary_monitoring_reason_code` is hidden/unavailable, skip it for now.

Also add:

```text
[P03 Cumulative Pace Ratio]
```

This means hovering over a date can tell the user something like:

```text
Date                  8/19/2026
Status                WATCH
Reason                ...
Remittance performance 87.4%
```

That is useful operational information.

### Step 4 — Formatting

Keep this chart **short**—roughly 140–170 px high. We want it to read as a status trajectory, not compete with the two major performance charts.

Turn markers **On** if they remain readable.

Do not add a legend.

---

# 2. Servicing & exceptions

For this one, I recommend a **table**, not another chart.

And we need to distinguish two concepts carefully:

**Monitoring alerts** are daily conditions.  
**Servicing events** are actual operational actions/events.

The daily source contains flags for daily shortfall, cumulative pace deterioration, zero-sales streak, liquidity stress, horizon overrun, and paid-off status. [export reference: filecite | turn42file3 | L44-L46]

But we should **not call those servicing actions**.

So let's initially make this visual a compact **Monitoring exceptions** table, and then add actual servicing events if the model contains an appropriate servicing fact.

### Step 1 — Create these measures

```DAX
P03 Daily Shortfall =
SUM (
    FactAccountDaily[daily_shortfall_amount]
)
```

```DAX
P03 Cumulative Shortfall =
MAX (
    FactAccountDaily[cumulative_shortfall_amount]
)
```

```DAX
P03 Days Since Remittance =
MAX (
    FactAccountDaily[days_since_last_positive_remittance]
)
```

We already have:

```text
[P03 Cumulative Pace Ratio]
```

### Step 2 — Create a table

Place this beneath **Monitoring journey**.

Use:

```text
FactAccountDaily[monitoring_date]
FactAccountDaily[monitoring_status_code]
[P03 Daily Shortfall]
[P03 Cumulative Shortfall]
[P03 Cumulative Pace Ratio]
[P03 Days Since Remittance]
```

Rename the headers:

```text
Date
Status
Daily shortfall
Cumulative shortfall
Pace
Days since remittance
```

Title it:

**Monitoring exceptions**

At first this will probably contain **every monitoring day**. That's okay—we're establishing the raw behavior.

---

## 3. Then filter the exception table

We don't want 100 ordinary CURRENT rows.

Use the visual-level filter:

```text
FactAccountDaily[monitoring_status_rank]
```

and set it to whatever excludes the ordinary/current state.

Based on the data we've already inspected, rank `1` corresponds to `CURRENT`, while elevated states have higher ranks. For example, the supplied rows show CURRENT at rank 1 and UNDERPERFORMING at rank 3. [export reference: filecite | turn42file0 | L10-L12] [export reference: filecite | turn42file2 | L32-L35]

So initially set:

**monitoring_status_rank > 1**

Now the table becomes an exception history rather than a daily dump.

---

## 4. The eventual servicing component

After these two are physically working, search the Fields pane for:

```text
servicing
exception
case
action
resolution
alert
```

We know from P01/P02 that the model has servicing concepts because we've already displayed **Open servicing**. I don't want to manufacture a servicing history from monitoring flags if a proper servicing-event fact already exists.

If we find one, the final bottom visual may become:

**Servicing & exceptions**

with something like:

```text
Date | Type | Status | Reason | Resolution
```

and monitoring alerts can remain contextual rather than masquerading as servicing events.

---

### Your P03 will then read

```text
RELATIONSHIP        APPLICATION / FUNDING              PERFORMANCE

Merchant profile    Merchant request & decision        Receivable trajectory
                    Funded terms                       Remittance performance

                    Monitoring journey
                    Monitoring exceptions /
                    Servicing & exceptions
```

That's a very strong Merchant 360 story.

**Start with `P03 Monitoring Status Rank` and the Monitoring journey line chart.** Show me what the status trajectory looks like for Merchant **000749 / Baseline** before we polish its axis or build the exceptions table; the actual pattern will tell us whether a line/step-style presentation is the right native visual.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7a8e8a53-74ab-48f7-99f1-c54b92ace45a"></a>
## Andrew / user · C109-M00358

C109-M00358 · 2026-08-26T21:01:51.387000-04:00 · active path

Preceding visible parent: [C109-M00357](part-13.md#m-ee5d4240-9827-4b1d-80c9-cdf0438d0178)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 61ece78e-03e9-43ed-ac10-fe7b1c1dc85e.png

<!-- BEGIN_SOURCE_MESSAGE -->
monitoring status code and primary monitoring reason code need measures to be in the tooltips.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bfa93ec4-132e-4811-9b31-06dc56918f16"></a>
## Assistant · C109-M00359

C109-M00359 · 2026-08-26T21:01:57.235518-04:00 · active path

Preceding visible parent: [C109-M00358](part-13.md#m-7a8e8a53-74ab-48f7-99f1-c54b92ace45a)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. Because implicit measures are disabled, those text fields need explicit scalar measures for tooltips.

Create:

```DAX
P03 Monitoring Status =
VAR _Value =
    SELECTEDVALUE (
        FactAccountDaily[monitoring_status_code]
    )
RETURN
    COALESCE ( _Value, "NOT AVAILABLE" )
```

and:

```DAX
P03 Monitoring Reason =
VAR _Value =
    SELECTEDVALUE (
        FactAccountDaily[primary_monitoring_reason_code]
    )
RETURN
    COALESCE ( _Value, "NOT AVAILABLE" )
```

Then add both to the **Tooltip** well for `Monitoring journey`, along with `[P03 Cumulative Pace Ratio]` if you want the hover state to explain the status numerically.

For this chart, these measures are appropriate because each plotted point already establishes a single merchant/scenario/date context. Unlike the earlier table issue, we are not asking the measures to behave as row-level grouping attributes.

Your current chart is also useful: it shows frequent movement between ranks 1 and 2, a short rank-4 deterioration around late October, and then rank 0 after that. Before we polish the Y-axis, I want to understand what **rank 0** represents—likely paid-off/inactive or another terminal state—because that changes how we should label the journey.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9b12fe35-e026-49e0-96bd-e5835fa8eced"></a>
## Andrew / user · C109-M00360

C109-M00360 · 2026-08-26T21:13:46.917000-04:00 · active path

Preceding visible parent: [C109-M00359](part-13.md#m-bfa93ec4-132e-4811-9b31-06dc56918f16)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 6381c516-cee6-4f6f-9994-019712b2a9f8.png; 54768adc-910c-4ce4-81c0-f55b53748e5e.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-c7cfc284-896e-4e84-a86a-6d80346c351a"></a>
## Assistant · C109-M00361

C109-M00361 · 2026-08-26T21:13:50.251982-04:00 · active path

Preceding visible parent: [C109-M00360](part-13.md#m-9b12fe35-e026-49e0-96bd-e5835fa8eced)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. These tooltips validate the chart nicely:

- Rank **2 = WATCH**, with `M2_5_STATUS_WATCH`.
- Rank **4 = SEVERE_SHORTFALL**, with `M2_5_STATUS_SEVERE_SHORTFALL`.
- So the numeric trajectory is genuinely representing changes in monitoring severity rather than an arbitrary score.

The remaining question is rank **0** after the late-October severe-shortfall episode. Given that the receivable trajectory reaches zero around the same period, I strongly suspect rank 0 is the terminal/paid-off state. But we should verify rather than infer it.

Hover one of the **rank-0 dates in November** and show me the tooltip. That will tell us whether it reports `PAID_OFF`, `NOT ACTIVE`, blank, or something else.

### I would keep this visual

The physical result is better than I expected. The stepped-looking movement makes the merchant's monitoring history very easy to understand:

**Current ↔ Watch → severe shortfall → terminal state**

Once we identify rank 0, I think we should improve the Y-axis. `0 / 1 / 2 / 3 / 4` is analytically correct but not executive-friendly. Ideally the chart itself communicates the states, while the tooltip provides the exact code/reason.

One particularly interesting feature is that the late-October rank-4 event occurs while the remittance-performance chart is still around/above 100%. That's not necessarily contradictory: the monitoring framework can respond to **daily or other monitoring conditions even when cumulative pace remains healthy**. The physical daily source explicitly contains both daily-shortfall and cumulative-pace alert concepts, so we should preserve that distinction rather than assume cumulative pace alone determines status. [export reference: filecite | turn42file3 | L44-L46]

After you hover a rank-0 point, we'll finish this visual and then use the remaining space for **Servicing & exceptions**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-40d17115-34ce-41c7-ac4e-6952d7833f2c"></a>
## Andrew / user · C109-M00362

C109-M00362 · 2026-08-26T21:14:40.067000-04:00 · active path

Preceding visible parent: [C109-M00361](part-13.md#m-c7cfc284-896e-4e84-a86a-6d80346c351a)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 17460020-c789-4237-944a-f0b23eff19b1.png

<!-- BEGIN_SOURCE_MESSAGE -->
 0 - paid off.
<!-- END_SOURCE_MESSAGE -->


<a id="m-775ff02b-0a7e-4d71-b455-b1f9983e1c9a"></a>
## Assistant · C109-M00363

C109-M00363 · 2026-08-26T21:14:43.114498-04:00 · active path

Preceding visible parent: [C109-M00362](part-13.md#m-40d17115-34ce-41c7-ac4e-6952d7833f2c)

<!-- BEGIN_SOURCE_MESSAGE -->
Exactly. That resolves the entire scale:

- **0 = Paid off**
- **1 = Current**
- **2 = Watch**
- **3 = Underperforming**
- **4 = Severe shortfall**

And the trajectory for Merchant 000749 now tells a coherent story: predominantly Current with intermittent Watch periods, a brief Severe Shortfall episode, then Paid Off on November 1.

I would **keep Monitoring journey exactly as the analytical concept**. The numeric Y-axis isn't perfect, but the tooltip makes the status explicit, and the ordered rank is meaningful.

One small improvement: change the Y-axis title, if currently shown, to **Monitoring severity**, or leave the axis title off. I would not spend time trying to replace 0–4 with text labels; that likely creates more complexity than value.

Now let's use the remaining space for **Servicing & exceptions**. Before building it, search your Fields pane for a fact table containing `servicing`, `exception`, or `case`. If one exists, tell me its table name(s). I want actual servicing/event records there rather than repackaging monitoring alerts as servicing activity.
<!-- END_SOURCE_MESSAGE -->


<a id="m-73b3ee7e-e717-45a2-acf1-5af3396f7f06"></a>
## Andrew / user · C109-M00364

C109-M00364 · 2026-08-26T21:15:43.833000-04:00 · active path

Preceding visible parent: [C109-M00363](part-13.md#m-775ff02b-0a7e-4d71-b455-b1f9983e1c9a)

<!-- BEGIN_SOURCE_MESSAGE -->
I won't if we can make the Y-axis more informative to the reader
<!-- END_SOURCE_MESSAGE -->


<a id="m-2021b409-f758-4b41-afad-03a78c02635e"></a>
## Assistant · C109-M00365

C109-M00365 · 2026-08-26T21:15:46.914935-04:00 · active path

Preceding visible parent: [C109-M00364](part-13.md#m-73b3ee7e-e717-45a2-acf1-5af3396f7f06)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree. **A 0–4 axis is too cryptic for a portfolio piece.** A viewer shouldn't need to hover to learn what `3` means.

Unfortunately, a standard Power BI line chart does not cleanly support replacing numeric Y-axis tick labels with arbitrary categorical labels such as `Paid off`, `Current`, `Watch`, etc. But we can make the visual substantially more informative without overengineering it.

### Best native solution: add labeled horizontal reference lines

Keep the rank measure exactly as-is, but use the Analytics pane to add constant lines at the meaningful levels:

| Value | Label |
|---:|---|
| 4 | Severe shortfall |
| 3 | Underperforming |
| 2 | Watch |
| 1 | Current |
| 0 | Paid off |

For each line:

1. Select **Monitoring journey**.
2. Open the **Analytics** pane.
3. Add a **Y-axis constant line**.
4. Enter the value.
5. Turn **Data label = On**.
6. Set the label/text to the corresponding status.
7. Repeat for the five ranks.

Then we can potentially turn the normal Y-axis labels **Off**, because the reference-line labels themselves explain the scale.

Conceptually, the viewer sees:

```text
Severe shortfall ────────────────
                    ┌───┐
Underperforming ────│───│────────
                    │   │
Watch ──┐─┐──┐─┐────│───│────────
        │ │  │ │    │   │
Current └─┴──┴─┴────┘   │
                         │
Paid off ────────────────└────────
```

That is **far more portfolio-quality** than `0, 1, 2, 3, 4`.

### One caveat

Five labeled constant lines could become visually busy in this relatively small chart. So I would test it physically rather than assume all five are necessary.

My preferred hierarchy would be:

**Definitely label**
- `4 — Severe shortfall`
- `3 — Underperforming`
- `2 — Watch`

Then perhaps leave `1` and `0` understandable through the axis/tooltips—or label all five if it remains clean.

Another option is to keep the numeric ticks and change the Y-axis title to:

**Monitoring severity (0 Paid off → 4 Severe)**

That's less elegant but extremely compact.

**I would try the labeled constant-line approach first.** If five lines clutter the visual, we'll simplify it rather than accept an unexplained numeric scale.
<!-- END_SOURCE_MESSAGE -->


<a id="m-85c37616-04e8-48ec-bdc7-3fd527016676"></a>
## Andrew / user · C109-M00366

C109-M00366 · 2026-08-26T21:22:57.931000-04:00 · active path

Preceding visible parent: [C109-M00365](part-13.md#m-2021b409-f758-4b41-afad-03a78c02635e)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: e6528e63-15fd-43e4-b692-f520053ed681.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->
