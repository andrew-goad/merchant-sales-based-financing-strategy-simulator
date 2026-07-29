# M1.6 Execution and Validation Guide

## 1. Environment

Execute against the accepted PostgreSQL database used for G0 through M1.5.

```text
Database:   msbf_strategy
PostgreSQL: 14 or later
Tool:       DBeaver or psql
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
6. Do not delete or update accepted baseline POS/deposit rows.
7. After script 39 commits, do not rerun it.
8. Structured CSV exports are sufficient evidence; execution logs are optional unless diagnosing a failure.

## 3. Exact execution order

| Order | Script | Required result |
|---:|---|---|
| 1 | `tests/38_msbf_m1_6_preflight_validation_v0_2.sql` | `preflight_status = PASS` |
| 2 | `sql/39_msbf_m1_6_matched_scenario_overlay_generation_v0_2.sql` | 270,000 POS rows; 270,000 deposit rows; `generation_status = PASS` |
| 3 | `sql/40_msbf_m1_6_matched_scenario_overlay_validation_v0_2.sql` | 62 rows; all `PASS` |
| 4 | `sql/41_msbf_m1_6_negative_control_tests_v0_2.sql` | 5 rows; all `PASS` |
| 5 | `sql/42_msbf_m1_6_acceptance_finalize_v0_2.sql` | Gate `PASS`; run `M1_6_ACCEPTED` |
| 6 | `tests/43_MSBF_M1_6_Matched_Scenario_Overlay_Master_Report_v0_2.sql` | `overall_m1_6_status = PASS` |
| 7 | `tests/44_MSBF_M1_6_Matched_Scenario_Overlay_Detail_Report_v0_2.sql` | 16 result sets; mismatch/error sets empty |

## 4. Preflight expectations

The preflight must show:

```text
run_status                       M1_5_ACCEPTED
population_status                M1_2_ACCEPTED
merchant rows                    750
application rows                 750
base POS rows                    135,000
base deposit rows                135,000
history days                     180
approved scenarios               2
BASELINE scenarios               1
RECESSION_ENERGY scenarios       1
required parameter pairs         32 / 32
POS source ready                 1
DEPOSIT source ready             1
scenario POS rows                0
scenario deposit rows            0
downstream analytical rows        0
blocking errors                   0
preflight_status                 PASS
```

## 5. Generation checkpoint

Script 39 creates the helper functions and scenario rows inside one transaction. Required output:

```text
run_status               M1_6_GENERATED
POS scenario rows         270,000
Deposit scenario rows     270,000
BASELINE rows/entity      135,000
RECESSION rows/entity     135,000
POS hash                  non-null
Deposit hash              non-null
Combined hash             non-null
generation_status         PASS
```

After a successful commit, do not rerun script 39. If DBeaver loses the result tab, reconstruct the checkpoint from the persisted rows and `M1_6_*_SET_HASH` evidence rather than resetting the run.

## 6. Positive validation

Script 40 produces 62 blocking controls. Every row must return `PASS`. Key controls include:

- accepted upstream gate and hash preservation;
- exact scenario cardinality and grain;
- exact BASELINE reproduction;
- exact pre-shock stress reproduction;
- 45,000 direct-window rows and 39,750 propagated-window rows;
- factor and payload controls;
- POS accounting and settlement-delay reproduction;
- expected aggregate stress directions;
- energy-versus-healthcare sensitivity ordering;
- deposit accounting and balance roll-forward;
- deterministic row and set-hash reproduction;
- complete matched POS/deposit share;
- strict stage boundary.

Expected final state: `run_status = M1_6_VALIDATED`.

## 7. Negative controls

Script 41 must return five `PASS` rows:

1. missing required scenario parameter rejected;
2. unapproved stress scenario rejected;
3. scenario-history disablement rejected;
4. accepted history-window drift rejected;
5. post-generation rerun rejected.

The mutations execute inside PL/pgSQL exception subtransactions and roll back automatically.

## 8. Acceptance finalization

Script 42 passes only when:

```text
62 / 62 positive checks PASS
5 / 5 negative controls PASS
270,000 POS scenario rows
270,000 deposit scenario rows
2 scenarios
750 merchants
180 dates
540,000 expected and actual canonical rows
0 row-level mismatches
stored POS/deposit/combined hashes reconcile
0 downstream rows
0 blocking errors
```

Required final state:

```text
gate_id       M1_6_MATCHED_SCENARIO_OVERLAYS
result_status PASS
run_status    M1_6_ACCEPTED
```

## 9. Evidence exports

Retain:

- preflight result;
- generation checkpoint;
- 62-row positive-validation result;
- five-row negative-control result;
- acceptance-finalizer result;
- one-row master report;
- all sixteen detailed-report result sets;
- completed acceptance milestone after independent review.

The Row-Level Deterministic Mismatches and Blocking Resolution Errors outputs must retain headers and contain zero rows.

## 10. Interpretation boundary

The scenario design is a controlled synthetic sensitivity. It is not an economic forecast, calibrated stress model, production underwriting policy, accounting estimate, regulatory capital result, or legal/compliance conclusion.
