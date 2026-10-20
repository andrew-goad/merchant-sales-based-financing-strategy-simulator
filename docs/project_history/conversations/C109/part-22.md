# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 22 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-21.md)
[Next part](part-23.md)

<a id="m-ece16306-eda6-4e73-9105-fa231bd6471f"></a>
## Assistant · C109-M00533

C109-M00533 · 2026-08-27T23:30:30.005406-04:00 · active path

Preceding visible parent: [C109-M00532](part-21.md#m-ac231597-ade6-4803-874f-a4f6c955b82d)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The decline examples exposed a **real logic problem in the narrative measures**, not a problem in the underlying model.

The clearest case is **Merchant 000012**. Your card correctly says **Policy decline**, but all three narratives currently read as though this were an **insufficient-evidence decline**. The source tells us something more specific: M000012 has `verification_disposition = STOP`, blocked downstream capacity/risk/economics, and a primary reason of `BANK_ACCOUNT_MISMATCH`. [export reference: filecite | turn75file6 | L91-L92] Yet `FactFinalDecision` deliberately classifies both scenarios as `DECLINE_POLICY_AUTHORIZED`, not insufficient evidence. [export reference: filecite | turn75file3 | L53-L54] [export reference: filecite | turn75file0 | L11-L12]

That combination is legitimate. A **failed hard-stop verification gate** can block downstream analytics while still producing a policy decline. Verification and fraud are intentionally separate from cash-flow/risk assessment, and hard-stop evidence is supposed to prevent a strong-looking cash-flow profile from overriding failed verification. [export reference: filecite | turn72file6 | L174-L196]

Our DAX blurred two different states:

> **Evidence unavailable** → cannot make the assessment → Evidence decline

versus

> **Evidence was available and revealed a prohibited condition** → stop assessment → Policy decline

We need to fix that distinction.

## 1. Fix `P03 Decision Readout` first

The main bug is this branch from the current measure:

```DAX
_FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
    || _PricingDisposition = "NO_STRUCTURE_INSUFFICIENT_EVIDENCE"
    || _ContractEvidence = "BLOCKED"
```

**Remove `_ContractEvidence = "BLOCKED"` from that test.**

`BLOCKED` tells us some downstream calculations were suppressed. It does **not** independently tell us why M2.3 declined the application.

The terminal `FactFinalDecision` outcome must always control the first branch.

Use this revised return section. You can keep all of your existing variables above it.

```DAX
RETURN
    SWITCH (
        TRUE (),

        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        /* 1. Terminal evidence decline */
        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            || _PricingDisposition = "NO_STRUCTURE_INSUFFICIENT_EVIDENCE",
            SWITCH (
                TRUE (),

                CONTAINSSTRING ( _ReasonText, "CRITICAL_SOURCE_UNAVAILABLE" ),
                    "Required source evidence was unavailable, so the governed process could not complete a reliable underwriting assessment.",

                _Verification = "INSUFFICIENT_EVIDENCE",
                    "Required verification evidence was insufficient, so the governed process could not complete a reliable underwriting assessment.",

                "Required underwriting evidence was insufficient to complete the governed capacity, risk, loss, and economic assessment."
            ),

        /* 2. Authorized final offer */
        _FinalOutcome = "FINAL_OFFER_AUTHORIZED"
            && _OfferReduced,
            "The merchant supported an offer, but the authorized structure reduced exposure from "
                & _RequestedAmountText
                & " to "
                & _FinalOfferAmountText
                & ". The selected terms satisfied the final governed decision boundary.",

        _FinalOutcome = "FINAL_OFFER_AUTHORIZED",
            "The selected structure satisfied the governed eligibility, risk, and economic boundary; no binding condition prevented final authorization.",

        /* 3. Counteroffer / review */
        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _CapacityIssue
            && _EconomicIssue,
            "The requested structure strained cash-flow capacity and did not meet the economic hurdle. A reduced structure was identified, but governance requires manual authorization before it can become an offer.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _CapacityIssue,
            "The requested structure exceeded sustainable cash-flow capacity. A reduced structure was identified, but governance requires manual authorization before it can become an offer.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _EconomicIssue,
            "The requested structure did not meet the governed economic hurdle. An alternative structure was identified, but it requires manual authorization.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && ( _RiskIssue || _LossIssue ),
            "Risk or comparative loss at the requested structure required a reduced structure and governed review before authorization.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED",
            "A reduced structure was identified, but governance requires manual authorization before it can become an offer.",

        /* 4. Policy decline — hard stops MUST precede downstream blocked analytics */
        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && CONTAINSSTRING ( _ReasonText, "BANK_ACCOUNT_MISMATCH" ),
            "Bank-account verification did not satisfy the governed match requirement. This hard-stop condition prevented offer design, so no financing structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && CONTAINSSTRING ( _ReasonText, "BENEFICIAL_OWNER_FAILURE" ),
            "Beneficial-owner verification did not satisfy the governed requirement. This hard-stop condition prevented offer design, so no financing structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && CONTAINSSTRING ( _ReasonText, "PROCESSOR_MISMATCH" ),
            "Processor verification did not satisfy the governed match requirement. This hard-stop condition prevented offer design, so no financing structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _HardStopIssue,
            "A governed verification or policy hard stop prevented offer design; no financing structure was authorized.",

        /* 5. Policy decline — evaluated credit/economic weaknesses */
        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue
            && _EconomicIssue,
            "The requested structure produced insufficient coverage or negative residual cash flow and did not meet the governed economic hurdle; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue
            && ( _RiskIssue || _LossIssue ),
            "The requested structure exceeded sustainable cash-flow capacity while risk or comparative loss was also elevated; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue,
            "The requested structure exceeded sustainable cash-flow capacity; no supportable alternative structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _EconomicIssue,
            "Risk-adjusted economics did not meet the governed hurdle; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && ( _RiskIssue || _LossIssue ),
            "Integrated risk or comparative loss exceeded the governed boundary; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _OperatingIssue,
            "Operating instability materially weakened the underwriting profile; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED",
            "One or more governed eligibility or structure gates failed; no supportable structure was authorized.",

        "The governed decision requires further review."
    )
```

The important architecture is now:

**Final outcome first → then explain the reason.**

Not:

**See a blocked field → assume evidence decline.**

---

# 2. Fix `P03 Merchant Evidence Narrative`

This has the same conceptual issue.

Right now:

```DAX
_EvidenceBlocked =
    _ContractEvidence = "BLOCKED"
        || _FeatureCompleteness = "BLOCKED"
        || _Verification IN {
            "STOP",
            "INSUFFICIENT_EVIDENCE"
        }
```

and then everything produces:

> Critical source or verification evidence was unavailable or blocked.

But `STOP` is fundamentally different from `INSUFFICIENT_EVIDENCE`.

For 000012 the verification evidence was strong enough to tell us something concrete: **the bank-account match failed**. The downstream calculations were then blocked. [export reference: filecite | turn75file6 | L91-L92]

Add these variables:

```DAX
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
```

Then **replace the beginning of your RETURN** with this precedence:

```DAX
RETURN
    SWITCH (
        TRUE (),

        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        /* Verification actually failed — this is NOT missing evidence */
        _Verification = "STOP"
            && CONTAINSSTRING ( _ReasonText, "BANK_ACCOUNT_MISMATCH" ),
            "The merchant's source data was available, but bank-account verification identified a governed mismatch. That hard-stop condition prevented the remaining underwriting assessment from proceeding.",

        _Verification = "STOP"
            && CONTAINSSTRING ( _ReasonText, "BENEFICIAL_OWNER_FAILURE" ),
            "The merchant's source data was available, but beneficial-owner verification failed a governed requirement. That hard-stop condition prevented the remaining underwriting assessment from proceeding.",

        _Verification = "STOP"
            && CONTAINSSTRING ( _ReasonText, "PROCESSOR_MISMATCH" ),
            "The merchant's source data was available, but processor verification identified a governed mismatch. That hard-stop condition prevented the remaining underwriting assessment from proceeding.",

        _Verification = "STOP",
            "The merchant's source evidence produced a governed verification hard stop. The remaining underwriting assessment was therefore not permitted to proceed.",

        /* Evidence genuinely insufficient */
        _Verification = "INSUFFICIENT_EVIDENCE"
            || CONTAINSSTRING ( _ReasonText, "CRITICAL_SOURCE_UNAVAILABLE" ),
            "Required source or verification evidence was unavailable or insufficient, so the merchant's operating profile could not be treated as decision-ready.",

        /* Other blocked state */
        _ContractEvidence = "BLOCKED"
            || _FeatureCompleteness = "BLOCKED",
            "Required underwriting evidence was blocked before a complete operating assessment could be produced.",

        /* Normal supported case */
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

For **000012**, you should then get something like:

### Merchant operating evidence
> The merchant's source data was available, but bank-account verification identified a governed mismatch. That hard-stop condition prevented the remaining underwriting assessment from proceeding.

That is dramatically better than:

> Critical source or verification evidence was unavailable or blocked.

It tells the viewer **what actually happened**.

---

# 3. Structure assessment is mostly correct — but needs one wording refinement

For 000012, this:

> Capacity and affordability were not reportable under the evidence contract. Integrated risk was not assessable under the evidence contract. Comparative expected loss was not reportable. Risk-adjusted economics were not reportable.

is factually much closer to correct.

But now that the Merchant operating evidence explains **why**, we can make the structure narrative less repetitive.

For a verification hard stop, I would instead say:

> **The verification hard stop occurred before capacity, integrated risk, comparative loss, and risk-adjusted economics could be used for decisioning. No downstream structure assessment is shown.**

That is easier to understand and demonstrates correct sequencing.

At the top of `P03 Structure Assessment Narrative`, add:

```DAX
VAR _Verification =
    SELECTEDVALUE (
        'FactApplicationScenario'[verification_disposition]
    )

VAR _ContractEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[contract_evidence_status]
    )
