# COPY/PASTE PROMPT - CONTROLLED POWER BI GITHUB PUBLICATION AFTER AUDIT ACCEPT

Proceed only after Independent Audit has returned **ACCEPT** for `MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip` as the corrected successor to `IA-D-R16-PBI-001`.

Use the exact audited R3 bytes. Do not regenerate the PBIX or silently substitute another project artifact.

## Publication candidate

- PBIX: `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix`
- Bytes: `27,635,305`
- SHA-256: `ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4`
- Visible scope: P01-P04
- Hidden diagnostic: P02-DIAG - Attention States
- P05/P06: excluded from the client-facing rc2 publication
- Evidence boundary: deterministic synthetic evidence only

R16's localized P04 stale-filter blocker has been corrected. The accepted R3 physical scan must show zero predecessor-fact references across all visual JSON including `filterConfig`.

## Publication action

1. Publish only the artifacts approved by the accepted audit and the package publication policy.
2. Preserve the public/client-facing boundary: do not publish private owner QA/UI evidence, internal project ZIPs, or internal P05/P06 candidate pages unless separately authorized.
3. Preserve release-candidate wording. Do not represent rc2 as production software, production underwriting/servicing, real-customer results, causal evidence, CECL, audited profitability, or regulatory model validation.
4. Activate public supersession only within the authority explicitly accepted by Audit.
5. After publication, download every hosted artifact and verify:
   - exact SHA-256;
   - exact byte size;
   - archive CRC where applicable;
   - path safety; and
   - Windows-native clean extraction of downloadable ZIP assets.
6. If any hosted byte differs from the audited package, HOLD. Do not silently regenerate or replace the accepted artifact.
7. Produce a final publication receipt listing hosted URLs, downloaded hashes/sizes, extraction results, and supersession state.

The owner-approved existing P04 captures remain valid publication evidence; the R16 correction did not change visible results and no duplicate screenshot cycle was performed.
