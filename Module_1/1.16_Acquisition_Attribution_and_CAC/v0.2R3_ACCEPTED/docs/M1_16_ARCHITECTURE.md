# M1.16 Architecture

## Purpose
M1.16 is an additive acquisition-evidence and economics foundation inserted after accepted M1.15 and before the independent G2 assurance stage.

## Flow
```text
Accepted M1.2/M1.3 channel and application lineage
+ accepted M1.14 legacy acquisition cost
+ accepted M1.15 consumption contract
        ↓
Source profiles and acquisition campaigns
        ↓
Campaign funnel and cost ledger
        ↓
Bounded application touchpoints and governed primary attribution
        ↓
Deterministic cost allocation, residual-cent reconciliation,
M1.14 overlap bridge, and evidence gates
        ↓
M1.16 latest companion contract and immutable archive
        ↓
Read-only M1.15 + M1.16 integrated consumption view
        ↓
M1.17 end-to-end QA, evidence, and G2 contract acceptance
```

## Contract pattern
M1.16 does not mutate `M1_APPLICATION_CONSUMPTION v1`. It publishes `M1_ACQUISITION_CONSUMPTION v1` under `M1_ACQUISITION_SCHEMA_V1` and joins it read-only to the accepted scenario-aware M1.15 contract.

## Physical inventory
- 18 new parent/control/reference tables with 344 designed columns.
- 5 explicitly projected views.
- 8 governed functions.
- 1 archive-immutability trigger.
- 10 supporting indexes plus primary/unique/foreign-key/check constraints.

See `diagrams/M1_16_ARCHITECTURE.svg` and `.png`.
