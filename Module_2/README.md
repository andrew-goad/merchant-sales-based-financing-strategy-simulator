# Module 2 — Governed Decisioning, Operations, Portfolio Strategy & G3 Certification

**Release:** Module 2 / G3 v2.0.0  
**Formal state:** `M2.12 ACCEPTED / G3_M2_CONTRACT PASS`  
**Current next proof:** Campaign Scale Certification — `750 → 2,500 → 25,000`

Module 2 consumes the accepted Module 1/G2 boundary and advances governed merchant evidence through eligibility, pricing, offer authorization, simulated activation and operations, servicing, reconciliation, portfolio analytics, strategy simulation, optimization, and enterprise G3 certification.

## Accepted stage chain

| Stage | Capability | Public revision | Status |
|---|---|---|---|
| [M2.1](2.01_Eligibility_Policy_Gates_and_Decision_Routing/) | Eligibility, Policy Gates & Decision Routing | `v0.2R7_ACCEPTED` | `ACCEPTED` |
| [M2.2](2.02_Pricing_Structure_and_Counteroffer/) | Pricing, Structure & Counteroffer | `v0.2R2_ACCEPTED` | `ACCEPTED` |
| [M2.3](2.03_Final_Offer_and_Decision_Authorization/) | Final Offer & Decision Authorization | `v0.2R2_ACCEPTED` | `ACCEPTED` |
| [M2.4](2.04_Booking_Funding_and_Portfolio_Activation/) | Booking, Funding & Portfolio Activation | `v0.2_ACCEPTED` | `ACCEPTED` |
| [M2.5](2.05_Daily_Remittance_Exposure_and_Portfolio_Monitoring/) | Daily Remittance, Exposure & Portfolio Monitoring | `v0.2R5_ACCEPTED` | `ACCEPTED` |
| [M2.6](2.06_Early_Warning_Intervention_and_Servicing_Strategy/) | Early Warning, Intervention & Servicing Strategy | `v0.2R1_ACCEPTED` | `ACCEPTED` |
| [M2.7](2.07_Operational_Activation_and_Account_Setup/) | Operational Activation & Account Setup | `v0.2R1_ACCEPTED` | `ACCEPTED` |
| [M2.8](2.08_Servicing_Execution_Payment_and_Lifecycle_Control/) | Servicing Execution, Payment & Lifecycle Control | `v0.2_ACCEPTED` | `ACCEPTED` |
| [M2.9](2.09_Payment_Reconciliation_and_Account_State_Certification/) | Payment Reconciliation & Account State Certification | `v0.2R1_ACCEPTED` | `ACCEPTED` |
| [M2.10](2.10_Portfolio_Performance_KPI_and_Servicing_Analytics/) | Portfolio Performance, KPI & Servicing Analytics | `v0.2R5_ACCEPTED` | `ACCEPTED` |
| [M2.11](2.11_Portfolio_Optimization_and_Strategy_Simulation/) | Portfolio Optimization & Strategy Simulation | `v0.2R13_ACCEPTED` | `ACCEPTED` |
| [M2.12](2.12_Enterprise_Portfolio_Certification_and_G3_Contract/) | Enterprise Portfolio Certification & G3 Contract | `v1_ACCEPTED` | `ACCEPTED` |

## Public stage-package standard

Every stage includes:

- an executive-quality stage README;
- a public BRD and architecture record;
- validation and acceptance documentation;
- source provenance and correction history;
- selected machine-readable catalogs;
- exact current/reporting/recovery SQL identities;
- recovery classification isolated from normal execution;
- public validation and signoff records;
- stage-level manifests and SHA-256 inventories.

## Governed boundaries

- **G2 input:** `M1_G2_CONSUMPTION_BUNDLE v1 / G2_M1_CONTRACT PASS`
- **M2.11 strategy boundary:** accepted portfolio optimization and strategy simulation
- **G3 output:** `M2_G3_CONSUMPTION_BUNDLE v1 / G3_M2_CONTRACT PASS`
- **Production deployment:** not authorized
- **Empirical or causal optimization claims:** not supported
- **Module 3 execution:** not authorized

## Visual authorities

- [Enterprise architecture](../docs/enterprise_architecture/README.md)
- [Executive strategy brief](../docs/executive_strategy/README.md)

## Machine-readable indexes

- [`MODULE_2_STAGE_INDEX.csv`](MODULE_2_STAGE_INDEX.csv)
- [`MODULE_2_SOURCE_CLASSIFICATION.csv`](MODULE_2_SOURCE_CLASSIFICATION.csv)
- [`MODULE_2_ACCEPTED_CHAIN.json`](MODULE_2_ACCEPTED_CHAIN.json)

## Cross-repository review paths

- [Business Requirements and Validation Index](../docs/BRD_AND_VALIDATION_INDEX.md)
- [Module 2 lineage exhibit](../docs/enterprise_architecture/Module_2_Governed_Decisioning_Operations_Portfolio_&_G3_Acceptance_Lineage.png)
- [Executive explanation of the accepted platform](../docs/executive_strategy/README.md)
- [Campaign Scale Certification](../docs/campaign_scale/README.md)
- [Development transparency archive](../docs/project_history/README.md)

The public stage tree is the source-navigation authority for the GitHub release. Conversation history and campaign preparation do not modify accepted stage identities.
