# MSBF - Power BI Executive Portfolio Intelligence Part 3

Part 04 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-03.md)
[Next part](part-05.md)

<a id="m-8c7311e5-6a2a-4af2-88cd-ee7868ce2f38"></a>
## Assistant · C118-M00051

C118-M00051 · 2026-09-03T17:15:56.936414-04:00 · active path

Preceding visible parent: [C118-M00050](part-03.md#m-ec198197-9f20-4674-90a3-4d0e5096882f)

<!-- BEGIN_SOURCE_MESSAGE -->
# P04 design decision

**Disposition:** `KEEP_PAGE_SKELETON / REPLACE_PREDECESSOR_SEMANTICS / REPURPOSE_LOWER_DETAIL`

The current P04 layout has the right basic operating model:

- one Scenario controller;
- an endpoint summary;
- monitoring and servicing charts;
- an account-level workbench;
- a lower-detail area.

It should **not** be rebuilt from scratch. But it also should not be treated as nearly complete. The physical binding inventory shows that its substantive visuals still depend on predecessor `FactMonitoringEndpoint`, `FactServicingExecution`, `FactPaymentException`, and predecessor `P04 ...` measures. Even the two chart subtitles are leftover text about “four accepted decision outcomes,” which does not describe either chart. [export reference: filecite | turn99file0 | L78-L90] [export reference: filecite | turn99file0 | L93-L116]

The correct P04 work is a **controlled semantic rebase with one purposeful structural change**: replace the unsupported event-level **Payment exception history** with a successor-supported **Payment & certification detail** table.

---

# 1. Story told across the portfolio so far

| Page | Question answered |
|---|---|
| **P01 — Cohort Command Center** | What portfolio was generated, what decisions and exposure exist, and what is the governed endpoint status? |
| **P02 — Cohort Lifecycle** | How did the funded cohort progress through exposure, remittance, monitoring, and payoff over time? |
| **P03 — Application Journey** | Why did one application receive its governed outcome and proposed structure, and—when funded—what happened to that account? |
| **P04 — Servicing & Exceptions** | Which funded accounts require operational attention at the endpoint, why, what intervention was recommended, how did the governed setup and servicing path progress, and did the resulting account state reconcile? |

That P04 story should move in this order:

```text
Find the attention population
        ↓
Understand the monitoring driver
        ↓
See the recommended intervention
        ↓
Trace operational setup and execution
        ↓
Verify payment, exception, and certification outcome
```

The successor architecture explicitly separates M2.6 intervention, M2.7 setup, M2.8 execution, M2.9 certification, and M2.10 performance. P04 should make that progression intelligible without blending the stages together. [export reference: filecite | turn95file15 | L619-L644]

---

# 2. What the current page gets right—and wrong

## What to keep

Keep:

- page title;
- one Scenario slicer;
- endpoint-only design with **no Observation date slicer**;
- left-side KPI stack;
- two top charts;
- middle account workbench;
- lower selected-account detail area;
- workbench interaction that leaves the portfolio KPIs and charts stable while filtering the lower detail;
- native visuals and the current basic geometry.

## What must change

### A. The current population is the predecessor population

The old page reflects the earlier servicing implementation that had 59 servicing rows, 57 with no processing, one active temporary-processing path, and one review hold. [export reference: filecite | turn96file19 | L793-L835]

The current R26 successor has:

```text
R1FactIntervention             130 rows
R1FactOperationalSetup         130 rows
R1FactServicingExecution       130 rows
R1FactAccountCertification     130 rows
R1FactPortfolioPerformance     130 rows
```

Each is at one row per exact `ApplicationScenarioKey`, while daily monitoring remains 15,600 rows at application-scenario × monitoring-day grain. [export reference: filecite | turn102file1 | L21-L27]

### B. The current page understates the operational population

The current Baseline screenshot shows:

```text
Requiring attention       2
Active servicing          1
Review holds              1
```

Direct reconciliation of the current physical R26 carrier produces:

```text
Baseline funded paths            103
Endpoint paid off                 99
Endpoint severe shortfall          4
Accounts requiring attention       4
Active servicing                    1
Review holds                        3
```

So the present page is not just using old names—it is displaying a materially obsolete population.

### C. The current account story is wrong

The predecessor page presents **merchant 312** as the temporary-payment active-servicing path. The illustrative handoff also repeated 312 as that case. [export reference: filecite | turn95file15 | L654-L660]

The current R26 physical carrier instead establishes:

- **749 / Baseline** as the single temporary-remittance, active-processing, return-and-retry path;
- **098, 112, and 312 / Baseline** as targeted-outreach, governance-review, execution-review-hold paths.

The exact current retry case is merchant 749, with seven payment events, one return, one retry, exact reconciliation, and certified ending exposure. [export reference: filecite | turn96file7 | L197-L215]

This is why P04 must be rebuilt from the successor chain rather than cosmetically rebinding old labels.

### D. Payment exception history cannot remain

The current lower table uses predecessor event-level fields:

```text
originating_event_date
exception_amount
resolving_event_date
exception_open_days
```

from `FactPaymentException`. [export reference: filecite | turn99file0 | L104-L110]

The current R1 curated carrier does **not** provide a successor event-level payment-exception table with those dates. It provides payment-event counts and amounts through M2.8, followed by exception-resolution and reconciliation state through M2.9/M2.10.

We must not fabricate an event history or preserve predecessor events merely because the old visual looks useful.

---

# 3. Final P04 page story and layout

## Page title

Keep:

> **Merchant Servicing & Exceptions**

## Subtitle

Replace the current subtitle with:

> **Identify funded accounts requiring operational attention, understand the drivers, and trace governed intervention, servicing, and certification outcomes.**

That better represents the full M2.5–M2.10 progression.

## Final visual architecture

| Page area | Final visual |
|---|---|
| Left | Endpoint operational KPI stack |
| Upper middle | **Endpoint monitoring posture** |
| Upper right | **Servicing execution state** |
| Middle | **Account attention workbench** |
| Lower | **Payment & certification detail** |
| Top | Scenario slicer only |
| Footer | Current R26/C2 identity and bounded synthetic interpretation |

This is a **moderate redesign**, not a wholesale replacement.

---

# 4. Governing source map

Use this exact division of responsibility:

| Story element | Governing source |
|---|---|
| Merchant/scenario row anchor | `R1DimApplicationScenario` |
| Endpoint monitoring state and receivable | `R1FactDailyMonitoring`, endpoint row |
| Recommended intervention | `R1FactIntervention` — M2.6 |
| Operational setup/review state | `R1FactOperationalSetup` — M2.7 |
| Payment-processing and servicing execution | `R1FactServicingExecution` — M2.8 |
| Reconciliation and certified account state | `R1FactAccountCertification` — M2.9 |
| Final servicing queue, performance tier, exceptions, and burden | `R1FactPortfolioPerformance` — M2.10 |

The M2.6 total population remains exactly:

```text
126  Closed / no further action
  3  Targeted merchant outreach review
  1  Temporary remittance-adjustment review
```

[export reference: filecite | turn95file15 | L646-L652]

Use `ApplicationScenarioKey` as the exact cross-stage identity. Do not join or resolve the chain using merchant number alone.

---

# 5. Step-by-step production roadmap

## Step 1 — Preserve the controlled starting state

Continue in:

```text
MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902
```

Do not create C3.

The R4 package already preserves the physical current P04 before-state, so a duplicate page is not required. Save C2 before installing any P04 measures.

Do not:

- delete predecessor tables from the model;
- edit accepted source queries;
- add relationships;
- mutate the R26 source facts;
- create an observation-date slicer;
- infer servicing from raw alert counts;
- use `operational_activation_date` as a funding date. [export reference: filecite | turn95file15 | L633-L645]

Unbinding predecessor objects from P04 is authorized; deleting them from the shared model is not part of this page rebase.

---

## Step 2 — Create a bounded P04 presentation layer

Place the new objects under `R1Measures` with these folders:

```text
P04 | 01 Summary
P04 | 02 Monitoring
P04 | 03 Workbench
P04 | 04 Servicing & Certification
P04 | 90 Accessibility
P04 | 99 QA
```

Create only report-owned presentation adapters and context adapters. No servicing method belongs in DAX.

### Reuse existing canonical semantics

Where an existing accepted measure already owns the metric, use a page alias rather than recreating it:

```text
R26 P04 Accounts Requiring Attention
    → R26 P02 Accounts in Adverse Monitoring Status As Of

R26 P04 Review Holds
    → R1 P01 Review-Hold Paths

R26 P04 Certified Exposure
    → R1 P01 Certified Exposure

R26 P04 Servicing Burden
    → R1 P01 Servicing Burden Units

R26 P04 Unresolved Exceptions
    → R1 P01 Unresolved Exceptions

R26 P04 Intervention Display
    → R26 P03 Intervention Display
```

This follows the established P01/P02 alias hierarchy rather than creating competing formulas. P01 already owns certified exposure, unresolved exceptions, review holds, and servicing burden from the R1 certification and performance facts. [export reference: filecite | turn96file12 | L491-L509] [export reference: filecite | turn96file13 | L520-L540]

### Create P04-specific context adapters

P04-specific measures are needed for:

- endpoint monitoring status by application-scenario;
- endpoint remittance pace;
- endpoint remaining exposure;
- attention flag;
- active-servicing count;
- monitoring count by displayed status;
- monitoring exposure by displayed status;
- servicing count by execution state;
- certified exposure and burden by execution state;
- setup-state display;
- execution-state display;
- reconciliation display;
- endpoint performance-state display;
- payment-event count;
- processed-payment amount;
- return/retry summary;
- exception-resolution display;
- certification date.

### Presentation columns

Create only the category/display columns required for chart axes:

1. `R26 P04 Monitoring Status Display`
2. `R26 P04 Monitoring Status Sort`
3. `R26 P04 Servicing Execution State Display`
4. `R26 P04 Servicing Execution State Sort`
5. `R26 P04 Merchant Display`

These are friendly-label and sort adapters, not new business classifications.

---

# 6. Rebuild the left KPI stack

I recommend **seven** endpoint KPIs:

| Order | Display label | Semantic source |
|---:|---|---|
| 1 | **Requiring attention** | Adverse endpoint monitoring population |
| 2 | **Attention exposure** | Endpoint remaining receivable on adverse paths |
| 3 | **Active servicing** | M2.8 processing-authorized paths |
| 4 | **Review holds** | M2.8/M2.10 governed review-hold paths |
| 5 | **Certified exposure** | M2.9 certified residual exposure |
| 6 | **Servicing burden** | M2.10 workload units |
| 7 | **Unresolved exceptions** | M2.10 unresolved exception count |

This creates a coherent progression:

```text
Monitoring need
→ exposure
→ execution state
→ certification
→ workload
→ unresolved controls
```

### Expected default values

| KPI | Baseline | Recession Energy |
|---|---:|---:|
| Requiring attention | **4** | **0** |
| Attention exposure | **$7,823.28** | **$0.00** |
| Active servicing | **1** | **0** |
| Review holds | **3** | **0** |
| Certified exposure | **$6,061.03** | **$0.00** |
| Servicing burden | **17** | **0** |
| Unresolved exceptions | **0** | **0** |

Seven values should fit with slightly tighter vertical spacing. If visual readability requires six, move **Certified exposure** to the lower detail and retain the other six. Do not remove Servicing burden; it is the direct M2.10 workload signal.

---

# 7. Rebuild the first chart

## Title

Change:

> Monitoring posture

to:

> **Endpoint monitoring posture**

## Optional subtitle

> **Funded accounts at the governed 2026-11-22 synthetic endpoint.**

## Bindings

| Role | Binding |
|---|---|
| Y-axis/category | `R26 P04 Monitoring Status Display` |
| X-axis/value | `R26 P04 Monitoring Account Count` |
| Tooltip | `R26 P04 Monitoring Exposure` |
| Tooltip | `R26 P04 Average Remittance Pace` |
| Tooltip | Operational alert-family count, only if useful |

Apply a visual-level endpoint filter:

```text
R1FactDailyMonitoring[monitoring_day_index] = 120
```

The current source contract contains exactly one day-120 row for every funded application-scenario.

Use the full governed status vocabulary:

```text
Dormant / no remittance
Severe shortfall
Underperforming
Watch
Current
Paid off
```

Sort from most operationally severe to Paid off.

The chart should show the complete endpoint posture, but the **Requiring attention** KPI must count only:

```text
UNDERPERFORMING
SEVERE_SHORTFALL
DORMANT_NO_REMITTANCE
```

It must exclude `WATCH`, `CURRENT`, and `PAID_OFF`. The accepted monitoring interpretation expressly treats Watch as broader monitoring evidence rather than an adverse servicing population. [export reference: filecite | turn97file1 | L77-L127]

### Expected chart results

```text
Baseline
  Severe shortfall     4
  Paid off            99

Recession Energy
  Paid off            27
```

Remove the current copied subtitle:

> Four accepted decision outcomes at application-scenario grain.

---

# 8. Rebuild the second chart

## Title

Change:

> Servicing disposition

to:

> **Servicing execution state**

## Optional subtitle

> **Funded paths requiring active processing or governed review.**

## Bindings

| Role | Binding |
|---|---|
| Y-axis/category | `R26 P04 Servicing Execution State Display` |
| X-axis/value | `R26 P04 Servicing Account Count` |
| Tooltip | `R26 P04 Certified Exposure` under execution-state context |
| Tooltip | `R26 P04 Servicing Burden` under execution-state context |

Apply this visual filter:

```text
R1FactServicingExecution[no_processing_required_flag] = FALSE
```

This chart should deliberately omit the 99 or 27 `No servicing required` paths. Including them would visually swamp the four actionable Baseline accounts and undermine the page's operational purpose.

Use only these currently populated categories:

```text
Active servicing
Review hold
```

### Expected results

```text
Baseline
  Active servicing     1
  Review hold          3

Recession Energy
  no actionable rows
```

Remove the current copied decision-outcome subtitle here as well.

---

# 9. Rebuild the Account attention workbench

## Title

Keep:

> **Account attention workbench**

## Governing row anchor

Anchor the visual on:

```text
R1DimApplicationScenario
```

not directly on one of the facts.

That ensures a selected row filters all M2.5–M2.10 facts through the exact application-scenario dimension rather than attempting fact-to-fact propagation.

## Final columns

| Order | Display label | Source stage |
|---:|---|---|
| 1 | **Merchant** | `R1DimApplicationScenario` |
| 2 | **Monitoring status** | M2.5 endpoint adapter |
| 3 | **Remittance pace** | M2.5 endpoint adapter |
| 4 | **Attention exposure** | M2.5 endpoint receivable |
| 5 | **Intervention** | M2.6 |
| 6 | **Setup state** | M2.7 |
| 7 | **Execution state** | M2.8 |
| 8 | **Endpoint state** | M2.10 |

Apply:

```text
R26 P04 Requires Attention Flag = 1
```

Sort by **Attention exposure descending**.

### Friendly state mappings

**Setup state**

```text
NO_OPERATIONAL_SETUP_REQUIRED
→ No setup required

OPERATIONAL_SETUP_REVIEW_REQUIRED
→ Governance review required

TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY
→ Temporary-adjustment setup ready
```

**Execution state**

```text
NO_SERVICING_EXECUTION_REQUIRED
→ No servicing required

SERVICING_EXECUTION_REVIEW_HOLD
→ Review hold

SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE
→ Active servicing
```

**Endpoint state**

```text
CLOSED_STABLE
→ Closed stable

CONTROLLED_REVIEW
→ Controlled review

ACTIVE_RECONCILED
→ Active reconciled
```

Do not collapse Intervention, Setup state, Execution state, and Endpoint state into one generic “Disposition” field. Their progression is the page's central analytical story.

### Expected Baseline rows

| Merchant | Intervention | Setup | Execution | Endpoint |
|---:|---|---|---|---|
| **000749** | Temporary remittance review | Setup ready | Active servicing | Active reconciled |
| **000098** | Targeted outreach review | Governance review | Review hold | Controlled review |
| **000112** | Targeted outreach review | Governance review | Review hold | Controlled review |
| **000312** | Targeted outreach review | Governance review | Review hold | Controlled review |

Recession Energy should produce **zero workbench rows**.

This directly corrects the predecessor page, where 312 was shown as the active temporary-payment path.

---

# 10. Replace Payment exception history

## Remove

Remove all predecessor bindings from:

> Payment exception history

including:

```text
FactPaymentException[P04 Exception Merchant]
FactPaymentException[originating_event_date]
FactPaymentException[exception_amount]
FactPaymentException[P04 Exception Status]
FactPaymentException[resolving_event_date]
FactPaymentException[exception_open_days]
FactPaymentException[P04 Exception Resolution]
```

Do not retain the title “history.”

## New title

Use:

> **Payment & certification detail**

## Optional subtitle

> **Select an attention-workbench row to isolate one funded account.**

## Final columns

| Order | Display label | Governing source |
|---:|---|---|
| 1 | **Merchant** | `R1DimApplicationScenario` |
| 2 | **Execution** | M2.8 |
| 3 | **Payment events** | M2.8 `payment_event_count` |
| 4 | **Processed** | M2.8/M2.9 `processed_payment_amount` |
| 5 | **Return / retry** | M2.8 returned and retry counts/amounts |
| 6 | **Reconciliation** | M2.9 `reconciliation_outcome_code` |
| 7 | **Certified on** | M2.9 `certification_date` |
| 8 | **Certified exposure** | M2.9 `certified_exposure_amount` |

The Return / retry display should render examples such as:

```text
None
1 returned / 1 retried
```

The Reconciliation display should render:

```text
No payment activity — reconciled
Reconciled after retry
Reconciliation review hold
```

This table tells a truthful account-level processing and control story without implying the carrier contains dated event-history rows that do not exist.

---

# 11. Preserve and tighten interactions

## Scenario slicer

Scenario must filter:

- all seven KPIs;
- Endpoint monitoring posture;
- Servicing execution state;
- Account attention workbench;
- Payment & certification detail;
- footer context where applicable.

## Workbench

A selected workbench row should filter **only**:

> Payment & certification detail

It should **not** change:

- the portfolio KPI stack;
- Endpoint monitoring posture;
- Servicing execution state.

That preserves the distinction between:

- portfolio posture; and
- selected-account detail.

## Charts

Do not permit either chart to cross-highlight the KPI stack, the other chart, or the workbench. The Scenario slicer should be the only page-wide controller.

No Merchant slicer and no Observation-date slicer should be added.

---

# 12. Footer and boundary update

Use current identity:

```text
Run:                 M1_V0_2_BASELINE_BUILD
Source release:      Module 2 / G3 v2.1.0-rc2
Model version:       PBI_R26_PARALLEL_REFINEMENT_C2_20260902
Observed-source cutoff: 2026-07-23
```

Use these two compact boundary lines:

> **Temporal boundary:** Monitoring posture reflects the governed 2026-11-22 synthetic endpoint; servicing, payment, and certification fields are deterministic synthetic lifecycle evidence.  
> **Interpretation boundary:** Deterministic synthetic evidence; intervention, setup, execution, and certification are simulated governance outcomes, not real production servicing actions.

---

# 13. Required P04 QA

Run QA before visual evidence.

## Population and key controls

Require:

```text
R1FactIntervention             130 rows / 130 unique keys
R1FactOperationalSetup         130 rows / 130 unique keys
R1FactServicingExecution       130 rows / 130 unique keys
R1FactAccountCertification     130 rows / 130 unique keys
R1FactPortfolioPerformance     130 rows / 130 unique keys
```

Require exact set equality across:

```text
R1FactFundedLifecycle
R1FactIntervention
R1FactOperationalSetup
R1FactServicingExecution
R1FactAccountCertification
R1FactPortfolioPerformance
day-120 R1FactDailyMonitoring membership
```

## Stage-distribution controls

Require the current total chain:

```text
M2.6
126 closed / 3 outreach / 1 temporary review

M2.7
126 no setup / 3 setup review / 1 setup ready

M2.8
126 no execution / 3 review hold / 1 active processing

M2.9
126 certified closed / 3 certified review hold /
1 certified reassessment after retry

M2.10
126 closed stable / 3 controlled review / 1 active reconciled
```

## Reconciliation controls

Require:

```text
State-certified rows                 130
Reconciliation variance              $0.00
Exposure variance                    $0.00
Exception incidents                      1
Resolved exceptions                      1
Unresolved exceptions                    0
```

For the active 749 path:

```text
Payment events              7
Settled events              5
Returned events             1
Retry events                1
Scheduled amount      $1,762.25
Processed amount      $1,762.25
Returned amount         $251.75
Retry amount            $251.75
Certified exposure    $2,937.12
Endpoint state        Active reconciled
Servicing burden                   2
```

The exact-zero reconciliation contract is important; the earlier one-cent defect on merchant 749 was corrected at the M2.8 generation layer rather than hidden with tolerance. [export reference: filecite | turn96file7 | L197-L259]

---

# 14. Visual regression cases

Capture or inspect these after the page is complete:

| Case | Required result |
|---|---|
| **Baseline, no account selected** | 4 attention rows; 1 active servicing; 3 review holds |
| **Recession Energy** | 27 paid-off accounts; no attention, servicing, or detail rows |
| **749 / Baseline** | Temporary-remittance setup, active processing, one return and retry, reconciled active state |
| **098 / Baseline** | Targeted outreach, governance review, execution review hold |
| **112 / Baseline** | Same governed review-hold chain, distinct exposure/pace |
| **312 / Baseline** | Targeted outreach and review hold—not temporary processing |
| **264 / Baseline** | Closed/no further action/no processing/certified closed when tested outside the attention filter |
| **082 / Baseline or 738 / Recession Energy** | Nonfunded path absent from every P04 servicing population |

---

# 15. Accessibility and evidence sequence

After semantics, visuals, interactions, and footer are complete:

1. Apply title/page alt text.
2. Add dynamic alt text for the KPI summary, both charts, the workbench, and Payment & certification detail.
3. Establish tab order:
   - title;
   - Scenario;
   - KPI summary;
   - Endpoint monitoring posture;
   - Servicing execution state;
   - Account attention workbench;
   - Payment & certification detail;
   - footer.
4. Run full refresh.
5. Save C2.
6. Close Power BI Desktop.
7. Reopen C2.
8. Revalidate Baseline and Recession Energy.
9. Capture final P04 evidence.
10. Freeze P04.

---

# Final roadmap disposition

```text
Page title                         KEEP
Subtitle                           UPDATE
Scenario slicer                    KEEP
Observation-date slicer            DO NOT ADD
KPI stack                          KEEP / REBASE / EXPAND TO 7
Monitoring chart                   KEEP / RETITLE / REBIND
Servicing chart                    KEEP / RETITLE / REBIND
Account attention workbench        KEEP / RESTRUCTURE
Payment exception history          REMOVE
Payment & certification detail     ADD BY REPURPOSING EXISTING TABLE
Existing page geometry             SUBSTANTIALLY PRESERVE
Predecessor P04 bindings            REMOVE FROM PAGE
Predecessor model objects           DO NOT DELETE
New source or relationships         NONE
New servicing methodology           NONE
```

This is the controlling P04 production design. The next implementation artifact should be a single bounded **R26 P04 presentation-layer patch plus QA query**, followed by the visual rebindings in the exact sequence above.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1cf187a8-db3e-421c-bacb-261d708f7a73"></a>
## Andrew / user · C118-M00052

C118-M00052 · 2026-09-03T17:54:38.824000-04:00 · active path

Preceding visible parent: [C118-M00051](part-04.md#m-8c7311e5-6a2a-4af2-88cd-ee7868ce2f38)

**Editorial record note:** Attachment references: Pasted text(20260903-215419).txt

<!-- BEGIN_SOURCE_MESSAGE -->
Your Recommended P03 evidence population list is not accurate. 101 is Declined Evidence Decline. Here is the Dax MSBF R26 P03 Narrative QA Queries - Correction R1 Result 3 of 3. Please re-provide recommended P03 evidence population for me to capture. Note, I already captured 738 Baseline - Approved as requested.
<!-- END_SOURCE_MESSAGE -->


<a id="m-49de8627-b2c8-453c-b33e-0b69395511d2"></a>
## Assistant · C118-M00053

C118-M00053 · 2026-09-03T18:11:40.845353-04:00 · active path

Preceding visible parent: [C118-M00052](part-04.md#m-1cf187a8-db3e-421c-bacb-261d708f7a73)

<!-- BEGIN_SOURCE_MESSAGE -->
You are correct. **000101 / Recession Energy is an evidence decline**, not a counteroffer authorization. Its governed outcome is `DECLINE_INSUFFICIENT_EVIDENCE`: 28 usable days versus 30 required, including two disconnected processor-outage days. My earlier classification was wrong. [export reference: filecite | turn113file0 | L11-L11]

The correct Recession Energy counteroffer-authorization example is **000098 / Recession Energy**. [export reference: filecite | turn108file1 | L23-L23]

I reclassified the supplied Result 3 inventory from the actual visible narrative wording. The smallest defensible **branch-complete** population contains **24 cases**:

- 2 authorization situations
- 6 counteroffer-review reason situations
- 5 manual-underwriting-review reason situations
- 3 evidence-decline situations
- 3 no-feasible-structure situations
- 5 policy-hard-stop situations

This captures all material visible narrative branches, all six observed proposed-structure adjustment patterns, both scenarios, funded and nonfunded behavior, the scenario non-improvement floor, and the important evidence-language conditions. It does not attempt to capture every merchant-specific permutation of industry, size, amount, and rate.

Because **000738 / Baseline is already complete**, the branch-complete population requires **23 additional screenshots**.

# Corrected P03 evidence population

## 1. Authorized outcomes

| Status | Merchant | Scenario | Narrative situation | Why this case |
|---|---:|---|---|---|
| **Captured** | **000738** | **Baseline** | Approve as requested | Clean requested-terms authorization, physical funding date, and downstream funded-lifecycle displays. [export reference: filecite | turn108file0 | L11-L11] |
| Capture | **000098** | **Recession Energy** | Counteroffer authorized | Correct stress-scenario authorization example. It shows an amount-only reduction from $5,200 to $2,500, negative observed liquidity, 100% negative-balance days, non-improvement-floor reselection, and actual funding. [export reference: filecite | turn108file1 | L23-L23] |

## 2. Counteroffer-review situations

These six cases exhaust the distinct business-facing reasons used in the `COUNTEROFFER_REVIEW_REQUIRED` Decision narrative.

| Merchant | Scenario | Narrative situation | Why this case |
|---:|---|---|---|
| **000002** | **Recession Energy** | Verification concern **plus capacity boundary** | Exercises the combined verification-and-capacity explanation; the proposed alternative adjusts remittance and payback. [export reference: filecite | turn108file2 | L35-L35] |
| **000149** | **Baseline** | Verification concern **only** | The only pure verification-only counteroffer-review case. It also demonstrates simultaneous amount, remittance, and payback changes. [export reference: filecite | turn108file3 | L47-L47] |
| **000082** | **Baseline** | Evidence usable, but not strong enough for straight-through authorization | Canonical Patch 3 wording case; amount and remittance are changed, and the corrected specialist-review sentence is visible. [export reference: filecite | turn108file4 | L59-L59] |
| **000741** | **Recession Energy** | Processor-continuity concern | Exercises the disrupted-processor-continuity explanation, an amount reduction, omitted sales language, and observed negative-balance days. [export reference: filecite | turn109file0 | L11-L11] |
| **000051** | **Baseline** | Capacity boundary **plus repayment guardrail** | Exercises the combined capacity/repayment-band language, remittance and payback changes, and the evidence wording for one NSF event with no negative-balance days. [export reference: filecite | turn109file1 | L23-L23] |
| **000108** | **Recession Energy** | Capacity boundary **only** | Clean capacity-only case with a remittance-only adjustment; also provides a returning merchant with strong prior performance. [export reference: filecite | turn109file2 | L35-L35] |

## 3. Manual-underwriting-review situations

These five cases exhaust the distinct visible reasons used in `MANUAL_UNDERWRITING_REVIEW_REQUIRED`.

| Merchant | Scenario | Narrative situation | Why this case |
|---:|---|---|---|
| **000116** | **Baseline** | Verification concern **plus capacity boundary** | The sole manual-underwriting case using the combined verification-and-capacity wording. [export reference: filecite | turn109file3 | L47-L47] |
| **000201** | **Recession Energy** | Verification concern **only** | Shows a requested structure that remains potentially supportable but requires specialist verification resolution. [export reference: filecite | turn109file4 | L59-L59] |
| **000298** | **Recession Energy** | Evidence usable, but not strong enough for straight-through authorization | Manual-review counterpart to the 082 counteroffer-review case; the strategy retained a potentially supportable review path. [export reference: filecite | turn110file0 | L11-L11] |
| **000335** | **Recession Energy** | Processor-continuity concern | Manual-review processor-continuity branch, with negative liquidity and negative balances on 100% of observed days. [export reference: filecite | turn110file1 | L23-L23] |
| **000749** | **Recession Energy** | Capacity/resilience review frontier | Capacity-boundary Decision wording with negative liquidity and 100% negative-balance days; no funding occurs under this scenario. [export reference: filecite | turn110file2 | L33-L33] |

## 4. Evidence-decline situations

| Merchant | Scenario | Narrative situation | Why this case |
|---:|---|---|---|
| **000001** | **Baseline** | One disconnected outage day | Exercises the singular grammar: 29 usable days versus 30 required, including **one** disconnected processor-outage day. [export reference: filecite | turn110file3 | L45-L45] |
| **000738** | **Recession Energy** | Multiple disconnected outage days | Exercises the plural grammar: 28 usable days versus 30 required, including **two** outage days. It is also the most valuable direct scenario contrast with the already-captured 738 Baseline approval. [export reference: filecite | turn110file4 | L57-L57] |
| **000042** | **Baseline** | Incomplete or contradictory operating evidence | Exercises the non-outage evidence-decline branch: required evidence is incomplete or contradictory, and structure assessment is withheld rather than converted into weak performance. [export reference: filecite | turn111file0 | L11-L11] |

**000101 / Recession Energy would duplicate the multiple-outage evidence-decline situation.** Use 738 / Recession Energy instead because it creates a much stronger Baseline-versus-Recession evidence pair.

## 5. No-feasible-structure situations

| Merchant | Scenario | Narrative situation | Why this case |
|---:|---|---|---|
| **000004** | **Baseline** | Ordinary complete search | Clean complete-search decline: 11 alternatives were evaluated and none satisfied policy, capacity, resilience, risk, and economics together. [export reference: filecite | turn111file1 | L23-L23] |
| **000022** | **Recession Energy** | Stress-route non-improvement floor without an independent complete-search claim | The independent stress path had insufficient evidence, while the governed route was held to the matched Baseline no-feasible result. It also captures returning/mixed-prior language, negative liquidity, one NSF event, and 100% negative-balance days. [export reference: filecite | turn111file2 | L35-L35] |
| **000082** | **Recession Energy** | Complete candidate search **plus** stress non-improvement floor | Direct contrast with 082 Baseline review: a candidate search occurred, but no eligible stress candidate survived the Baseline term floor, producing a governed no-feasible decline. [export reference: filecite | turn111file3 | L47-L47] |

The two stress-floor cases are genuinely different:

- **000022:** no independently supportable stress structure is presented; the Baseline **route** floor controls.
- **000082:** stress candidate evaluation occurred, but the Baseline **term** floor leaves no eligible governed candidate.

Both should be captured.

## 6. Policy-hard-stop situations

| Merchant | Scenario | Narrative situation | Why this case |
|---:|---|---|---|
| **000012** | **Recession Energy** | Elevated verification or fraud-risk condition | Exercises the fraud/verification-risk hard-stop branch and adds returning/mixed-prior and negative-liquidity evidence. [export reference: filecite | turn111file4 | L59-L59] |
| **000549** | **Baseline** | Required processor-continuity condition | Exercises the hard-stop processor-continuity branch and adds a developing-merchant evidence profile. [export reference: filecite | turn112file0 | L11-L11] |
| **000102** | **Baseline** | Evidence-confidence condition outside the permitted policy boundary | Distinct from a reviewable medium-confidence case: this condition is outside policy and therefore cannot be cured through revised terms. [export reference: filecite | turn112file1 | L23-L23] |
| **000120** | **Recession Energy** | Non-remediable verification conflict | Exercises the specific verification-conflict branch and the evidence wording that decision-critical operating evidence was available even though a hard stop controlled. [export reference: filecite | turn112file2 | L35-L35] |
| **000074** | **Baseline** | Generic policy, verification, or covenant hard stop | Exercises the governed fallback hard-stop wording and provides a returning lower-middle-market merchant with mixed prior performance. [export reference: filecite | turn112file3 | L47-L47] |

# Coverage achieved by the 24-case set

The resulting evidence package contains:

```text
Baseline screenshots          11
Recession Energy screenshots  13
Total branch-complete set     24
Already captured               1
Remaining captures            23
```

It covers every material visible decision-narrative situation and all six observed structure treatments:

```text
No proposed-term change
Amount only
Remittance only
Amount + remittance
Remittance + payback
Amount + remittance + payback
```

It also includes these evidence-language states:

```text
Clean operating evidence
Sales stated
Sales omitted
Positive liquidity
Negative liquidity
No NSF or negative-balance days
One NSF with no negative-balance days
Negative-balance days with no NSF
One NSF plus negative-balance days
One outage day
Multiple outage days
Incomplete or contradictory evidence
```

# Two recommended supplemental screenshots

These are not needed to complete the 24 narrative branches, but they materially strengthen the evidence package by showing that adverse observations are incorporated rather than mechanically forcing review or decline.

| Merchant | Scenario | Supplemental value |
|---:|---|---|
| **000589** | **Baseline** | Approve as requested despite slightly negative liquidity, one NSF event, and negative balances on 60% of observed days; the structure still clears the governed standards. [export reference: filecite | turn114file0 | L11-L11] |
| **000664** | **Baseline** | Authorized counteroffer for a returning merchant with mixed prior performance, negative liquidity, and 100% negative-balance days; amount, remittance, and payback are all revised before funding. [export reference: filecite | turn114file1 | L23-L23] |

My recommendation is therefore:

```text
Required branch-complete evidence      24 total / 23 remaining
Recommended enhanced evidence          26 total / 25 remaining
```

Use the **26-case enhanced population** for the final P03 evidence package. It is extensive enough to demonstrate the depth of the narrative engine without devolving into repetitive merchant-specific screenshots.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2b07a212-ce23-49d4-a4be-b4d38b99395d"></a>
## Andrew / user · C118-M00054

C118-M00054 · 2026-09-03T18:29:04.915000-04:00 · active path

Preceding visible parent: [C118-M00053](part-04.md#m-49de8627-b2c8-453c-b33e-0b69395511d2)

<!-- BEGIN_SOURCE_MESSAGE -->
somehow i deleted (well - changed it to a blank measure) the DimApplication P03 Channel Label we had created. What I was trying to solve was I noticed a value we had not accounted for RELATIONSHIP MANAGER or something like that. We need to account for all channel types. Please help me create a more proper channel Dax Measure.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6dd938d1-5c33-4877-a3d2-d5d841638fb3"></a>
## Assistant · C118-M00055

C118-M00055 · 2026-09-03T18:29:44.466261-04:00 · active path

Preceding visible parent: [C118-M00054](part-04.md#m-2b07a212-ce23-49d4-a4be-b4d38b99395d)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I found the exact prior calculated-column definition, and I also see why you encountered the gap.

`P03 Channel Label` is a **calculated column in `DimApplication`**, not a measure. The prior version used `DimApplication[application_channel]` and explicitly prettified only three values—`PROCESSOR_EMBEDDED`, `DIGITAL_DIRECT`, and `BROKER_REFERRAL`—then fell back to replacing underscores with spaces for anything else. [export reference: filecite | turn117file12 | L303-L316]

That fallback is why a value such as `RELATIONSHIP_MANAGER` would show up as `RELATIONSHIP MANAGER` rather than a polished display label. We should improve the column so that **all known channel codes are intentionally mapped, while retaining a safe fallback for any future code**.

Use this as the replacement calculated column:

```DAX
P03 Channel Label =
VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                'DimApplication'[application_channel],
                ""
            )
        )
    )
RETURN
    SWITCH (
        TRUE (),

        _Value = "", BLANK (),

        _Value = "PROCESSOR_EMBEDDED", "Processor embedded",
        _Value = "PROCESSOR_DIRECT", "Processor direct",

        _Value = "DIGITAL_DIRECT", "Digital direct",

        _Value = "BROKER_REFERRAL", "Broker referral",
        _Value = "BROKER_NETWORK", "Broker network",

        _Value = "BANK_RELATIONSHIP", "Bank relationship",
        _Value = "RELATIONSHIP_MANAGER", "Relationship manager",

        _Value = "STRATEGIC_PARTNER", "Strategic partner",

        -- Fail-safe for any legitimate future channel code
        VAR _Spaced =
            SUBSTITUTE ( LOWER ( _Value ), "_", " " )
        RETURN
            UPPER ( LEFT ( _Spaced, 1 ) )
                & MID ( _Spaced, 2, LEN ( _Spaced ) )
    )
```

This is materially better than the original for three reasons. First, it explicitly handles the channel concepts we know are appearing in R26—including processor, digital, broker, bank/relationship, and strategic-partner routes. Second, it normalizes case and whitespace before matching, so an otherwise valid source value cannot miss its mapping merely because of capitalization or surrounding spaces. Third, it **does not silently turn an unrecognized channel into blank**; a future value such as `AFFILIATE_PARTNER` would display as `Affiliate partner`, which is preferable on P03 to losing the channel entirely.

The underlying model definitely contains both `application_channel` and `accepted_application_channel`; the prior P03 display column was intentionally based on `application_channel`. [export reference: filecite | turn117file12 | L267-L274] The P03 Merchant Request visual also still expects `DimApplication[P03 Channel Label]` as its `Channel` field. [export reference: filecite | turn116file5 | L121-L128] So **do not recreate this as a measure**—select `DimApplication`, choose **New column**, and paste the DAX above.

One important point: the narrative QA output independently demonstrates five business-facing source descriptions—**digital-direct, bank-relationship, processor-direct, strategic partner, and broker network**—so it makes sense to cover those concepts rather than limiting ourselves to the three values in the old calculated column. For example, the supplied R26 narrative population contains bank-relationship, processor-direct, digital-direct, and strategic-partner cases in the same governed population. [export reference: filecite | turn115file0 | L5-L8]

After you add it, I would do one quick validation before continuing screenshots: temporarily put **`application_channel` + `P03 Channel Label`** into a two-column table visual. That will tell us in about 30 seconds whether R26 contains any additional raw channel code that we have not explicitly enumerated. If you paste those distinct rows back to me, I can give you the **final exact closed-set mapping** before we continue P03 evidence capture.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f5200887-3927-43c3-8b9c-27604adb706e"></a>
## Andrew / user · C118-M00056

C118-M00056 · 2026-09-03T18:38:23.814000-04:00 · active path

Preceding visible parent: [C118-M00055](part-04.md#m-6dd938d1-5c33-4877-a3d2-d5d841638fb3)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 6057b55f-fe17-4ea1-9286-30670e8f1c82.png

<!-- BEGIN_SOURCE_MESSAGE -->
Similarly, Use has a value that is not formatted: EQUIPMENT_REPAIR - P03 Use Label =  
VAR _Value = 'DimApplication'[requested_use_of_proceeds] 
RETURN 
    SWITCH ( 
        _Value, 
        "WORKING_CAPITAL", "Working capital", 
        "INVENTORY", "Inventory", 
        "SEASONAL_NEED", "Seasonal need", 
        "EXPANSION", "Expansion", 
        "EQUIPMENT", "Equipment", 
        IF ( 
            ISBLANK ( _Value ), 
            BLANK (), 
            SUBSTITUTE ( _Value, "_", " " ) 
        ) 
    )               please update for all possible values now and in the future.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ebf361f0-0a14-448e-b05e-435e7833711b"></a>
## Assistant · C118-M00057

C118-M00057 · 2026-09-03T18:38:31.023382-04:00 · active path

Preceding visible parent: [C118-M00056](part-04.md#m-f5200887-3927-43c3-8b9c-27604adb706e)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. We should make `P03 Use Label` resilient in the same way: explicit mappings for known values, normalization up front, and a future-safe fallback that converts any new underscore-delimited code into clean sentence case.

Use this replacement calculated column:

```DAX
P03 Use Label =
VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                'DimApplication'[requested_use_of_proceeds],
                ""
            )
        )
    )

VAR _Fallback =
    VAR _Spaced =
        SUBSTITUTE (
            LOWER ( _Value ),
            "_",
            " "
        )
    RETURN
        IF (
            _Spaced = "",
            BLANK (),
            UPPER ( LEFT ( _Spaced, 1 ) )
                & MID (
                    _Spaced,
                    2,
                    LEN ( _Spaced )
                )
        )

RETURN
    SWITCH (
        TRUE (),

        _Value = "", BLANK (),

        _Value = "WORKING_CAPITAL", "Working capital",
        _Value = "INVENTORY", "Inventory",
        _Value = "SEASONAL_NEED", "Seasonal need",
        _Value = "EXPANSION", "Expansion",
        _Value = "EQUIPMENT", "Equipment",
        _Value = "EQUIPMENT_REPAIR", "Equipment repair",

        _Value = "EQUIPMENT_PURCHASE", "Equipment purchase",
        _Value = "EQUIPMENT_UPGRADE", "Equipment upgrade",

        _Value = "RENOVATION", "Renovation",
        _Value = "REMODELING", "Remodeling",
        _Value = "REPAIR", "Repair",
        _Value = "MAINTENANCE", "Maintenance",

        _Value = "MARKETING", "Marketing",
        _Value = "ADVERTISING", "Advertising",

        _Value = "PAYROLL", "Payroll",
        _Value = "HIRING", "Hiring",

        _Value = "DEBT_REFINANCE", "Debt refinance",
        _Value = "DEBT_CONSOLIDATION", "Debt consolidation",

        _Value = "PURCHASE_ORDER", "Purchase order",
        _Value = "SUPPLIES", "Supplies",

        _Value = "BUSINESS_ACQUISITION", "Business acquisition",
        _Value = "LOCATION_EXPANSION", "Location expansion",
        _Value = "NEW_LOCATION", "New location",

        _Value = "EMERGENCY_EXPENSE", "Emergency expense",
        _Value = "TAX_PAYMENT", "Tax payment",

        _Value = "OTHER", "Other",

        _Fallback
    )
```

The important improvement is the `_Fallback`. Even if a value appears later that we never anticipated—say:

```text
VEHICLE_REPAIR
TECHNOLOGY_UPGRADE
LEASEHOLD_IMPROVEMENT
BRIDGE_FINANCING
```

it will display automatically as:

```text
Vehicle repair
Technology upgrade
Leasehold improvement
Bridge financing
```

instead of the raw all-caps source code.

I would actually treat the explicit mappings above as **semantic documentation rather than a requirement for formatting**. The fallback is what makes this future-proof. So `EQUIPMENT_REPAIR` is now explicitly controlled, while any legitimately new use-of-proceeds code will still render correctly without another DAX defect.

Also keep this as a **calculated column on `DimApplication`**, just like the existing `P03 Use Label`; the P03 Merchant Request visual is using it as a row-level display field, not as an aggregation.

One small refinement I recommend after this: we should use the same normalization pattern for both **Channel** and **Use** so these two P03 display columns follow one consistent controlled-display convention. That will eliminate this class of issue rather than fixing values one at a time.
<!-- END_SOURCE_MESSAGE -->


<a id="m-287520df-a07b-4ea0-9077-ffdac2a4ba83"></a>
## Andrew / user · C118-M00058

C118-M00058 · 2026-09-03T18:45:55.384000-04:00 · active path

Preceding visible parent: [C118-M00057](part-04.md#m-ebf361f0-0a14-448e-b05e-435e7833711b)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: b7e1bdc1-63f9-4f7d-83ca-952f85a6d362.png; 7739dea8-a18e-4674-88e5-61f4891f30e3.png

<!-- BEGIN_SOURCE_MESSAGE -->
P03 Relationship Stage =  
VAR _Value = 
    SELECTEDVALUE ( 'DimMerchant'[relationship_stage] ) 
RETURN 
    IF ( 
        ISBLANK ( _Value ), 
        "NOT AVAILABLE", 
        SWITCH ( 
            _Value, 
            "NEW", "New", 
            "EXISTING", "Existing", 
            "RETURNING", "Returning", 
            SUBSTITUTE ( _Value, "_", " " ) 
        ) 
    )                           This needs updated to account for all possible values now and in the future.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cf863505-3d08-4a6d-a640-dfe2ecb1ffba"></a>
## Assistant · C118-M00059

C118-M00059 · 2026-09-03T18:46:31.699742-04:00 · active path

Preceding visible parent: [C118-M00058](part-04.md#m-287520df-a07b-4ea0-9077-ffdac2a4ba83)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The current value you are seeing, `RETURNING_GOOD`, is one of four defined relationship-stage values in the governing parameter set:

- `NEW`
- `RETURNING_GOOD`
- `RETURNING_MIXED`
- `LOW_AND_GROW` [export reference: filecite | turn118file3 | L216-L226]

The old `P03 Relationship Stage` measure only explicitly handled `NEW`, `EXISTING`, and `RETURNING`, so it was obsolete for the actual synthetic population. [export reference: filecite | turn118file2 | L137-L151]

Replace it with this future-safe measure:

```DAX
P03 Relationship Stage =
VAR _RawValue =
    SELECTEDVALUE ( 'DimMerchant'[relationship_stage] )

VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                _RawValue,
                ""
            )
        )
    )

VAR _Fallback =
    VAR _Spaced =
        SUBSTITUTE (
            LOWER ( _Value ),
            "_",
            " "
        )
    RETURN
        IF (
            _Spaced = "",
            "NOT AVAILABLE",
            UPPER ( LEFT ( _Spaced, 1 ) )
                & MID (
                    _Spaced,
                    2,
                    LEN ( _Spaced )
                )
        )

RETURN
    SWITCH (
        TRUE (),

        _Value = "", "NOT AVAILABLE",

        _Value = "NEW", "New",

        _Value = "RETURNING_GOOD", "Returning — good",
        _Value = "RETURNING_MIXED", "Returning — mixed",

        _Value = "LOW_AND_GROW", "Low and grow",

        -- Legacy / compatibility values if they ever appear
        _Value = "EXISTING", "Existing",
        _Value = "RETURNING", "Returning",

        -- Future-safe rendering of any new governed code
        _Fallback
    )
```

I prefer **“Returning — good”** and **“Returning — mixed”** over simply `Returning good` / `Returning mixed`. These are relationship-stage classifications, so the dash makes the hierarchy more natural and executive-readable.

The fallback also makes the measure future-safe. For example:

```text
ESTABLISHED_GROWTH → Established growth
RETURNING_STRONG   → Returning strong
EARLY_TENURE       → Early tenure
```

without another broken all-caps display.

One distinction from the `Use` and `Channel` fixes: **keep this as a measure**, because the current P03 left-side profile is already consuming `ModelParameters[P03 Relationship Stage]` in selected-merchant context. The old implementation was also a measure over `DimMerchant[relationship_stage]`, so there is no reason to change that architecture. [export reference: filecite | turn118file8 | L531-L545]

This now correctly covers the full defined relationship-stage population and remains readable if new codes are introduced later.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d230b47d-119e-40e6-87e0-fd6314770ce3"></a>
## Andrew / user · C118-M00060

C118-M00060 · 2026-09-03T19:03:25.346000-04:00 · active path

Preceding visible parent: [C118-M00059](part-04.md#m-cf863505-3d08-4a6d-a640-dfe2ecb1ffba)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: cdfb711b-64cb-4374-9e29-4003207be9b1.png; 3f2dc4a1-025e-4d48-ad33-b0862d858448.png; f145102f-84d1-484e-8422-b69fea4f7db4.png

<!-- BEGIN_SOURCE_MESSAGE -->
these two we should change to use proper case:           P03 Merchant Size Tier =  
VAR _Value = 
    SELECTEDVALUE ( 'DimMerchant'[merchant_size_tier] ) 
RETURN 
    SWITCH ( 
        _Value, 
        "LOWER_MIDDLE", "Lower middle", 
        "UPPER_MIDDLE", "Upper middle", 
        "SMALL", "Small", 
        "LARGE", "Large", 
        IF ( 
            ISBLANK ( _Value ), 
            "NOT AVAILABLE", 
            SUBSTITUTE ( _Value, "_", " " ) 
        ) 
    )                                                P03 Annual Sales Band =  
VAR _Value = 
    SELECTEDVALUE ( 'DimMerchant'[annual_sales_band] ) 
RETURN 
    SWITCH ( 
        _Value, 
        "UNDER_1M", "< $1M", 
        "1M_TO_5M", "$1M–$5M", 
        "5M_TO_10M", "$5M–$10M", 
        "10M_TO_25M", "$10M–$25M", 
        "25M_PLUS", "$25M+", 
        IF ( 
            ISBLANK ( _Value ), 
            "NOT AVAILABLE", 
            SUBSTITUTE ( _Value, "_", " " ) 
        ) 
    )                        account for values now and in the future.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1b293532-4b2c-4ef3-bfa2-75e3113e3172"></a>
## Assistant · C118-M00061

C118-M00061 · 2026-09-03T19:03:55.285278-04:00 · active path

Preceding visible parent: [C118-M00060](part-04.md#m-d230b47d-119e-40e6-87e0-fd6314770ce3)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Both current measures need the same cleanup pattern we just applied elsewhere: explicit mappings for the governed values that exist now, plus a future-safe fallback that converts any new underscore-delimited code to readable sentence case instead of exposing raw source codes.

For **Merchant Size Tier**, the current governed population uses exactly `MICRO`, `SMALL`, `LOWER_MIDDLE`, and `MIDDLE`. [export reference: filecite | turn119file1 | L95-L119] Use:

```DAX
P03 Merchant Size Tier =
VAR _RawValue =
    SELECTEDVALUE ( 'DimMerchant'[merchant_size_tier] )

VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                _RawValue,
                ""
            )
        )
    )

VAR _Fallback =
    VAR _Spaced =
        SUBSTITUTE (
            LOWER ( _Value ),
            "_",
            " "
        )
    RETURN
        IF (
            _Spaced = "",
            "NOT AVAILABLE",
            UPPER ( LEFT ( _Spaced, 1 ) )
                & MID (
                    _Spaced,
                    2,
                    LEN ( _Spaced )
                )
        )

RETURN
    SWITCH (
        TRUE (),

        _Value = "", "NOT AVAILABLE",

        _Value = "MICRO", "Micro",
        _Value = "SMALL", "Small",
        _Value = "LOWER_MIDDLE", "Lower middle",
        _Value = "MIDDLE", "Middle",

        -- Compatibility / future controlled values
        _Value = "UPPER_MIDDLE", "Upper middle",
        _Value = "LARGE", "Large",

        _Fallback
    )
```

That fixes the current `MICRO` display immediately and still renders future values like `MID_MARKET` as `Mid market` rather than `MID MARKET`.

For **Annual Sales Band**, the current deterministic merchant population actually uses these four bands:

```text
UNDER_250K
250K_TO_1M
1M_TO_5M
5M_TO_20M
```

They are generated directly from the current merchant-size architecture. [export reference: filecite | turn119file3 | L232-L236] Your old measure was therefore especially stale because it expected `UNDER_1M`, `5M_TO_10M`, `10M_TO_25M`, etc.

Use this:

```DAX
P03 Annual Sales Band =
VAR _RawValue =
    SELECTEDVALUE ( 'DimMerchant'[annual_sales_band] )

VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                _RawValue,
                ""
            )
        )
    )

VAR _Fallback =
    VAR _Spaced =
        SUBSTITUTE (
            LOWER ( _Value ),
            "_",
            " "
        )
    RETURN
        IF (
            _Spaced = "",
            "NOT AVAILABLE",
            UPPER ( LEFT ( _Spaced, 1 ) )
                & MID (
                    _Spaced,
                    2,
                    LEN ( _Spaced )
                )
        )

RETURN
    SWITCH (
        TRUE (),

        _Value = "", "NOT AVAILABLE",

        -- Current governed bands
        _Value = "UNDER_250K", "< $250K",
        _Value = "250K_TO_1M", "$250K–$1M",
        _Value = "1M_TO_5M", "$1M–$5M",
        _Value = "5M_TO_20M", "$5M–$20M",

        -- Legacy / compatibility values
        _Value = "UNDER_1M", "< $1M",
        _Value = "5M_TO_10M", "$5M–$10M",
        _Value = "10M_TO_25M", "$10M–$25M",
        _Value = "25M_PLUS", "$25M+",

        -- Future-safe display
        _Fallback
    )
```

So your screenshot would change from:

```text
Size tier
MICRO

Annual sales
UNDER 250K
```

to:

```text
Size tier
Micro

Annual sales
< $250K
```

which is much more appropriate for the executive-facing P03 page.

One nuance: the generic fallback is excellent for future **categorical names**, but dollar-band codes are special because something like `20M_TO_50M` would fall back to `20m to 50m`, not a professionally formatted `$20M–$50M`. So this measure is future-safe in the sense that a new code will remain readable and never show raw underscores, but **new monetary bands should still be explicitly mapped when introduced** if we want the polished currency-range convention. That is preferable to trying to write brittle DAX that parses every imaginable monetary code automatically.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7a171dfe-05d4-4f88-b16a-399af9de671e"></a>
## Andrew / user · C118-M00062

C118-M00062 · 2026-09-03T19:32:11.895000-04:00 · active path

Preceding visible parent: [C118-M00061](part-04.md#m-1b293532-4b2c-4ef3-bfa2-75e3113e3172)

**Editorial record note:** Attachment references: P03_Captures.zip

<!-- BEGIN_SOURCE_MESSAGE -->
Perform final review of P03.  All evidence is attached.  One thing I do wonder about is if Intervention and Action columns are too similar. Whether there is something else that would be valuable there.
<!-- END_SOURCE_MESSAGE -->


<a id="m-732d5c15-993a-479b-b3fa-2ba0486fb048"></a>
## Assistant · C118-M00063

C118-M00063 · 2026-09-03T19:37:02.000095-04:00 · active path

Preceding visible parent: [C118-M00062](part-04.md#m-7a171dfe-05d4-4f88-b16a-399af9de671e)

<!-- BEGIN_SOURCE_MESSAGE -->
I reviewed all **31 artifacts** in `P03_Captures.zip`: the 25 scenario/narrative captures, three narrative-QA result sets, alt-text evidence, tab-order evidence, and tooltip evidence.

## Final disposition

**P03 is substantively very strong and very close to freeze, but I would not freeze it yet.**

My disposition is:

```text
P03 semantic architecture                    PASS
Narrative architecture                       PASS
Narrative branch coverage                    PASS — extensive
Narrative QA                                 PASS — 2 / 0 / 1,500
Scenario isolation                           PASS
Funded-lifecycle gating                      PASS
Account-performance implementation           PASS
Monitoring-journey implementation            PASS
Servicing/intervention semantics             PASS
Accessibility architecture                   PASS with evidence note
Page presentation                            PASS with minor refinement
Footer/current project identity               FAIL — localized correction
Technical-rationale tooltip evidence         NOT PRESENT IN PACKAGE
Operational P03 QA evidence                  NOT PRESENT IN PACKAGE
P03 freeze                                   HOLD — localized closeout only
```

This is no longer a page-remediation exercise. It is a very bounded closeout.

## What looks particularly good

The overall page now tells a coherent application-to-account story. The subtitle is right, **Proposed structure** is the appropriate business-facing term, the profile data is cleanly presented, the revised relationship-stage/size/sales formatting reads professionally, the three narrative sections work well as a proof sequence, and nonfunded paths correctly stop before downstream lifecycle evidence.

The 25 captured cases are also excellent coverage. You captured the complete branch-oriented set we identified, plus an additional funded approval example. The evidence demonstrates approval, authorized counteroffer, all material review-reason families, evidence declines, ordinary and stress-floor no-feasible outcomes, and the material hard-stop families across both Baseline and Recession Energy.

Your narrative QA is clean as well: Result 1 shows the two 738 paths, Result 2 is empty, and Result 3 contains 1,500 rows with only `PASS` in the QA-status filter. That is exactly the semantic control we wanted.

The right-side lifecycle behavior also looks right. Funded examples populate Account performance and Monitoring journey; nonfunded examples remain blank. The new expected-to-date tooltip is behaving coherently—for example, the captured 749 tooltip reconciles expected-to-date, actual remitted-to-date, and cumulative shortfall rather than reaching back into the old `FactAccountDaily` population.

## One definite defect: the footer still says C1

Every P03 page capture I inspected has this footer value:

```text
Model version: PBI_R26_PARALLEL_REFINEMENT_C1_20260902
```

while the Power BI window itself correctly shows:

```text
MSBF_PBI_R26_PARALLEL_REFINEMENT_C2_20260902
```

That must be corrected to:

```text
Model version: PBI_R26_PARALLEL_REFINEMENT_C2_20260902
```

This is more than cosmetic in a controlled evidence package: right now the screenshot contains **two contradictory physical-project identities**.

Everything else in the footer looks good, including the `Module 2 / G3 v2.1.0-rc2` source identity, observed-source cutoff, and the shortened temporal/interpretation boundaries.

## Intervention versus Action: yes, I would change this

Your instinct is right.

On the physical current M2.6 architecture, **Intervention and Action are functionally one-to-one for the current governed outcomes**:

| Intervention | Action |
|---|---|
| No further action | No action — closed |
| Continue monitoring | Continue standard monitoring |
| Targeted outreach review | Outreach review |
| Temporary remittance review | Temporary remittance review |

That isn't merely coincidental wording. M2.6 explicitly generates `strategy_outcome_code` and `servicing_action_code` from the same governed monitoring state, and the current mapping pairs them deterministically. [export reference: filecite | turn122file2 | L106-L112] The R26 presentation measures then translate those two source fields almost exactly as your visual shows. [export reference: filecite | turn122file5 | L200-L250]

So **Action adds very little incremental information to P03**.

I also would **not replace Action with Priority**. `servicing_priority_rank` is generated from the same state as Intervention—0/1/2/3 for closed/monitoring/outreach/temporary review—so that would largely substitute one redundant field for another. The action/review flags are similarly governed from the same state. [export reference: filecite | turn122file4 | L160-L168]

### Recommended final table

I would change the visible table to:

| Recommended intervention | Queue | Exposure | Reason |
|---|---|---:|---|
| Targeted outreach review | Servicing review | $1,720.89 | Severe shortfall |
| Temporary remittance review | Servicing review | $4,699.37 | Severe shortfall |
| No further action | Closed | $0.00 | Paid off |

I slightly prefer **`Recommended intervention`** over just `Intervention`. It reinforces the critical M2.6 boundary: this is a governed servicing recommendation, **not evidence that an action was executed**. M2.6 itself expressly keeps execution flags false; actual setup/execution belongs to M2.7/M2.8 and therefore to the P04 story. [export reference: filecite | turn122file6 | L263-L279]

That four-column design is more marketable:

```text
What should happen?
→ Where does it route?
→ How much exposure is involved?
→ Why?
```

And it gives each remaining column a genuinely distinct analytical purpose.

### Update the servicing alt text accordingly

If you make that change, update `R26 P03 Servicing Alt Text` to:

```DAX
R26 P03 Servicing Alt Text =
IF (
    [R26 P03 Funded Lifecycle Available] <> 1,
    "No funded-account servicing or intervention evidence is available for this application-scenario path.",
    "Servicing and intervention. Recommended intervention: "
        & COALESCE (
            [R26 P03 Intervention Display],
            "not available"
        )
        & ". Queue: "
        & COALESCE (
            [R26 P03 Servicing Queue Display],
            "not available"
        )
        & ". Exposure: "
        & FORMAT (
            COALESCE (
                [R26 P03 Intervention Exposure],
                0
            ),
            "$#,0.00"
        )
        & ". Reason: "
        & COALESCE (
            [R26 P03 Intervention Reason Display],
            "not available"
        )
        & "."
)
```

Leave `R26 P03 Servicing Action Display` in the model. We are not deleting the semantic object; we simply don't need to expose it on P03.

## Two evidence gaps I found

The first is the **Technical rationale tooltip**.

Your file named `P03_Tooltip_Evidence.png` is good evidence of the **Account performance tooltip**—and that tooltip looks excellent—but it is not the Technical rationale report-page tooltip that was part of the P03 narrative architecture.

The controlled design calls for a tooltip page containing:

```text
R26 P03 Technical Evidence Rationale
R26 P03 Technical Structure Rationale
R26 P03 Technical Decision Rationale
ApplicationScenarioKey
governed final outcome
binding reason codes
human-review reason codes
```

The purpose is to preserve exact source-level traceability underneath the polished executive narratives. [export reference: filecite | turn123file0 | L84-L114] I see no screenshot of that tooltip in the attached package. If you've already built it, we only need to capture it. If it has not been built, that is the one substantive P03 feature still missing.

The second gap is the **post-remediation performance/monitoring QA**. The package contains all three narrative-QA result sets, but I do not see captures from `MSBF_R26_P03_PERFORMANCE_MONITORING_QA_R1_20260903.dax`. The controlled P03 production sequence requires:

```text
Result 1    15,600 / 130 / 120 / 120
Result 2    0 rows
Result 3    738 Baseline = 120 + lifecycle; Recession Energy = 0
Result 4    126 closed / 3 outreach / 1 temporary remittance
```

[export reference: filecite | turn120file11 | L731-L748]

I would capture those before freeze.

## Two smaller observations

The Account performance visual is strong, including the dual-axis scaling and tooltip. In the screenshots I can clearly see the **Remittance pace** secondary-axis title, but I do not see the primary-axis title **Remaining receivable**. The legend identifies that series, so this is not a correctness defect, but since we explicitly chose both axis titles, I would turn the primary title on if it is currently off.

Your tab order is logically sound through the substantive page: title → selectors → profile/request/decision/structure → narratives → performance → monitoring → servicing. The remaining footer/text/shape objects follow later. I would not spend more time reorganizing it unless a decorative shape is actually keyboard-focusable in the live report.

The alt-text screenshot proves the dynamic `R26 P03 Servicing Alt Text` binding. It does not independently prove every static alt-text assignment we made, but I would not create ten additional screenshots solely for that—the final physical PBIX can provide exhaustive accessibility evidence during integration audit.

## Exact closeout sequence

1. Change the footer from `...C1_20260902` to **`PBI_R26_PARALLEL_REFINEMENT_C2_20260902`**.
2. I recommend changing Servicing & intervention to **Recommended intervention | Queue | Exposure | Reason**, removing visible Action and updating the servicing alt-text measure above.
3. Turn on **Remaining receivable** as the primary Account-performance Y-axis title if it is currently off.
4. Verify/capture the **Technical rationale** report-page tooltip.
5. Capture one **Monitoring journey tooltip** as well; your current evidence only demonstrates the Account-performance hover.
6. Run and capture the four-result **P03 performance/monitoring QA**.
7. Save C2, close Power BI Desktop completely, reopen C2, and spot-check 738 Baseline/RE plus one funded intervention case.
8. Then freeze P03 and move on to P04.

You **do not need to redo the narrative work or another narrative review cycle**. The narratives are done.

For the screenshots already captured, the C1 footer makes them imperfect as *final freeze* evidence. For the cleanest audit package I would recapture the page examples after the footer correction. If you want to minimize effort, however, the existing 25 screenshots can legitimately be retained as **branch-review evidence**, because the footer correction is non-semantic; then capture a smaller post-fix freeze set plus the corrected footer/technical-tooltip/operational-QA evidence. The final physical PBIX and post-fix QA will establish the controlling state.

Once those localized items are complete, I would record **P03 = PASS / FROZEN** and shift fully to P04.
<!-- END_SOURCE_MESSAGE -->


<a id="m-20eb815c-107a-453f-acd3-2b5c8d3f0de4"></a>
## Andrew / user · C118-M00064

C118-M00064 · 2026-09-03T19:45:03.937000-04:00 · active path

Preceding visible parent: [C118-M00063](part-04.md#m-732d5c15-993a-479b-b3fa-2ba0486fb048)

<!-- BEGIN_SOURCE_MESSAGE -->
I updated the model version, but I wonder if we shouldn't start targeting a more refined name in line with what we'll actually publish this as. We're not going to upload our first Power BI build to GitHub titled, MSBF_PBI_R26_PARALLEL.... Let's think of a publishable name and stick with that. It should be short and aligned to where we are in the build. This is through Module 2 architecture. It should also be a marketable name. Something we can share and it conveys professionalism and would be in line with something you'd present to a client.
<!-- END_SOURCE_MESSAGE -->
