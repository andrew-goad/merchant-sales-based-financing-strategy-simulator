# MSBF Merchant Credit Intelligence
## Power BI Business Requirements Document

**Document ID:** MSBF-MCI-PBI-BRD-R1  
**Product:** MSBF Merchant Credit Intelligence  
**Subtitle:** Decisioning, Portfolio & Servicing Intelligence  
**Release candidate:** Module 2 v2.1.0-rc2  
**Document date:** 2026-09-04  
**Status:** Corrected final publication candidate; R16 localized P04 filter defect remediated; expedited focused re-audit pending; GitHub publication remains separately controlled  
**Requirements baseline:** 142 requirements; 142 VERIFIED in the companion register

---

## 1. Executive summary

MSBF Merchant Credit Intelligence is a governed Power BI analytical product that translates the accepted Module 2 merchant-financing decision, lifecycle, monitoring, intervention, servicing, and certification architecture into a client-ready executive-to-account reporting experience.

The current release candidate covers an initial fixed cohort of 750 deterministic synthetic merchants evaluated under two alternative governed scenarios: **Baseline** and **Recession Energy**. The report provides:

- executive cohort and decision intelligence;
- funded-account lifecycle and payment-performance analysis;
- application-level decision traceability and plain-language narratives;
- endpoint servicing, intervention, payment, and certification analysis;
- visible governance and interpretation boundaries;
- source-to-report traceability, automated QA, interaction evidence, and accessibility controls.

The release candidate consists of four visible pages plus one hidden diagnostic page. It is designed for portfolio demonstration, analytical validation, professional presentation, and GitHub publication support. It is not a production underwriting, pricing, payment, or servicing platform.

## 2. Business context

The underlying MSBF program simulates a merchant-financing portfolio from application and evidence through decisioning, candidate structure search, funding, account lifecycle, monitoring, intervention, operational setup, servicing execution, certification, and portfolio analysis.

The Power BI product is needed to convert that governed technical architecture into an accessible business-consumption layer that can answer five questions:

1. **What happened across the cohort?**
2. **How did funded accounts perform through the governed lifecycle?**
3. **Why did a selected application receive its outcome and proposed structure?**
4. **Which funded accounts require endpoint attention, and what servicing state followed?**
5. **Can every displayed result be traced to accepted successor sources and validation evidence?**

Without this layer, technically accepted outputs remain difficult to interpret, compare, and present. The product must therefore balance executive clarity with exact semantic authority.

## 3. Business objectives

The Power BI build shall:

1. provide a professional, marketable portfolio intelligence product suitable for a client, hiring manager, auditor, or technical reviewer;
2. preserve accepted R26 source authority without recreating business logic in DAX;
3. provide a coherent path from portfolio summary to account-level evidence;
4. distinguish observed source evidence from deterministic synthetic-forward lifecycle evidence;
5. make scenario sensitivity visible without presenting scenarios as forecasts;
6. explain the full seven-outcome decision architecture;
7. expose funded-account monitoring and servicing results only where physical funding occurred;
8. preserve exact source-to-report traceability and validation;
9. support GitHub publication through controlled documentation, manifests, checksums, and public-candidate visuals;
10. remain maintainable as later pages and modules are completed.

## 4. Success criteria

The release candidate is successful when:

- P01-P04 are page-frozen and visually coherent;
- P02-DIAG is retained as a hidden diagnostic;
- the client-facing PBIX contains no predecessor-fact references in physical P01-P04/P02-DIAG visual JSON, including query bindings, `filterConfig`, and active filter predicates;
- page bindings are 100% successor-or-shared;
- P03 narrative QA passes across all 1,500 paths;
- P03 monitoring QA passes across all 130 funded paths and 15,600 monitoring rows;
- P04 M2.6-M2.10 population and representative-path QA pass;
- scenario isolation is demonstrated;
- visible labels and narratives are business-readable;
- tooltips add interpretive value without unexplained metrics;
- substantive visuals include appropriate alt text and tab order;
- physical package integrity passes;
- final persistence/nonregression closure and the separate publication action are explicitly tracked.

## 5. Scope

### 5.1 In scope

- One client-facing Power BI Desktop file:
  `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix`
- Four visible pages:
  - P01 - Cohort Command Center
  - P02 - Cohort Lifecycle
  - P03 - Application Journey
  - P04 - Servicing & Exceptions
- One hidden diagnostic page:
  - P02-DIAG - Attention States
