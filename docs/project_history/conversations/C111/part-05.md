# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing

Part 05 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-04.md)
[Next part](part-06.md)

<a id="m-4ac080a2-9435-4891-96cb-df2721c3059b"></a>
## Assistant · C111-M00068

C111-M00068 · 2026-08-29T10:30:48.835848-04:00 · active path

Preceding visible parent: [C111-M00067](part-04.md#m-058b0a1a-34ea-465f-ad26-59c7e6ff243f)

<!-- BEGIN_SOURCE_MESSAGE -->
# Phase 2C construction complete

The owner-approved R1 policy slate is now frozen into the default Phase 2C profile:

```text
Minimum counteroffer ratio        40%
Maximum exposure reduction        60%
Exact supported horizons          30 / 60 / 90 days
Economic hurdle                   Required
Selection method                  Dual-frontier, authority-first
Search entry                      Any decisionable structure-remediable FAIL or REVIEW
Stress non-improvement            Route and structure floors enabled
```

I handled future-user flexibility **now**, rather than deferring all of it to Campaign Scale.

## Configuration flexibility implemented

A versioned policy profile can adjust these inputs without editing strategy code:

| Configurable input | Phase 2C treatment |
|---|---|
| Minimum counteroffer ratio | Configurable |
| Maximum exposure reduction | Configurable; must remain complementary to the minimum ratio |
| Exact supported horizons | Configurable subset of 30/60/90 |
| Strict resilience-tier ceiling | Configurable |
| Strict integrated-risk-tier ceiling | Configurable |
| Review-frontier tier ceilings | Configurable |
| Capacity/economics search-entry rules | Configurable |
| Genuine human-review conditions | Configurable |
| Advisory classifications | Configurable |

Every run preserves the exact profile code, version, bytes, SHA-256, and whether a nondefault profile was explicitly authorized.

A nondefault profile cannot be applied accidentally. It requires this explicit runtime switch:

```powershell
-AuthorizeNonDefaultProfile
```

The approved 40%/60% profile remains the default for the current run.

The following remain source-bound or deferred because they should not become casual end-user sliders:

- accepted M1.10–M1.14 formulas and method thresholds;
- M2.2 product bounds, candidate templates, and rounding increments;
- unsupported M1.13 horizon interpolation;
- alternative selection algorithms;
- disabling the economic hurdle or stress non-improvement controls;
- campaign population size, dates, scenarios, and deterministic seeds; and
- segment- or channel-specific policy profiles.

Those can be made configurable later through separately versioned strategy, method, and Campaign profiles with complete rerun evidence.

## Phase 2C runtime scope

The one-command runtime will:

1. preserve `msbf_r1b_p2b_r3_20260829_080240` as an immutable source;
2. create a new disposable Phase 2C clone;
3. perform the 11 supplemental economics-review searches;
4. evaluate the default 350 supplemental candidates through exact M1.10–M1.14 methods;
5. merge them with the 6,047 previously validated candidates;
6. apply the approved commercial, credit, review, and economic feasibility rules to all 6,397 exact candidates;
7. select strict and review frontiers;
8. apply genuine human-review classification;
9. produce independent Baseline and Recession Energy outcomes;
10. apply exact evaluated-candidate route and structure floors;
11. generate complete no-feasible-structure proofs;
12. reconcile predecessor and successor decisions;
13. generate the five curated Power BI facts; and
14. retain all outputs in the disposable database and a portable evidence ZIP.

The resulting decisions remain classified as:

```text
SUCCESSOR_COUNTERFACTUAL_FINAL_DECISIONS_NOT_ACCEPTED_AUTHORITY
```

They do not supersede accepted M1/G2 or M2/G3 authority.

## Construction validation

```text
Static controls                    24 / 24 PASS
Python compilation                 PASS
Default profile validation         PASS
Custom-profile template validation PASS
Frozen supplemental population     11 / 11
Frozen supplemental candidates     350
Minimum candidate ratio            ≥ 40%
Candidate horizons                 60 / 90 in default supplemental set
Accepted-source hash bindings      4 / 4 PASS
Clean extraction                   PASS
Package-manifest mismatches        0
Database execution                 NOT RUN
```

The archive uses the short root `R1B_PHASE2C`, has a maximum member path of 94 characters, and passed clean extraction. It should avoid the Windows ZIP problem encountered earlier.

# Download Phase 2C

Download the Phase 2C final-strategy runtime (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829.zip.sha256`; referenced bytes not established here)

```text
Package size:
112,969 bytes

SHA-256:
6e5fb3164270b3276d86e6df254bd5c9c0275c45e1d7a1c8993fb0cd9de7d61f
```

Supporting controls:

Open the final package receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_PACKAGE_RECEIPT_20260829.json`; referenced bytes not established here)

Open the clean-extraction receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_CLEAN_EXTRACTION_RECEIPT_20260829.json`; referenced bytes not established here)

Open the owner policy-decision receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829/OWNER_POLICY_DECISION_RECEIPT.json`; referenced bytes not established here)

Open the construction receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829/BUILD_RECEIPT.json`; referenced bytes not established here)

Documentation:

Open the START HERE guide (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829/00_START_HERE.md`; referenced bytes not established here)

Open the policy approval and flexibility design (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829/docs/01_OWNER_POLICY_APPROVAL_AND_FLEXIBILITY.md`; referenced bytes not established here)

Open the method and authority boundary (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829/docs/02_PHASE2C_METHOD_AND_AUTHORITY_BOUNDARY.md`; referenced bytes not established here)

Open the future configuration scope (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_FINAL_STRATEGY_RUNTIME_20260829/docs/03_FUTURE_CONFIGURATION_SCOPE.md`; referenced bytes not established here)

Plain-text fallbacks:

Download START HERE as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_START_HERE_20260829.txt`; referenced bytes not established here)

Download the policy and flexibility document as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_POLICY_AND_FLEXIBILITY_20260829.txt`; referenced bytes not established here)

Download the method boundary as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_METHOD_BOUNDARY_20260829.txt`; referenced bytes not established here)

# Run the approved default profile

Extract the ZIP into:

```text
C:\MSBF
```

You should then have:

```text
C:\MSBF\R1B_PHASE2C
```

Run:

```powershell
cd C:\MSBF\R1B_PHASE2C
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\RUN_R1B_PHASE2C.ps1
```

Enter the local PostgreSQL `postgres` password when prompted.

The runtime will preserve:

```text
msbf_r1b_p2b_r3_20260829_080240
```

and create a new clone resembling:

```text
msbf_r1b_p2c_20260829_XXXXXX
```

When the run finishes, upload both generated files from:

```text
C:\MSBF\R1B_PHASE2C\results
```

They will resemble:

```text
msbf_r1b_p2c_..._R1B_PHASE2C_RESULTS.zip
msbf_r1b_p2c_..._R1B_PHASE2C_RESULTS.zip.sha256
```

Do not rerun after either `PASS` or `FAIL`; the captured evidence will govern the next correction or final strategy-impact review.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f4fc4d5c-fd5c-4eb9-8461-1a1aed80a80c"></a>
## Andrew / user · C111-M00069

C111-M00069 · 2026-08-29T10:39:26.464000-04:00 · active path

