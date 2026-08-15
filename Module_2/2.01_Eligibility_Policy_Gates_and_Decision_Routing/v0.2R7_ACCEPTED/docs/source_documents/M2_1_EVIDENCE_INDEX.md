# M2.1 Evidence Index

## Accepted execution checkpoints

- `accepted_execution/sql/01_132_schema_policy_v0_2.sql` — exact executed source; SHA-256 `a3adf8ad240ea424f49bb601e68b997fadddefbf253d250099197775bf6a5fa1`
- `accepted_execution/tests/02_132B_stage_boundary_recovery_R1.sql` — exact executed source; SHA-256 `fa04e8bd9baaf17197dd5f67ff7453abcf46324d013addf794241c7b0672a68c`
- `accepted_execution/tests/03_133_preflight_R1.sql` — exact executed source; SHA-256 `280e5e88bd96f06bfb2b701b719b4ca7a4be86c81d100e48d8b95a57b77b40b5`
- `accepted_execution/sql/04_134_generation_R1.sql` — exact executed source; SHA-256 `3812115e493619690e87099f9773c0555d0c3dbaadf6506a0e77590f065249ab`
- `accepted_execution/tests/05_132D_generated_state_recovery_R3.sql` — exact executed source; SHA-256 `b7d65b299591a4d4f2fcf3a401a59112c38bf33c06f43c0e67ca4b527cb5b060`
- `accepted_execution/sql/06_135_validation_R3.sql` — exact executed source; SHA-256 `3bfd73fc5312f61bfc0ad1380cf7dc868bf0458a8e22dc68f6f5922f2caf3646`
- `accepted_execution/tests/07_132E_campaign_hash_recovery_R4.sql` — exact executed source; SHA-256 `864fccd1117f8859db0bbb12220e1452df414293891a860f9dee4dcbd9862d85`
- `accepted_execution/sql/08_135_validation_R4.sql` — exact executed source; SHA-256 `97a41a6aa93df3879f70640779bacb99bdc0229a814328dc597458528d98c1f3`
- `accepted_execution/tests/09_132F_boundary_assertion_recovery_R5.sql` — exact executed source; SHA-256 `5d93a0fc4fb1d261ea60ae105aff1fcd320e8838601e327fbf64bcbbbd5b44af`
- `accepted_execution/tests/10_132G_validation_context_recovery_R6.sql` — exact executed source; SHA-256 `487054e269e725ddffb85ce7711c628e40fb93abac3c48f6c07afa7cd9f6a312`
- `accepted_execution/sql/11_135_final_positive_validation_R6.sql` — exact executed source; SHA-256 `e226e9bc718987f6293deacdcc97d3e8904ef57336335c0f4d12210d18e79d80`
- `accepted_execution/sql/12_136_final_negative_controls_R6.sql` — exact executed source; SHA-256 `20f214f0cb92ac05a22cfd0a91c0b95dea0970f014f9659b9f84ec9a3656dd1a`
- `accepted_execution/tests/13_132H_pre_acceptance_recovery_R7.sql` — exact executed source; SHA-256 `4473f3ddd9db32feb9cce0cea8f138df106ad119b6ac36c060bc4d4e0c432a61`
- `accepted_execution/sql/14_137_acceptance_finalize_R7.sql` — exact executed source; SHA-256 `12aa63168a757933672c10f6e997e1bb0812ee4c40adeaf8e02b91f9c6f50927`
- `accepted_execution/tests/15_138_master_report_R7.sql` — exact executed source; SHA-256 `0fd3532ee323bef4bdef33f75e88142f0d847c96ccaf14c78fc272d080411175`
- `accepted_execution/tests/16_139_detail_report_R7.sql` — exact executed source; SHA-256 `c1e906ce311eced1f4d6a5d44a82e803b0b04782f5b63eb918aee559e6c1d938`

## Final control and acceptance evidence

- `evidence/final/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R6_results_20260730.csv`
- `evidence/final/136_msbf_m2_1_negative_control_tests_v0_2R6_results_20260730.csv`
- `evidence/final/132H_msbf_m2_1_failed_acceptance_ambiguity_recovery_check_v0_2R7_results_20260730.csv`
- `evidence/final/137_msbf_m2_1_acceptance_finalize_v0_2R7137_msbf_m2_1_acceptance_finalize_v0_2R7_results_20260730.csv`
- `evidence/final/MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Master_Report_v0_2R7_20260730.csv`

## Detailed-report result sets

