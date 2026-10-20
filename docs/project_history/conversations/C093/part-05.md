# MSBF - Campaign Scale 750 - 2,500 - 25,000

Part 05 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-04.md)
[Next part](part-06.md)

<a id="m-765aba24-01c2-4ec7-933e-1812b8ed6d51"></a>
## Andrew / user · C093-M00095

C093-M00095 · 2026-08-20T19:59:04.765000-04:00 · active path

Preceding visible parent: [C093-M00094](part-04.md#m-97b5eb2f-71d1-4aca-a749-6c5c2c0bb18a)

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Runner = Join-Path (Get-Location).Path "Run-CRWP5R4NativeEvidence.ps1"
>>
>> $Tokens = $null
>> $Errors = $null
>>
>> [System.Management.Automation.Language.Parser]::ParseFile(
>>     $Runner,
>>     [ref]$Tokens,
>>     [ref]$Errors
>> ) | Out-Null
>>
>> $Errors |
>>     Select-Object `
>>         Message,
>>         @{N="StartLine";E={$_.Extent.StartLineNumber}},
>>         @{N="StartColumn";E={$_.Extent.StartColumnNumber}},
>>         @{N="EndLine";E={$_.Extent.EndLineNumber}},
>>         @{N="Text";E={$_.Extent.Text}} |
>>     Format-List
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> Get-Content -LiteralPath $Runner |
>>     Select-Object -First 80
#requires -Version 7.2
[CmdletBinding()]
param(
    [Parameter()][string]$BasePath = (Get-Location).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$CarrierName = 'MSBF_CR_WP5_R4_STATIC_REMEDIATION_20260820_R1.zip'
$ExpectedCarrierSha256 = '285af15ed4859f8e1e5ec72192dd427502cc2b62389fe968de5029878c2e25d5'
$PackageName = 'MSBF_CR_WP5_R4_STATIC_REMEDIATION_20260820_R1'
$EvidenceName = 'CR_WP5_R4_NATIVE_EVIDENCE'
$EvidenceZipName = 'CR_WP5_R4_NATIVE_EVIDENCE.zip'

$BasePath = [IO.Path]::GetFullPath($BasePath)
$CarrierPath = Join-Path $BasePath $CarrierName
$PackageRoot = Join-Path $BasePath $PackageName
$EvidenceRoot = Join-Path $BasePath $EvidenceName
$EvidenceZip = Join-Path $BasePath $EvidenceZipName
$EvidenceSidecar = "$EvidenceZip.sha256"
$PowerShellPath = (Get-Command pwsh -ErrorAction Stop).Source

if (-not (Test-Path -LiteralPath $CarrierPath -PathType Leaf)) {
    throw "Carrier not found: $CarrierPath"
}
$ActualCarrierSha256 = (Get-FileHash -LiteralPath $CarrierPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ActualCarrierSha256 -ne $ExpectedCarrierSha256) {
    throw "Carrier SHA-256 mismatch. Expected=$ExpectedCarrierSha256 Actual=$ActualCarrierSha256"
}
foreach ($path in @($PackageRoot,$EvidenceRoot,$EvidenceZip,$EvidenceSidecar)) {
    if (Test-Path -LiteralPath $path) {
        throw "Clean-run requirement failed; path already exists: $path"
    }
}

Expand-Archive -LiteralPath $CarrierPath -DestinationPath $PackageRoot
$ManifestRows = @(Import-Csv -LiteralPath (Join-Path $PackageRoot 'MANIFEST.csv'))
$ControlEnvelope = @(
    'MANIFEST.csv',
    'SHA256SUMS.txt',
    '13_VALIDATION/R4_FINAL_PACKAGE_VALIDATION.json',
    '13_VALIDATION/R4_FINAL_PACKAGE_VALIDATION.md'
)
$ExpectedPhysicalCount = $ManifestRows.Count + $ControlEnvelope.Count
$PhysicalFiles = @(Get-ChildItem -LiteralPath $PackageRoot -Recurse -File)
if ($PhysicalFiles.Count -ne $ExpectedPhysicalCount) {
    throw "Unexpected extracted population. Expected=$ExpectedPhysicalCount Actual=$($PhysicalFiles.Count)"
}

$Harness = Join-Path $PackageRoot '10_NATIVE_TEST_PREPARATION_R4/Invoke-CRWP5R4NativeOfflineTests.ps1'
& $Harness `
    -PackageRoot $PackageRoot `
    -CarrierPath $CarrierPath `
    -OutputDirectory $EvidenceRoot `
    -PowerShellPath $PowerShellPath

$SummaryPath = Join-Path $EvidenceRoot 'R4_NATIVE_OFFLINE_TEST_SUMMARY.json'
$Summary = Get-Content -LiteralPath $SummaryPath -Raw | ConvertFrom-Json -Depth 50
if ([string]$Summary.overall_status -ne 'PASS' -or [int]$Summary.fail -ne 0) {
    throw 'R4 native suite did not pass.'
}
if (-not [bool]$Summary.production_chain_tested -or
    -not [bool]$Summary.fake_psql_process_invoked -or
    [bool]$Summary.real_psql_process_invoked -or
    [bool]$Summary.postgresql_connection_attempted -or
    [bool]$Summary.database_action_performed -or
    [bool]$Summary.checkpoint_report_executed_against_database -or
    [bool]$Summary.recovery_invoked -or
    [bool]$Summary.campaign_replay_invoked) {
    throw 'R4 native evidence activity boundary failed.'
}
if ([string]$Summary.carrier_sha256 -ne $ExpectedCarrierSha256) {
    throw 'R4 native evidence is not bound to the exact source carrier.'
}

Compress-Archive -Path (Join-Path $EvidenceRoot '*') -DestinationPath $EvidenceZip -CompressionLevel Optimal
$EvidenceSha256 = (Get-FileHash -LiteralPath $EvidenceZip -Algorithm SHA256).Hash.ToLowerInvariant()
"$EvidenceSha256  $EvidenceZipName" | Set-Content -LiteralPath $EvidenceSidecar -Encoding utf8NoBOM
<!-- END_SOURCE_MESSAGE -->


<a id="m-353a99d0-1017-4a83-b264-8a62674b43b9"></a>
## Assistant · C093-M00096

C093-M00096 · 2026-08-20T20:00:42.626384-04:00 · active path

Preceding visible parent: [C093-M00095](part-05.md#m-765aba24-01c2-4ec7-933e-1812b8ed6d51)

<!-- BEGIN_SOURCE_MESSAGE -->
The diagnostic confirms the **outer runner is syntactically valid**: `$Errors` returned nothing. The parse failure is inside the packaged native harness that the runner invokes after extraction.

I found the exact defect in `Invoke-CRWP5R4NativeOfflineTests.ps1`. In the authorization preimage array, three command invocations were written as bare comma-delimited elements:

```powershell
$resolvedPreimage = [string]::Join('|', @(
    [string]$selectedBindingRow.binding_row_sha256,
    [string]$profileRow.profile_binding_row_sha256,
    Get-Hash -Path $fakePsql,
    Get-Hash -Path $targetPath,
    Get-Hash -Path $environmentPath,
    $attemptId,
    [IO.Path]::GetFullPath($attemptRoot)
))
```

Those three `Get-Hash` calls need to be expression-grouped when used as comma-separated array elements:

```powershell
$resolvedPreimage = [string]::Join('|', @(
    [string]$selectedBindingRow.binding_row_sha256,
    [string]$profileRow.profile_binding_row_sha256,
    (Get-Hash -Path $fakePsql),
    (Get-Hash -Path $targetPath),
    (Get-Hash -Path $environmentPath),
    $attemptId,
    [IO.Path]::GetFullPath($attemptRoot)
))
```

That explains the precise `Missing expression after ','` error. I also scanned the remainder of this harness for the same **bare command + trailing comma** pattern; these are the three occurrences I found.

So, importantly:

- your PowerShell 7.6.5 installation is fine;
- `Run-CRWP5R4NativeEvidence.ps1` itself parses correctly;
- the R4 native harness has a real source defect;
- the production chain did **not** run;
- this attempt cannot be native evidence;
- we should **not manually patch your extracted copy**, because R4 requires regenerated final identities and native evidence from the exact final bytes. The governing R4 requirement explicitly calls for regenerated manifests/source-tree identities/native evidence and testing of the exact production path. [export reference: filecite | turn20file1 | L15-L17]

The folders created during this failed attempt are therefore only partial diagnostic artifacts. They should not be reused as final evidence.

I should now produce a bounded **CR-WP5 R4 Correction R1** that fixes these three expressions, re-scans the complete PowerShell population for this syntax class, regenerates the affected manifest/tree/carrier identities, and gives you a fresh runner tied to the corrected bytes. We should preserve the current R4 substantive remediation and change nothing unrelated. PostgreSQL and all campaign execution remain prohibited. [export reference: filecite | turn20file0 | L218-L220]
<!-- END_SOURCE_MESSAGE -->


<a id="m-b5eea0d7-940f-45cc-98cf-3512769d2115"></a>
## Andrew / user · C093-M00097

C093-M00097 · 2026-08-20T20:02:33.078000-04:00 · active path

Preceding visible parent: [C093-M00096](part-05.md#m-353a99d0-1017-4a83-b264-8a62674b43b9)

<!-- BEGIN_SOURCE_MESSAGE -->
produce a bounded **CR-WP5 R4 Correction R1** that fixes these three expressions, re-scans the complete PowerShell population for this syntax class, regenerates the affected manifest/tree/carrier identities, and gives you a fresh runner tied to the corrected bytes. We should preserve the current R4 substantive remediation and change nothing unrelated. PostgreSQL and all campaign execution remain prohibited.   
<!-- END_SOURCE_MESSAGE -->


<a id="m-9ad93b5b-6d9b-48b9-b0a6-9a9c0753dc61"></a>
## Assistant · C093-M00098

C093-M00098 · 2026-08-20T20:02:36.885645-04:00 · active path

Preceding visible parent: [C093-M00097](part-05.md#m-b5eea0d7-940f-45cc-98cf-3512769d2115)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll patch only the three bare command expressions in the R4 native harness, scan the full PowerShell population for the same comma-delimited command-expression defect, then rebuild the package-control identities and issue a fresh Correction R1 carrier and runner. No PostgreSQL or campaign execution will occur.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6e0feb79-90b2-48f0-876a-463e12fdb79c"></a>
## Assistant · C093-M00099

C093-M00099 · 2026-08-20T20:06:29.362952-04:00 · active path

Preceding visible parent: [C093-M00098](part-05.md#m-9ad93b5b-6d9b-48b9-b0a6-9a9c0753dc61)

<!-- BEGIN_SOURCE_MESSAGE -->
# CR-WP5 R4 Correction R1 Complete

The bounded correction is complete. I changed only the reproduced native-harness parse defect and the package-control identities necessarily affected by that change; the substantive R4 trust, catalog-binding, same-session transcript, fake-`psql`, freshness, and authorization design is preserved.

The governing audit requires R4 to regenerate identities and native evidence from the final physical bytes while remaining entirely offline from PostgreSQL. [export reference: filecite | turn20file1 | L7-L17]

## Correction result

| Control | Result |
|---|---:|
| Original malformed expressions | **3** |
| Corrected expressions | **3 / 3** |
| PowerShell-family files rescanned | **6** |
| Residual hits for this exact syntax class | **0** |
| PostgreSQL connections | **0** |
| Real `psql` invocations | **0** |
| Database actions | **0** |
| Checkpoint/report execution | **0** |
| Recovery/replay | **0** |
| Native evidence | **PENDING FRESH POWERSHELL RUN** |

The three corrected expressions are now:

```powershell
(Get-Hash -Path $fakePsql),
(Get-Hash -Path $targetPath),
(Get-Hash -Path $environmentPath),
```

instead of the invalid bare command forms.

## New controlling source identity

```text
Artifact
MSBF_CR_WP5_R4_CORRECTION_R1_STATIC_REMEDIATION_20260820.zip

SHA-256
d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342

Manifest rows
1,059

Package payload-tree SHA-256
b4a13539ee0d43b2c5fb1fe21efc77a80e1021d8214f1f0c97dab6c355571499

Protected-manifest SHA-256
6fbb80b9a522d5aae87efd07d1db525bffd0f1e1223640de7d8ef6dff847096a

Protected-tree SHA-256
c8a8961623cc04f797bdbdfad8432a25cd7ac8c3d32dcb31499e650b3fc26948
```

The protected tree changed because the authorization template is now bound to the exact **Correction R1 carrier filename**. The native harness itself is not in that protected population, but its corrected SHA-256 is propagated through the runtime identity root:

```text
Original R4 harness
1863c3ac21ca61ec1a4511fb634117dab97466dbc17220f8354566e7aeae5380

Correction R1 harness
b65f8b69ed713c20b8b6e5b241ade2dc09e159fa2d90c49ad34fdab26176b7dc
```

## Deliverables

- Download the R4 Correction R1 source carrier (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R1_STATIC_REMEDIATION_20260820.zip`; referenced bytes not established here)
- Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R1_STATIC_REMEDIATION_20260820.zip.sha256`; referenced bytes not established here)
- Read the external validation report (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R1_STATIC_REMEDIATION_20260820_VALIDATION_REPORT.md`; referenced bytes not established here)
- Download the machine-readable validation (historical reference: `sandbox:[session]/MSBF_CR_WP5_R4_CORRECTION_R1_STATIC_REMEDIATION_20260820_VALIDATION_REPORT.json`; referenced bytes not established here)
- Read the bounded Correction R1 report (historical reference: `sandbox:[session]/_crwp5_r4_correction_r1_build/15_CORRECTION_R1/CR_WP5_R4_CORRECTION_R1_REPORT.md`; referenced bytes not established here)
- Download the full PowerShell syntax-class scan (historical reference: `sandbox:[session]/_crwp5_r4_correction_r1_build/15_CORRECTION_R1/POWERSHELL_BARE_COMMAND_ARRAY_SCAN_RESULTS.csv`; referenced bytes not established here)
- Download the three reproduced original-R4 findings (historical reference: `sandbox:[session]/_crwp5_r4_correction_r1_build/15_CORRECTION_R1/ORIGINAL_R4_SYNTAX_CLASS_FINDINGS.csv`; referenced bytes not established here)
- Download the R4→Correction R1 diff (historical reference: `sandbox:[session]/_crwp5_r4_correction_r1_build/15_CORRECTION_R1/R4_R1_TO_CORRECTION_R1_DIFF.csv`; referenced bytes not established here)