- Baseline and Recession Energy governed scenarios
- Fixed initial 750-merchant cohort
- Decision, structure, funding, monitoring, servicing, and certification evidence through Module 2
- Power Query ingestion already embodied in the current PBIX
- R1 successor semantic facts and current shared dimensions
- Centralized DAX measures and page-specific presentation adapters
- Tooltips, interactions, alt text, tab order, footers, and interpretation boundaries
- QA and publication-support documentation

### 5.2 Out of scope for this release candidate

- P05 Economics & Value Creation
- P06 Strategy & Decision Effectiveness
- Module 3 enterprise intelligence
- Campaign-scale runtime execution
- Power BI Service deployment, tenant administration, or deployment pipelines
- Live production data
- Real customer or merchant decisions
- Real payment processing or merchant contact
- Production servicing or adverse action
- CECL, accounting reserve, or audited profitability reporting
- Causal or treatment-effect claims
- GitHub publication execution itself

## 6. Stakeholders and audiences

| Audience | Primary needs |
| --- | --- |
| Executive / portfolio leader | Cohort size, funding, risk, economics, decision distribution, endpoint posture |
| Credit strategy leader | Outcome mix, supportable paths, structure selection, scenario sensitivity |
| Risk and governance reviewer | Source authority, evidence gates, scenario isolation, limitations |
| Servicing / operations leader | Attention population, exposure, queue, intervention, execution, certification |
| Analyst / validator | Exact keys, source populations, tooltips, diagnostic page, QA results |
| GitHub / portfolio reviewer | Professional product story, readable documentation, screenshots, PBIX, reproducibility |
| Future maintainer | Canonical source map, requirements, traceability, prohibited bindings, release gates |

## 7. Governing principles

### 7.1 Authority

The accepted R26 M2.5-M2.12 / G3-v2 technical successor baseline is controlling. Power BI integration is version-separated and authorized. Public release remains a separate controlled action.

### 7.2 Synthetic evidence

All merchant, application, funding, lifecycle, monitoring, intervention, servicing, and certification data are deterministic synthetic evidence. They must not be represented as actual customer behavior or production execution.

### 7.3 Scenario interpretation

Baseline and Recession Energy are alternative governed scenarios applied to the same fixed application population. They are not sequential states, forecasts, macroeconomic projections, or realized outcomes.

### 7.4 Source-owned logic

Power BI may consume, aggregate, filter, label, narrate, and visualize accepted outputs. It may not recreate:

- candidate feasibility;
- strategy selection;
- no-feasible proof;
- stress-floor governance;
- final decision authority;
- servicing or payment methodology;
- certification logic;
- treatment effects.

### 7.5 Exact identity

`ApplicationScenarioKey` is the exact identity across decision, funding, monitoring, servicing, and certification facts. Merchant-only joins are insufficient for cross-scenario analysis.

## 8. Product architecture

### 8.1 Report composition

| Order | Page | Visibility | Purpose | Visual count |
| --- | --- | --- | --- | --- |
| 1 | P01 - Cohort Command Center | Visible | Executive portfolio, decision, risk, economics, endpoint, and governance summary | 24 |
| 2 | P02 - Cohort Lifecycle | Visible | Funded-cohort runoff, remittance, monitoring, and payoff analysis | 21 |
| 3 | P02-DIAG - Attention States | Hidden | Internal alert/adverse-state diagnostic | 9 |
| 4 | P03 - Application Journey | Visible | Selected application-scenario decision rationale and funded-account journey | 25 |
| 5 | P04 - Servicing & Exceptions | Visible | Endpoint attention, intervention, servicing, payment, and certification view | 17 |

### 8.2 Analytical narrative

The page sequence shall tell this story:

> Cohort and decisions -> funded lifecycle -> selected application rationale -> endpoint servicing and certification.

The user should be able to begin with the portfolio, identify material outcomes or segments, inspect how funded accounts performed, understand one application's governed decision, and finally review operational attention and certification.

## 9. Data requirements

### 9.1 Core source populations

