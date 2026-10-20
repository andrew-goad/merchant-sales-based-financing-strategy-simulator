# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 11 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-10.md)
[Next part](part-12.md)

<a id="m-0e5e3416-a0ed-41b9-968b-565361733bce"></a>
## Assistant · C123-M00100

C123-M00100 · 2026-09-10T10:17:25.825172-04:00 · active path

Preceding visible parent: [C123-M00099](part-10.md#m-1ade9040-7394-4c7a-bf09-140a7266959c)

<!-- BEGIN_SOURCE_MESSAGE -->
That is sufficient to close **Phase L**.

Your attached front-page printout gives direct visual evidence that the repository is publicly reachable, the v2.1.0 release is shown as **Latest**, the publication commit is visible, and the root README renders with the approved editorial/visual treatment. The rendered pages show the executive proposition, enterprise architecture, structure-search visual, P03 Application Journey, P01 portfolio view, and Module 1/2 lineage imagery without broken-image placeholders. [export reference: filecite | turn36file0 | L2-L7]

Combined with your explicit confirmation that the links are operational and your earlier release-page printout, we can record:

```text
PHASE_L_ANONYMOUS_PUBLIC_NAVIGATION = PASS

Repository accessible publicly:       PASS
Root README renders:                  PASS
Core visuals render:                  PASS
Documentation/navigation links:       PASS
P03 explainability route:             PASS
Learning/poster routes:               PASS
Cohort / Power BI routes:             PASS
v2.1.0 release page:                  PASS
Four intended custom ZIPs visible:    PASS
Historical v2.0.0 preserved:          PASS

RELEASE CLOSURE GATES:
Remote commit/tag binding              PASS
Publication event                      PASS
Hosted asset identity                  PASS
Windows-native hosted extraction       PASS
Anonymous/public navigation            PASS
```

The Phase K receipt already records 4/4 Explorer-shell opens, 4/4 Windows-native extraction passes, and zero extracted-file read failures. [export reference: filecite | turn35file0 | L7-L10] The hosted-verification receipt separately records all four actual GitHub-hosted ZIPs as exact hash/size matches. [export reference: filecite | turn34file1 | L14-L17]

We can therefore proceed to **Phase M — genuine release closure**. This next block only creates the closure evidence package under `D:\MSBF_RELEASE_ENGINEERING_EVIDENCE`; it does **not** modify the Git repository or move the published v2.1.0 tag.

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'

    $Commit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $Tree   = 'fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb'

    $NewTag = 'module-2-g3-v2.1.0'
    $NewTagObject = 'cdef0c49eb37d0cc72444c0829c253e09eee050a'

    $OldTag = 'module-2-g3-v2.0.0'
    $OldTagObject = 'fcf32b615142a06075a7fccede26a97042ca8194'
    $OldTagCommit = '500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65'

    $ReleaseUrl = 'https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/module-2-g3-v2.1.0'
    $PublishedAt = '2026-09-10T13:59:29Z'

    $PhaseH = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_H_20260910T135054341Z_007dc7ce'
    $PhaseJ = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_J_20260910T140346449Z_a425ebc6'
    $PhaseK = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_K_20260910T140834154Z_c43ee4c6'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Root = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_M_RELEASE_CLOSURE_${Stamp}"
    $Package = Join-Path $Root 'MSBF_RELEASE_CLOSURE_R1_20260910'

    New-Item -ItemType Directory -Path $Package -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Package 'evidence') -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE M — FINAL RELEASE CLOSURE"
    Write-Host "============================================================"

    # ------------------------------------------------------------
    # 1. Fresh final Git binding
    # ------------------------------------------------------------

    $RemoteMain = (
        (git -C $Repo ls-remote origin refs/heads/main)[0] -split '\s+'
    )[0].ToLowerInvariant()

    $NewRemote = @(git -C $Repo ls-remote origin "refs/tags/$NewTag" "refs/tags/$NewTag^{}")
    $OldRemote = @(git -C $Repo ls-remote origin "refs/tags/$OldTag" "refs/tags/$OldTag^{}")

    $NewObj = (($NewRemote | Where-Object { $_ -match "refs/tags/$([regex]::Escape($NewTag))$" })[0] -split '\s+')[0].ToLowerInvariant()
    $NewCommit = (($NewRemote | Where-Object { $_ -match "refs/tags/$([regex]::Escape($NewTag))\^\{\}$" })[0] -split '\s+')[0].ToLowerInvariant()

    $OldObj = (($OldRemote | Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))$" })[0] -split '\s+')[0].ToLowerInvariant()
    $OldCommit = (($OldRemote | Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))\^\{\}$" })[0] -split '\s+')[0].ToLowerInvariant()

    if ($RemoteMain -ne $Commit) { throw "STOP: remote main changed." }
    if ($NewObj -ne $NewTagObject) { throw "STOP: new tag object changed." }
    if ($NewCommit -ne $Commit) { throw "STOP: new tag target changed." }
    if ($OldObj -ne $OldTagObject) { throw "STOP: historical tag object changed." }
    if ($OldCommit -ne $OldTagCommit) { throw "STOP: historical tag target changed." }

    # ------------------------------------------------------------
    # 2. Read completed hosted / Windows receipts
    # ------------------------------------------------------------

    $J = Get-Content `
        -LiteralPath (Join-Path $PhaseJ 'MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION_RECOVERED.json') `
        -Raw | ConvertFrom-Json

    $K = Get-Content `
        -LiteralPath (Join-Path $PhaseK 'MSBF_PHASE_K_WINDOWS_HOSTED_EXTRACTION.json') `
        -Raw | ConvertFrom-Json

    if ($J.HostedAssetVerification -ne 'PASS') {
        throw "STOP: Phase J receipt is not PASS."
    }

    if ($K.WindowsHostedExtraction -ne 'PASS') {
        throw "STOP: Phase K receipt is not PASS."
    }

    # ------------------------------------------------------------
    # 3. Final asset table
    # ------------------------------------------------------------

    $AssetRows = @(
        $J.AssetResults |
        ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                Bytes = $_.DownloadedBytes
                Sha256 = $_.DownloadedSha256
                HostedIdentity = $_.Status
                WindowsExtraction = 'PASS'
            }
        }
    )

    $AssetRows |
        Export-Csv `
            -LiteralPath (Join-Path $Package 'HOSTED_ASSET_FINAL_VERIFICATION.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 4. Machine-readable closure
    # ------------------------------------------------------------

    $Closure = [pscustomobject]@{
        SchemaVersion = '1.0'
        Record = 'MSBF_RELEASE_CLOSURE'

        OperatingModel = 'IA-GOV-20260822-001'
        ControllingAcceptance = 'IA-D-R20-INT-001'
        PublicationAuthority = 'IA-PUB-R20-INTEGRATED-001'

        Release = [pscustomobject]@{
            Repository = 'andrew-goad/merchant-sales-based-financing-strategy-simulator'
            StableLabel = 'module-2-g3-v2.1.0'
            ReleaseUrl = $ReleaseUrl
            PublishedAt = $PublishedAt
            PublicationCommit = $Commit
            PublicationTree = $Tree
            NewTagObject = $NewObj
            NewTagPeeledCommit = $NewCommit
        }

        HistoricalIntegrity = [pscustomobject]@{
            HistoricalTag = $OldTag
            HistoricalTagObject = $OldObj
            HistoricalTagPeeledCommit = $OldCommit
            HistoricalTagPreserved = $true
        }

        HostedAssets = $AssetRows

        Gates = [pscustomobject]@{
            ReleaseAssetPreflight = 'PASS'
            GitRemoteTagPreflight = 'PASS'
            R6StagingValidation = 'PASS'
            CheckoutMaterialization = 'PASS'
            PreCommitPublicationGate = 'PASS'
            CommitBinding = 'PASS'
            PrePushTagGate = 'PASS'
            RemoteBinding = 'PASS'
            PublicationEvent = 'PASS'
            HostedAssetIdentity = 'PASS'
            WindowsNativeHostedExtraction = 'PASS'
            AnonymousPublicNavigation = 'PASS'
        }

        WindowsHostedExtraction = [pscustomobject]@{
            AssetsTested = 4
            ExplorerShellOpenPasses = 4
            NativeExtractionPasses = 4
            ExtractedReadFailures = 0
        }

        AnonymousNavigation = [pscustomobject]@{
            OwnerConfirmedPublicRepositoryAccess = $true
            OwnerConfirmedImagesRender = $true
            OwnerConfirmedLinksOperational = $true
            ReleasePagePreviouslyConfirmed = $true
        }

        PreservedBoundaries = [pscustomobject]@{
            SyntheticNonProductionScope = $true
            RouteB = 'QUALIFIED_ONLY_FOR_PORTABLE_CHECKPOINT_RESTORE_AND_ISOLATED_RETAINED_FINAL_M2_11_M2_12_G3V2_REPLAY'
            RouteD = 'NOT_QUALIFIED'
            CampaignScaleRuntimeAuthority = 'NOT_GRANTED'
            Module3RuntimeAuthority = 'NOT_GRANTED'
            ArbitraryFreshCampaignRunner = 'NOT_QUALIFIED'
        }

        GitMutationDuringClosureRecord = $false
        TagMovedDuringClosureRecord = $false

        FinalDisposition = 'RELEASE_CLOSURE_COMPLETE'
    }

    $Closure |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -LiteralPath (Join-Path $Package 'MSBF_RELEASE_CLOSURE_RECORD_R1_20260910.json') `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 5. Owner-readable closure summary
    # ------------------------------------------------------------

    @"
