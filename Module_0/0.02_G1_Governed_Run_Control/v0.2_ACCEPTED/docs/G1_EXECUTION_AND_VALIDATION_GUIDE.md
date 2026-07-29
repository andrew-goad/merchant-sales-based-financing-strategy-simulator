# G1 Execution and Validation Guide

## Purpose

This procedure takes the accepted G0 PostgreSQL foundation to the next governed milestone:

```text
G1 — Governed Run and Configuration Readiness
```

G1 must pass before M1.2 merchant generation begins.

## Prerequisites

- Database: `msbf_strategy`
- PostgreSQL: 14 or later; the accepted G0 environment used PostgreSQL 17.9
- G0 physical foundation: accepted and unchanged
- Module 1 analytical tables: empty
- User: an authorized project build user with INSERT/UPDATE/SELECT privileges on `msbf_ctl` and `msbf_m1`

## Safety rules

1. Confirm the active DBeaver editor is connected to `msbf_strategy` before every script.
2. Execute each file as a complete script using **Execute SQL Script**, not **Execute SQL Statement**.
3. Do not generate merchants, applications, POS history, or analytical outputs during G1.
4. Stop immediately if a script reports `G1_FAILED`, a blocking resolution error, or a PostgreSQL exception.
5. Do not edit frozen snapshot rows manually.
6. Do not rerun snapshot-construction scripts after the run reaches `G1_READY`.

---

# A. Recommended DBeaver procedure

## Step 1 — Create an evidence folder

Create a local folder such as:

```text
MSBF_G1_Evidence_20260723/
```

Recommended subfolders:

```text
execution_logs/
exports/
screenshots/
acceptance/
```

## Step 2 — Confirm database context

Run:

```sql
SELECT
    current_database() AS database_name,
    current_user AS database_user,
    current_setting('server_version') AS postgresql_version,
    clock_timestamp() AS execution_timestamp;
```

Expected database:

```text
msbf_strategy
```

## Step 3 — Run the read-only preflight

Open and execute:

```text
tests/00_msbf_g1_preflight_validation_v0_2.sql
```

Expected final row:

```text
preflight_status = PASS
```

The preflight expects the G0 state exactly:

| Metric | Expected before G1 |
|---|---:|
| Project schemas | 8 |
| Designed tables | 70 |
| Child table partitions | 4 |
| Physical table relations | 74 |
| Designed-table columns | 1,041 |
| Child-partition columns | 80 |
| View columns | 92 |
| Views | 5 |
| Functions | 3 |
| Designed primary keys | 70 |
| Designed foreign keys | 141 |
| Child-partition foreign keys | 20 |
| Parameter definitions | 155 |
| G0 parameter sets | 1 |
| G0 parameter values | 397 |
| Feature definitions | 32 |
| Industry segments | 8 |
| Module 1 analytical rows | 0 |

If preflight fails, do not continue.

## Step 4 — Bootstrap the governed run

Execute:

```text
sql/02_msbf_g1_run_configuration_bootstrap_v0_2.sql
```

Expected output:

```text
run_code                = M1_V0_2_BASELINE_BUILD
run_version             = 1
run_status              = READY_FOR_G1_VALIDATION
population_id           = MSBF_POP_0001
as_of_date              = 2026-07-23
parameter_set_code      = M1_G1_BASELINE_DEMO
parameter_set_version   = 1
planned_merchant_count  = 750
history_start_date      = 2026-01-25
history_end_date        = 2026-07-23
scenario_code           = BASELINE
contract_code           = M1_APPLICATION_RISK_SNAPSHOT
contract_version        = 1
```

### What the bootstrap adds

The bootstrap does not alter the accepted G0 parameter set. It creates:

- one G1-complete parameter set;
- four merchant-size funding/sales center values;
- one G1 policy;
- one G1 strategy;
- one baseline/stress scenario family;
- one baseline run;
- one deterministic population identity;
- jurisdiction, data, retention, financial-crime, payment-data, and third-party demonstration profiles;
- four Module 1 risk-appetite limits.

### Post-bootstrap count note

After bootstrap, total control-table counts are expected to increase. Do not continue using the G0 totals of one parameter set and 397 parameter values as current-database totals. G1 validation evaluates the selected G1 set directly:

```text
M1_G1_BASELINE_DEMO v1 = 401 rows / 155 parameter names
```

## Step 5 — Resolve and freeze parameters and profiles

