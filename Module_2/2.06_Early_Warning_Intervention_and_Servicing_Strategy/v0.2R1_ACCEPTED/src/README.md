# Source Classification — M2.6

## Current normal chain

- `01` — [`01_172_schema_policy.sql`](current/01_172_schema_policy.sql)
- `02` — [`02_173_preflight.sql`](current/02_173_preflight.sql)
- `03` — [`03_174_generation.sql`](current/03_174_generation.sql)
- `04` — [`04_175_positive_validation.sql`](current/04_175_positive_validation.sql)
- `05` — [`05_176_negative_controls.sql`](current/05_176_negative_controls.sql)
- `06` — [`06_177_acceptance_finalize.sql`](current/06_177_acceptance_finalize.sql)

## Reporting

- `07` — [`07_178_master_report_v0_2R1.sql`](reporting/07_178_master_report_v0_2R1.sql)
- `08` — [`08_179_detail_report.sql`](reporting/08_179_detail_report.sql)

## Recovery boundary

- `172A` — [`172A_msbf_m2_6_failed_schema_policy_recovery_check_v0_2.sql`](recovery/172A_msbf_m2_6_failed_schema_policy_recovery_check_v0_2.sql)
- `174A` — [`174A_msbf_m2_6_failed_generation_recovery_check_v0_2.sql`](recovery/174A_msbf_m2_6_failed_generation_recovery_check_v0_2.sql)
- `174B` — [`174B_msbf_m2_6_generation_reconciliation_reconstructed_v0_2.sql`](recovery/174B_msbf_m2_6_generation_reconciliation_reconstructed_v0_2.sql)
- `178A` — [`178A_msbf_m2_6_failed_master_report_boundary_source_recovery_v0_2R1.sql`](recovery/178A_msbf_m2_6_failed_master_report_boundary_source_recovery_v0_2R1.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
