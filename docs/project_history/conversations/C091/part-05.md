# MSBF - Power BI Executive Portfolio Intelligence

Part 05 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-04.md)
[Next part](part-06.md)

<a id="m-2d7dad92-3fd4-4dbd-b478-10e4eefb70a9"></a>
## Andrew / user · C091-M00066

C091-M00066 · 2026-08-19T09:33:46.902000-04:00 · active path

Preceding visible parent: [C091-M00065](part-04.md#m-97c445e5-fa1d-4c36-b8fb-25d8b81a9001)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\Windows\System32> $work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
>> $ev   = Join-Path $work "evidence\local_engine_return"
>> $hotfixRoot = Join-Path $ev "E03_M_RUNTIME_HOTFIX_R1"
>> $beforeRoot = Join-Path $hotfixRoot "before"
>>
>> $modelPath = Join-Path $work `
>>     "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"
>>
>> $targets = [ordered]@{
>>     "stg_POWER_BI_DATA_CATALOG" = Join-Path $work `
>>         "power_query\staging\stg_POWER_BI_DATA_CATALOG.m"
>>     "fxReadCatalogedCsv" = Join-Path $work `
>>         "power_query\functions\fxReadCatalogedCsv.m"
>>     "fxReadBuildCsv" = Join-Path $work `
>>         "power_query\functions\fxReadBuildCsv.m"
>> }
>>
>> $checks = foreach ($name in $targets.Keys) {
>>     [pscustomobject]@{
>>         object = $name
>>         unchanged = (
>>             (Get-FileHash $targets[$name] -Algorithm SHA256).Hash -ceq
>>             (Get-FileHash (Join-Path $beforeRoot "$name.m") -Algorithm SHA256).Hash
>>         )
>>     }
>> }
>>
>> $checks += [pscustomobject]@{
>>     object = "model.bim"
>>     unchanged = (
>>         (Get-FileHash $modelPath -Algorithm SHA256).Hash -ceq
>>         (Get-FileHash (Join-Path $beforeRoot "model.bim") -Algorithm SHA256).Hash
>>     )
>> }
>>
>> $checks | Format-Table -AutoSize
>>
>> if (@($checks | Where-Object { -not $_.unchanged }).Count -gt 0) {
>>     throw "STOP: a governed file changed."
>> }
>>
>> Write-Host "PRE-WRITE INTEGRITY PASS"

object                    unchanged
------                    ---------
stg_POWER_BI_DATA_CATALOG      True
fxReadCatalogedCsv             True
fxReadBuildCsv                 True
model.bim                      True

PRE-WRITE INTEGRITY PASS
PS C:\Windows\System32> $modelBeforePath = Join-Path $beforeRoot "model.bim"
>>
>> $model = Get-Content `
>>     -LiteralPath $modelBeforePath `
>>     -Raw |
>>     ConvertFrom-Json
>>
>> $diagnostic = foreach ($name in $targets.Keys) {
>>
>>     $expr = @(
>>         $model.model.expressions |
>>         Where-Object { $_.name -ceq $name }
>>     )
>>
>>     if ($expr.Count -ne 1) {
>>         throw "Expected one expression named $name; found $($expr.Count)."
>>     }
>>
>>     $value = $expr[0].expression
>>
>>     [pscustomobject]@{
>>         object = $name
>>         expression_type = $value.GetType().FullName
>>         expression_count = @($value).Count
>>         first_element_type = if (@($value).Count -gt 0) {
>>             @($value)[0].GetType().FullName
>>         } else {
>>             $null
>>         }
>>         first_element = if (@($value).Count -gt 0) {
>>             @($value)[0]
>>         } else {
>>             $null
>>         }
>>     }
>> }
>>
>> $diagnostic | Format-List
>>
>> $diagnostic |
>>     Export-Csv `
>>         -LiteralPath "$hotfixRoot\MODEL_BIM_EXPRESSION_STRUCTURE_DIAGNOSTIC.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8

object             : stg_POWER_BI_DATA_CATALOG
expression_type    : System.Object[]
expression_count   : 13
first_element_type : System.String
first_element      : // Catalog authority for all core CSV reads.

object             : fxReadCatalogedCsv
expression_type    : System.Object[]
expression_count   : 27
first_element_type : System.String
first_element      : // Governed CSV reader: exact catalog row, path, ordered header, and row-count checks.

object             : fxReadBuildCsv
expression_type    : System.Object[]
expression_count   : 10
first_element_type : System.String
first_element      : // Reads versioned Power BI-owned catalogs from the WP1/WP2 package root.

PS C:\Windows\System32> $raw = [IO.File]::ReadAllText($modelBeforePath)
>>
>> foreach ($name in $targets.Keys) {
>>
>>     $needle = '"name": "' + $name + '"'
>>     $index = $raw.IndexOf(
>>         $needle,
>>         [System.StringComparison]::Ordinal
>>     )
>>
>>     if ($index -lt 0) {
>>         throw "Could not locate raw model.bim name: $name"
>>     }
>>
>>     $start = [Math]::Max(0, $index - 200)
>>     $length = [Math]::Min(
>>         2200,
>>         $raw.Length - $start
>>     )
>>
>>     $fragment = $raw.Substring($start, $length)
>>
>>     $out = Join-Path $hotfixRoot `
>>         ("RAW_MODEL_FRAGMENT_" + $name + ".txt")
>>
>>     [IO.File]::WriteAllText(
>>         $out,
>>         $fragment,
>>         [Text.UTF8Encoding]::new($false)
>>     )
>>
>>     Write-Host ""
>>     Write-Host "========== $name =========="
>>     Write-Host $fragment
>> }

