# M1.9 Accepted Execution Guide — v0.2R5

## Accepted status

- Stage: **M1.9 — As-of Cash-Flow Feature Engineering**
- Accepted package revision: `v0.2R5`
- Methodology: `M1_9_METHOD_V1`
- Annualization basis: `PERSISTED_ROUNDED_90D_AVERAGE`
- Annualization days: `365`
- Final run status: `M1_9_ACCEPTED`
- Acceptance gate: `M1_9_ASOF_CASHFLOW_FEATURES — PASS`

## Clean-build execution order

Use the clean-build source under `accepted_execution/` for a new environment:

1. `sql/60_msbf_m1_9_schema_policy_extension_v0_2R5.sql`
2. `tests/61_msbf_m1_9_preflight_validation_v0_2R5.sql`
3. `sql/62_msbf_m1_9_asof_cashflow_feature_generation_v0_2R5.sql`
4. `sql/63_msbf_m1_9_asof_cashflow_feature_validation_v0_2R5.sql`
5. `sql/64_msbf_m1_9_negative_control_tests_v0_2R5.sql`
6. `sql/65_msbf_m1_9_acceptance_finalize_v0_2R5.sql`
7. `tests/66_MSBF_M1_9_As_Of_Cash_Flow_Feature_Master_Report_v0_2R5.sql`
8. `tests/67_MSBF_M1_9_As_Of_Cash_Flow_Feature_Detail_Report_v0_2R5.sql`

`62A` is contingency-only and reconstructs the generation evidence after a successful commit if the DBeaver result tab is lost.

## Accepted outputs

```text
Wide scenario-aware snapshots       1,500
Long-form feature values           54,000
Governed features                      36
Canonical entities                 55,500
Positive validations           66 / 66 PASS
Negative controls                6 / 6 PASS
Row-level mismatches                     0
Annualized-sales identity errors         0
Blocking errors                          0
```

## Live acceptance history

The live accepted database path included controlled corrections through `v0.2R5`. See `M1_9_VALIDATION_HISTORY.md`, `source_history/`, and `evidence/` for the complete audit trail.
