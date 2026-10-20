# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 5

Part 41 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-40.md)
[Next part](part-42.md)

<a id="m-03f2dc4f-0ecd-4f52-b9d8-56aa1cfcb0a3"></a>
## Assistant · C123-M00522

C123-M00522 · 2026-10-16T17:02:52.297657-04:00 · active path

Preceding visible parent: [C123-M00521](part-40.md#m-7ebbd0cc-60dc-4790-b21b-726d65a4b4b1)

<!-- BEGIN_SOURCE_MESSAGE -->
**I compared your folder with the earlier package and prepared the expanded update using your layout.** It now includes the Tableau landing README, the main project README changes, the relevant navigation/support updates, and the inventory changes needed to keep the repository’s validator passing.

**This is a documentation and portfolio update—not a new version or release.**

## Download the integrated update

### Download the Tableau GitHub documentation update — 9.32 MB ZIP (historical reference: `sandbox:[session]/MCI_Tableau_Documentation_Update.zip`; referenced bytes not established here)

The most useful files to review directly are:

**New Tableau README (historical reference: `sandbox:[session]/MCI_Tableau_Documentation_Update/repo_files/docs/tableau/README.md`; referenced bytes not established here)** · **Updated main project README (historical reference: `sandbox:[session]/MCI_Tableau_Documentation_Update/repo_files/README.md`; referenced bytes not established here)** · **Folder comparison (historical reference: `sandbox:[session]/MCI_Tableau_Documentation_Update/review/Folder_Comparison.md`; referenced bytes not established here)** · **Installation instructions (historical reference: `sandbox:[session]/MCI_Tableau_Documentation_Update/START_HERE.md`; referenced bytes not established here)**

## What I retained from your folder

Your arrangement is appropriate, especially because it keeps the workbook separate from its explanatory material:

```text
docs/
└── tableau/
    ├── README.md
    ├── release/
    │   └── MCI_Risk_Decision_Scenario_Review.twb
    ├── docs/
    │   ├── MCI_Risk_Decision_Scenario_Review_Carousel.pdf
    │   ├── MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/
    │   │   └── 01_... through 13_...
    │   └── WORKBOOK_AND_EVIDENCE_NOTES.md
    └── manifests/
        └── ASSET_MANIFEST.json
```

I did **not** introduce the competing `docs/tableau/images/` arrangement from my earlier package or duplicate the PDF at the Tableau folder root.

| Comparison | Result |
|---|---|
| Your carousel PDF versus the earlier package | **Identical bytes.** Preserved unchanged. |
| Your thirteen PNGs versus the earlier package | **Identical image bytes.** Twelve filenames corrected to match the actual PDF-page subjects. |
| Your `.twb` workbook | Additional material not in the earlier package. **Preserved unchanged.** |
| Your 24 root support files | **All match** the complete repository snapshot available here. |
| Additional documentation pages | Retrieved from that matching snapshot and checked against the hashes in your supplied manifest. |

The `release/` folder name stays because it is your organizational convention. The documentation explicitly distinguishes that directory from creating a **GitHub Release**.

## What the README and support changes cover

The Tableau README follows the useful structure of your Power BI example: product, overview, analytical scope, artifact identity, folder map, validation position, and interpretation boundaries. It does **not** inherit Power BI’s release-candidate labels, acceptance decisions, or validation-control counts. Those belong to the Power BI package. [export reference: filecite | turn112file0 | L41-L58]

The new page explains the dashboard’s five sections, two segment-analysis modes, source-backed narrative selector, comparison population, and distinction between portfolio filters and investigation selections. It also links all thirteen carousel pages in the correct order.

**The main README receives a prominent Tableau navigation link, one overview image, and a focused Tableau section.** It does not become a thirteen-image gallery.

The supporting updates are:

| Files | Change |
|---|---|
| `docs/README.md` | Add Tableau to the documentation portal and analytical library. |
| `docs/guide/ANALYTICS.md` | Explain how Tableau complements Power BI and cohort analysis. |
| `docs/guide/CURRENT_USE.md` | Add the Tableau viewing path and workbook prerequisites. |
| `PROJECT_ARTIFACT_MAP.md` | Register the workbook, carousel, images, and supporting notes. |
| `MODULE_AND_RELEASE_INDEX.md` | Identify Tableau as a companion—not a new module or release. |
| Reproducibility, governance, evidence-policy, and publication guides | Add narrowly scoped Tableau documentation notes while preserving the existing content. |
| Four root manifests/inventories | Record the intended additions and changed documentation hashes. |

**Unchanged:** simulator source, accepted Power BI artifacts, historical audit evidence, `release_metadata.json`, `RELEASE_NOTES.md`, `CHANGELOG.md`, citation version fields, historical overlay indexes, and tag identities.

## One important workbook distinction

Your uploaded `.twb` references a local CSV and an enabled temporary Hyper extract. **Neither data file is in `tableau.zip`.** The workbook therefore supplies the authored definitions and calculations, but it is not a self-contained download that another person can necessarily open immediately.

I documented that rather than changing the workbook or claiming portability. Tableau’s packaged `.twbx` format is the format designed to include the workbook and its supporting local data. [export reference: cite | turn265566search0]

This does not prevent publishing the README, carousel, or source definition. It means the download needs to be labeled accurately. The **live Tableau dashboard should be the primary interactive destination** once its exact Share URL is added.

## Verification completed

The unchanged repository validator passed on the complete matching tree **before and after** the update:

| Check | Result |
|---|---|
| Original governed payload files | **2,880** |
| Updated governed payload files | **2,898** |
| Existing documentation files changed | **10** |
| New Tableau companion files | **18** |
| Root inventory/checksum files updated | **4** |
| Other pre-existing payload files | **2,870 checked and unchanged** |
| Relative links checked in updated Markdown | **310 resolved** |
| PDF, workbook, and thirteen PNG contents | **Unchanged** |
| Installer repeat test | **Zero writes on repeat** |
| Unexpected protected-file change | **Refused before writing** |

The installer and local publication-preview logic were tested here. **Native Windows PowerShell execution, a Tableau opening test, and a live GitHub push were not performed.** The verification record (historical reference: `sandbox:[session]/MCI_Tableau_Documentation_Update/review/Verification_Results.json`; referenced bytes not established here) distinguishes those limits.

## Run the update in PowerShell

**Use this package instead of installing the earlier preparation package alongside it.** Save the ZIP in Downloads, then extract it outside your repository:

```powershell
$ErrorActionPreference = 'Stop'

$Zip = Join-Path $env:USERPROFILE 'Downloads\MCI_Tableau_Documentation_Update.zip'
$Folder = 'D:\MCI_Tableau_Documentation_Update'

if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) {
    throw "ZIP not found: $Zip"
}

if (Test-Path -LiteralPath $Folder) {
    throw "Folder already exists: $Folder. Do not overwrite an earlier run."
}

Expand-Archive -LiteralPath $Zip -DestinationPath $Folder
```

Run the **preview** first:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\MCI_Tableau_Documentation_Update\Apply-TableauDocumentation.ps1' `
  -RepoPath 'D:\x\m'
```

Then apply the checked changes:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\MCI_Tableau_Documentation_Update\Apply-TableauDocumentation.ps1' `
  -RepoPath 'D:\x\m' -Apply
```

The installer checks your actual checkout, preserves backups outside the repository, corrects the image filenames, installs the documentation, and runs the existing validator. **It does not stage, commit, or push.** A separate, explicitly invoked publication script is included for the subsequent documentation commit; it does not create or move tags or create a release.

**Send the Apply output and your exact Tableau Public Share URL next.** The package already supports inserting that URL into both READMEs without guessing the destination or leaving a broken placeholder link.
<!-- END_SOURCE_MESSAGE -->


<a id="m-626bfab5-c0cf-4bdd-a685-829e32fc2386"></a>
## Andrew / user · C123-M00523

C123-M00523 · 2026-10-16T17:16:25.821000-04:00 · active path

Preceding visible parent: [C123-M00522](part-41.md#m-03f2dc4f-0ecd-4f52-b9d8-56aa1cfcb0a3)

<!-- BEGIN_SOURCE_MESSAGE -->
so you are saying those powershell commands will extract and update my D:/x/m folder appropriately?
<!-- END_SOURCE_MESSAGE -->


<a id="m-7d48bafd-8415-4327-91e7-735d3e90efda"></a>
## Assistant · C123-M00524

C123-M00524 · 2026-10-16T17:16:38.751450-04:00 · active path

Preceding visible parent: [C123-M00523](part-41.md#m-626bfab5-c0cf-4bdd-a685-829e32fc2386)

<!-- BEGIN_SOURCE_MESSAGE -->
**Yes. That is exactly what the two PowerShell command blocks are designed to do.** They will extract the prepared package and then update your existing repository at `D:\x\m`.

There is one important distinction: **the first block extracts the package; the second block previews the changes; the third command actually applies them.**

| Step | Action | Changes `D:\x\m`? |
|---|---|---|
| 1. Extract ZIP | Extracts the package to `D:\MCI_Tableau_Documentation_Update` | No |
| 2. Preview | Checks your existing repository against the prepared update | No |
| 3. Apply | Installs the Tableau documentation and updates the relevant project files | **Yes** |
| 4. Git publication | Stages, commits, and pushes the approved changes | Not yet |

### What the Apply command is intended to update

- Your existing `docs/tableau/` folder, retaining your preferred structure.
- `docs/tableau/README.md`, modeled on your Power BI documentation.
- The root `README.md`, adding the Tableau showcase.
- Relevant documentation indexes, navigation, and supporting guides.
- Required manifest and checksum entries.
- The carousel PDF and 13 correctly named PNGs.

**It will not intentionally change the simulator's source code, accepted validation evidence, historical releases, or Git tags.**

### One important safeguard

The package was tested against the repository snapshot available to me, **not against your live Windows checkout**. The installer is designed to check for differences and refuse unexpected changes, but I cannot guarantee its behavior on your machine until we see its output.

I recommend running the extraction and **preview commands first**, then reviewing the reported changes before running `-Apply`.

After a successful Apply, the files will be updated **locally only**. Nothing will appear on GitHub until we explicitly stage, commit, and push the documentation update.

**Bottom line:** Yes, these commands are designed to update `D:\x\m` appropriately, without creating a new project version or GitHub Release. I recommend completing the preview checkpoint before allowing the actual write.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7cf63a3e-c9f9-428e-976a-07e7bd0bf204"></a>
## Andrew / user · C123-M00525

C123-M00525 · 2026-10-16T17:21:05.503000-04:00 · active path

Preceding visible parent: [C123-M00524](part-41.md#m-7d48bafd-8415-4327-91e7-735d3e90efda)

<!-- BEGIN_SOURCE_MESSAGE -->
STOP: Preflight stopped before writing:
Unexpected physical file (not included or overwritten): main_github_folder_support_files.zip
The bounded documentation update stopped. Read the STOP message above.
At D:\MCI_Tableau_Documentation_Update\Apply-TableauDocumentation.ps1:31 char:28
+ ... DE -ne 0) { throw 'The bounded documentation update stopped. Read the ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (The bounded doc... message above.:String) [], RuntimeException
    + FullyQualifiedErrorId : The bounded documentation update stopped. Read the STOP message above.
<!-- END_SOURCE_MESSAGE -->


<a id="m-39701cfd-f815-4800-bbb1-4a2c79d136b9"></a>
## Assistant · C123-M00526

C123-M00526 · 2026-10-16T17:21:19.805016-04:00 · active path

Preceding visible parent: [C123-M00525](part-41.md#m-7cf63a3e-c9f9-428e-976a-07e7bd0bf204)

<!-- BEGIN_SOURCE_MESSAGE -->
**The preflight safeguard worked as intended. No repository files were changed.**

The installer encountered an unexpected file in your repository:

`D:\x\m\main_github_folder_support_files.zip`

That file was not included in the repository snapshot used to prepare the update, so the installer stopped rather than risking an unintended modification.

**This does not necessarily indicate a problem with your repository.** It may simply be a local support archive that should be preserved and excluded from the installer's inventory comparison.

I recommend a narrowly scoped correction—not deleting the ZIP, moving your repository, or disabling the preflight checks.

## Next step: verify the unexpected file

Run this in PowerShell:

```powershell
cd D:\x\m

Get-Item .\main_github_folder_support_files.zip |
    Select-Object Name, Length, LastWriteTime

git status --short -- main_github_folder_support_files.zip

git ls-files --error-unmatch main_github_folder_support_files.zip
```

The final command may report that the file is not tracked by Git. That is useful information, not a failure.

**Please paste the output.** I can then give you a targeted adjustment to the installer that preserves this ZIP, maintains the existing checksum protections, and allows the Tableau documentation update to proceed.

I also inspected the installer's preflight logic: it checks every physical file against its approved inventory. Simply adding this ZIP to `.gitignore` would **not** resolve the error, because the check includes ignored files.

We should authorize this one file as a preserved local exception rather than weaken the protection for the entire repository.
<!-- END_SOURCE_MESSAGE -->


<a id="m-be903876-ee4a-4df4-add2-60134f58af90"></a>
## Andrew / user · C123-M00527

C123-M00527 · 2026-10-16T17:23:27.640000-04:00 · active path

Preceding visible parent: [C123-M00526](part-41.md#m-39701cfd-f815-4800-bbb1-4a2c79d136b9)

<!-- BEGIN_SOURCE_MESSAGE -->
?? main_github_folder_support_files.zip
error: pathspec 'main_github_folder_support_files.zip' did not match any file(s) known to git
Did you forget to 'git add'?
Name                                 Length LastWriteTime
----                                 ------ -------------
main_github_folder_support_files.zip 684638 10/16/2026 4:30:05 PM
<!-- END_SOURCE_MESSAGE -->


<a id="m-1dba073d-f0e8-4f4d-8185-b44baf9e9a69"></a>
## Assistant · C123-M00528

C123-M00528 · 2026-10-16T17:23:38.099089-04:00 · active path

Preceding visible parent: [C123-M00527](part-41.md#m-be903876-ee4a-4df4-add2-60134f58af90)

<!-- BEGIN_SOURCE_MESSAGE -->
**Confirmed. `main_github_folder_support_files.zip` is an untracked local archive, not a Git-managed project file.**

Your output establishes:

- The file exists in `D:\x\m`.
- Its size is 684,638 bytes.
- Git reports `??`, meaning it is untracked.
- `git ls-files` confirms it is not part of Git's tracked inventory.

This explains the preflight failure. The installer encountered a local file that was absent from its expected repository snapshot.

**We should preserve the archive and move it outside the repository before retrying.** That avoids modifying the installer or weakening its integrity checks.

## 1. Move the archive to a safe location

Run this PowerShell block:

```powershell
$Source = 'D:\x\m\main_github_folder_support_files.zip'
$BackupFolder = 'D:\MCI_Tableau_Documentation_Update\Local_Backups'
$Destination = Join-Path $BackupFolder 'main_github_folder_support_files.zip'

New-Item -ItemType Directory -Path $BackupFolder -Force | Out-Null

if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) {
    throw "Source archive not found."
}

