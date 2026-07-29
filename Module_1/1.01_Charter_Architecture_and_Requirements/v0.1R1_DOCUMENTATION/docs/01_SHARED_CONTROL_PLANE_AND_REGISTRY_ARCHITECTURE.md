# Shared Control Plane and Registry Architecture
## Merchant Sales-Based Financing Strategy Simulator v0.1R1

# 1. Purpose

The control plane provides the governed configuration, identity, lineage, and evidence needed by all four modules. It centralizes assumptions without centralizing business calculations that belong inside a module.

# 2. Registry catalog

| Registry | Logical grain | Primary owner | Main consumers | P0 purpose |
|---|---|---|---|---|
| Product legal-structure profile | Structure × version × effective period | Legal/Product | M2, reporting | Separate economic mechanics from approved legal interpretation |
| Operating-model profile | Entity-role model × version | Legal/Compliance/Operations | M1–M3 | Assign provider, bank, processor, broker, servicer, funding, and collections roles |
| Third-party relationship profile | Provider/service/role × version × effective period | Operations/Risk/Compliance | M1–M3 | Due diligence, responsibilities, monitoring, incidents, remediation, subcontractors, continuity, and exit |
| Parameter set/value | Parameter set × name × effective period | Model/Strategy owner | All modules | Centralize numeric and categorical assumptions |
| Policy profile | Policy × version × effective period | Credit Policy | M1–M3 | Approved eligibility, limits, covenant, collateral, and lifecycle rules |
| Strategy profile | Strategy × version | Portfolio/Credit Strategy | M2–M4 | Champion/challenger configuration and objective |
| Experiment registry/cell | Experiment × generation × cell | Strategy/Analytics | M2–M4 | Deterministic testing and exposure budgets |
| Scenario registry | Scenario × version | Portfolio/Stress | M1, M4 | Baseline and stress assumptions |
| Risk-appetite limit | Limit × segment scope × effective period | Credit Committee | M2–M4 | Limit, warning, action, owner, and review cadence |
| Jurisdiction profile | Jurisdiction × version × effective period | Legal/Compliance | M2 | Approved product and entity scope |
| Regulatory requirement | Requirement × version | Legal/Compliance | M2, reporting | Effective-dated obligations and official-source lineage |
| Applicability rule | Requirement × rule version | Compliance/Technology | M2 | Approved machine-readable applicability conditions |
| Disclosure/calculation profile | Template or method × version | Compliance/Legal | M2 | Required fields, calculations, format, and assumptions |
| License/registration profile | Entity role × jurisdiction × product × version | Legal/Compliance | M2 | Permission status and expiry validation |
| Small-business data-reporting profile (including Section 1071 where applicable) | Reporting program × version | Compliance/Data | M1, M2, reporting | Product scope, institutional threshold, data, dates, firewall, submission, and retention |
| Financial-crime role profile | Operating model × version | BSA/AML/Compliance | M1–M3 | KYB, beneficial owner, sanctions, AML, monitoring, reporting roles |
| Payment-data scope profile | Integration × version | Information Security | M1–M3 | Data classification and PCI-scope evidence |
| Source/data-contract registry | Source × contract version | Data Owner | M1–M4 | Grain, freshness, completeness, lineage, and quality SLA |
| Reason-code catalog | Reason code × version | Policy/Compliance | M2–M3 | Deterministic explanation and action evidence |
| Run registry | Technical run | Platform owner | All modules | Execution identity, status, code, profile, and source snapshot |
| Comparison registry | Comparison definition | Analytics/Governance | M1–M4 | Explicit baseline/challenger/scenario pairing |
| Evidence/acceptance registry | Run × gate/metric | Validation/Governance | Reporting | QA results, findings, acceptance, and residual limitations |
| Unsupported-feature catalog | Feature × version | Legal/Compliance | M2–M3 | Prevent prohibited or intentionally excluded strategies |

# 3. Current-rule classification principle

As of 2026-07-23, the CFPB rule effective June 30, 2026 expressly excludes a qualifying merchant cash advance under the current definition. The control plane still cannot infer Section 1071 treatment from `product_name` or `legal_structure_code` alone. It must freeze an approved transaction-classification result, effective rule version, evidence reference, owner, and approval date. Other sales-based loans, lines, and hybrid products remain subject to separate coverage analysis.

# 4. Profile versioning standard

Every approved profile contains:

```text
profile_id
profile_version
business_name
effective_start_date
effective_end_date
status
owner_role
approver_role
approval_timestamp
source_reference_id
supersedes_profile_id
last_review_date
next_review_date
change_reason
```

