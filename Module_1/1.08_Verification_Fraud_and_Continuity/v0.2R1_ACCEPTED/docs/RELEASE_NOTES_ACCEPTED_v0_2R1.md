# Release Notes — M1.8 v0.2R1 Accepted

## Acceptance milestone

M1.8 — Verification, Fraud & Processor Continuity was accepted on 2026-07-25.

## Accepted results

```text
Applications                         750
Verification-result rows           4,500
Application-summary rows             750
Canonical entities                 5,250
Positive validations          60 / 60 PASS
Negative controls              6 / 6 PASS
Deterministic mismatches              0
Blocking errors                       0
Verification hash  4cea9d266720d1fbd45bc0f994b4ba23
Summary hash       23cf75e01c639150d2b4a28800701303
Combined hash      604a5640a25da92a850840dbe13e3d56
```

## v0.2R1 correction

The original v0.2 positive validation detected 18 applications with a lower independently classified stressed processor-continuity tier than baseline. The accepted method:

```text
Final Stress Tier = greatest(Baseline Tier, Independently Classified Stress Tier)
```

preserves observed rates and changes only application-level stressed-tier interpretation. The 4,500 atomic verification rows were unchanged.

The revised validation script also produces one 60-row result set rather than 60 one-row helper result sets plus a final result set.

## Package changes

- Added accepted clean-build v0.2R1 SQL and reports.
- Preserved the original v0.2 execution path and failed validation evidence.
- Added fail-closed recovery and controlled remediation artifacts.
- Added all structured live evidence and seventeen detail exports.
- Added independent evidence review, machine-readable summary, evidence index, and completed milestone.
- Updated project status and authorized M1.9.
- Regenerated manifests, hashes, validation reports, and Windows-compatible release archives.
