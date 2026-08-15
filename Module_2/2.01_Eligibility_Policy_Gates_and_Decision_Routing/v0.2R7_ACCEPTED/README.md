# M2.1 — Eligibility, Policy Gates & Decision Routing · v0.2R7_ACCEPTED

> Accepted public projection for **Module 2 / G3 v2.0.0**.

## Purpose

Translate certified merchant and application evidence into deterministic eligibility, policy-gate, and transparent decision-routing outcomes.

## Scope

- Eligibility and prohibited-condition evaluation
- Policy limits, concentration rules, and exception handling
- Decision-route assignment with transparent reason codes
- Deterministic evidence lineage from G2-certified inputs

## Governed outputs

- Governed eligibility result
- Policy-gate outcome
- Decision route and reason-code evidence

## Package map

| Area | Purpose |
|---|---|
| [`docs/`](docs/) | BRD, architecture, validation, provenance, correction history, and selected governing records |
| [`catalogs/`](catalogs/) | Public stage facts, source inventories, and selected machine-readable catalogs |
| [`src/current/`](src/current/) | Current normal governed SQL |
| [`src/reporting/`](src/reporting/) | Current read-only reporting SQL, where applicable |
| [`src/recovery/`](src/recovery/) | Contingency-only recovery SQL |
| [`tests/`](tests/) | Public signoff and package-validation summaries |
| [`diagrams/`](diagrams/) | Links to governed architecture and lineage exhibits |

## Governing status

```text
Stage                    M2.1
Status                   ACCEPTED
Revision                 v0.2R7_ACCEPTED
Normal programs          01, 03, 04, 06, 08, 11, 12, 14, 15, 16, 132, 133, 134, 135, 136
Recovery programs        02, 05, 07, 09, 10, 13, 132A, 132C, 134A
Production deployment    NOT AUTHORIZED
Causal claims            NOT SUPPORTED
Module 3                 NOT AUTHORIZED
```
