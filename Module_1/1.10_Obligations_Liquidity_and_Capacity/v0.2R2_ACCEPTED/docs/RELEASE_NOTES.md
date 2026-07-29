# M1.10 Accepted Release Notes — v0.2R2

## Release status

M1.10 — Obligations, Liquidity & Residual Cash Flow is formally accepted.

## Final accepted outputs

- 906 atomic application-obligation rows
- 595 applications with generated obligations
- 631 short-term obligation rows
- 1,500 matched baseline/stress capacity rows
- 2,406 canonical entities
- 70 / 70 positive validations
- 6 / 6 negative controls
- zero deterministic mismatches
- zero adverse-scenario capacity-tier improvements
- zero blocking resolution errors

## Accepted correction sequence

- v0.2: schema/policy extension accepted; initial preflight exposed the incorrect M1.2 hash lookup.
- v0.2R1: sourced the M1.2 identity from `population_registry`, bounded temporary hash updates, and generated the accepted business rows.
- v0.2R2: corrected validation parser/parenthesis defects and latent aggregate `FILTER` syntax without changing generated business rows or hashes.

## Governed methodology

- Methodology: `M1_10_METHOD_V1`
- Requested burden basis: `MAX_RATE_OR_HORIZON`
- Stress non-improvement floor: enabled

## Next stage

M1.11 — Cash-Flow Archetypes & Operating Resilience is authorized.
