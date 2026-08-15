# M2.10 Program 208 Negative-Control Correction — v0.2R5

## Observed result

```text
Program 207 v0.2R3    120 / 120 PASS
Program 208 v0.2R1     19 / 20 PASS
```

## Failed control

```text
M2_10_NEG_012_INVALID_KPI_APPLICABILITY
```

The legacy applicability constraint used:

```sql
(applicable_flag AND kpi_value_numeric IS NOT NULL)
OR (NOT applicable_flag AND kpi_value_text='NOT_APPLICABLE')
```

For the deliberately invalid row `(false, 1.0, null)`, the expression evaluates
to SQL `NULL`, not `FALSE`. PostgreSQL CHECK constraints reject `FALSE` but
accept `TRUE` or `NULL`, so the invalid row was admitted and the negative
control correctly reported a failure.

The same legacy expression existed on the physical
`msbf_m2.portfolio_kpi_snapshot` table. The current-database repair therefore
replaces the physical constraint, not merely the test table.

## Corrected contract

An applicable KPI must have a numeric value and no text value. A non-applicable
KPI must have no numeric value and the exact text `NOT_APPLICABLE`.

```sql
(
    applicable_flag IS TRUE
    AND kpi_value_numeric IS NOT NULL
    AND kpi_value_text IS NULL
)
OR
(
    applicable_flag IS FALSE
    AND kpi_value_numeric IS NULL
    AND kpi_value_text IS NOT NULL
    AND kpi_value_text='NOT_APPLICABLE'
)
```

## Current database sequence

```text
ROLLBACK
→ 208A v0.2R2
→ 208B v0.2R2
→ 208 v0.2R2
→ 209 → 210 → 211
```

Programs 204–207 must not be rerun. Program 208B changes only the CHECK
constraint. It does not modify any business row, hash, canonical identity,
evidence row, or lifecycle status.
