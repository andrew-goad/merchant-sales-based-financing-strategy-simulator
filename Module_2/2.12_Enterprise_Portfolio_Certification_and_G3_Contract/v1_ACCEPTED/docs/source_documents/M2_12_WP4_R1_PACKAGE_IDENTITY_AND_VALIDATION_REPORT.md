# M2.12 WP4 R1 Package Identity and Validation Report

## Package identity

- Canonical package name: `M2_12_Build_WP4_R1.zip`
- Governing WP3 R1 SHA-256: `5aa031b5e1dba1a92538eccb25a047e3db682357122c2f882a7736fd4b14cf26`
- Governing WP2 R4 SHA-256: `aa234e534c8dbed7cdd7ba5ed6041e498df4c9046cbac4663477a08647e73592`
- Planned final ZIP file-entry count: **77**
- Source execution state: **NOT EXECUTED**
- M2.12 runtime validation/acceptance: **NOT CLAIMED**

## Physical source checkpoints

| Artifact | Bytes | SHA-256 | Readback |
|---|---:|---|---|
| Program 225 | 196837 | `3769fe5c43d8d8aafe18e3e3d4538bd696dc370fd4ca080fa3fa5cfbad625119` | PASS |
| Program 226 | 116188 | `e43bab189d439f0e09ad879ea253f6162560e5b157b71f030eaa3ff16b9e3f56` | PASS |
| Program 227 | 131787 | `17a27cb49fe0611953d5bc499c15513d46d8768fe441ed1fd0bfb126f3300b50` | PASS |
| Acceptance traceability | 16895 | `22af59fd2e3f20918cba0bb9cb564f378f45a9eda8afa192d03857d415e1a72a` | 48 rows PASS |
| Detail traceability | 20017 | `d3df95b81d762bcd0d4f15cbbded3850b609905156a8ac604074b2c61fa686ee` | 24 rows PASS |

## Independently recalculated pre-ZIP controls

- Governing WP3/WP2/WP1/audit packages and accepted M2.11 baseline: hashes and CRC PASS.
- Nine upstream SQL identities: PASS, byte-identical.
- Programs 225-227 physical readback: PASS.
- Acceptance requirements/phases: 48/48 and 8/8 PASS.
- Master report and detailed-result traceability: PASS.
- Parser/lexical/static controls: 23/23 PASS.
- Persistent reporting mutations: 0.
- PostgreSQL executions: 0.
- Execution/WP5 packages: absent.

## Metadata and release boundary

`MANIFEST.csv` and `manifest.json` cover substantive files that physically exist before metadata construction. `SHA256SUMS.txt` additionally covers both manifests. `PACKAGE_INVENTORY.csv` catalogs every final ZIP file except itself. This report is generated before the canonical ZIP and does not substitute for the post-creation release gate. The ZIP is released only after independent reopen, CRC, complete extraction, path/size/SHA comparison, and extracted metadata recalculation. The external sidecar is created only after those gates pass.
