# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 04 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-03.md)
[Next part](part-05.md)

<a id="m-2b039d52-441a-4e68-8068-d007650eb9a3"></a>
## Assistant · C123-M00054

C123-M00054 · 2026-09-10T07:59:32.521161-04:00 · active path

Preceding visible parent: [C123-M00053](part-03.md#m-faf9aae8-5f4a-435a-ae3e-9ffb12487797)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase A is closed with an exact PASS.** The physical receipt confirms all five inputs matched their required filenames, byte sizes, SHA-256 identities, and expected ZIP-entry counts, with before/after nonmutation. [export reference: filecite | turn20file0 | L20-L24] The four release carriers and R6 each passed the full entry-stream readability check; R6 is exactly 279,632,507 bytes with SHA-256 `31611a…d0bf2` and 2,884 entries. [export reference: filecite | turn20file0 | L159-L188]

So we can record:

```text
RELEASE_ASSET_PREFLIGHT = PASS
R20-PRE-03 / release-carrier identity portion = PASS
```

The receipt correctly leaves Git, extraction, publication, hosted verification, and anonymous navigation unperformed. [export reference: filecite | turn20file0 | L192-L203]

We now move to **Phase B: fresh Git / remote / historical-tag preflight**. This block is intentionally **read-only with respect to the checkout and local Git refs**—I am using `git ls-remote` rather than `git fetch` first, so if the live public predecessor differs from the recorded R20 references we stop **before changing even remote-tracking refs**. R20 requires fresh Git/base/tag verification and preservation of the historical tag before publication. [export reference: filecite | turn19file5 | L15-L22]

Paste this entire block into the **same PowerShell window**:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'

    $ExpectedRemoteMain = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'
    $OldTag = 'module-2-g3-v2.0.0'
    $ExpectedOldTagObject = 'fcf32b615142a06075a7fccede26a97042ca8194'
    $ExpectedOldTagCommit = '500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65'
    $NewTag = 'module-2-g3-v2.1.0'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_B_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    function Invoke-GitCapture {
        param(
            [Parameter(Mandatory=$true)][string[]]$Args,
            [switch]$AllowFailure
        )

        $output = & git -C $Repo @Args 2>&1
        $code = $LASTEXITCODE

        if (($code -ne 0) -and (-not $AllowFailure)) {
            throw "git $($Args -join ' ') failed with exit code $code`n$($output -join "`n")"
        }

        [pscustomobject]@{
            Command  = "git -C `"$Repo`" $($Args -join ' ')"
            ExitCode = $code
            Output   = @($output | ForEach-Object { "$_" })
        }
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE B — READ-ONLY GIT / REMOTE / TAG PREFLIGHT"
    Write-Host "============================================================"
    Write-Host "Repository: $Repo"
    Write-Host "Evidence:   $EvidenceDir"
    Write-Host ""

    if (-not (Test-Path -LiteralPath $Repo -PathType Container)) {
        throw "Repository directory not found: $Repo"
    }

    $GitVersion = (& git --version 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "Git is not available in this PowerShell session."
    }

    $RootResult = Invoke-GitCapture @('rev-parse','--show-toplevel')
    $RepoRoot = ($RootResult.Output | Select-Object -First 1).Trim()

    $ExpectedRepoNormalized = (
        [System.IO.Path]::GetFullPath($Repo).TrimEnd('\')
    ).Replace('\','/')

    $ActualRepoNormalized = (
        [System.IO.Path]::GetFullPath($RepoRoot).TrimEnd('\')
    ).Replace('\','/')

    if ($ActualRepoNormalized -ine $ExpectedRepoNormalized) {
        throw "Unexpected Git repository root. Expected $ExpectedRepoNormalized ; actual $ActualRepoNormalized"
    }

    $BranchResult = Invoke-GitCapture @('branch','--show-current')
    $CurrentBranch = ($BranchResult.Output | Select-Object -First 1).Trim()

    $StatusBranch = Invoke-GitCapture @('status','--short','--branch')
    $Porcelain = Invoke-GitCapture @('status','--porcelain=v1')

    $WorkingTreeClean = ($Porcelain.Output.Count -eq 0)

    $HeadResult = Invoke-GitCapture @('rev-parse','HEAD')
    $LocalHead = ($HeadResult.Output | Select-Object -First 1).Trim().ToLowerInvariant()

    $OriginUrlResult = Invoke-GitCapture @('remote','get-url','origin')
    $OriginUrl = ($OriginUrlResult.Output | Select-Object -First 1).Trim()

    $OriginMainResult = Invoke-GitCapture @('rev-parse','--verify','refs/remotes/origin/main') -AllowFailure
    $LocalOriginMain = if ($OriginMainResult.ExitCode -eq 0) {
        ($OriginMainResult.Output | Select-Object -First 1).Trim().ToLowerInvariant()
    } else {
        $null
    }

    $BranchVV = Invoke-GitCapture @('branch','-vv')
    $AutoCrlf = Invoke-GitCapture @('config','--get','core.autocrlf') -AllowFailure
    $LongPaths = Invoke-GitCapture @('config','--get','core.longpaths') -AllowFailure
    $RecentGraph = Invoke-GitCapture @('log','--oneline','--decorate','--graph','-n','20','--all')

    # ----- Historical local tag -----

    $OldLocalTagObjectResult = Invoke-GitCapture @(
        'rev-parse',
        "$OldTag^{tag}"
    ) -AllowFailure

    $OldLocalTagCommitResult = Invoke-GitCapture @(
        'rev-parse',
        "$OldTag^{commit}"
    ) -AllowFailure

    $OldLocalTagObject = if ($OldLocalTagObjectResult.ExitCode -eq 0) {
        ($OldLocalTagObjectResult.Output | Select-Object -First 1).Trim().ToLowerInvariant()
    } else {
        $null
    }

    $OldLocalTagCommit = if ($OldLocalTagCommitResult.ExitCode -eq 0) {
        ($OldLocalTagCommitResult.Output | Select-Object -First 1).Trim().ToLowerInvariant()
    } else {
        $null
    }

    # ----- New tag MUST NOT already exist locally -----

    $NewLocalTagResult = Invoke-GitCapture @(
        'show-ref',
        '--verify',
        "refs/tags/$NewTag"
    ) -AllowFailure

    $NewTagExistsLocally = ($NewLocalTagResult.ExitCode -eq 0)

    # ----- Fresh REMOTE reads — no local ref update -----

    $RemoteMainRaw = & git -C $Repo ls-remote origin refs/heads/main 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Fresh remote main query failed:`n$($RemoteMainRaw -join "`n")"
    }

    $RemoteMainLine = @($RemoteMainRaw) |
        Where-Object { "$_" -match '\s+refs/heads/main$' } |
        Select-Object -First 1

    if (-not $RemoteMainLine) {
        throw "Remote origin did not return refs/heads/main."
    }

    $RemoteMain = (("$RemoteMainLine" -split '\s+')[0]).ToLowerInvariant()

    $OldRemoteRaw = & git -C $Repo ls-remote origin `
        "refs/tags/$OldTag" `
        "refs/tags/$OldTag^{}" 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Fresh historical-tag query failed:`n$($OldRemoteRaw -join "`n")"
    }

    $OldRemoteObjectLine = @($OldRemoteRaw) |
        Where-Object { "$_" -match "refs/tags/$([regex]::Escape($OldTag))$" } |
        Select-Object -First 1

    $OldRemoteCommitLine = @($OldRemoteRaw) |
        Where-Object { "$_" -match "refs/tags/$([regex]::Escape($OldTag))\^\{\}$" } |
        Select-Object -First 1

    if (-not $OldRemoteObjectLine) {
        throw "Historical remote tag object not found: $OldTag"
    }

    if (-not $OldRemoteCommitLine) {
        throw "Historical tag did not return a peeled commit. Expected an annotated tag."
    }

    $OldRemoteTagObject = (
        ("$OldRemoteObjectLine" -split '\s+')[0]
    ).ToLowerInvariant()

    $OldRemoteTagCommit = (
        ("$OldRemoteCommitLine" -split '\s+')[0]
    ).ToLowerInvariant()

    $NewRemoteRaw = & git -C $Repo ls-remote origin "refs/tags/$NewTag" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Fresh proposed-new-tag query failed:`n$($NewRemoteRaw -join "`n")"
    }

    $NewTagExistsRemotely = (
        @($NewRemoteRaw | Where-Object { "$_".ToString().Trim().Length -gt 0 }).Count -gt 0
    )

    # ----- Exact reference comparisons -----

    $Checks = @(
        [pscustomobject]@{
            Check = 'REPOSITORY_ROOT'
            Expected = $ExpectedRepoNormalized
            Actual = $ActualRepoNormalized
            Status = if ($ActualRepoNormalized -ieq $ExpectedRepoNormalized) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'WORKING_TREE_CLEAN'
            Expected = 'TRUE'
            Actual = "$WorkingTreeClean"
            Status = if ($WorkingTreeClean) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'CURRENT_BRANCH'
            Expected = 'main'
            Actual = $CurrentBranch
            Status = if ($CurrentBranch -ceq 'main') {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'FRESH_REMOTE_MAIN'
            Expected = $ExpectedRemoteMain
            Actual = $RemoteMain
            Status = if ($RemoteMain -ceq $ExpectedRemoteMain) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'OLD_REMOTE_TAG_OBJECT'
            Expected = $ExpectedOldTagObject
            Actual = $OldRemoteTagObject
            Status = if ($OldRemoteTagObject -ceq $ExpectedOldTagObject) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'OLD_REMOTE_TAG_PEELED_COMMIT'
            Expected = $ExpectedOldTagCommit
            Actual = $OldRemoteTagCommit
            Status = if ($OldRemoteTagCommit -ceq $ExpectedOldTagCommit) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'OLD_LOCAL_TAG_OBJECT'
            Expected = $ExpectedOldTagObject
            Actual = $OldLocalTagObject
            Status = if ($OldLocalTagObject -ceq $ExpectedOldTagObject) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'OLD_LOCAL_TAG_PEELED_COMMIT'
            Expected = $ExpectedOldTagCommit
            Actual = $OldLocalTagCommit
            Status = if ($OldLocalTagCommit -ceq $ExpectedOldTagCommit) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'NEW_TAG_ABSENT_LOCALLY'
            Expected = 'TRUE'
            Actual = "$(-not $NewTagExistsLocally)"
            Status = if (-not $NewTagExistsLocally) {'PASS'} else {'FAIL'}
        }

        [pscustomobject]@{
            Check = 'NEW_TAG_ABSENT_REMOTELY'
            Expected = 'TRUE'
            Actual = "$(-not $NewTagExistsRemotely)"
            Status = if (-not $NewTagExistsRemotely) {'PASS'} else {'FAIL'}
        }
    )

    $HardFailures = @($Checks | Where-Object Status -ne 'PASS')

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_B_GIT_PREFLIGHT'
        GoverningDecision = 'IA-D-R20-INT-001'
        ConditionalAuthority = 'IA-PUB-R20-INTEGRATED-001'
        EvidenceDirectory = $EvidenceDir
        Repository = $Repo
        GitVersion = "$GitVersion"
        RepoRoot = $RepoRoot
        CurrentBranch = $CurrentBranch
        LocalHead = $LocalHead
        LocalOriginMain = $LocalOriginMain
        OriginUrl = $OriginUrl
        WorkingTreeClean = $WorkingTreeClean
        FreshRemoteMain = $RemoteMain
        RecordedRemoteMain = $ExpectedRemoteMain
        OldTag = $OldTag
        OldLocalTagObject = $OldLocalTagObject
        OldLocalTagPeeledCommit = $OldLocalTagCommit
        OldRemoteTagObject = $OldRemoteTagObject
        OldRemoteTagPeeledCommit = $OldRemoteTagCommit
        NewTag = $NewTag
        NewTagExistsLocally = $NewTagExistsLocally
        NewTagExistsRemotely = $NewTagExistsRemotely
        CoreAutoCrlf = @($AutoCrlf.Output)
        CoreLongPaths = @($LongPaths.Output)
        Checks = $Checks
        StatusShortBranch = @($StatusBranch.Output)
        BranchesAndUpstreams = @($BranchVV.Output)
        RecentGraph = @($RecentGraph.Output)
        Mutation = 'NONE'
        FetchPerformed = $false
        TagMutationPerformed = $false
        CheckoutMutationPerformed = $false
        PhaseBStatus = if ($HardFailures.Count -eq 0) {
            'PASS'
        } else {
            'HOLD'
        }
    }

    $JsonPath = Join-Path $EvidenceDir 'MSBF_PHASE_B_GIT_REMOTE_TAG_PREFLIGHT.json'
    $CsvPath = Join-Path $EvidenceDir 'MSBF_PHASE_B_CHECKS.csv'
    $TxtPath = Join-Path $EvidenceDir 'MSBF_PHASE_B_SUMMARY.txt'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $JsonPath -Encoding UTF8

    $Checks |
        Export-Csv -LiteralPath $CsvPath -NoTypeInformation -Encoding UTF8

    $Summary = @()
    $Summary += "PHASE_B_GIT_PREFLIGHT = $($Receipt.PhaseBStatus)"
    $Summary += "Repository: $RepoRoot"
    $Summary += "Branch: $CurrentBranch"
    $Summary += "Working tree clean: $WorkingTreeClean"
    $Summary += "Local HEAD: $LocalHead"
    $Summary += "Local origin/main: $LocalOriginMain"
    $Summary += "Fresh remote main: $RemoteMain"
    $Summary += "Origin: $OriginUrl"
    $Summary += ""
    $Summary += "Historical tag object:"
    $Summary += "  local : $OldLocalTagObject"
    $Summary += "  remote: $OldRemoteTagObject"
    $Summary += ""
    $Summary += "Historical peeled commit:"
    $Summary += "  local : $OldLocalTagCommit"
    $Summary += "  remote: $OldRemoteTagCommit"
    $Summary += ""
    $Summary += "New tag exists locally: $NewTagExistsLocally"
    $Summary += "New tag exists remotely: $NewTagExistsRemotely"
    $Summary += ""
    $Summary += "Checks:"
    foreach ($c in $Checks) {
        $Summary += "  [$($c.Status)] $($c.Check)"
    }
    $Summary += ""
    $Summary += "No fetch, checkout mutation, commit, tag creation, push, or publication performed."

    $Summary |
        Set-Content -LiteralPath $TxtPath -Encoding UTF8

    Write-Host ""
    $Checks | Format-Table -AutoSize
    Write-Host ""
    $Summary | ForEach-Object { Write-Host $_ }
    Write-Host ""
    Write-Host "Receipt: $JsonPath"

    if ($HardFailures.Count -gt 0) {
        throw "PHASE_B_GIT_PREFLIGHT = HOLD. Stop. Do not mutate the repository."
    }

    Write-Host ""
    Write-Host "PHASE_B_GIT_PREFLIGHT = PASS"
    Write-Host "Stop here and return the JSON receipt and console summary."
}
```

### What constitutes a PASS

At this gate I expect:

```text
Repository root                         D:/x/m
Current branch                          main
Working tree                            clean
Fresh remote main                       46fb1f9198475678edc9cabdeefd2f91a59e49c2

Historical v2.0.0 tag object            fcf32b615142a06075a7fccede26a97042ca8194
Historical v2.0.0 peeled commit         500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

module-2-g3-v2.1.0 local tag             absent
module-2-g3-v2.1.0 remote tag            absent
```

Those historical identities are R20 **reference values until freshly verified**, exactly as the authority records them. [export reference: filecite | turn19file6 | L13-L19]

If the block returns `HOLD`, **do not correct anything yourself**—even if the difference looks trivial. Paste the output here. In particular, do not checkout another branch, reset, pull, fetch, delete a tag, or clean the working tree.

If it returns:

```text
PHASE_B_GIT_PREFLIGHT = PASS
```

send me the generated JSON plus the final console summary. I’ll reconcile it, then we can proceed to the **clean R6 staging/extraction gate** before touching `D:\x\m`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-38201f8f-21dd-45ad-97dd-3678874f4ae5"></a>
## Andrew / user · C123-M00055

C123-M00055 · 2026-09-10T08:06:24.283000-04:00 · active path

Preceding visible parent: [C123-M00054](part-04.md#m-2b039d52-441a-4e68-8068-d007650eb9a3)

**Editorial record note:** Attachment references: MSBF_PHASE_B_GIT_REMOTE_TAG_PREFLIGHT.json; MSBF_PHASE_B_SUMMARY.txt; MSBF_PHASE_B_CHECKS.csv

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE B — READ-ONLY GIT / REMOTE / TAG PREFLIGHT
============================================================
Repository: D:\x\m
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_B_20260910T120548506Z_ff83ed61



Check                        Expected                                 Actual                                   Status
-----                        --------                                 ------                                   ------
REPOSITORY_ROOT              D:/x/m                                   D:/x/m                                   PASS
WORKING_TREE_CLEAN           TRUE                                     True                                     PASS
CURRENT_BRANCH               main                                     main                                     PASS
FRESH_REMOTE_MAIN            46fb1f9198475678edc9cabdeefd2f91a59e49c2 46fb1f9198475678edc9cabdeefd2f91a59e49c2 PASS
OLD_REMOTE_TAG_OBJECT        fcf32b615142a06075a7fccede26a97042ca8194 fcf32b615142a06075a7fccede26a97042ca8194 PASS
OLD_REMOTE_TAG_PEELED_COMMIT 500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65 500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65 PASS
OLD_LOCAL_TAG_OBJECT         fcf32b615142a06075a7fccede26a97042ca8194 fcf32b615142a06075a7fccede26a97042ca8194 PASS
OLD_LOCAL_TAG_PEELED_COMMIT  500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65 500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65 PASS
NEW_TAG_ABSENT_LOCALLY       TRUE                                     True                                     PASS
NEW_TAG_ABSENT_REMOTELY      TRUE                                     True                                     PASS


PHASE_B_GIT_PREFLIGHT = PASS
Repository: D:/x/m
Branch: main
Working tree clean: True
Local HEAD: 46fb1f9198475678edc9cabdeefd2f91a59e49c2
Local origin/main: 46fb1f9198475678edc9cabdeefd2f91a59e49c2
Fresh remote main: 46fb1f9198475678edc9cabdeefd2f91a59e49c2
Origin: https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git

Historical tag object:
  local : fcf32b615142a06075a7fccede26a97042ca8194
  remote: fcf32b615142a06075a7fccede26a97042ca8194

Historical peeled commit:
  local : 500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
  remote: 500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

New tag exists locally: False
New tag exists remotely: False

Checks:
  [PASS] REPOSITORY_ROOT
  [PASS] WORKING_TREE_CLEAN
  [PASS] CURRENT_BRANCH
  [PASS] FRESH_REMOTE_MAIN
  [PASS] OLD_REMOTE_TAG_OBJECT
  [PASS] OLD_REMOTE_TAG_PEELED_COMMIT
  [PASS] OLD_LOCAL_TAG_OBJECT
  [PASS] OLD_LOCAL_TAG_PEELED_COMMIT
  [PASS] NEW_TAG_ABSENT_LOCALLY
  [PASS] NEW_TAG_ABSENT_REMOTELY

No fetch, checkout mutation, commit, tag creation, push, or publication performed.

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_B_20260910T120548506Z_ff83ed61\MSBF_PHASE_B_GIT_REMOTE_TAG_PREFLIGHT.json

PHASE_B_GIT_PREFLIGHT = PASS
Stop here and return the JSON receipt and console summary.
<!-- END_SOURCE_MESSAGE -->


<a id="m-be9236c0-b641-4c5b-93db-0252099e23d8"></a>
## Assistant · C123-M00056

C123-M00056 · 2026-09-10T08:06:26.969089-04:00 · active path

Preceding visible parent: [C123-M00055](part-04.md#m-38201f8f-21dd-45ad-97dd-3678874f4ae5)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase B is closed with an exact PASS.** The uploaded receipt confirms that `D:\x\m` is clean on `main`, local HEAD, local `origin/main`, and fresh remote `main` are all exactly `46fb1f9…e49c2`; the historical v2.0.0 annotated tag object and peeled commit match both locally and remotely; and the proposed v2.1.0 tag is absent locally and remotely. No Git mutation occurred. [export reference: filecite | turn21file0 | L9-L24] [export reference: filecite | turn21file0 | L113-L117]

We can therefore record:

```text
PHASE_B_GIT_PREFLIGHT = PASS
R20-PRE-04 = PASS
```

This exactly satisfies R20's fresh Git/base and historical-tag preflight requirement. [export reference: filecite | turn19file6 | L73-L76]

Now proceed to **Phase C: cleanly materialize R6 into a separate staging tree and validate it before touching `D:\x\m`**.

Use the **same PowerShell window**. Do **not** `cd D:\x\m`. Paste this complete block:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $R6Zip = 'D:\MSBF_ZIP_FILES_091026\MSBF_FINAL_INTEGRATED_PUBLICATION_CANDIDATE_R6_20260910_FINAL_MICROPOLISH.zip'
    $ExpectedR6Bytes = 279632507
    $ExpectedR6Sha256 = '31611a7c90ad7a0b597ecc3c0a5592c2aa7c031a82b5c7fbcc40750c8e8d0bf2'
    $ExpectedMembers = 2884

    $ExpectedPbixBytes = 27635305
    $ExpectedPbixSha256 = 'ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)

    $Stage = "D:\MSBF_RELEASE_R6_STAGING_${Stamp}_${Suffix}"
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE C — R6 CLEAN STAGING / VALIDATION"
    Write-Host "============================================================"
    Write-Host "R6 ZIP:    $R6Zip"
    Write-Host "Staging:   $Stage"
    Write-Host "Evidence:  $EvidenceDir"
    Write-Host ""

    # ---------------------------------------------------------
    # 1. Reconfirm R6 outer identity before extraction
    # ---------------------------------------------------------

    if (-not (Test-Path -LiteralPath $R6Zip -PathType Leaf)) {
        throw "R6 ZIP not found: $R6Zip"
    }

    $R6Item = Get-Item -LiteralPath $R6Zip
    $R6HashBefore = (Get-FileHash -LiteralPath $R6Zip -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($R6Item.Length -ne $ExpectedR6Bytes) {
        throw "R6 size mismatch. Expected $ExpectedR6Bytes ; actual $($R6Item.Length)"
    }

    if ($R6HashBefore -cne $ExpectedR6Sha256) {
        throw "R6 SHA-256 mismatch. Expected $ExpectedR6Sha256 ; actual $R6HashBefore"
    }

    # ---------------------------------------------------------
    # 2. Inspect ZIP namespace BEFORE writing files
    # ---------------------------------------------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = [System.IO.Compression.ZipFile]::OpenRead($R6Zip)

    try {
        $Entries = @($zip.Entries)

        if ($Entries.Count -ne $ExpectedMembers) {
            throw "R6 member-count mismatch. Expected $ExpectedMembers ; actual $($Entries.Count)"
        }

        $Names = New-Object System.Collections.Generic.List[string]
        $Unsafe = New-Object System.Collections.Generic.List[string]
        $SymlinkLike = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $Entries) {
            $name = $entry.FullName.Replace('\','/')

            if ([string]::IsNullOrWhiteSpace($name)) {
                throw "ZIP contains an empty member name."
            }

            $Names.Add($name)

            if (
                $name.StartsWith('/') -or
                $name.StartsWith('\') -or
                $name -match '^[A-Za-z]:' -or
                $name -split '/' | Where-Object { $_ -eq '..' }
            ) {
                $Unsafe.Add($name)
            }

            # Unix symlink file-type bits, when present.
            $unixMode = (($entry.ExternalAttributes -shr 16) -band 0xF000)
            if ($unixMode -eq 0xA000) {
                $SymlinkLike.Add($name)
            }
        }

        $ExactDupes = @(
            $Names |
            Group-Object |
            Where-Object Count -gt 1 |
            ForEach-Object Name
        )

        $CaseFoldDupes = @(
            $Names |
            Group-Object { $_.ToLowerInvariant() } |
            Where-Object Count -gt 1 |
            ForEach-Object { $_.Group -join ' | ' }
        )

        if ($Unsafe.Count -gt 0) {
            throw "Unsafe ZIP path(s): $($Unsafe -join '; ')"
        }

        if ($ExactDupes.Count -gt 0) {
            throw "Duplicate ZIP member(s): $($ExactDupes -join '; ')"
        }

        if ($CaseFoldDupes.Count -gt 0) {
            throw "Case-fold collision(s): $($CaseFoldDupes -join '; ')"
        }

        if ($SymlinkLike.Count -gt 0) {
            throw "Symlink-like ZIP member(s) found: $($SymlinkLike -join '; ')"
        }

        if (Test-Path -LiteralPath $Stage) {
            throw "Staging path unexpectedly already exists: $Stage"
        }

        New-Item -ItemType Directory -Path $Stage | Out-Null

        # ---------------------------------------------------------
        # 3. Controlled extraction
        # ---------------------------------------------------------

        $StageFull = [System.IO.Path]::GetFullPath($Stage).TrimEnd('\') + '\'

        foreach ($entry in $Entries) {
            $relative = $entry.FullName.Replace('/','\')
            $dest = [System.IO.Path]::GetFullPath((Join-Path $Stage $relative))

            if (-not $dest.StartsWith($StageFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Extraction path escaped staging root: $($entry.FullName)"
            }

            # R6 contains files only, but retain directory-safe logic.
            if ([string]::IsNullOrEmpty($entry.Name)) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                continue
            }

            $parent = Split-Path -Parent $dest
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            $source = $entry.Open()
            try {
                $target = [System.IO.File]::Open(
                    $dest,
                    [System.IO.FileMode]::CreateNew,
                    [System.IO.FileAccess]::Write,
                    [System.IO.FileShare]::None
                )
                try {
                    $source.CopyTo($target)
                }
                finally {
                    $target.Dispose()
                }
            }
            finally {
                $source.Dispose()
            }
        }
    }
    finally {
        $zip.Dispose()
    }

    # ---------------------------------------------------------
    # 4. Extracted-tree count / shape
    # ---------------------------------------------------------

    $StageFiles = @(Get-ChildItem -LiteralPath $Stage -Recurse -File -Force)

    if ($StageFiles.Count -ne $ExpectedMembers) {
        throw "Extracted file count mismatch. Expected $ExpectedMembers ; actual $($StageFiles.Count)"
    }

    # Ensure this is the Git-tree root, not a nested archive wrapper.
    $RootReadme = Join-Path $Stage 'README.md'
    $RootManifest = Join-Path $Stage 'MANIFEST.csv'
    $RootChecksums = Join-Path $Stage 'SHA256SUMS.txt'
    $DocsReadme = Join-Path $Stage 'docs\README.md'
    $CurrentUse = Join-Path $Stage 'docs\guide\CURRENT_USE.md'
    $PublicValidator = Join-Path $Stage 'tools\validate_public_release.py'

    foreach ($required in @(
        $RootReadme,
        $RootManifest,
        $RootChecksums,
        $DocsReadme,
        $CurrentUse,
        $PublicValidator
    )) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            throw "Required R6 root member missing: $required"
        }
    }

    # ---------------------------------------------------------
    # 5. Discover retained overlay validator from physical source
    #    rather than inventing its path
    # ---------------------------------------------------------

    $OverlayHits = @(
        Get-ChildItem -LiteralPath $Stage -Recurse -File -Filter '*.py' |
        Select-String -SimpleMatch 'Candidate overlay validation PASS' |
        Select-Object -ExpandProperty Path -Unique
    )

    if ($OverlayHits.Count -ne 1) {
        throw "Expected exactly one retained candidate-overlay validator containing its PASS string; found $($OverlayHits.Count): $($OverlayHits -join '; ')"
    }

    $OverlayValidator = $OverlayHits[0]

    # ---------------------------------------------------------
    # 6. Locate Python without changing environment
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
        throw "Python launcher not found in this PowerShell session."
    }

    # ---------------------------------------------------------
    # 7. Execute BOTH unchanged validators from R6 root
    # ---------------------------------------------------------

    Push-Location $Stage
    try {
        $PublicOutput = @(& $PythonExe @PythonPrefix $PublicValidator 2>&1)
        $PublicCode = $LASTEXITCODE

        $OverlayOutput = @(& $PythonExe @PythonPrefix $OverlayValidator 2>&1)
        $OverlayCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    if ($PublicCode -ne 0) {
        throw "Public release validator failed with exit code $PublicCode`n$($PublicOutput -join "`n")"
    }

    if ($OverlayCode -ne 0) {
        throw "Candidate overlay validator failed with exit code $OverlayCode`n$($OverlayOutput -join "`n")"
    }

    $PublicText = $PublicOutput -join "`n"
    $OverlayText = $OverlayOutput -join "`n"

    if ($PublicText -notmatch 'Public release validation PASS') {
        throw "Public validator returned code zero but expected PASS text was not found."
    }

    if ($PublicText -notmatch 'Governed manifest files:\s*2880') {
        throw "Public validator did not report 2880 governed manifest files."
    }

    if ($PublicText -notmatch 'Module 2 stage folders:\s*12') {
        throw "Public validator did not report 12 Module 2 stage folders."
    }

    if ($OverlayText -notmatch 'Candidate overlay validation PASS') {
        throw "Overlay validator returned code zero but expected PASS text was not found."
    }

    if ($OverlayText -notmatch 'Governed candidate files:\s*248') {
        throw "Overlay validator did not report 248 governed candidate files."
    }

    # ---------------------------------------------------------
    # 8. Eleven R22 excluded paths must remain absent
    # ---------------------------------------------------------

    $ExcludedLeafNames = @(
        '02_POST_DESKTOP_STRUCTURAL_VALIDATION.json'
    )

    # Strong exact-prefix check for the private R22 evidence directory.
    $PrivateR22Root = Join-Path $Stage 'successor_candidates\m2-g3-v2.1.0-rc2\power_bi\evidence\r22'

    $R22PrivateFiles = @()
    if (Test-Path -LiteralPath $PrivateR22Root) {
        $R22PrivateFiles = @(
            Get-ChildItem -LiteralPath $PrivateR22Root -Recurse -File -Force
        )
    }

    if ($R22PrivateFiles.Count -gt 0) {
        throw "Excluded private R22 evidence directory contains public files: $($R22PrivateFiles.FullName -join '; ')"
    }

    # ---------------------------------------------------------
    # 9. No obvious private carrier / raw-history package leakage
    # ---------------------------------------------------------

    $ForbiddenCarrierPatterns = @(
        '*PRIVATE*.zip',
        '*EVIDENCE_PRIVATE*.zip',
        '*CONTROL_PRIVATE*.zip',
        '*ChatGPT Conversation Log*.pdf',
        '*PART4_RETURN*.zip',
        '*AUDIT_RETURN*.zip'
    )

    $ForbiddenCarriers = New-Object System.Collections.Generic.List[string]

    foreach ($pattern in $ForbiddenCarrierPatterns) {
        Get-ChildItem -LiteralPath $Stage -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object { $ForbiddenCarriers.Add($_.FullName) }
    }

    if ($ForbiddenCarriers.Count -gt 0) {
        throw "Potential private/raw carrier found in public tree: $($ForbiddenCarriers -join '; ')"
    }

    # ---------------------------------------------------------
    # 10. No standalone font files
    # ---------------------------------------------------------

    $FontExtensions = @('.ttf','.otf','.woff','.woff2','.eot')
    $FontFiles = @(
        $StageFiles |
        Where-Object { $FontExtensions -contains $_.Extension.ToLowerInvariant() }
    )

    if ($FontFiles.Count -gt 0) {
        throw "Standalone font file(s) present: $($FontFiles.FullName -join '; ')"
    }

    # ---------------------------------------------------------
    # 11. PBIX identity
    # ---------------------------------------------------------

    $PbixHits = @(
        Get-ChildItem -LiteralPath $Stage -Recurse -File |
        Where-Object Name -eq 'MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix'
    )

    if ($PbixHits.Count -ne 1) {
        throw "Expected exactly one accepted PBIX; found $($PbixHits.Count)."
    }

    $Pbix = $PbixHits[0]
    $PbixHash = (Get-FileHash -LiteralPath $Pbix.FullName -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($Pbix.Length -ne $ExpectedPbixBytes) {
        throw "PBIX size mismatch. Expected $ExpectedPbixBytes ; actual $($Pbix.Length)"
    }

    if ($PbixHash -cne $ExpectedPbixSha256) {
        throw "PBIX SHA-256 mismatch. Expected $ExpectedPbixSha256 ; actual $PbixHash"
    }

    # ---------------------------------------------------------
    # 12. Required public documentation / visual routes exist
    # ---------------------------------------------------------

    $RequiredDocPaths = @(
        'README.md',
        'docs\README.md',
        'docs\guide\CURRENT_USE.md'
    )

    foreach ($relative in $RequiredDocPaths) {
        if (-not (Test-Path -LiteralPath (Join-Path $Stage $relative) -PathType Leaf)) {
            throw "Required public documentation entry point missing: $relative"
        }
    }

    # Confirm expected major public asset families physically exist.
    $ImageFiles = @(
        $StageFiles |
        Where-Object { $_.Extension.ToLowerInvariant() -in @('.png','.jpg','.jpeg','.webp','.svg') }
    )

    if ($ImageFiles.Count -eq 0) {
        throw "No public visual files found in staged tree."
    }

    $PowerBiFiles = @(
        $StageFiles |
        Where-Object { $_.FullName -match '(?i)power[_ -]?bi' }
    )

    if ($PowerBiFiles.Count -eq 0) {
        throw "No Power BI public projection files found in staged tree."
    }

    # ---------------------------------------------------------
    # 13. Reconfirm outer R6 did not mutate
    # ---------------------------------------------------------

    $R6HashAfter = (Get-FileHash -LiteralPath $R6Zip -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($R6HashAfter -cne $R6HashBefore) {
        throw "R6 outer ZIP changed during Phase C."
    }

    # ---------------------------------------------------------
    # 14. Write receipt
    # ---------------------------------------------------------

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_C_R6_STAGING'
        GoverningDecision = 'IA-D-R20-INT-001'
        ConditionalAuthority = 'IA-PUB-R20-INTEGRATED-001'

        R6Zip = $R6Zip
        R6ExpectedBytes = $ExpectedR6Bytes
        R6ActualBytes = $R6Item.Length
        R6ExpectedSha256 = $ExpectedR6Sha256
        R6Sha256Before = $R6HashBefore
        R6Sha256After = $R6HashAfter

        Stage = $Stage
        EvidenceDirectory = $EvidenceDir

        ZipMembers = $ExpectedMembers
        ExtractedFiles = $StageFiles.Count
        UnsafePaths = @($Unsafe)
        ExactDuplicatePaths = @($ExactDupes)
        CaseFoldCollisions = @($CaseFoldDupes)
        SymlinkLikeMembers = @($SymlinkLike)

        PublicValidator = $PublicValidator.Substring($Stage.Length).TrimStart('\')
        PublicValidatorExitCode = $PublicCode
        PublicValidatorOutput = @($PublicOutput)

        OverlayValidator = $OverlayValidator.Substring($Stage.Length).TrimStart('\')
        OverlayValidatorExitCode = $OverlayCode
        OverlayValidatorOutput = @($OverlayOutput)

        ExcludedR22DirectoryPublicFileCount = $R22PrivateFiles.Count
        ForbiddenPrivateCarrierCount = $ForbiddenCarriers.Count
        StandaloneFontFileCount = $FontFiles.Count

        PbixPath = $Pbix.FullName.Substring($Stage.Length).TrimStart('\')
        PbixBytes = $Pbix.Length
        PbixSha256 = $PbixHash

        PublicImageFileCount = $ImageFiles.Count
        PowerBiNamedFileCount = $PowerBiFiles.Count

        CheckoutMutation = 'NONE'
        GitMutation = 'NONE'
        Publication = 'NOT_PERFORMED'
        WindowsHostedExtraction = 'NOT_PERFORMED'
        PhaseCStatus = 'PASS'
    }

    $JsonPath = Join-Path $EvidenceDir 'MSBF_PHASE_C_R6_STAGING_VALIDATION.json'
    $TxtPath = Join-Path $EvidenceDir 'MSBF_PHASE_C_SUMMARY.txt'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $JsonPath -Encoding UTF8

    $Summary = @(
        'PHASE_C_R6_STAGING = PASS',
        "R6 SHA-256: $R6HashAfter",
        "Staging root: $Stage",
        "Extracted files: $($StageFiles.Count)",
        "Public validator: PASS",
        "Overlay validator: PASS",
        "Excluded R22 public files: $($R22PrivateFiles.Count)",
        "Forbidden private/raw carriers: $($ForbiddenCarriers.Count)",
        "Standalone fonts: $($FontFiles.Count)",
        "PBIX bytes: $($Pbix.Length)",
        "PBIX SHA-256: $PbixHash",
        "Public image files: $($ImageFiles.Count)",
        "Power BI named files: $($PowerBiFiles.Count)",
        '',
        'No mutation of D:\x\m, Git refs, release assets, or R6 ZIP occurred.',
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

### What I expect from this phase

The key hard results should be:

```text
PHASE_C_R6_STAGING = PASS

Extracted files: 2884

Public release validation PASS
Governed manifest files: 2880
Module 2 stage folders: 12

Candidate overlay validation PASS
Governed candidate files: 248

Excluded R22 public files: 0
Forbidden private/raw carriers: 0
Standalone fonts: 0

PBIX bytes: 27635305
PBIX SHA-256:
ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4
```

A useful detail from Phase B: both `core.autocrlf=true` and `core.longpaths=true` are already recorded. [export reference: filecite | turn21file0 | L25-L29] We will account explicitly for `autocrlf` when we eventually compare and stage the R6 tree so Git does not surprise us with a mass line-ending transformation.

This Phase C extraction is **local staging validation**, not the later mandatory Windows-native hosted-asset extraction. R20 specifically requires the latter only after publication against the actual hosted copies. [export reference: filecite | turn19file5 | L24-L30]

If this block reports a failure, stop and send me the complete error. If it reports `PASS`, send the generated **`MSBF_PHASE_C_R6_STAGING_VALIDATION.json`** and console summary. Then we'll perform the controlled `D:\x\m` synchronization and exact tree-equality gate—still **before any commit or tag creation**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c1c732ae-7083-4120-8ad6-e693710d2058"></a>
## Andrew / user · C123-M00057

C123-M00057 · 2026-09-10T08:10:32.416000-04:00 · active path

Preceding visible parent: [C123-M00056](part-04.md#m-be9236c0-b641-4c5b-93db-0252099e23d8)

**Editorial record note:** Attachment references: Pasted text(20260910-121015).txt

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3b149401-d794-4174-b4ae-3ea3a9e4db8a"></a>
## Assistant · C123-M00058

C123-M00058 · 2026-09-10T08:10:35.191176-04:00 · active path

Preceding visible parent: [C123-M00057](part-04.md#m-c1c732ae-7083-4120-8ad6-e693710d2058)

<!-- BEGIN_SOURCE_MESSAGE -->
The Phase C stop is **not an R6 defect**. It is a bug in the traversal-test expression I gave you.

The script incorrectly classified essentially every normal relative ZIP member—starting with `.gitattributes`, `.github/...`, `README.md`, and the normal `Module_0/...` tree—as unsafe. [export reference: filecite | turn22file0 | L8-L12] That pattern makes clear this is the guard logic, not malicious/path-traversal content in R6.

Also importantly, the failure occurred **before staging-tree creation/extraction**, so `D:\x\m` and Git were not touched.

### Cause

This expression was the problem:

```powershell
$name -split '/' | Where-Object { $_ -eq '..' }
```

inside the larger multiline Boolean expression. PowerShell's parsing/coercion around the pipeline made that unsafe as a Boolean test.

The correct explicit test is:

```powershell
($name.Split('/') -contains '..')
```

So we should **rerun Phase C from scratch with a new evidence/staging identity**, not modify R6.

Use the same PowerShell window and paste this corrected block:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $R6Zip = 'D:\MSBF_ZIP_FILES_091026\MSBF_FINAL_INTEGRATED_PUBLICATION_CANDIDATE_R6_20260910_FINAL_MICROPOLISH.zip'

    $ExpectedR6Bytes = 279632507
    $ExpectedR6Sha256 = '31611a7c90ad7a0b597ecc3c0a5592c2aa7c031a82b5c7fbcc40750c8e8d0bf2'
    $ExpectedMembers = 2884

    $ExpectedPbixBytes = 27635305
    $ExpectedPbixSha256 = 'ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)

    $Stage = "D:\MSBF_RELEASE_R6_STAGING_${Stamp}_${Suffix}"
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE C — R6 CLEAN STAGING / VALIDATION — RETRY"
    Write-Host "============================================================"
    Write-Host "R6 ZIP:    $R6Zip"
    Write-Host "Staging:   $Stage"
    Write-Host "Evidence:  $EvidenceDir"
    Write-Host ""

    # ---------------------------------------------------------
    # 1. Reconfirm exact R6 identity
    # ---------------------------------------------------------

    if (-not (Test-Path -LiteralPath $R6Zip -PathType Leaf)) {
        throw "R6 ZIP not found: $R6Zip"
    }

    $R6Item = Get-Item -LiteralPath $R6Zip
    $R6HashBefore = (Get-FileHash -LiteralPath $R6Zip -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($R6Item.Length -ne $ExpectedR6Bytes) {
        throw "R6 size mismatch. Expected $ExpectedR6Bytes ; actual $($R6Item.Length)"
    }

    if ($R6HashBefore -cne $ExpectedR6Sha256) {
        throw "R6 SHA-256 mismatch. Expected $ExpectedR6Sha256 ; actual $R6HashBefore"
    }

    # ---------------------------------------------------------
    # 2. Inspect ZIP namespace before extraction
    # ---------------------------------------------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $zip = [System.IO.Compression.ZipFile]::OpenRead($R6Zip)

    try {
        $Entries = @($zip.Entries)

        if ($Entries.Count -ne $ExpectedMembers) {
            throw "R6 member-count mismatch. Expected $ExpectedMembers ; actual $($Entries.Count)"
        }

        $Names = New-Object System.Collections.Generic.List[string]
        $Unsafe = New-Object System.Collections.Generic.List[string]
        $SymlinkLike = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $Entries) {
            $name = $entry.FullName.Replace('\','/')

            if ([string]::IsNullOrWhiteSpace($name)) {
                throw "ZIP contains an empty member name."
            }

            $Names.Add($name)

            # Corrected explicit traversal test.
            $Segments = $name.Split('/')
            $HasParentTraversal = ($Segments -contains '..')

            if (
                $name.StartsWith('/') -or
                $name.StartsWith('\') -or
                $name -match '^[A-Za-z]:' -or
                $HasParentTraversal
            ) {
                $Unsafe.Add($name)
            }

            $unixMode = (($entry.ExternalAttributes -shr 16) -band 0xF000)
            if ($unixMode -eq 0xA000) {
                $SymlinkLike.Add($name)
            }
        }

        $ExactDupes = @(
            $Names |
            Group-Object |
            Where-Object Count -gt 1 |
            ForEach-Object Name
        )

        $CaseFoldDupes = @(
            $Names |
            Group-Object { $_.ToLowerInvariant() } |
            Where-Object Count -gt 1 |
            ForEach-Object { $_.Group -join ' | ' }
        )

        if ($Unsafe.Count -gt 0) {
            throw "Unsafe ZIP path(s): $($Unsafe -join '; ')"
        }

        if ($ExactDupes.Count -gt 0) {
            throw "Duplicate ZIP member(s): $($ExactDupes -join '; ')"
        }

        if ($CaseFoldDupes.Count -gt 0) {
            throw "Case-fold collision(s): $($CaseFoldDupes -join '; ')"
        }

        if ($SymlinkLike.Count -gt 0) {
            throw "Symlink-like ZIP member(s) found: $($SymlinkLike -join '; ')"
        }

        if (Test-Path -LiteralPath $Stage) {
            throw "Staging path unexpectedly already exists: $Stage"
        }

        New-Item -ItemType Directory -Path $Stage | Out-Null

        # ---------------------------------------------------------
        # 3. Controlled extraction
        # ---------------------------------------------------------

        $StageFull = [System.IO.Path]::GetFullPath($Stage).TrimEnd('\') + '\'

        foreach ($entry in $Entries) {
            $relative = $entry.FullName.Replace('/','\')
            $dest = [System.IO.Path]::GetFullPath((Join-Path $Stage $relative))

            if (-not $dest.StartsWith($StageFull, [System.StringComparison]::OrdinalIgnoreCase)) {
                throw "Extraction path escaped staging root: $($entry.FullName)"
            }

            if ([string]::IsNullOrEmpty($entry.Name)) {
                New-Item -ItemType Directory -Path $dest -Force | Out-Null
                continue
            }

            $parent = Split-Path -Parent $dest
            if (-not (Test-Path -LiteralPath $parent)) {
                New-Item -ItemType Directory -Path $parent -Force | Out-Null
            }

            $source = $entry.Open()

            try {
                $target = [System.IO.File]::Open(
                    $dest,
                    [System.IO.FileMode]::CreateNew,
                    [System.IO.FileAccess]::Write,
                    [System.IO.FileShare]::None
                )

                try {
                    $source.CopyTo($target)
                }
                finally {
                    $target.Dispose()
                }
            }
            finally {
                $source.Dispose()
            }
        }
    }
    finally {
        $zip.Dispose()
    }

    # ---------------------------------------------------------
    # 4. Tree count / root-shape validation
    # ---------------------------------------------------------

    $StageFiles = @(Get-ChildItem -LiteralPath $Stage -Recurse -File -Force)

    if ($StageFiles.Count -ne $ExpectedMembers) {
        throw "Extracted file count mismatch. Expected $ExpectedMembers ; actual $($StageFiles.Count)"
    }

    $RequiredRootFiles = @(
        'README.md',
        'MANIFEST.csv',
        'SHA256SUMS.txt',
        'manifest.json',
        'release_metadata.json',
        'PACKAGE_INVENTORY.csv',
        'docs\README.md',
        'docs\guide\CURRENT_USE.md',
        'tools\validate_public_release.py'
    )

    foreach ($relative in $RequiredRootFiles) {
        $candidate = Join-Path $Stage $relative

        if (-not (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            throw "Required R6 member missing: $relative"
        }
    }

    # ---------------------------------------------------------
    # 5. Exact retained validator paths
    # ---------------------------------------------------------

    $PublicValidator = Join-Path $Stage 'tools\validate_public_release.py'

    $OverlayValidator = Join-Path $Stage `
        'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py'

    if (-not (Test-Path -LiteralPath $OverlayValidator -PathType Leaf)) {
        throw "Retained candidate-overlay validator missing: $OverlayValidator"
    }

    # ---------------------------------------------------------
    # 6. Python discovery
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
    # 7. Run unchanged validators
    # ---------------------------------------------------------

    Push-Location $Stage

    try {
        $PublicOutput = @(& $PythonExe @PythonPrefix $PublicValidator 2>&1)
        $PublicCode = $LASTEXITCODE

        $OverlayOutput = @(& $PythonExe @PythonPrefix $OverlayValidator 2>&1)
        $OverlayCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    $PublicText = $PublicOutput -join "`n"
    $OverlayText = $OverlayOutput -join "`n"

    if ($PublicCode -ne 0) {
        throw "Public release validator failed with exit code $PublicCode`n$PublicText"
    }

    if ($OverlayCode -ne 0) {
        throw "Candidate overlay validator failed with exit code $OverlayCode`n$OverlayText"
    }

    if ($PublicText -notmatch 'Public release validation PASS') {
        throw "Expected public-validator PASS text not found."
    }

    if ($PublicText -notmatch 'Governed manifest files:\s*2880') {
        throw "Public validator did not report 2880 governed manifest files."
    }

    if ($PublicText -notmatch 'Module 2 stage folders:\s*12') {
        throw "Public validator did not report 12 Module 2 stage folders."
    }

    if ($OverlayText -notmatch 'Candidate overlay validation PASS') {
        throw "Expected candidate-overlay PASS text not found."
    }

    if ($OverlayText -notmatch 'Governed candidate files:\s*248') {
        throw "Overlay validator did not report 248 governed candidate files."
    }

    # ---------------------------------------------------------
    # 8. Private / excluded carrier screening
    # ---------------------------------------------------------

    $ForbiddenPatterns = @(
        '*PRIVATE*.zip',
        '*EVIDENCE_PRIVATE*.zip',
        '*CONTROL_PRIVATE*.zip',
        '*AUDIT_RETURN*.zip',
        '*PART4_RETURN*.zip',
        '*ChatGPT Conversation Log*.pdf'
    )

    $ForbiddenCarriers = New-Object System.Collections.Generic.List[string]

    foreach ($pattern in $ForbiddenPatterns) {
        Get-ChildItem -LiteralPath $Stage -Recurse -File -Filter $pattern -ErrorAction SilentlyContinue |
            ForEach-Object { $ForbiddenCarriers.Add($_.FullName) }
    }

    if ($ForbiddenCarriers.Count -gt 0) {
        throw "Potential private/raw carrier found: $($ForbiddenCarriers -join '; ')"
    }

    # ---------------------------------------------------------
    # 9. No standalone font files
    # ---------------------------------------------------------

    $FontExtensions = @('.ttf','.otf','.woff','.woff2','.eot')

    $FontFiles = @(
        $StageFiles |
        Where-Object { $FontExtensions -contains $_.Extension.ToLowerInvariant() }
    )

    if ($FontFiles.Count -gt 0) {
        throw "Standalone font file(s) present: $($FontFiles.FullName -join '; ')"
    }

    # ---------------------------------------------------------
    # 10. Exact accepted PBIX identity
    # ---------------------------------------------------------

    $PbixPath = Join-Path $Stage `
        'docs\power_bi\m2_v2_1\release\MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix'

    if (-not (Test-Path -LiteralPath $PbixPath -PathType Leaf)) {
        throw "Accepted PBIX missing: $PbixPath"
    }

    $Pbix = Get-Item -LiteralPath $PbixPath
    $PbixHash = (Get-FileHash -LiteralPath $PbixPath -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($Pbix.Length -ne $ExpectedPbixBytes) {
        throw "PBIX size mismatch. Expected $ExpectedPbixBytes ; actual $($Pbix.Length)"
    }

    if ($PbixHash -cne $ExpectedPbixSha256) {
        throw "PBIX SHA-256 mismatch. Expected $ExpectedPbixSha256 ; actual $PbixHash"
    }

    # ---------------------------------------------------------
    # 11. Key documentation / visual / P03 / poster paths
    # ---------------------------------------------------------

    $RequiredPublicPaths = @(
        'docs\guide\EXPLAINABILITY.md',
        'docs\guide\LEARNING.md',
        'docs\guide\VISUALS.md',

        'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_738_baseline.png',
        'docs\power_bi\m2_v2_1\assets\power_bi\core\p03_application_journey_749_baseline.png',

        'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\posters\MSBF_MCI_How_the_Governed_Decision_Engine_Works_v2_1_COPYFIX_R1.png',
        'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\posters\MSBF_MCI_What_Happens_After_the_Decision_v2_1_COPYFIX_R1.png',

        'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\architecture\png\Enterprise_Merchant_Sales_Based_Financing_Platform_v2_1.png',
        'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\architecture\png\Module_1_Governed_Evidence_Contract_and_Acceptance_Lineage_v2_1.png',
        'docs\portfolio_visuals\MSBF_VISUAL_PUBLIC_R1\assets\architecture\png\Module_2_Governed_Decisioning_Operations_and_G3v2_Lineage_v2_1.png',

        'docs\cohort\m2_v2_1\MSBF_Merchant_Credit_Intelligence_Initial_750_Cohort_Overview_R3_PATCH1_20260908_REVIEW.pdf'
    )

    foreach ($relative in $RequiredPublicPaths) {
        if (-not (Test-Path -LiteralPath (Join-Path $Stage $relative) -PathType Leaf)) {
            throw "Required public route/asset missing: $relative"
        }
    }

    # ---------------------------------------------------------
    # 12. Outer ZIP nonmutation
    # ---------------------------------------------------------

    $R6HashAfter = (Get-FileHash -LiteralPath $R6Zip -Algorithm SHA256).Hash.ToLowerInvariant()

    if ($R6HashAfter -cne $R6HashBefore) {
        throw "R6 outer ZIP changed during Phase C."
    }

    # ---------------------------------------------------------
    # 13. Receipt
    # ---------------------------------------------------------

    $Receipt = [ordered]@{
        SchemaVersion = '1.1'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_C_R6_STAGING_RETRY'
        GoverningDecision = 'IA-D-R20-INT-001'
        ConditionalAuthority = 'IA-PUB-R20-INTEGRATED-001'

        RetryReason = 'Corrected PowerShell ZIP parent-traversal Boolean expression; prior attempt falsely classified normal relative members as unsafe.'

        R6Zip = $R6Zip
        R6Bytes = $R6Item.Length
        R6Sha256Before = $R6HashBefore
        R6Sha256After = $R6HashAfter

        Stage = $Stage
        EvidenceDirectory = $EvidenceDir

        ZipMembers = $Entries.Count
        ExtractedFiles = $StageFiles.Count
        UnsafePaths = @($Unsafe)
        ExactDuplicatePaths = @($ExactDupes)
        CaseFoldCollisions = @($CaseFoldDupes)
        SymlinkLikeMembers = @($SymlinkLike)

        PublicValidator = 'tools\validate_public_release.py'
        PublicValidatorExitCode = $PublicCode
        PublicValidatorOutput = @($PublicOutput)

        OverlayValidator = 'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py'
        OverlayValidatorExitCode = $OverlayCode
        OverlayValidatorOutput = @($OverlayOutput)

        ForbiddenPrivateCarrierCount = $ForbiddenCarriers.Count
        StandaloneFontFileCount = $FontFiles.Count

        PbixPath = 'docs\power_bi\m2_v2_1\release\MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix'
        PbixBytes = $Pbix.Length
        PbixSha256 = $PbixHash

        CheckoutMutation = 'NONE'
        GitMutation = 'NONE'
        Publication = 'NOT_PERFORMED'
        PhaseCStatus = 'PASS'
    }

    $JsonPath = Join-Path $EvidenceDir 'MSBF_PHASE_C_R6_STAGING_VALIDATION.json'
    $TxtPath = Join-Path $EvidenceDir 'MSBF_PHASE_C_SUMMARY.txt'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $JsonPath -Encoding UTF8

    $Summary = @(
        'PHASE_C_R6_STAGING = PASS',
        "R6 SHA-256: $R6HashAfter",
        "Staging root: $Stage",
        "ZIP members: $($Entries.Count)",
        "Extracted files: $($StageFiles.Count)",
        'Public release validator: PASS',
        'Governed manifest files: 2880',
        'Module 2 stage folders: 12',
        'Candidate overlay validator: PASS',
        'Governed candidate files: 248',
        "Forbidden private/raw carriers: $($ForbiddenCarriers.Count)",
        "Standalone fonts: $($FontFiles.Count)",
        "PBIX bytes: $($Pbix.Length)",
        "PBIX SHA-256: $PbixHash",
        '',
        'D:\x\m was not modified.',
        'No Git ref, commit, tag, push, or publication action was performed.',
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

One improvement I made while correcting the defect: the retry now uses the **known physical overlay-validator path** visible in R6 rather than searching all Python files for a PASS string. That is more deterministic.

The failed attempt should remain in the evidence directory as a **failed Phase C attempt**; don't delete it. Its disposition is simply:

```text
PHASE_C_ATTEMPT_1 = FAILED_SCRIPT_GUARD_LOGIC
R6_DEFECT = NO_EVIDENCE
CHECKOUT_MUTATION = NONE
```

We are **not** advancing to `D:\x\m` synchronization yet. Run this corrected Phase C only and return its receipt/output.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d869abed-5892-4b8f-af16-34dde76b39fb"></a>
## Andrew / user · C123-M00059

C123-M00059 · 2026-09-10T08:14:13.120000-04:00 · active path

Preceding visible parent: [C123-M00058](part-04.md#m-3b149401-d794-4174-b4ae-3ea3a9e4db8a)

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE C — R6 CLEAN STAGING / VALIDATION — RETRY
============================================================
R6 ZIP:    D:\MSBF_ZIP_FILES_091026\MSBF_FINAL_INTEGRATED_PUBLICATION_CANDIDATE_R6_20260910_FINAL_MICROPOLISH.zip
Staging:   D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94
Evidence:  D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_20260910T121241797Z_028c5f94

Exception:
Line |
 295 |          throw "Overlay validator did not report 248 governed candidat …
     |          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Overlay validator did not report 248 governed candidate files.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5cfccc5e-15a7-462c-b626-98d95f170229"></a>
## Assistant · C123-M00060

C123-M00060 · 2026-09-10T08:14:16.456174-04:00 · active path

Preceding visible parent: [C123-M00059](part-04.md#m-d869abed-5892-4b8f-af16-34dde76b39fb)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a **bounded Phase C assertion mismatch**, not evidence yet of an R6 defect.

Because the script reached the specific line:

```text
Overlay validator did not report 248 governed candidate files.
```

the preceding checks necessarily got past the overlay validator's **exit-code check** and its **`Candidate overlay validation PASS` check**. What we do **not** yet know is whether the validator reported a different count, used different wording, or omitted the count line entirely.

Do **not** delete the staging tree and do **not** modify `D:\x\m`. We should inspect the actual validator output before changing any expectation.

Run this **read-only diagnostic only** in the same PowerShell session:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'
    $EvidenceDir = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_20260910T121241797Z_028c5f94'

    $OverlayValidator = Join-Path $Stage `
        'successor_candidates\m2-g3-v2.1.0-rc1\tools\validate_candidate_overlay.py'

    if (-not (Test-Path -LiteralPath $OverlayValidator -PathType Leaf)) {
        throw "Overlay validator missing: $OverlayValidator"
    }

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
        throw 'Python launcher not found.'
    }

    Push-Location $Stage

    try {
        $Output = @(& $PythonExe @PythonPrefix $OverlayValidator 2>&1)
        $ExitCode = $LASTEXITCODE
    }
    finally {
        Pop-Location
    }

    $OutputPath = Join-Path $EvidenceDir 'OVERLAY_VALIDATOR_RAW_OUTPUT_RETRY1.txt'

    @(
        "Validator: $OverlayValidator"
        "ExitCode: $ExitCode"
        ''
        '----- RAW OUTPUT -----'
        $Output
    ) | Set-Content -LiteralPath $OutputPath -Encoding UTF8

    Write-Host ''
    Write-Host '============================================================'
    Write-Host 'OVERLAY VALIDATOR — RAW DIAGNOSTIC'
    Write-Host '============================================================'
    Write-Host "Exit code: $ExitCode"
    Write-Host ''
    $Output | ForEach-Object { Write-Host $_ }
    Write-Host ''
    Write-Host "Saved: $OutputPath"
    Write-Host ''
    Write-Host 'No extraction, checkout mutation, Git mutation, or publication performed.'
}
```

Return the console output. In particular, I need the lines surrounding:

```text
Candidate overlay validation PASS
```

and whatever count the validator actually reports.

For now the disposition is:

```text
PHASE_C_ATTEMPT_2 = HOLD_ASSERTION_MISMATCH
R6_DEFECT = NOT_ESTABLISHED
STAGING_EXTRACTION = COMPLETED_TO_POINT_OF_VALIDATOR_CHECK
CHECKOUT_MUTATION = NONE
GIT_MUTATION = NONE
PUBLICATION = NONE
```

We will not weaken the validator or silently change `248`. Once we see the validator's actual output, I can determine whether this is merely another wrapper expectation defect or a genuine candidate-count discrepancy.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9ad08d54-40b2-4b66-88b4-d5d7506e5ff1"></a>
## Andrew / user · C123-M00061

C123-M00061 · 2026-09-10T08:16:33.011000-04:00 · active path

Preceding visible parent: [C123-M00060](part-04.md#m-5cfccc5e-15a7-462c-b626-98d95f170229)

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
OVERLAY VALIDATOR — RAW DIAGNOSTIC
============================================================
Exit code: 0

Candidate overlay validation PASS
Governed candidate files: 235

Saved: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_C_20260910T121241797Z_028c5f94\OVERLAY_VALIDATOR_RAW_OUTPUT_RETRY1.txt

No extraction, checkout mutation, Git mutation, or publication performed.
<!-- END_SOURCE_MESSAGE -->
