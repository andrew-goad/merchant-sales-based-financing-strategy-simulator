# M2.1 Validation and Correction History

## Accepted revision stack

```text
Schema and policy extension       v0.2
Preflight and generation          v0.2R1
Final positive validation         v0.2R6
Final negative controls           v0.2R6
Acceptance and reports            v0.2R7
Final accepted package            v0.2R7
```

## Governed history

### Original schema/policy extension

Program 132 created the M2.1 physical tables, policy, one strategy campaign, 12 gates, 23 transparent reasons, four route definitions, contract registry, immutability controls, and consumption views. It completed successfully.

### R1 — stage-boundary preflight and processor continuity

The preflight counted a governance dictionary field as a prohibited application output. Recovery proved that `production_adverse_action_flag` was a control field and all values were false. The prohibited-output predicate was scoped to application contracts. The same audit found that `UNAVAILABLE` processor continuity would pass; the gate was corrected to review. Preflight and Program 134 generation then completed successfully.

### R2/R3 — validation syntax and recovery view

A generated validation expression and the first recovery query contained syntax/object-reference defects. The R2 repair was superseded and preserved as history. R3 restored the authoritative validation source, corrected only the true parser defects, and used `v_m2_1_matched_scenario_comparison` rather than a nonexistent table.

### R4 — campaign physical-row hash

POS023 returned one mismatch because the campaign seed used JSON key `run_id` while the persisted row uses `module1_run_id`. R4 replaced the seed-alias hash with the physical-row hash and atomically synchronized campaign, registry, contract, combined, and generation-evidence hashes. Revalidation returned 112 of 112 passes.

### R5 — negative-control boundary assertions

The original configuration assertion did not compare two physical boundary flags to the governed payload. R5 strengthened the configuration and acceptance assertions, proved both mutations were rejected, and preserved the 18-of-20 failed execution as superseded history.

### R6 — validation context and final controls

The enhanced POS002 referenced four boundary fields that were absent from `_m2_1_vctx`. R6 projected the fields, verified payload alignment, and completed 112 of 112 positive controls and 20 of 20 negative controls.

### R7 — acceptance namespace

The initial acceptance query exposed overlapping registry and physical count names. R7 narrowed the registry projection and qualified every acceptance field. The finalizer issued `M2_1_ELIGIBILITY_POLICY_ROUTING = PASS`; the master report passed; all 24 detailed reports completed.

## Closure

No correction changed accepted Module 1/G2 records or regenerated the committed M2.1 gate, routing, latest, archive, or comparison populations after Program 134. The accepted state contains zero current failed evidence rows, zero deterministic mismatches, and zero blocking/stage-boundary violations.
