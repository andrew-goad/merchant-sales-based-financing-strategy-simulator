# M1.4 Validation Matrix

## Positive controls

| # | Evidence code | Validation objective | Acceptance condition |
|---:|---|---|---|
| 1 | `M1_4_POS_01_RUN_STAGE_STATUS` | Generated stage state | Run is generated, validated, or failed-review state |
| 2 | `M1_4_POS_02_G1_GATE` | G1 prerequisite | Latest gate is PASS |
| 3 | `M1_4_POS_03_M1_2_GATE` | M1.2 prerequisite | Latest gate is PASS |
| 4 | `M1_4_POS_04_M1_3_GATE` | M1.3 prerequisite | Latest gate is PASS |
| 5 | `M1_4_POS_05_ACCEPTED_G1_HASHES` | Approved G1 identity | Three accepted hashes unchanged |
| 6 | `M1_4_POS_06_RECOMPUTED_G1_HASHES` | G1 content integrity | Recomputed hashes equal stored hashes |
| 7 | `M1_4_POS_07_POPULATION_HASH` | Merchant-population integrity | Accepted and recomputed population hashes match |
| 8 | `M1_4_POS_08_APPLICATION_HASH` | Application-set integrity | Accepted and recomputed application hashes match |
| 9 | `M1_4_POS_09_GENERATION_SPEC` | Code-owned methodology integrity | Specification text and hash reconcile |
| 10 | `M1_4_POS_10_ROW_COUNT` | Fact cardinality | 135,000 rows |
| 11 | `M1_4_POS_11_MERCHANT_COVERAGE` | Merchant coverage | 750 merchants |
| 12 | `M1_4_POS_12_DATE_COVERAGE` | Date coverage | 180 distinct dates |
| 13 | `M1_4_POS_13_PER_MERCHANT_DENSITY` | Rectangular panel | 180 rows per merchant |
| 14 | `M1_4_POS_14_DATE_BOUNDS` | Frozen temporal window | Minimum/maximum dates match population registry |
| 15 | `M1_4_POS_15_UNIQUE_GRAIN` | Physical uniqueness | 135,000 unique composite keys |
| 16 | `M1_4_POS_16_POPULATION_IDENTITY` | Population lineage | Every row uses accepted population |
| 17 | `M1_4_POS_17_PROCESSOR_ALIGNMENT` | Processor lineage | Merchant and processor align on every row |
| 18 | `M1_4_POS_18_SOURCE_CONTRACT` | Source lineage | Every row uses frozen POS source contract |
| 19 | `M1_4_POS_19_RUN_IDENTITY` | Run lineage | Every row uses accepted run ID |
| 20 | `M1_4_POS_20_NO_FUTURE_DATA` | Leakage control | No date exceeds as-of date |
| 21 | `M1_4_POS_21_PRE_OPEN_BEHAVIOR` | Thin-history treatment | Pre-open rows are zero and not connected |
| 22 | `M1_4_POS_22_STATUS_CONNECTION_MAPPING` | Continuity diagnostics | Four permitted state pairs only |
| 23 | `M1_4_POS_23_NONNEGATIVE` | Range controls | No negative amount or count |
| 24 | `M1_4_POS_24_ZERO_SALES_IDENTITY` | Zero-day integrity | Flag exactly matches gross sales = 0 |
| 25 | `M1_4_POS_25_TRANSACTION_COUNT` | Transaction identity | Positive-sales days have transactions; zero days do not |
| 26 | `M1_4_POS_26_AVERAGE_TICKET` | Ticket reconciliation | Gross / count matches average ticket |
| 27 | `M1_4_POS_27_ELIGIBLE_SALES` | Gross-to-eligible identity | Deductions reconcile within currency tolerance |
| 28 | `M1_4_POS_28_SETTLEMENT_PROCEEDS` | Settlement accounting | Net proceeds = settlement − fee |
| 29 | `M1_4_POS_29_SETTLEMENT_DELAY` | Lag methodology | Persisted settlement reproduces governed lag |
| 30 | `M1_4_POS_30_STORED_ROW_HASH` | Physical hash integrity | Every stored row hash recomputes |
| 31 | `M1_4_POS_31_ROW_REPRODUCTION` | Full deterministic reproduction | Zero expected/actual mismatches |
| 32 | `M1_4_POS_32_SET_HASH` | Full-set integrity | Stored, expected, and actual hashes match |
| 33 | `M1_4_POS_33_INDUSTRY_COVERAGE` | Industry diversity | Eight industries represented |
| 34 | `M1_4_POS_34_ARCHETYPE_COVERAGE` | Operating-pattern diversity | At least six archetypes represented |
| 35 | `M1_4_POS_35_CORE_ARCHETYPES` | Core trends | Stable, growing, and declining merchants present |
| 36 | `M1_4_POS_36_ZERO_SALES_SHARE` | Zero-day realism | Portfolio share between 3% and 50% |
| 37 | `M1_4_POS_37_OUTAGE_SHARE` | Processor outage boundary | Positive and below 2% |
| 38 | `M1_4_POS_38_DEGRADED_SHARE` | Processor degradation boundary | Positive and below 4% |
| 39 | `M1_4_POS_39_REFUND_RATE` | Refund boundary | Positive and below 12% |
| 40 | `M1_4_POS_40_CHARGEBACK_RATE` | Chargeback boundary | Positive and below 3% |
| 41 | `M1_4_POS_41_REVERSAL_RATE` | Reversal boundary | Positive and below 2% |
| 42 | `M1_4_POS_42_SALES_DAY_TRANSACTIONS` | Sales-day detail | Positive-sales rows have positive count |
| 43 | `M1_4_POS_43_ZERO_DAY_DETAILS` | Zero-day detail | Count and ticket are zero |
| 44 | `M1_4_POS_44_ACTIVE_POSITIVE_DAYS` | Minimum usable activity | At least ten positive active days per merchant |
| 45 | `M1_4_POS_45_GROWING_TREND` | Growth direction | Last 30-day average exceeds first 30-day average |
| 46 | `M1_4_POS_46_DECLINING_TREND` | Decline direction | Last 30-day average is below first 30-day average |
| 47 | `M1_4_POS_47_DISRUPTION_EFFECT` | Event direction | Disruption sales below normal sales |
| 48 | `M1_4_POS_48_WEEKEND_PATTERN` | Industry differentiation | Restaurant weekend ratio exceeds professional services |
| 49 | `M1_4_POS_49_CALENDAR_EFFECTS` | Calendar coverage | Three governed dates represented |
| 50 | `M1_4_POS_50_FEE_MAPPING` | Channel fee mapping | Five channels mapped to positive fees |
| 51 | `M1_4_POS_51_STAGE_BOUNDARY` | Scope control | Scenario and downstream rows remain zero |
| 52 | `M1_4_POS_52_BLOCKING_ERRORS` | Configuration readiness | Zero blocking resolution errors |

## Negative controls

| Evidence code | Controlled defect | Required response |
|---|---|---|
| `M1_4_NEG_01_MISSING_PARAMETER_REJECTED` | Delete one required industry parameter in a subtransaction | Generation gate rejects fewer than 86 resolved pairs |
| `M1_4_NEG_02_SOURCE_NOT_READY_REJECTED` | Mark POS source not ready in a subtransaction | Generation gate rejects source state |
| `M1_4_NEG_03_HISTORY_DRIFT_REJECTED` | Shorten accepted history by one day in a subtransaction | Generation gate rejects 179-day window |
| `M1_4_NEG_04_REGENERATION_REJECTED` | Call generation gate after rows exist | Stage rejects rerun |

Each controlled mutation is automatically rolled back by its PL/pgSQL exception subtransaction.

## Final acceptance

The finalizer requires all 56 validation/evidence controls to pass, zero mismatches, complete cardinality, exact hashes, zero downstream rows, and zero blocking errors.
