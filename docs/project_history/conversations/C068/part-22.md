# Merchant POS Lending Simulator

Part 22 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-21.md)
[Next part](part-23.md)

<a id="m-35b093d4-ed20-485b-a704-51ccabf38e34"></a>
## Assistant · C068-M00293

C068-M00293 · 2026-07-26T20:05:33.971777-04:00 · active path

Preceding visible parent: [C068-M00292](part-21.md#m-8e64f045-5b8d-45eb-ab8a-f544c809a2a2)

<!-- BEGIN_SOURCE_MESSAGE -->
# M1.13 — Exposure, Recovery & Expected Loss Foundations

The complete **M1.13 v0.2 governed module** is built, statically validated, integrated into the accepted M1.12 repository, and ready for controlled PostgreSQL execution.

M1.13 is **not yet live-executed or accepted**. Formal acceptance will require successful execution, structured evidence export, independent evidence review, and milestone sign-off.

## Primary deliveries

### Standalone M1.13 package

Download MSBF M1.13 v0.2 (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2.zip`; referenced bytes not established here)

Download the standalone SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2.zip.sha256`; referenced bytes not established here)

```text
SHA-256
ee7749d33cfda42def7297cb1079e07aaf956ad7083e48a427307ef131283306

Archive size
317,021 bytes

Files
46
```

Canonical long-form copy:

Download the canonical M1.13 package (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_13_exposure_recovery_expected_loss_foundations_v0_2.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_13_exposure_recovery_expected_loss_foundations_v0_2.zip.sha256`; referenced bytes not established here)

### Updated full project repository

This repository preserves every accepted artifact through M1.12 and adds M1.13 under `15_M1_13` in **Ready for Live Execution** status.

Download MSBF Project v0.2 — M1.13 Ready for Execution (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_13_READY_FOR_EXECUTION_Windows.zip`; referenced bytes not established here)

Download the full-project SHA-256 file (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_13_READY_FOR_EXECUTION_Windows.zip.sha256`; referenced bytes not established here)

```text
SHA-256
dcfee3a37f82a293f2ce2c60088e0b7d4935fb6bc4b9eef20f576aa5a1041793

Archive size
8,944,338 bytes

Files
1,450

Longest internal path
180 characters
```

Canonical full-project copy:

Download the canonical M1.13-ready repository (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M1_13_READY_FOR_EXECUTION.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M1_13_READY_FOR_EXECUTION.zip.sha256`; referenced bytes not established here)

The canonical and Windows-compatible project ZIPs contain identical content. For Windows, extract near the drive root, preferably:

```text
C:\MSBF\
```

---

# Module purpose

M1.13 creates a governed, scenario-aware foundation for:

- contractual-receivable exposure;
- daily exposure-path construction;
- path-weighted Exposure at Default;
- recovery evidence and LGD assumptions;
- simple comparative expected loss;
- schedule-adjusted comparative expected loss;
- matched baseline-versus-stress loss evidence.

The analytical boundary is explicit:

```text
Synthetic merchant-risk proxy
≠
Contractual exposure path / EAD foundation
≠
Recovery / LGD foundation
≠
Comparative expected loss
≠
CECL, reserves, capital, pricing, or decisioning
```

M1.13 does **not** produce:

- calibrated probability of default;
- production EAD or LGD;
- CECL allowance or reserve;
- regulatory capital;
- pricing;
- an offer;
- approval, counteroffer, manual-review, or decline outcomes;
- adverse-action reasons;
- Module 1 latest or archive contract outputs.

Open the M1.13 architecture diagram (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/diagrams/M1_13_ARCHITECTURE.png`; referenced bytes not established here)

Open the architecture specification (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/docs/M1_13_ARCHITECTURE.md`; referenced bytes not established here)

---

# Governed physical outputs

## Daily EAD path

```text
msbf_m1.application_ead_path_value
```

The table records each application’s contractual-receivable exposure from day zero through its governed expected payoff horizon.

Governed grain:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
+ path_day_number
```

## Exposure, recovery, and comparative-loss snapshot

```text
msbf_m1.application_exposure_recovery_loss_snapshot
```

Governed grain:

```text
module1_run_id
+ scenario_id
+ merchant_application_id
```

## Lineage view

```text
msbf_m1.v_m1_13_exposure_recovery_loss_lineage
```

The view exposes the accepted lineage from:

```text
M1.3 requested financing terms
+
M1.10 capacity evidence
+
M1.12 integrated merchant-risk proxy
+
frozen EAD / LGD parameters
+
source, collateral, and guarantee evidence
```

## Expected live cardinality

```text
750 applications
×
2 matched scenarios
=
1,500 exposure/recovery/loss snapshots
```

The daily exposure-path population varies by each application’s 30-, 60-, or 90-day payoff horizon:

```text
Path Rows
=
2 scenarios
×
Σ(requested expected payoff days + day zero)
```

For the accepted M1.3 population:

```text
188 applications × 30 days
337 applications × 60 days
225 applications × 90 days
```

the exact expected output is:

```text
93,720 daily exposure-path rows
```

Combined canonical reconciliation universe:

```text
93,720 path entities
+
1,500 snapshot entities
=
95,220 canonical entities
```

---

# Exposure methodology

## Initial exposure

M1.13 uses the requested total repayment amount as the initial contractual-receivable exposure:

```text
Initial Receivable Exposure
=
Requested Total Repayment Amount
```

This is intentionally distinct from funded principal because the modeled asset is the contractual sales-based receivable.

## Governed daily payment

The daily contractual payment foundation is derived from the accepted requested structure. Under `RECESSION_ENERGY`, the adverse-scenario daily payment is capped at the accepted baseline amount:

```text
Final Stress Daily Payment
=
minimum(
    Independent Stress Payment,
    Accepted Baseline Payment
)
```

An adverse scenario therefore cannot create artificially faster contractual paydown.

## Exposure path

Frozen 30-, 60-, and 90-day paydown-curve parameters govern the path shape.

The package includes a specific rounding safeguard:

> The final payoff-horizon day is explicitly set to zero ending exposure.

This prevents two-decimal daily-remittance rounding from leaving a synthetic penny residual beyond the governed payoff horizon.

---

# Path-weighted EAD foundation

Each path day is assigned to a governed default-timing bucket:

```text
EARLY
MIDDLE
LATE
```

The frozen weight for each bucket is distributed across the number of path days within that bucket.

```text
Daily Default-Timing Weight
=
Bucket Weight
÷
Number of Days in Bucket
```

```text
Path-Weighted EAD
=
Σ(
    Ending Exposure
    ×
    Daily Default-Timing Weight
)
```

```text
Expected EAD Rate
=
Path-Weighted EAD
÷
Initial Receivable Exposure
```

This produces transparent schedule-aware exposure evidence without presenting the result as a calibrated production EAD model.

---

# Recovery and LGD foundation

The independent LGD foundation is:

```text
Industry LGD Baseline
+
Scenario LGD Add-On
−
Supported Collateral Recovery Credit
−
Supported Guarantee Recovery Credit
```

The result is bounded by frozen LGD floor and cap parameters.

Aggregate collateral and guarantee recovery credit is also bounded by a governed policy cap.

## Recovery evidence states

```text
SUPPORTED
PARAMETER_ONLY
CONFLICT
```

- `SUPPORTED` indicates usable collateral or guarantee evidence.
- `PARAMETER_ONLY` uses the governed industry and scenario assumptions without supported recovery evidence.
- `CONFLICT` preserves inconsistent recovery evidence and routes the record for review.

Under `RECESSION_ENERGY`, final LGD cannot improve relative to baseline:

```text
Final Stress LGD
=
maximum(
    Baseline LGD,
    Independent Stress LGD
)
```

---

# Comparative expected-loss foundations

M1.13 publishes two transparent synthetic comparison measures.

## Simple comparative expected loss

```text
Simple Comparative Expected Loss
=
Synthetic Merchant Risk Proxy
×
LGD
×
Initial Receivable Exposure
```

## Schedule-adjusted comparative expected loss

```text
Schedule-Adjusted Comparative Expected Loss
=
Synthetic Merchant Risk Proxy
×
LGD
×
Path-Weighted EAD
```

## Comparative loss rate

```text
Schedule-Adjusted Comparative Loss Rate
=
Schedule-Adjusted Comparative Expected Loss
÷
Initial Receivable Exposure
```

These are comparative analytical foundations—not forecasts, reserves, CECL outputs, or calibrated expected-loss estimates.

The manual-review and reason-routing logic uses the same persisted eight-decimal comparative-loss-rate basis presented in the physical snapshot. This prevents a visible metric from disagreeing with its routing threshold because of separate rounding sequences.

---

# Evidence gating

M1.13 assigns:

```text
COMPLETE
PARTIAL
BLOCKED
```

A blocked M1.12 integrated-risk record does not receive fabricated loss evidence:

```text
Synthetic Risk Proxy              NULL
Simple Comparative Loss           NULL
Schedule-Adjusted Comparative Loss NULL
```

The row remains present with an explicit controlled review route.

The governing principle remains:

```text
Missing or unusable risk evidence
≠
low expected loss
```

---

# Ten governed M1.13 features

The module registers ten active features under the `EXPOSURE_RECOVERY_LOSS` family:

1. Initial Receivable Exposure Amount  
2. Path-Weighted Exposure at Default  
3. Expected EAD Rate  
4. Industry LGD Baseline  
5. Recovery Rate Assumption  
6. LGD Input Rate  
7. Simple Comparative Expected Loss  
8. Schedule-Adjusted Comparative Expected Loss  
9. Schedule-Adjusted Comparative Loss Rate  
10. Recovery Evidence Status  

Open the feature dictionary (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_FEATURE_DICTIONARY.csv`; referenced bytes not established here)

