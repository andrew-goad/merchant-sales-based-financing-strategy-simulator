# MSBF - Power BI Executive Portfolio Intelligence

Part 18 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-17.md)
[Next part](part-19.md)

<a id="m-b2cc4070-adbe-4bee-93e4-572d170019f8"></a>
## Assistant · C091-M00232

C091-M00232 · 2026-08-21T08:34:09.469490-04:00 · active path

Preceding visible parent: [C091-M00231](part-17.md#m-b48209a6-5d02-4c18-a416-6fc5a0569ee9)

<!-- BEGIN_SOURCE_MESSAGE -->
This is enough to classify the remaining two `model.bim` differences as **Power BI-authored serialization metadata rather than substantive semantic drift**.

After reversing the authorized measure change in memory, the only residual differences are the `PBI_ResultType` annotations on `DimDate` and `DimRunCampaign`, each changing from `Table` to `Exception`. Every other annotation on those tables is identical; their names, import partitions, partition source structures, columns, relationships, measures, activation-wave annotations, and local-engine-status annotations are unchanged. More importantly, the exhaustive JSON comparison found **no other parsed-model difference**. The focused authorization expressly permits ordinary Power BI serialization changes mechanically caused by the one authorized measure edit and calls for separating that metadata from substantive model changes. [export reference: filecite | turn39file0 | L8-L11] [export reference: filecite | turn39file1 | L25-L30]

So the final physical classification is now:

```text
AUTHORIZED SEMANTIC CHANGE
1 measure expression:
ModelParameters[Source Reconciliation Pass]

DESKTOP / SERIALIZATION STATE
Report/.pbi/localSettings.json
  securityBindingsSignature only

SemanticModel/.pbi/localSettings.json
  securityBindingsSignature only

SemanticModel/.pbi/cache.abf
  Desktop processed-model cache

model.bim serialization metadata:
DimDate[PBI_ResultType]         Table → Exception
DimRunCampaign[PBI_ResultType] Table → Exception

NO OTHER PARSED MODEL DIFFERENCE
```

The original supplied validator should remain preserved as **FAIL at an overly narrow physical-file assertion**. The serialization-aware diagnostic should remain preserved as **PASS**. We should not alter either the executed project or the original validator merely to manufacture a one-file diff.

## Final freeze procedure

First, if Power BI Desktop or DAX Studio is still open, close both normally now. Do not make any further edit or refresh. If Desktop asks whether to save changes and you have not made any change since the successful refresh/evidence capture, choose the normal close path without intentionally editing anything.

Then verify both processes are gone:

```powershell
Get-Process `
    -Name PBIDesktop,DaxStudio `
    -ErrorAction SilentlyContinue |
    Select-Object Id,ProcessName,StartTime |
    Format-Table -AutoSize
```

The desired output is no processes.

Now run the following.

### 1. Record the resolved serialization classification

```powershell
$ErrorActionPreference = "Stop"

$work   = "C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820"
$return = Join-Path $work "evidence\local_engine_return"

$classification = @'
# A1b Focused R2 — Final Serialization Classification

## Governing semantic correction

The only authorized substantive semantic correction is:

ModelParameters[Source Reconciliation Pass]

The normalized expression hashes reconcile exactly to the focused-remediation
authorization:

- predecessor expression:
  cec29977bab86071d1209afaa1aaa5738f1a7f6d5c0d28791bbc847fcca1c1f5

- Focused R2 replacement expression:
  98c2a0d31349e30277192dfa531ec78066f883899895286961249d38000daac0

## Executed physical project differences

The post-Desktop project retains exactly 16 physical project files.

Relative to the controlling predecessor, exactly four project files changed:

1. Report/.pbi/localSettings.json
2. SemanticModel/.pbi/cache.abf
3. SemanticModel/.pbi/localSettings.json
4. SemanticModel/model.bim

No project file was added or deleted.

## Local-settings classification

Both changed localSettings.json files retain their original JSON structure.

Their only observed changed value is:

securityBindingsSignature

This is classified as Desktop-local security-binding serialization metadata.

## cache.abf classification

SemanticModel/.pbi/cache.abf is the Power BI Desktop processed-model cache.

Its post-refresh physical change is preserved as executed Desktop state and is not
treated as an authored semantic-model change.

## model.bim exact semantic classification

An exhaustive parsed-JSON comparison was performed after replacing only the
authorized Focused R2 Source Reconciliation Pass expression with the controlling
predecessor expression in memory.

Exactly two residual parsed differences remained:

DimDate
  annotation: PBI_ResultType
  predecessor: Table
  executed R2: Exception

DimRunCampaign
  annotation: PBI_ResultType
  predecessor: Table
  executed R2: Exception

For both tables:

- table identity is unchanged;
- annotation identity is unchanged;
- MSBF_ActivationWave remains A1a;
- MSBF_LocalEngineStatus remains PENDING_LOCAL_DESKTOP_EVIDENCE;
- PBI_NavigationStepName remains Navigation;
- partition mode remains import;
- partition source structure remains unchanged.

No other parsed semantic-model difference was identified after reversing the
authorized measure expression in memory.

The two PBI_ResultType values are therefore classified as Power BI-authored
serialization/runtime annotation metadata, not as an additional source-owner
semantic correction.

## Validator disposition

The supplied Validate-A1bFocusedR2Static.py validator remains preserved unchanged.

It fails before its substantive checks because it requires the complete physical
project diff to contain model.bim only.

That physical-file predicate is narrower than the focused-remediation authorization,
which expressly permits ordinary Power BI serialization caused by the authorized
one-measure correction.

A copied serialization-aware diagnostic validator was used without altering the
supplied validator. It passed all remaining substantive controls and established:

- 32 tables
- 32 relationships
- 79 Power Query objects
- 60 measures
- exactly one changed measure expression
- one technical shell
- zero substantive pages
- zero visuals
- REL-076 as the sole inactive relationship

The original validator failure and the serialization-aware PASS are both retained
for Independent Audit review.

## No normalization

No executed-state file has been restored merely to force the project into a
one-file physical diff.

No PBI_ResultType annotation has been edited.

No cache or local-settings file has been replaced.

No additional semantic remediation has been performed.

Independent Audit retains final acceptance authority.
'@

$classification |
    Set-Content `
        -LiteralPath "$return\R2_E107_FINAL_SERIALIZATION_CLASSIFICATION.md" `
        -Encoding utf8
```

### 2. Re-run the final serialization-aware validator after Desktop closure

The copied diagnostic validator already exists in the evidence directory. Run it once more against the now-closed, stable filesystem state:

```powershell
$diagnosticValidator = Join-Path $return `
    "R2_E103_Validate-A1bFocusedR2Static_SERIALIZATION_AWARE_DIAGNOSTIC.py"

& "C:\Python314\python.exe" `
    $diagnosticValidator `
    $work *>&1 |
    Tee-Object `
        -FilePath "$return\R2_E107_FINAL_POST_CLOSE_SERIALIZATION_AWARE_STATIC_BOUNDARY.txt"
```

Required final disposition:

```text
status                      PASS
tables                      32
relationships               32
power_query_objects         79
measures                    60
technical_shell_pages       1
substantive_pages           0
visuals                     0
inactive_relationships      REL-076 only
changed_measure_expressions Source Reconciliation Pass only
```

If it does **not** pass, stop and send me the result.

### 3. Create the definitive post-close project manifest and root hash

Use the same root-hash definition as the supplied validator:

```powershell
$project = Join-Path $work "project"

$projectManifest = @(
    Get-ChildItem `
        -LiteralPath $project `
        -File `
        -Recurse `
        -Force |
    Sort-Object {
        $_.FullName.Substring($project.Length + 1).Replace('\','/').ToLowerInvariant()
    } |
    ForEach-Object {
        [pscustomobject]@{
            relative_path =
                $_.FullName.Substring($project.Length + 1).Replace('\','/')

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
        -LiteralPath "$return\R2_E107_FINAL_PROJECT_MANIFEST.csv" `
        -NoTypeInformation `
        -Encoding utf8

$rootMaterial = ""

foreach (
    $row in @(
        $projectManifest |
        Sort-Object { $_.relative_path.ToLowerInvariant() }
    )
) {
    $rootMaterial += (
        $row.relative_path + "`t" +
        $row.bytes + "`t" +
        $row.sha256 + "`n"
    )
}

