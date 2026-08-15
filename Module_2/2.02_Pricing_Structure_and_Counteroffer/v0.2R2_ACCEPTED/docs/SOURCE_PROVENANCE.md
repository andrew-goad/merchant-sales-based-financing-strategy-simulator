# Source Provenance — M2.2 Pricing, Structure & Counteroffer

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
21_M2_2
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_140_schema_policy_v0_2.sql` | `48,700` | `c33652356dd8ece52822117b9536a57eef61673c04c17e61fb62685042833cb1` | `accepted_execution/sql/01_140_schema_policy_v0_2.sql` |
| `02` | CURRENT_NORMAL | `02_141_preflight_v0_2.sql` | `6,505` | `151409a6e52dec2f801db85edecad90ca2770984b704f883eed4283066ffa8ae` | `accepted_execution/tests/02_141_preflight_v0_2.sql` |
| `03` | RECOVERY | `03_140B_numeric_typmod_recovery_R1.sql` | `6,170` | `130a21de8d38a9eb2ad2746f82cd19c68d47b6f2fa4c2e207c9ec30fba360f7c` | `accepted_execution/tests/03_140B_numeric_typmod_recovery_R1.sql` |
| `04` | RECOVERY | `04_140C_selected_stress_recovery_R2.sql` | `6,711` | `d6ceded7401588d8c65d6c7ffae9cbaa4ff3ee860056138945cdf0fe93e0083e` | `accepted_execution/tests/04_140C_selected_stress_recovery_R2.sql` |
| `05` | CURRENT_NORMAL | `05_142_generation_R2.sql` | `65,313` | `1dc60e0884d1b49d7e417557602bb410734d7f3273e768a1e4eed0e2fbbfafc8` | `accepted_execution/sql/05_142_generation_R2.sql` |
| `06` | CURRENT_NORMAL | `06_143_positive_validation_R2.sql` | `78,854` | `105d3e3e48115ef30a04b6d26d5c9cb4645325c6abf932218337810f26d95afe` | `accepted_execution/sql/06_143_positive_validation_R2.sql` |
| `07` | CURRENT_NORMAL | `07_144_negative_controls_R2.sql` | `11,021` | `b00e549e6894e062a66942989f1943e71b1c9a18ab3b67f2a576982270c2d33b` | `accepted_execution/sql/07_144_negative_controls_R2.sql` |
| `08` | CURRENT_NORMAL | `08_145_acceptance_finalize_R2.sql` | `10,161` | `3969bd79d3bea027a14dd63fcd804023555f93b52224673d2ea7d717b45f04ef` | `accepted_execution/sql/08_145_acceptance_finalize_R2.sql` |
| `09` | REPORTING | `09_146_master_report_R2.sql` | `3,346` | `1b2ed622c5f7d831cbf295474e0a93d75368d4cb47259fb17ab561e59708112d` | `accepted_execution/tests/09_146_master_report_R2.sql` |
| `10` | REPORTING | `10_147_detail_report_R2.sql` | `17,162` | `e731cf138201a2d3e760527faf99b4b750e2cc035ac68b9379efab47c84f0bc6` | `accepted_execution/tests/10_147_detail_report_R2.sql` |
| `140` | CURRENT_NORMAL | `140_msbf_m2_2_schema_policy_structure_contract_extension_v0_2R2.sql` | `48,704` | `82056eadcbbd977ec3ef4c15667a77c32970d7618e00183f6837b94e591c89d8` | `sql/140_msbf_m2_2_schema_policy_structure_contract_extension_v0_2R2.sql` |
| `140A` | RECOVERY | `140A_msbf_m2_2_failed_generation_recovery_check_v0_2R2.sql` | `1,565` | `e7d499d239c772ef28c436f2664b66b21d085f8aa28cff2de1a6aa53c4f52e6d` | `tests/140A_msbf_m2_2_failed_generation_recovery_check_v0_2R2.sql` |
| `142A` | RECOVERY | `142A_msbf_m2_2_generation_reconciliation_reconstructed_v0_2R2.sql` | `1,355` | `169fc388943ed87c30339f1554d2819b1a15008a736a3ae0a9292f4ec770b0f1` | `tests/142A_msbf_m2_2_generation_reconciliation_reconstructed_v0_2R2.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
