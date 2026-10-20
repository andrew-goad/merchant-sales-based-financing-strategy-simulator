# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 06 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-05.md)
[Next part](part-07.md)

<a id="m-7b70860b-3e3d-4dd5-aabf-280e2aa1ad1d"></a>
## Assistant · C123-M00066

C123-M00066 · 2026-09-10T08:27:17.752089-04:00 · active path

Preceding visible parent: [C123-M00065](part-05.md#m-6722514a-701a-4117-a0a2-07cdba8d3582)

<!-- BEGIN_SOURCE_MESSAGE -->
Phase D is **cleanly closed as PASS**. The receipt confirms that `D:\x\m` now contains exactly the R6 publication tree: **2,884 files on each side, 0 missing, 0 extra, and 0 path/size/SHA mismatches**, while `HEAD` remains the Phase-B predecessor commit `46fb1f...`. No commit, tag, push, or publication occurred. [export reference: filecite | turn24file4 | L6-L22] [export reference: filecite | turn24file5 | L1-L18]

The reported 29 Git-status entries are also consistent with the intended R6 integration: 16 existing tracked files are modified and the remaining status entries are new R6 publication surfaces such as the guide, Power BI, visual, history, release-integration, reproducibility, and successor-candidate trees. [export reference: filecite | turn24file2 | L1-L29] The relatively large textual diff is concentrated where expected—particularly the governed manifests/inventories plus the rebuilt README/documentation surfaces—not evidence by itself of a mass technical rewrite. [export reference: filecite | turn24file1 | L1-L17]

The Robocopy exit code of `3` is nonfatal here: the receipt records both dry-run and application code 3, followed by exact post-copy equality. The one directory reported as an "extra" during Robocopy is consistent with `.git`, which was explicitly excluded from the mirror; the final tree comparison excluded `.git` and found **zero actual R6-tree extras**. [export reference: filecite | turn24file4 | L15-L22]

We now advance to **Phase E — PRE-COMMIT PUBLICATION GATE**. This phase is read-only with respect to repository content. It will write evidence **outside** `D:\x\m`, but it will not stage, commit, tag, push, resave PBIX, or publish anything.

Paste this complete block into the **same PowerShell**:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    # ============================================================
    # MSBF PHASE E — PRE-COMMIT PUBLICATION GATE
    # READ-ONLY AGAINST REPOSITORY CONTENT
    # ============================================================

    $Repo  = 'D:\x\m'
    $Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'

    $ExpectedHead = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'
    $ExpectedFiles = 2884

    $ExpectedPbixBytes = 27635305
    $ExpectedPbixSha = 'ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4'
    $ExpectedDataModelSha = '24396d02c0fbcb782cc9918e842886711146b8ff9455c8822d2aeaf009b96061'

    $PbixRel = 'docs\power_bi\m2_v2_1\release\MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)

    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_${Stamp}_${Suffix}"
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE E — PRE-COMMIT PUBLICATION GATE"
    Write-Host "============================================================"
    Write-Host "Repository: $Repo"
    Write-Host "R6 stage:   $Stage"
    Write-Host "Evidence:   $EvidenceDir"
    Write-Host ""

    $Checks = New-Object System.Collections.Generic.List[object]

    function Add-Check {
        param(
            [string]$Name,
            [bool]$Pass,
            [string]$Actual,
            [string]$Expected
        )

        $Checks.Add([pscustomobject]@{
            Check    = $Name
            Expected = $Expected
            Actual   = $Actual
            Status   = $(if ($Pass) { 'PASS' } else { 'FAIL' })
        })
    }

    function Get-TreeInventory {
        param(
            [Parameter(Mandatory=$true)][string]$Root,
            [switch]$ExcludeGit
        )

        $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
        $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force)

        if ($ExcludeGit) {
            $gitPrefix = [IO.Path]::GetFullPath(
                (Join-Path $Root '.git')
            ).TrimEnd('\') + '\'

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

    function Test-HashList {
        param(
            [Parameter(Mandatory=$true)][string]$BaseDir,
            [Parameter(Mandatory=$true)][string]$HashFile,
            [Parameter(Mandatory=$true)][string]$Label
        )

        if (-not (Test-Path -LiteralPath $HashFile -PathType Leaf)) {
            Add-Check $Label $false 'HASH_FILE_MISSING' $HashFile
            return
        }

        $rows = New-Object System.Collections.Generic.List[object]
        $bad = 0
        $checked = 0

        foreach ($line in Get-Content -LiteralPath $HashFile) {
            $t = $line.Trim()

            if (
                [string]::IsNullOrWhiteSpace($t) -or
                $t.StartsWith('#')
            ) {
                continue
            }

            # Supports common:
            # <sha256><spaces>*relative/path
            if ($t -notmatch '^([0-9a-fA-F]{64})\s+\*?(.+)$') {
                continue
            }

            $expected = $Matches[1].ToLowerInvariant()
            $rel = $Matches[2].Trim().Replace('/','\')
            $path = Join-Path $BaseDir $rel

            $exists = Test-Path -LiteralPath $path -PathType Leaf
            $actual = $null
            $pass = $false

            if ($exists) {
                $actual = (
                    Get-FileHash -LiteralPath $path -Algorithm SHA256
                ).Hash.ToLowerInvariant()
                $pass = ($actual -ceq $expected)
            }

            if (-not $pass) { $bad++ }
            $checked++

            $rows.Add([pscustomobject]@{
                RelativePath = $rel
                Exists       = $exists
                ExpectedSha  = $expected
                ActualSha    = $actual
                Status       = $(if ($pass) { 'PASS' } else { 'FAIL' })
            })
        }

        $safeLabel = ($Label -replace '[^A-Za-z0-9_.-]','_')

        $rows |
            Export-Csv `
                -LiteralPath (Join-Path $EvidenceDir "${safeLabel}.csv") `
                -NoTypeInformation `
                -Encoding UTF8

        Add-Check `
            $Label `
            ($checked -gt 0 -and $bad -eq 0) `
            "Checked=$checked; Failed=$bad" `
            'Failed=0'
    }

    # ============================================================
    # A. BASE REPOSITORY / HEAD / BRANCH / NO-STAGING CHECKS
    # ============================================================

    $Root = (& git -C $Repo rev-parse --show-toplevel).Trim()
    $Branch = (& git -C $Repo branch --show-current).Trim()
    $Head = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()

    Add-Check 'REPOSITORY_ROOT' `
        ($Root -ceq 'D:/x/m') `
        $Root `
        'D:/x/m'

    Add-Check 'CURRENT_BRANCH' `
        ($Branch -ceq 'main') `
        $Branch `
        'main'

    Add-Check 'HEAD_UNCHANGED_FROM_PHASE_B' `
        ($Head -ceq $ExpectedHead) `
        $Head `
        $ExpectedHead

    $CachedNames = @(& git -C $Repo diff --cached --name-only)

    Add-Check 'INDEX_UNSTAGED' `
        ($CachedNames.Count -eq 0) `
        "CachedPaths=$($CachedNames.Count)" `
        'CachedPaths=0'

    # ============================================================
    # B. EXACT R6 CHECKOUT EQUALITY — FRESH HASH PASS
    # ============================================================

    Write-Host "Freshly hashing R6 stage..."
    $StageInv = @(Get-TreeInventory -Root $Stage)

    Write-Host "Freshly hashing actual checkout..."
    $RepoInv = @(Get-TreeInventory -Root $Repo -ExcludeGit)

    $StageInv |
        Sort-Object Path |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'R6_STAGE_FRESH_INVENTORY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $RepoInv |
        Sort-Object Path |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'CHECKOUT_FRESH_INVENTORY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $StageMap = @{}
    foreach ($x in $StageInv) {
        $StageMap[$x.Path.ToLowerInvariant()] = $x
    }

    $RepoMap = @{}
    foreach ($x in $RepoInv) {
        $RepoMap[$x.Path.ToLowerInvariant()] = $x
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
            $Mismatch.Add([pscustomobject]@{
                StagePath   = $s.Path
                RepoPath    = $r.Path
                StageBytes  = $s.Bytes
                RepoBytes   = $r.Bytes
                StageSha256 = $s.Sha256
                RepoSha256  = $r.Sha256
            })
        }
    }

    foreach ($k in $RepoMap.Keys) {
        if (-not $StageMap.ContainsKey($k)) {
            $Extra.Add($RepoMap[$k].Path)
        }
    }

    $Missing |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'R6_EQUALITY_MISSING.txt') `
            -Encoding UTF8

    $Extra |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'R6_EQUALITY_EXTRA.txt') `
            -Encoding UTF8

    $Mismatch |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'R6_EQUALITY_MISMATCH.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $TreeEqual = (
        $StageInv.Count -eq $ExpectedFiles -and
        $RepoInv.Count -eq $ExpectedFiles -and
        $Missing.Count -eq 0 -and
        $Extra.Count -eq 0 -and
        $Mismatch.Count -eq 0
    )

    Add-Check 'R6_FILE_TREE_EQUALITY' `
        $TreeEqual `
        "Stage=$($StageInv.Count); Checkout=$($RepoInv.Count); Missing=$($Missing.Count); Extra=$($Extra.Count); Mismatch=$($Mismatch.Count)" `
        "Stage=$ExpectedFiles; Checkout=$ExpectedFiles; Missing=0; Extra=0; Mismatch=0"

    # ============================================================
    # C. GOVERNING VALIDATORS — DO NOT MODIFY THEM
    # ============================================================

    $PythonCmd = Get-Command python -ErrorAction Stop

    function Invoke-Validator {
        param(
            [string]$Label,
            [string]$RelPath,
            [string]$ExpectedText1,
            [string]$ExpectedText2
        )

        $path = Join-Path $Repo $RelPath

        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            Add-Check $Label $false 'VALIDATOR_MISSING' $RelPath
            return
        }

        Push-Location $Repo
        try {
            $output = @(& $PythonCmd.Source $path 2>&1)
            $code = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $outPath = Join-Path $EvidenceDir "$Label.txt"
        $output | Set-Content -LiteralPath $outPath -Encoding UTF8

        $joined = $output -join "`n"

        $pass = (
            $code -eq 0 -and
            $joined.Contains($ExpectedText1) -and
            $joined.Contains($ExpectedText2)
        )

        Add-Check `
            $Label `
            $pass `
            "ExitCode=$code" `
            "ExitCode=0; $ExpectedText1; $ExpectedText2"
    }

    Invoke-Validator `
        'PUBLIC_RELEASE_VALIDATOR' `
        'tools\validate_public_release.py' `
        'Public release validation PASS' `
        'Governed manifest files: 2880'

    Invoke-Validator `
        'RC1_OVERLAY_VALIDATOR' `
        'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py' `
        'Candidate overlay validation PASS' `
        'Governed candidate files: 235'

    Invoke-Validator `
        'RC2_OVERLAY_VALIDATOR' `
        'successor_candidates\m2-g3-v2.1.0-rc2\tools\validate_candidate_overlay.py' `
        'Candidate overlay validation PASS' `
        'Governed candidate files: 248'

    # ============================================================
    # D. PBIX + EMBEDDED DATAMODEL EXACT IDENTITY
    # ============================================================

    $Pbix = Join-Path $Repo $PbixRel

    if (-not (Test-Path -LiteralPath $Pbix -PathType Leaf)) {
        Add-Check 'PBIX_EXISTS' $false 'MISSING' $PbixRel
    }
    else {
        $pbixItem = Get-Item -LiteralPath $Pbix
        $pbixHash = (
            Get-FileHash -LiteralPath $Pbix -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        Add-Check 'PBIX_BYTES' `
            ($pbixItem.Length -eq $ExpectedPbixBytes) `
            "$($pbixItem.Length)" `
            "$ExpectedPbixBytes"

        Add-Check 'PBIX_SHA256' `
            ($pbixHash -ceq $ExpectedPbixSha) `
            $pbixHash `
            $ExpectedPbixSha

        # Read embedded DataModel without extraction/resave/modification.
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        $zip = [System.IO.Compression.ZipFile]::OpenRead($Pbix)

        try {
            $dm = @(
                $zip.Entries |
                    Where-Object {
                        $_.FullName -eq 'DataModel' -or
                        $_.FullName -like '*/DataModel'
                    }
            )

            if ($dm.Count -ne 1) {
                Add-Check 'PBIX_DATAMODEL_MEMBER_COUNT' `
                    $false `
                    "$($dm.Count)" `
                    '1'
            }
            else {
                Add-Check 'PBIX_DATAMODEL_MEMBER_COUNT' `
                    $true `
                    '1' `
                    '1'

                $sha = [System.Security.Cryptography.SHA256]::Create()
                try {
                    $stream = $dm[0].Open()
                    try {
                        $bytes = $sha.ComputeHash($stream)
                        $dmHash = (
                            [BitConverter]::ToString($bytes).Replace('-','')
                        ).ToLowerInvariant()
                    }
                    finally {
                        $stream.Dispose()
                    }
                }
                finally {
                    $sha.Dispose()
                }

                Add-Check 'PBIX_DATAMODEL_SHA256' `
                    ($dmHash -ceq $ExpectedDataModelSha) `
                    $dmHash `
                    $ExpectedDataModelSha
            }
        }
        finally {
            $zip.Dispose()
        }
    }

    # ============================================================
    # E. NESTED PROTECTED HASH CONTROLS
    # ============================================================

    Test-HashList `
        -BaseDir (Join-Path $Repo 'docs\power_bi\m2_v2_1') `
        -HashFile (Join-Path $Repo 'docs\power_bi\m2_v2_1\manifests\SHA256SUMS.txt') `
        -Label 'POWER_BI_PROJECTION_SHA256SUMS'

    Test-HashList `
        -BaseDir (Join-Path $Repo 'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1') `
        -HashFile (Join-Path $Repo 'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\SHA256SUMS.txt') `
        -Label 'VISUAL_FAMILY_SHA256SUMS'

    Test-HashList `
        -BaseDir (Join-Path $Repo 'docs\reproducibility\m2_v2_1\runbook') `
        -HashFile (Join-Path $Repo 'docs\reproducibility\m2_v2_1\runbook\SHA256SUMS.txt') `
        -Label 'RUNBOOK_SHA256SUMS'

    Test-HashList `
        -BaseDir (Join-Path $Repo 'docs\project_history\chatgpt_logs_through_2026-09-09') `
        -HashFile (Join-Path $Repo 'docs\project_history\chatgpt_logs_through_2026-09-09\SHA256SUMS.txt') `
        -Label 'FROZEN_HISTORY_SHA256SUMS'

    Test-HashList `
        -BaseDir (Join-Path $Repo 'docs\release_change_control\module_2_g3_v2_1') `
        -HashFile (Join-Path $Repo 'docs\release_change_control\module_2_g3_v2_1\PUBLIC_SHA256SUMS.txt') `
        -Label 'RELEASE_CHANGE_CONTROL_SHA256SUMS'

    # ============================================================
    # F. R22 EXCLUSION-PROVENANCE DERIVATION
    #
    # We do not guess the eleven paths. Derive path-like strings only
    # from exclusion/private/omission-related branches of the retained
    # R18 provenance JSON, then require exactly 11 unique candidates.
    # ============================================================

    $ProvPath = Join-Path $Repo `
        'docs\release_integration\module_2_g3_v2_1\R18_PUBLIC_PROJECTION_PROVENANCE.json'

    $ExcludedCandidates = New-Object System.Collections.Generic.List[string]

    function Walk-Json {
        param(
            $Node,
            [string]$Context = ''
        )

        if ($null -eq $Node) { return }

        if ($Node -is [string]) {
            if (
                $Context -match '(?i)(exclude|excluded|private|omit|omission|removed|r22)' -and
                $Node -match '[\\/]' -and
                $Node -notmatch '^(https?|file):'
            ) {
                $ExcludedCandidates.Add($Node.Trim())
            }
            return
        }

        if ($Node -is [System.Collections.IEnumerable] -and
            -not ($Node -is [System.Management.Automation.PSCustomObject])) {

            foreach ($item in $Node) {
                Walk-Json -Node $item -Context $Context
            }
            return
        }

        foreach ($p in $Node.PSObject.Properties) {
            $next = if ($Context) {
                "$Context.$($p.Name)"
            }
            else {
                $p.Name
            }

            Walk-Json -Node $p.Value -Context $next
        }
    }

    if (-not (Test-Path -LiteralPath $ProvPath -PathType Leaf)) {
        Add-Check 'R22_EXCLUSION_PROVENANCE_EXISTS' `
            $false `
            'MISSING' `
            $ProvPath
    }
    else {
        Add-Check 'R22_EXCLUSION_PROVENANCE_EXISTS' `
            $true `
            'PRESENT' `
            'PRESENT'

        $prov = Get-Content -LiteralPath $ProvPath -Raw | ConvertFrom-Json
        Walk-Json -Node $prov

        $ExcludedUnique = @(
            $ExcludedCandidates |
                ForEach-Object {
                    $_.Replace('/','\').TrimStart('.\')
                } |
                Sort-Object -Unique
        )

        $ExcludedUnique |
            Set-Content `
                -LiteralPath (Join-Path $EvidenceDir 'R22_DERIVED_EXCLUDED_PATHS.txt') `
                -Encoding UTF8

        Add-Check 'R22_DERIVED_EXCLUDED_PATH_COUNT' `
            ($ExcludedUnique.Count -eq 11) `
            "$($ExcludedUnique.Count)" `
            '11'

        $PresentExcluded = New-Object System.Collections.Generic.List[string]

        foreach ($rel in $ExcludedUnique) {
            $candidate = Join-Path $Repo $rel
            if (Test-Path -LiteralPath $candidate) {
                $PresentExcluded.Add($rel)
            }
        }

        $PresentExcluded |
            Set-Content `
                -LiteralPath (Join-Path $EvidenceDir 'R22_EXCLUDED_PATHS_PRESENT.txt') `
                -Encoding UTF8

        Add-Check 'R22_EXCLUDED_PATHS_ABSENT' `
            (
                $ExcludedUnique.Count -eq 11 -and
                $PresentExcluded.Count -eq 0
            ) `
            "Derived=$($ExcludedUnique.Count); Present=$($PresentExcluded.Count)" `
            'Derived=11; Present=0'
    }

    # ============================================================
    # G. FORBIDDEN CARRIERS / STANDALONE FONT / ARCHIVE CHECK
    # ============================================================

    $AllRepoFiles = @(
        Get-ChildItem -LiteralPath $Repo -Recurse -File -Force |
        Where-Object {
            $_.FullName -notlike "$Repo\.git\*"
        }
    )

    $StandaloneFonts = @(
        $AllRepoFiles |
        Where-Object {
            $_.Extension -match '^\.(ttf|otf|woff|woff2|eot)$'
        }
    )

    Add-Check 'STANDALONE_FONT_FILES' `
        ($StandaloneFonts.Count -eq 0) `
        "$($StandaloneFonts.Count)" `
        '0'

    $RepoZipFiles = @(
        $AllRepoFiles |
        Where-Object { $_.Extension -ieq '.zip' }
    )

    $RepoZipFiles.FullName |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'REPOSITORY_ZIP_FILES.txt') `
            -Encoding UTF8

    # Forbidden/private carrier naming screen.
    $ForbiddenCarrierPattern = '(?i)(private.*(audit|evidence|control|history)|desktop.*evidence|route.?b.*checkpoint|raw.*chat|editorial.*control|audit.*return|private.*cohort.*source|source.*repro.*carrier)'

    $ForbiddenNamed = @(
        $AllRepoFiles |
        Where-Object {
            $_.Name -match $ForbiddenCarrierPattern -or
            $_.FullName -match $ForbiddenCarrierPattern
        }
    )

    $ForbiddenNamed.FullName |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'FORBIDDEN_NAMED_CARRIERS.txt') `
            -Encoding UTF8

    Add-Check 'FORBIDDEN_PRIVATE_RAW_CARRIERS' `
        ($ForbiddenNamed.Count -eq 0) `
        "$($ForbiddenNamed.Count)" `
        '0'

    # ============================================================
    # H. TARGETED CREDENTIAL / SECRET SCAN
    #
    # Do not print secret values. Evidence records only path + rule.
    # ============================================================

    $TextExtensions = @(
        '.md','.txt','.json','.jsonl','.csv','.yml','.yaml',
        '.py','.sql','.ps1','.html','.xml','.toml','.ini','.cfg',
        '.properties','.env'
    )

    $SecretRules = [ordered]@{
        'GITHUB_CLASSIC_PAT' = 'ghp_[A-Za-z0-9]{30,}'
        'GITHUB_FINE_GRAINED_PAT' = 'github_pat_[A-Za-z0-9_]{40,}'
        'AWS_ACCESS_KEY' = 'AKIA[0-9A-Z]{16}'
        'PRIVATE_KEY_BLOCK' = '-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----'
        'PASSWORD_ASSIGNMENT' = '(?i)(password|passwd|pwd)\s*[:=]\s*["''][^"'']{4,}["'']'
        'SECRET_ASSIGNMENT' = '(?i)(client_secret|api_secret|access_token)\s*[:=]\s*["''][^"'']{8,}["'']'
    }

    $SecretFindings = New-Object System.Collections.Generic.List[object]

    foreach ($f in $AllRepoFiles) {
        if ($TextExtensions -notcontains $f.Extension.ToLowerInvariant()) {
            continue
        }

        # Bound scanner; huge binary-like text should already be governed
        # by tree/hash validators.
        if ($f.Length -gt 10MB) {
            continue
        }

        try {
            $content = Get-Content -LiteralPath $f.FullName -Raw -ErrorAction Stop
        }
        catch {
            continue
        }

        foreach ($rule in $SecretRules.GetEnumerator()) {
            if ($content -match $rule.Value) {
                $rel = $f.FullName.Substring(
                    ([IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\').Length
                )

                $SecretFindings.Add([pscustomobject]@{
                    RelativePath = $rel
                    Rule = $rule.Key
                })
            }
        }
    }

    $SecretFindings |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'TARGETED_SECRET_SCAN_FINDINGS.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Add-Check 'TARGETED_SECRET_SCAN' `
        ($SecretFindings.Count -eq 0) `
        "$($SecretFindings.Count)" `
        '0'

    # ============================================================
    # I. DOCUMENTATION / RELATIVE-LINK CHECK
    # ============================================================

    $MarkdownFiles = @(
        Get-ChildItem -LiteralPath $Repo -Recurse -File -Filter '*.md' |
        Where-Object {
            $_.FullName -notlike "$Repo\.git\*"
        }
    )

    $BrokenLinks = New-Object System.Collections.Generic.List[object]

    foreach ($md in $MarkdownFiles) {
        $text = Get-Content -LiteralPath $md.FullName -Raw

        # Inline markdown links/images. Reference-style definitions
        # are handled separately below.
        $matches = [regex]::Matches(
            $text,
            '!?\[[^\]]*\]\(([^)]+)\)'
        )

        foreach ($m in $matches) {
            $target = $m.Groups[1].Value.Trim()

            # Strip optional title after URL/path conservatively.
            if ($target -match '^<(.+)>$') {
                $target = $Matches[1]
            }
            elseif ($target -match '^(\S+)\s+["''].*["'']$') {
                $target = $Matches[1]
            }

            if (
                [string]::IsNullOrWhiteSpace($target) -or
                $target.StartsWith('#') -or
                $target -match '^(?i)(https?|mailto|tel|data):'
            ) {
                continue
            }

            $pathPart = ($target -split '#',2)[0]
            $pathPart = [uri]::UnescapeDataString($pathPart)

            if ([string]::IsNullOrWhiteSpace($pathPart)) {
                continue
            }

            $resolved = Join-Path $md.DirectoryName $pathPart

            if (-not (Test-Path -LiteralPath $resolved)) {
                $relMd = $md.FullName.Substring(
                    ([IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\').Length
                )

                $BrokenLinks.Add([pscustomobject]@{
                    MarkdownFile = $relMd
                    Target = $target
                })
            }
        }

        # Reference-style definitions: [id]: relative/path
        $refMatches = [regex]::Matches(
            $text,
            '(?m)^\s*\[[^\]]+\]:\s*(\S+)'
        )

        foreach ($m in $refMatches) {
            $target = $m.Groups[1].Value.Trim('<','>')

            if (
                $target.StartsWith('#') -or
                $target -match '^(?i)(https?|mailto|tel|data):'
            ) {
                continue
            }

            $pathPart = ($target -split '#',2)[0]
            $pathPart = [uri]::UnescapeDataString($pathPart)

            if ([string]::IsNullOrWhiteSpace($pathPart)) {
                continue
            }

            $resolved = Join-Path $md.DirectoryName $pathPart

            if (-not (Test-Path -LiteralPath $resolved)) {
                $relMd = $md.FullName.Substring(
                    ([IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\').Length
                )

                $BrokenLinks.Add([pscustomobject]@{
                    MarkdownFile = $relMd
                    Target = $target
                })
            }
        }
    }

    $BrokenLinks |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'BROKEN_RELATIVE_MARKDOWN_LINKS.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Add-Check 'RELATIVE_MARKDOWN_LINKS' `
        ($BrokenLinks.Count -eq 0) `
        "$($BrokenLinks.Count)" `
        '0'

    # Explicit critical navigation surfaces.
    $CriticalPaths = [ordered]@{
        'ROOT_README' = 'README.md'
        'DOC_PORTAL' = 'docs\README.md'
        'CURRENT_USE_GUIDE' = 'docs\guide\CURRENT_USE.md'
        'EXPLAINABILITY_GUIDE' = 'docs\guide\EXPLAINABILITY.md'
        'LEARNING_GUIDE_ROUTE' = 'docs\guide\LEARNING.md'
        'VISUAL_GUIDE' = 'docs\guide\VISUALS.md'
        'REQUIREMENTS_VALIDATION_GUIDE' = 'docs\guide\REQUIREMENTS_AND_VALIDATION.md'
        'SOURCE_VERSION_GUIDE' = 'docs\guide\SOURCE_VERSIONS.md'
        'POWER_BI_ROUTE' = 'docs\power_bi\m2_v2_1\README.md'
        'COHORT_ROUTE' = 'docs\cohort\m2_v2_1\README.md'
        'VISUAL_PORTFOLIO' = 'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\README.md'
        'ENTERPRISE_ARCHITECTURE_ROUTE' = 'docs\enterprise_architecture\README.md'
        'MODULE1_LINEAGE_PNG' = 'docs\enterprise_architecture\Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage.png'
        'MODULE2_LINEAGE_PNG' = 'docs\enterprise_architecture\Module_2_Governed_Decisioning_Operations_Portfolio_&_G3_Acceptance_Lineage.png'
        'P03_082' = 'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_082_baseline.png'
        'P03_738_BASELINE' = 'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_738_baseline.png'
        'P03_738_RECESSION' = 'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_738_recession_energy.png'
        'P03_749' = 'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_749_baseline.png'
        'POSTER_HOW' = 'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\posters\MSBF_MCI_How_the_Governed_Decision_Engine_Works_v2_1_COPYFIX_R1.png'
        'POSTER_AFTER' = 'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\posters\MSBF_MCI_What_Happens_After_the_Decision_v2_1_COPYFIX_R1.png'
    }

    $CriticalMissing = New-Object System.Collections.Generic.List[object]

    foreach ($cp in $CriticalPaths.GetEnumerator()) {
        $full = Join-Path $Repo $cp.Value
        $exists = Test-Path -LiteralPath $full

        if (-not $exists) {
            $CriticalMissing.Add([pscustomobject]@{
                Route = $cp.Key
                RelativePath = $cp.Value
            })
        }
    }

    $CriticalMissing |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'CRITICAL_NAVIGATION_MISSING.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Add-Check 'CRITICAL_NAVIGATION_TARGETS' `
        ($CriticalMissing.Count -eq 0) `
        "$($CriticalMissing.Count)" `
        '0'

    # Stale local/session/temp links.
    $StaleLinkFindings = New-Object System.Collections.Generic.List[object]
    $StalePatterns = @(
        'localhost',
        '127\.0\.0\.1',
        'file:///',
        '[A-Za-z]:\\Users\\',
        '[session]/',
        'sandbox:/',
        'session[_-]',
        'temp[/\\]',
        'tmp[/\\]'
    )

    foreach ($md in $MarkdownFiles) {
        $text = Get-Content -LiteralPath $md.FullName -Raw

        foreach ($pattern in $StalePatterns) {
            if ($text -match $pattern) {
                $relMd = $md.FullName.Substring(
                    ([IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\').Length
                )

                $StaleLinkFindings.Add([pscustomobject]@{
                    RelativePath = $relMd
                    Pattern = $pattern
                })
            }
        }
    }

    $StaleLinkFindings |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'STALE_LOCAL_LINK_FINDINGS.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Add-Check 'STALE_LOCAL_TEMP_SESSION_LINKS' `
        ($StaleLinkFindings.Count -eq 0) `
        "$($StaleLinkFindings.Count)" `
        '0'

    # ============================================================
    # J. GIT DIFF / LINE ENDING / WHITESPACE / SIZE REVIEW
    # ============================================================

    $GitStatus = @(& git -C $Repo status --short)
    $GitStatusBranch = @(& git -C $Repo status --short --branch)
    $DiffStat = @(& git -C $Repo diff --stat)
    $DiffNameStatus = @(& git -C $Repo diff --name-status)
    $DiffNumStat = @(& git -C $Repo diff --numstat)
    $DiffCheck = @(& git -C $Repo diff --check)
    $DiffCheckCode = $LASTEXITCODE

    # Include untracked paths in a full candidate list.
    $TrackedChanged = @(& git -C $Repo diff --name-only)
    $UntrackedAll = @(& git -C $Repo ls-files --others --exclude-standard)

    $GitStatus |
        Set-Content -LiteralPath (Join-Path $EvidenceDir 'GIT_STATUS_SHORT.txt') -Encoding UTF8

    $GitStatusBranch |
        Set-Content -LiteralPath (Join-Path $EvidenceDir 'GIT_STATUS_SHORT_BRANCH.txt') -Encoding UTF8

    $DiffStat |
        Set-Content -LiteralPath (Join-Path $EvidenceDir 'GIT_DIFF_STAT.txt') -Encoding UTF8

    $DiffNameStatus |
        Set-Content -LiteralPath (Join-Path $EvidenceDir 'GIT_DIFF_NAME_STATUS.txt') -Encoding UTF8

    $DiffNumStat |
        Set-Content -LiteralPath (Join-Path $EvidenceDir 'GIT_DIFF_NUMSTAT.txt') -Encoding UTF8

    $DiffCheck |
        Set-Content -LiteralPath (Join-Path $EvidenceDir 'GIT_DIFF_CHECK.txt') -Encoding UTF8

    $UntrackedAll |
        Set-Content -LiteralPath (Join-Path $EvidenceDir 'GIT_UNTRACKED_ALL_FILES.txt') -Encoding UTF8

    Add-Check 'GIT_DIFF_CHECK' `
        ($DiffCheckCode -eq 0) `
        "ExitCode=$DiffCheckCode; Findings=$($DiffCheck.Count)" `
        'ExitCode=0; Findings=0'

    # Detect paths that disappear when ignoring end-of-line whitespace.
    # This is diagnostic rather than automatically fatal unless there is
    # evidence of broad line-ending-only churn.
    $NormalNames = @(& git -C $Repo diff --name-only)
    $IgnoreEolNames = @(& git -C $Repo diff --ignore-space-at-eol --name-only)

    $EolOnlyCandidates = @(
        $NormalNames |
        Where-Object { $_ -notin $IgnoreEolNames }
    )

    $EolOnlyCandidates |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'POSSIBLE_EOL_ONLY_CHANGED_PATHS.txt') `
            -Encoding UTF8

    # Fail closed only on mass EOL-only churn.
    $MassEolRewrite = ($EolOnlyCandidates.Count -ge 10)

    Add-Check 'NO_MASS_EOL_ONLY_REWRITE' `
        (-not $MassEolRewrite) `
        "PossibleEolOnlyPaths=$($EolOnlyCandidates.Count)" `
        '<10'

    # Unexpected very large untracked files: enumerate, but PBIX/visuals/
    # cohort are expected R6 members. Exact R6 equality is the primary
    # authorization for their presence.
    $LargeFiles = @(
        $AllRepoFiles |
        Where-Object { $_.Length -ge 25MB } |
        Sort-Object Length -Descending |
        ForEach-Object {
            [pscustomobject]@{
                Bytes = $_.Length
                RelativePath = $_.FullName.Substring(
                    ([IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\').Length
                )
            }
        }
    )

    $LargeFiles |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'FILES_GE_25MB.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ============================================================
    # K. ENSURE VALIDATION DID NOT MUTATE THE R6 TREE
    # ============================================================

    Write-Host "Re-hashing checkout after validators/scanners..."
    $RepoAfterValidation = @(Get-TreeInventory -Root $Repo -ExcludeGit)

    $AfterMap = @{}
    foreach ($x in $RepoAfterValidation) {
        $AfterMap[$x.Path.ToLowerInvariant()] = $x
    }

    $PostMutationMismatch = 0

    if ($AfterMap.Count -ne $StageMap.Count) {
        $PostMutationMismatch++
    }

    foreach ($k in $StageMap.Keys) {
        if (-not $AfterMap.ContainsKey($k)) {
            $PostMutationMismatch++
            continue
        }

        if (
            $StageMap[$k].Bytes -ne $AfterMap[$k].Bytes -or
            $StageMap[$k].Sha256 -cne $AfterMap[$k].Sha256 -or
            $StageMap[$k].Path -cne $AfterMap[$k].Path
        ) {
            $PostMutationMismatch++
        }
    }

    Add-Check 'VALIDATORS_LEFT_R6_TREE_UNCHANGED' `
        ($PostMutationMismatch -eq 0) `
        "$PostMutationMismatch" `
        '0'

    # ============================================================
    # L. FINAL INDEX / GIT SANITY
    # ============================================================

    $HeadFinal = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $CachedFinal = @(& git -C $Repo diff --cached --name-only)

    Add-Check 'HEAD_STILL_UNCHANGED' `
        ($HeadFinal -ceq $ExpectedHead) `
        $HeadFinal `
        $ExpectedHead

    Add-Check 'NOTHING_STAGED_AFTER_PHASE_E' `
        ($CachedFinal.Count -eq 0) `
        "CachedPaths=$($CachedFinal.Count)" `
        'CachedPaths=0'

    # ============================================================
    # M. FINAL HARD-GATE DECISION + RECEIPT
    # ============================================================

    $Checks |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'PHASE_E_CHECK_REGISTER.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $Failures = @($Checks | Where-Object { $_.Status -eq 'FAIL' })

    $PhaseStatus = if ($Failures.Count -eq 0) {
        'PASS'
    }
    else {
        'FAIL'
    }

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_E_PRE_COMMIT_GATE'
        GoverningDecision = 'IA-D-R20-INT-001'
        ConditionalAuthority = 'IA-PUB-R20-INTEGRATED-001'

        Repository = $Repo
        SourceR6Stage = $Stage
        EvidenceDirectory = $EvidenceDir

        Branch = $Branch
        Head = $HeadFinal

        R6Tree = [ordered]@{
            ExpectedFiles = $ExpectedFiles
            StageFiles = $StageInv.Count
            CheckoutFiles = $RepoInv.Count
            Missing = $Missing.Count
            Extra = $Extra.Count
            Mismatch = $Mismatch.Count
        }

        Validators = [ordered]@{
            PublicReleaseExpectedGovernedFiles = 2880
            Rc1ExpectedGovernedFiles = 235
            Rc2ExpectedGovernedFiles = 248
        }

        Pbix = [ordered]@{
            RelativePath = $PbixRel
            ExpectedBytes = $ExpectedPbixBytes
            ExpectedSha256 = $ExpectedPbixSha
            ExpectedDataModelSha256 = $ExpectedDataModelSha
        }

        R22DerivedExcludedPathCount = @($ExcludedUnique).Count
        R22ExcludedPathsPresent = @($PresentExcluded).Count

        SecretFindings = $SecretFindings.Count
        BrokenRelativeMarkdownLinks = $BrokenLinks.Count
        CriticalNavigationMissing = $CriticalMissing.Count
        StaleLocalLinkFindings = $StaleLinkFindings.Count
        PossibleEolOnlyChangedPaths = $EolOnlyCandidates.Count

        GitStatusEntryCount = $GitStatus.Count
        TrackedChangedPathCount = $TrackedChanged.Count
        UntrackedFileCount = $UntrackedAll.Count
        CachedPathCount = $CachedFinal.Count

        CheckCount = $Checks.Count
        FailureCount = $Failures.Count
        FailedChecks = @($Failures | Select-Object Check,Actual,Expected)

        CommitPerformed = $false
        TagPerformed = $false
        PushPerformed = $false
        PublicationPerformed = $false

        PreCommitGate = $PhaseStatus
    }

    $JsonPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_E_PRE_COMMIT_GATE.json'

    $Receipt |
        ConvertTo-Json -Depth 10 |
        Set-Content -LiteralPath $JsonPath -Encoding UTF8

    $SummaryPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_E_SUMMARY.txt'

    $Summary = @(
        "PRE_COMMIT_GATE = $PhaseStatus",
        "Repository: $Repo",
        "Branch: $Branch",
        "HEAD: $HeadFinal",
        '',
        "R6 tree: Stage=$($StageInv.Count) Checkout=$($RepoInv.Count) Missing=$($Missing.Count) Extra=$($Extra.Count) Mismatch=$($Mismatch.Count)",
        "Hard checks: $($Checks.Count)",
        "Failures: $($Failures.Count)",
        '',
        "R22 excluded paths derived: $(@($ExcludedUnique).Count)",
        "R22 excluded paths present: $(@($PresentExcluded).Count)",
        "Secret findings: $($SecretFindings.Count)",
        "Broken relative Markdown links: $($BrokenLinks.Count)",
        "Critical navigation targets missing: $($CriticalMissing.Count)",
        "Stale local/temp/session link findings: $($StaleLinkFindings.Count)",
        "Possible EOL-only changed paths: $($EolOnlyCandidates.Count)",
        '',
        "Git status entries: $($GitStatus.Count)",
        "Tracked changed paths: $($TrackedChanged.Count)",
        "Untracked files: $($UntrackedAll.Count)",
        "Cached/staged paths: $($CachedFinal.Count)",
        '',
        'No commit performed.',
        'No tag created.',
        'No push performed.',
        'No publication performed.',
        '',
        "Receipt: $JsonPath"
    )

    $Summary |
        Set-Content -LiteralPath $SummaryPath -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    $Summary | ForEach-Object { Write-Host $_ }
    Write-Host "============================================================"

    if ($Failures.Count -gt 0) {
        Write-Host ""
        Write-Host "FAILED CHECKS:"
        $Failures |
            Format-Table Check,Expected,Actual,Status -AutoSize |
            Out-Host

        Write-Host ""
        Write-Host "PHASE E FAILED CLOSED."
        Write-Host "Do NOT stage, commit, tag, push, or publish."
    }
    else {
        Write-Host ""
        Write-Host "PRE_COMMIT_GATE = PASS"
        Write-Host "Stop here. Do NOT stage or commit yet."
    }

    Write-Host ""
    Write-Host "Return the JSON receipt, console summary, and any failed-check evidence."
}
```

A few aspects of this gate are deliberately strict.

First, we **re-hash the full 2,884-file tree both before and after the validators**. That gives us direct evidence that none of the validation utilities altered the checkout. Second, the embedded `DataModel` is read directly from the PBIX archive stream—there is **no extraction to the repository, resave, or Power BI Desktop invocation**. Third, the R22 check attempts to derive the eleven excluded paths from the retained provenance record rather than inventing them. If that derivation does not yield exactly eleven, the gate will stop and we will inspect that one bounded issue rather than weakening the test.

The final outcome we want is approximately:

```text
PRE_COMMIT_GATE = PASS

R6 tree:
Stage=2884
Checkout=2884
Missing=0
Extra=0
Mismatch=0

Public validator: PASS / 2880
rc1 overlay: PASS / 235
rc2 overlay: PASS / 248

PBIX:
27635305 bytes
ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4

DataModel:
24396d02c0fbcb782cc9918e842886711146b8ff9455c8822d2aeaf009b96061

R22 excluded paths present: 0
Secret findings: 0
Broken relative Markdown links: 0
Critical navigation targets missing: 0

Cached/staged paths: 0
HEAD:
46fb1f9198475678edc9cabdeefd2f91a59e49c2
```

If Phase E passes, **still do not run `git add` afterward**. Send me the receipt. I will evaluate the actual check register and, only then, we move across the next mutation boundary into **Phase F — staged-content validation and commit binding**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e50ef3ae-2eff-46e2-a02c-6f67d3b3b994"></a>
## Andrew / user · C123-M00067

C123-M00067 · 2026-09-10T08:34:34.247000-04:00 · active path

Preceding visible parent: [C123-M00066](part-06.md#m-7b70860b-3e3d-4dd5-aabf-280e2aa1ad1d)

**Editorial record note:** Attachment references: MSBF_PHASE_E_PRE_COMMIT_GATE.json; MSBF_PHASE_E_SUMMARY.txt; R6_STAGE_FRESH_INVENTORY.csv; BROKEN_RELATIVE_MARKDOWN_LINKS.csv; CHECKOUT_FRESH_INVENTORY.csv; FROZEN_HISTORY_SHA256SUMS.csv; GIT_DIFF_CHECK.txt; GIT_UNTRACKED_ALL_FILES.txt

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE E — PRE-COMMIT PUBLICATION GATE
============================================================
Repository: D:\x\m
R6 stage:   D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_20260910T123054197Z_3a252164

Freshly hashing R6 stage...
Freshly hashing actual checkout...
Re-hashing checkout after validators/scanners...

============================================================
PRE_COMMIT_GATE = FAIL
Repository: D:\x\m
Branch: main
HEAD: 46fb1f9198475678edc9cabdeefd2f91a59e49c2

R6 tree: Stage=2884 Checkout=2884 Missing=0 Extra=0 Mismatch=0
Hard checks: 31
Failures: 6

R22 excluded paths derived: 16
R22 excluded paths present: 5
Secret findings: 0
Broken relative Markdown links: 28
Critical navigation targets missing: 0
Stale local/temp/session link findings: 74
Possible EOL-only changed paths: 0

Git status entries: 29
Tracked changed paths: 16
Untracked files: 950
Cached/staged paths: 0

No commit performed.
No tag created.
No push performed.
No publication performed.

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_20260910T123054197Z_3a252164\MSBF_PHASE_E_PRE_COMMIT_GATE.json
============================================================

FAILED CHECKS:

Check                           Expected               Actual                    Status
-----                           --------               ------                    ------
R22_DERIVED_EXCLUDED_PATH_COUNT 11                     16                        FAIL
R22_EXCLUDED_PATHS_ABSENT       Derived=11; Present=0  Derived=16; Present=5     FAIL
FORBIDDEN_PRIVATE_RAW_CARRIERS  0                      6                         FAIL
RELATIVE_MARKDOWN_LINKS         0                      28                        FAIL
STALE_LOCAL_TEMP_SESSION_LINKS  0                      74                        FAIL
GIT_DIFF_CHECK                  ExitCode=0; Findings=0 ExitCode=2; Findings=8658 FAIL


PHASE E FAILED CLOSED.
Do NOT stage, commit, tag, push, or publish.

Return the JSON receipt, console summary, and any failed-check evidence.
<!-- END_SOURCE_MESSAGE -->
