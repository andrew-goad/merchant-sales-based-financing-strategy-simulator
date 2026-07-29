# Run, Version, Comparison, and Evidence Standard
## Merchant Sales-Based Financing Strategy Simulator v0.1R1

# 1. Identity hierarchy

```text
campaign_id
  └── comparison_id / experiment_id / scenario_set_id
        └── module run_id
              └── row-level business key
```

# 2. Run identity

Every run records:

- module name/version;
- technical run ID;
- parent/upstream run ID;
- population and portfolio snapshot IDs;
- application/performance/stress as-of date;
- scenario/strategy/policy/experiment versions;
- product/legal/operating/jurisdiction/regulatory profiles;
- parameter and source snapshots;
- contract version;
- code commit/hash;
- start/end/status;
- owner and reviewer.

# 3. Deterministic business IDs

Recommended deterministic IDs:

- merchant: hash of population ID + merchant sequence;
- application: merchant + application sequence/date;
- facility: merchant + relationship sequence;
- advance: facility + advance sequence;
- candidate: application + strategy + candidate-grid coordinates;
- experiment assignment: application + experiment + assignment seed;
- stress result: portfolio snapshot + scenario + entity.

# 4. Latest and archive

- archive is the governed source of truth;
- latest is a selected accepted run derived from archive;
- rerunning the same business key and version must either reproduce exactly or fail with a conflict;
- a changed parameter/profile/code/source version creates a new run identity;
- no archive comparison uses timestamp alone.

# 5. Matched comparison rules

## M1 scenario comparison

Hold population and intrinsic merchant data constant. Compare by merchant application ID.

## M2 strategy/experiment comparison

Hold accepted M1 source run, population, and application constant. Compare by application ID.

## M3 lifecycle comparison

Hold booked advance and source performance history constant. Compare policy/action recommendations by advance/facility and review date.

## M4 stress comparison

Hold accepted portfolio snapshot and strategy constant when isolating scenario effects; hold scenario constant when isolating strategy effects.

# 6. Evidence levels

| Evidence | Grain | Examples |
|---|---|---|
| Run | one run | row count, totals, averages, acceptance result |
| Segment | run × segment | industry, partner, risk, health, collateral, relationship |
| Row diagnostic | business key | component contributions, candidate comparison, state cause |
| Comparison | baseline/challenger pair | deltas, migrations, marginal populations |
| Governance | run × gate | pass/fail, reviewer, residual issue, action |

# 7. Acceptance record

An accepted run records:

```text
acceptance_status
accepted_use
prohibited_use
material_findings
residual_limitations
required_follow_up
reviewer
review_date
next_review_date
```

# 8. Campaign registry

A campaign states:

- business question;
- run inventory;
- intended comparisons;
- required controls;
- success/failure criteria;
- risk/experiment budgets;
- evidence set;
- final recommendation.

# 9. Reproducibility tests

- profile/source/code hashes match;
- repeated run row hashes match;
- comparison keys cover the same population;
- no missing baseline/challenger rows;
- totals reconcile to row-level data;
- accepted evidence resolves to archived output;
- compliance package hash resolves to final offer.
