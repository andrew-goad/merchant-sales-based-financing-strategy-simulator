# M2.3 v0.2R2 Policy Hash and Acceptance-Gate Correction

The original Program 148 inserted the literal `TEMP_HASH` into a column whose
check constraint requires a 32-character lowercase hexadecimal hash. PostgreSQL
checks constraints before later statements run, so the intended follow-up
`UPDATE` could never repair the row.

v0.2R2 creates an exact target-typed policy seed, calculates the physical row
hash before insertion, and inserts only a valid deterministic identity.

The downstream audit also found that the M2.3 acceptance gate had not been
registered in `msbf_ref.acceptance_gate_catalog`. v0.2R2 registers and verifies
the gate before generation, preventing a later Program 153 foreign-key failure.
