# M1.7 Execution and Validation Guide

## 1. Environment

```text
Database:   msbf_strategy
PostgreSQL: 14 or later
Tool:       DBeaver or psql
Prerequisite run status: M1_6_ACCEPTED
```

Before each script:

```sql
SELECT current_database(),current_user,current_setting('server_version'),clock_timestamp();
```

Required database: `msbf_strategy`.

## 2. DBeaver operating rules

1. Confirm the active editor connection is `msbf_strategy`.
2. Use **Execute SQL Script**, not current-statement execution.
3. Stop on the first PostgreSQL exception.
4. Never choose Retry, Skip, or Skip All after a failure.
5. Execute `ROLLBACK;` after a failed transactional script.
6. Do not alter accepted G0–M1.6 data.
7. After script 46 commits, do not rerun it.
8. Structured CSV exports are sufficient; logs are optional.
9. Script 46A is contingency-only.

## 3. Normal execution order

| Order | Script | Required result |
|---:|---|---|
| 1 | `tests/45_msbf_m1_7_preflight_validation_v0_2.sql` | `preflight_status = PASS` |
| 2 | `sql/46_msbf_m1_7_source_quality_data_confidence_generation_v0_2.sql` | 5,250 rows; `generation_status = PASS` |
| 3 | `sql/47_msbf_m1_7_source_quality_data_confidence_validation_v0_2.sql` | 55 rows; all `PASS` |
| 4 | `sql/48_msbf_m1_7_negative_control_tests_v0_2.sql` | 5 rows; all `PASS` |
| 5 | `sql/49_msbf_m1_7_acceptance_finalize_v0_2.sql` | Gate `PASS`; run `M1_7_ACCEPTED` |
| 6 | `tests/50_MSBF_M1_7_Source_Quality_Data_Confidence_Master_Report_v0_2.sql` | `overall_m1_7_status = PASS` |
| 7 | `tests/51_MSBF_M1_7_Source_Quality_Data_Confidence_Detail_Report_v0_2.sql` | 15 result sets; sets 13 and 15 empty |

## 4. Contingency script 46A

Run `tests/46A_msbf_m1_7_generation_reconciliation_reconstructed_v0_2.sql` only if script 46 committed but its result tab was lost. It is read-only. Required field: `generation_reconciliation_status = PASS`.

## 5. Preflight expectations

```text
run_status                         M1_6_ACCEPTED
population_status                  M1_2_ACCEPTED
prerequisite gates                 6 / 6 PASS
applications                       750
baseline POS rows                  135,000
baseline deposit rows              135,000
scenario POS rows                  270,000
scenario deposit rows              270,000
required parameter rows            18
required parameter names           12
contract-ready source families      7
existing M1.7 source rows           0
downstream analytical rows          0
blocking configuration errors       0
preflight_status                  PASS
```

## 6. Generation phases

Script 46 emits five notices:

```text
Phase 1/5 — validate configuration and materialize accepted inputs
Phase 2/5 — aggregate accepted daily histories once and calculate paired-source state
Phase 3/5 — transform the 5,250-row application/source grid
Phase 4/5 — persist snapshots, refresh statistics, and reconcile canonical rows
Phase 5/5 — committed generation checkpoint
```

Required checkpoint:

```text
run_status                  M1_7_GENERATED
source_snapshot_rows                 5,250
applications                            750
source_codes                              7
source_set_hash                    non-null
canonical_reconciliation expected=5250 actual=5250 mismatches=0
generation_status                       PASS
```

A 15-minute statement timeout fails closed. A timeout should be diagnosed rather than allowed to run indefinitely.

## 7. Validation and acceptance

Script 47 must return 55 of 55 `PASS` and set `run_status = M1_7_VALIDATED`.

Script 48 must return five `PASS` controls: missing parameter, unready source, invalid threshold ordering, run-status drift, and post-generation rerun rejection.

Script 49 accepts only with:

```text
55 / 55 positive PASS
5 / 5 negative PASS
5,250 rows | 750 applications | 7 sources
0 hash mismatches | 0 downstream rows | 0 blocking errors
```

Required final state:

```text
gate_id        M1_7_SOURCE_QUALITY_CONFIDENCE
result_status  PASS
run_status     M1_7_ACCEPTED
```

## 8. Evidence exports

Retain scripts 45–51 results and all fifteen detail-report result sets. If used, retain 46A with a short note explaining why generation evidence was reconstructed. Result set 13 and result set 15 must contain headers and zero rows.

## 9. Interpretation boundary

M1.7 evaluates synthetic source availability and fitness for downstream use. It is not production data-quality certification, consumer-reporting compliance, bank-statement verification, model validation, or a conclusion about a real merchant.
