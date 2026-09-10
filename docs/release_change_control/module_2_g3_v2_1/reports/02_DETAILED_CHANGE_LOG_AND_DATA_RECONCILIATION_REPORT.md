# MSBF Module 1/2 v2.1 Technical Successor
## Detailed Change Log and Data Reconciliation Report

**Report date:** 2026-09-04  
**Report version:** R1  
**Public comparator:** Module 2 / G3 v2.0.0  
**Accepted technical successor:** R26 M2.5-M2.12/G3-v2  
**Independent decision:** `IA-D-R15-M12-001` - `PASS_WITH_OBSERVATIONS`

> **Status boundary**  
> This report uses **v2.1** as the working stable-release family for the accepted R26 technical successor. The exact final public tag, Git commit, and release title are **not yet frozen**. Public Module 2 / G3 v2.0.0 remains controlling until a version-separated R26 repository/Power BI candidate passes bounded integration audit and an explicit release action activates supersession.


## 1. Purpose and scope

This report governs the substantive comparison between the previously published Module 1/G2 and Module 2/G3 v2.0.0 release and the accepted R26 technical successor intended for a future v2.1 release family. It answers four questions:

1. What business and code logic changed?
2. What data populations and outcomes changed?
3. Which changes are corrections, policy calibrations, source adaptations, or presentation decisions?
4. Why can each reported difference be trusted?

The report covers Module 1 nonregression; M2.1-M2.4 strategy and activation changes; M2.5-M2.10 Wave A reconstruction and R26 calibration; M2.11/M2.12 strategy simulation and G3-v2 certification; the pre-R26 R23 repository candidate; and the current P01-P04 Power BI publication scope.

It does not claim that the exact final v2.1 Git tree, release tag, or hosted assets exist. Those remain downstream integration and release gates.

## 2. Authority hierarchy and release state

| Layer | Identity / status | Interpretation |
| --- | --- | --- |
| Public predecessor | v2.0.0; Git HEAD `46fb1f9198475678edc9cabdeefd2f91a59e49c2` | Still controlling public authority. |
| Wave A successor | R17 M2.5-M2.10 | Accepted predecessor rebuild for the 130-path population. |
| Wave B successor | R19 M2.11/M2.12/G3-v2 | Accepted predecessor simulation/certification. |
| Pre-R26 repository candidate | R23 / `v2.1.0-rc2`; HEAD `58b4dbda229d7176431cb09eecd1e3e3ec1feeee` | Accepted pre-R26 repository/Power BI baseline; not the final R26 integration. |
| Current technical successor | R26; result `113450c7...4096c3` | Accepted under IA-D-R15-M12-001. |
| Permitted next step | IA-INT-R15-R26-001 | Build and audit one version-separated R26 integration candidate. |
| Publication / supersession | Not authorized | Requires a later explicit action after audit. |

## 3. Executive change map

