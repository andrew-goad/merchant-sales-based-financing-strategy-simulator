# Release Notes — M1.6 Accepted v0.2R3

## Acceptance milestone

M1.6 — Matched POS and Deposit Scenario Overlay Generation was accepted on 2026-07-25.

## Final results

```text
Approved scenarios                 2
POS scenario rows            270,000
Deposit scenario rows        270,000
Canonical entities           540,000
Deterministic mismatches            0
Positive checks              62 / 62 PASS
Negative controls             5 / 5 PASS
Failed evidence                     0
Blocking errors                     0
Downstream rows                     0
POS scenario hash            54793b3be9f6832f9bda5b4a30bf6569
Deposit scenario hash        7c55c8ce6c74e965959e1c57921ca3b8
Combined scenario hash       3f85921bf6fc30ddc6cee146085e58c5
```

## Controlled corrections

- v0.2: original POS-blueprint self-join produced unacceptable runtime; cancelled before commit.
- v0.2R1: POS optimization exposed a deposit-blueprint runtime issue; cancelled before commit.
- v0.2R2: comprehensively optimized generation, canonical reconciliation, validation, acceptance, and reporting; accepted generation revision.
- v0.2R3: corrected the settlement-lag validation for left-boundary carry-in; no scenario data or hashes changed.

## Package changes

- Added the exact accepted execution path.
- Added complete structured live evidence.
- Preserved the initial 61/62 validation result and fail-closed settlement-boundary diagnosis.
- Added validation history, evidence index, independent sign-off, milestone, and machine-readable summary.
- Authorized M1.7.
- Excluded execution logs under the accepted evidence policy.
