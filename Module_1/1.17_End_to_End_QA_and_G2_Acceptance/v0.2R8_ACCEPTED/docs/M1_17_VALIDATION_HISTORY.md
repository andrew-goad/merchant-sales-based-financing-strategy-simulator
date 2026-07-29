# M1.17 Validation and Correction History

## Accepted revision map

| Stage | Accepted revision |
|---|---|
| Schema/policy extension | v0.2 |
| Gate predicate, preflight, generation, initial validation | v0.2R2 |
| Final positive-validation evidence recovery | v0.2R5 |
| Negative controls | v0.2R5 |
| Acceptance finalizer and master report | v0.2R6 |
| Detailed report | v0.2R8 |
| Final accepted package | v0.2R8 |

## History

1. **Original preflight gate predicate:** the v0.2 source queried the wrong G2 gate relation. Program 124B proved the catalog row already existed; Program 124C installed the correct predicate and preflight passed.
2. **Source completeness:** the original v0.2 ZIP did not contain Program 127. The v0.2R2 recovery delivery supplied the missing governed positive-validation program and aligned Programs 125–131.
3. **POS007 false negative:** the stored policy hash was valid, but the hash-shape implementation returned a false fail. Programs 124E/124F proved the deterministic payload identity and restored 128/128 passing evidence.
4. **Noncanonical revalidation:** Program 127 was rerun after validation, producing expected lifecycle-boundary failures. Program 124F preserved that rerun and restored the accepted validation boundary.
5. **Acceptance evidence value contract:** the first finalizer populated numeric and text evidence values simultaneously. v0.2R6 staged one text value—the combined G2 hash—and acceptance committed successfully.
6. **Read-only report corrections:** v0.2R7 qualified `scenario_id`; v0.2R8 used the accepted `contract_row_hash` fields. All 24 result sets then completed.

The final accepted evidence contains 128 positive PASS records, 20 negative PASS records, 16 generation PASS records, one acceptance PASS record, and two superseded history records. There are no current failed M1.17 evidence records.
