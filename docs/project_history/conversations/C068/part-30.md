# Merchant POS Lending Simulator

Part 30 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-29.md)
[Next part](part-31.md)

<a id="m-83579413-5065-4317-adab-03acfdd8cc27"></a>
## Assistant · C068-M00387

C068-M00387 · 2026-07-29T18:12:18.255791-04:00 · active path

Preceding visible parent: [C068-M00386](part-29.md#m-960de191-a054-44c8-9e91-0331d0ca049c)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.1 — Strategy Identity, Profile & Source Gatekeeper Foundations

The first governed stage of **Module 2 — Strategy and Offer Decisioning** is complete, statically validated, integrated into the accepted M1.17/G2 repository, and packaged for controlled PostgreSQL execution.

M2.1 is **ready for live execution but is not yet accepted**. Formal acceptance requires successful execution of Programs 132–139, structured evidence export, and independent evidence review.

## Primary deliveries

### Full project repository — recommended

Download MSBF Project v0.2 — M2.1 Ready for Execution (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M2_1_READY_FOR_EXECUTION_Windows.zip`; referenced bytes not established here)

Download the full-project SHA-256 file (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M2_1_READY_FOR_EXECUTION_Windows.zip.sha256`; referenced bytes not established here)

Canonical long-form copy:

Download the canonical M2.1-ready project repository (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M2_1_READY_FOR_EXECUTION.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_project_delivery_v0_2_M2_1_READY_FOR_EXECUTION.zip.sha256`; referenced bytes not established here)

For Windows, extract near the drive root:

```text
C:\MSBF\
```

### Standalone M2.1 package

Download MSBF M2.1 v0.2 (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2.zip`; referenced bytes not established here)

Download the standalone SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2.zip.sha256`; referenced bytes not established here)

Canonical long-form copy:

Download the canonical standalone M2.1 package (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_strategy_identity_profile_source_gatekeeper_foundations_v0_2.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_strategy_identity_profile_source_gatekeeper_foundations_v0_2.zip.sha256`; referenced bytes not established here)

### Build records

- Final delivery summary (historical reference: `sandbox:[session]/M2_1_FINAL_DELIVERY_SUMMARY.md`; referenced bytes not established here)
- Complete package-build report (historical reference: `sandbox:[session]/MSBF_M2_1_PACKAGE_BUILD_REPORT.json`; referenced bytes not established here)
- Delivery index (historical reference: `sandbox:[session]/M2_1_DELIVERY_INDEX.md`; referenced bytes not established here)

Both standalone and full-project archives passed CRC, complete-extraction, inventory, in-archive SHA-256, extracted-file SHA-256, and Windows ZIP-metadata validation.

---

# Governed scope

The full Module 2 architecture ultimately needs to support:

```text
Strategy identity
→ experiment assignment
→ eligibility and policy gates
→ pricing and structure
→ candidate offers
→ compliance controls
→ final decision routing
→ portfolio allocation
```

M2.1 deliberately implements only the first bounded layer:

> **For each accepted application/scenario, which governed strategy and product profiles are applicable, should the record pass, route to review, or be blocked, and why?**

It does **not** create:

- experiment-cell assignment;
- price, factor rate, APR, or remittance rate;
- funding amount or term;
- approval;
- counteroffer;
- decline;
- adverse-action reasons;
- booking or funding;
- realized portfolio outcomes.

Those remain later governed Module 2 stages.

---

# Source and run architecture

M2.1 consumes only the accepted G2 boundary:

```text
M1_G2_CONSUMPTION_BUNDLE v1
M1_G2_BUNDLE_SCHEMA_V1

Accepted combined G2 hash
7d9e466da28cad2551aa99c4c40c912b
```

A separate Module 2 run identity is created:

```text
Run code
M2_V0_2_GATEKEEPER_BUILD

Run version
1

Initial status
M2_1_PLANNED
```

Governed lifecycle:

```text
M2_1_PLANNED
→ M2_1_GENERATED
→ M2_1_VALIDATED
→ M2_1_ACCEPTED
```

This prevents Module 2 development from mutating the accepted Module 1 run or its certified contracts.

## M2.1 contract identity

```text
Methodology
M2_1_METHOD_V1

Contract
M2_1_GATEKEEPER_CONSUMPTION v1

Schema
M2_1_GATEKEEPER_SCHEMA_V1

Acceptance gate
M2_1_PROFILE_SOURCE_GATEKEEPER
```

---

# Strategy and product profiles

## Strategy profiles

| Strategy | Role | Governed posture |
|---|---|---|
| `M2_1_CONTROLLED_ENTRY` | Baseline | Balanced reference posture |
| `M2_1_RELATIONSHIP_GROWTH` | Challenger | Relationship-led growth posture |
| `M2_1_RESILIENCE_DISCIPLINE` | Challenger | Conservative resilience posture |

## Product profiles

```text
M2_1_STANDARD_SALES_LINKED
M2_1_LOW_AND_GROW
```

## Operating model

```text
M2_1_PROCESSOR_EMBEDDED_DAILY_REMITTANCE
```

## Jurisdiction identity

```text
M2_1_SYNTHETIC_US_COMMERCIAL_BASE
```

The jurisdiction profile is a synthetic strategy identity—not legal advice, licensing approval, or a production compliance conclusion.

---

# Ten ordered gatekeeper rules

Every accepted G2 scenario/application record is evaluated under each of the three strategy profiles through ten transparent rules:

| Order | Gate |
|---:|---|
| 1 | Certified G2 contract readiness |
| 2 | M1.15 application-contract evidence |
| 3 | M1.16 acquisition-contract evidence |
| 4 | Accepted hard-stop recommendation |
| 5 | Accepted manual-review recommendation |
| 6 | Verification disposition |
| 7 | Processor continuity |
| 8 | Product applicability |
| 9 | Strategy applicability |
| 10 | Economic evidence |

Each rule returns exactly one result:

```text
PASS
REVIEW
BLOCK
```

## Profile-level aggregation

```text
Any BLOCK
→ BLOCK / INELIGIBLE

No BLOCK and one or more REVIEW gates
→ REVIEW / REVIEW_REQUIRED

All ten gates PASS
→ PASS / ELIGIBLE
```

Product and strategy rules also produce:

```text
APPLICABLE
CONDITIONAL
NOT_APPLICABLE
```

The first highest-severity nonpass rule becomes the primary reason code. All other nonpass reasons remain available in the secondary-reason payload.

---

# Deterministic expected population

| Entity family | Expected rows |
|---|---:|
| Configuration profiles | 1 |
| Strategy profiles | 3 |
| Product profiles | 2 |
| Operating-model profiles | 1 |
| Jurisdiction profiles | 1 |
| Profile bundles | 3 |
| Gate rules | 10 |
| Accepted G2 source rows | 1,500 |
| Long-form gate results | 45,000 |
| Gatekeeper snapshots | 4,500 |
| Latest contract rows | 4,500 |
| Immutable archive rows | 4,500 |
| Contract-registry rows | 1 |
| **Canonical entities** | **60,022** |

