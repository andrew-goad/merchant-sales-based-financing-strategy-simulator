# Regulatory Source and Boundary Bridge
## Merchant Sales-Based Financing Strategy Simulator v0.1R1

This package inherits the regulatory design baseline and official-source controls in the updated kickoff pack:

- `10_REGULATORY_AND_POLICY_CONFIGURATION_FRAMEWORK.md`;
- `11_OFFICIAL_SOURCE_AND_REGULATORY_RESEARCH_NOTE.md`;
- `13_REGULATORY_CHANGE_IMPACT_ASSESSMENT_2026_07_23.md`.

# Current-rule bridge — as of 2026-07-23

The CFPB reconsideration rule effective June 30, 2026 expressly excludes a qualifying merchant cash advance under the current regulatory definition, while other sales-based loans, lines, and hybrid structures may remain covered unless another exclusion applies. The architecture therefore stores an approved, effective-dated transaction classification and rule version; it does not infer coverage from the product label. The current compliance date for covered institutions is January 1, 2028.

# Architecture use

The architecture operationalizes the kickoff controls through:

- effective-dated legal-structure, operating-model, jurisdiction, requirement, reporting, and applicability profiles;
- explicit transaction-classification evidence and current-rule supersession;
- separate credit outcome and compliance disposition;
- disclosure, permission, reporting, financial-crime, data-segregation, and payment-data-scope controls;
- fail-closed behavior for stale, unresolved, unsupported, or unapproved configurations;
- historical reconstruction of the rules and profiles selected for each simulated offer;
- explicit exclusion of production legal conclusions and real payment account data.

# Boundary

The package is a strategy, architecture, and synthetic-simulation design artifact. It does not provide legal advice, classify a real transaction as a loan or true sale, determine licensing status, generate legally sufficient disclosures, certify Section 1071 treatment, certify BSA/AML or PCI DSS compliance, or approve production use.
