# M2.3 v0.2R2 SQL Engineering Audit

```json
{
  "status": "PASS",
  "failure_class": "PROHIBITED_PAYLOAD_KEY_VOCABULARY_MISMATCH",
  "failed_negative_control": "M2_3_NEG_019_EXTERNAL_NOTICE_PAYLOAD",
  "prior_negative_passes": 19,
  "prior_negative_failures": 1,
  "missing_key_in_v0_2R1": "external_notice_payload",
  "proactive_alignment_key": "account_number",
  "live_recovery_program": "148C_msbf_m2_3_failed_external_notice_payload_boundary_recovery_v0_2R2.sql",
  "positive_control_inventory": 120,
  "negative_control_inventory": 20,
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
  "continuation_program_logic_equivalence": {
    "152_msbf_m2_3_negative_control_tests_v0_2R2.sql": true,
    "153_msbf_m2_3_acceptance_finalize_v0_2R2.sql": true,
    "154_MSBF_M2_3_Master_Report_v0_2R2.sql": true,
    "155_MSBF_M2_3_Detail_Report_v0_2R2.sql": true
  },
  "live_clean_continuation_identity": {
    "152_msbf_m2_3_negative_control_tests_v0_2R2.sql": true,
    "153_msbf_m2_3_acceptance_finalize_v0_2R2.sql": true,
    "154_MSBF_M2_3_Master_Report_v0_2R2.sql": true,
    "155_MSBF_M2_3_Detail_Report_v0_2R2.sql": true
  },
  "generated_data_changed": false,
  "hashes_changed": false,
  "positive_evidence_changed": false,
  "policy_values_changed": false,
  "decision_mapping_changed": false,
  "business_logic_changed": false,
  "source_findings": {},
  "issues": [],
  "warnings": []
}
```
