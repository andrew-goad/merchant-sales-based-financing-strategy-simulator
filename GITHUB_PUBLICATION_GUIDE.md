# Owner-directed presentation update · 22 October 2026

Publish the final [Merchant Credit Intelligence narrated presentation](docs/presentation/README.md) as a bounded MSBF documentation/portfolio commit. The owner will manually commit and push using Git. Scope: `docs/presentation/`, the root README and current documentation navigation, this publication note, the artifact/release indexes, media attributes and the four current root file inventories.

Retain accepted source, Power BI and Tableau package bytes and all historical audit and release records. Keep `release_metadata.json`, `RELEASE_NOTES.md`, `CHANGELOG.md`, citation version fields and historical overlay indexes unchanged. This presentation update does not create or replace a release tag, publish a GitHub Release or grant technical supersession.

Before committing, run the unchanged `tools/validate_public_release.py`, verify the four root inventories, run `git diff --check`, inspect the bounded diff and stage only the supplied changed-path list. The prepared owner handoff includes an exact-baseline, hash-checked application helper and manual Git commands; it does not push automatically.

The earlier Tableau and release instructions below remain historical guidance.

---

# Owner-directed Tableau documentation update · no release

For the owner's 16 October 2026 request, add the [Tableau analytical companion](docs/tableau/README.md), its existing authored workbook/carousel/page images and related navigation. This instruction is limited to a documentation/portfolio commit and ordinary branch publication. It does not authorize a simulator version bump, new GitHub Release, tag creation/replacement, technical supersession, source-data changes or database execution.

Keep accepted Module 0/1/2, successor, Power BI and historical audit artifacts unchanged. Keep `release_metadata.json`, `RELEASE_NOTES.md`, `CHANGELOG.md`, citation version fields and historical overlay indexes unchanged. Update only the applicable documentation and current root file inventories; unchanged file records must retain their hashes.

The retained Tableau `.twb` is an explicitly disclosed authoring definition with local connection references, not a portable data package. Do not claim a native cross-machine opening test, bundled extract or verified live Share URL unless separately established. No credentials or private data may be added.

Before committing, verify the intended paths, run the unchanged repository validator, inspect `git diff --check` and the full diff, and stage only the documentation/companion paths. Publish only the intended branch commit. Do not use blanket staging, force push, tag commands or the historical release procedure below for this update.

The following candidate and predecessor instructions are preserved historical release guidance, not the procedure for this documentation-only change.

---

# Current publication overlay

This tree is a **final pre-audit candidate**, not a live release. Final Independent Audit must adjudicate the exact candidate/release assets and issue bounded supersession/publication authority before any commit/tag/push/release action. `PUB-RUN-001` Route B is Windows-qualified; Route D remains unqualified. After publication, download the actual hosted assets and verify filename, size, SHA-256 and Windows-native clean extraction before release closure.

---

## Preserved predecessor content

# GitHub Publication Guide — Module 2 / G3 v2.0.0

## Release candidate gate

Before publication:

1. integrate the final repository candidate into a clean local worktree;
2. inspect `git diff --stat` and the complete diff;
3. run `python tools/validate_public_release.py`;
4. verify `MANIFEST.csv`, `manifest.json`, and `SHA256SUMS.txt` against physical bytes;
5. confirm Markdown links and JSON/CSV parsing;
6. confirm the accepted source and recovery classifications;
7. confirm no raw development exports, credentials, local paths, or oversized release assets are committed;
8. commit the final candidate to `main`;
9. recreate the annotated release tag at the final commit;
10. publish large governed packages as GitHub Release assets rather than ordinary Git-tree files.

## Tag correction

If `module-2-g3-v2.0.0` was created before the final release commit, replace it only after the final commit is on `main`:

```bash
git tag -d module-2-g3-v2.0.0
git push origin :refs/tags/module-2-g3-v2.0.0
git tag -a module-2-g3-v2.0.0 -m "Module 2 G3 v2.0.0"
git push origin module-2-g3-v2.0.0
```

## Recommended local sequence

```bash
git switch main
git pull --ff-only origin main
git status
python tools/validate_public_release.py
git diff --check
git add .
git commit -m "Publish Module 2 G3 v2.0.0"
git push origin main
```

Then recreate the tag as shown above.

## Release boundary

The public release includes accepted source, selected evidence, documentation, and governed transparency records. It does not publish production credentials, raw private exports, operational databases, private correspondence, or claims beyond the deterministic synthetic boundary.
