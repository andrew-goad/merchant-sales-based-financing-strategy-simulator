# Source Provenance — M2.12 Enterprise Portfolio Certification & G3 Contract

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
31_M2_12
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `220` | CURRENT_NORMAL | `220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql` | `765,772` | `efc49c1f2c02587e03a84b46ab8c5c0b097ca28cd2682cd6f4eb477e29f508e8` | `07_source_authority/220_HF4/220_msbf_m2_12_schema_policy_certification_structures_g3_bundle_triggers_views_v1_HF4.sql` |
| `220A` | RECOVERY | `220A_msbf_m2_12_failed_schema_policy_installation_recovery_v1.sql` | `21,491` | `7510697598eb033e95d4d0fb3ff540c41dd0df810577312949b8ef57f1076d93` | `02_sql_recovery_contingency_only/220A_msbf_m2_12_failed_schema_policy_installation_recovery_v1.sql` |
| `221` | CURRENT_NORMAL | `221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql` | `221,276` | `97387aca692d676b74c89ab298e4e284bd862feaf289f98eba5fd91c336877d7` | `07_source_authority/221_HF6/221_msbf_m2_12_accepted_source_pristine_target_preflight_v1_HF6.sql` |
| `222` | CURRENT_NORMAL | `222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql` | `560,495` | `3674c53f4bc46222a45db8d3afa75337af921b2492485ebd2745d77ada220cab` | `07_source_authority/222_HF9/222_msbf_m2_12_end_to_end_certification_generation_physical_reconciliation_v1_HF9.sql` |
| `222A` | RECOVERY | `222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql` | `22,425` | `8087d51cd6d1dbcf89371d4219e787b53221ddf3a5959053af1306fef0967627` | `07_source_authority/222A_R1/222A_msbf_m2_12_failed_precommit_certification_generation_sequence_state_recovery_v1.sql` |
| `222B` | RECOVERY | `222B_msbf_m2_12_committed_certification_checkpoint_reconstruction_v1.sql` | `118,484` | `056f277eb07ef2144cb06e6afdd0158ea5ad07b96ecc56f0e34813852c1c790a` | `02_sql_recovery_contingency_only/222B_msbf_m2_12_committed_certification_checkpoint_reconstruction_v1.sql` |
| `223` | CURRENT_NORMAL | `223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql` | `769,374` | `a52a2ea1fe423fae840c21a3bba6dda7ca45dea1c29531134e823a96635411fe` | `07_source_authority/223_HF12/223_msbf_m2_12_positive_validation_128_controls_v1_HF12.sql` |
| `223A` | RECOVERY | `223A_msbf_m2_12_failed_positive_validation_recovery_v1.sql` | `60,158` | `0e65e3534440414f598a360e7fb67f1b299a4c4bc9883c80c686510af4ff6969` | `02_sql_recovery_contingency_only/223A_msbf_m2_12_failed_positive_validation_recovery_v1.sql` |
| `224` | CURRENT_NORMAL | `224_msbf_m2_12_negative_controls_20_isolated_v1_HF14.sql` | `153,481` | `d549f90da4ec3d9364d4f1e5bd1b8fc8a9e5e65d1c3d6af646bf48689ee9146e` | `07_source_authority/224_HF14/224_msbf_m2_12_negative_controls_20_isolated_v1_HF14.sql` |
| `225` | CURRENT_NORMAL | `225_msbf_m2_12_acceptance_finalizer_v1_HF23.sql` | `246,122` | `e5ac10c9c15512878361d080a4435fa70eac68004f8dfbabeeddaa052d51055b` | `07_source_authority/225_HF23/225_msbf_m2_12_acceptance_finalizer_v1_HF23.sql` |
| `226` | CURRENT_NORMAL | `226_HF24_pre_execution_accepted_checkpoint_verification.sql` | `161,148` | `1600bff055b51b491105652d829415fbf65e03ab82ff0ff4b715e165b9f0d3c8` | `07_source_authority/226_AUXILIARY/226_HF24_pre_execution_accepted_checkpoint_verification.sql` |
| `227` | CURRENT_NORMAL | `227_HF27_pre_execution_application_summary_diagnostic.sql` | `8,952` | `08089fc3a8c8a5f21d9bed9fcf12faffcde106828d6551f9961232aba79487c8` | `07_source_authority/227_AUXILIARY/227_HF27_pre_execution_application_summary_diagnostic.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
