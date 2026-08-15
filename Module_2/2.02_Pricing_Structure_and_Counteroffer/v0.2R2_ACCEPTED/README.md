# M2.2 — Pricing, Structure & Counteroffer · v0.2R2_ACCEPTED

> Accepted public projection for **Module 2 / G3 v2.0.0**.

## Purpose

Apply governed pricing, structure, remittance, and counteroffer logic to eligible merchant applications.

## Scope

- Pricing and factor/rate construction
- Term and remittance structure
- Counteroffer and alternative-structure generation
- Affordability, limits, and policy-bound pricing controls

## Governed outputs

- Governed price and structure
- Counteroffer alternatives
- Pricing rationale and lineage

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
Stage                    M2.2
Status                   ACCEPTED
Revision                 v0.2R2_ACCEPTED
Normal programs          01, 02, 05, 06, 07, 08, 09, 10, 140
Recovery programs        03, 04, 140A, 142A
Production deployment    NOT AUTHORIZED
Causal claims            NOT SUPPORTED
Module 3                 NOT AUTHORIZED
```
