# R19 publication-integrity workflow restoration

The supplied GitHub repository ZIP contained a Git working tree in which `.github/workflows/publication_integrity.yml` was deleted even though the path remained tracked in `HEAD`, `MANIFEST.csv`, `PACKAGE_INVENTORY.csv`, and `SHA256SUMS.txt`.

R19 does not invent a replacement. It restores the exact tracked blob from repository `HEAD`:

```text
Repository HEAD SHA-1  46fb1f9198475678edc9cabdeefd2f91a59e49c2
Git blob SHA-1         6be647e9fec6b8a04ffe2d342718a82cebddc4a2
File bytes             359
File SHA-256           9c2535f1ab9d484b55fbaeff023e05bcd136cbeee7e43b407fc6073aa65587ed
```

The restored workflow runs the existing `tools/validate_public_release.py` on pushes to `main`, pull requests, and manual dispatch. Applying the exact file to a clean copy of the supplied repository changed the repository validator from `Manifest extra path` failure to:

```text
Public release validation PASS
Governed manifest files: 1930
Module 2 stage folders: 12
```

The exact file is staged at `repository_overlay/.github/workflows/publication_integrity.yml`. The original repository remains unchanged; integration is deferred until a physical R19 PASS and the governed repository/Power BI/audit gate.
