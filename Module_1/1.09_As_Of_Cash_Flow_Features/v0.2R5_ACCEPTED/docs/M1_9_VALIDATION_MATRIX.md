# M1.9 Validation Matrix

## Acceptance inventory

```text
Positive controls    66
Negative controls     6
Detailed reports     20
Wide rows          1,500
Long rows         54,000
Canonical rows    55,500
```

## Positive-control families

| Family | Controls | Purpose |
|---|---:|---|
| Governance and upstream identity | 12 | Preserve accepted gates, run status, and upstream hashes |
| Cardinality, grain, and domains | 24 | Verify exact row counts, unique grains, source lineage, domains, and evidence masking |
| Feature arithmetic and bounds | 15 | Test annualization, activity identities, bounded rates, volatility, liquidity, and processor metrics |
| Scenario direction and baseline controls | 9 | Verify zero BASELINE deltas and expected portfolio-level adverse direction |
| Canonical and boundary controls | 6 | Reconcile wide/long values, row hashes, set hashes, stage boundaries, and blocking errors |

## Negative controls

| Code | Intentional failure | Required behavior |
|---|---|---|
| `M1_9_NEG_01_DISABLED_POLICY` | Disable M1.9 generation | Fail closed |
| `M1_9_NEG_02_MISSING_FEATURE` | Deactivate a required feature definition | Fail closed |
| `M1_9_NEG_03_UNAPPROVED_SCENARIO` | Remove scenario approval | Fail closed |
| `M1_9_NEG_04_PREREQUISITE_GATE` | Drift the M1.8 gate | Fail closed |
| `M1_9_NEG_05_BLOCKING_ERROR` | Introduce a blocking resolution error | Fail closed |
| `M1_9_NEG_06_REGENERATION_REJECTED` | Attempt generation after persistence | Fail closed |

## Acceptance threshold

M1.9 passes only when all 66 positive and all 6 negative controls pass, both output tables contain the expected cardinality, all three canonical hashes reconcile, and downstream credit-risk/contract tables remain empty.
