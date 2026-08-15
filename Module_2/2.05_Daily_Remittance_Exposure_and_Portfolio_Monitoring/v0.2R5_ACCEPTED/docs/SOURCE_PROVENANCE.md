# Source Provenance — M2.5 Daily Remittance, Exposure & Portfolio Monitoring

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
24_M2_5
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_164_schema_policy.sql` | `83,955` | `4e26ba3ef2d1893ed79f0e9689bea0f3790f644918712a8edf3e04a7cc71e06b` | `accepted_execution/sql/01_164_schema_policy.sql` |
| `02` | CURRENT_NORMAL | `02_165_preflight.sql` | `22,948` | `8142a40edc70caf912bc0faaf497b465ed6cd21643d8f30639df9b1e7f3735a6` | `accepted_execution/tests/02_165_preflight.sql` |
| `03` | CURRENT_NORMAL | `03_166_generation.sql` | `112,891` | `f1eee9785687b49e776c54bfe146dd03f40df5b2ddc28ef862efe6e79e7d0f71` | `accepted_execution/sql/03_166_generation.sql` |
| `04` | RECOVERY | `04_164B_generation_recovery_proof.sql` | `11,989` | `d09d4e0ad6d9a8e96c0951878f0237290cd82985740e85a7ad727d98f07fad72` | `accepted_execution/tests/04_164B_generation_recovery_proof.sql` |
| `05` | CURRENT_NORMAL | `05_167_positive_validation.sql` | `98,315` | `ec8f2d5a1b48c23e0dfa5019b9c98e3643a341a782b7395b9b69011b2682a51d` | `accepted_execution/sql/05_167_positive_validation.sql` |
| `06` | RECOVERY | `06_168A_negative_control_recovery_proof.sql` | `12,520` | `5df3a6d6a5fc92287a918f621b3cc35de9651943942266df3b4c0da8133f00a7` | `accepted_execution/tests/06_168A_negative_control_recovery_proof.sql` |
| `07` | CURRENT_NORMAL | `07_168_negative_controls.sql` | `26,112` | `935ec8220fb6683c3e7ff2968378dafc1cfa43dc19cb78fe302a4def03a99e52` | `accepted_execution/sql/07_168_negative_controls.sql` |
| `08` | RECOVERY | `08_169A_acceptance_recovery_proof.sql` | `28,310` | `d1f9f207d37aede877c5e4459f85362b749de560bd71e559fc6af912dd01f165` | `accepted_execution/tests/08_169A_acceptance_recovery_proof.sql` |
| `09` | CURRENT_NORMAL | `09_169_acceptance_finalize.sql` | `20,871` | `bbde79b07518127a235ddaf5e184c8f4dd39ad76e332b60039b880025f492ea1` | `accepted_execution/sql/09_169_acceptance_finalize.sql` |
| `10` | REPORTING | `10_170_master_report.sql` | `8,534` | `43459978177d82dbc28134e8770dc373e84ef9e256eb5e88e01d028cbfffd57e` | `accepted_execution/tests/10_170_master_report.sql` |
| `11` | REPORTING | `11_171_detail_report.sql` | `22,542` | `31a8446a85c3f8516a5b0a322f6606517b7c88892e9cf80f0efc3c6364e537c1` | `accepted_execution/tests/11_171_detail_report.sql` |
| `164A` | RECOVERY | `164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql` | `8,036` | `2594cb66cab3a191fa5ade6b8dbbae72d3c39c592a9c8f8aeb4924c84f2a090a` | `tests/164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql` |
| `166A` | RECOVERY | `166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql` | `5,284` | `5b38cce0b45605e2e875d228991dd19e85e86f62cd5672b1e2042fa27a2f4462` | `tests/166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql` |
| `166B` | RECOVERY | `166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql` | `6,076` | `25ce36ceb6438edb3734c46b0191eba851f9b06c956381b18a2d7bbff20b2fb2` | `tests/166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql` |
| `167` | CURRENT_NORMAL | `167_msbf_m2_5_daily_remittance_exposure_validation_v0_2R5.sql` | `100,853` | `acf62c8cc3aade5a561434da8b350eb32507dff2ec4c7e67876b7c769e16fcf3` | `sql/167_msbf_m2_5_daily_remittance_exposure_validation_v0_2R5.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
