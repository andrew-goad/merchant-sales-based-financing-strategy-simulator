# PostgreSQL Live Execution and QA Guide

## Purpose

Execute and validate the MSBF Module 1 physical foundation in a clean PostgreSQL 14+ database. PostgreSQL 17.9 on Windows was the accepted G0 environment.

## Execution order

1. Create a clean database named `msbf_strategy`.
2. Execute `sql/00_msbf_physical_schema_v0_2.sql` with stop-on-error behavior.
3. Commit only after the schema completes without errors.
4. Execute `sql/01_msbf_reference_parameter_seed_v0_2.sql`.
5. Commit only after the seed completes without errors.
6. Execute `tests/MSBF_Physical_Foundation_Live_Execution_Validation_Report_v0_2.sql`.
7. Export the single result row to CSV.
8. Compare the output to the accepted values below.
9. Rerun the seed and confirm that seeded counts remain unchanged.
10. Preserve the SQL, CSV, server logs, environment details, and acceptance milestone.

## Accepted structural values

| Metric | Expected |
|---|---:|
| Project schemas | 8 |
| Designed parent/non-child tables | 70 |
| Child partition tables | 4 |
| Physical base-table relations | 74 |
| Designed-table columns | 1,041 |
| Child-partition table columns | 80 |
| View columns | 92 |
| `information_schema` columns | 1,213 |
| Views | 5 |
| Functions | 3 |
| Primary keys | 70 |
| Designed foreign keys | 141 |
| Child-partition foreign keys | 20 |
| Total foreign keys | 161 |
| Parameter definitions | 155 |
| Parameter sets | 1 |
| Parameter values | 397 |
| Feature definitions | 32 |
| Industries | 8 |
| Merchant/application/latest/archive rows before generation | 0 |

## Important catalog rule

`pg_inherits` also records partitioned-index inheritance. Child-table counts must restrict `pg_class.relkind` to ordinary tables (`'r'`). The approved validation SQL contains that correction.

## Acceptance boundary

Passing this guide accepts the physical database and governed seed only. It does not accept populated Module 1 outputs, production underwriting policy, calibrated risk estimates, production pricing, legal conclusions, compliance certification, accounting treatment, or economic forecasts.