# MSBF Module 2 / G3 v2.1.0 — Release Closure

## Final disposition

**RELEASE_CLOSURE_COMPLETE**

The integrated MSBF Module 1 / Module 2 successor has been published under the stable release label:

`module-2-g3-v2.1.0`

## Publication identity

- Commit: `$Commit`
- Tree: `$Tree`
- Annotated tag object: `$NewObj`
- Tag target: `$NewCommit`
- Published: `$PublishedAt`
- Release: $ReleaseUrl

## Historical integrity

The historical `module-2-g3-v2.0.0` tag remains unchanged:

- Tag object: `$OldObj`
- Peeled commit: `$OldCommit`

The v2.1.0 publication is prospective supersession, not a rewrite of the historical v2.0.0 event.

## Hosted assets

All four actual GitHub-hosted release ZIPs reproduce their locked byte sizes and SHA-256 identities.

All four hosted copies were opened by the Windows Explorer ZIP shell and successfully extracted with Windows PowerShell Expand-Archive.

- Explorer ZIP-shell opens: 4 / 4
- Native extraction passes: 4 / 4
- Extracted read failures: 0

## Public navigation

The owner confirmed anonymous/public repository access, successful README rendering, successful image rendering and operational navigation links. The v2.1.0 release page was separately confirmed publicly accessible.

## Preserved scope

The portfolio remains deterministic synthetic / non-production.

Route B remains qualified only for portable checkpoint restore plus isolated retained-final M2.11 / M2.12 / G3-v2 replay.

Route D remains NOT_QUALIFIED.

No Campaign Scale or Module 3 runtime/database authority is created by this release.

A generalized arbitrary-new-campaign runner is not represented as qualified.

## Authority

Closure is linked to:

- IA-GOV-20260822-001
- IA-D-R20-INT-001
- IA-PUB-R20-INTEGRATED-001
"@ |
        Set-Content `
            -LiteralPath (Join-Path $Package 'MSBF_RELEASE_CLOSURE_SUMMARY_R1_20260910.md') `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 6. Copy core receipts into closure package
    # ------------------------------------------------------------

    Copy-Item `
        (Join-Path $PhaseH 'MSBF_PHASE_H_REMOTE_BINDING.json') `
        (Join-Path $Package 'evidence\PHASE_H_REMOTE_BINDING.json')

    Copy-Item `
        (Join-Path $PhaseJ 'MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION_RECOVERED.json') `
        (Join-Path $Package 'evidence\PHASE_J_HOSTED_ASSET_VERIFICATION.json')

    Copy-Item `
        (Join-Path $PhaseK 'MSBF_PHASE_K_WINDOWS_HOSTED_EXTRACTION.json') `
        (Join-Path $Package 'evidence\PHASE_K_WINDOWS_HOSTED_EXTRACTION.json')

    # ------------------------------------------------------------
    # 7. Manifest + hashes
    # ------------------------------------------------------------

    $PackageFiles = @(
        Get-ChildItem -LiteralPath $Package -Recurse -File |
        Sort-Object FullName
    )

    $PackageRoot = [IO.Path]::GetFullPath($Package).TrimEnd('\') + '\'

    $ManifestRows = foreach ($f in $PackageFiles) {
        [pscustomobject]@{
            Path = $f.FullName.Substring($PackageRoot.Length).Replace('\','/')
            Bytes = $f.Length
            Sha256 = (
                Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
            ).Hash.ToLowerInvariant()
        }
    }

    $ManifestRows |
        Export-Csv `
            -LiteralPath (Join-Path $Package 'MANIFEST.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # regenerate including MANIFEST itself
    $AllFiles = @(
        Get-ChildItem -LiteralPath $Package -Recurse -File |
        Sort-Object FullName
    )

    $HashLines = foreach ($f in $AllFiles) {
        $rel = $f.FullName.Substring($PackageRoot.Length).Replace('\','/')
        $sha = (
            Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        "$sha  $rel"
    }

    $HashLines |
        Set-Content `
            -LiteralPath (Join-Path $Package 'SHA256SUMS.txt') `
            -Encoding ASCII

    # ------------------------------------------------------------
    # 8. ZIP and verify closure carrier
    # ------------------------------------------------------------

    $ZipPath = "$Package.zip"

    Compress-Archive `
        -Path (Join-Path $Package '*') `
        -DestinationPath $ZipPath `
        -CompressionLevel Optimal

    $ZipItem = Get-Item -LiteralPath $ZipPath
    $ZipHash = (
        Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    "$ZipHash  $($ZipItem.Name)" |
        Set-Content `
            -LiteralPath "$ZipPath.sha256" `
            -Encoding ASCII

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $z = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)

    try {
        $ZipEntries = $z.Entries.Count

        foreach ($entry in $z.Entries) {
            $s = $entry.Open()
            try {
                $buffer = New-Object byte[] 1048576
                while ($s.Read($buffer,0,$buffer.Length) -gt 0) {}
            }
            finally {
                $s.Dispose()
            }
        }
    }
    finally {
        $z.Dispose()
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "RELEASE_CLOSURE = COMPLETE"
    Write-Host "============================================================"
    Write-Host "Commit:          $Commit"
    Write-Host "Tree:            $Tree"
    Write-Host "New tag object:  $NewObj"
    Write-Host "Old tag object:  $OldObj"
    Write-Host ""
    Write-Host "Hosted assets:   4 / 4 PASS"
    Write-Host "Windows extract: 4 / 4 PASS"
    Write-Host "Public nav:      PASS"
    Write-Host ""
    Write-Host "Closure ZIP:"
    Write-Host "  $ZipPath"
    Write-Host "Bytes:"
    Write-Host "  $($ZipItem.Length)"
    Write-Host "SHA-256:"
    Write-Host "  $ZipHash"
    Write-Host "ZIP entries:"
    Write-Host "  $ZipEntries"
    Write-Host ""
    Write-Host "Git mutation:    NONE"
    Write-Host "Tag mutation:    NONE"
    Write-Host "============================================================"
}
```

If this completes with `RELEASE_CLOSURE = COMPLETE`, return the bottom portion showing the **closure ZIP path, bytes, SHA-256, and entry count**.

At that point the Module 1/2 remediation and republication release-engineering cycle is substantively finished. The next workstream handoff can then be limited to **Campaign Scale / Module 3 rebasing against the published v2.1.0 successor**, while preserving their separate execution authorities.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9c598ebc-303c-4c61-b12c-782fb186ca84"></a>
## Andrew / user · C123-M00101

C123-M00101 · 2026-09-10T10:20:23.833000-04:00 · active path

Preceding visible parent: [C123-M00100](part-11.md#m-0e5e3416-a0ed-41b9-968b-565361733bce)

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE M — FINAL RELEASE CLOSURE
============================================================
Exception:
Line |
  52 |  …   if ($RemoteMain -ne $Commit) { throw "STOP: remote main changed." }
     |                                     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | STOP: remote main changed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bc54956e-05f4-4fe9-9c63-caed2a34b44d"></a>
## Assistant · C123-M00102

C123-M00102 · 2026-09-10T10:20:45.705858-04:00 · active path

Preceding visible parent: [C123-M00101](part-11.md#m-9c598ebc-303c-4c61-b12c-782fb186ca84)

<!-- BEGIN_SOURCE_MESSAGE -->
Stop is correct. We should **not** proceed with Phase M until we identify the new remote `main` SHA.

A GitHub release publication by itself should not move `main`, so this is a genuine state change that needs to be explained before we close the release. The likely possibilities are a later documentation/closure commit, an automated workflow, or another branch update—but we should not guess.

Run this **read-only diagnostic** in the same PowerShell window:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'
    $ExpectedPublicationCommit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $Tag = 'module-2-g3-v2.1.0'

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE M0 — REMOTE MAIN CHANGE DIAGNOSTIC"
    Write-Host "============================================================"

    $LocalHead = (git -C $Repo rev-parse HEAD).Trim()
    $LocalTree = (git -C $Repo rev-parse 'HEAD^{tree}').Trim()

    $RemoteMainRaw = @(git -C $Repo ls-remote origin refs/heads/main)

    if ($LASTEXITCODE -ne 0 -or $RemoteMainRaw.Count -ne 1) {
        throw "Unable to resolve remote main."
    }

    $RemoteMain = (($RemoteMainRaw[0] -split '\s+')[0]).ToLowerInvariant()

    $RemoteTagRaw = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$Tag" `
            "refs/tags/$Tag^{}"
    )

    $RemoteTagObject = (
        (
            $RemoteTagRaw |
            Where-Object { $_ -match "refs/tags/$([regex]::Escape($Tag))$" }
        )[0] -split '\s+'
    )[0].ToLowerInvariant()

    $RemoteTagCommit = (
        (
            $RemoteTagRaw |
            Where-Object { $_ -match "refs/tags/$([regex]::Escape($Tag))\^\{\}$" }
        )[0] -split '\s+'
    )[0].ToLowerInvariant()

    Write-Host "Local HEAD:           $LocalHead"
    Write-Host "Local HEAD tree:      $LocalTree"
    Write-Host "Expected pub commit:  $ExpectedPublicationCommit"
    Write-Host "Remote main:          $RemoteMain"
    Write-Host "Remote tag object:    $RemoteTagObject"
    Write-Host "Remote tag commit:    $RemoteTagCommit"
    Write-Host ""

    # Fetch remote main into a temporary remote-tracking ref only.
    git -C $Repo fetch origin main --no-tags

    if ($LASTEXITCODE -ne 0) {
        throw "Fetch of remote main failed."
    }

    $FetchedOriginMain = (git -C $Repo rev-parse origin/main).Trim()

    Write-Host "Fetched origin/main:  $FetchedOriginMain"
    Write-Host ""

    Write-Host "Recent origin/main history:"
    git -C $Repo log `
        --oneline `
        --decorate `
        --date=iso `
        --format='%H | %P | %cI | %an | %s' `
        -n 8 `
        origin/main

    Write-Host ""
    Write-Host "Relationship to publication commit:"

    git -C $Repo merge-base --is-ancestor `
        $ExpectedPublicationCommit `
        origin/main

    $AncestorCode = $LASTEXITCODE

    if ($AncestorCode -eq 0) {
        Write-Host "Publication commit IS an ancestor of current remote main."
    }
    elseif ($AncestorCode -eq 1) {
        Write-Host "Publication commit is NOT an ancestor of current remote main."
    }
    else {
        throw "merge-base ancestry check failed."
    }

    Write-Host ""
    Write-Host "Commits after publication commit on current remote main:"
    git -C $Repo log `
        --oneline `
        --decorate `
        "$ExpectedPublicationCommit..origin/main"

    Write-Host ""
    Write-Host "Files changed after publication commit:"
    git -C $Repo diff `
        --name-status `
        "$ExpectedPublicationCommit..origin/main"

    Write-Host ""
    Write-Host "Tag binding check:"
    Write-Host "v2.1.0 still peels to publication commit: $($RemoteTagCommit -eq $ExpectedPublicationCommit)"
    Write-Host ""
    Write-Host "No mutation performed."
    Write-Host "STOP HERE and return the full output."
}
```

What matters most is the relationship:

- If `fd9f67b6...` **is an ancestor** of the new `remote main`, and the intervening commit is a small post-publication documentation/closure update, we can likely treat it as the allowed post-publication addendum without moving the v2.1.0 tag.
- If `remote main` diverged or the publication commit is **not** an ancestor, we stop and reconcile before any closure record.
- The v2.1.0 tag must remain pinned to `fd9f67b6...`; we will **not move it**.

Do not rerun Phase M yet. Return the diagnostic output, especially the current remote SHA, recent commit(s), and changed-file list.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d8bac3c7-30d7-463d-af98-7b21e741fd34"></a>
## Andrew / user · C123-M00103

C123-M00103 · 2026-09-10T10:22:23.153000-04:00 · active path

Preceding visible parent: [C123-M00102](part-11.md#m-bc54956e-05f4-4fe9-9c63-caed2a34b44d)

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE M0 — REMOTE MAIN CHANGE DIAGNOSTIC
============================================================
Local HEAD:           fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Local HEAD tree:      fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb
Expected pub commit:  fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Remote main:          fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Remote tag object:    c
Remote tag commit:    f

From https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator
 * branch            main       -> FETCH_HEAD
Fetched origin/main:  fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Recent origin/main history:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046 | 46fb1f9198475678edc9cabdeefd2f91a59e49c2 | 2026-09-10T09:44:47-04:00 | Andrew R. Goad | Publish Module 2 / G3 v2.1.0 integrated successor
46fb1f9198475678edc9cabdeefd2f91a59e49c2 | 4cf6c46393fc127bc2127ad382c81b031f19cf27 | 2026-08-18T16:20:42-04:00 | Andrew R. Goad | Restore publication integrity for Module 2 / G3 v2.0.0
4cf6c46393fc127bc2127ad382c81b031f19cf27 | cd654fe9d441ebce3a8095aa3dce933562ceb7cb | 2026-08-15T10:38:40-04:00 | Andrew R. Goad | Publish Module 2 / G3 v2.0.0
cd654fe9d441ebce3a8095aa3dce933562ceb7cb | 39635f81ac71065adffb2110729e2fc2820b25d0 | 2026-08-15T09:46:34-04:00 | Andrew R. Goad | Publish Module 2 / G3 v2.0.0
39635f81ac71065adffb2110729e2fc2820b25d0 | 500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65 | 2026-08-15T09:12:18-04:00 | Andrew R. Goad | Publish Module 2 / G3 v2.0.0
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65 | f43ea8cb87523f477142fba2acea1be254c69e1a 2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a | 2026-08-15T01:20:20-04:00 | Andrew R. Goad | Merge pull request #1 from andrew-goad/release/module-2-g3-v2.0.0-final
2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a | f43ea8cb87523f477142fba2acea1be254c69e1a | 2026-08-15T00:38:03-04:00 | Andrew R. Goad | Publish Module 2 / G3 v2.0.0
f43ea8cb87523f477142fba2acea1be254c69e1a | 7f8d9aa888b0ae896b78ec412be5779f9c11e2ee | 2026-07-29T06:55:54-04:00 | Andrew R. Goad | Add full synthetic data release documentation

Relationship to publication commit:
Publication commit IS an ancestor of current remote main.

Commits after publication commit on current remote main:

Files changed after publication commit:

Tag binding check:
v2.1.0 still peels to publication commit: False

No mutation performed.
STOP HERE and return the full output.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fc61dfae-000b-4c0a-b653-0f20f143e672"></a>
## Assistant · C123-M00104

C123-M00104 · 2026-09-10T10:22:26.029778-04:00 · active path

Preceding visible parent: [C123-M00103](part-11.md#m-d8bac3c7-30d7-463d-af98-7b21e741fd34)

<!-- BEGIN_SOURCE_MESSAGE -->
The apparent failure is in the **Phase M0 parsing code**, not in the repository state.

The decisive facts in your output are:

- `Remote main` is still exactly `fd9f67b6d1d7fc848d315bcb696487b82c9a8046`.
- `origin/main` fetches to that same commit.
- There are **no commits after the publication commit**.
- There are **no files changed after the publication commit**.

So the original Phase M stop, `"remote main changed"`, was itself a wrapper/parsing error.

The suspicious lines are:

```text
Remote tag object:    c
Remote tag commit:    f
```

Those are obviously truncated to the first characters of the real SHAs. That happened because my PowerShell expression indexed the string incorrectly after pipeline grouping. The later comparison:

```text
v2.1.0 still peels to publication commit: False
```

is therefore invalid evidence; it compared `"f"` to the 40-character commit SHA.

Do **not** change the tag or repository. We should simply reverify the tag with a safer parser and then complete Phase M.

Run this corrected, read-only verification block first:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'

    $Tag = 'module-2-g3-v2.1.0'
    $ExpectedTagObject = 'cdef0c49eb37d0cc72444c0829c253e09eee050a'
    $ExpectedCommit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'

    $OldTag = 'module-2-g3-v2.0.0'
    $ExpectedOldTagObject = 'fcf32b615142a06075a7fccede26a97042ca8194'
    $ExpectedOldCommit = '500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65'

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE M0-R2 — CORRECTED REMOTE TAG VERIFICATION"
    Write-Host "============================================================"

    $RemoteMainLine = git -C $Repo ls-remote origin refs/heads/main

    if ($LASTEXITCODE -ne 0 -or -not $RemoteMainLine) {
        throw "STOP: unable to resolve remote main."
    }

    $RemoteMain = ($RemoteMainLine -split '\s+')[0].ToLowerInvariant()

    $NewRaw = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$Tag" `
            "refs/tags/$Tag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to query new remote tag."
    }

    $NewObjectLine = $NewRaw |
        Where-Object { $_ -like "*refs/tags/$Tag" } |
        Select-Object -First 1

    $NewCommitLine = $NewRaw |
        Where-Object { $_ -like "*refs/tags/$Tag^{}" } |
        Select-Object -First 1

    if (-not $NewObjectLine -or -not $NewCommitLine) {
        throw "STOP: new annotated tag did not resolve to object + peeled commit."
    }

    $NewObject = ($NewObjectLine -split '\s+')[0].ToLowerInvariant()
    $NewCommit = ($NewCommitLine -split '\s+')[0].ToLowerInvariant()

    $OldRaw = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$OldTag" `
            "refs/tags/$OldTag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to query historical tag."
    }

    $OldObjectLine = $OldRaw |
        Where-Object { $_ -like "*refs/tags/$OldTag" } |
        Select-Object -First 1

    $OldCommitLine = $OldRaw |
        Where-Object { $_ -like "*refs/tags/$OldTag^{}" } |
        Select-Object -First 1

    if (-not $OldObjectLine -or -not $OldCommitLine) {
        throw "STOP: historical annotated tag did not resolve exactly."
    }

    $OldObject = ($OldObjectLine -split '\s+')[0].ToLowerInvariant()
    $OldCommit = ($OldCommitLine -split '\s+')[0].ToLowerInvariant()

    Write-Host "Remote main:          $RemoteMain"
    Write-Host ""
    Write-Host "New tag object:       $NewObject"
    Write-Host "New peeled commit:    $NewCommit"
    Write-Host ""
    Write-Host "Old tag object:       $OldObject"
    Write-Host "Old peeled commit:    $OldCommit"
    Write-Host ""

    if ($RemoteMain -ne $ExpectedCommit) {
        throw "STOP: remote main differs from publication commit."
    }

    if ($NewObject -ne $ExpectedTagObject) {
        throw "STOP: v2.1.0 tag object mismatch."
    }

    if ($NewCommit -ne $ExpectedCommit) {
        throw "STOP: v2.1.0 tag target mismatch."
    }

    if ($OldObject -ne $ExpectedOldTagObject) {
        throw "STOP: historical v2.0.0 tag object mismatch."
    }

    if ($OldCommit -ne $ExpectedOldCommit) {
        throw "STOP: historical v2.0.0 tag target mismatch."
    }

    Write-Host "REMOTE_MAIN_BINDING = PASS"
    Write-Host "NEW_TAG_BINDING = PASS"
    Write-Host "HISTORICAL_TAG_PRESERVATION = PASS"
    Write-Host ""
    Write-Host "No mutation performed."
    Write-Host "STOP HERE and return this output."
}
```

Expected exact result:

```text
Remote main:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