Preceding visible parent: [C111-M00068](part-05.md#m-4ac080a2-9435-4891-96cb-df2721c3059b)

**Editorial record note:** Attachment references: msbf_r1b_p2c_20260829_103722_R1B_PHASE2C_RESULTS.zip; msbf_r1b_p2c_20260829_103722_R1B_PHASE2C_RESULTS.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
MSBF M1/M2 Successor R1B Phase 2C
Purpose: owner-approved final counteroffer feasibility, selection, routing, stress floor, and Power BI handoff
Source Phase2B database: msbf_r1b_p2b_r3_20260829_080240
Policy profile: C:\MSBF\R1B_PHASE2C\config\R1_POLICY_PROFILE_OWNER_APPROVED.json

The passed Phase2B database will not be modified.
A new disposable clone will be created.
Counterfactual final decisions are not accepted authority.

PostgreSQL password for local user postgres (not stored):

R1B Phase 2C finished: FAIL
Source Phase2B database modified: NO
Clone retained: msbf_r1b_p2c_20260829_103722
Counterfactual final decisions generated: NO
Accepted authority changed: NO
Last stage: SUPPLEMENTAL_SEARCH_POPULATION
Results: C:\MSBF\R1B_PHASE2C\results\msbf_r1b_p2c_20260829_103722_R1B_PHASE2C_RESULTS.zip
SHA-256: f4e6a731b8668486d9c9f3116f12d062764133ea232761c33aeab02f656a17fc
Failure: RuntimeError('Supplemental search rows 0 expected 11')
R1B Phase 2C stopped fail-closed. Upload the generated result ZIP and sidecar from C:\MSBF\R1B_PHASE2C\results.
At C:\MSBF\R1B_PHASE2C\RUN_R1B_PHASE2C.ps1:29 char:3
+   throw "R1B Phase 2C stopped fail-closed. Upload the generated resul ...
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (R1B Phase 2C st...HASE2C\results.:String) [], RuntimeException
    + FullyQualifiedErrorId : R1B Phase 2C stopped fail-closed. Upload the generated result ZIP and sidecar from C:\MSBF\R1B_PHASE2C\results.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a3d9c04b-d90e-4bc0-8cf3-ce420048a64f"></a>
## Assistant · C111-M00070

C111-M00070 · 2026-08-29T11:19:39.659090-04:00 · active path

Preceding visible parent: [C111-M00069](part-05.md#m-f4fc4d5c-fd5c-4eb9-8461-1a1aed80a80c)

<!-- BEGIN_SOURCE_MESSAGE -->
# Phase 2C R1 failure diagnosed; R2 ready

I verified the uploaded Phase 2C failure package and sidecar. The evidence package is intact and corresponds to the failed `msbf_r1b_p2c_20260829_103722` run. [export reference: filecite | turn14file0 | L1-L6] [export reference: filecite | turn14file1 | L7-L12]

## Exact root cause

The runtime queried the accepted gate table using:

```text
GATE_10_ECONOMICS
```

The physical accepted gate code is:

```text
GATE_10_UNIT_ECONOMICS
```

Because the nonexistent alias matched no rows, the supplemental population query returned zero instead of the frozen expected eleven:

```text
Expected supplemental rows          11
Actual supplemental rows             0
Baseline expected                     6
Recession Energy expected             5
```

The accepted snapshot confirms:

```text
GATE_10_UNIT_ECONOMICS rows        1,500
PASS                                447
REVIEW                              141
FAIL                                314
BLOCKED                             598

GATE_10_ECONOMICS rows                0
```

Classification:

```text
PHASE2C_RUNTIME_GATE_CODE_BINDING_DEFECT
```

This was not a source-data defect, an accepted-method defect, or a defect in the owner-approved 40%/60% policy.

Nothing substantive executed after the stop:

```text
Source Phase2B database modified       FALSE
Failed clone retained                  msbf_r1b_p2c_20260829_103722
Supplemental candidates evaluated      FALSE
Counterfactual decisions generated     FALSE
Accepted authority changed             FALSE
```

## Preventive corrections included in R2

I corrected the gate code in both the supplemental-search query and the full application export. I also added a live gate-domain preflight that must establish the exact gate vocabulary, outcome distribution, and eleven-row supplemental population **before a clone is created**.

Review of the final engine exposed three additional latent defects that R1 had not yet reached:

1. **Selected-candidate lineage incompleteness.** Decisionable applications that did not require alternative search could select a requested-structure candidate ID that was absent from `FactOfferCandidate`. R2 adds 122 accepted requested-reference rows and requires every selected candidate ID to resolve.

2. **Invalid stress-floor flag typing.** One Boolean expression could place a candidate ID string into `stress_floor_applied_flag`. R2 forces an actual Boolean and validates that the only retained values are `true` and `false`.

3. **Incomplete or misleading floor evidence.** Governed stress outcomes created by a matched-Baseline route or structure floor could lack a no-feasible proof or be narrated as though the stress scenario independently established the Baseline reason. R2 now:
   - preserves independent stress reasoning;
   - distinguishes Baseline route floors from stress structure floors;
   - produces a proof row for every governed no-feasible outcome; and
   - identifies the exact floor basis in the decision lineage.

I also replaced physical line counting with proper CSV parsing so embedded newlines cannot create a false cardinality failure.

## R2 construction controls

```text
Static controls                       20 / 20 PASS
Negative controls                      2 / 2 PASS
Python compilation                    PASS
Default policy-profile validation     PASS
Future-profile template validation    PASS
Frozen supplemental population        11 / 11
Frozen supplemental candidates       350
Expected exact search candidates    6,397
Requested-reference candidates       122
Expected Power BI candidate rows    6,519
Selected-candidate reference gaps       0
No-feasible proof gaps                  0
Search rows without candidates          0
Clean-extraction manifest mismatches    0
ZIP integrity                         PASS
Database execution                    NOT RUN
```

The offline strategy-engine exercise was structural validation only. It did not substitute fixture candidate metrics for the live PostgreSQL M1.10–M1.14 results as business-outcome evidence.

# Download Phase 2C R2

Download the corrected Phase 2C R2 runtime (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_FINAL_STRATEGY_RUNTIME_20260829.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_FINAL_STRATEGY_RUNTIME_20260829.zip.sha256`; referenced bytes not established here)

```text
Package size:
121,009 bytes

SHA-256:
0cb4a08f3495485945eefb8842040057306de4dc08b33599c94b9da84bcd2934

ZIP integrity:
PASS

Maximum archive-member path:
97 characters
```

Supporting documents:

Open the R2 START HERE guide (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_START_HERE_20260829.md`; referenced bytes not established here)

Open the R1 failure analysis and R2 correction record (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R1_FAILURE_ANALYSIS_AND_R2_CORRECTION_20260829.md`; referenced bytes not established here)

Open the R2 method and authority boundary (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_METHOD_BOUNDARY_20260829.md`; referenced bytes not established here)

Open the R2 build receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_BUILD_RECEIPT_20260829.json`; referenced bytes not established here)

Open the gate-binding validation (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_GATE_BINDING_VALIDATION_20260829.json`; referenced bytes not established here)

Open the offline structural-validation receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_OFFLINE_STRUCTURAL_VALIDATION_20260829.json`; referenced bytes not established here)

Open the final package receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_FINAL_PACKAGE_RECEIPT_20260829.json`; referenced bytes not established here)

Open the clean-extraction receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_CLEAN_EXTRACTION_RECEIPT_20260829.json`; referenced bytes not established here)

Plain-text fallbacks:

Download START HERE as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_START_HERE_20260829.txt`; referenced bytes not established here)