| Stage / layer | Prior public state | Successor state | Classification |
| --- | --- | --- | --- |
| M1.1-M1.17 | Accepted public predecessor | No business-logic or accepted-stage change. | NONREGRESSION |
| M2.1 | Shallow routing could classify structure-remediable FAIL/REVIEW paths before comprehensive search. | Routing explicitly distinguishes evidence declines, policy hard stops, structure-remediable cases, counteroffer review, manual underwriting review and approval. | BUSINESS_LOGIC_CORRECTION |
| M2.2 | 557 candidate structures; 249 selected structures across 183 applications. | 6,519 reportable candidates, 6,397 exact-search candidates and 122 requested-structure references; search runs before no-feasible disposition. | BUSINESS_LOGIC_EXPANSION |
| M2.3 | Four final outcome classes: authorized offer, counteroffer review, insufficient evidence, policy decline. | Seven final classes with explicit authorized counteroffer, manual review, no-feasible proof and policy hard stop. | TAXONOMY_AND_AUTHORITY_REFINEMENT |
| M2.4 | 59 activated paths; $667,600 synthetic funded amount. | 130 activated paths; $1,729,500 synthetic funded amount; 103 Baseline and 27 Recession Energy. | DOWNSTREAM_RECOMPUTATION |
| M2.5-M2.10 / R17 | Population-specific assumptions and accepted-output hashes embedded around the 59-path predecessor. | Versioned source transforms rebind exact R6 identities, remove population-bound assumptions, preserve stable keys and reconstruct 130-path outputs. | PORTABILITY_AND_IDENTITY_CORRECTION |
| M2.8 | Retry amount rounded after multiplying the unrounded factor result. | Scheduled cent amount is rounded before the retry multiplier; merchant 749 becomes exactly reconciled. | DETERMINISTIC_ROUNDING_CORRECTION |
| M2.9-M2.10 | Exact-zero certification and terminal-state comparisons operated on predecessor population. | Exact-zero controls retained; terminal states exempted from false matched-scenario improvement flags; state/reconciliation-based downstream mapping replaces brittle dollar-signature logic. | CONTROL_CORRECTION |
| M2.5 / R26 | Pace WATCH began day 7 and pace-adverse states day 14; expected pace used the former implied daily collection basis. | Monitoring begins at first expected remittance; expected pace = selected total repayment / selected horizon; pace WATCH day 21, adverse day 30, three-day persistence. Early hard triggers remain. | OWNER_APPROVED_POLICY_CALIBRATION |
| M2.5 / R26 | Raw alert conditions were presented without a separate operational family layer. | Raw alerts remain intact and are consolidated separately into PACE, NO_REMITTANCE, SALES_DORMANCY, LIQUIDITY and HORIZON families. | SEMANTIC_LAYER_ADDITION |
| M2.6-M2.10 / R26 | R17 successor outputs after the 130-path rebuild. | No business-output change from R17; only source identity rebinding where applicable. | EXACT_NONREGRESSION |
| M2.11 | 557 candidate source rows, 4,456 candidate evaluations, 59 account paths and 472 account simulations. | 6,519 candidates, 52,152 evaluations, 12,000 application simulations and 1,040 account simulations. Eight-profile method preserved; source and semantic identity updated. | SOURCE_ADAPTATION_AND_SCALE |
| M2.12 / G3-v2 | Original G3 certification bound to v2.0 source and report identities. | 70/70 successor controls certify R4 decision, R6 activation, R26 operations, M2.11 simulations, source root, Power BI bundle and report root. | SUCCESSOR_RECERTIFICATION |
| P01-P04 | Predecessor pages reflected 59 funded paths and the original four-class decision taxonomy. | P01-P04 use the seven-class decision fact, 130 funded lifecycle paths, 15,600-row calibrated monitoring, plain-language narratives and current source identity. | CONSUMPTION_AND_PRESENTATION_UPDATE |
| P05-P06 | R23 candidate exposed eight strategy-profile comparison pages. | Current public showcase is held because profiles alter governed candidate/terms but do not produce decision migration in R26. | PUBLICATION_SCOPE_HOLD |
| R23 -> R26 integration | Public HEAD 46fb1f...; 1,934 files; v2.0.0 remains controlling. | R23 pre-R26 candidate added version-separated source, evidence, docs and Power BI. Final R26 repository integration is still pending. | VERSION_SEPARATED_INTEGRATION_PENDING |

The complete machine-readable version is `registers/01_STAGE_CODE_LOGIC_CHANGE_REGISTER.csv`.

## 4. Module 1 / G2 nonregression

Module 1 remains the fixed evidence foundation. The successor does not rewrite the 750 applications, the two scenario environments, feature availability, cash-flow history, capacity, resilience, risk, loss, or unit economics. This separation is essential: the purpose of the successor is to correct and extend downstream strategy and lifecycle behavior, not to manufacture a more favorable upstream population.

Controls supporting that conclusion include:

- zero accepted-stage-directory changes in the R23 repository candidate;
- byte-exact accepted-chain, stage-index, source-classification, and release-metadata files;
- use of `module1_run_id`, scenario-qualified application identity, and accepted source hashes throughout the successor;
- source nonmutation checks before and after every compiler/final or resume cycle.

## 5. M2.1-M2.3: strategy correction

### 5.1 Business defect addressed

The predecessor strategy could stop too early on structure-remediable cases. A broad `DECLINE_POLICY_AUTHORIZED` category therefore included materially different situations: genuine hard stops, evidence limitations, cases where search had not found a feasible structure, and cases for which a governed alternative could be reviewed or authorized.

The successor requires candidate search before a no-feasible conclusion for decisionable, structure-remediable FAIL or REVIEW paths. It preserves evidence declines and hard stops; it does not use favorable pricing or economics to cure missing evidence or immutable policy constraints.

### 5.2 Owner-approved strategy controls

| Control | Successor rule |
| --- | --- |
| Minimum counteroffer amount | 40% of requested amount |
| Maximum exposure reduction | 60% |
| Supported payoff horizons | 30 / 60 / 90 days |
| Economic hurdle | Required |
| Selection method | Dual frontier; authority first |
| Automatic repayment-cost increase | 0% |
| Review repayment-cost increase | Maximum 2% |
| Rounding tolerance | $0.01 |
| Strict risk / resilience tier | 2 / 2 |
| Review risk / resilience tier | 3 / 3 |
| Custom profile | Only through explicit hashed selection |

### 5.3 Candidate search and proof populations