if (Test-Path -LiteralPath $Destination) {
    throw "Backup already exists. Refusing to overwrite."
}

$OriginalHash = (Get-FileHash -LiteralPath $Source -Algorithm SHA256).Hash

Copy-Item -LiteralPath $Source -Destination $Destination

$BackupHash = (Get-FileHash -LiteralPath $Destination -Algorithm SHA256).Hash

if ($OriginalHash -ne $BackupHash) {
    throw "Backup verification failed. Original file has not been removed."
}

Remove-Item -LiteralPath $Source

Write-Host "Archive safely relocated and SHA-256 verified."
```

This copies the archive, verifies that the backup is byte-identical, and only then removes the original from the repository directory.

## 2. Retry the preview

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\MCI_Tableau_Documentation_Update\Apply-TableauDocumentation.ps1' `
  -RepoPath 'D:\x\m'
```

If the preview passes, we can proceed with the actual installation:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\MCI_Tableau_Documentation_Update\Apply-TableauDocumentation.ps1' `
  -RepoPath 'D:\x\m' -Apply
```

**Do not run `-Apply` if the preview reports another unexpected file or mismatch.** There may be other local-only artifacts that need the same treatment.

The objective remains unchanged: install the Tableau documentation, update the relevant project READMEs and support inventories, preserve accepted technical artifacts, and make a normal Git commit without creating a new release.

Once the preview passes, share its output so we can confirm the exact change set before applying it.
<!-- END_SOURCE_MESSAGE -->


<a id="m-de62e79b-7922-4b87-841f-4968e51c0082"></a>
## Andrew / user · C123-M00529

C123-M00529 · 2026-10-16T17:24:40.145000-04:00 · active path

Preceding visible parent: [C123-M00528](part-41.md#m-1dba073d-f0e8-4f4d-8185-b44baf9e9a69)

<!-- BEGIN_SOURCE_MESSAGE -->
PS D:\x\m> powershell.exe -NoProfile -ExecutionPolicy Bypass `
>>   -File 'D:\MCI_Tableau_Documentation_Update\Apply-TableauDocumentation.ps1' `
>>   -RepoPath 'D:\x\m'
Repository: D:\x\m
Branch: main
HEAD: fd9f67b6d1d7fc848d315bcb696487b82c9a8046
Original governed files: 2880
Files to write: 32 | obsolete PNG names to remove after byte-preserving rename: 0
No release, version, tags, simulator execution, staging, commit or push is performed by this installer.
NOTICE: no verified Share URL supplied; no live-dashboard button will be invented.
NOTICE: original .twb is preserved with local connection metadata; no embedded data or native opening test is claimed.
UPDATE GITHUB_PUBLICATION_GUIDE.md
UPDATE GOVERNANCE_AND_VALIDATION.md
UPDATE MODULE_AND_RELEASE_INDEX.md
UPDATE PROJECT_ARTIFACT_MAP.md
UPDATE README.md
UPDATE REPRODUCIBILITY_AND_EXECUTION.md
UPDATE SAMPLE_DATA_AND_EVIDENCE_POLICY.md
UPDATE docs/README.md
UPDATE docs/guide/ANALYTICS.md
UPDATE docs/guide/CURRENT_USE.md
ADD    docs/tableau/README.md
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel.pdf
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/01_portfolio_overview.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/02_bank_relationship_portfolio.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/03_energy_services_portfolio.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/04_acquisition_source_comparison.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/05_merchant003_evidence_sufficiency.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/06_merchant040_underwriting_review.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/07_merchant098_authorized_counteroffer.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/08_merchant258_proposed_exposure_sensitivity.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/09_merchant288_structure_feasibility.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/10_merchant340_governed_structure_constraint.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/11_merchant134_underwriting_judgment.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/12_policy_hard_stop_governance.png
ADD    docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/13_merchant016_authorization_stability.png
ADD    docs/tableau/docs/WORKBOOK_AND_EVIDENCE_NOTES.md
ADD    docs/tableau/manifests/ASSET_MANIFEST.json
ADD    docs/tableau/release/MCI_Risk_Decision_Scenario_Review.twb
UPDATE MANIFEST.csv
UPDATE manifest.json
UPDATE SHA256SUMS.txt
UPDATE PACKAGE_INVENTORY.csv

PREVIEW ONLY. Run with -Apply / --apply to install these files.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8a36c6ec-bcd2-44cf-b6c0-cc008a3bcc21"></a>
## Assistant · C123-M00530

C123-M00530 · 2026-10-16T17:24:56.680559-04:00 · active path

Preceding visible parent: [C123-M00529](part-41.md#m-de62e79b-7922-4b87-841f-4968e51c0082)

<!-- BEGIN_SOURCE_MESSAGE -->
**Excellent. The preflight passed, and the proposed update matches our intended scope. I approve proceeding with `-Apply`.**

### Review of the preview

| Check | Result |
|---|---|
| Repository | `D:\x\m` — correct |
| Branch | `main` — correct |
| Original governed files | 2,880 |
| Files to write | 32 |
| Existing documentation updates | 10 |
| New Tableau companion files | 18 |
| Manifest/inventory updates | 4 |
| Obsolete PNGs to remove | 0 |
| New version or release | None |
| Git staging, commit, or push | None |

The preview correctly identifies your preferred `docs/tableau/` structure, all 13 carousel PNGs, the Tableau workbook, and the main README/supporting documentation updates.

Two notices are expected and acceptable:

- **Tableau Public URL:** No verified Share URL has been supplied, so the installer will not invent a link.
- **Workbook portability:** The `.twb` retains its local connection information. We will address public access separately rather than claim it is a self-contained workbook.

### 1. Apply the update

Run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass `
  -File 'D:\MCI_Tableau_Documentation_Update\Apply-TableauDocumentation.ps1' `
  -RepoPath 'D:\x\m' -Apply
```

