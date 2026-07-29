# M1.4 Live Execution Evidence Review and Formal Sign-Off

## Stage

**M1.4 — Enterprise Merchant Ecosystem / Deterministic Daily POS and Settlement History**

## Final disposition

> **PASSED AND ACCEPTED**

The submitted live PostgreSQL evidence supports formal acceptance of M1.4 v0.2. The stage preserves the accepted G0, G1, M1.2, and M1.3 foundations; generates the complete governed baseline merchant-day history; reproduces the persisted result set deterministically; passes all positive and negative controls; and leaves all excluded downstream stages empty.

## Execution environment

| Attribute | Observed |
|---|---|
| Database | `msbf_strategy` |
| Database user | `postgres` |
| PostgreSQL version | `17.9` |
| Run | `M1_V0_2_BASELINE_BUILD` v1 |
| Population | `MSBF_POP_0001` v1 |
| Evidence date | 2026-07-24 |

The Windows operating environment is inherited from the accepted G0 execution evidence.

## Prerequisite preservation

| Control | Result |
|---|---|
| G1 gate | PASS |
| M1.2 gate | PASS |
| M1.3 gate | PASS |
| Parameter snapshot | Exact stored/recomputed match |
| Profile snapshot | Exact stored/recomputed match |
| Source snapshot | Exact stored/recomputed match |
| Population hash | Exact stored/recomputed match |
| Application-set hash | Exact stored/recomputed match |

```text
Parameter snapshot  bd09e598c82db96e47459d77fd11e7c8
Profile snapshot    462cbd2ed92f68e5bdecf6b17537a973
Source snapshot     93c3d1368fb2450ab4a08e2b721f92d3
Population hash     9b706c926260a3ef1ae8ac95eed5d0bf
Application hash    01485256b9b5748fb412743d35ced602
```

## Core output acceptance

| Measure | Observed | Required | Status |
|---|---:|---:|---|
| Baseline POS-day rows | 135,000 | 135,000 | PASS |
| Merchants | 750 | 750 | PASS |
| Calendar dates | 180 | 180 | PASS |
| Minimum date | 2026-01-25 | 2026-01-25 | PASS |
| Maximum date | 2026-07-23 | 2026-07-23 | PASS |
| Expected canonical rows | 135,000 | 135,000 | PASS |
| Actual canonical rows | 135,000 | 135,000 | PASS |
| Row-level mismatches | 0 | 0 | PASS |
| Positive checks | 52/52 | 52/52 | PASS |
| Negative controls | 4/4 | 4/4 | PASS |
| Failed evidence | 0 | 0 | PASS |
| Downstream rows | 0 | 0 | PASS |
| Blocking errors | 0 | 0 | PASS |

## Deterministic reconciliation

The stored, expected, and independently recomputed actual POS-history hashes match exactly:

```text
Stored    d1971e8d319483c187ec0c0483a31e33
Expected  d1971e8d319483c187ec0c0483a31e33
Actual    d1971e8d319483c187ec0c0483a31e33
```

The row-level mismatch export contains headers and zero data rows.

## Operating-ecosystem diagnostics

The accepted population includes:

```text
8 industries
7 cash-flow archetypes
320 stable merchants
76 growing merchants
33 declining merchants
118 seasonal merchants
86 volatile merchants
34 recent-disruption merchants
83 thin-history merchants
```

Directional diagnostics are coherent:

- Growing merchants: first 30-day average sales **$4,345.74**; last 30-day average **$5,647.98**.
- Declining merchants: first 30-day average sales **$3,550.24**; last 30-day average **$2,842.91**.
- Recent-disruption event average sales **$804.18** versus normal-state average **$2,665.52**.
- Restaurant weekend factor exceeds professional-services weekend factor.
- All five acquisition channels map to governed positive processor-fee assumptions.
- Settlement-delay reproduction reports zero lag violations.
- Processor/data-connection statuses reconcile across active, degraded, outage, and pre-open states.

## Portfolio-level synthetic totals

```text
Gross POS sales          $448,665,263.23
Eligible POS sales       $434,530,056.67
Settlement amount        $433,767,730.89
Processor fees           $11,610,716.69
Net merchant proceeds    $422,157,014.20
Zero-sales share         20.8541%
Processor outage share   0.1244%
Degraded share           0.5148%
Refund rate              2.4695%
Chargeback rate          0.3836%
Reversal rate            0.2975%
```

These figures are synthetic demonstration outputs, not production benchmarks or forecasts.

## Stage-boundary confirmation

The evidence confirms zero rows in:

- scenario-adjusted POS history;
- deposit and liquidity history;
- source-quality snapshots;
- obligation, collateral, guarantee, credit, and verification snapshots;
- feature and risk outputs;
- EAD paths;
- Module 1 latest and archive outputs.

M1.4 therefore remained within its accepted scope.

## Acceptance conclusion

M1.4 deterministic enterprise merchant ecosystem history passed all defined structural, temporal, deterministic, economic-reconciliation, distribution, operating-event, source-lineage, negative-control, and stage-boundary acceptance criteria.

> **M1.4 is formally accepted. M1.5 — Daily Deposit & Liquidity History Generation is authorized.**

## Boundaries

This acceptance applies only to synthetic baseline daily POS and settlement history. It does not validate real merchant or processor behavior, deposit data, scenario forecasts, calibrated risk, pricing, legal classification, servicing performance, accounting, capital, fair lending, compliance, or production use.
