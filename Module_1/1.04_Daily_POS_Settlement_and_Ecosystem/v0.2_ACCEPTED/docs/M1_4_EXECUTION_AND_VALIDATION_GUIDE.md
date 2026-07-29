# M1.4 Execution and Validation Guide

## 1. Environment

Execute against the same accepted PostgreSQL database used for G0, G1, M1.2, and M1.3.

Recommended environment:

```text
Database:   msbf_strategy
PostgreSQL: 14 or later
Tool:       DBeaver or psql
```

The accepted project has already executed on PostgreSQL 17.9. A reconnect or new DBeaver editor does not affect committed state, but every editor must point to the correct database.

Before each script, confirm:

```sql
SELECT current_database(),current_user,current_setting('server_version'),clock_timestamp();
```

Required database:

```text
msbf_strategy
```

## 2. DBeaver operating rules

1. Open each file from the M1.4 package.
2. Confirm the active connection is `msbf_strategy`.
3. Use **Execute SQL Script**, not current-statement execution.
4. Stop on the first PostgreSQL exception.
5. Do not select Retry, Skip, or Skip All after a failure.
6. If a transactional script fails, execute `ROLLBACK;` in that connection.
7. Do not delete persisted M1.4 data to force a rerun.
8. After script 25 commits, never rerun it. Deterministic validation regenerates an expected blueprint without rewriting physical history.
9. Structured CSV exports are sufficient evidence for this portfolio project; execution logs are optional unless troubleshooting a failure.

## 3. Exact execution order

| Order | File | Required result |
|---:|---|---|
| 1 | `tests/24_msbf_m1_4_preflight_validation_v0_2.sql` | `preflight_status = PASS` |
| 2 | `sql/25_msbf_m1_4_enterprise_merchant_ecosystem_generation_v0_2.sql` | 135,000 rows, 750 merchants, 180 dates, non-null history hash |
| 3 | `sql/26_msbf_m1_4_enterprise_merchant_ecosystem_validation_v0_2.sql` | 52 rows, every status `PASS` |
| 4 | `sql/27_msbf_m1_4_negative_control_tests_v0_2.sql` | Four controls, every status `PASS` |
| 5 | `sql/28_msbf_m1_4_acceptance_finalize_v0_2.sql` | Latest M1.4 gate `PASS`; run `M1_4_ACCEPTED` |
| 6 | `tests/29_MSBF_M1_4_Enterprise_Merchant_Ecosystem_Master_Report_v0_2.sql` | `overall_m1_4_status = PASS` |
| 7 | `tests/30_MSBF_M1_4_Enterprise_Merchant_Ecosystem_Detail_Report_v0_2.sql` | Deterministic-mismatch and blocking-error result sets are empty |

## 4. Preflight expectation

The preflight is read-only. Required values include:

```text
run_status                M1_3_ACCEPTED
population_status         M1_2_ACCEPTED
G1 gate                   PASS
M1.2 gate                 PASS
M1.3 gate                 PASS
merchant rows             750
application rows          750
history days              180
expected POS rows         135,000
required parameter pairs  86
resolved parameter pairs  86
POS_DAILY source rows     1
contract-ready rows       1
existing baseline rows    0
scenario POS rows         0
downstream rows           0
blocking errors           0
preflight_status           PASS
```

It also recomputes and verifies the accepted G1, M1.2, and M1.3 hashes.

## 5. Generation expectation

Script 25 is transactional. It creates the M1.4 functions, builds a temporary deterministic blueprint, verifies its cardinality, persists the daily fact rows, and then independently compares the expected and actual canonical snapshots before commit.

Required checkpoint:

```text
run_status       M1_4_GENERATED
POS rows         135,000
merchants        750
dates            180
minimum date     2026-01-25
maximum date     2026-07-23
stored hash      non-null
```

The gross-sales, eligible-sales, settlement, zero-day, outage, degradation, and pre-open values should be taken from the live database. They are deterministic outputs, not externally calibrated benchmarks.

## 6. Positive validation

Script 26 persists 52 blocking checks. Every row must have:

```text
status = PASS
```

The checks cover:

- accepted upstream gates and hashes;
- exact row, merchant, date, and grain counts;
- temporal and source lineage;
- processor and connection-state coherence;
- accounting identities;
- lagged settlement reproduction;
- deterministic row and set hashes;
- industry and archetype diversity;
- zero-sales, outage, degradation, refund, chargeback, and reversal ranges;
- growing, declining, disruption, weekend, calendar, and fee behavior;
- strict downstream stage boundaries;
- zero blocking configuration errors.

