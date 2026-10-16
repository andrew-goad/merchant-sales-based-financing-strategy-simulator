# Merchant Credit Intelligence | Tableau
## Risk Decision & Scenario Review

**Product:** MSBF Merchant Credit Intelligence<br>
**Purpose:** Matched-scenario risk review, segment sensitivity and explainable application decisions<br>
**Delivery:** One Tableau dashboard with its authoring workbook, 13-page carousel and individual page images

**[Read the Tableau carousel](docs/MCI_Risk_Decision_Scenario_Review_Carousel.pdf)** · [Workbook definition](release/MCI_Risk_Decision_Scenario_Review.twb) · [Viewing and evidence notes](docs/WORKBOOK_AND_EVIDENCE_NOTES.md)

**[Open the interactive Tableau Public dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MCI_Risk_Decision_Scenario_Review/RiskDecisionScenarioReview)**

[![Tableau portfolio overview: matched applications, scenario decisions, segment sensitivity and evidence-driven interpretation.](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/01_portfolio_overview.png)](docs/MCI_Risk_Decision_Scenario_Review_Carousel.pdf)

## Overview

Compare the same **750 synthetic merchant-financing applications** under Baseline and Recession Energy. Move from portfolio indicators to a selected decision pairing, identify its concentration by industry or acquisition source, and inspect the selected merchant's evidence and financing terms.

This is an additive Tableau analytical companion to the existing MSBF system. It does not replace the Power BI report, rerun the simulator, change financing policy, or introduce a new project version or release. The source engine owns the decisions; Tableau makes their results and supporting evidence explorable.

## Dashboard scope

| Section | What the reviewer can do |
| --- | --- |
| 01 · Portfolio interpretation | Read a filter-responsive explanation beside four reconciled indicators. |
| 02 · Decision matrix | Compare final decision categories for matched applications; select a pairing to investigate. |
| 03 · Segment sensitivity | Switch between portfolio authorization rates and selected-pairing incidence; group by industry or acquisition source. |
| 04 · Application investigation | Identify the applications behind a selected pairing and inspect requested amounts. |
| 05 · Merchant evidence and decision interpretation | Switch the two scenario panels between Decision, Evidence, Structure and Source rationale. |

### Starting controls

| Unfiltered comparison | Value |
| --- | ---: |
| Matched applications | 750 |
| Different final decision categories | 236 / 31.5% |
| Same final decision category | 514 / 68.5% |
| Baseline authorizations | 103 / 13.7% |
| Recession Energy authorizations | 27 / 3.6% |

The denominator is the matched application population, not 1,500 separate application-scenario rows. A change between two authorized categories still counts as a category difference; changing proposed terms within the same category does not.

## Interaction design

**Portfolio filters** define the Industry/Acquisition Source population for the indicators, executive interpretation and both segment modes. **Matrix selections** narrow the application investigation and pass decision codes to the selected-pairing calculations. **Merchant selections** change the individual explanations without changing portfolio totals.

Selected-pairing incidence uses the full portfolio-filtered population of each segment as its denominator. For example, Counteroffer review required / Evidence decline includes **10 of 82 Healthcare Services applications: 12.2%**, not 100% of a prefiltered pairing.

The workbook demonstrates aggregate calculations, parameter-driven grouping and narrative selection, dashboard filter actions, parameter actions, dynamic zone visibility, sorted comparative charts and tiled layout. [See the workbook checks and limits](docs/WORKBOOK_AND_EVIDENCE_NOTES.md).

## What the cases reveal

Merchant **003** distinguishes insufficient evidence from adverse operating performance. Merchant **040** retains a potentially supportable structure but requires underwriting review. Merchant **098** retains authorization through a smaller counteroffer. Merchant **258** keeps a review category while its proposed amount changes. **117 matched hard-stop cases** remain distinct from no-feasible-structure and review outcomes.

## Folder map

| Path | Purpose |
| --- | --- |
| `release/MCI_Risk_Decision_Scenario_Review.twb` | Original authored Tableau definition; local data references retained. |
| `docs/MCI_Risk_Decision_Scenario_Review_Carousel.pdf` | Approved 13-page evidence-first carousel. |
| `docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/` | Matching full-page PNGs, in PDF order. |
| [Viewing and evidence notes](docs/WORKBOOK_AND_EVIDENCE_NOTES.md) | Workbook dependencies, interaction boundaries and verification scope. |
| [Asset manifest](manifests/ASSET_MANIFEST.json) | Exact hashes, byte sizes, page subjects and filename mapping. |

The `release/` directory retains the owner's folder convention. It is not a GitHub Release, a new version, or a supersession of accepted project artifacts.

## Open individual carousel pages

| Page | Evidence view |
| ---: | --- |
| 01 | [Executive portfolio overview](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/01_portfolio_overview.png) |
| 02 | [Bank Relationship: filtered portfolio](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/02_bank_relationship_portfolio.png) |
| 03 | [Energy Services: filtered portfolio](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/03_energy_services_portfolio.png) |
| 04 | [Authorization rates by acquisition source](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/04_acquisition_source_comparison.png) |
| 05 | [Merchant 003: evidence sufficiency](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/05_merchant003_evidence_sufficiency.png) |
| 06 | [Merchant 040: processor continuity and review](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/06_merchant040_underwriting_review.png) |
| 07 | [Merchant 098: authorized counteroffer](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/07_merchant098_authorized_counteroffer.png) |
| 08 | [Merchant 258: proposed exposure sensitivity](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/08_merchant258_proposed_exposure_sensitivity.png) |
| 09 | [Merchant 288: structure feasibility](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/09_merchant288_structure_feasibility.png) |
| 10 | [Merchant 340: governed structure constraint](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/10_merchant340_governed_structure_constraint.png) |
| 11 | [Merchant 134: underwriting judgment](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/11_merchant134_underwriting_judgment.png) |
| 12 | [Policy hard-stop governance](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/12_policy_hard_stop_governance.png) |
| 13 | [Merchant 016: authorization stability](docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/13_merchant016_authorization_stability.png) |

## Viewing and validation position

The PDF and PNGs can be read without Tableau or a database. The `.twb` preserves the author's worksheet definitions and calculations, but **is not self-contained**: it references a local CSV and temporary Hyper extract that are not included in this folder. Use the [viewing notes](docs/WORKBOOK_AND_EVIDENCE_NOTES.md) before attempting local authoring. No packaged `.twbx` or fresh native opening test is claimed here.

The preparation checks establish asset identity, page mapping, workbook XML structure and repository documentation integrity. They are not a new simulator audit or a transfer of Power BI's accepted validation controls to Tableau.

## Interpretation boundaries

All records and results are deterministic synthetic demonstration evidence. Baseline and Recession Energy are alternative scenarios, not sequential account histories or forecasts. Review is not authorization; authorization does not establish funding. Selected terms are not actual exposure, missing evidence is not zero, and same-category outcomes can have different terms and reasons. Technical source rationale may describe an earlier independent assessment rather than the final governed outcome.

[Portfolio home](../../README.md) · [Documentation portal](../README.md) · [Power BI companion](../power_bi/m2_v2_1/README.md) · [Analytical reading guide](../guide/ANALYTICS.md)
