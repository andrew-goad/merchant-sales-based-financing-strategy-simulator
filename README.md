# Merchant Sales-Based Financing Strategy Simulator

## Governed Decisioning, Operating Intelligence, Portfolio Strategy, and Enterprise Certification

[![Enterprise Merchant Sales-Based Financing Platform](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.png)](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.png)

[Open the architecture full size](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.png) · [PDF](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.pdf) · [Executive strategy brief](./docs/executive_strategy/From_First_Advance_to_Intelligent_Portfolio_v2.pdf)

> **Current release:** Module 1 / G2 accepted · Module 2 / G3 accepted · Campaign Scale Certification current

This repository is a deterministic, synthetic PostgreSQL 15 platform for merchant sales-based financing. It governs the full chain from acquisition and application evidence through eligibility, pricing, counteroffers, final-offer authorization, simulated activation and operations, servicing, reconciliation, portfolio analytics, strategy simulation, optimization, and enterprise G3 certification.

It is not a production lending system, deployed decision service, calibrated causal model, or autonomous strategy engine. Its purpose is to demonstrate enterprise-grade architecture, analytical discipline, reproducibility, evidence, controls, and release governance.

## Release position

| Boundary | Status |
|---|---|
| Module 1 deterministic evidence | **COMPLETE** |
| `G2_M1_CONTRACT` | **PASS** |
| Module 2 stages M2.1–M2.12 | **ACCEPTED** |
| `G3_M2_CONTRACT` | **PASS** |
| Campaign Scale Certification | **CURRENT — PREPARATION** |
| 750 accepted-fidelity replay | **NOT YET AUTHORIZED** |
| Production deployment | **NOT AUTHORIZED** |

## What Module 2 adds

```text
G2 certified evidence
→ eligibility and policy gates
→ pricing, structure, and counteroffers
→ final-offer authorization
→ simulated booking, funding, and activation
→ daily remittance, exposure, and monitoring state
→ early warning, servicing, intervention, and reconciliation
→ portfolio KPI and servicing analytics
→ strategy simulation and optimization
→ G3 enterprise portfolio certification
```

## Review paths

| Reviewer | Recommended path |
|---|---|
| Executive / hiring leader | [Architecture](./docs/enterprise_architecture/README.md) → [10-page strategy brief](./docs/executive_strategy/README.md) → [Release notes](./RELEASE_NOTES.md) |
| Technical / architecture | [Module and release index](./MODULE_AND_RELEASE_INDEX.md) → [Module 2](./Module_2/README.md) → stage BRDs and accepted source |
| Governance / validation | [Governance guide](./GOVERNANCE_AND_VALIDATION.md) → [BRD and validation index](./docs/BRD_AND_VALIDATION_INDEX.md) → M2.12 acceptance evidence |
| Campaign-scale reviewer | [Campaign Scale Certification](./docs/campaign_scale/README.md) → governance boundary → pre-750 roadmap |
| Development-history reviewer | [Project history](./docs/project_history/README.md) → sanitized transcript archive |
| Repository navigator | [Project artifact map](./PROJECT_ARTIFACT_MAP.md) |

## Principal release metrics

| Measure | Accepted result |
|---|---:|
| Accepted Module 2 stages | 12 / 12 |
| G2 integrated application/origination rows | 1,500 |
| Operational-account rows | 59 |
| Strategy/scope rows | 24 |
| M2.11 positive controls | 120 / 120 PASS |
| M2.11 negative controls | 20 / 20 PASS |
| M2.11 acceptance prerequisites | 45 / 45 PASS |
| M2.12 positive controls | 128 / 128 PASS |
| M2.12 negative controls | 20 / 20 PASS |
| M2.12 acceptance requirements | 48 / 48 PASS |
| M2.12 governed report sets | 24 / 24 PASS |
| G3 contract | `G3_M2_CONTRACT — PASS` |

## Repository map

- [`Module_0/`](./Module_0/) — physical foundation and governed run control.
- [`Module_1/`](./Module_1/) — deterministic merchant, operating, risk, economics, acquisition, contracts, and G2 assurance.
- [`Module_2/`](./Module_2/README.md) — twelve accepted decisioning, operating, portfolio, and G3 stages.
- [`docs/enterprise_architecture/`](./docs/enterprise_architecture/README.md) — current architecture and lineage exhibits.
- [`docs/executive_strategy/`](./docs/executive_strategy/README.md) — Governed Build Edition v3.0 ten-page brief.
- [`docs/campaign_scale/`](./docs/campaign_scale/README.md) — current campaign-readiness and pre-750 governance.
- [`docs/project_history/`](./docs/project_history/README.md) — sanitized development-transparency archive.
- [`docs/BRD_AND_VALIDATION_INDEX.md`](./docs/BRD_AND_VALIDATION_INDEX.md) — direct stage navigation.

## Campaign scale path

The accepted architecture is being prepared for deterministic scale verification:

```text
750 accepted-fidelity replay
→ 2,500 performance shakedown
→ 25,000 full campaign
```

Each step requires a separate fail-closed readiness and authorization gate. Preparation does not imply execution, production fitness, causal inference, or Module 3 authorization.

## Governance principles

```text
Governed
Deterministic
Auditable
Parameter-driven
Evidence-based
Reproducible
Contract-certified
Strategy-enabled
```

## Release and publication

- Release: **Module 2 / G3 v2.0.0**
- Tag: **`module-2-g3-v2.0.0`**
- Visual edition: **Governed Build Edition v3.0**
- Release date: **2026-08-13**

See [Release Notes](./RELEASE_NOTES.md), [GitHub Publication Guide](./GITHUB_PUBLICATION_GUIDE.md), and [Reproducibility and Execution](./REPRODUCIBILITY_AND_EXECUTION.md).

## Interpretation boundary

All data are synthetic. This repository is not a financing offer, production underwriting system, calibrated probability-of-default model, CECL or regulatory-capital model, legal or accounting advice, causal optimization engine, or autonomous decision service. Power BI references describe governed, Power BI-ready views and publication visuals—not a production dashboard deployment.
