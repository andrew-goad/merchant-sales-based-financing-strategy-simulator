
# M1.14 Validation and Correction History

## v0.2 — Initial source

- Schema and policy extension: PASS.
- Preflight: PASS.
- Generation stopped before commit because `stress_economic_worsening_flag`
  could evaluate to `NULL` for matched blocked evidence.

## v0.2R1 — Null-safe stress flag

- Recovery check: PASS; zero M1.14 business/evidence/gate rows.
- Preflight: PASS.
- Null-safe Boolean generation source introduced.
- Generation then exposed a separate legacy blocked-evidence constraint.

## v0.2R2 — Blocked-contract diagnosis

- Recovery check confirmed the legacy constraint and 278 stress-blocked rows
  retaining valid non-blocked baseline economics.
- Preflight correctly returned FAIL because baseline comparison references were
  still prohibited.
- Generation readiness guard rejected the unapproved contract.

## v0.2R3 — Atomic contract repair and committed generation

- Atomic repair converted the recognized legacy contract to APPROVED_V2.
- Hard-stop preflight: PASS.
- Generation: 1,500 snapshots, 21,000 components, 22,500 canonical entities,
  zero generation mismatches.
- Positive validation: 81 of 82 PASS.
- Negative controls: 7 of 7 PASS.
- Acceptance review version 1: FAIL, appropriately blocked by POS26.

## v0.2R4 — Physical snapshot row-hash validation

- Recovery proved physical snapshot mismatches = 0 and enriched-row mismatches =
  1,500.
- POS26 was corrected to reconstruct hashes from physical snapshot fields only.
- Final positive validation: 82 of 82 PASS.
- Final negative controls: 7 of 7 PASS.
- Acceptance review version 2: PASS.
- Master report: PASS.
- All 20 detail reports completed; mismatch and blocking-error outputs are empty.

## Final accepted state

```text
Run status      M1_14_ACCEPTED
Package         v0.2R4
Generation      v0.2R3
Methodology     M1_14_METHOD_V1
Combined hash   3a47f59b56fa158c18c111caa1c64909
```
