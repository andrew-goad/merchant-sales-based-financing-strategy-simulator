# M1.5 - Daily Deposit & Liquidity History

> **ACCEPTED - v0.2R2_ACCEPTED**  
> Accepted database milestone

## Business Question

Can daily deposits, withdrawals, balances, liquidity support, NSF events, and financing pressure be modeled without treating missing evidence as favorable liquidity?

## Why This Stage Matters

Creates scenario-ready daily deposit and liquidity histories aligned to accepted merchant and POS evidence.

## Accepted Status

| Item | Accepted value |
|---|---|
| Canonical stage | `M1.5` |
| Public navigation sequence | `1.05` |
| Package revision | `v0.2R2` |
| Status | **ACCEPTED** |
| Principal output | 135,000 daily deposit and liquidity rows. |
| Primary accepted identity | `bbe96dd24fbbba3af4a587dd475a88d0` |
| Source of truth | Accepted Module 1 G2 canonical repository |

## Scope and Boundary

This stage consumes accepted persisted predecessors and creates only its authorized evidence layer. It does not silently pull forward later pricing, approval, counteroffer, funding, or optimization decisions.

## Output and Grain

135,000 daily deposit and liquidity rows.

## Determinism and Governance

The accepted package uses deterministic generation, explicit physical grains, target-typed hashing, independent reconstruction, positive controls, negative controls, stage-boundary checks, and formal sign-off. Where evidence is unavailable or materially conflicted, the project preserves `COMPLETE`, `PARTIAL`, and `BLOCKED` treatment rather than manufacturing favorable values.

## Correction History

Pre-open NSF events were eliminated through a bounded correction; a read-only detail-report ambiguity was also corrected.

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
