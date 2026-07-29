# M1.3 Live Execution Evidence Review and Formal Sign-off

## Final determination

**M1.3 — Application and Requested Sales-Linked Structure Generation v0.2R1 is PASSED and ACCEPTED.**

The accepted live evidence demonstrates that the 750-row deterministic application population was generated from the accepted G1 configuration and M1.2 merchant population, reproduced with zero row-level mismatches, passed all revised positive and negative controls, and preserved all downstream stage boundaries.

## Evidence reviewed

The review covered the structured CSV outputs for:

- the original M1.3 preflight and generation checkpoint;
- the failed review-version-1 validation evidence;
- the v0.2R1 recovery-state precheck;
- the revised 42-check positive-validation suite;
- the three negative controls;
- acceptance finalization review version 2;
- the one-row master report;
- all twelve detailed-report result sets;
- zero-row deterministic-mismatch and blocking-resolution-error exports.

Execution logs are intentionally excluded under the project evidence policy. The structured exports, source SQL, hotfix documentation, independent review, and completed milestone are sufficient for this synthetic portfolio project.

## Audit history and corrective action

The first M1.3 acceptance review failed one blocking check, `M1_3_POS_36_RELATIONSHIP_DIFFERENTIATION`, while the generated application set itself contained 750 expected and 750 actual rows, zero deterministic mismatches, and identical stored/expected/actual hashes. The original check used unmatched cohort averages of final funding-to-sales ratios, which could be affected by merchant-size composition, payoff-horizon mix, use-of-proceeds mix, and the minimum product floor.

Revision v0.2R1 retained the original 750 application rows and changed only the validation specification. It tests the direct relationship-stage request control, `request_path_utilization_factor`, while retaining raw funding-to-sales ratios as diagnostics. The revised evidence shows:

```text
RETURNING_GOOD request_path_utilization_factor = 0.887308
LOW_AND_GROW  request_path_utilization_factor = 0.801099
```

The original failed review version 1 remains part of the audit history. Review version 2 passed.

## Acceptance reconciliation

| Validation area | Accepted result |
|---|---:|
| Run status | `M1_3_ACCEPTED` |
| M1.3 gate status | `PASS` |
| Acceptance review version | 2 |
| Applications | 750 |
| Unique merchants | 750 |
| Expected canonical application rows | 750 |
| Actual canonical application rows | 750 |
| Row-level deterministic mismatches | 0 |
| Positive checks | 42 / 42 PASS |
| Negative controls | 3 / 3 PASS |
| Failed evidence records | 0 |
| Blocking resolution errors | 0 |
| Downstream analytical rows | 0 |
| Master-report status | `PASS` |

## Hash reconciliation

```text
Parameter snapshot  bd09e598c82db96e47459d77fd11e7c8
Profile snapshot    462cbd2ed92f68e5bdecf6b17537a973
Source snapshot     93c3d1368fb2450ab4a08e2b721f92d3
Population snapshot 9b706c926260a3ef1ae8ac95eed5d0bf
Application set     01485256b9b5748fb412743d35ced602
```

The stored, regenerated expected, and independently recomputed actual application-set hashes are identical.

## Exact governed request mixes

### Expected payoff horizon

```text
30 days  188
60 days  337
90 days  225
Total    750
```

### Use of proceeds

```text
WORKING_CAPITAL    338
INVENTORY          150
EQUIPMENT_REPAIR    90
SEASONAL_NEED       75
EXPANSION           60
EMERGENCY_EXPENSE   37
Total               750
```

Every target-versus-actual delta equals zero.

## Request-population diagnostics

```text
Minimum requested funding       $5,000
Maximum requested funding     $150,000
Average requested funding      $25,446.93
Total requested funding    $19,085,200
Average remittance rate          13.5518%
Average payback multiple           1.19721
Average total repayment        $30,333.38
On-or-below reference path            289
Above reference path                  461
Minimum-product-floor rows             195
Binding-constraint types                 3
Mixed-signal request rows               45
```

The request population intentionally includes structures above the deterministic reference path. M1.3 creates merchant requests; it does not approve exposure or determine affordability.

## Stage-boundary confirmation

The detailed entity-count evidence confirms that the following remain empty:

- source evidence snapshots;
- obligations, collateral, guarantee, and credit snapshots;
- verification results;
- POS and deposit history;
- features and risk snapshots;
- EAD paths;
- latest and archive results.

## Interpretation boundary

This acceptance applies only to deterministic synthetic application and requested sales-linked structure generation. It does not approve credit, pricing, counteroffers, collateral, covenants, legal classification, disclosures, calibrated risk, profitability, accounting, capital, fair lending, servicing, or production use.

The annual-sales and sales-path values used by M1.3 are deterministic request-generation references, not observed underwriting evidence.

## Authorization

**M1.4 — Deterministic Daily POS and Settlement History Generation is authorized.**

Evidence review performed through an AI-assisted independent project-validation process. The project owner retains final governance accountability.