The central calculation is:

```text
1,500 accepted G2 source rows
×
3 governed strategy profiles
×
10 ordered rules
=
45,000 gate-result records
```

and:

```text
1,500 source rows
×
3 strategy profiles
=
4,500 gatekeeper contracts
```

---

# Physical architecture

## Control-plane objects

```text
msbf_ctl.m2_1_configuration_profile
msbf_ctl.m2_1_strategy_profile
msbf_ctl.m2_1_product_profile
msbf_ctl.m2_1_operating_model_profile
msbf_ctl.m2_1_jurisdiction_profile
msbf_ctl.m2_1_profile_bundle
msbf_ctl.m2_1_gate_rule_catalog
msbf_ctl.m2_1_reason_code_catalog
msbf_ctl.m2_1_run_evidence
msbf_ctl.m2_1_gatekeeper_contract_registry
```

## Business and contract objects

```text
msbf_m2.m2_1_source_contract_snapshot
msbf_m2.application_strategy_gate_result
msbf_m2.application_strategy_gatekeeper_snapshot
msbf_m2.application_strategy_gatekeeper_latest
msbf_m2.application_strategy_gatekeeper_archive
```

## Governed views

```text
msbf_m2.v_m2_1_gatekeeper_latest
msbf_m2.v_m2_1_gate_result_detail
msbf_m2.v_m2_1_strategy_summary
msbf_m2.v_m2_1_gatekeeper_lineage
msbf_m2.v_m2_1_power_bi_gatekeeper
```

The archive is protected against both `UPDATE` and `DELETE`.

Open the architecture diagram (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/diagrams/M2_1_ARCHITECTURE.png`; referenced bytes not established here)

Open the scalable SVG architecture (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/diagrams/M2_1_ARCHITECTURE.svg`; referenced bytes not established here)

Open the architecture specification (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_ARCHITECTURE.md`; referenced bytes not established here)

---

# Exact execution order

Run these programs in DBeaver against:

```text
msbf_strategy
```

Use **Execute SQL Script**.

| Order | Program | Required checkpoint |
|---:|---|---|
| 1 | 132 — Schema, run configuration, profiles, rules and views (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/sql/132_msbf_m2_1_schema_configuration_profile_extension_v0_2.sql`; referenced bytes not established here) | `schema_configuration_status = PASS` |
| 2 | 133 — Hard-stop preflight (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/tests/133_msbf_m2_1_preflight_validation_v0_2.sql`; referenced bytes not established here) | `preflight_status = PASS` |
| 3 | 134 — Deterministic gatekeeper generation (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/sql/134_msbf_m2_1_gatekeeper_generation_v0_2.sql`; referenced bytes not established here) | 60,022 canonical entities; zero mismatches |
| 4 | 135 — Positive validation (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/sql/135_msbf_m2_1_gatekeeper_validation_v0_2.sql`; referenced bytes not established here) | 96 of 96 `PASS` |
| 5 | 136 — Negative controls (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/sql/136_msbf_m2_1_negative_control_tests_v0_2.sql`; referenced bytes not established here) | 20 of 20 `PASS` |
| 6 | 137 — Acceptance finalizer (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/sql/137_msbf_m2_1_acceptance_finalize_v0_2.sql`; referenced bytes not established here) | Gate `PASS`; `M2_1_ACCEPTED` |
| 7 | 138 — Master report (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/tests/138_MSBF_M2_1_Gatekeeper_Master_Report_v0_2.sql`; referenced bytes not established here) | `overall_m2_1_status = PASS` |
| 8 | 139 — Detailed report (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/tests/139_MSBF_M2_1_Gatekeeper_Detail_Report_v0_2.sql`; referenced bytes not established here) | 24 result sets |

Open the complete execution and validation guide (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_EXECUTION_AND_VALIDATION_GUIDE.md`; referenced bytes not established here)

## Required Program 134 checkpoint

```text
run_status                    M2_1_GENERATED

configuration rows            1
strategy profiles             3
product profiles              2
operating profiles            1
jurisdiction profiles         1
profile bundles               3
gate rules                    10

source rows                   1,500
gate-result rows              45,000
gatekeeper rows               4,500
latest rows                   4,500
archive rows                  4,500
registry rows                 1

applications                  750
scenarios                     2
expected canonical entities   60,022
actual canonical entities     60,022
row-level mismatches          0

generation_status             PASS
```

After Program 134 commits successfully, **do not rerun it**.

## Final expected results

```text
Program 135
96 / 96 positive controls PASS
run_status = M2_1_VALIDATED

Program 136
20 / 20 negative controls PASS
run_status remains M2_1_VALIDATED

Program 137
acceptance_gate_status = PASS
contract_status = ACCEPTED
run_status = M2_1_ACCEPTED

Program 138
overall_m2_1_status = PASS

Program 139
24 governed result sets
```

Program 139’s final two result sets must retain their headers and contain zero rows:

```text
23 — Row-Level Deterministic Mismatches
24 — Blocking Errors and Stage-Boundary Violations
```

---

# Recovery programs

## Failed or cancelled generation

Download Program 132A (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/tests/132A_msbf_m2_1_failed_generation_recovery_check_v0_2.sql`; referenced bytes not established here)

Use only after Program 134 fails or is cancelled before commit and after:

```sql
ROLLBACK;
```

Required:

```text
run_status       M2_1_PLANNED
source rows      0
gate rows        0
snapshot rows    0
latest rows      0
archive rows     0
registry rows    0
evidence rows    0
recovery_status  PASS
```

## Lost generation-result tab

Download Program 134A (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/tests/134A_msbf_m2_1_generation_reconciliation_reconstructed_v0_2.sql`; referenced bytes not established here)

Use only if Program 134 committed successfully but its final DBeaver result tab was lost or suppressed.

It is read-only and reconstructs counts, lifecycle, set hashes, evidence count, and the combined canonical identity.

---

# Validation framework

The release includes:

```text
Positive controls                 96
Negative controls                 20
Detailed-report result sets       24
Generation-evidence rows          18
```

The positive controls cover:

- accepted G2 source run, gate, contract, schema, and hash;
- approved Module 2.1 configuration;
- exact profile, bundle, rule, source, gate, snapshot, latest, archive, and registry counts;
- unique physical grains;
- source G2 lineage and row hashes;
- every gate-rule mapping;
- product and strategy applicability;
- reason codes and severity ranks;
- profile-level aggregation;
- hard-stop and manual-review propagation;
- latest/archive reproduction;
- physical row hashes;
- all individual set hashes;
- the independently reconstructed 60,022-entity combined hash;
- strict absence of pricing, offer, final-decision, booking, and adverse-action outputs.

