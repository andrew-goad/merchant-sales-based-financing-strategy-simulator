# Package Validation Report

**Package:** Merchant Sales-Based Financing Module 1 Foundation v0.2  
**Validation date:** 2026-07-23  
**G0 status:** **PASSED**

## Source and evidence validation

- Physical DDL static status: PASS, 0 errors, 0 warnings.
- Schema SQL SHA-256 matches the governed static-validation record.
- Seed SQL SHA-256 matches the governed static-validation record.
- Corrected live-validation SQL contains the required table-only partition filter.
- Live CSV reconciles all 24 expected environment, object, constraint, seed, and empty-state values.
- Build-acceptance milestone records G0 as PASSED and names G1 as the next gate.

## Accepted live environment

- Database: `msbf_strategy`
- User: `postgres`
- PostgreSQL: `PostgreSQL 17.9 on x86_64-windows, compiled by msvc-19.44.35223, 64-bit`
- Execution timestamp: `2026-07-23 20:07:22.311 -0400`

## Package controls

- Canonical filenames do not contain duplicate-upload suffixes.
- Live evidence, test SQL, and milestone are retained under `evidence/G0_Physical_Foundation/`.
- Machine-readable catalogs and evidence JSON are included.
- The BRD PDF is promoted into the primary `docs/` folder.
- The canonical G1 readiness plan is retained at the package root.
- A package manifest and SHA-256 inventory are generated after content freeze.
- The completed ZIP is integrity-tested after creation.

## Acceptance conclusion

The v0.2 physical-foundation distribution is suitable for repository retention and handoff to G1 Governed Run and Configuration Readiness.
