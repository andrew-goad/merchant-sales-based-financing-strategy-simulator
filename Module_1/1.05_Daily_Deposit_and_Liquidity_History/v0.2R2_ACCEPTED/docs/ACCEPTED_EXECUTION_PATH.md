# Accepted M1.5 Execution Path — v0.2R2

## Historical live path

The accepted live run used:

1. `31_msbf_m1_5_preflight_validation_v0_2.sql` — original PASS tab later unavailable.
2. `32_msbf_m1_5_daily_deposit_liquidity_generation_v0_2.sql` — committed generation.
3. Initial `33` validation — detected 16 pre-open NSF events.
4. `corrections/v0_2R1_pre_open_nsf/32A...sql` — controlled correction.
5. `33`, `34`, `35`, and `36` — all passed.
6. Original `37` report — reporting-only ambiguity.
7. `corrections/v0_2R2_detail_report/37...v0_2R2.sql` — completed fourteen evidence exports.

## Future clean execution

The original source and corrections are preserved as an audit trail. Before a clean replay, consolidate the v0.2R1 pre-open behavior into the generation blueprint or execute the governed 32A correction before positive validation. Use the v0.2R2 detail-report script for evidence export. No untested consolidated SQL is represented as live-accepted in this package.
