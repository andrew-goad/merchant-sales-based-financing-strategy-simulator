# M1.15 Evidence Index

## Accepted live execution — 2026-07-27

| Sequence | Evidence | Purpose |
|---:|---|---|
| 1 | `live_20260727/108_schema_policy_contract_extension_v0_2.csv` | Schema, policy, registry, tables, trigger, and views |
| 2 | `live_20260727/108B_recovery_function_repair_v0_2R1.csv` | Recovery and installed readiness-function repair |
| 3 | `live_20260727/108C_evidence_union_recovery_v0_2R2.csv` | Pristine-state and evidence-type recovery validation |
| 4 | `live_20260727/109_preflight_v0_2R2.csv` | Accepted hard-stop preflight |
| 5 | `live_20260727/110_generation_v0_2R2.csv` | Committed latest/archive/comparison generation and canonical reconciliation |
| 6 | `live_20260727/108D_resilience_validation_recovery_v0_2R3.csv` | Governed recovery from POS62 contract-alignment finding |
| 7 | `live_20260727/111_positive_validation_v0_2R3.csv` | 84 positive controls |
| 8 | `live_20260727/112_negative_controls_v0_2R3.csv` | Seven fail-closed negative controls |
| 9 | `live_20260727/113_acceptance_finalize_v0_2R3.csv` | Final PASS acceptance and contract transition |
| 10 | `live_20260727/114_master_report_v0_2R3.csv` | One-row final contract and gate report |
| 11–30 | `live_20260727/detail_01_*` through `detail_20_*` | Twenty detailed evidence sets |

## Defect and review history

- `history/v0_2_ambiguous_join/` — ambiguous scenario binding stopped initial generation before commit.
- `history/v0_2R1_evidence_union/` — target-type resolution defect stopped R1 generation before commit.
- `history/v0_2R2_resilience_validation/` — committed generation and initial 83-of-84 POS62 result.

## Formal acceptance records

- `M1_15_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF.md`
- `M1_15_LIVE_EXECUTION_VALIDATION_SUMMARY_v0_2R3.json`
- `MSBF_M1_15_Consumption_Contract_Build_Acceptance_Milestone_v0_2R3.txt`
- `ORIGINAL_FILENAME_MAP.csv`

Structured exports, exact canonical reconciliation, archive immutability controls, fail-closed negative controls, master/detail reporting, and documented correction history are sufficient under the accepted synthetic-project evidence standard.