Execute:

```text
sql/03_msbf_g1_parameter_resolution_and_profile_snapshot_v0_2.sql
```

Expected output:

| Field | Expected |
|---|---:|
| `run_status` | `READY_FOR_G1_VALIDATION` |
| `parameter_name_count` | 155 |
| `parameter_snapshot_rows` | 401 |
| `profile_snapshot_rows` | 18 |
| `blocking_resolution_errors` | 0 |
| `parameter_snapshot_hash` | non-null |
| `profile_snapshot_hash` | non-null |

If the output query returns no row, inspect:

```sql
SELECT *
FROM msbf_ctl.profile_resolution_error
WHERE run_id=(
    SELECT run_id FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1
)
ORDER BY severity, profile_domain, scope_key;
```

## Step 6 — Freeze source contracts and cutoffs

Execute:

```text
sql/04_msbf_g1_source_contract_snapshot_v0_2.sql
```

Expected output:

| Field | Expected |
|---|---:|
| `run_status` | `READY_FOR_G1_VALIDATION` |
| `source_snapshot_rows` | 7 |
| `contract_ready_rows` | 7 |
| `blocking_resolution_errors` | 0 |
| `source_snapshot_hash` | non-null |

Each source row should have:

```text
source_row_count = 0
quality_status   = CONTRACT_READY_PRE_GENERATION
```

## Step 7 — Verify hash repeatability before final acceptance

Record the three hashes:

```sql
SELECT
    parameter_snapshot_hash,
    profile_snapshot_hash,
    source_snapshot_hash
FROM msbf_ctl.run_registry
WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1;
```

Then rerun, in order:

```text
sql/03_msbf_g1_parameter_resolution_and_profile_snapshot_v0_2.sql
sql/04_msbf_g1_source_contract_snapshot_v0_2.sql
```

Run the hash query again. All three hashes must match exactly.

Save both hash result grids as evidence. This is the G1 reproducibility test.

## Step 8 — Run the 20 positive readiness checks

Execute:

```text
sql/05_msbf_g1_readiness_validation_v0_2.sql
```

Expected summary:

```text
run_status           = G1_VALIDATED
positive_check_count = 20
positive_pass_count  = 20
positive_fail_count  = 0
```

The second result set lists every check. All statuses must be `PASS`.

## Step 9 — Run the three negative controls

Execute:

```text
sql/06_msbf_g1_negative_control_tests_v0_2.sql
```

Expected evidence:

| Evidence code | Status |
|---|---|
| `G1_NEG_01_MISSING_PARAMETER_REJECTED` | PASS |
| `G1_NEG_02_AMBIGUOUS_PARAMETER_REJECTED` | PASS |
| `G1_NEG_03_MISSING_SOURCE_REJECTED` | PASS |

The run must remain:

```text
G1_VALIDATED
```

## Step 10 — Finalize G1 acceptance

Execute:

```text
sql/07_msbf_g1_acceptance_finalize_v0_2.sql
```

Expected result:

```text
run_status        = G1_READY
population_status = READY_FOR_GENERATION
gate_id           = G1_CONTROL_PLANE
result_status      = PASS
```

This is the only script that authorizes M1.2 merchant generation.

## Step 11 — Run the one-row master report

Execute:

```text
tests/08_MSBF_G1_Governed_Run_Readiness_Master_Report_v0_2.sql
```

Expected final field:

```text
overall_g1_status = PASS
```

Export the result grid as:

```text
MSBF_G1_Governed_Run_Readiness_Master_Report_v0_2_20260723.csv
```

## Step 12 — Run the detailed report

Execute:

```text
tests/09_MSBF_G1_Governed_Run_Readiness_Detail_Report_v0_2.sql
```

Export the result sets, preferably into one Excel workbook with separate sheets:

```text
MSBF_G1_Governed_Run_Readiness_Detail_Report_v0_2_20260723.xlsx
```

Suggested sheet names:

1. Run and Acceptance
2. G1 Evidence
3. Profile Snapshots
4. Source Snapshots
5. Parameter Scope Summary
6. Funding Centers
7. Resolution Errors

The Resolution Errors sheet should contain zero rows.

## Step 13 — Save execution logs

For each script, save or screenshot the DBeaver execution output showing successful completion. Preserve the first error if any script fails; do not continue after an exception.

## Step 14 — Complete the build-acceptance milestone

