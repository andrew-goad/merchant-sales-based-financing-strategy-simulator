# M1.11 Validation and Correction History

## Purpose

This record preserves the full defect-detection, fail-closed diagnosis, controlled remediation, and final acceptance path for M1.11.

## Timeline

### Initial v0.2 execution

- Schema and policy extension: PASS
- Preflight: PASS
- Generation: PASS
- Generated snapshots: 1,500
- Generated components: 7,500
- Canonical entities: 9,000
- Generation mismatches: 0

### Initial v0.2 positive validation

- Positive controls: 70 / 72 PASS
- Failed controls:
  - `M1_11_POS_05_SOURCE_HASH`
  - `M1_11_POS_39_COMPOSITE_IDENTITY`

### v0.2R1 recovery attempt

The R1 precondition assumed all 313 composite findings were non-BLOCKED rounding differences. The fail-closed diagnostic observed only 237 persisted-component identity differences and rejected remediation before any write.

### v0.2R2 diagnosis

The R2 diagnostic proved the exact decomposition:

```text
Legacy ungated findings                  313
Non-BLOCKED rounding differences         237
BLOCKED rows with complete components     76
BLOCKED rows with non-null composite       0
Evidence-gated original-formula errors     0
Maximum non-BLOCKED difference      0.000001
```

### v0.2R2 remediation

- Non-BLOCKED composite scores corrected: 237
- BLOCKED composite values preserved as null: 76
- Component rows changed: 0
- Tier changes: 0
- Routing changes: 0
- Remaining evidence-gated identity violations: 0
- Methodology advanced to `M1_11_METHOD_V1_1`
- Composite basis set to `SUM_PERSISTED_WEIGHTED_COMPONENTS`

### Final v0.2R2 acceptance

- Positive controls: 72 / 72 PASS
- Negative controls: 6 / 6 PASS
- Acceptance gate: PASS
- Run status: `M1_11_ACCEPTED`
- Master report: PASS
- Deterministic mismatches: 0
- Blocking errors: 0

## Audit principle

The package retains the original failed validation, the unsuccessful R1 precondition, the R2 diagnosis, the controlled remediation, and the final passing evidence. No failed evidence was hidden or overwritten without a durable audit record.