New tag object:
cdef0c49eb37d0cc72444c0829c253e09eee050a

New peeled commit:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Old tag object:
fcf32b615142a06075a7fccede26a97042ca8194

Old peeled commit:
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

REMOTE_MAIN_BINDING = PASS
NEW_TAG_BINDING = PASS
HISTORICAL_TAG_PRESERVATION = PASS
```

If that passes, we will **not need another diagnostic cycle**. I’ll give you the corrected Phase M closure block using this safer parsing pattern and we can finish the release-closure package.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6f231e36-a303-4411-8f89-bf7069151290"></a>
## Andrew / user · C123-M00105

C123-M00105 · 2026-09-10T10:24:21.266000-04:00 · active path

Preceding visible parent: [C123-M00104](part-11.md#m-fc61dfae-000b-4c0a-b653-0f20f143e672)

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE M0-R2 — CORRECTED REMOTE TAG VERIFICATION
============================================================
Remote main:          fd9f67b6d1d7fc848d315bcb696487b82c9a8046

New tag object:       cdef0c49eb37d0cc72444c0829c253e09eee050a
New peeled commit:    fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Old tag object:       fcf32b615142a06075a7fccede26a97042ca8194
Old peeled commit:    500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

REMOTE_MAIN_BINDING = PASS
NEW_TAG_BINDING = PASS
HISTORICAL_TAG_PRESERVATION = PASS

No mutation performed.
STOP HERE and return this output.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4ee6aa35-7496-4764-bc47-5aef5a2d7bf8"></a>
## Assistant · C123-M00106

C123-M00106 · 2026-09-10T10:24:25.027265-04:00 · active path

Preceding visible parent: [C123-M00105](part-11.md#m-6f231e36-a303-4411-8f89-bf7069151290)

<!-- BEGIN_SOURCE_MESSAGE -->
The remote binding is now cleanly re-established:

```text
REMOTE_MAIN_BINDING = PASS
NEW_TAG_BINDING = PASS
HISTORICAL_TAG_PRESERVATION = PASS
```

The earlier Phase M stop was therefore a parser defect, not a repository-state problem. We can now complete the final closure package without changing the repository or either tag.

Run this corrected Phase M block. It uses the safer remote-tag parsing pattern that just passed, reads the already completed Phase J/K receipts, incorporates the owner-confirmed public-navigation result, and produces the final closure ZIP plus SHA-256 sidecar.

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'

    $Commit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $Tree   = 'fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb'

    $NewTag = 'module-2-g3-v2.1.0'
    $NewTagObject = 'cdef0c49eb37d0cc72444c0829c253e09eee050a'

    $OldTag = 'module-2-g3-v2.0.0'
    $OldTagObject = 'fcf32b615142a06075a7fccede26a97042ca8194'
    $OldTagCommit = '500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65'

    $ReleaseUrl = 'https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/module-2-g3-v2.1.0'
    $PublishedAt = '2026-09-10T13:59:29Z'

    $PhaseH = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_H_20260910T135054341Z_007dc7ce'
    $PhaseJ = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_J_20260910T140346449Z_a425ebc6'
    $PhaseK = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_K_20260910T140834154Z_c43ee4c6'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Root = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_M_RELEASE_CLOSURE_${Stamp}"
    $Package = Join-Path $Root 'MSBF_RELEASE_CLOSURE_R1_20260910'

    New-Item -ItemType Directory -Path $Package -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $Package 'evidence') -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE M — FINAL RELEASE CLOSURE"
    Write-Host "============================================================"

    # ------------------------------------------------------------
    # 1. Fresh final remote binding — corrected parser
    # ------------------------------------------------------------

    $RemoteMainLine = git -C $Repo ls-remote origin refs/heads/main

    if ($LASTEXITCODE -ne 0 -or -not $RemoteMainLine) {
        throw "STOP: unable to resolve remote main."
    }

    $RemoteMain = ($RemoteMainLine -split '\s+')[0].ToLowerInvariant()

    $NewRaw = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$NewTag" `
            "refs/tags/$NewTag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to resolve new remote tag."
    }

    $NewObjectLine = $NewRaw |
        Where-Object { $_ -like "*refs/tags/$NewTag" } |
        Select-Object -First 1

    $NewCommitLine = $NewRaw |
        Where-Object { $_ -like "*refs/tags/$NewTag^{}" } |
        Select-Object -First 1

    if (-not $NewObjectLine -or -not $NewCommitLine) {
        throw "STOP: new annotated tag did not resolve exactly."
    }

    $NewObj = ($NewObjectLine -split '\s+')[0].ToLowerInvariant()
    $NewCommit = ($NewCommitLine -split '\s+')[0].ToLowerInvariant()

    $OldRaw = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$OldTag" `
            "refs/tags/$OldTag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to resolve historical remote tag."
    }

    $OldObjectLine = $OldRaw |
        Where-Object { $_ -like "*refs/tags/$OldTag" } |
        Select-Object -First 1

    $OldCommitLine = $OldRaw |
        Where-Object { $_ -like "*refs/tags/$OldTag^{}" } |
        Select-Object -First 1

    if (-not $OldObjectLine -or -not $OldCommitLine) {
        throw "STOP: historical annotated tag did not resolve exactly."
    }

    $OldObj = ($OldObjectLine -split '\s+')[0].ToLowerInvariant()
    $OldCommit = ($OldCommitLine -split '\s+')[0].ToLowerInvariant()

    if ($RemoteMain -ne $Commit) {
        throw "STOP: remote main differs from publication commit."
    }

    if ($NewObj -ne $NewTagObject) {
        throw "STOP: new tag object changed."
    }

    if ($NewCommit -ne $Commit) {
        throw "STOP: new tag target changed."
    }

    if ($OldObj -ne $OldTagObject) {
        throw "STOP: historical tag object changed."
    }

    if ($OldCommit -ne $OldTagCommit) {
        throw "STOP: historical tag target changed."
    }

    # ------------------------------------------------------------
    # 2. Read Phase J / K completed receipts
    # ------------------------------------------------------------

    $JPath = Join-Path $PhaseJ `
        'MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION_RECOVERED.json'

    $KPath = Join-Path $PhaseK `
        'MSBF_PHASE_K_WINDOWS_HOSTED_EXTRACTION.json'

    if (-not (Test-Path -LiteralPath $JPath)) {
        throw "STOP: Phase J receipt missing."
    }

    if (-not (Test-Path -LiteralPath $KPath)) {
        throw "STOP: Phase K receipt missing."
    }

    $J = Get-Content -LiteralPath $JPath -Raw | ConvertFrom-Json
    $K = Get-Content -LiteralPath $KPath -Raw | ConvertFrom-Json

    if ($J.HostedAssetVerification -ne 'PASS') {
        throw "STOP: Phase J is not PASS."
    }

    if ($K.WindowsHostedExtraction -ne 'PASS') {
        throw "STOP: Phase K is not PASS."
    }

    if ($J.VerifiedHostedAssetCount -ne 4) {
        throw "STOP: Phase J verified asset count is not 4."
    }

    if ($K.WindowsNativeExtractionPassCount -ne 4) {
        throw "STOP: Phase K extraction pass count is not 4."
    }

    if ($K.ExtractedReadFailureTotal -ne 0) {
        throw "STOP: Phase K contains extracted-file read failures."
    }

    # ------------------------------------------------------------
    # 3. Final hosted asset table
    # ------------------------------------------------------------

    $AssetRows = @(
        $J.AssetResults |
        ForEach-Object {
            [pscustomobject]@{
                Name = $_.Name
                Bytes = [int64]$_.DownloadedBytes
                Sha256 = $_.DownloadedSha256
                HostedIdentity = $_.Status
                WindowsExtraction = 'PASS'
            }
        }
    )

    if ($AssetRows.Count -ne 4) {
        throw "STOP: final hosted-asset population is not 4."
    }

    $AssetRows |
        Export-Csv `
            -LiteralPath (Join-Path $Package 'HOSTED_ASSET_FINAL_VERIFICATION.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 4. Current Git / working-tree evidence
    # ------------------------------------------------------------

    $LocalHead = (git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $LocalTree = (git -C $Repo rev-parse 'HEAD^{tree}').Trim().ToLowerInvariant()
    $Status = @(git -C $Repo status --porcelain=v1)

    if ($LocalHead -ne $Commit) {
        throw "STOP: local HEAD changed."
    }

    if ($LocalTree -ne $Tree) {
        throw "STOP: local tree changed."
    }

    if ($Status.Count -ne 0) {
        throw "STOP: local working tree is not clean."
    }

    # ------------------------------------------------------------
    # 5. Machine-readable release closure record
    # ------------------------------------------------------------

    $Closure = [pscustomobject]@{
        SchemaVersion = '1.0'
        Record = 'MSBF_RELEASE_CLOSURE'

        OperatingModel = 'IA-GOV-20260822-001'
        ControllingAcceptance = 'IA-D-R20-INT-001'
        PublicationAuthority = 'IA-PUB-R20-INTEGRATED-001'

        Release = [pscustomobject]@{
            Repository = 'andrew-goad/merchant-sales-based-financing-strategy-simulator'
            StableLabel = $NewTag
            ReleaseUrl = $ReleaseUrl
            PublishedAt = $PublishedAt

            PublicationCommit = $Commit
            PublicationTree = $Tree

            RemoteMain = $RemoteMain
            NewTagObject = $NewObj
            NewTagPeeledCommit = $NewCommit
        }

        HistoricalIntegrity = [pscustomobject]@{
            HistoricalTag = $OldTag
            HistoricalTagObject = $OldObj
            HistoricalTagPeeledCommit = $OldCommit
            HistoricalTagPreserved = $true
        }

        HostedAssets = $AssetRows

        WindowsHostedExtraction = [pscustomobject]@{
            AssetsTested = 4
            ExplorerShellOpenPasses = 4
            NativeExtractionPasses = 4
            ExtractedReadFailures = 0
            Result = 'PASS'
        }

        AnonymousNavigation = [pscustomobject]@{
            OwnerConfirmedPublicRepositoryAccess = $true
            OwnerConfirmedRootReadmeRenders = $true
            OwnerConfirmedImagesRender = $true
            OwnerConfirmedLinksOperational = $true
            OwnerConfirmedReleasePageAccessible = $true
            Result = 'PASS'
        }

        Gates = [pscustomobject]@{
            ReleaseAssetPreflight = 'PASS'
            GitRemoteTagPreflight = 'PASS'
            R6StagingValidation = 'PASS'
            CheckoutMaterialization = 'PASS'
            PreCommitPublicationGate = 'PASS'
            StagedObjectCertification = 'PASS'
            CommitBinding = 'PASS'
            PrePushTagGate = 'PASS'
            RemoteBinding = 'PASS'
            PublicationEvent = 'PASS'
            HostedAssetIdentity = 'PASS'
            WindowsNativeHostedExtraction = 'PASS'
            AnonymousPublicNavigation = 'PASS'
        }

        PreservedBoundaries = [pscustomobject]@{
            SyntheticNonProductionScope = $true

            RouteB = `
                'QUALIFIED_ONLY_FOR_PORTABLE_CHECKPOINT_RESTORE_AND_ISOLATED_RETAINED_FINAL_M2_11_M2_12_G3V2_REPLAY'

            RouteD = 'NOT_QUALIFIED'

            CampaignScaleRuntimeAuthority = 'NOT_GRANTED'
            Module3RuntimeAuthority = 'NOT_GRANTED'

            ArbitraryFreshCampaignRunner = 'NOT_QUALIFIED'
        }

        GitMutationDuringClosureRecord = $false
        TagMutationDuringClosureRecord = $false

        FinalDisposition = 'RELEASE_CLOSURE_COMPLETE'
    }

    $ClosurePath = Join-Path $Package `
        'MSBF_RELEASE_CLOSURE_RECORD_R1_20260910.json'

    $Closure |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -LiteralPath $ClosurePath `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 6. Owner-readable closure summary
    # ------------------------------------------------------------

    $SummaryPath = Join-Path $Package `
        'MSBF_RELEASE_CLOSURE_SUMMARY_R1_20260910.md'

    @"
# MSBF Module 2 / G3 v2.1.0 — Release Closure

## Final disposition

**RELEASE_CLOSURE_COMPLETE**

The integrated MSBF Module 1 / Module 2 successor is published under:

`module-2-g3-v2.1.0`

## Publication identity

- Publication commit: `$Commit`
- Certified tree: `$Tree`
- Annotated v2.1.0 tag object: `$NewObj`
- v2.1.0 peeled commit: `$NewCommit`
- Published: `$PublishedAt`
- Release: $ReleaseUrl

## Historical integrity

The historical `module-2-g3-v2.0.0` tag remains unchanged:

- Tag object: `$OldObj`
- Peeled commit: `$OldCommit`

The v2.1.0 release is prospective supersession, not a rewrite of the historical v2.0.0 event.

## Hosted release assets

All four actual GitHub-hosted custom release ZIPs reproduced the locked byte sizes and SHA-256 identities.

All four hosted copies were then tested on Windows:

- Explorer ZIP-shell open: **4 / 4 PASS**
- Windows PowerShell Expand-Archive: **4 / 4 PASS**
- Extracted-file read failures: **0**

## Public navigation

The owner confirmed:

- public repository access;
- root README renders;
- accepted images render;
- documentation/navigation links operate;
- the published v2.1.0 release page opens successfully.

## Authority

Release closure remains linked to:

- `IA-GOV-20260822-001`
- `IA-D-R20-INT-001`
- `IA-PUB-R20-INTEGRATED-001`

## Preserved execution boundaries

The portfolio remains deterministic synthetic / non-production.

Route B remains qualified only for portable checkpoint restore plus isolated retained-final M2.11 / M2.12 / G3-v2 replay.

Route D remains `NOT_QUALIFIED`.

This release does not grant Campaign Scale or Module 3 runtime/database authority.

A generalized arbitrary-new-campaign runner is not represented as qualified.
"@ |
        Set-Content `
            -LiteralPath $SummaryPath `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 7. Campaign Scale / Module 3 continuation note
    # ------------------------------------------------------------

    $HandoffPath = Join-Path $Package `
        'CAMPAIGN_SCALE_MODULE3_REBASE_HANDOFF.md'

    @"
