# Governance and Validation

## Governing Principles

**Governed | Deterministic | Auditable | Parameter-Driven | Evidence-Based**

The project does not treat a successful query as acceptance. Every governed stage follows:

```text
Schema / Policy
-> Preflight
-> Deterministic Generation
-> Physical Reconciliation
-> Positive Validation
-> Negative Controls
-> Acceptance Finalizer
-> Master Report
-> Detailed Evidence
-> Formal Sign-Off
-> Versioned Package
```

## Fail-Closed Recovery

When a defect occurs, the workflow:

1. classifies the defect;
2. determines whether the transaction committed;
3. inspects downstream programs for the same defect class;
4. preserves the latest safe committed state;
5. applies one consolidated, version-aligned correction;
6. preserves original failure evidence;
7. refuses to weaken a valid control merely to obtain a pass;
8. replaces final clean-build source only after acceptance.

## Evidence Gates

`COMPLETE`, `PARTIAL`, and `BLOCKED` are analytical states, not presentation labels. Missing evidence is not converted to a favorable value. Blocked rows remain blocked through risk, loss, economics, contracts, and acquisition evidence.

## Hash Discipline

- expected values are cast to target physical types before hashing;
- stored hashes are independently reconstructed from persisted physical fields;
- reporting-only fields are excluded from canonical hashes;
- visible composites reconcile to persisted visible components;
- the M1.17 ordered hash chain certified all 18 G1-through-M1.16 physical identities.

Combined G2 canonical set: `7d9e466da28cad2551aa99c4c40c912b`.

## Positive and Negative Controls

The final M1.17 assurance executed 128 positive controls and 20 intentional negative controls. Negative controls proved that the system rejects invalid lifecycle states, unapproved configuration, archive mutations, contract drift, and prohibited boundaries rather than simply testing the happy path.

## Immutable Archives

Database triggers protect:

- M1.15 application archive;
- M1.16 acquisition archive;
- M1.17 G2 bundle archive.

All latest/archive reproduction checks passed with zero mismatches.

## G2 Boundary

M1.17 proved:

- 750 applications x two accepted scenarios = 1,500 integrated rows;
- zero duplicate application/scenario rows;
- zero scenario-count violations;
- zero prohibited PII columns;
- zero premature Module 2 rows;
- zero deterministic or archive mismatches;
- `G2_M1_CONTRACT = PASS`.

G2 certifies a synthetic Module 1 consumption boundary. It is not production or regulatory approval.
