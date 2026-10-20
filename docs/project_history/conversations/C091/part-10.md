# MSBF - Power BI Executive Portfolio Intelligence

Part 10 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-09.md)
[Next part](part-11.md)

<a id="m-15b609c5-bd1c-4f81-85e7-51913e9b5c81"></a>
## Andrew / user · C091-M00123

C091-M00123 · 2026-08-19T19:24:27.193000-04:00 · active path

Preceding visible parent: [C091-M00122](part-09.md#m-55384be4-876a-4f00-80c5-8db331f07821)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E00_DATA_SOURCES_IN_CURRENT_FILE.png

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\Windows\System32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819" 
>> $ev   = Join-Path $work "evidence\local_engine_pending" 
>> 
>> @' 
>> A1B DESKTOP IDENTITY HELPER TOOLING OBSERVATION 
>> 
>> Date: 2026-08-19 
>> 
>> Operation: 
>> Capture-A1bDesktopIdentity.ps1 
>> 
>> Observed failure: 
>> The helper attempted to use Get-AppxPackage. PowerShell located that command 
>> in the Appx module, but the module could not load in the current PowerShell 7 
>> environment: 
>> 
>> Operation is not supported on this platform. (0x80131539) 
>> 
>> Power BI Desktop remained open. 
>> No Power BI refresh occurred. 
>> No Power Query Refresh Preview occurred. 
>> No model processing occurred. 
>> No PBIP or semantic-model repair was performed. 
>> 
>> The Power BI About dialog independently showed: 
>> Version 2.156.951.0 64-bit (July 2026) 
>> 
>> Next action: 
>> Capture the active PBIDesktop process/executable/version using native process 
>> and CIM evidence without relying on the Appx module. 
>> '@ | 
>>     Set-Content ` 
>>         -LiteralPath "$ev\E00_DESKTOP_IDENTITY_HELPER_TOOLING_OBSERVATION.txt" ` 
>>         -Encoding utf8 
PS C:\Windows\System32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819" 
>> $ev   = Join-Path $work "evidence\local_engine_pending" 
>> 
>> $processes = @( 
>>     Get-CimInstance Win32_Process | 
>>     Where-Object { $_.Name -ieq "PBIDesktop.exe" } 
>> ) 
>> 
>> if ($processes.Count -eq 0) { 
>>     throw "STOP: no active PBIDesktop.exe process found." 
>> } 
>> 
>> $records = foreach ($p in $processes) { 
>> 
>>     $exe = [string]$p.ExecutablePath 
>> 
>>     $fileVersion = $null 
>>     $productVersion = $null 
>> 
>>     if ($exe -and (Test-Path -LiteralPath $exe)) { 
>>         $vi = (Get-Item -LiteralPath $exe).VersionInfo 
>>         $fileVersion = $vi.FileVersion 
>>         $productVersion = $vi.ProductVersion 
>>     } 
>> 
>>     [pscustomobject]@{ 
>>         process_id = [int]$p.ProcessId 
>>         parent_process_id = [int]$p.ParentProcessId 
>>         process_name = [string]$p.Name 
>>         executable_path = $exe 
>>         command_line = [string]$p.CommandLine 
>>         file_version = $fileVersion 
>>         product_version = $productVersion 
>>     } 
>> } 
>> 
>> $records | Format-List 
>> 
>> [pscustomobject]@{ 
>>     event = "A1B_POWER_BI_DESKTOP_PROCESS_IDENTITY" 
>>     captured_local = (Get-Date).ToString("o") 
>>     captured_utc = (Get-Date).ToUniversalTime().ToString("o") 
>>     about_dialog_version = "2.156.951.0" 
>>     about_dialog_architecture = "64-bit" 
>>     about_dialog_release = "July 2026" 
>>     active_process_count = $records.Count 
>>     processes = @($records) 
>> } | 
>>     ConvertTo-Json -Depth 8 | 
>>     Set-Content ` 
>>         -LiteralPath "$ev\E00_POWER_BI_DESKTOP_PROCESS_IDENTITY.json" ` 
>>         -Encoding utf8 
 
process_id        : 11356 
parent_process_id : 23168 
process_name      : PBIDesktop.exe 
executable_path   : C:\Program Files\WindowsApps\Microsoft.MicrosoftPowerBIDesktop_2.156.951.0_x64__8wekyb3d8bbwe\bin\pbidesktop.exe 
command_line      : "C:\Program Files\WindowsApps\Microsoft.MicrosoftPowerBIDesktop_2.156.951.0_x64__8wekyb3d8bbwe\bin\pbidesktop.exe" "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\project\MSBF_PBI_A1A_Local_Construction_R1.pbip" 
file_version      : 2.156.951.0 
product_version   : 2.156.951.0 (26.07)+c9381f8e5efc99c8de04425f1572e841914690d8                     Also, anytime I'm providing you a screenshot, like the attached, I am also saving it in our evidence folder and in my chatgpt_interaction folders
<!-- END_SOURCE_MESSAGE -->


<a id="m-75d669dd-c33f-4978-a98b-ea8b4415fcd1"></a>
## Assistant · C091-M00124

C091-M00124 · 2026-08-19T19:24:53.718719-04:00 · active path

Preceding visible parent: [C091-M00123](part-10.md#m-15b609c5-bd1c-4f81-85e7-51913e9b5c81)

<!-- BEGIN_SOURCE_MESSAGE -->
This is good progress. Two pre-refresh controls are now materially established, and the third has a clear path.

Your **global Privacy** screenshot shows that Power BI is enforcing each file/source’s privacy settings and that **“Always ignore Privacy Level settings” is not selected**. Your About dialog identifies **Power BI Desktop 2.156.951.0, 64-bit, July 2026**. The native CIM capture independently resolves the live `PBIDesktop.exe` to the WindowsApps path with matching file/product version `2.156.951.0`, so the substance of the Desktop-identity requirement is satisfied. Audit required both direct privacy enforcement and Desktop process/executable/version evidence before first A1b refresh. [export reference: filecite | turn16file3 | L188-L205]

The current-file Data Source Settings screenshot is also useful: it proves that **before A1b source evaluation, Desktop has no registered current-file source**, with the explicit warning that hand-authored queries may not be listed. Preserve that screenshot as a pre-registration observation; it is not yet the required screenshot showing the actual `S:\` privacy classification.

One correction before we continue: the package gate looks for the mandatory evidence under `evidence\local_engine_return`, whereas the commands I gave you wrote the helper observation and native identity JSON to `local_engine_pending`. The supplied gate explicitly requires the screenshots, privacy attestation, Desktop identity, synthetic-root mapping, A1a baseline preflight, and A1b boundary evidence under `local_engine_return`. We should reconcile that now rather than discover it at gate time.

### 1. Normalize the evidence location

Run this while Desktop remains open:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"

$pending = Join-Path $work "evidence\local_engine_pending"
$return  = Join-Path $work "evidence\local_engine_return"

New-Item `
    -ItemType Directory `
    -Path $return `
    -Force |
    Out-Null

# Preserve the helper failure in the controlling return-evidence directory.
if (Test-Path -LiteralPath "$pending\E00_DESKTOP_IDENTITY_HELPER_TOOLING_OBSERVATION.txt") {
    Copy-Item `
        -LiteralPath "$pending\E00_DESKTOP_IDENTITY_HELPER_TOOLING_OBSERVATION.txt" `
        -Destination "$return\E00_DESKTOP_IDENTITY_HELPER_TOOLING_OBSERVATION.txt" `
        -Force
}
```

Because you are already saving every screenshot in the evidence folder, make sure these exact files are in `local_engine_return`:

```text
E00_PRIVACY_GLOBAL_ENFORCEMENT.png
E00_POWER_BI_DESKTOP_ABOUT.png
```

Save the current screenshot showing **“We didn't find any data sources in this file”** separately as:

```text
E00_DATA_SOURCES_IN_CURRENT_FILE_PRE_REGISTRATION.png
```

That is useful adverse/pre-state evidence, but it should **not** masquerade as the required `E00_PRIVACY_DATA_SOURCE_SETTINGS.png`.

### 2. Write the native Desktop identity in the schema the gate expects

Your native capture is stronger than the failed Appx helper, but the package gate expects fields named `identity_status` and `resolved_version`. Create the controlling machine-readable identity from the process you just physically observed:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

$processes = @(
    Get-CimInstance Win32_Process |
    Where-Object { $_.Name -ieq "PBIDesktop.exe" }
)

if ($processes.Count -ne 1) {
    throw "STOP: expected exactly one active PBIDesktop.exe; found $($processes.Count)."
}

$p = $processes[0]
$exe = [string]$p.ExecutablePath

if (-not $exe -or -not (Test-Path -LiteralPath $exe)) {
    throw "STOP: active Power BI Desktop executable path cannot be resolved."
}

$vi = (Get-Item -LiteralPath $exe).VersionInfo

$identity = [ordered]@{
    captured_utc       = (Get-Date).ToUniversalTime().ToString("o")
    process_id         = [int]$p.ProcessId
    process_name       = [string]$p.Name
    parent_process_id  = [int]$p.ParentProcessId
    executable_path    = $exe
    command_line       = [string]$p.CommandLine
    file_version       = [string]$vi.FileVersion
    product_version    = [string]$vi.ProductVersion
    resolved_version   = [string]$vi.FileVersion
    version_source     = "EXECUTABLE_FILE_VERSION_AND_ABOUT_DIALOG"
    about_version      = "2.156.951.0"
    about_architecture = "64-bit"
    about_release      = "July 2026"
    appx_lookup        = "NOT_REQUIRED_EXECUTABLE_IDENTITY_RESOLVED"
    identity_status    = "PASS"
}

$identity |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E00_POWER_BI_DESKTOP_PROCESS_IDENTITY.json" `
        -Encoding utf8

$identity | Format-List
```

Required reconciliation:

```text
process_id        11356   # if the same process remains open
executable_path   ...\Microsoft.MicrosoftPowerBIDesktop_2.156.951.0_x64...\pbidesktop.exe
file_version      2.156.951.0
resolved_version  2.156.951.0
identity_status   PASS
```

The audit specifically left Desktop identity as an observation only until A1b, and required it closed before refresh. [export reference: filecite | turn16file3 | L203-L207]

### 3. Register the isolated `S:\` source without performing Refresh All

Your current-file screenshot establishes why the required source permission is not visible yet: the file uses hand-authored M and Desktop has not registered its source in this session.

Close the Data Source Settings dialog, then choose:

**Home → Transform data**

This is permitted at this stage; the runbook explicitly calls for opening Transform Data to verify the 79-query inventory before the refresh phase. [export reference: filecite | turn17file0 | L41-L53]

Once Power Query Editor opens, **do not click Refresh Preview → Refresh All** and do not Close & Apply.

First visually confirm the query count says:

```text
Queries [79]
```

Then select:

```text
stg_POWER_BI_DATA_CATALOG
```

This existing governed query should be sufficient to make Desktop resolve its `S:\pbi` source. If Power BI displays:

```text
Information is required about data privacy
```

click **Continue**.

For this isolated, fully inventoried synthetic A1b root, I recommend setting the source to **Public** rather than repeating the A1a Private failure. Independent Audit expressly permits Public **only** for an isolated MSBF synthetic root containing no unrelated personal or production data; the prohibited configuration is broad `C:\ Public` or global privacy ignore. [export reference: filecite | turn16file3 | L194-L201]

The important distinction is:

```text
A1a:
C:\  → Public
OVERBROAD / not reusable

A1b:
S:\ isolated synthetic root → Public
PERMITTED for this bounded local evidence run
```

If Desktop identifies the scopes separately as `S:\pbi` and `S:\build`, classify each consistently. Do **not** classify `C:\`.

If selecting the query immediately produces some other error before a privacy dialog appears, stop and send me the error. Do not troubleshoot by refreshing.

### 4. After source registration, capture the required exact privacy screenshot

Without running Refresh All, return to **Data Source Settings**.

We need the screenshot to show the actual registered isolated source(s), for example:

```text
S:\
```

or:

```text
S:\pbi
S:\build
```

with the applied privacy classification.

Use **Edit Permissions** if necessary to expose the exact privacy-level setting for the screenshot.

Save the final proof as exactly:

```text
E00_PRIVACY_DATA_SOURCE_SETTINGS.png
```

in `evidence\local_engine_return`.

The previous `C:\` global-permissions screenshot should also remain preserved as historical evidence, but it is **not** the controlling A1b source setting.

### 5. Then create the privacy attestation

Only after the UI actually shows the `S:\` classification, run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

$privacy = [ordered]@{
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    contains_unrelated_personal_or_production_data = $false
    isolated_synthetic_root_only = $true

    global_privacy_enforcement_enabled = $true
    ignore_privacy_levels = $false
    fast_combine_enabled = $false

    privacy_level = "Public"

    source_scopes = @(
        "S:\pbi",
        "S:\build"
    )

    screenshot_data_source_settings = "E00_PRIVACY_DATA_SOURCE_SETTINGS.png"
    screenshot_global_privacy = "E00_PRIVACY_GLOBAL_ENFORCEMENT.png"

    source_owner_attestation = `
        "Direct Power BI UI evidence confirms privacy enforcement. Public classification is limited to the isolated, inventoried MSBF synthetic S:\ source boundary and is not a production privacy standard."
}

$privacy |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E00_PRIVACY_ATTESTATION.json" `
        -Encoding utf8

$privacy | Format-List
```

If Desktop registers only `S:\` rather than the two subroots, **do not use this exact block yet**; send me the screenshot and we will make `source_scopes` match the physical UI exactly. The attestation should never claim finer scoping than Desktop actually shows.

### Current gate position

```text
A1a accepted baseline                         PASS
A1b 32/32/79/60 boundary                      PASS
S:\ isolated synthetic mapping                PASS
Global privacy enforcement                    PASS
Desktop About/version                         PASS
Desktop executable/process identity           PASS substantively
Helper Appx failure                            PRESERVED TOOLING OBSERVATION
Current-file pre-registration source state     CAPTURED
Exact S:\ privacy registration                 NEXT
Privacy attestation                            WAITING FOR S:\ UI
Pre-refresh evidence gate                      NOT YET RUN
Refresh Preview / Refresh All                  PROHIBITED
Close & Apply                                  PROHIBITED
Desktop Refresh                                PROHIBITED
```

And yes—continue saving every screenshot both in the formal evidence directory and in your ChatGPT interaction archive. That gives Independent Audit the same strong chronology/non-omission trail that proved valuable during A1a.

**Next action:** open **Transform Data**, confirm `Queries [79]`, select `stg_POWER_BI_DATA_CATALOG`, and show me what happens—especially any privacy dialog and the source path it identifies.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7645c4a6-e268-4a8d-87a0-3a1fe75f0819"></a>
## Andrew / user · C091-M00125

C091-M00125 · 2026-08-19T19:51:32.885000-04:00 · active path

Preceding visible parent: [C091-M00124](part-10.md#m-75d669dd-c33f-4978-a98b-ea8b4415fcd1)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: E00_DATA_SOURCE_SETTINGS_02.png; E00_STG_POWER_BI_DATA_CATALOG.png

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\Windows\System32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819" 
>> 
>> $pending = Join-Path $work "evidence\local_engine_pending" 
>> $return  = Join-Path $work "evidence\local_engine_return" 
>> 
>> New-Item ` 
>>     -ItemType Directory ` 
>>     -Path $return ` 
>>     -Force | 
>>     Out-Null 
>> 
>> # Preserve the helper failure in the controlling return-evidence directory. 
>> if (Test-Path -LiteralPath "$pending\E00_DESKTOP_IDENTITY_HELPER_TOOLING_OBSERVATION.txt") { 
>>     Copy-Item ` 
>>         -LiteralPath "$pending\E00_DESKTOP_IDENTITY_HELPER_TOOLING_OBSERVATION.txt" ` 
>>         -Destination "$return\E00_DESKTOP_IDENTITY_HELPER_TOOLING_OBSERVATION.txt" ` 
>>         -Force 
>> } 
PS C:\Windows\System32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819" 
>> $return = Join-Path $work "evidence\local_engine_return" 
>> 
>> $processes = @( 
>>     Get-CimInstance Win32_Process | 
>>     Where-Object { $_.Name -ieq "PBIDesktop.exe" } 
>> ) 
>> 
>> if ($processes.Count -ne 1) { 
>>     throw "STOP: expected exactly one active PBIDesktop.exe; found $($processes.Count)." 
>> } 
>> 
>> $p = $processes[0] 
>> $exe = [string]$p.ExecutablePath 
>> 
>> if (-not $exe -or -not (Test-Path -LiteralPath $exe)) { 
>>     throw "STOP: active Power BI Desktop executable path cannot be resolved." 
>> } 
>> 
>> $vi = (Get-Item -LiteralPath $exe).VersionInfo 
>> 
>> $identity = [ordered]@{ 
>>     captured_utc       = (Get-Date).ToUniversalTime().ToString("o") 
>>     process_id         = [int]$p.ProcessId 
>>     process_name       = [string]$p.Name 
>>     parent_process_id  = [int]$p.ParentProcessId 
>>     executable_path    = $exe 
>>     command_line       = [string]$p.CommandLine 
>>     file_version       = [string]$vi.FileVersion 
>>     product_version    = [string]$vi.ProductVersion 
>>     resolved_version   = [string]$vi.FileVersion 
>>     version_source     = "EXECUTABLE_FILE_VERSION_AND_ABOUT_DIALOG" 
>>     about_version      = "2.156.951.0" 
>>     about_architecture = "64-bit" 
>>     about_release      = "July 2026" 
>>     appx_lookup        = "NOT_REQUIRED_EXECUTABLE_IDENTITY_RESOLVED" 
>>     identity_status    = "PASS" 
>> } 
>> 
>> $identity | 
>>     ConvertTo-Json -Depth 6 | 
>>     Set-Content ` 
>>         -LiteralPath "$return\E00_POWER_BI_DESKTOP_PROCESS_IDENTITY.json" ` 
>>         -Encoding utf8 
>> 
>> $identity | Format-List 
 
Name  : captured_utc 
Value : 2026-08-19T23:32:23.4381847Z 
 
Name  : process_id 
Value : 11356 
 
Name  : process_name 
Value : PBIDesktop.exe 
 
Name  : parent_process_id 
Value : 23168 
 
Name  : executable_path 
Value : C:\Program Files\WindowsApps\Microsoft.MicrosoftPowerBIDesktop_2.156.951.0_x64__8wekyb3d8bbwe\bin\pbidesktop.exe 
 
Name  : command_line 
Value : "C:\Program Files\WindowsApps\Microsoft.MicrosoftPowerBIDesktop_2.156.951.0_x64__8wekyb3d8bbwe\bin\pbidesktop.exe" "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\project\MSBF_PBI_A1A_Local_Construction_R1.pbip" 
 
Name  : file_version 
Value : 2.156.951.0 
 
Name  : product_version 
Value : 2.156.951.0 (26.07)+c9381f8e5efc99c8de04425f1572e841914690d8 
 
Name  : resolved_version 
Value : 2.156.951.0 
 
Name  : version_source 
Value : EXECUTABLE_FILE_VERSION_AND_ABOUT_DIALOG 
 
Name  : about_version 
Value : 2.156.951.0 
 
Name  : about_architecture 
Value : 64-bit 
 
Name  : about_release 
Value : July 2026 
 
Name  : appx_lookup 
Value : NOT_REQUIRED_EXECUTABLE_IDENTITY_RESOLVED 
 
Name  : identity_status 
Value : PASS                            PATH STILL SHOWS C:
<!-- END_SOURCE_MESSAGE -->


<a id="m-d8308b9f-9c99-40e3-9758-fb7a689b97b6"></a>
## Assistant · C091-M00126

C091-M00126 · 2026-08-19T19:57:19.559518-04:00 · active path

Preceding visible parent: [C091-M00125](part-10.md#m-7645c4a6-e268-4a8d-87a0-3a1fe75f0819)

<!-- BEGIN_SOURCE_MESSAGE -->
The screenshot explains it: **Power Query is successfully reading the A1b source through `S:\`**, but **Data Source Settings is still showing only the old global `C:\` permission**. That means the `S:` drive mapping has not created a distinct privacy-permission entry in Desktop. Because the audit explicitly requires the privacy boundary itself to be a dedicated MSBF synthetic root—not broad `C:\`—we should treat this as a pre-refresh blocker rather than proceed. The audit’s stop condition is explicit: if the only executable route leaves the privacy boundary at `C:\`, stop. [export reference: filecite | turn16file3 | L194-L201]

Your Power Query screenshot is still valuable: it proves `pBuildRoot = S:\build`, `Queries [79]`, and `stg_POWER_BI_DATA_CATALOG` successfully evaluates with 214 rows. So the semantic source path is correct; the unresolved issue is specifically **Power BI’s privacy-source registration**.

Microsoft’s documentation confirms that Power Query privacy is attached to the recognized **data-source path**, and the path displayed in Data Source Settings is derived from the connector’s source parameters. It also warns against globally ignoring privacy levels. [export reference: cite | turn376300search0 | turn376300search3]

### Do not refresh or Close & Apply

At this point preserve the current state. Do **not**:

```text
Refresh All
Close & Apply
Desktop Refresh
edit the old C:\ permission
globally ignore privacy levels
```

The Desktop process identity is now fully resolved and reconciles perfectly:

```text
PBIDesktop.exe
2.156.951.0
64-bit
WindowsApps executable resolved
identity_status = PASS
```

So `PBI-F-006` has the required source-owner evidence. The remaining open precondition is `PBI-F-004`.

### Preserve this exact privacy-registration observation

Run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1B_DEDICATED_ROOT_PRIVACY_REGISTRATION_OBSERVATION"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    power_query_objects = 79
    selected_query = "stg_POWER_BI_DATA_CATALOG"
    selected_query_preview_rows = 214
    selected_query_preview_status = "PASS"

    pDataRoot = "S:\pbi"
    pBuildRoot = "S:\build"

    mapped_root = "S:\"
    mapped_target = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"

    global_privacy_enforcement = "ENABLED"
    ignore_privacy_levels = $false

    data_source_settings_observed_global_entries = @(
        "C:\"
    )

    dedicated_s_root_permission_visible = $false

    refresh_preview_all_executed = $false
    close_and_apply_executed = $false
    desktop_refresh_executed = $false

    disposition = "HOLD_PRE_REFRESH_PRIVACY_BOUNDARY"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E00_DEDICATED_ROOT_PRIVACY_REGISTRATION_OBSERVATION.json" `
        -Encoding utf8
```

Preserve the two latest screenshots as:

```text
E00_DATA_SOURCE_SETTINGS_02.png
E00_STG_POWER_BI_DATA_CATALOG.png
```

### Recommended correction

The cleanest fix is to **stop using a mapped `S:` drive backed by a `C:\` folder for the privacy boundary**. Power BI appears to be resolving the underlying File source permission to the physical drive/root rather than treating the `SUBST` alias as a separate privacy source.

Instead, we should use a **dedicated local UNC share** for the synthetic root, for example:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
\\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

This gives Power Query a distinct source path that is not `C:\`, while still pointing only to the fully inventoried synthetic folder. Power Query privacy settings are keyed to recognized source paths, so a UNC source should surface as its own permission boundary rather than inherit the old `C:\` entry. [export reference: cite | turn376300search3 | turn376300search4]

However, changing `pDataRoot` and `pBuildRoot` from `S:\...` to a dedicated governed synthetic root **is allowed by the audit**, while any broader A1a source change is not. The authorization explicitly permits changing only those two parameters to dedicated synthetic roots. [export reference: filecite | turn16file5 | L69-L86]

Before I give you the exact PowerShell commands to create the isolated UNC share and patch only those two parameter values, I want to keep this bounded and reproducible. The next step will be:

```text
1. Close Power Query without Apply.
2. Close Power BI without saving any data-processing state.
3. Create a dedicated read-only local SMB share over synthetic_root.
4. Change only pDataRoot and pBuildRoot to the UNC paths.
5. Re-run the static 32/32/79/60 boundary verifier.
6. Reopen Desktop.
7. Capture the UNC source in Data Source Settings.
8. Set its privacy classification.
9. Run the pre-refresh gate.
10. Only then permit Refresh Preview.
```

That is preferable to trying to force `S:` into Desktop’s permission store or altering the historical `C:\` permission.

Your current gate state is therefore:

```text
A1a baseline                              PASS
A1b 32/32/79/60 boundary                 PASS
Power Query 79-query inventory            PASS
stg_POWER_BI_DATA_CATALOG preview          PASS — 214 rows
Global privacy enforcement                PASS
Desktop process/version identity          PASS
Dedicated S:\ semantic paths              PASS
Dedicated S:\ privacy entry               FAIL / NOT PRESENT
PBI-F-004                                 OPEN
First Refresh All                         PROHIBITED
```

The right next move is to replace the `SUBST`-based privacy boundary with an isolated UNC source, not to continue refreshing.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9b10c5ea-feac-48b1-ac98-06e6c7745475"></a>
## Andrew / user · C091-M00127

C091-M00127 · 2026-08-19T20:37:42.808000-04:00 · active path

Preceding visible parent: [C091-M00126](part-10.md#m-d8308b9f-9c99-40e3-9758-fb7a689b97b6)

<!-- BEGIN_SOURCE_MESSAGE -->
Please give instructions for: 3. Create a dedicated read-only local SMB share over synthetic_root.
4. Change only pDataRoot and pBuildRoot to the UNC paths.
5. Re-run the static 32/32/79/60 boundary verifier.
6. Reopen Desktop.
7. Capture the UNC source in Data Source Settings.
8. Set its privacy classification.
9. Run the pre-refresh gate.
10. Only then permit Refresh Preview.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0db6109e-c521-450e-8a64-d2b53507df0f"></a>
## Assistant · C091-M00128

C091-M00128 · 2026-08-19T20:38:06.476786-04:00 · active path

Preceding visible parent: [C091-M00127](part-10.md#m-9b10c5ea-feac-48b1-ac98-06e6c7745475)

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-d6302927-6bbd-4532-a95e-f6c69a9f0774"></a>
## Andrew / user · C091-M00129

C091-M00129 · 2026-08-19T20:45:49.497000-04:00 · active path

Preceding visible parent: [C091-M00128](part-10.md#m-0db6109e-c521-450e-8a64-d2b53507df0f)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\WINDOWS\system32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
>>
>> $syntheticRoot = Join-Path $work "synthetic_root"
>> $shareName = "MSBF_PBI_A1B_SYNTHETIC"
>>
>> if (-not (Test-Path -LiteralPath $syntheticRoot)) {
>>     throw "STOP: synthetic_root does not exist."
>> }
>>
>> Get-ChildItem -LiteralPath $syntheticRoot


    Directory: C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root


Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----         8/19/2026   6:10 PM                build
d-----         8/19/2026   6:10 PM                pbi


PS C:\WINDOWS\system32> $existing = Get-SmbShare `
>>     -Name $shareName `
>>     -ErrorAction SilentlyContinue
>>
>> if ($existing) {
>>     Write-Host "Existing share found:"
>>     $existing |
>>         Select-Object Name,Path,Description |
>>         Format-List
>>
>>     if ($existing.Path -cne $syntheticRoot) {
>>         throw "STOP: existing share name points somewhere else."
>>     }
>> }
>> else {
>>     New-SmbShare `
>>         -Name $shareName `
>>         -Path $syntheticRoot `
>>         -ReadAccess $env:USERNAME `
>>         -Description "MSBF Power BI A1b isolated synthetic evidence root"
>> }

Name                   ScopeName Path                                                    Description
----                   --------- ----                                                    -----------
MSBF_PBI_A1B_SYNTHETIC *         C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root MSBF Power BI A1b isolated ...


PS C:\WINDOWS\system32> Get-SmbShare `
>>     -Name $shareName |
>>     Select-Object `
>>         Name,
>>         Path,
>>         Description |
>>     Format-List
>>
>> Get-SmbShareAccess `
>>     -Name $shareName |
>>     Format-Table -AutoSize


Name        : MSBF_PBI_A1B_SYNTHETIC
Path        : C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root
Description : MSBF Power BI A1b isolated synthetic evidence root




Name                   ScopeName AccountName  AccessControlType AccessRight
----                   --------- -----------  ----------------- -----------
MSBF_PBI_A1B_SYNTHETIC *         Owner\Andrew Allow             Read


PS C:\WINDOWS\system32> $uncRoot  = "\\localhost\MSBF_PBI_A1B_SYNTHETIC"
>> $uncPbi   = "$uncRoot\pbi"
>> $uncBuild = "$uncRoot\build"
>>
>> [pscustomobject]@{
>>     unc_root_exists  = Test-Path -LiteralPath $uncRoot
>>     unc_pbi_exists   = Test-Path -LiteralPath $uncPbi
>>     unc_build_exists = Test-Path -LiteralPath $uncBuild
>> } | Format-List


unc_root_exists  : True
unc_pbi_exists   : True
unc_build_exists : True



PS C:\WINDOWS\system32> $return = Join-Path $work "evidence\local_engine_return"
>>
>> $share = Get-SmbShare -Name $shareName
>> $access = @(Get-SmbShareAccess -Name $shareName)
>>
>> [pscustomobject]@{
>>     event = "A1B_DEDICATED_SYNTHETIC_SMB_ROOT"
>>     captured_local = (Get-Date).ToString("o")
>>     captured_utc = (Get-Date).ToUniversalTime().ToString("o")
>>
>>     share_name = $share.Name
>>     physical_path = $share.Path
>>
>>     unc_root = $uncRoot
>>     pDataRoot_target = $uncPbi
>>     pBuildRoot_target = $uncBuild
>>
>>     unc_root_exists = Test-Path -LiteralPath $uncRoot
>>     unc_pbi_exists = Test-Path -LiteralPath $uncPbi
>>     unc_build_exists = Test-Path -LiteralPath $uncBuild
>>
>>     purpose = "ISOLATED_MSBF_SYNTHETIC_POWER_BI_A1B_SOURCE"
>>     unrelated_personal_or_production_data = $false
>>
>>     share_access = @(
>>         $access | ForEach-Object {
>>             [pscustomobject]@{
>>                 account = $_.AccountName
>>                 access_control_type = $_.AccessControlType
>>                 access_right = $_.AccessRight
>>             }
>>         }
>>     )
>> } |
>>     ConvertTo-Json -Depth 8 |
>>     Set-Content `
>>         -LiteralPath "$return\E00_SYNTHETIC_SMB_ROOT.json" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> $model = Join-Path $work `
>>     "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"
>>
>> $before = Join-Path $return `
>>     "E00_MODEL_BIM_PRE_UNC_PARAMETER_PATCH.bim"
>>
>> Copy-Item `
>>     -LiteralPath $model `
>>     -Destination $before `
>>     -Force
>>
>> $beforeHash = (
>>     Get-FileHash $model -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> Write-Host "Before model.bim:"
>> Write-Host $beforeHash
Before model.bim:
43e5ccd3f48fe5e1125fe8d7a1278625ebfa08763b66b46708ec73276a2ae656
PS C:\WINDOWS\system32> $m = Get-Content -LiteralPath $model -Raw |
>>     ConvertFrom-Json
>>
>> $m.model.expressions |
>>     Where-Object {
>>         $_.name -in @("pDataRoot","pBuildRoot")
>>     } |
>>     Select-Object name,expression |
>>     Format-List


name       : pDataRoot
expression : "S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

name       : pBuildRoot
expression : "S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]



PS C:\WINDOWS\system32> $dataExpr = @(
>>     $m.model.expressions |
>>     Where-Object { $_.name -ceq "pDataRoot" }
>> )
>>
>> $buildExpr = @(
>>     $m.model.expressions |
>>     Where-Object { $_.name -ceq "pBuildRoot" }
>> )
>>
>> if ($dataExpr.Count -ne 1 -or $buildExpr.Count -ne 1) {
>>     throw "STOP: expected exactly one pDataRoot and one pBuildRoot."
>> }
>>
>> $dataExpr[0].expression = `
>>     '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>>
>> $buildExpr[0].expression = `
>>     '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
PS C:\WINDOWS\system32> $raw = [IO.File]::ReadAllText($model)
>>
>> $oldData  = '"S:\\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>> $newData  = '"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>>
>> $oldBuild = '"S:\\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>> $newBuild = '"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>>
>> $dataMatches  = ([regex]::Matches(
>>     $raw,
>>     [regex]::Escape($oldData)
>> )).Count
>>
>> $buildMatches = ([regex]::Matches(
>>     $raw,
>>     [regex]::Escape($oldBuild)
>> )).Count
>>
>> Write-Host "pDataRoot matches: " $dataMatches
>> Write-Host "pBuildRoot matches:" $buildMatches
>>
>> if ($dataMatches -ne 1 -or $buildMatches -ne 1) {
>>     throw "STOP: parameter replacement population is not exactly 1 + 1."
>> }
>>
>> $patched = $raw.Replace($oldData,$newData)
>> $patched = $patched.Replace($oldBuild,$newBuild)
>>
>> [IO.File]::WriteAllText(
>>     $model,
>>     $patched,
>>     [Text.UTF8Encoding]::new($false)
>> )
pDataRoot matches:  0
pBuildRoot matches: 0
STOP: parameter replacement population is not exactly 1 + 1.
At line:23 char:5
+     throw "STOP: parameter replacement population is not exactly 1 +  ...
+     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (STOP: parameter... exactly 1 + 1.:String) [], RuntimeException
    + FullyQualifiedErrorId : STOP: parameter replacement population is not exactly 1 + 1.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a92cca82-44c8-49b1-8c0b-da2d9f4b86f9"></a>
## Assistant · C091-M00130

C091-M00130 · 2026-08-19T20:46:54.470333-04:00 · active path

Preceding visible parent: [C091-M00129](part-10.md#m-d6302927-6bbd-4532-a95e-f6c69a9f0774)

<!-- BEGIN_SOURCE_MESSAGE -->
Good stop. **Nothing was written to `model.bim`**: your script threw before `[IO.File]::WriteAllText(...)`. Also, the earlier assignments to `$m.model.expressions[...]` only changed the in-memory PowerShell object; they were never serialized.

The mismatch happened because `model.bim` stores the M expression as JSON text, so the raw file contains escaped inner quotes and backslashes such as:

```text
"expression": "\"S:\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]"
```

Your search strings omitted those JSON escapes. We also need to patch the two external parameter `.m` files so the external Power Query source and embedded `model.bim` remain in parity.

The audit permits exactly this kind of change: only `pDataRoot` and `pBuildRoot` may be changed to dedicated governed synthetic roots; other A1a source changes are prohibited. [export reference: filecite | turn16file5 | L69-L86]

## 1. First prove the failed attempt made no change

Run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

$model = Join-Path $work `
    "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$before = Join-Path $return `
    "E00_MODEL_BIM_PRE_UNC_PARAMETER_PATCH.bim"

$currentHash = (
    Get-FileHash $model -Algorithm SHA256
).Hash.ToLowerInvariant()

$beforeHash = (
    Get-FileHash $before -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    model_current_sha256 = $currentHash
    preserved_before_sha256 = $beforeHash
    unchanged = ($currentHash -ceq $beforeHash)
} | Format-List

if ($currentHash -cne $beforeHash) {
    throw "STOP: model.bim changed during the failed replacement attempt."
}

Write-Host "FAILED PATCH ATTEMPT NONMUTATION PASS."
```

Expected:

```text
unchanged : True
FAILED PATCH ATTEMPT NONMUTATION PASS.
```

Preserve the failed attempt too:

```powershell
@'
A1B UNC PARAMETER PATCH TOOLING OBSERVATION

Date: 2026-08-19

Operation:
Attempted raw model.bim replacement of pDataRoot and pBuildRoot from S:\ paths
to the dedicated localhost SMB root.

Observed condition:
The raw replacement population returned 0 matches for each parameter because
the search strings did not account for model.bim JSON escaping of the embedded
Power Query M expression.

The script stopped before File.WriteAllText executed.

No model.bim write occurred.
No external Power Query parameter file was changed.
No Desktop refresh occurred.
No Close & Apply occurred.
No semantic processing occurred.

Follow-up:
Correct the raw JSON match strings, patch exactly the two authorized parameter
definitions and their external .m counterparts, verify parity, and rerun the
static A1b boundary.
'@ |
    Set-Content `
        -LiteralPath "$return\E00_UNC_PARAMETER_PATCH_TOOLING_OBSERVATION.txt" `
        -Encoding utf8
```

---

# 2. Inspect the four governed parameter files before changing them

Run:

```powershell
$dataM = Join-Path $work "power_query\parameters\pDataRoot.m"
$buildM = Join-Path $work "power_query\parameters\pBuildRoot.m"

Write-Host "===== pDataRoot.m ====="
Get-Content -LiteralPath $dataM

Write-Host ""
Write-Host "===== pBuildRoot.m ====="
Get-Content -LiteralPath $buildM
```

You should see approximately:

```text
"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
```

and:

```text
"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
```

If they show something materially different, stop and paste the output.

---

# 3. Preserve all four before-state identities

```powershell
$patchRoot = Join-Path $return "E00_UNC_PARAMETER_PATCH"
$beforeRoot = Join-Path $patchRoot "before"
$afterRoot  = Join-Path $patchRoot "after"

New-Item -ItemType Directory -Path $beforeRoot -Force | Out-Null
New-Item -ItemType Directory -Path $afterRoot  -Force | Out-Null

Copy-Item -LiteralPath $model  -Destination "$beforeRoot\model.bim"     -Force
Copy-Item -LiteralPath $dataM  -Destination "$beforeRoot\pDataRoot.m"  -Force
Copy-Item -LiteralPath $buildM -Destination "$beforeRoot\pBuildRoot.m" -Force

$beforeIdentities = @(
    $model,
    $dataM,
    $buildM
) | ForEach-Object {
    [pscustomobject]@{
        path = $_
        bytes = (Get-Item -LiteralPath $_).Length
        sha256 = (
            Get-FileHash -LiteralPath $_ -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$beforeIdentities |
    Export-Csv `
        -LiteralPath "$patchRoot\BEFORE_SHA256.csv" `
        -NoTypeInformation `
        -Encoding utf8

$beforeIdentities | Format-Table -AutoSize
```

---

# 4. Perform the exact bounded patch

Use this block exactly:

```powershell
$uncRoot  = "\\localhost\MSBF_PBI_A1B_SYNTHETIC"
$uncPbi   = "$uncRoot\pbi"
$uncBuild = "$uncRoot\build"

# ------------------------------------------------------------------
# A. Patch the external Power Query parameter definitions.
# ------------------------------------------------------------------

$expectedDataExternal =
    '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'

$expectedBuildExternal =
    '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'

$newDataExternal =
    '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'

$newBuildExternal =
    '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'

$dataRawExternal  = [IO.File]::ReadAllText($dataM)
$buildRawExternal = [IO.File]::ReadAllText($buildM)

if ($dataRawExternal.Trim() -cne $expectedDataExternal) {
    throw "STOP: external pDataRoot.m does not match the expected S:\ baseline."
}

if ($buildRawExternal.Trim() -cne $expectedBuildExternal) {
    throw "STOP: external pBuildRoot.m does not match the expected S:\ baseline."
}

# ------------------------------------------------------------------
# B. Prepare the exact raw JSON values used inside model.bim.
# ------------------------------------------------------------------

$raw = [IO.File]::ReadAllText($model)

$oldDataJson =
    '\"S:\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'

$newDataJson =
    '\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'

$oldBuildJson =
    '\"S:\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'

$newBuildJson =
    '\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'

$dataMatches = (
    [regex]::Matches(
        $raw,
        [regex]::Escape($oldDataJson)
    )
).Count

$buildMatches = (
    [regex]::Matches(
        $raw,
        [regex]::Escape($oldBuildJson)
    )
).Count

Write-Host "model.bim pDataRoot matches: " $dataMatches
Write-Host "model.bim pBuildRoot matches:" $buildMatches

if ($dataMatches -ne 1 -or $buildMatches -ne 1) {
    throw "STOP: expected exactly one embedded pDataRoot and one pBuildRoot value."
}

# ------------------------------------------------------------------
# C. Build all three changed files in memory before writing anything.
# ------------------------------------------------------------------

$patchedModel = $raw.Replace($oldDataJson, $newDataJson)
$patchedModel = $patchedModel.Replace($oldBuildJson, $newBuildJson)

# Validate patched JSON before committing it.
$null = $patchedModel | ConvertFrom-Json

# ------------------------------------------------------------------
# D. Commit exactly three governed files.
# ------------------------------------------------------------------

[IO.File]::WriteAllText(
    $dataM,
    $newDataExternal + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false)
)

[IO.File]::WriteAllText(
    $buildM,
    $newBuildExternal + [Environment]::NewLine,
    [Text.UTF8Encoding]::new($false)
)

[IO.File]::WriteAllText(
    $model,
    $patchedModel,
    [Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "UNC parameter patch committed."
```

Expected match population:

```text
model.bim pDataRoot matches:  1
model.bim pBuildRoot matches: 1
UNC parameter patch committed.
```

This does **not** reserialize the whole BIM; it changes only the exact two embedded parameter values.

---

# 5. Verify the new parameter values and external/embedded parity

Run:

```powershell
$modelObj = Get-Content -LiteralPath $model -Raw |
    ConvertFrom-Json

$embedded = @(
    $modelObj.model.expressions |
    Where-Object {
        $_.name -in @("pDataRoot","pBuildRoot")
    } |
    Sort-Object name |
    Select-Object name,expression
)

$embedded | Format-Table -AutoSize

Write-Host ""
Write-Host "===== external pDataRoot ====="
Get-Content -LiteralPath $dataM

Write-Host ""
Write-Host "===== external pBuildRoot ====="
Get-Content -LiteralPath $buildM
```

Required embedded results:

```text
pBuildRoot  "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [...]
pDataRoot   "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [...]
```

Then prove exact semantic parity:

```powershell
$embeddedData = string (historical reference: `
    $modelObj.model.expressions |
    Where-Object { $_.name -ceq "pDataRoot" }
`; referenced bytes not established here).expression

$embeddedBuild = string (historical reference: `
    $modelObj.model.expressions |
    Where-Object { $_.name -ceq "pBuildRoot" }
`; referenced bytes not established here).expression

$externalData = (
    [IO.File]::ReadAllText($dataM)
).Trim()

$externalBuild = (
    [IO.File]::ReadAllText($buildM)
).Trim()

$parity = @(
    [pscustomobject]@{
        parameter = "pDataRoot"
        embedded = $embeddedData
        external = $externalData
        exact_match = ($embeddedData -ceq $externalData)
    },
    [pscustomobject]@{
        parameter = "pBuildRoot"
        embedded = $embeddedBuild
        external = $externalBuild
        exact_match = ($embeddedBuild -ceq $externalBuild)
    }
)

$parity | Format-Table -AutoSize

$parity |
    Export-Csv `
        -LiteralPath "$patchRoot\PARAMETER_EMBEDDED_EXTERNAL_PARITY.csv" `
        -NoTypeInformation `
        -Encoding utf8

if (@($parity | Where-Object { -not $_.exact_match }).Count -gt 0) {
    throw "STOP: embedded/external parameter parity failed."
}

Write-Host "PARAMETER PARITY PASS."
```

---

# 6. Capture exact before/after hashes and limit the changed population

```powershell
Copy-Item -LiteralPath $model  -Destination "$afterRoot\model.bim"     -Force
Copy-Item -LiteralPath $dataM  -Destination "$afterRoot\pDataRoot.m"  -Force
Copy-Item -LiteralPath $buildM -Destination "$afterRoot\pBuildRoot.m" -Force

$afterIdentities = @(
    $model,
    $dataM,
    $buildM
) | ForEach-Object {
    [pscustomobject]@{
        path = $_
        bytes = (Get-Item -LiteralPath $_).Length
        sha256 = (
            Get-FileHash -LiteralPath $_ -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$afterIdentities |
    Export-Csv `
        -LiteralPath "$patchRoot\AFTER_SHA256.csv" `
        -NoTypeInformation `
        -Encoding utf8

$afterIdentities | Format-Table -AutoSize
```

Also write a bounded change record:

```powershell
[pscustomobject]@{
    event = "A1B_DEDICATED_UNC_PARAMETER_PATCH"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    authorization_basis = "PBI-F-004_A1B_DEDICATED_SYNTHETIC_ROOT"

    pDataRoot_before = "S:\pbi"
    pDataRoot_after = "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi"

    pBuildRoot_before = "S:\build"
    pBuildRoot_after = "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build"

    changed_external_m_files = 2
    changed_embedded_parameter_values = 2
    whole_bim_reserialization = $false

    table_count_change = 0
    relationship_count_change = 0
    query_count_change = 0
    measure_count_change = 0
    page_change = 0
    visual_change = 0

    refresh_executed = $false
    close_apply_executed = $false

    status = "PATCHED_PENDING_STATIC_BOUNDARY_REVERIFY"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$patchRoot\UNC_PARAMETER_PATCH_CONTROL.json" `
        -Encoding utf8
```

---

# 7. Re-run the static A1b 32/32/79/60 verifier

The package runbook requires a pre-refresh boundary check before any model processing. [export reference: filecite | turn17file0 | L26-L39]

Run:

```powershell
& "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath "$return\E00_A1B_PRE_REFRESH_BOUNDARY_AFTER_UNC_PATCH.txt"
```

Required state remains:

```text
tables                    32
relationships             32
power_query_objects       79
measures                  60

a1b_tables                18
a1b_relationships         26
a1b_power_query_objects   32
a1b_measures              60

technical_shell_pages      1
visuals                    0

inactive_relationships:
REL-076 only

bidirectional_relationships:
none

scenario_code_relationships:
none
```

And critically:

```text
pDataRoot  → \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
pBuildRoot → \\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

**If this verifier does not PASS, stop. Do not reopen Desktop.**

---

# 8. Reopen Desktop

Assuming the boundary verifier passes, open:

```text
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

Do **not** click a Refresh banner.

Go directly to:

**Home → Transform data**

Confirm:

```text
Queries [79]
```

Then select:

```text
stg_POWER_BI_DATA_CATALOG
```

At this point Power Query should try to resolve:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
```

rather than `S:\` or `C:\`.

---

# 9. Register and capture the UNC privacy source

If Power BI raises:

```text
Information is required about data privacy
```

choose **Continue**.

For this bounded execution, set the dedicated synthetic UNC source to:

```text
Public
```

That is permitted by Audit only because the source is an isolated, fully inventoried synthetic root; broad `C:\ Public` and globally ignoring privacy remain prohibited. [export reference: filecite | turn16file3 | L188-L201]

If Power BI presents the two paths separately:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi
\\localhost\MSBF_PBI_A1B_SYNTHETIC\build
```

set both consistently to `Public`.

If it recognizes only the parent:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC
```

that is also acceptable because that parent contains only the inventoried `pbi` and `build` synthetic directories.

Do **not** select or modify `C:\`.

Then open:

**Data source settings**

Capture the exact UNC source entry and privacy classification as:

```text
E00_PRIVACY_DATA_SOURCE_SETTINGS.png
```

We need the screenshot to visibly establish a boundary beginning with:

```text
\\localhost\MSBF_PBI_A1B_SYNTHETIC
```

—not `C:\`.

---

# 10. Create the privacy attestation from the actual UI scope

Do not run this until you know whether Desktop registered the parent root or the two subroots.

If it registers the **parent UNC root**, use:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    source_scope = "\\localhost\MSBF_PBI_A1B_SYNTHETIC"
    privacy_level = "Public"

    physical_backing_root =
        "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\synthetic_root"

    isolated_synthetic_root_only = $true
    contains_unrelated_personal_or_production_data = $false

    global_privacy_enforcement_enabled = $true
    ignore_privacy_levels = $false
    fast_combine_enabled = $false

    pDataRoot = "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi"
    pBuildRoot = "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build"

    screenshot_data_source_settings =
        "E00_PRIVACY_DATA_SOURCE_SETTINGS.png"

    screenshot_global_privacy =
        "E00_PRIVACY_GLOBAL_ENFORCEMENT.png"

    status = "PASS"
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$return\E00_PRIVACY_ATTESTATION.json" `
        -Encoding utf8
```

If Desktop shows two distinct subroots instead, send me the screenshot first and we will make the attestation match the physical UI exactly.

---

# 11. Re-capture Desktop identity after reopen

Because this will be a new Desktop process, re-run your successful native identity capture. The evidence should correspond to the actual process used for the eventual A1b refresh.

Use the same native CIM block that worked before and overwrite:

```text
E00_POWER_BI_DESKTOP_PROCESS_IDENTITY.json
```

with the new process ID while retaining:

```text
file_version      2.156.951.0
resolved_version  2.156.951.0
identity_status   PASS
```

The A1b audit explicitly requires Desktop About/version and active process/executable identity before first refresh. [export reference: filecite | turn16file3 | L203-L207]

---

# 12. Run the formal pre-refresh evidence gate

Only after all of these exist:

```text
E00_PRIVACY_GLOBAL_ENFORCEMENT.png
E00_PRIVACY_DATA_SOURCE_SETTINGS.png
E00_PRIVACY_ATTESTATION.json

E00_POWER_BI_DESKTOP_ABOUT.png
E00_POWER_BI_DESKTOP_PROCESS_IDENTITY.json

E00_SYNTHETIC_ROOT_MAPPING.json
E00_A1A_BASELINE_PREFLIGHT.json
E00_A1B_PRE_REFRESH_BOUNDARY.json
```

run:

```powershell
& "$work\tools\Verify-A1bPreRefreshEvidenceGate.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath "$return\E00_A1B_PRE_REFRESH_EVIDENCE_GATE.txt"
```

The runbook makes this gate mandatory before Refresh Preview, Close & Apply, or Desktop refresh. [export reference: filecite | turn17file0 | L26-L39]

We need:

```text
PASS
```

No waiver.

---

# 13. Only after PASS: permit Refresh Preview

If—and only if—the evidence gate passes, the first allowed engine action becomes:

**Power Query Editor → Refresh Preview → Refresh All**

Then:

```text
Stop on any query error.
Do not Close & Apply until all 79 queries evaluate successfully.
```

The authorized sequence is explicitly: successful Power Query evaluation first, then Close & Apply/model processing, then Desktop data refresh. [export reference: filecite | turn17file0 | L51-L67]

### Where you are right now

```text
SMB share                            PASS
Share access                         READ-ONLY
UNC reachability                     PASS
Failed patch                         NONMUTATING
Correct UNC patch                    NEXT
32/32/79/60 reverification           AFTER PATCH
Desktop reopen                       AFTER STATIC PASS
UNC privacy registration             AFTER REOPEN
Privacy attestation                  AFTER UI EVIDENCE
Pre-refresh evidence gate            AFTER ALL ABOVE
Refresh Preview                      STILL PROHIBITED
```

Run **Steps 1–7 first**. Send me the output from the corrected patch, parity test, and `Verify-A1bPreRefreshBoundary.ps1` before reopening Power BI.
<!-- END_SOURCE_MESSAGE -->


<a id="m-27f590b8-ae3f-413e-b531-8f96bcc7bdfb"></a>
## Andrew / user · C091-M00131

C091-M00131 · 2026-08-19T20:56:53.665000-04:00 · active path

Preceding visible parent: [C091-M00130](part-10.md#m-a92cca82-44c8-49b1-8c0b-da2d9f4b86f9)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\WINDOWS\system32> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
>> $return = Join-Path $work "evidence\local_engine_return"
>>
>> $model = Join-Path $work `
>>     "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"
>>
>> $before = Join-Path $return `
>>     "E00_MODEL_BIM_PRE_UNC_PARAMETER_PATCH.bim"
>>
>> $currentHash = (
>>     Get-FileHash $model -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> $beforeHash = (
>>     Get-FileHash $before -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> [pscustomobject]@{
>>     model_current_sha256 = $currentHash
>>     preserved_before_sha256 = $beforeHash
>>     unchanged = ($currentHash -ceq $beforeHash)
>> } | Format-List
>>
>> if ($currentHash -cne $beforeHash) {
>>     throw "STOP: model.bim changed during the failed replacement attempt."
>> }
>>
>> Write-Host "FAILED PATCH ATTEMPT NONMUTATION PASS."


model_current_sha256    : 43e5ccd3f48fe5e1125fe8d7a1278625ebfa08763b66b46708ec73276a2ae656
preserved_before_sha256 : 43e5ccd3f48fe5e1125fe8d7a1278625ebfa08763b66b46708ec73276a2ae656
unchanged               : True



FAILED PATCH ATTEMPT NONMUTATION PASS.
PS C:\WINDOWS\system32> @'
>> A1B UNC PARAMETER PATCH TOOLING OBSERVATION
>>
>> Date: 2026-08-19
>>
>> Operation:
>> Attempted raw model.bim replacement of pDataRoot and pBuildRoot from S:\ paths
>> to the dedicated localhost SMB root.
>>
>> Observed condition:
>> The raw replacement population returned 0 matches for each parameter because
>> the search strings did not account for model.bim JSON escaping of the embedded
>> Power Query M expression.
>>
>> The script stopped before File.WriteAllText executed.
>>
>> No model.bim write occurred.
>> No external Power Query parameter file was changed.
>> No Desktop refresh occurred.
>> No Close & Apply occurred.
>> No semantic processing occurred.
>>
>> Follow-up:
>> Correct the raw JSON match strings, patch exactly the two authorized parameter
>> definitions and their external .m counterparts, verify parity, and rerun the
>> static A1b boundary.
>> '@ |
>>     Set-Content `
>>         -LiteralPath "$return\E00_UNC_PARAMETER_PATCH_TOOLING_OBSERVATION.txt" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> $dataM = Join-Path $work "power_query\parameters\pDataRoot.m"
>> $buildM = Join-Path $work "power_query\parameters\pBuildRoot.m"
>>
>> Write-Host "===== pDataRoot.m ====="
>> Get-Content -LiteralPath $dataM
>>
>> Write-Host ""
>> Write-Host "===== pBuildRoot.m ====="
>> Get-Content -LiteralPath $buildM
===== pDataRoot.m =====
"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

===== pBuildRoot.m =====
"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
PS C:\WINDOWS\system32> $patchRoot = Join-Path $return "E00_UNC_PARAMETER_PATCH"
>> $beforeRoot = Join-Path $patchRoot "before"
>> $afterRoot  = Join-Path $patchRoot "after"
>>
>> New-Item -ItemType Directory -Path $beforeRoot -Force | Out-Null
>> New-Item -ItemType Directory -Path $afterRoot  -Force | Out-Null
>>
>> Copy-Item -LiteralPath $model  -Destination "$beforeRoot\model.bim"     -Force
>> Copy-Item -LiteralPath $dataM  -Destination "$beforeRoot\pDataRoot.m"  -Force
>> Copy-Item -LiteralPath $buildM -Destination "$beforeRoot\pBuildRoot.m" -Force
>>
>> $beforeIdentities = @(
>>     $model,
>>     $dataM,
>>     $buildM
>> ) | ForEach-Object {
>>     [pscustomobject]@{
>>         path = $_
>>         bytes = (Get-Item -LiteralPath $_).Length
>>         sha256 = (
>>             Get-FileHash -LiteralPath $_ -Algorithm SHA256
>>         ).Hash.ToLowerInvariant()
>>     }
>> }
>>
>> $beforeIdentities |
>>     Export-Csv `
>>         -LiteralPath "$patchRoot\BEFORE_SHA256.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> $beforeIdentities | Format-Table -AutoSize

path                                                                                                         bytes sha2
                                                                                                                   56
----                                                                                                         ----- ----
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim 463726 4...
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\power_query\parameters\pDataRoot.m                                     82 d...
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\power_query\parameters\pBuildRoot.m                                    84 f...


PS C:\WINDOWS\system32> $uncRoot  = "\\localhost\MSBF_PBI_A1B_SYNTHETIC"
>> $uncPbi   = "$uncRoot\pbi"
>> $uncBuild = "$uncRoot\build"
>>
>> # ------------------------------------------------------------------
>> # A. Patch the external Power Query parameter definitions.
>> # ------------------------------------------------------------------
>>
>> $expectedDataExternal =
>>     '"S:\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>>
>> $expectedBuildExternal =
>>     '"S:\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>>
>> $newDataExternal =
>>     '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>>
>> $newBuildExternal =
>>     '"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]'
>>
>> $dataRawExternal  = [IO.File]::ReadAllText($dataM)
>> $buildRawExternal = [IO.File]::ReadAllText($buildM)
>>
>> if ($dataRawExternal.Trim() -cne $expectedDataExternal) {
>>     throw "STOP: external pDataRoot.m does not match the expected S:\ baseline."
>> }
>>
>> if ($buildRawExternal.Trim() -cne $expectedBuildExternal) {
>>     throw "STOP: external pBuildRoot.m does not match the expected S:\ baseline."
>> }
>>
>> # ------------------------------------------------------------------
>> # B. Prepare the exact raw JSON values used inside model.bim.
>> # ------------------------------------------------------------------
>>
>> $raw = [IO.File]::ReadAllText($model)
>>
>> $oldDataJson =
>>     '\"S:\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'
>>
>> $newDataJson =
>>     '\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'
>>
>> $oldBuildJson =
>>     '\"S:\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'
>>
>> $newBuildJson =
>>     '\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]'
>>
>> $dataMatches = (
>>     [regex]::Matches(
>>         $raw,
>>         [regex]::Escape($oldDataJson)
>>     )
>> ).Count
>>
>> $buildMatches = (
>>     [regex]::Matches(
>>         $raw,
>>         [regex]::Escape($oldBuildJson)
>>     )
>> ).Count
>>
>> Write-Host "model.bim pDataRoot matches: " $dataMatches
>> Write-Host "model.bim pBuildRoot matches:" $buildMatches
>>
>> if ($dataMatches -ne 1 -or $buildMatches -ne 1) {
>>     throw "STOP: expected exactly one embedded pDataRoot and one pBuildRoot value."
>> }
>>
>> # ------------------------------------------------------------------
>> # C. Build all three changed files in memory before writing anything.
>> # ------------------------------------------------------------------
>>
>> $patchedModel = $raw.Replace($oldDataJson, $newDataJson)
>> $patchedModel = $patchedModel.Replace($oldBuildJson, $newBuildJson)
>>
>> # Validate patched JSON before committing it.
>> $null = $patchedModel | ConvertFrom-Json
>>
>> # ------------------------------------------------------------------
>> # D. Commit exactly three governed files.
>> # ------------------------------------------------------------------
>>
>> [IO.File]::WriteAllText(
>>     $dataM,
>>     $newDataExternal + [Environment]::NewLine,
>>     [Text.UTF8Encoding]::new($false)
>> )
>>
>> [IO.File]::WriteAllText(
>>     $buildM,
>>     $newBuildExternal + [Environment]::NewLine,
>>     [Text.UTF8Encoding]::new($false)
>> )
>>
>> [IO.File]::WriteAllText(
>>     $model,
>>     $patchedModel,
>>     [Text.UTF8Encoding]::new($false)
>> )
>>
>> Write-Host ""
>> Write-Host "UNC parameter patch committed."
model.bim pDataRoot matches:  1
model.bim pBuildRoot matches: 1

UNC parameter patch committed.
PS C:\WINDOWS\system32> $modelObj = Get-Content -LiteralPath $model -Raw |
>>     ConvertFrom-Json
>>
>> $embedded = @(
>>     $modelObj.model.expressions |
>>     Where-Object {
>>         $_.name -in @("pDataRoot","pBuildRoot")
>>     } |
>>     Sort-Object name |
>>     Select-Object name,expression
>> )
>>
>> $embedded | Format-Table -AutoSize
>>
>> Write-Host ""
>> Write-Host "===== external pDataRoot ====="
>> Get-Content -LiteralPath $dataM
>>
>> Write-Host ""
>> Write-Host "===== external pBuildRoot ====="
>> Get-Content -LiteralPath $buildM

name       expression
----       ----------
pBuildRoot "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequ...
pDataRoot  "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequir...



===== external pDataRoot =====
"\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]

===== external pBuildRoot =====
"\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]
PS C:\WINDOWS\system32> $embeddedData = string (historical reference: `
>>     $modelObj.model.expressions |
>>     Where-Object { $_.name -ceq "pDataRoot" }
>> `; referenced bytes not established here).expression
>>
>> $embeddedBuild = string (historical reference: `
>>     $modelObj.model.expressions |
>>     Where-Object { $_.name -ceq "pBuildRoot" }
>> `; referenced bytes not established here).expression
>>
>> $externalData = (
>>     [IO.File]::ReadAllText($dataM)
>> ).Trim()
>>
>> $externalBuild = (
>>     [IO.File]::ReadAllText($buildM)
>> ).Trim()
>>
>> $parity = @(
>>     [pscustomobject]@{
>>         parameter = "pDataRoot"
>>         embedded = $embeddedData
>>         external = $externalData
>>         exact_match = ($embeddedData -ceq $externalData)
>>     },
>>     [pscustomobject]@{
>>         parameter = "pBuildRoot"
>>         embedded = $embeddedBuild
>>         external = $externalBuild
>>         exact_match = ($embeddedBuild -ceq $externalBuild)
>>     }
>> )
>>
>> $parity | Format-Table -AutoSize
>>
>> $parity |
>>     Export-Csv `
>>         -LiteralPath "$patchRoot\PARAMETER_EMBEDDED_EXTERNAL_PARITY.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> if (@($parity | Where-Object { -not $_.exact_match }).Count -gt 0) {
>>     throw "STOP: embedded/external parameter parity failed."
>> }
>>
>> Write-Host "PARAMETER PARITY PASS."

parameter  embedded
---------  --------
pDataRoot  "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequir...
pBuildRoot "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequ...


PARAMETER PARITY PASS.
PS C:\WINDOWS\system32> Copy-Item -LiteralPath $model  -Destination "$afterRoot\model.bim"     -Force
>> Copy-Item -LiteralPath $dataM  -Destination "$afterRoot\pDataRoot.m"  -Force
>> Copy-Item -LiteralPath $buildM -Destination "$afterRoot\pBuildRoot.m" -Force
>>
>> $afterIdentities = @(
>>     $model,
>>     $dataM,
>>     $buildM
>> ) | ForEach-Object {
>>     [pscustomobject]@{
>>         path = $_
>>         bytes = (Get-Item -LiteralPath $_).Length
>>         sha256 = (
>>             Get-FileHash -LiteralPath $_ -Algorithm SHA256
>>         ).Hash.ToLowerInvariant()
>>     }
>> }
>>
>> $afterIdentities |
>>     Export-Csv `
>>         -LiteralPath "$patchRoot\AFTER_SHA256.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> $afterIdentities | Format-Table -AutoSize

path                                                                                                         bytes sha2
                                                                                                                   56
----                                                                                                         ----- ----
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim 463796 b...
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\power_query\parameters\pDataRoot.m                                    115 2...
C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\power_query\parameters\pBuildRoot.m                                   117 1...


PS C:\WINDOWS\system32> [pscustomobject]@{
>>     event = "A1B_DEDICATED_UNC_PARAMETER_PATCH"
>>     captured_local = (Get-Date).ToString("o")
>>     captured_utc = (Get-Date).ToUniversalTime().ToString("o")
>>
>>     authorization_basis = "PBI-F-004_A1B_DEDICATED_SYNTHETIC_ROOT"
>>
>>     pDataRoot_before = "S:\pbi"
>>     pDataRoot_after = "\\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi"
>>
>>     pBuildRoot_before = "S:\build"
>>     pBuildRoot_after = "\\localhost\MSBF_PBI_A1B_SYNTHETIC\build"
>>
>>     changed_external_m_files = 2
>>     changed_embedded_parameter_values = 2
>>     whole_bim_reserialization = $false
>>
>>     table_count_change = 0
>>     relationship_count_change = 0
>>     query_count_change = 0
>>     measure_count_change = 0
>>     page_change = 0
>>     visual_change = 0
>>
>>     refresh_executed = $false
>>     close_apply_executed = $false
>>
>>     status = "PATCHED_PENDING_STATIC_BOUNDARY_REVERIFY"
>> } |
>>     ConvertTo-Json -Depth 6 |
>>     Set-Content `
>>         -LiteralPath "$patchRoot\UNC_PARAMETER_PATCH_CONTROL.json" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> & "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
>>     -PackageRoot $work *>&1 |
>>     Tee-Object `
>>         -FilePath "$return\E00_A1B_PRE_REFRESH_BOUNDARY_AFTER_UNC_PATCH.txt"
& : File C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819\tools\Verify-A1bPreRefreshBoundary.ps1 cannot be loaded because
running scripts is disabled on this system. For more information, see about_Execution_Policies at
https:/go.microsoft.com/fwlink/?LinkID=135170.
At line:1 char:3
+ & "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
<!-- END_SOURCE_MESSAGE -->
