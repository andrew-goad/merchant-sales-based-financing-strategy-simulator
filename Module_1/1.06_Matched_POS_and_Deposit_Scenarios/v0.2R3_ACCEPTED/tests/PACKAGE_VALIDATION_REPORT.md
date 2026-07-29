# Package Validation Report — M1.6 Accepted v0.2R3

## Final stage milestone

```text
M1.6 Matched POS and Deposit Scenario Overlay Generation   PASS
M1.7 Source Quality & Data Confidence                      AUTHORIZED
```

## Live-evidence review

| Control | Result |
|---|---:|
| Approved scenarios | 2 |
| POS scenario rows | 270,000 |
| Deposit scenario rows | 270,000 |
| Merchants / dates | 750 / 180 |
| Expected / actual canonical entities | 540,000 / 540,000 |
| Row-level deterministic mismatches | 0 |
| Stored / expected / actual POS hash | Exact match |
| Stored / expected / actual deposit hash | Exact match |
| Stored / expected / actual combined hash | Exact match |
| Positive validations | 62 / 62 PASS |
| Negative controls | 5 / 5 PASS |
| Failed evidence | 0 |
| Blocking resolution errors | 0 |
| Downstream analytical rows | 0 |
| M1.6 gate | PASS |
| Master report | PASS |
| Detail-report result sets | 16 complete |

## Correction history

- v0.2 performance attempt cancelled and rolled back before commit.
- v0.2R1 performance attempt cancelled and rolled back before commit.
- v0.2R2 generated the accepted scenario histories.
- v0.2R3 corrected left-boundary settlement-lag validation; no scenario data changed.

## Settlement-lag diagnosis

```text
Original apparent violations       1,460
Boundary rows                       2,014
Nonzero accepted carry-in rows      1,460
Within-panel violations             0
Boundary-copy violations            0
Unexpected missing prior rows       0
```

## Evidence completeness

- Structured M1.6 live evidence files retained: **26**
- Execution logs retained: **0**
- Initial failed validation retained: **Yes**
- Fail-closed boundary diagnostic retained: **Yes**
- Zero-row mismatch export present: **Yes**
- Zero-row blocking-error export present: **Yes**
- Independent evidence review present: **Yes**
- Completed M1.6 milestone present: **Yes**
- Validation-summary JSON present: **Yes**
- Exact final accepted execution scripts present: **Yes**

## Evidence review assertions

Thirty-three independent package-level assertions were evaluated across recovery, preflight, generation, initial and final validation, negative controls, acceptance, master report, scenario totals, stress direction, industry ordering, pre-shock identity, deterministic hashes, stage boundaries, and empty error outputs.

```text
Assertions evaluated   33
Assertions passed      33
Assertions failed       0
```

## Interpretation boundary

This package accepts synthetic matched POS and deposit scenario histories. It does not imply acceptance of source-quality evidence, calibrated economic forecasts, production stress models, credit risk, pricing, servicing, accounting, capital, fair lending, legal or regulatory compliance, or production use.


## Final distribution validation

```text
Accepted-stage files               121
Maximum internal path length       177 characters
ZIP CRC validation                 PASS
Complete extraction                PASS
Source / ZIP inventory match       PASS
Extracted-file hash comparison     PASS
Windows/DOS ZIP metadata           PASS
ZIP64                              Not used
```
