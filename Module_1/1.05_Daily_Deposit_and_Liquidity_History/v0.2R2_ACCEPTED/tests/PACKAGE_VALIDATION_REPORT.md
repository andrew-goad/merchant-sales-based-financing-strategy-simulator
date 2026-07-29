# Package Validation Report — M1.5 Accepted v0.2R2

## Live-evidence controls

| Control | Result |
|---|---:|
| Generated rows / merchants / dates | 135,000 / 750 / 180 |
| Expected / actual canonical rows | 135,000 / 135,000 |
| Row-level mismatches | 0 |
| Corrected set hash | Exact stored / expected / actual match |
| Positive validations | 56 / 56 PASS |
| Negative controls | 4 / 4 PASS |
| Acceptance gate | PASS |
| Master report | PASS |
| Detailed report sets | 14 complete |
| Blocking errors | 0 |
| Downstream rows | 0 |

## Evidence policy

Execution logs are excluded. Structured result exports, deterministic reconciliation, validation/control results, the finalizer, master and detailed reports, correction evidence, independent review, and completed milestone are retained.

## Correction controls

- The v0.2R1 logic correction is explicit, scoped, reconciled, and retained.
- The v0.2R2 reporting correction is read-only and did not change accepted data.
- Original failed validation evidence remains retained as part of the audit trail.
