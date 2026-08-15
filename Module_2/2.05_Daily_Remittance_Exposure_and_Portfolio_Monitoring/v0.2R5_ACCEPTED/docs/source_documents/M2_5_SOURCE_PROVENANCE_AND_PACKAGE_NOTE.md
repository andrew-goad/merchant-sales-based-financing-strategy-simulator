# M2.5 Source Provenance and Package Note

- Accepted baseline: `MSBF_Project_v0_2_M2_4_COMPLETE_FINAL_Windows.zip`
- Accepted baseline SHA-256: `d710885f9dbd5ffb5ed85be1c69d133a5300619da4e2ef6a36b67072a79ca3ec`
- Consolidated source package: `MSBF_M2_5_v0_2R5.zip`
- Consolidated source SHA-256: `c2f4f574ef0158e9d8e290bffff477e7fedc3c86fdaa473466b80c1b718180c5`
- Execution evidence: `module_M2_5_evidence.zip`
- Evidence SHA-256: `4f482a02215293d9a4dffcc888c3ac99ec2cc2594e0d74c0bfbbb1f904928099`
- Accepted revision: `v0.2R5`

The accepted predecessor boundary is:

```text
M2_PORTFOLIO_ACTIVATION_CONSUMPTION v1
M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1
Combined hash: 117450a3eea7bb3d3c74d18cc3c8e96a
Acceptance gate: M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION
```

M2.5 also consumes the accepted M1.6 matched POS/deposit replay through gate
`M1_6_MATCHED_SCENARIO_OVERLAYS` and combined hash
`3f85921bf6fc30ddc6cee146085e58c5`.

The main `sql/` and `tests/` folders preserve the consolidated v0.2R5 clean
build. The `accepted_execution/` folder preserves the exact mixed-revision
source chain used to reach the accepted database state. The original evidence
ZIP and all 36 extracted CSV files are preserved under `evidence/raw/`. The
7,091-assertion review is preserved under `evidence/review/`.

The full project is rebuilt directly from the accepted M2.4 baseline. All
numbered predecessor stages are compared before and after M2.5 integration and
must remain byte-identical. The standalone accepted module and embedded
`24_M2_5` stage must also remain byte-identical.