| Population | Prior v2.0.0 | Successor | Interpretation |
| --- | --- | --- | --- |
| Application-scenario rows | 1,500 | 1,500 | Same comparison population |
| Candidate structures | 557 | 6,519 | Expanded governed search |
| Exact-search candidates | Not separately reported | 6,397 | Candidate alternatives generated by search |
| Requested references | Not separately reported | 122 | Requested-structure reference rows |
| Decision-gate rows | Not separately materialized | 84,228 | Constraint-by-candidate evidence |
| No-feasible proof rows | No separate proof population | 652 | Explicit failed-search evidence |

### 5.4 Seven-class decision taxonomy

| Scenario | Approve as requested | Counteroffer authorized | Counteroffer review | Underwriting review | Evidence decline | No feasible | Hard stop |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Baseline | 92 | 11 | 174 | 23 | 43 | 290 | 117 |
| Recession Energy | 23 | 4 | 38 | 15 | 191 | 362 | 117 |
| Total | 115 | 15 | 212 | 38 | 234 | 652 | 234 |

The seven classes reconcile to 1,500 paths. They are not a simple renaming of the four predecessor classes; the authoritative bridge is the full migration matrix.

### 5.5 Predecessor-successor migration matrix

| Predecessor outcome | Successor outcome | Rows | Share of predecessor |
| --- | --- | --- | --- |
| COUNTEROFFER_REVIEW_REQUIRED | COUNTEROFFER_REVIEW_REQUIRED | 71 | 37.4% |
| COUNTEROFFER_REVIEW_REQUIRED | APPROVE_AS_REQUESTED_AUTHORIZED | 56 | 29.5% |
| COUNTEROFFER_REVIEW_REQUIRED | MANUAL_UNDERWRITING_REVIEW_REQUIRED | 38 | 20.0% |
| COUNTEROFFER_REVIEW_REQUIRED | COUNTEROFFER_AUTHORIZED | 13 | 6.8% |
| COUNTEROFFER_REVIEW_REQUIRED | DECLINE_NO_FEASIBLE_STRUCTURE | 12 | 6.3% |
| DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED | DECLINE_INSUFFICIENT_EVIDENCE | 177 | 99.4% |
| DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED | DECLINE_NO_FEASIBLE_STRUCTURE | 1 | 0.6% |
| DECLINE_POLICY_AUTHORIZED | DECLINE_NO_FEASIBLE_STRUCTURE | 639 | 59.6% |
| DECLINE_POLICY_AUTHORIZED | DECLINE_POLICY_HARD_STOP | 234 | 21.8% |
| DECLINE_POLICY_AUTHORIZED | COUNTEROFFER_REVIEW_REQUIRED | 141 | 13.1% |
| DECLINE_POLICY_AUTHORIZED | DECLINE_INSUFFICIENT_EVIDENCE | 57 | 5.3% |
| DECLINE_POLICY_AUTHORIZED | COUNTEROFFER_AUTHORIZED | 2 | 0.2% |
| FINAL_OFFER_AUTHORIZED | APPROVE_AS_REQUESTED_AUTHORIZED | 59 | 100.0% |

Key interpretation:

- All 59 predecessor authorized offers remain supportable and become `APPROVE_AS_REQUESTED_AUTHORIZED`.
- The 190 predecessor counteroffer-review rows split into 56 approvals, 13 authorized counteroffers, 71 counteroffer reviews, 38 manual reviews, and 12 no-feasible outcomes.
- The 1,073 predecessor policy declines split into 234 genuine hard stops, 639 no-feasible outcomes, 141 counteroffer reviews, 57 evidence declines, and 2 authorized counteroffers.
- The migration does not imply all changed outcomes are improvements. It separates authority, evidence, and feasibility correctly.

### 5.6 Change-classification control

| Classification | Rows | Share |
| --- | --- | --- |
| EXPECTED_CHANGE_STRATEGY_OR_DEFECT_CORRECTION | 981 | 65.4% |
| UNCHANGED_EVIDENCE_OUTCOME_RECODED | 177 | 11.8% |
| EXPECTED_CHANGE_COUNTEROFFER_STRATEGY | 143 | 9.5% |
| UNCHANGED_EXACT | 71 | 4.7% |
| EXPECTED_CHANGE_AUTHORITY_REFINEMENT | 69 | 4.6% |
| EXPECTED_CHANGE_OFFER_SEMANTIC_REFINEMENT | 59 | 3.9% |

These classifications preserve traceability between intended taxonomy refinement, counteroffer strategy change, offer semantics, authority refinement, and unchanged evidence outcomes.

## 6. M2.4: activation and funding reconciliation

The corrected decision population drives a new M2.4 R6 activation result. The stage is not allowed to invent funding: it consumes only authorized final decisions and carries the exact selected amount, remittance rate, payback multiple and horizon.

