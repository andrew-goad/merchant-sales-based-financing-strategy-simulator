# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 10 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-09.md)
[Next part](part-11.md)

<a id="m-28bff249-0698-46b5-8e1e-07e2b84f96d1"></a>
## Assistant · C123-M00092

C123-M00092 · 2026-09-10T10:01:47.096493-04:00 · active path

Preceding visible parent: [C123-M00091](part-09.md#m-606551d3-584a-44f8-9f3b-cd5e2e53a7ec)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase I is complete: the GitHub release is now publicly published.** The supplied release-page capture shows `Module 2 / G3 v2.1.0 — Integrated Successor`, marked **Latest**, tied to `module-2-g3-v2.1.0` and commit `fd9f67b…`. It also shows the intended four custom ZIP assets. [export reference: filecite | turn33file0 | L1-L2]

The **“Assets 6”** count is expected: GitHub automatically adds **Source code (zip)** and **Source code (tar.gz)** to the four uploaded release assets. Those two GitHub-generated archives are **not** part of our four locked release-carrier population and should not be compared to the R20 hashes.

We can now record:

```text
PUBLICATION_EVENT = COMPLETE

Release:
Module 2 / G3 v2.1.0 — Integrated Successor

Tag:
module-2-g3-v2.1.0

Publication commit:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Custom locked assets shown:
4 / 4

GitHub-generated source archives:
2 — outside locked-asset verification scope

RELEASE_CLOSURE:
PENDING
```

The next mandatory gate is **Phase J: download the actual GitHub-hosted copies on Windows and prove all four remain byte-for-byte identical to the locked originals.** Do not click the assets manually; use this block so the hosted provenance is explicit and repeatable.

Paste this into the same PowerShell window:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $RepoSlug = 'andrew-goad/merchant-sales-based-financing-strategy-simulator'
    $Tag = 'module-2-g3-v2.1.0'

    $ExpectedCommit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $ExpectedTagObject = 'cdef0c49eb37d0cc72444c0829c253e09eee050a'

    $Assets = @(
        [pscustomobject]@{
            Name = 'MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip'
            Bytes = 39382961
            Sha256 = 'b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746'
        },
        [pscustomobject]@{
            Name = 'MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip'
            Bytes = 31056035
            Sha256 = '1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a'
        },
        [pscustomobject]@{
            Name = 'MSBF_Visual_Publication_Candidate_R1_20260909.zip'
            Bytes = 125229642
            Sha256 = 'c2122d0c47cd1bd604dd372bb4aa662a61be86af0578c23ed768629cccd855b5'
        },
        [pscustomobject]@{
            Name = 'MSBF_Cohort_R3_Editorial_Patch_R1_20260908.zip'
            Bytes = 9613925
            Sha256 = 'aadcb403b662fc5e53280fd92357e53db4f4c9bcad6b1111ba286d61f9f2bcc3'
        }
    )

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)

    $DownloadDir = "D:\MSBF_HOSTED_VERIFY_v2_1_0_${Stamp}_${Suffix}"
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_J_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $DownloadDir | Out-Null
    New-Item -ItemType Directory -Path $EvidenceDir | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE J — ACTUAL HOSTED DOWNLOAD VERIFICATION"
    Write-Host "============================================================"
    Write-Host "Release:   https://github.com/$RepoSlug/releases/tag/$Tag"
    Write-Host "Downloads: $DownloadDir"
    Write-Host "Evidence:  $EvidenceDir"
    Write-Host ""

    # ------------------------------------------------------------
    # 1. Fresh Git remote binding immediately before download
    # ------------------------------------------------------------

    $Repo = 'D:\x\m'

    $remoteTag = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$Tag" `
            "refs/tags/$Tag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: could not query hosted tag."
    }

    $objLine = @(
        $remoteTag |
        Where-Object {
            $_ -match "refs/tags/$([regex]::Escape($Tag))$"
        }
    )

    $commitLine = @(
        $remoteTag |
        Where-Object {
            $_ -match "refs/tags/$([regex]::Escape($Tag))\^\{\}$"
        }
    )

    if ($objLine.Count -ne 1 -or $commitLine.Count -ne 1) {
        throw "STOP: hosted annotated tag could not be resolved exactly."
    }

    $remoteTagObject = (
        ($objLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $remoteTagCommit = (
        ($commitLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if ($remoteTagObject -ne $ExpectedTagObject) {
        throw "STOP: hosted tag object changed."
    }

    if ($remoteTagCommit -ne $ExpectedCommit) {
        throw "STOP: hosted tag target changed."
    }

    # ------------------------------------------------------------
    # 2. Read PUBLIC release metadata from GitHub API
    # ------------------------------------------------------------

    $ApiUri = "https://api.github.com/repos/$RepoSlug/releases/tags/$Tag"

    $Headers = @{
        'User-Agent' = 'MSBF-release-verification'
        'Accept' = 'application/vnd.github+json'
    }

    $Release = Invoke-RestMethod `
        -Uri $ApiUri `
        -Headers $Headers `
        -Method Get

    $Release |
        ConvertTo-Json -Depth 12 |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GITHUB_RELEASE_METADATA.json') `
            -Encoding UTF8

    if ($Release.tag_name -cne $Tag) {
        throw "STOP: GitHub release tag differs from expected tag."
    }

    if ($Release.draft -eq $true) {
        throw "STOP: release is unexpectedly a draft."
    }

    if ($Release.prerelease -eq $true) {
        throw "STOP: release is unexpectedly marked prerelease."
    }

    # GitHub API "assets" means uploaded release assets. The automatically
    # generated source-code archives are separate and are not part of this
    # four-carrier lock.
    $HostedCustomAssets = @($Release.assets)

    if ($HostedCustomAssets.Count -ne 4) {
        throw "STOP: GitHub API reports $($HostedCustomAssets.Count) uploaded assets; expected exactly 4."
    }

    $HostedNames = @($HostedCustomAssets | ForEach-Object name)

    $Missing = @(
        $Assets.Name |
        Where-Object { $_ -notin $HostedNames }
    )

    $Unexpected = @(
        $HostedNames |
        Where-Object { $_ -notin $Assets.Name }
    )

    if ($Missing.Count -ne 0 -or $Unexpected.Count -ne 0) {
        throw "STOP: hosted custom asset population differs from expected set."
    }

    # ------------------------------------------------------------
    # 3. Download each ACTUAL hosted asset into clean directory
    # ------------------------------------------------------------

    $Rows = New-Object System.Collections.Generic.List[object]

    foreach ($Expected in $Assets) {

        $Hosted = @(
            $HostedCustomAssets |
            Where-Object { $_.name -ceq $Expected.Name }
        )

        if ($Hosted.Count -ne 1) {
            throw "STOP: could not resolve unique hosted asset: $($Expected.Name)"
        }

        $Dest = Join-Path $DownloadDir $Expected.Name

        Write-Host ""
        Write-Host "Downloading hosted asset:"
        Write-Host "  $($Expected.Name)"

        # browser_download_url is obtained from the live GitHub release
        # metadata rather than constructed from the local filename.
        $DownloadUrl = [string]$Hosted[0].browser_download_url

        if ([string]::IsNullOrWhiteSpace($DownloadUrl)) {
            throw "STOP: hosted asset has no browser_download_url."
        }

        # Use Windows curl with redirect following and hard HTTP failure.
        & curl.exe `
            --fail `
            --location `
            --silent `
            --show-error `
            --output $Dest `
            $DownloadUrl

        if ($LASTEXITCODE -ne 0) {
            throw "STOP: hosted download failed: $($Expected.Name)"
        }

        if (-not (Test-Path -LiteralPath $Dest -PathType Leaf)) {
            throw "STOP: expected hosted download not created."
        }

        $Item = Get-Item -LiteralPath $Dest
        $Hash = (
            Get-FileHash -LiteralPath $Dest -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        $FileNamePass = ($Item.Name -ceq $Expected.Name)
        $SizePass = ($Item.Length -eq $Expected.Bytes)
        $HashPass = ($Hash -ceq $Expected.Sha256)

        $Pass = $FileNamePass -and $SizePass -and $HashPass

        $Rows.Add([pscustomobject]@{
            Name = $Item.Name

            DownloadUrl = $DownloadUrl

            GitHubApiAssetId = $Hosted[0].id
            GitHubApiBytes = $Hosted[0].size

            ExpectedBytes = $Expected.Bytes
            DownloadedBytes = $Item.Length

            ExpectedSha256 = $Expected.Sha256
            DownloadedSha256 = $Hash

            FilenamePass = $FileNamePass
            SizePass = $SizePass
            Sha256Pass = $HashPass

            Status = if ($Pass) { 'PASS' } else { 'FAIL' }
        })

        if (-not $Pass) {
            throw "STOP RELEASE CLOSURE: hosted asset identity mismatch: $($Expected.Name)"
        }

        Write-Host "  bytes:  $($Item.Length)"
        Write-Host "  sha256: $Hash"
        Write-Host "  PASS"
    }

    # ------------------------------------------------------------
    # 4. Ensure exactly four ZIPs in clean hosted-download directory
    # ------------------------------------------------------------

    $Downloaded = @(
        Get-ChildItem -LiteralPath $DownloadDir -File -Filter '*.zip'
    )

    if ($Downloaded.Count -ne 4) {
        throw "STOP: clean hosted verification directory contains $($Downloaded.Count) ZIPs; expected 4."
    }

    # ------------------------------------------------------------
    # 5. Evidence
    # ------------------------------------------------------------

    $Rows |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'HOSTED_ASSET_VERIFICATION.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $Receipt = [ordered]@{
        Task = 'MSBF_PHASE_J_HOSTED_ASSET_IDENTITY_VERIFICATION'

        Repository = $RepoSlug
        Tag = $Tag

        ReleaseUrl = $Release.html_url
        ReleaseName = $Release.name
        PublishedAt = $Release.published_at

        PublicationCommit = $ExpectedCommit
        TagObject = $remoteTagObject
        TagPeeledCommit = $remoteTagCommit

        GitHubUploadedAssetCount = $HostedCustomAssets.Count
        LockedHostedAssetCount = $Rows.Count

        HostedDownloadDirectory = $DownloadDir
        EvidenceDirectory = $EvidenceDir

        AssetResults = @($Rows)

        HostedHashesVerified = (
            @($Rows | Where-Object Status -ne 'PASS').Count -eq 0
        )

        WindowsNativeExtractionPerformed = $false
        AnonymousNavigationPerformed = $false

        HostedAssetVerification = 'PASS'
        ReleaseClosure = 'PENDING_WINDOWS_EXTRACTION_AND_PUBLIC_NAVIGATION'
    }

    $ReceiptPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION.json'

    $Receipt |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -LiteralPath $ReceiptPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "HOSTED_ASSET_VERIFICATION = PASS"
    Write-Host "============================================================"
    Write-Host "Release URL: $($Release.html_url)"
    Write-Host "Published:   $($Release.published_at)"
    Write-Host ""
    Write-Host "GitHub uploaded custom assets: $($HostedCustomAssets.Count)"
    Write-Host "Verified hosted assets:        $($Rows.Count)"
    Write-Host ""

    $Rows |
        Select-Object Name,DownloadedBytes,Sha256Pass,Status |
        Format-Table -AutoSize |
        Out-Host

    Write-Host "Hosted download directory:"
    Write-Host "  $DownloadDir"
    Write-Host ""
    Write-Host "Windows-native extraction: NOT YET PERFORMED"
    Write-Host "Anonymous navigation:      NOT YET PERFORMED"
    Write-Host ""
    Write-Host "RELEASE CLOSURE = PENDING"
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "STOP HERE."
    Write-Host "Do not extract the hosted ZIPs yet."
}
```

A successful result should show **4/4 exact PASS** against these hashes:

```text
R26
b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746

Power BI
1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a

Visual
c2122d0c47cd1bd604dd372bb4aa662a61be86af0578c23ed768629cccd855b5

Cohort
aadcb403b662fc5e53280fd92357e53db4f4c9bcad6b1111ba286d61f9f2bcc3
```

This is intentionally **not** yet the Windows-native extraction test. Phase J proves that the files we subsequently test are genuinely the copies downloaded from the published GitHub release—not the local originals.

Once it passes, return the console output and `MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION.json`. Then we'll run the required **Windows-native clean extraction of these exact hosted copies**, followed by anonymous/public navigation verification.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e5db9a4e-f2f2-444c-958c-9ed83a3a0db0"></a>
## Andrew / user · C123-M00093

C123-M00093 · 2026-09-10T10:04:12.594000-04:00 · active path

Preceding visible parent: [C123-M00092](part-10.md#m-28bff249-0698-46b5-8e1e-07e2b84f96d1)

<!-- BEGIN_SOURCE_MESSAGE -->
Release:   https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/module-2-g3-v2.1.0
Downloads: D:\MSBF_HOSTED_VERIFY_v2_1_0_20260910T140346449Z_a425ebc6
Evidence:  D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_J_20260910T140346449Z_a425ebc6
Downloading hosted asset:
MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip
bytes:  39382961
sha256: b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746
PASS
Downloading hosted asset:
MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip
bytes:  31056035
sha256: 1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a
PASS
Downloading hosted asset:
MSBF_Visual_Publication_Candidate_R1_20260909.zip
bytes:  125229642
sha256: c2122d0c47cd1bd604dd372bb4aa662a61be86af0578c23ed768629cccd855b5
PASS
Downloading hosted asset:
MSBF_Cohort_R3_Editorial_Patch_R1_20260908.zip
bytes:  9613925
sha256: aadcb403b662fc5e53280fd92357e53db4f4c9bcad6b1111ba286d61f9f2bcc3
PASS
OperationStopped:
Line |
271 |      $Receipt = [ordered]@{
|      ~~~~~~~~~~~~~~~~~~~~~~
| Argument types do not match
<!-- END_SOURCE_MESSAGE -->


<a id="m-70863ea5-1fac-4ace-bde7-8180cc9e9027"></a>
## Assistant · C123-M00094

C123-M00094 · 2026-09-10T10:04:16.702719-04:00 · active path

Preceding visible parent: [C123-M00093](part-10.md#m-e5db9a4e-f2f2-444c-958c-9ed83a3a0db0)

<!-- BEGIN_SOURCE_MESSAGE -->
The important part succeeded: **all four actual GitHub-hosted ZIPs downloaded and independently reproduced the exact locked byte sizes and SHA-256 hashes.** The failure happened afterward while my wrapper was constructing the PowerShell receipt object.

So this is **not a hosted-asset mismatch and does not require re-downloading anything**.

The likely cause is PowerShell choking on the generic `List[object]` when embedding `$Rows` inside the `[ordered]` receipt hashtable. We can recover deterministically from the already-downloaded hosted files.

Current disposition:

```text
PHASE_J_DOWNLOADS                 COMPLETE
HOSTED_ASSET_IDENTITY            4 / 4 EXACT PASS

R26 SHA-256
b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746

POWER BI SHA-256
1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a

VISUAL SHA-256
c2122d0c47cd1bd604dd372bb4aa662a61be86af0578c23ed768629cccd855b5

COHORT SHA-256
aadcb403b662fc5e53280fd92357e53db4f4c9bcad6b1111ba286d61f9f2bcc3

RECEIPT WRITING                    FAILED
RELEASE CLOSURE                    STILL PENDING
```

Run this **receipt-recovery block only**. It rehashes the four already-downloaded hosted files, re-reads the public release metadata, and writes the Phase J evidence without downloading or changing anything.

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $RepoSlug = 'andrew-goad/merchant-sales-based-financing-strategy-simulator'
    $Tag = 'module-2-g3-v2.1.0'

    $DownloadDir = 'D:\MSBF_HOSTED_VERIFY_v2_1_0_20260910T140346449Z_a425ebc6'
    $EvidenceDir = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_J_20260910T140346449Z_a425ebc6'

    $ExpectedCommit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $ExpectedTagObject = 'cdef0c49eb37d0cc72444c0829c253e09eee050a'

    $Assets = @(
        [pscustomobject]@{
            Name = 'MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip'
            Bytes = 39382961
            Sha256 = 'b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746'
        },
        [pscustomobject]@{
            Name = 'MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip'
            Bytes = 31056035
            Sha256 = '1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a'
        },
        [pscustomobject]@{
            Name = 'MSBF_Visual_Publication_Candidate_R1_20260909.zip'
            Bytes = 125229642
            Sha256 = 'c2122d0c47cd1bd604dd372bb4aa662a61be86af0578c23ed768629cccd855b5'
        },
        [pscustomobject]@{
            Name = 'MSBF_Cohort_R3_Editorial_Patch_R1_20260908.zip'
            Bytes = 9613925
            Sha256 = 'aadcb403b662fc5e53280fd92357e53db4f4c9bcad6b1111ba286d61f9f2bcc3'
        }
    )

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE J — RECEIPT RECOVERY / REVERIFICATION"
    Write-Host "============================================================"
    Write-Host "Downloads: $DownloadDir"
    Write-Host "Evidence:  $EvidenceDir"
    Write-Host ""

    if (-not (Test-Path -LiteralPath $DownloadDir -PathType Container)) {
        throw "Hosted download directory is missing."
    }

    if (-not (Test-Path -LiteralPath $EvidenceDir -PathType Container)) {
        throw "Phase J evidence directory is missing."
    }

    # ---------------------------------------------------------
    # 1. Fresh public GitHub release metadata
    # ---------------------------------------------------------

    $ApiUri = "https://api.github.com/repos/$RepoSlug/releases/tags/$Tag"

    $Headers = @{
        'User-Agent' = 'MSBF-release-verification'
        'Accept' = 'application/vnd.github+json'
    }

    $Release = Invoke-RestMethod `
        -Uri $ApiUri `
        -Headers $Headers `
        -Method Get

    if ($Release.tag_name -cne $Tag) {
        throw "STOP: hosted release tag differs from expected."
    }

    if ($Release.draft -eq $true) {
        throw "STOP: hosted release is unexpectedly a draft."
    }

    if ($Release.prerelease -eq $true) {
        throw "STOP: hosted release is unexpectedly a prerelease."
    }

    $HostedAssets = @($Release.assets)

    if ($HostedAssets.Count -ne 4) {
        throw "STOP: GitHub API reports $($HostedAssets.Count) uploaded assets; expected 4."
    }

    # ---------------------------------------------------------
    # 2. Fresh remote tag binding
    # ---------------------------------------------------------

    $Repo = 'D:\x\m'

    $RemoteTag = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$Tag" `
            "refs/tags/$Tag^{}"
    )

    $ObjectLine = @(
        $RemoteTag |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($Tag))$" }
    )

    $CommitLine = @(
        $RemoteTag |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($Tag))\^\{\}$" }
    )

    if ($ObjectLine.Count -ne 1 -or $CommitLine.Count -ne 1) {
        throw "STOP: remote tag could not be resolved exactly."
    }

    $RemoteTagObject = (
        ($ObjectLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $RemoteTagCommit = (
        ($CommitLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if ($RemoteTagObject -ne $ExpectedTagObject) {
        throw "STOP: hosted tag object mismatch."
    }

    if ($RemoteTagCommit -ne $ExpectedCommit) {
        throw "STOP: hosted tag commit mismatch."
    }

    # ---------------------------------------------------------
    # 3. Reverify the EXISTING hosted downloads
    # ---------------------------------------------------------

    $Rows = @()

    foreach ($Expected in $Assets) {

        $Path = Join-Path $DownloadDir $Expected.Name

        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "STOP: hosted download missing: $($Expected.Name)"
        }

        $Item = Get-Item -LiteralPath $Path
        $Hash = (
            Get-FileHash -LiteralPath $Path -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        $Hosted = @(
            $HostedAssets |
            Where-Object { $_.name -ceq $Expected.Name }
        )

        if ($Hosted.Count -ne 1) {
            throw "STOP: GitHub metadata did not resolve exactly one asset for $($Expected.Name)"
        }

        $Pass = (
            $Item.Name -ceq $Expected.Name -and
            $Item.Length -eq $Expected.Bytes -and
            $Hash -ceq $Expected.Sha256
        )

        $Rows += [pscustomobject]@{
            Name = $Item.Name
            DownloadedPath = $Item.FullName

            GitHubAssetId = $Hosted[0].id
            GitHubApiBytes = $Hosted[0].size

            ExpectedBytes = $Expected.Bytes
            DownloadedBytes = $Item.Length

            ExpectedSha256 = $Expected.Sha256
            DownloadedSha256 = $Hash

            Status = if ($Pass) { 'PASS' } else { 'FAIL' }
        }

        if (-not $Pass) {
            throw "STOP RELEASE CLOSURE: hosted asset mismatch: $($Expected.Name)"
        }
    }

    $PhysicalZips = @(
        Get-ChildItem -LiteralPath $DownloadDir -File -Filter '*.zip'
    )

    if ($PhysicalZips.Count -ne 4) {
        throw "STOP: hosted download directory contains $($PhysicalZips.Count) ZIPs; expected 4."
    }

    # ---------------------------------------------------------
    # 4. Write evidence using ordinary PSCustomObject
    # ---------------------------------------------------------

    $CsvPath = Join-Path $EvidenceDir `
        'HOSTED_ASSET_VERIFICATION_RECOVERED.csv'

    $Rows |
        Export-Csv `
            -LiteralPath $CsvPath `
            -NoTypeInformation `
            -Encoding UTF8

    $Receipt = [pscustomobject]@{
        SchemaVersion = '1.1'
        Task = 'MSBF_PHASE_J_HOSTED_ASSET_IDENTITY_VERIFICATION_RECOVERED'

        Repository = $RepoSlug
        Tag = $Tag

        ReleaseUrl = [string]$Release.html_url
        ReleaseName = [string]$Release.name
        PublishedAt = [string]$Release.published_at

        PublicationCommit = $ExpectedCommit
        RemoteTagObject = $RemoteTagObject
        RemoteTagPeeledCommit = $RemoteTagCommit

        HostedDownloadDirectory = $DownloadDir
        EvidenceDirectory = $EvidenceDir

        GitHubUploadedAssetCount = [int]$HostedAssets.Count
        PhysicalHostedZipCount = [int]$PhysicalZips.Count
        VerifiedHostedAssetCount = [int]$Rows.Count

        AllHostedAssetsPass = (
            @($Rows | Where-Object { $_.Status -ne 'PASS' }).Count -eq 0
        )

        AssetResults = $Rows

        OriginalDownloadSucceeded = $true
        RedownloadPerformedByRecovery = $false

        WindowsNativeHostedExtractionPerformed = $false
        AnonymousNavigationVerificationPerformed = $false

        HostedAssetVerification = 'PASS'
        ReleaseClosure = 'PENDING_WINDOWS_EXTRACTION_AND_PUBLIC_NAVIGATION'
    }

    $ReceiptPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION_RECOVERED.json'

    $Receipt |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -LiteralPath $ReceiptPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "HOSTED_ASSET_VERIFICATION = PASS"
    Write-Host "============================================================"
    Write-Host "Release: $($Release.html_url)"
    Write-Host "Published: $($Release.published_at)"
    Write-Host ""
    Write-Host "GitHub uploaded assets: $($HostedAssets.Count)"
    Write-Host "Hosted ZIPs on disk:    $($PhysicalZips.Count)"
    Write-Host "Verified:               $($Rows.Count)"
    Write-Host ""

    $Rows |
        Select-Object Name,DownloadedBytes,DownloadedSha256,Status |
        Format-Table -AutoSize |
        Out-Host

    Write-Host ""
    Write-Host "Redownload performed:          NO"
    Write-Host "Windows-native extraction:     NOT YET PERFORMED"
    Write-Host "Anonymous navigation:          NOT YET PERFORMED"
    Write-Host ""
    Write-Host "PHASE_J = PASS"
    Write-Host "RELEASE_CLOSURE = PENDING"
    Write-Host ""
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "STOP HERE."
}
```

Expected result:

```text
HOSTED_ASSET_VERIFICATION = PASS

GitHub uploaded assets: 4
Hosted ZIPs on disk:    4
Verified:               4

Redownload performed:   NO

PHASE_J = PASS
RELEASE_CLOSURE = PENDING
```

Once this prints `PHASE_J = PASS`, send me that output. Then we can move directly to **Phase K: Windows-native extraction of these exact hosted copies**.

And importantly, **do not delete the original failed Phase J evidence**. We retain it as:

```text
PHASE_J_ATTEMPT_1
Hosted downloads and identity verification: PASS
Receipt construction: FAILED_WRAPPER_OBJECT_SERIALIZATION

PHASE_J_RECOVERY
Expected result: PASS
Redownload: NONE
```

That preserves the actual chronology instead of pretending the wrapper failure never happened.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d770b35c-955f-46fd-b158-e20ea31fdc2f"></a>
## Andrew / user · C123-M00095

C123-M00095 · 2026-09-10T10:06:38.914000-04:00 · active path

Preceding visible parent: [C123-M00094](part-10.md#m-70863ea5-1fac-4ace-bde7-8180cc9e9027)

**Editorial record note:** Attachment references: GITHUB_RELEASE_METADATA.json; HOSTED_ASSET_VERIFICATION.csv; HOSTED_ASSET_VERIFICATION_RECOVERED.csv; MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION_RECOVERED.json

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE J — RECEIPT RECOVERY / REVERIFICATION
============================================================
Downloads: D:\MSBF_HOSTED_VERIFY_v2_1_0_20260910T140346449Z_a425ebc6
Evidence:  D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_J_20260910T140346449Z_a425ebc6


============================================================
HOSTED_ASSET_VERIFICATION = PASS
============================================================
Release: https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/module-2-g3-v2.1.0
Published: 09/10/2026 13:59:29

GitHub uploaded assets: 4
Hosted ZIPs on disk:    4
Verified:               4


Name                                                         DownloadedBytes DownloadedSha256                                                 Status
----                                                         --------------- ----------------                                                 ------
MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip              39382961 b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746 PASS
MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip        31056035 1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a PASS
MSBF_Visual_Publication_Candidate_R1_20260909.zip                  125229642 c2122d0c47cd1bd604dd372bb4aa662a61be86af0578c23ed768629cccd855b5 PASS
MSBF_Cohort_R3_Editorial_Patch_R1_20260908.zip                       9613925 aadcb403b662fc5e53280fd92357e53db4f4c9bcad6b1111ba286d61f9f2bcc3 PASS


Redownload performed:          NO
Windows-native extraction:     NOT YET PERFORMED
Anonymous navigation:          NOT YET PERFORMED

PHASE_J = PASS
RELEASE_CLOSURE = PENDING

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_J_20260910T140346449Z_a425ebc6\MSBF_PHASE_J_HOSTED_ASSET_VERIFICATION_RECOVERED.json
============================================================

STOP HERE.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0f057e81-967f-45fb-935c-07cf2d3010be"></a>
## Assistant · C123-M00096

C123-M00096 · 2026-09-10T10:06:43.977353-04:00 · active path

Preceding visible parent: [C123-M00095](part-10.md#m-d770b35c-955f-46fd-b158-e20ea31fdc2f)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase J is now fully closed as PASS.** The recovered receipt confirms the actual GitHub-hosted copies—not the local originals—were verified 4/4 against the locked identities, with no redownload during recovery. [export reference: filecite | turn34file1 | L12-L17] Each hosted asset reproduces its expected byte size and SHA-256 exactly. [export reference: filecite | turn34file1 | L20-L28] [export reference: filecite | turn34file1 | L31-L39] [export reference: filecite | turn34file1 | L42-L50] [export reference: filecite | turn34file1 | L53-L61]

The live GitHub release metadata independently reports the same four uploaded assets, including GitHub's own SHA-256 digests, and records the release as published—not draft or prerelease—at `2026-09-10T13:59:29Z`. [export reference: filecite | turn34file0 | L29-L37] [export reference: filecite | turn34file0 | L66-L73] [export reference: filecite | turn34file0 | L102-L109] [export reference: filecite | turn34file0 | L138-L145] [export reference: filecite | turn34file0 | L174-L181]

We can therefore record:

```text
PHASE_J_HOSTED_ASSET_VERIFICATION = PASS
HOSTED_ASSETS = 4 / 4 EXACT
REDOWNLOAD_DURING_RECOVERY = NO

WINDOWS_NATIVE_HOSTED_EXTRACTION = NOT YET PERFORMED
ANONYMOUS_PUBLIC_NAVIGATION = NOT YET PERFORMED

RELEASE_CLOSURE = PENDING
```

## Phase K — Windows-native clean extraction of the hosted copies

For this gate, use the **already verified hosted files** in:

```text
D:\MSBF_HOSTED_VERIFY_v2_1_0_20260910T140346449Z_a425ebc6
```

We will use Windows PowerShell's built-in `Expand-Archive` into **fresh, short-path directories**, while also checking that Windows Explorer's ZIP shell can open each hosted carrier. That gives us both a native extraction result and an Explorer-compatibility signal without substituting Python/Linux extraction.

Run this entire block in the same PowerShell:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $HostedDir = 'D:\MSBF_HOSTED_VERIFY_v2_1_0_20260910T140346449Z_a425ebc6'

    $Assets = @(
        [pscustomobject]@{
            Id = 'R26'
            Name = 'MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip'
            Bytes = 39382961
            Sha256 = 'b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746'
        },
        [pscustomobject]@{
            Id = 'PBI'
            Name = 'MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip'
            Bytes = 31056035
            Sha256 = '1fe42707eabfb53512729581ded0dc2d1addf7ca4f6e4d4de594f3f3ea37551a'
        },
        [pscustomobject]@{
            Id = 'VIS'
            Name = 'MSBF_Visual_Publication_Candidate_R1_20260909.zip'
            Bytes = 125229642
            Sha256 = 'c2122d0c47cd1bd604dd372bb4aa662a61be86af0578c23ed768629cccd855b5'
        },
        [pscustomobject]@{
            Id = 'COH'
            Name = 'MSBF_Cohort_R3_Editorial_Patch_R1_20260908.zip'
            Bytes = 9613925
            Sha256 = 'aadcb403b662fc5e53280fd92357e53db4f4c9bcad6b1111ba286d61f9f2bcc3'
        }
    )

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)

    $ExtractRoot = "D:\MX_${Stamp}_${Suffix}"
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_K_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $ExtractRoot | Out-Null
    New-Item -ItemType Directory -Path $EvidenceDir | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE K — WINDOWS-NATIVE HOSTED EXTRACTION"
    Write-Host "============================================================"
    Write-Host "Hosted source: $HostedDir"
    Write-Host "Extract root:  $ExtractRoot"
    Write-Host "Evidence:      $EvidenceDir"
    Write-Host ""

    # Windows Explorer shell namespace check.
    $Shell = New-Object -ComObject Shell.Application

    $Rows = @()

    foreach ($a in $Assets) {

        $ZipPath = Join-Path $HostedDir $a.Name
        $Dest = Join-Path $ExtractRoot $a.Id

        Write-Host ""
        Write-Host "------------------------------------------------------------"
        Write-Host "Checking $($a.Id): $($a.Name)"
        Write-Host "------------------------------------------------------------"

        if (-not (Test-Path -LiteralPath $ZipPath -PathType Leaf)) {
            throw "STOP: hosted ZIP missing: $ZipPath"
        }

        # --------------------------------------------------------
        # 1. Reconfirm hosted identity immediately before extraction
        # --------------------------------------------------------

        $Item = Get-Item -LiteralPath $ZipPath
        $HashBefore = (
            Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        if ($Item.Length -ne $a.Bytes) {
            throw "STOP: hosted ZIP size changed: $($a.Name)"
        }

        if ($HashBefore -ne $a.Sha256) {
            throw "STOP: hosted ZIP SHA-256 changed: $($a.Name)"
        }

        # --------------------------------------------------------
        # 2. Explorer ZIP-shell compatibility
        # --------------------------------------------------------

        $ZipNamespace = $Shell.NameSpace($ZipPath)

        $ExplorerOpenPass = ($null -ne $ZipNamespace)

        if (-not $ExplorerOpenPass) {
            throw "STOP: Windows Explorer shell cannot open ZIP: $($a.Name)"
        }

        $ExplorerTopLevelItems = $ZipNamespace.Items().Count

        # --------------------------------------------------------
        # 3. Fresh native PowerShell extraction
        # --------------------------------------------------------

        if (Test-Path -LiteralPath $Dest) {
            throw "STOP: extraction destination already exists: $Dest"
        }

        New-Item -ItemType Directory -Path $Dest | Out-Null

        $Start = Get-Date

        try {
            Expand-Archive `
                -LiteralPath $ZipPath `
                -DestinationPath $Dest `
                -ErrorAction Stop
        }
        catch {
            throw "STOP RELEASE CLOSURE: Windows-native extraction failed for $($a.Name): $($_.Exception.Message)"
        }

        $Elapsed = (Get-Date) - $Start

        # --------------------------------------------------------
        # 4. Extracted-tree readability
        # --------------------------------------------------------

        $ExtractedFiles = @(
            Get-ChildItem -LiteralPath $Dest -Recurse -File -Force
        )

        if ($ExtractedFiles.Count -eq 0) {
            throw "STOP: extraction produced no files: $($a.Name)"
        }

        # Read every extracted file to ensure Windows can open/read it.
        $ReadFailures = 0
        $TotalReadBytes = [int64]0

        foreach ($f in $ExtractedFiles) {
            try {
                $stream = [System.IO.File]::Open(
                    $f.FullName,
                    [System.IO.FileMode]::Open,
                    [System.IO.FileAccess]::Read,
                    [System.IO.FileShare]::Read
                )

                try {
                    $buffer = New-Object byte[] 1048576

                    while (($n = $stream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $TotalReadBytes += $n
                    }
                }
                finally {
                    $stream.Dispose()
                }
            }
            catch {
                $ReadFailures++
            }
        }

        if ($ReadFailures -ne 0) {
            throw "STOP: $ReadFailures extracted files could not be read for $($a.Name)"
        }

        # --------------------------------------------------------
        # 5. Path-length evidence
        # --------------------------------------------------------

        $PathRows = @(
            $ExtractedFiles |
            ForEach-Object {
                [pscustomobject]@{
                    FullPath = $_.FullName
                    Length = $_.FullName.Length
                }
            } |
            Sort-Object Length -Descending
        )

        $LongestPath = $PathRows | Select-Object -First 1

        $PathRows |
            Select-Object -First 20 |
            Export-Csv `
                -LiteralPath (
                    Join-Path $EvidenceDir "$($a.Id)_LONGEST_EXTRACTED_PATHS.csv"
                ) `
                -NoTypeInformation `
                -Encoding UTF8

        # --------------------------------------------------------
        # 6. Reconfirm hosted carrier nonmutation
        # --------------------------------------------------------

        $HashAfter = (
            Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        if ($HashAfter -ne $HashBefore) {
            throw "STOP: hosted ZIP changed during extraction: $($a.Name)"
        }

        $Rows += [pscustomobject]@{
            Id = $a.Id
            Name = $a.Name

            HostedPath = $ZipPath
            HostedBytes = $Item.Length
            HostedSha256Before = $HashBefore
            HostedSha256After = $HashAfter

            ExplorerShellOpenedZip = $ExplorerOpenPass
            ExplorerTopLevelItemCount = $ExplorerTopLevelItems

            ExtractionMethod = 'Windows PowerShell Expand-Archive'
            ExtractDestination = $Dest

            ExtractedFileCount = $ExtractedFiles.Count
            ExtractedReadFailureCount = $ReadFailures
            ExtractedBytesRead = $TotalReadBytes

            LongestExtractedPath = $LongestPath.FullPath
            LongestExtractedPathLength = $LongestPath.Length

            ExtractionSeconds = [math]::Round($Elapsed.TotalSeconds,2)

            Status = 'PASS'
        }

        Write-Host "Explorer ZIP shell: PASS"
        Write-Host "Extracted files:    $($ExtractedFiles.Count)"
        Write-Host "Read failures:      $ReadFailures"
        Write-Host "Longest path:       $($LongestPath.Length) chars"
        Write-Host "Elapsed:            $([math]::Round($Elapsed.TotalSeconds,2)) sec"
        Write-Host "PASS"
    }

    # ------------------------------------------------------------
    # 7. Final evidence
    # ------------------------------------------------------------

    $Rows |
        Export-Csv `
            -LiteralPath (
                Join-Path $EvidenceDir 'WINDOWS_HOSTED_EXTRACTION_RESULTS.csv'
            ) `
            -NoTypeInformation `
            -Encoding UTF8

    $Receipt = [pscustomobject]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_PHASE_K_WINDOWS_NATIVE_HOSTED_EXTRACTION'

        HostedSourceDirectory = $HostedDir
        ExtractionRoot = $ExtractRoot
        EvidenceDirectory = $EvidenceDir

        HostedAssetCount = $Rows.Count
        ExplorerShellOpenPassCount = @(
            $Rows | Where-Object ExplorerShellOpenedZip
        ).Count

        WindowsNativeExtractionPassCount = @(
            $Rows | Where-Object Status -eq 'PASS'
        ).Count

        ExtractedReadFailureTotal = (
            ($Rows | Measure-Object ExtractedReadFailureCount -Sum).Sum
        )

        Results = $Rows

        HostedHashesPreviouslyVerified = $true
        WindowsNativeHostedExtractionPerformed = $true
        AnonymousNavigationVerificationPerformed = $false

        WindowsHostedExtraction = if (
            @($Rows | Where-Object Status -ne 'PASS').Count -eq 0
        ) {
            'PASS'
        } else {
            'FAIL'
        }

        ReleaseClosure = 'PENDING_ANONYMOUS_PUBLIC_NAVIGATION'
    }

    $ReceiptPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_K_WINDOWS_HOSTED_EXTRACTION.json'

    $Receipt |
        ConvertTo-Json -Depth 10 |
        Set-Content `
            -LiteralPath $ReceiptPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "WINDOWS_HOSTED_EXTRACTION = PASS"
    Write-Host "============================================================"

    $Rows |
        Select-Object `
            Id,
            ExtractedFileCount,
            ExplorerShellOpenedZip,
            ExtractedReadFailureCount,
            LongestExtractedPathLength,
            Status |
        Format-Table -AutoSize |
        Out-Host

    Write-Host ""
    Write-Host "Hosted copies tested:      4"
    Write-Host "Explorer ZIP-shell opens:  4 / 4"
    Write-Host "Native extraction passes:  4 / 4"
    Write-Host "Extracted read failures:   0"
    Write-Host ""
    Write-Host "Anonymous navigation:      NOT YET PERFORMED"
    Write-Host "RELEASE CLOSURE = PENDING"
    Write-Host ""
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "STOP HERE."
    Write-Host "Do not delete the hosted downloads or extracted trees yet."
}
```

### What this establishes

A PASS here means all four **actual hosted ZIPs**:

- still match their locked SHA-256 immediately before and after extraction;
- are recognized by the Windows Explorer ZIP shell;
- extract successfully through Windows PowerShell's native archive command;
- produce readable extracted file trees;
- do not encounter the historical Windows path/extraction problem that motivated this release gate.

This is deliberately stronger than the earlier Linux/Python extraction evidence, but it still does **not** claim that you manually dragged every ZIP through Explorer's GUI. The receipt will state the actual mechanisms used.

If you get:

```text
WINDOWS_HOSTED_EXTRACTION = PASS
Explorer ZIP-shell opens: 4 / 4
Native extraction passes: 4 / 4
Extracted read failures:  0
```

send me the output and receipt.

Then only **Phase L — anonymous/public navigation verification** remains before we can prepare the genuine release-closure record.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1d8315bb-2243-42a9-9aef-e95c2addb3ac"></a>
## Andrew / user · C123-M00097

C123-M00097 · 2026-09-10T10:09:43.592000-04:00 · active path

Preceding visible parent: [C123-M00096](part-10.md#m-0f057e81-967f-45fb-935c-07cf2d3010be)

**Editorial record note:** Attachment references: MSBF_PHASE_K_WINDOWS_HOSTED_EXTRACTION.json; PBI_LONGEST_EXTRACTED_PATHS.csv; R26_LONGEST_EXTRACTED_PATHS.csv; VIS_LONGEST_EXTRACTED_PATHS.csv; WINDOWS_HOSTED_EXTRACTION_RESULTS.csv; COH_LONGEST_EXTRACTED_PATHS.csv

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE K — WINDOWS-NATIVE HOSTED EXTRACTION
============================================================
Hosted source: D:\MSBF_HOSTED_VERIFY_v2_1_0_20260910T140346449Z_a425ebc6
Extract root:  D:\MX_20260910T140834154Z_c43ee4c6
Evidence:      D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_K_20260910T140834154Z_c43ee4c6


------------------------------------------------------------
Checking R26: MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip
------------------------------------------------------------
Explorer ZIP shell: PASS
Extracted files:    84
Read failures:      0
Longest path:       122 chars
Elapsed:            1.21 sec
PASS

------------------------------------------------------------
Checking PBI: MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip
------------------------------------------------------------
Explorer ZIP shell: PASS
Extracted files:    53
Read failures:      0
Longest path:       115 chars
Elapsed:            0.41 sec
PASS

------------------------------------------------------------
Checking VIS: MSBF_Visual_Publication_Candidate_R1_20260909.zip
------------------------------------------------------------
Explorer ZIP shell: PASS
Extracted files:    83
Read failures:      0
Longest path:       166 chars
Elapsed:            1.05 sec
PASS

------------------------------------------------------------
Checking COH: MSBF_Cohort_R3_Editorial_Patch_R1_20260908.zip
------------------------------------------------------------
Explorer ZIP shell: PASS
Extracted files:    18
Read failures:      0
Longest path:       180 chars
Elapsed:            0.22 sec
PASS

============================================================
WINDOWS_HOSTED_EXTRACTION = PASS
============================================================

Id  ExtractedFileCount ExplorerShellOpenedZip ExtractedReadFailureCount LongestExtractedPathLength Status
--  ------------------ ---------------------- ------------------------- -------------------------- ------
R26                 84                   True                         0                        122 PASS
PBI                 53                   True                         0                        115 PASS
VIS                 83                   True                         0                        166 PASS
COH                 18                   True                         0                        180 PASS


Hosted copies tested:      4
Explorer ZIP-shell opens:  4 / 4
Native extraction passes:  4 / 4
Extracted read failures:   0

Anonymous navigation:      NOT YET PERFORMED
RELEASE CLOSURE = PENDING

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_K_20260910T140834154Z_c43ee4c6\MSBF_PHASE_K_WINDOWS_HOSTED_EXTRACTION.json
============================================================

STOP HERE.
Do not delete the hosted downloads or extracted trees yet.
<!-- END_SOURCE_MESSAGE -->


<a id="m-aac2647d-8cac-4252-a86b-05a486301fae"></a>
## Assistant · C123-M00098

C123-M00098 · 2026-09-10T10:10:26.294502-04:00 · active path

Preceding visible parent: [C123-M00097](part-10.md#m-1d8315bb-2243-42a9-9aef-e95c2addb3ac)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase K is closed with an exact PASS.** The receipt confirms all four actual GitHub-hosted ZIPs were opened by the Windows Explorer ZIP shell, extracted with Windows PowerShell `Expand-Archive`, and every extracted file was readable. There were **0 read failures** across 84 R26 files, 53 Power BI files, 83 visual files, and 18 cohort files. The longest observed extracted path was 180 characters, and every carrier’s SHA-256 was unchanged before versus after extraction. [export reference: filecite | turn35file0 | L7-L10] [export reference: filecite | turn35file0 | L13-L29] [export reference: filecite | turn35file0 | L32-L48] [export reference: filecite | turn35file0 | L51-L67] [export reference: filecite | turn35file0 | L70-L86]

We can now record:

```text
PHASE_K_WINDOWS_HOSTED_EXTRACTION = PASS

Hosted copies tested             4 / 4
Explorer ZIP-shell open          4 / 4
Windows Expand-Archive           4 / 4
Extracted-file read failures     0

R26 extracted files              84
Power BI extracted files         53
Visual extracted files           83
Cohort extracted files           18

Longest observed path            180 characters

RELEASE_CLOSURE                  PENDING PHASE L ONLY
```

I also performed an independent anonymous public check from here. The repository is publicly readable without relying on your authenticated session, `main` exposes the new documentation/publication tree, and the rendered root README is available with its executive, architecture, Module 1, Module 2, evidence, and release-navigation content. [export reference: cite | turn911206view0] The historical `module-2-g3-v2.0.0` release remains publicly accessible as a separate historical release rather than having been rewritten. [export reference: cite | turn252078view1] The executive strategy PDF and Module 1 lineage asset also resolve publicly from the current repository. [export reference: cite | turn252078view0 | turn252078view2]

We still need your **actual browser-level visual/navigation confirmation** because some GitHub rendering behaviors—particularly image rendering and click-through UX—cannot be replaced by HTTP existence checks alone.

## Phase L — anonymous/public navigation closure

Open an **InPrivate/Incognito browser window** where you are **not signed into GitHub**.

Start here:

[export reference: url | Open the public MSBF repository | https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator]

Then perform this compact visual check:

1. On the **repository front door**, confirm:
   - root README renders normally;
   - primary visual(s) render rather than broken-image placeholders;
   - enterprise architecture is visible/opens;
   - Module 1 lineage opens;
   - Module 2 lineage opens;
   - no login is required to read the repository.

2. From the README, confirm these reading routes open:
   - Executive strategy brief
   - Documentation Portal
   - Current Use Guide
   - P03 / explainability route
   - Learning route / proof posters
   - Visual portfolio
   - Requirements / validation guide
   - Source/version guide
   - Cohort route
   - Power BI route

3. On the **P03 explainability route**, confirm at least one genuine Application Journey screenshot renders. The README/doc route should not lead to a broken or missing image.

4. On the **learning/visual route**, confirm both accepted posters can be opened:
   - `How the Governed Decision Engine Works`
   - `What Happens After the Decision`

5. Open the current release:

[export reference: url | Open Module 2 / G3 v2.1.0 release | https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/module-2-g3-v2.1.0]

Confirm:
   - title is **Module 2 / G3 v2.1.0 — Integrated Successor**;
   - tag is `module-2-g3-v2.1.0`;
   - four custom ZIP assets are visible;
   - the only other assets are GitHub's generated source-code ZIP/TAR;
   - no private evidence/control ZIP is exposed.

6. Finally open the historical v2.0.0 release and confirm it still exists separately and has not been replaced by v2.1.0.

You **do not need to redownload anything**—Phase J and K already closed those gates.

When finished, send me a compact response in this form:

```text
ANONYMOUS_PUBLIC_NAVIGATION

Repository accessible anonymously: PASS
Root README renders: PASS
Core visuals render: PASS
Documentation Portal: PASS
Current Use Guide: PASS
P03 explainability / screenshot: PASS
Learning / both posters: PASS
Visual portfolio: PASS
Requirements / validation: PASS
Source/version guide: PASS
Cohort route: PASS
Power BI route: PASS
v2.1.0 release page: PASS
Exactly four custom release ZIPs: PASS
No private assets visible: PASS
Historical v2.0.0 release remains accessible: PASS

Observations: NONE
```

If anything is broken, give me the **exact link or item**, not a generalized fail. We will stop on that one boundary.

If all of those pass, there is **no further publication gate**. I will then prepare the genuine **Phase M release-closure record/package**, binding the final commit, both tag identities, published release, four hosted hashes, Windows extraction results, anonymous-navigation results, R20 authority, and the bounded Campaign Scale / Module 3 successor handoff.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1ade9040-7394-4c7a-bf09-140a7266959c"></a>
## Andrew / user · C123-M00099

C123-M00099 · 2026-09-10T10:17:21.429000-04:00 · active path

Preceding visible parent: [C123-M00098](part-10.md#m-aac2647d-8cac-4252-a86b-05a486301fae)

**Editorial record note:** Attachment references: repository_front_page.pdf

<!-- BEGIN_SOURCE_MESSAGE -->
I already provided print out of the current release. I confirmed again that it opens. Here is a print of the front page. All images render and links are operational.
<!-- END_SOURCE_MESSAGE -->
