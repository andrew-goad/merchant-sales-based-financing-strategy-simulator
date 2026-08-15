# M2.2 v0.2R2 Target-Typed Hash Correction

The original Program 142 calculated candidate and pricing-snapshot hashes in
untyped CTAS staging tables. PostgreSQL then coerced their numeric values into
the persistent contract typmods during `INSERT`.

The hash function operates on `jsonb::text`; numeric scale is therefore part
of the deterministic representation. Values such as a rate produced at scale
four can persist at scale six, creating a physical-row hash mismatch even
when the business value is numerically equal.

v0.2R2 assigns candidate and selected-snapshot values to explicit target
types before hashing. Candidate formulas, ranking, route logic, template
eligibility, stress controls, counts and contract identities are unchanged.