---

# Physical schema extension

M1.13 adds:

```text
2 designed parent tables
69 designed columns
1 governed lineage view
10 active feature definitions
```

Projected physical-design totals after migration:

```text
80 designed parent/non-child tables
1,427 designed table columns
```

The original G0 milestone remains historically unchanged:

```text
70 physical parent tables
1,041 designed columns
```

M1.13 is a controlled post-G0 extension—not a rewrite of the accepted physical foundation.

Download program 92 — schema and policy extension (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/sql/92_msbf_m1_13_schema_policy_extension_v0_2.sql`; referenced bytes not established here)

Open the schema-extension table catalog (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_SCHEMA_EXTENSION_TABLES.csv`; referenced bytes not established here)

Open the schema-extension column catalog (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_SCHEMA_EXTENSION_COLUMNS.csv`; referenced bytes not established here)

---

# Performance and error-resolution engineering

The module incorporates the principal lessons from M1.6 through M1.12 before release.

## No upstream blueprint regeneration

M1.13 does not rebuild:

```text
M1.4 POS histories
M1.5 deposit/liquidity histories
M1.6 scenario overlays
M1.7 source-quality logic
M1.8 verification/fraud logic
M1.9 cash-flow feature engineering
M1.10 obligation/capacity logic
M1.11 operating-resilience logic
M1.12 integrated-risk logic
```

It reads accepted persisted inputs directly.

## Bounded processing path

```text
Accepted M1.12 risk snapshots
+
Accepted M1.10 capacity snapshots
+
Accepted M1.3 request terms
+
Frozen EAD/LGD parameters
        ↓
Materialize 1,500 matched inputs once
        ↓
Expand only the governed 30/60/90-day paths
        ↓
Persist 93,720 path rows and 1,500 snapshots
        ↓
Index and ANALYZE
        ↓
Independently reconstruct physical hashes
        ↓
Reconcile 95,220 canonical entities once
```

## Runtime controls

```sql
SET LOCAL work_mem = '128MB';
SET LOCAL jit = off;
SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '20min';
```

## Canonical-hash safeguards

- Expected tables use explicit target physical types before hashing.
- Numeric values are normalized to physical precision.
- Expected hashes are created before physical insertion.
- Whole-row hashing always uses explicit relation aliases.
- Physical hashes are independently reconstructed from persisted fields.
- Generation fails before commit unless expected and actual counts and hashes reconcile exactly.
- Validation and reporting read persisted outputs rather than rerunning business-generation logic.

## SQL projection safeguards

A deep static schema/DML audit confirmed:

```text
Schema tables parsed                     80
Persistent INSERT statements checked     14
Persistent UPDATE statements checked     10
Invalid persistent DML target columns     0
Major INSERT / SELECT shape differences   0
Unsafe whole-row hash references          0
Invalid dependency-column references      0
```

The four primary generation shapes reconcile exactly:

```text
Path expected INSERT / SELECT      17 / 17
Loss expected INSERT / SELECT      50 / 50
Path physical INSERT / SELECT      17 / 17
Loss physical INSERT / SELECT      50 / 50
```

## DBeaver behavior

Validation, negative-control, acceptance, and detailed-report working tables use session-preserved output where appropriate:

```sql
ON COMMIT PRESERVE ROWS
```

Their result grids remain sortable and filterable after commit within the same DBeaver session.

Validation helper functions use `PERFORM`, avoiding the earlier multiple-null-result-tab behavior.

Open the SQL engineering audit (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/docs/M1_13_SQL_ENGINEERING_AUDIT.md`; referenced bytes not established here)

