# Architecture — M2.5 Daily Remittance, Exposure & Portfolio Monitoring

## Position in the accepted chain

```text
M2.4 accepted stage
    ↓
M2.5 — Daily Remittance, Exposure & Portfolio Monitoring
    ↓
M2.6 accepted stage
```

## Capability layers

- Simulated remittance and exposure tracking
- Portfolio limits and concentration monitoring
- Daily performance and capacity measures
- Deterministic latest/archive operating evidence

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_164_schema_policy.sql`](../src/current/01_164_schema_policy.sql) | `4e26ba3ef2d1893ed79f0e9689bea0f3790f644918712a8edf3e04a7cc71e06b` |
| `02` | CURRENT_NORMAL | [`02_165_preflight.sql`](../src/current/02_165_preflight.sql) | `8142a40edc70caf912bc0faaf497b465ed6cd21643d8f30639df9b1e7f3735a6` |
| `03` | CURRENT_NORMAL | [`03_166_generation.sql`](../src/current/03_166_generation.sql) | `f1eee9785687b49e776c54bfe146dd03f40df5b2ddc28ef862efe6e79e7d0f71` |
| `04` | RECOVERY | [`04_164B_generation_recovery_proof.sql`](../src/recovery/04_164B_generation_recovery_proof.sql) | `d09d4e0ad6d9a8e96c0951878f0237290cd82985740e85a7ad727d98f07fad72` |
| `05` | CURRENT_NORMAL | [`05_167_positive_validation.sql`](../src/current/05_167_positive_validation.sql) | `ec8f2d5a1b48c23e0dfa5019b9c98e3643a341a782b7395b9b69011b2682a51d` |
| `06` | RECOVERY | [`06_168A_negative_control_recovery_proof.sql`](../src/recovery/06_168A_negative_control_recovery_proof.sql) | `5df3a6d6a5fc92287a918f621b3cc35de9651943942266df3b4c0da8133f00a7` |
| `07` | CURRENT_NORMAL | [`07_168_negative_controls.sql`](../src/current/07_168_negative_controls.sql) | `935ec8220fb6683c3e7ff2968378dafc1cfa43dc19cb78fe302a4def03a99e52` |
| `08` | RECOVERY | [`08_169A_acceptance_recovery_proof.sql`](../src/recovery/08_169A_acceptance_recovery_proof.sql) | `d1f9f207d37aede877c5e4459f85362b749de560bd71e559fc6af912dd01f165` |
| `09` | CURRENT_NORMAL | [`09_169_acceptance_finalize.sql`](../src/current/09_169_acceptance_finalize.sql) | `bbde79b07518127a235ddaf5e184c8f4dd39ad76e332b60039b880025f492ea1` |
| `10` | REPORTING | [`10_170_master_report.sql`](../src/reporting/10_170_master_report.sql) | `43459978177d82dbc28134e8770dc373e84ef9e256eb5e88e01d028cbfffd57e` |
| `11` | REPORTING | [`11_171_detail_report.sql`](../src/reporting/11_171_detail_report.sql) | `31a8446a85c3f8516a5b0a322f6606517b7c88892e9cf80f0efc3c6364e537c1` |
| `164A` | RECOVERY | [`164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql`](../src/recovery/164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql) | `2594cb66cab3a191fa5ade6b8dbbae72d3c39c592a9c8f8aeb4924c84f2a090a` |
| `166A` | RECOVERY | [`166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql`](../src/recovery/166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql) | `5b38cce0b45605e2e875d228991dd19e85e86f62cd5672b1e2042fa27a2f4462` |
| `166B` | RECOVERY | [`166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql`](../src/recovery/166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql) | `25ce36ceb6438edb3734c46b0191eba851f9b06c956381b18a2d7bbff20b2fb2` |
| `167` | CURRENT_NORMAL | [`167_msbf_m2_5_daily_remittance_exposure_validation_v0_2R5.sql`](../src/current/167_msbf_m2_5_daily_remittance_exposure_validation_v0_2R5.sql) | `acf62c8cc3aade5a561434da8b350eb32507dff2ec4c7e67876b7c769e16fcf3` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
