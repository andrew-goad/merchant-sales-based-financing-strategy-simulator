# M2.10 — Portfolio Performance, KPI & Servicing Analytics · v0.2R5_ACCEPTED

> Accepted public projection for **Module 2 / G3 v2.0.0**.

## Purpose

Produce governed portfolio-performance, KPI, servicing, vintage, and risk-adjusted analytics for decision makers.

## Scope

- Portfolio KPI and performance analytics
- Servicing and intervention analytics
- Vintage, segment, and trend analysis
- Power BI-ready governed consumption views

## Governed outputs

- Portfolio KPI evidence
- Servicing analytics
- Governed reporting and consumption views

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
Stage                    M2.10
Status                   ACCEPTED
Revision                 v0.2R5_ACCEPTED
Normal programs          01, 02, 03, 04, 05, 06, 07, 08, 204
Recovery programs        02A, 04A, 04B, 04C, 05A, 05B, 204A, 206A, 206B
Production deployment    NOT AUTHORIZED
Causal claims            NOT SUPPORTED
Module 3                 NOT AUTHORIZED
```