## Fresh native runner

The new runner is bound specifically to carrier SHA-256:

```text
d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342
```

Runner SHA-256:

```text
4997b259a4c2ec59900a98c0350c08f83c1a074f599e0ef9b260877c1edf19fe
```

- Download the Correction R1 native runner (historical reference: `sandbox:[session]/Run-CRWP5R4CorrectionR1NativeEvidence.ps1`; referenced bytes not established here)
- Download the runner SHA-256 sidecar (historical reference: `sandbox:[session]/Run-CRWP5R4CorrectionR1NativeEvidence.ps1.sha256`; referenced bytes not established here)
- Read the fresh native-run instructions (historical reference: `sandbox:[session]/CR_WP5_R4_CORRECTION_R1_NATIVE_RUN_INSTRUCTIONS.md`; referenced bytes not established here)

In your PowerShell 7.6.5/Core window, place the corrected ZIP and runner together and execute:

```powershell
$PSVersionTable.PSVersion
$PSVersionTable.PSEdition

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

& .\Run-CRWP5R4CorrectionR1NativeEvidence.ps1 `
    -BasePath (Get-Location).Path
```

It uses new Correction R1 extraction/evidence directory names, so the partial original-R4 folders can remain untouched as diagnostic provenance.

If successful, upload:

```text
CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE.zip
CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE.zip.sha256
```

Only after that fresh exact-byte native run should we assemble the final `ER-CAM-004/005/006/007` audit wrapper. PostgreSQL, real `psql`, database activity, accepted checkpoint/report execution, recovery, and all campaign stages remain prohibited. [export reference: filecite | turn20file1 | L19-L30]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e0246e0d-d3bb-440b-8409-a10768e22b33"></a>
## Andrew / user · C093-M00100

C093-M00100 · 2026-08-20T20:20:30.325000-04:00 · active path

Preceding visible parent: [C093-M00099](part-05.md#m-6e0feb79-90b2-48f0-876a-463e12fdb79c)

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $PSVersionTable.PSVersion
>> $PSVersionTable.PSEdition
>>
>> Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
>>
>> & .\Run-CRWP5R4CorrectionR1NativeEvidence.ps1 `
>>     -BasePath (Get-Location).Path

