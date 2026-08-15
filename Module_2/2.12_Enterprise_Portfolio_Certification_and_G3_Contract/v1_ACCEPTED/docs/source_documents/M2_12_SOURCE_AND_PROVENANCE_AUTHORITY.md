# M2.12 Source and Provenance Authority

## Current authority chain

1. Approved WP1 R10 implementation authority and frozen design extracts.
2. Approved WP2 Source R4 for Programs 220, 221, 222, 220A, 222A, and 222B.
3. Approved WP3 Source R1 for Programs 223, 224, and 223A.
4. Approved WP4 Source R1 for Programs 225, 226, and 227.
5. WP4 final independent audit: 134/134 PASS, zero open findings.
6. WP5 authorization: documentation and standalone ready-for-execution packaging only.

## Governing WP4 package

```text
M2_12_Build_WP4_R1.zip
Bytes       91,288,357
SHA-256     aa1506e932f63c350ba38b2db025f57077a6ffaa15b2437c896680aa6b4c38b6
ZIP entries 77
CRC         PASS
```

The source package's sidecar, manifests, inventory, reconciled WP3 signoff, and all twelve SQL identities were independently recalculated before this tree was built.

## Preserved SQL identity

- Normal source-set SHA-256: `6c88c593e05a8de9699e61722283b7044158bac7db4bd720156b9769b1d20bd0`
- Recovery source-set SHA-256: `35d81d74fa5bff735102d5dcc2f1466ab2bb55e989d3df9d46d4b032aef3262c`
- Full 12-file source-set SHA-256: `20291f3740a8a1350a84a1283903c56e9b69ac4e65edee7c9028fb2e1ac9011a`
- Physical SQL files changed: **0**
- SQL files added beyond approved Programs 220–227 and recoveries: **0**

See `04_catalogs/M2_12_SQL_SOURCE_SHA256_INVENTORY.csv` and `06_validation/M2_12_WP5_SQL_BYTE_PRESERVATION_AUDIT.csv`.

## Interpretation of source headers

The SQL headers preserve their source-construction status and prior work-package operator boundaries byte-for-byte. They were not rewritten during WP5. Current package and execution authority is established by the external WP5 signoff chain, not by editing historical header text.

## Current boundary

```text
READY FOR LIVE EXECUTION
NOT EXECUTED
NOT ACCEPTED
```

The readiness line describes package completeness. PostgreSQL execution remains pending independent WP5 review and explicit authorization. No live result, M2.12 acceptance, Module 3 authority, stage `31_M2_12`, accepted full-project package, or production/deployment authority is created here.
