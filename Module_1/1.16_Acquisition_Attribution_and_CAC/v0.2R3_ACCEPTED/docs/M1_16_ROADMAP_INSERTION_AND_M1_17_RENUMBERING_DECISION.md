# M1.16 Roadmap Insertion and M1.17 Renumbering Decision

## Decision status

```text
Decision                         APPROVED FOR FORWARD DEVELOPMENT
Decision point                   After M1.15 acceptance / before final G2 closure
Inserted stage                   M1.16 Acquisition Source, Marketing Attribution & Merchant Acquisition Cost Foundations
Renumbered assurance stage       M1.17 End-to-End QA, Evidence & G2 Contract Acceptance
Existing final gate              G2_M1_CONTRACT — retained for M1.17
```

## Context

M1.15 was formally accepted as the immutable scenario-aware Module 1 application consumption contract. Before the independent G2 closure stage began, the project identified a material enterprise-strategy gap: the accepted platform retained broad parent acquisition channels and a valid M1.14 channel-cost proxy, but did not yet provide governed source/campaign identity, funnel evidence, attribution, cost timing, exact campaign allocation, or a transparent bridge between detailed acquisition cost and the accepted M1.14 proxy.

The gap is material because paid media, direct mail, processor relationships, relationship-manager referrals, strategic partners, brokers, and purchased leads create different direct, allocated, and conditional costs. Top-of-funnel expenditure also includes prospects that never submit an application. A single percentage of requested funding cannot fully represent that operating reality.

## Decision

Insert M1.16 as an additive Module 1 enhancement and move the former M1.16 assurance stage to M1.17.

The revised sequence is:

```text
M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations
         ACCEPTED

M1.15 — Latest Output, Archive, Comparison & Consumption Contract
         ACCEPTED

M1.16 — Acquisition Source, Marketing Attribution
         & Merchant Acquisition Cost Foundations
         BUILT / STATICALLY VALIDATED / NOT YET ACCEPTED

M1.17 — End-to-End QA, Evidence & G2 Contract Acceptance
         PLANNED / NOT BUILT
```

## Architectural basis

M1.16 uses a companion-contract pattern:

```text
Accepted M1.15 scenario-aware contract
+
one M1.16 application-level acquisition contract
=
read-only integrated 1,500-row consumption view
```

M1.16 publishes:

```text
M1_ACQUISITION_CONSUMPTION v1
M1_ACQUISITION_SCHEMA_V1
```

It references, but does not rewrite:

```text
M1_APPLICATION_CONSUMPTION v1
M1_CONTRACT_SCHEMA_V1
```

## Why M1.14 and M1.15 remain closed

M1.14 contains an accepted synthetic channel-cost proxy and remains analytically valid for its approved scope. M1.16 inherits its scenario-invariant rate, amount, row hashes, and combined hash, then makes overlap and incremental cost visible. It does not update M1.14 total non-loss cost, contribution, return, tier, or any accepted hash.

M1.15 remains an accepted immutable contract. M1.16 does not add columns to, regenerate, rearchive, update, or delete any M1.15 registry, latest, archive, or comparison record. The integrated interface is a read-only join.

## Governance consequences

1. The old M1.16 assurance handoff is preserved as superseded roadmap history.
2. The active root next-step pointer now identifies M1.16 acquisition foundations.
3. M1.17 may begin only after live evidence establishes `M1_16_ACCEPTED`.
4. `G2_M1_CONTRACT` remains the final Module 1 gate and is not issued by M1.16.
5. Module 2 remains out of scope until M1.17 independently accepts the final G2 contract boundary.

## Stage boundary

M1.16 is authorized to create synthetic acquisition evidence, attribution, cost allocation, overlap reconciliation, a companion latest/archive contract, and integrated read-only views. It is not authorized to create pricing, approval, decline, counteroffer, funded outcomes, realized CAC, payback, LTV, causal attribution, marketing optimization, or credit-policy use of acquisition source.

## Evidence and package treatment

- Accepted M1.14 and M1.15 source, evidence, sign-offs, and hashes remain byte-preserved.
- The original accepted M1.15 external ZIP and checksum remain valid historical delivery evidence.
- The M1.16-ready derivative corrects only root packaging metadata and forward-looking roadmap/design artifacts.
- M1.17 is documented through a detailed handoff but is not built or executed in this package.

## Approval rationale

The insertion closes a genuine enterprise-learning and economics gap before final G2 certification. Deferring the enhancement until after G2 would either force the final contract to exclude material acquisition evidence or require reopening an already closed Module 1 boundary. Inserting M1.16 now preserves accepted history while allowing M1.17 to certify the true final architecture.
