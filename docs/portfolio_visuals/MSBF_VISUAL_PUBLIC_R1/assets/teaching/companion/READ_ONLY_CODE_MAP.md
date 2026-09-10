# Read-only driver, code and evidence map
## R7 masterclass / retained R6 technical explanation

This guide opens the implementation behind the lessons. It does not execute SQL, change a policy, run a profile simulation, connect to a database, or refresh Power BI. Source IDs resolve through `../source/SOURCE_IDENTITY_REGISTER.json`. Exact literal line matches are in `../source/CODE_LINE_LOCATORS.json`; retained basenames are not version authority by themselves.

## 1. Merchant evidence → derived features

| Lessons | Input / source | What to inspect | Decision connection |
|---|---|---|---|
| 02–03 | S01 requested-structure source; S02 as-of feature SQL | `avg_daily_eligible_sales_30d`, `sales_growth_30d_vs_90d`, `daily_sales_cv_90d`, `zero_sales_day_rate_30d`, `largest_30d_share_180d` | Sales level feeds cash generation and sales-linked obligations. Trend, variability and concentration feed resilience. |
| 04, 08–09 | S03 capacity SQL, lines 339–423; S04 binding record; S04a policy/schema | `_m1_10_capacity_independent`; industry margin; `requested_rate_based`, `requested_horizon_daily`, `operating_cash`, residual, projected buffer and independent tier | The maximum of two burden measures is compared with cash generation and liquidity. |
| 05 | S15 feature availability; S27 verification generation | `usable_pos_days`, `required_usable_days`, `disconnected_outage_days`, `value_status`; the six verification check families | Distinguish unusable evidence from a zero or an adverse observed value. |
| 06 | S05 resilience, S06 integrated risk, S07 loss, S08 economics | Component scores; independent tier; matched/floor logic; weighted EAD; LGD; non-loss costs; risk-capital charge | Risk and contribution are derived outputs, not raw data or production-calibrated default estimates. |

## 2. The exact capacity calculation, translated

For an assessable path, S03 applies the following source calculation. `round2` below means rounding to cents; `max(...,1)` is the source denominator safeguard. This is a translated formula map, not a new implementation or substitute for blocked-evidence handling.

```text
S = eligible daily sales over the required window
mu = industry operating-cash margin from the profile
C = round2(S * mu)
E = existing fixed payments + existing sales-linked daily commitments
T = rounded selected/requested total repayment
N = max(round2(S * remittance_rate), round2(T / horizon_days))
D = E + N
residual = C - D
projected_buffer = observed_average_balance + residual * 30
coverage = C / max(D, 1)
post_financing_buffer_days = projected_buffer / max(D, 1)
obligation_to_sales = D / max(S, 1)
```

Blocked or unavailable inputs retain their evidence treatment; do not turn SQL staging defaults into permission to assess missing sales. The source's industry margin is a policy assumption, not a measured merchant profit margin. The current liquidity proxy is derived from the balance evidence; the post-financing projection is a separate modeled quantity. The model does not simply add the advance proceeds to this buffer formula.

Tier 1 is more stringent than the strict-frontier maximum tier 2: coverage ≥1.50, burden ≤15%, buffer ≥30 days, nonnegative residual, and stacking <3. Tier 2 permits coverage ≥1.25, burden ≤22%, buffer ≥15 days and nonnegative residual. Tier 3 uses coverage ≥1.00, burden ≤30% and buffer ≥5 days. These composite gates, not one metric, explain the examples. Stacking means the count/depth of existing financing commitments in this source—not a categorical ban whenever it is at least three.

## 3. How raw sales become a resilience component

S05 lines 131–164 define several transparent components. Let `clip(x)=max(0,min(1,x))`. The following is a mathematical translation of the revenue expression, with the exact profile parameter names retained:

