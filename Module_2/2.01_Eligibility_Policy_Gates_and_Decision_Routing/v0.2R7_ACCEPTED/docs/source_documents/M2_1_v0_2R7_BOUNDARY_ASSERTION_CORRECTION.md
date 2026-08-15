# M2.1 v0.2R7 Boundary Assertion Correction

The prior configuration assertion verified the approved configuration payload
hash but did not compare the physical stage-boundary columns to the payload.

The v0.2R7 clean build explicitly requires:

- `synthetic_data_only_flag = true`
- `no_final_offer_terms_flag = true`
- `no_production_adverse_action_flag = true`
- `acquisition_source_review_only_flag = true`

and requires each physical flag to equal its governed payload value.

The acceptance assertion now calls both the configuration assertion and the
accepted-prerequisite assertion before checking validation evidence.
