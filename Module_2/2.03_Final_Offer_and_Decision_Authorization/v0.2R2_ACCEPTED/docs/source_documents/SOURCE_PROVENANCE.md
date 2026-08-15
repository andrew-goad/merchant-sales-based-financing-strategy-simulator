# M2.3 Accepted Execution Source Provenance

The final accepted M2.3 state was produced by the controlled execution chain below. The consolidated `sql/` and `tests/` folders contain the clean v0.2R2 source, while `accepted_execution/` preserves the exact revisions executed against the database.

| Order | Program | Revision | Purpose | Exact accepted source |
|---:|---|---|---|---|
| 1 | 148 | `v0.2R1` | Schema, policy, physical policy hash, gate registration | `accepted_execution/sql/01_148_schema_policy_R1.sql` |
| 2 | 148B | `v0.2R1` | Failed policy-hash/schema recovery proof | `accepted_execution/tests/02_148B_policy_hash_schema_recovery_R1.sql` |
| 3 | 149 | `v0.2R1` | Hard-stop preflight | `accepted_execution/tests/03_149_preflight_R1.sql` |
| 4 | 150 | `v0.2R1` | Deterministic final-offer/decision generation | `accepted_execution/sql/04_150_generation_R1.sql` |
| 5 | 151 | `v0.2R1` | 120 positive controls | `accepted_execution/sql/05_151_positive_validation_R1.sql` |
| 6 | 148C | `v0.2R2` | External-notice payload boundary recovery | `accepted_execution/tests/06_148C_external_notice_payload_recovery_R2.sql` |
| 7 | 152 | `v0.2R2` | 20 negative controls | `accepted_execution/sql/07_152_negative_controls_R2.sql` |
| 8 | 153 | `v0.2R2` | Acceptance finalizer | `accepted_execution/sql/08_153_acceptance_finalize_R2.sql` |
| 9 | 154 | `v0.2R2` | Master report | `accepted_execution/tests/09_154_master_report_R2.sql` |
| 10 | 155 | `v0.2R2` | 24 detailed result sets | `accepted_execution/tests/10_155_detail_report_R2.sql` |
