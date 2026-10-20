# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 17 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-16.md)
[Next part](part-18.md)

<a id="m-1747f8dd-31e0-4d34-b1e2-fbdd48740ed8"></a>
## Assistant · C123-M00182

C123-M00182 · 2026-09-11T19:05:48.382604-04:00 · active path

Preceding visible parent: [C123-M00181](part-16.md#m-8bda3f7a-87e4-4f63-bf23-95b2af88925b)

<!-- BEGIN_SOURCE_MESSAGE -->
The effort is **much smaller than the old Campaign Scale work made it appear**. Most of the hard design work already exists: parameterized scale profiles, `module1_run_id` lineage, the normal-source-plan concept, checkpoint/report catalogs, exact source/cardinality checks, recovery separation, and fail-closed behavior. [export reference: filecite | turn63file1 | L64-L95]

What we need now is primarily **rebasing and simplification**, not inventing another campaign architecture.

I would build a compact harness around roughly six functions: a profile/config layer for 750 and 2,500; a current v2.1.0 ordered source plan with hashes; an orchestrator that creates/targets the isolated database and executes the current SQL in order; checkpoint/report capture; a 750 accepted-reference reconciler; and a final run receipt containing source/config identities, stage timing, cardinalities, reconciliation results, and pre/post nonmutation evidence. The successful publication work already demonstrated the useful pattern: read-only preflight, isolated PostgreSQL execution, locked source/checkpoint identities, post-run reconciliation, and source nonmutation. [export reference: filecite | turn63file2 | L111-L139]

I would **not** port most of the old bootstrap/signature/trust-receipt/orchestrator ceremony. That complexity was responsible for much of the prior engineering burden. Even the old R5 specification was trying to solve authenticated handoffs, external signer authority, single-use trust, fake-engine paths, and sealing in addition to actually running the campaign. [export reference: filecite | turn63file0 | L30-L43] We no longer need that architecture for this local controlled campaign.

### How much work?

I would characterize it as **one substantial harness construction/rebase cycle, followed by one preflight correction cycle if needed**.

The likely work distribution is something like:

- **Low effort:** 750/2,500 profile/config definitions. Those concepts already exist.
- **Moderate:** regenerate the ordered source plan against v2.1.0 and map predecessor positions to current files.
- **Moderate:** execution driver/orchestrator.
- **Moderate:** checkpoint/report capture, largely adapting prior contracts rather than redesigning them.
- **Moderate:** 750 zero-difference reconciliation.
- **Low:** run receipts, timing, SHA-256 manifests and nonmutation checks.

The **business SQL itself should require essentially no development**. If we start changing strategy code, something has gone wrong with the campaign objective.

I also don't think we need to manually recreate 607 report definitions one by one. We should recover the prior catalogs and mechanically rebase them. The old architecture already had 172 checkpointed nonreporting positions, 58 reporting positions and 607 report result sets. [export reference: filecite | turn63file1 | L70-L93]

## What I absolutely need from you

Very little.

I need **one read-only machine inventory first**. I can give you a single PowerShell block that gathers everything I need without changing the repo or touching a database:

1. current `D:\x\m` Git status, HEAD, tags and v2.1.0 identity;
2. SQL/source inventory and SHA-256 hashes;
3. locations of the retained Campaign Scale package/catalogs;
4. PostgreSQL/`psql` version and installed cluster/service information;
5. retained Route-B / 750 reference artifacts and checkpoint filenames;
6. filesystem locations and free space relevant to an isolated campaign database/output directory.

You run that once and paste/upload the result.

After that there are only **two decisions I need from you**, and we may already know the answers:

**Canonical 750 reference.** I need us to identify exactly what physical artifact/output population represents the accepted v2.1.0 750 result against which “zero differences” will be judged. I do not want to invent that reference.

**Execution authorization.** Once static preflight passes, I need your explicit authorization to create an isolated campaign database and actually execute the 750 replay. We can then make the successful 750 reconciliation itself authorize progression to 2,500 under a predefined gate, rather than stopping repeatedly for permission.

I do **not** need you to:
- manually collect hundreds of hashes;
- manually inspect 230 source positions;
- answer detailed design questions;
- recreate the old campaign control package;
- provide passwords in chat;
- manually compare 750 outputs;
- run SQL one program at a time;
- take dozens of screenshots.

That is precisely what the harness should eliminate.

## How I want us to move in leaps

I think we can reduce this to **three major user interactions**.

**Leap 1 — discovery.**  
I give you one read-only PowerShell collector. You return one evidence folder/ZIP or pasted output.

From that, I construct the complete current campaign design: source-plan rebase, configs, execution order, expected controls, 750 comparator and evidence structure.

**Leap 2 — build + static preflight.**  
Rather than giving you 20 incremental scripts, I give you one campaign-harness package and one command that performs all non-destructive preflight checks. It should either produce:

`READY_FOR_750_EXECUTION`

or one concise defect list.

If defects are merely harness/configuration issues, we repair them in one batch.

**Leap 3 — execute 750 → gate → 2,500.**  
Once you authorize runtime, the harness should be capable of:

`750 fresh isolated replay → automatic reconciliation → PASS/STOP`

and, if the predefined gate is satisfied:

`fresh 2,500 campaign → validation → campaign receipt`

I would still probably make the transition from 750 to 2,500 a **visible stop**, because the 750 zero-diff result is valuable enough that I want to inspect it before creating the new population. But that should be one stop—not 50.

### The 750 gate I would encode

Something like:

```text
SOURCE_IDENTITY                     PASS
REFERENCE_CONFIG_IDENTITY           PASS
SOURCE_NONMUTATION                  PASS
EXPECTED_STAGE_CARDINALITIES        PASS
750_BUSINESS_ROW_DIFFERENCES        0
750_VALUE_DIFFERENCES               0
750_MISSING_REFERENCE_ROWS          0
750_UNEXPECTED_ROWS                 0
750_DECISION_DIFFERENCES            0
750_FINANCIAL_RECONCILIATION        PASS
CHECKPOINT/REPORT_CONTROLS           PASS
RUN_TERMINAL_STATUS                 PASS

=> AUTHORIZE_2500 = TRUE
```

Execution timestamps, paths, database OIDs, elapsed time and other inherently run-specific metadata would be excluded **in advance** from zero-difference testing.

Then the 2,500 campaign is not expected to match anything row-for-row. It is tested against its **contracts**: population size, expected cardinalities, referential integrity, decision-state invariants, financial reconciliation, lifecycle integrity, source nonmutation and successful completion.

## One important design choice

I would build the new harness as a **thin layer around the accepted SQL**, not embed campaign logic into another giant script.

Conceptually:

```text
campaign/
    config/
        0750_reference.json
        2500_fresh.json

    manifests/
        source_plan.csv
        checkpoint_catalog.csv
        report_catalog.csv

    harness/
        preflight.ps1
        run_campaign.ps1
        execute_sql.py
        capture_results.py
        reconcile_750.py
        certify_run.py

    evidence/
        <campaign_run_id>/
```

That keeps the distinction very clean:

**MSBF SQL owns business semantics.  
The harness owns execution, evidence and reproducibility.**

That separation is also better career evidence than another heavily intertwined control framework.

### So, what do I need from you right now?

**Nothing beyond one machine readout.**

You have already made the important governance decisions:

- preserve current v2.1.0 logic;
- replay 750 and require zero semantic differences;
- then run a genuinely fresh 2,500 population;
- retain useful Campaign Scale controls;
- abandon the unnecessarily restrictive trust/custody path;
- move in large controlled execution blocks.

If you want to begin now, my next response should be **the single read-only PowerShell discovery block**, not another planning exercise. After you return its output, I should have enough to build the actual campaign harness.
<!-- END_SOURCE_MESSAGE -->


<a id="m-afbc0810-b2bf-46f7-b9f3-ee80d93385a5"></a>
## Andrew / user · C123-M00183

C123-M00183 · 2026-09-11T19:09:05.069000-04:00 · active path

Preceding visible parent: [C123-M00182](part-17.md#m-1747f8dd-31e0-4d34-b1e2-fbdd48740ed8)

<!-- BEGIN_SOURCE_MESSAGE -->
Let's begin.
<!-- END_SOURCE_MESSAGE -->


<a id="m-058eba7d-3a8d-4385-8164-ab4897645608"></a>
## Assistant · C123-M00184

C123-M00184 · 2026-09-11T19:09:07.171651-04:00 · active path

Preceding visible parent: [C123-M00183](part-17.md#m-afbc0810-b2bf-46f7-b9f3-ee80d93385a5)

<!-- BEGIN_SOURCE_MESSAGE -->
Good. We start with **one collection pass**, not incremental troubleshooting.

Run the block below in a normal **PowerShell** window on the Windows machine that contains `D:\x\m`. It does **not** connect to PostgreSQL, execute SQL, change Git state, modify the repository, or start/stop services. It only reads the machine/repository and writes a new evidence folder **outside** the repo, then creates one ZIP for you to upload here.

It also hard-checks the publication identities we expect for `module-2-g3-v2.1.0`, inventories current executable/control sources, searches for the prior Campaign Scale machinery and 750-reference artifacts, and inventories PostgreSQL without connecting to it.

```powershell
# ======================================================================================
# MSBF CAMPAIGN SCALE — PHASE 0/1 DISCOVERY COLLECTOR
#
# PURPOSE
#   Collect everything needed to rebase the Campaign Scale harness onto the
#   published MSBF v2.1.0 source authority and prepare:
#
#       750 accepted-reference zero-difference replay
#           ->
#       fresh 2,500-merchant end-to-end shakedown
#
# SAFETY / NON-MUTATION
#   - NO PostgreSQL connection
#   - NO SQL execution
#   - NO database creation/drop/restore
#   - NO git fetch/pull/checkout/reset/commit
#   - NO source modification
#   - NO service start/stop
#   - Writes ONLY to a new discovery folder outside D:\x\m
# ======================================================================================

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# --------------------------------------------------------------------------------------
# GOVERNING PATH / PUBLICATION IDENTITY
# --------------------------------------------------------------------------------------

$Repo = "D:\x\m"

$ExpectedTag       = "module-2-g3-v2.1.0"
$ExpectedCommit    = "fd9f67b6d1d7fc848d315bcb696487b82c9a8046"
$ExpectedTree      = "fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb"
$ExpectedTagObject = "cdef0c49eb37d0cc72444c0829c253e09eee050a"

if (-not (Test-Path -LiteralPath $Repo -PathType Container)) {
    throw "Repository not found: $Repo"
}

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$OutRoot = "D:\x\MSBF_CAMPAIGN_DISCOVERY_$Stamp"
$ZipPath = "$OutRoot.zip"

New-Item -ItemType Directory -Path $OutRoot -Force | Out-Null

$ErrorLog = Join-Path $OutRoot "ERRORS.txt"

function Add-ErrorLine {
    param([string]$Text)
    Add-Content -LiteralPath $ErrorLog -Value ("[{0}] {1}" -f (Get-Date -Format o), $Text)
}

function Get-GitValue {
    param([string[]]$GitArgs)

    try {
        $out = & git -C $Repo @GitArgs 2>&1
        if ($LASTEXITCODE -ne 0) {
            return "<ERROR: $($out -join ' ')>"
        }
        return (($out | Out-String).Trim())
    }
    catch {
        Add-ErrorLine "git $($GitArgs -join ' '): $($_.Exception.Message)"
        return "<ERROR>"
    }
}

function Get-SafeHash {
    param([string]$Path)

    try {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    catch {
        Add-ErrorLine "Hash failure: $Path :: $($_.Exception.Message)"
        return "<HASH_ERROR>"
    }
}

# Prevent optional Git index locking / refresh writes during inspection.
$env:GIT_OPTIONAL_LOCKS = "0"

# --------------------------------------------------------------------------------------
# 1. BASIC MACHINE / RUN IDENTITY
# --------------------------------------------------------------------------------------

$Basic = [ordered]@{
    collection_started_utc = (Get-Date).ToUniversalTime().ToString("o")
    powershell_version      = $PSVersionTable.PSVersion.ToString()
    repo_path               = $Repo
    evidence_path           = $OutRoot
}

try {
    $os = Get-CimInstance Win32_OperatingSystem
    $cpu = Get-CimInstance Win32_Processor | Select-Object -First 1

    $Basic.os_caption         = $os.Caption
    $Basic.os_version         = $os.Version
    $Basic.os_architecture    = $os.OSArchitecture
    $Basic.memory_gb          = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    $Basic.cpu                = $cpu.Name
    $Basic.logical_processors = $cpu.NumberOfLogicalProcessors
}
catch {
    Add-ErrorLine "System inventory: $($_.Exception.Message)"
}

$Basic | ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath (Join-Path $OutRoot "00_BASIC_ENVIRONMENT.json") -Encoding UTF8

# --------------------------------------------------------------------------------------
# 2. GIT / PUBLICATION BINDING
# --------------------------------------------------------------------------------------

$Head      = Get-GitValue @("rev-parse", "HEAD")
$HeadTree  = Get-GitValue @("rev-parse", "HEAD^{tree}")
$Branch    = Get-GitValue @("branch", "--show-current")
$TagObject = Get-GitValue @("rev-parse", "refs/tags/$ExpectedTag")
$TagCommit = Get-GitValue @("rev-parse", "$ExpectedTag^{}")
$TagTree   = Get-GitValue @("rev-parse", "$ExpectedTag^{}^{tree}")

$GitIdentity = [ordered]@{
    expected_tag          = $ExpectedTag
    expected_commit       = $ExpectedCommit
    expected_tree         = $ExpectedTree
    expected_tag_object   = $ExpectedTagObject

    current_branch        = $Branch
    current_head          = $Head
    current_head_tree     = $HeadTree

    observed_tag_object   = $TagObject
    observed_tag_commit   = $TagCommit
    observed_tag_tree     = $TagTree

    tag_commit_match      = ($TagCommit -eq $ExpectedCommit)
    tag_tree_match        = ($TagTree -eq $ExpectedTree)
    tag_object_match      = ($TagObject -eq $ExpectedTagObject)
    head_at_publication   = ($Head -eq $ExpectedCommit)
}

$GitIdentity | ConvertTo-Json -Depth 5 |
    Set-Content -LiteralPath (Join-Path $OutRoot "01_PUBLICATION_IDENTITY.json") -Encoding UTF8

$GitStatePath = Join-Path $OutRoot "02_GIT_STATE.txt"

@"
================================================================================
MSBF GIT STATE
================================================================================
"@ | Set-Content -LiteralPath $GitStatePath -Encoding UTF8

$gitSections = @(
    @("REMOTE",                @("remote", "-v")),
    @("STATUS",                @("status", "--porcelain=v1", "--untracked-files=all")),
    @("UNSTAGED DIFF",         @("diff", "--no-ext-diff", "--name-status")),
    @("STAGED DIFF",           @("diff", "--cached", "--no-ext-diff", "--name-status")),
    @("TAGS NEAR HEAD",        @("tag", "--points-at", "HEAD")),
    @("RECENT COMMITS",        @("log", "-n", "12", "--decorate", "--oneline")),
    @("SUBMODULE STATUS",      @("submodule", "status")),
    @("TRACKED MODIFIED/OTHER",@("ls-files", "-m", "-o", "--exclude-standard"))
)

foreach ($section in $gitSections) {
    Add-Content -LiteralPath $GitStatePath -Value "`r`n--- $($section[0]) ---"
    try {
        $v = & git -C $Repo @($section[1]) 2>&1
        Add-Content -LiteralPath $GitStatePath -Value ($v | Out-String)
    }
    catch {
        Add-ErrorLine "Git section $($section[0]): $($_.Exception.Message)"
    }
}

# --------------------------------------------------------------------------------------
# 3. TRACKED SOURCE / CONTROL INVENTORY + SHA-256
# --------------------------------------------------------------------------------------

$SourceExtensions = @(
    ".sql", ".ps1", ".psm1", ".py",
    ".json", ".csv", ".yaml", ".yml",
    ".toml", ".cmd", ".bat"
)

$Tracked = @()

try {
    $Tracked = & git -C $Repo ls-files
}
catch {
    Add-ErrorLine "git ls-files failed: $($_.Exception.Message)"
}

$SourceRows = foreach ($rel in $Tracked) {

    $full = Join-Path $Repo $rel

    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        continue
    }

    $ext = [IO.Path]::GetExtension($full).ToLowerInvariant()

    if ($SourceExtensions -notcontains $ext) {
        continue
    }

    $fi = Get-Item -LiteralPath $full

    [pscustomobject]@{
        relative_path       = $rel
        extension           = $ext
        bytes               = $fi.Length
        last_write_time_utc = $fi.LastWriteTimeUtc.ToString("o")
        sha256              = Get-SafeHash $full
    }
}

$SourceRows |
    Sort-Object relative_path |
    Export-Csv -LiteralPath (Join-Path $OutRoot "03_TRACKED_SOURCE_INVENTORY.csv") `
        -NoTypeInformation -Encoding UTF8

# --------------------------------------------------------------------------------------
# 4. CAMPAIGN / REFERENCE ARTIFACT DISCOVERY
# --------------------------------------------------------------------------------------

# Search filenames only.  This intentionally does not extract archives or modify anything.
$CandidatePattern = '(?i)(campaign|CS[_-]?0750|CS[_-]?2500|CS[_-]?25000|source.?plan|' +
                    'checkpoint|report.?catalog|accepted.?reference|golden.?replay|' +
                    'reconcil|R26|G3.?v2|v2[._-]?1[._-]?0|route.?b|performance.?shakedown)'

$SearchRoots = @(
    $Repo,
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Desktop",
    "$env:USERPROFILE\Documents"
) |
Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Container) } |
Select-Object -Unique

$CandidateRows = New-Object System.Collections.Generic.List[object]

foreach ($root in $SearchRoots) {

    try {
        Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $CandidatePattern } |
        ForEach-Object {

            $CandidateRows.Add(
                [pscustomobject]@{
                    search_root         = $root
                    full_path           = $_.FullName
                    name                = $_.Name
                    extension           = $_.Extension.ToLowerInvariant()
                    bytes               = $_.Length
                    last_write_time_utc = $_.LastWriteTimeUtc.ToString("o")
                    sha256              = Get-SafeHash $_.FullName
                }
            )
        }
    }
    catch {
        Add-ErrorLine "Candidate scan failure under $root :: $($_.Exception.Message)"
    }
}