```text
G = clip((growth_30_vs_90 - revenue_growth_floor) / (0.10 - revenue_growth_floor))
V = clip((revenue_cv_max - daily_sales_cv_90d) /
         max(revenue_cv_max - revenue_cv_neutral, 0.000001))
Z = clip(1 - zero_sales_day_rate_30d / max(revenue_zero_sales_max, 0.000001))
K = clip((revenue_concentration_max - largest_30d_share_180d) /
         max(revenue_concentration_max - revenue_concentration_neutral, 0.000001))
revenue_score = round(100 * (0.40*G + 0.25*V + 0.20*Z + 0.15*K), 6)
```

This is why simply adding raw percentages is wrong. Each input first becomes a directionally consistent normalized score. Liquidity separately combines projected buffer, negative-balance frequency, NSF frequency and cash-flow buffer. Burden combines coverage, total-sales burden, nonnegative residual and stacking. Continuity combines outage frequency, degraded frequency and continuity risk tier. Source confidence/completeness supplies a separate data component. The profile weights then combine the five components. The archetype CASE has its own ordered tests (insufficient, thin, disrupted, declining, volatile, seasonal, growing, stable); an archetype is not interchangeable with the final integrated risk tier.

## 4. Risk, loss and contribution

S06's seven risk components are operating resilience, capacity/burden, liquidity, confidence, verification/fraud, processor continuity, and industry/relationship context. Inspect both weighted score and explicit floor rules; do not infer that a favorable component cancels a binding floor. S09 permits strict risk/resilience tiers up to 2 and review tiers up to 3.

S07 computes schedule-adjusted comparative loss from path-weighted exposure, the synthetic risk proxy and final LGD. LGD is the modeled loss share after recovery; path-weighted exposure reflects the modeled receivable over time. This is not a CECL estimate or a calibrated production PD.

S08 lines 488–599 build finance revenue and subtract processor, acquisition, funding, servicing and operating costs, comparative loss and the risk-capital charge. The latter is a separate modeled charge based on weighted exposure, capital and cost of capital over the term. The annualized modeled return is contribution / funded amount × 365 / horizon. The 18% hurdle in the selected source is not an APR or a promise of realized profit.

## 5. Request → candidates → final authority

| Artifact | Actual fields to read | What the learner should establish |
|---|---|---|
| S09 resolved policy | `minimum_counteroffer_ratio`, `exact_supported_horizons_days`, strict/review risk and resilience maxima, repayment-increase limits | Which changes are admissible before considering preference. |
| S10 gate export | `gate_code`, `remediability_class`, strict/review thresholds, `gate_status`, binding flags | Which condition failed and whether terms can repair it. |
| S11 human classification | `specific_verification_or_conflict_flag`, `human_review_required_flag`, `human_review_reason_codes`, `advisory_reason_codes` | Why MEDIUM confidence can bind review while processor WATCH can remain advisory. |
| S12 candidate export | `CandidateKey`, `funded_amount`, `remittance_rate`, `payback_multiple`, `horizon_days`, coverage/burden/buffer, `candidate_feasibility_status`, selected flags | Reproduce a comparison using actual source candidates, without manufacturing a search result. |
| S13 final export | `independent_outcome_code`, `governed_final_outcome_code`, selected candidate IDs, binding gates, `stress_floor_basis_code` | Why independent preference and the governed matched-scenario result can differ. |

A field named `funded_amount` in the candidate export is a candidate amount. It is not proof of actual funded membership. The 098 stress selection and 082 stress no-eligible result illustrate the matched-stress floor; neither is an M2.11 profile-driven change.

**Source limitation:** The R4 carrier supplies policy, candidate/final/gate outputs, and accepted method bindings, but not a separately packaged original R4 generator program. This casebook does not claim to independently reconstruct the whole candidate enumeration or every generator-internal tie-break. It teaches what is inspectable from the supplied source methods, policy and exact outputs. It does not infer a detailed hard-stop condition from the generic `R1_HARD_POLICY_STOP` flag alone.

## 6. Funded entry and the day-level key

