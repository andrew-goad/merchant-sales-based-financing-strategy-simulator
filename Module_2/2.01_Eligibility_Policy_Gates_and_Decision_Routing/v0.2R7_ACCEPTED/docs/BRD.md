# Business Requirements — M2.1 Eligibility, Policy Gates & Decision Routing

## Business objective

Translate certified merchant and application evidence into deterministic eligibility, policy-gate, and transparent decision-routing outcomes.

## Governing inputs

- Upstream authority: **M1.17 / G2 certified consumption boundary**.
- Accepted source identities and physical lineage must reconcile before stage mutation or reporting.
- Inputs remain deterministic, synthetic, versioned, and auditable.

## In-scope requirements

- Eligibility and prohibited-condition evaluation
- Policy limits, concentration rules, and exception handling
- Decision-route assignment with transparent reason codes
- Deterministic evidence lineage from G2-certified inputs

## Required outputs

- Governed eligibility result
- Policy-gate outcome
- Decision route and reason-code evidence

## Control requirements

1. Preserve deterministic business keys, grains, counts, and source identities.
2. Fail closed on unresolved source, hash, control, or acceptance findings.
3. Separate normal generation, validation, reporting, and recovery responsibilities.
4. Preserve latest/archive and lineage obligations where defined by the accepted stage.
5. Publish only governed, reproducible outputs with transparent status and reason evidence.
6. Maintain the synthetic, non-production, non-causal analytical boundary.

## Acceptance standard

The stage is accepted only when its governing validation, negative-control, reconciliation, and acceptance evidence pass under the accepted source authority. The public projection does not replace the accepted audit record; it indexes selected evidence and preserves exact current SQL bytes.

## Downstream boundary

The accepted output feeds **M2.2 accepted stage**. No downstream stage may reinterpret, bypass, or silently replace this stage's accepted contract or lineage.
