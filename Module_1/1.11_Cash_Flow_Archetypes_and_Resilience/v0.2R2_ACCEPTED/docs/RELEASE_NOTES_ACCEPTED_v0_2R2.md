# M1.11 Accepted Release Notes — v0.2R2

## Status

**PASSED AND ACCEPTED**

## Accepted scope

- 1,500 scenario-aware operating-resilience snapshots
- 7,500 long-form component records
- eight governed archetypes
- five transparent resilience components
- matched baseline/recession migration
- explicit evidence gating and controlled fallback paths
- deterministic row and set hashes
- 72 positive controls and six negative controls

## Final methodology

```text
Methodology version
M1_11_METHOD_V1_1

Composite score basis
SUM_PERSISTED_WEIGHTED_COMPONENTS
```

BLOCKED snapshots retain a null wide composite even when transparent component evidence exists. Non-BLOCKED wide composite scores equal the sum of the five persisted weighted component values.

## Corrections included

- Full accepted source hash used in validation
- Evidence-gated composite identity
- 237 non-BLOCKED composite rounding corrections
- 76 BLOCKED rows preserved as null composites
- Stress tier and archetype non-improvement floors preserved
- Professional SQL headers, comments, and report formatting added without executable logic changes

## Next authorized module

M1.12 — Merchant Risk Components & Integrated Risk Proxy