$CandidateRows |
    Sort-Object full_path -Unique |
    Export-Csv -LiteralPath (Join-Path $OutRoot "04_CAMPAIGN_REFERENCE_CANDIDATES.csv") `
        -NoTypeInformation -Encoding UTF8

# --------------------------------------------------------------------------------------
# 5. SEARCH REPOSITORY TEXT FOR KEY CAMPAIGN CONTRACTS
# --------------------------------------------------------------------------------------

$TextExtensions = @(".sql", ".ps1", ".psm1", ".py", ".json", ".csv", ".md", ".txt", ".yaml", ".yml")

$TextFiles = Get-ChildItem -LiteralPath $Repo -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $TextExtensions -contains $_.Extension.ToLowerInvariant() }

$Needles = @(
    "CS_0750_ACCEPTED_FIDELITY",
    "CS_2500_PERFORMANCE_SHAKEDOWN",
    "CS_25000_FULL_CAMPAIGN",
    "module1_run_id",
    "source_plan",
    "SOURCE_PLAN",
    "607",
    "172",
    "58 reporting",
    "accepted-reference",
    "accepted_reference",
    "golden replay",
    "performance shakedown"
)

$HitRows = New-Object System.Collections.Generic.List[object]

foreach ($needle in $Needles) {

    try {
        $hits = $TextFiles |
            Select-String -SimpleMatch -Pattern $needle -ErrorAction SilentlyContinue |
            Select-Object -First 150

        foreach ($hit in $hits) {

            $rel = if ($hit.Path.StartsWith($Repo, [System.StringComparison]::OrdinalIgnoreCase)) {
                $hit.Path.Substring($Repo.Length).TrimStart("\")
            } else {
                $hit.Path
            }

            $HitRows.Add(
                [pscustomobject]@{
                    search_term   = $needle
                    relative_path = $rel
                    line_number   = $hit.LineNumber
                    line          = $hit.Line.Trim()
                }
            )
        }
    }
    catch {
        Add-ErrorLine "Text search '$needle': $($_.Exception.Message)"
    }
}

$HitRows |
    Export-Csv -LiteralPath (Join-Path $OutRoot "05_CAMPAIGN_CONTRACT_TEXT_HITS.csv") `
        -NoTypeInformation -Encoding UTF8

