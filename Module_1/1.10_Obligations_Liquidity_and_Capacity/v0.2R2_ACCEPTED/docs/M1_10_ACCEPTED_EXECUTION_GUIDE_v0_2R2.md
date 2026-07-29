# M1.10 Accepted Execution Guide — v0.2R2

## Final clean-build sequence

Use the version-aligned files in the module-level `sql/` and `tests/` folders:

1. `sql/68_msbf_m1_10_schema_policy_extension_v0_2R2.sql`
2. `tests/69_msbf_m1_10_preflight_validation_v0_2R2.sql`
3. `sql/70_msbf_m1_10_obligations_liquidity_capacity_generation_v0_2R2.sql`
4. `sql/71_msbf_m1_10_obligations_liquidity_capacity_validation_v0_2R2.sql`
5. `sql/72_msbf_m1_10_negative_control_tests_v0_2R2.sql`
6. `sql/73_msbf_m1_10_acceptance_finalize_v0_2R2.sql`
7. `tests/74_MSBF_M1_10_Obligations_Liquidity_Capacity_Master_Report_v0_2R2.sql`
8. `tests/75_MSBF_M1_10_Obligations_Liquidity_Capacity_Detail_Report_v0_2R2.sql`

## Exact accepted live path

The live accepted run used:

1. v0.2 schema/policy extension;
2. v0.2R1 corrected preflight;
3. v0.2R1 generation;
4. v0.2R2 validation through detail reporting.

Those exact files are preserved in `accepted_execution/`.

## Contingency scripts

- `68A`: failed-generation recovery after rollback;
- `68B`: pre-generation recovery and M1.2 population-hash diagnosis;
- `68C`: post-generation validation-syntax recovery and hash reconciliation;
- `70A`: read-only generation-evidence reconstruction if the generation result tab is lost.

Contingency scripts are not part of a normal clean run.

## Required final results

```text
obligation rows           governed nonzero count
capacity rows             1,500
applications              750
scenarios                 2
canonical mismatches      0
positive controls         70 / 70 PASS
negative controls          6 / 6 PASS
stress improvements       0
blocking errors           0
run status                M1_10_ACCEPTED
master report             PASS
```
