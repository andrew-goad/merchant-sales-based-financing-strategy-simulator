# Requirements-to-Architecture Traceability
## Merchant Sales-Based Financing Strategy Simulator v0.1R1

This is the initial P0 traceability skeleton. The detailed BRDs will expand it to field, calculation, SQL object, test query, evidence output, and report measure.

| Requirement | Architecture owner | Primary logical tables | Contract/output | P0 validation evidence |
|---|---|---|---|---|
| PRD-001 legal-neutral structure | Control plane/M2 | product legal structure, operating model, offer decision | Profile snapshot, M2 decision | Structure code/status present; no legal-ready claim when unspecified |
| PRD-002 daily sales-linked remittance | M1/M3 | POS daily, advance, daily remittance | M1 snapshot, M3 account-day | Daily expected remittance reconciles |
| PRD-003 fixed fee/total repayment | M2 | offer candidate, candidate economics, advance | M2 decision/booking | Total repayment = funded + fee; payback multiple reconciles |
| PRD-004 expected horizon vs maturity | M1/M2/M3 | application, candidate, advance, performance | M1/M2/M3 contracts | Separate fields and tests; no conflation |
| DAT-001 determinism | Control/M1 | parameter snapshot, merchant, POS base | M1 contract | Repeated hashes identical |
| DAT-003 no future data | M1–M4 | source/feature/performance snapshots | All contracts | Max observation date ≤ as-of/review date |
| DAT-004 gross-to-eligible sales | M1 | POS daily, feature snapshot | M1 contract | Reconciliation identity passes |
| RSK-004 separate risk dimensions | M1 | verification, risk snapshot | M1 contract | Credit/fraud/data/continuity distinct and non-null |
| RSK-006 declining EAD | M1/M2 | EAD path, balance schedule | M1/M2 | Monotonic declining exposure subject to modeled rules |
| RSK-007 collateral-sensitive LGD | M1/M2 | collateral valuation, candidate economics | M2 decision | Haircut/control/cost/timing components reconcile |
| OFF-001 bounded candidates | M2 | offer candidate | M2 decision | Candidate count/ranges pass |
| OFF-003 price elasticity | M2 | elasticity result | M2 frontier | Acceptance responds directionally to price gap |
| OFF-004 adverse selection | M2 | elasticity result, candidate risk | M2 frontier | Booked mix worsens under configured high-price scenario |
| OFF-005 contribution identity | M2 | candidate economics | M2 decision | Revenue − costs − EL − risk charge reconciles |
| OFF-008 covenants | M2/M3 | covenant definition, advance covenant, test result | M2 booking/M3 health | Every covenant has test, threshold, cure, action, owner |
| OFF-011 allocation | M2 | portfolio allocation, risk limits | M2 final | Budget and concentration limits not exceeded |
| PER-004 low sales vs missing remittance | M3 | performance, processor event | M3 account-day | Dedicated test cases produce different states |
| PER-007 line action | M3 | health, line candidate/action | M3 health action | One action per facility/review; limits checked |
| PER-008 loss mitigation | M3 | treatment candidate | M3 mitigation | Cure/recovery/cost/time/value compared |
| STR-003 industry dependencies | M4 | industry dependency, scenario shock | M4 stress | Direct/indirect effects and caps reconcile |
| STR-007 robustness | M4 | frontier, robustness | M4 robustness | Cross-scenario metrics reproduce |
| GOV-003 latest/archive | All | module latest/archive | Accepted archives | Latest resolves to one accepted archive run |
| GOV-004 matched comparison | All | comparison registry, archives | Comparison evidence | Stable business keys and complete coverage |
| REG-003 regulatory registry | Control | regulatory requirement/applicability | Profile snapshot | Source/owner/status/dates complete |
| REG-006 credit/compliance separation | M2 | offer decision, compliance package | M2 decision | Block cannot be booked |
| REG-007 offer compliance package | M2 | applicability snapshot, package | Compliance contract | Exact final offer values and versions reconcile |
| REG-010 small-business data-reporting profile | Control/Data | reporting/data-segregation and transaction-classification profiles | Profile snapshot | Current approved rule version and effective date applied; qualifying-MCA exclusion is evidence-based; no other permanent product-coverage assumption |
| REG-011 data separation | Data/Compliance | data segregation, access evidence | Reporting contract | Restricted data absent from credit contract |
| REG-013 no cardholder data | Data/Security | source/data scope profiles | Source contract | Data classification scan passes |
| REG-017 fail closed | Control/M2 | profile, applicability, decision | M2 decision | Stale/unapproved profile routes to review/block |
| REG-013 third-party oversight | Control/M1–M3 | third-party relationship and operating-model profiles | Profile snapshot / control evidence | Critical roles, due diligence, monitoring, incident, continuity, remediation, and exit ownership complete |

## M1.16 TRACEABILITY ADDENDUM

The acquisition enhancement traces to channel-cost heterogeneity, nonconverter funnel burden, cost timing, attribution confidence, M1.14 overlap/double counting, companion-contract publication, and final M1.17/G2 assurance.