# --------------------------------------------------------------------------------------
# 6. ZIP CONTENT INDEX — NO EXTRACTION
# --------------------------------------------------------------------------------------

$ArchiveRows = New-Object System.Collections.Generic.List[object]

try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
}
catch {
    Add-ErrorLine "Could not load compression assembly: $($_.Exception.Message)"
}

$CandidateZips = $CandidateRows |
    Where-Object { $_.extension -eq ".zip" } |
    Sort-Object full_path -Unique |
    Select-Object -First 50

foreach ($zip in $CandidateZips) {

    try {
        $z = [System.IO.Compression.ZipFile]::OpenRead($zip.full_path)

        foreach ($entry in $z.Entries) {

            $ArchiveRows.Add(
                [pscustomobject]@{
                    archive_path      = $zip.full_path
                    archive_sha256    = $zip.sha256
                    entry_name        = $entry.FullName
                    uncompressed_size = $entry.Length
                    compressed_size   = $entry.CompressedLength
                }
            )
        }

        $z.Dispose()
    }
    catch {
        Add-ErrorLine "ZIP index failure $($zip.full_path): $($_.Exception.Message)"
    }
}

$ArchiveRows |
    Export-Csv -LiteralPath (Join-Path $OutRoot "06_ARCHIVE_INDEX.csv") `
        -NoTypeInformation -Encoding UTF8

# --------------------------------------------------------------------------------------
# 7. POSTGRESQL ENVIRONMENT — INVENTORY ONLY, NO CONNECTION
# --------------------------------------------------------------------------------------

$PgPath = Join-Path $OutRoot "07_POSTGRESQL_ENVIRONMENT.txt"

@"
================================================================================
POSTGRESQL / CLIENT ENVIRONMENT
NO DATABASE CONNECTION IS PERFORMED
================================================================================
"@ | Set-Content -LiteralPath $PgPath -Encoding UTF8

foreach ($cmdName in @("psql", "pg_config", "pg_dump", "pg_restore", "createdb", "dropdb")) {

    Add-Content -LiteralPath $PgPath -Value "`r`n--- COMMAND: $cmdName ---"

    try {
        $cmd = Get-Command $cmdName -ErrorAction SilentlyContinue

        if ($null -eq $cmd) {
            Add-Content -LiteralPath $PgPath -Value "<NOT FOUND>"
        }
        else {
            Add-Content -LiteralPath $PgPath -Value $cmd.Source
        }
    }
    catch {
        Add-ErrorLine "Get-Command $cmdName: $($_.Exception.Message)"
    }
}

foreach ($versionCmd in @("psql", "pg_config", "pg_dump", "pg_restore")) {

    try {
        $cmd = Get-Command $versionCmd -ErrorAction SilentlyContinue

        if ($cmd) {
            Add-Content -LiteralPath $PgPath -Value "`r`n--- VERSION: $versionCmd ---"
            $v = & $cmd.Source --version 2>&1
            Add-Content -LiteralPath $PgPath -Value ($v | Out-String)
        }
    }
    catch {
        Add-ErrorLine "$versionCmd --version: $($_.Exception.Message)"
    }
}

Add-Content -LiteralPath $PgPath -Value "`r`n--- POSTGRESQL WINDOWS SERVICES ---"

try {
    Get-Service -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "(?i)postgres" -or
            $_.DisplayName -match "(?i)postgres"
        } |
        Select-Object Name, DisplayName, Status, StartType |
        Format-Table -AutoSize |
        Out-String |
        Add-Content -LiteralPath $PgPath
}
catch {
    Add-ErrorLine "PostgreSQL service inventory: $($_.Exception.Message)"
}

Add-Content -LiteralPath $PgPath -Value "`r`n--- POSTGRESQL PROCESSES ---"

try {
    Get-Process -Name postgres -ErrorAction SilentlyContinue |
        Select-Object Id, ProcessName, Path |
        Format-Table -AutoSize |
        Out-String |
        Add-Content -LiteralPath $PgPath
}
catch {
    Add-ErrorLine "Postgres process inventory: $($_.Exception.Message)"
}

Add-Content -LiteralPath $PgPath -Value "`r`n--- POSTGRESQL REGISTRY INSTALLATIONS ---"

$RegistryPaths = @(
    "HKLM:\SOFTWARE\PostgreSQL\Installations",
    "HKLM:\SOFTWARE\WOW6432Node\PostgreSQL\Installations"
)

foreach ($reg in $RegistryPaths) {

    if (Test-Path $reg) {

        try {
            Get-ChildItem $reg |
                ForEach-Object {
                    Get-ItemProperty $_.PSPath |
                        Select-Object PSChildName, BaseDirectory, Version, DataDirectory
                } |
                Format-List |
                Out-String |
                Add-Content -LiteralPath $PgPath
        }
        catch {
            Add-ErrorLine "Registry inventory $reg: $($_.Exception.Message)"
        }
    }
}

Add-Content -LiteralPath $PgPath -Value "`r`n--- LISTENING PORTS OF INTEREST ---"

try {
    $ports = Get-NetTCPConnection -State Listen -ErrorAction Stop |
        Where-Object { $_.LocalPort -in @(5432, 55432) } |
        Select-Object LocalAddress, LocalPort, OwningProcess

    if ($ports) {
        $ports |
            Format-Table -AutoSize |
            Out-String |
            Add-Content -LiteralPath $PgPath
    }
    else {
        Add-Content -LiteralPath $PgPath -Value "<NO 5432/55432 LISTENERS OBSERVED>"
    }
}
catch {
    Add-Content -LiteralPath $PgPath -Value "<Get-NetTCPConnection unavailable; netstat follows>"

    try {
        netstat -ano |
            Select-String ":5432|:55432" |
            Out-String |
            Add-Content -LiteralPath $PgPath
    }
    catch {
        Add-ErrorLine "Port inventory failed: $($_.Exception.Message)"
    }
}

# --------------------------------------------------------------------------------------
# 8. DISK / CAPACITY CONTEXT
# --------------------------------------------------------------------------------------

$DiskPath = Join-Path $OutRoot "08_DISK_CAPACITY.txt"

try {
    Get-PSDrive -PSProvider FileSystem |
        Select-Object Name,
            @{N="UsedGB";E={[math]::Round($_.Used / 1GB,2)}},
            @{N="FreeGB";E={[math]::Round($_.Free / 1GB,2)}},
            Root |
        Format-Table -AutoSize |
        Out-String |
        Set-Content -LiteralPath $DiskPath -Encoding UTF8
}
catch {
    Add-ErrorLine "Disk inventory: $($_.Exception.Message)"
}

# --------------------------------------------------------------------------------------
# 9. DISCOVERY SUMMARY / QUICK GATE
# --------------------------------------------------------------------------------------

$TrackedSourceCount = @($SourceRows).Count
$CandidateCount     = @($CandidateRows).Count
$ArchiveEntryCount  = @($ArchiveRows).Count
$ContractHitCount   = @($HitRows).Count

$WorkingTreeLines = @(
    & git -C $Repo status --porcelain=v1 --untracked-files=all 2>$null
)

$Summary = [ordered]@{
    discovery_status = "COLLECTION_COMPLETE"

    repo = $Repo

    publication = [ordered]@{
        expected_tag         = $ExpectedTag
        tag_commit_match     = ($TagCommit -eq $ExpectedCommit)
        tag_tree_match       = ($TagTree -eq $ExpectedTree)
        tag_object_match     = ($TagObject -eq $ExpectedTagObject)
        current_head         = $Head
        head_at_publication  = ($Head -eq $ExpectedCommit)
        working_tree_entries = @($WorkingTreeLines).Count
    }

    inventory = [ordered]@{
        tracked_executable_control_files = $TrackedSourceCount
        campaign_reference_candidates    = $CandidateCount
        indexed_archive_entries          = $ArchiveEntryCount
        campaign_contract_text_hits      = $ContractHitCount
    }

    next_gate = "RETURN_DISCOVERY_ZIP_TO_CHATGPT_FOR_CAMPAIGN_HARNESS_REBASE"
}

$Summary |
    ConvertTo-Json -Depth 8 |
    Set-Content -LiteralPath (Join-Path $OutRoot "09_DISCOVERY_SUMMARY.json") -Encoding UTF8

# --------------------------------------------------------------------------------------
# 10. HASH THE DISCOVERY EVIDENCE ITSELF
# --------------------------------------------------------------------------------------

$EvidenceHashes = Get-ChildItem -LiteralPath $OutRoot -File |
    Sort-Object Name |
    ForEach-Object {
        [pscustomobject]@{
            file   = $_.Name
            bytes  = $_.Length
            sha256 = Get-SafeHash $_.FullName
        }
    }

$EvidenceHashes |
    Export-Csv -LiteralPath (Join-Path $OutRoot "10_EVIDENCE_HASHES.csv") `
        -NoTypeInformation -Encoding UTF8

