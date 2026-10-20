# Merchant POS Lending Simulator

Part 35 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-34.md)
[Next part](part-36.md)

<a id="m-8bc9b997-52e5-456b-8f7d-39d159ef65fc"></a>
## Assistant · C068-M00445

C068-M00445 · 2026-08-01T17:52:46.672993-04:00 · active path

Preceding visible parent: [C068-M00444](part-34.md#m-8367dc79-d3a1-4898-bc92-a66fd0ef3509)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.5 — Daily Remittance, Exposure & Portfolio Monitoring

M2.5 is built, statically validated, integrated into the accepted M2.4 repository, and packaged for controlled PostgreSQL execution.

**Current status:** `READY_FOR_LIVE_EXECUTION`  
**Formal M2.5 acceptance:** Pending successful execution of Programs 164–171 and review of the resulting evidence.

## Primary delivery — updated full project

Download MSBF Project v0.2 — M2.5 Ready for Execution (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M2_5_READY_FOR_EXECUTION_Windows.zip`; referenced bytes not established here)

Download the full-project SHA-256 file (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M2_5_READY_FOR_EXECUTION_Windows.zip.sha256`; referenced bytes not established here)

```text
SHA-256
8609524510d42a5830cca0f300f04c5ffcee94213b32d0f45cdccb614c666ad5

Archive size
16,528,013 bytes

Archive files
3,538

Maximum internal path
223 characters
```

Canonical byte-identical copy:

Download the canonical M2.5-ready full project (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M2_5_READY_FOR_EXECUTION.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M2_5_READY_FOR_EXECUTION.zip.sha256`; referenced bytes not established here)

For Windows, extract near the drive root:

```text
C:\MSBF\
```

## Standalone M2.5 package

Download MSBF M2.5 v0.2 (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2.zip`; referenced bytes not established here)

Download the standalone SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2.zip.sha256`; referenced bytes not established here)

```text
SHA-256
13d68cc126daa0e0ae74b3d05bd8f9115b9aea59333b23a92acdf1c0edc46bfe

Archive size
256,907 bytes

Archive files
80

Maximum internal path
136 characters
```

Canonical byte-identical copy:

Download the canonical standalone M2.5 package (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_5_daily_remittance_exposure_portfolio_monitoring_v0_2.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_5_daily_remittance_exposure_portfolio_monitoring_v0_2.zip.sha256`; referenced bytes not established here)

## Build and validation records

- Complete package-build report (historical reference: `sandbox:[session]/MSBF_M2_5_PACKAGE_BUILD_REPORT.json`; referenced bytes not established here)
- Complete delivery-validation report (historical reference: `sandbox:[session]/M2_5_COMPLETE_DELIVERY_VALIDATION.json`; referenced bytes not established here)
- Delivery index (historical reference: `sandbox:[session]/M2_5_DELIVERY_INDEX.md`; referenced bytes not established here)
- Final delivery summary (historical reference: `sandbox:[session]/M2_5_FINAL_DELIVERY_SUMMARY.md`; referenced bytes not established here)

---

# Governed business purpose

M2.5 consumes two accepted evidence boundaries:

```text
M2.4 portfolio activation
+
M1.6 matched POS and deposit scenario history
```

It answers:

> **How are activated advances remitting each day, how is receivable exposure changing, and which internal portfolio-monitoring conditions are present?**

M2.5 creates:

- a governed companion for the 59 activated M2.4 scenario/application records;
- a deterministic 120-day monitoring replay;
- daily expected and actual remittance evidence;
- cumulative collection pace and shortfall;
- remaining receivable exposure;
- principal-exposure and unearned-finance-charge proxies;
- trailing seven-day and thirty-day remittance;
- zero-sales and no-remittance streaks;
- accepted deposit-liquidity context;
- six governed monitoring statuses;
- seven internal monitoring alerts;
- latest and immutable archive contracts;
- daily portfolio summaries;
- matched baseline/stress diagnostics;
- Power BI consumption and lineage views.

## Source population

```text
Activated M2.4 source rows                  59
Baseline activated rows                     44
Recession / energy activated rows           15
Distinct applications                       44

Monitoring days per activated row          120
Daily monitoring rows                    7,080

Latest rows                                  59
Immutable archive rows                       59
Portfolio daily summary rows                240
Matched baseline/stress comparisons          15
Canonical entities                        7,536
```

The 15 matched comparisons represent applications activated in both baseline and recession/energy scenarios.

---

# Certified source boundaries

## Accepted M2.4 contract

```text
Contract
M2_PORTFOLIO_ACTIVATION_CONSUMPTION v1

Schema
M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1

Combined hash
117450a3eea7bb3d3c74d18cc3c8e96a

Acceptance gate
M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION
```

## Accepted M1.6 history

```text
Acceptance gate
M1_6_MATCHED_SCENARIO_OVERLAYS

Governed combined-hash evidence
M1_6_COMBINED_SET_HASH

Accepted POS daily rows
270,000

Accepted deposit daily rows
270,000
```

The accepted M1.6 combined hash is resolved dynamically from governed run evidence rather than being guessed or hard-coded.

The full project was derived from:

```text
MSBF_Project_v0_2_M2_4_COMPLETE_FINAL_Windows.zip

Accepted SHA-256
d710885f9dbd5ffb5ed85be1c69d133a5300619da4e2ef6a36b67072a79ca3ec
```

---

# Governed identities

```text
Methodology
M2_5_METHOD_V1

Policy
M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING_POLICY_V1

Consumption contract
M2_DAILY_REMITTANCE_EXPOSURE_MONITORING_CONSUMPTION v1

Schema
M2_5_DAILY_REMITTANCE_EXPOSURE_SCHEMA_V1

Acceptance gate
M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING
```

# Monitoring methodology

## Six governed statuses

| Rank | Monitoring status | Interpretation |
|---:|---|---|
| 0 | `PAID_OFF` | Receivable balance has reached zero |
| 1 | `CURRENT` | Remittance pace remains within the current band |
| 2 | `WATCH` | Early or moderate deterioration requires monitoring |
| 3 | `UNDERPERFORMING` | Material cumulative underperformance is present |
| 4 | `SEVERE_SHORTFALL` | Severe shortfall, zero-sales streak or horizon overrun is present |
| 5 | `DORMANT_NO_REMITTANCE` | No positive remittance has occurred for the governed dormant interval |

## Seven governed alerts