---

# Exact execution order

Run these programs in DBeaver against the accepted `msbf_strategy` database.

| Order | Program | Required checkpoint |
|---:|---|---|
| 1 | 92 — Schema and policy extension (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/sql/92_msbf_m1_13_schema_policy_extension_v0_2.sql`; referenced bytes not established here) | `schema_policy_extension_status = PASS` |
| 2 | 93 — Preflight validation (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/tests/93_msbf_m1_13_preflight_validation_v0_2.sql`; referenced bytes not established here) | `preflight_status = PASS` |
| 3 | 94 — Exposure/recovery/loss generation (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/sql/94_msbf_m1_13_exposure_recovery_loss_generation_v0_2.sql`; referenced bytes not established here) | 93,720 paths + 1,500 snapshots; zero mismatches |
| 4 | 95 — Positive validation (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/sql/95_msbf_m1_13_exposure_recovery_loss_validation_v0_2.sql`; referenced bytes not established here) | 82 of 82 `PASS` |
| 5 | 96 — Negative controls (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/sql/96_msbf_m1_13_negative_control_tests_v0_2.sql`; referenced bytes not established here) | 7 of 7 `PASS` |
| 6 | 97 — Acceptance finalizer (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/sql/97_msbf_m1_13_acceptance_finalize_v0_2.sql`; referenced bytes not established here) | Gate `PASS`; run `M1_13_ACCEPTED` |
| 7 | 98 — Master report (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/tests/98_MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2.sql`; referenced bytes not established here) | `overall_m1_13_status = PASS` |
| 8 | 99 — Detailed report (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/tests/99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2.sql`; referenced bytes not established here) | 20 result sets; mismatch/error sets empty |

Open the complete M1.13 execution guide (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/docs/M1_13_EXECUTION_AND_VALIDATION_GUIDE.md`; referenced bytes not established here)

## Required program-94 checkpoint

```text
run_status               M1_13_GENERATED
path rows                 93,720
snapshot rows              1,500
applications                 750
scenarios                      2
canonical entities        95,220
row-level mismatches            0
path set hash              non-null
snapshot set hash          non-null
combined set hash          non-null
generation_status              PASS
```

The path-row count is calculated dynamically. For the current accepted population, it must equal 93,720.

After program 94 commits successfully, **do not rerun it**.

---

# Contingency programs

These are not part of the normal sequence.

## Failed-generation recovery

Download program 92A (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/tests/92A_msbf_m1_13_failed_generation_recovery_check_v0_2.sql`; referenced bytes not established here)

Use only after program 94 fails or is cancelled and after executing:

```sql
ROLLBACK;
```

Required:

```text
run_status             M1_12_ACCEPTED
path rows              0
snapshot rows          0
M1.13 evidence rows    0
M1.13 gate rows        0
blocking errors        0
recovery_state_status  PASS
```

## Lost generation-result reconstruction

Download program 94A (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/tests/94A_msbf_m1_13_generation_reconciliation_reconstructed_v0_2.sql`; referenced bytes not established here)

Use only when program 94 commits successfully but DBeaver loses or closes its result tab.

Required:

```text
generation_reconciliation_status = PASS
```

---

# Validation framework

M1.13 includes:

```text
82 positive controls
7 negative controls
20 detailed evidence result sets
```

The positive controls cover:

- every accepted predecessor gate;
- every accepted upstream hash;
- accepted M1.6 scenario-set scoping;
- exact application and scenario coverage;
- 30/60/90-day path cardinality;
- unique daily path grain;
- initial, ending, and average exposure identities;
- terminal zero-exposure enforcement;
- scheduled-payment and paydown arithmetic;
- early/middle/late timing-weight reconciliation;
- path-weighted EAD and EAD-rate identities;
- industry LGD assumptions;
- collateral and guarantee recovery credits;
- LGD floor and cap bounds;
- recovery-evidence status and conflict routing;
- simple and schedule-adjusted comparative-loss identities;
- comparative-loss-rate identity;
- blocked-evidence behavior;
- manual-review and reason routing;
- matched stress payment, EAD, LGD, and loss non-improvement;
- row hashes and all three set hashes;
- no-future-data controls;
- strict downstream stage boundaries;
- zero blocking configuration errors.

The negative controls prove fail-closed rejection of:

```text
Disabled M1.13 generation
Unapproved M1.13 policy
Invalid methodology basis
Invalid default-timing-weight sum
Unapproved accepted stress scenario
Prerequisite run-status drift
Attempted post-generation rerun
```

Open the validation matrix (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/docs/M1_13_VALIDATION_MATRIX.md`; referenced bytes not established here)

