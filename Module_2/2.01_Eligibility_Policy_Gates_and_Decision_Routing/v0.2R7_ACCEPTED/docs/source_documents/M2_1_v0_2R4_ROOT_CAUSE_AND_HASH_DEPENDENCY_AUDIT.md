# M2.1 v0.2R4 Root Cause and Hash-Dependency Audit

## Defect

The stored campaign hash was generated from:

```sql
msbf_ctl.m2_1_hash_jsonb(to_jsonb(seed))
```

The seed exposed `run_id`. The persisted campaign row exposes
`module1_run_id`. Physical reconstruction therefore failed even though every
business attribute was unchanged.

## Dependent identities

The campaign row hash feeds:

1. `campaign_set_hash`
2. contract-registry `row_hash`
3. `contract_set_hash`
4. the 22,541-entity `combined_set_hash`
5. generation evidence `M2_1_CAMPAIGN_SET_HASH`
6. generation evidence `M2_1_COMBINED_SET_HASH`

The recovery updates all six atomically and independently verifies them before
commit.

## Preserved business data

No gate result, route, reason, routing snapshot, latest row, archive row,
matched comparison, source G2 record, accepted predecessor row, policy rule,
count, grain, or business outcome is changed.
