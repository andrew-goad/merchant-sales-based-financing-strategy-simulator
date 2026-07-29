# Merchant Sales-Based Financing Strategy Simulator

## A Governed Enterprise Platform for Merchant Acquisition, Operating Intelligence, Risk, Economics, and Portfolio Learning

[![Enterprise Merchant Sales-Based Financing Platform](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform.png)](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform.png)

[Open the enterprise architecture full size](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform.png) | [Open the PDF](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform.pdf)

How do you design, test, evidence, and certify a merchant sales-based financing platform before allowing strategy logic to make an offer?

I built this project as a deterministic, synthetic, PostgreSQL-based enterprise simulator for merchant financing tied to daily point-of-sale activity and sales-linked repayment. The platform connects merchant identity, acquisition source, POS and deposit behavior, source confidence, verification and fraud evidence, capacity, resilience, integrated risk, exposure, recovery, comparative loss, unit economics, immutable contracts, and end-to-end assurance - without using PII or production credit policy.

This is not a dashboard-only project and it is not a single opaque score. The core system is a governed evidence chain with explicit stage boundaries, target-typed hashes, positive and negative controls, immutable archives, fail-closed recovery, and formal acceptance.

> **Module 1 is complete. `G2_M1_CONTRACT = PASS`. Module 2 - Strategy and Offer Decisioning is authorized.**

## Executive Release Snapshot

| Release fact | Accepted result |
|---|---:|
| Governed run | `M1_V0_2_BASELINE_BUILD`, version 1 |
| Accepted progression | G0, G1, and M1.2-M1.17 |
| Applications | 750 |
| Matched scenarios | 2: `BASELINE` and `RECESSION_ENERGY` |
| Integrated G2 consumption rows | 1,500 |
| Ordered accepted hash-chain identities | 18 / 18 PASS |
| M1.17 positive controls | 128 / 128 PASS |
| M1.17 negative controls | 20 / 20 PASS |
| Deterministic mismatches | 0 |
| Archive reproduction mismatches | 0 |
| Prohibited PII columns | 0 |
| Premature Module 2 rows | 0 |
| Combined G2 canonical set | `7d9e466da28cad2551aa99c4c40c912b` |
| Final gate | **`G2_M1_CONTRACT - PASS`** |

The accepted source packages represent **110 designed parent/control/reference tables and 2,138 designed columns** at the final Module 1 boundary. These are source-derived design counts; the historical G0 baseline remains 70 parent tables and 1,041 designed columns.

## Repository Navigation

- [`RELEASE_NOTES.md`](./RELEASE_NOTES.md) - Module 1 G2 v1.0.0 release summary and boundaries.
- [`PROJECT_ARTIFACT_MAP.md`](./PROJECT_ARTIFACT_MAP.md) - curated file map and reviewer paths.
- [`MODULE_AND_RELEASE_INDEX.md`](./MODULE_AND_RELEASE_INDEX.md) - accepted versions, outputs, and hashes.
- [`GOVERNANCE_AND_VALIDATION.md`](./GOVERNANCE_AND_VALIDATION.md) - deterministic evidence, controls, recovery, and G2 assurance.
- [`SAMPLE_DATA_AND_EVIDENCE_POLICY.md`](./SAMPLE_DATA_AND_EVIDENCE_POLICY.md) - synthetic samples and the Controlled 50-Application Public Review Cohort.
- [`REPRODUCIBILITY_AND_EXECUTION.md`](./REPRODUCIBILITY_AND_EXECUTION.md) - PostgreSQL 15 and DBeaver execution model.

## Enterprise Architecture

The flagship architecture shows the enterprise capability chain from governance and merchant foundations through daily operating intelligence, risk and economics, acquisition evidence, governed consumption contracts, G2 assurance, and the next authorized strategy layer.

For the complete stage-by-stage technical chain, open the [Module 1 Governed Evidence, Contract & Acceptance Lineage](./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png).

## End-to-End Evidence Chain

```text
Governed Run Control
-> Deterministic Merchant Population
-> Application & Requested Sales-Linked Structure
-> Daily POS & Settlement History
-> Daily Deposit & Liquidity History
-> Matched Baseline / Stress Scenarios
-> Source Quality & Data Confidence
-> Verification, Fraud & Processor Continuity
-> As-of Cash-Flow Features
-> Obligations, Liquidity & Residual Capacity
-> Cash-Flow Archetypes & Operating Resilience
-> Merchant Risk Components & Integrated Risk Proxy
-> Exposure, Recovery & Comparative Loss
-> Unit Economics & Risk-Adjusted Contribution
-> Latest / Archive / Scenario Comparison Contract
-> Acquisition Source, Attribution & Merchant CAC Contract
-> Integrated Module 1 Consumption Interface
-> End-to-End G2 Assurance
-> Module 2 Strategy & Offer Decisioning
```

The architecture deliberately keeps these concepts distinct:

