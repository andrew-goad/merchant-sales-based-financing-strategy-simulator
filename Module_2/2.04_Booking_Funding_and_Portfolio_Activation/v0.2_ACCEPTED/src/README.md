# Source Classification — M2.4

## Current normal chain

- `01` — [`01_156_schema_policy.sql`](current/01_156_schema_policy.sql)
- `02` — [`02_157_preflight.sql`](current/02_157_preflight.sql)
- `03` — [`03_158_generation.sql`](current/03_158_generation.sql)
- `04` — [`04_159_positive_validation.sql`](current/04_159_positive_validation.sql)
- `05` — [`05_160_negative_controls.sql`](current/05_160_negative_controls.sql)
- `06` — [`06_161_acceptance_finalize.sql`](current/06_161_acceptance_finalize.sql)

## Reporting

- `07` — [`07_162_master_report.sql`](reporting/07_162_master_report.sql)
- `08` — [`08_163_detail_report.sql`](reporting/08_163_detail_report.sql)

## Recovery boundary

- `156A` — [`156A_msbf_m2_4_failed_schema_policy_recovery_check_v0_2.sql`](recovery/156A_msbf_m2_4_failed_schema_policy_recovery_check_v0_2.sql)
- `158A` — [`158A_msbf_m2_4_failed_generation_recovery_check_v0_2.sql`](recovery/158A_msbf_m2_4_failed_generation_recovery_check_v0_2.sql)
- `158B` — [`158B_msbf_m2_4_generation_reconciliation_reconstructed_v0_2.sql`](recovery/158B_msbf_m2_4_generation_reconciliation_reconstructed_v0_2.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
