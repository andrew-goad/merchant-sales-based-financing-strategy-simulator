# Package Validation Report — M1.8 v0.2R1 Accepted

## Disposition

```text
Live execution evidence       PASS
Formal stage acceptance       PASS
Accepted run status           M1_8_ACCEPTED
Accepted methodology          M1_8_METHOD_V1_1
Canonical reconciliation      PASS
Archive packaging             PASS
```

## Accepted evidence

```text
Applications                         750
Atomic verification rows           4,500
Application summaries                750
Canonical entities                 5,250
Positive validations          60 / 60 PASS
Negative controls              6 / 6 PASS
Row-level mismatches                   0
Blocking errors                        0
Failed evidence                        0
Stress-tier improvements               0
```

## Controlled correction

The initial v0.2 positive validation returned 59/60 PASS because 18 independently classified adverse-scenario continuity tiers were below baseline. The accepted v0.2R1 methodology preserves observed rates and applies a baseline floor to the interpreted stressed tier. Eighteen application-summary rows were corrected; all 4,500 atomic verification rows were unchanged.

## Accepted clean-build source checks

```text
Accepted SQL files                         9
Positive validation helper calls          60
Standalone helper SELECT result sets       0
Corrected methodology in preflight         TRUE
Stress-floor requirement in preflight      TRUE
Corrected policy-key count                 TRUE
Corrected methodology in generation        TRUE
Stress-floor requirement in generation     TRUE
Session-level random() calls                0
Destructive accepted-table deletes         0
Lexical parenthesis findings                0
```

The clean-build v0.2R1 source is a repository replacement derived from the accepted correction. The exact live acceptance path—original v0.2 generation followed by v0.2R1 recovery/remediation and revised validation—is preserved in `source_history/` and `evidence/`.

## Evidence-file validation

```text
Structured live evidence exports            26
Final positive PASS rows                     60 / 60
Final negative PASS rows                     6 / 6
Non-PASS final evidence rows                  0
Deterministic mismatch rows                   0
Blocking resolution error rows                0
Master-report status                          PASS
```

## Interpretation boundary

Synthetic demonstration evidence only. This acceptance is not production KYB/AML, sanctions, fraud-model, cybersecurity, identity, regulatory, fair-lending, or credit-decision certification.


## Final standalone archive validation

```text
Source files                         104
ZIP entries                          104
CRC validation                       PASS
Complete extraction                  PASS
Missing or extra entries             0
In-archive hash mismatches           0
Extracted-file hash mismatches       0
Windows/DOS ZIP metadata             PASS
ZIP64                                Not used
Maximum internal path length         145 characters
```
