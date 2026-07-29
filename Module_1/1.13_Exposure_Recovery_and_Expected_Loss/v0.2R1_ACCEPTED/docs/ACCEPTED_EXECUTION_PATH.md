# M1.13 Accepted Execution Path

## Actual live execution history

| Order | Program | Result |
|---:|---|---|
| 1 | `92_msbf_m1_13_schema_policy_extension_v0_2.sql` | PASS |
| 2 | `93_msbf_m1_13_preflight_validation_v0_2.sql` | PASS |
| 3 | `94_msbf_m1_13_exposure_recovery_loss_generation_v0_2.sql` | Stopped before commit: unsupported `max(boolean)` |
| 4 | `92B_msbf_m1_13_failed_boolean_aggregate_recovery_check_v0_2R1.sql` | PASS |
| 5 | `93_msbf_m1_13_preflight_validation_v0_2R1.sql` | PASS |
| 6 | `94_msbf_m1_13_exposure_recovery_loss_generation_v0_2R1.sql` | PASS |
| 7 | `95_msbf_m1_13_exposure_recovery_loss_validation_v0_2R1.sql` | 82 / 82 PASS |
| 8 | `96_msbf_m1_13_negative_control_tests_v0_2R1.sql` | 7 / 7 PASS |
| 9 | `97_msbf_m1_13_acceptance_finalize_v0_2R1.sql` | PASS |
| 10 | `98_MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2R1.sql` | PASS |
| 11 | `99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1.sql` | 20 result sets; PASS |

## Final clean-build execution order

1. `sql/92_msbf_m1_13_schema_policy_extension_v0_2.sql`
2. `tests/93_msbf_m1_13_preflight_validation_v0_2R1.sql`
3. `sql/94_msbf_m1_13_exposure_recovery_loss_generation_v0_2R1.sql`
4. `sql/95_msbf_m1_13_exposure_recovery_loss_validation_v0_2R1.sql`
5. `sql/96_msbf_m1_13_negative_control_tests_v0_2R1.sql`
6. `sql/97_msbf_m1_13_acceptance_finalize_v0_2R1.sql`
7. `tests/98_MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2R1.sql`
8. `tests/99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1.sql`

Program 92B is recovery-only and is not part of a clean build. Program 94A is contingency-only
when generation commits but the result tab is lost.
