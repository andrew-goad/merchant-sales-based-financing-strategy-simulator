# M1.12 - Merchant Risk Components & Integrated Risk Proxy

> **ACCEPTED - v0.2R1_ACCEPTED**  
> Accepted database milestone

## Business Question

Can transparent evidence components produce a synthetic integrated merchant-risk proxy without claiming to be a calibrated PD or production score?

## Why This Stage Matters

Combines seven risk components into one scenario-aware, evidence-gated synthetic proxy.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.12` |
| Public navigation sequence | `1.12` |
| Package revision | `v0.2R1` |
| Status | **ACCEPTED** |
| Principal output | 1,500 risk snapshots + 10,500 component rows; 12,000 canonical entities. |
| Primary accepted identity | `fb583c3fdd92f141ba5af1ddf942ffba` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

1,500 risk snapshots + 10,500 component rows; 12,000 canonical entities.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

A read-only detail-report primary-key reference was corrected; accepted generation and hashes were unchanged.

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
