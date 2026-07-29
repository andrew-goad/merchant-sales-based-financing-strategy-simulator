# M1.8 v0.2R1 Accepted Execution Guide

## Clean build from accepted M1.7

Run only the canonical files in this sequence:

```text
52 schema/policy extension v0.2R1
53 preflight v0.2R1
54 generation v0.2R1
55 positive validation v0.2R1
56 negative controls v0.2R1
57 acceptance finalizer v0.2R1
58 master report v0.2R1
59 detail report v0.2R1
```

Required outcomes:

```text
4,500 verification rows
750 application summaries
5,250 canonical entities
0 row-level mismatches
60 / 60 positive validations PASS
6 / 6 negative controls PASS
0 stress-tier improvements
M1_8_ACCEPTED
overall_m1_8_status = PASS
```

## Contingency scripts

- `52A`: use only after a failed/cancelled generation followed by `ROLLBACK;`.
- `54A`: use only to reconstruct a lost generation result tab after a successful commit.
- `52B` and `54B`: retain as historical recovery/remediation evidence for the original live v0.2 execution; do not use in a new clean v0.2R1 build.

## DBeaver controls

- Confirm `current_database() = 'msbf_strategy'`.
- Use **Execute SQL Script**.
- Stop on the first exception.
- Do not select Retry, Skip, or Skip All.
- Run `ROLLBACK;` after failed transactional execution.
- Do not rerun generation after a successful commit.
