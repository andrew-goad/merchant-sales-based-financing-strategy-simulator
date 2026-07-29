# M1.12 Accepted Execution Path

| Order | Program | Result |
|---:|---|---|
| 1 | `84_msbf_m1_12_schema_policy_extension_v0_2.sql` | PASS |
| 2 | `85_msbf_m1_12_preflight_validation_v0_2.sql` | PASS |
| 3 | `86_msbf_m1_12_integrated_risk_proxy_generation_v0_2.sql` | PASS |
| 4 | `87_msbf_m1_12_integrated_risk_proxy_validation_v0_2.sql` | 80 / 80 PASS |
| 5 | `88_msbf_m1_12_negative_control_tests_v0_2.sql` | 7 / 7 PASS |
| 6 | `89_msbf_m1_12_acceptance_finalize_v0_2.sql` | PASS |
| 7 | `90_MSBF_M1_12_Merchant_Risk_Proxy_Master_Report_v0_2.sql` | PASS |
| 8 | `91_MSBF_M1_12_Merchant_Risk_Proxy_Detail_Report_v0_2.sql` | Result sets 1–19 returned; result set 20 failed on invalid `error_id` |
| 9 | `91_MSBF_M1_12_Merchant_Risk_Proxy_Detail_Report_v0_2R1.sql` | 20 result sets; PASS |

Programs 84–90 remain the accepted v0.2 logic. The final clean-build reporting path uses program 91 v0.2R1.
