# M1.13 Live Execution Evidence Review and Formal Sign-Off

## Milestone

**M1.13 — Exposure, Recovery & Expected Loss Foundations**

**Final determination: PASSED AND ACCEPTED**

```text
Accepted package revision             v0.2R1
Schema / policy extension revision    v0.2
Recovery through reporting revision   v0.2R1
Methodology                           M1_13_METHOD_V1
Final run status                      M1_13_ACCEPTED
Acceptance gate                       M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS — PASS
```

## Evidence reviewed

The acceptance review covered:

- the v0.2 schema and policy extension;
- the original successful v0.2 preflight;
- the pre-commit `max(boolean)` generation error;
- the v0.2R1 rollback-state and governed-parameter recovery check;
- the v0.2R1 preflight and corrected generation;
- 82 positive validation controls;
- seven negative controls;
- the acceptance finalizer;
- the one-row master report;
- all 20 detailed-report exports;
- row-level deterministic mismatch and blocking-error outputs.

## Acceptance results

| Control | Final result |
|---|---:|
| Applications | 750 |
| Matched scenarios | 2 |
| Daily EAD path rows | 93,720 |
| Exposure/recovery/loss snapshots | 1,500 |
| Canonical entities | 95,220 |
| Positive validations | 82 / 82 PASS |
| Negative controls | 7 / 7 PASS |
| Row-level deterministic mismatches | 0 |
| EAD identity violations | 0 |
| Recovery identity violations | 0 |
| Simple comparative-loss identity violations | 0 |
| Schedule-adjusted comparative-loss identity violations | 0 |
| Stress EAD improvements | 0 |
| Stress LGD improvements | 0 |
| Stress comparative-loss improvements | 0 |
| Downstream stage-boundary rows | 0 |
| Blocking resolution errors | 0 |
| Master report | PASS |

## Deterministic reconciliation

The stored, generated, and independently reconstructed hashes reconcile exactly:

```text
Daily exposure-path set
97fa026a0c3cb5ae8584e98cd0a34555

Exposure/recovery/loss snapshot set
6a6eca57842eeaf5bf3be775cdfda754

Combined M1.13 canonical set
11dca65763f4062ad9002244ee6452f9
```

The accepted upstream identities also remained unchanged:

```text
Population hash       9b706c926260a3ef1ae8ac95eed5d0bf
Application hash      01485256b9b5748fb412743d35ced602
Scenario-set hash     3f85921bf6fc30ddc6cee146085e58c5
Capacity-set hash     a91e82a315305a98953d013043a17d9a
Integrated-risk hash  fb583c3fdd92f141ba5af1ddf942ffba
```

## Accepted portfolio evidence

```text
Average initial contractual exposure        $30,333.38
Average path-weighted EAD                    $15,420.30
Average expected EAD rate                    0.465160
Average recovery-rate assumption             0.308757
Average LGD input rate                        0.691243

Total simple comparative loss                $6,439,459.43
Total schedule-adjusted comparative loss     $3,259,257.56

Partial evidence rows                        902
Blocked evidence rows                        598
Parameter-only recovery rows                 770
Recovery-conflict rows                       730
Manual-review rows                           1,486
Hard-stop rows                               234
```

No application had supported collateral or guarantee recovery evidence in this synthetic campaign. Recovery credit therefore remained zero, and the 1,500 snapshots were classified as either `PARTIAL` or `BLOCKED`, never `COMPLETE`. This is transparently retained as a modeling and future-data-development limitation rather than converted into unsupported recovery value.

## Stress interpretation

The matched adverse scenario produced:

```text
Path-weighted EAD worsenings     331
LGD worsenings                   750
Comparative-loss worsenings      312

EAD improvements                 0
LGD improvements                 0
Comparative-loss improvements    0
```

The published aggregate schedule-adjusted comparative-loss total is lower under stress
($1,368,832.52) than baseline ($1,890,425.04)
because stress evidence gating reduces published scored rows from 590 to
312; it does **not** represent an improved matched risk result. The
matched-row controls confirm zero EAD, LGD, or comparative-loss improvements.

## Correction history

The original v0.2 generation stopped before persistence because PostgreSQL does not support
`max(boolean)`. The v0.2R1 correction replaced the two Boolean parameter aggregations with governed
`bool_or(boolean)` expressions. The recovery check confirmed zero M1.13 business rows, evidence rows,
or gate rows before the corrected generation was executed.

Programs 93 and 95–99 were version-aligned to v0.2R1 without changing executable business or
acceptance logic. The generated population and all final evidence reconciled exactly.

## Stage boundary

M1.13 did not populate:

- calibrated PD;
- production EAD or LGD;
- CECL or accounting reserves;
- regulatory capital;
- pricing or offer outputs;
- approval, counteroffer, review, or decline decisions;
- legacy merchant-risk outputs;
- Module 1 latest or archive contract outputs.

## Formal authorization

> **M1.13 is passed and accepted. M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations is authorized.**

This acceptance applies only to the synthetic contractual-receivable exposure path, comparative
EAD, recovery/LGD assumptions, and comparative expected-loss foundations. It is not model-risk
approval, accounting certification, regulatory approval, or authorization for production use.
