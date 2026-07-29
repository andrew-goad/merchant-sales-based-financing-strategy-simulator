# G1 Parameter-Set Delta from G0

## Governance treatment

The accepted G0 seed is not rewritten. G1 creates `M1_G1_BASELINE_DEMO v1`, superseding `M1_BASELINE_DEMO v1` for the governed baseline run.

## Reconciliation

| Component | Rows | Distinct parameter names |
|---|---:|---:|
| G0 `M1_BASELINE_DEMO v1` | 397 | 154 |
| G1 added scoped values | 4 | 1 |
| G1 `M1_G1_BASELINE_DEMO v1` | **401** | **155** |

## Added parameter

`funding_to_annualized_sales_center` is required by the parameter-definition catalog and scoped by merchant size tier.

| Scope | Synthetic center |
|---|---:|
| `MERCHANT_SIZE_TIER:MICRO` | 0.06 |
| `MERCHANT_SIZE_TIER:SMALL` | 0.08 |
| `MERCHANT_SIZE_TIER:LOWER_MIDDLE` | 0.10 |
| `MERCHANT_SIZE_TIER:MIDDLE` | 0.12 |

These are demonstration assumptions used to create coherent synthetic requested funding relative to annualized eligible sales. They are not production policy or market benchmarks.
