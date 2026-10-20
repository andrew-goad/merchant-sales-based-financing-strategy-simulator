# MSBF - Power BI Executive Portfolio Intelligence

Part 06 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-05.md)
[Next part](part-07.md)

<a id="m-5aaed5fb-63e3-4ddf-9b86-b8f6ecb4633c"></a>
## Assistant · C091-M00083

C091-M00083 · 2026-08-19T10:51:07.744052-04:00 · active path

Preceding visible parent: [C091-M00082](part-05.md#m-babfb37a-fc70-4205-bda7-b8d3af9e4545)

<!-- BEGIN_SOURCE_MESSAGE -->
The date metadata is clean. The stronger explanation is now that **the PBIP opened without a local data cache, so the model definition is present but the tables have not yet been physically populated**.

Microsoft’s PBIP documentation states that when a project has no `.pbi\cache.abf`, Power BI Desktop opens the semantic model with its **entire definition but without data**. [export reference: cite | turn205069search0 | turn205069search3] That matches exactly what you are seeing:

```text
14 table schemas visible
6 relationship definitions visible
columns visible
0 rows in Data view
"Some of the tables have incomplete or no data"
warning triangles
```

Your `DimDate` Power Query preview is 123/123 valid with a proper Date type, and the BIM maps it normally as `dateTime / Short Date`. So I would **not treat “Invalid Date” as evidence of bad date values** at this point. It is much more likely associated with the unprocessed/no-cache table state.

## Next action: perform the actual Desktop data refresh

You are now at the point where the banner’s **Refresh now** operation is appropriate.

First, close Power Query Editor **without making any changes**. Since you are only inspecting, use:

**Close & Apply** only if there are no pending edits. If Power Query asks about changes you did not intentionally make, do not apply them; tell me what it says.

Once back in Desktop, before clicking Refresh, record the pre-refresh state:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_PRE_DESKTOP_DATA_REFRESH"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    power_query_preview = "PASS"
    hotfix_id = "A1A-M-RUNTIME-HF01"
    semantic_tables_defined = 14
    relationships_defined = 6
    data_rows_currently_loaded = "NONE_OBSERVED"
    incomplete_or_no_data_banner = $true
    explicit_measures = 0
    substantive_report_pages = 0
    technical_shell_pages = 1
    a1b_started = $false
} |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -LiteralPath "$ev\E06_PRE_DESKTOP_DATA_REFRESH.json" `
        -Encoding utf8
```

Then click the banner:

**Refresh now**

or use:

**Home → Refresh → Refresh data only**

If your current Desktop exposes the expanded refresh choices, **Refresh data only** is preferable here because Microsoft distinguishes it from schema sync: it loads fresh data while preserving the existing semantic schema. [export reference: cite | turn205069search2] We already have the governed schema and do not want an incidental schema change.

Let that refresh run completely.

### If it succeeds

Go immediately to **Data view → DimDate**. You should now see 123 rows. Then check:

```text
DimAsOfDate             123
FactValidationResult    533
```

and one of the larger core dimensions such as `DimMerchant`.

Then return to Model view and see whether the warning triangles/banner disappear.

At that point we can start recording the actual loaded row-count evidence and move into `AUD-REL-005` / `AUD-SCN-004` testing.

### If it fails

Do not repair anything. Capture the full refresh dialog/error text. That would be the first true semantic-engine processing error and will tell us the exact table/column causing it.

The key correction to our interpretation is:

```text
Power Query Preview        PASS
Semantic definition        14 tables / 6 relationships present
No local cache/data        expected PBIP opening state
Desktop data refresh       NEXT REQUIRED ENGINE TEST
```

Microsoft explicitly documents that PBIP can open with full model metadata and no data when `cache.abf` is absent. [export reference: cite | turn205069search0]

Proceed with **Refresh data only** if available; otherwise use the banner’s **Refresh now**. Tell me whether it completes and whether `DimDate` then shows 123 rows.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d7be1b35-3f1e-40ab-8ddb-29104c294a45"></a>
## Andrew / user · C091-M00084

C091-M00084 · 2026-08-19T10:58:00.252000-04:00 · active path

Preceding visible parent: [C091-M00083](part-06.md#m-5aaed5fb-63e3-4ddf-9b86-b8f6ecb4633c)

<!-- BEGIN_SOURCE_MESSAGE -->
All tables now loaded successfully! I see 123 rows in DimDate and 533 in FactValidationResult
<!-- END_SOURCE_MESSAGE -->


<a id="m-550799f4-cef6-4c07-a215-884c0abe46e4"></a>
## Assistant · C091-M00085

C091-M00085 · 2026-08-19T10:58:01.819022-04:00 · active path

Preceding visible parent: [C091-M00084](part-06.md#m-d7be1b35-3f1e-40ab-8ddb-29104c294a45)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. That is the first successful **physical semantic-engine load**.

We can now distinguish the stages cleanly:

```text
Power Query inventory                 47/47 PASS
HF01                                  APPLIED
Power Query Preview Attempt 2         PASS
14-table schema instantiation         PASS
Desktop data refresh                  PASS
DimDate physical rows                 123
FactValidationResult physical rows    533
A1b                                   NOT STARTED
```

This does **not** close the three audit holds yet; it gives us the physical evidence needed to test them.

## 1. Preserve the successful refresh immediately

Run this in PowerShell:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_DESKTOP_DATA_REFRESH_ATTEMPT_1"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")

    result = "PASS"

    prior_hotfix = "A1A-M-RUNTIME-HF01"
    power_query_preview = "PASS"

    semantic_tables_defined = 14
    semantic_tables_loaded = 14
    relationships_defined = 6
    power_query_queries = 47
    explicit_measures = 0

    observed_row_counts = @{
        DimDate = 123
        FactValidationResult = 533
    }

    technical_shell_pages = 1
    substantive_report_pages = 0
    visual_objects = 0
    a1b_started = $false

    privacy_execution_configuration = @{
        local_source_classification = "PUBLIC"
        ignore_privacy_levels = $false
        classification_scope = "LOCAL_EXECUTION_CONFIGURATION"
    }

    unchanged_holds = @(
        "AUD-SCN-004",
        "AUD-REL-005",
        "AUD-ASOF-003"
    )

    pbi_wp2 = "HOLD"
} |
    ConvertTo-Json -Depth 8 |
    Set-Content `
        -LiteralPath "$ev\E06_DESKTOP_DATA_REFRESH_PASS.json" `
        -Encoding utf8