| Measure | Prior v2.0.0 | Successor | Delta |
| --- | --- | --- | --- |
| Funded paths | 59 | 130 | +71 (120.3%) |
| Baseline funded paths | 44 | 103 | +59 (134.1%) |
| Recession Energy funded paths | 15 | 27 | +12 (80.0%) |
| Total funded amount | $667,600.00 | $1,729,500.00 | +$1,061,900.00 (159.1%) |
| Baseline funded amount | $472,000.00 | $1,385,300.00 | +$913,300.00 (193.5%) |
| Stress funded amount | $195,600.00 | $344,200.00 | +$148,600.00 (76.0%) |

The physical activation layer contains:

| Activation outcome | Rows |
| --- | --- |
| ACTIVATION_REVIEW_REQUIRED | 250 |
| BOOKED_FUNDED_PORTFOLIO_ACTIVATED | 130 |
| NOT_ACTIVATED_INSUFFICIENT_EVIDENCE | 234 |
| NOT_ACTIVATED_POLICY_DECLINE | 886 |

R6 passes 120/120 positive controls, 20/20 negative controls, the acceptance gate, zero term mismatches, zero matched-scenario activation improvements, and zero matched-scenario amount improvements.

## 7. M2.5-M2.10: population-portable reconstruction

### 7.1 Why the chain was rebuilt

The predecessor M2.5-M2.10 code and identities were bound to the 59-path population and its accepted hashes. The successor needed to consume 130 activated paths without modifying the public predecessor. The correct implementation was a versioned compiler/final reconstruction from immutable R6.

### 7.2 Source-file change inventory

| Stage | Component | Accepted predecessor file | Successor file | Line diff | Policy change |
| --- | --- | --- | --- | --- | --- |
| M2.5 | SCHEMA | M2_5_SCHEMA__01_164_schema_policy.sql | M2_5_SCHEMA.sql | +2/-2 | False |
| M2.5 | GEN | M2_5_GEN__03_166_generation.sql | M2_5_GEN.sql | +7/-177 | False |
| M2.6 | SCHEMA | M2_6_SCHEMA__01_172_schema_policy.sql | M2_6_SCHEMA.sql | +35/-5 | False |
| M2.6 | GEN | M2_6_GEN__03_174_generation.sql | M2_6_GEN.sql | +4/-4 | False |
| M2.7 | SCHEMA | M2_7_SCHEMA__01_180_schema_policy.sql | M2_7_SCHEMA.sql | +29/-42 | False |
| M2.7 | GEN | M2_7_GEN__03_182_generation_v0_2R1.sql | M2_7_GEN.sql | +5/-137 | False |
| M2.8 | SCHEMA | M2_8_SCHEMA__01_188_schema_policy.sql | M2_8_SCHEMA.sql | +37/-24 | False |
| M2.8 | GEN | M2_8_GEN__03_190_generation.sql | M2_8_GEN.sql | +8/-8 | False |
| M2.9 | SCHEMA | M2_9_SCHEMA__01_196_schema_policy.sql | M2_9_SCHEMA.sql | +38/-29 | False |
| M2.9 | GEN | M2_9_GEN__03_198_generation.sql | M2_9_GEN.sql | +10/-10 | False |
| M2.10 | SCHEMA | M2_10_SCHEMA__01_204_schema_policy_executed_v0_2.sql | M2_10_SCHEMA.sql | +30/-29 | False |
| M2.10 | GEN | M2_10_GEN__03_206_generation_v0_2R1.sql | M2_10_GEN.sql | +59/-391 | False |

Every `policy_change` value in the R17 source-diff register is false. Most differences are source-identity, cardinality, execution-state, payload-canonicalization, validation, or portability changes. The later R26 monitoring calibration is separately classified as an owner-approved policy change.

### 7.3 Deterministic one-cent correction in M2.8

The R12 failure isolated one account where retry rounding produced a +$0.01 reconciliation variance and -$0.01 exposure variance. The prior expression rounded only after multiplying by the retry multiplier. The successor first rounds the scheduled cent amount, then multiplies and rounds the retry.

```sql
-- predecessor ordering
ROUND(ROUND(exposure / duration, 2) * payment_factor * retry_multiplier, 2)

-- successor ordering
ROUND(ROUND(ROUND(exposure / duration, 2) * payment_factor, 2) * retry_multiplier, 2)
```

For merchant application 749, the corrected retry is $503.50, the processed total is $1,762.25, and both reconciliation variance and exposure variance are exactly zero. M2.9 and M2.10 exact-zero controls were not weakened.

### 7.4 Other engineering corrections

- Power BI export order is bound to projected columns rather than an unavailable `scenario_id` field.
- Run-generated `created_at` values are excluded from nested deterministic payload hashes, while business and lineage fields remain inside the payload.
- Diagnostic comparators distinguish fields that must match from fields that must differ.
- Terminal-state matched comparisons do not report false stress improvements when both paths are already terminal.
- M2.10 uses state/reconciliation semantics rather than brittle exact-dollar signature mapping.
- Compiler and final clones are separately created and required to reproduce normalized receipts and identities.

