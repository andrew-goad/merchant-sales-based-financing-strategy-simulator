# M1.10 Architecture

```text
Accepted M1.9 matched cash-flow features
              +
Accepted M1.7 obligation-source confidence
              +
Accepted M1.8 verification/fraud disposition
              +
M1.3 requested financing structure
              +
M1.2 relationship history
              |
              v
Application-level deterministic obligation population (750 applications, once)
              |
              v
Scenario-aware obligation repricing against matched daily sales evidence
              |
              v
Requested burden = max(rate-based remittance, payoff-horizon requirement)
              |
              v
Operating-cash-flow coverage + residual cash flow + post-financing liquidity
              |
              v
Governed capacity tier, affordability status, review/fallback routing
              |
              v
Canonical row hashes, set hashes, positive/negative controls, acceptance gate
```

The largest scenario-aware population is 1,500 rows. Accepted daily and scenario histories are not rebuilt.
