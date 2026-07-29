# M1.15 Architecture

```text
Accepted M1.7–M1.14 persisted evidence
                |
                v
      1,500 scenario/application inputs
                |
                +-------------------------------+
                |                               |
                v                               v
  Scenario-aware latest contract      Immutable archive copy
          1,500 rows                       1,500 rows
                |                               |
                +---------------+---------------+
                                |
                                v
                  Matched baseline/stress
                       comparison
                         750 rows
                                |
                                v
                 Contract registry and hashes
                         one row
                                |
            +-------------------+-------------------+
            |                   |                   |
            v                   v                   v
       Latest view       Comparison view      Power BI view
```

The architecture consumes accepted physical outputs. It does not regenerate any
upstream blueprint or analytical model. The archive is database-enforced as
append-only. All contract rows retain upstream row hashes and lineage payloads.
