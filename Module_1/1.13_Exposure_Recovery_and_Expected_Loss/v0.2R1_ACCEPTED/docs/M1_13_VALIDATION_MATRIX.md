# M1.13 Validation Matrix

M1.13 requires:

```text
82 positive controls
7 negative controls
20 detailed evidence result sets
```

Positive controls cover accepted lineage, policy configuration, frozen
parameters, scenario scope, path cardinality, exposure arithmetic, timing
weights, EAD identities, recovery/LGD bounds, comparative-loss identities,
stress non-improvement, routing, deterministic hashes, and stage boundaries.

Negative controls prove fail-closed handling of disabled generation, unapproved
policy, invalid methodology basis, invalid timing weights, unapproved stress
scenario, prerequisite-status drift, and attempted rerun.

The full machine-readable inventory is in
`catalogs/M1_13_VALIDATION_MATRIX.csv`.
