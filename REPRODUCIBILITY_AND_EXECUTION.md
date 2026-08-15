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
