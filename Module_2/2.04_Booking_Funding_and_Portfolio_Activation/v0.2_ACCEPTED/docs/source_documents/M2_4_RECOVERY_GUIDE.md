# M2.4 Recovery Guide

## Failed Program 156

1. Click **Stop**.
2. Execute `ROLLBACK;`.
3. Run Program 156A.
4. Require `recovery_status = PASS` before applying one consolidated schema/policy correction.

## Failed or cancelled Program 158 before commit

1. Click **Stop**.
2. Execute `ROLLBACK;`.
3. Run Program 158A.
4. Require zero target/evidence/acceptance rows and `recovery_status = PASS`.
5. Rerun only the corrected Program 158 path.

## Lost Program 158 result tab after commit

Run Program 158B. It is read-only and reconstructs lifecycle, physical counts and deterministic hashes.

## Validation/report defect after committed generation

Preserve the M2.4 generated population. Correct Program 159 or later only. Do not regenerate source, activation, account, advance, portfolio, latest or archive rows unless physical-generation evidence proves they are defective.
