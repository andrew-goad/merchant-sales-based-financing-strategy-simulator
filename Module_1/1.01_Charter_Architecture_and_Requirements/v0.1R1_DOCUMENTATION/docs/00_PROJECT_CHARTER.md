# Project Charter
## Merchant Sales-Based Financing Strategy Simulator v0.1R2

| Charter field | Working definition |
|---|---|
| **Project type** | Public synthetic portfolio strategy and decision-system design artifact |
| **Primary purpose** | Demonstrate how a new entrant could design, launch, govern, learn from, optimize, and scale a short-duration merchant sales-based financing portfolio |
| **Primary audience** | Credit Risk, Portfolio Management, Underwriting, Pricing, Finance, Product, Operations, Data, Model Validation, and executive leadership |
| **Data boundary** | Synthetic and public demonstration assumptions only; no PII, proprietary policy, or client-specific information |
| **Decision boundary** | Pre-production strategy simulation; not an operational credit-decisioning, pricing, servicing, collections, or legal-compliance system |
| **Working horizon** | Design-complete executive package first; thin vertical implementation second; full modules and reporting thereafter |

---

# 1. Executive statement

The project will design a governed, deterministic, scenario-capable platform for short-duration merchant financing repaid through a percentage of eligible POS sales. It will connect merchant cash-flow evidence to underwriting, offer construction, pricing, collateral, covenants, daily remittance performance, dynamic exposure management, loss mitigation, economic stress testing, and portfolio allocation.

The project is not limited to answering whether a merchant should be approved. It is designed to answer how a new merchant-finance business should develop its credit capability over one-, three-, and five-year horizons while balancing growth, loss, profitability, competitive positioning, operational scalability, and governance.

# 2. Business problem

A new entrant to processor-linked merchant financing needs more than a score cutoff. It needs an integrated strategy that determines:

- which merchants and industries to enter;
- how to interpret daily POS and deposit behavior;
- how much exposure to offer;
- what remittance structure the merchant can sustain;
- what price is both competitive and profitable;
- how collateral and covenants mitigate risk;
- how to identify deterioration on a 30- to 90-day expected horizon;
- when to increase, reduce, freeze, restructure, renew, or exit exposure;
- how economic and industry shocks propagate through the portfolio;
- what capabilities and controls must exist before the business scales.

# 3. Central project thesis

> Merchant financing risk and value emerge from the interaction of merchant cash flow, product mechanics, remittance burden, price, competition, collateral, covenants, relationship behavior, economic conditions, and portfolio concentration—not from a single credit score or one month of sales.

The target end-to-end chain is:

```text
Merchant and Relationship Context
→ Multi-Source POS / Deposit / Credit / Verification Evidence
→ Revenue Quality, Stability, Liquidity, and Industry Context
→ Requested Facility and Advance Structure
→ Candidate Amount / Remittance / Price / Collateral / Covenant Packages
→ Acceptance, Capacity, Risk, EAD, LGD, and Contribution
→ Origination Decision and Portfolio Allocation
→ Daily Remittance and Merchant-Health Monitoring
→ Dynamic Line Management, Renewal, and Loss Mitigation
→ Economic and Industry-Network Stress Testing
→ Risk Appetite, Strategy Robustness, and Multi-Year Portfolio Planning
```

# 4. Project objectives

The project will:

1. Establish legally neutral but economically precise product mechanics.
2. Build a deterministic synthetic merchant and daily POS/deposit population.
3. Distinguish revenue level, quality, trend, seasonality, volatility, and liquidity.
4. Separate credit risk, fraud risk, data confidence, and operational continuity.
5. Design amount, remittance, expected payoff, price, collateral, and covenant strategies.
6. Model acceptance elasticity, competitive displacement, adverse selection, and expected contribution.
7. Replace conventional monthly DPD dependence with high-frequency remittance and merchant-health measures.
8. Design dynamic facility and line-management actions for both deterioration and opportunity.
9. Evaluate loss-mitigation treatments using cure, recovery, cost, and relationship value.
10. Stress the portfolio through direct and second-order industry transmission.
11. Create a governed one-, three-, and five-year credit strategy roadmap.
12. Produce executive, technical, validation, and Power BI-ready artifacts.
13. Create a regulation-aware product and offer architecture that can absorb changing jurisdiction, disclosure, licensing, reporting, data-segregation, and record-retention requirements through approved configuration.
14. Preserve clear separation among credit strategy, legal classification, compliance applicability, financial-crime controls, payment-data security, and operational execution.

