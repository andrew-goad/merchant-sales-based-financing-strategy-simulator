# M1.13 Accepted Execution Guide — v0.2R1

## Prerequisite

```text
run_status = M1_12_ACCEPTED
```

## Clean-build order

| Order | Program | Required result |
|---:|---|---|
| 1 | `sql/92_msbf_m1_13_schema_policy_extension_v0_2.sql` | PASS |
| 2 | `tests/93_msbf_m1_13_preflight_validation_v0_2R1.sql` | PASS |
| 3 | `sql/94_msbf_m1_13_exposure_recovery_loss_generation_v0_2R1.sql` | 93,720 paths; 1,500 snapshots; zero mismatches |
| 4 | `sql/95_msbf_m1_13_exposure_recovery_loss_validation_v0_2R1.sql` | 82 / 82 PASS |
| 5 | `sql/96_msbf_m1_13_negative_control_tests_v0_2R1.sql` | 7 / 7 PASS |
| 6 | `sql/97_msbf_m1_13_acceptance_finalize_v0_2R1.sql` | Gate PASS; `M1_13_ACCEPTED` |
| 7 | `tests/98_MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2R1.sql` | Overall PASS |
| 8 | `tests/99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1.sql` | 20 result sets |

## Recovery and contingency

- `tests/92B_...v0_2R1.sql` documents recovery from the original pre-commit Boolean-aggregate failure.
- `tests/94A_...v0_2R1.sql` is read-only and is used only if generation commits but the DBeaver result tab is lost.
- Do not rerun generation after a successful commit.

## Evidence

See `evidence/M1_13_EVIDENCE_INDEX.md`.
