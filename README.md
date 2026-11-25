# When repayment follows sales

**How much working capital can a small business borrow against future sales, and what happens if those sales weaken?**

Andrew Goad’s Merchant Sales-Based Financing (MSBF) Strategy Simulator follows a financing request from sales and bank deposits through underwriting, counteroffers, funding and repayment. It evaluates the same synthetic applicants under Baseline and Recession Energy. The lender can change its offer under stress. Once it funds an advance, the business pays a fixed share of eligible daily sales. A slow day means a smaller payment. A day without eligible sales means no collection.

**What this work establishes**

MSBF is a working decision engine tested on synthetic merchants. These studies show who received financing and how repayment unfolded under the modeled conditions. How well the strategy would serve real businesses, and what would improve it, remain open questions for future versions. Use this edition for policy research. Validate the strategy against observed merchant outcomes before using it for live lending.

**[Explore the interactive studies](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/)** · [Read the project guide](research-site/PROJECT_GUIDE.md) · [Design an experiment in the GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/experiment)

## One equipment repair, two repayment paths

In the **750 · Local GUI** study, merchant 000462 received **$146,600** for equipment repair in both scenarios. The agreement called for **$184,463.41** in total repayment from **9.7672%** of eligible daily sales. The first 60 collection days replayed the same sales. When the stress-affected dates entered the calculation on day 61, the balances began to diverge.

![Outstanding contractual balance for merchant 000462. The curves coincide through day 60. Baseline reaches zero on day 111. Recession Energy ends day 120 with 3,743.44 dollars remaining.](research-site/figures/merchant_462_receivable.png)

Baseline paid off on day 111. Under Recession Energy, **$3,743.44** remained at day 120. Of the 35 merchants funded in both scenarios, this merchant was the only one still owing money under stress. [Watch Merchant Sales-Based Financing and try the daily repayment calculator](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/mechanics) · [Inspect the daily ledger](research-site/evidence/merchant_000462.csv)

## Compare five completed studies

The tool began in DBeaver. Each SQL stage started with a business requirement, checked its inputs, applied the rule and tested the result. Under the **No Cold Handoffs** approach, the next stage received both the result and a summary of the checks behind it. For 2,500 merchants, the operator launched two modules from PowerShell on AWS. For 25,000, the operator opened an early AWS campaign console from PowerShell and used the browser to submit and monitor the run. Today, the Windows campaign console lets an analyst choose a policy on a local desktop or AWS, review and adjust experiment parameters and resolve conflicting choices before submitting the experiment.

Read each pair **Baseline → Recession Energy**. *Supportable* includes applications authorized for funding and those referred for review. *Open / funded* counts accounts with a positive ending balance among all accounts funded in that scenario. Each row follows its own synthetic population. Select a study and open its campaign film to see how it ran and follow a merchant through the decision.

| Study | Supportable | Funded | Open / funded at day 120 | Daily monitoring records |
| --- | ---: | ---: | --- | ---: |
| [750 · Local DBeaver](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750a/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-DBeaver/RiskDecisionScenarioReview) | 300 → 80 | 103 → 27 | 4/103 → 0/27 | 15,600 |
| [750 · Local GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-GUI/RiskDecisionScenarioReview) | 321 → 94 | 115 → 35 | 5/115 → 1/35 | 18,000 |
| [750 · AWS GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750c/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-AWS-GUI/RiskDecisionScenarioReview) | 318 → 72 | 110 → 26 | 5/110 → 1/26 | 16,320 |
| [2,500 · AWS PowerShell](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#2500/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-2500-AWS-PowerShell/RiskDecisionScenarioReview) | 1,055 → 269 | 329 → 100 | 22/329 → 7/100 | 51,480 |
| [25,000 · AWS GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#25000/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-25000-AWS-GUI/RiskDecisionScenarioReview) | 10,564 → 2,836 | 3,337 → 1,005 | 176/3,337 → 43/1,005 | 521,040 |

**Where can a bank keep lending in a recession, and what risk remains?** In the 750 · AWS GUI study, the same policy evaluated the same 750 simulated businesses. In Baseline, 110 received funding. Under Recession Energy, 26 received funding and 25 of them paid off by day 120. Merchant 000225 received the same $150,000 inventory advance in both scenarios. It still owed **$20,062.18 in Baseline and $21,410.48 under stress**. [Explore the AWS study](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750c/repayment)

In the 25,000-merchant study, the share still open fell from **5.27% to 4.28%** across the two funded portfolios. Follow just the **1,005 merchants funded in both**, and the open count rises from **36 to 43**. The change in who qualified explains why those comparisons point in different directions. The Local DBeaver counts use certified ending balances. The other reported endpoints use outstanding contractual receivables. [Study sources, definitions and checks](research-site/evidence/STUDY_SOURCES.md)

The later 750-merchant runs provide a timing guide for the original DBeaver study. Computation took about **2 h on a local Windows desktop** (8 GB RAM, Core i5-2500K at 3.30 GHz) and **45 min on AWS EC2 Windows** (m7i-flex.4xlarge). The 2,500 study’s **2 h 24 min** combines two AWS module runs, with m7i.4xlarge as the reference configuration. The 25,000 study recorded **15 h 26 min** on AWS EC2 Windows (m7i-flex.4xlarge). [Timing records and measurement scope](research-site/evidence/execution_records.csv)

This first version lets an analyst test how a policy choice changes offers and simulated repayment. Two questions come next. Do the decisions identify businesses that can repay while meeting operating expenses? Can a bank’s underwriting and servicing teams use the evidence at the point they have to act? Answering those questions takes observed merchant outcomes and testing within a bank’s workflow.

## Follow the work

| Reader’s question | Where to go |
| --- | --- |
| What evidence and U.S. rules inform this product? | [Watch the research introduction and read the sources](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/sources) |
| How is the product designed, and which requirements govern it? | [Watch the architecture and audit film](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/project) · [Project guide](research-site/PROJECT_GUIDE.md) · [Module 2 business requirements and validation](docs/BRD_AND_VALIDATION_INDEX.md) |
| Where does the code turn sales into a payment? | [Numbered stage map](docs/README.md#stage-map) · [M2.5 daily monitoring](docs/guide/stages/M2_05.md) · [SQL that caps the payment at the remaining balance](Module_2/2.05_Daily_Remittance_Exposure_and_Portfolio_Monitoring/v0.2R5_ACCEPTED/src/current/03_166_generation.sql#L872) |
| How can I run a challenger or inspect a completed campaign? | [Watch the GUI and parameter guide film and open the Windows setup instructions](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/experiment) · [Reports by study](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/reports) · [Andrew Goad’s Tableau Public collection](https://public.tableau.com/app/profile/andrew.goad/vizzes) |
| Can I reproduce the published figures? | [Evidence and reproduction commands](research-site/evidence/STUDY_SOURCES.md) · [Historical M2.5 stage acceptance](Module_2/2.05_Daily_Remittance_Exposure_and_Portfolio_Monitoring/v0.2R5_ACCEPTED/docs/VALIDATION_AND_ACCEPTANCE.md) · [Repository change log](CHANGELOG.md) |
