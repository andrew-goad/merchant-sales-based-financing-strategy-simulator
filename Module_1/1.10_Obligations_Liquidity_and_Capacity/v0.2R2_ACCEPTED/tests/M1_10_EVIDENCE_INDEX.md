# M1.10 Evidence Index

## Acceptance records

- `M1_10_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF.md`
- `M1_10_LIVE_EXECUTION_VALIDATION_SUMMARY_v0_2R2.json`
- `MSBF_M1_10_Obligations_Liquidity_Capacity_Build_Acceptance_Milestone_v0_2R2.txt`

## Accepted live evidence

Directory: `live_20260726/`

- 68 schema and policy extension
- 68B pre-generation recovery
- 69 corrected preflight
- 70 generation checkpoint
- 68C validation-syntax recovery and hash reconciliation
- 71 positive validations
- 72 negative controls
- 73 acceptance finalizer
- 74 master report
- 18 detailed-report result sets

The row-mismatch and blocking-error exports preserve headers and contain zero rows.

## Validation history

Directory: `history/`

- initial v0.2 preflight failure;
- DBeaver unbounded temporary-update warning;
- v0.2R1 program-71 validation syntax error.

## Accepted evidence summary

```text
Obligation rows            906
Capacity rows            1,500
Canonical entities       2,406
Positive controls        70 / 70 PASS
Negative controls         6 / 6 PASS
Row mismatches                    0
Stress improvements               0
Blocking errors                   0
Final run status       M1_10_ACCEPTED
Master report                    PASS
```
