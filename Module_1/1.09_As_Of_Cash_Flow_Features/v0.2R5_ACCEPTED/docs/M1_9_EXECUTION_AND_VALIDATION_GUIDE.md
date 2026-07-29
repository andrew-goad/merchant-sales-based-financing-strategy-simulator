# M1.9 Execution and Validation Guide

## Environment

Execute against the accepted PostgreSQL database:

```text
Database       msbf_strategy
Required run   M1_V0_2_BASELINE_BUILD v1
Required state M1_8_ACCEPTED
```

Before each script, confirm:

```sql
SELECT current_database(),current_user,current_setting('server_version'),clock_timestamp();
```

Use DBeaver **Execute SQL Script**. Stop at the first exception. Do not use Retry, Skip, or Skip All after an error.

## Normal execution order

| Order | Script | Required checkpoint |
|---:|---|---|
| 1 | `60_msbf_m1_9_schema_policy_extension_v0_2.sql` | Schema/policy extension returns `PASS` |
| 2 | `61_msbf_m1_9_preflight_validation_v0_2.sql` | `preflight_status = PASS` |
| 3 | `62_msbf_m1_9_asof_cashflow_feature_generation_v0_2.sql` | 1,500 snapshots; 54,000 values; generation `PASS` |
| 4 | `63_msbf_m1_9_asof_cashflow_feature_validation_v0_2.sql` | 66 rows; 66 `PASS`; zero `FAIL` |
| 5 | `64_msbf_m1_9_negative_control_tests_v0_2.sql` | 6 rows; 6 `PASS` |
| 6 | `65_msbf_m1_9_acceptance_finalize_v0_2.sql` | gate `PASS`; run `M1_9_ACCEPTED` |
| 7 | `66_MSBF_M1_9_As_Of_Cash_Flow_Feature_Master_Report_v0_2.sql` | `overall_m1_9_status = PASS` |
| 8 | `67_MSBF_M1_9_As_Of_Cash_Flow_Feature_Detail_Report_v0_2.sql` | 20 result sets; mismatch/error sets empty |

After script 62 commits successfully, **do not rerun it**.

## Generation progress notices

```text
Phase 1/6 — materialize accepted application, source, scenario and control inputs
Phase 2/6 — materialize scenario POS history and bounded rolling statistics
Phase 3/6 — aggregate scenario deposit/liquidity history once
Phase 4/6 — calculate bounded scenario-aware feature snapshots and matched deltas
Phase 5/6 — persist, index, analyze and perform canonical reconciliation
Phase 6/6 — committed generation checkpoint
```

## Contingency scripts

### 60A — failed-generation recovery check

Run only after a failed or cancelled script 62 and after:

```sql
ROLLBACK;
```

It must report:

```text
run_status             M1_8_ACCEPTED
snapshot rows          0
feature-value rows     0
M1.9 evidence rows     0
M1.9 gate rows         0
recovery_state_status  PASS
```

### 62A — generation evidence reconstruction

Run only when script 62 committed but DBeaver lost the result tab. It is read-only and must return:

```text
generation_reconciliation_status = PASS
```

## Expected checkpoints

### Script 62

```text
run_status             M1_9_GENERATED
snapshot_rows          1,500
feature_value_rows     54,000
canonical entities     55,500
row mismatches         0
three set hashes       non-null and reconciled
generation_status      PASS
```

### Script 63

```text
66 checks
66 PASS
0 FAIL
run_status = M1_9_VALIDATED
```

### Script 64

```text
6 controls
6 PASS
run_status remains M1_9_VALIDATED
```

### Script 65

```text
gate_id       M1_9_ASOF_CASHFLOW_FEATURES
result_status PASS
run_status    M1_9_ACCEPTED
```

## Evidence exports

Retain:

```text
60 schema/policy checkpoint
61 preflight
62 generation checkpoint
63 positive-validation result
64 negative-control result
65 acceptance-finalizer result
66 master report
67 all 20 detailed result sets
completed M1.9 acceptance milestone
```

Result set 19 (row-level mismatches) and result set 20 (blocking resolution errors) must contain headers and zero data rows.

## Recovery rules

- Never delete generated M1.9 rows manually.
- Never reset the run status manually.
- Never rerun script 62 after a commit.
- If a reporting query fails after acceptance, correct the read-only report; do not regenerate features.
- Preserve failed-validation evidence and remediation history if a hotfix is required.