Use S18 `R1FactFundedLifecycle.csv` for `ApplicationScenarioKey`, `AccountKey`, `AdvanceKey`, funding/activation dates and first expected remittance. Then use S19 for day-level monitoring. The complete 738 keys are:

```text
1|5|MSBF_POP_0001_M000738_A01   # Baseline; funded
1|6|MSBF_POP_0001_M000738_A01   # Recession Energy; not funded
```

Export basenames are not assumed PostgreSQL table names. Joining only on the merchant would corrupt the scenario boundary.

## 7. Literal R26 policy excerpt

The following three lines are copied from S16 `src/r26_policy.py`, lines 9–11. They are a dictionary fragment, not a standalone command:

```python
    'pace_watch_eligibility_day': 21,
    'pace_adverse_eligibility_day': 30,
    'pace_persistence_days': 3,
```

Read the **new_case** block, not the old_case string that the patch replaces. Lines 274–316 implement paid-off precedence, early hard signals, and three-day pace persistence. The operational-family block beginning at `WITH lagged AS` separately defines family flags and primary-family precedence. Three constants alone are not the entire model.

S17 retains the physical sales-based remittance ledger. R26 changes expected progress to selected repayment / selected horizon, with cumulative expectation capped at the repayment target. This changes interpretation, not the retained actual remittance cash path. A current low ratio is not enough: the correct eligible-day window, prior two ratios and other source status conditions matter.

## 8. Recommendation is narrower than the available evidence

S20's retained M2.6 source captures many contextual fields. Its actual branch uses paid-off status, latest status and an unpaid-path exposure rank. That is a deliberately transparent implementation, not a claim that every captured signal independently drives the route or that the selection was production-optimized. S25 preserves the accepted terminal-state treatment.

S21 tells what was recommended. S22 shows `setup_authorized_flag` and `operational_setup_outcome_code`. S23 shows `processing_authorized_flag`, `servicing_execution_outcome_code`, event counts and actual simulated processing. The three source review holds must not be relabeled executed outreach. No mandatory escalation staircase, automatic write-off, or automatic closure at horizon is inferred.

## 9. Reconcile events before reading the portfolio

S26 is the retained cent-rounding correction. S23 supplies scheduled, returned, retry and net processed amounts. S24 supplies `performance_tier_code`, `state_certified_flag`, exception flags and `certified_exposure_amount`. For 749, the net processing ledger is 1,762.25 − 251.75 + 251.75 = 1,762.25. Its remaining exposure is 2,937.12. The full Baseline certified exposure is 6,061.03, including 3,123.91 in review holds. A resolved exception is not a paid-off receivable.

## 10. Read-only capstone checks (educational pseudocode)

```text
identify the question's scenario and record grain
assert final keys are unique at application-scenario grain
assert every funded key is authorized
assert monitoring keys match the funded population
inspect the named policy gate before explaining a review or decline
reconcile net processing and remaining exposure at their source-owned stages
```

These statements express learning checks, not a runnable SQL or R26 orchestration path. G3-v2 certifies source consumption; Power BI presents source-owned facts. PUB-RUN-001, live repository integration, publication authority and Windows qualification remain separate workstreams.


## R7 provenance and source re-resolution

The R7 source registry re-resolves the R6 source families from the unchanged supplied archives. S04 is the exact accepted-method binding record; S04a separately carries the M1.10 schema/policy. The five core accepted method hashes match their recorded bindings. S28 adds the retained cohort scenario-metric table for cross-reference. This is not an assertion that the earlier R6 source-registry file itself was supplied or reconstructed byte-for-byte.

The displayed candidate fields, final outcome counts, funded membership, monitoring population, policy fragment and 749 execution/portfolio selections were compared read-only. The review report states the scope. None of the source SQL, strategy generators or run launchers was executed. Exact underlying private sources remain in their archived carriers; selected synthetic fields included here are review support, not a whole public source distribution.