---

# Evidence to retain

Structured CSV exports are sufficient. Execution logs remain optional unless diagnosing a defect.

Retain:

```text
92 schema and policy checkpoint
93 preflight result
94 generation checkpoint
95 positive-validation result
96 negative-control result
97 acceptance-finalizer result
98 one-row master report
99 all twenty detailed-report result sets
completed M1.13 acceptance milestone
```

In program 99, these result sets must preserve their headers and contain zero rows:

```text
19 — Row-Level Deterministic Mismatches
20 — Blocking Resolution Errors
```

Open the evidence instructions (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/evidence/README.md`; referenced bytes not established here)

Open the acceptance-milestone template (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/evidence/templates/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_Build_Acceptance_Milestone_v0_2_template.txt`; referenced bytes not established here)

---

# Documentation and catalogs

- Package README (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/README.md`; referenced bytes not established here)
- Architecture diagram (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/diagrams/M1_13_ARCHITECTURE.png`; referenced bytes not established here)
- Design and generation specification (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/docs/M1_13_DESIGN_AND_GENERATION_SPECIFICATION.md`; referenced bytes not established here)
- Parameter dictionary — Markdown (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/docs/M1_13_PARAMETER_DICTIONARY.md`; referenced bytes not established here)
- Parameter dictionary — CSV (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_PARAMETER_DICTIONARY.csv`; referenced bytes not established here)
- Governed parameter values (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_PARAMETER_VALUES.csv`; referenced bytes not established here)
- Feature dictionary (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_FEATURE_DICTIONARY.csv`; referenced bytes not established here)
- Field dictionary (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_FIELD_DICTIONARY.csv`; referenced bytes not established here)
- Expected results (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_EXPECTED_RESULTS.json`; referenced bytes not established here)
- Run configuration (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_RUN_CONFIGURATION.json`; referenced bytes not established here)
- Execution-order catalog (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_EXECUTION_ORDER.csv`; referenced bytes not established here)
- Physical dependency catalog (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_PHYSICAL_DEPENDENCY_COLUMNS.csv`; referenced bytes not established here)
- Release notes (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/RELEASE_NOTES.md`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Deep static audit (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/catalogs/M1_13_DEEP_STATIC_AUDIT.json`; referenced bytes not established here)
- Final build report (historical reference: `sandbox:[session]/MSBF_M1_13_FINAL_BUILD_REPORT.json`; referenced bytes not established here)

---

# Static package validation

The completed package passed all defined static controls:

```text
Controlled SQL files                          10
SQL source lines                           4,272
Positive validation controls                  82
Negative controls                               7
Detailed-report result sets                    20

Expected applications                         750
Expected scenarios                              2
Expected snapshots                          1,500
Expected current-portfolio path rows        93,720
Expected canonical entities                95,220

Designed parent tables added                    2
Designed columns added                         69
Projected parent tables                        80
Projected designed columns                  1,427

Schema tables parsed                           80
Persistent INSERT statements checked           14
Persistent UPDATE statements checked           10
Invalid persistent DML target columns           0
Major INSERT / SELECT shape differences         0

SQL lexical-balance errors                      0
Session-level random() calls                     0
Destructive accepted-data operations             0
Upstream blueprint-regeneration paths            0
Standalone helper SELECT result sets             0
Scalar md5/FILTER syntax defects                  0
Unsafe whole-row hash references                 0
Invalid dependency columns                       0
Static errors                                    0
Static warnings                                  0
```

## Archive validation

### Standalone package

```text
Files                              46
CRC validation                     PASS
Complete extraction                PASS
Inventory reconciliation           PASS
Extracted-file hash comparison     PASS
ZIP64                              Not used
Longest internal path              118 characters
```

### Full project repository

```text
Files                           1,450
CRC validation                     PASS
Complete extraction                PASS
Inventory reconciliation           PASS
Extracted-file hash comparison     PASS
ZIP64                              Not used
Longest internal path              180 characters
```

A PostgreSQL server was unavailable in the build environment. Static validation cannot establish live runtime, query-plan behavior, transactional execution, resulting exposure/LGD/loss distributions, or formal M1.13 acceptance.

---

# Next stage after M1.13 acceptance

The planned next module is:

> **M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations**

M1.14 will combine accepted M1.13 exposure, recovery, LGD, and comparative-loss evidence with requested funding economics to create:

- gross finance-charge and revenue foundations;
- funding, processor, servicing, and operating-cost assumptions;
- comparative expected-loss burden;
- contribution before and after comparative loss;
- scenario-aware risk-adjusted return measures;
- hurdle-rate and economic-review indicators.

It will remain separate from final pricing and offer decisions.

Open the M1.14 handoff plan (historical reference: `sandbox:[session]/build_m1_13/module/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_v0_2/NEXT_STEP_M1_14_UNIT_ECONOMICS_RISK_ADJUSTED_CONTRIBUTION.md`; referenced bytes not established here)

The controlled progression is now:

