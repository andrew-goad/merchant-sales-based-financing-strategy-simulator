# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 14 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-13.md)
[Next part](part-15.md)

<a id="m-b6585ff2-0b40-42ab-9034-da9b0ef7d829"></a>
## Assistant · C109-M00367

C109-M00367 · 2026-08-26T21:23:00.697515-04:00 · active path

Preceding visible parent: [C109-M00366](part-13.md#m-85c37616-04e8-48ec-bdc7-3fd527016676)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **this works very well. Keep it.**

The chart is now self-explanatory without requiring hover:

- **4 — Severe shortfall**
- **3 — Underperforming**
- **2 — Watch**
- **1 — Current**
- **0 — Paid off**

The horizontal guides also make the movement between monitoring states much easier to interpret. This now reads like a genuine **ordinal monitoring-state trajectory**, rather than a mysterious numeric line.

Two minor refinements only:

1. **Keep the numeric 0–4 labels.** In this implementation they help anchor the reference-line labels rather than creating confusion.
2. If Power BI allows you to make all five reference-line labels consistently left- or right-aligned without fighting the visual, do that. Right now Severe shortfall/Underperforming are left while Watch/Current/Paid off are right. That's not a problem, but consistent placement would be slightly cleaner. If placement becomes fiddly, leave it exactly as shown.

I would **not add a Y-axis title** now. The labeled states already explain the scale better than an axis title could.

### Monitoring journey is essentially complete

This is also a nice portfolio visual because it communicates something that the adjacent charts don't:

- Receivable trajectory → **balance liquidation**
- Remittance performance → **cumulative contractual pace**
- Monitoring journey → **governed risk/attention state**

Those are three distinct dimensions of the merchant lifecycle.

Now let's build the last major P03 component: **Servicing & exceptions**.

Before creating anything, look through the Fields pane for tables with names containing **Servicing**, **Exception**, **Alert**, **Case**, or similar. Give me the table names you find. We should use the actual operational-event grain if it exists rather than infer servicing activity from `FactAccountDaily`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a0d301e8-48aa-409f-9931-3349562b50c2"></a>
## Andrew / user · C109-M00368

C109-M00368 · 2026-08-26T21:25:11.942000-04:00 · active path

Preceding visible parent: [C109-M00367](part-14.md#m-b6585ff2-0b40-42ab-9034-da9b0ef7d829)

<!-- BEGIN_SOURCE_MESSAGE -->
next visual to build
<!-- END_SOURCE_MESSAGE -->


<a id="m-35776bd2-1634-4639-9bf6-a346c1efecb0"></a>
## Assistant · C109-M00369

C109-M00369 · 2026-08-26T21:25:17.446883-04:00 · active path

Preceding visible parent: [C109-M00368](part-14.md#m-a0d301e8-48aa-409f-9931-3349562b50c2)

<!-- BEGIN_SOURCE_MESSAGE -->
Build **Monitoring exceptions** next. It complements the Monitoring journey without duplicating it and uses fields we already know exist in `FactAccountDaily`.

Create a **Table** visual in the open space beneath or beside Monitoring journey. Use these fields/measures:

```DAX
P03 Daily Shortfall =
SUM ( FactAccountDaily[daily_shortfall_amount] )
```

```DAX
P03 Cumulative Shortfall =
MAX ( FactAccountDaily[cumulative_shortfall_amount] )
```

```DAX
P03 Days Since Remittance =
MAX ( FactAccountDaily[days_since_last_positive_remittance] )
```

Then populate the table with:

```text
FactAccountDaily[monitoring_date]
P03 Monitoring Status
P03 Daily Shortfall
P03 Cumulative Shortfall
P03 Cumulative Pace Ratio
P03 Days Since Remittance
```

Rename the displayed headers to:

```text
Date
Status
Daily shortfall
Cumulative shortfall
Pace
Days since remittance
```

Title the visual:

**Monitoring exceptions**

Then apply a **visual-level filter**:

```text
FactAccountDaily[monitoring_status_rank] > 1
```

That removes ordinary `CURRENT` and `PAID_OFF` days and leaves only the periods where the merchant required elevated monitoring—Watch, Underperforming, Severe shortfall.

For formatting, use currency for both shortfall fields, percentage for Pace, whole number for Days since remittance, and short date for Date. Sort **Date ascending**.

For Merchant 000749, I expect this to give us a compact event-like history showing the intermittent Watch periods and the late-October Severe shortfall episode. Once we see how many rows it produces, we can decide whether this remains a table or whether we should collapse consecutive exception days into a more executive-friendly operational summary.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9e099898-4d85-4cce-8c54-9ea00110df5c"></a>
## Andrew / user · C109-M00370

C109-M00370 · 2026-08-27T02:41:57.482000-04:00 · active path

Preceding visible parent: [C109-M00369](part-14.md#m-35776bd2-1634-4639-9bf6-a346c1efecb0)

<!-- BEGIN_SOURCE_MESSAGE -->
the monitoring status > 1 also leads to a bunch of rows where status = NOT AVAILABLE
<!-- END_SOURCE_MESSAGE -->


<a id="m-5bf2b702-1011-4012-9189-dd5382af4f89"></a>
## Assistant · C109-M00371

C109-M00371 · 2026-08-27T02:42:00.875922-04:00 · active path

Preceding visible parent: [C109-M00370](part-14.md#m-9e099898-4d85-4cce-8c54-9ea00110df5c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. That is the **same table-grain problem we've already encountered**, and we should correct course rather than patch it.

`P03 Monitoring Status` is a `SELECTEDVALUE` measure. By putting that measure into a detail table alongside other measures, Power BI is generating evaluation contexts in which `FactAccountDaily[monitoring_status_code]` isn't uniquely resolved. The `> 1` filter can still be true while the display measure returns `NOT AVAILABLE`.

For this visual, **use the actual column**, not the measure.

### Change the table

Remove:

`P03 Monitoring Status`

Replace it with:

`FactAccountDaily[monitoring_status_code]`

The table should now be:

| Field | Display name |
|---|---|
| `monitoring_date` | Date |
| `monitoring_status_code` | Status |
| `[P03 Daily Shortfall]` | Daily shortfall |
| `[P03 Cumulative Shortfall]` | Cumulative shortfall |
| `[P03 Cumulative Pace Ratio]` | Pace |
| `[P03 Days Since Remittance]` | Days since remittance |

Keep the visual filter:

**`monitoring_status_rank > 1`**

That should give us only the actual daily rows where the account is:

**Watch / Underperforming / Severe shortfall**

and eliminate the artificial `NOT AVAILABLE` rows.

### This reinforces our emerging construction rule

We've now encountered this enough times that I'd make it explicit:

**Chart tooltip:** scalar `SELECTEDVALUE` measure is appropriate.  
**Table row:** use the actual row-level column.  
**Chart Y-axis requiring aggregation:** explicit numeric measure.  
**Card:** scalar measure.

So `P03 Monitoring Status` remains useful for the **Monitoring journey tooltip**, but it should not be used as the Status column in this detail table.

Try that substitution before changing anything else. If the resulting exception table is still excessively long, the next question becomes more interesting: whether we want **every elevated-monitoring day** or a much cleaner **exception-transition/event history**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4998066a-d092-4977-8a4e-b6af022e50ae"></a>
## Andrew / user · C109-M00372

C109-M00372 · 2026-08-27T02:47:12.236000-04:00 · active path

Preceding visible parent: [C109-M00371](part-14.md#m-5bf2b702-1011-4012-9189-dd5382af4f89)

<!-- BEGIN_SOURCE_MESSAGE -->
ok, is there additional visuals for this page?
<!-- END_SOURCE_MESSAGE -->


<a id="m-9ef909da-5bde-4295-9635-3501101c09e9"></a>
## Assistant · C109-M00373

C109-M00373 · 2026-08-27T02:47:16.570882-04:00 · active path

Preceding visible parent: [C109-M00372](part-14.md#m-4998066a-d092-4977-8a4e-b6af022e50ae)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes, but **I would stop at one additional substantive visual after Monitoring exceptions**. P03 is already telling most of its story, and adding visuals just because space exists would weaken it.

The one missing dimension is **actual servicing activity**.

Right now P03 covers:

1. **Merchant profile** — who is this merchant and what prior relationship did we have?
2. **Merchant request & decision** — what did they request and what decision occurred?
3. **Funded terms** — what was actually funded?
4. **Receivable trajectory** — how did the balance liquidate?
5. **Remittance performance** — how did cumulative payment pace behave?
6. **Monitoring journey** — how did the governed monitoring state evolve?
7. **Monitoring exceptions** — what were the elevated-monitoring days and associated shortfall/pace conditions?

What's missing is:

> **Did anyone actually have to service/intervene on this account, and what happened?**

### Final candidate: Servicing activity

I would make this a **compact table**, not another chart.

Ideally:

**Servicing activity**

`Date | Type | Reason | Status | Resolution`

or whatever the actual servicing fact supports.

That is materially different from Monitoring exceptions:

- **Monitoring exceptions** = system-detected performance conditions.
- **Servicing activity** = operational response/action.

That distinction is analytically strong and will also set up the later dedicated **Servicing & Exceptions** page.

### What I would *not* add

I would not add:

- another KPI strip;
- daily sales;
- a separate payoff-slippage chart;
- cumulative remittance dollars;
- another alert-count chart;
- risk/economics;
- acquisition information;
- endpoint reconciliation.

Those either duplicate information already communicated or belong more naturally on later authorized pages.

### One possible enhancement after construction

There is one thing I might eventually add **without consuming another visual slot**: tooltips on Receivable trajectory and Remittance performance containing useful daily context—status, actual remittance, expected remittance, shortfall, etc.

That would deepen P03 without cluttering it.

So I think we're very close to the correct page boundary. **Monitoring exceptions + one Servicing activity table should complete P03.**

Before we build that last visual, look at your Fields pane for a fact table whose name contains something like `Servicing`, `Case`, `Exception`, `Intervention`, or `Action`. If there is one, give me its name and we'll build the final visual directly from the proper operational grain.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4e2bacae-f428-46fb-8370-b5d75d9630eb"></a>
## Andrew / user · C109-M00374

C109-M00374 · 2026-08-27T02:54:02.957000-04:00 · active path

Preceding visible parent: [C109-M00373](part-14.md#m-9ef909da-5bde-4295-9635-3501101c09e9)

**Editorial record note:** Attachment references: Pasted markdown(20260827-065223).md; Pasted markdown (2)(7).md; Pasted markdown (3)(1).md

<!-- BEGIN_SOURCE_MESSAGE -->


| module1\_run\_id servicing\_queue\_code servicing\_queue\_rank burden\_units manual\_review\_flag description definition\_status row\_hash created\_at  |                          |   |   |       |                                                  |          |                                  |          |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | - | - | ----- | ------------------------------------------------ | -------- | -------------------------------- | -------- |
| 1                                                                                                                                                       | NO\_SERVICING\_REQUIRED  | 0 | 0 | False | No servicing workload is required.               | APPROVED | 8dc4d0a846b84239585e4f86a694d42d | 8/4/2026 |
| 1                                                                                                                                                       | ACTIVE\_REASSESSMENT     | 1 | 2 | False | Active account awaits governed reassessment.     | APPROVED | 27af5a2b6fd70309c8b8bc41e5f06a1a | 8/4/2026 |
| 1                                                                                                                                                       | GOVERNANCE\_REVIEW\_HOLD | 2 | 5 | True  | Account remains in controlled governance review. | APPROVED | 1dda09ae9e5fafae40017974c395edd2 | 8/4/2026 |
<!-- END_SOURCE_MESSAGE -->


<a id="m-70f622d6-fcce-4d48-904b-25ddb7b05391"></a>
## Assistant · C109-M00375

C109-M00375 · 2026-08-27T02:54:07.388369-04:00 · active path

Preceding visible parent: [C109-M00374](part-14.md#m-4e2bacae-f428-46fb-8370-b5d75d9630eb)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. This is much better than the simple three-row servicing-queue dimension, and the supplied data changes what I recommend for the final P03 section.

The important discovery is that we actually have **three different layers of servicing information**:

- **Strategy/intervention:** what the governed process says should be reviewed or considered. For example, merchant 312 receives `TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW`, while merchant 98 receives `TARGETED_MERCHANT_OUTREACH_REVIEW`. Critically, the source explicitly says `NO_PAYMENT_CHANGE_EXECUTED` / `NO_MERCHANT_CONTACT_EXECUTED`, so these are governed review recommendations, not claims that somebody actually contacted the merchant or changed the payment. [export reference: filecite | turn43file2 | L3-L4]
- **Servicing execution:** what the synthetic servicing process subsequently did. Merchant 312 has simulated temporary-payment processing with payment-event counts, scheduled/processed/returned/retry amounts and residual exposure; merchant 98 instead lands in a servicing-review hold. [export reference: filecite | turn43file0 | L5-L6]
- **Certified servicing outcome:** the later portfolio-performance layer reconciles those outcomes. Merchant 312 is `ACTIVE_RECONCILED / ACTIVE_REASSESSMENT`, while merchant 98 is `CONTROLLED_REVIEW / GOVERNANCE_REVIEW_HOLD`. [export reference: filecite | turn43file1 | L6-L7]

That is a genuinely good story.

### I would change the final visual

Rather than a generic **“Servicing activity”** table with `Date | Type | Reason | Status | Resolution`, make the final section:

**Servicing & intervention**

And use a compact, one-row table at the selected merchant/scenario grain:

**Intervention | Queue | Exposure | Execution | Final state**

For example, merchant 312 should conceptually read something like:

`Temporary remittance adjustment review | Servicing review | $518 | Temporary payment processing | Reassessment due`

Merchant 98:

`Targeted merchant outreach review | Servicing review | $462 | Servicing review hold | Review hold`

And a normal merchant might simply show:

`No further action | Closed | $0 | No processing | Closed`

This is much more valuable than another chart.

### One important boundary

I would **not use the Observation-date slicer to filter this table**. These supplied servicing/intervention tables appear to be account/scenario outcome records, not daily observations. The `created_at` dates are artifact/process dates, not merchant servicing-event dates. So we should not manufacture a daily servicing timeline from them.

That also means our page now has a nice distinction:

**daily lifecycle evidence**
→ Receivable trajectory  
→ Remittance performance  
→ Monitoring journey / exceptions

**account/scenario servicing outcome**
→ Servicing & intervention

### Next step

Let's build **Servicing & intervention** now.

First, tell me the Power BI table name corresponding to the file containing these fields:

`strategy_outcome_code`  
`servicing_action_code`  
`servicing_queue_code`  
`recommended_action_exposure_amount`  
`primary_intervention_reason_code`

That is the third dataset you supplied, and **that is where I want to start the visual**. We can then bring in the execution/final-state layer with measures if necessary rather than creating another sprawling cross-grain table.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dc9c49f3-5ba6-4a36-9942-0ad7a5d2f465"></a>
## Andrew / user · C109-M00376

C109-M00376 · 2026-08-27T02:56:38.355000-04:00 · active path

Preceding visible parent: [C109-M00375](part-14.md#m-70f622d6-fcce-4d48-904b-25ddb7b05391)

<!-- BEGIN_SOURCE_MESSAGE -->
FactIntervention and I've made it viewable (removed hide)
<!-- END_SOURCE_MESSAGE -->


<a id="m-9b4ab8fa-d016-4245-8d2b-bb707a853e4e"></a>
## Assistant · C109-M00377

C109-M00377 · 2026-08-27T02:56:41.624206-04:00 · active path

Preceding visible parent: [C109-M00376](part-14.md#m-dc9c49f3-5ba6-4a36-9942-0ad7a5d2f465)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. `FactIntervention` is the correct starting point, and since you've exposed it, **let's use its actual columns rather than create unnecessary measures**.

For the final P03 section, create a **Table** visual titled **Servicing & intervention**. Add these `FactIntervention` columns in this exact order:

| FactIntervention field | Rename for this visual |
|---|---|
| `strategy_outcome_code` | **Intervention** |
| `servicing_action_code` | **Action** |
| `servicing_queue_code` | **Queue** |
| `recommended_action_exposure_amount` | **Exposure** |
| `primary_intervention_reason_code` | **Reason** |

These fields are all at the same merchant/application/scenario intervention grain, so this is much cleaner than mixing in daily monitoring fields. The source supports outcomes ranging from closed/no-action to targeted outreach review and temporary-remittance-adjustment review. [export reference: filecite | turn43file2 | L3-L8]

### Formatting

Use:

- **Exposure:** Currency, 0 decimals.
- Turn **Word wrap OFF** initially for values.
- Keep column headers on.
- Make **Intervention** the widest column.
- Make **Reason** reasonably wide, but don't let the long technical code dominate the page.
- No totals.
- No conditional formatting yet.

For your current Merchant **000749 / Baseline**, expect a fairly uneventful row: the source has that merchant as `CLOSED_NO_FURTHER_ACTION`, `NO_ACTION_CLOSED`, `CLOSED`, $0 exposure, with a paid-off/closed reason. [export reference: filecite | turn43file2 | L24-L24] That's actually useful UAT because P03 must represent both problem merchants and merchants requiring no intervention.

### Then test a more interesting merchant

After 749 renders correctly, switch Merchant to **000312 / Baseline**.

That should give us a much stronger test case:

`TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW`  
→ `TEMPORARY_REMITTANCE_REVIEW`  
→ `SERVICING_REVIEW`  
→ `$518.04`

with a severe-shortfall/reassessment reason. [export reference: filecite | turn43file2 | L3-L3]

**Show me the resulting table for 312 before we add the execution outcome.** If it behaves properly, we'll decide whether to extend this same visual with the downstream execution/final state or whether the five intervention fields already tell the story cleanly enough.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0de15ec7-9acc-4328-8a7f-16390d115481"></a>
## Andrew / user · C109-M00378

C109-M00378 · 2026-08-27T03:06:06.405000-04:00 · active path

Preceding visible parent: [C109-M00377](part-14.md#m-9b4ab8fa-d016-4245-8d2b-bb707a853e4e)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 5b3f1d86-29ad-4921-906c-b08e93e36551.png

<!-- BEGIN_SOURCE_MESSAGE -->
we need to create new columns for intervention / action / queue / reason to make them more professional: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-195ca25a-1f91-48c9-aa3f-f6acd8108520"></a>
## Assistant · C109-M00379

C109-M00379 · 2026-08-27T03:06:09.964743-04:00 · active path

Preceding visible parent: [C109-M00378](part-14.md#m-0de15ec7-9acc-4328-8a7f-16390d115481)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The raw codes are useful for governance but **too technical for the report surface**. I would preserve the source columns unchanged and add four calculated presentation columns to `FactIntervention`, exactly like we did for Use, Channel, and Decision.

For the current source population, we should translate the business meaning rather than merely replace underscores with spaces. The intervention source distinguishes, for example, temporary-remittance review, targeted outreach review, and closed/no-further-action states. [export reference: filecite | turn43file2 | L3-L5]

### 1. Intervention

```DAX
P03 Intervention =
SWITCH (
    FactIntervention[strategy_outcome_code],
    "CLOSED_NO_FURTHER_ACTION", "No further action",
    "TARGETED_MERCHANT_OUTREACH_REVIEW", "Merchant outreach review",
    "TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW", "Remittance adjustment review",
    SUBSTITUTE (
        PROPER (
            SUBSTITUTE (
                FactIntervention[strategy_outcome_code],
                "_",
                " "
            )
        ),
        "No Further Action",
        "No further action"
    )
)
```

### 2. Action

```DAX
P03 Servicing Action =
SWITCH (
    FactIntervention[servicing_action_code],
    "NO_ACTION_CLOSED", "No action — closed",
    "OUTREACH_REVIEW_QUEUE", "Outreach review",
    "TEMPORARY_REMITTANCE_REVIEW", "Remittance review",
    SUBSTITUTE (
        PROPER (
            SUBSTITUTE (
                FactIntervention[servicing_action_code],
                "_",
                " "
            )
        ),
        "No Action Closed",
        "No action — closed"
    )
)
```

### 3. Queue

The queue population is especially clean:

```DAX
P03 Servicing Queue =
SWITCH (
    FactIntervention[servicing_queue_code],
    "CLOSED", "Closed",
    "SERVICING_REVIEW", "Servicing review",
    PROPER (
        SUBSTITUTE (
            FactIntervention[servicing_queue_code],
            "_",
            " "
        )
    )
)
```

### 4. Reason

This is where I would be most aggressive about removing technical implementation language. The user doesn't need `M2_6_REASON_...`.

```DAX
P03 Intervention Reason =
SWITCH (
    FactIntervention[primary_intervention_reason_code],
    "M2_6_REASON_PAID_OFF_CLOSED", "Paid off",
    "M2_6_REASON_SEVERE_SHORTFALL_OUTREACH_REVIEW", "Severe shortfall",
    "M2_6_REASON_SEVERE_SHORTFALL_TEMPORARY_REMITTANCE_REVIEW", "Severe shortfall",
    SUBSTITUTE (
        PROPER (
            SUBSTITUTE (
                SUBSTITUTE (
                    FactIntervention[primary_intervention_reason_code],
                    "M2_6_REASON_",
                    ""
                ),
                "_",
                " "
            )
        ),
        "Paid Off Closed",
        "Paid off"
    )
)
```

The fallback is intentional. If another accepted code appears while you're testing merchants, it will still produce readable text instead of BLANK.

### Then rebuild that bottom-right table

Use only:

**Intervention | Action | Queue | Exposure | Reason**

with:

- `P03 Intervention`
- `P03 Servicing Action`
- `P03 Servicing Queue`
- `recommended_action_exposure_amount`
- `P03 Intervention Reason`

For merchant **000749**, your current row should become approximately:

**No further action | No action — closed | Closed | $0 | Paid off**

That's dramatically better than what is on screen now.

One additional change: give this table a visible title:

### **Servicing & intervention**

Then test **000312 / Baseline**. That's the merchant I most want to see next because its source row contains an actual intervention-review case rather than the uneventful paid-off outcome shown for 749. [export reference: filecite | turn43file2 | L3-L3]

Also, your overall P03 layout is coming together very well. I would **turn totals off on Monitoring exceptions**—the current `Total` row doesn't make semantic sense for Pace or Days since remittance and visually implies aggregations that aren't useful to the merchant story.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8c6c62ef-dd46-4c6a-9c34-0f7517b1cc23"></a>
## Andrew / user · C109-M00380

C109-M00380 · 2026-08-27T03:09:28.768000-04:00 · active path

Preceding visible parent: [C109-M00379](part-14.md#m-195ca25a-1f91-48c9-aa3f-f6acd8108520)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: e1425d6c-6611-4aa9-bf48-2969a2e069da.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-440dea21-2a95-4ec4-a57e-d5a627ba18dc"></a>
## Assistant · C109-M00381

C109-M00381 · 2026-08-27T03:09:36.373911-04:00 · active path

Preceding visible parent: [C109-M00380](part-14.md#m-8c6c62ef-dd46-4c6a-9c34-0f7517b1cc23)

<!-- BEGIN_SOURCE_MESSAGE -->
The error is because **DAX does not have a `PROPER()` function**. That was my mistake. Power Query has `Text.Proper`, Excel has `PROPER`, but DAX does not.

For these presentation columns, the cleanest approach is actually better anyway: use explicit mappings for the governed codes and a simple readable fallback.

Replace `P03 Intervention` with:

```DAX
P03 Intervention =
SWITCH (
    FactIntervention[strategy_outcome_code],
    "CLOSED_NO_FURTHER_ACTION", "No further action",
    "TARGETED_MERCHANT_OUTREACH_REVIEW", "Merchant outreach review",
    "TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW", "Remittance adjustment review",
    SUBSTITUTE (
        FactIntervention[strategy_outcome_code],
        "_",
        " "
    )
)
```

And revise the other three similarly:

```DAX
P03 Servicing Action =
SWITCH (
    FactIntervention[servicing_action_code],
    "NO_ACTION_CLOSED", "No action — closed",
    "OUTREACH_REVIEW_QUEUE", "Outreach review",
    "TEMPORARY_REMITTANCE_REVIEW", "Remittance review",
    SUBSTITUTE (
        FactIntervention[servicing_action_code],
        "_",
        " "
    )
)
```

```DAX
P03 Servicing Queue =
SWITCH (
    FactIntervention[servicing_queue_code],
    "CLOSED", "Closed",
    "SERVICING_REVIEW", "Servicing review",
    SUBSTITUTE (
        FactIntervention[servicing_queue_code],
        "_",
        " "
    )
)
```

```DAX
P03 Intervention Reason =
SWITCH (
    FactIntervention[primary_intervention_reason_code],
    "M2_6_REASON_PAID_OFF_CLOSED", "Paid off",
    "M2_6_REASON_SEVERE_SHORTFALL_OUTREACH_REVIEW", "Severe shortfall",
    "M2_6_REASON_SEVERE_SHORTFALL_TEMPORARY_REMITTANCE_REVIEW", "Severe shortfall",
    SUBSTITUTE (
        SUBSTITUTE (
            FactIntervention[primary_intervention_reason_code],
            "M2_6_REASON_",
            ""
        ),
        "_",
        " "
    )
)
```

For the known values, these will produce the polished labels we want. The fallback is only there as protection if we encounter another code during UAT; it may remain uppercase, but it will at least be readable rather than erroring or returning blank.

I would create all four with these versions, then replace the raw fields in **Servicing & intervention** with the new presentation columns.
<!-- END_SOURCE_MESSAGE -->


<a id="m-39c6c495-ef08-40e6-85f2-ddc8b95a20d3"></a>
## Andrew / user · C109-M00382

C109-M00382 · 2026-08-27T03:13:08.512000-04:00 · active path

Preceding visible parent: [C109-M00381](part-14.md#m-440dea21-2a95-4ec4-a57e-d5a627ba18dc)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 14cf2764-9915-4671-baf3-621bb5f92562.png; Pasted markdown(20260827-071303).md

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e5549117-69a3-4ad9-9b71-ad78e7432ed1"></a>
## Assistant · C109-M00383

C109-M00383 · 2026-08-27T03:13:15.709906-04:00 · active path

Preceding visible parent: [C109-M00382](part-14.md#m-39c6c495-ef08-40e6-85f2-ddc8b95a20d3)

<!-- BEGIN_SOURCE_MESSAGE -->
The error confirms Power BI is currently creating **`P03 Intervention` as a measure**, not a calculated column.

Because a measure evaluates over filter context, `FactIntervention[strategy_outcome_code]` can contain many rows, so Power BI cannot determine one value. For this use case, we want a **row-level presentation column**.

Do this instead:

1. In the Fields pane, click **`FactIntervention`**.
2. Go to **Table tools / Modeling → New column**.
3. Make sure you choose **New column**, not **New measure**.
4. Paste:

```DAX
P03 Intervention =
SWITCH (
    FactIntervention[strategy_outcome_code],
    "CLOSED_NO_FURTHER_ACTION", "No further action",
    "TARGETED_MERCHANT_OUTREACH_REVIEW", "Merchant outreach review",
    "TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW", "Remittance adjustment review",
    SUBSTITUTE (
        FactIntervention[strategy_outcome_code],
        "_",
        " "
    )
)
```

That should work immediately because each row has exactly one `strategy_outcome_code`. The source confirms these codes are row-level attributes of `FactIntervention`. [export reference: filecite | turn44file0 | L3-L5]

Then create the other three using **New column** as well:

```DAX
P03 Servicing Action =
SWITCH (
    FactIntervention[servicing_action_code],
    "NO_ACTION_CLOSED", "No action — closed",
    "OUTREACH_REVIEW_QUEUE", "Outreach review",
    "TEMPORARY_REMITTANCE_REVIEW", "Remittance review",
    SUBSTITUTE (
        FactIntervention[servicing_action_code],
        "_",
        " "
    )
)
```

```DAX
P03 Servicing Queue =
SWITCH (
    FactIntervention[servicing_queue_code],
    "CLOSED", "Closed",
    "SERVICING_REVIEW", "Servicing review",
    SUBSTITUTE (
        FactIntervention[servicing_queue_code],
        "_",
        " "
    )
)
```

```DAX
P03 Intervention Reason =
SWITCH (
    FactIntervention[primary_intervention_reason_code],
    "M2_6_REASON_PAID_OFF_CLOSED", "Paid off",
    "M2_6_REASON_SEVERE_SHORTFALL_OUTREACH_REVIEW", "Severe shortfall",
    "M2_6_REASON_SEVERE_SHORTFALL_TEMPORARY_REMITTANCE_REVIEW", "Severe shortfall",
    SUBSTITUTE (
        SUBSTITUTE (
            FactIntervention[primary_intervention_reason_code],
            "M2_6_REASON_",
            ""
        ),
        "_",
        " "
    )
)
```

Then replace the raw columns in the visual with these four calculated columns.

A quick visual check: in the Fields pane, a **column** will have the column-style icon, while a **measure** has the calculator icon. For these four objects, we want columns.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e34633b3-fde8-4f75-9c08-6a72d3efac3e"></a>
## Andrew / user · C109-M00384

C109-M00384 · 2026-08-27T03:51:05.142000-04:00 · active path

Preceding visible parent: [C109-M00383](part-14.md#m-e5549117-69a3-4ad9-9b71-ad78e7432ed1)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 8e6b3ca4-3c56-4c45-8013-1787cdb835eb.png

<!-- BEGIN_SOURCE_MESSAGE -->
I'd thinking about removing evidence from the Merchant request & decision table and placing it in a nicely formatted card in this white space: I'm thinking like a green approve, yellow (counteroffer review), red decline. something that grabs the users attention and lets them know immediately without searching and also looks visually appealing.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a21bc333-02e8-4457-b6b8-648f756f265d"></a>
## Assistant · C109-M00385

C109-M00385 · 2026-08-27T03:51:08.801798-04:00 · active path

Preceding visible parent: [C109-M00384](part-14.md#m-e34633b3-fde8-4f75-9c08-6a72d3efac3e)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **I would do this.** It improves the information hierarchy materially.

Right now `Decision` is buried at the far right of a dense request table. But the decision is arguably the **single most important result of the application stage**. The table should explain *what was requested*; a prominent decision object should tell the viewer *what happened*.

I would use that white space for a compact **Decision card**.

### 1. Remove `Decision` from Merchant request & decision

Then I would actually rename that section:

**Merchant request**

It becomes a clean factual record:

`Application | Applied | Requested | Use | Channel | Remittance | Payoff days | Repayment`

### 2. Create a short decision-display measure

We already have the underlying decision outcome. Create:

```DAX
P03 Decision Display =
VAR _Decision =
    SELECTEDVALUE ( DimDecisionOutcome[final_decision_outcome_code] )
RETURN
    SWITCH (
        _Decision,
        "FINAL_OFFER_AUTHORIZED", "APPROVED",
        "COUNTEROFFER_REVIEW_REQUIRED", "REVIEW",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "DECLINED",
        "DECLINE_POLICY_AUTHORIZED", "DECLINED",
        "NOT AVAILABLE"
    )
```

If your exact codes differ, we can adjust them, but those are the ones we've physically encountered during P03 construction.

### 3. Make the card visually prominent

Put a Card visual in exactly the white area you've highlighted.

I would make it roughly:

```text
DECISION

✓ APPROVED
Final offer
```

or

```text
DECISION

! REVIEW
Counteroffer review
```

or

```text
DECISION

× DECLINED
Evidence decline
```

The **large word** is the immediate signal. Then we can retain a smaller descriptive outcome beneath it if the native card supports a secondary value/reference label cleanly.

### 4. Use conditional color — but carefully

Your green/yellow/red concept is exactly right here because these colors carry an intuitive decision meaning.

I would use:

- **APPROVED → green**
- **REVIEW → amber/yellow**
- **DECLINED → red**
- **NOT AVAILABLE → neutral gray**

I would **not color the entire background a saturated green/red**. That would be too loud relative to the rest of this report.

Instead, keep the card background white and conditionally color either:

- the large decision text, **or**
- a restrained accent/bar/background tint if the Card visual gives us a polished implementation.

That keeps it consistent with the sophisticated visual language of P01/P02/P03 while still making the decision impossible to miss.

### 5. I would add a second measure for the specific outcome

Because `APPROVED` versus `DECLINED` alone loses useful information:

```DAX
P03 Decision Detail =
VAR _Decision =
    SELECTEDVALUE ( DimDecisionOutcome[final_decision_outcome_code] )
RETURN
    SWITCH (
        _Decision,
        "FINAL_OFFER_AUTHORIZED", "Final offer",
        "COUNTEROFFER_REVIEW_REQUIRED", "Counteroffer review",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "Evidence decline",
        "DECLINE_POLICY_AUTHORIZED", "Policy decline",
        "Not available"
    )
```

Then the object can read:

**APPROVED**  
Final offer

rather than merely `Final offer`.

That is better executive communication because **status and reason/outcome are different pieces of information**.

### 6. One semantic nuance: use `REVIEW`, not yellow “counteroffer”

I'd make the big yellow state **REVIEW**, with `Counteroffer review` underneath.

Why? Because `COUNTEROFFER_REVIEW_REQUIRED` is not itself an approved counteroffer. The governed outcome says **review required**. We shouldn't visually elevate that into a completed counteroffer.

So our three-state visual language becomes:

**APPROVED**  
Final offer

**REVIEW**  
Counteroffer review

**DECLINED**  
Policy decline / Evidence decline

That is both visually compelling and semantically precise.

And your screenshot shows **Merchant 000388 / Evidence decline**, so that is actually an excellent merchant for building the red state first. Once it works, we can switch to 749 to test green and one of our known counteroffer merchants to test amber.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7f68f36d-0a92-4c5e-8a4a-15eda7faa5c1"></a>
## Andrew / user · C109-M00386

C109-M00386 · 2026-08-27T03:59:43.493000-04:00 · active path

Preceding visible parent: [C109-M00385](part-14.md#m-a21bc333-02e8-4457-b6b8-648f756f265d)

<!-- BEGIN_SOURCE_MESSAGE -->
step by step advice on creating this element
<!-- END_SOURCE_MESSAGE -->


<a id="m-f14bbba3-0117-46c8-96f5-1abc0cf5a4b6"></a>
## Assistant · C109-M00387

C109-M00387 · 2026-08-27T03:59:49.916636-04:00 · active path

Preceding visible parent: [C109-M00386](part-14.md#m-7f68f36d-0a92-4c5e-8a4a-15eda7faa5c1)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Build it as a **small two-line decision panel** rather than a generic card with too much chrome.

First, remove `Decision` from the **Merchant request & decision** table and rename that section **Merchant request**.

Then create these two measures in your P03 measure area:

```DAX
P03 Decision Display =
VAR _Decision =
    SELECTEDVALUE ( DimDecisionOutcome[final_decision_outcome_code] )
RETURN
    SWITCH (
        _Decision,
        "FINAL_OFFER_AUTHORIZED", "APPROVED",
        "COUNTEROFFER_REVIEW_REQUIRED", "REVIEW",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "DECLINED",
        "DECLINE_POLICY_AUTHORIZED", "DECLINED",
        "NOT AVAILABLE"
    )
```

```DAX
P03 Decision Detail =
VAR _Decision =
    SELECTEDVALUE ( DimDecisionOutcome[final_decision_outcome_code] )
RETURN
    SWITCH (
        _Decision,
        "FINAL_OFFER_AUTHORIZED", "Final offer",
        "COUNTEROFFER_REVIEW_REQUIRED", "Counteroffer review",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "Evidence decline",
        "DECLINE_POLICY_AUTHORIZED", "Policy decline",
        "Not available"
    )
```

Now create a third measure that will drive the color:

```DAX
P03 Decision Color =
VAR _Decision =
    [P03 Decision Display]
RETURN
    SWITCH (
        _Decision,
        "APPROVED", "#2E7D32",
        "REVIEW", "#B8860B",
        "DECLINED", "#C62828",
        "#6B7280"
    )
```

Next, insert a **Card** visual into the white space to the left of Funded terms.

Put `[P03 Decision Display]` into the card.

Format it like this:

- Title: **Off**
- Category label: **Off**
- Callout value: large, around **22–28 pt**
- Font weight: bold
- Background: white
- Border: off or very subtle
- Shadow: off
- Padding: modest

Then conditionally format the callout color:

1. Select the card.
2. Format pane.
3. Find **Callout value → Color**.
4. Click **fx**.
5. Format style: **Field value**.
6. Based on field: `[P03 Decision Color]`.
7. Apply.

That gives you the green / amber / red signal.

Now add the smaller explanatory line. The cleanest way is a **second Card** directly beneath the first.

Put `[P03 Decision Detail]` in that second card and format it:

- font around **11–13 pt**
- neutral dark gray
- category label off
- background off
- border off

Above both cards, insert a tiny text box:

**Decision**

Use the same section-title treatment you already use elsewhere.

So visually, the element becomes:

```text
Decision

DECLINED
Evidence decline
```

or:

```text
Decision

APPROVED
Final offer
```

or:

```text
Decision

REVIEW
Counteroffer review
```

I would not add a colored background box yet. The colored word itself should be enough, and it will fit the restrained style of the rest of the page.

Finally, UAT the three states. Use:

- Merchant **000388** for a decline state
- Merchant **000749** for approved/final offer
- one merchant you already identified with `COUNTEROFFER_REVIEW_REQUIRED` for review

If all three change correctly with the Merchant slicer, the element is done.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ece65ec0-6c94-4406-91b8-976a2df7b34f"></a>
## Andrew / user · C109-M00388

C109-M00388 · 2026-08-27T04:17:14.482000-04:00 · active path

Preceding visible parent: [C109-M00387](part-14.md#m-f14bbba3-0117-46c8-96f5-1abc0cf5a4b6)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: f5734c4d-ff12-4ebf-9c83-2cc7cec73b27.png

<!-- BEGIN_SOURCE_MESSAGE -->
showing not available:
<!-- END_SOURCE_MESSAGE -->


<a id="m-486a3ede-4af5-4dc8-a278-42dc877b960d"></a>
## Assistant · C109-M00389

C109-M00389 · 2026-08-27T04:17:20.436585-04:00 · active path

Preceding visible parent: [C109-M00388](part-14.md#m-ece65ec0-6c94-4406-91b8-976a2df7b34f)

<!-- BEGIN_SOURCE_MESSAGE -->
That makes sense. The problem is **not the card**; it is the table I used in the measure.

`DimDecisionOutcome` is a lookup/dimension table. Your Merchant and Scenario slicers do not necessarily back-filter that dimension to one outcome, so:

```DAX
SELECTEDVALUE ( DimDecisionOutcome[final_decision_outcome_code] )
```

sees multiple decision codes and returns blank → our measure converts that to `NOT AVAILABLE`.

For P03 we should get the selected merchant's actual decision from **`FactFinalDecision`**, which is at the application/scenario decision grain.

### 1. Replace `P03 Decision Display`

Use:

```DAX
P03 Decision Display =
VAR _Decision =
    SELECTEDVALUE (
        FactFinalDecision[final_decision_outcome_code]
    )
RETURN
    SWITCH (
        _Decision,
        "FINAL_OFFER_AUTHORIZED", "APPROVED",
        "COUNTEROFFER_REVIEW_REQUIRED", "REVIEW",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "DECLINED",
        "DECLINE_POLICY_AUTHORIZED", "DECLINED",
        "NOT AVAILABLE"
    )
```

You **do not need to unhide `FactFinalDecision`** to reference it in a measure.

### 2. Replace `P03 Decision Detail` too

```DAX
P03 Decision Detail =
VAR _Decision =
    SELECTEDVALUE (
        FactFinalDecision[final_decision_outcome_code]
    )
RETURN
    SWITCH (
        _Decision,
        "FINAL_OFFER_AUTHORIZED", "Final offer",
        "COUNTEROFFER_REVIEW_REQUIRED", "Counteroffer review",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "Evidence decline",
        "DECLINE_POLICY_AUTHORIZED", "Policy decline",
        "Not available"
    )
```

`P03 Decision Color` can remain unchanged because it relies on `[P03 Decision Display]`, not directly on the underlying table.

### 3. Test Merchant 000749 first

Your existing Merchant Request table already tells us this merchant is:

**Final offer**

So after replacing the measure, that box should immediately change from:

`NOT AVAILABLE`

to:

**APPROVED**

and the conditional font should become green.

Then add the second smaller card underneath with `[P03 Decision Detail]`, which should show:

**Final offer**

### Why this is the correct architecture

This is another useful distinction for the model:

- **`DimDecisionOutcome`** → defines/describes the possible decision outcomes.
- **`FactFinalDecision`** → tells us **which decision this application actually received under the selected scenario**.

For a merchant-specific status card, we need the second one.

Once 749 works, switch to **000388**. From your screenshot, that merchant should return **DECLINED / Evidence decline**. Then we can verify the red conditional formatting and finish the card design.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b646dbc8-92c2-41d3-99ca-7d114040f6b2"></a>
## Andrew / user · C109-M00390

C109-M00390 · 2026-08-27T04:51:48.431000-04:00 · active path

Preceding visible parent: [C109-M00389](part-14.md#m-486a3ede-4af5-4dc8-a278-42dc877b960d)

**Editorial record note:** 4 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: b00fd36b-41b1-4280-b522-0d5f604174c8.png; 0a9255e7-4803-4c2c-99dc-1f8625d421bf.png; 03fa0cc6-523a-4e0c-8656-27c6cef263ca.png; 0d1f3ed8-05a3-4a9e-b8e0-3cf9141d9913.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e0aef418-52f9-43fc-8957-9b584773f440"></a>
## Assistant · C109-M00391

C109-M00391 · 2026-08-27T04:51:54.332986-04:00 · active path

Preceding visible parent: [C109-M00390](part-14.md#m-b646dbc8-92c2-41d3-99ca-7d114040f6b2)

<!-- BEGIN_SOURCE_MESSAGE -->
These screenshots validate the decision element very well. I would **keep this design**.

The three states are immediately understandable:

- **APPROVED / Final offer** — green
- **REVIEW / Counteroffer review** — amber
- **DECLINED / Evidence decline** or **Policy decline** — red

This is materially better than burying the outcome in the request table. The eye now goes naturally from **Merchant → Request → Decision → Funded terms → Performance/servicing**.

A few refinements stand out from the UAT screenshots:

1. **Rename `Merchant request & decision` permanently to `Merchant request`.** The card now owns the decision outcome, so the old heading would be redundant.

2. **The blank downstream visuals for REVIEW/DECLINED are logically correct.** A merchant that wasn't funded should not have funded terms, receivable trajectory, remittance performance, monitoring history, or servicing intervention fabricated for it. I would not fill those with zeros.

3. But the completely empty downstream region is a little ambiguous. I recommend adding a small measure-driven message such as:

   **Not funded — lifecycle monitoring not applicable**

   It could appear once in the lifecycle area when there is no funded advance rather than putting “Not available” into every visual. That tells the viewer the blank space is intentional.

4. **Fix `Prior funded` formatting.** Merchant 301 currently shows `$86.56723K`. Change that display to something like **$86.6K** (or `$86,567` if you prefer full dollars). The five-decimal K value looks unfinished.

5. I like that Merchant 301 demonstrates something important: the profile can show **RETURNING GOOD / 1 prior advance / prior funded amount** while the current application is still declined. That makes the 360 concept much stronger because relationship history clearly does not predetermine the current decision.

6. Keep the card dimensions and placement. The decision card is visually prominent without overwhelming the page. I would not add icons, gradients, or more decoration.

The next improvement I would make is the **single “Not funded” lifecycle-state message**, because your REVIEW and DECLINED screenshots expose that UX need very clearly. After that, P03 is close to a finished page rather than a construction prototype.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d28e93a6-64b2-48b9-b531-8ff6628234f3"></a>
## Andrew / user · C109-M00392

C109-M00392 · 2026-08-27T04:54:53.407000-04:00 · active path

Preceding visible parent: [C109-M00391](part-14.md#m-e0aef418-52f9-43fc-8957-9b584773f440)

<!-- BEGIN_SOURCE_MESSAGE -->
regarding, But the completely empty downstream region is a little ambiguous. I recommend adding a small measure-driven message such as:

**Not funded — lifecycle monitoring not applicable**

It could appear once in the lifecycle area when there is no funded advance rather than putting “Not available” into every visual. That tells the viewer the blank space is intentional.               It would seem that our DECLINED and REVIEW card would already signal this
<!-- END_SOURCE_MESSAGE -->


<a id="m-edef8328-45c9-4f79-979f-5c0daf63d532"></a>
## Assistant · C109-M00393

C109-M00393 · 2026-08-27T04:54:59.280715-04:00 · active path

Preceding visible parent: [C109-M00392](part-14.md#m-d28e93a6-64b2-48b9-b531-8ff6628234f3)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — I agree. **The DECLINED and REVIEW decision cards already communicate why the downstream lifecycle area is blank.** Adding a separate “Not funded — lifecycle monitoring not applicable” message would be redundant and would start cluttering a page that is currently very clean.

For this page, I would keep the behavior exactly as it is:

- **APPROVED** → funded terms and lifecycle visuals populate.
- **REVIEW** → no funded terms/lifecycle visuals.
- **DECLINED** → no funded terms/lifecycle visuals.

That actually reinforces the business logic visually: the journey stops at the decision when no advance is funded.

The only thing I would consider is ensuring the **Funded terms** section itself remains blank rather than showing zeros, which it already does in your screenshots. That is sufficient. I would not add another explanatory message.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8773d51c-07b1-4e3b-9983-50e70549691b"></a>
## Andrew / user · C109-M00394

C109-M00394 · 2026-08-27T04:59:04.811000-04:00 · active path

Preceding visible parent: [C109-M00393](part-14.md#m-edef8328-45c9-4f79-979f-5c0daf63d532)

<!-- BEGIN_SOURCE_MESSAGE -->
The title and subtitle would seem to need work. This isn't necessarily a 360 view of a merchant relationship but rather one particular merchant application. And perhaps we need to drill a bit into my documentation to see why that is for this stage of development. I know we had planned a 1 year / 3 year / 5 year product strategy launch, so we should be seeing accounts created, closed, new accounts, etc. but perhaps we haven't quite got there by end of module 2. let's investigate.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9ad366f4-034a-4316-bcd7-70e130e07e48"></a>
## Assistant · C109-M00395

C109-M00395 · 2026-08-27T04:59:36.378371-04:00 · active path

Preceding visible parent: [C109-M00394](part-14.md#m-8773d51c-07b1-4e3b-9983-50e70549691b)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I investigated the roadmap, and your instinct is correct: **the page we have built is not yet a true “Merchant Relationship 360.”** It is much closer to an **application-to-account lifecycle view** for one merchant/application/scenario.

### Why the model behaves this way

The strategic roadmap deliberately starts narrower than the eventual relationship vision. Year 1 is **“Launch, Control, and Learn”**: one core product, controlled launch, daily account-performance monitoring, early-warning status, and basic account-management actions. [export reference: filecite | turn46file0 | L32-L52]

There *is* some relationship awareness in Year 1. Q3 explicitly calls for analysis of **new versus returning merchants** and pilots for line reduction, freeze, renewal, and workout; Year 1 also lists basic increase/maintain/reduce/freeze/renew/workout capabilities. [export reference: filecite | turn46file0 | L99-L108] [export reference: filecite | turn46file0 | L120-L134] That explains why our current `DimMerchant` contains things such as relationship stage, relationship quality, prior advance count, and prior funded amount.

But the roadmap does **not** say that Year 1 already contains a fully simulated multi-generation merchant relationship history. In fact, the more sophisticated relationship capability is explicitly deferred.

Years 2–3 introduce differentiation among **new, repeat, renewed, and previously distressed merchants**, relationship/renewal pricing, prequalified renewals, treatment tracking, and merchant lifetime/relationship value. [export reference: filecite | turn46file0 | L206-L220] [export reference: filecite | turn47file0 | L11-L26]

Then Years 3–5 explicitly say the objective is to transform the portfolio **“from reactive application decisioning into proactive merchant-relationship and capital management.”** That's where continuous merchant health, automated renewal/re-underwriting, relationship-level profitability/value, broader facilities for proven merchants, cross-sell, retention, and relationship-manager strategy appear. [export reference: filecite | turn47file0 | L64-L88]

And the maturity matrix is especially revealing:

> Year 1 performance = **Daily remittance status**  
> Years 2–3 = **Merchant health and treatment**  
> Years 3–5 = **Continuous lifecycle optimization**  
> 5+ = **Ecosystem performance intelligence**. [export reference: filecite | turn47file0 | L141-L154]

So what we're seeing in Power BI is actually consistent with the roadmap.

### What P03 really is

Our current page follows:

**Merchant → current application → decision → funding → account performance → monitoring → intervention/servicing**

The merchant profile provides **prior-relationship context**, but those prior advances are attributes feeding the current decision. They are not separate historical advances/accounts whose complete lifecycles are represented in the current Module 2 analytical population.

That's exactly what we discovered empirically when Merchant 000301 showed:

**Prior advances = 1 / Prior funded ≈ $86.6K**

while the current application is a **Policy decline** and there is no corresponding prior-account lifecycle available to navigate on this page.

So calling the page **Merchant Relationship 360** overstates what the present model actually supplies.

## I would rename it now

My strongest recommendation is:

### **Merchant Application & Account Journey**

Subtitle:

> **Follow one synthetic merchant application from request and decision through funding, performance, monitoring and servicing.**

That precisely describes the page we actually built.

It also works beautifully with declined/review applications: their journey legitimately ends at decision, while funded applications continue through the account lifecycle.

There is another benefit: this essentially means we have organically built what our roadmap called **Application & Account Journey**, rather than the originally planned Merchant Relationship 360. That is not a failure—we learned the model boundary by building against it.

### What happens to the real Merchant Relationship 360?

**Keep it on the roadmap, but defer it until the data supports the name.**

A genuine future Merchant Relationship 360 should eventually let us select Merchant `000301` and see something conceptually like:

**Relationship established → Application A01 → Advance 1 → performance/payoff → Application A02 → decision → Advance 2 → renewal/re-underwriting → current relationship posture**

with multiple accounts/advances, closures, repeat applications, renewals, cumulative relationship economics, and possibly merchant-services/deposit relationships.

That becomes increasingly appropriate as the simulator matures into Years 2–3 and especially Years 3–5. The roadmap explicitly puts renewal/repeat performance and merchant lifetime/relationship value into Years 2–3, and relationship-level value and broader facilities into Years 3–5. [export reference: filecite | turn47file0 | L37-L49] [export reference: filecite | turn47file0 | L81-L88]

I would therefore **not manufacture that history now** merely to justify the page title.

### One implication for our page roadmap

We originally had both:

- **Merchant Relationship 360**
- **Application & Account Journey**

I now think the physical build has shown us those should **not both be current-wave pages**.

The page we're building is P03 **Application & Account Journey**.

The richer **Merchant Relationship 360** should move to a later simulator/model wave when we have actual multi-application/multi-advance longitudinal relationship data. At that point it becomes a genuinely differentiated experience rather than a second page rearranging the same current application.

That is exactly the sort of useful discovery Audit authorized the build-first operating model to surface.

**So I recommend changing the title and subtitle now to `Merchant Application & Account Journey` and the wording above.** Then we finish this page against that truthful contract and document that full Merchant Relationship 360 is deferred pending multi-generation relationship/account history. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-70a79c4f-1185-47da-88de-5e5b6d1285d8"></a>
## Andrew / user · C109-M00396

C109-M00396 · 2026-08-27T05:03:35.922000-04:00 · active path

Preceding visible parent: [C109-M00395](part-14.md#m-9ad366f4-034a-4316-bcd7-70e130e07e48)

<!-- BEGIN_SOURCE_MESSAGE -->
I confirmed with my earlier build chat: No. **By the end of Module 2, the current synthetic population does not have merchants with multiple applications.**

The important distinction is:

- **Merchant population:** 4,352 merchants. 
- **Application population:** 750 applications. 
-  Those 750 applications represent **750 distinct merchants** in the current governed build. 
-  A merchant can accumulate many downstream records because of scenarios, candidate structures, simulations, servicing/account observations, etc., but those are **not additional applications**. 
-  Therefore, the current relationship at the application level is effectively **1 merchant → 0 or 1 application**, not **1 merchant → many applications**. 

That matters for the Power BI work we are doing. When we select a Merchant ID today, we can safely treat the associated application as singular. We **should not design the Merchant Detail page as though multiple historical applications already exist**.

However, I would preserve the model architecture so that **merchant → multiple applications** can be introduced later. That is a very natural evolution for Module 3 / the longitudinal portfolio: a merchant could apply, receive an advance, perform over time, seek a renewal or additional advance, and generate another application/decision cycle. That is where the merchant-level history becomes substantially more valuable.
<!-- END_SOURCE_MESSAGE -->
