# M2.4 — Booking, Funding & Portfolio Activation · v0.2_ACCEPTED

> Accepted public projection for **Module 2 / G3 v2.0.0**.

## Purpose

Create governed simulated booking, funding, and portfolio-activation state from the authorized offer.

## Scope

- Simulated booking and funding state
- Portfolio account activation
- Initial balance, limit, and lifecycle state
- Activation reconciliation and lineage

## Governed outputs

- Activated simulated portfolio account
- Booking/funding evidence
- Initial lifecycle and balance state

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
Stage                    M2.4
Status                   ACCEPTED
Revision                 v0.2_ACCEPTED
Normal programs          01, 02, 03, 04, 05, 06, 07, 08
Recovery programs        156A, 158A, 158B
Production deployment    NOT AUTHORIZED
Causal claims            NOT SUPPORTED
Module 3                 NOT AUTHORIZED
```
