# Source Classification — M2.8

## Current normal chain

- `01` — [`01_188_schema_policy.sql`](current/01_188_schema_policy.sql)
- `02` — [`02_189_preflight.sql`](current/02_189_preflight.sql)
- `03` — [`03_190_generation.sql`](current/03_190_generation.sql)
- `04` — [`04_191_positive_validation.sql`](current/04_191_positive_validation.sql)
- `05` — [`05_192_negative_controls.sql`](current/05_192_negative_controls.sql)
- `06` — [`06_193_acceptance_finalize.sql`](current/06_193_acceptance_finalize.sql)

## Reporting

- `07` — [`07_194_master_report.sql`](reporting/07_194_master_report.sql)
- `08` — [`08_195_detail_report.sql`](reporting/08_195_detail_report.sql)

## Recovery boundary

- `188A` — [`188A_failed_schema_policy_recovery.sql`](recovery/188A_failed_schema_policy_recovery.sql)
- `190A` — [`190A_failed_generation_recovery.sql`](recovery/190A_failed_generation_recovery.sql)
- `190B` — [`190B_generation_reconstruction.sql`](recovery/190B_generation_reconstruction.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
