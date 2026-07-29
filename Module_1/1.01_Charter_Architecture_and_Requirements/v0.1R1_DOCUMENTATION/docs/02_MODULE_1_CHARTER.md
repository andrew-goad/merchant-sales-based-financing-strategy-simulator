# Module 1 Charter
## Merchant POS Cash-Flow, Verification, and Base-Risk Engine

# 1. Business question

> Given a deterministic merchant/application population and an application as-of date, what cash-flow, liquidity, data-confidence, verification, fraud, credit-risk, requested-structure, EAD, LGD-input, and Expected Loss evidence is available without using future information?

# 2. Purpose

Module 1 creates the synthetic merchant and as-of risk foundation. It is the only module allowed to generate baseline merchant/day histories and origination feature snapshots.

# 3. Primary output grain

```text
one row per
population_id
× module1_scenario_id
× merchant_application_id
```

Primary contract: `M1_APPLICATION_RISK_SNAPSHOT_V1`.

# 4. Inputs

- approved product/operating/source profiles;
- deterministic population and scenario parameters;
- merchant and owner/guarantor master data;
- daily POS, settlement, refund, chargeback, and processor continuity data;
- optional daily deposit/liquidity data;
- business/owner credit and adverse-event evidence;
- verification, fraud, sanctions/KYB statuses;
- existing obligations and stacking;
- collateral availability and guarantee availability—not final offer package;
- application request and as-of date;
- industry and channel reference data.

# 5. Processing stages

| Stage | Purpose |
|---|---|
| M1.0 | Scope, boundary, and run identity |
| M1.1 | Approved profile/parameter/source gatekeeper |
| M1.2 | Deterministic merchant, owner, partner, processor, and relationship population |
| M1.3 | Application/request generation |
| M1.4 | Baseline daily POS and settlement generation |
| M1.5 | Optional deposit/liquidity generation |
| M1.6 | Scenario overlays applied to matched history |
| M1.7 | Source completeness, freshness, reconciliation, and confidence |
| M1.8 | Verification, fraud, and operational-continuity evidence |
| M1.9 | As-of revenue level, trend, volatility, seasonality, and quality features |
| M1.10 | Liquidity, obligations, stacking, and residual cash-flow features |
| M1.11 | Cash-flow archetype assignment |
| M1.12 | Requested remittance/payment burden and capacity |
| M1.13 | Base merchant credit-risk proxy and component diagnostics |
| M1.14 | Requested-structure risk overlay |
| M1.15 | EAD path and collateral/guarantee LGD inputs |
| M1.16 | Comparative Expected Loss |
| M1.17 | Latest output and archive |
| M1.18 | QA, matched scenario comparison, evidence, and acceptance |

# 6. Core calculations

## Eligible revenue

```text
Gross POS Sales
− Refunds
− Chargebacks
− Reversals
− governed exclusions
= Eligible POS Sales
```

## Capacity

```text
Adjusted Eligible Revenue
× Synthetic Industry Cash-Flow Conversion Margin
− Existing Fixed Obligations
= Cash Flow Available for New Remittance
```

## Requested burden

```text
Expected Remittance
= Expected Eligible Sales × Requested Remittance Percentage
```

Supporting measures include total remittance-to-sales, post-financing coverage, residual cash flow, requested amount-to-sales, and expected payoff horizon.

## Risk dimensions

Module 1 preserves separate outputs:

```text
credit_risk_proxy
fraud_risk_tier
data_confidence_tier
operational_continuity_status
```

## Expected loss

```text
Expected Loss
= Requested-Structure Risk Proxy × LGD × Expected EAD
```

The risk proxy, LGD, and EAD remain synthetic comparative measures.

# 7. Owned logical tables

P0 ownership:

- `merchant_master`;
- `merchant_owner_guarantor`;
- `merchant_relationship_snapshot`;
- `partner_channel`;
- `processor_account`;
- `merchant_application`;
- `merchant_pos_daily_base`;
- `merchant_pos_daily_scenario`;
- `merchant_deposit_daily_base`;
- `merchant_deposit_daily_scenario`;
- `source_snapshot`;
- `verification_result`;
- `merchant_feature_snapshot`;
- `merchant_risk_snapshot`;
- `module1_latest`;
- `module1_archive`.

# 8. Output contract — mandatory field families

- run/scenario/population/application identity;
- merchant/industry/channel/relationship identifiers;
- application/as-of/history dates;
- source availability, freshness, reconciliation, confidence;
- verification/fraud/operational continuity;
- trailing revenue and transaction-quality measures;
- liquidity and obligations;
- cash-flow archetype;
- requested amount, remittance, expected horizon, total repayment;
- capacity and burden measures;
- credit-risk components and final proxy;
- EAD path summary, LGD inputs, Expected Loss;
- diagnostic and boundary flags.

# 9. Downstream consumers

- Module 2 candidate-offer and decision engine;
- Module 4 origination stress analysis;
- validation/evidence layer;
- future feature/model-development work.

# 10. Exclusions

Module 1 does not:

- select a final offer;
- optimize price;
- determine acceptance;
- assign final collateral/covenants;
- determine regulatory applicability or compliance disposition;
- book an advance;
- use observed post-application performance;
- issue a production PD or legal conclusion.

# 11. P0 validation

- deterministic reproduction;
- stable merchant/application/history keys;
- no observation after as-of date;
- POS gross-to-net-to-eligible reconciliation;
- source outage distinct from merchant deterioration;
- realistic industry/cash-flow distributions;
- mixed-signal merchants retained;
- risk components directional and bounded;
- EAD declines through expected payoff path;
- collateral availability is not treated as final perfected collateral;
- matched scenario differences attributable to governed overlays;
- contract schema/version and row count pass.

# 12. Acceptance gate

Module 1 is accepted when it produces a complete, deterministic, leakage-free application-risk contract that Module 2 can consume without reverse-engineering stage tables.

## M1.16 ACQUISITION FOUNDATIONS ADDENDUM

Module 1 now includes acquisition source, campaign funnel, attribution, cost timing/allocation, M1.14 overlap reconciliation, and a companion immutable acquisition contract. M1.17 performs final end-to-end QA and issues G2.
