# M1.2 Accepted Evidence Index

## Acceptance status

**PASSED AND ACCEPTED — 2026-07-24**

The evidence set consists of structured PostgreSQL result exports. Execution logs are intentionally not retained for this project.

## Governing records

- `M1_2_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF.md`
- `M1_2_LIVE_EXECUTION_VALIDATION_SUMMARY_v0_2.json`
- `MSBF_M1_2_Deterministic_Merchant_Population_Build_Acceptance_Milestone_v0_2.txt`

## Live result exports

- `live_20260724/09_msbf_m1_2_failed_generation_recovery_check_v0_2R2_results_20260724.csv` — Recovery-state confirmation after the pre-acceptance failed generation attempt.
- `live_20260724/10_msbf_m1_2_preflight_validation_v0_2_results_20260724.csv` — M1.2 preflight and unchanged G1 state.
- `live_20260724/11_msbf_m1_2_deterministic_merchant_population_v0_2_results_20260724.csv` — Deterministic population-generation checkpoint.
- `live_20260724/12_msbf_m1_2_population_validation_v0_2_results_20260724.csv` — Thirty-six positive validation checks.
- `live_20260724/13_msbf_m1_2_negative_control_tests_v0_2_results_20260724.csv` — Three fail-closed negative controls.
- `live_20260724/14_msbf_m1_2_acceptance_finalize_v0_2_results_20260724.csv` — Formal acceptance-finalizer output.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Blocking_Resolution_Errors_20260724.csv` — Expected zero-row blocking resolution-error export.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Entity_Row_Counts_20260724.csv` — Stage and downstream entity row counts.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Governed_Mix_Reconciliation_20260724.csv` — Target-versus-actual governed mix reconciliation.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_M1_2_Evidence_20260724.csv` — Persisted generation, positive, negative, and acceptance evidence.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Mixed_Signal_Examples_20260724.csv` — Row-level mixed-signal realism examples.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Owner_Guarantor_Diagnostics_20260724.csv` — Owner-credit, adverse-event, and guarantee diagnostics.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Processor_And_Partner_Diagnostics_20260724.csv` — Processor and acquisition-channel diagnostics.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Relationship_Stage_Diagnostics_20260724.csv` — Relationship-history diagnostics by stage.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Row_Level_Deterministic_Mismatches_20260724.csv` — Expected zero-row deterministic mismatch export.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Detail_Report_v0_2_Run_And_Acceptance_State_20260724.csv` — Detailed accepted run and population state.
- `live_20260724/MSBF_M1_2_Deterministic_Merchant_Population_Master_Report_v0_2_20260724.csv` — One-row consolidated M1.2 acceptance report.

## Acceptance highlights

- 750 merchants and 1,347 owner/guarantor rows.
- 4,352 expected and actual canonical entities.
- Zero row-level mismatches.
- All 30 governed mix categories reconcile with zero deltas.
- 36/36 positive checks and 3/3 negative controls pass.
- Zero blocking errors and zero downstream analytical rows.
- Master report and formal gate both equal `PASS`.
