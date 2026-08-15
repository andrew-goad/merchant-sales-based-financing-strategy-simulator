# M2.2 Execution and Validation Guide

Execute with DBeaver **Execute SQL Script** against `msbf_strategy`:

```text
140 → 141 → 142 → 143 → 144 → 145 → 146 → 147
```

Required checkpoints:

- 140: schema/policy extension `PASS`
- 141: `preflight_status = PASS`
- 142: 750 requests, 557 candidates, 1,500 pricing rows, 7,336 canonical entities, zero mismatches
- 143: 120 / 120 positive controls `PASS`
- 144: 20 / 20 negative controls `PASS`
- 145: `M2_2_ACCEPTED`, contract `ACCEPTED`, gate `PASS`
- 146: `overall_m2_2_status = PASS`
- 147: 24 result sets; Results 23 and 24 have headers and zero rows