========== stg_POWER_BI_DATA_CATALOG ==========
value": "false"
          }
        ],
        "expression": "false meta [IsParameterQuery=true, Type=\"Logical\", IsParameterQueryRequired=true]",
        "kind": "m"
      },
      {
        "name": "stg_POWER_BI_DATA_CATALOG",
        "annotations": [
          {
            "name": "MSBF_ActivationWave",
            "value": "A1a"
          },
          {
            "name": "MSBF_LoadEnabled",
            "value": "false"
          }
        ],
        "expression": [
          "// Catalog authority for all core CSV reads.",
          "let",
          "    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\\\"}),",
          "    Path = Root & \"\\\\data\\\\POWER_BI_DATA_CATALOG.csv\",",
          "    Raw = Csv.Document(File.Contents(Path), [Delimiter=\",\", Encoding=65001, QuoteStyle=QuoteStyle.Csv]),",
          "    Headers = Table.PromoteHeaders(Raw, [PromoteAllScalars=true]),",
          "    Typed = Table.TransformColumnTypes(Headers, {",
          "        {\"schema\", type text}, {\"object\", type text}, {\"rows\", Int64.Type}, {\"columns\", Int64.Type},",
          "        {\"bytes\", Int64.Type}, {\"sha256\", type text}, {\"role\", type text}, {\"primary_pages\", type text},",
          "        {\"import_priority\", type text}, {\"package_path\", type text}, {\"original_source_path\", type text}, {\"header_json\", type text}",
          "    }, \"en-US\")",
          "in",
          "    Typed"
        ],
        "kind": "m"
      },
      {
        "name": "fxReadCatalogedCsv",
        "annotations": [
          {
            "name": "MSBF_ActivationWave",
            "value": "A1a"
          },
          {
            "name": "MSBF_LoadEnabled",
            "value": "false"
          }
        ],
        "expression": [
          "// Governed CSV reader: exact catalog row, path, ordered header, and row-count checks.",
          "(schemaName as text, objectName as text) as table =>",
          "let",
          "    Matches = Table.SelectRows(stg_POWER_BI_DATA_CATALOG, each [schema] = schemaName and [object] = objectName),",
          "    CatalogRow = if Table.RowCount(Matches) <> 1 then error Error

========== fxReadCatalogedCsv ==========
original_source_path\", type text}, {\"header_json\", type text}",
          "    }, \"en-US\")",
          "in",
          "    Typed"
        ],
        "kind": "m"
      },
      {
        "name": "fxReadCatalogedCsv",
        "annotations": [
          {
            "name": "MSBF_ActivationWave",
            "value": "A1a"
          },
          {
            "name": "MSBF_LoadEnabled",
            "value": "false"
          }
        ],
        "expression": [
          "// Governed CSV reader: exact catalog row, path, ordered header, and row-count checks.",
          "(schemaName as text, objectName as text) as table =>",
          "let",
          "    Matches = Table.SelectRows(stg_POWER_BI_DATA_CATALOG, each [schema] = schemaName and [object] = objectName),",
          "    CatalogRow = if Table.RowCount(Matches) <> 1 then error Error.Record(\"CATALOG_LOOKUP\", \"Expected exactly one catalog row.\", [Schema=schemaName, Object=objectName, Matches=Table.RowCount(Matches)]) else Matches{0},",
          "    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\\\"}),",
          "    RelativePath = Text.Replace(CatalogRow[package_path], \"/\", \"\\\\\"),",
          "    FullPath = Root & \"\\\\\" & RelativePath,",
          "    Raw = try Csv.Document(File.Contents(FullPath), [Delimiter=\",\", Columns=CatalogRow[columns], Encoding=65001, QuoteStyle=QuoteStyle.Csv])",
          "          otherwise error Error.Record(\"SOURCE_READ\", \"Required source could not be read.\", [Path=FullPath, Schema=schemaName, Object=objectName]),",
          "    Headers = Table.PromoteHeaders(Raw, [PromoteAllScalars=true]),",
          "    ExpectedColumns = Json.Document(Text.ToBinary(CatalogRow[header_json], TextEncoding.Utf8)),",
          "    ActualColumns = Table.ColumnNames(Headers),",
          "    MissingColumns = List.Difference(ExpectedColumns, ActualColumns),",
          "    UnexpectedColumns = List.Difference(ActualColumns, ExpectedColumns),",
          "    HeaderCheck = if MissingColumns <> {} or UnexpectedColumns <> {} or ActualColumns <> ExpectedColumns",
          "        then error Error.Record(\"HEADER_MISMATCH\", \"Source he

========== fxReadBuildCsv ==========
Id)),",
          "    AssertedRun = fxAssertSelectedRun(SelectedRun, \"module1_run_id\")",
          "in",
          "    AssertedRun"
        ],
        "kind": "m"
      },
      {
        "name": "fxReadBuildCsv",
        "annotations": [
          {
            "name": "MSBF_ActivationWave",
            "value": "A1a"
          },
          {
            "name": "MSBF_LoadEnabled",
            "value": "false"
          }
        ],
        "expression": [
          "// Reads versioned Power BI-owned catalogs from the WP1/WP2 package root.",
          "(relativePath as text) as table =>",
          "let",
          "    Root = Text.TrimEnd(pBuildRoot, {\"/\", \"\\\\\"}),",
          "    FullPath = Root & \"\\\\\" & Text.Replace(relativePath, \"/\", \"\\\\\"),",
          "    Raw = try Csv.Document(File.Contents(FullPath), [Delimiter=\",\", Encoding=65001, QuoteStyle=QuoteStyle.Csv])",
          "          otherwise error Error.Record(\"BUILD_CATALOG_READ\", \"Power BI build catalog could not be read.\", [Path=FullPath]),",
          "    Headers = Table.PromoteHeaders(Raw, [PromoteAllScalars=true])",
          "in",
          "    Headers"
        ],
        "kind": "m"
      }
    ],
    "relationships": [
      {
        "name": "REL-001",
        "annotations": [
          {
            "name": "MSBF_ControlId",
            "value": "REL-001"
          },
          {
            "name": "MSBF_LocalEngineStatus",
            "value": "PENDING_AUD_REL_005"
          }
        ],
        "fromColumn": "industry_code",
        "fromTable": "DimMerchant",
        "toColumn": "industry_code",
        "toTable": "DimIndustry"
      },
      {
        "name": "REL-002",
        "annotations": [
          {
            "name": "MSBF_ControlId",
            "value": "REL-002"
          },
          {
            "name": "MSBF_LocalEngineStatus",
            "value": "PENDING_AUD_REL_005"
          }
        ],
        "fromColumn": "region_code",
        "fromTable": "DimMerchant",
        "toColumn": "region_code",
        "toTable": "DimRegion"
      },
      {
        "name": "REL-003",
<!-- END_SOURCE_MESSAGE -->


<a id="m-6461635e-33fa-4d5a-94af-9339c276ce0b"></a>
## Assistant · C091-M00067

C091-M00067 · 2026-08-19T09:33:50.746797-04:00 · active path

Preceding visible parent: [C091-M00066](part-05.md#m-2d7dad92-3fd4-4dbd-b478-10e4eefb70a9)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. We now know the exact physical representation: `model.bim` stores each of these M definitions as a **JSON array of individual source lines**. That explains every prior `0 raw JSON values` match.

We can now apply the hotfix without reserializing `model.bim`: patch the three external `.m` files and replace exactly **seven escaped JSON line values** in the raw BIM text. This preserves the rest of the file byte-for-byte.

Your pre-write integrity check already passed, so keep Desktop closed and run the block below.

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

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

if (@(Get-Process PBIDesktop -ErrorAction SilentlyContinue).Count -gt 0) {
    throw "Power BI Desktop is running. Close it before applying HF01."
}

# ------------------------------------------------------------------
# 1. RECONFIRM CURRENT FILES STILL EQUAL PRESERVED BEFORE COPIES
# ------------------------------------------------------------------

$integrity = foreach ($name in $targets.Keys) {
    [pscustomobject]@{
        object = $name
        unchanged = (
            (Get-FileHash $targets[$name] -Algorithm SHA256).Hash -ceq
            (Get-FileHash (Join-Path $beforeRoot "$name.m") -Algorithm SHA256).Hash
        )
    }
}

$integrity += [pscustomobject]@{
    object = "model.bim"
    unchanged = (
        (Get-FileHash $modelPath -Algorithm SHA256).Hash -ceq
        (Get-FileHash (Join-Path $beforeRoot "model.bim") -Algorithm SHA256).Hash
    )
}

$integrity | Format-Table -AutoSize

if (@($integrity | Where-Object { -not $_.unchanged }).Count -gt 0) {
    throw "PRE-WRITE INTEGRITY FAIL. Stop."
}

# ------------------------------------------------------------------
# 2. EXTERNAL M REPAIR FUNCTION
# ------------------------------------------------------------------

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
            throw "Unexpected target $Name"
        }
    }

    if ($result -ceq $Text) {
        throw "No external M change produced for $Name."
    }

    return $result
}

# ------------------------------------------------------------------
# 3. BUILD EXTERNAL BEFORE/AFTER + EXACT 7-LINE DIFF
# ------------------------------------------------------------------

$externalAfter = @{}
$lineDiff = @()

foreach ($name in $targets.Keys) {

    $beforeText = [IO.File]::ReadAllText(
        (Join-Path $beforeRoot "$name.m")
    )

    $afterText = Repair-A1aMDefinition `
        -Name $name `
        -Text $beforeText

    $externalAfter[$name] = $afterText

    $beforeLines = @($beforeText -split "`r?`n")
    $afterLines  = @($afterText  -split "`r?`n")

    $max = [Math]::Max($beforeLines.Count, $afterLines.Count)

    for ($i = 0; $i -lt $max; $i++) {
        $b = if ($i -lt $beforeLines.Count) { $beforeLines[$i] } else { $null }
        $a = if ($i -lt $afterLines.Count)  { $afterLines[$i]  } else { $null }

        if ($b -cne $a) {
            $lineDiff += [pscustomobject]@{
                object = $name
                line_number = $i + 1
                before = $b
                after = $a
            }
        }
    }
}

$lineDiff | Format-Table -AutoSize

if ($lineDiff.Count -ne 7) {
    throw "Expected exactly 7 external M line changes; observed $($lineDiff.Count)."
}

