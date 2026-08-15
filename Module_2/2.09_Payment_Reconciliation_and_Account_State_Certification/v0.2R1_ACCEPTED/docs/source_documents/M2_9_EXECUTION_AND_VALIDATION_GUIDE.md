# M2.9 Execution and Validation Guide

Run against `msbf_strategy` using DBeaver **Execute SQL Script**:

```text
196 → 197 → 198 → 199 v0.2R1 → 200 → 201 → 202 → 203
```

Required checkpoints:

```text
196  schema_policy_status = PASS
197  preflight_status = PASS
198  generation_status = PASS; canonical 438; mismatches 0
199  120 / 120 PASS
200  20 / 20 PASS
201  M2_9_ACCEPTED / ACCEPTED / PASS
202  overall_m2_9_status = PASS
203  24 result sets; Result Sets 23 and 24 empty
```

Do not rerun Program 198 after successful commit.

## Recovery from the v0.2 Program 199 failure

```text
Stop → ROLLBACK → 199A v0.2R1 → 199 v0.2R1 → 200
```

Do not rerun Programs 196–198.