### 7.5 R17 validation

R17 produces:

| Stage | Physical rows |
| --- | --- |
| M2.5 daily monitoring | 15,600 |
| M2.6 intervention | 130 |
| M2.7 operational setup | 130 |
| M2.8 servicing execution | 130 |
| M2.9 certification | 130 |
| M2.10 portfolio performance | 130 |
| Validation controls | 115 / 115 PASS |

## 8. R26 monitoring calibration

### 8.1 Policy change

| Policy element | Pre-calibration | R26 calibrated |
| --- | --- | --- |
| Daily monitoring anchor | Synthetic monitoring day | First expected remittance |
| Expected pace basis | Former implied-daily collection field | Selected total repayment / selected horizon |
| PACE WATCH eligibility | Day 7 | Day 21 |
| PACE adverse eligibility | Day 14 | Day 30 |
| Persistence | No explicit consecutive-day requirement | 3 consecutive days |
| Pace thresholds | 90% / 75% / 50% | 90% / 75% / 50% - unchanged |
| Early no-remittance trigger | Present | Preserved |
| Early zero-sales trigger | Present | Preserved |
| Liquidity and horizon triggers | Present | Preserved |
| Raw flags | Present | Preserved |
| Operational alert families | Not separate | PACE / NO_REMITTANCE / SALES_DORMANCY / LIQUIDITY / HORIZON |

### 8.2 Field-level physical reconciliation

| Field | Different rows | Unchanged rows | Classification |
| --- | --- | --- | --- |
| cumulative_pace_ratio | 9,249 | 6,351 | BUSINESS_CALIBRATION_CHANGE |
| cumulative_shortfall_amount | 4,840 | 10,760 | BUSINESS_CALIBRATION_CHANGE |
| monitoring_status_code | 3,300 | 12,300 | BUSINESS_CALIBRATION_CHANGE |
| cumulative_pace_watch_alert_flag | 1,656 | 13,944 | BUSINESS_CALIBRATION_CHANGE |
| daily_shortfall_alert_flag | 1,084 | 14,516 | BUSINESS_CALIBRATION_CHANGE |
| cumulative_pace_high_alert_flag | 591 | 15,009 | BUSINESS_CALIBRATION_CHANGE |
| stress_status_floor_applied_flag | 216 | 15,384 | BUSINESS_CALIBRATION_CHANGE |
| actual_remittance_amount | 0 | 15,600 | EXACT_NONREGRESSION |
| cumulative_remittance_amount | 0 | 15,600 | EXACT_NONREGRESSION |
| horizon_overrun_alert_flag | 0 | 15,600 | EXACT_NONREGRESSION |
| liquidity_stress_alert_flag | 0 | 15,600 | EXACT_NONREGRESSION |
| merchant_application_id | 0 | 15,600 | EXACT_NONREGRESSION |
| module1_run_id | 0 | 15,600 | EXACT_NONREGRESSION |
| monitoring_date | 0 | 15,600 | EXACT_NONREGRESSION |
| monitoring_day_index | 0 | 15,600 | EXACT_NONREGRESSION |
| paid_off_flag | 0 | 15,600 | EXACT_NONREGRESSION |
| principal_exposure_proxy | 0 | 15,600 | EXACT_NONREGRESSION |
| receivable_balance_after | 0 | 15,600 | EXACT_NONREGRESSION |
| scenario_code | 0 | 15,600 | EXACT_NONREGRESSION |
| source_eligible_pos_sales | 0 | 15,600 | EXACT_NONREGRESSION |
| synthetic_advance_id | 0 | 15,600 | EXACT_NONREGRESSION |
| zero_sales_streak_alert_flag | 0 | 15,600 | EXACT_NONREGRESSION |

The changed fields are exactly those expected from the pace calculation and status calibration. The following remain unchanged across all 15,600 rows: application/scenario/day identity, monitoring date, source sales, actual remittance, cumulative remittance, receivable balance, principal exposure, zero-sales flag, liquidity flag, horizon flag, and paid-off flag.

### 8.3 Operational peak comparison

