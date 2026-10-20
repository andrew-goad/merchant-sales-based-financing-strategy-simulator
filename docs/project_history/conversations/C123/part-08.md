# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 08 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-07.md)
[Next part](part-09.md)

<a id="m-1ab76181-ad34-4aae-8acd-675e1badfab3"></a>
## Andrew / user · C123-M00073

C123-M00073 · 2026-09-10T08:47:00.799000-04:00 · active path

Preceding visible parent: [C123-M00072](part-07.md#m-182b4373-d6ee-4e7a-aa37-281e7fbcece1)

**Editorial record note:** Attachment references: GIT_DIFF_CHECK_DIAGNOSTIC.txt; MSBF_PHASE_E_R2_PRE_COMMIT_GATE.json; PHASE_E_R2_CHECK_REGISTER.csv; PUBLIC_RELEASE_VALIDATOR.txt; RC1_OVERLAY_VALIDATOR.txt; RC2_OVERLAY_VALIDATOR.txt; AUTHORITATIVE_R22_EXCLUDED_PATHS.txt

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE E-R2 — CORRECTED PRE-COMMIT GATE
============================================================
Repository: D:\x\m
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_R2_20260910T124444700Z_d0736027

Hashing staging and checkout...
Re-hashing checkout after corrected gate...

============================================================
PRE_COMMIT_GATE_R2 = PASS
Hard checks: 22
Failures: 0

R6 tree equality: True
Authoritative R22 excluded: 11
Excluded paths present: 0
Broken current Markdown links: 0
Stale actual Markdown links: 0
git diff --check findings: 8658
git diff --check affected files: 3
diff-check files differing from R6: 0

HEAD: 46fb1f9198475678edc9cabdeefd2f91a59e49c2
Cached paths: 0

No staging, commit, tag, push, or publication performed.
Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_R2_20260910T124444700Z_d0736027\MSBF_PHASE_E_R2_PRE_COMMIT_GATE.json
============================================================

PRE_COMMIT_GATE = PASS
Stop here. Do not stage or commit yet.
<!-- END_SOURCE_MESSAGE -->


<a id="m-acd13cc5-f347-4d57-937b-c914530b5e72"></a>
## Assistant · C123-M00074

C123-M00074 · 2026-09-10T08:47:12.743583-04:00 · active path

Preceding visible parent: [C123-M00073](part-08.md#m-1ab76181-ad34-4aae-8acd-675e1badfab3)

<!-- BEGIN_SOURCE_MESSAGE -->
Phase E-R2 is cleanly closed. I reviewed the machine-readable receipt and the 22-row check register: **22/22 checks PASS, zero failures**. The authoritative R22 exclusion boundary is **11 expected / 0 present**, current Markdown navigation is clean, and all 8,658 `git diff --check` findings are confined to three files whose bytes remain exactly equal to R6. [export reference: filecite | turn28file1 | L12-L22] The public-release validator also passes over 2,880 governed manifest files, while both RC1 and RC2 overlay validators pass their respective 235- and 248-file populations. [export reference: filecite | turn28file2 | L1-L3] [export reference: filecite | turn28file3 | L1-L2] [export reference: filecite | turn28file4 | L1-L2]

The governance interpretation is now:

```text
PHASE_E_INITIAL                    FAIL — scanner/control-scope defects
PHASE_E1_FORENSIC_TRIAGE           COMPLETE — read-only
PHASE_E2_ADJUDICATION              COMPLETE — false positives resolved
PHASE_E_R2_CORRECTED_GATE          PASS — 22/22

R6_PUBLICATION_DEFECT              NONE ESTABLISHED
R6_TREE_IDENTITY                   PASS
R22_PRIVATE_EXCLUSION              PASS
PUBLIC_NAVIGATION                  PASS
PRE-COMMIT_GATE                    CLOSED / PASS

HEAD                               46fb1f9198475678edc9cabdeefd2f91a59e49c2
INDEX                              EMPTY
COMMIT/TAG/PUSH/PUBLICATION        NOT YET PERFORMED
```

The receipt expressly confirms that E-R2 itself performed no repository mutation, staging, commit, tag, push, or publication. [export reference: filecite | turn28file1 | L23-L29] The exact 11 excluded R22 Desktop-evidence paths are also preserved as the authoritative exclusion population; for example, they include the owner attestation, evidence manifest, and five Desktop captures under the R22 evidence directory. [export reference: filecite | turn28file5 | L5-L11]

We can therefore cross the controlled boundary into **Phase F — exact-tree staging, staged-content certification, and publication commit creation**. This phase deliberately stops **before tag, push, GitHub release, or other publication**.

Run the following in the same PowerShell window:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo  = 'D:\x\m'
    $Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'
    $E2Dir = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_R2_20260910T124444700Z_d0736027'

    $ExpectedParent = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'
    $ExpectedFiles  = 2884

    $ExpectedPbixBytes = 27635305
    $ExpectedPbixSha   = 'ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4'

    $CommitMessage = 'Publish integrated MSBF Module 1/2 successor release'

    $Stamp  = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_F_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE F — STAGE, CERTIFY, AND COMMIT"
    Write-Host "============================================================"
    Write-Host "Repository: $Repo"
    Write-Host "R6 stage:   $Stage"
    Write-Host "Phase E-R2: $E2Dir"
    Write-Host "Evidence:   $EvidenceDir"
    Write-Host ""

    $Checks = New-Object System.Collections.Generic.List[object]

    function Add-Check {
        param(
            [string]$Check,
            [bool]$Pass,
            [string]$Actual,
            [string]$Expected
        )

        $Checks.Add([pscustomobject]@{
            Check    = $Check
            Expected = $Expected
            Actual   = $Actual
            Status   = if ($Pass) { 'PASS' } else { 'FAIL' }
        })
    }

    function Get-TreeInventory {
        param(
            [string]$Root,
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
            [pscustomobject]@{
                Path = $f.FullName.Substring(
                    $rootFull.Length
                ).Replace('\','/')

                Bytes = [int64]$f.Length

                Sha256 = (
                    Get-FileHash `
                        -LiteralPath $f.FullName `
                        -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }
        }
    }

    function Fail-Closed {
        param([string]$Reason)

        Write-Host ""
        Write-Host "PHASE_F = FAIL"
        Write-Host $Reason
        Write-Host ""
        Write-Host "No commit should be relied upon."
        Write-Host "Do NOT tag, push, or publish."
        throw $Reason
    }

    # ============================================================
    # 1. Revalidate Phase E-R2 authority
    # ============================================================

    $E2ReceiptPath = Join-Path $E2Dir `
        'MSBF_PHASE_E_R2_PRE_COMMIT_GATE.json'

    if (-not (Test-Path -LiteralPath $E2ReceiptPath)) {
        Fail-Closed "Phase E-R2 receipt missing."
    }

    $E2 = Get-Content -LiteralPath $E2ReceiptPath -Raw |
        ConvertFrom-Json

    Add-Check `
        'PHASE_E_R2_PASS' `
        ($E2.PreCommitGate -ceq 'PASS' -and $E2.FailureCount -eq 0) `
        "Gate=$($E2.PreCommitGate);Failures=$($E2.FailureCount)" `
        'Gate=PASS;Failures=0'

    Add-Check `
        'PHASE_E_R2_R6_COUNT' `
        ($E2.R6FileCount -eq $ExpectedFiles) `
        "$($E2.R6FileCount)" `
        "$ExpectedFiles"

    # ============================================================
    # 2. Pre-staging repository boundary
    # ============================================================

    $HeadBefore = (
        & git -C $Repo rev-parse HEAD
    ).Trim().ToLowerInvariant()

    $Branch = (
        & git -C $Repo branch --show-current
    ).Trim()

    $CachedBefore = @(
        & git -C $Repo diff --cached --name-only
    )

    Add-Check `
        'PARENT_HEAD' `
        ($HeadBefore -ceq $ExpectedParent) `
        $HeadBefore `
        $ExpectedParent

    Add-Check `
        'BRANCH_MAIN' `
        ($Branch -ceq 'main') `
        $Branch `
        'main'

    Add-Check `
        'INDEX_EMPTY_BEFORE' `
        ($CachedBefore.Count -eq 0) `
        "$($CachedBefore.Count)" `
        '0'

    if (@($Checks | Where-Object Status -eq 'FAIL').Count -gt 0) {
        $Checks | Export-Csv `
            (Join-Path $EvidenceDir 'PHASE_F_CHECK_REGISTER.csv') `
            -NoTypeInformation -Encoding UTF8

        Fail-Closed "Pre-staging boundary failed."
    }

    # ============================================================
    # 3. Freshly certify working tree == exact R6
    # ============================================================

    Write-Host "Freshly hashing R6 stage..."
    $StageInv = @(Get-TreeInventory $Stage)

    Write-Host "Freshly hashing checkout..."
    $RepoInv = @(Get-TreeInventory $Repo -ExcludeGit)

    $sMap = @{}
    foreach ($r in $StageInv) {
        $sMap[$r.Path.ToLowerInvariant()] = $r
    }

    $rMap = @{}
    foreach ($r in $RepoInv) {
        $rMap[$r.Path.ToLowerInvariant()] = $r
    }

    $Missing  = 0
    $Extra    = 0
    $Mismatch = 0

    foreach ($k in $sMap.Keys) {
        if (-not $rMap.ContainsKey($k)) {
            $Missing++
            continue
        }

        $s = $sMap[$k]
        $r = $rMap[$k]

        if (
            $s.Path   -cne $r.Path   -or
            $s.Bytes  -ne  $r.Bytes  -or
            $s.Sha256 -cne $r.Sha256
        ) {
            $Mismatch++
        }
    }

    foreach ($k in $rMap.Keys) {
        if (-not $sMap.ContainsKey($k)) {
            $Extra++
        }
    }

    $TreePass = (
        $StageInv.Count -eq $ExpectedFiles -and
        $RepoInv.Count  -eq $ExpectedFiles -and
        $Missing  -eq 0 -and
        $Extra    -eq 0 -and
        $Mismatch -eq 0
    )

    Add-Check `
        'WORKTREE_EXACT_R6' `
        $TreePass `
        "Stage=$($StageInv.Count);Checkout=$($RepoInv.Count);Missing=$Missing;Extra=$Extra;Mismatch=$Mismatch" `
        "Stage=2884;Checkout=2884;Missing=0;Extra=0;Mismatch=0"

    if (-not $TreePass) {
        $Checks | Export-Csv `
            (Join-Path $EvidenceDir 'PHASE_F_CHECK_REGISTER.csv') `
            -NoTypeInformation -Encoding UTF8

        Fail-Closed "Checkout no longer equals R6."
    }

    # ============================================================
    # 4. Stage exact checkout
    # ============================================================

    Write-Host ""
    Write-Host "Staging exact reviewed R6 checkout..."

    & git -C $Repo add --all

    if ($LASTEXITCODE -ne 0) {
        Fail-Closed "git add --all failed."
    }

    $CachedAfterAdd = @(
        & git -C $Repo diff --cached --name-only
    )

    $StatusAfterAdd = @(
        & git -C $Repo status --porcelain=v1
    )

    Add-Check `
        'INDEX_NONEMPTY_AFTER_STAGE' `
        ($CachedAfterAdd.Count -gt 0) `
        "$($CachedAfterAdd.Count)" `
        '>0'

    # No ordinary unstaged changes may remain.
    $UnstagedAfterAdd = @(
        & git -C $Repo diff --name-only
    )

    Add-Check `
        'NO_UNSTAGED_TRACKED_CHANGES' `
        ($UnstagedAfterAdd.Count -eq 0) `
        "$($UnstagedAfterAdd.Count)" `
        '0'

    # No untracked paths may remain.
    $UntrackedAfterAdd = @(
        & git -C $Repo ls-files --others --exclude-standard
    )

    Add-Check `
        'NO_UNTRACKED_PATHS_AFTER_STAGE' `
        ($UntrackedAfterAdd.Count -eq 0) `
        "$($UntrackedAfterAdd.Count)" `
        '0'

    # ============================================================
    # 5. Stage-path population and index/worktree agreement
    # ============================================================

    $IndexPaths = @(
        & git -C $Repo ls-files
    )

    $IndexSet = @{}
    foreach ($p in $IndexPaths) {
        $IndexSet[$p.ToLowerInvariant()] = $p
    }

    $MissingFromIndex = @(
        $StageInv |
        Where-Object {
            -not $IndexSet.ContainsKey($_.Path.ToLowerInvariant())
        }
    )

    $ExtraInIndex = @(
        $IndexPaths |
        Where-Object {
            -not $sMap.ContainsKey($_.ToLowerInvariant())
        }
    )

    Add-Check `
        'INDEX_PATH_COUNT' `
        ($IndexPaths.Count -eq $ExpectedFiles) `
        "$($IndexPaths.Count)" `
        "$ExpectedFiles"

    Add-Check `
        'R6_PATHS_ALL_IN_INDEX' `
        ($MissingFromIndex.Count -eq 0) `
        "$($MissingFromIndex.Count)" `
        '0'

    Add-Check `
        'INDEX_HAS_NO_EXTRA_PATHS' `
        ($ExtraInIndex.Count -eq 0) `
        "$($ExtraInIndex.Count)" `
        '0'

    # git diff with no args must remain empty; therefore the staged
    # index is consistent with the exact-R6 working tree under the
    # repository's active attributes/configuration.
    $WorktreeVsIndex = @(
        & git -C $Repo diff --name-only
    )

    Add-Check `
        'INDEX_WORKTREE_AGREEMENT' `
        ($WorktreeVsIndex.Count -eq 0) `
        "$($WorktreeVsIndex.Count)" `
        '0'

    # ============================================================
    # 6. Authoritative R22 exclusion remains absent
    # ============================================================

    $ProvPath = Join-Path $Repo `
        'docs\release_integration\module_2_g3_v2_1\R18_PUBLIC_PROJECTION_PROVENANCE.json'

    $Prov = Get-Content -LiteralPath $ProvPath -Raw |
        ConvertFrom-Json

    $ExactExcluded = @(
        $Prov.excluded_private_files |
        ForEach-Object {
            ([string]$_.path).Replace('\','/')
        }
    )

    $ExcludedInIndex = @(
        $ExactExcluded |
        Where-Object {
            $IndexSet.ContainsKey($_.ToLowerInvariant())
        }
    )

    Add-Check `
        'AUTHORITATIVE_R22_EXCLUSION_COUNT' `
        ($ExactExcluded.Count -eq 11) `
        "$($ExactExcluded.Count)" `
        '11'

    Add-Check `
        'AUTHORITATIVE_R22_NOT_STAGED' `
        ($ExcludedInIndex.Count -eq 0) `
        "$($ExcludedInIndex.Count)" `
        '0'

    # ============================================================
    # 7. PBIX identity after staging
    # ============================================================

    $Pbix = Join-Path $Repo `
        'docs\power_bi\m2_v2_1\release\MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix'

    $PbixItem = Get-Item -LiteralPath $Pbix
    $PbixSha = (
        Get-FileHash -LiteralPath $Pbix -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    Add-Check `
        'PBIX_BYTES' `
        ($PbixItem.Length -eq $ExpectedPbixBytes) `
        "$($PbixItem.Length)" `
        "$ExpectedPbixBytes"

    Add-Check `
        'PBIX_SHA256' `
        ($PbixSha -ceq $ExpectedPbixSha) `
        $PbixSha `
        $ExpectedPbixSha

    # ============================================================
    # 8. Re-run static validators against staged working state
    # ============================================================

    $Python = (Get-Command python.exe -ErrorAction Stop).Source

    function Run-Validator {
        param(
            [string]$Label,
            [string]$Rel,
            [string]$Expected1,
            [string]$Expected2
        )

        Push-Location $Repo
        try {
            $out = @(
                & $Python (Join-Path $Repo $Rel) 2>&1
            )
            $code = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $out |
            Set-Content `
                -LiteralPath (Join-Path $EvidenceDir "$Label.txt") `
                -Encoding UTF8

        $text = $out -join "`n"

        Add-Check `
            $Label `
            (
                $code -eq 0 -and
                $text.Contains($Expected1) -and
                $text.Contains($Expected2)
            ) `
            "ExitCode=$code" `
            "ExitCode=0; $Expected1; $Expected2"
    }

    Run-Validator `
        'PUBLIC_RELEASE_VALIDATOR' `
        'tools\validate_public_release.py' `
        'Public release validation PASS' `
        'Governed manifest files: 2880'

    Run-Validator `
        'RC1_OVERLAY_VALIDATOR' `
        'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py' `
        'Candidate overlay validation PASS' `
        'Governed candidate files: 235'

    Run-Validator `
        'RC2_OVERLAY_VALIDATOR' `
        'successor_candidates\m2-g3-v2.1.0-rc2\tools\validate_candidate_overlay.py' `
        'Candidate overlay validation PASS' `
        'Governed candidate files: 248'

    # ============================================================
    # 9. Ensure validators did not mutate working tree/index
    # ============================================================

    $UnstagedAfterValidators = @(
        & git -C $Repo diff --name-only
    )

    Add-Check `
        'VALIDATORS_NO_WORKTREE_MUTATION' `
        ($UnstagedAfterValidators.Count -eq 0) `
        "$($UnstagedAfterValidators.Count)" `
        '0'

    $CachedAfterValidators = @(
        & git -C $Repo diff --cached --name-only
    )

    $StagePathDelta = Compare-Object `
        ($CachedAfterAdd | Sort-Object) `
        ($CachedAfterValidators | Sort-Object)

    Add-Check `
        'VALIDATORS_NO_INDEX_MUTATION' `
        (@($StagePathDelta).Count -eq 0) `
        "$(@($StagePathDelta).Count)" `
        '0'

    # ============================================================
    # 10. Diagnostic staged diff check
    #
    # Findings remain diagnostic because Phase E-R2 already proved
    # all three affected files are exact R6 bytes.
    # ============================================================

    $CachedDiffCheck = @(
        & git -C $Repo diff --cached --check
    )
    $CachedDiffCheckExit = $LASTEXITCODE

    $CachedDiffCheck |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'STAGED_GIT_DIFF_CHECK_DIAGNOSTIC.txt'
            ) `
            -Encoding UTF8

    $CachedDiffFiles = @(
        $CachedDiffCheck |
        ForEach-Object {
            if ($_ -match '^(.+?):\d+:') {
                $Matches[1]
            }
        } |
        Sort-Object -Unique
    )

    Add-Check `
        'STAGED_DIFF_CHECK_SCOPE' `
        ($CachedDiffFiles.Count -le 3) `
        "Findings=$($CachedDiffCheck.Count);Files=$($CachedDiffFiles.Count);ExitCode=$CachedDiffCheckExit" `
        'AffectedFiles<=3; findings diagnostic'

    # ============================================================
    # 11. Fail closed BEFORE commit if any certification fails
    # ============================================================

    $PreCommitFailures = @(
        $Checks | Where-Object Status -eq 'FAIL'
    )

    $Checks |
        Export-Csv `
            -LiteralPath (
                Join-Path $EvidenceDir 'PHASE_F_PRECOMMIT_CHECK_REGISTER.csv'
            ) `
            -NoTypeInformation `
            -Encoding UTF8

    if ($PreCommitFailures.Count -gt 0) {
        Write-Host ""
        Write-Host "PRE-COMMIT CERTIFICATION FAILED:"
        $PreCommitFailures |
            Format-Table -AutoSize |
            Out-Host

        Write-Host ""
        Write-Host "Index has been populated but NO COMMIT was made."
        Write-Host "Do NOT tag, push, or publish."
        Write-Host "Stop and return the evidence."

        return
    }

    # ============================================================
    # 12. Capture staged diff/stat before commit
    # ============================================================

    & git -C $Repo diff --cached --stat |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'STAGED_DIFF_STAT.txt'
            ) `
            -Encoding UTF8

    & git -C $Repo status --short |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'PRE_COMMIT_GIT_STATUS.txt'
            ) `
            -Encoding UTF8

    & git -C $Repo diff --cached --name-status |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'STAGED_NAME_STATUS.txt'
            ) `
            -Encoding UTF8

    # ============================================================
    # 13. Create publication commit
    # ============================================================

    Write-Host ""
    Write-Host "All staged certification checks PASS."
    Write-Host "Creating publication commit..."

    & git -C $Repo commit -m $CommitMessage

    $CommitExit = $LASTEXITCODE

    if ($CommitExit -ne 0) {
        Add-Check `
            'PUBLICATION_COMMIT_CREATED' `
            $false `
            "ExitCode=$CommitExit" `
            'ExitCode=0'

        $Checks |
            Export-Csv `
                -LiteralPath (
                    Join-Path $EvidenceDir 'PHASE_F_CHECK_REGISTER.csv'
                ) `
                -NoTypeInformation `
                -Encoding UTF8

        Fail-Closed "git commit failed."
    }

    $Commit = (
        & git -C $Repo rev-parse HEAD
    ).Trim().ToLowerInvariant()

    $Parent = (
        & git -C $Repo rev-parse HEAD^
    ).Trim().ToLowerInvariant()

    Add-Check `
        'PUBLICATION_COMMIT_CREATED' `
        ($Commit -cne $ExpectedParent) `
        $Commit `
        'new commit'

    Add-Check `
        'PUBLICATION_COMMIT_PARENT' `
        ($Parent -ceq $ExpectedParent) `
        $Parent `
        $ExpectedParent

    # ============================================================
    # 14. Commit tree vs index/working tree
    # ============================================================

    $PostCommitStatus = @(
        & git -C $Repo status --porcelain=v1
    )

    Add-Check `
        'POST_COMMIT_WORKTREE_CLEAN' `
        ($PostCommitStatus.Count -eq 0) `
        "$($PostCommitStatus.Count)" `
        '0'

    $CachedPostCommit = @(
        & git -C $Repo diff --cached --name-only
    )

    Add-Check `
        'POST_COMMIT_INDEX_CLEAN' `
        ($CachedPostCommit.Count -eq 0) `
        "$($CachedPostCommit.Count)" `
        '0'

    $CommittedPathCount = @(
        & git -C $Repo ls-tree -r --name-only HEAD
    ).Count

    Add-Check `
        'COMMITTED_TREE_PATH_COUNT' `
        ($CommittedPathCount -eq $ExpectedFiles) `
        "$CommittedPathCount" `
        "$ExpectedFiles"

    # ============================================================
    # 15. Fresh post-commit R6 filesystem identity
    # ============================================================

    Write-Host "Freshly hashing checkout after commit..."
    $RepoAfterCommit = @(Get-TreeInventory $Repo -ExcludeGit)

    $aMap = @{}
    foreach ($r in $RepoAfterCommit) {
        $aMap[$r.Path.ToLowerInvariant()] = $r
    }

    $PostCommitMissing  = 0
    $PostCommitExtra    = 0
    $PostCommitMismatch = 0

    foreach ($k in $sMap.Keys) {
        if (-not $aMap.ContainsKey($k)) {
            $PostCommitMissing++
            continue
        }

        $s = $sMap[$k]
        $a = $aMap[$k]

        if (
            $s.Path   -cne $a.Path   -or
            $s.Bytes  -ne  $a.Bytes  -or
            $s.Sha256 -cne $a.Sha256
        ) {
            $PostCommitMismatch++
        }
    }

    foreach ($k in $aMap.Keys) {
        if (-not $sMap.ContainsKey($k)) {
            $PostCommitExtra++
        }
    }

    $PostCommitTreePass = (
        $RepoAfterCommit.Count -eq $ExpectedFiles -and
        $PostCommitMissing  -eq 0 -and
        $PostCommitExtra    -eq 0 -and
        $PostCommitMismatch -eq 0
    )

    Add-Check `
        'POST_COMMIT_CHECKOUT_EXACT_R6' `
        $PostCommitTreePass `
        "Checkout=$($RepoAfterCommit.Count);Missing=$PostCommitMissing;Extra=$PostCommitExtra;Mismatch=$PostCommitMismatch" `
        'Checkout=2884;Missing=0;Extra=0;Mismatch=0'

    # ============================================================
    # 16. Commit object evidence
    # ============================================================

    & git -C $Repo show `
        --no-patch `
        --format=fuller `
        HEAD |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'PUBLICATION_COMMIT_OBJECT.txt'
            ) `
            -Encoding UTF8

    & git -C $Repo ls-tree `
        -r `
        --full-tree `
        HEAD |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'PUBLICATION_COMMIT_TREE.txt'
            ) `
            -Encoding UTF8

    # ============================================================
    # 17. Final decision
    # ============================================================

    $Failures = @(
        $Checks | Where-Object Status -eq 'FAIL'
    )

    $PhaseFStatus = if ($Failures.Count -eq 0) {
        'PASS'
    }
    else {
        'FAIL'
    }

    $Checks |
        Export-Csv `
            -LiteralPath (
                Join-Path $EvidenceDir 'PHASE_F_CHECK_REGISTER.csv'
            ) `
            -NoTypeInformation `
            -Encoding UTF8

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_F_STAGE_CERTIFY_COMMIT'

        GoverningDecision  = 'IA-D-R20-INT-001'
        PublicationAuthority = 'IA-PUB-R20-INTEGRATED-001'

        Repository = $Repo
        SourceStage = $Stage
        PhaseER2Evidence = $E2Dir
        EvidenceDirectory = $EvidenceDir

        Branch = $Branch

        ParentHead = $ExpectedParent
        PublicationCommit = $Commit
        PublicationCommitParent = $Parent

        R6FileCount = $ExpectedFiles
        CommittedTreePathCount = $CommittedPathCount

        AuthoritativeR22ExcludedCount = $ExactExcluded.Count
        AuthoritativeR22ExcludedStaged = $ExcludedInIndex.Count

        PbixBytes = $PbixItem.Length
        PbixSha256 = $PbixSha

        StagedDiffCheckFindingCount = $CachedDiffCheck.Count
        StagedDiffCheckAffectedFiles = $CachedDiffFiles.Count
        StagedDiffCheckDisposition = `
            'DIAGNOSTIC_ONLY_PHASE_E_R2_EXACT_R6_BYTES'

        CheckCount = $Checks.Count
        FailureCount = $Failures.Count
        FailedChecks = @(
            $Failures |
            Select-Object Check,Expected,Actual
        )

        StagingPerformed = $true
        CommitPerformed = ($CommitExit -eq 0)

        TagPerformed = $false
        PushPerformed = $false
        PublicationPerformed = $false

        PhaseF = $PhaseFStatus
    }

    $JsonPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_F_STAGE_CERTIFY_COMMIT_RECEIPT.json'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content `
            -LiteralPath $JsonPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "PHASE_F = $PhaseFStatus"
    Write-Host "============================================================"
    Write-Host "Parent HEAD:        $Parent"
    Write-Host "Publication commit: $Commit"
    Write-Host ""
    Write-Host "R6 files:           $ExpectedFiles"
    Write-Host "Committed paths:    $CommittedPathCount"
    Write-Host "R22 staged:         $($ExcludedInIndex.Count)"
    Write-Host "PBIX SHA-256:       $PbixSha"
    Write-Host ""
    Write-Host "Checks:              $($Checks.Count)"
    Write-Host "Failures:            $($Failures.Count)"
    Write-Host ""
    Write-Host "Tag created:         NO"
    Write-Host "Push performed:      NO"
    Write-Host "Publication:         NO"
    Write-Host ""
    Write-Host "Receipt: $JsonPath"
    Write-Host "============================================================"

    if ($Failures.Count -gt 0) {
        Write-Host ""
        Write-Host "FAILED CHECKS:"
        $Failures |
            Format-Table -AutoSize |
            Out-Host

        Write-Host ""
        Write-Host "STOP. Do NOT tag, push, or publish."
    }
    else {
        Write-Host ""
        Write-Host "PHASE F PASS."
        Write-Host "Publication commit exists locally and is certified."
        Write-Host "STOP HERE."
        Write-Host "Do NOT tag, push, or publish yet."
    }
}
```

A clean Phase F should end approximately like this:

```text
PHASE_F = PASS

