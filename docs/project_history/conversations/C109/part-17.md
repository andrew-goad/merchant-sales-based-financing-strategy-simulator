# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 17 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-16.md)
[Next part](part-18.md)

<a id="m-752aa5ad-3e42-4a82-80ba-95d600ce5f7a"></a>
## Assistant · C109-M00455

C109-M00455 · 2026-08-27T10:54:06.664721-04:00 · active path

Preceding visible parent: [C109-M00454](part-16.md#m-11bf13bf-f778-4592-80f6-d4e81d93a2b7)

<!-- BEGIN_SOURCE_MESSAGE -->
This is working well. The causal story is now visible at a glance: the two accounts share **Severe shortfall**, but 000098 is held for review while 000312 receives an active temporary-payment treatment.

I would make four refinements before calling this workbench done:

1. Rename the visual from **Monitoring exceptions** to **Account attention workbench**. This table is broader than monitoring exceptions; it combines monitoring condition, servicing disposition, treatment, exposure, and lifecycle state.

2. Rename **`Serving disposition`** to **`Servicing disposition`** if that is the current header.

3. Drop either **Shortfall** or **Attention exposure**. In the current endpoint population they are identical for both actionable accounts:
   - 000098: $461.69 / $461.69
   - 000312: $518.04 / $518.04  
   I would keep **Attention exposure**, because it is more directly aligned to the page question, and remove **Shortfall** unless we later see a case where the two differ materially.

4. Rename **Action** to **Treatment / action** or simply **Treatment**. I prefer **Treatment** here:
   - Hold for servicing review
   - Temporary payment cycle

That would leave a very clean table:

**Merchant | Monitoring status | Pace | Attention exposure | Servicing disposition | Treatment | Ending exposure | Lifecycle state**

I would keep the row order exactly as shown, with the review-hold account first only if that sorting is intentional. Otherwise, I would sort by **Attention exposure descending**, which would naturally put 000312 first at $518.04, followed by 000098 at $461.69.

After those edits, the next logical component is **payment-exception history**, but only as a compact secondary element because the current population contains just one resolved exception case.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e72c2a9a-3041-4836-8d85-c190b393e8f3"></a>
## Andrew / user · C109-M00456

C109-M00456 · 2026-08-27T11:05:58.458000-04:00 · active path

Preceding visible parent: [C109-M00455](part-17.md#m-752aa5ad-3e42-4a82-80ba-95d600ce5f7a)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: ecf06df3-07aa-437a-962c-b5d02a4326e1.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-7de1fb11-e737-4f5e-8eae-58dcf7fffe6a"></a>
## Assistant · C109-M00457

C109-M00457 · 2026-08-27T11:06:01.431439-04:00 · active path

Preceding visible parent: [C109-M00456](part-17.md#m-e72c2a9a-3041-4836-8d85-c190b393e8f3)

<!-- BEGIN_SOURCE_MESSAGE -->
This is coming together very well. The page now has a clear hierarchy: **portfolio posture → monitoring condition → servicing response → specific accounts requiring attention**.

A few observations before adding anything else:

**First, `Unresolved exceptions` showing `--` should be fixed.** Conceptually the answer is **0**, not blank. Modify the measure so zero displays explicitly:

```DAX
P04 Unresolved Exceptions =
COALESCE (
    CALCULATE (
        DISTINCTCOUNT ( FactPaymentException[PaymentExceptionKey] ),
        FactPaymentException[unresolved_exception_flag] = TRUE ()
    ),
    0
)
```

That should give Baseline **0** rather than `--`.

**Second, I like `Merchant Servicing & Exceptions` better than the generic title.** It tells the viewer immediately what population is being managed without implying a full production portfolio servicing platform.

**Third, the workbench is now excellent.** I would not put Shortfall back in. `Attention exposure → Ending exposure` is particularly effective: 000312 visibly moves from $518.04 to $323.79 through the temporary-payment treatment, whereas 000098 remains at $461.69 on review hold. That tells the story without another chart. The underlying servicing records substantiate those different treatment paths. [export reference: filecite | turn52file0 | L9-L10]

### Next: Payment exception history

We have enough white space for one more **compact table**, and this is the right final analytical element because “Exceptions” is in the page title.

I would place it below the Account attention workbench and call it:

**Payment exception history**

It should show only actual exception cases—not monitoring exceptions.

Because `FactPaymentException` is its own fact grain, let's keep this simple rather than forcing it through the workbench.

Create a readable status column:

```DAX
P04 Exception Status =
SWITCH (
    FactPaymentException[exception_status_code],
    "RESOLVED_BY_RETRY", "Resolved by retry",
    SUBSTITUTE (
        FactPaymentException[exception_status_code],
        "_",
        " "
    )
)
```

Create a readable resolution column:

```DAX
P04 Exception Resolution =
SWITCH (
    FactPaymentException[resolution_action_code],
    "RESOLVE_RETURN_WITH_RETRY", "Return resolved by retry",
    SUBSTITUTE (
        FactPaymentException[resolution_action_code],
        "_",
        " "
    )
)
```

For Merchant, I would create the same six-digit presentation column directly in `FactPaymentException` rather than introduce another cross-fact measure:

```DAX
P04 Exception Merchant =
VAR _Application =
    FactPaymentException[merchant_application_id]
VAR _MerchantStart =
    SEARCH ( "_M", _Application, 1, BLANK () )
RETURN
    IF (
        NOT ISBLANK ( _MerchantStart ),
        MID ( _Application, _MerchantStart + 2, 6 ),
        _Application
    )
```

Then build a **Table** with:

**Merchant | Originated | Amount | Status | Resolved | Open days | Resolution**

using:

- `P04 Exception Merchant`
- `originating_event_date`
- `exception_amount`
- `P04 Exception Status`
- `resolving_event_date`
- `exception_open_days`
- `P04 Exception Resolution`

Rename the headers as above.

For the current Baseline population, this should produce the single 000312 case:

**000312 | 7/27/2026 | $27.75 | Resolved by retry | 7/28/2026 | 1 | Return resolved by retry**

That is actually enough. It shows that the active-servicing account had a payment exception, but the exception was resolved and therefore **Unresolved exceptions = 0**.

I would **not make a chart from one exception**.

After that table is built, I think we should stop adding analytical content and assess the whole page for whitespace/layout. We may find that the remaining room is better used to enlarge the workbench and exception table rather than squeeze another visual out of Module 2.
<!-- END_SOURCE_MESSAGE -->


<a id="m-09f61ac8-b370-47c9-bd4b-49b17dd3086f"></a>
## Andrew / user · C109-M00458

C109-M00458 · 2026-08-27T11:07:54.414000-04:00 · active path

Preceding visible parent: [C109-M00457](part-17.md#m-7de1fb11-e737-4f5e-8eae-58dcf7fffe6a)

<!-- BEGIN_SOURCE_MESSAGE -->
and to be clear, which of the above are columns (in what table) and which are measures?
<!-- END_SOURCE_MESSAGE -->


<a id="m-4dbfb21c-245d-4d98-beec-b819ee02fe95"></a>
## Assistant · C109-M00459

C109-M00459 · 2026-08-27T11:07:56.134505-04:00 · active path

Preceding visible parent: [C109-M00458](part-17.md#m-09f61ac8-b370-47c9-bd4b-49b17dd3086f)

<!-- BEGIN_SOURCE_MESSAGE -->
For the **Payment exception history** addition, all three new presentation fields I proposed are **calculated columns**. There are **no new measures required for the table itself**.

| Object | Type | Table |
|---|---|---|
| `P04 Exception Status` | **Calculated column** | `FactPaymentException` |
| `P04 Exception Resolution` | **Calculated column** | `FactPaymentException` |
| `P04 Exception Merchant` | **Calculated column** | `FactPaymentException` |
| `P04 Unresolved Exceptions` | **Measure** | Your existing report-measure location |

### 1. COLUMN — `FactPaymentException[P04 Exception Status]`

Create with **New column** while `FactPaymentException` is selected:

```DAX
P04 Exception Status =
SWITCH (
    FactPaymentException[exception_status_code],
    "RESOLVED_BY_RETRY", "Resolved by retry",
    SUBSTITUTE (
        FactPaymentException[exception_status_code],
        "_",
        " "
    )
)
```

### 2. COLUMN — `FactPaymentException[P04 Exception Resolution]`

**New column:**

```DAX
P04 Exception Resolution =
SWITCH (
    FactPaymentException[resolution_action_code],
    "RESOLVE_RETURN_WITH_RETRY", "Return resolved by retry",
    SUBSTITUTE (
        FactPaymentException[resolution_action_code],
        "_",
        " "
    )
)
```

### 3. COLUMN — `FactPaymentException[P04 Exception Merchant]`

**New column:**

```DAX
P04 Exception Merchant =
VAR _Application =
    FactPaymentException[merchant_application_id]
VAR _MerchantStart =
    SEARCH ( "_M", _Application, 1, BLANK () )
RETURN
    IF (
        NOT ISBLANK ( _MerchantStart ),
        MID ( _Application, _MerchantStart + 2, 6 ),
        _Application
    )
```

This should turn:

`MSBF_POP_0001_M000312_A01`

into:

`000312`

### 4. MEASURE — `P04 Unresolved Exceptions`

This is the **only measure in that set**. Replace the existing version with:

```DAX
P04 Unresolved Exceptions =
COALESCE (
    CALCULATE (
        DISTINCTCOUNT ( FactPaymentException[PaymentExceptionKey] ),
        FactPaymentException[unresolved_exception_flag] = TRUE ()
    ),
    0
)
```

Keep this wherever you've been storing the P01–P04 report-owned measures.

### Then the table itself

All seven table fields can come **directly from `FactPaymentException`** because the visual is entirely at payment-exception grain:

1. `P04 Exception Merchant` — **column**
2. `originating_event_date` — existing **column**
3. `exception_amount` — existing **column**
4. `P04 Exception Status` — **column**
5. `resolving_event_date` — existing **column**
6. `exception_open_days` — existing **column**
7. `P04 Exception Resolution` — **column**

So unlike the Account Attention Workbench, **we don't need account-level `SELECTEDVALUE` measures or `TREATAS` here**. Everything belongs to the same fact and same exception-case grain.

And I'll explicitly identify **COLUMN vs MEASURE and its table** as we create each new P04 object from here forward.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b9d64b2b-a1ea-4ef4-83dc-96ffc6f8c709"></a>
## Andrew / user · C109-M00460

C109-M00460 · 2026-08-27T11:22:33.188000-04:00 · active path

Preceding visible parent: [C109-M00459](part-17.md#m-4dbfb21c-245d-4d98-beec-b819ee02fe95)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: fcdd18e3-4e72-42c8-b48b-a01a082823d3.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-bbbe9f33-34a2-47c0-85b1-3f14a66cbdec"></a>
## Assistant · C109-M00461

C109-M00461 · 2026-08-27T11:22:36.045439-04:00 · active path

Preceding visible parent: [C109-M00460](part-17.md#m-b9d64b2b-a1ea-4ef4-83dc-96ffc6f8c709)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a strong P04. The page now answers the intended operational question without trying to extract more analytical depth than Module 2 contains.

The narrative reads cleanly:

**2 accounts require attention → $979.73 exposure → both are severe shortfall → one receives active servicing and one is held for review → $785.48 remains after servicing → the one payment exception was resolved → zero unresolved exceptions.**

I would make only a few refinements before accessibility/UAT.

### 1. The left rail is right

Keep it exactly conceptually as:

**Requiring attention**  
**Exposure**  
**Active servicing**  
**Review holds**  
**Servicing exposure**  
**Unresolved exceptions**

I don't think it needs an `Operational posture` heading. The page title already establishes the context, and the rail reads naturally.

### 2. Monitoring posture — consider suppressing Paid off

This is the one design choice worth considering.

Right now **42 Paid off vs. 2 Severe shortfall** accurately communicates how exceptional the attention population is. That's valuable context. On the other hand, the page is explicitly an exceptions workbench, so the large Paid-off bar visually dominates.

I lean toward **keeping it**. The 42:2 relationship tells the viewer something important immediately: this isn't a distressed portfolio; these are two exceptional accounts in an overwhelmingly resolved endpoint population.

### 3. Servicing disposition is excellent as-is

The 1/1 split is simple, but it earns its place because it explains the bifurcation subsequently shown in the workbench.

I would not add another “drivers” chart.

### 4. Account attention workbench is the centerpiece

This is now the strongest element on the page.

The sequence is particularly good:

**Monitoring status → Pace → Attention exposure → Servicing disposition → Treatment → Ending exposure → Lifecycle state**

It lets the user compare the two cases without explanation.

One tiny wording improvement: change **`Pace`** header to **`Remittance pace`** if it fits. `Pace` alone is understandable in context, but `Remittance pace` is unambiguous.

### 5. Payment exception history is appropriately restrained

Keep it exactly as a table. One event does not warrant another chart.

I'd format **Amount** as currency so `$27.75` appears rather than `27.75`.

The resulting record then reads naturally:

**000312 | 7/27/2026 | $27.75 | Resolved by retry | 7/28/2026 | 1 | Return resolved by retry**

### 6. One substantive change: the footer

The existing footer is inherited from P03 and isn't quite right for P04.

P04 is specifically an **endpoint operational view**, so I would change the temporal boundary to:

> **Temporal boundary:** Monitoring and servicing posture reflects the governed 2026-11-22 synthetic endpoint; payment exceptions reflect dated synthetic servicing events. **Interpretation boundary:** Deterministic synthetic evidence.

That's substantially more precise than:

> Lifecycle dates after 2026-07-23...

which made sense for P03's longitudinal charts but isn't the analytical contract of P04.

Keep the provenance line above it unchanged.

### Then we're nearly done

I would **not add another substantive visual**. There is white space, but that's preferable to manufacturing content. The page already has a complete operational story, and the restrained density is consistent with P01–P03.

Next we should do exactly the P03 closeout sequence:

**Alt text → Tooltips → Tab order → Scenario UAT → freeze/evidence.**

For tooltips, this page should be especially light because most values are already visible. The two bar charts are the only obvious candidates for deliberate analytical tooltip treatment.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a667fc1b-fd3c-44e1-9f17-0a4c2d4c5375"></a>
## Andrew / user · C109-M00462

C109-M00462 · 2026-08-27T11:34:47.027000-04:00 · active path

Preceding visible parent: [C109-M00461](part-17.md#m-bbbe9f33-34a2-47c0-85b1-3f14a66cbdec)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 62a06a7d-5c82-4c8e-9fb4-587f352a18d9.png

<!-- BEGIN_SOURCE_MESSAGE -->
review final visual then provide alt text / tooltips / tab order / evidence to capture
<!-- END_SOURCE_MESSAGE -->


<a id="m-049b456e-d5aa-4aa1-b3d2-c088b03fdca3"></a>
## Assistant · C109-M00463

C109-M00463 · 2026-08-27T11:34:48.799722-04:00 · active path

Preceding visible parent: [C109-M00462](part-17.md#m-a667fc1b-fd3c-44e1-9f17-0a4c2d4c5375)

<!-- BEGIN_SOURCE_MESSAGE -->
The final visual is strong. I would **freeze the substantive P04 design as shown** after one tiny formatting fix: `Payment exception history → Amount` still displays `27.75`; format that field as **Currency, 2 decimals** so it reads `$27.75`. I would not add another visual or fill the remaining whitespace.

The hierarchy is now excellent: left rail summarizes workload → Monitoring posture establishes severity → Servicing disposition shows governed routing → Account attention workbench explains the two cases → Payment exception history provides the actual exception event. The revised footer is also the correct P04 temporal contract.

## 1. Alt text

I count **six substantive visual objects plus the title/subtitle** that should receive alt text.

**Title/subtitle**
> `Merchant Servicing & Exceptions. Identify accounts requiring operational attention, understand the drivers, and review governed servicing outcomes.`

**Left Operational Posture multi-card**
> `Endpoint servicing summary for the selected scenario, showing accounts requiring attention, attention exposure, active servicing accounts, review holds, remaining servicing exposure, and unresolved payment exceptions.`

**Monitoring posture**
> `Endpoint monitoring-status distribution for funded accounts in the selected scenario, showing the number of accounts by monitoring status.`

I deliberately would **not hard-code “42 paid off and 2 severe shortfall” into alt text** because those values change with Scenario.

**Servicing disposition**
> `Servicing disposition for accounts requiring operational attention in the selected scenario, showing counts of active servicing and review-hold accounts.`

**Account attention workbench**
> `Account-level workbench for the selected scenario showing merchants requiring attention, monitoring status, remittance pace, attention exposure, servicing disposition, governed treatment, ending exposure, and lifecycle state.`

**Payment exception history**
> `Payment-exception history for the selected scenario, showing merchant, origination date, exception amount, status, resolution date, open days, and resolution action.`

The **Scenario slicer** does not need custom alt text. The visible footer/provenance text doesn't need a separate alt-text object either; preserve it as readable text.

---

## 2. Tooltips

Keep these restrained.

### Monitoring posture

The default tooltip already gives **Monitoring status + Account count**, which is essentially everything the chart represents.

I would add only:

- `[P04 Attention Exposure]` **if it responds correctly to selection of a monitoring-status bar**.

That would let a user hover Severe shortfall and see:

**Accounts: 2**  
**Exposure: $979.73**

If the measure doesn't inherit the status category cleanly, don't engineer around it. The left rail already provides the exposure.

### Servicing disposition

The default tooltip provides:

**Disposition + Account count**

That's sufficient. Don't add treatment or ending exposure here because those differ at account grain and are already explained by the workbench.

### Tables

No custom tooltip work needed for:

- Account attention workbench
- Payment exception history
- Operational Posture card

Their important information is already visible.

So P04 can legitimately have **very little custom tooltip construction**. That's good design, not an omission.

---

## 3. Tab order

Because P04 is a workbench rather than a single-account journey, I recommend this exact order:

1. **Scenario slicer**
2. **Operational Posture multi-card**
3. **Monitoring posture**
4. **Servicing disposition**
5. **Account attention workbench**
6. **Payment exception history**

Then remove/exclude decorative or noninteractive objects from tab order where Power BI permits:

- title/subtitle
- vertical separator
- footer/provenance text
- decorative shapes/backgrounds

This gives keyboard users the same analytical sequence as sighted users:

**Choose scenario → understand workload → understand monitoring condition → understand servicing routing → inspect affected accounts → inspect payment exceptions.**

---

## 4. Final UAT / evidence capture

We don't need a huge evidence population because the physical population is small and well understood. I would capture **six screenshots**.

**E01 — Baseline full-page final state**  
Exactly what you've shown here, after changing `$27.75` formatting. This is the principal P04 evidence.

**E02 — Recession Energy full-page state**  
Switch Scenario to `Recession Energy`. We expect:
- Requiring attention = 0
- Exposure = $0
- Active servicing = 0
- Review holds = 0
- Servicing exposure = $0
- Unresolved exceptions = 0
- Monitoring posture = 15 Paid off
- no actionable servicing dispositions
- empty workbench
- empty payment-exception history

This is important because it demonstrates **scenario-sensitive fail-empty behavior**, rather than accidentally carrying Baseline servicing records into Recession Energy.

**E03 — Baseline Monitoring posture tooltip**  
Hover **Severe shortfall** and capture the tooltip. If you successfully add attention exposure, capture both account count and exposure; otherwise the native count tooltip is sufficient.

**E04 — Baseline Servicing disposition tooltip**  
Hover either `Active servicing` or `Review hold` and capture the native tooltip/count.

**E05 — Alt-text evidence**  
Use whatever accessibility/property view you used for P03 and capture enough to establish the final P04 alt-text population. If one screenshot cannot show all objects, use two. Don't contort the UI merely to force everything into one capture.

**E06 — Tab-order evidence**  
Capture the final tab-order pane showing the six-object sequence above.

### One optional evidence capture

If clicking **000312** in the Account attention workbench cross-filters Payment exception history down to its `$27.75` exception cleanly, that is worth capturing as **E07** because it demonstrates a meaningful native interaction.

But don't create a special interaction solely for evidence. Test the existing behavior first.

---

## Final footer

I confirm the current wording:

> **Temporal boundary:** Monitoring and servicing posture reflects the governed 2026-11-22 synthetic endpoint; payment exceptions reflect dated synthetic servicing events; **Interpretation boundary:** Deterministic synthetic evidence

I would retain it exactly.

The provenance line above it is also appropriate and consistent with the report family.

### Freeze threshold

Once the currency format, Baseline/Recession UAT, alt text, tooltips and tab order are complete, **P04 should freeze**. I don't see a substantive reason to add anything else.

P04 is doing something importantly different from P03: P03 explains **one application/account journey**; P04 finds the exceptional accounts across the endpoint population and explains **why operational attention exists and what governed servicing did about it**. That differentiation is now clear enough to justify both pages.
<!-- END_SOURCE_MESSAGE -->


<a id="m-03e73959-5575-46f4-845e-d07a4baab13f"></a>
## Andrew / user · C109-M00464

C109-M00464 · 2026-08-27T11:55:46.952000-04:00 · active path

Preceding visible parent: [C109-M00463](part-17.md#m-049b456e-d5aa-4aa1-b3d2-c088b03fdca3)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: d9c7df66-ea05-4bef-b0a3-2af799b6d9ed.png

<!-- BEGIN_SOURCE_MESSAGE -->
The recession energy full page exposed something we probably want to fix - the multi card nulls might be better as 0's:
<!-- END_SOURCE_MESSAGE -->


<a id="m-4517134f-6162-485f-9b17-430ccc60b171"></a>
## Assistant · C109-M00465

C109-M00465 · 2026-08-27T11:55:48.770459-04:00 · active path

Preceding visible parent: [C109-M00464](part-17.md#m-03e73959-5575-46f4-845e-d07a4baab13f)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **For these operational count/exposure KPIs, zero is semantically correct and materially better than `--`.** Recession Energy has a valid governed population; it simply has **no accounts requiring attention**. Blank makes that look like missing data.

I would make **all six left-rail measures fail to zero** where appropriate.

### Update these five measures

**1. Accounts requiring attention**

```DAX
P04 Accounts Requiring Attention =
COALESCE (
    CALCULATE (
        DISTINCTCOUNT ( FactMonitoringEndpoint[AccountKey] ),
        FactMonitoringEndpoint[latest_monitoring_status_rank] > 0
    ),
    0
)
```

**2. Attention exposure**

```DAX
P04 Attention Exposure =
COALESCE (
    CALCULATE (
        SUM ( FactMonitoringEndpoint[remaining_receivable_amount] ),
        FactMonitoringEndpoint[latest_monitoring_status_rank] > 0
    ),
    0
)
```

Keep currency formatting.

**3. Active servicing**

```DAX
P04 Active Servicing =
COALESCE (
    CALCULATE (
        DISTINCTCOUNT ( FactServicingExecution[AccountKey] ),
        FactServicingExecution[processing_authorized_flag] = TRUE ()
    ),
    0
)
```

**4. Review holds**

```DAX
P04 Review Holds =
COALESCE (
    CALCULATE (
        DISTINCTCOUNT ( FactServicingExecution[AccountKey] ),
        FactServicingExecution[processing_review_required_flag] = TRUE ()
    ),
    0
)
```

**5. Servicing exposure**

```DAX
P04 Servicing Exposure =
COALESCE (
    CALCULATE (
        SUM ( FactServicingExecution[ending_simulated_exposure_amount] ),
        FactServicingExecution[no_processing_required_flag] = FALSE ()
    ),
    0
)
```

Keep currency formatting.

Your revised **`P04 Unresolved Exceptions`** already has the correct `COALESCE(...,0)` treatment, which is why it correctly shows `0` in the screenshot.

### Expected Recession Energy rail

After those changes:

**Requiring attention**  
`0`

**Exposure**  
`$0.00`

**Active servicing**  
`0`

**Review holds**  
`0`

**Servicing exposure**  
`$0.00`

**Unresolved exceptions**  
`0`

That's much stronger. It communicates a legitimate **zero-state scenario**, while the Monitoring posture chart independently confirms why: all **15 funded endpoint accounts are Paid off**.

I would leave the empty **Servicing disposition**, **Account attention workbench**, and **Payment exception history** exactly as they are. Empty visuals there correctly mean **there are no applicable records**; converting their contents into artificial zero rows would be misleading.

One other thing your screenshot exposed: the provenance line still says **`M1_V0_2_BASELINE_BUILD` while Recession Energy is selected**. We should investigate that before freezing P04. If `Run` is intended to identify the underlying common build rather than selected scenario, it may be correct; but the word `BASELINE` creates a potentially confusing apparent contradiction that deserves verification.
<!-- END_SOURCE_MESSAGE -->


<a id="m-49384583-d977-448a-9cfe-7a0be3f08a38"></a>
## Andrew / user · C109-M00466

C109-M00466 · 2026-08-27T12:06:36.314000-04:00 · active path

Preceding visible parent: [C109-M00465](part-17.md#m-4517134f-6162-485f-9b17-430ccc60b171)

<!-- BEGIN_SOURCE_MESSAGE -->
My original build chat confirmed - **Confirmed: do not treat this as a provenance defect.** `M1_V0_2_BASELINE_BUILD` identifies the common governed Module 1 run/build and is intentionally shared by both `BASELINE` and `RECESSION_ENERGY`. Scenario is a separate dimension within that run, so selecting `RECESSION_ENERGY` should not change the run identity. The apparent contradiction comes from `BASELINE` being embedded in the historical run name, not from incorrect filtering or lineage.

For P04, preserve the underlying run value exactly as governed rather than renaming it. If needed for executive clarity, change only the **display label** from `Run` to something more explicit such as **`Governed Run`** or **`Source Run`**, while continuing to show the actual value `M1_V0_2_BASELINE_BUILD`. Keep `Scenario` separately visible as `RECESSION_ENERGY`.

Please verify the semantic model behaves accordingly—one governed run containing both scenario identities—and, assuming that passes, treat this item as **verified / no blocker to P04 freeze**.               Given that, I see no reason to change our provenance line
<!-- END_SOURCE_MESSAGE -->


<a id="m-1e184f14-6513-4208-b25e-ae7171544304"></a>
## Assistant · C109-M00467

C109-M00467 · 2026-08-27T12:06:41.111709-04:00 · active path

Preceding visible parent: [C109-M00466](part-17.md#m-49384583-d977-448a-9cfe-7a0be3f08a38)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. I would **not change the provenance line**.

Your build-chat explanation resolves the apparent contradiction cleanly: `M1_V0_2_BASELINE_BUILD` is the governed run/build identity, while `BASELINE` and `RECESSION_ENERGY` are scenario identities within that same run. The Scenario slicer should therefore change scenario-qualified facts while the run value remains fixed.

So for P04:

- keep `Run: M1_V0_2_BASELINE_BUILD` exactly as governed;
- keep `Scenario` separately visible in the slicer;
- do not relabel or rewrite the run value merely because the string contains `BASELINE`;
- treat the unchanged run identity under Recession Energy as **verified expected behavior**, not a lineage defect.

I also agree there is no compelling need to change the display label from `Run` to `Governed Run` unless you later decide the portfolio audience may misread it. The existing provenance line is consistent with P01–P03 and is already compact.

The only remaining P04 presentation fix exposed by the Recession Energy UAT is the left multi-card zero-state treatment. Once those five measures are wrapped in `COALESCE(...,0)`, I would regard the Recession Energy state as correct:

**0 requiring attention / $0 exposure / 0 active servicing / 0 review holds / $0 servicing exposure / 0 unresolved exceptions**, while Monitoring posture shows all 15 accounts Paid off.

After that, complete the alt text/tooltips/tab order evidence captures we outlined and freeze P04.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a956fca0-3d04-44fb-8465-38285bf781db"></a>
## Andrew / user · C109-M00468

C109-M00468 · 2026-08-27T12:12:18.460000-04:00 · active path

Preceding visible parent: [C109-M00467](part-17.md#m-1e184f14-6513-4208-b25e-ae7171544304)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 854e07b4-0fd9-4ae3-bd7f-c0d0ecd16988.png

<!-- BEGIN_SOURCE_MESSAGE -->
E07 - Is this what you wanted to see? Any concerns: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-1926c587-37ca-44fd-b42c-6bfce235931d"></a>
## Assistant · C109-M00469

C109-M00469 · 2026-08-27T12:12:20.836673-04:00 · active path

Preceding visible parent: [C109-M00468](part-17.md#m-a956fca0-3d04-44fb-8465-38285bf781db)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **This is exactly the E07 interaction I wanted to test**, and it exposes one real issue.

Selecting Merchant **000312** in the Account attention workbench correctly leaves its `$27.75` payment exception visible. That demonstrates the desired native cross-filter relationship between the account workbench and exception history.

However, I **would not use this screenshot as final E07 evidence yet**, because the interaction is only partially propagating.

Notice the inconsistency after selecting 000312:

- **Requiring attention = 1** — correctly filtered.
- **Exposure = $518.04** — correctly filtered to 000312.
- **Active servicing = 1** — correct.
- **Review holds = 1** — **incorrect for the selected account**.
- **Servicing exposure = $785.48** — **still the full two-account total**, not 000312's $323.79.
- Servicing disposition still shows **Active servicing = 1 and Review hold = 1**, rather than only Active servicing.

So the selection is filtering the monitoring-side facts but **is not propagating from `FactMonitoringEndpoint` to `FactServicingExecution`**. That's the same cross-fact boundary we encountered when the workbench's servicing fields initially came back blank.

This is **not a defect in the underlying data**. It's a visual-interaction/filter-propagation issue.

### What I recommend

For P04, I actually **do not think we should engineer additional cross-fact DAX merely to make clicking the workbench dynamically rewrite the entire page**. The page's primary contract is scenario-level operational posture, and the workbench itself already reconciles the two facts correctly through our explicit `TREATAS` measures.

Instead:

1. Keep the Scenario slicer as the governing page control.
2. Keep the Account attention workbench as the investigative table.
3. **Disable the workbench's interaction with the left Operational Posture card and the two bar charts.**
4. **Keep its interaction with Payment exception history enabled.**

That creates a very intentional interaction contract:

> Clicking an account in the workbench does **not redefine portfolio-level posture**; it drills the associated exception history beneath the workbench.

That is arguably better UX anyway. The left rail and charts remain **portfolio/scenario context**, while the bottom exception table becomes the selected-account detail.

Then E07 becomes strong evidence:

**Baseline portfolio remains 2 accounts / $979.73 / 1 active / 1 hold / $785.48**, while selecting 000312 filters Payment exception history to its `$27.75` resolved-by-retry event.

So go to **Format → Edit interactions**, select the Account attention workbench, and set:

- Operational Posture → **None**
- Monitoring posture → **None**
- Servicing disposition → **None**
- Payment exception history → **Filter**

Then select 000312 again.

**That resulting screenshot is the E07 I would retain.** It demonstrates a deliberate master-detail interaction without producing internally inconsistent portfolio KPIs.
<!-- END_SOURCE_MESSAGE -->


<a id="m-76d5ccab-58f8-4ae1-bf53-b0a1d0647cd3"></a>
## Andrew / user · C109-M00470

C109-M00470 · 2026-08-27T12:16:56.373000-04:00 · active path

Preceding visible parent: [C109-M00469](part-17.md#m-1926c587-37ca-44fd-b42c-6bfce235931d)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 6593624a-b4e0-4d7f-9e53-e7df5e287400.png; 0f9a4e06-227a-45cc-8bcd-85bc1807235e.png

<!-- BEGIN_SOURCE_MESSAGE -->
Updated E07 - What should I call this evidence? My naming and folder so far: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-07a4980d-16a2-48a2-9e30-928250d833d5"></a>
## Assistant · C109-M00471

C109-M00471 · 2026-08-27T12:16:58.757704-04:00 · active path

Preceding visible parent: [C109-M00470](part-17.md#m-76d5ccab-58f8-4ae1-bf53-b0a1d0647cd3)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes—this updated E07 is now exactly what we wanted. The portfolio-level context remains fixed at **2 / $979.73 / 1 active / 1 hold / $785.48**, while selecting Merchant **000312** filters only the Payment exception history to its `$27.75` case. That demonstrates the deliberate master-detail interaction cleanly.

Your folder structure is also fine:

`C:\MSBF\P04_Evidence_Capture`

Given your existing naming convention, I would name E07:

**`P04_Baseline_Including_Account_Workbench_Interaction.png`**

That is more descriptive than calling it E07 and remains consistent with your other filenames:

```text
P04_Baseline.png
P04_Baseline_Including_Alt_Text.png
P04_Baseline_Including_Monitoring_posture_Tooltips.png
P04_Baseline_Including_Servicing_disposition_Tooltips.png
P04_Baseline_Including_Tab_Order.png
P04_Recession_Energy.png
P04_Baseline_Including_Account_Workbench_Interaction.png
```

I would keep those names rather than renumbering everything E01–E07. They are self-describing, which will be more useful when Audit opens the evidence package later.

One small naming cleanup: for consistency, I'd capitalize the visual names in the filenames if convenient:

`P04_Baseline_Including_Monitoring_Posture_Tooltip.png`  
`P04_Baseline_Including_Servicing_Disposition_Tooltip.png`

Singular **Tooltip** is also slightly more accurate if each screenshot captures one hover state. But this is housekeeping only; I would not redo screenshots solely for filenames.

With E07 captured, **P04 UAT/evidence is substantively complete**. Save the PBIP/project in this final state, and then we should create the P04 freeze/delta evidence package just as we did for P03 before moving into **P05 — Risk, Economics & Concentration**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-42247a17-db70-45b5-aa08-f71e3d3a0c36"></a>
## Andrew / user · C109-M00472

C109-M00472 · 2026-08-27T12:20:55.259000-04:00 · active path

Preceding visible parent: [C109-M00471](part-17.md#m-07a4980d-16a2-48a2-9e30-928250d833d5)

<!-- BEGIN_SOURCE_MESSAGE -->
E07 captured. C:\MSBF\P04_Evidence_Capture includes all the requested evidence. Power BI project is saved. Let's freeze P04 and create the evidence package just as we did for P03. Provide the powershell commands, including initial commands to set up the powershell (I restarted my pc).
<!-- END_SOURCE_MESSAGE -->


<a id="m-75854e0f-d538-40f1-b012-cd6b7e0af617"></a>
## Assistant · C109-M00473

C109-M00473 · 2026-08-27T12:21:00.424948-04:00 · active path

Preceding visible parent: [C109-M00472](part-17.md#m-42247a17-db70-45b5-aa08-f71e3d3a0c36)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Since Power BI is saved and `C:\MSBF\P04_Evidence_Capture` contains the completed evidence set, we can freeze P04 exactly as we did P03.

Because you restarted the PC, start with a fresh PowerShell session and run these blocks **in order**.

## 1. Initialize PowerShell and establish paths

Open **PowerShell** and run:

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot    = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\project"
$EvidenceSource = "C:\MSBF\P04_Evidence_Capture"
$FreezeRoot     = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\evidence\P04_FREEZE"

New-Item -ItemType Directory -Force -Path $FreezeRoot | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\screenshots" | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\delta" | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\manifests" | Out-Null

Write-Host ""
Write-Host "Project root:   $ProjectRoot"
Write-Host "Evidence source:$EvidenceSource"
Write-Host "Freeze root:    $FreezeRoot"
Write-Host ""
```

Verify the two controlling inputs:

```powershell
if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "Project root not found: $ProjectRoot"
}

if (-not (Test-Path -LiteralPath $EvidenceSource)) {
    throw "P04 evidence folder not found: $EvidenceSource"
}

Write-Host "P04 freeze inputs verified." -ForegroundColor Green
```

---

# 2. Preserve the P04 evidence population

First copy the screenshots/evidence into the freeze structure.

```powershell
if (Test-Path -LiteralPath "$FreezeRoot\screenshots") {
    Remove-Item "$FreezeRoot\screenshots" -Recurse -Force
}

New-Item -ItemType Directory -Force -Path "$FreezeRoot\screenshots" | Out-Null

Copy-Item `
    -Path "$EvidenceSource\*" `
    -Destination "$FreezeRoot\screenshots" `
    -Recurse `
    -Force
```

Confirm the captured files:

```powershell
Get-ChildItem "$FreezeRoot\screenshots" -Recurse -File |
    Sort-Object Name |
    Select-Object Name, Length |
    Format-Table -AutoSize
```

You should see your P04 evidence set, including the Baseline full page, Recession Energy, alt text, both tooltip captures, tab order, and the Account Workbench interaction evidence.

---

# 3. Create the evidence carrier ZIP

Create a clean P04 evidence ZIP from the frozen copies:

```powershell
$EvidenceCarrier = "$FreezeRoot\P04_Evidence_Capture.zip"

if (Test-Path -LiteralPath $EvidenceCarrier) {
    Remove-Item -LiteralPath $EvidenceCarrier -Force
}

Compress-Archive `
    -Path "$FreezeRoot\screenshots\*" `
    -DestinationPath $EvidenceCarrier `
    -CompressionLevel Optimal
```

Hash it:

```powershell
$EvidenceZipHash = (
    Get-FileHash `
        -LiteralPath $EvidenceCarrier `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

[PSCustomObject]@{
    File   = "P04_Evidence_Capture.zip"
    Bytes  = (Get-Item $EvidenceCarrier).Length
    SHA256 = $EvidenceZipHash
} |
    Export-Csv `
        "$FreezeRoot\manifests\P04_EVIDENCE_ZIP_SHA256.csv" `
        -NoTypeInformation

Write-Host "P04 evidence ZIP SHA-256: $EvidenceZipHash"
```

---

# 4. Create the screenshot/evidence manifest

```powershell
$EvidenceManifest = Get-ChildItem "$FreezeRoot\screenshots" -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256

        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($FreezeRoot.Length + 1).Replace("\","/")
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLowerInvariant()
        }
    }

$EvidenceManifest |
    Export-Csv `
        "$FreezeRoot\manifests\P04_SCREENSHOT_MANIFEST.csv" `
        -NoTypeInformation
```

Show it:

```powershell
Import-Csv "$FreezeRoot\manifests\P04_SCREENSHOT_MANIFEST.csv" |
    Format-Table -AutoSize
```

---

# 5. Fingerprint the exact saved Power BI project

This creates the physical P04 freeze identity.

```powershell
$ProjectManifest = Get-ChildItem $ProjectRoot -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256

        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($ProjectRoot.Length + 1).Replace("\","/")
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLowerInvariant()
        }
    }

$ProjectManifest |
    Export-Csv `
        "$FreezeRoot\manifests\P04_PROJECT_FILE_MANIFEST.csv" `
        -NoTypeInformation
```

Now create the canonical project-manifest stream:

```powershell
$CanonicalLines = $ProjectManifest | ForEach-Object {
    "$($_.RelativePath)|$($_.Bytes)|$($_.SHA256)"
}

$CanonicalText = ($CanonicalLines -join "`n") + "`n"

[System.IO.File]::WriteAllText(
    "$FreezeRoot\manifests\P04_PROJECT_MANIFEST_CANONICAL.txt",
    $CanonicalText,
    [System.Text.UTF8Encoding]::new($false)
)
```

Hash that canonical manifest:

```powershell
$RootHash = (
    Get-FileHash `
        -LiteralPath "$FreezeRoot\manifests\P04_PROJECT_MANIFEST_CANONICAL.txt" `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

"Project manifest root SHA-256: $RootHash" |
    Set-Content `
        "$FreezeRoot\manifests\P04_PROJECT_ROOT_SHA256.txt" `
        -Encoding UTF8

Get-Content "$FreezeRoot\manifests\P04_PROJECT_ROOT_SHA256.txt"
```

Keep that `$RootHash`; it is the identity of the saved project at the P04 freeze.

---

# 6. Capture the physical P04 report/model delta

Search the saved PBIP for the major P04 objects and source tables.

```powershell
$Patterns = @(
    "P04",
    "Merchant Servicing & Exceptions",
    "Servicing & Exceptions",
    "Monitoring posture",
    "Servicing disposition",
    "Account attention workbench",
    "Payment exception history",
    "FactMonitoringEndpoint",
    "FactServicingExecution",
    "FactServicingQueueEndpoint",
    "FactPaymentException",
    "P04 Accounts Requiring Attention",
    "P04 Attention Exposure",
    "P04 Active Servicing",
    "P04 Review Holds",
    "P04 Servicing Exposure",
    "P04 Unresolved Exceptions"
)

$DeltaRefs = Get-ChildItem $ProjectRoot -Recurse -File |
    Where-Object {
        $_.Extension -in ".tmdl", ".json", ".pbir", ".bim", ".pbip"
    } |
    Select-String -Pattern $Patterns -SimpleMatch
```

Export machine-readable evidence:

```powershell
$DeltaRefs |
    Select-Object Path, LineNumber, Line |
    Export-Csv `
        "$FreezeRoot\delta\P04_PHYSICAL_DELTA_REFERENCES.csv" `
        -NoTypeInformation
```

And a human-readable version:

```powershell
$DeltaRefs |
    Format-Table Path, LineNumber, Line -AutoSize |
    Out-String -Width 4096 |
    Set-Content `
        "$FreezeRoot\delta\P04_PHYSICAL_DELTA_REFERENCES.txt" `
        -Encoding UTF8
```

Inspect it:

```powershell
Get-Content "$FreezeRoot\delta\P04_PHYSICAL_DELTA_REFERENCES.txt"
```

A large result is normal because report-owned P04 measures/columns will appear in semantic-model definition files and page objects will appear in report JSON.

---

# 7. Capture the P04 report-owned semantic object population

This narrower search is useful for Audit because it isolates the objects explicitly named `P04`.

```powershell
$P04SemanticRefs = Get-ChildItem $ProjectRoot -Recurse -File |
    Where-Object {
        $_.Extension -in ".tmdl", ".bim", ".json"
    } |
    Select-String -Pattern "P04 " -SimpleMatch

$P04SemanticRefs |
    Select-Object Path, LineNumber, Line |
    Export-Csv `
        "$FreezeRoot\delta\P04_REPORT_OWNED_OBJECT_REFERENCES.csv" `
        -NoTypeInformation

$P04SemanticRefs |
    Format-Table Path, LineNumber, Line -AutoSize |
    Out-String -Width 4096 |
    Set-Content `
        "$FreezeRoot\delta\P04_REPORT_OWNED_OBJECT_REFERENCES.txt" `
        -Encoding UTF8
```

This gives us a physical record of the P04 calculated columns and explicit measures without manually retyping every object into an evidence register.

---

# 8. Create the formal P04 freeze and delta note

Run this block:

```powershell
$FreezeTimestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssK"

@'
# P04 — Merchant Servicing & Exceptions Construction Freeze

## Freeze status

P04 construction is frozen following physical Power BI construction and representative UAT.

Final tab name:

P04 - Servicing & Exceptions

Final page title:

Merchant Servicing & Exceptions

Final page purpose:

Identify accounts requiring operational attention, understand the drivers, and review governed servicing outcomes.

## Analytical contract

P04 is an endpoint operational workbench.

It identifies scenario-qualified funded account paths requiring attention at the governed monitoring endpoint, distinguishes the associated servicing disposition and treatment path, presents remaining servicing exposure, and preserves dated payment-exception history.

P04 is not an arbitrary historical as-of servicing reconstruction and does not imply that the endpoint servicing queue can be recomputed for every prior observation date.

The page therefore uses Scenario as the governing analytical control and intentionally does not expose an Observation-date slicer.

## Endpoint monitoring population

The supplied current-model endpoint population supports two Baseline accounts requiring operational attention:

- Merchant 000312 — Severe shortfall.
- Merchant 000098 — Severe shortfall.

The Recession Energy endpoint population contains no accounts requiring attention in the current governed build.

The page preserves zero-state behavior explicitly for valid scenario populations with no attention accounts.

## Governed servicing distinction

The two Baseline severe-shortfall accounts follow different governed servicing paths.

Merchant 000312:

- enters the servicing layer with temporary-payment processing authorized;
- receives an active synthetic temporary-payment treatment;
- produces dated synthetic payment events;
- contains one payment exception resolved by retry;
- ends with reduced simulated exposure; and
- remains due for reassessment.

Merchant 000098:

- requires operational/governance review;
- does not receive synthetic payment processing;
- remains on servicing review hold; and
- retains its ending servicing exposure.

The page therefore demonstrates that the same terminal monitoring condition does not independently determine servicing treatment; the downstream governed servicing layer controls execution versus review-hold behavior.

## Physical construction delta

P04 introduced or used report-owned presentation/context objects within the accepted source/model boundary.

The construction includes:

- endpoint monitoring presentation from FactMonitoringEndpoint;
- servicing-execution presentation from FactServicingExecution;
- payment-exception presentation from FactPaymentException;
- servicing queue endpoint information inspected as part of construction;
- explicit P04 measures required by the model's discourage-implicit-measures setting;
- report-owned calculated presentation columns for readable monitoring, servicing, lifecycle and exception labels;
- explicit cross-fact account retrieval using accepted AccountKey context where required;
- zero-state presentation for operational count/exposure KPIs;
- scenario-sensitive endpoint monitoring and servicing behavior;
- a left-side operational summary rail;
- Monitoring posture;
- Servicing disposition;
- Account attention workbench;
- Payment exception history;
- accessibility alt text;
- representative analytical tooltips;
- logical tab order; and
- controlled native master-detail interaction from the Account attention workbench to Payment exception history.

No accepted governed-measure formula was overwritten.

No new business method, denominator, source, connector, Power Query business transformation, table relationship, privacy boundary, custom visual or external executable was introduced through P04 construction.

## Interaction contract

Scenario governs the page-level analytical population.

The Account attention workbench does not redefine portfolio-level monitoring or servicing summary visuals.

Selecting an account in the workbench may filter the associated Payment exception history while portfolio-level posture remains fixed to the selected Scenario.

This preserves a deliberate portfolio-context / account-detail interaction model.

## Provenance clarification

The governed run identity M1_V0_2_BASELINE_BUILD is intentionally shared across BASELINE and RECESSION_ENERGY scenario identities.

Scenario is a separate dimension within the governed run.

Accordingly, selecting RECESSION_ENERGY does not change the governed Run value and this behavior is not treated as a provenance defect.

## Temporal boundary

Monitoring and servicing posture reflects the governed 2026-11-22 synthetic endpoint; payment exceptions reflect dated synthetic servicing events.

Interpretation boundary: Deterministic synthetic evidence.

## Evidence population

Representative P04 evidence includes:

- Baseline full-page endpoint state;
- Recession Energy zero-attention state;
- final accessibility alt text;
- Monitoring posture tooltip behavior;
- Servicing disposition tooltip behavior;
- final tab order; and
- native Account attention workbench to Payment exception history master-detail interaction.

## Freeze determination

P04 is frozen as the current construction candidate.

Do not reopen P04 absent:

- a material construction defect;
- a hard-stop condition;
- a coherent-wave remediation requirement; or
- a later independently authorized model/method change.

Continue the authorized current-model report-depth wave with P05 — Risk, Economics & Concentration.
'@ |
    Set-Content `
        "$FreezeRoot\P04_CONSTRUCTION_FREEZE_AND_DELTA.md" `
        -Encoding UTF8
```

Append timestamp and physical project identity:

```powershell
@"

## Frozen physical project identity

Freeze timestamp:

$FreezeTimestamp

Project root:

$ProjectRoot

Project manifest root SHA-256:

$RootHash

P04 evidence carrier SHA-256:

$EvidenceZipHash
"@ |
    Add-Content `
        "$FreezeRoot\P04_CONSTRUCTION_FREEZE_AND_DELTA.md" `
        -Encoding UTF8
```

Inspect:

```powershell
Get-Content "$FreezeRoot\P04_CONSTRUCTION_FREEZE_AND_DELTA.md"
```

---

# 9. Create a compact freeze summary

This gives us a machine-friendly metadata record in addition to the Markdown narrative.

```powershell
$FreezeSummary = [ordered]@{
    page_id                    = "P04"
    tab_name                   = "P04 - Servicing & Exceptions"
    page_title                 = "Merchant Servicing & Exceptions"
    freeze_timestamp           = $FreezeTimestamp
    project_root               = $ProjectRoot
    project_manifest_root_sha256 = $RootHash
    evidence_zip               = "P04_Evidence_Capture.zip"
    evidence_zip_sha256        = $EvidenceZipHash
    temporal_contract          = "Governed 2026-11-22 synthetic endpoint; dated synthetic payment exceptions"
    scenario_control           = "Scenario"
    observation_date_control   = $false
    publication_authorized     = $false
    deployment_authorized      = $false
    construction_status        = "FROZEN_CANDIDATE"
}

$FreezeSummary |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        "$FreezeRoot\P04_FREEZE_SUMMARY.json" `
        -Encoding UTF8
```

Inspect it:

```powershell
Get-Content "$FreezeRoot\P04_FREEZE_SUMMARY.json"
```

---

# 10. Build the final P04 freeze inventory

Do this **after everything else above**.

```powershell
$FreezeInventory = Get-ChildItem $FreezeRoot -Recurse -File |
    Where-Object {
        $_.FullName -ne "$FreezeRoot\P04_FREEZE_INVENTORY.csv"
    } |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256

        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($FreezeRoot.Length + 1).Replace("\","/")
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLowerInvariant()
        }
    }

$FreezeInventory |
    Export-Csv `
        "$FreezeRoot\P04_FREEZE_INVENTORY.csv" `
        -NoTypeInformation
```

Inspect the entire freeze package:

```powershell
Get-ChildItem $FreezeRoot -Recurse -File |
    Sort-Object FullName |
    Select-Object `
        @{N="RelativePath";E={$_.FullName.Substring($FreezeRoot.Length + 1)}},
        Length |
    Format-Table -AutoSize
```

---

# 11. Final integrity check

Verify that every file listed in the project manifest still matches the saved project.

```powershell
$ProjectCheck = Import-Csv "$FreezeRoot\manifests\P04_PROJECT_FILE_MANIFEST.csv" |
    ForEach-Object {

        $PhysicalPath = Join-Path $ProjectRoot ($_.RelativePath.Replace("/","\"))

        if (-not (Test-Path -LiteralPath $PhysicalPath)) {
            [PSCustomObject]@{
                RelativePath = $_.RelativePath
                Result       = "MISSING"
            }
            return
        }

        $CurrentHash = (
            Get-FileHash `
                -LiteralPath $PhysicalPath `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        [PSCustomObject]@{
            RelativePath = $_.RelativePath
            Result       = if ($CurrentHash -eq $_.SHA256) { "PASS" } else { "HASH_MISMATCH" }
        }
    }

$ProjectCheck |
    Export-Csv `
        "$FreezeRoot\manifests\P04_PROJECT_RECHECK.csv" `
        -NoTypeInformation

$Failures = $ProjectCheck |
    Where-Object { $_.Result -ne "PASS" }

if ($Failures) {
    Write-Host "P04 FREEZE RECHECK FAILED" -ForegroundColor Red
    $Failures | Format-Table -AutoSize
}
else {
    Write-Host "P04 project recheck: ALL FILES PASS" -ForegroundColor Green
}
```

Because we are not editing Power BI during this freeze operation, every project file should return `PASS`.

---

# 12. Freeze completion output

Finally:

```powershell
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "P04 FREEZE COMPLETE" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Project manifest root:"
Write-Host $RootHash
Write-Host ""
Write-Host "Evidence carrier SHA-256:"
Write-Host $EvidenceZipHash
Write-Host ""
Write-Host "Freeze evidence root:"
Write-Host $FreezeRoot
Write-Host ""
Write-Host "Next construction page:"
Write-Host "P05 - Risk, Economics & Concentration"
Write-Host ""
```

### After this

Do **not** reopen P04 for ordinary polishing, and do not ZIP the entire P04 freeze directory into a final Audit submission yet. The directory should remain the frozen P04 component alongside `P03_FREEZE`.

Our construction state will then be:

**P01** accepted  
**P02** accepted  
**P03** frozen construction candidate  
**P04** frozen construction candidate  
**P05** next — Risk, Economics & Concentration  
**P06** later — Governance & Reconciliation

Once P05 and P06 are built and frozen, we can assemble **one coherent current-model report-depth wave package** for Independent Audit rather than creating separate page-level audit submissions. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-160f0740-20cd-43e3-96e6-cf89c24a50df"></a>
## Andrew / user · C109-M00474

C109-M00474 · 2026-08-27T12:23:02.903000-04:00 · active path

Preceding visible parent: [C109-M00473](part-17.md#m-75854e0f-d538-40f1-b012-cd6b7e0af617)

<!-- BEGIN_SOURCE_MESSAGE -->
wasn't there a privacy or profile, etc initial powershell command we had been using at the start of every powershell instance.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c75bfcb6-f75f-48d4-9945-95a64752bddd"></a>
## Assistant · C109-M00475

C109-M00475 · 2026-08-27T12:23:21.306354-04:00 · active path

Preceding visible parent: [C109-M00474](part-17.md#m-160f0740-20cd-43e3-96e6-cf89c24a50df)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. You remembered correctly. We have consistently been starting the controlled MSBF PowerShell sessions with a **process-scoped execution-policy bypass**, often together with the stop-on-error setting.

Use this **before Step 1** of the P04 freeze commands I just gave you:

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

The important command you were remembering is:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

### Why we use `-Scope Process`

It applies **only to the current PowerShell process**. When you close that PowerShell window, the bypass disappears. We are not changing your machine-wide or user-wide execution-policy configuration.

In some of the earlier controlled construction workflows we also launched scripts explicitly with:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass ...
```

The **`-NoProfile`** part is probably the “profile/privacy” wording you were remembering. That is useful when launching a new PowerShell process to ensure your personal PowerShell profile doesn't alter the controlled execution environment.

For the interactive session you're using now, start with:

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

Then proceed with my P04 freeze block beginning:

```powershell
$ProjectRoot    = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\project"
$EvidenceSource = "C:\MSBF\P04_Evidence_Capture"
$FreezeRoot     = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\evidence\P04_FREEZE"
```

So yes—I omitted the execution-policy initialization from the previous startup block. **Add it back as part of our standard startup sequence.** [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e0c87743-218b-449f-bddd-aa7ce9c70c47"></a>
## Andrew / user · C109-M00476

C109-M00476 · 2026-08-27T12:40:28.435000-04:00 · active path

Preceding visible parent: [C109-M00475](part-17.md#m-c75bfcb6-f75f-48d4-9945-95a64752bddd)

<!-- BEGIN_SOURCE_MESSAGE -->
P04 frozen construction candidate is complete. Let's discuss the story we've told so far across P01 through P04 .  One thing I've thought about is that P03 doesn't necessarily tell us explicitly why a loan was approved or not. What were the underlying metrics that led to the decision. Is that something we can easily improve on in P03, and should we? I think if I was in an interview they would want to know what were the underlying elements that I considered in my model that ultimately impacted that decision. Secondly, I think beyond risk I'd want to know as an executive, what was the bottom line, what was our ROI. Are we telling that story in P05/P06 and should we? What is the remaining story to tell?
<!-- END_SOURCE_MESSAGE -->


<a id="m-ccf60880-34c2-4b72-a180-8673b1902c4e"></a>
## Assistant · C109-M00477

C109-M00477 · 2026-08-27T12:40:49.644033-04:00 · active path

Preceding visible parent: [C109-M00476](part-17.md#m-e0c87743-218b-449f-bddd-aa7ce9c70c47)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I think you've identified the **two remaining questions that elevate this from a good Power BI portfolio into an executive credit-strategy story**:

1. **Why did we make the credit decision?**
2. **Did the business make money for the risk it took?**

P01–P04 already tell a coherent operational story, but those two questions are not yet prominent enough.

## The story P01–P04 currently tells

I would characterize the report sequence this way:

**P01 — Cohort Command Center:** *What did we launch and what happened at a high level?* This is the executive entry point: population, decision/funding outcomes, portfolio scale and high-level reconciliation.

**P02 — Cohort Lifecycle:** *How did the funded cohort perform through time?* We move from origination into seasoning/performance and show how the fixed launch cohort develops.

**P03 — Application Journey:** *What happened to this particular application/account?* We now follow one merchant from contextual profile → request → decision → funded terms → receivable/remittance performance → monitoring → servicing.

**P04 — Merchant Servicing & Exceptions:** *Where did the portfolio require operational attention, and what did we do about it?* This turns the account-level servicing experience into a portfolio operational workbench.

That's already a good sequence:

> **Launch → Season → Investigate → Intervene**

But there are two gaps:

> **Why did we decide?**  
> **Was it economically worthwhile?**

Those are exactly the questions I would expect a strong interviewer—particularly in credit strategy, portfolio analytics, model governance, or executive analytics—to ask.

---

# 1. P03 should explain the decision

I think we should **reopen P03 in a very bounded way**.

Not because P03 is defective. It is because physical construction has revealed an opportunity to make the page substantially more valuable.

Right now P03 tells us:

> Merchant 000749 requested X → **APPROVED / Final offer**

or

> Merchant 000001 requested X → **DECLINED / Evidence decline**

But it doesn't adequately answer:

> **Why?**

That's a material analytical gap in an application journey.

And your underlying model is much richer than what P03 currently exposes. The project contains cash-flow capacity, resilience, integrated risk, exposure, recovery/LGD, comparative loss and related underwriting/economic evidence. The broader strategy design also includes eligibility, pricing/structure, approve/counteroffer/manual-review/decline logic. [export reference: memcite]

### What I would add to P03

Not another giant table and definitely not a fake “model score.”

I would add a compact section between **Merchant context/request** and the downstream lifecycle called something like:

### **Decision profile**

Its job is to expose perhaps **5–7 governed decision-relevant metrics**.

Conceptually:

| Dimension | Example of what we want |
|---|---|
| Capacity | Cash-flow / repayment capacity |
| Resilience | Merchant resilience measure/tier |
| Risk | Integrated risk tier/measure |
| Exposure | Exposure / affordability relationship |
| Loss | Comparative loss / expected-loss evidence if actually decision-relevant |
| Economics | Unit-economic or pricing measure if actually used upstream |
| Evidence | Sufficiency/eligibility state |

Then the viewer gets:

**Merchant characteristics**  
↓  
**Requested structure**  
↓  
**Decision profile**  
↓  
**APPROVED / REVIEW / DECLINED**  
↓  
**Funded terms**  
↓  
**Performance**

That would transform P03 from a transaction trace into an **underwriting narrative**.

### But there is an important constraint

We should **not infer that every available risk metric caused the decision**.

Before building this section, we should inspect the actual decision/candidate/eligibility facts and documentation and identify:

- which variables genuinely feed the decision;
- which are merely descriptive;
- what thresholds or gates exist;
- what causes policy decline;
- what causes evidence decline;
- what causes counteroffer review;
- what permits final-offer authorization.

That's particularly important for an interview. You want to be able to say:

> “These are the governed inputs and gates that drove the synthetic decision.”

rather than:

> “These are some risk metrics that happened to be available on the merchant.”

The former demonstrates **credit strategy design**. The latter is just dashboarding.

So yes: **I recommend a bounded P03 enhancement, but only after physical inspection of the decision-driving structures.**

---

# 2. P05 absolutely should answer “Did we make money?”

This should become one of P05's principal jobs.

Our working title:

### **Risk, Economics & Concentration**

is actually very good because those three concepts belong together.

The executive question isn't merely:

> “How risky was the portfolio?”

It's:

> **“What return did we generate for the risk and capital/exposure we took, and where is that result concentrated?”**

The model already contains unit economics, merchant acquisition cost, exposure, recovery/LGD and comparative-loss evidence. [export reference: memcite]

So I would structure P05 around three executive questions.

### A. Economics — What was the bottom line?

This should be prominent, potentially the **left summary rail**.

We need to inspect the actual economic facts before choosing the exact metrics, but conceptually I want:

**Funded principal / deployed capital**  
**Finance charge / contractual revenue**  
**Realized or simulated collections**  
**Loss / unrecovered exposure**  
**Acquisition cost**  
**Net economics**  
**ROI / return on deployed capital**

Possibly contribution margin or another accepted economic metric if the model contains it.

The important thing is that we should **not invent a new ROI methodology in Power BI**. If Module 2 contains an accepted economics method from which ROI can be truthfully calculated, use it. If not, we expose the accepted economic components and defer the derived ROI until the method is governed.

### B. Risk — What did we earn for the risk?

This is where the page gets much more interesting than a standard portfolio dashboard.

We want to answer things like:

- economic outcome by risk tier;
- loss/exposure by risk tier;
- economics by merchant size;
- economics by industry;
- economics by acquisition channel;
- potentially economics by decision/offer structure.

Then the executive can see:

> “This segment generated more contractual revenue, but did the incremental risk justify it?”

That is the core portfolio-management question.

### C. Concentration — Where are we exposed?

Industry, merchant size, acquisition source/channel, risk tier, perhaps geography if supported.

But concentration shouldn't just be:

> “28% of balances are restaurants.”

It becomes much more useful if we can show:

> **Exposure share + economic contribution + risk/loss**

for the same segment.

That lets an executive distinguish:

**large and profitable**  
from  
**large and risky**  
from  
**small but disproportionately loss-producing**.

That's a very credible executive portfolio-management experience.

---

# 3. P06 should NOT become another economics page

I would preserve:

### **P06 — Governance & Reconciliation**

as the final answer to:

> **“Can I trust everything I just saw?”**

That gives the entire report a satisfying close.

P06 should deal with things like:

**source → model → report reconciliation**  
**certification status**  
**control results**  
**unresolved reconciliation exceptions**  
**model/source release identity**  
**governed evidence boundaries**

In other words:

> P05 tells the executive whether the business worked.  
> P06 tells the executive whether the evidence supporting that conclusion is controlled and trustworthy.

I would not dilute P06 with ROI.

---

# The revised six-page narrative

With the bounded P03 improvement, I think we arrive at a remarkably coherent six-page report:

| Page | Executive question |
|---|---|
| **P01 — Cohort Command Center** | **What did we launch and what happened?** |
| **P02 — Cohort Lifecycle** | **How did the funded cohort perform over time?** |
| **P03 — Application Journey** | **Why did we make this decision, and what happened afterward?** |
| **P04 — Servicing & Exceptions** | **Where did performance require intervention, and what did we do?** |
| **P05 — Risk, Economics & Concentration** | **Did we make money for the risk we took, and where is that risk/return concentrated?** |
| **P06 — Governance & Reconciliation** | **Can we trust the numbers and trace them to governed evidence?** |

And that gives us an even cleaner verbal story:

> **Originate → Perform → Explain → Intervene → Evaluate → Trust**

That is much stronger than simply having six attractive dashboards.

## What I would do next

I would **not start P05 quite yet**.

First, perform a very bounded investigation for P03: inspect the physical tables/documentation that contain the actual **eligibility, capacity, resilience, integrated-risk, loss/economic and decision-gate evidence** and determine exactly which metrics caused or governed Final Offer, Counteroffer Review, Policy Decline and Evidence Decline.

If the model supports what I suspect it does, we add one compact **Decision profile** section to P03, UAT the four decision paths again, update the P03 freeze delta as a coherent-wave refinement, and refreeze it.

Then we move to P05 and inspect the physical **economics/risk/concentration facts** before designing that page. That's where I would explicitly investigate whether Module 2 already supports a defensible **ROI/net economics** calculation or whether we should tell the bottom-line story through its governed components instead.

That sequence closes the two most important unanswered executive questions before P06 closes the report on governance. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-8201fece-242c-47c2-9f38-8dcdef225aa3"></a>
## Andrew / user · C109-M00478

C109-M00478 · 2026-08-27T12:49:51.675000-04:00 · active path

Preceding visible parent: [C109-M00477](part-17.md#m-ccf60880-34c2-4b72-a180-8673b1902c4e)

<!-- BEGIN_SOURCE_MESSAGE -->
Help me build this: What I would add to P03
Not another giant table and definitely not a fake “model score.”

I would add a compact section between **Merchant context/request** and the downstream lifecycle called something like:

### **Decision profile**

Its job is to expose perhaps **5–7 governed decision-relevant metrics**.

Conceptually:

| DimensionExample of what we want |                                                                         |
| -------------------------------- | ----------------------------------------------------------------------- |
| Capacity                         | Cash-flow / repayment capacity                                          |
| Resilience                       | Merchant resilience measure/tier                                        |
| Risk                             | Integrated risk tier/measure                                            |
| Exposure                         | Exposure / affordability relationship                                   |
| Loss                             | Comparative loss / expected-loss evidence if actually decision-relevant |
| Economics                        | Unit-economic or pricing measure if actually used upstream              |
| Evidence                         | Sufficiency/eligibility state                                           |

Then the viewer gets:

**Merchant characteristics**

↓

**Requested structure**

↓

**Decision profile**

↓

**APPROVED / REVIEW / DECLINED**

↓

**Funded terms**

↓

**Performance**

That would transform P03 from a transaction trace into an **underwriting narrative**.

### But there is an important constraint

We should **not infer that every available risk metric caused the decision**.

Before building this section, we should inspect the actual decision/candidate/eligibility facts and documentation and identify:

-  which variables genuinely feed the decision; 
-  which are merely descriptive; 
-  what thresholds or gates exist; 
-  what causes policy decline; 
-  what causes evidence decline; 
-  what causes counteroffer review; 
-  what permits final-offer authorization. 

That's particularly important for an interview. You want to be able to say:

> “These are the governed inputs and gates that drove the synthetic decision.”

rather than:

> “These are some risk metrics that happened to be available on the merchant.”

The former demonstrates **credit strategy design**. The latter is just dashboarding.

So yes: **I recommend a bounded P03 enhancement, but only after physical inspection of the decision-driving structures.              NOTE, I'm thinking we can create a similar table to Merchant request (with no title) and place it directly under that current table). Essentially it'll be like a second set of columns/1 x row under that same Merchant request section. I think I can fit that into the white space there.**
<!-- END_SOURCE_MESSAGE -->
