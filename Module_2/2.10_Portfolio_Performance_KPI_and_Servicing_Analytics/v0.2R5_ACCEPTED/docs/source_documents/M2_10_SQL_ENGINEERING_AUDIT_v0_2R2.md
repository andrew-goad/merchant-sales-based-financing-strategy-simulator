# M2.10 v0.2R2 SQL Engineering Audit

```json
{
  "status": "PASS",
  "revision": "v0.2R2",
  "input_archive": "M2_10_STANDALONE_FRESH_20260804_R1.zip",
  "input_archive_sha256": "e745f8c3a1a9e4a6815f4a65a32bdc0d4c3c8de3a6bb18ca0f200a5f1299d0be",
  "program_205A_checkpoint": "PASS",
  "program_205_checkpoint": "PASS",
  "controlled_sql_programs": 13,
  "sql_source_lines": 7501,
  "positive_control_codes": 120,
  "positive_control_calls": 120,
  "negative_control_codes": 20,
  "detail_result_sets": 24,
  "accepted_source_scan_count": 1,
  "stale_active_literal_count": 0,
  "exact_active_literal_count": 37,
  "persistent_generation_evidence_projection": "EXPLICIT",
  "source_mapping_fail_closed": "PASS",
  "program_audit": {
    "204_msbf_m2_10_schema_policy_portfolio_analytics_extension_v0_2.sql": {
      "lines": 1132,
      "bytes": 64568,
      "header": "PASS",
      "sections": 9,
      "lexical": []
    },
    "206_msbf_m2_10_portfolio_performance_kpi_generation_v0_2R1.sql": {
      "lines": 1259,
      "bytes": 77930,
      "header": "PASS",
      "sections": 10,
      "lexical": []
    },
    "207_msbf_m2_10_portfolio_performance_kpi_validation_v0_2R1.sql": {
      "lines": 1914,
      "bytes": 120057,
      "header": "PASS",
      "sections": 2,
      "lexical": []
    },
    "208_msbf_m2_10_negative_control_tests_v0_2R1.sql": {
      "lines": 537,
      "bytes": 24210,
      "header": "PASS",
      "sections": 2,
      "lexical": []
    },
    "209_msbf_m2_10_acceptance_finalize_v0_2R1.sql": {
      "lines": 445,
      "bytes": 25667,
      "header": "PASS",
      "sections": 4,
      "lexical": []
    },
    "204A_msbf_m2_10_failed_schema_policy_recovery_check_v0_2.sql": {
      "lines": 77,
      "bytes": 4403,
      "header": "PASS",
      "sections": 0,
      "lexical": []
    },
    "205A_msbf_m2_10_failed_active_reconciled_preflight_diagnostic_v0_2R1.sql": {
      "lines": 144,
      "bytes": 4956,
      "header": "PASS",
      "sections": 0,
      "lexical": []
    },
    "205_msbf_m2_10_preflight_validation_v0_2R1.sql": {
      "lines": 255,
      "bytes": 17829,
      "header": "PASS",
      "sections": 0,
      "lexical": []
    },
    "206A_msbf_m2_10_failed_generation_recovery_check_v0_2R1.sql": {
      "lines": 168,
      "bytes": 8780,
      "header": "PASS",
      "sections": 0,
      "lexical": []
    },
    "206B_msbf_m2_10_generation_reconciliation_reconstructed_v0_2R1.sql": {
      "lines": 294,
      "bytes": 15714,
      "header": "PASS",
      "sections": 0,
      "lexical": []
    },
    "207A_msbf_m2_10_failed_positive_validation_recovery_check_v0_2R1.sql": {
      "lines": 252,
      "bytes": 12219,
      "header": "PASS",
      "sections": 0,
      "lexical": []
    },
    "210_MSBF_M2_10_Master_Report_v0_2R1.sql": {
      "lines": 410,
      "bytes": 22061,
      "header": "PASS",
      "sections": 2,
      "lexical": []
    },
    "211_MSBF_M2_10_Detail_Report_v0_2R1.sql": {
      "lines": 614,
      "bytes": 32408,
      "header": "PASS",
      "sections": 26,
      "lexical": []
    }
  },
  "issues": [],
  "warnings": []
}
```
