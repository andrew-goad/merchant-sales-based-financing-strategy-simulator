# M1.5 Live-Execution Evidence Review and Formal Sign-Off

## Final determination

**M1.5 — Daily Deposit & Liquidity History Generation v0.2R2: PASSED AND ACCEPTED**

The complete evidence set supports formal acceptance of the deterministic baseline operating-account history.

## Acceptance controls

| Control | Accepted result |
|---|---:|
| Run status | `M1_5_ACCEPTED` |
| Acceptance gate | `M1_5_DAILY_DEPOSIT_LIQUIDITY` — PASS |
| Merchants / dates / rows | 750 / 180 / 135,000 |
| Expected / actual canonical rows | 135,000 / 135,000 |
| Row-level deterministic mismatches | 0 |
| Deposit-history set hash | `bbe96dd24fbbba3af4a587dd475a88d0` |
| Positive validations | 56 / 56 PASS |
| Negative controls | 4 / 4 PASS |
| Failed evidence | 0 |
| Blocking resolution errors | 0 |
| Downstream and scenario rows | 0 |
| Master report | `overall_m1_5_status = PASS` |

## Accepted portfolio evidence

```text
Total deposits                    $382,920,906.66
Total withdrawals                 $340,378,208.08
Withdrawal / deposit ratio               0.88889951
Portfolio ending balance           $62,036,399.93
Minimum observed balance             -$41,280.51
Negative-balance rows                       7,598
NSF events                                     527
Support-deposit rows                        3,882
Support-deposit amount               $3,609,045.82
Active existing-financing merchants            94
Existing-financing remittance rows           5,542
```

## Corrections reviewed

1. **v0.2R1 generation logic.** The first validation found 16 pre-open NSF events. A controlled correction changed only the affected NSF fields and row hashes, restored zero pre-open violations, and produced exact expected/actual/stored reconciliation.
2. **v0.2R2 detail reporting.** An ambiguous read-only reporting reference was qualified. The corrected detailed report ran successfully without changing accepted data or evidence.

## Evidence sufficiency

The original preflight PASS result tab was lost when DBeaver became unresponsive. This does not prevent acceptance because generation committed only after the fail-closed readiness function succeeded, upstream hashes remained unchanged, all 135,000 expected and actual rows reconcile, the generation evidence was persisted, all positive and negative controls passed after correction, and the final acceptance/master/detail reports are complete. The explanatory preflight evidence note is retained.

## Scope boundary

This sign-off accepts synthetic latent operating-account history only. It does not validate real bank statements, production transaction categorization, calibrated liquidity behavior, source observability, economic forecasts, credit risk, pricing, servicing, legal or regulatory compliance, accounting, capital, fair lending, or production use.

## Authorization

> **M1.5 is passed and accepted. M1.6 — Matched POS and Deposit Scenario Overlay Generation is authorized.**
