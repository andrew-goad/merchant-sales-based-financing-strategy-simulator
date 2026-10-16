# Analytical reading · Portfolio, application and account

[Portfolio home](../../README.md) · [Documentation portal](../README.md) · [Current use](CURRENT_USE.md)

Use the portfolio view to find a question, the application journey to understand its reasons, and the account evidence to inspect what followed. The cohort report adds deeper source-grounded interpretation.

## Four accepted analytical experiences

**P01 · Cohort Command Center**

**Question:** Where are funding, risk and endpoint exposure concentrated? **Current reading route:** Portfolio-level comparison with explicit scenario and denominator.

**P02 · Cohort Lifecycle**

**Question:** How do balances, payoff and attention states develop through the synthetic-forward period? **Current reading route:** Daily account evidence; watch status is not the same as an actionable condition.

**P03 · Application Journey**

**Question:** Why this decision and these terms—and what happened after funding? **Current reading route:** Source-owned merchant/economics/decision narratives, with funded/nonfunded behavior preserved.

**P04 · Servicing & Exceptions**

**Question:** Which accounts need attention and how did execution reconcile? **Current reading route:** Recommendation, permissions, processing and certification evidence.


P02-DIAG remains hidden. P05/P06 are excluded from this current client-facing scope. The accepted report filename still includes `v2.1.0-rc2`; it is not a direction to rename the file or infer a new Git tag.

[![Actual accepted P01 command-center Baseline screenshot, not a reconstructed dashboard.](../power_bi/m2_v2_1/assets/power_bi/core/p01_command_center_baseline.png)](../power_bi/m2_v2_1/assets/power_bi/core/p01_command_center_baseline.png)

**Start with the portfolio, then trace a contributor.** The view is source-certified analytical consumption, not an engine that makes financing decisions. [Open the unchanged source at full resolution](../power_bi/m2_v2_1/assets/power_bi/core/p01_command_center_baseline.png).

[Open the actual P02 lifecycle view](../power_bi/m2_v2_1/assets/power_bi/core/p02_cohort_lifecycle_baseline.png) · [Read P03 as an explainability capability](EXPLAINABILITY.md) · [Open the actual P04 servicing view](../power_bi/m2_v2_1/assets/power_bi/core/p04_servicing_exceptions_baseline.png) · [View the immutable PBIX](CURRENT_USE.md#view-power-bi).

## Investigate the paired scenarios in Tableau

[Merchant Credit Intelligence · Risk Decision & Scenario Review](../tableau/README.md) adds a focused Tableau investigation surface over the same 750 matched synthetic applications. It supplements the accepted Power BI experiences; it is not a fifth Power BI page or a new financing engine.

Compare portfolio authorization rates, select a decision pairing, inspect its within-segment incidence, and select an application for side-by-side Decision, Evidence, Structure or Source rationale. Pairing selection uses parameter actions for the concentration numerator while preserving the full portfolio-filtered segment denominator. Selecting one application must not replace the portfolio KPIs with that application's counts.

[Tableau carousel](../tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel.pdf) · [Workbook and viewing limits](../tableau/docs/WORKBOOK_AND_EVIDENCE_NOTES.md)

The source engine remains responsible for decisions and governed terms. Existing Power BI acceptance and G3-v2 source certification do not automatically validate the Tableau implementation. No new release or supersession is created by this companion.

## Read the cohort, not just the dashboard

The accepted R3 PATCH1 cohort is a **53-page analytical read-ahead**, with an executive overview, matched-scenario outcomes, channel/industry views, lifecycle and monitoring evidence, account cases and a facts sheet. It is not a 53-control validation suite or a short pitch deck.

Its outcome-transition comparison has 750 complete scenario pairs. **236 pairs (31.5%)** change final decision category; 514 do not. This is Baseline versus Recession Energy, not software v2.0.0 versus the successor and not 236 “lost approvals.” Changes between two authorized categories still count as category changes; different terms within an unchanged category do not.

The report's source-evidence coverage counts describe screenshots, not merchant populations. Its dated workflow notices are retained historical prose; R18 supplies the later bounded PATCH1 integration acceptance, preserved by R20. R17's separate Power BI acceptance is not cohort-report acceptance.

[Read the full accepted cohort PDF](../portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/cohort/MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R3_PATCH1_20260908_REVIEW.pdf) · [Open its retained editable PowerPoint](../portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/assets/cohort/MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R3_PATCH1_20260908.pptx).

The public cohort edition is available in the two registered formats linked above: PDF for reading and PowerPoint for editable access. Separate previews and private source figures are not public assets.

## Keep economics and populations honest

The demonstration has 750 synthetic merchants and 1,500 application-scenario paths. Authorization rates use 750 applications per scenario; funded lifecycle and payoff measures use 103 Baseline or 27 Recession Energy funded paths. The combined 130 count is a scenario-path count, not 130 distinct real customers.

Modeled risk-adjusted contribution is not audited realized profitability. Comparative expected loss is not CECL. A zero reconciliation-exception count can coexist with nonzero ending exposure. Synthetic-forward dates are not a claim to have observed future real-world results.

## Evidence and source routes

[Power BI BRD](../power_bi/m2_v2_1/docs/POWER_BI_BUSINESS_REQUIREMENTS.md) · [Power BI validation](../power_bi/m2_v2_1/docs/POWER_BI_VALIDATION_REPORT.md) · [Canonical accepted composition](../power_bi/m2_v2_1/docs/CANONICAL_SOURCE_OF_TRUTH.md) · [Portfolio-performance source interpretation](stages/M2_10.md) · [G3/G3-v2 source certification](stages/M2_12.md).

*Deterministic synthetic demonstration · Non-production · No real funds. This current-reading page does not alter source-of-record evidence.*
