# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 23 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-22.md)
[Next part](part-24.md)

<a id="m-dfe89512-07ba-41ea-be83-19547894bc58"></a>
## Assistant · C109-M00537

C109-M00537 · 2026-08-27T23:47:46.259679-04:00 · active path

Preceding visible parent: [C109-M00536](part-22.md#m-7c04aba0-11d2-4950-854e-71b313eda0ec)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **“Required underwriting evidence was blocked…” is technically true but narratively wrong for the main canvas.** `BLOCKED` is an implementation/evidence-contract state. It tells us what the pipeline did, not what an executive or interviewer needs to understand.

For an evidence decline, the page should say something closer to:

> **Merchant operating evidence**  
> Required source or verification evidence was insufficient to support a complete operating assessment.

> **Requested-structure assessment**  
> Because the evidence was insufficient, capacity, integrated risk, comparative loss, and risk-adjusted economics were not evaluated for decisioning.

> **Why this outcome**  
> The available evidence was insufficient to support a reliable underwriting determination, so no offer was authorized.

That is much cleaner. The exact `BLOCKED` statuses still belong in the technical tooltip/evidence note.

This also preserves the important distinction we just fixed: 000012 is a **policy decline caused by an actual verification hard stop**, whereas 000312 Recession Energy and 000001 are terminal insufficient-evidence outcomes. `FactFinalDecision` explicitly classifies 000312 Recession Energy as `NO_STRUCTURE_INSUFFICIENT_EVIDENCE / DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED`. [export reference: filecite | turn76file0 | L11-L13]

I would update the same three measures again, but this time make the main-canvas language business-facing throughout.

## 1. Full replacement — `P03 Merchant Evidence Narrative`

```DAX
P03 Merchant Evidence Narrative =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _FinalOutcome =
    SELECTEDVALUE (
        'FactFinalDecision'[final_decision_outcome_code]
    )

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
        "BLOCKED", "incomplete",
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

        /* Policy hard stop: source evidence existed and revealed a failure */
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

        /* Terminal evidence decline: translate pipeline status into business language */
        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            && CONTAINSSTRING (
                _ReasonText,
                "CRITICAL_SOURCE_UNAVAILABLE"
            ),
            "Required source evidence was unavailable, so the merchant's operating profile could not be assessed reliably enough to support an underwriting decision.",

        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            && _Verification = "INSUFFICIENT_EVIDENCE",
            "Required verification evidence was insufficient, so the merchant's operating profile could not be assessed reliably enough to support an underwriting decision.",

        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED",
            "Required source or verification evidence was insufficient to support a complete and reliable assessment of the merchant's operating profile.",

        /* Other blocked state, without exposing implementation terminology */
        _ContractEvidence = "BLOCKED"
            || _FeatureCompleteness = "BLOCKED",
            "The available underwriting evidence was not sufficient to support a complete operating assessment.",

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

---

## 2. Full replacement — `P03 Structure Assessment Narrative`

```DAX
P03 Structure Assessment Narrative =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

VAR _FinalOutcome =
    SELECTEDVALUE (
        'FactFinalDecision'[final_decision_outcome_code]
    )

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

        "Capacity and affordability could not be evaluated reliably.",

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

        "Integrated risk could not be evaluated reliably.",

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

        "Comparative expected loss could not be evaluated reliably.",

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

        "Risk-adjusted economics could not be evaluated reliably.",

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

        /* Hard stop: downstream assessment intentionally not performed */
        _Verification = "STOP",
            "A governed verification hard stop occurred before capacity, integrated risk, comparative loss, and risk-adjusted economics could be used for decisioning. No downstream structure assessment was performed.",

        /* Terminal insufficient-evidence decline */
        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED",
            "Because the available evidence was insufficient, capacity, integrated risk, comparative loss, and risk-adjusted economics could not be evaluated reliably for decisioning.",

        /* Other incomplete evidence */
        _Verification = "INSUFFICIENT_EVIDENCE"
            || _ContractEvidence = "BLOCKED",
            "The available evidence was insufficient to complete a reliable assessment of capacity, integrated risk, comparative loss, and risk-adjusted economics.",

        /* Normal supported case */
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

## 3. Full replacement — `P03 Decision Readout`

I would make one modest improvement here too. Your current evidence-decline wording is accurate but still sounds like an internal control statement.

Use this full version:

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

        /* Insufficient-evidence outcome */
        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            || _PricingDisposition = "NO_STRUCTURE_INSUFFICIENT_EVIDENCE",

            SWITCH (
                TRUE (),

                CONTAINSSTRING (
                    _ReasonText,
                    "CRITICAL_SOURCE_UNAVAILABLE"
                ),
                    "Required source evidence was unavailable, preventing a reliable underwriting determination. No offer was authorized.",

                _Verification = "INSUFFICIENT_EVIDENCE",
                    "Required verification evidence was insufficient to support a reliable underwriting determination. No offer was authorized.",

                "The available evidence was insufficient to support a reliable underwriting determination, so no offer was authorized."
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

            "A governed verification or policy hard stop prevented offer design, so no financing structure was authorized.",

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

### What I expect after this change

For **000312 — Recession Energy**, instead of three versions of “blocked,” you should get something approximately like:

**Merchant operating evidence**  
> Required source or verification evidence was insufficient to support a complete and reliable assessment of the merchant's operating profile.

**Requested-structure assessment**  
> Because the available evidence was insufficient, capacity, integrated risk, comparative loss, and risk-adjusted economics could not be evaluated reliably for decisioning.

**Why this outcome**  
> The available evidence was insufficient to support a reliable underwriting determination, so no offer was authorized.

That is the right level for the primary report. The technical state—`BLOCKED`, which components were blocked, source confidence, verification disposition, etc.—remains available in the evidence note and eventual tooltip.

And **000012 should remain unchanged in substance**: the merchant evidence should explicitly identify the bank-account mismatch, the structure assessment should explain that the hard stop prevented downstream assessment, and the final rationale should identify the hard-stop policy decline. Its source record supports that exact distinction. [export reference: filecite | turn75file6 | L91-L92]

One final presentation cleanup after the DAX: rename the visible headers from **`Structure assessment narrative` → `Requested-structure assessment`** and **`P03 Decision Readout` → `Why this outcome`**. The technical measure names can remain unchanged.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4b9d1301-6802-4b3b-aa9a-887b8c807887"></a>
## Andrew / user · C109-M00538

C109-M00538 · 2026-08-27T23:54:08.480000-04:00 · active path

Preceding visible parent: [C109-M00537](part-23.md#m-dfe89512-07ba-41ea-be83-19547894bc58)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P03_Merchant_003_Recession_Energy.png; P03_Merchant_003_Baseline.png

<!-- BEGIN_SOURCE_MESSAGE -->
Here is Merchant 003. You see detailed narrative for Baseline, but the same required underwriting was blocked... for recession energy. I need more than that. What evidence was there, and why did it get blocked before a complete operating assessment could be produced. We need that why in our return. It's not sufficient to say, "Required source or verification evidence was insufficient to support a complete operating assessment." as you suggest.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5b355588-e3c2-46fd-9054-bb74ad3d3084"></a>
## Assistant · C109-M00539

C109-M00539 · 2026-08-27T23:55:21.554178-04:00 · active path

Preceding visible parent: [C109-M00538](part-23.md#m-4b9d1301-6802-4b3b-aa9a-887b8c807887)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Merchant 000003 exposes the next issue: **we are still narrating the status of the pipeline rather than the evidence chain that caused that status.**

For 000003 under Recession Energy, we actually know considerably more than the page is saying. The selected row has **high source confidence (98.6%), clear verification, fraud Tier 1, monitored processor continuity, complete feature-completeness status, $28.6K average available balance, no negative-balance days, and no NSFs**. What disappears under stress is the merchant's 30-day eligible-sales measure and annualized eligible sales. Once `avg_daily_eligible_sales_30d` is unavailable, M1.10 cannot estimate daily operating cash flow; the governed capacity engine explicitly sets capacity evidence to `BLOCKED` when that sales measure is null. Coverage and residual cash flow therefore cannot be calculated, and the missing capacity evidence cascades into resilience/risk/loss/economics being unusable. [export reference: filecite | turn78file0 | L6-L6] [export reference: filecite | turn81file4 | L154-L190]

That is the story the page should tell.

## What 000003 should say

### Merchant operating evidence

Instead of:

> Required underwriting evidence was blocked before a complete operating assessment could be produced.

I would want:

> **Source confidence remained high with clear verification, no recent NSF or negative-balance activity, and $28.6K in average available liquidity. Under the stress scenario, however, the 30-day eligible-sales measure required to estimate operating cash flow was unavailable.**

That is both much more informative and much more defensible.

### Requested-structure assessment

Instead of:

> Required underwriting evidence was blocked before the governed capacity, risk, comparative-loss, and economic assessment could be completed.

Use:

> **Without a usable 30-day eligible-sales measure, operating cash flow and payment capacity could not be calculated reliably. The governed process therefore withheld coverage, residual capacity, integrated risk, comparative loss, and risk-adjusted economics rather than treating missing sales evidence as weak performance.**

That last phrase is particularly important. The capacity validation explicitly says blocked evidence must **not be converted into weak merchant performance**. [export reference: filecite | turn79file5 | L187-L191]

### Why this outcome

For 000003 Recession Energy, the final decision is actually **Policy decline**, not an evidence decline. [export reference: filecite | turn82file2 | L84-L88]

So I would want something such as:

> **The stress scenario left the application without a decisionable cash-flow capacity assessment. With required downstream risk and loss evidence unavailable, the governed policy path did not authorize a supportable structure.**

That is materially stronger than:

> One or more governed eligibility or structure gates failed.

---

# There is a model-design issue we should acknowledge

There are really **two levels of “why”**:

1. **Why did capacity become blocked?**  
   We can answer this from `FactApplicationScenario`: `avg_daily_eligible_sales_30d` is blank, and the capacity engine explicitly blocks when that field is unavailable. [export reference: filecite | turn81file4 | L171-L179]

2. **Why did the 30-day eligible-sales feature itself become unavailable?**  
   `FactApplicationScenario` does **not contain enough diagnostic lineage to answer that safely.**

M1.9 actually has richer fields including:

- `pos_quality_status`
- `deposit_quality_status`
- `downstream_routing_status`
- `ready_for_downstream_flag`
- `pos_history_days`
- `deposit_history_days`
- processor outage/degraded rates
- feature-specific `value_status`
- primary/secondary source snapshot IDs

The M1.9 feature layer explicitly maintains these details and even has a long `cashflow_feature_value` table in which each feature carries an `AVAILABLE` / `NOT_AVAILABLE` state and source lineage. [export reference: filecite | turn82file1 | L58-L72]

Those diagnostic fields did **not** all make it into the current `FactApplicationScenario` reporting contract.

So we should not have the Power BI narrative invent something like:

> “Sales became unavailable because of a processor outage.”

We do not currently have enough report-model evidence to prove that for the selected merchant.

What we **can** state credibly is:

> “The 30-day eligible-sales evidence required for capacity assessment was unavailable.”

That is specific, useful and directly proven.

---

# This changes how I would design the narrative DAX

The measure should no longer contain one generic branch such as:

```DAX
_ContractEvidence = "BLOCKED"
```

and then print:

> Required underwriting evidence was blocked...

Instead, it should identify the **first observable break in the evidence chain**.

The precedence should become approximately:

**Verification hard stop**  
→ name the actual hard stop.

**Eligible-sales unavailable**  
→ explain that operating cash flow/capacity cannot be calculated.

**Liquidity evidence unavailable**  
→ identify that liquidity cannot be evaluated.

**Risk evidence unavailable after capacity**  
→ say that capacity evidence existed but integrated-risk evidence was insufficient.

**Comparative-loss evidence unavailable**  
→ identify the loss-evidence limitation.

**Otherwise supported**  
→ give the complete merchant and structure narratives.

That is a much more mature analytical design because the narrative follows the **dependency graph**, not merely the final evidence flag.

---

# Merchant 000003 is an excellent example

Baseline tells one coherent story:

> Volatile merchant → $4.0K/day sales → $99.3K liquidity → clear verification → monitored processor → only 0.73x coverage → $360/day shortfall → moderate risk → 6.37% comparative loss → positive economics → **capacity-driven policy decline**.

Recession Energy tells a fundamentally different story:

> High-confidence evidence and clean bank-behavior indicators remain available → but the required eligible-sales measure disappears → operating cash flow cannot be estimated → capacity cannot be assessed → downstream risk/loss/economics cannot be used → **no supportable stress structure is authorized**.

That is precisely the type of scenario comparison that makes the project sophisticated. The stress scenario is not simply “all metrics get worse.” In some paths, **the evidence itself ceases to support a reliable decision**, and the model refuses to manufacture an answer. The scenario framework was explicitly designed to reduce sales, increase volatility and zero-sales behavior, pressure liquidity and transaction quality, and potentially disrupt processor evidence. [export reference: filecite | turn79file0 | L19-L28]

## What I recommend now

We should revise the narrative measures one more time, but this time around an explicit **evidence-dependency hierarchy** rather than adding another generic blocked-state sentence.

For the fields already present in `FactApplicationScenario`, I would make the narrative distinguish at minimum:

**verification failure → sales/cash-flow evidence unavailable → capacity unavailable → risk unavailable → loss unavailable → economics unavailable.**

And for cases like 000003, we should **still report the evidence that was successfully observed**—high confidence, clear verification, liquidity, NSF/negative-balance behavior, processor status—before explaining the specific missing input.

I would not yet add M1.9 tables to the Power BI carrier just to answer whether the eligible-sales gap came from POS history, source quality, or another upstream condition. That would reopen the semantic boundary. Instead, first make the P03 narrative maximally informative using the evidence already physically exposed. If, after testing the population, we repeatedly find that the reason *why a specific feature became unavailable* is essential, then we can make a bounded case for exposing a very small set of M1.9 diagnostic lineage fields.

And when we update the DAX, I will provide the **complete replacement formulas**, not partial edits.
<!-- END_SOURCE_MESSAGE -->


<a id="m-89f3b460-f931-4502-94f9-40b25bf99eef"></a>
## Andrew / user · C109-M00540

C109-M00540 · 2026-08-27T23:59:26.382000-04:00 · active path

Preceding visible parent: [C109-M00539](part-23.md#m-5b355588-e3c2-46fd-9054-bb74ad3d3084)

<!-- BEGIN_SOURCE_MESSAGE -->
please draft a detailed prompt to deliver back to my original build chat, regarding this: "There is a model-design issue we should acknowledge
There are really **two levels of “why”**:

1. **Why did capacity become blocked?**
    We can answer this from `FactApplicationScenario`: `avg_daily_eligible_sales_30d` is blank, and the capacity engine explicitly blocks when that field is unavailable.  
2. **Why did the 30-day eligible-sales feature itself become unavailable?**
    `FactApplicationScenario` does **not contain enough diagnostic lineage to answer that safely.** 

M1.9 actually has richer fields including:

- `pos_quality_status` 
- `deposit_quality_status` 
- `downstream_routing_status` 
- `ready_for_downstream_flag` 
- `pos_history_days` 
- `deposit_history_days` 
-  processor outage/degraded rates 
-  feature-specific `value_status` 
-  primary/secondary source snapshot IDs 

The M1.9 feature layer explicitly maintains these details and even has a long `cashflow_feature_value` table in which each feature carries an `AVAILABLE` / `NOT_AVAILABLE` state and source lineage. 

Those diagnostic fields did **not** all make it into the current `FactApplicationScenario` reporting contract.

So we should not have the Power BI narrative invent something like:

> “Sales became unavailable because of a processor outage.”

We do not currently have enough report-model evidence to prove that for the selected merchant.

What we **can** state credibly is:

> “The 30-day eligible-sales evidence required for capacity assessment was unavailable.”

That is specific, useful and directly proven."                  It seems like something we should investigate as a potential Module 1/2 issue. Would you agree?
<!-- END_SOURCE_MESSAGE -->