# Recompute the hash file list once so 10_EVIDENCE_HASHES.csv itself is also visible.
$FinalFileList = Get-ChildItem -LiteralPath $OutRoot -File |
    Sort-Object Name |
    Select-Object Name, Length, LastWriteTimeUtc

$FinalFileList |
    Export-Csv -LiteralPath (Join-Path $OutRoot "11_EVIDENCE_FILE_LIST.csv") `
        -NoTypeInformation -Encoding UTF8

# --------------------------------------------------------------------------------------
# 11. PACKAGE
# --------------------------------------------------------------------------------------

Compress-Archive -Path "$OutRoot\*" -DestinationPath $ZipPath -CompressionLevel Optimal

$ZipHash = (Get-FileHash -LiteralPath $ZipPath -Algorithm SHA256).Hash.ToLowerInvariant()

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "MSBF CAMPAIGN DISCOVERY COMPLETE" -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Evidence folder:"
Write-Host "  $OutRoot"
Write-Host ""
Write-Host "Upload this ZIP to ChatGPT:"
Write-Host "  $ZipPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "ZIP SHA-256:"
Write-Host "  $ZipHash"
Write-Host ""
Write-Host "Publication identity checks:"
Write-Host "  Tag commit match : $($TagCommit -eq $ExpectedCommit)"
Write-Host "  Tag tree match   : $($TagTree -eq $ExpectedTree)"
Write-Host "  Tag object match : $($TagObject -eq $ExpectedTagObject)"
Write-Host "  HEAD publication : $($Head -eq $ExpectedCommit)"
Write-Host ""
Write-Host "Working-tree entries observed: $(@($WorkingTreeLines).Count)"
Write-Host "Tracked source/control files  : $TrackedSourceCount"
Write-Host "Campaign/reference candidates : $CandidateCount"
Write-Host "Archive entries indexed       : $ArchiveEntryCount"
Write-Host "Campaign contract text hits   : $ContractHitCount"
Write-Host ""
Write-Host "NO PostgreSQL connection or SQL execution was performed." -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Cyan
```

### What I need back

Upload **only the resulting**:

`D:\x\MSBF_CAMPAIGN_DISCOVERY_<timestamp>.zip`

You do **not** need to interpret any results, manually inspect the CSVs, or troubleshoot mismatches before sending it.

If the script terminates early, don't start manually correcting things. Send me:

1. the console error, and  
2. the partial `MSBF_CAMPAIGN_DISCOVERY_...` folder/ZIP if one was created.

Once I have the successful package, the next leap is substantial: I will use it to determine the **current source-plan rebase, canonical 750 comparator, profile/config design, execution order, and actual thin harness structure**. The objective is for the following user-facing step to be a bounded campaign package/preflight—not another long discovery sequence.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dfb6b607-230a-4e3b-992f-4f2230a60137"></a>
## Andrew / user · C123-M00185

C123-M00185 · 2026-09-11T19:12:19.382000-04:00 · active path