| Version | Scenario | Semantic scope | Peak accounts | Peak day | Share of paths |
| --- | --- | --- | --- | --- | --- |
| R17_PRE_CALIBRATION | BASELINE | WATCH_ONLY | 89 | 11 | 86.4% |
| R26_CALIBRATED | BASELINE | WATCH_ONLY | 30 | 30 | 29.1% |
| R17_PRE_CALIBRATION | BASELINE | ACTIONABLE_EXCLUDING_WATCH | 41 | 14 | 39.8% |
| R26_CALIBRATED | BASELINE | ACTIONABLE_EXCLUDING_WATCH | 20 | 33 | 19.4% |
| R17_PRE_CALIBRATION | RECESSION_ENERGY | WATCH_ONLY | 22 | 11 | 81.5% |
| R26_CALIBRATED | RECESSION_ENERGY | WATCH_ONLY | 4 | 29 | 14.8% |
| R17_PRE_CALIBRATION | RECESSION_ENERGY | ACTIONABLE_EXCLUDING_WATCH | 11 | 14 | 40.7% |
| R26_CALIBRATED | RECESSION_ENERGY | ACTIONABLE_EXCLUDING_WATCH | 4 | 32 | 14.8% |

The policy lowers early monitoring noise without deleting severe evidence. R26 independently passes 16/16 static policy checks and all 18 submitted physical checkpoints.

### 8.4 Endpoint nonregression

| Version | Scenario | Paths | Paid off | Severe shortfall | Other open statuses | Ending exposure |
| --- | --- | --- | --- | --- | --- | --- |
| R17_PRE_CALIBRATION | BASELINE | 103 | 99 | 4 | 0 | $7,823.28 |
| R17_PRE_CALIBRATION | RECESSION_ENERGY | 27 | 27 | 0 | 0 | $0.00 |
| R26_CALIBRATED | BASELINE | 103 | 99 | 4 | 0 | $7,823.28 |
| R26_CALIBRATED | RECESSION_ENERGY | 27 | 27 | 0 | 0 | $0.00 |

M2.6-M2.10 remain exact between R17 and R26:

| Stage | R17 rows | R26 rows | Shared columns | Different cells | Status |
| --- | --- | --- | --- | --- | --- |
| M2.6 | 130 | 130 | 13 | 0 | EXACT |
| M2.7 | 130 | 130 | 18 | 0 | EXACT |
| M2.8 | 130 | 130 | 23 | 0 | EXACT |
| M2.9 | 130 | 130 | 22 | 0 | EXACT |
| M2.10 | 130 | 130 | 19 | 0 | EXACT |

## 9. Portfolio-level data reconciliation

| Section | Measure | Prior v2.0.0 | Successor | Delta | Comparability |
| --- | --- | --- | --- | --- | --- |
| Population | Applications | 750 | 750 | 0.00 | DIRECT |
| Population | Scenarios | 2 | 2 | 0.00 | DIRECT |
| Population | Application-scenario paths | 1,500 | 1,500 | 0.00 | DIRECT |
| Decision strategy | Final outcome classes | 4 | 7 | 3.00 | TAXONOMY_EXPANSION |
| Decision strategy | Candidate structures evaluated | 557 | 6,519 | 5,962.00 | DIRECT |
| Decision strategy | Selected structures / search-bearing paths | 249 | 780 | 531.00 | RELATED_NOT_IDENTICAL |
| Decision strategy | Explicit no-feasible proof rows | N/A | 652 | N/A | NEW_CAPABILITY |
| Decision strategy | Decision-gate result rows | N/A | 84,228 | N/A | NEW_CAPABILITY |
| Activation | Funded application-scenario paths | 59 | 130 | 71.00 | DIRECT |
| Activation | Baseline funded paths | 44 | 103 | 59.00 | DIRECT |
| Activation | Recession Energy funded paths | 15 | 27 | 12.00 | DIRECT |
| Activation | Total synthetic funded amount | $667,600.00 | $1,729,500.00 | $1,061,900.00 | DIRECT |
| Activation | Baseline synthetic funded amount | $472,000.00 | $1,385,300.00 | $913,300.00 | DIRECT |
| Activation | Recession Energy synthetic funded amount | $195,600.00 | $344,200.00 | $148,600.00 | DIRECT |
| Lifecycle | Daily monitoring rows | 7,080 | 15,600 | 8,520.00 | DIRECT |
| Lifecycle | Opening receivable | $801,838.72 | $2,076,147.40 | $1,274,308.68 | DIRECT |
| Lifecycle | Cumulative 120-day remittance | $800,858.99 | $2,068,324.12 | $1,267,465.13 | DIRECT |
| Lifecycle | Ending exposure | $979.73 | $7,823.28 | $6,843.55 | DIRECT |
| Lifecycle | Ending exposure / opening receivable | 0.12% | 0.38% | 0.00 | DIRECT |
| Lifecycle | Paid-off paths | 57 | 126 | 69.00 | DIRECT |
| Lifecycle | Payoff rate | 96.61% | 96.92% | 0.00 | DIRECT |
| Strategy simulation | Candidate-profile evaluations | 4,456 | 52,152 | 47,696.00 | DIRECT |
| Strategy simulation | Application-profile simulations | 12,000 | 12,000 | 0.00 | DIRECT |
| Strategy simulation | Account-profile simulations | 472 | 1,040 | 568.00 | DIRECT |
| Certification | G3-v2 controls | N/A | 70 | N/A | NEW_CERTIFICATION |

