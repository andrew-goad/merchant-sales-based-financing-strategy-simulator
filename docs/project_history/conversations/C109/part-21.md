# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 21 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-20.md)
[Next part](part-22.md)

<a id="m-4dea2330-ca54-4891-9f85-d42968c7abe7"></a>
## Assistant · C109-M00519

C109-M00519 · 2026-08-27T20:19:30.279014-04:00 · active path

Preceding visible parent: [C109-M00518](part-20.md#m-40ae42e4-eab1-44c3-93b5-f331c6f409d3)

<!-- BEGIN_SOURCE_MESSAGE -->
I see it. **The fields are in the Tooltips well correctly, but Power BI is only rendering two of the four additional tooltip fields**:

- Monitoring status — showing
- Remitted to date — **missing**
- Expected to date — **missing**
- Cumulative shortfall — showing

That strongly suggests the two existing `... As Of` measures are returning **BLANK in this `monitoring_date` point context**. Power BI suppresses blank tooltip fields rather than displaying their labels.

So my earlier caveat was correct: **we should not use the existing portfolio-style `As Of` measures here.** The chart itself is being driven directly by `FactAccountDaily[monitoring_date]`, while those measures have a different as-of evaluation contract.

### Fix: create P03 point-date measures

We want the values from the actual daily row represented by the hovered `monitoring_date`.

First, though, I don't want to guess the physical field names. We need the two columns in `FactAccountDaily` corresponding to:

**cumulative actual remittance**  
**cumulative expected remittance**

Your existing `P03 Cumulative Pace Ratio` almost certainly references them.

Open the formula for **`P03 Cumulative Pace Ratio`** and paste it here (or screenshot it). From that I can give you the exact two measures immediately.

They will conceptually be:

```DAX
P03 Cumulative Actual Remittance =
SELECTEDVALUE (
    FactAccountDaily[<actual cumulative column>]
)
```

and

```DAX
P03 Cumulative Expected Remittance =
SELECTEDVALUE (
    FactAccountDaily[<expected cumulative column>]
)
```

Then replace:

- `[Cumulative Actual Remittance As Of]` → `P03 Cumulative Actual Remittance`
- `[Cumulative Expected Remittance As Of]` → `P03 Cumulative Expected Remittance`

and retain the visual names:

**Remitted to date**  
**Expected to date**

### Everything else in this tooltip is working well

Your current hover already gives us:

> **8/23/2026**  
> Receivable balance — **$17,124**  
> Remittance pace — **88.67%**  
> Monitoring status — **WATCH**  
> Cumulative shortfall — **674.67**

Once we insert the two point-date cumulative measures, it will become:

> **8/23/2026**  
> Receivable balance — $17,124  
> Remittance pace — 88.67%  
> Monitoring status — Watch  
> Remitted to date — $X,XXX  
> Expected to date — $X,XXX  
> Cumulative shortfall — $674.67

That's the complete tooltip we want.

One cosmetic item I also notice: `Cumulative shortfall` is currently displaying **`674.67` without `$`**. Change `P03 Cumulative Shortfall` to **Currency, 2 decimals**, so the tooltip renders **$674.67**.

Send me the `P03 Cumulative Pace Ratio` formula and I'll give you the exact DAX for those two missing measures.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cf68a81f-5a0b-42f8-a550-8b19750baed7"></a>
## Andrew / user · C109-M00520

C109-M00520 · 2026-08-27T20:21:24.412000-04:00 · active path

Preceding visible parent: [C109-M00519](part-21.md#m-4dea2330-ca54-4891-9f85-d42968c7abe7)

<!-- BEGIN_SOURCE_MESSAGE -->
cumulative pace ratio just references the cumulative pace ratio variable in FactAccountDaily
<!-- END_SOURCE_MESSAGE -->


<a id="m-099e64e5-cc6b-4257-81b8-d50cbba04062"></a>
## Assistant · C109-M00521

C109-M00521 · 2026-08-27T20:21:31.776260-04:00 · active path

Preceding visible parent: [C109-M00520](part-21.md#m-cf68a81f-5a0b-42f8-a550-8b19750baed7)

<!-- BEGIN_SOURCE_MESSAGE -->
Good — that simplifies it.

Since `P03 Cumulative Pace Ratio` is already a direct `SELECTEDVALUE`-style reference to the daily-row column in `FactAccountDaily`, the two tooltip measures should follow the **same pattern**. The only thing we need is the exact physical column names for cumulative actual and cumulative expected remittance in `FactAccountDaily`.

They are likely something close to:

```DAX
P03 Cumulative Actual Remittance =
SELECTEDVALUE (
    FactAccountDaily[cumulative_actual_remittance_amount]
)
```

```DAX
P03 Cumulative Expected Remittance =
SELECTEDVALUE (
    FactAccountDaily[cumulative_expected_remittance_amount]
)
```

But I do **not** want you to create them until we confirm those exact field names.

Once you identify the two columns, use those direct measures and put them in the Account performance tooltip as:

**Remitted to date**  
**Expected to date**

That will match the same point-date logic already working for `P03 Cumulative Pace Ratio`, `P03 Monitoring Status`, and `P03 Cumulative Shortfall`.

Also keep the tooltip order as:

**Monitoring status → Remitted to date → Expected to date → Cumulative shortfall**

The plotted fields will already show:

**Receivable balance**  
**Remittance pace**

So the final hover becomes a concise six-line financial snapshot.

And yes, format `P03 Cumulative Shortfall` as currency so that `$674.67` renders instead of `674.67`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-58838291-a31f-402e-854e-bb21541a683d"></a>
## Andrew / user · C109-M00522

C109-M00522 · 2026-08-27T20:22:50.784000-04:00 · active path

Preceding visible parent: [C109-M00521](part-21.md#m-099e64e5-cc6b-4257-81b8-d50cbba04062)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: db38d046-76fb-4b52-bba4-550025afacbf.png; a4b51dca-817b-49ce-8a1c-eec507ba35b9.png

<!-- BEGIN_SOURCE_MESSAGE -->
factaccountdaily variables
<!-- END_SOURCE_MESSAGE -->


<a id="m-52884d16-6589-4ab3-8f96-f664c6678c55"></a>
## Assistant · C109-M00523

C109-M00523 · 2026-08-27T20:22:57.804620-04:00 · active path

Preceding visible parent: [C109-M00522](part-21.md#m-58838291-a31f-402e-854e-bb21541a683d)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. The physical fields confirm the exact measures we need, and they also reveal one useful distinction.

`FactAccountDaily` contains:

- `cumulative_remittance_amount` — actual cumulative remittance
- `cumulative_expected_remittance_amount` — expected cumulative remittance
- `cumulative_shortfall_amount`
- `cumulative_pace_ratio`

So create these two **point-date P03 measures**:

```DAX
P03 Cumulative Remittance =
SELECTEDVALUE (
    FactAccountDaily[cumulative_remittance_amount]
)
```

Format: **Currency, 2 decimals**

And:

```DAX
P03 Cumulative Expected Remittance =
SELECTEDVALUE (
    FactAccountDaily[cumulative_expected_remittance_amount]
)
```

Format: **Currency, 2 decimals**

These are preferable to the existing `... As Of` measures for this particular visual because the X-axis is `FactAccountDaily[monitoring_date]`. Each hover therefore resolves to the actual daily account row represented by that point.

### Account performance — final tooltip configuration

Keep your axes:

**X-axis**
- `monitoring_date`

**Y-axis**
- Receivable balance

**Secondary Y-axis**
- Remittance pace

Then Tooltips, in this order:

| Technical measure | Rename for this visual |
|---|---|
| `P03 Monitoring Status` | **Monitoring status** |
| `P03 Cumulative Remittance` | **Remitted to date** |
| `P03 Cumulative Expected Remittance` | **Expected to date** |
| `P03 Cumulative Shortfall` | **Cumulative shortfall** |

Also format `P03 Cumulative Shortfall` as **Currency, 2 decimals**.

Your resulting hover should now look approximately like:

> **8/23/2026**  
> Receivable balance $17,124  
> Remittance pace 88.67%  
> Monitoring status Watch  
> Remitted to date $X,XXX.XX  
> Expected to date $X,XXX.XX  
> Cumulative shortfall $674.67

That's enough. I would **not add any more fields** to Account performance.

### One useful distinction from the field inventory

You also have both:

- `actual_remittance_amount`
- `expected_daily_remittance_amount`

Those are the **single-day flows**.

We specifically do **not** want them here. The Account performance chart is telling a cumulative lifecycle story, so:

**cumulative actual vs cumulative expected → cumulative pace → cumulative shortfall**

is internally coherent.

Those daily fields are more appropriate for Monitoring journey if we ever decide the tooltip needs another layer of detail.

So after these two measures render correctly, I would consider the **Account performance tooltip complete**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6ea16f2d-2c62-4fd2-be95-25b55c620652"></a>
## Andrew / user · C109-M00524

C109-M00524 · 2026-08-27T22:16:31.514000-04:00 · active path

Preceding visible parent: [C109-M00523](part-21.md#m-52884d16-6589-4ab3-8f96-f664c6678c55)

<!-- BEGIN_SOURCE_MESSAGE -->
ok, those were fixed. now give me the new underwriting build items again, step by step.
<!-- END_SOURCE_MESSAGE -->


<a id="m-13408041-bc1c-46b3-9146-5a2909eaa4d5"></a>
## Assistant · C109-M00525

C109-M00525 · 2026-08-27T22:16:36.658422-04:00 · active path

Preceding visible parent: [C109-M00524](part-21.md#m-6ea16f2d-2c62-4fd2-be95-25b55c620652)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Now that the two lifecycle tooltips are settled, I would build the underwriting enhancement in this order. **Do not create any more of the old seven-column table measures.** Your existing `P03 Capacity Display`, `P03 Coverage Display`, `P03 Resilience Display`, `P03 Risk Display`, `P03 Expected Loss Display`, and `P03 Economics Display` remain useful and will move to the technical tooltip.

## Step 1 — Create the underwriting context control

Create this first. It protects every narrative from ambiguous Merchant/Scenario context.

```DAX
P03 Underwriting Context Pass =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )

VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ApplicationScenarioRows =
    IF (
        NOT ISBLANK ( _ApplicationKey )
            && NOT ISBLANK ( _RunScenarioKey ),
        CALCULATE (
            COUNTROWS ( 'FactApplicationScenario' ),
            KEEPFILTERS (
                'FactApplicationScenario'[ApplicationKey] = _ApplicationKey
            ),
            KEEPFILTERS (
                'FactApplicationScenario'[RunScenarioKey] = _RunScenarioKey
            )
        )
    )

VAR _FinalDecisionRows =
    IF (
        NOT ISBLANK ( _ApplicationKey )
            && NOT ISBLANK ( _RunScenarioKey ),
        CALCULATE (
            COUNTROWS ( 'FactFinalDecision' ),
            KEEPFILTERS (
                'FactFinalDecision'[ApplicationKey] = _ApplicationKey
            ),
            KEEPFILTERS (
                'FactFinalDecision'[RunScenarioKey] = _RunScenarioKey
            )
        )
    )

RETURN
    IF (
        NOT ISBLANK ( _ApplicationKey )
            && NOT ISBLANK ( _RunScenarioKey )
            && _ApplicationScenarioRows = 1
            && _FinalDecisionRows = 1,
        1,
        0
    )
```

Keep it visible while building. For every valid P03 Merchant + Scenario selection, it should show **1**.

---

# Step 2 — Create `P03 Merchant Evidence Narrative`

This is the first visible narrative. It answers:

> **What did we actually observe about this merchant?**

```DAX
P03 Merchant Evidence Narrative =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _Archetype =
    SELECTEDVALUE ( 'FactApplicationScenario'[archetype_code] )

VAR _AverageDailySales =
    SELECTEDVALUE (
        'FactApplicationScenario'[avg_daily_eligible_sales_30d]
    )

VAR _AverageAvailableBalance =
    SELECTEDVALUE (
        'FactApplicationScenario'[average_available_balance_30d]
    )

VAR _NegativeBalanceRate =
    SELECTEDVALUE (
        'FactApplicationScenario'[negative_balance_day_rate_30d]
    )

VAR _NSFCount =
    SELECTEDVALUE ( 'FactApplicationScenario'[nsf_count_30d] )

VAR _ProcessorContinuity =
    SELECTEDVALUE (
        'FactApplicationScenario'[processor_continuity_status]
    )

VAR _DataConfidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[data_confidence_tier]
    )

VAR _FeatureCompleteness =
    SELECTEDVALUE (
        'FactApplicationScenario'[feature_completeness_status]
    )

VAR _Verification =
    SELECTEDVALUE (
        'FactApplicationScenario'[verification_disposition]
    )

VAR _ContractEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[contract_evidence_status]
    )

VAR _EvidenceBlocked =
    _ContractEvidence = "BLOCKED"
        || _FeatureCompleteness = "BLOCKED"
        || _Verification IN {
            "STOP",
            "INSUFFICIENT_EVIDENCE"
        }

VAR _PatternPhrase =
    SWITCH (
        _Archetype,
        "STABLE", "a stable operating pattern",
        "GROWING", "a growing operating pattern",
        "SEASONAL", "a seasonal operating pattern",
        "VOLATILE", "a volatile operating pattern",
        "DECLINING", "a declining operating pattern",
        "DISRUPTED", "a disrupted operating pattern",
        "THIN_HISTORY", "limited operating history",
        "INSUFFICIENT_EVIDENCE", "insufficient operating-pattern evidence",
        "an unclassified operating pattern"
    )

VAR _SalesText =
    SWITCH (
        TRUE (),
        ISBLANK ( _AverageDailySales ), BLANK (),
        ABS ( _AverageDailySales ) >= 1000000,
            FORMAT ( _AverageDailySales / 1000000, "$0.0" ) & "M",
        ABS ( _AverageDailySales ) >= 1000,
            FORMAT ( _AverageDailySales / 1000, "$0.0" ) & "K",
        FORMAT ( _AverageDailySales, "$#,0" )
    )

VAR _SalesPhrase =
    IF (
        ISBLANK ( _AverageDailySales ),
        "eligible-sales evidence was unavailable",
        "averaging " & _SalesText & " in eligible sales per day"
    )

VAR _NSFPhrase =
    SWITCH (
        TRUE (),
        ISBLANK ( _NSFCount ), "NSF evidence was unavailable",
        _NSFCount = 0, "no recent NSF events",
        _NSFCount = 1, "one recent NSF event",
        FORMAT ( _NSFCount, "0" ) & " recent NSF events"
    )

VAR _NegativeBalancePhrase =
    SWITCH (
        TRUE (),
        ISBLANK ( _NegativeBalanceRate ),
            "negative-balance evidence was unavailable",
        _NegativeBalanceRate = 0,
            "no negative-balance days",
        "negative balances on "
            & FORMAT ( _NegativeBalanceRate, "0.0%" )
            & " of the last 30 days"
    )

VAR _BalanceText =
    SWITCH (
        TRUE (),
        ISBLANK ( _AverageAvailableBalance ), BLANK (),
        ABS ( _AverageAvailableBalance ) >= 1000000,
            FORMAT ( ABS ( _AverageAvailableBalance ) / 1000000, "$0.0" ) & "M",
        ABS ( _AverageAvailableBalance ) >= 1000,
            FORMAT ( ABS ( _AverageAvailableBalance ) / 1000, "$0.0" ) & "K",
        FORMAT ( ABS ( _AverageAvailableBalance ), "$#,0" )
    )

VAR _BalanceSentence =
    SWITCH (
        TRUE (),
        ISBLANK ( _AverageAvailableBalance ),
            "Average available balance was unavailable.",
        _AverageAvailableBalance < 0,
            "Average available balance was negative at " & _BalanceText & ".",
        "Average available balance was " & _BalanceText & "."
    )

VAR _ProcessorSentence =
    SWITCH (
        _ProcessorContinuity,
        "STABLE", "Processor continuity was stable.",
        "MONITORED", "Processor continuity required monitoring.",
        "WATCH", "Processor continuity was on watch.",
        "DISRUPTED", "Processor continuity was disrupted.",
        "UNAVAILABLE", "Processor-continuity evidence was unavailable.",
        "Processor-continuity status was not classified."
    )

VAR _ConfidenceLabel =
    SWITCH (
        _DataConfidence,
        "HIGH", "high-confidence",
        "MEDIUM", "medium-confidence",
        "LOW", "low-confidence",
        "REVIEW", "under-review",
        "unclassified"
    )

VAR _CompletenessLabel =
    SWITCH (
        _FeatureCompleteness,
        "COMPLETE", "complete",
        "PARTIAL", "partial",
        "BLOCKED", "blocked",
        "unclassified"
    )

VAR _EvidenceSentence =
    SWITCH (
        TRUE (),
        _Verification = "CLEAR",
            "The evidence was "
                & _ConfidenceLabel
                & " and "
                & _CompletenessLabel
                & ", with clear verification.",
        _Verification = "REVIEW",
            "The evidence was "
                & _ConfidenceLabel
                & " and "
                & _CompletenessLabel
                & ", but verification required review.",
        _Verification = "STOP",
            "Verification produced a hard-stop condition.",
        _Verification = "INSUFFICIENT_EVIDENCE",
            "Verification evidence was insufficient.",
        "Verification status was unavailable."
    )

RETURN
    SWITCH (
        TRUE (),
        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        _EvidenceBlocked,
            "Critical source or verification evidence was unavailable or blocked. "
                & "The governed process therefore does not treat the merchant's "
                & "operating profile as decision-ready.",

        "The merchant showed "
            & _PatternPhrase
            & ", "
            & _SalesPhrase
            & ", with "
            & _NSFPhrase
            & " and "
            & _NegativeBalancePhrase
            & ". "
            & _BalanceSentence
            & " "
            & _ProcessorSentence
            & " "
            & _EvidenceSentence
    )
```

---

# Step 3 — Create `P03 Structure Assessment Narrative`

This answers:

> **What did the requested financing structure do to capacity, liquidity, risk, loss and economics?**

```DAX
P03 Structure Assessment Narrative =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _CapacityEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[capacity_evidence_status]
    )

VAR _Affordability =
    SELECTEDVALUE (
        'FactApplicationScenario'[affordability_status]
    )

VAR _Coverage =
    SELECTEDVALUE (
        'FactApplicationScenario'[sales_linked_payment_coverage_ratio]
    )

VAR _ResidualCapacity =
    SELECTEDVALUE (
        'FactApplicationScenario'[residual_daily_operating_cash_flow]
    )

VAR _PostFinancingLiquidity =
    SELECTEDVALUE (
        'FactApplicationScenario'[post_financing_liquidity_buffer_amount]
    )

VAR _RiskEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[integrated_risk_evidence_status]
    )

VAR _RiskStatus =
    SELECTEDVALUE (
        'FactApplicationScenario'[integrated_risk_status]
    )

VAR _RiskTier =
    SELECTEDVALUE (
        'FactApplicationScenario'[integrated_risk_tier]
    )

VAR _RiskScore =
    SELECTEDVALUE (
        'FactApplicationScenario'[integrated_risk_score]
    )

VAR _LossEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[loss_evidence_status]
    )

VAR _ExpectedLossRate =
    SELECTEDVALUE (
        'FactApplicationScenario'[schedule_adjusted_comparative_loss_rate]
    )

VAR _EconomicsEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[unit_economics_evidence_status]
    )

VAR _Contribution =
    SELECTEDVALUE (
        'FactApplicationScenario'[risk_adjusted_contribution_amount]
    )

VAR _AnnualizedReturn =
    SELECTEDVALUE (
        'FactApplicationScenario'[annualized_risk_adjusted_return_rate]
    )

VAR _EconomicStatus =
    SELECTEDVALUE (
        'FactApplicationScenario'[economic_status]
    )

VAR _AffordabilityLabel =
    SWITCH (
        _Affordability,
        "AFFORDABLE", "affordable",
        "MARGINAL", "marginal",
        "UNAFFORDABLE", "unaffordable",
        "INSUFFICIENT_EVIDENCE", "not assessable",
        "unclassified"
    )

VAR _ResidualText =
    FORMAT (
        ABS ( _ResidualCapacity ),
        "$#,0"
    )

VAR _ResidualClause =
    SWITCH (
        TRUE (),
        ISBLANK ( _ResidualCapacity ),
            "with residual capacity unavailable",
        _ResidualCapacity >= 0,
            "leaving "
                & _ResidualText
                & " per day after modeled obligations",
        "producing a "
            & _ResidualText
            & " per-day shortfall"
    )

VAR _LiquidityText =
    SWITCH (
        TRUE (),
        ISBLANK ( _PostFinancingLiquidity ), BLANK (),
        ABS ( _PostFinancingLiquidity ) >= 1000000,
            FORMAT ( ABS ( _PostFinancingLiquidity ) / 1000000, "$0.0" ) & "M",
        ABS ( _PostFinancingLiquidity ) >= 1000,
            FORMAT ( ABS ( _PostFinancingLiquidity ) / 1000, "$0.0" ) & "K",
        FORMAT ( ABS ( _PostFinancingLiquidity ), "$#,0" )
    )

VAR _LiquidityClause =
    SWITCH (
        TRUE (),
        ISBLANK ( _PostFinancingLiquidity ), BLANK (),
        _PostFinancingLiquidity >= 0,
            "a post-financing liquidity buffer of " & _LiquidityText,
        "a negative post-financing liquidity position of " & _LiquidityText
    )

VAR _CapacitySentence =
    IF (
        _CapacityEvidence = "BLOCKED"
            || ISBLANK ( _Coverage ),
        "Capacity and affordability were not reportable under the evidence contract.",
        "At the requested structure, the governed capacity assessment was "
            & _AffordabilityLabel
            & ": modeled operating cash flow covered total daily obligations "
            & FORMAT ( _Coverage, "0.00x" )
            & ", "
            & _ResidualClause
            & IF (
                NOT ISBLANK ( _LiquidityClause ),
                ", with " & _LiquidityClause,
                ""
            )
            & "."
    )

VAR _RiskLabel =
    SWITCH (
        _RiskStatus,
        "LOW_RISK", "low",
        "MODERATE_RISK", "moderate",
        "ELEVATED_RISK", "elevated",
        "HIGH_RISK", "high",
        "SEVERE_RISK", "severe",
        "INSUFFICIENT_EVIDENCE", "not assessable",
        "unclassified"
    )

VAR _RiskSentence =
    IF (
        _RiskEvidence = "BLOCKED"
            || ISBLANK ( _RiskTier ),
        "Integrated risk was not assessable under the evidence contract.",
        "Integrated risk was "
            & _RiskLabel
            & " (Tier "
            & FORMAT ( _RiskTier, "0" )
            & IF (
                NOT ISBLANK ( _RiskScore ),
                "; score " & FORMAT ( _RiskScore, "0.0" ),
                ""
            )
            & ")."
    )

VAR _LossSentence =
    IF (
        _LossEvidence = "BLOCKED"
            || ISBLANK ( _ExpectedLossRate ),
        "Comparative expected loss was not reportable.",
        "Comparative expected loss was "
            & FORMAT ( _ExpectedLossRate, "0.00%" )
            & "."
    )

VAR _ContributionText =
    IF (
        ISBLANK ( _Contribution ),
        BLANK (),
        FORMAT (
            _Contribution,
            "$#,0;($#,0);$0"
        )
    )

VAR _EconomicStatusTail =
    SWITCH (
        _EconomicStatus,
        "ABOVE_HURDLE", ", above the governed hurdle.",
        "BELOW_HURDLE", ", below the governed hurdle.",
        "NEGATIVE_CONTRIBUTION", ", producing negative contribution.",
        "."
    )

VAR _EconomicsSentence =
    IF (
        _EconomicsEvidence = "BLOCKED"
            || ISBLANK ( _Contribution ),
        "Risk-adjusted economics were not reportable.",
        "Risk-adjusted contribution was "
            & _ContributionText
            & IF (
                NOT ISBLANK ( _AnnualizedReturn ),
                " ("
                    & FORMAT (
                        _AnnualizedReturn,
                        "0.0%;(0.0%);0.0%"
                    )
                    & " annualized)",
                ""
            )
            & _EconomicStatusTail
    )

RETURN
    IF (
        _ContextPass <> 1,
        "Select one merchant application and one scenario.",
        _CapacitySentence
            & " "
            & _RiskSentence
            & " "
            & _LossSentence
            & " "
            & _EconomicsSentence
    )
```

---

# Step 4 — Replace the formula in the existing `P03 Decision Readout`

Do **not** create another interpretation measure.

Keep the existing measure name:

```text
P03 Decision Readout
```

but replace its current formula with the fuller decision-rationale logic we developed.

The visible label will become:

### **Why this outcome**

Use this version:

```DAX
P03 Decision Readout =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _FinalOutcome =
    SELECTEDVALUE (
        'FactFinalDecision'[final_decision_outcome_code]
    )

VAR _PricingDisposition =
    SELECTEDVALUE (
        'FactFinalDecision'[source_pricing_disposition_code]
    )

VAR _FinalOfferAmount =
    SELECTEDVALUE (
        'FactFinalDecision'[final_offer_amount]
    )

VAR _RequestedAmount =
    SELECTEDVALUE (
        'DimApplication'[requested_funding_amount]
    )

VAR _Verification =
    SELECTEDVALUE (
        'FactApplicationScenario'[verification_disposition]
    )

VAR _ContractEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[contract_evidence_status]
    )

VAR _HardStop =
    SELECTEDVALUE (
        'FactApplicationScenario'[hard_stop_recommended_flag]
    )

VAR _Affordability =
    SELECTEDVALUE (
        'FactApplicationScenario'[affordability_status]
    )

VAR _Coverage =
    SELECTEDVALUE (
        'FactApplicationScenario'[sales_linked_payment_coverage_ratio]
    )

VAR _ResidualCapacity =
    SELECTEDVALUE (
        'FactApplicationScenario'[residual_daily_operating_cash_flow]
    )

VAR _RiskStatus =
    SELECTEDVALUE (
        'FactApplicationScenario'[integrated_risk_status]
    )

VAR _EconomicStatus =
    SELECTEDVALUE (
        'FactApplicationScenario'[economic_status]
    )

VAR _Archetype =
    SELECTEDVALUE (
        'FactApplicationScenario'[archetype_code]
    )

VAR _PrimaryReason =
    SELECTEDVALUE (
        'FactApplicationScenario'[primary_contract_reason_code]
    )

VAR _SecondaryReasons =
    COALESCE (
        SELECTEDVALUE (
            'FactApplicationScenario'[secondary_contract_reason_codes]
        ),
        ""
    )

VAR _ReasonText =
    UPPER (
        COALESCE ( _PrimaryReason, "" )
            & "|"
            & _SecondaryReasons
    )

VAR _HardStopIssue =
    _HardStop = TRUE ()
        || _Verification = "STOP"
        || CONTAINSSTRING ( _ReasonText, "VERIFICATION_HARD_STOP" )
        || CONTAINSSTRING ( _ReasonText, "CRITICAL_SOURCE_UNAVAILABLE" )

VAR _CapacityIssue =
    _Affordability = "UNAFFORDABLE"
        || ( NOT ISBLANK ( _Coverage ) && _Coverage < 1 )
        || (
            NOT ISBLANK ( _ResidualCapacity )
                && _ResidualCapacity < 0
        )
        || CONTAINSSTRING ( _ReasonText, "NEGATIVE_RESIDUAL_CASH_FLOW" )
        || CONTAINSSTRING ( _ReasonText, "CAPACITY_BURDEN_RISK" )

VAR _EconomicIssue =
    _EconomicStatus IN {
        "BELOW_HURDLE",
        "NEGATIVE_CONTRIBUTION"
    }
        || CONTAINSSTRING ( _ReasonText, "BELOW_ECONOMIC_HURDLE" )
        || CONTAINSSTRING (
            _ReasonText,
            "NEGATIVE_RISK_ADJUSTED_CONTRIBUTION"
        )

VAR _RiskIssue =
    _RiskStatus IN {
        "HIGH_RISK",
        "SEVERE_RISK"
    }

VAR _LossIssue =
    CONTAINSSTRING ( _ReasonText, "HIGH_COMPARATIVE_LOSS_RATE" )
        || CONTAINSSTRING ( _ReasonText, "RECOVERY_SOURCE_CONFLICT" )

VAR _OperatingIssue =
    _Archetype IN {
        "VOLATILE",
        "DECLINING",
        "DISRUPTED"
    }
        || CONTAINSSTRING ( _ReasonText, "OPERATING_DISRUPTION" )
        || CONTAINSSTRING ( _ReasonText, "DECLINING_CASH_FLOW" )
        || CONTAINSSTRING ( _ReasonText, "HIGH_CASH_FLOW_VOLATILITY" )
        || CONTAINSSTRING ( _ReasonText, "OPERATING_RESILIENCE_RISK" )

VAR _RequestedAmountText =
    FORMAT ( _RequestedAmount, "$#,0" )

VAR _FinalOfferAmountText =
    FORMAT ( _FinalOfferAmount, "$#,0" )

VAR _OfferReduced =
    NOT ISBLANK ( _RequestedAmount )
        && NOT ISBLANK ( _FinalOfferAmount )
        && _FinalOfferAmount < _RequestedAmount - 0.01

RETURN
    SWITCH (
        TRUE (),

        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            || _PricingDisposition = "NO_STRUCTURE_INSUFFICIENT_EVIDENCE"
            || _ContractEvidence = "BLOCKED",
            "Critical source or verification evidence was unavailable. "
                & "The governed process therefore did not infer capacity, risk, "
                & "comparative loss, or economics from incomplete inputs.",

        _FinalOutcome = "FINAL_OFFER_AUTHORIZED"
            && _OfferReduced,
            "The merchant supported an offer, but the authorized structure "
                & "reduced exposure from "
                & _RequestedAmountText
                & " to "
                & _FinalOfferAmountText
                & ". The selected terms satisfied the final governed decision boundary.",

        _FinalOutcome = "FINAL_OFFER_AUTHORIZED",
            "The selected structure satisfied the governed eligibility, risk, "
                & "and economic boundary; no binding condition prevented final authorization.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _CapacityIssue
            && _EconomicIssue,
            "The requested structure strained cash-flow capacity and did not "
                & "meet the economic hurdle. A reduced structure was identified, "
                & "but governance requires manual authorization before it can become an offer.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _CapacityIssue,
            "The requested structure exceeded sustainable cash-flow capacity. "
                & "A reduced structure was identified, but governance requires "
                & "manual authorization before it can become an offer.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _EconomicIssue,
            "The requested structure did not meet the governed economic hurdle. "
                & "An alternative structure was identified, but it requires manual authorization.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && ( _RiskIssue || _LossIssue ),
            "Risk or comparative loss at the requested structure required a "
                & "reduced structure and governed review before authorization.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED",
            "A reduced structure was identified, but governance requires manual "
                & "authorization before it can become an offer.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _HardStopIssue,
            "A hard-stop source, verification, or policy condition prevented "
                & "offer design; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue
            && _EconomicIssue,
            "The requested structure produced insufficient coverage or negative "
                & "residual cash flow and did not meet the governed economic hurdle; "
                & "no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue
            && ( _RiskIssue || _LossIssue ),
            "The requested structure exceeded sustainable cash-flow capacity "
                & "while risk or comparative loss was also elevated; no supportable "
                & "structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue,
            "The requested structure exceeded sustainable cash-flow capacity; "
                & "no supportable alternative structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _EconomicIssue,
            "Risk-adjusted economics did not meet the governed hurdle; "
                & "no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && ( _RiskIssue || _LossIssue ),
            "Integrated risk or comparative loss exceeded the governed boundary; "
                & "no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _OperatingIssue,
            "Operating instability materially weakened the underwriting profile; "
                & "no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED",
            "One or more governed eligibility or structure gates failed; "
                & "no supportable structure was authorized.",

        "The governed decision requires further review."
    )
```

---

# Step 5 — Create the evidence-basis note

This is small-text evidence disclosure beneath the three narratives.

```DAX
P03 Underwriting Evidence Note =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _ContractEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[contract_evidence_status]
    )

VAR _DataConfidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[data_confidence_tier]
    )

VAR _SourceConfidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[source_confidence_score]
    )

VAR _Verification =
    SELECTEDVALUE (
        'FactApplicationScenario'[verification_disposition]
    )

VAR _FraudTier =
    SELECTEDVALUE (
        'FactApplicationScenario'[fraud_risk_tier]
    )

VAR _CapacityEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[capacity_evidence_status]
    )

VAR _RiskEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[integrated_risk_evidence_status]
    )

VAR _LossEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[loss_evidence_status]
    )

VAR _EconomicsEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[unit_economics_evidence_status]
    )

VAR _VerificationLabel =
    SWITCH (
        _Verification,
        "CLEAR", "clear verification",
        "REVIEW", "verification review",
        "STOP", "verification stop",
        "INSUFFICIENT_EVIDENCE", "insufficient verification evidence",
        "verification unavailable"
    )

RETURN
    IF (
        _ContextPass <> 1,
        BLANK (),
        "Evidence basis: "
            & LOWER ( COALESCE ( _ContractEvidence, "unavailable" ) )
            & " overall"
            & " · "
            & LOWER ( COALESCE ( _DataConfidence, "unavailable" ) )
            & " data confidence"
            & IF (
                NOT ISBLANK ( _SourceConfidence ),
                " (" & FORMAT ( _SourceConfidence, "0.0%" ) & ")",
                ""
            )
            & " · "
            & _VerificationLabel
            & IF (
                NOT ISBLANK ( _FraudTier ),
                " · fraud tier " & FORMAT ( _FraudTier, "0" ),
                ""
            )
            & " · capacity "
            & LOWER ( COALESCE ( _CapacityEvidence, "unavailable" ) )
            & " · risk "
            & LOWER ( COALESCE ( _RiskEvidence, "unavailable" ) )
            & " · loss "
            & LOWER ( COALESCE ( _LossEvidence, "unavailable" ) )
            & " · economics "
            & LOWER ( COALESCE ( _EconomicsEvidence, "unavailable" ) )
    )
```

This is intentionally more technical than the prose above it.

---

# Step 6 — Create the decision-timing note

```DAX
P03 Underwriting Timing Note =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _DecisionSnapshotDate =
    SELECTEDVALUE (
        'FactApplicationScenario'[as_of_date]
    )

RETURN
    IF (
        _ContextPass <> 1,
        BLANK (),
        "Decision snapshot: "
            & FORMAT ( _DecisionSnapshotDate, "M/d/yyyy" )
            & ". Later account performance is shown separately and does not "
            & "rewrite the original underwriting assessment."
    )
```

This is important enough to keep visible.

---

# Step 7 — Build the visible panel

In the blank center-left space you created, build this:

```text
Underwriting rationale

Merchant operating evidence
<dynamic narrative>

Requested-structure assessment
<dynamic narrative>

Why this outcome
<dynamic narrative>

Evidence basis...
Decision snapshot...
```

### Use

Create **three Card (new)** visuals:

1. `P03 Merchant Evidence Narrative`
2. `P03 Structure Assessment Narrative`
3. `P03 Decision Readout`

Then two smaller Card (new) visuals:

4. `P03 Underwriting Evidence Note`
5. `P03 Underwriting Timing Note`

Do **not** use a Smart Narrative visual.

### Formatting

For all five:

- visual title OFF;
- backgrounds OFF;
- borders OFF;
- word wrap ON;
- left aligned.

Use static text labels:

**Underwriting rationale** — section title

**Merchant operating evidence**  
**Requested-structure assessment**  
**Why this outcome**

Then smaller muted text for the evidence/timing notes.

I would start around:

- section title: **14–15 pt bold**
- subsection labels: **10–11 pt bold**
- main narrative: **10 pt**
- `Why this outcome`: **10–11 pt**, perhaps semibold
- evidence/timing: **8–9 pt**

Do not add red/yellow/green coloring here. The existing decision card already owns that semantic signal.

---

# Step 8 — Build the technical tooltip page

Create a new report page:

### `P03 - Underwriting Detail`

Set:

**Page information → Tooltip = On**

and size it as a tooltip page.

Use the six measures you already created:

- `P03 Capacity Display`
- `P03 Coverage Display`
- `P03 Resilience Display`
- `P03 Risk Display`
- `P03 Expected Loss Display`
- `P03 Economics Display`

Arrange approximately:

```text
UNDERWRITING DETAIL

Capacity              Coverage              Resilience
[value]               [value]               [value]

Integrated risk       Expected loss         Economics
[value]               [value]               [value]

Evidence basis
[evidence note]
```

This is where the technically sophisticated interviewer can see exact scores, tiers and economics.

---

# Step 9 — Create the decision trace for that tooltip

```DAX
P03 Decision Trace =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _PricingDisposition =
    SELECTEDVALUE (
        'FactFinalDecision'[source_pricing_disposition_code]
    )

VAR _FinalOutcome =
    SELECTEDVALUE (
        'FactFinalDecision'[final_decision_outcome_code]
    )

VAR _FinalDecisionReason =
    SELECTEDVALUE (
        'FactFinalDecision'[primary_decision_reason_code]
    )

VAR _UpstreamReason =
    SELECTEDVALUE (
        'FactApplicationScenario'[primary_contract_reason_code]
    )

VAR _FallbackPath =
    SELECTEDVALUE (
        'FactApplicationScenario'[fallback_path_code]
    )

RETURN
    IF (
        _ContextPass <> 1,
        BLANK (),
        "Pricing disposition: "
            & COALESCE ( _PricingDisposition, "NOT AVAILABLE" )
            & " | Final outcome: "
            & COALESCE ( _FinalOutcome, "NOT AVAILABLE" )
            & " | M2.3 reason: "
            & COALESCE ( _FinalDecisionReason, "NOT AVAILABLE" )
            & " | Upstream reason: "
            & COALESCE ( _UpstreamReason, "NOT AVAILABLE" )
            & " | Fallback path: "
            & COALESCE ( _FallbackPath, "NOT AVAILABLE" )
    )
```

Add this at the bottom of the tooltip.

Also add static small text:

> **Internal synthetic explanation codes — not customer-facing adverse-action language or production policy.**

Then assign the `P03 - Underwriting Detail` tooltip page to all three main underwriting narrative visuals.

---

# Step 10 — Set visual interactions

This is critical.

The underwriting panel must respond to:

- **Merchant**
- **Scenario**

It must **not** respond to selections in:

- Account performance
- Monitoring journey
- Servicing outcome

Use **Format → Edit interactions**.

Select each lifecycle chart/table and set its interaction with every underwriting narrative object to:

### **None**

The underwriting section is the original decision snapshot. Later account performance must never rewrite it.

---

# Step 11 — Update the subtitle

Replace the current subtitle with:

> **Follow one synthetic application from merchant operating evidence and underwriting rationale through decision, funding, performance, monitoring and servicing.**

That now accurately describes P03.

---

# Step 12 — QA before polishing

Test these five combinations:

1. **000312 — Baseline**
   - approved/funded;
   - later poor performance;
   - underwriting rationale must remain original.

2. **000738 — Baseline**
   - counteroffer review;
   - rationale should explain why restructuring/review was needed.

3. **000001 — Baseline**
   - evidence decline;
   - blocked fields must not turn into zeros or invented risk conclusions.

4. **000311 — Baseline**
   - policy decline;
   - rationale should explain the supported binding weakness.

5. **000749 — Baseline vs Recession Energy**
   - use the same merchant and switch Scenario;
   - operating evidence, capacity/risk/economics, rationale and decision should move coherently with scenario.

For every test, confirm:

**`P03 Underwriting Context Pass = 1`**

and confirm that:

- blocked evidence is described as unavailable/blocked;
- partial evidence remains explicitly partial;
- `FactFinalDecision` controls what ultimately happened;
- the narrative does not infer a decline reason merely because one metric looks weak;
- lifecycle clicks do not alter underwriting.

---

## Final object inventory

After this enhancement, the underwriting-specific model population should be:

**Already built**
- `P03 Capacity Display`
- `P03 Coverage Display`
- `P03 Resilience Display`
- `P03 Risk Display`
- `P03 Expected Loss Display`
- `P03 Economics Display`
- `P03 Decision Readout` — **formula updated**

**New**
- `P03 Underwriting Context Pass`
- `P03 Merchant Evidence Narrative`
- `P03 Structure Assessment Narrative`
- `P03 Underwriting Evidence Note`
- `P03 Underwriting Timing Note`
- `P03 Decision Trace`

I would build **Steps 1–6 first and put the five visible measures into the available space before creating the tooltip**. That lets us inspect the actual page density and narrative quality before spending time polishing the technical hover experience.
<!-- END_SOURCE_MESSAGE -->


<a id="m-defefa9b-a923-4822-8ce0-9ffdc3267dad"></a>
## Andrew / user · C109-M00526

C109-M00526 · 2026-08-27T22:48:16.148000-04:00 · active path

Preceding visible parent: [C109-M00525](part-21.md#m-13408041-bc1c-46b3-9146-5a2909eaa4d5)

<!-- BEGIN_SOURCE_MESSAGE -->
how to fix this: multi card  - so much white space in between  - and the middle gets cutoff
<!-- END_SOURCE_MESSAGE -->


<a id="m-6010a079-f75d-4730-8acd-3fb1245ca51a"></a>
## Assistant · C109-M00527

C109-M00527 · 2026-08-27T22:48:21.914674-04:00 · active path

Preceding visible parent: [C109-M00526](part-21.md#m-defefa9b-a923-4822-8ce0-9ffdc3267dad)

<!-- BEGIN_SOURCE_MESSAGE -->
That is a limitation of using one **multi-card visual for long dynamic text**. Power BI tries to allocate the available height across the cards, which creates excessive internal spacing and can truncate the longest card—exactly what you're seeing.

For the underwriting narrative, I would **not fight the multi-card formatting**. Use separate visuals.

### Recommended fix

Create **three separate Card (new) visuals**, one for each narrative measure:

1. `P03 Merchant Evidence Narrative`
2. `P03 Structure Assessment Narrative`
3. `P03 Decision Readout`

Then two smaller separate cards beneath them for:

- `P03 Underwriting Evidence Note`
- `P03 Underwriting Timing Note`

Put one rectangle/background container behind all five so they still look like **one Underwriting rationale panel**.

For each of the three main cards:

- **Title:** Off
- **Category label:** Off
- **Callout/value:** On
- **Word wrap:** On
- **Background:** Off
- **Border:** Off
- **Padding:** reduce as far as Power BI allows
- **Vertical alignment:** Top
- **Text alignment:** Left
- Size each visual's height individually according to its text.

Then use ordinary static text labels immediately above each visual:

**Merchant operating evidence**  
**Requested-structure assessment**  
**Why this outcome**

This gives you precise control over spacing instead of Power BI distributing it for you.

### Why this is much better

Your three narratives naturally have different lengths. For example:

- Merchant evidence might require 3–4 lines.
- Structure assessment might require 4–5 lines.
- Why this outcome might require only 2–3 lines.

A multi-card visual effectively says, “give these cards some shared layout treatment.” We need the opposite: **each narrative gets exactly the vertical space it needs**.

I would lay the available center-left region out roughly:

```text
UNDERWRITING RATIONALE

Merchant operating evidence
[3–4 lines of dynamic text]

Requested-structure assessment
[4–5 lines of dynamic text]

Why this outcome
[2–3 lines of dynamic text]

Evidence basis: ...
Decision snapshot: ...
```

The gaps between sections should only be about **6–10 px**, not the huge blank regions you're getting now.

### One more important formatting point

For the three main Card (new) visuals, don't make the card itself display its measure name. The measure names are technical and they consume vertical space. Use the static section headings above them and let the card contain **only the narrative sentence**.

So yes: **break up the multi-card**. For normal KPIs multi-card is useful; for variable-length narrative text it is the wrong visual. The separate-card approach will solve both the white-space problem and the middle-text cutoff.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f5c84a93-fc32-4c29-9ade-7c70afa6935f"></a>
## Andrew / user · C109-M00528

C109-M00528 · 2026-08-27T22:49:11.047000-04:00 · active path

Preceding visible parent: [C109-M00527](part-21.md#m-6010a079-f75d-4730-8acd-3fb1245ca51a)

<!-- BEGIN_SOURCE_MESSAGE -->
but with single cards it still is dedicating a lot of white space around the visual
<!-- END_SOURCE_MESSAGE -->


<a id="m-5573484d-6da2-400e-a6fc-71ac37ddeaf9"></a>
## Assistant · C109-M00529

C109-M00529 · 2026-08-27T22:49:21.603201-04:00 · active path

Preceding visible parent: [C109-M00528](part-21.md#m-f5c84a93-fc32-4c29-9ade-7c70afa6935f)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. That means the problem is **the Card visual itself**, not the fact that you were using a multi-card. Cards reserve internal callout/container space even after you remove most formatting, so they are a poor fit for paragraph-length narrative.

For this P03 underwriting section, I would stop using cards for the narrative entirely.

### Best option: dynamic text boxes

Power BI text boxes can display **dynamic measure values** while giving you much tighter control over spacing than a Card.

For each narrative section:

1. **Insert → Text box**
2. Type the static heading, for example:
   **Merchant operating evidence**
3. Press Enter.
4. Use the text box's **`+ Value` / dynamic value** option.
5. Select:
   `P03 Merchant Evidence Narrative`
6. Put the dynamic value on the next line.
7. Format the heading bold, around 10–11 pt.
8. Format the dynamic value around 9.5–10 pt, regular.
9. Set the text box background and border off.
10. Resize the text box tightly around the actual content.

Repeat for:

- **Requested-structure assessment** → `P03 Structure Assessment Narrative`
- **Why this outcome** → `P03 Decision Readout`

Then use smaller dynamic text boxes for:

- `P03 Underwriting Evidence Note`
- `P03 Underwriting Timing Note`

This should give you something much closer to:

```text
UNDERWRITING RATIONALE

Merchant operating evidence
The merchant showed a growing operating pattern, averaging $2.1K...

Requested-structure assessment
At the requested structure, operating cash flow covered...

Why this outcome
The selected $18.5K structure...

Evidence basis: partial overall · high data confidence...
Decision snapshot: 7/23/2026...
```

with only the spacing **you** choose between sections.

### Why I prefer this

A card thinks it is displaying a KPI and reserves room for a callout area. A text box thinks it is displaying prose. What we're building here is fundamentally **dynamic prose**, so the text box is the correct visual primitive.

It also lets us do something useful stylistically: **put the subsection heading and narrative in the same object**. That reduces the number of visual objects and makes the whole panel much easier to align.

### If your Power BI build does not expose dynamic values in text boxes

Use a **one-column Table visual** as the fallback:

- put only the narrative measure in Values;
- column header OFF;
- gridlines OFF;
- outline OFF;
- row padding as low as possible;
- word wrap ON;
- background OFF;
- totals OFF.

A single-cell table is surprisingly effective for dynamic narrative because it does not reserve the large callout area that Cards do.

But given the purpose of this page, **dynamic text boxes are my first choice**. They should solve exactly the whitespace problem you're fighting and make the underwriting panel look much more like an intentional executive narrative rather than several oversized KPI containers.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ef4c2a3e-bfb4-48cc-98f2-b154e652760e"></a>
## Andrew / user · C109-M00530

C109-M00530 · 2026-08-27T23:03:00.924000-04:00 · active path

Preceding visible parent: [C109-M00529](part-21.md#m-5573484d-6da2-400e-a6fc-71ac37ddeaf9)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: cb9347ec-6dde-4c60-8ebe-767450c38335.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e664c36f-b7f5-449a-83f4-7a443b6e1319"></a>
## Assistant · C109-M00531

C109-M00531 · 2026-08-27T23:03:04.118322-04:00 · active path

Preceding visible parent: [C109-M00530](part-21.md#m-ef4c2a3e-bfb4-48cc-98f2-b154e652760e)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that screenshot clarifies it. **Do not turn on Q&A or create the local index.** That is unrelated to what we need.

I was too optimistic about the `+ Value` behavior in your Power BI text box. In your build, that route is invoking the Q&A-backed dynamic-value functionality, which is not worth introducing merely to render these narratives.

Click **Close**. Leave Q&A/indexing unchanged.

### Use a one-cell Table visual instead

For each narrative, create a separate **Table** visual. This is the better solution in your current Power BI environment because tables already render our measure-driven text without the Card visual's excessive internal whitespace.

For **Merchant operating evidence**:

1. Insert a **Table** visual.
2. Add only `P03 Merchant Evidence Narrative`.
3. In the field dropdown, choose **Rename for this visual** → `Merchant operating evidence`.
4. Format:
   - **Column headers:** On
   - Header font: roughly 10–11 pt, semibold/bold
   - **Values:** 9–10 pt
   - **Values → Word wrap:** On
   - **Column headers → Word wrap:** On
   - **Grid → Horizontal gridlines:** Off
   - **Grid → Vertical gridlines:** Off
   - **Outline:** None
   - **Totals:** Off
   - **Row padding:** minimum or very low
   - Background: Off
   - Border: Off
   - Visual title: Off
5. Make the single column occupy the entire width.
6. Resize the visual vertically until it fits the narrative tightly.

Then duplicate that visual twice and substitute:

**Requested-structure assessment**  
→ `P03 Structure Assessment Narrative`

**Why this outcome**  
→ `P03 Decision Readout`

This should produce almost exactly what we want:

```text
UNDERWRITING RATIONALE

Merchant operating evidence
The merchant showed a growing operating pattern, averaging $2.1K...

Requested-structure assessment
At the requested structure, the governed capacity assessment was...

Why this outcome
The merchant supported an offer, but the authorized structure reduced...
```

### For the two small notes

I would try putting both measures in a **fourth table visual**:

- `P03 Underwriting Evidence Note`
- `P03 Underwriting Timing Note`

But because adding two measures creates two columns, that may not be ideal. If so, create one additional measure:

```DAX
P03 Underwriting Notes =
VAR _Evidence =
    [P03 Underwriting Evidence Note]
VAR _Timing =
    [P03 Underwriting Timing Note]
RETURN
    _Evidence
        & UNICHAR ( 10 )
        & _Timing
```

Then use a fourth one-cell table:

**Column header:** Off  
**Value:** `P03 Underwriting Notes`  
**Word wrap:** On  
**Font:** ~8–9 pt  
**Row padding:** minimum

That should consume very little height.

### One advantage of the Table approach

This also keeps the underwriting section consistent with the visual language already established on P03. Your `Merchant request`, `Funded terms`, and `Servicing & intervention` sections are table-based. The narrative tables will therefore feel like part of the report rather than a collection of oversized KPI cards.

So the revised build is:

**one static text box** → `Underwriting rationale`

then **three one-cell tables** → the three narratives

then **one compact one-cell table** → evidence + timing notes.

No Q&A, no local index, and no Card whitespace problem.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ac231597-ade6-4803-874f-a4f6c955b82d"></a>
## Andrew / user · C109-M00532

C109-M00532 · 2026-08-27T23:29:41.743000-04:00 · active path

Preceding visible parent: [C109-M00531](part-21.md#m-e664c36f-b7f5-449a-83f4-7a443b6e1319)

**Editorial record note:** 10 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P03_Merchant_001_Baseline.png; P03_Merchant_001_Recession_Energy.png; P03_Merchant_012_Baseline.png; P03_Merchant_012_Recession_Energy.png; P03_Merchant_312_Baseline.png; P03_Merchant_312_Recession_Energy.png; P03_Merchant_738_Baseline.png; P03_Merchant_738_Recession_Energy.png; P03_Merchant_749_Baseline.png; P03_Merchant_749_Recession_Energy.png

<!-- BEGIN_SOURCE_MESSAGE -->
The narratives around the declines seem like there could be an issue.
<!-- END_SOURCE_MESSAGE -->
