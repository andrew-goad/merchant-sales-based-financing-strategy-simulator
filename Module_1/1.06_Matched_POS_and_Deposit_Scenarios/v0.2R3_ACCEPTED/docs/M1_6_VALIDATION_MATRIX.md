# M1.6 Validation Matrix

## Positive controls

| # | Evidence code | Validation objective | Acceptance condition |
|---:|---|---|---|
| 1 | `M1_6_POS_01_RUN_STAGE_STATUS` | Generated stage state | Run is generated, validated, or failed-review state |
| 2 | `M1_6_POS_02_G1_GATE` | G1 prerequisite | Latest gate is PASS |
| 3 | `M1_6_POS_03_M1_2_GATE` | M1.2 prerequisite | Latest gate is PASS |
| 4 | `M1_6_POS_04_M1_3_GATE` | M1.3 prerequisite | Latest gate is PASS |
| 5 | `M1_6_POS_05_M1_4_GATE` | M1.4 prerequisite | Latest gate is PASS |
| 6 | `M1_6_POS_06_M1_5_GATE` | M1.5 prerequisite | Latest gate is PASS |
| 7 | `M1_6_POS_07_ACCEPTED_G1_HASHES` | Accepted G1 identity | Three accepted hashes unchanged |
| 8 | `M1_6_POS_08_RECOMPUTED_G1_HASHES` | G1 content integrity | Recomputed hashes equal stored hashes |
| 9 | `M1_6_POS_09_POPULATION_HASH` | Population integrity | Accepted and recomputed hashes match |
| 10 | `M1_6_POS_10_APPLICATION_HASH` | Application integrity | Accepted and recomputed hashes match |
| 11 | `M1_6_POS_11_BASE_POS_HASH` | Baseline POS integrity | Accepted and recomputed hashes match |
| 12 | `M1_6_POS_12_BASE_DEPOSIT_HASH` | Baseline deposit integrity | Accepted and recomputed hashes match |
| 13 | `M1_6_POS_13_SCENARIO_SPEC_HASH` | Scenario specification integrity | Stored specification hash reconciles |
| 14 | `M1_6_POS_14_SCENARIO_COUNT` | Scenario registration | Exactly two approved scenarios |
| 15 | `M1_6_POS_15_SCENARIO_CODES` | Scenario identity | BASELINE and RECESSION_ENERGY |
| 16 | `M1_6_POS_16_PARAMETER_COMPLETENESS` | Configuration completeness | 32 of 32 pairs resolve |
| 17 | `M1_6_POS_17_SCENARIO_HISTORY_ENABLED` | Scenario persistence authorization | Enable flag is true |
| 18 | `M1_6_POS_18_POS_TOTAL_ROWS` | POS cardinality | 270,000 rows |
| 19 | `M1_6_POS_19_DEPOSIT_TOTAL_ROWS` | Deposit cardinality | 270,000 rows |
| 20 | `M1_6_POS_20_POS_ROWS_PER_SCENARIO` | POS scenario density | 135,000 per scenario |
| 21 | `M1_6_POS_21_DEPOSIT_ROWS_PER_SCENARIO` | Deposit scenario density | 135,000 per scenario |
| 22 | `M1_6_POS_22_POS_MERCHANT_COVERAGE` | POS merchant coverage | 750 per scenario |
| 23 | `M1_6_POS_23_DEPOSIT_MERCHANT_COVERAGE` | Deposit merchant coverage | 750 per scenario |
| 24 | `M1_6_POS_24_POS_DATE_COVERAGE` | POS date coverage | 180 per scenario |
| 25 | `M1_6_POS_25_DEPOSIT_DATE_COVERAGE` | Deposit date coverage | 180 per scenario |
| 26 | `M1_6_POS_26_POS_UNIQUE_GRAIN` | POS unique grain | 270,000 unique keys |
| 27 | `M1_6_POS_27_DEPOSIT_UNIQUE_GRAIN` | Deposit unique grain | 270,000 unique keys |
| 28 | `M1_6_POS_28_POS_BASE_HASH_LINEAGE` | POS baseline lineage | Zero missing base hashes |
| 29 | `M1_6_POS_29_DEPOSIT_BASE_HASH_LINEAGE` | Deposit baseline lineage | Zero missing base hashes |
| 30 | `M1_6_POS_30_POS_SOURCE_RUN_LINEAGE` | POS source/run lineage | Zero violations |
| 31 | `M1_6_POS_31_DEPOSIT_SOURCE_RUN_LINEAGE` | Deposit source/run lineage | Zero violations |
| 32 | `M1_6_POS_32_BASELINE_POS_COPY` | Baseline POS reproduction | Zero value differences |
| 33 | `M1_6_POS_33_BASELINE_DEPOSIT_COPY` | Baseline deposit reproduction | Zero value differences |
| 34 | `M1_6_POS_34_STRESS_PRE_SHOCK_POS_COPY` | Pre-shock POS preservation | Zero value differences |
| 35 | `M1_6_POS_35_STRESS_PRE_SHOCK_DEPOSIT_COPY` | Pre-shock deposit preservation | Zero value differences |
| 36 | `M1_6_POS_36_DIRECT_WINDOW_ROWS` | Direct stress window | 45,000 rows |
| 37 | `M1_6_POS_37_PROPAGATED_WINDOW_ROWS` | Propagated stress window | 39,750 rows |
| 38 | `M1_6_POS_38_BASELINE_FACTORS` | Baseline factor control | All factors equal one |
| 39 | `M1_6_POS_39_STRESS_FACTOR_BOUNDS` | Stress factor bounds | No cap violations |
| 40 | `M1_6_POS_40_PAYLOAD_COMPLETENESS` | Scenario payload identity | Zero code mismatches |
| 41 | `M1_6_POS_41_POS_NONNEGATIVE` | POS range controls | Zero negative values |
| 42 | `M1_6_POS_42_POS_RECONCILIATION` | Eligible-sales identity | Zero violations |
| 43 | `M1_6_POS_43_ZERO_SALES_FLAG` | Zero-sales identity | Zero violations |
| 44 | `M1_6_POS_44_SETTLEMENT_LAG_REPRODUCTION` | Scenario settlement mechanics | Zero lag violations |
| 45 | `M1_6_POS_45_STRESS_GROSS_DECLINE` | Aggregate sales direction | Stress below baseline |
| 46 | `M1_6_POS_46_STRESS_ELIGIBLE_DECLINE` | Eligible-sales direction | Stress below baseline |
| 47 | `M1_6_POS_47_REFUND_RATE_DIRECTION` | Refund burden direction | Stress above baseline |
| 48 | `M1_6_POS_48_CHARGEBACK_RATE_DIRECTION` | Chargeback burden direction | Stress above baseline |
| 49 | `M1_6_POS_49_OUTAGE_SHARE_DIRECTION` | Processor disruption direction | Stress above baseline |
| 50 | `M1_6_POS_50_INDUSTRY_SENSITIVITY_ORDER` | Industry-network direction | Energy decline exceeds healthcare |
| 51 | `M1_6_POS_51_DEPOSIT_RECONCILIATION` | Deposit accounting identity | Zero violations |
| 52 | `M1_6_POS_52_DEPOSIT_ROLL_FORWARD` | Balance continuity | Zero violations |
| 53 | `M1_6_POS_53_STRESS_POS_DEPOSIT_DECLINE` | POS deposit direction | Stress below baseline |
| 54 | `M1_6_POS_54_STRESS_WITHDRAWAL_INCREASE` | Withdrawal direction | Stress above baseline |
| 55 | `M1_6_POS_55_NEGATIVE_BALANCE_DIRECTION` | Negative balance direction | Stress not below baseline |
| 56 | `M1_6_POS_56_NSF_DIRECTION` | NSF direction | Stress not below baseline |
| 57 | `M1_6_POS_57_STRESS_SUPPORT_DEPOSITS` | Liquidity support evidence | Positive rows |
| 58 | `M1_6_POS_58_CANONICAL_REPRODUCTION` | Full deterministic reproduction | 540,000 / 540,000 / 0 mismatches |
| 59 | `M1_6_POS_59_SET_HASH_RECONCILIATION` | Full-set integrity | Stored and actual hashes match |
| 60 | `M1_6_POS_60_MATCHED_SHARE` | Matched POS/deposit coverage | Share at least 1.0 |
| 61 | `M1_6_POS_61_STAGE_BOUNDARY` | Scope control | Zero downstream rows |
| 62 | `M1_6_POS_62_BLOCKING_ERRORS` | Configuration readiness | Zero blocking errors |

## Negative controls

| Evidence code | Controlled defect | Required response |
|---|---|---|
| `M1_6_NEG_01_MISSING_PARAMETER_REJECTED` | Remove one required stress parameter inside a subtransaction | Generation gate rejects fewer than 32 resolved pairs |
| `M1_6_NEG_02_UNAPPROVED_SCENARIO_REJECTED` | Set the stress scenario to DRAFT inside a subtransaction | Generation gate rejects scenario registry state |
| `M1_6_NEG_03_SCENARIO_DISABLED_REJECTED` | Disable scenario persistence inside a subtransaction | Generation gate rejects the frozen enablement state |
| `M1_6_NEG_04_HISTORY_DRIFT_REJECTED` | Shorten the accepted history by one day inside a subtransaction | Generation gate rejects the 179-day window |
| `M1_6_NEG_05_REGENERATION_REJECTED` | Call generation gate after scenario rows exist | Stage rejects rerun |

All controlled mutations are rolled back automatically by PL/pgSQL exception subtransactions.

## Final acceptance

The finalizer requires all 67 validation/evidence controls to pass: 62 positive checks, five negative controls, exact scenario cardinality, zero deterministic mismatches, complete hashes, zero downstream rows, and zero blocking errors.
