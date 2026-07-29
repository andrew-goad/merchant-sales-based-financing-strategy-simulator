# M1.3 v0.2R1 Source Package Validation Report

**Overall static status:** `PASS`

## Scope

This report documents source-package checks completed before live PostgreSQL execution. Static validation is not live compilation, transaction execution, or analytical acceptance. The user must execute the controlled scripts and export the required evidence before M1.3 can be signed off.

## Summary

| Control | Result | Evidence |
|---|---|---|
| SQL file inventory | **PASS** | 8 controlled SQL files, including the read-only recovery precheck |
| M1.3 helper functions | **PASS** | 6 expected functions |
| SQL lexical balance | **PASS** | 0 issues |
| Session randomness prohibited | **PASS** | 0 files |
| Structured snapshot accessors | **PASS** | 0 invalid root extractions |
| Destructive stage operations | **PASS** | 0 issues |
| Canonical numeric scale | **PASS** | 0 missing controls |
| Request-path design controls | **PASS** | 0 missing terms |
| Relationship-stage validation specification | **PASS** | Direct utilization-factor control; raw funding-to-sales retained as diagnostic |
| Positive evidence codes | **PASS** | 42 codes |
| Negative controls | **PASS** | 3 codes |
| Detailed report result sets | **PASS** | 12 result sets |
| Physical dependency catalog | **PASS** | 534 columns across 34 tables |
| DML target-column validation | **PASS** | 0 invalid targets |
| Catalog parseability | **PASS** | 0 issues |
| Governed mix reconciliation | **PASS** | {'EXPECTED_PAYOFF_DAYS': {'weight_sum': 1.0, 'count_sum': 750}, 'USE_OF_PROCEEDS': {'weight_sum': 1.0, 'count_sum': 750}} |
| Internal documentation links | **PASS** | 0 broken links |
| Unfinished placeholders | **PASS** | 0 files |
| Known duplicate report fields | **PASS** | 0 issues |

## Prior-defect regression controls

- No use of session-level `random()`.
- No structured JSONB snapshot cast through `#>> '{}'`.
- Canonical monetary and rate values are cast to physical PostgreSQL scale before hashing.
- Product-minimum overrides are explicitly identified rather than hidden as feasible sales-linked requests.
- M1.3 validation requires both on/below-path and above-path request populations.
- Accepted M1.2 entities and M1.3 application rows are never deleted, truncated, or dropped by the package.

## Live-execution requirement

The package has not been executed against PostgreSQL in the artifact-build environment. For a clean first execution, the mandatory live sequence is scripts 17–23. For the submitted v0.2 failed-validation state, use the v0.2R1 recovery sequence beginning with script 16 and do not rerun script 18. Acceptance requires 42/42 positive checks, 3/3 negative controls, zero row mismatches, zero blocking errors, zero downstream rows, and `overall_m1_3_status = PASS`.


## v0.2R1 correction assessed

- The original 750 application rows and application-set hash are not changed.
- Positive control 36 now validates the direct `request_path_utilization_factor` relationship-stage control.
- Raw final funding-to-sales averages and minimum-floor counts remain visible as diagnostics.
- The recovery path preserves the failed review-version-1 gate and creates a new review version on finalization.
- DBeaver reconnection is not a causal factor because all relied-upon objects are committed PostgreSQL objects and the submitted hashes remained unchanged.
