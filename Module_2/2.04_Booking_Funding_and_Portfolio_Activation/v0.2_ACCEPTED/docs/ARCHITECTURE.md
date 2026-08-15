# Architecture — M2.4 Booking, Funding & Portfolio Activation

## Position in the accepted chain

```text
M2.3 accepted stage
    ↓
M2.4 — Booking, Funding & Portfolio Activation
    ↓
M2.5 accepted stage
```

## Capability layers

- Simulated booking and funding state
- Portfolio account activation
- Initial balance, limit, and lifecycle state
- Activation reconciliation and lineage

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_156_schema_policy.sql`](../src/current/01_156_schema_policy.sql) | `eb673af9966986614a67a203bf7d1807c72aa809d71f512b4c2d0928f617745a` |
| `02` | CURRENT_NORMAL | [`02_157_preflight.sql`](../src/current/02_157_preflight.sql) | `b8d2176a8defc1948f63c53cd1410efe567fc429fe5ce35cec77730daa711fe2` |
| `03` | CURRENT_NORMAL | [`03_158_generation.sql`](../src/current/03_158_generation.sql) | `60a3880304cd83b0d42f22cfa2d5f870f2d281bf0698e2ba6be20899d3650747` |
| `04` | CURRENT_NORMAL | [`04_159_positive_validation.sql`](../src/current/04_159_positive_validation.sql) | `21c1d825f1049205c4d0fb9914ee32ee7c07f521bcb36548e10fe1109715d0e9` |
| `05` | CURRENT_NORMAL | [`05_160_negative_controls.sql`](../src/current/05_160_negative_controls.sql) | `d0fc73a8e12245300c38cac9d88122887401a6f3a685a09e8d448a53bedb54f3` |
| `06` | CURRENT_NORMAL | [`06_161_acceptance_finalize.sql`](../src/current/06_161_acceptance_finalize.sql) | `a24ef1aae7e64cfa768eaaffc356c4856b325a176c1dea7404f8de597e28de16` |
| `07` | REPORTING | [`07_162_master_report.sql`](../src/reporting/07_162_master_report.sql) | `6f6a68d7d559a55d84d5ec6ade9e50de519dfc140e5b827d7a4fec1095edbb69` |
| `08` | REPORTING | [`08_163_detail_report.sql`](../src/reporting/08_163_detail_report.sql) | `ab2f47a240cb4bd9adba9f6b07124733ad7658cbdc87af4ed51a782ef1aca47f` |
| `156A` | RECOVERY | [`156A_msbf_m2_4_failed_schema_policy_recovery_check_v0_2.sql`](../src/recovery/156A_msbf_m2_4_failed_schema_policy_recovery_check_v0_2.sql) | `9f57eb54bf49758778cf760b04c7cdc5bcd6581d6693e6a1e159a8a715475ea8` |
| `158A` | RECOVERY | [`158A_msbf_m2_4_failed_generation_recovery_check_v0_2.sql`](../src/recovery/158A_msbf_m2_4_failed_generation_recovery_check_v0_2.sql) | `f1f6d653867bda4a4401987f9cb910a9b711bee16dae6c2741184382cc318a71` |
| `158B` | RECOVERY | [`158B_msbf_m2_4_generation_reconciliation_reconstructed_v0_2.sql`](../src/recovery/158B_msbf_m2_4_generation_reconciliation_reconstructed_v0_2.sql) | `6cec4b8f80a5f32cc6c70cec90ae56b8bad7f44f35f78a52b6905c8ee2aaf30f` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
