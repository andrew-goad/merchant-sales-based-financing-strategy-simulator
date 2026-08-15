# M2.5 — Daily Remittance, Exposure & Portfolio Monitoring · v0.2R5_ACCEPTED

> Accepted public projection for **Module 2 / G3 v2.0.0**.

## Purpose

Model daily remittance, exposure, performance, and monitoring state for the synthetic operating portfolio.

## Scope

- Simulated remittance and exposure tracking
- Portfolio limits and concentration monitoring
- Daily performance and capacity measures
- Deterministic latest/archive operating evidence

## Governed outputs

- Daily portfolio monitoring state
- Remittance and exposure measures
- Limit and concentration evidence

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
Stage                    M2.5
Status                   ACCEPTED
Revision                 v0.2R5_ACCEPTED
Normal programs          01, 02, 03, 05, 07, 09, 10, 11, 167
Recovery programs        04, 06, 08, 164A, 166A, 166B
Production deployment    NOT AUTHORIZED
Causal claims            NOT SUPPORTED
Module 3                 NOT AUTHORIZED
```
