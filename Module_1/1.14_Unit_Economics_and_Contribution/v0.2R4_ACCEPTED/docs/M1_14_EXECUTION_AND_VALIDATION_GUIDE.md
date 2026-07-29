# M1.14 Execution and Validation Guide

## Prerequisite

The governed run must be in `M1_13_ACCEPTED` status. Programs 100 through 107
must be executed in one database named `msbf_strategy` using **Execute SQL
Script** in DBeaver.

## Normal sequence

```text
100 schema and policy extension
101 preflight
102 generation
103 positive validation
104 negative controls
105 acceptance finalizer
106 master report
107 detailed report
```

### Program 100

Expected:

```text
unit_economics_table_exists = true
component_table_exists      = true
lineage_view_exists         = true
snapshot_columns            = 74
component_columns           = 14
active_features             = 14
policy_status               = APPROVED
methodology_version         = M1_14_METHOD_V1
schema_policy_extension_status = PASS
```

### Program 101

Expected final field:

```text
preflight_status = PASS
```

Stop immediately if preflight does not pass.

### Program 102

Expected:

```text
run_status               M1_14_GENERATED
snapshot rows            1,500
component rows           21,000
applications               750
scenarios                    2
canonical entities       22,500
row-level mismatches          0
generation_status          PASS
```

After a successful commit, do not rerun program 102.

### Programs 103–105

```text
103: 82 / 82 PASS and run_status M1_14_VALIDATED
104:  7 /  7 PASS and run_status remains M1_14_VALIDATED
105: gate PASS and run_status M1_14_ACCEPTED
```

Programs 103 and 104 leave session-scoped temporary result tables available for
sorting and filtering after commit in the same DBeaver connection.

### Programs 106–107

Program 106 must return one row with:

```text
overall_m1_14_status = PASS
```

Program 107 produces 20 result sets. Result sets 19 and 20 must contain their
headers and zero data rows.

## Failure handling

- Click **Stop** on the first PostgreSQL error.
- Do not select Retry, Skip, or Skip All.
- Execute `ROLLBACK;` after a failed transactional program.
- Do not delete business rows or manually reset run status.
- Use program 100A only after a pre-commit generation failure.
- Use program 102A only after generation committed but the result tab was lost.

## Evidence filenames

Use a consistent date suffix and preserve version `v0_2` in exported filenames.
Execution logs are optional; structured CSV evidence is sufficient.
