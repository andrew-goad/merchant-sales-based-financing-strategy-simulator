# M1.15 Design and Generation Specification

## Contract purpose

M1.15 is the publication boundary for accepted Module 1 evidence. It creates a
stable, versioned downstream contract while retaining complete lineage to the
accepted M1.8–M1.14 physical rows.

## Design principles

- consume accepted physical outputs; never regenerate upstream analytics;
- preserve scenario/application grain;
- separate current latest, immutable archive, and matched comparison;
- flatten high-value fields for ordinary consumers;
- retain upstream hashes and JSON lineage for reconciliation;
- publish a Power BI-oriented consumption view;
- preserve COMPLETE, PARTIAL, and BLOCKED evidence states;
- prevent adverse-scenario comparisons from hiding worsening conditions;
- keep strategy and offer decisions outside Module 1.

## Canonical entities

```text
Latest rows       1,500
Archive rows      1,500
Comparison rows     750
Contract rows          1
Total              3,751
```

## Hash basis

Latest and comparison hashes use target-typed physical fields excluding only
their row hash and creation timestamp. Archive rows retain the latest contract
hash and exact payload. The contract identity hash excludes lifecycle status,
combined hash, and timestamps so acceptance can advance the lifecycle without
changing immutable contract identity.