Preceding visible parent: [C123-M00184](part-17.md#m-058eba7d-3a8d-4385-8164-ab4897645608)

<!-- BEGIN_SOURCE_MESSAGE -->
what do you mean searches for the campaign scale work. is there something i can help find?
<!-- END_SOURCE_MESSAGE -->


<a id="m-199ca603-6876-4d22-904b-31f7ba6b7a17"></a>
## Assistant · C123-M00186

C123-M00186 · 2026-09-11T19:12:21.703574-04:00 · active path

Preceding visible parent: [C123-M00185](part-17.md#m-dfb6b607-230a-4e3b-992f-4f2230a60137)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — and if you know where the old Campaign Scale working artifacts live, that would save us some unnecessary scanning.

When I said the PowerShell collector “searches for the Campaign Scale work,” I meant it is doing a **filename-only inventory** across `D:\x\m`, Downloads, Desktop, and Documents looking for retained artifacts from the earlier workstream. It is not searching the internet or modifying anything.

The handoff you just supplied is the **summary/control handoff**, not necessarily the full executable Campaign Scale package. It tells us that the old work had a 230-position source plan, three scale profiles, 172 checkpoint positions, 58 reporting positions/607 result sets, and a static harness. [export reference: filecite | turn62file0 | L44-L72] What I would ideally recover is the physical implementation behind those descriptions.

The most helpful things for you to locate would be, in priority order:

1. **The main Campaign Scale working folder or ZIP** from the August work — especially the CR-WP5 R5/static-harness package.
2. The three profile/config files for:
   - `CS_0750_ACCEPTED_FIDELITY`
   - `CS_2500_PERFORMANCE_SHAKEDOWN`
   - `CS_25000_FULL_CAMPAIGN`
3. The **ordered source-plan** file representing the old 230 positions.
4. The **checkpoint catalog** and **report/result-set catalog**.
5. Any PowerShell/Python harness files that actually orchestrated the campaign.
6. Any retained **750 reference/output package** that was used or intended for accepted-fidelity comparison.

What I do **not** need you to hunt for manually:
- old screenshots;
- every audit ZIP;
- every cryptographic authority package;
- the withdrawn signer/private-key material;
- old Power BI outputs;
- random Campaign chat exports.

If you know the folder where the Campaign Scale work was physically stored — something like `D:\...campaign...`, an old Downloads ZIP, or a project subfolder — just tell me the path or upload the main ZIP. Then I can narrow the discovery block substantially and avoid recursively scanning all of Documents/Downloads.

The single **most valuable thing** would be the **latest full Campaign Scale source/harness package immediately before the workstream was handed off on August 28**. The summary ZIP you just uploaded is useful for governance, but the executable/static-engineering package underneath it is what would let us move fastest.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7be7564e-b6d1-463a-a3fe-b256bd1d1abf"></a>
## Andrew / user · C123-M00187

C123-M00187 · 2026-09-11T19:26:46.192000-04:00 · active path

Preceding visible parent: [C123-M00186](part-17.md#m-199ca603-6876-4d22-904b-31f7ba6b7a17)

**Editorial record note:** Attachment references: MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1(2).zip; MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1.zip(1).sha256; MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1(5).zip; MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1.zip(6).sha256; MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821(2).zip; MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip(1).sha256

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I can identify this much more precisely now, and you **do not need to let the new chat recursively scan all of Documents/Downloads**.

Your Campaign Scale working root was:

```text
D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000
```

The new chat is really asking for **two different things**: the broad physical Campaign project context, and the latest implementation-focused harness/source package. I would give it both.

| PriorityArtifactWhy it matters                           |                                                                |                                                                                                                                                                                                                                                                                                                                                                                                              |
| -------------------------------------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **1 — Broadest physical Campaign handoff**               | `MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1.zip`        | This is the comprehensive Campaign archive: accepted project context, accepted data-state material, readiness artifacts, three earlier harness releases, M1.17 closure, source/gap/checkpoint material, etc. The original handoff was designed as the comprehensive physical-execution/audit carrier.                                                                                                        |
| **2 — Best latest stable source/harness implementation** | `MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip` | This is what I think the other chat means by the “latest full Campaign Scale source/harness package.” It contains the actual v0.7 adapter harness, all three profiles, source-plan lock, 172 checkpoint definitions/catalog, 58-report catalog, 607-result-set catalog, drivers, modules, and static/native control architecture. R7 independently accepted R5 Correction R2 construction with observations. |
| **3 — Compact strategy-facing Campaign package**         | `MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1.zip`               | Much smaller, but extremely useful for the M1/2 strategy chat because it has the three profile plans, 230-position plan, expected-results artifacts, source inventories, and checkpoint/report specifications without all later trust/custody complexity. It contains 230 resolved normal positions, 3×230 profile plans, 172 checkpoint specs, 58 report specs and 607 result-set entries.                  |

### The files are already recoverable here

You can download them directly rather than hunting your hard drive:

- **Full Campaign Scale execution handoff — 274 MB** (historical reference: `sandbox:[session]/MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1.zip`; referenced bytes not established here)   **(D:\MSBF\_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\ChatGPT\_Interaction\_01\User\_Inputs\MSBF\_CAMPAIGN\_SCALE\_EXECUTION\_HANDOFF\_20260815\_R1.zip)**
- **Latest stable CR-WP5 R5 Correction R2 source/harness — 119 MB** (historical reference: `sandbox:[session]/MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip`; referenced bytes not established here) **(D:\MSBF\_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\MSBF\_CR\_WP5\_R5\_CORRECTION\_R2\_STATIC\_REMEDIATION\_20260821.zip)**
- **CR-WP3 static engineering package — 1.14 MB** (historical reference: `sandbox:[session]/MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1.zip`; referenced bytes not established here) **(D:\MSBF\_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000\ChatGPT\_Interaction\_03\ChatGPT\_Deliverables\MSBF\_CR\_WP3\_STATIC\_ENGINEERING\_20260818\_R1.zip)**

The exact validated identities I have are:

```text
MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1.zip
274,247,837 bytes
SHA-256
04e8caf1a28eeb689d47ca4c8cf22fc16fd7b84f68571ded6f6413a4193e083a

MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip
119,649,265 bytes
SHA-256
8b92cd282d9aedb2006936e7d11229d75baf49c8705ef119b416cbf02702f986

MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1.zip
1,138,614 bytes
SHA-256
59744f1a814c544a84ca1c5d79b32768ba31fce4b2f694ef9338fdaaf46fb778
```

### The R5 package contains exactly what the other chat is asking for

Inside `MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip`, the relevant physical files include:

```text
04_NATIVE_ADAPTER_HARNESS_V0_7/
    profiles/
        CS_0750_ACCEPTED_FIDELITY.json
        CS_0750_ACCEPTED_FIDELITY.lock.json
        CS_2500_PERFORMANCE_SHAKEDOWN.json
        CS_2500_PERFORMANCE_SHAKEDOWN.lock.json
        CS_25000_FULL_CAMPAIGN.json
        CS_25000_FULL_CAMPAIGN.lock.json
        SOURCE_PLAN_LOCK.json

    definitions/
        CHECKPOINT_ADAPTER_CATALOG.csv
        REPORT_ADAPTER_CATALOG.csv
        RESULT_SET_ADAPTER_CATALOG.csv
        R5_CURRENT_ADAPTER_BINDING_CATALOG.csv
        checkpoints/...

    drivers/
        Invoke-MSBFSingleSessionReadOnlyAdapter.ps1
        Invoke-MSBFTrustedAdapterAttempt.ps1
```

So for its priority items **2–5**, this package is almost exactly the answer.

For the more strategy-oriented frozen Campaign configuration, CR-WP3 additionally contains:

```text
03_FROZEN_CR_WP2_INPUTS/04_PROFILES/
    CS_0750_ACCEPTED_FIDELITY.json
    CS_2500_PERFORMANCE_SHAKEDOWN.json
    CS_25000_FULL_CAMPAIGN.json
    PROFILE_MATRIX.csv
    SOURCE_PLAN_LOCK.json

04_STATIC_OVERLAY/PROFILES/<each profile>/
    INVOCATION_PLAN.csv
    EXPECTED_RESULTS_PLAN.csv
    HASH_EXPECTATION_PLAN.csv
    SOURCE_PLAN_PREIMAGE.txt
    STATIC_BINDING.json

05_SOURCE_INVENTORIES/
    NORMAL_SOURCE_PLAN_CANONICAL_PREIMAGE.txt

06_CHECKPOINTS_AND_REPORTS/
    CHECKPOINT_SPECIFICATION_CATALOG.csv
    ...
```

That package is particularly good for the new **M1/2 Strategy Correction** chat because it captures the Campaign-facing expectations before the later cryptographic hardening. The profile plans were all 230 positions and explicitly `NOT_EXECUTED`.

### One correction to the other chat's request: there is no completed new 750 replay package

It should **not waste time searching for a completed “750 accepted-fidelity output package” from this Campaign workstream**. The governed Campaign ladder was 750 → 2,500 → 25,000, but the 750 replay was still pending; no replay under the new harness had been completed.

There may be predecessor/accepted **750-scale reference data** inside the comprehensive Campaign handoff and accepted project/data-state material, but there is no completed Campaign Scale 750 replay artifact to recover. The CR-WP3 package likewise explicitly recorded zero 750/2,500/25,000 runs.

### What I would send the new chat

I would upload **these three ZIPs**, in this order:

1. `MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1.zip`
2. `MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip`
3. `MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1.zip`

Then tell it:

> The first ZIP is the comprehensive predecessor/context carrier. The second is the latest stable independently audited static/no-database CR-WP5 source/harness implementation and should be used to inspect the actual profiles, adapter catalogs, checkpoint/report/result-set architecture, and orchestration code. The third is the compact strategy-facing Campaign static-engineering package containing the frozen profile/source-plan/expected-results structure. Do not infer that a 750 replay was completed; it was not. Use these artifacts to preserve downstream contracts while correcting and republishing Module 1/2 strategy, and expect Campaign source identities to be rebased after the corrected M1/M2 release.

I would **not** give the new strategy chat the later authority-rotation, custody-failure, signer, or activation packages unless it specifically needs them. They are downstream execution governance and would add noise to the business-strategy remediation you are trying to do.
<!-- END_SOURCE_MESSAGE -->


<a id="m-aa89fbf7-03c7-44b8-a83f-5206b110f428"></a>
## Assistant · C123-M00188

C123-M00188 · 2026-09-11T19:28:28.658038-04:00 · active path

Preceding visible parent: [C123-M00187](part-17.md#m-7be7564e-b6d1-463a-a3fe-b256bd1d1abf)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. This is exactly what I needed, and it materially reduces the discovery work.

I have inspected the three uploaded packages and independently verified all three ZIPs against the SHA-256 values you supplied:

```text
MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1.zip
04e8caf1a28eeb689d47ca4c8cf22fc16fd7b84f68571ded6f6413a4193e083a   PASS

MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip
8b92cd282d9aedb2006936e7d11229d75baf49c8705ef119b416cbf02702f986   PASS

MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1.zip
59744f1a814c544a84ca1c5d79b32768ba31fce4b2f694ef9338fdaaf46fb778   PASS
```

I also confirmed the important physical pieces are genuinely there: the WP3 package has the **230-position ordered execution plan, 172 checkpoint rows, 58 reporting rows, all three scale profiles, expected-results formulas and source mappings**; the R5 package contains the v0.7 profiles, adapter catalogs, **607-result-set architecture**, drivers and associated static harness. That matches the handoff's description of the reusable architecture. [export reference: filecite | turn62file0 | L44-L72]

There is one especially useful finding from inspecting the actual files: the old `CS_0750_ACCEPTED_FIDELITY` profile still carries **pre-correction predecessor expectations**, including `pricing_candidate_rows = 557` and `operational_account_rows = 59`. That confirms our earlier reasoning: **the old 750 profile is the configuration template, but its old business-result expectations cannot be our new zero-difference oracle.** We need to rebase those expectations to the accepted R26/v2.1.0 result.

And we know exactly what the strongest current reference is. The later publication runbook identifies the accepted result:

```text
msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS.zip
```

and the accepted-reference process reconciled it at **90/90 PASS**; the later isolated replay also produced a fresh result that independently reconciled 90/90. [export reference: filecite | turn65file0 | L32-L47] [export reference: filecite | turn65file7 | L359-L371]

So: **do not run the broad discovery script I gave you earlier.** We no longer need to crawl Downloads/Documents.

## What I need now

Only a very targeted machine snapshot:

1. exact current `D:\x\m` Git/publication state;
2. confirmation that the three predecessor packages at the archive root still match what you uploaded;
3. whether the accepted R26 golden result/runtime artifacts are still on your machine;
4. PostgreSQL 17/client/service/port state;
5. enough current source inventory to perform the old→v2.1.0 source-plan mapping.

Run this single read-only PowerShell block. It **does not connect to PostgreSQL or modify anything in the repo**.

```powershell
# =====================================================================================
# MSBF CAMPAIGN — TARGETED REBASE DISCOVERY
# Read-only. No PostgreSQL connection. No SQL execution. No Git mutation.
# =====================================================================================

$ErrorActionPreference = "Stop"
$env:GIT_OPTIONAL_LOCKS = "0"

$Repo = "D:\x\m"
$ArchiveRoot = "D:\MSBF_ARCHIVE\MSBF - Campaign Scale 750 - 2,500 - 25,000"

$ExpectedTag       = "module-2-g3-v2.1.0"
$ExpectedCommit    = "fd9f67b6d1d7fc848d315bcb696487b82c9a8046"
$ExpectedTree      = "fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb"
$ExpectedTagObject = "cdef0c49eb37d0cc72444c0829c253e09eee050a"

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$Out = "D:\x\MSBF_CAMPAIGN_TARGETED_DISCOVERY_$Stamp"
$Zip = "$Out.zip"

New-Item -ItemType Directory -Path $Out -Force | Out-Null

function HashFile($Path) {
    if (Test-Path -LiteralPath $Path -PathType Leaf) {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    return "<NOT_FOUND>"
}

function SaveText($Name, $Value) {
    $Value | Out-String | Set-Content -LiteralPath (Join-Path $Out $Name) -Encoding UTF8
}

# -------------------------------------------------------------------
# A. CURRENT PUBLICATION / GIT STATE
# -------------------------------------------------------------------

$Head      = (& git -C $Repo rev-parse HEAD).Trim()
$HeadTree  = (& git -C $Repo rev-parse 'HEAD^{tree}').Trim()
$TagObject = (& git -C $Repo rev-parse "refs/tags/$ExpectedTag").Trim()
$TagCommit = (& git -C $Repo rev-parse "$ExpectedTag^{}").Trim()
$TagTree   = (& git -C $Repo rev-parse "$ExpectedTag^{}^{tree}").Trim()

[ordered]@{
    repo                  = $Repo
    expected_tag          = $ExpectedTag
    expected_commit       = $ExpectedCommit
    expected_tree         = $ExpectedTree
    expected_tag_object   = $ExpectedTagObject
    current_head          = $Head
    current_head_tree     = $HeadTree
    observed_tag_object   = $TagObject
    observed_tag_commit   = $TagCommit
    observed_tag_tree     = $TagTree
    tag_object_match      = ($TagObject -eq $ExpectedTagObject)
    tag_commit_match      = ($TagCommit -eq $ExpectedCommit)
    tag_tree_match        = ($TagTree -eq $ExpectedTree)
    head_at_publication   = ($Head -eq $ExpectedCommit)
} |
ConvertTo-Json -Depth 5 |
Set-Content -LiteralPath "$Out\01_PUBLICATION_IDENTITY.json" -Encoding UTF8

@(
    "=== STATUS ==="
    (& git -C $Repo status --porcelain=v1 --untracked-files=all)
    ""
    "=== BRANCH ==="
    (& git -C $Repo branch --show-current)
    ""
    "=== REMOTES ==="
    (& git -C $Repo remote -v)
    ""
    "=== RECENT COMMITS ==="
    (& git -C $Repo log -n 10 --decorate --oneline)
    ""
    "=== TAGS AT HEAD ==="
    (& git -C $Repo tag --points-at HEAD)
) | Set-Content "$Out\02_GIT_STATE.txt" -Encoding UTF8

# -------------------------------------------------------------------
# B. CURRENT TRACKED CAMPAIGN-RELEVANT SOURCE INVENTORY
# -------------------------------------------------------------------

$AllowedExt = @(".sql",".ps1",".psm1",".py",".json",".csv",".yaml",".yml",".toml")

$Rows = foreach ($Rel in (& git -C $Repo ls-files)) {

    $Full = Join-Path $Repo $Rel
    if (-not (Test-Path -LiteralPath $Full -PathType Leaf)) { continue }

    $Ext = [IO.Path]::GetExtension($Full).ToLowerInvariant()
    if ($AllowedExt -notcontains $Ext) { continue }

    $F = Get-Item -LiteralPath $Full

    [pscustomobject]@{
        relative_path = $Rel
        extension     = $Ext
        bytes         = $F.Length
        sha256        = HashFile $Full
    }
}

$Rows |
Sort-Object relative_path |
Export-Csv "$Out\03_CURRENT_SOURCE_INVENTORY.csv" -NoTypeInformation -Encoding UTF8

# -------------------------------------------------------------------
# C. VERIFY THE THREE KNOWN CAMPAIGN PACKAGES ON DISK
# -------------------------------------------------------------------

$Known = @(
    [pscustomobject]@{
        name="Campaign execution handoff"
        expected_sha256="04e8caf1a28eeb689d47ca4c8cf22fc16fd7b84f68571ded6f6413a4193e083a"
        path="$ArchiveRoot\ChatGPT_Interaction_01\User_Inputs\MSBF_CAMPAIGN_SCALE_EXECUTION_HANDOFF_20260815_R1.zip"
    },
    [pscustomobject]@{
        name="R5 Correction R2 harness"
        expected_sha256="8b92cd282d9aedb2006936e7d11229d75baf49c8705ef119b416cbf02702f986"
        path="$ArchiveRoot\MSBF_CR_WP5_R5_CORRECTION_R2_STATIC_REMEDIATION_20260821.zip"
    },
    [pscustomobject]@{
        name="WP3 static engineering"
        expected_sha256="59744f1a814c544a84ca1c5d79b32768ba31fce4b2f694ef9338fdaaf46fb778"
        path="$ArchiveRoot\ChatGPT_Interaction_03\ChatGPT_Deliverables\MSBF_CR_WP3_STATIC_ENGINEERING_20260818_R1.zip"
    }
)

$KnownResults = foreach ($K in $Known) {
    $Observed = HashFile $K.path
    [pscustomobject]@{
        name            = $K.name
        path            = $K.path
        exists          = (Test-Path -LiteralPath $K.path -PathType Leaf)
        expected_sha256 = $K.expected_sha256
        observed_sha256 = $Observed
        match           = ($Observed -eq $K.expected_sha256)
    }
}

$KnownResults |
Export-Csv "$Out\04_KNOWN_CAMPAIGN_PACKAGE_BINDING.csv" -NoTypeInformation -Encoding UTF8

# -------------------------------------------------------------------
# D. LOCATE ONLY THE CURRENT R26 REFERENCE/RUNTIME ARTIFACTS
#    Search is intentionally limited to known MSBF roots.
# -------------------------------------------------------------------

$Roots = @(
    "C:\MSBF",
    $ArchiveRoot,
    "D:\x"
) | Where-Object { Test-Path -LiteralPath $_ -PathType Container }

$ExactNames = @(
    "msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS.zip",
    "MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip"
)

$Found = New-Object System.Collections.Generic.List[object]

foreach ($Root in $Roots) {

    foreach ($Name in $ExactNames) {

        Get-ChildItem -LiteralPath $Root -Recurse -File -Filter $Name `
            -ErrorAction SilentlyContinue |
        ForEach-Object {
            $Found.Add([pscustomobject]@{
                category       = "EXACT_R26_ARTIFACT"
                root           = $Root
                name           = $_.Name
                path           = $_.FullName
                bytes          = $_.Length
                sha256         = HashFile $_.FullName
                last_write_utc = $_.LastWriteTimeUtc.ToString("o")
            })
        }
    }

    # Only likely retained checkpoint / replay files — not a general filesystem scan.
    Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.Name -match '(?i)(r26|g3v2|m2_11|m2_12|checkpoint|portable)' -and
        $_.Extension -match '(?i)\.(zip|backup|dump|tar)$'
    } |
    Select-Object -First 200 |
    ForEach-Object {
        $Found.Add([pscustomobject]@{
            category       = "RELATED_REPLAY_CANDIDATE"
            root           = $Root
            name           = $_.Name
            path           = $_.FullName
            bytes          = $_.Length
            sha256         = HashFile $_.FullName
            last_write_utc = $_.LastWriteTimeUtc.ToString("o")
        })
    }
}

$Found |
Sort-Object path -Unique |
Export-Csv "$Out\05_R26_REFERENCE_AND_CHECKPOINT_FILES.csv" `
    -NoTypeInformation -Encoding UTF8

# -------------------------------------------------------------------
# E. POSTGRESQL ENVIRONMENT — NO CONNECTION
# -------------------------------------------------------------------

$Pg = New-Object System.Collections.Generic.List[string]

foreach ($Name in @("psql","pg_config","pg_dump","pg_restore","createdb","dropdb")) {

    $Cmd = Get-Command $Name -ErrorAction SilentlyContinue

    if ($Cmd) {
        $Pg.Add("COMMAND $Name = $($Cmd.Source)")
        if ($Name -in @("psql","pg_config","pg_dump","pg_restore")) {
            try {
                $Pg.Add("VERSION $Name = $((& $Cmd.Source --version 2>&1) -join ' ')")
            } catch {}
        }
    } else {
        $Pg.Add("COMMAND $Name = <NOT FOUND>")
    }
}

$Pg.Add("")
$Pg.Add("=== POSTGRESQL SERVICES ===")

Get-Service -ErrorAction SilentlyContinue |
Where-Object {
    $_.Name -match "(?i)postgres" -or $_.DisplayName -match "(?i)postgres"
} |
ForEach-Object {
    $Pg.Add("$($_.Name) | $($_.Status) | $($_.DisplayName)")
}

$Pg.Add("")
$Pg.Add("=== LISTENERS 5432 / 55432 ===")

try {
    Get-NetTCPConnection -State Listen -ErrorAction Stop |
    Where-Object { $_.LocalPort -in @(5432,55432) } |
    ForEach-Object {
        $Pg.Add("$($_.LocalAddress):$($_.LocalPort) PID=$($_.OwningProcess)")
    }
}
catch {
    $Pg.Add((netstat -ano | Select-String ":5432|:55432" | Out-String))
}

$Pg | Set-Content "$Out\06_POSTGRESQL_ENVIRONMENT.txt" -Encoding UTF8

# -------------------------------------------------------------------
# F. DISK CAPACITY
# -------------------------------------------------------------------

Get-PSDrive -PSProvider FileSystem |
Select-Object Name,
    @{N="UsedGB";E={[math]::Round($_.Used/1GB,2)}},
    @{N="FreeGB";E={[math]::Round($_.Free/1GB,2)}},
    Root |
Export-Csv "$Out\07_DISK_CAPACITY.csv" -NoTypeInformation -Encoding UTF8

# -------------------------------------------------------------------
# G. HASH EVIDENCE + PACKAGE
# -------------------------------------------------------------------

Get-ChildItem $Out -File |
Sort-Object Name |
ForEach-Object {
    [pscustomobject]@{
        file   = $_.Name
        bytes  = $_.Length
        sha256 = HashFile $_.FullName
    }
} |
Export-Csv "$Out\08_EVIDENCE_HASHES.csv" -NoTypeInformation -Encoding UTF8

Compress-Archive -Path "$Out\*" -DestinationPath $Zip -CompressionLevel Optimal

$ZipHash = HashFile $Zip

Write-Host ""
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "MSBF TARGETED CAMPAIGN DISCOVERY COMPLETE" -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Cyan
Write-Host "Upload:"
Write-Host "  $Zip" -ForegroundColor Yellow
Write-Host ""
Write-Host "SHA-256:"
Write-Host "  $ZipHash"
Write-Host ""
Write-Host "Tag commit match : $($TagCommit -eq $ExpectedCommit)"
Write-Host "Tag tree match   : $($TagTree -eq $ExpectedTree)"
Write-Host "Tag object match : $($TagObject -eq $ExpectedTagObject)"
Write-Host "HEAD publication : $($Head -eq $ExpectedCommit)"
Write-Host ""
Write-Host "Exact R26/reference candidates found: $(@($Found | Where-Object category -eq 'EXACT_R26_ARTIFACT').Count)"
Write-Host ""
Write-Host "NO PostgreSQL connection or SQL execution was performed." -ForegroundColor Green
Write-Host "==============================================================" -ForegroundColor Cyan
```

### Why this is now enough

The predecessor architecture is no longer an unknown. We have the actual old implementation, not merely a summary. And the later publication evidence gives us a known current R26 accepted-result/reconciliation mechanism. The current accepted result was explicitly used as the golden input for the 90/90 reference reconciliation. [export reference: filecite | turn65file0 | L32-L47]

What remains is simply to answer:

> **How do the old 230 Campaign positions map to the current published v2.1.0 source tree, and where is the current 750 accepted-reference evidence physically located on your machine?**

Upload the resulting `MSBF_CAMPAIGN_TARGETED_DISCOVERY_*.zip`.

After that, I do **not** expect another discovery round. I should be able to move directly into constructing the rebased harness and the **750 zero-difference gate → 2,500 fresh-campaign execution path**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e6eb4b1f-eddd-4831-8f37-ed7438178b33"></a>
## Andrew / user · C123-M00189

C123-M00189 · 2026-09-11T19:31:19.835000-04:00 · active path

Preceding visible parent: [C123-M00188](part-17.md#m-aa89fbf7-03c7-44b8-a83f-5206b110f428)

<!-- BEGIN_SOURCE_MESSAGE -->
are you trying to search for this or do you need assistance locating this: whether the accepted R26 golden result/runtime artifacts are still on your machine;  
<!-- END_SOURCE_MESSAGE -->


<a id="m-52d1d80f-1057-4300-9a25-18e163bced7e"></a>
## Assistant · C123-M00190

C123-M00190 · 2026-09-11T19:31:21.725802-04:00 · active path

Preceding visible parent: [C123-M00189](part-17.md#m-e6eb4b1f-eddd-4831-8f37-ed7438178b33)

<!-- BEGIN_SOURCE_MESSAGE -->
I was planning to have the targeted PowerShell block **search your known MSBF folders for them**, but if you can locate them directly, that is better and faster.

The two exact artifacts I am looking for are:

- `msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS.zip`
- `MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip`

The first is the accepted R26 golden-result package used for the 90/90 reference reconciliation; the second is the retained runtime package used for offline reproduction. [export reference: filecite | turn65file0 | L24-L47]

If you can identify their paths—or upload them here—we can remove that search entirely from the discovery script.

Helpful but secondary, if easy to locate, would be the retained Route-B portable checkpoint/backup carriers used for the isolated M2.11/M2.12/G3-v2 replay. Those are not required just to identify the golden reference, but they may help later when we design the isolated 750 execution path. [export reference: filecite | turn65file7 | L343-L371]

So yes: **assistance locating those exact R26 artifacts would save time.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-90f72a69-ccac-4590-b390-50143be77c63"></a>
## Andrew / user · C123-M00191

C123-M00191 · 2026-09-11T19:37:14.533000-04:00 · active path

Preceding visible parent: [C123-M00190](part-17.md#m-52d1d80f-1057-4300-9a25-18e163bced7e)

**Editorial record note:** Attachment references: msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS(1).zip; msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS.zip(1).sha256; MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902(2).zip; MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip(2).sha256

<!-- BEGIN_SOURCE_MESSAGE -->
these are both at D:\MSBF_ARCHIVE   what do you mean by: what files specifically: Helpful but secondary, if easy to locate, would be the retained Route-B portable checkpoint/backup carriers used for the isolated M2.11/M2.12/G3-v2 replay. Those are not required just to identify the golden reference, but they may help later when we design the isolated 750 execution path.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-cd1dc189-920d-4603-b3ba-d33a040bf4b6"></a>
## Assistant · C123-M00192

C123-M00192 · 2026-09-11T19:38:19.975236-04:00 · active path

Preceding visible parent: [C123-M00191](part-17.md#m-90f72a69-ccac-4590-b390-50143be77c63)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — I can be specific now.

You have already supplied the two primary R26 artifacts I needed, and I verified both against their sidecars:

- `msbf_r1_r26_resume_20260902_070655_M2_11_M2_12_G3V2_RESULTS.zip`
  - 6,386,878 bytes
  - SHA-256 `113450c7167c8a5e1b40497c4e39506d276aa0e057bbeb3f316561af5d4096c3`
- `MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip`
  - 39,382,961 bytes
  - SHA-256 `b17d0292180adf2bf49725be63b6c12f297d4ff64e0eba52c648045884497746`

So we can remove that entire search from the discovery step.

The **secondary Route-B files** I meant are these two exact PostgreSQL custom-format backups:

```text
msbf_r1_m2_4_r6_20260830_030634.backup
msbf_r1_r26_g3v2_20260902_024119.backup
```

They were created during the Route-B qualification as the portable carriers for:

- the **R6 source checkpoint**: `msbf_r1_m2_4_r6_20260830_030634`
- the **R26 R2 retained checkpoint**: `msbf_r1_r26_g3v2_20260902_024119`

The retained Phase 1 receipt records their original paths as:

```text
D:\MSBF_PUBRUN001_ROUTE_B_QUAL_20260909_R1\phase1_checkpoint_carriers\
    msbf_r1_m2_4_r6_20260830_030634.backup

D:\MSBF_PUBRUN001_ROUTE_B_QUAL_20260909_R1\phase1_checkpoint_carriers\
    msbf_r1_r26_g3v2_20260902_024119.backup
```

with these identities:

```text
msbf_r1_m2_4_r6_20260830_030634.backup
152,130,757 bytes
SHA-256
e1523bd4603cdec111a13d568451563254b8176f44dc9263cfa7a9e7fce62531

msbf_r1_r26_g3v2_20260902_024119.backup
154,727,612 bytes
SHA-256
105426f0cbaf9568a4cfc3b67ea9e13fdc85a0f271195a2c972d8ecdde1a4e0e
```

Both were `pg_dump` custom-format carriers created with `-Fc -C --no-owner --no-privileges`. [export reference: filecite | turn66file1 | L51-L75]

These are **helpful, not mandatory** for the new campaign harness.

Why they help: they give us a proven isolated-restore pattern and an exact checkpoint state from the publication qualification. The Route-B audit confirms that those two portable carriers were used as prerequisites for the isolated M2.11/M2.12/G3-v2 replay. [export reference: filecite | turn66file0 | L11-L39]

Why they are not required: our new 750 campaign goal is broader — we want to rerun the full accepted 750 path and reconcile to zero semantic changes, not merely replay the retained-final M2.11/M2.12 tail.

So if those two `.backup` files are easy to find, please tell me where they are or upload them. If they are not easy to find, **do not spend much time hunting**. We already have the more important golden result and retained runtime.
<!-- END_SOURCE_MESSAGE -->


<a id="m-45fbdcbd-b80c-4ff8-b535-5d81e37c7284"></a>
## Andrew / user · C123-M00193

C123-M00193 · 2026-09-11T19:40:59.895000-04:00 · active path

Preceding visible parent: [C123-M00192](part-17.md#m-cd1dc189-920d-4603-b3ba-d33a040bf4b6)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 0138ae50-7073-4888-8b1b-9b8ace216c0b.png; msbf_r1_m2_4_r6_20260830_030634.backup; msbf_r1_r26_g3v2_20260902_024119.backup

<!-- BEGIN_SOURCE_MESSAGE -->
those D paths you created are all still there and intact: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-c719d30a-bd11-41e8-a893-34cd17b68bcf"></a>
## Assistant · C123-M00194

C123-M00194 · 2026-09-11T19:41:16.917430-04:00 · active path

Preceding visible parent: [C123-M00193](part-17.md#m-45fbdcbd-b80c-4ff8-b535-5d81e37c7284)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. That closes the remaining artifact-location question.

I verified the two uploaded Route-B backup carriers against the retained Phase 1 receipt:

- `msbf_r1_m2_4_r6_20260830_030634.backup`
  - 152,130,757 bytes
  - SHA-256 `e1523bd4603cdec111a13d568451563254b8176f44dc9263cfa7a9e7fce62531`
  - **MATCH**

- `msbf_r1_r26_g3v2_20260902_024119.backup`
  - 154,727,612 bytes
  - SHA-256 `105426f0cbaf9568a4cfc3b67ea9e13fdc85a0f271195a2c972d8ecdde1a4e0e`
  - **MATCH**

Those are exactly the two portable checkpoint carriers recorded for the qualified Route-B replay. [export reference: filecite | turn66file1 | L62-L75]

And the screenshot confirms the broader September 9–10 publication/release working directories are still intact, including the Route-B qualification and follow-on comparator/harness-continuation folders. That is useful because it means we should **stop searching for historical execution evidence entirely**.

At this point, I have enough historical material to proceed with the campaign-harness rebase. The only current-machine facts I still need are:

- current `D:\x\m` Git/tag/tree state;
- current tracked source inventory for mapping the old 230-position plan to v2.1.0;
- PostgreSQL/client/service/port state;
- free disk capacity.

So I can now simplify the prior discovery script further. We no longer need it to search for:

- the three Campaign packages;
- the R26 golden result;
- the R26 retained runtime;
- either Route-B backup;
- the old publication qualification directories.

The next collector can be a **very small current-state-only preflight**. After that, I should be able to build the rebased 750→2,500 harness rather than ask you to locate more historical files.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bdb4f004-a5c0-409b-911d-7469b47d85d1"></a>
## Andrew / user · C123-M00195

C123-M00195 · 2026-09-11T19:42:19.469000-04:00 · active path

Preceding visible parent: [C123-M00194](part-17.md#m-c719d30a-bd11-41e8-a893-34cd17b68bcf)

<!-- BEGIN_SOURCE_MESSAGE -->
produce the current-state-only preflight. we will use D drive. It has 16TB free.
<!-- END_SOURCE_MESSAGE -->
