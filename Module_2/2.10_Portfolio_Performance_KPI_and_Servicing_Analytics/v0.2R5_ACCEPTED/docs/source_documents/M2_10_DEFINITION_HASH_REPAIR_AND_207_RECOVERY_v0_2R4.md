# M2.10 Definition-Hash Repair and Program 207 Recovery — v0.2R4

## Diagnosis

Program 207 v0.2R2 completed all 120 controls and returned 116 PASS / 4 FAIL.
The four failed family-level controls are:

- `M2_10_POS_025_KPI_HASH`
- `M2_10_POS_026_TIER_HASH`
- `M2_10_POS_027_QUEUE_HASH`
- `M2_10_POS_028_REASON_HASH`

Program 204 v0.2 hashed temporary seed records before insert. Four seed CTEs
used temporary field names that did not match the persisted physical column
names. Because JSONB hashes include key names, stored hashes remained
internally deterministic but could not be reconstructed from the physical
rows.

```text
KPI seed       zero_numeric             → zero_denominator_numeric_flag
Tier seed      code / rank / burden      → performance_tier_code / rank / burden_units
Queue seed     code / rank / burden / manual
                                         → servicing_queue_code / rank / burden_units / manual_review_flag
Reason seed    code                      → portfolio_analytics_reason_code
```

Program 206 remains valid: all generated business rows, counts, amounts,
latest/archive rows, and row-level reconciliation passed. Program 207
correctly identified the physical reconstructability gap.

## Current database recovery

```text
Stop → ROLLBACK;
→ 207B diagnostic
→ 207C atomic repair
→ 207 v0.2R3
→ 208 → 209 → 210 → 211
```

Do not rerun Programs 204–206.

## Repair scope

Program 207C changes only:

- four definition-table `row_hash` families;
- the four affected definition set hashes;
- registry `row_hash`;
- contract set hash;
- combined canonical hash;
- six existing generation-evidence hash values.

It does not change source rows, account performance, scope/KPI/queue rows,
latest/archive rows, business counts, amounts, timestamps, or stage boundary.

## Future clean execution

Program 204 v0.2R1 uses explicit physical aliases before hashing and explicit
persistent insert projections. A fresh build using v0.2R1 does not require
Program 207C.
