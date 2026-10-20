# Branch · Merchant POS Lending Simulator

Part 19 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-18.md)
[Next part](part-20.md)

<a id="m-ba4777c1-5e38-423e-9df9-4aa84ffa6a5f"></a>
## Andrew / user · C080-M00541

C080-M00541 · 2026-08-04T22:30:07.968000-04:00 · active path

Preceding visible parent: [C080-M00540](part-18.md#m-23d53406-8756-40cc-801b-ff58bac62502)

**Editorial record note:** Attachment references: M2_10_FULL_PROJECT_ACCEPTED_20260804(6).zip; M2_10_FULL_PROJECT_ACCEPTED_20260804.zip(6).sha256

<!-- BEGIN_SOURCE_MESSAGE -->
Lock Down M2.11 Source & Design Freeze. Do not generate SQL, documentation packaging, manifests, zip creation, etc. Only focus on locking down the source and design freeze in this prompt. M2.10 baseline attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c4a4c7c3-f299-4ae7-9fed-4d7339955429"></a>
## Assistant · C080-M00542

C080-M00542 · 2026-08-04T23:02:17.878062-04:00 · active path

Preceding visible parent: [C080-M00541](part-19.md#m-ba4777c1-5e38-423e-9df9-4aa84ffa6a5f)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.11 Source & Design Freeze — **LOCKED**

No SQL, documentation package, manifest, checksum inventory, ZIP, or other artifact was created or modified in this step.

## 1. Authoritative baseline verification

The attached accepted M2.10 full-project repository is the sole technical baseline for M2.11:

- Accepted M2.10 full-project baseline (historical reference: `sandbox:[session]/M2_10_FULL_PROJECT_ACCEPTED_20260804(6`; referenced bytes not established here).zip)
- Submitted SHA-256 sidecar (historical reference: `sandbox:[session]/M2_10_FULL_PROJECT_ACCEPTED_20260804.zip(6`; referenced bytes not established here).sha256)

Verification result:

```text
Archive
M2_10_FULL_PROJECT_ACCEPTED_20260804(6).zip

SHA-256
ca6aac62b1bb9442f3f3c5749930a13965a96c5141a18cf49fd8a37c765cf02c

Submitted sidecar reconciliation             PASS
ZIP CRC validation                           PASS
Accepted files                              4,488
Accepted archive size                  20,259,040 bytes
Accepted numbered stages                       29
Current final stage                       29_M2_10
```

The accepted database and contract boundary is:

```text
Run code
M1_V0_2_BASELINE_BUILD

Run version
1

Run status
M2_10_ACCEPTED

M2.10 contract
M2_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_CONSUMPTION v1

M2.10 schema
M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_SCHEMA_V1

M2.10 methodology
M2_10_METHOD_V1

M2.10 policy
M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS_POLICY_V1

M2.10 acceptance gate
M2_10_PORTFOLIO_PERFORMANCE_KPI_SERVICING_ANALYTICS

M2.10 combined set hash
24fca7263a04397ebf21d30639f9069b
```

Accepted M2.10 cardinalities frozen as source prerequisites:

```text
Account-performance latest rows                59
KPI snapshot rows                              72
Servicing-queue summary rows                    3
Matched account comparisons                    15
Latest/archive rows                       59 / 59
Canonical entities                           370

Closed-stable accounts                         57
Active-reconciled accounts                      1
Controlled-review accounts                      1
Certified exposure                        $785.48
Active exposure                           $323.79
Review-hold exposure                      $461.69
Servicing burden units                      7.000
Unresolved exceptions                           0
```

---

# 2. Frozen M2.11 identity

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
M2_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_CONSUMPTION

Contract version
1

Schema
M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION_SCHEMA_V1

Acceptance gate
M2_11_PORTFOLIO_OPTIMIZATION_STRATEGY_SIMULATION
```

Frozen lifecycle:

```text
M2_10_ACCEPTED
→ M2_11_GENERATED
→ M2_11_VALIDATED
→ M2_11_ACCEPTED
```

M2.11 does **not** close Module 2 and does not issue the final Module 2 consumption gate. That responsibility remains with:

```text
M2.12 — Enterprise Portfolio Certification
        & Consumption Contract