```text
G0 Physical Foundation
PASS

→

G1 Governed Run Control
PASS

→

M1.2–M1.12
PASS

→

M1.13 Exposure, Recovery & Expected Loss Foundations
READY FOR LIVE EXECUTION

→

M1.14 Unit Economics & Risk-Adjusted Contribution
PENDING M1.13 ACCEPTANCE
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-7775ff3e-dfb2-4cf8-b5f2-f4e88127cca2"></a>
## Andrew / user · C068-M00294

C068-M00294 · 2026-07-26T20:16:31.021000-04:00 · active path

Preceding visible parent: [C068-M00293](part-22.md#m-35b093d4-ed20-485b-a704-51ccabf38e34)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(161).png; 93_msbf_m1_13_preflight_validation_v0_2_results_20260726.csv; 92_msbf_m1_13_schema_policy_extension_v0_2_results_20260726.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 94_msbf_m1_13_exposure_recovery_loss_generation_v0_2.sql:
<!-- END_SOURCE_MESSAGE -->


<a id="m-4e3c51ec-f8b0-4444-804a-291d71aea033"></a>
## Assistant · C068-M00295

C068-M00295 · 2026-07-26T20:32:00.520477-04:00 · active path

Preceding visible parent: [C068-M00294](part-22.md#m-7775ff3e-dfb2-4cf8-b5f2-f4e88127cca2)

<!-- BEGIN_SOURCE_MESSAGE -->
# Diagnosis

The M1.13 preflight and schema extension both passed. Program 94 failed because PostgreSQL does not implement:

```sql
max(boolean)
```

The generation script used that unsupported aggregate to resolve these two governed Boolean parameters:

```text
simple_el_publish_flag
schedule_adjusted_el_publish_flag
```

The corrected expressions use PostgreSQL’s Boolean aggregate:

```sql
bool_or((resolved_value ->> 'value_boolean')::boolean)
    FILTER (WHERE ...)
```

Preflight and the generation guard require exactly one typed row for each parameter, so this preserves the intended value without changing any business logic.

The error occurred while building `_m1_13_global_params`, before M1.13 path rows, loss snapshots, hashes, evidence, or run-state changes were persisted.

## Immediate DBeaver action

Click **Stop**. Do not select Retry, Skip, or Skip All.

Then execute:

```sql
ROLLBACK;
```

Do not rerun program 92. Its schema and policy changes committed successfully:

```text
ead_path_table_exists       true
loss_snapshot_table_exists  true
lineage_view_exists         true
active_feature_definitions  10
policy_status               APPROVED
schema extension status     PASS
```

Your original program 93 preflight also passed with the correct expected population:

```text
run_status          M1_12_ACCEPTED
applications        750
scenarios           2
expected_path_rows  93,720
preflight_status    PASS
```

---

# M1.13 v0.2R1 consolidated hotfix

Download the complete M1.13 v0.2R1 Boolean Parameter Aggregation Hotfix (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix.zip`; referenced bytes not established here)

Download the ZIP SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
6e75f363cb7e8b80bfc218481cb391178ea3a77008ad4e86c979965bf65f1228

Files
17
```

## Primary corrected files

- 92B — Failed-generation recovery check (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/tests/92B_msbf_m1_13_failed_boolean_aggregate_recovery_check_v0_2R1.sql`; referenced bytes not established here)
- 93 — Version-aligned preflight (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/tests/93_msbf_m1_13_preflight_validation_v0_2R1.sql`; referenced bytes not established here)
- 94 — Corrected generation (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/sql/94_msbf_m1_13_exposure_recovery_loss_generation_v0_2R1.sql`; referenced bytes not established here)
- 95 — Positive validation (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/sql/95_msbf_m1_13_exposure_recovery_loss_validation_v0_2R1.sql`; referenced bytes not established here)
- 96 — Negative controls (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/sql/96_msbf_m1_13_negative_control_tests_v0_2R1.sql`; referenced bytes not established here)
- 97 — Acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/sql/97_msbf_m1_13_acceptance_finalize_v0_2R1.sql`; referenced bytes not established here)
- 98 — Master report (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/tests/98_MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2R1.sql`; referenced bytes not established here)
- 99 — Detailed report (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/tests/99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1.sql`; referenced bytes not established here)

Supporting records:

- Hotfix notes (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/HOTFIX_NOTES_v0_2R1.md`; referenced bytes not established here)
- Execution guide (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/docs/M1_13_v0_2R1_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)
- Manifest (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/MANIFEST.csv`; referenced bytes not established here)
- Internal SHA-256 inventory (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/SHA256SUMS.txt`; referenced bytes not established here)

---

# Exact recovery and execution sequence

## 1. Confirm rollback state

Run:

```text
92B_msbf_m1_13_failed_boolean_aggregate_recovery_check_v0_2R1.sql
```

Required result:

```text
run_status                               M1_12_ACCEPTED
path_rows                                0
snapshot_rows                            0
evidence_rows                            0
gate_rows                                0
blocking_errors                          0
path_table_exists                        true
snapshot_table_exists                    true
approved_policy_exists                   true
simple_flag_rows                         1
schedule_flag_rows                       1
recovery_state_status                    PASS
```

Stop if this result is not `PASS`.

## 2. Rerun the version-aligned preflight

Run:

```text
93_msbf_m1_13_preflight_validation_v0_2R1.sql
```

Required:

```text
preflight_status = PASS
```

## 3. Run corrected generation

Run:

```text
94_msbf_m1_13_exposure_recovery_loss_generation_v0_2R1.sql
```

Required checkpoint:

```text
run_status                M1_13_GENERATED
path_rows                 93,720
snapshot_rows              1,500
applications                 750
scenarios                      2
expected canonical rows    95,220
actual canonical rows      95,220
row-level mismatches            0
generation_status              PASS
```

