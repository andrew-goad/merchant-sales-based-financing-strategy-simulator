# M1.9 Live-Execution Evidence Review and Formal Sign-Off

## Final disposition

**M1.9 — As-of Cash-Flow Feature Engineering is PASSED and ACCEPTED.**

- Accepted package revision: `v0.2R5`
- Accepted methodology: `M1_9_METHOD_V1`
- Annualized-sales basis: `PERSISTED_ROUNDED_90D_AVERAGE`
- Accepted run status: `M1_9_ACCEPTED`
- Acceptance gate: `M1_9_ASOF_CASHFLOW_FEATURES — PASS`
- Database acceptance timestamp: `2026-07-26 09:28:50.824 -0400`
- Independent evidence review date: `2026-07-26`

## Acceptance summary

| Validation area | Final result |
|---|---:|
| Applications | 750 |
| Scenarios | 2 |
| Governed features | 36 |
| Wide feature snapshots | 1,500 |
| Long-form feature values | 54,000 |
| Canonical entities | 55,500 |
| Available feature values | 48,812 |
| Unavailable feature values | 5,188 |
| Complete / partial / blocked snapshots | 1,216 / 50 / 234 |
| Downstream-ready snapshots | 1,266 |
| Positive validations | 66 / 66 PASS |
| Negative controls | 6 / 6 PASS |
| Row-level deterministic mismatches | 0 |
| Annualized-sales identity violations | 0 |
| Failed evidence records | 0 |
| Blocking resolution errors | 0 |
| Downstream analytical rows | 0 |
| Overall master-report status | PASS |

## Deterministic reconciliation

```text
Wide snapshot set
28f285be33ee78b5251ab5fd06fe7536

Long feature-value set
ad08ae9f31b8d491792f4752b34aa178

Combined M1.9 set
7c25acac533179f42789a6daa79d0cc3
```

The stored and independently recomputed values match for all three sets.

## Controlled correction history

The accepted package retains the complete sequence of validation findings and corrections:

1. **Scenario scope:** M1.9 now selects the two scenario IDs represented in the accepted M1.6 physical panels rather than treating scenario codes as globally unique.
2. **CTAS projection:** duplicate `merchant_application_id` output was replaced with an explicit source-quality projection.
3. **Canonical numeric scale:** long-form numeric hash preimages were normalized to the physical `numeric(24,10)` type.
4. **Aggregate FILTER syntax:** filtered `string_agg()` expressions were corrected before scalar `md5()` wrapping.
5. **Annualized-sales identity:** annualized sales now use the persisted rounded 90-day average, a governed 365-day factor, and aligned availability.

The final controlled remediation changed 1,472 wide snapshot values and the corresponding 1,472 long-form values, rebuilt all relevant hashes, and left zero identity, wide/long, or row-hash mismatches.

## Feature and routing evidence

```text
Complete snapshots       1,216
Partial snapshots           50
Blocked snapshots          234
Downstream ready         1,266
Manual review flags        936
Average source confidence 0.914717
```

The matched stress scenario preserves zero baseline deltas and produces directionally adverse portfolio movement, including lower 30- and 90-day sales, lower deposits and available balances, higher withdrawals, more negative-balance exposure, more NSF events, and higher refund/chargeback pressure.

## Stage-boundary confirmation

M1.9 did not create:

- obligation or residual-cash-flow outputs;
- merchant credit-risk components;
- EAD or LGD;
- Expected Loss;
- pricing or offer decisions;
- Module 1 latest or archive contract rows.

## Interpretation boundary

Synthetic, scenario-aware cash-flow feature evidence only. This milestone is not production-calibrated capacity, credit-risk, pricing, loss, accounting, capital, fair-lending, legal, regulatory, or production certification.

## Sign-off

> **M1.9 is formally accepted. M1.10 — Obligations, Liquidity & Residual Cash Flow is authorized.**