```

M2.11 does not authorize Module 3.

---

# 3. Frozen business purpose

M2.11 will answer this bounded question:

> Given the accepted application, candidate-structure, activation, intervention, and portfolio-performance evidence, which finite governed challenger strategies create the strongest transparent tradeoffs among access, selected exposure, pricing and payment burden, expected-loss density, risk-adjusted profitability, intervention timing, and servicing workload—without violating hard constraints or creating artificial improvement under stress?

The term **optimization** is frozen to mean:

```text
Finite governed candidate enumeration
+ constraints-first feasibility
+ deterministic strategy-specific scoring
+ Pareto/non-dominated frontier analysis
+ governance-review prioritization
```

It does **not** mean:

- autonomous optimization;
- continuous mathematical generation of new terms;
- black-box machine learning;
- production decisioning;
- causal treatment-effect estimation;
- automatic policy deployment.

---

# 4. Frozen source hierarchy

M2.10 is the primary current-state source. Four earlier accepted contracts are authorized only as bounded supplemental sources for fields that M2.10 does not carry.

| Priority | Accepted source | Frozen use | Accepted count/hash |
|---:|---|---|---|
| 1 | M2.10 portfolio-performance contract | Current account state, KPI values, queue position, payment performance, exception posture, exposure, and servicing burden | 59 account rows; 72 KPI rows; 3 queue rows; hash `24fca7263a04397ebf21d30639f9069b` |
| 2 | M1.17 G2 integrated consumption boundary | Application-level risk, loss, economics, acquisition, and scenario context | 1,500 scenario/application rows; hash `7d9e466da28cad2551aa99c4c40c912b` |
| 3 | M2.2 pricing-and-structure candidate inventory | The only permitted candidate terms for challenger selection and re-ranking | 557 candidate rows; hash `bbe83b187b31ea561789797322031fc6` |
| 4 | M2.4 booking/funding/activation contract | Accepted final activation disposition and booked/funded structure | 1,500 rows; hash `117450a3eea7bb3d3c74d18cc3c8e96a` |
| 5 | M2.7 operational-activation contract | Accepted intervention posture, setup queue, payment factor, and reassessment timing | 59 rows; hash `c8e3a472afd2a16b1183677324e9db98` |

## Frozen physical source objects

### Primary M2.10 sources

```text
msbf_ctl.m2_10_portfolio_analytics_contract_registry
msbf_m2.application_portfolio_performance_latest
msbf_m2.portfolio_kpi_snapshot
msbf_m2.servicing_queue_analytics_snapshot
```

### Supplemental accepted sources

```text
msbf_m1.v_m1_17_g2_integrated_consumption
msbf_m2.application_pricing_structure_candidate
msbf_m2.application_booking_funding_activation_latest
msbf_m2.application_operational_activation_latest
```

The M1.17 integrated view is permitted because it is the accepted G2 consumption interface. Its physical registry and accepted G2 hash remain the governing lineage anchor.

## Explicitly excluded direct sources

M2.11 will not directly read M2.3, M2.5, M2.6, M2.8, or M2.9 business tables.

Those stages are already represented through accepted downstream contracts and row hashes. Reaching backward into them would:

- duplicate lineage;
- increase join multiplicity risk;
- create competing versions of the same state;
- weaken the accepted contract hierarchy.

No source may be added later merely because it is convenient. A new source family would require an explicit design-freeze amendment.

---

# 5. Frozen source-materialization rules

During the future generation program:

1. Each accepted source family will be read and materialized once.
2. Source snapshots will preserve upstream contract codes, versions, schema identities, row hashes, and combined hashes.
3. The M1.17 and M2.4 application sources must join exactly one-to-one at:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
```

4. M2.10 and M2.7 account sources must join exactly one-to-one for the 59 accepted operational accounts.
5. M2.2 candidate rows must retain their accepted candidate-template identity and accepted candidate hash.
6. Every materialized source will be indexed and analyzed before downstream evaluation.
7. No accepted upstream blueprint, candidate structure, risk calculation, loss calculation, economic calculation, activation result, payment event, or KPI will be regenerated.
8. Any source-count, source-hash, grain, orphan, or multiplicity discrepancy will block preflight or generation.

