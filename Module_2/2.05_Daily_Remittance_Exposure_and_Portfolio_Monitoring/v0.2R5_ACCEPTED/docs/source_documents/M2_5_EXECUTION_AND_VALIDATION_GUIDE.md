# M2.5 Execution and Validation Guide

Run against `msbf_strategy` using DBeaver **Execute SQL Script** in this exact order:

```text
164 → 165 v0.2R1 → 166 → 167 → 168 → 169 → 170 → 171
```

Required checkpoints:

- Program 164: `schema_policy_status = PASS`
- Program 165 v0.2R1: `preflight_status = PASS`
- Program 166: 59 source rows, 7,080 daily rows, 59 latest/archive rows, 240 portfolio daily rows, 15 comparisons, 7,536 canonical entities, zero mismatches and `generation_status = PASS`
- Program 167: 120 / 120 positive controls PASS and `M2_5_VALIDATED`
- Program 168: 20 / 20 negative controls PASS
- Program 169: `M2_5_ACCEPTED`, contract `ACCEPTED`, gate `PASS`
- Program 170: `overall_m2_5_status = PASS`
- Program 171: 24 result sets; Result Sets 23 and 24 have headers and zero rows

Do not rerun Program 166 after it commits. Preserve generated rows and correct only the proven downstream defect if a later validation/report program fails.


## v0.2R1 preflight correction

Program 165 v0.2R1 gives distinct names to the policy-declared source
identities and the physically observed source-registry identities inside the
`_m2_5_preflight` CTAS projection. This resolves SQLSTATE 42701 without
changing any preflight rule or expected result.
