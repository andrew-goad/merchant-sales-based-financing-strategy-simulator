# M2.2 SQL Engineering Audit

```json
{
  "status": "PASS",
  "accepted_baseline_archive": "MSBF_Project_v0_2R2_M2_1_COMPLETE_FINAL_Windows.zip",
  "accepted_baseline_sha256": "40fc6cdf927740a017c245fe84d89bf427b9fd3e9ba47c223b1d99fe463a4fc5",
  "controlled_sql_programs": 10,
  "sql_source_lines": 1287,
  "expected_counts": {
    "policy_rows": 1,
    "template_rows": 5,
    "reason_rows": 18,
    "disposition_rows": 4,
    "request_snapshot_rows": 750,
    "request_latest_rows": 750,
    "request_archive_rows": 750,
    "candidate_rows": 557,
    "pricing_snapshot_rows": 1500,
    "pricing_latest_rows": 1500,
    "pricing_archive_rows": 1500,
    "comparison_rows": 750,
    "registry_rows": 1,
    "canonical_entities": 7336,
    "positive_controls": 120,
    "negative_controls": 20,
    "detail_result_sets": 24,
    "generation_evidence_rows": 20
  },
  "checks": {
    "programs": true,
    "positive_controls": true,
    "negative_controls": true,
    "detail_sets": true,
    "no_random": true,
    "no_using_join": true,
    "no_braced_regex": true,
    "reviewer_role": true,
    "preserved_validation_output": true,
    "preserved_negative_output": true,
    "recovery_140A": true,
    "recovery_142A": true
  },
  "live_postgresql_execution": false,
  "formal_acceptance_issued": false,
  "limitations": [
    "No PostgreSQL server was available in the build environment; live transactional execution remains required."
  ]
}
```
