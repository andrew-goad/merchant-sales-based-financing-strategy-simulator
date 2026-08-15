# Campaign-Scale Governance Boundary

## Current status

```text
Module 1 / G2                         ACCEPTED
Module 2 / G3                         ACCEPTED
Campaign preparation                  ACTIVE
750 accepted-fidelity replay          NOT YET AUTHORIZED
2,500 performance shakedown           NOT YET AUTHORIZED
25,000 full campaign                  NOT YET AUTHORIZED
Production deployment                 NOT AUTHORIZED
```

## Permitted preparation

- freeze campaign identities, counts, dates, parameters, and expected-results formulas;
- construct stage overlays without changing accepted business semantics;
- compile read-only checkpoints and report definitions;
- validate the native adapter against a disposable PostgreSQL database;
- isolate normal and recovery programs;
- prepare deterministic evidence retention and performance measurement.

## Prohibited

- connecting the campaign harness to the accepted certification database;
- mutating accepted M2.12 source or accepted evidence;
- silently substituting recovery source into the normal chain;
- claiming campaign, production, empirical, or causal results before execution and review;
- authorizing Module 3 through campaign preparation.

## Advancement path

```text
CR-WP1 through CR-WP7 approved
→ separate authorization for 750 accepted-fidelity replay
→ exactness and evidence review
→ separate authorization for 2,500 performance shakedown
→ performance and control review
→ separate authorization for 25,000 full campaign
```

Each boundary is fail-closed. Completion of one step does not automatically authorize the next.