```

If you can, take screenshots of `DimDate` showing 123 rows and `FactValidationResult` showing 533 rows and save them in the evidence directory.

## 2. Don't perform another refresh

We now have the successful engine state. Repeated refreshing adds no value and makes the evidence chronology harder to interpret.

Also do not create measures or visuals to test the model. A1a remains at zero explicit measures and zero substantive report pages.

## 3. Next we verify the six instantiated relationships

Go to:

**Home → Manage relationships**

Do **not** edit anything.

You should see exactly six relationships. We need to verify their physical state against the frozen definitions:

| ID | Relationship |
|---|---|
| REL-001 | `DimIndustry[industry_code]` → `DimMerchant[industry_code]` |
| REL-002 | `DimRegion[region_code]` → `DimMerchant[region_code]` |
| REL-003 | `DimMerchant[MerchantKey]` → `DimApplication[MerchantKey]` |
| REL-004 | `DimAcquisitionSource[primary_source_code]` → `DimApplication[primary_source_code]` |
| REL-005 | `DimApplication[ApplicationKey]` → `DimAccountAdvance[ApplicationKey]` |
| REL-006 | `DimScenario[RunScenarioKey]` → `DimAccountAdvance[RunScenarioKey]` |

The frozen design requires one-to-many, single-direction relationships; scenario identity remains `scenario_id` through the scenario-qualified key rather than `scenario_code`. The cross-workstream audit explicitly froze `scenario_id` as the relationship identity and the account grain as run × scenario × application. [export reference: filecite | turn9file7 | L13-L25]

### What I need next

Open **Manage relationships** and send me a screenshot of the complete relationship list.

Don't click Edit yet.

Once we have that screenshot, we'll use DAX Studio to extract the authoritative `TMSCHEMA_RELATIONSHIPS` metadata rather than relying only on the GUI. That will establish the physical cardinality, active state, and filter direction required for `AUD-REL-005`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a81acdd4-cffb-4a92-8fae-eb8e96372189"></a>
## Andrew / user · C091-M00086

C091-M00086 · 2026-08-19T11:04:19.732000-04:00 · active path

Preceding visible parent: [C091-M00085](part-06.md#m-550799f4-cef6-4c07-a215-884c0abe46e4)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: MANAGE_RELATIONSHIPS.png

<!-- BEGIN_SOURCE_MESSAGE -->
Manage relationships screenshot attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-047d64d1-48dc-49c6-bfc0-58784d5bcb2a"></a>
## Assistant · C091-M00087

C091-M00087 · 2026-08-19T11:04:21.517746-04:00 · active path

Preceding visible parent: [C091-M00086](part-06.md#m-a81acdd4-cffb-4a92-8fae-eb8e96372189)

<!-- BEGIN_SOURCE_MESSAGE -->
This is exactly the relationship state we wanted to see.

The screenshot physically shows **six and only six relationships**, all **Active**, and every one is displayed as `*:1` with a single filter-direction arrow from the `1` side toward the `*` side. There is no visible many-to-many or bidirectional relationship.

The six instantiated relationships reconcile to the frozen A1a design:

| Physical relationship | Status |
|---|---|
| `DimApplication[ApplicationKey]` 1 → * `DimAccountAdvance[ApplicationKey]` | Active |
| `DimScenario[RunScenarioKey]` 1 → * `DimAccountAdvance[RunScenarioKey]` | Active |
| `DimMerchant[MerchantKey]` 1 → * `DimApplication[MerchantKey]` | Active |
| `DimAcquisitionSource[primary_source_code]` 1 → * `DimApplication[primary_source_code]` | Active |
| `DimIndustry[industry_code]` 1 → * `DimMerchant[industry_code]` | Active |
| `DimRegion[region_code]` 1 → * `DimMerchant[region_code]` | Active |

This is consistent with the frozen shared identity contract: `scenario_id` governs scenario identity, and operational account grain remains `module1_run_id × scenario_id × merchant_application_id`. [export reference: filecite | turn9file7 | L13-L25]

We should still **not close `AUD-REL-005` ourselves**. We now have strong GUI evidence of instantiation, but the audit requested metadata and behavioral evidence as well.

## Preserve this screenshot

Save it in:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\evidence\local_engine_return
\E07_MANAGE_RELATIONSHIPS_6_ACTIVE.png
```

Then record the GUI observation:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_RELATIONSHIP_GUI_INSTANTIATION"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")

    relationship_count = 6
    active_relationships = 6
    inactive_relationships = 0
    many_to_many_relationships = 0
    bidirectional_relationships_observed = 0
    single_direction_relationships_observed = 6

    relationships = @(
        "DimApplication[ApplicationKey] -> DimAccountAdvance[ApplicationKey]",
        "DimScenario[RunScenarioKey] -> DimAccountAdvance[RunScenarioKey]",
        "DimMerchant[MerchantKey] -> DimApplication[MerchantKey]",
        "DimAcquisitionSource[primary_source_code] -> DimApplication[primary_source_code]",
        "DimIndustry[industry_code] -> DimMerchant[industry_code]",
        "DimRegion[region_code] -> DimMerchant[region_code]"
    )

    aud_rel_005 = "PHYSICAL_GUI_EVIDENCE_CAPTURED_PENDING_METADATA_AND_BEHAVIOR_TEST"
    pbi_wp2 = "HOLD"
    a1b = "NOT_AUTHORIZED"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$ev\E07_RELATIONSHIP_GUI_EVIDENCE.json" `
        -Encoding utf8
```

## Next: DAX Studio

Close the **Manage relationships** dialog using its **X**. Don't change anything.

Then in Power BI Desktop select:

**External tools → DAX Studio**

DAX Studio should open connected to this running model.

Once DAX Studio opens successfully, **don't run anything yet**. Tell me whether it connected and what you see at the top/left—particularly whether the model tables are listed.

Then we'll extract the authoritative DMV metadata for:

```text
TMSCHEMA_TABLES
TMSCHEMA_COLUMNS
TMSCHEMA_RELATIONSHIPS
TMSCHEMA_MEASURES
TMSCHEMA_PARTITIONS
TMSCHEMA_EXPRESSIONS
```

That will give us machine-readable proof of the 14/6/47/0 engine footprint before we run the scenario, orphan, and as-of behavioral tests.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a11f9dc6-03c4-4108-a346-02b78a2fc6f0"></a>
## Andrew / user · C091-M00088

C091-M00088 · 2026-08-19T11:10:20.726000-04:00 · active path

Preceding visible parent: [C091-M00087](part-06.md#m-047d64d1-48dc-49c6-bfc0-58784d5bcb2a)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: DAX_STUDIO_SCREENSHOT.png

<!-- BEGIN_SOURCE_MESSAGE -->
Dax Studio Screenshot Attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-37c7f295-32ee-4f8e-950f-be1adbb1ea14"></a>
## Assistant · C091-M00089

C091-M00089 · 2026-08-19T11:10:22.352309-04:00 · active path

Preceding visible parent: [C091-M00088](part-06.md#m-a11f9dc6-03c4-4108-a346-02b78a2fc6f0)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. DAX Studio is **successfully connected to the live Power BI semantic engine**.

The screenshot establishes:

```text
Connection              Connected
Live model               MSBF_PBI_A1A_Local_Construction...
Tables visible           14
Engine endpoint          localhost
Metadata refresh         Successful
DAX Studio               3.5.2
```

I can see all 14 tables in the Metadata pane. The lighter/italic rendering of some tables is not itself an error; we'll let the DMV results establish their physical state.

## Next: capture the authoritative engine metadata

We'll do this carefully, **one query at a time**. These are read-only DMV queries; they do not create measures or modify the model.

### First query — relationships

In the large query editor, paste:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_RELATIONSHIPS
```

Click **Run**.

You should get exactly **6 rows**.

### Export it

Once the results appear:

1. Click inside the results grid.
2. Use **File → Export Data** if available, or the results-grid export/save option.
3. Save as CSV here:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\evidence\local_engine_return
\E08_TMSCHEMA_RELATIONSHIPS.csv
```

Do not worry yet about interpreting numeric enum fields such as cardinality or cross-filtering behavior. We'll resolve those using the column/table metadata rather than guessing.

## Second query — tables

Replace the query with:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_TABLES
```

Run it.

Expected:

```text
14 rows
```

Save:

```text
E08_TMSCHEMA_TABLES.csv
```

## Third — columns

Run:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_COLUMNS
```

Save:

```text
E08_TMSCHEMA_COLUMNS.csv
```

There will be many rows; that's expected.

## Fourth — measures

Run:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_MEASURES
```

Expected:

```text
0 rows
```

This zero-row result is important physical evidence that A1a still contains **zero explicit measures**.

Save the result as:

```text
E08_TMSCHEMA_MEASURES.csv
```

If DAX Studio won't export an empty result, take a screenshot clearly showing:

```text
0 rows
```

and save it as:

```text
E08_TMSCHEMA_MEASURES_ZERO_ROWS.png
```

## Fifth — partitions

Run:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_PARTITIONS
```

Expected:

```text
14 rows
```

Save:

```text
E08_TMSCHEMA_PARTITIONS.csv
```

## Sixth — expressions

Run:

```sql
SELECT *
FROM $SYSTEM.TMSCHEMA_EXPRESSIONS
```

Expected:

```text
33 rows
```

Save:

```text
E08_TMSCHEMA_EXPRESSIONS.csv
```

Together those two populations prove the Power Query count physically:

```text
14 table partitions
+ 33 named expressions
----------------------
  47 Power Query objects
