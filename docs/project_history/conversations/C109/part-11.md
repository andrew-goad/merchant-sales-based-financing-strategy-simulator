# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 11 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-10.md)
[Next part](part-12.md)

<a id="m-47585754-fd25-45e0-9573-4d61681e5acf"></a>
## Assistant · C109-M00277

C109-M00277 · 2026-08-26T16:28:23.701105-04:00 · active path

Preceding visible parent: [C109-M00276](part-10.md#m-f8be9d63-c3d3-468f-89c5-6503aa40775c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. We can pick up from here, and I would make **one small correction to the slicers first**.

Your first slicer is clearly the merchant selector, but its visible title currently says **Scenario**. Your second slicer shows `ScenarioLabel`. Rename the displayed slicer titles so the top row reads:

**Merchant | Scenario | Observation date**

That is the only change I would make to the header right now. The overall title/subtitle are good.

## Step 1 — Build the Merchant Profile block

Create a **New card** visual beneath the title area, on the left side of the page.

For the first pass, add these measures in this order:

```text
P03 Merchant Name
P03 Industry
P03 Merchant Size Tier
P03 Annual Sales Band
P03 Relationship Stage
P03 Relationship Quality
P03 Prior Advance Count
P03 Prior Funded Amount
```

Do not add more yet.

### Rename the displayed labels

In the card, use these user-facing labels:

```text
Merchant
Industry
Size tier
Annual sales
Relationship stage
Relationship quality
Prior advances
Prior funded
```

We want executive language, not semantic-model field names.

### Format the card

Start with:

- **Title:** `Merchant profile`
- **Visual background:** Off / white
- **Border:** Off
- **Category labels:** On
- **Values:** On
- **Callout/value font:** approximately the same hierarchy as the P01/P02 cards
- **Grid:** 2 columns if the New Card visual allows it cleanly
- **Padding:** modest; don't make every field its own giant tile

Conceptually:

```text
Merchant profile

Merchant                  Industry
Synthetic Merchant 000001 Construction & Skilled Trades

Size tier                 Annual sales
Mid-Market                $5M–$10M

Relationship stage        Relationship quality
Existing                  Strong

Prior advances            Prior funded
2                         $37K
```

The exact values will obviously depend on the selected merchant.

### Important design point

`P03 Merchant Name` may feel slightly redundant because the Merchant slicer already displays the selected business. **Keep it for this first physical pass.** Once we see the page, we can decide whether the merchant name belongs inside the profile or should become a stronger merchant-header element.

---

# Step 2 — Test the Merchant Profile before building anything else

Once the card is populated:

1. Select `Synthetic Merchant 000001`.
2. Note the profile values.
3. Change to 2–3 other merchants.
4. Confirm all eight values change appropriately.
5. Change Scenario from Baseline to Recession Energy.

For the profile attributes such as Industry, Size and Relationship Stage, I expect most to remain unchanged because they are merchant characteristics.

That is desirable.

If something unexpectedly blanks or changes under Scenario, tell me before we continue because that would reveal a context issue worth understanding.

---

# Step 3 — Create a second block: Acquisition & application

Once the profile works, move right of the profile and add a section heading:

**Acquisition & application**

For this section, we should **not yet create measures blindly**. First let's see which application fields behave naturally for the selected merchant.

The high-level story we want is:

> How did this merchant come to us, what did they ask for, and when?

The physical model gives us fields such as:

```text
application_date
requested_funding_amount
requested_remittance_rate
requested_expected_payoff_days
requested_use_of_proceeds
application_channel
application_status
primary_source_code
accepted_channel_type
attribution_confidence_tier
```

But a merchant may have more than one application, which means a Card could become misleading.

So for this section I recommend a **Table visual first**, not a Card.

### Add a Table visual

Use these raw columns as rows/columns in a standard Table visual:

```text
DimApplication[application_date]
DimApplication[application_status]
DimApplication[requested_funding_amount]
DimApplication[application_channel]
DimApplication[primary_source_code]
```

If Power BI gives you the same implicit-measure error for numeric columns, don't fight it. Tell me which fields fail and we'll make explicit P03 measures only where appropriate.

The purpose of this first table is diagnostic as much as presentational:

> Does the selected merchant have one application or several?

That decision affects almost everything else on Merchant 360.

---

# Step 4 — What I expect after we inspect the application population

There are two possible architectures.

### If merchants generally have one application

Then we can make **Acquisition & application** a polished card containing:

- Application date
- Acquisition source
- Application channel
- Requested funding
- Requested remittance rate
- Requested payoff days
- Use of proceeds
- Status

### If merchants can have multiple applications

Then the better Merchant 360 architecture is:

> **Merchant profile → Application history table/timeline → select/drill into application**

That is actually more powerful because it turns Merchant 360 into a relationship-history view rather than pretending each merchant has only one financing event.

We need the physical data to tell us which is correct.

---

# Step 5 — Do not build the performance chart yet

I know the natural temptation is to immediately add another Exposure or Remittance chart.

Hold that for one checkpoint.

The critical question now is:

> **What is the actual merchant → application → advance cardinality in this model?**

Once we see that, we can decide whether P03 should show:

- lifetime merchant totals,
- selected-application/account performance,
- multiple advances simultaneously,
- or a merchant-level timeline with drillthrough.

That is exactly the kind of issue Audit now wants us to discover empirically rather than trying to predesign from a catalog. The operating model expressly permits us to build and UAT the coherent experience this way. [export reference: filecite | turn34file1 | L8-L21]

## So your immediate steps are

1. Rename the slicer titles to **Merchant | Scenario | Observation date**.
2. Create the **Merchant profile** New Card with the eight `P03` measures above.
3. Test it across several merchants and both scenarios.
4. Add a temporary **Acquisition & application** Table with the five application fields above.
5. Send me a screenshot of the full page and, ideally, show me a merchant that has multiple application rows if one exists.

At that point we'll know how to structure the center of Merchant Relationship 360 instead of guessing.
<!-- END_SOURCE_MESSAGE -->


<a id="m-75657ca9-7b24-4a9a-ab98-a7dd2bb7bbb0"></a>
## Andrew / user · C109-M00278

C109-M00278 · 2026-08-26T16:35:10.870000-04:00 · active path

Preceding visible parent: [C109-M00277](part-11.md#m-47585754-fd25-45e0-9573-4d61681e5acf)

<!-- BEGIN_SOURCE_MESSAGE -->
The P03 Merchant Name - All the merchants in my data begin with the same Synthetic_Merchant ... I think we should parse just the number suffix for this card.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8308714a-4536-476a-9c65-10f8d365dd24"></a>
## Assistant · C109-M00279

C109-M00279 · 2026-08-26T16:35:17.462280-04:00 · active path

Preceding visible parent: [C109-M00278](part-11.md#m-75657ca9-7b24-4a9a-ab98-a7dd2bb7bbb0)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. On the card, repeating `Synthetic Merchant` adds no information. Since the prefix is common to every row, the executive-facing display should show just the merchant identifier suffix.

I would **modify the existing `P03 Merchant Name` measure** rather than create another one. That keeps the adapter layer cleaner.

If the stored value is consistently something like:

```text
Synthetic Merchant 000001
```

use:

```DAX
P03 Merchant Name =
VAR _Merchant =
    SELECTEDVALUE (
        'DimMerchant'[synthetic_business_name]
    )
RETURN
    IF (
        ISBLANK ( _Merchant ),
        "SELECT ONE MERCHANT",
        TRIM (
            SUBSTITUTE (
                _Merchant,
                "Synthetic Merchant",
                ""
            )
        )
    )
```

That would display:

```text
000001
```

If your actual physical values instead contain underscores, such as:

```text
Synthetic_Merchant_000001
```

then use:

```DAX
P03 Merchant Name =
VAR _Merchant =
    SELECTEDVALUE (
        'DimMerchant'[synthetic_business_name]
    )
RETURN
    IF (
        ISBLANK ( _Merchant ),
        "SELECT ONE MERCHANT",
        TRIM (
            SUBSTITUTE (
                _Merchant,
                "Synthetic_Merchant_",
                ""
            )
        )
    )
```

I would then change the card label from **Merchant** to:

**Merchant ID**

That makes the display semantically cleaner:

> Merchant ID  
> **000001**

while the slicer can still retain the full synthetic business name if that helps identification.

This is exactly the kind of report-owned presentation cleanup Audit has authorized: it preserves the accepted source value and only changes how it is displayed. [export reference: filecite | turn34file1 | L42-L50]
<!-- END_SOURCE_MESSAGE -->


<a id="m-717be45b-8b38-44ff-b780-dff425231269"></a>
## Andrew / user · C109-M00280

C109-M00280 · 2026-08-26T16:46:31.175000-04:00 · active path

Preceding visible parent: [C109-M00279](part-11.md#m-8308714a-4536-476a-9c65-10f8d365dd24)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: fb42e2a7-7187-4176-a184-b1e2f81005f0.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-db988874-1713-4b7b-838c-d79401819e54"></a>
## Assistant · C109-M00281

C109-M00281 · 2026-08-26T16:46:57.788910-04:00 · active path

Preceding visible parent: [C109-M00280](part-11.md#m-717be45b-8b38-44ff-b780-dff425231269)

<!-- BEGIN_SOURCE_MESSAGE -->
This first pass is useful. The card is working, but it has exposed **two things we should fix before building further**.

First, **Industry = NOT AVAILABLE is a filter-direction issue, not missing data.** The accepted relationship is `DimIndustry[industry_code] → DimMerchant[industry_code]`, so filtering one merchant does not propagate backward from `DimMerchant` into `DimIndustry`. The relationship itself is valid and intentionally single-direction. [export reference: filecite | turn35file9 | L671-L695]

Replace `P03 Industry` with this report-owned adapter:

```DAX
P03 Industry =
VAR _IndustryCode =
    SELECTEDVALUE ( 'DimMerchant'[industry_code] )
RETURN
    IF (
        ISBLANK ( _IndustryCode ),
        "NOT AVAILABLE",
        CALCULATE (
            SELECTEDVALUE ( 'DimIndustry'[industry_name] ),
            TREATAS (
                { _IndustryCode },
                'DimIndustry'[industry_code]
            )
        )
    )
```

That uses the selected merchant's accepted `industry_code` to retrieve the matching dimension label; it does **not** alter the relationship or model semantics. The model explicitly validates `DimMerchant[industry_code]` against `DimIndustry[industry_code]` with no orphan logic in that relationship. [export reference: filecite | turn35file1 | L40-L66]

Second, the card is showing **semantic codes rather than executive labels**:

- `LOWER_MIDDLE`
- `1M_TO_5M`
- `NEW`
- `2.00`
- `0.00`

Those are truthful, but we can make them much more polished.

For `P03 Merchant Size Tier`, use:

```DAX
P03 Merchant Size Tier =
VAR _Value =
    SELECTEDVALUE ( 'DimMerchant'[merchant_size_tier] )
RETURN
    SWITCH (
        _Value,
        "LOWER_MIDDLE", "Lower middle",
        "UPPER_MIDDLE", "Upper middle",
        "SMALL", "Small",
        "LARGE", "Large",
        IF (
            ISBLANK ( _Value ),
            "NOT AVAILABLE",
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

For `P03 Annual Sales Band`, I would translate the code rather than show `1M_TO_5M`:

```DAX
P03 Annual Sales Band =
VAR _Value =
    SELECTEDVALUE ( 'DimMerchant'[annual_sales_band] )
RETURN
    SWITCH (
        _Value,
        "UNDER_1M", "< $1M",
        "1M_TO_5M", "$1M–$5M",
        "5M_TO_10M", "$5M–$10M",
        "10M_TO_25M", "$10M–$25M",
        "25M_PLUS", "$25M+",
        IF (
            ISBLANK ( _Value ),
            "NOT AVAILABLE",
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

For `P03 Relationship Stage`:

```DAX
P03 Relationship Stage =
VAR _Value =
    SELECTEDVALUE ( 'DimMerchant'[relationship_stage] )
RETURN
    IF (
        ISBLANK ( _Value ),
        "NOT AVAILABLE",
        SWITCH (
            _Value,
            "NEW", "New",
            "EXISTING", "Existing",
            "RETURNING", "Returning",
            SUBSTITUTE ( _Value, "_", " " )
        )
    )
```

The more interesting one is **Relationship quality = `2.00`**. That strongly suggests `relationship_quality_tier` may not actually be a descriptive text tier in this physical source; it may be numerically encoded. I would **not invent “Good,” “Strong,” etc.** until we inspect the actual allowed values/meaning. For the moment, rename the card label:

**Relationship quality score**

and format it as:

```text
2.0
```

rather than `2.00`.

For Prior funded, format the existing measure as currency with no unnecessary decimals:

```text
$0
```

instead of `0.00`.

Similarly:

**Prior advances:** `0`

### One design change I recommend now

Change the visible first label from:

**Merchant**

to:

**Merchant ID**

because `000001` is an identifier, not a merchant name. That will read much more naturally.

So this card becomes approximately:

```text
Merchant ID
000001

Industry
Construction & Skilled Trades

Size tier
Lower middle

Annual sales
$1M–$5M

Relationship stage
New

Relationship quality score
2.0

Prior advances
0

Prior funded
$0
```

That is already a credible relationship profile.

### Then resume construction

Once those display corrections are made, **do not add more profile fields yet**. Next, create the temporary **Acquisition & application** table to establish the real merchant→application cardinality.

Use these columns:

```text
DimApplication[application_date]
DimApplication[application_status]
DimApplication[requested_funding_amount]
DimApplication[application_channel]
DimApplication[primary_source_code]
```

A standard **Table** visual should permit raw columns because it is not trying to collapse them to one scalar Card value. If Power BI objects to any specific numeric column because of the model setting, tell me exactly which one rather than creating measures preemptively.

Then switch among several merchants and answer one question:

> **Does a selected merchant ever produce more than one application row?**

That will determine whether the center of Merchant Relationship 360 should be a polished one-application summary or an actual application-history/timeline experience.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e61cb04a-ab15-4de8-969a-55ca077bdf35"></a>
## Andrew / user · C109-M00282

C109-M00282 · 2026-08-26T16:55:36.070000-04:00 · active path

Preceding visible parent: [C109-M00281](part-11.md#m-db988874-1713-4b7b-838c-d79401819e54)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 48bce55b-e0f8-49fa-9d5c-d159055620f2.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3422c5d4-21c1-4b4f-a203-0e8aa4de05e2"></a>
## Assistant · C109-M00283

C109-M00283 · 2026-08-26T16:55:43.666042-04:00 · active path

Preceding visible parent: [C109-M00282](part-11.md#m-e61cb04a-ab15-4de8-969a-55ca077bdf35)

<!-- BEGIN_SOURCE_MESSAGE -->
That answers the question. **`relationship_quality_tier` is not a text tier at all—it is an ordinal numeric classification with values 1 through 5.** So we should correct our presentation rather than treating `2.00` as a formatting anomaly.

I recommend displaying it as:

**Relationship quality**  
**Tier 2**

rather than inventing qualitative meanings such as “Good” or “Strong.” The physical data proves the 1–5 scale, but this screenshot alone does not establish what each tier semantically means.

Update the existing measure to:

```DAX
P03 Relationship Quality =
VAR _Tier =
    SELECTEDVALUE ( 'DimMerchant'[relationship_quality_tier] )
RETURN
    IF (
        ISBLANK ( _Tier ),
        "NOT AVAILABLE",
        "Tier " & FORMAT ( _Tier, "0" )
    )
```

That will give us:

> Relationship quality  
> **Tier 2**

which is accurate and polished.

I also notice something useful in your Data view: for the merchants shown, `prior_advance_count`, `total_prior_funded_amount`, and `total_prior_repaid_amount` are all zero, while `merchant_services_relationship_flag` is frequently `True` and `wallet_share_proxy` varies. So **relationship history here is broader than prior financing history**. That's useful for Merchant 360: later we may want the profile to distinguish existing banking/merchant-services relationship from prior-advance experience rather than implying “new” means entirely new to the institution.

For now, make the Relationship Quality measure change above, plus the other display cleanups from my prior response. Then proceed to the temporary **Acquisition & application** table. That table is the next important empirical test because the accepted relationship is explicitly `DimMerchant[MerchantKey] → DimApplication[MerchantKey]`, and we need to see whether our physical merchant population actually contains multiple applications per merchant. [export reference: filecite | turn35file1 | L97-L123]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e3714ee5-72fe-4699-b893-87f8b17b2ed1"></a>
## Andrew / user · C109-M00284

C109-M00284 · 2026-08-26T16:57:50.990000-04:00 · active path

Preceding visible parent: [C109-M00283](part-11.md#m-3422c5d4-21c1-4b4f-a203-0e8aa4de05e2)

**Editorial record note:** Attachment references: Pasted text(20260826-205740).txt

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-d21fda05-8504-4a9c-8ad5-a84031cbcbdd"></a>
## Assistant · C109-M00285

C109-M00285 · 2026-08-26T16:57:54.215447-04:00 · active path

Preceding visible parent: [C109-M00284](part-11.md#m-e3714ee5-72fe-4699-b893-87f8b17b2ed1)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — the full `DimMerchant` extract materially improves our interpretation, and it corrects one important point from my prior response.

`relationship_quality_tier` is clearly an **ordinal risk/relationship-quality classification where lower appears better**, not merely an unexplained 1–5 label. The evidence is strong: Tier 1 merchants are overwhelmingly `RETURNING_GOOD`, with high wallet-share proxies and clean prior histories, while Tier 5 merchants shown have prior defaults/payment interruptions and incomplete repayment histories. For example, Merchant 000221 is Tier 5 with both prior-default and prior-payment-interruption flags, whereas the later Tier 1 population is dominated by `RETURNING_GOOD` relationships. [export reference: filecite | turn36file0 | L506-L506] [export reference: filecite | turn36file0 | L634-L651]

However, I **still would not invent labels** such as Excellent/Good/Fair/Poor unless the governed documentation defines them. So keep the safe presentation:

```DAX
P03 Relationship Quality =
VAR _Tier =
    SELECTEDVALUE ( 'DimMerchant'[relationship_quality_tier] )
RETURN
    IF (
        ISBLANK ( _Tier ),
        "NOT AVAILABLE",
        "Tier " & FORMAT ( _Tier, "0" )
    )
```

### More importantly: our Merchant 360 test merchant should change

Merchant **000001 is a poor construction/UAT merchant**. It is `NEW`, has zero prior advances, zero prior funded/repaid amount, no deposit relationship, and Tier 2. [export reference: filecite | turn36file0 | L289-L289] That explains why the first profile looked rather uninteresting.

For P03 construction, I recommend we deliberately use a merchant with a **rich relationship history** while we build. A particularly useful candidate is **Merchant 000012**:

- Relationship stage = `RETURNING_MIXED`
- Prior advances = **4**
- Completed advances = **3**
- Prior default = No
- Prior payment interruption = **Yes**
- Prior funded = **$138,403.13**
- Prior repaid = **$133,405.17**
- Merchant-services relationship = Yes
- Wallet share proxy = 0.434448
- Relationship quality = **Tier 4** [export reference: filecite | turn36file0 | L483-L483]

That is much better for discovering whether Merchant Relationship 360 actually tells the story we intend. Later we'll UAT merchants from several archetypes, including clean returning, troubled returning, and genuinely new relationships.

Also, the extract confirms why the page should eventually distinguish **relationship profile** from **financing history**. There are merchants classified `RETURNING_GOOD` even where the current extract shows zero prior advances, so `relationship_stage` plainly should not be interpreted as synonymous with “prior MSBF financing.” [export reference: filecite | turn36file0 | L285-L288]

## Next construction step

Do **not** spend more time polishing the left card yet.

1. Change the Merchant slicer temporarily to **Synthetic Merchant 000012**.
2. Confirm the profile changes to Tier 4, 4 prior advances, and approximately $138.4K prior funded.
3. Leave the profile card in place.
4. Create a **temporary Table visual** in the large open body of P03.
5. Title it temporarily **Acquisition & application — physical model test**.
6. From `DimApplication`, add the raw fields that identify the application and its chronology/status. Start with:
   - `application_id` or equivalent application identifier
   - `application_date` / submitted date
   - application status
   - requested amount
   - acquisition source
   - decision/final outcome, **if those fields actually reside in `DimApplication`**

Don't create new measures for these yet.

What I want to establish empirically is:

> **When Merchant 000012 is selected, how many application records does Power BI physically return, and what fields are actually populated?**

Once you show me that temporary table, we'll know whether P03 should present the acquisition/application portion as a **single current application**, a **multi-application history**, or something richer. That is exactly the build-first approach Audit has now authorized. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-98efc9a4-cbb7-4ffe-bf73-f55fef38da42"></a>
## Andrew / user · C109-M00286

C109-M00286 · 2026-08-26T17:02:14.739000-04:00 · active path

Preceding visible parent: [C109-M00285](part-11.md#m-d21fda05-8504-4a9c-8ad5-a84031cbcbdd)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 7066c2bc-eea4-4ad5-b661-1e3c700d2a7a.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-8e2417a6-9ecd-4e3e-9ab0-4963390c562b"></a>
## Assistant · C109-M00287

C109-M00287 · 2026-08-26T17:02:17.609384-04:00 · active path

Preceding visible parent: [C109-M00286](part-11.md#m-98efc9a4-cbb7-4ffe-bf73-f55fef38da42)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. This is exactly the profile behavior we wanted to confirm.

The card now resolves Merchant **000012** correctly and gives us a substantially richer test case: Restaurant & Food Service, Small, $250K–$1M annual sales, Returning Mixed, Tier 4, four prior advances, and $138.40K prior funded. Those displayed values reconcile to the underlying merchant record. [export reference: filecite | turn36file0 | L483-L483]

I would **freeze this card structurally for now**. We can improve formatting later; there is no reason to burn time polishing it while we're still discovering what P03 can physically support.

### Next: build the temporary application-history diagnostic

In the large blank area immediately to the right of this profile:

1. Add a **Table** visual.
2. Give it plenty of width—we are diagnosing the model, not designing the finished visual yet.
3. Leave Merchant = **000012** selected.
4. Expand **`DimApplication`** in the Data pane.
5. Tell me—or screenshot—the fields available in `DimApplication`.

**Don't guess which fields to add yet.** My previous list was conceptual. Now that we're physically inside the model, I want to use its actual field names and grain rather than manufacture a mapping in advance.

Once I see `DimApplication`, I'll tell you exactly which fields to drag into the table and in what order. Then we'll answer the first important P03 modeling question:

**Does selecting Merchant 000012 propagate cleanly into its complete application history, and what does that history actually contain?**

That will determine the next section of Merchant Relationship 360.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c3d3131b-3c50-401e-ba78-54e888226a1f"></a>
## Andrew / user · C109-M00288

C109-M00288 · 2026-08-26T17:02:54.216000-04:00 · active path

Preceding visible parent: [C109-M00287](part-11.md#m-8e2417a6-9ecd-4e3e-9ab0-4963390c562b)

**Editorial record note:** Attachment references: Pasted text(20260826-210249).txt

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-22dccd33-aad2-4a1b-97ef-46fb07b0e9cd"></a>
## Assistant · C109-M00289

C109-M00289 · 2026-08-26T17:03:23.428389-04:00 · active path

Preceding visible parent: [C109-M00288](part-11.md#m-c3d3131b-3c50-401e-ba78-54e888226a1f)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — this is enough. You exported the actual `DimApplication` population, and it answers the field question cleanly. The table has the application grain and includes the requested economics, use of proceeds, channel, attribution, and evidence-status fields we need. [export reference: filecite | turn37file0 | L1-L8]

For **Merchant 000012**, I also located its application in the supplied data. It has one `A01` application in this population: **7/23/2026, $13,100 requested, 13.9062% requested remittance rate, 60 expected payoff days, $16,635.79 requested total repayment, $3,535.79 finance charge, Working Capital, Processor Embedded, Submitted, sourced through the processor portal.** Its attribution confidence is Medium / Partial at 0.75.

### Next step — build the Application History table

Keep Merchant **000012** selected. In your existing temporary Table visual, add these `DimApplication` fields **in this exact order**:

1. `application_date`
2. `requested_funding_amount`
3. `requested_use_of_proceeds`
4. `application_channel`
5. `requested_remittance_rate`
6. `requested_expected_payoff_days`
7. `requested_total_repayment_amount`
8. `requested_finance_charge_amount`
9. `application_status`
10. `primary_source_code`

For now, **do not add** the IDs, hashes, keys, attribution-method fields, or evidence-status fields. They're useful for governance/reconciliation, but they'll overwhelm the merchant story.

### What I expect to happen

With Merchant **000012** selected, the table should collapse to **one application row**. That row should approximately show:

**7/23/2026 | $13.10K | WORKING_CAPITAL | PROCESSOR_EMBEDDED | 13.91% | 60 | $16.64K | $3.54K | SUBMITTED | SRC_PROC_PORTAL**

This is an important physical-model test. The supplied source shows `MerchantKey = 1|MSBF_POP_0001_M000012`, so if the merchant slicer propagates correctly through the model, that one application should be isolated automatically.

**Stop there once those 10 fields are in the table.** Send me a screenshot of what Power BI renders. I want to inspect whether the Merchant filter propagation works and whether any fields aggregate incorrectly before we turn this diagnostic into the polished **Application & Acquisition History** section of Merchant Relationship 360. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-98715005-2134-4f1c-b1a8-45a0cc61ffd9"></a>
## Andrew / user · C109-M00290

C109-M00290 · 2026-08-26T17:04:37.673000-04:00 · active path

Preceding visible parent: [C109-M00289](part-11.md#m-22dccd33-aad2-4a1b-97ef-46fb07b0e9cd)

<!-- BEGIN_SOURCE_MESSAGE -->
sorry, explain this. are we moving on from the card and now creating a table? Keep Merchant **000012** selected. In your existing temporary Table visual, add these `DimApplication` fields **in this exact order**:  
<!-- END_SOURCE_MESSAGE -->


<a id="m-1eeca347-3ee2-4dc6-8c10-45db90a87836"></a>
## Assistant · C109-M00291

C109-M00291 · 2026-08-26T17:04:40.690737-04:00 · active path

Preceding visible parent: [C109-M00290](part-11.md#m-98715005-2134-4f1c-b1a8-45a0cc61ffd9)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **The merchant-profile card is complete for now.** We are moving to the **next visual on P03**, which will be a table showing that merchant's application history.

My wording about an "**existing temporary Table visual**" was confusing. You do **not** need to have already created one. I meant that our next construction step is to create one.

### Where we are on P03

You have completed the top-level controls and the left-side **Merchant Profile** card:

- Merchant
- Industry
- Size tier
- Annual sales
- Relationship stage
- Relationship quality
- Prior advances
- Prior funded

That card answers: **"Who is this merchant, and what relationship did we have with them coming into the current funding journey?"**

Now we start telling the actual **360° history**.

### Next visual: Application History

Yes — create a **Table** visual.

For the first pass, this is deliberately a physical-model diagnostic as well as a useful report component. We want to see whether selecting Merchant `000012` correctly retrieves that merchant's application records before spending time making the visual beautiful.

With Merchant **000012 still selected**:

1. Click a blank area of the canvas.
2. In **Visualizations**, select **Table**.
3. Resize it to give us reasonable working room.
4. Add these fields from `DimApplication`, in this order:

   `application_date`  
   `requested_funding_amount`  
   `requested_use_of_proceeds`  
   `application_channel`  
   `requested_remittance_rate`  
   `requested_expected_payoff_days`  
   `requested_total_repayment_amount`  
   `requested_finance_charge_amount`  
   `application_status`  
   `primary_source_code`

Don't worry about formatting, column names, widths, capitalization, or making it executive-ready yet.

The source data confirms that `DimApplication` contains precisely this application-level information and a `MerchantKey`, which is why this is the right next physical test. [export reference: filecite | turn37file0 | L1-L8]

Once you add those fields, **stop and show me the result**. I specifically want to inspect the row population and filtering behavior before we decide what the polished application-history visual should look like.

So, in short: **yes, card finished → now table.** [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-0e7fa5e8-1290-4f3f-91d7-fa61a6ab1435"></a>
## Andrew / user · C109-M00292

C109-M00292 · 2026-08-26T17:05:06.648000-04:00 · active path

Preceding visible parent: [C109-M00291](part-11.md#m-1eeca347-3ee2-4dc6-8c10-45db90a87836)

<!-- BEGIN_SOURCE_MESSAGE -->
and why is it temporary? is it not going to be part of the final build?
<!-- END_SOURCE_MESSAGE -->


<a id="m-9fac82a0-904e-491f-a59f-fd4c9b6073bd"></a>
## Assistant · C109-M00293

C109-M00293 · 2026-08-26T17:05:09.329224-04:00 · active path

Preceding visible parent: [C109-M00292](part-11.md#m-0e7fa5e8-1290-4f3f-91d7-fa61a6ab1435)

<!-- BEGIN_SOURCE_MESSAGE -->
Potentially yes — and I should not have called it “temporary” without explaining the distinction.

The **Application History concept is intended to be part of the final P03 build**. What is temporary is only its **first physical form**: a wide, minimally formatted table containing enough fields to let us understand how the merchant→application relationship behaves.

Why start this way? Because before deciding whether the final experience should be a table, timeline, compact history strip, or application selector/detail combination, we need to see the actual data behavior. In particular, we need to learn whether merchants commonly have one application or multiple applications, how much variation exists across those applications, and which fields are genuinely useful together.

So the workflow is:

**Merchant Profile** → essentially accepted as a final component, subject to later visual polish.

**Application History** → definitely part of the P03 story, but we first construct it as a plain table to understand the physical data.

Then, based on what we see, we might decide:

- **Keep the table** and polish it if merchants commonly have multiple applications and the rows tell the story well.
- Turn it into a **compact application timeline/history** if chronology is more important.
- Use an **application selector + detail panel** if merchants have many applications and each carries substantial information.
- Replace the wide diagnostic table with a smaller executive visual if most merchants only have one relevant application.

This is precisely where the new build-first operating model helps us. We don't need to decide the final native visual before seeing the data behave in Power BI.

So yes: **we are building a real final section called something like `Application history` or `Acquisition & applications`. We just aren't committing yet to a Table as its final presentation.**

And I would change one thing from my previous instruction: don't worry about carefully sizing or positioning this table on the final canvas yet. Give it enough room to inspect the records. Once we understand what Merchant 000012—and several other merchants—produce, we'll design that section properly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-30080ec1-0e20-46fd-8737-23ae6128dff9"></a>
## Andrew / user · C109-M00294

C109-M00294 · 2026-08-26T18:05:08.678000-04:00 · active path

Preceding visible parent: [C109-M00293](part-11.md#m-9fac82a0-904e-491f-a59f-fd4c9b6073bd)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 593360ac-500f-4bf0-943b-5562d30fdede.png

<!-- BEGIN_SOURCE_MESSAGE -->
i split into two tables so they screen would show all details at once and i added merchant_application_id for now
<!-- END_SOURCE_MESSAGE -->


<a id="m-4c14816b-ca75-4fdf-b75d-7588763c9784"></a>
## Assistant · C109-M00295

C109-M00295 · 2026-08-26T18:05:11.805615-04:00 · active path

Preceding visible parent: [C109-M00294](part-11.md#m-30080ec1-0e20-46fd-8737-23ae6128dff9)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes—this was a good way to inspect it. And adding `merchant_application_id` was useful because it confirms the grain unequivocally.

For Merchant **000012**, we now physically see one application:

- `MSBF_POP_0001_M000012_A01`
- Application date: **7/23/2026**
- Requested funding: **$13,100**
- Use: **Working Capital**
- Channel: **Processor Embedded**
- Requested remittance rate: **14%**
- Expected payoff: **60 days**
- Requested repayment: **$16,635.79**
- Finance charge: **$3,535.79**
- Status: **Submitted**
- Source: `SRC_PROC_PORTAL`

That tells us the filtering works and gives us the next important design insight.

### Before designing the final section, test cardinality

Don't format these two tables yet. Keep them exactly as diagnostic tables and use the **Merchant slicer** to click through perhaps 10–15 merchants, especially merchants with prior advances.

Watch only the `merchant_application_id` column and answer:

> **Do any selected merchants produce more than one row/application?**

You don't need to document every merchant. We're simply looking for evidence of `A02`, `A03`, etc.

Why this matters is significant. `000012` has **4 prior advances**, but the current application table shows only `A01`. That suggests the “prior advances” in `DimMerchant` may represent **relationship history entering this modeled run**, while `DimApplication` may contain only the applications generated within the current synthetic population/run. If so, we should **not call this section “Application History”**, because that would imply the model contains historical applications corresponding to those four prior advances when it may not.

Instead, the P03 story becomes more precise:

**Prior relationship** → summarized from `DimMerchant`

**Current application** → `DimApplication`

**Current decision / offer** → `FactFinalDecision`

**Current funded advance** → `DimAccountAdvance`

**Current performance and servicing** → account facts

That would actually make Merchant Relationship 360 better: it separates **pre-existing relationship history** from the **current financing journey** rather than blending them.

So leave your two tables as-is and click through several merchants. If they all return exactly one `_A01` row, tell me that. If you find an `_A02` or multiple rows, show me that merchant.

Then we'll know whether these two diagnostic tables have done their job and can replace them with the polished **Current application** section.
<!-- END_SOURCE_MESSAGE -->


<a id="m-890a840b-078f-4947-8892-63f6a79487e3"></a>
## Andrew / user · C109-M00296

C109-M00296 · 2026-08-26T18:05:57.722000-04:00 · active path

Preceding visible parent: [C109-M00295](part-11.md#m-4c14816b-ca75-4fdf-b75d-7588763c9784)

<!-- BEGIN_SOURCE_MESSAGE -->
you have all the merchant data. is there a good few merchants that you'd like me to test
<!-- END_SOURCE_MESSAGE -->


<a id="m-dcdfeaf9-bcf8-48a9-a651-b75053c08cf6"></a>
## Assistant · C109-M00297

C109-M00297 · 2026-08-26T18:06:14.943620-04:00 · active path

Preceding visible parent: [C109-M00296](part-11.md#m-890a840b-078f-4947-8892-63f6a79487e3)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Since we have the merchant population, we can be deliberate rather than randomly clicking 15 merchants.

For **this particular test**, though, I can simplify it even further: the accepted model documentation already tells us the relationship is **one merchant → potentially many applications**, but notes that multiple applications are anticipated for future campaigns. [export reference: filecite | turn38file12 | L726-L753] That makes it quite plausible that this current run has only one application per merchant. So we don't need an exhaustive hunt.

I'd test these **four archetypes**:

- **000012** — our `RETURNING_MIXED` case: 4 prior advances, Tier 4, meaningful prior funding. We already know it produces `_A01`.
- **000221** — deliberately adverse prior-history case: prior default + prior payment interruption and Tier 5. This tests whether a troubled relationship still produces the same current-run application grain.
- **000001** — genuinely `NEW`, no prior advances. This is our clean new-relationship control.
- **One `RETURNING_GOOD` / Tier 1 merchant** from the later population — use one of the merchants you see when filtering `relationship_stage = RETURNING_GOOD` and `relationship_quality_tier = 1`. This gives us the opposite end of the relationship spectrum.

For each, you only need to look at **`merchant_application_id`**. Don't inspect all ten columns.

We're testing whether you see:

```text
..._A01
```

only, or whether any merchant produces:

```text
..._A01
..._A02
```

etc.

If all four produce exactly one `_A01`, **stop testing**. I will treat the physical current-run contract as one application per merchant for this population, while preserving the model's future-capable 1:* merchant→application relationship.

That distinction is important for our final page language. The design authority already describes `[Merchant Applications]` simply as applications for the selected merchant and explicitly warns that the relationship evidence is bounded rather than a complete historical ledger. [export reference: filecite | turn38file0 | L17-L23]

So if these four all return one row, our P03 story should become:

**Relationship history**  
→ bounded prior relationship snapshot from `DimMerchant`

**Current application**  
→ this run's `DimApplication` record

**Current decision & offer**  
→ scenario-qualified decision facts

**Current advance**  
→ funded account/activation, where applicable

**Performance & servicing**  
→ lifecycle through the selected observation date

That is cleaner and more truthful than calling the current-run row an **Application History**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-967bc0dc-7d8e-4084-8cde-e55794dffe40"></a>
## Andrew / user · C109-M00298

C109-M00298 · 2026-08-26T18:09:24.862000-04:00 · active path

Preceding visible parent: [C109-M00297](part-11.md#m-dcdfeaf9-bcf8-48a9-a651-b75053c08cf6)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 96964b70-4d45-4815-bd30-f7d4c7a4b487.png; 098da978-8d99-41ad-890c-fc6953ac201a.png

<!-- BEGIN_SOURCE_MESSAGE -->
oddly, only the first table showed any data for these two
<!-- END_SOURCE_MESSAGE -->


<a id="m-8f41d0eb-dd71-4858-a3d2-dc7e52b7a7cb"></a>
## Assistant · C109-M00299

C109-M00299 · 2026-08-26T18:09:28.058454-04:00 · active path

Preceding visible parent: [C109-M00298](part-11.md#m-967bc0dc-7d8e-4084-8cde-e55794dffe40)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — and this is actually a useful discovery. **The second table going completely blank is not because those merchants lack the data.** For Merchant 000221, for example, the first table proves `DimApplication` has a matching application row, so other columns from that same row should not disappear merely because they're in a second Table visual.

The most likely cause is **visual interaction/filter state**, especially because we have been working with Edit Interactions. Notice that the second table is not merely showing blanks in some columns—it has **no row at all**. That points to the visual being filtered out rather than those fields being null.

### First diagnostic — very quick

For Merchant **000221**, select the **second table** and check the Filters pane:

**Filters on this visual**

Look for anything besides the fields that belong naturally to the table. In particular, see whether `merchant_application_id`, Scenario, or another field has acquired a visual-level selection/filter.

If you see anything unexpected, screenshot it.

### Then check interactions

This is the more likely culprit.

1. Click the **Merchant slicer**.
2. Go to **Format → Edit interactions**.
3. Look at the icons above the **second table**.
4. It should be set to **Filter** (the funnel), not **None**.
5. Do the same for the **Scenario slicer**.

Then turn Edit interactions back off.

Your screenshot actually shows interaction icons around the visuals, so we know interaction editing has been active during this construction. It's quite possible the two tables do not currently have identical interaction behavior.

### Easiest definitive test

If both of those look normal, don't spend 15 minutes debugging this diagnostic visual.

Take the **first table that works**, duplicate it with `Ctrl+C` / `Ctrl+V`, and then on the duplicate:

1. Remove:
   - `application_date`
   - `requested_funding_amount`
   - `requested_use_of_proceeds`
   - `application_channel`
   - `requested_remittance_rate`

2. Keep `merchant_application_id`.

3. Add:
   - `requested_expected_payoff_days`
   - `requested_total_repayment_amount`
   - `requested_finance_charge_amount`
   - `application_status`
   - `primary_source_code`

If that duplicate populates, we know the issue was simply some configuration/state on the original second visual.

### More importantly, we've already learned something

Both **000001** and **000221** return exactly one:

```text
..._A01
```

And 000012 did too.

So we now have three materially different merchant archetypes all behaving as:

**one selected merchant → one current-run application**

That aligns with the model documentation: the relationship is intentionally 1:* because **future campaigns may have multiple applications**, rather than because this particular current population necessarily contains multiple applications. [export reference: filecite | turn38file12 | L726-L753]

I don't think we need to keep hunting for 15 merchants.

Let's diagnose the second table using the steps above. Once it displays correctly, test **one Returning Good / Tier 1 merchant** as our final control. If that also returns one `_A01`, we're done with cardinality testing and can convert this diagnostic into the polished **Current application** section.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1557f28b-6882-4f9e-8325-e00f8dc53d30"></a>
## Andrew / user · C109-M00300

C109-M00300 · 2026-08-26T18:14:17.130000-04:00 · active path

Preceding visible parent: [C109-M00299](part-11.md#m-8f41d0eb-dd71-4858-a3d2-dc7e52b7a7cb)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 20950e4e-dba9-4458-90be-f69aca5748ef.png

<!-- BEGIN_SOURCE_MESSAGE -->
i followed that definitive test in creating it and we see it does show data for 12 (still does):
<!-- END_SOURCE_MESSAGE -->


<a id="m-ced62b48-4cbf-4f9e-a76b-a5187fc706f4"></a>
## Assistant · C109-M00301

C109-M00301 · 2026-08-26T18:14:20.340237-04:00 · active path

Preceding visible parent: [C109-M00300](part-11.md#m-1557f28b-6882-4f9e-8325-e00f8dc53d30)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. That tells us the **second-table construction itself is valid**. For Merchant 000012, both halves resolve to the same application ID and the complete application record is present.

The interesting part is now why the second table disappeared for 000001 and 000221. Given what we're seeing, I think there is a much simpler explanation than an interaction defect:

**one or more of the fields in Table 2 is blank for those applications, and Power BI's table is suppressing the row because the combination of displayed fields has no reportable values under the current context.**

But rather than speculate, we can identify the exact field in about a minute.

### Do this with Merchant 000221

Keep the **working duplicated second table**.

Switch Merchant to **000221**. If the row disappears, remove the Table 2 fields **one at a time**, starting from the right:

1. `primary_source_code`
2. `application_status`
3. `requested_finance_charge_amount`
4. `requested_total_repayment_amount`
5. `requested_expected_payoff_days`

Keep `merchant_application_id` throughout.

The moment the row reappears, tell me which field you just removed.

Then repeat only that check for 000001 if necessary.

### Why I want to resolve this

This isn't just debugging. It tells us something about the **evidence boundary of the current application**.

For example, if a merchant has:

```text
requested funding     $5,000
channel               BROKER_REFERRAL
```

but no requested repayment economics, that could be meaningful. It may indicate those terms exist only for certain application/decision paths. We shouldn't force them into a final Current Application card if they aren't universally applicable.

For 000012, we now know the complete requested structure exists:

```text
Requested amount       $13,100
Use                     Working capital
Channel                 Processor embedded
Requested remittance    14%
Expected payoff         60 days
Total repayment         $16,635.79
Finance charge          $3,535.79
Status                  Submitted
Source                   SRC_PROC_PORTAL
```

So **don't format these tables yet**. Switch to 000221 and remove those five fields one at a time until the application row returns. That will tell us exactly what we're dealing with.
<!-- END_SOURCE_MESSAGE -->


<a id="m-007faaf2-9878-41e6-9b1a-23a20069e59e"></a>
## Andrew / user · C109-M00302

C109-M00302 · 2026-08-26T18:20:25.944000-04:00 · active path

Preceding visible parent: [C109-M00301](part-11.md#m-ced62b48-4cbf-4f9e-a76b-a5187fc706f4)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 9ab1d2e2-1735-47f1-9a3c-ab282b2a1612.png; 38a1c33d-93eb-4042-ab84-623b21d45f1d.png; 0d3c90c8-09fb-4050-8218-f196b546ac9c.png

<!-- BEGIN_SOURCE_MESSAGE -->
sometimes you just have to delete and recreate. i deleted tables and now they are working. i wonder if the prior advances are data points used in evaluation but do not necessarily mean they have 4 advances in our current cohort and detail.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8d843fda-2c3a-47cc-99c1-27f3c25485fd"></a>
## Assistant · C109-M00303

C109-M00303 · 2026-08-26T18:20:29.162098-04:00 · active path

Preceding visible parent: [C109-M00302](part-11.md#m-007faaf2-9878-41e6-9b1a-23a20069e59e)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that is the correct interpretation, and the model documentation supports it.

`prior_advance_count`, `completed_advance_count`, `total_prior_funded_amount`, and `total_prior_repaid_amount` are **bounded prior-relationship attributes carried into `DimMerchant`**. They are not four account/advance records that we should expect to find in the current modeled cohort. The design authority explicitly describes current-run funded amount as being combined with an **“accepted prior funded amount snapshot”** and warns that this is bounded relationship evidence, **“not a complete historical ledger.”** Likewise, prior repayment is supplied as a snapshot; the individual prior remittance events are unavailable. [export reference: filecite | turn38file10 | L657-L662]

That resolves the apparent contradiction with Merchant 000012:

```text
Prior relationship entering this run
Prior advances       4
Prior funded         $138.4K
Prior repaid         $133.4K
Payment interruption Yes
Relationship tier    4

Current modeled run
Application          ...M000012_A01
Application date     7/23/2026
Requested amount     $13.1K
...
```

So **we should absolutely not try to find those four prior advances elsewhere in the current cohort.**

This also gives P03 a stronger conceptual architecture.

### The page should explicitly separate past relationship from current journey

The left-hand Merchant Profile should probably evolve into **Relationship profile**, because that's really what those attributes represent:

**Merchant profile**
Industry, size, annual sales

**Prior relationship**
Relationship stage, quality tier, prior advances, prior funded

Then everything to the right tells the **current financing journey**:

**Current application**  
→ **Decision & offer**  
→ **Funding / advance**  
→ **Performance through selected date**  
→ **Servicing / exceptions**

That's a genuine Merchant Relationship 360 rather than simply another account dashboard.

### And we're finished with the cardinality diagnostic

The recreated visuals prove that 000001, 000012 and 000221 all resolve cleanly to one `_A01` current-run application. We don't need to test more merchants just to establish this point. The model intentionally retains a 1:* Merchant→Application relationship because future campaigns may contain multiple applications, so we should preserve that future capability without pretending the current population contains historical application rows that aren't there. [export reference: filecite | turn38file12 | L726-L753]

Your observation about deleting/recreating the Power BI visuals is also useful: the prior blank table was clearly a **visual-state artifact**, not a data deficiency. We should not design around it.

## Next construction step: turn these diagnostics into `Current application`

Now we know what the data represents, so **the two diagnostic tables have served their purpose**.

Don't polish them. We're going to replace them with a much more compact **Current application** presentation.

I would retain these eight pieces of information:

```text
Application ID       A01
Applied              7/23/2026
Requested            $13.1K
Use of proceeds      Working capital

Channel              Processor embedded
Requested remittance 14.0%
Expected payoff      60 days
Requested repayment  $16.6K
```

I would **not** give valuable page real estate to:

- `application_status = SUBMITTED` — likely not especially informative once we're showing the subsequent decision/funding journey;
- `requested_finance_charge_amount` — derivable from requested amount/repayment and less important than the other terms;
- `primary_source_code = SRC_PROC_PORTAL` — technical code; acquisition/channel can be represented more meaningfully elsewhere;
- the full `MSBF_POP_0001_M000012_A01` string — executive clutter.

For Application ID, we can parse the suffix exactly as we did for Merchant ID and display simply:

**Application ID: A01**

### But there's one thing I want to inspect before we build that card

Now that we've established the **requested** terms, the natural next question is:

> **What actually happened to this application under the selected Scenario?**

That means our next physical source is **`FactFinalDecision`**, because the comparison between **Requested → Decision/Offer → Funded** is potentially the heart of this page.

So before creating another eight P03 display measures, let's inspect `FactFinalDecision` for Merchant 000012 / Application A01 under Baseline.

If the fields are as rich as the physical model suggested, we may discover that the better middle-of-page experience isn't separate “Application” and “Decision” cards at all. It may be a very effective **Request → Decision → Funding** progression showing how the merchant's ask became the actual financing structure.

That's the next thing I would build.
<!-- END_SOURCE_MESSAGE -->


<a id="m-861c11dc-dcb2-4888-84fc-f25c1c3a7a5a"></a>
## Andrew / user · C109-M00304

C109-M00304 · 2026-08-26T18:23:06.694000-04:00 · active path

Preceding visible parent: [C109-M00303](part-11.md#m-8d843fda-2c3a-47cc-99c1-27f3c25485fd)

<!-- BEGIN_SOURCE_MESSAGE -->
we should create a measure for application or try to understand the components of merchant_application_id better. it seems like there is a population component. in this case they are all population 0001 , then we have merchant id (12) and then comes the application id A01.
<!-- END_SOURCE_MESSAGE -->


<a id="m-47cc9c5c-e437-4c3d-9cb5-6d03e2a11c16"></a>
## Assistant · C109-M00305

C109-M00305 · 2026-08-26T18:23:27.923061-04:00 · active path

Preceding visible parent: [C109-M00304](part-11.md#m-861c11dc-dcb2-4888-84fc-f25c1c3a7a5a)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — your read of the identifier is correct, and the model documentation confirms the identity rule.

`merchant_application_id` is the **scenario-invariant application identifier**. The accepted semantic model defines:

```text
ApplicationKey = run_id | merchant_application_id
```

and explicitly says application identity is stable across scenarios. [export reference: filecite | turn39file0 | L9-L12]

For a value like:

```text
MSBF_POP_0001_M000012_A01
```

the components are effectively:

```text
MSBF_POP_0001   = population identifier
M000012         = merchant identifier within that population
A01             = application sequence / application identifier
```

The raw application extract reinforces that structure because it separately carries `population_id`, `merchant_id`, and `merchant_application_id`. [export reference: filecite | turn39file1 | L22-L27]

So I agree we should create a **clean P03 Application ID measure** and display only `A01` on the executive page.

Use:

```DAX
P03 Application ID =
VAR _Application =
    SELECTEDVALUE (
        'DimApplication'[merchant_application_id]
    )
VAR _LastUnderscore =
    SEARCH (
        "|",
        SUBSTITUTE ( _Application, "_", "|", LEN ( _Application ) - LEN ( SUBSTITUTE ( _Application, "_", "" ) ) ),
        1,
        0
    )
RETURN
    IF (
        ISBLANK ( _Application ),
        "NOT AVAILABLE",
        RIGHT (
            _Application,
            LEN ( _Application ) - _LastUnderscore
        )
    )
```

But because the identifier format appears governed and consistently ends in `_Axx`, we can make this much simpler and more readable:

```DAX
P03 Application ID =
VAR _Application =
    SELECTEDVALUE (
        'DimApplication'[merchant_application_id]
    )
RETURN
    IF (
        ISBLANK ( _Application ),
        "NOT AVAILABLE",
        RIGHT ( _Application, 3 )
    )
```

For the current population that yields:

```text
A01
```

I prefer the simpler version **only if we are comfortable that `A01`, `A02`, etc. are always fixed at three characters**. The model documentation proves application identity and the current data strongly supports that naming convention, but it does not explicitly state that future application sequences can never exceed `A99`.

So the safer presentation adapter is to extract everything after the final underscore:

```DAX
P03 Application ID =
VAR _Application =
    SELECTEDVALUE (
        'DimApplication'[merchant_application_id]
    )
VAR _Marker =
    SEARCH (
        "_A",
        _Application,
        1,
        0
    )
RETURN
    IF (
        ISBLANK ( _Application ) || _Marker = 0,
        "NOT AVAILABLE",
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

That is the version I recommend.

One subtle point: **Population ID should not be displayed on Merchant Relationship 360 right now.** It is part of the governed identity and matters for lineage, but all of our current rows are in `MSBF_POP_0001`, so showing it would add technical clutter without helping the executive user. It belongs in Governance/Reconciliation or a tooltip if we later need it.

The clean hierarchy for P03 should therefore be:

```text
Population       hidden lineage/context
Merchant ID      000012
Application ID   A01
Scenario         Baseline
```

That preserves the real identity structure without exposing the entire concatenated technical key.
<!-- END_SOURCE_MESSAGE -->


<a id="m-106029e1-4bd7-4b05-bb64-3314f712144d"></a>
## Andrew / user · C109-M00306

C109-M00306 · 2026-08-26T18:33:08.036000-04:00 · active path

Preceding visible parent: [C109-M00305](part-11.md#m-47cc9c5c-e437-4c3d-9cb5-6d03e2a11c16)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: b7006f80-8b8a-455a-ae25-ceeef6b7c5f3.png; 381f1b76-52e9-4bc5-8665-2adb2dd155e3.png

<!-- BEGIN_SOURCE_MESSAGE -->
your P03 application id expands the table:
<!-- END_SOURCE_MESSAGE -->
