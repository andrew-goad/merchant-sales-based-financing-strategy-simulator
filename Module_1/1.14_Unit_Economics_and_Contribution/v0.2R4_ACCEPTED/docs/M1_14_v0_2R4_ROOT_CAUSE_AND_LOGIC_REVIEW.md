# M1.14 v0.2R4 Root-Cause and Logic-Preservation Review

## Root cause

The persisted row hash is defined over the physical columns of
`application_unit_economics_snapshot`, excluding only `row_hash` and
`created_at`.

Program 103 enriched the row with `scenario_code` and then hashed the enriched
record. The extra nonphysical field changes the JSON representation and
therefore the MD5 for every snapshot.

## Why generation is valid

Program 102 used `m1_14_actual_snapshot`, which reads the physical table and
recomputes the canonical hash correctly. It reconciled all 22,500 canonical
entities with zero mismatches. Program 105 independently performed the same
physical-row check and reported zero snapshot mismatches.

## Executable changes

The only validation-logic correction is POS26:

- **Before:** hash `_m1_14_vs`, which includes `scenario_code`.
- **After:** hash `application_unit_economics_snapshot` directly.

Programs 104, 106, and 107 are executable-logic equivalent to R3 after comments
and version headers are removed. Program 105 differs only in the acceptance
note revision string. No unit-economics formula, evidence gate, stress floor,
tier, threshold, hash function, cardinality, negative control, or acceptance
criterion changed.

## Clean-build source disposition

The clean-build replacement set preserves the successful R3 preparation,
preflight, generation, and generation-reconstruction programs. It replaces
validation through reporting with R4 source.
