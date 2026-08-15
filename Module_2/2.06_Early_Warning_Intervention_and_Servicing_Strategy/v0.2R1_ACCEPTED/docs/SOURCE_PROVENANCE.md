# Source Provenance — M2.6 Early Warning, Intervention & Servicing Strategy

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
25_M2_6
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_172_schema_policy.sql` | `54,692` | `e90525e58f089cc84f9a518d61216e16bf96aba76cb09581f8ce7d363a36cf83` | `accepted_execution/sql/01_172_schema_policy.sql` |
| `02` | CURRENT_NORMAL | `02_173_preflight.sql` | `10,667` | `6f2f4f9dff66ad5da183cc88e4400a823967305153fde142ae5124d968a612b5` | `accepted_execution/tests/02_173_preflight.sql` |
| `03` | CURRENT_NORMAL | `03_174_generation.sql` | `38,123` | `967ba6d8d12485c2dd887807a41c9ddebb029575c4f4162f10009fbfed4f1c29` | `accepted_execution/sql/03_174_generation.sql` |
| `04` | CURRENT_NORMAL | `04_175_positive_validation.sql` | `71,822` | `089fcab6962f3bda4d5e2029546ab7d5e8d1abc8f565574d625f72c1fce2e739` | `accepted_execution/sql/04_175_positive_validation.sql` |
| `05` | CURRENT_NORMAL | `05_176_negative_controls.sql` | `13,901` | `c28fb91dddc0788a6f79190abe3fe96bb88d3b51dae1bb3b24e03afb03148428` | `accepted_execution/sql/05_176_negative_controls.sql` |
| `06` | CURRENT_NORMAL | `06_177_acceptance_finalize.sql` | `9,060` | `793f869122cc187d28e1c066c0125fa5980ac086846ae12c12be09104d072d3e` | `accepted_execution/sql/06_177_acceptance_finalize.sql` |
| `07` | REPORTING | `07_178_master_report_v0_2R1.sql` | `11,439` | `07df5d1b0a0031849764178787aa520153712535624355706875d04e5be4bbeb` | `accepted_execution/tests/07_178_master_report_v0_2R1.sql` |
| `08` | REPORTING | `08_179_detail_report.sql` | `11,208` | `53982a04b7fdc90ae5b235ae1b5cce6cd80d127e7230275e4376609b75c43f29` | `accepted_execution/tests/08_179_detail_report.sql` |
| `172A` | RECOVERY | `172A_msbf_m2_6_failed_schema_policy_recovery_check_v0_2.sql` | `388` | `73bd70af3c7e81c8dabbd312c9e909e0259e55e0136a174fd6474e53afab4cd0` | `tests/172A_msbf_m2_6_failed_schema_policy_recovery_check_v0_2.sql` |
| `174A` | RECOVERY | `174A_msbf_m2_6_failed_generation_recovery_check_v0_2.sql` | `714` | `3d9377a35a79e7c0041d1ddcdfd2f44e02becd67d790e6f8915facc3a396f965` | `tests/174A_msbf_m2_6_failed_generation_recovery_check_v0_2.sql` |
| `174B` | RECOVERY | `174B_msbf_m2_6_generation_reconciliation_reconstructed_v0_2.sql` | `649` | `0a766a7ac73de2efa6e5e076ec0a510c2ba7895642868b6c589428729b9c3717` | `tests/174B_msbf_m2_6_generation_reconciliation_reconstructed_v0_2.sql` |
| `178A` | RECOVERY | `178A_msbf_m2_6_failed_master_report_boundary_source_recovery_v0_2R1.sql` | `8,670` | `0272759ad9262d7dafde1dfa561ff89f186c0dfdbf5a48ebcda210fb71cac1a6` | `tests/178A_msbf_m2_6_failed_master_report_boundary_source_recovery_v0_2R1.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
