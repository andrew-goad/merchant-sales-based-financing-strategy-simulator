# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 18 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-17.md)
[Next part](part-19.md)

<a id="m-5cbe0373-4b80-4674-a11a-ab675f86e358"></a>
## Assistant · C123-M00196

C123-M00196 · 2026-09-11T19:42:21.382584-04:00 · active path

Preceding visible parent: [C123-M00195](part-17.md#m-bdb4f004-a5c0-409b-911d-7469b47d85d1)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. We now know the historical artifacts and their locations, so this preflight does **no historical searching at all**. It inspects only the **current MSBF repository, current toolchain/PostgreSQL installation, current listeners/services, and D: capacity**.

Use a normal PowerShell window. It performs **no PostgreSQL connection, no SQL execution, no Git mutation, no service changes, and no repository writes**. Its only writes are to a new evidence directory on `D:`.

```powershell
# =====================================================================================
# MSBF CAMPAIGN SCALE
# CURRENT-STATE-ONLY PREFLIGHT
#
# PURPOSE
#   Establish the current machine/repository state needed to construct the rebased
#   Campaign Scale harness for:
#
#       750 accepted-reference deterministic replay
#              -> zero semantic differences gate
#       fresh 2,500-merchant end-to-end shakedown
#
# SCOPE
#   CURRENT STATE ONLY.
#
#   This script DOES NOT:
#     - search historical Campaign Scale folders
#     - search Documents / Downloads / Desktop
#     - search for R26 golden/runtime/checkpoint artifacts
#     - connect to PostgreSQL
#     - execute SQL
#     - create/drop/restore a database
#     - start/stop PostgreSQL
#     - fetch/pull/checkout/reset Git
#     - modify D:\x\m
#
# WRITES
#   Evidence only, under:
#       D:\MSBF_CAMPAIGN_CURRENT_STATE_<timestamp>
#
# =====================================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$env:GIT_OPTIONAL_LOCKS = "0"

# -------------------------------------------------------------------------------------
# GOVERNING CURRENT SOURCE
# -------------------------------------------------------------------------------------

$Repo = "D:\x\m"

$ExpectedTag       = "module-2-g3-v2.1.0"
$ExpectedCommit    = "fd9f67b6d1d7fc848d315bcb696487b82c9a8046"
$ExpectedTree      = "fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb"
$ExpectedTagObject = "cdef0c49eb37d0cc72444c0829c253e09eee050a"

if (-not (Test-Path -LiteralPath $Repo -PathType Container)) {
    throw "STOP: repository does not exist: $Repo"
}

# -------------------------------------------------------------------------------------
# OUTPUT — D DRIVE ONLY
# -------------------------------------------------------------------------------------

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Out   = "D:\MSBF_CAMPAIGN_CURRENT_STATE_$Stamp"
$Zip   = "$Out.zip"

New-Item -ItemType Directory -Path $Out -Force | Out-Null

$ErrorLog = Join-Path $Out "ERRORS.txt"

function Log-Error {
    param([string]$Message)

    Add-Content -LiteralPath $ErrorLog `
        -Value ("[{0}] {1}" -f (Get-Date -Format o), $Message)
}

function Hash-File {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return "<NOT_FOUND>"
    }

    try {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    catch {
        Log-Error "Hash failure: $Path :: $($_.Exception.Message)"
        return "<HASH_ERROR>"
    }
}

function Git-Value {
    param([string[]]$Args)

    try {
        $Value = & git -C $Repo @Args 2>&1

        if ($LASTEXITCODE -ne 0) {
            Log-Error "git $($Args -join ' ') :: $($Value -join ' ')"
            return "<ERROR>"
        }

        return (($Value | Out-String).Trim())
    }
    catch {
        Log-Error "git $($Args -join ' ') :: $($_.Exception.Message)"
        return "<ERROR>"
    }
}

# =====================================================================================
# 00 — COLLECTION / MACHINE CONTEXT
# =====================================================================================

$Context = [ordered]@{
    collection_started_local = (Get-Date).ToString("o")
    collection_started_utc   = (Get-Date).ToUniversalTime().ToString("o")

    computer_name             = $env:COMPUTERNAME
    powershell_version        = $PSVersionTable.PSVersion.ToString()

    repo_path                 = $Repo
    output_path               = $Out

    campaign_intent           = "750_REFERENCE_REPLAY_THEN_FRESH_2500_SHAKEDOWN"
    database_execution        = "NOT_PERFORMED"
    historical_search         = "NOT_PERFORMED"
}

try {
    $OS  = Get-CimInstance Win32_OperatingSystem
    $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1

    $Context.os_caption          = $OS.Caption
    $Context.os_version          = $OS.Version
    $Context.os_architecture     = $OS.OSArchitecture
    $Context.memory_gb           = [math]::Round($OS.TotalVisibleMemorySize / 1MB, 2)
    $Context.cpu_name            = $CPU.Name
    $Context.logical_processors  = $CPU.NumberOfLogicalProcessors
}
catch {
    Log-Error "Machine context: $($_.Exception.Message)"
}

$Context |
    ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath "$Out\00_RUN_CONTEXT.json" -Encoding UTF8


# =====================================================================================
# 01 — PUBLICATION AUTHORITY BINDING
# =====================================================================================

$Head      = Git-Value @("rev-parse", "HEAD")
$HeadTree  = Git-Value @("rev-parse", "HEAD^{tree}")
$Branch    = Git-Value @("branch", "--show-current")

$TagObject = Git-Value @("rev-parse", "refs/tags/$ExpectedTag")
$TagCommit = Git-Value @("rev-parse", "$ExpectedTag^{}")
$TagTree   = Git-Value @("rev-parse", "$ExpectedTag^{}^{tree}")

$Publication = [ordered]@{
    expected = [ordered]@{
        tag        = $ExpectedTag
        tag_object = $ExpectedTagObject
        commit     = $ExpectedCommit
        tree       = $ExpectedTree
    }

    observed = [ordered]@{
        current_branch  = $Branch
        current_head    = $Head
        current_tree    = $HeadTree
        tag_object      = $TagObject
        tag_commit      = $TagCommit
        tag_tree        = $TagTree
    }

    checks = [ordered]@{
        tag_object_match     = ($TagObject -eq $ExpectedTagObject)
        tag_commit_match     = ($TagCommit -eq $ExpectedCommit)
        tag_tree_match       = ($TagTree -eq $ExpectedTree)

        head_at_publication  = ($Head -eq $ExpectedCommit)
        head_tree_at_release = ($HeadTree -eq $ExpectedTree)
    }
}

$Publication |
    ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath "$Out\01_PUBLICATION_BINDING.json" -Encoding UTF8


# =====================================================================================
# 02 — CURRENT GIT / WORKING-TREE STATE
# =====================================================================================

$GitState = "$Out\02_GIT_STATE.txt"

@"
================================================================================
MSBF CURRENT GIT STATE
================================================================================

Repository:
$Repo

Collection:
$(Get-Date -Format o)

"@ | Set-Content -LiteralPath $GitState -Encoding UTF8

$Sections = @(
    @{
        Name = "CURRENT BRANCH"
        Args = @("branch", "--show-current")
    },
    @{
        Name = "HEAD"
        Args = @("rev-parse", "HEAD")
    },
    @{
        Name = "STATUS PORCELAIN"
        Args = @("status", "--porcelain=v1", "--untracked-files=all")
    },
    @{
        Name = "UNSTAGED DIFF"
        Args = @("diff", "--no-ext-diff", "--name-status")
    },
    @{
        Name = "STAGED DIFF"
        Args = @("diff", "--cached", "--no-ext-diff", "--name-status")
    },
    @{
        Name = "REMOTES"
        Args = @("remote", "-v")
    },
    @{
        Name = "TAGS AT HEAD"
        Args = @("tag", "--points-at", "HEAD")
    },
    @{
        Name = "RECENT COMMITS"
        Args = @("log", "-n", "15", "--decorate", "--oneline")
    },
    @{
        Name = "SUBMODULE STATUS"
        Args = @("submodule", "status")
    }
)

foreach ($S in $Sections) {

    Add-Content -LiteralPath $GitState `
        -Value "`r`n--- $($S.Name) ---"

    try {
        $Value = & git -C $Repo @($S.Args) 2>&1

        Add-Content -LiteralPath $GitState `
            -Value ($Value | Out-String)
    }
    catch {
        Log-Error "Git state section '$($S.Name)': $($_.Exception.Message)"
    }
}


# =====================================================================================
# 03 — PUBLICATION COMMIT -> CURRENT HEAD DIFFERENCE
#
# This is important if development occurred after publication.
# It does NOT change anything.
# =====================================================================================

$DiffPath = "$Out\03_PUBLICATION_TO_HEAD_DIFF.txt"

@"
================================================================================
DIFF: PUBLISHED v2.1.0 COMMIT -> CURRENT HEAD
================================================================================

Published commit:
$ExpectedCommit

