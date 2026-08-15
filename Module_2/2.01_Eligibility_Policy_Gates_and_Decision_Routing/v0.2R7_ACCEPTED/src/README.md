# Source Classification — M2.1

## Current normal chain

- `01` — [`01_132_schema_policy_v0_2.sql`](current/01_132_schema_policy_v0_2.sql)
- `03` — [`03_133_preflight_R1.sql`](current/03_133_preflight_R1.sql)
- `04` — [`04_134_generation_R1.sql`](current/04_134_generation_R1.sql)
- `06` — [`06_135_validation_R3.sql`](current/06_135_validation_R3.sql)
- `08` — [`08_135_validation_R4.sql`](current/08_135_validation_R4.sql)
- `11` — [`11_135_final_positive_validation_R6.sql`](current/11_135_final_positive_validation_R6.sql)
- `12` — [`12_136_final_negative_controls_R6.sql`](current/12_136_final_negative_controls_R6.sql)
- `14` — [`14_137_acceptance_finalize_R7.sql`](current/14_137_acceptance_finalize_R7.sql)
- `132` — [`132_msbf_m2_1_schema_policy_extension_v0_2R7.sql`](current/132_msbf_m2_1_schema_policy_extension_v0_2R7.sql)
- `133` — [`133_msbf_m2_1_preflight_validation_v0_2R7.sql`](current/133_msbf_m2_1_preflight_validation_v0_2R7.sql)
- `134` — [`134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R7.sql`](current/134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R7.sql)
- `135` — [`135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R7.sql`](current/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R7.sql)
- `136` — [`136_msbf_m2_1_negative_control_tests_v0_2R7.sql`](current/136_msbf_m2_1_negative_control_tests_v0_2R7.sql)

## Reporting

- `15` — [`15_138_master_report_R7.sql`](reporting/15_138_master_report_R7.sql)
- `16` — [`16_139_detail_report_R7.sql`](reporting/16_139_detail_report_R7.sql)

## Recovery boundary

- `02` — [`02_132B_stage_boundary_recovery_R1.sql`](recovery/02_132B_stage_boundary_recovery_R1.sql)
- `05` — [`05_132D_generated_state_recovery_R3.sql`](recovery/05_132D_generated_state_recovery_R3.sql)
- `07` — [`07_132E_campaign_hash_recovery_R4.sql`](recovery/07_132E_campaign_hash_recovery_R4.sql)
- `09` — [`09_132F_boundary_assertion_recovery_R5.sql`](recovery/09_132F_boundary_assertion_recovery_R5.sql)
- `10` — [`10_132G_validation_context_recovery_R6.sql`](recovery/10_132G_validation_context_recovery_R6.sql)
- `13` — [`13_132H_pre_acceptance_recovery_R7.sql`](recovery/13_132H_pre_acceptance_recovery_R7.sql)
- `132A` — [`132A_msbf_m2_1_failed_generation_recovery_check_v0_2R7.sql`](recovery/132A_msbf_m2_1_failed_generation_recovery_check_v0_2R7.sql)
- `132C` — [`132C_msbf_m2_1_failed_validation_parenthesis_recovery_check_v0_2R2.sql`](recovery/132C_msbf_m2_1_failed_validation_parenthesis_recovery_check_v0_2R2.sql)
- `134A` — [`134A_msbf_m2_1_generation_reconciliation_reconstructed_v0_2R7.sql`](recovery/134A_msbf_m2_1_generation_reconciliation_reconstructed_v0_2R7.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
