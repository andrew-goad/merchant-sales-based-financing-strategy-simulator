# M1.2 Execution and Validation Guide

> **v0.2R2 correction:** The v0.2R1 generation transaction rolled back after 817 canonical hashes differed solely because expected zero-valued numerics were represented as `0` while fixed-scale physical columns were represented as `0.00`. This release canonicalizes monetary and rate fields to physical types before hashing. Execute `ROLLBACK;`, confirm M1.2 tables remain empty, then restart from preflight. G0 and G1 do not need to be rerun.

> **v0.2R1 correction retained:** The frozen G1 `resolved_value` column is a structured JSONB object. This release extracts the typed `value_numeric` member explicitly. If the earlier v0.2 preflight failed with SQLSTATE `22P02`, execute `ROLLBACK;` if your session is in an aborted transaction, then run this corrected package from Step 1. The failed preflight was read-only.


## 1. Purpose

This guide provides the controlled live-execution procedure for **M1.2 — Deterministic Merchant Population Generation v0.2R2**. The stage creates and validates the 750-merchant synthetic population authorized by the accepted G1 configuration.

M1.2 must be executed only after:

```text
G0 Physical PostgreSQL Foundation       PASS
G1 Governed Run and Configuration       PASS
run_status                              G1_READY
population_status                       READY_FOR_GENERATION
```

The stage is intentionally one-time and non-destructive. After the generation transaction commits, **do not rerun the generation script**. Deterministic repeatability is validated by regenerating the blueprint in functions and comparing every persisted row hash, not by deleting and recreating accepted data.

---

## 2. Target environment

The accepted project database is:

```text
Database       msbf_strategy
Run code       M1_V0_2_BASELINE_BUILD
Run version    1
Population     MSBF_POP_0001
Merchants      750
As-of date     2026-07-23
```

The package is designed for PostgreSQL 14 or later. The accepted G0/G1 environment used PostgreSQL 17.9 on 64-bit Windows.

Before each script, confirm the active database:

```sql
SELECT
    current_database() AS database_name,
    current_user AS database_user,
    current_setting('server_version') AS postgresql_version,
    clock_timestamp() AS execution_timestamp;
```

Required:

```text
database_name = msbf_strategy
```

---

## 2A. Recovery from the failed v0.2R1 generation

The generation script was enclosed in an explicit transaction. After the exception:

```sql
ROLLBACK;
```

Then execute the optional read-only recovery check:

```text
tests/09_msbf_m1_2_failed_generation_recovery_check_v0_2R2.sql
```

Required result:

```text
run_status            = G1_READY
population_status     = READY_FOR_GENERATION
all M1.2 entity rows  = 0
recovery_state_status = PASS
```

Do not manually delete rows and do not rerun G0 or G1.

---

## 3. Files and exact execution order

| Order | File | Purpose | Required checkpoint |
|---:|---|---|---|
| 1 | `tests/10_msbf_m1_2_preflight_validation_v0_2.sql` | Confirm accepted G1 identity, hashes, sources, parameter mixes, empty M1.2 state, and empty downstream state | `preflight_status = PASS` |
| 2 | `sql/11_msbf_m1_2_deterministic_merchant_population_v0_2.sql` | Create deterministic helper functions and persist the population once | Run and population become `M1_2_GENERATED`; counts and canonical hash reconcile |
| 3 | `sql/12_msbf_m1_2_population_validation_v0_2.sql` | Execute and persist 36 positive checks | `positive_checks = 36`, `positive_passes = 36`, `positive_failures = 0`; run becomes `M1_2_VALIDATED` |
| 4 | `sql/13_msbf_m1_2_negative_control_tests_v0_2.sql` | Prove missing, invalid, and unauthorized inputs fail closed | `3 / 3 PASS` |
| 5 | `sql/14_msbf_m1_2_acceptance_finalize_v0_2.sql` | Resolve the formal M1.2 gate | Run and population become `M1_2_ACCEPTED`; gate result `PASS` |
| 6 | `tests/15_MSBF_M1_2_Deterministic_Merchant_Population_Master_Report_v0_2.sql` | Produce the one-row acceptance report | `overall_m1_2_status = PASS` |
| 7 | `tests/16_MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2.sql` | Produce detailed evidence result sets | Mismatch and blocking-error result sets contain zero rows |

---

## 4. DBeaver execution method

### 4.1 Use the correct editor connection

For every file:

