# Initial 750-Merchant Cohort Overview — R3 editorial patch 1

**Date:** September 8, 2026. **Status:** Four amended pages ready for owner review.

This is a bounded editorial/layout derivative of the accepted R3 report, not a new cohort analysis, Power BI build, or R26 execution. The owner accepted the rest of the visual report and identified only the explanation on page 2, context on page 3, and crowded KPI boxes on pages 14/31.

## Review first

Open `review/Changed_Pages_02_03_14_31.pdf` for the four corrected pages. The full 53-page PDF and editable PowerPoint are under `public/`. The four individual PNGs are under `review/pages/`.

The `public/` folder identifies the two report derivatives intended for the eventual public report set; it is not permission to upload them. The containing review package, source locators and validation records are not an automatically approved public asset.

## What 31.5% means

For each of the 750 matched merchant/application pairs, compare `governed_final_outcome_code` between `BASELINE` and `RECESSION_ENERGY` in the same retained source run. There are 1,500 application-scenario records: two records per pair.

236 pairs differ in their final decision category; 514 retain the same category. Therefore 236 / 750 × 100 = 31.4666…%, displayed as 31.5%. The 49-cell outcome transition matrix reconciles exactly to the original derived file.

This is not a before-and-after event, software-version comparison, M2.11 profile comparison, or count of approvals lost. Changed terms with the same final category do not count. Approve-as-requested becoming an authorized counteroffer does count, even though both categories are authorized.

## Precisely bounded changes

| Page | Change | Preserved |
|---|---|---|
| 2 | Label changed to “Outcome differs in stress”; explicitly identify 236/750 matched pairs and Baseline vs. Recession Energy; add comparison interpretation. | All KPI values and analytical conclusions. |
| 3 | Explain population, source-derived calculations, screenshot coverage, and the scoped Power BI acceptance references. Identify the 94 images as screenshots, not merchants. | 94 total = 32 P01 + 32 P02 + 28 P03 + 2 P04; R17/PBI identities and authority scope. |
| 14 | Separate the large 514/236 values from their percentage captions. | Every word, figure, chart image and other layout element. |
| 31 | Separate 34/20/4 values from dates and endpoint captions. | Every word, figure, chart image and other layout element. |

## Version and preservation rule

The original R3 PPTX/PDF and private source carrier are unchanged. The new filenames explicitly include `R3_PATCH1_20260908`. The printed R3 report headers, original date context, all other slides and all notes remain unchanged to avoid a global editorial rewrite. Patch identity is in the filename and this receipt; this does not silently rename or overwrite the accepted R3 files.

Only `ppt/slides/slide2.xml`, `slide3.xml`, `slide14.xml`, and `slide31.xml` differ from the exact R3 PowerPoint. All 38 embedded media files, all 53 notes and all other package members are byte-exact. In the assembled PDF, the other 49 pages are pixel-identical at the tested 1.5× render scale. Changes on the four edited pages are contained within the edited text/shape regions.

## Verification scope

- Read-only paired-outcome recalculation against the exact R1FactFinalDecision export and original 49-cell transition matrix.
- Screenshot counts reconciled to the exact evidence register: 94 presentation-focused captures and 48 other private QA images. No private screenshots are newly distributed.
- Corrected PDF page images inspected, and native PowerPoint/PDF copy and layout compared.
- No engine run, PostgreSQL connection, Power BI refresh/save, cohort reconstruction, new screenshot capture, live repository modification, publication or public supersession.
- Native Windows PowerPoint rendering and Windows-native ZIP extraction have not been tested here.

The owner’s approval of the two preserved proof posters is recorded separately; their images were not changed.
