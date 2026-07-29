# M1.4 - Daily POS, Settlement & Merchant Ecosystem

> **ACCEPTED - v0.2_ACCEPTED**  
> Accepted database milestone

## Business Question

Can the platform create deterministic daily sales and settlement evidence that reflects seasonality, volatility, disruptions, processor behavior, and merchant operating patterns?

## Why This Stage Matters

Builds 180 days of synthetic POS and settlement history per merchant.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.4` |
| Public navigation sequence | `1.04` |
| Package revision | `v0.2` |
| Status | **ACCEPTED** |
| Principal output | 135,000 baseline daily POS and settlement rows. |
| Primary accepted identity | `d1971e8d319483c187ec0c0483a31e33` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

135,000 baseline daily POS and settlement rows.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

Accepted at v0.2 after live execution and full deterministic reconciliation.

The public repository includes the accepted clean-build source and a concise correction history. Complete raw failure, recovery, and superseded-source evidence remains in the private canonical audit repository.

## Anchor Artifacts

- [`docs/`](./v0.2_ACCEPTED/docs/) - design, methodology, dictionaries, and release documentation.
- [`src/`](./v0.2_ACCEPTED/src/) - accepted clean-build SQL or source-provenance package.
- [`outputs/`](./v0.2_ACCEPTED/outputs/) - compact synthetic outputs and aggregate evidence where applicable.
- [`tests/`](./v0.2_ACCEPTED/tests/) - accepted validation, reports, hashes, and formal sign-off.
- [`RELEASE_METADATA.json`](./v0.2_ACCEPTED/RELEASE_METADATA.json) - structured release facts.

## Interpretation Boundary

All data are synthetic. Acceptance demonstrates deterministic consistency within this portfolio platform; it is not production credit-policy approval, model-risk approval, legal or regulatory certification, accounting approval, or authorization for operational deployment.

---

[Return to the repository README](../../README.md) | [Open the Project Artifact Map](../../PROJECT_ARTIFACT_MAP.md)