Use:

```text
evidence/templates/MSBF_G1_Governed_Run_Configuration_Build_Acceptance_Milestone_v0_2_template.txt
```

Populate:

- acceptance date/time;
- PostgreSQL version;
- final three hashes;
- evidence filenames;
- reviewer/owner;
- PASS conclusion.

Do not mark G1 accepted until the exported master report shows `overall_g1_status = PASS`.

---

# B. psql execution alternative

Run from the G1 package directory. Use `ON_ERROR_STOP` so psql stops on the first error.

```powershell
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 -f "tests\00_msbf_g1_preflight_validation_v0_2.sql"
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 -f "sql\02_msbf_g1_run_configuration_bootstrap_v0_2.sql"
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 -f "sql\03_msbf_g1_parameter_resolution_and_profile_snapshot_v0_2.sql"
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 -f "sql\04_msbf_g1_source_contract_snapshot_v0_2.sql"
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 -f "sql\05_msbf_g1_readiness_validation_v0_2.sql"
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 -f "sql\06_msbf_g1_negative_control_tests_v0_2.sql"
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 -f "sql\07_msbf_g1_acceptance_finalize_v0_2.sql"
```

Export the master report:

```powershell
psql -U postgres -d msbf_strategy -v ON_ERROR_STOP=1 --csv `
  -f "tests\08_MSBF_G1_Governed_Run_Readiness_Master_Report_v0_2.sql" `
  > "MSBF_G1_Governed_Run_Readiness_Master_Report_v0_2_20260723.csv"
```

---

# C. Expected final values

| Metric | Expected |
|---|---:|
| Run status | `G1_READY` |
| Population status | `READY_FOR_GENERATION` |
| Planned merchants | 750 |
| Inclusive history days | 180 |
| Parameter snapshot rows | 401 |
| Distinct parameter names | 155 |
| Funding-center rows | 4 |
| Profile snapshot rows | 18 |
| Profile domains | 15 |
| Risk-appetite limit rows | 4 |
| Feature-set snapshot rows | 1 |
| Source snapshot rows | 7 |
| Source codes | 7 |
| Approved scenarios in set | 2 |
| Active feature definitions | 32 |
| Positive readiness checks | 20 / 20 PASS |
| Negative controls | 3 / 3 PASS |
| Blocking resolution errors | 0 |
| Analytical rows | 0 |
| G1 gate status | PASS |
| Master-report status | PASS |

The three hash values are environment-generated and should not be compared to a hard-coded value. They must be non-null and must reconcile to their independently recomputed values.

---

# D. Troubleshooting

## Transaction is aborted

Run:

```sql
ROLLBACK;
```

Then locate the first error. Later “current transaction is aborted” messages are secondary.

## Script 03 returns no summary row

Inspect `msbf_ctl.profile_resolution_error`. The script intentionally does not create snapshots after a blocking error.

## Script 05 sets `G1_FAILED`

Run:

```sql
SELECT evidence_code, status, metric_value_text, interpretation
FROM msbf_ctl.run_evidence
WHERE run_id=(SELECT run_id FROM msbf_ctl.run_registry
              WHERE run_code='M1_V0_2_BASELINE_BUILD' AND run_version=1)
  AND evidence_code LIKE 'G1_POS_%'
ORDER BY evidence_code;
```

Correct the failed configuration; rerun scripts 03, 04, and 05.

## Script 06 fails

A negative-control failure means the invalid temporary state was not detected. Do not finalize G1.

## Finalizer returns FAIL

Review the latest `G1_CONTROL_PLANE` acceptance row and all `G1_POS_%` / `G1_NEG_%` evidence. Correct the issue, rerun scripts 03–06, then rerun the finalizer. A new immutable review version will be written.

## Run is already `G1_READY`

This is expected after acceptance. Snapshot scripts are designed to fail closed after G1. Use the report scripts only. A materially different configuration should use a new run version rather than rewriting the accepted run.

---

# E. Evidence package checklist

Retain at minimum:

- all seven executed G1 SQL files;
- preflight output;
- before/after reproducibility hash exports;
- positive-check result export;
- negative-control result export;
- master report CSV;
- detailed report workbook or result exports;
- DBeaver or psql execution logs;
- completed G1 acceptance milestone;
- package manifest and checksums.

Once these are reviewed and approved, the main project ZIP can be updated to include the accepted G1 milestone and evidence.
