# Regulatory and Policy Configuration Framework
## Merchant Sales-Based Financing Strategy Simulator v0.1R2

**As-of date:** 2026-07-23  
**Purpose:** Define how the simulator represents changing legal, regulatory, conduct, financial-crime, disclosure, reporting, and payment-data-security obligations without issuing legal conclusions or hard-coding state law.

# 1. Executive design position

The platform is **regulation-aware, not a legal or compliance adjudicator**. It separates four questions:

```text
1. Is the merchant and requested exposure credit-feasible?
2. Is an economically viable offer available?
3. Which approved legal/compliance requirement profile applies?
4. Is the offer clear, conditioned, under review, or blocked?
```

The answer to Question 1 or 2 cannot override Question 3 or 4.

# 2. Why configuration is required

Merchant sales-based financing may be structured as a loan, receivables purchase, hybrid, or another commercial-financing form. Requirements can vary by:

- legal structure and contractual substance;
- provider, bank-partner, processor, broker, servicer, or funding entity role;
- merchant and provider jurisdiction;
- transaction amount and recipient characteristics;
- remittance, reconciliation, maturity, collateral, and recourse mechanics;
- channel, solicitation, broker, and compensation model;
- effective date and transition rules;
- federal and state reporting, data, marketing, servicing, and collections obligations.

The architecture must therefore store approved interpretations and requirements as data rather than embed unreviewed conclusions in credit logic.

# 3. Governing principles

1. **Effective dating:** every requirement has an effective start, optional end, and review date.
2. **Source lineage:** every record points to an official source and, where applicable, a legal opinion or compliance memorandum.
3. **Named ownership:** Legal owns interpretation; Compliance owns implementation requirements; Credit owns credit policy; Technology owns execution controls.
4. **Fail closed:** stale, unresolved, unapproved, or out-of-scope profiles produce review or block.
5. **No silent override:** credit, pricing, Sales, or Operations cannot bypass a compliance block.
6. **Frozen decision evidence:** each offer retains the exact context, requirement version, calculation method, documents, and disposition used.
7. **No permanent claims:** regulatory research is dated and periodically recertified.
8. **Data minimization:** the simulator uses synthetic aggregate/tokenized POS data and does not store real cardholder data.

# 4. Control-plane registries

| Registry | Grain | Core purpose |
|---|---|---|
| `product_legal_structure_profile` | One row per structure/version/effective period | Working legal form, interpretation status, reconciliation/recourse characteristics |
| `operating_model_profile` | One row per entity-role model/version | Provider, bank, processor, broker, servicer, funding, and collections responsibilities |
| `jurisdiction_profile` | One row per jurisdiction/version/effective period | Approved geographic scope and launch status |
| `regulatory_requirement` | One row per requirement/version | Obligation, source, owner, dates, status, applicability dimensions |
| `regulatory_applicability_rule` | One row per requirement and rule version | Machine-readable approved applicability conditions |
| `disclosure_template` | One row per disclosure/version | Required fields, format, calculation profile, document template |
| `license_registration_requirement` | One row per role/jurisdiction/product/version | Required permission, registration, expiry, and validation method |
| `broker_requirement` | One row per broker/channel/jurisdiction/version | Registration, compensation, disclosure, and conduct controls |
| `reporting_requirement` | One row per reporting program/version | Coverage, data, timing, submission, and record-retention requirements |
| `data_segregation_requirement` | One row per requirement/version | Storage, firewall, access, masking, and audit controls |
| `financial_crime_role_profile` | One row per operating model/version | KYB, identification, beneficial-owner, sanctions, AML, monitoring, and reporting ownership |
| `payment_data_scope_profile` | One row per integration/version | Whether the environment stores, processes, transmits, or impacts payment account data |
| `unsupported_feature_catalog` | One row per excluded feature/version | Features that cannot be recommended or enabled by the simulator |
| `regulatory_review_attestation` | One row per profile/review event | Reviewer, decision, evidence, date, next review, findings |

# 5. Requirement lifecycle

```text
DRAFT
→ LEGAL_REVIEW
→ COMPLIANCE_REVIEW
→ APPROVED
→ SUPERSEDED or RETIRED
```

Only an `APPROVED` record whose effective date covers the offer date and whose review date has not expired can generate a compliance-ready result.

# 6. Applicability flow

```text
Frozen Offer Context
  merchant jurisdiction
  provider and partner entities
  channel and broker
  product legal structure
  amount and recipient characteristics
  offer mechanics
  decision date
        ↓
Approved Jurisdiction and Operating-Model Profile
        ↓
Applicable Requirement Evaluation
        ↓
Disclosure / License / Reporting / Data / Document Requirements
        ↓
Compliance Disposition
        ↓
Versioned Offer Compliance Package
        ↓
Archive and Evidence
```

# 7. Compliance dispositions

| Code | Meaning | Credit-engine consequence |
|---|---|---|
| `COMPLIANCE_CLEAR` | All approved requirements satisfied | Offer may proceed subject to credit and operations |
| `COMPLIANCE_CONDITIONED` | Offer may proceed only after specified condition or document | Finalization blocked until condition evidence exists |
| `COMPLIANCE_REVIEW` | Applicability or requirement unresolved | Route to Legal/Compliance; no merchant-facing offer |
| `COMPLIANCE_BLOCK` | Product/entity/jurisdiction not permitted or required permission absent | Offer cannot proceed |