```

That directly corroborates the static A1a inventory, which specified 9 parameters + 5 functions + 19 staging + 14 semantic queries = 47. [export reference: filecite | turn10file0 | L16-L31]

## After those six exports

Don't run behavioral DAX yet.

Tell me the observed row counts for:

```text
TMSCHEMA_RELATIONSHIPS = ?
TMSCHEMA_TABLES        = ?
TMSCHEMA_COLUMNS       = ?
TMSCHEMA_MEASURES      = ?
TMSCHEMA_PARTITIONS    = ?
TMSCHEMA_EXPRESSIONS   = ?
```

If you have trouble finding DAX Studio's CSV export option, tell me what options appear when you right-click the results grid. We can use its **Output → File** mode instead.

Once those counts reconcile, we'll use the exported metadata to prove the six relationships' exact columns/cardinality/filter direction and then run the **read-only scenario, orphan, and as-of tests**—without adding a single measure or visual.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6b714553-8cad-4580-8aed-57e4ae848921"></a>
## Andrew / user · C091-M00090

C091-M00090 · 2026-08-19T11:33:13.998000-04:00 · active path

Preceding visible parent: [C091-M00089](part-06.md#m-37c7f295-32ee-4f8e-950f-be1adbb1ea14)

**Editorial record note:** Attachment references: E08_TMSCHEMA_EXPRESSIONS.csv; E08_TMSCHEMA_MEASURES.csv; E08_TMSCHEMA_PARTITIONS.csv; E08_TMSCHEMA_RELATIONSHIPS.csv; E08_TMSCHEMA_TABLES.csv; E08_TMSCHEMA_COLUMNS.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Query Results attached and saved in evidence folder.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a73c746a-c694-43f6-b572-b9172b451db1"></a>
## Assistant · C091-M00091

C091-M00091 · 2026-08-19T11:33:59.547669-04:00 · active path

Preceding visible parent: [C091-M00090](part-06.md#m-6b714553-8cad-4580-8aed-57e4ae848921)

<!-- BEGIN_SOURCE_MESSAGE -->
The six DMV exports reconcile cleanly. I inspected the attached CSVs directly.

The live semantic engine now physically reports:

```text
TMSCHEMA_TABLES          14
TMSCHEMA_COLUMNS        242
TMSCHEMA_RELATIONSHIPS    6
TMSCHEMA_MEASURES         0
TMSCHEMA_PARTITIONS      14
TMSCHEMA_EXPRESSIONS     33
```

That gives us the exact A1a engine footprint:

```text
14 semantic tables
6 instantiated relationships
14 table partitions
33 named expressions
14 + 33 = 47 Power Query objects
0 explicit DAX measures
```

This independently corroborates the static A1a design inventory of 47 queries with the expected 9 parameter / 5 function / 19 staging / 14 semantic split. [export reference: filecite | turn10file0 | L16-L31]

The relationship DMV is also clean. All six are `IsActive = True`, all have `State = 1`, and all show the same single-direction cross-filter behavior value. Their physical endpoints resolve exactly as follows:

| ID | Many side | One side |
|---|---|---|
| REL-001 | `DimMerchant[industry_code]` | `DimIndustry[industry_code]` |
| REL-002 | `DimMerchant[region_code]` | `DimRegion[region_code]` |
| REL-003 | `DimApplication[MerchantKey]` | `DimMerchant[MerchantKey]` |
| REL-004 | `DimApplication[primary_source_code]` | `DimAcquisitionSource[primary_source_code]` |
| REL-005 | `DimAccountAdvance[ApplicationKey]` | `DimApplication[ApplicationKey]` |
| REL-006 | `DimAccountAdvance[RunScenarioKey]` | `DimScenario[RunScenarioKey]` |

The DMV cardinality values are consistent across all six: `FromCardinality = 2` on the many side and `ToCardinality = 1` on the one side. That matches the GUI evidence you already captured. The scenario relationship is physically on `RunScenarioKey`, preserving the frozen `scenario_id`-qualified account identity rather than using `scenario_code`. The shared audit froze exactly that scenario identity and account grain. [export reference: filecite | turn9file7 | L13-L25]

There is also useful refresh evidence in `TMSCHEMA_PARTITIONS`: all 14 partitions have `State = 1`, no `ErrorMessage`, and non-null refresh timestamps from the successful Desktop refresh. So the prior no-data/invalid-date condition is no longer the controlling engine state.

## Preserve a DMV summary now

Run this in PowerShell so the evidence package has a compact machine-readable reconciliation:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_LIVE_ENGINE_METADATA_RECONCILIATION"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")

    tmschema_tables = 14
    tmschema_columns = 242
    tmschema_relationships = 6
    tmschema_measures = 0
    tmschema_partitions = 14
    tmschema_expressions = 33

    calculated_power_query_object_count = 47

    active_relationships = 6
    inactive_relationships = 0
    relationship_state_1_count = 6
    partition_state_1_count = 14
    partition_error_count = 0

    physical_engine_boundary = "14_TABLES_6_RELATIONSHIPS_47_QUERIES_0_MEASURES"

    aud_rel_005 = "METADATA_EVIDENCE_CAPTURED_BEHAVIOR_TEST_PENDING"
    aud_scn_004 = "HOLD_BEHAVIOR_TEST_PENDING"
    aud_asof_003 = "HOLD_BEHAVIOR_TEST_PENDING"

    pbi_wp2 = "HOLD"
    a1b = "NOT_AUTHORIZED"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$ev\E08_LIVE_ENGINE_METADATA_RECONCILIATION.json" `
        -Encoding utf8
```

## Next: behavioral tests

We can now move from metadata to the three remaining local-engine behaviors. We should test them with **query-scoped DAX only**—no persistent measures.

Start with scenario isolation. In DAX Studio, paste and run this:

```DAX
EVALUATE
SUMMARIZECOLUMNS(
    DimScenario[scenario_code],
    "AccountPaths",
        COUNTROWS(DimAccountAdvance),
    "DistinctApplications",
        DISTINCTCOUNT(DimAccountAdvance[merchant_application_id]),
    "FundedAmount",
        SUM(DimAccountAdvance[funded_amount])
)
ORDER BY
    DimScenario[scenario_code]
```

Expected physical result:

```text
BASELINE
AccountPaths           44
DistinctApplications   44
FundedAmount            472000

RECESSION_ENERGY
AccountPaths           15
DistinctApplications   15
FundedAmount            195600
```

This is our first direct `AUD-SCN-004` filter-behavior test.

Save the result as:

```text
E09_SCENARIO_ISOLATION.csv
```

Do not create a measure from any of these expressions.

After you run that query, send me the two result rows. Then we'll run the relationship orphan/filter-propagation controls and finally the as-of/endpoint test.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d202596e-a55f-417b-911b-1db266771b56"></a>
## Andrew / user · C091-M00092

C091-M00092 · 2026-08-19T11:36:33.194000-04:00 · active path

Preceding visible parent: [C091-M00091](part-06.md#m-a73c746a-c694-43f6-b572-b9172b451db1)

**Editorial record note:** Attachment references: E09_SCENARIO_ISOLATION.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Scenario Isolation query attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6a9e7efb-a064-4877-a811-90074cf49280"></a>
## Assistant · C091-M00093

C091-M00093 · 2026-08-19T11:36:42.819029-04:00 · active path

Preceding visible parent: [C091-M00092](part-06.md#m-d202596e-a55f-417b-911b-1db266771b56)

<!-- BEGIN_SOURCE_MESSAGE -->
Scenario isolation passed exactly as expected.

The attached engine result is:

```text
BASELINE
AccountPaths           44
DistinctApplications   44
FundedAmount            472000