# Campaign Scale / Module 3 Rebase Handoff

The public Module 1 / Module 2 successor baseline is now:

- Stable release: `module-2-g3-v2.1.0`
- Publication commit: `$Commit`
- Certified tree: `$Tree`

Campaign Scale and Module 3 may rebase their static integration/source assumptions onto this published successor where their own governing authorities permit.

This release does **not** grant new runtime or database authority to either workstream.

## Campaign Scale

Preserve the separate Campaign Scale execution gate. Planned 2,500 / 25,000 scale work and streamlined campaign orchestration remain future maturation work. Do not treat the historical program catalog as a qualified arbitrary-new-campaign execution loop.

## Module 3

Preserve the separate Module 3 construction/execution authorities. Static rebase may reference the published v2.1.0 Module 1 / Module 2 successor, but database connection and runtime execution remain governed separately.

## Route qualification

Route B remains limited to the accepted portable-checkpoint restore plus isolated retained-final M2.11 / M2.12 / G3-v2 replay.

Route D remains NOT_QUALIFIED.
"@ |
        Set-Content `
            -LiteralPath $HandoffPath `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 8. Copy core receipts
    # ------------------------------------------------------------

    Copy-Item `
        -LiteralPath (Join-Path $PhaseH 'MSBF_PHASE_H_REMOTE_BINDING.json') `
        -Destination (Join-Path $Package 'evidence\PHASE_H_REMOTE_BINDING.json')

    Copy-Item `
        -LiteralPath $JPath `
        -Destination (Join-Path $Package 'evidence\PHASE_J_HOSTED_ASSET_VERIFICATION.json')

    Copy-Item `
        -LiteralPath $KPath `
        -Destination (Join-Path $Package 'evidence\PHASE_K_WINDOWS_HOSTED_EXTRACTION.json')

    # ------------------------------------------------------------
    # 9. Add explicit Phase L owner-confirmed receipt
    # ------------------------------------------------------------

    $PhaseL = [pscustomobject]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_PHASE_L_ANONYMOUS_PUBLIC_NAVIGATION'

        Repository = 'andrew-goad/merchant-sales-based-financing-strategy-simulator'
        ReleaseUrl = $ReleaseUrl

        RepositoryAccessiblePublicly = $true
        RootReadmeRenders = $true
        CoreImagesRender = $true
        NavigationLinksOperational = $true
        ReleasePageAccessible = $true

        EvidenceBasis = `
            'Owner browser confirmation and supplied repository-front-page printout.'

        Result = 'PASS'
    }

    $PhaseL |
        ConvertTo-Json -Depth 6 |
        Set-Content `
            -LiteralPath (Join-Path $Package 'evidence\PHASE_L_PUBLIC_NAVIGATION.json') `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 10. Build manifest
    # ------------------------------------------------------------

    function Get-PackageRows {
        param([string]$RootPath)

        $base = [IO.Path]::GetFullPath($RootPath).TrimEnd('\') + '\'

        Get-ChildItem -LiteralPath $RootPath -Recurse -File |
            Sort-Object FullName |
            ForEach-Object {
                [pscustomobject]@{
                    Path = $_.FullName.Substring($base.Length).Replace('\','/')
                    Bytes = [int64]$_.Length
                    Sha256 = (
                        Get-FileHash `
                            -LiteralPath $_.FullName `
                            -Algorithm SHA256
                    ).Hash.ToLowerInvariant()
                }
            }
    }

    $RowsBeforeManifest = @(Get-PackageRows $Package)

    $RowsBeforeManifest |
        Export-Csv `
            -LiteralPath (Join-Path $Package 'MANIFEST.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 11. SHA256SUMS after MANIFEST exists
    # ------------------------------------------------------------

    $AllBeforeSums = @(Get-PackageRows $Package)

    $SumLines = foreach ($r in $AllBeforeSums) {
        "$($r.Sha256)  $($r.Path)"
    }

    $SumLines |
        Set-Content `
            -LiteralPath (Join-Path $Package 'SHA256SUMS.txt') `
            -Encoding ASCII

    # ------------------------------------------------------------
    # 12. Final manifest including SHA256SUMS itself
    # ------------------------------------------------------------

    $FinalRows = @(Get-PackageRows $Package)

    $FinalRows |
        Export-Csv `
            -LiteralPath (Join-Path $Package 'MANIFEST_FINAL.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 13. Create ZIP
    # ------------------------------------------------------------

    $ZipPath = "$Package.zip"

    Compress-Archive `
        -Path (Join-Path $Package '*') `
        -DestinationPath $ZipPath `
        -CompressionLevel Optimal

    if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
        throw "STOP: closure ZIP was not created."
    }

    $ZipItem = Get-Item -LiteralPath $ZipPath
    $ZipHash = (
        Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    "$ZipHash  $($ZipItem.Name)" |
        Set-Content `
            -LiteralPath "$ZipPath.sha256" `
            -Encoding ASCII

    # ------------------------------------------------------------
    # 14. ZIP integrity/readability
    # ------------------------------------------------------------

    Add-Type -AssemblyName System.IO.Compression.FileSystem

    $z = [System.IO.Compression.ZipFile]::OpenRead($ZipPath)

    try {
        $ZipEntries = $z.Entries.Count

        foreach ($entry in $z.Entries) {

            if ([string]::IsNullOrEmpty($entry.Name)) {
                continue
            }

            $stream = $entry.Open()

            try {
                $buffer = New-Object byte[] 1048576

                while ($stream.Read($buffer,0,$buffer.Length) -gt 0) {
                }
            }
            finally {
                $stream.Dispose()
            }
        }
    }
    finally {
        $z.Dispose()
    }

    # ------------------------------------------------------------
    # 15. Final nonmutation confirmation
    # ------------------------------------------------------------

    $FinalLocalHead = (git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $FinalStatus = @(git -C $Repo status --porcelain=v1)

    if ($FinalLocalHead -ne $Commit) {
        throw "STOP: local HEAD changed during closure packaging."
    }

    if ($FinalStatus.Count -ne 0) {
        throw "STOP: working tree changed during closure packaging."
    }

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "RELEASE_CLOSURE = COMPLETE"
    Write-Host "============================================================"
    Write-Host "Publication commit:"
    Write-Host "  $Commit"
    Write-Host "Certified tree:"
    Write-Host "  $Tree"
    Write-Host ""
    Write-Host "New v2.1.0 tag object:"
    Write-Host "  $NewObj"
    Write-Host "New v2.1.0 peeled commit:"
    Write-Host "  $NewCommit"
    Write-Host ""
    Write-Host "Preserved v2.0.0 tag object:"
    Write-Host "  $OldObj"
    Write-Host "Preserved v2.0.0 peeled commit:"
    Write-Host "  $OldCommit"
    Write-Host ""
    Write-Host "Hosted asset identity:        4 / 4 PASS"
    Write-Host "Windows hosted extraction:    4 / 4 PASS"
    Write-Host "Anonymous/public navigation:  PASS"
    Write-Host ""
    Write-Host "Closure ZIP:"
    Write-Host "  $ZipPath"
    Write-Host "Bytes:"
    Write-Host "  $($ZipItem.Length)"
    Write-Host "SHA-256:"
    Write-Host "  $ZipHash"
    Write-Host "ZIP entries:"
    Write-Host "  $ZipEntries"
    Write-Host ""
    Write-Host "Git mutation during closure:  NONE"
    Write-Host "Tag mutation during closure:  NONE"
    Write-Host "============================================================"
}
```

The expected terminal state is:

```text
RELEASE_CLOSURE = COMPLETE

Publication commit:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Certified tree:
fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb

New v2.1.0 tag object:
cdef0c49eb37d0cc72444c0829c253e09eee050a

Preserved v2.0.0 tag object:
fcf32b615142a06075a7fccede26a97042ca8194

Hosted asset identity:        4 / 4 PASS
Windows hosted extraction:    4 / 4 PASS
Anonymous/public navigation:  PASS

Git mutation during closure:  NONE
Tag mutation during closure:  NONE
```

Return the final block showing the **closure ZIP path, bytes, SHA-256, and ZIP entry count**. Once that passes, the Module 1/2 remediation and republication cycle is genuinely closed, and we can move to a concise Campaign Scale / Module 3 rebase handoff.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a12bd895-d23b-4cd6-8cdc-07802d70f69f"></a>
## Andrew / user · C123-M00107

C123-M00107 · 2026-09-10T10:27:34.080000-04:00 · active path

Preceding visible parent: [C123-M00106](part-11.md#m-4ee6aa35-7496-4764-bc47-5aef5a2d7bf8)

**Editorial record note:** Attachment references: MSBF_RELEASE_CLOSURE_R1_20260910.zip; MSBF_RELEASE_CLOSURE_R1_20260910.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE M — FINAL RELEASE CLOSURE
============================================================

============================================================
RELEASE_CLOSURE = COMPLETE
============================================================
Publication commit:
  fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Certified tree:
  fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb

New v2.1.0 tag object:
  cdef0c49eb37d0cc72444c0829c253e09eee050a
New v2.1.0 peeled commit:
  fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Preserved v2.0.0 tag object:
  fcf32b615142a06075a7fccede26a97042ca8194
Preserved v2.0.0 peeled commit:
  500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

Hosted asset identity:        4 / 4 PASS
Windows hosted extraction:    4 / 4 PASS
Anonymous/public navigation:  PASS

Closure ZIP:
  D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_M_RELEASE_CLOSURE_20260910T142621377Z\MSBF_RELEASE_CLOSURE_R1_20260910.zip
Bytes:
  10352
SHA-256:
  092c812dea5cdd63cabf9f86b737489e9d6ab2781b20088943840b49561df957
ZIP entries:
  11

Git mutation during closure:  NONE
Tag mutation during closure:  NONE
============================================================
<!-- END_SOURCE_MESSAGE -->


<a id="m-c7ae3b87-6971-4450-8b8b-a3fce6776d58"></a>
## Assistant · C123-M00108

C123-M00108 · 2026-09-10T10:28:31.215978-04:00 · active path

Preceding visible parent: [C123-M00107](part-11.md#m-a12bd895-d23b-4cd6-8cdc-07802d70f69f)

<!-- BEGIN_SOURCE_MESSAGE -->
**Release closure is complete.** I independently rechecked the uploaded closure carrier itself:

- ZIP bytes: **10,352**
- SHA-256: `092c812dea5cdd63cabf9f86b737489e9d6ab2781b20088943840b49561df957`
- Sidecar: exact match
- ZIP entries: **11**
- Archive opens cleanly and contains the expected closure record, summary, Phase H/J/K/L evidence, hosted-asset verification, manifests/checksums, and Campaign Scale / Module 3 rebase handoff.

The controlling final identities are now:

```text
Publication commit
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Certified tree
fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb

module-2-g3-v2.1.0 tag object
cdef0c49eb37d0cc72444c0829c253e09eee050a

module-2-g3-v2.1.0 peeled commit
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Preserved module-2-g3-v2.0.0 tag object
fcf32b615142a06075a7fccede26a97042ca8194

Preserved v2.0.0 peeled commit
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

Closure carrier SHA-256
092c812dea5cdd63cabf9f86b737489e9d6ab2781b20088943840b49561df957
```

The substantive end state is therefore achieved: remote binding passed, v2.1.0 was published, all four hosted release ZIPs matched their locked identities, all four passed Windows-native hosted extraction, anonymous/public navigation passed, and the historical v2.0.0 tag was preserved unchanged. No Git or tag mutation occurred during closure packaging.

You can retain this as the canonical local closure artifact:

MSBF release-closure package (historical reference: `sandbox:[session]/MSBF_RELEASE_CLOSURE_R1_20260910.zip`; referenced bytes not established here)

SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_RELEASE_CLOSURE_R1_20260910.zip.sha256`; referenced bytes not established here)

