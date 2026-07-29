# M1.9 Design and Generation Specification

## 1. Objective

Create deterministic, scenario-aware as-of cash-flow features for every accepted application under BASELINE and RECESSION_ENERGY, using only evidence available on or before the application as-of date.

## 2. Inputs

| Input | Accepted source |
|---|---|
| Applications and requested structures | M1.3 |
| POS and settlement scenario history | M1.6 |
| Deposit and liquidity scenario history | M1.6 |
| Source quality and confidence | M1.7 |
| Verification, fraud, and continuity | M1.8 |
| Merchant identity, industry, relationship and processor data | M1.2–M1.4 |
| Governed feature definitions and policy | M1.9 schema/policy extension |

## 3. Time semantics

- `as_of_date` is the accepted application date.
- Observation windows are trailing calendar windows ending at `as_of_date`.
- No source row after `as_of_date` may contribute.
- Scenario deltas are matched against the same application and BASELINE scenario.
- Unavailable or insufficient source evidence produces `NOT_AVAILABLE`, not a synthetic zero.

## 4. Calculation controls

- Growth measures are bounded to `[-1, 5]`.
- Coefficients of variation are bounded to `[0, 10]`.
- Seasonality and ratio measures are capped by governed policy.
- Buffer days are bounded to `[-365, 365]`.
- All baseline scenario deltas equal zero.
- Stress direction is validated at the portfolio level; M1.9 does not force every merchant to deteriorate identically.

## 5. Completeness and routing

| Status | Meaning |
|---|---|
| `COMPLETE` | Core POS and deposit evidence satisfy governed depth and quality requirements |
| `PARTIAL` | Some evidence is warning-level, unavailable, or below full history depth |
| `BLOCKED` | POS evidence is unavailable or M1.8 routing is `STOP` / `INSUFFICIENT_EVIDENCE` |

Feature readiness is separate from creditworthiness. `ready_for_downstream_flag` authorizes later feature consumption; it does not approve credit.

## 6. Long-form feature lineage

Every feature value stores:

- feature code and version;
- source-snapshot lineage;
- observation window;
- availability status;
- value or explicit absence;
- deterministic calculation hash;
- run and scenario identity.

## 7. Canonical reconciliation

Generation creates two independently comparable representations:

```text
Expected canonical rows from generation-time typed blueprints
versus
Actual canonical rows recomputed from persisted physical fields
```

Acceptance requires:

```text
1,500 wide snapshot entities
54,000 long feature-value entities
55,500 combined entities
0 row-level mismatches
stored set hashes = independently recomputed set hashes
```

## 8. Performance controls

The module applies the prior runtime lessons before release:

1. Accepted daily histories are read once.
2. Expensive aggregations are materialized once.
3. Window calculations replace repetitive self-joins.
4. Temporary tables are indexed and analyzed before reuse.
5. Validation does not recalculate business features.
6. Recovery and read-only evidence reconstruction are packaged.
7. Phase notices identify execution progress.

## 9. Boundaries

All outputs are synthetic demonstration evidence. They are not calibrated capacity, PD, loss, pricing, accounting, capital, legal, regulatory, or production decisions.