RECESSION_ENERGY
AccountPaths           15
DistinctApplications   15
FundedAmount            195600
```

That means the live model is preserving the intended scenario-qualified account population with **no visible cross-scenario leakage** in this test. The combined interpretation remains 59 scenario-qualified paths representing 44 distinct applications, including 15 matched stress overlays.

For audit purposes, I would now mark the source-owner status of `AUD-SCN-004` as:

```text
PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
```

—not closed by us.

Next we should test relationship propagation and orphan behavior. In DAX Studio, run this read-only query:

```DAX
EVALUATE
ROW(
    "IndustryChildRows",
        COUNTROWS(DimMerchant),

    "IndustryFilteredRows",
        SUMX(
            VALUES(DimIndustry[industry_code]),
            CALCULATE(COUNTROWS(DimMerchant))
        ),

    "RegionChildRows",
        COUNTROWS(DimMerchant),

    "RegionFilteredRows",
        SUMX(
            VALUES(DimRegion[region_code]),
            CALCULATE(COUNTROWS(DimMerchant))
        ),

    "MerchantChildRows",
        COUNTROWS(DimApplication),

    "MerchantFilteredRows",
        SUMX(
            VALUES(DimMerchant[MerchantKey]),
            CALCULATE(COUNTROWS(DimApplication))
        ),

    "AcquisitionChildRows",
        COUNTROWS(DimApplication),

    "AcquisitionFilteredRows",
        SUMX(
            VALUES(DimAcquisitionSource[primary_source_code]),
            CALCULATE(COUNTROWS(DimApplication))
        ),

    "ApplicationChildRows",
        COUNTROWS(DimAccountAdvance),

    "ApplicationFilteredRows",
        SUMX(
            VALUES(DimApplication[ApplicationKey]),
            CALCULATE(COUNTROWS(DimAccountAdvance))
        ),

    "ScenarioChildRows",
        COUNTROWS(DimAccountAdvance),

    "ScenarioFilteredRows",
        SUMX(
            VALUES(DimScenario[RunScenarioKey]),
            CALCULATE(COUNTROWS(DimAccountAdvance))
        )
)
```

For each relationship pair, the filtered-row total should equal the child-table total. Save the result as:

```text
E10_RELATIONSHIP_FILTER_BEHAVIOR.csv
```

Then we’ll run a separate six-relationship orphan-key test and finish with the as-of/endpoint evidence.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9e82db36-ed95-4118-b973-3ef52248fa55"></a>
## Andrew / user · C091-M00094

C091-M00094 · 2026-08-19T11:39:56.410000-04:00 · active path

Preceding visible parent: [C091-M00093](part-06.md#m-6a9e7efb-a064-4877-a811-90074cf49280)

**Editorial record note:** Attachment references: E10_RELATIONSHIP_FILTER_BEHAVIOR.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E10_RELATIONSHIP_FILTER_BEHAVIOR attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c29b347b-0a10-4046-9105-fad986eaa9cb"></a>
## Assistant · C091-M00095

C091-M00095 · 2026-08-19T11:40:03.262699-04:00 · active path

Preceding visible parent: [C091-M00094](part-06.md#m-9e82db36-ed95-4118-b973-3ef52248fa55)

<!-- BEGIN_SOURCE_MESSAGE -->
`E10_RELATIONSHIP_FILTER_BEHAVIOR.csv` passes cleanly.

The live-engine result is:

| Relationship path | Child rows | Filter-propagated rows | Result |
|---|---:|---:|---|
| Industry → Merchant | 750 | 750 | PASS |
| Region → Merchant | 750 | 750 | PASS |
| Merchant → Application | 750 | 750 | PASS |
| Acquisition Source → Application | 750 | 750 | PASS |
| Application → Account Advance | 59 | 59 | PASS |
| Scenario → Account Advance | 59 | 59 | PASS |

So all **six instantiated relationships successfully propagate filters from the one-side to the many-side without losing child rows**.

Combined with the evidence already captured, `AUD-REL-005` now has:

```text
6/6 relationships physically instantiated
6/6 Active
6/6 one-to-many
6/6 single-direction
0 many-to-many
0 bidirectional
6/6 filter-propagation tests PASS
```

We should still leave its source-owner disposition as:

```text
AUD-REL-005 =
PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
```

### Next: six-relationship orphan test

Run this in DAX Studio:

```DAX
EVALUATE
ROW(
    "IndustryOrphanKeys",
        COUNTROWS(
            EXCEPT(
                VALUES(DimMerchant[industry_code]),
                VALUES(DimIndustry[industry_code])
            )
        ),

    "RegionOrphanKeys",
        COUNTROWS(
            EXCEPT(
                VALUES(DimMerchant[region_code]),
                VALUES(DimRegion[region_code])
            )
        ),

    "MerchantOrphanKeys",
        COUNTROWS(
            EXCEPT(
                VALUES(DimApplication[MerchantKey]),
                VALUES(DimMerchant[MerchantKey])
            )
        ),

    "AcquisitionSourceOrphanKeys",
        COUNTROWS(
            EXCEPT(
                VALUES(DimApplication[primary_source_code]),
                VALUES(DimAcquisitionSource[primary_source_code])
            )
        ),

    "ApplicationOrphanKeys",
        COUNTROWS(
            EXCEPT(
                VALUES(DimAccountAdvance[ApplicationKey]),
                VALUES(DimApplication[ApplicationKey])
            )
        ),

    "ScenarioOrphanKeys",
        COUNTROWS(
            EXCEPT(
                VALUES(DimAccountAdvance[RunScenarioKey]),
                VALUES(DimScenario[RunScenarioKey])
            )
        )
)
```

Expected:

```text
IndustryOrphanKeys             0
RegionOrphanKeys               0
MerchantOrphanKeys             0
AcquisitionSourceOrphanKeys    0
ApplicationOrphanKeys          0
ScenarioOrphanKeys             0
```

Save it as:

```text
E11_RELATIONSHIP_ORPHANS.csv
```

After that, we'll run the final **as-of / endpoint behavioral evidence** for `AUD-ASOF-003`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-58b17d27-a93d-4d68-b9b4-b1ed267a4a7a"></a>
## Andrew / user · C091-M00096

C091-M00096 · 2026-08-19T11:41:42.283000-04:00 · active path

Preceding visible parent: [C091-M00095](part-06.md#m-c29b347b-0a10-4046-9105-fad986eaa9cb)

**Editorial record note:** Attachment references: E11_RELATIONSHIP_ORPHANS.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E11_RELATIONSHIP_ORPHANS attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d5768509-1ae0-427e-b1e7-f98a81b1aa13"></a>
## Assistant · C091-M00097

C091-M00097 · 2026-08-19T11:41:48.617070-04:00 · active path

Preceding visible parent: [C091-M00096](part-06.md#m-58b17d27-a93d-4d68-b9b4-b1ed267a4a7a)

<!-- BEGIN_SOURCE_MESSAGE -->
There is an important nuance in `E11_RELATIONSHIP_ORPHANS.csv`: **all six results are blank, not zero**.

The attached file contains:

```text
IndustryOrphanKeys             BLANK
RegionOrphanKeys               BLANK
MerchantOrphanKeys             BLANK
AcquisitionSourceOrphanKeys    BLANK
ApplicationOrphanKeys          BLANK
ScenarioOrphanKeys             BLANK
```

That is consistent with DAX `COUNTROWS()` returning `BLANK()` when its table argument contains no rows. Semantically, this is what we hoped to see—each `EXCEPT()` produced an empty orphan set—but for audit evidence I do **not** want to submit blanks and later describe them as literal zeroes.

Let's make the evidence unambiguous.

## Rerun E11 with explicit zero coercion

Run this in DAX Studio:

```DAX
EVALUATE
ROW(
    "IndustryOrphanKeys",
        COALESCE(
            COUNTROWS(
                EXCEPT(
                    VALUES(DimMerchant[industry_code]),
                    VALUES(DimIndustry[industry_code])
                )
            ),
            0
        ),

    "RegionOrphanKeys",
        COALESCE(
            COUNTROWS(
                EXCEPT(
                    VALUES(DimMerchant[region_code]),
                    VALUES(DimRegion[region_code])
                )
            ),
            0
        ),

    "MerchantOrphanKeys",
        COALESCE(
            COUNTROWS(
                EXCEPT(
                    VALUES(DimApplication[MerchantKey]),
                    VALUES(DimMerchant[MerchantKey])
                )
            ),
            0
        ),

    "AcquisitionSourceOrphanKeys",
        COALESCE(
            COUNTROWS(
                EXCEPT(
                    VALUES(DimApplication[primary_source_code]),
                    VALUES(DimAcquisitionSource[primary_source_code])
                )
            ),
            0
        ),

    "ApplicationOrphanKeys",
        COALESCE(
            COUNTROWS(
                EXCEPT(
                    VALUES(DimAccountAdvance[ApplicationKey]),
                    VALUES(DimApplication[ApplicationKey])
                )
            ),
            0
        ),

    "ScenarioOrphanKeys",
        COALESCE(
            COUNTROWS(
                EXCEPT(
                    VALUES(DimAccountAdvance[RunScenarioKey]),
                    VALUES(DimScenario[RunScenarioKey])
                )
            ),
            0
        )
)
```

Overwrite or save the corrected result as:

```text
E11_RELATIONSHIP_ORPHANS.csv
```

Expected literal output:

```text
IndustryOrphanKeys             0
RegionOrphanKeys               0
MerchantOrphanKeys             0
AcquisitionSourceOrphanKeys    0
ApplicationOrphanKeys          0
ScenarioOrphanKeys             0
```

This does **not** change the substantive result; it only makes the evidence machine-readable and audit-safe.

Once you have the corrected E11, attach it. Then we'll proceed to the final `AUD-ASOF-003` tests for the July 23 source cutoff, November 22 evidence endpoint, default as-of date, and no historical endpoint back-casting.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4be8e837-9914-4bc9-bcc7-d7cc7c3e3d01"></a>
## Andrew / user · C091-M00098

C091-M00098 · 2026-08-19T11:43:54.990000-04:00 · active path

Preceding visible parent: [C091-M00097](part-06.md#m-d5768509-1ae0-427e-b1e7-f98a81b1aa13)

**Editorial record note:** Attachment references: E11_RELATIONSHIP_ORPHANS(1).csv

<!-- BEGIN_SOURCE_MESSAGE -->
Updated E11_RELATIONSHIP_ORPHANS attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-827e7b6e-523d-4315-8194-cb31c898f559"></a>
## Assistant · C091-M00099

C091-M00099 · 2026-08-19T11:44:00.289481-04:00 · active path

Preceding visible parent: [C091-M00098](part-06.md#m-4be8e837-9914-4bc9-bcc7-d7cc7c3e3d01)

<!-- BEGIN_SOURCE_MESSAGE -->
Confirmed. The revised `E11_RELATIONSHIP_ORPHANS` now contains literal zeroes across all six relationship controls:

```text
IndustryOrphanKeys             0
RegionOrphanKeys               0
MerchantOrphanKeys             0
AcquisitionSourceOrphanKeys    0
ApplicationOrphanKeys          0
ScenarioOrphanKeys             0
```

Together with E08 and E10, the relationship evidence is now very strong: 6/6 instantiated and active, 6/6 filter-propagation tests reconcile, and 6/6 orphan tests return zero. We will leave `AUD-REL-005` pending Independent Audit disposition rather than self-closing it.

## Final local-engine control: `AUD-ASOF-003`

We need to be precise here. A1a contains the **date/control spine**, but the 13 endpoint-only business facts themselves are deferred beyond A1a. Therefore, this cycle can physically prove the date boundaries and controller behavior, while any test requiring those deferred endpoint fact tables must remain explicitly unexecuted—not simulated.

First run this DAX Studio query:

```DAX
EVALUATE
ROW(
    "DimDateRows",
        COUNTROWS(DimDate),

    "DimDateMin",
        MIN(DimDate[Date]),

    "DimDateMax",
        MAX(DimDate[Date]),

    "SourceRunAsOfRows",
        CALCULATE(
            COUNTROWS(DimDate),
            DimDate[IsSourceRunAsOf] = TRUE()
        ),

    "SourceRunAsOfDate",
        CALCULATE(
            MAX(DimDate[Date]),
            DimDate[IsSourceRunAsOf] = TRUE()
        ),

    "EvidenceEndpointRows",
        CALCULATE(
            COUNTROWS(DimDate),
            DimDate[IsEvidenceEndpoint] = TRUE()
        ),

    "EvidenceEndpointDate",
        CALCULATE(
            MAX(DimDate[Date]),
            DimDate[IsEvidenceEndpoint] = TRUE()
        ),

    "AsOfControllerRows",
        COUNTROWS(DimAsOfDate),

    "AsOfControllerMin",
        MIN(DimAsOfDate[AsOfDate]),

    "AsOfControllerMax",
        MAX(DimAsOfDate[AsOfDate]),

    "DefaultAsOfRows",
        CALCULATE(
            COUNTROWS(DimAsOfDate),
            DimAsOfDate[IsDefaultAsOf] = TRUE()
        ),

    "DefaultAsOfDate",
        CALCULATE(
            MAX(DimAsOfDate[AsOfDate]),
            DimAsOfDate[IsDefaultAsOf] = TRUE()
        )
)
```

Save as:

```text
E12_ASOF_DATE_SPINE.csv
```

The expected result is:

```text
DimDateRows             123
DimDateMin              2026-07-23
DimDateMax              2026-11-22

