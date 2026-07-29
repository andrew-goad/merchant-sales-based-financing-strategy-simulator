# Accepted M1.15 Execution Path

The live accepted path preserved the committed M1.15 generation and corrected only the affected stage onward.

```text
108 v0.2   — Schema, policy, contract registry, tables, trigger, and views
108B R1    — Recovery and installed readiness-function repair
108C R2    — Pristine-state and evidence-type recovery check
109 R2     — Hard-stop preflight
110 R2     — Committed latest/archive/comparison generation
108D R3    — Governed recovery from the POS62 validation-specification finding
111 R3     — Final 84-control positive validation
112 R3     — Seven negative controls
113 R3     — Acceptance finalizer
114 R3     — Master report
115 R3     — Twenty detailed reports
```

The clean-build `sql/` and `tests/` directories contain synchronized v0.2R3 replacements that incorporate all accepted corrections from the outset.