Parent HEAD:
46fb1f9198475678edc9cabdeefd2f91a59e49c2

Publication commit:
<NEW 40-CHAR COMMIT SHA>

R6 files:        2884
Committed paths: 2884
R22 staged:      0

Checks:          all PASS
Failures:        0

Tag created:     NO
Push performed:  NO
Publication:     NO

PHASE F PASS.
Publication commit exists locally and is certified.
STOP HERE.
Do NOT tag, push, or publish yet.
```

One important control point: the **8,658 whitespace diagnostics are not being silently waived**. The staged gate records them again, but E-R2 established that the affected files are the approved R6 bytes. The raw diagnostic demonstrates that these are manifest/content whitespace findings rather than evidence of an unintended post-R6 edit. [export reference: filecite | turn28file0 | L1-L18]

Return the Phase F console summary plus `MSBF_PHASE_F_STAGE_CERTIFY_COMMIT_RECEIPT.json` and `PHASE_F_CHECK_REGISTER.csv`. If it passes, the next boundary will be **Phase G: independently verify the new commit object and tree from Git itself, construct the intended tag/release identities, and perform the final pre-push gate—still before any network mutation.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-f271e8b8-b1fb-49ce-92e7-f138a93253f4"></a>
## Andrew / user · C123-M00075

C123-M00075 · 2026-09-10T08:52:11.466000-04:00 · active path

Preceding visible parent: [C123-M00074](part-08.md#m-acd13cc5-f347-4d57-937b-c914530b5e72)

**Editorial record note:** Attachment references: PHASE_F_PRECOMMIT_CHECK_REGISTER.csv; PUBLIC_RELEASE_VALIDATOR(1).txt; RC1_OVERLAY_VALIDATOR(1).txt; RC2_OVERLAY_VALIDATOR(1).txt; STAGED_GIT_DIFF_CHECK_DIAGNOSTIC.txt

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE F — STAGE, CERTIFY, AND COMMIT
============================================================
Repository: D:\x\m
R6 stage:   D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94
Phase E-R2: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_R2_20260910T124444700Z_d0736027
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_F_20260910T124937642Z_bdc3094b

Freshly hashing R6 stage...
Freshly hashing checkout...

Staging exact reviewed R6 checkout...

PRE-COMMIT CERTIFICATION FAILED:

Check                   Expected                              Actual                               Status
-----                   --------                              ------                               ------
STAGED_DIFF_CHECK_SCOPE AffectedFiles<=3; findings diagnostic Findings=42098;Files=3142;ExitCode=2 FAIL


Index has been populated but NO COMMIT was made.
Do NOT tag, push, or publish.
Stop and return the evidence.
<!-- END_SOURCE_MESSAGE -->


<a id="m-333b28d9-f28c-4035-b617-b255249e8a02"></a>
## Assistant · C123-M00076

C123-M00076 · 2026-09-10T08:52:49.726771-04:00 · active path

Preceding visible parent: [C123-M00075](part-08.md#m-f271e8b8-b1fb-49ce-92e7-f138a93253f4)

<!-- BEGIN_SOURCE_MESSAGE -->
Phase F stopped correctly, and the new evidence shows the failure is in **my Phase F diagnostic gate design—not in R6 and not in the staged release content**.

I reviewed the supplied pre-commit register and diagnostic. **22 of 23 Phase F checks passed.** The important controls all passed: HEAD remained the expected predecessor, the working tree was exactly the 2,884-file R6 tree, the index contained exactly 2,884 paths with no extras or omissions, there were no unstaged or untracked paths, the 11 authoritative R22 private artifacts remained excluded, the PBIX identity matched exactly, and all three release validators passed. The public validator reports 2,880 governed manifest files, and RC1/RC2 report 235 and 248 governed candidate files respectively. [export reference: filecite | turn29file0 | L1-L3] [export reference: filecite | turn29file1 | L1-L2] [export reference: filecite | turn29file2 | L1-L2]

The sole failure was:

```text
STAGED_DIFF_CHECK_SCOPE
Expected: AffectedFiles<=3
Actual:   Findings=42098;Files=3142;ExitCode=2
```

That result is misleading for **two separate reasons**.

First, after `git add --all`, `git diff --cached --check` is no longer examining the narrow condition that Phase E-R2 adjudicated. It is evaluating the **entire staged publication delta against the old HEAD**. Your register shows **966 cached paths**, so a much larger diagnostic population is entirely plausible. The diagnostic immediately starts flagging trailing whitespace in `MANIFEST.csv` entries representing release files. [export reference: filecite | turn29file3 | L1-L18] In other words, I incorrectly carried the E-R2 “three affected files” expectation across a different Git comparison boundary.

Second, the `Files=3142` figure is itself invalid. The parser I gave you used:

```powershell
if ($_ -match '^(.+?):\d+:') {
    $Matches[1]
}
```

But `git diff --check` emits the offending added line immediately after each diagnostic. Many MSBF records contain timestamps such as `2026-09-01T01:...`; those added-content lines also satisfy that regex. I reperformed the parsing against your full uploaded diagnostic: thousands of supposed “filenames” are actually CSV content beginning with strings such as:

```text
+15,conv_100,48,...,2026-09-01T01
+12,conv_97,400,...,2026-08-28T03
```

So **3,142 is not a file count at all**.

Accordingly, the disposition is:

```text
PHASE_F_R1
  Result:                     FAIL-CLOSED
  Cause:                      PHASE_F_CONTROL_DEFECT
  Release-content defect:     NOT ESTABLISHED
  R6 regression:              NOT ESTABLISHED
  Repository commit:          NONE
  Tag / push / publication:   NONE

