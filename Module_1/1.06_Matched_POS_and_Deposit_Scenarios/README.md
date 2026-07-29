# M1.6 - Matched POS & Deposit Scenario Overlays

> **ACCEPTED - v0.2R3_ACCEPTED**  
> Accepted database milestone

## Business Question

Can baseline and adverse operating environments be compared on the same merchants, applications, dates, and source histories?

## Why This Stage Matters

Creates an exact-copy BASELINE panel and a governed RECESSION_ENERGY overlay across POS and deposit histories.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.6` |
| Public navigation sequence | `1.06` |
| Package revision | `v0.2R3` |
| Status | **ACCEPTED** |
| Principal output | 270,000 POS scenario rows + 270,000 deposit scenario rows; 540,000 canonical entities. |
| Primary accepted identity | `3f85921bf6fc30ddc6cee146085e58c5` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

270,000 POS scenario rows + 270,000 deposit scenario rows; 540,000 canonical entities.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

Performance remediation removed large self-joins and upstream regeneration; the final revision also corrected settlement-lag validation at the left boundary.

The public repository includes the accepted clean-build source and a concise correction history. Complete raw failure, recovery, and superseded-source evidence remains in the private canonical audit repository.

## Anchor Artifacts

- [`docs/`](./v0.2R3_ACCEPTED/docs/) - design, methodology, dictionaries, and release documentation.
- [`src/`](./v0.2R3_ACCEPTED/src/) - accepted clean-build SQL or source-provenance package.
- [`outputs/`](./v0.2R3_ACCEPTED/outputs/) - compact synthetic outputs and aggregate evidence where applicable.
- [`tests/`](./v0.2R3_ACCEPTED/tests/) - accepted validation, reports, hashes, and formal sign-off.
- [`RELEASE_METADATA.json`](./v0.2R3_ACCEPTED/RELEASE_METADATA.json) - structured release facts.

## Interpretation Boundary

All data are synthetic. Acceptance demonstrates deterministic consistency within this portfolio platform; it is not production credit-policy approval, model-risk approval, legal or regulatory certification, accounting approval, or authorization for operational deployment.

---

[Return to the repository README](../../README.md) | [Open the Project Artifact Map](../../PROJECT_ARTIFACT_MAP.md)
