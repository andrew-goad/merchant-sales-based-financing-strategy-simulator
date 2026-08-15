# M2.7 Program 182 v0.2R1 — Latest-Staging Hash Recovery

## Failure

Program 182 v0.2 stopped with PostgreSQL SQLSTATE `23502`:

```text
null value in column "contract_row_hash"
of relation "_m2_7_latest_expected"
violates not-null constraint
```

## Root cause

The temporary latest staging table was created with:

```sql
CREATE TEMP TABLE _m2_7_latest_expected
(
    LIKE msbf_m2.application_operational_activation_latest
    EXCLUDING DEFAULTS
    EXCLUDING CONSTRAINTS
);
```

PostgreSQL `LIKE` copies column `NOT NULL` attributes independently of
`EXCLUDING CONSTRAINTS`. The staging table therefore inherited
`contract_row_hash NOT NULL`.

Program 182 intentionally inserted a NULL placeholder and populated the
target-typed physical hash in the next statement. The inherited staging-only
NOT NULL attribute rejected the row before that update could execute.

## Correction

Program 182 v0.2R1:

1. temporarily drops NOT NULL from the staging hash column;
2. inserts target-typed rows;
3. populates each physical contract hash;
4. rejects NULL or malformed hashes;
5. restores NOT NULL;
6. continues to persistent latest and immutable archive generation.

No source mapping, row count, exposure, setup term, lifecycle identity,
dictionary, or accepted M2.6 boundary changed.

## Live recovery

Programs 180 and 181 passed and remain authoritative.

1. Click **Stop** in DBeaver.
2. Execute:

```sql
ROLLBACK;
```

3. Run `182A_msbf_m2_7_failed_generation_recovery_check_v0_2.sql`.
4. Require `recovery_status = PASS`.
5. Run `182_msbf_m2_7_operational_activation_generation_v0_2R1.sql`.
6. Continue with Programs 183–187 only after Program 182 v0.2R1 returns
   `generation_status = PASS`.
