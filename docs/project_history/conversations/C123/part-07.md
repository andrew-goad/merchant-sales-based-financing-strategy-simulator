# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 07 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-06.md)
[Next part](part-08.md)

<a id="m-06faa778-65ed-4f88-8417-1a5241239bda"></a>
## Assistant · C123-M00068

C123-M00068 · 2026-09-10T08:35:28.248362-04:00 · active path

Preceding visible parent: [C123-M00067](part-06.md#m-e50ef3ae-2eff-46e2-a02c-6f67d3b3b994)

<!-- BEGIN_SOURCE_MESSAGE -->
Phase E did exactly what we wanted a fail-closed gate to do: **nothing crossed the mutation boundary**. `HEAD` is still `46fb1f9...`, nothing is staged, and no commit, tag, push, or publication occurred. Most importantly, the fundamental R6 materialization control remains perfect: **2,884 vs. 2,884 files, with zero missing, extra, or mismatched objects**. [export reference: filecite | turn25file0 | L9-L17] [export reference: filecite | turn25file0 | L75-L79]

I would **not remediate the repository yet**. The six failures are not six demonstrated publication defects. Several are already identifiable as **Phase-E validator design/targeting defects**, and changing the accepted R6 tree in response would be the wrong control action.

The strongest example is `RELATIVE_MARKDOWN_LINKS`. I inspected the supplied 28 findings. Every finding is from only two frozen historical ChatGPT transcripts, and the alleged “links” are things such as `:WriteAllText(`, `:new($false)`, `:GetCurrent().Name`, and `:Escape($oldDataJson)`. Those are PowerShell/.NET expressions inside archived conversation text, not Markdown hyperlinks. The regex scanner is parsing code as Markdown. This failure should be reclassified as a **scanner false positive**, not repaired by altering frozen history.

`GIT_DIFF_CHECK` has a similar issue. The supplied evidence begins with repeated findings such as `MANIFEST.csv:5: trailing whitespace`, immediately followed by governed manifest records. [export reference: filecite | turn25file2 | L1-L18] The pattern then repeats across accepted Module 0, Module 1, Module 2, documentation, Power BI, history, and other R6 records. This is materially different from finding 8,658 independent code-quality defects. We need to determine whether it is generated-manifest formatting already embedded in accepted R6 versus genuine new whitespace damage. Because the checkout is byte-for-byte equal to R6, **we must not run whitespace cleanup against these files** unless the governing release itself is intentionally regenerated.

The R22 result also looks like an overbroad derivation rule. The script was supposed to identify the exact eleven R22-excluded objects, but instead derived 16 strings and then found five of those strings actually present. [export reference: filecite | turn25file0 | L30-L31] Given that R6 explicitly contains public R22 adjudication/control artifacts—including `R22_DESKTOP_EVIDENCE_FINAL_ADJUDICATION` and R22 Power BI evidence—the heuristic's inclusion of any path-like string occurring under a JSON branch containing words like `private`, `exclude`, or `r22` is not authoritative enough. The untracked inventory itself confirms that R22 adjudication artifacts are intentionally part of the candidate tree. [export reference: filecite | turn25file3 | L722-L727]

Likewise, the `STALE_LOCAL_TEMP_SESSION_LINKS = 74` result is suspect because the scanner scanned **all Markdown**, including frozen project-history transcripts. Historical execution conversations will legitimately contain `D:\...`, `[session]/`, session/temp paths, localhost references, etc. Those become defects only if they occur in a **current navigational/publication link surface**, not merely as historical evidence. And `FORBIDDEN_PRIVATE_RAW_CARRIERS = 6` cannot yet be adjudicated from the files you supplied because the actual six matched paths were not included.

So the correct next action is **Phase E1 — bounded failure triage**, read-only. It will not touch R6. It will extract exactly what caused each failed gate and distinguish current publication surfaces from frozen evidence/history.

Run this in the **same PowerShell**:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    # ============================================================
    # MSBF PHASE E1 — FAILED-GATE FORENSIC TRIAGE
    # READ ONLY. NO REPOSITORY MUTATION.
    # ============================================================

    $Repo = 'D:\x\m'
    $PhaseE = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_20260910T123054197Z_3a252164'

    $ExpectedHead = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)

    $Out = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E1_${Stamp}_${Suffix}"
    New-Item -ItemType Directory -Path $Out -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE E1 — FAILED-GATE FORENSIC TRIAGE"
    Write-Host "============================================================"
    Write-Host "Repository: $Repo"
    Write-Host "Phase E:    $PhaseE"
    Write-Host "Evidence:   $Out"
    Write-Host ""

    $HeadBefore = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $CachedBefore = @(& git -C $Repo diff --cached --name-only)

    if ($HeadBefore -cne $ExpectedHead) {
        throw "HEAD changed before E1. Expected $ExpectedHead, found $HeadBefore"
    }

    if ($CachedBefore.Count -ne 0) {
        throw "Index is no longer empty. Stop."
    }

    # ------------------------------------------------------------
    # 1. Copy exact failed-check evidence produced by Phase E
    # ------------------------------------------------------------

    $EvidenceNames = @(
        'R22_DERIVED_EXCLUDED_PATHS.txt',
        'R22_EXCLUDED_PATHS_PRESENT.txt',
        'FORBIDDEN_NAMED_CARRIERS.txt',
        'BROKEN_RELATIVE_MARKDOWN_LINKS.csv',
        'STALE_LOCAL_LINK_FINDINGS.csv',
        'GIT_DIFF_CHECK.txt',
        'PHASE_E_CHECK_REGISTER.csv',
        'MSBF_PHASE_E_PRE_COMMIT_GATE.json'
    )

    foreach ($name in $EvidenceNames) {
        $src = Join-Path $PhaseE $name

        if (Test-Path -LiteralPath $src -PathType Leaf) {
            Copy-Item -LiteralPath $src -Destination (Join-Path $Out $name)
        }
        else {
            "MISSING: $name" |
                Add-Content -LiteralPath (Join-Path $Out 'MISSING_PHASE_E_EVIDENCE.txt')
        }
    }

    # ------------------------------------------------------------
    # 2. R22 — show exactly what heuristic derived
    # ------------------------------------------------------------

    $derivedPath = Join-Path $PhaseE 'R22_DERIVED_EXCLUDED_PATHS.txt'
    $presentPath = Join-Path $PhaseE 'R22_EXCLUDED_PATHS_PRESENT.txt'

    $derived = @()
    $present = @()

    if (Test-Path -LiteralPath $derivedPath) {
        $derived = @(
            Get-Content -LiteralPath $derivedPath |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    if (Test-Path -LiteralPath $presentPath) {
        $present = @(
            Get-Content -LiteralPath $presentPath |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    }

    $r22Rows = foreach ($p in $derived) {
        [pscustomobject]@{
            DerivedPath = $p
            PresentInRepository = ($p -in $present)
            ExistsPhysical = Test-Path -LiteralPath (Join-Path $Repo $p)
        }
    }

    $r22Rows |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'R22_HEURISTIC_TRIAGE.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # Dump exclusion-related structure from controlling provenance,
    # without attempting to reinterpret it.
    $Prov = Join-Path $Repo `
        'docs\release_integration\module_2_g3_v2_1\R18_PUBLIC_PROJECTION_PROVENANCE.json'

    if (Test-Path -LiteralPath $Prov) {
        $json = Get-Content -LiteralPath $Prov -Raw | ConvertFrom-Json

        function Walk-Node {
            param(
                $Node,
                [string]$Path = '$'
            )

            if ($null -eq $Node) { return }

            if ($Node -is [string] -or
                $Node -is [ValueType]) {

                if (
                    $Path -match '(?i)(exclude|private|omit|r22|public)' -or
                    "$Node" -match '(?i)(exclude|private|omit|r22)'
                ) {
                    [pscustomobject]@{
                        JsonPath = $Path
                        Value = "$Node"
                    }
                }

                return
            }

            if (
                $Node -is [System.Collections.IEnumerable] -and
                -not ($Node -is [System.Management.Automation.PSCustomObject])
            ) {
                $i = 0
                foreach ($item in $Node) {
                    Walk-Node -Node $item -Path "$Path[$i]"
                    $i++
                }
                return
            }

            foreach ($prop in $Node.PSObject.Properties) {
                Walk-Node `
                    -Node $prop.Value `
                    -Path "$Path.$($prop.Name)"
            }
        }

        @(Walk-Node -Node $json) |
            Export-Csv `
                -LiteralPath (Join-Path $Out 'R18_PROVENANCE_BOUNDARY_ROWS.csv') `
                -NoTypeInformation `
                -Encoding UTF8
    }

    # ------------------------------------------------------------
    # 3. Forbidden-carrier results — exact six
    # ------------------------------------------------------------

    $forbidden = Join-Path $PhaseE 'FORBIDDEN_NAMED_CARRIERS.txt'

    if (Test-Path -LiteralPath $forbidden) {
        $forbiddenRows = foreach ($p in Get-Content -LiteralPath $forbidden) {
            if ([string]::IsNullOrWhiteSpace($p)) { continue }

            $classification =
                if ($p -match '(?i)\\docs\\project_history\\') {
                    'FROZEN_PROJECT_HISTORY'
                }
                elseif ($p -match '(?i)\\docs\\release_integration\\') {
                    'PUBLIC_RELEASE_INTEGRATION_CONTROL'
                }
                elseif ($p -match '(?i)\\docs\\reproducibility\\') {
                    'PUBLIC_REPRODUCIBILITY_CONTROL'
                }
                elseif ($p -match '(?i)\\successor_candidates\\') {
                    'SUCCESSOR_CANDIDATE'
                }
                else {
                    'OTHER_CURRENT_SURFACE'
                }

            [pscustomobject]@{
                FullPath = $p
                Classification = $classification
                Exists = Test-Path -LiteralPath $p
            }
        }

        $forbiddenRows |
            Export-Csv `
                -LiteralPath (Join-Path $Out 'FORBIDDEN_CARRIER_TRIAGE.csv') `
                -NoTypeInformation `
                -Encoding UTF8
    }

    # ------------------------------------------------------------
    # 4. Broken Markdown links — classify by source surface
    # ------------------------------------------------------------

    $brokenFile = Join-Path $PhaseE 'BROKEN_RELATIVE_MARKDOWN_LINKS.csv'

    if (Test-Path -LiteralPath $brokenFile) {
        $broken = Import-Csv -LiteralPath $brokenFile

        $classifiedBroken = foreach ($row in $broken) {
            $surface =
                if ($row.MarkdownFile -match '(?i)^docs\\project_history\\.*\\conversations\\') {
                    'FROZEN_CONVERSATION_TRANSCRIPT'
                }
                elseif ($row.MarkdownFile -match '(?i)^docs\\project_history\\') {
                    'PROJECT_HISTORY_CONTROL'
                }
                else {
                    'CURRENT_PUBLICATION_SURFACE'
                }

            $looksLikeCode =
                (
                    $row.Target -match '^:' -or
                    $row.Target -match '^\$' -or
                    $row.Target -match '\(' -or
                    $row.Target -match '::' -or
                    $row.Target -eq '='
                )

            [pscustomobject]@{
                MarkdownFile = $row.MarkdownFile
                Target = $row.Target
                Surface = $surface
                LooksLikeCodeExpression = $looksLikeCode
            }
        }

        $classifiedBroken |
            Export-Csv `
                -LiteralPath (Join-Path $Out 'BROKEN_LINK_TRIAGE.csv') `
                -NoTypeInformation `
                -Encoding UTF8

        $classifiedBroken |
            Group-Object Surface,LooksLikeCodeExpression |
            Select-Object Name,Count |
            Export-Csv `
                -LiteralPath (Join-Path $Out 'BROKEN_LINK_TRIAGE_SUMMARY.csv') `
                -NoTypeInformation `
                -Encoding UTF8
    }

    # ------------------------------------------------------------
    # 5. Stale local/temp/session findings — current vs history
    # ------------------------------------------------------------

    $staleFile = Join-Path $PhaseE 'STALE_LOCAL_LINK_FINDINGS.csv'

    if (Test-Path -LiteralPath $staleFile) {
        $stale = Import-Csv -LiteralPath $staleFile

        $classifiedStale = foreach ($row in $stale) {
            $surface =
                if ($row.RelativePath -match '(?i)^docs\\project_history\\.*\\conversations\\') {
                    'FROZEN_CONVERSATION_TRANSCRIPT'
                }
                elseif ($row.RelativePath -match '(?i)^docs\\project_history\\') {
                    'PROJECT_HISTORY_CONTROL'
                }
                elseif ($row.RelativePath -match '(?i)^successor_candidates\\') {
                    'SUCCESSOR_CANDIDATE'
                }
                else {
                    'CURRENT_PUBLICATION_SURFACE'
                }

            [pscustomobject]@{
                RelativePath = $row.RelativePath
                Pattern = $row.Pattern
                Surface = $surface
            }
        }

        $classifiedStale |
            Export-Csv `
                -LiteralPath (Join-Path $Out 'STALE_LINK_TRIAGE.csv') `
                -NoTypeInformation `
                -Encoding UTF8

        $classifiedStale |
            Group-Object Surface,Pattern |
            Select-Object Name,Count |
            Export-Csv `
                -LiteralPath (Join-Path $Out 'STALE_LINK_TRIAGE_SUMMARY.csv') `
                -NoTypeInformation `
                -Encoding UTF8
    }

    # ------------------------------------------------------------
    # 6. git diff --check — classify all findings by file/reason
    # ------------------------------------------------------------

    $diffCheckFile = Join-Path $PhaseE 'GIT_DIFF_CHECK.txt'

    $diffFindings = New-Object System.Collections.Generic.List[object]

    if (Test-Path -LiteralPath $diffCheckFile) {
        foreach ($line in Get-Content -LiteralPath $diffCheckFile) {
            if ($line -match '^(.+?):(\d+):\s+(.+)$') {
                $diffFindings.Add([pscustomobject]@{
                    File = $Matches[1]
                    Line = [int]$Matches[2]
                    Reason = $Matches[3]
                })
            }
        }
    }

    $diffFindings |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'GIT_DIFF_CHECK_PARSED.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $diffFindings |
        Group-Object File,Reason |
        Sort-Object Count -Descending |
        ForEach-Object {
            [pscustomobject]@{
                FileAndReason = $_.Name
                Count = $_.Count
            }
        } |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'GIT_DIFF_CHECK_SUMMARY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # Determine whether whitespace findings are confined to exact R6
    # content rather than created by Phase E.
    $diffFiles = @(
        $diffFindings |
        Select-Object -ExpandProperty File -Unique
    )

    $diffFileRows = foreach ($rel in $diffFiles) {
        $full = Join-Path $Repo $rel

        [pscustomobject]@{
            RelativePath = $rel
            Exists = Test-Path -LiteralPath $full -PathType Leaf
            FindingCount = @(
                $diffFindings | Where-Object File -ceq $rel
            ).Count
        }
    }

    $diffFileRows |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'GIT_DIFF_CHECK_FILE_COUNTS.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 7. Reconfirm immutable checkout / index boundary
    # ------------------------------------------------------------

    $HeadAfter = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $CachedAfter = @(& git -C $Repo diff --cached --name-only)

    $status = @(& git -C $Repo status --short)

    $result = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_PHASE_E1_FAILED_GATE_FORENSIC_TRIAGE'
        Repository = $Repo
        SourcePhaseE = $PhaseE
        EvidenceDirectory = $Out

        HeadBefore = $HeadBefore
        HeadAfter = $HeadAfter
        HeadUnchanged = ($HeadBefore -ceq $HeadAfter)

        CachedBefore = $CachedBefore.Count
        CachedAfter = $CachedAfter.Count

        R22DerivedCount = $derived.Count
        R22DerivedPresentCount = $present.Count

        ForbiddenCarrierEvidencePresent =
            (Test-Path -LiteralPath $forbidden)

        BrokenLinkEvidencePresent =
            (Test-Path -LiteralPath $brokenFile)

        StaleLinkEvidencePresent =
            (Test-Path -LiteralPath $staleFile)

        GitDiffCheckParsedFindingCount = $diffFindings.Count
        GitDiffCheckAffectedFileCount = $diffFiles.Count

        GitStatusEntryCount = $status.Count

        RepositoryMutationPerformed = $false
        StagingPerformed = $false
        CommitPerformed = $false
        TagPerformed = $false
        PushPerformed = $false
        PublicationPerformed = $false

        Disposition = 'TRIAGE_ONLY_NO_RELEASE_DECISION'
    }

    $receipt = Join-Path $Out 'MSBF_PHASE_E1_TRIAGE_RECEIPT.json'

    $result |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $receipt -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "PHASE_E1_TRIAGE = COMPLETE"
    Write-Host "HEAD before: $HeadBefore"
    Write-Host "HEAD after:  $HeadAfter"
    Write-Host "Cached before: $($CachedBefore.Count)"
    Write-Host "Cached after:  $($CachedAfter.Count)"
    Write-Host ""
    Write-Host "R22 derived: $($derived.Count)"
    Write-Host "R22 present: $($present.Count)"
    Write-Host "git diff --check parsed findings: $($diffFindings.Count)"
    Write-Host "git diff --check affected files:   $($diffFiles.Count)"
    Write-Host ""
    Write-Host "No repository mutation performed."
    Write-Host "No staging performed."
    Write-Host "No commit performed."
    Write-Host "No tag created."
    Write-Host "No push performed."
    Write-Host "No publication performed."
    Write-Host ""
    Write-Host "Receipt: $receipt"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "Stop here. Return:"
    Write-Host "  MSBF_PHASE_E1_TRIAGE_RECEIPT.json"
    Write-Host "  R22_HEURISTIC_TRIAGE.csv"
    Write-Host "  R18_PROVENANCE_BOUNDARY_ROWS.csv"
    Write-Host "  FORBIDDEN_CARRIER_TRIAGE.csv"
    Write-Host "  BROKEN_LINK_TRIAGE_SUMMARY.csv"
    Write-Host "  STALE_LINK_TRIAGE_SUMMARY.csv"
    Write-Host "  GIT_DIFF_CHECK_SUMMARY.csv"
    Write-Host "  GIT_DIFF_CHECK_FILE_COUNTS.csv"
}
```

### Current disposition

**Do not stage, commit, or alter R6.** Phase E remains formally `FAIL`, but I am treating that as **“gate implementation requires adjudication,” not “R6 publication candidate defective.”**

We already have several positive controls underneath that failure: zero secret findings, zero critical-navigation targets missing, zero possible EOL-only changed paths, an empty Git index, and exact R6 tree equality. [export reference: filecite | turn25file1 | L6-L20] The untracked count of 950 is also not inherently anomalous: the supplied inventory shows the newly introduced guide, cohort, visual, Power BI, history, change-control, reproducibility, and successor-candidate trees that Phase D intentionally materialized. [export reference: filecite | turn25file3 | L1-L27]

Once you return the **E1 triage outputs**, I can make the important determination cleanly: which of the six failures are **false-positive/incorrect-scope controls**, whether any represent a genuine R6 defect, and whether we can issue a corrected **Phase E-R2 gate** without changing a single publication byte. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3ff06cd2-ab63-4fa0-8a4e-31b683c6fbd8"></a>
## Andrew / user · C123-M00069

C123-M00069 · 2026-09-10T08:39:18.343000-04:00 · active path

Preceding visible parent: [C123-M00068](part-07.md#m-06faa778-65ed-4f88-8417-1a5241239bda)

**Editorial record note:** Attachment references: BROKEN_LINK_TRIAGE_SUMMARY.csv; FORBIDDEN_CARRIER_TRIAGE.csv; GIT_DIFF_CHECK_FILE_COUNTS.csv; GIT_DIFF_CHECK_SUMMARY.csv; MSBF_PHASE_E1_TRIAGE_RECEIPT.json; R18_PROVENANCE_BOUNDARY_ROWS.csv; R22_HEURISTIC_TRIAGE.csv; STALE_LINK_TRIAGE_SUMMARY.csv

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE E1 — FAILED-GATE FORENSIC TRIAGE
============================================================
Repository: D:\x\m
Phase E:    D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_20260910T123054197Z_3a252164
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E1_20260910T123741105Z_f054cc06


============================================================
PHASE_E1_TRIAGE = COMPLETE
HEAD before: 46fb1f9198475678edc9cabdeefd2f91a59e49c2
HEAD after:  46fb1f9198475678edc9cabdeefd2f91a59e49c2
Cached before: 0
Cached after:  0

R22 derived: 16
R22 present: 5
git diff --check parsed findings: 4329
git diff --check affected files:   3

No repository mutation performed.
No staging performed.
No commit performed.
No tag created.
No push performed.
No publication performed.

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E1_20260910T123741105Z_f054cc06\MSBF_PHASE_E1_TRIAGE_RECEIPT.json
============================================================

Stop here. Return:
  MSBF_PHASE_E1_TRIAGE_RECEIPT.json
  R22_HEURISTIC_TRIAGE.csv
  R18_PROVENANCE_BOUNDARY_ROWS.csv
  FORBIDDEN_CARRIER_TRIAGE.csv
  BROKEN_LINK_TRIAGE_SUMMARY.csv
  STALE_LINK_TRIAGE_SUMMARY.csv
  GIT_DIFF_CHECK_SUMMARY.csv
  GIT_DIFF_CHECK_FILE_COUNTS.csv
<!-- END_SOURCE_MESSAGE -->


<a id="m-6ef47ac3-8cf8-41b5-b486-fb9a4e67026c"></a>
## Assistant · C123-M00070

C123-M00070 · 2026-09-10T08:39:40.642720-04:00 · active path

Preceding visible parent: [C123-M00069](part-07.md#m-3ff06cd2-ab63-4fa0-8a4e-31b683c6fbd8)

<!-- BEGIN_SOURCE_MESSAGE -->
Phase E1 gives us enough to adjudicate most of the prior failures, and the picture is materially better than the original Phase E result suggested.

The release boundary itself is still intact: `HEAD` did not move, the index remained empty, and there was no repository mutation, staging, commit, tag, push, or publication. [export reference: filecite | turn26file0 | L7-L11] [export reference: filecite | turn26file0 | L20-L26]

The key findings are:

- **R22 exclusion check was implemented incorrectly.** The provenance record actually contains **exactly 11** entries under the authoritative `excluded_private_files[]` collection. All eleven are the private R22 desktop evidence/capture objects, and all eleven are absent from the repository. The earlier count of 16 happened because the heuristic also harvested five metadata/control files from other JSON branches—`FINAL_CANDIDATE_VALIDATION.json`, `R18_PUBLIC_PROJECTION_PROVENANCE.json`, and the three rc2 candidate manifest/hash files. Those five are not members of the authoritative 11-path exclusion set. Therefore the correct result is **R22_EXCLUDED_PATHS_ABSENT = PASS**.
- **The 28 alleged Markdown failures are false positives.** E1 classified all 28 as `FROZEN_CONVERSATION_TRANSCRIPT, True` for `LooksLikeCodeExpression`. They are code syntax inside frozen historical conversations, not public navigation links. No frozen-history rewrite is warranted.
- **`git diff --check` is narrowly concentrated, not a broad corruption event.** All 4,329 parsed findings occur in only three files: `PACKAGE_INVENTORY.csv` (2,881), `MANIFEST.csv` (1,420), and `docs/README.md` (28). [export reference: filecite | turn26file0 | L17-L18] The two large CSV populations are generated inventory/manifest formatting. We should not “clean” them independently because that would break their R6 byte identities and associated checksums. The 28 `docs/README.md` findings need one more exact inspection before I classify them.
- **The six “forbidden carriers” are not the 11 excluded raw R22 files.** Every one of the six is under a `successor_candidates` public candidate tree and consists of a checklist, adjudication, or acceptance document—not the raw `power_bi/evidence/r22/...` private payload. That strongly suggests another overbroad name-based scanner, but I want the governing R18 public/private boundary applied explicitly rather than merely waiving names.
- **The stale-path scanner needs one final scope check.** Of 74 findings, 25 are in frozen conversation transcripts and are harmless. The remaining 49 classified as current surfaces are mostly `session[_-]` matches (45), plus two `localhost` and two `127.0.0.1`. A token such as `session_id` is not automatically a stale local hyperlink, so we need the exact lines/paths before deciding whether those 49 are defects or semantic false positives.

So I do **not** authorize a repository edit yet. We are down to a small adjudication problem, not a candidate rebuild.

Run this **read-only Phase E2 block**. It will inspect only the unresolved three areas: the six named carriers against the authoritative exclusion list, the 28 `docs/README.md` whitespace findings, and the 49 non-history stale-token findings. It performs no mutation.

```powershell
& {
    $ErrorActionPreference = 'Stop'

    # ============================================================
    # MSBF PHASE E2 — FINAL PRE-COMMIT FAILURE ADJUDICATION
    # READ ONLY — NO REPOSITORY MUTATION
    # ============================================================

    $Repo   = 'D:\x\m'
    $PhaseE = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_20260910T123054197Z_3a252164'
    $PhaseE1 = 'D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E1_20260910T123741105Z_f054cc06'

    $ExpectedHead = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'

    $Stamp  = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)
    $Out    = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E2_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $Out -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE E2 — FINAL FAILURE ADJUDICATION"
    Write-Host "============================================================"
    Write-Host "Repository: $Repo"
    Write-Host "Evidence:   $Out"
    Write-Host ""

    $HeadBefore = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $CachedBefore = @(& git -C $Repo diff --cached --name-only)

    if ($HeadBefore -cne $ExpectedHead) {
        throw "HEAD mismatch. Expected $ExpectedHead, found $HeadBefore"
    }

    if ($CachedBefore.Count -ne 0) {
        throw "Index is not empty. Stop."
    }

    # ------------------------------------------------------------
    # A. Reconstruct EXACT authoritative 11-path R22 exclusion set
    # ------------------------------------------------------------

    $ProvPath = Join-Path $Repo `
        'docs\release_integration\module_2_g3_v2_1\R18_PUBLIC_PROJECTION_PROVENANCE.json'

    if (-not (Test-Path -LiteralPath $ProvPath)) {
        throw "Missing governing provenance JSON: $ProvPath"
    }

    $Prov = Get-Content -LiteralPath $ProvPath -Raw | ConvertFrom-Json

    $ExactExcluded = @(
        $Prov.excluded_private_files |
        ForEach-Object {
            ([string]$_.path).Replace('/','\')
        }
    )

    $ExactExcludedRows = foreach ($rel in $ExactExcluded) {
        [pscustomobject]@{
            RelativePath = $rel
            ExistsInRepo = Test-Path -LiteralPath (Join-Path $Repo $rel)
        }
    }

    $ExactExcludedRows |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'AUTHORITATIVE_R22_EXCLUSION_CHECK.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # B. Compare six "forbidden carrier" findings to exact 11 paths
    # ------------------------------------------------------------

    $ForbiddenPath = Join-Path $PhaseE1 'FORBIDDEN_CARRIER_TRIAGE.csv'

    if (-not (Test-Path -LiteralPath $ForbiddenPath)) {
        throw "Missing E1 forbidden-carrier triage."
    }

    $Forbidden = Import-Csv -LiteralPath $ForbiddenPath

    $ForbiddenAdjudication = foreach ($row in $Forbidden) {
        $full = [string]$row.FullPath
        $rel  = $full.Substring($Repo.Length).TrimStart('\')

        $isExactExcluded = $ExactExcluded -contains $rel

        [pscustomobject]@{
            RelativePath = $rel
            Exists = Test-Path -LiteralPath $full
            Classification = $row.Classification
            IsAuthoritativeExcludedR22Path = $isExactExcluded
            Disposition =
                if ($isExactExcluded) {
                    'HARD_PRIVATE_BOUNDARY_VIOLATION'
                }
                else {
                    'NOT_IN_AUTHORITATIVE_11_PATH_EXCLUSION_SET'
                }
        }
    }

    $ForbiddenAdjudication |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'FORBIDDEN_CARRIER_AUTHORITATIVE_ADJUDICATION.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # C. Inspect exact docs/README.md git-diff-check findings
    # ------------------------------------------------------------

    $DiffCheck = Join-Path $PhaseE 'GIT_DIFF_CHECK.txt'
    $DocsReadmeFindings = New-Object System.Collections.Generic.List[object]

    if (Test-Path -LiteralPath $DiffCheck) {
        foreach ($line in Get-Content -LiteralPath $DiffCheck) {
            if ($line -match '^docs/README\.md:(\d+):\s+(.+)$') {
                $DocsReadmeFindings.Add([pscustomobject]@{
                    LineNumber = [int]$Matches[1]
                    Reason = $Matches[2]
                })
            }
        }
    }

    $ReadmePath = Join-Path $Repo 'docs\README.md'
    $ReadmeLines = Get-Content -LiteralPath $ReadmePath

    $ReadmeContext = foreach ($f in $DocsReadmeFindings) {
        $n = [int]$f.LineNumber
        $text =
            if ($n -ge 1 -and $n -le $ReadmeLines.Count) {
                $ReadmeLines[$n - 1]
            }
            else {
                '<OUT_OF_RANGE>'
            }

        [pscustomobject]@{
            LineNumber = $n
            Reason = $f.Reason
            Text = $text
            EndsWithSpaceOrTab = ($text -match '[ \t]+$')
            IsBlankOrStructuralMarkdown =
                (
                    $text -match '^\s*$' -or
                    $text -match '^\s*\|' -or
                    $text -match '^\s*<' -or
                    $text -match '^\s*>'
                )
        }
    }

    $ReadmeContext |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'DOCS_README_WHITESPACE_FINDINGS.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # Establish whether docs/README.md equals the validated R6 staging copy.
    $R6Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'
    $StageReadme = Join-Path $R6Stage 'docs\README.md'

    $CheckoutReadmeHash = (Get-FileHash -LiteralPath $ReadmePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $StageReadmeHash = (Get-FileHash -LiteralPath $StageReadme -Algorithm SHA256).Hash.ToLowerInvariant()

    [pscustomobject]@{
        CheckoutPath = $ReadmePath
        StagePath = $StageReadme
        CheckoutSHA256 = $CheckoutReadmeHash
        StageSHA256 = $StageReadmeHash
        ExactR6Equality = ($CheckoutReadmeHash -ceq $StageReadmeHash)
        FindingCount = $DocsReadmeFindings.Count
    } |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'DOCS_README_R6_IDENTITY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # D. Reproduce stale-token findings with exact path/line/context
    # ------------------------------------------------------------

    $Patterns = [ordered]@{
        'localhost'   = 'localhost'
        '127.0.0.1'   = '127\.0\.0\.1'
        'session[_-]' = 'session[_-]'
        'tmp[/\]'     = 'tmp[/\\]'
    }

    $CurrentStale = New-Object System.Collections.Generic.List[object]

    Get-ChildItem -LiteralPath $Repo -Recurse -File -Filter '*.md' |
        Where-Object {
            $_.FullName -notlike "$Repo\.git\*" -and
            $_.FullName -notmatch '\\docs\\project_history\\.*\\conversations\\'
        } |
        ForEach-Object {

            $file = $_
            $rel = $file.FullName.Substring($Repo.Length).TrimStart('\')
            $lines = Get-Content -LiteralPath $file.FullName

            for ($i = 0; $i -lt $lines.Count; $i++) {
                $text = $lines[$i]

                foreach ($key in $Patterns.Keys) {
                    if ($text -match $Patterns[$key]) {

                        $LooksLikeMarkdownLink =
                            (
                                $text -match '\[[^\]]+\]\([^)]+\)' -or
                                $text -match '<https?://' -or
                                $text -match 'https?://'
                            )

                        $CurrentStale.Add([pscustomobject]@{
                            RelativePath = $rel
                            LineNumber = $i + 1
                            Pattern = $key
                            Text = $text
                            LooksLikeActualLink = $LooksLikeMarkdownLink
                        })
                    }
                }
            }
        }

    $CurrentStale |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'CURRENT_SURFACE_STALE_TOKEN_CONTEXT.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $CurrentStale |
        Group-Object RelativePath,Pattern,LooksLikeActualLink |
        Sort-Object Count -Descending |
        ForEach-Object {
            [pscustomobject]@{
                Group = $_.Name
                Count = $_.Count
            }
        } |
        Export-Csv `
            -LiteralPath (Join-Path $Out 'CURRENT_SURFACE_STALE_TOKEN_SUMMARY.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    # ------------------------------------------------------------
    # E. Final nonmutation verification
    # ------------------------------------------------------------

    $HeadAfter = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $CachedAfter = @(& git -C $Repo diff --cached --name-only)

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_PHASE_E2_FINAL_FAILURE_ADJUDICATION'
        Repository = $Repo
        EvidenceDirectory = $Out

        HeadBefore = $HeadBefore
        HeadAfter = $HeadAfter
        HeadUnchanged = ($HeadBefore -ceq $HeadAfter)

        CachedBefore = $CachedBefore.Count
        CachedAfter = $CachedAfter.Count

        AuthoritativeExcludedR22Count = $ExactExcluded.Count
        AuthoritativeExcludedR22Present =
            @($ExactExcludedRows | Where-Object ExistsInRepo).Count

        ForbiddenScannerFindingCount = $Forbidden.Count
        ForbiddenFindingsActuallyInAuthoritativeExcludedSet =
            @(
                $ForbiddenAdjudication |
                Where-Object IsAuthoritativeExcludedR22Path
            ).Count

        DocsReadmeDiffCheckFindingCount = $DocsReadmeFindings.Count
        DocsReadmeExactR6Equality =
            ($CheckoutReadmeHash -ceq $StageReadmeHash)

        CurrentSurfaceStaleTokenCount = $CurrentStale.Count
        CurrentSurfaceLikelyActualLinkCount =
            @($CurrentStale | Where-Object LooksLikeActualLink).Count

        RepositoryMutationPerformed = $false
        StagingPerformed = $false
        CommitPerformed = $false
        TagPerformed = $false
        PushPerformed = $false
        PublicationPerformed = $false

        Disposition = 'READ_ONLY_ADJUDICATION_COMPLETE'
    }

    $ReceiptPath = Join-Path $Out 'MSBF_PHASE_E2_ADJUDICATION_RECEIPT.json'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $ReceiptPath -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "PHASE_E2_ADJUDICATION = COMPLETE"
    Write-Host "Authoritative R22 excluded paths: $($ExactExcluded.Count)"
    Write-Host "Authoritative excluded paths present: $(@($ExactExcludedRows | Where-Object ExistsInRepo).Count)"
    Write-Host "Six-name scanner findings in exact exclusion set: $(@($ForbiddenAdjudication | Where-Object IsAuthoritativeExcludedR22Path).Count)"
    Write-Host "docs/README.md diff-check findings: $($DocsReadmeFindings.Count)"
    Write-Host "docs/README.md exact R6 equality: $($CheckoutReadmeHash -ceq $StageReadmeHash)"
    Write-Host "Current-surface stale-token findings: $($CurrentStale.Count)"
    Write-Host "Current-surface findings that look like actual links: $(@($CurrentStale | Where-Object LooksLikeActualLink).Count)"
    Write-Host ""
    Write-Host "HEAD unchanged: $($HeadBefore -ceq $HeadAfter)"
    Write-Host "Index entries after: $($CachedAfter.Count)"
    Write-Host ""
    Write-Host "No repository mutation performed."
    Write-Host "No staging performed."
    Write-Host "No commit performed."
    Write-Host "No tag created."
    Write-Host "No push performed."
    Write-Host "No publication performed."
    Write-Host ""
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "Stop here and return:"
    Write-Host "  MSBF_PHASE_E2_ADJUDICATION_RECEIPT.json"
    Write-Host "  AUTHORITATIVE_R22_EXCLUSION_CHECK.csv"
    Write-Host "  FORBIDDEN_CARRIER_AUTHORITATIVE_ADJUDICATION.csv"
    Write-Host "  DOCS_README_WHITESPACE_FINDINGS.csv"
    Write-Host "  DOCS_README_R6_IDENTITY.csv"
    Write-Host "  CURRENT_SURFACE_STALE_TOKEN_CONTEXT.csv"
    Write-Host "  CURRENT_SURFACE_STALE_TOKEN_SUMMARY.csv"
}
```

One important conclusion is already firm: **do not remove those five R22-related metadata files merely to make the original heuristic say “11.”** The authoritative provenance structure distinguishes the actual 11 excluded private files from retained metadata describing that exclusion boundary. Removing the latter would be curing a scanner bug by damaging the governed publication tree.

If E2 confirms what the current evidence strongly indicates—zero of the six named carriers are members of the exact exclusion set, `docs/README.md` remains byte-identical to R6, and the remaining `session_*`/localhost matches are prose/code references rather than navigational URLs—then the next step will be a **corrected Phase E-R2 pre-commit gate**, not an R7 candidate or another editorial revision.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5f09bedd-f948-4267-b044-e86758a1fc26"></a>
## Andrew / user · C123-M00071

C123-M00071 · 2026-09-10T08:42:15.030000-04:00 · active path

Preceding visible parent: [C123-M00070](part-07.md#m-6ef47ac3-8cf8-41b5-b486-fb9a4e67026c)

**Editorial record note:** Attachment references: CURRENT_SURFACE_STALE_TOKEN_SUMMARY.csv; DOCS_README_R6_IDENTITY.csv; DOCS_README_WHITESPACE_FINDINGS.csv; FORBIDDEN_CARRIER_AUTHORITATIVE_ADJUDICATION.csv; MSBF_PHASE_E2_ADJUDICATION_RECEIPT.json; AUTHORITATIVE_R22_EXCLUSION_CHECK.csv; CURRENT_SURFACE_STALE_TOKEN_CONTEXT.csv

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE E2 — FINAL FAILURE ADJUDICATION
============================================================
Repository: D:\x\m
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E2_20260910T124124167Z_764abb5a


============================================================
PHASE_E2_ADJUDICATION = COMPLETE
Authoritative R22 excluded paths: 11
Authoritative excluded paths present: 0
Six-name scanner findings in exact exclusion set: 0
docs/README.md diff-check findings: 28
docs/README.md exact R6 equality: True
Current-surface stale-token findings: 50
Current-surface findings that look like actual links: 2

HEAD unchanged: True
Index entries after: 0

No repository mutation performed.
No staging performed.
No commit performed.
No tag created.
No push performed.
No publication performed.

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E2_20260910T124124167Z_764abb5a\MSBF_PHASE_E2_ADJUDICATION_RECEIPT.json
============================================================

Stop here and return:
  MSBF_PHASE_E2_ADJUDICATION_RECEIPT.json
  AUTHORITATIVE_R22_EXCLUSION_CHECK.csv
  FORBIDDEN_CARRIER_AUTHORITATIVE_ADJUDICATION.csv
  DOCS_README_WHITESPACE_FINDINGS.csv
  DOCS_README_R6_IDENTITY.csv
  CURRENT_SURFACE_STALE_TOKEN_CONTEXT.csv
  CURRENT_SURFACE_STALE_TOKEN_SUMMARY.csv
<!-- END_SOURCE_MESSAGE -->


<a id="m-182b4373-d6ee-4e7a-aa37-281e7fbcece1"></a>
## Assistant · C123-M00072

C123-M00072 · 2026-09-10T08:42:47.053204-04:00 · active path

Preceding visible parent: [C123-M00071](part-07.md#m-5f09bedd-f948-4267-b044-e86758a1fc26)

<!-- BEGIN_SOURCE_MESSAGE -->
E2 resolves the remaining ambiguity. I do **not** see a concrete R6 publication defect.

The authoritative R22 boundary is clean: exactly **11** excluded paths are identified and **0** are present. None of the six name-based “forbidden carrier” hits is one of those authoritative excluded paths. `docs/README.md` is byte-identical to the validated R6 staging copy, so its 28 `git diff --check` trailing-whitespace findings are inherited R6 formatting—not checkout damage. The two stale-token rows flagged as “actual links” are also false positives: both are legitimate links to `M2_12_AUDIT_DETERMINATION_SUPERSESSION_RECORD_20260812.md`; the scanner matched the substring `session_` inside **`supersession_`**, not a stale session URL. The rest of the stale-token hits are similarly prose/code terms such as “session-scoped,” not broken navigation. The E2 receipt also confirms no mutation, staging, commit, tag, push, or publication occurred. [export reference: filecite | turn27file0 | L6-L18] [export reference: filecite | turn27file0 | L19-L25]

So the correct disposition is:

```text
PHASE_E_ORIGINAL = FAIL / CONTROL-SCOPE FALSE POSITIVES
R6_DEFECT = NOT ESTABLISHED
AUTHORITATIVE_R22_BOUNDARY = PASS
BROKEN_NAVIGATION = NOT ESTABLISHED
PRIVATE_CARRIER_LEAK = NOT ESTABLISHED
R6_TREE_INTEGRITY = PASS
```

We should now run a **corrected Phase E-R2 gate** that preserves the hard controls but fixes the three bad heuristics:

1. use the authoritative `excluded_private_files[]` list directly;
2. scan current Markdown navigation while excluding frozen conversation transcripts and code-like false positives;
3. treat `git diff --check` as diagnostic for exact R6 bytes rather than requiring zero historical/generated whitespace findings.

Use the same PowerShell window and run this block. It remains read-only and performs no staging or Git mutation.

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo  = 'D:\x\m'
    $Stage = 'D:\MSBF_RELEASE_R6_STAGING_20260910T121241797Z_028c5f94'

    $ExpectedHead = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'
    $ExpectedFiles = 2884

    $ExpectedPbixBytes = 27635305
    $ExpectedPbixSha = 'ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4'
    $ExpectedDataModelSha = '24396d02c0fbcb782cc9918e842886711146b8ff9455c8822d2aeaf009b96061'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_E_R2_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE E-R2 — CORRECTED PRE-COMMIT GATE"
    Write-Host "============================================================"
    Write-Host "Repository: $Repo"
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
            Check = $Check
            Expected = $Expected
            Actual = $Actual
            Status = if ($Pass) { 'PASS' } else { 'FAIL' }
        })
    }

    function Get-TreeInventory {
        param([string]$Root,[switch]$ExcludeGit)

        $rootFull = [IO.Path]::GetFullPath($Root).TrimEnd('\') + '\'
        $files = @(Get-ChildItem -LiteralPath $Root -Recurse -File -Force)

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
            [pscustomobject]@{
                Path = $f.FullName.Substring($rootFull.Length).Replace('\','/')
                Bytes = [int64]$f.Length
                Sha256 = (
                    Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }
        }
    }

    # ------------------------------------------------------------
    # 1. Git/base/index controls
    # ------------------------------------------------------------

    $Head = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $Branch = (& git -C $Repo branch --show-current).Trim()
    $Cached = @(& git -C $Repo diff --cached --name-only)

    Add-Check 'HEAD_UNCHANGED' ($Head -ceq $ExpectedHead) $Head $ExpectedHead
    Add-Check 'BRANCH_MAIN' ($Branch -ceq 'main') $Branch 'main'
    Add-Check 'INDEX_EMPTY' ($Cached.Count -eq 0) "$($Cached.Count)" '0'

    # ------------------------------------------------------------
    # 2. Fresh exact tree equality
    # ------------------------------------------------------------

    Write-Host "Hashing staging and checkout..."
    $StageInv = @(Get-TreeInventory $Stage)
    $RepoInv = @(Get-TreeInventory $Repo -ExcludeGit)

    $sMap = @{}
    foreach ($r in $StageInv) { $sMap[$r.Path.ToLowerInvariant()] = $r }

    $rMap = @{}
    foreach ($r in $RepoInv) { $rMap[$r.Path.ToLowerInvariant()] = $r }

    $Missing = 0
    $Extra = 0
    $Mismatch = 0

    foreach ($k in $sMap.Keys) {
        if (-not $rMap.ContainsKey($k)) {
            $Missing++
            continue
        }

        $s = $sMap[$k]
        $r = $rMap[$k]

        if (
            $s.Path -cne $r.Path -or
            $s.Bytes -ne $r.Bytes -or
            $s.Sha256 -cne $r.Sha256
        ) {
            $Mismatch++
        }
    }

    foreach ($k in $rMap.Keys) {
        if (-not $sMap.ContainsKey($k)) { $Extra++ }
    }

    $TreePass = (
        $StageInv.Count -eq $ExpectedFiles -and
        $RepoInv.Count -eq $ExpectedFiles -and
        $Missing -eq 0 -and
        $Extra -eq 0 -and
        $Mismatch -eq 0
    )

    Add-Check 'R6_TREE_EQUALITY' `
        $TreePass `
        "Stage=$($StageInv.Count);Repo=$($RepoInv.Count);Missing=$Missing;Extra=$Extra;Mismatch=$Mismatch" `
        "Stage=2884;Repo=2884;Missing=0;Extra=0;Mismatch=0"

    # ------------------------------------------------------------
    # 3. Unchanged validators
    # ------------------------------------------------------------

    $Python = (Get-Command python.exe -ErrorAction Stop).Source

    function Run-Validator {
        param(
            [string]$Label,
            [string]$Rel,
            [string]$Expected1,
            [string]$Expected2
        )

        $path = Join-Path $Repo $Rel

        Push-Location $Repo
        try {
            $out = @(& $Python $path 2>&1)
            $code = $LASTEXITCODE
        }
        finally {
            Pop-Location
        }

        $out | Set-Content -LiteralPath (Join-Path $EvidenceDir "$Label.txt") -Encoding UTF8
        $text = $out -join "`n"

        Add-Check `
            $Label `
            ($code -eq 0 -and $text.Contains($Expected1) -and $text.Contains($Expected2)) `
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

    # ------------------------------------------------------------
    # 4. Authoritative R22 exclusion set — exact 11
    # ------------------------------------------------------------

    $ProvPath = Join-Path $Repo `
        'docs\release_integration\module_2_g3_v2_1\R18_PUBLIC_PROJECTION_PROVENANCE.json'

    $Prov = Get-Content -LiteralPath $ProvPath -Raw | ConvertFrom-Json

    $ExactExcluded = @(
        $Prov.excluded_private_files |
        ForEach-Object { ([string]$_.path).Replace('/','\') }
    )

    $PresentExcluded = @(
        $ExactExcluded |
        Where-Object { Test-Path -LiteralPath (Join-Path $Repo $_) }
    )

    $ExactExcluded |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'AUTHORITATIVE_R22_EXCLUDED_PATHS.txt') `
            -Encoding UTF8

    Add-Check `
        'AUTHORITATIVE_R22_EXCLUSION_COUNT' `
        ($ExactExcluded.Count -eq 11) `
        "$($ExactExcluded.Count)" `
        '11'

    Add-Check `
        'AUTHORITATIVE_R22_EXCLUDED_PATHS_ABSENT' `
        ($PresentExcluded.Count -eq 0) `
        "$($PresentExcluded.Count)" `
        '0'

    # ------------------------------------------------------------
    # 5. PBIX + DataModel exact identity
    # ------------------------------------------------------------

    $Pbix = Join-Path $Repo `
        'docs\power_bi\m2_v2_1\release\MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix'

    $pbixItem = Get-Item -LiteralPath $Pbix
    $pbixSha = (
        Get-FileHash -LiteralPath $Pbix -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    Add-Check 'PBIX_BYTES' `
        ($pbixItem.Length -eq $ExpectedPbixBytes) `
        "$($pbixItem.Length)" `
        "$ExpectedPbixBytes"

    Add-Check 'PBIX_SHA256' `
        ($pbixSha -ceq $ExpectedPbixSha) `
        $pbixSha `
        $ExpectedPbixSha

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $pbixZip = [System.IO.Compression.ZipFile]::OpenRead($Pbix)

    try {
        $dm = @(
            $pbixZip.Entries |
            Where-Object {
                $_.FullName -eq 'DataModel' -or
                $_.FullName -like '*/DataModel'
            }
        )

        if ($dm.Count -ne 1) {
            Add-Check 'DATAMODEL_MEMBER_COUNT' $false "$($dm.Count)" '1'
        }
        else {
            Add-Check 'DATAMODEL_MEMBER_COUNT' $true '1' '1'

            $sha = [Security.Cryptography.SHA256]::Create()
            try {
                $stream = $dm[0].Open()
                try {
                    $hashBytes = $sha.ComputeHash($stream)
                    $dmSha = (
                        [BitConverter]::ToString($hashBytes).Replace('-','')
                    ).ToLowerInvariant()
                }
                finally {
                    $stream.Dispose()
                }
            }
            finally {
                $sha.Dispose()
            }

            Add-Check 'DATAMODEL_SHA256' `
                ($dmSha -ceq $ExpectedDataModelSha) `
                $dmSha `
                $ExpectedDataModelSha
        }
    }
    finally {
        $pbixZip.Dispose()
    }

    # ------------------------------------------------------------
    # 6. Private/raw carrier check — authoritative scope
    #
    # We fail only if an exact excluded R22 path exists or an actual
    # private ZIP/raw owner carrier is present. Public adjudication and
    # checklist documents are not classified private by filename alone.
    # ------------------------------------------------------------

    $RepoFiles = @(
        Get-ChildItem -LiteralPath $Repo -Recurse -File -Force |
        Where-Object {
            $_.FullName -notlike "$Repo\.git\*"
        }
    )

    $PrivateCarriers = @(
        $RepoFiles |
        Where-Object {
            $_.Extension -ieq '.zip' -and
            $_.FullName -match '(?i)(private|audit_return|control_private|history_freeze_evidence|desktop_evidence_private|raw_chat)'
        }
    )

    Add-Check `
        'PRIVATE_ZIP_RAW_CARRIERS_ABSENT' `
        ($PrivateCarriers.Count -eq 0) `
        "$($PrivateCarriers.Count)" `
        '0'

    $FontFiles = @(
        $RepoFiles |
        Where-Object {
            $_.Extension -match '^\.(ttf|otf|woff|woff2|eot)$'
        }
    )

    Add-Check `
        'STANDALONE_FONT_FILES_ABSENT' `
        ($FontFiles.Count -eq 0) `
        "$($FontFiles.Count)" `
        '0'

    # ------------------------------------------------------------
    # 7. Current navigation link validation
    #
    # Exclude frozen conversation transcripts. Parse only real markdown
    # link syntax and validate filesystem target paths.
    # ------------------------------------------------------------

    $Markdown = @(
        Get-ChildItem -LiteralPath $Repo -Recurse -File -Filter '*.md' |
        Where-Object {
            $_.FullName -notlike "$Repo\.git\*" -and
            $_.FullName -notmatch '\\docs\\project_history\\.*\\conversations\\'
        }
    )

    $BrokenLinks = New-Object System.Collections.Generic.List[object]

    foreach ($md in $Markdown) {
        $text = Get-Content -LiteralPath $md.FullName -Raw

        $matches = [regex]::Matches(
            $text,
            '!?\[[^\]]*\]\(([^)]+)\)'
        )

        foreach ($m in $matches) {
            $target = $m.Groups[1].Value.Trim()

            if (
                [string]::IsNullOrWhiteSpace($target) -or
                $target.StartsWith('#') -or
                $target -match '^(?i)(https?|mailto|tel|data):'
            ) {
                continue
            }

            if ($target -match '^<(.+)>$') {
                $target = $Matches[1]
            }
            elseif ($target -match '^(\S+)\s+["''].*["'']$') {
                $target = $Matches[1]
            }

            $pathPart = ($target -split '#',2)[0]

            if ([string]::IsNullOrWhiteSpace($pathPart)) {
                continue
            }

            $pathPart = [uri]::UnescapeDataString($pathPart)
            $resolved = Join-Path $md.DirectoryName $pathPart

            if (-not (Test-Path -LiteralPath $resolved)) {
                $rel = $md.FullName.Substring($Repo.Length).TrimStart('\')

                $BrokenLinks.Add([pscustomobject]@{
                    MarkdownFile = $rel
                    Target = $target
                })
            }
        }
    }

    $BrokenLinks |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'BROKEN_CURRENT_MARKDOWN_LINKS.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Add-Check `
        'CURRENT_MARKDOWN_LINKS' `
        ($BrokenLinks.Count -eq 0) `
        "$($BrokenLinks.Count)" `
        '0'

    # ------------------------------------------------------------
    # 8. Stale navigational URL/path check — corrected scope
    #
    # Only actual Markdown link targets count. Plain prose terms such as
    # "session-scoped" or file names containing "supersession_" do not.
    # ------------------------------------------------------------

    $StaleActualLinks = New-Object System.Collections.Generic.List[object]

    foreach ($md in $Markdown) {
        $text = Get-Content -LiteralPath $md.FullName -Raw

        $matches = [regex]::Matches(
            $text,
            '!?\[[^\]]*\]\(([^)]+)\)'
        )

        foreach ($m in $matches) {
            $target = $m.Groups[1].Value.Trim()

            if (
                $target -match '(?i)localhost' -or
                $target -match '127\.0\.0\.1' -or
                $target -match '(?i)^file:///' -or
                $target -match '(?i)sandbox:/' -or
                $target -match '(?i)[session]/' -or
                $target -match '(?i)[A-Za-z]:\\Users\\'
            ) {
                $rel = $md.FullName.Substring($Repo.Length).TrimStart('\')

                $StaleActualLinks.Add([pscustomobject]@{
                    MarkdownFile = $rel
                    Target = $target
                })
            }
        }
    }

    $StaleActualLinks |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'STALE_ACTUAL_MARKDOWN_LINKS.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Add-Check `
        'STALE_ACTUAL_MARKDOWN_LINKS' `
        ($StaleActualLinks.Count -eq 0) `
        "$($StaleActualLinks.Count)" `
        '0'

    # ------------------------------------------------------------
    # 9. git diff --check diagnostic with R6-equality disposition
    # ------------------------------------------------------------

    $DiffCheck = @(& git -C $Repo diff --check)
    $DiffCheckCode = $LASTEXITCODE

    $DiffCheck |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GIT_DIFF_CHECK_DIAGNOSTIC.txt') `
            -Encoding UTF8

    $DiffCheckFiles = @(
        $DiffCheck |
        ForEach-Object {
            if ($_ -match '^(.+?):\d+:') { $Matches[1] }
        } |
        Sort-Object -Unique
    )

    # Hard condition is that every flagged file remains exact R6 bytes.
    $WhitespaceMismatch = 0

    foreach ($rel in $DiffCheckFiles) {
        $repoPath = Join-Path $Repo $rel
        $stagePath = Join-Path $Stage $rel

        if (
            -not (Test-Path -LiteralPath $repoPath -PathType Leaf) -or
            -not (Test-Path -LiteralPath $stagePath -PathType Leaf)
        ) {
            $WhitespaceMismatch++
            continue
        }

        $rh = (
            Get-FileHash -LiteralPath $repoPath -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        $sh = (
            Get-FileHash -LiteralPath $stagePath -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        if ($rh -cne $sh) {
            $WhitespaceMismatch++
        }
    }

    Add-Check `
        'DIFF_CHECK_FINDINGS_ARE_EXACT_R6_BYTES' `
        ($WhitespaceMismatch -eq 0) `
        "Findings=$($DiffCheck.Count);Files=$($DiffCheckFiles.Count);R6Mismatch=$WhitespaceMismatch" `
        'R6Mismatch=0'

    # ------------------------------------------------------------
    # 10. Critical public routes
    # ------------------------------------------------------------

    $CriticalPaths = @(
        'README.md',
        'docs\README.md',
        'docs\guide\CURRENT_USE.md',
        'docs\guide\EXPLAINABILITY.md',
        'docs\guide\LEARNING.md',
        'docs\guide\VISUALS.md',
        'docs\guide\REQUIREMENTS_AND_VALIDATION.md',
        'docs\guide\SOURCE_VERSIONS.md',
        'docs\power_bi\m2_v2_1\README.md',
        'docs\cohort\m2_v2_1\README.md'
    )

    $MissingCritical = @(
        $CriticalPaths |
        Where-Object {
            -not (Test-Path -LiteralPath (Join-Path $Repo $_))
        }
    )

    Add-Check `
        'CRITICAL_PUBLIC_ROUTES' `
        ($MissingCritical.Count -eq 0) `
        "$($MissingCritical.Count)" `
        '0'

    # ------------------------------------------------------------
    # 11. Reconfirm no validator/scanner mutation
    # ------------------------------------------------------------

    Write-Host "Re-hashing checkout after corrected gate..."
    $RepoAfter = @(Get-TreeInventory $Repo -ExcludeGit)

    $afterMap = @{}
    foreach ($r in $RepoAfter) {
        $afterMap[$r.Path.ToLowerInvariant()] = $r
    }

    $PostMismatch = 0

    if ($afterMap.Count -ne $sMap.Count) {
        $PostMismatch++
    }

    foreach ($k in $sMap.Keys) {
        if (-not $afterMap.ContainsKey($k)) {
            $PostMismatch++
            continue
        }

        if (
            $sMap[$k].Path -cne $afterMap[$k].Path -or
            $sMap[$k].Bytes -ne $afterMap[$k].Bytes -or
            $sMap[$k].Sha256 -cne $afterMap[$k].Sha256
        ) {
            $PostMismatch++
        }
    }

    Add-Check `
        'POST_GATE_TREE_UNCHANGED' `
        ($PostMismatch -eq 0) `
        "$PostMismatch" `
        '0'

    # ------------------------------------------------------------
    # 12. Final Git boundary
    # ------------------------------------------------------------

    $HeadAfter = (& git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $CachedAfter = @(& git -C $Repo diff --cached --name-only)

    Add-Check 'HEAD_STILL_UNCHANGED' `
        ($HeadAfter -ceq $ExpectedHead) `
        $HeadAfter `
        $ExpectedHead

    Add-Check 'INDEX_STILL_EMPTY' `
        ($CachedAfter.Count -eq 0) `
        "$($CachedAfter.Count)" `
        '0'

    # ------------------------------------------------------------
    # 13. Gate decision
    # ------------------------------------------------------------

    $Checks |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'PHASE_E_R2_CHECK_REGISTER.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    $Failures = @($Checks | Where-Object Status -eq 'FAIL')
    $Status = if ($Failures.Count -eq 0) { 'PASS' } else { 'FAIL' }

    $Receipt = [ordered]@{
        SchemaVersion = '1.0'
        Task = 'MSBF_RELEASE_ENGINEERING_PHASE_E_R2_PRE_COMMIT_GATE'
        GoverningDecision = 'IA-D-R20-INT-001'
        ConditionalAuthority = 'IA-PUB-R20-INTEGRATED-001'

        PriorPhaseE = 'FAIL_CONTROL_SCOPE_FALSE_POSITIVES'
        Repository = $Repo
        SourceStage = $Stage
        EvidenceDirectory = $EvidenceDir

        Head = $HeadAfter
        Branch = $Branch

        R6FileCount = $ExpectedFiles
        AuthoritativeR22ExcludedCount = $ExactExcluded.Count
        AuthoritativeR22Present = $PresentExcluded.Count

        BrokenCurrentMarkdownLinks = $BrokenLinks.Count
        StaleActualMarkdownLinks = $StaleActualLinks.Count

        DiffCheckFindingCount = $DiffCheck.Count
        DiffCheckAffectedFiles = $DiffCheckFiles.Count
        DiffCheckR6MismatchCount = $WhitespaceMismatch

        CheckCount = $Checks.Count
        FailureCount = $Failures.Count
        FailedChecks = @($Failures | Select-Object Check,Expected,Actual)

        RepositoryMutationPerformed = $false
        StagingPerformed = $false
        CommitPerformed = $false
        TagPerformed = $false
        PushPerformed = $false
        PublicationPerformed = $false

        PreCommitGate = $Status
    }

    $JsonPath = Join-Path $EvidenceDir 'MSBF_PHASE_E_R2_PRE_COMMIT_GATE.json'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content -LiteralPath $JsonPath -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "PRE_COMMIT_GATE_R2 = $Status"
    Write-Host "Hard checks: $($Checks.Count)"
    Write-Host "Failures: $($Failures.Count)"
    Write-Host ""
    Write-Host "R6 tree equality: $TreePass"
    Write-Host "Authoritative R22 excluded: $($ExactExcluded.Count)"
    Write-Host "Excluded paths present: $($PresentExcluded.Count)"
    Write-Host "Broken current Markdown links: $($BrokenLinks.Count)"
    Write-Host "Stale actual Markdown links: $($StaleActualLinks.Count)"
    Write-Host "git diff --check findings: $($DiffCheck.Count)"
    Write-Host "git diff --check affected files: $($DiffCheckFiles.Count)"
    Write-Host "diff-check files differing from R6: $WhitespaceMismatch"
    Write-Host ""
    Write-Host "HEAD: $HeadAfter"
    Write-Host "Cached paths: $($CachedAfter.Count)"
    Write-Host ""
    Write-Host "No staging, commit, tag, push, or publication performed."
    Write-Host "Receipt: $JsonPath"
    Write-Host "============================================================"

    if ($Failures.Count -gt 0) {
        Write-Host ""
        Write-Host "FAILED CHECKS:"
        $Failures | Format-Table -AutoSize | Out-Host
        Write-Host ""
        Write-Host "STOP. Do not stage or commit."
    }
    else {
        Write-Host ""
        Write-Host "PRE_COMMIT_GATE = PASS"
        Write-Host "Stop here. Do not stage or commit yet."
    }
}
```

The expected result is:

```text
PRE_COMMIT_GATE_R2 = PASS

R6 tree equality: True
Authoritative R22 excluded: 11
Excluded paths present: 0
Broken current Markdown links: 0
Stale actual Markdown links: 0
diff-check files differing from R6: 0

HEAD:
46fb1f9198475678edc9cabdeefd2f91a59e49c2

Cached paths: 0
```

If that passes, Phase E is closed without changing a byte of R6. Then we can safely cross the next boundary into **Phase F: stage the reviewed exact R6 tree, validate the staged content, and create the publication commit**.
<!-- END_SOURCE_MESSAGE -->