SourceRunAsOfRows       1
SourceRunAsOfDate       2026-07-23

EvidenceEndpointRows    1
EvidenceEndpointDate    2026-11-22

AsOfControllerRows      123
AsOfControllerMin       2026-07-23
AsOfControllerMax       2026-11-22

DefaultAsOfRows         1
DefaultAsOfDate         2026-11-22
```

The July 23 source/evidence cutoff and the distinction between that cutoff and the deterministic synthetic horizon are frozen cross-workstream controls. [export reference: filecite | turn9file4 | L17-L24]

### Then run one boundary-classification query

This tests the controller's temporal classification without pretending the deferred endpoint facts are loaded:

```DAX
EVALUATE
SELECTCOLUMNS(
    FILTER(
        DimAsOfDate,
        DimAsOfDate[AsOfDate] IN {
            DATE(2026,7,23),
            DATE(2026,7,24),
            DATE(2026,11,21),
            DATE(2026,11,22)
        }
    ),
    "AsOfDate", DimAsOfDate[AsOfDate],
    "IsSourceRunAsOf", DimAsOfDate[IsSourceRunAsOf],
    "IsEvidenceEndpoint", DimAsOfDate[IsEvidenceEndpoint],
    "IsDefaultAsOf", DimAsOfDate[IsDefaultAsOf]
)
ORDER BY [AsOfDate]
```

Save as:

```text
E12_ASOF_BOUNDARY_CLASSIFICATION.csv
```

This should demonstrate that July 23 and November 22 have distinct roles and that November 21 is not incorrectly marked as the certified endpoint.

After you attach **both E12 files**, we'll reconcile exactly what portion of `AUD-ASOF-003` A1a physically proves and what portion must remain held because the 13 endpoint-only fact tables are outside the authorized A1a footprint. That distinction is important because the audit explicitly says no static artifact can close the full endpoint-behavior control. [export reference: filecite | turn9file6 | L94-L100]
<!-- END_SOURCE_MESSAGE -->


<a id="m-f00b7fab-6477-46c5-ad67-df72467f0954"></a>
## Andrew / user · C091-M00100

C091-M00100 · 2026-08-19T11:46:37.442000-04:00 · active path

Preceding visible parent: [C091-M00099](part-06.md#m-827e7b6e-523d-4315-8194-cb31c898f559)

**Editorial record note:** Attachment references: E12_ASOF_BOUNDARY_CLASSIFICATION.csv; E12_ASOF_DATE_SPINE.csv

<!-- BEGIN_SOURCE_MESSAGE -->
E12_ASOF_... queries attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2df02491-7d08-406a-b3e4-b78f653e108c"></a>
## Assistant · C091-M00101

C091-M00101 · 2026-08-19T11:46:47.643790-04:00 · active path

Preceding visible parent: [C091-M00100](part-06.md#m-f00b7fab-6477-46c5-ad67-df72467f0954)

<!-- BEGIN_SOURCE_MESSAGE -->
The two E12 files reconcile exactly to the intended A1a temporal-control spine.

`E12_ASOF_DATE_SPINE.csv` physically shows:

```text
DimDateRows             123
DimDateMin              2026-07-23
DimDateMax              2026-11-22

