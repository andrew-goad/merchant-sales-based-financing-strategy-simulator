# Full Synthetic Table-Data Snapshot

The optional **MSBF Module 1 G2 Full Synthetic Table Data v1.0.0** release asset provides all 110 accepted parent/control/reference tables in both CSV and PostgreSQL INSERT formats.

## Release asset

- [Download `MSBF_Module_1_G2_Full_Synthetic_Table_Data_v1.0.0.zip`](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/module-1-g2-v1.0.0/MSBF_Module_1_G2_Full_Synthetic_Table_Data_v1.0.0.zip)
- [Download the SHA-256 file](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/download/module-1-g2-v1.0.0/MSBF_Module_1_G2_Full_Synthetic_Table_Data_v1.0.0.zip.sha256)

```text
SHA-256      5a1cec08cb0bbd1b28fa0c04800802746159b6b40d105f2db2c0cecfeea5d26d
Size bytes   142,504,187
Tables       110
Rows         1,042,591
Formats      110 CSV + 110 SQL INSERT exports
```

## Accepted boundary

```text
Database             msbf_strategy
Platform             PostgreSQL 15
Governed run         M1_V0_2_BASELINE_BUILD, version 1
Final run status     M1_17_ACCEPTED
Final gate           G2_M1_CONTRACT — PASS
G2 bundle            M1_G2_CONSUMPTION_BUNDLE v1
Combined G2 hash     7d9e466da28cad2551aa99c4c40c912b
```

All records are deterministic and synthetic. The accepted G2 controls found zero prohibited PII columns. The data package also includes an independent header scan with zero potential prohibited-PII findings.

## Package structure

```text
MSBF_Module_1_G2_Full_Synthetic_Table_Data_v1.0.0/
├── README_DATA_SNAPSHOT.md
├── DATA_INVENTORY.csv
├── TABLE_ROW_COUNTS.csv
├── PII_HEADER_SCAN.csv
├── DATA_SNAPSHOT_VALIDATION_REPORT.md
├── SNAPSHOT_METADATA.json
├── SHA256SUMS.txt
├── csv/
│   ├── msbf_ctl/
│   ├── msbf_m1/
│   └── msbf_ref/
├── sql_insert/
│   ├── msbf_ctl/
│   ├── msbf_m1/
│   └── msbf_ref/
└── docs/
    └── DBeaver table-inventory screenshots
```

## Interpretation and restore boundary

This asset contains table data only. It does not independently create schemas, tables, constraints, indexes, sequences, functions, triggers, views, materialized views, custom types, ownership, or privileges.

Use the accepted repository as the governing schema and methodology source. SQL INSERT files should be loaded only into a compatible pre-created schema with dependency-aware controls. The asset has not been certified as a one-command database restore.

## Why the full data are a Release asset rather than repository content

The uncompressed table-data export exceeds one gigabyte and includes individual files larger than GitHub's normal Git-object limit. Keeping the snapshot as a versioned Release asset preserves the repository's readable history while making full synthetic data available to reviewers who need it.
