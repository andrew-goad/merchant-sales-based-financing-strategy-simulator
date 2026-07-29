# M1.15 Parameter Dictionary

M1.15 is primarily a publication and contract-governance stage. It does not
introduce new credit-risk or economics assumptions.

| Parameter | Value | Purpose |
|---|---|---|
| methodology_version | `M1_15_METHOD_V1` | Governed contract methodology |
| contract_code | `M1_APPLICATION_CONSUMPTION` | Contract identity |
| contract_version | `1` | Contract version |
| schema_version | `M1_CONTRACT_SCHEMA_V1` | Schema identity |
| latest_expected_rows | `1500` | Scenario/application latest cardinality |
| archive_expected_rows | `1500` | Immutable archive cardinality |
| comparison_expected_rows | `750` | Matched comparison cardinality |
| baseline_scenario_code | `BASELINE` | Matched reference |
| stress_scenario_code | `RECESSION_ENERGY` | Matched adverse scenario |
| archive_immutable | `true` | Database-enforced archive contract |
| power_bi_contract_enabled | `true` | Consumption-view publication |
