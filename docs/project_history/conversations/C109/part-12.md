# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 12 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-11.md)
[Next part](part-13.md)

<a id="m-f910a805-8272-40b0-b052-dd0fd502689e"></a>
## Assistant · C109-M00307

C109-M00307 · 2026-08-26T18:33:13.184861-04:00 · active path

Preceding visible parent: [C109-M00306](part-11.md#m-106029e1-4bd7-4b05-bb64-3314f712144d)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that result tells us the **measure is the wrong object for this particular table use case**. Your screenshot is actually very diagnostic.

When you add `P03 Application ID`, Power BI starts evaluating that measure across the table's grouping contexts. Because the measure uses `SELECTEDVALUE('DimApplication'[merchant_application_id])`, most of those generated contexts do **not** resolve to exactly one application, so the measure returns `NOT AVAILABLE`. One context finally resolves to the actual application and returns `A01`. That's why adding the measure explodes the visual into many rows.

So, **delete `P03 Application ID` from this table.** The underlying application data is fine; the problem is only our presentation adapter.

For a row-level identifier such as application suffix, a **calculated column on `DimApplication`** is the cleaner object because the suffix is an attribute of each application row, not a context-dependent calculation. The model authority confirms that `merchant_application_id` is the scenario-invariant application identity, while the semantic `ApplicationKey` adds the run boundary. [export reference: filecite | turn39file0 | L9-L12]

Create this calculated column in `DimApplication`:

```DAX
P03 Application Label =
VAR _Application = 'DimApplication'[merchant_application_id]
VAR _Marker = SEARCH ( "_A", _Application, 1, 0 )
RETURN
    IF (
        ISBLANK ( _Application ) || _Marker = 0,
        BLANK (),
        MID (
            _Application,
            _Marker + 1,
            LEN ( _Application )
        )
    )
```

For:

```text
MSBF_POP_0001_M000012_A01
```

it returns:

```text
A01
```

And because this is a **column on the application row**, if you put it into a table beside `application_date`, `requested_funding_amount`, etc., it will stay at the same one-row application grain rather than changing the grouping behavior.

### What about the existing measure?

I would actually **delete `P03 Application ID`** from `ModelParameters`. We discovered empirically that this identity belongs at row grain, so carrying both a measure and a column just creates unnecessary adapter clutter.

The calculated column should be named something like:

**`P03 Application Label`**

rather than `Application ID`, because technically the governed application identifier is still the complete:

`MSBF_POP_0001_M000012_A01`

We're only creating a compact **presentation label** from its application-sequence component.

### One more important observation from your screenshot

Those extra rows from `$5,000`, `$5,100`, `$5,200`, etc. are another reason not to try to make scalar measures do row-identity work. The measure is causing Power BI to evaluate combinations that weren't exposed when the table consisted only of row-level fields. It does **not** mean Merchant 000012 suddenly has all those applications.

So the correct pattern going forward is:

```text
Row-level application attribute
→ calculated presentation column

Scalar KPI / context-dependent value
→ explicit measure
```

That is cleaner semantically and should behave naturally in both tables and future drillthrough.

After creating `P03 Application Label`, replace the long `merchant_application_id` in your diagnostic table with this new column. You should get the same single row, except the first field will simply read **A01**. Show me that result, and then we're ready to stop diagnosing application identity and design the actual **Current application → Decision & offer** presentation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-33a33275-eda6-4a13-be37-f531485cc79e"></a>
## Andrew / user · C109-M00308

C109-M00308 · 2026-08-26T18:48:16.811000-04:00 · active path

Preceding visible parent: [C109-M00307](part-12.md#m-f910a805-8272-40b0-b052-dd0fd502689e)

**Editorial record note:** Attachment references: Pasted text(20260826-224811).txt

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3f46153e-ec20-4c30-9fec-c336d69e4261"></a>
## Assistant · C109-M00309

C109-M00309 · 2026-08-26T18:48:40.451147-04:00 · active path

Preceding visible parent: [C109-M00308](part-12.md#m-33a33275-eda6-4a13-be37-f531485cc79e)

<!-- BEGIN_SOURCE_MESSAGE -->
The pasted data confirms the identifier structure we inferred. `merchant_application_id` is explicitly carried alongside separate `population_id` and `merchant_id` fields, and the composite keys then prepend run/scenario identifiers. For example, Merchant 000012 appears as `MSBF_POP_0001_M000012_A01`, with `ApplicationKey = 1|MSBF_POP_0001_M000012_A01` and `ApplicationScenarioKey = 1|6|MSBF_POP_0001_M000012_A01`. [export reference: filecite | turn40file0 | L1-L10]

So our interpretation is now well supported:

```text
MSBF_POP_0001_M000012_A01
│        │       │      │
│        │       │      └─ Application sequence = A01
│        │       └──────── Merchant = M000012
│        └──────────────── Population = POP_0001
└───────────────────────── MSBF namespace
```

One correction to my previous recommendation, though: **do not create the calculated column yet.** Given the audit authorization, we should minimize semantic-model additions when the existing physical field can do the job. We also now know from the supplied decision data that `A01` is consistently embedded in the governed application identifier; the rows shown throughout the file follow that pattern. [export reference: filecite | turn40file0 | L5-L8]

For the actual P03 experience, I don't think the user needs to see `A01` at all unless there are multiple applications for a merchant. Right now the application table is telling a much more useful story through **application date, requested amount, use of proceeds, channel, requested remittance rate, expected payoff days, requested repayment, finance charge, status and source**.

More importantly, this new file gives us the next layer we need: **final decision and offer.** It contains `final_decision_outcome_code`, authorization/review flags, final offer amount, final remittance rate, payback multiple, collection horizon, total repayment, finance charge, implied payoff days, evidence status and decision reasons. [export reference: filecite | turn40file0 | L1-L10]

So I recommend we stop spending time on application-ID cosmetics and proceed with the real P03 story.

### Next step in Power BI

Leave your two working application tables in place for the moment. Keep **Merchant 000012**, **Baseline**, and **7/23/2026** selected.

Now find the model table corresponding to the data you just pasted — it should contain fields such as:

```text
final_decision_outcome_code
final_offer_authorized_flag
counteroffer_review_required_flag
decline_authorized_flag
manual_review_required_flag
final_offer_amount
final_remittance_rate
final_payback_multiple
final_collection_horizon_days
final_total_repayment_amount
final_finance_charge_amount
final_implied_payoff_days
final_authorization_evidence_status
primary_decision_reason_code
```

Create **one new temporary Table visual** beneath the application tables.

For the first test, add only these **four fields**, in this order:

```text
merchant_application_id
scenario_code
final_decision_outcome_code
final_authorization_evidence_status
```

Don't format it yet and don't add the monetary fields yet.

We're testing something materially more important than presentation: whether the **Merchant + Scenario selection propagates correctly from the application/request layer into the final-decision layer**.

For Merchant 000012 under **Baseline**, I want to see exactly what that four-column diagnostic table returns. That will tell us how to build the **Application → Decision → Offer** section without introducing another unnecessary adapter.
<!-- END_SOURCE_MESSAGE -->


<a id="m-756de20d-1f5d-4e03-a613-d7fdc331a573"></a>
## Andrew / user · C109-M00310

C109-M00310 · 2026-08-26T18:52:15.758000-04:00 · active path

Preceding visible parent: [C109-M00309](part-12.md#m-3f46153e-ec20-4c30-9fec-c336d69e4261)

<!-- BEGIN_SOURCE_MESSAGE -->
that fact final decision is a hidden table. we have been creating measures in this case or i could just unhide.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9ad1fd0d-bfb8-4941-8f9b-4fc35b100f81"></a>
## Assistant · C109-M00311

C109-M00311 · 2026-08-26T18:52:18.818150-04:00 · active path

Preceding visible parent: [C109-M00310](part-12.md#m-756de20d-1f5d-4e03-a613-d7fdc331a573)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **Keep `FactFinalDecision` hidden and use measures.** I would not unhide it just to make P03 easier to construct.

That is consistent with how we've been building this report: the hidden fact tables remain technical/model infrastructure, while the report exposes a curated presentation layer through report-owned measures. Audit explicitly authorized those adapters when they are presentation/context measures and do not redefine the underlying business method.

The pasted data also reinforces that this is a good candidate: `FactFinalDecision` contains the governed application/scenario decision result, including the final outcome, authorization status, offer economics, and decision reason. [export reference: filecite | turn40file0 | L1-L10]

### Let's create the P03 decision measures

Start with these four. Create them in the same visible measures table where you've been putting the other `P03` measures:

```DAX
P03 Decision Outcome =
VAR _Value =
    SELECTEDVALUE ( FactFinalDecision[final_decision_outcome_code] )
RETURN
    COALESCE ( _Value, "NOT AVAILABLE" )
```

```DAX
P03 Decision Evidence Status =
VAR _Value =
    SELECTEDVALUE ( FactFinalDecision[final_authorization_evidence_status] )
RETURN
    COALESCE ( _Value, "NOT AVAILABLE" )
```

```DAX
P03 Final Offer Amount =
SELECTEDVALUE ( FactFinalDecision[final_offer_amount] )
```

```DAX
P03 Final Remittance Rate =
SELECTEDVALUE ( FactFinalDecision[final_remittance_rate] )
```

**Do not create anything else yet.**

Then create a temporary table containing, in this exact order:

```text
P03 Decision Outcome
P03 Decision Evidence Status
P03 Final Offer Amount
P03 Final Remittance Rate
```

Keep **Merchant 000012 / Baseline / 7/23/2026** selected.

### What we're testing

This is a cleaner test than unhiding the fact. If those measures resolve correctly, we've demonstrated that the existing filter path gives us a unique final-decision row at the intended P03 context.

Also, don't be concerned if **Final Offer Amount is blank** for Merchant 000012. The supplied final-decision data shows Merchant 000012 under Recession Energy as `DECLINE_POLICY_AUTHORIZED`, with the offer-economic fields blank—which is exactly the kind of state in which blank should remain semantically meaningful rather than being converted to zero. [export reference: filecite | turn40file0 | L10-L10]

Once you show me what those four measures return for **000012 / Baseline**, we'll know whether we can proceed directly into the polished **Application → Decision → Offer** experience or need to adjust the measure context first.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c7006089-7b9d-4d9e-9d2f-83fbbffd229c"></a>
## Andrew / user · C109-M00312

C109-M00312 · 2026-08-26T18:53:27.385000-04:00 · active path

Preceding visible parent: [C109-M00311](part-12.md#m-9ad1fd0d-bfb8-4941-8f9b-4fc35b100f81)

<!-- BEGIN_SOURCE_MESSAGE -->
final decision outcome code does exist in another, visible table but the evidence status does not
<!-- END_SOURCE_MESSAGE -->


<a id="m-5d3a251b-ac44-402c-8492-939f00de04c1"></a>
## Assistant · C109-M00313

C109-M00313 · 2026-08-26T18:53:32.309301-04:00 · active path

Preceding visible parent: [C109-M00312](part-12.md#m-c7006089-7b9d-4d9e-9d2f-83fbbffd229c)

<!-- BEGIN_SOURCE_MESSAGE -->
Then use the **visible table for `final_decision_outcome_code`** and reserve a report-owned measure only for the hidden fact field that has no visible equivalent.

That is preferable to unnecessarily reaching into a hidden fact for a field we already expose elsewhere.

So I would revise the plan like this:

For the outcome, use the existing visible field directly wherever the visual allows it. If you need a scalar/card value, create a thin display measure over that visible table rather than `FactFinalDecision`.

For evidence status, keep the hidden fact table hidden and create only:

```DAX
P03 Decision Evidence Status =
VAR _Value =
    SELECTEDVALUE (
        FactFinalDecision[final_authorization_evidence_status]
    )
RETURN
    COALESCE ( _Value, "NOT AVAILABLE" )
```

For the other final-offer economics, first check whether those fields also exist in a visible table. If they do, use the visible source. If they do not, then create narrowly scoped P03 measures from `FactFinalDecision`.

So the rule for P03 should be:

**Visible accepted field exists → use it.**  
**Only hidden technical fact has the needed attribute → create a thin P03 measure.**

That keeps the adapter layer minimal and makes the report easier to maintain.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d520687b-874f-4df4-aa59-1f8068b2b0a6"></a>
## Andrew / user · C109-M00314

C109-M00314 · 2026-08-26T18:55:44.495000-04:00 · active path

Preceding visible parent: [C109-M00313](part-12.md#m-5d3a251b-ac44-402c-8492-939f00de04c1)

<!-- BEGIN_SOURCE_MESSAGE -->
that P03 Decision Evidence Status expanded the table like before
<!-- END_SOURCE_MESSAGE -->


<a id="m-0b1f1726-ee2a-4693-9a98-1418ef7598dc"></a>
## Assistant · C109-M00315

C109-M00315 · 2026-08-26T18:55:50.084823-04:00 · active path

Preceding visible parent: [C109-M00314](part-12.md#m-d520687b-874f-4df4-aa59-1f8068b2b0a6)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that confirms the same pattern, and my last instruction was wrong for this use case.

`P03 Decision Evidence Status` is a **scalar measure from `FactFinalDecision`**. When you drop it into a row-level table built from another table, Power BI has to evaluate that measure across the table's grouping combinations. Because the row context does not map cleanly to one `FactFinalDecision` row in every generated grouping, the visual expands just like the Application ID measure did.

So: **remove `P03 Decision Evidence Status` from the table. Do not troubleshoot the data.**

For P03, I would use this rule going forward:

- **Row/detail tables:** use columns from the table that owns the row grain.
- **Cards/KPIs:** use explicit measures.
- Do not mix hidden-fact scalar measures into a diagnostic/detail table unless we deliberately establish a common row key.

For **Decision Evidence Status**, we don't actually need it in the application/decision table. It's governance metadata, not part of the merchant's core business story. Keep the measure, but eventually display it as a **small Card** or tooltip in the Decision section if we decide it adds value.

### What to do next

For now, build the decision test using only the **visible decision table**.

Add a separate Table visual and start with the visible fields that identify the decision at its natural grain, specifically the available equivalents of:

```text
merchant_application_id
scenario
final_decision_outcome_code
```

Then add any **visible** final-offer fields that exist in that same table.

What I want to see physically is something like:

```text
Application   Scenario   Decision
A01           Baseline   FINAL_OFFER...
```

without any report-owned measures in the table.

Once we confirm that grain, we'll decide how much of it becomes the finished **Decision & offer** presentation.

### One broader correction

We are learning an important Power BI implementation rule for this model:

> **Don't use `SELECTEDVALUE` presentation measures as surrogate row attributes.**

They work very well for cards because the slicers establish a single merchant/application/scenario context. They are a poor fit for table rows when the visual itself is creating grouping contexts.

So the two visual expansions we've encountered are **presentation-layer behavior, not data problems**. We should stop trying to force those measures into tables.

And for `final_authorization_evidence_status` specifically, I would **not create a calculated column or unhide `FactFinalDecision` yet**. It is not important enough to justify changing the semantic presentation surface. We'll use the existing measure later in a scalar context if needed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-629351a8-1fac-4a5e-813f-13b2110e8bc2"></a>
## Andrew / user · C109-M00316

C109-M00316 · 2026-08-26T19:06:39.027000-04:00 · active path

Preceding visible parent: [C109-M00315](part-12.md#m-0b1f1726-ee2a-4693-9a98-1418ef7598dc)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 53b2f94c-7267-4947-9232-3a278591cb72.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3c9511db-a7b7-47cf-9610-32a94b6142aa"></a>
## Assistant · C109-M00317

C109-M00317 · 2026-08-26T19:06:42.422969-04:00 · active path

Preceding visible parent: [C109-M00316](part-12.md#m-629351a8-1fac-4a5e-813f-13b2110e8bc2)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. **This is the clean result we were trying to establish.** The visual is staying at one application row, the Merchant and Scenario context are propagating correctly, and we now have the beginning of a very useful merchant journey.

For Merchant 000012 / Baseline, the story is immediately understandable:

**A01 → Applied 7/23/2026 → Requested $13.1K → Working Capital → Processor Embedded → 14% requested remittance → 60-day expected payoff → $16.64K requested repayment → Policy Decline**

That last transition is where P03 starts becoming much more interesting than simply displaying merchant attributes.

### One immediate cleanup

Rename the two raw headers:

- `scenario_code` → **Scenario**
- `final_decision_outcome_code` → **Decision outcome**

And I would eventually presentation-clean the value `DECLINE_POLICY_AUTHORIZED` to **Policy decline**, just as we did with P01 decision outcomes. But don't create another measure for the table. We should see whether the existing P01 presentation column/label can be reused or whether the visible decision table already has a display label.

### Next: extend this same row into the decision/offer

Don't create another visual yet.

In the **same visible table that supplied `final_decision_outcome_code`**, look for fields corresponding to:

- final offer amount
- final remittance rate
- final payback multiple
- final collection horizon/days
- final total repayment
- final finance charge
- implied payoff days
- primary decision reason

If those are visible, add them temporarily to the **right side of this same table**.

For Merchant 000012 / Baseline, because this is a policy decline, I expect several offer fields to be blank. **That's desirable.** It will show us how the final visual needs to handle different decision paths.

Then change the Scenario slicer to **Recession Energy** and see whether the decision/outcome or offer terms change.

After that, switch to a merchant that receives a **final offer**. That is the state we especially need to inspect because it will tell us whether P03 can elegantly present:

> **Requested terms → Decision → Authorized terms**

rather than simply dumping application and decision fields into a wide table.

### I think we're approaching the final P03 structure

Based on what we've physically learned, I would now expect the middle of the page to become something like:

**Current application**

`A01` · Applied `7/23/2026` · Working capital · Processor embedded

| Requested | Decision / authorized |
|---|---|
| Funding: $13.1K | Policy decline |
| Remittance: 14.0% | — |
| Expected payoff: 60 days | — |
| Repayment: $16.64K | — |

For a funded/final-offer merchant, the right side would instead contain actual authorized terms.

That gives the user a very natural question-and-answer flow:

**Who is the merchant? → What did they request? → What did we decide? → What did we actually fund? → How did it perform?**

So your current table is doing exactly what we needed. **Next, inspect the visible decision table for those final-offer fields and add whichever ones exist to this same diagnostic row.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-b16cbbae-6b65-495c-9bda-ae49cc841e16"></a>
## Andrew / user · C109-M00318

C109-M00318 · 2026-08-26T19:08:38.350000-04:00 · active path

Preceding visible parent: [C109-M00317](part-12.md#m-3c9511db-a7b7-47cf-9610-32a94b6142aa)

<!-- BEGIN_SOURCE_MESSAGE -->
Not sure we even need Scenario since the slicer would select the scenario
<!-- END_SOURCE_MESSAGE -->


<a id="m-5a07ef96-6a48-4858-9f62-eb8576e1774c"></a>
## Assistant · C109-M00319

C109-M00319 · 2026-08-26T19:08:41.240899-04:00 · active path

Preceding visible parent: [C109-M00318](part-12.md#m-b16cbbae-6b65-495c-9bda-ae49cc841e16)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. **I would remove Scenario from this table.**

The Scenario slicer already establishes the scenario context for the page. Repeating `BASELINE` in every row consumes horizontal space without adding information.

That gives us a cleaner row:

**Application ID | Applied | Requested | Use of proceeds | Channel | Requested remittance | Expected payoff | Requested repayment | Decision outcome**

This is also semantically sound because the **Decision outcome changes with the Scenario slicer**, while the application/request attributes generally remain fixed. The user can see the selected scenario directly at the top of the page.

### I would apply this principle throughout P03

Don't repeat slicer context inside visuals unless it serves a specific comparison purpose.

So:

- **Merchant** — selected at top; don't repeat full merchant name everywhere.
- **Scenario** — selected at top; don't repeat it in tables.
- **Observation date** — selected at top; don't repeat it unless a visual specifically needs to show dates over time.
- **Application ID** — useful because it identifies the current application/journey and leaves us future-ready for multiple applications.

Your current visual becomes noticeably stronger simply by dropping `scenario_code`.

And now we have more horizontal room for the important next fields—**Decision outcome** and, where applicable, the authorized offer terms.
<!-- END_SOURCE_MESSAGE -->


<a id="m-57aee6a9-5888-4fca-8b39-28d8e7281ea6"></a>
## Andrew / user · C109-M00320

C109-M00320 · 2026-08-26T19:09:43.881000-04:00 · active path

Preceding visible parent: [C109-M00319](part-12.md#m-5a07ef96-6a48-4858-9f62-eb8576e1774c)

<!-- BEGIN_SOURCE_MESSAGE -->
Decision outcome is duplicative. I named it just Decision and I think this works nicely as a table vs a card
<!-- END_SOURCE_MESSAGE -->


<a id="m-507c5ab2-be68-4c2c-b8c2-2f203f6eeb1c"></a>
## Assistant · C109-M00321

C109-M00321 · 2026-08-26T19:09:46.440160-04:00 · active path

Preceding visible parent: [C109-M00320](part-12.md#m-57aee6a9-5888-4fca-8b39-28d8e7281ea6)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed on both points.

**`Decision` is better than `Decision outcome`.** “Outcome” adds nothing—the values themselves tell us the outcome. And after seeing the physical data, I now prefer this as a **table rather than a card**.

The table works particularly well because it reads naturally left-to-right as a compact transaction narrative:

**Application ID → Applied → Requested → Use of proceeds → Channel → Requested remittance → Expected payoff → Requested repayment → Decision**

That is much more information-dense than a collection of cards, while still being very easy to scan. It also future-proofs P03: if a future population contains A01, A02, etc. for one merchant, the exact same visual simply gains another row instead of requiring redesign.

I would therefore promote this from diagnostic to a **final P03 visual**, with a section title of **Current application** for this release. We can later reconsider “Applications” once the model actually contains multi-application merchants.

### Next step

Now we should determine whether the **authorized/final terms belong in this same table** or deserve the next visual.

Because horizontal space is finite, I don't want to just append every `FactFinalDecision` field. First, find which of these are available in the same visible table that gave you `Decision`:

- Final offer amount
- Final remittance rate
- Final payback multiple
- Final collection horizon
- Final total repayment
- Final finance charge
- Final implied payoff days
- Primary decision reason

Tell me which of those are visible. Then we'll choose the **minimum high-value set** and test a final-offer merchant.

My initial expectation is that the final page will be stronger if this table remains focused on **what the merchant requested + the decision**, while a compact **Authorized terms / Funding** section immediately beneath it tells what actually happened after the decision. That creates a clean progression instead of a 15-column table.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5010791e-e217-4009-953d-7783b9f204bf"></a>
## Andrew / user · C109-M00322

C109-M00322 · 2026-08-26T19:10:59.397000-04:00 · active path

Preceding visible parent: [C109-M00321](part-12.md#m-507c5ab2-be68-4c2c-b8c2-2f203f6eeb1c)

<!-- BEGIN_SOURCE_MESSAGE -->
I like distinguishing what was requested along with the decision in one table and then have a separate table for the approved details.
<!-- END_SOURCE_MESSAGE -->


<a id="m-875a16e4-643c-42b1-a7b7-c73aef652b9d"></a>
## Assistant · C109-M00323

C109-M00323 · 2026-08-26T19:11:02.092047-04:00 · active path

Preceding visible parent: [C109-M00322](part-12.md#m-5010791e-e217-4009-953d-7783b9f204bf)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree. That creates a much stronger **Requested → Decision → Approved structure** and prevents one oversized table from mixing different stages of the financing journey.

I would now treat your current table as essentially final:

### Current application

**Application ID | Applied | Requested | Use of proceeds | Channel | Requested remittance | Expected payoff | Requested repayment | Decision**

That answers:

> **What did the merchant ask for, and what was our decision?**

Then immediately below or beside it, create a second visual:

### Approved terms

That answers:

> **If approved, what terms did we actually authorize?**

I would keep this one deliberately compact. The highest-value fields are:

**Approved amount | Remittance rate | Payback multiple | Collection horizon | Total repayment**

I would consider **Finance charge** useful but secondary; we can add it if space permits. **Implied payoff days** may be duplicative with collection horizon depending on exactly what those two fields mean in this model, so I would not automatically include both.

Critically, for a decline such as Merchant 000012, I want this second visual to **show no approved terms rather than zeros**. Ideally the section communicates something like `No approved offer` rather than producing an empty-looking or misleading row. We'll solve that after seeing the native behavior.

### Build the raw Approved terms table next

Stay on Merchant **000012 / Baseline** for the first test.

From the **visible table containing the final-decision fields**, add these raw columns if available:

```text
final_offer_amount
final_remittance_rate
final_payback_multiple
final_collection_horizon_days
final_total_repayment_amount
```

If `final_finance_charge_amount` is visible, add it temporarily as a sixth field too.

Do **not** add measures and don't add Scenario, Merchant ID, Application ID, Decision, or evidence status. The selected application context is already apparent from the visual immediately above it.

Then we'll test two states:

**000012 / Baseline — decline path**  
We learn how the Approved terms visual behaves when no offer exists.

**A final-offer merchant / Baseline — approval path**  
We learn what a populated authorized structure looks like and whether all six fields deserve permanent space.

After that, the next logical section becomes **Funding / activation**, which is a different event again:

**Requested → Decision → Approved → Funded**

That progression is shaping up to be the core of Merchant Relationship 360, with the left-side relationship profile supplying the historical context and later performance/servicing visuals completing the journey.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d18bb31f-a4f3-4168-8a55-89f33de512a6"></a>
## Andrew / user · C109-M00324

C109-M00324 · 2026-08-26T19:17:50.780000-04:00 · active path

Preceding visible parent: [C109-M00323](part-12.md#m-875a16e4-643c-42b1-a7b7-c73aef652b9d)

**Editorial record note:** 5 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: a549037f-d9d3-4897-b4e9-aecc70c0239b.png; c1a69677-93cc-4530-8eba-8d6ecfb9e2ad.png; 81f4eb41-cece-4bdf-9174-563b6687086f.png; 27f77916-d056-447b-891e-1888689367a3.png; a1e07216-43d1-4b93-9565-36e0d9f1a040.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-ebce1ba6-5f80-4328-b99c-5b805d5a81d8"></a>
## Assistant · C109-M00325

C109-M00325 · 2026-08-26T19:17:53.960531-04:00 · active path

Preceding visible parent: [C109-M00324](part-12.md#m-d18bb31f-a4f3-4168-8a55-89f33de512a6)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a very useful test set. **The two-table architecture is validated.** The screenshots show exactly why separating **Merchant request & decision** from **Authorized terms** is better than combining everything.

The five examples establish three materially different paths:

- **000012 / 000221 / 000001:** decline → no authorized terms.
- **000738:** counteroffer review required → no authorized terms yet.
- **000749:** final offer authorized → authorized terms populate.

And 000749 demonstrates the business story especially well:

> Requested **$17.7K** at **10%**, 90-day expected payoff, $21.45K repayment → **Final offer authorized** → authorized amount **$11.7K** at **10%**, 1.21× payback, 90-day collection horizon, **$14.18K** repayment.

That's exactly the kind of request-to-authorization comparison Merchant 360 should make easy.

## I would keep both tables

They're no longer diagnostic visuals. They're legitimate P03 components.

I would make a few presentation changes now.

### Merchant request & decision

Keep your current nine columns, but clean the displayed values/headers:

| Current | Display |
|---|---|
| Application ID | Application |
| Applied | Applied |
| Requested | Requested |
| Use of proceeds | Use |
| Channel | Channel |
| Requested remittance | Remittance |
| Expected payoff | Payoff days |
| Requested repayment | Repayment |
| Decision | Decision |

I particularly like your title **Merchant request & decision**. Keep it.

We should also clean the categorical values eventually:

`WORKING_CAPITAL` → `Working capital`  
`PROCESSOR_EMBEDDED` → `Processor embedded`  
`FINAL_OFFER_AUTHORIZED` → `Final offer`  
`COUNTEROFFER_REVIEW_REQUIRED` → `Counteroffer review`  
`DECLINE_POLICY_AUTHORIZED` → `Policy decline`  
`DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED` → `Evidence decline`

But I would **not create measures for that**. If these are columns, presentation columns are the appropriate mechanism if needed, just as we learned with Application ID. We can batch that cleanup rather than creating adapters one-by-one right now.

### Authorized terms

Keep these five:

**Funded amount | Remittance | Payback multiple | Collection horizon | Total repayment**

Your selection is excellent.

But there is an important semantic issue with the title:

The fields you've actually used are named:

```text
funded_amount
activation_remittance_rate
activation_payback_multiple
activation_collection_horizon_days
activation_total_repayment_amount
```

Those sound like **activation/funded-account terms**, not merely final-decision authorized-offer terms.

And the fact that they populate for 000749 but not for the decline/review cases is consistent with that.

Therefore, I would rename this section:

## **Funded terms**

rather than **Authorized terms**.

That gives us a much cleaner and more exact lifecycle:

**Merchant request & decision**  
↓  
**Funded terms**

And it avoids claiming that `funded_amount` is merely an authorized amount when the field explicitly says funded.

### One thing to verify before we freeze that title

Change the **Observation date** for Merchant 000749 from 7/23 to a few days later.

If these fields remain the same, as I expect, then they are activation/funding attributes and **Funded terms** is unquestionably the better label.

If they only become populated after an actual funding date, that's even stronger confirmation.

---

## One design issue the screenshots reveal

For decline/review merchants, the empty **Funded terms** table is truthful, but visually it looks unfinished.

Eventually I would prefer:

> **Funded terms**  
> *No funded advance for the selected application and scenario.*

rather than five headers floating above an empty row.

But **don't solve that yet**. That could require another display measure/conditional visual arrangement, and we have more important construction to do first.

The empty table is perfectly acceptable while building.

---

## Next: Funding → performance

We're now ready for the next major P03 component.

Merchant 000749 is the right merchant to keep selected because it has a funded path. Advance the Observation date beyond funding and inspect the account lifecycle.

The next section should answer:

> **Once funded, how is this merchant performing as of the selected observation date?**

We already know from P01/P02 that the model supports:

- current exposure,
- cumulative/expected remittance,
- remittance fulfillment/pace,
- days since last remittance,
- payoff slippage,
- monitoring status,
- active alerts,
- open servicing,
- paid-off status.

But Merchant 360 should not simply reproduce P01.

I think the next visual should be a **compact merchant-level performance trajectory**—likely exposure plus cumulative/expected remittance or remittance fulfillment—paired with a small selected-date servicing/status block.

That would give the page its complete narrative:

**Relationship context**  
→ **Merchant request & decision**  
→ **Funded terms**  
→ **Performance trajectory**  
→ **Servicing & exceptions**

Before we build that, change **000749's Observation date forward until the funded account becomes active** and show me what happens to the Funded terms table and roughly when it first populates. That will establish the activation timing boundary we need for the rest of P03.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1eebbeee-180d-4021-986c-1eff74d47955"></a>
## Andrew / user · C109-M00326

C109-M00326 · 2026-08-26T19:26:28.243000-04:00 · active path

Preceding visible parent: [C109-M00325](part-12.md#m-ebce1ba6-5f80-4328-b99c-5b805d5a81d8)

<!-- BEGIN_SOURCE_MESSAGE -->
I clicked a sort by - how to remove that little triangle
<!-- END_SOURCE_MESSAGE -->


<a id="m-e4b94e96-6d90-4795-90b4-f9f34e477a8f"></a>
## Assistant · C109-M00327

C109-M00327 · 2026-08-26T19:26:31.060055-04:00 · active path

Preceding visible parent: [C109-M00326](part-12.md#m-1eebbeee-180d-4021-986c-1eff74d47955)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. That triangle is Power BI's **sort indicator** for the table column.

To remove it:

1. Select the table.
2. Open the visual's **⋯ (More options)** menu.
3. Choose **Sort axis / Sort by**.
4. Power BI generally requires a table to retain some sort state, so there often isn't a true **“No sort”** option.

For a **Table visual**, the easiest way to make the triangle disappear is usually to **click the currently sorted column header again or Ctrl+click the sorted header** (depending on your Desktop version) to clear/reset that interactive sort.

If that does not clear it, tell me which Power BI menu/options you see under the `...`; there are a couple version-specific behaviors here, and I don't want you changing the underlying model's **Sort by column** property just to remove a visual indicator.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2e33ce12-d5f6-4115-b002-ad74a9512ba5"></a>
## Andrew / user · C109-M00328

C109-M00328 · 2026-08-26T19:30:09.283000-04:00 · active path

Preceding visible parent: [C109-M00327](part-12.md#m-e4b94e96-6d90-4795-90b4-f9f34e477a8f)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 36fbf2f3-b75a-4ec4-90a9-70f2e32d5c09.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-92599a75-3259-4c7e-8826-2d79605207d2"></a>
## Assistant · C109-M00329

C109-M00329 · 2026-08-26T19:30:12.152699-04:00 · active path

Preceding visible parent: [C109-M00328](part-12.md#m-2e33ce12-d5f6-4115-b002-ad74a9512ba5)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **this is much better**, and the move to **Funded terms** is now physically validated.

For Merchant 000749 at observation date 8/16/2026, the page tells a clean sequential story:

**Merchant request & decision**  
A01 → applied 7/23 → requested $17.7K → Working Capital → Processor Embedded → 10% remittance → 90-day payoff → $21.45K repayment → Final offer authorized

**Funded terms**  
$11.7K funded → 10% activation remittance → 1.21× payback → 90-day collection horizon → $14.18K total repayment → funded 7/25

That's a meaningful comparison: the merchant requested **$17.7K**, but the ultimately funded amount was **$11.7K**. The two-table structure makes that immediately apparent without us manufacturing a variance metric.

A few refinements before moving on:

- Keep **Funded terms** as the title.
- Keep `funding_date`; it is important because it establishes when the application became an active advance.
- Rename `funding_date` → **Funded**.
- I'd shorten **Collection horizon** to **Horizon days** if you need horizontal space.
- Format **Payback multiple** as `1.21×` if Power BI permits that cleanly without creating another semantic adapter. Otherwise `1.21` is perfectly acceptable.
- The raw decision value `FINAL_OFFER_AUTHORIZED` is now the biggest remaining presentation rough edge. We should eventually show **Final offer**. Likewise `WORKING_CAPITAL` → **Working capital** and `PROCESSOR_EMBEDDED` → **Processor embedded**. I suggest batching those presentation-label corrections rather than interrupting construction now.

And importantly, the observation-date test has confirmed what we needed: **funding occurred 7/25/2026 and the funded terms persist when we move the observation date forward.** They are fixed activation attributes, while the selected date will control the subsequent performance/servicing state.

## Next visual: merchant performance

We're ready to leave origination and move into the lifecycle.

Keep:

**Merchant 000749 | Baseline | Observation date 8/16/2026**

The next section should answer:

> **How has this funded advance performed from funding through the selected observation date?**

I recommend that our first physical test be a **line chart** using the account-daily data, with:

**X-axis:** monitoring/observation date  
**Y-axis:** exposure/receivable balance

But unlike P02, P03 should **end the trajectory at the selected Observation date**. That's important: this is a merchant 360 viewed **as of 8/16**, so it shouldn't reveal the merchant's subsequent lifecycle through November.

Then we'll likely add remittance performance to that section and eventually a compact selected-date status/servicing block.

So the page is now naturally becoming:

**Relationship profile** → **Merchant request & decision** → **Funded terms** → **Performance through selected date** → **Servicing & exceptions**

I would proceed next with the **exposure-through-selected-date line chart**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-eb14758b-087c-416e-9aab-872db66b2d6e"></a>
## Andrew / user · C109-M00330

C109-M00330 · 2026-08-26T19:32:15.595000-04:00 · active path

Preceding visible parent: [C109-M00329](part-12.md#m-92599a75-3259-4c7e-8826-2d79605207d2)

<!-- BEGIN_SOURCE_MESSAGE -->
If you'd like to propose updated columns for working capital / channel / decision - or anything else - propose and let's build
<!-- END_SOURCE_MESSAGE -->


<a id="m-9a68095a-98bd-4a38-b938-03f7b8149040"></a>
## Assistant · C109-M00331

C109-M00331 · 2026-08-26T19:32:18.419888-04:00 · active path

Preceding visible parent: [C109-M00330](part-12.md#m-eb14758b-087c-416e-9aab-872db66b2d6e)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Now is a good time to create a **small P03 presentation-label layer**. We have enough physical evidence to know which raw codes are hurting readability, and calculated columns are preferable here because these are row attributes used in tables—not scalar measures.

I would create **three columns now**, all on the table that owns the corresponding raw field. I would not transform the underlying governed columns.

### 1. Application use label — `DimApplication`

```DAX
P03 Use Label =
VAR _Value = 'DimApplication'[requested_use_of_proceeds]
RETURN
    SWITCH (
        _Value,
        "WORKING_CAPITAL", "Working capital",
        "INVENTORY", "Inventory",
        "SEASONAL_NEED", "Seasonal need",
        "EXPANSION", "Expansion",
        "EQUIPMENT", "Equipment",
        IF (
            ISBLANK ( _Value ),
            BLANK (),
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

This is intentionally fail-soft: if another valid category exists that we haven't explicitly mapped, it still displays without underscores rather than disappearing.

Use the visual header **Use**.

### 2. Application channel label — `DimApplication`

```DAX
P03 Channel Label =
VAR _Value = 'DimApplication'[application_channel]
RETURN
    SWITCH (
        _Value,
        "PROCESSOR_EMBEDDED", "Processor embedded",
        "DIGITAL_DIRECT", "Digital direct",
        "BROKER_REFERRAL", "Broker referral",
        IF (
            ISBLANK ( _Value ),
            BLANK (),
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

Visual header:

**Channel**

### 3. Decision label — on the visible table currently supplying `final_decision_outcome_code`

Use the **same table that contains your raw Decision field**. Replace `YourVisibleDecisionTable` below with its actual name:

```DAX
P03 Decision Label =
VAR _Value =
    'YourVisibleDecisionTable'[final_decision_outcome_code]
RETURN
    SWITCH (
        _Value,
        "FINAL_OFFER_AUTHORIZED", "Final offer",
        "COUNTEROFFER_REVIEW_REQUIRED", "Counteroffer review",
        "DECLINE_POLICY_AUTHORIZED", "Policy decline",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "Evidence decline",
        IF (
            ISBLANK ( _Value ),
            BLANK (),
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

Visual header:

**Decision**

Before you create that third column, tell me the **actual visible table name** containing `final_decision_outcome_code`, and I'll give you the exact paste-ready DAX rather than having you substitute anything.

### I would also keep these existing presentation choices

Your current headers are already strong:

**Merchant request & decision**

`Application | Applied | Requested | Use | Channel | Remittance | Payoff days | Repayment | Decision`

**Funded terms**

`Funded amount | Remittance | Payback multiple | Horizon days | Total repayment | Funded`

I wouldn't add more columns to either table right now.

### Formatting cleanup

While we're here:

- Requested / Funded amount: `$#,0` or `$#,0.00` depending on how you want the report standardized. Given the underlying terms, I'd favor **$13.1K / $11.7K** only if Power BI's native display units look good; otherwise `$13,100` is excellent.
- Remittance: **14.0% / 10.0%**, not `0.14 / 0.10`.
- Payback multiple: **1.21×** if native formatting permits; otherwise `1.21`.
- Payoff/Horizon days: integer, no `.00`.
- Repayment: currency.
- Applied/Funded: short date.

The categorical-label columns are worth creating because they materially improve executive readability. The numeric changes should mostly be **format strings**, not new measures or columns.

Give me the visible table name for `final_decision_outcome_code`, and we'll finish the three-column presentation layer before moving into performance.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b0c5464e-7eb2-478c-bd32-9e37d39d4b12"></a>
## Andrew / user · C109-M00332

C109-M00332 · 2026-08-26T19:41:43.179000-04:00 · active path

Preceding visible parent: [C109-M00331](part-12.md#m-9a68095a-98bd-4a38-b938-03f7b8149040)

<!-- BEGIN_SOURCE_MESSAGE -->
DimDecisionOutcome
<!-- END_SOURCE_MESSAGE -->


<a id="m-e82976c6-3ab9-4982-a685-19e95154981c"></a>
## Assistant · C109-M00333

C109-M00333 · 2026-08-26T19:41:48.703386-04:00 · active path

Preceding visible parent: [C109-M00332](part-12.md#m-b0c5464e-7eb2-478c-bd32-9e37d39d4b12)

<!-- BEGIN_SOURCE_MESSAGE -->
Great. Then the exact calculated column goes on `DimDecisionOutcome`:

```DAX
P03 Decision Label =
VAR _Value =
    'DimDecisionOutcome'[final_decision_outcome_code]
RETURN
    SWITCH (
        _Value,
        "FINAL_OFFER_AUTHORIZED", "Final offer",
        "COUNTEROFFER_REVIEW_REQUIRED", "Counteroffer review",
        "DECLINE_POLICY_AUTHORIZED", "Policy decline",
        "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED", "Evidence decline",
        IF (
            ISBLANK ( _Value ),
            BLANK (),
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

Then replace the raw `final_decision_outcome_code` column in **Merchant request & decision** with `P03 Decision Label`, and rename the displayed header simply:

**Decision**

I would also go ahead and create the two `DimApplication` presentation columns from my last response at the same time:

```DAX
P03 Use Label =
VAR _Value = 'DimApplication'[requested_use_of_proceeds]
RETURN
    SWITCH (
        _Value,
        "WORKING_CAPITAL", "Working capital",
        "INVENTORY", "Inventory",
        "SEASONAL_NEED", "Seasonal need",
        "EXPANSION", "Expansion",
        "EQUIPMENT", "Equipment",
        IF (
            ISBLANK ( _Value ),
            BLANK (),
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

```DAX
P03 Channel Label =
VAR _Value = 'DimApplication'[application_channel]
RETURN
    SWITCH (
        _Value,
        "PROCESSOR_EMBEDDED", "Processor embedded",
        "DIGITAL_DIRECT", "Digital direct",
        "BROKER_REFERRAL", "Broker referral",
        IF (
            ISBLANK ( _Value ),
            BLANK (),
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

Then swap those into the table and keep the displayed headers as **Use** and **Channel**.

That gives you a much cleaner row without changing any governed source values. After that, I’d format the numeric columns: Remittance as percent, Payoff/Horizon as whole numbers, and Payback multiple as 2 decimals.
<!-- END_SOURCE_MESSAGE -->


<a id="m-34c1c8ea-0319-4d07-ad0a-c8522888ccbb"></a>
## Andrew / user · C109-M00334

C109-M00334 · 2026-08-26T19:52:44.306000-04:00 · active path

Preceding visible parent: [C109-M00333](part-12.md#m-e82976c6-3ab9-4982-a685-19e95154981c)

<!-- BEGIN_SOURCE_MESSAGE -->
if I want to change the merchant slicer to allow the user to type the merchant number in - how could I do that. scrolling is not very feasible, especially once we expand beyond 750
<!-- END_SOURCE_MESSAGE -->


<a id="m-d7151149-2c03-4327-af20-ee53d345bd5b"></a>
## Assistant · C109-M00335

C109-M00335 · 2026-08-26T19:52:47.051409-04:00 · active path

Preceding visible parent: [C109-M00334](part-12.md#m-34c1c8ea-0319-4d07-ad0a-c8522888ccbb)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. For P03, scrolling through 750+ merchants is not viable. **Use the slicer's built-in Search** rather than changing the model.

With the existing Merchant dropdown selected:

1. Select the **Merchant slicer**.
2. Go to **Format visual → Slicer settings → Options**.
3. Make sure the slicer style is **Dropdown**.
4. Turn **Search = On**. Depending on your Desktop version, Search may instead be available from the slicer's `...` menu.
5. Open the slicer dropdown. You should now have a search box at the top.
6. Type `000749` and Power BI should narrow the list to `Synthetic Merchant 000749`.
7. Select it.

That immediately solves the scalability problem without another measure or calculated column.

### But I think we can improve it further

The slicer currently forces the user to know that the displayed values begin with `Synthetic Merchant`. Search will still find `000749`, but the visible selector is unnecessarily verbose.

I recommend creating a **merchant presentation column** on `DimMerchant`, analogous to our application label:

```DAX
P03 Merchant Label =
VAR _Merchant = 'DimMerchant'[synthetic_business_name]
VAR _Marker = SEARCH ( "M", 'DimMerchant'[MerchantKey], 1, 0 )
RETURN
    RIGHT ( _Merchant, 6 )
```

Actually, since `synthetic_business_name` is consistently displayed as `Synthetic Merchant 000749`, we don't need to involve the technical key at all:

```DAX
P03 Merchant Label =
VAR _Merchant = 'DimMerchant'[synthetic_business_name]
RETURN
    IF (
        ISBLANK ( _Merchant ),
        BLANK (),
        RIGHT ( _Merchant, 6 )
    )
```

Then use **`P03 Merchant Label`** as the slicer field.

The top control becomes:

> **Merchant**  
> `000749 ▼`

and when opened, the user can type:

> `749`

or

> `000749`

to find it immediately.

That is what I recommend for the final P03 design. We already say **Merchant** above the control, so repeating “Synthetic Merchant” 750+ times adds no information.

One caution: keep the original `synthetic_business_name` untouched. `P03 Merchant Label` is only a report presentation column. That preserves the governed identity while giving the user a much better selector.

**I would make this change now.** P03 is specifically intended to become the merchant-level navigation destination, so merchant lookup needs to work efficiently before we build the rest of the page.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c8c70bb5-f6a9-4859-8259-2e7a3be34c70"></a>
## Andrew / user · C109-M00336

C109-M00336 · 2026-08-26T19:58:39.216000-04:00 · active path

Preceding visible parent: [C109-M00335](part-12.md#m-d7151149-2c03-4327-af20-ee53d345bd5b)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: d8aec274-ea1a-43b9-a4de-6d2422e3b3aa.png

<!-- BEGIN_SOURCE_MESSAGE -->
we did create this measure before for the card , but perhaps we should have just created a column instead?
<!-- END_SOURCE_MESSAGE -->