Current HEAD:
$Head

"@ | Set-Content -LiteralPath $DiffPath -Encoding UTF8

try {
    & git -C $Repo diff `
        --no-ext-diff `
        --name-status `
        $ExpectedCommit `
        $Head 2>&1 |
        Out-String |
        Add-Content -LiteralPath $DiffPath
}
catch {
    Log-Error "Publication -> HEAD diff: $($_.Exception.Message)"
}


# =====================================================================================
# 04 — ALL CURRENT TRACKED FILES
#
# Metadata only. SHA-256 is calculated separately for executable/control-relevant files.
# =====================================================================================

$TrackedPaths = @()

try {
    $TrackedPaths = @(
        & git -c core.quotepath=false -C $Repo ls-files
    )
}
catch {
    throw "STOP: unable to inventory tracked files."
}

$AllTracked = foreach ($Rel in $TrackedPaths) {

    if ([string]::IsNullOrWhiteSpace($Rel)) {
        continue
    }

    $Full = Join-Path $Repo $Rel

    if (Test-Path -LiteralPath $Full -PathType Leaf) {

        $F = Get-Item -LiteralPath $Full

        [pscustomobject]@{
            relative_path       = $Rel
            extension           = $F.Extension.ToLowerInvariant()
            bytes               = $F.Length
            last_write_time_utc = $F.LastWriteTimeUtc.ToString("o")
            exists              = $true
        }
    }
    else {

        [pscustomobject]@{
            relative_path       = $Rel
            extension           = [IO.Path]::GetExtension($Rel).ToLowerInvariant()
            bytes               = $null
            last_write_time_utc = $null
            exists              = $false
        }
    }
}

$AllTracked |
    Sort-Object relative_path |
    Export-Csv `
        -LiteralPath "$Out\04_ALL_TRACKED_FILES.csv" `
        -NoTypeInformation `
        -Encoding UTF8


# =====================================================================================
# 05 — EXECUTABLE / CONTROL SOURCE SHA-256 INVENTORY
#
# This becomes the current side of the old-230-position -> v2.1.0 mapping.
# =====================================================================================

$ControlExtensions = @(
    ".sql",
    ".ps1",
    ".psm1",
    ".py",
    ".json",
    ".csv",
    ".yaml",
    ".yml",
    ".toml",
    ".cmd",
    ".bat",
    ".txt",
    ".sha256"
)

$ControlRows = foreach ($Rel in $TrackedPaths) {

    if ([string]::IsNullOrWhiteSpace($Rel)) {
        continue
    }

    $Full = Join-Path $Repo $Rel

    if (-not (Test-Path -LiteralPath $Full -PathType Leaf)) {
        continue
    }

    $Ext = [IO.Path]::GetExtension($Full).ToLowerInvariant()

    if ($ControlExtensions -notcontains $Ext) {
        continue
    }

    $F = Get-Item -LiteralPath $Full

    [pscustomobject]@{
        relative_path       = $Rel
        extension           = $Ext
        bytes               = $F.Length
        last_write_time_utc = $F.LastWriteTimeUtc.ToString("o")
        sha256              = Hash-File $Full
    }
}

$ControlRows |
    Sort-Object relative_path |
    Export-Csv `
        -LiteralPath "$Out\05_EXECUTABLE_CONTROL_SOURCE_HASHES.csv" `
        -NoTypeInformation `
        -Encoding UTF8


# =====================================================================================
# 06 — CURRENT SQL INVENTORY
# =====================================================================================

$SqlRows = $ControlRows |
    Where-Object { $_.extension -eq ".sql" } |
    Sort-Object relative_path

