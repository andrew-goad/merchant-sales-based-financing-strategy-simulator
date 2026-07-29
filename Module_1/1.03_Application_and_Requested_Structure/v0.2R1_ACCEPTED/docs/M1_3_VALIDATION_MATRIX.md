# M1.3 Validation Matrix

M1.3 contains **42 blocking positive checks** and three negative controls.

| # | Evidence code | Validation area | Acceptance intent |
|---:|---|---|---|
| 1 | `M1_3_POS_01_RUN_STAGE_STATUS` | stage status | Correct stage status before validation. |
| 2 | `M1_3_POS_02_G1_GATE` | G1 gate | Accepted G1 gate remains in force. |
| 3 | `M1_3_POS_03_M1_2_GATE` | M1.2 gate | Accepted M1.2 gate remains in force. |
| 4 | `M1_3_POS_04_ACCEPTED_G1_HASHES` | accepted G1 hashes | Approved stored G1 hashes remain unchanged. |
| 5 | `M1_3_POS_05_RECOMPUTED_G1_HASHES` | recomputed G1 hashes | Frozen G1 content independently recomputes to stored hashes. |
| 6 | `M1_3_POS_06_M1_2_POPULATION` | population status and hash | Accepted population status and hash remain unchanged. |
| 7 | `M1_3_POS_07_GENERATION_SPEC` | generation specification hash | Generation specification and hash reconcile. |
| 8 | `M1_3_POS_08_APPLICATION_COUNT` | application count | Exactly 750 applications. |
| 9 | `M1_3_POS_09_ONE_PER_MERCHANT` | one application per merchant | Exactly one application per merchant. |
| 10 | `M1_3_POS_10_APPLICATION_IDENTITY` | application identity pattern | Stable, unique application keys. |
| 11 | `M1_3_POS_11_RUN_POPULATION_IDENTITY` | run and population identity | Run and population identity preserved. |
| 12 | `M1_3_POS_12_PROCESSOR_ALIGNMENT` | processor alignment | Processor linkage is merchant-consistent. |
| 13 | `M1_3_POS_13_PARTNER_ALIGNMENT` | partner alignment | Partner channel matches processor evidence. |
| 14 | `M1_3_POS_14_APPLICATION_CHANNEL` | application-channel mapping | Application channel maps deterministically. |
| 15 | `M1_3_POS_15_TEMPORAL_INTEGRITY` | temporal integrity | No future dates. |
| 16 | `M1_3_POS_16_APPLICATION_STATUS` | status validity | All applications remain submitted requests. |
| 17 | `M1_3_POS_17_FUNDING_BOUNDS` | funding bounds | Funding within global bounds. |
| 18 | `M1_3_POS_18_FUNDING_INCREMENT` | funding increment | Funding uses the governed increment. |
| 19 | `M1_3_POS_19_FUNDING_TO_SALES` | funding-to-sales maximum | Funding-to-sales cap respected. |
| 20 | `M1_3_POS_20_REMITTANCE_BOUNDS` | remittance bounds | Remittance within bounds. |
| 21 | `M1_3_POS_21_PAYBACK_BOUNDS` | payback multiple bounds | Derived payback multiple within bounds. |
| 22 | `M1_3_POS_22_FINANCE_CHARGE_IDENTITY` | finance-charge identity | Finance-charge identity reconciles. |
| 23 | `M1_3_POS_23_REPAYMENT_ORDERING` | repayment ordering | Repayment ordering is valid. |
| 24 | `M1_3_POS_24_HORIZON_VALUES` | horizon values | Only 30/60/90-day horizons. |
| 25 | `M1_3_POS_25_HORIZON_MIX` | exact horizon mix | Exact governed horizon counts. |
| 26 | `M1_3_POS_26_USE_MIX` | exact use-of-proceeds mix | Exact governed use-of-proceeds counts. |
| 27 | `M1_3_POS_27_USE_VALUES` | use category validity | Only governed use values. |
| 28 | `M1_3_POS_28_DAILY_REMITTANCE_IDENTITY` | expected daily remittance identity | Daily-remittance arithmetic identity. |
| 29 | `M1_3_POS_29_PAYOFF_PATH_DIVERSITY` | implied payoff-path diversity | Both on-path and above-path requests exist. |
| 30 | `M1_3_POS_30_REMITTANCE_PATH_DIVERSITY` | remittance-path ratio diversity | Reference repayment-path ratios are positive and diverse. |
| 31 | `M1_3_POS_31_REQUEST_HASH` | stored request hash | Stored request hashes independently recompute. |
| 32 | `M1_3_POS_32_CANONICAL_COUNTS` | canonical counts | Expected and actual canonical universes complete. |
| 33 | `M1_3_POS_33_ROW_LEVEL_RERUN` | row-level deterministic comparison | Zero row-level deterministic mismatches. |
| 34 | `M1_3_POS_34_APPLICATION_SET_HASH` | application-set hash | Stored/expected/actual aggregate hashes match. |
| 35 | `M1_3_POS_35_SIZE_DIFFERENTIATION` | merchant-size differentiation | Average request increases by merchant size. |
| 36 | `M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION` | relationship-stage request discipline | The direct request-path utilization factor is lower for `LOW_AND_GROW` than `RETURNING_GOOD`. Raw final funding-to-sales averages remain non-blocking diagnostics because product minimums and unmatched cohort composition can invert unadjusted aggregate ratios. |
| 37 | `M1_3_POS_37_HORIZON_DIFFERENTIATION` | horizon differentiation | Longer horizons support larger sales-relative requests. |
| 38 | `M1_3_POS_38_MIXED_SIGNAL_REQUESTS` | mixed-signal request diversity | Mixed-signal request examples remain present. |
| 39 | `M1_3_POS_39_BINDING_DIVERSITY` | binding-constraint diversity | More than one request-sizing constraint is active. |
| 40 | `M1_3_POS_40_NO_APPLICATION_EVIDENCE` | no source or application-evidence adjuncts | No source/obligation/collateral/credit/verification rows yet. |
| 41 | `M1_3_POS_41_NO_DOWNSTREAM_ANALYTICS` | no transaction or downstream analytical rows | No POS/deposit/feature/risk/EAD/latest/archive rows yet. |
| 42 | `M1_3_POS_42_NO_BLOCKING_ERRORS` | no blocking resolution errors | No blocking configuration errors. |

## Negative controls

| Evidence code | Required behavior |
|---|---|
| `M1_3_NEG_01_MISSING_WEIGHT_PARAMETER` | Missing governed mix input raises an exception. |
| `M1_3_NEG_02_INVALID_WEIGHT_SUM` | Non-reconciling category weights raise an exception. |
| `M1_3_NEG_03_REGENERATION_REJECTED` | A persisted application population cannot be regenerated. |