After program 94 commits successfully, do not rerun it.

## 4. Complete the R1 sequence

Run:

```text
95_msbf_m1_13_exposure_recovery_loss_validation_v0_2R1.sql

96_msbf_m1_13_negative_control_tests_v0_2R1.sql

97_msbf_m1_13_acceptance_finalize_v0_2R1.sql

98_MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2R1.sql

99_MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1.sql
```

Expected final results:

```text
Positive validations       82 / 82 PASS
Negative controls            7 / 7 PASS
Deterministic mismatches             0
Blocking errors                      0
Acceptance gate                    PASS
Run status                M1_13_ACCEPTED
Master report                       PASS
```

Program 99 must produce 20 result sets. These two must contain headers and zero data rows:

```text
19 — Row-Level Deterministic Mismatches
20 — Blocking Resolution Errors
```

## Contingency-only program

94A — Generation reconciliation reconstruction (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_Boolean_Parameter_Aggregation_Hotfix/tests/94A_msbf_m1_13_generation_reconciliation_reconstructed_v0_2R1.sql`; referenced bytes not established here) is not part of the normal sequence.

Use it only if corrected program 94 commits successfully but DBeaver loses or closes the generation result tab.

---

# Consolidated downstream audit

I reviewed the full program-94-through-99 path rather than changing only the first failing line.

The R1 package confirms:

```text
Unsupported max(boolean) expressions remaining       0
Governed bool_or Boolean aggregations present         4
Positive validation controls                         82
Negative controls                                      7
Detailed-report result sets                           20
Downstream files logic-equivalent to v0.2          6 / 6
Static package status                                PASS
ZIP CRC and complete extraction                     PASS
```

Only program 94 has an executable correction:

1. Two unsupported `max(boolean)` aggregates became `bool_or(boolean)`.
2. The guarantee-capacity aggregate was parenthesized before its numeric cast for parser clarity.

No exposure-path, EAD, LGD, recovery-credit, comparative-loss, routing, threshold, cardinality, hash, validation, or acceptance formula changed. Programs 93 and 95–99 are version-aligned copies whose comment/whitespace-normalized executable logic matches the original v0.2 source exactly.

Retain the original error screenshot and the original successful 92/93 exports with the R1 evidence. This documents the pre-commit defect and controlled recovery without suggesting that accepted upstream data was regenerated.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f6e03a2f-7d02-40ac-9863-cdde92fdf738"></a>
## Andrew / user · C068-M00296

C068-M00296 · 2026-07-26T20:58:33.738000-04:00 · active path

Preceding visible parent: [C068-M00295](part-22.md#m-4e3c51ec-f8b0-4444-804a-291d71aea033)

**Editorial record note:** Attachment references: MSBF_M1_13_Exposure_Recovery_Loss_Master_Report_v0_2R1_20260726.csv; 97_msbf_m1_13_acceptance_finalize_v0_2R1_results_20260726.csv; 96_msbf_m1_13_negative_control_tests_v0_2R1_results_20260726.csv; 95_msbf_m1_13_exposure_recovery_loss_validation_v0_2R1_results_20260726.csv; 94_msbf_m1_13_exposure_recovery_loss_generation_v0_2R1_results_20260726.csv; 93_msbf_m1_13_preflight_validation_v0_2R1_results_20260726.csv; 92B_msbf_m1_13_failed_boolean_aggregate_recovery_check_v0_2R1_results_20260726.csv; 93_msbf_m1_13_preflight_validation_v0_2_results_20260726(1).csv; 92_msbf_m1_13_schema_policy_extension_v0_2_results_20260726(1).csv

<!-- BEGIN_SOURCE_MESSAGE -->
Here is the batch 1 of 2 for M1.13 execution evidence. Do not do anything but intake at this point until after I issue batch 2 of 2 and further instructions. In this prompt though, I would like you to briefly mention the remaining M1.## modules left.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7a801459-bfa9-4da8-92bc-b73895aec187"></a>
## Assistant · C068-M00297

C068-M00297 · 2026-07-26T21:02:19.966755-04:00 · active path

Preceding visible parent: [C068-M00296](part-22.md#m-f6e03a2f-7d02-40ac-9863-cdde92fdf738)

<!-- BEGIN_SOURCE_MESSAGE -->
Received batch 1 of 2 for M1.13, including:

- Program 92 schema and policy extension
- Original and v0.2R1 program 93 preflight results
- Program 92B recovery check
- Program 94 v0.2R1 generation
- Program 95 positive validation
- Program 96 negative controls
- Program 97 acceptance finalizer
- Program 98 master report

I will not analyze the evidence, determine acceptance, or update the repository until batch 2 and your further instructions.

## Remaining Module 1 roadmap

Based on the revised build sequence, three substantive M1 modules remain after M1.13:

1. **M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations**  
   Revenue, funding costs, servicing and operating costs, comparative-loss burden, contribution, risk-adjusted return, and economic hurdle evidence.

2. **M1.15 — Latest Output, Archive, Comparison & Consumption Contract**  
   Final persistent Module 1 outputs, latest-versus-archive controls, matched scenario comparison, governed contract rows, versioning, and downstream consumption readiness.

3. **M1.16 — End-to-End QA, Evidence & G2 Contract Acceptance**  
   Full-population reconciliation, reproducibility, scenario matching, output-contract validation, final evidence package, and the formal G2 Module 1 acceptance gate.

That places the project very near completion of the full Module 1 foundation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-73d42d8e-b16f-4107-a75a-45cfef779bfb"></a>
## Andrew / user · C068-M00298

C068-M00298 · 2026-07-26T21:07:03.912000-04:00 · active path

Preceding visible parent: [C068-M00297](part-22.md#m-7a801459-bfa9-4da8-92bc-b73895aec187)

**Editorial record note:** Attachment references: MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_M1_13_Governed_Evidence_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Sample_Matched_Application_Profiles_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Relationship_Stage_And_Merchant_Size_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Partner_Channel_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Review_Fallback_And_Reason_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Matched_Stress_Migration_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Comparative_Loss_Summary_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Loss_Evidence_Status_Distribution_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Integrated_Risk_Tier_And_Loss_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Collateral_And_Guarantee_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Recovery_Evidence_And_Basis_Distribution_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Industry_EAD_LGD_And_Comparative_Loss_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Payoff_Horizon_And_Paydown_Curve_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Default_Timing_Bucket_Diagnostics_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Exposure_Path_Summary_By_Scenario_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Governed_Methodology_And_Frozen_Parameters_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Entity_And_Stage_Boundary_Row_Counts_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Run_And_Acceptance_State_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Blocking_Resolution_Errors_20260726.csv; MSBF_M1_13_Exposure_Recovery_Loss_Detail_Report_v0_2R1_Row_Level_Deterministic_Mismatches_20260726.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Remainder of M1.13 evidence. Validate M1.13 is a success. If it is approved, sign off M1.13 and update full project zip.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a5f4e085-8034-4c0d-8a1f-5ec7b014975f"></a>
## Assistant · C068-M00299

C068-M00299 · 2026-07-26T21:27:18.825615-04:00 · active path

Preceding visible parent: [C068-M00298](part-22.md#m-73d42d8e-b16f-4107-a75a-45cfef779bfb)

<!-- BEGIN_SOURCE_MESSAGE -->
# M1.13 final determination: **Passed and accepted**

I reviewed the complete M1.13 evidence set, including:

- the v0.2 schema and policy extension;
- the original successful preflight;
- the initial pre-commit Boolean-aggregation failure;
- the v0.2R1 recovery-state validation;
- the corrected v0.2R1 generation;
- all 82 positive controls;
- all seven negative controls;
- the acceptance finalizer;
- the master report;
- all 20 detailed-report exports;
- the empty deterministic-mismatch and blocking-resolution-error results.

The evidence supports formal acceptance of:

> **M1.13 — Exposure, Recovery & Expected Loss Foundations**  
> **Accepted package revision:** `v0.2R1`  
> **Schema and policy revision:** `v0.2`  
> **Recovery through reporting revision:** `v0.2R1`  
> **Methodology:** `M1_13_METHOD_V1`

## Acceptance results

| Validation area | Final result | Disposition |
|---|---:|---|
| Final run status | `M1_13_ACCEPTED` | Pass |
| Acceptance gate | `M1_13_EXPOSURE_RECOVERY_LOSS_FOUNDATIONS — PASS` | Pass |
| Applications | 750 | Pass |
| Matched scenarios | 2 | Pass |
| Daily EAD-path rows | 93,720 | Pass |
| Exposure/recovery/loss snapshots | 1,500 | Pass |
| Canonical entities | 95,220 | Pass |
| Positive validations | 82 of 82 PASS | Pass |
| Negative controls | 7 of 7 PASS | Pass |
| Row-level deterministic mismatches | 0 | Pass |
| EAD identity violations | 0 | Pass |
| Recovery identity violations | 0 | Pass |
| Comparative-loss identity violations | 0 | Pass |
| Stress EAD improvements | 0 | Pass |
| Stress LGD improvements | 0 | Pass |
| Stress comparative-loss improvements | 0 | Pass |
| Downstream stage-boundary rows | 0 | Pass |
| Blocking resolution errors | 0 | Pass |
| Master report | `overall_m1_13_status = PASS` | Pass |

The deterministic-mismatch and blocking-resolution-error files contain their required headers and zero data rows.

## Deterministic reconciliation

The persisted and independently reconstructed hashes match exactly:

```text
Daily exposure-path set
97fa026a0c3cb5ae8584e98cd0a34555

Exposure/recovery/loss snapshot set
6a6eca57842eeaf5bf3be775cdfda754

Combined M1.13 canonical set
11dca65763f4062ad9002244ee6452f9
```

All accepted upstream identities also remained unchanged:

```text
Population hash       9b706c926260a3ef1ae8ac95eed5d0bf
Application hash      01485256b9b5748fb412743d35ced602
Scenario-set hash     3f85921bf6fc30ddc6cee146085e58c5
Capacity-set hash     a91e82a315305a98953d013043a17d9a
Integrated-risk hash  fb583c3fdd92f141ba5af1ddf942ffba
```

## Accepted synthetic portfolio evidence

```text
Average initial contractual exposure        $30,333.38
Average path-weighted EAD                    $15,420.30
Average expected EAD rate                    46.5160%
Average recovery-rate assumption             30.8757%
Average LGD input rate                        69.1243%

Total simple comparative loss                $6,439,459.43
Total schedule-adjusted comparative loss     $3,259,257.56

Partial evidence rows                        902
Blocked evidence rows                        598
Parameter-only recovery rows                 770
Recovery-conflict rows                       730
Manual-review rows                           1,486
Hard-stop rows                               234
```

No application had supported collateral or guarantee recovery evidence in this synthetic campaign. Recovery credit therefore remained zero, and the 1,500 snapshots were classified as either `PARTIAL` or `BLOCKED`, rather than `COMPLETE`. That limitation remains explicit instead of creating unsupported recovery value.

The adverse scenario produced:

```text
Path-weighted EAD worsenings     331
LGD worsenings                   750
Comparative-loss worsenings      312

EAD improvements                   0
LGD improvements                   0
Comparative-loss improvements      0
```

One interpretation point is important: the published aggregate schedule-adjusted comparative-loss total is lower under stress—approximately **$1.37 million**, versus **$1.89 million** at baseline—because stress evidence gating reduces published scored rows from **590 to 312**. It does not represent an improved matched risk result. The row-level non-improvement controls all passed.

## Correction history

The initial v0.2 generation stopped before persistent output because PostgreSQL does not support `max(boolean)`. The v0.2R1 source replaced the two Boolean parameter aggregations with governed `bool_or(boolean)` expressions.

The recovery evidence confirmed before the corrected generation:

```text
M1.13 path rows       0
M1.13 snapshot rows   0
M1.13 evidence rows   0
M1.13 gate rows       0
Blocking errors       0
```

I also completed a SQL-aware comparison of programs 93 and 95–99. After removing comments and whitespace while preserving executable tokens, all six downstream programs were logic-equivalent to their v0.2 sources. The only executable correction was in program 94.

> **M1.13 is formally passed and accepted. M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations is authorized.**

---

# Updated full project repository

## Recommended Windows-compatible delivery

Download MSBF Project v0.2 — M1.13 Complete FINAL (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_13_COMPLETE_FINAL_Windows.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_13_COMPLETE_FINAL_Windows.zip.sha256`; referenced bytes not established here)

