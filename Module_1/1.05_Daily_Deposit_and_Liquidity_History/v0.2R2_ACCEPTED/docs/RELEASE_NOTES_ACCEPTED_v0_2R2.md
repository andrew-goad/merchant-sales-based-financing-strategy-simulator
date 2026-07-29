# Release Notes — M1.5 Accepted v0.2R2

## Acceptance milestone

M1.5 — Daily Deposit & Liquidity History Generation was accepted on 2026-07-25.

## Final results

```text
Deposit-day rows                  135,000
Merchants / dates                 750 / 180
Expected / actual rows            135,000 / 135,000
Deterministic mismatches          0
Positive checks                   56 / 56 PASS
Negative controls                 4 / 4 PASS
Failed evidence                   0
Blocking errors                   0
Downstream rows                   0
Deposit-history hash              bbe96dd24fbbba3af4a587dd475a88d0
```

## Controlled corrections

- v0.2R1: suppressed 16 pre-open NSF events and rebuilt affected hashes before acceptance.
- v0.2R2: qualified an ambiguous column in the read-only detail report; no data changes.

## Package changes

- Added complete structured live evidence.
- Added correction source and notes.
- Added validation history, evidence index, independent sign-off, milestone, and machine-readable summary.
- Authorized M1.6.
- Excluded execution logs under the accepted evidence policy.