SourceRunAsOfRows       1
SourceRunAsOfDate       2026-07-23

EvidenceEndpointRows    1
EvidenceEndpointDate    2026-11-22

AsOfControllerRows      123
AsOfControllerMin       2026-07-23
AsOfControllerMax       2026-11-22

DefaultAsOfRows         1
DefaultAsOfDate         2026-11-22
```

`E12_ASOF_BOUNDARY_CLASSIFICATION.csv` then confirms the four tested boundary dates behave distinctly:

| As-of date | Source run as-of | Evidence endpoint | Default as-of |
|---|---:|---:|---:|
| 2026-07-23 | TRUE | FALSE | FALSE |
| 2026-07-24 | FALSE | FALSE | FALSE |
| 2026-11-21 | FALSE | FALSE | FALSE |
| 2026-11-22 | FALSE | TRUE | TRUE |

That is clean physical local-engine evidence that the model distinguishes the accepted **2026-07-23 source/evidence cutoff** from the **2026-11-22 deterministic-synthetic endpoint**, rather than conflating those dates. That distinction is part of the frozen cross-workstream contract. [export reference: filecite | turn9file4 | L17-L24]

The important governance distinction is that **A1a does not contain the 13 endpoint-only business fact tables**. Therefore, A1a can prove the controller/date-spine component of `AUD-ASOF-003`, but it cannot physically prove that each deferred endpoint-only fact returns blank before November 22 or a HOLD outside the evidence horizon. The prior audit explicitly said that endpoint-only behavioral evidence remains a local-engine hold and cannot be closed by static evidence alone. [export reference: filecite | turn9file6 | L94-L100]

I would now record the three controls as:

```text
AUD-SCN-004
PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
Evidence: E09_SCENARIO_ISOLATION.csv
Result: 44 / $472,000 baseline; 15 / $195,600 recession overlay

AUD-REL-005
PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
Evidence:
  E08_TMSCHEMA_RELATIONSHIPS.csv
  E10_RELATIONSHIP_FILTER_BEHAVIOR.csv
  E11_RELATIONSHIP_ORPHANS.csv
Result:
  6 instantiated
  6 active
  6 one-to-many / single-direction
  6/6 filter behavior PASS
  6/6 orphan controls = 0

AUD-ASOF-003
PARTIAL_PHYSICAL_EVIDENCE_CAPTURED / HOLD_REMAINS
Evidence:
  E12_ASOF_DATE_SPINE.csv
  E12_ASOF_BOUNDARY_CLASSIFICATION.csv
Result:
  date/controller spine PASS
Limitation:
  13 endpoint-only deferred facts are outside A1a and were not instantiated,
  so historical blanking / endpoint visibility / outside-evidence HOLD behavior
  cannot yet be physically tested.
```

## Next step: preserve the completed A1a engine state

We are now at the point where I recommend **saving the working project once**, closing Power BI and DAX Studio, and generating the final post-execution manifest before we package the evidence for Independent Audit.

Before saving, verify visually one last time that the report still contains exactly:

```text
1 technical shell page
0 substantive pages
0 visuals
0 explicit measures
```

Then use **Ctrl+S** in Power BI Desktop. Do not publish or convert the project.

After saving, close DAX Studio and then Power BI Desktop normally. Once both are fully closed, tell me. I’ll give you the final PowerShell block to generate the post-save hashes, reconcile all A1a evidence artifacts, and prepare the audit submission package—including the HF01 chronology and the privacy-setting observation—without beginning A1b.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5b702427-e71b-48d3-9f74-62e3fb4fa1a9"></a>
## Andrew / user · C091-M00102

C091-M00102 · 2026-08-19T11:49:58.140000-04:00 · active path

Preceding visible parent: [C091-M00101](part-06.md#m-2df02491-7d08-406a-b3e4-b78f653e108c)

<!-- BEGIN_SOURCE_MESSAGE -->
Power BI Desktop saved and closed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fc456bcb-78ab-417f-8c39-e0e60d33a9d1"></a>
## Assistant · C091-M00103

C091-M00103 · 2026-08-19T11:50:02.582364-04:00 · active path

Preceding visible parent: [C091-M00102](part-06.md#m-5b702427-e71b-48d3-9f74-62e3fb4fa1a9)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. Now that Power BI Desktop and DAX Studio are closed, we can freeze the executed A1a state, generate the final manifests/hashes, and build the audit-return package **without reopening Desktop and without beginning A1b**.

The evidence collected so far supports a successful bounded A1a local-engine execution, with one important limitation: `AUD-ASOF-003` has only the A1a date/controller portion physically tested because the 13 endpoint-only facts are outside A1a. The shell decision explicitly keeps all three controls subject to Independent Audit disposition. [export reference: filecite | turn9file0 | L127-L155]

## 1. Run the final post-save boundary verification

Open PowerShell 7 and run:

```powershell
$ErrorActionPreference = "Stop"

$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"
$downloads = Join-Path $HOME "Downloads"

$verifier = Join-Path $downloads `
    "Verify-A1aTechnicalShellBoundary.ps1"

& $verifier `
    -PackageRoot $work `
    -SourceRoot `
    "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818" *>&1 |
    Tee-Object `
        -FilePath "$ev\E13_FINAL_POST_SAVE_BOUNDARY_VERIFICATION.txt"
```

Required result remains:

```text
14 semantic tables
6 relationships
47 Power Query queries
0 explicit measures
67 semantic activation objects

1 technical shell page
0 substantive report pages
0 visuals
0 bookmarks
0 A1b objects

active_page_resolves = true
status = PASS
```

If anything differs, stop and paste the output.

---

## 2. Capture the installed Power BI Desktop identity without reopening it

Run:

```powershell
$desktopCandidates = @(
    "$env:LOCALAPPDATA\Microsoft\WindowsApps\PBIDesktop.exe",
    "$env:ProgramFiles\Microsoft Power BI Desktop\bin\PBIDesktop.exe",
    "${env:ProgramFiles(x86)}\Microsoft Power BI Desktop\bin\PBIDesktop.exe"
) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

$desktopExe = $null

foreach ($candidate in $desktopCandidates) {
    try {
        $resolved = (Get-Item -LiteralPath $candidate -ErrorAction Stop)
        if ($resolved) {
            $desktopExe = $resolved.FullName
            break
        }
    }
    catch {}
}

$desktopEvidence = [ordered]@{
    event = "POWER_BI_DESKTOP_LOCAL_IDENTITY"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")
    executable_path_found = ($null -ne $desktopExe)
    executable_path = if ($desktopExe) { $desktopExe } else { "NOT_RESOLVED" }
    file_version = if ($desktopExe) {
        (Get-Item -LiteralPath $desktopExe).VersionInfo.FileVersion
    } else {
        "NOT_RESOLVED"
    }
    product_version = if ($desktopExe) {
        (Get-Item -LiteralPath $desktopExe).VersionInfo.ProductVersion
    } else {
        "NOT_RESOLVED"
    }
}

$desktopEvidence |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -LiteralPath "$ev\E13_POWER_BI_DESKTOP_IDENTITY.json" `
        -Encoding utf8