```text
DAILY_COLLECTION_SHORTFALL
CUMULATIVE_PACE_BELOW_90
CUMULATIVE_PACE_BELOW_75
ZERO_SALES_STREAK
LIQUIDITY_STRESS
CONTRACT_HORIZON_OVERRUN
STRESS_STATUS_FLOOR
```

## Core policy thresholds

```text
Monitoring horizon                         120 days
Accepted source replay                     120 days

Watch classification begins                 Day 7
Underperforming classification begins       Day 14
Severe classification begins                Day 14

Watch cumulative pace threshold             90%
Underperforming pace threshold               75%
Severe pace threshold                        50%

Daily coverage watch threshold               75%

Underperforming no-remittance interval        7 days
Dormant no-remittance interval               14 days
Severe zero-sales streak                     10 days

Low-liquidity available-balance threshold   $0.00
```

Open the parameter dictionary — Markdown (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_PARAMETER_DICTIONARY.md`; referenced bytes not established here)

Open the parameter dictionary — CSV (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_PARAMETER_DICTIONARY.csv`; referenced bytes not established here)

---

# Stage boundary

M2.5 is an **internal monitoring layer only**.

It does not create or authorize:

- a real debit instruction;
- ACH or payment-network transmission;
- merchant contact or collections action;
- a servicing action;
- write-off or charge-off;
- restructure or workout terms;
- an external notice;
- a production adverse-action notice;
- a legal or compliance conclusion.

The prohibited-payload assertion covers exact keys including:

```text
debit_instruction
real_debit_instruction
ach_trace_number
payment_network_confirmation
bank_account_number
routing_number
account_number
collection_action
servicing_action
write_off
charge_off
restructure_offer
workout_offer
external_notice
external_notice_payload
production_adverse_action_notice
production_adverse_action_notice_payload
```

All 24 monitoring reasons require:

```text
production_adverse_action_notice_flag = false
servicing_action_authorized_flag = false
```

---

# Physical architecture

M2.5 adds governed objects for:

```text
Policy, thresholds and accepted source identities
Monitoring-status dictionary
Monitoring-alert dictionary
Monitoring-reason dictionary

Activated-advance source snapshot

Daily remittance and exposure ledger
Latest portfolio-monitoring contract
Immutable monitoring archive
Scenario/day portfolio summary

Contract registry
Generation and validation evidence
Matched baseline/stress comparison
Lineage and Power BI consumption
Run-scoped canonical entity and hash views
```

Open the M2.5 architecture diagram (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/diagrams/M2_5_ARCHITECTURE.png`; referenced bytes not established here)

Open the scalable architecture SVG (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/diagrams/M2_5_ARCHITECTURE.svg`; referenced bytes not established here)

Open the architecture specification (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_ARCHITECTURE.md`; referenced bytes not established here)

---

# Exact execution sequence

Run against:

```text
msbf_strategy
```

Use DBeaver **Execute SQL Script**.

```text
164 → 165 → 166 → 167 → 168 → 169 → 170 → 171
```

| Order | Program | Required checkpoint |
|---:|---|---|
| 1 | 164 — Schema, policy, dictionaries, functions and views (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/164_msbf_m2_5_schema_policy_monitoring_contract_extension_v0_2.sql`; referenced bytes not established here) | `schema_policy_status = PASS` |
| 2 | 165 — Hard-stop preflight (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/165_msbf_m2_5_preflight_validation_v0_2.sql`; referenced bytes not established here) | `preflight_status = PASS` |
| 3 | 166 — Deterministic daily monitoring generation (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/166_msbf_m2_5_daily_remittance_exposure_generation_v0_2.sql`; referenced bytes not established here) | 7,536 canonical entities and zero mismatches |
| 4 | 167 — Positive validation (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/167_msbf_m2_5_daily_remittance_exposure_validation_v0_2.sql`; referenced bytes not established here) | 120 of 120 `PASS` |
| 5 | 168 — Negative controls (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/168_msbf_m2_5_negative_control_tests_v0_2.sql`; referenced bytes not established here) | 20 of 20 `PASS` |
| 6 | 169 — Acceptance finalizer (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/169_msbf_m2_5_acceptance_finalize_v0_2.sql`; referenced bytes not established here) | Run and contract accepted; gate `PASS` |
| 7 | 170 — Master report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/170_MSBF_M2_5_Master_Report_v0_2.sql`; referenced bytes not established here) | `overall_m2_5_status = PASS` |
| 8 | 171 — Detailed report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/171_MSBF_M2_5_Detail_Report_v0_2.sql`; referenced bytes not established here) | 24 result sets |

Open the complete execution and validation guide (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_EXECUTION_AND_VALIDATION_GUIDE.md`; referenced bytes not established here)

## Required Program 164 checkpoint

```text
policy_status                       APPROVED
acceptance_gate_catalog_rows        1
status_definition_rows              6
alert_definition_rows               7
reason_definition_rows             24
monitoring_horizon_days            120
source_replay_days                 120
schema_policy_status              PASS
```

## Required Program 165 checkpoint

```text
run_status                         M2_4_ACCEPTED

source M2.4 contract               ACCEPTED
source M2.4 combined hash          117450a3eea7bb3d3c74d18cc3c8e96a

M1.6 POS source rows               270,000
M1.6 deposit source rows           270,000

activated source rows                   59
baseline source rows                    44
stress source rows                      15
distinct applications                   44

minimum available POS days             ≥120
minimum available deposit days         ≥120

all M2.5 generated targets               0
preflight_status                       PASS
```

## Required Program 166 checkpoint

```text
run_status                         M2_5_GENERATED

policy_rows                                  1
status_rows                                  6
alert_rows                                   7
reason_rows                                 24

source_rows                                 59
daily_rows                               7,080
latest_rows                                 59
archive_rows                                59
portfolio_daily_rows                       240
comparison_rows                             15
registry_rows                                1

paid_off_rows + open_monitoring_rows        59

expected_canonical_entities              7,536
actual_canonical_entities                7,536
row_level_mismatches                         0
stress_status_improvements                   0

all governed set hashes                non-null
generation_status                         PASS
```

`paid_off_rows`, `open_monitoring_rows`, total remittance, ending exposure and stress-floor applications are execution-derived governed outputs rather than pre-imposed business results.

After Program 166 commits successfully, **do not rerun it**.

## Expected final sequence