---

# 6. Frozen strategy method

M2.11 will not invent a new offer or price. It may only **re-rank and select among the 557 accepted M2.2 candidate structures**.

The future selection sequence is frozen as:

```text
Accepted source verification
→ hard-constraint evaluation
→ candidate feasibility classification
→ strategy-specific objective scoring
→ deterministic within-strategy candidate ranking
→ selected candidate or preserved non-access outcome
→ scope-level strategy summary
→ Pareto-dominance evaluation
→ governance-review frontier
```

## Deterministic tie-break order

When two candidates are otherwise equivalent, selection will use this fixed order:

```text
1. Lowest hard-constraint violation count
2. Highest feasibility rank
3. Best strategy-specific objective score
4. Accepted M2.2 candidate rank
5. Candidate template code
6. Candidate row hash
```

Database row order will never determine selection.

## Baseline control

`BASELINE_REPLAY` must exactly reproduce the accepted source posture. It is the no-change control for the entire module.

A difference between baseline replay and the accepted M2.2/M2.4 source outcome is a blocking defect, not a strategy result.

---

# 7. Frozen strategy profiles

Exactly eight strategy profiles are authorized.

| Code | Frozen purpose |
|---|---|
| `BASELINE_REPLAY` | Exact reproduction of accepted candidate selection, final decision, and activation posture |
| `ACCESS_EXPANSION` | Tests additional access only among governed counteroffer-review candidates; policy declines and insufficient-evidence records remain inaccessible |
| `PRICE_FOR_RISK` | Prefers accepted candidates with stronger finance-charge economics when eligibility, burden, evidence, and profitability constraints remain satisfied |
| `PAYMENT_BURDEN_RELIEF` | Prefers lower remittance burden or longer accepted collection horizon while retaining valid economics |
| `LOSS_CONTAINMENT` | Prefers lower selected amount and lower expected-loss density, accepting reduced access where necessary |
| `PROFITABILITY_DISCIPLINE` | Prefers positive risk-adjusted contribution, annualized return, and economic-hurdle compliance |
| `EARLY_INTERVENTION` | Simulates bounded reassessment timing or payment-factor treatment for eligible active/review accounts using accepted M2.7 and M2.10 evidence |
| `BALANCED_FRONTIER` | Applies constraints-first multi-objective scoring and may receive a governance-review priority only when non-dominated |

`BALANCED_FRONTIER` is not an automatically approved or deployed strategy.

---

# 8. Frozen objectives

Exactly eight objective definitions are authorized.

| Objective | Direction |
|---|---:|
| `ACCESS_RATE` | Maximize within hard constraints |
| `SELECTED_EXPOSURE_AMOUNT` | Strategy-dependent |
| `FINANCE_CHARGE_AMOUNT` | Maximize where burden and economics remain feasible |
| `EXPECTED_LOSS_DENSITY` | Minimize |
| `RISK_ADJUSTED_CONTRIBUTION` | Maximize |
| `ANNUALIZED_RISK_ADJUSTED_RETURN` | Maximize |
| `SERVICING_BURDEN_UNITS` | Minimize |
| `PAYMENT_BURDEN_RATE` | Minimize |

Strategy-specific weights may differ, but:

- objective definitions cannot change by scenario;
- an objective cannot override a hard constraint;
- weighted scores may rank feasible candidates but cannot determine Pareto dominance;
- raw and normalized objective values must both remain visible.

---

# 9. Frozen hard constraints

Exactly twelve hard-constraint families are authorized.

1. **Accepted-source identity**  
   All prerequisite statuses, contract identities, gates, counts, and hashes must match the accepted source.

2. **Accepted-candidate restriction**  
   A selected structure must exist in the accepted M2.2 candidate inventory.

3. **Policy-decline preservation**  
   A policy-decline outcome cannot be overturned.

