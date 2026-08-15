# M2.10 Recovery Guide

## Failed Program 204

Stop, run `ROLLBACK;`, then run 204A. Accepted M2.9 must remain unchanged and
M2.10 objects must remain absent.

## Failed or cancelled Program 206

Stop, run `ROLLBACK;`, then run 206A. Programs 204 and 205 remain authoritative
and generated M2.10 targets must remain empty.

## Lost Program 206 result tab

Run 206B. It reconstructs counts, KPIs, burden, hashes, canonical identity,
and stress diagnostics without writes.

## Failed Program 207

Stop, run `ROLLBACK;`, then run 207A before rerunning Program 207.


## Program 207 v0.2R2 resume

```text
ROLLBACK; → 207A v0.2R2 → 207 v0.2R2 → 208
```

Do not rerun Programs 204–206.