The negative controls prove fail-closed rejection of:

- invalid profile and rule statuses;
- duplicate strategy and source grains;
- invalid gate status and severity;
- inconsistent gatekeeper counts and eligibility mappings;
- archive update and delete attempts;
- post-generation reruns;
- premature acceptance;
- source G2 and configuration-hash drift;
- price, approval, counteroffer, and booking payloads.

Open the validation matrix (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_VALIDATION_MATRIX.md`; referenced bytes not established here)

---

# Performance and error-prevention engineering

The cumulative lessons from M1.6–M1.17 were incorporated before release:

```text
No upstream blueprint regeneration
Accepted G2 input materialized once
No large self-joins
Explicit qualified ON joins
No operational USING joins
No joined alias.* projections
Explicit persistent INSERT projections
Target-typed expected tables
Index and ANALYZE before downstream reconciliation
Independent physical hash reconstruction
No session random()
No unsupported max(boolean)
No scalar md5/FILTER defects
No heterogeneous untyped evidence UNION
No transaction control inside PL/pgSQL blocks
PERFORM for helper functions
ON COMMIT PRESERVE ROWS for filterable outputs
Negative mutations isolated in exception subtransactions
Exactly one value representation per evidence row
No DBeaver-sensitive braced hash regex
```

Open the SQL engineering audit (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_SQL_ENGINEERING_AUDIT.md`; referenced bytes not established here)

