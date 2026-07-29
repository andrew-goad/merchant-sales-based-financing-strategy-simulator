# M1.10 Design and Generation Specification

## Business purpose

M1.10 makes merchant capacity explicit before risk translation. It distinguishes existing debt burden, the requested sales-linked structure, operating cash generation, residual cash flow, and post-financing liquidity.

## Critical interpretation rules

- Missing obligations evidence is not equivalent to no obligations.
- Requested daily remittance uses the greater of rate-based and payoff-horizon requirements.
- Stress capacity may remain unchanged or worsen, but may not improve relative to baseline.
- Data confidence, verification/fraud evidence, affordability/capacity, and future credit risk remain separate dimensions.
- All assumptions and outputs are synthetic demonstration evidence.

## Performance design

- Accepted M1.9 feature snapshots are consumed physically.
- Application, relationship, source, verification, and scenario inputs are materialized once.
- Atomic obligations are generated only once per application.
- Scenario burden is aggregated across 1,500 application/scenario rows.
- Persistent tables are indexed and analyzed before reconciliation.
- Validation, acceptance, and reporting use persisted physical evidence and independent hash reconstruction; they do not rebuild generation logic.

## Deterministic reconciliation

Expected typed rows are hashed before insertion. Actual hashes are independently reconstructed from persisted physical fields. The stage fails before commit unless expected and actual entity counts match and row-hash mismatches equal zero.
