# Merchant POS Lending Simulator

Part 31 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-30.md)
[Next part](part-32.md)

<a id="m-dc6d6ac5-05e4-4b06-8245-c5c8db108575"></a>
## Assistant · C068-M00399

C068-M00399 · 2026-07-29T21:21:25.332628-04:00 · active path

Preceding visible parent: [C068-M00398](part-30.md#m-2d561894-8f6d-4426-92b4-ae71f148e5e9)

<!-- BEGIN_SOURCE_MESSAGE -->
# Diagnosis

Program 134 completed successfully and committed the M2.1 generated population:

```text
run_status                    M2_1_GENERATED

strategy campaign rows        1
gate-definition rows          12
reason-code rows              23
outcome-definition rows       4

gate-result rows              18,000
routing-snapshot rows          1,500
latest rows                    1,500
archive rows                   1,500
comparison rows                  750

canonical entities            22,541
row-level mismatches                0
generation_status             PASS
```

The Program 135 failure is a **SQL syntax defect in the validation source**, not a defect in the generated data.

## Exact defect

Program 135 contains 37 Boolean validation expressions written in this malformed form:

```sql
coalesce(((SELECT ...))), false)
```

The extra closing parentheses terminate `coalesce()` before PostgreSQL reaches its second argument, producing:

```text
SQLSTATE 42601
mismatched parentheses at or near ";"
```

The valid form is:

```sql
coalesce((SELECT ...), false)
```

The first parser failure occurred around the gate-result set-hash validation, but the same malformed pattern existed in 37 controls. All 37 were corrected together.

Do **not** rerun Program 134.

---

# M2.1 v0.2R2 consolidated hotfix

Download M2.1 v0.2R2 — Validation Parenthesis & Downstream Audit Hotfix (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
93085c77e96057a6306490dd9c7a64c796e47fdc332490112d1c8baed1cc9c30
```

Canonical copy:

Download the canonical v0.2R2 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R2_validation_parenthesis_downstream_audit_hotfix.zip`; referenced bytes not established here)

## Key files

- 132C — Generated-state recovery check (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/tests/132C_msbf_m2_1_failed_validation_parenthesis_recovery_check_v0_2R2.sql`; referenced bytes not established here)
- 135 — Corrected positive validation (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/sql/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R2.sql`; referenced bytes not established here)
- 136 — Negative controls (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/sql/136_msbf_m2_1_negative_control_tests_v0_2R2.sql`; referenced bytes not established here)
- 137 — Acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/sql/137_msbf_m2_1_acceptance_finalize_v0_2R2.sql`; referenced bytes not established here)
- 138 — Master report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/tests/138_MSBF_M2_1_Master_Report_v0_2R2.sql`; referenced bytes not established here)
- 139 — Detailed report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/tests/139_MSBF_M2_1_Detail_Report_v0_2R2.sql`; referenced bytes not established here)
- Execution guide (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/docs/M2_1_v0_2R2_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/docs/M2_1_v0_2R2_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Exact source diff (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/docs/M2_1_v0_2R2_SOURCE_DIFF.txt`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

# Exact recovery sequence

## 1. Stop the failed Program 135

Click:

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

Because the error was a parse-time syntax error, a “no transaction in progress” notice would be harmless.

## 2. Run Program 132C

```text
132C_msbf_m2_1_failed_validation_parenthesis_recovery_check_v0_2R2.sql
```

This is read-only.

Required result:

```text
run_status                    M2_1_GENERATED
contract_status               GENERATED

strategy_campaign_rows        1
gate_definition_rows          12
reason_code_rows              23
outcome_definition_rows       4

gate_result_rows              18,000
routing_snapshot_rows          1,500
latest_rows                    1,500
archive_rows                   1,500
comparison_rows                  750
canonical_entities            22,541

all set hashes                non-null

positive_evidence_rows             0
negative_evidence_rows             0
acceptance_rows                    0
blocking_errors                    0
prohibited_application_columns     0

recovery_status                PASS
```

Stop if `recovery_status` is not `PASS`.

## 3. Run corrected Program 135

```text
135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R2.sql
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

The validation output remains filterable in the same DBeaver session.

## 4. Continue with v0.2R2 Programs 136–139

```text
136_msbf_m2_1_negative_control_tests_v0_2R2.sql

137_msbf_m2_1_acceptance_finalize_v0_2R2.sql

138_MSBF_M2_1_Master_Report_v0_2R2.sql

139_MSBF_M2_1_Detail_Report_v0_2R2.sql
```

Expected final results:

```text
Program 136
20 / 20 negative controls PASS

Program 137
run_status       M2_1_ACCEPTED
contract_status  ACCEPTED
gate_status      PASS
acceptance_status PASS

Program 138
overall_m2_1_status = PASS

Program 139
24 governed result sets
```

The final detailed-report outputs must retain their headers and contain zero rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

# Logic preservation

The hotfix changes only the malformed parenthesis structure in Program 135.

It does not change:

- the committed 18,000 gate results;
- the 1,500 routing snapshots;
- latest, archive, or comparison records;
- any gate outcome;
- any route or reason code;
- the processor-continuity correction;
- any source record;
- any set hash;
- the 22,541 canonical-entity universe;
- any positive-control condition or threshold;
- negative controls;
- acceptance logic;
- reports.

Programs 136–139 are executable-logic equivalent to their v0.2R1 versions apart from revision headers.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0fefaf76-4853-4114-9270-18d8208fe0bd"></a>
## Andrew / user · C068-M00400

C068-M00400 · 2026-07-29T21:26:49.073000-04:00 · active path

Preceding visible parent: [C068-M00399](part-31.md#m-dc6d6ac5-05e4-4b06-8245-c5c8db108575)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(195).png

<!-- BEGIN_SOURCE_MESSAGE -->
error in 132C_msbf_m2_1_failed_validation_parenthesis_recovery_check_v0_2R2.sql:
<!-- END_SOURCE_MESSAGE -->


<a id="m-2c943c90-7aee-4e10-93c1-6bf1f33e9fc5"></a>
## Assistant · C068-M00401

C068-M00401 · 2026-07-29T21:53:42.376345-04:00 · active path

Preceding visible parent: [C068-M00400](part-31.md#m-0fefaf76-4853-4114-9270-18d8208fe0bd)

<!-- BEGIN_SOURCE_MESSAGE -->
# Diagnosis

Program 132C contains an incorrect physical-object reference:

```sql
msbf_m2.application_eligibility_routing_comparison
```

That relation does not exist because M2.1 does **not** persist comparison rows in a separate table. Its 750 matched baseline/stress comparisons are derived from the accepted latest contract through the governed view:

```sql
msbf_m2.v_m2_1_matched_scenario_comparison
```

The correct count is therefore:

```sql
SELECT count(*)
FROM msbf_m2.v_m2_1_matched_scenario_comparison
WHERE module1_run_id = ...;
```

Program 132C is read-only. Its failure did not change the committed Program 134 population or lifecycle.

Your database should remain at:

```text
Run status                  M2_1_GENERATED
Contract status             GENERATED

Gate-result rows            18,000
Routing snapshots            1,500
Latest rows                  1,500
Archive rows                 1,500
Matched comparisons            750
Canonical entities          22,541
Deterministic mismatches          0

Positive evidence rows           0
Negative evidence rows           0
Acceptance rows                  0
```

## Important correction to the prior R2 package

Do **not** run any files from:

```text
MSBF_M2_1_v0_2R2_Validation_Parenthesis_Downstream_Audit_Hotfix
```

My prior diagnosis that 37 `coalesce()` expressions required rewriting was incorrect. That R2 transformation damaged otherwise valid expressions.

The authoritative v0.2R1 Program 135 has exactly **three** true parse defects:

```text
M2_1_POS_105_NO_PRICING_COLUMNS
M2_1_POS_106_NO_ADVERSE_ACTION_COLUMNS
M2_1_POS_107_NO_FUNDED_OUTCOME
```

Each observed-value subquery is missing one closing parenthesis before `::text`.

Conceptually, the malformed construction is:

```sql
((SELECT count(*)::text FROM ... )::text
```

The corrected construction is:

```sql
((SELECT count(*)::text FROM ... ))::text
```

The new v0.2R3 package restores Program 135 from the authoritative v0.2R1 source and changes only those three expressions.

# M2.1 v0.2R3 consolidated hotfix

Download M2.1 v0.2R3 — Recovery View & Validation Syntax Hotfix (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
25c02c6ed40efa845e0680b1b37081d5d392cda796d82b89c5ab07f0e8938f7d
```

Canonical copy:

Download the canonical v0.2R3 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R3_recovery_view_and_validation_syntax_hotfix.zip`; referenced bytes not established here)

## Key programs

- 132D — Generated-state recovery and comparison-view check (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/tests/132D_msbf_m2_1_generated_state_recovery_and_comparison_view_check_v0_2R3.sql`; referenced bytes not established here)
- 135 — Corrected positive validation (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/sql/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R3.sql`; referenced bytes not established here)
- 136 — Negative controls (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/sql/136_msbf_m2_1_negative_control_tests_v0_2R3.sql`; referenced bytes not established here)
- 137 — Acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/sql/137_msbf_m2_1_acceptance_finalize_v0_2R3.sql`; referenced bytes not established here)
- 138 — Master report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/tests/138_MSBF_M2_1_Master_Report_v0_2R3.sql`; referenced bytes not established here)
- 139 — Detailed report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/tests/139_MSBF_M2_1_Detail_Report_v0_2R3.sql`; referenced bytes not established here)
- Execution guide (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/docs/M2_1_v0_2R3_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/docs/M2_1_v0_2R3_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Exact Program 135 source diff (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/docs/M2_1_v0_2R3_SOURCE_DIFF.txt`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R3_Recovery_View_And_Validation_Syntax_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

# Exact execution sequence

## 1. Stop the failed Program 132C

Click:

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

A “no transaction in progress” notice is harmless because Program 132C is read-only.

## 2. Do not rerun successful upstream programs

Do **not** rerun:

```text
132
132B
133
134
```

Program 134’s committed generation remains authoritative.

Do not execute Program 135 from the v0.2R2 package.

## 3. Run Program 132D

Execute:

```text
132D_msbf_m2_1_generated_state_recovery_and_comparison_view_check_v0_2R3.sql
```

Required result:

```text
run_status                         M2_1_GENERATED
contract_status                    GENERATED

strategy_campaign_rows             1
gate_definition_rows              12
reason_code_rows                  23
outcome_definition_rows            4

gate_result_rows              18,000
routing_snapshot_rows          1,500
latest_rows                    1,500
archive_rows                   1,500
comparison_rows                  750
canonical_entities            22,541

campaign_set_hash             non-null
gate_definition_set_hash      non-null
reason_code_set_hash          non-null
outcome_definition_set_hash   non-null
gate_result_set_hash          non-null
routing_snapshot_set_hash     non-null
latest_set_hash               non-null
archive_set_hash              non-null
contract_set_hash             non-null
combined_set_hash             non-null

positive_evidence_rows              0
negative_evidence_rows              0
acceptance_rows                     0
blocking_errors                     0
prohibited_application_columns      0
unavailable_continuity_mismatches   0

recovery_status                  PASS
```

Program 132D uses:

```sql
msbf_m2.v_m2_1_matched_scenario_comparison
```

and does not attempt to query a nonexistent comparison table.

Stop if `recovery_status` is not `PASS`.

## 4. Run corrected Program 135

```text
135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R3.sql
```

Required:

```text
Positive controls             112
Positive passes               112
Positive failures               0

run_status
M2_1_VALIDATED

contract_status
VALIDATED
```

The output table remains filterable within the same DBeaver session.

## 5. Run Programs 136–139 v0.2R3

```text
136_msbf_m2_1_negative_control_tests_v0_2R3.sql

137_msbf_m2_1_acceptance_finalize_v0_2R3.sql

138_MSBF_M2_1_Master_Report_v0_2R3.sql

139_MSBF_M2_1_Detail_Report_v0_2R3.sql
```

Expected final results:

```text
Program 136
20 / 20 negative controls PASS

Program 137
final_run_status       M2_1_ACCEPTED
final_contract_status  ACCEPTED
gate_status            PASS
acceptance_status      PASS

Program 138
overall_m2_1_status = PASS

Program 139
24 governed result sets
```

The final two detailed-report outputs must retain their headers and contain zero data rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

# Package audit

The v0.2R3 package passed these source checks:

```text
Positive-control calls                          112
Unique positive-control codes                  112
Function arguments per validation call           6
Unbalanced validation-call lines                 0

Corrected controls:
M2_1_POS_105_NO_PRICING_COLUMNS
M2_1_POS_106_NO_ADVERSE_ACTION_COLUMNS
M2_1_POS_107_NO_FUNDED_OUTCOME

Nonexistent comparison-table references          0
Correct governed comparison-view reference      PASS

Programs 136–139 logic-equivalent to v0.2R1     PASS
Generation logic changed                        false
Generated data changed                          false
Business logic changed                          false

ZIP CRC                                         PASS
Complete extraction                             PASS
Manifest and SHA-256 inventory                  PASS
```

The R2 sources are retained under `source_history` solely to preserve the correction trail; they are not part of the execution sequence.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a907f01b-9955-4b09-9ac9-53da4a3a411b"></a>
## Andrew / user · C068-M00402

C068-M00402 · 2026-07-29T23:10:16.261000-04:00 · active path

Preceding visible parent: [C068-M00401](part-31.md#m-2c943c90-7aee-4e10-93c1-6bf1f33e9fc5)

**Editorial record note:** Attachment references: 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R3_results_20260729.csv; 132D_msbf_m2_1_generated_state_recovery_and_comparison_view_check_v0_2R3_results_20260729.csv

<!-- BEGIN_SOURCE_MESSAGE -->
1 positive failure: M2_1_POS_023_CAMPAIGN_HASH
<!-- END_SOURCE_MESSAGE -->


<a id="m-1a0998b3-1750-4efd-a261-325f30664da2"></a>
## Assistant · C068-M00403

C068-M00403 · 2026-07-29T23:34:06.288886-04:00 · active path

Preceding visible parent: [C068-M00402](part-31.md#m-a907f01b-9955-4b09-9ac9-53da4a3a411b)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.1 diagnosis: POS023 correctly identified a persisted campaign-hash defect

Program 134 remains valid and committed successfully. The generated population is intact:

```text
Run status                    M2_1_GENERATED
Contract status               GENERATED

Strategy campaigns            1
Gate definitions              12
Reason codes                  23
Routing outcomes              4

Gate-result rows              18,000
Routing snapshots              1,500
Latest rows                    1,500
Archive rows                   1,500
Matched comparisons              750
Canonical entities            22,541
Deterministic mismatches            0
```

Program 135 completed all 112 controls:

```text
Positive controls             112
PASS                          111
FAIL                            1

Sole failed control
M2_1_POS_023_CAMPAIGN_HASH

Observed mismatches              1
```

- Open the successful generated-state evidence (historical reference: `sandbox:[session]/132D_msbf_m2_1_generated_state_recovery_and_comparison_view_check_v0_2R3_results_20260729.csv`; referenced bytes not established here)
- Open the 112-control validation evidence (historical reference: `sandbox:[session]/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R3_results_20260729.csv`; referenced bytes not established here)

## Exact root cause

The campaign row was originally hashed from a seed CTE whose run identifier was named:

```text
run_id
```

The persisted physical table stores that field as:

```text
module1_run_id
```

The original generation used:

```sql
msbf_ctl.m2_1_hash_jsonb(to_jsonb(seed))
```

Therefore, the stored JSON identity contained:

```json
{"run_id": 1, ...}
```

The positive validation correctly reconstructed the physical row as:

```json
{"module1_run_id": 1, ...}
```

The value is the same, but the JSON key is different. Since the key name is part of the deterministic payload:

```text
original seed-record hash
≠
physical persisted-row hash
```

This is **not a validation-specification defect**. POS023 is correct. The persisted campaign hash must be repaired.

# Dependent hashes that must also change

The campaign row hash feeds several downstream identities:

```text
Campaign row_hash
       ↓
campaign_set_hash
       ↓
contract-registry row_hash
       ↓
contract_set_hash
       ↓
combined_set_hash
```

Two generation-evidence records also carry affected values:

```text
M2_1_CAMPAIGN_SET_HASH
M2_1_COMBINED_SET_HASH
```

Updating only `strategy_campaign.row_hash` would leave the contract registry and generation evidence internally inconsistent. The v0.2R4 recovery updates the complete dependency chain atomically.

No routing, gate, reason, eligibility, latest, archive, or comparison business record is regenerated or changed.

---

# M2.1 v0.2R4 consolidated hotfix

## Recommended package

Download M2.1 v0.2R4 — Campaign Physical Row-Hash Remediation Hotfix (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
b05371519e1f541649fedebf21ae40226e4bc6335e0f5f64c42561041784fa41

Archive size
Approximately 241 KB

Files
69
```

Canonical byte-identical copy:

Download the canonical M2.1 v0.2R4 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R4_campaign_physical_row_hash_remediation_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R4_campaign_physical_row_hash_remediation_hotfix.zip.sha256`; referenced bytes not established here)

## Key live-recovery programs

- 132E — Campaign physical-row-hash recovery (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/live_recovery/tests/132E_msbf_m2_1_failed_campaign_physical_row_hash_recovery_v0_2R4.sql`; referenced bytes not established here)
- 135 — Positive validation (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/live_recovery/sql/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R4.sql`; referenced bytes not established here)
- 136 — Negative controls (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/live_recovery/sql/136_msbf_m2_1_negative_control_tests_v0_2R4.sql`; referenced bytes not established here)
- 137 — Acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/live_recovery/sql/137_msbf_m2_1_acceptance_finalize_v0_2R4.sql`; referenced bytes not established here)
- 138 — Master report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/live_recovery/tests/138_MSBF_M2_1_Master_Report_v0_2R4.sql`; referenced bytes not established here)
- 139 — Detailed report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/live_recovery/tests/139_MSBF_M2_1_Detail_Report_v0_2R4.sql`; referenced bytes not established here)

Supporting records:

- Execution guide (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/docs/M2_1_v0_2R4_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and hash-dependency audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/docs/M2_1_v0_2R4_ROOT_CAUSE_AND_HASH_DEPENDENCY_AUDIT.md`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R4_Campaign_Physical_Row_Hash_Remediation_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# Exact execution sequence

## 1. Do not rerun Program 134

Program 134’s generated routing population is authoritative.

Do not rerun:

```text
132
132B
133
134
132D
135 v0.2R3
```

Program 135 completed normally and committed a governed failed-validation state. This was not a PostgreSQL execution exception, so **no rollback is required** before running the recovery.

The expected current state is:

```text
Run status                    M2_1_FAILED
Contract status               GENERATED
Positive evidence rows        112
Positive passes               111
Positive failures               1
Negative evidence rows          0
Acceptance rows                 0
```

## 2. Run Program 132E

Execute:

```text
132E_msbf_m2_1_failed_campaign_physical_row_hash_recovery_v0_2R4.sql
```

Program 132E first requires the exact one-failure state and independently proves:

```text
stored_campaign_row_hash
=
original_seed_alias_hash

stored_campaign_row_hash
≠
physical_campaign_row_hash
```

It also requires every other governed physical hash to remain valid.

### Required pre-remediation fields

```text
prior_run_status                 M2_1_FAILED
prior_contract_status            GENERATED

prior_positive_checks            112
prior_positive_passes            111
prior_positive_failures            1

failed_positive_codes
M2_1_POS_023_CAMPAIGN_HASH

reported_pos023_value            1

campaign_rows                    1
gate_definition_rows             12
reason_code_rows                 23
outcome_definition_rows          4
gate_result_rows                 18,000
routing_snapshot_rows            1,500
latest_rows                      1,500
archive_rows                     1,500
comparison_rows                    750

negative_evidence_rows           0
acceptance_rows                  0
blocking_errors                  0
```

### What Program 132E changes

It atomically recalculates:

```text
strategy_campaign.row_hash
campaign_set_hash
contract-registry row_hash
contract_set_hash
combined_set_hash
M2_1_CAMPAIGN_SET_HASH evidence
M2_1_COMBINED_SET_HASH evidence
```

It then:

- preserves the original POS023 finding as `SUPERSEDED` audit history;
- removes only stale `M2_1_POS_*` evidence;
- returns the run to `M2_1_GENERATED`;
- leaves every generated business record unchanged.

### Required final fields

```text
final_campaign_hash_mismatches        0
final_registry_hash_mismatches        0
generation_evidence_hash_mismatches   0

remaining_positive_evidence_rows      0
preserved_history_rows                1

final_run_status                      M2_1_GENERATED
final_contract_status                 GENERATED

recovery_status                       PASS
```

Stop immediately if `recovery_status` is not `PASS`.

## 3. Run Program 135 v0.2R4

```text
135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R4.sql
```

Required:

```text
112 positive controls
112 PASS
0 FAIL

M2_1_POS_023_CAMPAIGN_HASH
observed_value = 0
status = PASS

run_status
M2_1_VALIDATED

contract_status
VALIDATED
```

## 4. Run Program 136 v0.2R4

```text
136_msbf_m2_1_negative_control_tests_v0_2R4.sql
```

Required:

```text
20 negative controls
20 PASS
0 FAIL
```

## 5. Run Program 137 v0.2R4

```text
137_msbf_m2_1_acceptance_finalize_v0_2R4.sql
```

Required:

```text
Positive controls             112 / 112 PASS
Negative controls              20 / 20 PASS

Gate-result rows              18,000
Routing snapshots              1,500
Latest rows                    1,500
Archive rows                   1,500
Matched comparisons              750
Canonical entities            22,541

Physical hash mismatches            0
Archive reproduction mismatches     0
Blocking errors                     0

final_run_status             M2_1_ACCEPTED
final_contract_status        ACCEPTED
gate_status                  PASS
acceptance_status            PASS
```

## 6. Run Programs 138 and 139 v0.2R4

```text
138_MSBF_M2_1_Master_Report_v0_2R4.sql

139_MSBF_M2_1_Detail_Report_v0_2R4.sql
```

Required master-report field:

```text
overall_m2_1_status = PASS
```

Program 139 should return 24 governed result sets.

These final two must retain their headers and contain zero data rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

---

# Important hash-evidence note

The following hashes reported by the original Program 134 checkpoint were calculated from the old campaign seed hash:

```text
campaign_set_hash
contract_set_hash
combined_set_hash
```

They are valid **pre-remediation audit evidence**, but they will no longer be the final accepted M2.1 identities after Program 132E.

Retain the original Program 134 result as part of the correction history. Use the corrected hashes returned by Program 132E, Program 135, Program 137, and Program 138 as the final governed identities.

# Clean-build correction

The package also contains a complete synchronized clean-build module:

```text
clean_build\
MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_v0_2R4
```

Its Program 132 no longer hashes the temporary seed record directly. It constructs the campaign hash using the exact persisted physical field name:

```text
module1_run_id
```

This prevents the same defect on any future pristine execution.

No gate logic, route, reason, eligibility result, stage boundary, expected cardinality, or acceptance threshold changed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-208c9823-07bd-45f3-8cf3-37c177b6b14a"></a>
## Andrew / user · C068-M00404

C068-M00404 · 2026-07-30T06:20:28.721000-04:00 · active path

Preceding visible parent: [C068-M00403](part-31.md#m-1a0998b3-1750-4efd-a261-325f30664da2)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(196).png; 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R4_results_20260730.csv; 132E_msbf_m2_1_failed_campaign_physical_row_hash_recovery_v0_2R4_results_20260730.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 136_msbf_m2_1_negative_control_tests_v0_2R4.sql:
<!-- END_SOURCE_MESSAGE -->


<a id="m-7463e9bd-e47c-46f2-8dbc-5dad4cc8d4e5"></a>
## Assistant · C068-M00405

C068-M00405 · 2026-07-30T06:48:05.769414-04:00 · active path

Preceding visible parent: [C068-M00404](part-31.md#m-208c9823-07bd-45f3-8cf3-37c177b6b14a)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.1 diagnosis: two boundary controls were not enforced by the configuration assertion

Program 135 v0.2R4 completed successfully:

```text
Positive controls          112
Positive passes            112
Positive failures            0

Run status                 M2_1_VALIDATED
Contract status            VALIDATED
```

Open the successful Program 135 evidence (historical reference: `sandbox:[session]/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R4_results_20260730.csv`; referenced bytes not established here)

The Program 136 source audit isolates the two nonpassing negative controls to:

```text
M2_1_NEG_004_FINAL_OFFER_BOUNDARY
M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY
```

## Exact root cause

Those controls temporarily change these physical policy fields:

```text
no_final_offer_terms_flag
acquisition_source_review_only_flag
```

and then call:

```sql
msbf_ctl.m2_1_assert_configuration(...)
```

The prior assertion checked:

- policy status;
- methodology, contract, and schema identities;
- source G2 hash;
- expected counts;
- `configuration_hash = hash(configuration_payload)`.

It did **not** compare the physical boundary columns to the approved configuration payload.

Therefore, the negative controls created this temporary state:

```text
Physical column                         false
Governed configuration payload          true
Configuration payload hash              still valid
```

Because the payload itself was unchanged, its hash remained valid, and the old assertion did not reject the physical drift.

That explains the exact outcome:

```text
18 controls rejected correctly
2 boundary mutations were not rejected
```

This is an assertion-layer defect. It is not a defect in:

- the 18,000 gate results;
- 1,500 routing snapshots;
- latest or archive contracts;
- matched scenario comparisons;
- route or reason logic;
- the 22,541 canonical-entity population;
- the repaired campaign or combined hashes;
- any accepted Module 1 or G2 record.

# Transactional impact

Program 136 runs inside one explicit transaction. The final 18-of-20 inventory exception aborted that transaction.

The individual mutations were also contained inside PL/pgSQL exception subtransactions. Consequently, none of the test mutations persisted.

After clicking **Stop**, execute:

```sql
ROLLBACK;
```

The expected database state remains:

```text
Run status                    M2_1_VALIDATED
Contract status               VALIDATED

Positive evidence             112 / 112 PASS
Negative evidence rows          0
Acceptance-result rows          0

Gate-result rows              18,000
Routing snapshots              1,500
Latest rows                    1,500
Archive rows                   1,500
Matched comparisons              750
Canonical entities            22,541
```

Do not rerun Programs 132B, 133, 134, 132D, or 132E.

---

# M2.1 v0.2R5 consolidated hotfix

Download M2.1 v0.2R5 — Negative-Control Boundary Assertion Hotfix (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
d52fa0b950675fe9a01db6d9ebf9dd46ff7a914ba5f97c9b53a0aa9a0225c4c7
```

Canonical byte-identical copy:

Download the canonical M2.1 v0.2R5 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R5_negative_control_boundary_assertion_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R5_negative_control_boundary_assertion_hotfix.zip.sha256`; referenced bytes not established here)

## Key live-recovery files

- 132F — Boundary-assertion recovery and function repair (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/live_recovery/tests/132F_msbf_m2_1_failed_negative_control_boundary_assertion_recovery_v0_2R5.sql`; referenced bytes not established here)
- 135 — Strengthened positive validation (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/live_recovery/sql/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R5.sql`; referenced bytes not established here)
- 136 — Negative controls (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/live_recovery/sql/136_msbf_m2_1_negative_control_tests_v0_2R5.sql`; referenced bytes not established here)
- 137 — Strengthened acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/live_recovery/sql/137_msbf_m2_1_acceptance_finalize_v0_2R5.sql`; referenced bytes not established here)
- 138 — Master report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/live_recovery/tests/138_MSBF_M2_1_Master_Report_v0_2R5.sql`; referenced bytes not established here)
- 139 — Detailed report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/live_recovery/tests/139_MSBF_M2_1_Detail_Report_v0_2R5.sql`; referenced bytes not established here)

Supporting records:

- Execution guide (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/docs/M2_1_v0_2R5_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/docs/M2_1_v0_2R5_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Program 135 source diff (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/docs/M2_1_v0_2R5_PROGRAM_135_DIFF.txt`; referenced bytes not established here)
- Program 137 source diff (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/docs/M2_1_v0_2R5_PROGRAM_137_DIFF.txt`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R5_Negative_Control_Boundary_Assertion_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# What Program 132F repairs

## 1. Complete configuration assertion

The repaired `m2_1_assert_configuration()` now explicitly requires:

```text
synthetic_data_only_flag                 true
no_final_offer_terms_flag                true
no_production_adverse_action_flag        true
acquisition_source_review_only_flag      true
```

It also requires every physical flag to match the corresponding field in:

```text
configuration_payload
```

Therefore, either of these conditions now fails closed:

```text
Physical flag changed but payload unchanged
Payload changed but physical flag unchanged
```

## 2. Acceptance assertion

The repaired `m2_1_assert_acceptance_ready()` now calls:

```sql
m2_1_assert_configuration(...)
m2_1_assert_prerequisite_status(...)
```

before checking the run lifecycle and positive/negative evidence counts.

This prevents a future acceptance from relying solely on evidence counts after a policy-boundary drift.

## 3. Independent proof of the two repaired controls

Program 132F replays both formerly ineffective mutations in isolated exception subtransactions and requires:

```text
final_offer_boundary_rejected       true
acquisition_boundary_rejected       true
```

The physical policy row remains unchanged because each test mutation rolls back inside its exception subtransaction.

## 4. Audit history

The failed 18-of-20 execution is preserved as:

```text
M2_1_HIST_NEG_004_005_V0_2R4
```

with status:

```text
SUPERSEDED
```

It does not count as current positive or negative evidence.

---

# Exact execution sequence

## 1. Clear the failed Program 136 transaction

Click **Stop**, then execute:

```sql
ROLLBACK;
```

Do not select Retry, Skip, or Skip All.

## 2. Run Program 132F

```text
132F_msbf_m2_1_failed_negative_control_boundary_assertion_recovery_v0_2R5.sql
```

Required result:

```text
prior_run_status                       M2_1_VALIDATED
prior_contract_status                  VALIDATED

positive_checks                        112
positive_passes                        112
positive_failures                        0
negative_evidence_rows                   0

final_offer_boundary_rejected          true
acquisition_boundary_rejected          true

final_configuration_function_complete  true
final_acceptance_calls_configuration   true
final_policy_flags_valid               true

final_run_status                       M2_1_VALIDATED
final_contract_status                  VALIDATED
final_positive_passes                  112
final_negative_evidence_rows             0
preserved_history_rows                   1

recovery_status                        PASS
```

The SQLSTATE and message fields for both mutation proofs should contain the configuration-assertion rejection rather than the sentinel:

```text
M2_1_NEGATIVE_CONTROL_NOT_REJECTED
```

Stop if `recovery_status` is not `PASS`.

## 3. Rerun positive validation with Program 135 v0.2R5

```text
135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R5.sql
```

This rerun is intentional. Program 135 is governed to run from either `GENERATED` or `VALIDATED`, and v0.2R5 strengthens the existing POS002 control without changing the 112-control inventory.

POS002 now certifies:

```text
Policy status
+
synthetic-only boundary
+
no-final-offer boundary
+
no-production-adverse-action boundary
+
acquisition-review-only boundary
```

Required:

```text
112 controls
112 PASS
0 FAIL

M2_1_POS_002_POLICY_APPROVED
observed_value =
APPROVED|true|true|true|true
status = PASS

run_status
M2_1_VALIDATED

contract_status
VALIDATED
```

## 4. Run Program 136 v0.2R5

```text
136_msbf_m2_1_negative_control_tests_v0_2R5.sql
```

Required:

```text
20 negative controls
20 PASS
0 FAIL
```

The repaired controls should show:

```text
M2_1_NEG_004_FINAL_OFFER_BOUNDARY       PASS
M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY PASS
```

Their messages should reflect the strengthened configuration assertion.

## 5. Run Program 137 v0.2R5

```text
137_msbf_m2_1_acceptance_finalize_v0_2R5.sql
```

The finalizer now invokes the strengthened acceptance assertion before its independent physical acceptance guard.

Required:

```text
Positive controls             112 / 112 PASS
Negative controls              20 / 20 PASS

Gate-result rows              18,000
Routing snapshots              1,500
Latest rows                    1,500
Archive rows                   1,500
Matched comparisons              750
Canonical entities            22,541

Physical hash mismatches            0
Archive reproduction mismatches     0
Blocking errors                     0

final_run_status             M2_1_ACCEPTED
final_contract_status        ACCEPTED
gate_status                  PASS
acceptance_status            PASS
```

## 6. Run Programs 138 and 139 v0.2R5

```text
138_MSBF_M2_1_Master_Report_v0_2R5.sql

139_MSBF_M2_1_Detail_Report_v0_2R5.sql
```

Required master result:

```text
overall_m2_1_status = PASS
```

Program 139 should return 24 governed result sets.

The final two must retain their headers and contain zero data rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

# Logic preservation

The hotfix does not modify:

- the 18,000 committed gate results;
- the 1,500 routing snapshots;
- latest or archive contract rows;
- the 750 matched scenario comparisons;
- gate definitions;
- routing outcomes;
- reason codes;
- acquisition review-only methodology;
- processor-continuity logic;
- campaign, contract, or combined hashes;
- the 22,541-entity canonical population;
- any accepted Module 1 or G2 data.

The correction is confined to **governance assertions and validation evidence**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a87c71d8-c721-4d4a-b40e-0802f4fbd2c0"></a>
## Andrew / user · C068-M00406

C068-M00406 · 2026-07-30T06:58:11.757000-04:00 · active path

Preceding visible parent: [C068-M00405](part-31.md#m-7463e9bd-e47c-46f2-8dbc-5dad4cc8d4e5)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(197).png; 132F_msbf_m2_1_failed_negative_control_boundary_assertion_recovery_v0_2R5_results_20260730.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R5.sql:
<!-- END_SOURCE_MESSAGE -->


<a id="m-5c397dcc-a309-4b0e-9098-162003badc03"></a>
## Assistant · C068-M00407

C068-M00407 · 2026-07-30T07:21:57.199715-04:00 · active path

Preceding visible parent: [C068-M00406](part-31.md#m-a87c71d8-c721-4d4a-b40e-0802f4fbd2c0)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.1 diagnosis: the physical policy column exists; the validation context omitted it

The error is an **intermediate-projection defect in Program 135 v0.2R5**, not a missing database-schema column.

Program 132F completed successfully and proved that the physical policy table contains all four governed boundary fields and that the repaired configuration and acceptance assertions recognize them:

```text
synthetic_data_only_flag
no_final_offer_terms_flag
no_production_adverse_action_flag
acquisition_source_review_only_flag
```

Its final result was:

```text
final_configuration_function_complete  true
final_acceptance_calls_configuration   true
final_policy_flags_valid               true

final_run_status                       M2_1_VALIDATED
final_contract_status                  VALIDATED
final_positive_passes                  112
final_negative_evidence_rows             0
recovery_status                        PASS
```

Open the successful Program 132F result (historical reference: `sandbox:[session]/132F_msbf_m2_1_failed_negative_control_boundary_assertion_recovery_v0_2R5_results_20260730.csv`; referenced bytes not established here)

## Exact root cause

Program 135 creates this session-temporary context table:

```sql
CREATE TEMP TABLE _m2_1_vctx
ON COMMIT DROP
AS
SELECT
    r.run_id,
    r.run_status,
    p.policy_status,
    p.methodology_version,
    p.contract_code,
    p.contract_version,
    p.schema_version,
    p.configuration_payload,
    p.configuration_hash AS policy_configuration_hash,
    ...
```

The v0.2R5 enhancement then made POS002 reference:

```sql
synthetic_data_only_flag
no_final_offer_terms_flag
no_production_adverse_action_flag
acquisition_source_review_only_flag
```

through `_m2_1_vctx`.

But those four fields were never included in the temporary table’s `SELECT` projection. PostgreSQL therefore correctly reported:

```text
SQLSTATE 42703
column "synthetic_data_only_flag" does not exist
```

The missing column is in `_m2_1_vctx`, not in:

```text
msbf_ctl.m2_1_policy_profile
```

The corrected Program 135 explicitly projects all four fields and validates the projected values against the approved configuration payload before executing the 112 controls.

---

# Transactional impact

Program 135 begins with an explicit transaction. The error occurred inside the positive-control `DO` block, before Program 135 reached:

```sql
DELETE FROM msbf_ctl.run_evidence
WHERE evidence_code LIKE 'M2_1_POS_%';
```

or any lifecycle updates.

Therefore, after rollback, the expected persistent state remains:

```text
Run status                    M2_1_VALIDATED
Contract status               VALIDATED

Positive controls             112
Positive passes               112
Positive failures               0

Negative evidence rows          0
Acceptance-result rows          0

Gate-result rows              18,000
Routing snapshots              1,500
Latest rows                    1,500
Archive rows                   1,500
Matched comparisons              750
Canonical entities            22,541
```

The repaired campaign, registry, contract, and combined hashes remain intact.

---

# M2.1 v0.2R6 consolidated hotfix

Download M2.1 v0.2R6 — Validation Context Projection Hotfix (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
dc00ce8add8e4f10cc00c65944995bc3bbbcbd7005231f380101abfd46dbabd8
```

Canonical byte-identical copy:

Download the canonical M2.1 v0.2R6 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R6_validation_context_projection_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R6_validation_context_projection_hotfix.zip.sha256`; referenced bytes not established here)

## Key live-recovery files

- 132G — Failed-validation recovery and policy-projection check (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/live_recovery/tests/132G_msbf_m2_1_failed_validation_context_projection_recovery_check_v0_2R6.sql`; referenced bytes not established here)
- 135 — Corrected positive validation (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/live_recovery/sql/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R6.sql`; referenced bytes not established here)
- 136 — Negative controls (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/live_recovery/sql/136_msbf_m2_1_negative_control_tests_v0_2R6.sql`; referenced bytes not established here)
- 137 — Acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/live_recovery/sql/137_msbf_m2_1_acceptance_finalize_v0_2R6.sql`; referenced bytes not established here)
- 138 — Master report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/live_recovery/tests/138_MSBF_M2_1_Master_Report_v0_2R6.sql`; referenced bytes not established here)
- 139 — Detailed report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/live_recovery/tests/139_MSBF_M2_1_Detail_Report_v0_2R6.sql`; referenced bytes not established here)

Supporting records:

- Execution guide (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/docs/M2_1_v0_2R6_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/docs/M2_1_v0_2R6_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Exact Program 135 source diff (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/docs/M2_1_v0_2R6_PROGRAM_135_DIFF.txt`; referenced bytes not established here)
- Context-projection audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/catalogs/M2_1_v0_2R6_CONTEXT_PROJECTION_AUDIT.json`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R6_Validation_Context_Projection_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# Exact execution sequence

## 1. Stop and roll back failed Program 135

Click:

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

## 2. Do not rerun successful upstream programs

Do **not** rerun:

```text
132
132B
133
134
132D
132E
132F
```

Do not rerun Program 135 v0.2R5.

## 3. Run Program 132G

Execute:

```text
132G_msbf_m2_1_failed_validation_context_projection_recovery_check_v0_2R6.sql
```

Program 132G is read-only. It independently calls the repaired configuration and validation-ready assertions and verifies the four physical policy columns.

Required result:

```text
run_status                              M2_1_VALIDATED
contract_status                         VALIDATED

policy_code
M2_1_ELIGIBILITY_POLICY_V1

policy_status                           APPROVED
synthetic_data_only_flag                true
no_final_offer_terms_flag               true
no_production_adverse_action_flag       true
acquisition_source_review_only_flag     true
payload_boundary_match                  true

policy_boundary_column_count            4

gate_result_rows                        18,000
routing_snapshot_rows                    1,500
latest_rows                              1,500
archive_rows                             1,500
comparison_rows                            750
canonical_entities                      22,541

all contract and set hashes             non-null

positive_checks                            112
positive_passes                            112
positive_failures                            0
negative_evidence_rows                       0
acceptance_rows                              0
blocking_errors                              0
campaign_hash_mismatches                     0
registry_hash_mismatches                     0

recovery_status                           PASS
```

Stop immediately if `recovery_status` is not `PASS`.

## 4. Run corrected Program 135 v0.2R6

```text
135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R6.sql
```

The corrected validation context now includes:

```sql
p.synthetic_data_only_flag,
p.no_final_offer_terms_flag,
p.no_production_adverse_action_flag,
p.acquisition_source_review_only_flag
```

It also has a dedicated context-projection guard before the 112 controls begin.

Required result:

```text
112 positive controls
112 PASS
0 FAIL

M2_1_POS_002_POLICY_APPROVED

observed_value
APPROVED|true|true|true|true

threshold_value
APPROVED|true|true|true|true

status
PASS

run_status
M2_1_VALIDATED

contract_status
VALIDATED
```

## 5. Run Program 136 v0.2R6

```text
136_msbf_m2_1_negative_control_tests_v0_2R6.sql
```

Required:

```text
20 negative controls
20 PASS
0 FAIL
```

The two boundary controls repaired by Program 132F should now return:

```text
M2_1_NEG_004_FINAL_OFFER_BOUNDARY
PASS

M2_1_NEG_005_ACQUISITION_CREDIT_BOUNDARY
PASS
```

## 6. Run Program 137 v0.2R6

```text
137_msbf_m2_1_acceptance_finalize_v0_2R6.sql
```

Required:

```text
Positive controls             112 / 112 PASS
Negative controls              20 / 20 PASS

Gate-result rows              18,000
Routing snapshots              1,500
Latest rows                    1,500
Archive rows                   1,500
Matched comparisons              750
Canonical entities            22,541

Physical hash mismatches            0
Archive reproduction mismatches     0
Blocking errors                     0

final_run_status             M2_1_ACCEPTED
final_contract_status        ACCEPTED
gate_status                  PASS
acceptance_status            PASS
```

## 7. Run Programs 138 and 139 v0.2R6

```text
138_MSBF_M2_1_Master_Report_v0_2R6.sql

139_MSBF_M2_1_Detail_Report_v0_2R6.sql
```

Required master-report result:

```text
overall_m2_1_status = PASS
```

Program 139 should return 24 governed result sets. The final two must retain their headers and contain zero data rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

---

# Logic preservation

The v0.2R6 correction changes only the session-temporary validation context and adds a fail-closed projection guard.

It does not modify:

- the policy-profile row;
- any of the four physical stage-boundary flags;
- the 18,000 gate results;
- the 1,500 routing snapshots;
- latest or immutable archive rows;
- the 750 matched comparisons;
- gate definitions;
- route outcomes;
- reason codes;
- campaign, registry, contract, or combined hashes;
- the 22,541 canonical entities;
- any positive-control threshold or Boolean methodology;
- any negative-control methodology;
- acceptance logic;
- accepted Module 1 or G2 data.

Programs 136–139 v0.2R6 are executable-logic equivalent to their v0.2R5 versions apart from revision labels.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ae3ead5e-d4f2-40ac-89c5-6700d825dfb3"></a>
## Andrew / user · C068-M00408

C068-M00408 · 2026-07-30T08:01:43.236000-04:00 · active path

Preceding visible parent: [C068-M00407](part-31.md#m-5c397dcc-a309-4b0e-9098-162003badc03)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: image(198).png; 136_msbf_m2_1_negative_control_tests_v0_2R6_results_20260730.csv; 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R6_results_20260730.csv; 132G_msbf_m2_1_failed_validation_context_projection_recovery_check_v0_2R6_results_20260730.csv

<!-- BEGIN_SOURCE_MESSAGE -->
error in program 137_msbf_m2_1_acceptance_finalize_v0_2R6.sql:
<!-- END_SOURCE_MESSAGE -->


<a id="m-ee313e6c-4955-498e-be55-4ff4cc361180"></a>
## Assistant · C068-M00409

C068-M00409 · 2026-07-30T08:19:55.408910-04:00 · active path

Preceding visible parent: [C068-M00408](part-31.md#m-ae3ead5e-d4f2-40ac-89c5-6700d825dfb3)

<!-- BEGIN_SOURCE_MESSAGE -->
# M2.1 diagnosis: acceptance query had five ambiguous column references

Programs 135 and 136 completed successfully:

```text
Positive validation
112 / 112 PASS

Negative controls
20 / 20 PASS

Run status
M2_1_VALIDATED

Contract status
VALIDATED
```

Evidence:

- Program 132G recovery checkpoint (historical reference: `sandbox:[session]/132G_msbf_m2_1_failed_validation_context_projection_recovery_check_v0_2R6_results_20260730.csv`; referenced bytes not established here)
- Program 135 — 112 positive controls (historical reference: `sandbox:[session]/135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R6_results_20260730.csv`; referenced bytes not established here)
- Program 136 — 20 negative controls (historical reference: `sandbox:[session]/136_msbf_m2_1_negative_control_tests_v0_2R6_results_20260730.csv`; referenced bytes not established here)

The Program 137 failure occurred while creating its temporary acceptance table, before any acceptance updates or inserts.

## Exact root cause

Program 137 joined these two CTEs:

```sql
c AS
(
    SELECT *
    FROM msbf_ctl.m2_1_strategy_contract_registry
),
physical AS
(
    SELECT
        ...
)
```

Both CTEs exposed these identically named fields:

```text
gate_definition_rows
gate_result_rows
latest_rows
archive_rows
comparison_rows
```

The acceptance `CASE` then referenced them without an alias:

```sql
AND gate_definition_rows = 12
AND gate_result_rows = 18000
AND latest_rows = 1500
AND archive_rows = 1500
AND comparison_rows = 750
```

PostgreSQL could not determine whether `gate_definition_rows` referred to:

```sql
c.gate_definition_rows
```

or:

```sql
physical.gate_definition_rows
```

and correctly raised:

```text
SQLSTATE 42702
column reference "gate_definition_rows" is ambiguous
```

Even if only the first reference had been patched, the other four names would have produced the same failure later.

# Consolidated correction

Program 137 v0.2R7 now:

1. narrows the registry CTE to only the four fields actually required:

```text
contract_status
canonical_entities
contract_set_hash
combined_set_hash
```

2. removes `controls.*` and `physical.*` wildcard projections;
3. explicitly selects every acceptance field;
4. qualifies every condition with:

```text
r.
c.
controls.
physical.
```

No count, threshold, hash, lifecycle transition, evidence rule, routing result, or business outcome changed.

---

# M2.1 v0.2R7 hotfix

Download M2.1 v0.2R7 — Acceptance Column Qualification Hotfix (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix.zip.sha256`; referenced bytes not established here)

```text
SHA-256
c4b8eb84f6911b7ccc47b6eec611a341271202e33b065a8e125e4aba88ae9000
```

Canonical byte-identical copy:

Download the canonical v0.2R7 hotfix (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R7_acceptance_column_qualification_hotfix.zip`; referenced bytes not established here)

Download its SHA-256 file (historical reference: `sandbox:[session]/merchant_sales_based_financing_m2_1_v0_2R7_acceptance_column_qualification_hotfix.zip.sha256`; referenced bytes not established here)

## Key live-recovery files

- 132H — Failed-acceptance rollback-state recovery check (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/live_recovery/tests/132H_msbf_m2_1_failed_acceptance_ambiguity_recovery_check_v0_2R7.sql`; referenced bytes not established here)
- 137 — Corrected acceptance finalizer (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/live_recovery/sql/137_msbf_m2_1_acceptance_finalize_v0_2R7.sql`; referenced bytes not established here)
- 138 — Master report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/live_recovery/tests/138_MSBF_M2_1_Master_Report_v0_2R7.sql`; referenced bytes not established here)
- 139 — Detailed report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/live_recovery/tests/139_MSBF_M2_1_Detail_Report_v0_2R7.sql`; referenced bytes not established here)

Supporting records:

- Execution guide (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/docs/M2_1_v0_2R7_EXECUTION_GUIDE.md`; referenced bytes not established here)
- Root-cause and downstream audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/docs/M2_1_v0_2R7_ROOT_CAUSE_AND_DOWNSTREAM_AUDIT.md`; referenced bytes not established here)
- Exact Program 137 source diff (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/docs/M2_1_v0_2R7_PROGRAM_137_DIFF.txt`; referenced bytes not established here)
- Acceptance namespace audit (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/catalogs/M2_1_v0_2R7_ACCEPTANCE_NAMESPACE_AUDIT.json`; referenced bytes not established here)
- Package-validation report (historical reference: `sandbox:[session]/MSBF_M2_1_v0_2R7_Acceptance_Column_Qualification_Hotfix/PACKAGE_VALIDATION_REPORT.md`; referenced bytes not established here)

---

# Exact execution sequence

## 1. Stop and roll back Program 137

Click:

```text
Stop
```

Do not use:

```text
Retry
Skip
Skip All
```

Then execute:

```sql
ROLLBACK;
```

The error occurred in the initial `CREATE TEMP TABLE ... AS` statement. Therefore, none of these actions committed:

- run-status transition;
- contract-status transition;
- acceptance-gate result;
- acceptance-summary evidence.

## 2. Do not rerun Programs 132–136

In particular, do **not** rerun:

```text
134 — generation
135 — positive validation
136 — negative controls
```

Their successful committed results remain authoritative.

## 3. Run Program 132H

```text
132H_msbf_m2_1_failed_acceptance_ambiguity_recovery_check_v0_2R7.sql
```

This is read-only and calls the strengthened acceptance-readiness assertion.

Required result:

```text
run_status                    M2_1_VALIDATED
contract_status               VALIDATED

positive_checks               112
positive_passes               112
positive_failures               0

negative_checks                20
negative_passes                20
negative_failures               0

acceptance_summary_rows         0
acceptance_gate_rows            0

campaign_rows                   1
gate_definition_rows           12
reason_rows                    23
outcome_rows                    4
gate_result_rows            18,000
snapshot_rows               1,500
latest_rows                 1,500
archive_rows                1,500
comparison_rows               750

canonical_entities          22,541

latest_archive_mismatches        0
snapshot_hash_mismatches         0
latest_hash_mismatches           0
archive_hash_mismatches          0
blocking_errors                  0

all registry and set hashes      non-null

recovery_status               PASS
```

Stop if `recovery_status` is not `PASS`.

## 4. Run corrected Program 137

```text
137_msbf_m2_1_acceptance_finalize_v0_2R7.sql
```

Required pre-acceptance result:

```text
prior_run_status             M2_1_VALIDATED
prior_contract_status        VALIDATED

positive controls            112 / 112 PASS
negative controls             20 / 20 PASS

campaign rows                   1
gate definitions               12
reason codes                   23
outcome definitions             4
gate-result rows           18,000
routing snapshots           1,500
latest rows                 1,500
archive rows                1,500
comparisons                   750
canonical entities         22,541

blocking errors                 0
existing acceptance rows        0
stress route improvements       0
acquisition decline gates       0
acquisition decline reasons     0
prohibited offer columns        0
production adverse-action rows  0
processor unavailable errors    0
snapshot hash mismatches        0
latest hash mismatches          0
archive hash mismatches         0
archive reproduction errors     0

acceptance_status             PASS
```

Required final state:

```text
final_run_status             M2_1_ACCEPTED
final_contract_status        ACCEPTED
gate_status                  PASS
```

Program 137 should issue:

```text
M2_1_ELIGIBILITY_POLICY_ROUTING
PASS
```

and persist:

```text
M2_1_ACCEPTANCE_SUMMARY
status = PASS
```

After successful commit, do not rerun Program 137.

## 5. Run Program 138 v0.2R7

```text
138_MSBF_M2_1_Master_Report_v0_2R7.sql
```

Required result:

```text
overall_m2_1_status = PASS
```

The master report should show:

```text
Run status                   M2_1_ACCEPTED
Contract status              ACCEPTED
Acceptance gate              PASS
Positive controls            112 / 112
Negative controls             20 / 20
Canonical entities          22,541
Blocking errors                  0
Stress improvements              0
```

## 6. Run Program 139 v0.2R7

```text
139_MSBF_M2_1_Detail_Report_v0_2R7.sql
```

It should produce 24 governed result sets.

The final two must retain their headers and contain zero rows:

```text
Result Set 23
Deterministic Mismatches

Result Set 24
Blocking Errors and Stage-Boundary Violations
```

# Package audit

The v0.2R7 package passed:

```text
Original overlapping fields identified           5
Broad registry SELECT * remaining                 0
Wildcard acceptance projections remaining         0
Unqualified ambiguous acceptance references       0
Required qualified acceptance predicates         PASS

Program 135 evidence                         112 / 112 PASS
Program 136 evidence                          20 / 20 PASS

Program 138 logic-equivalent to v0.2R6            PASS
Program 139 logic-equivalent to v0.2R6            PASS

Generated data changed                            false
Evidence changed                                  false
Hashes changed                                    false
Acceptance thresholds changed                     false
Business logic changed                            false

ZIP CRC                                           PASS
Complete extraction                              PASS
Manifest and SHA-256 inventory                   PASS
```
<!-- END_SOURCE_MESSAGE -->


<a id="m-103f42b3-2334-41da-8f9d-2099c11e8191"></a>
## Andrew / user · C068-M00410

C068-M00410 · 2026-07-30T09:34:12.824000-04:00 · active path

Preceding visible parent: [C068-M00409](part-31.md#m-ee313e6c-4955-498e-be55-4ff4cc361180)

**Editorial record note:** Attachment references: 132H_msbf_m2_1_failed_acceptance_ambiguity_recovery_check_v0_2R7_results_20260730.csv; 136_msbf_m2_1_negative_control_tests_v0_2R6_results_20260730(2).csv; 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R6_results_20260730(2).csv; 132G_msbf_m2_1_failed_validation_context_projection_recovery_check_v0_2R6_results_20260730(2).csv; 132F_msbf_m2_1_failed_negative_control_boundary_assertion_recovery_v0_2R5_results_20260730(2).csv; 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R4_results_20260730(2).csv; 132E_msbf_m2_1_failed_campaign_physical_row_hash_recovery_v0_2R4_results_20260730(1).csv; 135_msbf_m2_1_eligibility_policy_routing_validation_v0_2R3_results_20260729(2).csv; 132D_msbf_m2_1_generated_state_recovery_and_comparison_view_check_v0_2R3_results_20260729(2).csv; 134_msbf_m2_1_eligibility_policy_routing_generation_v0_2R1_results_20260729(1).csv; 133_msbf_m2_1_preflight_validation_v0_2R1_results_20260729(1).csv; 132B_msbf_m2_1_failed_stage_boundary_preflight_recovery_v0_2R1_results_20260729(1).csv; 132_msbf_m2_1_schema_policy_extension_v0_2_results_20260729.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Gate_Definitions_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Entity_Cardinality_And_Grains_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Accepted_G2_Source_Boundary_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Policy_Campaign_And_Registry_Identity_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Run_Contract_Lifecycle_And_Acceptance_Gate_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Master_Report_v0_2R7_20260730.csv; 137_msbf_m2_1_acceptance_finalize_v0_2R7137_msbf_m2_1_acceptance_finalize_v0_2R7_results_20260730.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Here is the batch 1 of 2 for M2.1 execution evidence. Do not do anything but intake at this point until after I issue batch 2 of 2 and further instructions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ae51107f-6c71-4866-b5f3-ad0ac998f60b"></a>
## Assistant · C068-M00411

C068-M00411 · 2026-07-30T09:36:10.847413-04:00 · active path

Preceding visible parent: [C068-M00410](part-31.md#m-103f42b3-2334-41da-8f9d-2099c11e8191)

<!-- BEGIN_SOURCE_MESSAGE -->
Received **batch 1 of 2** for the M2.1 execution evidence.

The intake includes:

- Program 132 schema and policy extension
- Program 132B stage-boundary preflight recovery
- Program 133 corrected preflight validation
- Program 134 committed eligibility, policy-gate, and routing generation
- Program 132D generated-state and comparison-view recovery check
- Program 135 v0.2R3 positive-validation result
- Program 132E campaign physical-row-hash remediation
- Program 135 v0.2R4 positive-validation result
- Program 132F negative-control boundary-assertion recovery
- Program 132G validation-context projection recovery
- Program 135 v0.2R6 final positive validation
- Program 136 v0.2R6 final negative controls
- Program 132H pre-acceptance rollback-state recovery
- Program 137 v0.2R7 acceptance finalizer
- Program 138 v0.2R7 master report
- Program 139 v0.2R7 detailed-report evidence covering:
  - Run, contract lifecycle, and acceptance gate
  - Policy, campaign, and registry identity
  - Accepted G2 source boundary
  - Entity cardinality and governed grains
  - Gate-definition inventory

I will not analyze the evidence, determine M2.1 acceptance, issue sign-off, or update the repository until you provide **batch 2 of 2** and further instructions.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d36885d9-3a13-4974-83e2-10afd1abdd88"></a>
## Andrew / user · C068-M00412

C068-M00412 · 2026-07-30T09:41:36.240000-04:00 · active path

Preceding visible parent: [C068-M00411](part-31.md#m-ae51107f-6c71-4866-b5f3-ad0ac998f60b)

**Editorial record note:** Attachment references: MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Industry_And_Merchant_Size_Routing_Diagnostics_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Stress_Floor_Diagnostics_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Matched_Baseline_Stress_Route_Migration_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Policy_Decline_Population_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Insufficient_Evidence_Population_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Manual_Review_Population_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Eligible_For_Offer_Design_Population_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Hard_Stop_Diagnostics_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Primary_Reason_Distribution_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Routing_Evidence_Status_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Final_Route_Distribution_By_Scenario_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Gate_Outcomes_By_Scenario_And_Gate_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Routing_Outcome_Definitions_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Transparent_Reason_Code_Dictionary_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Blocking_Errors_And_Stage_Boundary_Violations_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Deterministic_Mismatches_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Governed_M2_1_Evidence_Summary_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Latest_Archive_Reproduction_20260730.csv; MSBF_M2_1_Eligibility_Policy_Gates_Decision_Routing_Foundations_Detail_Report_v0_2R7_Acquisition_Evidence_Operational_Boundary_20260730.csv

<!-- BEGIN_SOURCE_MESSAGE -->
Remainder of M2.1 evidence. Validate M2.1 is a success. If it is approved, sign off M2.1 and update full project zip.
<!-- END_SOURCE_MESSAGE -->
