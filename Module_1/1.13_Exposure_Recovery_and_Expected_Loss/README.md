# M1.13 - Exposure, Recovery & Expected Loss Foundations

> **ACCEPTED - v0.2R1_ACCEPTED**  
> Accepted database milestone

## Business Question

What contractual-receivable path, path-weighted exposure, recovery assumptions, LGD, and comparative loss can be supported without claiming CECL or production risk parameters?

## Why This Stage Matters

Builds daily contractual exposure paths and scenario-aware comparative loss evidence.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.13` |
| Public navigation sequence | `1.13` |
| Package revision | `v0.2R1` |
| Status | **ACCEPTED** |
| Principal output | 93,720 exposure-path rows + 1,500 snapshots; 95,220 canonical entities. |
| Primary accepted identity | `11dca65763f4062ad9002244ee6452f9` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

93,720 exposure-path rows + 1,500 snapshots; 95,220 canonical entities.

## Validation Summary

| Control family | Accepted result |
|---|---:|
| Positive controls | 82 / 82 PASS |
| Negative controls | 7 / 7 PASS |

Full-population acceptance evidence remains in the versioned `tests/` directory.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

PostgreSQL does not support max(boolean); the pre-commit failure was recovered and the accepted source uses bool_or(boolean).

The public repository includes the accepted clean-build source and a concise correction history. Complete raw failure, recovery, and superseded-source evidence remains in the private canonical audit repository.

## Anchor Artifacts

- [`docs/`](./v0.2R1_ACCEPTED/docs/) - design, methodology, dictionaries, and release documentation.
- [`src/`](./v0.2R1_ACCEPTED/src/) - accepted clean-build SQL or source-provenance package.
- [`outputs/`](./v0.2R1_ACCEPTED/outputs/) - compact synthetic outputs and aggregate evidence where applicable.
- [`tests/`](./v0.2R1_ACCEPTED/tests/) - accepted validation, reports, hashes, and formal sign-off.
- [`RELEASE_METADATA.json`](./v0.2R1_ACCEPTED/RELEASE_METADATA.json) - structured release facts.

## Interpretation Boundary

All data are synthetic. Acceptance demonstrates deterministic consistency within this portfolio platform; it is not production credit-policy approval, model-risk approval, legal or regulatory certification, accounting approval, or authorization for operational deployment.

---

[Return to the repository README](../../README.md) | [Open the Project Artifact Map](../../PROJECT_ARTIFACT_MAP.md)
