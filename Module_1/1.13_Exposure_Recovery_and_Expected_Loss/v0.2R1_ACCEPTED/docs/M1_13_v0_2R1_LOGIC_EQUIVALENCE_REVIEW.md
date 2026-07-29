# M1.13 v0.2R1 Logic-Equivalence Review

The v0.2R1 package corrects the unsupported Boolean aggregation in program 94.

For programs 93 and 95–99, a SQL-aware normalization removed comments and whitespace while
preserving identifiers, operators, literals, dollar-quoted PL/pgSQL bodies, DML, predicates,
transaction boundaries, and statement order.

| Program class | Files compared | Logic-equivalent |
|---|---:|---:|
| Preflight | 1 | 1 |
| Positive validation | 1 | 1 |
| Negative controls | 1 | 1 |
| Acceptance finalizer | 1 | 1 |
| Master report | 1 | 1 |
| Detail report | 1 | 1 |
| **Total** | **6** | **6** |

Executable differences are confined to program 94:

- two unsupported `max(boolean)` expressions were replaced by `bool_or(boolean)`;
- one aggregate cast was parenthesized for parser clarity.

No exposure, EAD, LGD, recovery, comparative-loss, routing, threshold, cardinality,
hashing, validation, or acceptance formula changed.
