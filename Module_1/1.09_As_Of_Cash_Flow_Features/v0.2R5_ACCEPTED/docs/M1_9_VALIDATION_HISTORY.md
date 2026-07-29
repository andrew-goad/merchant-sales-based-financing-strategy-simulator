# M1.9 Validation and Correction History

M1.9 preserves the full build-and-validation history rather than presenting only the final result.

## v0.2 — scenario registry scope

The initial preflight counted all globally approved `BASELINE` and `RECESSION_ENERGY` registry rows. Two legitimate scenario sets produced `4 / 2 / 2` rather than the accepted M1.6 panel's `2 / 1 / 1`. v0.2R1 selected the scenario IDs actually represented in the accepted M1.6 POS and deposit panels.

## v0.2R2 — duplicate CTAS projection

Generation used `a.merchant_application_id` together with `sa.*`, where `sa.*` also contained `merchant_application_id`. PostgreSQL rejected the duplicate output name before persistence. v0.2R2 replaced the wildcard with an explicit projection and audited downstream joins.

## v0.2R3 — canonical numeric scale

Generation reached the full 55,500-entity reconciliation but long-form numeric hashes differed because the expected preimage used unconstrained numeric scale while the physical target is `numeric(24,10)`. v0.2R3 normalized the canonical preimage to the physical type. Generation then passed and committed.

## v0.2R4 — aggregate FILTER syntax

The first validation attempt attached `FILTER` to scalar `md5()` rather than aggregate `string_agg()`. v0.2R4 corrected all downstream instances and preserved the committed generation.

## v0.2R5 — annualized-sales identity

The R4 validation correctly detected 856 visible annualized-sales identity exceptions and 616 availability mismatches. The governed definition was clarified as:

```text
Annualized Eligible Sales
=
round(Persisted Rounded 90-Day Average × 365, 2)
```

The controlled remediation updated 1,472 wide snapshots and the corresponding 1,472 long-form values, rebuilt row and set hashes, and produced zero remaining identity or availability mismatches. Validation then passed 66 of 66 controls.

## Final accepted position

- Accepted revision: `v0.2R5`
- Final hashes reconcile exactly.
- Positive validation: `66 / 66 PASS`
- Negative controls: `6 / 6 PASS`
- Annualized-sales identity violations: `0`
- Row-level deterministic mismatches: `0`
