# M2.5 Recovery Guide

- Failed Program 164: click Stop, execute `ROLLBACK;`, then run Program 164A. All M2.5 objects and rows should be absent and `recovery_status = PASS`.
- Failed or cancelled Program 166 before commit: execute `ROLLBACK;`, then run Program 166A. Generated M2.5 targets, registry, evidence and acceptance rows must remain zero.
- Lost Program 166 result tab after a successful commit: run Program 166B. It reconstructs the generation checkpoint read-only.
- Failed Program 167 or later after Program 166 commits: do not regenerate. Preserve the committed population and repair only the validation, negative-control, acceptance, or reporting layer proven defective.


## Failed Program 165 v0.2 duplicate projection

Program 165 writes session-temporary objects only. Click Stop, execute
`ROLLBACK;` (a no-transaction warning is harmless), do not rerun Program 164,
and run `165_msbf_m2_5_preflight_validation_v0_2R1.sql`. The corrected script
drops and recreates its temporary objects before evaluation.
