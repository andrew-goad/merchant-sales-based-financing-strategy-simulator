# Source Provenance — M2.1 Eligibility, Policy Gates & Decision Routing

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
20_M2_1
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_132_schema_policy_v0_2.sql` | `49,970` | `a3adf8ad240ea424f49bb601e68b997fadddefbf253d250099197775bf6a5fa1` | `accepted_execution/sql/01_132_schema_policy_v0_2.sql` |
| `02` | RECOVERY | `02_132B_stage_boundary_recovery_R1.sql` | `6,874` | `fa04e8bd9baaf17197dd5f67ff7453abcf46324d013addf794241c7b0672a68c` | `accepted_execution/tests/02_132B_stage_boundary_recovery_R1.sql` |
| `03` | CURRENT_NORMAL | `03_133_preflight_R1.sql` | `7,902` | `280e5e88bd96f06bfb2b701b719b4ca7a4be86c81d100e48d8b95a57b77b40b5` | `accepted_execution/tests/03_133_preflight_R1.sql` |
| `04` | CURRENT_NORMAL | `04_134_generation_R1.sql` | `46,682` | `3812115e493619690e87099f9773c0555d0c3dbaadf6506a0e77590f065249ab` | `accepted_execution/sql/04_134_generation_R1.sql` |
| `05` | RECOVERY | `05_132D_generated_state_recovery_R3.sql` | `8,067` | `b7d65b299591a4d4f2fcf3a401a59112c38bf33c06f43c0e67ca4b527cb5b060` | `accepted_execution/tests/05_132D_generated_state_recovery_R3.sql` |
| `06` | CURRENT_NORMAL | `06_135_validation_R3.sql` | `67,381` | `3bfd73fc5312f61bfc0ad1380cf7dc868bf0458a8e22dc68f6f5922f2caf3646` | `accepted_execution/sql/06_135_validation_R3.sql` |
| `07` | RECOVERY | `07_132E_campaign_hash_recovery_R4.sql` | `31,804` | `864fccd1117f8859db0bbb12220e1452df414293891a860f9dee4dcbd9862d85` | `accepted_execution/tests/07_132E_campaign_hash_recovery_R4.sql` |
| `08` | CURRENT_NORMAL | `08_135_validation_R4.sql` | `67,381` | `97a41a6aa93df3879f70640779bacb99bdc0229a814328dc597458528d98c1f3` | `accepted_execution/sql/08_135_validation_R4.sql` |
| `09` | RECOVERY | `09_132F_boundary_assertion_recovery_R5.sql` | `21,232` | `5d93a0fc4fb1d261ea60ae105aff1fcd320e8838601e327fbf64bcbbbd5b44af` | `accepted_execution/tests/09_132F_boundary_assertion_recovery_R5.sql` |
| `10` | RECOVERY | `10_132G_validation_context_recovery_R6.sql` | `10,081` | `487054e269e725ddffb85ce7711c628e40fb93abac3c48f6c07afa7cd9f6a312` | `accepted_execution/tests/10_132G_validation_context_recovery_R6.sql` |
| `11` | CURRENT_NORMAL | `11_135_final_positive_validation_R6.sql` | `69,570` | `e226e9bc718987f6293deacdcc97d3e8904ef57336335c0f4d12210d18e79d80` | `accepted_execution/sql/11_135_final_positive_validation_R6.sql` |
| `12` | CURRENT_NORMAL | `12_136_final_negative_controls_R6.sql` | `17,518` | `20f214f0cb92ac05a22cfd0a91c0b95dea0970f014f9659b9f84ec9a3656dd1a` | `accepted_execution/sql/12_136_final_negative_controls_R6.sql` |
| `13` | RECOVERY | `13_132H_pre_acceptance_recovery_R7.sql` | `11,342` | `4473f3ddd9db32feb9cce0cea8f138df106ad119b6ac36c060bc4d4e0c432a61` | `accepted_execution/tests/13_132H_pre_acceptance_recovery_R7.sql` |
| `14` | CURRENT_NORMAL | `14_137_acceptance_finalize_R7.sql` | `12,740` | `12aa63168a757933672c10f6e997e1bb0812ee4c40adeaf8e02b91f9c6f50927` | `accepted_execution/sql/14_137_acceptance_finalize_R7.sql` |
| `15` | REPORTING | `15_138_master_report_R7.sql` | `3,582` | `0fd3532ee323bef4bdef33f75e88142f0d847c96ccaf14c78fc272d080411175` | `accepted_execution/tests/15_138_master_report_R7.sql` |
| `16` | REPORTING | `16_139_detail_report_R7.sql` | `13,807` | `c1e906ce311eced1f4d6a5d44a82e803b0b04782f5b63eb918aee559e6c1d938` | `accepted_execution/tests/16_139_detail_report_R7.sql` |
| `132` | CURRENT_NORMAL | `132_msbf_m2_1_schema_policy_extension_v0_2R7.sql` | `53,025` | `02ef9fe47a252aa8bce6b2eb587914ba329a752815d6b4d5b9724846f41e6f1b` | `sql/132_msbf_m2_1_schema_policy_extension_v0_2R7.sql` |
| `132A` | RECOVERY | `132A_msbf_m2_1_failed_generation_recovery_check_v0_2R7.sql` | `3,175` | `984e52f8381507129f4383f373cb89c32e1198a76a6d8bdda65aba0154acb183` | `tests/132A_msbf_m2_1_failed_generation_recovery_check_v0_2R7.sql` |
| `132C` | RECOVERY | `132C_msbf_m2_1_failed_validation_parenthesis_recovery_check_v0_2R2.sql` | `7,311` | `fef980e07e345d480b21e4fa6b6f29d261f2cd2c6af01fcbe9c35a0638b297db` | `source_history/R2_superseded_validation_repair/132C_msbf_m2_1_failed_validation_parenthesis_recovery_check_v0_2R2.sql` |
| `133` | CURRENT_NORMAL | `133_msbf_m2_1_preflight_validation_v0_2R7.sql` | `7,902` | `35fd290f935432abf901925bc8fe720d41d45728287644152e847a5e6969f806` | `tests/133_msbf_m2_1_preflight_validation_v0_2R7.sql` |
| `134` | CURRENT_NORMAL | `134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R7.sql` | `46,682` | `2725a6bf2244104e565d87df8943ea796ff2793cf65cbad1a1ed053f03a4930a` | `sql/134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R7.sql` |
| `134A` | RECOVERY | `134A_msbf_m2_1_generation_reconciliation_reconstructed_v0_2R7.sql` | `4,047` | `3515b9567dde455e18fba4b99a77d4e50d6d3fc447c21f7595beb7acdd4b35b1` | `tests/134A_msbf_m2_1_generation_reconciliation_reconstructed_v0_2R7.sql` |
| `135` | CURRENT_NORMAL | `135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R7.sql` | `69,570` | `c81e0cb94f39c3fc3af775f6182044fcee1a9cd40f82fa38c6ea1a57ce344429` | `sql/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R7.sql` |
| `136` | CURRENT_NORMAL | `136_msbf_m2_1_negative_control_tests_v0_2R7.sql` | `17,518` | `c5567f88f9183d6cafe802b2c4164b9c2ca0b123840cff154f6e8ef9fe904352` | `sql/136_msbf_m2_1_negative_control_tests_v0_2R7.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
