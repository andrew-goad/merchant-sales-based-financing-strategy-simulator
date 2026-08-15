# M2.7 SQL Engineering Audit

```json
{
  "status": "PASS",
  "controlled_sql_programs": 11,
  "sql_source_lines": 7436,
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
  "persistent_insert_audit": [
    {
      "program": "180_msbf_m2_7_schema_policy_operational_setup_extension_v0_2.sql",
      "target": "msbf_ref.acceptance_gate_catalog",
      "target_columns": 6,
      "projection_expressions": 6,
      "method": "VALUES",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "180_msbf_m2_7_schema_policy_operational_setup_extension_v0_2.sql",
      "target": "msbf_ctl.m2_7_policy_profile",
      "target_columns": 50,
      "projection_expressions": 50,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "180_msbf_m2_7_schema_policy_operational_setup_extension_v0_2.sql",
      "target": "msbf_m2.operational_setup_outcome_definition",
      "target_columns": 14,
      "projection_expressions": 14,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "180_msbf_m2_7_schema_policy_operational_setup_extension_v0_2.sql",
      "target": "msbf_m2.operational_setup_action_definition",
      "target_columns": 20,
      "projection_expressions": 20,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "180_msbf_m2_7_schema_policy_operational_setup_extension_v0_2.sql",
      "target": "msbf_m2.operational_setup_reason_definition",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_m2.operational_activation_source_snapshot",
      "target_columns": 19,
      "projection_expressions": 19,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_m2.application_operational_activation_snapshot",
      "target_columns": 34,
      "projection_expressions": 34,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_m2.operational_account_setup_snapshot",
      "target_columns": 29,
      "projection_expressions": 29,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_m2.operational_activation_portfolio_summary",
      "target_columns": 15,
      "projection_expressions": 15,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_m2.application_operational_activation_latest",
      "target_columns": 40,
      "projection_expressions": 40,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_m2.application_operational_activation_archive",
      "target_columns": 42,
      "projection_expressions": 42,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_ctl.m2_7_operational_activation_contract_registry",
      "target_columns": 51,
      "projection_expressions": 51,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "182_msbf_m2_7_operational_activation_generation_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "183_msbf_m2_7_operational_activation_validation_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "184_msbf_m2_7_negative_control_tests_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "185_msbf_m2_7_acceptance_finalize_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "185_msbf_m2_7_acceptance_finalize_v0_2.sql",
      "target": "msbf_ctl.acceptance_gate_result",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    }
  ],
  "program_audit": {
    "180_msbf_m2_7_schema_policy_operational_setup_extension_v0_2.sql": {
      "bytes": 66933,
      "lines": 1644,
      "lexical": [],
      "header": "PASS"
    },
    "182_msbf_m2_7_operational_activation_generation_v0_2.sql": {
      "bytes": 68369,
      "lines": 1803,
      "lexical": [],
      "header": "PASS"
    },
    "183_msbf_m2_7_operational_activation_validation_v0_2.sql": {
      "bytes": 88719,
      "lines": 1279,
      "lexical": [],
      "header": "PASS"
    },
    "184_msbf_m2_7_negative_control_tests_v0_2.sql": {
      "bytes": 21592,
      "lines": 785,
      "lexical": [],
      "header": "PASS"
    },
    "185_msbf_m2_7_acceptance_finalize_v0_2.sql": {
      "bytes": 15453,
      "lines": 335,
      "lexical": [],
      "header": "PASS"
    },
    "180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql": {
      "bytes": 4912,
      "lines": 131,
      "lexical": [],
      "header": "PASS"
    },
    "181_msbf_m2_7_preflight_validation_v0_2.sql": {
      "bytes": 14044,
      "lines": 359,
      "lexical": [],
      "header": "PASS"
    },
    "182A_msbf_m2_7_failed_generation_recovery_check_v0_2.sql": {
      "bytes": 2951,
      "lines": 57,
      "lexical": [],
      "header": "PASS"
    },
    "182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql": {
      "bytes": 4822,
      "lines": 86,
      "lexical": [],
      "header": "PASS"
    },
    "186_MSBF_M2_7_Master_Report_v0_2.sql": {
      "bytes": 14866,
      "lines": 394,
      "lexical": [],
      "header": "PASS"
    },
    "187_MSBF_M2_7_Detail_Report_v0_2.sql": {
      "bytes": 20064,
      "lines": 563,
      "lexical": [],
      "header": "PASS"
    }
  },
  "issues": [],
  "update_audit_note": "False-positive tokens from trigger phrase 'UPDATE OR DELETE' and ON CONFLICT 'DO UPDATE SET' were excluded. Every executable UPDATE statement contains an explicit WHERE predicate."
}
```
