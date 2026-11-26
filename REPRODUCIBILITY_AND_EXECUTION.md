# Tableau viewing companion

The [Tableau companion](docs/tableau/README.md) adds read-only analytical exploration of existing matched-scenario outputs. The PDF/PNGs can be read without Tableau or a database. The authored `.twb` depends on a local CSV and temporary extract not bundled with the supplied folder; it is not a self-contained runtime package.

[Workbook dependencies and reference checks](docs/tableau/docs/WORKBOOK_AND_EVIDENCE_NOTES.md) are distinct from the existing qualified database/replay routes. No SQL execution, new campaign, version, release or new qualification claim is introduced here.

---

# Current reproducibility overlay

`PUB-RUN-001` governs the v2.1-family publication. Route A is an offline M2.11 proof; **Route B is Windows-qualified checkpoint restore/replay** with isolated M2.11/M2.12/G3-v2 execution and 90/90 accepted-reference reconciliation; Route C is immutable Power BI viewing; Route D empty-database build remains unqualified. Do not describe Route A/B as a G0→G3-v2 cold start. Qualification summary: `docs/reproducibility/m2_v2_1/PUB_RUN_001_ROUTE_B_QUALIFICATION_R1.md`.

---

## Preserved predecessor content

# Reproducibility and Execution

## Environment

- PostgreSQL 15
- Database: `msbf_strategy`
- Execution interface used for acceptance: DBeaver
- Governed run: `M1_V0_2_BASELINE_BUILD`, version 1

## DBeaver Execution Standard

- Use **Execute SQL Script** for complete programs.
- Stop at the first PostgreSQL error.
- Never use Retry, Skip, or Skip All.
- Execute `ROLLBACK;` after a failed transactional program.
- Preserve committed generation and correct only the affected stage onward.
- Do not rerun accepted predecessor modules unless an explicit fail-closed recovery authorizes it.

## Reproducibility Model

The accepted project uses deterministic pseudo-random functions derived from MD5-based keys and an accepted seed version. Generation programs materialize expensive intermediates once, index and `ANALYZE` them, cast expected values to physical target types, persist accepted rows, and independently reconstruct hashes from physical fields.

## Public Source vs. Canonical Delivery

This GitHub repository is a curated public projection. The accepted full-project ZIP remains the canonical audit source. Public SQL is copied byte-for-byte where exact accepted source is retained. GitHub-derived Markdown, samples, and visuals are separately identified as publication artifacts.

## M1.17 Source Provenance

The exact standalone v0.2R2 source files for Programs 124C-128 were not present in the final active runtime. Their live execution evidence and original-plus-hotfix lineage are preserved. The public repository does not reconstruct and relabel them as exact executed source.

## Read-Only Public Review Cohort

The cohort selection SQL is read-only and does not alter accepted database objects. Use the published cohort registry as the immutable public ID map when extracting stage-specific review records.

## Campaign-scale reproducibility boundary

The accepted certification database must not be used as a campaign target. Future replay and scale work must use a disposable PostgreSQL environment, exact source identities, frozen parameters, retained checkpoint/report evidence, and separate authorization for each scale gate.

See [Campaign Scale Certification](docs/campaign_scale/README.md).
