# MSBF - Power BI Executive Portfolio Intelligence

Part 04 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-03.md)
[Next part](part-05.md)

<a id="m-66970bec-2389-4727-a9f9-7d4a2df37375"></a>
## Assistant · C091-M00059

C091-M00059 · 2026-08-19T09:16:34.791351-04:00 · active path

Preceding visible parent: [C091-M00058](part-03.md#m-d6189681-97c7-4f4b-b7ee-d1f56ef2ac1f)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Your authorization is sufficiently bounded to proceed **inside the derived A1a working copy only**. The screenshots physically establish both failure branches:

```text
stg_/Dim branch:
Expression.Error: The value isn't a single-character string.
Value=\\

Fact branch:
BUILD_CATALOG_READ: Power BI build catalog could not be read.
Path=[Error]
```

This is consistent with a common path-literal defect in the three shared M definitions. The existing static package verified all 47 definitions were present and lexically balanced, but that did not prove Power Query runtime behavior. [export reference: filecite | turn10file0 | L43-L67]

We will preserve the failed execution, close without applying it, patch **only** the three authorized definitions in both their external `.m` copies and their embedded `model.bim` expressions, capture exact before/after hashes and changed lines, rerun static boundary checks, and then resume Desktop. The audit continues to permit A1a execution while prohibiting A1b and any expansion of the semantic footprint. [export reference: filecite | turn9file0 | L102-L123]

## 1. Preserve the two screenshots and failed-refresh record

Leave Power Query open for the moment. Open a separate **PowerShell 7** window and run this block.

It will give you two file-selection windows so you do not have to know the screenshot paths manually.

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

New-Item -ItemType Directory -Force -Path $ev | Out-Null

Add-Type -AssemblyName System.Windows.Forms

function Select-EvidenceImage {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,

        [Parameter(Mandatory=$true)]
        [string]$DestinationName
    )

    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = $Title
    $dialog.Filter = "PNG images (*.png)|*.png|JPEG images (*.jpg;*.jpeg)|*.jpg;*.jpeg|All files (*.*)|*.*"
    $dialog.Multiselect = $false

    $result = $dialog.ShowDialog()

    if ($result -ne [System.Windows.Forms.DialogResult]::OK) {
        throw "Screenshot selection cancelled. Stop."
    }

    $destination = Join-Path $ev $DestinationName

    Copy-Item `
        -LiteralPath $dialog.FileName `
        -Destination $destination `
        -Force

    return $destination
}

$stgScreenshot = Select-EvidenceImage `
    -Title "Select screenshot showing stg_POWER_BI_DATA_CATALOG single-character error" `
    -DestinationName "E02_REFRESH_ATTEMPT1_STG_CATALOG_ERROR.png"

$factScreenshot = Select-EvidenceImage `
    -Title "Select screenshot showing Fact BUILD_CATALOG_READ error" `
    -DestinationName "E02_REFRESH_ATTEMPT1_FACT_BUILD_CATALOG_ERROR.png"

$failureRecord = [ordered]@{
    schema_version = "1.0"
    event = "A1A_POWER_QUERY_REFRESH_PREVIEW_ATTEMPT_1"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")

    result = "FAILED_COMMON_M_PATH_LITERAL_DEFECT"

    governed_state = [ordered]@{
        semantic_tables = 14
        relationships = 6
        power_query_queries = 47
        explicit_measures = 0
        substantive_report_pages = 0
        technical_shell_pages = 1
        visual_objects = 0
        a1b_objects = 0
    }

    execution_state = [ordered]@{
        refresh_preview_attempted = $true
        refresh_preview_succeeded = $false
        apply_changes_performed = $false
        close_and_apply_performed = $false
        semantic_model_refresh_performed = $false
    }

    root_failure = [ordered]@{
        upstream_query = "stg_POWER_BI_DATA_CATALOG"
        error_type = "Expression.Error"
        error_text = "The value isn't a single-character string."
        error_value = "\\"
    }

    downstream_failure = [ordered]@{
        error_code = "BUILD_CATALOG_READ"
        error_text = "Power BI build catalog could not be read."
        path_state = "[Error]"
    }

    affected_shared_definitions = @(
        "stg_POWER_BI_DATA_CATALOG",
        "fxReadCatalogedCsv",
        "fxReadBuildCsv"
    )

    source_owner_authorization = [ordered]@{
        authorized = $true
        authorization_date = "2026-08-19"
        scope = "THREE_DEFINITION_A1A_M_RUNTIME_HOTFIX_DERIVED_WORKING_COPY_ONLY"
        semantic_count_change_authorized = $false
        business_logic_change_authorized = $false
        a1b_authorized = $false
        audit_notification_required = $true
    }

    evidence_files = @(
        [IO.Path]::GetFileName($stgScreenshot),
        [IO.Path]::GetFileName($factScreenshot)
    )
}

$failureRecord |
    ConvertTo-Json -Depth 8 |
    Set-Content `
        -LiteralPath "$ev\E02_REFRESH_ATTEMPT1_FAILURE.json" `
        -Encoding utf8

@(
    $stgScreenshot
    $factScreenshot
) |
    ForEach-Object {
        [pscustomobject]@{
            file = [IO.Path]::GetFileName($_)
            bytes = (Get-Item -LiteralPath $_).Length
            sha256 = (
                Get-FileHash -LiteralPath $_ -Algorithm SHA256
            ).Hash.ToLowerInvariant()
        }
    } |
    Export-Csv `
        -LiteralPath "$ev\E02_REFRESH_ATTEMPT1_SCREENSHOT_HASHES.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host ""
Write-Host "Failed-refresh evidence preserved."
Write-Host "STG evidence:  $stgScreenshot"
Write-Host "Fact evidence: $factScreenshot"
```

If the screenshots do not currently exist as files on your PC, use **Snipping Tool → Save As** for each screenshot first, then run the block.

## 2. Close the failed Power Query execution without applying it

Now go back to Power Query Editor.

Click its upper-right **X**.

When asked about pending changes, choose:

```text
Discard changes
```

Do **not** choose Apply.

Back in Desktop, close Desktop.

If it asks whether to save the project, choose:

```text
Don't Save
```

This preserves the previously verified technical-shell baseline and prevents the failed refresh state from being committed.

Once Desktop is fully closed, continue below.

---

# 3. Run the controlled three-definition hotfix

This next block does all of the following automatically:

- refuses to run if Power BI Desktop is still open;
- verifies all three target `.m` files exist;
- preserves exact pre-hotfix copies;
- records pre-hotfix SHA-256 values;
- changes only the malformed Windows backslash literals;
- patches the **matching embedded M expressions in `model.bim` without reserializing the whole BIM**;
- verifies each embedded expression had exactly one match;
- records all changed line numbers and before/after text;
- records post-hotfix hashes;
- proves no fourth external M definition changed;
- produces an evidence manifest.

Run it as one block:

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

$modelPath = Join-Path $work `
    "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$targets = [ordered]@{
    "stg_POWER_BI_DATA_CATALOG" = Join-Path $work `
        "power_query\staging\stg_POWER_BI_DATA_CATALOG.m"

    "fxReadCatalogedCsv" = Join-Path $work `
        "power_query\functions\fxReadCatalogedCsv.m"

    "fxReadBuildCsv" = Join-Path $work `
        "power_query\functions\fxReadBuildCsv.m"
}

# ------------------------------------------------------------
# HARD PRECONDITIONS
# ------------------------------------------------------------

$pbiProcesses = @(
    Get-Process `
        -Name "PBIDesktop" `
        -ErrorAction SilentlyContinue
)

if ($pbiProcesses.Count -gt 0) {
    throw "Power BI Desktop is still running. Close Desktop before applying the hotfix."
}

if (-not (Test-Path -LiteralPath $modelPath)) {
    throw "model.bim not found: $modelPath"
}

foreach ($item in $targets.GetEnumerator()) {
    if (-not (Test-Path -LiteralPath $item.Value)) {
        throw "Target M file not found: $($item.Value)"
    }
}

$hotfixRoot = Join-Path $ev `
    "E03_M_RUNTIME_HOTFIX_R1"

$beforeRoot = Join-Path $hotfixRoot "before"
$afterRoot  = Join-Path $hotfixRoot "after"

New-Item -ItemType Directory -Force -Path $beforeRoot | Out-Null
New-Item -ItemType Directory -Force -Path $afterRoot  | Out-Null

# ------------------------------------------------------------
# RECORD FULL POWER-QUERY TREE HASHES BEFORE HOTFIX
# ------------------------------------------------------------

$allMFilesBefore = @(
    Get-ChildItem `
        -LiteralPath (Join-Path $work "power_query") `
        -File `
        -Recurse `
        -Filter "*.m" |
    Sort-Object FullName
)

$preTree = foreach ($file in $allMFilesBefore) {
    [pscustomobject]@{
        relative_path = $file.FullName.Substring($work.Length + 1)
        bytes = $file.Length
        sha256 = (
            Get-FileHash `
                -LiteralPath $file.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$preTree |
    Export-Csv `
        -LiteralPath "$hotfixRoot\POWER_QUERY_TREE_BEFORE.csv" `
        -NoTypeInformation `
        -Encoding utf8

# ------------------------------------------------------------
# COPY AND HASH TARGETS BEFORE
# ------------------------------------------------------------

$beforeHashes = @()

foreach ($item in $targets.GetEnumerator()) {

    $name = $item.Key
    $path = $item.Value

    Copy-Item `
        -LiteralPath $path `
        -Destination (Join-Path $beforeRoot "$name.m") `
        -Force

    $beforeHashes += [pscustomobject]@{
        object = $name
        artifact = "EXTERNAL_M"
        path = $path.Substring($work.Length + 1)
        sha256_before = (
            Get-FileHash `
                -LiteralPath $path `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

Copy-Item `
    -LiteralPath $modelPath `
    -Destination (Join-Path $beforeRoot "model.bim") `
    -Force

$modelHashBefore = (
    Get-FileHash `
        -LiteralPath $modelPath `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

# ------------------------------------------------------------
# EXACT M RUNTIME REPAIR FUNCTION
# ------------------------------------------------------------

function Repair-A1aMDefinition {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    $result = $Text

    switch ($Name) {

        "stg_POWER_BI_DATA_CATALOG" {

            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )

            $result = $result.Replace(
                '"\\data\\POWER_BI_DATA_CATALOG.csv"',
                '"\data\POWER_BI_DATA_CATALOG.csv"'
            )
        }

        "fxReadCatalogedCsv" {

            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )

            $result = $result.Replace(
                'Text.Replace(CatalogRow[package_path], "/", "\\")',
                'Text.Replace(CatalogRow[package_path], "/", "\")'
            )

            $result = $result.Replace(
                'Root & "\\" & RelativePath',
                'Root & "\" & RelativePath'
            )
        }

        "fxReadBuildCsv" {

            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )

            $result = $result.Replace(
                'Root & "\\" & Text.Replace(relativePath, "/", "\\")',
                'Root & "\" & Text.Replace(relativePath, "/", "\")'
            )
        }

        default {
            throw "Unexpected hotfix object: $Name"
        }
    }

    if ($result -ceq $Text) {
        throw "No text changed for $Name. Stop rather than applying an unproven patch."
    }

    return $result
}

# ------------------------------------------------------------
# BUILD EXACT BEFORE/AFTER DEFINITIONS
# ------------------------------------------------------------

$definitions = @{}

foreach ($item in $targets.GetEnumerator()) {

    $name = $item.Key
    $path = $item.Value

    $beforeText = [IO.File]::ReadAllText($path)
    $afterText  = Repair-A1aMDefinition `
        -Name $name `
        -Text $beforeText

    # Ensure malformed double-backslash form is actually removed
    # from the known path-construction expressions.
    if (
        $afterText.Contains('{"/", "\\"}') -or
        $afterText.Contains('Root & "\\"') -or
        $afterText.Contains('"/", "\\"')
    ) {
        throw "Malformed path literal remains in $name after proposed repair."
    }

    $definitions[$name] = [pscustomobject]@{
        before = $beforeText
        after  = $afterText
        path   = $path
    }
}

# ------------------------------------------------------------
# BUILD CHANGED-LINE EVIDENCE BEFORE WRITING
# ------------------------------------------------------------

$lineDiff = @()

foreach ($name in $targets.Keys) {

    $beforeLines = @(
        $definitions[$name].before -split "`r?`n"
    )

    $afterLines = @(
        $definitions[$name].after -split "`r?`n"
    )

    $max = [Math]::Max(
        $beforeLines.Count,
        $afterLines.Count
    )

    for ($i = 0; $i -lt $max; $i++) {

        $beforeLine = if ($i -lt $beforeLines.Count) {
            $beforeLines[$i]
        } else {
            $null
        }

        $afterLine = if ($i -lt $afterLines.Count) {
            $afterLines[$i]
        } else {
            $null
        }

        if ($beforeLine -cne $afterLine) {

            $lineDiff += [pscustomobject]@{
                object = $name
                line_number = $i + 1
                before = $beforeLine
                after = $afterLine
            }
        }
    }
}

# Exact expected changed-line population = 7
if ($lineDiff.Count -ne 7) {
    $lineDiff |
        Format-Table -AutoSize |
        Out-String |
        Write-Host

    throw "Expected exactly 7 changed M lines; observed $($lineDiff.Count). Stop."
}

$lineDiff |
    Export-Csv `
        -LiteralPath "$hotfixRoot\M_RUNTIME_EXACT_LINE_DIFF.csv" `
        -NoTypeInformation `
        -Encoding utf8

# ------------------------------------------------------------
# PATCH MODEL.BIM WITHOUT RE-SERIALIZING THE DOCUMENT
# ------------------------------------------------------------

$modelRaw = [IO.File]::ReadAllText($modelPath)

foreach ($name in $targets.Keys) {

    $beforeExpressionJson = [System.Text.Json.JsonSerializer]::Serialize(
        $definitions[$name].before
    )

    $afterExpressionJson = [System.Text.Json.JsonSerializer]::Serialize(
        $definitions[$name].after
    )

    $matchCount = (
        [regex]::Matches(
            $modelRaw,
            [regex]::Escape($beforeExpressionJson)
        )
    ).Count

    if ($matchCount -ne 1) {
        throw "Embedded model expression for $name matched $matchCount times; expected exactly 1."
    }

    $modelRaw = $modelRaw.Replace(
        $beforeExpressionJson,
        $afterExpressionJson
    )
}

# ------------------------------------------------------------
# WRITE EXTERNAL DEFINITIONS AND MODEL.BIM
# ------------------------------------------------------------

foreach ($name in $targets.Keys) {

    [IO.File]::WriteAllText(
        $definitions[$name].path,
        $definitions[$name].after,
        [Text.UTF8Encoding]::new($false)
    )

    [IO.File]::WriteAllText(
        (Join-Path $afterRoot "$name.m"),
        $definitions[$name].after,
        [Text.UTF8Encoding]::new($false)
    )
}

[IO.File]::WriteAllText(
    $modelPath,
    $modelRaw,
    [Text.UTF8Encoding]::new($false)
)

Copy-Item `
    -LiteralPath $modelPath `
    -Destination (Join-Path $afterRoot "model.bim") `
    -Force

# ------------------------------------------------------------
# VERIFY EMBEDDED EXPRESSIONS NOW MATCH EXTERNAL M
# ------------------------------------------------------------

$parsedModel = Get-Content `
    -LiteralPath $modelPath `
    -Raw |
    ConvertFrom-Json

foreach ($name in $targets.Keys) {

    $modelExpression = @(
        $parsedModel.model.expressions |
        Where-Object { $_.name -ceq $name }
    )

    if ($modelExpression.Count -ne 1) {
        throw "Expected one embedded expression named $name; found $($modelExpression.Count)."
    }

    $external = [IO.File]::ReadAllText(
        $targets[$name]
    )

    if ($modelExpression[0].expression -cne $external) {
        throw "Embedded model M does not exactly match external M for $name."
    }
}

# ------------------------------------------------------------
# RECORD AFTER HASHES
# ------------------------------------------------------------

$hashRows = @()

foreach ($name in $targets.Keys) {

    $path = $targets[$name]

    $before = @(
        $beforeHashes |
        Where-Object { $_.object -ceq $name }
    )[0]

    $hashRows += [pscustomobject]@{
        object = $name
        artifact = "EXTERNAL_M"
        relative_path = $path.Substring($work.Length + 1)
        sha256_before = $before.sha256_before
        sha256_after = (
            Get-FileHash `
                -LiteralPath $path `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        changed = $true
    }
}

$hashRows += [pscustomobject]@{
    object = "model.bim"
    artifact = "EMBEDDED_MODEL"
    relative_path = $modelPath.Substring($work.Length + 1)
    sha256_before = $modelHashBefore
    sha256_after = (
        Get-FileHash `
            -LiteralPath $modelPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    changed = $true
}

$hashRows |
    Export-Csv `
        -LiteralPath "$hotfixRoot\M_RUNTIME_BEFORE_AFTER_HASHES.csv" `
        -NoTypeInformation `
        -Encoding utf8

# ------------------------------------------------------------
# PROVE NO OTHER EXTERNAL M FILE CHANGED
# ------------------------------------------------------------

$postTree = foreach (
    $file in @(
        Get-ChildItem `
            -LiteralPath (Join-Path $work "power_query") `
            -File `
            -Recurse `
            -Filter "*.m" |
        Sort-Object FullName
    )
) {
    [pscustomobject]@{
        relative_path = $file.FullName.Substring($work.Length + 1)
        bytes = $file.Length
        sha256 = (
            Get-FileHash `
                -LiteralPath $file.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$postTree |
    Export-Csv `
        -LiteralPath "$hotfixRoot\POWER_QUERY_TREE_AFTER.csv" `
        -NoTypeInformation `
        -Encoding utf8

$treeComparison = foreach ($before in $preTree) {

    $after = @(
        $postTree |
        Where-Object {
            $_.relative_path -ceq $before.relative_path
        }
    )

    if ($after.Count -ne 1) {
        throw "Power Query tree object mismatch: $($before.relative_path)"
    }

    [pscustomobject]@{
        relative_path = $before.relative_path
        sha256_before = $before.sha256
        sha256_after = $after[0].sha256
        changed = (
            $before.sha256 -cne $after[0].sha256
        )
    }
}

$treeComparison |
    Export-Csv `
        -LiteralPath "$hotfixRoot\POWER_QUERY_TREE_CHANGE_CONTROL.csv" `
        -NoTypeInformation `
        -Encoding utf8

$changedExternalM = @(
    $treeComparison |
    Where-Object { $_.changed }
)

$expectedChangedPaths = @(
    $targets.Values |
    ForEach-Object {
        $_.Substring($work.Length + 1)
    }
)

if ($changedExternalM.Count -ne 3) {
    throw "Expected exactly 3 changed external M files; observed $($changedExternalM.Count)."
}

foreach ($changed in $changedExternalM) {

    if ($changed.relative_path -cnotin $expectedChangedPaths) {
        throw "Unauthorized external M change detected: $($changed.relative_path)"
    }
}

# ------------------------------------------------------------
# WRITE GOVERNANCE RECORD
# ------------------------------------------------------------

$governance = [ordered]@{
    schema_version = "1.0"
    hotfix_id = "A1A-M-RUNTIME-HF01"
    date = "2026-08-19"

    authority = [ordered]@{
        authority_type = "SOURCE_OWNER_EXPLICIT_AUTHORIZATION"
        scope = "THREE_DEFINITION_A1A_M_RUNTIME_HOTFIX_DERIVED_WORKING_COPY_ONLY"
        audit_notification_status = "PENDING_POST_ACTION_DISCLOSURE"
    }

    defect = [ordered]@{
        runtime = "POWER_QUERY_M"
        root_error = "Expression.Error: The value isn't a single-character string."
        malformed_value = "\\"
        cause = "Windows backslash represented as a two-character M string."
    }

    changed_definitions = @(
        "stg_POWER_BI_DATA_CATALOG",
        "fxReadCatalogedCsv",
        "fxReadBuildCsv"
    )

    boundaries = [ordered]@{
        tables_before = 14
        tables_after_expected = 14
        relationships_before = 6
        relationships_after_expected = 6
        queries_before = 47
        queries_after_expected = 47
        measures_before = 0
        measures_after_expected = 0
        substantive_pages = 0
        technical_shell_pages = 1
        visuals = 0
        a1b_objects = 0
        business_logic_changed = $false
        source_selection_changed = $false
        grain_changed = $false
        key_design_changed = $false
    }

    local_engine_holds = @(
        "AUD-SCN-004",
        "AUD-REL-005",
        "AUD-ASOF-003"
    )

    pbi_wp2 = "HOLD"
    a1b = "NOT_AUTHORIZED"
}

$governance |
    ConvertTo-Json -Depth 10 |
    Set-Content `
        -LiteralPath "$hotfixRoot\A1A_M_RUNTIME_HOTFIX_GOVERNANCE.json" `
        -Encoding utf8

Write-Host ""
Write-Host "============================================================"
Write-Host "A1A M-runtime hotfix applied."
Write-Host "External M definitions changed: 3"
Write-Host "Expected changed M lines:       7"
Write-Host "model.bim expressions updated:  3"
Write-Host "A1b changes:                    0"
Write-Host "============================================================"
Write-Host ""
Write-Host "Evidence:"
Write-Host $hotfixRoot
```

## 4. What the seven authorized line changes should be

The evidence CSV should show exactly these semantic changes:

```text
stg_POWER_BI_DATA_CATALOG
  Text.TrimEnd ... {"/", "\\"}  → {"/", "\"}
  "\\data\\POWER_BI_DATA_CATALOG.csv"
                              → "\data\POWER_BI_DATA_CATALOG.csv"

fxReadCatalogedCsv
  Text.TrimEnd ... {"/", "\\"}  → {"/", "\"}
  Text.Replace(..., "/", "\\")  → Text.Replace(..., "/", "\")
  Root & "\\" & RelativePath    → Root & "\" & RelativePath

fxReadBuildCsv
  Text.TrimEnd ... {"/", "\\"}  → {"/", "\"}
  Root & "\\" & Text.Replace(..., "/", "\\")
                              → Root & "\" & Text.Replace(..., "/", "\")
```

Nothing else should change.

---

# 5. Rerun the static semantic boundary verifier

Because the old pre-shell verifier expects zero pages, **do not use it** now.

Use the corrected shell-aware verifier that already produced PASS:

```powershell
$downloads = Join-Path $HOME "Downloads"

$verifier = Join-Path $downloads `
    "Verify-A1aTechnicalShellBoundary.ps1"

& $verifier `
    -PackageRoot $work `
    -SourceRoot `
    "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"
```

Required result remains:

```text
semantic_tables             14
relationships                6
power_query_queries         47
explicit_measures            0
semantic_activation_objects 67

technical_shell_pages        1
substantive_report_pages     0
visual_objects               0
a1b_tokens                   0
active_page_resolves         true
status                       PASS
```

That count is controlling: the audit authorized one technical page but explicitly kept the semantic A1a footprint at 67 objects. [export reference: filecite | turn9file0 | L63-L83]

## 6. One additional check before reopening Desktop

Run this:

```powershell
$hotfixRoot = Join-Path $ev "E03_M_RUNTIME_HOTFIX_R1"

$diff = Import-Csv `
    "$hotfixRoot\POWER_QUERY_TREE_CHANGE_CONTROL.csv"

$changed = @(
    $diff |
    Where-Object { $_.changed -eq "True" }
)

$changed |
    Format-Table `
        relative_path,
        sha256_before,
        sha256_after `
        -AutoSize

Write-Host ""
Write-Host "Changed external M files:" $changed.Count
```

It must say:

```text
Changed external M files: 3
```

No more, no fewer.

---

# 7. Then resume Desktop

If **both** controls pass:

```text
Shell-aware boundary verifier = PASS
Changed external M files       = 3
```

reopen the same derived PBIP:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

Then:

**Home → Transform data**

Before refreshing, click:

```text
stg_POWER_BI_DATA_CATALOG
```

It should now evaluate rather than throw the single-character error.

Then click:

```text
fxReadBuildCsv
```

The function itself should no longer show the malformed path-literal failure.

Only after those upstream definitions behave normally should you run:

```text
Refresh Preview → Refresh All
```

again.

### Do not go directly to Close & Apply

We will treat that as:

```text
Refresh Preview Attempt 2
```

and compare it against the recorded failed Attempt 1.

If Attempt 2 succeeds cleanly, **stop before Close & Apply and send me the result**. Then we will record the successful query-layer execution before physically loading the 14 tables.

Also, when the Independent Audit is free, we will disclose exactly what happened: Attempt 1 failed at runtime, you explicitly authorized `A1A-M-RUNTIME-HF01`, the hotfix changed three existing M definitions only, exact before/after hashes and seven line changes were preserved, no object count or business interpretation changed, and all three local-engine holds remained open. That preserves the “No Cold Handoffs” evidence chain rather than retroactively pretending the original code executed successfully.
<!-- END_SOURCE_MESSAGE -->


<a id="m-73acb1f9-174f-4c34-9196-668aa3b97c46"></a>
## Andrew / user · C091-M00060

C091-M00060 · 2026-08-19T09:20:12.148000-04:00 · active path

Preceding visible parent: [C091-M00059](part-04.md#m-66970bec-2389-4727-a9f9-7d4a2df37375)

<!-- BEGIN_SOURCE_MESSAGE -->
ParentContainsErrorRecordException:
Line |
 301 |      $beforeExpressionJson = [System.Text.Json.JsonSerializer]::Serial …
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Cannot find an overload for "Serialize" and the argument count: "1".
<!-- END_SOURCE_MESSAGE -->


<a id="m-0da0cd84-4dde-4b60-a47f-99f4d8390a96"></a>
## Assistant · C091-M00061

C091-M00061 · 2026-08-19T09:20:15.535549-04:00 · active path

Preceding visible parent: [C091-M00060](part-04.md#m-73acb1f9-174f-4c34-9196-668aa3b97c46)

<!-- BEGIN_SOURCE_MESSAGE -->
That failure is in the **PowerShell evidence/hotfix script**, not in Power BI or the M correction itself.

`System.Text.Json.JsonSerializer.Serialize()` is overloaded in a way PowerShell cannot resolve from a single dynamically typed argument in your environment. The block stopped **before the three `.m` files or `model.bim` were written**, so the governed working project should still be unchanged from the pre-hotfix state.

Do **not** reopen Desktop yet.

First, record this scripting interruption and verify that nothing was partially written. Run this in the same PowerShell 7 session:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"
$hotfixRoot = Join-Path $ev "E03_M_RUNTIME_HOTFIX_R1"
$beforeRoot = Join-Path $hotfixRoot "before"

@'
A1A M-RUNTIME HOTFIX SCRIPT INTERRUPTION

Date: 2026-08-19

The first A1A-M-RUNTIME-HF01 execution stopped during preparation of the
embedded model.bim expression replacements.

PowerShell error:
Cannot find an overload for "Serialize" and the argument count: "1".

The failure occurred before the script's WRITE EXTERNAL DEFINITIONS AND
MODEL.BIM section.

No Power BI Desktop execution occurred during this interruption.
The current source files are being independently compared to the preserved
pre-hotfix copies before execution resumes.
'@ |
    Set-Content `
        -LiteralPath "$hotfixRoot\HOTFIX_SCRIPT_INTERRUPTION_01.txt" `
        -Encoding utf8

$targets = [ordered]@{
    "stg_POWER_BI_DATA_CATALOG" = Join-Path $work `
        "power_query\staging\stg_POWER_BI_DATA_CATALOG.m"

    "fxReadCatalogedCsv" = Join-Path $work `
        "power_query\functions\fxReadCatalogedCsv.m"

    "fxReadBuildCsv" = Join-Path $work `
        "power_query\functions\fxReadBuildCsv.m"
}

$modelPath = Join-Path $work `
    "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$preResumeChecks = @()

foreach ($name in $targets.Keys) {

    $current = $targets[$name]
    $before  = Join-Path $beforeRoot "$name.m"

    $currentHash = (
        Get-FileHash -LiteralPath $current -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $beforeHash = (
        Get-FileHash -LiteralPath $before -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $preResumeChecks += [pscustomobject]@{
        object = $name
        current_sha256 = $currentHash
        preserved_before_sha256 = $beforeHash
        unchanged_since_failure = ($currentHash -ceq $beforeHash)
    }
}

$currentModelHash = (
    Get-FileHash -LiteralPath $modelPath -Algorithm SHA256
).Hash.ToLowerInvariant()

$beforeModelHash = (
    Get-FileHash `
        -LiteralPath (Join-Path $beforeRoot "model.bim") `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

$preResumeChecks += [pscustomobject]@{
    object = "model.bim"
    current_sha256 = $currentModelHash
    preserved_before_sha256 = $beforeModelHash
    unchanged_since_failure = ($currentModelHash -ceq $beforeModelHash)
}

$preResumeChecks |
    Format-Table -AutoSize

$preResumeChecks |
    Export-Csv `
        -LiteralPath "$hotfixRoot\HOTFIX_PRE_RESUME_INTEGRITY.csv" `
        -NoTypeInformation `
        -Encoding utf8

if (@($preResumeChecks | Where-Object {
    $_.unchanged_since_failure -ne $true
}).Count -gt 0) {
    throw "One or more governed files changed before hotfix resume. STOP."
}

Write-Host ""
Write-Host "PRE-RESUME INTEGRITY PASS — no hotfix writes occurred."
```

You should see all four `unchanged_since_failure` values as:

```text
True
```

and:

```text
PRE-RESUME INTEGRITY PASS — no hotfix writes occurred.
```

### Then resume the hotfix with this corrected block

This replaces the problematic `.NET Serialize()` call with PowerShell's `ConvertTo-Json -Compress`, which gives us the quoted/escaped JSON string needed to locate each M expression inside `model.bim`.

```powershell
$ErrorActionPreference = "Stop"

# Re-establish these objects in case the prior error affected scope.
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"
$hotfixRoot = Join-Path $ev "E03_M_RUNTIME_HOTFIX_R1"
$beforeRoot = Join-Path $hotfixRoot "before"
$afterRoot  = Join-Path $hotfixRoot "after"

$modelPath = Join-Path $work `
    "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$targets = [ordered]@{
    "stg_POWER_BI_DATA_CATALOG" = Join-Path $work `
        "power_query\staging\stg_POWER_BI_DATA_CATALOG.m"

    "fxReadCatalogedCsv" = Join-Path $work `
        "power_query\functions\fxReadCatalogedCsv.m"

    "fxReadBuildCsv" = Join-Path $work `
        "power_query\functions\fxReadBuildCsv.m"
}

function Repair-A1aMDefinition {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true)]
        [string]$Text
    )

    $result = $Text

    switch ($Name) {

        "stg_POWER_BI_DATA_CATALOG" {
            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )

            $result = $result.Replace(
                '"\\data\\POWER_BI_DATA_CATALOG.csv"',
                '"\data\POWER_BI_DATA_CATALOG.csv"'
            )
        }

        "fxReadCatalogedCsv" {
            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )

            $result = $result.Replace(
                'Text.Replace(CatalogRow[package_path], "/", "\\")',
                'Text.Replace(CatalogRow[package_path], "/", "\")'
            )

            $result = $result.Replace(
                'Root & "\\" & RelativePath',
                'Root & "\" & RelativePath'
            )
        }

        "fxReadBuildCsv" {
            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )

            $result = $result.Replace(
                'Root & "\\" & Text.Replace(relativePath, "/", "\\")',
                'Root & "\" & Text.Replace(relativePath, "/", "\")'
            )
        }

        default {
            throw "Unexpected hotfix object: $Name"
        }
    }

    if ($result -ceq $Text) {
        throw "No text changed for $Name. Stop."
    }

    return $result
}

# Recreate exact before/after definitions from preserved BEFORE evidence,
# not from an assumed in-memory state.
$definitions = @{}

foreach ($name in $targets.Keys) {

    $preservedBeforePath = Join-Path $beforeRoot "$name.m"

    $beforeText = [IO.File]::ReadAllText(
        $preservedBeforePath
    )

    $afterText = Repair-A1aMDefinition `
        -Name $name `
        -Text $beforeText

    $definitions[$name] = [pscustomobject]@{
        before = $beforeText
        after = $afterText
        path = $targets[$name]
    }
}

# Reconfirm the exact seven changed lines.
$lineDiff = @()

foreach ($name in $targets.Keys) {

    $beforeLines = @(
        $definitions[$name].before -split "`r?`n"
    )

    $afterLines = @(
        $definitions[$name].after -split "`r?`n"
    )

    $max = [Math]::Max(
        $beforeLines.Count,
        $afterLines.Count
    )

    for ($i = 0; $i -lt $max; $i++) {

        $beforeLine = if ($i -lt $beforeLines.Count) {
            $beforeLines[$i]
        } else {
            $null
        }

        $afterLine = if ($i -lt $afterLines.Count) {
            $afterLines[$i]
        } else {
            $null
        }

        if ($beforeLine -cne $afterLine) {
            $lineDiff += [pscustomobject]@{
                object = $name
                line_number = $i + 1
                before = $beforeLine
                after = $afterLine
            }
        }
    }
}

$lineDiff |
    Format-Table -AutoSize

if ($lineDiff.Count -ne 7) {
    throw "Expected exactly 7 changed M lines; observed $($lineDiff.Count)."
}

$lineDiff |
    Export-Csv `
        -LiteralPath "$hotfixRoot\M_RUNTIME_EXACT_LINE_DIFF.csv" `
        -NoTypeInformation `
        -Encoding utf8

# ------------------------------------------------------------
# PATCH model.bim USING POWERSHELL JSON STRING SERIALIZATION
# ------------------------------------------------------------

$modelRaw = [IO.File]::ReadAllText(
    (Join-Path $beforeRoot "model.bim")
)

$embeddedMatchEvidence = @()

foreach ($name in $targets.Keys) {

    # ConvertTo-Json on a string gives the exact quoted JSON string,
    # including escaping of quotes/newlines/backslashes.
    $beforeExpressionJson = ConvertTo-Json `
        -InputObject $definitions[$name].before `
        -Compress

    $afterExpressionJson = ConvertTo-Json `
        -InputObject $definitions[$name].after `
        -Compress

    $matchCount = (
        [regex]::Matches(
            $modelRaw,
            [regex]::Escape($beforeExpressionJson)
        )
    ).Count

    $embeddedMatchEvidence += [pscustomobject]@{
        object = $name
        before_expression_matches_in_model = $matchCount
    }

    if ($matchCount -ne 1) {
        throw "Embedded model expression for $name matched $matchCount times; expected exactly 1."
    }

    $modelRaw = $modelRaw.Replace(
        $beforeExpressionJson,
        $afterExpressionJson
    )
}

$embeddedMatchEvidence |
    Export-Csv `
        -LiteralPath "$hotfixRoot\EMBEDDED_EXPRESSION_MATCH_CONTROL.csv" `
        -NoTypeInformation `
        -Encoding utf8

# ------------------------------------------------------------
# WRITE ONLY THE 3 M FILES + model.bim
# ------------------------------------------------------------

New-Item -ItemType Directory -Force -Path $afterRoot |
    Out-Null

foreach ($name in $targets.Keys) {

    [IO.File]::WriteAllText(
        $targets[$name],
        $definitions[$name].after,
        [Text.UTF8Encoding]::new($false)
    )

    [IO.File]::WriteAllText(
        (Join-Path $afterRoot "$name.m"),
        $definitions[$name].after,
        [Text.UTF8Encoding]::new($false)
    )
}

[IO.File]::WriteAllText(
    $modelPath,
    $modelRaw,
    [Text.UTF8Encoding]::new($false)
)

Copy-Item `
    -LiteralPath $modelPath `
    -Destination (Join-Path $afterRoot "model.bim") `
    -Force

# ------------------------------------------------------------
# VERIFY MODEL EMBEDDING AGAINST THE 3 EXTERNAL M FILES
# ------------------------------------------------------------

$parsedModel = Get-Content `
    -LiteralPath $modelPath `
    -Raw |
    ConvertFrom-Json

$embeddedParity = @()

foreach ($name in $targets.Keys) {

    $expr = @(
        $parsedModel.model.expressions |
        Where-Object { $_.name -ceq $name }
    )

    if ($expr.Count -ne 1) {
        throw "Expected exactly one model expression named $name; observed $($expr.Count)."
    }

    $externalText = [IO.File]::ReadAllText(
        $targets[$name]
    )

    $parity = (
        $expr[0].expression -ceq $externalText
    )

    $embeddedParity += [pscustomobject]@{
        object = $name
        embedded_equals_external = $parity
    }

    if (-not $parity) {
        throw "Embedded/external M parity failed for $name."
    }
}

$embeddedParity |
    Export-Csv `
        -LiteralPath "$hotfixRoot\EMBEDDED_EXTERNAL_M_PARITY.csv" `
        -NoTypeInformation `
        -Encoding utf8

# ------------------------------------------------------------
# BEFORE/AFTER HASH EVIDENCE
# ------------------------------------------------------------

$hashRows = @()

foreach ($name in $targets.Keys) {

    $beforePath = Join-Path $beforeRoot "$name.m"
    $afterPath  = $targets[$name]

    $hashRows += [pscustomobject]@{
        object = $name
        artifact = "EXTERNAL_M"
        sha256_before = (
            Get-FileHash `
                -LiteralPath $beforePath `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        sha256_after = (
            Get-FileHash `
                -LiteralPath $afterPath `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        changed = $true
    }
}

$hashRows += [pscustomobject]@{
    object = "model.bim"
    artifact = "EMBEDDED_MODEL"
    sha256_before = (
        Get-FileHash `
            -LiteralPath (Join-Path $beforeRoot "model.bim") `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    sha256_after = (
        Get-FileHash `
            -LiteralPath $modelPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    changed = $true
}

$hashRows |
    Export-Csv `
        -LiteralPath "$hotfixRoot\M_RUNTIME_BEFORE_AFTER_HASHES.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host ""
Write-Host "=============================================="
Write-Host "A1A-M-RUNTIME-HF01 WRITE PHASE COMPLETE"
Write-Host "External M files changed:       3"
Write-Host "Expected changed source lines:  7"
Write-Host "Embedded expressions changed:   3"
Write-Host "=============================================="
```

If that succeeds, we still need to prove that **only those three external `.m` files** changed relative to the pre-hotfix tree. Run:

```powershell
$preTree = Import-Csv `
    "$hotfixRoot\POWER_QUERY_TREE_BEFORE.csv"

$postTree = foreach (
    $file in @(
        Get-ChildItem `
            -LiteralPath (Join-Path $work "power_query") `
            -File `
            -Recurse `
            -Filter "*.m" |
        Sort-Object FullName
    )
) {
    [pscustomobject]@{
        relative_path = $file.FullName.Substring($work.Length + 1)
        bytes = $file.Length
        sha256 = (
            Get-FileHash `
                -LiteralPath $file.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$postTree |
    Export-Csv `
        -LiteralPath "$hotfixRoot\POWER_QUERY_TREE_AFTER.csv" `
        -NoTypeInformation `
        -Encoding utf8

$treeComparison = foreach ($before in $preTree) {

    $after = @(
        $postTree |
        Where-Object {
            $_.relative_path -ceq $before.relative_path
        }
    )

    if ($after.Count -ne 1) {
        throw "Tree mismatch for $($before.relative_path)."
    }

    [pscustomobject]@{
        relative_path = $before.relative_path
        sha256_before = $before.sha256
        sha256_after = $after[0].sha256
        changed = (
            $before.sha256 -cne $after[0].sha256
        )
    }
}

$treeComparison |
    Export-Csv `
        -LiteralPath "$hotfixRoot\POWER_QUERY_TREE_CHANGE_CONTROL.csv" `
        -NoTypeInformation `
        -Encoding utf8

$changed = @(
    $treeComparison |
    Where-Object { $_.changed -eq $true }
)

$changed |
    Format-Table `
        relative_path,
        sha256_before,
        sha256_after `
        -AutoSize

Write-Host ""
Write-Host "Changed external M files:" $changed.Count

if ($changed.Count -ne 3) {
    throw "Expected exactly 3 changed external M files."
}
```

Required:

```text
Changed external M files: 3
```

Then rerun the already-corrected shell-aware verifier:

```powershell
$verifier = Join-Path $HOME `
    "Downloads\Verify-A1aTechnicalShellBoundary.ps1"

& $verifier `
    -PackageRoot $work `
    -SourceRoot `
    "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"
```

We still require:

```text
semantic_tables             14
relationships                6
power_query_queries         47
explicit_measures            0
technical_shell_pages        1
substantive_report_pages     0
visual_objects               0
a1b_tokens                   0
active_page_resolves         true
status                       PASS
```

The audit-approved compatibility exception permits execution only inside this exact one-shell/14/6/47/0 boundary and still prohibits A1b or silent expansion. [export reference: filecite | turn9file0 | L102-L123]

**Send me the output from the pre-resume integrity check first.** If all four rows are `True`, you can immediately run the corrected resume block above.
<!-- END_SOURCE_MESSAGE -->


<a id="m-66c1279d-175e-406b-97f1-311de596db4a"></a>
## Andrew / user · C091-M00062

C091-M00062 · 2026-08-19T09:25:07.433000-04:00 · active path

Preceding visible parent: [C091-M00061](part-04.md#m-0da0cd84-4dde-4b60-a47f-99f4d8390a96)

<!-- BEGIN_SOURCE_MESSAGE -->
object                    line_number before                                                                after
------                    ----------- ------                                                                -----
stg_POWER_BI_DATA_CATALOG           3     Root = Text.TrimEnd(pDataRoot, {"/", "\\"}),                          Root = Text.TrimEnd(pDataRoot, {"/", "\"}),
stg_POWER_BI_DATA_CATALOG           4     Path = Root & "\\data\\POWER_BI_DATA_CATALOG.csv",                    Path = Root & "\data\POWER_BI_DATA_CATALOG.csv",
fxReadCatalogedCsv                  6     Root = Text.TrimEnd(pDataRoot, {"/", "\\"}),                          Root = Text.TrimEnd(pDataRoot, {"/", "\"}),
fxReadCatalogedCsv                  7     RelativePath = Text.Replace(CatalogRow[package_path], "/", "\\"),     RelativePath = Text.Replace(CatalogRow[package_path], "/", "\"),
fxReadCatalogedCsv                  8     FullPath = Root & "\\" & RelativePath,                                FullPath = Root & "\" & RelativePath,
fxReadBuildCsv                      4     Root = Text.TrimEnd(pBuildRoot, {"/", "\\"}),                         Root = Text.TrimEnd(pBuildRoot, {"/", "\"}),
fxReadBuildCsv                      5     FullPath = Root & "\\" & Text.Replace(relativePath, "/", "\\"),       FullPath = Root & "\" & Text.Replace(relativePath, "/", "\"),

Exception:
Line |
 204 |          throw "Embedded model expression for $name matched $matchCoun …
     |          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Embedded model expression for stg_POWER_BI_DATA_CATALOG matched 0 times; expected exactly 1.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9c33c9b5-c690-4e5e-a360-393252bef433"></a>
## Assistant · C091-M00063

C091-M00063 · 2026-08-19T09:25:27.958854-04:00 · active path

Preceding visible parent: [C091-M00062](part-04.md#m-66c1279d-175e-406b-97f1-311de596db4a)

<!-- BEGIN_SOURCE_MESSAGE -->
We found a second **hotfix-script matching defect**, not a defect in the seven M changes. The seven proposed changes are exactly the intended ones.

The `0 times` result is occurring because the script tried to find the **external `.m` file text byte-for-byte inside `model.bim`**. The embedded M expression is semantically the same, but its line-ending/JSON representation is normalized inside `model.bim`, so the external-file serialization is not an exact raw-text match.

The script again stopped **before the write phase**, so first confirm that nothing was changed. Keep Desktop closed.

### 1. Reconfirm pre-hotfix integrity

Run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"
$hotfixRoot = Join-Path $ev "E03_M_RUNTIME_HOTFIX_R1"
$beforeRoot = Join-Path $hotfixRoot "before"

$modelPath = Join-Path $work `
    "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$targets = [ordered]@{
    "stg_POWER_BI_DATA_CATALOG" = Join-Path $work `
        "power_query\staging\stg_POWER_BI_DATA_CATALOG.m"

    "fxReadCatalogedCsv" = Join-Path $work `
        "power_query\functions\fxReadCatalogedCsv.m"

    "fxReadBuildCsv" = Join-Path $work `
        "power_query\functions\fxReadBuildCsv.m"
}

$checks = foreach ($name in $targets.Keys) {
    $current = $targets[$name]
    $before  = Join-Path $beforeRoot "$name.m"

    [pscustomobject]@{
        object = $name
        unchanged = (
            (Get-FileHash $current -Algorithm SHA256).Hash -ceq
            (Get-FileHash $before  -Algorithm SHA256).Hash
        )
    }
}

$checks += [pscustomobject]@{
    object = "model.bim"
    unchanged = (
        (Get-FileHash $modelPath -Algorithm SHA256).Hash -ceq
        (Get-FileHash (Join-Path $beforeRoot "model.bim") -Algorithm SHA256).Hash
    )
}

$checks | Format-Table -AutoSize

if (@($checks | Where-Object { -not $_.unchanged }).Count -gt 0) {
    throw "STOP: a governed file changed during the interrupted hotfix."
}

Write-Host "PRE-WRITE INTEGRITY PASS"
```

All four rows should be `True`.

### 2. Record this second interruption

```powershell
@'
A1A M-RUNTIME HOTFIX SCRIPT INTERRUPTION 02

Date: 2026-08-19

The second A1A-M-RUNTIME-HF01 attempt successfully reproduced the exact
seven intended M-source line changes but stopped before writing files.

Observed condition:
The script searched model.bim for a JSON serialization derived from the
external .m file text and found zero exact matches for
stg_POWER_BI_DATA_CATALOG.

Cause:
The M expression embedded in model.bim is semantically equivalent to the
external definition but its line-ending/JSON representation is normalized.
External-file bytes therefore cannot be used as the raw model.bim search
identity.

Remediation:
The next write attempt derives each before/after embedded expression from
the actual parsed model.bim expression and performs a targeted raw JSON
replacement of that embedded representation.

No governed Power BI file was written during this interruption.
'@ |
    Set-Content `
        -LiteralPath "$hotfixRoot\HOTFIX_SCRIPT_INTERRUPTION_02.txt" `
        -Encoding utf8
```

## 3. Apply the corrected write phase

This version deliberately maintains **two representations**:

- external `.m` → repaired from the preserved external source;
- embedded `model.bim` expression → repaired from the actual embedded expression.

That avoids relying on identical line-ending bytes.

```powershell
$ErrorActionPreference = "Stop"

function Repair-A1aMDefinition {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Text
    )

    $result = $Text

    switch ($Name) {
        "stg_POWER_BI_DATA_CATALOG" {
            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )
            $result = $result.Replace(
                '"\\data\\POWER_BI_DATA_CATALOG.csv"',
                '"\data\POWER_BI_DATA_CATALOG.csv"'
            )
        }

        "fxReadCatalogedCsv" {
            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )
            $result = $result.Replace(
                'Text.Replace(CatalogRow[package_path], "/", "\\")',
                'Text.Replace(CatalogRow[package_path], "/", "\")'
            )
            $result = $result.Replace(
                'Root & "\\" & RelativePath',
                'Root & "\" & RelativePath'
            )
        }

        "fxReadBuildCsv" {
            $result = $result.Replace(
                '{"/", "\\"}',
                '{"/", "\"}'
            )
            $result = $result.Replace(
                'Root & "\\" & Text.Replace(relativePath, "/", "\\")',
                'Root & "\" & Text.Replace(relativePath, "/", "\")'
            )
        }

        default {
            throw "Unexpected hotfix target: $Name"
        }
    }

    if ($result -ceq $Text) {
        throw "No repair occurred for $Name."
    }

    $result
}

# Always start from the preserved pre-hotfix BIM.
$modelBeforePath = Join-Path $beforeRoot "model.bim"
$modelRaw = [IO.File]::ReadAllText($modelBeforePath)

$modelParsed = Get-Content `
    -LiteralPath $modelBeforePath `
    -Raw |
    ConvertFrom-Json

$embeddedEvidence = @()

foreach ($name in $targets.Keys) {

    $expr = @(
        $modelParsed.model.expressions |
        Where-Object { $_.name -ceq $name }
    )

    if ($expr.Count -ne 1) {
        throw "Expected exactly one embedded expression named $name; found $($expr.Count)."
    }

    # IMPORTANT: use the expression actually embedded in model.bim,
    # not the external .m bytes.
    $embeddedBefore = [string]$expr[0].expression
    $embeddedAfter  = Repair-A1aMDefinition `
        -Name $name `
        -Text $embeddedBefore

    $jsonBefore = ConvertTo-Json `
        -InputObject $embeddedBefore `
        -Compress

    $jsonAfter = ConvertTo-Json `
        -InputObject $embeddedAfter `
        -Compress

    $matchCount = (
        [regex]::Matches(
            $modelRaw,
            [regex]::Escape($jsonBefore)
        )
    ).Count

    $embeddedEvidence += [pscustomobject]@{
        object = $name
        embedded_expression_match_count = $matchCount
        embedded_before_length = $embeddedBefore.Length
        embedded_after_length = $embeddedAfter.Length
    }

    if ($matchCount -ne 1) {
        throw "Actual embedded expression for $name matched $matchCount raw JSON values; expected 1."
    }

    $modelRaw = $modelRaw.Replace(
        $jsonBefore,
        $jsonAfter
    )
}

$embeddedEvidence |
    Format-Table -AutoSize

$embeddedEvidence |
    Export-Csv `
        -LiteralPath "$hotfixRoot\EMBEDDED_EXPRESSION_MATCH_CONTROL.csv" `
        -NoTypeInformation `
        -Encoding utf8

# Rebuild external repaired definitions from preserved BEFORE files.
$externalAfter = @{}

foreach ($name in $targets.Keys) {

    $beforeText = [IO.File]::ReadAllText(
        (Join-Path $beforeRoot "$name.m")
    )

    $externalAfter[$name] = Repair-A1aMDefinition `
        -Name $name `
        -Text $beforeText
}

# Only now perform writes.
foreach ($name in $targets.Keys) {
    [IO.File]::WriteAllText(
        $targets[$name],
        $externalAfter[$name],
        [Text.UTF8Encoding]::new($false)
    )
}

[IO.File]::WriteAllText(
    $modelPath,
    $modelRaw,
    [Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "WRITE PHASE COMPLETE"
```

The `EMBEDDED_EXPRESSION_MATCH_CONTROL` output must show:

```text
stg_POWER_BI_DATA_CATALOG    1
fxReadCatalogedCsv           1
fxReadBuildCsv               1
```

If any value is not `1`, the block stops before writing.

## 4. Verify embedded/external semantic parity

Because line endings may differ, we should now compare normalized M rather than raw bytes:

```powershell
$modelAfter = Get-Content `
    -LiteralPath $modelPath `
    -Raw |
    ConvertFrom-Json

$parity = foreach ($name in $targets.Keys) {

    $expr = @(
        $modelAfter.model.expressions |
        Where-Object { $_.name -ceq $name }
    )[0]

    $external = [IO.File]::ReadAllText($targets[$name])

    $embeddedNorm = ([string]$expr.expression) -replace "`r`n", "`n"
    $externalNorm = $external -replace "`r`n", "`n"

    [pscustomobject]@{
        object = $name
        normalized_embedded_equals_external = (
            $embeddedNorm -ceq $externalNorm
        )
    }
}

$parity | Format-Table -AutoSize

$parity |
    Export-Csv `
        -LiteralPath "$hotfixRoot\EMBEDDED_EXTERNAL_M_NORMALIZED_PARITY.csv" `
        -NoTypeInformation `
        -Encoding utf8

if (@($parity | Where-Object {
    -not $_.normalized_embedded_equals_external
}).Count -gt 0) {
    throw "Embedded/external normalized M parity failed."
}

Write-Host "EMBEDDED/EXTERNAL NORMALIZED PARITY PASS"
```

Required:

```text
stg_POWER_BI_DATA_CATALOG    True
fxReadCatalogedCsv           True
fxReadBuildCsv               True

EMBEDDED/EXTERNAL NORMALIZED PARITY PASS
```

Then we will do the 47-file tree-diff and shell-aware boundary verification before Desktop is reopened.

The important point is that the evidence already supports the intended correction: **exactly seven source lines across three existing definitions**, with no table/query/relationship/measure expansion. The A1a authorization remains bounded to 14 tables, 6 relationships, 47 queries, zero measures, and the one technical shell. [export reference: filecite | turn9file0 | L63-L79]

Run **Step 1 first**. If all four rows are `True`, proceed through Steps 2–4 and paste the resulting match-control and parity output.
<!-- END_SOURCE_MESSAGE -->


<a id="m-37fc3aba-46b2-4c99-ad6a-069f5564ea17"></a>
## Andrew / user · C091-M00064

C091-M00064 · 2026-08-19T09:28:54.998000-04:00 · active path

Preceding visible parent: [C091-M00063](part-04.md#m-9c33c9b5-c690-4e5e-a360-393252bef433)

<!-- BEGIN_SOURCE_MESSAGE -->
Exception:
Line |
 113 |          throw "Actual embedded expression for $name matched $matchCou …
     |          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Actual embedded expression for stg_POWER_BI_DATA_CATALOG matched 0 raw JSON values; expected 1.
<!-- END_SOURCE_MESSAGE -->


<a id="m-97c445e5-fa1d-4c36-b8fb-25d8b81a9001"></a>
## Assistant · C091-M00065

C091-M00065 · 2026-08-19T09:28:59.343487-04:00 · active path

Preceding visible parent: [C091-M00064](part-04.md#m-37fc3aba-46b2-4c99-ad6a-069f5564ea17)

<!-- BEGIN_SOURCE_MESSAGE -->
That tells us the embedded `model.bim` representation is **not a single JSON string value**, which explains both zero-match attempts. The most likely structure is that Power BI stores each M expression as a **JSON array of source lines**, not one multiline string. We should stop trying to infer its serialization.

Nothing has been written by this attempt because the script again failed before the write section. Keep Desktop closed.

We’ll inspect the actual embedded structure first, then make the patch against what is physically there.

### 1. Confirm no partial write occurred again

Run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"
$hotfixRoot = Join-Path $ev "E03_M_RUNTIME_HOTFIX_R1"
$beforeRoot = Join-Path $hotfixRoot "before"

$modelPath = Join-Path $work `
    "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$targets = [ordered]@{
    "stg_POWER_BI_DATA_CATALOG" = Join-Path $work `
        "power_query\staging\stg_POWER_BI_DATA_CATALOG.m"
    "fxReadCatalogedCsv" = Join-Path $work `
        "power_query\functions\fxReadCatalogedCsv.m"
    "fxReadBuildCsv" = Join-Path $work `
        "power_query\functions\fxReadBuildCsv.m"
}

$checks = foreach ($name in $targets.Keys) {
    [pscustomobject]@{
        object = $name
        unchanged = (
            (Get-FileHash $targets[$name] -Algorithm SHA256).Hash -ceq
            (Get-FileHash (Join-Path $beforeRoot "$name.m") -Algorithm SHA256).Hash
        )
    }
}

$checks += [pscustomobject]@{
    object = "model.bim"
    unchanged = (
        (Get-FileHash $modelPath -Algorithm SHA256).Hash -ceq
        (Get-FileHash (Join-Path $beforeRoot "model.bim") -Algorithm SHA256).Hash
    )
}

$checks | Format-Table -AutoSize

if (@($checks | Where-Object { -not $_.unchanged }).Count -gt 0) {
    throw "STOP: a governed file changed."
}

Write-Host "PRE-WRITE INTEGRITY PASS"
```

We still want all four `True`.

### 2. Inspect how Power BI actually stores the three expressions

Then run:

```powershell
$modelBeforePath = Join-Path $beforeRoot "model.bim"

$model = Get-Content `
    -LiteralPath $modelBeforePath `
    -Raw |
    ConvertFrom-Json

$diagnostic = foreach ($name in $targets.Keys) {

    $expr = @(
        $model.model.expressions |
        Where-Object { $_.name -ceq $name }
    )

    if ($expr.Count -ne 1) {
        throw "Expected one expression named $name; found $($expr.Count)."
    }

    $value = $expr[0].expression

    [pscustomobject]@{
        object = $name
        expression_type = $value.GetType().FullName
        expression_count = @($value).Count
        first_element_type = if (@($value).Count -gt 0) {
            @($value)[0].GetType().FullName
        } else {
            $null
        }
        first_element = if (@($value).Count -gt 0) {
            @($value)[0]
        } else {
            $null
        }
    }
}

$diagnostic | Format-List

$diagnostic |
    Export-Csv `
        -LiteralPath "$hotfixRoot\MODEL_BIM_EXPRESSION_STRUCTURE_DIAGNOSTIC.csv" `
        -NoTypeInformation `
        -Encoding utf8
```

I expect something like:

```text
expression_type  : System.Object[]
expression_count : several lines
first_element    : let
```

rather than `System.String`.

### 3. Capture the actual raw `model.bim` fragments

Also run this. It extracts a small read-only window around each expression name:

```powershell
$raw = [IO.File]::ReadAllText($modelBeforePath)

foreach ($name in $targets.Keys) {

    $needle = '"name": "' + $name + '"'
    $index = $raw.IndexOf(
        $needle,
        [System.StringComparison]::Ordinal
    )

    if ($index -lt 0) {
        throw "Could not locate raw model.bim name: $name"
    }

    $start = [Math]::Max(0, $index - 200)
    $length = [Math]::Min(
        2200,
        $raw.Length - $start
    )

    $fragment = $raw.Substring($start, $length)

    $out = Join-Path $hotfixRoot `
        ("RAW_MODEL_FRAGMENT_" + $name + ".txt")

    [IO.File]::WriteAllText(
        $out,
        $fragment,
        [Text.UTF8Encoding]::new($false)
    )

    Write-Host ""
    Write-Host "========== $name =========="
    Write-Host $fragment
}
```

This does not modify anything.

### Why this is the right move

Your seven external M changes are already exactly what we intended:

```text
2 lines  stg_POWER_BI_DATA_CATALOG
3 lines  fxReadCatalogedCsv
2 lines  fxReadBuildCsv
--------------------------------
7 total
```

The only unresolved issue is **how those same lines are physically encoded inside `model.bim`**. We should patch the actual representation instead of repeatedly guessing at JSON serialization.

The A1a footprint remains unchanged at 14 tables, 6 relationships, 47 queries, zero explicit measures, and one technical shell page. [export reference: filecite | turn9file0 | L63-L79]

Paste the output from **Step 2**. If it confirms an array-of-lines representation, I can give you a much simpler and safer hotfix that replaces only the affected array elements in `model.bim`, with no whole-file reserialization.
<!-- END_SOURCE_MESSAGE -->
