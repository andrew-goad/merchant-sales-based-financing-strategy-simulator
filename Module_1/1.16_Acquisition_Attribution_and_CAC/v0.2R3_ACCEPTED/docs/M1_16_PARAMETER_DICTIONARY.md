# M1.16 Governed Parameter and Configuration Dictionary

## Governance pattern

M1.16 uses a dedicated approved parameter set and policy profile. It does not mutate accepted G1 parameter, profile, or source snapshots. The M1.16 parameter-set hash becomes companion-contract lineage.

```text
Parameter set code       M1_16_ACQUISITION_FOUNDATIONS
Parameter set version    1
Methodology              M1_16_METHOD_V1
Contract                 M1_ACQUISITION_CONSUMPTION v1
Schema                   M1_ACQUISITION_SCHEMA_V1
```

## Contract and method controls

| Parameter | Type | Governed value | Purpose |
|---|---|---:|---|
| `m1_16_methodology_version` | text | `M1_16_METHOD_V1` | Freezes business and evidence methodology. |
| `m1_16_contract_code` | text | `M1_ACQUISITION_CONSUMPTION` | Companion contract identity. |
| `m1_16_contract_version` | integer | 1 | Contract version. |
| `m1_16_schema_version` | text | `M1_ACQUISITION_SCHEMA_V1` | Physical/consumption schema identity. |
| `m1_16_attribution_method` | text | `GOVERNED_PRIMARY_TOUCH_V1` | Deterministic descriptive allocation method. |

## Expected cardinality controls

| Population | Governed rows |
|---|---:|
| Source profiles | 18 |
| Campaigns | 20 |
| Funnel rows | 120 |
| Cost-ledger rows | 40 |
| Touchpoints | 1,075 |
| Attribution snapshots | 750 |
| Cost snapshots | 750 |
| Cost components | 9,000 |
| Latest contract | 750 |
| Immutable archive | 750 |
| Integrated view | 1,500 |
| Registry | 1 |
| Canonical entities | 13,274 |

## Attribution controls

| Control | Governed value | Interpretation |
|---|---:|---|
| Maximum touchpoints | 3 | Bounds application-level synthetic interactions. |
| Assisted-touch modulus | 3 | Deterministic second-touch assignment. |
| Third-touch modulus | 10 | Deterministic third-touch assignment. |
| Attribution block modulus | 47 | Creates bounded synthetic attribution conflict evidence. |
| Primary weight | 1.0 | One primary touch receives financial allocation. |
| Assisted weight | 0.0 | Assisted touches remain descriptive in v1. |

## Cost and evidence controls

| Control | Governed value | Interpretation |
|---|---:|---|
| Cost block modulus | 61 | Creates bounded synthetic cost-scope limitations. |
| Currency allocation tolerance | 0.00 | Campaign allocations reconcile to the cent. |
| Scenario invariance required | true | Historical acquisition evidence cannot diverge by current matched scenario. |
| Supported zero requires evidence | true | Zero is not inferred from absence. |
| Unknown overlap is blocked | true | Unknown M1.14 overlap is not treated as zero overlap. |
| Synthetic data only | true | No actual marketing or merchant data. |
| No PII | true | No person/device/contact/tracking identifiers. |
| Prohibited Module 2 outputs | true | No offer, pricing, decision, funding, payback, LTV, or optimization. |

## Assumption status

Source profiles, campaigns, funnel factors, cost bases, timing, unit costs, and overlap rates are synthetic demonstration assumptions—not external market benchmarks, vendor quotes, accounting policy, or production transfer-pricing values.

## Change control

A material taxonomy, attribution, cost, overlap, evidence, or cardinality change requires a new parameter/profile version and contract review. It must not be introduced by editing an accepted contract row or predecessor snapshot.

See the machine-readable parameter, source, campaign, cost, timing, attribution, and evidence dictionaries under `catalogs/`.
