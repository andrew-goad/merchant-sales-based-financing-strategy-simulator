# M2.5 Source Provenance and Package Note

M2.5 was built from the formally accepted full-project repository:

```text
MSBF_Project_v0_2_M2_4_COMPLETE_FINAL_Windows.zip
SHA-256: d710885f9dbd5ffb5ed85be1c69d133a5300619da4e2ef6a36b67072a79ca3ec
```

The governed predecessor boundary is:

```text
M2_PORTFOLIO_ACTIVATION_CONSUMPTION v1
M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1
Combined hash: 117450a3eea7bb3d3c74d18cc3c8e96a
Acceptance gate: M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION
```

M2.5 also consumes the accepted M1.6 matched POS/deposit daily scenario history through gate `M1_6_MATCHED_SCENARIO_OVERLAYS` and dynamically resolves the accepted `M1_6_COMBINED_SET_HASH` evidence value from the database. No accepted predecessor object is regenerated or rewritten.

The standalone module and embedded full-project module are required to remain byte-identical. Full-project packaging validates CRC, complete extraction, inventory equality, in-archive SHA-256, extracted-file SHA-256, Windows ZIP metadata, and byte preservation of numbered stages `01_Design` through `23_M2_4`.
