# Source Provenance — M2.3 Final Offer & Decision Authorization

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
22_M2_3
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_148_schema_policy_R1.sql` | `51,489` | `4f402ea36bf62c302e1abc016c36b78e6ccd30eef13cead8c8d6eba8fb2450be` | `accepted_execution/sql/01_148_schema_policy_R1.sql` |
| `02` | RECOVERY | `02_148B_policy_hash_schema_recovery_R1.sql` | `5,944` | `3689c98c7df02b1451685942e9b62b3b4c8b7166f99835c60ac4f8396d9aff18` | `accepted_execution/tests/02_148B_policy_hash_schema_recovery_R1.sql` |
| `03` | CURRENT_NORMAL | `03_149_preflight_R1.sql` | `11,414` | `9909841c1dd694b4e0cfe56bd305027d3d5a30da69d87689bf3daceda8fafc24` | `accepted_execution/tests/03_149_preflight_R1.sql` |
| `04` | CURRENT_NORMAL | `04_150_generation_R1.sql` | `54,815` | `a6668e470478e06fbc8e5130737bfd13ca9a0408df5daff4f20d114bd5852041` | `accepted_execution/sql/04_150_generation_R1.sql` |
| `05` | CURRENT_NORMAL | `05_151_positive_validation_R1.sql` | `86,777` | `c732a204c06f839b80c9999a7bebfe22be53ffbe9deaa7b284c67a85b68e4ede` | `accepted_execution/sql/05_151_positive_validation_R1.sql` |
| `06` | RECOVERY | `06_148C_external_notice_payload_recovery_R2.sql` | `15,210` | `ba541981734ef4991985474a4646d88b306ce97e855e0399d7be51d28fc0b177` | `accepted_execution/tests/06_148C_external_notice_payload_recovery_R2.sql` |
| `07` | CURRENT_NORMAL | `07_152_negative_controls_R2.sql` | `18,085` | `d1ce1785f9bf536473429b66634c76baf15e494d67aa95cee90779edd85250d8` | `accepted_execution/sql/07_152_negative_controls_R2.sql` |
| `08` | CURRENT_NORMAL | `08_153_acceptance_finalize_R2.sql` | `14,907` | `8b5087924380bf8f315ccba6fc7a8b6415d9c16bb5aa2e0ad53273b3f3b2555f` | `accepted_execution/sql/08_153_acceptance_finalize_R2.sql` |
| `09` | REPORTING | `09_154_master_report_R2.sql` | `6,447` | `b08a2dedeae752a99f6f51766268bc53ca2d37859f799c04c6a8c31124b66674` | `accepted_execution/tests/09_154_master_report_R2.sql` |
| `10` | REPORTING | `10_155_detail_report_R2.sql` | `15,501` | `b5e35c53c9182600a1789d7b8dc28fcbe365567cb69af13af22fbc23f65051c8` | `accepted_execution/tests/10_155_detail_report_R2.sql` |
| `148` | CURRENT_NORMAL | `148_msbf_m2_3_schema_policy_decision_contract_extension_v0_2R2.sql` | `52,106` | `d637ffbe76dde7307b198ee902e383f37b26fbe70e30f329f1d06c1e01bd895a` | `sql/148_msbf_m2_3_schema_policy_decision_contract_extension_v0_2R2.sql` |
| `148A` | RECOVERY | `148A_msbf_m2_3_failed_generation_recovery_check_v0_2R2.sql` | `2,779` | `1e845eaaf5510d6109d908374b214abb7c690e2d299c58b3a5326ccd3e894467` | `tests/148A_msbf_m2_3_failed_generation_recovery_check_v0_2R2.sql` |
| `149` | CURRENT_NORMAL | `149_msbf_m2_3_preflight_validation_v0_2R2.sql` | `11,414` | `451db1ffd6b2f232bee5545727abba934db07e1c6613a6dedab2bb69a52394e1` | `tests/149_msbf_m2_3_preflight_validation_v0_2R2.sql` |
| `150` | CURRENT_NORMAL | `150_msbf_m2_3_final_offer_decision_generation_v0_2R2.sql` | `54,815` | `685a3173abc7fd0ace801d7c4523ec18b95837937b1923fccd9dfa0b6c782efb` | `sql/150_msbf_m2_3_final_offer_decision_generation_v0_2R2.sql` |
| `150A` | RECOVERY | `150A_msbf_m2_3_generation_reconciliation_reconstructed_v0_2R2.sql` | `2,899` | `86b1d01b24841d3246eb0626a2af569189ffb6f21a17f43f897710e1b2859abf` | `tests/150A_msbf_m2_3_generation_reconciliation_reconstructed_v0_2R2.sql` |
| `151` | CURRENT_NORMAL | `151_msbf_m2_3_final_offer_decision_validation_v0_2R2.sql` | `86,777` | `9eb2f42eacbc50b92fcfa8389b8f831d5f2aa509461757da2282d62a5bf018e5` | `sql/151_msbf_m2_3_final_offer_decision_validation_v0_2R2.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