Download the failure analysis as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R1_FAILURE_ANALYSIS_AND_R2_CORRECTION_20260829.txt`; referenced bytes not established here)

# Run R2

Extract the ZIP into:

```text
C:\MSBF
```

It should create:

```text
C:\MSBF\R1B_PHASE2C_R2
```

Preserve these databases unchanged:

```text
msbf_r1b_p2b_r3_20260829_080240
msbf_r1b_p2c_20260829_103722
```

Run:

```powershell
cd C:\MSBF\R1B_PHASE2C_R2
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\RUN_R1B_PHASE2C_R2.ps1
```

R2 will create a new disposable clone resembling:

```text
msbf_r1b_p2c_r2_20260829_XXXXXX
```

When it finishes, upload the generated ZIP and sidecar from:

```text
C:\MSBF\R1B_PHASE2C_R2\results
```

Do not rerun after either `PASS` or `FAIL`; the new evidence package will determine the next action.
<!-- END_SOURCE_MESSAGE -->


<a id="m-045b4664-28f5-4390-a468-5d5677b26a14"></a>
## Andrew / user · C111-M00071

C111-M00071 · 2026-08-29T18:46:58.099000-04:00 · active path

Preceding visible parent: [C111-M00070](part-05.md#m-a3d9c04b-d90e-4bc0-8cf3-ce420048a64f)

**Editorial record note:** Attachment references: msbf_r1b_p2c_r2_20260829_184119_R1B_PHASE2C_R2_RESULTS.zip; msbf_r1b_p2c_r2_20260829_184119_R1B_PHASE2C_R2_RESULTS.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
MSBF M1/M2 Successor R1B Phase 2C R2
Purpose: owner-approved final counteroffer feasibility, selection, routing, stress floor, and Power BI handoff
Source Phase2B database: msbf_r1b_p2b_r3_20260829_080240
Policy profile: C:\MSBF\R1B_PHASE2C_R2\config\R1_POLICY_PROFILE_OWNER_APPROVED.json

The passed Phase2B database and failed Phase2C R1 clone will not be modified.
A new disposable clone will be created.
Counterfactual final decisions are not accepted authority.

PostgreSQL password for local user postgres (not stored):

R1B Phase 2C finished: FAIL
Source Phase2B database modified: NO
Clone retained: msbf_r1b_p2c_r2_20260829_184119
Counterfactual final decisions generated: NO
Accepted authority changed: NO
Last stage: EXPORT_FINAL_STRATEGY_INPUTS
Results: C:\MSBF\R1B_PHASE2C_R2\results\msbf_r1b_p2c_r2_20260829_184119_R1B_PHASE2C_R2_RESULTS.zip
SHA-256: fcc28a890007916ea1070325e0d37f9a25835fe70fbf98ea1b8f71c3f3f65e5f
Failure: RuntimeError("Command failed (1): C:\\Program Files\\PostgreSQL\\17\\bin\\psql.exe -h localhost -p 5432 -U postgres -d msbf_r1b_p2c_r2_20260829_184119 -X -v ON_ERROR_STOP=1 -c \\copy (SELECT a.module1_run_id, a.scenario_id, a.merchant_application_id, a.population_id, a.merchant_id, a.as_of_date, a.scenario_code, a.industry_code, a.merchant_size_tier, a.relationship_stage, a.partner_channel_id, a.channel_type, a.source_confidence_score, a.data_confidence_tier, a.verification_disposition, a.fraud_risk_tier, cf.processor_continuity_status AS processor_continuity_status, a.feature_completeness_status, a.avg_daily_eligible_sales_30d, a.annualized_eligible_sales, a.average_available_balance_30d, a.negative_balance_day_rate_30d, a.nsf_count_30d, a.capacity_tier, a.capacity_evidence_status, a.affordability_status, a.sales_linked_payment_coverage_ratio, a.residual_daily_operating_cash_flow, a.post_financing_liquidity_buffer_amount, a.archetype_code, a.operating_resilience_score, a.resilience_tier, a.resilience_status, a.operating_resilience_evidence_status, a.integrated_risk_score, a.synthetic_merchant_risk_proxy, a.integrated_risk_tier, a.integrated_risk_status, a.integrated_risk_evidence_status, a.path_weighted_ead_amount, a.expected_ead_rate, a.recovery_rate_assumption, a.lgd_input_rate, a.schedule_adjusted_comparative_expected_loss_amount, a.schedule_adjusted_comparative_loss_rate, a.loss_evidence_status, a.gross_finance_revenue_amount, a.total_non_loss_cost_amount, a.risk_adjusted_contribution_amount, a.annualized_risk_adjusted_return_rate, a.economic_surplus_amount, a.economic_tier, a.economic_status, a.unit_economics_evidence_status, a.hard_stop_recommended_flag, a.manual_review_recommended_flag, a.contract_evidence_status, a.fallback_path_code, a.primary_contract_reason_code, a.secondary_contract_reason_codes, a.m1_8_row_hash, a.m1_9_row_hash, a.m1_10_row_hash, a.m1_11_row_hash, a.m1_12_row_hash, a.m1_13_row_hash, a.m1_14_row_hash, a.source_payload, a.lineage_payload, a.contract_code, a.contract_version, a.schema_version, a.contract_row_hash, a.created_by_run_id, a.created_at, a.processor_continuity_status AS predecessor_flattened_processor_continuity_status, q.requested_funding_amount AS requested_amount, q.requested_remittance_rate, q.requested_payback_multiple, q.requested_expected_payoff_days AS requested_horizon_days, q.requested_total_repayment_amount, c.requested_daily_remittance_amount, c.post_financing_buffer_days, c.existing_daily_payment_amount, c.total_daily_obligation_burden, ue.hurdle_annual_return_rate, ue.hurdle_pass_flag, cf.pos_quality_status, cf.deposit_quality_status, cf.processor_outage_day_rate_30d, cf.processor_degraded_day_rate_30d, cf.pos_history_days, cf.deposit_history_days, cf.ready_for_downstream_flag, cf.downstream_routing_status, g6.gate_outcome AS capacity_gate_outcome, g6.reason_code AS capacity_gate_reason_code, g6.observed_value_text AS capacity_gate_observed, g6.threshold_value_text AS capacity_gate_threshold, g6.row_hash AS capacity_gate_row_hash, g10.gate_outcome AS economics_gate_outcome, g10.reason_code AS economics_gate_reason_code, g10.observed_value_text AS economics_gate_observed, g10.threshold_value_text AS economics_gate_threshold, g10.row_hash AS economics_gate_row_hash, r.final_route_code, r.independent_route_code, r.baseline_route_code, r.stress_floor_applied_flag, r.primary_reason_code, r.reason_codes, r.contract_row_hash AS contract_row_hash_route, d.final_decision_outcome_code, d.final_offer_amount, d.final_remittance_rate, d.final_payback_multiple, d.final_collection_horizon_days, d.primary_decision_reason_code, d.contract_row_hash AS contract_row_hash_pred\n      FROM msbf_m1.application_module1_latest a\n      JOIN msbf_m2.application_request_structure_latest q\n        ON q.module1_run_id=a.module1_run_id AND q.merchant_application_id=a.merchant_application_id\n      JOIN msbf_m1.application_liquidity_capacity_snapshot c\n        USING(module1_run_id,scenario_id,merchant_application_id)\n      JOIN msbf_m1.application_unit_economics_snapshot ue\n        USING(module1_run_id,scenario_id,merchant_application_id)\n      JOIN msbf_m1.application_cashflow_feature_snapshot cf\n        USING(module1_run_id,scenario_id,merchant_application_id)\n      JOIN msbf_m2.application_policy_gate_result g6\n        ON g6.module1_run_id=a.module1_run_id AND g6.scenario_id=a.scenario_id\n       AND g6.scenario_code=a.scenario_code AND g6.merchant_application_id=a.merchant_application_id\n       AND g6.gate_code='GATE_06_CAPACITY'\n      JOIN msbf_m2.application_policy_gate_result g10\n        ON g10.module1_run_id=a.module1_run_id AND g10.scenario_id=a.scenario_id\n       AND g10.scenario_code=a.scenario_code AND g10.merchant_application_id=a.merchant_application_id\n       AND g10.gate_code='GATE_10_UNIT_ECONOMICS'\n      JOIN msbf_m2.application_eligibility_routing_latest r\n        USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)\n      JOIN msbf_m2.application_final_offer_decision_latest d\n        USING(module1_run_id,scenario_id,scenario_code,merchant_application_id)\n      ORDER BY a.scenario_id,a.merchant_application_id) TO 'C:/MSBF/R1B_PHASE2C_R2/results/msbf_r1b_p2c_r2_20260829_184119/inputs/application_scenario_source.csv' WITH (FORMAT csv,HEADER true,ENCODING 'UTF8');")
R1B Phase 2C R2 stopped fail-closed. Upload the generated result ZIP and sidecar from C:\MSBF\R1B_PHASE2C_R2\results.
At C:\MSBF\R1B_PHASE2C_R2\RUN_R1B_PHASE2C_R2.ps1:29 char:3
+   throw "R1B Phase 2C R2 stopped fail-closed. Upload the generated re ...
+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (R1B Phase 2C R2...E2C_R2\results.:String) [], RuntimeException
    + FullyQualifiedErrorId : R1B Phase 2C R2 stopped fail-closed. Upload the generated result ZIP and sidecar from C:\MSBF\R1B_PHASE2C_R2\results.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6a4bc4b5-f460-465f-b42a-b92af2fe0933"></a>
## Assistant · C111-M00072

C111-M00072 · 2026-08-29T19:05:30.487791-04:00 · active path

Preceding visible parent: [C111-M00071](part-05.md#m-045b4664-28f5-4390-a468-5d5677b26a14)

<!-- BEGIN_SOURCE_MESSAGE -->
# Phase 2C R2 failure diagnosed; R3 resume runtime ready

I verified the uploaded R2 results package against its SHA-256 sidecar. [export reference: filecite | turn14file0 | L1-L6] [export reference: filecite | turn14file1 | L7-L12]

The owner-approved policy, supplemental candidate generation, and exact downstream replay all completed correctly before the failure:

```text
Supplemental search rows                    11
Supplemental candidates                    350
Supplemental M1.10 candidate rows          350
Supplemental M1.11–M1.14 candidate rows    350
Requested-stage comparisons                 44
Requested-stage mismatches                   0
Counterfactual final decisions generated     0
Accepted authority changed                  NO
```

## Exact root cause

The application export first joined `application_request_structure_latest q` through an explicit `ON` clause. That preserved both tables’ copies of `module1_run_id` in the intermediate joined relation.

The next join then used:

```sql
USING(module1_run_id, scenario_id, merchant_application_id)
```

PostgreSQL rejected it because `module1_run_id` already appeared more than once in the accumulated left relation:

```text
ERROR: common column name "module1_run_id" appears more than once in left table
```

Classification:

```text
PHASE2C_EXPORT_QUERY_JOIN_KEY_COLLISION
```

This is not:

- a strategy or policy defect;
- a candidate-calculation defect;
- an accepted M1.10–M1.14 method defect;
- a data-snapshot defect; or
- a final-decision finding.

## R3 correction

R3 is a **resume runtime**, not another full Phase 2C replay.

It uses this preserved R2 database as an immutable template:

```text
msbf_r1b_p2c_r2_20260829_184119
```

It will not repeat the exact 350-candidate supplemental replay. Instead, it:

1. verifies the complete Phase 2B and supplemental replay state;
2. verifies the exact candidate IDs and requested-stage reproduction results;
3. parses and cardinality-tests all four corrected export queries **before creating another clone**;
4. replaces all problematic application-export `USING` joins with explicit alias-qualified `ON` predicates;
5. replaces wildcard candidate projection with a frozen 49-field source projection;
6. freezes exact export headers and row counts;
7. creates a new disposable R3 clone;
8. executes the final strategy engine;
9. validates selected-candidate references, stress floors, no-feasible proofs and Power BI contracts;
10. installs the five counterfactual analytical facts; and
11. re-verifies that the R2 source database was unchanged.

## Preventive validation completed

```text
Static controls                         12 / 12 PASS
Python compilation                      PASS
Package-manifest mismatches              0
Clean extraction                        PASS
Application export columns             119
Candidate export columns                56
Pre-clone export-query controls           4
Maximum archive-member path              78
Windows path compatibility risk         LOW
Database execution                      NOT RUN
```

I also re-performed the corrected application join from the accepted snapshot and exercised the complete strategy engine structurally using:

```text
Application-scenario rows             1,500
Baseline rows                           750
Recession Energy rows                   750
Scenario-continuity corrections         462
Verification rows                     4,500
Feature rows                          1,500
Unavailable 30-day features             413
Live exact Phase 2B candidates         6,047
Structural supplemental candidates      350
Total exact-search candidate rows      6,397
Nonsearch requested references           122
Power BI offer-candidate rows          6,519
Search application-scenarios             780
Human-review classifications             425
Missing selected-candidate references      0
No-feasible proof gaps                     0
```

The supplemental metrics in that offline exercise were fixtures used only to test the complete engine contract. The live exact supplemental M1.10–M1.14 results already committed in the R2 database remain the R3 source.

# Download Phase 2C R3

Download the Phase 2C R3 resume runtime (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_RESUME_FINAL_STRATEGY_RUNTIME_20260829.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_RESUME_FINAL_STRATEGY_RUNTIME_20260829.zip.sha256`; referenced bytes not established here)

