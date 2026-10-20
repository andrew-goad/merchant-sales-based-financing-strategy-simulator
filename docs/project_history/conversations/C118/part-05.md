# MSBF - Power BI Executive Portfolio Intelligence Part 3

Part 05 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-04.md)
[Next part](part-06.md)

<a id="m-5af312db-1b9a-4490-998b-9312d0440256"></a>
## Assistant · C118-M00065

C118-M00065 · 2026-09-03T19:45:06.864233-04:00 · active path

Preceding visible parent: [C118-M00064](part-04.md#m-20eb815c-107a-453f-acd3-2b5c8d3f0de4)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I would stop exposing the internal construction name once we finish this controlled build. `MSBF_PBI_R26_PARALLEL_REFINEMENT...` is useful lineage, but it reads like an engineering workstream—not a client-ready product.

My recommendation is:

# **MSBF Merchant Credit Intelligence**

Short form:

**MSBF MCI**

And I would use the subtitle:

> **Decisioning, Portfolio & Servicing Intelligence**

That combination fits what the Power BI product actually does through Module 2:

- merchant/application profiling;
- governed credit decisioning;
- strategy and structure selection;
- portfolio/cohort intelligence;
- funded-account lifecycle;
- monitoring;
- intervention and servicing;
- economics and decision-effectiveness views.

It also avoids overclaiming. “Credit Intelligence” is broad enough to encompass the current decisioning and servicing architecture without implying that this is a production underwriting platform.

### Recommended naming convention

I would separate the **market-facing product name** from the **technical release identity**:

| Purpose | Name |
|---|---|
| Product/report title | **MSBF Merchant Credit Intelligence** |
| Short name | **MSBF MCI** |
| Subtitle | **Decisioning, Portfolio & Servicing Intelligence** |
| Current scope label | **Module 2 Architecture** |
| Current release identity | **v2.1.0-rc2** |
| PBIX filename while RC | `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2.pbix` |
| Final PBIX filename after accepted release | `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0.pbix` |
| GitHub display/folder name | `MSBF Merchant Credit Intelligence` |

For the report footer, I would change the current engineering-style model identity to something like:

> **Model:** MSBF MCI · M2 v2.1.0-rc2

That is much cleaner than:

> `PBI_R26_PARALLEL_REFINEMENT_C2_20260902`

while we can still retain that exact C2/R26 lineage internally in manifests, audit evidence, package receipts, and technical metadata.

## Why I prefer this over the alternatives

**Merchant Finance Intelligence** is a little too broad—it sounds like accounting, treasury, or financial-management analytics.

**Merchant Lending Intelligence** is good, but somewhat narrower and more product-specific.

**Credit Strategy Intelligence** understates the monitoring and servicing architecture.

**Decisioning & Servicing Intelligence** is accurate but sounds more like an internal platform component.

**Merchant Credit Intelligence** is concise, recognizable, and sounds like something a consulting team, fintech, bank, or risk organization could actually present to executives.

It also scales well later. Module 3 can become a deeper enterprise layer **inside the same MSBF Merchant Credit Intelligence product** rather than forcing us to rename the portfolio again.

### I would standardize on this now

For the visible Power BI product:

> **MSBF Merchant Credit Intelligence**  
> *Decisioning, Portfolio & Servicing Intelligence*

For compact footer identity:

> **Model: MSBF MCI · M2 v2.1.0-rc2**

And keep `R26`, `C2`, hashes, and construction lineage **behind the scenes as controlled technical metadata**, not in the client-facing branding.

That is the naming convention I would carry consistently through P03–P06, the final Power BI package, GitHub documentation, screenshots, README material, and eventual release assets.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d0d3eeaa-0080-47e1-a6a9-5de6b559813e"></a>
## Andrew / user · C118-M00066

C118-M00066 · 2026-09-03T20:05:19.990000-04:00 · active path

Preceding visible parent: [C118-M00065](part-05.md#m-5af312db-1b9a-4490-998b-9312d0440256)

**Editorial record note:** 3 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P01_Corrected_File_Name_Footnote.png; P02_Corrected_File_Name_Footnote.png; P03_Corrected_File_Name_Footnote.png

<!-- BEGIN_SOURCE_MESSAGE -->
I've fixed footnotes and file names. Attached are updated evidence of that for P01, P02, and P03. We do not need to recreate all other evidence, but can point to that change with these latest captures. what else needs corrected on P03 to get to sign off.
<!-- END_SOURCE_MESSAGE -->


<a id="m-110e647a-ac73-4472-b287-5a9af6e76f4b"></a>
## Assistant · C118-M00067

C118-M00067 · 2026-09-03T20:05:26.731457-04:00 · active path

Preceding visible parent: [C118-M00066](part-05.md#m-d0d3eeaa-0080-47e1-a6a9-5de6b559813e)

<!-- BEGIN_SOURCE_MESSAGE -->
The naming/footer correction is now good. The new filename and visible footer identity are aligned and client-ready:

> **MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2**  
> **Model version: MSBF MCI · M2 v2.1.0-rc2**

Your new P01/P02/P03 captures are sufficient to supersede the old footer/name evidence without recreating the earlier screenshot population.

For **P03 sign-off**, I see only a small closeout list remaining.

1. **Remove the visible `Action` column from Servicing & intervention.** I still recommend this. In the current R26 M2.6 design, Intervention and Action are nearly one-to-one presentation variants, so the second column adds little analytical information. The stronger final table is:

   **Recommended intervention | Queue | Exposure | Reason**

   This also better preserves the M2.6 boundary: P03 is showing the **recommended intervention**, while actual setup/execution belongs downstream in P04. Do not delete the `R26 P03 Servicing Action Display` measure from the model; just stop displaying it here.

   After doing so, update `R26 P03 Servicing Alt Text` to remove the Action sentence as previously provided.

2. **Turn on the primary Account performance Y-axis title: `Remaining receivable`.** Your new screenshot still shows the secondary-axis title `Remittance pace`, but I do not see the left-axis title. This is a presentation-quality item rather than a semantic defect, but I would fix it before freeze.

3. **Technical rationale tooltip must be verified and captured.** This remains the substantive evidence item I have not seen. The P03 architecture intentionally retains a second technical layer underneath the executive narratives, using `R26 P03 Technical Evidence Rationale`, `R26 P03 Technical Structure Rationale`, and `R26 P03 Technical Decision Rationale`. [export reference: filecite | turn123file0 | L84-L114]  
   If the tooltip already exists, no redesign is needed—just capture one representative hover showing that it works and follows the selected ApplicationScenarioKey. If it was never completed, build it before freeze.

4. **Capture one Monitoring journey hover.** We already have Account performance tooltip evidence, but the strengthened Monitoring Journey has several important successor-only tooltip fields. One representative hover is enough to demonstrate that `Primary alert family`, `Daily shortfall alert`, `Remittance pace`, `Cumulative shortfall`, `Days since remittance`, operational-family count, and raw-condition count resolve in the current model.

5. **Run/capture the post-remediation P03 performance/monitoring QA if you have not already done so.** Narrative QA alone is not the entire final control set. We want the separate operational QA confirming:
   - 15,600 monitoring rows / 130 paths / 120–120 days;
   - 0 reconciliation failures;
   - 738 Baseline = funded monitoring path, 738 Recession Energy = no monitoring path;
   - 126 closed / 3 outreach / 1 temporary-remittance intervention population.

6. **Final persistence check:** save → completely close Power BI Desktop → reopen this newly named RC2 PBIX → spot-check:
   - 738 Baseline;
   - 738 Recession Energy;
   - 749 Baseline;
   - one review case such as 082 Baseline.

   Then rerun the narrative QA. The narrative control remains 2-row scenario regression, zero genuine failures, and 1,500 PASS rows. The accepted QA architecture specifically requires the full 1,500-path inventory and zero failures. [export reference: filecite | turn123file5 | L400-L440]

### What does **not** need more work

I would **not** reopen any of these:

- visible narrative wording;
- Merchant Request;
- Proposed structure;
- decision cards;
- merchant profile formatting;
- temporal/interpretation boundary wording;
- title/subtitle;
- expected-to-date logic;
- funded-lifecycle integration;
- narrative branch screenshots;
- the 738 scenario-isolation narrative work;
- page layout/geometry.

The narrative system is explicitly intended to tell **what we observed → how the request was tested → why the final path followed**, without recomputing the governed decision. Your completed P03 now does that well. [export reference: filecite | turn123file0 | L11-L23]

### Sign-off gate

Once the six items above are complete, my intended disposition is:

```text
P03 Application Journey
Semantic implementation          PASS
Narrative implementation         PASS
Lifecycle integration            PASS
Monitoring / servicing           PASS
Accessibility                    PASS
Current release identity         PASS
QA                               PASS
Save / reopen persistence        PASS
Evidence package                 PASS
FINAL STATUS                     PASS / FROZEN
```

So the only visual change I would still make is **remove Action** and **show `Remaining receivable` on the primary Y-axis**. Everything else is evidence/closeout rather than further page design.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bbb87ecb-30ed-4eec-9e00-3b863879319d"></a>
## Andrew / user · C118-M00068

C118-M00068 · 2026-09-03T20:07:29.420000-04:00 · active path

Preceding visible parent: [C118-M00067](part-05.md#m-110e647a-ac73-4472-b287-5a9af6e76f4b)

<!-- BEGIN_SOURCE_MESSAGE -->
Is there anything we can fill that space though after removing Action from the Servicing & Intervention table. Anything else that would be informative there? Not a lot, but any 1 more variable that would be relevant to that story?
<!-- END_SOURCE_MESSAGE -->


<a id="m-1e315b97-6f60-4610-a841-42e930ccfd4b"></a>
## Assistant · C118-M00069

C118-M00069 · 2026-09-03T20:07:32.346660-04:00 · active path

Preceding visible parent: [C118-M00068](part-05.md#m-bbb87ecb-30ed-4eec-9e00-3b863879319d)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. There is one field I think improves the story rather than merely filling space:

**Priority**

But I would **not** use the raw numeric `servicing_priority_rank`. I would expose it as a business-facing **Priority** classification.

The final table would become:

| Recommended intervention | Queue | Priority | Exposure | Reason |
|---|---|---|---:|---|
| Temporary remittance review | Servicing review | High | $4,699.37 | Severe shortfall |
| Targeted outreach review | Servicing review | Medium | $1,720.89 | Severe shortfall |
| No further action | Closed | None | $0.00 | Paid off |

### Why Priority earns the space

The five columns would answer five distinct operational questions:

**Recommended intervention** → What should we do?  
**Queue** → Where should it go?  
**Priority** → How urgently should it be handled?  
**Exposure** → How much is at stake?  
**Reason** → Why is intervention indicated?

That's materially better than:

> Intervention → Action

where both are essentially answering “what should happen?”

There is one caveat. Earlier I rejected Priority as a *replacement on semantic-information grounds* because the source `servicing_priority_rank` is itself determined by the same intervention state. That remains true: **Priority does not add a new independent risk signal.** But your question now is whether one additional variable would improve the operational presentation. In that role, Priority does add useful **workflow interpretation**.

I would therefore use it, provided we label it accurately rather than implying it is an independently modeled urgency score.

### Recommended mapping

The source rank is:

```text
0 → closed/no action
1 → continue monitoring
2 → targeted outreach review
3 → temporary remittance review
```

For P03, I would translate that to:

```DAX
R26 P03 Servicing Priority Display =
VAR _Priority =
    SELECTEDVALUE (
        'R1FactIntervention'[servicing_priority_rank]
    )
RETURN
    SWITCH (
        _Priority,
        0, "None",
        1, "Routine",
        2, "Medium",
        3, "High",
        BLANK ()
    )
```

I prefer **None / Routine / Medium / High** over Low / Medium / High because rank 0 is genuinely a closed/no-action state, not a low-priority servicing case.

### One alternative I considered

`Review required` would be another candidate, but I would **not** use it. It would largely repeat Queue and Intervention.

Likewise I would reject:

- funding date — already shown in Proposed structure;
- monitoring status — duplicates Reason for the current M2.6 mapping;
- remittance pace — already available in Account performance/Monitoring journey;
- operational alert count — belongs more naturally in the monitoring story/tooltips;
- servicing execution state — belongs in **P04**, not P03;
- payment/reconciliation status — also P04;
- selected horizon or structure data — already shown on the left.

So if we want five columns, my preferred final design is:

> **Recommended intervention | Queue | Priority | Exposure | Reason**

That actually improves the table's operational readability while maintaining the important P03/P04 boundary.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5f3228cf-593b-478d-a083-c4185a993a90"></a>
## Andrew / user · C118-M00070

C118-M00070 · 2026-09-03T20:17:14.626000-04:00 · active path

Preceding visible parent: [C118-M00069](part-05.md#m-1e315b97-6f60-4610-a841-42e930ccfd4b)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P03_Servicing_&_Intervention_Removed_Action_Added_Priority.png; P03_Tooltip_Evidence.png

<!-- BEGIN_SOURCE_MESSAGE -->
Corrected that servicing table and made sure the capture also caught the tooltips of the monitoring journey. Earlier we had also captured the tooltips of the Account Performance in the reattached P03_Tooltip_Evidence. What else needs corrected in P03?
<!-- END_SOURCE_MESSAGE -->


<a id="m-8e0cbd56-f0d0-4f96-b251-4308d031989d"></a>
## Assistant · C118-M00071

C118-M00071 · 2026-09-03T20:17:17.533144-04:00 · active path

Preceding visible parent: [C118-M00070](part-05.md#m-5f3228cf-593b-478d-a083-c4185a993a90)

<!-- BEGIN_SOURCE_MESSAGE -->
The two new captures close the two visual items I had outstanding.

The revised **Servicing & intervention** table is better. `Intervention | Queue | Priority | Exposure | Reason` now gives each column a distinct operational role, and the 749 example reads cleanly as **Temporary remittance review → Servicing review → High → $4,699.37 → Severe shortfall**. I would keep it exactly that way.

The new Monitoring journey hover also closes that evidence gap. It demonstrates the intended successor tooltip stack: status, primary alert family, daily-shortfall alert, remittance pace, cumulative shortfall, days since remittance, operational-alert-family count, and raw-alert-condition count. The previously captured Account performance hover demonstrates its corresponding performance tooltip.

## What remains before P03 sign-off

At this point I would **stop changing the visible P03 design**. I see only these closeout controls:

1. **Update `R26 P03 Servicing Alt Text` for the final table.** Since Action is no longer visible and Priority is, the accessibility measure should match the physical visual. Use:

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
        & ". Priority: "
        & COALESCE (
            [R26 P03 Servicing Priority Display],
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

Then confirm the Servicing visual's Alt text remains bound to that measure.

2. **Technical-rationale tooltip remains the only page feature/evidence item I still have not seen.** This is different from the two tooltips you just proved. The narrative architecture deliberately preserves exact technical rationales underneath the executive-facing narratives—Evidence, Structure, and Decision—so the polished explanation remains traceable to source-owned rationale. [export reference: filecite | turn123file9 | L820-L850]

   If you've already built that report-page tooltip, simply capture one representative invocation. If it has not been built, this is the last actual P03 feature I would add.

3. **Run/capture the separate performance/monitoring QA.** The narrative QA is already excellent and complete; its controlling design explicitly checks the 738 scenario pair, zero failures, and the complete 1,500-row inventory. [export reference: filecite | turn123file7 | L614-L675] We still need the operational QA from the later performance/monitoring remediation to establish the 15,600-row/130-path monitoring population and intervention reconciliation.

4. **Persistence test.** After items 1–3:
   - Save `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2`.
   - Completely close Power BI Desktop.
   - Reopen it.
   - Check 738 Baseline.
   - Switch to 738 Recession Energy and confirm downstream lifecycle visuals blank.
   - Check 749 Baseline and confirm the final servicing row remains `Temporary remittance review | Servicing review | High | $4,699.37 | Severe shortfall`.
   - Rerun the narrative QA and operational QA.

### One thing I would *not* hold sign-off for

I previously mentioned the missing visible left Y-axis title **Remaining receivable**. Looking at the final page in context, I no longer think that is worth forcing.

The Account performance legend already says **Remaining receivable**, the secondary axis needs its explicit `Remittance pace` title because it uses a different unit, and adding a rotated left title would consume scarce horizontal space. The current presentation is cleaner. **Leave it as shown.**

## P03 status now

```text
Page composition                    PASS
Merchant/request presentation       PASS
Decision/proposed structure         PASS
Visible narratives                  PASS
Narrative branch evidence           PASS
Narrative QA                        PASS
Account performance                 PASS
Account-performance tooltip         PASS
Monitoring journey                  PASS
Monitoring-journey tooltip          PASS
Servicing & intervention            PASS
Release identity/footer             PASS
Temporal/interpretation boundary    PASS
Accessibility                       PENDING servicing-alt-text refresh
Technical-rationale traceability    PENDING capture/verification
Operational QA                      PENDING final capture
Persistence                         PENDING final save/reopen
```

**No further narrative, layout, chart, table, or business-logic redesign is warranted.** Once those four bounded closeout items pass, I would sign **P03 = PASS / FROZEN** and move completely to P04.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2b57225c-65e6-49f1-a4aa-5c7c2445aebc"></a>
## Andrew / user · C118-M00072

C118-M00072 · 2026-09-03T20:22:19.986000-04:00 · active path

Preceding visible parent: [C118-M00071](part-05.md#m-8e0cbd56-f0d0-4f96-b251-4308d031989d)

<!-- BEGIN_SOURCE_MESSAGE -->
servicing alt text is corrected. do you mean by #2 that the merchant operating evidence / risk & economics assessment / decision narratives require tooltips? please advise if so on what is needed there.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bbff6493-1780-4685-b253-308f0f81536a"></a>
## Assistant · C118-M00073

C118-M00073 · 2026-09-03T20:22:22.723148-04:00 · active path

Preceding visible parent: [C118-M00072](part-05.md#m-2b57225c-65e6-49f1-a4aa-5c7c2445aebc)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes—but I want to correct the impression my wording may have created.

The three visible narrative sections **do not require ordinary hover tooltips for comprehension**. They are already complete, business-facing explanations:

- **Merchant operating evidence** — what we observed.
- **Risk & economics assessment** — how the request/alternatives were evaluated.
- **Decision** — why the governed outcome followed.

The original narrative design contemplated an **optional technical-rationale drill-down/tooltip layer** containing the exact source-owned `evidence_why_text`, `underwriting_why_text`, and `decision_why_text`. Its purpose was traceability, not to complete the visible narratives. [export reference: filecite | turn123file1 | L202-L232]

### Do we actually need it for P03?

**I would not require it for final P03 sign-off.**

Now that we've completed the page and reviewed the evidence package, I think adding hover behavior to all three narrative tables would be more likely to clutter an already strong executive page than materially improve it.

We already have the important controls:

- the visible narratives are generated from accepted structured R26 facts;
- the technical rationale measures remain preserved in the model;
- the 1,500-path QA evaluates the visible narratives alongside the three technical rationale measures; [export reference: filecite | turn123file5 | L419-L440]
- the narrative architecture explicitly separates polished business language from exact technical/source rationale so traceability is retained. [export reference: filecite | turn123file1 | L222-L232]

That is sufficient for the portfolio product.

### Recommended final treatment

Leave the three narrative visuals **exactly as they are**. Do not add report-page tooltips to them.

Retain these measures in the semantic model:

```text
R26 P03 Technical Evidence Rationale
R26 P03 Technical Structure Rationale
R26 P03 Technical Decision Rationale
```

They remain available for audit, QA, future drill-through, or a technical appendix. The implementation guide itself describes those raw technical rationales as appropriate for being hidden from routine authoring **or tooltip-only**, rather than requiring them to be visible on the page. [export reference: filecite | turn123file1 | L165-L175]

So I am removing **Technical-rationale tooltip** from the P03 freeze blockers.

With your Servicing alt text now corrected, the remaining P03 closeout is just:

1. **Performance/monitoring operational QA** — run/capture the separate final QA we created after replacing the predecessor monitoring/performance bindings.
2. **Final persistence test** — save → close Desktop completely → reopen → spot-check 738 Baseline, 738 Recession Energy, and 749 Baseline → rerun the final QA controls.
3. Then **P03 = PASS / FROZEN**.

You do **not** need to add anything else to Merchant operating evidence, Risk & economics assessment, or Decision.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c3cc7e2a-d829-4901-b555-628a8740f933"></a>
## Andrew / user · C118-M00074

C118-M00074 · 2026-09-03T20:24:20.372000-04:00 · active path

Preceding visible parent: [C118-M00073](part-05.md#m-bbff6493-1780-4685-b253-308f0f81536a)

<!-- BEGIN_SOURCE_MESSAGE -->
yes, I think the narratives are self-explanatory. I do not think that is needed.  what do you mean by: We still need the operational QA from the later performance/monitoring remediation to establish the 15,600-row/130-path monitoring population and intervention reconciliation.  what specific evidence are you after?
<!-- END_SOURCE_MESSAGE -->


<a id="m-e56522d5-52db-46b2-800f-bd05ce93e9cb"></a>
## Assistant · C118-M00075

C118-M00075 · 2026-09-03T20:24:23.519304-04:00 · active path

Preceding visible parent: [C118-M00074](part-05.md#m-c3cc7e2a-d829-4901-b555-628a8740f933)

<!-- BEGIN_SOURCE_MESSAGE -->
I mean a **very specific four-result DAX QA query** we prepared when we replaced the remaining predecessor P03 performance/monitoring bindings with R26/R1 equivalents.

It is **not another visual review**, and you do not need to recreate the extensive P03 narrative evidence.

The file is:

Open the P03 performance/monitoring QA query (historical reference: `sandbox:[session]/MSBF_R26_P03_PERFORMANCE_MONITORING_QA_R1_20260903.dax`; referenced bytes not established here)

### What I want captured

Open **DAX Query View**, paste that query, select **Run only**—do **not** update the model—and capture its four result sets.

| Result | What it proves | Exact expected result |
|---|---|---|
| **1 — monitoring population** | P03 is operating against the complete successor monitoring population rather than the old predecessor population | **15,600 rows; 130 unique application-scenario paths; minimum 120 days; maximum 120 days** |
| **2 — successor-monitoring reconciliation failures** | The new R1-derived Expected-to-date / pace / shortfall semantics reconcile correctly | **0 rows** |
| **3 — 738 scenario isolation** | Baseline's funded lifecycle does not leak into Recession Energy | **738 Baseline = 120 monitoring rows + lifecycle available; 738 Recession Energy = 0 monitoring rows / no lifecycle** |
| **4 — intervention population** | P03 Servicing & intervention is using the complete current M2.6 successor population | **126 closed/no-further-action; 3 targeted-outreach-review; 1 temporary-remittance-review** |

### Why I care about this particular evidence

It closes the exact defect family we found while finishing P03.

Remember, the old `Expected to date` was:

```DAX
SELECTEDVALUE (
    FactAccountDaily[cumulative_expected_remittance_amount]
)
```

That predecessor population covered only **59 funded paths**, whereas current R26 has **130 funded paths / 15,600 monitoring rows**. We subsequently found the same predecessor problem in other Monitoring Journey fields and replaced them with successor-safe semantics.

So the four-result QA is our evidence that:

> **The final physical P03 no longer merely looks correct—it is operating over the complete current successor monitoring/intervention populations and preserves application-scenario isolation.**

It complements the narrative QA rather than duplicating it.

### What to send me

Just four screenshots:

**Result 1 of 4**  
**Result 2 of 4**  
**Result 3 of 4**  
**Result 4 of 4**

You don't need to capture the DAX itself unless you want it in the evidence package; we already have the controlled query.

If those return the expected results above, I will treat **P03 operational QA = PASS**.

Then the only thing left is the save → close → reopen persistence check. After that, I see no reason to keep P03 open: **we freeze it and proceed to P04.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-d9afe469-f73f-4afa-9b88-ea27063451d9"></a>
## Andrew / user · C118-M00076

C118-M00076 · 2026-09-03T20:29:39.593000-04:00 · active path

Preceding visible parent: [C118-M00075](part-05.md#m-e56522d5-52db-46b2-800f-bd05ce93e9cb)

**Editorial record note:** 4 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: P03_Performance_Monitoring_QA_Result_Set_04.png; P03_Performance_Monitoring_QA_Result_Set_03.png; P03_Performance_Monitoring_QA_Result_Set_02.png; P03_Performance_Monitoring_QA_Result_Set_01.png

<!-- BEGIN_SOURCE_MESSAGE -->
performance monitoring QA captured. regarding saving/restarting capture - we will do that after the power bi is complete as a final step. what else is needed for P03 signoff?
<!-- END_SOURCE_MESSAGE -->


<a id="m-44ab94d7-0423-49bf-a656-971f3b500ff4"></a>
## Assistant · C118-M00077

C118-M00077 · 2026-09-03T20:29:42.456041-04:00 · active path

Preceding visible parent: [C118-M00076](part-05.md#m-d9afe469-f73f-4afa-9b88-ea27063451d9)

<!-- BEGIN_SOURCE_MESSAGE -->
The operational QA now passes cleanly from the four captures:

- **Result 1:** `15,600` monitoring rows, `130` application-scenario paths, exactly `120–120` days per path.
- **Result 2:** `0` reconciliation failures.
- **Result 3:** 738 Baseline = `120` monitoring rows + lifecycle available; 738 Recession Energy = `0` monitoring rows / no lifecycle.
- **Result 4:** intervention population = `126 / 3 / 1`, with exposure `$0 / $3,123.91 / $4,699.37`.

So **P03 Performance/Monitoring QA = PASS**.

Given your decision to perform save/close/reopen persistence once after the entire Power BI build is finished, I agree that should **not hold P03 page completion**. It becomes a portfolio-level final persistence gate covering P01–P06 together.

## P03 sign-off

At this point, I do **not** see another substantive P03 correction required.

The final state is:

| Control | Disposition |
|---|---|
| Page story/layout | **PASS** |
| Merchant/profile presentation | **PASS** |
| Merchant request | **PASS** |
| Governed decision | **PASS** |
| Proposed structure | **PASS** |
| Plain-language narratives | **PASS** |
| Narrative branch coverage | **PASS** |
| Narrative QA | **PASS — 2 / 0 / 1,500** |
| Funded-lifecycle integration | **PASS** |
| Account performance | **PASS** |
| Account-performance tooltip | **PASS** |
| Monitoring journey | **PASS** |
| Monitoring tooltip | **PASS** |
| Performance/monitoring QA | **PASS — 15,600 / 130 / 120–120 / zero failures** |
| Servicing & intervention | **PASS** |
| Intervention population | **PASS — 126 / 3 / 1** |
| Servicing Priority refinement | **PASS** |
| Alt text | **PASS** |
| Tab order/accessibility | **PASS** |
| Temporal/interpretation boundaries | **PASS** |
| Publishable model/release identity | **PASS** |
| Technical rationale measures | **RETAINED; no visible tooltip required** |
| Final save/reopen persistence | **DEFERRED to portfolio-wide final gate** |

### Disposition

**P03 — Merchant Application & Account Journey: `PASS / PAGE FROZEN`**

There is one procedural distinction worth preserving: **page frozen does not yet mean release-certified**. We should make no further P03 semantic or presentation changes during P04–P06 construction unless a downstream integration/nonregression test identifies an actual defect. At the end of the complete Power BI build, P03 participates in the common refresh → save → close → reopen → QA/nonregression → evidence gate.

That is cleaner than repeatedly reopening completed pages.

We can now move to **P04 production**. The P04 roadmap we established remains the right starting point, but given what we learned from P03, I would apply the same discipline there: **first establish the canonical existing-measure/reuse landscape, then install only genuinely P04-specific presentation adapters, rather than recreating semantics that P01/P02/P03 already own.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-f1b3956e-c64f-4b56-8436-79d97f345640"></a>
## Andrew / user · C118-M00078

C118-M00078 · 2026-09-03T20:41:35.455000-04:00 · active path

Preceding visible parent: [C118-M00077](part-05.md#m-44ab94d7-0423-49bf-a656-971f3b500ff4)

<!-- BEGIN_SOURCE_MESSAGE -->
You mention a bounded P04 presentation layer. Are there specific P04 measures that we need to create? I do not see a dax handoff like before, if so. Also, I do not want separate P04 subfolders. We'd just have one P04 measures folder if there are indeed P04 specific measures that we need to create. Please advise here and provide what i need for that P04 presentation layer that you mention. 
<!-- END_SOURCE_MESSAGE -->


<a id="m-63807c7e-ed19-4130-855b-99ca96f2b764"></a>
## Assistant · C118-M00079

C118-M00079 · 2026-09-03T20:50:15.102655-04:00 · active path

Preceding visible parent: [C118-M00078](part-05.md#m-f1b3956e-c64f-4b56-8436-79d97f345640)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. There **are P04-specific measures we need to create**, and you were right to notice that I had described a “bounded P04 presentation layer” without actually handing you the corresponding DAX.

I have now built that handoff.

## One P04 folder only

I agree with your preference. All new P04 measures should live in exactly one display folder:

```text
P04 | Servicing & Exceptions
```

No `01 Summary`, `02 Monitoring`, etc. subfolders.

There are **26 P04 measures** in the batch, but that does **not** mean we are inventing 26 new business calculations. The layer deliberately follows the semantic-reuse discipline we established after the P03 problem:

- P04 **reuses** the existing R26 P02 adverse-monitoring semantic for its attention population.
- It **reuses** P01's canonical Certified Exposure, Review Holds, Servicing Burden, and Unresolved Exceptions measures rather than reproducing their mathematics. P01 already owns those endpoint semantics. [export reference: filecite | turn126file8 | L276-L364]
- `R26 P04 Intervention Display` is a pure page alias to the already-governed M2.6 presentation adapter from P03.
- New calculations are confined to genuinely P04-specific needs: endpoint category breakdowns, exact-key workbench fields, friendly M2.7/M2.8/M2.10 state displays, and payment/certification detail.

That is the architecture we want.

### What the 26 measures do

| Class | Count | Purpose |
|---|---:|---|
| Page-summary KPIs | 7 | Attention, exposure, active servicing, review holds, certified exposure, servicing burden, unresolved exceptions |
| Monitoring chart | 3 | Account count, exposure, average pace by endpoint status |
| Servicing chart | 3 | Account count, certified exposure, burden by endpoint servicing queue |
| Attention workbench | 7 | Attention flag, monitoring state/pace, intervention, setup, execution, endpoint state |
| Payment/certification detail | 6 | Payment events, processed payment, return/retry, reconciliation, certification date, certified exposure |
| **Total** | **26** | |

The M2.7, M2.8, M2.9, and M2.10 facts genuinely represent different stages, so the workbench measures intentionally keep them distinct instead of collapsing them into one generic servicing status. For example, M2.7 has explicit setup outcomes/actions and review states, while M2.8 separately owns servicing-execution outcomes and payment processing. [export reference: filecite | turn125file4 | L361-L441] [export reference: filecite | turn130file8 | L569-L579]

## One refinement to the earlier P04 roadmap

After doing this deeper source-level pass, I would **keep the upper-right chart titled `Servicing disposition`**, rather than renaming it `Servicing execution state`.

The chart should summarize the final **M2.10 servicing queue**:

```text
No servicing required
Active reassessment
Governance review hold
```

M2.10 explicitly maps `CLOSED_STABLE`, `ACTIVE_RECONCILED`, and `CONTROLLED_REVIEW` to those three queues. [export reference: filecite | turn127file0 | L19-L52]

Then the **Account attention workbench** shows the actual M2.8 **Execution state**. This creates a better hierarchy:

```text
Top chart:
Where did the account ultimately land operationally?

Workbench:
What intervention → setup → execution → endpoint chain produced that state?
```

That is cleaner than using the top chart and the workbench to tell the same M2.8 story.

## Two small model-display additions

The new measures are all in the one P04 folder. Separately, we need **three calculated columns strictly for readable chart categories**:

```text
DimMonitoringStatus[P04 Monitoring Status Label]
DimMonitoringStatus[P04 Monitoring Status Sort]
DimServicingQueue[P04 Servicing Queue Label]
```

Those dimensions currently provide codes, ranks, flags, descriptions, etc., but not the concise business-facing labels we need for these charts. [export reference: filecite | turn129file0 | L9-L20] [export reference: filecite | turn129file1 | L31-L39]

The guide contains the exact calculated-column DAX. They are presentation metadata only; they do not alter any source fact.

# What to do now

### 1. Install the P04 measure layer

Open this file:

Download the P04 presentation-layer DAX (historical reference: `sandbox:[session]/p04_presentation_layer/MSBF_R26_P04_PRESENTATION_LAYER_R1_20260903.dax`; referenced bytes not established here)

In Power BI:

1. Save `MSBF_Merchant_Credit_Intelligence_M2_v2.1.0-rc2`.
2. Open **DAX Query View**.
3. Paste the complete file.
4. Click **Run** first.
5. The final result should report:

```text
Patch                  R26 P04 successor presentation layer R1
Measures               26
Display folder         P04 | Servicing & Exceptions
Source mutation        NONE
Relationship mutation  NONE
Methodology mutation   NONE
```

6. If it compiles cleanly, click **Update model with changes** once.
7. Move all 26 measures into:

```text
P04 | Servicing & Exceptions
```

If Power BI reports any identifier/compile error, **stop there and send me the exact error**. Do not substitute another field based on name similarity.

### 2. Add the three calculated display columns

The complete formulas and sorting instructions are here:

Open the P04 presentation-layer implementation guide (historical reference: `sandbox:[session]/p04_presentation_layer/MSBF_R26_P04_PRESENTATION_LAYER_GUIDE_R1_20260903.md`; referenced bytes not established here)

The same guide gives the exact:

- measure formatting;
- KPI assignments;
- two chart field wells/tooltips;
- Account attention workbench columns;
- replacement Payment & certification detail columns;
- visual filtering and interaction behavior.

### 3. Then run the P04 QA

I also prepared the controlled QA now rather than waiting until the page is finished:

Download the P04 successor QA query (historical reference: `sandbox:[session]/p04_presentation_layer/MSBF_R26_P04_PRESENTATION_QA_R1_20260903.dax`; referenced bytes not established here)

That is **Run only**—never Update model.

It produces seven result sets covering:

1. exact 130-row / 130-key equality across M2.6–M2.10;
2. M2.7 setup distribution;
3. M2.8 execution distribution;
4. M2.9 certification distribution;
5. M2.10 endpoint/servicing disposition;
6. Baseline versus Recession Energy page KPI regression;
7. the five representative physical paths—749, 098, 112, 312, and 264.

## Final intended page bindings after installation

The left KPI stack becomes:

```text
Requiring attention
Attention exposure
Active servicing
Review holds
Certified exposure
Servicing burden
Unresolved exceptions
```

The first chart:

```text
Endpoint monitoring posture

Y-axis   P04 Monitoring Status Label
X-axis   R26 P04 Monitoring Account Count

Tooltips
Exposure
Average remittance pace
```

The second chart:

```text
Servicing disposition

Y-axis   P04 Servicing Queue Label
X-axis   R26 P04 Servicing Account Count

Tooltips
Certified exposure
Servicing burden

Visual filter:
exclude No servicing required
```

This uses the actual M2.10 queue architecture, whose governed categories carry distinct burden and manual-review semantics. [export reference: filecite | turn127file13 | L791-L806]

The workbench becomes:

```text
Merchant
Monitoring status
Remittance pace
Attention exposure
Intervention
Setup state
Execution state
Endpoint state
```

with:

```text
R26 P04 Requires Attention Flag = 1
```

And the old **Payment exception history** is repurposed to:

```text
Payment & certification detail

Merchant
Execution
Payment events
Processed
Return / retry
Reconciliation
Certified on
Certified exposure
```

That lower table is now supported by the actual R1 M2.8/M2.9 carrier rather than pretending we have a successor event-history table with predecessor event dates. M2.8 physically carries payment/return/retry counts and amounts, while M2.9 owns reconciliation and certification. [export reference: filecite | turn125file12 | L1024-L1030] [export reference: filecite | turn125file13 | L1040-L1047]

So the missing P04 DAX handoff is now resolved. **Start with the presentation-layer DAX above; once it compiles and installs, we can go visual-by-visual through P04 without improvising measures as we go.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-590480cb-7aea-409b-b605-329757b8922e"></a>
## Andrew / user · C118-M00080

C118-M00080 · 2026-09-03T21:30:06.341000-04:00 · active path

Preceding visible parent: [C118-M00079](part-05.md#m-63807c7e-ed19-4130-855b-99ca96f2b764)

<!-- BEGIN_SOURCE_MESSAGE -->
the presentation-only calculated columns seem to reference non-R1 Dim tables. Is that accurate?
<!-- END_SOURCE_MESSAGE -->


<a id="m-12c4716e-4032-4c3a-b08a-b1722b216649"></a>
## Assistant · C118-M00081

C118-M00081 · 2026-09-03T21:30:40.615888-04:00 · active path

Preceding visible parent: [C118-M00080](part-05.md#m-590480cb-7aea-409b-b605-329757b8922e)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. As written, the presentation-only columns reference the shared tables:

- `DimMonitoringStatus`
- `DimServicingQueue`

They are **not R1-prefixed**, but they are also **not predecessor-only tables**. In the current C2 source of truth they are retained, current semantic dimensions: `DimMonitoringStatus` is the accepted monitoring-status dictionary, and `DimServicingQueue` is the accepted servicing-queue dictionary with rank/burden/manual-review metadata. [export reference: filecite | turn129file0 | L5-L20] [export reference: filecite | turn129file1 | L27-L39]

So technically, referencing them is valid.

However, given the discipline we established after the P03 issues, I would tighten the design further:

> **Use shared non-R1 dimensions only where they are genuinely the current canonical dimension for an R1 fact. Avoid non-R1 facts entirely when an R1 successor fact exists.**

That means:

- `DimMonitoringStatus` → acceptable as the category dictionary for `R1FactDailyMonitoring[monitoring_status_code]`
- `DimServicingQueue` → acceptable as the category dictionary for `R1FactPortfolioPerformance[servicing_queue_code]`
- old `FactMonitoringEndpoint`, `FactServicingExecution`, `FactPaymentException`, etc. → **not acceptable** for the P04 successor rebase

The R4 register explicitly shows those dimensions are retained current C2 tables, not stale predecessor objects. [export reference: filecite | turn129file0 | L5-L7]

### One correction to my prior wording

I should not have called those calculated columns “R1 presentation columns” without explaining that they sit on **shared canonical dimensions** rather than R1-prefixed tables.

The architecture is:

```text
DimMonitoringStatus
    shared canonical status dictionary
        ↓
R1FactDailyMonitoring[monitoring_status_code]

DimServicingQueue
    shared canonical queue dictionary
        ↓
R1FactPortfolioPerformance[servicing_queue_code]
```

That is a legitimate star-schema pattern.

### Do I recommend changing the plan?

**No, not merely because the dimension names lack `R1`.**

I would keep the three display columns on those two dimensions because that is cleaner than:

- duplicating labels down 15,600 monitoring fact rows;
- creating disconnected P04-only dimension tables;
- or hard-coding category labels directly into every measure.

The important boundary is **semantic authority**, not the presence of `R1` in the table name.

So the corrected rule for P04 is:

> **R1 successor facts for all substantive data; existing shared canonical dimensions are permitted for labels, sorting, and category metadata. No predecessor fact is permitted in the final P04 page.**

That is the standard I would use as we proceed. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-8051558f-e623-4d43-aad3-d6eea04df8a5"></a>
## Andrew / user · C118-M00082

C118-M00082 · 2026-09-03T22:21:53.561000-04:00 · active path

Preceding visible parent: [C118-M00081](part-05.md#m-12c4716e-4032-4c3a-b08a-b1722b216649)

<!-- BEGIN_SOURCE_MESSAGE -->
is it real important to say "Dormant / no remittance" or can we leave it at "Dormant" Or can we have that appear on two lines in the y-axis label for endpoint monitoring posture. how to get it to appear on two lines if that's the direction
<!-- END_SOURCE_MESSAGE -->


<a id="m-ea6c12cd-b2a0-48b1-9ab9-e548bb0e2fbd"></a>
## Assistant · C118-M00083

C118-M00083 · 2026-09-03T22:22:01.841902-04:00 · active path

Preceding visible parent: [C118-M00082](part-05.md#m-8051558f-e623-4d43-aad3-d6eea04df8a5)

<!-- BEGIN_SOURCE_MESSAGE -->
You can shorten it to **“Dormant”** without materially weakening the chart, especially because this is an executive-facing endpoint-status visual and the underlying governed code remains `DORMANT_NO_REMITTANCE`.

My preference would actually be:

> **Dormant**

It is cleaner and avoids overloading a compact Y-axis. The fuller meaning can remain in the tooltip/alt text or underlying status definition.

If you want to preserve the explicit meaning on the axis, use a two-line label:

> **Dormant**  
> **No remittance**

Update the calculated column branch to:

```DAX
"DORMANT_NO_REMITTANCE", "Dormant" & UNICHAR ( 10 ) & "No remittance",
```

Then in the bar chart:

**Format visual → Y-axis → Labels → Word wrap = On**

Power BI usually honors the line break on categorical labels when wrapping is enabled, though rendering can vary slightly with visual width.

For this page, though, I recommend **just “Dormant.”** The chart title already says **Endpoint monitoring posture**, so the concise state label reads more professionally alongside:

- Severe shortfall
- Underperforming
- Watch
- Current
- Paid off
- **Dormant**

That is the cleaner client-facing presentation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-853abe25-6cac-4fe9-b306-df9d365ffbe4"></a>
## Andrew / user · C118-M00084

C118-M00084 · 2026-09-03T22:26:06.887000-04:00 · active path

Preceding visible parent: [C118-M00083](part-05.md#m-ea6c12cd-b2a0-48b1-9ab9-e548bb0e2fbd)

<!-- BEGIN_SOURCE_MESSAGE -->
should I go back to P03 and adjust the Monitoring journey chart label to Dormant or leave it as Dormant / no remittance?
<!-- END_SOURCE_MESSAGE -->


<a id="m-9dce3a94-93e9-4736-bdea-ab497312c8d3"></a>
## Assistant · C118-M00085

C118-M00085 · 2026-09-03T22:26:10.286600-04:00 · active path

Preceding visible parent: [C118-M00084](part-05.md#m-853abe25-6cac-4fe9-b306-df9d365ffbe4)

<!-- BEGIN_SOURCE_MESSAGE -->
Leave P03 as **“Dormant / no remittance.”**

I would intentionally allow the labels to differ slightly by page:

- **P03 Monitoring journey:** `Dormant / no remittance`
- **P04 Endpoint monitoring posture:** `Dormant`

The distinction makes sense because P03 is an **individual-account journey**. There, “no remittance” adds useful explanatory meaning to the state transition and helps a reader understand what Dormant means without consulting documentation.

P04 is a **portfolio-level categorical summary**, where brevity matters more and the Y-axis already has several categories. “Dormant” is sufficient there.

So I would **not reopen frozen P03 for this**. Its current wording is actually preferable for that page's purpose.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2300e7ad-2f0d-4cfd-952d-2ead49083b96"></a>
## Andrew / user · C118-M00086

C118-M00086 · 2026-09-03T22:39:37.245000-04:00 · active path

Preceding visible parent: [C118-M00085](part-05.md#m-9dce3a94-93e9-4736-bdea-ab497312c8d3)

<!-- BEGIN_SOURCE_MESSAGE -->
can we adjust the servicing queue column to have values on two lines? it would help the visual.
<!-- END_SOURCE_MESSAGE -->


<a id="m-878a3581-033e-4c50-80dc-159ffe022181"></a>
## Assistant · C118-M00087

C118-M00087 · 2026-09-03T22:39:40.644092-04:00 · active path

Preceding visible parent: [C118-M00086](part-05.md#m-2300e7ad-2f0d-4cfd-952d-2ead49083b96)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. For P04, I think that is preferable to shortening the queue names because **Active reassessment** and **Governance review hold** carry useful meaning.

Update `DimServicingQueue[P04 Servicing Queue Label]` so the two longer labels contain explicit line breaks:

```DAX
P04 Servicing Queue Label =
VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                'DimServicingQueue'[servicing_queue_code],
                ""
            )
        )
    )
VAR _Fallback =
    SUBSTITUTE ( LOWER ( _Value ), "_", " " )
RETURN
    SWITCH (
        _Value,
        "", BLANK (),

        "NO_SERVICING_REQUIRED",
            "No servicing" & UNICHAR ( 10 ) & "required",

        "ACTIVE_REASSESSMENT",
            "Active" & UNICHAR ( 10 ) & "reassessment",

        "GOVERNANCE_REVIEW_HOLD",
            "Governance" & UNICHAR ( 10 ) & "review hold",

        UPPER ( LEFT ( _Fallback, 1 ) )
            & MID ( _Fallback, 2, LEN ( _Fallback ) )
    )
```

Then set:

**Servicing disposition visual → Format visual → Y-axis → Labels → Word wrap = On**

Keep the existing:

**Sort by column → `servicing_queue_rank`**

For the actual P04 chart, we're excluding **No servicing required**, so the visible labels should render as:

```text
Active
reassessment

Governance
review hold
```

I prefer that to abbreviating them. It preserves the governed business meaning while making much better use of the Y-axis width.
<!-- END_SOURCE_MESSAGE -->


<a id="m-29e12a94-5b6b-4f64-90e7-de3d0c5eb43e"></a>
## Andrew / user · C118-M00088

C118-M00088 · 2026-09-03T22:44:37.037000-04:00 · active path

Preceding visible parent: [C118-M00087](part-05.md#m-878a3581-033e-4c50-80dc-159ffe022181)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 53ca054c-512e-4147-84fa-701eef0fd644.png

<!-- BEGIN_SOURCE_MESSAGE -->
after that change: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-70d3ac96-a9b6-4c54-b2f0-edda36f31dc1"></a>
## Assistant · C118-M00089

C118-M00089 · 2026-09-03T22:44:40.431210-04:00 · active path

Preceding visible parent: [C118-M00088](part-05.md#m-29e12a94-5b6b-4f64-90e7-de3d0c5eb43e)

<!-- BEGIN_SOURCE_MESSAGE -->
That confirms Power BI is **not honoring the embedded `UNICHAR(10)` as a categorical Y-axis line break** in this bar chart. Instead, it is truncating each label with ellipses. So I would undo that approach.

More importantly, I notice a separate problem: **all three bars show 44**. That is not the expected P04 servicing distribution. We should address that before formatting.

For the label issue, revert the display column to ordinary text:

```DAX
P04 Servicing Queue Label =
VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                'DimServicingQueue'[servicing_queue_code],
                ""
            )
        )
    )
VAR _Fallback =
    SUBSTITUTE ( LOWER ( _Value ), "_", " " )
RETURN
    SWITCH (
        _Value,
        "", BLANK (),
        "NO_SERVICING_REQUIRED", "No servicing required",
        "ACTIVE_REASSESSMENT", "Active reassessment",
        "GOVERNANCE_REVIEW_HOLD", "Governance review hold",
        UPPER ( LEFT ( _Fallback, 1 ) )
            & MID ( _Fallback, 2, LEN ( _Fallback ) )
    )
```

For the finished chart, because we planned to exclude `No servicing required`, I would shorten the two actionable labels slightly rather than fight Power BI's axis renderer:

> **Reassessment**  
> **Review hold**

Those are still clear under the chart title **Servicing disposition**, and the full governed queue can remain available in the tooltip/alt text.

But **don't format further yet**. The `44 / 44 / 44` result tells me our new `R26 P04 Servicing Account Count` is not receiving the queue-category context correctly. The intended current R26 distribution is certainly not 44 in every queue.

That is exactly the kind of semantic issue we want to catch before polishing P04. **Next we should correct the Servicing Account Count/category binding**, then return to the label presentation.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fa8e1f55-9bac-426a-a565-5153a5e56542"></a>
## Andrew / user · C118-M00090

C118-M00090 · 2026-09-03T22:53:01.283000-04:00 · active path

Preceding visible parent: [C118-M00089](part-05.md#m-70d3ac96-a9b6-4c54-b2f0-edda36f31dc1)

<!-- BEGIN_SOURCE_MESSAGE -->
even removing the y-axis, the x-axis still shows a bar going to 44 reverting the servicing label variable did not resolve. this is certainly odd. earlier we did have 1/1
<!-- END_SOURCE_MESSAGE -->


<a id="m-7c643132-ce67-47ff-90cf-49855c7e178e"></a>
## Assistant · C118-M00091

C118-M00091 · 2026-09-03T22:53:33.539725-04:00 · active path

Preceding visible parent: [C118-M00090](part-05.md#m-fa8e1f55-9bac-426a-a565-5153a5e56542)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes—**44 is a strong signal that this is not a label-formatting problem at all.** Reverting the display column would never fix it.

And your recollection that the old page showed **1 / 1** is useful: the current visual is almost certainly still bound to the **predecessor `P04 Servicing Account Count`**, or otherwise to a field whose filter context is not the R26 servicing population.

The key point is this:

> With the Y-axis removed, the **new** `R26 P04 Servicing Account Count` should not produce a meaningful aggregate bar at all, because it is intentionally category-dependent. It starts by taking `SELECTEDVALUE(DimServicingQueue[servicing_queue_code])`; without one queue selected, that should be blank.

So if you remove the Y-axis and still get **44**, that makes me suspect the visual's X-axis is **not actually using the new R26 measure** I handed you.

### Please check this first

Select the **Servicing disposition** chart and look at the field well.

The X-axis must say exactly:

```text
R26 P04 Servicing Account Count
```

under `R1Measures`.

It must **not** say:

```text
P04 Servicing Account Count
```

The original P04 visual was indeed bound to the predecessor P04 measure, so this is a very plausible carryover during rebinding. The old page was built on predecessor servicing objects, which is precisely what we're replacing. The canonical register shows the current R1 servicing semantics are based on `R1FactPortfolioPerformance[ApplicationScenarioKey]` and `[servicing_queue_code]`. [export reference: filecite | turn132file0 | L7-L14]

### Quick diagnostic

If the X-axis **does already say** `R26 P04 Servicing Account Count`, do this one test before changing anything else:

Create a temporary table visual with:

```text
DimServicingQueue[servicing_queue_code]
R26 P04 Servicing Account Count
```

No friendly label. No extra visual filters.

Under **Baseline**, the current R26 population should resolve to something structurally like:

```text
NO_SERVICING_REQUIRED       99
ACTIVE_REASSESSMENT          1
GOVERNANCE_REVIEW_HOLD       3
```

—not `44 / 44 / 44`.

If that temporary table also returns 44 for every row, then I will correct the **measure itself**. If it returns the expected queue-specific values, then the defect is isolated to the bar visual's retained filter/binding state, and the cleanest fix will be to rebuild that one chart rather than continue fighting inherited predecessor configuration.

### One thing not to do

Do **not** adjust the queue calculated column again. The label is not causing the 44. `DimServicingQueue` is a legitimate current shared dimension with `servicing_queue_code` and `servicing_queue_rank`; the underlying current R1 fact also owns `servicing_queue_code`. [export reference: filecite | turn132file1 | L26-L34] [export reference: filecite | turn132file0 | L7-L14]

So first confirm the exact X-axis measure name. **If it is already `R26 P04 Servicing Account Count`, run the two-column temporary table test and send me the result.** That will tell us immediately which side of the problem we're on.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5b349e8e-a57d-44cf-bc6d-1124b20c0b3e"></a>
## Andrew / user · C118-M00092

C118-M00092 · 2026-09-03T22:59:34.479000-04:00 · active path

Preceding visible parent: [C118-M00091](part-05.md#m-7c643132-ce67-47ff-90cf-49855c7e178e)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: c93eb611-6401-48f0-a308-d2aa47555dcb.png

<!-- BEGIN_SOURCE_MESSAGE -->
that fixed it. i also reverted to the new service label and it interesting still shows one line but when I hover over it: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-93f5db2b-69f0-4f4d-94f4-64b4f10f7d02"></a>
## Assistant · C118-M00093

C118-M00093 · 2026-09-03T22:59:45.879490-04:00 · active path

Preceding visible parent: [C118-M00092](part-05.md#m-5b349e8e-a57d-44cf-bc6d-1124b20c0b3e)

<!-- BEGIN_SOURCE_MESSAGE -->
Good — the **99 / 1 / 3** result confirms the correct R26 servicing population is now driving the visual.

On the label behavior: Power BI is clearly **storing the full line-break text**, which is why the hover reveals the complete value, but the categorical Y-axis renderer is still collapsing it into a single truncated line. So the `UNICHAR(10)` is present in the data; the axis simply is not honoring it visually.

I would stop trying to force a two-line axis label here. The cleanest client-facing choice is to shorten the displayed labels while preserving the full governed queue meaning elsewhere.

Use:

```DAX
P04 Servicing Queue Label =
VAR _Value =
    UPPER (
        TRIM (
            COALESCE (
                'DimServicingQueue'[servicing_queue_code],
                ""
            )
        )
    )
VAR _Fallback =
    SUBSTITUTE ( LOWER ( _Value ), "_", " " )
RETURN
    SWITCH (
        _Value,
        "", BLANK (),
        "NO_SERVICING_REQUIRED", "No servicing",
        "ACTIVE_REASSESSMENT", "Reassessment",
        "GOVERNANCE_REVIEW_HOLD", "Review hold",
        UPPER ( LEFT ( _Fallback, 1 ) )
            & MID ( _Fallback, 2, LEN ( _Fallback ) )
    )
```

That will give you a much cleaner axis:

- **No servicing**
- **Reassessment**
- **Review hold**

The chart title **Servicing disposition** supplies the context, so these shortened labels remain unambiguous.

For the tooltip, I would keep the **full governed wording** rather than the abbreviated axis label. If we create a tooltip display measure later, it can say:

- No servicing required
- Active reassessment
- Governance review hold

That gives us the best of both worlds: concise axis, precise hover/accessibility text.

Also, the visible 99 / 1 / 3 distribution is exactly the kind of result we wanted this chart to reveal. I would now consider the semantic binding corrected and move on to the next P04 visual.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4f97dcde-cfda-48e6-9c8e-8e4c81963e72"></a>
## Andrew / user · C118-M00094

C118-M00094 · 2026-09-03T23:01:50-04:00 · active path

Preceding visible parent: [C118-M00093](part-05.md#m-93f5db2b-69f0-4f4d-94f4-64b4f10f7d02)

<!-- BEGIN_SOURCE_MESSAGE -->
You say: For the tooltip, I would keep the **full governed wording** rather than the abbreviated axis label. If we create a tooltip display measure later, it can say:   but you do not provide the column for this
<!-- END_SOURCE_MESSAGE -->
