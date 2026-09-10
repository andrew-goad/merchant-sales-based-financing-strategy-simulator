# MSBF execution runbook — PUB-RUN-001

**R1 · September 4, 2026 · Prepared and offline-tested; final release binding / Windows qualification remain open.**

Read [Quick Start](QUICK_START_RUNBOOK.md) or the [one-page roadmap](MSBF_Execution_Roadmap_R1.pdf). Use [the complete procedure](REPRODUCIBILITY_AND_EXECUTION.md) or the matching [PDF](MSBF_Control_Party_Execution_Runbook_R1.pdf).

**Default route:** verify the source, reproduce the M2.11 calculation offline, reconcile the accepted evidence, and retain the run record. PostgreSQL is not required for that route.

**Checkpoint database route:** only after run-specific approval, use the original frozen retained-final launcher. It executes M2.11/M2.12 from exact existing R6/R2 checkpoint databases. It is not a clean G0-to-R26 bootstrap.

**Fresh-machine / empty database:** do not run the historical catalog as a script loop. Final integrated source, seed/restore or normal-plan binding, and independent Windows qualification are required. These are tracked in [the closure matrix](registers/PUB_RUN_001_CLOSURE_MATRIX.csv).

All new tools are Python standard library only; they do not create, write to or drop databases. `offline_replay.py` executes only the locked source-owned offline proof with process/network calls disabled. Input archives are external dependencies, not secretly embedded in this small runbook.

## Package navigation

- `tools/`: source/evidence identity, safe extraction, offline reproduction and environment probes.
- `registers/`: immutable reference hashes, source inventory, historical sequence and open gates.
- `templates/`: operator/reviewer record, checkpoint list and exception log.
- `support/`: qualification, final binding and software/source references.
- `tests/` and `validation/`: reproducible test suite and actual build results.
- `source_references/`: small exact reference documents; not alternate executable entry points.

The runbook ZIP uses the short internal root `runbook/`. Extract to `C:\MSBF` for the documented paths. Logs go outside that frozen root. No changes were made to the engine, accepted PBIX, cohort report or visual candidates.

## Qualification package boundary

This ZIP is the controlled runbook-review package. It is not an already-qualified public cold-start release. Supporting reference copies and local validation receipts retain review/provenance status; execution logs and workstation paths are private evidence. Select public documentation/tools through the later repository integration review rather than uploading this review ZIP wholesale.
