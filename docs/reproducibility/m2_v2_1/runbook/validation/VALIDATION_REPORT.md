# PUB-RUN-001 — Runbook build validation

**Runbook R1 | September 4, 2026 | Result: PASS for the performed checks.**

## Disposition

The operator procedure and supporting tools are prepared and offline-tested. PUB-RUN-001 remains open for final executable-release/source/seed binding and independent Windows qualification. No database or Power BI runtime acceptance is issued by this report. “Audit-proof” is not a supported claim.

## What was actually tested

| Layer | Result | Evidence |
|---|---|---|
| New checker positive/negative tests | 43/43 PASS; zero skips | TOOLKIT_TEST_LOG.txt |
| Environment probe mocked-version tests | 6/6 PASS | ENVIRONMENT_PROBE_TESTS.txt |
| Exact frozen source validator | 21/21 PASS | FROZEN_RUNTIME_VALIDATOR_RESULT.json |
| Accepted R26 result reconciliation | 90/90 PASS | ACCEPTED_RESULT_RECONCILIATION.json |
| Exact source-owned M2.11 offline reproduction | PASS; matching compiler/final canonical and simulation identities | OFFLINE_SOURCE_REPLAY.json |
| Pristine runtime source preservation | 84/84 exact before and after | PRISTINE_RUNTIME_CHECK.json; OFFLINE_SOURCE_REPLAY.json |
| Runtime, golden result and Power BI component intake | Exact size/hash; CRC and safe extraction PASS | Component receipt JSONs |
| Frozen accepted PBIX | Exact whole file, DataModel, five pages and 96 visuals | ACCEPTED_PBIX_VERIFICATION.json |
| Externally extracted byte comparison | Exact 53-file Power BI package equality | EXTRACTION_BYTE_COMPARISON.json |
| Document / register / source-copy / tool checks | 78/78 PASS | VALIDATION_RESULT.json |
| Printed document | 15 pages; all rendered and visually inspected | PDF/DOCX; no page images distributed |
| Native-host precheck | Expected HOLD on this Linux host | LOCAL_ENVIRONMENT_PROBE_EXPECTED_HOLD.json |

These counts describe different layers; they are not added into a fictitious single engine-certification population. The unit tests include path traversal, case/file collisions, reserved names, tampering, missing source, report overwrite, interrupted runtime output, altered receipts, failed controls and PBIX substitution. They are not exhaustive security or adversarial testing.

## Offline replay scope

The supplied exact R26 retained-final runtime executes its source-owned `r2_failure_reperformance` function against retained R4/R2 CSV evidence. The proof re-executes M2.11 simulation/canonicalization twice and reproduces the accepted semantic source and simulation identities. External subprocess and socket calls were guarded and no attempt was observed. This is not M2.1–M2.10 regeneration, M2.12 database persistence, a Power BI refresh, or an empty-database build.

## Repository-path qualification finding

The inspected pre-R26 R23 Git tree is commit `58b4dbda229d7176431cb09eecd1e3e3ec1feeee`. Its historical catalog has 230 normal positions and 128 separate recovery positions. Exact source hashes map to 224 of the 230 positions; six positions do not map. Zero canonical catalog paths directly exist in that public projection. These facts are recorded without altering the accepted source or representing a historical catalog as a final R26 executor. See HISTORICAL_PLAN_RECONCILIATION.json and the 230-row register.

M1.17 source-closure documentation explicitly distinguishes static closure from future full-replay runtime equivalence. The final cold-start chain must bind the accepted clean-build variants, current R26 changes, seed/restore inputs, normal/reporting/recovery paths and executable checkpoints.

## Untested boundaries

No Windows process, PowerShell parser, PostgreSQL server, database preflight SQL, fresh-machine end-to-end execution, Desktop open/refresh, Windows-native extraction, hosted asset test or independent reviewer signoff was performed in this build. Software-documentation review and historical accepted runtime evidence do not substitute for those tests.

## Preservation and publication

All changes are new documentation, locks, read-only/offline proof tools and temporary fixture tests. Accepted R26/PBIX/cohort and visual artifacts were not edited. The final runbook-review ZIP is not a source-engine release and should not be uploaded wholesale as though all referenced private inputs were public-safe. After final packaging, use the external ZIP verification report for manifest/checksum/clean-extraction results.