1. Open the SQL script in DBeaver.
2. Confirm the active connection points to `msbf_strategy`.
3. Execute the entire script using **Execute SQL Script**, not Execute Statement.
4. Review the first error if any.
5. Do not proceed to the next script until the current checkpoint passes.

Each implementation script contains its own `BEGIN`/`COMMIT` transaction. Do not wrap it in another manual transaction.

### 4.2 Error handling

If a script fails before its internal commit:

```sql
ROLLBACK;
```

Capture:

- SQLSTATE;
- complete error message;
- failed line or statement;
- error detail and hint;
- the first preceding error if PostgreSQL reports an aborted transaction.

Do not edit persisted rows manually. Stop and correct the stage logic or configuration first.

---

## 5. Step 1 — Preflight validation

Execute:

```text
tests/10_msbf_m1_2_preflight_validation_v0_2.sql
```

### Required result

The final field must equal:

```text
preflight_status = PASS
```

Expected core observations:

| Metric | Expected |
|---|---:|
| Run status | `G1_READY` |
| Population status | `READY_FOR_GENERATION` |
| Planned merchant count | 750 |
| Parameter snapshot rows | 401 |
| Required parameter names | 155 |
| Profile snapshot rows | 18 |
| Profile domains | 15 |
| Source snapshot rows | 7 |
| Contract-ready source rows | 7 |
| Governed mix parameter families | 5 |
| Valid weight-sum families | 5 |
| Existing M1.2 rows | 0 |
| Downstream analytical rows | 0 |
| Blocking resolution errors | 0 |

The three accepted and recomputed G1 hashes must match:

```text
Parameter  bd09e598c82db96e47459d77fd11e7c8
Profile    462cbd2ed92f68e5bdecf6b17537a973
Source     93c3d1368fb2450ab4a08e2b721f92d3
```

### Evidence export

Export the result grid as:

```text
10_msbf_m1_2_preflight_validation_v0_2_results_20260723.csv
```

If the query returns no row or `FAIL`, do not run generation.

---

## 6. Step 2 — Generate the deterministic population

Execute once:

```text
sql/11_msbf_m1_2_deterministic_merchant_population_v0_2.sql
```

### What the script does

The script:

1. registers the M1.2 acceptance gate;
2. creates seven deterministic helper/blueprint functions;
3. revalidates the accepted G1 configuration and hashes;
4. rejects any pre-existing M1.2 or downstream rows;
5. assigns exact category quotas using largest remainder and deterministic ranking;
6. inserts merchant, industry, channel, processor, relationship, and owner records;
7. independently regenerates expected and actual canonical snapshots;
8. rejects the transaction if any canonical row differs;
9. stores the deterministic population hash;
10. changes the run and population to `M1_2_GENERATED`.

### Required checkpoint

| Object | Expected rows |
|---|---:|
| `merchant_master` | 750 |
| `merchant_owner_guarantor` | 1,347 |
| `merchant_industry_assignment` | 750 |
| `partner_channel` | 5 |
| `processor_account` | 750 |
| `merchant_relationship_snapshot` | 750 |
| Expected canonical entities | 4,352 |
| Actual canonical entities | 4,352 |
| Row-level mismatches | 0 |

Required state:

```text
run_status        = M1_2_GENERATED
population_status = M1_2_GENERATED
population_hash   = non-null
```

### Critical rerun rule

After a successful commit, do **not** rerun this file. The generation authorization function is designed to reject a second generation attempt.

Determinism will be proven in Steps 3–7 through expected-versus-actual regenerated blueprints and hash equality.

### Evidence export

Export the final result grid as:

```text
11_msbf_m1_2_deterministic_merchant_population_v0_2_results_20260723.csv
```

Retain the DBeaver execution log as:

```text
11_msbf_m1_2_deterministic_merchant_population_v0_2_execution_20260723.log
```

---

## 7. Step 3 — Positive population validation

Execute:

```text
sql/12_msbf_m1_2_population_validation_v0_2.sql
```

The script persists 36 validation checks covering:

- stage and G1 state;
- accepted and recomputed hashes;
- generation-specification identity;
- row counts and key uniqueness;
- exact industry, region, size, relationship, legal, and channel mixes;
- business-age and processor-tenure chronology;
- owner/guarantor counts and coherence;
- relationship snapshot determinism;
- mixed-signal realism;
- expected-versus-actual canonical rows and hashes;
- zero downstream records;
- zero blocking configuration errors.

### Required checkpoint

```text
positive_checks   = 36
positive_passes   = 36
positive_failures = 0
run_status        = M1_2_VALIDATED
```

Export the summary result as:

```text
12_msbf_m1_2_population_validation_v0_2_results_20260723.csv
```

If one or more checks fail, the script sets the run to `M1_2_FAILED`. Do not proceed to negative controls or finalization.

Inspect failed checks with:

```sql
SELECT
    evidence_code,
    metric_name,
    metric_value_numeric,
    metric_value_text,
    threshold_value_numeric,
    status,
    interpretation
FROM msbf_ctl.run_evidence
WHERE run_id = (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
)
  AND evidence_code LIKE 'M1_2_POS_%'
  AND status <> 'PASS'
ORDER BY evidence_code;
```

---

## 8. Step 4 — Negative controls

Execute:

```text
sql/13_msbf_m1_2_negative_control_tests_v0_2.sql
```

The tests use controlled function calls only and do not alter the accepted population.

| Control | Expected behavior |
|---|---|
| Missing mix parameter | Assignment function raises an exception before producing rows |
| Invalid JSON weight sum | Assignment function rejects weights that do not sum to one |
| Regeneration after persistence | Generation authorization rejects a second build |

### Required result

```text
M1_2_NEG_01_MISSING_PARAMETER_REJECTED   PASS
M1_2_NEG_02_INVALID_WEIGHT_SUM            PASS
M1_2_NEG_03_REGENERATION_REJECTED         PASS
```

Export as:

```text
13_msbf_m1_2_negative_control_tests_v0_2_results_20260723.csv
```

---

## 9. Step 5 — Finalize M1.2 acceptance

Execute:

```text
sql/14_msbf_m1_2_acceptance_finalize_v0_2.sql
```

The finalizer independently rechecks:

- 36 positive checks and 36 passes;
- three negative controls and three passes;
- zero failed evidence rows;
- zero row-level canonical mismatches;
- equality of expected, actual, and stored population hashes;
- zero downstream analytical rows.

### Required result

```text
run_status          = M1_2_ACCEPTED
population_status   = M1_2_ACCEPTED
gate_id             = M1_2_POPULATION
result_status        = PASS
```

Export as:

```text
14_msbf_m1_2_acceptance_finalize_v0_2_results_20260723.csv
```

The finalizer is idempotent after acceptance: a second call records no duplicate acceptance and returns a notice. Routine rerunning is unnecessary.

---

## 10. Step 6 — Master acceptance report

Execute:

```text
tests/15_MSBF_M1_2_Deterministic_Merchant_Population_Master_Report_v0_2.sql
```

The one-row report must end with:

```text
overall_m1_2_status = PASS
```

It must also show:

```text
merchant rows                  750
owner rows                   1,347
industry rows                  750
partner channels                 5
processor accounts             750
relationship snapshots         750
canonical expected rows      4,352
canonical actual rows        4,352
canonical mismatches              0
positive checks                 36
positive passes                 36
negative controls                3
negative passes                  3
downstream rows                  0
blocking errors                  0
```

Export as:

```text
MSBF_M1_2_Deterministic_Merchant_Population_Master_Report_v0_2_20260723.csv
```

---

## 11. Step 7 — Detailed evidence report

Execute:

```text
tests/16_MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2.sql
```

The file produces ten result sets.

| Result set | Recommended export name | Acceptance expectation |
|---:|---|---|
| 1 | `..._Run_And_Acceptance_20260723.csv` | Accepted statuses and PASS gate |
| 2 | `..._Entity_Row_Counts_20260723.csv` | Six M1.2 entity counts plus downstream zeros |
| 3 | `..._Governed_Mix_Reconciliation_20260723.csv` | Every row `PASS`; every delta zero |
| 4 | `..._Relationship_Diagnostics_20260723.csv` | Four relationship stages populated |
| 5 | `..._Owner_Guarantor_Summary_20260723.csv` | Valid score bands and counts |
| 6 | `..._Processor_Partner_Summary_20260723.csv` | Five channel rows; 750 accounts total |
| 7 | `..._Mixed_Signal_Examples_20260723.csv` | Representative examples present |
| 8 | `..._Row_Level_Deterministic_Mismatches_20260723.csv` | Header only; zero data rows |
| 9 | `..._M1_2_Evidence_20260723.csv` | 36 positive, three negative, acceptance summary, generation evidence |
| 10 | `..._Blocking_Resolution_Errors_20260723.csv` | Header only; zero data rows |

DBeaver may display each result set in a separate result tab. Export each tab separately, or export them to separate worksheets in a single workbook.

---

## 12. Independent spot-check queries

### 12.1 Accepted state

