# Source Provenance — M2.10 Portfolio Performance, KPI & Servicing Analytics

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
29_M2_10
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_204_schema_policy_executed_v0_2.sql` | `64,568` | `f3fa214ee8a2364301afba1c8dcaf2d4448da8d20c139d465afc43e526c70204` | `accepted_execution/sql/01_204_schema_policy_executed_v0_2.sql` |
| `02` | CURRENT_NORMAL | `02_205_preflight_v0_2R1.sql` | `17,829` | `fb5e92c3f79a71cf490f06dd966021a172fde156195bb4b275ef319875702b49` | `accepted_execution/tests/02_205_preflight_v0_2R1.sql` |
| `02A` | RECOVERY | `02A_205A_active_reconciled_diagnostic.sql` | `4,956` | `c098ba5f23dad265441ffd97ddcf8d0c533bbd9cb99f4f4055f16f3abc906be9` | `accepted_execution/recovery/02A_205A_active_reconciled_diagnostic.sql` |
| `03` | CURRENT_NORMAL | `03_206_generation_v0_2R1.sql` | `77,930` | `b368a2f2a7cbaa8594419568a495fd631b3d255fc4aea8426326c5c3feb43513` | `accepted_execution/sql/03_206_generation_v0_2R1.sql` |
| `04` | CURRENT_NORMAL | `04_207_positive_validation_v0_2R3.sql` | `130,555` | `691fe4b6e17fe1186f8a7f36bae2f2314357b615f884ccdd0fa9ae2f009c79a2` | `accepted_execution/sql/04_207_positive_validation_v0_2R3.sql` |
| `04A` | RECOVERY | `04A_207A_positive_validation_recovery.sql` | `12,314` | `c41c37f0bf221115a881c142c642e8fd11c902a8f7bd3c5ef1e116047012fd70` | `accepted_execution/recovery/04A_207A_positive_validation_recovery.sql` |
| `04B` | RECOVERY | `04B_207B_definition_hash_diagnostic.sql` | `5,567` | `6de090ca0216850eada7da31123ee7d1d530422904dec5c67d5428136920a895` | `accepted_execution/recovery/04B_207B_definition_hash_diagnostic.sql` |
| `04C` | RECOVERY | `04C_207C_definition_hash_repair.sql` | `20,688` | `654c4fbf0d1c7d65b364a46cdc0d31c92336b4b6289459958a73e37dbbf62fc5` | `accepted_execution/sql/04C_207C_definition_hash_repair.sql` |
| `05` | CURRENT_NORMAL | `05_208_negative_controls_v0_2R2.sql` | `26,279` | `7da3968bcb310d05ba838605edaac12f7c00f3b646a070d8bf0f8d5dc4765c9f` | `accepted_execution/sql/05_208_negative_controls_v0_2R2.sql` |
| `05A` | RECOVERY | `05A_208A_negative_control_diagnostic.sql` | `7,604` | `2a88531e595c61b1e53b2ef556a1b6f1017a2e06e95e9f6d1435580243d87a9a` | `accepted_execution/recovery/05A_208A_negative_control_diagnostic.sql` |
| `05B` | RECOVERY | `05B_208B_kpi_applicability_repair.sql` | `9,641` | `d4f2b33f257ba978bc8a973bd0b3a645c86824125a3b9c3c2946cb03205b8121` | `accepted_execution/sql/05B_208B_kpi_applicability_repair.sql` |
| `06` | CURRENT_NORMAL | `06_209_acceptance_finalize_v0_2R1.sql` | `25,667` | `ed9de6c5c1355c6ca80935209f804106fcd2aee4d365502b6e00b598de67c45d` | `accepted_execution/sql/06_209_acceptance_finalize_v0_2R1.sql` |
| `07` | REPORTING | `07_210_master_report_v0_2R1.sql` | `22,061` | `0afe26438431e2ea4d0d404d9d47ad855c70dc61a10035a4b838f3c86b477589` | `accepted_execution/tests/07_210_master_report_v0_2R1.sql` |
| `08` | REPORTING | `08_211_detail_report_v0_2R1.sql` | `32,408` | `76481215bc9debc65a86034fd2ada1de6b17218f1bea92c5815a14a5c9f97d27` | `accepted_execution/tests/08_211_detail_report_v0_2R1.sql` |
| `204` | CURRENT_NORMAL | `204_msbf_m2_10_schema_policy_portfolio_analytics_extension_v0_2R2.sql` | `65,847` | `f67724035b5b3a280644774f7ec77a0e88536caebdaac7433314bbadca4aa3dd` | `sql/204_msbf_m2_10_schema_policy_portfolio_analytics_extension_v0_2R2.sql` |
| `204A` | RECOVERY | `204A_msbf_m2_10_failed_schema_policy_recovery_check_v0_2.sql` | `4,403` | `a920c1ce48ca2dd989b11a21e95c02e22f2ff2880c1d22e6c5feb308b350332d` | `tests/204A_msbf_m2_10_failed_schema_policy_recovery_check_v0_2.sql` |
| `206A` | RECOVERY | `206A_msbf_m2_10_failed_generation_recovery_check_v0_2R1.sql` | `8,780` | `9295ecbb73bc67a325f266bc4004710cf81e6a6bada24a64992c2fb4befc3453` | `tests/206A_msbf_m2_10_failed_generation_recovery_check_v0_2R1.sql` |
| `206B` | RECOVERY | `206B_msbf_m2_10_generation_reconciliation_reconstructed_v0_2R1.sql` | `15,714` | `2f3e1144858a4426ddd03c63f3d9dd76b842aecc42871af2e4171a99bbd2fb9b` | `tests/206B_msbf_m2_10_generation_reconciliation_reconstructed_v0_2R1.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