```text
Program 167
120 / 120 positive controls PASS
run_status = M2_5_VALIDATED
contract_status = VALIDATED

Program 168
20 / 20 negative controls PASS

Program 169
acceptance_status = PASS
run_status = M2_5_ACCEPTED
contract_status = ACCEPTED
M2_5_DAILY_REMITTANCE_EXPOSURE_PORTFOLIO_MONITORING = PASS

Program 170
overall_m2_5_status = PASS

Program 171
24 governed result sets
```

The final two detailed-report outputs must retain their headers and contain zero data rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

---

# Recovery behavior

## Failed Program 164

Open Program 164A (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql`; referenced bytes not established here)

After executing:

```sql
ROLLBACK;
```

Program 164A verifies that the failed schema/policy transaction left no M2.5 objects or persisted rows.

## Failed or cancelled Program 166

Open Program 166A (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql`; referenced bytes not established here)

After:

```sql
ROLLBACK;
```

it requires all M2.5 generated tables, registry, evidence and acceptance rows to remain empty.

## Lost Program 166 result tab

Open Program 166B (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql`; referenced bytes not established here)

Program 166B is read-only and reconstructs the generation checkpoint after a successful commit.

Open the complete recovery guide (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_RECOVERY_GUIDE.md`; referenced bytes not established here)

---

# Validation framework

The module contains:

```text
Positive controls                   120
Negative controls                    20
Generation-evidence rows             24
Detailed-report result sets          24
Controlled SQL programs              11
SQL source lines                  10,274
```

Positive validation covers:

- accepted M2.4 lifecycle, gate, schema and canonical hash;
- accepted M1.6 gate, POS/deposit counts and combined hash;
- every M2.5 policy threshold and stage-boundary flag;
- status, alert and reason definitions;
- source, daily, latest, archive and portfolio-summary cardinality;
- all governed grains;
- daily remittance and receivable reconciliation;
- source and hash lineage;
- physical row hashes;
- all set hashes;
- registry and combined canonical identity;
- latest/archive reproduction;
- portfolio-summary reproduction;
- paid-off/open monitoring reconciliation;
- total-remittance and ending-exposure registry reconciliation;
- stress-status non-improvement;
- no servicing-action columns or reasons;
- absence of premature M2.6 objects.

Negative controls prove rejection of:

- invalid policy status;
- real-debit boundary drift;
- external-notice boundary drift;
- production adverse-action boundary drift;
- write-off/restructure boundary drift;
- monitoring-only boundary drift;
- prohibited reason flags;
- duplicate daily grain;
- negative remittance;
- actual remittance exceeding raw remittance;
- invalid receivable reconciliation;
- invalid monitoring status rank;
- archive updates and deletes;
- post-generation reruns;
- premature acceptance;
- accepted M2.4 hash drift;
- real-debit payloads;
- collections, write-off, restructure, external-notice and production-adverse-action payload vocabulary.

Open the validation matrix (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_VALIDATION_MATRIX.md`; referenced bytes not established here)

---

# Performance and coding-error prevention

The source was audited against the defect classes encountered in M1.17, M2.1, M2.2 and M2.3.

## Source materialization

```text
Accepted M2.4 latest source materialized once
Accepted M1.6 daily replay aggregated once
Expensive daily intermediates materialized once
Indexes created before downstream joins
ANALYZE executed before reconciliation
```

## Window-based processing

Window functions are used for:

```text
Cumulative remittance
Cumulative expected remittance
Trailing seven-day remittance
Trailing thirty-day remittance
Days since positive remittance
Zero-sales streaks
Receivable exposure progression
```

No unnecessary large self-join is used for cumulative calculations.

## Hash and type safety

```text
Target-typed staging before hashing
No invalid temporary hash placeholders
Physical field names used in identities
Expected and actual canonical universes reconstructed independently
Latest/archive payload reproduction
Run-scoped canonical hash
```

## SQL namespace and DBeaver safety

```text
No operational USING joins
No persistent INSERT SELECT *
Explicit persistent INSERT target lists
No ambiguous acceptance namespace
No session random()
No unsupported Boolean max/min
No scalar MD5/FILTER construction
No concatenated RAISE EXCEPTION syntax
No DBeaver-sensitive braced hash expressions
Full-table staging hash updates include WHERE predicates
```

## Header and comment standard

All 11 controlled SQL programs contain complete module, program, version and purpose headers. Larger programs contain explicit section-level navigation for source materialization, replay, window calculations, stress flooring, persistence, hashing, evidence, lifecycle and reporting.

Open the SQL engineering standards (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_SQL_ENGINEERING_STANDARDS.md`; referenced bytes not established here)

Open the completed SQL engineering audit (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_SQL_ENGINEERING_AUDIT.md`; referenced bytes not established here)

Open the package-validation report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# Additional documentation and catalogs

- Package README (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/README.md`; referenced bytes not established here)
- Design and generation specification (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_DESIGN_AND_GENERATION_SPECIFICATION.md`; referenced bytes not established here)
- Business and stage-boundary charter (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_BUSINESS_AND_STAGE_BOUNDARY_CHARTER.md`; referenced bytes not established here)
- Known limitations (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_KNOWN_LIMITATIONS.md`; referenced bytes not established here)
- Expected-results catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_EXPECTED_RESULTS.json`; referenced bytes not established here)
- Run configuration (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_RUN_CONFIGURATION.json`; referenced bytes not established here)
- Execution-order catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_EXECUTION_ORDER.csv`; referenced bytes not established here)
- Table and grain catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_TABLE_GRAIN_CATALOG.csv`; referenced bytes not established here)
- Field dictionary (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_FIELD_DICTIONARY.csv`; referenced bytes not established here)
- Status catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_STATUS_CATALOG.csv`; referenced bytes not established here)
- Alert catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_ALERT_CATALOG.csv`; referenced bytes not established here)
- Reason-code catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_REASON_CODE_CATALOG.csv`; referenced bytes not established here)
- Positive-control catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_POSITIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Negative-control catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_NEGATIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Source-provenance note (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_SOURCE_PROVENANCE_AND_PACKAGE_NOTE.md`; referenced bytes not established here)
- Module build report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/M2_5_FINAL_BUILD_REPORT.json`; referenced bytes not established here)
- M2.6 handoff (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/NEXT_STEP_M2_6_EARLY_WARNING_INTERVENTION_SERVICING_STRATEGY.md`; referenced bytes not established here)

---

# Package quality assurance

The standalone and full-project archives passed:

```text
ZIP CRC validation                    PASS
Complete extraction                   PASS
Archive inventory reconciliation      PASS
In-archive SHA-256 reconciliation     PASS
Extracted-file SHA-256 validation     PASS
Windows/DOS ZIP metadata              PASS
Standalone/embedded module identity   PASS
```

All 23 accepted predecessor numbered directories—from `01_Design` through `23_M2_4`—were preserved byte for byte.

A live PostgreSQL server was not available in the build environment. Static validation cannot establish final live distributions, execution-derived remittance totals, ending exposure, physical database planner behavior, final database hashes or formal M2.5 acceptance. Those require the governed execution and evidence-review sequence above.

# Current governed progression

```text
G0 Physical Foundation
PASS

→

G1 Governed Run Control
PASS

→

M1.2–M1.17
PASS

→

G2_M1_CONTRACT
PASS

→

M2.1 Eligibility, Policy Gates
& Decision Routing Foundations
PASS

→

M2.2 Pricing, Structure
& Counteroffer Foundations
PASS

→

M2.3 Final Offer
& Decision Authorization
PASS

→

M2.4 Booking, Funding
& Portfolio Activation
PASS

→

M2.5 Daily Remittance, Exposure
& Portfolio Monitoring
READY FOR LIVE EXECUTION

→

M2.6 Early Warning, Intervention
& Servicing Strategy
PENDING M2.5 ACCEPTANCE
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-edb3778d-9251-46e2-b2f1-a96678c019b2"></a>
## Assistant · C068-M00446

C068-M00446 · 2026-08-01T18:37:48.030831-04:00 · active path

Preceding visible parent: [C068-M00445](part-35.md#m-8bc9b997-52e5-456b-8f7d-39d159ef65fc)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.5 — Daily Remittance, Exposure & Portfolio Monitoring

M2.5 is **built, statically validated, integrated into the accepted M2.4 repository, and packaged for controlled PostgreSQL execution**.

```text
Current status       READY_FOR_LIVE_EXECUTION
Live execution       Not performed
Formal acceptance    Pending Programs 164–171 and evidence review
```

The build uses the formally accepted M2.4 repository:

```text
Baseline archive
MSBF_Project_v0_2_M2_4_COMPLETE_FINAL_Windows.zip

Accepted baseline SHA-256
d710885f9dbd5ffb5ed85be1c69d133a5300619da4e2ef6a36b67072a79ca3ec
```

## Primary delivery — updated full project

Download MSBF Project v0.2 — M2.5 Ready for Execution (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M2_5_READY_FOR_EXECUTION_Windows.zip`; referenced bytes not established here)

Download the full-project SHA-256 file (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M2_5_READY_FOR_EXECUTION_Windows.zip.sha256`; referenced bytes not established here)

Canonical byte-identical copy:

Download the canonical M2.5-ready project repository (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M2_5_READY_FOR_EXECUTION.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M2_5_READY_FOR_EXECUTION.zip.sha256`; referenced bytes not established here)

For Windows, extract near the drive root:

```text
C:\MSBF\
```

M2.5 is embedded under:

```text
24_M2_5
```

## Standalone M2.5 package

Download MSBF M2.5 v0.2 (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2.zip`; referenced bytes not established here)

Download the standalone SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2.zip.sha256`; referenced bytes not established here)

Canonical byte-identical copy:

Download the canonical standalone M2.5 package (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_5_daily_remittance_exposure_portfolio_monitoring_v0_2.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_5_daily_remittance_exposure_portfolio_monitoring_v0_2.zip.sha256`; referenced bytes not established here)

## Delivery and validation records

- Complete package-build report (historical reference: `sandbox:[session]/MSBF_M2_5_PACKAGE_BUILD_REPORT.json`; referenced bytes not established here)
- Complete delivery-validation report (historical reference: `sandbox:[session]/M2_5_COMPLETE_DELIVERY_VALIDATION.json`; referenced bytes not established here)
- Final artifact-verification report (historical reference: `sandbox:[session]/M2_5_FINAL_ARTIFACT_VERIFICATION.json`; referenced bytes not established here)
- Delivery index (historical reference: `sandbox:[session]/M2_5_DELIVERY_INDEX.md`; referenced bytes not established here)
- Final delivery summary (historical reference: `sandbox:[session]/M2_5_FINAL_DELIVERY_SUMMARY.md`; referenced bytes not established here)

The ZIPs passed CRC, complete extraction, inventory reconciliation, in-archive SHA-256 verification, extracted-file SHA-256 verification, and Windows metadata validation. The standalone M2.5 tree and the embedded `24_M2_5` tree are byte-identical. All accepted predecessor stages were preserved byte for byte.

---

# Governed business purpose

M2.4 created the accepted synthetic active portfolio:

```text
Activated scenario/application records       59

Baseline activations                         44
Recession / energy activations               15
```

M2.5 answers:

> **How should those active advances be monitored each day for remittance performance, balance run-off, emerging shortfall, exposure concentration, and portfolio-level risk signals?**

M2.5 creates:

- a deterministic 30-day expected remittance schedule;
- synthetic observed eligible sales;
- synthetic observed remittance;
- principal and finance-charge allocation;
- expected and observed balance roll-forward;
- rolling 7-day and 14-day coverage;
- consecutive shortfall streaks;
- non-DPD performance status;
- governed internal early-warning codes;
- advance-level exposure-at-risk summaries;
- daily scenario-level portfolio summaries;
- concentration and performance-limit evidence;
- latest and immutable archive contracts;
- matched baseline/stress comparisons;
- lineage and Power BI consumption views.

It does **not** move real payments or settlement funds, use bank-account or routing information, transmit external notices, produce production adverse-action notices, refer merchants to collections, or initiate legal action.

---

# Governed identities

```text
Methodology
M2_5_METHOD_V1

Policy
M2_5_DAILY_REMITTANCE_MONITORING_POLICY_V1

Consumption contract
M2_DAILY_REMITTANCE_MONITORING_CONSUMPTION v1

Schema
M2_5_DAILY_REMITTANCE_MONITORING_SCHEMA_V1

Acceptance gate
M2_5_DAILY_REMITTANCE_EXPOSURE_MONITORING
```

## Certified M2.4 source boundary

```text
Source contract
M2_PORTFOLIO_ACTIVATION_CONSUMPTION v1

Source schema
M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1

Accepted M2.4 combined hash
117450a3eea7bb3d3c74d18cc3c8e96a

Source acceptance gate
M2_4_BOOKING_FUNDING_PORTFOLIO_ACTIVATION
```

The build independently audited the accepted M2.4 physical source objects and required columns before packaging. The source contract includes the accepted account, advance, initial-portfolio, latest-activation, and M2.4 registry layers.

---

# Monitoring design

## Expected remittance schedule

Each activated scenario/application record receives a 30-day monitoring schedule:

```text
59 active advances
×
30 monitoring days
=
1,770 expected schedule rows
```

The daily schedule includes:

```text
Expected eligible sales
Expected remittance
Expected principal allocation
Expected finance-charge allocation
Expected beginning balance
Expected cumulative remittance
Expected ending balance
Expected payoff-complete flag
```

Daily remittance is capped by the remaining accepted total repayment amount.

## Deterministic observed performance

Observed eligible sales are generated with a stable MD5-derived application/day factor. The design does not use PostgreSQL `random()` or any session-dependent seed.

```text
Baseline factor floor           0.75
Baseline factor span            0.55

Stress factor floor             0.55
Stress factor span              0.55

Weekend factor                  0.90
Zero-sales modulus                29
```

Baseline and stress use the **same matched application/day seed**. The stress factor is then constrained against the matched baseline factor, providing an explicit stress non-improvement boundary.

Observed performance includes:

```text
Observed eligible sales
Observed remittance
Principal and finance-charge allocation
Observed beginning and ending balance
Cumulative remittance and shortfall
Daily coverage
Rolling 7-day coverage
Rolling 14-day coverage
Consecutive shortfall days
Early-warning indicators
Performance status
```

The implementation uses window functions rather than daily self-joins.

---

# Non-DPD performance statuses

M2.5 uses sales-linked remittance performance rather than traditional consumer-loan delinquency buckets.

| Status | Rank | Governing interpretation |
|---|---:|---|
| `PAID_OFF` | 0 | Ending monitored balance reached zero |
| `ON_TRACK` | 1 | Rolling 7-day coverage is at least 90% |
| `WATCH` | 2 | Rolling 7-day coverage is 75%–90% |
| `UNDERPERFORMING` | 3 | Rolling 7-day coverage is 50%–75% |
| `SEVERE_SHORTFALL` | 4 | Rolling 7-day coverage is below 50% |

All definitions retain:

```text
production_adverse_action_notice_flag = false
```

---

# Early-warning framework

The eight governed warnings are:

```text
M2_5_EW_7D_COVERAGE_BELOW_90
M2_5_EW_14D_COVERAGE_BELOW_80
M2_5_EW_3_CONSECUTIVE_SHORTFALLS
M2_5_EW_CUMULATIVE_SHORTFALL_10PCT
M2_5_EW_BALANCE_RUNOFF_SLOW
M2_5_EW_STRESS_SCENARIO
M2_5_EW_ZERO_SALES_DAY
M2_5_EW_SEVERE_UNDERPERFORMANCE
```

These are internal synthetic monitoring signals. They are not production notices, adverse-action reasons, collection referrals, or legal conclusions.

# Portfolio-limit framework

Six scenario-aware monitoring limits are included:

```text
Baseline total ending outstanding exposure
Stress total ending outstanding exposure
Maximum single-advance concentration
Watch-plus account share
Severe-shortfall account share
Cumulative shortfall ratio
```

Limit breaches are retained as evidence. A synthetic breach does not by itself invalidate the module; acceptance requires that the limit methodology, calculation, identity and evidence all reconcile.

---

# Expected deterministic population

| Entity family | Expected rows |
|---|---:|
| Policy profiles | 1 |
| Performance-status definitions | 5 |
| Early-warning definitions | 8 |
| Portfolio-limit definitions | 6 |
| Accepted active-advance source rows | 59 |
| Daily expected schedule rows | 1,770 |
| Daily observed-performance rows | 1,770 |
| Advance-monitoring summaries | 59 |
| Daily portfolio summaries | 60 |
| Latest monitoring contracts | 59 |
| Immutable archive rows | 59 |
| Matched baseline/stress comparisons | 15 |
| Contract-registry rows | 1 |
| **Canonical entities** | **3,857** |

The 60 daily portfolio summaries are:

```text
2 scenarios
×
30 monitoring days
=
60 rows
```

The 15 matched comparisons represent applications active in both baseline and recession/energy scenarios.

---

# Physical architecture

M2.5 adds:

```text
msbf_ctl.m2_5_policy_profile
msbf_ctl.m2_5_daily_monitoring_contract_registry

msbf_m2.remittance_performance_status_definition
msbf_m2.portfolio_early_warning_definition
msbf_m2.portfolio_monitoring_limit_definition

msbf_m2.advance_monitoring_source_snapshot
msbf_m2.daily_remittance_schedule
msbf_m2.daily_remittance_performance_snapshot
msbf_m2.advance_monitoring_summary_snapshot
msbf_m2.daily_portfolio_monitoring_summary
msbf_m2.advance_monitoring_latest
msbf_m2.advance_monitoring_archive
```

The archive is protected against `UPDATE` and `DELETE`.

Governed views provide:

```text
Latest monitoring consumption
Daily performance consumption
Daily portfolio consumption
Matched baseline/stress comparison
Lineage
Power BI monitoring output
Run-scoped canonical entities and combined hash
```

Open the architecture diagram (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/diagrams/M2_5_ARCHITECTURE.png`; referenced bytes not established here)

Open the scalable SVG (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/diagrams/M2_5_ARCHITECTURE.svg`; referenced bytes not established here)

Open the architecture specification (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_ARCHITECTURE.md`; referenced bytes not established here)