$SqlRows |
    Export-Csv `
        -LiteralPath "$Out\06_CURRENT_SQL_SOURCE_INVENTORY.csv" `
        -NoTypeInformation `
        -Encoding UTF8


# =====================================================================================
# 07 — CURRENT TOOLCHAIN
# =====================================================================================

$ToolchainPath = "$Out\07_TOOLCHAIN.txt"

@"
================================================================================
CURRENT TOOLCHAIN
================================================================================

"@ | Set-Content -LiteralPath $ToolchainPath -Encoding UTF8

$Commands = @(
    "git",
    "python",
    "py",
    "psql",
    "pg_config",
    "pg_dump",
    "pg_restore",
    "createdb",
    "dropdb"
)

foreach ($Name in $Commands) {

    Add-Content -LiteralPath $ToolchainPath `
        -Value "`r`n--- $Name ---"

    try {
        $Cmd = Get-Command $Name -ErrorAction SilentlyContinue

        if ($null -eq $Cmd) {

            Add-Content -LiteralPath $ToolchainPath `
                -Value "<NOT FOUND>"

            continue
        }

        Add-Content -LiteralPath $ToolchainPath `
            -Value "PATH: $($Cmd.Source)"

        if ($Name -eq "git") {
            Add-Content -LiteralPath $ToolchainPath `
                -Value ((& $Cmd.Source --version 2>&1) | Out-String)
        }

        elseif ($Name -eq "python") {
            Add-Content -LiteralPath $ToolchainPath `
                -Value ((& $Cmd.Source --version 2>&1) | Out-String)
        }

        elseif ($Name -in @("psql","pg_config","pg_dump","pg_restore")) {
            Add-Content -LiteralPath $ToolchainPath `
                -Value ((& $Cmd.Source --version 2>&1) | Out-String)
        }
    }
    catch {
        Log-Error "Toolchain $Name :: $($_.Exception.Message)"
    }
}


# =====================================================================================
# 08 — POSTGRESQL INSTALLATION / SERVICE STATE
#
# NO DATABASE CONNECTION.
# =====================================================================================

$PgPath = "$Out\08_POSTGRESQL_CURRENT_STATE.txt"

@"
================================================================================
POSTGRESQL CURRENT STATE
NO DATABASE CONNECTION PERFORMED
================================================================================

"@ | Set-Content -LiteralPath $PgPath -Encoding UTF8


# ---- PostgreSQL Windows services -----------------------------------------------------

Add-Content -LiteralPath $PgPath `
    -Value "--- WINDOWS SERVICES ---"

try {

    $PgServices = Get-CimInstance Win32_Service |
        Where-Object {
            $_.Name -match "(?i)postgres" -or
            $_.DisplayName -match "(?i)postgres"
        }

    foreach ($S in $PgServices) {

        Add-Content -LiteralPath $PgPath -Value @"

Name        : $($S.Name)
DisplayName : $($S.DisplayName)
State       : $($S.State)
StartMode   : $($S.StartMode)
ProcessId   : $($S.ProcessId)
PathName    : $($S.PathName)

"@
    }

    if (-not $PgServices) {
        Add-Content -LiteralPath $PgPath `
            -Value "<NO POSTGRESQL WINDOWS SERVICE FOUND>"
    }
}
catch {
    Log-Error "PostgreSQL service inventory: $($_.Exception.Message)"
}


# ---- PostgreSQL processes ------------------------------------------------------------

Add-Content -LiteralPath $PgPath `
    -Value "`r`n--- POSTGRES PROCESSES ---"

try {

    $Processes = Get-Process postgres -ErrorAction SilentlyContinue

    if ($Processes) {

        $Processes |
            Select-Object Id, ProcessName, Path |
            Format-Table -AutoSize |
            Out-String |
            Add-Content -LiteralPath $PgPath
    }
    else {
        Add-Content -LiteralPath $PgPath `
            -Value "<NO postgres PROCESS OBSERVED>"
    }
}
catch {
    Log-Error "PostgreSQL process inventory: $($_.Exception.Message)"
}


# ---- Known PostgreSQL registry installations ----------------------------------------

Add-Content -LiteralPath $PgPath `
    -Value "`r`n--- POSTGRESQL REGISTRY INSTALLATIONS ---"

$RegistryRoots = @(
    "HKLM:\SOFTWARE\PostgreSQL\Installations",
    "HKLM:\SOFTWARE\WOW6432Node\PostgreSQL\Installations"
)

foreach ($Root in $RegistryRoots) {

    if (-not (Test-Path $Root)) {
        continue
    }

    try {

        Get-ChildItem $Root |
            ForEach-Object {

                Get-ItemProperty $_.PSPath |
                    Select-Object `
                        PSChildName,
                        BaseDirectory,
                        Version,
                        DataDirectory
            } |
            Format-List |
            Out-String |
            Add-Content -LiteralPath $PgPath
    }
    catch {
        Log-Error "PostgreSQL registry inventory $Root :: $($_.Exception.Message)"
    }
}


# ---- Listening ports ----------------------------------------------------------------

Add-Content -LiteralPath $PgPath `
    -Value "`r`n--- LISTENERS: 5432 / 55432 ---"

try {

    $Listeners = Get-NetTCPConnection -State Listen -ErrorAction Stop |
        Where-Object {
            $_.LocalPort -in @(5432,55432)
        }

    if ($Listeners) {

        foreach ($L in $Listeners) {

            $ProcessName = ""

            try {
                $ProcessName = (
                    Get-Process -Id $L.OwningProcess -ErrorAction Stop
                ).ProcessName
            }
            catch {}

            Add-Content -LiteralPath $PgPath `
                -Value "$($L.LocalAddress):$($L.LocalPort) | PID=$($L.OwningProcess) | $ProcessName"
        }
    }
    else {
        Add-Content -LiteralPath $PgPath `
            -Value "<NO LISTENER ON 5432 OR 55432>"
    }
}
catch {

    Add-Content -LiteralPath $PgPath `
        -Value "<Get-NetTCPConnection unavailable; netstat fallback>"

    try {

        netstat -ano |
            Select-String ":5432|:55432" |
            Out-String |
            Add-Content -LiteralPath $PgPath
    }
    catch {
        Log-Error "Listener inventory: $($_.Exception.Message)"
    }
}


# =====================================================================================
# 09 — D DRIVE CAPACITY
# =====================================================================================

$DriveRows = @()

try {

    $DDrive = Get-PSDrive -Name D -PSProvider FileSystem

    $DriveRows += [pscustomobject]@{
        drive   = "D:"
        root    = $DDrive.Root
        used_gb = [math]::Round($DDrive.Used / 1GB, 2)
        free_gb = [math]::Round($DDrive.Free / 1GB, 2)
        free_tb = [math]::Round($DDrive.Free / 1TB, 3)
    }
}
catch {
    Log-Error "D drive capacity: $($_.Exception.Message)"
}

try {

    $Volume = Get-Volume -DriveLetter D -ErrorAction Stop

    $DriveRows += [pscustomobject]@{
        drive   = "D: VOLUME"
        root    = $Volume.FileSystemLabel
        used_gb = $null
        free_gb = [math]::Round($Volume.SizeRemaining / 1GB, 2)
        free_tb = [math]::Round($Volume.SizeRemaining / 1TB, 3)
    }

    $Volume |
        Select-Object `
            DriveLetter,
            FileSystemLabel,
            FileSystem,
            HealthStatus,
            OperationalStatus,
            Size,
            SizeRemaining |
        ConvertTo-Json -Depth 4 |
        Set-Content `
            -LiteralPath "$Out\09B_D_VOLUME_DETAILS.json" `
            -Encoding UTF8
}
catch {
    Log-Error "Get-Volume D: $($_.Exception.Message)"
}

$DriveRows |
    Export-Csv `
        -LiteralPath "$Out\09_D_DRIVE_CAPACITY.csv" `
        -NoTypeInformation `
        -Encoding UTF8


# =====================================================================================
# 10 — PREFLIGHT GATE
# =====================================================================================

$WorkingState = @(
    & git -C $Repo status --porcelain=v1 --untracked-files=all 2>$null
)

$PublicationToHead = @(
    & git -C $Repo diff `
        --no-ext-diff `
        --name-only `
        $ExpectedCommit `
        $Head 2>$null
)

$Psql = Get-Command psql -ErrorAction SilentlyContinue
$PgDump = Get-Command pg_dump -ErrorAction SilentlyContinue
$PgRestore = Get-Command pg_restore -ErrorAction SilentlyContinue

$DFreeGB = $null

try {
    $DFreeGB = [math]::Round(
        (Get-PSDrive -Name D -PSProvider FileSystem).Free / 1GB,
        2
    )
}
catch {}

$Gate = [ordered]@{
    status = "CURRENT_STATE_CAPTURE_COMPLETE"

    source_authority = [ordered]@{
        tag_object_match        = ($TagObject -eq $ExpectedTagObject)
        tag_commit_match        = ($TagCommit -eq $ExpectedCommit)
        tag_tree_match          = ($TagTree -eq $ExpectedTree)

        current_head            = $Head
        current_head_tree       = $HeadTree

        head_at_publication     = ($Head -eq $ExpectedCommit)
        head_tree_at_publication= ($HeadTree -eq $ExpectedTree)

        publication_to_head_changed_paths = @($PublicationToHead).Count
        working_tree_entries              = @($WorkingState).Count
        working_tree_clean                = (@($WorkingState).Count -eq 0)
    }

    inventory = [ordered]@{
        tracked_files                  = @($AllTracked).Count
        executable_control_files       = @($ControlRows).Count
        sql_files                      = @($SqlRows).Count
    }

    postgres_toolchain = [ordered]@{
        psql_found       = ($null -ne $Psql)
        pg_dump_found    = ($null -ne $PgDump)
        pg_restore_found = ($null -ne $PgRestore)
    }

    storage = [ordered]@{
        drive       = "D:"
        free_gb     = $DFreeGB
        intended_for_campaign_runtime = $true
    }

    safety = [ordered]@{
        historical_artifact_search = $false
        postgres_connection         = $false
        sql_execution               = $false
        database_mutation           = $false
        git_mutation                = $false
        service_mutation            = $false
        repository_write            = $false
    }

    next_step = "RETURN_ZIP_FOR_230_POSITION_REBASE_AND_HARNESS_CONSTRUCTION"
}

$Gate |
    ConvertTo-Json -Depth 10 |
    Set-Content `
        -LiteralPath "$Out\10_PREFLIGHT_GATE.json" `
        -Encoding UTF8


# =====================================================================================
# 11 — HASH THE EVIDENCE PACKAGE
# =====================================================================================

$EvidenceFiles = Get-ChildItem -LiteralPath $Out -File |
    Sort-Object Name

$EvidenceHashes = foreach ($F in $EvidenceFiles) {

    [pscustomobject]@{
        file   = $F.Name
        bytes  = $F.Length
        sha256 = Hash-File $F.FullName
    }
}

$EvidenceHashes |
    Export-Csv `
        -LiteralPath "$Out\11_EVIDENCE_HASHES.csv" `
        -NoTypeInformation `
        -Encoding UTF8


# =====================================================================================
# 12 — PACKAGE
# =====================================================================================

Compress-Archive `
    -Path "$Out\*" `
    -DestinationPath $Zip `
    -CompressionLevel Optimal

$ZipHash = Hash-File $Zip


# =====================================================================================
# CONSOLE SUMMARY
# =====================================================================================

Write-Host ""
Write-Host "======================================================================" `
    -ForegroundColor Cyan

Write-Host "MSBF CURRENT-STATE PREFLIGHT COMPLETE" `
    -ForegroundColor Green

Write-Host "======================================================================" `
    -ForegroundColor Cyan

Write-Host ""
Write-Host "Evidence:"
Write-Host "  $Out"

Write-Host ""
Write-Host "Upload this ZIP:"
Write-Host "  $Zip" `
    -ForegroundColor Yellow

Write-Host ""
Write-Host "ZIP SHA-256:"
Write-Host "  $ZipHash"

Write-Host ""
Write-Host "SOURCE AUTHORITY"
Write-Host "  Tag object match : $($TagObject -eq $ExpectedTagObject)"
Write-Host "  Tag commit match : $($TagCommit -eq $ExpectedCommit)"
Write-Host "  Tag tree match   : $($TagTree -eq $ExpectedTree)"

Write-Host ""
Write-Host "CURRENT REPOSITORY"
Write-Host "  HEAD             : $Head"
Write-Host "  HEAD = release   : $($Head -eq $ExpectedCommit)"
Write-Host "  Working tree rows: $(@($WorkingState).Count)"
Write-Host "  Tag -> HEAD paths: $(@($PublicationToHead).Count)"

Write-Host ""
Write-Host "SOURCE INVENTORY"
Write-Host "  Tracked files    : $(@($AllTracked).Count)"
Write-Host "  Control sources  : $(@($ControlRows).Count)"
Write-Host "  SQL files        : $(@($SqlRows).Count)"

Write-Host ""
Write-Host "POSTGRESQL TOOLCHAIN"
Write-Host "  psql             : $($null -ne $Psql)"
Write-Host "  pg_dump          : $($null -ne $PgDump)"
Write-Host "  pg_restore       : $($null -ne $PgRestore)"

Write-Host ""
Write-Host "D: FREE"
Write-Host "  $DFreeGB GB"

Write-Host ""
Write-Host "NO PostgreSQL connection or SQL execution was performed." `
    -ForegroundColor Green

Write-Host "NO historical artifact search was performed." `
    -ForegroundColor Green

Write-Host "======================================================================" `
    -ForegroundColor Cyan
```

### What to send me

Upload the single resulting ZIP:

`D:\MSBF_CAMPAIGN_CURRENT_STATE_<timestamp>.zip`

There is no need to send console screenshots unless the script stops with an error.

The key distinction now is that **all historical discovery is closed**. I already have:

- predecessor Campaign Scale architecture;
- WP3 frozen campaign configuration;
- R5 static harness;
- all three scale profiles;
- source-plan/checkpoint/report/result-set catalogs;
- R26 golden result;
- retained R26 runtime;
- R6 source backup;
- R26 retained-checkpoint backup.

This preflight therefore answers only four current questions:

**What exact v2.1.0 source authority exists now?  
Has `D:\x\m` moved since publication?  
What current source files must replace the predecessor 230-position plan?  
What PostgreSQL/tooling state is available for our new D:-based isolated campaign?**

Once you return this ZIP, I intend the next leap to be **actual harness construction/rebase**, including the 750 zero-difference certification gate and the fresh 2,500 profile—not another artifact-location exercise.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4e25155a-f9de-4bff-a18b-d1976a5f8ddf"></a>
## Andrew / user · C123-M00197

C123-M00197 · 2026-09-11T19:44:02.764000-04:00 · active path

Preceding visible parent: [C123-M00196](part-18.md#m-5cbe0373-4b80-4674-a11a-ab675f86e358)

<!-- BEGIN_SOURCE_MESSAGE -->
what about the bypass line at the top. we normally do that.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3bee61ee-05c9-4ab8-8d0e-3e11457fc931"></a>
## Assistant · C123-M00198

C123-M00198 · 2026-09-11T19:44:13.272981-04:00 · active path

Preceding visible parent: [C123-M00197](part-18.md#m-4e25155a-f9de-4bff-a18b-d1976a5f8ddf)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I would keep the **process-scoped execution-policy bypass** at the top, consistent with how we've handled the other MSBF PowerShell runbooks.

Add this immediately after the opening comments, before `$ErrorActionPreference`:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
```

So the opening should be:

```powershell
# =====================================================================================
# MSBF CAMPAIGN SCALE
# CURRENT-STATE-ONLY PREFLIGHT
# =====================================================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$env:GIT_OPTIONAL_LOCKS = "0"
```

A couple of important points:

- **`-Scope Process` only** — it changes policy for that PowerShell window and disappears when you close it.
- It does **not** alter LocalMachine or CurrentUser policy.
- It normally does not require an elevated/admin PowerShell window.
- For a block pasted directly into PowerShell, it isn't strictly necessary, but it is useful for consistency and becomes relevant once the campaign harness starts invoking our `.ps1` components.
- I would **not** use `Set-ExecutionPolicy Unrestricted` or make a persistent machine-level change.

So yes: **put the bypass line back in.** I should have included it in the current-state preflight given our established MSBF execution pattern.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a8c3515d-50ed-420f-9396-f4e6080a3da3"></a>
## Andrew / user · C123-M00199

C123-M00199 · 2026-09-11T19:48:30.469000-04:00 · active path

Preceding visible parent: [C123-M00198](part-18.md#m-3bee61ee-05c9-4ab8-8d0e-3e11457fc931)

**Editorial record note:** Attachment references: MSBF_CAMPAIGN_CURRENT_STATE_20260911_194525.zip

<!-- BEGIN_SOURCE_MESSAGE -->
====================================================================== 
MSBF CURRENT-STATE PREFLIGHT COMPLETE 
====================================================================== 
 
Evidence: 
  D:\MSBF_CAMPAIGN_CURRENT_STATE_20260911_194525 
 
Upload this ZIP: 
  D:\MSBF_CAMPAIGN_CURRENT_STATE_20260911_194525.zip 
 
ZIP SHA-256: 
  dd7154709dfdec2f4e6ffdb501dfa4da1180c0214b4c408dbc27289c8381a104 
 
SOURCE AUTHORITY 
  Tag object match : False 
  Tag commit match : False 
  Tag tree match   : False 
 
CURRENT REPOSITORY 
  HEAD             : <ERROR> 
  HEAD = release   : False 
  Working tree rows: 0 
  Tag -> HEAD paths: 0 
 
SOURCE INVENTORY 
  Tracked files    : 2884 
  Control sources  : 1751 
  SQL files        : 407 
 
POSTGRESQL TOOLCHAIN 
  psql             : False 
  pg_dump          : False 
  pg_restore       : False 
 
D: FREE 
  16461.86 GB 
 
NO PostgreSQL connection or SQL execution was performed. 
NO historical artifact search was performed. 
======================================================================                Proceed with the next leap - actual harness construction/rebase, including the 750 zero-difference certification gate and the fresh 2,500 profile - not another artifact-location exercise.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f322b593-29b4-4792-827d-d9fe756b5eba"></a>
## Assistant · C123-M00200

C123-M00200 · 2026-09-11T19:49:04.379002-04:00 · active path

Preceding visible parent: [C123-M00199](part-18.md#m-a8c3515d-50ed-420f-9396-f4e6080a3da3)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll build the harness from the retained packages and preflight, correcting Git/tool discovery within it. Database execution stays blocked until source identity and 750 reconciliation pass.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cfa39e0e-266f-4176-82b5-77ccaad09812"></a>
## Assistant · C123-M00201

C123-M00201 · 2026-09-11T19:52:16.485586-04:00 · active path

Preceding visible parent: [C123-M00200](part-18.md#m-f322b593-29b4-4792-827d-d9fe756b5eba)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll locally test the rebuilt harness without database execution, including target isolation and reference-coverage checks before any Windows runtime step.
<!-- END_SOURCE_MESSAGE -->


<a id="m-91b9e9fa-7e35-4b32-a3f8-3e33d256bf88"></a>
## Assistant · C123-M00202

C123-M00202 · 2026-09-11T20:34:44.172339-04:00 · active path

Preceding visible parent: [C123-M00201](part-18.md#m-cfa39e0e-266f-4176-82b5-77ccaad09812)

<!-- BEGIN_SOURCE_MESSAGE -->
## Harness construction R1 is delivered—but full campaign execution is not yet ready

I built and tested the **harness core, source mappings, 750/2,500 profiles, exact-comparison logic and progression gates**.

**I have not completed the full fresh-database execution path.** Inspecting the actual sources exposed three concrete integration gaps that the earlier handoffs did not resolve. The package blocks execution at those gaps rather than passing off a retained-750 replay as a fresh campaign.

**My earlier estimate that this was mostly a thin-wrapper rebase was too optimistic.** The business methods are available, but several successful historical launchers depend on retained intermediate data. Connecting those methods to newly generated campaign data is additional engineering—not an artifact-location problem.

### Deliverables

| File | Contents |
|---|---|
| **Campaign harness R1 (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R1_20260911.zip`; referenced bytes not established here)** | **3.39 MB.** Actual Python/PowerShell code, profiles, source bindings, recovered original methods, comparison contracts and tests. |
| **Build and source-rebase report (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R1_BUILD_REPORT.md`; referenced bytes not established here)** | Exact construction results, source-level findings, completed checks and remaining implementation. |
| **Private verification evidence (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R1_PRIVATE_EVIDENCE_20260911.zip`; referenced bytes not established here)** | Original preflight evidence, diagnosis, test results, source anchors and clean-extraction checks. |
| **Delivery verification (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R1_DELIVERY_VERIFICATION.json`; referenced bytes not established here)** | Machine-readable archive identities, test results and explicit execution limitations. |
| **Harness SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R1_20260911.zip.sha256`; referenced bytes not established here)** | Exact delivery identity. |

These are **private engineering artifacts**, not GitHub publication assets.

## 1. The alarming preflight results came from the collector—not evidence of a broken installation

### Git

Your `02_GIT_STATE.txt` contains successful direct Git output showing:

```text
HEAD:   fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Branch: main
Status: empty
Staged and unstaged differences: empty
```

The six failed helper calls logged **Git with no forwarded arguments**. That helper reused `$Args`, an automatic PowerShell variable. The new package avoids that helper entirely and uses explicit argument lists, checked exit codes and full-length object-ID validation. Microsoft documents `$args` as an automatically maintained variable, not an appropriate general-purpose parameter name. [export reference: cite | turn223895view0]

**The failed comparisons did not establish a tag mismatch.** Fresh tag-object/tree verification still needs the corrected native check; I have not converted the invalid `<ERROR>` results into a PASS.

### PostgreSQL

Your evidence records a running `postgresql-x64-17` service, an installation registered as `17.9-2`, and this executable directory:

```text
C:\Program Files\PostgreSQL\17\bin
```

The earlier collector only looked for commands on `PATH`. The new harness uses the explicit installation directory. **There is no evidence here that PostgreSQL needs reinstalling.**

I also matched **all 1,751 inventoried source/control files** against the supplied repository snapshot, with zero mismatches. The diagnosis and comparisons are retained in the build report (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R1_BUILD_REPORT.md`; referenced bytes not established here).

## 2. What is actually constructed

| Component | Implemented result |
|---|---|
| **Source authority** | Exact 2,884-file publication-tree lock, current and historical tag expectations, direct Git checks and source-nonmutation checks. |
| **Historical source rebase** | All **230 predecessor positions** resolved: 222 byte-identical files in the supplied public tree and eight originals recovered from retained packages. |
| **Module 1 prefix** | **134 original G0/G1/M1 SQL files** assembled with exact source bindings. They have not been executed here. |
| **Campaign profiles** | A reference-750 profile and a fresh-2,500 profile, with separate population/run identities and explicit scenario/date/horizon treatment. |
| **Comparator and gates** | Exact keyed comparisons, missing/extra/duplicate/value detection, narrowly declared metadata normalization, and rejection of incomplete or tail-only reference certification. |
| **Execution core** | Sequential PostgreSQL/Python invocation, isolated-target checks, source hashes, logs, timeouts, progress messages and retained failure receipts. **Database execution remains blocked.** |

The original **172-checkpoint, 58-report and 607-result-set catalogs** are preserved as engineering inputs. Their presence is not represented as proof that every current-release adapter is implemented.

The 2,500 profile defines **2,500 merchants and 5,000 application-scenario paths**. It does **not** multiply the old 130 funded paths or 6,519 structures by a scale factor. Those outcomes must emerge from the new population.

I recovered the necessary small strategy and M2.4 source packages from retained files myself. **No additional historical file search is requested from you.**

## 3. Why full execution remains blocked

### A. The current launchers consume retained population data

The retained R26 code explicitly reads `PHASE2C_R4_STRATEGY.zip`. The historical M2.4 integration launcher loads a packaged:

```text
M2_3_SUCCESSOR_DOWNSTREAM_COMPATIBILITY.csv
```

Those are valid inputs for the executions they originally supported. They are **not a fresh campaign input path**.

The remaining adapter work must connect freshly generated merchant/application evidence to the existing strategy methods, then construct the corresponding compatibility and lifecycle inputs. **Restoring a checkpoint or loading the accepted CSV as the subject would skip the behavior you want to test.**

### B. Configuration declarations are not completed parameter adapters

The old WP3 register contains **926 binding declarations**, with entries explicitly labeled:

```text
DECLARE_BINDING_REQUIREMENT_NO_SQL_EDIT
PENDING_CR_WP5
```

That does not mean 926 defects. It means the old architecture documented where binding was needed without completing all the runtime bindings.

Later methods also contain known-reference assertions such as **1,500 applications, 413 unavailable-feature cases, 130 funded paths and 15,600 monitoring rows**.

For the 750 replay, appropriate known-answer checks should remain exact. For 2,500, population formulas and data-dependent outcomes must be handled differently. **A global replacement of `750` or `130` would be unsafe and would not meet your minimal-impact requirement.**

### C. The accepted R26 result is not a complete end-to-end reference export

The supplied golden ZIP provides **15 distinct tail CSV surfaces** and the retained R26 reconciliation evidence. Its existing 90-check reconciler does not establish full G0-through-M2.12 reconstruction.

That limitation is also explicit in the original runbook: its offline route does not regenerate M2.1–M2.10. [export reference: filecite | turn65file0 | L24-L47]

The full reference contract still needs upstream and current-strategy coverage, with keys and metadata exclusions declared **before** comparing a newly generated subject. The backups and retained source evidence are available; the missing work is the comparison implementation.

**These are source-integration tasks. They are not a revival of the external-signer requirement or a new broad audit prerequisite.**

## 4. Checks actually performed

| Check | Result | Scope |
|---|---|---|
| New harness unit/negative tests | **54/54 PASS** | Fixtures and local process tests; repeated from the cleanly extracted delivery ZIP |
| Recovered R4 strategy engine | **20/20 generated outputs byte-identical** | Actual execution of unchanged methods on retained reference inputs |
| Existing R26 offline replay | **PASS** | Actual source-owned simulation/canonicalization on retained inputs |
| Existing golden reconciler | **90/90 PASS** | Retained R26 evidence—not a new campaign |
| New comparator on actual reference exports | **15/15 PASS; 97,265 rows** | Same-reference comparison test, **not** a fresh zero-difference result |
| Metadata normalization parity | **2/2 exact** | Compared with the source-owned R26 normalization functions |
| Source-owned R26 static transformation | **12 transforms / 16 checks PASS** | Static construction; no SQL execution |
| Runtime entry-point rejection | **Both blocked as intended** | `replay750` and `fresh2500` stopped before credentials or connections |
| Delivery integrity | **PASS** | CRC, safe paths, collisions, manifests and clean-extraction member comparison |

An integrated preparation/compiler test also passed, using the actual source files and analytical methods. **Only the unavailable native Git and PostgreSQL-version probes were mocked**, and that distinction is recorded beside the test receipts.

No Windows-native PowerShell execution, PostgreSQL connection, fresh 750 run, fresh 2,500 run, PBIX refresh or Git mutation was performed here. The original input identities remain unchanged.

## 5. The next Windows action is available—but it cannot close the construction gaps

The package’s `Prepare` mode exercises the delivered software on your actual Python/Windows installation, fixes the earlier Git/tool discovery and performs the retained-source method checks. It does **not** search your archives or connect to PostgreSQL.

After saving the harness ZIP in `D:\MSBF_ARCHIVE`, the launch is:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_CAMPAIGN_HARNESS_R1_20260911.zip'
$ExpectedHash = 'ca338ea1f89745770ae82dbc52801e23d1a2f0208490d9f4abc70d2c63b76b1d'
$Destination = 'D:\MSBF_CS_R1'

if ((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedHash) {
    throw 'STOP: harness ZIP identity mismatch.'
}
if (Test-Path -LiteralPath $Destination) {
    throw 'STOP: destination already exists; do not overwrite.'
}

Expand-Archive -LiteralPath $Zip -DestinationPath $Destination
& "$Destination\RUN_CAMPAIGN.ps1" -Mode Prepare
```

Successful preparation will correctly print:

```text
PACKAGE_PREPARATION = PASS
FULL_750_EXECUTION = HOLD
FRESH_2500_EXECUTION = HOLD
```

That HOLD is already known; **another machine readout will not resolve it**. The command is useful for native verification of the constructed package, not a prerequisite for locating more files.

**The next engineering work is to finish the fresh-input adapters, implement the precise population/cardinality bindings, and complete the full-750 comparison contract. The source methods and retained evidence are now assembled; the remaining responsibility is implementation, not further preparation by you.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-12eecfed-c62f-4a69-b0c6-a0480e2c0aa5"></a>
## Andrew / user · C123-M00203

C123-M00203 · 2026-09-11T20:49:31.252000-04:00 · active path

Preceding visible parent: [C123-M00202](part-18.md#m-91b9e9fa-7e35-4b32-a3f8-3e33d256bf88)

<!-- BEGIN_SOURCE_MESSAGE -->
so are you wanting me to run that powershell command?
<!-- END_SOURCE_MESSAGE -->


<a id="m-719d5d2d-df8f-4bbd-b2a4-985be922188c"></a>
## Assistant · C123-M00204

C123-M00204 · 2026-09-11T20:49:33.190992-04:00 · active path

Preceding visible parent: [C123-M00203](part-18.md#m-12eecfed-c62f-4a69-b0c6-a0480e2c0aa5)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **run that PowerShell block next.**

Its purpose is to verify that the R1 harness I just built behaves correctly on your actual Windows environment. It is **not** going to execute the 750 campaign yet.

### First, save the harness ZIP here

Put:

`MSBF_CAMPAIGN_HARNESS_R1_20260911.zip`

in:

`D:\MSBF_ARCHIVE\`

Then open your normal PowerShell window and run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_CAMPAIGN_HARNESS_R1_20260911.zip'
$ExpectedHash = 'ca338ea1f89745770ae82dbc52801e23d1a2f0208490d9f4abc70d2c63b76b1d'
$Destination = 'D:\MSBF_CS_R1'

if ((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedHash) {
    throw 'STOP: harness ZIP identity mismatch.'
}

if (Test-Path -LiteralPath $Destination) {
    throw 'STOP: destination already exists; do not overwrite.'
}

Expand-Archive -LiteralPath $Zip -DestinationPath $Destination

& "$Destination\RUN_CAMPAIGN.ps1" -Mode Prepare
```

### What this will and will not do

It **will** verify the actual Windows environment, Git/source bindings, tool discovery, harness configuration, retained-source analytical methods, and preparation controls.

It **will not**:

- connect to PostgreSQL;
- create or modify a database;
- execute the 750 campaign;
- execute the 2,500 campaign;
- modify `D:\x\m`;
- commit/push anything to Git;
- touch the published release.

The expected terminal disposition is:

```text
PACKAGE_PREPARATION = PASS
FULL_750_EXECUTION = HOLD
FRESH_2500_EXECUTION = HOLD
```

That HOLD is intentional at this stage. It means the harness correctly refuses to cross into database execution until I finish the remaining fresh-input adapters and full 750 comparison contract.

**Run it and paste the complete console result here.** Then I'll use that result alongside the R1 construction evidence to continue the engineering rather than send you through another discovery exercise.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7384a0b2-8038-4a2e-81a3-8800dce5c569"></a>
## Andrew / user · C123-M00205

C123-M00205 · 2026-09-11T20:53:37.033000-04:00 · active path

Preceding visible parent: [C123-M00204](part-18.md#m-719d5d2d-df8f-4bbd-b2a4-985be922188c)

**Editorial record note:** Attachment references: PREPARE_20260912T005050_5556cc38_RETURN.zip.validation.json; PREPARE_20260912T005050_5556cc38_RETURN.zip; PREPARE_20260912T005050_5556cc38_RETURN.zip(1).sha256

<!-- BEGIN_SOURCE_MESSAGE -->
Powershell Result: MSBF campaign harness R1 — actual package preparation and file-only tests
No historical search. Runtime remains held until fresh-source bridges are completed.
  offline_r26: 15s elapsed
  r4_method: 15s elapsed
PACKAGE_PREPARATION = PASS
FULL_750_EXECUTION = HOLD
FRESH_2500_EXECUTION = HOLD
No database connection, SQL, restore, Git mutation or source search performed.
RETURN ZIP: D:\MSBF_CAMPAIGNS\PREPARE_20260912T005050_5556cc38_RETURN.zip
SHA-256: 90adcbbb58a7d55507dc6285a44c094c274a156d5cf59c6d1928855a5c0a1c62
CONSTRUCTION/READINESS HOLD is recorded. No database campaign was executed.    Now, proceed with the next engineering work, finishing the fresh-input adapters, implementing the precise population/cardinality bindings, and completing the full-750 comparison contract.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fe3e2fc2-daf9-49b8-9f72-7cdb8920c710"></a>
## Assistant · C123-M00206

C123-M00206 · 2026-09-11T20:54:13.523759-04:00 · active path

Preceding visible parent: [C123-M00205](part-18.md#m-7384a0b2-8038-4a2e-81a3-8800dce5c569)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll verify the Windows return, then finish fresh-input wiring, population bindings, and the full-750 comparator while preventing 2,500 execution from inheriting 750-specific assumptions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1485a085-e4b9-4410-a29d-a5d72d1389a3"></a>
## Andrew / user · C123-M00207

C123-M00207 · 2026-09-11T23:51:54.491000-04:00 · active path

Preceding visible parent: [C123-M00206](part-18.md#m-fe3e2fc2-daf9-49b8-9f72-7cdb8920c710)

**Editorial record note:** Attachment references: PREPARE_20260912T005050_5556cc38_RETURN.zip(2).sha256; PREPARE_20260912T005050_5556cc38_RETURN.zip.validation(1).json; PREPARE_20260912T005050_5556cc38_RETURN(1).zip

<!-- BEGIN_SOURCE_MESSAGE -->
Powershell Result: MSBF campaign harness R1 — actual package preparation and file-only tests No historical search. Runtime remains held until fresh-source bridges are completed.   offline_r26: 15s elapsed   r4_method: 15s elapsed PACKAGE_PREPARATION = PASS FULL_750_EXECUTION = HOLD FRESH_2500_EXECUTION = HOLD No database connection, SQL, restore, Git mutation or source search performed. RETURN ZIP: D:\MSBF_CAMPAIGNS\PREPARE_20260912T005050_5556cc38_RETURN.zip SHA-256: 90adcbbb58a7d55507dc6285a44c094c274a156d5cf59c6d1928855a5c0a1c62 CONSTRUCTION/READINESS HOLD is recorded. No database campaign was executed.    Now, proceed with the next engineering work, finishing the fresh-input adapters, implementing the precise population/cardinality bindings, and completing the full-750 comparison contract.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-ac43cd8c-33e1-42ca-8bb2-438fd082c925"></a>
## Assistant · C123-M00208

C123-M00208 · 2026-09-11T23:52:31.978248-04:00 · alternate branch

Preceding visible parent: [C123-M00207](part-18.md#m-1485a085-e4b9-4410-a29d-a5d72d1389a3)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll verify the Windows preparation return, then implement and test the fresh-input adapters, population bindings, and full-750 comparison contract while preserving accepted business sources.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7684fc51-d124-4520-a151-563b9e881bda"></a>
## Andrew / user · C123-M00209

C123-M00209 · 2026-09-12T00:08:10.114000-04:00 · active path

Preceding visible parent: [C123-M00207](part-18.md#m-1485a085-e4b9-4410-a29d-a5d72d1389a3)

<!-- BEGIN_SOURCE_MESSAGE -->
Build Module A — Fresh-input adapters
This is the largest remaining task.

Right now the recovered strategy methods still expect artifacts that originated from accepted historical runs.

Instead, they must consume freshly generated campaign data.

Conceptually today:

```
```

```
historical accepted data
        ↓
strategy methods
```

Needs to become:

```
```

```
fresh Module 1 generation
        ↓
adapter layer
        ↓
strategy methods
```

That adapter is where I expect most of the remaining effort.
<!-- END_SOURCE_MESSAGE -->


<a id="m-29802205-786a-48be-9aaf-3b12e17ad3f5"></a>
## Assistant · C123-M00210

C123-M00210 · 2026-09-12T00:34:28.048150-04:00 · active path

Preceding visible parent: [C123-M00209](part-18.md#m-7684fc51-d124-4520-a151-563b9e881bda)

<!-- BEGIN_SOURCE_MESSAGE -->
Module A R2 is built and packaged.

This closes the **file-level fresh-input adapter construction** that was holding R1: the harness now has a current Module A bridge from fresh campaign inputs into the retained R4 strategy methods, plus 750/2,500 cardinality bindings and the full-750 zero-difference comparison contract.

It does **not** yet claim native database execution, 750 replay, 2,500 campaign completion, Power BI refresh, Git mutation, publication, or audit acceptance.

## Deliverables

| File | Purpose |
|---|---|
| **MSBF Campaign Harness R2 — Module A (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_20260912.zip`; referenced bytes not established here)** | Main package to save under `D:\MSBF_ARCHIVE`. |
| **SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_20260912.zip.sha256`; referenced bytes not established here)** | Exact package identity. |
| **Build report (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_BUILD_REPORT.md`; referenced bytes not established here)** | What was built, tested, and still held. |
| **Delivery verification (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_DELIVERY_VERIFICATION.json`; referenced bytes not established here)** | Machine-readable package and check results. |
| **Private evidence package (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_PRIVATE_EVIDENCE_20260912.zip`; referenced bytes not established here)** | Receipts, manifests, test outputs, parity checks. Not a public artifact. |
| **Private evidence validation (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_PRIVATE_EVIDENCE_VALIDATION.json`; referenced bytes not established here)** | CRC/path-safety validation for the evidence package. |

## R2 package identity

```text
MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_20260912.zip
Bytes:   3,443,306
SHA-256: f53b68780e197e81082e0cb9bbd6608f674f5cf98916cc6065d685fdb4ead3db
Entries: 246
```

## What Module A now does

R2 implements the bridge you described:

```text
fresh Module 1 / M2.1-M2.3 campaign data
        ↓
Module A adapter/export layer
        ↓
retained R4 strategy methods
```

The old Campaign Scale work established useful execution contracts—configuration-driven 750/2,500/25,000 profiles, `module1_run_id` lineage, source-plan concepts, checkpoint/report catalogs, recovery outside the normal path, and fail-closed controls—but it also explicitly required rebasing after the M1/M2 strategy was republished. [export reference: filecite | turn62file0 | L44-L79]

R2 converts that principle into package code for Module A:

- **Fresh subject inputs** are now four current files:
  - `application_scenario_source.csv`
  - `verification_result.csv`
  - `candidate_exact_result.csv`
  - `feature_availability_source.csv`

- **Historical R3 hash-history inputs are prohibited** for fresh campaign subjects. The wrapper writes deterministic no-predecessor provenance markers instead of copying retained predecessor hashes.

- **Reference-750 mode still requires all six R4 input files** so the campaign wrapper can prove byte-identical parity with the original retained R4 engine.

- **2,500 profile bindings are explicit**: 2,500 merchants, 5,000 application-scenario rows, 15,000 verification rows, 5,000 feature rows, 450,000 base-history rows and 900,000 scenario-history rows.

Candidate structures, funded paths and monitoring rows remain data-dependent. R2 does **not** multiply the old 750 outcomes into 2,500 expectations.

## Checks completed

| Check | Result |
|---|---|
| Your R1 Prepare return package | CRC/path safety PASS, 21 files, SHA matched. [export reference: filecite | turn69file0 | L2-L8] |
| Final package CRC/path/case-fold/duplicate checks | PASS |
| Final package source-member byte reconciliation | PASS |
| Manifest rows / checksum rows | 244 / 245 |
| Clean-extract package verification | PASS |
| Clean-extract selftests | 71/71 PASS |
| Module A reference input validation | PASS |
| Original R4 engine vs. campaign wrapper | 20/20 output files byte-identical |
| Fresh no-predecessor fixture | PASS |
| Database connection / SQL execution | NOT PERFORMED |
| Fresh 750 replay / fresh 2,500 campaign | NOT PERFORMED |

The R26 retained route still matters as reference evidence, but the runbook is explicit that the existing offline route does **not** regenerate M2.1–M2.10 or execute M2.12 in a database. [export reference: filecite | turn65file0 | L24-L47] That is why R2 now builds the fresh-input bridge rather than pretending the retained R26 tail proof is a fresh campaign.

## Remaining gates

R2 narrows the construction hold to three native-runtime items:

1. **Native Module A DB export** against an isolated 750 subject database.
2. **Full 750 zero-difference comparison** using the new predeclared comparison contract.
3. **Downstream M2.4/R26 fresh-subject bridge** after Module A/R4 outputs exist as native subject outputs.

This is also why R2 continues to respect the warning that the historical 230-position catalog is not a universal R26 end-to-end launcher, and that qualified Route B was limited to portable checkpoint restore plus isolated retained-final replay—not arbitrary new campaign inputs. [export reference: filecite | turn69file0 | L25-L39]

## Next owner-side verification command

Save the main R2 ZIP to:

```text
D:\MSBF_ARCHIVE\MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_20260912.zip
```

Then run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_CAMPAIGN_HARNESS_R2_MODULE_A_20260912.zip'
$ExpectedHash = 'f53b68780e197e81082e0cb9bbd6608f674f5cf98916cc6065d685fdb4ead3db'
$Destination = 'D:\MSBF_CS_R2_MODULE_A'

if ((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedHash) {
    throw 'STOP: harness ZIP identity mismatch.'
}

if (Test-Path -LiteralPath $Destination) {
    throw 'STOP: destination already exists; choose a fresh destination.'
}

Expand-Archive -LiteralPath $Zip -DestinationPath $Destination

& "$Destination\RUN_CAMPAIGN.ps1" `
    -Mode ModuleA `
    -Repository 'D:\x\m' `
    -WorkRoot 'D:\MSBF_CAMPAIGNS' `
    -PostgreSQLBin 'C:\Program Files\PostgreSQL\17\bin' `
    -PythonExecutable 'python'
```

Expected terminal disposition:

```text
MODULE_A_FRESH_INPUT_ADAPTERS = PASS
REFERENCE_R4_WRAPPER_PARITY = PASS
FRESH_NO_PREDECESSOR_FIXTURE = PASS
DATABASE_EXECUTION = HOLD
FULL_750_EXECUTION = HOLD
FRESH_2500_EXECUTION = HOLD
```

That HOLD is intentional. It means **Module A construction passed**, but the harness still refuses to cross into native database execution until the next gate is built and authorized.

The next engineering leap should be **Native Module A DB Export + 750 Subject Construction**, not more artifact discovery.
<!-- END_SOURCE_MESSAGE -->


<a id="m-321ece0c-ef93-436d-be10-42e979b5cc8e"></a>
## Andrew / user · C123-M00211

C123-M00211 · 2026-09-12T00:36:37.841000-04:00 · active path

Preceding visible parent: [C123-M00210](part-18.md#m-29802205-786a-48be-9aaf-3b12e17ad3f5)

<!-- BEGIN_SOURCE_MESSAGE -->
Exception: D:\MSBF_CS_R2_MODULE_A\RUN_CAMPAIGN.ps1:14
Line |
  14 |      throw "STOP: Python not at the path observed in your preflight: $ …
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | STOP: Python not at the path observed in your preflight: python
<!-- END_SOURCE_MESSAGE -->


<a id="m-40c99e6a-0afe-4e87-a4f4-948543c05a69"></a>
## Assistant · C123-M00212

C123-M00212 · 2026-09-12T00:36:40.665788-04:00 · active path

Preceding visible parent: [C123-M00211](part-18.md#m-321ece0c-ef93-436d-be10-42e979b5cc8e)

<!-- BEGIN_SOURCE_MESSAGE -->
This is a **good failure**. It's a harness bug, not an MSBF bug.

The important part is:

> **STOP: Python not at the path observed in your preflight: python**

That tells me exactly what happened.

## Root cause

I made an incorrect assumption in R2.

Your preflight proved one of these is true:

- Python is installed but **`python` is not the executable name**
- or Python is available only through **`py.exe`**
- or it is installed in a specific path (Anaconda, Store install, etc.)
- or the launcher isn't on PATH.

The harness should **discover Python**, not require `"python"`.

That's my mistake.

---

## Do NOT change your machine

Please **do not**:

- reinstall Python
- edit PATH
- create aliases
- change environment variables

This is exactly the kind of thing the harness should handle automatically.

---

# Let's fix the harness correctly

Rather than hardcoding

```powershell
python
```

the harness should determine the interpreter using a fallback sequence.

Something like:

```
1. explicit -PythonExecutable parameter

2. python

3. py -3

4. py

5. registry

6. fail closed
```

That's much more robust.

---

# Before I build R3

I need exactly one thing.

Run:

```powershell
Get-Command python,py -ErrorAction SilentlyContinue |
    Format-List Name,Source
```

and

```powershell
py --version
```

(if that errors, tell me.)

and

```powershell
python --version
```

(if that errors, tell me.)

That will tell me exactly how your Windows installation exposes Python.

---

# I also want to improve the harness

Since we're already making another revision, I want to eliminate this entire class of failures.

Instead of relying on PATH, R3 should automatically discover:

- Git
- Python
- psql
- pg_dump
- pg_restore

exactly the same way.

Then we never have this issue again.

---

## This is actually good timing

We're still before **any database execution**.

Nothing has mutated.

Nothing has been restored.

Nothing has been executed.

So this is exactly where I would want to discover a portability issue.

---

I would call this:

> **Campaign Harness R2 Finding 001**
>
> Toolchain discovery incorrectly assumed `python` instead of implementing adaptive interpreter discovery.

That's a harness defect—not a campaign defect.

I would fix it before proceeding to any native 750 execution.
<!-- END_SOURCE_MESSAGE -->


<a id="m-574acad5-92ad-45be-bada-6dc2c767dd2d"></a>
## Andrew / user · C123-M00213

C123-M00213 · 2026-09-12T00:37:48.937000-04:00 · active path

Preceding visible parent: [C123-M00212](part-18.md#m-40c99e6a-0afe-4e87-a4f4-948543c05a69)

<!-- BEGIN_SOURCE_MESSAGE -->
Name   : python.exe
Source : C:\Python314\python.exe

Name   : py.exe
Source : C:\WINDOWS\py.exe

PS D:\x\m> py --version
Python 3.14.7
PS D:\x\m> python --version
Python 3.14.7
<!-- END_SOURCE_MESSAGE -->


<a id="m-b6c60e97-e91c-4514-8571-7c411c384540"></a>
## Assistant · C123-M00214

C123-M00214 · 2026-09-12T00:37:52.682205-04:00 · active path

Preceding visible parent: [C123-M00213](part-18.md#m-574acad5-92ad-45be-bada-6dc2c767dd2d)

<!-- BEGIN_SOURCE_MESSAGE -->
Good — no R3 needed yet. Python is installed and available. The R2 command I gave you passed the **command alias** `python`, but the harness wanted a **literal executable path**.

Run the existing extracted package again with the full Python path:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

& "D:\MSBF_CS_R2_MODULE_A\RUN_CAMPAIGN.ps1" `
    -Mode ModuleA `
    -Repository 'D:\x\m' `
    -WorkRoot 'D:\MSBF_CAMPAIGNS' `
    -PostgreSQLBin 'C:\Program Files\PostgreSQL\17\bin' `
    -PythonExecutable 'C:\Python314\python.exe'
```

You do **not** need to re-extract the ZIP or create a new destination.

Expected disposition remains:

```text
MODULE_A_FRESH_INPUT_ADAPTERS = PASS
REFERENCE_R4_WRAPPER_PARITY = PASS
FRESH_NO_PREDECESSOR_FIXTURE = PASS
DATABASE_EXECUTION = HOLD
FULL_750_EXECUTION = HOLD
FRESH_2500_EXECUTION = HOLD
```

This still should not connect to PostgreSQL or execute SQL. If it fails again, paste the exception and I’ll patch the harness rather than having you change your environment.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b9659601-f599-4ac5-946e-569dd071101c"></a>
## Andrew / user · C123-M00215

C123-M00215 · 2026-09-12T00:42:58.727000-04:00 · active path

Preceding visible parent: [C123-M00214](part-18.md#m-b6c60e97-e91c-4514-8571-7c411c384540)

**Editorial record note:** Attachment references: MODULE_A_20260912T043825_437e112b_RETURN.zip; MODULE_A_20260912T043825_437e112b_RETURN.zip.sha256; MODULE_A_20260912T043825_437e112b_RETURN.zip.validation.json

<!-- BEGIN_SOURCE_MESSAGE -->
MSBF campaign harness R2 — actual package preparation and file-only tests
No historical search. Module A adapters are constructed and file-tested; database runtime remains held until native export/full-750 gates pass.
  r4_original_reference_output: 15s elapsed
  r4_campaign_reference_output: 15s elapsed
MODULE_A_FRESH_INPUT_ADAPTERS = PASS
REFERENCE_R4_WRAPPER_PARITY = PASS
FRESH_NO_PREDECESSOR_FIXTURE = PASS
DATABASE_EXECUTION = HOLD
FULL_750_EXECUTION = HOLD
FRESH_2500_EXECUTION = HOLD
No database connection, SQL, restore, Git mutation or source search performed.
RETURN ZIP: D:\MSBF_CAMPAIGNS\MODULE_A_20260912T043825_437e112b_RETURN.zip
SHA-256: 945e2e5d56bd6b638e9c167f257f280a83050177e7f558549c08ace4aea378f0
CONSTRUCTION/READINESS HOLD is recorded. No database campaign was executed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c659144f-817d-454b-9765-532ac627cdca"></a>
## Assistant · C123-M00216

C123-M00216 · 2026-09-12T00:49:07.971271-04:00 · active path

Preceding visible parent: [C123-M00215](part-18.md#m-b9659601-f599-4ac5-946e-569dd071101c)

<!-- BEGIN_SOURCE_MESSAGE -->
Module A native export gate is now built.

This R3 package advances beyond file-only adapter testing: it adds a **native, read-only PostgreSQL export path** that can pull the Module A/R4 input surfaces from an explicit subject database, validate them, run the R4 campaign-aware wrapper, and in `REFERENCE_750` mode compare all 20 R4 outputs against the retained accepted reference.

Your uploaded R2 return package validates cleanly: 94 regular files, CRC PASS, path safety PASS, and SHA-256 `945e2e5d56bd6b638e9c167f257f280a83050177e7f558549c08ace4aea378f0`. [export reference: filecite | turn70file0 | L2-L8]

## Deliverables

| File | Purpose |
|---|---|
| MSBF Campaign Harness R3 — Native Module A (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_20260912.zip`; referenced bytes not established here) | Main package to save under `D:\MSBF_ARCHIVE`. |
| SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_20260912.zip.sha256`; referenced bytes not established here) | Package identity. |
| Build report (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_BUILD_REPORT.md`; referenced bytes not established here) | What changed, what passed, and what remains held. |
| Delivery verification (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_DELIVERY_VERIFICATION.json`; referenced bytes not established here) | CRC/path/expanded-byte verification. |
| Selftest evidence (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_SELFTEST.json`; referenced bytes not established here) | Clean-extract selftests: 77/77 PASS. |
| Delivery manifest (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_DELIVERY_MANIFEST.csv`; referenced bytes not established here) | Hashes for the delivered files. |

## R3 package identity

```text
MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_20260912.zip
Bytes:   3,491,953
SHA-256: 37dc9ca1c6ea031f01ce1b591490c81d24bcd2df6ee7b5f2f81823a6832ea46e
Entries: 252
Clean-extract selftests: 77/77 PASS
```

## What R3 does

R3 adds:

```text
PostgreSQL subject database
        ↓
read-only Module A export queries
        ↓
six/four CSV input surfaces
        ↓
R4 campaign-aware strategy wrapper
        ↓
reference-750 parity comparison or fresh-campaign validation
```

It does **not** create, drop, restore, or mutate databases. The native path uses `PGOPTIONS` with `default_transaction_read_only=on` and `COPY (SELECT ...) TO STDOUT`.

## Recommended next owner-side run

For the first R3 test, run it against the retained Phase2C R3 source database, assuming it still exists locally:

```text
msbf_r1b_p2c_r3_20260829_190652
```

Save the R3 ZIP to:

```text
D:\MSBF_ARCHIVE\MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_20260912.zip
```

Then run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_CAMPAIGN_HARNESS_R3_NATIVE_MODULE_A_20260912.zip'
$ExpectedHash = '37dc9ca1c6ea031f01ce1b591490c81d24bcd2df6ee7b5f2f81823a6832ea46e'
$Destination = 'D:\MSBF_CS_R3_NATIVE_MODULE_A'

if ((Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant() -ne $ExpectedHash) {
    throw 'STOP: harness ZIP identity mismatch.'
}

if (Test-Path -LiteralPath $Destination) {
    throw 'STOP: destination already exists; choose a fresh destination.'
}

Expand-Archive -LiteralPath $Zip -DestinationPath $Destination

& "$Destination\RUN_CAMPAIGN.ps1" `
    -Mode NativeModuleA `
    -Repository 'D:\x\m' `
    -WorkRoot 'D:\MSBF_CAMPAIGNS' `
    -PostgreSQLBin 'C:\Program Files\PostgreSQL\17\bin' `
    -PythonExecutable 'C:\Python314\python.exe' `
    -SubjectDatabase 'msbf_r1b_p2c_r3_20260829_190652' `
    -ProfileId '0750_REFERENCE' `
    -ModuleAMode 'REFERENCE_750' `
    -DatabaseHost '127.0.0.1' `
    -DatabasePort 5432 `
    -DatabaseUser 'postgres' `
    -ApproveReadOnlyDatabaseExport
```

Expected successful disposition:

```text
NATIVE_MODULE_A_DB_EXPORT = PASS
REFERENCE_750_R4_OUTPUT_COMPARISON = PASS
REFERENCE_750_R4_FILES_COMPARED = 20
DATABASE_MUTATION = NO
FULL_750_EXECUTION = HOLD
FRESH_2500_EXECUTION = HOLD
```

This will ask for the local PostgreSQL password. It does not record the password.

## Boundary

A PASS here proves **native Module A/R4 equivalence** for the named subject database. It still does **not** certify the full 750 replay or authorize fresh 2,500 execution. The next engineering gate after this return package is the full isolated 750 subject run/canonical database comparison.
<!-- END_SOURCE_MESSAGE -->


<a id="m-506f74a8-a764-462d-bc6e-cbec55c50650"></a>
## Andrew / user · C123-M00217

C123-M00217 · 2026-09-12T00:51:02.868000-04:00 · active path

Preceding visible parent: [C123-M00216](part-18.md#m-c659144f-817d-454b-9765-532ac627cdca)

<!-- BEGIN_SOURCE_MESSAGE -->
Exception: D:\MSBF_CS_R3_NATIVE_MODULE_A\RUN_CAMPAIGN.ps1:40
Line |
  40 |      throw "STOP: package action failed with exit code $NativeExitCode …
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | STOP: package action failed with exit code 2. Preserve the emitted evidence.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3d179073-4ee5-401d-9105-d78fd2bdb037"></a>
## Assistant · C123-M00218

C123-M00218 · 2026-09-12T00:51:05.218394-04:00 · active path

Preceding visible parent: [C123-M00217](part-18.md#m-506f74a8-a764-462d-bc6e-cbec55c50650)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — stop there and **do not rerun yet**.

That failure means the R3 wrapper did exactly what it was supposed to do at the PowerShell level: the internal package action returned nonzero, and the launcher stopped rather than continuing.

Now I need the emitted evidence from that failed run.

## What to upload

Look in:

```text
D:\MSBF_CAMPAIGNS
```

Upload the newest R3 return package, likely named something like:

```text
NATIVE_MODULE_A_20260912T...._RETURN.zip
```

Also upload its `.sha256` and `.validation.json` if they exist.

## Quick command to find it

Run this in PowerShell:

```powershell
Get-ChildItem 'D:\MSBF_CAMPAIGNS' -Recurse -File |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 25 FullName, Length, LastWriteTime |
    Format-Table -AutoSize
```

If you see a newest `*_RETURN.zip`, upload that ZIP.

## What I expect the failure to be

Exit code `2` likely means one of these native Module A export conditions failed:

- the subject database name was not found;
- `psql` failed to connect or authenticate;
- one of the expected source tables/views was not present in `msbf_r1b_p2c_r3_20260829_190652`;
- the read-only export query failed;
- exported CSV columns did not match the declared Module A input contract.

I do **not** want to guess which one. The evidence package should tell us precisely.

The R2 return was clean — 94 regular files, CRC PASS, path-safety PASS — so this is now a **native database/export integration failure**, not a package-integrity issue. [export reference: filecite | turn70file0 | L2-L8]

Upload the emitted return ZIP and I’ll patch the next package from the actual failure evidence.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5f5565d4-c83d-4e31-880b-eb0f381bcc49"></a>
## Andrew / user · C123-M00219

C123-M00219 · 2026-09-12T00:52:47.608000-04:00 · active path

Preceding visible parent: [C123-M00218](part-18.md#m-3d179073-4ee5-401d-9105-d78fd2bdb037)

**Editorial record note:** Attachment references: NATIVE_MODULE_A_20260912T045029_904caab6_RETURN.zip; NATIVE_MODULE_A_20260912T045029_904caab6_RETURN.zip.sha256; NATIVE_MODULE_A_20260912T045029_904caab6_RETURN.zip.validation.json

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->