Successful validation sets:

```text
run_status = M1_4_VALIDATED
```

If any check fails, the run becomes `M1_4_FAILED`. Do not alter data or rerun generation. Export the failed evidence and provide it for diagnosis.

## 7. Negative controls

Script 27 demonstrates fail-closed behavior through transactional subtests. Each temporary mutation rolls back inside its own exception block.

Required results:

```text
M1_4_NEG_01_MISSING_PARAMETER_REJECTED  PASS
M1_4_NEG_02_SOURCE_NOT_READY_REJECTED   PASS
M1_4_NEG_03_HISTORY_DRIFT_REJECTED      PASS
M1_4_NEG_04_REGENERATION_REJECTED       PASS
```

## 8. Acceptance finalization

Script 28 requires:

```text
52 / 52 positive checks PASS
4 / 4 negative controls PASS
0 failed evidence records
0 row-level mismatches
135,000 POS rows
750 merchants
180 dates
stored hash = expected hash = actual hash
0 downstream rows
0 blocking errors
```

Required final state:

```text
gate_id             M1_4_DAILY_POS_HISTORY
result_status       PASS
run_status          M1_4_ACCEPTED
population_status   M1_2_ACCEPTED
```

The population status does not change because M1.4 adds operating history to the accepted merchant population; it does not replace the population.

## 9. Master report

The final master-report field must equal:

```text
overall_m1_4_status = PASS
```

This report is the canonical one-row stage summary and should be exported as CSV.

## 10. Detail report result sets

Script 30 produces fourteen result sets:

1. Run and Acceptance State
2. Entity and Stage-Boundary Row Counts
3. Industry Operating Diagnostics
4. Cash-Flow Archetype Diagnostics
5. Processor and Connection Status Diagnostics
6. Partner/Channel Settlement and Fee Diagnostics
7. Day-of-Week and Industry Pattern
8. Calendar and Bounded Operating-Event Diagnostics
9. Merchant Operating-Pattern Examples
10. Transaction-Quality Diagnostics by Industry
11. Settlement-Delay Reproduction
12. Row-Level Deterministic Mismatches
13. M1.4 Evidence
14. Blocking Resolution Errors

Result sets 12 and 14 must contain headers and zero data rows.

## 11. Evidence filenames

Recommended names:

```text
24_msbf_m1_4_preflight_validation_v0_2_results_YYYYMMDD.csv
25_msbf_m1_4_enterprise_merchant_ecosystem_generation_v0_2_results_YYYYMMDD.csv
26_msbf_m1_4_enterprise_merchant_ecosystem_validation_v0_2_results_YYYYMMDD.csv
27_msbf_m1_4_negative_control_tests_v0_2_results_YYYYMMDD.csv
28_msbf_m1_4_acceptance_finalize_v0_2_results_YYYYMMDD.csv
MSBF_M1_4_Enterprise_Merchant_Ecosystem_Master_Report_v0_2_YYYYMMDD.csv
MSBF_M1_4_Enterprise_Merchant_Ecosystem_Detail_Report_v0_2_<Result_Set>_YYYYMMDD.csv
```

Complete the acceptance-milestone template only after the evidence is independently reviewed and signed off.

## 12. Failure recovery

### Preflight failure

Do not run generation. Review the failed counts, gates, hashes, parameters, source contract, or unexpected rows.

### Generation failure before commit

Execute:

```sql
ROLLBACK;
```

Then confirm:

```sql
SELECT COUNT(*)
FROM msbf_m1.merchant_pos_daily_base
WHERE generated_by_run_id=(
  SELECT run_id FROM msbf_ctl.run_registry
  WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
);
```

Expected after a fully rolled-back failure:

```text
0
```

Do not manually delete data if the count is nonzero. Preserve the state and request a controlled recovery assessment.

### Validation failure after successful generation

Do not rerun script 25. The persisted data and hash should remain intact. A corrected validation package can update review evidence while retaining the original failed gate version as audit history.

## 13. Production boundary

Passing M1.4 demonstrates deterministic synthetic-data engineering and governed validation. It does not establish that the simulated behavior matches any lender, merchant sector, processor, economy, or legal product in production.
