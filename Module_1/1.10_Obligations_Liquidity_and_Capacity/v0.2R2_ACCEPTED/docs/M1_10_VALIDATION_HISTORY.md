# M1.10 Validation and Correction History

## v0.2 — Initial source

The schema and policy extension passed. The initial preflight correctly showed that all predecessor gates, row counts, scenario counts, and stage boundaries were ready, but it failed because the source referenced a nonexistent `M1_2_POPULATION_SET_HASH` run-evidence code.

DBeaver also warned about intentional full-table updates on temporary expected-result tables. Those statements calculated row hashes for every temporary expected row but did not explicitly state the scope.

## v0.2R1 — Preflight hash and DBeaver safety correction

v0.2R1:

- sourced the M1.2 identity from `msbf_m1.population_registry.population_hash`;
- bounded temporary expected-table hash updates with `WHERE row_hash IS NULL`;
- preserved all business formulas and thresholds;
- produced 906 obligation rows and 1,500 capacity rows;
- reconciled 2,406 canonical entities with zero mismatches.

Program 71 then exposed a validation-source parser defect before any validation evidence committed.

## v0.2R2 — Validation syntax correction

v0.2R2:

- rewrote the stress non-improvement test with `NOT EXISTS`;
- corrected a latent parenthesis defect in the no-future-data test;
- corrected cast placement around filtered aggregates in downstream acceptance/reconstruction logic;
- preserved the committed v0.2R1 business rows and hashes.

Final results:

```text
70 / 70 positive controls PASS
6 / 6 negative controls PASS
0 deterministic mismatches
0 stress improvements
0 blocking errors
M1_10_ACCEPTED
overall_m1_10_status = PASS
```

No generation row or business value changed between v0.2R1 generation and v0.2R2 acceptance.