$desktopEvidence | Format-List
```

If the Microsoft Store installation prevents PowerShell from resolving the executable version, `NOT_RESOLVED` is acceptable; do not reopen Desktop just to manufacture missing evidence.

---

## 3. Generate the corrected post-save manifest

Use the corrected helper—not the defective original packaged copy:

```powershell
$postSaveManifest = Join-Path $downloads `
    "Export-A1aPostSaveManifest_FIXED.ps1"

Unblock-File -LiteralPath $postSaveManifest

& $postSaveManifest `
    -PackageRoot $work `
    -OutputDirectory $ev
```

Expected files:

```text
E12_POST_SAVE_MANIFEST.csv
E12_POST_SAVE_SHA256SUMS.txt
```

If you already generated an earlier E12 manifest before the final engine run, this invocation should replace it with the **actual final saved state**.

---

## 4. Record the final control dispositions

Run:

```powershell
$controlStatus = @(
    [pscustomobject]@{
        control_id = "AUD-SCN-004"
        source_owner_status = "PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION"
        evidence = "E09_SCENARIO_ISOLATION.csv"
        result = "BASELINE 44 paths / 44 applications / 472000 funded; RECESSION_ENERGY 15 paths / 15 applications / 195600 funded"
        limitation = "Independent Audit closure required"
    },
    [pscustomobject]@{
        control_id = "AUD-REL-005"
        source_owner_status = "PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION"
        evidence = "E08_TMSCHEMA_RELATIONSHIPS.csv; E10_RELATIONSHIP_FILTER_BEHAVIOR.csv; E11_RELATIONSHIP_ORPHANS.csv"
        result = "6 instantiated active one-to-many single-direction relationships; filter propagation reconciles; 6/6 orphan controls = 0"
        limitation = "Independent Audit closure required"
    },
    [pscustomobject]@{
        control_id = "AUD-ASOF-003"
        source_owner_status = "PARTIAL_PHYSICAL_EVIDENCE_CAPTURED_HOLD_REMAINS"
        evidence = "E12_ASOF_DATE_SPINE.csv; E12_ASOF_BOUNDARY_CLASSIFICATION.csv"
        result = "A1a date/controller spine physically reconciles 2026-07-23 source cutoff and 2026-11-22 endpoint/default-as-of"
        limitation = "13 endpoint-only business facts are outside authorized A1a; historical blanking, endpoint visibility, and post-evidence HOLD behavior were not physically executed"
    }
)

$controlStatus |
    Export-Csv `
        -LiteralPath "$ev\E13_LOCAL_ENGINE_CONTROL_DISPOSITION.csv" `
        -NoTypeInformation `
        -Encoding utf8
```

This distinction is important because the governing audit says static evidence cannot itself close the endpoint-behavior control. [export reference: filecite | turn9file6 | L94-L100]

---

## 5. Create the complete execution chronology

This records the two runtime issues transparently rather than presenting the final successful state as though it occurred on the first attempt.

```powershell
$chronology = @'
# A1a Local Power BI Execution Chronology

## Governing boundary

- 14 semantic tables
- 6 relationships
- 47 Power Query queries
- 0 explicit measures
- 1 physical technical shell page
- 0 substantive report pages
- 0 visual objects
- 0 A1b objects

## Execution chronology

1. Initial zero-page PBIP open failed:
   - `ActivePageName not found`
   - `The report has no pages. Reports must have at least one page.`
   - Desktop was closed without saving that attempted state.

2. Independent Audit decision `IA-D-R3A-PBI-001` authorized exactly one blank technical shell page:
   - `A1A_TECHNICAL_SHELL_NO_VISUALS`
   - zero visuals
   - zero substantive report pages.

3. Derived working copy created.
   Pre-shell verification:
   - 14 tables
   - 6 relationships
   - 47 queries
   - 0 measures
   - 0 pages
   - 0 A1b tokens.

4. Technical shell created and saved.
   Post-shell verification:
   - 1 physical technical shell page
   - 0 substantive pages
   - 0 visuals
   - active-page reference resolved.

5. Power Query Refresh Preview Attempt 1 failed:
   - `Expression.Error: The value isn't a single-character string.`
   - malformed M path literal used `\\` where Power Query M required `\`.
   - downstream build-catalog reads also failed.

6. Source owner explicitly authorized bounded hotfix `A1A-M-RUNTIME-HF01`.
   Hotfix changed only:
   - `stg_POWER_BI_DATA_CATALOG`
   - `fxReadCatalogedCsv`
   - `fxReadBuildCsv`

   Exact change population:
   - 3 external M definitions
   - 7 M source lines
   - matching 7 embedded model.bim line values
   - no whole-BIM JSON reserialization
   - no table, relationship, query, measure, page, key, grain, source-selection, or business-logic expansion.

7. Power Query Refresh Preview Attempt 2 reached the Desktop privacy gate.
   - Private classification produced local function-population errors.
   - local C:\ source was classified Public for this local execution.
   - privacy protection was not globally ignored.
   - this setting is recorded as a local execution configuration, not a production governance standard.

8. Refresh Preview Attempt 2 then completed successfully.

9. Initial Close & Apply instantiated model metadata but no rows were visible.
   Desktop showed `Invalid Date` / incomplete-data indicators.
   Read-only investigation established:
   - `DimDate` had 123 rows in Power Query,
   - Date type,
   - 100% valid,
   - 0% error,
   - model date metadata was valid `dateTime / Short Date`.

10. Desktop data refresh then completed successfully.
    All 14 tables loaded.
    Physical examples:
    - `DimDate` = 123 rows
    - `FactValidationResult` = 533 rows.

11. DAX Studio live-engine metadata reconciled:
    - 14 tables
    - 242 columns
    - 6 relationships
    - 0 measures
    - 14 partitions
    - 33 expressions
    - 47 Power Query objects.

12. Scenario isolation physically passed:
    - BASELINE = 44 paths / 44 applications / $472,000
    - RECESSION_ENERGY = 15 paths / 15 applications / $195,600.

13. Six relationship filter-propagation tests passed.

14. Six relationship orphan tests returned literal zeroes.

15. A1a as-of/date-controller tests passed:
    - source cutoff = 2026-07-23
    - endpoint = 2026-11-22
    - default as-of = 2026-11-22
    - 123-date controller spine.

16. The 13 endpoint-only business facts remain outside A1a.
    Therefore full pre-endpoint blanking / endpoint visibility / post-evidence HOLD behavior was not physically tested.

17. Power BI Desktop was saved and closed.
    A1b was not started.
    No public Power BI milestone claim was made.

## Controlling source-owner state

- `AUD-SCN-004`: PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
- `AUD-REL-005`: PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION
- `AUD-ASOF-003`: PARTIAL_PHYSICAL_EVIDENCE_CAPTURED / HOLD_REMAINS
- `PBI-WP2`: HOLD
- `A1b`: NOT_AUTHORIZED
- Public Power BI claims: NOT_AUTHORIZED
'@

$chronology |
    Set-Content `
        -LiteralPath "$ev\E13_A1A_LOCAL_EXECUTION_CHRONOLOGY.md" `
        -Encoding utf8
```

---

## 6. Create a final evidence inventory with hashes

Run:

```powershell
$evidenceInventory = @(
    Get-ChildItem `
        -LiteralPath $ev `
        -File `
        -Recurse |
    Sort-Object FullName |
    ForEach-Object {
        [pscustomobject]@{
            relative_path = $_.FullName.Substring($ev.Length + 1)
            bytes = $_.Length
            sha256 = (
                Get-FileHash `
                    -LiteralPath $_.FullName `
                    -Algorithm SHA256
            ).Hash.ToLowerInvariant()
        }
    }
)

