# Release Notes — MSBF M1.4 v0.2 Accepted

## Acceptance milestone

M1.4 — Enterprise Merchant Ecosystem / Daily POS & Settlement History was accepted on 2026-07-24.

## Accepted results

```text
Baseline POS-day rows             135,000
Accepted merchants                   750
Governed dates                        180
Expected / actual rows          135,000 / 135,000
Row-level mismatches                       0
Positive validations                 52 / 52 PASS
Negative controls                      4 / 4 PASS
Failed evidence                              0
Downstream rows                              0
Blocking errors                              0
POS-history set hash          d1971e8d319483c187ec0c0483a31e33
```

## Accepted scope

- Deterministic 180-day baseline merchant POS and processor-settlement history.
- Industry, archetype, weekday, seasonality, trend, volatility, calendar, and bounded operating-event behavior.
- Gross-to-eligible-sales, processor-fee, lagged-settlement, and net-proceeds reconciliation.
- Processor status and data-connection continuity.
- Full row-level and population-level deterministic reproduction.
- Strict exclusion of scenarios, deposits, source-quality snapshots, features, risk, EAD, latest, and archive outputs.

## Package changes

- Added all structured live-execution result exports.
- Added independent evidence review and formal sign-off.
- Added completed M1.4 acceptance milestone.
- Added machine-readable live-validation summary.
- Updated package status from build-ready to accepted.
- Authorized M1.5 — Daily Deposit & Liquidity History Generation.
- Execution logs remain excluded under the accepted project evidence policy.