```text
SHA-256
2b2abda0738bf71ee20e23b2f9f661311fbb4a18f0a320ab4aacbe50ba5886cf

Archive size
9,188,026 bytes

Archive entries
1,566

Maximum internal path
180 characters
```

The archive passed:

```text
CRC validation                       PASS
Complete extraction                  PASS
Source / ZIP inventory match         PASS
Missing or extra files               0
Extracted-file hash mismatches       0
Windows/DOS ZIP metadata             PASS
ZIP64                                Not used
```

Extract close to the drive root, preferably:

```text
C:\MSBF\
```

## Canonical full-project filename

Download the canonical M1.13-complete project ZIP (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M1_13_COMPLETE_FINAL.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M1_13_COMPLETE_FINAL.zip.sha256`; referenced bytes not established here)

The canonical and Windows-compatible project archives are byte-identical.

## Standalone accepted M1.13 package

Download the standalone M1.13 v0.2R1 Complete package (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_COMPLETE_FINAL.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M1_13_v0_2R1_COMPLETE_FINAL.zip.sha256`; referenced bytes not established here)

```text
SHA-256
1af4f32440825a7e15cc4ea87974eeedff0050bc6eb6533476f2465db81bff6a

Archive size
570,610 bytes

Archive entries
156
```

Download the canonical standalone M1.13 package (historical reference: `sandbox:[session]/merchant_sales_based_financing_m1_13_exposure_recovery_expected_loss_foundations_v0_2R1_COMPLETE_FINAL.zip`; referenced bytes not established here)

