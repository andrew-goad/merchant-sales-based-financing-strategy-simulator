# M2.1 Execution and Validation Guide

Run Programs 132–139 in sequence with DBeaver **Execute SQL Script**.

Stop at the first PostgreSQL error. Never use Retry, Skip or Skip All. Run `ROLLBACK;` after a failed transactional program.

Do not rerun Program 134 after it commits. Use Program 134A only if its result tab is lost. Use Program 132A only after a pre-commit Program 134 failure and rollback.

Expected checkpoints:
- 133: `preflight_status = PASS`
- 134: 22,541 canonical entities; zero mismatches; `M2_1_GENERATED`
- 135: 112/112 PASS
- 136: 20/20 PASS
- 137: gate PASS; `M2_1_ACCEPTED`
- 138: `overall_m2_1_status = PASS`
- 139: 24 result sets; 23 and 24 empty
