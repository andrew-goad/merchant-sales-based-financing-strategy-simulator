# M2.11 Work Package 5 — Evidence and Lineage Correction R1

## Correction identity

```text
WP5_EVIDENCE_AND_LINEAGE_CORRECTION_R1
```

## Scope

This is a bounded Work Package 5 documentation, catalog, evidence-operability, and package-regeneration correction. It does not reopen WP1–WP4 and does not modify any normal or recovery SQL.

## Corrections

1. Removed the unreachable `M2_11_219_PRIMARY_RESULT / 219_primary_result.csv` export definition.
2. Reconciled the evidence inventory to exactly 38 reachable exports: seven Program 212–218 primary outputs, twenty-four Program 219 detailed outputs, and seven post-chain state exports.
3. Added one unnumbered, SELECT-only post-chain evidence-query utility with exact projections, filters, row expectations, deterministic ordering, timing, and header requirements.
4. Corrected the exact M1.17 and M2.7 predecessor identities in the source-lineage document.
5. Expanded the source-lineage document to show physical source objects, registry, contract or bundle code and version, schema, methodology, gate, accepted rows, and accepted combined hash for all five source families.
6. Regenerated package inventories, manifests, validation controls, ZIP, and external sidecar.

## Preserved byte authorities

```text
Programs 212–219                         BYTE-IDENTICAL
Recoveries 212A, 214A, 214B, 215A       BYTE-IDENTICAL
Approved WP1–WP4 technical catalogs      BYTE-IDENTICAL
WP2 Source Authority R6                  BYTE-IDENTICAL
WP3 R2 and provenance addendum           BYTE-IDENTICAL
WP4 Source Authority R2                  BYTE-IDENTICAL
```

No strategy, objective, constraint, reason, scope, grain, count, score, stress rule, Pareto rule, archive rule, contract rule, lifecycle boundary, M2.12 boundary, or production boundary changed.

## Status

```text
READY FOR LIVE EXECUTION
NOT EXECUTED
NOT VALIDATED
NOT ACCEPTED
PROGRAM 212 NOT AUTHORIZED PENDING NARROW WP5 R1 REVIEW
```
