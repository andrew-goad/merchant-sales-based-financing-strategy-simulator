# M2.1 v0.2R7 Acceptance Column Qualification

The Program 137 acceptance query joined:

- the contract registry CTE `c`;
- the physical-count CTE `physical`.

Both exposed several identically named columns:

```text
gate_definition_rows
gate_result_rows
latest_rows
archive_rows
comparison_rows
```

The acceptance `CASE` referenced those fields without relation qualifiers,
causing SQLSTATE 42702 before acceptance could begin.

v0.2R7 narrows the registry CTE to the four fields actually needed and
explicitly qualifies every control and physical field. No threshold, count,
hash, lifecycle transition, evidence rule, or business outcome changed.
