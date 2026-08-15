# M2.9 SQL Engineering Audit

```json
{
  "status": "PASS",
  "accepted_baseline_archive": "MSBF_Project_v0_2_M2_8_COMPLETE_FINAL_Windows_ACCEPTED_20260803(1).zip",
  "accepted_baseline_sha256": "91649efbd678fb423e5b6b30865e5519dbe0fe2c76a1837c5d938a05b602afc2",
  "accepted_project_root": "MSBF_Project_v0_2_M2_8_COMPLETE_FINAL",
  "accepted_predecessor_stage_count": 27,
  "controlled_sql_programs": 11,
  "sql_source_lines": 2845,
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
  "source_scan_audit": {
    "msbf_m2.application_servicing_execution_latest": {
      "alias": "source",
      "count": 1,
      "status": "PASS"
    },
    "msbf_m2.synthetic_payment_processing_event": {
      "alias": "payment",
      "count": 1,
      "status": "PASS"
    },
    "msbf_m2.account_lifecycle_transition_snapshot": {
      "alias": "transition",
      "count": 1,
      "status": "PASS"
    }
  },
  "accepted_source_columns": {
    "latest": [
      "module1_run_id",
      "contract_code",
      "contract_version",
      "schema_version",
      "methodology_version",
      "scenario_id",
      "scenario_code",
      "merchant_application_id",
      "merchant_id",
      "synthetic_account_id",
      "synthetic_advance_id",
      "source_operational_setup_outcome_code",
      "source_operational_setup_action_code",
      "source_account_setup_status_code",
      "source_exposure_amount",
      "servicing_execution_outcome_code",
      "servicing_execution_action_code",
      "servicing_execution_priority_rank",
      "servicing_execution_queue_code",
      "processing_authorized_flag",
      "processing_review_required_flag",
      "no_processing_required_flag",
      "synthetic_servicing_execution_id",
      "initial_lifecycle_state_code",
      "final_lifecycle_state_code",
      "payment_event_count",
      "settled_event_count",
      "returned_event_count",
      "retry_event_count",
      "standard_daily_payment_amount",
      "temporary_daily_payment_amount",
      "scheduled_payment_amount",
      "processed_payment_amount",
      "returned_payment_amount",
      "retry_payment_amount",
      "ending_simulated_exposure_amount",
      "primary_execution_reason_code",
      "execution_reason_codes",
      "source_contract_row_hash",
      "source_snapshot_row_hash",
      "execution_snapshot_row_hash",
      "policy_configuration_hash",
      "contract_row_hash",
      "created_at"
    ],
    "payment": [
      "module1_run_id",
      "scenario_id",
      "scenario_code",
      "merchant_application_id",
      "synthetic_account_id",
      "synthetic_advance_id",
      "synthetic_servicing_execution_id",
      "synthetic_servicing_plan_id",
      "event_sequence",
      "event_date",
      "payment_event_type_code",
      "payment_status_code",
      "standard_daily_payment_amount",
      "applied_payment_factor",
      "scheduled_payment_amount",
      "retry_payment_amount",
      "returned_payment_amount",
      "processed_payment_amount",
      "cumulative_processed_amount",
      "simulated_outstanding_exposure_amount",
      "lifecycle_state_before_code",
      "lifecycle_state_after_code",
      "primary_event_reason_code",
      "synthetic_payment_instruction_id",
      "synthetic_processor_reference_id",
      "real_funds_moved_flag",
      "bank_account_data_present_flag",
      "ach_or_network_transmitted_flag",
      "external_processor_called_flag",
      "merchant_contact_executed_flag",
      "external_notice_generated_flag",
      "production_adverse_action_flag",
      "source_execution_row_hash",
      "row_hash",
      "created_at"
    ],
    "transition": [
      "module1_run_id",
      "scenario_id",
      "scenario_code",
      "merchant_application_id",
      "synthetic_account_id",
      "synthetic_advance_id",
      "synthetic_servicing_execution_id",
      "transition_sequence",
      "transition_date",
      "transition_type_code",
      "lifecycle_state_before_code",
      "lifecycle_state_after_code",
      "related_payment_event_sequence",
      "related_payment_instruction_id",
      "primary_transition_reason_code",
      "real_funds_moved_flag",
      "production_account_state_flag",
      "external_system_update_flag",
      "source_execution_row_hash",
      "related_payment_event_row_hash",
      "row_hash",
      "created_at"
    ],
    "registry": [
      "registry_id",
      "module1_run_id",
      "contract_code",
      "contract_version",
      "schema_version",
      "methodology_version",
      "source_contract_code",
      "source_contract_version",
      "source_schema_version",
      "source_acceptance_gate_id",
      "source_combined_set_hash",
      "policy_configuration_hash",
      "policy_rows",
      "outcome_rows",
      "action_rows",
      "lifecycle_state_rows",
      "reason_rows",
      "source_rows",
      "execution_rows",
      "payment_event_rows",
      "lifecycle_transition_rows",
      "portfolio_summary_rows",
      "latest_rows",
      "archive_rows",
      "comparison_rows",
      "registry_rows",
      "canonical_entities",
      "no_processing_required_rows",
      "temporary_processing_rows",
      "review_hold_rows",
      "settled_event_rows",
      "returned_event_rows",
      "retry_event_rows",
      "initial_transition_rows",
      "payment_transition_rows",
      "checkpoint_transition_rows",
      "processing_authorized_amount",
      "review_hold_amount",
      "scheduled_payment_amount",
      "processed_payment_amount",
      "returned_payment_amount",
      "retry_payment_amount",
      "ending_simulated_exposure_amount",
      "policy_set_hash",
      "outcome_set_hash",
      "action_set_hash",
      "lifecycle_state_set_hash",
      "reason_set_hash",
      "source_set_hash",
      "execution_set_hash",
      "payment_event_set_hash",
      "lifecycle_transition_set_hash",
      "portfolio_summary_set_hash",
      "latest_set_hash",
      "archive_set_hash",
      "contract_set_hash",
      "combined_set_hash",
      "contract_status",
      "generated_at",
      "validated_at",
      "accepted_at",
      "row_hash",
      "created_at"
    ]
  },
  "accepted_source_missing_columns": {
    "latest": [],
    "payment": [],
    "transition": [],
    "registry": []
  },
  "program_audit": {
    "196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql": {
      "lines": 918,
      "bytes": 78680,
      "header": "PASS",
      "navigation_count": 9
    },
    "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql": {
      "lines": 352,
      "bytes": 90524,
      "header": "PASS",
      "navigation_count": 8
    },
    "199_msbf_m2_9_payment_reconciliation_certification_validation_v0_2.sql": {
      "lines": 538,
      "bytes": 87788,
      "header": "PASS",
      "navigation_count": 2
    },
    "200_msbf_m2_9_negative_control_tests_v0_2.sql": {
      "lines": 157,
      "bytes": 15008,
      "header": "PASS",
      "navigation_count": 3
    },
    "201_msbf_m2_9_acceptance_finalize_v0_2.sql": {
      "lines": 194,
      "bytes": 19621,
      "header": "PASS",
      "navigation_count": 5
    },
    "196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql": {
      "lines": 47,
      "bytes": 4231,
      "header": "PASS",
      "navigation_count": 0
    },
    "197_msbf_m2_9_preflight_validation_v0_2.sql": {
      "lines": 128,
      "bytes": 16083,
      "header": "PASS",
      "navigation_count": 3
    },
    "198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql": {
      "lines": 39,
      "bytes": 3380,
      "header": "PASS",
      "navigation_count": 0
    },
    "198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql": {
      "lines": 65,
      "bytes": 6068,
      "header": "PASS",
      "navigation_count": 0
    },
    "202_MSBF_M2_9_Master_Report_v0_2.sql": {
      "lines": 165,
      "bytes": 15463,
      "header": "PASS",
      "navigation_count": 2
    },
    "203_MSBF_M2_9_Detail_Report_v0_2.sql": {
      "lines": 242,
      "bytes": 21906,
      "header": "PASS",
      "navigation_count": 24
    }
  },
  "update_audit": [
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_account_source_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_payment_source_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_transition_source_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_payment_reconciliation_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_exception_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_account_reconciliation_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_certification_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_portfolio_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_latest_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_archive_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_registry_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_registry_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "_m2_9_registry_expected",
      "has_where": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_ctl.run_registry",
      "has_where": true
    },
    {
      "program": "201_msbf_m2_9_acceptance_finalize_v0_2.sql",
      "target": "msbf_ctl.m2_9_reconciliation_certification_contract_registry",
      "has_where": true
    },
    {
      "program": "201_msbf_m2_9_acceptance_finalize_v0_2.sql",
      "target": "msbf_ctl.run_registry",
      "has_where": true
    },
    {
      "program": "201_msbf_m2_9_acceptance_finalize_v0_2.sql",
      "target": "_m2_9_acceptance",
      "has_where": true
    }
  ],
  "persistent_insert_audit": [
    {
      "program": "196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql",
      "target": "msbf_ref.acceptance_gate_catalog",
      "target_columns": 6,
      "projection_expressions": 6,
      "method": "VALUES",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql",
      "target": "msbf_ctl.m2_9_policy_profile",
      "target_columns": 58,
      "projection_expressions": 58,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql",
      "target": "msbf_m2.payment_reconciliation_outcome_definition",
      "target_columns": 12,
      "projection_expressions": 12,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql",
      "target": "msbf_m2.exception_resolution_action_definition",
      "target_columns": 12,
      "projection_expressions": 12,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql",
      "target": "msbf_m2.account_state_certification_definition",
      "target_columns": 11,
      "projection_expressions": 11,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "196_msbf_m2_9_schema_policy_reconciliation_certification_extension_v0_2.sql",
      "target": "msbf_m2.payment_reconciliation_reason_definition",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.account_reconciliation_source_snapshot",
      "target_columns": 30,
      "projection_expressions": 30,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.payment_reconciliation_source_event",
      "target_columns": 27,
      "projection_expressions": 27,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.lifecycle_certification_source_transition",
      "target_columns": 21,
      "projection_expressions": 21,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.payment_event_reconciliation_snapshot",
      "target_columns": 23,
      "projection_expressions": 23,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.payment_exception_case_snapshot",
      "target_columns": 20,
      "projection_expressions": 20,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.account_payment_reconciliation_snapshot",
      "target_columns": 48,
      "projection_expressions": 48,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.account_state_certification_snapshot",
      "target_columns": 22,
      "projection_expressions": 22,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.payment_reconciliation_portfolio_summary",
      "target_columns": 20,
      "projection_expressions": 20,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.application_payment_reconciliation_certification_latest",
      "target_columns": 47,
      "projection_expressions": 47,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_m2.application_payment_reconciliation_certification_archive",
      "target_columns": 49,
      "projection_expressions": 49,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_ctl.m2_9_reconciliation_certification_contract_registry",
      "target_columns": 73,
      "projection_expressions": 73,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "198_msbf_m2_9_reconciliation_exception_certification_generation_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "199_msbf_m2_9_payment_reconciliation_certification_validation_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "200_msbf_m2_9_negative_control_tests_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "201_msbf_m2_9_acceptance_finalize_v0_2.sql",
      "target": "msbf_ctl.acceptance_gate_result",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    },
    {
      "program": "201_msbf_m2_9_acceptance_finalize_v0_2.sql",
      "target": "msbf_ctl.run_evidence",
      "target_columns": 9,
      "projection_expressions": 9,
      "method": "SELECT",
      "select_star": false,
      "count_match": true
    }
  ],
  "latest_archive_alias_audit": {
    "199_msbf_m2_9_payment_reconciliation_certification_validation_v0_2.sql": {
      "matches": [
        [
          "archive",
          "latest"
        ],
        [
          "archive",
          "latest"
        ]
      ],
      "status": "PASS"
    },
    "201_msbf_m2_9_acceptance_finalize_v0_2.sql": {
      "matches": [
        [
          "archive",
          "latest"
        ]
      ],
      "status": "PASS"
    },
    "202_MSBF_M2_9_Master_Report_v0_2.sql": {
      "matches": [
        [
          "archive",
          "latest"
        ]
      ],
      "status": "PASS"
    },
    "203_MSBF_M2_9_Detail_Report_v0_2.sql": {
      "matches": [
        [
          "archive",
          "latest"
        ]
      ],
      "status": "PASS"
    }
  },
  "issues": [],
  "warnings": []
}
```
