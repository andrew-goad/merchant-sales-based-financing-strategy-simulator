# M1.16 Live Execution Evidence Review and Formal Sign-Off

## Milestone

**M1.16 — Acquisition Source, Marketing Attribution & Merchant Acquisition Cost Foundations**

**Final determination: PASSED AND ACCEPTED**

```text
Accepted package revision          v0.2R3
Schema / policy revision           v0.2
Generation revision                v0.2R1
Validation through reporting       v0.2R3
Methodology                        M1_16_METHOD_V1
Contract code                      M1_ACQUISITION_CONSUMPTION
Contract version                   1
Schema version                     M1_ACQUISITION_SCHEMA_V1
Final run status                   M1_16_ACCEPTED
Contract status                    ACCEPTED
Acceptance gate                    PASS
Acceptance date                    2026-07-28
```

## Evidence reviewed

The final review covered:

- the v0.2 schema, policy, dictionaries, contract registry, acquisition tables, archive trigger, and consumption views;
- the original pre-commit campaign-evidence projection failure;
- the v0.2R1 recovery, preflight, and committed deterministic generation;
- the initial 111-of-112 POS087 parent-reconciliation result;
- the v0.2R2 governed recovery and corrected parent-channel/evidence-status validation;
- the subsequent 111-of-112 POS050 generation-evidence inventory result;
- the v0.2R3 governed recovery and exact 25-code generation-evidence inventory;
- the final 112 positive controls, 20 negative controls, acceptance finalizer, master report, and all 24 detailed reports;
- the zero-row deterministic-mismatch and blocking-error/stage-boundary outputs.

## Acceptance results

| Control | Final result |
|---|---:|
| Acquisition-source profiles | 18 |
| Acquisition campaigns | 20 |
| Campaign funnel rows | 120 |
| Cost-ledger rows | 40 |
| Application touchpoints | 1,075 |
| Attribution snapshots | 750 |
| Acquisition-cost snapshots | 750 |
| Long-form cost components | 9,000 |
| Latest companion-contract rows | 750 |
| Immutable archive rows | 750 |
| Integrated M1.15 × M1.16 rows | 1,500 |
| Canonical entities | 13,274 |
| Positive validations | 112 / 112 PASS |
| Negative controls | 20 / 20 PASS |
| Deterministic mismatches | 0 |
| Archive mismatches | 0 |
| Blocking/stage-boundary errors | 0 |
| Master report | PASS |

## Deterministic reconciliation

```text
Source-profile set
f29cd5ffd27c2039da5c8ee61440456d

Campaign set
f1c0c9e2c8ee9c1a4700d74018a03a8a

Funnel set
1ebb3e75a96fbf463e7c970e814c77bf

Cost-ledger set
97081e655a81381c13c0ae153c80e53c

Touchpoint set
e75a2f28cfd181fba43450e1405a3444

Attribution set
ff62a26ebe5ad9bd554e696502d47d21

Acquisition-cost snapshot set
9add563f4af9f77d7896142131b91c58

Cost-component set
2fb3311e3e649e25e59cc12a8d3375c1

Latest companion-contract set
a94699d1e65f3787bc184ce7119f5c25

Immutable archive set
6c0469623d892af2d574e8584568bb03

Contract-registry set
5a4b419da2c707504d030bd2aeb0db32

Combined M1.16 canonical set
86df51a0ca68d84096d00ff0f1b19f33
```

The accepted predecessor identities remained unchanged:

```text
M1.14 combined set
3a47f59b56fa158c18c111caa1c64909

M1.15 combined set
fcd2704e17ec0d2e73191ea36061d74b
```

## Accepted acquisition evidence

```text
Acquisition-contract evidence
  COMPLETE                         9
  PARTIAL                          714
  BLOCKED                          27

Attribution evidence
  COMPLETE                         55
  PARTIAL                          680
  BLOCKED                          15

Governed parent-channel mapping
  MATCH                            735
  BLOCKED_CONFLICT                  15
  Physical parent mismatches         0
```

