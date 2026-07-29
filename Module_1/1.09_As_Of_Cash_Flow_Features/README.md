# M1.9 - As-of Cash-Flow Feature Engineering

> **ACCEPTED - v0.2R5_ACCEPTED**  
> Accepted database milestone

## Business Question

Can daily operating evidence be transformed into transparent, scenario-aware cash-flow features at a controlled as-of date?

## Why This Stage Matters

Builds wide application-scenario feature snapshots and a long-form feature contract for sales, cash flow, liquidity, concentration, volatility, and disruptions.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.9` |
| Public navigation sequence | `1.09` |
| Package revision | `v0.2R5` |
| Status | **ACCEPTED** |
| Principal output | 1,500 wide snapshots + 54,000 long-form values across 36 features; 55,500 canonical entities. |
| Primary accepted identity | `7c25acac533179f42789a6daa79d0cc3` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

1,500 wide snapshots + 54,000 long-form values across 36 features; 55,500 canonical entities.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

The accepted R5 sequence fixed scenario scoping, explicit CTAS shape, target-typed hashing, aggregate FILTER syntax, visible composite reconciliation, and session-preserved result grids.

The public repository includes the accepted clean-build source and a concise correction history. Complete raw failure, recovery, and superseded-source evidence remains in the private canonical audit repository.

## Anchor Artifacts

- [`docs/`](./v0.2R5_ACCEPTED/docs/) - design, methodology, dictionaries, and release documentation.
- [`src/`](./v0.2R5_ACCEPTED/src/) - accepted clean-build SQL or source-provenance package.
- [`outputs/`](./v0.2R5_ACCEPTED/outputs/) - compact synthetic outputs and aggregate evidence where applicable.
- [`tests/`](./v0.2R5_ACCEPTED/tests/) - accepted validation, reports, hashes, and formal sign-off.
- [`RELEASE_METADATA.json`](./v0.2R5_ACCEPTED/RELEASE_METADATA.json) - structured release facts.

## Interpretation Boundary

All data are synthetic. Acceptance demonstrates deterministic consistency within this portfolio platform; it is not production credit-policy approval, model-risk approval, legal or regulatory certification, accounting approval, or authorization for operational deployment.

---

[Return to the repository README](../../README.md) | [Open the Project Artifact Map](../../PROJECT_ARTIFACT_MAP.md)
