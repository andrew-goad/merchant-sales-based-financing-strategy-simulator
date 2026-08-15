# Source Classification — M2.9

## Current normal chain

- `01` — [`01_196_schema_policy.sql`](current/01_196_schema_policy.sql)
- `02` — [`02_197_preflight.sql`](current/02_197_preflight.sql)
- `03` — [`03_198_generation.sql`](current/03_198_generation.sql)
- `04` — [`04_199_positive_validation_v0_2R1.sql`](current/04_199_positive_validation_v0_2R1.sql)
- `05` — [`05_200_negative_controls.sql`](current/05_200_negative_controls.sql)
- `06` — [`06_201_acceptance_finalize.sql`](current/06_201_acceptance_finalize.sql)

## Reporting

- `07` — [`07_202_master_report_executed_v0_2.sql`](reporting/07_202_master_report_executed_v0_2.sql)
- `08` — [`08_203_detail_report.sql`](reporting/08_203_detail_report.sql)

## Recovery boundary

- `03A` — [`03A_199A_failed_positive_validation_recovery.sql`](recovery/03A_199A_failed_positive_validation_recovery.sql)
- `07R` — [`07R1_202_master_report_header_normalized.sql`](recovery/07R1_202_master_report_header_normalized.sql)
- `196A` — [`196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql`](recovery/196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql)
- `198A` — [`198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql`](recovery/198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql)
- `198B` — [`198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql`](recovery/198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
