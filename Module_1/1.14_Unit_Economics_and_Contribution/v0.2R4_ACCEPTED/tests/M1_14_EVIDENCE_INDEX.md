# M1.14 Evidence Index

## Accepted live execution — 2026-07-27

| Sequence | Evidence | Purpose |
|---:|---|---|
1 | `live_20260727/100E_atomic_contract_repair_v0_2R3.csv` | Atomic migration from legacy blocked contract to approved V2 contract |
2 | `live_20260727/101_preflight_v0_2R3.csv` | Final hard-stop preflight |
3 | `live_20260727/102_generation_v0_2R3.csv` | Committed unit-economics generation and canonical reconciliation |
4 | `live_20260727/100F_snapshot_hash_validation_recovery_v0_2R4.csv` | Governed recovery from false POS26 validation failure |
5 | `live_20260727/103_positive_validation_v0_2R4.csv` | 82 positive controls |
6 | `live_20260727/104_negative_controls_v0_2R4.csv` | Seven fail-closed negative controls |
7 | `live_20260727/105_acceptance_finalize_v0_2R4.csv` | Final PASS gate and M1_14_ACCEPTED transition |
8 | `live_20260727/106_master_report_v0_2R4.csv` | One-row final acceptance/economics report |
9–28 | `live_20260727/detail_01_*` through `detail_20_*` | Twenty detailed evidence sets |

## Defect and review history

- `history/v0_2_nullable_stress_flag/` — pre-commit nullable Boolean finding.
- `history/v0_2R1_blocked_constraint/` — legacy blocked-contract finding.
- `history/v0_2R2_contract_sequence/` — failed preflight and contract-sequence weakness.
- `history/v0_2R3_snapshot_hash_validation/` — false enriched-row POS26 validation and failed review version 1.

## Formal acceptance records

- `M1_14_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF.md`
- `M1_14_LIVE_EXECUTION_VALIDATION_SUMMARY_v0_2R4.json`
- `MSBF_M1_14_Unit_Economics_Risk_Adjusted_Contribution_Build_Acceptance_Milestone_v0_2R4.txt`
- `ORIGINAL_FILENAME_MAP.csv`

Execution logs are optional under the accepted project evidence policy. The structured exports, deterministic reconciliation, fail-closed controls, master/detail reports, and documented correction history are sufficient for this synthetic governed project.
