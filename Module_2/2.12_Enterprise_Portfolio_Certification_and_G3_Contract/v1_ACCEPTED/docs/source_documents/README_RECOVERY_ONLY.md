# M2.12 Contingency-Only Recovery Sources

These four files are physically preserved approved SQL sources, but they are **not part of the normal execution chain**.

```text
Normal chain: 220 → 221 → 222 → 223 → 224 → 225 → 226 → 227
Recoveries:   220A, 222A, 222B, 223A
```

A recovery may be selected only after the failed program, transaction outcome, persistent-state checkpoint, and owned-sequence state have been diagnosed. Recovery execution requires explicit authorization. Do not execute a recovery speculatively, prophylactically, or merely because a normal program returned an error.

Current package state:

```text
READY FOR LIVE EXECUTION
NOT EXECUTED
NOT ACCEPTED
```
