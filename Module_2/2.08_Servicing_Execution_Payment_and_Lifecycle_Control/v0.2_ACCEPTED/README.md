# M2.8 — Servicing Execution, Payment & Lifecycle Control · v0.2_ACCEPTED

> Accepted public projection for **Module 2 / G3 v2.0.0**.

## Purpose

Simulate servicing, payment, intervention, and lifecycle-control processes under governed rules.

## Scope

- Simulated servicing and payment events
- Lifecycle transitions
- Intervention and restructuring controls
- Operational evidence and exception handling

## Governed outputs

- Servicing and payment evidence
- Lifecycle state
- Intervention and exception records

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
Stage                    M2.8
Status                   ACCEPTED
Revision                 v0.2_ACCEPTED
Normal programs          01, 02, 03, 04, 05, 06, 07, 08
Recovery programs        188A, 190A, 190B
Production deployment    NOT AUTHORIZED
Causal claims            NOT SUPPORTED
Module 3                 NOT AUTHORIZED
```
