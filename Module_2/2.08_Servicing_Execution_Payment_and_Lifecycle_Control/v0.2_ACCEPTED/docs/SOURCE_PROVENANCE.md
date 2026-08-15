# Source Provenance — M2.8 Servicing Execution, Payment & Lifecycle Control

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
27_M2_8
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_188_schema_policy.sql` | `72,999` | `32d1df4de1d4fe4544f75f808acf20d40620c23761499ba9e2d0e21e9dfbf0de` | `accepted_execution/sql/01_188_schema_policy.sql` |
| `02` | CURRENT_NORMAL | `02_189_preflight.sql` | `11,889` | `5e91d83d1bb3fe7ff46841c54e39b4bfa4bdc7c6a9d3cb4241f70ee18a0e66c8` | `accepted_execution/tests/02_189_preflight.sql` |
| `03` | CURRENT_NORMAL | `03_190_generation.sql` | `66,282` | `233852c8e497738aafe3b3368ff15272385a9b05c57047948b6b71c44e8faed5` | `accepted_execution/sql/03_190_generation.sql` |
| `04` | CURRENT_NORMAL | `04_191_positive_validation.sql` | `81,341` | `ede4a609b8aa039b6ec718ed17f2a954caf470adadbcdc2b33ed3e62eefeac12` | `accepted_execution/sql/04_191_positive_validation.sql` |
| `05` | CURRENT_NORMAL | `05_192_negative_controls.sql` | `13,734` | `b81f1699fdacaf79c598dc89bd324e548d67697426d55c91bcb2e7d56bfac4cf` | `accepted_execution/sql/05_192_negative_controls.sql` |
| `06` | CURRENT_NORMAL | `06_193_acceptance_finalize.sql` | `14,816` | `caf841a57b9615efb3b831a9634e8cbd318b45273787069375a5ec834a8ce0df` | `accepted_execution/sql/06_193_acceptance_finalize.sql` |
| `07` | REPORTING | `07_194_master_report.sql` | `12,543` | `d283607820dce42229df05fe47795d1bdaa254f510162be0e427f1a9b4e515a7` | `accepted_execution/tests/07_194_master_report.sql` |
| `08` | REPORTING | `08_195_detail_report.sql` | `17,320` | `528a64ff8dd7ab6d0da8eca4a6f117225db7abf62c4c03bd2e294a13d2a5c990` | `accepted_execution/tests/08_195_detail_report.sql` |
| `188A` | RECOVERY | `188A_failed_schema_policy_recovery.sql` | `3,839` | `49663756457e1d87a94aa69c7c4c3a8ef75fa9b409ed42f84901ee50696697b4` | `accepted_execution/recovery/188A_failed_schema_policy_recovery.sql` |
| `190A` | RECOVERY | `190A_failed_generation_recovery.sql` | `2,832` | `7752749f08f180e7981da76613375ea161f3613c571bab20fae286068c2fa328` | `accepted_execution/recovery/190A_failed_generation_recovery.sql` |
| `190B` | RECOVERY | `190B_generation_reconstruction.sql` | `4,970` | `bce4c279ce8f6f0e077ae467bfc0bd6a313b1cae14838655f920a24b2677eede` | `accepted_execution/recovery/190B_generation_reconstruction.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
