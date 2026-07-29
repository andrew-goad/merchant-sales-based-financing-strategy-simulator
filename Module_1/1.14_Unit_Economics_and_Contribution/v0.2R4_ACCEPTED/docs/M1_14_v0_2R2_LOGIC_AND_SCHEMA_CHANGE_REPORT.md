# M1.14 v0.2R2 Logic and Schema-Contract Change Report

## Intentional schema-contract change

`ck_m1_14_blocked` no longer requires these matched-baseline reference fields to
be NULL on blocked stress rows:

```text
baseline_risk_adjusted_contribution_amount
baseline_annualized_risk_adjusted_return_rate
```

It continues to require every current-scenario loss-dependent economic field to
be NULL.

## Business calculation logic

The transformation from accepted inputs through independent economics, matched
stress floors, economic tiers, statuses, fallback routing, and reason codes is
unchanged from v0.2R1.

The v0.2R2 additions are fail-closed guards and validation/acceptance checks for
the corrected physical contract.

## Downstream version alignment

Programs 104, 106, 107, and 102A differ from the synchronized source only in
revision metadata. Programs 101, 102, 103, and 105 contain the documented
constraint-aware checks. Program 100D is the current-database schema
remediation; the source-replacement program 100 contains the corrected clean
schema definition.
