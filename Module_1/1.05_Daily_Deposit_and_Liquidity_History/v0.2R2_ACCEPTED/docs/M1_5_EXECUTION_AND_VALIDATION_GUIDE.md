# M1.5 Execution and Validation Guide

## 1. Environment

Execute against the accepted PostgreSQL database used for G0 through M1.4.

```text
Database:   msbf_strategy
PostgreSQL: 14 or later
Tool:       DBeaver or psql
```

Before each script, confirm:

```sql
SELECT current_database(),current_user,current_setting('server_version'),clock_timestamp();
```

Required database:

```text
msbf_strategy
```

## 2. DBeaver operating rules

1. Confirm the active editor connection is `msbf_strategy`.
2. Use **Execute SQL Script**, not current-statement execution.
3. Stop on the first PostgreSQL exception.
4. Never select Retry, Skip, or Skip All after a failure.
5. Execute `ROLLBACK;` after a failed transactional script.
6. Do not manually delete generated M1.5 rows.
7. After script 32 commits, never rerun it. Validation regenerates the expected blueprint without rewriting history.
8. Structured CSV exports are sufficient evidence; execution logs are optional unless diagnosing a failure.

## 3. Exact execution order

| Order | File | Required result |
|---:|---|---|
| 1 | `tests/31_msbf_m1_5_preflight_validation_v0_2.sql` | `preflight_status = PASS` |
| 2 | `sql/32_msbf_m1_5_daily_deposit_liquidity_generation_v0_2.sql` | 135,000 rows; 750 merchants; 180 dates; non-null hash |
| 3 | `sql/33_msbf_m1_5_daily_deposit_liquidity_validation_v0_2.sql` | 56 rows; every status `PASS` |
| 4 | `sql/34_msbf_m1_5_negative_control_tests_v0_2.sql` | 4 rows; every status `PASS` |
| 5 | `sql/35_msbf_m1_5_acceptance_finalize_v0_2.sql` | Gate `PASS`; run status `M1_5_ACCEPTED` |
| 6 | `tests/36_MSBF_M1_5_Daily_Deposit_Liquidity_Master_Report_v0_2.sql` | `overall_m1_5_status = PASS` |
| 7 | `tests/37_MSBF_M1_5_Daily_Deposit_Liquidity_Detail_Report_v0_2.sql` | 14 result sets; mismatch/error sets empty |

## 4. Preflight expectations

The preflight must confirm:

```text
run_status                    M1_4_ACCEPTED
population_status             M1_2_ACCEPTED
merchant_count                750
history_days                  180
base POS rows                 135,000
required parameter pairs      32 / 32
deposit source rows           1 / 1 ready / 1 approved
existing base deposit rows    0
scenario and downstream rows  0
blocking errors               0
preflight_status              PASS
```

The accepted upstream hashes must remain:

```text
Parameter  bd09e598c82db96e47459d77fd11e7c8
Profile    462cbd2ed92f68e5bdecf6b17537a973
Source     93c3d1368fb2450ab4a08e2b721f92d3
Population 9b706c926260a3ef1ae8ac95eed5d0bf
Application 01485256b9b5748fb412743d35ced602
POS history d1971e8d319483c187ec0c0483a31e33
```

## 5. Generation expectations

Required checkpoint:

```text
deposit_rows          135,000
merchants                  750
dates                      180
minimum_date     2026-01-25
maximum_date     2026-07-23
row mismatches               0
stored hash           non-null
run_status       M1_5_GENERATED
```

Do not compare total synthetic deposits or balances to a predetermined numerical target. Live outputs are authoritative and are accepted through accounting, range, direction, deterministic, and stage-boundary controls.

## 6. Positive validation

The validation script must return exactly 56 evidence rows, all `PASS`, and set:

```text
run_status = M1_5_VALIDATED
```

The controls cover upstream identity, structural integrity, temporal controls, source lineage, accounting identities, balance continuity, liquidity differentiation, source observability, existing-financing pressure, exact reproduction, and strict stage boundaries.

## 7. Negative controls

Required:

```text
M1_5_NEG_01_MISSING_PARAMETER_REJECTED    PASS
M1_5_NEG_02_SOURCE_NOT_READY_REJECTED     PASS
M1_5_NEG_03_HISTORY_DRIFT_REJECTED        PASS
M1_5_NEG_04_REGENERATION_REJECTED         PASS
```

Each mutation executes inside a PL/pgSQL exception subtransaction and is rolled back automatically.

## 8. Final acceptance

Required final state:

```text
gate_id             M1_5_DAILY_DEPOSIT_LIQUIDITY
gate_status         PASS
run_status          M1_5_ACCEPTED
population_status   M1_2_ACCEPTED
positive checks     56 / 56 PASS
negative controls    4 / 4 PASS
row mismatches             0
downstream rows            0
blocking errors            0
overall_m1_5_status        PASS
```

## 9. Evidence exports

Retain:

- preflight result;
- generation checkpoint;
- 56-row positive-validation result;
- four-row negative-control result;
- acceptance-finalizer result;
- one-row master report;
- all 14 detailed-report result sets;
- completed acceptance milestone after independent review.

The mismatch and blocking-error exports must retain headers and contain zero data rows.

## 10. Failure recovery

If preflight fails, do not continue. Resolve the upstream condition and rerun preflight.

If generation fails before commit:

1. click **Stop**;
2. execute `ROLLBACK;`;
3. verify zero M1.5 physical rows;
4. send the first PostgreSQL error, SQLSTATE, line, statement, detail, and hint for review.

If validation fails after generation commits, preserve the generated rows. Do not regenerate. Review the failed evidence code and correct only the validation or generation defect through a controlled revision.