$rootBytes = [Text.Encoding]::UTF8.GetBytes($rootMaterial)

$rootHash = (
    [BitConverter]::ToString(
        [Security.Cryptography.SHA256]::Create().ComputeHash(
            $rootBytes
        )
    )
).Replace("-","").ToLowerInvariant()

$modelPath = Join-Path $project `
    "MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"

$modelHash = (
    Get-FileHash `
        -LiteralPath $modelPath `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

[pscustomobject]@{
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    project_files = $projectManifest.Count
    project_root_sha256 = $rootHash
    model_bim_sha256 = $modelHash

    controlling_predecessor_project_root =
        "e3ec3953c97d29d289ee111d74a63677dbab18100886a53493188befee2b2740"

    status = "FINAL_EXECUTED_FOCUSED_R2_IDENTITY"
} |
    ConvertTo-Json -Depth 5 |
    Set-Content `
        -LiteralPath "$return\R2_E107_FINAL_EXECUTED_PROJECT_IDENTITY.json" `
        -Encoding utf8

Write-Host ""
Write-Host "Final project files:" $projectManifest.Count
Write-Host "Final project root: " $rootHash
Write-Host "Final model.bim:    " $modelHash
```

Do **not** assume the root remains `4d67e1...` until this post-close calculation says so.

### 4. Create the source-owner final disposition

```powershell
$finalDisposition = @'
# MSBF Power BI A1b Focused R2 — Source-Owner Final Disposition

## Focused remediation

The Focused R2 correction was derived from controlling predecessor project root:

e3ec3953c97d29d289ee111d74a63677dbab18100886a53493188befee2b2740

Exactly one source-owner semantic correction was authorized and executed:

ModelParameters[Source Reconciliation Pass]

The corrected measure preserves the qualified source status:

PASS_A1A_R3_STATIC

and requires exact source and validation cardinalities.

No source carrier was normalized to literal PASS.

## Live-engine re-performance

R2_E01:
All 60 measures compiled/evaluated in one live-engine query.

R2_E02:
FactSourceReconciliation:
- rows = 214
- distinct SourceObjectKey = 214
- PASS_A1A_R3_STATIC = 214

FactValidationResult:
- rows = 533
- distinct ValidationControlKey = 533
- PASS = 533

Source Reconciliation Pass = 1.

R2_E03:
The exact control baseline returned gate 1.
Every truncated, duplicate, missing, unexpected-status, extra-control and
dual-extra adversarial population returned gate 0.

R2_E04:
Endpoint availability = 0 / 1 / 0 across:
- 2026-11-21
- 2026-11-22
- 2026-11-23

Post-evidence state = HOLD_OUTSIDE_EVIDENCE.

R2_E05:
At the evidence endpoint the six core endpoint populations reconcile to:

- FactGovernanceControl = 9
- FactMonitoringEndpoint = 59
- FactAccountCertification = 59
- FactPortfolioPerformanceEndpoint = 59
- FactServicingQueueEndpoint = 3
- FactPortfolioKPIEndpoint = 72

R2_E06:
Endpoint measure behavior reconciles, including:

- Certified Exposure = 785.48
- Servicing Burden Units = 7
- Endpoint Open Servicing Queue = 2

R2_E07:
- tables = 32
- columns = 849
- measures = 60
- relationships = 32
- active relationships = 31
- REL-076 sole inactive
- zero bidirectional relationships

R2_E08 / R2_E09:
All 31 active relationships demonstrate populated-key filter propagation after
the six targeted follow-up cases.

R2_E10:
32 / 32 physical relationships return literal zero orphan keys.

R2_E11:
Scenario isolation remains:

BASELINE:
- 750 application-scenario rows
- 44 account paths

RECESSION_ENERGY:
- 750 application-scenario rows
- 15 account paths

## Privacy/source nonregression

The isolated read-only SMB source remains:

\\localhost\MSBF_PBI_A1B_SYNTHETIC

The 222 synthetic-root files reconcile exactly to the governed manifest.

Power BI Desktop exposes the dedicated UNC source in Data Source Settings.

Its privacy classification was physically captured.

Global privacy enforcement remains enabled and global privacy-ignore remains disabled.

pDataRoot and pBuildRoot remain unchanged.

## Report boundary

- technical shell pages = 1
- substantive pages = 0
- visuals = 0
- bookmarks = 0

No substantive report construction occurred.

## Physical Desktop serialization

Post-execution physical serialization is fully disclosed.

Exactly four project files differ from the controlling predecessor:

- Report/.pbi/localSettings.json
- SemanticModel/.pbi/cache.abf
- SemanticModel/.pbi/localSettings.json
- SemanticModel/model.bim

The two localSettings files differ only in securityBindingsSignature.

cache.abf is processed Desktop cache state.

Within parsed model.bim, after reversing the authorized measure expression in
memory, only two residual Power BI annotation values differ:

- DimDate PBI_ResultType: Table -> Exception
- DimRunCampaign PBI_ResultType: Table -> Exception

All remaining parsed model semantics reconcile to the predecessor.

The original supplied static validator remains preserved with its one-physical-file
assertion failure.

A serialization-aware diagnostic copy passes all substantive static controls.

Independent Audit is asked to classify the disclosed Desktop serialization under
the authorization's ordinary-serialization allowance rather than having the source
owner normalize the executed state.

## Governing status

ER-PBI-008:
FOCUSED R2 EVIDENCE COMPLETE — PENDING INDEPENDENT AUDIT

ER-PBI-010:
FOCUSED R2 EVIDENCE COMPLETE — PENDING INDEPENDENT AUDIT

PBI-WP2:
HOLD

Substantive report construction:
NOT AUTHORIZED

Publication:
NOT AUTHORIZED

Deployment:
NOT AUTHORIZED

Production readiness:
NOT CLAIMED

Public Power BI milestone:
NOT AUTHORIZED
'@

$finalDisposition |
    Set-Content `
        -LiteralPath "$return\R2_E107_SOURCE_OWNER_FINAL_DISPOSITION.md" `
        -Encoding utf8
```