```

Then at the top of the RETURN:

```DAX
RETURN
    SWITCH (
        TRUE (),

        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        _Verification = "STOP",
            "A governed verification hard stop occurred before capacity, integrated risk, comparative loss, and risk-adjusted economics could be used for decisioning. No downstream structure assessment is shown.",

        _Verification = "INSUFFICIENT_EVIDENCE"
            || _ContractEvidence = "BLOCKED",
            "Required evidence was insufficient to complete the governed capacity, risk, comparative-loss, and economic assessment.",

        _CapacitySentence
            & " "
            & _RiskSentence
            & " "
            & _LossSentence
            & " "
            & _EconomicsSentence
    )
```

There is an important subtlety: if we later encounter `contract_evidence_status = BLOCKED` for some other reason with a **policy decline**, we may want to refine that generic second branch. But the explicit `STOP` branch fixes the cases visible here.

---

# What your examples are telling us

The screenshots actually show that the overall architecture is working very well once this distinction is corrected.

### 000001 — Evidence decline

Both scenarios are genuine terminal insufficient-evidence declines. `FactFinalDecision` explicitly says `NO_STRUCTURE_INSUFFICIENT_EVIDENCE → DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED`. [export reference: filecite | turn74file15 | L600-L602]

So an evidence narrative is appropriate.

### 000012 — Policy decline

This is the key defect we found.

M000012 has an actual **verification STOP / bank-account mismatch**, with downstream capacity, resilience, risk, loss and economics blocked. [export reference: filecite | turn75file6 | L91-L92] M2.3 nevertheless—and correctly—terminates it as **Policy decline**, not evidence decline. [export reference: filecite | turn75file3 | L53-L54]

That is precisely why `BLOCKED ≠ INSUFFICIENT_EVIDENCE`.

### 000312 — Baseline approval → Recession Energy evidence decline

This is a useful scenario story rather than necessarily a defect. Baseline supports an actual funded account; in Recession Energy the final decision becomes `NO_STRUCTURE_INSUFFICIENT_EVIDENCE / DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED`. [export reference: filecite | turn76file0 | L11-L13]

We should let the actual upstream reason determine whether that sentence says source unavailable, verification insufficient, or another evidence deficiency.

### 000738 — Baseline counteroffer review

This looks strong. The final-decision layer really does classify it as `COUNTEROFFER_FOUNDATION_REVIEW / COUNTEROFFER_REVIEW_REQUIRED`. [export reference: filecite | turn76file7 | L96-L98] Its source application evidence is decisionable—high confidence, verification review, volatile operating pattern, low integrated risk, above-hurdle economics—so the current “reduced structure identified, manual authorization required” narrative is directionally appropriate. [export reference: filecite | turn76file13 | L172-L174]

### 000749 — Baseline approval → Recession Energy review

This is also exactly the kind of story the revised P03 should surface: the same merchant moves from a final offer to a counteroffer-review state under stress. The Recession Energy final outcome is explicitly `COUNTEROFFER_REVIEW_REQUIRED`. [export reference: filecite | turn76file9 | L122-L124]

---

## One presentation cleanup

Now that these are functioning as business narratives, rename the visible table headers:

**Current**
- `Merchant operating evidence`
- `Structure assessment narrative`
- `P03 Decision Readout`

**Final**
- **Merchant operating evidence**
- **Requested-structure assessment**
- **Why this outcome**

The internal measures can retain their technical names.

After these three DAX corrections, rerun **000012 Baseline** first. That should be our decisive QA case: I want to see **Policy decline + explicit bank-account verification hard stop + downstream assessment suppressed**, with no sentence suggesting that the decline happened merely because evidence was unavailable.
<!-- END_SOURCE_MESSAGE -->


<a id="m-170a657a-e4ec-4c68-b2bf-1e010445f33b"></a>
## Andrew / user · C109-M00534

C109-M00534 · 2026-08-27T23:33:26.427000-04:00 · active path

Preceding visible parent: [C109-M00533](part-22.md#m-ece16306-eda6-4e73-9105-fa231bd6471f)

<!-- BEGIN_SOURCE_MESSAGE -->
do not give me partial DAX updates. Provide the full updated copy/paste DAX for any measures that need updated.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7ba98b9e-8a80-4ea2-aaa4-a7e698c5c14b"></a>
## Assistant · C109-M00535

C109-M00535 · 2026-08-27T23:33:31.296469-04:00 · active path

Preceding visible parent: [C109-M00534](part-22.md#m-170a657a-e4ec-4c68-b2bf-1e010445f33b)

<!-- BEGIN_SOURCE_MESSAGE -->
Understood. Replace only these **three measures**. Everything else can stay as-is.

## 1. `P03 Merchant Evidence Narrative`

```DAX
P03 Merchant Evidence Narrative =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _Archetype =
    SELECTEDVALUE (
        'FactApplicationScenario'[archetype_code]
    )

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
    SELECTEDVALUE (
        'FactApplicationScenario'[nsf_count_30d]
    )

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
            FORMAT (
                _AverageDailySales / 1000000,
                "$0.0"
            ) & "M",
        ABS ( _AverageDailySales ) >= 1000,
            FORMAT (
                _AverageDailySales / 1000,
                "$0.0"
            ) & "K",
        FORMAT (
            _AverageDailySales,
            "$#,0"
        )
    )

