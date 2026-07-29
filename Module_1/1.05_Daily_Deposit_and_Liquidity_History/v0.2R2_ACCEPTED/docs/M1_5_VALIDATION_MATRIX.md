# M1.5 Validation Matrix

## Positive controls

| # | Evidence code | Validation objective | Acceptance condition |
|---:|---|---|---|
| 1 | `M1_5_POS_01_RUN_STAGE_STATUS` | Generated stage state | Run is generated, validated, or failed-review state |
| 2 | `M1_5_POS_02_G1_GATE` | G1 prerequisite | Latest gate is PASS |
| 3 | `M1_5_POS_03_M1_2_GATE` | M1.2 prerequisite | Latest gate is PASS |
| 4 | `M1_5_POS_04_M1_3_GATE` | M1.3 prerequisite | Latest gate is PASS |
| 5 | `M1_5_POS_05_M1_4_GATE` | M1.4 prerequisite | Latest gate is PASS |
| 6 | `M1_5_POS_06_ACCEPTED_G1_HASHES` | Approved G1 identity | Three accepted hashes unchanged |
| 7 | `M1_5_POS_07_RECOMPUTED_G1_HASHES` | G1 content integrity | Recomputed hashes equal stored hashes |
| 8 | `M1_5_POS_08_POPULATION_HASH` | Merchant-population integrity | Accepted and recomputed population hashes match |
| 9 | `M1_5_POS_09_APPLICATION_HASH` | Application-set integrity | Accepted and recomputed application hashes match |
| 10 | `M1_5_POS_10_POS_HASH` | POS-history integrity | Accepted and recomputed POS hashes match |
| 11 | `M1_5_POS_11_GENERATION_SPEC` | Code-owned methodology integrity | Specification text and hash reconcile |
| 12 | `M1_5_POS_12_ROW_COUNT` | Fact cardinality | 135,000 rows |
| 13 | `M1_5_POS_13_MERCHANT_COVERAGE` | Merchant coverage | 750 merchants |
| 14 | `M1_5_POS_14_DATE_COVERAGE` | Date coverage | 180 distinct dates |
| 15 | `M1_5_POS_15_PER_MERCHANT_DENSITY` | Rectangular panel | 180 rows per merchant |
| 16 | `M1_5_POS_16_DATE_BOUNDS` | Frozen temporal window | Minimum/maximum dates match population registry |
| 17 | `M1_5_POS_17_UNIQUE_GRAIN` | Physical uniqueness | 135,000 unique composite keys |
| 18 | `M1_5_POS_18_POPULATION_IDENTITY` | Population lineage | Every row uses accepted population |
| 19 | `M1_5_POS_19_SOURCE_CONTRACT` | Source lineage | Every row uses frozen DEPOSIT_DAILY source contract |
| 20 | `M1_5_POS_20_RUN_IDENTITY` | Run lineage | Every row uses accepted run ID |
| 21 | `M1_5_POS_21_NO_FUTURE_DATA` | Leakage control | No date exceeds as-of date |
| 22 | `M1_5_POS_22_POS_ALIGNMENT` | POS/deposit alignment | Every merchant-day has one accepted POS row |
| 23 | `M1_5_POS_23_NONNEGATIVE` | Range controls | Deposits, withdrawals, and NSF counts nonnegative |
| 24 | `M1_5_POS_24_BALANCE_IDENTITY` | Accounting identity | Closing = opening + deposits − withdrawals |
| 25 | `M1_5_POS_25_OPENING_ROLLFORWARD` | Balance continuity | Opening equals prior-day closing |
| 26 | `M1_5_POS_26_AVAILABLE_BALANCE` | Available balance | Available never exceeds closing balance |
| 27 | `M1_5_POS_27_MINIMUM_BALANCE` | Minimum balance | Minimum equals least of opening, closing, available |
| 28 | `M1_5_POS_28_NEGATIVE_FLAG` | Negative flag | Flag exactly matches minimum balance below zero |
| 29 | `M1_5_POS_29_PRE_OPEN_BEHAVIOR` | Pre-open treatment | No fabricated activity before processor activation |
| 30 | `M1_5_POS_30_CAPTURE_RATE_BOUNDS` | Capture-rate boundary | Daily rate between 0.25 and 1.00 |
| 31 | `M1_5_POS_31_INDUSTRY_CAPTURE` | Industry parameter direction | Eight industries within tolerance of governed centers |
| 32 | `M1_5_POS_32_WITHDRAWAL_DEPOSIT_RATIO` | Portfolio flow boundary | Portfolio ratio between 0.60 and 1.35 |
| 33 | `M1_5_POS_33_RISK_TIER_COVERAGE` | Liquidity-tier diversity | At least four tiers represented within 1–5 |
| 34 | `M1_5_POS_34_NSF_PROBABILITY_BOUNDS` | NSF-probability boundary | Adjusted probability between 0 and 0.25 |
| 35 | `M1_5_POS_35_NSF_TIER_GRADIENT` | NSF tier direction | Highest available tier exceeds lowest |
| 36 | `M1_5_POS_36_NSF_EVENT_RARITY` | NSF portfolio rate | Positive and below 5% of rows |
| 37 | `M1_5_POS_37_NEGATIVE_BALANCE_SHARE` | Negative balance boundary | Positive and below 30% of rows |
| 38 | `M1_5_POS_38_NEGATIVE_PROPENSITY_GRADIENT` | Negative-propensity direction | Highest available tier exceeds lowest |
| 39 | `M1_5_POS_39_BOUNDED_CLOSING_FLOOR` | Liquidity floor | No closing balance below governed floor |
| 40 | `M1_5_POS_40_SOURCE_MISSINGNESS` | Source observability | Deterministic missingness share between 3% and 13% |
| 41 | `M1_5_POS_41_SOURCE_MISSING_TRUTH_ROWS` | Latent truth completeness | 180 rows per source-missing merchant |
| 42 | `M1_5_POS_42_RELATIONSHIP_CAPTURE` | Relationship adjustment | Direct adjustments equal +0.025 / −0.010 |
| 43 | `M1_5_POS_43_INDUSTRY_DIFFERENTIATION` | Industry differentiation | Capture-rate spread at least 0.08 |
| 44 | `M1_5_POS_44_EVENT_DIVERSITY` | Liquidity-event diversity | At least five event codes |
| 45 | `M1_5_POS_45_SUPPORT_DEPOSIT_PRESENCE` | Support-deposit behavior | Positive rows and amount |
| 46 | `M1_5_POS_46_NSF_COUNT_BOUND` | NSF count bound | Maximum daily count between 0 and 2 |
| 47 | `M1_5_POS_47_DEPOSIT_COMPONENT_IDENTITY` | Deposit components | Total equals POS capture + support deposit |
| 48 | `M1_5_POS_48_FINANCING_REMITTANCE_COHERENCE` | Financing pressure | Valid active window and assigned amount |
| 49 | `M1_5_POS_49_FINANCING_COHORT_PRESENCE` | Financing cohort | Positive active merchant cohort and amounts |
| 50 | `M1_5_POS_50_TEMPORARY_HOLD_IDENTITY` | Available-balance hold | Available = closing − temporary hold |
| 51 | `M1_5_POS_51_INITIAL_OPENING_IDENTITY` | Initial liquidity state | First opening equals profile opening balance |
| 52 | `M1_5_POS_52_ROW_REPRODUCTION` | Full deterministic reproduction | Zero expected/actual mismatches |
| 53 | `M1_5_POS_53_SET_HASH` | Full-set integrity | Stored, expected, and actual hashes match |
| 54 | `M1_5_POS_54_PARAMETER_COMPLETENESS` | Configuration completeness | 32 of 32 required pairs resolve |
| 55 | `M1_5_POS_55_STAGE_BOUNDARY` | Scope control | Scenario and downstream rows remain zero |
| 56 | `M1_5_POS_56_BLOCKING_ERRORS` | Configuration readiness | Zero blocking resolution errors |

## Negative controls

| Evidence code | Controlled defect | Required response |
|---|---|---|
| `M1_5_NEG_01_MISSING_PARAMETER_REJECTED` | Remove one required industry capture parameter inside a subtransaction | Generation gate rejects fewer than 32 resolved pairs |
| `M1_5_NEG_02_SOURCE_NOT_READY_REJECTED` | Mark `DEPOSIT_DAILY` source not ready inside a subtransaction | Generation gate rejects source state |
| `M1_5_NEG_03_HISTORY_DRIFT_REJECTED` | Shorten accepted history by one day inside a subtransaction | Generation gate rejects 179-day window |
| `M1_5_NEG_04_REGENERATION_REJECTED` | Call generation gate after rows exist | Stage rejects rerun |

Each controlled mutation is automatically rolled back by its PL/pgSQL exception subtransaction.

## Final acceptance

The finalizer requires all 60 validation/evidence controls to pass: 56 positive checks, four negative controls, zero deterministic mismatches, complete cardinality, exact hashes, zero downstream rows, and zero blocking errors.