```text
Package size:
34,809 bytes

SHA-256:
a809fd40b3fffa87af186dc3bfa3db7ad947b926a206dfd0c7032a15422fc626

ZIP integrity:
PASS

Archive members:
16
```

Supporting controls:

Open the R3 START HERE guide (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_RESUME_FINAL_STRATEGY_RUNTIME_20260829/00_START_HERE.md`; referenced bytes not established here)

Open the R2 failure analysis and R3 correction record (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_RESUME_FINAL_STRATEGY_RUNTIME_20260829/docs/01_PHASE2C_R2_FAILURE_ANALYSIS_AND_R3_RESUME_CORRECTION.md`; referenced bytes not established here)

Open the R3 method and authority boundary (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_RESUME_FINAL_STRATEGY_RUNTIME_20260829/docs/02_PHASE2C_R3_METHOD_AND_AUTHORITY_BOUNDARY.md`; referenced bytes not established here)

Open the R3 build receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_RESUME_FINAL_STRATEGY_RUNTIME_20260829/BUILD_RECEIPT.json`; referenced bytes not established here)

Open the final package receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_FINAL_PACKAGE_RECEIPT_20260829.json`; referenced bytes not established here)

Open the clean-extraction receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_CLEAN_EXTRACTION_RECEIPT_20260829.json`; referenced bytes not established here)

Plain-text fallbacks:

Download START HERE as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_START_HERE_20260829.txt`; referenced bytes not established here)

Download the failure analysis as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R2_FAILURE_ANALYSIS_AND_R3_CORRECTION_20260829.txt`; referenced bytes not established here)

