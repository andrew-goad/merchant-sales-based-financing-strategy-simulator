# M1.11 Execution and Validation Guide

## Prerequisite

The governed run must be `M1_10_ACCEPTED` and the accepted M1.9/M1.10 physical outputs and hashes must remain unchanged.

## Execute in order

1. 76 schema/policy extension — expect `schema_policy_extension_status = PASS`.
2. 77 preflight — expect `preflight_status = PASS`.
3. 78 generation — expect 1,500 snapshots, 7,500 components, 9,000 canonical entities, zero mismatches, `M1_11_GENERATED`.
4. 79 positive validation — expect 72/72 PASS and `M1_11_VALIDATED`.
5. 80 negative controls — expect 6/6 PASS.
6. 81 acceptance — expect gate PASS and `M1_11_ACCEPTED`.
7. 82 master report — expect `overall_m1_11_status = PASS`.
8. 83 detail report — export all 19 sets; sets 17 and 19 must be empty.

## DBeaver controls

- Confirm `current_database() = msbf_strategy`.
- Use **Execute SQL Script**.
- Stop at the first PostgreSQL exception.
- Do not use Retry, Skip, or Skip All after a failure.
- Execute `ROLLBACK;` after a failed transactional script.
- Do not rerun generation after it commits.
- Validation and negative-control temporary result tables use `ON COMMIT PRESERVE ROWS`, so filtering works in the same live database session.

## Contingencies

- 76A: after a failed/cancelled generation and rollback.
- 78A: if generation committed but the result tab was lost.
