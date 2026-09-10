# PUB-RUN-001 — final pre-audit qualification state

**Disposition for this candidate:** `ROUTE_B_WINDOWS_QUALIFIED_PENDING_FINAL_IA`  
**Route D / empty-database build:** `NOT QUALIFIED`  
**Publication/supersession:** `NOT AUTHORIZED BY THIS RECORD`

## What was demonstrated on Windows

On September 9, 2026, the owner executed the bounded control-party qualification on Windows 10 / PowerShell 7.6.5 / Python 3.14.7 / PostgreSQL 17.9.

The qualified route is **portable checkpoint restore + isolated M2.11/M2.12/G3-v2 re-execution**, not a G0→G3-v2 cold start.

1. The owner repository was clean at `46fb1f9198475678edc9cabdeefd2f91a59e49c2`, with `origin/main` resolving to the same commit.
2. Portable `pg_dump -Fc -C --no-owner --no-privileges` carriers were created from the immutable R6 source and retained R26-R2 checkpoint.
3. A new PostgreSQL 17 cluster was initialized on `127.0.0.1:55432` and both carriers restored under their exact database names.
4. The original strict Phase-2 schema-text comparator stopped because one restored view was deparsed with fewer redundant parentheses. The stop is preserved. A bounded Phase-2B comparator proved the complete delta was confined to `msbf_m12r1e.v_m2_4_physical_semantics_control`, with exact non-parenthesis/non-whitespace token streams and identical control-view results (`CONSTRAINTS|34`, `DEFAULTS|18`, `IDENTITIES|2`). The correction does not globally ignore parentheses.
5. The retained-final R26 M2.11/M2.12/G3-v2 runtime executed once against the isolated restored state and completed PASS.
6. A post-execution harness variable collision (`$B` / `$b`, case-insensitive in PowerShell) prevented the first post-run checker invocation. Execution was **not rerun**. A bounded continuation resumed after execution, completed post-run source verification, accepted-reference reconciliation and nonmutation checks, and shut down the isolated cluster.
7. The generated result ZIP reconciled **90/90 PASS** to the accepted R26 reference. New timestamps, database name and outer ZIP identity were permitted; locked business exports and canonical roots reconciled.
8. The original R6 source, retained checkpoint and Git repository remained unchanged.

## Exact qualification identities

- Qualification evidence ZIP SHA-256: `80a4b9ab3cfd76cc2aa9413bfe423944e92d108ff9d4fa83b92001094d3329c1`
- Generated qualification result SHA-256: `70e812fb9989d91b74aacebf905a6b578844c56902d9b293ffa8ec77291391b5`
- R6 portable carrier SHA-256: `e1523bd4603cdec111a13d568451563254b8176f44dc9263cfa7a9e7fce62531`
- Retained-R2 portable carrier SHA-256: `105426f0cbaf9568a4cfc3b67ea9e13fdc85a0f271195a2c972d8ecdde1a4e0e`
- Accepted R26 reference result SHA-256: `113450c7167c8a5e1b40497c4e39506d276aa0e057bbeb3f316561af5d4096c3`
- Certification: `G3V2_R26_C053DC064AB32A4D21864F94`

The two large backup carriers are retained privately by the owner pending Independent Audit/publication disposition. They are not public Git artifacts and are not embedded in this repository candidate.

## Claim boundary

This evidence supports a reproducible **checkpoint-based Route B** for the v2.1-family publication. It does **not** establish a clean-machine, empty-database execution of G0/G1/Module 1/M2.1–M2.10. Route A remains an offline M2.11 proof; Route C remains accepted-PBIX identity/viewing; Route D remains unqualified. The final Independent Audit must determine whether this bounded Route-B qualification is sufficient for the release's reproducibility claim.