VAR _SalesPhrase =
    IF (
        ISBLANK ( _AverageDailySales ),
        "eligible-sales evidence was unavailable",
        "averaging "
            & _SalesText
            & " in eligible sales per day"
    )

VAR _NSFPhrase =
    SWITCH (
        TRUE (),
        ISBLANK ( _NSFCount ),
            "NSF evidence was unavailable",
        _NSFCount = 0,
            "no recent NSF events",
        _NSFCount = 1,
            "one recent NSF event",
        FORMAT ( _NSFCount, "0" )
            & " recent NSF events"
    )

VAR _NegativeBalancePhrase =
    SWITCH (
        TRUE (),
        ISBLANK ( _NegativeBalanceRate ),
            "negative-balance evidence was unavailable",
        _NegativeBalanceRate = 0,
            "no negative-balance days",
        "negative balances on "
            & FORMAT (
                _NegativeBalanceRate,
                "0.0%"
            )
            & " of the last 30 days"
    )

VAR _BalanceText =
    SWITCH (
        TRUE (),
        ISBLANK ( _AverageAvailableBalance ), BLANK (),
        ABS ( _AverageAvailableBalance ) >= 1000000,
            FORMAT (
                ABS ( _AverageAvailableBalance ) / 1000000,
                "$0.0"
            ) & "M",
        ABS ( _AverageAvailableBalance ) >= 1000,
            FORMAT (
                ABS ( _AverageAvailableBalance ) / 1000,
                "$0.0"
            ) & "K",
        FORMAT (
            ABS ( _AverageAvailableBalance ),
            "$#,0"
        )
    )