```text
Data confidence
!= verification evidence
!= fraud risk
!= processor continuity
!= cash-flow behavior
!= obligations and capacity
!= operating resilience
!= synthetic integrated risk
!= exposure and recovery
!= comparative loss
!= unit economics
!= acquisition economics
!= pricing or final strategy decisions
```

## Accepted Stage Progression

| Stage | Capability | Accepted revision | Status | Principal output |
|---|---|---:|---:|---|
| [G0](./Module_0/0.01_G0_Physical_Data_Foundation/README.md) | Physical Data Foundation | v0.2 | **ACCEPTED** | G0 baseline: 70 physical parent tables, 1,041 designed columns, plus four partition children. |
| [G1](./Module_0/0.02_G1_Governed_Run_Control/README.md) | Governed Run Control | v0.2 | **ACCEPTED** | Governed run M1_V0_2_BASELINE_BUILD, version 1, with three accepted snapshot identities. |
| [M1.2](./Module_1/1.02_Deterministic_Merchant_Population/README.md) | Deterministic Merchant Population | v0.2R2 | **ACCEPTED** | 750 merchants and 4,352 canonical entities. |
| [M1.3](./Module_1/1.03_Application_and_Requested_Structure/README.md) | Application & Requested Sales-Linked Structure | v0.2R1 | **ACCEPTED** | 750 applications and requested financing structures. |
| [M1.4](./Module_1/1.04_Daily_POS_Settlement_and_Ecosystem/README.md) | Daily POS, Settlement & Merchant Ecosystem | v0.2 | **ACCEPTED** | 135,000 baseline daily POS and settlement rows. |
| [M1.5](./Module_1/1.05_Daily_Deposit_and_Liquidity_History/README.md) | Daily Deposit & Liquidity History | v0.2R2 | **ACCEPTED** | 135,000 daily deposit and liquidity rows. |
| [M1.6](./Module_1/1.06_Matched_POS_and_Deposit_Scenarios/README.md) | Matched POS & Deposit Scenario Overlays | v0.2R3 | **ACCEPTED** | 270,000 POS scenario rows + 270,000 deposit scenario rows; 540,000 canonical entities. |
| [M1.7](./Module_1/1.07_Source_Quality_and_Data_Confidence/README.md) | Source Quality & Data Confidence | v0.2 | **ACCEPTED** | 5,250 source-quality records across 750 applications. |
| [M1.8](./Module_1/1.08_Verification_Fraud_and_Continuity/README.md) | Verification, Fraud & Processor Continuity | v0.2R1 | **ACCEPTED** | 4,500 atomic checks + 750 application summaries; 5,250 canonical entities. |
| [M1.9](./Module_1/1.09_As_Of_Cash_Flow_Features/README.md) | As-of Cash-Flow Feature Engineering | v0.2R5 | **ACCEPTED** | 1,500 wide snapshots + 54,000 long-form values across 36 features; 55,500 canonical entities. |
| [M1.10](./Module_1/1.10_Obligations_Liquidity_and_Capacity/README.md) | Obligations, Liquidity & Residual Cash Flow | v0.2R2 | **ACCEPTED** | 906 atomic obligations + 1,500 capacity snapshots; 2,406 canonical entities. |
| [M1.11](./Module_1/1.11_Cash_Flow_Archetypes_and_Resilience/README.md) | Cash-Flow Archetypes & Operating Resilience | v0.2R2 | **ACCEPTED** | 1,500 snapshots + 7,500 component rows; 9,000 canonical entities. |
| [M1.12](./Module_1/1.12_Merchant_Risk_and_Integrated_Proxy/README.md) | Merchant Risk Components & Integrated Risk Proxy | v0.2R1 | **ACCEPTED** | 1,500 risk snapshots + 10,500 component rows; 12,000 canonical entities. |
| [M1.13](./Module_1/1.13_Exposure_Recovery_and_Expected_Loss/README.md) | Exposure, Recovery & Expected Loss Foundations | v0.2R1 | **ACCEPTED** | 93,720 exposure-path rows + 1,500 snapshots; 95,220 canonical entities. |
| [M1.14](./Module_1/1.14_Unit_Economics_and_Contribution/README.md) | Unit Economics & Risk-Adjusted Contribution | v0.2R4 | **ACCEPTED** | 1,500 snapshots + 21,000 component rows; 22,500 canonical entities. |
| [M1.15](./Module_1/1.15_Latest_Archive_Comparison_and_Contract/README.md) | Latest, Archive, Comparison & Consumption Contract | v0.2R3 | **ACCEPTED** | 1 registry + 1,500 latest + 1,500 archive + 750 comparisons; 3,751 canonical entities. |
| [M1.16](./Module_1/1.16_Acquisition_Attribution_and_CAC/README.md) | Acquisition Source, Marketing Attribution & Merchant CAC | v0.2R3 | **ACCEPTED** | 13,274 canonical entities, including 750 acquisition contracts and a 1,500-row integrated M1.15 x M1.16 view. |
| [M1.17](./Module_1/1.17_End_to_End_QA_and_G2_Acceptance/README.md) | End-to-End QA, Evidence & G2 Contract Acceptance | v0.2R8 | **ACCEPTED** | 18 hash-chain rows + 48 assurance records + one latest/archive/registry bundle; 69 canonical entities. |

