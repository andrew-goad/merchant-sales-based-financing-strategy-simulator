# M1.2 Live-Execution Evidence Review and Sign-Off

## Final determination

**M1.2 — Deterministic Merchant Population Generation v0.2R2 is PASSED AND ACCEPTED.**

The submitted PostgreSQL evidence demonstrates that the stage executed against the accepted G0/G1 environment, recovered cleanly from the earlier canonical-formatting exception, generated the complete 750-merchant population, reconciled all deterministic entities and governed mixes, passed all positive and negative controls, and preserved the intended stage boundary.

## Execution context

| Attribute | Observed |
|---|---|
| Database | `msbf_strategy` |
| Database user | `postgres` |
| PostgreSQL version | `17.9` |
| Run | `M1_V0_2_BASELINE_BUILD` v1 |
| Population | `MSBF_POP_0001` v1 |
| As-of date | `2026-07-23` |
| Accepted run status | `M1_2_ACCEPTED` |
| Accepted population status | `M1_2_ACCEPTED` |
| Acceptance timestamp | `2026-07-24 01:02:35.284 -0400` |

## Evidence-based acceptance results

| Validation area | Observed | Acceptance result |
|---|---:|---|
| Recovery-state check after failed R1 attempt | `PASS`; all M1.2 entity counts zero | PASS |
| M1.2 preflight | `PASS` | PASS |
| Merchants | 750 | PASS |
| Owner/guarantor rows | 1,347 | PASS |
| Primary-industry rows | 750 | PASS |
| Partner-channel definitions | 5 | PASS |
| Processor accounts | 750 | PASS |
| Relationship snapshots | 750 | PASS |
| Expected canonical entities | 4,352 | PASS |
| Actual canonical entities | 4,352 | PASS |
| Row-level deterministic mismatches | 0 | PASS |
| Governed mix rows | 30; all deltas zero | PASS |
| Positive validation checks | 36 / 36 | PASS |
| Negative controls | 3 / 3 | PASS |
| Failed evidence records | 0 | PASS |
| Blocking resolution errors | 0 | PASS |
| Downstream analytical rows | 0 across applications, POS, deposits, features, risk, EAD, latest, and archive | PASS |
| M1.2 acceptance gate | `PASS` | PASS |
| Master-report status | `PASS` | PASS |

## Hash and rerun reconciliation

| Hash | Stored / expected / actual |
|---|---|
| Parameter snapshot | `bd09e598c82db96e47459d77fd11e7c8` |
| Profile snapshot | `462cbd2ed92f68e5bdecf6b17537a973` |
| Source snapshot | `93c3d1368fb2450ab4a08e2b721f92d3` |
| Population | `9b706c926260a3ef1ae8ac95eed5d0bf` |

The parameter, profile, and source hashes equal their independently recomputed values. The stored, regenerated expected, and persisted actual population hashes are identical:

```text
9b706c926260a3ef1ae8ac95eed5d0bf
```

## Governed population reconciliation

All 30 governed categories reconciled exactly:

- 8 industry categories;
- 5 geography regions;
- 4 merchant-size tiers;
- 4 legal-entity categories;
- 4 relationship stages;
- 5 partner channels.

Every target-versus-actual delta equals zero.

## Realism and integrity diagnostics

- Owner scores range from 524 to 830.
- The population contains 45 major-derogatory owner rows and 10 bankruptcy rows.
- Personal-guarantee availability is present on 1,011 owner rows.
- Business age ranges from 7 to 240 months.
- Processor tenure ranges from 3 to 120 months and does not exceed business age.
- Mixed-signal merchants total 48, or 6.4%, above the 1.0% minimum.
- The mixed-signal sample includes strong-owner/adverse-relationship, weak-owner/positive-relationship, young-business/strong-owner, and larger-merchant/weak-owner patterns.
- Every merchant has one active processor account and one complete as-of relationship snapshot.

## Technical correction history

The initial M1.2 execution encountered two source-package defects before acceptance:

1. v0.2R1 corrected typed extraction from structured G1 parameter-snapshot JSON.
2. v0.2R2 corrected canonical JSONB numeric-scale normalization for fixed-scale zero values.

The recovery-state evidence confirms that the failed generation transaction left no persisted M1.2 rows and preserved the accepted G1 state. The accepted execution uses v0.2R2 and has zero row-level deterministic mismatches.

## Acceptance conclusion

The M1.2 deterministic population satisfies the approved stage requirements:

- exact cardinality;
- complete and unique identity;
- deterministic row-level reproduction;
- exact governed mix allocation;
- temporal integrity;
- synthetic-data and no-PII boundaries;
- mixed-signal realism;
- unchanged G1 governance snapshots;
- empty downstream analytical state;
- formal gate and master-report PASS.

**M1.2 is accepted, and M1.3 — Application and Requested Sales-Linked Structure Generation is authorized.**

## Boundaries

This acceptance applies only to the deterministic synthetic merchant-population stage. It does not accept or certify:

- application or offer structures;
- daily POS or deposit history;
- source evidence;
- engineered features;
- credit, fraud, or data-confidence risk;
- EAD, LGD, Expected Loss, pricing, or profitability;
- production underwriting;
- legal, regulatory, accounting, capital, fair-lending, privacy, information-security, or model-risk conclusions.

Execution logs are not retained in this project package by design. The structured SQL result exports, detailed reports, master report, mismatch/error empty-state files, and completed milestone are the accepted evidence set.
