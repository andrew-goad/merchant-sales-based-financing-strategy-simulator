## Explore the research in your browser

A business receives working capital and repays a share of eligible daily sales. Five synthetic campaigns follow those agreements from the financing decision to the balance remaining on day 120. The simulator demonstrates how lending rules work under modeled conditions. Its effectiveness for real businesses remains an open question.

[Read *When repayment follows sales*](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/)

In the **750 · Local GUI** study, a merchant received a $146,600 advance for equipment repair. On the same terms, Baseline paid off on day 111 and Recession Energy finished day 120 with $3,743.44 outstanding. The **25,000** study shows why the share still owing changes depending on which funded merchants you compare. [Follow the merchant](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#750b/repayment) · [Inspect the portfolio comparison](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/#25000/outcomes)

## Open a saved study

Start with **750 · Local GUI** to inspect the equipment-repair case. Every Tableau dashboard opens in a browser. For a local copy, choose the Tableau packaged workbook (.twbx) or the Power BI report (.pbix) in the same row. Open .twbx files in Tableau Desktop or Tableau Desktop Public Edition, and .pbix files in Power BI Desktop on Windows. The files contain the saved study results.

| Campaign | Tableau Public | Tableau download | Power BI download |
| --- | --- | ---: | ---: |
| 750 · Local DBeaver | [Open dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-DBeaver/RiskDecisionScenarioReview) | [0.35 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-750-Local-DBeaver.twbx) | [26.33 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-750-Local-DBeaver.pbix) |
| 750 · Local GUI | [Open dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-Local-GUI/RiskDecisionScenarioReview) | [0.36 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-750-Local-GUI.twbx) | [28.06 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-750-Local-GUI.pbix) |
| 750 · AWS GUI | [Open dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-750-AWS-GUI/RiskDecisionScenarioReview) | [0.35 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-750-AWS-GUI.twbx) | [27.75 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-750-AWS-GUI.pbix) |
| 2,500 · AWS PowerShell | [Open dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-2500-AWS-PowerShell/RiskDecisionScenarioReview) | [0.94 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-2500-AWS-PowerShell.twbx) | [90.45 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-2500-AWS-PowerShell.pbix) |
| 25,000 · AWS GUI | [Open dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MSBF-25000-AWS-GUI/RiskDecisionScenarioReview) | [7.91 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-25000-AWS-GUI.twbx) | [879.66 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF-25000-AWS-GUI.pbix) |

## Run your own experiment on Windows

The RC21 A3 operator launches the campaign console so you can choose a population and policy, submit a new experiment, and follow its progress. The Windows setup guide covers 64-bit Python, PostgreSQL 17.11 and Windows PowerShell. It also walks through opening the resulting Tableau and Power BI workbooks. [Read the Windows experiment guide](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/experiment.html) · [Download RC21 A3 · 342.67 MiB](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF_Portable_Windows_RC21_A3.zip)

## Verify a download

In PowerShell, run `Get-FileHash -Algorithm SHA256 -LiteralPath '.\YOUR-FILENAME'` from the download folder, substituting your filename. For any of the ten workbooks, match the result to its named entry in [the workbook checksums](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/SHA256SUMS.txt). For the operator ZIP, use [the operator checksum](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/msbf-research-assets-2026-11/MSBF_Portable_Windows_RC21_A3.zip.sha256).

The RC21 A3 ZIP has SHA-256 `1e04cb721eddbec19ffd97afbd80469ac750b148da701344d32b1457f49783f0`. [Trace a payment to the SQL and ledger](https://andrew-goad.github.io/merchant-sales-based-financing-strategy-simulator/PROJECT_GUIDE.html)
