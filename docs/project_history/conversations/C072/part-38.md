# PostgreSQL M1.14 Execution

Part 38 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-37.md)
[Next part](part-39.md)

<a id="m-51fa913e-cba4-4cdc-81d7-b6f322ffb1e1"></a>
## Andrew / user · C072-M00547

C072-M00547 · 2026-08-15T09:34:34.013000-04:00 · active path

Preceding visible parent: [C072-M00546](part-37.md#m-a78a72fd-54cf-4144-9069-9043f054ad4c)

**Editorial record note:** Attachment references: Pasted markdown(20260815-133424).md

<!-- BEGIN_SOURCE_MESSAGE -->
give me the full updated markdown with that module 1 architecture update we just discussed. here is the current full markdown: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-9fc85792-88fc-48f1-8ae1-9280f13e84a1"></a>
## Assistant · C072-M00548

C072-M00548 · 2026-08-15T09:43:56.047171-04:00 · active path

Preceding visible parent: [C072-M00547](part-38.md#m-51fa913e-cba4-4cdc-81d7-b6f322ffb1e1)

<!-- BEGIN_SOURCE_MESSAGE -->
Below is the full replacement `README.md`. It preserves the existing release metrics, stage navigation, governance boundaries, validator instructions, and publication metadata, while replacing the Module-2-first/collapsed-Module-1 treatment with two fully visible, full-width lineage exhibits and an explicit G2-to-G3 connection. [export reference: filecite | turn218file0 | L138-L175] [export reference: filecite | turn218file0 | L222-L238]

````markdown
# Merchant Sales-Based Financing Strategy Simulator

## Governed Decisioning, Operating Intelligence, Portfolio Strategy, and Enterprise Certification

![Enterprise Merchant Sales-Based Financing Platform (historical reference: `./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.png`; referenced bytes not established here)](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.png)

Open the architecture full size (historical reference: `./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.png`; referenced bytes not established here) ·
Architecture PDF (historical reference: `./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform_v2.pdf`; referenced bytes not established here) ·
Executive strategy brief (historical reference: `./docs/executive_strategy/From_First_Advance_to_Intelligent_Portfolio_v2.pdf`; referenced bytes not established here) ·
Page gallery (historical reference: `./docs/executive_strategy/pages_v2/README.md`; referenced bytes not established here) ·
[Module 2 / G3 release](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/module-2-g3-v2.0.0)

Module 1 / G2 lineage (historical reference: `./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png`; referenced bytes not established here) ·
Module 2 / G3 lineage (historical reference: `./docs/enterprise_architecture/Module_2_Governed_Decisioning_Operations_Portfolio_%26_G3_Acceptance_Lineage.png`; referenced bytes not established here)

> **Current governed position:** Module 1 / G2 accepted · Module 2 / G3 accepted · `G2_M1_CONTRACT = PASS` · `G3_M2_CONTRACT = PASS` · Campaign Scale Certification current

This repository is a deterministic, synthetic PostgreSQL 15 platform for
merchant sales-based financing tied to daily point-of-sale activity and
sales-linked repayment.

The platform governs the complete analytical and strategy path from
acquisition-source evidence and merchant applications through cash-flow,
capacity, risk, economics, eligibility, pricing, counteroffers, final-offer
authorization, simulated activation and operating states, servicing,
reconciliation, portfolio analytics, strategy comparison, optimization, and
enterprise G3 certification.

It is not a production lending system, deployed decision service, calibrated
causal model, or autonomous strategy engine. Its purpose is to demonstrate
enterprise-grade architecture, analytical discipline, reproducibility,
validation, evidence, controls, and governed handoffs.

---

## Executive Visual Story

<table>
<tr>
<td width="50%" valign="top">

<a href="./docs/executive_strategy/pages_v2/02_launch_with_discipline.png">
<img src="./docs/executive_strategy/pages_v2/02_launch_with_discipline.png" alt="Launch With Discipline">
</a>

<strong>Launch With Discipline</strong>

Capability advances only after the preceding boundary is validated, evidenced,
and contract-certified.

</td>
<td width="50%" valign="top">

<a href="./docs/executive_strategy/pages_v2/05_from_decision_to_enterprise_certification.png">
<img src="./docs/executive_strategy/pages_v2/05_from_decision_to_enterprise_certification.png" alt="From Decision to Enterprise Certification">
</a>

<strong>From Decision to Enterprise Certification</strong>

Module 2 converts accepted G2 evidence into governed offers, simulated
operations, portfolio strategy, and an accepted G3 consumption boundary.

</td>
</tr>
<tr>
<td width="50%" valign="top">

<a href="./docs/executive_strategy/pages_v2/08_proof_before_scale.png">
<img src="./docs/executive_strategy/pages_v2/08_proof_before_scale.png" alt="Proof Before Scale">
</a>

<strong>Proof Before Scale</strong>

Every stage must generate, validate, challenge, reconcile, and certify before
the enterprise boundary advances.

</td>
<td width="50%" valign="top">

<a href="./docs/executive_strategy/pages_v2/10_the_opportunity_ahead.png">
<img src="./docs/executive_strategy/pages_v2/10_the_opportunity_ahead.png" alt="The Opportunity Ahead">
</a>

<strong>The Opportunity Ahead</strong>

The next governed proof expands accepted-fidelity replay through performance
shakedown and full-campaign certification.

</td>
</tr>
</table>

Open the complete ten-page executive strategy brief (historical reference: `./docs/executive_strategy/From_First_Advance_to_Intelligent_Portfolio_v2.pdf`; referenced bytes not established here) ·
View the ten-page contact sheet (historical reference: `./docs/executive_strategy/from_first_advance_to_intelligent_portfolio_contact_sheet_v2.png`; referenced bytes not established here)

---

## Release Position

| Governed boundary | Current status |
|---|---|
| Module 0 physical foundation and run control | **ACCEPTED** |
| Module 1 deterministic evidence | **COMPLETE** |
| `G2_M1_CONTRACT` | **PASS** |
| Module 2 stages M2.1–M2.12 | **12 / 12 ACCEPTED** |
| `G3_M2_CONTRACT` | **PASS** |
| Campaign Scale Certification | **CURRENT — PREPARATION** |
| 750 accepted-fidelity replay | **NOT YET AUTHORIZED** |
| 2,500 performance shakedown | **NOT YET AUTHORIZED** |
| 25,000 full campaign | **NOT YET AUTHORIZED** |
| Production deployment | **NOT AUTHORIZED** |
| Module 3 execution | **NOT AUTHORIZED** |

---

## End-to-End Platform

```text
Acquisition Source, Campaign & Attribution
→ Application & Requested Structure
→ POS, Settlement, Deposit & Liquidity Evidence
→ Cash-Flow, Capacity & Operating Resilience
→ Integrated Risk, Exposure, Recovery & Comparative Loss
→ Unit Economics & Merchant Acquisition Cost
→ G2 Certified Consumption
→ Eligibility & Policy Gates
→ Pricing, Structure & Counteroffers
→ Final-Offer Authorization
→ Simulated Booking, Funding & Activation
→ Remittance, Exposure & Portfolio Monitoring
→ Early Warning, Servicing & Intervention
→ Payment Reconciliation & Account-State Certification
→ Portfolio KPI & Servicing Analytics
→ Strategy Comparison, Simulation & Optimization
→ G3 Enterprise Portfolio Certification
→ Campaign Scale Certification
```

---

## Accepted Release Evidence

### Module 1 / G2

| Measure | Accepted result |
|---|---:|
| Governed progression | G0, G1, and M1.2–M1.17 |
| Designed data foundation | 110 parent/control/reference tables |
| Designed columns | 2,138 |
| Deterministic applications | 750 |
| Matched scenarios | `BASELINE` and `RECESSION_ENERGY` |
| Integrated application-scenario rows | 1,500 |
| Accepted physical hash identities | 18 / 18 PASS |
| Final positive controls | 128 / 128 PASS |
| Final negative controls | 20 / 20 PASS |
| Deterministic or archive mismatches | 0 |
| Final contract | **`G2_M1_CONTRACT — PASS`** |

### Module 2 / G3

| Measure | Accepted result |
|---|---:|
| Accepted Module 2 stages | 12 / 12 |
| Integrated application/origination rows | 1,500 |
| Operational-account rows | 59 |
| Strategy/scope rows | 24 |
| M2.11 positive controls | 120 / 120 PASS |
| M2.11 negative controls | 20 / 20 PASS |
| M2.11 acceptance prerequisites | 45 / 45 PASS |
| M2.11 matched strategy groups | 20 |
| M2.11 risk scenarios | 19 |
| M2.12 positive controls | 128 / 128 PASS |
| M2.12 negative controls | 20 / 20 PASS |
| M2.12 acceptance requirements | 48 / 48 PASS |
| M2.12 governed report sets | 24 / 24 PASS |
| Latest-versus-archive reconciliation | PASS |
| Final contract | **`G3_M2_CONTRACT — PASS`** |
| Governed publication manifest | 1,930 files |

---

## Governed Evidence, Contract, and Acceptance Lineage

The platform is governed across two accepted and connected certification
boundaries.

Module 1 establishes the deterministic merchant, application, operating,
risk, economics, acquisition, and consumption evidence required by downstream
strategy. Module 2 consumes that accepted foundation and extends it through
decisioning, simulated operating states, portfolio analytics, strategy
comparison, optimization, and G3 enterprise certification.

### Module 1 / G2 — Deterministic Evidence Foundation

![Module 1 Governed Evidence, Contract and Acceptance Lineage (historical reference: `./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png`; referenced bytes not established here)](./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png)

Open the Module 1 lineage full size (historical reference: `./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png`; referenced bytes not established here) ·
PDF (historical reference: `./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.pdf`; referenced bytes not established here) ·
Review M1.17 G2 assurance (historical reference: `./Module_1/1.17_End_to_End_QA_and_G2_Acceptance/`; referenced bytes not established here)

#### What this boundary certifies

- deterministic merchant and application identities;
- daily POS, settlement, deposit, liquidity, and cash-flow evidence;
- capacity, resilience, integrated risk, exposure, loss, and unit economics;
- acquisition source, attribution, confidence, and merchant acquisition cost;
- latest, archive, comparison, and companion consumption layers;
- accepted source-to-contract and contract-to-consumption lineage;
- 18 / 18 accepted physical hash identities;
- `G2_M1_CONTRACT — PASS`.

### Module 2 / G3 — Decisioning, Operations, Portfolio Strategy, and Enterprise Certification

![Module 2 Governed Decisioning, Operations, Portfolio and G3 Acceptance Lineage (historical reference: `./docs/enterprise_architecture/Module_2_Governed_Decisioning_Operations_Portfolio_%26_G3_Acceptance_Lineage.png`; referenced bytes not established here)](./docs/enterprise_architecture/Module_2_Governed_Decisioning_Operations_Portfolio_%26_G3_Acceptance_Lineage.png)

Open the Module 2 lineage full size (historical reference: `./docs/enterprise_architecture/Module_2_Governed_Decisioning_Operations_Portfolio_%26_G3_Acceptance_Lineage.png`; referenced bytes not established here) ·
PDF (historical reference: `./docs/enterprise_architecture/Module_2_Governed_Decisioning_Operations_Portfolio_%26_G3_Acceptance_Lineage.pdf`; referenced bytes not established here) ·
Explore the complete Module 2 stage tree (historical reference: `./Module_2/README.md`; referenced bytes not established here)

#### What this boundary certifies

- eligibility, policy, pricing, structure, counteroffers, and alternatives;
- final-offer authorization, decision routing, and rationale;
- deterministic simulated activation and operating states;
- monitoring, early warning, intervention, servicing, and reconciliation;
- portfolio KPI and servicing analytics;
- matched strategy comparison, simulation, optimization, and trade-offs;
- 12 / 12 accepted Module 2 stages;
- enterprise-certified G3 consumption;
- `G3_M2_CONTRACT — PASS`.

```text
MODULE 1 / G2
Certified evidence foundation
        ↓
MODULE 2 / G3
Governed decisioning, simulated operations, portfolio strategy,
and enterprise certification
        ↓
CURRENT
Campaign Scale Certification
```

> **Connected-boundary principle:** Module 1 proves that the evidence can be
> trusted. Module 2 proves that trusted evidence can drive governed strategy.
> G2 and G3 establish the accepted consumption boundaries connecting the two.

> **Authority boundary:** The lineage exhibits summarize accepted synthetic,
> non-production evidence and contract boundaries. They do not represent live
> account processing, deployed credit policy, causal optimization, or
> autonomous decisioning.

---

## Module 2 Accepted Stage Chain

| Stage | Governed capability | Accepted revision |
|---|---|---|
| M2.1 (historical reference: `./Module_2/2.01_Eligibility_Policy_Gates_and_Decision_Routing/`; referenced bytes not established here) | Eligibility, policy gates, and decision routing | `v0.2R7_ACCEPTED` |
| M2.2 (historical reference: `./Module_2/2.02_Pricing_Structure_and_Counteroffer/`; referenced bytes not established here) | Pricing, structure, and counteroffers | `v0.2R2_ACCEPTED` |
| M2.3 (historical reference: `./Module_2/2.03_Final_Offer_and_Decision_Authorization/`; referenced bytes not established here) | Final-offer and decision authorization | `v0.2R2_ACCEPTED` |
| M2.4 (historical reference: `./Module_2/2.04_Booking_Funding_and_Portfolio_Activation/`; referenced bytes not established here) | Booking, funding, and portfolio activation | `v0.2_ACCEPTED` |
| M2.5 (historical reference: `./Module_2/2.05_Daily_Remittance_Exposure_and_Portfolio_Monitoring/`; referenced bytes not established here) | Daily remittance, exposure, and portfolio monitoring | `v0.2R5_ACCEPTED` |
| M2.6 (historical reference: `./Module_2/2.06_Early_Warning_Intervention_and_Servicing_Strategy/`; referenced bytes not established here) | Early warning, intervention, and servicing strategy | `v0.2R1_ACCEPTED` |
| M2.7 (historical reference: `./Module_2/2.07_Operational_Activation_and_Account_Setup/`; referenced bytes not established here) | Operational activation and account setup | `v0.2R1_ACCEPTED` |
| M2.8 (historical reference: `./Module_2/2.08_Servicing_Execution_Payment_and_Lifecycle_Control/`; referenced bytes not established here) | Servicing execution, payment, and lifecycle control | `v0.2_ACCEPTED` |
| M2.9 (historical reference: `./Module_2/2.09_Payment_Reconciliation_and_Account_State_Certification/`; referenced bytes not established here) | Payment reconciliation and account-state certification | `v0.2R1_ACCEPTED` |
| M2.10 (historical reference: `./Module_2/2.10_Portfolio_Performance_KPI_and_Servicing_Analytics/`; referenced bytes not established here) | Portfolio performance, KPIs, and servicing analytics | `v0.2R5_ACCEPTED` |
| M2.11 (historical reference: `./Module_2/2.11_Portfolio_Optimization_and_Strategy_Simulation/`; referenced bytes not established here) | Portfolio optimization and strategy simulation | `v0.2R13_ACCEPTED` |
| M2.12 (historical reference: `./Module_2/2.12_Enterprise_Portfolio_Certification_and_G3_Contract/`; referenced bytes not established here) | Enterprise portfolio certification and G3 contract | `v1_ACCEPTED` |

> **Simulation boundary:** Public Module 2 operating, activation, servicing,
> and portfolio states are deterministic synthetic simulation outputs. They
> are not evidence of live account processing or production deployment.

Each stage provides a governed public projection containing:

```text
README
→ BRD
→ architecture
→ validation and acceptance
→ source provenance
→ correction history
→ catalogs
→ current source
→ reporting source
→ recovery-only source
→ final sign-off
→ manifests and SHA-256 evidence
```

Open the complete Module 2 stage index (historical reference: `./Module_2/README.md`; referenced bytes not established here) ·
Open the BRD and validation index (historical reference: `./docs/BRD_AND_VALIDATION_INDEX.md`; referenced bytes not established here)

---

## What the Platform Demonstrates

### 1. Acquire and Establish Evidence

- deterministic merchant, owner, processor, application, POS, settlement,
  deposit, and liquidity foundations;
- acquisition-source taxonomy, campaign funnels, application touchpoints,
  deterministic attribution, and merchant-acquisition cost;
- source confidence, verification evidence, fraud indicators, and processor
  continuity;
- matched baseline and adverse scenarios using the same governed merchant and
  application identities.

### 2. Decide and Structure

- eligibility and policy gates;
- pricing, terms, factor-rate, and remittance design;
- configurable counteroffers and alternative structures;
- final-offer authorization;
- transparent route, disposition, reason-code, and rationale evidence;
- governed lineage from certified G2 input to merchant-level decision output.

### 3. Operate and Service

- deterministic simulated booking, funding, activation, and initial-limit
  states;
- simulated daily remittance, exposure, and performance monitoring;
- early-warning indicators and intervention triggers;
- servicing, restructures, collections, and lifecycle-control evidence;
- payment-event reconciliation;
- account-state certification;
- complete source-to-operating-state lineage.

### 4. Analyze, Compare, Optimize, and Certify

- portfolio KPI and servicing analytics;
- vintage, exposure, concentration, return, and risk-adjusted evidence;
- matched baseline and challenger strategy comparison;
- strategy simulation across governed scenarios and objectives;
- portfolio optimization and trade-off analysis;
- certified G3 enterprise consumption;
- controlled preparation for the next governed campaign cycle.

---

## Proof Before Scale

```text
GENERATE
→ VALIDATE
→ CHALLENGE
→ RECONCILE
→ CERTIFY
```

The repository advances only after:

- expected outcomes are explicitly defined;
- positive controls prove intended behavior;
- negative controls prove failure boundaries;
- counts, grains, identities, hashes, and contracts reconcile;
- recovery programs are isolated from normal execution;
- accepted outputs are sealed through governed consumption contracts;
- manifests and SHA-256 identities reproduce the physical release.

```text
Evidence first.
Challenge everything.
Reconcile all grains.
Certify the contract.
Scale only after proof.
```

---

## Campaign Scale Certification

The current governed initiative is preparation for deterministic scale
verification:

```text
750 accepted-fidelity replay
→ 2,500 performance shakedown
→ 25,000 full campaign
```

Each scale step requires a separate fail-closed readiness and authorization
gate.

Preparation does not imply:

- execution authorization;
- production fitness;
- causal inference;
- calibrated credit performance;
- autonomous decisioning;
- Module 3 authorization.

Open the campaign-scale documentation (historical reference: `./docs/campaign_scale/README.md`; referenced bytes not established here) ·
Read the governance boundary (historical reference: `./docs/campaign_scale/CAMPAIGN_SCALE_GOVERNANCE_BOUNDARY.md`; referenced bytes not established here) ·
Read the pre-750 roadmap (historical reference: `./docs/campaign_scale/CAMPAIGN_PRE_750_REPLAY_ROADMAP.md`; referenced bytes not established here)

---

## Choose a Review Path

| Reviewer | Recommended path |
|---|---|
| Executive or hiring leader | Architecture (historical reference: `./docs/enterprise_architecture/README.md`; referenced bytes not established here) → 10-page strategy brief (historical reference: `./docs/executive_strategy/README.md`; referenced bytes not established here) → Release notes (historical reference: `./RELEASE_NOTES.md`; referenced bytes not established here) |
| Product, pricing, or portfolio leader | Beyond Underwriting (historical reference: `./docs/executive_strategy/pages_v2/03_beyond_underwriting.png`; referenced bytes not established here) → Strategy Engine (historical reference: `./docs/executive_strategy/pages_v2/06_the_strategy_engine.png`; referenced bytes not established here) → Opportunity Ahead (historical reference: `./docs/executive_strategy/pages_v2/10_the_opportunity_ahead.png`; referenced bytes not established here) |
| Technical or architecture reviewer | Module and release index (historical reference: `./MODULE_AND_RELEASE_INDEX.md`; referenced bytes not established here) → Module 1 lineage (historical reference: `./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png`; referenced bytes not established here) → Module 2 stage tree (historical reference: `./Module_2/README.md`; referenced bytes not established here) |
| Governance or validation reviewer | Governance guide (historical reference: `./GOVERNANCE_AND_VALIDATION.md`; referenced bytes not established here) → BRD and validation index (historical reference: `./docs/BRD_AND_VALIDATION_INDEX.md`; referenced bytes not established here) → M2.12 acceptance (historical reference: `./Module_2/2.12_Enterprise_Portfolio_Certification_and_G3_Contract/`; referenced bytes not established here) |
| Campaign-scale reviewer | Campaign Scale Certification (historical reference: `./docs/campaign_scale/README.md`; referenced bytes not established here) → governance boundary → pre-750 roadmap |
| Development-history reviewer | Project history (historical reference: `./docs/project_history/README.md`; referenced bytes not established here) → sanitized transcript archive |
| Repository navigator | Project artifact map (historical reference: `./PROJECT_ARTIFACT_MAP.md`; referenced bytes not established here) |

---

## Repository Map

- `Module_0/` (historical reference: `./Module_0/`; referenced bytes not established here) — physical data foundation and governed run
  control.
- `Module_1/` (historical reference: `./Module_1/`; referenced bytes not established here) — deterministic merchant, application, operating,
  risk, economics, acquisition, contract, and G2-assurance foundation.
- `Module_2/` (historical reference: `./Module_2/README.md`; referenced bytes not established here) — twelve accepted decisioning, operating,
  servicing, portfolio, strategy, and G3-certification stages.
- `docs/enterprise_architecture/` (historical reference: `./docs/enterprise_architecture/README.md`; referenced bytes not established here) —
  current enterprise architecture and Module 1/Module 2 lineage exhibits.
- `docs/executive_strategy/` (historical reference: `./docs/executive_strategy/README.md`; referenced bytes not established here) — Governed
  Build Edition v3.0 ten-page executive brief.
- `docs/campaign_scale/` (historical reference: `./docs/campaign_scale/README.md`; referenced bytes not established here) — campaign
  readiness, clean-build source closure, governance boundary, and pre-750
  roadmap.
- `docs/project_history/` (historical reference: `./docs/project_history/README.md`; referenced bytes not established here) — sanitized and
  searchable development-transparency archive.
- `docs/BRD_AND_VALIDATION_INDEX.md` (historical reference: `./docs/BRD_AND_VALIDATION_INDEX.md`; referenced bytes not established here) —
  direct stage-level BRD, validation, and source navigation.
- `PROJECT_ARTIFACT_MAP.md` (historical reference: `./PROJECT_ARTIFACT_MAP.md`; referenced bytes not established here) — repository-wide
  artifact map.
- `MODULE_AND_RELEASE_INDEX.md` (historical reference: `./MODULE_AND_RELEASE_INDEX.md`; referenced bytes not established here) — governed
  module and release index.

---

## Validate the Public Release

Clone the repository and run the publication validator:

```bash
git clone https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
cd merchant-sales-based-financing-strategy-simulator
python tools/validate_public_release.py
```

Expected result for Module 2 / G3 v2.0.0:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

The validator checks repository navigation, manifests, governed file
identities, required Module 2 stage structure, and publication boundaries.

---

## Source Classification

Within each accepted Module 2 stage:

| Source area | Classification |
|---|---|
| `src/current/` | Accepted normal-chain source |
| `src/reporting/` | Reporting, detail-report, and evidence-export source |
| `src/recovery/` | Contingency-only recovery source; excluded from normal execution |

Recovery SQL is retained for provenance, reproducibility, and failure-mode
transparency. It is not part of the normal execution chain.

---

## Transparency and Provenance

The repository includes a sanitized, searchable development-history archive
through August 12, 2026.

It provides:

- date-ordered Markdown transcripts;
- machine-readable JSONL records;
- project chronology;
- milestone and decision indexes;
- source-export identities;
- duplicate-format classification;
- deterministic redaction reporting;
- an explicit authority hierarchy distinguishing working discussion from
  accepted source and formal sign-off.

Open the project-history guide (historical reference: `./docs/project_history/README.md`; referenced bytes not established here)

Discussion history is supporting transparency evidence. Accepted SQL,
manifests, BRDs, validation records, and formal sign-offs remain the governing
authorities.

---

## Governance Principles

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

The governing philosophy is:

> **Logic, controls, validation, evidence, interpretation, and ownership travel together.**

---

## Release and Publication

| Release element | Authority |
|---|---|
| Public release | **Module 2 / G3 v2.0.0** |
| Release title | **Merchant Sales-Based Financing Strategy Simulator — Module 2 G3 — Governed Decisioning, Operations, Portfolio Strategy & Enterprise Certification** |
| Git tag | **`module-2-g3-v2.0.0`** |
| Visual edition | **Governed Build Edition v3.0** |
| Release date | **2026-08-13** |
| Module 1 contract | **`G2_M1_CONTRACT — PASS`** |
| Module 2 contract | **`G3_M2_CONTRACT — PASS`** |
| Current initiative | **Campaign Scale Certification** |

See:

- Release Notes (historical reference: `./RELEASE_NOTES.md`; referenced bytes not established here)
- GitHub Publication Guide (historical reference: `./GITHUB_PUBLICATION_GUIDE.md`; referenced bytes not established here)
- Governance and Validation (historical reference: `./GOVERNANCE_AND_VALIDATION.md`; referenced bytes not established here)
- Reproducibility and Execution (historical reference: `./REPRODUCIBILITY_AND_EXECUTION.md`; referenced bytes not established here)
- Citation metadata (historical reference: `./CITATION.cff`; referenced bytes not established here)

---

## Interpretation Boundary

All data are synthetic.

This repository is not:

- a financing offer;
- a production underwriting system;
- a deployed servicing platform;
- a calibrated probability-of-default model;
- a CECL or regulatory-capital model;
- legal or accounting advice;
- a causal optimization engine;
- an autonomous decision service.

Power BI references describe governed, Power BI-ready views and publication
visuals—not a production dashboard deployment.

The repository demonstrates transferable methodology, system architecture,
governed simulation, validation discipline, evidence design, release
governance, and executive communication.
````

This README should be committed before publishing the GitHub Release so the tagged `v2.0.0` source snapshot and the public landing page contain the same expanded visual narrative.
<!-- END_SOURCE_MESSAGE -->


<a id="m-19bbd934-614c-4ccd-b538-e1c087cf8f30"></a>
## Andrew / user · C072-M00549

C072-M00549 · 2026-08-15T09:48:01.306000-04:00 · active path

Preceding visible parent: [C072-M00548](part-38.md#m-9fc85792-88fc-48f1-8ae1-9280f13e84a1)

<!-- BEGIN_SOURCE_MESSAGE -->
you have a Module 2 Accepted Stage Chain section but not similar thing for module 1 - is that another oversight or intended?
<!-- END_SOURCE_MESSAGE -->


<a id="m-5a7fa54d-8239-4748-aeac-1849a5a6934b"></a>
## Assistant · C072-M00550

C072-M00550 · 2026-08-15T09:51:57.567594-04:00 · active path

Preceding visible parent: [C072-M00549](part-38.md#m-19bbd934-614c-4ccd-b538-e1c087cf8f30)

<!-- BEGIN_SOURCE_MESSAGE -->
It is **an oversight in the final README design**, not an asymmetry I recommend preserving.

There was an understandable reason for initially emphasizing the Module 2 chain: this is the **Module 2 / G3 release**, and the twelve-stage public Module 2 tree is the principal new technical addition. But once the root README was expanded to present:

- both Module 1/G2 and Module 2/G3 as accepted boundaries;
- separate evidence tables for both modules;
- both lineage exhibits at full width;
- the complete end-to-end platform story;

then showing only the **Module 2 Accepted Stage Chain** became inconsistent. The current structure gives Module 1 and Module 2 parallel evidence summaries, but immediately afterward enumerates only M2.1–M2.12. [export reference: filecite | turn218file0 | L138-L175] [export reference: filecite | turn218file0 | L179-L194]

## Why Module 1 also needs a visible stage chain

Module 1 is not merely historical context. It is the accepted evidence foundation consumed by Module 2:

```text
Module 1 stages
→ G2_M1_CONTRACT
→ Module 2 stages
→ G3_M2_CONTRACT
```

Without a Module 1 stage table, a first-time reviewer can see the G2 metrics and the Module 1 lineage image, but cannot quickly understand **which governed stages created that evidence boundary**. It makes Module 1 look like a summarized black box while Module 2 receives stage-level treatment.

That weakens three important claims:

1. **Architectural continuity** — Module 2 consumes a complete governed foundation rather than beginning with unexplained inputs.
2. **Comparable build discipline** — both modules were constructed stage by stage with accepted source, controls, evidence, and release governance.
3. **No Cold Handoffs** — the transition from evidence generation to decisioning should be physically visible in the README.

## Recommended final sequence

The middle of the README should be organized as:

```text
Accepted Release Evidence
    Module 1 / G2 metrics
    Module 2 / G3 metrics

Module 1 Accepted Stage Chain
    G0
    G1
    M1.2 through M1.17

Module 2 Accepted Stage Chain
    M2.1 through M2.12

Governed Evidence, Contract, and Acceptance Lineage
    Module 1 / G2 image
    Module 2 / G3 image
```

That creates the strongest progression:

```text
Metrics
→ stage construction
→ visual lineage
→ capability interpretation
```

## Recommended presentation

The Module 1 chain should mirror the Module 2 table:

```markdown
## Module 1 Accepted Stage Chain

| Stage | Governed capability | Accepted revision |
|---|---|---|
| G0 | Physical data foundation | ... |
| G1 | Governed run control | ... |
| M1.2 | Deterministic merchant population | ... |
| ... | ... | ... |
| M1.16 | Acquisition attribution and merchant CAC | ... |
| M1.17 | End-to-end QA, G2 assurance, and consumption contract | ... |
```

It should be **fully visible**, not hidden inside `<details>`. The README is deliberately comprehensive, and the Module 1 chain is important enough to justify the additional rows.

The exact stage titles, links, and accepted revisions should be sourced from the repository’s existing Module 1 authorities—particularly `Module_1/README.md`, `MODULE_AND_RELEASE_INDEX.md`, and the accepted stage directories—rather than reconstructed from memory.

## Final determination

```text
Module 1 metrics                        PRESENT
Module 1 lineage                        PRESENT in revised design
Module 1 accepted stage chain           MISSING — CORRECT
Module 2 metrics                        PRESENT
Module 2 lineage                        PRESENT
Module 2 accepted stage chain           PRESENT

Disposition                             README REVISION REQUIRED
```

The next full Markdown revision should include **both accepted stage chains at equal visual authority** before the GitHub Release is published.
<!-- END_SOURCE_MESSAGE -->


<a id="m-84b033a3-7d52-40a5-a2e2-bc2b3ffe14db"></a>
## Andrew / user · C072-M00551

C072-M00551 · 2026-08-15T09:57:04.747000-04:00 · active path

Preceding visible parent: [C072-M00550](part-38.md#m-5a7fa54d-8239-4748-aeac-1849a5a6934b)

**Editorial record note:** Attachment references: Pasted markdown(20260815-135648).md

<!-- BEGIN_SOURCE_MESSAGE -->
correct in another full readme easy copy paste. this time also audit it for a final publication. current full readme: 
<!-- END_SOURCE_MESSAGE -->
