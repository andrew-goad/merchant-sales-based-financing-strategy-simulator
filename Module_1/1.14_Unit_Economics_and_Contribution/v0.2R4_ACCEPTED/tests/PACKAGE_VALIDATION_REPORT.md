
# M1.14 Accepted Package Validation Report

## Status

**PASS — accepted package v0.2R4**

## Evidence validation

```text
Positive controls                         82 / 82 PASS
Negative controls                           7 / 7 PASS
Detail result sets                         20
Snapshot rows                           1,500
Component rows                         21,000
Canonical entities                     22,500
Snapshot hash mismatches                    0
Component hash mismatches                   0
Blocked-contract violations                 0
Blocking errors                             0
Final run status                  M1_14_ACCEPTED
```

## Source lineage

```text
Clean-build schema/policy        v0.2R3
Clean-build generation           v0.2R3
Clean-build validation           v0.2R4
Clean-build controls/acceptance  v0.2R4
Clean-build reports              v0.2R4
```

The final source files match the governed R3/R4 source replacements. The
committed v0.2R3 generation hashes reconcile to the final v0.2R4 validation and
acceptance evidence.

## Deterministic hashes

```text
Snapshot set   3c81b24f479b5fcc2db4b7667b8346ff
Component set  01df265884e0c157b5d3a3e4f3b76ce0
Combined set   3a47f59b56fa158c18c111caa1c64909
```

The module manifest and SHA-256 inventory are regenerated after final assembly.