# 5. Core management questions

The platform must answer:

1. Which merchants should be eligible for financing?
2. How much should be offered initially and over the relationship lifecycle?
3. What remittance percentage and expected payoff horizon are sustainable?
4. What price maximizes expected booked value rather than nominal yield alone?
5. What collateral and covenant package is required?
6. Which offers should be approved, counteroffered, reviewed, or declined?
7. Is an account performing appropriately relative to actual sales and expected payoff progress?
8. Which merchants require line increases, reductions, freezes, renewals, or workouts?
9. Which loss-mitigation action maximizes expected recovery and relationship value?
10. Which segments are vulnerable under recession, industry, funding, or competitive stress?
11. Where should incremental lending capacity be deployed?
12. What must be true before the business moves from launch to scale?
13. Which approved product-structure and jurisdiction profile applies to an offer, and what disclosure, documentation, license/registration, reporting, record-retention, and data-control package must accompany it?
14. Which requirements are unresolved, stale, under legal review, or blocking launch in a jurisdiction?

# 6. Target architecture

The target state comprises a shared control plane and four modules.

## Shared governance and evidence control plane

- parameter registry;
- product legal-structure and operating-model registry;
- policy and strategy registry;
- experiment registry;
- scenario registry;
- risk-appetite registry;
- effective-dated jurisdiction and regulatory-requirement registry;
- disclosure, documentation, licensing/registration, reporting, record-retention, and data-segregation profile registry;
- Legal/Compliance review-status and ownership registry;
- reason-code catalog;
- run and campaign registry;
- latest/archive controls;
- parameter snapshots;
- validation evidence;
- acceptance records;
- requirements traceability;
- change control;
- regulatory applicability and offer-compliance-package snapshots;
- official-source and legal-opinion references.

## Module 1 — Merchant POS Cash-Flow, Verification, and Base-Risk Engine

Generates the deterministic merchant population, daily POS and deposit history, as-of features, cash-flow archetypes, credit/fraud/data-confidence dimensions, requested structure, EAD, collateral-adjusted LGD inputs, and comparative Expected Loss.

## Module 2 — Origination, Offer, Pricing, Collateral, and Covenant Strategy Engine

Applies eligibility, sizing, remittance, pricing, elasticity, counteroffer, collateral, covenant, risk-appetite, concentration, and portfolio-allocation logic.

## Module 3 — Daily Performance, Merchant Health, Line Management, and Loss Mitigation Engine

Monitors actual versus expected remittance, processor continuity, covenant compliance, merchant health, payoff slippage, dynamic line actions, renewals, workouts, cure, recovery, and exit decisions.

## Module 4 — Portfolio Strategy, Economic Stress, Industry Dependency, and Capital Allocation Engine

Propagates economic and industry shocks, evaluates segment vulnerability and concentration, compares strategy robustness, and supports annual and multi-year capacity allocation.

# 7. In-scope design areas

- merchant and owner/guarantor profiles;
- POS and deposit history;
- source lineage and data confidence;
- underwriting and exposure strategy;
- sales-linked repayment mechanics;
- fixed-fee or payback-multiple economics;
- analytical annualized cost;
- EAD, LGD, Expected Loss, and contribution;
- price elasticity and competitive response;
- collateral and covenant frameworks;
- counteroffers and low-and-grow programs;
- daily performance and merchant health;
- line management and renewals;
- loss mitigation and workout strategy;
- economic and industry stress;
- portfolio concentration and risk appetite;
- deterministic experiments and strategy frontiers;
- validation, evidence, and executive reporting;
- one-, three-, and five-year capability roadmap;
- regulation-aware product configuration and jurisdiction applicability;
- offer compliance-package generation and audit evidence;
- configurable Section 1071, financial-crime/KYB, payment-data-scope, marketing-transparency, and complaint-management controls.

# 8. Explicitly out of scope for initial validation

