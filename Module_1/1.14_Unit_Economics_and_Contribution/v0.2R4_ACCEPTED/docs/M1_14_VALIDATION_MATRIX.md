# M1.14 Validation Matrix

## Positive controls

Program 103 executes 82 blocking controls in the following groups:

| Group | Controls | Coverage |
|---|---:|---|
| Governance and upstream identity | 1–14 | Run state, prerequisite gates, accepted hashes, policy, scenarios |
| Cardinality and grains | 15–22 | 1,500 snapshots, 21,000 components, unique grains, matched coverage |
| Revenue and non-loss costs | 23–39 | Request identities, yields, processor, channel, funding, servicing, operating costs |
| Loss, contribution, capital and return | 40–59 | Comparative loss, margins, capital charge, contribution, hurdle, surplus |
| Evidence, tier and routing | 60–70 | Evidence gates, stress floors, tiers, statuses, review and reason logic |
| Long-form reconciliation | 71–72 | Wide-versus-long amount and lineage reconciliation |
| Hashes and boundaries | 73–82 | Set hashes, canonical counts, evidence completeness, no future data, stage boundary |

All 82 controls must return `PASS`.

## Negative controls

Program 104 verifies fail-closed rejection of:

1. Disabled M1.14 generation.
2. Invalid processor-payment cost rate.
3. Invalid economic-tier threshold ordering.
4. Unapproved policy profile.
5. Unapproved accepted stress scenario.
6. Prerequisite run-status drift.
7. Attempted post-generation rerun.

All seven negative controls must return `PASS` while preserving the committed
M1.14 generated evidence and `M1_14_VALIDATED` status.

## Acceptance threshold

Program 105 requires:

```text
82 / 82 positive controls PASS
7 / 7 negative controls PASS
1,500 snapshots
21,000 components
22,500 canonical entities
0 row-hash mismatches
0 stress contribution improvements
0 stress return improvements
0 stress tier improvements
0 downstream latest/archive rows
0 blocking configuration errors
```
