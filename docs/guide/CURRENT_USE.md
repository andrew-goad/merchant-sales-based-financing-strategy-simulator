[MSBF](../../README.md) / [Documentation](../README.md)

# Current Use Guide

### Choose a supported activity before choosing an execution route.

You can inspect the documentation, exact source, analytical report and frozen visual assets directly. Database replay is a different activity: the qualified route requires **specific retained checkpoints**, not an empty database or an arbitrary new campaign.

This guide points to existing tools and procedures; it does not replace them or authorize execution. [Current authority and scope](../release_integration/module_2_g3_v2_1/CURRENT_STATE.md).

## At a glance

| Activity | Availability / prerequisite |
| --- | --- |
| Read the code, guides, cohort and visuals | Available in this repository snapshot; no database needed. |
| Check retained repository files | Complete local tree, Python and its existing manifests/validators. |
| Read the Tableau scenario-review companion | PDF and PNGs are available without Tableau; the authoring `.twb` needs its original data or a separately packaged workbook. |
| View the accepted Power BI report | Exact PBIX plus Power BI Desktop; open a separate copy, without refresh or save. |
| Route A · offline M2.11 reproduction | Documented but prerequisite-dependent: exact runtime and accepted output/reference inputs. |
| Route B · checkpoint restore and replay | Qualified within its specific retained-checkpoint scope; private checkpoint carriers, exact runtime and approved isolated environment required. |
| Route D / arbitrary fresh campaign | **Not qualified here.** No general run-all-programs procedure is supplied. |

## Inspect and browse

The [documentation portal](../README.md) maps G0/G1, Module 1 and Module 2 to their original packages. Start with [cash capacity](stages/M1_10.md), [structure search](stages/M2_02.md) or [operational setup](stages/M2_07.md) to follow a business question into requirements, implementation and evidence.

Use the [Markdown visual gallery](../portfolio_visuals/MSBF_VISUAL_PUBLIC_R1/GALLERY.md) for the ten-page pitch, 23-page masterclass, engineering trio, two explainers and 53-page cohort report. Downloadable gallery HTML is not evidence of a hosted GitHub Pages site. No report preview or source map is a database-build instruction.

## Verify retained files

With a complete local copy, the existing [public-release validator](../../tools/validate_public_release.py) checks structured-file readability, selected public-text risks, relative Markdown links, exact root manifest membership/hashes and required release surfaces. The historical [rc2 overlay validator](../../successor_candidates/m2-g3-v2.1.0-rc2/tools/validate_candidate_overlay.py) checks its own retained projection. **A validator PASS is not new technical acceptance or a public/private classification decision.**

For component inputs and accepted outputs, the detailed runbook provides [file verification and reconciliation tooling](../reproducibility/m2_v2_1/runbook/tools/runbook_checks.py), the [component locks](../reproducibility/m2_v2_1/runbook/registers/COMPONENT_LOCK.json) and [golden R26 reference](../reproducibility/m2_v2_1/runbook/registers/GOLDEN_R26_REFERENCE.json). Its commands require the specified input file and a new evidence destination. Follow the exact [procedure](../reproducibility/m2_v2_1/runbook/REPRODUCIBILITY_AND_EXECUTION.md); do not shorten expected hashes or substitute a projected folder for the locked outer ZIP.

**Expected evidence:** identity/manifest report, followed where applicable by accepted-reference reconciliation. A successful process exit alone is not the required comparison.

## View Power BI

The retained file is [MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix](../power_bi/m2_v2_1/release/MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix). Keep its accepted name and bytes. Use the runbook's **Route C** to verify it, make a separate viewing copy, and inspect it in Power BI Desktop **without refresh or save**.

P01–P04 are the visible command-center, cohort, application-journey and servicing experiences. P02-DIAG is hidden; P05/P06 are outside this report's public scope. The observed-source cutoff is **23 July 2026** and the synthetic-forward endpoint **22 November 2026**. [Exact report identity and viewing scope](../power_bi/m2_v2_1/README.md) · [Route C and identity-check instructions](../reproducibility/m2_v2_1/runbook/REPRODUCIBILITY_AND_EXECUTION.md).

The stored report can be viewed; opening it is not permission to reconnect sources or create a fresh analytical run.

## View the Tableau companion

Start with the [Tableau overview](../tableau/README.md) and [13-page carousel](../tableau/docs/MCI_Risk_Decision_Scenario_Review_Carousel.pdf). The dashboard investigates 750 matched applications across the two alternative scenarios, with portfolio controls, a decision matrix, two segment modes and source-backed application explanations.

The retained [Tableau authoring definition](../tableau/release/MCI_Risk_Decision_Scenario_Review.twb) is not a self-contained `.twbx`. Its CSV and temporary extract are not bundled; see [dependencies and reference checks](../tableau/docs/WORKBOOK_AND_EVIDENCE_NOTES.md). Opening this companion does not require or authorize a new database replay.

