# R26 R2 M2.11 Identity Failure and R3 Correction

R26 R2 passed its 41/41 package gate and physically completed compiler M2.5–M2.12 plus final M2.5–M2.10, then stopped fail-closed before loading final M2.11 because the final simulation identity did not equal the compiler identity. The immutable R6 carrier remained unchanged.

Independent comparison of the packaged R2 evidence localized the mismatch to raw Wave A evidence metadata, not business facts:

- `m2_5`, `m2_5_r26`, `m2_6`, `m2_7`, `m2_8`, `m2_9`, and `m2_10` compiler/final exports are byte-exact.
- `WAVE_A_DATABASE_IDENTITY.json` and R26 physical policy controls are exact.
- `stage_registry.csv` differs only in execution-role/timestamp metadata: `contract_authority`, `validated_at`, and volatile time keys embedded in `legacy_registry_payload`.
- `validation.csv` differs only in `evaluated_at`.

R2 incorrectly fed those raw observational fields and their raw CSV hashes into the M2.11 source root. That made deterministic business facts produce different M2.11 row hashes.

R3 corrects only this identity boundary. Before M2.11, it canonicalizes the Wave A stage registry and validation evidence by removing volatile execution times, normalizing the compiler/final role suffix, and preserving all business hashes, populations, statuses, controls, and raw physical exports. M2.7 and M2.10 remain byte-exact physical simulation inputs.

The embedded R2 failure evidence is independently reperformed during R3 package validation. The R3 validator requires the raw R2 stage/validation files to differ, the canonical semantic forms to match, and the reconstructed compiler/final M2.11 simulation identities to become exact.

No R26 monitoring policy, M2.5–M2.10 business logic, M2.11 eight-profile method, M2.12 control population, accepted predecessor, or publication authority changes in R3. A fresh R3 compiler/final run from immutable R6 is authorized because R2 failed due to this localized runtime identity defect.