Interpret ending exposure with scale context: the absolute residual rises from $979.73 to $7,823.28 because the portfolio more than doubles. The normalized residual is 0.12% versus 0.38% of opening receivable. The payoff rate remains approximately 97% (96.61% versus 96.92%).

## 10. M2.11 strategy simulation

### 10.1 Scale and identity

| Population | Prior v2.0.0 | R26 |
| --- | --- | --- |
| Strategy profiles | 8 | 8 |
| Candidate structures | 557 | 6,519 |
| Candidate-profile evaluations | 4,456 | 52,152 |
| Application-profile simulations | 12,000 | 12,000 |
| Operational account paths | 59 | 130 |
| Account-profile simulations | 472 | 1,040 |
| Portfolio summary | 24 | 24 |
| Portfolio frontier | 24 | 24 |
| Portfolio comparison | 21 | 21 |

The eight-profile method is preserved. R26 changes the physical source population and semantic source identity; it does not silently change the profile-selection method.

### 10.2 Public interpretation control

| Question | Physical answer | Publication consequence |
| --- | --- | --- |
| Do profiles change high-level decisions? | 0 of 1,500 application-scenario paths show profile outcome migration. | Do not call the current pages a full strategy challenger. |
| Do profiles change selected candidates? | 249 paths; 65.5% of candidate-bearing paths. | Valid offer/terms optimization evidence. |
| Do profiles change selected amounts? | 247 paths. | Valid terms tradeoff evidence. |
| Does Early Intervention change account treatment? | 4 of 1,040 account-profile rows; no exposure or payment-factor change. | Bounded account-treatment evidence only. |

P05/P06 are therefore held from the present public Power BI showcase, while the technical evidence remains preserved.

## 11. M2.12 / G3-v2 successor certification

R26 certifies a new source/report identity rather than reusing v2.0.0 hashes. The final physical populations are:

| Certified population | Rows / result |
| --- | --- |
| Strategy profiles | 8 |
| Candidate evaluations | 52,152 |
| Application simulations | 12,000 |
| Account simulations | 1,040 |
| Portfolio summaries | 24 |
| Portfolio frontiers | 24 |
| Portfolio comparisons | 21 |
| G3-v2 certification controls | 70 / 70 PASS |

The accepted R26 identities are listed in `registers/10_IDENTITY_AND_HASH_REGISTER.csv`.

### 11.1 R2 failure and retained-final resume

The first R26 R2 runtime correctly remains a failed record because compiler and final M2.11 simulation identities differed. Independent comparison showed the M2.5-M2.10 business exports were byte-identical; only execution metadata contaminated the semantic identity boundary.

The accepted resume:

- verifies the exact retained R2 final database;
- proves nine Wave A exports exact before cloning;
- clones the retained final without modifying it;
- executes only M2.11/M2.12/G3-v2;
- reproduces the nine Wave A exports afterward;
- confirms immutable R6 and retained R2 nonmutation.

This is why R2 remains FAIL provenance while the resume result is the accepted technical successor execution evidence.

## 12. Power BI changes and publication scope

The successor Power BI source now uses:

- the seven-class final-decision fact;
- the 130-row funded-lifecycle object (103 Baseline, 27 Recession Energy);
- the 15,600-row R26 monitoring fact;
- plain-language P03 narratives based on source-owned facts;
- P03 semantic QA of 2 scenario-isolation rows PASS, 0 genuine failures, and 1,500 unique application-scenario paths PASS;
- P01-P04 completed and tested.

DAX and Power Query do not reconstruct eligibility, candidate feasibility, final authority, funding, monitoring, or lifecycle truth.

Current publication scope:

| Page | Disposition | Reason |
| --- | --- | --- |
| P01 - Executive Portfolio Command Center | Retain | Executive portfolio posture |
| P02 - Cohort Lifecycle | Retain | Funded-cohort lifecycle |
| P03 - Application Journey | Retain | Decision proof and narrative |
| P04 - Servicing & Exceptions | Retain | Operational monitoring and intervention |
| P05 - Economics & Value Creation | Hold | Strategy profiles not yet a full decision challenger |
| P06 - Strategy & Decision Effectiveness | Hold | Avoid overstating profile functionality |

## 13. Repository and documentation delta

The R23 pre-R26 candidate demonstrates the intended version-separated integration pattern:

| Measure | R23 result |
| --- | --- |
| Base HEAD | 46fb1f9198475678edc9cabdeefd2f91a59e49c2 |
| Candidate HEAD | 58b4dbda229d7176431cb09eecd1e3e3ec1feeee |
| Candidate commits from base | 2 |
| Changed paths | 508 |
| Added paths | 501 |
| Modified paths | 7 |
| Accepted M2.1-M2.12 stage changes | 0 |
| Public-release validator | PASS |
| Candidate-overlay validator | PASS |
| Patch apply/reproduction | PASS |

