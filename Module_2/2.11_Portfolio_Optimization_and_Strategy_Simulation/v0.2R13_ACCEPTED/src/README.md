# Source Classification — M2.11

## Current normal chain

- `212` — [`212_msbf_m2_11_schema_policy_definitions_contracts_triggers_views_v1.sql`](current/212_msbf_m2_11_schema_policy_definitions_contracts_triggers_views_v1.sql)
- `213` — [`213_msbf_m2_11_accepted_source_pristine_target_preflight_v1.sql`](current/213_msbf_m2_11_accepted_source_pristine_target_preflight_v1.sql)
- `214` — [`214_msbf_m2_11_deterministic_strategy_simulation_reconciliation_v1.sql`](current/214_msbf_m2_11_deterministic_strategy_simulation_reconciliation_v1.sql)
- `215` — [`215_msbf_m2_11_positive_validation_v1.sql`](current/215_msbf_m2_11_positive_validation_v1.sql)
- `216` — [`216_msbf_m2_11_negative_controls_v1.sql`](current/216_msbf_m2_11_negative_controls_v1.sql)
- `217` — [`217_msbf_m2_11_acceptance_finalizer_v1.sql`](current/217_msbf_m2_11_acceptance_finalizer_v1.sql)

## Reporting

- `218` — [`218_msbf_m2_11_master_report_v1.sql`](reporting/218_msbf_m2_11_master_report_v1.sql)
- `219` — [`219_msbf_m2_11_detailed_report_v1.sql`](reporting/219_msbf_m2_11_detailed_report_v1.sql)
- `M2_11_218_MASTER_REPORT_EXPORT_QUERY` — [`M2_11_218_MASTER_REPORT_EXPORT_QUERY.sql`](reporting/M2_11_218_MASTER_REPORT_EXPORT_QUERY.sql)
- `M2_11_219_DETAIL_REPORT_EXPORT_QUERIES` — [`M2_11_219_DETAIL_REPORT_EXPORT_QUERIES.sql`](reporting/M2_11_219_DETAIL_REPORT_EXPORT_QUERIES.sql)
- `M2_11_POST_CHAIN_EVIDENCE_EXPORT_QUERIES` — [`M2_11_POST_CHAIN_EVIDENCE_EXPORT_QUERIES.sql`](reporting/M2_11_POST_CHAIN_EVIDENCE_EXPORT_QUERIES.sql)

## Recovery boundary

- `212A` — [`212A_msbf_m2_11_failed_schema_policy_installation_recovery_v1.sql`](recovery/212A_msbf_m2_11_failed_schema_policy_installation_recovery_v1.sql)
- `214A` — [`214A_msbf_m2_11_failed_precommit_generation_rollback_recovery_v1.sql`](recovery/214A_msbf_m2_11_failed_precommit_generation_rollback_recovery_v1.sql)
- `214B` — [`214B_msbf_m2_11_committed_generation_checkpoint_reconstruction_v1.sql`](recovery/214B_msbf_m2_11_committed_generation_checkpoint_reconstruction_v1.sql)
- `215A` — [`215A_msbf_m2_11_failed_positive_validation_recovery_v1.sql`](recovery/215A_msbf_m2_11_failed_positive_validation_recovery_v1.sql)

Recovery source is contingency-only. It may execute only under its exact governed precondition and never replaces the normal chain.