Open the package-validation report (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# Documentation and catalogs

- Package README (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/README.md`; referenced bytes not established here)
- Design and generation specification (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_DESIGN_AND_GENERATION_SPECIFICATION.md`; referenced bytes not established here)
- Business and stage-boundary charter (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_BUSINESS_AND_STAGE_BOUNDARY_CHARTER.md`; referenced bytes not established here)
- Parameter dictionary — Markdown (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_PARAMETER_DICTIONARY.md`; referenced bytes not established here)
- Parameter dictionary — CSV (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_PARAMETER_DICTIONARY.csv`; referenced bytes not established here)
- Expected results (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_EXPECTED_RESULTS.json`; referenced bytes not established here)
- Run configuration (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_RUN_CONFIGURATION.json`; referenced bytes not established here)
- Execution-order catalog (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_EXECUTION_ORDER.csv`; referenced bytes not established here)
- Table and grain catalog (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_TABLE_GRAIN_CATALOG.csv`; referenced bytes not established here)
- Field dictionary (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_FIELD_DICTIONARY.csv`; referenced bytes not established here)
- Strategy profiles (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_STRATEGY_PROFILES.csv`; referenced bytes not established here)
- Product profiles (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_PRODUCT_PROFILES.csv`; referenced bytes not established here)
- Gate-rule catalog (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_GATE_RULE_CATALOG.csv`; referenced bytes not established here)
- Reason-code catalog (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_REASON_CODE_CATALOG.csv`; referenced bytes not established here)
- Positive-control catalog (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_POSITIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Negative-control catalog (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_NEGATIVE_CONTROL_CATALOG.csv`; referenced bytes not established here)
- Static-validation record (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/catalogs/M2_1_STATIC_VALIDATION.json`; referenced bytes not established here)
- Module build report (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/M2_1_FINAL_BUILD_REPORT.json`; referenced bytes not established here)
- Recovery guide (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_RECOVERY_GUIDE.md`; referenced bytes not established here)
- Known limitations (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/M2_1_KNOWN_LIMITATIONS.md`; referenced bytes not established here)
- M2.2 handoff (historical reference: `sandbox:[session]/build_m2_1/MSBF_M2_1_Strategy_Identity_Profile_Source_Gatekeeper_Foundations_v0_2/docs/NEXT_STEP_M2_2_DETERMINISTIC_EXPERIMENT_ASSIGNMENT.md`; referenced bytes not established here)

---

# Accepted-history protection

The derivative full-project repository preserves the accepted M1.14, M1.15, M1.16, and M1.17 module trees byte for byte.

M2.1 was added under:

```text
20_M2_1
```

The standalone M2.1 package and the embedded full-project module directory are byte-identical.

---

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

M2.1 Strategy Identity, Profile
& Source Gatekeeper Foundations
READY FOR LIVE EXECUTION

→

M2.2 Deterministic Experiment Assignment
PENDING M2.1 ACCEPTANCE
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-8f6be5c7-82d5-4cb3-bb75-2aa5d9d490b0"></a>
## Andrew / user · C068-M00388

C068-M00388 · 2026-07-29T18:43:14.298000-04:00 · active path

Preceding visible parent: [C068-M00387](part-30.md#m-83579413-5065-4317-adab-03acfdd8cc27)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(191).png; 132_msbf_m2_1_schema_policy_extension_v0_2_20260729.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 133_msbf_m2_1_preflight_validation_v0_2.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bd1f3a40-1603-496a-b906-1d397d43050c"></a>
## Assistant · C068-M00389

C068-M00389 · 2026-07-29T18:54:00.672482-04:00 · active path

Preceding visible parent: [C068-M00388](part-30.md#m-8f6be5c7-82d5-4cb3-bb75-2aa5d9d490b0)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.1 preflight diagnosis

Program 133 stopped for **one isolated condition**:

```text
prohibited_columns = 1
preflight_status   = FAIL
```

Every other material preflight condition shown in the error passed:

```text
Accepted source run                 M1_17_ACCEPTED
M2.1 policy                         APPROVED
G2 bundle                           ACCEPTED
G2 combined hash                    matched
G2 acceptance gate                  PASS

Input rows                          1,500
Applications                          750
Scenarios                               2
Baseline rows                         750
Stress rows                           750

Strategy campaigns                      1
Gate definitions                       12
Reason definitions                     23
Outcome definitions                     4

Target gate rows                         0
Target snapshot rows                     0
Target latest rows                       0
Target archive rows                      0
Target registry rows                     0
Evidence rows                            0
Acceptance rows                          0
Blocking errors                          0
M2.2 tables                              0
```

Program 132 also formally returned `PASS` with the expected one campaign, 12 gate definitions, 23 reason codes, and four outcome definitions. Open the Program 132 checkpoint (historical reference: `sandbox:[session]/132_msbf_m2_1_schema_policy_extension_v0_2_20260729.csv`; referenced bytes not established here).

This means:

- the accepted M1.17/G2 state remains intact;
- Program 132’s schema and reference records committed;
- no M2.1 application-level generation occurred;
- Program 133 found exactly one physical column that its stage-boundary query classifies as downstream-only.

## Most likely defect class

The most likely explanation is an **overbroad preflight column scan**, not bad source data.

The strongest clue is:

```text
outcome_definition_rows = 4
prohibited_columns      = 1
```

A plausible culprit is a field such as:

```text
decision_outcome_code
```

inside the four-row **outcome-definition catalog**. A definition/catalog field can legitimately describe later governed outcomes while M2.1 still prohibits those fields from appearing in application-level gatekeeper outputs.

That would mean Program 133 is scanning the whole M2.1 object family rather than restricting the prohibition test to the row-level targets:

```text
gate results
profile snapshots
latest output
archive output
```

That is the most structurally consistent interpretation, but the exact column should be identified before changing the control.

# Immediate DBeaver action

Click **Stop**.

Do not select:

```text
Retry
Skip
Skip All
```

Then execute:

```sql
ROLLBACK;
```

Do not rerun Program 132. Do not proceed to Program 134.

This follows the established project rule to stop at the first exception and roll back the failed transactional program rather than bypassing a hard-stop control. [export reference: filecite | turn61file1]

# Run this diagnostic query

This is read-only. It will identify the column behind `prohibited_columns = 1`.

```sql
/* ============================================================================
M2.1 prohibited-column diagnostic
Purpose:
    Identify the exact M2.1 physical column being classified as premature
    pricing, offer, exposure, or final-decision output.

Writes:
    None.
============================================================================ */

SELECT
    c.table_schema,
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,

    CASE
        WHEN lower(c.table_name) ~
             '(definition|catalog|reference|dictionary)'
            THEN 'REFERENCE_OR_DEFINITION_OBJECT'

        WHEN lower(c.table_name) ~
             '(gate_result|snapshot|latest|archive|output|contract)'
            THEN 'ROW_LEVEL_OR_CONSUMPTION_OBJECT'

        ELSE 'REVIEW_OBJECT_SCOPE'
    END AS object_role_hint

FROM information_schema.columns AS c

WHERE c.table_schema IN
(
    'msbf_ctl',
    'msbf_ref',
    'msbf_m2'
)

  AND
  (
       lower(c.table_name) LIKE '%m2_1%'
       OR lower(c.table_name) LIKE '%strategy_campaign%'
       OR lower(c.table_name) LIKE '%gate_definition%'
       OR lower(c.table_name) LIKE '%reason_code%'
       OR lower(c.table_name) LIKE '%outcome_definition%'
       OR lower(c.table_name) LIKE '%gate_result%'
       OR lower(c.table_name) LIKE '%gatekeeper%'
  )

  AND lower(c.column_name) IN
  (
      'decision_outcome',
      'decision_outcome_code',
      'decision_path',

      'approval',
      'approval_flag',
      'counteroffer',
      'counteroffer_flag',
      'manual_review_flag',
      'decline',
      'decline_flag',
      'simulated_offer_exposure_flag',

      'price',
      'pricing',
      'factor_rate',
      'apr',
      'term',
      'offer',

      'approved_amount',
      'counteroffer_amount',
      'funding_amount',
      'remittance_rate',
      'approved_monthly_payment_proxy',
      'approved_payment_to_income_ratio',
      'approved_expected_loss_amount',

      'adverse_action',
      'booking',
      'funding_status'
  )

ORDER BY
    c.table_schema,
    c.table_name,
    c.ordinal_position;
```

## How to interpret the result

### If the row is in a definition or catalog object

For example:

```text
m2_1_outcome_definition.decision_outcome_code
```

then this is a **false-positive preflight-scope defect**.

The corrected Program 133 should:

- continue validating that the four governed outcome definitions exist;
- permit descriptive outcome identities in the reference catalog;
- apply the prohibited-column test only to row-level generated targets;
- continue prohibiting approval, counteroffer, decline, pricing, exposure, and booking fields from application-level M2.1 outputs.

### If the row is `manual_review_flag` in a gatekeeper target

That requires a semantic distinction:

- review routing is within the stated M2.1 gatekeeper purpose;
- a final `MANUAL_REVIEW` credit decision is not.

The control should prohibit final-decision fields, not a governed review-routing indicator that M2.1 intentionally needs.

### If the row is a true downstream field in a row-level target

Examples:

```text
approval_flag
counteroffer_flag
decline_flag
approved_amount
factor_rate
funding_amount
decision_outcome
```

then Program 132 created a real stage-boundary defect, and the schema must be corrected before generation.

# Source-package alignment

The live executable package is clearly the design with:

```text
1 strategy campaign
12 gate definitions
23 reason codes
4 outcome definitions
```

That differs materially from the profile-count narrative previously described in this chat. I will treat the **actual executable package** as authoritative and will not patch Program 133 from an assumed or mismatched source tree.

Attach one of these:

```text
Preferred:
MSBF_M2_1_v0_2.zip

Minimum:
133_msbf_m2_1_preflight_validation_v0_2.sql
```

The complete ZIP is strongly preferred because the same stage-boundary predicate should be audited through Programs 134–139. The resulting consolidated revision should include:

```text
132B — failed-preflight recovery and prohibited-column diagnosis
133  — corrected hard-stop preflight
134–139 — version-aligned downstream source after a complete audit
clean-build replacements
root-cause documentation
static SQL audit
manifest and SHA-256 inventory
validated hotfix ZIP
```

Until that source is attached and the one column is classified, **Program 134 should not be run**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-29bc6df9-fcb4-4c55-9b00-74c2db57bf14"></a>
## Andrew / user · C068-M00390

C068-M00390 · 2026-07-29T18:58:53.659000-04:00 · active path

Preceding visible parent: [C068-M00389](part-30.md#m-bd1f3a40-1603-496a-b906-1d397d43050c)

<!-- BEGIN_SOURCE_MESSAGE -->
that query you provided produces no rows
<!-- END_SOURCE_MESSAGE -->


<a id="m-180e4f28-3104-496b-bfad-1d4a9b41b392"></a>
## Assistant · C068-M00391

C068-M00391 · 2026-07-29T19:04:31.022268-04:00 · active path

Preceding visible parent: [C068-M00390](part-30.md#m-29bc6df9-fcb4-4c55-9b00-74c2db57bf14)

<!-- BEGIN_SOURCE_MESSAGE -->
You are right to flag that. **A zero-row result means my first diagnostic was too narrow.** It searched a guessed list of exact column names inside a guessed set of table-name patterns. It did not reproduce Program 133’s actual `prohibited_columns` predicate.

It does **not** mean that the preflight’s count of `1` is valid, nor does it prove the schema is clean. Program 133 may be:

- matching a broader pattern such as any column containing `outcome`, `decision`, or `offer`;
- inspecting a target table whose name does not contain `m2_1`, `gatekeeper`, or `gate_result`;
- inspecting `pg_attribute` rather than `information_schema.columns`;
- counting a JSON/configuration key rather than a physical column;
- or evaluating an incorrect catalog relation.

Do not proceed to Program 134, and do not rerun Program 132.

## Run this broader physical-column diagnostic

This removes the narrow object filter and searches all non-system schemas for both exact downstream fields and broader name patterns:

```sql
/* ============================================================================
M2.1 broad prohibited-column diagnostic

Purpose:
    Identify any column in an M2 / strategy / gate / snapshot / latest /
    archive / outcome-related object whose name could be classified by the
    Program 133 stage-boundary test.

Writes:
    None.
============================================================================ */

WITH candidate_columns AS
(
    SELECT
        c.table_schema,
        c.table_name,
        c.ordinal_position,
        c.column_name,
        c.data_type,

        CASE
            WHEN lower(c.column_name) IN
            (
                'decision_outcome',
                'decision_outcome_code',
                'decision_path',
                'strategy_outcome',
                'strategy_outcome_code',

                'approval',
                'approval_flag',
                'approved_amount',

                'counteroffer',
                'counteroffer_flag',
                'counteroffer_amount',

                'decline',
                'decline_flag',

                'manual_review',
                'manual_review_flag',

                'offer',
                'offer_amount',
                'simulated_offer_exposure_flag',

                'price',
                'pricing',
                'factor_rate',
                'apr',
                'term',

                'funding_amount',
                'funding_status',
                'remittance_rate',

                'adverse_action',
                'booking',
                'booking_status'
            )
                THEN 'EXACT_DOWNSTREAM_FIELD_NAME'

            WHEN lower(c.column_name) ~
                 '(decision|outcome|approv|counter|declin|manual_review)'
                THEN 'DECISION_OR_OUTCOME_NAME_PATTERN'

            WHEN lower(c.column_name) ~
                 '(offer|price|pricing|factor|apr|term)'
                THEN 'PRICING_OR_OFFER_NAME_PATTERN'

            WHEN lower(c.column_name) ~
                 '(fund|remit|book|adverse)'
                THEN 'FUNDING_OR_BOOKING_NAME_PATTERN'

            WHEN lower(c.column_name) ~
                 '(approved|exposure)'
                THEN 'APPROVED_EXPOSURE_NAME_PATTERN'

            ELSE NULL
        END AS suspected_reason,

        CASE
            WHEN lower(c.table_name) ~
                 '(definition|catalog|reference|dictionary)'
                THEN 'REFERENCE_OR_DEFINITION_OBJECT'

            WHEN lower(c.table_name) ~
                 '(gate|snapshot|latest|archive|output|contract|result)'
                THEN 'ROW_LEVEL_OR_CONSUMPTION_OBJECT'

            ELSE 'OTHER_RELATED_OBJECT'
        END AS object_role_hint

    FROM information_schema.columns AS c

    WHERE c.table_schema NOT IN
    (
        'pg_catalog',
        'information_schema'
    )

      AND lower(c.table_name) ~
          '(m2|strategy|campaign|gate|profile|snapshot|latest|archive|registry|outcome|reason|decision)'
)

SELECT
    table_schema,
    table_name,
    ordinal_position,
    column_name,
    data_type,
    suspected_reason,
    object_role_hint

FROM candidate_columns

WHERE suspected_reason IS NOT NULL

ORDER BY
    CASE object_role_hint
        WHEN 'ROW_LEVEL_OR_CONSUMPTION_OBJECT' THEN 1
        WHEN 'REFERENCE_OR_DEFINITION_OBJECT' THEN 2
        ELSE 3
    END,
    table_schema,
    table_name,
    ordinal_position;
```

This should expose fields the first query missed, especially possibilities such as:

```text
outcome_code
strategy_outcome_code
recommended_outcome_code
manual_review_flag
approved_exposure_flag
```

or a relevant column in a table named simply:

```text
strategy_snapshot
strategy_latest
strategy_archive
```

rather than a table containing `m2_1`.

## If that broader query is also empty

Run this inventory query. It deliberately applies **no column-name filter** and will reveal every physical column in the objects that Program 133 is likely inspecting:

```sql
/* ============================================================================
M2.1 related-object physical column inventory

Writes:
    None.
============================================================================ */

SELECT
    c.table_schema,
    c.table_name,
    c.ordinal_position,
    c.column_name,
    c.data_type,
    c.is_nullable

FROM information_schema.columns AS c

WHERE c.table_schema NOT IN
(
    'pg_catalog',
    'information_schema'
)

  AND lower(c.table_name) ~
      '(m2|strategy|campaign|gate|profile|snapshot|latest|archive|registry|outcome|reason|decision)'

ORDER BY
    c.table_schema,
    c.table_name,
    c.ordinal_position;
```

## Most important next step

The zero-row result makes the **exact Program 133 source necessary** before changing the preflight. Please attach either:

```text
133_msbf_m2_1_preflight_validation_v0_2.sql
```

or, preferably:

```text
MSBF_M2_1_v0_2.zip
```

The live package is demonstrably the design with:

```text
1 strategy campaign
12 gate definitions
23 reason codes
4 outcome definitions
```

so I should audit and correct that exact executable source rather than continue inferring its predicate from the error summary.

The database remains safely at:

```text
M1_17_ACCEPTED
M2.1 schema/reference extension committed
M2.1 application-level generation rows = 0
```

No database repair or status reset is appropriate at this point.
<!-- END_SOURCE_MESSAGE -->


<a id="m-007c9e39-31b5-4f3b-8f8a-68fc2f7ae74e"></a>
## Andrew / user · C068-M00392

C068-M00392 · 2026-07-29T19:08:33.628000-04:00 · active path

Preceding visible parent: [C068-M00391](part-30.md#m-180e4f28-3104-496b-bfad-1d4a9b41b392)

**Editorial record note:** Attachment references: m2_1_broad_prohibited_column_diagnostic_v0_2_20260729.csv; m2_1_related_object_physical_column_inventory_v0_2_20260729.csv

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-6392ecd5-8d61-4420-9432-e38965c5465a"></a>
## Assistant · C068-M00393

C068-M00393 · 2026-07-29T19:22:56.933789-04:00 · active path

Preceding visible parent: [C068-M00392](part-30.md#m-007c9e39-31b5-4f3b-8f8a-68fc2f7ae74e)

<!-- BEGIN_SOURCE_MESSAGE -->
## The diagnostics now identify the defect

The first diagnostic returned no rows because its exact-name list did **not** include the field that the live M2.1 design actually uses:

```text
eligible_for_offer_design_flag
```

The broader diagnostic found that field in these M2.1 objects:

| Object | Position | Role |
|---|---:|---|
| `msbf_m2.application_eligibility_routing_snapshot` | 37 | Persisted application-level routing snapshot |
| `msbf_m2.application_eligibility_routing_latest` | 20 | Persisted latest consumption contract |
| `msbf_m2.routing_outcome_definition` | 6 | Governed outcome-definition catalog |
| `msbf_m2.v_m2_1_eligibility_latest` | 20 | Read-only view |
| `msbf_m2.v_m2_1_power_bi_routing` | 11 | Read-only reporting view |

Open the broad prohibited-column diagnostic (historical reference: `sandbox:[session]/m2_1_broad_prohibited_column_diagnostic_v0_2_20260729.csv`; referenced bytes not established here)

Open the complete M2.1-related physical-column inventory (historical reference: `sandbox:[session]/m2_1_related_object_physical_column_inventory_v0_2_20260729.csv`; referenced bytes not established here)

Program 132 also confirms that the actual executable design consists of one strategy campaign, 12 gate definitions, 23 reason codes, and four routing-outcome definitions, and that its schema/policy extension passed. [export reference: filecite | turn68file11]

# Final diagnosis

`prohibited_columns = 1` is a **false-positive preflight-scope defect**.

The unique offending **column name** is almost certainly:

```text
eligible_for_offer_design_flag
```

It occurs physically more than once, but Program 133 likely counts either:

- distinct prohibited column names; or
- the latest consumption table only.

That explains why the preflight reports `1` rather than every physical occurrence.

## Why this field is valid in M2.1

This field does **not** contain:

- an offer;
- an offer amount;
- a factor rate;
- a remittance rate;
- a term;
- an approval;
- a counteroffer;
- a decline;
- a booking or funding result.

Its meaning is:

> The record has passed the M2.1 eligibility and routing foundation and may proceed to a later governed offer-design stage.

That is exactly the boundary M2.1 is supposed to establish. It is a **handoff eligibility indicator**, not an offer-design output.

The distinction is:

```text
eligible_for_offer_design_flag
= M2.1 routing eligibility
= permitted

offer_amount / factor_rate / remittance_rate / term
= actual offer construction
= prohibited in M2.1
```

# Other diagnostic matches are not defects

The broad query intentionally overmatched names across the project. These M2.1 fields are also legitimate:

```text
gate_outcome
gate_outcome_rank
decision_influence_code
terminal_flag
outcome_definition_rows
outcome_definition_set_hash
```

They describe routing rules, outcomes, governance, counts, and lineage. They are not final customer credit decisions.

Likewise:

```text
production_adverse_action_flag
```

on `reason_code_definition` is a governance-control flag. It identifies whether a synthetic internal reason is approved for production adverse-action use; it is not itself an adverse-action output. Given the project boundary, its expected value should presumably remain false.

# Correct Program 133 control

The prohibited-column test should be limited to **actual downstream offer, exposure-treatment, and final-decision fields** in application-level outputs.

A defensible predicate would be:

```sql
SELECT COUNT(DISTINCT c.column_name)
FROM information_schema.columns AS c
WHERE c.table_schema = 'msbf_m2'

  AND c.table_name IN
  (
      'application_policy_gate_result',
      'application_eligibility_routing_snapshot',
      'application_eligibility_routing_latest',
      'application_eligibility_routing_archive'
  )

  AND lower(c.column_name) IN
  (
      /* Final decision outcomes */
      'decision_outcome',
      'decision_path',
      'approval_flag',
      'counteroffer_flag',
      'decline_flag',

      /* Actual offer or approved-exposure fields */
      'offer_amount',
      'approved_amount',
      'counteroffer_amount',
      'factor_rate',
      'apr',
      'term',
      'remittance_rate',
      'approved_monthly_payment_proxy',
      'approved_payment_to_income_ratio',
      'approved_expected_loss_amount',

      /* Booking, funding and external-action fields */
      'booking_status',
      'funding_status',
      'adverse_action_code'
  );
```

It should **not** prohibit:

```text
eligible_for_offer_design_flag
gate_outcome
gate_outcome_rank
final_route_code
final_route_rank
reason_code fields
routing_evidence_status
```

Those are core M2.1 outputs.

# Database disposition

No schema rollback or data deletion is appropriate.

The safe state remains:

```text
M1.17 / G2 source                ACCEPTED
M2.1 schema and references       COMMITTED
M2.1 policy                      APPROVED

Application gate-result rows     0
Routing snapshot rows            0
Latest rows                      0
Archive rows                     0
Contract-registry rows           0
Evidence rows                    0
Acceptance rows                  0
```

Do not:

```text
drop eligible_for_offer_design_flag
rename it
manually bypass the preflight
continue to Program 134
rerun Program 132
```

The correction belongs in Program 133 and should be audited through Programs 134–139 for the same overbroad stage-boundary predicate.

To produce the consolidated version-aligned hotfix safely, attach the exact executable `133_msbf_m2_1_preflight_validation_v0_2.sql` or the `MSBF_M2_1_v0_2.zip` package.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9f630b87-5181-434d-99a7-8c217711df3b"></a>
## Andrew / user · C068-M00394

C068-M00394 · 2026-07-29T20:02:19.920000-04:00 · active path

Preceding visible parent: [C068-M00393](part-30.md#m-6392ecd5-8d61-4420-9432-e38965c5465a)

**Editorial record note:** Attachment references: MSBF_M2_1_v0_2.zip

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-7b2414ab-7144-48cd-b550-e16954f21b3b"></a>
## Assistant · C068-M00395

C068-M00395 · 2026-07-29T20:59:39.558161-04:00 · active path

Preceding visible parent: [C068-M00394](part-30.md#m-9f630b87-5181-434d-99a7-8c217711df3b)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.1 v0.2R1 consolidated hotfix completed

I audited the **exact M2.1 package you uploaded**, including Programs 132–139, both contingency programs, the catalogs, and the physical-column diagnostics.

Open the exact uploaded M2.1 v0.2 source package (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2.zip`; referenced bytes not established here)

```text
Uploaded source-package SHA-256
993fc41487fab14016ae26fb68fc5c13e04fe3fac6446969747ce14a45f4a537

Uploaded files
50

ZIP CRC
PASS
```

## Conclusive root cause

The original Program 133 used this overbroad predicate:

```sql
SELECT count(*)
FROM information_schema.columns
WHERE table_schema = 'msbf_m2'
  AND lower(column_name) ~
      '(apr|factor_rate|approved_amount|offer_amount|
        remittance_rate|adverse_action|funded_outcome)';
```

The single match behind:

```text
prohibited_columns = 1
```

was **not**:

```text
eligible_for_offer_design_flag
```

The exact matching column was:

```text
msbf_m2.reason_code_definition.production_adverse_action_flag
```

That is a legitimate **governance dictionary field**. Its purpose is to prove that M2.1’s synthetic internal routing reasons are not approved production adverse-action notices. All 23 reason definitions carry:

```text
production_adverse_action_flag = false
```

Therefore, Program 133 incorrectly treated a control designed to enforce the stage boundary as though it violated the stage boundary.

The correct distinction is:

```text
production_adverse_action_flag
on a governed reference dictionary
= permitted and required to remain false

adverse_action_code / adverse_action_notice
on an application-level output
= prohibited in M2.1
```

# Additional downstream defect corrected

The complete source audit identified one material gate-logic issue before application-level generation began.

The accepted source domain includes:

```text
processor_continuity_status = UNAVAILABLE
```

The original GATE_05 logic was:

```sql
CASE
    WHEN processor_continuity_status IS NULL
        THEN 'BLOCKED'
    WHEN processor_continuity_status IN ('WATCH', 'DISRUPTED')
        THEN 'REVIEW'
    ELSE 'PASS'
END
```

That caused `UNAVAILABLE` to fall through to `PASS`.

The corrected logic is:

```text
STABLE or MONITORED
→ PASS

WATCH, DISRUPTED, or UNAVAILABLE
→ REVIEW

Missing
→ BLOCKED
```

The gate-definition dictionary, Program 134 generation, Program 135 validation, Program 137 acceptance, and Program 139 reporting now all enforce that same interpretation.

This correction does not change any expected cardinality, contract grain, canonical-entity count, or acceptance threshold. No M2.1 application-level rows have been generated yet, so this is the correct point to repair the rule.

---

# Download the complete v0.2R1 hotfix

## Recommended package

Download M2.1 v0.2R1 — Stage-Boundary Preflight & Downstream Audit Hotfix (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
3c537a617543afa860e9cbec147d992fcf11e6740a45972ba3260debba1e05db

Archive size
Approximately 407 KB

Files
119
```

Canonical byte-identical copy:

Download the canonical M2.1 v0.2R1 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R1_stage_boundary_preflight_downstream_audit_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R1_stage_boundary_preflight_downstream_audit_hotfix.zip.sha256`; referenced bytes not established here)

## Package organization

```text
live_recovery
Corrected programs for the current database state

clean_build
Complete synchronized M2.1 v0.2R1 source package

source_history
Exact uploaded v0.2 package preserved unchanged

evidence_inputs
Program 132 checkpoint and both physical-column diagnostics
```

## Key files

- 132B — Failed-preflight recovery and reference repair (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/tests/132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1.sql`; referenced bytes not established here)
- 133 — Corrected hard-stop preflight (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/tests/133_msbf_m2_1_preflight_validation_v0_2R1.sql`; referenced bytes not established here)
- 134 — Corrected deterministic generation (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/sql/134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R1.sql`; referenced bytes not established here)
- 134A — Generation-result reconstruction (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/tests/134A_msbf_m2_1_generation_reconciliation_reconstructed_v0_2R1.sql`; referenced bytes not established here)
- 135 — Corrected positive validation (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/sql/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R1.sql`; referenced bytes not established here)
- 136 — Negative controls (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/sql/136_msbf_m2_1_negative_control_tests_v0_2R1.sql`; referenced bytes not established here)
- 137 — Strengthened acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/sql/137_msbf_m2_1_acceptance_finalize_v0_2R1.sql`; referenced bytes not established here)
- 138 — Master report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/tests/138_MSBF_M2_1_Master_Report_v0_2R1.sql`; referenced bytes not established here)
- 139 — Detailed report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/tests/139_MSBF_M2_1_Detail_Report_v0_2R1.sql`; referenced bytes not established here)
- Execution guide (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/docs/M2_1_v0_2R1_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/docs/M2_1_v0_2R1_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# Exact recovery and execution sequence

## 1. Stop and roll back failed Program 133

In DBeaver, click:

```text
Stop
```

Do not select:

```text
Retry
Skip
Skip All
```

Then execute:

```sql
ROLLBACK;
```

Do **not** rerun Program 132. Its schema, policy, campaign, gate, reason, and outcome reference records committed successfully.

## 2. Run Program 132B

```text
132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1.sql
```

Program 132B verifies:

- the accepted source run remains `M1_17_ACCEPTED`;
- the M2.1 policy is approved;
- the original broad predicate finds exactly one column;
- that column is the governed adverse-action dictionary flag;
- all 23 dictionary values remain false;
- the corrected application-output predicate finds zero prohibited columns;
- all M2.1 application-level targets remain empty;
- no M2.1 evidence or acceptance result exists;
- no blocking error or M2.2 table exists.

It then updates only the GATE_05 reference definition so that `UNAVAILABLE` is reviewable rather than passing and reconstructs its physical row hash.

Required result:

```text
run_status
M1_17_ACCEPTED

policy_status
APPROVED

original_broad_prohibited_columns
1

adverse_action_governance_columns
1

production_adverse_action_rows
0

corrected_prohibited_application_columns
0

gate_rows
0

snapshot_rows
0

latest_rows
0

archive_rows
0

registry_rows
0

evidence_rows
0

acceptance_rows
0

blocking_errors
0

m2_2_tables
0

prior_g5_review_rule
WATCH or DISRUPTED

final_g5_review_rule
WATCH, DISRUPTED, or UNAVAILABLE

final_g5_row_hash
non-null

final_g5_hash_mismatches
0

recovery_status
PASS
```

Stop if `recovery_status` is not `PASS`.

## 3. Run corrected Program 133

```text
133_msbf_m2_1_preflight_validation_v0_2R1.sql
```

Required key fields:

```text
run_status                         M1_17_ACCEPTED
policy_status                      APPROVED

source_g2_bundle_status            ACCEPTED
source_g2_combined_hash            7d9e466da28cad2551aa99c4c40c912b
g2_gate_status                     PASS

input_rows                         1,500
applications                       750
scenarios                          2
baseline_rows                      750
stress_rows                        750

campaign_rows                      1
gate_definition_rows               12
reason_rows                        23
outcome_rows                       4

target_gate_rows                   0
target_snapshot_rows               0
target_latest_rows                 0
target_archive_rows                0
target_registry_rows               0
evidence_rows                      0
acceptance_rows                    0
blocking_errors                    0
m2_2_tables                        0

prohibited_columns                 0
adverse_action_governance_columns  1
production_adverse_action_rows     0

preflight_status                   PASS
```

Do not proceed unless the preflight returns `PASS`.

## 4. Run corrected Program 134

```text
134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R1.sql
```

Required generation checkpoint:

```text
run_status                   M2_1_GENERATED

strategy_campaign_rows       1
gate_definition_rows         12
reason_code_rows             23
outcome_definition_rows      4

gate_result_rows             18,000
routing_snapshot_rows         1,500
latest_rows                   1,500
archive_rows                  1,500
comparison_rows                 750

canonical_entities           22,541
row_level_mismatches              0

campaign_set_hash            non-null
gate_definition_set_hash     non-null
reason_code_set_hash         non-null
outcome_definition_set_hash  non-null
gate_result_set_hash         non-null
routing_snapshot_set_hash    non-null
latest_set_hash              non-null
archive_set_hash             non-null
contract_set_hash            non-null
combined_set_hash            non-null

generation_status            PASS
```

Program 134 now has a hard guard requiring every source record with:

```text
processor_continuity_status = UNAVAILABLE
```

to receive:

```text
GATE_05_PROCESSOR_CONTINUITY = REVIEW
```

After Program 134 commits successfully, do not rerun it.

## 5. Run Program 135 v0.2R1

```text
135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R1.sql
```

Required:

```text
112 positive controls
112 PASS
0 FAIL

run_status
M2_1_VALIDATED

contract_status
VALIDATED
```

The corrected controls preserve the distinction between:

```text
Governance dictionary field
production_adverse_action_flag
→ permitted, but every value must be false

Application-level adverse-action output
→ prohibited
```

## 6. Run Program 136 v0.2R1

```text
136_msbf_m2_1_negative_control_tests_v0_2R1.sql
```

Required:

```text
20 negative controls
20 PASS
0 FAIL

run_status remains
M2_1_VALIDATED
```

## 7. Run Program 137 v0.2R1

```text
137_msbf_m2_1_acceptance_finalize_v0_2R1.sql
```

The finalizer independently requires:

```text
112 / 112 positive PASS
20 / 20 negative PASS

Gate results                     18,000
Routing snapshots                1,500
Latest rows                      1,500
Archive rows                     1,500
Matched comparisons                750
Canonical entities              22,541

Stress route improvements             0
Acquisition-driven decline gates      0
Acquisition decline reasons           0
Prohibited application columns        0
Production adverse-action flags       0
UNAVAILABLE continuity mismatches     0
Physical hash mismatches              0
Archive reproduction mismatches       0
```

Required final state:

```text
final_run_status
M2_1_ACCEPTED

final_contract_status
ACCEPTED

gate_status
PASS

acceptance_status
PASS
```

## 8. Run Programs 138 and 139 v0.2R1

```text
138_MSBF_M2_1_Master_Report_v0_2R1.sql

139_MSBF_M2_1_Detail_Report_v0_2R1.sql
```

Required master result:

```text
overall_m2_1_status = PASS
```

Program 139 must produce 24 governed result sets.

These final outputs must retain their headers and contain zero data rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

---

# What was not changed

The hotfix does not change:

- the accepted M1.17 or G2 source;
- the 1,500-row G2 input population;
- the one strategy campaign;
- the 12-gate architecture;
- the 23-reason-code inventory;
- the four routing outcomes;
- the route-rank hierarchy;
- the acquisition-source review-only boundary;
- the stress non-improvement floor;
- expected physical counts;
- the 22,541-entity canonical universe;
- positive- or negative-control counts;
- latest/archive grains;
- acceptance thresholds.

The only gate-logic change is the correction of an impossible favorable interpretation:

```text
UNAVAILABLE processor continuity
PASS  →  REVIEW
```

Programs 136, 134A, and 138 are executable-logic equivalent to their original v0.2 sources apart from revision headers.

# Package QA

```text
Uploaded source CRC                         PASS
Original uploaded source preserved         PASS

Positive controls                           112
Negative controls                            20
Detailed-report result sets                  24

Old broad Program 133 predicate remaining     0
Scoped stage-boundary predicate             PASS
Governance adverse-action control           PASS
Processor UNAVAILABLE generation rule       PASS
Processor UNAVAILABLE validation rule       PASS
Acceptance direct guards                    PASS
Detailed-report direct guards               PASS

Operational USING joins                       0
Session random() calls                         0
DBeaver-sensitive braced hash regex            0
Concatenated PL/pgSQL RAISE syntax             0
Transaction control inside PL/pgSQL blocks     0
SQL lexical findings                           0

Hotfix ZIP CRC                              PASS
Complete extraction                         PASS
Manifest and SHA-256 inventory              PASS
```

The next controlled action is:

```text
ROLLBACK failed Program 133
→ 132B
→ 133 v0.2R1
→ 134–139 v0.2R1
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-005f4d69-ac3c-43fa-929b-c2e9e18e5860"></a>
## Andrew / user · C068-M00396

C068-M00396 · 2026-07-29T21:05:51.321000-04:00 · active path

Preceding visible parent: [C068-M00395](part-30.md#m-7b2414ab-7144-48cd-b550-e16954f21b3b)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(192).png; image(193).png

<!-- BEGIN_SOURCE_MESSAGE -->
where is 132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1.sql? I see the following programs:
<!-- END_SOURCE_MESSAGE -->


<a id="m-1824a087-a8ca-40c1-b04f-a7dd93266ac0"></a>
## Assistant · C068-M00397

C068-M00397 · 2026-07-29T21:05:55.470801-04:00 · active path

Preceding visible parent: [C068-M00396](part-30.md#m-005f4d69-ac3c-43fa-929b-c2e9e18e5860)

<!-- BEGIN_SOURCE_MESSAGE -->
`132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1.sql` is **not inside `clean_build`**.

It is located here:

```text
MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix
└── live_recovery
    └── tests
        └── 132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1.sql
```

Open Program 132B directly (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R1_Stage_Boundary_Preflight_Downstream_Audit_Hotfix/live_recovery/tests/132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1.sql`; referenced bytes not established here)

The package intentionally separates two execution contexts:

| Folder | Purpose |
|---|---|
| `live_recovery` | Programs for **your current database**, where original Program 132 already committed and Program 133 failed |
| `clean_build` | Complete synchronized source for a **brand-new execution**, where corrected Program 132 v0.2R1 runs from the beginning |

Therefore, for your current database, use:

```text
live_recovery\tests\132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1.sql
```

Then continue with the other programs under `live_recovery`:

```text
live_recovery\tests\133_msbf_m2_1_preflight_validation_v0_2R1.sql
live_recovery\sql\134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R1.sql
live_recovery\sql\135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R1.sql
live_recovery\sql\136_msbf_m2_1_negative_control_tests_v0_2R1.sql
live_recovery\sql\137_msbf_m2_1_acceptance_finalize_v0_2R1.sql
live_recovery\tests\138_MSBF_M2_1_Master_Report_v0_2R1.sql
live_recovery\tests\139_MSBF_M2_1_Detail_Report_v0_2R1.sql
```

Do **not** run the clean-build Program 132 again against your current database. The clean-build folder correctly contains `132`, while the live-recovery folder contains the additional `132B` recovery program.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2d561894-8f6d-4426-92b4-ae71f148e5e9"></a>
## Andrew / user · C068-M00398

C068-M00398 · 2026-07-29T21:14:58.854000-04:00 · active path

Preceding visible parent: [C068-M00397](part-30.md#m-1824a087-a8ca-40c1-b04f-a7dd93266ac0)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(194).png; 133_msbf_m2_1_preflight_validation_v0_2R1_results_20260729.csv; 132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1_results_20260729.csv; 134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R1_results_20260729.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R1.sql:
<!-- END_SOURCE_MESSAGE -->