| Source object | Required population | Business purpose |
| --- | --- | --- |
| R1DimApplicationScenario | 1,500 | Application-scenario profile, request, evidence, and governed outcome context |
| R1FactFinalDecision | 1,500 | Final outcome and selected/proposed structure |
| R1FactFundedLifecycle | 130 | Physical funding identity and date |
| R1FactDailyMonitoring | 15,600 = 130 x 120 | Daily receivable, remittance, status, alert, and shortfall evidence |
| R1FactIntervention | 130 | M2.6 recommended servicing strategy |
| R1FactOperationalSetup | 130 | M2.7 operational setup and governance state |
| R1FactServicingExecution | 130 | M2.8 synthetic payment and servicing execution |
| R1FactAccountCertification | 130 | M2.9 reconciliation and account-state certification |
| R1FactPortfolioPerformance | 130 | M2.10 endpoint performance and servicing queue |
| R1FactCandidateEvaluation | 52,152 | Accepted M2.11 candidate-profile evaluation population |
| R1FactApplicationStrategySimulation | 12,000 | Accepted application-profile simulation population |
| R1FactAccountStrategySimulation | 1,040 | Accepted funded-account profile simulation population |
| R1FactPortfolioStrategyAnalysis | 24 | Accepted scope-profile analysis population |
| R1FactG3v2Certification | 70 | G3-v2 certification controls |

### 9.2 Data-quality requirements

- Each source must retain its defined grain and key contract.
- R1 monitoring shall contain exactly 120 rows per funded application-scenario path.
- M2.6-M2.10 shall preserve exact 130-key set equality.
- Physical funding shall exist only for authorized funded paths.
- Nonfunded paths shall not inherit monitoring or servicing evidence.
- Source SHA-256 values shall be recorded in the canonical register.
- The model shall fail closed where required evidence is unavailable or out of bounds.

## 10. Semantic-model requirements

The semantic layer shall:

- use R1 successor facts for substantive calculations;
- use current shared dimensions for categories and labels where appropriate;
- contain no predecessor-fact reference anywhere in P01-P04 or P02-DIAG physical visual JSON, including `filterConfig`;
- centralize canonical measures;
- reuse prior canonical measures through aliases rather than reimplement calculations;
- keep page adapters within the presentation layer;
- preserve source codes alongside friendly display labels;
- use future-safe label fallbacks for new categorical codes;
- maintain scenario filter propagation;
- qualify reconstructed model inventory until the final DMV inventory is rerun.

---

Current binding coverage is:

| Page | Bindings | R1 successor | Shared dimension/metadata | Predecessor facts | Coverage |
| --- | --- | --- | --- | --- | --- |
| P01 - Cohort Command Center | 49 | 39 | 10 | 0 | 100% |
| P02 - Cohort Lifecycle | 49 | 39 | 10 | 0 | 100% |
| P02-DIAG - Attention States | 33 | 26 | 7 | 0 | 100% |
| P03 - Application Journey | 55 | 42 | 13 | 0 | 100% |
| P04 - Servicing & Exceptions | 35 | 29 | 6 | 0 | 100% |

## 11. Functional requirements by page

### 11.1 P01 - Cohort Command Center

**Business question:** What does the current cohort look like, how was it decisioned and funded, and what is its current endpoint posture?

Required controls:

- Scenario
- Industry
- Acquisition source
- Observation date

Required KPIs:

- Funded accounts
- Funded amount
- Current exposure
- Remittance fulfillment
- Supportable path rate
- Comparative expected-loss rate

Required analyses:

- Funding by acquisition source
- Seven governed decision outcomes
- Industry risk and economics
- Endpoint status
- Active alerts as of the observation date
- Evidence and governance status

The page must distinguish operational-alert breadth from adverse monitoring. It must preserve fixed decision/funding populations while allowing account performance to vary by observation date.

![P01 Baseline](../assets/power_bi/core/p01_command_center_baseline.png)

### 11.2 P02 - Cohort Lifecycle

**Business question:** How did the selected funded cohort perform through the governed synthetic lifecycle?

Required controls:

- Scenario
- Industry
- Acquisition source
- Observation period

Required KPIs:

- Funded accounts
- Funded amount
- Average funded amount
- Authorized-offer rate
- Comparative expected-loss rate
- Risk-adjusted contribution

Required analyses:

- Receivable runoff
- Remittance fulfillment
- Monitoring breadth and severity
- Payoff timing versus plan

The page must:

- use current R1 monitoring;
- retain valid scenario comparison behavior;
- distinguish operational alerts from adverse status;
- stop at the governed evidence endpoint;
- provide diagnostic tooltips for alert conditions and families;
- preserve a hidden diagnostic page for attention-state analysis.

![P02 Baseline](../assets/power_bi/core/p02_cohort_lifecycle_baseline.png)

### 11.3 P03 - Application Journey

**Business question:** Why did this application receive its governed outcome and proposed structure, and what happened after funding?

Required selectors:

- Merchant
- Scenario

Required merchant context:

- Industry
- Size tier
- Annual sales band
- Relationship stage
- Relationship quality
- Prior advances
- Prior funded amount

