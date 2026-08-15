# M2.4 Execution and Validation Guide

Run against PostgreSQL database `msbf_strategy` using DBeaver **Execute SQL Script**.

```text
156 -> 157 -> 158 -> 159 -> 160 -> 161 -> 162 -> 163
```

## Required checkpoints

### Program 156

```text
policy_status                 APPROVED
acceptance_gate_catalog_rows  1
outcome_definition_rows       5
reason_definition_rows        24
notice_control_rows           4
schema_policy_status          PASS
```

### Program 157

```text
source run status             M2_3_ACCEPTED
source contract status        ACCEPTED
source rows                   1,500
final offer rows              59
review rows                   190
insufficient rows             178
policy decline rows           1,073
all M2.4 targets              0
preflight_status              PASS
```

### Program 158

```text
run_status                    M2_4_GENERATED
source rows                   1,500
activation rows               1,500
latest rows                   1,500
archive rows                  1,500
account rows                  59
advance rows                  59
portfolio rows                59
comparison rows               750
canonical entities            6,212
row-level mismatches          0
stress improvements           0
generation_status             PASS
```

After Program 158 commits, do not rerun it.

### Programs 159–163

```text
159: 120 / 120 positive PASS; M2_4_VALIDATED
160: 20 / 20 negative PASS
161: M2_4_ACCEPTED; contract ACCEPTED; gate PASS
162: overall_m2_4_status = PASS
163: 24 result sets; Result Sets 23 and 24 have headers and zero rows
```

## DBeaver rules

- Stop at the first PostgreSQL exception.
- Never use Retry, Skip or Skip All.
- Execute `ROLLBACK;` after a failed transactional program.
- Program 156A is for a failed Program 156 transaction.
- Program 158A is for a failed/cancelled Program 158 transaction.
- Program 158B reconstructs a committed Program 158 result if its result tab is lost.