The 15 `BLOCKED_CONFLICT` records preserve the accepted parent channel while explicitly retaining material attribution conflict. They are not converted to favorable `MATCH` evidence.

## Funnel and allocation evidence

```text
TARGETED_OR_ELIGIBLE               4,704
DELIVERED_OR_PRESENTED             4,164
ENGAGED_OR_RESPONDED               1,978
QUALIFIED_LEAD                     1,160
APPLICATION_STARTED                  870
APPLICATION_SUBMITTED                750

Campaign allocation difference      0.00
```

The funnel is monotonically nonincreasing and terminates at the 750 accepted submitted applications. Campaign incurred spend and application allocation reconcile exactly.

## Acquisition-cost foundation

```text
Direct attributable incurred cost                 $6,574.50
Internally allocated cost                         $46,625.00
Detailed incurred acquisition cost                $53,199.50
Detailed conditional partner/broker cost          $213,530.80
Detailed total acquisition cost if booked         $266,730.30
Accepted M1.14 legacy acquisition cost             $315,834.35
Identified supported legacy overlap                $224,293.73
Incremental acquisition cost beyond M1.14          $31,587.73
Supported enhanced total acquisition cost          $335,108.33
```

The enhanced total applies only to the 723 `COMPLETE` or `PARTIAL` records with supported overlap and total-cost evidence. For that supported population:

```text
Supported-population M1.14 legacy cost             $303,520.60
+ Incremental M1.16 cost beyond M1.14              $31,587.73
= Supported enhanced total                         $335,108.33
```

The 27 blocked records retain known components and accepted M1.14 legacy cost but do not receive an unsupported enhanced total.

## Scenario-invariant acquisition contract

The application-level acquisition evidence joins to both accepted M1.15 scenarios without duplication:

```text
BASELINE integrated rows                750
RECESSION_ENERGY integrated rows        750
Average incurred acquisition cost       $70.932667
Average supported enhanced cost         $463.496999
Scenario-specific acquisition drift     0
```

Scenario-specific M1.15 risk and economics remain unchanged while the acquisition fields remain invariant.

## Correction history

1. **v0.2 — campaign projection.** Program 118 omitted `campaign_evidence_status` from an intermediate temporary projection. The transaction stopped before M1.16 business persistence.
2. **v0.2R1 — committed generation and POS087.** Corrected generation committed 13,274 canonical entities with zero mismatches. POS087 then incorrectly treated 15 governed `BLOCKED_CONFLICT` attribution records as physical parent-channel mismatches.
3. **v0.2R2 — parent reconciliation and POS050.** POS087 was corrected to distinguish physical parent identity from evidence status. The retained audit-history record then caused the broad POS050 evidence count to report 26 rather than the exact 25 governed generation records.
4. **v0.2R3 — exact generation-evidence inventory.** POS050 was aligned to the explicit 25-code inventory while retaining both superseded findings as audit history. Final validation returned 112 of 112 passes.

The repository retains the complete detection, recovery, correction, reconciliation, and acceptance record.

## Stage boundary

M1.16 did not create or claim:

- pricing, factor, APR, remittance, or approved amount;
- approval, counteroffer, manual-review decision, or decline;
- funding outcomes or funding probability;
- realized funded CAC, CAC payback, or lifetime value;
- marketing-budget optimization or causal production attribution;
- any mutation of accepted M1.14 or M1.15 business records;
- PII, cookies, device identifiers, email addresses, telephone numbers, or external tracking identifiers.

## Formal authorization

> **M1.16 is passed and accepted. M1.17 — End-to-End QA, Evidence & G2 Contract Acceptance is authorized.**

This acceptance applies to the deterministic synthetic acquisition-source, campaign, funnel, attribution, cost-allocation, M1.14 overlap, companion-contract, immutable archive, and integrated-consumption foundations. It is not production attribution, accounting certification, legal or regulatory approval, marketing optimization, or live credit-decision authorization.
