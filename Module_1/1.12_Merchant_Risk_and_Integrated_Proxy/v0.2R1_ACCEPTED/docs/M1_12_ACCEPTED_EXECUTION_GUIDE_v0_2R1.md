# M1.12 Accepted Clean-Build Execution Guide — v0.2R1

## Clean-build order

```text
84 — Schema and policy extension v0.2
85 — Preflight validation v0.2
86 — Integrated-risk generation v0.2
87 — Positive validation v0.2
88 — Negative controls v0.2
89 — Acceptance finalizer v0.2
90 — Master report v0.2
91 — Detailed report v0.2R1
```

## Required final checkpoints

```text
Snapshots                      1,500
Components                    10,500
Applications                     750
Scenarios                           2
Canonical entities             12,000
Positive controls           80 / 80 PASS
Negative controls             7 / 7 PASS
Stress score improvements            0
Stress tier improvements             0
Deterministic mismatches             0
Blocking errors                      0
Run status               M1_12_ACCEPTED
Master status                     PASS
```

The v0.2R1 detail report changes only the final blocking-resolution-error query to use `resolution_error_id`.
