# G1 Package and Live-Execution Validation Report

**Package:** `merchant_sales_based_financing_g1_governed_run_readiness_v0_2_COMPLETE`  
**Gate:** G1 — Governed Run and Configuration Readiness  
**Acceptance date:** 2026-07-23  
**Disposition:** **PASS / ACCEPTED**

## Static package validation

- SQL files: 9
- Positive readiness checks defined: 20
- Negative controls defined: 3
- Internal Markdown link issues: 0
- SQL lexical-balance issues: 0
- Invalid INSERT target-column issues: 0
- TODO/FIXME/TBD placeholders: 0

## Live PostgreSQL evidence

- Database: `msbf_strategy`
- PostgreSQL: 17.9
- Run status: `G1_READY`
- Population status: `READY_FOR_GENERATION`
- Parameter snapshots: 401 rows / 155 required names
- Profile snapshots: 18 rows / 15 domains
- Source snapshots: 7 rows / 7 contract-ready
- Positive checks: 20/20 PASS
- Negative controls: 3/3 PASS
- Failed evidence: 0
- Blocking resolution errors: 0
- Pre-authorization analytical rows: 0
- Master-report status: PASS
- Gate status: PASS

## Reproducibility

Parameter, profile, and source hashes matched their independently recomputed values and remained unchanged after rerunning scripts 03 and 04.

## Disposition

**PASS — G1 is accepted. M1.2 deterministic merchant population generation is authorized.**
