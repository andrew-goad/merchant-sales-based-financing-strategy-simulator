# M1.10 Execution and Validation Guide

## Prerequisite

The accepted run must be `M1_9_ACCEPTED` in database `msbf_strategy`.

## Normal order

| Order | Script | Required checkpoint |
|---:|---|---|
| 1 | 68 schema/policy extension | `schema_policy_extension_status = PASS` |
| 2 | 69 preflight | `preflight_status = PASS` |
| 3 | 70 generation | `generation_status = PASS`, 1,500 capacity rows, zero mismatches |
| 4 | 71 positive validation | 70/70 PASS, `M1_10_VALIDATED` |
| 5 | 72 negative controls | 6/6 PASS |
| 6 | 73 acceptance | gate PASS, `M1_10_ACCEPTED` |
| 7 | 74 master report | `overall_m1_10_status = PASS` |
| 8 | 75 detail report | 18 result sets; mismatch/error sets empty |

## DBeaver execution controls

Use **Execute SQL Script**. Stop on the first exception. Never use Retry, Skip, or Skip All after an error. Run `ROLLBACK;` after a failed transactional script. Do not delete business rows or manually reset run status.

Validation, negative-control, and detail-report temp tables use `ON COMMIT PRESERVE ROWS`, so their result grids remain filterable in the same DBeaver session after commit.

## Contingency scripts

- 68A: run after failed/cancelled generation and rollback to prove nothing committed.
- 70A: use only when generation committed but the DBeaver result tab was lost.
