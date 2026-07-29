# M1.5 Evidence Index — Accepted v0.2R2

## Acceptance status

**M1.5 — Daily Deposit & Liquidity History Generation: PASSED AND ACCEPTED**

## Evidence set

| Evidence | Internal file | Disposition |
|---|---|---|
| Preflight readiness | `live_20260725/31_preflight_evidence_note.txt` | Original PASS tab was lost; governed alternative evidence note retained |
| Generation checkpoint | `live_20260725/32_generation_checkpoint_reconstructed.csv` | PASS; committed 135,000-row history |
| Deterministic reconciliation | `live_20260725/32_generation_reconciliation.csv` | PASS; 0 mismatches |
| Persisted generation evidence | `live_20260725/32_persisted_generation_evidence.csv` | PASS |
| Pre-open NSF remediation | `live_20260725/32A_pre_open_nsf_remediation.csv` | PASS; 16 rows corrected before acceptance |
| Initial positive validation | `live_20260725/33_positive_validation_initial_fail.csv` | 55 PASS / 1 FAIL; defect detected |
| Final positive validation | `live_20260725/33_positive_validation_final_pass.csv` | 56 / 56 PASS |
| Negative controls | `live_20260725/34_negative_controls.csv` | 4 / 4 PASS |
| Acceptance finalizer | `live_20260725/35_acceptance_finalize.csv` | PASS |
| Master report | `live_20260725/36_master_report.csv` | `overall_m1_5_status=PASS` |
| Detailed reports | `live_20260725/detail_01...detail_14...` | Complete v0.2R2 evidence set |
| Deterministic mismatches | `live_20260725/detail_12_row_mismatches.csv` | Zero data rows |
| Blocking errors | `live_20260725/detail_14_blocking_errors.csv` | Zero data rows |

## Correction history

- `corrections/v0_2R1_pre_open_nsf/`: controlled generation-logic correction before acceptance.
- `corrections/v0_2R2_detail_report/`: reporting-only alias correction after acceptance; no database changes.

Execution logs are intentionally excluded under the accepted project evidence policy.