Current index:
  STAGED
  Expected staged paths:      966 changed vs predecessor
  Complete index population:  2,884
  Working tree vs R6:         PASS
  R22 exclusion:              PASS
  PBIX identity:              PASS
  Static validators:          PASS
```

I do **not** want to unstage or restage yet. The index is currently a useful controlled object. The correct next action is a **Phase F-R2 staged-object certification** that proves the actual Git index blobs correspond to the exact approved R6 source under Git's own attribute/filter rules, then treats `git diff --cached --check` as a diagnostic inventory rather than imposing the erroneous three-file threshold. Only after that proof should we commit.

Run this correction from the same PowerShell window. It will inspect and certify the existing staged state; it will **not commit, tag, push, or publish**.

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo  = 'D:\x\m'
    $Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'
    $PriorF = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_F_20260910T124937642Z_bdc3094b'

    $ExpectedHead  = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'
    $ExpectedFiles = 2884
    $ExpectedChangedPaths = 966

    $Stamp  = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_F_R2_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE F-R2 — CORRECTED STAGED-OBJECT CERTIFICATION"
    Write-Host "============================================================"
    Write-Host "Repository:      $Repo"
    Write-Host "R6 stage:        $Stage"
    Write-Host "Prior Phase F:   $PriorF"
    Write-Host "Evidence:        $EvidenceDir"
    Write-Host ""

    $Checks = New-Object System.Collections.Generic.List[object]

    function Add-Check {
        param(
            [string]$Check,
            [bool]$Pass,
            [string]$Actual,
            [string]$Expected
        )

        $Checks.Add([pscustomobject]@{
            Check    = $Check
            Expected = $Expected
            Actual   = $Actual
            Status   = if ($Pass) { 'PASS' } else { 'FAIL' }
        })
    }

    function Write-Register {
        $Checks |
            Export-Csv `
                -LiteralPath (Join-Path $EvidenceDir 'PHASE_F_R2_CHECK_REGISTER.csv') `
                -NoTypeInformation `
                -Encoding UTF8
    }

    function Stop-Fail {
        param([string]$Reason)

        Write-Register

        Write-Host ""
        Write-Host "PHASE_F_R2 = FAIL"
        Write-Host $Reason
        Write-Host ""
        Write-Host "NO COMMIT CREATED."
        Write-Host "DO NOT TAG, PUSH, OR PUBLISH."
        throw $Reason
    }

    function Get-RawInventory {
        param([string]$Root)

        $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'

        foreach ($f in Get-ChildItem -LiteralPath $Root -Recurse -File -Force) {
            [pscustomobject]@{
                Path = $f.FullName.Substring(
                    $rootFull.Length
                ).Replace('\','/')

                Bytes = [int64]$f.Length

                Sha256 = (
                    Get-FileHash `
                        -LiteralPath $f.FullName `
                        -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }
        }
    }

    # ============================================================
    # 1. Confirm we are still at the stopped Phase F boundary
    # ============================================================

    $Head = (
        & git -C $Repo rev-parse HEAD
    ).Trim().ToLowerInvariant()

    $Branch = (
        & git -C $Repo branch --show-current
    ).Trim()

    $CachedPaths = @(
        & git -C $Repo diff --cached --name-only
    )

    $Unstaged = @(
        & git -C $Repo diff --name-only
    )

    $Untracked = @(
        & git -C $Repo ls-files --others --exclude-standard
    )

    Add-Check `
        'HEAD_UNCHANGED' `
        ($Head -ceq $ExpectedHead) `
        $Head `
        $ExpectedHead

    Add-Check `
        'BRANCH_MAIN' `
        ($Branch -ceq 'main') `
        $Branch `
        'main'

    Add-Check `
        'EXPECTED_STAGED_DELTA_PATHS' `
        ($CachedPaths.Count -eq $ExpectedChangedPaths) `
        "$($CachedPaths.Count)" `
        "$ExpectedChangedPaths"

    Add-Check `
        'NO_UNSTAGED_TRACKED_CHANGES' `
        ($Unstaged.Count -eq 0) `
        "$($Unstaged.Count)" `
        '0'

    Add-Check `
        'NO_UNTRACKED_PATHS' `
        ($Untracked.Count -eq 0) `
        "$($Untracked.Count)" `
        '0'

    if (@($Checks | Where-Object Status -eq 'FAIL').Count -gt 0) {
        Stop-Fail 'Repository no longer matches the stopped Phase F boundary.'
    }

    # ============================================================
    # 2. Re-prove raw checkout == exact R6 bytes
    # ============================================================

    Write-Host "Hashing exact R6 source..."
    $StageInv = @(Get-RawInventory $Stage)

    $repoRoot = [IO.Path]::GetFullPath($Repo).TrimEnd('\') + '\'
    $gitRoot  = [IO.Path]::GetFullPath(
        (Join-Path $Repo '.git')
    ).TrimEnd('\') + '\'

    Write-Host "Hashing checkout..."
    $RepoInv = @(
        Get-ChildItem -LiteralPath $Repo -Recurse -File -Force |
        Where-Object {
            -not $_.FullName.StartsWith(
                $gitRoot,
                [StringComparison]::OrdinalIgnoreCase
            )
        } |
        ForEach-Object {
            [pscustomobject]@{
                Path = $_.FullName.Substring(
                    $repoRoot.Length
                ).Replace('\','/')

                Bytes = [int64]$_.Length

                Sha256 = (
                    Get-FileHash `
                        -LiteralPath $_.FullName `
                        -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }
        }
    )

    $sMap = @{}
    foreach ($r in $StageInv) {
        $sMap[$r.Path.ToLowerInvariant()] = $r
    }

    $rMap = @{}
    foreach ($r in $RepoInv) {
        $rMap[$r.Path.ToLowerInvariant()] = $r
    }

    $Missing  = 0
    $Extra    = 0
    $Mismatch = 0

    foreach ($k in $sMap.Keys) {
        if (-not $rMap.ContainsKey($k)) {
            $Missing++
            continue
        }

        $s = $sMap[$k]
        $r = $rMap[$k]

        if (
            $s.Path   -cne $r.Path   -or
            $s.Bytes  -ne  $r.Bytes  -or
            $s.Sha256 -cne $r.Sha256
        ) {
            $Mismatch++
        }
    }

    foreach ($k in $rMap.Keys) {
        if (-not $sMap.ContainsKey($k)) {
            $Extra++
        }
    }

    $ExactRawR6 = (
        $StageInv.Count -eq $ExpectedFiles -and
        $RepoInv.Count  -eq $ExpectedFiles -and
        $Missing  -eq 0 -and
        $Extra    -eq 0 -and
        $Mismatch -eq 0
    )

    Add-Check `
        'RAW_CHECKOUT_EXACT_R6' `
        $ExactRawR6 `
        "Stage=$($StageInv.Count);Checkout=$($RepoInv.Count);Missing=$Missing;Extra=$Extra;Mismatch=$Mismatch" `
        'Stage=2884;Checkout=2884;Missing=0;Extra=0;Mismatch=0'

    if (-not $ExactRawR6) {
        Stop-Fail 'Raw checkout no longer equals exact R6.'
    }

    # ============================================================
    # 3. Exact index path population
    # ============================================================

    $IndexPaths = @(
        & git -C $Repo ls-files
    )

    $IndexSet = @{}
    foreach ($p in $IndexPaths) {
        $IndexSet[$p.ToLowerInvariant()] = $p
    }

    $MissingFromIndex = @(
        $StageInv |
        Where-Object {
            -not $IndexSet.ContainsKey($_.Path.ToLowerInvariant())
        }
    )

    $ExtraInIndex = @(
        $IndexPaths |
        Where-Object {
            -not $sMap.ContainsKey($_.ToLowerInvariant())
        }
    )

    Add-Check `
        'INDEX_PATH_COUNT' `
        ($IndexPaths.Count -eq $ExpectedFiles) `
        "$($IndexPaths.Count)" `
        "$ExpectedFiles"

    Add-Check `
        'R6_PATHS_ALL_IN_INDEX' `
        ($MissingFromIndex.Count -eq 0) `
        "$($MissingFromIndex.Count)" `
        '0'

    Add-Check `
        'INDEX_HAS_NO_EXTRA_PATHS' `
        ($ExtraInIndex.Count -eq 0) `
        "$($ExtraInIndex.Count)" `
        '0'

    if (
        $IndexPaths.Count -ne $ExpectedFiles -or
        $MissingFromIndex.Count -ne 0 -or
        $ExtraInIndex.Count -ne 0
    ) {
        Stop-Fail 'Index path population differs from R6.'
    }

    # ============================================================
    # 4. Certify every staged Git blob against R6 under Git filters
    #
    # This is the key correction. For each R6 source file:
    #   - calculate the blob Git itself would create for that path
    #   - retrieve the actual blob currently stored in the index
    #   - require exact object-ID equality
    #
    # This accommodates intentional .gitattributes/EOL filters while
    # proving the index is exactly the Git representation of R6.
    # ============================================================

    Write-Host "Certifying all 2,884 Git index blobs against R6..."

    $BlobRows = New-Object System.Collections.Generic.List[object]
    $BlobMismatchCount = 0
    $BlobErrorCount = 0

    foreach ($r in ($StageInv | Sort-Object Path)) {

        $rel = $r.Path
        $sourceFile = Join-Path $Stage ($rel.Replace('/','\'))

        # Hash the approved R6 file exactly as Git would hash it
        # for this repository path, including applicable attributes.
        $expectedBlob = (
            & git -C $Repo hash-object --path="$rel" "$sourceFile"
        ).Trim().ToLowerInvariant()

        if ($LASTEXITCODE -ne 0 -or -not $expectedBlob) {
            $BlobErrorCount++

            $BlobRows.Add([pscustomobject]@{
                Path = $rel
                ExpectedBlob = ''
                IndexBlob = ''
                Status = 'ERROR_HASHING_R6'
            })

            continue
        }

        $indexLine = @(
            & git -C $Repo ls-files -s -- "$rel"
        )

        if ($LASTEXITCODE -ne 0 -or $indexLine.Count -ne 1) {
            $BlobErrorCount++

            $BlobRows.Add([pscustomobject]@{
                Path = $rel
                ExpectedBlob = $expectedBlob
                IndexBlob = ''
                Status = 'ERROR_READING_INDEX'
            })

            continue
        }

        if ($indexLine[0] -notmatch '^\d+\s+([0-9a-fA-F]+)\s+\d+\s+') {
            $BlobErrorCount++

            $BlobRows.Add([pscustomobject]@{
                Path = $rel
                ExpectedBlob = $expectedBlob
                IndexBlob = ''
                Status = 'ERROR_PARSING_INDEX'
            })

            continue
        }

        $indexBlob = $Matches[1].ToLowerInvariant()

        $status = if ($indexBlob -ceq $expectedBlob) {
            'PASS'
        }
        else {
            $BlobMismatchCount++
            'FAIL'
        }

        $BlobRows.Add([pscustomobject]@{
            Path = $rel
            ExpectedBlob = $expectedBlob
            IndexBlob = $indexBlob
            Status = $status
        })
    }

    $BlobRows |
        Export-Csv `
            -LiteralPath (
                Join-Path $EvidenceDir 'R6_TO_INDEX_BLOB_CERTIFICATION.csv'
            ) `
            -NoTypeInformation `
            -Encoding UTF8

    Add-Check `
        'R6_TO_INDEX_BLOB_CERTIFICATION' `
        (
            $BlobRows.Count -eq $ExpectedFiles -and
            $BlobMismatchCount -eq 0 -and
            $BlobErrorCount -eq 0
        ) `
        "Rows=$($BlobRows.Count);Mismatch=$BlobMismatchCount;Errors=$BlobErrorCount" `
        'Rows=2884;Mismatch=0;Errors=0'

    if ($BlobMismatchCount -ne 0 -or $BlobErrorCount -ne 0) {
        Stop-Fail 'Git index blobs do not exactly represent approved R6.'
    }

    # ============================================================
    # 5. Verify the staged tree itself can be materialized
    # ============================================================

    $IndexTree = (
        & git -C $Repo write-tree
    ).Trim().ToLowerInvariant()

    Add-Check `
        'INDEX_TREE_OBJECT_CREATED' `
        (
            $LASTEXITCODE -eq 0 -and
            $IndexTree -match '^[0-9a-f]{40,64}$'
        ) `
        $IndexTree `
        'valid Git tree object'

    if ($LASTEXITCODE -ne 0 -or -not $IndexTree) {
        Stop-Fail 'Unable to materialize index tree.'
    }

    & git -C $Repo ls-tree -r --full-tree $IndexTree |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'CERTIFIED_INDEX_TREE.txt'
            ) `
            -Encoding UTF8

    $TreePathCount = @(
        & git -C $Repo ls-tree -r --name-only $IndexTree
    ).Count

    Add-Check `
        'INDEX_TREE_PATH_COUNT' `
        ($TreePathCount -eq $ExpectedFiles) `
        "$TreePathCount" `
        "$ExpectedFiles"

    # ============================================================
    # 6. Reconfirm authoritative R22 exclusion in certified index
    # ============================================================

    $ProvPath = Join-Path $Repo `
        'docs\release_integration\module_2_g3_v2_1\R18_PUBLIC_PROJECTION_PROVENANCE.json'

    $Prov = Get-Content -LiteralPath $ProvPath -Raw |
        ConvertFrom-Json

    $Excluded = @(
        $Prov.excluded_private_files |
        ForEach-Object {
            ([string]$_.path).Replace('\','/')
        }
    )

    $ExcludedPresent = @(
        $Excluded |
        Where-Object {
            $IndexSet.ContainsKey($_.ToLowerInvariant())
        }
    )

    Add-Check `
        'AUTHORITATIVE_R22_EXCLUSION_COUNT' `
        ($Excluded.Count -eq 11) `
        "$($Excluded.Count)" `
        '11'

    Add-Check `
        'AUTHORITATIVE_R22_ABSENT_FROM_INDEX' `
        ($ExcludedPresent.Count -eq 0) `
        "$($ExcludedPresent.Count)" `
        '0'

    # ============================================================
    # 7. Re-run validators from certified staged working state
    # ============================================================

    $Python = (Get-Command python.exe -ErrorAction Stop).Source

    function Run-Validator {
        param(
            [string]$Label,
            [string]$Rel,
            [string]$Expected1,
            [string]$Expected2
        )

        Push-Location $Repo
        try {
            $out = @(
                & $Python (Join-Path $Repo $Rel) 2>&1
            )
            $code = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $out |
            Set-Content `
                -LiteralPath (Join-Path $EvidenceDir "$Label.txt") `
                -Encoding UTF8

        $text = $out -join "`n"

        Add-Check `
            $Label `
            (
                $code -eq 0 -and
                $text.Contains($Expected1) -and
                $text.Contains($Expected2)
            ) `
            "ExitCode=$code" `
            "ExitCode=0; $Expected1; $Expected2"
    }

    Run-Validator `
        'PUBLIC_RELEASE_VALIDATOR' `
        'tools\validate_public_release.py' `
        'Public release validation PASS' `
        'Governed manifest files: 2880'

    Run-Validator `
        'RC1_OVERLAY_VALIDATOR' `
        'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py' `
        'Candidate overlay validation PASS' `
        'Governed candidate files: 235'

    Run-Validator `
        'RC2_OVERLAY_VALIDATOR' `
        'successor_candidates\m2-g3-v2.1.0-rc2\tools\validate_candidate_overlay.py' `
        'Candidate overlay validation PASS' `
        'Governed candidate files: 248'

    # ============================================================
    # 8. Reconfirm validators caused no mutation
    # ============================================================

    $PostValidatorUnstaged = @(
        & git -C $Repo diff --name-only
    )

    $PostValidatorCached = @(
        & git -C $Repo diff --cached --name-only
    )

    $CachedDelta = @(
        Compare-Object `
            ($CachedPaths | Sort-Object) `
            ($PostValidatorCached | Sort-Object)
    )

    Add-Check `
        'VALIDATORS_NO_WORKTREE_MUTATION' `
        ($PostValidatorUnstaged.Count -eq 0) `
        "$($PostValidatorUnstaged.Count)" `
        '0'

    Add-Check `
        'VALIDATORS_NO_INDEX_PATH_MUTATION' `
        ($CachedDelta.Count -eq 0) `
        "$($CachedDelta.Count)" `
        '0'

    # Materialize tree again: strongest post-validator index check.
    $IndexTreeAfterValidators = (
        & git -C $Repo write-tree
    ).Trim().ToLowerInvariant()

    Add-Check `
        'VALIDATORS_NO_INDEX_TREE_MUTATION' `
        ($IndexTreeAfterValidators -ceq $IndexTree) `
        $IndexTreeAfterValidators `
        $IndexTree

    # ============================================================
    # 9. Correct treatment of git diff --cached --check
    #
    # Diagnostic only. Do NOT impose the invalid <=3-file threshold.
    # Preserve complete output and summarize only true Git diagnostic
    # header lines.
    # ============================================================

    $DiffCheck = @(
        & git -C $Repo diff --cached --check
    )
    $DiffCheckExit = $LASTEXITCODE

    $DiffCheck |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'STAGED_GIT_DIFF_CHECK_DIAGNOSTIC.txt'
            ) `
            -Encoding UTF8

    # True diagnostic header lines end in known git --check messages.
    # Added content lines are deliberately excluded from path parsing.
    $HeaderPattern = `
        '^(.*?):(\d+): (trailing whitespace\.|space before tab in indent\.|new blank line at EOF\.)$'

    $DiagnosticRows = New-Object System.Collections.Generic.List[object]

    foreach ($line in $DiffCheck) {
        if ($line -match $HeaderPattern) {
            $DiagnosticRows.Add([pscustomobject]@{
                Path    = $Matches[1]
                Line    = [int]$Matches[2]
                Finding = $Matches[3]
            })
        }
    }

    $TrueAffectedFiles = @(
        $DiagnosticRows.Path |
        Sort-Object -Unique
    )

    $DiagnosticRows |
        Export-Csv `
            -LiteralPath (
                Join-Path $EvidenceDir 'STAGED_DIFF_CHECK_PARSED_DIAGNOSTICS.csv'
            ) `
            -NoTypeInformation `
            -Encoding UTF8

    @(
        "Raw output lines: $($DiffCheck.Count)"
        "Parsed diagnostic findings: $($DiagnosticRows.Count)"
        "True affected paths: $($TrueAffectedFiles.Count)"
        "git diff --cached --check exit code: $DiffCheckExit"
        ""
        "DISPOSITION:"
        "DIAGNOSTIC_ONLY"
        "The staged index was independently certified against exact approved R6."
        "No threshold is applied to pre-existing/source-bound whitespace diagnostics."
    ) |
        Set-Content `
            -LiteralPath (
                Join-Path $EvidenceDir 'STAGED_DIFF_CHECK_DISPOSITION.txt'
            ) `
            -Encoding UTF8

    Add-Check `
        'STAGED_DIFF_CHECK_CAPTURED_AND_SOURCE_BOUND' `
        (
            $BlobMismatchCount -eq 0 -and
            $BlobErrorCount -eq 0 -and
            $IndexTreeAfterValidators -ceq $IndexTree
        ) `
        "RawLines=$($DiffCheck.Count);ParsedFindings=$($DiagnosticRows.Count);AffectedPaths=$($TrueAffectedFiles.Count);ExitCode=$DiffCheckExit;IndexBlobMismatch=0" `
        'diagnostic captured; exact-R6 index independently certified'

    # ============================================================
    # 10. Final fail-closed decision — still NO COMMIT
    # ============================================================

    $Failures = @(
        $Checks | Where-Object Status -eq 'FAIL'
    )

    $Status = if ($Failures.Count -eq 0) {
        'PASS'
    }
    else {
        'FAIL'
    }

    Write-Register

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_PHASE_F_R2_CORRECTED_STAGED_OBJECT_CERTIFICATION'

        Repository = $Repo
        SourceStage = $Stage
        PriorPhaseF = $PriorF
        EvidenceDirectory = $EvidenceDir

        Head = $Head
        Branch = $Branch

        R6FileCount = $StageInv.Count
        CheckoutFileCount = $RepoInv.Count
        IndexPathCount = $IndexPaths.Count
        StagedDeltaPathCount = $CachedPaths.Count

        RawR6MismatchCount = $Mismatch

        IndexBlobCertificationRows = $BlobRows.Count
        IndexBlobMismatchCount = $BlobMismatchCount
        IndexBlobErrorCount = $BlobErrorCount

        CertifiedIndexTree = $IndexTree
        CertifiedIndexTreePathCount = $TreePathCount

        AuthoritativeR22ExcludedCount = $Excluded.Count
        AuthoritativeR22PresentInIndex = $ExcludedPresent.Count

        DiffCheckRawLineCount = $DiffCheck.Count
        DiffCheckParsedFindingCount = $DiagnosticRows.Count
        DiffCheckAffectedPathCount = $TrueAffectedFiles.Count
        DiffCheckExitCode = $DiffCheckExit
        DiffCheckDisposition = `
            'DIAGNOSTIC_ONLY_SOURCE_BOUND_TO_EXACT_CERTIFIED_R6_INDEX'

        CheckCount = $Checks.Count
        FailureCount = $Failures.Count
        FailedChecks = @(
            $Failures |
            Select-Object Check,Expected,Actual
        )

        StagingAlreadyPresent = $true
        AdditionalStagingPerformed = $false
        CommitPerformed = $false
        TagPerformed = $false
        PushPerformed = $false
        PublicationPerformed = $false

        PhaseFR2 = $Status
    }

    $ReceiptPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_F_R2_STAGED_OBJECT_CERTIFICATION_RECEIPT.json'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content `
            -LiteralPath $ReceiptPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "PHASE_F_R2 = $Status"
    Write-Host "============================================================"
    Write-Host "HEAD:                    $Head"
    Write-Host "R6 files:                $($StageInv.Count)"
    Write-Host "Checkout files:          $($RepoInv.Count)"
    Write-Host "Index paths:             $($IndexPaths.Count)"
    Write-Host "Staged delta paths:      $($CachedPaths.Count)"
    Write-Host ""
    Write-Host "Index blob mismatches:   $BlobMismatchCount"
    Write-Host "Index blob errors:       $BlobErrorCount"
    Write-Host "Certified index tree:    $IndexTree"
    Write-Host "Index tree paths:        $TreePathCount"
    Write-Host ""
    Write-Host "R22 present in index:    $($ExcludedPresent.Count)"
    Write-Host ""
    Write-Host "Diff-check raw lines:    $($DiffCheck.Count)"
    Write-Host "Parsed findings:         $($DiagnosticRows.Count)"
    Write-Host "True affected paths:     $($TrueAffectedFiles.Count)"
    Write-Host "Diff-check disposition:  DIAGNOSTIC / SOURCE-BOUND"
    Write-Host ""
    Write-Host "Checks:                  $($Checks.Count)"
    Write-Host "Failures:                $($Failures.Count)"
    Write-Host ""
    Write-Host "Commit performed:        NO"
    Write-Host "Tag performed:           NO"
    Write-Host "Push performed:          NO"
    Write-Host "Publication performed:   NO"
    Write-Host ""
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"

    if ($Failures.Count -gt 0) {
        Write-Host ""
        Write-Host "FAILED CHECKS:"
        $Failures | Format-Table -AutoSize | Out-Host
    }

    Write-Host ""
    Write-Host "STOP HERE."
    Write-Host "Do NOT commit, tag, push, or publish."
}
```

The critical new control is `R6_TO_INDEX_BLOB_CERTIFICATION`. That closes a subtle gap in my first Phase F design: merely knowing the working tree equals R6 and `git diff` shows no worktree/index difference is strong, but it does not independently prove every **index blob object** corresponds to R6 under `.gitattributes`/clean-filter semantics. F-R2 does that for all **2,884 files** before we authorize the local commit.

A successful result should therefore look broadly like:

```text
PHASE_F_R2 = PASS

R6 files:                2884
Checkout files:          2884
Index paths:             2884
Staged delta paths:      966

Index blob mismatches:   0
Index blob errors:       0
Certified index tree:    <TREE OBJECT ID>
Index tree paths:        2884

R22 present in index:    0

Diff-check raw lines:    ~42098
Parsed findings:         <correct diagnostic count>
True affected paths:     <correct path count>
Diff-check disposition:  DIAGNOSTIC / SOURCE-BOUND

Failures:                0

Commit performed:        NO
Tag performed:           NO
Push performed:          NO
Publication performed:   NO
```

**Do not manually clean any whitespace and do not alter `MANIFEST.csv` or the historical records.** Those bytes are part of the accepted R6 tree; changing them at this point would create a new, unaudited release tree. If F-R2 passes, I will give you a very small Phase F-R3 operation that creates the local publication commit from the already-certified tree and then proves the commit's tree ID equals this exact certified `write-tree` object before we advance toward tag/push.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e31a9a6c-f2d3-4036-9973-b01dc09c3937"></a>
## Andrew / user · C123-M00077

C123-M00077 · 2026-09-10T09:05:44.925000-04:00 · active path

Preceding visible parent: [C123-M00076](part-08.md#m-333b28d9-f28c-4035-b617-b255249e8a02)

<!-- BEGIN_SOURCE_MESSAGE -->
how long do we expect F-R2 to run? It has said, "Certifying all 2,884 Git index blobs against R6..." for about 10 minutes now.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bc1eb419-f9c7-46fb-96a3-a65e8f376477"></a>
## Assistant · C123-M00078

C123-M00078 · 2026-09-10T09:05:50.261051-04:00 · active path

Preceding visible parent: [C123-M00077](part-08.md#m-e31a9a6c-f2d3-4036-9973-b01dc09c3937)

<!-- BEGIN_SOURCE_MESSAGE -->
Ten minutes at that step is longer than I would have expected, but it is not automatically a problem.

That loop is expensive because it runs **two Git subprocesses per file** across 2,884 files:

- `git hash-object --path=...` once per file
- `git ls-files -s -- ...` once per file

So we are launching roughly **5,768 Git processes**. On Windows, especially with antivirus/Defender and a large repository, process startup overhead dominates. That can easily push runtime into the **10–30 minute range**, and potentially longer on an older machine or slower disk.

I would use this rule:

- **<15 minutes:** normal enough; let it continue.
- **15–30 minutes:** slow, but still plausible.
- **>30 minutes with no visible progress:** I would consider stopping it and replacing that section with a much more efficient bulk implementation.
- **>45 minutes:** I would stop it unless Task Manager clearly shows sustained `git.exe`/PowerShell CPU or disk activity.

The important point is that the script is not necessarily hung; it just has no progress output inside that loop.

You can safely inspect activity **without interrupting it**. Open another PowerShell and run:

```powershell
Get-Process git,powershell,pwsh -ErrorAction SilentlyContinue |
    Select-Object ProcessName,Id,CPU,WorkingSet,StartTime |
    Sort-Object ProcessName,Id
```

And optionally:

```powershell
Get-Counter '\PhysicalDisk(_Total)\Disk Bytes/sec',
            '\Processor(_Total)\% Processor Time' `
    -SampleInterval 2 `
    -MaxSamples 5
```

If you see `git.exe` processes appearing/changing and some CPU/disk activity, it is progressing.

I would **not stop it yet at 10 minutes**. Give it another 10–15 minutes. If it reaches around 25–30 minutes still sitting on the same message, tell me before killing it; I can give you a dramatically faster F-R2 replacement that performs the same certification using bulk Git operations instead of thousands of subprocess launches.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ef716608-7469-4db2-af00-123d22e2c1ea"></a>
## Andrew / user · C123-M00079

C123-M00079 · 2026-09-10T09:13:41.760000-04:00 · active path

Preceding visible parent: [C123-M00078](part-08.md#m-bc1eb419-f9c7-46fb-96a3-a65e8f376477)

**Editorial record note:** Attachment references: PHASE_F_R2_CHECK_REGISTER.csv; PUBLIC_RELEASE_VALIDATOR(2).txt; R6_TO_INDEX_BLOB_CERTIFICATION.csv; RC1_OVERLAY_VALIDATOR(2).txt; RC2_OVERLAY_VALIDATOR(2).txt; STAGED_DIFF_CHECK_DISPOSITION.txt; STAGED_DIFF_CHECK_PARSED_DIAGNOSTICS.csv; STAGED_GIT_DIFF_CHECK_DIAGNOSTIC(1).txt; CERTIFIED_INDEX_TREE.txt; MSBF_PHASE_F_R2_STAGED_OBJECT_CERTIFICATION_RECEIPT.json

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE F-R2 — CORRECTED STAGED-OBJECT CERTIFICATION
============================================================
Repository:      D:\x\m
R6 stage:        D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94
Prior Phase F:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_F_20260910T124937642Z_bdc3094b
Evidence:        D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_F_R2_20260910T125503493Z_856501ea

Hashing exact R6 source...
Hashing checkout...
Certifying all 2,884 Git index blobs against R6...

============================================================
PHASE_F_R2 = PASS
============================================================
HEAD:                    46fb1f9198475678edc9cabdeefd2f91a59e49c2
R6 files:                2884
Checkout files:          2884
Index paths:             2884
Staged delta paths:      966

Index blob mismatches:   0
Index blob errors:       0
Certified index tree:    fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb
Index tree paths:        2884

R22 present in index:    0

Diff-check raw lines:    42098
Parsed findings:         21050
True affected paths:     102
Diff-check disposition:  DIAGNOSTIC / SOURCE-BOUND

Checks:                  21
Failures:                0

Commit performed:        NO
Tag performed:           NO
Push performed:          NO
Publication performed:   NO

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_F_R2_20260910T125503493Z_856501ea\MSBF_PHASE_F_R2_STAGED_OBJECT_CERTIFICATION_RECEIPT.json
============================================================

STOP HERE.
Do NOT commit, tag, push, or publish.
<!-- END_SOURCE_MESSAGE -->
