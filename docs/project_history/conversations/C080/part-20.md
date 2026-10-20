# Branch · Merchant POS Lending Simulator

Part 20 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-19.md)
[Next part](part-21.md)

<a id="m-b56d0923-2af9-4ba5-8c19-efcc7bd70bba"></a>
## Assistant · C080-M00544

C080-M00544 · 2026-08-04T23:40:44.422348-04:00 · active path

Preceding visible parent: [C080-M00543](part-19.md#m-a94f17aa-4a28-4799-ad16-1f0ff739cfbb)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.11 Source & Design Freeze Amendment A — **LOCKED**

The assessment is correct. The original freeze established the right architecture, but the remaining semantic gaps were material enough to justify a bounded amendment before SQL construction.

This amendment supersedes only the scoring, normalization, portfolio-rollup, Pareto, reason-code, stress-comparison, and contract-behavior sections identified below. Every other element of the original M2.11 freeze remains unchanged.

```text
Authoritative M2.10 baseline                         UNCHANGED
Accepted source hierarchy                            UNCHANGED
Stage and production boundaries                      UNCHANGED
Physical object grains                               UNCHANGED
Expected physical row counts                         UNCHANGED
Canonical entity count                            19,298
Programs 212–219                                      UNCHANGED
M2.12 final-certification handoff                     UNCHANGED
```

No SQL, package documentation, manifest, checksum inventory, or ZIP was generated in this step.

---

# A1. Physical representation of the weight matrix

The new strategy-weight semantics will **not** add a 64-row strategy/objective bridge table because that would alter the frozen object inventory and canonical count.

The existing eight-row:

```text
msbf_m2.portfolio_strategy_profile
```

will carry the matrix through explicit target-typed fields for:

- eight objective weights;
- selection mode;
- selected-exposure direction;
- candidate-scoring applicability;
- scope-scoring applicability;
- score weight total;
- evidence handling code;
- score precision;
- row hash.

The eight-row:

```text
msbf_m2.portfolio_strategy_objective_definition
```

will carry the stable objective semantics:

- raw-value formula code;
- default optimization direction;
- normalization method;
- missing-value policy;
- scoring domain;
- scope-aggregation method;
- Pareto-inclusion flag;
- equality tolerance;
- numeric scale.

Weights will not exist only inside an opaque JSON document. Any JSON payload will be a reporting representation of explicit physical fields.

The frozen canonical count therefore remains:

```text
19,298
```

---

# A2. Exact objective definitions

## Objective formulas

| Objective | Application/candidate raw value | Scope-level raw value | Stable direction | Pareto |
|---|---|---|---:|---:|
| `ACCESS_RATE` | `1` for a selected access candidate; `0` for implicit no-access | Access-selected application rows ÷ total application rows in scope | Maximize | Yes |
| `SELECTED_EXPOSURE_AMOUNT` | Candidate funding amount; zero for no-access | Sum of selected funding amount | Strategy-specific | **No** |
| `FINANCE_CHARGE_AMOUNT` | Candidate finance-charge amount; zero for no-access | Sum of selected finance-charge amount | Maximize | Yes |
| `EXPECTED_LOSS_DENSITY` | Candidate expected loss ÷ candidate funding amount | Sum expected loss ÷ sum selected exposure | Minimize | Yes |
| `RISK_ADJUSTED_CONTRIBUTION` | Candidate risk-adjusted contribution; zero for no-access | Sum risk-adjusted contribution | Maximize | Yes |
| `ANNUALIZED_RISK_ADJUSTED_RETURN` | Candidate annualized return; zero for no-access | Selected-exposure-weighted annualized return | Maximize | Yes |
| `SERVICING_BURDEN_UNITS` | Not used in candidate ranking | Sum of selected account-servicing burden units | Minimize | Yes |
| `PAYMENT_BURDEN_RATE` | Candidate remittance rate; zero for no-access | Selected-exposure-weighted remittance rate | Minimize | Yes |

## Exact access-rate denominator

For every reporting scope:

```text
Access Rate
=
Access-selected application rows
÷
Total application rows in the scope
```

The denominator includes:

- access selections;
- controlled reviews;
- strategy restrictions;
- insufficient-evidence outcomes;
- policy declines;
- blocked rows.

It does not use only the eligible population.

Expected scope denominators:

```text
BASELINE            750
RECESSION_ENERGY    750
PORTFOLIO           750
```

## Expected-loss density

```text
Candidate Expected-Loss Density
=
candidate_expected_loss_amount
÷
candidate_funding_amount
```

```text
Scope Expected-Loss Density
=
sum(selected_expected_loss_amount)
÷
sum(selected_funding_amount)
```

If selected exposure is zero, the scope metric is `NULL`, not zero, and the strategy is not Pareto-eligible for that scope.

## Annualized-return aggregation

```text
Scope Annualized Return
=
sum(selected_funding_amount × annualized_return_rate)
÷
sum(selected_funding_amount)
```

If selected exposure is zero, the scope annualized return is `NULL`.

## Payment-burden aggregation

```text
Scope Payment-Burden Rate
=
sum(selected_funding_amount × selected_remittance_rate)
÷
sum(selected_funding_amount)
```

If selected exposure is zero, the scope payment-burden rate is `NULL`.

---

# A3. Exact strategy-weight matrix

Legend:

```text
↑  maximize
↓  minimize
—  weight zero / not used in that strategy’s weighted score
```

| Strategy | Selection mode | Access ↑ | Exposure | Finance charge ↑ | Loss density ↓ | Contribution ↑ | Return ↑ | Servicing burden ↓ | Payment burden ↓ |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| `BASELINE_REPLAY` | `SOURCE_REPLAY` | — | — | — | — | — | — | — | — |
| `ACCESS_EXPANSION` | `WEIGHTED_CANDIDATE` | **0.450000** | **0.150000 ↑** | 0.050000 | 0.100000 | 0.100000 | 0.050000 | — | 0.100000 |
| `PRICE_FOR_RISK` | `WEIGHTED_CANDIDATE` | 0.100000 | 0.050000 ↑ | **0.300000** | 0.150000 | 0.200000 | 0.100000 | — | 0.100000 |
| `PAYMENT_BURDEN_RELIEF` | `WEIGHTED_CANDIDATE` | 0.150000 | 0.100000 ↓ | 0.050000 | 0.100000 | 0.100000 | 0.050000 | — | **0.450000** |
| `LOSS_CONTAINMENT` | `WEIGHTED_CANDIDATE` | 0.050000 | 0.250000 ↓ | — | **0.400000** | 0.100000 | 0.050000 | — | 0.150000 |
| `PROFITABILITY_DISCIPLINE` | `WEIGHTED_CANDIDATE` | 0.050000 | 0.050000 ↑ | 0.150000 | 0.150000 | **0.350000** | **0.200000** | — | 0.050000 |
| `EARLY_INTERVENTION` | `RULE_BASED_ACCOUNT` | — | — | — | — | — | — | **0.600000** | **0.400000** |
| `BALANCED_FRONTIER` | `WEIGHTED_CANDIDATE` | 0.200000 | 0.050000 ↑ | 0.100000 | 0.200000 | **0.200000** | 0.100000 | 0.100000 | 0.050000 |

Frozen weight requirements:

```text
ACCESS_EXPANSION total                    1.000000
PRICE_FOR_RISK total                      1.000000
PAYMENT_BURDEN_RELIEF total               1.000000
LOSS_CONTAINMENT total                    1.000000
PROFITABILITY_DISCIPLINE total            1.000000
EARLY_INTERVENTION scope total            1.000000
BALANCED_FRONTIER total                   1.000000
BASELINE_REPLAY total                     0.000000
```

## Candidate-ranking treatment of servicing burden

`SERVICING_BURDEN_UNITS` is not available at the M2.2 candidate grain and will not be fabricated.

Therefore:

- the candidate-selection score excludes servicing burden;
- `BALANCED_FRONTIER` candidate selection renormalizes its remaining application-objective weights from `0.900000` to `1.000000`;
- its full eight-objective matrix is used only for the scope-level evaluation score;
- all other weighted candidate strategies already have candidate-domain weights totaling `1.000000`.

## Baseline and early-intervention exceptions

`BASELINE_REPLAY` never uses a score to choose a candidate.

`EARLY_INTERVENTION` replays the baseline application structure and access outcome. Its weights are used only to evaluate the resulting scope-level workload and payment-burden posture.

---

# A4. Exact normalization and scoring mechanics

## Candidate-selection normalization population

Normalization occurs within:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
+ strategy_profile_code
```

The normalization population contains:

1. M2.2 candidates that pass source-integrity checks;
2. candidates that pass the strategy’s hard constraints;
3. the deterministic implicit no-access alternative.

The implicit no-access alternative is evaluated in Program 214 temporary logic but is **not** added to the persisted 4,456-row candidate-evaluation table. The frozen count remains:

```text
557 accepted candidate rows × 8 strategies = 4,456
```

## Maximize transformation

```text
normalized_value
=
(raw_value − minimum_value)
÷
(maximum_value − minimum_value)
```

## Minimize transformation

```text
normalized_value
=
(maximum_value − raw_value)
÷
(maximum_value − minimum_value)
```

## Constant population

When:

```text
maximum_value = minimum_value
```

every non-null alternative receives:

```text
normalized_value = 1.0000000000
```

The objective then has no ranking power, and deterministic tie-breaking decides.

## Domain-adjusted weighted score

```text
Candidate Objective Score
=
sum(normalized_value × strategy_weight)
÷
sum(applicable candidate-domain strategy weights)
```

For `BALANCED_FRONTIER` candidate selection:

```text
denominator = 0.900000
```

because its `0.100000` servicing-burden weight is scope-only.

## Scope strategy score

Scope values are normalized across all eight strategy profiles within:

```text
module1_run_id
+ reporting_scope_code
```

The full strategy weight row is then applied.

`BASELINE_REPLAY` receives no strategy score. It remains the control comparator.

## Missing and blocked evidence

No objective value will be imputed from an average, median, floor, ceiling, or other strategy.

| Condition | Frozen treatment |
|---|---|
| Structural field absent, such as amount, remittance, or finance charge | `BLOCKED_SOURCE_INTEGRITY` |
| Expected loss, contribution, or return required by a positive weight but null | `INFEASIBLE_OBJECTIVE_EVIDENCE` |
| Upstream evidence `BLOCKED` | Candidate may not be selected |
| Upstream evidence `PARTIAL`, but objective values physically exist | Candidate may be scored; evidence remains `PARTIAL` |
| Objective weight is zero or objective is outside evaluation domain | `NOT_APPLICABLE`; omitted from denominator |
| Scope metric required by a positive weight is null | Scope score becomes null; strategy is frontier-ineligible |
| Unknown amount | Remains null; never converted to zero |

`PARTIAL` evidence receives no concealed numerical haircut. The evidence status remains visible and participates in governance-priority ordering.

## Numeric precision

```text
Strategy weight                numeric(9,6)
Raw scoring value              numeric(28,10)
Minimum / maximum              numeric(28,10)
Normalized value               numeric(18,10)
Weighted contribution          numeric(22,12)
Total objective score          numeric(22,12)
Scope balance score            numeric(22,12)
```

All arithmetic uses PostgreSQL `numeric`, never floating-point types.

Rounding occurs only at the following points:

```text
normalized value       round(..., 10)
weighted contribution  round(..., 12)
total score             round(sum(...), 12)
```

PostgreSQL numeric rounding semantics apply.

## Candidate-score equality

Two objective scores are tied when their persisted 12-decimal values are identical or differ by no more than:

```text
0.000000000001
```

The frozen deterministic tie-break remains:

```text
1. Lowest hard-constraint violation count
2. Best feasibility rank
3. Highest 12-decimal objective score
4. Accepted M2.2 candidate rank
5. Candidate template code
6. Accepted M2.2 candidate row hash
```

Database row order is prohibited as a tie-break.

---

# A5. Exact selected-exposure treatment

The recommended option **B** is adopted.

```text
SELECTED_EXPOSURE_AMOUNT
```

is:

- visible in every candidate, strategy, comparison, and contract output;
- available for strategy-specific weighted scoring;
- available for baseline deltas;
- available for worst-case portfolio ordering;
- **excluded from Pareto dominance**.

Rationale:

```text
Higher exposure supports access and revenue.
Lower exposure supports loss and burden containment.
Neither direction is universally superior across strategies.
```

No strategy can obtain Pareto superiority solely by increasing or decreasing exposure.

---

# A6. Exact feasibility classes

Lower rank is better.

| Rank | Feasibility class | Meaning |
|---:|---|---|
| 1 | `FEASIBLE_ACCESS` | Candidate satisfies all constraints and strategy permits synthetic access |
| 2 | `FEASIBLE_CONTROLLED_REVIEW` | Candidate is analytically viable but source route, evidence, or economics requires review |
| 3 | `FEASIBLE_NO_ACCESS` | Deterministic no-access alternative |
| 4 | `INFEASIBLE_OBJECTIVE_EVIDENCE` | A positively weighted required objective is missing or blocked |
| 5 | `INFEASIBLE_HARD_CONSTRAINT` | One or more hard constraints fail |
| 6 | `PRESERVED_INSUFFICIENT_EVIDENCE` | M2.2 no-structure insufficient-evidence outcome preserved |
| 7 | `PRESERVED_POLICY_DECLINE` | M2.2 policy-decline outcome preserved |
| 8 | `BLOCKED_SOURCE_INTEGRITY` | Source count, grain, lineage, identity, or accepted-candidate inconsistency |

Infeasible candidates remain in the 4,456-row evaluation table with:

```text
objective_score = NULL
candidate_selected_flag = false
```

They are not silently dropped.

---

# A7. Exact strategy-outcome severity order

Lower rank is better. Higher rank is selected by the `PORTFOLIO` worst-case rollup.

| Rank | Strategy outcome |
|---:|---|
| 1 | `ACCESS_SELECTED` |
| 2 | `CONTROLLED_REVIEW` |
| 3 | `NO_ACCESS_STRATEGY_RESTRICTION` |
| 4 | `NO_ACCESS_NO_FEASIBLE_CANDIDATE` |
| 5 | `NO_ACCESS_INSUFFICIENT_EVIDENCE` |
| 6 | `NO_ACCESS_POLICY_DECLINE` |
| 7 | `BLOCKED_SOURCE_INTEGRITY` |

A policy decline is not interpreted as a data-integrity defect. A source-integrity block remains the most severe outcome because the strategy result cannot be relied upon.

---

# A8. Exact baseline-replay contract

`BASELINE_REPLAY` must reproduce the accepted source at two levels.

## M2.2 structure fields

The following must reproduce exactly for all 1,500 scenario/application rows:

```text
pricing_disposition_code
structure_available_flag
review_required_flag
selected_candidate_template_code
selected_candidate_row_hash
requested_funding_amount
selected_funding_amount
selected_remittance_rate
selected_payback_multiple
selected_collection_horizon_days
selected_total_repayment_amount
selected_finance_charge_amount
selected_implied_daily_collection_amount
selected_implied_payoff_days
selected_amount_to_request_ratio
candidate_count
counteroffer_foundation_flag
stress_nonimprovement_applied_flag
routing_evidence_status
```

Where a structure exists, the selected candidate must match one accepted:

```text
msbf_m2.application_pricing_structure_candidate
```

row on:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
+ candidate_template_code
```

and its accepted candidate row hash.

## M2.4 final activation fields

The following must also reproduce exactly:

```text
source_final_decision_outcome_code
activation_outcome_code
activation_outcome_rank
booking_eligible_flag
booking_authorized_flag
funding_authorized_flag
funding_completed_flag
portfolio_activated_flag
operational_review_required_flag
synthetic_offer_acceptance_assumed_flag
synthetic_account_id
synthetic_advance_id
booked_amount
funded_amount
activation_remittance_rate
activation_payback_multiple
activation_collection_horizon_days
activation_total_repayment_amount
activation_finance_charge_amount
activation_implied_daily_collection_amount
activation_implied_payoff_days
activation_evidence_status
```

## Operational account replay

For the 59 M2.10 account rows, baseline replay must preserve:

```text
M2.7 operational setup outcome
M2.7 operational setup action
M2.7 payment factor
M2.7 setup duration
M2.7 reassessment interval and date
M2.10 certified state
M2.10 performance tier
M2.10 servicing queue
M2.10 certified exposure
M2.10 servicing burden units
M2.10 payment and exception posture
```

Baseline-replay acceptance requires:

```text
Application replay mismatches      0 of 1,500
Account replay mismatches          0 of 59
```

No tolerance is applied to source hashes, categorical fields, flags, dates, or currency values.

---

# A9. Applications without accepted M2.2 candidates

The treatment is now exact.

| M2.2 source condition | M2.11 treatment |
|---|---|
| `NO_STRUCTURE_POLICY_DECLINE` | Preserve `NO_ACCESS_POLICY_DECLINE` for every strategy |
| `NO_STRUCTURE_INSUFFICIENT_EVIDENCE` | Preserve `NO_ACCESS_INSUFFICIENT_EVIDENCE` for every strategy |
| Structure available and candidate rows present | Evaluate accepted candidates |
| Structure available but expected candidate rows absent | `BLOCKED_SOURCE_INTEGRITY` |
| Selected M2.2 candidate absent from accepted candidate inventory | `BLOCKED_SOURCE_INTEGRITY` |
| Candidates exist but none passes M2.11 constraints | `NO_ACCESS_NO_FEASIBLE_CANDIDATE` |
| Strategy deliberately chooses the implicit no-access option | `NO_ACCESS_STRATEGY_RESTRICTION` |

M2.11 does not synthesize a new candidate for an application with no accepted M2.2 candidate.

The implicit no-access alternative is a strategy fallback, not a fabricated offer row.

---

# A10. Profitability-evidence requirements

The M1.15 contract legitimately contains `PARTIAL` and `BLOCKED` evidence states. M2.11 will not incorrectly require an upstream `COMPLETE` status that the accepted population does not provide.

## Economics-supported candidate

A candidate has supported economics only when:

```text
candidate_eligible_flag = true

expected_loss_amount is not null
risk_adjusted_contribution_amount is not null
annualized_return_rate is not null
candidate_finance_charge_amount is not null

m1_15_contract_evidence_status <> 'BLOCKED'
acquisition_contract_evidence_status <> 'BLOCKED'
economic_status <> 'INSUFFICIENT_EVIDENCE'
```

## Economic treatment

| Accepted economic status | Challenger treatment |
|---|---|
| `ABOVE_HURDLE` | May be `FEASIBLE_ACCESS` if all other constraints pass |
| `BELOW_HURDLE` | At most `FEASIBLE_CONTROLLED_REVIEW` |
| `NEGATIVE_CONTRIBUTION` | `INFEASIBLE_HARD_CONSTRAINT` |
| `INSUFFICIENT_EVIDENCE` | `INFEASIBLE_OBJECTIVE_EVIDENCE` |

Additionally, no challenger may receive `ACCESS_SELECTED` when:

```text
risk_adjusted_contribution_amount < 0
OR
annualized_return_rate < 0
```

## Manual-review route treatment

A candidate originating from:

```text
source_route_code = 'MANUAL_REVIEW'
```

normally remains:

```text
CONTROLLED_REVIEW
```

The sole exception is `ACCESS_EXPANSION`, which may produce synthetic access only when all are true:

```text
candidate_eligible_flag = true
counteroffer_foundation_flag = true
hard_constraint_violation_count = 0
economic_status = 'ABOVE_HURDLE'
risk_adjusted_contribution_amount >= 0
annualized_return_rate >= 0
upstream evidence is not BLOCKED
unresolved_exception_count = 0
```

This is a counterfactual strategy result, not a production authorization.

---

# A11. Exact EARLY_INTERVENTION semantics

`EARLY_INTERVENTION` is now explicitly a **timing-only** strategy. It does not invent a new payment factor, exposure amount, price, or expected-loss benefit.

Its application structure, access outcome, exposure, finance charge, loss, contribution, and return replay `BASELINE_REPLAY`.

## Account treatment

### Closed-stable account

```text
No intervention
No new review date
No burden increment
No payment-factor change
```

### Active-reconciled account

```text
Treatment code
EARLY_REASSESSMENT_SIMULATION

Simulated reassessment date
greatest(
    source_operational_activation_date + 1 day,
    source_next_reassessment_date − 4 days
)

Payment factor
Unchanged from accepted M2.7

Exposure
Unchanged

Incremental servicing burden
+1.000000 unit
```

### Controlled-review account

```text
Treatment code
ACCELERATED_GOVERNANCE_REVIEW_SIMULATION

Simulated review due date
coalesce(
    source_operational_activation_date,
    governed run as_of_date
) + 1 day

Payment factor
Unchanged

Exposure
Unchanged

Incremental servicing burden
+1.000000 unit
```

Given the current accepted M2.10 posture of:

```text
57 closed stable
1 active reconciled
1 controlled review
```

the timing-only strategy would add:

```text
2.000000 servicing burden units
```

while making no claim of reduced default risk, improved return, higher contribution, or improved payment performance.

This intentionally demonstrates that proactive intervention has an observable operating cost even when the project does not yet contain empirical treatment-effect evidence.

---

# A12. Exact PORTFOLIO worst-case selection

The `PORTFOLIO` scope selects exactly one scenario row per:

```text
merchant_application_id
+ strategy_profile_code
```

using this frozen descending adversity order:

```text
1. Highest hard-constraint violation count

2. Worst strategy-outcome severity rank

3. Worst evidence rank:
      BLOCKED = 3
      PARTIAL = 2
      COMPLETE = 1

4. Highest expected-loss density
      NULL sorts as worst

5. Lowest risk-adjusted contribution
      NULL sorts as worst

6. Lowest annualized risk-adjusted return
      NULL sorts as worst

7. Highest payment-burden rate
      NULL sorts as worst

8. Highest servicing-burden units
      NULL sorts as worst

9. Scenario priority:
      RECESSION_ENERGY before BASELINE

10. Physical application-strategy row hash,
       ascending lexical order
```

The rollup is not an average and does not sum scenarios.

It preserves:

```text
750 distinct applications per strategy
```

for scope aggregation.

The scenario code is a final business tie-break before the row hash, ensuring that a completely equivalent stress record is selected over baseline.

---

# A13. Exact Pareto-dominance model

## Frontier objectives

Seven objectives participate:

```text
ACCESS_RATE                          maximize
FINANCE_CHARGE_AMOUNT                maximize
EXPECTED_LOSS_DENSITY                minimize
RISK_ADJUSTED_CONTRIBUTION           maximize
ANNUALIZED_RISK_ADJUSTED_RETURN      maximize
SERVICING_BURDEN_UNITS               minimize
PAYMENT_BURDEN_RATE                  minimize
```

Excluded:

```text
SELECTED_EXPOSURE_AMOUNT
```

## Frontier eligibility

A strategy/scope row is frontier-eligible only when:

```text
hard_constraint_violation_count = 0
strategy_evidence_status <> 'BLOCKED'
all seven frontier objective values are non-null
stress_improvement_violation_count = 0
```

A frontier-ineligible strategy remains visible but receives no frontier rank.

## Equality tolerances

| Objective | Equality/no-worse tolerance |
|---|---:|
| `ACCESS_RATE` | `0.00000001` |
| `FINANCE_CHARGE_AMOUNT` | `$0.01` |
| `EXPECTED_LOSS_DENSITY` | `0.00000001` |
| `RISK_ADJUSTED_CONTRIBUTION` | `$0.01` |
| `ANNUALIZED_RISK_ADJUSTED_RETURN` | `0.00000001` |
| `SERVICING_BURDEN_UNITS` | `0.000001` |
| `PAYMENT_BURDEN_RATE` | `0.00000001` |

## Dominance test

Strategy A dominates Strategy B when:

1. A is no worse than B on all seven frontier objectives after tolerance; and
2. A is strictly better than B beyond tolerance on at least one objective.

If all differences are within tolerance, neither strategy dominates the other.

## Frontier rank

Iterative non-dominated sorting is frozen:

```text
Rank 1
All non-dominated strategies in the full eligible set.

Rank 2
Non-dominated strategies after Rank 1 is removed.

Rank 3+
Repeat until every eligible strategy has a rank.
```

More than one strategy may receive the same frontier rank.

Strategy code is used only for deterministic display order. It does not alter frontier rank.

---

# A14. Governance-review priority

A frontier position does not constitute deployment approval.

## Primary priority count

Exactly:

```text
zero or one PRIMARY_GOVERNANCE_REVIEW strategy per scope
```

is permitted.

Multiple Rank 1 strategies may receive:

```text
SECONDARY_FRONTIER_REVIEW
```

in the same scope.

`BASELINE_REPLAY` is never assigned challenger priority. It remains:

```text
CONTROL_REFERENCE
```

## Governance balance score

For review ordering only, the seven Pareto objectives are normalized across all frontier-eligible strategies in the scope.

Each receives equal weight:

```text
1 ÷ 7
```

```text
Governance Balance Score
=
mean(
    normalized access benefit,
    normalized finance-charge benefit,
    normalized loss-density benefit,
    normalized contribution benefit,
    normalized return benefit,
    normalized servicing-burden benefit,
    normalized payment-burden benefit
)
```

This score:

- does not select application candidates;
- does not determine Pareto dominance;
- does not override constraints;
- does not authorize deployment.

## Primary-priority prerequisites

A challenger must have:

```text
frontier_rank = 1
hard_constraint_violation_count = 0
strategy_evidence_status in ('COMPLETE','PARTIAL')
stress_improvement_violation_count = 0
all seven frontier metrics present
```

## Primary-priority ordering

```text
1. Better evidence rank:
      COMPLETE before PARTIAL

2. Higher governance balance score

3. Higher risk-adjusted contribution delta versus baseline

4. Lower expected-loss-density delta versus baseline

5. Higher access-rate delta versus baseline

6. Lower payment-burden delta versus baseline

7. Lower servicing-burden delta versus baseline

8. Strategy profile code, ascending
```

If no challenger satisfies the prerequisites, the scope receives no primary governance priority.

A strategy may receive primary priority in more than one scope, but no scope may have more than one primary strategy.

---

# A15. Stress non-improvement — exact interpretation

The amendment formally separates:

```text
SOURCE IMPROVEMENT
STRATEGY RESTRICTION
ABSOLUTE WORKLOAD REDUCTION
```

They are not interchangeable.

## Source non-improvement metrics

For each matched application, stress cannot improve these accepted source measures beyond tolerance:

```text
integrated_risk_score                         lower is better
synthetic_merchant_risk_proxy                lower is better

source_expected_loss_density
=
schedule_adjusted_comparative_expected_loss_amount
÷
path_weighted_ead_amount                     lower is better

annualized_risk_adjusted_return_rate          higher is better
```

A source-improvement violation exists when stress shows:

```text
lower integrated risk
OR
lower merchant risk proxy
OR
lower source loss density
OR
higher source annualized return
```

beyond `0.00000001`.

## Strategy access and feasibility

Stress cannot have a better:

```text
strategy_outcome_rank
feasibility_rank
```

than baseline for the same application and strategy.

A numerically lower rank under stress is a violation.

## Comparable-treatment burden test

Payment and servicing burden are compared for non-improvement only when treatment is comparable.

Treatment is comparable when both scenarios have:

```text
the same strategy outcome code
AND
the same selected candidate template code
AND
selected funding amounts equal within $0.01
AND
the same servicing treatment code
```

Under comparable treatment:

```text
stress payment burden < baseline payment burden
```

or:

```text
stress servicing burden < baseline servicing burden
```

beyond tolerance is an improvement violation.

## Strategy restriction

When stress produces:

- a worse access outcome;
- a worse feasibility class;
- lower selected exposure;
- a more conservative candidate;
- no access where baseline had access;

then lower exposure, lower payment burden, lower finance charge, higher selected-candidate return, or lower total workload is classified as:

```text
STRATEGY_RESTRICTION
```

It is not classified as favorable source performance.

## Absolute workload reduction

The following remains visible:

```text
stress total servicing burden
−
baseline total servicing burden
```

A negative value may result because fewer accounts receive access or review under stress.

That reduction:

- is reported;
- is not hidden;
- is not called a source improvement;
- does not fail stress non-improvement when caused by a worse access outcome.

## Frozen stress flags

Every matched comparison will carry:

```text
source_risk_improvement_violation_flag
source_return_improvement_violation_flag
strategy_access_improvement_violation_flag
strategy_feasibility_improvement_violation_flag
comparable_payment_burden_improvement_violation_flag
comparable_servicing_burden_improvement_violation_flag

strategy_restriction_flag
absolute_workload_reduction_flag
stress_nonimprovement_pass_flag
```

`stress_nonimprovement_pass_flag` is true only when all six violation flags are false.

---

# A16. Exact 32-reason catalog

Every reason definition will carry:

```text
reason_code
reason_family
severity_code
severity_rank
applicability_code
description
production_action_flag = false
external_system_update_flag = false
merchant_contact_flag = false
production_adverse_action_flag = false
```

Severity hierarchy:

```text
INFO           1
REVIEW         2
ACCESS_BLOCK   3
SYSTEM_BLOCK   4
```

## Source and evidence reasons

| # | Reason code | Severity | Applicability |
|---:|---|---|---|
| 1 | `M2_11_REASON_SOURCE_CONTRACTS_VERIFIED` | `INFO` | `ALL` |
| 2 | `M2_11_REASON_BASELINE_REPLAY_MATCH` | `INFO` | `APPLICATION_ACCOUNT` |
| 3 | `M2_11_REASON_SOURCE_EVIDENCE_PARTIAL` | `REVIEW` | `CANDIDATE_APPLICATION` |
| 4 | `M2_11_REASON_SOURCE_EVIDENCE_BLOCKED` | `SYSTEM_BLOCK` | `ALL` |
| 5 | `M2_11_REASON_SOURCE_GRAIN_OR_LINEAGE_ERROR` | `SYSTEM_BLOCK` | `ALL` |

## Constraint and feasibility reasons

| # | Reason code | Severity | Applicability |
|---:|---|---|---|
| 6 | `M2_11_REASON_POLICY_DECLINE_PRESERVED` | `ACCESS_BLOCK` | `APPLICATION` |
| 7 | `M2_11_REASON_INSUFFICIENT_EVIDENCE_PRESERVED` | `ACCESS_BLOCK` | `APPLICATION` |
| 8 | `M2_11_REASON_CANDIDATE_NOT_ELIGIBLE` | `ACCESS_BLOCK` | `CANDIDATE` |
| 9 | `M2_11_REASON_STRUCTURE_BOUND_VIOLATION` | `ACCESS_BLOCK` | `CANDIDATE` |
| 10 | `M2_11_REASON_AFFORDABILITY_CONSTRAINT` | `ACCESS_BLOCK` | `CANDIDATE` |
| 11 | `M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED` | `ACCESS_BLOCK` | `CANDIDATE` |
| 12 | `M2_11_REASON_NEGATIVE_CONTRIBUTION` | `ACCESS_BLOCK` | `CANDIDATE` |
| 13 | `M2_11_REASON_BELOW_HURDLE_REVIEW` | `REVIEW` | `CANDIDATE_APPLICATION` |
| 14 | `M2_11_REASON_UNRESOLVED_EXCEPTION` | `ACCESS_BLOCK` | `APPLICATION_ACCOUNT` |
| 15 | `M2_11_REASON_CLOSED_STATE_PRESERVED` | `INFO` | `ACCOUNT` |

## Strategy-selection reasons

| # | Reason code | Severity | Applicability |
|---:|---|---|---|
| 16 | `M2_11_REASON_ACCESS_EXPANSION_SELECTED` | `INFO` | `APPLICATION` |
| 17 | `M2_11_REASON_PRICE_FOR_RISK_SELECTED` | `INFO` | `APPLICATION` |
| 18 | `M2_11_REASON_PAYMENT_BURDEN_RELIEF_SELECTED` | `INFO` | `APPLICATION` |
| 19 | `M2_11_REASON_LOSS_CONTAINMENT_SELECTED` | `INFO` | `APPLICATION` |
| 20 | `M2_11_REASON_PROFITABILITY_DISCIPLINE_SELECTED` | `INFO` | `APPLICATION` |
| 21 | `M2_11_REASON_EARLY_INTERVENTION_SIMULATED` | `REVIEW` | `ACCOUNT` |
| 22 | `M2_11_REASON_BALANCED_FRONTIER_SELECTED` | `INFO` | `APPLICATION` |
| 23 | `M2_11_REASON_NO_ACCESS_STRATEGY_RESTRICTION` | `INFO` | `APPLICATION` |
| 24 | `M2_11_REASON_CONTROLLED_REVIEW_REQUIRED` | `REVIEW` | `APPLICATION_ACCOUNT` |
| 25 | `M2_11_REASON_DETERMINISTIC_TIE_BREAK_APPLIED` | `INFO` | `CANDIDATE_APPLICATION` |
| 26 | `M2_11_REASON_NO_FEASIBLE_CANDIDATE` | `ACCESS_BLOCK` | `APPLICATION` |

## Stress, frontier, and governance reasons

| # | Reason code | Severity | Applicability |
|---:|---|---|---|
| 27 | `M2_11_REASON_STRESS_SOURCE_NONIMPROVEMENT_PASS` | `INFO` | `COMPARISON` |
| 28 | `M2_11_REASON_STRESS_STRATEGY_RESTRICTION` | `INFO` | `COMPARISON` |
| 29 | `M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION` | `SYSTEM_BLOCK` | `COMPARISON` |
| 30 | `M2_11_REASON_NONDOMINATED_FRONTIER` | `INFO` | `FRONTIER` |
| 31 | `M2_11_REASON_DOMINATED_STRATEGY` | `INFO` | `FRONTIER` |
| 32 | `M2_11_REASON_GOVERNANCE_REVIEW_PRIORITY` | `REVIEW` | `FRONTIER` |

The count remains exactly:

```text
32
```

No future reason may be inserted ad hoc during Program 214. A new reason would require a freeze amendment.

---

# A17. Contract version and archive behavior

The frozen M2.11 consumption identity remains:

```text
M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION
Contract version 1
M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1
```

## Latest and archive grain

```text
module1_run_id
+ contract_version
+ strategy_profile_code
+ reporting_scope_code
```

Expected rows:

```text
Latest     24
Archive    24
```

## Archive immutability

A database-level:

```text
BEFORE UPDATE OR DELETE
```

row trigger will reject every archive mutation with an exception.

The archive will not use:

```text
ON CONFLICT DO UPDATE
```

Generation will insert each version exactly once.

## Exact reproduction

For every latest row:

```text
archive.contract_row_hash
=
latest.contract_row_hash
```

and:

```text
archive.contract_payload
=
to_jsonb(latest) excluding reporting-only created timestamp
```

The archive row hash will be based on:

- contract payload;
- source latest row hash;
- archive identity;
- contract version.

## Lifecycle behavior

Program 214 creates the version-1 latest and archive rows and sets:

```text
contract_status = GENERATED
run_status      = M2_11_GENERATED
```

Programs 215 and 217 may update only mutable registry lifecycle fields and timestamps.

They may not update:

- latest business values;
- latest contract hashes;
- archive payloads;
- archive hashes.

## Rerun behavior

A committed Program 214 cannot be rerun for contract version 1.

A future methodology change requires:

```text
new methodology version
+ new contract version
+ new source/design freeze
```

It may not overwrite the accepted version-1 archive.

---

# A18. Final amended freeze status

```text
Authoritative M2.10 baseline                    LOCKED
Five-source hierarchy                           LOCKED
Eight strategy profiles                         LOCKED
Eight objective definitions                     LOCKED
8 × 8 weight matrix                             LOCKED
Objective normalization                         LOCKED
Missing-evidence treatment                      LOCKED
Score scale and rounding                        LOCKED
Candidate tie precision                         LOCKED
Selected-exposure Pareto treatment               LOCKED
Feasibility classes and ranks                   LOCKED
Outcome/access severity order                   LOCKED
Baseline-replay source fields                   LOCKED
No-candidate treatment                          LOCKED
Profitability evidence requirements             LOCKED
EARLY_INTERVENTION treatment                    LOCKED
PORTFOLIO worst-case hierarchy                  LOCKED
Pareto tolerances and frontier ranks            LOCKED
Governance-review priority                      LOCKED
Stress non-improvement interpretation           LOCKED
Thirty-two reason definitions                   LOCKED
Archive version and trigger behavior            LOCKED

Physical object counts                         UNCHANGED
Canonical entity count                         19,298
Programs 212–219                               UNCHANGED
M2.12 handoff                                  UNCHANGED
```

## Amendment disposition

```text
Design Freeze Amendment A                     APPROVED
M2.11 source and business design          FULLY FROZEN
Remaining business-design ambiguities                0

SQL generated                                      NO
Documentation package generated                    NO
Manifest generated                                 NO
ZIP generated                                      NO
Accepted M2.10 baseline modified                   NO
```

Work Package 2 may now build Programs **212–214** without reopening M2.11 business design.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c27d755a-a56e-40c9-9cef-0c6adf0bfc9d"></a>
## Andrew / user · C080-M00545

C080-M00545 · 2026-08-05T07:15:10.272000-04:00 · active path

Preceding visible parent: [C080-M00544](part-20.md#m-b56d0923-2af9-4ba5-8c19-efcc7bd70bba)

**Editorial record note:** Attachment references: Pasted markdown(19).md; Pasted markdown (2)(5).md

<!-- BEGIN_SOURCE_MESSAGE -->
Review the two chat responses above and finalize M2.11 source and design freeze.
<!-- END_SOURCE_MESSAGE -->


<a id="m-582064d0-e53e-4522-81fe-0b823f7ef479"></a>
## Assistant · C080-M00546

C080-M00546 · 2026-08-05T07:30:16.824655-04:00 · active path

Preceding visible parent: [C080-M00545](part-20.md#m-c27d755a-a56e-40c9-9cef-0c6adf0bfc9d)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.11 Source & Design Freeze — **FINAL AND LOCKED**

I reviewed both attached responses together.

The first response is controlling on **design completeness**: it correctly confirms the accepted M2.10 baseline, approves the architecture and five-work-package approach, and identifies six implementation-affecting issues that still required a bounded Amendment B. [export reference: filecite | turn3file1]

The second response is controlling on **build execution discipline**: its five separately approved work packages, clean-workspace rules, no-work-ahead requirement, atomic Program 214 boundary, independent validation, and standalone-only pre-acceptance packaging model remain approved. Its statement that the design was already complete is revised to mean **complete after incorporation of Amendment B below**. [export reference: filecite | turn3file0]

This response constitutes:

```text
M2.11 Source & Design Freeze Amendment B
+
Final Consolidated Freeze Disposition
```

No SQL, implementation specification, catalog, manifest, checksum inventory, documentation package, or ZIP has been generated in this step.

---

# 1. Final governing hierarchy

The M2.11 build is governed in this order:

```text
1. Accepted M2.10 full-project repository
   and its governing acceptance records

2. Original M2.11 Source & Design Freeze

3. M2.11 Source & Design Freeze Amendment A

4. M2.11 Source & Design Freeze Amendment B
   established by this response

5. Approved output from the immediately
   preceding M2.11 work package
```

Where a narrow conflict exists:

```text
Amendment B
supersedes Amendment A
only on the six matters expressly resolved below.

Amendment A
supersedes the original freeze
only on the matters expressly resolved by Amendment A.

All remaining original freeze provisions remain binding.
```

An approved Work Package 1 implementation specification may consolidate and map these rules, but it may not alter them.

---

# 2. Authoritative M2.10 baseline remains locked

The accepted M2.10 baseline remains:

```text
Archive SHA-256
ca6aac62b1bb9442f3f3c5749930a13965a96c5141a18cf49fd8a37c765cf02c

Archive size
20,259,040 bytes

ZIP entries
4,488

Numbered stages
29

Final accepted stage
29_M2_10

Run code
M1_V0_2_BASELINE_BUILD

Run version
1

Run status
M2_10_ACCEPTED

Contract status
ACCEPTED

Acceptance gate
PASS

M2.10 combined set hash
24fca7263a04397ebf21d30639f9069b
```

The reviewed baseline also reconciles to:

```text
Account-performance rows                    59
KPI rows                                    72
Servicing-queue rows                         3
Matched account comparisons                 15
Canonical entities                         370

Closed-stable accounts                      57
Active-reconciled accounts                   1
Controlled-review accounts                   1

Certified exposure                     $785.48
Active exposure                        $323.79
Review-hold exposure                   $461.69
Servicing burden units                 7.000000
Unresolved exceptions                         0
```

The M2.10 ZIP itself is confirmed as the accepted baseline. Work Package 1 must also reconcile it to the matching external `.sha256` sidecar before producing implementation-control artifacts. The design freeze does not depend on rerunning M2.10 in PostgreSQL.

---

# 3. Amendment B1 — M2.2 source-family completion

## Final decision

The five-source-family hierarchy remains unchanged. The M2.2 source family is expanded to include the physical latest contract required for exact baseline replay.

The authorized M2.2 physical objects are now:

```text
msbf_m2.application_pricing_structure_latest
    Expected rows: 1,500

msbf_m2.application_pricing_structure_candidate
    Expected rows: 557

Accepted M2.2 contract registry,
acceptance gate, and set-hash metadata
```

This does **not** create a sixth source family.

## Purpose of each M2.2 object

`application_pricing_structure_latest` supplies the accepted application-level outcome and replay fields, including:

```text
pricing_disposition_code
structure_available_flag
review_required_flag
selected_candidate_template_code
selected_candidate_row_hash
candidate_count
stress_nonimprovement_applied_flag
routing_evidence_status
```

`application_pricing_structure_candidate` supplies the finite accepted structures that M2.11 may evaluate and re-rank.

## Frozen source checks

Program 213 and Program 214 must require:

```text
M2.2 latest rows                              1,500
M2.2 latest unique scenario/application rows  1,500
M2.2 candidate rows                             557
M2.2 candidate grain duplicates                   0

Selected-candidate references absent
from the candidate inventory                       0

Structure-available rows lacking
their expected candidate population                0

No-structure outcomes incorrectly
carrying selected candidates                       0
```

## Canonical-count effect

None.

The 1,500 M2.2 latest rows contribute fields to the already-frozen:

```text
portfolio_strategy_application_source_snapshot
Expected rows: 1,500
```

The 557 accepted candidates continue to populate:

```text
portfolio_strategy_candidate_source_snapshot
Expected rows: 557
```

No new M2.11 target table or canonical entity family is introduced.

## Source-scan rule

Within Program 214, every authorized physical source object may be scanned exactly once into a dedicated materialized staging object.

This rule applies per Program 214 execution. Program 213 may independently read the accepted sources for preflight validation.

After materialization, no downstream Program 214 logic may rescan the accepted physical source tables.

---

# 4. Amendment B2 — implicit no-access objective treatment

## Final decision

The implicit no-access alternative remains a temporary Program 214 evaluation construct. It is not inserted into the 4,456-row accepted-candidate evaluation table and does not alter the canonical count.

Frozen identity:

```text
Alternative code
IMPLICIT_NO_ACCESS
```

## Candidate-ranking conventions

For candidate-choice normalization and scoring only:

| Objective | Implicit no-access value |
|---|---:|
| `ACCESS_RATE` | `0` |
| `SELECTED_EXPOSURE_AMOUNT` | `0.00` |
| `FINANCE_CHARGE_AMOUNT` | `0.00` |
| `EXPECTED_LOSS_DENSITY` | `0.0000000000` |
| `RISK_ADJUSTED_CONTRIBUTION` | `0.00` |
| `ANNUALIZED_RISK_ADJUSTED_RETURN` | `0.0000000000` |
| `PAYMENT_BURDEN_RATE` | `0.0000000000` |
| `SERVICING_BURDEN_UNITS` | Not applicable at candidate grain |

The zero expected-loss density is a **finite-choice scoring convention**, not an economic ratio calculated from zero exposure.

## Persisted economic treatment

When no access is selected:

```text
selected_exposure_amount                 0.00
selected_expected_loss_amount            0.00
selected_finance_charge_amount           0.00
selected_risk_adjusted_contribution      0.00

selected_expected_loss_density           NULL
```

The economic density remains `NULL` because:

```text
0 expected loss ÷ 0 selected exposure
```

has no meaningful ratio interpretation.

The final application simulation must preserve the distinction between:

```text
candidate-ranking loss-density convention = 0

and

persisted economic loss density = NULL
```

## Scope-level zero-exposure treatment

When a strategy/scope has no selected exposure:

```text
access_rate                               0
selected_exposure_amount                  0.00
finance_charge_amount                     0.00
expected_loss_amount                      0.00
risk_adjusted_contribution                0.00

expected_loss_density                     NULL
annualized_risk_adjusted_return           NULL
payment_burden_rate                       NULL
```

Such a strategy/scope is:

```text
visible in summaries and comparisons
but
ineligible for Pareto-frontier evaluation
```

because required frontier ratios are absent.

---

# 5. Amendment B3 — candidate-selection precedence

## Final decision

The original sequence placing feasibility rank before objective score is superseded for weighted candidate selection.

### Step 1 — preserve outcomes that are not candidate-selection populations

The following bypass challenger candidate selection:

```text
NO_ACCESS_POLICY_DECLINE
NO_ACCESS_INSUFFICIENT_EVIDENCE
BLOCKED_SOURCE_INTEGRITY
```

They remain governed preserved outcomes.

### Step 2 — exclude nonselectable candidate alternatives

A candidate is excluded from selection when it has:

```text
hard_constraint_violation_count > 0

OR

feasibility_class in
(
    INFEASIBLE_OBJECTIVE_EVIDENCE,
    INFEASIBLE_HARD_CONSTRAINT,
    BLOCKED_SOURCE_INTEGRITY
)

OR

objective_score IS NULL
```

### Step 3 — rank feasible accepted candidates and implicit no access

For weighted-candidate strategies, the final selection order is:

```text
1. Highest persisted 12-decimal objective score

2. On score equality within 0.000000000001:
   best feasibility rank

3. Accepted M2.2 candidate rank

4. Candidate template code

5. Accepted candidate row hash
```

Feasibility ranks remain:

```text
1  FEASIBLE_ACCESS
2  FEASIBLE_CONTROLLED_REVIEW
3  FEASIBLE_NO_ACCESS
```

Therefore:

- no access may win when its weighted score is strictly superior;
- access or controlled review wins a true score tie against no access;
- database row order never resolves a tie.

## Score-exempt strategies

The following remain exempt:

```text
BASELINE_REPLAY
EARLY_INTERVENTION
```

`BASELINE_REPLAY` reproduces the accepted source structure.

`EARLY_INTERVENTION` replays the baseline application structure and changes only the frozen account-intervention timing treatment.

## Candidate-evaluation persistence

The persisted evaluation table remains:

```text
557 accepted candidate rows
× 8 strategies
=
4,456 rows
```

The implicit no-access alternative is calculated in temporary scoring logic and represented only through the selected application-strategy outcome when chosen.

---

# 6. Amendment B4 — account-servicing strategy treatment

## Final population

The frozen account-servicing simulation population remains:

```text
59 accepted M2.10 operational account rows
×
8 strategies
=
472 account-servicing strategy rows
```

## Seven replay strategies

For every strategy except `EARLY_INTERVENTION`, account servicing must replay the accepted M2.7/M2.10 account posture exactly:

```text
BASELINE_REPLAY
ACCESS_EXPANSION
PRICE_FOR_RISK
PAYMENT_BURDEN_RELIEF
LOSS_CONTAINMENT
PROFITABILITY_DISCIPLINE
BALANCED_FRONTIER
```

These strategies may not change:

```text
operational setup outcome
operational setup action
payment factor
setup duration
reassessment interval
reassessment date
certified account state
performance tier
servicing queue
certified exposure
payment performance
exception posture
servicing burden units
```

## EARLY_INTERVENTION

The Amendment A timing-only treatment remains unchanged:

```text
Closed stable:
    no intervention
    no burden increment

Active reconciled:
    earlier reassessment
    payment factor unchanged
    exposure unchanged
    +1.000000 burden unit

Controlled review:
    accelerated governance review
    payment factor unchanged
    exposure unchanged
    +1.000000 burden unit
```

No account strategy claims reduced risk, improved return, higher contribution, or improved payment performance.

## Separation from application selection

The application-strategy layer and account-servicing layer are distinct governed simulations.

An application strategy outcome does not:

- delete an accepted operational account;
- close an accepted operational account;
- fabricate an account for a newly selected application;
- alter accepted payment or account history.

An existing account remains in the account-servicing simulation even when an application strategy’s counterfactual outcome is no access.

## Scope-specific account counts

Frozen expected account coverage:

```text
BASELINE account rows                     44
RECESSION_ENERGY account rows             15
PORTFOLIO distinct operational accounts   44
```

The accepted 15 stress accounts must each match one baseline operational application. Program 213 must fail closed if that relationship does not hold.

## PORTFOLIO account rollup

For each:

```text
merchant_application_id
+ strategy_profile_code
```

select one account-servicing row from the available scenarios using:

```text
1. Highest accepted source-account posture rank

   CONTROLLED_REVIEW     3
   ACTIVE_RECONCILED     2
   CLOSED_STABLE         1

2. Highest strategy servicing-burden units

3. Highest certified exposure amount

4. RECESSION_ENERGY before BASELINE

5. Account-servicing simulation row hash,
   ascending lexical order
```

The 15 matched baseline/stress pairs collapse to one adverse row each. Baseline-only accounts remain as their available row.

## Servicing-burden interpretation

Newly access-selected applications without an accepted operational account receive no fabricated servicing simulation or burden estimate.

Scope-level servicing burden means:

> Burden on the accepted M2.10 operational-account population under the strategy—not projected total servicing cost for newly selected access.

Every scope summary and contract row must expose:

```text
servicing_account_rows
servicing_distinct_application_rows

servicing_burden_coverage_code
=
ACCEPTED_OPERATIONAL_ACCOUNTS_ONLY

new_access_servicing_burden_estimated_flag
=
false
```

This limitation must remain visible in Program 218, Program 219, and the final contract.

---

# 7. Amendment B5 — applications without an operational account

## Final decision

Absence of an accepted M2.10 operational account is not a credit-data, economics, or source-integrity defect.

For an application with no operational account:

```text
operational_account_present_flag
=
false

account_certification_constraint_applicability
=
NOT_APPLICABLE

constraint_unresolved_exception_count
=
0
```

The `0` applies only to hard-constraint evaluation. It means:

```text
No associated operational exception exists
because no accepted operational account exists.
```

It must not be represented as a measured operational-account metric.

Accordingly:

```text
source_unresolved_exception_count
=
NULL

source_certified_state_code
=
NULL

source_servicing_queue_code
=
NULL

source_certified_exposure_amount
=
NULL
```

For an application with an accepted account, the exception/certification constraint applies and requires:

```text
state_certified_flag = true
unresolved_exception_count = 0
certification_blocked_flag = false
accepted account lineage intact
```

This rule applies to every strategy, including the controlled `ACCESS_EXPANSION` exception.

It does not weaken economic, affordability, candidate, policy-decline, or insufficient-evidence controls.

---

# 8. Amendment B6 — latest and archive contract grain

## Latest contract

Frozen unique key:

```text
module1_run_id
+ strategy_profile_code
+ reporting_scope_code
```

`contract_version` is a required stored attribute but is not part of latest-row uniqueness.

Expected version-1 latest rows:

```text
8 strategies × 3 scopes = 24
```

## Immutable archive

Frozen unique key:

```text
module1_run_id
+ contract_version
+ strategy_profile_code
+ reporting_scope_code
```

Expected version-1 archive rows:

```text
24
```

## Current-version behavior

Program 214 must:

1. insert 24 latest rows for version 1;
2. insert 24 immutable archive rows for version 1;
3. fail closed if version-1 latest, archive, registry, or generated business rows already exist;
4. prohibit a committed version-1 rerun.

Program 215–219 may not rewrite latest business values or archive values.

Program 217 may update only mutable lifecycle fields and timestamps in the contract registry.

## Archive trigger

The archive remains protected by a database-level:

```text
BEFORE UPDATE OR DELETE
```

trigger that raises on every attempted mutation.

## Future versions

A future contract or methodology version requires:

```text
a new source/design freeze
+ new methodology identity
+ new contract version
+ separately governed implementation
```

Such a future version may replace the current latest view of the contract while appending a new immutable archive version. That behavior is outside the current version-1 programs.

---

# 9. Frozen source hierarchy after Amendment B

Exactly five accepted source families remain authorized.

## 1. M2.10 current portfolio-performance family

```text
msbf_ctl.m2_10_portfolio_analytics_contract_registry
msbf_m2.application_portfolio_performance_latest
msbf_m2.portfolio_kpi_snapshot
msbf_m2.servicing_queue_analytics_snapshot
```

## 2. M1.17 integrated application family

```text
msbf_m1.v_m1_17_g2_integrated_consumption
```

## 3. M2.2 pricing-and-structure family

```text
msbf_m2.application_pricing_structure_latest
msbf_m2.application_pricing_structure_candidate
accepted M2.2 registry and gate metadata
```

## 4. M2.4 booking/funding/activation family

```text
msbf_m2.application_booking_funding_activation_latest
```

## 5. M2.7 operational-activation family

```text
msbf_m2.application_operational_activation_latest
```

Direct reads of M2.3, M2.5, M2.6, M2.8, and M2.9 business tables remain prohibited.

---

# 10. All other frozen design elements remain unchanged

The following remain exactly as previously locked:

```text
Module
M2.11 — Portfolio Optimization & Strategy Simulation

Repository stage
30_M2_11

Methodology
M2_11_METHOD_V1

Policy
M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_POLICY_V1

Contract
M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION v1

Schema
M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1

Acceptance gate
M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION
```

Also unchanged:

```text
Strategy profiles                          8
Objective definitions                      8
Hard-constraint families                  12
Reason definitions                        32
Reporting scopes                           3

Positive controls                        120
Negative controls                         20
Generation evidence rows                  24
Acceptance evidence rows                   1
Detailed-report result sets               24
```

The eight strategies remain:

```text
BASELINE_REPLAY
ACCESS_EXPANSION
PRICE_FOR_RISK
PAYMENT_BURDEN_RELIEF
LOSS_CONTAINMENT
PROFITABILITY_DISCIPLINE
EARLY_INTERVENTION
BALANCED_FRONTIER
```

The 8 × 8 weight matrix, normalization formulas, missing-evidence treatment, exact precision and rounding, selected-exposure exclusion from Pareto dominance, feasibility classes, outcome-severity ranks, baseline-replay fields, profitability requirements, PORTFOLIO application adversity order, Pareto tolerances, non-dominated sorting, governance-review priority, stress non-improvement rules, 32-reason catalog, and non-production boundary remain governed by Amendment A.

---

# 11. Physical counts and canonical arithmetic remain unchanged

```text
Policy profile                                  1
Strategy profiles                               8
Objective definitions                           8
Constraint definitions                         12
Reason definitions                             32

Application source snapshots                1,500
Candidate source snapshots                    557
Account source snapshots                       59
KPI source snapshots                           72
Queue source snapshots                          3

Candidate evaluations                       4,456
Application strategy simulations           12,000
Account servicing simulations                 472

Strategy summaries                             24
Frontier rows                                  24
Baseline/challenger comparisons                21

Latest contract rows                           24
Archive contract rows                          24
Contract registry rows                          1
                                            ------
Canonical entities                         19,298
```

Arithmetic:

```text
1 + 8 + 8 + 12 + 32
+ 1,500 + 557 + 59 + 72 + 3
+ 4,456 + 12,000 + 472
+ 24 + 24 + 21
+ 24 + 24 + 1
=
19,298
```

The implicit no-access alternative is temporary and is excluded from canonical counts.

The newly authorized M2.2 latest source populates an existing source snapshot and does not create additional canonical rows.

---

# 12. Program and mutation architecture remains unchanged

Normal sequence:

```text
212  Schema, policy, definitions,
     contracts, triggers, and views

213  Accepted-source and pristine-target preflight

214  Deterministic strategy simulation
     and physical reconciliation

215  Positive validation

216  Negative controls

217  Acceptance finalizer

218  Master report

219  Detailed report
```

Recovery programs:

```text
212A  Failed schema/policy installation recovery
214A  Failed pre-commit generation rollback recovery
214B  Committed-generation checkpoint reconstruction
215A  Failed-positive-validation recovery
```

Implementation invariants:

```text
212 installs structures and definitions only.

213 is read-only.

214 is the sole normal writer of
M2.11 simulation business rows.

215–219 cannot regenerate the simulation blueprint.

218 and 219 are read-only.

Every combined hash uses explicit ordered aggregation.

Every selection and tie uses frozen business keys.

Recovery programs never appear in the normal execution chain.
```

---

# 13. Five-work-package plan — final disposition

The five-work-package approach remains fully approved. It creates the necessary review and restart boundaries and prevents another monolithic one-pass build. [export reference: filecite | turn4file0]

The governing references in the work-package prompts must now read:

```text
Accepted M2.10 baseline
+ Final M2.11 Source & Design Freeze
  consisting of:
    original freeze
    Amendment A
    Amendment B
```

The five packages remain:

```text
WP1  Freeze consolidation and implementation specification

WP2  Programs 212–214 and associated recovery utilities

WP3  Programs 215–216 and validation recovery

WP4  Programs 217–219

WP5  Documentation and standalone execution packaging
```

The global controls from the work-package response remain binding:

- one clean workspace;
- no reuse of partial failed M2.11 builds;
- no work ahead;
- no invented business rules;
- no fabricated hashes, results, champions, or acceptance;
- PostgreSQL `numeric`, not floating point;
- explicit insert projections;
- ordered hashes;
- staged source consumption;
- index and `ANALYZE` before downstream joins;
- materialize expensive intermediates once;
- no full-project ZIP before acceptance;
- standalone status must remain `READY FOR LIVE EXECUTION / NOT EXECUTED / NOT ACCEPTED`. [export reference: filecite | turn7file0]

This conversation is already the dedicated M2.11 build conversation. There is no need to return to the failed build chat or open another one.

---

# 14. Final authorization state

```text
M2.10 authoritative baseline                  LOCKED
Original M2.11 Source & Design Freeze          LOCKED
M2.11 Amendment A                              LOCKED
M2.11 Amendment B                              LOCKED

Five-source-family hierarchy                   LOCKED
Authorized physical source objects             LOCKED
Eight strategies                               LOCKED
Eight objectives                               LOCKED
8 × 8 weight matrix                            LOCKED
Twelve hard constraints                        LOCKED
Thirty-two reasons                             LOCKED
Three reporting scopes                         LOCKED

No-access objective treatment                  LOCKED
Candidate-selection precedence                 LOCKED
Account-servicing treatment                    LOCKED
Operational-account applicability              LOCKED
PORTFOLIO account rollup                       LOCKED
Latest/archive grain                           LOCKED

Expected physical counts                       LOCKED
Canonical count of 19,298                      LOCKED
Programs 212–219                               LOCKED
Recovery boundaries                            LOCKED
Validation counts                              LOCKED
Non-production boundary                        LOCKED
M2.12 handoff                                  LOCKED

Remaining business-design ambiguities               0
```

## Build authorization

```text
Work Package 1
AUTHORIZED

Programs 212–219 SQL construction
NOT YET AUTHORIZED

Condition for SQL authorization
Work Package 1 approval with:

Frozen-semantic changes                         0
Unmapped required source fields                 0
Unresolved target grains                        0
Canonical-count discrepancies                  0
Program-boundary ambiguities                    0
```

## Artifact status for this response

```text
SQL generated                                  NO
Implementation files generated                 NO
Documentation package generated                NO
Manifest generated                             NO
ZIP generated                                  NO
Accepted M2.10 baseline modified               NO
```

**The M2.11 source and business design is now fully frozen. The next governed action is Work Package 1 only.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-65d21eea-ce26-4638-9c09-1bdeeffb7f6f"></a>
## Andrew / user · C080-M00547

C080-M00547 · 2026-08-06T23:53:32.244000-04:00 · active path

Preceding visible parent: [C080-M00546](part-20.md#m-582064d0-e53e-4522-81fe-0b823f7ef479)

**Editorial record note:** Attachment references: M2_11_STANDALONE_ACCEPTED_20260806(2).zip; M2.11_Acceptance.rtf; M2_11_FULL_PROJECT_ACCEPTED_20260806(2).zip

<!-- BEGIN_SOURCE_MESSAGE -->
M2.11 acceptance. Ingest before we move on to M2.12 source and business design.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9685dc0c-c207-475a-a21d-b95431542f9c"></a>
## Assistant · C080-M00548

C080-M00548 · 2026-08-06T23:57:50.887103-04:00 · active path

Preceding visible parent: [C080-M00547](part-20.md#m-65d21eea-ce26-4638-9c09-1bdeeffb7f6f)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.11 accepted baseline ingested

The following artifacts are now treated as the authoritative M2.11 acceptance set:

```text
M2_11_STANDALONE_ACCEPTED_20260806(2).zip
M2_11_FULL_PROJECT_ACCEPTED_20260806(2).zip
M2.11_Acceptance.rtf
```

I independently confirmed that both ZIP archives open successfully and pass CRC validation. Their calculated identities match the acceptance record:

```text
Accepted standalone M2.11
SHA-256
7fec978d1675af4fe415f31a7560dda605f6f48fe055fe8c671b07c59156c6b6

ZIP entries
308

Accepted full project through M2.11
SHA-256
92f0491eea26b0d546c85992e27433cd006a0b2f126c32a139d795b7749904fc

ZIP entries
4,819

Numbered stages
30

Final stage
30_M2_11
```

The acceptance record confirms that the independent audit concluded **PASS**, with no source, runtime, canonical-identity, validation, acceptance, archive, stress, or evidence-completeness blocker. It also confirms that all packaging advisories were resolved without changing SQL or rerunning PostgreSQL. [export reference: filecite | turn8file0 | L10-L45]

## Accepted database identity

```text
Run code
M1_V0_2_BASELINE_BUILD

Run version
1

Run status
M2_11_ACCEPTED

Contract status
ACCEPTED

Acceptance gate
PASS

Generation evidence
24 / 24 PASS

Positive controls
120 / 120 PASS

Negative controls
20 / 20 PASS

Acceptance prerequisites
45 / 45 PASS

Canonical families
19

Canonical entities
19,298

Contract set hash
19f1a9d842c9cb35617ca03e49445aad

Combined set hash
a67d375b9f9248b3eec8160cf3dc656d

Registry row hash
61c22f4f3f2e99905d05958fddf80671

Deterministic mismatches
0

Blocking or stage-boundary findings
0

Stress-improvement violations
0

Latest/archive mismatches
0

Governed evidence exports
38 / 38 PASS
```

These identities reconcile across the acceptance finalizer, master report, 24 detailed reports, post-chain state, and independent audit. [export reference: filecite | turn8file0 | L179-L239]

## Repository authority

The full-project ZIP is now the sole technical baseline for M2.12 source and business design:

```text
Authoritative project baseline
M2_11_FULL_PROJECT_ACCEPTED_20260806(2).zip

Accepted predecessor stages
29 / 29 byte-identical

Embedded accepted M2.11 stage
30_M2_11

Standalone versus embedded M2.11
BYTE-IDENTICAL
```

The acceptance package reports that all 29 predecessor stages were preserved and that the embedded `30_M2_11` stage is byte-identical to the accepted standalone package. [export reference: filecite | turn8file0 | L145-L170]

## Current governance boundary

```text
M2.11                                    ACCEPTED
M2.12 source and business design         AUTHORIZED
M2.12 SQL construction                   NOT AUTHORIZED
M2.12 PostgreSQL execution               NOT AUTHORIZED
Production deployment                    NOT AUTHORIZED
Module 3                                 NOT AUTHORIZED
```

The independent audit expressly authorizes **M2.12 source/design planning only** while retaining separate approval requirements for M2.12 implementation and execution. [export reference: filecite | turn8file0 | L241-L280]

No files were created, modified, repackaged, or superseded during this intake.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c4179f9b-ac68-4205-96df-5fc5ab251a50"></a>
## Andrew / user · C080-M00549

C080-M00549 · 2026-08-07T00:01:11.213000-04:00 · active path

Preceding visible parent: [C080-M00548](part-20.md#m-9685dc0c-c207-475a-a21d-b95431542f9c)

<!-- BEGIN_SOURCE_MESSAGE -->
Produce M2.12 source and business design. We will build M2.12 in a separate chat. We need to pass everything to the other chat in explicit detail to ensure successful M2.12 build.
<!-- END_SOURCE_MESSAGE -->
