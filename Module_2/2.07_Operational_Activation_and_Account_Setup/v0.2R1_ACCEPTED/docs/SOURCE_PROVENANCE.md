# Source Provenance — M2.7 Operational Activation & Account Setup

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
26_M2_7
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_180_schema_policy.sql` | `66,933` | `4ece293aa09cac3b52134112e001cbc378cff773f208f347fb046fdbc945338a` | `accepted_execution/sql/01_180_schema_policy.sql` |
| `02` | CURRENT_NORMAL | `02_181_preflight.sql` | `14,044` | `994552d5644b25644c3cc28d76d29a31a368461e33b3ca8bb282d326e75925e1` | `accepted_execution/tests/02_181_preflight.sql` |
| `02A` | RECOVERY | `02A_182A_failed_generation_recovery.sql` | `2,951` | `8acd01d81de97cc35894fa4907b587030c2edbdeddc66c22ada5f9356f6bfcda` | `accepted_execution/recovery/02A_182A_failed_generation_recovery.sql` |
| `03` | CURRENT_NORMAL | `03_182_generation_v0_2R1.sql` | `70,259` | `292bd1902ba161fc8069ce17a50f5a1ae17f24caa3eccb7c957b9ca47d61185b` | `accepted_execution/sql/03_182_generation_v0_2R1.sql` |
| `04` | CURRENT_NORMAL | `04_183_positive_validation.sql` | `88,719` | `12456e6aa4d2a86e8b9fa680d1fdc9da9f561d1487510922645695e39a11f836` | `accepted_execution/sql/04_183_positive_validation.sql` |
| `05` | CURRENT_NORMAL | `05_184_negative_controls.sql` | `21,592` | `3fc46b8df3552e2e1773a3315d1399fabab6de1cc10d6f20daa2922452e20fc8` | `accepted_execution/sql/05_184_negative_controls.sql` |
| `06` | CURRENT_NORMAL | `06_185_acceptance_finalize.sql` | `15,453` | `99937602960d59e13662922d1ae878b7e84e41525a1f3ee9a37b553be35924c4` | `accepted_execution/sql/06_185_acceptance_finalize.sql` |
| `07` | REPORTING | `07_186_master_report.sql` | `14,866` | `a613959c075f48874299516dfa38cd0ada9c5c4cd5b2d126509b63bcb816fecc` | `accepted_execution/tests/07_186_master_report.sql` |
| `08` | REPORTING | `08_187_detail_report.sql` | `20,064` | `dd8514c29ee5737cabef82b19a79502b302fc597136d3f7624d501ed9523631c` | `accepted_execution/tests/08_187_detail_report.sql` |
| `180A` | RECOVERY | `180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql` | `4,912` | `9b43a3c1d34793a3e607c087871f9c982a87d85498e953acb41517fbcfba7b52` | `tests/180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql` |
| `182B` | RECOVERY | `182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql` | `4,822` | `2e2711fb95755c1c54f175367832e8ba14fda41772a0b259fe045f9c33a18de4` | `tests/182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