Major  Minor  Patch  PreReleaseLabel BuildLabel
-----  -----  -----  --------------- ----------
7      6      5
Core
{
  "schema_version": "MSBF_CR_WP5_R4_NATIVE_OFFLINE_TEST_SUMMARY_V1",
  "carrier_sha256": "d57a90256adfa265c9f1777a01f88158e4499c57d42c1d2571bc56f174a15342",
  "package_manifest_sha256": "690c718aa02218c618281308da9be1e72cadd9d29cf1debbba0086035859e260",
  "package_payload_tree_sha256": "b4a13539ee0d43b2c5fb1fe21efc77a80e1021d8214f1f0c97dab6c355571499",
  "complete_extracted_tree_sha256": "c646c1546100842283a3b4c514d48ff11375e7873664278b1d8fd1a4ffad538b",
  "protected_tree_manifest_sha256": "6fbb80b9a522d5aae87efd07d1db525bffd0f1e1223640de7d8ef6dff847096a",
  "protected_tree_sha256": "c8a8961623cc04f797bdbdfad8432a25cd7ac8c3d32dcb31499e650b3fc26948",
  "ast_files": 6,
  "ast_pass": 6,
  "tests": 53,
  "pass": 36,
  "fail": 17,
  "overall_status": "FAIL",
  "production_chain_tested": true,
  "fake_psql_process_invoked": true,
  "real_psql_process_invoked": false,
  "postgresql_connection_attempted": false,
  "database_action_performed": false,
  "checkpoint_report_executed_against_database": false,
  "recovery_invoked": false,
  "campaign_replay_invoked": false,
  "tested_at_utc": "2026-08-21T00:19:24.5626725+00:00"
}
Exception: D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\Run-CRWP5R4CorrectionR1NativeEvidence.ps1:61
Line |
  61 |      throw 'R4 native suite did not pass.'
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | R4 native suite did not pass.
<!-- END_SOURCE_MESSAGE -->


