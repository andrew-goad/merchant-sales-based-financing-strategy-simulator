# M2.10 Downstream Audit and Correction — v0.2R2

## Accepted execution checkpoint

The submitted Program 205A and corrected Program 205 v0.2R1 evidence passed:

```text
205A diagnostic_status                PASS
205 preflight_status                  PASS
Accepted M2.9 source rows             59
Closed / active / review          57 / 1 / 1
Active accepted outcome              PAYMENT_ACTIVITY_RECONCILED_AFTER_RETRY
Active accepted certification        CERTIFIED_REASSESSMENT_DUE_AFTER_RETRY
Active certified exposure            $323.79
All M2.10 generated targets          0
```

Programs 204 and 205 are authoritative and must not be rerun.

## Downstream findings and corrections

### Program 206

- Removed the stale `CERTIFIED_REASSESSMENT_DUE` literal.
- Added a fail-closed, materialized source-classification layer using the exact
  accepted M2.9 outcome, certification, state flags, exception posture,
  amounts, and zero-variance predicates.
- Invalid or unrecognized source combinations now produce
  `SOURCE_MAPPING_ERROR` and stop generation rather than defaulting to
  controlled review.
- Replaced the persistent `run_evidence SELECT *` with an explicit projection.

### Programs 206A, 206B, and 207A

Recovery and reconstruction now independently verify the exact accepted M2.9
57 / 1 / 1 posture and/or zero source-to-performance mapping errors.

### Program 207

The positive-control inventory remains 120. Controls 034, 046, 059, and 060
now validate the exact accepted M2.9 source semantics and the physical
source-to-performance mapping.

### Program 208

The 20 negative controls are unchanged in business purpose. A fail-closed
readiness guard now requires zero source-to-performance mapping errors before
negative testing begins.

### Program 209

Formal acceptance now independently reconstructs and requires zero exact
source-to-performance mapping errors.

### Program 210

The master report now includes and requires the accepted M2.9 physical
contract/gate identity, zero mapping errors, zero prohibited columns, and zero
blocking profile errors.

### Program 211

Result Sets 08 and 11–13 now expose the accepted M2.9 outcome/state semantics.
Result Set 24 additionally reports source-mapping violations,
latest/archive mismatches, prohibited columns, and blocking profile errors.
It must remain empty.

## Execution resume

```text
206 v0.2R1 → 207 v0.2R1 → 208 v0.2R1 →
209 v0.2R1 → 210 v0.2R1 → 211 v0.2R1
```

If Program 206 fails:

```text
Stop → ROLLBACK → 206A v0.2R1
```

Do not rerun Programs 204 or 205.