Download the method boundary as TXT (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R3_METHOD_BOUNDARY_20260829.txt`; referenced bytes not established here)

# Run R3

Extract the ZIP into:

```text
C:\MSBF
```

The resulting folder should be:

```text
C:\MSBF\R1B_PHASE2C_R3
```

Preserve this resume source unchanged:

```text
msbf_r1b_p2c_r2_20260829_184119
```

Run:

```powershell
cd C:\MSBF\R1B_PHASE2C_R3
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\RUN_R1B_PHASE2C_R3.ps1
```

R3 performs its corrected export-query tests before creating a database. After those pass, it creates a new clone resembling:

```text
msbf_r1b_p2c_r3_20260829_XXXXXX
```

When it finishes, upload both generated files from:

```text
C:\MSBF\R1B_PHASE2C_R3\results
```

They will resemble:

```text
msbf_r1b_p2c_r3_..._R1B_PHASE2C_R3_RESULTS.zip
msbf_r1b_p2c_r3_..._R1B_PHASE2C_R3_RESULTS.zip.sha256
```

Do not rerun after either `PASS` or `FAIL`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-47fb8f2a-e45d-4961-8dfd-636f4672821d"></a>
## Andrew / user · C111-M00073

C111-M00073 · 2026-08-29T19:10:44.091000-04:00 · active path

Preceding visible parent: [C111-M00072](part-05.md#m-6a4bc4b5-f460-465f-b42a-b92af2fe0933)

**Editorial record note:** Attachment references: msbf_r1b_p2c_r3_20260829_190652_R1B_PHASE2C_R3_RESULTS.zip; msbf_r1b_p2c_r3_20260829_190652_R1B_PHASE2C_R3_RESULTS.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
MSBF M1/M2 Successor R1B Phase 2C R3 Resume
Purpose: resume from the passed supplemental replay state and complete final strategy/Power BI outputs
Resume source database: msbf_r1b_p2c_r2_20260829_184119
Policy profile: C:\MSBF\R1B_PHASE2C_R3\config\R1_POLICY_PROFILE_OWNER_APPROVED.json

The failed Phase 2C R2 clone will not be modified.
A new disposable clone will be created after read-only export-query preflight.
Counterfactual decisions remain not accepted authority.

PostgreSQL password for local user postgres (not stored):

R1B Phase 2C R3 finished: PASS
Resume source database modified: NO
Clone retained: msbf_r1b_p2c_r3_20260829_190652
Counterfactual final decisions generated: YES
Accepted authority changed: NO
Last stage: COMPLETE
Results: C:\MSBF\R1B_PHASE2C_R3\results\msbf_r1b_p2c_r3_20260829_190652_R1B_PHASE2C_R3_RESULTS.zip
SHA-256: 4114b5c9c17bc4aa2cf4a9ba0cbea1223c337eeeda4e183d70241586301fc7a3
Owner-approved R1 strategy counterfactual: PASS
Upload the result ZIP and sidecar. Accepted authority remains unchanged pending review and audit.

PASS. Upload the generated *_R1B_PHASE2C_R3_RESULTS.zip and sidecar from:
C:\MSBF\R1B_PHASE2C_R3\results
<!-- END_SOURCE_MESSAGE -->


<a id="m-6f438452-ad5b-4c38-9e63-072d85b6c185"></a>
## Assistant · C111-M00074

C111-M00074 · 2026-08-29T20:01:31.789294-04:00 · active path

Preceding visible parent: [C111-M00073](part-05.md#m-47fb8f2a-e45d-4961-8dfd-636f4672821d)

<!-- BEGIN_SOURCE_MESSAGE -->
# Phase 2C R3 review complete

I verified the uploaded result package against its SHA-256 sidecar and independently re-performed the strategy engine from the exact exported inputs. The runtime result is genuine and reproducible. [export reference: filecite | turn14file0 | L1-L6] [export reference: filecite | turn14file1 | L7-L12]

```text
PHASE2C_R3_RUNTIME                         PASS
COUNTERFACTUAL_FINAL_DECISIONS             GENERATED
SOURCE_DATABASE_MODIFIED                   FALSE
ACCEPTED_M1/G2_OR_M2/G3_AUTHORITY_CHANGED FALSE

APPLICATION-SCENARIO ROWS                  1,500
SEARCH APPLICATION-SCENARIOS                 780
EXACT SEARCH CANDIDATES                    6,397
TOTAL REPORTABLE CANDIDATES                6,519
FINAL DECISIONS                            1,500
```

The result is a **material business-strategy success**, but it is not yet ready for physical source integration, Audit, or republication. One new owner policy boundary and several contract/evidence corrections should be resolved in Phase 2C R4.

## Quantified strategy impact

### Baseline population

| Outcome family | Accepted predecessor | Phase 2C R3 |
|---|---:|---:|
| Authorized | **44** | **103** |
| Review | 139 | 197 |
| Policy decline / no feasible / hard stop | 524 | 407 |
| Insufficient evidence | 43 | 43 |

Straight-through authorization rises from **5.9% to 13.7%**.

More broadly, the successor finds an authorized or reviewable structure for **300 of 750 Baseline applications, or 40.0%**, versus 183 predecessor offer/review cases, or 24.4%.

The increase in review is not merely a looser review funnel:

- 118 applications previously receiving immediate policy declines now receive evidence-supported counteroffer review.
- Within the predecessor’s original 139-review population, 57 become authorized, 79 remain review, and 3 become no-feasible.
- The 407 Baseline capacity failures produce 120 supportable structures.
- The 82 Baseline capacity-review rows produce 79 supportable structures.
- All six Baseline capacity-pass/economics-review rows produce a supportable structure.

This confirms the central strategy conclusion: the predecessor was often declining the **merchant** after establishing only that the **requested structure** was unsupported.

### Recession Energy

The governed stress distribution is:

```text
Authorized                         28
Review                             53
No feasible structure            361
Hard policy stop                 117
Insufficient evidence            191
```

Independent stress outcomes and the matched-Baseline route/structure floor remain separately preserved.

## Merchant 000003

Under Baseline, Merchant `000003` is no longer an unsupported policy decline:

```text
Requested amount                  $61,300
Selected counteroffer             $42,500
Selected remittance rate          13.6730%
Selected payback multiple         1.152434
Selected horizon                  60 days

Payment coverage                  1.001210x
Residual daily cash flow          $1.17
Post-financing liquidity          $99,375.85
Integrated risk tier              1
Comparative loss rate             4.1116%
Risk-adjusted contribution        $2,543.11
Annualized RA return              36.4014%

Successor outcome                 COUNTEROFFER_REVIEW_REQUIRED
```

The selected candidate preserves positive economics and restores coverage slightly above 1.00x. It remains reviewable because its exact capacity result is on the review frontier—not because a genuine human-review condition exists.

Under Recession Energy, the merchant remains an insufficient-evidence outcome: two disconnected outage days leave 28 usable POS days against 30 required, so the required 30-day sales feature and dependent capacity assessment remain unavailable.

## New policy gap: total repayment

The approved 40% minimum-counteroffer ratio protects against commercially trivial principal offers, but Phase 2C R3 does not constrain how much the counteroffer can increase **total repayment**.

Among 233 selected counteroffers:

```text
Total repayment above request                 91
Automatically authorized above request        11
Review counteroffers above request            80
Same-principal counteroffers                  120
Largest repayment increase                  21.14%
```

Three automatic counteroffers increase total repayment by approximately 20%–21%. For example, one $5,000 request with a requested repayment of $5,778.23 is converted into a same-principal $7,000 repayment obligation.

Even though such structures pass capacity and portfolio-economics tests, automatic authorization is not commercially appropriate without a merchant-cost guardrail.

## Recommended R4 policy

I recommend adding the following configurable profile values:

```text
automatic_max_total_repayment_increase_rate = 0.00
review_max_total_repayment_increase_rate    = 0.02
total_repayment_rounding_tolerance_amount   = 0.01
```

Meaning:

- An automatically authorized counteroffer cannot exceed the requested total repayment, except for one cent of rounding tolerance.
- A review-frontier counteroffer can increase total repayment by no more than 2%, plus one cent.
- A candidate above 2% is infeasible under the R1 profile.
- These values remain versioned, configurable, hashed, and explicitly authorized for future runs.

### Exact sensitivity

Applying the recommendation:

- Baseline headline distribution remains unchanged: **103 authorized, 197 review, 290 no-feasible, 117 hard stops and 43 evidence declines**.
- Stress changes by one authorization: **27 authorized instead of 28**, with no-feasible increasing from 361 to 362.
- Nineteen selected candidate identities change.
- Six outcome codes change:
  - five counteroffer-review cases become manual review of the requested terms; and
  - one stress counteroffer becomes no-feasible under the Baseline structure floor.
- Total selected structure amount across both scenarios falls by only **$11,900**.
- Automatically authorized higher-cost counteroffers fall from **11 to zero**.

The 2% review allowance is useful because it preserves modest restructuring flexibility where a lower daily burden or different horizon may justify a small cost increase, but keeps that trade-off under explicit human review.

## Other confirmed R4 corrections

These do not require additional owner decisions:

1. **Binding-reason correction.** `HUMAN_REVIEW` is assigned to 195 rows even though their genuine human-review flag is false. Most are actually capacity-review candidates.

2. **Final-decision hash correction.** All 1,500 current decision hashes fail to bind the outcome, selected candidate and policy profile because those values were mistakenly passed as field names.

3. **Candidate hash expansion.** Candidate hashes must bind exact M1.10–M1.14 metrics, selection state, profile identity and accepted-method identity.

4. **Threshold explainability.** The composite capacity gate must be decomposed into reportable coverage, obligation burden, residual cash flow, liquidity-buffer and stacking observations with their exact resolved thresholds.

5. **Independent versus governed candidate lineage.** Thirty-seven stress rows have a different independent candidate and governed candidate after the Baseline floor. Both term sets should be explicit in `FactFinalDecision`.

6. **No-feasible proof contract.** The 651 complete-search proofs should become a curated Power BI fact or equivalent compact contract.

7. **Request-cost fields.** `FactApplicationScenario` should expose requested total repayment and requested daily remittance.

8. **Feature-fact scope.** The current feature fact contains one decision-critical feature; it should be named accordingly or explicitly expanded rather than implying coverage of the accepted 36-feature long population.

9. **Portable JSON determinism.** All 16 CSV outputs re-performed byte-for-byte. The two JSON outputs were semantically identical but differed physically by newline serialization; R4 will use canonical UTF-8/LF output and preserve both physical and semantic hashes.

After R4 stabilizes the decision population, the changed authorizations will require a controlled M2.4–M2.12 downstream rerun so booking, funding, performance, servicing and portfolio outputs align with the successor decisions before Power BI resumes.

## Review package

Open the review start guide (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/00_START_HERE.md`; referenced bytes not established here)

