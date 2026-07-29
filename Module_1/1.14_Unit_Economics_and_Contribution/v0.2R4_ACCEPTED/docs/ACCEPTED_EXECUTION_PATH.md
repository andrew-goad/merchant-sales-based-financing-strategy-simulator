
# M1.14 Accepted Execution Path

## Accepted database lineage

```text
M1_13_ACCEPTED
→ v0.2 schema/policy extension
→ v0.2R3 atomic blocked-contract preparation
→ v0.2R3 hard-stop preflight
→ v0.2R3 generation: 22,500 canonical entities, zero mismatches
→ v0.2R4 governed recovery from false POS26 validation
→ v0.2R4 82/82 positive controls
→ v0.2R4 7/7 negative controls
→ v0.2R4 acceptance review version 2 PASS
→ M1_14_ACCEPTED
```

The top-level `sql` and `tests` directories contain the final clean-build source.
The `accepted_execution` directory preserves the exact programs used to reach
the accepted live state. Historical versions remain under `source_history`.
