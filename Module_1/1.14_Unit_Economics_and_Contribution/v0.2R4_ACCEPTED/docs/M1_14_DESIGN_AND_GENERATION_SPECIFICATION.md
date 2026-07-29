# M1.14 Design and Generation Specification

## 1. Objective

Create deterministic scenario-aware unit-economics evidence for every accepted
application without issuing a final price or decision.

## 2. Accepted inputs

- M1.13 exposure/recovery/loss snapshot: 1,500 rows.
- M1.10 liquidity/capacity snapshot: 1,500 rows.
- M1.3 merchant application request and sales-linked structure.
- M1.2 partner-channel acquisition-cost evidence.
- Accepted M1.6 baseline and recession/energy scenario identities.

## 3. Output grains

```text
Wide snapshot
module1_run_id + scenario_id + merchant_application_id

Long component
module1_run_id + scenario_id + merchant_application_id
+ component_code + component_version
```

## 4. Economic formulas

### Revenue

```text
Gross Finance Revenue = Requested Finance Charge
Gross Finance Charge Rate = Finance Charge / Requested Funding
Annualized Gross Yield = Gross Finance Charge Rate × 365 / Payoff Days
```

### Non-loss costs

```text
Processor Cost = Total Repayment × Processor Cost Rate
Partner Cost = Requested Funding × Governed Partner Acquisition Rate
Funding Cost = Path-Weighted EAD × Annual Funding Rate × Payoff Days / 365
Servicing Cost = Daily Servicing Cost × Payoff Days
               + Total Repayment × Variable Servicing Rate
Operating Cost = Fixed Operating Cost
               + Requested Funding × Variable Operating Rate
Total Non-Loss Cost = sum of all five non-loss costs
```

### Contribution and comparative loss

```text
Contribution Before Comparative Loss
= Gross Finance Revenue − Total Non-Loss Cost

Contribution After Comparative Loss
= Contribution Before Comparative Loss
− Accepted M1.13 Schedule-Adjusted Comparative Expected Loss
```

### Synthetic capital and risk-adjusted contribution

```text
Risk Capital Charge
= Path-Weighted EAD × Capital Allocation Rate
× Annual Cost of Capital × Payoff Days / 365

Independent Risk-Adjusted Contribution
= Contribution After Comparative Loss − Risk Capital Charge
```

### Return and hurdle

```text
Annualized Risk-Adjusted Return
= Risk-Adjusted Contribution / Requested Funding
× 365 / Payoff Days

Hurdle Requirement
= Requested Funding × Annual Hurdle Rate × Payoff Days / 365

Economic Surplus
= Risk-Adjusted Contribution − Hurdle Requirement
```

## 5. Stress interpretation

For `RECESSION_ENERGY`, final risk-adjusted contribution and annualized return
are capped at their matched baseline values. Final economic tier cannot improve
relative to baseline.

## 6. Evidence states

- `COMPLETE`: supported channel cost and non-blocked loss evidence.
- `PARTIAL`: non-blocked economics with a governed default channel cost or
  partial comparative-loss evidence.
- `BLOCKED`: comparative-loss evidence is unavailable; after-loss contribution,
  risk-adjusted return, surplus, and favorable hurdle conclusions remain null.

## 7. Determinism

- Every snapshot and component is hashed from its persisted physical fields.
- Numeric values are cast to target physical precision before hashing.
- Expected and actual canonical sets must reconcile at 22,500 entities with zero
  mismatches before generation commits.

## 8. Performance strategy

- Materialize the accepted 1,500-row matched input once.
- Resolve the approved policy once.
- Avoid self-joins over daily histories.
- Persist, index, and `ANALYZE` before downstream reconciliation.
- Validation reads persisted M1.14 outputs and does not regenerate economics.

## 9. Production boundary

All rates and costs are synthetic governed demonstration assumptions. M1.14 is
not an accounting, pricing, treasury, capital, or production profitability
system.