VAR _BalanceSentence =
    SWITCH (
        TRUE (),
        ISBLANK ( _AverageAvailableBalance ),
            "Average available balance was unavailable.",
        _AverageAvailableBalance < 0,
            "Average available balance was negative at "
                & _BalanceText
                & ".",
        "Average available balance was "
            & _BalanceText
            & "."
    )

VAR _ProcessorSentence =
    SWITCH (
        _ProcessorContinuity,
        "STABLE",
            "Processor continuity was stable.",
        "MONITORED",
            "Processor continuity required monitoring.",
        "WATCH",
            "Processor continuity was on watch.",
        "DISRUPTED",
            "Processor continuity was disrupted.",
        "UNAVAILABLE",
            "Processor-continuity evidence was unavailable.",
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
            "Verification produced a governed hard-stop condition.",

        _Verification = "INSUFFICIENT_EVIDENCE",
            "Verification evidence was insufficient.",

        "Verification status was unavailable."
    )

RETURN
    SWITCH (
        TRUE (),

        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        _Verification = "STOP"
            && CONTAINSSTRING (
                _ReasonText,
                "BANK_ACCOUNT_MISMATCH"
            ),
            "The merchant's source data was available, but bank-account verification identified a governed mismatch. That hard-stop condition prevented the remaining underwriting assessment from proceeding.",

        _Verification = "STOP"
            && CONTAINSSTRING (
                _ReasonText,
                "BENEFICIAL_OWNER_FAILURE"
            ),
            "The merchant's source data was available, but beneficial-owner verification failed a governed requirement. That hard-stop condition prevented the remaining underwriting assessment from proceeding.",

        _Verification = "STOP"
            && CONTAINSSTRING (
                _ReasonText,
                "PROCESSOR_MISMATCH"
            ),
            "The merchant's source data was available, but processor verification identified a governed mismatch. That hard-stop condition prevented the remaining underwriting assessment from proceeding.",

        _Verification = "STOP",
            "The merchant's source evidence produced a governed verification hard stop. The remaining underwriting assessment was therefore not permitted to proceed.",

        _Verification = "INSUFFICIENT_EVIDENCE"
            || CONTAINSSTRING (
                _ReasonText,
                "CRITICAL_SOURCE_UNAVAILABLE"
            ),
            "Required source or verification evidence was unavailable or insufficient, so the merchant's operating profile could not be treated as decision-ready.",

        _ContractEvidence = "BLOCKED"
            || _FeatureCompleteness = "BLOCKED",
            "Required underwriting evidence was blocked before a complete operating assessment could be produced.",

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

## 2. `P03 Structure Assessment Narrative`

```DAX
P03 Structure Assessment Narrative =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _Verification =
    SELECTEDVALUE (
        'FactApplicationScenario'[verification_disposition]
    )

VAR _ContractEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[contract_evidence_status]
    )

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
    SWITCH (
        TRUE (),
        ISBLANK ( _ResidualCapacity ), BLANK (),
        ABS ( _ResidualCapacity ) >= 1000000,
            FORMAT (
                ABS ( _ResidualCapacity ) / 1000000,
                "$0.0"
            ) & "M",
        ABS ( _ResidualCapacity ) >= 1000,
            FORMAT (
                ABS ( _ResidualCapacity ) / 1000,
                "$0.0"
            ) & "K",
        FORMAT (
            ABS ( _ResidualCapacity ),
            "$#,0"
        )
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
            FORMAT (
                ABS ( _PostFinancingLiquidity ) / 1000000,
                "$0.0"
            ) & "M",
        ABS ( _PostFinancingLiquidity ) >= 1000,
            FORMAT (
                ABS ( _PostFinancingLiquidity ) / 1000,
                "$0.0"
            ) & "K",
        FORMAT (
            ABS ( _PostFinancingLiquidity ),
            "$#,0"
        )
    )

VAR _LiquidityClause =
    SWITCH (
        TRUE (),
        ISBLANK ( _PostFinancingLiquidity ),
            BLANK (),

        _PostFinancingLiquidity >= 0,
            "a post-financing liquidity buffer of "
                & _LiquidityText,

        "a negative post-financing liquidity position of "
            & _LiquidityText
    )

VAR _CapacitySentence =
    IF (
        _CapacityEvidence = "BLOCKED"
            || ISBLANK ( _Coverage ),

        "Capacity and affordability were not reportable under the evidence contract.",

        "At the requested structure, the governed capacity assessment was "
            & _AffordabilityLabel
            & ": modeled operating cash flow covered total daily obligations "
            & FORMAT (
                _Coverage,
                "0.00x"
            )
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
            & FORMAT (
                _RiskTier,
                "0"
            )
            & IF (
                NOT ISBLANK ( _RiskScore ),
                "; score "
                    & FORMAT (
                        _RiskScore,
                        "0.0"
                    ),
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
            & FORMAT (
                _ExpectedLossRate,
                "0.00%"
            )
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
        "ABOVE_HURDLE",
            ", above the governed hurdle.",
        "BELOW_HURDLE",
            ", below the governed hurdle.",
        "NEGATIVE_CONTRIBUTION",
            ", producing negative contribution.",
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
    SWITCH (
        TRUE (),

        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        _Verification = "STOP",
            "A governed verification hard stop occurred before capacity, integrated risk, comparative loss, and risk-adjusted economics could be used for decisioning. No downstream structure assessment is shown.",

        _Verification = "INSUFFICIENT_EVIDENCE",
            "Required verification evidence was insufficient to complete the governed capacity, risk, comparative-loss, and economic assessment.",

        _ContractEvidence = "BLOCKED",
            "Required underwriting evidence was blocked before the governed capacity, risk, comparative-loss, and economic assessment could be completed.",

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

## 3. `P03 Decision Readout`

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
        || CONTAINSSTRING (
            _ReasonText,
            "VERIFICATION_HARD_STOP"
        )
        || CONTAINSSTRING (
            _ReasonText,
            "CRITICAL_SOURCE_UNAVAILABLE"
        )

VAR _CapacityIssue =
    _Affordability = "UNAFFORDABLE"
        || (
            NOT ISBLANK ( _Coverage )
                && _Coverage < 1
        )
        || (
            NOT ISBLANK ( _ResidualCapacity )
                && _ResidualCapacity < 0
        )
        || CONTAINSSTRING (
            _ReasonText,
            "NEGATIVE_RESIDUAL_CASH_FLOW"
        )
        || CONTAINSSTRING (
            _ReasonText,
            "CAPACITY_BURDEN_RISK"
        )

VAR _EconomicIssue =
    _EconomicStatus IN {
        "BELOW_HURDLE",
        "NEGATIVE_CONTRIBUTION"
    }
        || CONTAINSSTRING (
            _ReasonText,
            "BELOW_ECONOMIC_HURDLE"
        )
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
    CONTAINSSTRING (
        _ReasonText,
        "HIGH_COMPARATIVE_LOSS_RATE"
    )
        || CONTAINSSTRING (
            _ReasonText,
            "RECOVERY_SOURCE_CONFLICT"
        )

VAR _OperatingIssue =
    _Archetype IN {
        "VOLATILE",
        "DECLINING",
        "DISRUPTED"
    }
        || CONTAINSSTRING (
            _ReasonText,
            "OPERATING_DISRUPTION"
        )
        || CONTAINSSTRING (
            _ReasonText,
            "DECLINING_CASH_FLOW"
        )
        || CONTAINSSTRING (
            _ReasonText,
            "HIGH_CASH_FLOW_VOLATILITY"
        )
        || CONTAINSSTRING (
            _ReasonText,
            "OPERATING_RESILIENCE_RISK"
        )

VAR _RequestedAmountText =
    IF (
        ISBLANK ( _RequestedAmount ),
        BLANK (),
        FORMAT (
            _RequestedAmount,
            "$#,0"
        )
    )

VAR _FinalOfferAmountText =
    IF (
        ISBLANK ( _FinalOfferAmount ),
        BLANK (),
        FORMAT (
            _FinalOfferAmount,
            "$#,0"
        )
    )

VAR _OfferReduced =
    NOT ISBLANK ( _RequestedAmount )
        && NOT ISBLANK ( _FinalOfferAmount )
        && _FinalOfferAmount < _RequestedAmount - 0.01

RETURN
    SWITCH (
        TRUE (),

        _ContextPass <> 1,
            "Select one merchant application and one scenario.",

        /* Terminal insufficient-evidence outcome */
        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            || _PricingDisposition = "NO_STRUCTURE_INSUFFICIENT_EVIDENCE",

            SWITCH (
                TRUE (),

                CONTAINSSTRING (
                    _ReasonText,
                    "CRITICAL_SOURCE_UNAVAILABLE"
                ),
                    "Required source evidence was unavailable, so the governed process could not complete a reliable underwriting assessment.",

                _Verification = "INSUFFICIENT_EVIDENCE",
                    "Required verification evidence was insufficient, so the governed process could not complete a reliable underwriting assessment.",

                "Required underwriting evidence was insufficient to complete the governed capacity, risk, comparative-loss, and economic assessment."
            ),

        /* Final offer */
        _FinalOutcome = "FINAL_OFFER_AUTHORIZED"
            && _OfferReduced,

            "The merchant supported an offer, but the authorized structure reduced exposure from "
                & _RequestedAmountText
                & " to "
                & _FinalOfferAmountText
                & ". The selected terms satisfied the final governed decision boundary.",

        _FinalOutcome = "FINAL_OFFER_AUTHORIZED",

            "The selected structure satisfied the governed eligibility, risk, and economic boundary; no binding condition prevented final authorization.",

        /* Counteroffer review */
        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _CapacityIssue
            && _EconomicIssue,

            "The requested structure strained cash-flow capacity and did not meet the economic hurdle. A reduced structure was identified, but governance requires manual authorization before it can become an offer.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _CapacityIssue,

            "The requested structure exceeded sustainable cash-flow capacity. A reduced structure was identified, but governance requires manual authorization before it can become an offer.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _EconomicIssue,

            "The requested structure did not meet the governed economic hurdle. An alternative structure was identified, but it requires manual authorization.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && (
                _RiskIssue
                    || _LossIssue
            ),

            "Risk or comparative loss at the requested structure required a reduced structure and governed review before authorization.",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED",

            "A reduced structure was identified, but governance requires manual authorization before it can become an offer.",

        /* Policy decline — explicit verification hard stops */
        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && CONTAINSSTRING (
                _ReasonText,
                "BANK_ACCOUNT_MISMATCH"
            ),

            "Bank-account verification did not satisfy the governed match requirement. This hard-stop condition prevented offer design, so no financing structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && CONTAINSSTRING (
                _ReasonText,
                "BENEFICIAL_OWNER_FAILURE"
            ),

            "Beneficial-owner verification did not satisfy the governed requirement. This hard-stop condition prevented offer design, so no financing structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && CONTAINSSTRING (
                _ReasonText,
                "PROCESSOR_MISMATCH"
            ),

            "Processor verification did not satisfy the governed match requirement. This hard-stop condition prevented offer design, so no financing structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _HardStopIssue,

            "A governed verification or policy hard stop prevented offer design; no financing structure was authorized.",

        /* Policy decline — evaluated underwriting weaknesses */
        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue
            && _EconomicIssue,

            "The requested structure produced insufficient coverage or negative residual cash flow and did not meet the governed economic hurdle; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue
            && (
                _RiskIssue
                    || _LossIssue
            ),

            "The requested structure exceeded sustainable cash-flow capacity while risk or comparative loss was also elevated; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityIssue,

            "The requested structure exceeded sustainable cash-flow capacity; no supportable alternative structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _EconomicIssue,

            "Risk-adjusted economics did not meet the governed hurdle; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && (
                _RiskIssue
                    || _LossIssue
            ),

            "Integrated risk or comparative loss exceeded the governed boundary; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _OperatingIssue,

            "Operating instability materially weakened the underwriting profile; no supportable structure was authorized.",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED",

            "One or more governed eligibility or structure gates failed; no supportable structure was authorized.",

        "The governed decision requires further review."
    )
```

### What these changes fix

After replacing all three formulas:

- **000001** should remain an **Evidence decline**, with an actual insufficiency explanation.
- **000012** should become a **Policy decline driven by the bank-account verification hard stop**, rather than being described as generic missing evidence. Its source row explicitly carries `STOP`, `HARD_STOP`, and `BANK_ACCOUNT_MISMATCH`, while M2.3 authorizes a policy decline. [export reference: filecite | turn75file6 | L91-L92] [export reference: filecite | turn75file3 | L53-L54]
- **000312 Recession Energy** should remain an insufficient-evidence decline because the terminal M2.3 outcome is explicitly `DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED`. [export reference: filecite | turn76file0 | L11-L13]
- **000738 Baseline** and **000749 Recession Energy** should continue to explain counteroffer review rather than being mistaken for declines. [export reference: filecite | turn76file7 | L96-L98] [export reference: filecite | turn76file9 | L122-L124]

After pasting these three, test **000012 Baseline first**. That is the cleanest validation case for whether we have correctly separated **hard-stop policy failure** from **insufficient evidence**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7c04aba0-11d2-4950-854e-71b313eda0ec"></a>
## Andrew / user · C109-M00536

C109-M00536 · 2026-08-27T23:47:40.072000-04:00 · active path

Preceding visible parent: [C109-M00535](part-22.md#m-7ba98b9e-8a80-4ea2-aaa4-a7e698c5c14b)

**Editorial record note:** 10 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P03_Merchant_012_Recession_Energy(1).png; P03_Merchant_312_Baseline(1).png; P03_Merchant_312_Recession_Energy(1).png; P03_Merchant_738_Baseline(1).png; P03_Merchant_738_Recession_Energy(1).png; P03_Merchant_749_Baseline(1).png; P03_Merchant_749_Recession_Energy(1).png; P03_Merchant_001_Baseline(1).png; P03_Merchant_001_Recession_Energy(1).png; P03_Merchant_012_Baseline(1).png

<!-- BEGIN_SOURCE_MESSAGE -->
the required underwriting evidence was blocked... seems like a narrative issue
<!-- END_SOURCE_MESSAGE -->
