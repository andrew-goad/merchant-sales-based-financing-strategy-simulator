# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 05 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-04.md)
[Next part](part-06.md)

<a id="m-f05426f1-17bb-4c6a-a78b-01076c3f3d52"></a>
## Assistant · C123-M00062

C123-M00062 · 2026-09-10T08:17:13.675037-04:00 · active path

Preceding visible parent: [C123-M00061](part-04.md#m-9ad08d54-40b2-4b66-88b4-d5d7506e5ff1)

<!-- BEGIN_SOURCE_MESSAGE -->
The mismatch is now explained. **R6 is not defective. The retry wrapper invoked the wrong retained overlay validator.**

R6 contains **two** overlay validators:

```text
successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py
successor_candidates\m2-g3-v2.1.0-rc2\tools\validate_candidate_overlay.py
```

I independently checked the exact retained R6 ZIP again. Their outputs are:

```text
rc1 validator:
Candidate overlay validation PASS
Governed candidate files: 235
```

```text
rc2 validator:
Candidate overlay validation PASS
Governed candidate files: 248
```

And the root validator still returns:

```text
Public release validation PASS
Governed manifest files: 2880
Module 2 stage folders: 12
```

So the problem was my Phase C retry line that hardcoded the **rc1** validator while still asserting the **rc2 expected count of 248**.

The correct disposition is therefore:

```text
PHASE_C_ATTEMPT_1 = FAILED_SCRIPT_GUARD_LOGIC
PHASE_C_ATTEMPT_2 = FAILED_WRAPPER_VALIDATOR_SELECTION
R6_DEFECT = NO
RC1_VALIDATOR = PASS / 235
RC2_VALIDATOR = PASS / 248
CHECKOUT_MUTATION = NONE
GIT_MUTATION = NONE
PUBLICATION = NONE
```

We do **not** weaken or edit either validator. Both are legitimate historical/current retained validators with different governed populations.

Run this bounded completion block against the **already extracted staging tree**. There is no need to extract R6 a third time.

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'
    $EvidenceDir = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_20260910T121241797Z_028c5f94'

    $R6Zip = 'D:\MSBF_ZIP_FILES_091026\MSBF_FINAL_INTEGRATED_PUBLICATION_CANDIDATE_R6_20260910_FINAL_MICROPOLISH.zip'

    $ExpectedR6Bytes = 279632507
    $ExpectedR6Sha256 = '31611a7c90ad7a0b597ecc3c0a5592c2aa7c031a82b5c7fbcc40750c8e8d0bf2'
    $ExpectedMembers = 2884

    $ExpectedPbixBytes = 27635305
    $ExpectedPbixSha256 = 'ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4'

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE C — FINAL VALIDATION COMPLETION"
    Write-Host "============================================================"
    Write-Host "Staging:  $Stage"
    Write-Host "Evidence: $EvidenceDir"
    Write-Host ""

    foreach ($required in @($Stage,$EvidenceDir)) {
        if (-not (Test-Path -LiteralPath $required -PathType Container)) {
            throw "Required directory missing: $required"
        }
    }

    if (-not (Test-Path -LiteralPath $R6Zip -PathType Leaf)) {
        throw "R6 ZIP missing: $R6Zip"
    }

    # ---------------------------------------------------------
    # 1. Reconfirm outer R6 identity
    # ---------------------------------------------------------

    $R6Item = Get-Item -LiteralPath $R6Zip
    $R6Hash = (Get-FileHash -LiteralPath $R6Zip -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($R6Item.Length -ne $ExpectedR6Bytes) {
        throw "R6 size mismatch."
    }

    if ($R6Hash -cne $ExpectedR6Sha256) {
        throw "R6 SHA-256 mismatch."
    }

    # ---------------------------------------------------------
    # 2. Reconfirm extracted population
    # ---------------------------------------------------------

    $StageFiles = @(Get-ChildItem -LiteralPath $Stage -Recurse -File -Force)

    if ($StageFiles.Count -ne $ExpectedMembers) {
        throw "Extracted-file count mismatch. Expected $ExpectedMembers ; actual $($StageFiles.Count)"
    }

    # ---------------------------------------------------------
    # 3. Locate Python
    # ---------------------------------------------------------

    $PythonExe = $null
    $PythonPrefix = @()

    $pythonCmd = Get-Command python.exe -ErrorAction SilentlyContinue

    if ($pythonCmd) {
        $PythonExe = $pythonCmd.Source
    }
    else {
        $pyCmd = Get-Command py.exe -ErrorAction SilentlyContinue

        if ($pyCmd) {
            $PythonExe = $pyCmd.Source
            $PythonPrefix = @('-3')
        }
    }

    if (-not $PythonExe) {
        throw "Python launcher not found."
    }

    # ---------------------------------------------------------
    # 4. Exact validator paths
    # ---------------------------------------------------------

    $PublicValidator = Join-Path $Stage `
        'tools\validate_public_release.py'

    $Rc1Validator = Join-Path $Stage `
        'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py'

    $Rc2Validator = Join-Path $Stage `
        'successor_candidates\m2-g3-v2.1.0-rc2\tools\validate_candidate_overlay.py'

    foreach ($v in @($PublicValidator,$Rc1Validator,$Rc2Validator)) {
        if (-not (Test-Path -LiteralPath $v -PathType Leaf)) {
            throw "Validator missing: $v"
        }
    }

    # ---------------------------------------------------------
    # 5. Run all three unchanged validators
    # ---------------------------------------------------------

    Push-Location $Stage

    try {
        $PublicOutput = @(& $PythonExe @PythonPrefix $PublicValidator 2>&1)
        $PublicCode = $LASTEXITCODE

        $Rc1Output = @(& $PythonExe @PythonPrefix $Rc1Validator 2>&1)
        $Rc1Code = $LASTEXITCODE

        $Rc2Output = @(& $PythonExe @PythonPrefix $Rc2Validator 2>&1)
        $Rc2Code = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    $PublicText = $PublicOutput -join "`n"
    $Rc1Text = $Rc1Output -join "`n"
    $Rc2Text = $Rc2Output -join "`n"

    if ($PublicCode -ne 0) {
        throw "Public validator failed:`n$PublicText"
    }

    if ($Rc1Code -ne 0) {
        throw "rc1 overlay validator failed:`n$Rc1Text"
    }

    if ($Rc2Code -ne 0) {
        throw "rc2 overlay validator failed:`n$Rc2Text"
    }

    if ($PublicText -notmatch 'Public release validation PASS' -or
        $PublicText -notmatch 'Governed manifest files:\s*2880' -or
        $PublicText -notmatch 'Module 2 stage folders:\s*12') {
        throw "Public validator output differs from expected R6 result."
    }

    if ($Rc1Text -notmatch 'Candidate overlay validation PASS' -or
        $Rc1Text -notmatch 'Governed candidate files:\s*235') {
        throw "rc1 overlay output differs from its retained expected result."
    }

    if ($Rc2Text -notmatch 'Candidate overlay validation PASS' -or
        $Rc2Text -notmatch 'Governed candidate files:\s*248') {
        throw "rc2 overlay output differs from its retained expected result."
    }

    # ---------------------------------------------------------
    # 6. PBIX identity
    # ---------------------------------------------------------

    $PbixPath = Join-Path $Stage `
        'docs\power_bi\m2_v2_1\release\MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix'

    if (-not (Test-Path -LiteralPath $PbixPath -PathType Leaf)) {
        throw "Accepted PBIX missing."
    }

    $Pbix = Get-Item -LiteralPath $PbixPath
    $PbixHash = (Get-FileHash -LiteralPath $PbixPath -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($Pbix.Length -ne $ExpectedPbixBytes) {
        throw "PBIX byte-size mismatch."
    }

    if ($PbixHash -cne $ExpectedPbixSha256) {
        throw "PBIX SHA-256 mismatch."
    }

    # ---------------------------------------------------------
    # 7. Eleven exact R22 excluded paths
    #
    # Pull them from the public exclusion register in R6 if present.
    # Fail closed if the register cannot be resolved.
    # ---------------------------------------------------------

    $ExclusionRegisterHits = @(
        Get-ChildItem -LiteralPath $Stage -Recurse -File |
        Where-Object {
            $_.Name -match '(?i)exclusion|provenance|projection'
        } |
        Select-String -SimpleMatch '02_POST_DESKTOP_STRUCTURAL_VALIDATION.json' `
            -List -ErrorAction SilentlyContinue |
        Select-Object -ExpandProperty Path -Unique
    )

    if ($ExclusionRegisterHits.Count -eq 0) {
        throw "Could not resolve a retained public exclusion/provenance record for R22."
    }

    # Direct known private-R22 subtree must not exist as public payload.
    $PrivateR22Root = Join-Path $Stage `
        'successor_candidates\m2-g3-v2.1.0-rc2\power_bi\evidence\r22'

    $PrivateR22Files = @()

    if (Test-Path -LiteralPath $PrivateR22Root) {
        $PrivateR22Files = @(
            Get-ChildItem -LiteralPath $PrivateR22Root -Recurse -File -Force
        )
    }

    if ($PrivateR22Files.Count -gt 0) {
        throw "Private R22 payload files are present under excluded subtree."
    }

    # ---------------------------------------------------------
    # 8. Private/raw carrier screening
    # ---------------------------------------------------------

    $ForbiddenPatterns = @(
        '*PRIVATE*.zip',
        '*EVIDENCE_PRIVATE*.zip',
        '*CONTROL_PRIVATE*.zip',
        '*AUDIT_RETURN*.zip',
        '*PART4_RETURN*.zip',
        '*ChatGPT Conversation Log*.pdf'
    )

    $Forbidden = New-Object System.Collections.Generic.List[string]

    foreach ($pattern in $ForbiddenPatterns) {
        Get-ChildItem -LiteralPath $Stage -Recurse -File -Filter $pattern `
            -ErrorAction SilentlyContinue |
            ForEach-Object { $Forbidden.Add($_.FullName) }
    }

    if ($Forbidden.Count -gt 0) {
        throw "Potential private/raw carrier found: $($Forbidden -join '; ')"
    }

    # ---------------------------------------------------------
    # 9. Standalone font check
    # ---------------------------------------------------------

    $FontExtensions = @('.ttf','.otf','.woff','.woff2','.eot')

    $Fonts = @(
        $StageFiles |
        Where-Object { $FontExtensions -contains $_.Extension.ToLowerInvariant() }
    )

    if ($Fonts.Count -gt 0) {
        throw "Standalone fonts found: $($Fonts.FullName -join '; ')"
    }

    # ---------------------------------------------------------
    # 10. Key public routes
    # ---------------------------------------------------------

    $RequiredPublicPaths = @(
        'README.md',
        'docs\README.md',
        'docs\guide\CURRENT_USE.md',
        'docs\guide\EXPLAINABILITY.md',
        'docs\guide\LEARNING.md',
        'docs\guide\VISUALS.md',

        'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_738_baseline.png',
        'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_749_baseline.png',

        'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\posters\MSBF_MCI_How_the_Governed_Decision_Engine_Works_v2_1_COPYFIX_R1.png',
        'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\posters\MSBF_MCI_What_Happens_After_the_Decision_v2_1_COPYFIX_R1.png'
    )

    foreach ($relative in $RequiredPublicPaths) {
        if (-not (Test-Path -LiteralPath (Join-Path $Stage $relative) -PathType Leaf)) {
            throw "Required public path missing: $relative"
        }
    }

    # ---------------------------------------------------------
    # 11. Write final Phase C receipt
    # ---------------------------------------------------------

    $Receipt = [ordered]@{
        SchemaVersion = '1.2'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_C_FINAL'
        GoverningDecision = 'IA-D-R20-INT-001'
        ConditionalAuthority = 'IA-PUB-R20-INTEGRATED-001'

        PriorAttempt1 = 'FAILED_SCRIPT_GUARD_LOGIC'
        PriorAttempt2 = 'FAILED_WRAPPER_VALIDATOR_SELECTION'
        CandidateDefectEstablished = $false

        R6Zip = $R6Zip
        R6Bytes = $R6Item.Length
        R6Sha256 = $R6Hash

        Stage = $Stage
        EvidenceDirectory = $EvidenceDir
        ExtractedFiles = $StageFiles.Count

        PublicValidator = [ordered]@{
            Path = 'tools\validate_public_release.py'
            ExitCode = $PublicCode
            Output = @($PublicOutput)
            ExpectedGovernedFiles = 2880
        }

        Rc1OverlayValidator = [ordered]@{
            Path = 'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py'
            ExitCode = $Rc1Code
            Output = @($Rc1Output)
            ExpectedGovernedFiles = 235
        }

        Rc2OverlayValidator = [ordered]@{
            Path = 'successor_candidates\m2-g3-v2.1.0-rc2\tools\validate_candidate_overlay.py'
            ExitCode = $Rc2Code
            Output = @($Rc2Output)
            ExpectedGovernedFiles = 248
        }

        PbixBytes = $Pbix.Length
        PbixSha256 = $PbixHash

        PrivateR22Files = $PrivateR22Files.Count
        ForbiddenPrivateCarriers = $Forbidden.Count
        StandaloneFonts = $Fonts.Count

        ExclusionProvenanceRecordCandidates = @($ExclusionRegisterHits)

        CheckoutMutation = 'NONE'
        GitMutation = 'NONE'
        Publication = 'NOT_PERFORMED'

        PhaseCStatus = 'PASS'
    }

    $JsonPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_C_R6_STAGING_VALIDATION_FINAL.json'

    $TxtPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_C_FINAL_SUMMARY.txt'

    $Receipt |
        ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $JsonPath -Encoding UTF8

    $Summary = @(
        'PHASE_C_R6_STAGING = PASS',
        "R6 SHA-256: $R6Hash",
        "Staging root: $Stage",
        "Extracted files: $($StageFiles.Count)",
        '',
        'Public release validation PASS',
        'Governed manifest files: 2880',
        'Module 2 stage folders: 12',
        '',
        'rc1 candidate overlay validation PASS',
        'Governed candidate files: 235',
        '',
        'rc2 candidate overlay validation PASS',
        'Governed candidate files: 248',
        '',
        "Private R22 payload files: $($PrivateR22Files.Count)",
        "Forbidden private/raw carriers: $($Forbidden.Count)",
        "Standalone fonts: $($Fonts.Count)",
        "PBIX bytes: $($Pbix.Length)",
        "PBIX SHA-256: $PbixHash",
        '',
        'Candidate defect established: False',
        'D:\x\m mutation: NONE',
        'Git mutation: NONE',
        'Publication: NOT PERFORMED',
        '',
        "Receipt: $JsonPath"
    )

    $Summary |
        Set-Content -LiteralPath $TxtPath -Encoding UTF8

    Write-Host ""
    $Summary | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Stop here and return the JSON receipt and console summary."
}
```

What I expect is:

```text
PHASE_C_R6_STAGING = PASS

