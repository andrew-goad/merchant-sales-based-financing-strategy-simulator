# M1.7 Validation Matrix

## Blocking positive controls

| Family | Check range | Purpose |
|---|---|---|
| Prerequisite governance | 01–10 | Preserve accepted run, gate, and hash identities |
| Cardinality and lineage | 11–18 | Enforce 5,250-row grain, contracts, as-of, and dates |
| Measurement integrity | 19–28 | Validate counts, completeness, freshness, reconciliation, confidence, statuses, and fallbacks |
| Source-specific semantics | 29–37 | Validate POS, deposit, and point-source observation logic |
| Thresholds and determinism | 38–42 | Validate controls, outages, contract thresholds, and paired reconciliation |
| Critical routing and diversity | 43–49 | Validate fail-closed/fallback paths, conflicts, diversity, and application diagnostics |
| Hashes and stage boundaries | 50–55 | Recompute hashes, preserve histories, enforce boundaries, and require zero blocking errors |

## Negative controls

| Code | Mutation | Expected rejection |
|---|---|---|
| M1_7_NEG_01 | Remove required typed value | Incomplete configuration |
| M1_7_NEG_02 | Mark POS source not ready | Seven ready sources not satisfied |
| M1_7_NEG_03 | Make thresholds non-monotonic | Invalid threshold configuration |
| M1_7_NEG_04 | Drift prerequisite status | Generation prerequisite rejected |
| M1_7_NEG_05 | Attempt rerun over persisted snapshots | Rerun rejected |

## Acceptance conditions

```text
55 positive controls, all PASS
5 negative controls, all PASS
5,250 source rows | 750 applications | 7 source families
0 deterministic mismatches | 0 downstream rows | 0 blocking errors
overall_m1_7_status = PASS
```

## Detail result sets

1. Run and Acceptance State
2. Entity and Stage-Boundary Row Counts
3. Source-Level Quality Summary
4. Availability and Fallback Diagnostics
5. Completeness, Freshness, and Contract Diagnostics
6. POS/Deposit Reconciliation Diagnostics
7. Application-Level Confidence Tiers
8. Critical-Source and Manual-Review Diagnostics
9. Conflict, Failure, and Warning Diagnostics
10. Partner/Channel Diagnostics
11. Industry Diagnostics
12. Sample Application/Source Profiles
13. Row-Level Deterministic Mismatches
14. M1.7 Evidence
15. Blocking Resolution Errors

Result sets 13 and 15 must be empty.
