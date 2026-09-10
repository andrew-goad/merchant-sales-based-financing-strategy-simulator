# COPY/PASTE PROMPT - EXPEDITED R16 POWER BI CORRECTION RE-AUDIT

Perform the expedited focused re-audit of `MSBF_MCI_POWER_BI_GITHUB_PUBLICATION_SUPPORT_R3_20260904.zip` as the successor submission to Independent Audit decision **IA-D-R16-PBI-001**.

## Controlling correction scope

R16 returned `HOLD` for **one localized P04 correction only** on:

- Page: `P04 - Servicing & Exceptions`
- Visual ID: `36e098c177fe1ff70689`
- Title: `Payment & certification detail`

The corrected PBIX removes exactly these stale predecessor predicates:

1. `FactAccountDaily[monitoring_status_rank] >= 1`
2. `FactMonitoringEndpoint[P04 Monitoring Status] <> "Paid off"`

and retains the correct successor predicate:

`R1Measures[R26 P04 Requires Attention Flag] = 1`

## Exact corrected PBIX

- File: `release/MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix`
- Bytes: `27,635,305`
- SHA-256: `ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4`
- Embedded DataModel SHA-256: `24396d02c0fbcb782cc9918e842886711146b8ff9455c8822d2aeaf009b96061` - unchanged from the audited R2 PBIX

## Required focused recheck

1. Verify outer ZIP sidecar, CRC, clean extraction, path safety, MANIFEST.csv, SHA256SUMS.txt, and payload reconciliation.
2. Verify the corrected PBIX exact size/hash and embedded DataModel identity.
3. Directly inspect the physical PBIX visual JSON for `36e098c177fe1ff70689` and confirm the two R16 predecessor predicates are absent and `R26 P04 Requires Attention Flag = 1` remains active.
4. Independently scan **all physical visual JSON, including every `filterConfig` and active predicate**, and confirm:
   - predecessor-fact references across physical visual JSON = `0`;
   - predecessor-fact filter rows = `0`.
5. Reconcile that scan to:
   - `registers/CURRENT_PHYSICAL_VISUAL_REFERENCES_R7.csv`;
   - `registers/CURRENT_PHYSICAL_FILTER_REFERENCES_R7.csv`;
   - `registers/PHYSICAL_VISUAL_REFERENCE_SCAN_SUMMARY_R7.csv`;
   - `registers/FOCUSED_CORRECTION_PBIX_MEMBER_DIFF_R7.csv`.
6. Confirm correction boundedness: DataModel unchanged; no query/layout change outside `filterConfig`; only the four documented PBIX members changed versus the audited R2 candidate.
7. Ingest `handoff/R16_FOCUSED_P04_CORRECTION_RECEIPT_R1_20260904.*` and `handoff/PERSISTENCE_CLOSURE_RECEIPT_R2_20260904.*`.
8. Preserve all prior R16 PASS / PASS_WITH_OBSERVATIONS determinations outside this localized blocker unless the corrected bytes independently demonstrate a new defect.

## Owner signoff on evidence re-capture

The owner reports that **no visual or numerical change was noticed after the stale filters were removed** and expressly approves **not re-capturing P04 screenshots**. The existing final P04 Baseline, Recession Energy, merchant-filtered, tooltip, accessibility, tab-order, and seven-result QA captures remain the controlling output evidence.

The owner asks Independent Audit to accept this no-recapture treatment because:

- the correction is confined to stale `filterConfig` predicates;
- the embedded DataModel is byte-identical;
- the target visual and the other changed P04 visual are identical outside `filterConfig`;
- the correct successor attention predicate remains active; and
- no visible/result change was observed.

Do **not** HOLD merely because duplicate screenshots were not recreated unless the physical correction or independent inspection demonstrates a result change or other regression that would make re-capture materially necessary.

## Explicit non-rerun boundary

Do **not** require another:

- R26 execution;
- G3-v2 70-control cycle;
- P03 1,500-path narrative QA cycle;
- broad semantic-model validation cycle;
- P01/P02 test cycle; or
- general Power BI publication-readiness cycle

unless the focused correction independently exposes a new defect.

## Decision requested

Return an expedited **ACCEPT / REJECT / HOLD** on the R3 corrected publication candidate.

If the corrected PBIX has zero predecessor-fact references across all physical visual JSON and the package/identity/persistence evidence reconciles, authorize direct handoff to the separately controlled GitHub publication action.

Do **not** publish to GitHub or activate public supersession during this audit.
