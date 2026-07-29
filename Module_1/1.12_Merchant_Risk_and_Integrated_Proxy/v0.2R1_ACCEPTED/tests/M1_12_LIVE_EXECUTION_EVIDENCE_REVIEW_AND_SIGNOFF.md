# M1.12 Live-Execution Evidence Review and Formal Sign-Off

## Final disposition

**M1.12 — Merchant Risk Components & Integrated Risk Proxy is PASSED and ACCEPTED.**

- Accepted package revision: `v0.2R1`
- Accepted generation, validation, negative-control, acceptance, and master-report revision: `v0.2`
- Accepted detail-report revision: `v0.2R1`
- Accepted methodology: `M1_12_METHOD_V1`
- Composite-score basis: `SUM_PERSISTED_WEIGHTED_RISK_COMPONENTS`
- Stress score floor: enabled
- Stress tier floor: enabled
- Final run status: `M1_12_ACCEPTED`
- Acceptance gate: `M1_12_INTEGRATED_RISK_PROXY — PASS`
- Database acceptance timestamp: `2026-07-26 18:11:32.008 -0400`
- Independent evidence review date: `2026-07-26`

## Acceptance summary

| Validation area | Final result |
|---|---:|
| Applications | 750 |
| Matched scenarios | 2 |
| Integrated-risk snapshots | 1,500 |
| Long-form component rows | 10,500 |
| Governed risk components | 7 |
| Canonical entities | 12,000 |
| Positive validations | 80 / 80 PASS |
| Negative controls | 7 / 7 PASS |
| Deterministic mismatches | 0 |
| Composite-identity violations | 0 |
| Synthetic-proxy identity violations | 0 |
| Stress score improvements | 0 |
| Stress tier improvements | 0 |
| Failed final evidence records | 0 |
| Blocking resolution errors | 0 |
| Downstream EAD / latest / archive rows | 0 |
| Overall master-report status | PASS |

## Deterministic reconciliation

```text
Integrated-risk snapshot set
309c4f76d5f88a352ec58ebaa10cce0b

Integrated-risk component set
d190ae7a88ad03d836ef3cb4a0ba85f9

Combined M1.12 set
fb583c3fdd92f141ba5af1ddf942ffba
```

The stored and independently reconstructed hashes match for all three sets. The 12,000-entity canonical universe contains zero row-level mismatches.

## Accepted portfolio evidence

```text
Average integrated risk score       29.386560
Average synthetic risk proxy         0.293866

Complete evidence rows                    166
Partial evidence rows                     736
Blocked evidence rows                     598

Tier 1 rows                               214
Tier 2 rows                               476
Tier 3 rows                               212
Tier 4 rows                                 0
Tier 5 / insufficient-evidence rows       598

Available component rows                8,947
Unavailable component rows              1,553

Stress worsenings                         311
Stress score improvements                   0
Stress tier improvements                    0

Manual-review rows                       1,484
Hard-stop rows                             234
```

Baseline scored rows average `26.609084`; recession-stress scored rows average `34.638839`. Matched stress migration contains no score or tier improvement.

The high manual-review incidence is retained transparently. It reflects conservative upstream data-confidence, verification, capacity, resilience, and routing conditions. It is a downstream calibration consideration rather than a structural acceptance defect in this synthetic risk-evidence module.

## Report-only correction history

Programs 84 through 90 completed successfully. The original v0.2 detail report produced its first nineteen read-only result sets and then failed in result set 20 because the query ordered `msbf_ctl.profile_resolution_error` by a nonexistent `error_id` column.

The v0.2R1 detail report corrected only that final result set by:

- explicitly selecting the governed resolution-error fields; and
- ordering by `resolution_error_id`.

No persistent DML, generation formula, component calculation, score, tier, routing result, validation control, acceptance condition, business row, or hash changed. The corrected report produced all twenty result sets; the deterministic-mismatch and blocking-error sets retain headers and contain zero rows.

## Stage-boundary confirmation

M1.12 did not create calibrated probability of default, EAD, LGD, Expected Loss, pricing, offers, final credit decisions, or Module 1 latest/archive outputs.

## Sign-off

> **M1.12 is formally accepted. M1.13 — Exposure, Recovery & Expected Loss Foundations is authorized.**