Open the schema-change specification (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_SCHEMA_CHANGE_SPECIFICATION.md`; referenced bytes not established here)

---

# Exact execution order

Run against:

```text
msbf_strategy
```

Use DBeaver **Execute SQL Script**.

```text
164 → 165 → 166 → 167 → 168 → 169 → 170 → 171
```

| Order | Program | Required checkpoint |
|---:|---|---|
| 1 | 164 — Schema, policy, definitions, functions and views (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/164_msbf_m2_5_schema_policy_monitoring_contract_extension_v0_2.sql`; referenced bytes not established here) | `schema_policy_status = PASS` |
| 2 | 165 — Hard-stop preflight (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/165_msbf_m2_5_preflight_validation_v0_2.sql`; referenced bytes not established here) | `preflight_status = PASS` |
| 3 | 166 — Daily remittance and monitoring generation (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/166_msbf_m2_5_daily_remittance_monitoring_generation_v0_2.sql`; referenced bytes not established here) | 3,857 canonical entities and zero mismatches |
| 4 | 167 — Positive validation (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/167_msbf_m2_5_daily_remittance_monitoring_validation_v0_2.sql`; referenced bytes not established here) | 120 of 120 `PASS` |
| 5 | 168 — Negative controls (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/168_msbf_m2_5_negative_control_tests_v0_2.sql`; referenced bytes not established here) | 20 of 20 `PASS` |
| 6 | 169 — Acceptance finalizer (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/sql/169_msbf_m2_5_acceptance_finalize_v0_2.sql`; referenced bytes not established here) | Run and contract accepted; gate `PASS` |
| 7 | 170 — Master report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/170_MSBF_M2_5_Master_Report_v0_2.sql`; referenced bytes not established here) | `overall_m2_5_status = PASS` |
| 8 | 171 — Detailed report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/171_MSBF_M2_5_Detail_Report_v0_2.sql`; referenced bytes not established here) | 24 result sets |

Open the complete execution and validation guide (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_EXECUTION_AND_VALIDATION_GUIDE.md`; referenced bytes not established here)

## Required Program 164 checkpoint

```text
policy_status                         APPROVED
acceptance_gate_catalog_rows          1
status_definition_rows                5
warning_definition_rows               8
limit_definition_rows                 6
schema_policy_status                  PASS
```

## Required Program 165 checkpoint

```text
run_status                            M2_4_ACCEPTED

source_contract_status                ACCEPTED
source_contract_code                  M2_PORTFOLIO_ACTIVATION_CONSUMPTION
source_contract_version               1
source_schema_version                 M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1
source_combined_hash                  117450a3eea7bb3d3c74d18cc3c8e96a
source_gate_status                    PASS

active source rows                    59
distinct scenario/application rows    59
baseline active rows                  44
stress active rows                    15

all M2.5 targets                       0
preflight_status                      PASS
```

## Required Program 166 checkpoint

```text
run_status                         M2_5_GENERATED

policy_rows                        1
status_definition_rows             5
warning_definition_rows            8
limit_definition_rows              6

source_rows                        59
schedule_rows                   1,770
performance_rows                1,770
advance_summary_rows               59
portfolio_summary_rows             60
latest_rows                        59
archive_rows                       59
comparison_rows                    15
registry_rows                       1

expected_canonical_entities     3,857
actual_canonical_entities       3,857
row_level_mismatches                0

stress_status_improvements           0
stress_coverage_improvements         0

all governed set hashes          non-null
generation_status                PASS
```

After Program 166 commits successfully, do **not** rerun it.

## Expected final results

```text
Program 167
120 / 120 positive controls PASS
run_status = M2_5_VALIDATED
contract_status = VALIDATED

Program 168
20 / 20 negative controls PASS

Program 169
acceptance_status = PASS
final_run_status = M2_5_ACCEPTED
final_contract_status = ACCEPTED
gate_status = PASS

Program 170
overall_m2_5_status = PASS

Program 171
24 governed result sets
```

The final two result sets must retain their headers and contain zero rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

---

# Recovery behavior

## Failed Program 164

Open Program 164A (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/164A_msbf_m2_5_failed_schema_policy_recovery_check_v0_2.sql`; referenced bytes not established here)

After clicking Stop, execute:

```sql
ROLLBACK;
```

Program 164A verifies that the failed schema transaction left no partial M2.5 tables, views, functions, triggers, policy rows, definitions, evidence or acceptance rows.

## Failed or cancelled Program 166

Open Program 166A (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/166A_msbf_m2_5_failed_generation_recovery_check_v0_2.sql`; referenced bytes not established here)

Run after:

```sql
ROLLBACK;
```

Programs 164 and 165 remain authoritative. All generated M2.5 targets must remain empty.

## Lost Program 166 result tab

Open Program 166B (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/tests/166B_msbf_m2_5_generation_reconciliation_reconstructed_v0_2.sql`; referenced bytes not established here)

Program 166B is read-only and reconstructs:

```text
Lifecycle
Physical cardinalities
Outcome totals
All governed hashes
Canonical count
Matched stress diagnostics
Expected and observed remittance totals
```

Open the recovery guide (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_RECOVERY_GUIDE.md`; referenced bytes not established here)

---

# Validation framework

The package includes:

```text
Positive controls                   120
Negative controls                    20
Generation evidence rows             24
Detailed-report result sets          24
```

Positive coverage includes:

- accepted M2.4 contract, schema, gate and combined hash;
- policy and payload-to-physical-field reconciliation;
- status, warning and limit dictionaries;
- source, schedule, performance, summary, latest and archive grains;
- expected and observed remittance allocation;
- daily and cumulative balance roll-forward;
- rolling 7-day and 14-day coverage;
- consecutive-shortfall streak logic;
- early-warning trigger identities;
- advance and portfolio aggregation;
- portfolio-limit evaluation;
- physical row-hash reconstruction;
- every governed set hash;
- run-scoped combined canonical identity;
- latest/archive reproduction;
- matched baseline/stress non-improvement;
- archive immutability;
- absence of real-payment, bank-account, notice, collection and legal payloads;
- acceptance readiness.

Negative controls prove rejection of:

```text
Invalid policy status
Policy boundary drift
Invalid status, warning and limit definitions
Duplicate daily performance grain
Invalid observed remittance
Broken balance roll-forward
Invalid zero-sales identity
Invalid status rank
Warning-array type drift
Archive update and delete attempts
Post-generation rerun
Premature acceptance
M2.4 source-hash drift
Real-payment payload
Bank-account payload
External-notice payload
Production adverse-action payload
Collections-referral payload
Legal-action payload
```