$evidenceInventory |
    Export-Csv `
        -LiteralPath "$ev\E13_FINAL_EVIDENCE_INVENTORY.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host "Evidence files inventoried:" $evidenceInventory.Count
```

---

## 7. Create a fresh final PBIP project manifest

```powershell
$projectRoot = Join-Path $work "project"

$projectManifest = @(
    Get-ChildItem `
        -LiteralPath $projectRoot `
        -File `
        -Recurse |
    Sort-Object FullName |
    ForEach-Object {
        [pscustomobject]@{
            relative_path = $_.FullName.Substring($projectRoot.Length + 1)
            bytes = $_.Length
            sha256 = (
                Get-FileHash `
                    -LiteralPath $_.FullName `
                    -Algorithm SHA256
            ).Hash.ToLowerInvariant()
        }
    }
)

$projectManifest |
    Export-Csv `
        -LiteralPath "$ev\E13_FINAL_PBIP_PROJECT_MANIFEST.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host "PBIP files inventoried:" $projectManifest.Count
```

This is the final physical project identity after the Desktop execution—not the pre-shell or pre-hotfix identity.

---

## 8. Build the Independent Audit submission carrier

Run this only after Steps 1–7 pass:

```powershell
$submissionName = "MSBF_PBI_A1A_LOCAL_ENGINE_EVIDENCE_R1_20260819"
$submissionRoot = Join-Path "C:\MSBF" $submissionName

if (Test-Path -LiteralPath $submissionRoot) {
    throw "Submission root already exists. Preserve it and choose a new R-number rather than overwriting."
}

New-Item `
    -ItemType Directory `
    -Path $submissionRoot |
    Out-Null

New-Item `
    -ItemType Directory `
    -Path (Join-Path $submissionRoot "project") |
    Out-Null

New-Item `
    -ItemType Directory `
    -Path (Join-Path $submissionRoot "evidence") |
    Out-Null

Copy-Item `
    -LiteralPath "$work\project\*" `
    -Destination "$submissionRoot\project" `
    -Recurse `
    -Force

Copy-Item `
    -LiteralPath "$ev\*" `
    -Destination "$submissionRoot\evidence" `
    -Recurse `
    -Force

$status = @'
# MSBF Power BI A1a Local-Engine Evidence — Source-Owner Submission

## Submission state

A1a bounded local-engine execution completed under source-owner authority and the
independently authorized one-page technical-shell compatibility exception.

### Physical executed footprint

- Semantic tables: 14
- Relationships: 6
- Power Query queries: 47
- Explicit DAX measures: 0
- Semantic activation objects: 67
- Physical technical shell pages: 1
- Substantive report pages: 0
- Visual objects: 0
- A1b objects: 0

### Runtime remediation disclosed

`A1A-M-RUNTIME-HF01` corrected a Power Query M Windows-path literal defect in
three existing definitions. Exact before/after hashes and seven changed source
lines are included. No source-selection, key, grain, semantic-count, business
logic, measure, or report-experience expansion occurred.

### Local privacy observation

The local C:\ data source required Public privacy classification for the
successful bounded Desktop execution after Private produced function-evaluation
errors. Privacy protections were not globally disabled. This is evidence of the
local execution configuration and is not proposed as a production privacy
standard.

### Local-engine controls

- AUD-SCN-004:
  PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION

- AUD-REL-005:
  PHYSICAL_EVIDENCE_CAPTURED_PENDING_INDEPENDENT_DISPOSITION

- AUD-ASOF-003:
  PARTIAL_PHYSICAL_EVIDENCE_CAPTURED / HOLD_REMAINS

The A1a date/controller spine was physically tested. The thirteen endpoint-only
facts are outside A1a and therefore their historical blanking, endpoint
visibility, and outside-evidence HOLD behavior were not physically executed.

### Unchanged governance

- PBI-WP2: HOLD
- A1b: NOT_AUTHORIZED
- Public Power BI milestone claims: NOT_AUTHORIZED
- No substantive report-page construction occurred.
- No publication or deployment occurred.

This is a source-owner evidence submission. Independent Audit retains finding
and gate disposition authority.
'@

$status |
    Set-Content `
        -LiteralPath "$submissionRoot\00_SOURCE_OWNER_SUBMISSION_STATUS.md" `
        -Encoding utf8
```

---

## 9. Create the carrier manifest and ZIP

```powershell
$payloadManifestPath = Join-Path $submissionRoot `
    "MANIFEST_SHA256.csv"

$payloadFiles = @(
    Get-ChildItem `
        -LiteralPath $submissionRoot `
        -File `
        -Recurse |
    Where-Object {
        $_.FullName -ne $payloadManifestPath
    } |
    Sort-Object FullName
)

$payloadManifest = foreach ($file in $payloadFiles) {
    [pscustomobject]@{
        relative_path = $file.FullName.Substring($submissionRoot.Length + 1)
        bytes = $file.Length
        sha256 = (
            Get-FileHash `
                -LiteralPath $file.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$payloadManifest |
    Export-Csv `
        -LiteralPath $payloadManifestPath `
        -NoTypeInformation `
        -Encoding utf8

$zip = "C:\MSBF\$submissionName.zip"

Compress-Archive `
    -Path "$submissionRoot\*" `
    -DestinationPath $zip `
    -CompressionLevel Optimal

$zipHash = (
    Get-FileHash `
        -LiteralPath $zip `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

$sidecar = "$zip.sha256"

"$zipHash  $submissionName.zip" |
    Set-Content `
        -LiteralPath $sidecar `
        -Encoding ascii

Write-Host ""
Write-Host "Audit carrier created:"
Write-Host $zip
Write-Host ""
Write-Host "SHA-256:"
Write-Host $zipHash
```

---

## 10. Run a simple ZIP integrity check

```powershell
Add-Type -AssemblyName System.IO.Compression.FileSystem

$archive = [System.IO.Compression.ZipFile]::OpenRead($zip)

try {
    $entries = @($archive.Entries)

    $unsafe = @(
        $entries |
        Where-Object {
            $_.FullName.StartsWith("/") -or
            $_.FullName.StartsWith("\") -or
            $_.FullName -match '(^|[\\/])\.\.([\\/]|$)'
        }
    )

    $duplicates = @(
        $entries |
        Group-Object FullName |
        Where-Object Count -gt 1
    )

    $caseFoldDuplicates = @(
        $entries |
        Group-Object { $_.FullName.ToLowerInvariant() } |
        Where-Object Count -gt 1
    )

    [pscustomobject]@{
        zip = [IO.Path]::GetFileName($zip)
        bytes = (Get-Item $zip).Length
        sha256 = $zipHash
        members = $entries.Count
        unsafe_paths = $unsafe.Count
        duplicate_paths = $duplicates.Count
        case_fold_duplicate_paths = $caseFoldDuplicates.Count
        result = if (
            $unsafe.Count -eq 0 -and
            $duplicates.Count -eq 0 -and
            $caseFoldDuplicates.Count -eq 0
        ) {
            "PASS"
        } else {
            "FAIL"
        }
    } |
        Format-List
}
finally {
    $archive.Dispose()
}
```

Required:

```text
unsafe_paths                0
duplicate_paths             0
case_fold_duplicate_paths   0
result                      PASS
```

---

Once those commands finish, send me:

1. the final shell-verifier result;
2. the generated ZIP filename, byte size, and SHA-256;
3. the ZIP integrity result.

Then I can give you the exact **Independent Audit submission prompt**, including the disclosure of your bounded HF01 authorization and the request for separate dispositions on `AUD-SCN-004`, `AUD-REL-005`, and the still-partial `AUD-ASOF-003`.
<!-- END_SOURCE_MESSAGE -->
