# M2.1 v0.2R7 Validation Context Projection Correction

The physical policy table and the repaired configuration assertion both
contained the four governed stage-boundary fields:

- `synthetic_data_only_flag`
- `no_final_offer_terms_flag`
- `no_production_adverse_action_flag`
- `acquisition_source_review_only_flag`

Program 135 v0.2R5 referenced those fields through `_m2_1_vctx`, but omitted
them from the temporary table's `SELECT` projection. PostgreSQL therefore
raised SQLSTATE 42703 before positive validation could execute.

Program 135 v0.2R7 explicitly projects all four fields and verifies them
against the approved configuration payload before running the 112 controls.
No validation methodology or business logic changed.
