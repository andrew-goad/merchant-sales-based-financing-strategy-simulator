# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 09 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-08.md)
[Next part](part-10.md)

<a id="m-a66589f3-25a4-412e-b97c-f25916076a82"></a>
## Assistant · C123-M00080

C123-M00080 · 2026-09-10T09:14:02.394735-04:00 · active path

Preceding visible parent: [C123-M00079](part-08.md#m-ef716608-7469-4db2-af00-123d22e2c1ea)

<!-- BEGIN_SOURCE_MESSAGE -->
Phase F-R2 is a clean **PASS**. I reviewed the returned evidence, including the 21-check register, the 2,884-row R6→index blob certification, the certified index tree, and the validator outputs. The key point is that the Git index is now independently bound to the exact approved R6 content: **2,884 index paths, 0 missing, 0 extra, 0 blob mismatches, 0 blob errors**, with certified index tree `fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb`. The authoritative 11-path R22 exclusion set is also absent from the index. [export reference: filecite | turn30file6 | L10-L21]

The existing validators also remain green: public release validation reports **2,880 governed manifest files and 12 Module 2 stage folders**; the rc1 overlay reports **235 governed candidate files**; and rc2 reports **248**. [export reference: filecite | turn30file0 | L1-L3] [export reference: filecite | turn30file1 | L1-L2] [export reference: filecite | turn30file2 | L1-L2]

The large `git diff --cached --check` result is now correctly classified as **diagnostic/source-bound**, not a release blocker. The evidence records 42,098 raw lines, 21,050 parsed findings across 102 paths, while separately establishing that the staged index is exactly the approved R6 content. [export reference: filecite | turn30file3 | L1-L9] That is materially stronger than trying to “fix” those whitespace findings, because doing so would alter the already approved R6 bytes.

So we can now advance to the actual **commit-binding step**. I recommend one bounded command block that rechecks the index state immediately before commit, commits the exact staged tree, then captures the new commit/tree/parent identities. Do **not** create the tag yet.

Run this in the same PowerShell:

```powershell
Set-Location 'D:\x\m'

$ErrorActionPreference = 'Stop'

$expectedParent = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'
$expectedTree   = 'fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb'

Write-Host '============================================================'
Write-Host 'MSBF PHASE F-R3 — FINAL COMMIT BINDING'
Write-Host '============================================================'

# ------------------------------------------------------------------
# 1. Immediate pre-commit identity checks
# ------------------------------------------------------------------

$headBefore = (git rev-parse HEAD).Trim()
$branch     = (git branch --show-current).Trim()
$indexTree  = (git write-tree).Trim()
$unstaged   = @(git diff --name-only)
$untracked  = @(git ls-files --others --exclude-standard)
$staged     = @(git diff --cached --name-only)

Write-Host "HEAD before:        $headBefore"
Write-Host "Branch:             $branch"
Write-Host "Index tree:         $indexTree"
Write-Host "Staged delta paths: $($staged.Count)"
Write-Host "Unstaged paths:     $($unstaged.Count)"
Write-Host "Untracked paths:    $($untracked.Count)"

if ($headBefore -ne $expectedParent) {
    throw "STOP: HEAD changed unexpectedly."
}
if ($branch -ne 'main') {
    throw "STOP: Current branch is not main."
}
if ($indexTree -ne $expectedTree) {
    throw "STOP: Git index tree no longer matches certified R6 tree."
}
if ($unstaged.Count -ne 0) {
    throw "STOP: Unstaged tracked changes appeared."
}
if ($untracked.Count -ne 0) {
    throw "STOP: Untracked paths appeared."
}
if ($staged.Count -ne 966) {
    throw "STOP: Expected 966 staged delta paths; found $($staged.Count)."
}

Write-Host ''
Write-Host 'Final staged summary:'
git diff --cached --stat
Write-Host ''
git diff --cached --name-status

# ------------------------------------------------------------------
# 2. Commit exact certified index
# ------------------------------------------------------------------

git commit -m "Publish Module 2 / G3 v2.1.0 integrated successor"

if ($LASTEXITCODE -ne 0) {
    throw "STOP: git commit failed."
}

# ------------------------------------------------------------------
# 3. Capture commit binding
# ------------------------------------------------------------------

$commit = (git rev-parse HEAD).Trim()
$tree   = (git rev-parse 'HEAD^{tree}').Trim()
$parent = (git rev-parse 'HEAD^').Trim()
$subject = (git log -1 --format='%s').Trim()
$timestamp = (git log -1 --format='%cI').Trim()
$status = @(git status --short)

Write-Host ''
Write-Host '============================================================'
Write-Host 'PHASE_F_R3_COMMIT_BINDING'
Write-Host '============================================================'
Write-Host "Commit SHA: $commit"
Write-Host "Tree SHA:   $tree"
Write-Host "Parent SHA: $parent"
Write-Host "Branch:     $branch"
Write-Host "Timestamp:  $timestamp"
Write-Host "Subject:    $subject"
Write-Host "Status rows after commit: $($status.Count)"

if ($tree -ne $expectedTree) {
    throw "STOP: committed tree does not equal certified R6 index tree."
}
if ($parent -ne $expectedParent) {
    throw "STOP: commit parent does not equal verified predecessor."
}
if ($status.Count -ne 0) {
    Write-Host ''
    Write-Host 'Post-commit status:'
    git status --short
    throw "STOP: working tree is not clean after commit."
}

Write-Host ''
Write-Host 'PHASE_F_R3_COMMIT_BINDING = PASS'
Write-Host 'No tag created.'
Write-Host 'No push performed.'
Write-Host 'No publication performed.'
Write-Host 'STOP HERE and return this console output.'
```

Expected hard invariants are:

- parent remains `46fb1f9198475678edc9cabdeefd2f91a59e49c2`;
- committed tree must be exactly `fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb`;
- staged delta count immediately before commit remains **966**;
- post-commit working tree is clean;
- no tag, push, or publication occurs.

The F-R2 receipt itself confirms that no commit, tag, push, or publication has yet occurred, so this is the correct next publication boundary. [export reference: filecite | turn30file6 | L27-L36]

Return the full F-R3 console result. If it passes, our next step is **Phase G: create and verify the new annotated `module-2-g3-v2.1.0` tag while proving the historical v2.0.0 tag remains untouched**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9fbe1fce-f06c-4b47-9560-d33dc67401da"></a>
## Andrew / user · C123-M00081

C123-M00081 · 2026-09-10T09:43:56.376000-04:00 · active path

Preceding visible parent: [C123-M00080](part-09.md#m-a66589f3-25a4-412e-b97c-f25916076a82)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 325ca548-6b6a-4a80-8ebe-e0b8583f8741.png

<!-- BEGIN_SOURCE_MESSAGE -->
i had to keep  pressing spacebar to get all of the output to show. now it's on this screen. is there anything i need to do? 
<!-- END_SOURCE_MESSAGE -->


<a id="m-fe1ff0df-8808-477a-b2f1-c711eb53ba6d"></a>
## Assistant · C123-M00082

C123-M00082 · 2026-09-10T09:43:58.988746-04:00 · active path

Preceding visible parent: [C123-M00081](part-09.md#m-9fbe1fce-f06c-4b47-9560-d33dc67401da)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. You are simply inside Git's **pager (`less`)** because the `git diff --cached --stat` / `--name-status` output was long.

The `(END)` at the bottom means **all output has been displayed**. Nothing is wrong, and you do **not** need to press Space anymore.

### Do this now

Press:

```text
q
```

just once.

That exits the pager and returns control to the PowerShell script. **Do not press Ctrl+C and do not close PowerShell.**

After you press `q`, the script should continue automatically. Because our block has another long `git diff --cached --name-status` command, it **may put you into another pager**. If you again see `(END)`, press **`q` again**. You do not need to page through it with Space—we already have the relevant staged-set certification from F-R2.

Eventually you should see the commit execute and then something like:

```text
PHASE_F_R3_COMMIT_BINDING
...
Commit SHA: ...
Tree SHA:   fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb
Parent SHA: 46fb1f9198475678edc9cabdeefd2f91a59e49c2
...
PHASE_F_R3_COMMIT_BINDING = PASS
No tag created.
No push performed.
No publication performed.
STOP HERE and return this console output.
```

**Important:** right now, just press `q`. Don't type or run any new command manually.
<!-- END_SOURCE_MESSAGE -->


<a id="m-af016f85-c189-4d18-b259-2f6f7b1561aa"></a>
## Andrew / user · C123-M00083

C123-M00083 · 2026-09-10T09:45:28.386000-04:00 · active path

Preceding visible parent: [C123-M00082](part-09.md#m-fe1ff0df-8808-477a-b2f1-c711eb53ba6d)

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
PHASE_F_R3_COMMIT_BINDING
============================================================
Commit SHA: fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Tree SHA:   fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb
Parent SHA: 46fb1f9198475678edc9cabdeefd2f91a59e49c2
Branch:     main
Timestamp:  2026-09-10T09:44:47-04:00
Subject:    Publish Module 2 / G3 v2.1.0 integrated successor
Status rows after commit: 0

PHASE_F_R3_COMMIT_BINDING = PASS
No tag created.
No push performed.
No publication performed.
STOP HERE and return this console output.
<!-- END_SOURCE_MESSAGE -->


<a id="m-32a65a3e-f2b0-44f2-afec-a977d70b15b0"></a>
## Assistant · C123-M00084

C123-M00084 · 2026-09-10T09:45:29.308833-04:00 · active path

Preceding visible parent: [C123-M00083](part-09.md#m-af016f85-c189-4d18-b259-2f6f7b1561aa)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase F-R3 passes.** We now have the exact local publication commit bound to the previously certified R6 Git tree:

```text
Publication commit:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Certified/committed tree:
fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb

Parent:
46fb1f9198475678edc9cabdeefd2f91a59e49c2

Branch:
main

Working tree:
CLEAN

Commit subject:
Publish Module 2 / G3 v2.1.0 integrated successor
```

That tree identity is particularly important: it is exactly the tree independently certified in F-R2 from all **2,884 R6 files with 0 blob mismatches and 0 blob errors**. [export reference: filecite | turn30file6 | L10-L21]

We have crossed the **local commit boundary**, but nothing is public yet.

## Phase G — create and certify the new stable tag

We can now create the **new annotated tag**:

```text
module-2-g3-v2.1.0
```

This block first freshly verifies the local/remote historical v2.0.0 identities and confirms v2.1.0 is still absent remotely. Only then does it create the **local** new tag. It does **not push anything**.

Paste this in the same PowerShell window:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'

    $ExpectedCommit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $ExpectedTree   = 'fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb'
    $ExpectedParent = '46fb1f9198475678edc9cabdeefd2f91a59e49c2'

    $OldTag = 'module-2-g3-v2.0.0'
    $ExpectedOldTagObject = 'fcf32b615142a06075a7fccede26a97042ca8194'
    $ExpectedOldCommit    = '500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65'

    $NewTag = 'module-2-g3-v2.1.0'
    $TagMessage = 'Module 2 / G3 v2.1.0 integrated successor'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_G_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE G — STABLE TAG / PRE-PUSH CERTIFICATION"
    Write-Host "============================================================"

    # ------------------------------------------------------------
    # 1. Certify local publication commit
    # ------------------------------------------------------------

    $Head = (git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $Tree = (git -C $Repo rev-parse 'HEAD^{tree}').Trim().ToLowerInvariant()
    $Parent = (git -C $Repo rev-parse 'HEAD^').Trim().ToLowerInvariant()
    $Branch = (git -C $Repo branch --show-current).Trim()
    $Status = @(git -C $Repo status --porcelain=v1)

    if ($Head -ne $ExpectedCommit) {
        throw "STOP: HEAD differs from certified publication commit."
    }

    if ($Tree -ne $ExpectedTree) {
        throw "STOP: HEAD tree differs from certified R6 tree."
    }

    if ($Parent -ne $ExpectedParent) {
        throw "STOP: publication commit parent changed."
    }

    if ($Branch -ne 'main') {
        throw "STOP: branch is not main."
    }

    if ($Status.Count -ne 0) {
        throw "STOP: working tree is not clean."
    }

    # ------------------------------------------------------------
    # 2. Fresh historical tag verification — LOCAL
    # ------------------------------------------------------------

    $OldLocalObject = (
        git -C $Repo rev-parse "$OldTag^{tag}"
    ).Trim().ToLowerInvariant()

    $OldLocalCommit = (
        git -C $Repo rev-parse "$OldTag^{commit}"
    ).Trim().ToLowerInvariant()

    if ($OldLocalObject -ne $ExpectedOldTagObject) {
        throw "STOP: historical local v2.0.0 tag object changed."
    }

    if ($OldLocalCommit -ne $ExpectedOldCommit) {
        throw "STOP: historical local v2.0.0 peeled commit changed."
    }

    # ------------------------------------------------------------
    # 3. Fresh historical tag + branch verification — REMOTE
    #    ls-remote does not update local refs.
    # ------------------------------------------------------------

    $RemoteMainRaw = @(git -C $Repo ls-remote origin refs/heads/main)

    if ($LASTEXITCODE -ne 0 -or $RemoteMainRaw.Count -ne 1) {
        throw "STOP: unable to resolve remote main."
    }

    $RemoteMain = (
        ($RemoteMainRaw[0] -split '\s+')[0]
    ).ToLowerInvariant()

    # Remote main must still be the predecessor because we have not pushed.
    if ($RemoteMain -ne $ExpectedParent) {
        throw "STOP: remote main changed unexpectedly before push. Actual: $RemoteMain"
    }

    $OldRemoteRaw = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$OldTag" `
            "refs/tags/$OldTag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to query historical remote tag."
    }

    $OldRemoteObjectLine = @(
        $OldRemoteRaw |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))$" }
    )

    $OldRemoteCommitLine = @(
        $OldRemoteRaw |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))\^\{\}$" }
    )

    if (
        $OldRemoteObjectLine.Count -ne 1 -or
        $OldRemoteCommitLine.Count -ne 1
    ) {
        throw "STOP: historical remote annotated tag could not be resolved exactly."
    }

    $OldRemoteObject = (
        ($OldRemoteObjectLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $OldRemoteCommit = (
        ($OldRemoteCommitLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if ($OldRemoteObject -ne $ExpectedOldTagObject) {
        throw "STOP: historical remote tag object changed."
    }

    if ($OldRemoteCommit -ne $ExpectedOldCommit) {
        throw "STOP: historical remote peeled commit changed."
    }

    # ------------------------------------------------------------
    # 4. New tag must still be absent locally AND remotely
    # ------------------------------------------------------------

    git -C $Repo show-ref --verify --quiet "refs/tags/$NewTag"
    $NewLocalExists = ($LASTEXITCODE -eq 0)

    $NewRemoteRaw = @(
        git -C $Repo ls-remote origin "refs/tags/$NewTag"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to query proposed remote tag."
    }

    $NewRemoteExists = (
        @(
            $NewRemoteRaw |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        ).Count -gt 0
    )

    if ($NewLocalExists) {
        throw "STOP: proposed v2.1.0 tag unexpectedly already exists locally."
    }

    if ($NewRemoteExists) {
        throw "STOP: proposed v2.1.0 tag unexpectedly already exists remotely."
    }

    # ------------------------------------------------------------
    # 5. CREATE NEW LOCAL ANNOTATED TAG
    # ------------------------------------------------------------

    Write-Host ""
    Write-Host "All pre-tag controls PASS."
    Write-Host "Creating new LOCAL annotated tag..."

    git -C $Repo tag -a $NewTag $ExpectedCommit -m $TagMessage

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: annotated tag creation failed."
    }

    # ------------------------------------------------------------
    # 6. Certify new tag
    # ------------------------------------------------------------

    $NewTagObject = (
        git -C $Repo rev-parse "$NewTag^{tag}"
    ).Trim().ToLowerInvariant()

    $NewTagCommit = (
        git -C $Repo rev-parse "$NewTag^{commit}"
    ).Trim().ToLowerInvariant()

    if ($NewTagCommit -ne $ExpectedCommit) {
        throw "STOP: new tag does not peel to publication commit."
    }

    # Reconfirm old tag did not move.
    $OldObjectAfter = (
        git -C $Repo rev-parse "$OldTag^{tag}"
    ).Trim().ToLowerInvariant()

    $OldCommitAfter = (
        git -C $Repo rev-parse "$OldTag^{commit}"
    ).Trim().ToLowerInvariant()

    if (
        $OldObjectAfter -ne $ExpectedOldTagObject -or
        $OldCommitAfter -ne $ExpectedOldCommit
    ) {
        throw "STOP: historical tag changed during new-tag creation."
    }

    $HeadAfter = (
        git -C $Repo rev-parse HEAD
    ).Trim().ToLowerInvariant()

    $StatusAfter = @(
        git -C $Repo status --porcelain=v1
    )

    if ($HeadAfter -ne $ExpectedCommit) {
        throw "STOP: branch HEAD changed unexpectedly."
    }

    if ($StatusAfter.Count -ne 0) {
        throw "STOP: working tree changed unexpectedly."
    }

    # ------------------------------------------------------------
    # 7. Evidence
    # ------------------------------------------------------------

    git -C $Repo show-ref --tags |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'ALL_LOCAL_TAG_REFS.txt') `
            -Encoding UTF8

    git -C $Repo cat-file -p $NewTagObject |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'NEW_TAG_OBJECT.txt') `
            -Encoding UTF8

    $Receipt = [ordered]@{
        Task = 'MSBF_PHASE_G_LOCAL_TAG_PRE_PUSH_CERTIFICATION'

        Repository = $Repo
        EvidenceDirectory = $EvidenceDir

        Branch = $Branch

        PublicationCommit = $ExpectedCommit
        PublicationTree = $ExpectedTree
        PublicationParent = $ExpectedParent

        RemoteMainBeforePush = $RemoteMain

        HistoricalTag = $OldTag
        HistoricalTagObject = $OldObjectAfter
        HistoricalTagPeeledCommit = $OldCommitAfter

        NewTag = $NewTag
        NewTagObject = $NewTagObject
        NewTagPeeledCommit = $NewTagCommit

        WorkingTreeClean = ($StatusAfter.Count -eq 0)

        CommitPushPerformed = $false
        TagPushPerformed = $false
        GitHubReleasePerformed = $false
        PublicationPerformed = $false

        PrePushGate = 'PASS'
    }

    $ReceiptPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_G_PRE_PUSH_GATE.json'

    $Receipt |
        ConvertTo-Json -Depth 6 |
        Set-Content `
            -LiteralPath $ReceiptPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "PRE_PUSH_GATE = PASS"
    Write-Host "============================================================"
    Write-Host "Publication commit:       $ExpectedCommit"
    Write-Host "Publication tree:         $ExpectedTree"
    Write-Host ""
    Write-Host "Historical v2.0.0 object: $OldObjectAfter"
    Write-Host "Historical v2.0.0 commit: $OldCommitAfter"
    Write-Host ""
    Write-Host "New v2.1.0 tag object:    $NewTagObject"
    Write-Host "New v2.1.0 peeled commit: $NewTagCommit"
    Write-Host ""
    Write-Host "Remote main before push:  $RemoteMain"
    Write-Host "Working tree clean:       $($StatusAfter.Count -eq 0)"
    Write-Host ""
    Write-Host "Commit pushed:            NO"
    Write-Host "Tag pushed:               NO"
    Write-Host "GitHub release:           NO"
    Write-Host "Publication:              NO"
    Write-Host ""
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "STOP HERE."
    Write-Host "Do not push anything yet."
}
```

The new annotated tag will naturally have a **new tag-object SHA** that we do not know in advance; that is expected because the annotated tag object includes metadata. What is invariant is that its **peeled commit must be exactly**:

```text
fd9f67b6d1d7fc848d315bcb696487b82c9a8046
```

and the historical tag must remain exactly:

```text
v2.0.0 tag object:
fcf32b615142a06075a7fccede26a97042ca8194

v2.0.0 peeled commit:
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

If this returns `PRE_PUSH_GATE = PASS`, stop and send me the output. The following phase will be the **first network mutation**: explicit push of `main`, verification, then explicit push of **only** `module-2-g3-v2.1.0`, followed by fresh remote binding checks. No force options and no historical-tag mutation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-74d03780-3170-42a6-b660-e90884c92920"></a>
## Andrew / user · C123-M00085

C123-M00085 · 2026-09-10T09:48:29.014000-04:00 · active path

Preceding visible parent: [C123-M00084](part-09.md#m-32a65a3e-f2b0-44f2-afec-a977d70b15b0)

**Editorial record note:** Attachment references: ALL_LOCAL_TAG_REFS.txt; MSBF_PHASE_G_PRE_PUSH_GATE.json; NEW_TAG_OBJECT.txt

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE G — STABLE TAG / PRE-PUSH CERTIFICATION
============================================================

All pre-tag controls PASS.
Creating new LOCAL annotated tag...

============================================================
PRE_PUSH_GATE = PASS
============================================================
Publication commit:       fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Publication tree:         fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb

Historical v2.0.0 object: fcf32b615142a06075a7fccede26a97042ca8194
Historical v2.0.0 commit: 500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

New v2.1.0 tag object:    cdef0c49eb37d0cc72444c0829c253e09eee050a
New v2.1.0 peeled commit: fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Remote main before push:  46fb1f9198475678edc9cabdeefd2f91a59e49c2
Working tree clean:       True

Commit pushed:            NO
Tag pushed:               NO
GitHub release:           NO
Publication:              NO

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_G_20260910T134637937Z_1aa0f38f\MSBF_PHASE_G_PRE_PUSH_GATE.json
============================================================

STOP HERE.
Do not push anything yet.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fc7b3729-32a1-47be-995f-da9f1ce287c8"></a>
## Assistant · C123-M00086

C123-M00086 · 2026-09-10T09:48:34.112559-04:00 · active path

Preceding visible parent: [C123-M00085](part-09.md#m-74d03780-3170-42a6-b660-e90884c92920)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase G is closed with an exact PASS.** The uploaded receipt confirms the local publication commit and certified R6 tree are unchanged, the working tree is clean, the historical `module-2-g3-v2.0.0` tag object/peeled commit remain intact, and the new annotated `module-2-g3-v2.1.0` tag exists locally and peels to the exact publication commit. [export reference: filecite | turn31file1 | L5-L16]

The local tag inventory also shows the old and new tag objects as distinct refs, with the new v2.1.0 object at `cdef0c49...` and the old v2.0.0 object still at `fcf32b61...`. [export reference: filecite | turn31file0 | L1-L3] The annotated tag itself targets commit `fd9f67b6...` and carries the intended `Module 2 / G3 v2.1.0 integrated successor` message. [export reference: filecite | turn31file2 | L1-L6]

So the controlling identities are now:

```text
PUBLICATION COMMIT
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

CERTIFIED R6 TREE
fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb

NEW v2.1.0 TAG OBJECT
cdef0c49eb37d0cc72444c0829c253e09eee050a

NEW v2.1.0 PEELED COMMIT
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

PRESERVED v2.0.0 TAG OBJECT
fcf32b615142a06075a7fccede26a97042ca8194

PRESERVED v2.0.0 PEELED COMMIT
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

The receipt correctly records that no commit push, tag push, GitHub release, or publication had occurred at the end of Phase G. [export reference: filecite | turn31file1 | L17-L21]

## Phase H — push `main`, then push only the new tag

This is the **first network mutation**. We will push the branch first, verify the remote branch, then push **only** `module-2-g3-v2.1.0`, then verify both new and historical remote tag identities.

Run this entire block in the same PowerShell window:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $Repo = 'D:\x\m'

    $ExpectedCommit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $ExpectedTree   = 'fa82f71a9aabf88d5ecbc16ba38cac8de8d83cbb'

    $OldTag = 'module-2-g3-v2.0.0'
    $ExpectedOldTagObject = 'fcf32b615142a06075a7fccede26a97042ca8194'
    $ExpectedOldTagCommit = '500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65'

    $NewTag = 'module-2-g3-v2.1.0'
    $ExpectedNewTagObject = 'cdef0c49eb37d0cc72444c0829c253e09eee050a'

    $Stamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddTHHmmssfffZ')
    $Suffix = [guid]::NewGuid().ToString('N').Substring(0,8)
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_H_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE H — PUSH COMMIT AND NEW STABLE TAG"
    Write-Host "============================================================"
    Write-Host "Repository: $Repo"
    Write-Host "Evidence:   $EvidenceDir"
    Write-Host ""

    # ------------------------------------------------------------
    # 1. Immediate local pre-push checks
    # ------------------------------------------------------------

    $Head = (git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $Tree = (git -C $Repo rev-parse 'HEAD^{tree}').Trim().ToLowerInvariant()
    $Branch = (git -C $Repo branch --show-current).Trim()
    $Status = @(git -C $Repo status --porcelain=v1)

    $NewTagObject = (
        git -C $Repo rev-parse "$NewTag^{tag}"
    ).Trim().ToLowerInvariant()

    $NewTagCommit = (
        git -C $Repo rev-parse "$NewTag^{commit}"
    ).Trim().ToLowerInvariant()

    $OldTagObject = (
        git -C $Repo rev-parse "$OldTag^{tag}"
    ).Trim().ToLowerInvariant()

    $OldTagCommit = (
        git -C $Repo rev-parse "$OldTag^{commit}"
    ).Trim().ToLowerInvariant()

    if ($Head -ne $ExpectedCommit) {
        throw "STOP: local HEAD differs from certified publication commit."
    }

    if ($Tree -ne $ExpectedTree) {
        throw "STOP: local tree differs from certified R6 tree."
    }

    if ($Branch -ne 'main') {
        throw "STOP: branch is not main."
    }

    if ($Status.Count -ne 0) {
        throw "STOP: working tree is not clean."
    }

    if ($NewTagObject -ne $ExpectedNewTagObject) {
        throw "STOP: new tag object changed."
    }

    if ($NewTagCommit -ne $ExpectedCommit) {
        throw "STOP: new tag no longer peels to publication commit."
    }

    if (
        $OldTagObject -ne $ExpectedOldTagObject -or
        $OldTagCommit -ne $ExpectedOldTagCommit
    ) {
        throw "STOP: historical tag changed locally."
    }

    # ------------------------------------------------------------
    # 2. Fresh remote state immediately before mutation
    # ------------------------------------------------------------

    $RemoteMainBeforeRaw = @(
        git -C $Repo ls-remote origin refs/heads/main
    )

    if ($LASTEXITCODE -ne 0 -or $RemoteMainBeforeRaw.Count -ne 1) {
        throw "STOP: unable to resolve remote main before push."
    }

    $RemoteMainBefore = (
        ($RemoteMainBeforeRaw[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $NewRemoteBefore = @(
        git -C $Repo ls-remote origin "refs/tags/$NewTag"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to query remote new tag before push."
    }

    if (@($NewRemoteBefore | Where-Object { $_.Trim() }).Count -ne 0) {
        throw "STOP: new tag unexpectedly already exists remotely."
    }

    # ------------------------------------------------------------
    # 3. Push MAIN explicitly
    # ------------------------------------------------------------

    Write-Host ""
    Write-Host "Pushing main explicitly..."

    $PushMainOutput = @(
        git -C $Repo push origin main 2>&1
    )

    $PushMainCode = $LASTEXITCODE

    $PushMainOutput |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'PUSH_MAIN_OUTPUT.txt') `
            -Encoding UTF8

    $PushMainOutput | ForEach-Object { Write-Host $_ }

    if ($PushMainCode -ne 0) {
        throw "STOP: main push failed. Do NOT push tag."
    }

    # ------------------------------------------------------------
    # 4. Verify REMOTE MAIN now equals publication commit
    # ------------------------------------------------------------

    $RemoteMainAfterRaw = @(
        git -C $Repo ls-remote origin refs/heads/main
    )

    if ($LASTEXITCODE -ne 0 -or $RemoteMainAfterRaw.Count -ne 1) {
        throw "STOP: unable to verify remote main after push."
    }

    $RemoteMainAfter = (
        ($RemoteMainAfterRaw[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if ($RemoteMainAfter -ne $ExpectedCommit) {
        throw "STOP: remote main does not equal publication commit after push."
    }

    Write-Host ""
    Write-Host "REMOTE MAIN VERIFIED:"
    Write-Host $RemoteMainAfter

    # ------------------------------------------------------------
    # 5. Reconfirm old remote tag BEFORE new-tag push
    # ------------------------------------------------------------

    $OldRemoteBefore = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$OldTag" `
            "refs/tags/$OldTag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to verify old remote tag."
    }

    $OldObjLine = @(
        $OldRemoteBefore |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))$" }
    )

    $OldCommitLine = @(
        $OldRemoteBefore |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))\^\{\}$" }
    )

    if (
        $OldObjLine.Count -ne 1 -or
        $OldCommitLine.Count -ne 1
    ) {
        throw "STOP: historical remote tag cannot be resolved exactly."
    }

    $OldRemoteObj = (
        ($OldObjLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $OldRemoteCommit = (
        ($OldCommitLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if (
        $OldRemoteObj -ne $ExpectedOldTagObject -or
        $OldRemoteCommit -ne $ExpectedOldTagCommit
    ) {
        throw "STOP: historical remote tag changed before new-tag push."
    }

    # ------------------------------------------------------------
    # 6. Push ONLY the new stable tag
    # ------------------------------------------------------------

    Write-Host ""
    Write-Host "Pushing ONLY $NewTag ..."

    $PushTagOutput = @(
        git -C $Repo push origin "refs/tags/$NewTag" 2>&1
    )

    $PushTagCode = $LASTEXITCODE

    $PushTagOutput |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'PUSH_NEW_TAG_OUTPUT.txt') `
            -Encoding UTF8

    $PushTagOutput | ForEach-Object { Write-Host $_ }

    if ($PushTagCode -ne 0) {
        throw "STOP: tag push failed."
    }

    # ------------------------------------------------------------
    # 7. Fresh remote verification of new tag
    # ------------------------------------------------------------

    $NewRemoteAfter = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$NewTag" `
            "refs/tags/$NewTag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to verify new remote tag."
    }

    $NewObjLine = @(
        $NewRemoteAfter |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($NewTag))$" }
    )

    $NewCommitLine = @(
        $NewRemoteAfter |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($NewTag))\^\{\}$" }
    )

    if (
        $NewObjLine.Count -ne 1 -or
        $NewCommitLine.Count -ne 1
    ) {
        throw "STOP: new remote annotated tag did not resolve exactly."
    }

    $NewRemoteObj = (
        ($NewObjLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $NewRemoteCommit = (
        ($NewCommitLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if ($NewRemoteObj -ne $ExpectedNewTagObject) {
        throw "STOP: remote new-tag object differs from local certified tag object."
    }

    if ($NewRemoteCommit -ne $ExpectedCommit) {
        throw "STOP: remote new tag does not peel to publication commit."
    }

    # ------------------------------------------------------------
    # 8. Final old-tag preservation check AFTER new-tag push
    # ------------------------------------------------------------

    $OldRemoteAfter = @(
        git -C $Repo ls-remote origin `
            "refs/tags/$OldTag" `
            "refs/tags/$OldTag^{}"
    )

    $OldObjAfterLine = @(
        $OldRemoteAfter |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))$" }
    )

    $OldCommitAfterLine = @(
        $OldRemoteAfter |
        Where-Object { $_ -match "refs/tags/$([regex]::Escape($OldTag))\^\{\}$" }
    )

    $OldRemoteObjAfter = (
        ($OldObjAfterLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $OldRemoteCommitAfter = (
        ($OldCommitAfterLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if (
        $OldRemoteObjAfter -ne $ExpectedOldTagObject -or
        $OldRemoteCommitAfter -ne $ExpectedOldTagCommit
    ) {
        throw "STOP: historical tag changed after new-tag push."
    }

    # ------------------------------------------------------------
    # 9. Final branch/worktree check
    # ------------------------------------------------------------

    $HeadAfter = (git -C $Repo rev-parse HEAD).Trim().ToLowerInvariant()
    $StatusAfter = @(git -C $Repo status --porcelain=v1)

    if ($HeadAfter -ne $ExpectedCommit) {
        throw "STOP: local HEAD changed unexpectedly."
    }

    if ($StatusAfter.Count -ne 0) {
        throw "STOP: working tree is no longer clean."
    }

    # ------------------------------------------------------------
    # 10. Evidence receipt
    # ------------------------------------------------------------

    $Receipt = [ordered]@{
        Task = 'MSBF_PHASE_H_REMOTE_COMMIT_TAG_BINDING'

        Repository = $Repo
        EvidenceDirectory = $EvidenceDir

        PublicationCommit = $ExpectedCommit
        PublicationTree = $ExpectedTree

        RemoteMainBeforePush = $RemoteMainBefore
        RemoteMainAfterPush = $RemoteMainAfter

        HistoricalTag = $OldTag
        HistoricalTagObjectAfterPush = $OldRemoteObjAfter
        HistoricalTagPeeledCommitAfterPush = $OldRemoteCommitAfter

        NewTag = $NewTag
        NewTagObjectRemote = $NewRemoteObj
        NewTagPeeledCommitRemote = $NewRemoteCommit

        WorkingTreeClean = ($StatusAfter.Count -eq 0)

        MainPushPerformed = $true
        NewTagPushPerformed = $true
        ForcePushPerformed = $false
        HistoricalTagMutationPerformed = $false

        GitHubReleasePerformed = $false
        PublicationEventComplete = $false

        RemoteBinding = 'PASS'
    }

    $ReceiptPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_H_REMOTE_BINDING.json'

    $Receipt |
        ConvertTo-Json -Depth 6 |
        Set-Content `
            -LiteralPath $ReceiptPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "REMOTE_BINDING = PASS"
    Write-Host "============================================================"
    Write-Host "Remote main:             $RemoteMainAfter"
    Write-Host ""
    Write-Host "New v2.1.0 tag object:   $NewRemoteObj"
    Write-Host "New v2.1.0 peeled commit:$NewRemoteCommit"
    Write-Host ""
    Write-Host "Old v2.0.0 tag object:   $OldRemoteObjAfter"
    Write-Host "Old v2.0.0 peeled commit:$OldRemoteCommitAfter"
    Write-Host ""
    Write-Host "Working tree clean:      $($StatusAfter.Count -eq 0)"
    Write-Host ""
    Write-Host "GitHub release created:  NO"
    Write-Host "Publication event:       NOT COMPLETE"
    Write-Host ""
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "STOP HERE."
    Write-Host "Do not create the GitHub release yet."
}
```

A successful Phase H should end with:

```text
REMOTE_BINDING = PASS

Remote main:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

New v2.1.0 tag object:
cdef0c49eb37d0cc72444c0829c253e09eee050a

New v2.1.0 peeled commit:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Old v2.0.0 tag object:
fcf32b615142a06075a7fccede26a97042ca8194

Old v2.0.0 peeled commit:
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

If the **main push succeeds but the tag push fails**, stop and return the output; do not retry blindly. If both pass, we will have completed the remote Git binding but **not yet the GitHub release publication event**.

After Phase H passes, the next step will be **Phase I**: create the GitHub release attached to the exact `module-2-g3-v2.1.0` tag and upload exactly the four locked ZIPs—no R6 candidate, private controls, history evidence, or other carrier.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8d448489-d15d-4d00-8e66-9d23247cce02"></a>
## Andrew / user · C123-M00087

C123-M00087 · 2026-09-10T09:52:32.523000-04:00 · active path

Preceding visible parent: [C123-M00086](part-09.md#m-fc7b3729-32a1-47be-995f-da9f1ce287c8)

**Editorial record note:** Attachment references: MSBF_PHASE_H_REMOTE_BINDING.json; PUSH_MAIN_OUTPUT.txt; PUSH_NEW_TAG_OUTPUT.txt

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE H — PUSH COMMIT AND NEW STABLE TAG
============================================================
Repository: D:\x\m
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_H_20260910T135054341Z_007dc7ce


Pushing main explicitly...
info: please complete authentication in your browser...
To https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
   46fb1f9..fd9f67b  main -> main

REMOTE MAIN VERIFIED:
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Pushing ONLY module-2-g3-v2.1.0 ...
To https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
 * [new tag]         module-2-g3-v2.1.0 -> module-2-g3-v2.1.0

============================================================
REMOTE_BINDING = PASS
============================================================
Remote main:             fd9f67b6d1d7fc848d315bcb696487b82c9a8046

New v2.1.0 tag object:   cdef0c49eb37d0cc72444c0829c253e09eee050a
New v2.1.0 peeled commit:fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Old v2.0.0 tag object:   fcf32b615142a06075a7fccede26a97042ca8194
Old v2.0.0 peeled commit:500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

Working tree clean:      True

GitHub release created:  NO
Publication event:       NOT COMPLETE

Receipt: D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_H_20260910T135054341Z_007dc7ce\MSBF_PHASE_H_REMOTE_BINDING.json
============================================================

STOP HERE.
Do not create the GitHub release yet.
<!-- END_SOURCE_MESSAGE -->


<a id="m-df630cdb-0ef5-4ce2-8617-cf773478f1d0"></a>
## Assistant · C123-M00088

C123-M00088 · 2026-09-10T09:52:36.138749-04:00 · active path

Preceding visible parent: [C123-M00087](part-09.md#m-8d448489-d15d-4d00-8e66-9d23247cce02)

<!-- BEGIN_SOURCE_MESSAGE -->
**Phase H is closed with an exact PASS.** Remote `main` now equals the certified publication commit, the new v2.1.0 annotated tag is on the remote and peels to that same commit, and the historical v2.0.0 tag object/target remain unchanged. The working tree is clean, no force operation occurred, and the receipt correctly records that the GitHub release itself has not yet been created. [export reference: filecite | turn32file0 | L5-L22] The underlying push evidence independently shows the `main` update and creation of only the new v2.1.0 tag. [export reference: filecite | turn32file1 | L1-L2] [export reference: filecite | turn32file2 | L1-L2]

So the current state is:

```text
REMOTE_BINDING = PASS

Remote main
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

New v2.1.0 tag object
cdef0c49eb37d0cc72444c0829c253e09eee050a

New v2.1.0 peeled commit
fd9f67b6d1d7fc848d315bcb696487b82c9a8046

Historical v2.0.0 tag object
fcf32b615142a06075a7fccede26a97042ca8194

Historical v2.0.0 peeled commit
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

GitHub release
NOT YET CREATED
```

## Phase I — create the GitHub release

This is the actual **release-publication event**. The block below uses GitHub CLI, but it first fails closed if `gh` is unavailable/not authenticated, if the release already exists, if the remote tag no longer matches our certified identity, or if any of the four locked ZIPs differs from its expected filename, size, or SHA-256.

It uploads **exactly four assets**. It does **not** upload R6, any overlay, private evidence, chat export, audit carrier, or checkpoint backup.

Run this in the same PowerShell window:

```powershell
& {
    $ErrorActionPreference = 'Stop'

    $RepoDir = 'D:\x\m'
    $AssetDir = 'D:\MSBF_ZIP_FILES_091026'

    $GitHubRepo = 'andrew-goad/merchant-sales-based-financing-strategy-simulator'
    $Tag = 'module-2-g3-v2.1.0'

    $ExpectedCommit = 'fd9f67b6d1d7fc848d315bcb696487b82c9a8046'
    $ExpectedTagObject = 'cdef0c49eb37d0cc72444c0829c253e09eee050a'

    $ReleaseTitle = 'Module 2 / G3 v2.1.0 — Integrated Successor'

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
    $EvidenceDir = "D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_I_${Stamp}_${Suffix}"

    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "MSBF PHASE I — CREATE GITHUB RELEASE"
    Write-Host "============================================================"
    Write-Host "Repository: $GitHubRepo"
    Write-Host "Tag:        $Tag"
    Write-Host "Evidence:   $EvidenceDir"
    Write-Host ""

    # ------------------------------------------------------------
    # 1. GitHub CLI availability / authentication
    # ------------------------------------------------------------

    $Gh = Get-Command gh.exe -ErrorAction SilentlyContinue

    if (-not $Gh) {
        throw @"
STOP: GitHub CLI (gh.exe) was not found.

Do not create the release manually yet.
Return this message and I will give you the bounded GitHub-UI procedure.
"@
    }

    Write-Host "GitHub CLI:"
    & $Gh.Source --version

    Write-Host ""
    Write-Host "Checking GitHub authentication..."

    $AuthOutput = @(& $Gh.Source auth status 2>&1)
    $AuthCode = $LASTEXITCODE

    $AuthOutput |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GH_AUTH_STATUS.txt') `
            -Encoding UTF8

    $AuthOutput | ForEach-Object { Write-Host $_ }

    if ($AuthCode -ne 0) {
        throw "STOP: GitHub CLI is not authenticated. Do not create the release."
    }

    # ------------------------------------------------------------
    # 2. Reconfirm local repository state
    # ------------------------------------------------------------

    $Head = (git -C $RepoDir rev-parse HEAD).Trim().ToLowerInvariant()
    $TreeStatus = @(git -C $RepoDir status --porcelain=v1)

    if ($Head -ne $ExpectedCommit) {
        throw "STOP: local HEAD differs from publication commit."
    }

    if ($TreeStatus.Count -ne 0) {
        throw "STOP: working tree is not clean."
    }

    # ------------------------------------------------------------
    # 3. Reconfirm remote tag identities immediately before release
    # ------------------------------------------------------------

    $RemoteTag = @(
        git -C $RepoDir ls-remote origin `
            "refs/tags/$Tag" `
            "refs/tags/$Tag^{}"
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: unable to query remote v2.1.0 tag."
    }

    $TagObjectLine = @(
        $RemoteTag |
        Where-Object {
            $_ -match "refs/tags/$([regex]::Escape($Tag))$"
        }
    )

    $TagCommitLine = @(
        $RemoteTag |
        Where-Object {
            $_ -match "refs/tags/$([regex]::Escape($Tag))\^\{\}$"
        }
    )

    if (
        $TagObjectLine.Count -ne 1 -or
        $TagCommitLine.Count -ne 1
    ) {
        throw "STOP: remote annotated tag did not resolve exactly."
    }

    $RemoteTagObject = (
        ($TagObjectLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    $RemoteTagCommit = (
        ($TagCommitLine[0] -split '\s+')[0]
    ).ToLowerInvariant()

    if ($RemoteTagObject -ne $ExpectedTagObject) {
        throw "STOP: remote tag object changed."
    }

    if ($RemoteTagCommit -ne $ExpectedCommit) {
        throw "STOP: remote tag target changed."
    }

    # ------------------------------------------------------------
    # 4. Fresh four-asset identity verification
    # ------------------------------------------------------------

    $AssetRows = New-Object System.Collections.Generic.List[object]

    foreach ($a in $Assets) {

        $Path = Join-Path $AssetDir $a.Name

        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "STOP: release asset missing: $Path"
        }

        $Item = Get-Item -LiteralPath $Path
        $Hash = (
            Get-FileHash -LiteralPath $Path -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        $Pass = (
            $Item.Name -ceq $a.Name -and
            $Item.Length -eq $a.Bytes -and
            $Hash -ceq $a.Sha256
        )

        $AssetRows.Add([pscustomobject]@{
            Name = $Item.Name
            FullPath = $Item.FullName
            ExpectedBytes = $a.Bytes
            ActualBytes = $Item.Length
            ExpectedSha256 = $a.Sha256
            ActualSha256 = $Hash
            Status = if ($Pass) { 'PASS' } else { 'FAIL' }
        })

        if (-not $Pass) {
            throw "STOP: release asset identity mismatch: $($a.Name)"
        }
    }

    $AssetRows |
        Export-Csv `
            -LiteralPath (Join-Path $EvidenceDir 'RELEASE_ASSET_UPLOAD_PREFLIGHT.csv') `
            -NoTypeInformation `
            -Encoding UTF8

    Write-Host ""
    $AssetRows |
        Select-Object Name,ActualBytes,Status |
        Format-Table -AutoSize |
        Out-Host

    # ------------------------------------------------------------
    # 5. Release must NOT already exist
    # ------------------------------------------------------------

    & $Gh.Source release view $Tag `
        --repo $GitHubRepo `
        --json tagName `
        *> $null

    $ExistingRelease = ($LASTEXITCODE -eq 0)

    if ($ExistingRelease) {
        throw "STOP: a GitHub release already exists for $Tag. Do not overwrite or edit it automatically."
    }

    # ------------------------------------------------------------
    # 6. Create exact release notes
    # ------------------------------------------------------------

    $NotesPath = Join-Path $EvidenceDir 'RELEASE_NOTES_v2.1.0.md'

    @'
# Module 2 / G3 v2.1.0 — Integrated Successor

Merchant evidence → governed structure search → explicit authority → funded-account lifecycle → explainable portfolio intelligence.

This release activates the accepted integrated successor for the MSBF Module 1 / Module 2 portfolio and preserves the historical v2.0.0 record.

## What this release demonstrates

The portfolio connects source-owned merchant evidence and capacity analysis to governed structure search, explicit decision authority, funded-account monitoring, intervention logic, source certification, and executive portfolio intelligence.

Representative governed populations include:

- **750 synthetic merchants**
- **1,500 application-scenario paths**
- **6,519 reportable structures**
- **130 funded scenario paths**
- **15,600 monitoring rows**
- **70/70 G3-v2 source-certification controls**

## Module 2 / G3 successor

The successor incorporates the corrected governed structure-search and authority model, including the funded lifecycle through M2.4–M2.10, retained-final R26 monitoring calibration, bounded M2.11 strategy/account-treatment comparison, M2.12 servicing and reconciliation, and G3-v2 source certification.

The repository documentation distinguishes stage ownership, requirements, validation evidence, historical records, and the current reading path.

## Power BI and explainability

The accepted Power BI publication covers **P01–P04**.

A central differentiator is **P03 Application Journey explainability**: business-facing narratives connect merchant operating evidence, risk/economics assessment, and final decision authority while retaining the technical rationale underneath.

Curated examples illustrate distinct governed outcomes, including cases where missing evidence cannot be repaired through terms and cases where permissible structure changes can repair a structure problem.

## Cohort and visual documentation

The publication includes the accepted 750-merchant cohort report, enterprise / Module 1 / Module 2 lineage visuals, executive and teaching material, and the two end-to-end proof posters:

- **How the Governed Decision Engine Works**
- **What Happens After the Decision**

## Reproducibility boundary

The public repository supports analytical reading, source study, delivered validation/reconciliation procedures, and the accepted Power BI artifact.

The qualified Windows Route-B scope remains limited to **portable checkpoint restore plus isolated retained-final M2.11 / M2.12 / G3-v2 replay**.

It does **not** establish a qualified arbitrary-new-campaign end-to-end runner. Route D remains **NOT_QUALIFIED**. Larger Campaign Scale execution and streamlined generalized orchestration remain separate future work.

## Scope

This portfolio uses **deterministic synthetic / non-production data**.

This release does not claim production deployment, real customer or real-funds activity, causal impact, CECL implementation, audited realized profitability, regulatory approval, or autonomous production operation.

## Release assets

The four attached ZIPs preserve the accepted identities for:

1. retained-final R26 runtime / reproducibility support;
2. Power BI publication support;
3. the approved visual publication family;
4. the accepted cohort report package.

For the current reading path, start with the repository README and Documentation Portal.
'@ |
        Set-Content `
            -LiteralPath $NotesPath `
            -Encoding UTF8

    # ------------------------------------------------------------
    # 7. CREATE GITHUB RELEASE
    # ------------------------------------------------------------

    Write-Host ""
    Write-Host "All release-publication prechecks PASS."
    Write-Host "Creating GitHub release and uploading EXACTLY four assets..."
    Write-Host ""

    $AssetPaths = @(
        $Assets |
        ForEach-Object {
            Join-Path $AssetDir $_.Name
        }
    )

    $CreateOutput = @(
        & $Gh.Source release create $Tag `
            --repo $GitHubRepo `
            --verify-tag `
            --title $ReleaseTitle `
            --notes-file $NotesPath `
            @AssetPaths 2>&1
    )

    $CreateCode = $LASTEXITCODE

    $CreateOutput |
        Set-Content `
            -LiteralPath (Join-Path $EvidenceDir 'GH_RELEASE_CREATE_OUTPUT.txt') `
            -Encoding UTF8

    $CreateOutput | ForEach-Object { Write-Host $_ }

    if ($CreateCode -ne 0) {
        throw @"
STOP: GitHub release creation returned a failure.

Do NOT retry automatically.
Do NOT delete the tag.
Do NOT recreate the release.

Return the complete output for reconciliation.
"@
    }

    # ------------------------------------------------------------
    # 8. Fresh hosted release metadata verification
    # ------------------------------------------------------------

    $ReleaseJsonPath = Join-Path $EvidenceDir 'GH_RELEASE_VIEW.json'

    $ViewRaw = @(
        & $Gh.Source release view $Tag `
            --repo $GitHubRepo `
            --json `
            tagName,name,url,isDraft,isPrerelease,publishedAt,assets
    )

    if ($LASTEXITCODE -ne 0) {
        throw "STOP: release creation may have succeeded, but fresh release metadata could not be retrieved."
    }

    $ViewText = $ViewRaw -join "`n"

    $ViewText |
        Set-Content `
            -LiteralPath $ReleaseJsonPath `
            -Encoding UTF8

    $Release = $ViewText | ConvertFrom-Json

    if ($Release.tagName -cne $Tag) {
        throw "STOP: hosted release tag differs from expected tag."
    }

    if ($Release.isDraft -eq $true) {
        throw "STOP: release exists but is still a draft."
    }

    if ($Release.isPrerelease -eq $true) {
        throw "STOP: release was unexpectedly created as a prerelease."
    }

    $HostedAssetNames = @($Release.assets | ForEach-Object name)

    $MissingAssets = @(
        $Assets.Name |
        Where-Object { $_ -notin $HostedAssetNames }
    )

    $UnexpectedAssets = @(
        $HostedAssetNames |
        Where-Object { $_ -notin $Assets.Name }
    )

    if (
        $MissingAssets.Count -ne 0 -or
        $UnexpectedAssets.Count -ne 0 -or
        $HostedAssetNames.Count -ne 4
    ) {
        throw @"
STOP: hosted release asset-name population is not exactly four expected ZIPs.

Do not delete or modify the release automatically.
Return the metadata for bounded reconciliation.
"@
    }

    # ------------------------------------------------------------
    # 9. Receipt
    # ------------------------------------------------------------

    $Receipt = [ordered]@{
        Task = 'MSBF_PHASE_I_GITHUB_RELEASE_PUBLICATION'

        GitHubRepository = $GitHubRepo

        ReleaseTag = $Tag
        ReleaseTitle = $Release.name
        ReleaseUrl = $Release.url
        PublishedAt = $Release.publishedAt

        PublicationCommit = $ExpectedCommit
        TagObject = $RemoteTagObject
        TagPeeledCommit = $RemoteTagCommit

        HostedAssetCount = $HostedAssetNames.Count
        HostedAssetNames = $HostedAssetNames

        MissingExpectedAssets = $MissingAssets
        UnexpectedAssets = $UnexpectedAssets

        ReleaseIsDraft = $Release.isDraft
        ReleaseIsPrerelease = $Release.isPrerelease

        GitCommitPushAlreadyComplete = $true
        GitTagPushAlreadyComplete = $true
        GitHubReleasePerformed = $true

        HostedHashVerificationPerformed = $false
        WindowsNativeHostedExtractionPerformed = $false
        AnonymousNavigationVerificationPerformed = $false

        PublicationEvent = 'COMPLETE'
        ReleaseClosure = 'PENDING_POST_PUBLICATION_VERIFICATION'
    }

    $ReceiptPath = Join-Path $EvidenceDir `
        'MSBF_PHASE_I_PUBLICATION_EVENT.json'

    $Receipt |
        ConvertTo-Json -Depth 8 |
        Set-Content `
            -LiteralPath $ReceiptPath `
            -Encoding UTF8

    Write-Host ""
    Write-Host "============================================================"
    Write-Host "PUBLICATION_EVENT = COMPLETE"
    Write-Host "============================================================"
    Write-Host "Release title: $($Release.name)"
    Write-Host "Release tag:   $($Release.tagName)"
    Write-Host "Release URL:   $($Release.url)"
    Write-Host "Published at:  $($Release.publishedAt)"
    Write-Host ""
    Write-Host "Hosted assets: $($HostedAssetNames.Count)"
    $HostedAssetNames | ForEach-Object {
        Write-Host "  $_"
    }
    Write-Host ""
    Write-Host "Hosted hashes:              NOT YET VERIFIED"
    Write-Host "Windows hosted extraction:  NOT YET VERIFIED"
    Write-Host "Anonymous navigation:       NOT YET VERIFIED"
    Write-Host ""
    Write-Host "RELEASE CLOSURE = PENDING"
    Write-Host "Receipt: $ReceiptPath"
    Write-Host "============================================================"
    Write-Host ""
    Write-Host "STOP HERE."
    Write-Host "Do not modify or re-upload release assets."
    Write-Host "Return the console output and publication-event receipt."
}
```

### Two possible outcomes

If `gh.exe` is **not installed** or isn't authenticated, the block stops **before publication**. Send me that message and I'll give you the exact bounded GitHub web-interface procedure instead. Do not improvise asset selection.

If it succeeds, we should see:

```text
PUBLICATION_EVENT = COMPLETE

Release tag:
module-2-g3-v2.1.0

Hosted assets:
4

Hosted hashes:             NOT YET VERIFIED
Windows hosted extraction: NOT YET VERIFIED
Anonymous navigation:      NOT YET VERIFIED

RELEASE CLOSURE = PENDING
```

That distinction matters. **Creating the GitHub release will complete the publication event, but it will not complete release closure.** The next mandatory phases will download the actual GitHub-hosted copies into a clean Windows directory, prove all four SHA-256/size identities, perform Windows-native extraction on those hosted files, and then verify the public repository/navigation anonymously.

Do not download the assets manually yet after Phase I. Once you return its result, I'll give you a controlled hosted-download block that cannot accidentally substitute the local originals.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3710281a-292b-4b9e-9617-d558c7bc3c74"></a>
## Andrew / user · C123-M00089

C123-M00089 · 2026-09-10T09:55:31.329000-04:00 · active path

Preceding visible parent: [C123-M00088](part-09.md#m-df630cdb-0ef5-4ce2-8617-cf773478f1d0)

<!-- BEGIN_SOURCE_MESSAGE -->
============================================================
MSBF PHASE I — CREATE GITHUB RELEASE
============================================================
Repository: andrew-goad/merchant-sales-based-financing-strategy-simulator
Tag:        module-2-g3-v2.1.0
Evidence:   D:\MSBF_RELEASE_ENGINEERING_EVIDENCE\PHASE_I_20260910T135512047Z_403c896f

Exception:
Line |
  60 |          throw @"
     |          ~~~~~~~~
     | STOP: GitHub CLI (gh.exe) was not found.

Do not create the release manually yet.
Return this message and I will give you the bounded GitHub-UI procedure.
<!-- END_SOURCE_MESSAGE -->


<a id="m-28044717-851a-4964-9b5c-7c931f08fdab"></a>
## Assistant · C123-M00090

C123-M00090 · 2026-09-10T09:55:35.328057-04:00 · active path

Preceding visible parent: [C123-M00089](part-09.md#m-3710281a-292b-4b9e-9617-d558c7bc3c74)

<!-- BEGIN_SOURCE_MESSAGE -->
Phase I stopped exactly where it should have: **before publication**, because `gh.exe` is not installed. Nothing about the repository, tag, or release assets changed.

We can now use the bounded GitHub web interface path. Keep the PowerShell window open, but you do not need to run anything else there yet.

Open this page in your browser:

`https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/new`

Then use these exact values:

- **Choose a tag:** `module-2-g3-v2.1.0`
- **Target:** leave it on the commit associated with that tag; do not retarget it
- **Release title:** `Module 2 / G3 v2.1.0 — Integrated Successor`
- **Do not mark as prerelease**
- **Do not create a new tag in the UI**
- **Do not upload R6**
- **Upload exactly these four ZIPs from `D:\MSBF_ZIP_FILES_091026`:**
  - `MSBF_R26_R3_RETAINED_FINAL_RESUME_RUNTIME_20260902.zip`
  - `MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip`
  - `MSBF_Visual_Publication_Candidate_R1_20260909.zip`
  - `MSBF_Cohort_R3_Editorial_Patch_R1_20260908.zip`

Use these release notes:

> Merchant evidence → governed structure search → explicit authority → funded-account lifecycle → explainable portfolio intelligence.
>
> This release activates the accepted integrated successor for the MSBF Module 1 / Module 2 portfolio and preserves the historical v2.0.0 record.
>
> Representative governed populations include 750 synthetic merchants, 1,500 application-scenario paths, 6,519 reportable structures, 130 funded scenario paths, 15,600 monitoring rows, and 70/70 G3-v2 source-certification controls.
>
> The successor incorporates the corrected governed structure-search and authority model, funded lifecycle through M2.4–M2.10, retained-final R26 monitoring calibration, bounded M2.11 strategy/account-treatment comparison, M2.12 servicing and reconciliation, and G3-v2 source certification.
>
> The accepted Power BI publication covers P01–P04. A central differentiator is P03 Application Journey explainability: business-facing narratives connect merchant operating evidence, risk/economics assessment, and final decision authority while retaining technical rationale underneath.
>
> The publication also includes the accepted 750-merchant cohort report, enterprise / Module 1 / Module 2 lineage visuals, executive and teaching material, and the two end-to-end proof posters, “How the Governed Decision Engine Works” and “What Happens After the Decision.”
>
> The qualified Windows Route-B scope remains limited to portable checkpoint restore plus isolated retained-final M2.11 / M2.12 / G3-v2 replay. It does not establish a qualified arbitrary-new-campaign end-to-end runner. Route D remains NOT_QUALIFIED.
>
> This portfolio uses deterministic synthetic / non-production data. This release does not claim production deployment, real customer or real-funds activity, causal impact, CECL implementation, audited realized profitability, regulatory approval, or autonomous production operation.
>
> Start with the repository README and Documentation Portal for the current reading path.

Before you click **Publish release**, visually confirm all four filenames exactly. Then publish once.

After publication, send me:
- the release URL,
- the four displayed asset filenames,
- the published timestamp if visible,
- and ideally a screenshot of the release page.

Do **not** download or modify anything yet after publishing. The next step is the mandatory hosted-download verification against the actual GitHub-hosted copies.
<!-- END_SOURCE_MESSAGE -->


<a id="m-606551d3-584a-44f8-9f3b-cd5e2e53a7ec"></a>
## Andrew / user · C123-M00091

C123-M00091 · 2026-09-10T10:01:30.415000-04:00 · active path

Preceding visible parent: [C123-M00090](part-09.md#m-28044717-851a-4964-9b5c-7c931f08fdab)

**Editorial record note:** Attachment references: Module 2 - G3 v2.1.0 - Integrated Successor.pdf

<!-- BEGIN_SOURCE_MESSAGE -->
https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/releases/tag/module-2-g3-v2.1.0
<!-- END_SOURCE_MESSAGE -->
