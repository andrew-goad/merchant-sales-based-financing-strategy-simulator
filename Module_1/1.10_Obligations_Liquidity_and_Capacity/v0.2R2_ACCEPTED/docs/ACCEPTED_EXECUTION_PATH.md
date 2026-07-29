# M1.10 Accepted Execution Path

## Final clean-build path

Use the version-aligned files under `sql/` and `tests/`:

1. `sql/68_msbf_m1_10_schema_policy_extension_v0_2R2.sql`
2. `tests/69_msbf_m1_10_preflight_validation_v0_2R2.sql`
3. `sql/70_msbf_m1_10_obligations_liquidity_capacity_generation_v0_2R2.sql`
4. `sql/71_msbf_m1_10_obligations_liquidity_capacity_validation_v0_2R2.sql`
5. `sql/72_msbf_m1_10_negative_control_tests_v0_2R2.sql`
6. `sql/73_msbf_m1_10_acceptance_finalize_v0_2R2.sql`
7. `tests/74_MSBF_M1_10_Obligations_Liquidity_Capacity_Master_Report_v0_2R2.sql`
8. `tests/75_MSBF_M1_10_Obligations_Liquidity_Capacity_Detail_Report_v0_2R2.sql`

## Exact live accepted path

The accepted database execution used:

1. v0.2 schema/policy extension;
2. v0.2R1 preflight and generation;
3. v0.2R2 validation, negative controls, acceptance, and reporting.

Those exact programs are retained under `accepted_execution/`.

## Contingency-only programs

- `68A`: failed-generation recovery after rollback;
- `68B`: pre-generation recovery and M1.2 population-hash diagnosis;
- `68C`: post-generation validation-syntax recovery and hash reconciliation;
- `70A`: read-only generation-evidence reconstruction after a successful commit if the result tab is lost.

Contingency programs are not part of a normal clean-build sequence.
