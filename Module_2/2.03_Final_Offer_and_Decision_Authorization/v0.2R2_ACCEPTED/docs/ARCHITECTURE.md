# Architecture — M2.3 Final Offer & Decision Authorization

## Position in the accepted chain

```text
M2.2 accepted stage
    ↓
M2.3 — Final Offer & Decision Authorization
    ↓
M2.4 accepted stage
```

## Capability layers

- Final-offer selection
- Authorization controls
- Decision outcome and rationale
- Alternative and exception evidence preservation

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_148_schema_policy_R1.sql`](../src/current/01_148_schema_policy_R1.sql) | `4f402ea36bf62c302e1abc016c36b78e6ccd30eef13cead8c8d6eba8fb2450be` |
| `02` | RECOVERY | [`02_148B_policy_hash_schema_recovery_R1.sql`](../src/recovery/02_148B_policy_hash_schema_recovery_R1.sql) | `3689c98c7df02b1451685942e9b62b3b4c8b7166f99835c60ac4f8396d9aff18` |
| `03` | CURRENT_NORMAL | [`03_149_preflight_R1.sql`](../src/current/03_149_preflight_R1.sql) | `9909841c1dd694b4e0cfe56bd305027d3d5a30da69d87689bf3daceda8fafc24` |
| `04` | CURRENT_NORMAL | [`04_150_generation_R1.sql`](../src/current/04_150_generation_R1.sql) | `a6668e470478e06fbc8e5130737bfd13ca9a0408df5daff4f20d114bd5852041` |
| `05` | CURRENT_NORMAL | [`05_151_positive_validation_R1.sql`](../src/current/05_151_positive_validation_R1.sql) | `c732a204c06f839b80c9999a7bebfe22be53ffbe9deaa7b284c67a85b68e4ede` |
| `06` | RECOVERY | [`06_148C_external_notice_payload_recovery_R2.sql`](../src/recovery/06_148C_external_notice_payload_recovery_R2.sql) | `ba541981734ef4991985474a4646d88b306ce97e855e0399d7be51d28fc0b177` |
| `07` | CURRENT_NORMAL | [`07_152_negative_controls_R2.sql`](../src/current/07_152_negative_controls_R2.sql) | `d1ce1785f9bf536473429b66634c76baf15e494d67aa95cee90779edd85250d8` |
| `08` | CURRENT_NORMAL | [`08_153_acceptance_finalize_R2.sql`](../src/current/08_153_acceptance_finalize_R2.sql) | `8b5087924380bf8f315ccba6fc7a8b6415d9c16bb5aa2e0ad53273b3f3b2555f` |
| `09` | REPORTING | [`09_154_master_report_R2.sql`](../src/reporting/09_154_master_report_R2.sql) | `b08a2dedeae752a99f6f51766268bc53ca2d37859f799c04c6a8c31124b66674` |
| `10` | REPORTING | [`10_155_detail_report_R2.sql`](../src/reporting/10_155_detail_report_R2.sql) | `b5e35c53c9182600a1789d7b8dc28fcbe365567cb69af13af22fbc23f65051c8` |
| `148` | CURRENT_NORMAL | [`148_msbf_m2_3_schema_policy_decision_contract_extension_v0_2R2.sql`](../src/current/148_msbf_m2_3_schema_policy_decision_contract_extension_v0_2R2.sql) | `d637ffbe76dde7307b198ee902e383f37b26fbe70e30f329f1d06c1e01bd895a` |
| `148A` | RECOVERY | [`148A_msbf_m2_3_failed_generation_recovery_check_v0_2R2.sql`](../src/recovery/148A_msbf_m2_3_failed_generation_recovery_check_v0_2R2.sql) | `1e845eaaf5510d6109d908374b214abb7c690e2d299c58b3a5326ccd3e894467` |
| `149` | CURRENT_NORMAL | [`149_msbf_m2_3_preflight_validation_v0_2R2.sql`](../src/current/149_msbf_m2_3_preflight_validation_v0_2R2.sql) | `451db1ffd6b2f232bee5545727abba934db07e1c6613a6dedab2bb69a52394e1` |
| `150` | CURRENT_NORMAL | [`150_msbf_m2_3_final_offer_decision_generation_v0_2R2.sql`](../src/current/150_msbf_m2_3_final_offer_decision_generation_v0_2R2.sql) | `685a3173abc7fd0ace801d7c4523ec18b95837937b1923fccd9dfa0b6c782efb` |
| `150A` | RECOVERY | [`150A_msbf_m2_3_generation_reconciliation_reconstructed_v0_2R2.sql`](../src/recovery/150A_msbf_m2_3_generation_reconciliation_reconstructed_v0_2R2.sql) | `86b1d01b24841d3246eb0626a2af569189ffb6f21a17f43f897710e1b2859abf` |
| `151` | CURRENT_NORMAL | [`151_msbf_m2_3_final_offer_decision_validation_v0_2R2.sql`](../src/current/151_msbf_m2_3_final_offer_decision_validation_v0_2R2.sql) | `9eb2f42eacbc50b92fcfa8389b8f831d5f2aa509461757da2282d62a5bf018e5` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