<a id="m-077671c2-43ba-49f6-90a4-194c583bda48"></a>
## Assistant · C093-M00101

C093-M00101 · 2026-08-20T20:20:36.902708-04:00 · active path

Preceding visible parent: [C093-M00100](part-05.md#m-e0246e0d-d3bb-440b-8409-a10768e22b33)

<!-- BEGIN_SOURCE_MESSAGE -->
This is materially different from the earlier parse failure: **Correction R1 successfully executed the complete native R4 harness and the exact fake-`psql` production path**, but 17 of 53 controls failed. The safety boundary held—real `psql`, PostgreSQL, database actions, accepted checkpoint/report execution, recovery, and replay all remained false—so we should preserve this run as diagnostic evidence and **not rebuild or rerun anything yet**.

We need the exact 17 failed controls before deciding whether they represent production-path defects, fake-`psql` fixture defects, stale test expectations, or a smaller common root cause. In the same PowerShell window, run:

```powershell
$EvidenceRoot = Join-Path (Get-Location).Path `
    "CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE"

Test-Path -LiteralPath $EvidenceRoot
```

It should return `True`. Then run:

```powershell
$Results = Import-Csv `
    (Join-Path $EvidenceRoot "R4_NATIVE_ADVERSARIAL_TEST_RESULTS.csv")

$Results |
    Where-Object status -eq "FAIL" |
    Format-List *
```

Also give me a compact view:

```powershell
$Results |
    Where-Object status -eq "FAIL" |
    Select-Object test_id, expected, actual, status, detail |
    Format-Table -Wrap -AutoSize
```

And the complete test population:

```powershell
$Results |
    Select-Object test_id, status, expected, actual |
    Format-Table -AutoSize
```

Finally, list the evidence files:

```powershell
Get-ChildItem -LiteralPath $EvidenceRoot -Recurse -File |
    Select-Object FullName, Length |
    Format-Table -AutoSize
```

If the results CSV has a different filename, this command will show the available CSVs:

```powershell
Get-ChildItem -LiteralPath $EvidenceRoot -Recurse -File -Filter "*.csv" |
    Select-Object FullName
```

Paste those outputs here. **Do not delete the evidence folder, modify the extracted Correction R1 package, manually create an evidence ZIP, or rerun the harness.**

What we already know is useful:

```text
Native AST                         6 / 6 PASS
Native controls                   36 / 53 PASS
Production chain exercised        true
Fake psql process invoked         true
Real psql process invoked         false
PostgreSQL connection attempted   false
Database action                   false
Checkpoint/report against DB      false
Recovery                          false
Campaign replay                   false
```

So the bounded Correction R1 achieved its immediate purpose: it got us through parsing and into the **actual production trust-receipt → orchestrator → driver → fake-psql path** without touching PostgreSQL. The 17 failed rows are now the evidence needed to diagnose R4 itself rather than another syntax problem.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d12bf5ed-96c2-4fe9-8937-cf847e331cd2"></a>
## Andrew / user · C093-M00102

C093-M00102 · 2026-08-20T20:24:49.703000-04:00 · active path

Preceding visible parent: [C093-M00101](part-05.md#m-077671c2-43ba-49f6-90a4-194c583bda48)

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $EvidenceRoot = Join-Path (Get-Location).Path `
>>     "CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE"
>>
>> Test-Path -LiteralPath $EvidenceRoot
True
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results = Import-Csv `
>>     (Join-Path $EvidenceRoot "R4_NATIVE_ADVERSARIAL_TEST_RESULTS.csv")
>>
>> $Results |
>>     Where-Object status -eq "FAIL" |
>>     Format-List *
Import-Csv: Could not find file 'D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_ADVERSARIAL_TEST_RESULTS.csv'.
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results |
>>     Where-Object status -eq "FAIL" |
>>     Select-Object test_id, expected, actual, status, detail |
>>     Format-Table -Wrap -AutoSize
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> $Results |
>>     Select-Object test_id, status, expected, actual |
>>     Format-Table -AutoSize
PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> Get-ChildItem -LiteralPath $EvidenceRoot -Recurse -File |
>>     Select-Object FullName, Length |
>>     Format-Table -AutoSize

FullName                                                                                                                                                                                                      Length
--------                                                                                                                                                                                                      ------
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_ADVERSARIAL_AND_PRODUCTION_PATH_RESULTS.csv                                                       20378
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_MODULE_IMPORT.stderr.txt                                                                              0
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_MODULE_IMPORT.stdout.txt                                                                            323
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_OFFLINE_TEST_SUMMARY.json                                                                          1160
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_POWERSHELL_AST_RESULTS.csv                                                                          994
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ADAPTER_TYPE_MISMATCH\authorization_envelope.json                                      756
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ADAPTER_TYPE_MISMATCH\authorization_payload.json                                      7369
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ADAPTER_TYPE_MISMATCH\environment.json                                                 281
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ADAPTER_TYPE_MISMATCH\target.json                                                      461
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BACKEND_PID_CHANGE\authorization_envelope.json                                         753
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BACKEND_PID_CHANGE\authorization_payload.json                                         7375
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BACKEND_PID_CHANGE\environment.json                                                    278
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BACKEND_PID_CHANGE\target.json                                                         458
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BASELINE\authorization_envelope_override_1868c450d7cc4f89833182371be0ea5c.json         747
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BASELINE\authorization_envelope_override_96e1016faa394684a1b2257dcace76b4.json         738
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BASELINE\authorization_envelope.json                                                   743
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BASELINE\authorization_payload.json                                                   7321
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BASELINE\environment.json                                                              268
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_BASELINE\target.json                                                                   448
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CATALOG_ROW_MISMATCH\authorization_envelope.json                                       755
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CATALOG_ROW_MISMATCH\authorization_payload.json                                       7369
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CATALOG_ROW_MISMATCH\environment.json                                                  280
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CATALOG_ROW_MISMATCH\target.json                                                       460
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CONNECTION_SUBSTITUTION\authorization_envelope.json                                    758
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CONNECTION_SUBSTITUTION\authorization_payload.json                                    7400
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CONNECTION_SUBSTITUTION\environment.json                                               283
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_CONNECTION_SUBSTITUTION\target.json                                                    463
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DEFINITION_MISMATCH\authorization_envelope.json                                        754
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DEFINITION_MISMATCH\authorization_payload.json                                        7365
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DEFINITION_MISMATCH\environment.json                                                   279
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DEFINITION_MISMATCH\target.json                                                        459
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DUPLICATE_MARKER\authorization_envelope.json                                           751
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DUPLICATE_MARKER\authorization_payload.json                                           7365
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DUPLICATE_MARKER\environment.json                                                      276
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_DUPLICATE_MARKER\target.json                                                           456
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MARKER_ONLY_SPOOF\authorization_envelope.json                                          752
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MARKER_ONLY_SPOOF\authorization_payload.json                                          7370
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MARKER_ONLY_SPOOF\environment.json                                                     277
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MARKER_ONLY_SPOOF\target.json                                                          457
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MISSING_MARKER\authorization_envelope.json                                             749
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MISSING_MARKER\authorization_payload.json                                             7355
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MISSING_MARKER\environment.json                                                        274
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_MISSING_MARKER\target.json                                                             454
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PARAMETERIZED_CHECKPOINT_005\authorization_envelope.json                               763
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PARAMETERIZED_CHECKPOINT_005\authorization_payload.json                               7401
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PARAMETERIZED_CHECKPOINT_005\environment.json                                          288
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PARAMETERIZED_CHECKPOINT_005\target.json                                               468
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PRISTINE_STATE_DRIFT\authorization_envelope.json                                       755
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PRISTINE_STATE_DRIFT\authorization_payload.json                                       7385
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PRISTINE_STATE_DRIFT\environment.json                                                  280
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PRISTINE_STATE_DRIFT\target.json                                                       460
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROCESS_FAILURE_QUARANTINE\authorization_envelope.json                                 761
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROCESS_FAILURE_QUARANTINE\authorization_payload.json                                 7406
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROCESS_FAILURE_QUARANTINE\environment.json                                            286
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROCESS_FAILURE_QUARANTINE\target.json                                                 466
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROFILE_MISMATCH\authorization_envelope.json                                           751
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROFILE_MISMATCH\authorization_payload.json                                           7353
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROFILE_MISMATCH\environment.json                                                      276
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PROFILE_MISMATCH\target.json                                                           456
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PSQL_PROCESS_FAIL\authorization_envelope.json                                          752
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PSQL_PROCESS_FAIL\authorization_payload.json                                          7370
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PSQL_PROCESS_FAIL\environment.json                                                     277
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_PSQL_PROCESS_FAIL\target.json                                                          457
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_MISMATCH\authorization_envelope.json                                             749
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_MISMATCH\authorization_payload.json                                             7345
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_MISMATCH\environment.json                                                        274
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_MISMATCH\target.json                                                             454
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_PATH_MISMATCH\authorization_envelope.json                                        754
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_PATH_MISMATCH\authorization_payload.json                                        7365
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_PATH_MISMATCH\environment.json                                                   279
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_QUERY_PATH_MISMATCH\target.json                                                        459
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_REORDERED_MARKER\authorization_envelope.json                                           751
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_REORDERED_MARKER\authorization_payload.json                                           7365
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_REORDERED_MARKER\environment.json                                                      276
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_REORDERED_MARKER\target.json                                                           456
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ROLE_SUBSTITUTION\authorization_envelope.json                                          752
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ROLE_SUBSTITUTION\authorization_payload.json                                          7370
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ROLE_SUBSTITUTION\environment.json                                                     277
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_ROLE_SUBSTITUTION\target.json                                                          457
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_SOURCE_PLAN_MISMATCH\authorization_envelope.json                                       755
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_SOURCE_PLAN_MISMATCH\authorization_payload.json                                       7369
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_SOURCE_PLAN_MISMATCH\environment.json                                                  280
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\case_SOURCE_PLAN_MISMATCH\target.json                                                       460
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\external_authority\Invoke-MSBFIndependentPreImportTrustGate_TAMPERED.ps1                  45838
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\external_authority\Invoke-MSBFIndependentPreImportTrustGate.ps1                           45817
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\external_authority\offline_test_trust_anchor.json                                          1274
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\external_authority\R4_OFFLINE_BOOTSTRAP_CARRIER_TAMPERED.zip                               8343
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\external_authority\R4_OFFLINE_BOOTSTRAP_CARRIER.zip                                        8325
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\offline_test_work\external_authority\bootstrap_carrier_source\Invoke-MSBFIndependentPreImportTrustGate.ps1  45817

PS D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000> Get-ChildItem -LiteralPath $EvidenceRoot -Recurse -File -Filter "*.csv" |
>>     Select-Object FullName

FullName
--------
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_ADVERSARIAL_AND_PRODUCTION_PATH_RESULTS.csv
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE\R4_NATIVE_POWERSHELL_AST_RESULTS.csv
<!-- END_SOURCE_MESSAGE -->


<a id="m-9ba4e8be-be57-4713-84b6-b25f4629e7ee"></a>
## Assistant · C093-M00103

C093-M00103 · 2026-08-20T20:24:55.013375-04:00 · active path

Preceding visible parent: [C093-M00102](part-05.md#m-d12bf5ed-96c2-4fe9-8937-cf847e331cd2)

<!-- BEGIN_SOURCE_MESSAGE -->
You found the issue: I gave you the wrong CSV filename. The native harness wrote:

```text
R4_NATIVE_ADVERSARIAL_AND_PRODUCTION_PATH_RESULTS.csv
```

—not `R4_NATIVE_ADVERSARIAL_TEST_RESULTS.csv`.

Your evidence folder is intact and contains the diagnostic artifacts we need. Do **not** rerun anything yet.

Run these commands exactly:

```powershell
$Results = Import-Csv `
    (Join-Path $EvidenceRoot "R4_NATIVE_ADVERSARIAL_AND_PRODUCTION_PATH_RESULTS.csv")
```

Then show all 17 failures in full detail:

```powershell
$Results |
    Where-Object status -eq "FAIL" |
    Format-List *
```

Then the compact failure view:

```powershell
$Results |
    Where-Object status -eq "FAIL" |
    Select-Object test_id, expected, actual, status, detail |
    Format-Table -Wrap -AutoSize
```

And finally the entire 53-control population:

```powershell
$Results |
    Select-Object test_id, status, expected, actual |
    Format-Table -AutoSize
```

Please paste those three outputs here.

One useful thing is already clear from the file population you showed: the harness created cases for baseline production execution, parameterized checkpoint execution, catalog/definition/query/profile/source-plan mismatches, connection and role substitution, backend-PID changes, pristine-state drift, transcript-marker attacks, and process/quarantine failures. So the 17 failures may cluster around only one or two shared production-path defects rather than representing 17 separate problems.

Keep the entire `CR_WP5_R4_CORRECTION_R1_NATIVE_EVIDENCE` directory unchanged. Once I see the failed rows, I’ll trace them to their common root causes before we modify any governed bytes.
<!-- END_SOURCE_MESSAGE -->
