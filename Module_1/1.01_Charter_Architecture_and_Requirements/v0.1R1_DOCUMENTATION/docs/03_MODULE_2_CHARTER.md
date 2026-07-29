# Module 2 Charter
## Origination, Offer, Pricing, Collateral, Covenant, Compliance-Package, and Portfolio Allocation Engine

# 1. Business question

> Given an accepted Module 1 application-risk snapshot and approved strategy, policy, product, jurisdiction, and operating-model profiles, what offer—if any—is individually feasible, competitively acceptable, risk-adjusted profitable, properly mitigated, compliance-ready, and portfolio-compliant?

# 2. Purpose

Module 2 converts application evidence into candidate and final origination outcomes. It jointly evaluates amount, remittance, expected payoff horizon, fixed fee/payback multiple, acceptance, adverse selection, collateral, covenants, EAD, LGD, Expected Loss, contribution, compliance disposition, and portfolio capacity.

# 3. Primary grains

```text
offer candidate:
M1 source lineage × strategy_id × experiment_cell_id × candidate_id

final decision:
M1 source lineage × strategy_id × merchant_application_id

compliance package:
final_offer_id × compliance_package_version
```

# 4. Inputs

- accepted `M1_APPLICATION_RISK_SNAPSHOT_V1`;
- product legal-structure and operating-model profiles;
- global and overlay credit policies;
- strategy and experiment profiles;
- pricing, cost, and elasticity parameters;
- collateral and guarantee policy;
- covenant policy;
- risk appetite and funding budget;
- jurisdiction/regulatory profiles and applicability rules;
- competitor-price and market assumptions.

# 5. Processing stages

| Stage | Purpose |
|---|---|
| M2.0 | Source/run/strategy/product/jurisdiction identity |
| M2.1 | Profile and source gatekeeper |
| M2.2 | Deterministic experiment assignment |
| M2.3 | Verification, fraud, unsupported-feature, and compliance pre-gates |
| M2.4 | Merchant, risk, cash-flow, relationship, industry, and channel segmentation |
| M2.5 | Non-final credit policy flags and preliminary route |
| M2.6 | Candidate amount/remittance/horizon/price generation |
| M2.7 | Candidate collateral, guarantee, and covenant package generation |
| M2.8 | Candidate burden and offer-specific risk/EAD/LGD/EL |
| M2.9 | Acceptance, competitor displacement, and adverse-selection estimate |
| M2.10 | Revenue, cost, expected contribution, and return proxy |
| M2.11 | Candidate feasibility and ranking |
| M2.12 | Regulatory applicability snapshot and compliance package |
| M2.13 | Individual final decision resolution |
| M2.14 | Funding budget, credit-mix, and concentration allocation |
| M2.15 | Final outcome, compliance disposition, and reason codes |
| M2.16 | Booking contract for accepted/funded offers |
| M2.17 | Latest/archive, matched comparison, frontier, evidence, and acceptance |

# 6. Candidate-offer dimensions

P0 candidate grid varies:

- funded amount;
- total repayment amount or fixed fee/payback multiple;
- remittance percentage;
- expected payoff horizon;
- minimum-progress requirement;
- collateral/guarantee package;
- covenant package;
- standard versus low-and-grow program;
- relationship discount or competitor-retention treatment.

# 7. Economics

```text
Expected Booked Contribution
= Acceptance Probability
× (
    Finance Revenue
  − Cost of Funds
  − Partner/Broker/Acquisition Cost
  − Servicing and Payment Cost
  − Expected Credit Loss
  − Capital/Risk Charge
  − Expected Incentive or Retention Cost
)
```

The engine must expose both conditional contribution if booked and probability-weighted expected booked contribution.

# 8. Pricing and elasticity

Separate components:

- acceptance elasticity to price and offer structure;
- competitive displacement from price/term gaps;
- risk elasticity from higher remittance or burden;
- adverse selection as stronger merchants reject unattractive offers;
- relationship elasticity and future wallet value.

Synthetic elasticity curves are scenario assumptions, not observed causal estimates.

# 9. Collateral and covenant treatment

Collateral affects eligibility and LGD through availability, eligibility, valuation, haircut, lien/control, recovery cost, timing, and stress. It does not automatically reduce PD.

Every covenant must define:

- metric/source;
- test frequency;
- threshold and warning;
- breach and cure;
- action and owner;
- waiver authority;
- monitoring start/end.

# 10. Credit and compliance separation

Module 2 records:

```text
credit_outcome
    APPROVE / COUNTEROFFER / MANUAL_REVIEW / DECLINE

compliance_disposition
    CLEAR / CONDITIONED / REVIEW / BLOCK
```

A merchant-facing offer requires a positive credit result **and** `CLEAR` or fully satisfied `CONDITIONED` compliance status. Credit cannot override `BLOCK`.

# 11. Final outcome logic

| Credit result | Compliance result | Portfolio allocation | Final treatment |
|---|---|---|---|
| Approve/counteroffer | Clear | Allocated | Offer eligible for booking |
| Approve/counteroffer | Conditioned | Reserved | Pending required condition |
| Approve/counteroffer | Review | Not final | Legal/Compliance review |
| Any positive | Block | None | No offer |
| Review | Any | None/reserved | Manual review path |
| Decline | Any | None | Decline |

# 12. Owned logical tables

- `experiment_assignment`;
- `application_segment_snapshot`;
- `offer_candidate`;
- `candidate_collateral_requirement`;
- `candidate_covenant_requirement`;
- `candidate_risk_economics`;
- `elasticity_result`;
- `regulatory_applicability_snapshot`;
- `offer_compliance_package`;
- `offer_decision`;
- `offer_reason_code`;
- `portfolio_allocation_result`;
- `credit_facility`;
- `facility_limit_snapshot`;
- `financing_advance`;
- `advance_collateral_link`;
- `advance_covenant`;
- `module2_latest`;
- `module2_archive`.

# 13. Output contracts

- `M2_FINAL_DECISION_V1`;
- `M2_OFFER_COMPLIANCE_PACKAGE_V1`;
- `M2_BOOKED_ADVANCE_V1` for funded/accepted offers;
- strategy/experiment/frontier evidence.

# 14. Exclusions

Module 2 does not:

- observe future repayment performance;
- execute contracts or disclosures;
- certify licensing or legal form;
- perform production demand optimization;
- execute collections or workouts;
- forecast macroeconomic outcomes.

# 15. P0 validation

- exactly one final decision per application/strategy;
- bounded candidate count and deterministic ranking;
- all positive candidates pass capacity and risk limits;
- price cannot cure failed affordability;
- contribution identity reconciles;
- adverse selection moves booked mix directionally;
- collateral and covenants affect intended components only;
- compliance package matches final offer and approved profile;
- stale/unapproved profiles fail closed;
- allocation does not exceed funding or concentration limits;
- reason codes are deterministic and mutually coherent;
- booking contract reconciles to final offer.

# 16. Acceptance gate

Module 2 is accepted when every final outcome is individually explainable, economically reconciled, mitigation-aware, compliance-dispositioned, portfolio-allocated, and reproducible from accepted Module 1 and control-plane contracts.