Statuses are explicit. For regulatory requirements:

```text
DRAFT → LEGAL_REVIEW → COMPLIANCE_REVIEW → APPROVED → SUPERSEDED/RETIRED
```

For credit policy/strategy:

```text
DRAFT → VALIDATION → GOVERNANCE_REVIEW → APPROVED → RETIRED
```

# 5. Policy inheritance and precedence

The control plane resolves configuration in a fixed order. A more specific approved profile can tighten but cannot weaken a non-overridable control without an approved exception path.

```text
Unsupported / regulatory block
→ Product legal structure and operating model
→ Jurisdiction requirements
→ Enterprise risk appetite hard limits
→ Global product policy
→ Product / industry / channel overlays
→ Relationship-stage overlay
→ Strategy profile
→ Experiment cell
→ Authorized manual exception
```

Credit exceptions cannot override regulatory blocks, unsupported features, expired licenses, or data-security scope constraints.

# 6. Run lifecycle

```text
PLANNED
→ CONFIGURED
→ GATEKEEPER_PASSED
→ RUNNING
→ TECHNICALLY_COMPLETE
→ QA_COMPLETE
→ ACCEPTED or REJECTED
→ ARCHIVED
```

A run stores immutable references to:

- population ID;
- as-of date;
- scenario version;
- strategy/policy versions;
- regulatory/jurisdiction profile versions;
- source snapshot IDs;
- parameter snapshot ID;
- code version/hash;
- module contract version;
- comparison/campaign/experiment IDs.

# 7. Fail-fast gatekeepers

P0 pre-run gates include:

- one active parameter set per intended run;
- valid mix sums, bounds, and calculation assumptions;
- complete source contracts and as-of dates;
- no unapproved profile reference;
- no stale regulatory or license/registration profile;
- legal structure and operating model compatible with selected jurisdiction profile;
- no unsupported feature enabled;
- risk-appetite limits have owner/action/thresholds;
- comparison baselines exist and use compatible population/account keys;
- Section 1071 data-separation profile present when required;
- payment-data scope is approved for the integration mode.
- critical third-party responsibilities, due-diligence status, monitoring, incident, continuity, and exit ownership are complete.

# 8. Regulatory applicability and offer package

The control plane evaluates a frozen offer context against approved rules. It returns a requirement set, not a legal opinion.

Mandatory results:

```text
applicability_snapshot_id
applicable_requirement_ids
non_applicable_requirement_ids
unresolved_requirement_ids
required_disclosure_profile_ids
required_license_checks
required_reporting_profile_ids
required_data_segregation_profile_ids
required_manual_approval_roles
compliance_disposition
```

# 9. Evidence architecture

Evidence exists at three levels:

| Level | Examples |
|---|---|
| Technical | row counts, uniqueness, nulls, contract checks, hashes |
| Analytical | distributions, elasticity response, risk/loss coherence, stress transmission |
| Governance | profile approval, exception, compliance disposition, acceptance gate, residual issue |

Each accepted run has:

- run evidence summary;
- segment evidence;
- gate results;
- exceptions;
- known limitations;
- acceptance decision;
- reviewer and date.

# 10. Role separation

| Role | Owns | Cannot unilaterally override |
|---|---|---|
| Credit Policy | eligibility, amount, burden, collateral/covenant credit rules | Legal/compliance blocks, data-security scope |
| Pricing/Finance | revenue, costs, margin, elasticity assumptions | Capacity, risk appetite, compliance blocks |
| Portfolio Strategy | strategy mix, allocation, stress, line actions | Approved policy and regulatory hard controls |
| Legal | product interpretation, contract authority, legal source | Credit risk calibration |
| Compliance | requirement implementation, disclosures, reporting, conduct | Legal interpretation or credit risk decision |
| BSA/AML | financial-crime program roles and escalation | Credit policy |
| Data/Technology | data contracts, execution, access, lineage | Business approval of policy/requirements |
| Model Validation | independent testing and limitations | Business ownership of strategy |

# 11. Control-plane acceptance criteria

- all active profiles are versioned and effective-dated;
- no run resolves to more than one conflicting active hard-control profile;
- profile precedence is deterministic;
- all requirements have source, owner, status, dates, and implementation mapping;
- stale regulatory profiles fail closed;
- exact run configuration can be reconstructed;
- no credit rule overrides compliance disposition;
- evidence and acceptance are immutable and linked to archived output.
- critical third-party services have an approved accountable owner, oversight status, review date, and exit/continuity evidence.
