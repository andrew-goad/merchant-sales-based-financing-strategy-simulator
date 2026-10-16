# Documentation · MSBF Merchant Credit Intelligence

[Portfolio home](../README.md) · [Current Use Guide](guide/CURRENT_USE.md) · [Visual reading paths](guide/VISUALS.md)

**Find the explanation, then inspect the record.** This portal separates current reading companions from preserved stage packages, technical-successor evidence and historical release records. It is a map of the repository—not a universal execution order.

## Start with your question

**Evaluating the portfolio?** Begin with the [executive brief](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/pitch/From_First_Advance_to_Intelligent_Portfolio.pdf), [enterprise map](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/architecture/pdf/Enterprise_Merchant_Sales_Based_Financing_Platform_v2_1.pdf) and [cohort report](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/cohort/MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R3_PATCH1_20260908_REVIEW.pdf). Together they explain the proposition, system and results.

**Reviewing the logic?** Use the stage map below, then open the source README, requirements, implementation and validation. The new companions explain the hard boundaries without rewriting accepted records.

**Learning or using the files?** Open the [masterclass learning guide](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/teaching/companion/LEARNING_GUIDE.md), [exercise answers](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/teaching/companion/EXERCISE_ANSWER_KEY.md) or [Current Use Guide](guide/CURRENT_USE.md). Viewing evidence and executing a qualified replay have different prerequisites.

## Current reading hubs

[Module 0 · foundations](guide/MODULE_0.md) · [Module 1 · evidence](guide/MODULE_1.md) · [Module 2 · decisions and accounts](guide/MODULE_2.md)

[Explainability and P03 cases](guide/EXPLAINABILITY.md) · [Power BI, Tableau and cohort analysis](guide/ANALYTICS.md) · [Tableau scenario review](tableau/README.md) · [Visual portfolio](guide/VISUALS.md) · [Learn the mechanism](guide/LEARNING.md)

[Requirements and validation](guide/REQUIREMENTS_AND_VALIDATION.md) · [Source versions and provenance](guide/SOURCE_VERSIONS.md) · [Current use](guide/CURRENT_USE.md)