Required request context:

- Applied date
- Requested amount
- Use of proceeds
- Channel
- Requested remittance
- Payback multiple
- Payoff days
- Total repayment

Required decision content:

- Decision class
- Decision label
- Proposed structure
- Physical funding date
- Merchant operating evidence narrative
- Risk & economics assessment narrative
- Decision narrative

Required funded-path content:

- Account performance: remaining receivable and remittance pace
- Performance tooltips: monitoring status, remitted, expected, shortfall
- Monitoring journey and status transitions
- Monitoring tooltips: alert family, shortfall alert, pace, shortfall, days since remittance, alert counts
- Servicing & intervention: intervention, queue, priority, exposure, reason

The narrative layer must cover all seven governed outcomes and material reason branches, remain scenario-isolated, and pass the complete 1,500-path QA.

![P03 738 Baseline](../assets/power_bi/core/p03_application_journey_738_baseline.png)

### 11.4 P04 - Servicing & Exceptions

**Business question:** Which funded accounts require endpoint attention, what operational path was assigned, and did the downstream account state reconcile and certify?

Required control:

- Scenario only

Required KPIs:

- Requiring attention
- Attention exposure
- Active servicing
- Review holds
- Certified exposure
- Unresolved exceptions

Required analyses:

- Endpoint monitoring posture
- Servicing disposition
- Account attention workbench
- Payment & certification detail

The workbench shall trace:

> monitoring status -> recommended intervention -> operational setup -> servicing execution -> endpoint state.

The lower detail shall show:

- execution state;
- payment-event count;
- processed amount;
- return/retry behavior;
- reconciliation result;
- certification date;
- certified exposure.

The visible page shall not display servicing burden units because the report does not otherwise establish an interpretable scale or benchmark. The measure may remain available for technical QA.

![P04 Baseline](../assets/power_bi/core/p04_servicing_exceptions_baseline.png)

## 12. Interaction requirements

- Scenario shall filter every intended visual on each page.
- Industry and acquisition source shall filter intended P01/P02 visuals.
- Observation date/period shall affect only valid date-sensitive measures.
- P03 Merchant and Scenario shall resolve one exact application-scenario path.
- P04 workbench selection shall filter Payment & certification detail.
- P04 workbench selection shall not change portfolio-level KPI or posture charts.
- Hidden diagnostics shall not enter public navigation.

## 13. Narrative and terminology requirements

The product shall use terminology appropriate for a client-facing merchant-financing portfolio:

- **Proposed structure**, not selected structure, where authorization is not guaranteed.
- **Reassessment** and **Review hold** as concise chart labels, with full queue wording in tooltips.
- **Dormant** for compact P04 endpoint labels and **Dormant / no remittance** where P03 journey context benefits from the full meaning.
- **Counteroffer review**, **Underwriting review**, **Evidence decline**, **No feasible structure**, and **Policy hard stop** as distinct outcomes.

Narratives must explain evidence and economics without overstating certainty or inventing facts.

## 14. Accessibility requirements

- Substantive title, KPI, chart, and table visuals shall receive meaningful alt text.
- Dynamic KPI alt text may state current values and grammar.
- Separate narrative tables shall have distinct purpose-oriented alt text.
- Slicers and visible footer text shall use native readable labels without redundant custom alt text.
- Tab order shall follow the page's analytical reading sequence.
- Tooltips shall not be the only place where essential meaning is conveyed.
- Short axis labels may be backed by full tooltip descriptions.

## 15. Nonfunctional requirements

### 15.1 Integrity

- PBIX CRC shall pass.
- Package paths shall be safe and noncolliding.
- Source and publication artifacts shall carry SHA-256 checksums.
- Publication ZIPs shall extract cleanly with ordinary Windows-native tooling.

### 15.2 Maintainability

- Canonical and page-specific measures shall be documented.
- Requirements and validation shall be traceable.
- Friendly-label logic shall preserve underlying codes.
- Future additions shall update the source-of-truth register and change log.
- P05/P06 shall not be activated without separate completion and validation.

### 15.3 Performance and usability

The report shall remain usable in Power BI Desktop with native visuals and bounded page complexity. The current build was developed on an older desktop where interaction latency was observed; publication does not assert enterprise-scale Power BI Service performance.

### 15.4 Privacy and security

The public package shall contain deterministic synthetic data and public-candidate presentation assets only. Private owner evidence, raw Desktop QA captures, and internal development packages shall remain outside the public package unless separately authorized.

## 16. Validation and acceptance requirements

Acceptance requires:

- physical package validation;
- report page and binding inventory;
- G3-v2 certification;
- source-population reconciliation;
- P03 narrative and monitoring QA;
- P04 M2.6-M2.10 QA;
- interaction and scenario testing;
- accessibility evidence;
- temporal and interpretation-boundary review;
- final refresh/save/close/reopen persistence and nonregression;
- separate GitHub release authorization.

The current validation state is:

| Status | Controls |
| --- | --- |
| PASS | 46 |
| DEFERRED | 0 |
| PENDING | 1 |

The current pages remain accepted and frozen at the page-production level. Following IA-D-R16-PBI-001, a bounded P04 metadata correction removed two stale predecessor filters without changing the DataModel, visual query/layout payload, or observed results. The owner explicitly approved reuse of the existing P04 captures without re-capture. The next action is expedited focused re-audit; GitHub publication/public supersession remains separately controlled after audit ACCEPT.

## 17. Requirements baseline

The companion register contains **142 requirements**.

| Category | Total | Verified | Deferred | Pending | Planned |
| --- | ---: | ---: | ---: | ---: | ---: |
| Accessibility | 6 | 6 | 0 | 0 | 0 |
| Data Sources | 17 | 17 | 0 | 0 | 0 |
| Governance | 12 | 12 | 0 | 0 | 0 |
| Nonfunctional | 5 | 5 | 0 | 0 | 0 |
| P01 Command Center | 12 | 12 | 0 | 0 | 0 |
| P02 Cohort Lifecycle | 12 | 12 | 0 | 0 | 0 |
| P03 Application Journey | 18 | 18 | 0 | 0 | 0 |
| P04 Servicing & Exceptions | 18 | 18 | 0 | 0 | 0 |
| Product | 10 | 10 | 0 | 0 | 0 |
| Release | 6 | 6 | 0 | 0 | 0 |
| Semantic Model | 16 | 16 | 0 | 0 | 0 |
| User Experience | 4 | 4 | 0 | 0 | 0 |
| Validation | 6 | 6 | 0 | 0 | 0 |

The complete requirement text, rationale, authority, verification method, current status, and evidence mapping are available in:

- `registers/MSBF_MCI_POWER_BI_BUSINESS_REQUIREMENTS_REGISTER_R3_20260904.csv`
- `registers/MSBF_MCI_POWER_BI_REQUIREMENTS_TRACEABILITY_MATRIX_R3_20260904.csv`
- `registers/MSBF_MCI_POWER_BI_CANONICAL_SOURCE_OF_TRUTH_R7_20260904.xlsx`

## 18. Release and change management

Final persistence/nonregression remains owner-confirmed for the current report output state. The post-audit correction is documented by exact physical PBIX diff, complete visual/filter scan, and owner no-output-change/no-recapture signoff. Before GitHub publication:

1. use the final persisted PBIX and publication-support package without further report edits;
2. verify the package manifest and SHA-256 identities;
3. obtain the required independent-audit acceptance of the final publication-candidate package;
4. execute the separately authorized GitHub release/public-supersession action;
5. download every hosted asset and verify exact hash and byte size against the final release register;
6. validate Windows-native clean extraction of hosted archives;
7. record the publication and hosted-asset verification receipt.

Any later change shall identify affected requirements and controls, update the canonical register, rerun bounded QA, and preserve the synthetic and authority boundaries.

## Appendix A - Requirement-status definitions

| Status | Meaning |
| --- | --- |
| VERIFIED | Implemented and supported by automated validation, physical inspection, binding review, or approved owner evidence |
| DEFERRED | Required but intentionally scheduled for the portfolio-wide final gate |
| PENDING | Awaiting a separate authorized action |
| PLANNED | Future requirement not yet implemented; no current requirements remain in this state |

## Appendix B - Current release artifacts

| Artifact | Role |
| --- | --- |
| `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix` | Primary client-facing Power BI release candidate |
| `CANONICAL_SOURCE_OF_TRUTH.md` | Human-readable current state |
| `MSBF_MCI_POWER_BI_CANONICAL_SOURCE_OF_TRUTH_R7_20260904.xlsx` | Detailed machine/audit-friendly source-of-truth workbook |
| `POWER_BI_BUSINESS_REQUIREMENTS.md` | GitHub-facing BRD |
| `POWER_BI_VALIDATION_REPORT.md` | GitHub-facing validation report |
| Requirements and validation CSVs | Traceability and machine-readable control registers |
| `assets/power_bi/core/` | Curated public-candidate visual evidence |