4. **Insufficient-evidence preservation**  
   Insufficient evidence cannot be interpreted as favorable access.

5. **Structure bounds**  
   Selected amount cannot exceed requested amount or accepted candidate bounds.

6. **Affordability integrity**  
   Price or contribution cannot cure a hard affordability or capacity failure.

7. **Economic evidence**  
   Required economics must be present, valid, and evidence-gated.

8. **Exception and certification integrity**  
   Unresolved exceptions or blocked certification prevent an access or intervention recommendation.

9. **Servicing eligibility**  
   Servicing strategy applies only to funded, active, or controlled-review accounts.

10. **Closed-state preservation**  
    Closed-stable accounts remain no-action accounts.

11. **Stress non-improvement**  
    Stress cannot improve underlying eligibility, access rank, source risk, risk density, return, or workload. A more conservative stress response may reduce exposure or burden, but it must be labeled as a strategy restriction—not as source improvement.

12. **Non-production boundary**  
    No strategy may cause a real decision, account update, payment change, funds movement, external call, merchant contact, collection, legal action, or notice.

---

# 10. Frozen scenario and scope treatment

The accepted application population contains:

```text
750 distinct applications
× 2 accepted scenarios
= 1,500 scenario/application rows
```

M2.11 will retain both scenarios:

```text
BASELINE
RECESSION_ENERGY
```

Exactly three strategy-reporting scopes are frozen:

```text
BASELINE
RECESSION_ENERGY
PORTFOLIO
```

`PORTFOLIO` will not sum the two scenarios and double-count applications. It will be a conservative matched rollup containing one deterministic worst-case record per distinct application.

The portfolio rollup will therefore preserve:

```text
750 distinct applications
```

rather than treating 1,500 scenario projections as 1,500 separate merchants.

Acquisition, identity, and other scenario-invariant fields must remain identical across matched scenarios. Risk, economics, access, candidate feasibility, and strategy results may differ only through accepted scenario-specific source evidence and frozen strategy logic.

---

# 11. Frozen physical grains and expected counts

## Control and definition layer

| Frozen object | Grain | Expected rows |
|---|---|---:|
| `msbf_ctl.m2_11_policy_profile` | Run | 1 |
| `msbf_m2.portfolio_strategy_profile` | Run × strategy | 8 |
| `msbf_m2.portfolio_strategy_objective_definition` | Run × objective | 8 |
| `msbf_m2.portfolio_strategy_constraint_definition` | Run × constraint | 12 |
| `msbf_m2.portfolio_strategy_reason_definition` | Run × reason | 32 |

## Accepted-source snapshots

| Frozen object | Grain | Expected rows |
|---|---|---:|
| `msbf_m2.portfolio_strategy_application_source_snapshot` | Run × scenario × application | 1,500 |
| `msbf_m2.portfolio_strategy_candidate_source_snapshot` | Run × scenario × application × candidate template | 557 |
| `msbf_m2.portfolio_strategy_account_source_snapshot` | Run × scenario × operational account | 59 |
| `msbf_m2.portfolio_strategy_kpi_source_snapshot` | Run × scope × KPI | 72 |
| `msbf_m2.portfolio_strategy_queue_source_snapshot` | Run × servicing queue | 3 |

## Simulation and frontier layer

| Frozen object | Grain | Expected rows |
|---|---|---:|
| `msbf_m2.application_strategy_candidate_evaluation` | Candidate source row × 8 strategies | 4,456 |
| `msbf_m2.application_portfolio_strategy_simulation` | 1,500 source rows × 8 strategies | 12,000 |
| `msbf_m2.account_servicing_strategy_simulation` | 59 operational accounts × 8 strategies | 472 |
| `msbf_m2.portfolio_strategy_summary` | 8 strategies × 3 scopes | 24 |
| `msbf_m2.portfolio_strategy_frontier` | 8 strategies × 3 scopes | 24 |
| `msbf_m2.portfolio_strategy_comparison` | 7 challengers versus baseline × 3 scopes | 21 |

## Contract layer