$lineDiff |
    Export-Csv `
        -LiteralPath "$hotfixRoot\M_RUNTIME_EXACT_LINE_DIFF.csv" `
        -NoTypeInformation `
        -Encoding utf8

# ------------------------------------------------------------------
# 4. TARGETED RAW model.bim PATCH
#
# model.bim stores expression as JSON ARRAYS OF LINES.
# These replacements therefore operate on exact escaped line strings.
# ------------------------------------------------------------------

$modelRaw = [IO.File]::ReadAllText(
    (Join-Path $beforeRoot "model.bim")
)

$rawReplacements = @(
    [pscustomobject]@{
        control = "PDataRoot_TrimEnd"
        old = '"    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\\\"}),"'
        new = '"    Root = Text.TrimEnd(pDataRoot, {\"/\", \"\\\"}),"'
        expected_count = 2
    },
    [pscustomobject]@{
        control = "Catalog_Path"
        old = '"    Path = Root & \"\\\\data\\\\POWER_BI_DATA_CATALOG.csv\","'
        new = '"    Path = Root & \"\\data\\POWER_BI_DATA_CATALOG.csv\","'
        expected_count = 1
    },
    [pscustomobject]@{
        control = "CatalogedCsv_RelativePath"
        old = '"    RelativePath = Text.Replace(CatalogRow[package_path], \"/\", \"\\\\\"),"'
        new = '"    RelativePath = Text.Replace(CatalogRow[package_path], \"/\", \"\\\"),"'
        expected_count = 1
    },
    [pscustomobject]@{
        control = "CatalogedCsv_FullPath"
        old = '"    FullPath = Root & \"\\\\\" & RelativePath,"'
        new = '"    FullPath = Root & \"\\\" & RelativePath,"'
        expected_count = 1
    },
    [pscustomobject]@{
        control = "PBuildRoot_TrimEnd"
        old = '"    Root = Text.TrimEnd(pBuildRoot, {\"/\", \"\\\\\"}),"'
        new = '"    Root = Text.TrimEnd(pBuildRoot, {\"/\", \"\\\"}),"'
        expected_count = 1
    },
    [pscustomobject]@{
        control = "BuildCsv_FullPath"
        old = '"    FullPath = Root & \"\\\\\" & Text.Replace(relativePath, \"/\", \"\\\\\"),"'
        new = '"    FullPath = Root & \"\\\" & Text.Replace(relativePath, \"/\", \"\\\"),"'
        expected_count = 1
    }
)

$replacementEvidence = @()

foreach ($r in $rawReplacements) {

    $count = (
        [regex]::Matches(
            $modelRaw,
            [regex]::Escape($r.old)
        )
    ).Count

    $replacementEvidence += [pscustomobject]@{
        control = $r.control
        expected_count = $r.expected_count
        actual_count = $count
        pass = ($count -eq $r.expected_count)
    }

    if ($count -ne $r.expected_count) {
        $replacementEvidence | Format-Table -AutoSize
        throw "Raw BIM replacement control $($r.control) matched $count; expected $($r.expected_count). No writes performed."
    }
}

$replacementEvidence |
    Format-Table -AutoSize

$replacementEvidence |
    Export-Csv `
        -LiteralPath "$hotfixRoot\MODEL_BIM_RAW_REPLACEMENT_CONTROL.csv" `
        -NoTypeInformation `
        -Encoding utf8

# Perform replacements only after ALL match-count controls pass.
foreach ($r in $rawReplacements) {
    $modelRaw = $modelRaw.Replace($r.old, $r.new)
}

# ------------------------------------------------------------------
# 5. WRITE EXACTLY THREE EXTERNAL M FILES + model.bim
# ------------------------------------------------------------------

New-Item -ItemType Directory -Force -Path $afterRoot | Out-Null

