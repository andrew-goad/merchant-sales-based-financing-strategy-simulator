# M1.8 Validation Matrix

M1.8 includes **60 blocking positive controls** and **6 fail-closed negative controls**.

Positive controls cover predecessor identity, row cardinality, source lineage, result mapping, fraud-score/tier reconstruction, continuity status, transparent routing, row and set hashes, stage boundaries and unresolved configuration errors.

Negative controls prove rejection of a disabled policy, invalid fraud thresholds, an unapproved policy, an inactive required check, prerequisite-status drift and attempted regeneration.

Acceptance requires all 66 controls to pass, exact canonical hashes, 4,500 check rows, 750 summaries, zero downstream rows and zero blocking errors.


## Accepted v0.2R1 validation correction

`M1_8_POS_48_STRESS_NONIMPROVEMENT` requires zero applications with a final stressed processor-continuity tier below baseline and requires the governed stress-floor policy to be enabled. The accepted validation implementation returns one 60-row result set rather than one result set per helper-function call.
