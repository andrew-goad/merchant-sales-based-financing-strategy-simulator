# MSBF - Power BI Executive Portfolio Intelligence

Part 14 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-13.md)
[Next part](part-15.md)

<a id="m-63aad9fc-5804-4bb3-88b0-ea68db21dc14"></a>
## Assistant · C091-M00192

C091-M00192 · 2026-08-20T13:44:48.525155-04:00 · active path

Preceding visible parent: [C091-M00191](part-13.md#m-38551fc8-2287-4990-b589-6c1915578f51)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The right move now is to freeze the exact A1b state, package the complete live-engine evidence and reproducibility carriers, and return to Independent Audit with only two bounded decision requests:

1. ratify the source-owner `PBI-F-004` equivalent-evidence exception; and
2. determine disposition and remediation authority for the `PASS_A1A_R3_STATIC` versus literal `PASS` mismatch exposed under `AUD-ASOF-003B`.

No A1b measure should be edited, normalized, or “fixed” before Audit rules on that second issue.

Below is the packaging sequence I recommend, followed by the complete audit prompt.

## 1. Freeze the current A1b state

Do **not** refresh again and do not change Power Query, parameters, relationships, measures, pages, visuals, privacy configuration, or source data.

If Power BI Desktop is still open, save once with **Ctrl+S**. You may then leave Desktop and DAX Studio open while creating the filesystem package; the commands below are read/copy/hash operations only.

Run this first:

```powershell
$ErrorActionPreference = "Stop"

$work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
$return = Join-Path $work "evidence\local_engine_return"

[pscustomobject]@{
    event = "A1B_PRE_AUDIT_EVIDENCE_FREEZE"
    captured_local = (Get-Date).ToString("o")
    captured_utc = (Get-Date).ToUniversalTime().ToString("o")

    construction_state = "A1B_BOUNDED_LOCAL_ENGINE_EXECUTED"
    live_engine_testing_state = "STOPPED_AFTER_E09D"

    tables = 32
    relationships = 32
    measures = 60
    power_query_objects = 79

    technical_shell_pages = 1
    substantive_report_pages = 0
    visuals = 0

    pbi_f_004 =
        "SOURCE_OWNER_EQUIVALENT_EVIDENCE_EXCEPTION_PENDING_INDEPENDENT_AUDIT_RATIFICATION"

    aud_asof_003b_temporal_boundary =
        "PASS_SOURCE_OWNER_EVIDENCE"

    aud_asof_003b_endpoint_grant =
        "BLOCKED_PENDING_INDEPENDENT_AUDIT_DISPOSITION"

    discovered_runtime_condition =
        "PASS_A1A_R3_STATIC_VERSUS_LITERAL_PASS_STATUS_VOCABULARY_MISMATCH"

    a1b_measure_edit_after_finding = $false
    semantic_remediation_executed = $false

    pbi_wp2 = "HOLD"
    publication = "NOT_AUTHORIZED"
    deployment = "NOT_AUTHORIZED"
    production_readiness = "NOT_CLAIMED"
} |
    ConvertTo-Json -Depth 8 |
    Set-Content `
        -LiteralPath "$return\E10_PRE_AUDIT_EVIDENCE_FREEZE.json" `
        -Encoding utf8
```

## 2. Record the bounded source-owner disposition

Run:

```powershell
$disposition = @'
# A1b Source-Owner Pre-Audit Disposition

## Construction boundary

The bounded A1b semantic construction remains within the authorized footprint:

- 32 total semantic tables
- 32 total relationships
- 79 total Power Query objects
- 60 explicit measures
- 18 A1b-added tables
- 26 A1b-added relationships
- 32 A1b-added Power Query objects
- 60 A1b measures
- one inherited technical shell page
- zero substantive report pages
- zero visuals
- zero bookmarks
- REL-076 is the sole inactive relationship
- zero bidirectional relationships

No substantive report construction, publication, deployment, or production-readiness
claim has occurred.

## PBI-F-004

The original PBI-F-004 requirement contemplated a visibly distinct dedicated source
privacy entry in Power BI Data Source Settings before Refresh Preview.

Power BI Desktop continued to expose the legacy C:\ global permission UI rather than
a separately visible UNC permission entry.

The source owner authorized an equivalent-evidence exception before the formal A1b
Refresh Preview.

Equivalent evidence captured includes:

- dedicated local SMB share over the isolated A1b synthetic root;
- share access limited to read access for the executing user;
- UNC pDataRoot and pBuildRoot;
- embedded/external parameter parity;
- 32/32/79/60 pre-refresh static boundary PASS;
- global privacy enforcement enabled;
- "Always ignore Privacy Level settings" not selected;
- Power BI Desktop executable/process/version identity;
- successful UNC-backed catalog preview;
- successful formal 79-query Refresh Preview with zero observed query errors.

Independent Audit ratification remains required.

## Live-engine execution

After Close & Apply instantiated the semantic model without visible data rows,
Power BI Desktop Refresh completed successfully.

Observed physical examples included:

- DimDate = 123 rows
- FactValidationResult = 533 rows
- FactApplicationScenario = 1,500 rows
- FactAccountDaily = 7,080 rows
- FactPortfolioKPIEndpoint = 72 rows
- FactFinalDecision = 1,500 rows after Desktop Refresh

DAX Studio live-engine evidence established:

- 32 tables
- 849 columns
- 60 measures
- 32 relationships
- 31 active relationships
- REL-076 as the sole inactive relationship
- zero bidirectional relationships
- all 32 tables physically populated
- all 60 measures compiled/evaluated in one live request
- 31/31 active relationships demonstrated populated-key filter propagation
- 32/32 physical relationships returned literal zero orphan keys
- scenario isolation preserved 750 / 750 application-scenario populations
  and 44 / 15 account-path populations.

## AUD-ASOF-003B

Three-date live-engine testing established:

2026-11-21:
- valid historical as-of state;
- endpoint availability remained closed;
- historical as-of measures populated.

2026-11-22:
- valid evidence-endpoint state;
- selected as-of date = 2026-11-22;
- portfolio evidence max date = 2026-11-22;
- G2 Contract Pass = 1;
- G3 Contract Pass = 1;
- endpoint availability remained closed.

2026-11-23:
- As Of Evidence Status = HOLD_OUTSIDE_EVIDENCE;
- Selected As Of Date = BLANK;
- exposure/remittance outputs were blank;
- no post-endpoint carry-forward was observed.

The endpoint grant remained closed because Source Reconciliation Pass evaluated 0.

Subsequent evidence identified the exact cause:

FactSourceReconciliation:
- 214 rows
- all 214 rows carry object_audit_status = PASS_A1A_R3_STATIC
- zero rows carry literal status PASS

FactValidationResult:
- 533 rows
- all 533 rows carry status = PASS
- zero non-PASS rows

The Source Reconciliation Pass DAX measure requires literal PASS for every
FactSourceReconciliation object_audit_status value.

Therefore:

PASS_A1A_R3_STATIC <> PASS
→ Source Reconciliation Pass = 0
→ Endpoint Evidence Available = 0

No substantive failed source-reconciliation row was observed.
No substantive failed validation row was observed.

This is classified by the source owner as an A1b runtime status-vocabulary /
acceptance-predicate mismatch pending Independent Audit disposition.

## No self-remediation

No A1b measure has been edited after discovery of the mismatch.

The source owner is not self-authorizing any of the following:

- treating PASS_A1A_R3_STATIC as equivalent to PASS inside the measure;
- normalizing the physical source carrier to PASS;
- changing the Source Reconciliation Pass measure;
- changing Endpoint Evidence Available;
- changing any validation status;
- closing AUD-ASOF-003B;
- claiming PBI-WP2;
- beginning report/dashboard construction;
- publication or deployment.

Independent Audit retains disposition and remediation authority.
'@

$disposition |
    Set-Content `
        -LiteralPath "$return\E10_SOURCE_OWNER_PRE_AUDIT_DISPOSITION.md" `
        -Encoding utf8
```

## 3. Capture final manifests of the frozen working state

This inventories the project, external M definitions, tools, synthetic roots, and evidence independently.

```powershell
$manifestRoot = Join-Path $return "E10_FINAL_MANIFESTS"

New-Item `
    -ItemType Directory `
    -Path $manifestRoot `
    -Force |
    Out-Null

$manifestTargets = [ordered]@{
    project        = Join-Path $work "project"
    power_query    = Join-Path $work "power_query"
    tools          = Join-Path $work "tools"
    synthetic_root = Join-Path $work "synthetic_root"
    evidence       = Join-Path $work "evidence"
}

foreach ($name in $manifestTargets.Keys) {

    $root = $manifestTargets[$name]

    if (-not (Test-Path -LiteralPath $root)) {
        throw "STOP: required package component is missing: $root"
    }

    $rows = @(
        Get-ChildItem `
            -LiteralPath $root `
            -File `
            -Recurse `
            -Force |
        Sort-Object FullName |
        ForEach-Object {
            [pscustomobject]@{
                relative_path = $_.FullName.Substring($root.Length + 1)
                bytes = $_.Length
                sha256 = (
                    Get-FileHash `
                        -LiteralPath $_.FullName `
                        -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }
        }
    )

    $rows |
        Export-Csv `
            -LiteralPath "$manifestRoot\${name}_MANIFEST_SHA256.csv" `
            -NoTypeInformation `
            -Encoding utf8

    Write-Host "$name files:" $rows.Count
}
```

## 4. Capture the exact post-finding semantic boundary again

Use the already corrected working-copy verifier. This does **not** authorize refresh.

```powershell
& "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
    -PackageRoot $work *>&1 |
    Tee-Object `
        -FilePath "$return\E10_FINAL_STATIC_SEMANTIC_BOUNDARY.txt"
```

Expected structural state remains:

```text
32 tables
32 relationships
79 Power Query objects
60 measures

18 A1b tables
26 A1b relationships
32 A1b Power Query objects
60 A1b measures

1 technical shell page
0 visuals
0 bookmarks

REL-076 sole inactive
0 bidirectional
0 scenario_code relationships
```

The verifier should not be interpreted as closing `AUD-ASOF-003B`; it is only a structural non-regression control.

## 5. Create the Independent Audit submission directory

I recommend this name:

```text
MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820
```

Run:

```powershell
$submissionName =
    "MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820"

$submissionRoot = Join-Path "C:\MSBF" $submissionName

if (Test-Path -LiteralPath $submissionRoot) {
    throw "STOP: submission root already exists. Do not overwrite it."
}

New-Item `
    -ItemType Directory `
    -Path $submissionRoot |
    Out-Null

foreach ($folder in @(
    "project",
    "power_query",
    "tools",
    "synthetic_root",
    "evidence"
)) {
    New-Item `
        -ItemType Directory `
        -Path (Join-Path $submissionRoot $folder) |
        Out-Null
}
```

## 6. Copy the exact frozen carriers

Use `Get-ChildItem | Copy-Item`, which avoids the wildcard issue encountered during A1a packaging.

```powershell
foreach ($folder in @(
    "project",
    "power_query",
    "tools",
    "synthetic_root",
    "evidence"
)) {

    $source = Join-Path $work $folder
    $dest   = Join-Path $submissionRoot $folder

    Get-ChildItem `
        -LiteralPath $source `
        -Force |
        Copy-Item `
            -Destination $dest `
            -Recurse `
            -Force
}
```

This deliberately includes `synthetic_root`. That gives Audit the exact isolated `pbi` and `build` bytes underlying the UNC execution rather than only a manifest of them.

## 7. Add the audit-request summary to the package

Run:

```powershell
$auditRequest = @'
# MSBF Power BI A1b — Independent Audit Submission R1

## Purpose

This submission requests two bounded Independent Audit decisions only.

### Decision Request 1 — PBI-F-004

Ratify or reject the source-owner equivalent-evidence exception used for PBI-F-004.

The dedicated A1b source was physically isolated behind a read-only local SMB share
and consumed through UNC pDataRoot/pBuildRoot paths. Global privacy enforcement
remained enabled and global privacy-ignore remained disabled.

Power BI Desktop did not expose the dedicated UNC source as a separately visible
permission entry in Data Source Settings; it continued to show a legacy C:\ global
permission entry.

The source owner authorized equivalent evidence before the formal Refresh Preview.
That evidence is preserved in this submission.

Independent Audit is asked to determine whether the equivalent evidence is
sufficient for PBI-F-004.

### Decision Request 2 — AUD-ASOF-003B runtime mismatch

Determine disposition and remediation authority for the following exact condition:

FactSourceReconciliation:
- 214 / 214 rows = PASS_A1A_R3_STATIC
- 0 / 214 rows = literal PASS

FactValidationResult:
- 533 / 533 rows = PASS
- zero non-PASS rows

The Source Reconciliation Pass measure requires literal PASS for all
FactSourceReconciliation rows.

Observed live-engine consequence:

PASS_A1A_R3_STATIC does not equal literal PASS
→ Source Reconciliation Pass = 0
→ Endpoint Evidence Available = 0

The source-owner evidence found no substantive failed source-reconciliation row and
no substantive failed validation row.

Independent Audit is asked to determine whether:

A. PASS_A1A_R3_STATIC is an authorized successful source-reconciliation state and
   the DAX acceptance predicate requires bounded remediation;

B. the physical reconciliation carrier should instead be normalized to literal PASS;

C. the current fail-closed state is intentionally required and no remediation should
   occur; or

D. another governed disposition is required.

No measure, source status, or endpoint-grant logic has been changed after discovery.

## Scope expressly not requested

This submission does not request:

- PBI-WP2 acceptance;
- dashboard/report-page authorization;
- substantive report construction;
- visual construction;
- publication;
- deployment;
- production-readiness determination;
- public milestone language;
- redesign of the A1b semantic model beyond any narrowly authorized correction
  Independent Audit determines is necessary.

Independent Audit retains all finding, closure, and remediation-authorization
authority.
'@

$auditRequest |
    Set-Content `
        -LiteralPath "$submissionRoot\00_INDEPENDENT_AUDIT_REQUEST.md" `
        -Encoding utf8
```

## 8. Reconcile copied files against the frozen source

Run this before creating the ZIP:

```powershell
$copyChecks = @()

foreach ($folder in @(
    "project",
    "power_query",
    "tools",
    "synthetic_root",
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

        $relative = $sourceFile.FullName.Substring(
            $sourceRoot.Length + 1
        )

        $destFile = Join-Path $destRoot $relative

        $sourceHash = (
            Get-FileHash `
                -LiteralPath $sourceFile.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        $destExists = Test-Path -LiteralPath $destFile

        $destHash = if ($destExists) {
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
            copied_exists = $destExists
            pass = (
                $destExists -and
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

## 9. Create the final package manifest

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

## 10. ZIP the complete live-evidence submission

```powershell
$zip = "C:\MSBF\$submissionName.zip"

if (Test-Path -LiteralPath $zip) {
    throw "STOP: ZIP already exists. Preserve it rather than overwriting."
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

Depending on the size of `synthetic_root`, this ZIP may be materially larger than A1a. That is expected.

## 11. Validate the ZIP physically

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
        case_fold_duplicate_paths = $caseFoldDuplicates.Count
        archive_read_failures = $readFailures.Count

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

At that point the submission ZIP is complete.

---

# Full Independent Audit prompt — single copy/paste

Use the following as the **entire audit prompt**. I have deliberately made the interaction-log filename dynamic so you only need to replace `##` with the actual final interaction number immediately before submission.

```text
# INDEPENDENT AUDIT REQUEST — MSBF POWER BI A1b BOUNDED LOCAL-ENGINE EXECUTION

Treat the attached A1b evidence package, governing prior Audit response, source-owner execution evidence, and interaction history as the complete bounded submission for this review.

## FILES PROVIDED

The submission includes, at minimum:

1. `MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820.zip`
2. its SHA-256 sidecar;
3. its ZIP-validation JSON;
4. the prior Independent Audit response that authorized bounded A1b semantic construction;
5. the controlling A1b authorization catalog / construction package previously supplied to Audit;
6. `MSBF - Power BI Executive Portfolio Intelligence - ChatGPT_Interactions_49_Thru_##.zip`

For the interaction-history file, `##` is the final interaction number at the time of submission. Treat that archive as the chronological execution log from interaction 49 through that final interaction. It contains the user's inputs, input files/screenshots, ChatGPT responses, and generated or referenced deliverables. Use it as execution-history evidence, but reconcile all material conclusions to the physical evidence carriers in the A1b submission package.

Do not assume a statement in the interaction log is physically true where the attached native evidence permits direct verification.

## GOVERNING PREDECESSOR

A1b began from the exact independently accepted A1a final project identified by:

`project-root SHA-256 = 3ec549cc46168c47ec122bfa81d9ebb1e5ee02a9b0ebf73d05714347fbc93a56`

The bounded A1b construction authorization permitted only:

- 18 added semantic tables;
- 26 added relationships;
- 32 added Power Query objects;
- 60 measures;
- preservation of HF01;
- preservation of the one zero-visual technical shell;
- no substantive report page;
- no visual;
- no PBI-WP2 claim;
- no publication;
- no deployment;
- no production-readiness claim.

The source owner was also required, before first refresh, to use dedicated MSBF synthetic data/build roots rather than the broad `C:\` root, capture privacy/global-enforcement evidence, capture Power BI Desktop identity, and pass the A1a/A1b baseline preflight.

## PHYSICAL A1b CONSTRUCTION BOUNDARY

The executed A1b state reports:

- 32 total semantic tables;
- 32 total relationships;
- 79 total Power Query objects;
- 60 explicit measures;
- 18 A1b-added tables;
- 26 A1b-added relationships;
- 32 A1b-added Power Query objects;
- 60 A1b measures;
- 1 inherited technical-shell page;
- 0 substantive report pages;
- 0 visuals;
- 0 bookmarks;
- REL-076 as the sole inactive relationship;
- 0 bidirectional relationships;
- 0 scenario_code relationships.

Independently verify these counts and identities from the physical project and live-engine evidence.

Do not infer acceptance solely from the source-owner summaries.

## DEDICATED SOURCE ROOT

The source owner created a dedicated local SMB share over the isolated A1b synthetic root:

`\\localhost\MSBF_PBI_A1B_SYNTHETIC`

The share maps only to the A1b working-copy synthetic root and was configured read-only for the executing user.

The A1b parameters were changed to:

`pDataRoot  = \\localhost\MSBF_PBI_A1B_SYNTHETIC\pbi`

`pBuildRoot = \\localhost\MSBF_PBI_A1B_SYNTHETIC\build`

External M parameter definitions and embedded model.bim parameter values were reconciled exactly.

The structural A1b verifier originally retained an obsolete S:\ expectation. The original verifier was preserved, the root-expectation predicates were corrected only to the exact authorized UNC roots, the two-line verifier diff was recorded, and the structural verifier then passed the 32/32/79/60 boundary.

Review this correction as verifier-only tooling remediation, not as substantive model remediation.

## POWER BI DESKTOP IDENTITY

The execution evidence physically resolved the active Power BI Desktop process and executable as:

- Power BI Desktop 2.156.951.0
- 64-bit
- July 2026
- executable under the Microsoft Store WindowsApps installation
- active executable FileVersion = 2.156.951.0

The initial helper's Get-AppxPackage method failed under PowerShell 7 because the Appx module could not load. The failure was preserved. Desktop identity was then obtained from the active `PBIDesktop.exe` process, its executable path, and its file/product version without modifying the model.

## PBI-F-004 — BOUNDED RATIFICATION REQUEST

The original PBI-F-004 expectation required the dedicated source privacy classification to be visibly established in Power BI Data Source Settings before formal Refresh Preview.

Power BI Desktop did not expose the dedicated UNC source as a distinct permission entry in Data Source Settings. The UI continued to show the legacy global `C:\` file permission.

However, before formal A1b Refresh Preview, the source owner explicitly authorized an equivalent-evidence exception.

The equivalent-evidence package includes:

- dedicated local SMB synthetic root;
- read-only SMB access;
- UNC pDataRoot;
- UNC pBuildRoot;
- embedded/external parameter parity;
- exact post-UNC 32/32/79/60 structural boundary PASS;
- Power BI global privacy enforcement visibly enabled;
- global privacy-ignore visibly not selected;
- Power BI Desktop process/executable/version identity;
- successful single-query UNC-backed `stg_POWER_BI_DATA_CATALOG` Refresh Preview;
- successful formal 79-query Refresh Preview;
- zero observed Power Query errors in that formal refresh sequence.

The source-owner exception remains explicitly pending Independent Audit ratification.

### DECISION REQUEST 1

Determine whether this evidence is sufficient to ratify the PBI-F-004 equivalent-evidence exception.

Do not treat the source-owner exception as self-ratification.

If PBI-F-004 cannot be ratified, identify the exact missing evidence or bounded corrective action required. Do not broaden the scope beyond what is needed to resolve PBI-F-004.

## REFRESH / LOCAL ENGINE EXECUTION

Formal Power Query Refresh Preview completed successfully across all 79 queries.

After Close & Apply, the semantic tables were instantiated but initially showed no visible rows, consistent with the predecessor A1a Desktop behavior.

A subsequent Power BI Desktop Refresh completed successfully and physically populated the model.

Observed examples include:

- `DimDate` = 123 rows;
- `FactValidationResult` = 533 rows;
- `FactApplicationScenario` = 1,500 rows;
- `FactAccountDaily` = 7,080 rows;
- `FactPortfolioKPIEndpoint` = 72 rows;
- `FactFinalDecision` = 1,500 rows after Desktop Refresh.

Review the pre-refresh null/unpopulated evidence and the post-refresh populated evidence as distinct physical states.

## DAX STUDIO LIVE-ENGINE EVIDENCE

DAX Studio 3.5.2 connected to the running Power BI semantic model.

The live engine reported:

- 32 tables;
- 849 columns;
- 60 measures;
- 32 relationships.

Relationship metadata reported:

- 31 active relationships;
- 1 inactive relationship;
- REL-076 as the sole inactive relationship;
- 32 OneDirection relationships;
- 0 bidirectional relationships.

All 32 semantic tables returned physical row populations. No semantic table had zero rows in the final refreshed live state.

The 60-measure execution control requested all 60 measures in one live-engine `ROW()` evaluation and returned one result row without a DAX compilation/evaluation exception.

Do not infer that a BLANK measure value is itself a compilation failure.

## RELATIONSHIP EXECUTION EVIDENCE

The initial active-relationship filter-propagation query tested all 31 active relationships.

Twenty-five relationships produced populated direct-versus-propagated comparisons immediately.

Six automatic test keys produced BLANK/BLANK comparisons and were therefore treated as inconclusive rather than self-passed.

A targeted follow-up selected populated many-side keys for exactly those six:

- REL-005
- REL-045
- REL-057
- REL-072
- REL-075
- REL-078

All six produced positive direct row counts and exactly matching relationship-propagated row counts.

Combined result:

- 31/31 active relationships tested using populated keys;
- 31/31 direct-versus-propagated row counts matched;
- 0 filter-propagation failures.

The orphan-integrity test then covered all 32 physical relationships, including inactive REL-076.

The first query returned BLANK orphan counts for empty orphan sets. A normalization-only follow-up converted those empty results to literal zero without changing the relationship test population.

Final normalized result:

- 32/32 relationships had nonzero from-side key populations;
- 32/32 returned literal `OrphanKeyCount = 0`;
- 32/32 returned PASS;
- REL-076 was included and returned zero orphan keys.

Evaluate whether this evidence is sufficient for the A1b relationship portion of the previously open relationship control. Do not infer broader PBI-WP2 acceptance.

## SCENARIO ISOLATION

Live-engine scenario testing returned:

BASELINE:
- ApplicationScenarioRows = 750
- DistinctApplications = 750
- DistinctMerchants = 750
- BookingActivationRows = 750
- FinalDecisionRows = 750
- AccountCount = 44
- MonitoringEndpointRows = 44
- PortfolioPerformanceEndpointRows = 44
- ServicingExecutionRows = 44

RECESSION_ENERGY:
- ApplicationScenarioRows = 750
- DistinctApplications = 750
- DistinctMerchants = 750
- BookingActivationRows = 750
- FinalDecisionRows = 750
- AccountCount = 15
- MonitoringEndpointRows = 15
- PortfolioPerformanceEndpointRows = 15
- ServicingExecutionRows = 15

Review this as evidence that both the 750/750 application-scenario grain and 44/15 account-path grain remain scenario-isolated.

## AUD-ASOF-003B — TEMPORAL EXECUTION EVIDENCE

A1a could not physically execute the endpoint-only business-fact behavior because those facts were outside the authorized A1a scope.

A1b introduced the required endpoint-governed objects and executed the three-date live-engine test.

The source-owner test dates were:

- 2026-11-21 — PRE_ENDPOINT
- 2026-11-22 — EVIDENCE_ENDPOINT
- 2026-11-23 — POST_EVIDENCE

The central live-engine results were:

### 2026-11-21

- Selected As Of Date = 2026-11-21
- As Of Evidence Status = VALID
- Portfolio Evidence Max Date = 2026-11-22
- Endpoint Evidence Available = 0
- historical/as-of exposure and remittance measures populated

### 2026-11-22

- Selected As Of Date = 2026-11-22
- As Of Evidence Status = VALID
- Portfolio Evidence Max Date = 2026-11-22
- G2 Contract Pass = 1
- G3 Contract Pass = 1
- Endpoint Evidence Available = 0

### 2026-11-23

- Selected As Of Date = BLANK
- As Of Evidence Status = HOLD_OUTSIDE_EVIDENCE
- Portfolio Evidence Max Date = 2026-11-22
- endpoint availability remained 0
- exposure/remittance outputs were blank
- Open Servicing Queue was blank
- no post-evidence carry-forward was observed

The source owner therefore treats the temporal boundary behavior itself as physically demonstrated:

- valid pre-endpoint historical behavior;
- recognition of the evidence endpoint;
- post-endpoint HOLD;
- no carry-forward of endpoint values beyond the evidence boundary.

Independent Audit retains final disposition authority.

## DISCOVERED AUD-ASOF-003B STATUS-VOCABULARY MISMATCH

The `Endpoint Evidence Available` measure requires all of the following:

- `As Of Evidence Status = "VALID"`
- `Selected As Of Date = Portfolio Evidence Max Date`
- `G2 Contract Pass = 1`
- `G3 Contract Pass = 1`
- `Source Reconciliation Pass = 1`

At 2026-11-22 the first four conditions were satisfied.

`Source Reconciliation Pass` evaluated to 0.

The exact live-engine source populations were then inspected.

### FactSourceReconciliation

Physical row count:

214

Status distribution:

- `PASS_A1A_R3_STATIC` = 214
- literal `PASS` = 0
- other statuses = 0

The non-PASS query returned all 214 rows solely because the DAX measure compares each `object_audit_status` to literal `PASS`.

### FactValidationResult

Physical row count:

533

Status distribution:

- `PASS` = 533
- non-PASS = 0

The validation non-PASS query returned zero rows.

The source-owner evidence therefore found:

- no substantive failed source-reconciliation row;
- no substantive failed validation row.

The current DAX acceptance chain is effectively:

`PASS_A1A_R3_STATIC <> "PASS"`

therefore:

`Source Reconciliation Pass = 0`

therefore:

`Endpoint Evidence Available = 0`

The source owner has classified this as an A1b runtime status-vocabulary / acceptance-predicate mismatch pending Independent Audit disposition.

No A1b measure has been edited after discovery.

No source reconciliation status has been normalized.

No endpoint grant has been forced open.

No remediation has been self-authorized.

### DECISION REQUEST 2

Determine the correct disposition and remediation authority for the exact mismatch between:

`PASS_A1A_R3_STATIC`

and the literal:

`PASS`

required by the current `Source Reconciliation Pass` DAX measure.

Please determine which of the following, or another explicitly stated disposition, is correct:

A. `PASS_A1A_R3_STATIC` is an authorized successful source-reconciliation state, and the `Source Reconciliation Pass` DAX predicate should receive a narrowly bounded semantic remediation;

B. the physical `FactSourceReconciliation` carrier should instead be normalized to literal `PASS`;

C. the current fail-closed behavior is intentional and no remediation is appropriate;

D. another governed remediation or interpretation is required.

If remediation is authorized, define the smallest permissible correction population and the evidence required for re-execution.

Do not authorize broad measure redesign or unrelated semantic changes unless independently necessary.

## IMPORTANT GOVERNANCE BOUNDARIES

The source owner expressly does NOT claim:

- Independent Audit closure of PBI-F-004;
- Independent Audit closure of AUD-ASOF-003B;
- PBI-WP2 acceptance;
- dashboard completion;
- substantive report-page completion;
- visual completion;
- publication;
- deployment;
- production readiness;
- a public Power BI milestone.

No substantive Power BI report page or visual has been created.

The inherited one-page technical shell remains a non-substantive compatibility container only.

## REQUIRED INDEPENDENT AUDIT OUTPUT

Please independently inspect the native evidence and provide:

1. integrity/reconciliation result for the submitted package and manifests;
2. A1b construction-boundary disposition;
3. PBI-F-004 equivalent-evidence ratification decision;
4. live-engine object-count and row-population disposition;
5. measure-compilation/evaluation disposition;
6. relationship metadata, filter-propagation, and orphan-integrity disposition;
7. scenario-isolation disposition;
8. AUD-ASOF-003B temporal-boundary disposition;
9. exact finding/disposition for the `PASS_A1A_R3_STATIC` versus literal `PASS` mismatch;
10. whether any semantic remediation is authorized;
11. if remediation is authorized, the exact bounded correction scope and required re-execution evidence;
12. explicit statement of what remains HOLD or NOT AUTHORIZED;
13. whether another focused Independent Audit submission is required after any authorized correction.

Do not convert source-owner evidence into Independent Audit acceptance without independently validating the attached physical carriers.

Do not expand this review into substantive report design, visual design, publication, deployment, or production-readiness review.

Until Independent Audit expressly rules otherwise:

- PBI-F-004 remains pending ratification;
- AUD-ASOF-003B remains pending final disposition;
- PBI-WP2 remains HOLD;
- substantive A1b report construction remains unauthorized;
- publication remains unauthorized;
- deployment remains unauthorized;
- production readiness remains unclaimed.
```

The only item you should edit in that prompt immediately before sending is the interaction archive suffix:

```text
MSBF - Power BI Executive Portfolio Intelligence - ChatGPT_Interactions_49_Thru_##.zip
```

For example, if this packaging sequence ends at interaction 91, change it to:

```text
MSBF - Power BI Executive Portfolio Intelligence - ChatGPT_Interactions_49_Thru_91.zip
```

Do **not** hard-code `87` now; keeping the placeholder until the final interaction log is assembled avoids creating another metadata mismatch.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8f8db18d-779c-42cb-96a4-29cbc3ca82e6"></a>
## Andrew / user · C091-M00193

C091-M00193 · 2026-08-20T14:03:39.565000-04:00 · active path

Preceding visible parent: [C091-M00192](part-14.md#m-63aad9fc-5804-4bb3-88b0-ea68db21dc14)

**Editorial record note:** Attachment references: MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820_ZIP_VALIDATION.json; MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820.zip; MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\WINDOWS\system32> $ErrorActionPreference = "Stop"
>>
>> $work = "C:\MSBF\MSBF_PBI_A1B_WORKING_R1_20260819"
>> $return = Join-Path $work "evidence\local_engine_return"
>>
>> [pscustomobject]@{
>>     event = "A1B_PRE_AUDIT_EVIDENCE_FREEZE"
>>     captured_local = (Get-Date).ToString("o")
>>     captured_utc = (Get-Date).ToUniversalTime().ToString("o")
>>
>>     construction_state = "A1B_BOUNDED_LOCAL_ENGINE_EXECUTED"
>>     live_engine_testing_state = "STOPPED_AFTER_E09D"
>>
>>     tables = 32
>>     relationships = 32
>>     measures = 60
>>     power_query_objects = 79
>>
>>     technical_shell_pages = 1
>>     substantive_report_pages = 0
>>     visuals = 0
>>
>>     pbi_f_004 =
>>         "SOURCE_OWNER_EQUIVALENT_EVIDENCE_EXCEPTION_PENDING_INDEPENDENT_AUDIT_RATIFICATION"
>>
>>     aud_asof_003b_temporal_boundary =
>>         "PASS_SOURCE_OWNER_EVIDENCE"
>>
>>     aud_asof_003b_endpoint_grant =
>>         "BLOCKED_PENDING_INDEPENDENT_AUDIT_DISPOSITION"
>>
>>     discovered_runtime_condition =
>>         "PASS_A1A_R3_STATIC_VERSUS_LITERAL_PASS_STATUS_VOCABULARY_MISMATCH"
>>
>>     a1b_measure_edit_after_finding = $false
>>     semantic_remediation_executed = $false
>>
>>     pbi_wp2 = "HOLD"
>>     publication = "NOT_AUTHORIZED"
>>     deployment = "NOT_AUTHORIZED"
>>     production_readiness = "NOT_CLAIMED"
>> } |
>>     ConvertTo-Json -Depth 8 |
>>     Set-Content `
>>         -LiteralPath "$return\E10_PRE_AUDIT_EVIDENCE_FREEZE.json" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> $disposition = @'
>> # A1b Source-Owner Pre-Audit Disposition
>>
>> ## Construction boundary
>>
>> The bounded A1b semantic construction remains within the authorized footprint:
>>
>> - 32 total semantic tables
>> - 32 total relationships
>> - 79 total Power Query objects
>> - 60 explicit measures
>> - 18 A1b-added tables
>> - 26 A1b-added relationships
>> - 32 A1b-added Power Query objects
>> - 60 A1b measures
>> - one inherited technical shell page
>> - zero substantive report pages
>> - zero visuals
>> - zero bookmarks
>> - REL-076 is the sole inactive relationship
>> - zero bidirectional relationships
>>
>> No substantive report construction, publication, deployment, or production-readiness
>> claim has occurred.
>>
>> ## PBI-F-004
>>
>> The original PBI-F-004 requirement contemplated a visibly distinct dedicated source
>> privacy entry in Power BI Data Source Settings before Refresh Preview.
>>
>> Power BI Desktop continued to expose the legacy C:\ global permission UI rather than
>> a separately visible UNC permission entry.
>>
>> The source owner authorized an equivalent-evidence exception before the formal A1b
>> Refresh Preview.
>>
>> Equivalent evidence captured includes:
>>
>> - dedicated local SMB share over the isolated A1b synthetic root;
>> - share access limited to read access for the executing user;
>> - UNC pDataRoot and pBuildRoot;
>> - embedded/external parameter parity;
>> - 32/32/79/60 pre-refresh static boundary PASS;
>> - global privacy enforcement enabled;
>> - "Always ignore Privacy Level settings" not selected;
>> - Power BI Desktop executable/process/version identity;
>> - successful UNC-backed catalog preview;
>> - successful formal 79-query Refresh Preview with zero observed query errors.
>>
>> Independent Audit ratification remains required.
>>
>> ## Live-engine execution
>>
>> After Close & Apply instantiated the semantic model without visible data rows,
>> Power BI Desktop Refresh completed successfully.
>>
>> Observed physical examples included:
>>
>> - DimDate = 123 rows
>> - FactValidationResult = 533 rows
>> - FactApplicationScenario = 1,500 rows
>> - FactAccountDaily = 7,080 rows
>> - FactPortfolioKPIEndpoint = 72 rows
>> - FactFinalDecision = 1,500 rows after Desktop Refresh
>>
>> DAX Studio live-engine evidence established:
>>
>> - 32 tables
>> - 849 columns
>> - 60 measures
>> - 32 relationships
>> - 31 active relationships
>> - REL-076 as the sole inactive relationship
>> - zero bidirectional relationships
>> - all 32 tables physically populated
>> - all 60 measures compiled/evaluated in one live request
>> - 31/31 active relationships demonstrated populated-key filter propagation
>> - 32/32 physical relationships returned literal zero orphan keys
>> - scenario isolation preserved 750 / 750 application-scenario populations
>>   and 44 / 15 account-path populations.
>>
>> ## AUD-ASOF-003B
>>
>> Three-date live-engine testing established:
>>
>> 2026-11-21:
>> - valid historical as-of state;
>> - endpoint availability remained closed;
>> - historical as-of measures populated.
>>
>> 2026-11-22:
>> - valid evidence-endpoint state;
>> - selected as-of date = 2026-11-22;
>> - portfolio evidence max date = 2026-11-22;
>> - G2 Contract Pass = 1;
>> - G3 Contract Pass = 1;
>> - endpoint availability remained closed.
>>
>> 2026-11-23:
>> - As Of Evidence Status = HOLD_OUTSIDE_EVIDENCE;
>> - Selected As Of Date = BLANK;
>> - exposure/remittance outputs were blank;
>> - no post-endpoint carry-forward was observed.
>>
>> The endpoint grant remained closed because Source Reconciliation Pass evaluated 0.
>>
>> Subsequent evidence identified the exact cause:
>>
>> FactSourceReconciliation:
>> - 214 rows
>> - all 214 rows carry object_audit_status = PASS_A1A_R3_STATIC
>> - zero rows carry literal status PASS
>>
>> FactValidationResult:
>> - 533 rows
>> - all 533 rows carry status = PASS
>> - zero non-PASS rows
>>
>> The Source Reconciliation Pass DAX measure requires literal PASS for every
>> FactSourceReconciliation object_audit_status value.
>>
>> Therefore:
>>
>> PASS_A1A_R3_STATIC <> PASS
>> → Source Reconciliation Pass = 0
>> → Endpoint Evidence Available = 0
>>
>> No substantive failed source-reconciliation row was observed.
>> No substantive failed validation row was observed.
>>
>> This is classified by the source owner as an A1b runtime status-vocabulary /
>> acceptance-predicate mismatch pending Independent Audit disposition.
>>
>> ## No self-remediation
>>
>> No A1b measure has been edited after discovery of the mismatch.
>>
>> The source owner is not self-authorizing any of the following:
>>
>> - treating PASS_A1A_R3_STATIC as equivalent to PASS inside the measure;
>> - normalizing the physical source carrier to PASS;
>> - changing the Source Reconciliation Pass measure;
>> - changing Endpoint Evidence Available;
>> - changing any validation status;
>> - closing AUD-ASOF-003B;
>> - claiming PBI-WP2;
>> - beginning report/dashboard construction;
>> - publication or deployment.
>>
>> Independent Audit retains disposition and remediation authority.
>> '@
>>
>> $disposition |
>>     Set-Content `
>>         -LiteralPath "$return\E10_SOURCE_OWNER_PRE_AUDIT_DISPOSITION.md" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> $manifestRoot = Join-Path $return "E10_FINAL_MANIFESTS"
>>
>> New-Item `
>>     -ItemType Directory `
>>     -Path $manifestRoot `
>>     -Force |
>>     Out-Null
>>
>> $manifestTargets = [ordered]@{
>>     project        = Join-Path $work "project"
>>     power_query    = Join-Path $work "power_query"
>>     tools          = Join-Path $work "tools"
>>     synthetic_root = Join-Path $work "synthetic_root"
>>     evidence       = Join-Path $work "evidence"
>> }
>>
>> foreach ($name in $manifestTargets.Keys) {
>>
>>     $root = $manifestTargets[$name]
>>
>>     if (-not (Test-Path -LiteralPath $root)) {
>>         throw "STOP: required package component is missing: $root"
>>     }
>>
>>     $rows = @(
>>         Get-ChildItem `
>>             -LiteralPath $root `
>>             -File `
>>             -Recurse `
>>             -Force |
>>         Sort-Object FullName |
>>         ForEach-Object {
>>             [pscustomobject]@{
>>                 relative_path = $_.FullName.Substring($root.Length + 1)
>>                 bytes = $_.Length
>>                 sha256 = (
>>                     Get-FileHash `
>>                         -LiteralPath $_.FullName `
>>                         -Algorithm SHA256
>>                 ).Hash.ToLowerInvariant()
>>             }
>>         }
>>     )
>>
>>     $rows |
>>         Export-Csv `
>>             -LiteralPath "$manifestRoot\${name}_MANIFEST_SHA256.csv" `
>>             -NoTypeInformation `
>>             -Encoding utf8
>>
>>     Write-Host "$name files:" $rows.Count
>> }
project files: 16
power_query files: 79
tools files: 9
synthetic_root files: 222
evidence files: 142
PS C:\WINDOWS\system32> & "$work\tools\Verify-A1bPreRefreshBoundary.ps1" `
>>     -PackageRoot $work *>&1 |
>>     Tee-Object `
>>         -FilePath "$return\E10_FINAL_STATIC_SEMANTIC_BOUNDARY.txt"
{
    "tables":  32,
    "relationships":  32,
    "named_expressions":  47,
    "partitions":  32,
    "power_query_objects":  79,
    "measures":  60,
    "a1b_tables":  18,
    "a1b_relationships":  26,
    "a1b_power_query_objects":  32,
    "a1b_measures":  60,
    "exact_a1b_tables":  true,
    "exact_a1b_relationships":  true,
    "exact_a1b_queries":  true,
    "exact_a1b_measures":  true,
    "technical_shell_pages":  1,
    "page_display_names":  [
                               "A1A_TECHNICAL_SHELL_NO_VISUALS"
                           ],
    "visuals":  0,
    "bookmarks":  0,
    "inactive_relationships":  [
                                   "REL-076"
                               ],
    "bidirectional_relationships":  [

                                    ],
    "scenario_code_relationships":  [

                                    ],
    "pDataRoot":  "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\pbi\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]",
    "pBuildRoot":  "\"\\\\localhost\\MSBF_PBI_A1B_SYNTHETIC\\build\" meta [IsParameterQuery=true, Type=\"Text\", IsParameterQueryRequired=true]"
}
A1b pre-refresh semantic boundary PASS.
REL-076 is the sole authorized inactive role-playing date relationship; any other inactive relationship is a stop.
REFRESH REMAINS PROHIBITED until privacy/global-enforcement, Desktop identity, and A1a baseline evidence are captured.
PS C:\WINDOWS\system32> $submissionName =
>>     "MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820"
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
>>     "project",
>>     "power_query",
>>     "tools",
>>     "synthetic_root",
>>     "evidence"
>> )) {
>>     New-Item `
>>         -ItemType Directory `
>>         -Path (Join-Path $submissionRoot $folder) |
>>         Out-Null
>> }
PS C:\WINDOWS\system32> foreach ($folder in @(
>>     "project",
>>     "power_query",
>>     "tools",
>>     "synthetic_root",
>>     "evidence"
>> )) {
>>
>>     $source = Join-Path $work $folder
>>     $dest   = Join-Path $submissionRoot $folder
>>
>>     Get-ChildItem `
>>         -LiteralPath $source `
>>         -Force |
>>         Copy-Item `
>>             -Destination $dest `
>>             -Recurse `
>>             -Force
>> }
PS C:\WINDOWS\system32> $auditRequest = @'
>> # MSBF Power BI A1b - Independent Audit Submission R1
>>
>> ## Purpose
>>
>> This submission requests two bounded Independent Audit decisions only.
>>
>> ### Decision Request 1 - PBI-F-004
>>
>> Ratify or reject the source-owner equivalent-evidence exception used for PBI-F-004.
>>
>> The dedicated A1b source was physically isolated behind a read-only local SMB share
>> and consumed through UNC pDataRoot/pBuildRoot paths. Global privacy enforcement
>> remained enabled and global privacy-ignore remained disabled.
>>
>> Power BI Desktop did not expose the dedicated UNC source as a separately visible
>> permission entry in Data Source Settings; it continued to show a legacy C:\ global
>> permission entry.
>>
>> The source owner authorized equivalent evidence before the formal Refresh Preview.
>> That evidence is preserved in this submission.
>>
>> Independent Audit is asked to determine whether the equivalent evidence is
>> sufficient for PBI-F-004.
>>
>> ### Decision Request 2 - AUD-ASOF-003B runtime mismatch
>>
>> Determine disposition and remediation authority for the following exact condition:
>>
>> FactSourceReconciliation:
>> - 214 / 214 rows = PASS_A1A_R3_STATIC
>> - 0 / 214 rows = literal PASS
>>
>> FactValidationResult:
>> - 533 / 533 rows = PASS
>> - zero non-PASS rows
>>
>> The Source Reconciliation Pass measure requires literal PASS for all
>> FactSourceReconciliation rows.
>>
>> Observed live-engine consequence:
>>
>> PASS_A1A_R3_STATIC does not equal literal PASS
>> → Source Reconciliation Pass = 0
>> → Endpoint Evidence Available = 0
>>
>> The source-owner evidence found no substantive failed source-reconciliation row and
>> no substantive failed validation row.
>>
>> Independent Audit is asked to determine whether:
>>
>> A. PASS_A1A_R3_STATIC is an authorized successful source-reconciliation state and
>>    the DAX acceptance predicate requires bounded remediation;
>>
>> B. the physical reconciliation carrier should instead be normalized to literal PASS;
>>
>> C. the current fail-closed state is intentionally required and no remediation should
>>    occur; or
>>
>> D. another governed disposition is required.
>>
>> No measure, source status, or endpoint-grant logic has been changed after discovery.
>>
>> ## Scope expressly not requested
>>
>> This submission does not request:
>>
>> - PBI-WP2 acceptance;
>> - dashboard/report-page authorization;
>> - substantive report construction;
>> - visual construction;
>> - publication;
>> - deployment;
>> - production-readiness determination;
>> - public milestone language;
>> - redesign of the A1b semantic model beyond any narrowly authorized correction
>>   Independent Audit determines is necessary.
>>
>> Independent Audit retains all finding, closure, and remediation-authorization
>> authority.
>> '@
>>
>> $auditRequest |
>>     Set-Content `
>>         -LiteralPath "$submissionRoot\00_INDEPENDENT_AUDIT_REQUEST.md" `
>>         -Encoding utf8
PS C:\WINDOWS\system32> $copyChecks = @()
>>
>> foreach ($folder in @(
>>     "project",
>>     "power_query",
>>     "tools",
>>     "synthetic_root",
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
>>         $relative = $sourceFile.FullName.Substring(
>>             $sourceRoot.Length + 1
>>         )
>>
>>         $destFile = Join-Path $destRoot $relative
>>
>>         $sourceHash = (
>>             Get-FileHash `
>>                 -LiteralPath $sourceFile.FullName `
>>                 -Algorithm SHA256
>>         ).Hash.ToLowerInvariant()
>>
>>         $destExists = Test-Path -LiteralPath $destFile
>>
>>         $destHash = if ($destExists) {
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
>>             copied_exists = $destExists
>>             pass = (
>>                 $destExists -and
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
Copy controls: 470
Copy failures: 0
PS C:\WINDOWS\system32> $manifestPath = Join-Path $submissionRoot "MANIFEST_SHA256.csv"
>>
>> $payloadFiles = @(
>>     Get-ChildItem `
>>         -LiteralPath $submissionRoot `
>>         -File `
>>         -Recurse `                                                                                                                                                                         >>         -Force |                                                                                                                                                                           >>     Where-Object {                                                                                                                                                                         >>         $_.FullName -cne $manifestPath                                                                                                                                                     >>     } |                                                                                                                                                                                    >>     Sort-Object FullName
>> )
>>
>> $payloadManifest = foreach ($file in $payloadFiles) {
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
Submission manifest entries: 472
PS C:\WINDOWS\system32> $zip = "C:\MSBF\$submissionName.zip"
>>
>> if (Test-Path -LiteralPath $zip) {
>>     throw "STOP: ZIP already exists. Preserve it rather than overwriting."
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

ZIP:     C:\MSBF\MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820.zip
Bytes:   36497498
SHA-256: 49cd887a80de82861aa9f3dafcfb8a479edc0dc22db6a394c3008a1b7ff9bf94
Sidecar: C:\MSBF\MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820.zip.sha256
PS C:\WINDOWS\system32> Add-Type -AssemblyName System.IO.Compression.FileSystem
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
>>         Group-Object { $_.FullName.ToLowerInvariant() } |
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
>>         case_fold_duplicate_paths = $caseFoldDuplicates.Count
>>         archive_read_failures = $readFailures.Count
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


zip                       : MSBF_PBI_A1B_INDEPENDENT_AUDIT_SUBMISSION_R1_20260820.zip
bytes                     : 36497498
sha256                    : 49cd887a80de82861aa9f3dafcfb8a479edc0dc22db6a394c3008a1b7ff9bf94
members                   : 477
unsafe_paths              : 0
duplicate_paths           : 0
case_fold_duplicate_paths : 0
archive_read_failures     : 0
result                    : PASS                                                               88 will be the final interaction number in the file name I'll provide summarizing our interactions.           
<!-- END_SOURCE_MESSAGE -->
