# M1.13 SQL Engineering Audit

## Scope

The final M1.13 source was reviewed against the accepted M1.12 repository and
the M1.13 schema extension before packaging.

## Controls completed

```text
Accepted/revised schema tables parsed      80
Persistent INSERT statements checked       14
Persistent UPDATE statements checked       10
Invalid persistent DML target columns      0
Major INSERT / SELECT shape differences    0
Unsafe schema-qualified whole-row hashes   0
Invalid source_snapshot scenario columns   0
Scalar md5/FILTER defects                  0
Terminal exposure rounding residual risk   mitigated
Filterable validation/report outputs       present
```

## Proactive corrections incorporated

- The final payoff day is hard-set to zero exposure so currency rounding in the
  governed daily-remittance amount cannot leave a terminal penny balance.
- Manual-review and reason routing use the same persisted eight-decimal
  comparative-loss-rate basis presented in the physical snapshot.
- Whole-row hash reconstruction always uses an explicit relation alias.
- The physical dependency catalog reflects the actual application-level
  `source_snapshot` grain; it does not claim a nonexistent `scenario_id`.
- Expected tables are typed to the physical target schema before hashing.
- Generation persists each business output once, ANALYZES it, and downstream
  validation reads the physical records rather than rebuilding business logic.

## Limitation

This audit is static. Controlled live PostgreSQL execution remains the authority
for planner behavior, transactional execution, output distributions, and formal
M1.13 acceptance.
