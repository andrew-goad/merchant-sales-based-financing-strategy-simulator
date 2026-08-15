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

* eight objective weights;
* selection mode;
* selected-exposure direction;
* candidate-scoring applicability;
* scope-scoring applicability;
* score weight total;
* evidence handling code;
* score precision;
* row hash.

The eight-row:

```text
msbf_m2.portfolio_strategy_objective_definition
```

will carry the stable objective semantics:

* raw-value formula code;
* default optimization direction;
* normalization method;
* missing-value policy;
* scoring domain;
* scope-aggregation method;
* Pareto-inclusion flag;
* equality tolerance;
* numeric scale.

Weights will not exist only inside an opaque JSON document. Any JSON payload will be a reporting representation of explicit physical fields.

The frozen canonical count therefore remains:

```text
19,298
```

---

# A2. Exact objective definitions

## Objective formulas

| Objective                         | Application/candidate raw value                                 | Scope-level raw value                                              |  Stable direction | Pareto |
| --------------------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------ | ----------------: | -----: |
| `ACCESS_RATE`                     | `1` for a selected access candidate; `0` for implicit no-access | Access-selected application rows ÷ total application rows in scope |          Maximize |    Yes |
| `SELECTED_EXPOSURE_AMOUNT`        | Candidate funding amount; zero for no-access                    | Sum of selected funding amount                                     | Strategy-specific | **No** |
| `FINANCE_CHARGE_AMOUNT`           | Candidate finance-charge amount; zero for no-access             | Sum of selected finance-charge amount                              |          Maximize |    Yes |
| `EXPECTED_LOSS_DENSITY`           | Candidate expected loss ÷ candidate funding amount              | Sum expected loss ÷ sum selected exposure                          |          Minimize |    Yes |
| `RISK_ADJUSTED_CONTRIBUTION`      | Candidate risk-adjusted contribution; zero for no-access        | Sum risk-adjusted contribution                                     |          Maximize |    Yes |
| `ANNUALIZED_RISK_ADJUSTED_RETURN` | Candidate annualized return; zero for no-access                 | Selected-exposure-weighted annualized return                       |          Maximize |    Yes |
| `SERVICING_BURDEN_UNITS`          | Not used in candidate ranking                                   | Sum of selected account-servicing burden units                     |          Minimize |    Yes |
| `PAYMENT_BURDEN_RATE`             | Candidate remittance rate; zero for no-access                   | Selected-exposure-weighted remittance rate                         |          Minimize |    Yes |

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

* access selections;
* controlled reviews;
* strategy restrictions;
* insufficient-evidence outcomes;
* policy declines;
* blocked rows.

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

| Strategy                   | Selection mode       |     Access ↑ |       Exposure | Finance charge ↑ | Loss density ↓ | Contribution ↑ |     Return ↑ | Servicing burden ↓ | Payment burden ↓ |
| -------------------------- | -------------------- | -----------: | -------------: | ---------------: | -------------: | -------------: | -----------: | -----------------: | ---------------: |
| `BASELINE_REPLAY`          | `SOURCE_REPLAY`      |            — |              — |                — |              — |              — |            — |                  — |                — |
| `ACCESS_EXPANSION`         | `WEIGHTED_CANDIDATE` | **0.450000** | **0.150000 ↑** |         0.050000 |       0.100000 |       0.100000 |     0.050000 |                  — |         0.100000 |
| `PRICE_FOR_RISK`           | `WEIGHTED_CANDIDATE` |     0.100000 |     0.050000 ↑ |     **0.300000** |       0.150000 |       0.200000 |     0.100000 |                  — |         0.100000 |
| `PAYMENT_BURDEN_RELIEF`    | `WEIGHTED_CANDIDATE` |     0.150000 |     0.100000 ↓ |         0.050000 |       0.100000 |       0.100000 |     0.050000 |                  — |     **0.450000** |
| `LOSS_CONTAINMENT`         | `WEIGHTED_CANDIDATE` |     0.050000 |     0.250000 ↓ |                — |   **0.400000** |       0.100000 |     0.050000 |                  — |         0.150000 |
| `PROFITABILITY_DISCIPLINE` | `WEIGHTED_CANDIDATE` |     0.050000 |     0.050000 ↑ |         0.150000 |       0.150000 |   **0.350000** | **0.200000** |                  — |         0.050000 |
| `EARLY_INTERVENTION`       | `RULE_BASED_ACCOUNT` |            — |              — |                — |              — |              — |            — |       **0.600000** |     **0.400000** |
| `BALANCED_FRONTIER`        | `WEIGHTED_CANDIDATE` |     0.200000 |     0.050000 ↑ |         0.100000 |       0.200000 |   **0.200000** |     0.100000 |           0.100000 |         0.050000 |

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

