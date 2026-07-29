# M1.16 Design and Generation Specification

## Deterministic population
The generator consumes accepted physical M1.2/M1.3/M1.14/M1.15 rows. It does not call upstream generation blueprints. Application ordering and all source/campaign/touch/cost assignments use stable accepted keys and deterministic sequence rules.

## Source and campaign design
- Five accepted parent channels are preserved.
- Eighteen normalized source profiles sit below those parent channels.
- Twenty campaigns cover processor, bank relationship, paid/owned/organic digital, strategic partner, and broker/lead paths.
- Campaign dates span the accepted application boundary and every primary application maps to one active approved campaign.

## Funnel
Six normalized stages end at `APPLICATION_SUBMITTED`. Counts are campaign aggregate evidence; nonapplicants are not materialized as person-level records. Submitted counts reconcile exactly to 750 applications.

## Touchpoints and attribution
Every application has one to three touchpoints. Exactly one primary touch carries weight 1.0; assisted touches carry weight 0.0. Source/campaign evidence status propagates to touchpoint and attribution evidence. Attribution is descriptive and allocative, not causal.

## Cost allocation
Every campaign has one incurred/allocated ledger line and one conditional-on-funding line. Incurred cost is allocated only to primary-attributed applications. Whole cents are allocated by deterministic quotient/remainder order on application ID, producing exact physical reconciliation.

## M1.14 bridge
Accepted M1.14 acquisition rate/amount are verified scenario-invariant and inherited once per application. M1.16 calculates detailed cost, supported overlap, unmapped legacy proxy, incremental cost beyond M1.14, and enhanced total if booked without altering M1.14.

## Evidence gates
Known components remain visible. `BLOCKED` overlap or attribution leaves unsupported overlap/incremental/enhanced totals null. Unknown cost is not converted to zero. Supported zero requires an explicit basis.

## Persistence and hashing
Expected rows are created in physical target types, hashed before persistence, and then reconstructed from physical rows. The generation transaction fails unless all 13,274 canonical entities reconcile with zero mismatches.
