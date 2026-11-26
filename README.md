# When repayment follows sales

A business needs to repair its equipment. It receives an advance and agrees to repay a share of its daily sales. A slow sales day means a smaller payment. How does that change the financing a business can obtain and the balance it carries?

I built the Merchant Sales-Based Financing Strategy Simulator to follow those questions from underwriting rules to daily collections. The five studies below use synthetic merchants. They demonstrate how the engine makes decisions and applies a contract under modeled conditions. Judging whether these policies work for real businesses requires observed outcomes.

**[Read the interactive paper from the beginning](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/)** · [Run an experiment in the Windows GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/experiment) · [Inspect requirements, code and validation](research-site/PROJECT_GUIDE.md)

## One equipment repair in the 750 Local GUI study

Merchant **000462** received the same **$146,600 advance** on the same terms in both scenarios. The agreed total repayment was **$184,463.41**. On day one, eligible sales of $24,302.06 generated a $2,373.63 payment at the 9.7672% remittance rate. The balance fell to $182,089.78. The model replays sales already available at underwriting, and the two balance paths first diverge on day 61.

![Outstanding contractual balance for merchant 000462. The curves agree through day 60. Baseline pays off on day 111. Under Recession Energy the merchant still owes 3,743.44 dollars on day 120.](research-site/figures/merchant_462_receivable.png)

In Baseline the advance paid off on day 111. Under Recession Energy the merchant still owed **$3,743.44 on day 120**. Funding fell from **115 of 750** businesses to **35 of 750**. Among all funded merchants, 5 of 115 still owed money in Baseline and 1 of 35 under stress. Among the **same 35** funded in both scenarios, the counts were **0 and 1**. The equipment-repair merchant was that one. [Daily ledger](research-site/evidence/merchant_000462.csv) · [Application-level decisions and balances](research-site/evidence/application_paths.csv)

## Five completed studies

Each row compares **Baseline → Recession Energy** within one campaign. “Supportable” includes funded applications and referrals for review. “Open / funded” counts positive balances on day 120 among the businesses funded in that scenario. An outstanding balance at that point measures money still owed. The historical DBeaver study uses certified endpoint exposure, and the other studies use contractual receivables.

| Study | Supportable | Funded | Open / funded at day 120 | Daily monitoring records |
| --- | ---: | ---: | --- | ---: |
| [750 · Local DBeaver](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750a/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-DBeaver/RiskDecisionScenarioReview) | 300 → 80 | 103 → 27 | 4/103 → 0/27 | 15,600 |
| [750 · Local GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-GUI/RiskDecisionScenarioReview) | 321 → 94 | 115 → 35 | 5/115 → 1/35 | 18,000 |
| [750 · AWS GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750c/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-AWS-GUI/RiskDecisionScenarioReview) | 318 → 72 | 110 → 26 | 5/110 → 1/26 | 16,320 |
| [2,500 · AWS PowerShell](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#2500/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-2500-AWS-PowerShell/RiskDecisionScenarioReview) | 1,055 → 269 | 329 → 100 | 22/329 → 7/100 | 51,480 |
| [25,000 · AWS GUI](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#25000/repayment) · [Explore in Tableau](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-25000-AWS-GUI/RiskDecisionScenarioReview) | 10,564 → 2,836 | 3,337 → 1,005 | 176/3,337 → 43/1,005 | 521,040 |

In the **separate 25,000 study**, 176 of 3,337 funded businesses still owed money in Baseline (5.27%), compared with 43 of 1,005 under stress (4.28%). Among the **same 1,005** funded in both, 36 still owed money in Baseline (3.58%) and 43 under stress. Matching the merchants holds their identities fixed. Sixty-one received different advances across scenarios. [25,000 funded paths](research-site/evidence/funded_paths_25000.csv) · [Study definitions and verification](research-site/evidence/STUDY_SOURCES.md)

## Run a new policy comparison or inspect the evidence

The original 750 study ran manually in DBeaver and produced 1,500 decisions and 15,600 daily monitoring records. Later campaigns used repeatable PowerShell and browser workflows. On Windows the RC21 A3 GUI lets you choose settings, resolve conflicting choices and save a reference population for a paired challenger. The paper includes the operating steps for the selected study. The saved workbooks let you investigate the completed campaigns. [Inline experiment procedure](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/experiment) · [Saved workbooks and Windows operator](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/msbf-research-assets-2026-11) · [Computation records](research-site/evidence/execution_records.csv)

To trace one payment, start with the contractual balance cap, then follow the SQL into the account-day record. The stage index connects each implementation to its own requirements and acceptance evidence. [Project guide](research-site/PROJECT_GUIDE.md) · [M2.5 business requirements](Module_2/2.05_Daily_Remittance_Exposure_and_Portfolio_Monitoring/v0.2R5_ACCEPTED/docs/BRD.md) · [Collection cap in SQL](Module_2/2.05_Daily_Remittance_Exposure_and_Portfolio_Monitoring/v0.2R5_ACCEPTED/src/current/03_166_generation.sql#L872) · [Requirements and validation by stage](docs/BRD_AND_VALIDATION_INDEX.md)

Andrew R. Goad · [LinkedIn](https://www.linkedin.com/in/andrewrgoad) · [Cite the research or software](research-site/PROJECT_GUIDE.md#cite-this-work)
