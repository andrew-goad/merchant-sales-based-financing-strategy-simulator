# M1.3 v0.2R1 Release Notes


## v0.2R1 validation correction

- Corrects positive control `M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION`.
- Validates the direct `request_path_utilization_factor` control rather than an unmatched raw funding-to-sales group average.
- Retains raw funding-to-sales and minimum-product-floor counts as diagnostics.
- Does not regenerate or modify any of the 750 persisted applications.
- Adds a read-only recovery precheck for the live `M1_3_FAILED` state.
- Preserves the failed acceptance review version 1 and supports a new review version 2 on successful re-finalization.

## Delivered capability

- One deterministic baseline application per accepted M1.2 merchant.
- Exact governed 30/60/90-day expected-payoff mix using largest-remainder allocation.
- Exact governed use-of-proceeds mix.
- Synthetic annual-sales request proxy tied to accepted merchant size.
- Requested funding amount, remittance rate, payback multiple, finance charge, total repayment, horizon, channel, and use of proceeds.
- A mixed request population containing structures on or below the reference sales-linked repayment path and structures above it for downstream capacity review.
- Independent expected-versus-actual canonical hashes over all persisted application columns.
- Forty-two blocking positive checks and three fail-closed negative controls.
- Formal acceptance gate `M1_3_APPLICATION_REQUEST`.

## Design clarification

M1.3 does not pre-approve or force every request to be affordable. A merchant request can be conservative or aggressive. The stage records a coherent requested structure and preserves diagnostic reference-path measures. Actual capacity, affordability, risk, counteroffer, collateral, covenant, price, and approval treatment are downstream responsibilities.

## Known boundaries

- Annual sales in M1.3 is a deterministic request-generation proxy, not observed POS history.
- Expected payoff days are request-horizon bands, not a legal maturity conclusion.
- Payback multiples and finance charges are illustrative request economics, not customer pricing.
- No legal, disclosure, fair-lending, accounting, capital, regulatory, or production conclusion is made.