* the candidate-selection score excludes servicing burden;
* `BALANCED_FRONTIER` candidate selection renormalizes its remaining application-objective weights from `0.900000` to `1.000000`;
* its full eight-objective matrix is used only for the scope-level evaluation score;
* all other weighted candidate strategies already have candidate-domain weights totaling `1.000000`.

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

| Condition                                                                     | Frozen treatment                                          |
| ----------------------------------------------------------------------------- | --------------------------------------------------------- |
| Structural field absent, such as amount, remittance, or finance charge        | `BLOCKED_SOURCE_INTEGRITY`                                |
| Expected loss, contribution, or return required by a positive weight but null | `INFEASIBLE_OBJECTIVE_EVIDENCE`                           |
| Upstream evidence `BLOCKED`                                                   | Candidate may not be selected                             |
| Upstream evidence `PARTIAL`, but objective values physically exist            | Candidate may be scored; evidence remains `PARTIAL`       |
| Objective weight is zero or objective is outside evaluation domain            | `NOT_APPLICABLE`; omitted from denominator                |
| Scope metric required by a positive weight is null                            | Scope score becomes null; strategy is frontier-ineligible |
| Unknown amount                                                                | Remains null; never converted to zero                     |

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

* visible in every candidate, strategy, comparison, and contract output;
* available for strategy-specific weighted scoring;
* available for baseline deltas;
* available for worst-case portfolio ordering;
* **excluded from Pareto dominance**.

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

| Rank | Feasibility class                 | Meaning                                                                                   |
| ---: | --------------------------------- | ----------------------------------------------------------------------------------------- |
|    1 | `FEASIBLE_ACCESS`                 | Candidate satisfies all constraints and strategy permits synthetic access                 |
|    2 | `FEASIBLE_CONTROLLED_REVIEW`      | Candidate is analytically viable but source route, evidence, or economics requires review |
|    3 | `FEASIBLE_NO_ACCESS`              | Deterministic no-access alternative                                                       |
|    4 | `INFEASIBLE_OBJECTIVE_EVIDENCE`   | A positively weighted required objective is missing or blocked                            |
|    5 | `INFEASIBLE_HARD_CONSTRAINT`      | One or more hard constraints fail                                                         |
|    6 | `PRESERVED_INSUFFICIENT_EVIDENCE` | M2.2 no-structure insufficient-evidence outcome preserved                                 |
|    7 | `PRESERVED_POLICY_DECLINE`        | M2.2 policy-decline outcome preserved                                                     |
|    8 | `BLOCKED_SOURCE_INTEGRITY`        | Source count, grain, lineage, identity, or accepted-candidate inconsistency               |

Infeasible candidates remain in the 4,456-row evaluation table with:

```text
objective_score = NULL
candidate_selected_flag = false
```

They are not silently dropped.

---

# A7. Exact strategy-outcome severity order

Lower rank is better. Higher rank is selected by the `PORTFOLIO` worst-case rollup.

| Rank | Strategy outcome                  |
| ---: | --------------------------------- |
|    1 | `ACCESS_SELECTED`                 |
|    2 | `CONTROLLED_REVIEW`               |
|    3 | `NO_ACCESS_STRATEGY_RESTRICTION`  |
|    4 | `NO_ACCESS_NO_FEASIBLE_CANDIDATE` |
|    5 | `NO_ACCESS_INSUFFICIENT_EVIDENCE` |
|    6 | `NO_ACCESS_POLICY_DECLINE`        |
|    7 | `BLOCKED_SOURCE_INTEGRITY`        |

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

