# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 16 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-15.md)
[Next part](part-17.md)

<a id="m-a8153ab7-cfe0-44e5-b343-7a96ce40ffd5"></a>
## Assistant · C109-M00425

C109-M00425 · 2026-08-27T08:13:39.958370-04:00 · active path

Preceding visible parent: [C109-M00424](part-15.md#m-3bc43e39-f119-44c1-a7e9-d738a2e7dfbe)

<!-- BEGIN_SOURCE_MESSAGE -->
Ingested. `FactServicingExecution` is the strongest operational fact we have seen so far for P04, and it confirms that this page should be built as a **small but precise servicing workbench**, not as a broad production-collections dashboard.

The table is at one row per scenario-qualified account/advance servicing-execution outcome. It carries account identity, source operational setup, servicing outcome/action/queue, processing flags, lifecycle state, payment-event counts, payment amounts, ending simulated exposure, and execution reasons. That is enough to support both the top servicing KPIs and the operational-detail table. [export reference: filecite | turn50file0 | L1-L6]

Two rows define the actual workload population. Merchant 000312 / Baseline is the active-processing case: `$518.04` source exposure, `SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE`, queue `TEMPORARY_PAYMENT_PROCESSING`, processing authorized, seven payment events, one return, one retry, and `$323.79` ending simulated exposure. Merchant 000098 / Baseline is the review-hold case: `$461.69` exposure, `SERVICING_EXECUTION_REVIEW_HOLD`, queue `SERVICING_REVIEW_HOLD`, review required, zero payment events, and `$461.69` ending exposure. [export reference: filecite | turn50file0 | L5-L6]

Everything else in the supplied population follows the no-processing path: `NO_SERVICING_EXECUTION_REQUIRED`, `NO_PAYMENT_PROCESSING`, `CLOSED_NO_PROCESSING`, zero processing amounts, and zero ending exposure. Merchant 000749 from P03 is one example. [export reference: filecite | turn50file0 | L26-L26]

That gives us a very useful operational hierarchy for P04:

**Normal / no servicing**
→ closed, no processing required

**Active servicing**
→ temporary payment processing

**Review required**
→ servicing review hold

Those are distinct enough to support a small status distribution.

### Fields I would treat as report-grade

From `FactServicingExecution`, these are the fields worth designing around:

```text
merchant_id
merchant_application_id
source_exposure_amount
servicing_execution_outcome_code
servicing_execution_action_code
servicing_execution_priority_rank
servicing_execution_queue_code
processing_authorized_flag
processing_review_required_flag
no_processing_required_flag
final_lifecycle_state_code
payment_event_count
returned_event_count
retry_event_count
scheduled_payment_amount
processed_payment_amount
returned_payment_amount
retry_payment_amount
ending_simulated_exposure_amount
primary_execution_reason_code
AccountKey
```

The hashes, contract metadata, methodology/version fields, and synthetic execution IDs belong in lineage/evidence, not the main page.

### This changes the KPI recommendation slightly

I would now anchor the **top KPI strip on `FactServicingExecution`**, because it gives us a clean account-grain servicing posture.

The first four KPIs I want are:

**Accounts requiring attention**  
Count rows where either:

```text
processing_authorized_flag = TRUE
OR
processing_review_required_flag = TRUE
```

**Exposure requiring attention**  
Sum `source_exposure_amount` over those same rows.

**Active servicing**  
Count rows where `processing_authorized_flag = TRUE`.

**Review holds**  
Count rows where `processing_review_required_flag = TRUE`.

For the full current population, we expect approximately:

```text
Accounts requiring attention     2
Exposure requiring attention     $979.73
Active servicing                 1
Review holds                     1
```

across both scenarios together, although with the required single-select Scenario slicer the visible values will depend on which scenario owns those two rows. The two supplied actionable rows are both Baseline. [export reference: filecite | turn50file0 | L5-L6]

I would **not** make “57 no processing required” a headline KPI. That's useful context for a distribution chart, but the page should foreground exceptions.

### The execution fact is not date-as-of

One important boundary has also become clear: `FactServicingExecution` itself does **not contain an operational event date** other than `created_at`, which is artifact creation metadata. So the Observation-date slicer should **not directly filter this execution fact as though servicing execution happened on `created_at`**.

That means P04 will likely combine:

- **as-of monitoring state** from `FactAccountDaily` / endpoint facts,
- **dated exception history** from `FactPaymentException`,
- **servicing outcome state** from `FactServicingExecution`.

We need to be careful not to pretend all three are the same temporal grain.

### Next table

Before constructing measures, send me **`FactServicingQueueEndpoint`** next.

That is the crucial one because it may already provide the governed endpoint summary of servicing queue, exposure and burden. If it does, we may use:

- daily/as-of monitoring for current operational condition,
- endpoint queue for certified servicing posture,
- execution fact for the specific action/outcome,
- payment exception for case history.

Once I ingest `FactServicingQueueEndpoint`, we should have enough to lock P04's exact KPI architecture and start building.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0c0f7787-fb87-40f8-99c9-79d6b35f23e4"></a>
## Andrew / user · C109-M00426

C109-M00426 · 2026-08-27T08:14:29.496000-04:00 · active path

Preceding visible parent: [C109-M00425](part-16.md#m-a8153ab7-cfe0-44e5-b343-7a96ce40ffd5)

<!-- BEGIN_SOURCE_MESSAGE -->
factservicingqueueendpoint : 

| module1\_run\_id servicing\_queue\_code account\_count scenario\_count certified\_exposure\_amount payment\_event\_count exception\_case\_count resolved\_exception\_count unresolved\_exception\_count servicing\_burden\_units maximum\_tier\_rank row\_hash created\_at  |                          |    |   |        |   |   |   |   |   |   |                                  |          |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------ | -- | - | ------ | - | - | - | - | - | - | -------------------------------- | -------- |
| 1                                                                                                                                                                                                                                                                           | ACTIVE\_REASSESSMENT     | 1  | 1 | 323.79 | 7 | 1 | 1 | 0 | 2 | 1 | c4dca8f26dc946f4f8faeab96ace3fb6 | 8/4/2026 |
| 1                                                                                                                                                                                                                                                                           | GOVERNANCE\_REVIEW\_HOLD | 1  | 1 | 461.69 | 0 | 0 | 0 | 0 | 5 | 2 | ee2bd79461c84bb18d13e31af768fbc3 | 8/4/2026 |
| 1                                                                                                                                                                                                                                                                           | NO\_SERVICING\_REQUIRED  | 57 | 2 | 0      | 0 | 0 | 0 | 0 | 0 | 0 | 97c04aff7b6d829daf49de5f264ef01e | 8/4/2026 |
<!-- END_SOURCE_MESSAGE -->


<a id="m-7662782e-144f-42f2-9ab4-9bcd176e5714"></a>
## Assistant · C109-M00427

C109-M00427 · 2026-08-27T08:14:31.392879-04:00 · active path

Preceding visible parent: [C109-M00426](part-16.md#m-0c0f7787-fb87-40f8-99c9-79d6b35f23e4)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. `FactServicingQueueEndpoint` clarifies the architecture substantially.

It is **not scenario-grain**. It is an endpoint aggregate across the accepted population, with `scenario_count` telling us how many scenarios contribute to each queue. Therefore, **we should not use it for Scenario-sensitive P04 KPIs**. Doing so would make a Baseline/Recession Energy slicer appear to control figures that are actually cross-scenario endpoint aggregates.

Its three rows reconcile cleanly to the servicing-execution population:

| Queue | Accounts | Certified exposure | Burden | Interpretation |
|---|---:|---:|---:|---|
| Active reassessment | 1 | $323.79 | 2 | Active temporary-processing account |
| Governance review hold | 1 | $461.69 | 5 | Controlled review account |
| No servicing required | 57 | $0 | 0 | Remaining funded account paths |

That gives **59 account paths**, **$785.48 certified endpoint exposure**, and **7 servicing-burden units**. It also confirms one exception case, resolved, and zero unresolved exceptions.

### Important distinction from `FactServicingExecution`

We now have two different exposure concepts:

- `FactServicingExecution[source_exposure_amount]`: exposure entering the servicing execution stage.
  - 312 = **$518.04**
  - 098 = **$461.69**
  - attention population = **$979.73**

- `FactServicingQueueEndpoint[certified_exposure_amount]`: certified **ending** exposure.
  - Active reassessment = **$323.79**
  - Governance review hold = **$461.69**
  - attention population = **$785.48**

Those are both valid, but they answer different questions.

For a page titled **Servicing & Exceptions**, I strongly prefer the second for a headline:

**Current servicing exposure: $785.48**

because it represents the endpoint posture rather than the amount entering servicing.

## But we should not start building yet

This table exposes an important temporal issue that we need to resolve first.

Our original P04 concept included an **Observation date** slicer. But `FactServicingQueueEndpoint` is endpoint-only, while `FactServicingExecution` is an execution-state snapshot and `FactPaymentException` contains actual event dates. Mixing those under an Observation-date slicer could imply historical as-of servicing states that these facts do not actually contain.

So I want to inspect **`FactMonitoringEndpoint` next**.

That table may tell us whether P04 should ultimately be:

**A. an Observation-date operational workbench**, with endpoint servicing information carefully gated, or

**B. an endpoint servicing/exception workbench**, with no Observation-date slicer at all.

Given what we've learned from P03, I would much rather discover that now than build five visuals and later realize the temporal contract is wrong.

Please send **`FactMonitoringEndpoint`** next. After that, I expect we'll be able to lock the temporal contract and begin actual P04 construction.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f2973fe1-0b1c-4889-8878-37f2ec3df782"></a>
## Andrew / user · C109-M00428

C109-M00428 · 2026-08-27T08:15:18.583000-04:00 · active path

Preceding visible parent: [C109-M00427](part-16.md#m-7662782e-144f-42f2-9ab4-9bcd176e5714)

**Editorial record note:** Attachment references: Pasted markdown(20260827-121509).md

<!-- BEGIN_SOURCE_MESSAGE -->
factmonitoringendpoint : 
<!-- END_SOURCE_MESSAGE -->


<a id="m-4513ecdd-dcdb-4dc1-8cc2-8afa74c3a9c1"></a>
## Assistant · C109-M00429

C109-M00429 · 2026-08-27T08:15:23.224945-04:00 · active path

Preceding visible parent: [C109-M00428](part-16.md#m-f2973fe1-0b1c-4889-8878-37f2ec3df782)

<!-- BEGIN_SOURCE_MESSAGE -->
Ingested. `FactMonitoringEndpoint` resolves the temporal question.

This is explicitly an **endpoint fact**: every supplied row has `latest_monitoring_day_index = 120` and `latest_monitoring_date = 11/22/2026`. It provides one terminal monitoring state per scenario-qualified funded account, including status, exposure, pace, remittance recency, liquidity indicators, alerts and monitoring reason. [export reference: filecite | turn51file0 | L1-L8]

The two materially distressed Baseline accounts are exactly the ones we already identified operationally:

- **Merchant 000312:** Severe shortfall, remaining receivable **$518.04**, pace **97.69%**, one active alert, not paid off. [export reference: filecite | turn51file0 | L25-L25]
- **Merchant 000098:** Severe shortfall, remaining receivable **$461.69**, pace **91.27%**, one active alert, not paid off. [export reference: filecite | turn51file0 | L34-L34]

That reconciles the **$979.73 monitoring exposure** entering the servicing decision. The servicing layer then distinguishes what happens next: 312 receives temporary payment processing, reducing its certified ending exposure to $323.79, while 098 remains on governance review hold at $461.69. Hence the servicing endpoint becomes **$785.48**.

That progression is actually a very good story:

**Monitoring identifies $979.73 requiring attention → governed servicing acts/reviews → certified servicing endpoint exposure is $785.48.**

## Lock the P04 temporal contract

I recommend **no Observation Date slicer on P04**.

P04 should be explicitly an **endpoint operational workbench as of November 22, 2026**.

Why? Because:

- `FactMonitoringEndpoint` = November 22 endpoint.
- `FactServicingQueueEndpoint` = certified servicing endpoint.
- `FactServicingExecution` = servicing-execution result/state.
- `FactPaymentException` = dated case history associated with that servicing process.

An Observation-date slicer would falsely suggest we can reconstruct the complete servicing queue as it existed on arbitrary dates. We cannot from these endpoint/execution facts.

`FactAccountDaily` remains useful for P03's longitudinal journey, but P04 is answering a different question: **what requires attention at the governed endpoint?**

## We can now start construction

Create a **fresh blank page**.

Use:

**Tab**
`P04 - Servicing & Exceptions`

**Title**
`Servicing & Exceptions`

**Subtitle**
`Identify accounts requiring operational attention, understand the drivers, and review governed servicing outcomes.`

I changed the earlier subtitle slightly. I prefer **“review governed servicing outcomes”** to “quantify the associated exposure” because the page is going to do both, and the former better captures its operational purpose.

### Top slicers

For now, create only:

**Scenario**

Single-select, Select All off.

Do **not** create Observation date.

I would eventually consider Industry as a second slicer, but not yet.

---

# First visual: endpoint monitoring KPI strip

Let's build four cards across the top, immediately under the title/slicer area.

Because `FactMonitoringEndpoint` is scenario-grain, these will respond correctly to Scenario.

### KPI 1 — Accounts requiring attention

Create:

```DAX
P04 Accounts Requiring Attention =
CALCULATE (
    DISTINCTCOUNT ( FactMonitoringEndpoint[AccountKey] ),
    FactMonitoringEndpoint[latest_monitoring_status_rank] > 0
)
```

However, I want to flag something before we blindly accept that definition: rank > 0 may include terminal/status conditions that aren't actually servicing-worthy. From the rows we've seen, most endpoints are Paid Off = rank 0, while the two severe-shortfall accounts are rank 4. But we should test the distribution before freezing the definition.

So create a temporary table first:

**Rows**
- `latest_monitoring_status_code`
- `latest_monitoring_status_rank`

**Value**
- distinct count `AccountKey`

With Scenario = **Baseline**.

Tell me what that table shows.

That will tell us whether `> 0` safely means **attention required**, or whether there are Current/Watch/Underperforming endpoint populations that need a more nuanced definition.

### Why we're pausing at that tiny test

This is exactly the sort of physical-model discovery that improved P03.

I don't want to define “Accounts requiring attention” as rank > 0 and then discover that 20 perfectly normal Current accounts are rank 1. The monitoring hierarchy appears to be:

```text
0  Paid off
1  Current
2  Watch
3  Underperforming
4  Severe shortfall
```

If so, our operational attention threshold may be `>= 2`, or perhaps only specific alert/servicing states. We should let the actual endpoint population answer that.

So the immediate steps are:

1. Create fresh P04.
2. Add title/subtitle.
3. Add **Scenario** single-select slicer.
4. Unhide `FactMonitoringEndpoint` if necessary.
5. Create the temporary status/rank/count table under **Baseline**.
6. Send me the result.

Then we'll lock the definition of **Accounts requiring attention** and construct the real KPI strip.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cf5b1c53-f15b-466f-9fd4-f5e64d0cac4c"></a>
## Andrew / user · C109-M00430

C109-M00430 · 2026-08-27T08:17:54.166000-04:00 · active path

Preceding visible parent: [C109-M00429](part-16.md#m-4513ecdd-dcdb-4dc1-8cc2-8afa74c3a9c1)

<!-- BEGIN_SOURCE_MESSAGE -->
are we going to have a left hand side card like we've had in P01 through P03? Wondering why KPI 1 would not fit into that.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f522b361-9011-4b0c-84d3-087a5efd195a"></a>
## Assistant · C109-M00431

C109-M00431 · 2026-08-27T08:17:56.015046-04:00 · active path

Preceding visible parent: [C109-M00430](part-16.md#m-cf5b1c53-f15b-466f-9fd4-f5e64d0cac4c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I think your instinct is better than the layout I just proposed.

We **should preserve the left-hand summary rail established in P01–P03**. It has become part of the report's visual grammar: controls/context at the top, a compact executive summary on the left, and the deeper analytical story across the larger right-hand canvas.

For P04, though, the left rail should not be a merchant profile. It should be an **Operational Posture** multi-card.

### Proposed P04 left rail

I would reserve roughly the same width as P03's Merchant Profile and eventually populate it with something like:

**Operational Posture**

**Accounts requiring attention**  
`2`

**Attention exposure**  
`$979.73`

**Active servicing**  
`1`

**Review holds**  
`1`

**Active alerts**  
`2`

**Unresolved exceptions**  
`0`

Potentially one or two additional values if physical construction demonstrates they add something—perhaps **Servicing burden** or **Certified servicing exposure**.

That is much better than scattering six individual KPI cards across the top.

### Why `Accounts requiring attention` belongs there

It becomes the lead value in the left rail—the operational equivalent of the merchant identity/context rail on P03.

The page then reads naturally:

**Left:** *How much attention is required?*  
**Upper right:** *Where/why is attention required?*  
**Middle/right:** *What servicing posture/action resulted?*  
**Bottom/right:** *Which specific accounts require investigation?*

That gives us much more canvas for the actual workbench.

### One important semantic issue

I would still **not create the final `Accounts requiring attention` measure yet**. We need the tiny status-distribution test I requested, because we have not established whether `latest_monitoring_status_rank > 0` is the correct business definition.

In fact, now that we've ingested the servicing tables, I suspect the best headline definition may ultimately be **governed servicing attention**, rather than simply monitoring deterioration.

For example, the two known Baseline cases tell a clean story:

- 312 → severe shortfall → temporary processing
- 098 → severe shortfall → governance review hold

But we need to determine whether `WATCH` or `UNDERPERFORMING` accounts exist at the endpoint and whether those count as “requiring attention” even when no servicing execution was generated.

### Layout adjustment

I would therefore build the shell as:

```text
┌───────────────────────────────────────────────────────────────┐
│ Servicing & Exceptions                         [Scenario ▼]   │
│ Identify accounts requiring operational attention...         │
├───────────────┬───────────────────────────────────────────────┤
│               │                                               │
│ OPERATIONAL   │        Monitoring / attention visuals         │
│ POSTURE       │                                               │
│               ├───────────────────────────────────────────────┤
│ Attention     │                                               │
│ accounts      │        Servicing / queue / driver             │
│ Exposure      │                                               │
│ Active svc    ├───────────────────────────────────────────────┤
│ Review holds  │                                               │
│ Alerts        │        Account exception workbench            │
│ Exceptions    │                                               │
│               │                                               │
└───────────────┴───────────────────────────────────────────────┘
```

And I would make the left rail a **single multi-card**, just as we learned works well on P03. That means one visual, one alt text, compact formatting, and consistent page architecture.

So yes: **reserve the left-hand side now. Don't build a top-row KPI strip.**

Next, let's perform the temporary Baseline `latest_monitoring_status_code / rank / account count` test. Once we see that population, we'll know exactly what the first value in the Operational Posture card should mean and can start filling that card from the top down.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4450cb10-f75e-427f-bf3e-dccb7cfe38bb"></a>
## Andrew / user · C109-M00432

C109-M00432 · 2026-08-27T08:19:12.207000-04:00 · active path

Preceding visible parent: [C109-M00431](part-16.md#m-f522b361-9011-4b0c-84d3-087a5efd195a)

<!-- BEGIN_SOURCE_MESSAGE -->
why temporary tables - i provided the full datasets. what more do you need to guide construction?
<!-- END_SOURCE_MESSAGE -->


<a id="m-5d59b651-5983-4765-acf6-6dd273ad3d5f"></a>
## Assistant · C109-M00433

C109-M00433 · 2026-08-27T08:19:24.915118-04:00 · active path

Preceding visible parent: [C109-M00432](part-16.md#m-4450cb10-f75e-427f-bf3e-dccb7cfe38bb)

<!-- BEGIN_SOURCE_MESSAGE -->
You're right. **We do not need temporary diagnostic tables here.** You supplied the full datasets, and I should use them directly.

From the complete `FactMonitoringEndpoint` population, the endpoint state is already clear:

- **Baseline:** 44 funded account paths = **42 Paid Off + 2 Severe Shortfall**
- **Recession Energy:** 15 funded account paths = **15 Paid Off**
- The two Baseline Severe Shortfall accounts are **Merchant 000312 ($518.04 remaining receivable)** and **Merchant 000098 ($461.69)**. [export reference: filecite | turn51file0 | L25-L25] [export reference: filecite | turn51file0 | L34-L34]
- Therefore, at the endpoint, `latest_monitoring_status_rank > 0` **does cleanly identify the attention population in this build**: 2 accounts / $979.73 in Baseline, 0 in Recession Energy.
- `FactServicingExecution` then routes those two Baseline accounts differently: 000312 into active temporary processing and 000098 into servicing review hold. [export reference: filecite | turn50file0 | L5-L6]

So we can stop probing and **build**.

## P04 shell

Use the left-side rail, consistent with P01–P03.

**Tab:** `P04 - Servicing & Exceptions`

**Title:** `Servicing & Exceptions`

**Subtitle:**  
`Identify accounts requiring operational attention, understand the drivers, and review governed servicing outcomes.`

Top-right control:

**Scenario** — single select, Select All off.

No Observation Date slicer. P04 is an **endpoint operational workbench**, not an arbitrary historical as-of servicing view.

## Build the left multi-card: `Operational Posture`

I recommend six values. These all remain Scenario-sensitive and avoid using the cross-scenario `FactServicingQueueEndpoint` aggregate directly.

Create these measures.

### 1. Accounts requiring attention

```DAX
P04 Accounts Requiring Attention =
CALCULATE (
    DISTINCTCOUNT ( FactMonitoringEndpoint[AccountKey] ),
    FactMonitoringEndpoint[latest_monitoring_status_rank] > 0
)
```

Expected:
- Baseline = **2**
- Recession Energy = **0**

### 2. Attention exposure

```DAX
P04 Attention Exposure =
CALCULATE (
    SUM ( FactMonitoringEndpoint[remaining_receivable_amount] ),
    FactMonitoringEndpoint[latest_monitoring_status_rank] > 0
)
```

Expected:
- Baseline = **$979.73**
- Recession Energy = **$0**

This is the exposure identified by endpoint monitoring **before the servicing execution outcome**.

### 3. Active servicing

```DAX
P04 Active Servicing =
CALCULATE (
    DISTINCTCOUNT ( FactServicingExecution[AccountKey] ),
    FactServicingExecution[processing_authorized_flag] = TRUE ()
)
```

Expected:
- Baseline = **1**
- Recession Energy = **0**

### 4. Review holds

```DAX
P04 Review Holds =
CALCULATE (
    DISTINCTCOUNT ( FactServicingExecution[AccountKey] ),
    FactServicingExecution[processing_review_required_flag] = TRUE ()
)
```

Expected:
- Baseline = **1**
- Recession Energy = **0**

### 5. Servicing exposure

This is useful because it shows what remains after the servicing-execution state has been applied:

```DAX
P04 Servicing Exposure =
CALCULATE (
    SUM ( FactServicingExecution[ending_simulated_exposure_amount] ),
    FactServicingExecution[no_processing_required_flag] = FALSE ()
)
```

Expected Baseline:

**$785.48**

That decomposes into:
- 000312 active processing = **$323.79**
- 000098 review hold = **$461.69**

This creates a useful contrast with **Attention Exposure = $979.73**.

### 6. Unresolved exceptions

```DAX
P04 Unresolved Exceptions =
CALCULATE (
    DISTINCTCOUNT ( FactPaymentException[PaymentExceptionKey] ),
    FactPaymentException[unresolved_exception_flag] = TRUE ()
)
```

Expected:
- Baseline = **0**
- Recession Energy = **0**

That zero is valuable here because it tells the operational user that the payment exception generated during the temporary-processing cycle was resolved rather than sitting in backlog.

## Multi-card order

Build one multi-card on the left, titled:

**Operational Posture**

Put the measures in this order:

1. Accounts requiring attention
2. Attention exposure
3. Active servicing
4. Review holds
5. Servicing exposure
6. Unresolved exceptions

That tells a compact story:

**2 accounts identified → $979.73 at risk/attention → 1 actively serviced + 1 held for review → $785.48 remaining servicing exposure → no unresolved exception backlog.**

That is much more useful than six disconnected KPI boxes.

### One thing I would not include yet: `Active alerts`

The endpoint data contains `active_alert_count = 1` on some accounts that are nevertheless **Paid Off**, apparently because the alert payload can retain things such as liquidity-stress indicators at the endpoint. For example, some paid-off rows still carry an active-alert count. [export reference: filecite | turn51file0 | L21-L21]

So I would **not call a raw sum of `active_alert_count` “Active alerts”** without a more careful semantic definition. The six measures above are cleaner.

## Then the first right-hand visual

Once that left card is working, the first substantive visual should be **Monitoring posture**, not another KPI.

I recommend a horizontal bar chart:

**Y-axis**
`FactMonitoringEndpoint[latest_monitoring_status_code]`

**X-axis**
Distinct count of `AccountKey`

With the Scenario slicer controlling it.

Baseline should immediately show the stark endpoint distribution:

**Paid Off — 42**  
**Severe Shortfall — 2**

and Recession Energy:

**Paid Off — 15**

We should create a polished presentation label column for those status codes rather than display `SEVERE_SHORTFALL`.

So the immediate construction sequence is now straightforward: **create the page shell → Scenario slicer → Operational Posture multi-card with these six measures → then Monitoring Posture chart.** No temporary tables needed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f8260fc6-b21c-423a-98f4-a717de11cb9e"></a>
## Andrew / user · C109-M00434

C109-M00434 · 2026-08-27T08:52:04.092000-04:00 · active path

Preceding visible parent: [C109-M00433](part-16.md#m-5d59b651-5983-4765-acf6-6dd273ad3d5f)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 91c55c4a-cc03-4981-86f7-516be8678b2f.png

<!-- BEGIN_SOURCE_MESSAGE -->
latest_monitoring_status_code can't be in y-axis: please stop making that mistake.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d0ffa82c-5525-4dc3-88c9-605a47b5699c"></a>
## Assistant · C109-M00435

C109-M00435 · 2026-08-27T08:52:10.896037-04:00 · active path

Preceding visible parent: [C109-M00434](part-16.md#m-f8260fc6-b21c-423a-98f4-a717de11cb9e)

<!-- BEGIN_SOURCE_MESSAGE -->
You're right. With **Discourage implicit measures** enabled, I should not tell you to drag raw numeric/text fields into visuals when Power BI requires an explicit measure for the value context. I’ll treat that as a hard construction rule from here forward.

For the Monitoring posture chart, keep the raw status field only as the category **if Power BI allows it there**, but use an explicit measure for the count. If even the category field is blocked in that visual, then we need a small presentation table/column strategy instead of forcing it.

Create this measure:

```DAX
P04 Monitoring Account Count =
DISTINCTCOUNT ( FactMonitoringEndpoint[AccountKey] )
```

Then try:

- **Y-axis:** `FactMonitoringEndpoint[latest_monitoring_status_code]`
- **X-axis / Values:** `[P04 Monitoring Account Count]`

If Power BI still refuses `latest_monitoring_status_code` on the Y-axis, then stop there and tell me. In that case I’ll give you the correct workaround using a report-owned presentation dimension/column rather than repeating the same mistake.

Also, for presentation, I would not leave the raw codes visible anyway. We will likely create a proper label such as:

- `Paid off`
- `Current`
- `Watch`
- `Underperforming`
- `Severe shortfall`

with a governed sort rank.

I’ll keep the build guidance explicit-measure-safe from this point forward.
<!-- END_SOURCE_MESSAGE -->


<a id="m-481d901c-ac3a-4142-80b0-e244ae519994"></a>
## Andrew / user · C109-M00436

C109-M00436 · 2026-08-27T08:56:47.208000-04:00 · active path

Preceding visible parent: [C109-M00435](part-16.md#m-d0ffa82c-5525-4dc3-88c9-605a47b5699c)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: a05ab2da-120a-485f-be05-c18c3c425b51.png

<!-- BEGIN_SOURCE_MESSAGE -->
 can't be on x-axis and confirmed that latest_monitoring_status_code can't be on y-axis
<!-- END_SOURCE_MESSAGE -->


<a id="m-ee96eadc-7d9f-4289-b7a3-b3549a37f0cd"></a>
## Assistant · C109-M00437

C109-M00437 · 2026-08-27T08:56:51.691472-04:00 · active path

Preceding visible parent: [C109-M00436](part-16.md#m-481d901c-ac3a-4142-80b0-e244ae519994)

<!-- BEGIN_SOURCE_MESSAGE -->
This tells us exactly what happened: **the selected visual is using column-chart field roles, not bar-chart roles.** The errors are complementary:

- `latest_monitoring_status_code` on **Y-axis** → Power BI says a **measure is required**.
- `[P04 Monitoring Account Count]` on **X-axis** → Power BI says a **non-measure field is required**.

So Power BI is telling us:

**X-axis = category**  
**Y-axis = measure**

That means either keep the current column chart and use:

- **X-axis:** `FactMonitoringEndpoint[latest_monitoring_status_code]`
- **Y-axis:** `[P04 Monitoring Account Count]`

or, if we want the horizontal bar chart I originally proposed, first change the visual type to **Clustered bar chart**. Then use:

- **Y-axis:** `FactMonitoringEndpoint[latest_monitoring_status_code]`
- **X-axis:** `[P04 Monitoring Account Count]`

I recommend the **horizontal clustered bar chart**, because the status labels will read much better—especially `Severe shortfall`—and it fits the operational-workbench design.

### Before adding the fields, create the presentation label

Rather than showing `PAID_OFF` and `SEVERE_SHORTFALL`, create a **calculated column** in `FactMonitoringEndpoint`:

```DAX
P04 Monitoring Status =
SWITCH (
    FactMonitoringEndpoint[latest_monitoring_status_code],
    "PAID_OFF", "Paid off",
    "CURRENT", "Current",
    "WATCH", "Watch",
    "UNDERPERFORMING", "Underperforming",
    "SEVERE_SHORTFALL", "Severe shortfall",
    SUBSTITUTE (
        FactMonitoringEndpoint[latest_monitoring_status_code],
        "_",
        " "
    )
)
```

And a sort column:

```DAX
P04 Monitoring Status Sort =
SWITCH (
    FactMonitoringEndpoint[latest_monitoring_status_code],
    "SEVERE_SHORTFALL", 1,
    "UNDERPERFORMING", 2,
    "WATCH", 3,
    "CURRENT", 4,
    "PAID_OFF", 5,
    99
)
```

Then set:

**`P04 Monitoring Status` → Sort by column → `P04 Monitoring Status Sort`**

### Build the chart

Select **Clustered bar chart**, then:

**Y-axis**
`P04 Monitoring Status`

**X-axis**
`[P04 Monitoring Account Count]`

For **Baseline**, based on the full endpoint population you supplied, we should see:

- Paid off — **42**
- Severe shortfall — **2**

For **Recession Energy**:

- Paid off — **15**

That is the correct explicit-measure-safe construction. The issue wasn't that categorical fields cannot be used; I had the axis roles wrong for the visual you currently had selected.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3ad25cd2-6bf2-447b-8169-2bb708de12aa"></a>
## Andrew / user · C109-M00438

C109-M00438 · 2026-08-27T08:57:40.681000-04:00 · active path

Preceding visible parent: [C109-M00437](part-16.md#m-ee96eadc-7d9f-4289-b7a3-b3549a37f0cd)

<!-- BEGIN_SOURCE_MESSAGE -->
oh i had this as a line chart still - what should it be?
<!-- END_SOURCE_MESSAGE -->


<a id="m-355c0d13-3471-451e-be1b-ec4ea72fd710"></a>
## Assistant · C109-M00439

C109-M00439 · 2026-08-27T08:57:42.473858-04:00 · active path

Preceding visible parent: [C109-M00438](part-16.md#m-3ad25cd2-6bf2-447b-8169-2bb708de12aa)

<!-- BEGIN_SOURCE_MESSAGE -->
Use a **Clustered bar chart** — horizontal bars.

This is a categorical endpoint comparison, not a time series, so a line chart is the wrong visual. We want to compare the number of accounts in each monitoring status.

Set it up as:

- **Visual:** Clustered bar chart
- **Y-axis:** `P04 Monitoring Status` — the calculated presentation column
- **X-axis:** `[P04 Monitoring Account Count]` — the explicit measure
- **Legend:** none
- **Title:** `Monitoring posture`

For Baseline, it should show essentially:

**Severe shortfall** | 2  
**Paid off** | 42

The horizontal format is preferable because later status labels such as **Underperforming** and **Severe shortfall** remain easy to read if the population expands.

And yes—the errors now make complete sense. They weren't related to Discourage Implicit Measures; you still had a **line chart**, whose X-axis expects the category and Y-axis expects the measure. My initial assumption about your selected visual caused the confusion.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9fd3aa31-c32e-43f3-a3fc-e1154b8da468"></a>
## Andrew / user · C109-M00440

C109-M00440 · 2026-08-27T09:11:16.266000-04:00 · active path

Preceding visible parent: [C109-M00439](part-16.md#m-355c0d13-3471-451e-be1b-ec4ea72fd710)

<!-- BEGIN_SOURCE_MESSAGE -->
the clustered bar chart - Monitoring posture is built
<!-- END_SOURCE_MESSAGE -->


<a id="m-cb91e5e9-c97d-447c-8a4f-4fdcb59f8210"></a>
## Assistant · C109-M00441

C109-M00441 · 2026-08-27T09:11:18.262206-04:00 · active path

Preceding visible parent: [C109-M00440](part-16.md#m-9fd3aa31-c32e-43f3-a3fc-e1154b8da468)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. Keep **Monitoring posture** as the first right-hand visual. Now I would build the complementary visual that answers **“what happened to the accounts requiring attention?”**

## Next visual — Servicing disposition

Use a **clustered bar chart** again.

First create a presentation column in `FactServicingExecution`:

```DAX
P04 Servicing Disposition =
SWITCH (
    FactServicingExecution[servicing_execution_outcome_code],
    "NO_SERVICING_EXECUTION_REQUIRED", "No servicing required",
    "SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE", "Active servicing",
    "SERVICING_EXECUTION_REVIEW_HOLD", "Review hold",
    SUBSTITUTE (
        FactServicingExecution[servicing_execution_outcome_code],
        "_",
        " "
    )
)
```

Then create the explicit measure:

```DAX
P04 Servicing Account Count =
DISTINCTCOUNT ( FactServicingExecution[AccountKey] )
```

Build:

- **Visual:** Clustered bar chart
- **Y-axis:** `P04 Servicing Disposition`
- **X-axis:** `[P04 Servicing Account Count]`
- **Legend:** none
- **Title:** `Servicing disposition`

With **Baseline** selected, we expect the chart to show the normal population plus the two exceptional paths: one **Active servicing** and one **Review hold**.

### But I would filter out “No servicing required”

For this page, 57 normal paths will visually swamp the two cases we care about. `Monitoring posture` already provides the portfolio context.

So add a **visual-level filter**:

`P04 Servicing Disposition` **is not** `No servicing required`

Then this chart becomes intentionally focused on operational workload:

**Active servicing — 1**  
**Review hold — 1**

That is much more useful.

Place **Servicing disposition** beside or immediately below **Monitoring posture**. The pair tells a very clean story:

**Monitoring posture:** *Which accounts ended in distress?*  
→ 2 Severe shortfall

**Servicing disposition:** *What happened to them?*  
→ 1 Active servicing / 1 Review hold

Once that is built, the next visual should answer the third question: **why?** We'll use the monitoring/execution reason fields for an **Attention drivers** visual before constructing the detailed account workbench.
<!-- END_SOURCE_MESSAGE -->


<a id="m-87ee6374-f0f4-4f07-8589-a6cd28114334"></a>
## Andrew / user · C109-M00442

C109-M00442 · 2026-08-27T09:20:38.872000-04:00 · active path

Preceding visible parent: [C109-M00441](part-16.md#m-cb91e5e9-c97d-447c-8a4f-4fdcb59f8210)

<!-- BEGIN_SOURCE_MESSAGE -->
Monitoring posture and Servicing disposition are both built
<!-- END_SOURCE_MESSAGE -->


<a id="m-55169421-3415-4e31-90e6-9b36231749cc"></a>
## Assistant · C109-M00443

C109-M00443 · 2026-08-27T09:21:07.355136-04:00 · active path

Preceding visible parent: [C109-M00442](part-16.md#m-87ee6374-f0f4-4f07-8589-a6cd28114334)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. Next I would build **Attention drivers**, but based on the actual servicing execution reason—not the raw monitoring reason, which would just repeat “severe shortfall” for both actionable accounts.

Create a presentation column in `FactServicingExecution`:

```DAX
P04 Attention Driver =
SWITCH (
    FactServicingExecution[primary_execution_reason_code],
    "M2_8_REASON_SOURCE_TEMPORARY_PROCESSING", "Temporary processing required",
    "M2_8_REASON_SOURCE_REVIEW_HOLD", "Governance review required",
    "M2_8_REASON_SOURCE_NO_PROCESSING", "No servicing required",
    SUBSTITUTE (
        FactServicingExecution[primary_execution_reason_code],
        "_",
        " "
    )
)
```

The two actionable Baseline accounts genuinely have different reasons: Merchant 000312 is sourced to temporary processing, while Merchant 000098 is sourced to review hold. [export reference: filecite | turn52file0 | L9-L10]

Then use the explicit measure you already created:

```DAX
[P04 Servicing Account Count]
```

Build another **clustered bar chart**:

- **Y-axis:** `P04 Attention Driver`
- **X-axis:** `[P04 Servicing Account Count]`
- **Visual filter:** exclude `No servicing required`
- **Title:** `Attention drivers`

Expected Baseline result:

- Temporary processing required — **1**
- Governance review required — **1**

This will intentionally resemble the servicing-disposition count pattern, but it answers a different question: **why did the account enter that servicing path?**

After this, I would stop adding summary charts. The next major component should be the **account workbench table**, which is where P04 starts becoming operationally useful rather than just descriptive.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6a6994a0-d451-445c-a011-bcc6152dab98"></a>
## Andrew / user · C109-M00444

C109-M00444 · 2026-08-27T09:23:29.010000-04:00 · active path

Preceding visible parent: [C109-M00443](part-16.md#m-55169421-3415-4e31-90e6-9b36231749cc)

<!-- BEGIN_SOURCE_MESSAGE -->
but what does Temporary processing required and Governance review required and how did those accounts end up in those paths
<!-- END_SOURCE_MESSAGE -->


<a id="m-abb8976a-1bf7-4946-b99f-cfcad613165c"></a>
## Assistant · C109-M00445

C109-M00445 · 2026-08-27T09:23:31.128917-04:00 · active path

Preceding visible parent: [C109-M00444](part-16.md#m-6a6994a0-d451-445c-a011-bcc6152dab98)

<!-- BEGIN_SOURCE_MESSAGE -->
That is the more important question, and it changes my recommendation for the next visual. **“Attention drivers” based only on `primary_execution_reason_code` would be too circular**: it tells us the servicing path chosen, not what underlying account behavior caused that path.

For the two Baseline accounts, we can reconstruct the chain from the supplied facts.

### Merchant 000312 — why temporary processing?

At the monitoring endpoint, 000312 is **Severe shortfall**, not paid off, with **$518.04 remaining receivable**, **$518.04 cumulative shortfall**, cumulative pace of about **97.69%**, and an active alert. Its monitoring reason is `M2_5_STATUS_SEVERE_SHORTFALL`; the alert payload specifically says `contract_horizon_overrun = true`. [export reference: filecite | turn51file0 | L25-L25]

The servicing layer then says its upstream operational setup was:

`TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY`

with action:

`CREATE_TEMPORARY_ADJUSTMENT_BLUEPRINT`

and therefore authorized:

`SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE`

The synthetic servicing cycle changes its daily payment from **$37.00 to $27.75**, schedules/processes **$194.25** across seven events, includes one return and one retry, and reduces ending simulated exposure from **$518.04 to $323.79**. Its final lifecycle state is `REASSESSMENT_DUE`. [export reference: filecite | turn52file0 | L9-L9]

So in business language:

> **000312 reached the end of its contractual monitoring horizon with a remaining shortfall. The governed upstream setup authorized a temporary payment adjustment, so servicing executed a synthetic reduced-payment cycle and left the account due for reassessment.**

That is what **Active servicing / temporary processing** actually means here.

### Merchant 000098 — why governance review?

000098 also ends at **Severe shortfall**, not paid off, with **$461.69 remaining receivable**, **$461.69 cumulative shortfall**, approximately **91.27% cumulative pace**, and one active alert. It also carries `contract_horizon_overrun = true`. [export reference: filecite | turn51file0 | L34-L34]

But its upstream operational setup is different:

`OPERATIONAL_SETUP_REVIEW_REQUIRED`

with:

`ROUTE_OPERATIONAL_GOVERNANCE_REVIEW`

and status:

`OPERATIONAL_REVIEW_REQUIRED`

Therefore servicing **does not authorize payment processing**. Instead it produces:

`SERVICING_EXECUTION_REVIEW_HOLD`

→ `HOLD_FOR_SERVICING_REVIEW`

→ final state `SERVICING_REVIEW_HOLD`

No payment events are generated and the entire **$461.69** remains as ending exposure. [export reference: filecite | turn52file1 | L23-L24]

In business language:

> **000098 also reached the endpoint with unresolved shortfall, but the upstream governed setup did not authorize an automated temporary-payment treatment. It required operational/governance review, so servicing correctly stopped rather than executing a synthetic payment cycle.**

### The important distinction

So **Severe shortfall itself does not determine the servicing treatment**.

Both accounts have the same terminal monitoring status:

**Severe shortfall + contract horizon overrun**

but the next governed layer distinguishes them:

**000312**  
Severe shortfall → temporary adjustment setup authorized → **Active servicing** → reduced synthetic payment cycle → reassessment due

**000098**  
Severe shortfall → operational review required → **Governance review hold** → no payment processing → exposure remains held

That's actually an excellent analytical story for P04.

And it means I would **not build the `Attention drivers` bar chart I just proposed**. With only one account in each path, it would merely restate Servicing disposition.

Instead, I think the next visual should be the **Account attention workbench**, where those causal/path differences become visible at account level. We can give it columns along the lines of:

**Merchant | Monitoring status | Pace | Shortfall | Attention exposure | Servicing disposition | Treatment/action | Ending exposure | Lifecycle state**

Then 000312 and 000098 will sit side-by-side and the user can immediately understand **same monitoring problem, different governed treatment**.

That is considerably more useful than a third 1-versus-1 bar chart.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0f2abad5-5ccf-4e42-a495-da1ae7c54f98"></a>
## Andrew / user · C109-M00446

C109-M00446 · 2026-08-27T09:25:44.382000-04:00 · active path

Preceding visible parent: [C109-M00445](part-16.md#m-abb8976a-1bf7-4946-b99f-cfcad613165c)

<!-- BEGIN_SOURCE_MESSAGE -->
build **Account attention workbench**, where those causal/path differences become visible at account level. We can give it columns along the lines of:

**Merchant | Monitoring status | Pace | Shortfall | Attention exposure | Servicing disposition | Treatment/action | Ending exposure | Lifecycle state**

Then 000312 and 000098 will sit side-by-side and the user can immediately understand **same monitoring problem, different governed treatment**.

That is considerably more useful than a third 1-versus-1 bar chart.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9b2a9381-f19d-4d49-b097-9600fec6ca91"></a>
## Assistant · C109-M00447

C109-M00447 · 2026-08-27T09:25:45.974995-04:00 · active path

Preceding visible parent: [C109-M00446](part-16.md#m-0f2abad5-5ccf-4e42-a495-da1ae7c54f98)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Build this as a **Table visual**. This should become the principal operational workbench on P04.

Because we are combining fields from `FactMonitoringEndpoint` and `FactServicingExecution`, I recommend using **explicit measures for the account-specific numeric/text values** rather than dragging fact columns across grains and risking row expansion like we encountered on P03.

### 1. Merchant

We already have merchant presentation logic from P03. For this portfolio table, create a calculated column in `FactMonitoringEndpoint`:

```DAX
P04 Merchant =
VAR _Merchant = FactMonitoringEndpoint[merchant_id]
VAR _Pos = SEARCH ( "M", _Merchant, 1, BLANK() )
RETURN
    IF (
        NOT ISBLANK ( _Pos ),
        RIGHT ( _Merchant, 6 ),
        _Merchant
    )
```

If your existing P03 merchant-number column is in a shared dimension and filters these facts correctly, we can reuse it instead. **Do not create this duplicate if that existing column is available at the proper grain.**

### 2. Monitoring status

We already created:

`P04 Monitoring Status`

Use that presentation column.

### 3. Pace

Create:

```DAX
P04 Account Pace =
SELECTEDVALUE ( FactMonitoringEndpoint[cumulative_pace_ratio] )
```

Format as **Percentage, 1 decimal place**.

The two expected Baseline values are approximately:

- 000312 → **97.7%**
- 000098 → **91.3%**. [export reference: filecite | turn51file0 | L25-L25] [export reference: filecite | turn51file0 | L34-L34]

### 4. Shortfall

```DAX
P04 Account Shortfall =
SELECTEDVALUE ( FactMonitoringEndpoint[cumulative_shortfall_amount] )
```

Format currency, 0 or 2 decimals. I'd use **$0** here given the portfolio presentation.

### 5. Attention exposure

```DAX
P04 Account Attention Exposure =
SELECTEDVALUE ( FactMonitoringEndpoint[remaining_receivable_amount] )
```

Format currency.

For these two accounts, shortfall and remaining receivable happen to be identical, so we may ultimately find one column redundant. **Build both initially; we'll judge the physical table afterward.**

### 6. Servicing disposition

Instead of trying to use the calculated `FactServicingExecution` column directly, create:

```DAX
P04 Account Servicing Disposition =
SELECTEDVALUE (
    FactServicingExecution[P04 Servicing Disposition]
)
```

Expected:

- 000312 → **Active servicing**
- 000098 → **Review hold**. [export reference: filecite | turn52file0 | L9-L10]

### 7. Treatment/action

The raw action codes are far too technical. Create a presentation column in `FactServicingExecution`:

```DAX
P04 Servicing Action =
SWITCH (
    FactServicingExecution[servicing_execution_action_code],
    "EXECUTE_TEMPORARY_SYNTHETIC_PAYMENT_CYCLE", "Temporary payment cycle",
    "HOLD_FOR_SERVICING_REVIEW", "Hold for servicing review",
    "NO_PAYMENT_PROCESSING", "No processing",
    SUBSTITUTE (
        FactServicingExecution[servicing_execution_action_code],
        "_",
        " "
    )
)
```

Then the measure:

```DAX
P04 Account Servicing Action =
SELECTEDVALUE (
    FactServicingExecution[P04 Servicing Action]
)
```

### 8. Ending exposure

```DAX
P04 Account Ending Exposure =
SELECTEDVALUE (
    FactServicingExecution[ending_simulated_exposure_amount]
)
```

Format currency.

Expected:

- 000312 → **$323.79**
- 000098 → **$461.69**. [export reference: filecite | turn52file0 | L9-L10]

This is particularly useful beside Attention exposure because the user can see that servicing reduced 312's exposure while 098 remained unchanged.

### 9. Lifecycle state

Create a presentation column:

```DAX
P04 Lifecycle State =
SWITCH (
    FactServicingExecution[final_lifecycle_state_code],
    "REASSESSMENT_DUE", "Reassessment due",
    "SERVICING_REVIEW_HOLD", "Servicing review hold",
    "CLOSED_NO_PROCESSING_REQUIRED", "Closed — no processing",
    SUBSTITUTE (
        FactServicingExecution[final_lifecycle_state_code],
        "_",
        " "
    )
)
```

Then:

```DAX
P04 Account Lifecycle State =
SELECTEDVALUE (
    FactServicingExecution[P04 Lifecycle State]
)
```

---

## Build the table

Add a **Table** visual and put the fields in this exact order:

| Display column | Field |
|---|---|
| Merchant | `P04 Merchant` |
| Monitoring status | `P04 Monitoring Status` |
| Pace | `[P04 Account Pace]` |
| Shortfall | `[P04 Account Shortfall]` |
| Attention exposure | `[P04 Account Attention Exposure]` |
| Servicing disposition | `[P04 Account Servicing Disposition]` |
| Treatment / action | `[P04 Account Servicing Action]` |
| Ending exposure | `[P04 Account Ending Exposure]` |
| Lifecycle state | `[P04 Account Lifecycle State]` |

Rename the headers in the visual to those concise names.

### Critical visual filter

We want an **attention workbench**, not all 44 Baseline accounts.

Add a visual-level filter:

**`P04 Monitoring Status` → is not `Paid off`**

Given the full endpoint population, Baseline should therefore show exactly **two rows**: 000312 and 000098. Recession Energy should show no rows because all 15 funded endpoint paths are Paid Off.

### What the finished Baseline table should communicate

Conceptually:

| Merchant | Monitoring | Pace | Shortfall | Attention exposure | Disposition | Action | Ending exposure | Lifecycle |
|---|---|---:|---:|---:|---|---|---:|---|
| 000312 | Severe shortfall | 97.7% | $518 | $518 | Active servicing | Temporary payment cycle | $324 | Reassessment due |
| 000098 | Severe shortfall | 91.3% | $462 | $462 | Review hold | Hold for servicing review | $462 | Servicing review hold |

That makes the business story immediately visible: **both reached the endpoint in severe shortfall, but only 312 was authorized for a temporary-payment treatment; 098 was stopped for review.**

Turn **Totals off**. There is no analytically useful total row for this mixture of statuses, rates, exposures and lifecycle states.

Build that table first and show me the result before we decide whether `Shortfall` and `Attention exposure` are visually redundant or whether another field—probably the underlying monitoring reason or payment-exception history—deserves the space more.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a559645e-edb9-4b2a-8125-5ea463ffcd6e"></a>
## Andrew / user · C109-M00448

C109-M00448 · 2026-08-27T09:42:36.183000-04:00 · active path

Preceding visible parent: [C109-M00447](part-16.md#m-9b2a9381-f19d-4d49-b097-9600fec6ca91)

<!-- BEGIN_SOURCE_MESSAGE -->
account pace, shortfall, and attention exposure are all measures, correct?
<!-- END_SOURCE_MESSAGE -->


<a id="m-c0adba36-668a-479f-9e7b-82c19ab1620d"></a>
## Assistant · C109-M00449

C109-M00449 · 2026-08-27T09:42:37.977925-04:00 · active path

Preceding visible parent: [C109-M00448](part-16.md#m-a559645e-edb9-4b2a-8125-5ea463ffcd6e)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. **All three are explicit measures**, not calculated columns:

```DAX
P04 Account Pace =
SELECTEDVALUE ( FactMonitoringEndpoint[cumulative_pace_ratio] )
```

```DAX
P04 Account Shortfall =
SELECTEDVALUE ( FactMonitoringEndpoint[cumulative_shortfall_amount] )
```

```DAX
P04 Account Attention Exposure =
SELECTEDVALUE ( FactMonitoringEndpoint[remaining_receivable_amount] )
```

Formatting:

- **Account Pace:** Percentage, 1 decimal
- **Account Shortfall:** Currency
- **Account Attention Exposure:** Currency

The categorical presentation fields such as **`P04 Monitoring Status`**, **`P04 Servicing Disposition`**, **`P04 Servicing Action`**, and **`P04 Lifecycle State`** are calculated columns; their account-specific retrieval versions are measures where needed in the cross-fact workbench.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f4175821-768b-40d2-b95b-749051ee4ca8"></a>
## Andrew / user · C109-M00450

C109-M00450 · 2026-08-27T10:19:50.936000-04:00 · active path

Preceding visible parent: [C109-M00449](part-16.md#m-c0adba36-668a-479f-9e7b-82c19ab1620d)

<!-- BEGIN_SOURCE_MESSAGE -->
is Servicing Disposition a column or measure?
<!-- END_SOURCE_MESSAGE -->


<a id="m-58eab9d4-dc20-4e94-8f81-f89e0a571288"></a>
## Assistant · C109-M00451

C109-M00451 · 2026-08-27T10:19:52.842126-04:00 · active path

Preceding visible parent: [C109-M00450](part-16.md#m-f4175821-768b-40d2-b95b-749051ee4ca8)

<!-- BEGIN_SOURCE_MESSAGE -->
We created **both**, for different purposes:

- **`P04 Servicing Disposition`** = **calculated column** in `FactServicingExecution`. This translates the raw outcome code into readable categories such as `Active servicing`, `Review hold`, and `No servicing required`.
- **`P04 Account Servicing Disposition`** = **measure** that retrieves the appropriate disposition for each account row in the cross-fact workbench.

The column was:

```DAX
P04 Servicing Disposition =
SWITCH (
    FactServicingExecution[servicing_execution_outcome_code],
    "NO_SERVICING_EXECUTION_REQUIRED", "No servicing required",
    "SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE", "Active servicing",
    "SERVICING_EXECUTION_REVIEW_HOLD", "Review hold",
    SUBSTITUTE (
        FactServicingExecution[servicing_execution_outcome_code],
        "_",
        " "
    )
)
```

And for the **Account attention workbench**, use this measure:

```DAX
P04 Account Servicing Disposition =
SELECTEDVALUE (
    FactServicingExecution[P04 Servicing Disposition]
)
```

So: **presentation category = column; workbench value = measure.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-3f2e6f76-e181-49e6-bf04-4af36ca05bc5"></a>
## Andrew / user · C109-M00452

C109-M00452 · 2026-08-27T10:29:34.470000-04:00 · active path

Preceding visible parent: [C109-M00451](part-16.md#m-58eab9d4-dc20-4e94-8f81-f89e0a571288)

<!-- BEGIN_SOURCE_MESSAGE -->
servicing disposition is blank
<!-- END_SOURCE_MESSAGE -->


<a id="m-fb33a139-679e-489a-b4b3-d4a123eb01bf"></a>
## Assistant · C109-M00453

C109-M00453 · 2026-08-27T10:29:38.816484-04:00 · active path

Preceding visible parent: [C109-M00452](part-16.md#m-3f2e6f76-e181-49e6-bf04-4af36ca05bc5)

<!-- BEGIN_SOURCE_MESSAGE -->
That is the expected failure mode from the way we built the workbench, and the fix is straightforward.

The issue is **filter propagation between two fact tables**. Your table row is being established by `FactMonitoringEndpoint`, but that account-level row context does not automatically filter `FactServicingExecution`. Therefore this:

```DAX
SELECTEDVALUE (
    FactServicingExecution[P04 Servicing Disposition]
)
```

sees multiple servicing rows and returns blank.

We should explicitly pass the selected `AccountKey` from the monitoring fact into the servicing fact with `TREATAS`.

Replace **`P04 Account Servicing Disposition`** with:

```DAX
P04 Account Servicing Disposition =
VAR _AccountKeys =
    VALUES ( FactMonitoringEndpoint[AccountKey] )
RETURN
    CALCULATE (
        SELECTEDVALUE (
            FactServicingExecution[P04 Servicing Disposition]
        ),
        TREATAS (
            _AccountKeys,
            FactServicingExecution[AccountKey]
        )
    )
```

For Baseline, that should now return:

- `000312` → **Active servicing**
- `000098` → **Review hold**

The supplied servicing fact confirms those two distinct outcomes. [export reference: filecite | turn52file0 | L9-L10]

### Correct the other servicing-side workbench measures now

They will have the same cross-fact problem, so fix them before adding them to the table.

**Servicing action**

```DAX
P04 Account Servicing Action =
VAR _AccountKeys =
    VALUES ( FactMonitoringEndpoint[AccountKey] )
RETURN
    CALCULATE (
        SELECTEDVALUE (
            FactServicingExecution[P04 Servicing Action]
        ),
        TREATAS (
            _AccountKeys,
            FactServicingExecution[AccountKey]
        )
    )
```

**Ending exposure**

```DAX
P04 Account Ending Exposure =
VAR _AccountKeys =
    VALUES ( FactMonitoringEndpoint[AccountKey] )
RETURN
    CALCULATE (
        SELECTEDVALUE (
            FactServicingExecution[ending_simulated_exposure_amount]
        ),
        TREATAS (
            _AccountKeys,
            FactServicingExecution[AccountKey]
        )
    )
```

**Lifecycle state**

```DAX
P04 Account Lifecycle State =
VAR _AccountKeys =
    VALUES ( FactMonitoringEndpoint[AccountKey] )
RETURN
    CALCULATE (
        SELECTEDVALUE (
            FactServicingExecution[P04 Lifecycle State]
        ),
        TREATAS (
            _AccountKeys,
            FactServicingExecution[AccountKey]
        )
    )
```

Your three monitoring-side measures—**Pace, Shortfall, Attention Exposure**—do **not** need this fix because the table itself is already anchored on `FactMonitoringEndpoint`.

This is the correct pattern for P04: **MonitoringEndpoint establishes the account rows; `TREATAS(AccountKey)` retrieves the corresponding servicing result from the other fact grain.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-11bf13bf-f778-4592-80f6-d4e81d93a2b7"></a>
## Andrew / user · C109-M00454

C109-M00454 · 2026-08-27T10:53:57.671000-04:00 · active path

Preceding visible parent: [C109-M00453](part-16.md#m-fb33a139-679e-489a-b4b3-d4a123eb01bf)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 7a3a330e-bcbc-4d87-8327-6b1c188b685c.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->
