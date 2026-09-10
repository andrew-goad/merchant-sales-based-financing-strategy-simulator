# R22 Power BI Desktop evidence — final independent adjudication

**Decision: PASS.** The bounded saved-state correction is complete. The R22 Power BI Desktop evidence is accepted as physically sufficient for the bounded Independent Audit submission.

## Exact evidence identity

- Evidence ZIP: `MSBF_R22_POWER_BI_DESKTOP_EVIDENCE_20260831_192211.zip`
- SHA-256: `c50eda59928244ee6b7e4a967681d51ebff282a0ff6038a27aa96871cdf0b5af`
- Owner manifest: `153` governed rows; no missing, extra, size-mismatched, or hash-mismatched files.

## Physical findings

- Power BI Desktop: `2.157.879.0 64-bit (August 2026)`
- Model: `54 tables / 52 relationships / 164 measures / 52 expressions`
- P01–P04 source bytes: exact
- P05: error-free; no-feasible proof coverage `100.0%`
- P06 Balanced Frontier: `100.0% / 0 / 0 / 1 / treatment-effect claims 0`
- P06 Early Intervention: `4 / 4 / 0 / treatment-effect claims 0`
- Incremental servicing comparison: Early Intervention `4`; other profiles `0`
- Saved and reopened state: `Portfolio / BALANCED_FRONTIER / BASELINE / All`

## Non-regression and authority

- R19 business evidence and the R20 comprehensive carrier are unchanged.
- The R22 source PBIP is unchanged.
- Relationships, columns, DAX semantics, Power Query partitions, and model expressions are semantically exact between governed source and saved working copy.
- Accepted P01–P04 report definitions remain byte-for-byte exact.
- Accepted Module 1/G2 and Module 2/G3 remain controlling until Independent Audit explicitly accepts the successor.
- No publication, Campaign Scale, Module 3, production, funding, payment, collection, or merchant-contact authority is created.

## Correction-history disposition

- `180652` remains preserved as superseded diagnostic evidence.
- `192211` is the controlling R22 Desktop evidence package.
- The former saved-state contradiction is closed; no open R22 Desktop finding remains.

## Controls

| Control | Status | Scope |
|---|---:|---|
| `R22F_EVIDENCE_SIDECAR_EXACT` | PASS | PACKAGE |
| `R22F_ARCHIVE_CRC` | PASS | PACKAGE |
| `R22F_ARCHIVE_MEMBER_UNIQUE` | PASS | PACKAGE |
| `R22F_ARCHIVE_PATH_SAFE` | PASS | PACKAGE |
| `R22F_ARCHIVE_NOT_ENCRYPTED` | PASS | PACKAGE |
| `R22F_ARCHIVE_NO_SYMLINKS` | PASS | PACKAGE |
| `R22F_OWNER_MANIFEST_DOMAIN_EXACT` | PASS | PACKAGE |
| `R22F_OWNER_MANIFEST_HASH_SIZE_EXACT` | PASS | PACKAGE |
| `R22F_POST_DESKTOP_STRUCTURAL_PASS` | PASS | STRUCTURE |
| `R22F_SOURCE_PBIP_UNCHANGED` | PASS | NONMUTATION |
| `R22F_MODEL_COUNTS_EXACT` | PASS | STRUCTURE |
| `R22F_OWNER_ATTESTATION_PASS_DOMAIN` | PASS | OWNER_EVIDENCE |
| `R22F_OWNER_NO_MANUAL_SOURCE_MODEL_CHANGES` | PASS | NONMUTATION |
| `R22F_REOPEN_SCREENSHOT_UPLOAD_BOUND` | PASS | OWNER_EVIDENCE |
| `R22F_SAVED_P06_PROFILE_BALANCED` | PASS | SAVED_STATE |
| `R22F_SAVED_P06_PROFILE_NOT_EARLY` | PASS | SAVED_STATE |
| `R22F_BOUNDED_STATE_CORRECTION_FILESET` | PASS | CONTROLLED_DIVERGENCE |
| `R22F_RELATIONSHIPS_EXACT` | PASS | NONMUTATION |
| `R22F_COLUMNS_SEMANTIC_EXACT` | PASS | NONMUTATION |
| `R22F_MEASURES_SEMANTIC_EXACT` | PASS | NONMUTATION |
| `R22F_PARTITIONS_SEMANTIC_EXACT` | PASS | NONMUTATION |
| `R22F_EXPRESSIONS_SEMANTIC_EXACT` | PASS | NONMUTATION |
| `R22F_P01_SOURCE_BYTES_EXACT` | PASS | NONREGRESSION |
| `R22F_P02_SOURCE_BYTES_EXACT` | PASS | NONREGRESSION |
| `R22F_P03_SOURCE_BYTES_EXACT` | PASS | NONREGRESSION |
| `R22F_P04_SOURCE_BYTES_EXACT` | PASS | NONREGRESSION |
| `R22F_R1_SELECTED_CANDIDATE_COUNT_COALESCE` | PASS | REMEDIATION |
| `R22F_R1_TREATMENT_EFFECT_CLAIMS_COALESCE` | PASS | REMEDIATION |
| `R22F_R1_FRONTIER_ELIGIBLE_PROFILES_COALESCE` | PASS | REMEDIATION |
| `R22F_R1_PRIMARY_GOVERNANCE_PROFILES_COALESCE` | PASS | REMEDIATION |
| `R22F_INCREMENTAL_SERVICING_CHART_BINDING` | PASS | REMEDIATION |
