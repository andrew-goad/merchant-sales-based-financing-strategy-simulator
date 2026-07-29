# Project Artifact Map

## Start Here

1. [`README.md`](./README.md) - executive overview, accepted release facts, and reviewer paths.
2. [`Enterprise_Merchant_Sales_Based_Financing_Platform.png`](./docs/enterprise_architecture/Enterprise_Merchant_Sales_Based_Financing_Platform.png) - flagship enterprise architecture.
3. [`From_First_Advance_to_Intelligent_Portfolio.pdf`](./docs/executive_strategy/From_First_Advance_to_Intelligent_Portfolio.pdf) - eight-page executive strategy brief.
4. [`Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png`](./docs/enterprise_architecture/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png) - detailed stage and contract lineage.
5. [`MODULE_AND_RELEASE_INDEX.md`](./MODULE_AND_RELEASE_INDEX.md) - accepted revision and hash index.
6. [`M1.16 README`](./Module_1/1.16_Acquisition_Attribution_and_CAC/README.md) - acquisition source, attribution, and merchant CAC foundations.
7. [`M1.17 README`](./Module_1/1.17_End_to_End_QA_and_G2_Acceptance/README.md) - end-to-end assurance and G2 acceptance.
8. [`GOVERNANCE_AND_VALIDATION.md`](./GOVERNANCE_AND_VALIDATION.md) - control philosophy, recovery standard, and final certification.
9. [`PUBLIC_REVIEW_COHORT_REGISTRY.csv`](./docs/project_lineage/public_review_cohort/PUBLIC_REVIEW_COHORT_REGISTRY.csv) - stable public IDs for 50 synthetic applications.

## Repository Structure

```text
merchant-sales-based-financing-strategy-simulator/
├── README.md
├── PROJECT_ARTIFACT_MAP.md
├── MODULE_AND_RELEASE_INDEX.md
├── PROJECT_ROADMAP.md
├── SAMPLE_DATA_AND_EVIDENCE_POLICY.md
├── REPRODUCIBILITY_AND_EXECUTION.md
├── GOVERNANCE_AND_VALIDATION.md
├── docs/
│   ├── executive_strategy/
│   ├── enterprise_architecture/
│   └── project_lineage/
├── Module_0/
│   ├── 0.01_G0_Physical_Data_Foundation/
│   └── 0.02_G1_Governed_Run_Control/
└── Module_1/
    ├── 1.01_Charter_Architecture_and_Requirements/
    ├── 1.02_Deterministic_Merchant_Population/
    ├── ...
    ├── 1.16_Acquisition_Attribution_and_CAC/
    └── 1.17_End_to_End_QA_and_G2_Acceptance/
```

Every governed stage contains a stage README and an exact accepted-version directory organized into `docs/`, `outputs/`, `src/`, and `tests/`.

## Enterprise-Level Artifacts

| Artifact | Role |
|---|---|
| Flagship enterprise architecture | Executive system map and accepted G2 state |
| Detailed Module 1 lineage | Technical stage, contract, hash, and acceptance chain |
| From First Advance to Intelligent Portfolio | Strategic launch, learning, relationship, and long-horizon narrative |
| Complete accepted hash chain | All 18 G1-through-M1.16 physical identities |
| Public Review Cohort | Cross-stage navigation for 50 deterministic synthetic applications |

## Current vs. Historical Artifacts

The public repository contains final accepted clean-build source and concise correction histories. The private canonical repository remains the audit-complete source of truth for all raw failures, superseded source, recovery execution, and DBeaver exports.

M1.17 has one explicit source-provenance limitation: exact standalone v0.2R2 source files for Programs 124C-128 were not retained in the active runtime. The public package preserves the accepted execution evidence and original-plus-hotfix source chain and does not label reconstructed code as byte-identical executed source.

## Module 0

