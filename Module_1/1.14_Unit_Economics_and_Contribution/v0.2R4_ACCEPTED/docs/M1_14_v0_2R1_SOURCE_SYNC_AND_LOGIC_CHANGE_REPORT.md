# M1.14 v0.2R1 Source Synchronization and Logic Change Report

## Finding

The v0.2 standalone and full-project ZIPs contained an older generation source
than the final M1.14 build workspace.

```text
Archived program-102 SHA-256
9e1a515681cb8abfc36dc0d7db23a81d856db133644e607b7bef5cf8f7cb8159

Final build-workspace program-102 SHA-256
7377b8a0900bb9fb3694a7a8d80a46c000a0ff1d192bdfd4688539f27f5ec6b8
```

Programs 103 and 105 were also stale in the archive. The R1 package eliminates
that mismatch by generating its manifest from the same files placed in the ZIP
and then re-extracting and hashing every archived file.

## Intentional executable changes

### Program 102

1. Null-safe stress-worsening flag.
2. Baseline-null-aware stress contribution and return floors.
3. Fail-closed hurdle-pass mapping.
4. Pre-persist target-Boolean guard.
5. Explicit persistent INSERT projections.
6. R1 run-note metadata.

### Program 103

1. Null-safe stress-worsening validation.
2. Fail-closed hurdle-pass validation.
3. R1 run-note metadata.

### Program 105

1. Baseline-null-aware stress contribution-floor acceptance test.
2. R1 run-note metadata.

## Logic-equivalent version-aligned files

The following R1 files differ from their v0.2 build-workspace source only in
comments, file names, or revision metadata:

```text
101 preflight
104 negative controls
106 master report
107 detailed report
102A generation reconstruction
```

No accepted upstream formula, parameter, scenario scope, row count, canonical
key, hash algorithm, positive-control count, negative-control count, report
result-set order, or stage boundary is changed by the hotfix.