| Frozen object | Grain | Expected rows |
|---|---|---:|
| `msbf_m2.portfolio_strategy_simulation_latest` | Run × strategy × scope | 24 |
| `msbf_m2.portfolio_strategy_simulation_archive` | Run × contract version × strategy × scope | 24 |
| `msbf_ctl.m2_11_portfolio_strategy_contract_registry` | Run × contract version | 1 |

Frozen expected canonical-entity count:

```text
19,298
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

The canonical count excludes mutable evidence rows and acceptance-gate rows.

---

# 12. Frozen contract boundary

The M2.11 downstream contract is a **strategy-and-scope contract**, not an application-level contract.

Frozen contract grain:

```text
module1_run_id
+ strategy_profile_code
+ reporting_scope_code
```

Expected latest and archive count:

```text
8 strategies × 3 scopes = 24
```

Each contract row must expose at least:

- strategy and scope identity;
- source contract identities and hashes;
- application and account counts;
- access and preserved-decline counts;
- selected exposure;
- average payment burden;
- finance-charge amount;
- expected-loss amount and density;
- risk-adjusted contribution;
- annualized risk-adjusted return;
- servicing burden;
- hard-constraint violation count;
- dominated/non-dominated status;
- frontier rank;
- baseline delta;
- stress non-improvement flags;
- governance-review priority;
- strategy reason evidence;
- row and contract hashes.

The 12,000 application-strategy rows, 4,456 candidate evaluations, and 472 account-servicing simulations are supporting canonical evidence. They are not the ordinary downstream consumption contract.

---

# 13. Frozen validation architecture

The following counts are locked:

```text
Positive controls                         120
Negative controls                          20
Generation evidence rows                   24
Acceptance evidence rows                    1
Detailed-report result sets                24
Deterministic mismatch result sets          1
Blocking/stage-boundary result sets         1
```

Mandatory validation families include:

- accepted-source statuses, gates, counts, and hashes;
- source grain and one-to-one joins;
- baseline replay;
- candidate eligibility;
- policy-decline and insufficient-evidence preservation;
- strategy-profile and objective completeness;
- deterministic score and tie-break reconstruction;
- application, candidate, account, and scope reconciliations;
- stress non-improvement;
- objective-value reconstruction;
- Pareto-dominance reconstruction;
- latest/archive reproduction;
- archive immutability;
- canonical counts and combined hash;
- zero unauthorized production behavior.

A valid control will not be weakened merely to produce a pass.

---

# 14. Frozen program architecture

No SQL has been generated, but the program boundaries and numbering are frozen:

```text
212  Schema, policy, definitions, contracts, triggers, and views
213  Accepted-source and pristine-target preflight
214  Deterministic strategy simulation and physical reconciliation
215  Positive validation
216  Negative controls
217  Acceptance finalizer
218  Master report
219  Detailed report
```

Frozen recovery sequence:

```text
212A  Failed schema/policy installation recovery
214A  Failed pre-commit generation rollback-state recovery
214B  Committed-generation checkpoint reconstruction
215A  Failed-positive-validation recovery
```

Program 214 will be the only normal program authorized to persist simulation business rows.

Programs 215–219 will not regenerate the strategy blueprint.

---

# 15. Frozen stage boundaries

## M2.11 is authorized to create

- finite strategy profiles;
- objective and hard-constraint dictionaries;
- immutable accepted-source snapshots;
- accepted-candidate feasibility and ranking evidence;
- application-level counterfactual strategy outcomes;
- bounded account-servicing strategy simulations;
- portfolio and scenario strategy summaries;
- baseline/challenger comparisons;
- deterministic Pareto/frontier evidence;
- governance-review priorities;
- latest and immutable archive strategy contracts;
- M2.12-ready lineage.

## M2.11 is prohibited from creating or claiming

- a new offer structure not present in M2.2;
- recalculated PD, LGD, EAD, expected loss, or M1.14 economics;
- a production-optimal strategy;
- empirical or causal uplift;
- calibrated performance learning;
- autonomous strategy deployment;
- real account or payment changes;
- merchant contact;
- funds movement;
- production servicing action;
- collection, legal, or notice activity;
- CECL, capital allocation, warehouse funding, or economic-capital decisions;
- final Module 2 certification;
- G3 or Module 3 authorization.

---

# 16. Data sufficiency boundary

M2.10 contains 59 synthetic performance/account rows. That is sufficient for a governed strategy-simulation demonstration, but not for empirical optimization.

M2.11 may claim:

```text
Deterministic comparative strategy evidence
Scenario-specific tradeoffs
Constraint feasibility
Relative frontier position
Synthetic portfolio implications
```

It may not claim:

```text
Observed treatment effectiveness
Causal strategy uplift
Production optimization
Calibrated profitability improvement
Statistical generalization
Forecast accuracy
```

The 59-row performance population is a feedback signal within a synthetic learning system—not a production training sample.

---

# 17. M2.12 handoff boundary

After M2.11 is live-executed and accepted, M2.12 will independently certify:

- the complete M2.1–M2.11 chain;
- accepted source and strategy hashes;
- baseline replay;
- candidate and application reconciliation;
- strategy frontier and comparisons;
- latest/archive reproduction;
- final Module 2 consumption interface;
- final Module 2 evidence and release candidate.

M2.11 itself will not issue that final certification.

---

# 18. Freeze change control

The following are now frozen and require an explicit amendment before the M2.11 build:

- module identity and lifecycle;
- five accepted source families;
- exclusion of direct M2.3/M2.5/M2.6/M2.8/M2.9 sourcing;
- eight strategy profiles;
- eight objective definitions;
- twelve hard-constraint families;
- three reporting scopes;
- physical object grains;
- deterministic row counts;
- canonical count of 19,298;
- strategy-and-scope contract grain;
- 120 positive and 20 negative controls;
- Programs 212–219 and recovery boundaries;
- M2.12 as the final Module 2 certification stage.

Implementation-level choices that remain open—but may not alter the frozen semantics—are:

- physical column order;
- index names;
- temporary-table and CTE names;
- exact allocation of the 120 controls across control families;
- query formatting and comments;
- performance-tuning details;
- report wording and presentation order.

## Final freeze declaration

```text
M2.10 authoritative baseline          VERIFIED
M2.11 source hierarchy               FROZEN
M2.11 business purpose               FROZEN
M2.11 strategy framework             FROZEN
M2.11 objectives and constraints      FROZEN
M2.11 grains and expected counts      FROZEN
M2.11 contract boundary              FROZEN
M2.11 stage boundaries               FROZEN
M2.12 handoff boundary               FROZEN