- [`G0 Physical Data Foundation`](./Module_0/0.01_G0_Physical_Data_Foundation/README.md)
- [`G1 Governed Run Control`](./Module_0/0.02_G1_Governed_Run_Control/README.md)

## Module 1

- [`M1.2 - Deterministic Merchant Population`](./Module_1/1.02_Deterministic_Merchant_Population/README.md)
- [`M1.3 - Application & Requested Sales-Linked Structure`](./Module_1/1.03_Application_and_Requested_Structure/README.md)
- [`M1.4 - Daily POS, Settlement & Merchant Ecosystem`](./Module_1/1.04_Daily_POS_Settlement_and_Ecosystem/README.md)
- [`M1.5 - Daily Deposit & Liquidity History`](./Module_1/1.05_Daily_Deposit_and_Liquidity_History/README.md)
- [`M1.6 - Matched POS & Deposit Scenario Overlays`](./Module_1/1.06_Matched_POS_and_Deposit_Scenarios/README.md)
- [`M1.7 - Source Quality & Data Confidence`](./Module_1/1.07_Source_Quality_and_Data_Confidence/README.md)
- [`M1.8 - Verification, Fraud & Processor Continuity`](./Module_1/1.08_Verification_Fraud_and_Continuity/README.md)
- [`M1.9 - As-of Cash-Flow Feature Engineering`](./Module_1/1.09_As_Of_Cash_Flow_Features/README.md)
- [`M1.10 - Obligations, Liquidity & Residual Cash Flow`](./Module_1/1.10_Obligations_Liquidity_and_Capacity/README.md)
- [`M1.11 - Cash-Flow Archetypes & Operating Resilience`](./Module_1/1.11_Cash_Flow_Archetypes_and_Resilience/README.md)
- [`M1.12 - Merchant Risk Components & Integrated Risk Proxy`](./Module_1/1.12_Merchant_Risk_and_Integrated_Proxy/README.md)
- [`M1.13 - Exposure, Recovery & Expected Loss Foundations`](./Module_1/1.13_Exposure_Recovery_and_Expected_Loss/README.md)
- [`M1.14 - Unit Economics & Risk-Adjusted Contribution`](./Module_1/1.14_Unit_Economics_and_Contribution/README.md)
- [`M1.15 - Latest, Archive, Comparison & Consumption Contract`](./Module_1/1.15_Latest_Archive_Comparison_and_Contract/README.md)
- [`M1.16 - Acquisition Source, Marketing Attribution & Merchant CAC`](./Module_1/1.16_Acquisition_Attribution_and_CAC/README.md)
- [`M1.17 - End-to-End QA, Evidence & G2 Contract Acceptance`](./Module_1/1.17_End_to_End_QA_and_G2_Acceptance/README.md)

## Sample Data and Evidence

The public repository does not upload every full-population operational extract. It publishes accepted aggregate evidence, selected G2 integrated records, zero-row exception outputs with headers, and a deterministic 50-application review cohort. Full-population counts, hashes, and acceptance controls remain the governing evidence.

See [`SAMPLE_DATA_AND_EVIDENCE_POLICY.md`](./SAMPLE_DATA_AND_EVIDENCE_POLICY.md).

## Suggested Reviewer Paths

### Fast Executive Review

`README -> Flagship Architecture -> Strategy Brief -> M1.16 -> M1.17 G2`

### Technical / Architecture Review

`Detailed Lineage -> Charter -> Stage SQL -> M1.15 Contract -> M1.16 Companion Contract -> Integrated G2 Interface`

### Governance / Validation Review

`Governance Guide -> Hash Chain -> Positive / Negative Controls -> Archive Triggers -> Zero-Row Exceptions -> Formal Sign-Off`

## Documentation Status

All public `main` branch artifacts in this release are accepted or are clearly labeled GitHub-derived publication documents. There are no “coming soon” placeholders in the v1.0.0 release. Power BI remains planned and is not represented as implemented.
