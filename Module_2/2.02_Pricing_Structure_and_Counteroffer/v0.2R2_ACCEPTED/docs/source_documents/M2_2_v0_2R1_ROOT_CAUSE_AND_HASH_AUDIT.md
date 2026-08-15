# M2.2 v0.2R1 Root Cause and Hash Audit

## Evidence pattern

The original mismatch total was 806. This is not a random population:

```text
All 557 candidate rows
All 249 snapshots carrying selected candidate numeric values
No request-snapshot mismatch family
No no-design snapshot mismatch family
```

That pattern isolates the defect to candidate-derived numeric fields.

## Technical cause

The original source used:

```sql
CREATE TEMP TABLE ... AS SELECT ...
UPDATE ... SET row_hash = hash(to_jsonb(row))
INSERT INTO persistent_table ...
```

CTAS inferred generic numeric types from calculation expressions. Persistent
tables enforce explicit numeric typmods. PostgreSQL performed the typmod cast
during insert, after the hash had already been calculated.

Because the hash is `md5(jsonb::text)`, a numeric value at a different scale
has a different deterministic representation.

## Correction

v0.2R1 uses explicit target-typed temporary tables for:

- `_m2_2_candidate_expected`
- `_m2_2_snapshot_expected`

Every persisted numeric field is assigned to its exact physical type before
the row hash is created.

Latest and archive contracts inherit the corrected target-typed snapshot
values and hashes.

## Preserved logic

No candidate formula, template, selected-candidate rank, route, reason,
disposition, stress floor, expected row count, canonical entity count,
contract identity, source identity, or stage boundary changed.
