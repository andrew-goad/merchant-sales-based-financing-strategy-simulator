# M2.9 Positive-Validation Hotfix — v0.2R1

Program 199 v0.2 correctly identified three failed controls, but the failures
were defects in the validation expressions rather than defects in the
committed Program 198 population.

## Corrected controls

### M2_9_POS_056_RETURN_EXCEPTION

The returned event opens the shared exception case but is not itself marked
resolved. Resolution is recorded on the subsequent retry-settled event.

```text
v0.2 defect     returned AND required AND resolved
v0.2R1          returned AND required AND NOT resolved
```

### M2_9_POS_064_EXCEPTION_ID_SHAPE

Program 198 deterministically generates exception identifiers with:

```text
MSBF_EXC_
```

The v0.2 validation incorrectly expected `MSBF_PAY_EXC_`.

### M2_9_POS_066_EVENT_SOURCE_LINEAGE

Program 198 stores the M2.9 payment-source snapshot row hash in
`payment_event_reconciliation_snapshot.source_event_row_hash`.

The source snapshot's `source_event_row_hash` field intentionally retains the
accepted M2.8 event hash. Therefore, validation must compare:

```text
reconciliation.source_event_row_hash = source_snapshot.row_hash
```

—not the nested accepted-M2.8 hash field.

## Unchanged business evidence

Program 196, Program 197, and Program 198 remain valid and must not be rerun.
No schema, source boundary, reconciliation formula, exception case,
account-level outcome, certification state, amount, canonical entity, or
combined-hash logic changed.
