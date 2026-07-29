# M1.8 Parameter Dictionary

M1.8 uses accepted frozen run parameters plus an effective-dated methodology policy profile. No accepted G1 parameter snapshot is rewritten.

## Run Parameters

| Parameter | Scope | Baseline | Purpose |
|---|---|---:|---|
| `fraud_base_probability` | `GLOBAL` | 0.015 | Synthetic base probability converted to fraud-score points. |
| `bank_account_mismatch_fraud_points` | `GLOBAL` | 40 | Points when bank-account ownership mismatch is observed. |
| `processor_mismatch_fraud_points` | `GLOBAL` | 35 | Points when processor-account mismatch is observed. |
| `identity_conflict_fraud_points` | `GLOBAL` | 30 | Points for identity or ownership conflict evidence. |
| `abnormal_refund_fraud_points` | `GLOBAL` | 12 | Points for abnormal refund-rate evidence. |
| `abnormal_chargeback_fraud_points` | `GLOBAL` | 18 | Points for abnormal chargeback-rate evidence. |
| `fraud_tier_2_threshold` | `GLOBAL` | 10 | Tier-2 fraud-score threshold. |
| `fraud_tier_3_threshold` | `GLOBAL` | 25 | Tier-3 fraud-score threshold. |
| `fraud_tier_4_threshold` | `GLOBAL` | 45 | Tier-4 fraud-score threshold. |
| `fraud_tier_5_threshold` | `GLOBAL` | 70 | Tier-5 fraud-score threshold. |
| `verification_hard_stop_check` | `VERIFICATION_CHECK:*` | Scoped | Whether FAIL/UNAVAILABLE check evidence recommends a hard stop. |
| `verification_review_check` | `VERIFICATION_CHECK:*` | Scoped | Whether the check is configured for review routing. |

## Policy-Profile Constants

| Constant | Value |
|---|---:|
| `generation_enabled` | `True` |
| `methodology_version` | `M1_8_METHOD_V1_1` |
| `stress_continuity_tier_floor_to_baseline` | `true` |
| `recent_window_days` | `30` |
| `kyb_fail_multiplier` | `0.4` |
| `beneficial_owner_fail_multiplier` | `0.55` |
| `sanctions_fail_multiplier` | `0.05` |
| `bank_account_mismatch_multiplier` | `0.75` |
| `processor_mismatch_multiplier` | `0.65` |
| `identity_conflict_multiplier` | `0.5` |
| `review_band_multiplier` | `1.5` |
| `refund_rate_multiplier_threshold` | `1.5` |
| `refund_rate_absolute_floor` | `0.035` |
| `chargeback_rate_multiplier_threshold` | `1.75` |
| `chargeback_rate_absolute_floor` | `0.008` |
| `continuity_tier_2_degraded_rate` | `0.01` |
| `continuity_tier_3_degraded_rate` | `0.03` |
| `continuity_tier_4_degraded_rate` | `0.08` |
| `continuity_tier_2_outage_rate` | `0.001` |
| `continuity_tier_3_outage_rate` | `0.005` |
| `continuity_tier_4_outage_rate` | `0.015` |
| `continuity_tier_2_connection_gap_rate` | `0.01` |
| `continuity_tier_3_connection_gap_rate` | `0.03` |
| `continuity_tier_4_connection_gap_rate` | `0.08` |
| `continuity_tier_2_recent_outage_rate` | `0.0` |
| `continuity_tier_3_recent_outage_rate` | `0.01` |
| `continuity_tier_4_recent_outage_rate` | `0.03` |
| `manual_review_fraud_tier` | `3` |
| `hard_stop_fraud_tier` | `5` |
| `manual_review_continuity_tier` | `3` |
| `hard_stop_continuity_tier` | `5` |

All values are synthetic demonstration assumptions and require formal production calibration and approval.

## Accepted v0.2R1 methodology correction

The adverse-scenario continuity tier is governed by:

```text
Final Stress Continuity Tier
=
greatest(Baseline Continuity Tier, Independently Classified Stress Continuity Tier)
```

Observed processor rates remain unchanged. The floor affects only the interpreted stressed tier and downstream routing evidence.
