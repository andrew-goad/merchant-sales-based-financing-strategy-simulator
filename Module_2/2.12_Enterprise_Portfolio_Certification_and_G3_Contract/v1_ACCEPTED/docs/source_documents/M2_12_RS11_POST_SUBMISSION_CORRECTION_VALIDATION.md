# M2.12 Result Set 11 Post-Submission Correction Validation

## Corrected physical identity

```text
Filename
MSBF_M2_12_Enterprise_Portfolio_Certification_&_Consumption_Contract_Detail_Report_v1_Full_1500_Row_Application_Detail_20260812.csv

Bytes
607,719

SHA-256
bd81106ace62fece19f86c528478a672dc0500cb77a72f5f3409bef10338fc7c

Data rows
1,500

Columns
18
```

## Prior superseded export

```text
Bytes
80,281

SHA-256
f820387c499555cfd2dd1d9d7a3f4445ac5fe9642b222a4640b8c447f8a78226

Data rows
200
```

The corrected file's first 200 data rows match the complete prior export row-for-row. The corrected file then supplies the remaining 1,300 governed rows.

## Independent physical/content controls

```text
Controls                              16 / 16 PASS
Blocking failures                     0
BASELINE rows                         750
RECESSION_ENERGY rows                 750
Distinct applications                 750
Distinct merchants                    750
Unique scenario/application keys      1500
Missing lineage rows                  0
Invalid hash-format rows              0
Evidence-status domain                BLOCKED=1500
RS10 reconciliation                   PASS
Frozen ordering                       PASS
```

## Governance treatment

- The original `module_M2_12_evidence.zip` remains unchanged and is retained as the initial raw submission.
- The current final evidence paths use the corrected 1,500-row file.
- The prior 200-row export is preserved as superseded historical evidence.
- `AUDIT-HOLD-001` is builder-classified as **RESOLVED**, subject to independent auditor recalculation.
- This correction does not resolve the separate runtime transcript/process-record finding.
