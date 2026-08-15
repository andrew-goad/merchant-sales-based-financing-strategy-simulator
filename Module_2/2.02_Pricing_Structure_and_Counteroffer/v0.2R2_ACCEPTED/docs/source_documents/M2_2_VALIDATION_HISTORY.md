# M2.2 Validation and Correction History

## Original v0.2

Programs 140 and 141 completed successfully. The first Program 142 execution
reached deterministic reconciliation with the correct 7,336 canonical entities,
557 candidates, and 750 comparisons, but reported 806 row-hash mismatches.

## v0.2R1 — Target-Typed Hash Reconciliation

The candidate and selected pricing-snapshot staging records were hashed before
their numeric fields were coerced to the physical table typmods. PostgreSQL
persisted numerically equivalent values with different JSON text scales,
changing row hashes.

v0.2R1 introduced exact target-typed staging before hashing. No candidate
formula or business outcome changed.

## v0.2R2 — Selected-Structure Stress Floor

After the typmod repair, Program 142 correctly reached the stress
non-improvement assertion and identified nine favorable stress structures.
The original floor compared candidates within the same template. Ten accepted
applications changed from baseline `STRUCTURE_READY` to stress
`COUNTEROFFER_FOUNDATION_REVIEW`, changing the selected template family. Nine
selected stress structures therefore bypassed the template-level floor.

v0.2R2 added a matched selected-structure floor across funding amount,
remittance rate, payback multiple, and collection horizon. It adjusted exactly
nine stress rows and reduced post-floor improvements to zero.

## Final accepted result

```text
M2_2_ACCEPTED
Contracts ACCEPTED
Acceptance gate PASS
120 / 120 positive PASS
20 / 20 negative PASS
0 deterministic mismatches
0 blocking/stage-boundary violations
```
