# Release Notes — M1.2 v0.2R2

- Corrects canonical hash mismatches caused by numeric-scale differences between expected zero values and persisted `numeric(18,2)` values.
- Reconciles the observed 817 mismatches to 481 no-prior-advance relationship rows and 336 no-guarantee owner rows.
- Casts monetary and rate values to their physical PostgreSQL types before canonical JSONB hashing.
- Adds entity-level mismatch summaries and example keys to future generation exceptions.
- Retains the v0.2R1 correction for typed access to structured G1 parameter snapshots.
- Preserves accepted G0 and G1 state and hashes.

## Cumulative M1.2 scope

- Corrects structured JSONB parameter extraction from `run_parameter_snapshot.resolved_value` by reading `value_numeric` rather than casting the full snapshot object.
- Adds a static validation rule that rejects scalar-root extraction (`#>> '{}'`) from structured run-parameter snapshots.
- Adds a fail-closed M1.2 preflight.
- Adds exact largest-remainder category allocation and deterministic rank assignment.
- Adds merchant, owner/guarantor, industry, channel, processor, and relationship generation.
- Adds expected-versus-actual canonical row snapshots and comprehensive population hashing.
- Adds 36 positive checks and three negative controls.
- Adds formal M1.2 acceptance finalization, master report, detailed report, evidence template, and M1.3 handoff.
- Preserves accepted G1 hashes without modifying the G1 parameter, profile, or source snapshots.
- Adds a reusable static package validator, physical dependency catalog, package validation report, execution guide, and SHA-256 manifest workflow.
## Live acceptance — 2026-07-24

- Recovery-state validation confirmed the earlier failed generation left zero persisted M1.2 rows.
- Preflight passed against the unchanged accepted G1 state.
- The v0.2R2 generator created 750 merchants and 4,352 canonical deterministic entities.
- Expected and actual entity counts match; row-level mismatch count is zero.
- All 30 governed mix categories reconcile exactly.
- Thirty-six positive checks and three negative controls pass.
- The M1.2 gate and one-row master report both equal `PASS`.
- M1.2 is formally accepted and M1.3 is authorized.
- Structured CSV exports are the accepted evidence set; execution logs are intentionally not retained.
