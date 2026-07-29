# M1.7 Design and Generation Specification

## 1. Business objective

M1.7 separates the quality of available evidence from the quality of the merchant. Missing, stale, partial, or conflicting data must not be silently translated into low sales, poor credit, no obligations, no collateral, or failed verification.

## 2. Output contract

| Element | Specification |
|---|---|
| Physical table | `msbf_m1.source_snapshot` |
| Grain | run × application × source |
| Expected rows | 5,250 |
| Applications | 750 |
| Source families | 7 |
| As-of date | Accepted run/application as-of date |
| Canonical identity | `merchant_application_id | source_code` |
| Deterministic proof | row hash plus complete source-set hash |

## 3. Source dimensions

Each source snapshot preserves availability, history depth, completeness, freshness, reconciliation, quality status, data confidence, fallback path, and source/run/application lineage.

## 4. Governed sources

| Source | Grain | Core M1.7 treatment |
|---|---|---|
| POS_DAILY | merchant/date | Actual connected/delayed history, freshness, completeness, paired reconciliation |
| DEPOSIT_DAILY | merchant/date | Governed source availability, active-window history, paired reconciliation |
| BUSINESS_CREDIT | application/as-of | Deterministic point-in-time availability and freshness |
| OWNER_CREDIT | application/party/as-of | Owner-count expected observations, bounded partial/missing behavior |
| VERIFICATION | application/check/as-of | Active-check count, bounded partial/missing behavior, fail-closed if unavailable |
| OBLIGATIONS | application/obligation/as-of | Point-in-time availability, fallback to manual obligation review |
| COLLATERAL_AVAILABILITY | application/type/as-of | Point-in-time availability, unsecured fallback when absent |

## 5. POS and deposit paired-source logic

M1.7 reduces accepted M1.4 and M1.5 histories to one merchant-level daily-evidence aggregation. Reconciliation is calculated only when both POS and deposit sources are available:

```text
Reconciliation score = min(
  aligned deposits / expected captured proceeds,
  expected captured proceeds / aligned deposits,
  1
)

expected captured proceeds = aligned net merchant proceeds × governed merchant capture rate
```

When either source is unavailable, reconciliation is null rather than zero. Missing evidence is therefore not interpreted as contradictory evidence.

## 6. Threshold precedence

Effective thresholds apply the stricter requirement across the global parameter set and the approved source contract:

- history requirement = maximum(global, contract);
- completeness pass = maximum(global, contract);
- freshness pass = minimum(global age, contract SLA);
- reconciliation pass = maximum(global, `1 − contract tolerance`).

## 7. Confidence and fallback

The source confidence score is a bounded synthetic index combining availability, completeness, freshness, reconciliation where applicable, conflict penalty, and insufficient-history penalty. It is not a calibrated model score.

Critical fallback routes include:

| Condition | Fallback |
|---|---|
| POS unavailable | `FAIL_CLOSED_NO_POS` |
| Verification unavailable | `FAIL_CLOSED_VERIFICATION` |
| Deposit unavailable | `POS_ONLY` |
| Business credit unavailable | `CASHFLOW_OWNER_FALLBACK` |
| Owner credit unavailable | `BUSINESS_CASHFLOW_REVIEW` |
| Obligations unavailable | `MANUAL_OBLIGATION_REVIEW` |
| Collateral unavailable | `UNSECURED_PATH` |
| Source conflict | `MANUAL_REVIEW_SOURCE_CONFLICT` |
| Insufficient POS/deposit history | source-specific insufficient-history route |
| Warning-quality source | `SOURCE_REFRESH` |

## 8. Application-level diagnostics

Validation and reporting calculate a non-persisted weighted application-confidence diagnostic:

```text
POS 35% | Deposit 20% | Verification 15% | Business credit 10%
Owner credit 8% | Obligations 7% | Collateral 5%
```

Missing critical POS/deposit evidence applies governed penalties. The final underwriting feature is created later from the accepted source snapshots.

## 9. Deterministic and performance architecture

```text
Accepted physical histories
→ bounded merchant aggregation
→ 750 application inputs
→ 5,250 application/source grid
→ one deterministic transformation
→ persisted source snapshots
→ one canonical reconciliation
```

All random-looking assignments use stable keys and seed labels. Session-level `random()` is prohibited. Generation cannot rerun after source snapshots exist. Validation and reporting do not reconstruct daily histories or scenario panels.

## 10. Stage boundary

M1.7 establishes whether each source is available and fit for downstream use. It does not create the substantive obligation, collateral, credit, or verification evidence.
