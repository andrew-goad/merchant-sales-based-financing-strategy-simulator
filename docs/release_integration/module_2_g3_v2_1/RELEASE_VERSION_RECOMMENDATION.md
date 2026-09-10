# Release-version recommendation — not owner selection

**Recommendation:** use stable release family **Module 2 / G3 v2.1.0** after the combined candidate passes Independent Audit and explicit public supersession is granted.

Rationale: the public predecessor is v2.0.0; the accepted R26 work is a substantive strategy/lifecycle successor rather than a documentation-only patch; Power BI's immutable filename already contains `v2.1.0-rc2` but that filename is evidence identity, not the authority for the stable tag. A stable v2.1.0 tag would therefore describe the integrated release family without renaming the PBIX.

This package does **not** create the tag or claim the owner has selected it. Final audit should assess the candidate independently of the filename recommendation. If the owner selects another v2.1-family label before submission, update only current candidate metadata/navigation and re-run candidate validation; do not rename accepted source/PBIX bytes.
