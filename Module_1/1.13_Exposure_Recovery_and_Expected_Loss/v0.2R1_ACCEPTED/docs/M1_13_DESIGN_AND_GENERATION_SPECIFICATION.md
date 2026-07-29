# M1.13 Design and Generation Specification

## 1. Purpose

M1.13 establishes transparent synthetic foundations for contractual exposure,
path-weighted EAD, recovery/LGD, and comparative expected loss. It is an
analytical evidence layer, not a calibrated credit-loss model.

## 2. Input contracts

- Accepted M1.12 integrated-risk snapshots: 1,500 rows.
- Accepted M1.10 liquidity/capacity snapshots: 1,500 rows.
- Accepted M1.3 application request terms: 750 applications.
- Frozen run-parameter snapshots for EAD timing, paydown, LGD, and tolerances.
- Source-quality, collateral, and guarantee evidence where available.
- Exactly one accepted BASELINE and one accepted RECESSION_ENERGY scenario from
  `M1_V0_2_BASELINE_AND_STRESS` v1.

## 3. Exposure basis

Initial exposure is the requested total repayment amount, representing the
contractual receivable rather than only funded principal.

For each application/scenario, the path runs from day zero through the requested
30-, 60-, or 90-day expected payoff horizon. The scheduled daily payment is
capped to the accepted baseline amount in the adverse scenario. Frozen
paydown-curve shape parameters transform the linear remaining-balance ratio into
a governed exposure path. The terminal path day is explicitly set to zero
exposure so two-decimal daily-remittance rounding cannot leave a synthetic
penny residual beyond the governed payoff horizon.

## 4. Default timing and EAD

Each day is assigned to EARLY, MIDDLE, or LATE. The frozen bucket weight is
divided across the number of days in that bucket. Path-weighted EAD is the sum
of ending exposure multiplied by daily default-timing weight.

## 5. Recovery and LGD

The independent LGD foundation equals:

```text
Industry LGD baseline
+ governed scenario LGD addon
− supported collateral recovery credit
− supported guarantee recovery credit
```

The result is bounded by the frozen LGD floor and cap. The aggregate recovery
credit is bounded by the M1.13 policy cap. Under the adverse scenario, final LGD
cannot improve relative to baseline.

## 6. Comparative expected loss

```text
Simple comparative loss
= synthetic risk proxy × LGD × initial contractual exposure

Schedule-adjusted comparative loss
= synthetic risk proxy × LGD × path-weighted EAD
```

These measures are comparative synthetic evidence only. They are not CECL,
reserves, forecasts, capital, pricing, or production loss estimates.

## 7. Evidence states

- `COMPLETE`: risk evidence is usable and supported recovery evidence is PASS.
- `PARTIAL`: parameter-only or warning-quality recovery evidence.
- `BLOCKED`: integrated-risk evidence is blocked or the synthetic proxy is null.

Blocked rows retain null comparative-loss values and explicit review routing.

## 8. Determinism and acceptance

Expected rows are typed to the physical target schema before hashing. Physical
rows are independently reserialized from stored fields. Generation fails before
commit unless counts, row hashes, and set hashes reconcile exactly.