| M2.2 source condition                                            | M2.11 treatment                                               |
| ---------------------------------------------------------------- | ------------------------------------------------------------- |
| `NO_STRUCTURE_POLICY_DECLINE`                                    | Preserve `NO_ACCESS_POLICY_DECLINE` for every strategy        |
| `NO_STRUCTURE_INSUFFICIENT_EVIDENCE`                             | Preserve `NO_ACCESS_INSUFFICIENT_EVIDENCE` for every strategy |
| Structure available and candidate rows present                   | Evaluate accepted candidates                                  |
| Structure available but expected candidate rows absent           | `BLOCKED_SOURCE_INTEGRITY`                                    |
| Selected M2.2 candidate absent from accepted candidate inventory | `BLOCKED_SOURCE_INTEGRITY`                                    |
| Candidates exist but none passes M2.11 constraints               | `NO_ACCESS_NO_FEASIBLE_CANDIDATE`                             |
| Strategy deliberately chooses the implicit no-access option      | `NO_ACCESS_STRATEGY_RESTRICTION`                              |

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

| Accepted economic status | Challenger treatment                                   |
| ------------------------ | ------------------------------------------------------ |
| `ABOVE_HURDLE`           | May be `FEASIBLE_ACCESS` if all other constraints pass |
| `BELOW_HURDLE`           | At most `FEASIBLE_CONTROLLED_REVIEW`                   |
| `NEGATIVE_CONTRIBUTION`  | `INFEASIBLE_HARD_CONSTRAINT`                           |
| `INSUFFICIENT_EVIDENCE`  | `INFEASIBLE_OBJECTIVE_EVIDENCE`                        |

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

| Objective                         | Equality/no-worse tolerance |
| --------------------------------- | --------------------------: |
| `ACCESS_RATE`                     |                `0.00000001` |
| `FINANCE_CHARGE_AMOUNT`           |                     `$0.01` |
| `EXPECTED_LOSS_DENSITY`           |                `0.00000001` |
| `RISK_ADJUSTED_CONTRIBUTION`      |                     `$0.01` |
| `ANNUALIZED_RISK_ADJUSTED_RETURN` |                `0.00000001` |
| `SERVICING_BURDEN_UNITS`          |                  `0.000001` |
| `PAYMENT_BURDEN_RATE`             |                `0.00000001` |

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

* does not select application candidates;
* does not determine Pareto dominance;
* does not override constraints;
* does not authorize deployment.

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

* a worse access outcome;
* a worse feasibility class;
* lower selected exposure;
* a more conservative candidate;
* no access where baseline had access;

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

* is reported;
* is not hidden;
* is not called a source improvement;
* does not fail stress non-improvement when caused by a worse access outcome.

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

|  # | Reason code                                  | Severity       | Applicability           |
| -: | -------------------------------------------- | -------------- | ----------------------- |
|  1 | `M2_11_REASON_SOURCE_CONTRACTS_VERIFIED`     | `INFO`         | `ALL`                   |
|  2 | `M2_11_REASON_BASELINE_REPLAY_MATCH`         | `INFO`         | `APPLICATION_ACCOUNT`   |
|  3 | `M2_11_REASON_SOURCE_EVIDENCE_PARTIAL`       | `REVIEW`       | `CANDIDATE_APPLICATION` |
|  4 | `M2_11_REASON_SOURCE_EVIDENCE_BLOCKED`       | `SYSTEM_BLOCK` | `ALL`                   |
|  5 | `M2_11_REASON_SOURCE_GRAIN_OR_LINEAGE_ERROR` | `SYSTEM_BLOCK` | `ALL`                   |

## Constraint and feasibility reasons

