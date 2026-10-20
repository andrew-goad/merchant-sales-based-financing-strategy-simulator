# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 19 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-18.md)
[Next part](part-20.md)

<a id="m-94b2538c-1ec6-4cbe-8daf-849510ff0daf"></a>
## Assistant · C109-M00497

C109-M00497 · 2026-08-27T13:52:38.534980-04:00 · active path

Preceding visible parent: [C109-M00496](part-18.md#m-e80e0d49-b4d9-4eeb-b3c2-6054dbd090a4)

<!-- BEGIN_SOURCE_MESSAGE -->
Use a **single-row table** directly under `Merchant request`, with these fields in this exact left-to-right order:

| Order | Display name | Type | Source / measure |
|---|---|---|---|
| 1 | **Capacity** | Measure | `P03 Capacity` |
| 2 | **Coverage** | Measure | `P03 Coverage` |
| 3 | **Resilience** | Measure | `P03 Resilience` |
| 4 | **Risk** | Measure | `P03 Risk` |
| 5 | **Expected loss** | Measure | `P03 Expected Loss` |
| 6 | **Economics** | Measure | `P03 Economics` |
| 7 | **Interpretation** | Measure | `P03 Interpretation` |

I would rename the measures from the earlier `... Display` wording to these cleaner names because they are now purpose-built for a compact table.

Use these definitions.

### `P03 Capacity`

```DAX
P03 Capacity =
VAR _Evidence =
    SELECTEDVALUE ( FactApplicationScenario[capacity_evidence_status] )
RETURN
    IF (
        _Evidence = "BLOCKED",
        BLANK (),
        SELECTEDVALUE (
            FactApplicationScenario[residual_daily_operating_cash_flow]
        )
    )
```

Format: **Currency**, 0 decimals.

Display header: **Capacity**

---

### `P03 Coverage`

```DAX
P03 Coverage =
VAR _Evidence =
    SELECTEDVALUE ( FactApplicationScenario[capacity_evidence_status] )
RETURN
    IF (
        _Evidence = "BLOCKED",
        BLANK (),
        SELECTEDVALUE (
            FactApplicationScenario[sales_linked_payment_coverage_ratio]
        )
    )
```

Format: custom **`0.00x`**

Display header: **Coverage**

The source definition supports using this as the operating-cash-flow-to-obligation-burden relationship. [export reference: filecite | turn63file4 | L119-L122]

---

### `P03 Resilience`

Because we want both score and governed tier in one narrow column, keep this one as text:

```DAX
P03 Resilience =
VAR _Evidence =
    SELECTEDVALUE (
        FactApplicationScenario[operating_resilience_evidence_status]
    )
VAR _Score =
    SELECTEDVALUE (
        FactApplicationScenario[operating_resilience_score]
    )
VAR _Tier =
    SELECTEDVALUE (
        FactApplicationScenario[resilience_tier]
    )
RETURN
    IF (
        _Evidence = "BLOCKED",
        BLANK (),
        IF (
            ISBLANK ( _Score ),
            BLANK (),
            FORMAT ( _Score, "0.0" )
                & " · T"
                & FORMAT ( _Tier, "0" )
        )
    )
```

Display header: **Resilience**

Both score and tier are governed source outputs, so we are not inventing a reporting band. [export reference: filecite | turn63file13 | L452-L454]

---

### `P03 Risk`

```DAX
P03 Risk =
VAR _Evidence =
    SELECTEDVALUE (
        FactApplicationScenario[integrated_risk_evidence_status]
    )
VAR _Score =
    SELECTEDVALUE (
        FactApplicationScenario[integrated_risk_score]
    )
VAR _Tier =
    SELECTEDVALUE (
        FactApplicationScenario[integrated_risk_tier]
    )
RETURN
    IF (
        _Evidence = "BLOCKED",
        BLANK (),
        IF (
            ISBLANK ( _Score ),
            BLANK (),
            FORMAT ( _Score, "0.0" )
                & " · T"
                & FORMAT ( _Tier, "0" )
        )
    )
```

Display header: **Risk**

---

### `P03 Expected Loss`

```DAX
P03 Expected Loss =
VAR _Evidence =
    SELECTEDVALUE (
        FactApplicationScenario[loss_evidence_status]
    )
RETURN
    IF (
        _Evidence = "BLOCKED",
        BLANK (),
        SELECTEDVALUE (
            FactApplicationScenario[schedule_adjusted_comparative_loss_rate]
        )
    )
```

Format: **Percentage, 2 decimals**

Display header: **Expected loss**

This remains explicitly **synthetic comparative expected loss**, not CECL or a production-calibrated loss estimate. [export reference: filecite | turn67file0 | L27-L29]

---

### `P03 Economics`

For this one, combine risk-adjusted contribution and annualized return:

```DAX
P03 Economics =
VAR _Evidence =
    SELECTEDVALUE (
        FactApplicationScenario[unit_economics_evidence_status]
    )
VAR _Contribution =
    SELECTEDVALUE (
        FactApplicationScenario[risk_adjusted_contribution_amount]
    )
VAR _Return =
    SELECTEDVALUE (
        FactApplicationScenario[annualized_risk_adjusted_return_rate]
    )
RETURN
    IF (
        _Evidence = "BLOCKED",
        BLANK (),
        IF (
            ISBLANK ( _Contribution ),
            BLANK (),
            FORMAT (
                _Contribution,
                "$#,0;($#,0);$0"
            )
                &
                IF (
                    NOT ISBLANK ( _Return ),
                    " · " & FORMAT ( _Return, "0.0%" ),
                    ""
                )
        )
    )
```

Display header: **Economics**

The source economics layer explicitly defines risk-adjusted contribution and annualized risk-adjusted return as separate governed outputs, so pairing them here is analytically coherent. [export reference: filecite | turn68file0 | L19-L34]

---

### `P03 Interpretation`

This is the only field that translates the governed evidence into plain English.

```DAX
P03 Interpretation =
VAR _FinalOutcome =
    SELECTEDVALUE (
        FactFinalDecision[final_decision_outcome_code]
    )

VAR _ContractEvidence =
    SELECTEDVALUE (
        FactApplicationScenario[contract_evidence_status]
    )

VAR _Affordability =
    SELECTEDVALUE (
        FactApplicationScenario[affordability_status]
    )

VAR _ResidualCashFlow =
    SELECTEDVALUE (
        FactApplicationScenario[residual_daily_operating_cash_flow]
    )

VAR _EconomicStatus =
    SELECTEDVALUE (
        FactApplicationScenario[economic_status]
    )

VAR _RiskTier =
    SELECTEDVALUE (
        FactApplicationScenario[integrated_risk_tier]
    )

VAR _CapacityIssue =
    _Affordability = "UNAFFORDABLE"
        || (
            NOT ISBLANK ( _ResidualCashFlow )
                && _ResidualCashFlow < 0
        )

VAR _EconomicsIssue =
    _EconomicStatus = "BELOW_HURDLE"
        || _EconomicStatus = "NEGATIVE_CONTRIBUTION"

VAR _RiskIssue =
    NOT ISBLANK ( _RiskTier )
        && _RiskTier >= 4

RETURN
    SWITCH (
        TRUE (),

        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            || _ContractEvidence = "BLOCKED",
            "Insufficient underwriting evidence",

        _FinalOutcome = "FINAL_OFFER_AUTHORIZED",
            "Within governed thresholds",

        _CapacityIssue && _EconomicsIssue,
            "Capacity / economics threshold exceeded",

        _CapacityIssue && _RiskIssue,
            "Affordability / risk threshold exceeded",

        _CapacityIssue,
            "Affordability / capacity threshold exceeded",

        _EconomicsIssue,
            "Economic hurdle not met",

        _RiskIssue,
            "Risk threshold exceeded",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED",
            "Structure requires review",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED",
            "Governed policy threshold exceeded",

        "Within governed thresholds"
    )
```

Display header: **Interpretation**

That intentionally does **not** repeat `Approved`, `Review`, `Policy decline`, etc. The colored decision card already owns that information.

## Build order in the visual

Add them to the table in exactly this order:

**Capacity → Coverage → Resilience → Risk → Expected loss → Economics → Interpretation**

Then:

- turn **Totals OFF**
- turn **Column subtotals OFF**
- keep only **one data row**
- keep the visual **untitled**
- widen `Interpretation` the most
- give `Economics` slightly more width than the other numeric columns
- keep `Capacity`, `Coverage`, `Resilience`, `Risk`, and `Expected loss` comparatively tight.

One small naming point: although the underlying field is `residual_daily_operating_cash_flow`, I would **not** call the header `Residual cash flow`. `Capacity` is better for the underwriting narrative, and the tooltip can explain that it represents residual daily operating cash flow after modeled obligation burden.

Once you have this table rendering, send me a screenshot before we do any conditional formatting or tooltip work.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1b0f9d97-285e-4385-bfb5-c78d42606977"></a>
## Andrew / user · C109-M00498

C109-M00498 · 2026-08-27T13:53:55.444000-04:00 · active path

Preceding visible parent: [C109-M00497](part-19.md#m-94b2538c-1ec6-4cbe-8daf-849510ff0daf)

<!-- BEGIN_SOURCE_MESSAGE -->
so, the earlier P03 Capacity Display are now unusable? I have to create a whole new set of DAX? I had already created all of those measures.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6af2e0ac-cdd1-4906-bbd5-fc9f14433131"></a>
## Assistant · C109-M00499

C109-M00499 · 2026-08-27T13:54:02.409399-04:00 · active path

Preceding visible parent: [C109-M00498](part-19.md#m-1b0f9d97-285e-4385-bfb5-c78d42606977)

<!-- BEGIN_SOURCE_MESSAGE -->
No. **Do not recreate them.** The earlier `P03 Capacity Display`, `P03 Coverage Display`, `P03 Resilience Display`, `P03 Risk Display`, `P03 Expected Loss Display`, and `P03 Economics Display` measures are still usable.

I overcorrected when adapting from cards to a table. The presentation changed; the underlying DAX does not need to.

Use the measures you already created in the table in this order:

1. `P03 Capacity Display`
2. `P03 Coverage Display`
3. `P03 Resilience Display`
4. `P03 Risk Display`
5. `P03 Expected Loss Display`
6. `P03 Economics Display`
7. `P03 Decision Readout`

Then rename the **visual column headers only** to:

**Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation**

The only possible adjustment is cosmetic: because those earlier measures return text such as `INSUFFICIENT EVIDENCE`, they may make the table wider than we want. But first build the table with the existing measures exactly as they are. If the blocked-state wording proves visually awkward, we can make a **small formatting refinement to those same measures** rather than creating a duplicate DAX family.

So: **no new six-measure set. Keep what you already built.** The only question is whether we want to rename `P03 Decision Readout` to `P03 Interpretation`; I would actually leave the measure name alone and just rename its displayed table header to **Interpretation**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-142541f2-06ca-4049-ae9d-204ef2301bc6"></a>
## Andrew / user · C109-M00500

C109-M00500 · 2026-08-27T14:04:57.262000-04:00 · active path

Preceding visible parent: [C109-M00499](part-19.md#m-6af2e0ac-cdd1-4906-bbd5-fc9f14433131)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 2d7442ed-54a8-4546-82ae-fd2b08dc474f.png

<!-- BEGIN_SOURCE_MESSAGE -->
need to resolve positioning, but here it is. One concern - context - if i did not know what I was looking at (and even knowing - I'm scratching my head a bit) - how do I interpret this 
<!-- END_SOURCE_MESSAGE -->


<a id="m-13716e30-d0e5-468a-8111-b7d27b503a03"></a>
## Assistant · C109-M00501

C109-M00501 · 2026-08-27T14:05:03.650189-04:00 · active path

Preceding visible parent: [C109-M00500](part-19.md#m-142541f2-06ca-4049-ae9d-204ef2301bc6)

<!-- BEGIN_SOURCE_MESSAGE -->
You are right. **The table is analytically correct, but not self-explanatory enough yet.** A reader can see numbers, but they do not immediately know what “good,” “bad,” or “material” means.

The main issue is that we are showing **raw governed metrics without enough semantic framing**.

I would fix this without making the row much larger.

The best solution is to turn each column into **value + concise interpretation**, either through the displayed text itself or the column label.

For example, instead of:

**Capacity:** `$80 / DAY`

use:

**Capacity:** `$80/day surplus`

Instead of:

**Coverage:** `1.32x`

use:

**Coverage:** `1.32x covered`

Instead of:

**Resilience:** `92.7 · TIER 1`

use:

**Resilience:** `92.7 · Tier 1`

and make the tooltip explain that Tier 1 is the strongest governed resilience tier.

Instead of:

**Risk:** `11.0 · TIER 1`

use:

**Risk:** `11.0 · Tier 1`

with tooltip explaining lower integrated-risk score / Tier 1 = lower relative risk.

For expected loss:

**Expected loss:** `4.18% · Partial`

is actually fairly understandable, but the tooltip should say:

> Synthetic comparative expected-loss rate; lower is better. Partial indicates governed comparative-loss evidence is usable but not complete.

For economics:

**Economics:** `$1,828 · 39.9% ann.`

is powerful, but it needs one line of explanation in the tooltip:

> Risk-adjusted contribution and annualized risk-adjusted return after modeled loss, costs and capital charge.

The biggest improvement would be the **Interpretation** field. Right now:

> `Offer authorized — economics and risk within decision boundary`

still partly repeats the decision card.

I would shorten it to something more diagnostic, such as:

> **Capacity, risk and economics within governed thresholds**

That answers “why” much more directly.

So the row becomes conceptually:

**Capacity**  
`$80/day surplus`

**Coverage**  
`1.32x covered`

**Resilience**  
`92.7 · Tier 1`

**Risk**  
`11.0 · Tier 1`

**Expected loss**  
`4.18% · Partial`

**Economics**  
`$1,828 · 39.9% ann.`

**Interpretation**  
`Capacity, risk and economics within governed thresholds`

That is much easier to read as an underwriting story.

I would **not add a separate heading or explanatory paragraph** above the row. The page is already tight. Instead, use **good labels + tooltips**.

One additional improvement may be worth considering: rename the columns slightly more explicitly:

**Cash-flow capacity | Payment coverage | Resilience | Integrated risk | Expected loss | Risk-adjusted economics | Interpretation**

That costs some horizontal room, but it removes a lot of ambiguity.

My preference, given your layout, would be:

**Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation**

and let the **tooltips carry the exact definitions**.

The row is worth keeping. We just need to make it read like an underwriting explanation instead of a model-output dump.
<!-- END_SOURCE_MESSAGE -->


<a id="m-62e0eafb-af10-44e3-9de2-1729bfd20a1b"></a>
## Andrew / user · C109-M00502

C109-M00502 · 2026-08-27T14:31:03.975000-04:00 · active path

Preceding visible parent: [C109-M00501](part-19.md#m-13716e30-d0e5-468a-8111-b7d27b503a03)

<!-- BEGIN_SOURCE_MESSAGE -->
Thought about this some more. This is arguably the most key aspect of P03. We have to dedicate more space to this story. Not only these rolled up components but the underlying merchant aspects that led to those components. When I was interviewing they did not care about resilience so much as knowing what would make a merchant resilient or not. I think we need to free up space. A few ideas. 1) remove the bottom left daily warning table. It is already covered by the chart directly above; 2) possibly combine the two right hand charts using a double Y axis. They already have the same x-axis. Turning pro on for this response. Please think through how best to tell the P03 story that'll win folks over in my interviews. They need to know that I know how to properly evaluate these merchants risk when launching a product such as this.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c03cbbc4-cdb0-44e7-9625-47ed7f31415b"></a>
## Assistant · C109-M00503

C109-M00503 · 2026-08-27T14:43:54.978013-04:00 · active path

Preceding visible parent: [C109-M00502](part-19.md#m-62e0eafb-af10-44e3-9de2-1729bfd20a1b)

<!-- BEGIN_SOURCE_MESSAGE -->
You are right to stop and redesign rather than squeeze one more row into the existing P03. **The underwriting rationale should become the centerpiece of the page**, not a thin diagnostic strip between the request and the decision card.

The current page is strong at showing **what happened after the decision**, but an interviewer evaluating credit strategy will care more about whether you can explain:

> What evidence did you examine?  
> What did it say about the merchant’s ability to absorb the obligation?  
> How did that translate into risk, expected loss, and economics?  
> Why did that support this structure—or no structure?

That requires three visible levels:

1. **Merchant operating evidence**
2. **Underwriting assessment**
3. **Governed decision rationale**

## Recommended P03 redesign

### 1. Remove `Monitoring exceptions`

I agree completely.

The table is useful for exact daily records, but it is not carrying enough unique narrative value on P03:

- `Monitoring journey` already shows when the status changed.
- `Remittance performance` already shows the pace deterioration.
- the existing chart tooltips can preserve exact dates, shortfalls, statuses, and monitoring reasons;
- P04 is now explicitly the portfolio servicing-and-exceptions workbench.

Removing the table is not abandoning information. It is **moving detailed exception review to the page designed for it** and using P03 to explain the complete underwriting-to-performance story.

Keep the monitoring chart, but enrich its tooltip with:

- monitoring status;
- primary monitoring reason;
- daily shortfall;
- cumulative shortfall;
- remittance pace;
- days since remittance.

That retains the useful daily evidence without occupying permanent canvas space.

---

### 2. Combine the two right-hand charts

I also support this, with one important design constraint: make it one clearly labeled **dual-axis lifecycle chart**, not two equally weighted lines whose scales are easy to confuse.

Current Power BI line charts support a secondary Y-axis for measures with different scales, and Power BI’s current axis guidance emphasizes separately labeled axes for dual-axis visuals. [export reference: cite | turn854520search3 | turn854520search1]

Call the combined visual:

## **Account performance**

Use:

- **X-axis:** observation date
- **Primary Y-axis:** remaining receivable, dollars
- **Secondary Y-axis:** remittance fulfillment, percent
- **Reference line:** 100% on the remittance axis

Recommended visual treatment:

- remaining receivable: solid, visually dominant trajectory;
- remittance fulfillment: contrasting line style and slightly lighter visual weight;
- retain the 100% dotted benchmark;
- show both axis titles explicitly;
- retain a legend;
- turn data labels off;
- tooltip: date, remaining receivable, cumulative actual remittance, cumulative expected remittance, remittance fulfillment.

The axes should **not** be synchronized. Dollars and percentages have different meanings. The chart is showing two co-timed lifecycle signals, not asserting that their magnitudes are directly comparable.

This consolidation should release nearly the entire current top-right chart footprint for underwriting content.

---

# The revised visual hierarchy

I would organize the main canvas approximately like this:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│ Title / subtitle                       Merchant slicer   Scenario slicer     │
├──────────────┬──────────────────────────────────────────┬───────────────────┤
│ Merchant     │ Application request                      │ Decision outcome  │
│ profile      │                                          │                   │
│              ├──────────────────────────────────────────┤ Funded terms      │
│              │ UNDERWRITING RATIONALE                   │                   │
│              │                                          │                   │
│              │ Merchant operating evidence              │                   │
│              │ [one-row evidence table]                 │                   │
│              │                                          │                   │
│              │ Underwriting assessment                  │                   │
│              │ [one-row assessment table]               │                   │
│              │                                          │                   │
│              │ Why this outcome                         │                   │
│              │ [wide rationale sentence]                │                   │
├──────────────┼────────────────────────┬─────────────────────────────────────┤
│              │ Monitoring journey     │ Account performance                 │
│              │                        │ receivable $ + remittance %          │
├──────────────┴────────────────────────┴─────────────────────────────────────┤
│ Servicing outcome — compact account-level result                           │
├─────────────────────────────────────────────────────────────────────────────┤
│ Provenance and interpretation boundary                                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

The top half then answers:

> **Who applied? What did they request? What did we observe? What did it mean? What did we decide?**

The bottom half answers:

> **How did the account subsequently perform, and where did it end?**

That is the interview-winning P03 story.

---

# Underwriting rationale: the exact content

## Row 1 — Merchant operating evidence

This should expose the concrete merchant behaviors and operating conditions that fed the higher-order assessments.

Use these seven columns:

| Display name | Physical source |
|---|---|
| **Eligible sales / day** | `FactApplicationScenario[avg_daily_eligible_sales_30d]` |
| **Available liquidity** | `FactApplicationScenario[average_available_balance_30d]` |
| **Negative-balance days** | `FactApplicationScenario[negative_balance_day_rate_30d]` |
| **NSFs** | `FactApplicationScenario[nsf_count_30d]` |
| **Operating pattern** | `FactApplicationScenario[archetype_code]` |
| **Processor continuity** | `FactApplicationScenario[processor_continuity_status]` |
| **Evidence quality** | combined `data_confidence_tier`, `verification_disposition`, and optionally `feature_completeness_status` |

These fields all exist in the curated application-scenario fact alongside the downstream capacity, resilience, risk, loss, and economics outputs. [export reference: filecite | turn64file0 | L12-L13]

A supported merchant row could read:

| Eligible sales / day | Available liquidity | Negative-balance days | NSFs | Operating pattern | Processor continuity | Evidence quality |
|---:|---:|---:|---:|---|---|---|
| $2.1K | $50.6K | 0.0% | 0 | Stable | Stable | High · Clear |

That immediately gives an interviewer something meaningful to discuss.

Instead of saying:

> “The merchant had a resilience score of 92.7,”

you can say:

> “The merchant had a stable operating pattern, no recent NSF activity, no negative-balance days, strong available liquidity, stable processor continuity, and high-confidence verified evidence.”

That is a much stronger demonstration of merchant-risk judgment.

---

## Row 2 — Underwriting assessment

I would replace visible **Resilience** with **Post-funding liquidity**. Preserve the resilience measure for tooltips, but do not spend one of the six principal positions on the opaque roll-up.

Use:

| Display name | Physical source |
|---|---|
| **Payment coverage** | `sales_linked_payment_coverage_ratio` |
| **Residual capacity** | `residual_daily_operating_cash_flow` |
| **Post-funding liquidity** | `post_financing_liquidity_buffer_amount` |
| **Integrated risk** | `integrated_risk_score` + `integrated_risk_tier` |
| **Expected loss** | `schedule_adjusted_comparative_loss_rate` |
| **Risk-adjusted economics** | `risk_adjusted_contribution_amount` + `annualized_risk_adjusted_return_rate` |

The source model defines payment coverage as operating cash flow divided by total obligation burden and residual daily capacity as operating cash flow after total daily obligation burden. [export reference: filecite | turn63file4 | L119-L123]

A supported row could read:

| Payment coverage | Residual capacity | Post-funding liquidity | Integrated risk | Expected loss | Risk-adjusted economics |
|---:|---:|---:|---:|---:|---:|
| 1.32x · Affordable | $80/day surplus | $52.1K | 11.0 · Tier 1 | 4.18% · Partial | $1,828 · 39.9% ann. |

That is far easier to explain than the current row because each value follows from a recognizable underwriting question:

- **Coverage:** Does operating cash flow cover total obligations?
- **Residual capacity:** What remains after the proposed burden?
- **Post-funding liquidity:** What liquidity cushion remains after financing?
- **Integrated risk:** What is the combined relative risk profile?
- **Expected loss:** What comparative loss burden accompanies the exposure?
- **Economics:** Is the structure worthwhile after costs, loss, and capital?

The economics layer explicitly defines risk-adjusted contribution after comparative loss and capital charge, and annualizes that contribution against requested funding and payoff horizon. [export reference: filecite | turn68file0 | L12-L35]

---

## Row 3 — Why this outcome

Do **not** keep Interpretation as a narrow seventh table column.

Give it the full width of the underwriting section:

### **Why this outcome**

> Strong payment coverage, positive residual cash flow, substantial post-funding liquidity, low integrated risk, and positive risk-adjusted economics.

For other outcomes:

**Counteroffer review**
> Merchant economics remain viable, but the requested structure exceeds sustainable cash-flow capacity; a reduced structure requires review.

**Policy decline**
> Negative residual cash flow and an economic hurdle breach prevent a sustainable structure.

**Evidence decline**
> Critical underwriting or comparative-loss evidence is unavailable; the assessment cannot be completed.

This sentence should be controlled by `FactFinalDecision` for the terminal outcome and by the governed application-scenario statuses/reasons for the explanation. `FactFinalDecision` remains the authority for whether the row was authorized, routed to counteroffer review, or declined. [export reference: filecite | turn60file0 | L12-L13]

The language should avoid overstating causality. The underlying Module 1 documentation expressly treats diagnostics as explanatory unless they are explicitly consumed by downstream decisioning. [export reference: filecite | turn68file5 | L465-L480] That means:

- label Row 1 **Merchant operating evidence**, not “causal drivers”;
- label Row 2 **Underwriting assessment**;
- reserve **Why this outcome** for the governed decision interpretation.

---

# What happens to the measures already created

Do not delete or rebuild them.

Reuse:

- `P03 Capacity Display` → **Residual capacity**
- `P03 Coverage Display` → **Payment coverage**
- `P03 Risk Display` → **Integrated risk**
- `P03 Expected Loss Display` → **Expected loss**
- `P03 Economics Display` → **Risk-adjusted economics**
- `P03 Decision Readout` → revise and enlarge as the full-width **Why this outcome** statement

Retain:

- `P03 Resilience Display`

but move it to a tooltip, perhaps on **Operating pattern** or **Integrated risk**:

> Operating resilience: 92.7, Tier 1. The visible operating evidence shows the underlying factors used to contextualize this roll-up.

The genuinely new DAX population should therefore be limited to:

- eligible sales display;
- available liquidity display;
- negative-balance-days display;
- NSF display;
- operating-pattern presentation;
- processor-continuity presentation;
- evidence-quality presentation;
- post-funding-liquidity display;
- revised full-width rationale.

You are not discarding the prior work. You are **promoting the meaningful metrics and demoting the opaque aggregate**.

---

# Bottom-of-page lifecycle design

After removing `Monitoring exceptions` and merging the performance charts, preserve:

## Monitoring journey

This still earns its place because it shows how the account migrated through Current, Watch, Underperforming, Severe shortfall, and Paid off.

## Account performance

The new dual-axis chart tells the financial lifecycle:

- receivable decreases;
- remittance fulfillment moves above or below the expected path;
- the 100% benchmark remains visible.

## Servicing outcome

Keep the servicing record, but compress and rename it from `Servicing & intervention` to:

### **Servicing outcome**

Suggested columns:

**Disposition | Treatment | Exposure | Reason | Lifecycle state**

For merchant 000312, that would read conceptually:

**Active servicing | Temporary payment cycle | $518.04 | Severe shortfall | Reassessment due**

P04 owns the detailed operational workbench. P03 only needs the final account-level outcome that completes the journey.

---

# The interview narrative this page should support

A disciplined 45-second walkthrough would be:

> “I begin with evidence sufficiency and the merchant’s actual operating profile—not just an aggregate score. I evaluate eligible sales, liquidity, negative-balance and NSF behavior, operating pattern, processor continuity, and verification quality. I then translate those fundamentals into payment coverage, residual cash-flow capacity, post-financing liquidity, integrated risk, comparative expected loss, and risk-adjusted economics. The governed policy layer determines whether the requested structure is sustainable, needs restructuring, must be declined, or cannot be assessed because evidence is insufficient. The lower half then shows whether the funded account’s performance validated or challenged the original underwriting assessment and how servicing responded.”

That communicates:

- merchant cash-flow underwriting;
- evidence governance;
- affordability and capacity;
- integrated credit risk;
- loss estimation;
- unit economics;
- structure selection;
- lifecycle monitoring;
- servicing feedback.

That is much stronger than leading with “resilience score 92.7.”

## Recommended construction order

1. Remove `Monitoring exceptions`.
2. Create the dual-axis `Account performance` visual and validate it across high-pace and low-pace merchants.
3. Move the decision card and funded terms into the released upper-right space.
4. Build `Merchant operating evidence`.
5. Reuse the existing measures for `Underwriting assessment`, replacing visible Resilience with Post-funding liquidity.
6. Convert `P03 Decision Readout` into a full-width `Why this outcome` sentence.
7. Compress `Servicing outcome`.
8. Update the subtitle to:

> **Follow one synthetic application from merchant operating evidence and underwriting rationale through funding, performance, monitoring and servicing.**

This is the one bounded P03 enhancement worth reopening the frozen candidate for. It changes P03 from an attractive account trace into a credible demonstration of **how you would launch, underwrite, monitor, and defend a merchant financing product**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f731f0ad-0c2f-4110-80b9-addeacd77ca6"></a>
## Andrew / user · C109-M00504

C109-M00504 · 2026-08-27T15:03:38.830000-04:00 · active path

Preceding visible parent: [C109-M00503](part-19.md#m-c03cbbc4-cdb0-44e7-9625-47ed7f31415b)

<!-- BEGIN_SOURCE_MESSAGE -->
I like how you said this, and I think there could be value in having an automated text interpretation box vs having a capacity/coverage/decision line : “The merchant had a stable operating pattern, no recent NSF activity, no negative-balance days, strong available liquidity, stable processor continuity, and high-confidence verified evidence.” thoughts?
<!-- END_SOURCE_MESSAGE -->


<a id="m-d613f3a6-cc6e-4039-b51e-b653e8bcd5fa"></a>
## Assistant · C109-M00505

C109-M00505 · 2026-08-27T15:10:28.322976-04:00 · active path

Preceding visible parent: [C109-M00504](part-19.md#m-f731f0ad-0c2f-4110-80b9-addeacd77ca6)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **That is the stronger direction.** I would replace the current seven-column underwriting table with a wide, automated **Underwriting rationale** panel.

The key is not to replace numbers with vague prose. The panel should translate the governed evidence into a short narrative while retaining the decisive quantitative values. That gives an interviewer both:

- the merchant behavior you evaluated; and
- the financial/risk conclusion you drew from it.

The curated application-scenario fact already contains the operating evidence needed for this: sales, liquidity, negative-balance activity, NSFs, operating archetype, processor continuity, evidence quality, capacity, risk, comparative loss, and economics. [export reference: filecite | turn64file0 | L12-L13]

## Recommended design

Use **three dynamic text measures**, visually grouped inside one bordered panel:

### Underwriting rationale

**Merchant evidence**  
> The merchant showed a stable operating pattern, no recent NSF or negative-balance activity, $50.6K in average available liquidity, stable processor continuity, and high-confidence evidence with clear verification.

**Structure assessment**  
> At the requested structure, operating cash flow covered total obligations 1.32x, leaving $80 per day of residual capacity. Integrated risk was Tier 1, comparative expected loss was 4.18%, and risk-adjusted contribution was $1,828, or 39.9% annualized.

**Why this outcome**  
> The requested structure remained within governed capacity, risk, and economic boundaries.

The green card beside or immediately above it continues to say:

> **APPROVED**  
> Final offer

That division is clean:

- **Decision card:** What happened?
- **Merchant evidence:** What did we observe?
- **Structure assessment:** What did the requested structure imply?
- **Why this outcome:** Why did those facts support the result?

## Why this is better than the current row

The existing row requires the reader to know that:

- coverage above 1.00x generally represents cash-flow coverage;
- positive residual capacity is preferable;
- Tier 1 is favorable;
- lower comparative expected loss is preferable;
- positive risk-adjusted contribution and annualized return support economics;
- `PARTIAL` describes evidence quality rather than a failed result.

That is too much decoding for an executive or interviewer.

The narrative demonstrates that you understand how to translate technical outputs into credit judgment:

> “I did not approve this merchant because the model produced a Tier 1 label. I considered the stability of sales and processor activity, liquidity behavior, adverse account events, evidence quality, obligation coverage, residual cash flow, expected loss, and risk-adjusted economics.”

That is the interview story you want.

## Do not use one uninterrupted paragraph

A single large paragraph would become difficult to scan. Visually group three measures under one title:

```text
UNDERWRITING RATIONALE

Merchant evidence
[dynamic sentence]

Structure assessment
[dynamic sentence]

Why this outcome
[dynamic sentence]
```

That can appear as one cohesive box while remaining easy to read.

I would name the measures:

```text
P03 Merchant Evidence Narrative
P03 Structure Assessment Narrative
P03 Decision Rationale
```

Your existing measures are still useful:

```text
P03 Capacity Display
P03 Coverage Display
P03 Resilience Display
P03 Risk Display
P03 Expected Loss Display
P03 Economics Display
```

The new `P03 Structure Assessment Narrative` can reuse those values. None of that work is wasted.

## What the merchant-evidence sentence should cover

The first sentence should emphasize the **underlying evidence**, not “resilience.”

Its preferred components are:

- operating pattern or archetype;
- NSF activity;
- negative-balance-day activity;
- average available liquidity;
- processor continuity;
- data confidence;
- verification disposition.

Depending on space and materiality, it can also mention sales level or sales trend.

A positive case might read:

> The merchant showed a stable operating pattern, no recent NSF or negative-balance activity, $50.6K in average available liquidity, stable processor continuity, and high-confidence evidence with clear verification.

A weaker but still decisionable merchant might read:

> The merchant showed a volatile operating pattern, two recent NSF events, negative balances on 6.7% of recent days, monitored processor continuity, and medium-confidence evidence requiring verification review.

An evidence-deficient case might read:

> Critical underwriting evidence was unavailable or blocked; merchant capacity, resilience, risk, comparative loss, and economics could not be assessed reliably.

That last state is important. Where evidence is blocked, the source methodology requires downstream economic conclusions to remain unavailable rather than being represented as zero or favorable. [export reference: filecite | turn68file0 | L43-L49]

## Avoid unsupported adjectives

The sentence you quoted includes **“strong available liquidity.”** That is natural language, but we should only say “strong” if we map it to an accepted source status or governed threshold.

Safer wording is:

> `$50.6K in average available liquidity`

or:

> `positive post-financing liquidity of $52.1K`

That is more precise and gives the interviewer the evidence directly.

Likewise:

- use `high-confidence evidence` only when `data_confidence_tier = HIGH`;
- use `clear verification` only when `verification_disposition = CLEAR`;
- use `stable processor continuity` only when the source says `STABLE`;
- use `no recent NSF activity` only when `nsf_count_30d = 0`;
- use `no negative-balance days` only when the rate is zero.

This keeps the narrative deterministic and auditable rather than promotional.

## Structure-assessment sentence

The second line should preserve the core numerical evidence. I would use:

- payment coverage;
- residual daily capacity;
- post-financing liquidity;
- integrated risk tier;
- comparative expected-loss rate;
- risk-adjusted contribution;
- annualized risk-adjusted return.

I would **not lead with resilience score**. Resilience can remain in a tooltip because the first narrative already explains what made the merchant operationally resilient or vulnerable.

A good sentence pattern is:

> At the requested structure, operating cash flow covered total obligations **[coverage]**, leaving **[residual capacity]** and **[post-financing liquidity]**. Integrated risk was **[tier]**, comparative expected loss was **[rate]**, and risk-adjusted contribution was **[amount]**, or **[annualized return]** annualized.

That walks through the underwriting chain in the right order:

> **Affordability → remaining capacity → liquidity cushion → risk → loss → economics**

## Decision-rationale sentence

The third line should not repeat the red/yellow/green card. It should explain the binding conclusion.

### Final offer

> The requested structure remained within governed capacity, risk, and economic boundaries.

### Counteroffer review

> Merchant economics remained viable, but the requested structure exceeded sustainable cash-flow capacity; a reduced structure required review.

### Policy decline driven by capacity

> The requested structure produced insufficient coverage and negative residual cash flow, exceeding the governed affordability boundary.

### Policy decline driven by economics

> The structure did not generate sufficient risk-adjusted contribution to meet the governed economic hurdle.

### Multiple constraints

> Affordability, integrated risk, and risk-adjusted economics did not support a sustainable structure.

### Evidence decline

> Critical underwriting evidence was unavailable, preventing a reliable capacity, risk, loss, and economic assessment.

`FactFinalDecision` must remain authoritative for the terminal result; the application-scenario evidence explains the result but must not override it. That fact contains the final outcome, authorization/review/decline flags, offer terms, and final decision reason. [export reference: filecite | turn60file0 | L12-L13]

## Page-layout recommendation

I would now make these changes:

1. Remove the current seven-column interpretation table.
2. Remove the bottom-left `Monitoring exceptions` table.
3. Combine receivable trajectory and remittance performance into the planned dual-axis **Account performance** chart.
4. Use the released space for a wide **Underwriting rationale** box.
5. Retain the green/yellow/red decision card and funded terms.
6. Keep `Monitoring journey` and a compressed `Servicing outcome` beneath the underwriting section.

The top half of P03 would then tell:

> **Merchant → Request → Evidence → Assessment → Decision → Terms**

The bottom half would tell:

> **Performance → Monitoring → Servicing outcome**

## Recommended final P03 narrative

A strong interviewer walkthrough becomes:

> “The page starts with the merchant and requested structure. The underwriting rationale then explains the operating evidence I considered—sales behavior, liquidity, negative-balance and NSF activity, processor continuity, and evidence quality. It translates those facts into obligation coverage, residual capacity, post-financing liquidity, integrated risk, comparative expected loss, and risk-adjusted economics. The governed decision layer then determines whether the requested structure is supportable, needs restructuring, fails policy, or cannot be evaluated because evidence is insufficient. The lower half shows whether the funded account’s subsequent performance supported or challenged the original assessment.”

That is significantly stronger than presenting a resilience score or a thin metrics row. It makes P03 an **explainable merchant-underwriting case study**, which should become one of the most persuasive pages in the portfolio.
<!-- END_SOURCE_MESSAGE -->


<a id="m-54f59a76-b3d4-42d9-b0a5-8706a564631c"></a>
## Andrew / user · C109-M00506

C109-M00506 · 2026-08-27T16:03:37.434000-04:00 · active path

Preceding visible parent: [C109-M00505](part-19.md#m-d613f3a6-cc6e-4039-b51e-b653e8bcd5fa)

<!-- BEGIN_SOURCE_MESSAGE -->
I will handle a first pass at freeing up space. I agree with your recommendations. Please construct the measures/columns/guidance to build the underwriting narrative and any related output we wish to show. Create this carefully and credibly and make it translate complexity/thorough evaluation in a way that anyone can understand and that also demonstrates my grasp of the material to interviewers and those with an advanced knowledge. It must accomplish that dual purpose in a way that comes off easy and professionally.
<!-- END_SOURCE_MESSAGE -->
