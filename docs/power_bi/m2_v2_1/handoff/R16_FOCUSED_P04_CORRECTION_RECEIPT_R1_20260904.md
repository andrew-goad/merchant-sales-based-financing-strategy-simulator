# R16 Focused P04 Correction Receipt

**Decision addressed:** `IA-D-R16-PBI-001`  
**Correction scope:** One localized P04 visual only  
**Corrected package cycle:** R3 / Canonical R7  
**Date:** 2026-09-04

## Authorized defect

Independent Audit identified two stale predecessor-fact predicates on P04 visual `36e098c177fe1ff70689`, **Payment & certification detail**:

1. `FactAccountDaily[monitoring_status_rank] >= 1`
2. `FactMonitoringEndpoint[P04 Monitoring Status] <> "Paid off"`

The successor filter `R1Measures[R26 P04 Requires Attention Flag] = 1` was already correct and was required to remain.

## Corrected physical state

- Client PBIX: `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix`
- Bytes: `27,635,305`
- SHA-256: `ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4`
- Embedded DataModel SHA-256: `24396d02c0fbcb782cc9918e842886711146b8ff9455c8822d2aeaf009b96061` - **unchanged**
- Target predecessor predicates: **0**
- Retained successor attention predicate: **present / active**

A complete direct scan of all 96 physical visual JSON files, including every `filterConfig`, found:

- 293 physical field-reference occurrences;
- 26 `filterConfig` rows;
- 3 active filter predicates;
- **0 predecessor-fact reference occurrences**; and
- **0 predecessor-fact filter rows**.

## Exact PBIX boundedness

Only four internal PBIX members changed versus the audited R2 candidate:

1. target visual `36e098c177fe1ff70689/visual.json` - exactly the two stale predicates were removed; non-filter JSON is unchanged;
2. P04 Endpoint monitoring posture visual `82fed0991642d762c6ce/visual.json` - Power BI Desktop serialized four current/shared field references into `filterConfig`; none has an active predicate and non-filter JSON is unchanged;
3. `pages.json` - saved active page changed to P04; page order is unchanged;
4. `SecurityBindings` - save serialization metadata changed.

No DataModel member changed. No visual query/layout content changed outside `filterConfig`.

## Owner output-equivalence and no-recapture signoff

The owner confirms that **no visual or numerical change was noticed after the stale filters were removed** and expressly approves **not re-capturing P04 evidence**. The existing final P04 Baseline, Recession Energy, filtered-account, tooltip, accessibility, tab-order, and seven-result QA captures remain the controlling output evidence.

This owner signoff is intentional: the correction was confined to stale physical filter metadata; the semantic model is byte-identical; the surviving successor attention predicate is unchanged; and the physical report output was observed to remain unchanged. Duplicate screenshot capture would not add substantive assurance.

## Required audit recheck

The expedited re-audit should verify the corrected PBIX hash/size, the target visual `filterConfig`, the complete physical visual/filter reference scan, this bounded correction receipt, and the updated package manifests. It should **not** require another R26 run, G3-v2 cycle, P03 1,500-path QA cycle, broad semantic validation cycle, or duplicate screenshot cycle absent a newly demonstrated regression.