- production credit decisions;
- empirically calibrated PD, fraud, acceptance, or recovery models;
- production legal classification or contract drafting;
- accounting, tax, licensing, usury, true-sale, disclosure, or compliance conclusions;
- legal interpretation of any transaction, jurisdiction, or contractual term;
- automatic state-law determination without approved Legal/Compliance configuration;
- PCI DSS certification or storage/processing of real cardholder data;
- certification of a bank or nonbank BSA/AML, sanctions, customer-identification, or beneficial-ownership program;
- real merchant, owner, processor, or customer data;
- production reserve, capital, or regulatory stress estimates;
- production adverse-action notices;
- fair-lending conclusions;
- full payment-processing, settlement, servicing, or collections infrastructure;
- claims that hypothetical price elasticity represents observed merchant behavior.

# 9. Design principles

1. **Product specificity over field renaming.** Merchant economics must be modeled directly.
2. **Daily lifecycle over monthly delinquency convention.** Short-duration performance requires high-frequency evidence.
3. **Economic mechanics separated from legal classification.** Similar remittance behavior may exist under different legal forms.
4. **Multi-source evidence over bureau dependence.** POS, deposits, verification, owner/business credit, collateral, and relationship data must reconcile.
5. **Merchant-specific precision over universal rules.** Global policy must support industry, partner, cash-flow, relationship, and data-confidence overlays.
6. **Controlled learning over indiscriminate expansion.** Low-and-grow, experiment budgets, and explicit scale gates are required.
7. **Booked-value optimization over nominal pricing.** Acceptance, adverse selection, risk, costs, and relationship value must be considered together.
8. **Collateral and covenants as structured mitigants.** They affect eligibility, offer terms, monitoring, LGD, and workout options.
9. **Lifecycle portfolio ownership over origination-only analysis.** Lines, renewals, distress, recovery, and wallet expansion are part of strategy.
10. **Transmission-based stress over flat segment shocks.** Direct and second-order industry effects must be visible and bounded.
11. **Deterministic, parameterized, staged, and auditable design.** Identical inputs must produce identical outputs.
12. **Latest output separated from historical evidence.** Archives, comparison keys, and run registries are mandatory.
13. **Validation evidence over plausible appearance.** A script that runs is not automatically realistic or decision-ready.
14. **Regulatory configuration over hard-coded law.** Requirements must be effective-dated, sourced, owned, reviewed, approved, and versioned.
15. **Credit decision separate from compliance disposition.** A credit-viable offer cannot proceed when an approved compliance profile blocks, conditions, or requires additional documentation.
16. **Data minimization and scope clarity.** The simulator uses synthetic aggregated POS evidence and avoids real cardholder data; payment-data-security obligations depend on actual stored, processed, transmitted, or security-impacting data.
17. **Dated research over permanent claims.** Current regulatory research is recorded with an as-of date and review cadence rather than presented as timeless fact.
14. **Boundary-aware communication over overclaiming.** Synthetic outputs remain comparative and illustrative.

# 10. Primary deliverables

## Design package

- project charter;
- product mechanics decision record;
- one-/three-/five-year strategy roadmap;
- enterprise architecture;
- module charters and BRDs;
- logical and physical data models;
- data, feature, parameter, policy, collateral, covenant, scenario, and reason-code dictionaries;
- validation and requirements traceability framework;
- model and system boundaries;
- executive presentation.

## Implementation package

- PostgreSQL schemas and governed modules;
- deterministic synthetic outputs;
- scenario and strategy archives;
- campaign and experiment registries;
- validation evidence;
- sample exports;
- Power BI model and screenshots.

# 11. Definition of design-complete

The design is complete when:

- the product mechanics reconcile mathematically and terminologically;
- every module has a defined business question, grain, input, output, control, and boundary;
- every material field has a source, as-of rule, range, business purpose, and validation test;
- every decision lever maps to a parameter or governed policy;
- pricing includes acceptance and adverse-selection effects;
- performance distinguishes lower sales from withheld remittance or processor diversion;
- collateral and covenants have monitoring and action logic;
- stress results can be traced from shock to portfolio action;
- the one-/three-/five-year roadmap includes explicit scale gates;
- requirements trace across design, implementation, validation, and reporting;
- all outputs remain within synthetic, non-production boundaries.

# 12. Executive success criteria

A reviewer should conclude that the project demonstrates:

- transferable senior credit-risk judgment;
- ability to build a new portfolio capability rather than merely tune an existing score;
- strong integration of credit, pricing, Finance, Product, Operations, and data architecture;
- disciplined product and legal-boundary awareness;
- lifecycle portfolio ownership;
- credible stress and concentration thinking;
- enterprise governance, validation, and executive communication;
- a practical roadmap from Year 1 launch to Year 5 maturity.
