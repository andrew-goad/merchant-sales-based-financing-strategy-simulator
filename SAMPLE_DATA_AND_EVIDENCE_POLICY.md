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
