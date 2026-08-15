# M2.7 Recovery Guide

## Failed Program 180

Click Stop, execute `ROLLBACK;`, then run Program 180A. Recovery must be PASS.

## Failed or cancelled Program 182

Click Stop, execute `ROLLBACK;`, then run Program 182A. Programs 180 and 181
remain authoritative and all generated targets must be empty.

## Lost Program 182 result tab

Run Program 182B. It reconstructs lifecycle, physical counts, exact
distribution, exposure, hashes, canonical identity, and stress diagnostics
without writes.

After committed generation, repair only a proven downstream defect. Do not
regenerate the accepted population without evidence of a generation defect.

## SQLSTATE 23502 in Program 182 v0.2

Use Program 182 v0.2R1 after rollback and a passing Program 182A recovery check. The correction is limited to the staging-only `contract_row_hash` NOT NULL inheritance.
