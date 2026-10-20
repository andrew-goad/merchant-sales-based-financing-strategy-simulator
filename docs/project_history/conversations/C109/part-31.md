# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 31 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-30.md)
[Next part](part-32.md)

<a id="m-2a5d7831-148c-44f1-af3b-90972457aee6"></a>
## Assistant · C109-M00661

C109-M00661 · 2026-09-02T11:50:50.852664-04:00 · active path

Preceding visible parent: [C109-M00660](part-30.md#m-2981f8b0-028f-4353-be7f-262e2040ae2d)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **this is the version I would keep.** The smaller alert tile solved the remaining balance issue.

Compared with the prior version, three things now work particularly well:

- **Active alerts is clearly separate from Endpoint status.** It no longer reads like a seventh endpoint metric.
- The amber treatment is noticeable without competing with the decision/funding story.
- The two-line heading makes the temporal distinction understandable: **Endpoint status** versus **Active alerts / as of observation date**.

I would stop adjusting its size and placement. More cosmetic work risks making it worse rather than better.

One small detail: the amber tile is now appropriately compact, but the `4` could perhaps move up by a few pixels if Power BI gives you an easy vertical-alignment control. I would **not** spend time fighting the visual if it doesn't.

### Final interaction contract I recommend

For **Active alerts**:
- Scenario → **On**
- Industry → **On**
- Acquisition source → **On**
- Observation date → **On**

For **Endpoint status**:
- Scenario → **On**
- Industry → **On**
- Acquisition source → **On**
- Observation date → **Off**

That distinction is important. Endpoint status should still respond to the business population being analyzed; it just shouldn't pretend that an intermediate Observation date changes the governed endpoint.

### One thing to update: accessibility

Because the number-only card no longer has a category label, its alt text matters more. Use the dynamic/appropriate alt text we discussed, or at minimum:

> Active alerts: distinct active, non-paid-off account paths with one or more operational alert families at the selected observation date.

The separate text box visually supplies the title; the alt text supplies the semantic identity for assistive technology.

For **Endpoint status**, I would update its alt text to reflect the new six-metric composition:

> Endpoint status summarizes reconciled paths, ending exposure, reconciliation variance, unresolved exceptions, open servicing paths, and review holds at the governed lifecycle endpoint.

### Now do the interaction test

Before freezing P01, test three states:

1. **Baseline / All / All / 8/8/2026**  
   Active alerts should become **12**. Endpoint status should remain fixed at the Baseline endpoint.

2. **Baseline / filtered Industry or Acquisition source / 8/8/2026**  
   Both blocks should respond to the population filter, while only Active alerts responds temporally.

3. **Recession Energy / All / All / 8/8/2026**  
   Active alerts should become **2**. Endpoint status should switch to the Recession Energy endpoint population.

If those behave correctly, **freeze P01**. Visually, I think you've landed it.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8019f042-0855-4c89-ab70-244ff57faf2c"></a>
## Andrew / user · C109-M00662

C109-M00662 · 2026-09-02T12:00:02.086000-04:00 · active path

Preceding visible parent: [C109-M00661](part-31.md#m-2a5d7831-148c-44f1-af3b-90972457aee6)

<!-- BEGIN_SOURCE_MESSAGE -->
what about P02 title alt text since we changed the monitoring breadth and severity chart. current alt text: Merchant Financing Cohort Lifecycle. Tracks the selected synthetic funded cohort from activation through receivable runoff, remittance performance, operational attention, and payoff timing.
<!-- END_SOURCE_MESSAGE -->


<a id="m-554605e3-08ba-4649-b3b5-e6b5df2c5bde"></a>
## Assistant · C109-M00663

C109-M00663 · 2026-09-02T12:00:06.101933-04:00 · active path

Preceding visible parent: [C109-M00662](part-31.md#m-8019f042-0855-4c89-ab70-244ff57faf2c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Since the P02 story has materially changed, the **page/title alt text should change too**. I would not leave “operational attention” in it; that now understates the deliberate distinction between alert breadth and adverse monitoring status.

Use this:

> **Merchant Financing Cohort Lifecycle. Tracks the selected synthetic funded cohort from activation through receivable runoff, remittance performance, monitoring breadth and adverse status, and payoff timing.**

That mirrors the visible subtitle and accurately describes the four analytical areas without becoming overly technical.

For accessibility, I prefer **“monitoring breadth and adverse status”** here rather than **“monitoring breadth and severity.”** The chart title can remain *Monitoring breadth and severity*, but the page alt text should describe what is actually measured: operationally alerted accounts versus accounts in adverse monitoring states.

So I would lock:

**Visible subtitle**
> Track the selected synthetic funded cohort from activation through receivable runoff, remittance performance, monitoring breadth and adverse status, and payoff timing.

**Page/title alt text**
> Merchant Financing Cohort Lifecycle. Tracks the selected synthetic funded cohort from activation through receivable runoff, remittance performance, monitoring breadth and adverse status, and payoff timing.

And separately keep the **Monitoring breadth and severity chart** on its dynamic `R26 P02 Monitoring Breadth Severity Alt Text` measure. That gives the page-level description the simple business story and the visual-level alt text the detailed R26 semantics.
<!-- END_SOURCE_MESSAGE -->


<a id="m-97954695-e051-4a21-941d-259a995dda05"></a>
## Andrew / user · C109-M00664

C109-M00664 · 2026-09-02T12:02:56.173000-04:00 · active path

Preceding visible parent: [C109-M00663](part-31.md#m-554605e3-08ba-4649-b3b5-e6b5df2c5bde)

**Editorial record note:** 18 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P01_Tooltip_Evidence(3).png; P02_Acquisition_Source_Slicer_Interaction(3).png; P02_Alt_Text(3).png; P02_Baseline_Full_Page(3).png; P02_Edit_Interactions_Observation_Period_Slicer(2).png; P02_Edit_Interactions_Scenario_Slicer(2).png; P02_Industry_Slicer_Interaction(3).png; P02_Observation_Period_Test(2).png; P02_Recession_Energy_Full_Page(3).png; P02_Tab_Order(3).png; P02_Tooltip_Evidence(4).png; P01_Observation_Period_Test(1).png; P01_Acquisition_Source_Slicer_Interaction(3).png; P01_Alt_Text(4).png; P01_Baseline_Full_Page(3).png; P01_Industry_Slicer_Interaction(3).png; P01_Recession_Energy_Full_Page(3).png; P01_Tab_Order(4).png

<!-- BEGIN_SOURCE_MESSAGE -->
Thanks. P01 is substantially better with the active alerts card and the redesign of the endpoint status. P02 values are more realistic after the remediation/correction. P01 and P02 are now frozen and ready for review. All evidence is attached and saved at: C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\owner_evidence\captures
<!-- END_SOURCE_MESSAGE -->


<a id="m-075c41ce-c8e8-4a5f-adf9-55be74e1d9bb"></a>
## Assistant · C109-M00665

C109-M00665 · 2026-09-02T12:03:00.283891-04:00 · active path

Preceding visible parent: [C109-M00664](part-31.md#m-97954695-e051-4a21-941d-259a995dda05)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. I’m recording **P01 and P02 as frozen for this refinement candidate and ready for review**.

The evidence set is strong enough to support that freeze: P01 now has the cleaner six-cell **Endpoint status** block plus a temporally distinct **Active alerts — as of observation date** indicator; P02 has the R26-corrected **Monitoring breadth and severity** semantics, revised subtitle/alt text, tooltip detail, and demonstrated scenario, industry, acquisition-source, and observation-period behavior.

The key checkpoint is also visibly reconciled in the evidence: at **Baseline, 8/8/2026**, P01 reports **12 Active alerts**, while P02 shows the corresponding R26 monitoring state of **12 accounts with operational alerts and 11 accounts in adverse monitoring status**. That is exactly the distinction we wanted after the remediation.

I would preserve the diagnostic page for now as **non-final diagnostic evidence**, rather than delete it before review. It documents why the prior attention semantics were replaced and gives us useful lineage if Audit asks how the redesign was validated.

### Frozen state

**P01 — Cohort Command Center**
- Executive decision taxonomy retained.
- Funding, economics, supportable-path and lifecycle KPIs retained.
- Endpoint status redesigned to the six business-relevant endpoint measures.
- Observation-date interaction intentionally disabled for Endpoint status.
- Active alerts separated as an observation-date-sensitive indicator.
- Accessibility, tooltips, slicer interactions and tab order evidenced.

**P02 — Cohort Lifecycle**
- Receivable runoff retained.
- Remittance fulfillment retained.
- Prior attention-signals construct replaced by **Monitoring breadth and severity**.
- Main series now distinguish **Accounts with operational alerts** from **Accounts in adverse monitoring status**.
- Detailed R26 raw-condition/family information remains available through tooltip rather than cluttering the executive chart.
- Observation-period semantics, scenario behavior, filtering, accessibility and tab order evidenced.
- Revised title/subtitle semantics are consistent with the page.

**Candidate identity shown in the evidence:** `PBI_R26_PARALLEL_REFINEMENT_C1_20260902`.

**Evidence location recorded:**  
`C:\MSBF\PowerBI\R26_Parallel\MSBF_PBI_R26_PARALLEL_REFINEMENT_C1_20260902_DELIVERY\owner_evidence\captures`

I would make **no further P01/P02 design changes unless review identifies a concrete defect**. From here, we should return to implementation and move to **P03 — Application Journey**, carrying the same R26 source discipline and preserving P01/P02 as the frozen nonregression baseline.
<!-- END_SOURCE_MESSAGE -->


<a id="m-43bfaf63-3bb9-4d15-a80b-ad975fe7fc04"></a>
## Andrew / user · C109-M00666

C109-M00666 · 2026-09-02T12:11:10.924000-04:00 · active path

Preceding visible parent: [C109-M00665](part-31.md#m-075c41ce-c8e8-4a5f-adf9-55be74e1d9bb)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 4c940fd7-5643-4849-b171-dd9788e03c7f.png; 8417dced-5c39-4e1a-af58-5d1f1001a692.png

<!-- BEGIN_SOURCE_MESSAGE -->
one thing we didn't discuss was tooltips adjustments. these two may need slight adjustments. I see the >100 active alerts being flagged there. please advise.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0d1e3e8f-f0df-45d2-bf2e-c5f49aff3dac"></a>
## Assistant · C109-M00667

C109-M00667 · 2026-09-02T12:11:14.856084-04:00 · active path

Preceding visible parent: [C109-M00666](part-31.md#m-43bfaf63-3bb9-4d15-a80b-ad975fe7fc04)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **Both P02 tooltips need a small R26 cleanup before I would call P02 fully frozen.** The charts themselves are right; the residual problem is that the tooltips still carry some of the pre-R26 monitoring semantics.

The `102` you are seeing is **Raw alert conditions**, not 102 active/alerted accounts. At 8/8 the governed distinction is:

- Accounts with operational alerts = **12**
- Accounts in adverse monitoring status = **11**
- Raw alert conditions = **102**
- Operational alert families = **23**
- Active / non-paid-off accounts = **100**

So `102` is valid, but putting it into multiple general-purpose tooltips without enough semantic framing makes it very easy for a user to misread.

### 1. Monitoring breadth and severity tooltip

Your current tooltip is actually quite good. I would **keep all of its monitoring diagnostics** because this is exactly where the distinction belongs.

Keep, in this order:

```text
Accounts with operational alerts
Accounts in adverse monitoring status
Raw alert conditions
Operational alert families
Raw conditions per alerted account
Operational families per alerted account
Active / non-paid-off accounts
Remaining receivable
Remittance fulfillment
Average payoff variance
```

The 8/8 example then reads coherently: 12 alerted accounts generated 102 raw conditions, which were consolidated into 23 operational alert families.

I would **not remove `Raw alert conditions = 102` from this tooltip**. This tooltip is precisely where the user should be able to investigate breadth versus underlying signal volume.

### 2. Remittance fulfillment tooltip

This is where I would make the bigger change.

Right now you have:

```text
Remittance fulfillment
Remitted to date
Expected to date
Remaining receivable
Accounts with operational alerts
Accounts in adverse monitoring status
Raw alert conditions
Operational alert families
```

The last two don't belong here. They turn a remittance-performance tooltip into a quasi-monitoring diagnostic and recreate the ambiguity we just corrected.

Change it to:

```text
Remittance fulfillment
Remitted to date
Expected to date
Remaining receivable
Accounts with operational alerts
Accounts in adverse monitoring status
```

So **remove** from the Remittance fulfillment visual's Tooltips field well:

```text
Raw alert conditions
Operational alert families
```

I would retain the two account measures because they provide useful business context: an executive hovering over an unusual remittance point can immediately see whether the cohort was also experiencing monitoring deterioration.

### 3. Check Receivable runoff

We should apply the same principle there.

Its primary tooltip should be lifecycle/exposure-oriented. I would target:

```text
Remaining receivable
Funded accounts
Active / non-paid-off accounts
Paid-off accounts
Remittance fulfillment
Accounts with operational alerts
Accounts in adverse monitoring status
```

Do **not** put raw conditions or operational-family counts there.

### 4. Check Payoff timing vs plan

Likewise, keep this outcome-oriented:

```text
Average payoff variance
Active / non-paid-off accounts
Paid-off accounts
Remaining receivable
Remittance fulfillment
Accounts with operational alerts
Accounts in adverse monitoring status
```

Again, no raw-condition or family counts.

### The semantic rule for P02

This gives us a very clean hierarchy:

**Main charts:** business concepts.

**General chart tooltips:** relevant account-level monitoring context.

**Monitoring breadth and severity tooltip:** full R26 diagnostic decomposition.

That means `102` appears where it is meaningful and properly contextualized rather than appearing throughout the page.

I would make those changes before freezing P02. **No DAX changes are required for this cleanup**—this is just field-well configuration using the R26 measures we've already validated.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1eea8099-0d10-4537-8d65-901aa25dd170"></a>
## Andrew / user · C109-M00668

C109-M00668 · 2026-09-02T12:14:42.395000-04:00 · active path

Preceding visible parent: [C109-M00667](part-31.md#m-0d1e3e8f-f0df-45d2-bf2e-c5f49aff3dac)

<!-- BEGIN_SOURCE_MESSAGE -->
how should average payoff variance be formatted?
<!-- END_SOURCE_MESSAGE -->


<a id="m-93e1133c-bbb0-4d9b-8c95-621c3070382c"></a>
## Assistant · C109-M00669

C109-M00669 · 2026-09-02T12:14:45.844989-04:00 · active path

Preceding visible parent: [C109-M00668](part-31.md#m-1eea8099-0d10-4537-8d65-901aa25dd170)

<!-- BEGIN_SOURCE_MESSAGE -->
For **Average payoff variance**, I would format it as a **signed number of days with one decimal place**.

So your 8/8 value should display as:

**−1.2 days**

rather than `-1.22`.

The interpretation should be:

- **Negative** = paying off **earlier than plan**
- **0.0 days** = on plan
- **Positive** = paying off **later than plan**

For P02 tooltips, I recommend the format:

`0.0 "days";-0.0 "days";0.0 "days"`

So examples become **−17.6 days**, **−1.2 days**, **0.0 days**, or **+?** Note that this format will not explicitly show a `+` for positive values. I actually prefer that: **7.0 days** naturally communicates seven days late, while `−7.0 days` communicates seven days early.

For the **Payoff timing vs plan chart axis**, however, I would leave it as a plain numeric day scale—`-20`, `-10`, `0`, etc.—rather than appending “days” to every tick. The chart title already establishes the unit/context.

So: **tooltip = one decimal + “days”; axis = whole-number days.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-c4283dc5-58e0-44a6-9e5d-8c6fe8f60b1c"></a>
## Andrew / user · C109-M00670

C109-M00670 · 2026-09-02T12:28:55.165000-04:00 · active path

Preceding visible parent: [C109-M00669](part-31.md#m-93e1133c-bbb0-4d9b-8c95-621c3070382c)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P02_Tooltip_Evidence(5).png; P02_DIAG_Attention_States.png

<!-- BEGIN_SOURCE_MESSAGE -->
Tooltips were updated and the P02-DIAG was updated. Those captures are now in the owner_evidence/captures folder I shared. P01 and P02 are done.
<!-- END_SOURCE_MESSAGE -->


<a id="m-59c9fa21-04b4-48dd-9ac6-77ec8a6f24bb"></a>
## Assistant · C109-M00671

C109-M00671 · 2026-09-02T12:29:02.654026-04:00 · active path

Preceding visible parent: [C109-M00670](part-31.md#m-c4283dc5-58e0-44a6-9e5d-8c6fe8f60b1c)

<!-- BEGIN_SOURCE_MESSAGE -->
Recorded. **P01 and P02 are complete and frozen for review.**

The final P02 cleanup closes the remaining semantic loose end: the general lifecycle tooltips no longer overexpose raw monitoring-condition counts, while **Monitoring breadth and severity** retains the full R26 diagnostic decomposition where it belongs. The updated P02-DIAG page also preserves the calibration evidence and makes the distinction between operational alerts, adverse monitoring status, and the older diagnostic states auditable.

I would preserve the current P02-DIAG page in the candidate as **diagnostic/review evidence, not an executive-facing final page**. It is useful support for why the monitoring presentation changed and should remain available until review is complete.

So the working status is now:

```text
P01 — Cohort Command Center
FROZEN / READY FOR REVIEW

P02 — Cohort Lifecycle
FROZEN / READY FOR REVIEW

P02-DIAG — Attention States
RETAIN AS DIAGNOSTIC EVIDENCE
NOT PART OF FINAL EXECUTIVE PAGE SET
```

The next implementation target should be **P03 — Application Journey**. We should treat the now-frozen P01/P02 behavior as a nonregression boundary and make no further changes to them unless review identifies a specific defect.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f839b06a-f07d-42ef-990d-ff4d93f3b24b"></a>
## Andrew / user · C109-M00672

C109-M00672 · 2026-09-02T12:32:32.955000-04:00 · active path

Preceding visible parent: [C109-M00671](part-31.md#m-59c9fa21-04b4-48dd-9ac6-77ec8a6f24bb)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 1ead43d4-8576-4857-9c03-cdf813497b31.png; c8bf8c2c-e857-4015-974d-82f317459056.png; e10ad71b-0caa-4ad7-986a-29eddbd5846c.png

<!-- BEGIN_SOURCE_MESSAGE -->
Prepare step by step to bring P03 up to the level we need it (if it's not already there). Obviously the footnote needs updated. Let me know everything else, in detailed step by step.
<!-- END_SOURCE_MESSAGE -->


<a id="m-479298e7-6fb8-4d04-b5dc-f290786327e3"></a>
## Assistant · C109-M00673

C109-M00673 · 2026-09-02T12:44:10.169473-04:00 · active path

Preceding visible parent: [C109-M00672](part-31.md#m-f839b06a-f07d-42ef-990d-ff4d93f3b24b)

<!-- BEGIN_SOURCE_MESSAGE -->
P03 is **visually much closer to finished than P01/P02 were when we started**, so I would **not redesign the page**. The current three-column journey structure is good.

What it still needs is a controlled **semantic successor/R26 rebase**. The biggest defect is that the page still treats “selected structure,” “authorized offer,” and “funded account” too much like the same event. The successor model now gives us enough source-owned evidence to distinguish them cleanly. `R1FactFinalDecision` is explicitly one row per application/scenario and preserves the source-owned final outcome, authority-first selection, selected structure and exact decision lineage. [export reference: filecite | turn122file9 | L182-L195] The governed selected-structure fields are also physically present rather than something we need to infer in DAX. [export reference: filecite | turn122file14 | L316-L329]

I would make the following changes in this order.

## 1. Keep the page architecture, change the subtitle

Keep:

**Merchant Application & Account Journey**

Replace the subtitle with:

> **Follow one synthetic merchant application from request through evidence, governed decision and selected structure; funded paths continue through account performance, monitoring and servicing.**

This immediately fixes the false implication that every reviewed/declined application gets an account.

Use this as the title/text-box alt text:

> **Merchant Application & Account Journey. Follows the selected synthetic application from request through source-owned evidence, governed decision and selected structure. Funded paths continue through deterministic synthetic account performance, monitoring and servicing.**

That funded/non-funded distinction is source-grounded: the activation source requires account/funding/date fields for activated rows and requires those fields to remain null for nonactivated rows. [export reference: filecite | turn125file0 | L11-L36]

---

## 2. Add the P03 successor measures first

Go to **DAX Query View** → New query.

Paste this **entire block**. Do not create fragments individually.

```DAX
DEFINE

    MEASURE 'R1Measures'[R26 P03 Decision Class] =
        VAR _Outcome =
            COALESCE (
                SELECTEDVALUE (
                    'R1FactFinalDecision'[governed_final_outcome_code]
                ),
                SELECTEDVALUE (
                    'R1DimApplicationScenario'[governed_final_outcome_code]
                )
            )
        RETURN
            SWITCH (
                TRUE (),
                _Outcome
                    IN {
                        "APPROVE_AS_REQUESTED_AUTHORIZED",
                        "COUNTEROFFER_AUTHORIZED"
                    }, "AUTHORIZED",
                _Outcome
                    IN {
                        "COUNTEROFFER_REVIEW_REQUIRED",
                        "MANUAL_UNDERWRITING_REVIEW_REQUIRED"
                    }, "REVIEW",
                _Outcome
                    IN {
                        "DECLINE_INSUFFICIENT_EVIDENCE",
                        "DECLINE_NO_FEASIBLE_STRUCTURE",
                        "DECLINE_POLICY_HARD_STOP"
                    }, "DECLINED",
                BLANK ()
            )


    MEASURE 'R1Measures'[R26 P03 Decision Label] =
        VAR _Outcome =
            COALESCE (
                SELECTEDVALUE (
                    'R1FactFinalDecision'[governed_final_outcome_code]
                ),
                SELECTEDVALUE (
                    'R1DimApplicationScenario'[governed_final_outcome_code]
                )
            )
        RETURN
            SWITCH (
                _Outcome,
                "APPROVE_AS_REQUESTED_AUTHORIZED", "Approved as requested",
                "COUNTEROFFER_AUTHORIZED", "Counteroffer authorized",
                "COUNTEROFFER_REVIEW_REQUIRED", "Counteroffer review",
                "MANUAL_UNDERWRITING_REVIEW_REQUIRED", "Underwriting review",
                "DECLINE_INSUFFICIENT_EVIDENCE", "Evidence decline",
                "DECLINE_NO_FEASIBLE_STRUCTURE", "No feasible structure",
                "DECLINE_POLICY_HARD_STOP", "Policy hard stop",
                BLANK ()
            )


    MEASURE 'R1Measures'[R26 P03 Decision Tile Background] =
        SWITCH (
            [R26 P03 Decision Class],
            "AUTHORIZED", "#2E7D32",
            "REVIEW",     "#C58A00",
            "DECLINED",   "#C62828",
            "#667085"
        )


    MEASURE 'R1Measures'[R26 P03 Evidence Narrative] =
        COALESCE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[evidence_why_text]
            ),
            SELECTEDVALUE (
                'R1DimApplicationScenario'[evidence_why_text]
            )
        )


    MEASURE 'R1Measures'[R26 P03 Underwriting Narrative] =
        COALESCE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[underwriting_why_text]
            ),
            SELECTEDVALUE (
                'R1DimApplicationScenario'[underwriting_why_text]
            )
        )


    MEASURE 'R1Measures'[R26 P03 Decision Narrative] =
        COALESCE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[decision_why_text]
            ),
            SELECTEDVALUE (
                'R1DimApplicationScenario'[decision_why_text]
            )
        )


    MEASURE 'R1Measures'[R26 P03 Selected Structure Amount] =
        SELECTEDVALUE (
            'R1FactFinalDecision'[governed_selected_funding_amount]
        )


    MEASURE 'R1Measures'[R26 P03 Selected Remittance Rate] =
        SELECTEDVALUE (
            'R1FactFinalDecision'[governed_selected_remittance_rate]
        )


    MEASURE 'R1Measures'[R26 P03 Selected Payback Multiple] =
        SELECTEDVALUE (
            'R1FactFinalDecision'[governed_selected_payback_multiple]
        )


    MEASURE 'R1Measures'[R26 P03 Selected Horizon Days] =
        SELECTEDVALUE (
            'R1FactFinalDecision'[governed_selected_horizon_days]
        )


    MEASURE 'R1Measures'[R26 P03 Selected Total Repayment] =
        SELECTEDVALUE (
            'R1FactFinalDecision'[governed_selected_total_repayment_amount]
        )


    MEASURE 'R1Measures'[R26 P03 Selection Frontier] =
        VAR _Frontier =
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_selection_frontier]
            )
        RETURN
            SWITCH (
                _Frontier,
                "STRICT_AUTOMATIC_FRONT", "Automatic frontier",
                "REVIEW_ELIGIBLE_FRONT",  "Review frontier",
                "BASELINE_ROUTE_FLOOR",    "Baseline route floor",
                "NO_STRUCTURE",            "No structure",
                _Frontier
            )


    MEASURE 'R1Measures'[R26 P03 Candidates Evaluated] =
        SELECTEDVALUE (
            'R1DimApplicationScenario'[evaluated_candidate_count]
        )


    MEASURE 'R1Measures'[R26 P03 Candidate Search Summary] =
        VAR _Required =
            SELECTEDVALUE (
                'R1DimApplicationScenario'[search_required_flag]
            )
        VAR _Attempted =
            SELECTEDVALUE (
                'R1DimApplicationScenario'[search_attempted_flag]
            )
        VAR _Complete =
            SELECTEDVALUE (
                'R1DimApplicationScenario'[search_complete_flag]
            )
        VAR _Count =
            [R26 P03 Candidates Evaluated]
        VAR _Frontier =
            [R26 P03 Selection Frontier]
        RETURN
            SWITCH (
                TRUE (),
                ISBLANK ( _Required ), BLANK (),
                _Required = FALSE (), "Search: not required",
                _Attempted = FALSE (), "Search: required • not attempted",
                _Complete = FALSE (),
                    "Search: "
                        & FORMAT ( COALESCE ( _Count, 0 ), "0" )
                        & " evaluated • incomplete",
                "Search: "
                    & FORMAT ( COALESCE ( _Count, 0 ), "0" )
                    & " evaluated"
                    & IF (
                        NOT ISBLANK ( _Frontier ),
                        " • " & _Frontier,
                        ""
                    )
            )


    MEASURE 'R1Measures'[R26 P03 Funded Lifecycle Available] =
        VAR _ApplicationScenarioKey =
            SELECTEDVALUE (
                'R1DimApplicationScenario'[ApplicationScenarioKey]
            )
        VAR _MonitoringRows =
            IF (
                NOT ISBLANK ( _ApplicationScenarioKey ),
                CALCULATE (
                    COUNTROWS ( 'R1FactDailyMonitoring' ),
                    REMOVEFILTERS (
                        'R1FactDailyMonitoring'[monitoring_date]
                    ),
                    TREATAS (
                        { _ApplicationScenarioKey },
                        'R1FactDailyMonitoring'[ApplicationScenarioKey]
                    )
                )
            )
        RETURN
            IF (
                ISBLANK ( _ApplicationScenarioKey ),
                BLANK (),
                IF ( COALESCE ( _MonitoringRows, 0 ) > 0, 1, 0 )
            )


    MEASURE 'R1Measures'[R26 P03 Account Performance Subtitle] =
        IF (
            [R26 P03 Funded Lifecycle Available] = 1,
            "Funded synthetic account • deterministic synthetic-forward",
            "No funded-account lifecycle for this application-scenario"
        )


    MEASURE 'R1Measures'[R26 P03 Monitoring Journey Subtitle] =
        IF (
            [R26 P03 Funded Lifecycle Available] = 1,
            "Governed monitoring status across the funded-account lifecycle",
            "No funded-account monitoring path for this application-scenario"
        )


    MEASURE 'R1Measures'[R26 P03 Remaining Receivable] =
        MAX (
            'R1FactDailyMonitoring'[receivable_balance_after]
        )


    MEASURE 'R1Measures'[R26 P03 Remittance Pace] =
        MAX (
            'R1FactDailyMonitoring'[cumulative_pace_ratio]
        )


    MEASURE 'R1Measures'[R26 P03 Remitted To Date] =
        MAX (
            'R1FactDailyMonitoring'[cumulative_remittance_amount]
        )


    MEASURE 'R1Measures'[R26 P03 Cumulative Shortfall] =
        MAX (
            'R1FactDailyMonitoring'[cumulative_shortfall_amount]
        )


    MEASURE 'R1Measures'[R26 P03 Operational Alert Families] =
        MAX (
            'R1FactDailyMonitoring'[operational_alert_family_count]
        )


    MEASURE 'R1Measures'[R26 P03 Raw Alert Conditions] =
        MAX (
            'R1FactDailyMonitoring'[raw_alert_condition_count]
        )


    MEASURE 'R1Measures'[R26 P03 Monitoring Status Rank] =
        VAR _Status =
            SELECTEDVALUE (
                'R1FactDailyMonitoring'[monitoring_status_code]
            )
        RETURN
            SWITCH (
                _Status,
                "PAID_OFF",              0,
                "CURRENT",               1,
                "WATCH",                 2,
                "UNDERPERFORMING",       3,
                "SEVERE_SHORTFALL",      4,
                "DORMANT_NO_REMITTANCE", 5,
                BLANK ()
            )


    MEASURE 'R1Measures'[R26 P03 Monitoring Status Display] =
        VAR _Status =
            SELECTEDVALUE (
                'R1FactDailyMonitoring'[monitoring_status_code]
            )
        RETURN
            SWITCH (
                _Status,
                "PAID_OFF",              "Paid off",
                "CURRENT",               "Current",
                "WATCH",                 "Watch",
                "UNDERPERFORMING",       "Underperforming",
                "SEVERE_SHORTFALL",      "Severe shortfall",
                "DORMANT_NO_REMITTANCE", "Dormant / no remittance",
                BLANK ()
            )


    MEASURE 'R1Measures'[R26 P03 Intervention Display] =
        VAR _Code =
            SELECTEDVALUE (
                'R1FactIntervention'[strategy_outcome_code]
            )
        RETURN
            SWITCH (
                _Code,
                "CLOSED_NO_FURTHER_ACTION", "No further action",
                "CONTINUE_STANDARD_MONITORING", "Continue monitoring",
                "TARGETED_MERCHANT_OUTREACH_REVIEW", "Targeted outreach review",
                "TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW", "Temporary remittance review",
                _Code
            )


    MEASURE 'R1Measures'[R26 P03 Servicing Action Display] =
        VAR _Code =
            SELECTEDVALUE (
                'R1FactIntervention'[servicing_action_code]
            )
        RETURN
            SWITCH (
                _Code,
                "NO_ACTION_CLOSED", "No action — closed",
                "CONTINUE_STANDARD_MONITORING", "Continue standard monitoring",
                "OUTREACH_REVIEW_QUEUE", "Outreach review",
                "TEMPORARY_REMITTANCE_REVIEW", "Temporary remittance review",
                _Code
            )


    MEASURE 'R1Measures'[R26 P03 Servicing Queue Display] =
        VAR _Code =
            SELECTEDVALUE (
                'R1FactIntervention'[servicing_queue_code]
            )
        RETURN
            SWITCH (
                _Code,
                "CLOSED",              "Closed",
                "STANDARD_MONITORING", "Standard monitoring",
                "SERVICING_REVIEW",    "Servicing review",
                _Code
            )


    MEASURE 'R1Measures'[R26 P03 Intervention Exposure] =
        SELECTEDVALUE (
            'R1FactIntervention'[recommended_action_exposure_amount]
        )


    MEASURE 'R1Measures'[R26 P03 Intervention Reason Display] =
        VAR _Code =
            SELECTEDVALUE (
                'R1FactIntervention'[primary_intervention_reason_code]
            )
        RETURN
            SWITCH (
                _Code,
                "M2_6_REASON_PAID_OFF_CLOSED", "Paid off",
                "M2_6_REASON_SEVERE_SHORTFALL_TEMPORARY_REMITTANCE_REVIEW", "Severe shortfall",
                "M2_6_REASON_SEVERE_SHORTFALL_OUTREACH_REVIEW", "Severe shortfall",
                "M2_6_REASON_UNDERPERFORMING_OUTREACH_REVIEW", "Underperforming",
                "M2_6_REASON_WATCH_OUTREACH_REVIEW", "Watch",
                "M2_6_REASON_CURRENT_MONITORING_CONTINUES", "Current monitoring",
                _Code
            )


    MEASURE 'R1Measures'[R26 P03 Decision Tile Alt Text] =
        VAR _Class =
            [R26 P03 Decision Class]
        VAR _Label =
            [R26 P03 Decision Label]
        VAR _Search =
            [R26 P03 Candidate Search Summary]
        RETURN
            IF (
                ISBLANK ( _Label ),
                "No single governed application decision is selected.",
                "Governed decision: "
                    & _Class
                    & " — "
                    & _Label
                    & "."
                    & IF (
                        NOT ISBLANK ( _Search ),
                        " " & _Search & ".",
                        ""
                    )
            )


    MEASURE 'R1Measures'[R26 P03 Selected Structure Alt Text] =
        VAR _Amount =
            [R26 P03 Selected Structure Amount]
        RETURN
            IF (
                ISBLANK ( _Amount ),
                "No governed selected structure is present for the selected application and scenario.",
                "Governed selected structure. Selected amount "
                    & FORMAT ( _Amount, "$#,0.00" )
                    & ", remittance rate "
                    & FORMAT (
                        [R26 P03 Selected Remittance Rate],
                        "0.00%"
                    )
                    & ", payback multiple "
                    & FORMAT (
                        [R26 P03 Selected Payback Multiple],
                        "0.00"
                    )
                    & ", horizon "
                    & FORMAT (
                        [R26 P03 Selected Horizon Days],
                        "0"
                    )
                    & " days, total repayment "
                    & FORMAT (
                        [R26 P03 Selected Total Repayment],
                        "$#,0.00"
                    )
                    & "."
            )


    MEASURE 'R1Measures'[R26 P03 Servicing Alt Text] =
        IF (
            [R26 P03 Funded Lifecycle Available] <> 1,
            "No funded-account servicing or intervention evidence is available for this application-scenario path.",
            "Servicing and intervention. Intervention: "
                & COALESCE (
                    [R26 P03 Intervention Display],
                    "not available"
                )
                & ". Action: "
                & COALESCE (
                    [R26 P03 Servicing Action Display],
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

EVALUATE
ROW (
    "P03 successor measures staged", 1
)
```

Click **Update model with changes**.

The intervention table above is using actual M2.6 source fields—the source physically carries strategy outcome, servicing action, queue, exposure and intervention reason at one row per funded application/scenario. [export reference: filecite | turn130file0 | L10-L14]

---

## 3. Format and organize those measures

In Model view, select the new measures and set:

```text
Display folder:
P03 | Application Journey
```

Set these formats:

| Measure | Format |
|---|---|
| Selected Structure Amount | `$#,0.00;($#,0.00);$0.00` |
| Selected Remittance Rate | `0.00%` |
| Selected Payback Multiple | `0.00` |
| Selected Horizon Days | `0` |
| Selected Total Repayment | `$#,0.00;($#,0.00);$0.00` |
| Candidates Evaluated | `0` |
| Remaining Receivable | `$#,0.00;($#,0.00);$0.00` |
| Remittance Pace | `0.00%` |
| Remitted To Date | `$#,0.00;($#,0.00);$0.00` |
| Cumulative Shortfall | `$#,0.00;($#,0.00);$0.00` |
| Operational Alert Families | `0` |
| Raw Alert Conditions | `0` |
| Monitoring Status Rank | `0` |
| Intervention Exposure | `$#,0.00;($#,0.00);$0.00` |

---

## 4. Leave Merchant, Scenario, merchant profile and Merchant request alone

I see no reason to rebuild the left profile or request row.

Keep:

- Merchant
- Industry
- Size tier
- Annual sales
- Relationship stage
- Relationship quality
- Prior advances
- Prior funded

Keep the existing **Merchant request** fields as well.

Those components are visually clean and already explain what the merchant asked for. The successor work belongs **after the request**, where the decision and structure logic changed.

---

## 5. Rebind the decision tile

This is important.

The current generic:

```text
APPROVED
Final offer
```

is no longer precise enough. In the successor taxonomy, **approved as requested** and **counteroffer authorized** are separate outcomes. The accepted P01 display taxonomy already distinguishes all seven governed outcomes. [export reference: filecite | turn124file0 | L19-L42]

Use the existing tile—do not redesign it.

Replace its high-level value with:

```text
R26 P03 Decision Class
```

Replace its secondary value with:

```text
R26 P03 Decision Label
```

So possible displays are:

```text
AUTHORIZED
Approved as requested
```

or

```text
AUTHORIZED
Counteroffer authorized
```

or

```text
REVIEW
Counteroffer review
```

or

```text
DECLINED
Policy hard stop
```

I strongly prefer **AUTHORIZED** instead of **APPROVED** for the high-level green state. It avoids collapsing “counteroffer authorized” into “approved as requested.”

For the background:

**Format visual → General → Effects → Background → fx → Field value → `R26 P03 Decision Tile Background`.**

Keep white text.

For Alt text:

**General → Alt text → fx → Field value → `R26 P03 Decision Tile Alt Text`.**

---

## 6. Change “Funded terms” to “Selected structure”

This is the most important visible semantic correction.

Rename:

```text
Funded terms
```

to:

```text
Selected structure
```

The successor model explicitly distinguishes candidate search/selected structure from later funding. The candidate source carries terms and feasibility at candidate grain, while the final-decision source carries the governed selection. [export reference: filecite | turn124file8 | L650-L665]

Replace the visible term fields with this order:

| Position | Field | Rename for this visual |
|---:|---|---|
| 1 | `[R26 P03 Selected Structure Amount]` | `Selected amount` |
| 2 | `[R26 P03 Selected Remittance Rate]` | `Remittance` |
| 3 | `[R26 P03 Selected Payback Multiple]` | `Payback multiple` |
| 4 | `[R26 P03 Selected Horizon Days]` | `Horizon days` |
| 5 | `[R26 P03 Selected Total Repayment]` | `Repayment` |
| 6 | **keep the existing actual funding-date field** | `Funding date` |

That last field is deliberately different: it is the **physical synthetic funding date**, not another selected-structure attribute.

The behavior we want is:

**Authorized/funded path:** selected terms + funding date.

**Review path with a governed candidate:** selected terms may appear, but funding date remains blank.

**Decline/no-structure path:** selected terms remain blank when the source has no selected candidate.

That distinction is much stronger than the current “Funded terms” block.

Set the visual's alt text to:

```text
R26 P03 Selected Structure Alt Text
```

---

## 7. Surface candidate-search sophistication without adding clutter

We do need this on P03. The successor source physically records evaluated-candidate count and selection frontier, and the no-feasible proof object even retains strict/review candidate counts, closest candidate and failure evidence. [export reference: filecite | turn126file1 | L18-L20]

But I would **not add another table**.

Insert a small **Card** next to the `Selected structure` heading.

Field:

```text
R26 P03 Candidate Search Summary
```

Turn Category label off.

Formatting:

```text
Font:        8–9 pt
Color:       muted gray
Background:  Off
Border:      Off
Word wrap:   On
```

It should read something like:

```text
Search: 6 evaluated • Automatic frontier
```

or:

```text
Search: 8 evaluated • Review frontier
```

or:

```text
Search: not required
```

or for an actual no-feasible case:

```text
Search: 6 evaluated • No structure
```

This gives P03 much more analytical credibility without overwhelming the page.

---

## 8. Rebind the three narrative sections to source-owned successor text

Do **not** regenerate these narratives in DAX.

The final-decision source is designed to preserve source-owned decision explanation rather than require Power BI to reconstruct policy logic. [export reference: filecite | turn122file9 | L182-L195]

Keep the first heading:

```text
Merchant operating evidence
```

Replace its text with:

```text
R26 P03 Evidence Narrative
```

Rename:

```text
Structure assessment narrative
```

to:

```text
Underwriting & structure assessment
```

Bind it to:

```text
R26 P03 Underwriting Narrative
```

Rename:

```text
P03 Decision Readout
```

to:

```text
Governed decision
```

Bind it to:

```text
R26 P03 Decision Narrative
```

This is one place where I would **not edit wording for polish**. Preserve the physical R1/R26 explanation text. We can format it, but not rewrite its substantive conclusion.

---

## 9. Rebase Account performance to R1/R26

The right-side chart should now be driven by the successor account path.

Select **Account performance**.

Set:

```text
X-axis
R1FactDailyMonitoring[monitoring_date]

Y-axis
R26 P03 Remaining Receivable

Secondary Y-axis
R26 P03 Remittance Pace
```

The R1 monitoring carrier physically provides the daily monitoring date, cumulative remittance, remaining receivable, cumulative shortfall, pace and monitoring status at application-scenario × day grain. [export reference: filecite | turn128file1 | L20-L21]

Rename for this visual:

```text
R26 P03 Remaining Receivable → Remaining receivable
R26 P03 Remittance Pace      → Remittance pace
```

Tooltips, in this order:

```text
R26 P03 Monitoring Status Display   → Monitoring status
R26 P03 Remitted To Date            → Remitted to date
R26 P03 Cumulative Shortfall        → Cumulative shortfall
R26 P03 Operational Alert Families  → Operational alert families
R26 P03 Raw Alert Conditions        → Raw alert conditions
```

Unlike P02, I am comfortable including raw alert conditions here because this is **one account on one day**, so the grain is much less ambiguous.

Keep the chart title:

```text
Account performance
```

Add a dynamic subtitle if your Power BI version exposes **Subtitle → fx**:

```text
R26 P03 Account Performance Subtitle
```

That gives funded paths:

> Funded synthetic account • deterministic synthetic-forward

and review/decline paths:

> No funded-account lifecycle for this application-scenario

If your build does not allow dynamic subtitle formatting, use a tiny borderless card immediately below the title with that measure.

---

## 10. Correct Monitoring journey for the full governed M2.5 status scale

Your current chart is missing **Dormant / no remittance**.

The governed status ranks are physically defined as:

```text
0  Paid off
1  Current
2  Watch
3  Underperforming
4  Severe shortfall
5  Dormant / no remittance
```

That rank order is source-defined. [export reference: filecite | turn123file1 | L43-L84]

Select **Monitoring journey**.

Use:

```text
X-axis
R1FactDailyMonitoring[monitoring_date]

Y-axis
R26 P03 Monitoring Status Rank
```

In **Format visual → Y-axis → Range**:

```text
Minimum = 0
Maximum = 5
```

Keep whole-number status levels.

Your current right-side semantic labels/constant lines should become:

```text
5   Dormant / no remittance
4   Severe shortfall
3   Underperforming
2   Watch
1   Current
0   Paid off
```

If those are Analytics-pane constant lines, add the sixth at `5`. If they are text boxes aligned to grid lines, add the sixth and reposition the others against the 0–5 axis.

Tooltips:

```text
R26 P03 Monitoring Status Display   → Monitoring status
R26 P03 Remaining Receivable        → Remaining receivable
R26 P03 Remittance Pace             → Remittance pace
R26 P03 Operational Alert Families  → Operational alert families
R26 P03 Raw Alert Conditions        → Raw alert conditions
```

Do **not** put P02's portfolio-level alert-account measures on this chart. P03 is a single-account status journey.

If available, use:

```text
R26 P03 Monitoring Journey Subtitle
```

as its dynamic subtitle.

---

## 11. Rebind Servicing & intervention

Keep the title:

```text
Servicing & intervention
```

The current five-column design is good.

Replace its fields with:

| Column | Measure | Visible label |
|---|---|---|
| 1 | `[R26 P03 Intervention Display]` | Intervention |
| 2 | `[R26 P03 Servicing Action Display]` | Action |
| 3 | `[R26 P03 Servicing Queue Display]` | Queue |
| 4 | `[R26 P03 Intervention Exposure]` | Exposure |
| 5 | `[R26 P03 Intervention Reason Display]` | Reason |

This keeps the row internally coherent at **M2.6 intervention grain** instead of mixing later servicing/certification states into the main row.

The later source chain remains available elsewhere: R1 servicing execution physically carries execution action/queue/final lifecycle state and ending exposure, while account certification separately carries certified state, reconciliation variance and certified exposure. [export reference: filecite | turn127file1 | L35-L35] [export reference: filecite | turn127file4 | L190-L190] P04 remains the more appropriate place to expose that deeper operational detail.

Set the table's Alt text to:

```text
R26 P03 Servicing Alt Text
```

Most importantly, **do not fabricate servicing rows for review/decline paths**. A blank table there is correct.

---

## 12. Replace the stale footer completely

The current footer still says:

```text
MSBF_PBI_SOURCE_SELECTION_R3_20260816
PBI_A1A_MODEL_R1_20260818
```

Those must go.

The easiest method is to copy the **identity row** from frozen P02 and paste it into P03, because P02 already has the correct R26 identity.

P03 should show:

```text
Run:                    M1_V0_2_BASELINE_BUILD
Source release:         Module 2 / G3 v2.1.0-rc2
Model version:          PBI_R26_PARALLEL_REFINEMENT_C1_20260902
Observed-source cutoff: 2026-07-23
```

Then replace the two boundary lines with:

> **Temporal boundary:** Decision and selected-structure evidence is fixed at the 2026-07-23 source snapshot. Funded-account lifecycle evidence is deterministic synthetic-forward through 2026-11-22.

> **Interpretation boundary:** Synthetic decision and lifecycle evidence; review or decline paths do not imply funding or account creation.

That last sentence is especially important on P03.

---

## 13. Interaction contract

Go to **Format → Edit interactions**.

For the **Merchant** slicer:

```text
FILTER
merchant profile
merchant request
decision tile
selected structure
candidate search
all three narratives
account performance
monitoring journey
servicing & intervention
```

For the **Scenario** slicer: same.

For **Account performance**, **Monitoring journey**, and **Servicing & intervention**, turn interaction with the other report visuals to **None**. Selecting a point in the lifecycle should not rewrite the decision evidence.

The page contract should be:

```text
Merchant + Scenario define the application-scenario path.
Everything else describes that path.
No analytical visual redefines another analytical visual.
```

---

## 14. Tab order

After the visuals are stable:

**View → Selection → Tab order.**

I recommend this order:

```text
1   Page title / subtitle
2   Merchant slicer
3   Scenario slicer
4   Merchant profile
5   Merchant request
6   Governed decision tile
7   Selected structure
8   Candidate search
9   Merchant operating evidence
10  Underwriting & structure assessment
11  Governed decision narrative
12  Account performance
13  Monitoring journey
14  Servicing & intervention
15  Footer / boundary
```

Decorative lines/shapes should not interrupt the tab sequence.

---

## 15. P03 acceptance testing

Use at least these three paths you already know.

**Merchant 000749 / Baseline**

This is your funded lifecycle case. It should show:

- source-owned governed decision;
- source-owned selected structure;
- actual funding date;
- populated Account performance;
- populated Monitoring journey;
- populated Servicing & intervention.

One important check: its current page says `APPROVED / Final offer`, but requested amount is $17.7K and the synthetic funded amount is $11.7K. I therefore expect the successor source may identify it as **`AUTHORIZED / Counteroffer authorized`** rather than generic approval. Do **not** force that result—let `[R26 P03 Decision Label]` tell us what the physical governed source says.

**Merchant 000749 / Recession Energy**

This is the critical review test:

- decision = REVIEW;
- exact review outcome below it;
- selected structure **may populate** if the governed source selected a review candidate;
- funding date must remain blank if not funded;
- account performance blank;
- monitoring journey blank;
- servicing/intervention blank.

That is the distinction we specifically want P03 to communicate.

**Merchant 000003 / Recession Energy**

This should show:

- source-owned decline outcome;
- evidence/underwriting/decision narrative;
- no fabricated funding;
- no fabricated lifecycle.

We should also capture one actual `DECLINE_NO_FEASIBLE_STRUCTURE` case after the page is working, because that lets us demonstrate the candidate-search/no-feasible-proof story.

---

### Where I expect P03 to land

The page should tell this sequence very cleanly:

**Merchant & request → evidence → candidate search → governed decision → selected structure → actual funding boundary → funded-account performance → monitoring → servicing/intervention.**

That is materially stronger than the current page while preserving almost all of its visual architecture. It also follows the governing successor chain rather than asking Power BI to reconstruct upstream logic. The Power BI handoff explicitly requires that source-owned chain to remain merchant evidence → gates → candidate search → selected structure → final decision → funding → monitoring/intervention → servicing/certification. [export reference: filecite | turn125file2 | L221-L241]

I would implement **Steps 1–7 first**—through the selected structure, candidate-search line and source-owned narratives. Once those physically render for 000749 Baseline/Recession and 000003 Recession, we can inspect that center column before touching the three right-side lifecycle visuals.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f1b95dac-6c3d-4232-ac68-e8b139cc7fdc"></a>
## Andrew / user · C109-M00674

C109-M00674 · 2026-09-02T13:07:58.341000-04:00 · active path

Preceding visible parent: [C109-M00673](part-31.md#m-479298e7-6fb8-4d04-b5dc-f290786327e3)

<!-- BEGIN_SOURCE_MESSAGE -->
what about: Follow synthetic merchant applications from request through evidence, governed decision and selected structure; funded paths continue through performance, monitoring and servicing.     this seems to fit better in my available 2 lines for that.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d56cb79f-4e04-4d3b-a72c-9df6bec8d070"></a>
## Assistant · C109-M00675

C109-M00675 · 2026-09-02T13:08:02.738174-04:00 · active path

Preceding visible parent: [C109-M00674](part-31.md#m-f1b95dac-6c3d-4232-ac68-e8b139cc7fdc)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I prefer your version for the page.

> **Follow synthetic merchant applications from request through evidence, governed decision and selected structure; funded paths continue through performance, monitoring and servicing.**

It is tighter, fits the two-line constraint better, and preserves the important distinction that only funded paths proceed into lifecycle performance. I would use it exactly as written.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6c2b4ae4-67d6-4c59-9003-7721d4dd5a4d"></a>
## Andrew / user · C109-M00676

C109-M00676 · 2026-09-02T13:23:38.149000-04:00 · active path

Preceding visible parent: [C109-M00675](part-31.md#m-d56cb79f-4e04-4d3b-a72c-9df6bec8d070)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 11172073-a1fa-420b-a67e-006d95f95cf2.png

<!-- BEGIN_SOURCE_MESSAGE -->
Regarding the left profile is it possible to get Industry value to read on two lines? I'd like it to read on two lines and raise the font slightly. 
<!-- END_SOURCE_MESSAGE -->


<a id="m-8b21d4a8-f3f2-465c-b3e9-a5340046aaa1"></a>
## Andrew / user · C109-M00677

C109-M00677 · 2026-09-02T13:24:28.260000-04:00 · active path

Preceding visible parent: [C109-M00676](part-31.md#m-6c2b4ae4-67d6-4c59-9003-7721d4dd5a4d)

<!-- BEGIN_SOURCE_MESSAGE -->
why are you generating an image...
<!-- END_SOURCE_MESSAGE -->


<a id="m-3b419581-c101-48f6-8ad8-1deea699c9d2"></a>
## Assistant · C109-M00678

C109-M00678 · 2026-09-02T13:24:33.408069-04:00 · active path

Preceding visible parent: [C109-M00677](part-31.md#m-8b21d4a8-f3f2-465c-b3e9-a5340046aaa1)

<!-- BEGIN_SOURCE_MESSAGE -->
That was my mistake. You asked for Power BI formatting guidance, not an image. I should not have triggered image generation.

And yes — you can absolutely make the **Industry value wrap intentionally onto two lines** and then raise its font size independently from the other profile values.

Because Power BI will not reliably wrap `Professional Services` just because **Text wrap = On**, the cleanest approach is a P03 display measure with an explicit line break.

Create this measure in `R1Measures` under `P03 | Application Journey`:

```DAX
R26 P03 Industry Display =
VAR _Industry =
    SELECTEDVALUE ( 'DimIndustry'[industry_name] )
RETURN
    SWITCH (
        _Industry,
        "Construction & Skilled Trades", "Construction &" & UNICHAR ( 10 ) & "Skilled Trades",
        "E-Commerce & Digital",          "E-Commerce &" & UNICHAR ( 10 ) & "Digital",
        "Energy Services",               "Energy" & UNICHAR ( 10 ) & "Services",
        "General Retail",                "General" & UNICHAR ( 10 ) & "Retail",
        "Healthcare Services",           "Healthcare" & UNICHAR ( 10 ) & "Services",
        "Professional Services",         "Professional" & UNICHAR ( 10 ) & "Services",
        "Restaurant & Food Service",     "Restaurant &" & UNICHAR ( 10 ) & "Food Service",
        "Transportation & Logistics",    "Transportation &" & UNICHAR ( 10 ) & "Logistics",
        _Industry
    )
```

Then on your left profile card:

1. Select the profile visual.
2. In **Build visual**, locate the existing Industry field.
3. Remove the existing industry-name field.
4. Add:
   `R26 P03 Industry Display`
5. **Rename for this visual** → `Industry`.

Then format only that card. You are already in exactly the right area shown in your screenshot:

1. **Format visual → Visual**
2. Under **Apply settings to**
3. Choose **Cards → Industry**
4. Expand **Value**
5. Keep **Text wrap = On**
6. Increase the font from **9** to **10** initially.
7. Keep **Bold** on, as you currently have it.
8. Keep horizontal alignment **Left**.

For example, it would become:

```text
Industry
Professional
Services
```

I would start with **10 pt**, not 11. Your left rail is compact, and two lines at 10 pt should improve readability without forcing the card below it to move too much.

You may also need a very small height adjustment to the Industry card itself. Under **Apply settings to → Cards → Industry → Padding**, reduce vertical padding slightly if the two-line value creates too much white space.

I prefer this controlled approach over simply narrowing the card because it gives every industry a deliberate, readable break rather than letting Power BI decide where to wrap.
<!-- END_SOURCE_MESSAGE -->


<a id="m-01e8c8b3-4db6-483d-8985-ca2eac8511c8"></a>
## Andrew / user · C109-M00679

C109-M00679 · 2026-09-02T13:32:21.795000-04:00 · active path

Preceding visible parent: [C109-M00678](part-31.md#m-3b419581-c101-48f6-8ad8-1deea699c9d2)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 010796d0-c709-4e41-bcfe-3179f7a291b1.png

<!-- BEGIN_SOURCE_MESSAGE -->
it's null: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-ee6903b0-3f58-48fe-864e-b603d1e33486"></a>
## Assistant · C109-M00680

C109-M00680 · 2026-09-02T13:32:29.706239-04:00 · active path

Preceding visible parent: [C109-M00679](part-31.md#m-01e8c8b3-4db6-483d-8985-ca2eac8511c8)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The screenshot tells us exactly what happened: **the formatting idea is fine; I referenced the wrong semantic field in the measure.**

`Industry_old` is still correctly returning **Professional Services**, while `R26 P03 Industry Display` is returning blank. That means `DimIndustry[industry_name]` is not receiving the merchant/application filter context the way the existing P03 Industry field does.

Do **not** change relationships or try to force this with `MAX()`. We should simply base the display measure on the **same physical field that already works in `Industry_old`**.

### 1. Identify the existing working Industry field

Keep the page exactly as it is for a moment.

1. Click the `Industry_old / Professional Services` portion of the left profile visual.
2. In the **Visualizations** pane, switch from **Format visual** to **Build visual** by clicking the first icon near the top.
3. Find the field corresponding to `Industry_old`.
4. Hover over it, or click its dropdown arrow.
5. Note the **exact table name and field name**.

It will look something like:

```text
R1DimApplicationScenario[industry_name]
```

or perhaps an existing core field from another table.

**That exact field is what we want.**

### 2. Replace the Industry display measure

Once you know that working field, edit `R26 P03 Industry Display`.

For example, **if the existing working field is**:

```DAX
'R1DimApplicationScenario'[industry_name]
```

then use:

```DAX
R26 P03 Industry Display =
VAR _Industry =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[industry_name]
    )
RETURN
    SWITCH (
        _Industry,
        "Construction & Skilled Trades",
            "Construction &" & UNICHAR ( 10 ) & "Skilled Trades",
        "E-Commerce & Digital",
            "E-Commerce &" & UNICHAR ( 10 ) & "Digital",
        "Energy Services",
            "Energy" & UNICHAR ( 10 ) & "Services",
        "General Retail",
            "General" & UNICHAR ( 10 ) & "Retail",
        "Healthcare Services",
            "Healthcare" & UNICHAR ( 10 ) & "Services",
        "Professional Services",
            "Professional" & UNICHAR ( 10 ) & "Services",
        "Restaurant & Food Service",
            "Restaurant &" & UNICHAR ( 10 ) & "Food Service",
        "Transportation & Logistics",
            "Transportation &" & UNICHAR ( 10 ) & "Logistics",
        _Industry
    )
```

But **don't paste that exact version until you confirm the table/field from `Industry_old`**. Replace that first reference with whatever field your existing working card is actually using.

### 3. Then test before deleting `Industry_old`

After updating the measure:

1. Return to Report view.
2. The new `Industry` card should immediately change from `--` to:

```text
Professional
Services
```

3. Change Merchant from `000749` to several others.
4. Verify the new Industry display follows the merchant exactly as `Industry_old` does.

Once those match, delete `Industry_old` from the visual.

### 4. Your current formatting can stay

I can see you already set the new Industry value to **11 pt**, bold, wrap on. That looks like the right size for this rail. Once the measure actually returns text, I would test 11 pt before reducing it.

One other thing visible in your screenshot: the profile rail currently cuts off `Prior funded` because the extra temporary Industry card consumed vertical space. **Don't resize anything yet.** Once `Industry_old` is removed, we recover that vertical space and can evaluate the final rail cleanly.

So the only thing I need from you is the **exact table + field shown for `Industry_old` in Build visual**. Send me that and I'll give you the exact corrected DAX with no guesswork.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1c8d1d2d-f4cf-49a8-9276-7275d1740101"></a>
## Andrew / user · C109-M00681

C109-M00681 · 2026-09-02T13:36:48.423000-04:00 · active path

Preceding visible parent: [C109-M00680](part-31.md#m-ee6903b0-3f58-48fe-864e-b603d1e33486)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 1987df26-1f9f-4e3e-8bd0-0dd18ec1f520.png; acaaf15c-512e-4b29-b1d1-7db91c35f564.png; 970a456c-023b-4ef1-a3ca-5014614269f7.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-b39fd9e6-1679-4cb5-913e-fc94ab348576"></a>
## Assistant · C109-M00682

C109-M00682 · 2026-09-02T13:37:06.175788-04:00 · active path

Preceding visible parent: [C109-M00681](part-31.md#m-1c8d1d2d-f4cf-49a8-9276-7275d1740101)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — now we have the exact answer.

The existing working field is **not** a physical column named `ModelParameters[P03 Industry]`. It is a **measure** called `P03 Industry`, and your third screenshot shows its actual logic:

```DAX
P03 Industry =
VAR _IndustryCode =
    SELECTEDVALUE ( 'DimMerchant'[industry_code] )
RETURN
    IF (
        ISBLANK ( _IndustryCode ),
        "NOT AVAILABLE",
        CALCULATE (
            SELECTEDVALUE ( 'DimIndustry'[industry_name] ),
            TREATAS (
                { _IndustryCode },
                'DimIndustry'[industry_code]
            )
        )
    )
```

So the clean fix is: **build the display measure on top of the existing working `[P03 Industry]` measure**, not on a column.

Use this exact DAX:

```DAX
R26 P03 Industry Display =
VAR _Industry =
    [P03 Industry]
RETURN
    SWITCH (
        _Industry,
        "Construction & Skilled Trades",
            "Construction &" & UNICHAR ( 10 ) & "Skilled Trades",
        "E-Commerce & Digital",
            "E-Commerce &" & UNICHAR ( 10 ) & "Digital",
        "Energy Services",
            "Energy" & UNICHAR ( 10 ) & "Services",
        "General Retail",
            "General" & UNICHAR ( 10 ) & "Retail",
        "Healthcare Services",
            "Healthcare" & UNICHAR ( 10 ) & "Services",
        "Professional Services",
            "Professional" & UNICHAR ( 10 ) & "Services",
        "Restaurant & Food Service",
            "Restaurant &" & UNICHAR ( 10 ) & "Food Service",
        "Transportation & Logistics",
            "Transportation &" & UNICHAR ( 10 ) & "Logistics",
        _Industry
    )
```

A couple of important points:

- Do **not** write `'ModelParameters'[P03 Industry]`. That syntax assumes `P03 Industry` is a column, which is why Power BI rejected it.
- Refer to the existing measure simply as `[P03 Industry]`.
- Your existing measure already handles the `DimMerchant[industry_code]` → `DimIndustry[industry_name]` lookup with `TREATAS`, so we should reuse that rather than duplicate the relationship logic.

After updating:

1. Click the checkmark to validate the measure.
2. Return to Report view.
3. The new `Industry` value should now display:
   `Professional`
   `Services`
4. Change merchants a few times and confirm it follows `Industry_old`.
5. Once confirmed, remove `Industry_old`.
6. Keep the new Industry at **11 pt bold** with **Text wrap On**. Based on your screenshot, 11 pt should work well once the duplicate temporary field is removed.

That is the right implementation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b4c5a807-191b-4a90-aaaa-3a2b41242687"></a>
## Andrew / user · C109-M00683

C109-M00683 · 2026-09-02T13:52:27.562000-04:00 · active path

Preceding visible parent: [C109-M00682](part-31.md#m-b39fd9e6-1679-4cb5-913e-fc94ab348576)

<!-- BEGIN_SOURCE_MESSAGE -->
for step 5, so both cards have the same Alt Text - R26 P03 Decision Tile Alt Text?
<!-- END_SOURCE_MESSAGE -->


<a id="m-6a87978b-9c64-4bb5-96f4-0abb29734046"></a>
## Assistant · C109-M00684

C109-M00684 · 2026-09-02T13:52:30.912922-04:00 · active path

Preceding visible parent: [C109-M00683](part-31.md#m-b4c5a807-191b-4a90-aaaa-3a2b41242687)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **if your decision tile is physically built as two separate cards**, both should use the same dynamic alt-text measure:

`R26 P03 Decision Tile Alt Text`

That is intentional because the two cards are really **one semantic object**:

- Card 1: `R26 P03 Decision Class` → `AUTHORIZED`, `REVIEW`, `DECLINED`
- Card 2: `R26 P03 Decision Label` → `Approved as requested`, `Counteroffer authorized`, `Counteroffer review`, etc.

The alt-text measure describes the **combined decision**, e.g. conceptually: “Governed decision: REVIEW — Counteroffer review. Search: …”

One refinement, though: having identical alt text on two separately focusable cards can cause a screen reader to announce the same information twice. So if Power BI exposes both cards independently in the tab order, my preference is:

**Decision Class card:** `R26 P03 Decision Tile Alt Text`  
**Decision Label card:** remove from tab order / decorative if possible, and leave its alt text blank.

If Power BI doesn't let us make the second card non-focusable cleanly, then using the same alt text on both is acceptable for now, but **one accessible semantic object is the better final design**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ee959db6-45a7-4d13-97b7-8a73ee0bfe02"></a>
## Andrew / user · C109-M00685

C109-M00685 · 2026-09-02T13:55:33.018000-04:00 · active path

Preceding visible parent: [C109-M00684](part-31.md#m-6a87978b-9c64-4bb5-96f4-0abb29734046)

<!-- BEGIN_SOURCE_MESSAGE -->
for the left KPI card - current alt text ok? Merchant profile for the selected application, showing merchant ID, industry, size tier, annual sales band, relationship stage, relationship quality, prior advance count, and prior funded amount.     what about merchant request alt text? Application request details for the selected merchant and scenario, including application date, requested amount, use, channel, remittance rate, expected payoff period, and requested repayment.
<!-- END_SOURCE_MESSAGE -->


<a id="m-50df23c2-d549-4823-a10d-cb035b37f0b1"></a>
## Assistant · C109-M00686

C109-M00686 · 2026-09-02T13:55:37.034828-04:00 · active path

Preceding visible parent: [C109-M00685](part-31.md#m-ee959db6-45a7-4d13-97b7-8a73ee0bfe02)

<!-- BEGIN_SOURCE_MESSAGE -->
Both are fundamentally good. I would make **one small update to each** so the accessibility wording matches the successor P03 semantics we are establishing.

For the **left Merchant profile card**, change `application` to `merchant` because most of those attributes describe the merchant rather than the application:

> **Merchant profile for the selected merchant, showing merchant ID, industry, size tier, annual sales band, relationship stage, relationship quality, prior advance count, and prior funded amount.**

That is the version I would freeze.

For **Merchant request**, your current alt text is already accurate. I would make only one terminology adjustment—`expected payoff period` → `requested payoff period`—because this block describes the **merchant's requested structure**, not an expectation generated by the model:

> **Application request details for the selected merchant and scenario, including application date, requested amount, use, channel, remittance rate, requested payoff period, and requested repayment.**

So yes: **keep both, with those two minor refinements.**

That also gives P03 a clean accessibility progression: **Merchant profile → Application request → Governed decision → Selected structure → Evidence/narratives → Funded lifecycle**, which mirrors the visual and analytical story of the page.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dfefbd8e-c132-45a6-a433-9ba0d4933aa2"></a>
## Andrew / user · C109-M00687

C109-M00687 · 2026-09-02T13:59:12.486000-04:00 · active path

Preceding visible parent: [C109-M00686](part-31.md#m-50df23c2-d549-4823-a10d-cb035b37f0b1)

<!-- BEGIN_SOURCE_MESSAGE -->
is the selected amount set up correctly? it changed my "Selected structure" table to be many rows when it should just be at most 1 row
<!-- END_SOURCE_MESSAGE -->


<a id="m-0fffd50b-d8b4-4e86-ac96-77ce91133812"></a>
## Assistant · C109-M00688

C109-M00688 · 2026-09-02T13:59:22.349135-04:00 · active path

Preceding visible parent: [C109-M00687](part-31.md#m-dfefbd8e-c132-45a6-a433-9ba0d4933aa2)

<!-- BEGIN_SOURCE_MESSAGE -->
The **measure itself is probably fine**, but the **visual is not currently at the right grain**.

`R26 P03 Selected Structure Amount` was defined as:

```DAX
R26 P03 Selected Structure Amount =
    SELECTEDVALUE (
        'R1FactFinalDecision'[governed_selected_funding_amount]
    )
```

That is appropriate for P03 because the selected merchant + scenario should resolve to **at most one governed final-decision row**.

What caused the table to explode into many rows is almost certainly that the visual still contains one or more **raw columns** whose underlying table has multiple rows for the selected application/scenario. In a Power BI table, those columns establish the row grain; adding a scalar measure does not force the table back to one row.

### Fix the Selected structure visual

Select the `Selected structure` table and look at **Build visual → Values**.

For this block, I want **measures only**, except for the existing funding date if that field is already known to resolve uniquely.

Use:

```text
R26 P03 Selected Structure Amount
R26 P03 Selected Remittance Rate
R26 P03 Selected Payback Multiple
R26 P03 Selected Horizon Days
R26 P03 Selected Total Repayment
```

Remove any raw columns such as:

```text
governed_selected_funding_amount
governed_selected_remittance_rate
governed_selected_payback_multiple
governed_selected_horizon_days
governed_selected_total_repayment_amount
candidate_id
candidate_rank
offer_candidate_id
selected_candidate_id
```

or any fields sourced directly from `R1FactOfferCandidate` / `R1FactCandidateEvaluation`.

Those candidate-grain fields can create multiple rows because candidate search legitimately has many candidates.

### Funding date

For now, **temporarily remove the funding-date field too**.

Once the five selected-structure measures display as exactly **one row**, we will add funding date back using a scalar measure rather than a raw column. That prevents the same grain issue.

Create:

```DAX
R26 P03 Funding Date =
SELECTEDVALUE (
    'FactBookingActivation'[funding_date]
)
```

**But don't use that exact table/column yet unless that is the field your current P03 `Funded` column uses.** We should inspect the existing working funding-date source first, just as we did with Industry, rather than guess its field name.

### Expected result

For `000749 / Baseline`, you should get one row resembling:

| Selected amount | Remittance | Payback multiple | Horizon days | Repayment |
|---|---:|---:|---:|---:|
| $11,700.00 | 9.85% | 1.21 | 90 | $14,179.50 |

For `000749 / Recession Energy`, it should also be **at most one row** if a governed review candidate was selected.

For a decline/no-selected-structure path, the row may be blank or Power BI may suppress it depending on the table settings—but it should **never fan out into candidate-level rows**.

So yes: **`Selected Structure Amount` as a measure is conceptually correct. The many-row result tells us the Selected structure table still contains a field that is setting the wrong grain.**

If you send me a screenshot of the **Values field well for that Selected structure visual**, I can tell you exactly which fields to remove and what to replace each with.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cfc2ecc9-7f17-4fc3-a764-2fb9cb38e010"></a>
## Andrew / user · C109-M00689

C109-M00689 · 2026-09-02T14:09:33.749000-04:00 · active path

Preceding visible parent: [C109-M00688](part-31.md#m-0fffd50b-d8b4-4e86-ac96-77ce91133812)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: d599aca9-8bd9-45a7-a23a-7adb8106c095.png

<!-- BEGIN_SOURCE_MESSAGE -->
This is interesting. So it says REVIEW / Counteroffer review and "An alternative structure was identified..." Selected structure is populated and funding date is populated. Also, the selected amount = requested but the repayment is > under the selected structure. please explain why this makes sense. 
<!-- END_SOURCE_MESSAGE -->
