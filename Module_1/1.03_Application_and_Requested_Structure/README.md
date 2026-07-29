# M1.3 - Application & Requested Sales-Linked Structure

> **ACCEPTED - v0.2R1_ACCEPTED**  
> Accepted database milestone

## Business Question

Can each merchant receive one governed financing application and requested sales-linked structure without creating a decision?

## Why This Stage Matters

Creates one synthetic application per merchant, requested funding, remittance structure, total repayment, finance charge, payoff horizon, and relationship-path differentiation.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.3` |
| Public navigation sequence | `1.03` |
| Package revision | `v0.2R1` |
| Status | **ACCEPTED** |
| Principal output | 750 applications and requested financing structures. |
| Primary accepted identity | `01485256b9b5748fb412743d35ced602` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

750 applications and requested financing structures.

## Validation Summary

| Control family | Accepted result |
|---|---:|
| Positive controls | 42 / 42 PASS |
| Negative controls | 3 / 3 PASS |

Full-population acceptance evidence remains in the versioned `tests/` directory.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

Initial application and relationship-differentiation findings were resolved through a version-aligned correction without changing the accepted merchant population.

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
