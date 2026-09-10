# MSBF Merchant Credit Intelligence

## Final Power BI publication-candidate package - Module 2 v2.1.0-rc2

**Product:** MSBF Merchant Credit Intelligence (MSBF MCI)  
**Subtitle:** Decisioning, Portfolio & Servicing Intelligence  
**Release candidate:** Module 2 v2.1.0-rc2  
**Package revision:** R3 - focused R16 correction / final publication candidate  
**Status:** R16 localized P04 correction complete; owner-confirmed no-output-change/no-recapture signoff recorded; package ready for expedited focused re-audit. Public release/public supersession is not executed by this package.

## Overview

This package provides the final client-facing Power BI rc2 artifact and the governance, requirements, validation, traceability, persistence-closure, handoff, and curated visual evidence needed for controlled GitHub publication. The report presents deterministic synthetic merchant-credit decisioning, portfolio, lifecycle, monitoring, intervention, servicing, reconciliation, and certification evidence.

Visible report scope:

1. **P01 - Cohort Command Center**
2. **P02 - Cohort Lifecycle**
3. **P03 - Application Journey**
4. **P04 - Servicing & Exceptions**

`P02-DIAG - Attention States` remains a hidden diagnostic page. P05 and P06 are not part of the client-facing rc2 PBIX.

## Final artifact identity

- **File:** `release/MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix`
- **Bytes:** `27,635,305`
- **SHA-256:** `ca46e8551860836a0cf4ff9239c42fcf8df02f1705596b9f8ca1bd047b5294e4`
- **Observed-source cutoff:** `2026-07-23`
- **Synthetic-forward lifecycle endpoint:** `2026-11-22`
- **Technical authority:** accepted R26 M2.5-M2.12 / G3-v2 successor baseline
- **Persistence/nonregression:** **PASS / CLOSED**, including bounded post-R16 correction signoff; DataModel unchanged and owner approved reuse of existing captures


## R16 focused correction

Independent Audit decision `IA-D-R16-PBI-001` identified exactly two stale predecessor filters on P04 visual `36e098c177fe1ff70689` (`Payment & certification detail`). Both were removed, while `R1Measures[R26 P04 Requires Attention Flag] = 1` was retained. A complete physical visual-JSON scan including `filterConfig` now reports **0 predecessor-fact references** and **0 predecessor-fact filter rows**. The embedded DataModel hash is unchanged.

The owner observed no change to visible results and expressly approved **no re-capture** of P04 screenshots. Existing final P04 captures remain the controlling output evidence; the correction evidence is physical PBIX diff/scan evidence.

## Package map

| Path | Purpose |
| --- | --- |
| `release/` | Final client-facing rc2 PBIX |
| `docs/` | Canonical source of truth, BRD, and validation report |
| `registers/` | Canonical workbook/state, requirements, traceability, validation, report structure/bindings, evidence, and release registers |
| `assets/power_bi/core/` | Curated public-candidate Power BI captures |
| `handoff/` | Persistence closure receipt and copy/paste audit/publication prompts |
| `manifests/` | Payload manifest, SHA-256 register, and package validation receipt |

## Validation position

The final validation population contains **52 controls: 51 PASS, 0 DEFERRED, 1 PENDING**. The sole pending control is the separately authorized GitHub publication/public-supersession action.

The requirements baseline contains **142 requirements: 142 VERIFIED**.

Passed controls include physical PBIX integrity; 70/70 G3-v2 certification; exact P01-P04 page/binding inventory; zero predecessor-fact references across all 96 physical visual JSON files, including `filterConfig`; 1,500 application-scenario paths; 15,600 monitoring rows across 130 funded paths; P03 narrative and monitoring QA; the complete M2.6-M2.10 P04 chain and seven-result QA; scenario/interaction/accessibility controls; owner-confirmed persistence closure; and publication-package path/checksum/clean-extraction controls.

## Remaining controlled action

No further Power BI report edits are authorized in this release cycle absent a verified defect. The next sequence is:

1. expedited focused independent re-audit of this exact R3 package against IA-D-R16-PBI-001;
2. if accepted, separately authorized GitHub publication/public supersession;
3. download every hosted artifact and verify exact hash, byte size, and Windows-native clean extraction against the final package.

## Interpretation boundaries

- All data and outcomes are deterministic synthetic evidence.
- Baseline and Recession Energy are alternative governed scenarios, not forecasts or sequential states.
- Post-cutoff lifecycle activity is synthetic-forward through 2026-11-22.
- The report is not a production underwriting, pricing, payment, or servicing system.
- No causal, treatment-effect, audited-profitability, CECL, regulatory-model-validation, or real-customer claims are authorized.

Start with `docs/CANONICAL_SOURCE_OF_TRUTH.md`, then `docs/POWER_BI_VALIDATION_REPORT.pdf`, then the appropriate handoff prompt.