| Result set | Title | Rows | Packaged file |
|---:|---|---:|---|
| 01 | Run Contract Lifecycle And Acceptance Gate | 1 | `evidence/final/01_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Run_Contract_Lifecycle_And_Acceptance_Gate_20260730.csv` |
| 02 | Policy Campaign And Registry Identity | 1 | `evidence/final/02_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Policy_Campaign_And_Registry_Identity_20260730.csv` |
| 03 | Accepted G2 Source Boundary | 1 | `evidence/final/03_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Accepted_G2_Source_Boundary_20260730.csv` |
| 04 | Entity Cardinality And Grains | 8 | `evidence/final/04_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Entity_Cardinality_And_Grains_20260730.csv` |
| 05 | Gate Definitions | 12 | `evidence/final/05_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Gate_Definitions_20260730.csv` |
| 06 | Transparent Reason Code Dictionary | 23 | `evidence/final/06_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Transparent_Reason_Code_Dictionary_20260730.csv` |
| 07 | Routing Outcome Definitions | 4 | `evidence/final/07_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Routing_Outcome_Definitions_20260730.csv` |
| 08 | Gate Outcomes By Scenario And Gate | 72 | `evidence/final/08_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Gate_Outcomes_By_Scenario_And_Gate_20260730.csv` |
| 09 | Final Route Distribution By Scenario | 8 | `evidence/final/09_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Final_Route_Distribution_By_Scenario_20260730.csv` |
| 10 | Routing Evidence Status | 4 | `evidence/final/10_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Routing_Evidence_Status_20260730.csv` |
| 11 | Primary Reason Distribution | 17 | `evidence/final/11_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Primary_Reason_Distribution_20260730.csv` |
| 12 | Hard Stop Diagnostics | 2 | `evidence/final/12_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Hard_Stop_Diagnostics_20260730.csv` |
| 13 | Eligible For Offer Design Population | 2 | `evidence/final/13_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Eligible_For_Offer_Design_Population_20260730.csv` |
| 14 | Manual Review Population | 8 | `evidence/final/14_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Manual_Review_Population_20260730.csv` |
| 15 | Insufficient Evidence Population | 2 | `evidence/final/15_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Insufficient_Evidence_Population_20260730.csv` |
| 16 | Policy Decline Population | 5 | `evidence/final/16_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Policy_Decline_Population_20260730.csv` |
| 17 | Matched Baseline Stress Route Migration | 9 | `evidence/final/17_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Matched_Baseline_Stress_Route_Migration_20260730.csv` |
| 18 | Stress Floor Diagnostics | 3 | `evidence/final/18_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Stress_Floor_Diagnostics_20260730.csv` |
| 19 | Industry And Merchant Size Routing Diagnostics | 184 | `evidence/final/19_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Industry_And_Merchant_Size_Routing_Diagnostics_20260730.csv` |
| 20 | Acquisition Evidence Operational Boundary | 4 | `evidence/final/20_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Acquisition_Evidence_Operational_Boundary_20260730.csv` |
| 21 | Latest Archive Reproduction | 1 | `evidence/final/21_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Latest_Archive_Reproduction_20260730.csv` |
| 22 | Governed M2 1 Evidence Summary | 5 | `evidence/final/22_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Governed_M2_1_Evidence_Summary_20260730.csv` |
| 23 | Deterministic Mismatches | 0 | `evidence/final/23_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Deterministic_Mismatches_20260730.csv` |
| 24 | Blocking Errors And Stage Boundary Violations | 0 | `evidence/final/24_MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Blocking_Errors_And_Stage_Boundary_Violations_20260730.csv` |

Result Sets 23 and 24 retain their headers and contain zero data rows.

## Correction history

- `evidence/history/132_msbf_m2_1_schema_policy_extension_v0_2_results_20260729.csv`
- `evidence/history/132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1_results_20260729.csv`
- `evidence/history/133_msbf_m2_1_preflight_validation_v0_2R1_results_20260729.csv`
- `evidence/history/134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R1_results_20260729.csv`
- `evidence/history/132D_msbf_m2_1_generated_state_recovery_and_comparison_view_check_v0_2R3_results_20260729.csv`
- `evidence/history/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R3_results_20260729.csv`
- `evidence/history/132E_msbf_m2_1_failed_campaign_physical_row_hash_recovery_v0_2R4_results_20260730.csv`
- `evidence/history/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R4_results_20260730.csv`
- `evidence/history/132F_msbf_m2_1_failed_negative_control_boundary_assertion_recovery_v0_2R5_results_20260730.csv`
- `evidence/history/132G_msbf_m2_1_failed_validation_context_projection_recovery_check_v0_2R6_results_20260730.csv`

The `source_history` and `evidence/errors` directories preserve the complete fail-closed correction trail.