The installer is designed to back up affected files, apply the bounded changes, and run the repository's validation checks.

### 2. Verify the resulting Git changes

After `-Apply` completes successfully, run:

```powershell
cd D:\x\m

git status --short
git diff --check
git diff --stat
```

These commands will show the working-tree changes, check for whitespace errors, and summarize modifications to tracked files. Newly added files will appear in `git status` but not necessarily in the unstaged diff statistics.

**Do not run `git add`, `git commit`, or `git push` yet.** I want to verify the installer's actual completion and validation output before we publish.

### 3. What we'll do next

Once installation passes, we'll review the final change set, stage only the intended Tableau and documentation paths, create a normal documentation commit on `main`, and push to the existing GitHub repository.

We will **not** create a GitHub Release, change the project version, modify historical tags, or supersede accepted technical evidence.

**Next:** Run `-Apply` and paste the complete output. We're at the final local installation checkpoint.
<!-- END_SOURCE_MESSAGE -->


<a id="m-80c6726d-0d8d-4ba8-abab-52889ac9f81e"></a>
## Andrew / user · C123-M00531

C123-M00531 · 2026-10-16T17:26:47.332000-04:00 · active path

Preceding visible parent: [C123-M00530](part-41.md#m-8a36c6ec-bcd2-44cf-b6c0-cc008a3bcc21)

**Editorial record note:** Attachment references: Pasted text(20261016-212638).txt

<!-- BEGIN_SOURCE_MESSAGE -->
what do I press now - look ok?
<!-- END_SOURCE_MESSAGE -->


<a id="m-e0389119-84f7-457a-8525-99d2f9412218"></a>
## Assistant · C123-M00532

C123-M00532 · 2026-10-16T17:26:55.788581-04:00 · active path

Preceding visible parent: [C123-M00531](part-41.md#m-80c6726d-0d8d-4ba8-abab-52889ac9f81e)

<!-- BEGIN_SOURCE_MESSAGE -->
**The Tableau update installed successfully, and the repository validator passed. You're very close—but don't press anything to publish yet.**

Your output confirms:

- **APPLIED** — all 32 intended file updates were installed.
- **Validation PASS** — 2,898 governed files verified.
- **Git status** — only the expected documentation, inventory, and Tableau additions appear.
- **No commit or push has occurred.**

The `(END)` at the bottom means you're viewing Git output through its pager.

**Press `q`** to exit the pager and return to:

```powershell
PS D:\x\m>
```

### One issue to resolve before committing

`git diff --check` reported trailing-whitespace warnings in `MANIFEST.csv` and `PACKAGE_INVENTORY.csv`.

The displayed `^M` indicates carriage-return characters associated with Windows-style line endings. These may be **line-ending warnings rather than actual malformed CSV records**.

Because your repository uses SHA-256 manifests, **do not run an automatic whitespace cleanup, line-ending conversion, or `git add --renormalize`**. That could alter recorded file identities.

The existing repository validator passed, so the correct next step is to check whether Git is simply interpreting the CSV line endings differently.

After pressing `q`, run:

```powershell
git -c core.whitespace=cr-at-eol diff --check
```

If that returns directly to the prompt with **no warnings**, the issue is confirmed as Git's treatment of CRLF line endings rather than substantive trailing whitespace.

**Send me that result.** If it passes, we can proceed with the bounded Git staging, commit, and push—without creating a new version, tag, or GitHub Release.
<!-- END_SOURCE_MESSAGE -->


<a id="m-116e50ae-0bfb-4163-b05b-caf93f345c34"></a>
## Andrew / user · C123-M00533

C123-M00533 · 2026-10-16T17:27:56.361000-04:00 · active path

Preceding visible parent: [C123-M00532](part-41.md#m-e0389119-84f7-457a-8525-99d2f9412218)

<!-- BEGIN_SOURCE_MESSAGE -->
GITHUB_PUBLICATION_GUIDE.md        |  14 ++++
 GOVERNANCE_AND_VALIDATION.md       |   8 ++
 MANIFEST.csv                       |  42 +++++++---
 MODULE_AND_RELEASE_INDEX.md        |   8 ++
 PACKAGE_INVENTORY.csv              |  42 +++++++---
 PROJECT_ARTIFACT_MAP.md            |  16 ++++
 README.md                          |  16 +++-
 REPRODUCIBILITY_AND_EXECUTION.md   |   8 ++
 SAMPLE_DATA_AND_EVIDENCE_POLICY.md |  10 +++
 SHA256SUMS.txt                     |  42 +++++++---
 docs/README.md                     |   4 +-
 docs/guide/ANALYTICS.md            |  10 +++
 docs/guide/CURRENT_USE.md          |   9 +++
 manifest.json                      | 152 +++++++++++++++++++++++++++++--------
 14 files changed, 312 insertions(+), 69 deletions(-)                 PS D:\x\m> git -c core.whitespace=cr-at-eol diff --check
PS D:\x\m>
<!-- END_SOURCE_MESSAGE -->


<a id="m-aa8a5b15-0e36-4595-acae-8535bdc61271"></a>
## Assistant · C123-M00534

C123-M00534 · 2026-10-16T17:28:04.668478-04:00 · active path

Preceding visible parent: [C123-M00533](part-41.md#m-116e50ae-0bfb-4163-b05b-caf93f345c34)

<!-- BEGIN_SOURCE_MESSAGE -->
**PASS. We're ready for Git staging and publication.**

The whitespace check returned cleanly, confirming that the earlier warnings were attributable to Windows CRLF line endings.

Your update remains within the authorized scope: Tableau documentation, supporting files, carousel assets, and repository inventories. **No new version, tag, or GitHub Release.**

### Step 1 — Stage the intended files

Run this in PowerShell from `D:\x\m`:

```powershell
git add -- `
  GITHUB_PUBLICATION_GUIDE.md `
  GOVERNANCE_AND_VALIDATION.md `
  MANIFEST.csv `
  MODULE_AND_RELEASE_INDEX.md `
  PACKAGE_INVENTORY.csv `
  PROJECT_ARTIFACT_MAP.md `
  README.md `
  REPRODUCIBILITY_AND_EXECUTION.md `
  SAMPLE_DATA_AND_EVIDENCE_POLICY.md `
  SHA256SUMS.txt `
  docs/README.md `
  docs/guide/ANALYTICS.md `
  docs/guide/CURRENT_USE.md `
  manifest.json `
  docs/tableau/
```

This stages only the intended files, including the 18 new Tableau artifacts.

### Step 2 — Verify the staged changes

```powershell
git diff --cached --check
git diff --cached --stat
git status --short
```

Because of the CSV line endings, if the first command reports only the same `^M` warnings, repeat the check using:

```powershell
git -c core.whitespace=cr-at-eol diff --cached --check
```

**Do not run automatic line-ending normalization.**

The staged summary should contain the 14 modified tracked files and 18 new Tableau files. Confirm that no simulator source files, historical release artifacts, or unexpected paths appear.

### Step 3 — Commit

Once the staged checks pass:

```powershell
git commit -m "docs: add Tableau merchant credit risk dashboard showcase"
```

This creates an ordinary documentation commit on `main`.

### Step 4 — Push to GitHub

```powershell
git push origin main
```

This updates your existing repository:

[merchant-sales-based-financing-strategy-simulator](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator)

It does **not** create a GitHub Release or move any tags.

### Step 5 — Verify publication

After the push, open:

[Tableau documentation](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/tree/main/docs/tableau)

Confirm that the README renders, the carousel PDF opens, and the main project README links correctly to the Tableau section.

**My recommendation:** Complete Steps 1–2 first. If the staged inventory matches the expected 32 files, proceed with the commit and push. Then we can finalize the Bank of America follow-up using the published GitHub artifact.
<!-- END_SOURCE_MESSAGE -->


<a id="m-875f68df-9e69-4a60-8cfd-805a847b9acc"></a>
## Andrew / user · C123-M00535

C123-M00535 · 2026-10-16T17:28:36.754000-04:00 · active path

Preceding visible parent: [C123-M00534](part-41.md#m-aa8a5b15-0e36-4595-acae-8535bdc61271)

<!-- BEGIN_SOURCE_MESSAGE -->
one question before staging - in the updated project readme do we show any of the tableau images? how did you incorporate the tableau work into the readme?
<!-- END_SOURCE_MESSAGE -->


<a id="m-d9b1bc6e-6112-4342-93b5-e6e71eb634a4"></a>
## Assistant · C123-M00536

C123-M00536 · 2026-10-16T17:29:00.147736-04:00 · active path

Preceding visible parent: [C123-M00535](part-41.md#m-875f68df-9e69-4a60-8cfd-805a847b9acc)

<!-- BEGIN_SOURCE_MESSAGE -->
**Yes. The updated main project README includes a prominent Tableau screenshot, a dedicated Tableau section, and links to the supporting materials.** I checked the actual prepared `README.md`, rather than relying on the installation summary.

### Here's exactly what was added

The existing README's executive introduction and Power BI presentation remain intact. Immediately after the Power BI/cohort discussion, I added:

**Investigate matched scenarios in Tableau**

The section contains:

<box border radius="lg" padding={3} gap={2}>
  <AsyncImage query="Tableau Merchant Credit Intelligence risk decision scenario review dashboard matrix KPI charts" aspectRatio="5:4" maxHeight={220}/>
  <text weight="medium">Merchant Credit Intelligence · Risk Decision & Scenario Review</text>
  <text size="sm">Compare 750 matched applications, investigate 236 differing decision categories, and explore segment concentration and merchant-level evidence.</text>
  <text size="xs" color="secondary">Identify → Investigate → Explain</text>
</box>

<caption>The image above is illustrative; the GitHub README uses your actual Tableau screenshot, not a generated substitute.</caption>

Specifically, the Markdown embeds your actual image:

```markdown
[![Tableau risk decision and scenario review:
portfolio indicators, matched decision matrix,
segment sensitivity and source-backed narrative interpretation.]
(docs/tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel_PNGs/01_portfolio_overview.png)]
(docs/tableau/README.md)
```

That means **the screenshot itself is clickable** and takes the reader to the dedicated Tableau documentation page.

### What readers will see

The section provides:

- **One full Tableau overview image**, rather than flooding the main README with thirteen screenshots.
- **The key analytical results:** 750 matched applications, 236 different final decision categories (31.5%).
- **Your analytical workflow:** Identify → Investigate → Explain.
- **Tableau capabilities:** portfolio filtering, decision-pairing investigation, segment concentration, and dynamic Decision/Evidence/Structure/Source rationale.
- **Three links:** the Tableau companion README, the 13-page carousel, and workbook/evidence notes.

I also added an **Explore Tableau** link near the top of the main README, so visitors can reach the Tableau work without scrolling down to its dedicated section.

### My assessment

I think this is the right balance for the main repository README.

The root README is already an established MSBF project presentation. Showing all thirteen Tableau screenshots there would make it too long and compete with the Power BI and simulator material.

**One compelling Tableau screenshot in the root README, with a deeper dedicated Tableau page, is the stronger professional presentation.**

The dedicated page contains the full carousel navigation and individual examples for visitors who want to explore further.

### One outstanding item

The README contains a reserved marker for your Tableau Public Share URL:

```markdown
<!-- MCI_TABLEAU_LIVE_LINK -->
```

No live link was inserted because we haven't verified the exact URL. This is not a broken link; it's an invisible HTML comment.

Once you provide the Tableau Public URL, we can replace that marker with a direct link to the interactive dashboard and update the associated manifest hashes.

**My recommendation: keep the README arrangement as prepared.** It's prominent enough to advertise the Tableau work, while preserving the broader Merchant Credit Intelligence story. You can proceed with staging the approved documentation update.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d6c3d7ef-3da1-4baa-808c-95f092a5232f"></a>
## Andrew / user · C123-M00537

C123-M00537 · 2026-10-16T17:32:52.822000-04:00 · active path

Preceding visible parent: [C123-M00536](part-41.md#m-d9b1bc6e-6112-4342-93b5-e6e71eb634a4)

<!-- BEGIN_SOURCE_MESSAGE -->
Tableau Public URL: [https://public.tableau.com/app/profile/andrew.goad/viz/MCI_Risk_Decision_Scenario_Review/RiskDecisionScenarioReview](https://public.tableau.com/app/profile/andrew.goad/viz/MCI_Risk_Decision_Scenario_Review/RiskDecisionScenarioReview)  - please provide updated readme and I'll save it manually
<!-- END_SOURCE_MESSAGE -->


<a id="m-45de5a09-6583-4b6d-bcfd-c948999d78df"></a>
## Assistant · C123-M00538

C123-M00538 · 2026-10-16T17:33:46.590328-04:00 · active path

Preceding visible parent: [C123-M00537](part-41.md#m-d6c3d7ef-3da1-4baa-808c-95f092a5232f)

<!-- BEGIN_SOURCE_MESSAGE -->
I've updated the **complete main project README** with your verified Tableau Public URL, preserving the existing content, formatting, and links.

### Download Updated README.md (historical reference: `sandbox:[session]/README_Tableau_Public_Link_Updated.md`; referenced bytes not established here)

The only change is replacing the Tableau live-link placeholder with:

**[Open the interactive Tableau Public dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MCI_Risk_Decision_Scenario_Review/RiskDecisionScenarioReview)**

The Tableau section now presents the interactive dashboard link immediately above your portfolio screenshot, followed by the analytical explanation, 13-page carousel, and supporting documentation.

### Save it to your repository

Save the downloaded file as:

`D:\x\m\README.md`

Replace the existing README, but **do not stage or commit yet**.

**Important:** Your repository tracks file sizes and SHA-256 hashes in its publication inventories. Replacing `README.md` changes its hash, so the existing manifest entries must be updated before committing.

The Tableau companion README also contains a live-link placeholder. I recommend updating that in the same documentation commit so visitors can launch the interactive dashboard from either README.

**Next:** Once you've saved the updated root README, we should update the companion README and reconcile the four inventory files, then rerun validation before staging.
<!-- END_SOURCE_MESSAGE -->


<a id="m-980b1535-6d08-4af0-b2cf-38c82319a1f2"></a>
## Andrew / user · C123-M00539

C123-M00539 · 2026-10-16T17:35:39.296000-04:00 · active path

Preceding visible parent: [C123-M00538](part-41.md#m-45de5a09-6583-4b6d-bcfd-c948999d78df)

<!-- BEGIN_SOURCE_MESSAGE -->
readme replaced. should the readme in the tableau folder also be updated?
<!-- END_SOURCE_MESSAGE -->


<a id="m-1d7b7dcb-cb21-49ca-9d94-a330022b0145"></a>
## Assistant · C123-M00540

C123-M00540 · 2026-10-16T17:35:58.082613-04:00 · active path

Preceding visible parent: [C123-M00539](part-41.md#m-980b1535-6d08-4af0-b2cf-38c82319a1f2)

<!-- BEGIN_SOURCE_MESSAGE -->
**Yes. We should update `D:\x\m\docs\tableau\README.md` as well.** It is the dedicated Tableau landing page, so visitors should be able to launch the interactive dashboard directly from there—not just from the main project README.

I checked the prepared file. It already contains the carousel link, workbook definition, evidence notes, and overview screenshot. The only necessary change is replacing its `<!-- MCI_TABLEAU_LIVE_LINK -->` placeholder with your Tableau Public URL.

I recommend placing the live dashboard link prominently above the screenshot, while preserving the rest of the README unchanged.

### Download the updated Tableau README (historical reference: `sandbox:[session]/Tableau_README_Public_Link_Updated.md`; referenced bytes not established here)

Save it as:

`D:\x\m\docs\tableau\README.md`

Replace the existing file. All other content and relative links are preserved.

**Important before staging:** Both README files now differ from the hashes recorded by the installer. We need to update their entries in `MANIFEST.csv`, `manifest.json`, `SHA256SUMS.txt`, and `PACKAGE_INVENTORY.csv`, then rerun the repository validator.

Don't stage or commit yet. Once you've replaced the Tableau README, tell me and I'll give you the exact PowerShell commands to reconcile the manifests safely without modifying any other project artifacts.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a163e95a-5ac3-4a13-a761-d39baffc946b"></a>
## Andrew / user · C123-M00541

C123-M00541 · 2026-10-16T17:38:02.217000-04:00 · active path

Preceding visible parent: [C123-M00540](part-41.md#m-1d7b7dcb-cb21-49ca-9d94-a330022b0145)

<!-- BEGIN_SOURCE_MESSAGE -->
both files replaced. ready to verify github and move forward with publishing
<!-- END_SOURCE_MESSAGE -->


<a id="m-45bd8797-5bfd-4c64-b035-c877b11f561c"></a>
## Assistant · C123-M00542

C123-M00542 · 2026-10-16T17:38:39.468453-04:00 · active path

Preceding visible parent: [C123-M00541](part-41.md#m-a163e95a-5ac3-4a13-a761-d39baffc946b)

<!-- BEGIN_SOURCE_MESSAGE -->
**Both README updates are in place. We're ready for the final manifest reconciliation and GitHub publication checks.**

Because the two README files now contain your live Tableau Public link, their SHA-256 hashes have changed. We must update those two entries in the four repository inventories before committing.

The scope remains unchanged: **no new version, no GitHub Release, no tags, and no changes to simulator code or accepted analytical evidence.**

I also identified an important detail in the earlier publication script: it checks the original installation hashes. Since you subsequently updated both READMEs, **we should not use that script unchanged**. We'll reconcile the inventories and use a controlled Git commit instead.

## 1. Download the manifest reconciliation script

**Download Reconcile_Tableau_Readme_Manifests.py** (historical reference: `sandbox:[session]/Reconcile_Tableau_Readme_Manifests.py`; referenced bytes not established here)

I tested this script against the prepared repository inventories and both updated README files. It updates only the two README entries in each of the four inventories.

Save it to your Downloads folder.

## 2. Reconcile the inventories

Run in PowerShell:

```powershell
cd D:\x\m

py -3 "$env:USERPROFILE\Downloads\Reconcile_Tableau_Readme_Manifests.py" "D:\x\m"
```

The expected README identities are:

| File | Expected bytes |
|---|---:|
| `README.md` | 15,209 |
| `docs/tableau/README.md` | 8,396 |

If your output differs, stop and share it before continuing.

## 3. Run final repository validation

```powershell
cd D:\x\m

py -3 tools\validate_public_release.py

git -c core.whitespace=cr-at-eol diff --check

git status --short
```

We want the repository validator to report **PASS**, the whitespace check to return without errors, and Git status to show only the intended documentation/inventory changes and `docs/tableau/`.

## 4. Stage and verify

Once validation passes, run:

```powershell
git add -- `
  GITHUB_PUBLICATION_GUIDE.md `
  GOVERNANCE_AND_VALIDATION.md `
  MANIFEST.csv `
  MODULE_AND_RELEASE_INDEX.md `
  PACKAGE_INVENTORY.csv `
  PROJECT_ARTIFACT_MAP.md `
  README.md `
  REPRODUCIBILITY_AND_EXECUTION.md `
  SAMPLE_DATA_AND_EVIDENCE_POLICY.md `
  SHA256SUMS.txt `
  docs/README.md `
  docs/guide/ANALYTICS.md `
  docs/guide/CURRENT_USE.md `
  manifest.json `
  docs/tableau/

git -c core.whitespace=cr-at-eol diff --cached --check
git diff --cached --stat
```

The staged change set should contain **14 modified existing files and 18 new Tableau companion files**.

## 5. Commit and publish

After the staged checks pass, first confirm that your local branch is aligned with GitHub:

```powershell
git fetch --no-tags origin main

git rev-parse HEAD
git rev-parse origin/main
```

Those two commit hashes should match. If they do, publish:

```powershell
git commit -m "docs: add Tableau merchant credit risk dashboard showcase"

git push origin main
```

This is an ordinary documentation commit. It does not create a tag or GitHub Release.

## 6. Verify the published result

Open these destinations after pushing:

- [Main project README](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator)
- [Tableau companion README](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/tree/main/docs/tableau)
- [Interactive Tableau dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MCI_Risk_Decision_Scenario_Review/RiskDecisionScenarioReview)

Confirm that both GitHub READMEs link to the live Tableau dashboard, the overview screenshot renders, and the carousel PDF opens.

**Start with Steps 2–3 and send me the output.** Once the validator passes, the remaining work is the controlled Git commit and push.
<!-- END_SOURCE_MESSAGE -->


<a id="m-86d95127-e22e-4e86-aa16-072d9222899a"></a>
## Andrew / user · C123-M00543

C123-M00543 · 2026-10-16T17:40:52.706000-04:00 · active path

Preceding visible parent: [C123-M00542](part-41.md#m-45bd8797-5bfd-4c64-b035-c877b11f561c)

<!-- BEGIN_SOURCE_MESSAGE -->
Download Reconcile_Tableau_Readme_Manifests.py did not download
<!-- END_SOURCE_MESSAGE -->


<a id="m-2ea01770-125f-4b6a-b237-ee104de28e40"></a>
## Assistant · C123-M00544

C123-M00544 · 2026-10-16T17:41:29.161717-04:00 · active path

Preceding visible parent: [C123-M00543](part-41.md#m-86d95127-e22e-4e86-aa16-072d9222899a)

<!-- BEGIN_SOURCE_MESSAGE -->
I've repackaged the Python script into a ZIP file, which should be easier to download.

### Download Tableau Manifest Reconciliation — ZIP (historical reference: `sandbox:[session]/Tableau_Manifest_Reconciliation.zip`; referenced bytes not established here)

The ZIP has been verified and contains `Reconcile_Tableau_Readme_Manifests.py`.

### Step 1 — Extract the ZIP

Save it to Downloads, then right-click → **Extract All**.

### Step 2 — Run in PowerShell

Copy and paste:

```powershell
cd D:\x\m

py -3 "$env:USERPROFILE\Downloads\Tableau_Manifest_Reconciliation\Reconcile_Tableau_Readme_Manifests.py" "D:\x\m"
```

This assumes Windows extracted the ZIP into a folder named `Tableau_Manifest_Reconciliation` inside Downloads.

### Step 3 — Validate

After the script completes successfully, run:

```powershell
py -3 tools\validate_public_release.py

git -c core.whitespace=cr-at-eol diff --check

git status --short
```

**Do not stage or commit yet.** Share the output so we can verify that the two README changes and four inventory updates are consistent before publishing to GitHub.
<!-- END_SOURCE_MESSAGE -->


<a id="m-01a57832-3ea0-4d0b-a670-662ad834e2e2"></a>
## Andrew / user · C123-M00545

C123-M00545 · 2026-10-16T17:44:31.029000-04:00 · active path

Preceding visible parent: [C123-M00544](part-41.md#m-2ea01770-125f-4b6a-b237-ee104de28e40)

<!-- BEGIN_SOURCE_MESSAGE -->
>> py -3 "$env:USERPROFILE\Downloads\Tableau_Manifest_Reconciliation\Reconcile_Tableau_Readme_Manifests.py" "D:\x\m"
Updated inventory entries for:
  README.md: 15209 bytes; d78a3d1d2925ddf81d5fc405198e91a8e953614ab427c1b534814db6a5c978c8
  docs/tableau/README.md: 8396 bytes; e2847f8d63213ce10deb111aba73c5db7df0d41b7650395d571725533ccaead1
Updated: MANIFEST.csv, PACKAGE_INVENTORY.csv, SHA256SUMS.txt, manifest.json
PS D:\x\m> py -3 tools\validate_public_release.py
>>
>> git -c core.whitespace=cr-at-eol diff --check
>>
>> git status --short
Public release validation PASS
Governed manifest files: 2898
Module 2 stage folders: 12
 M GITHUB_PUBLICATION_GUIDE.md
 M GOVERNANCE_AND_VALIDATION.md
 M MANIFEST.csv
 M MODULE_AND_RELEASE_INDEX.md
 M PACKAGE_INVENTORY.csv
 M PROJECT_ARTIFACT_MAP.md
 M README.md
 M REPRODUCIBILITY_AND_EXECUTION.md
 M SAMPLE_DATA_AND_EVIDENCE_POLICY.md
 M SHA256SUMS.txt
 M docs/README.md
 M docs/guide/ANALYTICS.md
 M docs/guide/CURRENT_USE.md
 M manifest.json
?? docs/tableau/
PS D:\x\m>
<!-- END_SOURCE_MESSAGE -->


<a id="m-8e8b1c06-4b3a-49d8-a836-4b25f69fe0c9"></a>
## Assistant · C123-M00546

C123-M00546 · 2026-10-16T17:44:42.173385-04:00 · active path

Preceding visible parent: [C123-M00545](part-41.md#m-01a57832-3ea0-4d0b-a670-662ad834e2e2)

<!-- BEGIN_SOURCE_MESSAGE -->
<badge color="success"><icon name="check-circle" inline/> Validation passed</badge>

**Excellent. The Tableau documentation update is ready for Git staging.** Your results confirm that both README files and all four repository inventories have been reconciled successfully.

| Validation checkpoint | Result |
|---|---|
| Repository validator | **PASS** |
| Governed manifest files | 2,898 |
| Module 2 stage folders | 12 |
| Git whitespace check | **PASS** |
| Unexpected file changes | None reported |
| Git staging / publication | Not yet performed |

We can now proceed with the final controlled publication.

## Step 1 — Stage the 32 intended files

In PowerShell, run:

```powershell
cd D:\x\m

git add -- `
  GITHUB_PUBLICATION_GUIDE.md `
  GOVERNANCE_AND_VALIDATION.md `
  MANIFEST.csv `
  MODULE_AND_RELEASE_INDEX.md `
  PACKAGE_INVENTORY.csv `
  PROJECT_ARTIFACT_MAP.md `
  README.md `
  REPRODUCIBILITY_AND_EXECUTION.md `
  SAMPLE_DATA_AND_EVIDENCE_POLICY.md `
  SHA256SUMS.txt `
  docs/README.md `
  docs/guide/ANALYTICS.md `
  docs/guide/CURRENT_USE.md `
  manifest.json `
  docs/tableau/
```

Then verify:

```powershell
git -c core.whitespace=cr-at-eol diff --cached --check

git diff --cached --stat

git diff --cached --name-only
```

The staged files should consist of 14 modified existing files and 18 new Tableau files. No simulator source code or historical release files should appear.

## Step 2 — Confirm your branch is current

Run:

```powershell
git fetch --no-tags origin main

git rev-parse HEAD
git rev-parse origin/main
```

**The two commit hashes must match.** If they differ, stop and share the output before committing or pushing.

## Step 3 — Commit and push

If the staged files are correct and the two hashes match:

```powershell
git commit -m "docs: add Tableau merchant credit risk dashboard showcase"

git push origin main
```

This publishes the documentation update to your existing repository without creating a new version, tag, or GitHub Release.

## Step 4 — Verify GitHub

After the push succeeds, check:

[Main project repository](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator)

[Tableau documentation](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/tree/main/docs/tableau)

[Interactive Tableau dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MCI_Risk_Decision_Scenario_Review/RiskDecisionScenarioReview)

Verify that the Tableau screenshot displays in the main README, both READMEs link to Tableau Public, and the 13-page carousel PDF opens.

**My recommendation:** Run Steps 1 and 2 now. Once those checks pass, you're clear to commit and push. This will complete the Tableau publication while preserving the existing Merchant Credit Intelligence release history.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9fb65dfb-c7af-4e57-ba96-9eec3ec34a50"></a>
## Andrew / user · C123-M00547

C123-M00547 · 2026-10-16T17:47:35.904000-04:00 · active path

Preceding visible parent: [C123-M00546](part-41.md#m-8e8b1c06-4b3a-49d8-a836-4b25f69fe0c9)

<!-- BEGIN_SOURCE_MESSAGE -->
all four steps are done and I've verified everything in github and on tableau public
<!-- END_SOURCE_MESSAGE -->


<a id="m-a78068a1-30d7-465d-803c-69bc82be1c36"></a>
## Assistant · C123-M00548

C123-M00548 · 2026-10-16T17:47:41.962031-04:00 · active path

Preceding visible parent: [C123-M00547](part-41.md#m-9fb65dfb-c7af-4e57-ba96-9eec3ec34a50)

<!-- BEGIN_SOURCE_MESSAGE -->
**Excellent. The Tableau publication is complete.** Based on your confirmation, the GitHub commit and push succeeded, and you've verified the published artifacts.

You now have three connected portfolio assets:

- **[Interactive Tableau Dashboard](https://public.tableau.com/app/profile/andrew.goad/viz/MCI_Risk_Decision_Scenario_Review/RiskDecisionScenarioReview)** — Portfolio risk analysis, scenario comparisons, segment sensitivity, and merchant-level investigation.
- **[GitHub Tableau Case Study](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator/tree/main/docs/tableau)** — Supporting documentation, workbook definition, and visual evidence.
- **[Main Merchant Credit Intelligence Repository](https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator)** — The broader analytical system, now incorporating Tableau alongside the existing project capabilities.

The important accomplishment is that **Tableau adds a new analytical consumption layer to the Merchant Credit Intelligence system**, rather than simply reproducing Power BI.

For the Bank of America Global Risk Management audience, the strongest demonstration is the progression from portfolio-level indicators to decision-pairing analysis, segment concentration, and source-backed explanations of individual risk decisions.

**My recommendation is to freeze this published state.** No further dashboard development or documentation changes are necessary before sharing it professionally.

The next high-value step is your Bank of America interview follow-up: a concise message linking the live dashboard and GitHub case study, emphasizing the risk-management capabilities demonstrated rather than the technology alone.

You've completed the build, validation, documentation, and publication workflow. Now the priority is getting that work in front of the right people.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d3f26203-e25f-4822-870d-3192d76ccbb2"></a>
## Andrew / user · C123-M00549

C123-M00549 · 2026-10-16T17:48:40.257000-04:00 · active path

Preceding visible parent: [C123-M00548](part-41.md#m-a78068a1-30d7-465d-803c-69bc82be1c36)

**Editorial record note:** Attachment references: Pasted text(20261016-214819).txt

<!-- BEGIN_SOURCE_MESSAGE -->
we should now update the current github main repository readme:
<!-- END_SOURCE_MESSAGE -->


<a id="m-9335161b-dc3e-4947-9328-00500f63a4c4"></a>
## Assistant · C123-M00550

C123-M00550 · 2026-10-16T17:50:42.372638-04:00 · active path

Preceding visible parent: [C123-M00549](part-41.md#m-d3f26203-e25f-4822-870d-3192d76ccbb2)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll update the `andrew-goad/andrew-goad` profile README with a focused Tableau showcase and live-dashboard link, preserving the existing leadership, Power BI, career, and portfolio content.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e0536cc2-dd1c-44a6-bd50-f252a31da1be"></a>
## Assistant · C123-M00551

C123-M00551 · 2026-10-16T17:54:08.872725-04:00 · active path

Preceding visible parent: [C123-M00550](part-41.md#m-9335161b-dc3e-4947-9328-00500f63a4c4)

<!-- BEGIN_SOURCE_MESSAGE -->
This remains separate from the MSBF repository update just published.
<!-- END_SOURCE_MESSAGE -->
