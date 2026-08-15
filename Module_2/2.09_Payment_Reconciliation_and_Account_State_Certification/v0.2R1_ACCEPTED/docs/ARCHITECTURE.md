# Architecture — M2.9 Payment Reconciliation & Account State Certification

## Position in the accepted chain

```text
M2.8 accepted stage
    ↓
M2.9 — Payment Reconciliation & Account State Certification
    ↓
M2.10 accepted stage
```

## Capability layers

- Payment and balance reconciliation
- Account-state certification
- Latest/archive consistency
- Exception and lineage controls

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_196_schema_policy.sql`](../src/current/01_196_schema_policy.sql) | `5ad98f677fcdd630de18d3d7cf699f464539ee8698367f80e836125f91c6c958` |
| `02` | CURRENT_NORMAL | [`02_197_preflight.sql`](../src/current/02_197_preflight.sql) | `55182c021ab057bd357993c0d17da5f9a69bddc466dad72cb2837d8fd4462271` |
| `03` | CURRENT_NORMAL | [`03_198_generation.sql`](../src/current/03_198_generation.sql) | `beb1c64b357dd2a60a9acf235e0f8af06199f80704a3b47f13eb9947168d66e9` |
| `03A` | RECOVERY | [`03A_199A_failed_positive_validation_recovery.sql`](../src/recovery/03A_199A_failed_positive_validation_recovery.sql) | `e243a0b1ed95ef1bf13f7bd54b13c16842a044b2083ae4cdcfa00309f4aaec6a` |
| `04` | CURRENT_NORMAL | [`04_199_positive_validation_v0_2R1.sql`](../src/current/04_199_positive_validation_v0_2R1.sql) | `f7eead4738cb4592be5e143af31e897b796aecbea4e117392d7ecd970fa4e0d5` |
| `05` | CURRENT_NORMAL | [`05_200_negative_controls.sql`](../src/current/05_200_negative_controls.sql) | `fba2e7a683e85b5c1ba749052edb287fe878f8ecfdc2392f4304ce90127b06ef` |
| `06` | CURRENT_NORMAL | [`06_201_acceptance_finalize.sql`](../src/current/06_201_acceptance_finalize.sql) | `3aa3f3b95969338caf4ec082f2b21d14ae7f5695399703ef381ad3a07a36dd38` |
| `07` | REPORTING | [`07_202_master_report_executed_v0_2.sql`](../src/reporting/07_202_master_report_executed_v0_2.sql) | `4ece660334953b9fdecbd93f78e7a22707ed04ee5bb17d0753883a87ed3bb4a5` |
| `07R` | RECOVERY | [`07R1_202_master_report_header_normalized.sql`](../src/recovery/07R1_202_master_report_header_normalized.sql) | `45919b991e529f536ad3a9180e7734b4c104138145ac65ebc8fc95a05e6b7411` |
| `08` | REPORTING | [`08_203_detail_report.sql`](../src/reporting/08_203_detail_report.sql) | `7c4081bcd6e877a6ec578979cac7936d85850a06db66dffcb65d3e7cfbfa33e0` |
| `196A` | RECOVERY | [`196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql`](../src/recovery/196A_msbf_m2_9_failed_schema_policy_recovery_check_v0_2.sql) | `3120d63c38aa85fa0fde02c3f91ab48068a0cb233b6819217f650f956f8fead4` |
| `198A` | RECOVERY | [`198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql`](../src/recovery/198A_msbf_m2_9_failed_generation_recovery_check_v0_2.sql) | `f7f28e5e0f041d69d4b33404eae8dbb4e4d2e3e27846a621f297d2f8b88375f5` |
| `198B` | RECOVERY | [`198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql`](../src/recovery/198B_msbf_m2_9_generation_reconciliation_reconstructed_v0_2.sql) | `bbd770c7e605d64c643bdc23487c197844b96074dcc5cde1ae2c524cb9159bfc` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
