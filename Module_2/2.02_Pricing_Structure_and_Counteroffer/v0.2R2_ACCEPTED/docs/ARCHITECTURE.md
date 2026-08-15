# Architecture — M2.2 Pricing, Structure & Counteroffer

## Position in the accepted chain

```text
M2.1 accepted stage
    ↓
M2.2 — Pricing, Structure & Counteroffer
    ↓
M2.3 accepted stage
```

## Capability layers

- Pricing and factor/rate construction
- Term and remittance structure
- Counteroffer and alternative-structure generation
- Affordability, limits, and policy-bound pricing controls

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_140_schema_policy_v0_2.sql`](../src/current/01_140_schema_policy_v0_2.sql) | `c33652356dd8ece52822117b9536a57eef61673c04c17e61fb62685042833cb1` |
| `02` | CURRENT_NORMAL | [`02_141_preflight_v0_2.sql`](../src/current/02_141_preflight_v0_2.sql) | `151409a6e52dec2f801db85edecad90ca2770984b704f883eed4283066ffa8ae` |
| `03` | RECOVERY | [`03_140B_numeric_typmod_recovery_R1.sql`](../src/recovery/03_140B_numeric_typmod_recovery_R1.sql) | `130a21de8d38a9eb2ad2746f82cd19c68d47b6f2fa4c2e207c9ec30fba360f7c` |
| `04` | RECOVERY | [`04_140C_selected_stress_recovery_R2.sql`](../src/recovery/04_140C_selected_stress_recovery_R2.sql) | `d6ceded7401588d8c65d6c7ffae9cbaa4ff3ee860056138945cdf0fe93e0083e` |
| `05` | CURRENT_NORMAL | [`05_142_generation_R2.sql`](../src/current/05_142_generation_R2.sql) | `1dc60e0884d1b49d7e417557602bb410734d7f3273e768a1e4eed0e2fbbfafc8` |
| `06` | CURRENT_NORMAL | [`06_143_positive_validation_R2.sql`](../src/current/06_143_positive_validation_R2.sql) | `105d3e3e48115ef30a04b6d26d5c9cb4645325c6abf932218337810f26d95afe` |
| `07` | CURRENT_NORMAL | [`07_144_negative_controls_R2.sql`](../src/current/07_144_negative_controls_R2.sql) | `b00e549e6894e062a66942989f1943e71b1c9a18ab3b67f2a576982270c2d33b` |
| `08` | CURRENT_NORMAL | [`08_145_acceptance_finalize_R2.sql`](../src/current/08_145_acceptance_finalize_R2.sql) | `3969bd79d3bea027a14dd63fcd804023555f93b52224673d2ea7d717b45f04ef` |
| `09` | REPORTING | [`09_146_master_report_R2.sql`](../src/reporting/09_146_master_report_R2.sql) | `1b2ed622c5f7d831cbf295474e0a93d75368d4cb47259fb17ab561e59708112d` |
| `10` | REPORTING | [`10_147_detail_report_R2.sql`](../src/reporting/10_147_detail_report_R2.sql) | `e731cf138201a2d3e760527faf99b4b750e2cc035ac68b9379efab47c84f0bc6` |
| `140` | CURRENT_NORMAL | [`140_msbf_m2_2_schema_policy_structure_contract_extension_v0_2R2.sql`](../src/current/140_msbf_m2_2_schema_policy_structure_contract_extension_v0_2R2.sql) | `82056eadcbbd977ec3ef4c15667a77c32970d7618e00183f6837b94e591c89d8` |
| `140A` | RECOVERY | [`140A_msbf_m2_2_failed_generation_recovery_check_v0_2R2.sql`](../src/recovery/140A_msbf_m2_2_failed_generation_recovery_check_v0_2R2.sql) | `e7d499d239c772ef28c436f2664b66b21d085f8aa28cff2de1a6aa53c4f52e6d` |
| `142A` | RECOVERY | [`142A_msbf_m2_2_generation_reconciliation_reconstructed_v0_2R2.sql`](../src/recovery/142A_msbf_m2_2_generation_reconciliation_reconstructed_v0_2R2.sql) | `169fc388943ed87c30339f1554d2819b1a15008a736a3ae0a9292f4ec770b0f1` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