```sql
SELECT
    r.run_id,
    r.run_code,
    r.run_version,
    r.run_status,
    p.population_id,
    p.population_status,
    p.population_hash,
    r.parameter_snapshot_hash,
    r.profile_snapshot_hash,
    r.source_snapshot_hash
FROM msbf_ctl.run_registry r
JOIN msbf_m1.population_registry p
  ON p.population_id=r.population_id
WHERE r.run_code='M1_V0_2_BASELINE_BUILD'
  AND r.run_version=1;
```

### 12.2 Entity reconciliation

```sql
WITH r AS (
    SELECT run_id, population_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
)
SELECT * FROM (VALUES
  ('merchant_master',
   (SELECT COUNT(*) FROM msbf_m1.merchant_master WHERE population_id=(SELECT population_id FROM r))),
  ('merchant_owner_guarantor',
   (SELECT COUNT(*) FROM msbf_m1.merchant_owner_guarantor o
     JOIN msbf_m1.merchant_master m ON m.merchant_id=o.merchant_id
    WHERE m.population_id=(SELECT population_id FROM r))),
  ('merchant_industry_assignment',
   (SELECT COUNT(*) FROM msbf_m1.merchant_industry_assignment i
     JOIN msbf_m1.merchant_master m ON m.merchant_id=i.merchant_id
    WHERE m.population_id=(SELECT population_id FROM r))),
  ('partner_channel',
   (SELECT COUNT(*) FROM msbf_m1.partner_channel WHERE created_by_run_id=(SELECT run_id FROM r))),
  ('processor_account',
   (SELECT COUNT(*) FROM msbf_m1.processor_account WHERE created_by_run_id=(SELECT run_id FROM r))),
  ('merchant_relationship_snapshot',
   (SELECT COUNT(*) FROM msbf_m1.merchant_relationship_snapshot WHERE created_by_run_id=(SELECT run_id FROM r)))
) x(entity_name,row_count)
ORDER BY entity_name;
```

### 12.3 Canonical deterministic equality

```sql
WITH r AS (
    SELECT run_id
    FROM msbf_ctl.run_registry
    WHERE run_code='M1_V0_2_BASELINE_BUILD'
      AND run_version=1
)
SELECT COUNT(*) AS row_level_mismatches
FROM msbf_m1.m1_2_expected_entity_snapshot((SELECT run_id FROM r)) e
FULL JOIN msbf_m1.m1_2_actual_entity_snapshot((SELECT run_id FROM r)) a
  USING (entity_type,entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash;
```

Expected:

```text
0
```

---

## 13. Evidence package checklist

Retain the following for review:

```text
10 preflight CSV
11 generation checkpoint CSV and execution log
12 positive-validation CSV
13 negative-control CSV
14 acceptance-finalizer CSV
15 master-report CSV
16 ten detailed report exports
M1.2 SQL source files
M1.2 package SHA-256 manifest
completed acceptance milestone
```

Use the supplied template:

```text
evidence/templates/MSBF_M1_2_Deterministic_Merchant_Population_Build_Acceptance_Milestone_v0_2_template.txt
```

Do not mark the milestone PASS until the evidence has been independently reviewed.

---

## 14. Failure states and remediation

| Failure point | Required response |
|---|---|
| Preflight failure | Stop; reconcile G1 state, hashes, or unexpected rows |
| Generation exception before commit | Roll back; capture first error; do not manually insert partial rows |
| Canonical mismatch during generation | Treat as code defect; generation transaction should roll back |
| Positive check failure | Run remains or becomes `M1_2_FAILED`; inspect the exact evidence row |
| Negative control failure | Do not finalize; fail-closed behavior has not been demonstrated |
| Acceptance finalizer returns FAIL | Do not modify gate result manually; remediate underlying evidence |
| Master report not PASS | Treat M1.2 as unaccepted even if individual scripts appeared successful |

If the generation script committed successfully but later validation fails, do not delete and regenerate without a controlled remediation plan. Preserve the evidence and diagnose the stage result first.

---

## 15. Acceptance boundary and next stage

A PASS accepts only the deterministic synthetic merchant population stage. It does not accept:

- applications or requested financing structures;
- POS or deposit history;
- features or cash-flow capacity;
- default-risk proxies;
- EAD, LGD, or Expected Loss;
- pricing or customer offers;
- legal, regulatory, accounting, capital, fair-lending, privacy, or security conclusions.

After formal M1.2 acceptance, the next authorized stage is:

```text
M1.3 — Application and Requested Sales-Linked Structure Generation
```
