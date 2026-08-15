# Source Provenance — M2.9 Payment Reconciliation & Account State Certification

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
28_M2_9
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_196_schema_policy.sql` | `78,680` | `5ad98f677fcdd630de18d3d7cf699f464539ee8698367f80e836125f91c6c958` | `accepted_execution/sql/01_196_schema_policy.sql` |
| `02` | CURRENT_NORMAL | `02_197_preflight.sql` | `16,083` | `55182c021ab057bd357993c0d17da5f9a69bddc466dad72cb2837d8fd4462271` | `accepted_execution/tests/02_197_preflight.sql` |
| `03` | CURRENT_NORMAL | `03_198_generation.sql` | `90,524` | `beb1c64b357dd2a60a9acf235e0f8af06199f80704a3b47f13eb9947168d66e9` | `accepted_execution/sql/03_198_generation.sql` |
| `03A` | RECOVERY | `03A_199A_failed_positive_validation_recovery.sql` | `6,792` | `e243a0b1ed95ef1bf13f7bd54b13c16842a044b2083ae4cdcfa00309f4aaec6a` | `accepted_execution/recovery/03A_199A_failed_positive_validation_recovery.sql` |
| `04` | CURRENT_NORMAL | `04_199_positive_validation_v0_2R1.sql` | `87,902` | `f7eead4738cb4592be5e143af31e897b796aecbea4e117392d7ecd970fa4e0d5` | `accepted_execution/sql/04_199_positive_validation_v0_2R1.sql` |
| `05` | CURRENT_NORMAL | `05_200_negative_controls.sql` | `15,008` | `fba2e7a683e85b5c1ba749052edb287fe878f8ecfdc2392f4304ce90127b06ef` | `accepted_execution/sql/05_200_negative_controls.sql` |
| `06` | CURRENT_NORMAL | `06_201_acceptance_finalize.sql` | `19,621` | `3aa3f3b95969338caf4ec082f2b21d14ae7f5695399703ef381ad3a07a36dd38` | `accepted_execution/sql/06_201_acceptance_finalize.sql` |
| `07` | REPORTING | `07_202_master_report_executed_v0_2.sql` | `15,463` | `4ece660334953b9fdecbd93f78e7a22707ed04ee5bb17d0753883a87ed3bb4a5` | `accepted_execution/tests/07_202_master_report_executed_v0_2.sql` |
| `07R` | RECOVERY | `07R1_202_master_report_header_normalized.sql` | `15,499` | `45919b991e529f536ad3a9180e7734b4c104138145ac65ebc8fc95a05e6b7411` | `accepted_execution/reporting_normalization/07R1_202_master_report_header_normalized.sql` |
| `08` | REPORTING | `08_203_detail_report.sql` | `21,906` | `7c4081bcd6e877a6ec578979cac7936d85850a06db66dffcb65d3e7cfbfa33e0` | `accepted_execution/tests/08_203_detail_report.sql` |
| `196A` | RECOVERY | `196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql` | `4,231` | `3120d63c38aa85fa0fde02c3f91ab48068a0cb233b6819217f650f956f8fead4` | `tests/196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql` |
| `198A` | RECOVERY | `198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql` | `3,380` | `f7f28e5e0f041d69d4b33404eae8dbb4e4d2e3e27846a621f297d2f8b88375f5` | `tests/198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql` |
| `198B` | RECOVERY | `198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql` | `6,068` | `bbd770c7e605d64c643bdc23487c197844b96074dcc5cde1ae2c524cb9159bfc` | `tests/198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