Category summary:

| Category | Git status | Paths | Final R26 status |
| --- | --- | --- | --- |
| R23_RC1_PRESERVED_HISTORY | A | 238 | PENDING |
| R23_RC2_CONTROL_METADATA | A | 9 | PENDING |
| R23_RC2_DOCUMENTATION | A | 14 | PENDING |
| R23_RC2_EVIDENCE | A | 17 | PENDING |
| R23_RC2_POWER_BI | A | 174 | PENDING |
| R23_RC2_SOURCE | A | 48 | PENDING |
| ROOT_NAVIGATION_OR_MANIFEST | A | 1 | PENDING |
| ROOT_NAVIGATION_OR_MANIFEST | M | 7 | PENDING |

The final R26-integrated repository must be rebuilt from exact R26 identities. The R23 candidate is not simply relabeled as final v2.1 because the monitoring policy, source root, Power BI source bundle, report root and certification all changed after R23.

## 14. Why the reconciliation is accurate

### 14.1 Stable grains

Every major comparison is performed at a governed key:

- strategy: `module1_run_id + scenario_id + merchant_application_id`;
- candidate: add candidate ID/template;
- activation and account: application-scenario plus account/advance;
- monitoring: application-scenario plus monitoring day;
- strategy profile: application-scenario or account plus profile code.

### 14.2 Full-population comparison

No outcome conclusion is based on a sample. The decision migration covers all 1,500 paths, monitoring comparison covers all 15,600 daily rows, and M2.6-M2.10 comparisons cover every 130-row stage output.

### 14.3 Independent identities

Rows, ordered sets, source bundles, controls, reports and certifications are bound to SHA-256 or governed set hashes. The focused audit independently recomputed the critical R26 roots.

### 14.4 Exact arithmetic

Counts are direct row counts; funded amounts and receivables are direct sums; rates are explicit ratios; migration percentages are row counts divided by predecessor-row totals. The validation script re-performs these formulas.

### 14.5 Failed history is preserved

R12-R16 and R26 R2 are not hidden. Their failure class, last stage and retained/dropped databases remain part of provenance. A PASS is assigned only to the accepted final result.

## 15. Limitations and open gates

| Finding | Boundary | Required treatment | Status |
| --- | --- | --- | --- |
| VERSION_LABEL | The term v2.1 is a working stable-release family label; the final tag/title are not frozen. | Decide only after the integrated R26 repository/Power BI/history/visual candidate is frozen. | OPEN_RELEASE_GATE |
| PUBLIC_AUTHORITY | Public v2.0.0 remains controlling. R26 is accepted technically but is not yet public. | Preserve v2.0.0 until bounded integration audit and explicit supersession. | GATED |
| FINAL_GIT_DIFF | The exact final R26-integrated Git tree and commit do not yet exist. | Use this report as the governing technical change specification; generate final file-level diff after integration. | PENDING |
| R4_GENERATOR_SOURCE | Original R4 generator source was not packaged; outputs, contracts, policy, receipts and independent replay are available. | Retain observation R23-O-001 and recover generator bytes if later found; do not reconstruct silently. | NONBLOCKING_OBSERVATION |
| R26_R2_PROVENANCE | R26 R2 remains FAIL at final M2.11/M2.12 identity comparison. | Consume only exact Wave A facts through the accepted retained-final resume; keep FAIL provenance. | NONBLOCKING_OBSERVATION |
| STRATEGY_PROFILE_SCOPE | Current profiles do not demonstrate decision migration. | Hold P05/P06 and describe profiles as offer/terms optimization plus bounded account treatment. | PUBLICATION_HOLD |
| PRODUCTION_CLAIMS | All data and values are deterministic synthetic. | No production, causal, regulatory, CECL, realized profitability or autonomous-strategy claim. | PERMANENT_BOUNDARY |
| WINDOWS_EXTRACTION | Linux clean extraction and path simulation do not replace actual Windows-native release testing. | Test exact hosted release assets on Windows after authorized publication. | PENDING_RELEASE_GATE |

## 16. Governing conclusion

The successor materially improves strategy correctness, explanation, lifecycle scalability, monitoring calibration, deterministic reconciliation, source identity, and certification. It does not change the accepted Module 1 foundation, does not perform real funding or servicing, and does not yet authorize public supersession.

The exact next step is to integrate these R26 facts, reports, P01-P04 Power BI assets, project history, and public documentation into one version-separated repository candidate; generate its exact Git/file/hash delta; submit the combined delta for bounded Independent Audit; and only then decide and activate the final public v2.1 release identity.
