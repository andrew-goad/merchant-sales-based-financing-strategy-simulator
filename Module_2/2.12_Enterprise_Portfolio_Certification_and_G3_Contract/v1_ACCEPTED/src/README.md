# Source Classification — M2.12

## Current normal chain

- `220` — [`220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql`](current/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql)
- `221` — [`221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql`](current/221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql)
- `222` — [`222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql`](current/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql)
- `223` — [`223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql`](current/223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql)
- `224` — [`224_msbf_m2_12_negative_controls_20_isolated_v1_HF14.sql`](current/224_msbf_m2_12_negative_controls_20_isolated_v1_HF14.sql)
- `225` — [`225_msbf_m2_12_acceptance_finalizer_v1_HF23.sql`](current/225_msbf_m2_12_acceptance_finalizer_v1_HF23.sql)
- `226` — [`226_HF24_pre_execution_accepted_checkpoint_verification.sql`](current/226_HF24_pre_execution_accepted_checkpoint_verification.sql)
- `227` — [`227_HF27_pre_execution_application_summary_diagnostic.sql`](current/227_HF27_pre_execution_application_summary_diagnostic.sql)

## Reporting

- No separately classified reporting SQL.

## Recovery boundary

- `220A` — [`220A_msbf_m2_12_failed_schema_policy_installation_recovery_v1.sql`](recovery/220A_msbf_m2_12_failed_schema_policy_installation_recovery_v1.sql)
- `222A` — [`222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql`](recovery/222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql)
- `222B` — [`222B_msbf_m2_12_committed_certification_checkpoint_reconstruction_v1.sql`](recovery/222B_msbf_m2_12_committed_certification_checkpoint_reconstruction_v1.sql)
- `223A` — [`223A_msbf_m2_12_failed_positive_validation_recovery_v1.sql`](recovery/223A_msbf_m2_12_failed_positive_validation_recovery_v1.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
