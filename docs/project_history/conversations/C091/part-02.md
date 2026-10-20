# MSBF - Power BI Executive Portfolio Intelligence

Part 02 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-01.md)
[Next part](part-03.md)

<a id="m-225867d9-2d54-41b6-ba3c-069153681087"></a>
## Assistant · C091-M00025

C091-M00025 · 2026-08-18T20:11:55.376652-04:00 · active path

Preceding visible parent: [C091-M00024](part-01.md#m-bbb21604-867e-414d-9670-66379361465c)

<!-- BEGIN_SOURCE_MESSAGE -->
# A1a local Power BI Desktop setup

Treat this as a **controlled local-engine evidence run**, not ordinary report development. The authorized boundary is exactly:

```text
14 semantic tables
6 relationships
47 Power Query queries
0 measures
0 report pages
A1b NOT STARTED
```

The audit expressly prohibits A1b, measures, report pages, PBI-WP2 acceptance, or claims that the full dashboard has been built or validated. [export reference: filecite | turn9file1 | L55-L74] The three controls below must remain open until the Independent Audit reviews the physical evidence:

```text
AUD-SCN-004   HOLD_LOCAL_DESKTOP_EVIDENCE
AUD-REL-005   HOLD_LOCAL_DESKTOP_EVIDENCE
AUD-ASOF-003  HOLD_LOCAL_DESKTOP_EVIDENCE
```

[export reference: filecite | turn9file1 | L45-L53]

The run must also preserve `module1_run_id`, `scenario_id`, the run/scenario/application account grain, the 59-path/44-identity population interpretation, the July 23, 2026 source cutoff, and the thirteen endpoint-only/no-back-casting controls. [export reference: filecite | turn9file0 | L11-L24]

## Files to download first

Download these five files into your Windows **Downloads** folder:

1. A1a local-construction package (historical reference: `sandbox:[session]/MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818.zip`; referenced bytes not established here)
2. Package SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818.zip.sha256`; referenced bytes not established here)
3. Desktop execution and evidence runbook (historical reference: `sandbox:[session]/MSBF_PBI_A1A_LOCAL_DESKTOP_EXECUTION_AND_EVIDENCE_RUNBOOK_20260818.md`; referenced bytes not established here)
4. Corrected E12 post-save manifest helper (historical reference: `sandbox:[session]/Export-A1aPostSaveManifest_FIXED.ps1`; referenced bytes not established here)
5. Supplemental E08 orphan and filter-behavior DAX queries (historical reference: `sandbox:[session]/A1A_E08_ORPHAN_AND_FILTER_BEHAVIOR_QUERIES.dax`; referenced bytes not established here)

Use the corrected E12 helper rather than the copy inside the ZIP. The packaged E12 script has an erroneous leading backslash that prevents it from parsing. The supplemental DAX file supplies the six orphan and filter-behavior tests not present in the original evidence-query file.

---

## 1. Install or verify the required software

### Power BI Desktop

Use the current **standard 64-bit Power BI Desktop**, installed from Microsoft’s normal Power BI Desktop distribution—not **Power BI Desktop optimized for Power BI Report Server**. Microsoft no longer supports 32-bit Desktop, and PBIP projects are not supported in the Report Server-optimized edition. [export reference: cite | turn892161search14 | turn977778view0]

Open **Help → About** in Desktop and verify that the product name does **not** say:

```text
Power BI Desktop optimized for Power BI Report Server
```

### PowerShell 7

Open Windows Terminal or PowerShell and run:

```powershell
winget install --id Microsoft.PowerShell --source winget
```

Microsoft identifies WinGet as the recommended PowerShell installation route on Windows clients. [export reference: cite | turn685883view0]

After installation, open **PowerShell 7** from the Start menu and verify:

```powershell
$PSVersionTable.PSVersion
```

The major version must be `7`.

### DAX Studio

Run this from an elevated Windows Terminal or PowerShell window:

```powershell
winget install daxstudio.daxstudio --scope machine
```

The machine/all-users installation is important because it registers DAX Studio in Power BI Desktop’s **External Tools** ribbon. The current-user and portable installations do not provide that same integration. [export reference: cite | turn427188search0 | turn427188search10]

Restart Power BI Desktop after installing DAX Studio.

**Tabular Editor is not required for this A1a run.** Do not use it to alter the model.

---

## 2. Verify the package and extract it to a short local path

Do not extract the project under OneDrive, SharePoint, a network drive, or a deeply nested Downloads folder. Microsoft documents a default 260-character PBIP path limit and recommends a short local root; it also warns that locally synchronized OneDrive folders can cause save failures. [export reference: cite | turn977778view0]

Open **PowerShell 7** and run this entire block:

```powershell
$downloads = Join-Path $HOME "Downloads"

$zip = Join-Path $downloads `
    "MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818.zip"

$sidecar = Join-Path $downloads `
    "MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818.zip.sha256"

$knownHash = `
    "9f6b5366f113ffbca3f4585fa372484dfb69d04a8a54a6d60c25e23764a28b1a"

if (-not (Test-Path -LiteralPath $zip)) {
    throw "ZIP not found: $zip"
}

if (-not (Test-Path -LiteralPath $sidecar)) {
    throw "SHA-256 sidecar not found: $sidecar"
}

$sidecarHash = (
    (Get-Content -LiteralPath $sidecar -Raw).Trim() -split "\s+"
)[0].ToLowerInvariant()

$actualHash = (
    Get-FileHash -LiteralPath $zip -Algorithm SHA256
).Hash.ToLowerInvariant()

if ($sidecarHash -ne $knownHash) {
    throw "The sidecar does not contain the governing SHA-256. Stop."
}

if ($actualHash -ne $knownHash) {
    throw "The ZIP SHA-256 does not match the governing identity. Stop."
}

Write-Host "SHA-256 PASS: $actualHash"

# Remove the Windows downloaded-file block from the verified carrier.
Unblock-File -LiteralPath $zip

# Use the short governed local root.
New-Item -ItemType Directory -Force -Path "C:\MSBF" | Out-Null

Expand-Archive `
    -LiteralPath $zip `
    -DestinationPath "C:\MSBF" `
    -Force

$root = "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"

$projectFile = Join-Path $root `
    "project\MSBF_PBI_A1A_Local_Construction_R1.pbip"

if (-not (Test-Path -LiteralPath $projectFile)) {
    throw "PBIP project was not extracted to the expected location."
}

Write-Host "Package root: $root"
Write-Host "Project file: $projectFile"
```

If Windows denies creation of `C:\MSBF`, reopen PowerShell 7 with **Run as administrator**, create the directory, and then continue under your normal Windows account.

---

## 3. Create the evidence-return directory

Continue in the same PowerShell 7 window:

```powershell
$ev = Join-Path $root "evidence\local_engine_return"

New-Item -ItemType Directory -Force -Path $ev | Out-Null

Get-ChildItem -Path "$root\tools\*.ps1" -File |
    Unblock-File

Unblock-File -LiteralPath `
    "$HOME\Downloads\Export-A1aPostSaveManifest_FIXED.ps1"

Write-Host "Evidence directory: $ev"
```

Downloaded scripts can retain a Windows Internet-zone marker. `Unblock-File` removes that marker without requiring a permanent relaxation of the machine’s execution policy. [export reference: cite | turn709858search3 | turn709858search11]

If PowerShell still reports that script execution is disabled, set a session-only policy:

```powershell
Set-ExecutionPolicy `
    -Scope Process `
    -ExecutionPolicy RemoteSigned
```

The `Process` scope expires when that PowerShell window closes. [export reference: cite | turn709858search7]

---

## 4. Patch the governed local data paths

Run:

```powershell
& "$root\tools\Set-A1aLocalPaths.ps1" `
    -PackageRoot $root
```

Expected output:

```text
Patched pDataRoot:  C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818\inputs\pbi
Patched pBuildRoot: C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818\inputs\build
Model:              ...\model.bim
```

This changes only the two local root parameters inside the TMSL `model.bim`. It does not add a table, query, relationship, measure, or report page.

---

## 5. Run the mandatory pre-open boundary test

Run:

```powershell
& "$root\tools\Verify-A1aSourceProject.ps1" `
    -PackageRoot $root *>&1 |
    Tee-Object `
        -FilePath "$ev\E01_SOURCE_PROJECT_BOUNDARY.txt"
```

The result must show:

```json
{
  "tables": 14,
  "relationships": 6,
  "named_expressions": 33,
  "table_partitions": 14,
  "power_query_queries": 47,
  "measures": 0,
  "page_directories": 0,
  "a1b_tokens": 0
}
```

followed by:

```text
A1a source-project boundary PASS.
```

### Hard stop

Do not open Power BI Desktop if any value differs. Preserve the console output and stop.

---

## 6. Configure Power BI Desktop before opening the project

Start Power BI Desktop **without opening the project yet**.

Go to:

```text
File
→ Options and settings
→ Options
→ Preview features
```

Set the following:

| Setting | Required state |
|---|---|
| Power BI Project (.pbip) save option | Enabled |
| Store reports using enhanced metadata format (PBIR) | Enabled if displayed |
| Store semantic model using TMDL format | **Disabled** |

PBIP project support currently requires its preview option, and a `.pbip` file opens the referenced report and semantic model. [export reference: cite | turn977778view0] The supplied report uses the PBIR folder format, for which Microsoft exposes a separate preview setting. [export reference: cite | turn685883view1]

The semantic model is intentionally supplied as **TMSL in `model.bim`**. Do not convert it to TMDL. Microsoft notes that a TMDL upgrade replaces `model.bim`, and the conversion cannot be reversed through Desktop; when prompted, the correct choice is **Keep current format**. [export reference: cite | turn977778view1]

Restart Power BI Desktop after changing preview settings.

---

## 7. Open the governed PBIP file

Open this exact file:

```text
C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

You can double-click the `.pbip` file or use **File → Open → Browse**. Microsoft documents both `.pbip` and `.pbir` as valid project-opening entry points. [export reference: cite | turn977778view0]

### Respond to prompts as follows

| Prompt or behavior | Required action |
|---|---|
| Upgrade semantic model to TMDL | Select **Keep current format** |
| Convert or save as PBIX | Cancel |
| Publish to Power BI Service | Cancel |
| Repair or upgrade the zero-page report | Capture screenshot; close without saving; stop |
| Desktop automatically creates a blank page | Capture screenshot; close without saving; stop |
| Add or auto-detect another relationship | Decline or cancel |
| Create a measure, quick measure, column, or table | Cancel |

The zero-page condition is intentional. Do not create a blank page and then delete it as a workaround. If Desktop cannot open and preserve the zero-page report physically, that behavior is evidence of a HOLD.

---

## 8. Verify all 47 Power Query objects

In Desktop, select:

```text
Home
→ Transform data
```

Compare the Queries pane against:

```text
C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818
\catalogs
\A1A_POWER_QUERY_CATALOG_47.csv
```

The exact inventory is:

| Query class | Count | Load state |
|---|---:|---|
| Parameters | 9 | Not loaded |
| Functions | 5 | Not loaded |
| Staging queries | 19 | Enable load off |
| Semantic queries | 14 | Enable load on |
| **Total** | **47** | — |

The fourteen loaded semantic queries must be:

```text
ModelParameters
DimDate
DimAsOfDate
DimRunCampaign
DimScenario
DimMerchant
DimApplication
DimAccountAdvance
DimIndustry
DimRegion
DimAcquisitionSource
FactGovernanceControl
FactSourceReconciliation
FactValidationResult
```

Do not change query names, types, load settings, M code, or query order.

### E02 evidence

Capture enough screenshots to show the complete Queries pane. Save the primary screenshot as:

```text
E02_POWER_QUERY_QUERY_PANE.png
```

Additional screenshots may be named:

```text
E02_POWER_QUERY_QUERY_PANE_02.png
E02_POWER_QUERY_QUERY_PANE_03.png
```

Crop screenshots so that local data-root paths are not exposed.

---

## 9. Refresh the A1a model

While still in Power Query:

1. Select **Home → Refresh Preview → Refresh All**.
2. Confirm that no query shows an error.
3. Select **Close & Apply**.
4. After the model loads, select **Home → Refresh** in Power BI Desktop.

If Power BI asks for privacy levels, assign the same non-public privacy classification to both local roots and record the selection in the refresh log. Do not choose an option that globally ignores privacy checks.

### Hard-stop errors

Stop rather than bypassing any of the following:

```text
missing source file
header mismatch
row-count mismatch
SHA-256 or catalog mismatch
selected-run mismatch
duplicate-key failure
orphan-key failure
Formula.Firewall or privacy error that cannot be governed
unexpected table, relationship, or page creation
```

### E03 evidence

Capture:

```text
E03_REFRESH_SUCCESS.png
E03_REFRESH_LOG.txt
```

The text log should record:

```text
Desktop version:
Refresh date/time:
Refresh result:
Loaded semantic tables: 14
Power Query objects: 47
Query errors: 0
Measures: 0
Pages: 0
Notes:
```

Do not place your Windows username, full local path, or machine name in the evidence log.

---

## 10. Verify the model view and six relationships

Open **Model view**.

There must be exactly fourteen table boxes and six relationship lines. Capture:

```text
E04_MODEL_VIEW.png
```

Then open **Manage relationships** and verify these exact relationships:

| One side | Many side | Active | Cardinality | Direction |
|---|---|---:|---|---|
| `DimIndustry[industry_code]` | `DimMerchant[industry_code]` | Yes | 1:* | Single |
| `DimRegion[region_code]` | `DimMerchant[region_code]` | Yes | 1:* | Single |
| `DimMerchant[MerchantKey]` | `DimApplication[MerchantKey]` | Yes | 1:* | Single |
| `DimAcquisitionSource[primary_source_code]` | `DimApplication[primary_source_code]` | Yes | 1:* | Single |
| `DimApplication[ApplicationKey]` | `DimAccountAdvance[ApplicationKey]` | Yes | 1:* | Single |
| `DimScenario[RunScenarioKey]` | `DimAccountAdvance[RunScenarioKey]` | Yes | 1:* | Single |

Do not edit or recreate a relationship even if it appears visually inconvenient. A discrepancy is a HOLD, not an invitation to repair the model locally.

---

## 11. Connect DAX Studio and export the model metadata

With the PBIP still open, select:

```text
External Tools
→ DAX Studio
```

An all-users DAX Studio installation should launch with the open Power BI model already connected. [export reference: cite | turn892161search1]

Open:

```text
$root\tools\A1A_LOCAL_ENGINE_DMV_QUERIES.sql
```

Run each `SELECT` statement separately. Use DAX Studio’s **File** output mode and select CSV; DAX Studio supports direct CSV output without applying display formatting. [export reference: cite | turn559735search0]

Save the outputs as:

```text
E05_TMSCHEMA_RELATIONSHIPS.csv
E06_TMSCHEMA_TABLES.csv
E06_TMSCHEMA_MEASURES.csv
E06_TMSCHEMA_PARTITIONS.csv
E06_TMSCHEMA_EXPRESSIONS.csv
```

Also run this supplemental DMV so the relationship column IDs can be resolved to physical column names:

```sql
SELECT * FROM $SYSTEM.TMSCHEMA_COLUMNS;
```

Save it as:

```text
E05_TMSCHEMA_COLUMNS.csv
```

Expected metadata counts:

```text
Tables               14
Relationships          6
Measures               0
Partitions            14
Named expressions     33
Partitions + expressions = 47
```

After exporting the CSVs, run this in PowerShell 7:

```powershell
$counts = [ordered]@{
    tables = @(
        Import-Csv "$ev\E06_TMSCHEMA_TABLES.csv"
    ).Count

    relationships = @(
        Import-Csv "$ev\E05_TMSCHEMA_RELATIONSHIPS.csv"
    ).Count

    measures = @(
        Import-Csv "$ev\E06_TMSCHEMA_MEASURES.csv"
    ).Count

    partitions = @(
        Import-Csv "$ev\E06_TMSCHEMA_PARTITIONS.csv"
    ).Count

    named_expressions = @(
        Import-Csv "$ev\E06_TMSCHEMA_EXPRESSIONS.csv"
    ).Count

    report_pages = 0
}

$counts["power_query_queries"] = `
    $counts.partitions + $counts.named_expressions

$counts |
    ConvertTo-Json |
    Set-Content `
        -LiteralPath "$ev\E06_MODEL_OBJECT_COUNTS.json" `
        -Encoding utf8
```

Open `E06_MODEL_OBJECT_COUNTS.json` and verify:

```json
{
  "tables": 14,
  "relationships": 6,
  "measures": 0,
  "partitions": 14,
  "named_expressions": 33,
  "report_pages": 0,
  "power_query_queries": 47
}
```

---

## 12. Run the read-only DAX evidence queries

Open this file in DAX Studio:

```text
$root\tools\A1A_LOCAL_ENGINE_EVIDENCE_QUERIES.dax
```

Run **one `EVALUATE` block at a time**. Do not run the whole file as one batch and do not create persistent measures.

Export the results as:

| Block | Output |
|---|---|
| E07 semantic row counts | `E07_SEMANTIC_ROW_COUNTS.csv` |
| E08 key uniqueness | `E08_TABLE_KEY_RESULTS.csv` |
| E09 lifecycle authority | `E09_AUTHORITATIVE_LIFECYCLE.csv` |
| E10 scenario isolation | `E10_SCENARIO_ISOLATION.csv` |
| E11 date spine | `E11_ASOF_DATE_SPINE.csv` |

Then open the downloaded supplemental file:

```text
A1A_E08_ORPHAN_AND_FILTER_BEHAVIOR_QUERIES.dax
```

Run its two blocks separately and export:

```text
E08_RELATIONSHIP_ORPHANS.csv
E08_RELATIONSHIP_FILTER_BEHAVIOR.csv
```

### Expected E07 row counts

| Table | Rows |
|---|---:|
| ModelParameters | 8 |
| DimDate | 123 |
| DimAsOfDate | 123 |
| DimRunCampaign | 1 |
| DimScenario | 2 |
| DimMerchant | 750 |
| DimApplication | 750 |
| DimAccountAdvance | 59 |
| DimIndustry | 8 |
| DimRegion | 5 |
| DimAcquisitionSource | 18 |
| FactGovernanceControl | 9 |
| FactSourceReconciliation | 214 |
| FactValidationResult | 533 |

### Expected E08 results

For every table key:

```text
Rows = DistinctKeys
NullKeys = 0
```

For all six relationships:

```text
OrphanDistinctKeys = 0
GroupedChildRows = TotalChildRows
```

### Expected E09 lifecycle results

The engine evidence must establish:

```text
run_status                 M2_12_ACCEPTED
latest G2 result           PASS
latest G3 result           PASS
G2 registry status         ACCEPTED
G3 registry status         ACCEPTED
NotesUsedForStatus          false
```

The stale narrative notes field must not control lifecycle status.

### Expected E10 scenario results

| Scenario | Account paths | Distinct applications | Funded amount |
|---|---:|---:|---:|
| BASELINE | 44 | 44 | $472,000 |
| RECESSION_ENERGY | 15 | 15 | $195,600 |

Combined interpretation:

```text
59 scenario-qualified paths
44 distinct applications/merchants
15 matched stress overlays
```

Do not describe these as 59 distinct merchants.

### Expected E11 date-spine results

```text
DimDateRows             123
MinimumDate             2026-07-23
MaximumDate             2026-11-22
SourceAsOfRows          1
EvidenceEndpointRows    1
DimAsOfDateRows         123
DefaultAsOfRows         1
```

**Known package discrepancy:** the packaged static expected `DimDate` CSV appears to leave `IsSourceRunAsOf` false throughout. Do not change the model to reproduce that static-file defect. The governing source cutoff is July 23, 2026, so the physical engine result should contain exactly one source-as-of row. Record the discrepancy in the evidence notes for Independent Audit review.

---

## 13. Complete the supplied evidence templates

The templates are located at:

```text
$root\evidence\local_engine_pending
```

Copy them into:

```text
$root\evidence\local_engine_return
```

Remove `_TEMPLATE` from the copied filenames. Complete at least:

```text
A1A_EVIDENCE_INDEX.csv
A1A_POWER_QUERY_REFRESH_EVIDENCE.csv
A1A_SEMANTIC_TABLE_RECONCILIATION.csv
A1A_KEY_UNIQUENESS_AND_ORPHAN.csv
A1A_RELATIONSHIP_INSTANTIATION.csv
A1A_RUN_LINEAGE_ALIAS_CONTROL.csv
A1A_SOURCE_RECONCILIATION.csv
A1A_LOCAL_EVIDENCE_PACKAGE_MANIFEST.csv
```

For each completed control, enter:

```text
actual result
status
evidence filename
tester
tested date/time
notes or limitation
```

### Hold handling

The source-owner evidence may say that the result matched the expected value, but do **not** mark these controls closed:

```text
AUD-SCN-004
AUD-REL-005
AUD-ASOF-003
```

Use language such as:

```text
PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
```

The Independent Audit—not the source-owner workstream—makes the closure decision.

---

## 14. Save only if the boundary is still exact

Before saving, verify:

```text
14 tables
6 relationships
47 queries
0 measures
0 pages
no A1b objects
```

Then select:

```text
File
→ Save
```

Do not use:

```text
Save As PBIX
Publish
New measure
New column
New table
New page
```

If prompted to upgrade the semantic model to TMDL, choose **Keep current format**.

Close Power BI Desktop completely.

---

## 15. Perform the post-save boundary test

Back in PowerShell 7:

```powershell
& "$root\tools\Verify-A1aSourceProject.ps1" `
    -PackageRoot $root *>&1 |
    Tee-Object `
        -FilePath "$ev\E01_POST_SAVE_SOURCE_PROJECT_BOUNDARY.txt"
```

It must still return:

```text
tables                 14
relationships            6
power_query_queries      47
measures                  0
page_directories          0
a1b_tokens                0
A1a source-project boundary PASS
```

Any post-save change to those values is a HOLD.

---

## 16. Generate the E12 post-save manifest

Do **not** run the defective `Export-A1aPostSaveManifest.ps1` from the extracted package.

Run the corrected downloaded helper:

```powershell
& "$HOME\Downloads\Export-A1aPostSaveManifest_FIXED.ps1" `
    -PackageRoot $root `
    -OutputDirectory $ev
```

Expected outputs:

```text
E12_POST_SAVE_MANIFEST.csv
E12_POST_SAVE_SHA256SUMS.txt
```

The corrected helper excludes Power BI’s machine-specific local settings and model cache from the manifest. Microsoft also identifies `localSettings.json` and `cache.abf` as local or cache artifacts that should normally be excluded from source-controlled PBIP content. [export reference: cite | turn977778view0 | turn977778view1]

---

## 17. Confirm the final stopping state

Your final local status must read:

```text
A1a project opened in Power BI Desktop
47 Power Query objects physically refreshed
14 semantic tables physically loaded
6 relationships physically instantiated
0 measures
0 calculated columns
0 calculated tables
0 report pages
A1b not started

AUD-SCN-004   HOLD_PENDING_INDEPENDENT_REVIEW
AUD-REL-005   HOLD_PENDING_INDEPENDENT_REVIEW
AUD-ASOF-003  HOLD_PENDING_INDEPENDENT_REVIEW
PBI-WP2       HOLD
```

Return the saved `project` directory and the completed `evidence\local_engine_return` directory. Do not begin A1b, create a report page, add a measure, convert the project to PBIX/TMDL, publish it, or characterize the Power BI solution as accepted.
<!-- END_SOURCE_MESSAGE -->


<a id="m-036de414-482c-44af-813b-00ed75a3938b"></a>
## Andrew / user · C091-M00026

C091-M00026 · 2026-08-19T06:32:31.685000-04:00 · active path

Preceding visible parent: [C091-M00025](part-02.md#m-225867d9-2d54-41b6-ba3c-069153681087)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 687b645a-179d-4a56-a64a-7366ff15034f.png

<!-- BEGIN_SOURCE_MESSAGE -->
step 7: ActivePageName not found
The report has no pages. Reports must have at least one page                     no prompts came up besides this.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6062460d-731e-4aea-b7c7-f12131d450fa"></a>
## Assistant · C091-M00027

C091-M00027 · 2026-08-19T06:38:00.940053-04:00 · active path

Preceding visible parent: [C091-M00026](part-02.md#m-036de414-482c-44af-813b-00ed75a3938b)

<!-- BEGIN_SOURCE_MESSAGE -->
## Stop here—do **not** click **Continue**

This is the exact zero-page hard stop anticipated in the runbook. Your screenshot confirms a genuine incompatibility between:

```text
Audit-authorized A1a boundary: 0 report pages
Power BI Desktop report requirement: at least 1 report page
```

The audit authorized **14 tables, 6 relationships, 47 queries, 0 measures, and 0 report pages**, and explicitly prohibited adding any report page. [export reference: filecite | turn9file1 | L55-L74] Microsoft’s current Desktop documentation states that a report starts with at least one blank page; PBIP opens a report and its referenced semantic model together rather than opening the semantic model by itself. [export reference: cite | turn831800view0 | turn831800view1]

The two errors are related:

```text
The report has no pages
→ there is no valid page that can be identified as ActivePageName
```

Microsoft identifies invalid `activePageName` metadata as something Desktop may automatically repair, but continuing and later saving could persist an automatic report-definition change. [export reference: cite | turn831800view2] Under the current authorization, that change must not be allowed.

## Do this now

### 1. Copy the full diagnostic details

Click:

```text
Copy details to clipboard
```

Do this **before** closing Desktop.

### 2. Save the clipboard output as evidence

Open PowerShell 7 and run:

```powershell
$root = "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"
$ev   = Join-Path $root "evidence\local_engine_return"

New-Item -ItemType Directory -Force -Path $ev | Out-Null

Get-Clipboard |
    Set-Content `
        -LiteralPath "$ev\E00_DESKTOP_ZERO_PAGE_OPEN_ERROR.txt" `
        -Encoding utf8
```

Open the resulting text file and confirm that it contains the two errors.

### 3. Save the screenshot locally

Save a screenshot of the exact dialog as:

```text
C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818
\evidence\local_engine_return
\E00_DESKTOP_ZERO_PAGE_OPEN_ERROR.png
```

The screenshot you posted captures the necessary content:

```text
ActivePageName not found
The report has no pages. Reports must have at least one page.
```

### 4. Click **Close Desktop**

Select:

```text
Close Desktop
```

Do **not** select **Continue**.

If Power BI asks whether to save changes, select:

```text
Don't Save
```

Do not create a page, let Desktop repair the report, or save the project.

### 5. Re-run the boundary verifier

After Desktop is fully closed, run:

```powershell
$root = "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"
$ev   = Join-Path $root "evidence\local_engine_return"

& "$root\tools\Verify-A1aSourceProject.ps1" `
    -PackageRoot $root *>&1 |
    Tee-Object `
        -FilePath "$ev\E00_POST_FAILED_OPEN_BOUNDARY.txt"
```

It must still report:

```text
tables                 14
relationships           6
power_query_queries    47
measures                0
page_directories        0
a1b_tokens              0

A1a source-project boundary PASS
```

If the page count is no longer zero, do not manually repair it. Delete the extracted working copy and re-extract the verified ZIP to restore the governed state.

## What this result means

This is **physical Power BI Desktop evidence**, but only of a report-container constraint:

```text
PBIP report opened far enough for Desktop validation
Desktop rejected the zero-page report definition
No refresh occurred
No relationships were instantiated
No DAX was compiled
No page was authorized or constructed
No A1b work occurred
```

It does **not** close any of the three local-engine controls:

```text
AUD-SCN-004   HOLD_LOCAL_DESKTOP_EVIDENCE
AUD-REL-005   HOLD_LOCAL_DESKTOP_EVIDENCE
AUD-ASOF-003  HOLD_LOCAL_DESKTOP_EVIDENCE
```

Those holds require scenario-isolation, instantiated-relationship, and as-of/endpoint behavior evidence that has not yet been reached. [export reference: filecite | turn9file1 | L45-L53]

No other prompt appearing before this error does not establish that the queries, tables, sources, or relationships loaded successfully. Desktop stopped at report-definition validation before the authorized refresh and engine tests could be completed.

## Required audit decision before proceeding

The current package cannot complete a Desktop run while simultaneously retaining an exact zero-page report definition. Microsoft’s PBIR structure treats report pages as part of the report definition, with a pages folder and one page folder for each page. [export reference: cite | turn251776view0]

The Independent Audit therefore needs to authorize one of these two bounded remedies:

1. **Preferred:** permit one empty technical shell page solely to satisfy Desktop, with:
   ```text
   1 technical page
   0 visuals
   0 measures
   no substantive report-page construction
   no navigation
   no formatting work
   A1b still prohibited
   ```

2. Authorize a different semantic-model-only local-engine route instead of the currently authorized PBIP/Desktop report-opening route.

The exact update to send the Independent Audit is:

```text
A1a Desktop entry encountered a physical zero-page PBIP constraint. Power BI
Desktop reported “ActivePageName not found” and “The report has no pages.
Reports must have at least one page.” Desktop was closed without continuing or
saving. The governed source project remains 14 tables, 6 relationships,
47 queries, 0 measures, and 0 pages; A1b was not started.

Please issue a specific boundary decision authorizing either:

1. one blank technical shell page with zero visuals and no substantive report
   construction solely to permit Desktop semantic-model execution; or
2. an alternate semantic-model-only local-engine evidence route.

Until that decision, A1a remains stopped and AUD-SCN-004, AUD-REL-005, and
AUD-ASOF-003 remain HOLD_LOCAL_DESKTOP_EVIDENCE.
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-c01dbc72-33db-48be-86dc-daa78806e213"></a>
## Andrew / user · C091-M00028

C091-M00028 · 2026-08-19T07:05:56.568000-04:00 · active path

Preceding visible parent: [C091-M00027](part-02.md#m-6062460d-731e-4aea-b7c7-f12131d450fa)

**Editorial record note:** Attachment references: 01_IA_WP2A_A1A_ZERO_PAGE_CONSTRAINT_BOUNDARY_DECISION(1).md; 02_IA_WP2A_A1A_ZERO_PAGE_CONSTRAINT_MACHINE_SUMMARY(1).json; 04_A1A_TECHNICAL_SHELL_EVIDENCE_CHECKLIST(1).md; MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819(1).zip; MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819.zip(1).sha256; MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819_ZIP_VALIDATION_REPORT(1).md

<!-- BEGIN_SOURCE_MESSAGE -->
# A1a boundary decision issued

**Decision:** **Option 1 is authorized.**

Power BI A1a may resume using **exactly one blank technical shell page** solely to satisfy the Power BI Desktop report-container requirement and permit local semantic-engine execution.

The prior audit required a specific A1a Desktop-entry decision while preserving the A1a/A1b boundary and the three local-engine holds. The earlier Power BI submission also contained no report/page assets and expressly retained the local-engine hold, so this is recorded as a new bounded compatibility exception rather than a reinterpretation of an existing page artifact.

## Authorized page

```
A1A_TECHNICAL_SHELL_NO_VISUALS
```

Required classification:

```
TECHNICAL_CONTAINER_ONLY
NON_SUBSTANTIVE
NOT_REPORT_DESIGN
NOT_PUBLIC_CLAIMABLE
```

## Exact authorized A1a state

| ComponentAuthorized count   |    |
| --------------------------- | -- |
| Semantic tables             | 14 |
| Relationships               | 6  |
| Power Query queries         | 47 |
| Explicit DAX measures       | 0  |
| Substantive report pages    | 0  |
| Technical shell pages       | 1  |
| Total physical report pages | 1  |
| Visual objects              | 0  |
| A1b objects                 | 0  |

The governed **semantic activation footprint remains 67 objects**: 14 tables, 6 relationships, and 47 queries. The technical shell is a separately governed execution-enabling container; it is not a substantive activation object.

Once the shell is saved, the physical project must no longer be described simply as having “zero pages.” The exact representation is:

> **One physical technical shell page, zero substantive report pages, and zero visuals.**

## Shell-page controls

The page must:

1. Be the only physical report page.
2. Use the exact display name `A1A_TECHNICAL_SHELL_NO_VISUALS`.
3. Be the valid target of the report’s active-page reference.
4. Contain zero visuals, including text boxes, shapes, buttons, images, slicers, tables, cards, or charts.
5. Contain no bookmarks, navigation, tooltip configuration, drillthrough destination, mobile layout, or substantive report filter.
6. Introduce no measure or A1b object.
7. Remain visibly identifiable as technical-only and never be presented as a dashboard or report page.

Default metadata that Desktop requires to maintain the empty report container is permissible, but it must be inventoried in the evidence submission.

## Authorized operations

The Power BI workstream may now:

- Create the shell in a **derived working copy**, leaving accepted predecessor packages unchanged.
- Open, save, close, and reopen the PBIP.
- Construct and execute only the governed 14 tables, 6 relationships, and 47 queries.
- Refresh or evaluate the bounded A1a model solely to produce local-engine evidence.
- Capture screenshots, metadata, logs, hashes, counts, reconciliations, and relationship/filter results.

If Desktop creates any unauthorized object, the workstream must stop and preserve the resulting artifact. It must not silently remove the object and submit a cleaned version as though it were the executed state.

## Unchanged holds and prohibitions

```
AUD-SCN-004   HOLD_LOCAL_DESKTOP_EVIDENCE
AUD-REL-005   HOLD_LOCAL_DESKTOP_EVIDENCE
AUD-ASOF-003  HOLD_LOCAL_DESKTOP_EVIDENCE

PBI-WP2       HOLD
A1b           NOT_AUTHORIZED
Public claims NOT_AUTHORIZED
```

The shell authorization does not close any local-engine control, accept a PBIP, validate a refresh, accept instantiated relationship behavior, or authorize report construction.

The reported zero-page error, the no-save condition, and the statement that A1b was not started remain source-owner assertions until supported by the physical evidence package.

## Alternate route decision

**Option 2 is not authorized through this decision.**

A semantic-model-only alternate route would introduce a different toolchain and evidence contract that have not been designed or independently audited. The one-page shell is the smallest sufficient deviation from the accepted boundary.

## Exact permitted next action

> Create one blank page named `A1A_TECHNICAL_SHELL_NO_VISUALS` in a derived A1a working PBIP; keep it at zero visuals and create no other report objects; construct only the governed 14 tables, 6 relationships, and 47 queries with zero explicit measures; save, close, and reopen solely to execute and capture A1a local-engine evidence; retain `AUD-SCN-004`, `AUD-REL-005`, and `AUD-ASOF-003` as holds; submit the complete physical evidence package; do not begin A1b.

## Audit addendum package

```
Package:
MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819.zip

SHA-256:
605f37d03bf3e9b40abcd8a7d9fed00eee23792f069e7c1c30ae13697c64b460

ZIP CRC:
PASS

Unsafe paths:
0

Duplicate paths:
0

Case-fold duplicate paths:
0

Symlinks:
0

Encrypted entries:
0
```

Download the complete boundary-decision package (historical reference: `sandbox:[session]/MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819.zip`; referenced bytes not established here)

Download the SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819.zip.sha256`; referenced bytes not established here)

Open the formal boundary-decision report (historical reference: `sandbox:[session]/MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819/01_IA_WP2A_A1A_ZERO_PAGE_CONSTRAINT_BOUNDARY_DECISION.md`; referenced bytes not established here)

Open the A1a evidence checklist (historical reference: `sandbox:[session]/MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819/04_A1A_TECHNICAL_SHELL_EVIDENCE_CHECKLIST.md`; referenced bytes not established here)

Open the machine-readable decision summary (historical reference: `sandbox:[session]/MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819/02_IA_WP2A_A1A_ZERO_PAGE_CONSTRAINT_MACHINE_SUMMARY.json`; referenced bytes not established here)

Open the external ZIP validation report (historical reference: `sandbox:[session]/MSBF_IA_POWER_BI_A1A_ZERO_PAGE_BOUNDARY_DECISION_20260819_ZIP_VALIDATION_REPORT.md`; referenced bytes not established here)
<!-- END_SOURCE_MESSAGE -->


<a id="m-a2ff2d13-06cf-4930-a436-acba954914ef"></a>
## Assistant · C091-M00029

C091-M00029 · 2026-08-19T07:26:15.290714-04:00 · active path

Preceding visible parent: [C091-M00028](part-02.md#m-c01dbc72-33db-48be-86dc-daa78806e213)

<!-- BEGIN_SOURCE_MESSAGE -->
# Resume A1a under the technical-shell exception

The prior instruction **not to click Continue** is superseded, but only within a **derived working copy** and only to create the authorized shell. The governing physical state is now:

```text
14 semantic tables
6 relationships
47 Power Query queries
0 explicit DAX measures
0 substantive report pages
1 technical shell page
1 total physical report page
0 visual objects
0 A1b objects
```

The page must be named exactly `A1A_TECHNICAL_SHELL_NO_VISUALS` and remain technical-only, non-substantive, non-report-design, and not publicly claimable. [export reference: filecite | turn9file0 | L42-L79]

## Download the shell-control helpers

Save these three files in your Windows **Downloads** folder:

- Initialize the derived A1a working copy (historical reference: `sandbox:[session]/Initialize-A1aTechnicalShellWorkingCopy.ps1`; referenced bytes not established here)
- Update the A1a boundary annotation (historical reference: `sandbox:[session]/Set-A1aTechnicalShellAnnotation.ps1`; referenced bytes not established here)
- Verify the authorized technical-shell boundary (historical reference: `sandbox:[session]/Verify-A1aTechnicalShellBoundary.ps1`; referenced bytes not established here)

The original `Verify-A1aSourceProject.ps1` remains useful only **before** the shell is created because it still requires zero page directories. Do not use it as the post-shell verifier.

---

## 1. Preserve and close the failed zero-page attempt

If the original error dialog is still open:

1. Select **Copy details to clipboard**.
2. Preserve the screenshot already taken.
3. Select **Close Desktop**.
4. If asked to save, choose **Don’t Save**.

Do not create the shell in that original extracted project. The audit requires the shell to be created in a derived working copy and requires evidence that the first failed attempt did not mutate the governed project. [export reference: filecite | turn9file0 | L104-L109]

---

## 2. Create the derived working copy

Open **PowerShell 7** and run:

```powershell
$downloads = Join-Path $HOME "Downloads"

$initialize = Join-Path $downloads `
    "Initialize-A1aTechnicalShellWorkingCopy.ps1"

Unblock-File -LiteralPath $initialize

& $initialize
```

The helper will:

- verify that Power BI Desktop is closed;
- compare the current source project against the governed release manifest;
- create a new derived working root;
- verify the copied project before altering local parameters;
- repatch the local data and build roots for the derived copy;
- capture pre-shell manifests and hashes;
- run the original zero-page boundary verifier one final time;
- create the derived working-copy identity record.

Expected working root:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
```

Expected PBIP:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

Expected evidence directory:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\evidence
\local_engine_return
```

### If the script says the working root already exists

Do not delete or overwrite it. Preserve it and use a new identity:

```powershell
& $initialize `
    -WorkingRoot `
    "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R2_20260819"
```

---

## 3. Open only the derived PBIP

Open:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

The same zero-page dialog will probably appear again. That is expected because the derived report definition still contains zero pages at this point.

At the dialog:

1. Select **Copy details to clipboard**.
2. Save the diagnostic in PowerShell:

```powershell
$work = `
    "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"

$ev = Join-Path $work "evidence\local_engine_return"

Get-Clipboard |
    Set-Content `
        -LiteralPath `
        "$ev\E00_ZERO_PAGE_DIAGNOSTIC_DERIVED_WORKING_COPY.txt" `
        -Encoding utf8

[pscustomobject]@{
    event = "ZERO_PAGE_DIALOG_DISPLAYED"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    project = "MSBF_PBI_A1A_Local_Construction_R1.pbip"
    working_root = $work
} |
    ConvertTo-Json |
    Set-Content `
        -LiteralPath "$ev\E00_ZERO_PAGE_EVENT_TIMESTAMP.json" `
        -Encoding utf8
```

3. Capture a screenshot as:

```text
E00_ZERO_PAGE_DIAGNOSTIC_DERIVED_WORKING_COPY.png
```

4. **Now select Continue.**

Continue is authorized only because decision `IA-D-R3A-PBI-001` permits exactly one blank technical shell page. The semantic-model-only alternate route remains unauthorized. [export reference: filecite | turn9file0 | L40-L61]

---

## 4. Create exactly one blank page

After selecting **Continue**, inspect the bottom of the report canvas.

### If Desktop automatically created one page

Do **not** create another page. Proceed directly to renaming it.

### If no page tab exists

Create one page exactly once:

```text
Insert
→ New page
→ Blank page
```

You may alternatively use the `+` beside the report-page tabs. Microsoft documents both routes for adding a blank Desktop report page. [export reference: cite | turn877051search5]

### If two or more pages appear

Stop immediately:

1. Do not delete either page.
2. Do not save.
3. Capture screenshots.
4. Close Desktop without saving.
5. Preserve the resulting evidence.

The audit expressly prohibits silently deleting an unauthorized object and submitting a cleaned state as though it were the executed state. [export reference: filecite | turn9file0 | L113-L123]

---

## 5. Rename the single page

Right-click the single page tab and select **Rename Page**. Enter exactly:

```text
A1A_TECHNICAL_SHELL_NO_VISUALS
```

Press **Enter**.

Do not abbreviate, add spaces, alter capitalization, or append a version identifier. Power BI supports renaming a page from its tab context menu. [export reference: cite | turn877051search0]

Leave this page selected when saving so that it becomes the active page. The post-save verifier will independently confirm that:

```text
pages.json pageOrder
=
the page’s internal identifier
=
pages.json activePageName
```

PBIR stores the active page and page order in `pages.json`, while each physical page has its own page folder and `page.json`. [export reference: cite | turn198476search1]

---

## 6. Keep the shell completely empty

Do not click or use any of the following:

```text
New visual
Text box
Shape
Button
Image
Slicer
Table
Card
Chart
Page navigator
Bookmark navigator
Drillthrough
Tooltip
Mobile layout
Page filter
Report filter
New measure
Quick measure
New column
New table
```

The shell must contain:

```text
Visuals                         0
Bookmarks                       0
Navigation objects              0
Tooltip configuration           0
Drillthrough configuration       0
Substantive filters             0
Additional pages                0
Explicit measures               0
A1b objects                     0
```

These are explicit shell controls, not optional presentation preferences. [export reference: filecite | turn9file0 | L85-L98]

### Inspect the empty state

Open the **Selection** pane using the View menu or pane switcher. It must contain no report objects.

Open the **Bookmarks** pane. It must contain no bookmarks.

Capture:

```text
E01_TECHNICAL_SHELL_BLANK_CANVAS.png
E01_TECHNICAL_SHELL_EMPTY_SELECTION_PANE.png
E01_TECHNICAL_SHELL_EMPTY_BOOKMARKS_PANE.png
```

The screenshots should show:

- the exact page name;
- one page tab only;
- blank canvas;
- zero objects in Selection;
- zero bookmarks;
- the derived working-project title where visible.

---

## 7. Save and close the shell state

With the single technical page selected:

```text
File
→ Save
```

Then record the save time:

```powershell
[pscustomobject]@{
    event = "FIRST_TECHNICAL_SHELL_SAVE_COMPLETED"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
} |
    ConvertTo-Json |
    Set-Content `
        -LiteralPath "$ev\E01_FIRST_SHELL_SAVE_TIMESTAMP.json" `
        -Encoding utf8
```

Close Power BI Desktop completely.

Record the close time:

```powershell
[pscustomobject]@{
    event = "DESKTOP_CLOSED_AFTER_FIRST_SHELL_SAVE"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
} |
    ConvertTo-Json |
    Set-Content `
        -LiteralPath "$ev\E01_FIRST_SHELL_CLOSE_TIMESTAMP.json" `
        -Encoding utf8
```

---

## 8. Correct the predecessor’s stale zero-page annotation

The predecessor PBIR contains this internal annotation:

```text
MSBF_A1aBoundary = ZERO_REPORT_PAGES
```

That label cannot remain unqualified after the shell is saved because the new decision requires the working project to be represented as:

> One physical technical shell page, zero substantive report pages, and zero visuals.

[export reference: filecite | turn9file0 | L81-L83]

Run the bounded annotation helper while Desktop is closed:

```powershell
$annotationScript = Join-Path $downloads `
    "Set-A1aTechnicalShellAnnotation.ps1"

Unblock-File -LiteralPath $annotationScript

& $annotationScript `
    -PackageRoot $work
```

It changes only the existing boundary annotation to the machine-safe equivalent:

```text
ONE_PHYSICAL_TECHNICAL_SHELL_ZERO_SUBSTANTIVE_REPORT_PAGES_ZERO_VISUALS
```

It does not add a page, visual, measure, query, relationship, or A1b object.

---

## 9. Run the shell-aware verifier

Run:

```powershell
$verifier = Join-Path $downloads `
    "Verify-A1aTechnicalShellBoundary.ps1"

Unblock-File -LiteralPath $verifier

& $verifier `
    -PackageRoot $work `
    -SourceRoot `
    "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"
```

Expected final lines:

```text
A1a technical-shell boundary PASS.
One physical technical shell page, zero substantive report pages, and zero visuals.
```

The verifier checks:

```text
Semantic tables                  14
Relationships                     6
Power Query queries              47
Explicit measures                 0
Semantic activation objects      67

Physical report pages             1
Technical shell pages             1
Substantive report pages          0
Visual objects                    0
Bookmarks                         0
Page/report filters               0
Mobile visual layouts             0
A1b tokens                        0

Display name                      A1A_TECHNICAL_SHELL_NO_VISUALS
Active page mapping               Valid
Boundary annotation               Current
```

It also creates:

```text
E01_A1A_TECHNICAL_SHELL_BOUNDARY.json
E01_A1A_TECHNICAL_SHELL_BOUNDARY.csv
E01_A1A_TECHNICAL_SHELL_BOUNDARY.txt
E01_REPORT_DEFINITION_AFTER_SHELL_MANIFEST.csv
E01_REPORT_DEFINITION_BEFORE_AFTER_DIFF.csv
```

### If the verifier returns HOLD

Do not manually delete or “fix” any object. Preserve:

- the working project;
- the verifier output;
- the report-definition diff;
- screenshots;
- the complete evidence directory.

A verifier HOLD is a reportable executed-state variance.

---

## 10. Reopen the derived PBIP

Open the same derived PBIP again:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

Record the reopen time:

```powershell
[pscustomobject]@{
    event = "TECHNICAL_SHELL_PROJECT_REOPENED"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
} |
    ConvertTo-Json |
    Set-Content `
        -LiteralPath "$ev\E01_SHELL_REOPEN_TIMESTAMP.json" `
        -Encoding utf8
```

The project should now open without the zero-page error and show exactly one blank page with the authorized name.

Stop without saving if Desktop:

- displays another repair dialog;
- creates another page;
- creates a visual;
- changes the shell name;
- changes the page into a tooltip;
- creates any report experience object.

---

## 11. Continue the original runbook from Power Query inspection

Once the reopened shell is stable, resume at the prior runbook’s **Power Query verification** step:

1. Open **Transform data**.
2. Confirm exactly 47 Power Query objects:
   - 9 parameters;
   - 5 functions;
   - 19 load-disabled staging queries;
   - 14 load-enabled semantic queries.
3. Refresh Preview.
4. Select **Close & Apply**.
5. Perform the Desktop refresh.
6. Capture refresh evidence.
7. Verify 14 semantic tables and 6 relationships.
8. Use DAX Studio for DMV and read-only DAX evidence.
9. Complete the row-count, uniqueness, orphan, lifecycle, scenario, and as-of controls.

Do not add a measure or use a visual to conduct any test. All testing remains through Power Query, model metadata, DMV queries, and read-only DAX queries.

---

## 12. Amend the prior object-count evidence

Any earlier evidence template or command that says only:

```text
report_pages = 0
```

is now obsolete.

Use these fields instead:

```json
{
  "semantic_tables": 14,
  "relationships": 6,
  "power_query_queries": 47,
  "explicit_measures": 0,
  "semantic_activation_objects": 67,
  "substantive_report_pages": 0,
  "technical_shell_pages": 1,
  "total_physical_report_pages": 1,
  "visual_objects": 0,
  "a1b_objects": 0
}
```

The checklist requires proof of the single page, zero visuals, active-page mapping, Desktop timestamps, manifests, before/after report-definition diff, model counts, source reconciliation, and the three local-engine test populations. [export reference: filecite | turn9file2 | L3-L24]

---

## 13. Final post-execution checks

After refresh, DAX Studio testing, and evidence capture:

1. Save.
2. Close Desktop completely.
3. Run `Verify-A1aTechnicalShellBoundary.ps1` again.
4. Run the corrected `Export-A1aPostSaveManifest_FIXED.ps1`.
5. Package the complete working `project` folder and `evidence\local_engine_return` folder.
6. Retain the exact disposition:

```text
AUD-SCN-004   PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
AUD-REL-005   PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
AUD-ASOF-003  PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION

PBI-WP2       HOLD
A1b           NOT_AUTHORIZED
Public claims NOT_AUTHORIZED
```

The shell authorization resumes Desktop entry but does not itself close any hold, accept the model, validate refresh behavior, authorize A1b, or authorize public claims. [export reference: filecite | turn9file0 | L141-L155]

After the shell is visible and before running refresh, send one screenshot showing the exact page tab, blank canvas, and empty Selection pane.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3c384f31-945f-4719-a6a5-bfa62c83bd82"></a>
## Andrew / user · C091-M00030

C091-M00030 · 2026-08-19T07:47:42.460000-04:00 · active path

Preceding visible parent: [C091-M00029](part-02.md#m-a2ff2d13-06cf-4930-a436-acba954914ef)

<!-- BEGIN_SOURCE_MESSAGE -->
step 2: PS C:\Windows\System32> $downloads = Join-Path $HOME "Downloads"
>>
>> $initialize = Join-Path $downloads `
>>     "Initialize-A1aTechnicalShellWorkingCopy.ps1"
>>
>> Unblock-File -LiteralPath $initialize
>>
>> & $initialize
Patched pDataRoot:  C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819\inputs\pbi
Patched pBuildRoot: C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819\inputs\build
Model:              C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819\project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim
ForEach-Object: C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819\tools\Verify-A1aSourceProject.ps1:9
Line |
   9 |  $measures=@($tables | ForEach-Object { $_.measures } | Where-Object { …
     |                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | The property 'measures' cannot be found on this object. Verify that the property exists.
<!-- END_SOURCE_MESSAGE -->


<a id="m-63ded749-0612-4138-9b53-2d964676bdcc"></a>
## Assistant · C091-M00031

C091-M00031 · 2026-08-19T07:48:01.065564-04:00 · active path

Preceding visible parent: [C091-M00030](part-02.md#m-3c384f31-945f-4719-a6a5-bfa62c83bd82)

<!-- BEGIN_SOURCE_MESSAGE -->
That error is from the **pre-shell verifier script**, not from your Power BI model. The working copy was created and the local paths were patched successfully before the verifier failed.

The issue is this line in the packaged verifier:

```powershell
$measures=@($tables | ForEach-Object { $_.measures } | Where-Object { $_ })
```

Some of the 14 table JSON objects have no `measures` property at all. Under your current PowerShell behavior, referencing a missing property throws instead of simply returning `$null`. That is consistent with A1a having **zero measures**; it is not evidence that a measure exists or that the model is malformed.

Do **not** open Power BI Desktop yet. The audit requires the derived working copy and pre-shell evidence to be established before shell creation. [export reference: filecite | turn9file0 | L104-L109]

## 1. Keep the working copy you just created

Do **not** rerun `Initialize-A1aTechnicalShellWorkingCopy.ps1`. It correctly stopped after creating:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
```

Rerunning the initializer would now fail because that governed working-root identity already exists.

## 2. Patch the verifier in the derived copy only

In the same PowerShell 7 window, copy/paste this whole block:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"

$verifier = Join-Path $work `
    "tools\Verify-A1aSourceProject.ps1"

$backup = "$verifier.PRE_FIX_20260819"

# Preserve the exact verifier that encountered the error.
Copy-Item `
    -LiteralPath $verifier `
    -Destination $backup `
    -Force

$fixedVerifier = @'
param(
    [Parameter(Mandatory=$false)]
    [string]$PackageRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'

$modelPath = Join-Path $PackageRoot `
    'project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim'

$model = Get-Content -LiteralPath $modelPath -Raw |
    ConvertFrom-Json

$tables = @($model.model.tables)
$rels = @($model.model.relationships)
$expressions = @($model.model.expressions)

$partitions = @(
    $tables |
        ForEach-Object {
            if ($null -ne $_.PSObject.Properties['partitions']) {
                @($_.partitions)
            }
        }
)

$measures = @(
    $tables |
        ForEach-Object {
            if ($null -ne $_.PSObject.Properties['measures']) {
                @($_.measures)
            }
        } |
        Where-Object { $null -ne $_ }
)

$pagesRoot = Join-Path $PackageRoot `
    'project\MSBF_PBI_A1A_Local_Construction_R1.Report\definition\pages'

$pageFiles = @(
    Get-ChildItem `
        -LiteralPath $pagesRoot `
        -Directory `
        -ErrorAction SilentlyContinue
)

$modelRaw = Get-Content -LiteralPath $modelPath -Raw

$result = [ordered]@{
    tables              = $tables.Count
    relationships       = $rels.Count
    named_expressions   = $expressions.Count
    table_partitions    = $partitions.Count
    power_query_queries = $expressions.Count + $partitions.Count
    measures            = $measures.Count
    page_directories    = $pageFiles.Count
    a1b_tokens          = (
        [regex]::Matches(
            $modelRaw,
            '"MSBF_ActivationWave"\s*,\s*"value"\s*:\s*"A1b"'
        )
    ).Count
}

$result | ConvertTo-Json

if (
    $result.tables -ne 14 -or
    $result.relationships -ne 6 -or
    $result.power_query_queries -ne 47 -or
    $result.measures -ne 0 -or
    $result.page_directories -ne 0 -or
    $result.a1b_tokens -ne 0
) {
    throw 'A1a boundary validation failed.'
}

Write-Host 'A1a source-project boundary PASS.'
'@

Set-Content `
    -LiteralPath $verifier `
    -Value $fixedVerifier `
    -Encoding utf8

Write-Host "Verifier patched:"
Write-Host $verifier
Write-Host ""
Write-Host "Original preserved:"
Write-Host $backup
```

This is a **tooling repair only**. It does not alter `model.bim`, the report definition, any query, table, relationship, measure, or page.

## 3. Preserve the verifier-error evidence

Now create a short evidence record of what happened:

```powershell
$ev = Join-Path $work "evidence\local_engine_return"

$errorRecord = @'
A1A PRE-SHELL VERIFIER TOOLING OBSERVATION

Date: 2026-08-19

Operation:
Initialize-A1aTechnicalShellWorkingCopy.ps1

Observed error:
The packaged Verify-A1aSourceProject.ps1 attempted to access the
"measures" property on every table object directly. Some A1a table
objects contain no measures property because A1a has zero explicit
measures. The verifier therefore stopped on a missing-property access.

The error occurred after:
- creation of the derived working copy;
- successful pDataRoot patch;
- successful pBuildRoot patch.

No Power BI Desktop entry occurred.
No shell page was created.
No semantic-model object was changed by the verifier repair.

Remediation:
The verifier was patched in the derived working copy only to test for
property existence before enumerating measures. The original verifier
was preserved as Verify-A1aSourceProject.ps1.PRE_FIX_20260819.
'@

Set-Content `
    -LiteralPath "$ev\E00_PRE_SHELL_VERIFIER_TOOLING_OBSERVATION.txt" `
    -Value $errorRecord `
    -Encoding utf8
```

This is useful because the audit requires a manifest and evidence of what actually happened in the derived working project; we should not hide a tooling failure. [export reference: filecite | turn9file0 | L127-L138]

## 4. Run the corrected pre-shell verifier manually

Now run:

```powershell
& "$work\tools\Verify-A1aSourceProject.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath `
        "$ev\E00_PRE_SHELL_ZERO_PAGE_BOUNDARY.txt"
```

You should get output equivalent to:

```json
{
  "tables": 14,
  "relationships": 6,
  "named_expressions": 33,
  "table_partitions": 14,
  "power_query_queries": 47,
  "measures": 0,
  "page_directories": 0,
  "a1b_tokens": 0
}
```

and then:

```text
A1a source-project boundary PASS.
```

That is the exact pre-shell state we need. The authorized exception only permits the later transition from zero physical pages to exactly one technical shell page while keeping the semantic footprint at 14/6/47/0. [export reference: filecite | turn9file0 | L63-L79]

## 5. If it passes, create the missing working-copy identity file

Because the initializer terminated before its final section, it likely did **not** create:

```text
E00_DERIVED_WORKING_COPY_IDENTITY.json
```

Check:

```powershell
Test-Path `
    "$ev\E00_DERIVED_WORKING_COPY_IDENTITY.json"
```

If that returns:

```text
False
```

tell me. I’ll give you the exact recovery command to complete the initializer’s remaining evidence-only steps **without recreating or overwriting the working copy**.

For now, please run **Step 4 only** and paste the resulting JSON/PASS output here. Do not open Desktop yet.
<!-- END_SOURCE_MESSAGE -->


<a id="m-aff94e30-f032-4fcf-84c1-076b0a1f829a"></a>
## Andrew / user · C091-M00032

C091-M00032 · 2026-08-19T07:51:26.014000-04:00 · active path

Preceding visible parent: [C091-M00031](part-02.md#m-63ded749-0612-4138-9b53-2d964676bdcc)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\Windows\System32> $work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
>>
>> $verifier = Join-Path $work `
>>     "tools\Verify-A1aSourceProject.ps1"
>>
>> $backup = "$verifier.PRE_FIX_20260819"
>>
>> # Preserve the exact verifier that encountered the error.
>> Copy-Item `
>>     -LiteralPath $verifier `
>>     -Destination $backup `
>>     -Force
>>
>> $fixedVerifier = @'
>> param(
>>     [Parameter(Mandatory=$false)]
>>     [string]$PackageRoot = (Split-Path -Parent $PSScriptRoot)
>> )
>>
>> $ErrorActionPreference = 'Stop'
>>
>> $modelPath = Join-Path $PackageRoot `
>>     'project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim'
>>
>> $model = Get-Content -LiteralPath $modelPath -Raw |
>>     ConvertFrom-Json
>>
>> $tables = @($model.model.tables)
>> $rels = @($model.model.relationships)
>> $expressions = @($model.model.expressions)
>>
>> $partitions = @(
>>     $tables |
>>         ForEach-Object {
>>             if ($null -ne $_.PSObject.Properties['partitions']) {
>>                 @($_.partitions)
>>             }
>>         }
>> )
>>
>> $measures = @(
>>     $tables |
>>         ForEach-Object {
>>             if ($null -ne $_.PSObject.Properties['measures']) {
>>                 @($_.measures)
>>             }
>>         } |
>>         Where-Object { $null -ne $_ }
>> )
>>
>> $pagesRoot = Join-Path $PackageRoot `
>>     'project\MSBF_PBI_A1A_Local_Construction_R1.Report\definition\pages'
>>
>> $pageFiles = @(
>>     Get-ChildItem `
>>         -LiteralPath $pagesRoot `
>>         -Directory `
>>         -ErrorAction SilentlyContinue
>> )
>>
>> $modelRaw = Get-Content -LiteralPath $modelPath -Raw
>>
>> $result = [ordered]@{
>>     tables              = $tables.Count
>>     relationships       = $rels.Count
>>     named_expressions   = $expressions.Count
>>     table_partitions    = $partitions.Count
>>     power_query_queries = $expressions.Count + $partitions.Count
>>     measures            = $measures.Count
>>     page_directories    = $pageFiles.Count
>>     a1b_tokens          = (
>>         [regex]::Matches(
>>             $modelRaw,
>>             '"MSBF_ActivationWave"\s*,\s*"value"\s*:\s*"A1b"'
>>         )
>>     ).Count
>> }
>>
>> $result | ConvertTo-Json
>>
>> if (
>>     $result.tables -ne 14 -or
>>     $result.relationships -ne 6 -or
>>     $result.power_query_queries -ne 47 -or
>>     $result.measures -ne 0 -or
>>     $result.page_directories -ne 0 -or
>>     $result.a1b_tokens -ne 0
>> ) {
>>     throw 'A1a boundary validation failed.'
>> }
>>
>> Write-Host 'A1a source-project boundary PASS.'
>> '@
>>
>> Set-Content `
>>     -LiteralPath $verifier `
>>     -Value $fixedVerifier `
>>     -Encoding utf8
>>
>> Write-Host "Verifier patched:"
>> Write-Host $verifier
>> Write-Host ""
>> Write-Host "Original preserved:"
>> Write-Host $backup
Verifier patched:
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819\tools\Verify-A1aSourceProject.ps1

Original preserved:
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819\tools\Verify-A1aSourceProject.ps1.PRE_FIX_20260819
PS C:\Windows\System32> $ev = Join-Path $work "evidence\local_engine_return"
>>
>> $errorRecord = @'
>> A1A PRE-SHELL VERIFIER TOOLING OBSERVATION
>>
>> Date: 2026-08-19
>>
>> Operation:
>> Initialize-A1aTechnicalShellWorkingCopy.ps1
>>
>> Observed error:
>> The packaged Verify-A1aSourceProject.ps1 attempted to access the
>> "measures" property on every table object directly. Some A1a table
>> objects contain no measures property because A1a has zero explicit
>> measures. The verifier therefore stopped on a missing-property access.
>>
>> The error occurred after:
>> - creation of the derived working copy;
>> - successful pDataRoot patch;
>> - successful pBuildRoot patch.
>>
>> No Power BI Desktop entry occurred.
>> No shell page was created.
>> No semantic-model object was changed by the verifier repair.
>>
>> Remediation:
>> The verifier was patched in the derived working copy only to test for
>> property existence before enumerating measures. The original verifier
>> was preserved as Verify-A1aSourceProject.ps1.PRE_FIX_20260819.
>> '@
>>
>> Set-Content `
>>     -LiteralPath "$ev\E00_PRE_SHELL_VERIFIER_TOOLING_OBSERVATION.txt" `
>>     -Value $errorRecord `
>>     -Encoding utf8
PS C:\Windows\System32> & "$work\tools\Verify-A1aSourceProject.ps1" `
>>     -PackageRoot $work *>&1 |
>>     Tee-Object `
>>         -FilePath `
>>         "$ev\E00_PRE_SHELL_ZERO_PAGE_BOUNDARY.txt"
{
  "tables": 14,
  "relationships": 6,
  "named_expressions": 33,
  "table_partitions": 14,
  "power_query_queries": 47,
  "measures": 0,
  "page_directories": 0,
  "a1b_tokens": 0
}
A1a source-project boundary PASS.
PS C:\Windows\System32> Test-Path `
>>     "$ev\E00_DERIVED_WORKING_COPY_IDENTITY.json"
False
<!-- END_SOURCE_MESSAGE -->
