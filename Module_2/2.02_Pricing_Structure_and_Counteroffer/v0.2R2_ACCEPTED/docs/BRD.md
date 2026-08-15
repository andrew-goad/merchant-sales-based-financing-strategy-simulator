# Business Requirements — M2.2 Pricing, Structure & Counteroffer

## Business objective

Apply governed pricing, structure, remittance, and counteroffer logic to eligible merchant applications.

## Governing inputs

- Upstream authority: **M2.1 accepted stage**.
- Accepted source identities and physical lineage must reconcile before stage mutation or reporting.
- Inputs remain deterministic, synthetic, versioned, and auditable.

## In-scope requirements

- Pricing and factor/rate construction
- Term and remittance structure
- Counteroffer and alternative-structure generation
- Affordability, limits, and policy-bound pricing controls

## Required outputs

- Governed price and structure
- Counteroffer alternatives
- Pricing rationale and lineage

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

The accepted output feeds **M2.3 accepted stage**. No downstream stage may reinterpret, bypass, or silently replace this stage's accepted contract or lineage.