Open the validation matrix (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_VALIDATION_MATRIX.md`; referenced bytes not established here)

---

# Error-prevention and engineering hardening

The build was specifically audited against the defect classes encountered in M1.17, M2.1, M2.2 and M2.3.

## Source-contract safety

```text
Accepted M2.4 ZIP checksum verified
Exact physical source relations verified
Required M2.4 columns verified
Accepted source hash frozen
No guessed source relation or field
```

## Hash and type safety

```text
No invalid temporary hash placeholder
Target-typed staging before every hash
Physical persisted field names used in identities
Expected/actual canonical reconstruction
Run-scoped combined canonical view
Latest/archive payload reproduction
```

## SQL namespace and projection controls

```text
No operational USING joins
No persistent INSERT SELECT *
Explicit persistent INSERT target columns
Insert targets and projections audited
No ambiguous acceptance namespace
Joined source projection expanded explicitly
```

## DBeaver and PL/pgSQL controls

```text
Every UPDATE has a WHERE predicate
No session random()
No DBeaver-sensitive braced hash regex
No concatenated RAISE EXCEPTION
No transaction control inside PL/pgSQL bodies
No scalar MD5/FILTER construction
No unsupported Boolean max/min aggregate
```

## Performance controls

```text
No upstream regeneration
Accepted M2.4 source materialized once
30-day schedule materialized once
Window functions for rolling coverage and streaks
Indexes before downstream joins
ANALYZE before reuse
Persisted generation separated from validation
```

## Recent-module lessons incorporated

```text
Scenario/application grain is explicit
Baseline/stress observations share the same deterministic seed
Stress factor is constrained against matched baseline
Rolling coverage is null-safe after payoff
Consecutive-shortfall streak uses a filtered window count
Positive validation supports aligned rerun state
Coverage identity handles zero expected remittance
Grouped detail reports use group-safe ranking and ordering
Acceptance evidence is one-valued
Acceptance writer includes reviewer_role
```

All 11 controlled SQL programs include full professional headers. Long programs include navigable section or result-set commentary.

Open the SQL engineering standards (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_SQL_ENGINEERING_STANDARDS.md`; referenced bytes not established here)

Open the completed SQL engineering audit (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_SQL_ENGINEERING_AUDIT.md`; referenced bytes not established here)

Open the package-validation report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

Open the accepted-source and hardening audit (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_ACCEPTED_SOURCE_AND_HARDENING_AUDIT.json`; referenced bytes not established here)

---

# Additional documentation and catalogs

