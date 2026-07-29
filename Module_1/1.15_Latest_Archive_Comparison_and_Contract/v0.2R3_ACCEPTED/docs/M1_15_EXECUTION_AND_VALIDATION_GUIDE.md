# M1.15 v0.2R3 Execution Guide

## Current expected state

- Run status: `M1_15_FAILED`
- Contract status: `GENERATED`
- Latest rows: 1,500
- Archive rows: 1,500
- Comparison rows: 750
- Positive controls: 83/84 PASS
- Sole failed code: `M1_15_POS_62_RESILIENCE_NONIMPROVEMENT`
- Negative-control evidence: 0
- M1.15 gate rows: 0

## Execute in this order

1. `tests/108D_msbf_m1_15_failed_resilience_nonimprovement_validation_recovery_v0_2R3.sql`
2. `sql/111_msbf_m1_15_consumption_contract_validation_v0_2R3.sql`
3. `sql/112_msbf_m1_15_negative_control_tests_v0_2R3.sql`
4. `sql/113_msbf_m1_15_acceptance_finalize_v0_2R3.sql`
5. `tests/114_MSBF_M1_15_Consumption_Contract_Master_Report_v0_2R3.sql`
6. `tests/115_MSBF_M1_15_Consumption_Contract_Detail_Report_v0_2R3.sql`

## Do not rerun

- 108 schema/policy extension
- 108B or 108C recovery
- 109 preflight
- 110 generation

The committed generation is authoritative.

## Expected checkpoints

### 108D

- prior run status `M1_15_FAILED`
- final run status `M1_15_GENERATED`
- score improvements 1
- tier improvements 0
- archetype improvements 0
- physical hash mismatches 0
- recovery status `PASS`

### 111

- 84/84 PASS
- POS62 observed value includes
  `tier=0|archetype=0|score_increases_diagnostic=1`
- run status `M1_15_VALIDATED`

### 112

- 7/7 PASS

### 113

- acceptance status `PASS`
- run status `M1_15_ACCEPTED`
- contract status `ACCEPTED`

### 114

- `overall_m1_15_status = PASS`

### 115

- 20 result sets
- Result Set 19 deterministic mismatches: zero rows
- Result Set 20 blocking errors: zero rows
