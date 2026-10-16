# Tableau companion evidence

The [Tableau companion](docs/tableau/README.md) publishes an authoring definition, a 13-page carousel and matching PNGs. Its displayed analysis covers the complete 750-application matched-scenario cohort; the selected screenshots illustrate cases and are not the entire underlying dataset.

The supplied folder does not bundle a CSV, Hyper extract or packaged workbook. Its `.twb` retains author-local connection references and software-generated authoring metadata; it contains no embedded data and is disclosed as a definition requiring reconnection, not a portable data carrier. A separately packaged workbook would require its own data/public-disclosure review.

Carousel and workbook identities are recorded in the [asset manifest](docs/tableau/manifests/ASSET_MANIFEST.json). Exact image bytes are preserved, with filenames corrected against the PDF subjects. This companion does not replace the separately defined 50-application public review cohort or the historical full-table snapshot.

---

# Sample Data and Evidence Policy

## Synthetic Data Boundary

All records in this repository are synthetic. No PII, real merchant information, production credit policy, or operational decision output is included.

## Full-Population Evidence vs. Public Samples

Portfolio metrics, validation conclusions, hashes, and acceptance decisions use the complete accepted population. Public CSVs are compact review artifacts and are never described as the full output unless they are full aggregate control sets.

## Controlled 50-Application Public Review Cohort

The release defines `PUBLIC_REVIEW_COHORT_V1`:

- 40 channel-balanced applications: eight from each accepted parent acquisition channel;
- 10 governance-coverage anchors selected from accepted G2 sample evidence;
- stable Public Review IDs `MSBF-PRC-001` through `MSBF-PRC-050`;
- canonical application and merchant IDs retained beside each public ID;
- both matched scenarios retained for scenario-aware materialized records;
- no public ID is written to the accepted PostgreSQL database.

The cohort set hash is `d44e563a81380a45cf81499d0daebbab`.

Artifacts:

- [`PUBLIC_REVIEW_COHORT_REGISTRY.csv`](./docs/project_lineage/public_review_cohort/PUBLIC_REVIEW_COHORT_REGISTRY.csv)
- [`PUBLIC_REVIEW_COHORT_COVERAGE.csv`](./docs/project_lineage/public_review_cohort/PUBLIC_REVIEW_COHORT_COVERAGE.csv)
- [`PUBLIC_REVIEW_COHORT_ANCHOR_INTEGRATED_RECORDS.csv`](./docs/project_lineage/public_review_cohort/PUBLIC_REVIEW_COHORT_ANCHOR_INTEGRATED_RECORDS.csv)
- [`PUBLIC_REVIEW_COHORT_SELECTION.sql`](./docs/project_lineage/public_review_cohort/PUBLIC_REVIEW_COHORT_SELECTION.sql)

The cohort is a review-and-coverage cohort, not a statistically population-weighted sample.

## Zero-Row Exception Evidence

Accepted deterministic-mismatch and blocking-error exports retain headers and contain zero data rows. This preserves the tested schema and makes the meaning of a clean result visible.

## Archive Scope

The public repository excludes the complete raw DBeaver export history, every superseded SQL revision, and full operational-scale archives. Those remain in the private canonical repository. The public release preserves accepted source, selected evidence, formal sign-offs, aggregate results, and correction-history summaries.

## Optional Full Synthetic Table-Data Release Asset

The first formal GitHub Release provides an optional [full synthetic table-data snapshot](./docs/data_snapshot/README.md) for reviewers who need complete table-level access.

```text
110 designed tables
1,042,591 total table rows
110 CSV exports
110 PostgreSQL INSERT exports
0 potential prohibited-PII header findings
```

The large snapshot is distributed as a GitHub Release asset rather than committed to normal Git history. It does not replace the Controlled 50-Application Public Review Cohort, and it is not a one-command database backup. The accepted source repository remains authoritative for schema creation, database objects, and governed execution.
