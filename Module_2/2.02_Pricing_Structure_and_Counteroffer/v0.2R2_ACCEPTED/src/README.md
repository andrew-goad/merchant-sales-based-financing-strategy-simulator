# Source Classification — M2.2

## Current normal chain

- `01` — [`01_140_schema_policy_v0_2.sql`](current/01_140_schema_policy_v0_2.sql)
- `02` — [`02_141_preflight_v0_2.sql`](current/02_141_preflight_v0_2.sql)
- `05` — [`05_142_generation_R2.sql`](current/05_142_generation_R2.sql)
- `06` — [`06_143_positive_validation_R2.sql`](current/06_143_positive_validation_R2.sql)
- `07` — [`07_144_negative_controls_R2.sql`](current/07_144_negative_controls_R2.sql)
- `08` — [`08_145_acceptance_finalize_R2.sql`](current/08_145_acceptance_finalize_R2.sql)
- `140` — [`140_msbf_m2_2_schema_policy_structure_contract_extension_v0_2R2.sql`](current/140_msbf_m2_2_schema_policy_structure_contract_extension_v0_2R2.sql)

## Reporting

- `09` — [`09_146_master_report_R2.sql`](reporting/09_146_master_report_R2.sql)
- `10` — [`10_147_detail_report_R2.sql`](reporting/10_147_detail_report_R2.sql)

## Recovery boundary

- `03` — [`03_140B_numeric_typmod_recovery_R1.sql`](recovery/03_140B_numeric_typmod_recovery_R1.sql)
- `04` — [`04_140C_selected_stress_recovery_R2.sql`](recovery/04_140C_selected_stress_recovery_R2.sql)
- `140A` — [`140A_msbf_m2_2_failed_generation_recovery_check_v0_2R2.sql`](recovery/140A_msbf_m2_2_failed_generation_recovery_check_v0_2R2.sql)
- `142A` — [`142A_msbf_m2_2_generation_reconciliation_reconstructed_v0_2R2.sql`](recovery/142A_msbf_m2_2_generation_reconciliation_reconstructed_v0_2R2.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
