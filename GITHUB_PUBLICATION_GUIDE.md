# GitHub Publication Guide

## Repository Settings

- Repository name: `merchant-sales-based-financing-strategy-simulator`
- Visibility: Public
- Default branch: `main`
- Issues: Disabled
- Discussions: Disabled
- Wiki: Disabled
- Projects: Disabled
- GitHub Pages: Disabled for v1.0.0
- License: MIT
- Byte preservation: keep the committed `.gitattributes`; do not run `git add --renormalize`.

## Recommended First Commit

```bash
git init
git branch -M main
git add .
git commit -m "Initial public release: Module 1 G2 v1.0.0"
git remote add origin https://github.com/andrew-goad/merchant-sales-based-financing-strategy-simulator.git
git push -u origin main
```

## Tag and Release

```bash
git tag -a module-1-g2-v1.0.0 -m "Module 1 G2 v1.0.0"
git push origin module-1-g2-v1.0.0
```

Create a GitHub Release titled:

> Merchant Sales-Based Financing Strategy Simulator - Module 1 G2 - Governed Merchant Intelligence, Risk, Economics & Acquisition Foundations

Attach the release ZIP and its `.sha256` companion. Do not commit the ZIP inside the repository tree.

## Final Live Checks

1. Confirm the root README renders correctly.
2. Open both architecture PNGs and PDFs.
3. Open the strategic brief PDF, cover, and contact sheet.
4. Test the executive, technical, and governance reviewer paths.
5. Download the release ZIP and independently re-run SHA-256.
6. Confirm no Issues, Discussions, Wiki, Projects, or Pages surface is enabled.