Open the complete Phase 2C R3 evidence review (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/01_PHASE2C_R3_EVIDENCE_REVIEW.md`; referenced bytes not established here)

Open the total-repayment policy decision memo (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/10_POLICY_DECISION_MEMO.md`; referenced bytes not established here)

Open the policy sensitivity register (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/06_TOTAL_REPAYMENT_GUARDRAIL_SENSITIVITY.csv`; referenced bytes not established here)

Open the exact recommended-selection changes (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/06A_RECOMMENDED_GUARDRAIL_SELECTION_CHANGES.csv`; referenced bytes not established here)

Open the R4 correction register (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/07_CONFIRMED_R4_CORRECTION_REGISTER.csv`; referenced bytes not established here)

Open the Merchant 000003 successor trace (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/08_MERCHANT_000003_SUCCESSOR_TRACE.md`; referenced bytes not established here)

Open the independent validation results (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829/14_INDEPENDENT_VALIDATION_RESULTS.csv`; referenced bytes not established here)

Download the complete review and decision package (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R3_EVIDENCE_REVIEW_AND_R4_DECISION_20260829.zip.sha256`; referenced bytes not established here)

```text
Package SHA-256:
e14ce68b0135f6210aefcd8eb2447a05043866aed7dd8928118c7a5a6912407c
```

This is the next genuine owner policy decision. A sufficient authorization is:

> **Approve an automatic maximum total-repayment increase of 0%, a review maximum of 2%, a $0.01 rounding tolerance, and proceed with Phase 2C R4 and the listed contract/evidence corrections.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-6e635d7f-1a8e-426e-b736-a268f0e238fb"></a>
## Andrew / user · C111-M00075

C111-M00075 · 2026-08-29T20:11:35.907000-04:00 · active path

