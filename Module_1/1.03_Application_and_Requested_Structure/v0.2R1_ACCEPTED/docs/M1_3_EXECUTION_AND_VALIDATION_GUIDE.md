# v0.2R1 recovery path for the accepted 750-row generated set

Use this sequence only when the original v0.2 run is in `M1_3_FAILED` solely because `M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION` failed, while all 750 applications and canonical hashes reconcile.

The DBeaver reconnect did not cause the result. PostgreSQL committed tables, functions, evidence, and hashes persist across connections; each M1.3 script is transactionally self-contained. The submitted evidence shows the same database, accepted G1/M1.2 hashes, 750 applications, zero row-level mismatches, and zero downstream rows.

Do **not** rerun script 18 and do not delete or update application rows.

Execute:

```text
1. tests/16_msbf_m1_3_failed_validation_recovery_check_v0_2R1.sql
2. sql/19_msbf_m1_3_application_validation_v0_2.sql
3. sql/20_msbf_m1_3_negative_control_tests_v0_2.sql
4. sql/21_msbf_m1_3_acceptance_finalize_v0_2.sql
5. tests/22_MSBF_M1_3_Application_Request_Master_Report_v0_2.sql
6. tests/23_MSBF_M1_3_Application_Request_Detail_Report_v0_2.sql
```

Required recovery checkpoint:

```text
recovery_state_status = PASS
applications          = 750
row mismatches        = 0
failed positive code  = M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION
```

After the revised validation, required evidence is:

```text
42 / 42 positive checks PASS
3 / 3 negative controls PASS
latest M1.3 review version = 2
latest M1.3 gate result     = PASS
run_status                  = M1_3_ACCEPTED
overall_m1_3_status         = PASS
```

The failed review-version-1 gate record remains in the audit history. The finalizer creates review version 2; it does not erase the prior failure.

---

# M1.3 Execution and Validation Guide

## 1. Prerequisites

Use the accepted `msbf_strategy` database after G0, G1, and M1.2 sign-off. Before starting, verify:

```text
run_status          = M1_2_ACCEPTED
population_status   = M1_2_ACCEPTED
G1 gate             = PASS
M1.2 gate           = PASS
merchant rows       = 750
application rows    = 0
```

Do not run M1.3 against a different population, run version, as-of date, or snapshot hash.

## 2. DBeaver procedure

1. Connect the editor to `msbf_strategy`.
2. Execute each complete file with **Execute SQL Script**.
3. Stop on the first PostgreSQL exception.
4. Do not select Retry, Skip, or Skip All after a failure.
5. If a transactional script fails, execute `ROLLBACK;` in that connection and confirm the stage state before continuing.
6. Save the structured result exports listed below. Execution logs are optional for this portfolio project unless a failure needs diagnosis.

## 3. Exact execution order

| Order | File | Required checkpoint |
|---:|---|---|
| 1 | `tests/17_msbf_m1_3_preflight_validation_v0_2.sql` | `preflight_status = PASS` |
| 2 | `sql/18_msbf_m1_3_application_request_generation_v0_2.sql` | 750 applications, zero mismatches |
| 3 | `sql/19_msbf_m1_3_application_validation_v0_2.sql` | 42 of 42 positive checks pass |
| 4 | `sql/20_msbf_m1_3_negative_control_tests_v0_2.sql` | 3 of 3 negative controls pass |
| 5 | `sql/21_msbf_m1_3_acceptance_finalize_v0_2.sql` | Gate PASS; run becomes `M1_3_ACCEPTED` |
| 6 | `tests/22_MSBF_M1_3_Application_Request_Master_Report_v0_2.sql` | `overall_m1_3_status = PASS` |
| 7 | `tests/23_MSBF_M1_3_Application_Request_Detail_Report_v0_2.sql` | Mismatch and blocking-error sets empty |

After script 18 commits successfully, **do not rerun it**. The assertion function intentionally rejects regeneration.

## 4. Preflight result

Expected:

```text
preflight_status       PASS
run_status             M1_2_ACCEPTED
population_status      M1_2_ACCEPTED
merchants              750
owners                  1347
industry rows           750
channels                5
processors              750
relationships           750
required parameter pairs 30
resolved parameter pairs 30
applications            0
downstream rows          0
blocking errors          0
```

## 5. Generation result

Required:

```text
applications          750
merchants             750
expected canonical    750
actual canonical      750
mismatches              0
expected hash = actual hash
run_status            M1_3_GENERATED
```

## 6. Positive and negative validation

Script 19 returns 42 rows. Every `status` must equal `PASS`.

Script 20 must return:

```text
M1_3_NEG_01_MISSING_WEIGHT_PARAMETER  PASS
M1_3_NEG_02_INVALID_WEIGHT_SUM         PASS
M1_3_NEG_03_REGENERATION_REJECTED      PASS
```

## 7. Acceptance result

Required:

```text
run_status          M1_3_ACCEPTED
population_status   M1_2_ACCEPTED
gate_id             M1_3_APPLICATION_REQUEST
result_status       PASS
```

The population status remains M1.2 accepted because M1.3 adds applications; it does not replace the accepted merchant population.

## 8. Master report

The final column must be:

```text
overall_m1_3_status = PASS
```

Expected exact categorical counts:

```text
30-day horizon  188
60-day horizon  337
90-day horizon  225

WORKING_CAPITAL    338
INVENTORY          150
EQUIPMENT_REPAIR    90
SEASONAL_NEED       75
EXPANSION           60
EMERGENCY_EXPENSE   37
```

Other distributional values—amounts, rates, path ratios, constraint mix, and mixed-signal counts—are generated deterministically but should be taken from the live database rather than represented as production benchmarks.

## 9. Detailed-report exports

Export the twelve result sets with these labels:

1. Run and Acceptance State
2. Entity Row Counts
3. Expected Payoff Horizon Mix
4. Use of Proceeds Mix
5. Merchant Size Diagnostics
6. Relationship Stage Diagnostics
7. Channel and Processor Diagnostics
8. Binding Constraint Diagnostics
9. Mixed Signal Examples
10. Row-Level Deterministic Mismatches
11. M1.3 Evidence
12. Blocking Resolution Errors

Result sets 10 and 12 must contain headers and zero data rows.

## 10. Recommended evidence filenames

```text
17_msbf_m1_3_preflight_validation_v0_2_results_YYYYMMDD.csv
18_msbf_m1_3_application_request_generation_v0_2_results_YYYYMMDD.csv
19_msbf_m1_3_application_validation_v0_2_results_YYYYMMDD.csv
20_msbf_m1_3_negative_control_tests_v0_2_results_YYYYMMDD.csv
21_msbf_m1_3_acceptance_finalize_v0_2_results_YYYYMMDD.csv
MSBF_M1_3_Application_Request_Master_Report_v0_2_YYYYMMDD.csv
MSBF_M1_3_Application_Request_Detail_Report_v0_2_<Result_Set>_YYYYMMDD.csv
```

## 11. Failure recovery

If preflight fails, do not generate applications. Review configuration, accepted gates, hashes, counts, parameters, or unexpected stage rows.

If script 18 fails before commit:

```sql
ROLLBACK;
```

Then confirm application rows remain zero before using a corrected package. Never delete an accepted or partially accepted population to force a rerun.

## 12. Evidence review and sign-off

M1.3 is not accepted merely because the SQL finishes. Acceptance requires exported evidence, review of all positive/negative checks, zero row-level mismatches, zero blocking errors, a PASS master report, and a completed stage milestone.
