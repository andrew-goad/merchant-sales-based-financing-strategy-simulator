# M1.15 Validation and Correction History

## v0.2 — Initial source

- Schema and policy/contract extension: PASS.
- Preflight: PASS.
- Generation stopped before commit because a chained `USING (scenario_id)` followed a left relation that already exposed two scenario identifiers.

## v0.2R1 — Join and readiness repair

- Recovery and function repair: PASS.
- Hard-stop preflight: PASS.
- Operational joins were fully qualified and a recursive readiness function was repaired.
- Generation then stopped before commit because a mixed evidence `UNION ALL` attempted to reconcile text-resolved nulls with a bigint mismatch count.

## v0.2R2 — Committed contract generation

- Recovery: PASS; zero M1.15 business/evidence/gate rows.
- Preflight: PASS.
- Generation: one registry row, 1,500 latest rows, 1,500 immutable archive rows, 750 matched comparison rows, 3,751 canonical entities, zero mismatches.
- Positive validation: 83 of 84 PASS.
- The sole finding was POS62, which treated a one-row continuous resilience-score increase as prohibited.

## v0.2R3 — Accepted resilience-contract alignment

- Recovery proved continuous score increases = 1, resilience-tier improvements = 0, archetype-risk-rank improvements = 0, and all canonical hashes unchanged.
- POS62 was aligned to the accepted M1.11 contract while preserving the score movement as descriptive evidence.
- Final positive validation: 84 of 84 PASS.
- Negative controls: 7 of 7 PASS.
- Acceptance gate and contract lifecycle: PASS / ACCEPTED.
- Master report: PASS.
- All 20 detailed reports completed; mismatch and blocking-error outputs are empty.

## Final accepted state

```text
Run status        M1_15_ACCEPTED
Contract status   ACCEPTED
Package           v0.2R3
Generation        v0.2R2
Methodology       M1_15_METHOD_V1
Schema            M1_CONTRACT_SCHEMA_V1
Combined hash     fcd2704e17ec0d2e73191ea36061d74b
```
