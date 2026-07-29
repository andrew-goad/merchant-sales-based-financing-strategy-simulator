# M1.10 v0.2R1 Execution Guide

## Immediate action

1. In the current DBeaver warning dialog, select **Cancel**.
2. In the same connection, execute `ROLLBACK;`.
3. Do not rerun script 68.
4. Run the R1 recovery check and proceed only if it returns `PASS`.

## Normal R1 sequence

1. `tests/68B_msbf_m1_10_pre_generation_recovery_check_v0_2R1.sql`
2. `tests/69_msbf_m1_10_preflight_validation_v0_2R1.sql`
3. `sql/70_msbf_m1_10_obligations_liquidity_capacity_generation_v0_2R1.sql`
4. `sql/71_msbf_m1_10_obligations_liquidity_capacity_validation_v0_2R1.sql`
5. `sql/72_msbf_m1_10_negative_control_tests_v0_2R1.sql`
6. `sql/73_msbf_m1_10_acceptance_finalize_v0_2R1.sql`
7. `tests/74_MSBF_M1_10_Obligations_Liquidity_Capacity_Master_Report_v0_2R1.sql`
8. `tests/75_MSBF_M1_10_Obligations_Liquidity_Capacity_Detail_Report_v0_2R1.sql`

## Required checkpoints

### Recovery

- run status: `M1_9_ACCEPTED`
- obligation rows: `0`
- capacity rows: `0`
- M1.10 evidence rows: `0`
- M1.10 gate rows: `0`
- population-registry hash: `9b706c926260a3ef1ae8ac95eed5d0bf`
- recovery status: `PASS`

### Preflight

- `m12_hash = 9b706c926260a3ef1ae8ac95eed5d0bf`
- `preflight_status = PASS`

### Generation

- capacity rows: `1,500`
- applications: `750`
- scenarios: `2`
- canonical mismatches: `0`
- generation status: `PASS`

### Final

- positive controls: `70 / 70 PASS`
- negative controls: `6 / 6 PASS`
- gate: `PASS`
- run status: `M1_10_ACCEPTED`
- master report: `PASS`

## DBeaver behavior

R1 bounds both temporary-table row-hash updates with `WHERE row_hash IS NULL`. The prior destructive-query warning should no longer appear for those statements. Do not disable DBeaver's global confirmation safeguards.
