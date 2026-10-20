# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 28 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-27.md)
[Next part](part-29.md)

<a id="m-572e7b4e-a355-4328-a0b0-66a6fa4fed0a"></a>
## Assistant · C109-M00601

C109-M00601 · 2026-09-02T08:15:29.623904-04:00 · active path

Preceding visible parent: [C109-M00600](part-27.md#m-afc980b4-d940-4dae-ab8b-0eba393bd6c3)

<!-- BEGIN_SOURCE_MESSAGE -->
You do **not** need to pre-build the `C:\MSBF\R26\power_bi\carrier` folder. The script creates that path for you. The only local prerequisite is that you have the **exact R26 handoff ZIP** somewhere on your PC and know its full path.

The handoff package itself has already been verified as clean and candidate-only, with the expected SHA-256 and no publication authority. [export reference: filecite | turn99file0 | L2-L15]

### Recommended local setup

I would keep it simple:

```text
C:\MSBF\R26\
    MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip

C:\MSBF\PowerBI\R26_Parallel\
    MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\
        scripts\
            00_PREPARE_R26_CARRIER.ps1
        ...
```

But those exact locations are **not required**. The handoff ZIP could even remain in Downloads, because you pass its full path to the script.

What matters is:

- the script file exists locally;
- the exact R26 handoff ZIP exists locally;
- you have write permission to `C:\MSBF`;
- Power BI is not actively refreshing from the carrier while you replace it.

### Important behavior of the script

The script does four things automatically:

1. Verifies the handoff ZIP itself against this exact SHA-256:

```text
53fd448b61b15b1e61ebd34e778cb00364169145c541467ea2a453cd1a9ec467
```

2. Extracts the handoff ZIP into a temporary Windows folder.

3. Finds the embedded:

```text
carrier\
```

folder and copies it to:

```text
C:\MSBF\R26\power_bi\carrier
```

4. Then independently verifies:
   - `SUCCESSOR_DATA_CATALOG.csv`
   - `curated\R1FactDailyMonitoring.csv`
   - the unique `r26_policy_sha256` inside the monitoring file.

So you **do not** manually extract the handoff first. Give the script the ZIP itself.

### One destructive behavior to be aware of

If this already exists:

```text
C:\MSBF\R26\power_bi\carrier
```

the script **deletes that entire carrier folder first** and replaces it with the verified copy from the handoff.

That is intentional.

It does **not** delete:

```text
C:\MSBF
C:\MSBF\R26
your current PBIP
your old R22/R1 refinement project
```

Only the exact `carrier` folder supplied as `$CarrierRoot`.

So if you happen to have manually put anything unique inside:

```text
C:\MSBF\R26\power_bi\carrier
```

move it first. Normally there should be nothing there that needs preserving.

---

## Exact steps I recommend

### 1. Put the handoff ZIP somewhere convenient

For example:

```text
C:\MSBF\R26\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip
```

Do **not** unzip it.

### 2. Extract my delivery package

Extract:

MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY.zip (historical reference: `sandbox:[session]/MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY.zip`; referenced bytes not established here)

For example to:

```text
C:\MSBF\PowerBI\R26_Parallel\
```

After extraction you should have something like:

```text
C:\MSBF\PowerBI\R26_Parallel\
    MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\
        00_START_HERE.md
        evidence\
        project\
        scripts\
        tests\
```

Inside `scripts`:

```text
00_PREPARE_R26_CARRIER.ps1
```

### 3. Close or leave idle your currently open pre-R26 Power BI

I recommend **saving and closing** the current pre-R26 PBIP first.

That preserves your exact pre-R26 working candidate as the comparison point.

### 4. Open a fresh PowerShell window

You do **not** need to run PowerShell as Administrator unless your Windows permissions specifically prevent writing under `C:\MSBF`.

Then run:

```powershell
Set-Location "C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY"
```

Verify the two things we need:

```powershell
Test-Path ".\scripts\00_PREPARE_R26_CARRIER.ps1"
Test-Path "C:\MSBF\R26\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip"
```

Both should return:

```text
True
```

### 5. Run the preparation script

Use:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File ".\scripts\00_PREPARE_R26_CARRIER.ps1" `
    -HandoffZip "C:\MSBF\R26\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip"
```

You do **not** need to specify `-CarrierRoot`, because the script defaults to:

```text
C:\MSBF\R26\power_bi\carrier
```

If successful, the last line should be:

```text
R26 carrier prepared and verified: C:\MSBF\R26\power_bi\carrier
```

If any hash or policy identity fails, the script stops rather than installing an unverified carrier.

---

## 6. Verify the result manually

After it finishes:

```powershell
Test-Path "C:\MSBF\R26\power_bi\carrier"
Test-Path "C:\MSBF\R26\power_bi\carrier\SUCCESSOR_DATA_CATALOG.csv"
Test-Path "C:\MSBF\R26\power_bi\carrier\curated\R1FactDailyMonitoring.csv"
```

All three should return:

```text
True
```

You can also confirm the monitoring header now has 47 fields:

```powershell
$Row = Import-Csv "C:\MSBF\R26\power_bi\carrier\curated\R1FactDailyMonitoring.csv" |
    Select-Object -First 1

$Row.PSObject.Properties.Name.Count
```

Expected:

```text
47
```

And confirm the R26 policy:

```powershell
Import-Csv "C:\MSBF\R26\power_bi\carrier\curated\R1FactDailyMonitoring.csv" |
    Select-Object -ExpandProperty r26_policy_sha256 -Unique
```

Expected exactly:

```text
6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027
```

### What you do **not** need to place there

Do **not** put any of these inside the carrier folder:

- your `.pbip`/report project;
- the SemanticModel folder;
- the Report folder;
- screenshots/evidence;
- old R22 carrier;
- old R1 carrier;
- DAX scripts.

`C:\MSBF\R26\power_bi\carrier` is purely the **governed R26 source-data carrier** Power Query will read.

Your Power BI project remains separate.

Once you get the `R26 carrier prepared and verified` message, the next step is opening the new R26 project and doing the physical **Refresh All**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e8760874-3162-47bc-bd22-aa3ea2bc3b4d"></a>
## Andrew / user · C109-M00602

C109-M00602 · 2026-09-02T08:20:56.376000-04:00 · active path

Preceding visible parent: [C109-M00601](part-28.md#m-572e7b4e-a355-4328-a0b0-66a6fa4fed0a)

<!-- BEGIN_SOURCE_MESSAGE -->
C:\MSBF\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip & C:\MSBF\PowerBI\R26_Parallel\     MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY... are established. re-provide updated powershell script
<!-- END_SOURCE_MESSAGE -->


<a id="m-ea961c39-b351-40a6-b999-a965df7808a8"></a>
## Assistant · C109-M00603

C109-M00603 · 2026-09-02T08:21:00.001664-04:00 · active path

Preceding visible parent: [C109-M00602](part-28.md#m-e8760874-3162-47bc-bd22-aa3ea2bc3b4d)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. With those two locations established, use the following exactly from a **fresh PowerShell window**.

Your paths are now:

```text
R26 handoff ZIP:
C:\MSBF\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip

R26 Power BI delivery:
C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY
```

## 1. Start in a clean PowerShell session

Open **Windows PowerShell** normally. Administrator is not required unless Windows blocks writes under `C:\MSBF`.

Run:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
```

Then establish the three working paths:

```powershell
$DeliveryRoot = "C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY"
$HandoffZip   = "C:\MSBF\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip"
$CarrierRoot  = "C:\MSBF\R26\power_bi\carrier"
```

Move into the delivery package:

```powershell
Set-Location $DeliveryRoot
```

Confirm:

```powershell
Get-Location
```

Expected:

```text
C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY
```

---

## 2. Confirm all required inputs exist before doing anything

Run:

```powershell
$Checks = [ordered]@{
    "Delivery root" = Test-Path $DeliveryRoot
    "R26 handoff ZIP" = Test-Path $HandoffZip
    "Preparation script" = Test-Path "$DeliveryRoot\scripts\00_PREPARE_R26_CARRIER.ps1"
    "R26 Desktop DAX checks" = Test-Path "$DeliveryRoot\tests\R26_DESKTOP_CHECKPOINTS.dax"
    "Project folder" = Test-Path "$DeliveryRoot\project"
}

$Checks.GetEnumerator() | Format-Table -AutoSize
```

Every line should say:

```text
True
```

If any line says `False`, stop there.

---

## 3. Independently verify the handoff ZIP hash before running the script

Run:

```powershell
$ExpectedHandoffSha = "53fd448b61b15b1e61ebd34e778cb00364169145c541467ea2a453cd1a9ec467"

$ActualHandoffSha = (Get-FileHash -Algorithm SHA256 $HandoffZip).Hash.ToLower()

[pscustomobject]@{
    File     = $HandoffZip
    Expected = $ExpectedHandoffSha
    Actual   = $ActualHandoffSha
    Match    = ($ActualHandoffSha -eq $ExpectedHandoffSha)
} | Format-List
```

You want:

```text
Match : True
```

Do not continue if it returns `False`.

The package receipt identifies that handoff as `PASS`, clean-extraction `PASS`, and candidate-only pending R26 focused audit. [export reference: filecite | turn99file0 | L2-L15]

---

# 4. Run the R26 carrier-preparation script

Now run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File "$DeliveryRoot\scripts\00_PREPARE_R26_CARRIER.ps1" `
    -HandoffZip "$HandoffZip" `
    -CarrierRoot "$CarrierRoot"
```

Because we are explicitly passing both paths, there is no ambiguity about where the script reads from or writes to.

The target is:

```text
C:\MSBF\R26\power_bi\carrier
```

### Expected successful ending

You should see something equivalent to:

```text
R26 carrier prepared and verified:
C:\MSBF\R26\power_bi\carrier
```

If the script produces an error, **do not manually copy the carrier as a workaround**. Send me the full PowerShell error.

---

# 5. Verify the installed carrier

After the script completes successfully, run:

```powershell
$CarrierChecks = [ordered]@{
    "Carrier root" = Test-Path $CarrierRoot
    "Catalog" = Test-Path "$CarrierRoot\SUCCESSOR_DATA_CATALOG.csv"
    "Daily monitoring" = Test-Path "$CarrierRoot\curated\R1FactDailyMonitoring.csv"
}

$CarrierChecks.GetEnumerator() | Format-Table -AutoSize
```

All should return:

```text
True
```

---

## 6. Verify the R26 monitoring file has exactly 47 columns

Run:

```powershell
$MonitoringFile = "$CarrierRoot\curated\R1FactDailyMonitoring.csv"

$FirstMonitoringRow = Import-Csv $MonitoringFile | Select-Object -First 1

$MonitoringColumnCount = $FirstMonitoringRow.PSObject.Properties.Name.Count

Write-Host "R1FactDailyMonitoring column count: $MonitoringColumnCount"
```

Expected:

```text
R1FactDailyMonitoring column count: 47
```

Then verify the 11 new R26 fields physically exist:

```powershell
$RequiredR26Fields = @(
    "raw_alert_condition_count",
    "pace_family_active_flag",
    "pace_family_severity_code",
    "no_remittance_family_active_flag",
    "sales_dormancy_family_active_flag",
    "liquidity_family_active_flag",
    "horizon_family_active_flag",
    "operational_alert_family_count",
    "primary_operational_alert_family_code",
    "operational_alert_payload",
    "r26_policy_sha256"
)

$ActualColumns = $FirstMonitoringRow.PSObject.Properties.Name

$RequiredR26Fields | ForEach-Object {
    [pscustomobject]@{
        Field = $_
        Present = ($_ -in $ActualColumns)
    }
} | Format-Table -AutoSize
```

Every row should show:

```text
Present = True
```

---

# 7. Verify the monitoring population is 15,600 rows

Run:

```powershell
$MonitoringRows = @(Import-Csv $MonitoringFile).Count

Write-Host "Monitoring rows: $MonitoringRows"
```

Expected:

```text
Monitoring rows: 15600
```

---

# 8. Verify the exact R26 policy SHA

Run:

```powershell
$ExpectedPolicySha = "6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027"

$PolicyValues = Import-Csv $MonitoringFile |
    Select-Object -ExpandProperty r26_policy_sha256 |
    Sort-Object -Unique

Write-Host "Unique R26 policy SHA values:"
$PolicyValues

Write-Host ""
Write-Host "Unique policy count:" $PolicyValues.Count
Write-Host "Exact policy match:" ($PolicyValues.Count -eq 1 -and $PolicyValues[0] -eq $ExpectedPolicySha)
```

Expected:

```text
Unique policy count: 1
Exact policy match: True
```

---

# 9. Optional but useful — verify the carrier file count and size

Run:

```powershell
$CarrierFiles = Get-ChildItem $CarrierRoot -File -Recurse

[pscustomobject]@{
    CarrierRoot = $CarrierRoot
    FileCount   = $CarrierFiles.Count
    TotalBytes  = ($CarrierFiles | Measure-Object Length -Sum).Sum
} | Format-List
```

This gives us a simple local receipt for what Power BI is about to consume.

---

# 10. Locate the new R26 Power BI project before opening Desktop

Run:

```powershell
Get-ChildItem "$DeliveryRoot\project" -Recurse -Filter definition.pbir |
    Select-Object FullName
```

You should see the new R26 report project's `definition.pbir`.

For convenience, set:

```powershell
$R26Pbir = (
    Get-ChildItem "$DeliveryRoot\project" -Recurse -Filter definition.pbir |
    Select-Object -First 1
).FullName

Write-Host $R26Pbir
```

Confirm:

```powershell
Test-Path $R26Pbir
```

Expected:

```text
True
```

---

# 11. Open the R26 project

You can then launch it directly:

```powershell
Start-Process $R26Pbir
```

Power BI Desktop should open the **new R26 parallel refinement**, not your pre-R26 project.

Before refreshing, verify visually that the project identity is the new:

```text
MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902
```

Then perform:

```text
Home → Refresh
```

or:

```text
Home → Refresh all
```

depending on how your Desktop build labels it.

---

## The full copy/paste block

If you want to execute the carrier preparation in one controlled block, use this:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$DeliveryRoot = "C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY"
$HandoffZip   = "C:\MSBF\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip"
$CarrierRoot  = "C:\MSBF\R26\power_bi\carrier"

Set-Location $DeliveryRoot

Write-Host "=== INPUT CHECKS ==="

$Checks = [ordered]@{
    "Delivery root"       = Test-Path $DeliveryRoot
    "R26 handoff ZIP"     = Test-Path $HandoffZip
    "Preparation script"  = Test-Path "$DeliveryRoot\scripts\00_PREPARE_R26_CARRIER.ps1"
    "Desktop DAX checks"   = Test-Path "$DeliveryRoot\tests\R26_DESKTOP_CHECKPOINTS.dax"
    "Project folder"       = Test-Path "$DeliveryRoot\project"
}

$Checks.GetEnumerator() | Format-Table -AutoSize

if ($Checks.Values -contains $false) {
    throw "One or more required inputs are missing."
}

Write-Host ""
Write-Host "=== HANDOFF SHA-256 ==="

$ExpectedHandoffSha = "53fd448b61b15b1e61ebd34e778cb00364169145c541467ea2a453cd1a9ec467"
$ActualHandoffSha = (Get-FileHash -Algorithm SHA256 $HandoffZip).Hash.ToLower()

Write-Host "Expected:" $ExpectedHandoffSha
Write-Host "Actual:  " $ActualHandoffSha

if ($ActualHandoffSha -ne $ExpectedHandoffSha) {
    throw "R26 handoff SHA-256 mismatch."
}

Write-Host "Handoff SHA-256: PASS"

Write-Host ""
Write-Host "=== PREPARE R26 CARRIER ==="

powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File "$DeliveryRoot\scripts\00_PREPARE_R26_CARRIER.ps1" `
    -HandoffZip "$HandoffZip" `
    -CarrierRoot "$CarrierRoot"

if ($LASTEXITCODE -ne 0) {
    throw "R26 carrier preparation script failed with exit code $LASTEXITCODE."
}

Write-Host ""
Write-Host "=== CARRIER VALIDATION ==="

$CatalogFile    = "$CarrierRoot\SUCCESSOR_DATA_CATALOG.csv"
$MonitoringFile = "$CarrierRoot\curated\R1FactDailyMonitoring.csv"

if (-not (Test-Path $CatalogFile)) {
    throw "SUCCESSOR_DATA_CATALOG.csv is missing."
}

if (-not (Test-Path $MonitoringFile)) {
    throw "R1FactDailyMonitoring.csv is missing."
}

$MonitoringRows = @(Import-Csv $MonitoringFile)
$MonitoringCount = $MonitoringRows.Count
$Columns = $MonitoringRows[0].PSObject.Properties.Name
$ColumnCount = $Columns.Count

Write-Host "Monitoring rows:    $MonitoringCount"
Write-Host "Monitoring columns: $ColumnCount"

if ($MonitoringCount -ne 15600) {
    throw "Unexpected R1FactDailyMonitoring row count."
}

if ($ColumnCount -ne 47) {
    throw "Unexpected R1FactDailyMonitoring column count."
}

$RequiredR26Fields = @(
    "raw_alert_condition_count",
    "pace_family_active_flag",
    "pace_family_severity_code",
    "no_remittance_family_active_flag",
    "sales_dormancy_family_active_flag",
    "liquidity_family_active_flag",
    "horizon_family_active_flag",
    "operational_alert_family_count",
    "primary_operational_alert_family_code",
    "operational_alert_payload",
    "r26_policy_sha256"
)

$MissingFields = @(
    $RequiredR26Fields | Where-Object { $_ -notin $Columns }
)

if ($MissingFields.Count -gt 0) {
    throw "Missing required R26 fields: $($MissingFields -join ', ')"
}

$ExpectedPolicySha = "6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027"

$PolicyValues = @(
    $MonitoringRows |
        Select-Object -ExpandProperty r26_policy_sha256 |
        Sort-Object -Unique
)

if ($PolicyValues.Count -ne 1) {
    throw "R26 monitoring carrier contains more than one policy SHA."
}

if ($PolicyValues[0] -ne $ExpectedPolicySha) {
    throw "R26 policy SHA mismatch."
}

Write-Host ""
Write-Host "R26 CARRIER VALIDATION: PASS"
Write-Host "Carrier root: $CarrierRoot"
Write-Host "Rows:         $MonitoringCount"
Write-Host "Columns:      $ColumnCount"
Write-Host "Policy SHA:   $($PolicyValues[0])"
```

Once that ends with:

```text
R26 CARRIER VALIDATION: PASS
```

the source side is ready. The next controlled step is opening the R26 PBIP and performing **Refresh All**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0b059880-6a5a-4a7b-bace-27d0ab3028e0"></a>
## Andrew / user · C109-M00604

C109-M00604 · 2026-09-02T08:24:05.874000-04:00 · active path

Preceding visible parent: [C109-M00603](part-28.md#m-ea961c39-b351-40a6-b999-a965df7808a8)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\MSBF\R26_R3_RESUME> Set-StrictMode -Version Latest
>> $ErrorActionPreference = "Stop"
>> $ProgressPreference = "SilentlyContinue"
PS C:\MSBF\R26_R3_RESUME> $DeliveryRoot = "C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY"
>> $HandoffZip   = "C:\MSBF\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip"
>> $CarrierRoot  = "C:\MSBF\R26\power_bi\carrier"
PS C:\MSBF\R26_R3_RESUME> Set-Location $DeliveryRoot
PS C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY> Get-Location

Path
----
C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY

PS C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY> $Checks = [ordered]@{
>>     "Delivery root" = Test-Path $DeliveryRoot
>>     "R26 handoff ZIP" = Test-Path $HandoffZip
>>     "Preparation script" = Test-Path "$DeliveryRoot\scripts\00_PREPARE_R26_CARRIER.ps1"
>>     "R26 Desktop DAX checks" = Test-Path "$DeliveryRoot\tests\R26_DESKTOP_CHECKPOINTS.dax"
>>     "Project folder" = Test-Path "$DeliveryRoot\project"
>> }
>>
>> $Checks.GetEnumerator() | Format-Table -AutoSize

Name                   Value
----                   -----
Delivery root          True
R26 handoff ZIP        True
Preparation script     True
R26 Desktop DAX checks True
Project folder         True

PS C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY> $ExpectedHandoffSha = "53fd448b61b15b1e61ebd34e778cb00364169145c541467ea2a453cd1a9ec467"
>>
>> $ActualHandoffSha = (Get-FileHash -Algorithm SHA256 $HandoffZip).Hash.ToLower()
>>
>> [pscustomobject]@{
>>     File     = $HandoffZip
>>     Expected = $ExpectedHandoffSha
>>     Actual   = $ActualHandoffSha
>>     Match    = ($ActualHandoffSha -eq $ExpectedHandoffSha)
>> } | Format-List

File     : C:\MSBF\MSBF_POWER_BI_R26_PARALLEL_HANDOFF_20260902.zip
Expected : 53fd448b61b15b1e61ebd34e778cb00364169145c541467ea2a453cd1a9ec467
Actual   : 53fd448b61b15b1e61ebd34e778cb00364169145c541467ea2a453cd1a9ec467
Match    : True

PS C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY> powershell.exe -NoProfile -ExecutionPolicy Bypass `
>>     -File "$DeliveryRoot\scripts\00_PREPARE_R26_CARRIER.ps1" `
>>     -HandoffZip "$HandoffZip" `
>>     -CarrierRoot "$CarrierRoot"
R26 policy identity mismatch
At C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\scripts\00_PREPARE_R26_CARRIER.ps1:28 char:73
+ ... y[0] -ne $ExpectedPolicySha) { throw "R26 policy identity mismatch" }
+                                    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (R26 policy identity mismatch:String) [], RuntimeException
    + FullyQualifiedErrorId : R26 policy identity mismatch
<!-- END_SOURCE_MESSAGE -->


<a id="m-35d32fad-9336-4bd9-a1b1-02bc8488c1ec"></a>
## Assistant · C109-M00605

C109-M00605 · 2026-09-02T08:25:06.977827-04:00 · active path

Preceding visible parent: [C109-M00604](part-28.md#m-0b059880-6a5a-4a7b-bace-27d0ab3028e0)

<!-- BEGIN_SOURCE_MESSAGE -->
This is **a bug in my PowerShell verification script, not an R26 source/carrier contradiction**.

The handoff ZIP hash matched exactly before the script ran, and the script had already passed the catalog SHA and monitoring-file SHA checks before it reached the failing policy test. The package receipt independently reports the handoff as `PASS`, clean-extraction `PASS`, with the expected R26 result identity and candidate-only authority. [export reference: filecite | turn99file0 | L2-L15]

The problem is this PowerShell behavior:

```powershell
$Policy = Import-Csv ... | Select-Object -ExpandProperty r26_policy_sha256 -Unique
```

When there is exactly **one** unique policy SHA, PowerShell stores `$Policy` as a scalar string, not an array. Then:

```powershell
$Policy[0]
```

returns the **first character of the SHA** (`"6"`), not the whole SHA string. So the script falsely throws `R26 policy identity mismatch`.

I independently inspected the actual handoff carrier. It contains exactly one policy value:

```text
6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027
```

which is the expected R26 policy.

## First: verify the carrier that was already installed

The script copied the carrier before that final faulty check, and its `finally` block removes only the temporary extraction folder—not `C:\MSBF\R26\power_bi\carrier`.

Run this now in your existing PowerShell session:

```powershell
$MonitoringFile = "C:\MSBF\R26\power_bi\carrier\curated\R1FactDailyMonitoring.csv"

Test-Path $MonitoringFile

$Policy = @(
    Import-Csv $MonitoringFile |
    Select-Object -ExpandProperty r26_policy_sha256 -Unique
)

$Policy

Write-Host "Unique policy count:" $Policy.Count
Write-Host "Exact policy match:" (
    $Policy.Count -eq 1 -and
    ([string]$Policy[0]).Trim().ToLowerInvariant() -eq
    "6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027"
)
```

Expected:

```text
True

6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027

Unique policy count: 1
Exact policy match: True
```

Then run these two hash checks:

```powershell
(Get-FileHash -Algorithm SHA256 `
    "C:\MSBF\R26\power_bi\carrier\SUCCESSOR_DATA_CATALOG.csv").Hash.ToLower()

(Get-FileHash -Algorithm SHA256 `
    "C:\MSBF\R26\power_bi\carrier\curated\R1FactDailyMonitoring.csv").Hash.ToLower()
```

Expected:

```text
c21530bc668e9559e9194dcaa21d612935420434a1c54ac8220f7f91b9733c6b

900dec0ad182b696d426295c2f9825a5e6d29d270d5ef95605b85719e474ba59
```

If all of those match, **the carrier currently on your drive is good** and you do not actually need to recopy it.

## Corrected preparation script

I also corrected the script so this cannot recur:

Download corrected R26 carrier-preparation script (historical reference: `sandbox:[session]/00_PREPARE_R26_CARRIER_CORRECTED.ps1`; referenced bytes not established here)

The critical fix is:

```powershell
$Policy = @(
    Import-Csv (Join-Path $CarrierRoot "curated\R1FactDailyMonitoring.csv") |
    Select-Object -ExpandProperty r26_policy_sha256 -Unique
)

$PolicyValue =
    if ($Policy.Count -eq 1) {
        ([string]$Policy[0]).Trim().ToLowerInvariant()
    }
    else {
        ""
    }

if (
    $Policy.Count -ne 1 -or
    $PolicyValue -ne $ExpectedPolicySha
) {
    throw "R26 policy identity mismatch: count=$($Policy.Count); observed=[$PolicyValue]; expected=[$ExpectedPolicySha]"
}
```

### You have two valid paths now

**Fastest path:** run the verification commands above. If they all pass, proceed to opening the R26 PBIP and Refresh All.

**Clean audit path:** replace:

```text
C:\MSBF\PowerBI\R26_Parallel\
MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\
scripts\00_PREPARE_R26_CARRIER.ps1
```

with the corrected script, then rerun:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File "$DeliveryRoot\scripts\00_PREPARE_R26_CARRIER.ps1" `
    -HandoffZip "$HandoffZip" `
    -CarrierRoot "$CarrierRoot"
```

I prefer the **clean audit path**, because then your execution transcript ends with the script itself reporting:

```text
R26 carrier prepared and verified: C:\MSBF\R26\power_bi\carrier
```

rather than relying on a manual follow-up to compensate for the script defect.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e710781d-ee10-4df5-a0ee-0b3164b6c62b"></a>
## Andrew / user · C109-M00606

C109-M00606 · 2026-09-02T08:28:31.631000-04:00 · active path

Preceding visible parent: [C109-M00605](part-28.md#m-35d32fad-9336-4bd9-a1b1-02bc8488c1ec)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY> $MonitoringFile = "C:\MSBF\R26\power_bi\carrier\curated\R1FactDailyMonitoring.csv" 
>> 
>> Test-Path $MonitoringFile 
>> 
>> $Policy = @( 
>>     Import-Csv $MonitoringFile | 
>>     Select-Object -ExpandProperty r26_policy_sha256 -Unique 
>> ) 
>> 
>> $Policy 
>> 
>> Write-Host "Unique policy count:" $Policy.Count 
>> Write-Host "Exact policy match:" ( 
>>     $Policy.Count -eq 1 -and 
>>     ([string]$Policy[0]).Trim().ToLowerInvariant() -eq 
>>     "6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027" 
>> ) 
True 
6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027 
Unique policy count: 1 
Exact policy match: True 
PS C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY> (Get-FileHash -Algorithm SHA256 ` 
>>     "C:\MSBF\R26\power_bi\carrier\SUCCESSOR_DATA_CATALOG.csv").Hash.ToLower() 
>> 
>> (Get-FileHash -Algorithm SHA256 ` 
>>     "C:\MSBF\R26\power_bi\carrier\curated\R1FactDailyMonitoring.csv").Hash.ToLower() 
c21530bc668e9559e9194dcaa21d612935420434a1c54ac8220f7f91b9733c6b 
900dec0ad182b696d426295c2f9825a5e6d29d270d5ef95605b85719e474ba59            record this and let's move on.
<!-- END_SOURCE_MESSAGE -->


<a id="m-90f2758d-bb9a-4912-8161-4ba4891bc11c"></a>
## Assistant · C109-M00607

C109-M00607 · 2026-09-02T08:28:35.510441-04:00 · active path

Preceding visible parent: [C109-M00606](part-28.md#m-e710781d-ee10-4df5-a0ee-0b3164b6c62b)

<!-- BEGIN_SOURCE_MESSAGE -->
Recorded. The carrier-preparation checkpoint is now **PASS by independent local verification**, and the earlier script failure is classified as a verification-script defect only.

```text
R26 CARRIER PREPARATION — PASS

Carrier root
C:\MSBF\R26\power_bi\carrier

R1FactDailyMonitoring present
TRUE

Unique R26 policy SHA count
1

Exact policy SHA
6c6a6f8103bb7276c5d1063d900d96070903e82b5f7143431bc150556e092027
PASS

SUCCESSOR_DATA_CATALOG.csv SHA-256
c21530bc668e9559e9194dcaa21d612935420434a1c54ac8220f7f91b9733c6b
PASS

R1FactDailyMonitoring.csv SHA-256
900dec0ad182b696d426295c2f9825a5e6d29d270d5ef95605b85719e474ba59
PASS

Earlier preparation-script result
FALSE FAIL caused by PowerShell scalar-array handling
No source contradiction established
```

The outer R26 handoff had already independently matched its expected SHA and reported clean-extraction `PASS`, so the source side is sufficiently controlled to proceed. [export reference: filecite | turn99file0 | L2-L15]

## Next: open the new R26 Power BI project

Keep your old pre-R26 refinement closed. In the same PowerShell window, run:

```powershell
$DeliveryRoot = "C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY"

Get-ChildItem "$DeliveryRoot\project" -Recurse -Filter definition.pbir |
    Select-Object FullName
```

We want the `definition.pbir` underneath the **R26 Report** folder.

Then use:

```powershell
$R26Pbir = (
    Get-ChildItem "$DeliveryRoot\project" -Recurse -Filter definition.pbir |
    Where-Object { $_.FullName -match "Report" } |
    Select-Object -First 1
).FullName

Write-Host "Opening:"
Write-Host $R26Pbir

Start-Process $R26Pbir
```

### Once Power BI opens

Before doing anything else, confirm it is the new branch and not yesterday's project. Then:

1. **Home → Refresh**
2. Let the entire refresh finish.
3. **Do not start modifying visuals yet.**
4. If any query fails, send me the **exact query name + full error text**.

If refresh completes cleanly, our next operation is the supplied:

```text
tests\R26_DESKTOP_CHECKPOINTS.dax
```

That will be our first physical-model verification before we inspect P02.
<!-- END_SOURCE_MESSAGE -->


<a id="m-66a8df2b-d864-47a4-a458-6866c820044d"></a>
## Andrew / user · C109-M00608

C109-M00608 · 2026-09-02T08:30:27.330000-04:00 · active path

Preceding visible parent: [C109-M00607](part-28.md#m-90f2758d-bb9a-4912-8161-4ba4891bc11c)

<!-- BEGIN_SOURCE_MESSAGE -->
I also updated C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\scripts\00_PREPARE_R26_CARRIER.ps1   for documentation purposes.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ae6c4a1b-dae9-497a-bbac-1968db988972"></a>
## Assistant · C109-M00609

C109-M00609 · 2026-09-02T08:30:30.704078-04:00 · active path

Preceding visible parent: [C109-M00608](part-28.md#m-66a8df2b-d864-47a4-a458-6866c820044d)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. Record that as part of the controlled evidence trail:

```text
DOCUMENTATION UPDATE — COMPLETE

Corrected script retained at:
C:\MSBF\PowerBI\R26_Parallel\
MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\
scripts\00_PREPARE_R26_CARRIER.ps1

Purpose:
Preserve the corrected scalar-safe R26 policy identity verification in the delivery package.

Status:
Documentation/control improvement only.
No carrier/source facts changed.
No Power BI model/report logic changed.
```

That is the right thing to do because it prevents the delivery package from retaining a known false-fail condition in its own preparation script.

We can move on to the **physical Power BI refresh and R26 Desktop checkpoint** now.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f3ca8dc8-2600-4fd3-bf4a-f843f790ce25"></a>
## Andrew / user · C109-M00610

C109-M00610 · 2026-09-02T08:41:17.071000-04:00 · active path

Preceding visible parent: [C109-M00609](part-28.md#m-ae6c4a1b-dae9-497a-bbac-1968db988972)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 347aff39-414f-40c6-93ce-c7be3dfbe6b8.png

<!-- BEGIN_SOURCE_MESSAGE -->
looks like we may have an issue. please advise.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d79f328d-6d39-4a08-9414-1ae2fa1912dd"></a>
## Assistant · C109-M00611

C109-M00611 · 2026-09-02T08:43:04.324409-04:00 · active path

Preceding visible parent: [C109-M00610](part-28.md#m-f3ca8dc8-2600-4fd3-bf4a-f843f790ce25)

<!-- BEGIN_SOURCE_MESSAGE -->
This looks like a **single local source-mount problem**, not 24 separate query defects and not an R26 carrier failure.

The affected queries shown—`DimDate`, `DimAsOfDate`, `DimRunCampaign`, `DimScenario`, `DimMerchant`, etc.—are part of the **pre-existing core Power BI model**. That model still reads its base synthetic source through:

```text
pDataRoot  = \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
pBuildRoot = \\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

That UNC share was intentionally mapped to the isolated local synthetic root:

```text
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root
```

with separate `pbi` and `build` subdirectories. [export reference: filecite | turn100file10 | L777-L802]

R26 added a **separate** successor source root at `C:\MSBF\R26\power_bi\carrier`; it did not replace the core model's old source. So do **not** repoint `pDataRoot` to the R26 carrier.

The message **“The network name cannot be found”** strongly indicates that the local SMB share `MSBF_PBI_A1B_SYNTHETIC` is no longer registered/available. The accepted model historically depended on that exact share. [export reference: filecite | turn100file4 | L302-L312]

### First: click Cancel

On the Power BI error window, click **Cancel**. Do not edit any Power Query yet.

Then run this **read-only diagnostic** in your existing PowerShell window:

```powershell
$SyntheticRoot = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"
$ShareName     = "MSBF_PBI_A1B_SYNTHETIC"
$UncRoot       = "\\localhost\$ShareName"

Write-Host "===== PHYSICAL SOURCE ====="
Write-Host "Synthetic root exists:" (Test-Path $SyntheticRoot)
Write-Host "PBI folder exists:     " (Test-Path "$SyntheticRoot\pbi")
Write-Host "Build folder exists:   " (Test-Path "$SyntheticRoot\build")
Write-Host "Core catalog exists:   " (Test-Path "$SyntheticRoot\pbi\data\POWER_BI_DATA_CATALOG.csv")

Write-Host ""
Write-Host "===== SMB SHARE ====="

$Share = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue

if ($null -eq $Share) {
    Write-Host "SMB share exists:       False"
}
else {
    Write-Host "SMB share exists:       True"
    Write-Host "SMB share path:         " $Share.Path
}

Write-Host ""
Write-Host "===== UNC ACCESS ====="
Write-Host "UNC root reachable:     " (Test-Path $UncRoot)
Write-Host "UNC PBI reachable:      " (Test-Path "$UncRoot\pbi")
Write-Host "UNC Build reachable:    " (Test-Path "$UncRoot\build")
Write-Host "UNC catalog reachable:  " (Test-Path "$UncRoot\pbi\data\POWER_BI_DATA_CATALOG.csv")
```

### What I expect

Most likely you'll get something like:

```text
Synthetic root exists: True
PBI folder exists:      True
Build folder exists:    True
Core catalog exists:    True

SMB share exists:       False

UNC root reachable:     False
UNC PBI reachable:      False
UNC Build reachable:    False
UNC catalog reachable:  False
```

If so, this is straightforward: **the underlying files are still there; only the local SMB share disappeared.**

### If the physical folders are TRUE but SMB share is FALSE

Close Power BI Desktop first.

Then open **PowerShell as Administrator** and run this exact block:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SyntheticRoot = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"
$ShareName     = "MSBF_PBI_A1B_SYNTHETIC"
$Identity      = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

if (-not (Test-Path "$SyntheticRoot\pbi\data\POWER_BI_DATA_CATALOG.csv")) {
    throw "STOP: governing PBI source catalog is missing from the synthetic root."
}

if (-not (Test-Path "$SyntheticRoot\build")) {
    throw "STOP: build root is missing from the synthetic root."
}

$ExistingShare = Get-SmbShare -Name $ShareName -ErrorAction SilentlyContinue

if ($null -ne $ExistingShare) {
    if ($ExistingShare.Path -ne $SyntheticRoot) {
        throw "STOP: share already exists but points to [$($ExistingShare.Path)] instead of [$SyntheticRoot]."
    }

    Write-Host "Existing share already points to the correct root."
}
else {
    New-SmbShare `
        -Name $ShareName `
        -Path $SyntheticRoot `
        -ReadAccess $Identity `
        -CachingMode None |
        Out-Null

    Write-Host "Created read-only local SMB share for:" $Identity
}

Write-Host ""
Write-Host "===== SHARE IDENTITY ====="
Get-SmbShare -Name $ShareName |
    Select-Object Name, Path, Description |
    Format-List

Write-Host "===== SHARE ACCESS ====="
Get-SmbShareAccess -Name $ShareName |
    Format-Table AccountName, AccessControlType, AccessRight -AutoSize

Write-Host "===== UNC VALIDATION ====="
Write-Host "UNC root:   " (Test-Path "\\localhost\$ShareName")
Write-Host "UNC PBI:    " (Test-Path "\\localhost\$ShareName\pbi")
Write-Host "UNC Build:  " (Test-Path "\\localhost\$ShareName\build")
Write-Host "UNC Catalog:" (Test-Path "\\localhost\$ShareName\pbi\data\POWER_BI_DATA_CATALOG.csv")
```

The important final result is:

```text
UNC root:    True
UNC PBI:     True
UNC Build:   True
UNC Catalog: True
```

The historic controlled source environment specifically used read access for the executing user rather than broad share access. [export reference: filecite | turn100file4 | L302-L310]

### Then reopen R26 Power BI

Once all four UNC checks are `True`:

1. Reopen the **R26 parallel refinement** project.
2. Do not change any parameters.
3. Run **Home → Refresh** again.

At that point Power BI will have both source families available:

```text
CORE / PREDECESSOR MODEL
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
\\localhost\MSBF_PBI_A1B_SYNTHETIC\build

R26 SUCCESSOR CARRIER
C:\MSBF\R26\power_bi\carrier
```

That is the intended architecture.

### One condition where we should stop

If your first diagnostic instead says:

```text
Synthetic root exists: False
```

or the root exists but:

```text
Core catalog exists: False
```

**do not create a new empty share and do not modify Power BI.** That would mean the underlying accepted A1b synthetic source itself is missing, and we should restore the exact source carrier rather than fabricate a replacement path.

Run the first diagnostic block and paste the output here. I expect we can resolve this without modifying any of yesterday's Power BI work.
<!-- END_SOURCE_MESSAGE -->


<a id="m-265da0e8-c6cf-48c8-a63f-d2a53e8d505a"></a>
## Andrew / user · C109-M00612

C109-M00612 · 2026-09-02T08:45:37.141000-04:00 · active path

Preceding visible parent: [C109-M00611](part-28.md#m-d79f328d-6d39-4a08-9414-1ae2fa1912dd)

<!-- BEGIN_SOURCE_MESSAGE -->
===== PHYSICAL SOURCE =====
Synthetic root exists: False
PBI folder exists:      False
Build folder exists:    False
Core catalog exists:    False

===== SMB SHARE =====
SMB share exists:       False

===== UNC ACCESS =====
UNC root reachable:      False
UNC PBI reachable:       False
UNC Build reachable:     False
UNC catalog reachable:   False
<!-- END_SOURCE_MESSAGE -->


<a id="m-40d0ee9d-d779-4176-a5e3-4af1d9a086d5"></a>
## Assistant · C109-M00613

C109-M00613 · 2026-09-02T08:46:57.679313-04:00 · active path

Preceding visible parent: [C109-M00612](part-28.md#m-265da0e8-c6cf-48c8-a63f-d2a53e8d505a)

<!-- BEGIN_SOURCE_MESSAGE -->
This confirms the issue is **not R26 and not the Power BI model**. The accepted legacy/core synthetic source tree itself is no longer on this machine at the path the model expects.

We should restore the **exact accepted source**, not repoint Power BI or create replacement files. The best restoration authority is the later accepted **A1b Focused R2 carrier**, not the earlier failed R1 candidate. Independent Audit made Focused R2 the controlling A1b local-engine authority, and specifically confirmed that all **222 synthetic-root files were unchanged** from the accepted source. [export reference: filecite | turn103file1 | L61-L68] [export reference: filecite | turn103file1 | L88-L96]

Its exact package identity is:

```text
MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip

Bytes:
34,813,542

SHA-256:
8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02

ZIP members:
441
```

That carrier passed archive validation and contains the `synthetic_root` we need. [export reference: filecite | turn103file6 | L527-L568]

## First, keep Power BI closed

Cancel/close the failed R26 Power BI session. Do **not save changes caused by this failed refresh** if Desktop asks whether to save.

We want the project untouched while we restore its source dependency.

## Step 1 — find the accepted Focused R2 carrier on your PC

Open PowerShell and run:

```powershell
$TargetName = "MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip"

$SearchRoots = @(
    "C:\MSBF",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents"
)

$Found = foreach ($Root in $SearchRoots) {
    if (Test-Path -LiteralPath $Root) {
        Get-ChildItem `
            -LiteralPath $Root `
            -File `
            -Recurse `
            -Filter $TargetName `
            -ErrorAction SilentlyContinue
    }
}

$Found |
    Select-Object FullName, Length, LastWriteTime |
    Format-Table -AutoSize
```

### Ideal result

Something like:

```text
FullName
--------
C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip
```

If that exact ZIP is found, verify it immediately:

```powershell
$ExpectedSha =
    "8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02"

$CarrierZip = $Found[0].FullName

$ActualSha = (
    Get-FileHash `
        -LiteralPath $CarrierZip `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    File     = $CarrierZip
    Bytes    = (Get-Item -LiteralPath $CarrierZip).Length
    Expected = $ExpectedSha
    Actual   = $ActualSha
    Match    = ($ActualSha -eq $ExpectedSha)
} | Format-List
```

We require:

```text
Bytes : 34813542
Match : True
```

Do **not extract it yet if the hash does not match**.

---

# If the accepted carrier is found and matches

Then we can restore the dependency in one controlled action.

The original accepted architecture was:

```text
UNC:
\\localhost\MSBF_PBI_A1B_SYNTHETIC

Physical:
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root

Children:
pbi
build
```

That mapping and those exact parameter roots were part of the accepted A1b environment. [export reference: filecite | turn101file12 | L624-L649]

## Step 2 — extract and verify the accepted synthetic root

Use an **Administrator PowerShell** for this complete block:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$CarrierZip = "PUT_THE_EXACT_FOUND_ZIP_PATH_HERE"

$ExpectedCarrierSha =
    "8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02"

$RestoreParent =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$RestoreRoot =
    "$RestoreParent\synthetic_root"

$TempRoot =
    "C:\MSBF\_A1B_FOCUSED_R2_SOURCE_RESTORE_TEMP_20260902"

$ShareName =
    "MSBF_PBI_A1B_SYNTHETIC"

# ------------------------------------------------------------
# 1. Verify sealed accepted carrier.
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $CarrierZip)) {
    throw "STOP: accepted Focused R2 carrier ZIP not found."
}

$ActualCarrierSha = (
    Get-FileHash `
        -LiteralPath $CarrierZip `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

if ($ActualCarrierSha -ne $ExpectedCarrierSha) {
    throw "STOP: Focused R2 carrier SHA-256 mismatch."
}

if ((Get-Item -LiteralPath $CarrierZip).Length -ne 34813542) {
    throw "STOP: Focused R2 carrier byte-size mismatch."
}

Write-Host "Accepted Focused R2 carrier identity: PASS"

# ------------------------------------------------------------
# 2. Fail closed if restoration target unexpectedly exists.
# ------------------------------------------------------------

if (Test-Path -LiteralPath $RestoreRoot) {
    throw "STOP: restoration target already exists. Do not overwrite it."
}

if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item `
        -LiteralPath $TempRoot `
        -Recurse `
        -Force
}

New-Item `
    -ItemType Directory `
    -Path $TempRoot `
    -Force |
    Out-Null

# ------------------------------------------------------------
# 3. Extract accepted carrier to temporary location.
# ------------------------------------------------------------

Expand-Archive `
    -LiteralPath $CarrierZip `
    -DestinationPath $TempRoot `
    -Force

$ExtractedSyntheticRoot =
    Join-Path $TempRoot "synthetic_root"

if (-not (Test-Path -LiteralPath $ExtractedSyntheticRoot)) {
    throw "STOP: synthetic_root not found in accepted carrier."
}

if (-not (Test-Path -LiteralPath "$ExtractedSyntheticRoot\pbi")) {
    throw "STOP: accepted synthetic_root\pbi missing."
}

if (-not (Test-Path -LiteralPath "$ExtractedSyntheticRoot\build")) {
    throw "STOP: accepted synthetic_root\build missing."
}

# ------------------------------------------------------------
# 4. Verify exact source population count.
# ------------------------------------------------------------

$SourceFiles = @(
    Get-ChildItem `
        -LiteralPath $ExtractedSyntheticRoot `
        -File `
        -Recurse `
        -Force
)

Write-Host "Synthetic-root file count:" $SourceFiles.Count

if ($SourceFiles.Count -ne 222) {
    throw "STOP: expected exactly 222 synthetic-root files."
}

# ------------------------------------------------------------
# 5. Locate and enforce the supplied synthetic-root manifest.
# ------------------------------------------------------------

$ManifestFile = @(
    Get-ChildItem `
        -LiteralPath $TempRoot `
        -File `
        -Recurse `
        -Force |
    Where-Object {
        $_.Name -eq "synthetic_root_MANIFEST_SHA256.csv"
    }
)

if ($ManifestFile.Count -ne 1) {
    throw "STOP: expected exactly one synthetic-root SHA-256 manifest."
}

$ManifestRows = @(
    Import-Csv -LiteralPath $ManifestFile[0].FullName
)

Write-Host "Synthetic-root manifest rows:" $ManifestRows.Count

if ($ManifestRows.Count -ne 222) {
    throw "STOP: synthetic-root manifest does not contain 222 rows."
}

$ManifestFailures = @()

foreach ($Row in $ManifestRows) {

    $FilePath =
        Join-Path $ExtractedSyntheticRoot $Row.relative_path

    if (-not (Test-Path -LiteralPath $FilePath)) {
        $ManifestFailures +=
            "MISSING: $($Row.relative_path)"
        continue
    }

    $File = Get-Item -LiteralPath $FilePath

    if ([int64]$Row.bytes -ne $File.Length) {
        $ManifestFailures +=
            "BYTE_MISMATCH: $($Row.relative_path)"
        continue
    }

    $ActualHash = (
        Get-FileHash `
            -LiteralPath $FilePath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    if ($ActualHash -ne $Row.sha256.ToLowerInvariant()) {
        $ManifestFailures +=
            "HASH_MISMATCH: $($Row.relative_path)"
    }
}

if ($ManifestFailures.Count -gt 0) {
    $ManifestFailures | Format-Table
    throw "STOP: accepted synthetic-root manifest verification failed."
}

Write-Host "Synthetic-root manifest verification: PASS"

# ------------------------------------------------------------
# 6. Restore exact accepted physical source tree.
# ------------------------------------------------------------

New-Item `
    -ItemType Directory `
    -Path $RestoreParent `
    -Force |
    Out-Null

Copy-Item `
    -LiteralPath $ExtractedSyntheticRoot `
    -Destination $RestoreParent `
    -Recurse

$RestoredFiles = @(
    Get-ChildItem `
        -LiteralPath $RestoreRoot `
        -File `
        -Recurse `
        -Force
)

if ($RestoredFiles.Count -ne 222) {
    throw "STOP: restored source does not contain exactly 222 files."
}

Write-Host "Accepted physical synthetic source restored: PASS"

# ------------------------------------------------------------
# 7. Restore exact local SMB share.
# ------------------------------------------------------------

$ExistingShare =
    Get-SmbShare `
        -Name $ShareName `
        -ErrorAction SilentlyContinue

if ($null -ne $ExistingShare) {
    if ($ExistingShare.Path -ne $RestoreRoot) {
        throw "STOP: existing SMB share points to an unexpected path."
    }
}
else {

    $Identity =
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    New-SmbShare `
        -Name $ShareName `
        -Path $RestoreRoot `
        -ReadAccess $Identity `
        -CachingMode None |
        Out-Null
}

# ------------------------------------------------------------
# 8. Final physical / UNC validation.
# ------------------------------------------------------------

Write-Host ""
Write-Host "===== RESTORED SOURCE ====="

Write-Host "Physical root:" `
    (Test-Path $RestoreRoot)

Write-Host "Physical PBI:" `
    (Test-Path "$RestoreRoot\pbi")

Write-Host "Physical build:" `
    (Test-Path "$RestoreRoot\build")

Write-Host "File count:" `
    @(Get-ChildItem $RestoreRoot -File -Recurse).Count

Write-Host ""
Write-Host "===== SMB SHARE ====="

Get-SmbShare -Name $ShareName |
    Select-Object Name,Path |
    Format-List

Get-SmbShareAccess -Name $ShareName |
    Format-Table `
        AccountName,
        AccessControlType,
        AccessRight `
        -AutoSize

Write-Host ""
Write-Host "===== UNC ACCESS ====="

Write-Host "UNC root:" `
    (Test-Path "\\localhost\$ShareName")

Write-Host "UNC PBI:" `
    (Test-Path "\\localhost\$ShareName\pbi")

Write-Host "UNC build:" `
    (Test-Path "\\localhost\$ShareName\build")

Write-Host ""
Write-Host "A1B ACCEPTED SOURCE RESTORE: PASS"
```

### One thing to change before running it

Replace:

```powershell
$CarrierZip = "PUT_THE_EXACT_FOUND_ZIP_PATH_HERE"
```

with the path returned by Step 1.

---

## Why this is preferable to changing the R26 model

The current R26 carrier is indeed a **complete R20-derived successor carrier**, but it contains the R4/R1 successor objects—not the older core `DimDate`, `DimMerchant`, `DimScenario`, etc. The R26 handoff says only the R26 monitoring object, six M2.11/M2.12 objects and candidate authority metadata are rebased; the remainder of that carrier is the R20-derived successor population. It does not replace the A1b core synthetic source.

And the accepted Focused R2 authority explicitly states that the source carrier, both source-root parameters, and all 222 synthetic-root files remained unchanged. [export reference: filecite | turn103file5 | L420-L448]

So our intended architecture remains:

```text
CORE POWER BI MODEL
        ↓
\\localhost\MSBF_PBI_A1B_SYNTHETIC
        ↓
accepted 222-file A1b synthetic_root


R1/R26 SUCCESSOR MODEL
        ↓
C:\MSBF\R26\power_bi\carrier
        ↓
R4 + R17/R26 + M2.11/M2.12 successor facts
```

We should restore the first leg rather than collapse the two source boundaries.

### For now

Run **Step 1 only** first—the ZIP search—and paste the result.

If the exact Focused R2 ZIP is present and its SHA matches, recovery should be straightforward and should require **zero Power BI semantic or visual rework**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b16c7ae9-4130-49c5-828a-41991f761377"></a>
## Andrew / user · C109-M00614

C109-M00614 · 2026-09-02T08:50:25.752000-04:00 · active path

Preceding visible parent: [C109-M00613](part-28.md#m-40d0ee9d-d779-4176-a5e3-4af1d9a086d5)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: f4a18100-f62f-46df-8e7b-a4fdd0136df7.png

<!-- BEGIN_SOURCE_MESSAGE -->
it is here: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-a905de47-8dab-486d-bc7c-0ea53b203c66"></a>
## Assistant · C109-M00615

C109-M00615 · 2026-09-02T08:50:29.252507-04:00 · active path

Preceding visible parent: [C109-M00614](part-28.md#m-b16c7ae9-4130-49c5-828a-41991f761377)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that is the exact carrier we need. Windows Explorer is hiding the `.zip` extension, but your screenshot shows both the ZIP and its SHA sidecar in `C:\MSBF`.

The accepted Focused R2 carrier should be exactly **34,813,542 bytes**, SHA-256 `8dddea7d...44b02`, with 441 members. [export reference: filecite | turn103file9 | L792-L801]

### 1. Verify the exact local ZIP first

Keep Power BI closed. In PowerShell run:

```powershell
$CarrierZip = "C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip"

Test-Path $CarrierZip

$CarrierFile = Get-Item -LiteralPath $CarrierZip
$CarrierHash = (
    Get-FileHash -LiteralPath $CarrierZip -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    Path          = $CarrierFile.FullName
    Bytes         = $CarrierFile.Length
    ExpectedBytes = 34813542
    ByteMatch     = ($CarrierFile.Length -eq 34813542)
    SHA256        = $CarrierHash
    ExpectedSHA   = "8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02"
    HashMatch     = (
        $CarrierHash -eq
        "8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02"
    )
} | Format-List
```

We require:

```text
True

Bytes         : 34813542
ByteMatch     : True
HashMatch     : True
```

If those pass, proceed.

## 2. Restore the accepted 222-file source

For this next block, open **PowerShell as Administrator**.

This version is slightly improved from my prior script: it does **not** assume the ZIP has no outer package directory. It discovers the one exact `synthetic_root` inside the accepted package.

Copy/paste the entire block:

```powershell
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$CarrierZip =
    "C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip"

$ExpectedCarrierSha =
    "8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02"

$ExpectedCarrierBytes = 34813542

$RestoreParent =
    "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$RestoreRoot =
    Join-Path $RestoreParent "synthetic_root"

$TempRoot =
    "C:\MSBF\_A1B_FOCUSED_R2_SOURCE_RESTORE_TEMP_20260902"

$ShareName =
    "MSBF_PBI_A1B_SYNTHETIC"

Write-Host "===== 1. VERIFY ACCEPTED CARRIER ====="

if (-not (Test-Path -LiteralPath $CarrierZip)) {
    throw "STOP: Focused R2 carrier ZIP not found."
}

$CarrierItem = Get-Item -LiteralPath $CarrierZip

if ($CarrierItem.Length -ne $ExpectedCarrierBytes) {
    throw "STOP: Focused R2 carrier byte-size mismatch."
}

$ActualCarrierSha = (
    Get-FileHash `
        -LiteralPath $CarrierZip `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

if ($ActualCarrierSha -ne $ExpectedCarrierSha) {
    throw "STOP: Focused R2 carrier SHA-256 mismatch."
}

Write-Host "Accepted Focused R2 carrier: PASS"


Write-Host ""
Write-Host "===== 2. PREPARE TEMP EXTRACTION ====="

if (Test-Path -LiteralPath $RestoreRoot) {
    throw "STOP: restoration target already exists. Review before overwriting."
}

if (Test-Path -LiteralPath $TempRoot) {
    Remove-Item `
        -LiteralPath $TempRoot `
        -Recurse `
        -Force
}

New-Item `
    -ItemType Directory `
    -Path $TempRoot `
    -Force |
    Out-Null

Expand-Archive `
    -LiteralPath $CarrierZip `
    -DestinationPath $TempRoot `
    -Force

Write-Host "Carrier extracted."


Write-Host ""
Write-Host "===== 3. LOCATE ACCEPTED SYNTHETIC ROOT ====="

$SyntheticRoots = @(
    Get-ChildItem `
        -LiteralPath $TempRoot `
        -Directory `
        -Recurse `
        -Force |
    Where-Object {
        $_.Name -eq "synthetic_root" -and
        (Test-Path -LiteralPath (Join-Path $_.FullName "pbi")) -and
        (Test-Path -LiteralPath (Join-Path $_.FullName "build"))
    }
)

if ($SyntheticRoots.Count -ne 1) {
    throw "STOP: expected exactly one valid synthetic_root; found $($SyntheticRoots.Count)."
}

$ExtractedSyntheticRoot = $SyntheticRoots[0].FullName

Write-Host "Synthetic root:"
Write-Host $ExtractedSyntheticRoot


Write-Host ""
Write-Host "===== 4. VERIFY 222-FILE SOURCE POPULATION ====="

$SourceFiles = @(
    Get-ChildItem `
        -LiteralPath $ExtractedSyntheticRoot `
        -File `
        -Recurse `
        -Force
)

Write-Host "Synthetic-root files:" $SourceFiles.Count

if ($SourceFiles.Count -ne 222) {
    throw "STOP: expected exactly 222 synthetic-root files."
}


Write-Host ""
Write-Host "===== 5. LOCATE AND VERIFY SOURCE MANIFEST ====="

$ManifestFiles = @(
    Get-ChildItem `
        -LiteralPath $TempRoot `
        -File `
        -Recurse `
        -Force |
    Where-Object {
        $_.Name -eq "synthetic_root_MANIFEST_SHA256.csv"
    }
)

if ($ManifestFiles.Count -ne 1) {
    throw "STOP: expected exactly one synthetic_root_MANIFEST_SHA256.csv; found $($ManifestFiles.Count)."
}

$ManifestPath = $ManifestFiles[0].FullName
$ManifestRows = @(Import-Csv -LiteralPath $ManifestPath)

Write-Host "Manifest rows:" $ManifestRows.Count

if ($ManifestRows.Count -ne 222) {
    throw "STOP: expected 222 manifest rows."
}

$ManifestFailures = @()

foreach ($Row in $ManifestRows) {

    $RelativePath = [string]$Row.relative_path
    $ExpectedBytes = [int64]$Row.bytes
    $ExpectedHash = ([string]$Row.sha256).ToLowerInvariant()

    $PhysicalPath =
        Join-Path $ExtractedSyntheticRoot $RelativePath

    if (-not (Test-Path -LiteralPath $PhysicalPath)) {
        $ManifestFailures += "MISSING: $RelativePath"
        continue
    }

    $Item = Get-Item -LiteralPath $PhysicalPath

    if ($Item.Length -ne $ExpectedBytes) {
        $ManifestFailures += "BYTE_MISMATCH: $RelativePath"
        continue
    }

    $ActualHash = (
        Get-FileHash `
            -LiteralPath $PhysicalPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    if ($ActualHash -ne $ExpectedHash) {
        $ManifestFailures += "HASH_MISMATCH: $RelativePath"
    }
}

if ($ManifestFailures.Count -gt 0) {
    $ManifestFailures
    throw "STOP: synthetic-root manifest verification failed."
}

Write-Host "Synthetic-root manifest: PASS"


Write-Host ""
Write-Host "===== 6. RESTORE PHYSICAL SOURCE ====="

New-Item `
    -ItemType Directory `
    -Path $RestoreParent `
    -Force |
    Out-Null

Copy-Item `
    -LiteralPath $ExtractedSyntheticRoot `
    -Destination $RestoreParent `
    -Recurse

$RestoredFiles = @(
    Get-ChildItem `
        -LiteralPath $RestoreRoot `
        -File `
        -Recurse `
        -Force
)

if ($RestoredFiles.Count -ne 222) {
    throw "STOP: restored source does not contain exactly 222 files."
}

Write-Host "Physical source restored: PASS"


Write-Host ""
Write-Host "===== 7. RESTORE LOCAL SMB SHARE ====="

$ExistingShare =
    Get-SmbShare `
        -Name $ShareName `
        -ErrorAction SilentlyContinue

if ($null -ne $ExistingShare) {

    if (
        [IO.Path]::GetFullPath($ExistingShare.Path).TrimEnd('\') -ne
        [IO.Path]::GetFullPath($RestoreRoot).TrimEnd('\')
    ) {
        throw "STOP: existing share points to [$($ExistingShare.Path)], not [$RestoreRoot]."
    }

    Write-Host "Existing SMB share already points to correct source."
}
else {

    $Identity =
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    New-SmbShare `
        -Name $ShareName `
        -Path $RestoreRoot `
        -ReadAccess $Identity `
        -CachingMode None |
        Out-Null

    Write-Host "SMB share created for:" $Identity
}


Write-Host ""
Write-Host "===== 8. FINAL SOURCE VALIDATION ====="

$UncRoot = "\\localhost\$ShareName"

$FinalChecks = [ordered]@{
    "Physical root"  = Test-Path $RestoreRoot
    "Physical pbi"   = Test-Path "$RestoreRoot\pbi"
    "Physical build" = Test-Path "$RestoreRoot\build"
    "UNC root"       = Test-Path $UncRoot
    "UNC pbi"        = Test-Path "$UncRoot\pbi"
    "UNC build"      = Test-Path "$UncRoot\build"
}

$FinalChecks.GetEnumerator() |
    Format-Table -AutoSize

if ($FinalChecks.Values -contains $false) {
    throw "STOP: one or more final physical/UNC checks failed."
}

$FinalCount = @(
    Get-ChildItem `
        -LiteralPath $RestoreRoot `
        -File `
        -Recurse `
        -Force
).Count

Write-Host ""
Write-Host "Restored source files:" $FinalCount

if ($FinalCount -ne 222) {
    throw "STOP: final restored source count is not 222."
}

Write-Host ""
Write-Host "SMB share:"
Get-SmbShare -Name $ShareName |
    Select-Object Name, Path |
    Format-List

Write-Host "Share permissions:"
Get-SmbShareAccess -Name $ShareName |
    Format-Table AccountName, AccessControlType, AccessRight -AutoSize

Write-Host ""
Write-Host "A1B ACCEPTED SOURCE RESTORE: PASS"
```

The authoritative history confirms that this accepted source consisted of exactly **222 synthetic-root files**, with the UNC parameters remaining `\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi` and `...\build`. [export reference: filecite | turn103file5 | L420-L448]

### What success should look like

At the end, we want something like:

```text
Physical root   True
Physical pbi    True
Physical build  True
UNC root        True
UNC pbi         True
UNC build       True

Restored source files: 222

A1B ACCEPTED SOURCE RESTORE: PASS
```

Do **not** reopen Power BI until that final PASS appears.

Once it does, we'll retry the R26 refresh with **zero Power Query changes**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-aba63a79-44b1-44d6-9880-15b3c92ff640"></a>
## Andrew / user · C109-M00616

C109-M00616 · 2026-09-02T08:54:27.620000-04:00 · active path

Preceding visible parent: [C109-M00615](part-28.md#m-a905de47-8dab-486d-bc7c-0ea53b203c66)

**Editorial record note:** 9 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 4f96f2fa-47bd-4c6e-9a6d-bb475ae32790.png; 0cbd431c-8450-4ca1-b0c1-ffd7acc8c803.png; 24b96d5f-069e-4292-b844-2e210a7e2989.png; 685eff9c-b855-435c-9dfe-036737b1250a.png; bd4edd63-685e-476e-b94c-e286ca764154.png; 29b266eb-cbc7-49ba-9dd9-3e0399886ec1.png; d407f8bc-f0da-494b-8b45-33efe0170a3c.png; 817c2f7b-7693-4806-86c6-477abf0732df.png; b7ee93b6-2d75-4ebe-a1a9-40e81e81b7b6.png

<!-- BEGIN_SOURCE_MESSAGE -->
also, before we do that, we had been working here. not sure if that is relevant or not.
<!-- END_SOURCE_MESSAGE -->


<a id="m-957ae1b4-e859-47c0-9e56-6c119864a053"></a>
## Assistant · C109-M00617

C109-M00617 · 2026-09-02T08:54:31.232933-04:00 · active path

Preceding visible parent: [C109-M00616](part-28.md#m-aba63a79-44b1-44d6-9880-15b3c92ff640)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — this is relevant, and it actually clarifies the architecture. **Do not delete, move, or repoint anything under `C:\MSBF\R22\power_bi`.** That tree is your preserved R22/R1 successor state and the working lineage we have been refining.

What your screenshots show is that there are **two different source families** in this Power BI model.

```text
A. CORE / ORIGINAL POWER BI SOURCE
   \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
   \\localhost\MSBF_PBI_A1B_SYNTHETIC\build

   Supplies things such as:
   DimDate
   DimAsOfDate
   DimRunCampaign
   DimScenario
   DimMerchant
   DimApplication
   DimIndustry
   DimAcquisitionSource
   core validation/governance facts
```

That is the source that is currently missing. The accepted A1b design used exactly that UNC root and an underlying 222-file synthetic source tree. [export reference: filecite | turn103file5 | L420-L448]

Separately:

```text
B. SUCCESSOR / R1-R26 SOURCE

R22 predecessor:
C:\MSBF\R22\power_bi\carrier

R26 candidate:
C:\MSBF\R26\power_bi\carrier
```

Your screenshots of `C:\MSBF\R22\power_bi\carrier` prove what it contains: `R1DimApplicationScenario`, `R1FactDailyMonitoring`, `R1FactFinalDecision`, offer candidates, strategy simulations, G3-v2 certification, R4/R17/R19 raw files, etc. That is the **successor carrier**, not the core A1b source.

So the R22 folder is highly relevant to **preserving our work and lineage**, but it cannot fix the `DimDate / DimMerchant / DimScenario` refresh failure.

### What the rest of R22 is

Your folders line up exactly with the history of our recent work:

```text
C:\MSBF\R22\power_bi\carrier
    → accepted/pre-R26 successor data carrier

C:\MSBF\R22\power_bi\pbip
    → frozen R22 successor PBIP candidate

C:\MSBF\R22\power_bi\desktop_working\
    MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22\
        MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.Report
        MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.SemanticModel
        MSBF_PBI_R1_PARALLEL_REFINEMENT_C1_20260901.pbip
```

That `desktop_working` branch is precisely the refinement candidate you were using before the R26 rebase. **We want that entire tree preserved unchanged as the before-state.**

It also explains why your report could work previously: Power BI had both:

```text
old core UNC source
+
R22 successor carrier
```

R26 only replaced/rebased the second component. The R26 handoff was never intended to contain the original Dim/Fact core source.

## One thing I would check before restoring anything

Since this is an important dependency boundary, let's confirm it directly from the actual R22 working semantic model.

Run this read-only PowerShell block:

```powershell
$R22Working =
    "C:\MSBF\R22\power_bi\desktop_working\MSBF_PBI_R1_SUCCESSOR_CANDIDATE_R22"

Get-ChildItem `
    -LiteralPath $R22Working `
    -File `
    -Recurse `
    -ErrorAction Stop |
Select-String `
    -Pattern @(
        'MSBF_PBI_A1B_SYNTHETIC',
        'pDataRoot',
        'pBuildRoot',
        'R22\\power_bi\\carrier',
        'R1Successor'
    ) `
    -SimpleMatch |
Select-Object Path, LineNumber, Line |
Format-List
```

I expect this to show two parallel dependencies:

```text
pDataRoot / pBuildRoot
→ \\localhost\MSBF_PBI_A1B_SYNTHETIC\...

successor carrier/root
→ C:\MSBF\R22\power_bi\carrier
```

That gives us a nice before-state confirmation before restoring the missing A1b source.

### What we should not do

Do **not**:

- point `pDataRoot` to `C:\MSBF\R22\power_bi\carrier`;
- point `pDataRoot` to `C:\MSBF\R26\power_bi\carrier`;
- copy R22 curated CSVs into the missing A1b source tree;
- rely on a `cache.abf` as a replacement for the governed source;
- modify the R22 working candidate.

Those approaches could make visuals render but would collapse two distinct source boundaries and damage the audit lineage.

### What we should do

The clean recovery remains:

```text
1. Preserve C:\MSBF\R22\power_bi exactly as-is.

2. Preserve C:\MSBF\R26\power_bi\carrier exactly as already verified.

3. Restore the accepted A1b 222-file synthetic_root from:
   C:\MSBF\
   MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip

4. Restore its expected physical path:
   C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root

5. Restore:
   \\localhost\MSBF_PBI_A1B_SYNTHETIC

6. Reopen R26 and Refresh All without changing any Power Query definitions.
```

The Focused R2 authority is particularly useful here because Independent Audit confirmed that its final carrier was the controlling A1b authority and that the 222 synthetic-root files/source roots were unchanged. [export reference: filecite | turn103file1 | L61-L68] [export reference: filecite | turn103file1 | L88-L96]

So your R22 screenshots do **not** change the recovery plan, but they give us confidence that the missing UNC source is a **separate environmental dependency**, not evidence that we chose the wrong R26 carrier or accidentally bypassed your current refinement work.

I would run the short read-only R22 parameter search above first. Then we can restore the A1b source with the exact accepted carrier.
<!-- END_SOURCE_MESSAGE -->
