# M1.12 Execution and Validation Guide

## Prerequisite

The governed run must be `M1_11_ACCEPTED` and all predecessor gates/hashes must reconcile.

## Normal execution order

1. `84_msbf_m1_12_schema_policy_extension_v0_2.sql`
2. `85_msbf_m1_12_preflight_validation_v0_2.sql`
3. `86_msbf_m1_12_integrated_risk_proxy_generation_v0_2.sql`
4. `87_msbf_m1_12_integrated_risk_proxy_validation_v0_2.sql`
5. `88_msbf_m1_12_negative_control_tests_v0_2.sql`
6. `89_msbf_m1_12_acceptance_finalize_v0_2.sql`
7. `90_MSBF_M1_12_Merchant_Risk_Proxy_Master_Report_v0_2.sql`
8. `91_MSBF_M1_12_Merchant_Risk_Proxy_Detail_Report_v0_2.sql`

## DBeaver controls

- Confirm `current_database() = 'msbf_strategy'`.
- Use **Execute SQL Script**.
- Stop on the first PostgreSQL exception.
- Do not choose Retry, Skip, or Skip All after a failure.
- Execute `ROLLBACK;` after a failed transactional program.
- Do not rerun program 86 after a successful commit.
- Programs 87, 88, and 91 retain session-scoped temporary result tables after commit so the result grids remain filterable in the same session.

## Contingencies

- `84A`: run only after a failed/cancelled generation and rollback.
- `86A`: run only if program 86 committed but the generation result tab was lost.

## Required final results

```text
Generation               PASS
Positive validation      80 / 80 PASS
Negative controls         7 / 7 PASS
Acceptance gate          PASS
Run status               M1_12_ACCEPTED
Master report            PASS
Deterministic mismatches 0
Blocking errors          0
```
