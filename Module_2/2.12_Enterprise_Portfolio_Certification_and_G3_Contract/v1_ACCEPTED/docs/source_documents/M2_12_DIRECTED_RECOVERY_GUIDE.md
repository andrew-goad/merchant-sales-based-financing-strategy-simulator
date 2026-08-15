# M2.12 Directed Recovery Guide

Recoveries are **contingency-only** and require explicit authorization. They are never part of the normal chain.

```text
Normal:     220 → 221 → 222 → 223 → 224 → 225 → 226 → 227
Recovery:   220A | 222A | 222B | 223A
```

The machine-readable selection authority is `04_catalogs/M2_12_RECOVERY_DECISION_MATRIX.csv`.

## Decision sequence

1. Identify the failed normal program and physical source hash.
2. Determine whether its transaction committed, rolled back, or is ambiguous.
3. Reconstruct current run and registry lifecycle.
4. Count M2.12 canonical rows, generation/positive/negative/acceptance evidence, and G3 gate rows.
5. Read all three owned sequence states where relevant.
6. Prove whether canonical hashes and immutable fingerprints are exact.
7. Select a recovery only when one row of the decision matrix matches every fact.
8. Obtain explicit recovery authorization naming the recovery file and SHA-256.

## 220A — Failed installation recovery

Use only for a diagnosed incomplete Program 220 installation while the governed run remains `M2_11_ACCEPTED` and all non-policy canonical, evidence, and gate state is absent. It may repair/remove only the bounded incomplete installation surface and guarded policy-sequence state. It cannot delete or change a successfully matching policy row merely to permit a rerun.

## 222A — Failed precommit generation/sequence recovery

Use only when Program 222 did not commit any non-policy canonical/evidence/gate state, the run remains `M2_11_ACCEPTED`, and exact ownership/empty-state proof shows archive or registry identity sequences advanced. It may restore only those sequences to the approved initial state. It cannot regenerate business rows.

## 222B — Committed generation checkpoint reconstruction

Use only when all 134 canonical entities and every immutable hash independently reconstruct exactly, the archive and registry identities/sequences are exact committed state, but generation evidence and/or mutable generated lifecycle checkpoint is incomplete. It may restore only the governed generation checkpoint; it cannot mutate canonical/latest/archive/immutable registry fields or sequences.

## 223A — Failed positive-validation recovery

Use only when the generated checkpoint remains exact, positive validation is incomplete, and no negative/acceptance/gate state exists. It may delete only partial `M2_12_POS_%` evidence and restore mutable lifecycle to generated. It refuses complete validation or any negative/acceptance state.

## Programs without a dedicated recovery

- 221: no persistent writes; diagnose the prerequisite discrepancy and stop.
- 224: the outer transaction must roll back all negative evidence on failure; any residual state is an unsupported anomaly requiring audit disposition.
- 225: the acceptance transaction must roll back gate, evidence, and lifecycle writes on failure; any residual or partial acceptance state is an unsupported anomaly.
- 226/227: read-only; no recovery is authorized.

Unsupported state is not a reason to choose the closest recovery. Stop fail-closed and escalate for a bounded correction or new authority.
