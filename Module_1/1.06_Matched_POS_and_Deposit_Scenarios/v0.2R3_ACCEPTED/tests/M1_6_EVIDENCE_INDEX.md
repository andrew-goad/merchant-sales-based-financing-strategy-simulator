# M1.6 Evidence Index — Accepted v0.2R3

## Acceptance status

**M1.6 — Matched POS and Deposit Scenario Overlay Generation: PASSED AND ACCEPTED**

## Evidence set

| Evidence | Internal file | Disposition |
|---|---|---|
| Initial v0.2 preflight | `live_20260725/38_initial_v0_2_preflight.csv` | Historical PASS before cancelled original attempt |
| R2 recovery check | `live_20260725/37A_r2_aborted_generation_recovery.csv` | PASS; no scenario rows committed |
| R2 preflight | `live_20260725/38_r2_preflight.csv` | PASS |
| R2 generation checkpoint | `live_20260725/39_r2_generation_checkpoint.csv` | PASS; 270,000 POS and 270,000 deposit rows |
| Initial R2 positive validation | `live_20260725/40_r2_positive_validation_initial_fail.csv` | 61 PASS / 1 FAIL; boundary assumption identified |
| R3 settlement-lag diagnosis | `live_20260725/37B_r3_settlement_lag_recovery.csv` | PASS; zero true lag errors |
| Final R3 positive validation | `live_20260725/40_r3_positive_validation_final_pass.csv` | 62 / 62 PASS |
| Negative controls | `live_20260725/41_r3_negative_controls.csv` | 5 / 5 PASS |
| Acceptance finalizer | `live_20260725/42_r3_acceptance_finalize.csv` | PASS |
| Master report | `live_20260725/43_r3_master_report.csv` | `overall_m1_6_status=PASS` |
| Detailed reports | `live_20260725/detail_01...detail_16...` | Complete v0.2R3 evidence set |
| Deterministic mismatches | `live_20260725/detail_14_row_mismatches.csv` | Zero data rows |
| Blocking errors | `live_20260725/detail_16_blocking_errors.csv` | Zero data rows |

## Correction sources

- `corrections/v0_2R1_pos_blueprint_performance/`: first performance correction; superseded before commit.
- `corrections/v0_2R2_comprehensive_performance/`: accepted generation revision.
- `corrections/v0_2R3_settlement_lag_validation/`: accepted validation/reporting revision.

Execution logs are intentionally excluded under the accepted project evidence policy.