foreach ($name in $targets.Keys) {

    [IO.File]::WriteAllText(
        $targets[$name],
        $externalAfter[$name],
        [Text.UTF8Encoding]::new($false)
    )

    [IO.File]::WriteAllText(
        (Join-Path $afterRoot "$name.m"),
        $externalAfter[$name],
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

# ------------------------------------------------------------------
# 6. PARSE model.bim AND VERIFY ARRAY-LINE SEMANTIC PARITY
# ------------------------------------------------------------------

$modelAfter = Get-Content `
    -LiteralPath $modelPath `
    -Raw |
    ConvertFrom-Json

$parity = foreach ($name in $targets.Keys) {

    $expr = @(
        $modelAfter.model.expressions |
        Where-Object { $_.name -ceq $name }
    )

    if ($expr.Count -ne 1) {
        throw "Expected one embedded expression named $name; observed $($expr.Count)."
    }

    $embeddedLines = @($expr[0].expression)

    # Join the array-of-lines into normalized source.
    $embeddedNorm = ($embeddedLines -join "`n").TrimEnd("`r","`n")

    $externalNorm = (
        [IO.File]::ReadAllText($targets[$name]) -replace "`r`n", "`n"
    ).TrimEnd("`r","`n")

    [pscustomobject]@{
        object = $name
        embedded_line_count = $embeddedLines.Count
        normalized_embedded_equals_external = ($embeddedNorm -ceq $externalNorm)
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
    throw "Embedded/external normalized parity failed after write."
}

# ------------------------------------------------------------------
# 7. BEFORE/AFTER HASH EVIDENCE
# ------------------------------------------------------------------

$hashEvidence = foreach ($name in $targets.Keys) {
    [pscustomobject]@{
        object = $name
        artifact = "EXTERNAL_M"
        sha256_before = (
            Get-FileHash `
                (Join-Path $beforeRoot "$name.m") `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        sha256_after = (
            Get-FileHash `
                $targets[$name] `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$hashEvidence += [pscustomobject]@{
    object = "model.bim"
    artifact = "EMBEDDED_MODEL"
    sha256_before = (
        Get-FileHash `
            (Join-Path $beforeRoot "model.bim") `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    sha256_after = (
        Get-FileHash `
            $modelPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()
}

$hashEvidence |
    Export-Csv `
        -LiteralPath "$hotfixRoot\M_RUNTIME_BEFORE_AFTER_HASHES.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host ""
Write-Host "================================================"
Write-Host "A1A-M-RUNTIME-HF01 APPLIED"
Write-Host "External M definitions changed: 3"
Write-Host "External source lines changed:   7"
Write-Host "model.bim patched in place:      YES"
Write-Host "Whole-BIM JSON reserialization:  NO"
Write-Host "Embedded/external parity:        PASS"
Write-Host "================================================"
```

The raw replacement control should report:

```text
PDataRoot_TrimEnd          expected 2   actual 2
Catalog_Path               expected 1   actual 1
CatalogedCsv_RelativePath  expected 1   actual 1
CatalogedCsv_FullPath      expected 1   actual 1
PBuildRoot_TrimEnd         expected 1   actual 1
BuildCsv_FullPath          expected 1   actual 1
```

That totals exactly **7 physical BIM line-value changes**, corresponding to the same seven external-M line changes you already reproduced.

Then the parity table should show all three as `True`.

### After that, prove only three external M files changed

Run:

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
        sha256 = (
            Get-FileHash `
                $file.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }
}

$comparison = foreach ($before in $preTree) {

    $after = @(
        $postTree |
        Where-Object {
            $_.relative_path -ceq $before.relative_path
        }
    )

    if ($after.Count -ne 1) {
        throw "Tree mismatch for $($before.relative_path)"
    }

    [pscustomobject]@{
        relative_path = $before.relative_path
        sha256_before = $before.sha256
        sha256_after = $after[0].sha256
        changed = ($before.sha256 -cne $after[0].sha256)
    }
}

$comparison |
    Export-Csv `
        "$hotfixRoot\POWER_QUERY_TREE_CHANGE_CONTROL.csv" `
        -NoTypeInformation `
        -Encoding utf8

$changed = @(
    $comparison |
    Where-Object { $_.changed }
)

$changed |
    Format-Table `
        relative_path,
        sha256_before,
        sha256_after `
        -AutoSize

Write-Host "Changed external M files:" $changed.Count

if ($changed.Count -ne 3) {
    throw "Expected exactly 3 external M files to change."
}
```

Required:

```text
Changed external M files: 3
```

Finally rerun the corrected shell verifier:

```powershell
$verifier = Join-Path $HOME `
    "Downloads\Verify-A1aTechnicalShellBoundary.ps1"

& $verifier `
    -PackageRoot $work `
    -SourceRoot `
    "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"
```

It must still return 14 tables, 6 relationships, 47 queries, 0 explicit measures, one technical shell page, zero substantive pages/visuals, zero A1b objects, and `status = PASS`. That remains the exact authorized physical boundary. [export reference: filecite | turn9file0 | L63-L79]

If the hotfix block reaches **`A1A-M-RUNTIME-HF01 APPLIED`**, paste the raw replacement-control table and the parity table next.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ab725594-9115-46b0-85f5-c63eda7a9b1e"></a>
## Andrew / user · C091-M00068

C091-M00068 · 2026-08-19T09:54:13.808000-04:00 · active path

Preceding visible parent: [C091-M00067](part-05.md#m-6461635e-33fa-4d5a-94af-9339c276ce0b)

<!-- BEGIN_SOURCE_MESSAGE -->
object                    unchanged
------                    ---------
stg_POWER_BI_DATA_CATALOG      True
fxReadCatalogedCsv             True
fxReadBuildCsv                 True
model.bim                      True


object                    line_number before                                                                after
------                    ----------- ------                                                                -----
stg_POWER_BI_DATA_CATALOG           3     Root = Text.TrimEnd(pDataRoot, {"/", "\\"}),                          Root = Text.TrimEnd(pDataRoot, {"/", "\"}),
stg_POWER_BI_DATA_CATALOG           4     Path = Root & "\\data\\POWER_BI_DATA_CATALOG.csv",                    Path = Root & "\data\POWER_BI_DATA_CATALOG.csv",
fxReadCatalogedCsv                  6     Root = Text.TrimEnd(pDataRoot, {"/", "\\"}),                          Root = Text.TrimEnd(pDataRoot, {"/", "\"}),
fxReadCatalogedCsv                  7     RelativePath = Text.Replace(CatalogRow[package_path], "/", "\\"),     RelativePath = Text.Replace(CatalogRow[package_path], "/", "\"),
fxReadCatalogedCsv                  8     FullPath = Root & "\\" & RelativePath,                                FullPath = Root & "\" & RelativePath,
fxReadBuildCsv                      4     Root = Text.TrimEnd(pBuildRoot, {"/", "\\"}),                         Root = Text.TrimEnd(pBuildRoot, {"/", "\"}),
fxReadBuildCsv                      5     FullPath = Root & "\\" & Text.Replace(relativePath, "/", "\\"),       FullPath = Root & "\" & Text.Replace(relativePath, "/", "\"),


control                   expected_count actual_count pass
-------                   -------------- ------------ ----
PDataRoot_TrimEnd                      2            2 True
Catalog_Path                           1            1 True
CatalogedCsv_RelativePath              1            1 True
CatalogedCsv_FullPath                  1            1 True
PBuildRoot_TrimEnd                     1            1 True
BuildCsv_FullPath                      1            1 True


object                    embedded_line_count normalized_embedded_equals_external
------                    ------------------- -----------------------------------
stg_POWER_BI_DATA_CATALOG                  13                                True
fxReadCatalogedCsv                         27                                True
fxReadBuildCsv                             10                                True


================================================
A1A-M-RUNTIME-HF01 APPLIED
External M definitions changed: 3
External source lines changed:   7
model.bim patched in place:      YES
Whole-BIM JSON reserialization:  NO
Embedded/external parity:        PASS
================================================
PS C:\Windows\System32> $preTree = Import-Csv `
>>     "$hotfixRoot\POWER_QUERY_TREE_BEFORE.csv"
>>
>> $postTree = foreach (
>>     $file in @(
>>         Get-ChildItem `
>>             -LiteralPath (Join-Path $work "power_query") `
>>             -File `
>>             -Recurse `
>>             -Filter "*.m" |
>>         Sort-Object FullName
>>     )
>> ) {
>>     [pscustomobject]@{
>>         relative_path = $file.FullName.Substring($work.Length + 1)
>>         sha256 = (
>>             Get-FileHash `
>>                 $file.FullName `
>>                 -Algorithm SHA256
>>         ).Hash.ToLowerInvariant()
>>     }
>> }
>>
>> $comparison = foreach ($before in $preTree) {
>>
>>     $after = @(
>>         $postTree |
>>         Where-Object {
>>             $_.relative_path -ceq $before.relative_path
>>         }
>>     )
>>
>>     if ($after.Count -ne 1) {
>>         throw "Tree mismatch for $($before.relative_path)"
>>     }
>>
>>     [pscustomobject]@{
>>         relative_path = $before.relative_path
>>         sha256_before = $before.sha256
>>         sha256_after = $after[0].sha256
>>         changed = ($before.sha256 -cne $after[0].sha256)
>>     }
>> }
>>
>> $comparison |
>>     Export-Csv `
>>         "$hotfixRoot\POWER_QUERY_TREE_CHANGE_CONTROL.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> $changed = @(
>>     $comparison |
>>     Where-Object { $_.changed }
>> )
>>
>> $changed |
>>     Format-Table `
>>         relative_path,
>>         sha256_before,
>>         sha256_after `
>>         -AutoSize
>>
>> Write-Host "Changed external M files:" $changed.Count
>>
>> if ($changed.Count -ne 3) {
>>     throw "Expected exactly 3 external M files to change."
>> }

relative_path                                   sha256_before                                                    sha256_after
-------------                                   -------------                                                    ------------
power_query\functions\fxReadBuildCsv.m          d02b486b9dd1f950ce728fc4f9b926ed6e8f57822792b46b2327d756b0e23656 50baff873f4b77162f521e0460d261c3747fa216ab9ea35ce2ef0d32732c68dc
power_query\functions\fxReadCatalogedCsv.m      af950de91052f82dc0bfdc094d0fea395ebf6fe144c047db32b78dff4b9396c7 a4e46ac8367592965a5eb4a848b23b7a856ba1b09ee27ab7a059c7e86cff7a9f
power_query\staging\stg_POWER_BI_DATA_CATALOG.m c643d527e9a0670e9b13dc881dc7e6d7d5fd6077160ca2e79e931785720cd5e7 c100d18b3bdb382752b25604c49c6b232e56d8861c3fa7980d46b3277de06919

Changed external M files: 3
PS C:\Windows\System32> $verifier = Join-Path $HOME `
>>     "Downloads\Verify-A1aTechnicalShellBoundary.ps1"
>>
>> & $verifier `
>>     -PackageRoot $work `
>>     -SourceRoot `
>>     "C:\MSBF\MSBF_PBI_A1A_LOCAL_CONSTRUCTION_R1_20260818"
{
  "schema_version": "1.0",
  "decision_id": "IA-D-R3A-PBI-001",
  "verified_utc": "2026-08-19T13:53:47.9642109Z",
  "package_root": "C:\\MSBF\\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819",
  "semantic_tables": 14,
  "relationships": 6,
  "named_expressions": 33,
  "table_partitions": 14,
  "power_query_queries": 47,
  "explicit_measures": 0,
  "semantic_activation_objects": 67,
  "substantive_report_pages": 0,
  "technical_shell_pages": 1,
  "total_physical_report_pages": 1,
  "visual_objects": 0,
  "bookmark_objects": 0,
  "mobile_visual_layout_files": 0,
  "mobile_state_metadata_present": false,
  "report_extensions_metadata_present": false,
  "page_filters": 0,
  "report_filters": 0,
  "visual_interactions": 0,
  "page_binding_present": false,
  "tooltip_configuration_present": false,
  "a1b_tokens": 0,
  "page_display_name": "A1A_TECHNICAL_SHELL_NO_VISUALS",
  "page_internal_name": "b164c3b67606af1817c0",
  "page_folder_name": "b164c3b67606af1817c0",
  "page_order": "b164c3b67606af1817c0",
  "active_page_name": "b164c3b67606af1817c0",
  "active_page_resolves": true,
  "report_boundary_annotation": "ONE_PHYSICAL_TECHNICAL_SHELL_ZERO_SUBSTANTIVE_REPORT_PAGES_ZERO_VISUALS",
  "classification": [
    "TECHNICAL_CONTAINER_ONLY",
    "NON_SUBSTANTIVE",
    "NOT_REPORT_DESIGN",
    "NOT_PUBLIC_CLAIMABLE"
  ],
  "status": "PASS",
  "failures": [],
  "unchanged_holds": [
    "AUD-SCN-004",
    "AUD-REL-005",
    "AUD-ASOF-003"
  ],
  "pbi_wp2": "HOLD",
  "a1b": "NOT_AUTHORIZED"
}
A1a technical-shell boundary PASS.
One physical technical shell page, zero substantive report pages, and zero visuals.
<!-- END_SOURCE_MESSAGE -->


<a id="m-af520677-151b-48a6-958c-f0baddfabc56"></a>
## Assistant · C091-M00069

C091-M00069 · 2026-08-19T09:54:17.605480-04:00 · active path

Preceding visible parent: [C091-M00068](part-05.md#m-ab725594-9115-46b0-85f5-c63eda7a9b1e)

<!-- BEGIN_SOURCE_MESSAGE -->
The hotfix is now in a good controlled state.

What you have physically established is:

```text
A1A-M-RUNTIME-HF01
External M definitions changed: 3
Exact external source-line changes: 7
model.bim patched in place: YES
Whole-BIM JSON reserialization: NO
Embedded/external normalized parity: PASS
Changed external M files: exactly 3
Shell-aware boundary verification: PASS
```

The post-hotfix verifier also confirms the authorized footprint is still intact:

```text
14 semantic tables
6 relationships
47 Power Query queries
0 explicit measures
67 semantic activation objects

1 physical technical shell page
0 substantive report pages
0 visuals
0 bookmarks
0 A1b objects
active_page_resolves = true
status = PASS
```

That remains consistent with the audit’s technical-shell exception and does not close the three local-engine holds. [export reference: filecite | turn9file0 | L63-L79]

## Resume Desktop and test the repaired queries

Reopen the same derived PBIP:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\project
\MSBF_PBI_A1A_Local_Construction_R1.pbip
```

Do not click either Desktop `Refresh now` banner.

Open:

**Home → Transform data**

### 1. Test the upstream catalog query first

Click:

```text
stg_POWER_BI_DATA_CATALOG
```

It should now show a populated preview instead of:

```text
Expression.Error: The value isn't a single-character string.
```

If it still errors, stop and send the exact error.

### 2. Test the build reader

Click:

```text
fxReadBuildCsv
```

Because this is a function, Power Query may show its function interface rather than rows. That is fine. What we do not want to see is the prior malformed-path failure.

Then click one fact query that previously showed:

```text
BUILD_CATALOG_READ
```

Use:

```text
FactGovernanceControl
```

If the repair is working, it should evaluate rather than inherit the build-catalog error.

## Then perform Refresh Preview Attempt 2

Only after those spot checks are clean:

**Home → Refresh Preview ▼ → Refresh All**

Let the full 47-query evaluation finish.

Do not click **Close & Apply** yet.

If Attempt 2 completes successfully, preserve it immediately in PowerShell:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_POWER_QUERY_REFRESH_PREVIEW_ATTEMPT_2"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    result = "PASS"
    hotfix_id = "A1A-M-RUNTIME-HF01"
    query_inventory = 47
    semantic_queries = 14
    staging_queries = 19
    functions = 5
    parameters = 9
    refresh_preview_succeeded = $true
    close_and_apply_performed = $false
    semantic_model_refresh_performed = $false
    explicit_measures = 0
    a1b_started = $false
} |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -LiteralPath "$ev\E04_POWER_QUERY_REFRESH_ATTEMPT_2_PASS.json" `
        -Encoding utf8
```

Also take a screenshot showing the clean Queries pane after Refresh All.

If **any** query still errors, do not repair it on your own. Preserve the exact error and stop there.

The important transition now is:

```text
Attempt 1     FAIL — common M path-literal defect
HF01          APPLIED — 3 definitions / 7 lines
Static boundary PASS
Attempt 2     NEXT
Close & Apply NOT YET
```

Once Refresh Preview Attempt 2 finishes, tell me whether it passed cleanly and, if not, the exact remaining error.
<!-- END_SOURCE_MESSAGE -->


<a id="m-02e91f09-7a4e-4ea0-87e9-559be04615b2"></a>
## Andrew / user · C091-M00070

C091-M00070 · 2026-08-19T10:05:06.536000-04:00 · active path

Preceding visible parent: [C091-M00069](part-05.md#m-af520677-151b-48a6-958c-f0baddfabc56)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: REQUESTED_SCREENSHOT.png

<!-- BEGIN_SOURCE_MESSAGE -->
See attached screenshot after selecting Refresh All - Many items have a yellow warning and say "Information is required about data privacy." With a continue button following.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5a36e3b7-9ee7-4b0d-a3b0-ad24acb8bf7e"></a>
## Assistant · C091-M00071

C091-M00071 · 2026-08-19T10:05:18.534469-04:00 · active path

Preceding visible parent: [C091-M00070](part-05.md#m-02e91f09-7a4e-4ea0-87e9-559be04615b2)

<!-- BEGIN_SOURCE_MESSAGE -->
This is the expected next gate: **the M-runtime defect is fixed, and Power Query has advanced to data privacy classification**. Do not treat the yellow triangles as query failures yet.

Microsoft documents this exact state: when privacy levels haven’t been assigned, Power Query raises **“Information is required about data privacy”** and the **Continue** button opens the Privacy Levels dialog. [export reference: cite | turn417583search0]

For this A1a run, use a conservative, governed setting. All sources are local files inside the same derived working copy, so set them to the **same privacy level**. I recommend **Private** rather than Public, because these are controlled project artifacts and we do not need to relax isolation unnecessarily. Microsoft notes that Private is the most restrictive classification and that compatible privacy settings are what allow query combinations to proceed. [export reference: cite | turn417583search0 | turn417583search1]

Do this now:

1. Click **Continue** on the yellow privacy banner.
2. In the Privacy Levels dialog, you should see the local source roots—likely the `pDataRoot` and `pBuildRoot` locations, or their underlying file/folder sources.
3. Set **every listed A1a local source** to:
   ```text
   Private
   ```
4. Do **not** choose any option resembling:
   ```text
   Ignore Privacy Levels
   Fast Combine
   Always ignore privacy settings
   ```
   Microsoft explicitly cautions that ignoring privacy levels can allow unintended information transfer between sources. [export reference: cite | turn417583search0]
5. Click **Save/OK** in the privacy dialog and let Power Query continue evaluating.

Because your Desktop appears current, Microsoft’s July 2026 behavior should allow queries that reference other queries and also access sources as long as the privacy levels are compatible; disabling privacy protection should not be necessary. [export reference: cite | turn417583search1]

Before you click Continue, preserve this privacy-gate evidence in PowerShell:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_POWER_QUERY_PRIVACY_GATE"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    refresh_attempt = 2
    state = "PRIVACY_INFORMATION_REQUIRED"
    prior_hotfix = "A1A-M-RUNTIME-HF01"
    intended_privacy_classification = "PRIVATE"
    ignore_privacy_levels = $false
    semantic_model_refresh_performed = $false
    close_and_apply_performed = $false
    a1b_started = $false
} |
    ConvertTo-Json |
    Set-Content `
        -LiteralPath "$ev\E04_PRIVACY_GATE_ATTEMPT2.json" `
        -Encoding utf8
```

Your screenshot is also good evidence of this intermediate state: the full `Queries [47]` inventory is still present, and the engine is no longer reporting the original `single-character string` error. That is meaningful evidence that HF01 cleared the first runtime blocker.

After you click **Continue**, send me a screenshot of the Privacy Levels dialog **before you confirm it**, so I can verify exactly which sources Desktop is asking you to classify.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2dd1085c-5b92-4d0c-a266-6422f9589a24"></a>
## Andrew / user · C091-M00072

C091-M00072 · 2026-08-19T10:19:58.037000-04:00 · active path

Preceding visible parent: [C091-M00071](part-05.md#m-5a36e3b7-9ee7-4b0d-a3b0-ad24acb8bf7e)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: REQUESTED_SCREENSHOT_01(3).png; REQUESTED_SCREENSHOT_02(3).png

<!-- BEGIN_SOURCE_MESSAGE -->
The Data settings are looking at my C:\ root. Selecting Private created errors where the fx would not populate. I updated to Public and selected Refresh All. All data now loads correctly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-745c987b-b63d-482e-9c3c-50a105665b99"></a>
## Assistant · C091-M00073

C091-M00073 · 2026-08-19T10:19:59.726653-04:00 · active path

Preceding visible parent: [C091-M00072](part-05.md#m-2dd1085c-5b92-4d0c-a266-6422f9589a24)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. **Refresh Preview Attempt 2 has now succeeded**, but we should record the privacy behavior precisely rather than calling the Public setting intrinsically “correct.”

Your screenshots show two important physical results:

- `DimAsOfDate` is populated with **123 rows** and no visible column errors.
- `FactValidationResult` is populated with **533 rows**, and the visible validation rows show `PASS`.
- The warning triangles that accompanied the privacy gate are gone from the visible query population.

This means the hotfix cleared the original M-runtime defect and, after the privacy-level change, the 47-query Power Query layer evaluates successfully.

One nuance: setting the **C:\ data source privacy level to Public** is broader than ideal. Power Query privacy classification concerns whether data may be combined with other sources; “Public” does not mean the files themselves were published, but it does tell the Formula Firewall they may be freely combined. Since this machine/source configuration produced errors under Private, we should **preserve Public as an execution-enabling local configuration decision**, not silently characterize it as a governance standard for future deployments.

## 1. Record Attempt 2 and the privacy decision

While Power Query remains open, run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_POWER_QUERY_REFRESH_PREVIEW_ATTEMPT_2"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")

    result = "PASS_AFTER_HF01_AND_LOCAL_PRIVACY_CONFIGURATION"
    hotfix_id = "A1A-M-RUNTIME-HF01"

    query_inventory = 47
    parameters = 9
    functions = 5
    staging_queries = 19
    semantic_queries = 14

    refresh_preview_succeeded = $true

    observed_semantic_examples = @{
        DimAsOfDate = @{
            rows = 123
            visible_column_errors = 0
        }
        FactValidationResult = @{
            rows = 533
            visible_column_errors = 0
            visible_status = "PASS"
        }
    }

    privacy_configuration = @{
        initial_private_attempt = "ERROR_FUNCTIONS_DID_NOT_POPULATE"
        final_local_setting = "PUBLIC"
        configured_source_scope = "C_DRIVE_SOURCE_AS_PRESENTED_BY_POWER_QUERY"
        ignore_privacy_levels = $false
        interpretation = "LOCAL_EXECUTION_CONFIGURATION_NOT_PRODUCTION_GOVERNANCE_STANDARD"
    }

    close_and_apply_performed = $false
    semantic_model_refresh_performed = $false
    explicit_measures = 0
    substantive_report_pages = 0
    technical_shell_pages = 1
    a1b_started = $false

    unchanged_holds = @(
        "AUD-SCN-004",
        "AUD-REL-005",
        "AUD-ASOF-003"
    )
} |
    ConvertTo-Json -Depth 8 |
    Set-Content `
        -LiteralPath "$ev\E04_POWER_QUERY_REFRESH_ATTEMPT_2_PASS.json" `
        -Encoding utf8
```

The audit requires actual refresh/evaluation results and source-to-model evidence, so preserving this intermediate result is important. [export reference: filecite | turn9file0 | L127-L138]

## 2. Save the two successful screenshots

Save your screenshots locally as:

```text
E04_REFRESH_ATTEMPT2_DIMASOFDATE_123_ROWS.png
E04_REFRESH_ATTEMPT2_FACTVALIDATIONRESULT_533_ROWS.png
```

Place them in:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\evidence\local_engine_return
```

Also retain the earlier privacy-gate screenshot and the Attempt-1 error screenshots. We want the complete chronology:

```text
Attempt 1
→ M-runtime failure

HF01
→ 3 definitions / 7 lines

Attempt 2 initial evaluation
→ privacy gate

Private
→ incompatible local evaluation behavior

Public local source classification
→ 47-query evaluation succeeds
```

## 3. We can now perform `Close & Apply`

This is the important next transition: actually loading the 14 semantic tables into the local semantic engine.

In Power Query click:

**Home → Close & Apply**

Do **not** click ordinary Desktop Refresh separately yet.

Power BI should show an **Applying query changes** dialog and begin loading the model.

Let it run to completion without interacting with the report canvas.

### If anything fails

If you get:

- `Load was cancelled`;
- relationship errors;
- duplicate-key errors;
- data type conversion errors;
- privacy/firewall errors;
- query load errors;
- an unexpected request to alter the model;

stop and send me the entire dialog.

Do not click through a substantive error.

## 4. If Close & Apply succeeds

When you return to the blank technical shell, don't save yet.

First inspect the top banners. Ideally, the earlier messages about:

```text
Some of the tables have incomplete or no data.
```

should disappear or materially change.

Then click **Model view** using the relationship/model icon on the left.

We need to see the physically instantiated model.

At this stage we expect exactly:

```text
14 tables
6 relationships
```

and still:

```text
0 explicit measures
1 technical shell page
0 visuals
```

The six relationships are now particularly important because `AUD-REL-005` explicitly requires physical instantiated relationship metadata and filter behavior; static design evidence cannot close it. [export reference: filecite | turn9file5 | L45-L53]

### Send me two things after Close & Apply

1. Tell me whether **Close & Apply completed successfully**.
2. If successful, send a screenshot of **Model view** showing the tables and relationship lines.

Don't manually rearrange, create, delete, activate, or modify any relationship yet. The first Model-view screenshot should capture exactly what Desktop instantiated from the governed A1a project.
<!-- END_SOURCE_MESSAGE -->


<a id="m-74112f56-bd05-48b0-b2b3-4dfcbe39c15c"></a>
## Andrew / user · C091-M00074

C091-M00074 · 2026-08-19T10:25:53.006000-04:00 · active path

Preceding visible parent: [C091-M00073](part-05.md#m-745c987b-b63d-482e-9c3c-50a105665b99)

<!-- BEGIN_SOURCE_MESSAGE -->
The dialog seemed to run correctly but we still have a banner that says "Some of the tables have incomplete or no data."
<!-- END_SOURCE_MESSAGE -->


<a id="m-70090c58-a9d4-4b61-8a43-230295f9ee7c"></a>
## Assistant · C091-M00075

C091-M00075 · 2026-08-19T10:25:54.483224-04:00 · active path

Preceding visible parent: [C091-M00074](part-05.md#m-74112f56-bd05-48b0-b2b3-4dfcbe39c15c)

<!-- BEGIN_SOURCE_MESSAGE -->
That banner alone does **not** establish that `Close & Apply` failed. Given that the apply dialog appeared to complete normally, we should now determine whether it is simply a stale/expected Desktop warning or whether one of the 14 loaded tables is actually incomplete.

Do **not** click the banner's **Refresh now** button yet, and do not save.

### Next: inspect Model view

Click the **Model view** icon on the left—the icon showing connected boxes.

Once Model view opens, look for:

```text
14 table boxes
6 relationship lines
```

Do not move tables or modify relationships.

Send me a screenshot of the **entire Model view**, including the warning banner if it remains visible.

### Why we're checking this first

We already have clean Power Query evidence that the bounded query layer evaluated after HF01. The next audit requirement is physical evidence of the instantiated semantic model—especially the six relationships. The audit specifically retained `AUD-REL-005` until Desktop provides relationship metadata, cardinality, active/inactive state, and filter-behavior evidence. [export reference: filecite | turn9file5 | L45-L53]

The banner could have several explanations, including a table that Desktop considers unprocessed, a table intentionally having no imported rows, or simply state retained from before `Close & Apply`. We should not infer which one from the banner alone.

For now the evidence state is:

```text
Power Query inventory                 47/47 observed
HF01                                  APPLIED
Refresh Preview Attempt 2             PASS
Close & Apply                         APPARENTLY COMPLETED
Semantic-model load                   NEEDS VERIFICATION
"Incomplete or no data" banner        OPEN OBSERVATION
AUD-SCN-004                            HOLD
AUD-REL-005                            HOLD
AUD-ASOF-003                           HOLD
A1b                                    NOT STARTED
```

Please send the full **Model view screenshot** next.
<!-- END_SOURCE_MESSAGE -->


<a id="m-67232b65-018d-4de8-9fd6-22bac0b806c5"></a>
## Andrew / user · C091-M00076

C091-M00076 · 2026-08-19T10:34:50.832000-04:00 · active path

Preceding visible parent: [C091-M00075](part-05.md#m-70090c58-a9d4-4b61-8a43-230295f9ee7c)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: MODEL_VIEW_SCREENSHOT.png

<!-- BEGIN_SOURCE_MESSAGE -->
Model view screenshot attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1e5b801c-03b8-4ab5-82a9-51f92331a0e4"></a>
## Assistant · C091-M00077

C091-M00077 · 2026-08-19T10:34:52.536270-04:00 · active path

Preceding visible parent: [C091-M00076](part-05.md#m-67232b65-018d-4de8-9fd6-22bac0b806c5)

<!-- BEGIN_SOURCE_MESSAGE -->
This screenshot is useful. **The A1a model structure is physically present in Desktop.** I can count all **14 authorized semantic tables**, and I can see the expected relationship network on the left side. The right-side governance/control tables are intentionally disconnected in A1a.

However, the red/orange warning triangles on many table headers and the persistent **“Some of the tables have incomplete or no data”** banner mean we should **not yet claim the semantic-model load passed**. We need to identify what Desktop thinks is incomplete.

### What the screenshot establishes

The 14 tables visible are:

```text
DimIndustry
DimRegion
DimMerchant
DimApplication
DimAcquisitionSource
DimAccountAdvance
DimScenario
DimAsOfDate
DimDate
DimRunCampaign
FactGovernanceControl
FactSourceReconciliation
FactValidationResult
ModelParameters
```

So the physical table count is correct. This is meaningful progress, but `AUD-REL-005` remains held until we verify the instantiated relationship metadata and filter behavior, as the audit requires. [export reference: filecite | turn9file5 | L45-L53]

## Next — click one warning triangle

Don't click **Refresh now** yet.

Click the warning triangle in the upper-right corner of a simple table such as:

```text
DimDate
```

If that triangle itself isn't clickable, hover over it and see whether Desktop gives you a tooltip.

We need the exact reason Desktop associates with the table warning.

If nothing useful appears, switch to **Data view** using the table/grid icon on the left and select:

```text
DimDate
```

Then tell me whether you can see the 123 rows.

After that select:

```text
DimAsOfDate
```

and verify it also displays 123 rows.

Then check:

```text
FactValidationResult
```

and see whether the 533 rows are physically available in Data view.

### Don't refresh again yet

We already know Power Query Preview can produce these datasets. The question now is whether `Close & Apply` loaded them into VertiPaq or whether Desktop retained an unprocessed state. Clicking Refresh now before answering that would blur the evidence between:

```text
Close & Apply result
```

and:

```text
subsequent Desktop refresh result
```

We want those to remain distinct for the audit trail.

So please first **hover/click the warning triangle on `DimDate`**. If it provides no diagnostic, open **Data view → DimDate** and send me a screenshot.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a50ca085-a190-407f-88b5-af7cf8169660"></a>
## Andrew / user · C091-M00078

C091-M00078 · 2026-08-19T10:40:41.823000-04:00 · active path

Preceding visible parent: [C091-M00077](part-05.md#m-1e5b801c-03b8-4ab5-82a9-51f92331a0e4)

<!-- BEGIN_SOURCE_MESSAGE -->
Hovering over the triangles for all 14 tables, the culprit seems to be "Invalid Date". When I go to table view, I see columns exist in all 14 tables but there appear to be no rows.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8dffc3cd-12ba-4a27-9874-18f876e1ae09"></a>
## Assistant · C091-M00079

C091-M00079 · 2026-08-19T10:40:43.795890-04:00 · active path

Preceding visible parent: [C091-M00078](part-05.md#m-a50ca085-a190-407f-88b5-af7cf8169660)

<!-- BEGIN_SOURCE_MESSAGE -->
That identifies the next real local-engine defect.

The evidence now says:

```text
Power Query Preview                 PASS
47-query evaluation                 PASS
Close & Apply                       completed
14 table schemas instantiated       PASS
Rows physically loaded             NO
Desktop table status                Invalid Date
```

So the persistent banner is not merely stale. **The semantic-model load did not succeed.** The tables exist because their metadata was instantiated, but VertiPaq has no rows because processing encountered an `Invalid Date` condition.

Do **not** click **Refresh now**, save the project, or modify any date column yet.

The audit requires physical refresh/evaluation evidence and keeps the as-of behavior control open; we should preserve this executed failure rather than masking it. [export reference: filecite | turn9file0 | L127-L138]

### First, capture this state

In PowerShell run:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1A_CLOSE_AND_APPLY_ATTEMPT_1"
    timestamp_local = (Get-Date).ToString("o")
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")

    result = "FAILED_SEMANTIC_PROCESSING_INVALID_DATE"

    prior_power_query_preview = "PASS"
    prior_hotfix = "A1A-M-RUNTIME-HF01"

    semantic_tables_physically_instantiated = 14
    table_columns_visible = $true
    table_rows_visible = $false
    desktop_table_warning = "Invalid Date"
    incomplete_or_no_data_banner = $true

    desktop_refresh_after_close_apply = $false
    manual_model_repair_performed = $false
    project_saved_after_failure = $false

    explicit_measures = 0
    substantive_report_pages = 0
    technical_shell_pages = 1
    a1b_started = $false

    unchanged_holds = @(
        "AUD-SCN-004",
        "AUD-REL-005",
        "AUD-ASOF-003"
    )
} |
    ConvertTo-Json -Depth 6 |
    Set-Content `
        -LiteralPath "$ev\E05_CLOSE_AND_APPLY_ATTEMPT1_INVALID_DATE.json" `
        -Encoding utf8
```

Save your Model-view screenshot as:

```text
E05_MODEL_VIEW_INVALID_DATE_AFTER_CLOSE_APPLY.png
```

If practical, also take one Data-view screenshot showing an instantiated table with columns but no rows.

## Now diagnose the date failure without changing anything

Return to:

**Home → Transform data**

Do **not** Refresh All again.

We already know the preview layer succeeds. We need to inspect the date values and data types being handed to VertiPaq.

Start with `DimDate`.

Click:

```text
DimDate
```

Then inspect the `Date` column header.

Please tell me exactly what its Power Query data-type icon is:

- calendar = `Date`
- calendar + clock = `Date/Time`
- `ABC` = Text
- `123` = numeric
- something else

Then click the dropdown on the `Date` column and choose:

**Remove Empty**? **No. Don't alter anything.**

Instead, select the `Date` column and go to:

**View → Column quality**

and:

**View → Column profile**

We need to know whether Power Query reports:

```text
Valid 100%
Error 0%
Empty 0%
```

Your earlier `DimAsOfDate` screenshot showed precisely that sort of clean preview, which makes this particularly interesting: the invalid-date failure may be coming from the **semantic model's column metadata**, rather than bad source values.

### One specific clue I want checked

In your earlier Power Query screenshot, `DimAsOfDate[AsOfDate]` showed values beginning:

```text
7/23/2026
7/24/2026
...
```

with 123 distinct values and no preview errors. If `DimDate[Date]` is similarly 100% valid in Power Query but Desktop still marks it `Invalid Date`, we should inspect `model.bim` for the semantic column definitions—especially their `dataType`, `formatString`, and any date-table annotations—before changing the M code.

That distinction matters:

```text
bad Power Query date values
→ transformation/data defect

clean Power Query dates + Invalid Date during model processing
→ semantic metadata/type/format defect
```

The second case is increasingly likely because **all fourteen tables have zero loaded rows**, even tables that do not fundamentally depend on a date dimension. A processing failure in one model partition can leave the entire apply transaction unprocessed.

For now, please send me **one screenshot of `DimDate` in Power Query with Column quality/profile visible**, including the `Date` column's type icon. We should diagnose this before performing another refresh.
<!-- END_SOURCE_MESSAGE -->


<a id="m-62f4a1cb-5cb5-4e15-a556-d007e73680e7"></a>
## Andrew / user · C091-M00080

C091-M00080 · 2026-08-19T10:48:45.091000-04:00 · active path

Preceding visible parent: [C091-M00079](part-05.md#m-8dffc3cd-12ba-4a27-9874-18f876e1ae09)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: DIM_DATE_SCREENSHOT.png

<!-- BEGIN_SOURCE_MESSAGE -->
DIMDATE screenshot attached.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5867cc1f-02c1-4f1b-9196-0e4b74adc7c2"></a>
## Assistant · C091-M00081

C091-M00081 · 2026-08-19T10:48:48.899022-04:00 · active path

Preceding visible parent: [C091-M00080](part-05.md#m-62f4a1cb-5cb5-4e15-a556-d007e73680e7)

<!-- BEGIN_SOURCE_MESSAGE -->
This is strong diagnostic evidence. `DimDate` itself is **not producing invalid dates in Power Query**.

Your screenshot shows:

```text
DimDate[Date]
Data type: Date
Rows: 123
Distinct: 123
Valid: 100%
Error: 0%
Empty: 0%

Range begins: 7/23/2026
IsSourceRunAsOf on 7/23/2026: TRUE
```

The other visible columns are also 100% valid. So we should **not change `DimDate` M code**.

That materially shifts the diagnosis toward the semantic-model metadata or another date-typed column elsewhere causing the transactional model processing failure.

## Next diagnostic: inspect `model.bim` date metadata

Do not make any changes in Power Query. Leave Desktop/Power Query open if convenient, but don't Apply or Refresh.

Open a separate PowerShell 7 window and run this **read-only** diagnostic:

```powershell
$work = "C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819"
$ev   = Join-Path $work "evidence\local_engine_return"

$modelPath = Join-Path $work `
    "project\MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$model = Get-Content `
    -LiteralPath $modelPath `
    -Raw |
    ConvertFrom-Json

$dateColumns = foreach ($table in @($model.model.tables)) {

    foreach ($column in @($table.columns)) {

        $dataType = if (
            $null -ne $column.PSObject.Properties["dataType"]
        ) {
            [string]$column.dataType
        } else {
            ""
        }

        $formatString = if (
            $null -ne $column.PSObject.Properties["formatString"]
        ) {
            [string]$column.formatString
        } else {
            ""
        }

        if (
            $dataType -match "date" -or
            $formatString -match "[dMy]"
        ) {
            [pscustomobject]@{
                table = $table.name
                column = $column.name
                data_type = $dataType
                format_string = $formatString
                source_column = if (
                    $null -ne $column.PSObject.Properties["sourceColumn"]
                ) {
                    $column.sourceColumn
                } else {
                    ""
                }
            }
        }
    }
}

$dateColumns |
    Sort-Object table,column |
    Format-Table -AutoSize

$dateColumns |
    Export-Csv `
        -LiteralPath "$ev\E05_MODEL_DATE_COLUMN_METADATA.csv" `
        -NoTypeInformation `
        -Encoding utf8

Write-Host ""
Write-Host "Date/date-formatted semantic columns:" $dateColumns.Count
```

Then run this second read-only diagnostic for the two date dimensions specifically:

```powershell
foreach ($tableName in @("DimDate","DimAsOfDate")) {

    Write-Host ""
    Write-Host "================ $tableName ================"

    $table = @(
        $model.model.tables |
        Where-Object { $_.name -ceq $tableName }
    )[0]

    $table.columns |
        Select-Object `
            name,
            dataType,
            formatString,
            sourceColumn |
        Format-Table -AutoSize
}
```

### What I'm looking for

For the physical date columns, something like this is normal:

```text
DimDate      Date       dateTime    M/d/yyyy
DimAsOfDate  AsOfDate   dateTime    M/d/yyyy
```

But we are looking for anomalies such as:

```text
dataType = date
```

if the tabular model expects `dateTime`, a malformed `formatString`, a text field assigned date metadata, or some other semantic column being treated as a date unexpectedly.

Power Query and the semantic model have different type systems, so **Power Query `type date` being valid does not by itself prove the corresponding `model.bim` column metadata is valid**.

## Also preserve this clean DimDate evidence

Save the screenshot as:

```text
E05_DIMDATE_POWER_QUERY_123_ROWS_100PCT_VALID.png
```

in:

```text
C:\MSBF\MSBF_PBI_A1A_TECHNICAL_SHELL_WORKING_R1_20260819
\evidence\local_engine_return
```

The important evidence chain is now:

```text
Power Query DimDate
    123 rows
    Date type
    100% valid
    0% errors
        ↓
Close & Apply
        ↓
Desktop semantic model
    "Invalid Date"
    columns instantiated
    rows not processed
```

That is much more diagnostic than simply seeing the Desktop warning.

Also, your screenshot physically confirms `IsSourceRunAsOf = TRUE` for **July 23, 2026**, which aligns with the frozen accepted source/evidence cutoff. [export reference: filecite | turn9file4 | L17-L21] It does **not** close `AUD-ASOF-003`, but it is useful positive evidence for the eventual control package.

Paste the output of the **date-column metadata commands** next. Do not change any date types yet.
<!-- END_SOURCE_MESSAGE -->


<a id="m-babfb37a-fc70-4205-bda7-b8d3af9e4545"></a>
## Andrew / user · C091-M00082

C091-M00082 · 2026-08-19T10:50:03.232000-04:00 · active path

Preceding visible parent: [C091-M00081](part-05.md#m-5867cc1f-02c1-4f1b-9196-0e4b74adc7c2)

<!-- BEGIN_SOURCE_MESSAGE -->
table                column                         data_type format_string source_column
-----                ------                         --------- ------------- -------------
DimAccountAdvance    booking_date                   dateTime  Short Date    booking_date
DimAccountAdvance    created_at                     dateTime  Short Date    created_at
DimAccountAdvance    first_expected_remittance_date dateTime  Short Date    first_expected_remittance_date
DimAccountAdvance    funding_date                   dateTime  Short Date    funding_date
DimAccountAdvance    monitoring_start_date          dateTime  Short Date    monitoring_start_date
DimAccountAdvance    portfolio_activation_date      dateTime  Short Date    portfolio_activation_date
DimAcquisitionSource effective_end_date             dateTime  Short Date    effective_end_date
DimAcquisitionSource effective_start_date           dateTime  Short Date    effective_start_date
DimApplication       application_date               dateTime  Short Date    application_date
DimApplication       as_of_date                     dateTime  Short Date    as_of_date
DimAsOfDate          AsOfDate                       dateTime  Short Date    AsOfDate
DimDate              Date                           dateTime  Short Date    Date
DimIndustry          effective_end_date             dateTime  Short Date    effective_end_date
DimIndustry          effective_start_date           dateTime  Short Date    effective_start_date
DimMerchant          created_date                   dateTime  Short Date    created_date
DimMerchant          incorporation_date             dateTime  Short Date    incorporation_date
DimRunCampaign       as_of_date                     dateTime  Short Date    as_of_date
DimRunCampaign       completed_at                   dateTime  Short Date    completed_at
DimRunCampaign       created_at                     dateTime  Short Date    created_at
DimRunCampaign       started_at                     dateTime  Short Date    started_at


Date/date-formatted semantic columns: 20
PS C:\Windows\System32> foreach ($tableName in @("DimDate","DimAsOfDate")) {
>>
>>     Write-Host ""
>>     Write-Host "================ $tableName ================"
>>
>>     $table = @(
>>         $model.model.tables |
>>         Where-Object { $_.name -ceq $tableName }
>>     )[0]
>>
>>     $table.columns |
>>         Select-Object `
>>             name,
>>             dataType,
>>             formatString,
>>             sourceColumn |
>>         Format-Table -AutoSize
>> }

================ DimDate ================

name               dataType formatString sourceColumn
----               -------- ------------ ------------
Date               dateTime Short Date   Date
Year               int64                 Year
Quarter            string                Quarter
MonthNumber        int64                 MonthNumber
MonthName          string                MonthName
MonthYear          string                MonthYear
IsEvidenceEndpoint boolean               IsEvidenceEndpoint
IsSourceRunAsOf    boolean               IsSourceRunAsOf


================ DimAsOfDate ================

name               dataType formatString sourceColumn
----               -------- ------------ ------------
AsOfDate           dateTime Short Date   AsOfDate
Year               int64                 Year
Quarter            string                Quarter
MonthNumber        int64                 MonthNumber
MonthName          string                MonthName
MonthYear          string                MonthYear
IsEvidenceEndpoint boolean               IsEvidenceEndpoint
IsSourceRunAsOf    boolean               IsSourceRunAsOf
IsDefaultAsOf      boolean               IsDefaultAsOf
<!-- END_SOURCE_MESSAGE -->
