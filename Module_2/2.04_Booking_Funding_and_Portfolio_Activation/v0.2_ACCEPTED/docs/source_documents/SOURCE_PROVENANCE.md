# M2.4 Accepted Execution Source Provenance

The exact Programs 156–163 executed against PostgreSQL are preserved in this
folder. All eight programs executed from the original M2.4 v0.2 source package;
no live hotfix or recovery program was required.

| Order | Program | Revision | Purpose | Preserved path |
|---:|---:|---|---|---|
| 1 | 156 | v0.2 | Schema, policy, dictionaries, contract, and views | `accepted_execution/sql/01_156_schema_policy.sql` |
| 2 | 157 | v0.2 | Hard-stop preflight | `accepted_execution/tests/02_157_preflight.sql` |
| 3 | 158 | v0.2 | Deterministic booking/funding/activation generation | `accepted_execution/sql/03_158_generation.sql` |
| 4 | 159 | v0.2 | 120 positive controls | `accepted_execution/sql/04_159_positive_validation.sql` |
| 5 | 160 | v0.2 | 20 negative controls | `accepted_execution/sql/05_160_negative_controls.sql` |
| 6 | 161 | v0.2 | Acceptance finalizer | `accepted_execution/sql/06_161_acceptance_finalize.sql` |
| 7 | 162 | v0.2 | Master report | `accepted_execution/tests/07_162_master_report.sql` |
| 8 | 163 | v0.2 | Twenty-four detailed result sets | `accepted_execution/tests/08_163_detail_report.sql` |
