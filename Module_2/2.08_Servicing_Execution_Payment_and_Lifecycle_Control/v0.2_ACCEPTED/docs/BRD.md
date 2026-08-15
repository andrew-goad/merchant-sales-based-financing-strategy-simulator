# Business Requirements — M2.8 Servicing Execution, Payment & Lifecycle Control

## Business objective

Simulate servicing, payment, intervention, and lifecycle-control processes under governed rules.

## Governing inputs

- Upstream authority: **M2.7 accepted stage**.
- Accepted source identities and physical lineage must reconcile before stage mutation or reporting.
- Inputs remain deterministic, synthetic, versioned, and auditable.

## In-scope requirements

- Simulated servicing and payment events
- Lifecycle transitions
- Intervention and restructuring controls
- Operational evidence and exception handling

## Required outputs

- Servicing and payment evidence
- Lifecycle state
- Intervention and exception records

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

The accepted output feeds **M2.9 accepted stage**. No downstream stage may reinterpret, bypass, or silently replace this stage's accepted contract or lineage.
