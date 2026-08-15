# Architecture — M2.7 Operational Activation & Account Setup

## Position in the accepted chain

```text
M2.6 accepted stage
    ↓
M2.7 — Operational Activation & Account Setup
    ↓
M2.8 accepted stage
```

## Capability layers

- Operational account setup
- Servicing configuration
- Account-state and limit initialization
- Operational readiness and lineage controls

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_180_schema_policy.sql`](../src/current/01_180_schema_policy.sql) | `4ece293aa09cac3b52134112e001cbc378cff773f208f347fb046fdbc945338a` |
| `02` | CURRENT_NORMAL | [`02_181_preflight.sql`](../src/current/02_181_preflight.sql) | `994552d5644b25644c3cc28d76d29a31a368461e33b3ca8bb282d326e75925e1` |
| `02A` | RECOVERY | [`02A_182A_failed_generation_recovery.sql`](../src/recovery/02A_182A_failed_generation_recovery.sql) | `8acd01d81de97cc35894fa4907b587030c2edbdeddc66c22ada5f9356f6bfcda` |
| `03` | CURRENT_NORMAL | [`03_182_generation_v0_2R1.sql`](../src/current/03_182_generation_v0_2R1.sql) | `292bd1902ba161fc8069ce17a50f5a1ae17f24caa3eccb7c957b9ca47d61185b` |
| `04` | CURRENT_NORMAL | [`04_183_positive_validation.sql`](../src/current/04_183_positive_validation.sql) | `12456e6aa4d2a86e8b9fa680d1fdc9da9f561d1487510922645695e39a11f836` |
| `05` | CURRENT_NORMAL | [`05_184_negative_controls.sql`](../src/current/05_184_negative_controls.sql) | `3fc46b8df3552e2e1773a3315d1399fabab6de1cc10d6f20daa2922452e20fc8` |
| `06` | CURRENT_NORMAL | [`06_185_acceptance_finalize.sql`](../src/current/06_185_acceptance_finalize.sql) | `99937602960d59e13662922d1ae878b7e84e41525a1f3ee9a37b553be35924c4` |
| `07` | REPORTING | [`07_186_master_report.sql`](../src/reporting/07_186_master_report.sql) | `a613959c075f48874299516dfa38cd0ada9c5c4cd5b2d126509b63bcb816fecc` |
| `08` | REPORTING | [`08_187_detail_report.sql`](../src/reporting/08_187_detail_report.sql) | `dd8514c29ee5737cabef82b19a79502b302fc597136d3f7624d501ed9523631c` |
| `180A` | RECOVERY | [`180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql`](../src/recovery/180A_msbf_m2_7_failed_schema_policy_recovery_check_v0_2.sql) | `9b43a3c1d34793a3e607c087871f9c982a87d85498e953acb41517fbcfba7b52` |
| `182B` | RECOVERY | [`182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql`](../src/recovery/182B_msbf_m2_7_generation_reconciliation_reconstructed_v0_2.sql) | `2e2711fb95755c1c54f175367832e8ba14fda41772a0b259fe045f9c33a18de4` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
