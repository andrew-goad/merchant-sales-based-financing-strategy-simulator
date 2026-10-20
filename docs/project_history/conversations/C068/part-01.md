# Merchant POS Lending Simulator

Part 01 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Next part](part-02.md)

<a id="m-37832421-6392-4d21-a5eb-7dd4ab7ed00c"></a>
## Andrew / user · C068-M00001

C068-M00001 · 2026-07-23T12:54:09.812000-04:00 · active path

**Editorial record note:** Attachment references: module2_credit_policy_strategy_decision_outcome_simulation_engine_v1.0(3).sql; module1_synthetic_application_risk_engine_v2.0(25).sql; Enterprise_Credit_Decisioning_Simulator_Module1_Validation_Summary_v2.0 (1).pdf; Enterprise_Credit_Decisioning_Simulator_Module1_Synthetic_Application_Risk_Engine_BRD_v2.0 (1).pdf; Pasted markdown(11).md

<!-- BEGIN_SOURCE_MESSAGE -->
For context, here is the code for my module 1 v2.0 and module 2 of the credit decisioning strategy simulator plus the module 1 v2.0 brd/validation.  See attached prompt. Take your time and be very diligent. I'd like to design all phases of this Merchant POS Lending Strategy Simulator by early or midday tomorrow.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b32cb8e3-6391-4f59-88ea-8b3b5c2eea7b"></a>
## Assistant · C068-M00002

C068-M00002 · 2026-07-23T13:10:32.354305-04:00 · active path

