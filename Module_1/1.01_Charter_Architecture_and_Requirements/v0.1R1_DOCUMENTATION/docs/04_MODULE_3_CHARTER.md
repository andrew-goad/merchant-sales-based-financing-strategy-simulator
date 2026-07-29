# Module 3 Charter
## Daily Performance, Merchant Health, Line Management, Renewal, and Loss-Mitigation Engine

# 1. Business question

> For each booked facility and advance on each monitoring date, is performance consistent with actual sales, contractual remittance, minimum progress, expected payoff, covenants, collateral, processor continuity, and merchant health—and what action maximizes expected portfolio and relationship value within policy?

# 2. Purpose

Module 3 manages the short-duration account lifecycle at daily frequency. It replaces dependence on monthly DPD with diagnostic performance states and governed exposure actions.

# 3. Primary grains

```text
account performance:
advance_id × performance_date

merchant/facility health and action:
facility_id × review_date

loss-mitigation candidate:
advance_id × review_date × treatment_id
```

# 4. Inputs

- accepted `M2_BOOKED_ADVANCE_V1`;
- facility, advance, collateral, covenant, and compliance-package records;
- daily POS/settlement/remittance observations;
- optional deposit/liquidity updates;
- processor continuity and data-source health;
- covenant test data;
- collateral valuation/condition updates;
- industry and economic monitoring inputs;
- approved lifecycle, line, renewal, and workout policies.

# 5. Processing stages

| Stage | Purpose |
|---|---|
| M3.0 | Monitoring run, source, and policy identity |
| M3.1 | Booked-account and daily-source gatekeeper |
| M3.2 | Expected eligible sales and remittance calculation |
| M3.3 | Actual remittance and balance reconciliation |
| M3.4 | Cumulative fulfillment, progress, slippage, and interruption |
| M3.5 | Minimum-progress checkpoint testing |
| M3.6 | Processor continuity, diversion, and data-outage diagnosis |
| M3.7 | Covenant and collateral monitoring |
| M3.8 | Merchant-health component scoring and state assignment |
| M3.9 | Early-warning event generation |
| M3.10 | Facility line-action candidate generation |
| M3.11 | Renewal/wallet opportunity candidate generation |
| M3.12 | Loss-mitigation candidate generation and expected-value comparison |
| M3.13 | Final recommended action and escalation |
| M3.14 | Latest/archive, transitions, evidence, and acceptance |

# 6. Core daily measures

```text
Expected Daily Remittance
= Actual Eligible Daily Sales × Contractual Remittance Percentage
```

```text
Cumulative Remittance Fulfillment
= Actual Cumulative Remittance
÷ Expected Cumulative Remittance Based on Actual Sales
```

```text
Repayment Progress Index
= Actual Repaid Percentage
÷ Expected Repaid Percentage at Current Account Age
```

```text
Interruption Severity
= Consecutive Missed Expected Remittance Days
÷ Expected Payoff Horizon Days
```

```text
Projected Payoff Slippage
= Current Projected Payoff Date − Original Expected Payoff Date
```

# 7. Diagnostic performance states

- `AHEAD_OF_PATH`;
- `CURRENT`;
- `SALES_DECLINE_COMPLIANT`;
- `EARLY_REMITTANCE_SHORTFALL`;
- `MATERIAL_CUMULATIVE_SHORTFALL`;
- `SUSTAINED_INTERRUPTION`;
- `PROCESSOR_OR_DATA_REVIEW`;
- `SUSPECTED_RECEIVABLES_DIVERSION`;
- `COVENANT_WARNING`;
- `COVENANT_BREACH`;
- `WORKOUT`;
- `DEFAULT`;
- `CHARGE_OFF`;
- `PAID_OFF`;
- `RENEWED`.

A low-sales merchant remitting the correct share must not be treated the same as a merchant with continuing sales but missing remittance.

# 8. Merchant-health dimensions

- sales level, trend, seasonality, and volatility;
- liquidity and deposit behavior;
- remittance compliance and payoff progress;
- processor continuity and data confidence;
- refunds, chargebacks, and fraud signals;
- covenant and collateral status;
- industry/geographic outlook;
- prior advance and relationship performance;
- wallet-share opportunity;
- current facility utilization and concentration impact.

Health states:

```text
GROWTH_OPPORTUNITY
HEALTHY
WATCH
DETERIORATING
DISTRESSED
WORKOUT
EXIT
```

# 9. Line-management actions

- increase line;
- temporary seasonal increase;
- maintain;
- reduce availability;
- temporary freeze;
- permanent reduction;
- close after payoff;
- immediate close/exit subject to approved policy.

Actions are recommendations until execution evidence is recorded.

# 10. Loss-mitigation treatments

Candidates may include:

- reduced remittance percentage;
- temporary relief;
- extension or revised expected payoff;
- revised schedule where contractually available;
- cash reserve application;
- additional collateral/guarantee;
- covenant waiver with conditions;
- refinance/restructure;
- settlement;
- collateral enforcement;
- controlled exit;
- charge-off recommendation.

Candidate value:

```text
Expected Treatment Value
= Expected Cure Cash Flows
+ Expected Recovery
+ Expected Retained Relationship Value
− Concession Cost
− Operational/Legal Cost
− Time Value and Additional Expected Loss
```

# 11. Owned logical tables

- `daily_remittance_performance`;
- `minimum_progress_checkpoint_result`;
- `processor_continuity_event`;
- `covenant_test_result`;
- `collateral_monitoring_snapshot`;
- `merchant_health_snapshot`;
- `early_warning_event`;
- `line_management_candidate`;
- `line_management_action`;
- `renewal_candidate`;
- `loss_mitigation_candidate`;
- `workout_action`;
- `performance_state_transition`;
- `module3_latest`;
- `module3_archive`.

# 12. Output contracts

- `M3_ACCOUNT_DAY_PERFORMANCE_V1`;
- `M3_MERCHANT_HEALTH_ACTION_V1`;
- `M3_LOSS_MITIGATION_RECOMMENDATION_V1`;
- `M3_RELATIONSHIP_OPPORTUNITY_V1`.

# 13. Exclusions

Module 3 does not:

- decide legal default or enforce a contract without approved policy;
- execute bank withdrawals, line changes, or collections;
- produce accounting charge-off entries;
- use conventional 30/60/90 DPD as the sole status;
- construct enterprise macro scenarios;
- certify workout or legal-enforcement actions.

# 14. P0 validation

- daily expected/actual/cumulative balances reconcile;
- lower sales with correct percentage remittance maps to compliant deterioration, not withheld-payment default;
- data outage and processor switch have separate states;
- progress measures normalize across 30/60/90-day horizons;
- state transitions are valid and reproducible;
- one final recommended action per facility/review date;
- line increases pass capacity, performance, concentration, and compliance checks;
- workout candidates compare cure, recovery, cost, time, and relationship value;
- covenant and collateral changes affect intended health/action components;
- no post-review data leaks into the recommendation.

# 15. Acceptance gate

Module 3 is accepted when it can diagnose performance cause, assign a coherent state, and recommend a governed line, renewal, mitigation, or exit action from daily evidence without relying on monthly delinquency conventions.
