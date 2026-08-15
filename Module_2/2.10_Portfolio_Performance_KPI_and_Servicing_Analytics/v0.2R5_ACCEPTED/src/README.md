# Source Classification — M2.10

## Current normal chain

- `01` — [`01_204_schema_policy_executed_v0_2.sql`](current/01_204_schema_policy_executed_v0_2.sql)
- `02` — [`02_205_preflight_v0_2R1.sql`](current/02_205_preflight_v0_2R1.sql)
- `03` — [`03_206_generation_v0_2R1.sql`](current/03_206_generation_v0_2R1.sql)
- `04` — [`04_207_positive_validation_v0_2R3.sql`](current/04_207_positive_validation_v0_2R3.sql)
- `05` — [`05_208_negative_controls_v0_2R2.sql`](current/05_208_negative_controls_v0_2R2.sql)
- `06` — [`06_209_acceptance_finalize_v0_2R1.sql`](current/06_209_acceptance_finalize_v0_2R1.sql)
- `204` — [`204_msbf_m2_10_schema_policy_portfolio_analytics_extension_v0_2R2.sql`](current/204_msbf_m2_10_schema_policy_portfolio_analytics_extension_v0_2R2.sql)

## Reporting

- `07` — [`07_210_master_report_v0_2R1.sql`](reporting/07_210_master_report_v0_2R1.sql)
- `08` — [`08_211_detail_report_v0_2R1.sql`](reporting/08_211_detail_report_v0_2R1.sql)

## Recovery boundary

- `02A` — [`02A_205A_active_reconciled_diagnostic.sql`](recovery/02A_205A_active_reconciled_diagnostic.sql)
- `04A` — [`04A_207A_positive_validation_recovery.sql`](recovery/04A_207A_positive_validation_recovery.sql)
- `04B` — [`04B_207B_definition_hash_diagnostic.sql`](recovery/04B_207B_definition_hash_diagnostic.sql)
- `04C` — [`04C_207C_definition_hash_repair.sql`](recovery/04C_207C_definition_hash_repair.sql)
- `05A` — [`05A_208A_negative_control_diagnostic.sql`](recovery/05A_208A_negative_control_diagnostic.sql)
- `05B` — [`05B_208B_kpi_applicability_repair.sql`](recovery/05B_208B_kpi_applicability_repair.sql)
- `204A` — [`204A_msbf_m2_10_failed_schema_policy_recovery_check_v0_2.sql`](recovery/204A_msbf_m2_10_failed_schema_policy_recovery_check_v0_2.sql)
- `206A` — [`206A_msbf_m2_10_failed_generation_recovery_check_v0_2R1.sql`](recovery/206A_msbf_m2_10_failed_generation_recovery_check_v0_2R1.sql)
- `206B` — [`206B_msbf_m2_10_generation_reconciliation_reconstructed_v0_2R1.sql`](recovery/206B_msbf_m2_10_generation_reconciliation_reconstructed_v0_2R1.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