This viewing addition is not a new qualified execution route, technical release or supersession of Power BI or accepted source records.

## Route A · offline proof, with exact inputs

The retained procedure re-executes the source-owned **M2.11 simulation/canonicalization proof**, without PostgreSQL. It requires the exact retained-final runtime and accepted result/reference inputs named in the component locks; those are not interchangeable with any file containing “R26” in its name.

Use the original [offline replay tool](../reproducibility/m2_v2_1/runbook/tools/offline_replay.py) and the procedure's Route A instructions. The expected deliverable is a comparison to retained accepted outputs, not a newly originated merchant population. Availability of a readable source projection does not establish possession of every required carrier. [Route A inputs and method](../reproducibility/m2_v2_1/runbook/REPRODUCIBILITY_AND_EXECUTION.md).

## Route B · qualified checkpoint replay

The demonstrated route is **portable checkpoint restore + isolated retained-final M2.11/M2.12/G3-v2 replay**. The historical qualification used Windows 10, PowerShell 7.6.5, Python 3.14.7 and PostgreSQL 17.9, and its result reconciled **90/90** accepted-reference checks. Those are retained execution facts—not tests repeated by this documentation edit.

Prerequisites include the exact **R6 source checkpoint**, **retained R26-R2 checkpoint**, locked resume runtime, an approved isolated environment and run-specific controls. The two backup carriers remain **privately retained**, not public repository assets. A fresh PostgreSQL installation does not supply them. [Qualification scope and prerequisites](../reproducibility/m2_v2_1/PUB_RUN_001_ROUTE_B_QUALIFICATION_R1.md).

Read the [complete procedure](../reproducibility/m2_v2_1/runbook/REPRODUCIBILITY_AND_EXECUTION.md), [qualification record](../reproducibility/m2_v2_1/PUB_RUN_001_ROUTE_B_QUALIFICATION_R1.md) and [current R20 overlay](../release_integration/module_2_g3_v2_1/CURRENT_STATE.md) together. The original runbook's pending-qualification labels are historical. R20 preserves the later bounded qualification; it does not create a universal, fully automated restore-and-run command.

Do not rerun an unknown or interrupted state, use an accepted final database as a write target, or execute a recovery script because it is next in a filename list. The retained qualification's strict STOP and bounded continuations are part of its history—not blanket permission to ignore a new mismatch.

## Not a general launcher

The [historical 230-position catalog](../reproducibility/m2_v2_1/runbook/registers/HISTORICAL_230_PROGRAM_MAP.csv) is useful for source review; it is **not a qualified R26 end-to-end execution recipe**. The retained-final runtime resumes M2.11–M2.12; it verifies M2.5–M2.10 as predecessor facts rather than rerunning them. [Runtime boundary](../../successor_candidates/m2-g3-v2.1-r26-integration/README.md).

Empty-database Route D, arbitrary new campaigns, 2,500/25,000 scale execution and a generalized campaign runner remain future/separately gated work. Campaign Scale and Module 3 receive no runtime authority from these pages.

## Publication remains separate

R20's conditional authority does not mean the stable release exists. Four actual release ZIP identities, fresh owner Git/base/tag checks, final commit binding and subsequent hosted-download/Windows-extraction closure remain separate release conditions. None is established by browsing these pages or running a local manifest check.

[Current release state](../release_integration/module_2_g3_v2_1/CURRENT_STATE.md) · [Return to the portfolio](../../README.md)

*Deterministic synthetic demonstration only. No production underwriting, real payments, autonomous operation or regulatory/model approval is claimed.*

## Source completeness and environment scope

[M1.17 source-provenance caveat](stages/M1_17.md) matters for any attempted rebuild: the exact executed standalone v0.2R2 Programs 124C–128 were unavailable at final packaging. Retained evidence and the correction chain are not a license to generate substitute source and call it identical.

The qualified Windows Route B records PostgreSQL 17.9, Python 3.14.7 and PowerShell 7.6.5 for its **checkpoint restore plus isolated retained-final M2.11/M2.12/G3-v2 replay**. That qualification does not convert older PostgreSQL 15 predecessor instructions into a tested PostgreSQL 17 empty-database rebuild. R26's retained-final resume checks existing M2.5–M2.10 checkpoint evidence; it does not repeat those stages as a normal new run.

The public-release and candidate-overlay validators are file-only tools delivered in the repository. Their actual paths are [tools/validate_public_release.py](../../tools/validate_public_release.py) and [historical rc2 candidate-overlay validator](../../successor_candidates/m2-g3-v2.1.0-rc2/tools/validate_candidate_overlay.py). Their PASS results concern their documented file/metadata checks, not live Git state, private-content declassification or arbitrary-campaign execution.

[Read source-version boundaries](SOURCE_VERSIONS.md) · [Choose a Power BI/cohort reading path](ANALYTICS.md) · [Current prepublication status](../release_integration/module_2_g3_v2_1/CURRENT_STATE.md).
