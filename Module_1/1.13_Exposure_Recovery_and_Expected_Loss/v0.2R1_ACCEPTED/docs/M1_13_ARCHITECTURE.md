# M1.13 Architecture

```text
Accepted M1.12 integrated risk proxy ─┐
Accepted M1.10 capacity/remittance ───┼─> Materialized application/scenario input
Accepted application request ─────────┤
Collateral / guarantee evidence ──────┤
Frozen EAD / LGD parameters ──────────┘
                                      │
                                      ▼
                           Daily contractual exposure path
                           30 / 60 / 90 day governed horizon
                                      │
                                      ▼
                         Early / middle / late timing weights
                                      │
                                      ▼
                              Path-weighted EAD foundation
                                      │
                    ┌─────────────────┴──────────────────┐
                    ▼                                    ▼
          Recovery/LGD foundation              Comparative loss measures
     industry baseline + stress addon       simple and schedule-adjusted
     − supported recovery credits                      │
                    └─────────────────┬──────────────────┘
                                      ▼
                     Persisted scenario/application snapshot
                                      │
                                      ▼
                   Independent physical-field hash reconstruction
                                      │
                                      ▼
                    Validation → negative controls → acceptance
```

## Performance model

M1.13 reads accepted physical inputs once, materializes 1,500 scenario-aware
application rows, expands only the bounded payoff paths, persists the results,
indexes and analyzes the outputs, and performs one canonical reconciliation.
It does not regenerate M1.4–M1.12 business blueprints.
