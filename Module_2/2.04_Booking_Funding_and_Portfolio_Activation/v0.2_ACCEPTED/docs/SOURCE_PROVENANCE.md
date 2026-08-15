# Source Provenance — M2.4 Booking, Funding & Portfolio Activation

## Governing baseline

```text
Accepted full-project archive
M2_12_FULL_PROJECT_ACCEPTED_20260812.zip

Physical SHA-256
2d2524dae3802eb757197b75d7aeab94b64239cc2cb4585ff2599a728283a17a

Accepted stage path
23_M2_4
```

The public source files below are exact byte copies selected from the accepted full-project repository. Selection favors the final non-superseded authority for each program and excludes diagnostic, historical, and explicitly superseded SQL from executable folders.

## Published source identities

| Program | Classification | File | Bytes | SHA-256 | Accepted archive path |
|---|---|---|---:|---|---|
| `01` | CURRENT_NORMAL | `01_156_schema_policy.sql` | `86,676` | `eb673af9966986614a67a203bf7d1807c72aa809d71f512b4c2d0928f617745a` | `accepted_execution/sql/01_156_schema_policy.sql` |
| `02` | CURRENT_NORMAL | `02_157_preflight.sql` | `17,942` | `b8d2176a8defc1948f63c53cd1410efe567fc429fe5ce35cec77730daa711fe2` | `accepted_execution/tests/02_157_preflight.sql` |
| `03` | CURRENT_NORMAL | `03_158_generation.sql` | `82,138` | `60a3880304cd83b0d42f22cfa2d5f870f2d281bf0698e2ba6be20899d3650747` | `accepted_execution/sql/03_158_generation.sql` |
| `04` | CURRENT_NORMAL | `04_159_positive_validation.sql` | `104,738` | `21c1d825f1049205c4d0fb9914ee32ee7c07f521bcb36548e10fe1109715d0e9` | `accepted_execution/sql/04_159_positive_validation.sql` |
| `05` | CURRENT_NORMAL | `05_160_negative_controls.sql` | `23,656` | `d0fc73a8e12245300c38cac9d88122887401a6f3a685a09e8d448a53bedb54f3` | `accepted_execution/sql/05_160_negative_controls.sql` |
| `06` | CURRENT_NORMAL | `06_161_acceptance_finalize.sql` | `17,494` | `a24ef1aae7e64cfa768eaaffc356c4856b325a176c1dea7404f8de597e28de16` | `accepted_execution/sql/06_161_acceptance_finalize.sql` |
| `07` | REPORTING | `07_162_master_report.sql` | `15,188` | `6f6a68d7d559a55d84d5ec6ade9e50de519dfc140e5b827d7a4fec1095edbb69` | `accepted_execution/tests/07_162_master_report.sql` |
| `08` | REPORTING | `08_163_detail_report.sql` | `28,395` | `ab2f47a240cb4bd9adba9f6b07124733ad7658cbdc87af4ed51a782ef1aca47f` | `accepted_execution/tests/08_163_detail_report.sql` |
| `156A` | RECOVERY | `156A_msbf_m2_4_failed_schema_policy_recovery_check_v0_2.sql` | `6,756` | `9f57eb54bf49758778cf760b04c7cdc5bcd6581d6693e6a1e159a8a715475ea8` | `tests/156A_msbf_m2_4_failed_schema_policy_recovery_check_v0_2.sql` |
| `158A` | RECOVERY | `158A_msbf_m2_4_failed_generation_recovery_check_v0_2.sql` | `4,812` | `f1f6d653867bda4a4401987f9cb910a9b711bee16dae6c2741184382cc318a71` | `tests/158A_msbf_m2_4_failed_generation_recovery_check_v0_2.sql` |
| `158B` | RECOVERY | `158B_msbf_m2_4_generation_reconciliation_reconstructed_v0_2.sql` | `5,520` | `6cec4b8f80a5f32cc6c70cec90ae56b8bad7f44f35f78a52b6905c8ee2aaf30f` | `tests/158B_msbf_m2_4_generation_reconciliation_reconstructed_v0_2.sql` |

## Classification rules

- `CURRENT_NORMAL` — current governed normal-chain SQL.
- `REPORTING` — current read-only master/detail or export SQL.
- `RECOVERY` — current contingency source; never a normal-chain substitute.

## Limitation and boundary

The public package does not silently reconstruct missing executed source and does not label derived documentation as byte-identical source. Internal-only delivery paths, sandbox links, and redundant superseded packages are intentionally excluded from the public projection.
