# M1.2 Validation Matrix

## Positive checks

| Check | Validation theme | Blocking expectation |
|---:|---|---|
| 01 | Stage status | Generated population exists before validation |
| 02 | G1 gate | Latest G1 result remains PASS |
| 03 | Accepted hashes | Three exact G1 hashes unchanged |
| 04 | Recomputed hashes | Frozen G1 content independently reconciles |
| 05 | Population status | `M1_2_GENERATED` before final acceptance |
| 06 | Generation specification | Stage-owned JSON and hash reconcile |
| 07 | Merchant count | Exactly 750 |
| 08 | Merchant identity | Unique, contiguous sequence 1–750 |
| 09 | Synthetic boundary | Synthetic names, flags, and USD base currency |
| 10 | Industry completeness | Exactly one primary industry per merchant |
| 11–15 | Governed mixes | Industry, region, size, relationship, legal entity exact |
| 16–18 | Channel/processor | Five definitions; exact mix; one ready account per merchant |
| 19–20 | Temporal capacity | Business and processor tenure bounded and coherent |
| 21–25 | Owner/guarantor | 1,347 rows, 1–3 owners, 100% ownership, score/band integrity, synthetic IDs |
| 26–27 | Relationship | One as-of row per merchant and exact regenerated values |
| 28 | Temporal integrity | Zero future/effective-date violations |
| 29 | Mixed-signal realism | Share meets accepted risk-appetite minimum |
| 30–32 | Determinism | 4,352 canonical rows, zero mismatch, three-way hash equality |
| 33–35 | Stage boundary | No applications/downstream rows; source snapshot unchanged |
| 36 | Configuration | Zero blocking resolution errors |

## Negative controls

| Control | Expected result |
|---|---|
| Missing governed mix parameter | Assignment function rejects before output |
| JSON weights do not sum to one | Assignment function rejects before output |
| Regeneration after persistence | Generation authorization rejects |

## Acceptance rule

```text
36/36 positive checks PASS
3/3 negative controls PASS
0 failed evidence rows
0 canonical row mismatches
stored = expected = actual population hash
0 downstream analytical rows
```
