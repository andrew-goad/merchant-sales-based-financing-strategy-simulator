# Reproduce the financing and repayment findings

The five studies each have a distinct synthetic population. Among the three 750-merchant runs, the [Local DBeaver summary](official_750_r26_summary.csv) reports the original DBeaver campaign, the [Local GUI paired decisions](application_paths.csv) follow Local Take 4, and the [AWS GUI summary](aws_750_take1_summary.csv) records AWS Take 1. Look up each finding under its own run.

| Study | Source of its reported outcomes | Decisions | Daily monitoring records |
| --- | --- | ---: | ---: |
| 750 · Local DBeaver | *750-Merchant Cohort Validation*, pp. 2–3 and 28. Scenario aggregates include the certified ending balance after servicing. | 1,500 | 15,600 |
| 750 · Local GUI | Governed final decisions, bookings and daily remittances in the Local 750 return | 1,500 | 18,000 |
| 750 · AWS GUI | EC2 campaign report for decisions, principal and monitoring rows. Power BI P04 for day-120 payoff and open counts. | 1,500 | 16,320 |
| 2,500 · AWS PowerShell | Validated decision, funding and monitoring extracts from the historical two-module study | 5,000 | 51,480 |
| 25,000 · AWS GUI | AWS campaign decision summary, funding records, daily monitoring and matched Tableau data | 50,000 | 521,040 |

For 2,500 merchants, the operator launched two modules from PowerShell on AWS. For 25,000, the operator opened an early AWS campaign console from PowerShell and used the browser to submit and monitor the run.

The records model financing offers to synthetic businesses. They support comparisons within each experiment. Observed performance in a real lending portfolio remains an empirical question.

## Recalculate the exhibits

From the repository root, run these commands with Python 3.11 or later. The checks use the included extracts and the Python standard library.

```powershell
python -B research-site/evidence/verify_studies.py
python -B research-site/evidence/check_readme_table.py
```

The first command checks the study file digests, reconciles the AWS 750 endpoint counts to funded accounts and checks the scenario aggregates. For Local Take 4 and the two larger studies it reconciles the financing decisions and day-120 contractual receivables, and recalculates the daily payments in each featured trace. It also checks the decision transition counts, the earlier payoff example, the counteroffer counts and the recorded durations. The second checks the repository’s comparison and the five interactive studies against the same extracts. It verifies Baseline and Recession Energy separately in each funding table, including principal and supportable share, and checks each selector’s label and the decisions and monitoring totals at the top of each study. [Study verifier](verify_studies.py) · [Repository and Pages checks](check_readme_table.py) · [Study file checksums](study_extract_sha256.json)

## Choose the right denominator

| Question | Records to inspect |
| --- | --- |
| How did the policy classify all applicants? | The [seven decision categories](decision_counts.csv) sum to the size of each cohort in each scenario. The 750 rows in this file cover Local Take 4. A supportable path includes either authorization or a referral for review. Only the two authorization categories funded in these studies. |
| Where did the same applicant go under stress? | The [matched decisions](governed_decision_transitions.csv) cross authorization, review and decline. The last column counts changes among the seven detailed categories, including a counteroffer replacing an approval for the full request. The totals are 241 of 750 in the Local Take 4 rehearsal, 822 of 2,500 and 8,163 of 25,000. |
| Which merchants received financing in each scenario? | For Local 750, compare [all paired decisions and closing balances](application_paths.csv) with [issued principal](funding_pairs.csv). The [2,500](funded_paths_2500.csv) and [25,000](funded_paths_25000.csv) extracts include each merchant funded in at least one scenario. |
| How many still owed money after 120 days? | A positive closing contractual receivable counts as open. A zero balance records payoff. A blank scenario balance denotes an application that received no financing in that scenario. Restrict both sides to merchants funded twice to compare the same borrowers. |

## AWS 750 endpoint

In the AWS workbook, open **P04 · Servicing & Exceptions** and read **Endpoint monitoring posture** for all accounts in each scenario. Baseline shows 105 paid off and 5 in severe shortfall. Recession Energy shows 25 paid off and 1 in severe shortfall. Every other category is zero. The funded portfolios contain 110 and 26 accounts, respectively. [Baseline capture](aws750/P04_All.png) · [Recession Energy capture](aws750/P04_All_R.png)

P04 counts distinct funded accounts by monitoring status on the last observation date, November 22, 2026 (day 120). Module 2.5 assigns “Paid off” when the closing contractual receivable reaches zero. The five Baseline accounts and one Recession Energy account in severe shortfall therefore ended with a positive contractual balance. The `paid_off` and `open_accounts` fields in the [AWS study summary](aws_750_take1_summary.csv) record those endpoint counts.

## Follow the sales into the payments

The three detailed daily traces below follow merchants who received matching terms. Their first 60 collection days replay the same sales history. Day 61 first draws on a date affected by the energy shock. A daily payment equals eligible sales multiplied by the contractual remittance rate, rounded to cents and capped at the opening receivable. [Local Take 4 · merchant 000462 and repayment chart](../figures/merchant_462_receivable.png) · [Local Take 4 daily ledger](merchant_000462.csv) · [2,500 · merchant 002411](merchant_002411.csv) · [25,000 · merchant 009886](merchant_009886.csv)

The Local 750 files also show [terms and payoff dates for the 35 merchants funded twice](jointly_funded_terms_and_payoff.csv). Merchant 000499 repaid one day earlier under stress. The daily records let you inspect the replayed sales, simulation factors, eligible sales and actual collections behind that result. [Merchant 000499](merchant_000499_stress_sales.csv)

The suggested GUI experiment raises the minimum counteroffer amount. The [standard-policy counteroffer counts](counteroffer_floor_sensitivity.csv) show how many selected offers were below 60% of the request. Estimating the change in approvals or payments requires a separate challenger run.

## Interpreting computation time

The Local 750 clock covers native financial execution. The 45-minute AWS timing comes from a separate 750 rehearsal. Both are timing guides for the original DBeaver workflow. For 2,500, the 2 h 24 min sums two module receipts from different executions. The displayed m7i.4xlarge is the reference configuration. The Module 1 receipt identifies m7i-flex.large, and the Module 2 receipt leaves the instance type unspecified. The 25,000 campaign recorded 15 h 26 min of computation. Study sizes, releases and execution procedures differ. [Execution records, platforms and clock scope](execution_records.csv)

[Project license](../source-notices/MSBF_PROJECT_LICENSE.txt)