---

# Key acceptance records

- Formal M1.13 evidence review and sign-off (historical reference: `sandbox:[session]/M1_13_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF.md`; referenced bytes not established here)
- Completed M1.13 acceptance milestone (historical reference: `sandbox:[session]/MSBF_M1_13_Exposure_Recovery_Expected_Loss_Foundations_Build_Acceptance_Milestone_v0_2R1.txt`; referenced bytes not established here)
- Machine-readable M1.13 validation summary (historical reference: `sandbox:[session]/M1_13_LIVE_EXECUTION_VALIDATION_SUMMARY_v0_2R1.json`; referenced bytes not established here)
- M1.13 evidence index (historical reference: `sandbox:[session]/M1_13_EVIDENCE_INDEX.md`; referenced bytes not established here)
- M1.13 validation and correction history (historical reference: `sandbox:[session]/M1_13_VALIDATION_HISTORY.md`; referenced bytes not established here)
- v0.2R1 logic-equivalence review (historical reference: `sandbox:[session]/M1_13_v0_2R1_LOGIC_EQUIVALENCE_REVIEW.md`; referenced bytes not established here)
- Updated project status (historical reference: `sandbox:[session]/PROJECT_STATUS_M1_13_COMPLETE.md`; referenced bytes not established here)
- M1.14 authorized-stage handoff (historical reference: `sandbox:[session]/CURRENT_NEXT_STEP_M1_14_UNIT_ECONOMICS_RISK_ADJUSTED_CONTRIBUTION.md`; referenced bytes not established here)
- Final archive and package-build report (historical reference: `sandbox:[session]/MSBF_M1_13_COMPLETE_BUILD_REPORT.json`; referenced bytes not established here)

The governed progression is now:

```text
G0 Physical Foundation
PASS

→

G1 Governed Run Control
PASS

→

M1.2–M1.12
PASS

→

M1.13 Exposure, Recovery & Expected Loss Foundations
PASS

→

M1.14 Unit Economics & Risk-Adjusted Contribution Foundations
AUTHORIZED
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-7c9d3e13-ad70-40d0-ba4d-13cf478e79d8"></a>
## Andrew / user · C068-M00300

C068-M00300 · 2026-07-26T21:28:17.704000-04:00 · active path

Preceding visible parent: [C068-M00299](part-22.md#m-a5f4e085-8034-4c0d-8a1f-5ec7b014975f)

<!-- BEGIN_SOURCE_MESSAGE -->
Build M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations as a complete governed module. Use the accepted M1.13 repository as the baseline. Produce architecture, schema changes, parameter dictionary, preflight, generation, validation, negative controls, acceptance, master report, detail reports, documentation, manifest, SHA-256, and updated full-project ZIP. Apply the error resolution lessons, comment/header/format lessons, and performance lessons from prior modules proactively: no unnecessary blueprint regeneration, materialize expensive intermediates once, avoid self-joins where window functions suffice, index and ANALYZE before downstream joins, separate persisted generation from read-only validation, and include recovery behavior. Do not stop for interim design approval unless a material ambiguity would change the module’s business purpose.
<!-- END_SOURCE_MESSAGE -->
