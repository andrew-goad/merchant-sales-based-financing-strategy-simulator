# M1.6 Live-Execution Evidence Review and Formal Sign-Off

## Final determination

**M1.6 — Matched POS and Deposit Scenario Overlay Generation v0.2R3: PASSED AND ACCEPTED**

The complete evidence set supports formal acceptance of the matched baseline and recession/energy scenario histories.

## Acceptance controls

| Control | Accepted result |
|---|---:|
| Run status | `M1_6_ACCEPTED` |
| Acceptance gate | `M1_6_MATCHED_SCENARIO_OVERLAYS` — PASS |
| Approved scenarios | 2 |
| Merchants / dates | 750 / 180 |
| POS scenario rows | 270,000 |
| Deposit scenario rows | 270,000 |
| Expected / actual canonical entities | 540,000 / 540,000 |
| Row-level deterministic mismatches | 0 |
| Positive validations | 62 / 62 PASS |
| Negative controls | 5 / 5 PASS |
| Failed evidence records | 0 |
| Blocking resolution errors | 0 |
| Downstream analytical rows | 0 |
| Master report | `overall_m1_6_status = PASS` |

## Accepted hashes

```text
POS scenario set       54793b3be9f6832f9bda5b4a30bf6569
Deposit scenario set   7c55c8ce6c74e965959e1c57921ca3b8
Combined scenario set  3f85921bf6fc30ddc6cee146085e58c5
```

For each scenario set, the stored, expected, and actual hashes match exactly.

All accepted upstream identities also remained unchanged:

```text
Parameter snapshot   bd09e598c82db96e47459d77fd11e7c8
Profile snapshot     462cbd2ed92f68e5bdecf6b17537a973
Source snapshot      93c3d1368fb2450ab4a08e2b721f92d3
Population hash      9b706c926260a3ef1ae8ac95eed5d0bf
Application hash     01485256b9b5748fb412743d35ced602
Baseline POS hash    d1971e8d319483c187ec0c0483a31e33
Baseline deposit hash bbe96dd24fbbba3af4a587dd475a88d0
```

## Scenario evidence

The `BASELINE` scenario exactly reproduces the accepted M1.4 POS and M1.5 deposit histories. The `RECESSION_ENERGY` scenario preserves the same 750 merchants and 180 dates, applies a governed 60-day direct stress window, and begins propagated-industry effects after a seven-day lag.

```text
Direct stress rows       45,000
Propagated stress rows   39,750
Pre-shock rows           90,000
```

Across the full 180-day panel, the stress sensitivity produced:

```text
Gross POS sales         $448,665,263.23 → $425,933,436.56  (5.07% decline)
Eligible POS sales      $434,530,056.67 → $411,719,355.26  (5.25% decline)
Deposits                $382,920,906.66 → $362,043,641.26  (5.45% decline)
Withdrawals             $340,378,208.08 → $363,887,723.61  (6.91% increase)
NSF events              527 → 912
Negative-balance share  5.6281% → 12.2526%
Support deposits        $15,277,074.22 under stress
```

The industry-transmission results preserve the intended sensitivity ordering: energy-services gross sales declined 31.22%, compared with 11.62% for healthcare services.

## Correction history reviewed

1. **v0.2 original generation design.** A derived-CTE self-join created an unacceptable POS-blueprint runtime. The transaction was cancelled and rolled back; no M1.6 rows committed.
2. **v0.2R1 performance correction.** The POS path was improved, but the deposit blueprint remained CPU-bound. The attempt was cancelled and rolled back; no M1.6 rows committed.
3. **v0.2R2 comprehensive performance correction.** The accepted M1.5 physical history became the deposit source of truth, stress-only windows were isolated, deterministic calculations were reduced, snapshots were materialized once, and downstream scripts stopped rebuilding wide blueprints. Generation completed with 540,000 canonical entities and zero mismatches.
4. **v0.2R3 settlement-lag validation correction.** The initial R2 validation passed 61 of 62 controls. The only failure treated valid left-boundary settlement carry-in as a lag violation. The fail-closed diagnostic confirmed:
   - zero within-panel lag violations;
   - zero boundary-copy violations;
   - zero unexpected missing prior rows;
   - 1,460 original exceptions exactly matching nonzero accepted carry-in rows.

   No scenario row or hash changed. The corrected validation then passed 62 of 62 controls.

## Evidence sufficiency

The evidence set includes recovery and preflight results, successful generation, the initial validation finding, fail-closed boundary diagnosis, final positive validation, negative controls, acceptance result, master report, sixteen detailed reports, zero-row mismatch and blocking-error exports, and full persisted M1.6 evidence.

Execution logs are excluded under the accepted project evidence policy.

## Scope boundary

This sign-off accepts synthetic matched POS and deposit scenario overlays only. It does not validate real economic forecasts, calibrated macroeconomic transmission, production stress models, source quality, credit risk, pricing, servicing, accounting, capital, fair lending, legal or regulatory compliance, or production use.

## Authorization

> **M1.6 is passed and accepted. M1.7 — Source Quality & Data Confidence is authorized.**