The non-executable [`1.01 Module 1 Charter, Architecture & Requirements`](./Module_1/1.01_Charter_Architecture_and_Requirements/README.md) package provides the enterprise design context but is not represented as a separate accepted database milestone.

## Acquisition Source, Marketing Attribution & Merchant CAC

M1.16 extends unit economics from one broad channel-cost proxy into a governed acquisition evidence system.

```text
Acquisition Source Profile
-> Campaign & Funnel Evidence
-> Application Touchpoints
-> Deterministic Attribution
-> Incurred Pre-Application Cost
-> Conditional Partner / Broker Cost
-> M1.14 Legacy-Cost Overlap Control
-> Enhanced Acquisition Cost
-> Application-Level Companion Contract
```

### Accepted funnel

| Funnel stage | Count |
|---|---:|
| Targeted or eligible | 4,704 |
| Delivered or presented | 4,164 |
| Engaged or responded | 1,978 |
| Qualified lead | 1,160 |
| Application started | 870 |
| Application submitted | 750 |

### Accepted acquisition-cost foundation

| Economics item | Accepted amount |
|---|---:|
| Direct attributable incurred cost | $6,574.50 |
| Internally allocated acquisition cost | $46,625.00 |
| Detailed incurred acquisition cost | $53,199.50 |
| Conditional partner / broker cost | $213,530.80 |
| Detailed total acquisition cost if booked | $266,730.30 |
| Accepted M1.14 legacy acquisition cost | $315,834.35 |
| Identified supported M1.14 overlap | $224,293.73 |
| Incremental M1.16 cost beyond M1.14 | $31,587.73 |
| Supported enhanced acquisition cost | $335,108.33 |

Unknown acquisition cost is not converted to zero. Twenty-seven blocked records retain known components and the accepted M1.14 amount but do not receive an unsupported enhanced total.

[Open the M1.16 stage package](./Module_1/1.16_Acquisition_Attribution_and_CAC/README.md)

## G2 Contract Certification

M1.17 certifies two accepted contract families without rewriting them:

```text
M1_APPLICATION_CONSUMPTION v1
M1_CONTRACT_SCHEMA_V1
Combined M1.15 hash: fcd2704e17ec0d2e73191ea36061d74b

M1_ACQUISITION_CONSUMPTION v1
M1_ACQUISITION_SCHEMA_V1
Combined M1.16 hash: 86df51a0ca68d84096d00ff0f1b19f33
```

The final integrated interface contains exactly 750 `BASELINE` rows and 750 `RECESSION_ENERGY` rows, with zero duplicates, orphaned applications, scenario-count violations, contract-hash mismatches, or acquisition drift between matched scenarios.

[Open the M1.17 G2 assurance package](./Module_1/1.17_End_to_End_QA_and_G2_Acceptance/README.md) | [Review the complete hash chain](./docs/project_lineage/MODULE_1_ACCEPTED_HASH_CHAIN.md)

## From First Advance to Intelligent Portfolio

[![From First Advance to Intelligent Portfolio cover](./docs/executive_strategy/from_first_advance_to_intelligent_portfolio_cover.png)](./docs/executive_strategy/From_First_Advance_to_Intelligent_Portfolio.pdf)

[Open the eight-page strategic brief](./docs/executive_strategy/From_First_Advance_to_Intelligent_Portfolio.pdf) | [Open the contact sheet](./docs/executive_strategy/from_first_advance_to_intelligent_portfolio_contact_sheet.png) | [Open the page gallery](./docs/executive_strategy/pages/README.md)

> **The first advance is not the destination. It is the beginning of a learning system.**

The refreshed brief connects controlled acquisition, merchant operating evidence, governed strategy, relationship development, portfolio learning, and acquisition-to-lifetime-value intelligence.

## Technical Rigor

- **PostgreSQL 15 foundation** - implemented schemas, deterministic generation, persistence, contracts, evidence, and validation.
- **Accepted-only stage progression** - each module consumes persisted predecessor outputs and respects its analytical boundary.
- **Target-typed hashing** - expected values are cast to physical target types before hashing.
- **Independent reconstruction** - stored hashes are rebuilt from persisted physical fields.
- **Matched scenario discipline** - the same 750 applications are compared across two accepted scenarios.
- **Visible-component reconciliation** - published composites reconcile to persisted visible components.
- **Evidence gating** - `COMPLETE`, `PARTIAL`, and `BLOCKED` states remain explicit.
- **Immutable archives** - database triggers protect M1.15, M1.16, and G2 archive rows.
