# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 20 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-19.md)
[Next part](part-21.md)

<a id="m-ec52f08e-fc99-4ddc-92ee-903198d7107d"></a>
## Assistant · C109-M00507

C109-M00507 · 2026-08-27T16:26:52.937979-04:00 · active path

Preceding visible parent: [C109-M00506](part-19.md#m-54f59a76-b3d4-42d9-b0a5-8706a564631c)

<!-- BEGIN_SOURCE_MESSAGE -->
## Recommended construction contract

Build the panel as a **deterministic, rule-based underwriting explanation**, not as Power BI Smart Narrative. The visible text should be generated only from the selected application/scenario’s governed fields and the accepted final decision.

This does **not** create a new underwriting method. `FactApplicationScenario` already carries the operating evidence, capacity, affordability, resilience, integrated risk, comparative loss, economics, and evidence-status fields. M2.1 then evaluates 12 distinct gates and applies explicit fail → blocked → review → eligible precedence. [export reference: filecite | turn69file12 | L962-L996] [export reference: filecite | turn70file2 | L159-L185] The design also preserves the intended separation among evidence usability, verification/fraud, processor continuity, operating behavior, and subsequent credit risk. [export reference: filecite | turn69file13 | L1043-L1066]

### Objects to create or update

Create these in your central measure table under a display folder such as:

```text
03 Application Journey\Underwriting rationale
```

| Object | Type | Treatment |
|---|---|---|
| `P03 Underwriting Context Pass` | Measure | New; hide after QA |
| `P03 Merchant Evidence Narrative` | Measure | New; visible |
| `P03 Structure Assessment Narrative` | Measure | New; visible |
| `P03 Decision Readout` | Measure | **Replace the existing formula** |
| `P03 Underwriting Evidence Note` | Measure | New; visible in small type |
| `P03 Underwriting Timing Note` | Measure | New; visible in small type |
| `P03 Decision Trace` | Measure | New; tooltip only |
| `P03 Underwriting Alt Text` | Measure | New; accessibility |

**No calculated columns are required.** All outputs must change with the selected Merchant/Application and Scenario, so measures are the appropriate object type.

Keep all six measures you already created:

```text
P03 Capacity Display
P03 Coverage Display
P03 Resilience Display
P03 Risk Display
P03 Expected Loss Display
P03 Economics Display
```

They will remain useful for the technical tooltip and QA.

---

# 1. Context-control measure

This confirms that the selected context resolves to exactly one application-scenario row and one final-decision row.

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

Leave this visible until all QA is complete. It should always return `1` on P03 under a valid Merchant and Scenario selection.

---

# 2. Merchant operating-evidence narrative

This is the accessible, behavioral explanation of what made the merchant appear stable, stressed, incomplete, or operationally uncertain.

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

VAR _AverageDailySalesText =
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
        "averaging "
            & _AverageDailySalesText
            & " in eligible sales per day"
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

VAR _AverageBalanceMagnitudeText =
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
            "Average available balance was negative at "
                & _AverageBalanceMagnitudeText
                & ".",
        "Average available balance was "
            & _AverageBalanceMagnitudeText
            & "."
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

A normal result should read like:

> The merchant showed a stable operating pattern, averaging $1.3K in eligible sales per day, with no recent NSF events and no negative-balance days. Average available balance was $15.8K. Processor continuity was stable. The evidence was high-confidence and complete, with clear verification.

This is the visible explanation of the underlying merchant behavior. Resilience remains available technically, but the main page now explains **what produced the resilience interpretation**. The source archetype domain is governed and includes stable, growing, seasonal, volatile, declining, disrupted, thin-history, and insufficient-evidence states. [export reference: filecite | turn71file3 | L53-L57]

---

# 3. Requested-structure assessment narrative

This translates the request into affordability, remaining capacity, liquidity, risk, comparative loss, and risk-adjusted economics.

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

VAR _RiskAdjustedContribution =
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

VAR _ResidualMagnitudeText =
    SWITCH (
        TRUE (),
        ISBLANK ( _ResidualCapacity ), BLANK (),
        ABS ( _ResidualCapacity ) >= 1000000,
            FORMAT ( ABS ( _ResidualCapacity ) / 1000000, "$0.0" ) & "M",
        ABS ( _ResidualCapacity ) >= 1000,
            FORMAT ( ABS ( _ResidualCapacity ) / 1000, "$0.0" ) & "K",
        FORMAT ( ABS ( _ResidualCapacity ), "$#,0" )
    )

VAR _ResidualClause =
    SWITCH (
        TRUE (),
        ISBLANK ( _ResidualCapacity ),
            "with residual capacity unavailable",
        _ResidualCapacity >= 0,
            "leaving "
                & _ResidualMagnitudeText
                & " per day after modeled obligations",
        "producing a "
            & _ResidualMagnitudeText
            & " per-day shortfall"
    )

VAR _LiquidityMagnitudeText =
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
            "a post-financing liquidity buffer of "
                & _LiquidityMagnitudeText,
        "a negative post-financing liquidity position of "
            & _LiquidityMagnitudeText
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

VAR _RiskStatusLabel =
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
            & _RiskStatusLabel
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
    SWITCH (
        TRUE (),
        ISBLANK ( _RiskAdjustedContribution ), BLANK (),

        ABS ( _RiskAdjustedContribution ) >= 1000000,
            IF (
                _RiskAdjustedContribution < 0,
                "($"
                    & FORMAT (
                        ABS ( _RiskAdjustedContribution ) / 1000000,
                        "0.0"
                    )
                    & "M)",
                "$"
                    & FORMAT (
                        _RiskAdjustedContribution / 1000000,
                        "0.0"
                    )
                    & "M"
            ),

        ABS ( _RiskAdjustedContribution ) >= 1000,
            IF (
                _RiskAdjustedContribution < 0,
                "($"
                    & FORMAT (
                        ABS ( _RiskAdjustedContribution ) / 1000,
                        "0.0"
                    )
                    & "K)",
                "$"
                    & FORMAT (
                        _RiskAdjustedContribution / 1000,
                        "0.0"
                    )
                    & "K"
            ),

        IF (
            _RiskAdjustedContribution < 0,
            "($"
                & FORMAT (
                    ABS ( _RiskAdjustedContribution ),
                    "#,0"
                )
                & ")",
            "$"
                & FORMAT (
                    _RiskAdjustedContribution,
                    "#,0"
                )
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
            || ISBLANK ( _RiskAdjustedContribution ),
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

        _CapacitySentence
            & " "
            & _RiskSentence
            & " "
            & _LossSentence
            & " "
            & _EconomicsSentence
    )
```

A favorable result should read approximately:

> At the requested structure, the governed capacity assessment was affordable: modeled operating cash flow covered total daily obligations 1.32x, leaving $80 per day after modeled obligations, with a post-financing liquidity buffer of $52.1K. Integrated risk was low (Tier 1; score 11.0). Comparative expected loss was 4.18%. Risk-adjusted contribution was $1.8K (39.9% annualized), above the governed hurdle.

A weaker result might read:

> At the requested structure, the governed capacity assessment was unaffordable: modeled operating cash flow covered total daily obligations 0.50x, producing a $213 per-day shortfall, with a post-financing liquidity buffer of $9.4K. Integrated risk was moderate (Tier 2; score 29.8). Comparative expected loss was 10.30%. Risk-adjusted contribution was ($183) ((19.9%) annualized), producing negative contribution.

The capacity engine defines coverage as operating cash flow divided by total obligation burden, and residual capacity as operating cash flow after that burden. [export reference: filecite | turn63file4 | L119-L123] Risk-adjusted contribution and annualized return are governed synthetic economics outputs after comparative loss and capital charge; blocked evidence must not produce favorable economic conclusions. [export reference: filecite | turn68file0 | L12-L49]

---

# 4. Replace the existing `P03 Decision Readout`

Keep the existing measure name so you do not create another redundant object. Replace its formula with the following.

Its visual label will become **Why this outcome**.

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

VAR _PrimaryContractReason =
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
        COALESCE ( _PrimaryContractReason, "" )
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
    SWITCH (
        TRUE (),
        ISBLANK ( _RequestedAmount ), BLANK (),
        _RequestedAmount >= 1000000,
            FORMAT ( _RequestedAmount / 1000000, "$0.0" ) & "M",
        _RequestedAmount >= 1000,
            FORMAT ( _RequestedAmount / 1000, "$0.0" ) & "K",
        FORMAT ( _RequestedAmount, "$#,0" )
    )

VAR _FinalOfferAmountText =
    SWITCH (
        TRUE (),
        ISBLANK ( _FinalOfferAmount ), BLANK (),
        _FinalOfferAmount >= 1000000,
            FORMAT ( _FinalOfferAmount / 1000000, "$0.0" ) & "M",
        _FinalOfferAmount >= 1000,
            FORMAT ( _FinalOfferAmount / 1000, "$0.0" ) & "K",
        FORMAT ( _FinalOfferAmount, "$#,0" )
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

This measure keeps `FactFinalDecision` authoritative for the terminal result. It then uses the application-scenario evidence only to explain the binding conditions. M2.3’s physical validation requires structure-ready, counteroffer-review, insufficient-evidence, and policy-decline pricing dispositions to map to their corresponding final outcomes. [export reference: filecite | turn70file3 | L198-L224]

It also handles an important case the earlier table could not explain: a **final offer amount lower than the request**. The narrative will explicitly identify the exposure reduction without claiming a cause that the semantic model does not prove.

---

# 5. Evidence-quality note

This is the compact technical line for an advanced interviewer or reviewer. Keep it visible at the bottom of the panel in smaller, muted text.

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

VAR _FeatureCompleteness =
    SELECTEDVALUE (
        'FactApplicationScenario'[feature_completeness_status]
    )

VAR _CapacityEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[capacity_evidence_status]
    )

VAR _ResilienceEvidence =
    SELECTEDVALUE (
        'FactApplicationScenario'[operating_resilience_evidence_status]
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
            & " · features "
            & LOWER ( COALESCE ( _FeatureCompleteness, "unavailable" ) )
            & " · capacity "
            & LOWER ( COALESCE ( _CapacityEvidence, "unavailable" ) )
            & " · resilience "
            & LOWER ( COALESCE ( _ResilienceEvidence, "unavailable" ) )
            & " · risk "
            & LOWER ( COALESCE ( _RiskEvidence, "unavailable" ) )
            & " · loss "
            & LOWER ( COALESCE ( _LossEvidence, "unavailable" ) )
            & " · economics "
            & LOWER ( COALESCE ( _EconomicsEvidence, "unavailable" ) )
    )
```

Example:

> Evidence basis: partial overall · high data confidence (97.6%) · clear verification · fraud tier 1 · features complete · capacity complete · resilience complete · risk complete · loss partial · economics partial

That line demonstrates that you understand **evidence strength is not binary**. Partial comparative-loss evidence can be usable without being presented as complete, while blocked evidence suppresses conclusions.

---

# 6. Temporal-separation note

This prevents the most serious interpretation error on P03: using later performance as though it were known when the original decision was made.

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

This is especially valuable for merchant `000312`: the page can show a supportable original decision and later severe-shortfall behavior without implying that subsequent performance was available ex ante.

---

# 7. Technical decision trace

Use this **only on a report-page tooltip**. It exposes exact governed lineage to advanced reviewers without placing raw codes in the executive narrative.

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

VAR _UpstreamContractReason =
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
            & COALESCE ( _UpstreamContractReason, "NOT AVAILABLE" )
            & " | Fallback path: "
            & COALESCE ( _FallbackPath, "NOT AVAILABLE" )
    )
```

Add this static statement on the tooltip page:

> **Internal synthetic explanation codes—not customer-facing adverse-action language or production policy.**

The project documentation expressly distinguishes these internal strategy explanation codes from adverse-action notices, compliance determinations, customer communication, or fair-lending conclusions. [export reference: filecite | turn69file2 | L47-L72]

---

# 8. Dynamic alt text

```DAX
P03 Underwriting Alt Text =
VAR _ContextPass =
    [P03 Underwriting Context Pass]

RETURN
    IF (
        _ContextPass <> 1,
        "Underwriting rationale requires one selected merchant application and one scenario.",
        "Underwriting rationale for the selected merchant application and scenario. "
            & [P03 Merchant Evidence Narrative]
            & " "
            & [P03 Structure Assessment Narrative]
            & " Why this outcome: "
            & [P03 Decision Readout]
            & " "
            & [P03 Underwriting Evidence Note]
            & " "
            & [P03 Underwriting Timing Note]
    )
```

Use this measure as the conditional alt text for the grouped rationale panel if Power BI permits the `fx` binding in the property pane. Otherwise use the same wording as a static alt-text template and reference the visible dynamic content.

---

# Visual construction

## Main panel

Create one neutral background shape and place these elements inside it:

```text
UNDERWRITING RATIONALE

Merchant operating evidence
[P03 Merchant Evidence Narrative]

Requested-structure assessment
[P03 Structure Assessment Narrative]

Why this outcome
[P03 Decision Readout]

[P03 Underwriting Evidence Note]
[P03 Underwriting Timing Note]
```

Use **three separate Card (new) visuals** for the three main narratives rather than one multi-row card:

| Visual | Measure | Display label |
|---|---|---|
| Narrative 1 | `P03 Merchant Evidence Narrative` | Merchant operating evidence |
| Narrative 2 | `P03 Structure Assessment Narrative` | Requested-structure assessment |
| Narrative 3 | `P03 Decision Readout` | Why this outcome |

Then use two smaller text cards:

- `P03 Underwriting Evidence Note`
- `P03 Underwriting Timing Note`

### Formatting

Use a neutral white or very light surface. Do not make the rationale panel green, amber, or red; the existing decision card already owns outcome color.

Recommended hierarchy:

- panel heading: same weight as `Monitoring journey`;
- subsection labels: bold, approximately 10–11 pt;
- narrative text: approximately 10–11 pt, left aligned, word wrap on;
- `Why this outcome`: one point larger or slightly bolder;
- evidence and timing notes: approximately 8–9 pt, muted;
- individual card backgrounds and borders: off;
- one subtle outer border or separator for the complete panel;
- visual titles: off;
- category labels: on or replaced with small static labels above each card.

Keep the title **Underwriting rationale**. It is understandable to a general reader while still appropriate for a credit-strategy audience.

---

# Technical tooltip

Create a report-page tooltip named:

```text
P03 - Underwriting Detail
```

Include the measures you already built:

```text
P03 Capacity Display
P03 Coverage Display
P03 Resilience Display
P03 Risk Display
P03 Expected Loss Display
P03 Economics Display
P03 Underwriting Evidence Note
P03 Decision Trace
```

Suggested tooltip layout:

```text
UNDERWRITING DETAIL

Capacity           Coverage           Resilience
[measure]          [measure]          [measure]

Integrated risk    Expected loss      Economics
[measure]          [measure]          [measure]

Evidence basis
[evidence note]

Decision trace
[technical trace]

Internal synthetic explanation—not customer-facing adverse-action language.
```

Assign this tooltip to all three narrative cards. The main canvas remains easy to understand, while an advanced interviewer can hover and inspect exact scores, tiers, evidence statuses, economics, and decision lineage.

Comparative expected loss should remain labeled as synthetic comparative evidence rather than CECL or a production-calibrated estimate; risk-adjusted contribution remains governed synthetic economics rather than audited financial reporting. [export reference: filecite | turn67file0 | L27-L31]

---

# Interaction contract

This is essential.

Only these controls should change the underwriting panel:

- **Merchant/Application**
- **Scenario**

Set **Edit interactions → None** from:

- Monitoring journey
- the combined Account performance chart
- Servicing outcome
- any subsequent lifecycle visual

to every underwriting-rationale object.

That prevents a later account-performance selection from rewriting the original underwriting snapshot. The panel tells the **ex ante decision story**; the lower page tells the **ex post performance story**.

---

# UAT population

Test these known cases before final formatting:

| Selection | Required behavior |
|---|---|
| `000312` / Baseline | Supported decision narrative; later poor performance must not alter original rationale |
| `000738` / Baseline | Counteroffer rationale should explain reduced-structure review |
| `000001` / Baseline | Evidence-blocked narrative; no false zero risk/loss/economic values |
| `000311` / Baseline | Policy-boundary narrative should expose the supported capacity/risk/economic driver |
| `000749` / Baseline versus Recession Energy | Scenario switch should change evidence, assessment, rationale, and decision without cross-scenario bleed |

For each selection confirm:

1. `P03 Underwriting Context Pass = 1`.
2. Blocked evidence never becomes zero.
3. Partial evidence remains usable but is identified as partial.
4. The final outcome from `FactFinalDecision` always controls the rationale branch.
5. A reduced final offer is described as a structure change rather than incorrectly labeled as approval-as-requested.
6. Clicking lifecycle charts does not change the underwriting narrative.
7. The same merchant’s Baseline and Recession Energy narratives remain independently scenario-qualified.

---

## Revised P03 subtitle

Once the new panel is placed, use:

> **Follow one synthetic application from merchant operating evidence and underwriting rationale through decision, funding, performance, monitoring and servicing.**

That makes the page’s upgraded contract immediately clear. The finished P03 will demonstrate not merely that you can display a risk score, but that you can evaluate **evidence quality, merchant operating behavior, cash-flow affordability, residual capacity, liquidity, integrated risk, comparative loss, structure economics, decision governance, and subsequent performance**—and explain all of it without making the page feel complicated.
<!-- END_SOURCE_MESSAGE -->


<a id="m-40c6c659-52d5-41b8-8b46-b3ca625db099"></a>
## Andrew / user · C109-M00508

C109-M00508 · 2026-08-27T16:29:17.472000-04:00 · active path

Preceding visible parent: [C109-M00507](part-20.md#m-ec52f08e-fc99-4ddc-92ee-903198d7107d)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: d252d4f1-284e-45a2-8c02-9b6f675edcd7.png

<!-- BEGIN_SOURCE_MESSAGE -->
Here is my first pass at freeing up space. Please evaluate and then compare what you are trying to add to the space available.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c5a5c512-8846-4796-88ed-71819a735d25"></a>
## Assistant · C109-M00509

C109-M00509 · 2026-08-27T16:36:02.384740-04:00 · active path

Preceding visible parent: [C109-M00508](part-20.md#m-40c6c659-52d5-41b8-8b46-b3ca625db099)

<!-- BEGIN_SOURCE_MESSAGE -->
## Overall assessment

This first pass is successful. You created the correct amount of space **without weakening the application-to-account journey**:

- The daily monitoring-exception table is gone; its essential story remains in `Monitoring journey`.
- Receivable balance and remittance pace now share one time axis.
- Monitoring and servicing remain visible as downstream outcomes.
- The entire center-left region is now available for the underwriting explanation.

The page is materially better balanced. It now has a natural division:

- **Left/main area:** merchant, request, decision, terms, and underwriting rationale.
- **Right area:** what subsequently happened to the funded account.
- **Left rail:** merchant context.
- **Footer:** provenance and interpretation boundaries.

That separation also matches the underlying analytical architecture: operating behavior, evidence usability, verification, processor continuity, capacity, credit risk, and the final decision are distinct stages rather than one opaque score. [export reference: filecite | turn69file13 | L1043-L1066] M2.1 then applies separate gates for evidence, verification, processor continuity, capacity, affordability, resilience, risk, and economics before routing the case. [export reference: filecite | turn70file2 | L170-L185]

## Space available versus what we need

The blank region is approximately:

```text
Width:  about 510–520 pixels
Height: about 345–355 pixels
```

That is enough for the complete underwriting-rationale panel, provided we use a **stacked narrative design** and do not try to retain the seven-column metric table on the main canvas.

A practical vertical budget is:

| Component | Approximate height |
|---|---:|
| `Underwriting rationale` heading | 24 px |
| Merchant operating evidence | 70–80 px |
| Requested-structure assessment | 90–105 px |
| Why this outcome | 55–65 px |
| Evidence-basis note | 35–40 px |
| Decision-timing note | 25–30 px |
| Internal spacing | 25–30 px |
| **Total** | **324–374 px** |

We should target the lower end by keeping each visible narrative concise. The detailed scores, tiers, evidence statuses, and lineage codes belong in the technical tooltip.

### Recommended physical placement

Use approximately:

```text
X: 184–698
Y: 268–618
```

That aligns the panel’s top with `Monitoring journey` and its bottom with the current vertical divider and footer.

Use one subtle outer container, not five boxed cards.

```text
UNDERWRITING RATIONALE

Merchant operating evidence
[dynamic narrative]

Requested-structure assessment
[dynamic narrative]

Why this outcome
[dynamic narrative]

[evidence basis]
[decision timing]
```

A two-column narrative layout would save height but harm readability. At roughly 250 pixels per column, the sentences would wrap excessively. **Full-width stacked sections are the right treatment.**

---

## What it should look like for the current merchant

For merchant `000312` under Baseline, the source evidence supports a concise panel like this:

### Merchant operating evidence

> The merchant showed a growing operating pattern, averaging $2.1K in eligible sales per day, with no recent NSF events or negative-balance days. Average available balance was $32.9K; processor continuity was stable, and the evidence was high-confidence with clear verification.

### Requested-structure assessment

> At the requested structure, operating cash flow covered total obligations 1.32x, leaving $80 per day after modeled obligations and $35.3K in post-financing liquidity. Integrated risk was low, comparative expected loss was 4.18%, and risk-adjusted contribution was $1.8K, or 39.9% annualized.

### Why this outcome

> The selected $18.5K structure—slightly below the $18.6K request—satisfied the governed decision boundary, with no binding condition preventing final authorization.

### Evidence basis

> Partial overall · high data confidence · clear verification · capacity and risk complete · comparative-loss and economics evidence partial.

### Decision timing

> Decision snapshot: 7/23/2026. Later account performance does not rewrite the original underwriting assessment.

Those values are the actual selected application-scenario evidence, including the growing archetype, $2,062.82 daily eligible sales, $32,897.34 average available balance, 1.318828x coverage, $79.79 residual daily capacity, $35,291.04 post-financing liquidity, low Tier 1 risk, 4.177363% comparative loss, and $1,828.15 risk-adjusted contribution. [export reference: filecite | turn71file0 | L7-L7] The final decision record independently authorizes an $18,500 final offer against the $18,600 request. [export reference: filecite | turn72file0 | L7-L7]

That is about the maximum normal-case text density we should allow. It will fit comfortably in the available region at approximately 9.5–10.5 point body text.

---

## The existing measures still have an important role

Do not remove these:

```text
P03 Capacity Display
P03 Coverage Display
P03 Resilience Display
P03 Risk Display
P03 Expected Loss Display
P03 Economics Display
```

They should move to the **Underwriting Detail tooltip**, along with:

```text
P03 Underwriting Evidence Note
P03 Decision Trace
```

That gives the page two levels of communication:

### Main canvas

Anyone can understand:

- how the merchant operated;
- whether the requested obligation was supportable;
- what risk and economics resulted;
- why the governed outcome followed.

### Hover detail

An advanced interviewer can inspect:

- exact capacity and coverage;
- resilience score and tier;
- integrated risk score and tier;
- expected-loss rate;
- risk-adjusted contribution and annualized return;
- evidence completeness;
- exact pricing disposition;
- M2.3 decision reason;
- upstream reason and fallback path.

That is the strongest way to serve both audiences without making the page appear technical or cluttered.

---

## Evaluation of the combined performance chart

Combining the charts was the right decision. It preserves the shared timeline and gives us the space we needed.

I would make four refinements:

1. Rename the title to:

   **Account performance**

2. Rename the legend series:

   ```text
   Receivable balance
   Remittance pace
   ```

   `Balance` and `Pace` are a little too abbreviated for a first-time reader.

3. Add explicit axis titles:

   ```text
   Left:  Remaining receivable
   Right: Remittance pace
   ```

4. Add or retain a dotted **100% expected pace** reference line on the percentage axis.

Do not synchronize the two Y-axes. Dollars and percentage fulfillment have different analytical meanings.

The current visual already demonstrates the intended lifecycle story well: balance declines while remittance pace initially fluctuates, deteriorates, and later recovers toward 100%.

---

## Monitoring journey

The monitoring chart remains worthwhile and is now correctly positioned as **post-decision evidence**.

I would retain it but ensure its tooltip includes:

```text
Monitoring status
Primary monitoring reason
Daily shortfall
Cumulative shortfall
Remittance pace
Days since remittance
```

That preserves the removed daily table’s useful precision without permanently consuming canvas.

The visible selection outline and visual-header icons in the screenshot are editing-state artifacts; the final view should retain the clean, borderless treatment used elsewhere.

---

## Servicing section

The current section works, but it is now the least polished component.

Rename:

```text
Servicing & intervention
```

to:

```text
Servicing outcome
```

A more concise field sequence would be:

```text
Disposition | Treatment | Queue | Exposure | Reason | Lifecycle state
```

P03 needs the concluding account-level servicing result, not all the operational detail already available on P04. Reducing the current redundant `Intervention` and `Action` wording will also eliminate some awkward wrapping.

---

## Revised page narrative

With the underwriting panel inserted, the page will tell this story:

### Left side

> Who is the merchant?  
> What did the merchant request?  
> What did the operating evidence show?  
> Could the merchant carry the requested obligation?  
> What risk, expected loss, and economics resulted?  
> Why was this structure authorized, reviewed, or declined?

### Right side

> What happened after funding?  
> Did remittance remain on pace?  
> How did monitoring status evolve?  
> What servicing outcome followed?

That produces a very strong interview walkthrough:

> “I did not rely on a single score. I began with evidence quality and the merchant’s actual operating behavior—sales level and pattern, liquidity, NSF and negative-balance behavior, processor continuity, and verification. I then assessed obligation coverage, residual cash-flow capacity, post-financing liquidity, integrated risk, comparative expected loss, and risk-adjusted economics. The governed strategy used those dimensions to determine whether the requested structure was supportable, required restructuring, failed policy, or could not be assessed. The right side then shows whether subsequent performance validated or challenged the original decision.”

That is the P03 story that demonstrates **merchant underwriting judgment, credit-strategy design, evidence governance, financial analysis, and lifecycle accountability** without making the page difficult to understand.

## Recommended next construction state

Keep the current layout geometry. Insert the stacked underwriting panel into the center-left blank region and do not restore the seven-column table. The only visible elements in that region should be:

```text
Underwriting rationale
Merchant operating evidence
Requested-structure assessment
Why this outcome
Evidence basis
Decision timing
```

The available space is sufficient, and the resulting page should feel intentional rather than crowded.
<!-- END_SOURCE_MESSAGE -->


<a id="m-abe906c9-e8db-42ce-8752-4a66bde5e74d"></a>
## Andrew / user · C109-M00510

C109-M00510 · 2026-08-27T20:07:55.699000-04:00 · active path

Preceding visible parent: [C109-M00509](part-20.md#m-c5a5c512-8846-4796-88ed-71819a735d25)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 7374aacc-db9d-422d-98d0-bf7bc16936c2.png

<!-- BEGIN_SOURCE_MESSAGE -->
regarding the monitoring journey tooltips, please provide additional advice. here is what i have:
<!-- END_SOURCE_MESSAGE -->


<a id="m-da78d8b8-523b-4372-8358-12ad2d2ce7d1"></a>
## Assistant · C109-M00511

C109-M00511 · 2026-08-27T20:07:59.328749-04:00 · active path

Preceding visible parent: [C109-M00510](part-20.md#m-abe906c9-e8db-42ce-8752-4a66bde5e74d)

<!-- BEGIN_SOURCE_MESSAGE -->
What you have is a good base, but now that we've removed the `Monitoring exceptions` table, the **Monitoring journey tooltip should inherit the useful point-in-time diagnostics that table used to provide**.

You currently have:

- `P03 Monitoring Status`
- `P03 Monitoring Reason`
- `P03 Cumulative Pace Ratio`

I would expand it to **six fields total**, in this order:

| Order | Tooltip field | Purpose |
|---|---|---|
| 1 | **P03 Monitoring Status** | Human-readable state: Current / Watch / Underperforming / Severe shortfall / Paid off |
| 2 | **P03 Monitoring Reason** | Why that state was assigned |
| 3 | **P03 Cumulative Pace Ratio** | How actual remittance compares with expected |
| 4 | **P03 Daily Shortfall** | Today's remittance shortfall |
| 5 | **P03 Cumulative Shortfall** | Accumulated shortfall through that date |
| 6 | **P03 Days Since Remittance** | Whether payment activity has gone stale |

The date itself is already supplied by the X-axis (`monitoring_date`), so **don't add another date measure to Tooltips**.

### We likely need three additional measures

Because implicit measures are disabled, don't drag the raw numerical columns into Tooltips. Create explicit P03 measures consistent with what we've already been doing.

Assuming the physical fields in `FactAccountDaily` are the same ones we used for the former Monitoring exceptions table:

```DAX
P03 Daily Shortfall =
SELECTEDVALUE (
    FactAccountDaily[daily_shortfall_amount]
)
```

Format: **Currency, 2 decimals**.

```DAX
P03 Cumulative Shortfall =
SELECTEDVALUE (
    FactAccountDaily[cumulative_shortfall_amount]
)
```

Format: **Currency, 2 decimals**.

```DAX
P03 Days Since Remittance =
SELECTEDVALUE (
    FactAccountDaily[days_since_last_remittance]
)
```

Format: **Whole number**.

Before creating those, verify those three raw column names against `FactAccountDaily`; I don't want you creating DAX against guessed physical names. If the names differ, send me the corresponding fields and I'll adjust them.

### The resulting hover should read roughly

For the 8/11/2026 point on merchant 000312:

> **8/11/2026**  
> Monitoring status: Watch  
> Monitoring reason: [governed reason]  
> Remittance pace: 92.47%  
> Daily shortfall: $108.43  
> Cumulative shortfall: $262.88  
> Days since remittance: 0

And on the later severe-shortfall portion:

> **10/24/2026**  
> Monitoring status: Severe shortfall  
> Monitoring reason: [governed severe-shortfall reason]  
> Remittance pace: [value]  
> Daily shortfall: [value]  
> Cumulative shortfall: [value]  
> Days since remittance: [value]

That's considerably more useful than the former table because the user can interrogate **the exact point on the journey where something changed**.

### One field I would *not* add

Don't add `P03 Monitoring Status Rank`.

It's already the Y-axis mechanism and has no business meaning beyond positioning the line at:

`0 Paid off → 1 Current → 2 Watch → 3 Underperforming → 4 Severe shortfall`

The visible axis labels already translate it. Showing `Status Rank: 4` in the tooltip would expose implementation plumbing rather than analytical information.

Likewise, don't add receivable balance here. The adjacent **Account performance** chart owns balance and remittance trajectory. Keeping the tooltip focused prevents duplication.

So the final Monitoring journey contract becomes:

**State → Reason → Pace → Daily impact → Accumulated impact → Payment recency**

That is exactly the diagnostic information we sacrificed when we removed the daily warning table, now available at the point where it is most useful. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-84a711ea-6c76-4fc4-ab9e-945283b31867"></a>
## Andrew / user · C109-M00512

C109-M00512 · 2026-08-27T20:10:53.493000-04:00 · active path

Preceding visible parent: [C109-M00511](part-20.md#m-da78d8b8-523b-4372-8358-12ad2d2ce7d1)

<!-- BEGIN_SOURCE_MESSAGE -->
we should have names for our tooltips versus just having the variable names
<!-- END_SOURCE_MESSAGE -->


<a id="m-62a56afa-0a3a-403b-8d4c-0d4d51f51da2"></a>
## Assistant · C109-M00513

C109-M00513 · 2026-08-27T20:10:56.365738-04:00 · active path

Preceding visible parent: [C109-M00512](part-20.md#m-84a711ea-6c76-4fc4-ab9e-945283b31867)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **The tooltip should present business-language labels, not internal measure names.** This matters even more now because the tooltip is replacing the removed Monitoring exceptions table.

For the Monitoring journey visual, I would use these exact display names, in this order:

| Measure | Tooltip display name |
|---|---|
| `P03 Monitoring Status` | **Monitoring status** |
| `P03 Monitoring Reason` | **Reason** |
| `P03 Cumulative Pace Ratio` | **Remittance pace** |
| `P03 Daily Shortfall` | **Daily shortfall** |
| `P03 Cumulative Shortfall` | **Cumulative shortfall** |
| `P03 Days Since Remittance` | **Days since remittance** |

### How to do it

In the visual's **Tooltips** field well, right-click or use the dropdown beside each measure and select:

**Rename for this visual**

Then enter the names above.

Do **not** rename the underlying measures themselves. Keeping names such as `P03 Cumulative Pace Ratio` in the semantic model is useful because they identify the page-specific implementation. We're only separating the **technical model name** from the **reader-facing label**.

### One terminology refinement

I particularly recommend:

**`P03 Cumulative Pace Ratio` → `Remittance pace`**

rather than `Cumulative pace ratio`.

The former tells an executive what the number means. The latter tells a modeler how it was calculated.

Similarly:

**`P03 Monitoring Reason` → `Reason`**

is enough because the tooltip already establishes that the context is Monitoring journey.

The final hover should therefore look something like:

> **10/24/2026**  
> Monitoring status Severe shortfall  
> Reason Severe shortfall  
> Remittance pace 82.6%  
> Daily shortfall $129.68  
> Cumulative shortfall $461.69  
> Days since remittance 6

That's the standard I would use across P03 generally: **semantic-model names can remain technical; every user-facing tooltip label should speak the language of the business question.** [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-f2986051-edc6-45d0-9e8d-26ed07a6252a"></a>
## Andrew / user · C109-M00514

C109-M00514 · 2026-08-27T20:15:03.639000-04:00 · active path

Preceding visible parent: [C109-M00513](part-20.md#m-62a56afa-0a3a-403b-8d4c-0d4d51f51da2)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: fed34bb5-a202-43fc-92a0-c319b53613b4.png

<!-- BEGIN_SOURCE_MESSAGE -->
account performance tooltips: please advise.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bbeed959-9614-4f7c-ba57-b9b635d18c4b"></a>
## Assistant · C109-M00515

C109-M00515 · 2026-08-27T20:15:07.403670-04:00 · active path

Preceding visible parent: [C109-M00514](part-20.md#m-f2986051-edc6-45d0-9e8d-26ed07a6252a)

<!-- BEGIN_SOURCE_MESSAGE -->
For **Account performance**, I would make the tooltip answer a different question than Monitoring journey:

> **Where was the account financially on this date, relative to its expected repayment path?**

You already have the two essential measures on the axes:

- **Receivable balance**
- **Remittance pace**

So don't duplicate those in the Tooltips bucket unless Power BI fails to include both series automatically in the hover. Normally the plotted measures will already appear.

I would add **four diagnostic fields**:

| Order | Measure | Rename for this visual | Why |
|---|---|---|---|
| 1 | `P03 Monitoring Status` | **Monitoring status** | Connects financial performance to governed monitoring state |
| 2 | `P03 Cumulative Actual Remittance` | **Remitted to date** | Shows actual dollars collected |
| 3 | `P03 Cumulative Expected Remittance` | **Expected to date** | Gives the denominator/context for pace |
| 4 | `P03 Cumulative Shortfall` | **Cumulative shortfall** | Quantifies the dollar gap |

The ideal tooltip then reads:

> **10/15/2026**  
> Receivable balance $5,842  
> Remittance pace 86.7%  
> Monitoring status Watch  
> Remitted to date $X,XXX  
> Expected to date $X,XXX  
> Cumulative shortfall $XXX

That tells a complete financial story in six lines.

### Why I prefer this over adding everything

I would **not** put these here:

- `Monitoring reason` — better on Monitoring journey, where the purpose is status diagnosis.
- `Daily shortfall` — too granular for this cumulative lifecycle chart.
- `Days since remittance` — again, Monitoring journey.
- `Monitoring Status Rank` — implementation field, never user-facing.
- final payoff date/status — unnecessary because the chart itself shows balance reaching zero.

This creates a useful separation between your two visuals:

**Account performance tooltip:**  
**Balance → pace → actual vs expected → cumulative financial gap → resulting monitoring state**

**Monitoring journey tooltip:**  
**Status → reason → pace → daily shortfall → cumulative shortfall → remittance recency**

They overlap intentionally on **Monitoring status, Remittance pace, and Cumulative shortfall**, because those are the bridge between financial performance and monitoring classification. Everything else is specialized to the visual's purpose.

### Measures

You may already have the cumulative actual/expected measures from the existing semantic model. We previously established these accepted measures:

- `[Cumulative Actual Remittance As Of]`
- `[Cumulative Expected Remittance As Of]`
- `[Remittance Fulfillment %]`
- `[Remaining Receivable As Of]` [export reference: filecite | turn73file3 | L99-L105]

If the current chart's `Receivable balance` and `Remittance pace` are your P03 date-context measures rather than those `As Of` measures, **don't blindly add the portfolio/as-of measures**. We want all six tooltip values evaluated at the exact `monitoring_date` point.

So first tell me what measures you currently have behind the renamed **Receivable balance** and **Remittance pace** fields. Then I can tell you whether the existing cumulative actual/expected measures are safe here or whether we need P03 point-in-time versions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fd36a25b-db66-4985-8ea8-24785e575109"></a>
## Andrew / user · C109-M00516

C109-M00516 · 2026-08-27T20:16:29.864000-04:00 · active path

Preceding visible parent: [C109-M00515](part-20.md#m-bbeed959-9614-4f7c-ba57-b9b635d18c4b)

<!-- BEGIN_SOURCE_MESSAGE -->
do you mean the Cumulative Actual/Expected Remittance "As Of" you do not say "As Of" above
<!-- END_SOURCE_MESSAGE -->


<a id="m-b1910ef7-bc1b-4d4e-a7a8-be5de6b1aac0"></a>
## Assistant · C109-M00517

C109-M00517 · 2026-08-27T20:16:32.698173-04:00 · active path

Preceding visible parent: [C109-M00516](part-20.md#m-fd36a25b-db66-4985-8ea8-24785e575109)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I meant the existing measures:

- **`[Cumulative Actual Remittance As Of]`**
- **`[Cumulative Expected Remittance As Of]`**

I omitted the `As Of` suffix in the prose because I was describing the desired **user-facing tooltip labels**, not new measure names.

So the mapping I intended is:

| Existing measure | Rename for this visual |
|---|---|
| `[Cumulative Actual Remittance As Of]` | **Remitted to date** |
| `[Cumulative Expected Remittance As Of]` | **Expected to date** |
| `P03 Cumulative Shortfall` | **Cumulative shortfall** |
| `P03 Monitoring Status` | **Monitoring status** |

The accepted semantic definition confirms that the two `As Of` measures represent cumulative actual and cumulative expected remittance at the latest daily account row on/before the applicable as-of date. [export reference: filecite | turn73file3 | L99-L102]

**However, don't add them yet.** My caveat in the previous response matters: your new Account performance chart uses `monitoring_date` directly on the X-axis. We need to make sure those existing `As Of` measures resolve to **each plotted date** rather than continuing to evaluate against some separate observation-date context.

If your current:

- **Receivable balance** is `P03 Receivable Balance`
- **Remittance pace** is `P03 Cumulative Pace Ratio`

or similarly P03-specific measures we created for this date-axis chart, then I would prefer to construct matching P03 cumulative actual/expected tooltip measures using the same date-context pattern.

So yes: **I was referring to the existing `... As Of` measures, but I was intentionally proposing shorter business-facing names in the tooltip.** [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-40ae42e4-eab1-44c3-93b5-f331c6f409d3"></a>
## Andrew / user · C109-M00518

C109-M00518 · 2026-08-27T20:19:27.605000-04:00 · active path

Preceding visible parent: [C109-M00517](part-20.md#m-b1910ef7-bc1b-4d4e-a7a8-be5de6b1aac0)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: fac52aec-e03d-4327-bbc4-a584f5e36dd6.png

<!-- BEGIN_SOURCE_MESSAGE -->
not seeing all of our tooltips 
<!-- END_SOURCE_MESSAGE -->
