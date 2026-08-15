# Source Classification — M2.7

## Current normal chain

- `01` — [`01_180_schema_policy.sql`](current/01_180_schema_policy.sql)
- `02` — [`02_181_preflight.sql`](current/02_181_preflight.sql)
- `03` — [`03_182_generation_v0_2R1.sql`](current/03_182_generation_v0_2R1.sql)
- `04` — [`04_183_positive_validation.sql`](current/04_183_positive_validation.sql)
- `05` — [`05_184_negative_controls.sql`](current/05_184_negative_controls.sql)
- `06` — [`06_185_acceptance_finalize.sql`](current/06_185_acceptance_finalize.sql)

## Reporting

- `07` — [`07_186_master_report.sql`](reporting/07_186_master_report.sql)
- `08` — [`08_187_detail_report.sql`](reporting/08_187_detail_report.sql)

## Recovery boundary

- `02A` — [`02A_182A_failed_generation_recovery.sql`](recovery/02A_182A_failed_generation_recovery.sql)
- `180A` — [`180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql`](recovery/180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql)
- `182B` — [`182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql`](recovery/182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
