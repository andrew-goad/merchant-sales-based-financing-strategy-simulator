# Checkpoint and Report Definition Rebase

```text
Non-report checkpoint inventory rows             174
Active checkpoint specifications                 166
Existing compiled checkpoint definitions         154
  Existing generated read-only queries           127
  Existing program-output assertions              27
New M2.11/M2.12 checkpoints to compile            12
M1.17 positions blocked by provenance              8

Report definitions                                56
  Existing reusable definitions                   52
  New M2.11/M2.12 definitions                      4
Master report programs                            28
Detail report programs                            28
Detailed result sets                             554
Total governed report result sets                582
New result-retention rows to compile              50
```

No new checkpoint SQL or report wrapper SQL is generated in this rebase. The output
is the exact definition delta for a later Harness v0.4 compilation package.
