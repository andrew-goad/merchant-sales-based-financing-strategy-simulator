# Architecture — M2.12 Enterprise Portfolio Certification & G3 Contract

## Position in the accepted chain

```text
M2.11 accepted stage
    ↓
M2.12 — Enterprise Portfolio Certification & G3 Contract
    ↓
Campaign-scale certification and future M3 planning
```

## Capability layers

- Twelve-stage and thirteen-component certification
- Source-edge and contract reproduction
- Capability coverage and canonical identity
- G3 latest/archive/registry and enterprise consumption views
- Independent validation, acceptance, and reporting

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `220` | CURRENT_NORMAL | [`220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql`](../src/current/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql) | `efc49c1f2c02587e03a84b46ab8c5c0b097ca28cd2682cd6f4eb477e29f508e8` |
| `220A` | RECOVERY | [`220A_msbf_m2_12_failed_schema_policy_installation_recovery_v1.sql`](../src/recovery/220A_msbf_m2_12_failed_schema_policy_installation_recovery_v1.sql) | `7510697598eb033e95d4d0fb3ff540c41dd0df810577312949b8ef57f1076d93` |
| `221` | CURRENT_NORMAL | [`221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql`](../src/current/221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql) | `97387aca692d676b74c89ab298e4e284bd862feaf289f98eba5fd91c336877d7` |
| `222` | CURRENT_NORMAL | [`222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql`](../src/current/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql) | `3674c53f4bc46222a45db8d3afa75337af921b2492485ebd2745d77ada220cab` |
| `222A` | RECOVERY | [`222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql`](../src/recovery/222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql) | `8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627` |
| `222B` | RECOVERY | [`222B_msbf_m2_12_committed_certification_checkpoint_reconstruction_v1.sql`](../src/recovery/222B_msbf_m2_12_committed_certification_checkpoint_reconstruction_v1.sql) | `056f277eb07ef2144cb06e6afdd0158ea5ad07b96ecc56f0e34813852c1c790a` |
| `223` | CURRENT_NORMAL | [`223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql`](../src/current/223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql) | `a52a2ea1fe423fae840c21a3bba6dda7ca45dea1c29531134e823a96635411fe` |
| `223A` | RECOVERY | [`223A_msbf_m2_12_failed_positive_validation_recovery_v1.sql`](../src/recovery/223A_msbf_m2_12_failed_positive_validation_recovery_v1.sql) | `0e65e3534440414f598a360e7fb67f1b299a4c4bc9883c80c686510af4ff6969` |
| `224` | CURRENT_NORMAL | [`224_msbf_m2_12_negative_controls_20_isolated_v1_HF14.sql`](../src/current/224_msbf_m2_12_negative_controls_20_isolated_v1_HF14.sql) | `d549f90da4ec3d9364d4f1e5bd1b8fc8a9e5e65d1c3d6af646bf48689ee9146e` |
| `225` | CURRENT_NORMAL | [`225_msbf_m2_12_acceptance_finalizer_v1_HF23.sql`](../src/current/225_msbf_m2_12_acceptance_finalizer_v1_HF23.sql) | `e5ac10c9c15512878361d080a4435fa70eac68004f8dfbabeeddaa052d51055b` |
| `226` | CURRENT_NORMAL | [`226_HF24_pre_execution_accepted_checkpoint_verification.sql`](../src/current/226_HF24_pre_execution_accepted_checkpoint_verification.sql) | `1600bff055b51b491105652d829415fbf65e03ab82ff0ff4b715e165b9f0d3c8` |
| `227` | CURRENT_NORMAL | [`227_HF27_pre_execution_application_summary_diagnostic.sql`](../src/current/227_HF27_pre_execution_application_summary_diagnostic.sql) | `08089fc3a8c8a5f21d9bed9fcf12faffcde106828d6551f9961232aba79487c8` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
