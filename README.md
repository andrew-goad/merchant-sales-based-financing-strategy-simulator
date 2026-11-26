# When repayment follows sales

A small business needs to repair its equipment. It can take an advance today and repay it from a share of each day’s sales. How much financing can the business support, and what happens to repayment if sales weaken?

**Run your own campaign.** In the Windows GUI, choose a merchant population and run the reference policy. Then change one lending rule and rerun the saved population to see whose offer, funded amount or day-120 balance changes. [Run your own experiment in the GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/experiment.html) · [Read the interactive paper](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/)

## Research abstract

The Merchant Sales-Based Financing (MSBF) Strategy Simulator follows a request from sales and deposit evidence through underwriting, funding and daily repayment. Five synthetic studies evaluated the same applicants under Baseline and Recession Energy **within each study**. The engine could change the offer before funding. Once funded, the agreed share of eligible sales determined daily payments.

In the 25,000-merchant study, **176 of 3,337** funded businesses still owed money on day 120 in Baseline (5.27%). Under stress, **43 of 1,005** still owed money (4.28%). Among the **same 1,005 businesses funded in both scenarios**, the number still owing *rose* from **36 to 43** (3.58% to 4.28%). Of those matched businesses, 61 received different advance amounts. [Inspect the portfolio comparison](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#25000/outcomes)

**Scope.** These studies establish a working synthetic decision engine. An open account still has a balance on the observation date. Judging underwriting quality, actual losses and suitability for live lending requires observed merchant outcomes.

[Verify the figures against the campaign records](research-site/evidence/STUDY_SOURCES.md#recalculate-the-exhibits)

## Repayment on a $146,600 equipment-repair advance

In the **750 · Local GUI** study, merchant 000462 received a **$146,600** equipment-repair advance on identical terms in both scenarios. The agreement called for **$184,463.41** in total repayment from **9.7672% of eligible daily sales**. Both paths used the same sales history for 60 collection days. Day 61 was the first collection based on a date affected by the modeled shock.

![Outstanding contractual balance for merchant 000462. The curves coincide through day 60. Baseline reaches zero on day 111. Recession Energy ends day 120 with 3,743.44 dollars remaining.](research-site/figures/merchant_462_receivable.png)

The merchant paid off the advance on day 111 in Baseline. Under Recession Energy, **$3,743.44** remained on day 120. A reader can follow that difference all the way down to one day’s sales, the contractual percentage and the cap on the final payment. [Inspect the daily ledger](research-site/evidence/merchant_000462.csv) · [Trace day 111 into SQL](research-site/PROJECT_GUIDE.md#trace-one-requirement-to-one-payment)

## Compare five completed studies

Read each pair from **Baseline → Recession Energy**. Start with **Funded** to see how many businesses received an advance. **Supportable** includes both funded applications and referrals for underwriting review. **Open / funded** gives the count still owing at day 120 over the number funded in that scenario. Each row describes a separate population.

| Study | Supportable | Funded | Open / funded at day 120 | Daily monitoring records |
| --- | ---: | ---: | --- | ---: |
| [750 · Local DBeaver](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750a/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-DBeaver/RiskDecisionScenarioReview) | 300 → 80 | 103 → 27 | 4/103 → 0/27 | 15,600 |
| [750 · Local GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-GUI/RiskDecisionScenarioReview) | 321 → 94 | 115 → 35 | 5/115 → 1/35 | 18,000 |
| [750 · AWS GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750c/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-AWS-GUI/RiskDecisionScenarioReview) | 318 → 72 | 110 → 26 | 5/110 → 1/26 | 16,320 |
| [2,500 · AWS PowerShell](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#2500/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-2500-AWS-PowerShell/RiskDecisionScenarioReview) | 1,055 → 269 | 329 → 100 | 22/329 → 7/100 | 51,480 |
| [25,000 · AWS GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#25000/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-25000-AWS-GUI/RiskDecisionScenarioReview) | 10,564 → 2,836 | 3,337 → 1,005 | 176/3,337 → 43/1,005 | 521,040 |

The original DBeaver study reports certified ending balances after servicing. The other four report outstanding contractual receivables. Each study links to a narrated film and its own Tableau and Power BI reports. [Study sources and definitions](research-site/evidence/STUDY_SOURCES.md) · [Download the five workbook pairs](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/msbf-research-assets-2026-11)

## How the campaigns ran

The original 750 ran in DBeaver. Each stage checked its inputs, applied a financing rule and passed its result and acceptance checks to the next stage. PowerShell automated the two-module run for 2,500 merchants. For 25,000, the operator launched the early AWS console from PowerShell, then submitted and monitored the campaign in the browser. Today’s Windows console lets an analyst review and adjust parameters and resolve conflicting choices before submitting a run.

The **750 · Local GUI** campaign took about **2 h** of computation on a Windows desktop (8 GB RAM, Core i5-2500K at 3.30 GHz). The operator estimated **45 min** of computation for **750 · AWS GUI** on EC2 Windows (m7i-flex.4xlarge). The 2,500 study took **2 h 24 min** across two module runs (m7i.4xlarge reference configuration). The 25,000 study took **15 h 26 min** on AWS EC2 Windows (m7i-flex.4xlarge). [Timing records and measurement scope](research-site/evidence/execution_records.csv)

## Inspect the design

The Project Guide traces a business requirement from the analyst’s settings to a lending decision, a ledger entry and the SQL that produced it. The stage map indexes each module’s source and acceptance evidence. [Project Guide and current edition](research-site/PROJECT_GUIDE.md) · [Numbered stage map](docs/README.md#stage-map) · [Business requirements and validation](docs/BRD_AND_VALIDATION_INDEX.md)

Andrew R. Goad · [LinkedIn](https://www.linkedin.com/in/andrewrgoad) · [Tableau Public](https://public.tableau.com/app/profile/andrew.goad/vizzes) · [Cite the research or software](research-site/PROJECT_GUIDE.md#cite-this-work)
