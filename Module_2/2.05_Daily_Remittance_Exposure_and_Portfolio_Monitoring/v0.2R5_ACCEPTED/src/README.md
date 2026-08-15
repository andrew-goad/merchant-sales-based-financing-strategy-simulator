# Source Classification — M2.5

## Current normal chain

- `01` — [`01_164_schema_policy.sql`](current/01_164_schema_policy.sql)
- `02` — [`02_165_preflight.sql`](current/02_165_preflight.sql)
- `03` — [`03_166_generation.sql`](current/03_166_generation.sql)
- `05` — [`05_167_positive_validation.sql`](current/05_167_positive_validation.sql)
- `07` — [`07_168_negative_controls.sql`](current/07_168_negative_controls.sql)
- `09` — [`09_169_acceptance_finalize.sql`](current/09_169_acceptance_finalize.sql)
- `167` — [`167_msbf_m2_5_daily_remittance_exposure_validation_v0_2R5.sql`](current/167_msbf_m2_5_daily_remittance_exposure_validation_v0_2R5.sql)

## Reporting

- `10` — [`10_170_master_report.sql`](reporting/10_170_master_report.sql)
- `11` — [`11_171_detail_report.sql`](reporting/11_171_detail_report.sql)

## Recovery boundary

- `04` — [`04_164B_generation_recovery_proof.sql`](recovery/04_164B_generation_recovery_proof.sql)
- `06` — [`06_168A_negative_control_recovery_proof.sql`](recovery/06_168A_negative_control_recovery_proof.sql)
- `08` — [`08_169A_acceptance_recovery_proof.sql`](recovery/08_169A_acceptance_recovery_proof.sql)
- `164A` — [`164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql`](recovery/164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql)
- `166A` — [`166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql`](recovery/166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql)
- `166B` — [`166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql`](recovery/166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
