# M1.14 - Unit Economics & Risk-Adjusted Contribution

> **ACCEPTED - v0.2R4_ACCEPTED**  
> Accepted database milestone

## Business Question

How do revenue, non-loss costs, comparative loss, capital charge, hurdle requirement, and evidence limitations combine into transparent conditional-if-booked economics?

## Why This Stage Matters

Creates fourteen visible economics components and scenario-aware unit-economics snapshots.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.14` |
| Public navigation sequence | `1.14` |
| Package revision | `v0.2R4` |
| Status | **ACCEPTED** |
| Principal output | 1,500 snapshots + 21,000 component rows; 22,500 canonical entities. |
| Primary accepted identity | `3a47f59b56fa158c18c111caa1c64909` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

1,500 snapshots + 21,000 component rows; 22,500 canonical entities.

## Validation Summary

| Control family | Accepted result |
|---|---:|
| Positive controls | 82 / 82 PASS |
| Negative controls | 7 / 7 PASS |

Full-population acceptance evidence remains in the versioned `tests/` directory.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

Null-safe stress logic, the blocked-evidence constraint, atomic contract repair, and physical-row hash reconstruction were resolved across v0.2R1-v0.2R4.

The public repository includes the accepted clean-build source and a concise correction history. Complete raw failure, recovery, and superseded-source evidence remains in the private canonical audit repository.

## Anchor Artifacts

- [`docs/`](./v0.2R4_ACCEPTED/docs/) - design, methodology, dictionaries, and release documentation.
- [`src/`](./v0.2R4_ACCEPTED/src/) - accepted clean-build SQL or source-provenance package.
- [`outputs/`](./v0.2R4_ACCEPTED/outputs/) - compact synthetic outputs and aggregate evidence where applicable.
- [`tests/`](./v0.2R4_ACCEPTED/tests/) - accepted validation, reports, hashes, and formal sign-off.
- [`RELEASE_METADATA.json`](./v0.2R4_ACCEPTED/RELEASE_METADATA.json) - structured release facts.

## Interpretation Boundary

All data are synthetic. Acceptance demonstrates deterministic consistency within this portfolio platform; it is not production credit-policy approval, model-risk approval, legal or regulatory certification, accounting approval, or authorization for operational deployment.

---

[Return to the repository README](../../README.md) | [Open the Project Artifact Map](../../PROJECT_ARTIFACT_MAP.md)