# 8. Offer compliance package

Each candidate/final offer can produce:

```text
compliance_package_id
regulatory_profile_id
product_legal_structure_profile_id
operating_model_profile_id
jurisdiction_profile_id
applicability_snapshot_id
compliance_disposition
required_disclosure_template_ids
required_calculation_profile_ids
required_license_registration_checks
required_broker_documents
required_contract_document_ids
required_reporting_flags
required_data_segregation_profile_id
required_record_retention_profile_id
required_marketing_or_script_controls
required_manual_approvals
unresolved_requirement_count
package_generated_at
package_version
```

# 9. Section 1071 architecture

Section 1071 treatment is effective-dated. Under the CFPB reconsideration rule effective June 30, 2026, an agreement that meets the rule’s current merchant-cash-advance definition—an upfront lump-sum payment in exchange for the right to receive a percentage of the small business’s future sales or income up to a ceiling amount—is an excluded transaction. Other business credit, including sales-based loans, lines of credit, or hybrid structures that do not meet an exclusion, may remain covered. The current compliance date for covered institutions is January 1, 2028.

Accordingly, the platform will not derive Section 1071 treatment from a marketing name. An approved Legal/Compliance classification must compare the transaction’s substance to the effective rule. The Section 1071 profile must be effective-dated and capable of configuring:

- covered financial-institution threshold and lookback;
- covered/excluded transaction types;
- small-business definition;
- compliance date and transition rules;
- required data points;
- applicant demographic-information workflow;
- firewall or exception treatment;
- separate storage and role-based access;
- submission and correction timing;
- record retention;
- evidence of compliance.

The frozen applicability snapshot should also record:

```text
transaction_regulatory_classification_code
classification_basis_code
classification_evidence_reference
effective_rule_version
effective_rule_date
current_mca_exclusion_applied_flag
other_exclusion_code
coverage_determination
coverage_determination_owner
coverage_approved_at
next_review_date
```

No credit-decision field may be populated from protected demographic data collected solely for reporting unless separately lawful, approved, and documented.

# 10. Commercial-financing disclosure architecture

Official California and New York materials demonstrate that sales-based financing can require specialized commercial-financing disclosures, including estimated annualized-cost calculations and product-specific formats. The system therefore supports, but does not pre-populate as legal truth:

- funding amount;
- disbursement amount after fees;
- finance charge or cost of financing;
- total repayment/delivery amount;
- estimated payment/remittance amounts;
- payment frequency;
- estimated term/payoff assumptions;
- estimated APR or annualized cost where required;
- prepayment treatment;
- collateral and security interests;
- broker compensation;
- assumptions and reconciliation language.

Each field is generated only from an approved calculation/template profile.

# 11. Conduct, marketing, withdrawals, servicing, and collections

FTC materials support explicit controls for:

- accurate funding and fee representation;
- clear explanation of variable remittance and reconciliation;
- documented authorization for withdrawals;
- prevention of withdrawals beyond contractual authorization;
- complaint monitoring and root-cause analysis;
- fair and transparent servicing and collections;
- unsupported or prohibited contract-feature controls.

Confessions of judgment are excluded from the simulator's recommended strategy set.

# 12. Financial-crime and merchant verification

The simulator records responsibilities rather than certifying a program. The operating-model role matrix can assign:

- merchant entity verification;
- beneficial-owner identification and verification;
- owner/guarantor identification;
- sanctions screening;
- business-purpose and source-of-funds review;
- transaction monitoring;
- suspicious-activity investigation/reporting;
- ongoing due diligence;
- escalation and account closure.

Unassigned or disputed responsibilities block launch readiness. The profile is effective-dated because current requirements and relief can change. For example, FinCEN issued 2026 exceptive relief from identifying and verifying beneficial owners each time an existing legal-entity customer opens another account, while retaining initial, reliability-triggered, and risk-based obligations. The simulator records the approved role/profile version; it does not hard-code the pre-relief workflow.

# 13. Payment-data security boundary

PCI DSS applies to environments that store, process, or transmit payment account data, and can also be relevant to systems that affect its security. The public simulator will use only synthetic daily aggregates or tokenized identifiers. It will not contain:

- primary account numbers;
- sensitive authentication data;
- card verification values;
- PIN data;
- real cardholder identity;
- production processor credentials.

A future production integration would require a separate security and PCI-scope assessment.

# 14. Validation controls

Required P0 tests include:

1. Only approved, effective, non-stale profiles are used.
2. Applicability results reproduce from frozen context and profile version.
3. Credit outcome cannot override compliance disposition.
4. Required disclosures and calculations reconcile to the final offer.
5. License/registration status and expiration are validated.
6. Unresolved requirements generate review/block.
7. Section 1071 data is segregated and access-controlled under the active profile.
8. Official-source references and review dates are present.
9. Archived offers reproduce the exact compliance package.
10. No real cardholder data exists in simulator outputs.
11. Unsupported features cannot be selected.
12. Superseded rules do not apply after their effective end date.

# 15. Boundary statement

This framework is a software and governance design pattern. It is not legal advice, a state-law survey, a license determination, a regulatory approval, a PCI DSS certification, or a BSA/AML program assessment. Production use would require qualified Legal, Compliance, Information Security, BSA/AML, Operations, and independent validation review.