Preceding visible parent: [C111-M00074](part-05.md#m-6f438452-ad5b-4c38-9e63-072d85b6c185)

<!-- BEGIN_SOURCE_MESSAGE -->
Approve an automatic maximum total-repayment increase of 0%, a review maximum of 2%, a $0.01 rounding tolerance, and proceed with Phase 2C R4 and the listed contract/evidence corrections.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-c9dadccb-6d3b-4853-959b-bbbd18412372"></a>
## Assistant · C111-M00076

C111-M00076 · 2026-08-29T20:47:11.215904-04:00 · active path

Preceding visible parent: [C111-M00075](part-05.md#m-6e635d7f-1a8e-426e-b736-a268f0e238fb)

<!-- BEGIN_SOURCE_MESSAGE -->
# Phase 2C R4 construction complete

The approved repayment-cost guardrails and all listed contract/evidence corrections are now implemented in a new one-command R4 runtime.

```text
R4_CONSTRUCTION_STATUS                    PASS
OFFLINE_EXACT-INPUT_REPERFORMANCE         PASS
OFFLINE_VALIDATION_CONTROLS               57 / 57 PASS
STATIC_PACKAGE_CONTROLS                   PASS
NEGATIVE_CONTROLS                         7 / 7 PASS
NONDEFAULT_PROFILE_EXERCISE               PASS
CLEAN_EXTRACTION                          PASS
LIVE_POSTGRESQL_R4_EXECUTION              NOT YET RUN
ACCEPTED_M1/G2_OR_M2/G3_AUTHORITY_CHANGED FALSE
```

## Approved R4 policy

The default profile now enforces:

```text
Minimum counteroffer amount             40% of requested amount
Maximum exposure reduction              60%
Automatic total-repayment increase       0%
Review total-repayment increase           2%
Rounding tolerance                       $0.01
Supported payoff horizons                30 / 60 / 90 days
Economic hurdle                          Required
Selection                                Dual-frontier, authority-first
```

Operationally:

- An automatic counteroffer may not increase total repayment beyond the requested repayment, except for one cent of rounding tolerance.
- A reviewable counteroffer may increase total repayment by no more than 2%, plus one cent.
- A candidate above the review limit is infeasible.
- A strict automatic candidate is preferred over a larger marginal candidate that requires review.

## Contract and evidence corrections included

R4 now provides:

- genuine human-judgment reasons separately from candidate review-frontier reasons;
- corrected final-decision hashes binding the actual outcome, candidate, request, profile, method, floor and explanation values;
- expanded candidate hashes binding M1.10–M1.14 metrics and selection state;
- canonical UTF-8/LF JSON output;
- component capacity gates for coverage, obligation burden, residual cash flow, liquidity buffer and stacking;
- independent, matched-Baseline and governed candidate terms;
- explicit route-floor and structure-floor lineage;
- one curated proof row for every governed no-feasible outcome;
- requested total repayment and requested daily remittance in the application fact;
- an explicitly scoped `DecisionCriticalFeatureAvailability` fact; and
- exact R3 candidate and decision hashes retained as correction history.

## Frozen default-profile expectations

The live PostgreSQL run must reproduce:

```text
Application-scenario decisions            1,500
Search application-scenarios                780
Exact search candidates                   6,397
Requested-reference candidates              122
Reportable candidates                     6,519
Decision-gate rows                       84,228
No-feasible proof rows                      652

Authorized                                  130
Review                                      250
No feasible structure                       652
Hard policy stop                            234
Insufficient evidence                       234

R3 → R4 selected-candidate changes           19
R3 → R4 outcome-code changes                  6
Automatic higher-cost counteroffers           0
```

These remain construction expectations until the desktop run reproduces them.

## Future-run flexibility

The runtime includes a versioned future-user profile template. Bounded policy inputs can be changed without editing strategy code, including:

- minimum counteroffer ratio;
- maximum exposure reduction;
- automatic and review repayment-increase limits;
- supported subset of 30/60/90-day horizons;
- strict and review risk/resilience ceilings;
- genuine human-review conditions; and
- advisory classifications.

Every profile is hashed and retained in evidence. A nondefault profile requires the explicit `-AuthorizeNonDefaultProfile` switch. Accepted calculation methods, new horizon parameters, candidate-generation templates, selection algorithms, search populations and Campaign dimensions remain controlled changes requiring a fresh governed run rather than a silent parameter override.

# Download the R4 runtime

Download the Phase 2C R4 final-strategy correction runtime (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_FINAL_STRATEGY_CORRECTION_RUNTIME_20260829.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_FINAL_STRATEGY_CORRECTION_RUNTIME_20260829.zip.sha256`; referenced bytes not established here)

```text
Package size:
121,781 bytes

SHA-256:
ae73cd58405d13d938a620178de2e3a8fce500fb2c84195540f6d8c0598fed0f

ZIP integrity:
PASS

Archive members:
38

Maximum archive-member path:
115 characters
```

Supporting controls:

Open the R4 START HERE guide (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_START_HERE_20260829.md`; referenced bytes not established here)

Download START HERE as plain text (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_START_HERE_20260829.txt`; referenced bytes not established here)

Open the owner policy-decision receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_OWNER_POLICY_DECISION_RECEIPT_20260829.json`; referenced bytes not established here)

Open the method and authority boundary (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_METHOD_AND_AUTHORITY_BOUNDARY_20260829.md`; referenced bytes not established here)

Open the contract and evidence corrections (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_CONTRACT_AND_EVIDENCE_CORRECTIONS_20260829.md`; referenced bytes not established here)

Open the correction register (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_CORRECTION_REGISTER_20260829.csv`; referenced bytes not established here)

Open the construction receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_BUILD_RECEIPT_20260829.json`; referenced bytes not established here)

Open the final package receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_FINAL_PACKAGE_RECEIPT_20260829.json`; referenced bytes not established here)

Open the clean-extraction receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1B_PHASE2C_R4_CLEAN_EXTRACTION_RECEIPT_20260829.json`; referenced bytes not established here)

# Run R4

Extract the ZIP into:

```text
C:\MSBF
```

The resulting folder should be:

```text
C:\MSBF\R1B_PHASE2C_R4
```

Preserve the passed R3 source database unchanged:

```text
msbf_r1b_p2c_r3_20260829_190652
```

Run the approved default profile:

```powershell
cd C:\MSBF\R1B_PHASE2C_R4
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\RUN_R1B_PHASE2C_R4.ps1
```

The runtime will:

1. preflight the R3 source state and all six input queries read-only;
2. create a new disposable `msbf_r1b_p2c_r4_...` clone;
3. reproduce the complete R4 decision population;
4. reperform every candidate, decision, gate, feature, proof and comparison hash;
5. validate the exact R3-to-R4 changes;
6. install six counterfactual analytical tables in `msbf_m12r1d`;
7. generate the corrected Power BI handoff package; and
8. verify that the R3 source database remained unchanged.

After either `PASS` or `FAIL`, upload the generated results ZIP and sidecar from:

```text
C:\MSBF\R1B_PHASE2C_R4\results
```

Do not rerun it. The captured evidence will govern the next step.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c25597e7-a134-4173-8bb8-1f8da8c24976"></a>
## Andrew / user · C111-M00077

C111-M00077 · 2026-08-29T20:54:55.124000-04:00 · active path

Preceding visible parent: [C111-M00076](part-05.md#m-c9dadccb-6d3b-4853-959b-bbbd18412372)

**Editorial record note:** Attachment references: msbf_r1b_p2c_r4_20260829_204955_R1B_PHASE2C_R4_RESULTS.zip; msbf_r1b_p2c_r4_20260829_204955_R1B_PHASE2C_R4_RESULTS.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
MSBF M1/M2 Successor R1B Phase 2C R4
Purpose: owner-approved repayment guardrails, corrected evidence contracts, final counterfactual decisions, and Power BI handoff
Source Phase2C R3 database: msbf_r1b_p2c_r3_20260829_190652
Policy profile: C:\MSBF\R1B_PHASE2C_R4\config\R1_POLICY_PROFILE_OWNER_APPROVED_R4.json

The passed Phase2C R3 database will not be modified.
A new disposable clone will be created after read-only preflight.
Counterfactual decisions remain not accepted authority.

PostgreSQL password for local user postgres (not stored):

R1B Phase 2C R4 finished: PASS
Source Phase2C R3 database modified: NO
Clone retained: msbf_r1b_p2c_r4_20260829_204955
Counterfactual final decisions generated: YES
Accepted authority changed: NO
Last stage: COMPLETE
Results: C:\MSBF\R1B_PHASE2C_R4\results\msbf_r1b_p2c_r4_20260829_204955_R1B_PHASE2C_R4_RESULTS.zip
SHA-256: 1377e860629109fa9b19b479becc50e8a0d99cf55f1c760299de4203df6238d6
Owner-approved R1 Phase 2C R4 counterfactual: PASS
Upload the result ZIP and sidecar. Accepted authority remains unchanged pending source integration, downstream rerun, and audit.

PASS. Upload the generated *_R1B_PHASE2C_R4_RESULTS.zip and sidecar from:
C:\MSBF\R1B_PHASE2C_R4\results
<!-- END_SOURCE_MESSAGE -->


<a id="m-004e7766-0a00-4337-8d98-1670785a1069"></a>
## Assistant · C111-M00078

C111-M00078 · 2026-08-29T21:39:01.499359-04:00 · active path

Preceding visible parent: [C111-M00077](part-05.md#m-c25597e7-a134-4173-8bb8-1f8da8c24976)

<!-- BEGIN_SOURCE_MESSAGE -->
# Phase 2C R4 is validated

I verified the uploaded R4 results package and its SHA-256 sidecar. [export reference: filecite | turn14file0 | L1-L6] [export reference: filecite | turn14file1 | L7-L12]

The runtime completed successfully and independently reproduced the owner-approved strategy, repayment guardrails, corrected hashes, evidence contracts, and Power BI facts.

```text
PHASE2C_R4_RUNTIME                         PASS
RESULT_PACKAGE_SHA-256                    1377e860629109fa9b19b479becc50e8a0d99cf55f1c760299de4203df6238d6
APPLICATION-SCENARIO DECISIONS            1,500
REPORTABLE CANDIDATES                     6,519
DECISION-GATE ROWS                        84,228
NO-FEASIBLE PROOFS                          652
SELECTED-CANDIDATE REFERENCE GAPS             0
HASH-PAYLOAD MISMATCHES                       0
AUTOMATIC HIGHER-COST COUNTEROFFERS           0
SOURCE DATABASE MODIFIED                  FALSE
ACCEPTED AUTHORITY CHANGED                FALSE
```

## Final R4 strategy population

| Governed outcome family | Baseline | Recession Energy | Total |
|---|---:|---:|---:|
| Authorized | 103 | 27 | **130** |
| Review | 197 | 53 | **250** |
| No feasible structure | 290 | 362 | **652** |
| Hard policy stop | 117 | 117 | **234** |
| Insufficient evidence | 43 | 191 | **234** |
| **Total** | **750** | **750** | **1,500** |

The strategy recovers **143 predecessor policy declines** into an authorized or reviewable structure while preserving the approved capacity, risk, expected-loss, economic, amount-floor, horizon, and repayment-cost boundaries.

R4 is now the controlling **successor counterfactual construction result**. It is not yet revised M1/G2 or M2/G3 authority.

## R4 review package

Open the R4 review start guide (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R4_EVIDENCE_REVIEW_20260830/00_START_HERE.md`; referenced bytes not established here)

Open the complete R4 evidence review (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R4_EVIDENCE_REVIEW_20260830/01_PHASE2C_R4_EVIDENCE_REVIEW.md`; referenced bytes not established here)

Download the complete R4 evidence-review package (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R4_EVIDENCE_REVIEW_20260830.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M1M2_PHASE2C_R4_EVIDENCE_REVIEW_20260830.zip.sha256`; referenced bytes not established here)

```text
R4 review-package SHA-256:
5da7b7d948aae22ddb9ef7a1e96292166c07274e1cad0c949f29ca289b2b6bc7
```

# Next step: physical compatibility integration and M2.4 rebase

The next runtime is ready. It is the first physical downstream-integration step.

It will:

1. preserve the accepted predecessor M2.3 latest table, registry, and acceptance gate unchanged;
2. install a separate immutable, versioned **R4 M2.3 compatibility source**;
3. map the refined successor outcomes into the four broad codes M2.4–M2.12 currently understand;
4. archive and invalidate predecessor M2.4–M2.12 closure claims inside the new disposable clone;
5. rebase M2.4 booking, synthetic funding, account creation, advance creation, and initial portfolio activation;
6. execute the accepted M2.4 negative-control method;
7. run transformed M2.4 generation, 120 positive controls, 20 negative controls, and closure validation; and
8. leave M2.5–M2.12 explicitly marked `PENDING_REBASE`.

The refined R4 decisions remain authoritative within the successor candidate. The broad compatibility code is a transport layer only; it does not replace the refined outcomes, candidate evidence, binding gates, explanation lineage, thresholds, or no-feasible proofs.

## Expected M2.4 result

```text
Compatibility-source rows                    1,500

Synthetic activated accounts                   130
Synthetic funded advances                      130
Initial portfolio rows                         130

Baseline funded paths                          103
Recession Energy funded paths                   27

Review paths                                   250
Insufficient-evidence paths                    234
Policy/no-feasible/hard-stop paths             886

Matched scenario comparisons                   750
Stress activation improvements                   0
Stress funded-amount improvements                0

Positive controls                         120 / 120
Negative controls                           20 / 20
```

The runtime was statically validated through **22 controls**, includes the exact accepted M1.10–M1.14 source bytes and hashes, passed clean extraction, and has a maximum archive path of 127 characters.

# Download the runtime

Download the R1 source-integration and M2.4-rebase runtime (historical reference: `sandbox:[session]/MSBF_M1M2_R1_SOURCE_INTEGRATION_M2_4_REBASE_RUNTIME_20260830.zip`; referenced bytes not established here)

Download its SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_M1M2_R1_SOURCE_INTEGRATION_M2_4_REBASE_RUNTIME_20260830.zip.sha256`; referenced bytes not established here)

```text
Package size:
319,476 bytes

SHA-256:
a40f34083e59540842e9b530f29c0d968a966453ec1f00109c1cdf197f864524

ZIP integrity:
PASS
```

Supporting controls:

Open the START HERE guide (historical reference: `sandbox:[session]/MSBF_M1M2_SOURCE_INTEGRATION_M2_4_REBASE_R1_20260830/00_START_HERE.md`; referenced bytes not established here)

Open the source-integration architecture (historical reference: `sandbox:[session]/MSBF_M1M2_SOURCE_INTEGRATION_M2_4_REBASE_R1_20260830/docs/01_SOURCE_INTEGRATION_ARCHITECTURE.md`; referenced bytes not established here)

Open the M2.4 rebase boundary (historical reference: `sandbox:[session]/MSBF_M1M2_SOURCE_INTEGRATION_M2_4_REBASE_R1_20260830/docs/02_M2_4_REBASE_BOUNDARY.md`; referenced bytes not established here)

Open the static-validation results (historical reference: `sandbox:[session]/MSBF_M1M2_SOURCE_INTEGRATION_M2_4_REBASE_R1_20260830/evidence/01_STATIC_VALIDATION_RESULTS.csv`; referenced bytes not established here)

Open the final package receipt (historical reference: `sandbox:[session]/MSBF_M1M2_R1_SOURCE_INTEGRATION_M2_4_REBASE_FINAL_PACKAGE_RECEIPT_20260830.json`; referenced bytes not established here)

Open the exact 1,500-row downstream compatibility source (historical reference: `sandbox:[session]/MSBF_M1M2_SOURCE_INTEGRATION_M2_4_REBASE_R1_20260830/data/M2_3_SUCCESSOR_DOWNSTREAM_COMPATIBILITY.csv`; referenced bytes not established here)

# Desktop execution

Extract the ZIP into:

```text
C:\MSBF
```

The resulting directory should be:

```text
C:\MSBF\R1_SOURCE_INTEGRATION_M2_4
```

Preserve this passed R4 source database unchanged:

```text
msbf_r1b_p2c_r4_20260829_204955
```

Run:

```powershell
cd C:\MSBF\R1_SOURCE_INTEGRATION_M2_4
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\RUN_SOURCE_INTEGRATION_M2_4_R1.ps1
```

The runtime will create a new disposable clone resembling:

```text
msbf_r1_m2_4_20260830_XXXXXX
```

When it completes, upload the generated results ZIP and SHA-256 sidecar from:

```text
C:\MSBF\R1_SOURCE_INTEGRATION_M2_4\results
```

Do not rerun after either `PASS` or `FAIL`. The result will determine the M2.5–M2.12 rebase plan.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ed1c1af5-91ad-4237-a64b-87519f8f19c3"></a>
## Andrew / user · C111-M00079

C111-M00079 · 2026-08-29T22:36:33.335000-04:00 · active path

Preceding visible parent: [C111-M00078](part-05.md#m-004e7766-0a00-4337-8d98-1670785a1069)

**Editorial record note:** Attachment references: msbf_r1_m2_4_20260829_223315_SOURCE_INTEGRATION_M2_4_R1_RESULTS.zip; msbf_r1_m2_4_20260829_223315_SOURCE_INTEGRATION_M2_4_R1_RESULTS.zip.sha256

<!-- BEGIN_SOURCE_MESSAGE -->
MSBF M1/M2 R1 Source Integration + M2.4 Rebase
Source R4 database: msbf_r1b_p2c_r4_20260829_204955
The passed R4 database will not be modified.
A new disposable clone will be created.

PostgreSQL password for local user postgres (not stored):

Source Integration / M2.4 R1 finished: FAIL
Source R4 database modified: NO
Clone retained: msbf_r1_m2_4_20260829_223315
Results: C:\MSBF\R1_SOURCE_INTEGRATION_M2_4\results\msbf_r1_m2_4_20260829_223315_SOURCE_INTEGRATION_M2_4_R1_RESULTS.zip
SHA-256: b89d8801b9749090f2efa28d52aa569492ca9d9ad5bf62d9e7f47efed8c88fc5
Failure: RuntimeError('Command failed (3): C:\\Program Files\\PostgreSQL\\17\\bin\\psql.exe -h localhost -p 5432 -U postgres -d msbf_r1_m2_4_20260829_223315 -X -v ON_ERROR_STOP=1 -f C:\\MSBF\\R1_SOURCE_INTEGRATION_M2_4\\sql\\01_FINALIZE_COMPATIBILITY_AND_CONFIGURATION.sql')
Source Integration / M2.4 R1 stopped fail-closed. Upload the generated results ZIP and sidecar from C:\MSBF\R1_SOURCE_INTEGRATION_M2_4\results.
At C:\MSBF\R1_SOURCE_INTEGRATION_M2_4\RUN_SOURCE_INTEGRATION_M2_4_R1.ps1:14 char:28
+ ... DE -ne 0) { throw "Source Integration / M2.4 R1 stopped fail-closed.  ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : OperationStopped: (Source Integrat...N_M2_4\results.:String) [], RuntimeException
    + FullyQualifiedErrorId : Source Integration / M2.4 R1 stopped fail-closed. Upload the generated results ZIP and sidecar from C:\MSBF\R1_SOURCE_INTEGRATION_M2_4\results.
<!-- END_SOURCE_MESSAGE -->
