# Accepted M1.6 Execution Path — v0.2R3

## Accepted live path

The accepted live run used:

1. `37A_msbf_m1_6_aborted_generation_recovery_check_v0_2R2.sql`
2. `38_msbf_m1_6_preflight_validation_v0_2R2.sql`
3. `39_msbf_m1_6_matched_scenario_overlay_generation_v0_2R2.sql`
4. Initial R2 `40` validation — detected a left-boundary settlement-lag specification issue.
5. `37B_msbf_m1_6_failed_settlement_lag_validation_recovery_check_v0_2R3.sql` — confirmed zero true lag errors.
6. `40_msbf_m1_6_matched_scenario_overlay_validation_v0_2R3.sql`
7. `41_msbf_m1_6_negative_control_tests_v0_2R3.sql`
8. `42_msbf_m1_6_acceptance_finalize_v0_2R3.sql`
9. `43_MSBF_M1_6_Matched_Scenario_Overlay_Master_Report_v0_2R3.sql`
10. `44_MSBF_M1_6_Matched_Scenario_Overlay_Detail_Report_v0_2R3.sql`

`39A_msbf_m1_6_generation_reconciliation_reconstructed_v0_2R2.sql` is a read-only contingency script. It is needed only if the script-39 result tab is lost after a successful commit.

## Future clean replay

For a clean replay from an accepted M1.5 state, use the scripts under `accepted_execution/`:

1. `tests/37A...v0_2R2.sql` — optional but recommended recovery/readiness check.
2. `tests/38...v0_2R2.sql`
3. `sql/39...v0_2R2.sql`
4. `sql/40...v0_2R3.sql`
5. `sql/41...v0_2R3.sql`
6. `sql/42...v0_2R3.sql`
7. `tests/43...v0_2R3.sql`
8. `tests/44...v0_2R3.sql`

The R3 settlement-lag diagnostic under `accepted_execution/historical_diagnostics/` documents the actual remediation path but is not required when the final R3 validation is used immediately after R2 generation.

## Historical performance attempts

- Original v0.2: POS derived-CTE self-join caused prolonged buffer reads; cancelled and rolled back.
- v0.2R1: POS path improved, but deposit blueprint remained CPU-bound; cancelled and rolled back.
- v0.2R2: accepted generation revision.
- v0.2R3: accepted validation/reporting revision.

No cancelled attempt committed scenario rows.
