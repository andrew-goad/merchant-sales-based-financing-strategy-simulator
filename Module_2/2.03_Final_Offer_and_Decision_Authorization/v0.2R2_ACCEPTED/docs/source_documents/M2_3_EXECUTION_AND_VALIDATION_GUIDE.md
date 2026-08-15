# M2.3 Execution and Validation Guide

Run in order against `msbf_strategy` using DBeaver Execute SQL Script:

```text
148 -> 149 -> 150 -> 151 -> 152 -> 153 -> 154 -> 155
```

Do not rerun Program 150 after it commits. If Program 150 fails before commit, execute `ROLLBACK;`, run Program 148A, and then rerun the corrected generation path.

Required checkpoints:

- Program 149: `preflight_status = PASS`
- Program 150: 6,029 canonical entities and zero mismatches
- Program 151: 120 / 120 positive PASS
- Program 152: 20 / 20 negative PASS
- Program 153: `M2_3_ACCEPTED` and acceptance gate PASS
- Program 154: `overall_m2_3_status = PASS`
- Program 155: 24 result sets; Result Sets 23 and 24 have headers and zero rows
