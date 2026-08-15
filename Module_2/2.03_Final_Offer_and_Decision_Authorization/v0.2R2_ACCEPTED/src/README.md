# Source Classification — M2.3

## Current normal chain

- `01` — [`01_148_schema_policy_R1.sql`](current/01_148_schema_policy_R1.sql)
- `03` — [`03_149_preflight_R1.sql`](current/03_149_preflight_R1.sql)
- `04` — [`04_150_generation_R1.sql`](current/04_150_generation_R1.sql)
- `05` — [`05_151_positive_validation_R1.sql`](current/05_151_positive_validation_R1.sql)
- `07` — [`07_152_negative_controls_R2.sql`](current/07_152_negative_controls_R2.sql)
- `08` — [`08_153_acceptance_finalize_R2.sql`](current/08_153_acceptance_finalize_R2.sql)
- `148` — [`148_msbf_m2_3_schema_policy_decision_contract_extension_v0_2R2.sql`](current/148_msbf_m2_3_schema_policy_decision_contract_extension_v0_2R2.sql)
- `149` — [`149_msbf_m2_3_preflight_validation_v0_2R2.sql`](current/149_msbf_m2_3_preflight_validation_v0_2R2.sql)
- `150` — [`150_msbf_m2_3_final_offer_decision_generation_v0_2R2.sql`](current/150_msbf_m2_3_final_offer_decision_generation_v0_2R2.sql)
- `151` — [`151_msbf_m2_3_final_offer_decision_validation_v0_2R2.sql`](current/151_msbf_m2_3_final_offer_decision_validation_v0_2R2.sql)

## Reporting

- `09` — [`09_154_master_report_R2.sql`](reporting/09_154_master_report_R2.sql)
- `10` — [`10_155_detail_report_R2.sql`](reporting/10_155_detail_report_R2.sql)

## Recovery boundary

- `02` — [`02_148B_policy_hash_schema_recovery_R1.sql`](recovery/02_148B_policy_hash_schema_recovery_R1.sql)
- `06` — [`06_148C_external_notice_payload_recovery_R2.sql`](recovery/06_148C_external_notice_payload_recovery_R2.sql)
- `148A` — [`148A_msbf_m2_3_failed_generation_recovery_check_v0_2R2.sql`](recovery/148A_msbf_m2_3_failed_generation_recovery_check_v0_2R2.sql)
- `150A` — [`150A_msbf_m2_3_generation_reconciliation_reconstructed_v0_2R2.sql`](recovery/150A_msbf_m2_3_generation_reconciliation_reconstructed_v0_2R2.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
