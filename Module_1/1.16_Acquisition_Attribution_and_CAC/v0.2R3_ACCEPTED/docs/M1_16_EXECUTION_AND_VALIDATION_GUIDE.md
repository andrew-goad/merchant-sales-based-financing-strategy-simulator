# M1.16 Execution and Validation Guide

## Database
```text
PostgreSQL 15
Database: msbf_strategy
Run: M1_V0_2_BASELINE_BUILD / version 1
Required starting status: M1_15_ACCEPTED
```

## DBeaver rules
Use **Execute SQL Script**. Stop at the first PostgreSQL error. Never use Retry, Skip, or Skip All. Execute `ROLLBACK;` after a failed transactional program. Do not manually reset status or delete accepted records.

## Normal sequence
1. `116_msbf_m1_16_acquisition_foundations_schema_policy_extension_v0_2.sql`
2. `117_msbf_m1_16_preflight_validation_v0_2.sql`
3. `118_msbf_m1_16_acquisition_attribution_cost_generation_v0_2.sql`
4. `119_msbf_m1_16_acquisition_foundations_validation_v0_2.sql`
5. `120_msbf_m1_16_negative_control_tests_v0_2.sql`
6. `121_msbf_m1_16_acceptance_finalize_v0_2.sql`
7. `122_MSBF_M1_16_Acquisition_Foundations_Master_Report_v0_2.sql`
8. `123_MSBF_M1_16_Acquisition_Foundations_Detail_Report_v0_2.sql`

## Program 118 checkpoint
```text
run_status                 M1_16_GENERATED
source profiles            18
campaigns                  20
funnel rows                120
cost-ledger rows           40
touchpoints                1,075
attribution snapshots      750
cost snapshots             750
component rows             9,000
latest / archive           750 / 750
contract registry          1
integrated view            1,500
canonical entities         13,274
row-level mismatches       0
generation_status          PASS
```
After commit, do not rerun Program 118.

## Validation and acceptance
Program 119 must return 112/112 PASS and set `M1_16_VALIDATED`. Program 120 must return 20/20 PASS. Program 121 must set contract lifecycle `ACCEPTED`, gate `M1_16_ACQUISITION_MARKETING_COST_FOUNDATIONS` to PASS, and run status `M1_16_ACCEPTED`.

## Contingency
- `116A`: only after a failed/cancelled pre-commit Program 118 and `ROLLBACK;`.
- `118A`: only after Program 118 committed but its DBeaver result tab was lost.

## Evidence
Export 116–123 results. Program 123 result sets 23 and 24 must retain headers and contain zero rows.