Public release validation PASS
Governed manifest files: 2880

rc1 candidate overlay validation PASS
Governed candidate files: 235

rc2 candidate overlay validation PASS
Governed candidate files: 248
```

This distinction is worth retaining in the evidence because it explains the apparent discrepancy rather than hiding it.

Once that returns PASS, **Phase C will finally be closed**, and only then will I give you the deterministic staging-to-`D:\x\m` synchronization block. We still will not commit or tag at that point.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1cd5fcdc-1814-4175-bcdd-9f72cb229f8d"></a>
## Andrew / user · C123-M00063

C123-M00063 · 2026-09-10T08:20:04.682000-04:00 · active path

Preceding visible parent: [C123-M00062](part-05.md#m-f05426f1-17bb-4c6a-a78b-01076c3f3d52)

**Editorial record note:** Attachment references: MSBF_PHASE_C_FINAL_SUMMARY.txt; MSBF_PHASE_C_R6_STAGING_VALIDATION_FINAL.json; OVERLAY_VALIDATOR_RAW_OUTPUT_RETRY1.txt

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE C — FINAL VALIDATION COMPLETION
============================================================
Staging:  D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94
Evidence: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_20260910T121241797Z_028c5f94


PHASE_C_R6_STAGING = PASS
R6 SHA-256: 31611a7c90ad7a0b597ecc3c0a5592c2aa7c031a82b5c7fbcc40750c8e8d0bf2
Staging root: D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94
Extracted files: 2884

Public release validation PASS
Governed manifest files: 2880
Module 2 stage folders: 12

rc1 candidate overlay validation PASS
Governed candidate files: 235

rc2 candidate overlay validation PASS
Governed candidate files: 248

Private R22 payload files: 0
Forbidden private/raw carriers: 0
Standalone fonts: 0
PBIX bytes: 27635305
PBIX SHA-256: ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4

Candidate defect established: False
D:\x\m mutation: NONE
Git mutation: NONE
Publication: NOT PERFORMED

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_20260910T121241797Z_028c5f94\MSBF_PHASE_C_R6_STAGING_VALIDATION_FINAL.json

Stop here and return the JSON receipt and console summary.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cdf4dc43-26e7-4e52-a719-a5bf2cfed442"></a>
## Assistant · C123-M00064

C123-M00064 · 2026-09-10T08:20:09.587149-04:00 · active path

Preceding visible parent: [C123-M00063](part-05.md#m-1cd5fcdc-1814-4175-bcdd-9f72cb229f8d)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase C is now closed with a clean PASS.** The physical receipt records R6 at the expected SHA-256, all **2,884 extracted files**, the root validator at **2,880 governed files**, rc1 at **235**, rc2 at **248**, the accepted PBIX identity, zero private R22 payload files, zero forbidden private carriers, and zero standalone fonts. It also records that neither `D:\x\m` nor Git was mutated. [export reference: filecite | turn23file0 | L1-L20] [export reference: filecite | turn23file1 | L43-L54]

The two failed wrapper attempts are now properly characterized as tooling defects rather than candidate defects. The final receipt explicitly records `CandidateDefectEstablished: false`. [export reference: filecite | turn23file1 | L6-L14]

We can record:

```text
PHASE_C_R6_STAGING = PASS
R6_DEFECT = FALSE
R20 staging/validator gate = PASS
```

## Phase D — safely materialize R6 into `D:\x\m`

This is the **first step that will modify the checkout**, but it will not commit, tag, push, or publish anything.

The block below is designed to fail closed. Before copying, it rechecks the repository, branch, HEAD, cleanliness, **untracked files and ignored local-only files**, and the staging population. If it discovers local material that a mirror could delete, it stops before mutation.

If the checkout is safe, it:

1. records a complete pre-apply file inventory;
2. mirrors the already validated R6 staging tree into `D:\x\m` while explicitly preserving `.git`;
3. captures `git status`, `git diff --stat`, and `git diff --name-status`;
4. compares **every non-`.git` file path, size, and SHA-256** against R6 staging;
5. refuses to advance unless the checkout is exactly equal to R6.

Use the **same PowerShell window** and paste this entire block:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'
    $Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'

    $ExpectedHead = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'
    $ExpectedR6Files = 2884

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)

    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_D_${Stamp}_${Suffix}"
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE D — CONTROLLED R6 CHECKOUT MATERIALIZATION"
    Write-Host "============================================================"
    Write-Host "Validated source: $Stage"
    Write-Host "Target checkout:  $Repo"
    Write-Host "Evidence:         $EvidenceDir"
    Write-Host ""

    # =========================================================
    # A. HARD PRE-MUTATION CHECKS
    # =========================================================

    foreach ($requiredDir in @($Repo,$Stage)) {
        if (-not (Test-Path -LiteralPath $requiredDir -PathType Container)) {
            throw "Required directory missing: $requiredDir"
        }
    }

    if (-not (Test-Path -LiteralPath (Join-Path $Repo '.git') -PathType Container)) {
        throw "Target does not contain expected .git directory: $Repo"
    }

    $RepoRoot = (& git -C $Repo rev-parse --show-toplevel).Trim()
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to resolve target Git root."
    }

    if (
        ([IO.Path]::GetFullPath($RepoRoot).TrimEnd('\')) -ine
        ([IO.Path]::GetFullPath($Repo).TrimEnd('\'))
    ) {
        throw "Unexpected Git root. Expected $Repo ; actual $RepoRoot"
    }

    $Branch = (& git -C $Repo branch --show-current).Trim()

    if ($Branch -cne 'main') {
        throw "Expected branch main; actual: $Branch"
    }

    $Head = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()

    if ($Head -cne $ExpectedHead) {
        throw "HEAD changed since Phase B. Expected $ExpectedHead ; actual $Head"
    }

    $Porcelain = @(& git -C $Repo status --porcelain=v1)

    if ($LASTEXITCODE -ne 0) {
        throw "git status failed."
    }

    if ($Porcelain.Count -gt 0) {
        throw "Working tree is no longer clean. Stop before materialization.`n$($Porcelain -join "`n")"
    }

    # Untracked files should already be absent from porcelain, but make
    # this explicit.
    $Untracked = @(& git -C $Repo ls-files --others --exclude-standard)

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inventory untracked files."
    }

    if ($Untracked.Count -gt 0) {
        throw "Untracked files exist and could be affected by mirror operation:`n$($Untracked -join "`n")"
    }

    # Critical extra protection: ordinary git status does not show
    # ignored local-only content by default.
    $Ignored = @(& git -C $Repo ls-files --others --ignored --exclude-standard)

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inventory ignored local-only files."
    }

    if ($Ignored.Count -gt 0) {
        $IgnoredPath = Join-Path $EvidenceDir 'IGNORED_LOCAL_ONLY_FILES.txt'
        $Ignored | Set-Content -LiteralPath $IgnoredPath -Encoding UTF8

        throw @"
Ignored local-only files exist in D:\x\m.
A mirror could remove them, so Phase D is stopping BEFORE mutation.
Inventory saved to:
$IgnoredPath
"@
    }

    # Stage itself must have exactly the already accepted population.
    $StageFiles = @(
        Get-ChildItem -LiteralPath $Stage -Recurse -File -Force
    )

    if ($StageFiles.Count -ne $ExpectedR6Files) {
        throw "Staging population changed. Expected $ExpectedR6Files ; actual $($StageFiles.Count)"
    }

    # =========================================================
    # B. PRE-APPLY INVENTORY
    # =========================================================

    function Get-TreeInventory {
        param(
            [Parameter(Mandatory=$true)][string]$Root,
            [switch]$ExcludeGit
        )

        $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'

        $files = Get-ChildItem -LiteralPath $Root -Recurse -File -Force

        if ($ExcludeGit) {
            $gitPrefix = [IO.Path]::GetFullPath((Join-Path $Root '.git')).TrimEnd('\') + '\'

            $files = @(
                $files | Where-Object {
                    -not $_.FullName.StartsWith(
                        $gitPrefix,
                        [StringComparison]::OrdinalIgnoreCase
                    )
                }
            )
        }

        foreach ($f in $files) {
            $relative = $f.FullName.Substring($rootFull.Length).Replace('\','/')

            [pscustomobject]@{
                Path   = $relative
                Bytes  = [int64]$f.Length
                Sha256 = (
                    Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }
        }
    }

    Write-Host "Hashing pre-apply checkout inventory..."
    $RepoBefore = @(Get-TreeInventory -Root $Repo -ExcludeGit)

    $RepoBefore |
        Sort-Object Path |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'CHECKOUT_PRE_APPLY_INVENTORY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Host "Hashing validated R6 staging inventory..."
    $StageInventory = @(Get-TreeInventory -Root $Stage)

    if ($StageInventory.Count -ne $ExpectedR6Files) {
        throw "Hashed stage inventory count mismatch."
    }

    $StageInventory |
        Sort-Object Path |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'R6_STAGE_INVENTORY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # =========================================================
    # C. DRY-RUN MIRROR PREVIEW
    # =========================================================

    $DryRunLog = Join-Path $EvidenceDir 'ROBOCOPY_DRY_RUN.txt'

    $DryArgs = @(
        $Stage,
        $Repo,
        '/MIR',
        '/COPY:DAT',
        '/DCOPY:DAT',
        '/R:0',
        '/W:0',
        '/XJ',
        '/XD', '.git',
        '/L',
        '/FP',
        '/BYTES',
        '/NJH',
        '/NJS',
        '/NP'
    )

    & robocopy @DryArgs 2>&1 |
        Tee-Object -FilePath $DryRunLog |
        Out-Host

    $DryCode = $LASTEXITCODE

    # Robocopy 0-7 are nonfatal informational/success states.
    if ($DryCode -ge 8) {
        throw "Robocopy dry run failed with exit code $DryCode."
    }

    Write-Host ""
    Write-Host "Dry-run mirror completed. No mutation yet."
    Write-Host "Proceeding because checkout is clean and contains no ignored/untracked local files."
    Write-Host ""

    # =========================================================
    # D. ACTUAL MIRROR — PRESERVE .git
    # =========================================================

    $ApplyLog = Join-Path $EvidenceDir 'ROBOCOPY_APPLY.txt'

    $ApplyArgs = @(
        $Stage,
        $Repo,
        '/MIR',
        '/COPY:DAT',
        '/DCOPY:DAT',
        '/R:1',
        '/W:1',
        '/XJ',
        '/XD', '.git',
        '/FP',
        '/BYTES',
        '/TEE',
        "/LOG:$ApplyLog"
    )

    & robocopy @ApplyArgs
    $ApplyCode = $LASTEXITCODE

    if ($ApplyCode -ge 8) {
        throw "Robocopy materialization failed with exit code $ApplyCode. STOP. Do not commit."
    }

    # =========================================================
    # E. IMMEDIATE GIT EVIDENCE
    # =========================================================

    $StatusShort = @(& git -C $Repo status --short)
    if ($LASTEXITCODE -ne 0) {
        throw "git status failed after materialization."
    }

    $StatusBranch = @(& git -C $Repo status --short --branch)
    $DiffStat = @(& git -C $Repo diff --stat)
    $DiffNameStatus = @(& git -C $Repo diff --name-status)

    $StatusShort |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GIT_STATUS_SHORT.txt') `
            -Encoding UTF8

    $StatusBranch |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GIT_STATUS_SHORT_BRANCH.txt') `
            -Encoding UTF8

    $DiffStat |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GIT_DIFF_STAT.txt') `
            -Encoding UTF8

    $DiffNameStatus |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GIT_DIFF_NAME_STATUS.txt') `
            -Encoding UTF8

    # HEAD and historical tag must remain untouched.
    $HeadAfter = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()

    if ($HeadAfter -cne $ExpectedHead) {
        throw "HEAD changed unexpectedly during file materialization."
    }

    # =========================================================
    # F. EXACT FILE-TREE EQUALITY: R6 STAGE == CHECKOUT
    # =========================================================

    Write-Host ""
    Write-Host "Hashing post-apply checkout for exact R6 equality..."
    $RepoAfter = @(Get-TreeInventory -Root $Repo -ExcludeGit)

    $RepoAfter |
        Sort-Object Path |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'CHECKOUT_POST_APPLY_INVENTORY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $StageMap = @{}
    foreach ($r in $StageInventory) {
        $StageMap[$r.Path.ToLowerInvariant()] = $r
    }

    $RepoMap = @{}
    foreach ($r in $RepoAfter) {
        $RepoMap[$r.Path.ToLowerInvariant()] = $r
    }

    $Missing = New-Object System.Collections.Generic.List[string]
    $Extra = New-Object System.Collections.Generic.List[string]
    $Mismatch = New-Object System.Collections.Generic.List[object]

    foreach ($k in $StageMap.Keys) {
        if (-not $RepoMap.ContainsKey($k)) {
            $Missing.Add($StageMap[$k].Path)
            continue
        }

        $s = $StageMap[$k]
        $r = $RepoMap[$k]

        if (
            $s.Path -cne $r.Path -or
            $s.Bytes -ne $r.Bytes -or
            $s.Sha256 -cne $r.Sha256
        ) {
            $Mismatch.Add(
                [pscustomobject]@{
                    StagePath = $s.Path
                    RepoPath = $r.Path
                    StageBytes = $s.Bytes
                    RepoBytes = $r.Bytes
                    StageSha256 = $s.Sha256
                    RepoSha256 = $r.Sha256
                }
            )
        }
    }

    foreach ($k in $RepoMap.Keys) {
        if (-not $StageMap.ContainsKey($k)) {
            $Extra.Add($RepoMap[$k].Path)
        }
    }

    $Missing |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'TREE_MISSING_FROM_CHECKOUT.txt') `
            -Encoding UTF8

    $Extra |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'TREE_EXTRA_IN_CHECKOUT.txt') `
            -Encoding UTF8

    $Mismatch |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'TREE_HASH_MISMATCHES.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    if ($RepoAfter.Count -ne $ExpectedR6Files) {
        throw "Checkout file population differs from R6. Expected $ExpectedR6Files ; actual $($RepoAfter.Count)"
    }

    if ($Missing.Count -gt 0) {
        throw "Checkout is missing $($Missing.Count) R6 files."
    }

    if ($Extra.Count -gt 0) {
        throw "Checkout contains $($Extra.Count) files not present in R6."
    }

    if ($Mismatch.Count -gt 0) {
        throw "Checkout has $($Mismatch.Count) path/size/hash mismatches versus R6."
    }

    # =========================================================
    # G. RECEIPT
    # =========================================================

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_D_CHECKOUT_MATERIALIZATION'
        GoverningDecision = 'IA-D-R20-INT-001'
        ConditionalAuthority = 'IA-PUB-R20-INTEGRATED-001'

        SourceStage = $Stage
        TargetCheckout = $Repo
        EvidenceDirectory = $EvidenceDir

        Branch = $Branch
        HeadBefore = $Head
        HeadAfter = $HeadAfter

        PreApplyWorkingTreeClean = $true
        PreApplyUntrackedFiles = 0
        PreApplyIgnoredLocalOnlyFiles = 0

        RobocopyDryRunExitCode = $DryCode
        RobocopyApplyExitCode = $ApplyCode

        ExpectedR6Files = $ExpectedR6Files
        StageFiles = $StageInventory.Count
        CheckoutFilesAfter = $RepoAfter.Count

        MissingFromCheckout = $Missing.Count
        ExtraInCheckout = $Extra.Count
        PathSizeHashMismatches = $Mismatch.Count

        GitStatusShort = @($StatusShort)
        GitDiffStat = @($DiffStat)
        GitDiffNameStatus = @($DiffNameStatus)

        CommitPerformed = $false
        TagPerformed = $false
        PushPerformed = $false
        PublicationPerformed = $false

        PhaseDStatus = 'PASS'
    }

    $JsonPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_D_CHECKOUT_MATERIALIZATION.json'

    $TxtPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_D_SUMMARY.txt'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $JsonPath -Encoding UTF8

    $Summary = @(
        'PHASE_D_CHECKOUT_MATERIALIZATION = PASS',
        "Repository: $Repo",
        "Source staging: $Stage",
        "Branch: $Branch",
        "HEAD unchanged: $HeadAfter",
        '',
        "R6 staging files: $($StageInventory.Count)",
        "Checkout files: $($RepoAfter.Count)",
        "Missing: $($Missing.Count)",
        "Extra: $($Extra.Count)",
        "Path/size/hash mismatches: $($Mismatch.Count)",
        '',
        "Git changed paths: $($StatusShort.Count)",
        '',
        'No commit performed.',
        'No tag created.',
        'No push performed.',
        'No publication performed.',
        '',
        "Receipt: $JsonPath"
    )

    $Summary |
        Set-Content -LiteralPath $TxtPath -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    $Summary | ForEach-Object { Write-Host $_ }
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "git status --short:"
    $StatusShort | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "git diff --stat:"
    $DiffStat | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Stop here. Do NOT stage or commit yet."
    Write-Host "Return the JSON receipt and console summary."
}
```

### One potentially important stop condition

If this stops because it finds **ignored local-only files**, that is intentional. `git status` being clean does **not** prove there are no ignored items, and `/MIR` could otherwise remove them.

If that happens, **do not delete those files and do not rerun with the protection removed**. Send me the resulting list and I'll classify them against R6.

### Expected successful end state

We want:

```text
PHASE_D_CHECKOUT_MATERIALIZATION = PASS

