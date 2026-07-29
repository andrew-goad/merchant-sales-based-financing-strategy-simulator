# M1.13 Execution and Validation Guide

## Prerequisite

The baseline run must be in:

```text
M1_12_ACCEPTED
```

Connect DBeaver to `msbf_strategy`, use **Execute SQL Script**, and stop at the
first PostgreSQL exception. Never use Retry, Skip, or Skip All after an error.
After a failed transactional program, execute `ROLLBACK;`.

## Normal sequence

```text
92 schema/policy extension
93 preflight
94 generation
95 positive validation
96 negative controls
97 acceptance finalizer
98 master report
99 detail report
```

### 92 — Schema and policy extension

Required final field:

```text
schema_policy_extension_status = PASS
```

### 93 — Preflight

Required:

```text
preflight_status = PASS
```

### 94 — Generation

Required checkpoint:

```text
run_status               M1_13_GENERATED
snapshot_rows            1,500
applications               750
scenarios                    2
row_level_mismatches          0
generation_status           PASS
```

The path-row count is dynamic and must equal:

```text
2 × Σ(requested_expected_payoff_days + 1)
```

After program 94 commits successfully, do not rerun it.

### 95 — Positive validation

Required:

```text
82 checks
82 PASS
0 FAIL
run_status = M1_13_VALIDATED
```

The session-scoped `_m1_13_validation` table survives COMMIT, so the DBeaver
result grid remains filterable in the same connection.

### 96 — Negative controls

Required:

```text
7 / 7 PASS
```

### 97 — Acceptance

Required:

```text
gate_status      PASS
final_run_status M1_13_ACCEPTED
```

### 98 and 99 — Reports

The master report must return `overall_m1_13_status = PASS`.
The detail report returns 20 result sets. Result sets 19 and 20 must retain
headers and contain zero rows.

## Contingency scripts

- `92A`: run only after failed/cancelled generation and rollback.
- `94A`: run only when generation committed but the DBeaver result tab was lost.
