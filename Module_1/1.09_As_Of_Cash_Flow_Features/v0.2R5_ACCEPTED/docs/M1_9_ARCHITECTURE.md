# M1.9 Architecture — As-of Cash-Flow Feature Engineering

## Business purpose

M1.9 converts accepted scenario-aware merchant operating histories into governed, application-level cash-flow features as of the accepted application date. It preserves matched BASELINE and RECESSION_ENERGY identities while keeping data confidence, verification/fraud, processor continuity, and future credit risk analytically separate.

```text
Accepted M1.6 POS and deposit scenario histories
                 +
Accepted M1.7 source-quality evidence
                 +
Accepted M1.8 verification / fraud / continuity evidence
                 ↓
      Materialized application and source inputs
                 ↓
   One bounded pass across POS scenario history
                 +
 One bounded pass across deposit scenario history
                 ↓
  1,500 scenario-aware wide feature snapshots
                 +
 54,000 governed long-form feature values
                 ↓
 55,500 canonical entities and acceptance evidence
```

## Physical outputs

| Object | Grain | Expected rows |
|---|---|---:|
| `application_cashflow_feature_snapshot` | run × scenario × application | 1,500 |
| `cashflow_feature_value` | run × scenario × application × feature | 54,000 |
| Canonical universe | wide snapshots + long values | 55,500 |

## Feature families

| Family | Representative evidence |
|---|---|
| Revenue level | 7/30/60/90-day sales and annualized sales |
| Revenue trend | 7-vs-30 and 30-vs-90-day growth |
| Revenue stability | 30/90-day coefficient of variation and zero-sales frequency |
| Seasonality and concentration | seasonality index and largest 30-day share |
| Transaction quality | refund, chargeback, and reversal rates |
| Paired-source reconciliation | deposit-to-sales and POS/deposit reconciliation |
| Liquidity | negative-balance rate, NSF count, balances, and buffer days |
| Processor continuity | outage and degraded-day rates |
| Data confidence | inherited M1.7 source-confidence score |
| Scenario sensitivity | matched baseline/stress deltas across sales, liquidity, processor, and transaction quality |

## Governed separation

```text
Data confidence         describes evidence usability
Verification / fraud    describes identity and fraud evidence
Processor continuity    describes operating continuity
Cash-flow features      describe observed operating behavior
Credit risk             remains a later authorized stage
```

## Performance architecture

- No M1.4–M1.8 blueprint regeneration.
- Accepted physical histories are materialized once.
- The 270,000-row POS panel is scanned once with one bounded rolling-window pass.
- The 270,000-row deposit panel is aggregated once.
- Expensive intermediate tables receive indexes and `ANALYZE` before downstream joins.
- Expected canonical rows are materialized only during generation.
- Validation, acceptance, and reports use persisted rows and independent physical-field hashes.
- JIT is disabled and transaction-local memory/timeouts are governed.

## Stage boundary

M1.9 does not populate the final `merchant_feature_snapshot`, credit-risk snapshots, EAD paths, Expected Loss, pricing, offer outcomes, latest outputs, or archives. It supplies governed feature evidence for subsequent analytical stages.