SQL generated                            NO
Documentation package generated          NO
Manifest generated                       NO
ZIP generated                            NO
Accepted baseline modified               NO
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-a94f17aa-4a28-4799-ad16-1f0ff739cfbb"></a>
## Andrew / user · C080-M00543

C080-M00543 · 2026-08-04T23:09:18.464000-04:00 · active path

Preceding visible parent: [C080-M00542](part-19.md#m-c4a4c7c3-f299-4ae7-9fed-4d7339955429)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a strong design freeze and a much better foundation than the prior one-pass build attempts. The source hierarchy, stage boundaries, object grains, program sequence, expected counts, non-production boundary, and M2.12 handoff are coherent. The stated canonical count of **19,298** reconciles arithmetically. 

I would **not begin SQL yet**, however. A small **Design Freeze Amendment A** is needed because several implementation-affecting semantics remain open even though the document labels the design fully frozen.

## Items that still need to be locked

### 1. Exact strategy weight matrix

The freeze authorizes eight objectives and allows strategy-specific weights, but it does not specify the actual weights for each of the eight strategies.

That was one of the areas where the failed attempts began inventing scores during construction. Before implementation, lock an explicit matrix:

```text
8 strategies × 8 objectives
```

For every cell, define:

* weight;
* whether the objective is applicable;
* normalization method;
* missing-evidence treatment;
* direction transformation;
* score precision and rounding.

The SQL should implement a frozen scoring model—not design one while being written.

### 2. Objective normalization formulas

“Raw and normalized values remain visible” is correct, but the normalization mechanics are undefined.

Lock, for each objective:

* population over which min/max or reference values are calculated;
* handling when maximum equals minimum;
* handling of `NULL`, `PARTIAL`, and `BLOCKED` evidence;
* whether normalization occurs within strategy, scenario, or the full candidate population;
* target numeric type;
* rounding rule.

Without this, deterministic score reconstruction cannot be meaningfully validated.

### 3. Selected-exposure direction

`SELECTED_EXPOSURE_AMOUNT` is currently marked **strategy-dependent**.

That is acceptable for weighted scoring, but it is ambiguous for cross-strategy Pareto dominance. A Pareto objective needs one stable interpretation.

The amendment should choose one of these:

```text
A. Selected exposure is always maximized on the frontier;
B. Selected exposure is excluded from Pareto dominance and retained as
   a visible tradeoff metric; or
C. Separate access/exposure preservation and exposure containment
   objectives are defined.
```

I recommend **B**. Exposure is economically important, but larger is not universally better across access, profitability, and loss-containment strategies.

### 4. Exact PORTFOLIO worst-case selection

The freeze correctly prevents double-counting the two scenarios, but “one deterministic worst-case record per application” needs an exact ordering.

A suitable frozen hierarchy would be:

```text
1. Highest hard-constraint violation count
2. Worst preserved outcome/access rank
3. BLOCKED before PARTIAL before COMPLETE evidence
4. Highest expected-loss density
5. Lowest risk-adjusted contribution
6. Lowest annualized risk-adjusted return
7. Highest payment burden
8. Highest servicing burden
9. RECESSION_ENERGY before BASELINE as final deterministic tie-break
10. Physical row hash
```

The exact hierarchy can differ, but it must be fixed before Program 214.

### 5. The 32-reason catalog

The count is frozen at 32, but the actual reason codes, descriptions, families, severity, applicability, and production-boundary flags are not enumerated.

That catalog affects:

* physical seed data;
* reason-set hash;
* simulation output;
* validation;
* reports;
* contract interpretation.

It should be frozen before schema generation.

### 6. Stress non-improvement interpretation

The current wording could become internally contradictory:

```text
Stress cannot improve workload
```

while also allowing a conservative stress strategy to reduce exposure or burden.

Total workload can legitimately decline under stress because fewer accounts receive access. That is not necessarily favorable source performance.

The amendment should distinguish:

```text
Source improvement
≠
strategy restriction
≠
absolute workload reduction
```

I recommend validating stress non-improvement on matched records using:

* access rank;
* feasibility rank;
* source risk;
* expected-loss density;
* return;
* burden conditional on comparable treatment.

Total workload reduction caused by restricted access should remain visible but not be treated as an improvement violation.

## Additional implementation definitions worth locking

The amendment should also specify:

* exact feasibility classes and their rank;
* exact outcome/access severity order;
* exact baseline-replay source fields;
* treatment of applications with no accepted M2.2 candidate;
* profitability evidence requirements;
* candidate-score tie precision;
* Pareto equality tolerance;
* frontier-rank method;
* governance-review-priority rules;
* whether more than one strategy may receive priority;
* archive contract version and immutability-trigger behavior.

## Assessment

```text
Authoritative baseline                         LOCKED
Business purpose                               LOCKED
Source hierarchy                               LOCKED
Strategy identities                            LOCKED
Physical grains and counts                     LOCKED
Stage and production boundaries                LOCKED
Program architecture                           LOCKED

Scoring semantics                              NOT FULLY LOCKED
Portfolio rollup ordering                      NOT FULLY LOCKED
Pareto treatment                               NOT FULLY LOCKED
Reason dictionary                              NOT FULLY LOCKED
Stress interpretation                          NOT FULLY LOCKED
```

The freeze is approximately **90% complete** and is structurally excellent. The remaining 10% contains the exact areas most likely to produce redesign, inconsistent controls, or a predetermined champion during SQL construction.

The next action should be a narrowly bounded **M2.11 Source & Design Freeze Amendment A** addressing only these semantic gaps. After that amendment is approved, Work Package 2 can build Programs **212–214** without reopening business design.
<!-- END_SOURCE_MESSAGE -->