## Build the Independent Audit carrier

Use:

```text
MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821
```

### 5. Create submission directories

```powershell
$submissionName =
    "MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821"

$submissionRoot = Join-Path "C:\MSBF" $submissionName

if (Test-Path -LiteralPath $submissionRoot) {
    throw "STOP: submission root already exists. Do not overwrite it."
}

New-Item `
    -ItemType Directory `
    -Path $submissionRoot |
    Out-Null

foreach ($folder in @(
    "authority",
    "project",
    "power_query",
    "synthetic_root",
    "dax",
    "tools",
    "evidence"
)) {
    New-Item `
        -ItemType Directory `
        -Path (Join-Path $submissionRoot $folder) |
        Out-Null
}
```

### 6. Copy the exact controlled carriers

```powershell
foreach ($folder in @(
    "authority",
    "project",
    "power_query",
    "synthetic_root",
    "dax",
    "tools",
    "evidence"
)) {

    $source = Join-Path $work $folder
    $dest   = Join-Path $submissionRoot $folder

    if (-not (Test-Path -LiteralPath $source)) {
        throw "STOP: required component missing: $source"
    }

    Get-ChildItem `
        -LiteralPath $source `
        -Force |
        Copy-Item `
            -Destination $dest `
            -Recurse `
            -Force
}
```

### 7. Add a read-first audit request

```powershell
$auditRequest = @'
# MSBF Power BI A1b Focused R2 — Independent Audit Submission

## Requested review

This is the bounded Focused R2 resubmission under:

- ER-PBI-008
- ER-PBI-010

The source owner requests Independent Audit disposition of the authorized
Source Reconciliation Pass remediation and its required re-execution evidence.

No PBI-WP2 acceptance, substantive report construction, publication, deployment,
production-readiness claim or public Power BI milestone is requested.

## Controlling predecessor

Project root:

e3ec3953c97d29d289ee111d74a63677dbab18100886a53493188befee2b2740

## Authorized semantic correction

Exactly:

ModelParameters[Source Reconciliation Pass]

The replacement expression preserves PASS_A1A_R3_STATIC and requires exact:

214 source rows
214 distinct SourceObjectKey
214 accepted PASS_A1A_R3_STATIC rows

533 validation rows
533 distinct ValidationControlKey
533 accepted PASS rows

No Power Query definition, source carrier, table, relationship, source root,
other measure, page, visual, bookmark, filter, tooltip, drillthrough or mobile
layout was intentionally changed.

## Execution result

The supplied live-engine evidence establishes:

- all 60 measures execute;
- exact 214/214/214 and 533/533/533 populations;
- Source Reconciliation Pass = 1;
- adversarial fail-closed controls PASS;
- endpoint availability = 0 / 1 / 0;
- six core endpoint gates reconcile;
- endpoint measure behavior reconciles;
- 32 tables / 849 columns / 60 measures / 32 relationships;
- 31/31 active relationship propagation;
- 32/32 zero orphan controls;
- exact scenario isolation;
- privacy/source-root nonregression;
- one technical shell;
- zero substantive pages;
- zero visuals.

## Disclosed Desktop serialization

The supplied original static validator remains unchanged and fails at its
physical-file assertion because post-Desktop execution produced four changed
physical project files rather than model.bim only.

The governing remediation authorization expressly permits ordinary Power BI
serialization mechanically caused by the one authorized measure correction.

The four physical differences are:

1. Report/.pbi/localSettings.json
2. SemanticModel/.pbi/cache.abf
3. SemanticModel/.pbi/localSettings.json
4. SemanticModel/model.bim

The localSettings files differ only in securityBindingsSignature.

cache.abf is Desktop processed-model cache state.

The normalized predecessor and current measure-expression hashes exactly match
the authorization.

After reversing only the authorized measure expression in memory, the only
remaining parsed model differences are:

DimDate:
PBI_ResultType = Table -> Exception

DimRunCampaign:
PBI_ResultType = Table -> Exception

No other parsed semantic-model difference remains.

A copied serialization-aware diagnostic validator passes all substantive static
controls. The supplied original validator and its failure remain preserved.

Independent Audit is expressly asked to determine whether these disclosed
Desktop-generated physical/annotation differences fall within the authorized
ordinary-serialization allowance.

The source owner has not restored or normalized executed-state files merely to
force a one-file physical diff.

## Requested disposition

Please determine:

1. ER-PBI-008 focused-remediation disposition.
2. ER-PBI-010 live-control re-performance disposition.
3. Whether the disclosed three .pbi physical changes are ordinary authorized
   Desktop serialization.
4. Whether the two PBI_ResultType annotation changes are ordinary Power BI
   serialization/runtime metadata rather than an unauthorized semantic change.
5. Whether the one-measure correction is accepted as the sole substantive
   semantic remediation.
6. Whether AUD-ASOF-003B is now closed.
7. Whether any further Focused R2 correction or re-performance is required.
8. Explicitly preserve or revise the existing PBI-WP2 HOLD.

Do not infer PBI-WP2 acceptance from a successful Focused R2 decision.
'@

$auditRequest |
    Set-Content `
        -LiteralPath "$submissionRoot\00_INDEPENDENT_AUDIT_REQUEST.md" `
        -Encoding utf8
```

### 8. Reconcile every copied file

```powershell
$copyChecks = @()

