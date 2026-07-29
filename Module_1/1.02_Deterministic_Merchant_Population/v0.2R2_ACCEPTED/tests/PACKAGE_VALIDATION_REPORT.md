# M1.2 v0.2R2 Package Validation Report

## Validation disposition

**Static package status: PASS**

This report validates the delivered M1.2 source package before live PostgreSQL execution. It does not constitute stage acceptance. Live execution, evidence export, independent review, and a formal acceptance milestone remain mandatory.

## v0.2R2 correction validation

The v0.2R1 live execution produced the correct expected and actual canonical entity counts but rejected 817 hashes. The mismatch reconciles exactly to two fixed-scale monetary fields whose expected zero branches were represented as `0` while their persisted physical values were represented as `0.00`:

| Entity | Field | Affected rows |
|---|---|---:|
| `RELATIONSHIP_SNAPSHOT` | `total_prior_funded_amount` | 481 |
| `OWNER_GUARANTOR` | `guarantee_capacity_amount` | 336 |
| **Total** |  | **817** |

v0.2R2 applies physical-type casts before canonical JSONB hashing and adds entity-level mismatch diagnostics. The prior v0.2R1 typed JSONB parameter-access correction remains in force.

## Package inventory and structural checks

| Validation item | Observed | Status |
|---|---:|---|
| SQL files | 8 | PASS |
| Deterministic helper/blueprint functions | 7 | PASS |
| Positive readiness checks | 36 | PASS |
| Negative controls | 3 | PASS |
| Detailed-report result sets | 10 | PASS |
| Physical dependency tables checked | 36 | PASS |
| Physical dependency columns checked | 548 | PASS |
| SQL lexical-balance failures | 0 | PASS |
| Invalid INSERT target columns | 0 | PASS |
| Invalid UPDATE target columns | 0 | PASS |
| Prohibited `random()` calls | 0 | PASS |
| Destructive population operations | 0 | PASS |
| Known run-column reference issues | 0 | PASS |
| Invalid structured-snapshot scalar extractions | 0 | PASS |
| Untyped canonical zero branches | 0 | PASS |
| Broken internal Markdown links | 0 | PASS |
| JSON parse failures | 0 | PASS |
| CSV parse failures | 0 | PASS |
| Unfinished placeholder markers | 0 | PASS |

## Required implementation locks

| Control | Result |
|---|---|
| `generation_canonical_entity_lock` | PASS |
| `validation_positive_count_lock` | PASS |
| `finalizer_positive_lock` | PASS |
| `finalizer_negative_lock` | PASS |
| `generation_transaction` | PASS |
| `regeneration_prohibition` | PASS |
| `expected_actual_snapshot_comparison` | PASS |
| `accepted_g1_parameter_hash` | PASS |
| `accepted_g1_profile_hash` | PASS |
| `accepted_g1_source_hash` | PASS |
| `funded_amount_physical_scale` | PASS |
| `repaid_amount_physical_scale` | PASS |
| `guarantee_capacity_physical_scale` | PASS |
| `owner_rate_physical_scale` | PASS |
| `wallet_share_physical_scale` | PASS |
| `mismatch_entity_summary` | PASS |

## Canonical numeric-scale controls

The static validator now rejects untyped `THEN 0::numeric` branches in M1.2 SQL and confirms that the expected canonical payload uses the physical field scales:

```text
total_prior_funded_amount  numeric(18,2)
total_prior_repaid_amount  numeric(18,2)
guarantee_capacity_amount  numeric(18,2)
ownership_rate             numeric(9,6)
wallet_share_proxy          numeric(9,6)
```

The actual snapshot applies the same explicit physical types. Future mismatch errors include entity-level counts and example entity keys.

## Independent design-time reconciliation

The published deterministic rules independently reproduce:

```text
Merchants                            750
Owner/guarantor rows               1,347
Prior-advance merchants              269
No-prior-advance merchants            481
Guarantee-available owners          1,011
No-guarantee owners                   336
Observed v0.2R1 mismatches            817
Canonical deterministic entities    4,352
```

The identity `481 + 336 = 817` confirms the live v0.2R1 failure was a canonical representation issue rather than a population-generation discrepancy.

## Recovery control

The package now includes a read-only recovery-state script that confirms the failed transaction rolled back, all M1.2 entity tables remain empty, G1 statuses and hashes remain unchanged, and a clean rerun is authorized.

## Known validation boundary

A PostgreSQL server was not available in the package-build environment. The corrected SQL has therefore not been represented as live-executed. The following remain mandatory:

1. execute `ROLLBACK;` after the failed v0.2R1 transaction if the session remains aborted;
2. execute the recovery-state check and require `PASS`;
3. rerun the v0.2R2 preflight;
4. execute the corrected generation script once;
5. execute 36 positive checks and three negative controls;
6. finalize the M1.2 gate;
7. export master and detailed evidence;
8. independently review and sign off the stage.

## Conclusion

The M1.2 v0.2R2 package is **statically accepted for controlled live execution**. It is not yet accepted as a completed analytical stage.

## Live-execution acceptance supplement

The structured PostgreSQL evidence dated 2026-07-24 was independently reviewed after source revision v0.2R2.

```text
Recovery state                         PASS
Preflight                              PASS
Merchants                              750
Owner/guarantor rows                 1,347
Canonical expected / actual      4,352 / 4,352
Row-level mismatches                     0
Governed mix deltas                      0
Positive checks                    36 / 36 PASS
Negative controls                    3 / 3 PASS
Blocking errors                          0
Downstream analytical rows               0
Gate status                            PASS
Master report status                  PASS
```

M1.2 is accepted. See `evidence/M1_2_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF.md`.