**The short mechanism routes are deliberate.** The [decision-engine poster](guide/LEARNING.md#how-the-governed-decision-engine-works) explains evidence → search → authority. The [after-decision poster](guide/LEARNING.md#what-happens-after-the-decision) explains monitoring → permissions → servicing → certification. Each has its own full-resolution reading path.

## Three ways to inspect the logic

| Business question | Current reading companion |
| --- | --- |
| What cash remains after existing commitments and the request? | [M1.10 · Obligations, liquidity and residual cash flow](guide/stages/M1_10.md) |
| Can another permissible structure work without weakening authority? | [M2.2 · Pricing, structure and counteroffer](guide/stages/M2_02.md) |
| Does a recommendation permit setup or actual servicing? | [M2.7 · Operational activation and account setup](guide/stages/M2_07.md) |

Start with cash capacity, structure search or operational setup to follow a business question into requirements, implementation and validation. All **31 current companions** retain original-source routes; these are documentation entries, not 31 executed stages or controls.

## Which version am I reading?

**Original packages.** `Module_0/`, `Module_1/` and `Module_2/` preserve their accepted editions; original Module 2 packages record v2.0.0. `src/current` is current **within its package**, not permission to mix versions.

**Successor evidence.** The [v2.1 change-control reports](release_change_control/module_2_g3_v2_1/README.md) explain the strategy correction and 130-path lifecycle. The [R26 integration projection](../successor_candidates/m2-g3-v2.1-r26-integration/README.md) identifies exact runtime/source roles; historical rc2 remains separate lineage.

**Acceptance and release status.** [Source versions and provenance](guide/SOURCE_VERSIONS.md#approval-acceptance-and-publication-are-separate) separates R26, Power BI, cohort and integrated acceptance. Older pending notices remain event-time records. [Read the current R20 overlay](release_integration/module_2_g3_v2_1/CURRENT_STATE.md) for the local candidate and remaining release gates.

## Stage map

The map covers **31 stage/charter entry points**: G0/G1, the M1.1 charter, M1.2–M1.17 and M2.1–M2.12. M1.1 is a charter, not another executed stage. Each entry keeps its original requirements, code, catalog and evidence navigation.

### Module 0 · Governance foundation

[G0 · Physical Data Foundation](guide/stages/G0.md) — schemas, parameters and physical evidence framework.  
[G1 · Governed Run Control](guide/stages/G1.md) — frozen run, profile and source identities.

### Module 1 · Evidence and contracts

[Detailed Module 1 lineage](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/architecture/pdf/Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage_v2_1.pdf) · [M1.10 worked companion](guide/stages/M1_10.md)

**Frame the work.** [M1.1 · Charter, Architecture & Requirements](guide/stages/M1_01.md) defines responsibilities and boundaries.

**Build the merchant and its observed context.**

[M1.2 · Deterministic Merchant Population](guide/stages/M1_02.md)  
[M1.3 · Application & Requested Sales-Linked Structure](guide/stages/M1_03.md)  
[M1.4 · Daily POS, Settlement & Merchant Ecosystem](guide/stages/M1_04.md)  
[M1.5 · Daily Deposit & Liquidity History](guide/stages/M1_05.md)  
[M1.6 · Matched POS & Deposit Scenario Overlays](guide/stages/M1_06.md)  

**Assess evidence and capacity.**

[M1.7 · Source Quality & Data Confidence](guide/stages/M1_07.md)  
[M1.8 · Verification, Fraud & Processor Continuity](guide/stages/M1_08.md)  
[M1.9 · As-of Cash-Flow Feature Engineering](guide/stages/M1_09.md)  
[M1.10 · Obligations, Liquidity & Residual Cash Flow](guide/stages/M1_10.md)  

**Translate resilience, risk and economics.**

[M1.11 · Cash-Flow Archetypes & Operating Resilience](guide/stages/M1_11.md)  
[M1.12 · Merchant Risk Components & Integrated Risk Proxy](guide/stages/M1_12.md)  
[M1.13 · Exposure, Recovery & Expected Loss Foundations](guide/stages/M1_13.md)  
[M1.14 · Unit Economics & Risk-Adjusted Contribution](guide/stages/M1_14.md)  

**Finish with three distinct responsibilities.**

[M1.15 · Latest, Archive, Comparison & Consumption Contract](guide/stages/M1_15.md) — the application evidence contract.  
[M1.16 · Acquisition Source, Marketing Attribution & Merchant Acquisition Cost Foundations](guide/stages/M1_16.md) — the acquisition-attribution companion, not final QA.  
[M1.17 · End-to-End QA, Evidence & G2 Contract Acceptance](guide/stages/M1_17.md) — end-to-end acceptance of the consumption boundary.

M1.2–M1.14 are the thirteen core stages; the three concluding contract/attribution/assurance responsibilities remain separate.

### Module 2 · Decisions and account lifecycle

[Detailed Module 2 lineage](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/architecture/pdf/Module_2_Governed_Decisioning_Operations_and_G3v2_Lineage_v2_1.pdf) · [M2.2 structure companion](guide/stages/M2_02.md) · [M2.7 setup companion](guide/stages/M2_07.md)

**Resolve the request.**

[M2.1 · Eligibility, Policy Gates & Decision Routing](guide/stages/M2_01.md)  
[M2.2 · Pricing, Structure & Counteroffer](guide/stages/M2_02.md)  
[M2.3 · Final Offer & Decision Authorization](guide/stages/M2_03.md)  

**Follow the funded path.**

[M2.4 · Booking, Funding & Portfolio Activation](guide/stages/M2_04.md)  
[M2.5 · Daily Remittance, Exposure & Portfolio Monitoring](guide/stages/M2_05.md)  
[M2.6 · Early Warning, Intervention & Servicing Strategy](guide/stages/M2_06.md)  
[M2.7 · Operational Activation & Account Setup](guide/stages/M2_07.md)  
[M2.8 · Servicing Execution, Payment & Lifecycle Control](guide/stages/M2_08.md)  
[M2.9 · Payment Reconciliation & Account State Certification](guide/stages/M2_09.md)  

**Explain and certify the portfolio.**

[M2.10 · Portfolio Performance, KPI & Servicing Analytics](guide/stages/M2_10.md)  
[M2.11 · Portfolio Optimization & Strategy Simulation](guide/stages/M2_11.md)  
[M2.12 · Enterprise Portfolio Certification & G3 Contract](guide/stages/M2_12.md)  

The original M2.11 folder title is preserved. The accepted R26 interpretation is **bounded terms/account-treatment comparison**, not autonomous high-level decision optimization. [Read the interpretation evidence](release_change_control/module_2_g3_v2_1/registers/09_STRATEGY_PROFILE_IMPLEMENTATION_INTERPRETATION.csv).

## Requirements, implementation and validation

For G0 and Module 1, start with each stage's **docs**, **src**, **tests** and catalogs from the map. For Module 2, the [original BRD and validation index](BRD_AND_VALIDATION_INDEX.md) provides direct BRD/source/acceptance links. That older index covers **Module 2 only**; it is not the complete foundation-and-evidence map above.

Use [M1.10](guide/stages/M1_10.md#requirements-and-validation), [M2.2](guide/stages/M2_02.md#requirements-and-validation) and [M2.7](guide/stages/M2_07.md#requirements-and-validation) to follow business requirement → implementation → actual evidence → limitation. Editorial locators are identified as such; they do not create official requirement IDs.

For cross-stage changes, consult the [detailed reconciliation report](release_change_control/module_2_g3_v2_1/reports/02_DETAILED_CHANGE_LOG_AND_DATA_RECONCILIATION_REPORT.md) and [technical evidence report](release_change_control/module_2_g3_v2_1/reports/03_TECHNICAL_VALIDATION_AND_EVIDENCE_REPORT.md). Their historical status statements do not override later R20 acceptance.

## Analytical and visual library

**Engineering:** [enterprise, Module 1 and Module 2 architecture](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/architecture/MSBF_Architecture_Trio_v2_1.pdf). Open the full-resolution/vector-text versions for dense stage detail.

**Executive:** [ten-page frozen pitch](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/pitch/From_First_Advance_to_Intelligent_Portfolio.pdf) and [page descriptions](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/accessibility/PITCH_PAGE_DESCRIPTIONS.md). The current pitch is an image-only PDF with exact PNGs, not a newly editable PowerPoint.

**Analytical:** [53-page cohort report](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/cohort/MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R3_PATCH1_20260908_REVIEW.pdf); begin at page 2 for the overview, page 14 for matched-scenario transitions, or pages 39–43 for cases. [Power BI requirements](power_bi/m2_v2_1/docs/POWER_BI_BUSINESS_REQUIREMENTS.md) and [implementation validation](power_bi/m2_v2_1/docs/POWER_BI_VALIDATION_REPORT.md) support P01–P04. The hidden diagnostic page is not a fifth executive experience.

**Tableau:** [Risk Decision & Scenario Review](tableau/README.md) connects matched-scenario decisions, portfolio-filtered indicators, segment concentration and source-backed merchant explanations. [Read the 13-page carousel](tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel.pdf) or [inspect workbook dependencies](tableau/docs/WORKBOOK_AND_EVIDENCE_NOTES.md). This analytical companion does not create a new project version or release.

**Teaching:** [23-page masterclass](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/teaching/MSBF_MCI_Merchant_POS_Lending_Masterclass_v2_1.pdf), [learning guide](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/teaching/companion/LEARNING_GUIDE.md) and [read-only code map](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/teaching/companion/READ_ONLY_CODE_MAP.md). There are 22 lessons plus a closing synthesis; a code map is not an execution recipe.

**Illustrated orientation:** [How the Governed Decision Engine Works](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/posters/MSBF_MCI_How_the_Governed_Decision_Engine_Works_v2_1_COPYFIX_R1.png) and [What Happens After the Decision](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/posters/MSBF_MCI_What_Happens_After_the_Decision_v2_1_COPYFIX_R1.png). Both links use the corrected frozen editions.

[Browse the full Markdown gallery](portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/GALLERY.md) for formats and audience routes. The retained HTML gallery is downloadable content, not proof of a deployed GitHub Pages site.

## Future work and release records

[Campaign Scale boundaries](campaign_scale/CAMPAIGN_SCALE_GOVERNANCE_BOUNDARY.md) retain separately gated progression toward 2,500 and 25,000. Module 3 portfolio intelligence is preparation/development, not an executed capability granted here. A generalized campaign runner remains future maturation work.

[Current use and prerequisites](guide/CURRENT_USE.md) · [Detailed qualification runbook](reproducibility/m2_v2_1/runbook/REPRODUCIBILITY_AND_EXECUTION.md) · [Current acceptance and release gates](release_integration/module_2_g3_v2_1/CURRENT_STATE.md) · [Frozen history and fidelity](project_history/chatgpt_logs_through_2026-09-09/README.md)

*All results are deterministic synthetic demonstration evidence. Current companions explain; preserved sources and actual accepting decisions govern.*