foreach ($folder in @(
    "authority",
    "project",
    "power_query",
    "synthetic_root",
    "dax",
    "tools",
    "evidence"
)) {

    $sourceRoot = Join-Path $work $folder
    $destRoot   = Join-Path $submissionRoot $folder

    $sourceFiles = @(
        Get-ChildItem `
            -LiteralPath $sourceRoot `
            -File `
            -Recurse `
            -Force |
        Sort-Object FullName
    )

    foreach ($sourceFile in $sourceFiles) {

        $relative =
            $sourceFile.FullName.Substring($sourceRoot.Length + 1)

        $destFile = Join-Path $destRoot $relative

        $sourceHash = (
            Get-FileHash `
                -LiteralPath $sourceFile.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        $exists = Test-Path -LiteralPath $destFile

        $destHash = if ($exists) {
            (
                Get-FileHash `
                    -LiteralPath $destFile `
                    -Algorithm SHA256
            ).Hash.ToLowerInvariant()
        }
        else {
            ""
        }

        $copyChecks += [pscustomobject]@{
            component = $folder
            relative_path = $relative
            source_sha256 = $sourceHash
            copied_sha256 = $destHash
            copied_exists = $exists
            pass = (
                $exists -and
                ($sourceHash -ceq $destHash)
            )
        }
    }
}

$copyChecks |
    Export-Csv `
        -LiteralPath "$submissionRoot\COPY_RECONCILIATION.csv" `
        -NoTypeInformation `
        -Encoding utf8

$copyFailures = @(
    $copyChecks |
    Where-Object { -not $_.pass }
)

Write-Host "Copy controls:" $copyChecks.Count
Write-Host "Copy failures:" $copyFailures.Count

if ($copyFailures.Count -gt 0) {
    throw "STOP: submission copy reconciliation failed."
}
```

### 9. Build the submission manifest

```powershell
$manifestPath = Join-Path $submissionRoot "MANIFEST_SHA256.csv"

$payloadFiles = @(
    Get-ChildItem `
        -LiteralPath $submissionRoot `
        -File `
        -Recurse `
        -Force |
    Where-Object {
        $_.FullName -cne $manifestPath
    } |
    Sort-Object FullName
)

$payloadManifest = foreach ($file in $payloadFiles) {

    [pscustomobject]@{
        relative_path =
            $file.FullName.Substring($submissionRoot.Length + 1)

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
        -LiteralPath $manifestPath `
        -NoTypeInformation `
        -Encoding utf8

Write-Host "Submission manifest entries:" $payloadManifest.Count
```

### 10. Seal the ZIP and sidecar

```powershell
$zip = "C:\MSBF\$submissionName.zip"

if (Test-Path -LiteralPath $zip) {
    throw "STOP: ZIP already exists. Do not overwrite it."
}

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
Write-Host "ZIP:     $zip"
Write-Host "Bytes:  " (Get-Item -LiteralPath $zip).Length
Write-Host "SHA-256: $zipHash"
Write-Host "Sidecar: $sidecar"
```

### 11. Validate the ZIP

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
        Group-Object {
            $_.FullName.ToLowerInvariant()
        } |
        Where-Object Count -gt 1
    )

    $readFailures = @()

    foreach ($entry in $entries) {

        if ([string]::IsNullOrEmpty($entry.Name)) {
            continue
        }

        try {
            $stream = $entry.Open()
            $buffer = New-Object byte[] 65536

            try {
                while (
                    $stream.Read(
                        $buffer,
                        0,
                        $buffer.Length
                    ) -gt 0
                ) {}
            }
            finally {
                $stream.Dispose()
            }
        }
        catch {
            $readFailures += $entry.FullName
        }
    }

    $validation = [pscustomobject]@{
        zip = [IO.Path]::GetFileName($zip)
        bytes = (Get-Item -LiteralPath $zip).Length
        sha256 = $zipHash
        members = $entries.Count
        unsafe_paths = $unsafe.Count
        duplicate_paths = $duplicates.Count
        case_fold_duplicate_paths =
            $caseFoldDuplicates.Count
        archive_read_failures =
            $readFailures.Count

        result = if (
            $unsafe.Count -eq 0 -and
            $duplicates.Count -eq 0 -and
            $caseFoldDuplicates.Count -eq 0 -and
            $readFailures.Count -eq 0
        ) {
            "PASS"
        }
        else {
            "FAIL"
        }
    }

    $validation | Format-List

    $validation |
        ConvertTo-Json -Depth 6 |
        Set-Content `
            -LiteralPath `
            "C:\MSBF\${submissionName}_ZIP_VALIDATION.json" `
            -Encoding utf8

    if ($validation.result -ne "PASS") {
        throw "STOP: ZIP validation failed."
    }
}
finally {
    $archive.Dispose()
}
```

If the post-close serialization-aware validator passes, copy reconciliation is zero-failure, and ZIP validation is `PASS`, **stop there**. Do not reopen Desktop or perform more DAX execution.

Send me these final outputs:

```text
post-close serialization-aware validator result
final project-root SHA-256
final model.bim SHA-256
copy-control count / failures
manifest-entry count
ZIP bytes
ZIP SHA-256
ZIP member count
ZIP validation result
```

I will then give you the **final single-copy/paste Independent Audit prompt**, incorporating the exact sealed identities.

Because this is interaction **107**, the conversation-history carrier is currently:

```text
MSBF - Power BI Executive Portfolio Intelligence - ChatGPT_Interactions_89_Thru_107.zip
```

If you return the packaging results in the next interaction, the final history carrier will become `_89_Thru_108.zip`. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-2646c2f1-7122-4c23-8aae-04f775d21327"></a>
## Andrew / user · C091-M00233

C091-M00233 · 2026-08-21T08:43:24.106000-04:00 · active path

Preceding visible parent: [C091-M00232](part-18.md#m-b2cc4070-adbe-4bee-93e4-572d170019f8)

**Editorial record note:** Attachment references: MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip; MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821_ZIP_VALIDATION.json

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> Get-Process `
>>     -Name PBIDesktop,DaxStudio `
>>     -ErrorAction SilentlyContinue |
>>     Select-Object Id,ProcessName,StartTime |
>>     Format-Table -AutoSize
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $ErrorActionPreference = "Stop"
>>
>> $work   = "C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820"
>> $return = Join-Path $work "evidence\local_engine_return"
>>
>> $classification = @'
>> # A1b Focused R2 — Final Serialization Classification
>>
>> ## Governing semantic correction
>>
>> The only authorized substantive semantic correction is:
>>
>> ModelParameters[Source Reconciliation Pass]
>>
>> The normalized expression hashes reconcile exactly to the focused-remediation
>> authorization:
>>
>> - predecessor expression:
>>   cec29977bab86071d1209afaa1aaa5738f1a7f6d5c0d28791bbc847fcca1c1f5
>>
>> - Focused R2 replacement expression:
>>   98c2a0d31349e30277192dfa531ec78066f883899895286961249d38000daac0
>>
>> ## Executed physical project differences
>>
>> The post-Desktop project retains exactly 16 physical project files.
>>
>> Relative to the controlling predecessor, exactly four project files changed:
>>
>> 1. Report/.pbi/localSettings.json
>> 2. SemanticModel/.pbi/cache.abf
>> 3. SemanticModel/.pbi/localSettings.json
>> 4. SemanticModel/model.bim
>>
>> No project file was added or deleted.
>>
>> ## Local-settings classification
>>
>> Both changed localSettings.json files retain their original JSON structure.
>>
>> Their only observed changed value is:
>>
>> securityBindingsSignature
>>
>> This is classified as Desktop-local security-binding serialization metadata.
>>
>> ## cache.abf classification
>>
>> SemanticModel/.pbi/cache.abf is the Power BI Desktop processed-model cache.
>>
>> Its post-refresh physical change is preserved as executed Desktop state and is not
>> treated as an authored semantic-model change.
>>
>> ## model.bim exact semantic classification
>>
>> An exhaustive parsed-JSON comparison was performed after replacing only the
>> authorized Focused R2 Source Reconciliation Pass expression with the controlling
>> predecessor expression in memory.
>>
>> Exactly two residual parsed differences remained:
>>
>> DimDate
>>   annotation: PBI_ResultType
>>   predecessor: Table
>>   executed R2: Exception
>>
>> DimRunCampaign
>>   annotation: PBI_ResultType
>>   predecessor: Table
>>   executed R2: Exception
>>
>> For both tables:
>>
>> - table identity is unchanged;
>> - annotation identity is unchanged;
>> - MSBF_ActivationWave remains A1a;
>> - MSBF_LocalEngineStatus remains PENDING_LOCAL_DESKTOP_EVIDENCE;
>> - PBI_NavigationStepName remains Navigation;
>> - partition mode remains import;
>> - partition source structure remains unchanged.
>>
>> No other parsed semantic-model difference was identified after reversing the
>> authorized measure expression in memory.
>>
>> The two PBI_ResultType values are therefore classified as Power BI-authored
>> serialization/runtime annotation metadata, not as an additional source-owner
>> semantic correction.
>>
>> ## Validator disposition
>>
>> The supplied Validate-A1bFocusedR2Static.py validator remains preserved unchanged.
>>
>> It fails before its substantive checks because it requires the complete physical
>> project diff to contain model.bim only.
>>
>> That physical-file predicate is narrower than the focused-remediation authorization,
>> which expressly permits ordinary Power BI serialization caused by the authorized
>> one-measure correction.
>>
>> A copied serialization-aware diagnostic validator was used without altering the
>> supplied validator. It passed all remaining substantive controls and established:
>>
>> - 32 tables
>> - 32 relationships
>> - 79 Power Query objects
>> - 60 measures
>> - exactly one changed measure expression
>> - one technical shell
>> - zero substantive pages
>> - zero visuals
>> - REL-076 as the sole inactive relationship
>>
>> The original validator failure and the serialization-aware PASS are both retained
>> for Independent Audit review.
>>
>> ## No normalization
>>
>> No executed-state file has been restored merely to force the project into a
>> one-file physical diff.
>>
>> No PBI_ResultType annotation has been edited.
>>
>> No cache or local-settings file has been replaced.
>>
>> No additional semantic remediation has been performed.
>>
>> Independent Audit retains final acceptance authority.
>> '@
>>
>> $classification |
>>     Set-Content `
>>         -LiteralPath "$return\R2_E107_FINAL_SERIALIZATION_CLASSIFICATION.md" `
>>         -Encoding utf8
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $diagnosticValidator = Join-Path $return `
>>     "R2_E103_Validate-A1bFocusedR2Static_SERIALIZATION_AWARE_DIAGNOSTIC.py"
>>
>> & "C:\Python314\python.exe" `
>>     $diagnosticValidator `
>>     $work *>&1 |
>>     Tee-Object `
>>         -FilePath "$return\R2_E107_FINAL_POST_CLOSE_SERIALIZATION_AWARE_STATIC_BOUNDARY.txt"
{
  "status": "PASS",
  "baseline_project_root": "e3ec3953c97d29d289ee111d74a63677dbab18100886a53493188befee2b2740",
  "focused_r2_static_project_root": "4d67e1a43ae4e540bb5efed0c8b55eca0ecc4a40c30e2784485c0b400b7424d0",
  "baseline_model_sha256": "600c1bbd47af2313044fe319c28c7daa0d667119b55369c643d5f790b14cdc14",
  "focused_r2_model_sha256": "71ecb70eaa345ecd0d68398c844198424e62f954453b83f5e68ec13ac348de6f",
  "changed_project_files": [
    "MSBF_PBI_A1A_Local_Construction_R1.Report/.pbi/localSettings.json",
    "MSBF_PBI_A1A_Local_Construction_R1.SemanticModel/.pbi/cache.abf",
    "MSBF_PBI_A1A_Local_Construction_R1.SemanticModel/.pbi/localSettings.json",
    "MSBF_PBI_A1A_Local_Construction_R1.SemanticModel/model.bim"
  ],
  "changed_measure_expressions": [
    "ModelParameters[Source Reconciliation Pass]"
  ],
  "tables": 32,
  "relationships": 32,
  "power_query_objects": 79,
  "measures": 60,
  "technical_shell_pages": 1,
  "substantive_pages": 0,
  "visuals": 0,
  "inactive_relationships": [
    "REL-076"
  ]
}
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $project = Join-Path $work "project"
>>
>> $projectManifest = @(
>>     Get-ChildItem `
>>         -LiteralPath $project `
>>         -File `
>>         -Recurse `
>>         -Force |
>>     Sort-Object {
>>         $_.FullName.Substring($project.Length + 1).Replace('\','/').ToLowerInvariant()
>>     } |
>>     ForEach-Object {
>>         [pscustomobject]@{
>>             relative_path =
>>                 $_.FullName.Substring($project.Length + 1).Replace('\','/')
>>
>>             bytes = $_.Length
>>
>>             sha256 = (
>>                 Get-FileHash `
>>                     -LiteralPath $_.FullName `
>>                     -Algorithm SHA256
>>             ).Hash.ToLowerInvariant()
>>         }
>>     }
>> )
>>
>> $projectManifest |
>>     Export-Csv `
>>         -LiteralPath "$return\R2_E107_FINAL_PROJECT_MANIFEST.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> $rootMaterial = ""
>>
>> foreach (
>>     $row in @(
>>         $projectManifest |
>>         Sort-Object { $_.relative_path.ToLowerInvariant() }
>>     )
>> ) {
>>     $rootMaterial += (
>>         $row.relative_path + "`t" +
>>         $row.bytes + "`t" +
>>         $row.sha256 + "`n"
>>     )
>> }
>>
>> $rootBytes = [Text.Encoding]::UTF8.GetBytes($rootMaterial)
>>
>> $rootHash = (
>>     [BitConverter]::ToString(
>>         [Security.Cryptography.SHA256]::Create().ComputeHash(
>>             $rootBytes
>>         )
>>     )
>> ).Replace("-","").ToLowerInvariant()
>>
>> $modelPath = Join-Path $project `
>>     "MSBF_PBI_A1A_Local_Construction_R1.SemanticModel\model.bim"
>>
>> $modelHash = (
>>     Get-FileHash `
>>         -LiteralPath $modelPath `
>>         -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> [pscustomobject]@{
>>     captured_local = (Get-Date).ToString("o")
>>     captured_utc = (Get-Date).ToUniversalTime().ToString("o")
>>
>>     project_files = $projectManifest.Count
>>     project_root_sha256 = $rootHash
>>     model_bim_sha256 = $modelHash
>>
>>     controlling_predecessor_project_root =
>>         "e3ec3953c97d29d289ee111d74a63677dbab18100886a53493188befee2b2740"
>>
>>     status = "FINAL_EXECUTED_FOCUSED_R2_IDENTITY"
>> } |
>>     ConvertTo-Json -Depth 5 |
>>     Set-Content `
>>         -LiteralPath "$return\R2_E107_FINAL_EXECUTED_PROJECT_IDENTITY.json" `
>>         -Encoding utf8
>>
>> Write-Host ""
>> Write-Host "Final project files:" $projectManifest.Count
>> Write-Host "Final project root: " $rootHash
>> Write-Host "Final model.bim:    " $modelHash

Final project files: 16
Final project root:  4d67e1a43ae4e540bb5efed0c8b55eca0ecc4a40c30e2784485c0b400b7424d0
Final model.bim:     71ecb70eaa345ecd0d68398c844198424e62f954453b83f5e68ec13ac348de6f
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $finalDisposition = @'
>> # MSBF Power BI A1b Focused R2 — Source-Owner Final Disposition
>>
>> ## Focused remediation
>>
>> The Focused R2 correction was derived from controlling predecessor project root:
>>
>> e3ec3953c97d29d289ee111d74a63677dbab18100886a53493188befee2b2740
>>
>> Exactly one source-owner semantic correction was authorized and executed:
>>
>> ModelParameters[Source Reconciliation Pass]
>>
>> The corrected measure preserves the qualified source status:
>>
>> PASS_A1A_R3_STATIC
>>
>> and requires exact source and validation cardinalities.
>>
>> No source carrier was normalized to literal PASS.
>>
>> ## Live-engine re-performance
>>
>> R2_E01:
>> All 60 measures compiled/evaluated in one live-engine query.
>>
>> R2_E02:
>> FactSourceReconciliation:
>> - rows = 214
>> - distinct SourceObjectKey = 214
>> - PASS_A1A_R3_STATIC = 214
>>
>> FactValidationResult:
>> - rows = 533
>> - distinct ValidationControlKey = 533
>> - PASS = 533
>>
>> Source Reconciliation Pass = 1.
>>
>> R2_E03:
>> The exact control baseline returned gate 1.
>> Every truncated, duplicate, missing, unexpected-status, extra-control and
>> dual-extra adversarial population returned gate 0.
>>
>> R2_E04:
>> Endpoint availability = 0 / 1 / 0 across:
>> - 2026-11-21
>> - 2026-11-22
>> - 2026-11-23
>>
>> Post-evidence state = HOLD_OUTSIDE_EVIDENCE.
>>
>> R2_E05:
>> At the evidence endpoint the six core endpoint populations reconcile to:
>>
>> - FactGovernanceControl = 9
>> - FactMonitoringEndpoint = 59
>> - FactAccountCertification = 59
>> - FactPortfolioPerformanceEndpoint = 59
>> - FactServicingQueueEndpoint = 3
>> - FactPortfolioKPIEndpoint = 72
>>
>> R2_E06:
>> Endpoint measure behavior reconciles, including:
>>
>> - Certified Exposure = 785.48
>> - Servicing Burden Units = 7
>> - Endpoint Open Servicing Queue = 2
>>
>> R2_E07:
>> - tables = 32
>> - columns = 849
>> - measures = 60
>> - relationships = 32
>> - active relationships = 31
>> - REL-076 sole inactive
>> - zero bidirectional relationships
>>
>> R2_E08 / R2_E09:
>> All 31 active relationships demonstrate populated-key filter propagation after
>> the six targeted follow-up cases.
>>
>> R2_E10:
>> 32 / 32 physical relationships return literal zero orphan keys.
>>
>> R2_E11:
>> Scenario isolation remains:
>>
>> BASELINE:
>> - 750 application-scenario rows
>> - 44 account paths
>>
>> RECESSION_ENERGY:
>> - 750 application-scenario rows
>> - 15 account paths
>>
>> ## Privacy/source nonregression
>>
>> The isolated read-only SMB source remains:
>>
>> \\localhost\MSBF_PBI_A1B_SYNTHETIC
>>
>> The 222 synthetic-root files reconcile exactly to the governed manifest.
>>
>> Power BI Desktop exposes the dedicated UNC source in Data Source Settings.
>>
>> Its privacy classification was physically captured.
>>
>> Global privacy enforcement remains enabled and global privacy-ignore remains disabled.
>>
>> pDataRoot and pBuildRoot remain unchanged.
>>
>> ## Report boundary
>>
>> - technical shell pages = 1
>> - substantive pages = 0
>> - visuals = 0
>> - bookmarks = 0
>>
>> No substantive report construction occurred.
>>
>> ## Physical Desktop serialization
>>
>> Post-execution physical serialization is fully disclosed.
>>
>> Exactly four project files differ from the controlling predecessor:
>>
>> - Report/.pbi/localSettings.json
>> - SemanticModel/.pbi/cache.abf
>> - SemanticModel/.pbi/localSettings.json
>> - SemanticModel/model.bim
>>
>> The two localSettings files differ only in securityBindingsSignature.
>>
>> cache.abf is processed Desktop cache state.
>>
>> Within parsed model.bim, after reversing the authorized measure expression in
>> memory, only two residual Power BI annotation values differ:
>>
>> - DimDate PBI_ResultType: Table -> Exception
>> - DimRunCampaign PBI_ResultType: Table -> Exception
>>
>> All remaining parsed model semantics reconcile to the predecessor.
>>
>> The original supplied static validator remains preserved with its one-physical-file
>> assertion failure.
>>
>> A serialization-aware diagnostic copy passes all substantive static controls.
>>
>> Independent Audit is asked to classify the disclosed Desktop serialization under
>> the authorization's ordinary-serialization allowance rather than having the source
>> owner normalize the executed state.
>>
>> ## Governing status
>>
>> ER-PBI-008:
>> FOCUSED R2 EVIDENCE COMPLETE — PENDING INDEPENDENT AUDIT
>>
>> ER-PBI-010:
>> FOCUSED R2 EVIDENCE COMPLETE — PENDING INDEPENDENT AUDIT
>>
>> PBI-WP2:
>> HOLD
>>
>> Substantive report construction:
>> NOT AUTHORIZED
>>
>> Publication:
>> NOT AUTHORIZED
>>
>> Deployment:
>> NOT AUTHORIZED
>>
>> Production readiness:
>> NOT CLAIMED
>>
>> Public Power BI milestone:
>> NOT AUTHORIZED
>> '@
>>
>> $finalDisposition |
>>     Set-Content `
>>         -LiteralPath "$return\R2_E107_SOURCE_OWNER_FINAL_DISPOSITION.md" `
>>         -Encoding utf8
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $submissionName =
>>     "MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821"
>>
>> $submissionRoot = Join-Path "C:\MSBF" $submissionName
>>
>> if (Test-Path -LiteralPath $submissionRoot) {
>>     throw "STOP: submission root already exists. Do not overwrite it."
>> }
>>
>> New-Item `
>>     -ItemType Directory `
>>     -Path $submissionRoot |
>>     Out-Null
>>
>> foreach ($folder in @(
>>     "authority",
>>     "project",
>>     "power_query",
>>     "synthetic_root",
>>     "dax",
>>     "tools",
>>     "evidence"
>> )) {
>>     New-Item `
>>         -ItemType Directory `
>>         -Path (Join-Path $submissionRoot $folder) |
>>         Out-Null
>> }
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> foreach ($folder in @(
>>     "authority",
>>     "project",
>>     "power_query",
>>     "synthetic_root",
>>     "dax",
>>     "tools",
>>     "evidence"
>> )) {
>>
>>     $source = Join-Path $work $folder
>>     $dest   = Join-Path $submissionRoot $folder
>>
>>     if (-not (Test-Path -LiteralPath $source)) {
>>         throw "STOP: required component missing: $source"
>>     }
>>
>>     Get-ChildItem `
>>         -LiteralPath $source `
>>         -Force |
>>         Copy-Item `
>>             -Destination $dest `
>>             -Recurse `
>>             -Force
>> }
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $auditRequest = @'
>> # MSBF Power BI A1b Focused R2 — Independent Audit Submission
>>
>> ## Requested review
>>
>> This is the bounded Focused R2 resubmission under:
>>
>> - ER-PBI-008
>> - ER-PBI-010
>>
>> The source owner requests Independent Audit disposition of the authorized
>> Source Reconciliation Pass remediation and its required re-execution evidence.
>>
>> No PBI-WP2 acceptance, substantive report construction, publication, deployment,
>> production-readiness claim or public Power BI milestone is requested.
>>
>> ## Controlling predecessor
>>
>> Project root:
>>
>> e3ec3953c97d29d289ee111d74a63677dbab18100886a53493188befee2b2740
>>
>> ## Authorized semantic correction
>>
>> Exactly:
>>
>> ModelParameters[Source Reconciliation Pass]
>>
>> The replacement expression preserves PASS_A1A_R3_STATIC and requires exact:
>>
>> 214 source rows
>> 214 distinct SourceObjectKey
>> 214 accepted PASS_A1A_R3_STATIC rows
>>
>> 533 validation rows
>> 533 distinct ValidationControlKey
>> 533 accepted PASS rows
>>
>> No Power Query definition, source carrier, table, relationship, source root,
>> other measure, page, visual, bookmark, filter, tooltip, drillthrough or mobile
>> layout was intentionally changed.
>>
>> ## Execution result
>>
>> The supplied live-engine evidence establishes:
>>
>> - all 60 measures execute;
>> - exact 214/214/214 and 533/533/533 populations;
>> - Source Reconciliation Pass = 1;
>> - adversarial fail-closed controls PASS;
>> - endpoint availability = 0 / 1 / 0;
>> - six core endpoint gates reconcile;
>> - endpoint measure behavior reconciles;
>> - 32 tables / 849 columns / 60 measures / 32 relationships;
>> - 31/31 active relationship propagation;
>> - 32/32 zero orphan controls;
>> - exact scenario isolation;
>> - privacy/source-root nonregression;
>> - one technical shell;
>> - zero substantive pages;
>> - zero visuals.
>>
>> ## Disclosed Desktop serialization
>>
>> The supplied original static validator remains unchanged and fails at its
>> physical-file assertion because post-Desktop execution produced four changed
>> physical project files rather than model.bim only.
>>
>> The governing remediation authorization expressly permits ordinary Power BI
>> serialization mechanically caused by the one authorized measure correction.
>>
>> The four physical differences are:
>>
>> 1. Report/.pbi/localSettings.json
>> 2. SemanticModel/.pbi/cache.abf
>> 3. SemanticModel/.pbi/localSettings.json
>> 4. SemanticModel/model.bim
>>
>> The localSettings files differ only in securityBindingsSignature.
>>
>> cache.abf is Desktop processed-model cache state.
>>
>> The normalized predecessor and current measure-expression hashes exactly match
>> the authorization.
>>
>> After reversing only the authorized measure expression in memory, the only
>> remaining parsed model differences are:
>>
>> DimDate:
>> PBI_ResultType = Table -> Exception
>>
>> DimRunCampaign:
>> PBI_ResultType = Table -> Exception
>>
>> No other parsed semantic-model difference remains.
>>
>> A copied serialization-aware diagnostic validator passes all substantive static
>> controls. The supplied original validator and its failure remain preserved.
>>
>> Independent Audit is expressly asked to determine whether these disclosed
>> Desktop-generated physical/annotation differences fall within the authorized
>> ordinary-serialization allowance.
>>
>> The source owner has not restored or normalized executed-state files merely to
>> force a one-file physical diff.
>>
>> ## Requested disposition
>>
>> Please determine:
>>
>> 1. ER-PBI-008 focused-remediation disposition.
>> 2. ER-PBI-010 live-control re-performance disposition.
>> 3. Whether the disclosed three .pbi physical changes are ordinary authorized
>>    Desktop serialization.
>> 4. Whether the two PBI_ResultType annotation changes are ordinary Power BI
>>    serialization/runtime metadata rather than an unauthorized semantic change.
>> 5. Whether the one-measure correction is accepted as the sole substantive
>>    semantic remediation.
>> 6. Whether AUD-ASOF-003B is now closed.
>> 7. Whether any further Focused R2 correction or re-performance is required.
>> 8. Explicitly preserve or revise the existing PBI-WP2 HOLD.
>>
>> Do not infer PBI-WP2 acceptance from a successful Focused R2 decision.
>> '@
>>
>> $auditRequest |
>>     Set-Content `
>>         -LiteralPath "$submissionRoot\00_INDEPENDENT_AUDIT_REQUEST.md" `
>>         -Encoding utf8
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $copyChecks = @()
>>
>> foreach ($folder in @(
>>     "authority",
>>     "project",
>>     "power_query",
>>     "synthetic_root",
>>     "dax",
>>     "tools",
>>     "evidence"
>> )) {
>>
>>     $sourceRoot = Join-Path $work $folder
>>     $destRoot   = Join-Path $submissionRoot $folder
>>
>>     $sourceFiles = @(
>>         Get-ChildItem `
>>             -LiteralPath $sourceRoot `
>>             -File `
>>             -Recurse `
>>             -Force |
>>         Sort-Object FullName
>>     )
>>
>>     foreach ($sourceFile in $sourceFiles) {
>>
>>         $relative =
>>             $sourceFile.FullName.Substring($sourceRoot.Length + 1)
>>
>>         $destFile = Join-Path $destRoot $relative
>>
>>         $sourceHash = (
>>             Get-FileHash `
>>                 -LiteralPath $sourceFile.FullName `
>>                 -Algorithm SHA256
>>         ).Hash.ToLowerInvariant()
>>
>>         $exists = Test-Path -LiteralPath $destFile
>>
>>         $destHash = if ($exists) {
>>             (
>>                 Get-FileHash `
>>                     -LiteralPath $destFile `
>>                     -Algorithm SHA256
>>             ).Hash.ToLowerInvariant()
>>         }
>>         else {
>>             ""
>>         }
>>
>>         $copyChecks += [pscustomobject]@{
>>             component = $folder
>>             relative_path = $relative
>>             source_sha256 = $sourceHash
>>             copied_sha256 = $destHash
>>             copied_exists = $exists
>>             pass = (
>>                 $exists -and
>>                 ($sourceHash -ceq $destHash)
>>             )
>>         }
>>     }
>> }
>>
>> $copyChecks |
>>     Export-Csv `
>>         -LiteralPath "$submissionRoot\COPY_RECONCILIATION.csv" `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> $copyFailures = @(
>>     $copyChecks |
>>     Where-Object { -not $_.pass }
>> )
>>
>> Write-Host "Copy controls:" $copyChecks.Count
>> Write-Host "Copy failures:" $copyFailures.Count
>>
>> if ($copyFailures.Count -gt 0) {
>>     throw "STOP: submission copy reconciliation failed."
>> }
Copy controls: 434
Copy failures: 0
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $manifestPath = Join-Path $submissionRoot "MANIFEST_SHA256.csv"
>>
>> $payloadFiles = @(
>>     Get-ChildItem `
>>         -LiteralPath $submissionRoot `
>>         -File `
>>         -Recurse `
>>         -Force |
>>     Where-Object {
>>         $_.FullName -cne $manifestPath
>>     } |
>>     Sort-Object FullName
>> )
>>
>> $payloadManifest = foreach ($file in $payloadFiles) {
>>
>>     [pscustomobject]@{
>>         relative_path =
>>             $file.FullName.Substring($submissionRoot.Length + 1)
>>
>>         bytes = $file.Length
>>
>>         sha256 = (
>>             Get-FileHash `
>>                 -LiteralPath $file.FullName `
>>                 -Algorithm SHA256
>>         ).Hash.ToLowerInvariant()
>>     }
>> }
>>
>> $payloadManifest |
>>     Export-Csv `
>>         -LiteralPath $manifestPath `
>>         -NoTypeInformation `
>>         -Encoding utf8
>>
>> Write-Host "Submission manifest entries:" $payloadManifest.Count
Submission manifest entries: 436
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> $zip = "C:\MSBF\$submissionName.zip"
>>
>> if (Test-Path -LiteralPath $zip) {
>>     throw "STOP: ZIP already exists. Do not overwrite it."
>> }
>>
>> Compress-Archive `
>>     -Path "$submissionRoot\*" `
>>     -DestinationPath $zip `
>>     -CompressionLevel Optimal
>>
>> $zipHash = (
>>     Get-FileHash `
>>         -LiteralPath $zip `
>>         -Algorithm SHA256
>> ).Hash.ToLowerInvariant()
>>
>> $sidecar = "$zip.sha256"
>>
>> "$zipHash  $submissionName.zip" |
>>     Set-Content `
>>         -LiteralPath $sidecar `
>>         -Encoding ascii
>>
>> Write-Host ""
>> Write-Host "ZIP:     $zip"
>> Write-Host "Bytes:  " (Get-Item -LiteralPath $zip).Length
>> Write-Host "SHA-256: $zipHash"
>> Write-Host "Sidecar: $sidecar"

ZIP:     C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip
Bytes:   34813542
SHA-256: 8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02
Sidecar: C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip.sha256
PS C:\MSBF\MSBF_PBI_A1B_FOCUSED_R2_WORKING_20260820> Add-Type -AssemblyName System.IO.Compression.FileSystem
>>
>> $archive = [System.IO.Compression.ZipFile]::OpenRead($zip)
>>
>> try {
>>
>>     $entries = @($archive.Entries)
>>
>>     $unsafe = @(
>>         $entries |
>>         Where-Object {
>>             $_.FullName.StartsWith("/") -or
>>             $_.FullName.StartsWith("\") -or
>>             $_.FullName -match '(^|[\\/])\.\.([\\/]|$)'
>>         }
>>     )
>>
>>     $duplicates = @(
>>         $entries |
>>         Group-Object FullName |
>>         Where-Object Count -gt 1
>>     )
>>
>>     $caseFoldDuplicates = @(
>>         $entries |
>>         Group-Object {
>>             $_.FullName.ToLowerInvariant()
>>         } |
>>         Where-Object Count -gt 1
>>     )
>>
>>     $readFailures = @()
>>
>>     foreach ($entry in $entries) {
>>
>>         if ([string]::IsNullOrEmpty($entry.Name)) {
>>             continue
>>         }
>>
>>         try {
>>             $stream = $entry.Open()
>>             $buffer = New-Object byte[] 65536
>>
>>             try {
>>                 while (
>>                     $stream.Read(
>>                         $buffer,
>>                         0,
>>                         $buffer.Length
>>                     ) -gt 0
>>                 ) {}
>>             }
>>             finally {
>>                 $stream.Dispose()
>>             }
>>         }
>>         catch {
>>             $readFailures += $entry.FullName
>>         }
>>     }
>>
>>     $validation = [pscustomobject]@{
>>         zip = [IO.Path]::GetFileName($zip)
>>         bytes = (Get-Item -LiteralPath $zip).Length
>>         sha256 = $zipHash
>>         members = $entries.Count
>>         unsafe_paths = $unsafe.Count
>>         duplicate_paths = $duplicates.Count
>>         case_fold_duplicate_paths =
>>             $caseFoldDuplicates.Count
>>         archive_read_failures =
>>             $readFailures.Count
>>
>>         result = if (
>>             $unsafe.Count -eq 0 -and
>>             $duplicates.Count -eq 0 -and
>>             $caseFoldDuplicates.Count -eq 0 -and
>>             $readFailures.Count -eq 0
>>         ) {
>>             "PASS"
>>         }
>>         else {
>>             "FAIL"
>>         }
>>     }
>>
>>     $validation | Format-List
>>
>>     $validation |
>>         ConvertTo-Json -Depth 6 |
>>         Set-Content `
>>             -LiteralPath `
>>             "C:\MSBF\${submissionName}_ZIP_VALIDATION.json" `
>>             -Encoding utf8
>>
>>     if ($validation.result -ne "PASS") {
>>         throw "STOP: ZIP validation failed."
>>     }
>> }
>> finally {
>>     $archive.Dispose()
>> }

zip                       : MSBF_PBI_A1B_FOCUSED_R2_INDEPENDENT_AUDIT_SUBMISSION_20260821.zip
bytes                     : 34813542
sha256                    : 8dddea7de21f1ead227d9ed9bd6fdcbe439b0e48aa11f3cb16023e0b77744b02
members                   : 441
unsafe_paths              : 0
duplicate_paths           : 0
case_fold_duplicate_paths : 0
archive_read_failures     : 0
result                    : PASS                           Interaction: 108
<!-- END_SOURCE_MESSAGE -->