For the next workstream, **Campaign Scale and Module 3 should now treat the published `module-2-g3-v2.1.0` successor as the current Module 1/2 baseline**, while preserving their own separate runtime/database authorities. Route B remains limited to the accepted checkpoint-restore + isolated retained-final M2.11/M2.12/G3-v2 replay scope; Route D remains `NOT_QUALIFIED`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-93e94c9f-bceb-4b5c-a8a4-e8023a189037"></a>
## Andrew / user · C123-M00109

C123-M00109 · 2026-09-10T10:32:16.384000-04:00 · active path

Preceding visible parent: [C123-M00108](part-11.md#m-c7ae3b87-6971-4450-8b8b-a3fce6776d58)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 4e9eaee1-7aa0-439b-a600-8fec9e6f4fac.png

<!-- BEGIN_SOURCE_MESSAGE -->
update these: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-1449d1fe-d3a8-4364-96f3-2dcc14b6ece7"></a>
## Assistant · C123-M00110

C123-M00110 · 2026-09-10T10:32:18.243749-04:00 · active path

Preceding visible parent: [C123-M00109](part-11.md#m-93e94c9f-bceb-4b5c-a8a4-e8023a189037)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The **About** description and topic tags are still carrying the older framing. Given the v2.1.0 publication, I would update both.

### About

I recommend:

> **Governed merchant credit intelligence for sales-based financing: evidence, structure search, decision authority, servicing, portfolio analytics, and explainability.**

That is stronger than the current description because it presents the repository as the integrated portfolio it has become rather than primarily as a “PostgreSQL simulator.” It also brings forward the differentiators we deliberately emphasized in R6—governed structure search, authority, portfolio intelligence, and explainability.

If you want PostgreSQL retained explicitly, my second choice is:

> **Governed merchant credit intelligence for sales-based financing: PostgreSQL decisioning, structure search, servicing, portfolio analytics, and explainability.**

I prefer the **first** version.

### Topics

I would replace the current set with this tighter portfolio-oriented set:

```text
credit-risk
data-governance
decision-engine
explainable-ai
financial-services
merchant-finance
model-governance
portfolio-analytics
postgresql
power-bi
risk-analytics
strategy-simulation
synthetic-data
```

The important changes are:

- **Add `decision-engine`** — much more representative of M2.2–M2.10 and the governed structure/authority system.
- **Add `explainable-ai`** — makes P03/business-facing explainability discoverable. I am comfortable with this as a repository topic, provided the README continues to make clear that Power BI explains retained source-engine decisions rather than autonomously making them.
- **Add `power-bi`** — P01–P04 are now a substantial accepted publication component.
- Change **`merchant-funding` → `merchant-finance`** — broader and more professional for what the portfolio demonstrates.
- Remove **`pricing-analytics`** — pricing/economics remain important, but it is no longer one of the best top-level descriptors.
- Remove **`sql`** — redundant beside `postgresql`.
- Remove **`credit-risk`?** **No—keep it.** It remains a core domain.
- I would also retire the generic **`merchant-funding`** rather than carrying both it and `merchant-finance`.

That gives the GitHub sidebar a much better description of what someone now encounters on the front page: **merchant evidence → governed structure search → explicit authority → funded lifecycle → portfolio intelligence/explainability**, rather than the older SQL/simulator-heavy identity.

Because this is GitHub repository metadata rather than a repository-tree change, it **does not require moving the v2.1.0 tag or altering the release commit**. It would, however, be a post-publication metadata change, so I would record the final About/topics in the release-closure addendum if we want the closure evidence to remain exhaustive.
<!-- END_SOURCE_MESSAGE -->


<a id="m-974429e3-d868-4e90-8746-aea1f1fcd9a1"></a>
## Andrew / user · C123-M00111

C123-M00111 · 2026-09-10T10:35:11.074000-04:00 · active path

Preceding visible parent: [C123-M00110](part-11.md#m-1449d1fe-d3a8-4364-96f3-2dcc14b6ece7)

<!-- BEGIN_SOURCE_MESSAGE -->
merchant finance does not auto populate. hence why we had merchant-funding
<!-- END_SOURCE_MESSAGE -->


<a id="m-027fadd0-9450-47fc-926f-9f6076f7cb17"></a>
## Assistant · C123-M00112

C123-M00112 · 2026-09-10T10:35:12.618292-04:00 · active path

Preceding visible parent: [C123-M00111](part-11.md#m-974429e3-d868-4e90-8746-aea1f1fcd9a1)

<!-- BEGIN_SOURCE_MESSAGE -->
Right—that explains the existing choice. **Keep `merchant-funding`**. I would not replace a valid GitHub topic with a term GitHub isn't accepting/autocompleting.

My revised recommendation is:

```text
credit-risk
data-governance
decision-engine
explainable-ai
financial-services
merchant-funding
model-governance
portfolio-analytics
postgresql
power-bi
risk-analytics
strategy-simulation
synthetic-data
```

So relative to what you have now:

- **Keep:** `credit-risk`, `data-governance`, `financial-services`, `merchant-funding`, `model-governance`, `portfolio-analytics`, `postgresql`, `risk-analytics`, `strategy-simulation`, `synthetic-data`
- **Add:** `decision-engine`, `explainable-ai`, `power-bi`
- **Remove:** `pricing-analytics`, `sql`

And I still recommend changing the About text to:

> **Governed merchant credit intelligence for sales-based financing: evidence, structure search, decision authority, servicing, portfolio analytics, and explainability.**

That combination better reflects what we just published while retaining `merchant-funding` as the practical GitHub topic.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fca37e92-7bee-484f-b87e-2fcd8d1b6dda"></a>
## Andrew / user · C123-M00113

C123-M00113 · 2026-09-10T10:43:10.148000-04:00 · active path

Preceding visible parent: [C123-M00112](part-11.md#m-027fadd0-9450-47fc-926f-9f6076f7cb17)

<!-- BEGIN_SOURCE_MESSAGE -->
I'd like to pass a summary package of the updated merchant based sales-financing to my resume chat. this should be detail that the resume will ingest and use to tell the story of the merchant based sales-financing work I've done. please be detailed and comprehensive. give the resume chat everything it will need to tell this story at an exceptional level.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7b511d99-89e1-4f41-b4bc-265c5e75c519"></a>
## Assistant · C123-M00114

C123-M00114 · 2026-09-10T10:44:11.055095-04:00 · active path

Preceding visible parent: [C123-M00113](part-11.md#m-fca37e92-7bee-484f-b87e-2fcd8d1b6dda)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll build the résumé handoff around the published v2.1.0 portfolio: your contributions, problems solved, evidence-backed achievements, and interview stories, while clearly separating demonstrated capabilities from synthetic results.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d1a0f279-2fae-4ebf-9ea9-c6a2b568d483"></a>
## Assistant · C123-M00115

C123-M00115 · 2026-09-10T10:47:21.477824-04:00 · active path

Preceding visible parent: [C123-M00114](part-11.md#m-7b511d99-89e1-4f41-b4bc-265c5e75c519)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll also include role-specific résumé language and clearly separate future roadmap items from work already completed and published.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2761a7e1-dff9-40ac-a988-c682c37c8a45"></a>
## Assistant · C123-M00116

C123-M00116 · 2026-09-10T11:05:29.838004-04:00 · active path

Preceding visible parent: [C123-M00115](part-11.md#m-d1a0f279-2fae-4ebf-9ea9-c6a2b568d483)

<!-- BEGIN_SOURCE_MESSAGE -->
The central narrative is broader than a simulator: you reshaped credit decisioning, expanded governed structure search, preserved authority boundaries, and translated technical rationale into Power BI explainability.
<!-- END_SOURCE_MESSAGE -->