|  # | Reason code                                    | Severity       | Applicability           |
| -: | ---------------------------------------------- | -------------- | ----------------------- |
|  6 | `M2_11_REASON_POLICY_DECLINE_PRESERVED`        | `ACCESS_BLOCK` | `APPLICATION`           |
|  7 | `M2_11_REASON_INSUFFICIENT_EVIDENCE_PRESERVED` | `ACCESS_BLOCK` | `APPLICATION`           |
|  8 | `M2_11_REASON_CANDIDATE_NOT_ELIGIBLE`          | `ACCESS_BLOCK` | `CANDIDATE`             |
|  9 | `M2_11_REASON_STRUCTURE_BOUND_VIOLATION`       | `ACCESS_BLOCK` | `CANDIDATE`             |
| 10 | `M2_11_REASON_AFFORDABILITY_CONSTRAINT`        | `ACCESS_BLOCK` | `CANDIDATE`             |
| 11 | `M2_11_REASON_ECONOMIC_EVIDENCE_BLOCKED`       | `ACCESS_BLOCK` | `CANDIDATE`             |
| 12 | `M2_11_REASON_NEGATIVE_CONTRIBUTION`           | `ACCESS_BLOCK` | `CANDIDATE`             |
| 13 | `M2_11_REASON_BELOW_HURDLE_REVIEW`             | `REVIEW`       | `CANDIDATE_APPLICATION` |
| 14 | `M2_11_REASON_UNRESOLVED_EXCEPTION`            | `ACCESS_BLOCK` | `APPLICATION_ACCOUNT`   |
| 15 | `M2_11_REASON_CLOSED_STATE_PRESERVED`          | `INFO`         | `ACCOUNT`               |

## Strategy-selection reasons

|  # | Reason code                                      | Severity       | Applicability           |
| -: | ------------------------------------------------ | -------------- | ----------------------- |
| 16 | `M2_11_REASON_ACCESS_EXPANSION_SELECTED`         | `INFO`         | `APPLICATION`           |
| 17 | `M2_11_REASON_PRICE_FOR_RISK_SELECTED`           | `INFO`         | `APPLICATION`           |
| 18 | `M2_11_REASON_PAYMENT_BURDEN_RELIEF_SELECTED`    | `INFO`         | `APPLICATION`           |
| 19 | `M2_11_REASON_LOSS_CONTAINMENT_SELECTED`         | `INFO`         | `APPLICATION`           |
| 20 | `M2_11_REASON_PROFITABILITY_DISCIPLINE_SELECTED` | `INFO`         | `APPLICATION`           |
| 21 | `M2_11_REASON_EARLY_INTERVENTION_SIMULATED`      | `REVIEW`       | `ACCOUNT`               |
| 22 | `M2_11_REASON_BALANCED_FRONTIER_SELECTED`        | `INFO`         | `APPLICATION`           |
| 23 | `M2_11_REASON_NO_ACCESS_STRATEGY_RESTRICTION`    | `INFO`         | `APPLICATION`           |
| 24 | `M2_11_REASON_CONTROLLED_REVIEW_REQUIRED`        | `REVIEW`       | `APPLICATION_ACCOUNT`   |
| 25 | `M2_11_REASON_DETERMINISTIC_TIE_BREAK_APPLIED`   | `INFO`         | `CANDIDATE_APPLICATION` |
| 26 | `M2_11_REASON_NO_FEASIBLE_CANDIDATE`             | `ACCESS_BLOCK` | `APPLICATION`           |

## Stress, frontier, and governance reasons

|  # | Reason code                                      | Severity       | Applicability |
| -: | ------------------------------------------------ | -------------- | ------------- |
| 27 | `M2_11_REASON_STRESS_SOURCE_NONIMPROVEMENT_PASS` | `INFO`         | `COMPARISON`  |
| 28 | `M2_11_REASON_STRESS_STRATEGY_RESTRICTION`       | `INFO`         | `COMPARISON`  |
| 29 | `M2_11_REASON_STRESS_IMPROVEMENT_VIOLATION`      | `SYSTEM_BLOCK` | `COMPARISON`  |
| 30 | `M2_11_REASON_NONDOMINATED_FRONTIER`             | `INFO`         | `FRONTIER`    |
| 31 | `M2_11_REASON_DOMINATED_STRATEGY`                | `INFO`         | `FRONTIER`    |
| 32 | `M2_11_REASON_GOVERNANCE_REVIEW_PRIORITY`        | `REVIEW`       | `FRONTIER`    |

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

* contract payload;
* source latest row hash;
* archive identity;
* contract version.

## Lifecycle behavior

Program 214 creates the version-1 latest and archive rows and sets:

```text
contract_status = GENERATED
run_status      = M2_11_GENERATED
```

Programs 215 and 217 may update only mutable registry lifecycle fields and timestamps.

They may not update:

* latest business values;
* latest contract hashes;
* archive payloads;
* archive hashes.

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
