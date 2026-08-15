# Architecture — M2.6 Early Warning, Intervention & Servicing Strategy

## Position in the accepted chain

```text
M2.5 accepted stage
    ↓
M2.6 — Early Warning, Intervention & Servicing Strategy
    ↓
M2.7 accepted stage
```

## Capability layers

- Early-warning signal detection
- Intervention strategy assignment
- Servicing outreach and treatment logic
- Risk, resilience, and operational guardrails

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_172_schema_policy.sql`](../src/current/01_172_schema_policy.sql) | `e90525e58f089cc84f9a518d61216e16bf96aba76cb09581f8ce7d363a36cf83` |
| `02` | CURRENT_NORMAL | [`02_173_preflight.sql`](../src/current/02_173_preflight.sql) | `6f2f4f9dff66ad5da183cc88e4400a823967305153fde142ae5124d968a612b5` |
| `03` | CURRENT_NORMAL | [`03_174_generation.sql`](../src/current/03_174_generation.sql) | `967ba6d8d12485c2dd887807a41c9ddebb029575c4f4162f10009fbfed4f1c29` |
| `04` | CURRENT_NORMAL | [`04_175_positive_validation.sql`](../src/current/04_175_positive_validation.sql) | `089fcab6962f3bda4d5e2029546ab7d5e8d1abc8f565574d625f72c1fce2e739` |
| `05` | CURRENT_NORMAL | [`05_176_negative_controls.sql`](../src/current/05_176_negative_controls.sql) | `c28fb91dddc0788a6f79190abe3fe96bb88d3b51dae1bb3b24e03afb03148428` |
| `06` | CURRENT_NORMAL | [`06_177_acceptance_finalize.sql`](../src/current/06_177_acceptance_finalize.sql) | `793f869122cc187d28e1c066c0125fa5980ac086846ae12c12be09104d072d3e` |
| `07` | REPORTING | [`07_178_master_report_v0_2R1.sql`](../src/reporting/07_178_master_report_v0_2R1.sql) | `07df5d1b0a0031849764178787aa520153712535624355706875d04e5be4bbeb` |
| `08` | REPORTING | [`08_179_detail_report.sql`](../src/reporting/08_179_detail_report.sql) | `53982a04b7fdc90ae5b235ae1b5cce6cd80d127e7230275e4376609b75c43f29` |
| `172A` | RECOVERY | [`172A_msbf_m2_6_failed_schema_policy_recovery_check_v0_2.sql`](../src/recovery/172A_msbf_m2_6_failed_schema_policy_recovery_check_v0_2.sql) | `73bd70af3c7e81c8dabbd312c9e909e0259e55e0136a174fd6474e53afab4cd0` |
| `174A` | RECOVERY | [`174A_msbf_m2_6_failed_generation_recovery_check_v0_2.sql`](../src/recovery/174A_msbf_m2_6_failed_generation_recovery_check_v0_2.sql) | `3d9377a35a79e7c0041d1ddcdfd2f44e02becd67d790e6f8915facc3a396f965` |
| `174B` | RECOVERY | [`174B_msbf_m2_6_generation_reconciliation_reconstructed_v0_2.sql`](../src/recovery/174B_msbf_m2_6_generation_reconciliation_reconstructed_v0_2.sql) | `0a766a7ac73de2efa6e5e076ec0a510c2ba7895642868b6c589428729b9c3717` |
| `178A` | RECOVERY | [`178A_msbf_m2_6_failed_master_report_boundary_source_recovery_v0_2R1.sql`](../src/recovery/178A_msbf_m2_6_failed_master_report_boundary_source_recovery_v0_2R1.sql) | `0272759ad9262d7dafde1dfa561ff89f186c0dfdbf5a48ebcda210fb71cac1a6` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
