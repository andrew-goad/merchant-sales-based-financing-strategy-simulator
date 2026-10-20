# PostgreSQL M1.14 Execution

Part 36 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-35.md)
[Next part](part-37.md)

<a id="m-57bfa47f-f570-4012-8b91-73492087b093"></a>
## Assistant · C072-M00514

C072-M00514 · 2026-08-14T23:21:56.399578-04:00 · active path

Preceding visible parent: [C072-M00513](part-35.md#m-bbb210f9-d30b-446e-b650-18b063a754d9)

<!-- BEGIN_SOURCE_MESSAGE -->
Good — if the automated script completed successfully, the difficult packaging/extraction problem is behind us. **From this point forward, use only the extracted repository at:**

```text
C:\x\m
```

Keep your older repository at:

```text
C:\Git\merchant-sales-based-financing-strategy-simulator
```

untouched as a backup.

The governing publication runbook expects the local validator to report **1,930 governed manifest files and 12 Module 2 stage folders**, then after staging exactly **1,083 added files, 20 modified files, and 0 deleted files**. [export reference: filecite | turn213file0 | L84-L118] [export reference: filecite | turn213file0 | L149-L169]

I would now proceed exactly as follows.

---

# 1. Open PowerShell in the new repository

Open PowerShell and paste:

```powershell
Set-Location "C:\x\m"
```

Then confirm where you are:

```powershell
Get-Location
```

You should see:

```text
Path
----
C:\x\m
```

Do **not** continue from your old `C:\Git\...` folder.

---

# 2. Confirm this really is the Git repository we intend to publish

Paste:

```powershell
git status --short --branch
git branch --show-current
git remote -v
git log -1 --oneline --decorate
```

You want to confirm three things:

```text
Current branch: main
Remote: https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
Current baseline commit begins with: f43ea8c
```

It is **normal** for `git status` to show lots of modified and untracked files right now. Those are the Module 2/G3 release changes we intend to publish.

---

# 3. Make sure GitHub `main` has not changed since we built the package

Paste this entire block:

```powershell
git fetch origin --tags --prune

if ($LASTEXITCODE -ne 0) {
    throw "git fetch failed. Stop here."
}

$ExpectedBase = "f43ea8cb87523f477142fba2acea1be254c69e1a"

$LocalBase = (git rev-parse HEAD).Trim()
$RemoteBase = (git rev-parse origin/main).Trim()

Write-Host ""
Write-Host "Expected base: $ExpectedBase"
Write-Host "Local base:    $LocalBase"
Write-Host "Remote main:   $RemoteBase"

if ($LocalBase -ne $ExpectedBase) {
    throw "The extracted package is not on the expected baseline. Stop here."
}

if ($RemoteBase -ne $ExpectedBase) {
    throw "GitHub main changed since this package was built. Stop here."
}

Write-Host ""
Write-Host "BASELINE RECONCILIATION PASS" -ForegroundColor Green
```

### What you want to see

All three hashes should be:

```text
f43ea8cb87523f477142fba2acea1be254c69e1a
```

Then:

```text
BASELINE RECONCILIATION PASS
```

**If `Remote main` is different, stop and send me the PowerShell output. Do not pull or merge anything.**

---

# 4. Confirm the expected unpublished changes are present

Paste:

```powershell
$Status = git status --porcelain=v1

$ModifiedCount = @(
    $Status | Where-Object { $_ -match '^ M ' }
).Count

$UntrackedCount = @(
    $Status | Where-Object { $_ -match '^\?\? ' }
).Count

$DeletedCount = @(
    $Status | Where-Object { $_ -match '^( D|D )' }
).Count

Write-Host ""
Write-Host "Modified tracked files:   $ModifiedCount"
Write-Host "Untracked paths:          $UntrackedCount"
Write-Host "Deleted tracked files:    $DeletedCount"

if ($ModifiedCount -ne 20) {
    throw "Expected 20 modified tracked files."
}

if ($UntrackedCount -ne 15) {
    throw "Expected 15 collapsed untracked paths."
}

if ($DeletedCount -ne 0) {
    throw "Tracked deletions detected."
}

Write-Host ""
Write-Host "PRE-STAGING STATUS PASS" -ForegroundColor Green
```

Expected:

```text
Modified tracked files:   20
Untracked paths:          15
Deleted tracked files:    0

PRE-STAGING STATUS PASS
```

The `15` untracked entries are mostly whole directories. Once staged, they expand into many individual files.

---

# 5. Confirm the Publication Integrity workflow exists

Paste:

```powershell
Test-Path ".github\workflows\publication_integrity.yml"
```

Expected:

```text
True
```

Then:

```powershell
git status --short ".github/workflows/publication_integrity.yml"
```

Expected:

```text
(no output)
```

That means we preserved the existing GitHub Action and are not changing or deleting it.

---

# 6. Run the full local publication validator again

Even though the extraction script already ran it successfully, run it once more immediately before staging.

Try:

```powershell
python tools\validate_public_release.py
```

If Windows says `python` is not recognized, use:

```powershell
py -3 tools\validate_public_release.py
```

Expected:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Those are the governing expected results for this package. [export reference: filecite | turn213file0 | L92-L118]

If anything says `FAIL`, **stop and send me the exact output**.

---

# 7. Run Git's whitespace/error check

Paste:

```powershell
git diff --check
```

Expected:

```text
(no output)
```

No output is a PASS.

Then:

```powershell
if ($LASTEXITCODE -ne 0) {
    throw "git diff --check failed."
} else {
    Write-Host "GIT DIFF CHECK PASS" -ForegroundColor Green
}
```

---

# 8. Confirm the root manifests have the correct counts

Paste:

```powershell
$ManifestCsvCount = (Import-Csv .\MANIFEST.csv).Count

$ManifestJson = Get-Content .\manifest.json -Raw | ConvertFrom-Json
$ManifestJsonCount = $ManifestJson.file_count

Write-Host ""
Write-Host "MANIFEST.csv records: $ManifestCsvCount"
Write-Host "manifest.json count:  $ManifestJsonCount"

if ($ManifestCsvCount -ne 1930) {
    throw "MANIFEST.csv should contain 1930 records."
}

if ($ManifestJsonCount -ne 1930) {
    throw "manifest.json should report 1930 records."
}

Write-Host ""
Write-Host "ROOT MANIFEST COUNT PASS" -ForegroundColor Green
```

Expected:

```text
MANIFEST.csv records: 1930
manifest.json count:  1930

ROOT MANIFEST COUNT PASS
```

Now verify the GitHub workflow is actually included in the governed manifest:

```powershell
Select-String `
    -Path .\MANIFEST.csv `
    -Pattern '^\.github/workflows/publication_integrity\.yml,'
```

Expected:

```text
.github/workflows/publication_integrity.yml,359,9c2535f1ab9d484b55fbaeff023e05bcd136cbeee7e43b407fc6073aa65587ed
```

---

# 9. Create the release branch

We do **not** commit these changes directly on `main`.

Paste:

```powershell
$Branch = "release/module-2-g3-v2.0.0-final"

git switch -c $Branch
```

Expected:

```text
Switched to a new branch 'release/module-2-g3-v2.0.0-final'
```

Verify:

```powershell
git branch --show-current
```

Expected:

```text
release/module-2-g3-v2.0.0-final
```

If Git says that branch already exists, **stop and tell me**. Do not delete it automatically.

---

# 10. Stage all intended repository changes

Paste:

```powershell
git add -A
```

Nothing has gone to GitHub yet. This only moves the changes into Git's local staging area.

---

# 11. Verify the exact staged file counts

Paste:

```powershell
$Staged = git diff --cached --name-status

$AddedCount = @(
    $Staged | Where-Object { $_ -match '^A\s' }
).Count

$ModifiedCount = @(
    $Staged | Where-Object { $_ -match '^M\s' }
).Count

$DeletedCount = @(
    $Staged | Where-Object { $_ -match '^D\s' }
).Count

$TotalCount = $AddedCount + $ModifiedCount + $DeletedCount

Write-Host ""
Write-Host "Added:    $AddedCount"
Write-Host "Modified: $ModifiedCount"
Write-Host "Deleted:  $DeletedCount"
Write-Host "Total:    $TotalCount"

if ($AddedCount -ne 1083) {
    throw "Expected exactly 1083 added files."
}

if ($ModifiedCount -ne 20) {
    throw "Expected exactly 20 modified files."
}

if ($DeletedCount -ne 0) {
    throw "Expected zero deleted files."
}

Write-Host ""
Write-Host "STAGED FILE COUNTS PASS" -ForegroundColor Green
```

Expected:

```text
Added:    1083
Modified: 20
Deleted:  0
Total:    1103

STAGED FILE COUNTS PASS
```

These exact staged counts are part of the packaged release procedure. [export reference: filecite | turn213file0 | L136-L169]

If your numbers are different, **do not commit**.

---

# 12. Make sure no ZIP file accidentally got staged

This is important.

Paste:

```powershell
$StagedZips = @(
    git diff --cached --name-only |
        Select-String '\.zip(\.sha256)?$'
)

if ($StagedZips.Count -gt 0) {
    $StagedZips
    throw "A ZIP or ZIP sidecar was accidentally staged."
}

Write-Host "NO ZIP FILES STAGED — PASS" -ForegroundColor Green
```

Expected:

```text
NO ZIP FILES STAGED — PASS
```

The big Windows release ZIP stays outside the repository and will be uploaded later through **GitHub Releases**.

---

# 13. Make sure nothing is staged for deletion

Paste:

```powershell
$Deletes = git diff --cached --name-status |
    Where-Object { $_ -match '^D\s' }

if ($Deletes) {
    $Deletes
    throw "Files are staged for deletion. Stop."
}

Write-Host "NO DELETIONS STAGED — PASS" -ForegroundColor Green
```

Expected:

```text
NO DELETIONS STAGED — PASS
```

---

# 14. Review the high-level staged summary

Paste:

```powershell
git diff --cached --stat
```

There will be a lot of output.

The important final summary should correspond to:

```text
1103 files changed
```

and our exact control counts remain:

```text
1083 added
20 modified
0 deleted
```

You do **not** need to manually inspect all 1,103 files.

---

# 15. Inspect the most important repository-facing changes

Run these one at a time:

```powershell
git diff --cached -- README.md
```

```powershell
git diff --cached -- RELEASE_NOTES.md
```

```powershell
git diff --cached -- MODULE_AND_RELEASE_INDEX.md
```

```powershell
git diff --cached -- PROJECT_ARTIFACT_MAP.md
```

```powershell
git diff --cached -- Module_2/README.md
```

```powershell
git diff --cached -- docs/README.md
```

You are just making sure they look like the Module 2/G3 update we have been building—not trying to audit every word again.

---

# 16. Commit the release

If Steps 1–15 all pass, paste:

```powershell
git commit -m "Publish Module 2 / G3 v2.0.0"
```

You should get a large commit summary.

Now rerun the validator:

```powershell
python tools\validate_public_release.py
```

or, if needed:

```powershell
py -3 tools\validate_public_release.py
```

Again you need:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Then:

```powershell
git status --short --branch
```

Expected:

```text
## release/module-2-g3-v2.0.0-final
```

There should be **nothing beneath it**.

That means the commit is complete and the branch is clean.

---

# 17. Push the release branch to GitHub

Paste:

```powershell
git push -u origin release/module-2-g3-v2.0.0-final
```

If a browser/Git Credential Manager login appears, authenticate.

GitHub uses the standard `git push <remote> <branch>` workflow to publish a local branch. [export reference: cite | turn189635search0]

Expected near the end:

```text
[new branch] release/module-2-g3-v2.0.0-final -> release/module-2-g3-v2.0.0-final
```

At this point:

- the new branch is on GitHub;
- `main` has **not** yet changed;
- this is exactly where we want to be.

---

# 18. Open GitHub and create the pull request

Go to your repository in your browser.

GitHub should show a yellow banner for:

```text
release/module-2-g3-v2.0.0-final
```

Click:

```text
Compare & pull request
```

GitHub's documented PR flow after pushing a branch is to use that banner, select the base and compare branches, then enter the title and description. [export reference: cite | turn189635search2]

Make sure:

```text
base:    main
compare: release/module-2-g3-v2.0.0-final
```

PR title:

```text
Publish Module 2 / G3 v2.0.0
```

Use this PR description:

```markdown
## Module 2 / G3 v2.0.0

Publishes the accepted Module 2 stage chain through M2.12 and the
G3_M2_CONTRACT enterprise consumption boundary.

### Principal additions

- complete M2.1–M2.12 public stage tree;
- accepted source, BRDs, architecture, validation, provenance,
  correction history, catalogs, recovery boundaries, and sign-offs;
- Module 2/G3 enterprise architecture and lineage exhibits;
- Governed Build Edition v3.0 ten-page executive brief;
- campaign-readiness and pre-750 replay documentation;
- sanitized ChatGPT project-history archive through 2026-08-12;
- reconciled repository navigation and regenerated manifests.

### Publication boundary

- deterministic synthetic evidence only;
- no production deployment;
- no causal optimization claim;
- no campaign execution authorized;
- no Module 3 execution authorized.
```

Then click:

```text
Create pull request
```

Do **not** make it a draft PR.

---

# 19. Wait for the GitHub Action

On the PR page, look for the checks area.

You need:

```text
Publication Integrity
```

to turn **green**.

Do **not** merge while it says:

```text
Queued
Pending
In progress
```

If it turns red, click **Details** and send me the failure output.

---

# 20. Review the Files Changed tab before merging

Click:

```text
Files changed
```

You do not need to scroll all 1,103 files.

Spot-check that these exist:

```text
Module_2/
docs/campaign_scale/
docs/project_history/
docs/enterprise_architecture/
docs/executive_strategy/
```

Also search the changed-files list for:

```text
publication_integrity.yml
```

It should **not** appear as deleted.

Search for:

```text
.zip
```

There should be no big staging ZIP committed.

---

# 21. Merge the pull request

Once `Publication Integrity` is green:

1. Go back to the PR **Conversation** tab.
2. Click:

```text
Merge pull request
```

3. Then:

```text
Confirm merge
```

Use the normal **Merge pull request** option.

Do not choose:

```text
Rebase and merge
```

After GitHub confirms the PR is merged, click:

```text
Delete branch
```

That deletes the temporary remote release branch, not the merged content.

---

# 22. Bring your local `main` up to date

Return to PowerShell:

```powershell
Set-Location "C:\x\m"
```

Then:

```powershell
git switch main
git fetch origin --tags --prune
git pull --ff-only origin main
```

Now run:

```powershell
python tools\validate_public_release.py
```

or:

```powershell
py -3 tools\validate_public_release.py
```

Again expect:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Now verify local and GitHub `main` are identical:

```powershell
$FinalMain = (git rev-parse HEAD).Trim()
$RemoteMain = (git rev-parse origin/main).Trim()

Write-Host "Local main:  $FinalMain"
Write-Host "Remote main: $RemoteMain"

if ($FinalMain -ne $RemoteMain) {
    throw "Local main and origin/main do not match."
}

Write-Host ""
Write-Host "FINAL MAIN SYNCHRONIZATION PASS" -ForegroundColor Green
```

Then save that commit hash:

```powershell
$FinalMain |
    Set-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt"
```

If you don't have `C:\MSBF_RELEASE_FILES`, create it first:

```powershell
New-Item -ItemType Directory `
    -Path "C:\MSBF_RELEASE_FILES" `
    -Force | Out-Null
```

Finally:

```powershell
git status
```

Expected:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

---

# 23. Deal with the old premature tag

We previously created this tag too early:

```text
module-2-g3-v2.0.0
```

Before touching it, open the GitHub repository and click:

```text
Releases
```

### If there is NO published GitHub Release associated with that tag

Proceed to Step 24.

### If there IS already a GitHub Release named `Module 2 / G3 v2.0.0`

Stop there and tell me whether it is:

```text
Draft
Published
Immutable
```

Do not delete an immutable published Release without checking first, because GitHub's immutable-release behavior can affect tag reuse.

---

# 24. Delete the premature tag

Assuming there is no existing published immutable Release, return to PowerShell and paste:

```powershell
Set-Location "C:\x\m"

$Tag = "module-2-g3-v2.0.0"

$LocalTag = git tag --list $Tag

if ($LocalTag) {
    git tag -d $Tag

    if ($LASTEXITCODE -ne 0) {
        throw "Could not delete old local tag."
    }
}

$RemoteTag = git ls-remote --tags origin "refs/tags/$Tag"

if ($RemoteTag) {
    git push origin ":refs/tags/$Tag"

    if ($LASTEXITCODE -ne 0) {
        throw "Could not delete old remote tag."
    }
}

Write-Host "OLD PREMATURE TAG REMOVED" -ForegroundColor Green
```

---

# 25. Create the tag at the final release commit

Paste:

```powershell
$FinalMain = (
    Get-Content `
        "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt" `
        -Raw
).Trim()

$Tag = "module-2-g3-v2.0.0"

git tag -a $Tag -m "Module 2 / G3 v2.0.0"

if ($LASTEXITCODE -ne 0) {
    throw "Could not create final tag."
}

git push origin $Tag

if ($LASTEXITCODE -ne 0) {
    throw "Could not push final tag."
}

$TagCommit = (git rev-list -n 1 $Tag).Trim()

Write-Host "Final main: $FinalMain"
Write-Host "Tag commit: $TagCommit"

if ($TagCommit -ne $FinalMain) {
    throw "Tag does not point to final main."
}

Write-Host ""
Write-Host "FINAL RELEASE TAG PASS" -ForegroundColor Green
```

Expected:

```text
Final main: [hash]
Tag commit: [same hash]

FINAL RELEASE TAG PASS
```

---

# 26. Prepare the actual GitHub Release asset

The file you upload as the primary Release ZIP is:

```text
MSBF_M2G3_RELEASE_WINDOWS_R1.zip
```

**Not**:

```text
MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip
```

The first is the public Release archive.

The second contains `.git` and was only used to create your local worktree.

Before uploading, verify the public Release ZIP again:

```powershell
$ReleaseZip = "C:\MSBF_RELEASE_FILES\MSBF_M2G3_RELEASE_WINDOWS_R1.zip"

$ExpectedHash = "da0bd1643d0851a1779e4ea476ae9e7b08528bd45d7b4548089734ace1acf209"

$ObservedHash = (
    Get-FileHash `
        -LiteralPath $ReleaseZip `
        -Algorithm SHA256
).Hash.ToLower()

Write-Host "Expected: $ExpectedHash"
Write-Host "Observed: $ObservedHash"

if ($ObservedHash -ne $ExpectedHash) {
    throw "Release ZIP SHA-256 mismatch."
}

Write-Host ""
Write-Host "RELEASE ZIP HASH PASS" -ForegroundColor Green
```

Expected hash:

```text
da0bd1643d0851a1779e4ea476ae9e7b08528bd45d7b4548089734ace1acf209
```

---

# 27. Create the GitHub Release

On GitHub:

1. Open the repository.
2. Click:

```text
Releases
```

3. Click:

```text
Draft a new release
```

4. For **Choose a tag**, select the existing:

```text
module-2-g3-v2.0.0
```

Do not create a new tag in the Release screen.

5. Release title:

```text
Module 2 / G3 v2.0.0
```

6. Make sure:

```text
Set as latest release      YES
Pre-release                NO
```

GitHub Releases allow an existing tag to be selected, release notes added, and binary files attached before publishing. [export reference: cite | turn189635search3]

---

# 28. Use `RELEASE_NOTES.md` as the Release description

In PowerShell:

```powershell
Get-Content "C:\x\m\RELEASE_NOTES.md" -Raw | Set-Clipboard
```

Then click the GitHub Release description box and press:

```text
Ctrl + V
```

---

# 29. Attach the Release assets

Attach these files:

```text
MSBF_M2G3_RELEASE_WINDOWS_R1.zip
MSBF_M2G3_RELEASE_WINDOWS_R1.zip.sha256
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json
MSBF_Transparency_Campaign_Navigation_File_Inventory.csv
```

The first two are the essential release pair. The other three are validation/support artifacts. The runbook likewise separates the governed release asset pair from the local `.git` worktree ZIP. [export reference: filecite | turn213file0 | L232-L270]

Do **not** attach:

```text
MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip
MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip.sha256
ChatGPT_Logs.zip
MSBF_GitHub_UPLOAD_RUNBOOK_v2.0.0.md
old overlay ZIPs
```

Wait for all uploads to finish.

Then click:

```text
Save draft
```

Do not publish immediately.

---

# 30. Review the draft Release

Before publishing, verify:

```text
Tag:
module-2-g3-v2.0.0

Title:
Module 2 / G3 v2.0.0

Latest release:
Yes

Pre-release:
No
```

Verify all five files appear.

Verify no file still says:

```text
Uploading...
```

Then click:

```text
Publish release
```

---

# 31. Perform a clean-clone verification

This is the final technical proof.

Use a new short directory:

```text
C:\v
```

First ensure it does not already exist:

```powershell
if (Test-Path "C:\v") {
    throw "C:\v already exists. Rename or remove it deliberately before continuing."
}
```

Now clone the published tag:

```powershell
git clone `
    --branch module-2-g3-v2.0.0 `
    --depth 1 `
    https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git `
    C:\v
```

Enter it:

```powershell
Set-Location "C:\v"
```

Run:

```powershell
python tools\validate_public_release.py
```

or:

```powershell
py -3 tools\validate_public_release.py
```

Expected:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Now compare the tag commit to the final `main` commit:

```powershell
$CloneHead = (git rev-parse HEAD).Trim()

$FinalMain = (
    Get-Content `
        "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt" `
        -Raw
).Trim()

Write-Host "Published clone: $CloneHead"
Write-Host "Final main:      $FinalMain"

if ($CloneHead -ne $FinalMain) {
    throw "Published tag does not match final main."
}

Write-Host ""
Write-Host "CLEAN CLONE TAG/MAIN IDENTITY PASS" -ForegroundColor Green
```

Then:

```powershell
git status --short --branch
```

Because you cloned a tag, something like:

```text
## HEAD (no branch)
```

is normal.

The clean-clone validator and browser checks are the final steps in the governing runbook. [export reference: filecite | turn213file1 | L283-L314]

---

# 32. Final browser audit

On GitHub, verify these specific things:

**Repository home:** root README loads and describes Module 1/G2 and Module 2/G3 as accepted; campaign-scale certification is current.

**Module 2:** click `Module_2/`. You should see twelve accepted stages, M2.1 through M2.12.

**Documentation:** open each of these:

```text
docs/campaign_scale/
docs/project_history/
docs/enterprise_architecture/
docs/executive_strategy/
```

**Actions:** click `Actions`. The latest **Publication Integrity** run on `main` should be green.

**Tag:** `module-2-g3-v2.0.0` should point to the same commit you saved in:

```text
C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt
```

**Release:** verify:

```text
Module 2 / G3 v2.0.0
Latest
not Pre-release
```

and that the Windows R1 release ZIP plus sidecar are attached.

---

## The next thing for you to do right now

You have already completed the automated extraction successfully.

So **start with Step 1 above at `C:\x\m`, then work through Step 16 only**.

Once you reach the point where:

```text
git commit -m "Publish Module 2 / G3 v2.0.0"
```

has completed, the validator passes again, and:

```powershell
git status --short --branch
```

shows only:

```text
## release/module-2-g3-v2.0.0-final
```

then you are ready for the first actual GitHub-changing command:

```powershell
git push -u origin release/module-2-g3-v2.0.0-final
```

If you want to minimize risk, send me a screenshot of the PowerShell window **immediately before that push** and I can verify the checkpoint before you change anything on GitHub.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bbb21181-d023-4822-93c8-8d244f991e13"></a>
## Andrew / user · C072-M00515

C072-M00515 · 2026-08-15T00:05:12.254329-04:00 · active path

Preceding visible parent: [C072-M00514](part-36.md#m-57bfa47f-f570-4012-8b91-73492087b093)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\x\m> Select-String `
>>
>>     -Path .\MANIFEST.csv `
>>
>>     -Pattern '^\.github/workflows/publication_integrity\.yml,'

cmdlet Select-String at command pipeline position 1
Supply values for the following parameters:
Pattern[0]:           what do I do?
<!-- END_SOURCE_MESSAGE -->


<a id="m-e8a35178-764d-4a25-9c74-58207b739e77"></a>
## Assistant · C072-M00516

C072-M00516 · 2026-08-15T00:05:18.486077-04:00 · active path

Preceding visible parent: [C072-M00515](part-36.md#m-bbb21181-d023-4822-93c8-8d244f991e13)

<!-- BEGIN_SOURCE_MESSAGE -->
Nothing is wrong with the repository. PowerShell interpreted the pasted multiline command incorrectly and is now waiting for you to manually supply the `-Pattern` value.

### Right now

At this prompt:

```text
Pattern[0]:
```

press:

```text
Ctrl+C
```

That will cancel the incomplete command and return you to:

```text
PS C:\x\m>
```

### Then use this simpler one-line command

Copy and paste this **as one line**:

```powershell
Select-String -Path .\MANIFEST.csv -Pattern '^\.github/workflows/publication_integrity\.yml,'
```

Press **Enter**.

### What we expect

You should get a result containing:

```text
.github/workflows/publication_integrity.yml
```

Ideally the complete line will be:

```text
.github/workflows/publication_integrity.yml,359,9c2535f1ab9d484b55fbaeff023e05bcd136cbeee7e43b407fc6073aa65587ed
```

If you get that, **Step 8 passes and you can proceed to Step 9 (creating the release branch).**

If you get **no output**, don't continue—paste what PowerShell shows me.

The problem here was just the backtick-based multiline paste. For the remaining steps, I'll favor **single-line PowerShell commands** wherever practical so we don't run into this again.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fadd304f-180b-4802-9c8e-1c2deeb681ff"></a>
## Andrew / user · C072-M00517

C072-M00517 · 2026-08-15T00:24:06.477000-04:00 · active path

Preceding visible parent: [C072-M00516](part-36.md#m-e8a35178-764d-4a25-9c74-58207b739e77)

**Editorial record note:** Attachment references: Pasted text(20260815-042348).txt

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-dbc3c49e-2d2c-4b62-8673-51f123559eac"></a>
## Assistant · C072-M00518

C072-M00518 · 2026-08-15T00:24:22.554475-04:00 · active path

Preceding visible parent: [C072-M00517](part-36.md#m-fadd304f-180b-4802-9c8e-1c2deeb681ff)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **this passes the Step 14 staged-summary checkpoint.** I reviewed the output you pasted. The final line is exactly:

```text
1103 files changed, 359879 insertions(+), 4325 deletions(-)
```

[export reference: filecite | turn215file0 | L1102-L1105]

The contents also look structurally correct: the complete Module 2 public tree, campaign-scale documentation, updated architecture and executive-strategy assets, project-history archive, root manifests, release metadata, and validator are all represented in the staged change set. [export reference: filecite | turn215file0 | L1017-L1054] [export reference: filecite | turn215file0 | L1055-L1104]

So **do not change or unstage anything.**

### Next: Step 15

You are still at:

```text
PS C:\x\m>
```

Run these **one at a time**. Each command only displays the staged changes; it does not modify anything:

```powershell
git diff --cached -- README.md
```

When finished viewing it, if PowerShell puts you into a scrolling screen with a colon `:` at the bottom, press:

```text
q
```

Then run:

```powershell
git diff --cached -- RELEASE_NOTES.md
```

Press `q` when done if necessary.

Then:

```powershell
git diff --cached -- MODULE_AND_RELEASE_INDEX.md
```

Then:

```powershell
git diff --cached -- PROJECT_ARTIFACT_MAP.md
```

Then:

```powershell
git diff --cached -- Module_2/README.md
```

Then:

```powershell
git diff --cached -- docs/README.md
```

### What are you looking for?

You **do not need to proofread hundreds of lines**. For each, just confirm that:

- it is clearly describing the new **Module 2 / G3 v2.0.0** state;
- Module 2 is complete through **M2.12**;
- G2/G3 are accepted;
- campaign-scale work is the next/current governed initiative;
- the new Module 2, architecture, executive-strategy, campaign-scale, and project-history documentation is being referenced;
- nothing looks obviously corrupted or unrelated.

### Then send me one thing

After looking through those six diffs, run:

```powershell
git status --short --branch
```

Paste that output here.

**Do not run `git commit` yet.** I'll check that final pre-commit status with you, and then I'll give you the exact next command.
<!-- END_SOURCE_MESSAGE -->


<a id="m-031142cc-9ae1-4eb5-8899-7c18568cc21b"></a>
## Andrew / user · C072-M00519

C072-M00519 · 2026-08-15T00:34:40.875000-04:00 · active path

Preceding visible parent: [C072-M00518](part-36.md#m-dbc3c49e-2d2c-4b62-8673-51f123559eac)

**Editorial record note:** Attachment references: Pasted text(20260815-043428).txt

<!-- BEGIN_SOURCE_MESSAGE -->
steps 1-15 were a  pass.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-6e42dea9-08ec-4d33-a78e-4f90bd4a5860"></a>
## Assistant · C072-M00520

C072-M00520 · 2026-08-15T00:34:56.628050-04:00 · active path

Preceding visible parent: [C072-M00519](part-36.md#m-031142cc-9ae1-4eb5-8899-7c18568cc21b)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. I reviewed the status you supplied. You are on the correct release branch, and the expected staged publication payload is present. The status begins with `release/module-2-g3-v2.0.0-final` and shows the expected modified/new repository authorities rather than an unexpected branch state. [export reference: filecite | turn216file0 | L1-L9]

Since **Steps 1–15 all passed**, we can now commit.

## Step 16 — Commit the release

At:

```text
PS C:\x\m>
```

paste this **single line**:

```powershell
git commit -m "Publish Module 2 / G3 v2.0.0"
```

This may take a little while because you are committing 1,103 files. Let it finish completely.

### What success looks like

Near the beginning/end, you should see something resembling:

```text
[release/module-2-g3-v2.0.0-final <new commit hash>] Publish Module 2 / G3 v2.0.0
```

followed by a large summary.

Do **not** worry about the exact new commit hash; Git generates that now.

---

## Step 17 — Immediately validate the committed repository

When the commit finishes and you are back at:

```text
PS C:\x\m>
```

run:

```powershell
python tools\validate_public_release.py
```

If `python` doesn't work, use:

```powershell
py -3 tools\validate_public_release.py
```

You need to see:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

If it says `FAIL`, **stop there and send me the output. Do not push.**

---

## Step 18 — Verify that the commit captured everything

Next run:

```powershell
git status --short --branch
```

You want **only**:

```text
## release/module-2-g3-v2.0.0-final
```

There should be **no files listed underneath it**.

Then run:

```powershell
git log -1 --oneline
```

You should see:

```text
<new-hash> Publish Module 2 / G3 v2.0.0
```

---

## Step 19 — One final pre-push identity check

Run this single line:

```powershell
git diff --name-only HEAD
```

Expected:

```text
(no output)
```

Then:

```powershell
git diff --cached --name-only
```

Expected:

```text
(no output)
```

That proves there are no unstaged or staged changes left behind after the commit.

### Your checkpoint

If all of the following are true:

```text
Commit                                 SUCCESS
Public release validation              PASS
Governed manifest files                1930
Module 2 stage folders                 12
git status                             CLEAN
git diff HEAD                          EMPTY
git diff --cached                      EMPTY
Latest commit message                  Publish Module 2 / G3 v2.0.0
```

then the local release commit is complete.

**Stop there before pushing.** Send me the output from:

```powershell
git status --short --branch
git log -1 --oneline
```

I'll verify the commit checkpoint and then give you the exact push + GitHub PR steps from that point.
<!-- END_SOURCE_MESSAGE -->


<a id="m-24f5b3b6-271a-41f2-b0de-2cd365f1d48d"></a>
## Andrew / user · C072-M00521

C072-M00521 · 2026-08-15T00:47:19.124000-04:00 · active path

Preceding visible parent: [C072-M00520](part-36.md#m-6e42dea9-08ec-4d33-a78e-4f90bd4a5860)

**Editorial record note:** Attachment references: Pasted text(20260815-044709).txt

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-402cb9fb-2c2e-4c0d-bb94-d1346a8bbb6a"></a>
## Assistant · C072-M00522

C072-M00522 · 2026-08-15T00:47:25.581564-04:00 · active path

Preceding visible parent: [C072-M00521](part-36.md#m-24f5b3b6-271a-41f2-b0de-2cd365f1d48d)

<!-- BEGIN_SOURCE_MESSAGE -->
**Checkpoint passes completely. You are authorized to push the release branch.**

Your output establishes all of the required pre-push conditions:

- Commit successfully created as `2c9b938` with the correct message. [export reference: filecite | turn217file0 | L9-L10]
- Post-commit validator: **PASS**.
- Governed manifest files: **1,930**.
- Module 2 stage folders: **12**. [export reference: filecite | turn217file0 | L1089-L1092]
- Branch is exactly `release/module-2-g3-v2.0.0-final`, with no residual working-tree changes. [export reference: filecite | turn217file0 | L1093-L1094]
- HEAD is `2c9b938 — Publish Module 2 / G3 v2.0.0`. [export reference: filecite | turn217file0 | L1095-L1096]
- Both unstaged and staged diffs are empty. [export reference: filecite | turn217file0 | L1097-L1099]

## Step 20 — Push the release branch

At:

```text
PS C:\x\m>
```

run this **single command**:

```powershell
git push -u origin release/module-2-g3-v2.0.0-final
```

This is the first operation that publishes the new Module 2/G3 commit to GitHub. It does **not** change `main`; it only creates the release branch on GitHub.

If GitHub/Git Credential Manager opens a browser authentication window, approve it and return to PowerShell.

### Expected successful ending

Something similar to:

```text
[new branch]      release/module-2-g3-v2.0.0-final -> release/module-2-g3-v2.0.0-final
branch 'release/module-2-g3-v2.0.0-final' set up to track 'origin/release/module-2-g3-v2.0.0-final'.
```

GitHub may also print a URL suggesting that you create a pull request. That's fine.

## Step 21 — Verify the remote branch

After the push succeeds, run:

```powershell
git status --short --branch
```

Expected:

```text
## release/module-2-g3-v2.0.0-final...origin/release/module-2-g3-v2.0.0-final
```

Then run:

```powershell
git rev-parse HEAD
```

and:

```powershell
git rev-parse origin/release/module-2-g3-v2.0.0-final
```

**Those two full 40-character hashes must be identical.**

Do not merge anything yet. Once those commands pass, the local-to-GitHub branch publication is proven and we'll create the PR against `main`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-43d4b59b-be01-4169-95ba-ddb3885c02be"></a>
## Andrew / user · C072-M00523

C072-M00523 · 2026-08-15T00:57:08.691000-04:00 · active path

Preceding visible parent: [C072-M00522](part-36.md#m-402cb9fb-2c2e-4c0d-bb94-d1346a8bbb6a)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\x\m> git push -u origin release/module-2-g3-v2.0.0-final
Enumerating objects: 1197, done.
Counting objects: 100% (1197/1197), done.
Delta compression using up to 4 threads
Compressing objects: 100% (912/912), done.
Writing objects: 100% (1175/1175), 27.05 MiB | 8.55 MiB/s, done.
Total 1175 (delta 268), reused 1167 (delta 260), pack-reused 0 (from 0)
remote: Resolving deltas: 100% (268/268), completed with 8 local objects.
remote:
remote: Create a pull request for 'release/module-2-g3-v2.0.0-final' on GitHub by visiting:
remote:      https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/pull/new/release/module-2-g3-v2.0.0-final
remote:
To https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
 * [new branch]      release/module-2-g3-v2.0.0-final -> release/module-2-g3-v2.0.0-final
branch 'release/module-2-g3-v2.0.0-final' set up to track 'origin/release/module-2-g3-v2.0.0-final'.
PS C:\x\m> git status --short --branch
## release/module-2-g3-v2.0.0-final...origin/release/module-2-g3-v2.0.0-final
PS C:\x\m> git rev-parse HEAD
2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a
PS C:\x\m> git rev-parse origin/release/module-2-g3-v2.0.0-final
2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a
<!-- END_SOURCE_MESSAGE -->


<a id="m-bb8f99a1-6ac1-4b30-826c-4794fbc6d1bf"></a>
## Assistant · C072-M00524

C072-M00524 · 2026-08-15T00:57:15.334448-04:00 · active path

Preceding visible parent: [C072-M00523](part-36.md#m-43d4b59b-be01-4169-95ba-ddb3885c02be)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. **The push checkpoint is a complete PASS.**

The critical identity check is exact:

```text
Local HEAD:
2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a

GitHub release branch:
2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a
```

So GitHub now has an exact copy of the validated release commit. **`main` has not been changed yet.**

## Next — Create the Pull Request

### 1. Open the PR page

Git conveniently gave you the exact page. Open this in your browser:

[export reference: url | Open the Module 2/G3 pull request page | https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/pull/new/release/module-2-g3-v2.0.0-final]

You should land on GitHub's **Open a pull request** screen.

### 2. Check the two branches at the top

Before typing anything, make sure it says:

```text
base: main

compare: release/module-2-g3-v2.0.0-final
```

This is important.

You want:

**release branch → main**

not the reverse.

### 3. Check that GitHub says the branches can be merged

Near the branch selectors, you should see something like:

```text
Able to merge.
These branches can be automatically merged.
```

If GitHub instead reports a conflict, **do not continue**. Tell me what it says.

### 4. Enter this exact PR title

```text
Publish Module 2 / G3 v2.0.0
```

### 5. Put this in the description

Copy/paste:

```markdown
## Module 2 / G3 v2.0.0

Publishes the accepted Module 2 stage chain through M2.12 and the
G3_M2_CONTRACT enterprise consumption boundary.

### Principal additions

- complete M2.1–M2.12 public stage tree;
- accepted source, BRDs, architecture, validation, provenance,
  correction history, catalogs, recovery boundaries, and sign-offs;
- Module 2/G3 enterprise architecture and lineage exhibits;
- Governed Build Edition v3.0 ten-page executive brief;
- campaign-readiness and pre-750 replay documentation;
- sanitized ChatGPT project-history archive through 2026-08-12;
- reconciled repository navigation and regenerated manifests.

### Publication boundary

- deterministic synthetic evidence only;
- no production deployment;
- no causal optimization claim;
- no campaign execution authorized;
- no Module 3 execution authorized.

### Local publication validation

- Public release validation: PASS
- Governed manifest files: 1,930
- Module 2 stage folders: 12
- Release commit: `2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a`
- Local/remote release-branch identity: PASS
```

### 6. Do not make this a Draft PR

You want a normal pull request.

Click:

```text
Create pull request
```

---

# After you click Create pull request

**Do not click Merge yet.**

GitHub should open the newly created PR page.

We're specifically looking for the automated **Publication Integrity** check from the workflow we preserved.

It may initially say something like:

```text
Some checks haven't completed yet

Publication Integrity
Expected — Waiting for status to be reported
```

or:

```text
Publication Integrity
In progress
```

Give it time to run.

## What we ultimately want

A green check beside:

```text
Publication Integrity
```

and ideally GitHub indicating:

```text
All checks have passed
```

---

# While it runs, check one more thing

On the PR page, click:

```text
Files changed
```

You do **not** need to review 1,103 files manually—we already did the governed local checks.

Instead, use GitHub's file filter/search and spot-check these:

```text
README.md
Module_2/README.md
docs/README.md
docs/campaign_scale/README.md
docs/project_history/README.md
docs/enterprise_architecture/
docs/executive_strategy/
```

Also make sure there isn't an unexpected deletion of:

```text
.github/workflows/publication_integrity.yml
```

We already proved locally that it wasn't deleted, so this is simply a final GitHub-side sanity check.

---

## Your current release status

```text
Local release commit                 PASS
Commit                               2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a
Local worktree                       CLEAN
Local publication validator          PASS
Governed manifest files              1,930
Module 2 stages                      12
Release branch pushed                PASS
Remote tracking established          PASS
Local HEAD = remote branch           EXACT MATCH
main                                  UNCHANGED
Pull request                          NEXT
```

**Create the PR now, but don't merge it yet.** Once the PR exists, send me a screenshot of the PR page/checks area—or tell me exactly what GitHub shows for **Publication Integrity**—and we'll handle the merge checkpoint.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8eee3a22-c903-4ce8-9cb9-2df7b8517aa0"></a>
## Andrew / user · C072-M00525

C072-M00525 · 2026-08-15T01:01:20.469000-04:00 · active path

Preceding visible parent: [C072-M00524](part-36.md#m-bb8f99a1-6ac1-4b30-826c-4794fbc6d1bf)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: fba9648f-d001-42bb-90c1-800dd79057bf.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-164f068c-2f19-4538-b31e-8879306e2d04"></a>
## Assistant · C072-M00526

C072-M00526 · 2026-08-15T01:01:27.895302-04:00 · active path

Preceding visible parent: [C072-M00525](part-36.md#m-8eee3a22-c903-4ce8-9cb9-2df7b8517aa0)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **this screen is exactly right.** Do not change the branch selectors.

I can see:

```text
base: main
compare: release/module-2-g3-v2.0.0-final
✓ Able to merge. These branches can be automatically merged.
1 commit
1,103 files changed
```

Those numbers line up exactly with our validated release candidate.

Your title is also correct:

```text
Publish Module 2 / G3 v2.0.0
```

### 1. Paste this into the Description box

```markdown
## Module 2 / G3 v2.0.0

Publishes the accepted Module 2 stage chain through M2.12 and the
G3_M2_CONTRACT enterprise consumption boundary.

### Principal additions

- complete M2.1–M2.12 public stage tree;
- accepted source, BRDs, architecture, validation, provenance,
  correction history, catalogs, recovery boundaries, and sign-offs;
- Module 2/G3 enterprise architecture and lineage exhibits;
- Governed Build Edition v3.0 ten-page executive brief;
- campaign-readiness and pre-750 replay documentation;
- sanitized ChatGPT project-history archive through 2026-08-12;
- reconciled repository navigation and regenerated manifests.

### Publication boundary

- deterministic synthetic evidence only;
- no production deployment;
- no causal optimization claim;
- no campaign execution authorized;
- no Module 3 execution authorized.

### Publication validation

- Public release validation: **PASS**
- Governed manifest files: **1,930**
- Module 2 stage folders: **12**
- Release commit: `2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a`
- Local/remote release-branch identity: **PASS**
```

### 2. Leave everything else alone

You do **not** need to set:

- Reviewers
- Assignees
- Labels
- Projects
- Milestone

For this personal governed release, leaving those blank is fine.

### 3. Click the green **Create pull request** button

Use the main green button as shown in your screenshot. **Do not use its dropdown to create a draft.**

After clicking it, GitHub will take you to the newly created PR.

### 4. Then stop before merging

On the new PR page, we need to see what GitHub reports for the automated checks—particularly:

```text
Publication Integrity
```

It may initially show **Pending**, **In progress**, or **Expected**. That's normal.

**Do not click Merge pull request yet.**

Send me a screenshot of the PR page after you create it, particularly the lower section showing the checks/merge status. I'll verify that checkpoint before we merge into `main`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c514f293-db1a-4a95-8cfb-b1526b0781e3"></a>
## Andrew / user · C072-M00527

C072-M00527 · 2026-08-15T01:16:14.566000-04:00 · active path

Preceding visible parent: [C072-M00526](part-36.md#m-164f068c-2f19-4538-b31e-8879306e2d04)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: fc361077-f495-474b-a921-fc7caa3d36e6.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-aa099844-512c-49f8-a5fe-829ca06830b5"></a>
## Assistant · C072-M00528

C072-M00528 · 2026-08-15T01:16:30.423797-04:00 · active path

Preceding visible parent: [C072-M00527](part-36.md#m-c514f293-db1a-4a95-8cfb-b1526b0781e3)

<!-- BEGIN_SOURCE_MESSAGE -->
This is exactly what we wanted. **The GitHub pull-request gate is a PASS.**

I can see in your screenshot:

- PR **#1** is open.
- `main ← release/module-2-g3-v2.0.0-final` is the merge direction.
- GitHub reports **Ready to merge**.
- **All checks have passed**.
- `Publication Integrity / validate (pull_request)` completed successfully in **15s**.
- GitHub reports **No conflicts with base branch**.
- The PR still contains the expected **1 commit / 1,103 files changed**.
- The green **Merge pull request** button is enabled.

So we can merge.

## Step 22 — Merge the PR

Click the green:

**Merge pull request**

Do **not** use a dropdown to choose Squash or Rebase. We want the normal merge.

GitHub should then change the button/area and ask you to confirm.

Click:

**Confirm merge**

Wait until GitHub tells you the pull request was successfully merged.

### Important

After the merge completes, GitHub will probably offer:

**Delete branch**

Go ahead and click **Delete branch**. That deletes the temporary remote branch:

```text
release/module-2-g3-v2.0.0-final
```

It does **not** delete the newly merged Module 2/G3 content from `main`.

---

## Step 23 — Then return to PowerShell

Once GitHub says the PR is merged, return to:

```text
PS C:\x\m>
```

Run these commands **one at a time**:

```powershell
git switch main
```

Then:

```powershell
git fetch origin --tags --prune
```

Then:

```powershell
git pull --ff-only origin main
```

Because GitHub will create a merge commit, your local `main` should fast-forward from the old baseline to the newly merged GitHub `main`.

---

## Step 24 — Verify local `main` against GitHub

Run:

```powershell
git status
```

We want:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

Then run:

```powershell
git rev-parse HEAD
```

Copy the resulting 40-character hash somewhere temporarily.

Then run:

```powershell
git rev-parse origin/main
```

The two hashes must be **identical**.

---

## Step 25 — Run the publication validator on final `main`

Run:

```powershell
python tools\validate_public_release.py
```

If necessary:

```powershell
py -3 tools\validate_public_release.py
```

We need again:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

This is important because we are no longer validating the release branch—we are validating the actual repository `main` that the public will receive.

---

## Step 26 — Save the final `main` commit identity

First create our release-control folder if it doesn't already exist:

```powershell
New-Item -ItemType Directory -Path "C:\MSBF_RELEASE_FILES" -Force | Out-Null
```

Then run this **one-line command**:

```powershell
git rev-parse HEAD | Set-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt"
```

Now display what was saved:

```powershell
Get-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt"
```

That hash becomes our authoritative final GitHub `main` identity for the tag check.

---

## Step 27 — Final `main` checkpoint

Run:

```powershell
git status --short --branch
```

Expected:

```text
## main...origin/main
```

with **nothing listed beneath it**.

Then run:

```powershell
git log -2 --oneline
```

Because we used a normal PR merge, I expect the top entry to be a GitHub-created merge commit, followed by your release commit `2c9b938`.

---

### Stop after Step 27

Do **not** touch the old `module-2-g3-v2.0.0` tag yet.

We need to establish the exact final `main` commit first because the old tag was created prematurely and will need to be repointed to this new final release identity.

Once you've:

1. merged the PR;
2. deleted the temporary GitHub branch;
3. synchronized local `main`;
4. rerun the validator;
5. saved `FINAL_MAIN_COMMIT.txt`;

send me the PowerShell output from:

```powershell
git status --short --branch
git log -2 --oneline
git rev-parse HEAD
git rev-parse origin/main
```

Then I'll give you the exact old-tag correction steps.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a1fdb304-749e-4464-9875-30ef89a0bcb9"></a>
## Andrew / user · C072-M00529

C072-M00529 · 2026-08-15T01:29:12.759000-04:00 · active path

Preceding visible parent: [C072-M00528](part-36.md#m-aa099844-512c-49f8-a5fe-829ca06830b5)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\x\m> git status
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
PS C:\x\m> git rev-parse HEAD
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
PS C:\x\m> git rev-parse origin/main
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
PS C:\x\m> python tools\validate_public_release.py
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
PS C:\x\m> New-Item -ItemType Directory -Path "C:\MSBF_RELEASE_FILES" -Force | Out-Null
PS C:\x\m> git rev-parse HEAD | Set-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt"
PS C:\x\m> Get-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt"
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
PS C:\x\m> git status --short --branch
## main...origin/main
PS C:\x\m> git log -2 --oneline
500ec77 (HEAD -> main, origin/main, origin/HEAD) Merge pull request #1 from andrew-goad/release/module-2-g3-v2.0.0-final
2c9b938 (origin/release/module-2-g3-v2.0.0-final, release/module-2-g3-v2.0.0-final) Publish Module 2 / G3 v2.0.0
<!-- END_SOURCE_MESSAGE -->


<a id="m-25b0147e-b6ce-4cfe-9a34-316eff843e5d"></a>
## Assistant · C072-M00530

C072-M00530 · 2026-08-15T01:29:19.327128-04:00 · active path

Preceding visible parent: [C072-M00529](part-36.md#m-a1fdb304-749e-4464-9875-30ef89a0bcb9)

<!-- BEGIN_SOURCE_MESSAGE -->
That is a **complete PASS for final `main`**.

Your authoritative state is now:

```text
Final main:
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

origin/main:
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65

Release content commit:
2c9b93879ed3c98d4e38f0d42b3bedd16e79e62a

Publication validator:
PASS

Governed manifest files:
1930

Module 2 stage folders:
12

Working tree:
CLEAN
```

The merge commit is exactly what we expected from the normal GitHub PR merge.

Now we correct the **premature tag** so `module-2-g3-v2.0.0` points to `500ec776...`, not the older pre-publication state.

## Step 28 — First check whether a GitHub Release already exists

Before running any tag commands, open your repository in GitHub and click **Releases**.

You need to determine whether there is already a GitHub **Release** associated with:

```text
module-2-g3-v2.0.0
```

This is different from merely having a Git tag.

### If you see no Release

Perfect. Continue to Step 29 below.

### If you see a Release

Do **not** delete anything yet. Tell me whether GitHub shows it as:

```text
Draft
Pre-release
Published
```

and we'll handle that state deliberately.

---

# Step 29 — Inspect the existing premature tag

Assuming there is **no GitHub Release**, return to:

```text
PS C:\x\m>
```

Run:

```powershell
git tag --list module-2-g3-v2.0.0
```

I expect:

```text
module-2-g3-v2.0.0
```

Now determine where that old tag currently points:

```powershell
git rev-list -n 1 module-2-g3-v2.0.0
```

Write down or copy that hash.

Then inspect the remote tag:

```powershell
git ls-remote --tags origin "refs/tags/module-2-g3-v2.0.0^{}"
```

Because this is an annotated tag, you should get output containing a commit hash followed by:

```text
refs/tags/module-2-g3-v2.0.0^{}
```

The commit will presumably **not** be:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

That's why we're correcting it.

---

# Step 30 — Delete the premature local tag

Run this one line:

```powershell
git tag -d module-2-g3-v2.0.0
```

Expected:

```text
Deleted tag 'module-2-g3-v2.0.0' (...)
```

This only deletes your local copy of the tag.

It does **not** delete any repository content.

---

# Step 31 — Delete the premature remote tag

Now run:

```powershell
git push origin :refs/tags/module-2-g3-v2.0.0
```

Expected near the end:

```text
- [deleted]         module-2-g3-v2.0.0
```

Now prove that GitHub no longer has it:

```powershell
git ls-remote --tags origin "refs/tags/module-2-g3-v2.0.0*"
```

Expected:

```text
(no output)
```

If anything is returned, stop there.

---

# Step 32 — Create the final annotated tag on `500ec776...`

Before creating it, prove you're still sitting on final `main`:

```powershell
git rev-parse HEAD
```

Expected exactly:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

Now create the tag:

```powershell
git tag -a module-2-g3-v2.0.0 -m "Module 2 / G3 v2.0.0"
```

No output generally means success.

---

# Step 33 — Prove the new local tag points to final `main`

Run:

```powershell
git rev-list -n 1 module-2-g3-v2.0.0
```

Expected exactly:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

Now perform an automated identity check:

```powershell
$FinalMain = (Get-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt" -Raw).Trim(); $TagCommit = (git rev-list -n 1 module-2-g3-v2.0.0).Trim(); if ($FinalMain -ne $TagCommit) { throw "Tag does not point to final main." } else { Write-Host "LOCAL TAG / FINAL MAIN IDENTITY PASS" -ForegroundColor Green }
```

Expected:

```text
LOCAL TAG / FINAL MAIN IDENTITY PASS
```

---

# Step 34 — Push the corrected final tag

Now:

```powershell
git push origin module-2-g3-v2.0.0
```

Expected:

```text
[new tag]         module-2-g3-v2.0.0 -> module-2-g3-v2.0.0
```

---

# Step 35 — Prove the GitHub tag points to final `main`

Run:

```powershell
git ls-remote --tags origin "refs/tags/module-2-g3-v2.0.0^{}"
```

You want the first value to be:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

So the complete output should resemble:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65    refs/tags/module-2-g3-v2.0.0^{}
```

Then run this automated remote check:

```powershell
$FinalMain = (Get-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt" -Raw).Trim(); $RemoteTagCommit = ((git ls-remote --tags origin "refs/tags/module-2-g3-v2.0.0^{}") -split '\s+')[0]; if ($FinalMain -ne $RemoteTagCommit) { throw "Remote release tag does not point to final main." } else { Write-Host "REMOTE TAG / FINAL MAIN IDENTITY PASS" -ForegroundColor Green }
```

Expected:

```text
REMOTE TAG / FINAL MAIN IDENTITY PASS
```

---

# Step 36 — One final repository check

Run:

```powershell
git status --short --branch
```

Expected:

```text
## main...origin/main
```

Then:

```powershell
python tools\validate_public_release.py
```

Expected again:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

At that point we'll have:

```text
main                              PASS
origin/main                       PASS
Publication Integrity PR check    PASS
Local validator                   PASS
Final main                        500ec776...
Local release tag                 500ec776...
Remote release tag                500ec776...
Working tree                      CLEAN
```

Then the **only major publication step remaining is creating the actual GitHub Release and attaching `MSBF_M2G3_RELEASE_WINDOWS_R1.zip` plus its release-assurance artifacts.**

Start with **Step 28** now. If there is no existing GitHub Release, you can proceed through Steps 29–36.
<!-- END_SOURCE_MESSAGE -->


<a id="m-770a620b-33a2-404c-b64a-857e2e1b2b48"></a>
## Andrew / user · C072-M00531

C072-M00531 · 2026-08-15T01:54:21.414000-04:00 · active path

Preceding visible parent: [C072-M00530](part-36.md#m-25b0147e-b6ce-4cfe-9a34-316eff843e5d)

<!-- BEGIN_SOURCE_MESSAGE -->
Thru Step 36 is complete and a pass.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3d5cc7bc-63bd-48e1-bf90-adc1cc0fc130"></a>
## Assistant · C072-M00532

C072-M00532 · 2026-08-15T01:54:34.977221-04:00 · active path

Preceding visible parent: [C072-M00531](part-36.md#m-770a620b-33a2-404c-b64a-857e2e1b2b48)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. That means the **repository publication itself is now governed and synchronized**:

```text
main / origin-main identity                 PASS
Final main                                  500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
Publication Integrity                       PASS
Public-release validator                    PASS
Governed manifest files                     1,930
Module 2 stage folders                      12
Final local tag                             PASS
Final remote tag                            PASS
Tag = final main                            PASS
Working tree                                CLEAN
```

We are now at the final major step: **create the GitHub Release and attach the governed distribution artifacts.**

## Step 37 — Verify the Release ZIP one last time

Your public distribution ZIP is:

```text
MSBF_M2G3_RELEASE_WINDOWS_R1.zip
```

Do **not** upload the `UPLOAD_WORKTREE` ZIP.

In PowerShell, locate where you saved the release ZIP. If it is in:

```text
C:\MSBF_RELEASE_FILES
```

run this one-line command:

```powershell
Get-FileHash "C:\MSBF_RELEASE_FILES\MSBF_M2G3_RELEASE_WINDOWS_R1.zip" -Algorithm SHA256
```

You need:

```text
da0bd1643d0851a1779e4ea476ae9e7b08528bd45d7b4548089734ace1acf209
```

Then verify the sidecar exists:

```powershell
Test-Path "C:\MSBF_RELEASE_FILES\MSBF_M2G3_RELEASE_WINDOWS_R1.zip.sha256"
```

Expected:

```text
True
```

---

# Step 38 — Copy the final Release notes

While still in:

```text
C:\x\m
```

run:

```powershell
Get-Content ".\RELEASE_NOTES.md" -Raw | Set-Clipboard
```

No output is expected.

Your final `RELEASE_NOTES.md` is now on the clipboard.

---

# Step 39 — Open GitHub Releases

Open your repository in GitHub.

Click:

**Releases**

Then click:

**Draft a new release**

Do not use the old tag-creation workflow. We already have the correctly governed tag.

---

# Step 40 — Select the existing tag

Click **Choose a tag**.

Search for:

```text
module-2-g3-v2.0.0
```

Select that existing tag.

### Important

Do **not** type a different tag.

Do **not** click anything saying:

> Create new tag

We already proved that this tag resolves to:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

---

# Step 41 — Set the Release title

Enter exactly:

```text
Module 2 / G3 v2.0.0
```

---

# Step 42 — Paste the Release notes

Click inside the large Release-description field.

Press:

```text
Ctrl+V
```

You should see the contents of the repository's `RELEASE_NOTES.md`.

Use those notes rather than GitHub's automatically generated notes.

---

# Step 43 — Set the Release classification

Make sure:

```text
Set as the latest release     YES
Set as a pre-release          NO
```

If GitHub presents a **Create a discussion for this release** option, leave it unchecked unless you specifically want one.

---

# Step 44 — Attach the primary governed package

Find the section that says something similar to:

> Attach binaries by dropping them here or selecting them.

Upload:

```text
MSBF_M2G3_RELEASE_WINDOWS_R1.zip
```

Wait until it finishes uploading.

The file is about **71 MB**, so give it time.

Do not publish while the upload is still in progress.

---

# Step 45 — Attach the SHA-256 sidecar

Next upload:

```text
MSBF_M2G3_RELEASE_WINDOWS_R1.zip.sha256
```

This is important because it gives users a simple independent physical-identity check for the release archive.

---

# Step 46 — Attach the validation artifacts

You previously downloaded the publication assurance files. I recommend attaching these three as well:

```text
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md

MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json

MSBF_Transparency_Campaign_Navigation_File_Inventory.csv
```

So your final Release should have **five manually attached assets**:

```text
1. MSBF_M2G3_RELEASE_WINDOWS_R1.zip

2. MSBF_M2G3_RELEASE_WINDOWS_R1.zip.sha256

3. MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md

4. MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json

5. MSBF_Transparency_Campaign_Navigation_File_Inventory.csv
```

GitHub will separately provide its automatic **Source code (zip)** and **Source code (tar.gz)** downloads. Those are normal and are not substitutes for our governed ZIP.

---

# Step 47 — Do NOT attach these

Do not upload:

```text
MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip
MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip.sha256
```

Those contain the local Git worktree and `.git` state.

Also do not attach:

```text
ChatGPT_Logs.zip
```

The sanitized project-history projection is already inside the repository.

Do not attach old superseded candidates such as:

```text
MSBF_GitHub_Publication_Candidate_Transparency_Campaign_Reconciled...
MSBF_GitHub_Publication_Candidate_UPLOAD_READY...
MSBF_Transparency_Campaign_and_Navigation_Overlay...
```

The Release should look deliberate—not like a working directory dump.

---

# Step 48 — Save the Release as a draft first

Once all five assets have finished uploading, **do not publish immediately**.

Click:

**Save draft**

This gives us one last controlled checkpoint.

---

# Step 49 — Reopen the draft and inspect it

Open the draft Release.

Verify these fields exactly:

```text
Tag
module-2-g3-v2.0.0

Target
main / 500ec776...

Title
Module 2 / G3 v2.0.0

Latest release
YES

Pre-release
NO
```

Then inspect the assets.

You should have the five manually attached files above.

There should be no `UPLOAD_WORKTREE` ZIP.

There should be no raw ChatGPT export.

There should be no old candidate ZIP.

---

# Step 50 — Inspect the rendered Release notes

Scroll through the rendered notes.

We are checking for obvious presentation problems only:

- Markdown headings render properly.
- No raw local Windows paths.
- No unresolved placeholders.
- Module 2/G3 is described as accepted.
- Campaign-scale certification is described as current/next, not already completed.
- No production deployment claim.
- No causal optimization claim.
- No Module 3 execution claim.

Do not rewrite the Release notes at this stage unless there is an actual defect.

---

# Step 51 — Publish the Release

If Steps 37–50 all pass, click:

**Publish release**

That is the final publication action.

Once it succeeds, GitHub should take you to the public Release page.

---

# Step 52 — Confirm GitHub identifies it correctly

On the published Release page, verify:

```text
Module 2 / G3 v2.0.0

Latest
```

and that it is **not** labeled:

```text
Pre-release
```

Confirm the tag shown is:

```text
module-2-g3-v2.0.0
```

---

# Step 53 — Verify all five assets are downloadable

You should see:

```text
MSBF_M2G3_RELEASE_WINDOWS_R1.zip
MSBF_M2G3_RELEASE_WINDOWS_R1.zip.sha256
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json
MSBF_Transparency_Campaign_Navigation_File_Inventory.csv
```

plus GitHub's automatic source-code downloads.

Do not worry if GitHub displays file sizes differently from Windows because of MB/MiB conventions.

---

# Step 54 — Final independent clean-clone test

After the Release is published, we'll perform one last independent test of what a stranger cloning the tag receives.

First make sure this folder does not already exist:

```powershell
Test-Path "C:\v"
```

If it returns:

```text
False
```

continue.

If it returns `True`, stop and rename/delete the old verification folder before continuing.

Then run:

```powershell
git clone --branch module-2-g3-v2.0.0 --depth 1 https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git C:\v
```

When that finishes:

```powershell
Set-Location "C:\v"
```

Then:

```powershell
python tools\validate_public_release.py
```

We need:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

---

# Step 55 — Prove the published tag still equals final `main`

Run:

```powershell
git rev-parse HEAD
```

Expected:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

Then:

```powershell
Get-Content "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt"
```

Expected:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65
```

They must be identical.

---

# Step 56 — Check the clean clone is untouched

Run:

```powershell
git status --short --branch
```

Because you cloned a tag, you may see:

```text
## HEAD (no branch)
```

That's fine.

What matters is that there are **no file changes beneath it**.

---

# Step 57 — Final GitHub browser audit

After the clean-clone test passes, inspect four places in GitHub.

**Repository home:** README renders correctly and communicates the accepted Module 2/G3 state.

**Actions:** the Publication Integrity workflow associated with the merged `main` state is green.

**Module_2:** all M2.1–M2.12 stage folders are present and navigable.

**Release:** `Module 2 / G3 v2.0.0` is public, latest, correctly tagged, and has the governed assets.

At that point the publication is complete.

### Your next action right now

Proceed through **Steps 37–50 and save the GitHub Release as a draft**.

Before clicking **Publish release**, send me a screenshot of the draft Release page showing the tag/title and attached assets. I'll do the final pre-publication visual check with you.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cd4bf988-d14c-4b09-b1e4-a1f47220ebd8"></a>
## Andrew / user · C072-M00533

C072-M00533 · 2026-08-15T02:13:16.902000-04:00 · active path

Preceding visible parent: [C072-M00532](part-36.md#m-3d5cc7bc-63bd-48e1-bf90-adc1cc0fc130)

<!-- BEGIN_SOURCE_MESSAGE -->
in step 40 when drafting a new release, i do not see the module 2 tag when i search.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ef03df65-9b78-4a32-b9b6-5ba8f932f811"></a>
## Assistant · C072-M00534

C072-M00534 · 2026-08-15T02:13:22.993320-04:00 · active path

Preceding visible parent: [C072-M00533](part-36.md#m-cd4bf988-d14c-4b09-b1e4-a1f47220ebd8)

<!-- BEGIN_SOURCE_MESSAGE -->
Do **not** create a new tag in the Release screen. Since Step 36 passed, we first need to determine why GitHub's Release UI isn't offering the tag.

At `PS C:\x\m>`, run these commands one at a time.

1. Confirm the local tag exists:

```powershell
git tag --list module-2-g3-v2.0.0
```

Expected:

```text
module-2-g3-v2.0.0
```

2. Confirm the remote tag exists:

```powershell
git ls-remote --tags origin "refs/tags/module-2-g3-v2.0.0"
```

You should get a line ending in:

```text
refs/tags/module-2-g3-v2.0.0
```

Because this is an **annotated tag**, the hash on that particular line is the tag-object hash—not necessarily `500ec776...`. That's normal.

3. Now verify the commit behind the annotated remote tag:

```powershell
git ls-remote --tags origin "refs/tags/module-2-g3-v2.0.0^{}"
```

This is the critical one. Expected:

```text
500ec776ca25f1d4ade4eb45ecddb8df5e4f2e65    refs/tags/module-2-g3-v2.0.0^{}
```

### If all three commands pass

Then the tag **is definitely on GitHub**, and this is just a Release-page/UI selection issue.

Open the repository's Tags page directly:

[export reference: url | Repository tags | https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/tags]

You should see:

```text
module-2-g3-v2.0.0
```

and it should correspond to the final Module 2/G3 state.

If it appears there, go back to **Releases → Draft a new release**, refresh the page with:

```text
Ctrl + F5
```

Then click **Choose a tag** and search again for the **exact lowercase string**:

```text
module-2-g3-v2.0.0
```

Do not include spaces and do not search for `Module 2 / G3 v2.0.0`, because that's the release title rather than the tag name.

### If GitHub still doesn't show it

Don't create anything. Send me:

1. the output of those three PowerShell commands, and
2. a screenshot of the **Choose a tag** dropdown after searching.

We'll diagnose that exact state rather than risk creating a duplicate or incorrectly targeted tag.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2797e26d-71e0-476a-a8f9-afad7b0104a6"></a>
## Andrew / user · C072-M00535

C072-M00535 · 2026-08-15T02:21:40.039000-04:00 · active path

Preceding visible parent: [C072-M00534](part-36.md#m-ef03df65-9b78-4a32-b9b6-5ba8f932f811)

<!-- BEGIN_SOURCE_MESSAGE -->
PS C:\x\m> git tag --list module-2-g3-v2.0.0
module-2-g3-v2.0.0
PS C:\x\m> git ls-remote --tags origin "refs/tags/module-2-g3-v2.0.0"
PS C:\x\m>
<!-- END_SOURCE_MESSAGE -->