- Package README (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/README.md`; referenced bytes not established here)
- Business and stage-boundary charter (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_BUSINESS_AND_STAGE_BOUNDARY_CHARTER.md`; referenced bytes not established here)
- Design and generation specification (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_DESIGN_AND_GENERATION_SPECIFICATION.md`; referenced bytes not established here)
- Parameter dictionary — Markdown (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/M2_5_PARAMETER_DICTIONARY.md`; referenced bytes not established here)
- Parameter dictionary — CSV (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_PARAMETER_DICTIONARY.csv`; referenced bytes not established here)
- Expected-results catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_EXPECTED_RESULTS.json`; referenced bytes not established here)
- Run configuration (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_RUN_CONFIGURATION.json`; referenced bytes not established here)
- Execution-order catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_EXECUTION_ORDER.csv`; referenced bytes not established here)
- Table and grain catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_TABLE_GRAIN_CATALOG.csv`; referenced bytes not established here)
- Field dictionary (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_FIELD_DICTIONARY.csv`; referenced bytes not established here)
- Performance-status catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_STATUS_DEFINITION_CATALOG.csv`; referenced bytes not established here)
- Early-warning catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_EARLY_WARNING_CATALOG.csv`; referenced bytes not established here)
- Portfolio-limit catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_PORTFOLIO_LIMIT_CATALOG.csv`; referenced bytes not established here)
- Positive-control catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_POSITIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Negative-control catalog (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_NEGATIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Static-validation record (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/catalogs/M2_5_STATIC_VALIDATION.json`; referenced bytes not established here)
- Module build report (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/M2_5_FINAL_BUILD_REPORT.json`; referenced bytes not established here)
- M2.6 handoff (historical reference: `sandbox:[session]/build_m2_5_final/MSBF_M2_5_Daily_Remittance_Exposure_Portfolio_Monitoring_v0_2/docs/NEXT_STEP_M2_6_INTERVENTION_WORKOUT_RECOVERY_STRATEGY.md`; referenced bytes not established here)

# Current governed progression

```text
G0 Physical Foundation
PASS

→

G1 Governed Run Control
PASS

→

M1.2–M1.17
PASS

→

G2_M1_CONTRACT
PASS

→

M2.1 Eligibility, Policy Gates
& Decision Routing Foundations
PASS

→

M2.2 Pricing, Structure
& Counteroffer Foundations
PASS

→

M2.3 Final Offer
& Decision Authorization
PASS

→

M2.4 Booking, Funding
& Portfolio Activation
PASS

→

M2.5 Daily Remittance, Exposure
& Portfolio Monitoring
READY FOR LIVE EXECUTION

→

M2.6 Intervention, Workout
& Recovery Strategy
PENDING M2.5 ACCEPTANCE
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-22a3c67f-33a9-452a-9174-d39d09fa2be0"></a>
## Andrew / user · C068-M00447

C068-M00447 · 2026-08-01T18:56:26.391000-04:00 · active path

Preceding visible parent: [C068-M00446](part-35.md#m-edb3778d-9251-46e2-b2f1-a96678c019b2)

<!-- BEGIN_SOURCE_MESSAGE -->
Error in program 165 (preflight validation): SQL Error [42701]: ERROR: Column "source_m2_4_contract_code" specified more than once. Program 164 ran fine.
<!-- END_SOURCE_MESSAGE -->


<a id="m-508355ca-13a1-47cf-b9b8-2a63ad8b8426"></a>
## Assistant · C068-M00448

C068-M00448 · 2026-08-01T19:05:55.092644-04:00 · active path

Preceding visible parent: [C068-M00447](part-35.md#m-22a3c67f-33a9-452a-9174-d39d09fa2be0)

<!-- BEGIN_SOURCE_MESSAGE -->
I found the defect: Program 165’s final temporary-table projection duplicates five policy and observed-source identity column names. I’m preparing a governed v0.2R1 preflight hotfix.
<!-- END_SOURCE_MESSAGE -->


<a id="m-be3c1ac2-00e7-4e91-a206-8f87a28ab2d2"></a>
## Assistant · C068-M00449

C068-M00449 · 2026-08-01T19:12:13.880841-04:00 · active path

Preceding visible parent: [C068-M00448](part-35.md#m-508355ca-13a1-47cf-b9b8-2a63ad8b8426)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.5 Program 165 diagnosis

This is a **source-code defect in Program 165**, not a problem with the database state produced by Program 164.

Program 165 creates:

```sql
CREATE TEMP TABLE _m2_5_preflight
AS
SELECT ...
```

Within that projection, it assigned the same output column name to both the policy-declared source identity and the physically observed source-registry identity. For example:

```sql
policy.source_m2_4_contract_code,
source_m2_4.contract_code AS source_m2_4_contract_code,
```

A PostgreSQL `CREATE TABLE AS SELECT` requires every resulting table column to have a unique name. It therefore stopped at the first collision:

```text
SQLSTATE 42701
Column "source_m2_4_contract_code" specified more than once
```

The complete audit found **five duplicate output-name pairs**:

```text
source_m2_4_contract_code
source_m2_4_contract_version
source_m2_4_schema_version
source_m2_4_combined_hash
source_m1_6_combined_hash
```

The corrected program assigns a distinct `policy_source_...` alias to the policy-declared values while preserving the original `source_...` names for the physically observed source values.

For example:

```sql
policy.source_m2_4_contract_code
    AS policy_source_m2_4_contract_code,

source_m2_4.contract_code
    AS source_m2_4_contract_code,
```

No preflight predicate, expected count, source contract, source hash, methodology, stage boundary, or downstream program changed.

# Immediate DBeaver action

Click **Stop**.

Then execute:

```sql
ROLLBACK;
```

A PostgreSQL notice stating that no transaction is in progress is harmless.

Do **not** rerun Program 164. It completed successfully and established the M2.5 schema, policy, dictionaries, functions, views, and gate registration.

Program 165 writes only session-temporary preflight objects. The corrected script begins by dropping and reconstructing those temporary objects, so the partial failed attempt does not need a separate data cleanup.

# Corrected Program 165 v0.2R1

Download corrected Program 165 v0.2R1 (historical reference: `sandbox:[session]/165_msbf_m2_5_preflight_validation_v0_2R1.sql`; referenced bytes not established here)

```text
SHA-256
8142a40edc70caf912bc0faaf497b465ed6cd21643d8f30639df9b1e7f3735a6
```

Run:

```text
165_msbf_m2_5_preflight_validation_v0_2R1.sql
```

Do not run the original:

```text
165_msbf_m2_5_preflight_validation_v0_2.sql
```

## Required result

```text
preflight_status = PASS
```

The principal expected values remain:

```text
run_status                         M2_4_ACCEPTED

source_m2_4_contract_status        ACCEPTED
source_m2_4_contract_code          M2_PORTFOLIO_ACTIVATION_CONSUMPTION
source_m2_4_contract_version       1
source_m2_4_schema_version         M2_4_PORTFOLIO_ACTIVATION_SCHEMA_V1
source_m2_4_combined_hash          117450a3eea7bb3d3c74d18cc3c8e96a

source_m1_6_pos_rows               270,000
source_m1_6_deposit_rows           270,000

source_rows                        59
baseline_rows                      44
stress_rows                        15
applications                       44
account_ids                        59
advance_ids                        59
invalid_source_rows                0

replay_source_rows                 59
minimum_pos_days                   at least 120
minimum_deposit_days               at least 120
insufficient_replay_rows           0

status_rows                        6
alert_rows                         7
reason_rows                        24
prohibited_reason_flags            0

all generated M2.5 target rows     0
all M2.5 evidence rows             0
all M2.5 acceptance rows           0

preflight_status                   PASS
```

After Program 165 v0.2R1 returns `PASS`, continue with the existing programs:

```text
166 → 167 → 168 → 169 → 170 → 171
```

Programs 166 through 171 were not changed by this hotfix.

# Consolidated v0.2R1 hotfix package

Download M2.5 v0.2R1 — Preflight Duplicate-Projection Hotfix (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2R1_Preflight_Duplicate_Projection_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2R1_Preflight_Duplicate_Projection_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
2c9aa0ea50c54143ffcee7ba03936b8f0a0276242c96b40692930f6d8532c4c4

Archive size
302,875 bytes

Files
94
```

The hotfix package contains:

```text
live_recovery/tests/
    165_msbf_m2_5_preflight_validation_v0_2R1.sql

clean_build/
    Complete corrected M2.5 v0.2R1 standalone repository

source_history/
    Original Program 165 v0.2

docs/
    Root-cause and execution guide
    Exact Program 165 source diff

catalogs/
    Machine-readable duplicate-projection audit
```

# Complete corrected standalone M2.5 repository

Download MSBF M2.5 v0.2R1 complete standalone package (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2R1.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_5_v0_2R1.zip.sha256`; referenced bytes not established here)

```text
SHA-256
1fd698e1e220b67e3547104b9d43bca304ce3b96d47b1a9cbdf98a4d7c756e27

Archive size
266,739 bytes

Files
84
```

## Audit records

- Preflight projection audit (historical reference: `sandbox:[session]/M2_5_v0_2R1_PREFLIGHT_PROJECTION_AUDIT.json`; referenced bytes not established here)
- Hotfix build and archive-validation report (historical reference: `sandbox:[session]/M2_5_v0_2R1_HOTFIX_BUILD_REPORT.json`; referenced bytes not established here)

The corrected source was checked for all projected output names:

```text
Duplicate output columns in v0.2       5
Duplicate output columns in v0.2R1     0

Persistent data changed                false
Business logic changed                 false
Expected counts changed                false
Source contracts changed               false
Programs 166–171 changed               false

ZIP CRC                                PASS
Complete extraction                    PASS
File-level SHA-256 reconciliation      PASS
Windows ZIP metadata                   PASS
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-0e4c274f-64f0-49ce-81e5-8a92998f43ba"></a>
## Andrew / user · C068-M00450

C068-M00450 · 2026-08-01T19:20:18.122000-04:00 · active path

Preceding visible parent: [C068-M00449](part-35.md#m-be3c1ac2-00e7-4e91-a206-8f87a28ab2d2)

<!-- BEGIN_SOURCE_MESSAGE -->
Error in program 167: SQL Error [P0001]: ERROR: M2.5 positive validation failed: pass 119, fail 1. Where: PL/pgSQL function inline_code_block line 65 at RAISE.  Programs 164 through 166 ran fine.
<!-- END_SOURCE_MESSAGE -->


<a id="m-64130b4b-5486-4e0c-b939-5c4c42d8dc8c"></a>
## Assistant · C068-M00451

C068-M00451 · 2026-08-01T19:29:46.378891-04:00 · active path

Preceding visible parent: [C068-M00450](part-35.md#m-0e4c274f-64f0-49ce-81e5-8a92998f43ba)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m isolating the failed control against the exact v0.2R1 source and preparing a current-state recovery check with corrected validation.
<!-- END_SOURCE_MESSAGE -->
