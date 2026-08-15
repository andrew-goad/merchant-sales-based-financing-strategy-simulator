# M2.5 Validation History

## Governed execution and correction chain

### Program 164 — schema, policy and definitions

Program 164 completed successfully. It registered the M2.5 policy, accepted
M2.4 and M1.6 source identities, six statuses, seven alerts, 24 reasons,
functions, views and the acceptance gate.

### Program 165 — preflight projection correction

The original Program 165 failed before preflight completion because five
policy-declared and observed source fields projected duplicate CTAS output
names. Program 165 v0.2R1 separated the policy and physical source namespaces.
The corrected preflight returned PASS with all M2.5 targets empty, 59 active
source rows, 270,000 accepted M1.6 POS rows, 270,000 accepted M1.6 deposit rows,
and at least 120 replay days available.

### Program 166 — deterministic generation

Program 166 completed successfully and committed 7,536 canonical entities:
59 source rows, 7,080 daily rows, 59 latest contracts, 59 immutable archive
rows, 240 portfolio daily summaries, 15 matched comparisons and one registry
row. It returned zero row mismatches and zero stress improvements.

### Program 167 — latest/archive validation correction

The original validation returned 119 PASS and one false failure because the
archive payload intentionally excluded the system-managed latest `created_at`
column. Program 164B v0.2R3 proved 59 original comparison mismatches, zero
corrected mismatches and unchanged generated hashes. Program 167 v0.2R2 then
returned 120 of 120 PASS and transitioned the run and contract to VALIDATED.

### Program 168 — negative-control diagnostic correction

The original Program 168 reached Control 020 but failed on malformed PostgreSQL
`format()` diagnostic text. The transaction rolled back without persistent
negative evidence. Program 168A v0.2R4 proved the validated lifecycle, 120
positive passes, zero negative evidence and rejection of all prohibited
servicing/notice payloads. Corrected Program 168 v0.2R4 returned 20 of 20 PASS.

### Program 169 — active-count acceptance correction

The original acceptance reproduction used end-of-day paid-off semantics to
reproduce a start-of-day active-advance count. Program 169A v0.2R5 identified
46 payoff-event days, proved the original mismatch, and demonstrated zero
mismatches under the generation-aligned definition. Corrected Program 169
v0.2R5 returned acceptance PASS and committed:

```text
run_status       M2_5_ACCEPTED
contract_status  ACCEPTED
gate_status      PASS
```

### Programs 170 and 171 — reporting closure

Program 170 returned `overall_m2_5_status = PASS`. All 24 Program 171 result
sets were exported. Deterministic mismatches and blocking/stage-boundary
violations retained headers and contained zero rows.

## Final closure

The generated business population and deterministic identities were not
changed by any hotfix. The exact successful and recovery/proof source chain is
preserved under `accepted_execution/`. The clean-build source remains v0.2R5.
