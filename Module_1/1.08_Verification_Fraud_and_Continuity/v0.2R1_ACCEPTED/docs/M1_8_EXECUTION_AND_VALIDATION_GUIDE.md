# M1.8 Execution and Validation Guide

## Environment

Run in DBeaver against the accepted `msbf_strategy` PostgreSQL database. Before every script, confirm `current_database()` is `msbf_strategy`.

## Exact normal order

1. 52 schema/policy extension — expect `schema_policy_extension_status = PASS`.
2. 53 preflight — expect `preflight_status = PASS`.
3. 54 generation — expect `generation_status = PASS`; do not rerun after commit.
4. 55 positive validation — expect 60 of 60 PASS and `M1_8_VALIDATED`.
5. 56 negative controls — expect 6 of 6 PASS.
6. 57 acceptance — expect gate PASS and `M1_8_ACCEPTED`.
7. 58 master report — expect `overall_m1_8_status = PASS`.
8. 59 detailed report — export all 17 result sets; sets 15 and 17 must be empty.

## Recovery behavior

After a failed or cancelled generation, run `ROLLBACK;` and then 52A. Do not delete rows or reset status manually.

If generation committed but the result tab is lost, run 54A. Do not rerun generation.

## Evidence exports

Retain structured outputs for scripts 52–59 plus the completed acceptance milestone. Execution logs are optional unless diagnosing a defect.
