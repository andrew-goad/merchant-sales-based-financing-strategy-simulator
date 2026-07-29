# M1.10 v0.2R2 Recovery and Execution Guide

## Current accepted state expected before recovery

- Program 68 schema/policy extension: committed.
- Program 69 R1 preflight: `PASS`.
- Program 70 R1 generation: committed and `PASS`.
- Program 71 R1: failed with SQLSTATE `42601` before validation evidence was committed.

## Execution order

1. In the failed DBeaver session, select **Stop** and execute `ROLLBACK;`.
2. Run `68C_msbf_m1_10_failed_validation_syntax_recovery_check_v0_2R2.sql`.
3. Require `recovery_state_status = PASS`.
4. Run `71_msbf_m1_10_obligations_liquidity_capacity_validation_v0_2R2.sql`.
5. Require 70 rows, 70 `PASS`, zero `FAIL`, and `run_status = M1_10_VALIDATED`.
6. Run `72_msbf_m1_10_negative_control_tests_v0_2R2.sql`.
7. Run `73_msbf_m1_10_acceptance_finalize_v0_2R2.sql`.
8. Run master report 74 and detail report 75.

Do not rerun programs 68, 69, or 70.

`70A` is contingency-only and is not part of the normal sequence because the
program-70 result was retained.

The validation and negative-control temporary tables use `ON COMMIT PRESERVE
ROWS`, allowing result-grid filtering in the same DBeaver session after commit.