Preceding visible parent: [C068-M00001](part-01.md#m-37832421-6392-4d21-a5eb-7dd4ab7ed00c)

<!-- BEGIN_SOURCE_MESSAGE -->
# Merchant POS Lending Strategy Simulator — Design Blueprint v0.1

I reviewed the merchant-lending prompt together with the Module 1 V2.0 SQL, BRD, Validation Summary, and the Module 2 strategy engine. The correct approach is to reuse the **governance and decision-system architecture**, not the consumer-credit economics.

Your existing work already establishes the most difficult reusable patterns: deterministic population anchoring, centralized parameter control, staged transformations, latest-run versus archive separation, matched comparisons, diagnostic transparency, synthetic-risk boundaries, and evidence-driven validation. Module 2 adds profile-driven strategies, product-policy controls, counteroffer feasibility, deterministic explanation codes, campaign registries, strategy frontiers, persistent evidence, and post-campaign acceptance. [export reference: filecite | turn0file0] [export reference: filecite | turn0file1] [export reference: filecite | turn1file1]

The merchant project should preserve that architectural discipline while replacing the underlying economics with merchant revenue quality, cash-flow conversion, seasonality, transaction reversals, existing business obligations, declining-balance exposure, pricing economics, and portfolio concentration. That is also the distinction required in the attached project prompt. [export reference: filecite | turn0file2]

A design-complete package by early or midday tomorrow is realistic, provided “design-complete” means:

| Design artifact | Tomorrow’s target |
|---|---|
| Product decision record | Product, repayment, pricing, target market, boundaries |
| Enterprise architecture | Module sequence, lineage, latest/archive design |
| Logical data model | Grains, keys, history windows, comparison keys |
| V1 variable framework | 20–30 governed feature families |
| Credit and sizing framework | Eligibility, capacity, exposure, counteroffer |
| Pricing and economics framework | Revenue, costs, EAD, EL, contribution |
| Risk-appetite framework | Account limits, portfolio limits, actions and owners |
| Scenario and strategy register | Controlled initial campaign |
| Validation framework | Data, realism, risk, economics, strategy, reporting |
| Implementation backlog | Ordered build phases and acceptance gates |

It should not mean that the PostgreSQL engines, validation campaign, documentation package, and Power BI application are all implemented and validated by tomorrow.

---

## 1. Why this parallel project is strategically valuable

This project fills a genuine portfolio gap rather than duplicating your current simulator.

### It demonstrates transferability without overstating experience

Your existing simulator proves consumer-credit decision architecture. The merchant project demonstrates that you can transfer the same portfolio-management disciplines into a materially different domain:

- time-series cash-flow underwriting rather than primarily bureau-based underwriting;
- revenue quality rather than income alone;
- business and owner risk separation;
- short-term declining exposure;
- partner and industry concentration;
- offer-level pricing economics;
- repayment burden against volatile revenue;
- portfolio allocation under risk-appetite constraints.

That is a credible transfer-of-discipline story. It does not require claiming prior ownership of a production merchant-lending portfolio.

### It connects all major portfolio-management responsibilities

The resulting system would answer the management questions that matter:

1. Which merchants qualify?
2. What exposure is supportable?
3. What structure is affordable?
4. What price is economically viable?
5. What portfolio concentrations and risk limits should govern deployment?

The project therefore spans underwriting, exposure, pricing, expected loss, profitability, concentration management, champion/challenger testing, validation, and executive reporting rather than stopping at synthetic risk scoring.

### It complements your current system

The existing Module 1 concludes at borrower/product risk and comparative Expected Loss. The current Module 2 intentionally excludes revenue, funding cost, profitability, capital, and pricing optimization. The merchant system should use the same clean module separation, but its Module 2 should include **illustrative offer economics and risk-adjusted contribution**, because pricing and portfolio economics are central to this project’s thesis. [export reference: filecite | turn3file3]

---

## 2. The three plausible POS-linked product structures

| Structure | Core mechanics | Analytical strengths | Principal complications |
|---|---|---|---|
| **Closed-end short-term business loan** | Fixed principal, defined term, stated interest or finance charge, fixed ACH payment | Clear payment schedule, clean declining balance, transparent EAD, conventional affordability testing | Fixed payment may be less responsive to volatile merchant sales |
| **Sales-linked installment loan** | Loan obligation remains debt, but payment or remittance responds partly to POS receipts | Better alignment between payment and merchant revenue; strong POS-data story | Duration varies; payment forecasting and legal characterization become more complex |
| **Receivables purchase or revenue-based financing** | Purchased amount or fixed repayment amount collected as a share of future receivables | Authentic for some POS-finance providers; naturally sales-linked | Distinct legal/accounting treatment, factor-rate conventions, APR-equivalent ambiguity, and significant disclosure risk |

### Recommended V1 default

Use a:

> **Short-term closed-end small-business working-capital loan, underwritten primarily from POS and simplified deposit cash-flow data, with fixed weekly ACH repayment, a stated illustrative APR, and an optional origination fee.**

Recommended V1 term options:

- 26 weeks;
- 39 weeks;
- 52 weeks.

Recommended payment cadence:

- **Weekly**, not daily.

Weekly payment retains the short-duration merchant-lending character while avoiding unnecessary banking-calendar, holiday, ACH-retry, and daily-servicing complexity. Daily POS history should still be used for underwriting, but daily repayment does not need to be simulated in the first version.

The architecture should include a governed `repayment_mode`, with:

- `FIXED_WEEKLY` implemented in V1;
- `SALES_LINKED` reserved for a future enhancement.

This preserves the product-definition gate in the prompt: the project should not be described as a merchant cash advance unless that legal and economic structure is deliberately selected. [export reference: filecite | turn7file3]

### Important design boundary

The project can model illustrative loan economics, but it should not make conclusions about:

- legal product classification;
- required disclosures;
- state licensing;
- usury treatment;
- true-sale treatment;
- accounting classification;
- enforceability;
- regulatory compliance.

Those would require jurisdiction-specific legal and compliance review.

---

## 3. Recommended two-module architecture

The two-module structure in the prompt is correct, but each module should be sharpened around a specific boundary. [export reference: filecite | turn7file8]

## Module 1 — Merchant POS Cash-Flow, Structure & Risk Engine

### Business question

> Given a deterministic merchant population and an application as-of date, what merchant cash-flow profile, requested loan burden, synthetic default-risk proxy, EAD, LGD, and Expected Loss result from the selected merchant environment scenario?

### Recommended processing chain

```text
Run and Scenario Parameters
→ Deterministic Merchant Population
→ Baseline Daily POS History
→ Scenario-Adjusted POS History
→ Deposit and Liquidity Proxies
→ As-of Cash-Flow Feature Snapshot
→ Requested Loan Structure
→ Requested Payment and Burden
→ Base Merchant Risk
→ Requested-Structure Risk Overlay
→ Expected EAD
→ LGD
→ Expected Loss
→ Latest Output
→ Scenario Archive
→ QA and Matched Scenario Comparison
```

### Recommended stages

| Stage | Purpose |
|---|---|
| M1.0 | Purpose, boundaries, section map |
| M1.1 | Schema and clean rerun controls |
| M1.2 | Scenario, population, merchant-mix and economic parameters |
| M1.3 | Fail-fast parameter and lineage gatekeeper |
| M1.4 | Deterministic merchant/application population |
| M1.5 | Base daily POS and deposit history |
| M1.6 | Scenario overlays applied to matched daily history |
| M1.7 | As-of revenue, stability, quality, liquidity and debt features |
| M1.8 | Requested structure, payment and burden |
| M1.9 | Base merchant risk and requested-structure risk |
| M1.10 | Expected EAD, LGD and Expected Loss |
| M1.11 | Latest-run output |
| M1.12 | Scenario archive |
| M1.13 | Single-run QA |
| M1.14 | Matched scenario comparison |
| M1.15 | Evidence summary and scenario acceptance |

The scenario-design table on page 37 of your existing BRD makes an especially important distinction: `scenario_name` identifies **what is being tested**, while `population_id` identifies **who is being tested**. That same separation should be retained for merchants. [export reference: filecite | turn6file0]

## Module 2 — Underwriting, Offer, Pricing & Portfolio Strategy Engine

### Business question

> Given a completed Module 1 merchant-risk profile and a governed strategy, what offer—if any—is individually feasible, economically viable, portfolio-compliant, and explainable?

### Recommended processing chain

```text
Module 1 Merchant Profile
→ Strategy and Policy Profiles
→ Source and Lineage Validation
→ Eligibility and Risk Segmentation
→ Rule-Trigger Evidence
→ Candidate Offer Generation
→ Candidate Payment and Burden
→ Offer-Specific Risk Overlay
→ Pricing and Expected Economics
→ Counteroffer Feasibility
→ Candidate Ranking
→ Concentration and Funding-Budget Allocation
→ Final Outcome
→ Reason Codes
→ Latest Output
→ Archive
→ Matched Strategy Comparison
→ Strategy Frontier
→ Evidence Capture
→ Post-Campaign Acceptance
```

### Recommended stages

| Stage | Purpose |
|---|---|
| M2.0 | Purpose, boundaries, architecture map |
| M2.1 | Strategy, industry-policy, channel-policy and pricing profiles |
| M2.2 | Run selector, campaign registry and comparison registry |
| M2.3 | Fail-fast strategy/source/policy gatekeeper |
| M2.4 | Module 1 source staging and lineage normalization |
| M2.5 | Merchant-risk, cash-flow and exposure segmentation |
| M2.6 | Eligibility and non-final policy flags |
| M2.7 | Preliminary route |
| M2.8 | Candidate-offer generation |
| M2.9 | Candidate burden, offer-specific risk and economics |
| M2.10 | Feasibility testing and candidate ranking |
| M2.11 | Portfolio concentration and funding-budget allocation |
| M2.12 | Final decision resolution |
| M2.13 | Simulated explanation-code assignment |
| M2.14 | Latest output |
| M2.15 | Archive persistence |
| M2.16 | Matched baseline/challenger comparison |
| M2.17 | Latest-run validation |
| M2.18 | Strategy and economics frontier |
| M2.19 | Persistent evidence capture |
| M2.20 | Post-campaign acceptance |

This retains the strong staged pattern in your current Module 2—source, segmentation, flags, routing, exposure treatment, outcome, reasons, archive, comparison, QA, frontier, evidence and acceptance—but inserts the merchant-specific candidate-pricing and portfolio-allocation layers. [export reference: filecite | turn5file4]

### One deliberate departure from the current Module 2

Your present Module 2 does not recalculate the upstream estimated-PD proxy. In the merchant simulator:

- Module 1 should calculate a **base merchant-risk proxy** and a **requested-structure risk proxy**.
- Module 2 should preserve the base merchant-risk assessment.
- Module 2 may calculate an **offer-specific structural risk overlay** because changing amount, term and payment burden changes the risk associated with the proposed offer.

This is not rebuilding the merchant model. It is translating an approved or counteroffered structure into offer-specific risk.

---

## 4. Recommended table grains

### Core operational and analytical grains

| Logical table | Grain | Primary business key | Purpose |
|---|---|---|---|
| `merchant_population` | One row per synthetic merchant per population | `population_id + merchant_id` | Stable merchant identity and intrinsic profile |
| `merchant_application` | One row per application | `population_id + merchant_application_id` | Application date, requested structure and as-of date |
| `merchant_pos_daily_base` | One row per merchant per calendar date | `population_id + merchant_id + observation_date` | Immutable deterministic baseline POS history |
| `merchant_pos_daily_scenario` | One row per scenario, merchant and date | `scenario_set + scenario + population + merchant + date` | Scenario-adjusted daily POS, refunds, chargebacks and deposits |
| `merchant_feature_snapshot` | One row per Module 1 scenario and application | `scenario_set + scenario + population + application` | All features available as of the application date |
| `merchant_request_risk` | One row per Module 1 scenario and application | Same as feature snapshot | Requested payment, burden, risk proxy, EAD, LGD and EL |
| `offer_candidate` | One row per application, strategy and candidate | M1 lineage + M2 strategy lineage + application + `candidate_id` | Alternative amount/term/price structures |
| `strategy_decision_latest` | One row per selected application and current strategy | M1 lineage + M2 strategy lineage + application | Replaceable latest final decision |
| `strategy_decision_archive` | One row per application, scenario and strategy version | M1 lineage + M2 strategy lineage + application | Persistent comparison history |
| `portfolio_limit_status` | One row per run, limit and monitored segment | Run key + `risk_appetite_limit_id + segment_key` | Limit, early warning, breach, action and owner |
| `strategy_run_evidence` | One row per completed run | Technical run key | Executive outcome, exposure, risk and economics evidence |
| `strategy_run_segment_evidence` | One row per run and segment | Run key + segment level + segment key | Industry, channel, risk-tier and merchant-size drivers |
| `campaign_registry` | One row per planned/completed run | Deterministic run ID | Documentation and campaign linkage |
| `comparison_registry` | One row per governed comparison | Comparison ID | Explicit baseline/challenger selection |

### V1 simplification

Use **one application per merchant** initially, while retaining distinct `merchant_id` and `merchant_application_id`. That supports future:

- repeat applications;
- renewals;
- multiple applications per merchant;
- booked-account performance.

### Base history versus scenario history

Do not regenerate a completely different daily merchant history for each scenario. Instead:

1. Generate one deterministic baseline history.
2. Apply scenario transformations to the same merchant/date observations.
3. Preserve all merchant IDs and dates.
4. Archive the scenario feature and risk snapshots.

This makes scenario deltas attributable and avoids population noise.

### Leakage control

Every underwriting feature must satisfy:

```text
observation_date <= as_of_date
```

The feature window should be explicit, such as:

```text
as_of_date - 364 days through as_of_date
```

The same `as_of_date`, merchant IDs, application IDs and baseline history must be used for matched scenarios. The attachment explicitly requires this no-future-data condition. [export reference: filecite | turn7file15]

### Recommended scale

For the portfolio-grade V1 validation run:

- 5,000 merchants;
- 365 daily observations;
- approximately 1.825 million baseline POS rows;
- six Module 1 scenario snapshots;
- nine candidate offers per merchant and strategy, generated temporarily;
- approximately 95,000 archived final decisions for a 19-run Module 2 campaign.

This is large enough to demonstrate data engineering and portfolio analysis without making the repository unwieldy.

---

## 5. The 30 most important V1 field families

These are **field families**, not necessarily single physical columns. They would probably produce approximately 45–55 output columns.

| # | Field family | Principal business purpose |
|---:|---|---|
| 1 | `population_id`, scenario identity | Reproducibility and matched comparison |
| 2 | `merchant_id`, `merchant_application_id` | Merchant and application lineage |
| 3 | `application_date`, `as_of_date`, history start/end | Leakage control and observation-window traceability |
| 4 | `industry_group`, `industry_risk_tier` | Structural revenue behavior, policy and concentration |
| 5 | `channel_id`, `partner_id`, `channel_risk_tier` | Acquisition quality, cost and concentration |
| 6 | `geography_region` | Regional segmentation and concentration |
| 7 | `months_in_business` | Business stability |
| 8 | `processor_tenure_months` | POS-history depth and data reliability |
| 9 | `owner_credit_score`, owner adverse flags | Guarantor-quality evidence; secondary to business cash flow |
| 10 | `business_bureau_score`, liens, bankruptcy, prior default | Business credit and legal-risk evidence |
| 11 | `avg_monthly_net_pos_sales_12m` | Long-run revenue level |
| 12 | `avg_monthly_net_pos_sales_3m` | Recent revenue capacity |
| 13 | `sales_growth_3m_vs_12m` | Recent deterioration or growth |
| 14 | `monthly_sales_coefficient_of_variation` | Revenue volatility |
| 15 | `zero_sales_day_rate_90d` | Operating continuity |
| 16 | `seasonality_index`, `largest_month_share` | Distinguish seasonality from concentration or deterioration |
| 17 | `refund_rate_90d` | Sales quality and reversal behavior |
| 18 | `chargeback_rate_90d`, reversal rate | Transaction dispute and operational risk |
| 19 | `deposit_to_pos_sales_ratio`, deposit consistency | POS-to-bank reconciliation and revenue usability |
| 20 | `negative_balance_days_90d`, `nsf_count_90d` | Liquidity stress |
| 21 | `existing_monthly_debt_service` | Existing payment burden |
| 22 | `active_short_term_advance_count`, `stacking_flag` | Existing short-term leverage |
| 23 | Requested structure: amount, term, payment frequency, use | Original merchant demand |
| 24 | `adjusted_eligible_monthly_revenue` | Governed, haircut revenue available for sizing |
| 25 | `adjusted_monthly_cash_flow_available` | Synthetic cash-flow capacity after industry conversion |
| 26 | `loan_to_annualized_sales`, `loan_to_monthly_sales` | Exposure intensity |
| 27 | `new_payment_to_sales`, `total_payment_to_sales` | Structural repayment burden |
| 28 | `post_loan_fixed_obligation_coverage_ratio` | Primary affordability/capacity measure |
| 29 | Risk/loss package: base risk, offer risk, EAD, LGD, EL | Risk ranking and comparative loss |
| 30 | Offer/economics/outcome package | Approved amount, term, price, contribution, outcome and reasons |

### What should be deliberately omitted from V1

Do not add these merely for apparent sophistication:

- full financial statements;
- tax-return simulation;
- payroll detail;
- detailed merchant-category codes;
- transaction-level card events;
- full UCC priority modeling;
- collateral valuation;
- real bank-statement classification;
- machine-learning features with no explanatory role;
- lifetime account-performance variables.

Each additional feature should have a defined business purpose, expected direction, valid range, QA test, and downstream use.

---

## 6. First-pass underwriting, sizing, counteroffer, pricing and risk-appetite framework

## 6.1 Primary affordability design

The consumer analogue should **not** be a direct substitution of PTI with payment-to-sales.

Gross sales are not business cash flow. The primary V1 capacity metric should be:

```text
Post-Loan Fixed-Obligation Coverage Ratio
=
Adjusted Monthly Cash Flow Available
÷
(Existing Monthly Debt Service + Proposed Monthly Payment)
```

Supporting measures should include:

```text
New Payment-to-Sales
=
Proposed Monthly Payment
÷
Adjusted Eligible Monthly Revenue
```

```text
Total Payment-to-Sales
=
(Existing Monthly Debt Service + Proposed Monthly Payment)
÷
Adjusted Eligible Monthly Revenue
```

### Recommended hierarchy

1. **Post-loan fixed-obligation coverage** — primary capacity control.
2. **Total payment-to-sales** — structural burden guardrail.
3. **Loan-to-sales** — exposure-size guardrail.
4. **Cash flow after debt service** — dollar buffer.
5. **Revenue trend and volatility** — confidence in the capacity estimate.

This captures authentic merchant economics: the same payment-to-sales ratio has different implications for a high-margin professional service business and a low-margin restaurant or retailer.

## 6.2 Adjusted eligible revenue

A conservative initial formula is:

```text
Adjusted Eligible Monthly Revenue
=
Minimum of:
    Recent 3-month average net POS sales
    6-month average net POS sales
    Seasonally adjusted 12-month average net POS sales
×
Data-quality factor
×
Revenue-stability factor
×
Transaction-quality factor
```

Possible haircuts:

- incomplete POS history;
- high volatility;
- recent sharp growth unsupported by history;
- high refunds;
- high chargebacks;
- inconsistent bank deposits;
- high zero-sales-day frequency;
- severe seasonal concentration.

The calculation should preserve each component and haircut diagnostically.

## 6.3 Adjusted cash-flow availability

Because POS sales are not operating cash flow:

```text
Adjusted Monthly Cash Flow Available
=
Adjusted Eligible Monthly Revenue
×
Industry Cash-Flow Conversion Margin
```

The conversion margin is a **synthetic policy assumption**, not an estimate of actual EBITDA or free cash flow.

Example tier structure:

| Industry profile | Illustrative conversion margin |
|---|---:|
| Higher-margin services | 25%–35% |
| General retail | 15%–22% |
| Restaurants and food service | 10%–18% |
| Fuel, grocery or other thin-margin sectors | 6%–12% |

These ranges should be public demonstration assumptions, not represented as production benchmarks.

## 6.4 Eligibility and routing

### Hard simulated stops

- insufficient POS-history window;
- inactive or terminated processor status;
- severe missingness or reconciliation failure;
- prohibited industry;
- severe bankruptcy or prior-default flag;
- two or more active short-term advances;
- extreme chargeback behavior;
- no positive capacity after existing obligations;
- requested use outside the synthetic product scope.

### Manual-review conditions

- 6–11 months in business;
- 3–5 months processor tenure;
- material POS/deposit conflict;
- strong owner credit but deteriorating business cash flow;
- weak owner credit but strong business cash flow;
- severe seasonality that cannot be separated from deterioration;
- one existing short-term advance;
- material threshold adjacency;
- unusual industry/channel combination.

### Demonstration starting bands

These are starting calibration bands, not production policy recommendations:

| Measure | Approve zone | Counteroffer zone | Review zone | Decline zone |
|---|---:|---:|---:|---:|
| Post-loan FOCR | ≥1.25x | ≥1.15x | 1.00x–1.15x | <1.00x |
| Total payment-to-sales | Industry-specific, generally ≤10%–12% | Generally ≤15% | 15%–18% | >18% |
| Recent sales change | Better than −15% | −15% to −25% | −25% to −35% | Worse than −35% |
| Monthly sales CV | ≤0.35 | 0.35–0.50 | 0.50–0.65 | >0.65 |
| Chargeback rate | Low tier | Moderate tier | High tier | Severe tier |
| Active short-term advances | 0 | 0–1 | 1 | 2+ |

All thresholds should ultimately be parameterized by industry and strategy profile.

## 6.5 Loan sizing

Calculate maximum payment capacity first:

```text
Maximum New Monthly Debt Service
=
Adjusted Monthly Cash Flow Available
÷
Minimum Required FOCR
−
Existing Monthly Debt Service
```

Convert to weekly capacity:

```text
Maximum Weekly Payment
=
Maximum New Monthly Debt Service × 12 ÷ 52
```

Then solve the supported principal using:

- selected term;
- selected APR;
- weekly amortization schedule.

Final individually supportable exposure:

```text
Maximum Individually Supportable Amount
=
Minimum of:
    Requested amount
    Payment-capacity amount
    Loan-to-sales cap
    Risk-tier exposure cap
    Industry-policy cap
    Global product cap
```

The final funded offer may be lower once concentration and funding-budget allocation are applied.

## 6.6 Transparent risk framework

Use an **additive points framework mapped through a bounded logistic transformation**, rather than multiplying many risk factors together.

Example:

```text
Base Merchant Risk Points
+ Revenue Decline Points
+ Volatility Points
+ Refund / Chargeback Points
+ Liquidity Stress Points
+ Existing Debt / Stacking Points
+ Business Stability Points
+ Owner / Business Credit Points
+ Industry / Channel Points
+ Offer Burden Points
=
Raw Risk Score
→ Bounded Estimated Default-Risk Proxy
```

Advantages:

- clearer component attribution;
- reduced risk of multiplier explosions;
- better high-risk differentiation;
- easier champion/challenger tuning;
- less mechanical cap crowding.

Your Module 1 V2.0 validation identified cap crowding as a material issue and introduced soft saturation to preserve differentiation. The merchant system can retain the same governance lesson while using an additive score-to-risk mapping from the outset. [export reference: filecite | turn2file8]

Required diagnostics:

- base merchant-risk points;
- each component’s point contribution;
- requested-structure points;
- offer-specific structure points;
- raw score;
- transformed risk proxy;
- floor/cap status;
- risk tier.

The output must remain a **synthetic estimated default-risk proxy**, not a calibrated production PD.

## 6.7 EAD and Expected Loss

Publish both methods.

### Reconciliation measure

```text
Simple Expected Loss
=
Estimated Default-Risk Proxy
×
LGD
×
Approved Amount
```

### Preferred V1 measure

```text
Schedule-Adjusted Expected Loss
=
Estimated Default-Risk Proxy
×
LGD
×
Expected EAD
```

Expected EAD should use the fixed weekly amortization schedule and parameterized default-timing weights.

For example:

```text
Expected EAD
=
Σ (
    Scheduled Outstanding Balance at Week t
    ×
    Default-Timing Weight at Week t
)
```

This is substantially more authentic for a rapidly amortizing short-term loan than assuming the original principal remains outstanding at default.

Retaining both measures gives a valuable validation identity:

```text
Schedule-adjusted EL should generally be lower than full-principal EL
for amortizing offers, all else equal.
```

## 6.8 Candidate-offer and counteroffer framework

Generate a bounded candidate set, not a continuous optimizer.

Recommended V1 candidate grid:

- amounts: 100%, 80%, and 60% of the lower of request and preliminary policy cap;
- terms: 26, 39, and 52 weeks;
- price: determined by risk tier, term, channel cost and strategy profile.

That creates nine candidates per otherwise eligible merchant.

Each candidate should calculate:

- weekly payment;
- new and total payment-to-sales;
- post-loan FOCR;
- loan-to-sales;
- offer-specific risk proxy;
- expected EAD;
- Expected Loss;
- gross finance income;
- costs;
- expected contribution;
- margin rate;
- all candidate feasibility flags.

### Recommended counteroffer sequence

1. Reduce amount.
2. Extend term.
3. Apply the appropriate risk-tier price.
4. Recalculate payment, risk, EAD, EL and contribution.
5. Select the best feasible candidate under the active strategy objective.

Price should never be used to “cure” an unaffordable structure. A higher rate increases payment burden and can worsen risk.

### Outcome resolution

| Condition | Final outcome |
|---|---|
| Requested structure passes all individual and portfolio controls | `APPROVE` |
| Requested structure fails, but another candidate is feasible | `COUNTEROFFER` |
| Data conflict, threshold adjacency or unresolved concentration issue | `MANUAL_REVIEW` |
| Hard stop or no viable candidate | `DECLINE` |

## 6.9 Pricing and risk-adjusted economics

Use a governed price card rather than a mathematical price optimizer.

Price dimensions:

- merchant risk tier;
- term;
- industry tier;
- partner/channel acquisition cost;
- optional relationship status;
- funding-cost environment.

### Required economics

```text
Gross Finance Income
+ Origination Fee Income
− Cost of Funds
− Partner Commission
− Servicing Cost
− Expected Credit Loss
− Capital Charge
=
Expected Net Contribution
```

Recommended calculations:

| Component | V1 treatment |
|---|---|
| Interest income | Weekly amortization schedule |
| Fee income | Illustrative upfront origination fee |
| Cost of funds | Schedule-based average outstanding balance |
| Partner commission | Percentage of approved/funded amount |
| Servicing cost | Fixed account cost plus payment-frequency cost |
| Expected loss | Offer-specific risk × LGD × expected EAD |
| Capital charge | Simplified risk-weighted EAD × term factor |
| Margin rate | Contribution ÷ approved amount |
| Return proxy | Annualized contribution ÷ average outstanding balance |

Avoid calling the return measure RAROC unless the denominator is explicitly modeled regulatory or economic capital.

### Pricing feasibility conditions

A candidate should pass only when:

- APR and fee remain within synthetic floor/cap parameters;
- FOCR and payment burden pass;
- Expected Loss rate passes;
- expected net contribution is positive;
- expected margin exceeds strategy minimum;
- no hard policy or concentration stop applies.

## 6.10 Portfolio allocation and concentration

True concentration management cannot be demonstrated solely by reporting concentration after every merchant has been “approved.”

Recommended design:

1. Establish a fixed `strategy_funding_budget`.
2. Calculate individually viable offers.
3. Rank viable offers deterministically under the active strategy objective.
4. Allocate exposure while monitoring:
   - industry caps;
   - channel/partner caps;
   - geography caps;
   - risk-tier caps;
   - new-business caps;
   - high-volatility caps;
   - stacking caps.
5. Reduce an offer to remaining capacity where feasible.
6. Route unresolved rows to review or decline.

This converts concentration limits into active portfolio strategy rather than decorative dashboard metrics.

---

## 6.11 First-pass risk-appetite framework

The following are synthetic starting points for baseline calibration, not industry benchmarks.

| Metric | Limit | Early warning | Breach action | Primary owner |
|---|---:|---:|---|---|
| Approved Expected Loss rate | ≤6% | 6%–7% | Tighten risk/exposure or price profile | Credit Risk |
| High-risk-tier exposure | ≤15% | 15%–18% | Reduce risk-tier caps | Credit Risk |
| Largest industry share | ≤20% | 20%–23% | Restrict further allocation | Portfolio Management |
| Largest partner/channel share | ≤25% | 25%–28% | Apply partner overlay | Portfolio/Product |
| High-volatility exposure | ≤12% | 12%–15% | Tighten stability haircut | Credit Risk |
| Stacking exposure | ≤5% | 5%–7% | Suspend stacked approvals | Credit Policy |
| Exposure with FOCR <1.15x | ≤5% | 5%–7% | Counteroffer or review | Underwriting |
| Policy exception rate | ≤3% | 3%–5% | Escalate and reduce delegation | Credit Policy |
| Manual-review rate | ≤15% | 15%–20% | Review rules and data quality | Operations |
| Expected margin rate | ≥8% | 6%–8% | Reprice or reduce acquisition cost | Finance/Pricing |
| Negative-contribution offers | 0% | Any positive count | Block offer generation | Finance/Credit |
| Top-10 merchant exposure | ≤5% | 5%–7% | Reduce individual exposure caps | Portfolio Management |

Every risk-appetite record should preserve:

```text
Limit
→ Early-Warning Threshold
→ Current Result
→ Status
→ Breach Indicator
→ Required Action
→ Owner
→ Review Date
```

---

## 7. Recommended scenario and strategy campaign

Do not run a full Cartesian product of every scenario and every strategy. Use three campaign layers.

## Module 1 merchant-environment scenarios

| ID | Scenario | Primary transmission |
|---|---|---|
| M1-S01 | Baseline merchant environment | Reference |
| M1-S02 | Recent sales decline | Revenue → capacity → burden → risk |
| M1-S03 | Volatility and zero-sales-day stress | Stability → haircuts → capacity/risk |
| M1-S04 | Refund and chargeback stress | Net eligible revenue and transaction quality |
| M1-S05 | Existing-debt and stacking stress | Obligations → FOCR → exposure/risk |
| M1-S06 | Industry/channel deterioration | Segment risk and concentration |

Funding-cost stress should ordinarily be a Module 2 economics environment because it changes offer economics, not the underlying merchant history.

## Module 2 strategy profiles

| ID | Strategy | Objective |
|---|---|---|
| M2-B01 | Balanced baseline | Balanced access, loss and margin |
| M2-G01 | Growth/access | Expand viable offers subject to minimum economics |
| M2-R01 | Loss containment | Reduce high-risk exposure and EL |
| M2-A01 | Affordability discipline | Tighten FOCR and payment burden |
| M2-C01 | Selective counteroffer | Preserve access through feasible restructuring |
| M2-P01 | Margin protection / price for risk | Protect contribution under cost pressure |
| M2-K01 | Concentration guardrail | Enforce industry and partner limits |

## Campaign design

### Layer A — Pure strategy frontier

Run all seven Module 2 strategies against M1 baseline.

**Runs: 7**

This isolates downstream strategy effects.

### Layer B — Environment sensitivity

Run the balanced baseline strategy against all six Module 1 scenarios.

**Runs: 6**

This isolates upstream merchant-environment effects.

### Layer C — Targeted scenario × strategy tests

| Environment | Target strategy |
|---|---|
| Sales decline | Affordability discipline |
| Volatility stress | Selective counteroffer |
| Refund/chargeback stress | Loss containment |
| Existing-debt/stacking stress | Loss containment |
| Industry/channel deterioration | Concentration guardrail |
| Funding-cost increase | Margin protection |

**Runs: 6**

### Total initial campaign

```text
7 + 6 + 6 = 19 runs
```

This is large enough to produce a meaningful strategy frontier without creating an unmanageable campaign.

### Comparison rules

- M1 scenario comparisons: hold strategy and population constant.
- M2 strategy comparisons: hold M1 scenario and population constant.
- Scenario × strategy frontier: may summarize all archived points, but must not conflate upstream environment effects with downstream policy effects.
- Matched row comparisons: use `merchant_application_id`.
- Timestamps and run IDs: audit metadata only, not match keys.

This follows the comparison discipline in your existing modules. The current architecture correctly treats latest output as replaceable and the archive as the governed comparison source. [export reference: filecite | turn4file15]

---

## 8. Principal risks of overbuilding

| Overbuild risk | Why it would weaken the project | Control |
|---|---|---|
| Supporting three legal products at once | Blurs mechanics, pricing and legal boundaries | Implement one closed-end product |
| Transaction-level POS generation | Creates enormous data volume with little incremental strategy value | Generate daily aggregates |
| Full financial-statement simulation | Produces false precision | Use documented cash-flow conversion assumptions |
| Dozens of low-value features | Reduces explainability and QA quality | Limit V1 to 30 field families |
| Machine learning in V1 | Distracts from strategy, economics and governance | Use transparent additive risk framework |
| Full account-performance lifecycle | Requires state transitions and time-series validation | Reserve for Module 3 |
| Continuous pricing optimizer | Implies precision unsupported by synthetic data | Use discrete price cards |
| Full candidate archive | Multiplies data volume unnecessarily | Keep candidates transient; archive final offer and diagnostics |
| Hard concentration allocation too early | Can obscure individual offer logic during development | Validate individual feasibility first, then add allocation |
| Full Cartesian campaign | Creates repeated outputs without clear management questions | Use the targeted 19-run campaign |
| Power BI before definitions stabilize | Produces denominator and grain problems | Build only after source acceptance |
| BRD length before design decisions | Repeats unresolved assumptions in polished prose | Lock decision records first |
| Copying consumer thresholds | Creates a superficial reskin | Rebuild burden, risk and economics from merchant cash flow |
| Overclaiming calibration or profitability | Undermines credibility | Preserve explicit synthetic boundaries |

The strongest lesson from the existing Validation Summary is that realism comes from governing edge behavior—not eliminating it—and that strong-looking synthetic outputs must remain within explicit non-production boundaries. [export reference: filecite | turn6file5]

---

## 9. Phased minimum viable build

## Phase 0 — Product and portfolio charter

**Deliverables**

- closed-end fixed-weekly product decision;
- target merchant definition;
- illustrative amount and term ranges;
- pricing convention;
- risk-appetite objectives;
- boundary statement.

**Acceptance gate**

One internally consistent product definition, with no mixed debt/receivables terminology.

## Phase 1 — BRD and logical architecture

**Deliverables**

- Module 1 and Module 2 objectives;
- architecture diagram;
- grains and keys;
- lineage model;
- scenario and strategy identity;
- latest/archive design;
- requirements traceability skeleton.

**Acceptance gate**

Every material requirement maps to a module, grain, output and validation test.

## Phase 2 — V1 data and parameter dictionaries

**Deliverables**

- 30 field families;
- valid ranges;
- expected direction;
- generation logic;
- downstream use;
- parameter catalog;
- reason-code catalog;
- risk-appetite catalog.

**Acceptance gate**

No field exists without a defined purpose, range and QA rule.

## Phase 3 — Module 1 baseline engine

**Build**

- 5,000 deterministic merchants;
- 365 days of daily POS history;
- six to eight industry groups;
- simplified deposit/liquidity proxy;
- as-of feature engineering;
- one requested closed-end loan;
- transparent risk proxy;
- schedule-derived EAD;
- LGD and EL;
- latest output and QA.

**Acceptance gate**

Stable population, complete history, no leakage, plausible distributions, coherent risk directions.

## Phase 4 — Module 1 scenario framework

**Build**

- six governed merchant-environment scenarios;
- archive persistence;
- matched scenario comparison;
- diagnostic evidence;
- scenario acceptance.

**Acceptance gate**

Merchant identity and intrinsic attributes match; only controlled scenario fields move.

## Phase 5 — Module 2 individual decision and economics engine

**Build**

- strategy and policy profiles;
- hard and soft policy flags;
- nine candidate offers;
- candidate burden and offer-specific risk;
- schedule-based economics;
- counteroffer selection;
- outcomes and reason codes;
- latest output and archive.

**Acceptance gate**

One exclusive outcome per merchant; all positive offers pass capacity, risk and contribution controls.

## Phase 6 — Portfolio allocation and campaign

**Build**

- funding budget;
- concentration limits;
- deterministic allocation;
- comparison registry;
- 19-run campaign;
- strategy frontier;
- persistent evidence;
- post-campaign acceptance.

**Acceptance gate**

All archived runs reconcile to registries, evidence, parameter snapshots and matched comparison keys.

## Phase 7 — Documentation and Power BI

**Deliverables**

- Module 1 BRD and Validation Summary;
- Module 2 BRD and Validation Summary;
- parameter and data dictionaries;
- boundaries document;
- README and artifact map;
- Power BI model;
- four report pages;
- source-to-report reconciliation;
- executive presentation.

**Acceptance gate**

Every material dashboard value reconciles to an accepted PostgreSQL output.

### Deliberately deferred

- sales-linked repayment;
- merchant cash advance or receivables-purchase treatment;
- calibrated PD;
- machine-learning challenger;
- account performance;
- renewals;
- time to default or payoff;
- detailed fair-lending analysis;
- production legal/compliance conclusions;
- dynamic price optimization.

---

## 10. Five decisions needed before the BRD and PostgreSQL design

1. **Repayment cadence:** Should V1 use fixed weekly ACH, as recommended, rather than daily ACH?

2. **Pricing form:** Should the illustrative product use a stated APR plus origination fee, as recommended, rather than a fixed finance charge or factor-rate convention?

3. **Target merchant universe:** Should V1 represent a diversified six-to-eight-industry portfolio with governed industry tiers and exclusions, or focus on one vertical such as restaurants or retail?

4. **Data scope:** Should V1 include 12 months of daily POS history plus a simplified deposit/liquidity proxy, as recommended, or POS history only?

5. **Concentration enforcement:** Should the first accepted Module 2 version allocate against a fixed funding budget and hard concentration caps, or initially report concentrations and add active allocation in the next release?

Absent a contrary decision, the recommended defaults above are sufficient to begin the BRD, enterprise architecture, data model, parameter dictionary, scenario register, and validation matrix.
<!-- END_SOURCE_MESSAGE -->


<a id="m-92127da5-afa6-481d-a557-f8d323cfc551"></a>
## Andrew / user · C068-M00003

C068-M00003 · 2026-07-23T13:16:19.124000-04:00 · active path

Preceding visible parent: [C068-M00002](part-01.md#m-b32cb8e3-6391-4f59-88ea-8b3b5c2eea7b)

**Editorial record note:** Attachment references: Ultimate-Guide-for-Banks-2024.pdf; Creating a successful risk management framework.pdf

<!-- BEGIN_SOURCE_MESSAGE -->
Attached are two white papers on the subject, including a highly relevant one from EXL Service, the employer for the Credit Risk Manager position I interviewed for today related to this subject. Before we move on with next steps, please review and adjust our direction, if necessary, and re-evaluate the last response in light of these white papers, especially EXL Services perspective.  We want to impress with swiftness, thoroughness, and quality in this effort.
<!-- END_SOURCE_MESSAGE -->
