# Architecture — M2.8 Servicing Execution, Payment & Lifecycle Control

## Position in the accepted chain

```text
M2.7 accepted stage
    ↓
M2.8 — Servicing Execution, Payment & Lifecycle Control
    ↓
M2.9 accepted stage
```

## Capability layers

- Simulated servicing and payment events
- Lifecycle transitions
- Intervention and restructuring controls
- Operational evidence and exception handling

## Program and source architecture

| Program | Class | Public source | SHA-256 |
|---|---|---|---|
| `01` | CURRENT_NORMAL | [`01_188_schema_policy.sql`](../src/current/01_188_schema_policy.sql) | `32d1df4de1d4fe4544f75f808acf20d40620c23761499ba9e2d0e21e9dfbf0de` |
| `02` | CURRENT_NORMAL | [`02_189_preflight.sql`](../src/current/02_189_preflight.sql) | `5e91d83d1bb3fe7ff46841c54e39b4bfa4bdc7c6a9d3cb4241f70ee18a0e66c8` |
| `03` | CURRENT_NORMAL | [`03_190_generation.sql`](../src/current/03_190_generation.sql) | `233852c8e497738aafe3b3368ff15272385a9b05c57047948b6b71c44e8faed5` |
| `04` | CURRENT_NORMAL | [`04_191_positive_validation.sql`](../src/current/04_191_positive_validation.sql) | `ede4a609b8aa039b6ec718ed17f2a954caf470adadbcdc2b33ed3e62eefeac12` |
| `05` | CURRENT_NORMAL | [`05_192_negative_controls.sql`](../src/current/05_192_negative_controls.sql) | `b81f1699fdacaf79c598dc89bd324e548d67697426d55c91bcb2e7d56bfac4cf` |
| `06` | CURRENT_NORMAL | [`06_193_acceptance_finalize.sql`](../src/current/06_193_acceptance_finalize.sql) | `caf841a57b9615efb3b831a9634e8cbd318b45273787069375a5ec834a8ce0df` |
| `07` | REPORTING | [`07_194_master_report.sql`](../src/reporting/07_194_master_report.sql) | `d283607820dce42229df05fe47795d1bdaa254f510162be0e427f1a9b4e515a7` |
| `08` | REPORTING | [`08_195_detail_report.sql`](../src/reporting/08_195_detail_report.sql) | `528a64ff8dd7ab6d0da8eca4a6f117225db7abf62c4c03bd2e294a13d2a5c990` |
| `188A` | RECOVERY | [`188A_failed_schema_policy_recovery.sql`](../src/recovery/188A_failed_schema_policy_recovery.sql) | `49663756457e1d87a94aa69c7c4c3a8ef75fa9b409ed42f84901ee50696697b4` |
| `190A` | RECOVERY | [`190A_failed_generation_recovery.sql`](../src/recovery/190A_failed_generation_recovery.sql) | `7752749f08f180e7981da76613375ea161f3613c571bab20fae286068c2fa328` |
| `190B` | RECOVERY | [`190B_generation_reconstruction.sql`](../src/recovery/190B_generation_reconstruction.sql) | `bce4c279ce8f6f0e077ae467bfc0bd6a313b1cae14838655f920a24b2677eede` |

## Mutation and reporting boundary

- **Current normal source** implements the governed stage chain.
- **Reporting source** is read-only against accepted persistent state, except for session-local temporary reporting structures where explicitly governed.
- **Recovery source** is contingency-only, requires its own precondition, and is not part of normal execution.
- Superseded or diagnostic SQL is not placed in executable public source folders.

## Enterprise boundary

This stage contributes deterministic evidence to the accepted Module 2 chain. It neither authorizes production deployment nor converts synthetic comparison into empirical or causal proof.