R6 staging files: 2884
Checkout files: 2884
Missing: 0
Extra: 0
Path/size/hash mismatches: 0

HEAD unchanged:
46fb1f9198475678edc9cabdeefd2f91a59e49c2
```

The working tree is **expected to become dirty** here because R6 is being materialized over the public predecessor. That is not a failure. What matters is that its complete non-`.git` tree becomes exactly R6.

Do **not** run `git add`, commit, or create the tag afterward, even if Phase D passes. The next step is **Phase E**, where we'll validate the actual `D:\x\m` working tree—including manifests, public/private boundaries, PBIX/DataModel/protected payloads, documentation routes, line-ending behavior, and the exact Git change set—before anything is staged.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6722514a-701a-4117-a0a2-07cdba8d3582"></a>
## Andrew / user · C123-M00065

C123-M00065 · 2026-09-10T08:27:14.431000-04:00 · active path

Preceding visible parent: [C123-M00064](part-05.md#m-cdf4dc43-26e7-4e52-a719-a5bf2cfed442)

**Editorial record note:** Attachment references: GIT_DIFF_NAME_STATUS(1).txt; GIT_DIFF_STAT(1).txt; GIT_STATUS_SHORT(1).txt; GIT_STATUS_SHORT_BRANCH(1).txt; MSBF_PHASE_D_CHECKOUT_MATERIALIZATION(1).json; MSBF_PHASE_D_SUMMARY(1).txt; R6_STAGE_INVENTORY(1).csv; ROBOCOPY_APPLY(1).txt; ROBOCOPY_DRY_RUN(1).txt; CHECKOUT_POST_APPLY_INVENTORY(1).csv; CHECKOUT_PRE_APPLY_INVENTORY(1).csv

<!-- BEGIN_SOURCE_MESSAGE -->
------------------------------------------------------------------------------

               Total    Copied   Skipped  Mismatch    FAILED    Extras
    Dirs :       772       436       336         0         0         1
   Files :      2884      2884         0         0         0         0
   Bytes : 353094115 353094115         0         0         0         0
   Times :   0:00:42   0:00:03                       0:00:00   0:00:39


   Speed :            89255337 Bytes/sec.
   Speed :            5107.231 MegaBytes/min.
   Ended : Thursday, September 10, 2026 8:23:24 AM

Refresh index: 100% (1934/1934), done.

Hashing post-apply checkout for exact R6 equality...

============================================================
PHASE_D_CHECKOUT_MATERIALIZATION = PASS
Repository: D:\x\m
Source staging: D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94
Branch: main
HEAD unchanged: 46fb1f9198475678edc9cabdeefd2f91a59e49c2

R6 staging files: 2884
Checkout files: 2884
Missing: 0
Extra: 0
Path/size/hash mismatches: 0

Git changed paths: 29

No commit performed.
No tag created.
No push performed.
No publication performed.

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_D_20260910T122211251Z_abd96b08\MSBF_PHASE_D_CHECKOUT_MATERIALIZATION.json
============================================================

git status --short:
 M CHANGELOG.md
 M GITHUB_PUBLICATION_GUIDE.md
 M GOVERNANCE_AND_VALIDATION.md
 M MANIFEST.csv
 M MODULE_AND_RELEASE_INDEX.md
 M PACKAGE_INVENTORY.csv
 M PROJECT_ARTIFACT_MAP.md
 M PROJECT_ROADMAP.md
 M README.md
 M RELEASE_NOTES.md
 M REPRODUCIBILITY_AND_EXECUTION.md
 M SHA256SUMS.txt
 M docs/README.md
 M docs/project_history/README.md
 M manifest.json
 M release_metadata.json
?? CANDIDATE_RELEASES.md
?? R23_OVERLAY_DIFF_INDEX.csv
?? R23_OVERLAY_METADATA.json
?? docs/cohort/
?? docs/guide/
?? docs/portfolio_visuals/
?? docs/power_bi/
?? docs/project_history/chatgpt_logs_through_2026-09-09/
?? docs/project_history/preaudit/
?? docs/release_change_control/
?? docs/release_integration/
?? docs/reproducibility/
?? successor_candidates/

git diff --stat:
 CHANGELOG.md                     |    23 +
 GITHUB_PUBLICATION_GUIDE.md      |     8 +
 GOVERNANCE_AND_VALIDATION.md     |     8 +
 MANIFEST.csv                     |  1890 +++--
 MODULE_AND_RELEASE_INDEX.md      |    20 +
 PACKAGE_INVENTORY.csv            |  4812 ++++++-----
 PROJECT_ARTIFACT_MAP.md          |     8 +
 PROJECT_ROADMAP.md               |     8 +
 README.md                        |   629 +-
 RELEASE_NOTES.md                 |     8 +
 REPRODUCIBILITY_AND_EXECUTION.md |     8 +
 SHA256SUMS.txt                   |  1890 +++--
 docs/README.md                   |   151 +-
 docs/project_history/README.md   |     4 +
 manifest.json                    | 16314 ++++++++++++++++++++++++-------------
 release_metadata.json            |    40 +-
 16 files changed, 16564 insertions(+), 9257 deletions(-)

Stop here. Do NOT stage or commit yet.
Return the JSON receipt and console summary.
<!-- END_SOURCE_MESSAGE -->
