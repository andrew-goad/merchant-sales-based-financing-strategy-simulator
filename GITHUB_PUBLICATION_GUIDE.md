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
