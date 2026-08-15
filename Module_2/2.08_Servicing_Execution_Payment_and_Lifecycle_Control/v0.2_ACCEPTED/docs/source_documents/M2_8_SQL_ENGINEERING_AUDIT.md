# M2.8 SQL Engineering Audit

```json
{
  "status": "PASS",
  "accepted_baseline_archive": "MSBF_Project_v0_2_M2_7_COMPLETE_FINAL_Windows_ACCEPTED_20260803(2).zip",
  "accepted_baseline_sha256": "747a726ba487046a299772c9abfaf5bb9a53309774f17820341fc7d7b421d8af",
  "controlled_sql_programs": 11,
  "sql_source_lines": 1692,
  "positive_control_codes": 120,
  "positive_control_calls": 120,
  "negative_control_codes": 20,
  "detail_result_sets": [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
    23,
    24
  ],
  "accepted_source_relation": "msbf_m2.application_operational_activation_latest",
  "accepted_source_scan_count": 1,
  "accepted_source_missing_columns": [],
  "accepted_registry_missing_columns": [],
  "program_audit": {
    "188_msbf_m2_8_schema_policy_payment_lifecycle_extension_v0_2.sql": {
      "bytes": 72999,
      "lines": 730,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 7
    },
    "190_msbf_m2_8_servicing_payment_lifecycle_generation_v0_2.sql": {
      "bytes": 66282,
      "lines": 260,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 7
    },
    "191_msbf_m2_8_servicing_payment_lifecycle_validation_v0_2.sql": {
      "bytes": 81341,
      "lines": 162,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "192_msbf_m2_8_negative_control_tests_v0_2.sql": {
      "bytes": 13734,
      "lines": 133,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "193_msbf_m2_8_acceptance_finalize_v0_2.sql": {
      "bytes": 14816,
      "lines": 70,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "188A_msbf_m2_8_failed_schema_policy_recovery_check_v0_2.sql": {
      "bytes": 3839,
      "lines": 44,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "189_msbf_m2_8_preflight_validation_v0_2.sql": {
      "bytes": 11889,
      "lines": 93,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "190A_msbf_m2_8_failed_generation_recovery_check_v0_2.sql": {
      "bytes": 2832,
      "lines": 38,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "190B_msbf_m2_8_generation_reconciliation_reconstructed_v0_2.sql": {
      "bytes": 4970,
      "lines": 42,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "194_MSBF_M2_8_Master_Report_v0_2.sql": {
      "bytes": 12543,
      "lines": 42,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 0
    },
    "195_MSBF_M2_8_Detail_Report_v0_2.sql": {
      "bytes": 17320,
      "lines": 78,
      "header": "PASS",
      "lexical": "PASS",
      "major_section_markers": 24
    }
  },
  "issues": [],
  "warnings": []
}
```
