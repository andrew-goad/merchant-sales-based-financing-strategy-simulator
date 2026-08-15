# M2.7 Execution and Validation Guide

Run against `msbf_strategy` with DBeaver **Execute SQL Script**:

```text
180 → 181 → 182 v0.2R1 → 183 → 184 → 185 → 186 → 187
```

Required checkpoints:

```text
180  schema_policy_status = PASS
181  preflight_status = PASS
182  generation_status = PASS; canonical 341; mismatch 0
183  120 / 120 PASS
184  20 / 20 PASS
185  M2_7_ACCEPTED / ACCEPTED / PASS
186  overall_m2_7_status = PASS
187  24 result sets; Result Sets 23 and 24 empty
```

Do not rerun Program 182 after successful commit.

## Program 182 v0.2R1

After the failed v0.2 attempt, execute `ROLLBACK;`, run Program 182A, and require `recovery_status = PASS` before running Program 182 v0.2R1.
