# PostgreSQL M1.14 Execution

Part 35 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-34.md)
[Next part](part-36.md)

<a id="m-dad360ad-429d-4a23-89c0-6e3d995fb03b"></a>
## Assistant · C072-M00508

C072-M00508 · 2026-08-14T19:22:22.271497-04:00 · active path

Preceding visible parent: [C072-M00507](part-34.md#m-eb6a0f4f-8c51-44ef-8e68-8a19d5b87aba)

<!-- BEGIN_SOURCE_MESSAGE -->
# Important correction before you begin

**Do not publish the earlier `...Transparency_Campaign_Reconciled...zip` candidate as-is.**

During the upload-procedure review, I found that the earlier recreated worktree omitted the already-tracked:

```text
.github/workflows/publication_integrity.yml
```

That would have staged the deletion of your publication-integrity GitHub Action. The workflow is currently part of the public repository, so preserving it is required. [export reference: cite | turn371847view1]

I restored the exact tracked workflow, regenerated the repository-root manifests and inventories, reran the public-release validator, and rebuilt an **upload-ready superseding package**.

## Download these replacement artifacts

### Local Git worktree — use this to perform the commit

Download the upload-ready Git worktree candidate (historical reference: `sandbox:[session]/MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip.sha256`; referenced bytes not established here)

```text
Bytes       110,359,548
SHA-256     c6ca6ed524957931cd6c15c2d8eb152b2901613cfb9f1871c6034abf01870e9b
Includes    Existing .git history and remote configuration
Purpose     Local staging, review, commit, and push
```

### Governed GitHub Release asset — attach this to the Release

Download the governed Module 2/G3 release ZIP (historical reference: `sandbox:[session]/MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip.sha256`; referenced bytes not established here)

```text
Bytes       71,352,288
SHA-256     8ee23c2418e7c00772d2246699ce9a72a09d4c9f396ae15fc40484129787ee36
Includes    Repository content without .git
Purpose     GitHub Release attachment
```

### Supporting controls

- Upload-ready validation report (historical reference: `sandbox:[session]/MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md`; referenced bytes not established here)
- Machine-readable validation report (historical reference: `sandbox:[session]/MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json`; referenced bytes not established here)
- Downloadable PowerShell upload runbook (historical reference: `sandbox:[session]/MSBF_GitHub_UPLOAD_RUNBOOK_v2.0.0.md`; referenced bytes not established here)

Keep every downloaded ZIP **outside** the repository directory. Otherwise, `git add -A` could accidentally stage a large package that belongs in GitHub Releases rather than the Git tree. GitHub warns on ordinary repository files over 50 MiB, blocks files over 100 MiB, and recommends Releases for distributing larger binary packages. [export reference: cite | turn986566view2]

---

# Phase 1 — Create a separate staging worktree

Do not extract over:

```text
C:\Git\merchant-sales-based-financing-strategy-simulator
```

Keep that existing clone intact as your fallback.

The package contains long paths, so use a short extraction directory such as:

```text
C:\msbf-v2
```

Open **PowerShell** and run:

```powershell
$Zip = "$env:USERPROFILE\Downloads\MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip"
$ExpectedHash = "c6ca6ed524957931cd6c15c2d8eb152b2901613cfb9f1871c6034abf01870e9b"

$ActualHash = (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLower()

"Expected: $ExpectedHash"
"Observed: $ActualHash"

if ($ActualHash -ne $ExpectedHash) {
    throw "SHA-256 mismatch. Do not extract or use this package."
}
```

The expected and observed values must be identical.

Now prepare the staging directory:

```powershell
$Stage = "C:\msbf-v2"

if (Test-Path $Stage) {
    throw "$Stage already exists. Rename or remove it deliberately before proceeding."
}

New-Item -ItemType Directory -Path $Stage | Out-Null

git config --global core.longpaths true
```

Extract the package:

```powershell
tar -xf $Zip -C $Stage
```

The resulting repository should be:

```text
C:\msbf-v2\merchant-sales-based-financing-strategy-simulator
```

Set that as the active directory:

```powershell
$Repo = "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"
Set-Location $Repo
```

Should Windows `tar` report a path-length issue, use current 7-Zip and extract into the same short `C:\msbf-v2` directory. Avoid PowerShell `Expand-Archive` for this package because the deepest archive path is approximately 300 characters.

---

# Phase 2 — Verify the packaged Git repository

Run:

```powershell
git status --short --branch
git remote -v
git branch --show-current
git log -1 --oneline --decorate
```

You should see:

```text
Branch       main
Remote       https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
Base commit  f43ea8cb87523f477142fba2acea1be254c69e1a
```

The worktree will not be clean yet. That is expected: it contains the completed Module 2/G3 publication changes waiting to be committed.

Fetch the latest remote state without changing the worktree:

```powershell
git fetch origin --tags --prune
```

Now compare the package’s baseline to the current remote `main`:

```powershell
$LocalBase = (git rev-parse HEAD).Trim()
$RemoteBase = (git rev-parse origin/main).Trim()

"Package base: $LocalBase"
"Remote main:  $RemoteBase"

if ($LocalBase -ne $RemoteBase) {
    throw "origin/main changed after this package was built. Stop before staging or committing."
}
```

Both values should currently be:

```text
f43ea8cb87523f477142fba2acea1be254c69e1a
```

If they differ, do not pull, rebase, or force anything while the worktree has uncommitted publication changes. That would require a separate reconciliation step.

---

# Phase 3 — Confirm the workflow and deletion boundary

Verify that the workflow exists:

```powershell
Test-Path ".github\workflows\publication_integrity.yml"
```

Expected:

```text
True
```

Verify that Git does not show any tracked deletions:

```powershell
$Deleted = git status --short | Select-String '^ D|^D '

if ($Deleted) {
    $Deleted
    throw "Tracked deletions detected. Stop before committing."
}
```

That command should return no output.

The expected pre-staging state is:

```text
Modified tracked files         20
Collapsed untracked paths      15
Deleted tracked files           0
```

The “15 untracked paths” are mostly directories. After staging, they expand into 1,083 individual added files.

You can inspect the full current status:

```powershell
git status
```

Look particularly for:

```text
modified:
    README.md
    RELEASE_NOTES.md
    MANIFEST.csv
    manifest.json
    SHA256SUMS.txt
    ...

untracked:
    Module_2/
    docs/campaign_scale/
    docs/project_history/
    docs/executive_strategy/pages_v2/
    ...
```

You should **not** see:

```text
deleted: .github/workflows/publication_integrity.yml
```

---

# Phase 4 — Run all local publication gates

## 4.1 Run the repository validator

```powershell
py -3 tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Public release validation failed."
}
```

Expected output:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Should `py -3` not work but your prior `python` command does, use:

```powershell
python tools\validate_public_release.py
```

## 4.2 Run the tracked-diff whitespace check

```powershell
git diff --check

if ($LASTEXITCODE -ne 0) {
    throw "Tracked diff check failed."
}
```

This corrected package passes that command.

Do not normalize the accepted SQL, CSV, evidence, or provenance files merely to change their line endings. Many artifacts intentionally preserve their accepted physical bytes. The project validator and manifests, rather than wholesale text normalization, are the governing controls.

## 4.3 Verify root manifest counts

```powershell
$CsvManifestCount = (Import-Csv .\MANIFEST.csv).Count
$JsonManifestCount = (Get-Content .\manifest.json -Raw | ConvertFrom-Json).file_count

"MANIFEST.csv records: $CsvManifestCount"
"manifest.json count:   $JsonManifestCount"

if ($CsvManifestCount -ne 1930) {
    throw "MANIFEST.csv should contain exactly 1,930 governed records."
}

if ($JsonManifestCount -ne 1930) {
    throw "manifest.json should report exactly 1,930 governed records."
}
```

Verify that the restored GitHub Action is governed by the manifest:

```powershell
Select-String `
    -Path .\MANIFEST.csv `
    -Pattern '^\.github/workflows/publication_integrity\.yml,'
```

Expected record:

```text
.github/workflows/publication_integrity.yml,359,9c2535f1ab9d484b55fbaeff023e05bcd136cbeee7e43b407fc6073aa65587ed
```

## 4.4 Inspect the largest ordinary repository files

```powershell
$Files = Get-ChildItem -Recurse -Force -File |
    Where-Object { $_.FullName -notlike "$Repo\.git\*" } |
    Sort-Object Length -Descending

$Files |
    Select-Object -First 15 FullName, Length |
    Format-Table -AutoSize
```

Then enforce the GitHub hard boundary:

```powershell
$Oversize = $Files | Where-Object Length -ge 100MB

if ($Oversize) {
    $Oversize | Format-Table FullName, Length
    throw "A regular repository file is 100 MiB or larger."
}
```

The validated candidate has:

```text
Files over 50 MiB       0
Files over 100 MiB      0
Largest repository file approximately 9.1 MB
```

GitHub’s current ordinary-Git limits are a warning above 50 MiB and a hard block above 100 MiB; larger distributable packages belong in a GitHub Release. [export reference: cite | turn986566view2]

---

# Phase 5 — Create the final release branch

Do not commit directly from `main` yet. Create a final release branch:

```powershell
$Branch = "release/module-2-g3-v2.0.0-final"
git switch -c $Branch
```

If that branch name already exists locally, stop and inspect it:

```powershell
git branch --list $Branch
```

Do not delete an existing branch unless you have confirmed it contains no needed work. A safe alternate name would be:

```text
release/module-2-g3-v2.0.0-publication-final
```

Confirm the active branch:

```powershell
git branch --show-current
```

Expected:

```text
release/module-2-g3-v2.0.0-final
```

---

# Phase 6 — Stage and inspect the publication commit

Stage all additions and modifications:

```powershell
git add -A
```

## 6.1 Confirm that no file is staged for deletion

```powershell
git diff --cached --name-status | Select-String '^D'
```

Expected: **no output**.

## 6.2 Confirm that no downloaded ZIP is staged

```powershell
git diff --cached --name-only |
    Select-String '\.zip(\.sha256)?$'
```

Expected: **no output**.

If a ZIP appears, remove it from the Git index and move it outside the repository:

```powershell
git restore --staged "PATH_TO_FILE"
```

Do not use `git rm` unless you truly intend to delete a previously tracked file.

## 6.3 Inspect the staged summary

```powershell
git diff --cached --stat
```

For this exact package and baseline, the expected totals are:

```text
Added       1,083
Modified       20
Deleted         0
Total       1,103
```

You can calculate them directly:

```powershell
$Staged = git diff --cached --name-status

$Added = @($Staged | Where-Object { $_ -match '^A' }).Count
$Modified = @($Staged | Where-Object { $_ -match '^M' }).Count
$Deleted = @($Staged | Where-Object { $_ -match '^D' }).Count

"Added:    $Added"
"Modified: $Modified"
"Deleted:  $Deleted"
```

Expected:

```text
Added:    1083
Modified: 20
Deleted:  0
```

If the remote baseline matched and these counts are materially different, stop before committing.

## 6.4 Review the most important staged documents

```powershell
git diff --cached -- README.md
git diff --cached -- RELEASE_NOTES.md
git diff --cached -- GITHUB_PUBLICATION_GUIDE.md
git diff --cached -- MODULE_AND_RELEASE_INDEX.md
git diff --cached -- PROJECT_ARTIFACT_MAP.md
git diff --cached -- PROJECT_ROADMAP.md
git diff --cached -- docs\README.md
git diff --cached -- Module_2\README.md
```

For large generated manifests, inspect only their headers and relevant records rather than scrolling the entire diff:

```powershell
Get-Content .\MANIFEST.csv -TotalCount 10
Get-Content .\SHA256SUMS.txt -TotalCount 10
```

---

# Phase 7 — Commit the release branch

Create the release commit:

```powershell
git commit -m "Publish Module 2 / G3 v2.0.0"
```

Run validation again against the committed tree:

```powershell
py -3 tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Post-commit public release validation failed."
}
```

Confirm the worktree is clean:

```powershell
git status --short --branch
```

Expected:

```text
## release/module-2-g3-v2.0.0-final
```

There should be no modified, added, deleted, or untracked entries below it.

Record the commit:

```powershell
$ReleaseBranchCommit = (git rev-parse HEAD).Trim()
"Release branch commit: $ReleaseBranchCommit"
```

---

# Phase 8 — Push the release branch

Push the release branch to GitHub:

```powershell
git push -u origin $Branch
```

GitHub’s standard syntax is `git push REMOTE BRANCH`; pushing a single tag later uses the same pattern. [export reference: cite | turn986566view1]

Your remote is HTTPS. Since you have pushed successfully before, Git Credential Manager will likely reuse your authenticated session. If Git asks for a password, do not enter your GitHub account password; GitHub command-line HTTPS authentication uses a personal access token or a credential helper such as Git Credential Manager. SSH is the other supported command-line route. [export reference: cite | turn329423search0]

---

# Phase 9 — Open and merge a pull request

On GitHub:

1. Open the repository.
2. GitHub should display a banner for the newly pushed branch.
3. Select **Compare & pull request**.
4. Set:

```text
Base branch       main
Compare branch    release/module-2-g3-v2.0.0-final
```

5. Use this title:

```text
Publish Module 2 / G3 v2.0.0
```

6. Suggested PR description:

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

7. Review the **Files changed** tab.
8. Confirm `.github/workflows/publication_integrity.yml` is **not** deleted.
9. Wait for the **Publication Integrity** GitHub Action to pass.
10. Merge the PR into `main`.
11. Delete the remote release branch after the merge succeeds.

The workflow runs on pull requests and invokes:

```text
python tools/validate_public_release.py
```

Using a PR allows that control to run before the release is placed on `main`.

---

# Phase 10 — Synchronize final `main`

Back in PowerShell:

```powershell
git switch main
git fetch origin --tags --prune
git pull --ff-only origin main
```

Run the validator against final `main`:

```powershell
py -3 tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Final-main validation failed."
}
```

Confirm local and remote `main` are identical:

```powershell
$FinalMain = (git rev-parse HEAD).Trim()
$RemoteMain = (git rev-parse origin/main).Trim()

"Local main:  $FinalMain"
"Remote main: $RemoteMain"

if ($FinalMain -ne $RemoteMain) {
    throw "Local main and origin/main do not match."
}
```

Confirm the worktree is clean:

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

# Phase 11 — Correct the prematurely created tag

You previously pushed:

```text
module-2-g3-v2.0.0
```

before the final release commit existed. It must be recreated only after final `main` is published.

First inspect whether the remote tag exists:

```powershell
$Tag = "module-2-g3-v2.0.0"

git ls-remote --tags origin "refs/tags/$Tag*"
```

If output appears, the remote tag exists.

## 11.1 Check for an existing GitHub Release

Open the repository’s **Releases** page.

If a GitHub Release was already published using the premature tag, delete that Release before deleting and recreating the tag. GitHub permits repository collaborators with write access to create, edit, or delete Releases. [export reference: cite | turn986566view0]

Your current repository appears not to have a published Release, but verify in the browser before proceeding.

## 11.2 Delete the old local tag, when present

```powershell
if (git tag --list $Tag) {
    git tag -d $Tag
}
```

## 11.3 Delete the old remote tag, when present

```powershell
$RemoteTag = git ls-remote --tags origin "refs/tags/$Tag"

if ($RemoteTag) {
    git push origin ":refs/tags/$Tag"
}
```

GitHub documents the empty-source refspec form—pushing nothing to the remote reference—as the standard way to delete a remote branch or tag. [export reference: cite | turn986566view1]

## 11.4 Create the final annotated tag

```powershell
git tag -a $Tag -m "Module 2 / G3 v2.0.0"
git push origin $Tag
```

## 11.5 Prove that the tag points to final `main`

```powershell
$TagCommit = (git rev-list -n 1 $Tag).Trim()

"Final main commit: $FinalMain"
"Tag commit:        $TagCommit"

if ($TagCommit -ne $FinalMain) {
    throw "The release tag does not point to final main."
}
```

The two hashes must be identical.

---

# Phase 12 — Create the GitHub Release

On GitHub:

1. Open the repository.
2. Select **Releases**.
3. Select **Draft a new release**.
4. Choose the existing tag:

```text
module-2-g3-v2.0.0
```

5. Use the release title:

```text
Module 2 / G3 v2.0.0
```

6. Use the repository’s `RELEASE_NOTES.md` as the release description.
7. Select **Set as latest release**.
8. Do not mark it as a prerelease.
9. Save it as a draft before publishing.
10. Attach all final assets while it remains a draft.
11. Publish only after the asset list and hashes are verified.

GitHub’s release workflow supports choosing an existing tag, entering release notes, attaching binary assets, saving a draft, and then publishing. GitHub specifically recommends drafting first when immutable releases are enabled so all assets are present before publication. [export reference: cite | turn986566view0]

## Required governed release attachments

Attach:

```text
MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip
MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip.sha256
```

Expected release-package identity:

```text
SHA-256
8ee23c2418e7c00772d2246699ce9a72a09d4c9f396ae15fc40484129787ee36
```

## Recommended supplementary attachments

Attach these as release-assurance artifacts:

```text
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json
MSBF_Transparency_Campaign_Navigation_File_Inventory.csv
```

You already downloaded the inventory from the previous delivery.

## Do not attach or commit

Do not attach these to the public Release:

```text
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip
```

Reason: it contains `.git` internals and exists solely as a local staging worktree.

Do not attach:

```text
MSBF_Transparency_Campaign_and_Navigation_Overlay_v2.0.0.zip
```

Reason: it is an integration aid, not a public release deliverable.

Do not attach:

```text
ChatGPT_Logs.zip
```

Reason: the repository already contains the sanitized, searchable, governed transparency projection. The raw source archive should remain private.

Do not attach a Module 2 full synthetic data-state package unless it has separately completed:

```text
public-content review
PII/credential scan
inventory reconciliation
ZIP CRC
SHA-256 sidecar
release metadata
```

The code/documentation Release can be published without presenting an unvalidated data-state package as final.

---

# Phase 13 — Perform an independent clean-clone test

After the tag and Release are public, validate what an outside user actually receives.

Use a fresh directory:

```powershell
$VerifyRoot = "C:\msbf-release-verify"

if (Test-Path $VerifyRoot) {
    Remove-Item $VerifyRoot -Recurse -Force
}
```

Clone the released tag:

```powershell
git clone `
    --branch module-2-g3-v2.0.0 `
    --depth 1 `
    https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git `
    $VerifyRoot
```

Enter the clone:

```powershell
Set-Location $VerifyRoot
```

Run the validator:

```powershell
py -3 tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Clean-clone validation failed."
}
```

Expected:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Verify the clone is clean:

```powershell
git status --short --branch
```

Verify the tag commit:

```powershell
git rev-parse HEAD
```

It must equal the final `main` and tag commit recorded earlier.

---

# Phase 14 — Final browser review

Before declaring publication complete, inspect GitHub in the browser and confirm all of the following:

### Repository landing page

- The README says Module 1/G2 and Module 2/G3 are accepted.
- Campaign Scale Certification is identified as current.
- The current architecture and ten-page executive brief render.
- No old “Module 2 authorized next” lead framing remains.

### Module 2 tree

- `Module_2/` is visible.
- It contains M2.1 through M2.12.
- Stage links open correctly.
- BRD, validation, provenance, source, recovery, and catalogs are navigable.

### Documentation

- `docs/campaign_scale/` renders.
- `docs/project_history/` renders.
- The sanitized conversation archive is searchable.
- No raw private ChatGPT export appears.
- Enterprise architecture and executive-strategy README links work.

### GitHub Actions

- **Publication Integrity** is green on final `main`.
- The action validates 1,930 manifest files and 12 Module 2 stages.

### Tag

- `module-2-g3-v2.0.0` exists.
- It resolves to the final `main` commit.
- The old premature tag no longer points to the pre-release commit.

### Release

- Title is `Module 2 / G3 v2.0.0`.
- It is marked latest.
- It is not marked prerelease.
- Release notes match `RELEASE_NOTES.md`.
- The governed ZIP and SHA-256 sidecar are attached.
- The asset hash matches the sidecar.

---

# Publication completion standard

The update is complete only when all of these are true:

```text
Local upload-ready validation                 PASS
Release branch committed                      YES
Pull request validation                       PASS
Final main validation                         PASS
Publication Integrity GitHub Action           PASS
Premature tag replaced                        YES
Tag commit = final main commit                YES
GitHub Release published                      YES
Governed release ZIP attached                 YES
Release ZIP SHA-256 verified                  PASS
Independent clean-clone validation            PASS
Local worktree                                CLEAN
```

The downloadable runbook (historical reference: `sandbox:[session]/MSBF_GitHub_UPLOAD_RUNBOOK_v2.0.0.md`; referenced bytes not established here) contains the same commands in one consolidated file for use alongside PowerShell.
<!-- END_SOURCE_MESSAGE -->


<a id="m-53edba5e-1298-4f9a-b98c-ae1a1416387f"></a>
## Andrew / user · C072-M00509

C072-M00509 · 2026-08-14T19:42:47.053000-04:00 · active path

Preceding visible parent: [C072-M00508](part-35.md#m-dad360ad-429d-4a23-89c0-6e3d995fb03b)

<!-- BEGIN_SOURCE_MESSAGE -->
Your instructions are a little too generic. I've downloaded all your new files. Give the the "for dummies" step by explicit step.
<!-- END_SOURCE_MESSAGE -->


<a id="m-79809c55-0d57-4882-bd07-6d07b33a81ca"></a>
## Assistant · C072-M00510

C072-M00510 · 2026-08-14T20:02:25.087545-04:00 · active path

Preceding visible parent: [C072-M00509](part-35.md#m-53edba5e-1298-4f9a-b98c-ae1a1416387f)

<!-- BEGIN_SOURCE_MESSAGE -->
# Use this exact sequence

The repository update is **not** performed by dragging the 110 MB worktree ZIP into GitHub. You will:

1. Extract the **UPLOAD_READY** ZIP into a new local folder.
2. Use Git to commit and push the repository changes to a release branch.
3. Merge that branch into `main` through a pull request.
4. Recreate the premature release tag at the final `main` commit.
5. Upload the smaller **Strategy_Simulator** ZIP as a GitHub **Release asset**.

GitHub’s standard model is to push local commits with `git push`, while binary distribution packages can be attached to a Release. [export reference: cite | turn792726view1 | turn792726view0 | turn792726view3]

**Do not touch or replace your existing folder:**

```text
C:\Git\merchant-sales-based-financing-strategy-simulator
```

Keep it as your fallback copy.

At any checkpoint below, if the output differs from the stated expected result, **stop at that exact step rather than improvising**.

---

# Part 1 — Organize the downloaded files

## Step 1 — Create a release-files folder

Using File Explorer:

1. Open `This PC`.
2. Open `Local Disk (C:)`.
3. Create a new folder named:

```text
MSBF_RELEASE_FILES
```

The resulting path is:

```text
C:\MSBF_RELEASE_FILES
```

## Step 2 — Move the downloaded artifacts into that folder

Move these files from Downloads into `C:\MSBF_RELEASE_FILES`:

```text
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip.sha256

MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip
MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip.sha256

MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json

MSBF_Transparency_Campaign_Navigation_File_Inventory.csv
MSBF_GitHub_UPLOAD_RUNBOOK_v2.0.0.md
```

If Windows added suffixes such as `(1)`, rename the files so their names exactly match those above.

Do **not** put any of these downloaded ZIP files inside either Git repository.

## Step 3 — Understand which ZIP does what

| File | What you do with it |
|---|---|
| `MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip` | Extract locally and use it to make the Git commit |
| `MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip` | Upload later as a GitHub Release asset |
| `...VALIDATION_REPORT.md/.json` | Upload later as supporting Release assets |
| `...FILE_INVENTORY.csv` | Upload later as a supporting Release asset |
| `MSBF_GitHub_UPLOAD_RUNBOOK_v2.0.0.md` | Personal reference only; do not commit or attach |

Do **not** use the older packages named:

```text
MSBF_GitHub_Publication_Candidate_Transparency_Campaign_Reconciled...
MSBF_GitHub_Publication_Candidate_...NO_GIT...
MSBF_Transparency_Campaign_and_Navigation_Overlay...
```

The governing local package is the one containing:

```text
UPLOAD_READY_v2.0.0
```

---

# Part 2 — Verify the downloaded ZIP files

## Step 4 — Open PowerShell

1. Click the Windows Start button.
2. Type:

```text
PowerShell
```

3. Open **Windows PowerShell** or **PowerShell**.
4. You do not need to run it as Administrator.

## Step 5 — Paste this complete hash-check block

```powershell
$ReleaseFiles = "C:\MSBF_RELEASE_FILES"

$WorktreeZip = Join-Path $ReleaseFiles `
    "MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip"

$ReleaseZip = Join-Path $ReleaseFiles `
    "MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip"

$ExpectedWorktreeHash = `
    "c6ca6ed524957931cd6c15c2d8eb152b2901613cfb9f1871c6034abf01870e9b"

$ExpectedReleaseHash = `
    "8ee23c2418e7c00772d2246699ce9a72a09d4c9f396ae15fc40484129787ee36"

if (-not (Test-Path -LiteralPath $WorktreeZip)) {
    throw "The UPLOAD_READY worktree ZIP was not found at $WorktreeZip"
}

if (-not (Test-Path -LiteralPath $ReleaseZip)) {
    throw "The governed Release ZIP was not found at $ReleaseZip"
}

$ObservedWorktreeHash = `
    (Get-FileHash -LiteralPath $WorktreeZip -Algorithm SHA256).Hash.ToLower()

$ObservedReleaseHash = `
    (Get-FileHash -LiteralPath $ReleaseZip -Algorithm SHA256).Hash.ToLower()

"UPLOAD_READY expected: $ExpectedWorktreeHash"
"UPLOAD_READY observed: $ObservedWorktreeHash"
""
"RELEASE ZIP expected:  $ExpectedReleaseHash"
"RELEASE ZIP observed:  $ObservedReleaseHash"

if ($ObservedWorktreeHash -ne $ExpectedWorktreeHash) {
    throw "UPLOAD_READY ZIP SHA-256 mismatch. Do not continue."
}

if ($ObservedReleaseHash -ne $ExpectedReleaseHash) {
    throw "Release ZIP SHA-256 mismatch. Do not continue."
}

Write-Host ""
Write-Host "BOTH SHA-256 CHECKS PASS" -ForegroundColor Green
```

## What you must see

The final line must say:

```text
BOTH SHA-256 CHECKS PASS
```

The observed hashes must exactly equal:

```text
UPLOAD_READY
c6ca6ed524957931cd6c15c2d8eb152b2901613cfb9f1871c6034abf01870e9b

RELEASE ZIP
8ee23c2418e7c00772d2246699ce9a72a09d4c9f396ae15fc40484129787ee36
```

---

# Part 3 — Extract the upload-ready Git repository

## Step 6 — Make sure the staging folder does not already exist

The new working location will be:

```text
C:\msbf-v2
```

If `C:\msbf-v2` already exists from a previous attempt:

1. Open File Explorer.
2. Rename it to something such as:

```text
C:\msbf-v2-old
```

Do not overwrite it.

## Step 7 — Paste this extraction block

```powershell
$ReleaseFiles = "C:\MSBF_RELEASE_FILES"

$WorktreeZip = Join-Path $ReleaseFiles `
    "MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip"

$StageRoot = "C:\msbf-v2"

if (Test-Path -LiteralPath $StageRoot) {
    throw "$StageRoot already exists. Rename it before continuing."
}

New-Item -ItemType Directory -Path $StageRoot | Out-Null

git config --global core.longpaths true

tar.exe -xf $WorktreeZip -C $StageRoot

if ($LASTEXITCODE -ne 0) {
    throw "ZIP extraction failed. Do not continue."
}

$Repo = Join-Path $StageRoot `
    "merchant-sales-based-financing-strategy-simulator"

if (-not (Test-Path -LiteralPath "$Repo\.git")) {
    throw "The extracted .git directory was not found."
}

if (-not (Test-Path -LiteralPath `
    "$Repo\.github\workflows\publication_integrity.yml")) {
    throw "The publication-integrity workflow was not found."
}

if (-not (Test-Path -LiteralPath "$Repo\README.md")) {
    throw "The root README was not found."
}

Set-Location $Repo

Write-Host "EXTRACTION PASS" -ForegroundColor Green
Write-Host "Repository: $Repo"
```

## What you must see

The final output should include:

```text
EXTRACTION PASS
Repository: C:\msbf-v2\merchant-sales-based-financing-strategy-simulator
```

Your PowerShell prompt should now begin with something similar to:

```text
PS C:\msbf-v2\merchant-sales-based-financing-strategy-simulator>
```

### Only if `tar.exe` fails

Use 7-Zip:

1. Right-click `MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip`.
2. Select **7-Zip**.
3. Select **Extract files...**
4. Enter:

```text
C:\msbf-v2\
```

5. After extraction, return to PowerShell and run:

```powershell
Set-Location `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"
```

---

# Part 4 — Confirm that the Git baseline is still valid

## Step 8 — Run the Git identity commands

Paste:

```powershell
Set-Location `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"

git branch --show-current
git remote -v
git log -1 --oneline --decorate
```

## Expected results

The current branch should be:

```text
main
```

The remote should contain:

```text
https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
```

The current commit must begin with:

```text
f43ea8c
```

## Step 9 — Fetch the current GitHub state and compare it

Paste this entire block:

```powershell
Set-Location `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"

git fetch origin --tags --prune

if ($LASTEXITCODE -ne 0) {
    throw "git fetch failed."
}

$ExpectedBase = `
    "f43ea8cb87523f477142fba2acea1be254c69e1a"

$LocalBase = (git rev-parse HEAD).Trim()
$RemoteBase = (git rev-parse origin/main).Trim()

"Expected base: $ExpectedBase"
"Local base:    $LocalBase"
"Remote main:   $RemoteBase"

if ($LocalBase -ne $ExpectedBase) {
    throw "The extracted package is not at the expected baseline."
}

if ($RemoteBase -ne $ExpectedBase) {
    throw "GitHub main changed after the package was built. Stop here."
}

Write-Host ""
Write-Host "BASELINE RECONCILIATION PASS" -ForegroundColor Green
```

## What you must see

All three hashes must be:

```text
f43ea8cb87523f477142fba2acea1be254c69e1a
```

The final line must say:

```text
BASELINE RECONCILIATION PASS
```

If GitHub opens a browser sign-in prompt later during a push, complete the browser authentication. If Git asks directly for a password over HTTPS, GitHub requires a personal access token rather than your normal account password; Git Credential Manager may handle this automatically. [export reference: cite | turn792726view2]

---

# Part 5 — Validate the unpublished repository

## Step 10 — Confirm the expected pre-commit changes

Paste:

```powershell
Set-Location `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"

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

"Modified tracked files: $ModifiedCount"
"Collapsed untracked paths: $UntrackedCount"
"Deleted tracked files: $DeletedCount"

if ($ModifiedCount -ne 20) {
    throw "Expected 20 modified tracked files."
}

if ($UntrackedCount -ne 15) {
    throw "Expected 15 collapsed untracked paths."
}

if ($DeletedCount -ne 0) {
    throw "Tracked deletions were detected."
}

Write-Host ""
Write-Host "PRE-STAGING STATUS PASS" -ForegroundColor Green
```

## Expected result

```text
Modified tracked files: 20
Collapsed untracked paths: 15
Deleted tracked files: 0

PRE-STAGING STATUS PASS
```

The `15` refers to untracked paths as Git summarizes them before staging. Many are directories containing numerous files.

## Step 11 — Run the publication validator

Paste:

```powershell
python tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Public release validation failed."
}
```

If Windows says `python` is not recognized, use:

```powershell
py -3 tools\validate_public_release.py
```

## Expected result

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Nothing else is an acceptable result.

## Step 12 — Run the Git whitespace check

Paste:

```powershell
git diff --check

if ($LASTEXITCODE -ne 0) {
    throw "git diff --check failed."
}

Write-Host "GIT DIFF CHECK PASS" -ForegroundColor Green
```

`git diff --check` should print **nothing** before:

```text
GIT DIFF CHECK PASS
```

No output from `git diff --check` is good.

## Step 13 — Check the root manifests

Paste:

```powershell
$ManifestCsvCount = (Import-Csv .\MANIFEST.csv).Count

$ManifestJson = Get-Content .\manifest.json -Raw |
    ConvertFrom-Json

$ManifestJsonCount = $ManifestJson.file_count

"MANIFEST.csv governed records: $ManifestCsvCount"
"manifest.json governed records: $ManifestJsonCount"

if ($ManifestCsvCount -ne 1930) {
    throw "MANIFEST.csv does not contain 1,930 records."
}

if ($ManifestJsonCount -ne 1930) {
    throw "manifest.json does not report 1,930 records."
}

$WorkflowManifestRecord = Select-String `
    -Path .\MANIFEST.csv `
    -Pattern '^\.github/workflows/publication_integrity\.yml,'

if (-not $WorkflowManifestRecord) {
    throw "Publication Integrity workflow is absent from MANIFEST.csv."
}

$WorkflowManifestRecord.Line

Write-Host ""
Write-Host "ROOT MANIFEST CHECK PASS" -ForegroundColor Green
```

## Expected manifest record

You should see:

```text
.github/workflows/publication_integrity.yml,359,9c2535f1ab9d484b55fbaeff023e05bcd136cbeee7e43b407fc6073aa65587ed
```

## Step 14 — Check that no oversized file will be committed

Paste:

```powershell
$Repo = `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"

$OversizedFiles = Get-ChildItem `
    -Path $Repo `
    -Recurse `
    -Force `
    -File |
    Where-Object {
        $_.FullName -notlike "$Repo\.git\*" -and
        $_.Length -ge 100MB
    }

if ($OversizedFiles) {
    $OversizedFiles |
        Select-Object FullName, Length |
        Format-Table -AutoSize

    throw "At least one regular repository file is 100 MiB or larger."
}

Write-Host "GITHUB FILE-SIZE CHECK PASS" -ForegroundColor Green
```

Expected:

```text
GITHUB FILE-SIZE CHECK PASS
```

The larger distributable ZIP belongs in the Release, not the regular Git tree. GitHub blocks ordinary Git files larger than 100 MiB and recommends Releases for distributing large binaries. [export reference: cite | turn792726view3]

---

# Part 6 — Create the release branch

## Step 15 — Check your commit-author identity

Paste:

```powershell
git config user.name
git config user.email
```

You should see your preferred public Git author name and email.

If one or both are blank, set them before committing:

```powershell
git config --global user.name "Andrew Goad"
git config --global user.email "YOUR_GITHUB_COMMIT_EMAIL"
```

Replace `YOUR_GITHUB_COMMIT_EMAIL` with the email you want associated with your public commits. A GitHub-provided no-reply email is appropriate when you do not want a personal address exposed publicly.

## Step 16 — Create the release branch

Paste:

```powershell
$Branch = "release/module-2-g3-v2.0.0-final"

git switch -c $Branch

if ($LASTEXITCODE -ne 0) {
    throw "The release branch could not be created."
}

git branch --show-current
```

Expected:

```text
release/module-2-g3-v2.0.0-final
```

If Git says the branch already exists, stop. Do not delete or overwrite it blindly.

---

# Part 7 — Stage and inspect the release changes

## Step 17 — Stage everything

Paste:

```powershell
git add -A

if ($LASTEXITCODE -ne 0) {
    throw "git add failed."
}
```

`git add -A` does **not** upload anything. It only prepares the local files for the commit.

## Step 18 — Count the staged changes

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

"Added:    $AddedCount"
"Modified: $ModifiedCount"
"Deleted:  $DeletedCount"
"Total:    $($AddedCount + $ModifiedCount + $DeletedCount)"

if ($AddedCount -ne 1083) {
    throw "Expected exactly 1,083 added files."
}

if ($ModifiedCount -ne 20) {
    throw "Expected exactly 20 modified files."
}

if ($DeletedCount -ne 0) {
    throw "No files should be staged for deletion."
}

Write-Host ""
Write-Host "STAGED FILE COUNTS PASS" -ForegroundColor Green
```

## Exact expected result

```text
Added:    1083
Modified: 20
Deleted:  0
Total:    1103

STAGED FILE COUNTS PASS
```

## Step 19 — Prove that no ZIP was accidentally staged

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

## Step 20 — Prove that the workflow is not being deleted

Paste:

```powershell
$WorkflowChange = git diff --cached --name-status -- `
    ".github/workflows/publication_integrity.yml"

if ($WorkflowChange) {
    $WorkflowChange
    throw "The Publication Integrity workflow unexpectedly changed."
}

Write-Host "PUBLICATION WORKFLOW PRESERVED — PASS" `
    -ForegroundColor Green
```

Expected:

```text
PUBLICATION WORKFLOW PRESERVED — PASS
```

## Step 21 — Display the staged summary

Paste:

```powershell
git diff --cached --stat
```

The final summary line should be approximately:

```text
1103 files changed, 359879 insertions(+), 4325 deletions(-)
```

The critical controls are:

```text
1103 files changed
1083 added
20 modified
0 deleted
```

---

# Part 8 — Commit the update

## Step 22 — Create the release commit

Paste:

```powershell
git commit -m "Publish Module 2 / G3 v2.0.0"

if ($LASTEXITCODE -ne 0) {
    throw "git commit failed."
}
```

## Step 23 — Validate the committed tree

Paste:

```powershell
python tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Post-commit publication validation failed."
}

git status --short --branch
```

Expected validator output:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

Expected status:

```text
## release/module-2-g3-v2.0.0-final
```

There should be **nothing underneath** that branch line.

If modified or untracked files appear after the commit, do not push.

---

# Part 9 — Push the release branch to GitHub

## Step 24 — Push the branch

Paste:

```powershell
git push -u origin release/module-2-g3-v2.0.0-final

if ($LASTEXITCODE -ne 0) {
    throw "The release branch push failed."
}
```

GitHub’s syntax for publishing a local branch is `git push REMOTE BRANCH`; after the branch is pushed, it can be used as the source of a pull request. [export reference: cite | turn792726view1]

You may see:

- a browser authentication window;
- a Git Credential Manager window;
- a GitHub authorization prompt.

Complete the sign-in and return to PowerShell.

## Expected ending

You should see output indicating a new remote branch such as:

```text
[new branch] release/module-2-g3-v2.0.0-final
```

You may also see a GitHub message containing a pull-request link. You do not need to copy that link.

---

# Part 10 — Create the pull request on GitHub

## Step 25 — Copy the pull-request description to your clipboard

Paste this into PowerShell:

```powershell
$PrBody = @'
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
'@

$PrBody | Set-Clipboard

Write-Host "PR description copied to clipboard." `
    -ForegroundColor Green
```

## Step 26 — Open the repository in your browser

1. Open GitHub.
2. Open your repository:

```text
merchant-sales-based-financing-strategy-simulator
```

3. Make sure you are on the **Code** tab.

GitHub normally displays a yellow banner for the newly pushed branch. Its documented workflow is to click **Compare & pull request**, confirm the base and compare branches, enter a title and description, and create the pull request. [export reference: cite | turn216391search0]

## Step 27 — Click the pull-request banner

Click:

```text
Compare & pull request
```

If the yellow banner is absent:

1. Click **Pull requests**.
2. Click **New pull request**.
3. Set:

```text
base: main
compare: release/module-2-g3-v2.0.0-final
```

## Step 28 — Complete the pull-request form

Verify the branch fields:

```text
base repository:    andrew-goad/merchant-sales-based-financing-strategy-simulator
base branch:        main

head repository:    andrew-goad/merchant-sales-based-financing-strategy-simulator
compare branch:     release/module-2-g3-v2.0.0-final
```

Enter this title:

```text
Publish Module 2 / G3 v2.0.0
```

Click in the description field and press:

```text
Ctrl + V
```

That pastes the PR description copied in Step 25.

Click:

```text
Create pull request
```

Do not create it as a draft.

---

# Part 11 — Review and merge the pull request

## Step 29 — Wait for Publication Integrity

On the pull-request page, scroll toward the merge section.

Look for the check named something similar to:

```text
Publication Integrity
```

Wait until it has a green check.

Do **not** merge while it says:

```text
Queued
In progress
Pending
Expected
```

If the check is red:

1. Click **Details** beside the failed check.
2. Read the final error.
3. Do not merge.

Workflow activity can also be reviewed from the repository’s **Actions** tab by opening the workflow and then its specific run. [export reference: cite | turn132093search5]

## Step 30 — Review the changed files

Click:

```text
Files changed
```

Verify:

- the Module 2 tree exists;
- `docs/campaign_scale/` exists;
- `docs/project_history/` exists;
- the architecture and executive-strategy files exist;
- `.github/workflows/publication_integrity.yml` is **not** shown as deleted;
- no large staging ZIP is included.

GitHub’s Files changed view shows the proposed branch changes relative to the base branch. [export reference: cite | turn216391search8]

## Step 31 — Merge

Once the check is green:

1. Return to the **Conversation** tab.
2. Click the green:

```text
Merge pull request
```

3. Click:

```text
Confirm merge
```

Use the ordinary merge option rather than rebase.

## Step 32 — Delete the merged release branch

After the merge succeeds, click:

```text
Delete branch
```

This only deletes the remote release branch. The merged content remains on `main`.

---

# Part 12 — Update your local `main`

Return to PowerShell.

## Step 33 — Synchronize local `main`

Paste:

```powershell
$Repo = `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"

Set-Location $Repo

git switch main

git fetch origin --tags --prune

git pull --ff-only origin main

if ($LASTEXITCODE -ne 0) {
    throw "Final main synchronization failed."
}
```

## Step 34 — Validate final `main`

Paste:

```powershell
python tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Final-main publication validation failed."
}

$FinalMain = (git rev-parse HEAD).Trim()
$RemoteMain = (git rev-parse origin/main).Trim()

"Local main:  $FinalMain"
"Remote main: $RemoteMain"

if ($FinalMain -ne $RemoteMain) {
    throw "Local main and origin/main do not match."
}

$FinalMain |
    Set-Content `
        "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt"

git status

Write-Host ""
Write-Host "FINAL MAIN PASS" -ForegroundColor Green
Write-Host "Final commit: $FinalMain"
```

## Expected result

The two commit hashes must match.

Git status must say:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

The validator must again say:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

A text file containing the final commit will now exist at:

```text
C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt
```

---

# Part 13 — Remove the premature tag

The prior tag:

```text
module-2-g3-v2.0.0
```

was created before this final publication commit. It must be removed and recreated.

## Step 35 — Check GitHub for an existing Release first

In your browser:

1. Open the repository.
2. Click **Releases**.

If there is already a published or draft Release named:

```text
Module 2 / G3 v2.0.0
```

delete that Release before changing the tag.

To delete it:

1. Open the Release.
2. Use the delete/trash option.
3. Confirm **Delete this release**.

Deleting a GitHub Release is separate from deleting its Git tag. GitHub supports managing and deleting Releases from the Releases page. [export reference: cite | turn792726view0]

If there is no Release, proceed directly to the PowerShell tag commands.

## Step 36 — Delete the old local and remote tag

Paste:

```powershell
$Repo = `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"

Set-Location $Repo

$Tag = "module-2-g3-v2.0.0"

$LocalTag = git tag --list $Tag

if ($LocalTag) {
    git tag -d $Tag

    if ($LASTEXITCODE -ne 0) {
        throw "The old local tag could not be deleted."
    }
}

$RemoteTag = git ls-remote --tags origin "refs/tags/$Tag"

if ($RemoteTag) {
    git push origin ":refs/tags/$Tag"

    if ($LASTEXITCODE -ne 0) {
        throw "The old remote tag could not be deleted."
    }
}

Write-Host "OLD TAG REMOVAL COMPLETE" -ForegroundColor Green
```

GitHub documents pushing a single tag with `git push origin TAG` and deleting a remote reference by pushing an empty source to that reference. [export reference: cite | turn792726view1]

## Step 37 — Create the final annotated tag

Paste:

```powershell
$Tag = "module-2-g3-v2.0.0"

$FinalMain = (
    Get-Content `
        "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt" `
        -Raw
).Trim()

git tag -a $Tag -m "Module 2 / G3 v2.0.0"

if ($LASTEXITCODE -ne 0) {
    throw "The final local tag could not be created."
}

git push origin $Tag

if ($LASTEXITCODE -ne 0) {
    throw "The final tag could not be pushed."
}

$TagCommit = (git rev-list -n 1 $Tag).Trim()

"Final main: $FinalMain"
"Tag commit: $TagCommit"

if ($TagCommit -ne $FinalMain) {
    throw "The tag does not point to final main."
}

Write-Host ""
Write-Host "FINAL TAG PASS" -ForegroundColor Green
```

## Expected result

```text
Final main: [commit hash]
Tag commit: [same commit hash]

FINAL TAG PASS
```

The two hashes must be identical.

---

# Part 14 — Create the GitHub Release

## Step 38 — Recheck the Release ZIP immediately before upload

Paste:

```powershell
$ReleaseZip = `
    "C:\MSBF_RELEASE_FILES\MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip"

$ExpectedReleaseHash = `
    "8ee23c2418e7c00772d2246699ce9a72a09d4c9f396ae15fc40484129787ee36"

$ObservedReleaseHash = (
    Get-FileHash `
        -LiteralPath $ReleaseZip `
        -Algorithm SHA256
).Hash.ToLower()

"Expected: $ExpectedReleaseHash"
"Observed: $ObservedReleaseHash"

if ($ObservedReleaseHash -ne $ExpectedReleaseHash) {
    throw "Release ZIP SHA-256 mismatch."
}

Write-Host "RELEASE ASSET HASH PASS" -ForegroundColor Green
```

## Step 39 — Copy `RELEASE_NOTES.md` to your clipboard

Paste:

```powershell
$Repo = `
    "C:\msbf-v2\merchant-sales-based-financing-strategy-simulator"

Get-Content `
    "$Repo\RELEASE_NOTES.md" `
    -Raw |
    Set-Clipboard

Write-Host "Release notes copied to clipboard." `
    -ForegroundColor Green
```

## Step 40 — Open the Release form

In GitHub:

1. Open the repository.
2. Click **Releases**.
3. Click:

```text
Draft a new release
```

GitHub’s current documented Release flow is: open Releases, choose or create a tag, enter the title and description, attach binary files, optionally mark it latest, and either save the draft or publish it. [export reference: cite | turn792726view0]

## Step 41 — Select the tag

Click:

```text
Choose a tag
```

Enter:

```text
module-2-g3-v2.0.0
```

Select the **existing** tag.

Do not create a second tag.

## Step 42 — Enter the Release title

Enter:

```text
Module 2 / G3 v2.0.0
```

## Step 43 — Paste the Release notes

Click in the description box and press:

```text
Ctrl + V
```

## Step 44 — Set the Release options

Set:

```text
Set as latest release     CHECKED
This is a pre-release     UNCHECKED
```

Do not mark it as a prerelease.

## Step 45 — Attach these five files

Drag these files from `C:\MSBF_RELEASE_FILES` into the Release’s binary-assets box:

```text
MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip

MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip.sha256

MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.md

MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0_VALIDATION_REPORT.json

MSBF_Transparency_Campaign_Navigation_File_Inventory.csv
```

Wait until all uploads finish completely.

## Do not attach these files

```text
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip
MSBF_GitHub_Publication_Candidate_UPLOAD_READY_v2.0.0.zip.sha256
MSBF_GitHub_UPLOAD_RUNBOOK_v2.0.0.md
ChatGPT_Logs.zip
MSBF_Transparency_Campaign_and_Navigation_Overlay_v2.0.0.zip
```

The `UPLOAD_READY` ZIP contains the local `.git` directory and is only a staging worktree. It is not a public distribution asset.

## Step 46 — Save the draft first

Click:

```text
Save draft
```

Then reopen the draft and verify:

- correct tag;
- correct title;
- latest release selected;
- prerelease not selected;
- all five files attached;
- no upload still spinning;
- Release notes populated.

GitHub recommends drafting first when release immutability is relevant, so all assets are attached before publication. [export reference: cite | turn792726view0]

## Step 47 — Publish

Click:

```text
Publish release
```

---

# Part 15 — Validate the published tag with a clean clone

This proves that an outside user receives a complete, valid repository.

## Step 48 — Create a new verification clone

Return to PowerShell and paste:

```powershell
$VerifyRoot = "C:\msbf-release-verify"

if (Test-Path -LiteralPath $VerifyRoot) {
    throw "$VerifyRoot already exists. Rename it before continuing."
}

git clone `
    --branch module-2-g3-v2.0.0 `
    --depth 1 `
    https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git `
    $VerifyRoot

if ($LASTEXITCODE -ne 0) {
    throw "The clean release clone failed."
}

Set-Location $VerifyRoot
```

## Step 49 — Run the validator inside the clean clone

Paste:

```powershell
python tools\validate_public_release.py

if ($LASTEXITCODE -ne 0) {
    throw "Clean-clone validation failed."
}

$CloneHead = (git rev-parse HEAD).Trim()

$FinalMain = (
    Get-Content `
        "C:\MSBF_RELEASE_FILES\FINAL_MAIN_COMMIT.txt" `
        -Raw
).Trim()

"Published clone: $CloneHead"
"Final main:      $FinalMain"

if ($CloneHead -ne $FinalMain) {
    throw "Published tag does not match final main."
}

git status --short --branch

Write-Host ""
Write-Host "CLEAN-CLONE RELEASE VALIDATION PASS" `
    -ForegroundColor Green
```

## Expected result

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

The two commit hashes must match.

Because you cloned a tag rather than a branch, Git status may say:

```text
## HEAD (no branch)
```

That is normal for this verification clone.

The final line must say:

```text
CLEAN-CLONE RELEASE VALIDATION PASS
```

---

# Part 16 — Final browser review

Open the public repository and check each item.

## Repository landing page

Confirm:

- `README.md` renders.
- Module 1 / G2 is accepted.
- Module 2 / G3 is accepted.
- Campaign Scale Certification is current.
- The architecture image renders.
- The ten-page executive brief links work.

## Module 2

Open:

```text
Module_2
```

Confirm that M2.1 through M2.12 are all visible.

Open two or three stages and verify that links to:

```text
BRD
Architecture
Validation
Source provenance
Correction history
Catalogs
Current source
Recovery boundary
```

work.

## Documentation

Confirm these directories open:

```text
docs/campaign_scale
docs/project_history
docs/enterprise_architecture
docs/executive_strategy
```

## Actions

Open the **Actions** tab and confirm the latest:

```text
Publication Integrity
```

run is green.

## Releases

Open the Release and confirm:

```text
Title: Module 2 / G3 v2.0.0
Tag: module-2-g3-v2.0.0
Latest: Yes
Prerelease: No
```

Confirm the five assets appear.

---

# You are finished only when all of these are true

```text
UPLOAD_READY ZIP hash                       PASS
Governed Release ZIP hash                   PASS
Package baseline = origin/main              PASS
Pre-staging status                          20 modified / 15 untracked / 0 deleted
Local publication validator                 PASS
Manifest count                              1,930
Module 2 stage count                        12
Staged changes                              1,083 added / 20 modified / 0 deleted
Release branch pushed                       YES
Pull request created                        YES
Publication Integrity check                 GREEN
Pull request merged                         YES
Final main validator                        PASS
Old premature tag replaced                  YES
Tag commit = final main commit              YES
GitHub Release published                    YES
Governed Release ZIP attached               YES
Clean-clone validator                       PASS
```

The same commands are retained in the downloadable upload runbook (historical reference: `sandbox:[session]/MSBF_GitHub_UPLOAD_RUNBOOK_v2.0.0.md`; referenced bytes not established here).
<!-- END_SOURCE_MESSAGE -->


<a id="m-2543e061-fdf2-4223-9e02-056aab0bb17e"></a>
## Andrew / user · C072-M00511

C072-M00511 · 2026-08-14T22:07:22.631000-04:00 · active path

Preceding visible parent: [C072-M00510](part-35.md#m-79809c55-0d57-4882-bd07-6d07b33a81ca)

<!-- BEGIN_SOURCE_MESSAGE -->
when I tried to extract the downloaded MSBF_Github_Publication_Candidate_UPLOAD_READY_v2.0.0.zip and MSBF_Strategy_Simulator_Module_2_G3_v2.0.0.zip it said they were invalid.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1ef9c24b-659e-4ce3-a971-61782d2d14fb"></a>
## Assistant · C072-M00512

C072-M00512 · 2026-08-14T22:25:37.694876-04:00 · active path

Preceding visible parent: [C072-M00511](part-35.md#m-2543e061-fdf2-4223-9e02-056aab0bb17e)

<!-- BEGIN_SOURCE_MESSAGE -->
Stop using the two earlier downloaded ZIPs. I checked the source copies directly:

- both original archives pass full ZIP CRC testing;
- both match their published SHA-256 hashes;
- however, they contain paths up to **300 characters**, including **17 paths at or above 260 characters**;
- Windows File Explorer’s built-in “Extract All” handler can report that combination as an **invalid compressed folder**, even when the ZIP data itself is intact;
- an incomplete browser download can produce the same message.

I rebuilt both archives specifically for Windows compatibility. The new versions use Windows ZIP metadata, explicit directory records, a short internal root folder named `m`, and a maximum internal path of **252 characters**. I then extracted both from scratch and reran the repository validator successfully.

## Download these replacement files

### 1. Local Git worktree — this is the one you extract

Download MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip (historical reference: `sandbox:[session]/MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip.sha256`; referenced bytes not established here)

```text
File size:  110,176,194 bytes
SHA-256:    dab59ea66ffa65e3eae3b07928dbd0ddf7ce339c792f09e9b6e85143fc32125c
```

### 2. Governed GitHub Release asset — upload this later without extracting it

Download MSBF_M2G3_RELEASE_WINDOWS_R1.zip (historical reference: `sandbox:[session]/MSBF_M2G3_RELEASE_WINDOWS_R1.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M2G3_RELEASE_WINDOWS_R1.zip.sha256`; referenced bytes not established here)

```text
File size:  71,242,664 bytes
SHA-256:    da0bd1643d0851a1779e4ea476ae9e7b08528bd45d7b4548089734ace1acf209
```

### 3. Automated verification and extraction script

Download MSBF_WINDOWS_EXTRACT_AND_VERIFY_R1.ps1 (historical reference: `sandbox:[session]/MSBF_WINDOWS_EXTRACT_AND_VERIFY_R1.ps1`; referenced bytes not established here)

---

# Exact steps

## Step 1 — Delete or move the two earlier invalid downloads

Do not mix the old and new files.

The files you should now use have these exact names:

```text
MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip
MSBF_M2G3_UPLOAD_WORKTREE_WINDOWS_R1.zip.sha256

MSBF_M2G3_RELEASE_WINDOWS_R1.zip
MSBF_M2G3_RELEASE_WINDOWS_R1.zip.sha256

MSBF_WINDOWS_EXTRACT_AND_VERIFY_R1.ps1
```

## Step 2 — Put all five new files in one folder

Create:

```text
C:\MSBF_RELEASE_FILES
```

Move all five files there.

They must all be in the same folder because the PowerShell script looks beside itself for both ZIPs.

## Step 3 — Do not use Windows “Extract All”

The script uses Windows `tar.exe`, bypassing the File Explorer compressed-folder handler that produced the invalid-file message.

Open PowerShell and run:

```powershell
Set-Location "C:\MSBF_RELEASE_FILES"

powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File ".\MSBF_WINDOWS_EXTRACT_AND_VERIFY_R1.ps1"
```

## Step 4 — Let the script complete

The script will automatically:

1. verify both SHA-256 hashes;
2. verify that both ZIP structures are readable;
3. create the short extraction location:

```text
C:\x
```

4. extract the Git worktree to:

```text
C:\x\m
```

5. verify that `.git` exists;
6. verify that the Publication Integrity workflow exists;
7. run the repository’s release validator;
8. leave the release ZIP unextracted for later GitHub upload.

## Expected successful output

You should see these lines:

```text
SHA-256 verification PASS
ZIP structure verification PASS
Worktree extraction PASS
Repository path: C:\x\m

Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12

Repository validator PASS

READY
Use this worktree for the Git steps: C:\x\m
Do not extract the release ZIP. Upload it later to GitHub Releases as-is.
```

## Important distinction

After the script succeeds:

```text
C:\x\m
```

is the repository you will use for Git commands.

This file:

```text
MSBF_M2G3_RELEASE_WINDOWS_R1.zip
```

should remain in:

```text
C:\MSBF_RELEASE_FILES
```

You do **not** extract that second ZIP as part of publication. It will later be dragged directly into the GitHub Release assets section.

## If the script reports a SHA-256 mismatch

That specifically means the download did not complete correctly. Do not attempt extraction. The script will show the observed hash, which will distinguish a truncated download from a Windows extraction issue.

Both replacement archives passed:

```text
ZIP CRC                              PASS
File-by-file content comparison      PASS
Windows-style ZIP metadata           PASS
Explicit directory records           PASS
Maximum internal path                252 characters
Worktree .git directory              PASS
Publication workflow                 PASS
Public release validator             PASS
Governed manifest files              1,930
Module 2 stage folders               12
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-bbb210f9-d30b-446e-b650-18b063a754d9"></a>
## Andrew / user · C072-M00513

C072-M00513 · 2026-08-14T23:20:23.083161-04:00 · active path

Preceding visible parent: [C072-M00512](part-35.md#m-1ef9c24b-659e-4ce3-a971-61782d2d14fb)

<!-- BEGIN_SOURCE_MESSAGE -->
The Automated verification and extraction ran correctly. Now what do I do (step by explicit step)?
<!-- END_SOURCE_MESSAGE -->
