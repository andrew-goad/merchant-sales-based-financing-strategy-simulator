# M1.16 Evidence Index

## Accepted live execution — 2026-07-28

| Sequence | Evidence | Purpose |
|---:|---|---|
| 1 | `live_20260728/116_schema_policy_extension_v0_2.csv` | Schema, policy, dictionaries, contracts, archive trigger, and views |
| 2 | `live_20260728/116B_campaign_projection_recovery_v0_2R1.csv` | Recovery from the pre-commit campaign projection failure |
| 3 | `live_20260728/117_preflight_v0_2R1.csv` | Accepted hard-stop preflight |
| 4 | `live_20260728/118_generation_v0_2R1.csv` | Committed acquisition generation and canonical reconciliation |
| 5 | `live_20260728/116C_parent_reconciliation_recovery_v0_2R2.csv` | Governed POS087 validation recovery |
| 6 | `live_20260728/116D_generation_evidence_count_recovery_v0_2R3.csv` | Governed POS050 evidence-inventory recovery |
| 7 | `live_20260728/119_positive_validation_v0_2R3.csv` | 112 positive controls |
| 8 | `live_20260728/120_negative_controls_v0_2R3.csv` | 20 fail-closed negative controls |
| 9 | `live_20260728/121_acceptance_finalize_v0_2R3.csv` | Final PASS acceptance and contract transition |
| 10 | `live_20260728/122_master_report_v0_2R3.csv` | One-row acquisition contract and gate report |
| 11–34 | `live_20260728/detail_01_*` through `detail_24_*` | Twenty-four detailed evidence sets |

## Defect and validation history

- `history/v0_2_campaign_projection/` — Program 118 intermediate campaign projection stopped generation before commit.
- `history/v0_2R1_parent_reconciliation/` — committed generation and initial 111-of-112 POS087 result.
- `history/v0_2R2_generation_evidence_inventory/` — corrected POS087 and subsequent 111-of-112 POS050 result.

## Evidence filename note

The user-exported Program 116D CSV retained an earlier `failed_attribution_parent_reconciliation` filename. Its columns and content unambiguously document the POS050 generation-evidence-count recovery. The accepted package preserves the original filename in `ORIGINAL_FILENAME_MAP.csv` and stores the standardized evidence as `116D_generation_evidence_count_recovery_v0_2R3.csv`.

## Formal acceptance records

- `M1_16_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF.md`
- `M1_16_LIVE_EXECUTION_VALIDATION_SUMMARY_v0_2R3.json`
- `MSBF_M1_16_Acquisition_Foundations_Build_Acceptance_Milestone_v0_2R3.txt`
- `ORIGINAL_FILENAME_MAP.csv`
