# M1.2 - Deterministic Merchant Population

> **ACCEPTED - v0.2R2_ACCEPTED**  
> Accepted database milestone

## Business Question

Can a synthetic merchant population be generated deterministically with realistic entity, industry, relationship, processor, and channel structure?

## Why This Stage Matters

Creates 750 synthetic merchants, owner and guarantor records, industry assignments, relationship profiles, processor accounts, and five governed acquisition-channel definitions.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.2` |
| Public navigation sequence | `1.02` |
| Package revision | `v0.2R2` |
| Status | **ACCEPTED** |
| Principal output | 750 merchants and 4,352 canonical entities. |
| Primary accepted identity | `9b706c926260a3ef1ae8ac95eed5d0bf` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

750 merchants and 4,352 canonical entities.

## Validation Summary

| Control family | Accepted result |
|---|---:|
| Positive controls | 36 / 36 PASS |
| Negative controls | 3 / 3 PASS |

Full-population acceptance evidence remains in the versioned `tests/` directory.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

The final accepted revision preserves deterministic generation, exact quota reconciliation, and clean-build packaging after controlled recovery.

The public repository includes the accepted clean-build source and a concise correction history. Complete raw failure, recovery, and superseded-source evidence remains in the private canonical audit repository.

## Anchor Artifacts

- [`docs/`](./v0.2R2_ACCEPTED/docs/) - design, methodology, dictionaries, and release documentation.
- [`src/`](./v0.2R2_ACCEPTED/src/) - accepted clean-build SQL or source-provenance package.
- [`outputs/`](./v0.2R2_ACCEPTED/outputs/) - compact synthetic outputs and aggregate evidence where applicable.
- [`tests/`](./v0.2R2_ACCEPTED/tests/) - accepted validation, reports, hashes, and formal sign-off.
- [`RELEASE_METADATA.json`](./v0.2R2_ACCEPTED/RELEASE_METADATA.json) - structured release facts.

## Interpretation Boundary

All data are synthetic. Acceptance demonstrates deterministic consistency within this portfolio platform; it is not production credit-policy approval, model-risk approval, legal or regulatory certification, accounting approval, or authorization for operational deployment.

---

[Return to the repository README](../../README.md) | [Open the Project Artifact Map](../../PROJECT_ARTIFACT_MAP.md)
