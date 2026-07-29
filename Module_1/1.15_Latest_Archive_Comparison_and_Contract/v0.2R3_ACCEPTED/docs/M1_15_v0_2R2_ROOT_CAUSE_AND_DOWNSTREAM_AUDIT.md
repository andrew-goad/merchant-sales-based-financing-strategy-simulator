# M1.15 v0.2R2 Root Cause and Downstream Audit

## Observed failure

```text
SQLSTATE 42804
UNION types text and bigint cannot be matched
```

The error position falls within program 110's final generation-evidence INSERT.

## PostgreSQL type-resolution mechanism

A chain of `UNION ALL` operations is resolved from left to right. The first five
branches used an unknown `NULL` in the numeric evidence column. Because the
intermediate UNION contained only unknown values in that position, PostgreSQL
resolved the column to `text`. The sixth branch introduced a `bigint` mismatch
count, which cannot be unioned with the already resolved text column.

## R2 correction

The evidence rows are staged in a table whose column types exactly match
`msbf_ctl.run_evidence`:

- `metric_value_numeric numeric(24,10)`
- `metric_value_text text`

Each row is inserted separately with explicit casts, and a guard requires seven
rows with exactly one populated value field per row.

## Downstream audit

Programs 111, 113, 110A, and 115 contain canonical or diagnostic UNIONs. R2
explicitly casts every entity key and row hash to text and casts the diagnostic
NULL segment key to text. No remaining operational UNION contains an untyped
NULL in a mixed-type column.

## Logic preservation

The v0.2R1 and v0.2R2 business transformation sections are identical. The only
executable change in generation is the representation of evidence persistence
and explicit type declarations around canonical UNION branches.
