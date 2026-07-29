# M1.11 Accepted Clean-Build Execution Guide — v0.2R2

## Scope

This guide governs future clean execution of the final corrected M1.11 source. The accepted live milestone was established through the original v0.2 generation plus the governed v0.2R2 remediation path documented in `ACCEPTED_EXECUTION_PATH.md`.

## Clean-build order

```text
76 — Schema and policy extension v0.2R2
77 — Preflight validation v0.2R2
78 — Generation v0.2R2
79 — Positive validation v0.2R2
80 — Negative controls v0.2R2
81 — Acceptance finalizer v0.2R2
82 — Master report v0.2R2
83 — Detailed report v0.2R2
```

## Required final checkpoints

```text
Snapshots                         1,500
Components                        7,500
Applications                        750
Scenarios                             2
Canonical entities                9,000
Positive controls              72 / 72 PASS
Negative controls                6 / 6 PASS
Composite identity violations          0
Stress tier improvements               0
Stress archetype improvements          0
Deterministic mismatches               0
Blocking errors                        0
Run status                 M1_11_ACCEPTED
Master status                       PASS
```

## DBeaver result behavior

Programs 79, 80, 81, and 83 use session-preserved temporary result tables where applicable. Their result grids remain sortable and filterable after COMMIT while the same database session remains open.

## Logic-preservation note

The final presentation cleanup added comments and whitespace only. The executable SQL token sequence is identical to the final v0.2R2 source replacements. See `M1_11_COMMENTARY_ONLY_REFACTOR_VERIFICATION.md`.
