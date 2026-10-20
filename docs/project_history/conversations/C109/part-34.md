# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 34 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-33.md)
[Next part](part-35.md)

<a id="m-5756448f-56e6-49c3-8c05-12cc94d98677"></a>
## Assistant · C109-M00747

C109-M00747 · 2026-09-02T15:54:20.444480-04:00 · active path

Preceding visible parent: [C109-M00746](part-33.md#m-c0db7a1a-9c4b-46f3-8666-15ba4e12cebd)

<!-- BEGIN_SOURCE_MESSAGE -->
[export reference: message_reaction | 👍]Yes. With the authority boundary now clear, I would make **two targeted P03 corrections**.

First, the **Funding date** column should no longer depend on `DimAccountAdvance` or any predecessor booking object. Merchant 738 proves why: the predecessor path has no account record, but the corrected R1 successor decision authorizes the requested structure. [export reference: filecite | turn135file0 | L3-L3] The definition should instead be:

> **Funding date = the successor R1 funding/activation date for the selected application-scenario, when that application-scenario has an R1 authorized/funded lifecycle.**

In other words, the date needs to come from the **R1 successor operational/activation chain**, not from the pre-remediation `DimAccountAdvance`.

Given the R1 objects in this model, I would look first at:

`R1FactOperationalSetup`  
then `R1FactServicingExecution`

for the actual successor funding/activation date field. I would **not manufacture the date from the decision date** and I would not use the legacy booking date as a fallback.

So before I give you the final Funding Date DAX, click through those R1 tables in the Data pane and tell me the date-related field names available in `R1FactOperationalSetup`—or send a screenshot of its fields. I expect there is an activation/funding/setup-effective date we can bind to `ApplicationScenarioKey`.

The eventual measure should be structurally like this:

```DAX
R26 P03 Funding Date =
VAR _Authorized =
    [R26 P03 Decision Class] = "AUTHORIZED"

VAR _FundingDate =
    CALCULATE (
        SELECTEDVALUE (
            'R1FactOperationalSetup'[<successor funding/activation date>]
        )
    )

RETURN
    IF (
        _Authorized,
        _FundingDate,
        BLANK ()
    )
```

The important change is **where `_FundingDate` comes from**.

That preserves your desired business rule:

**AUTHORIZED → eligible to display funding date**  
**REVIEW / DECLINED → blank**

while making the physical date itself successor-owned.

Second, the **decision-card color should be completely detached from the old M1/manual-review logic**. Merchant 738 is the perfect proof case. Its corrected R1 outcome is `APPROVE_AS_REQUESTED_AUTHORIZED`, no human review, `ALL_MANDATORY_GATES_PASS`, and `SUPPORTED_STRUCTURE`. [export reference: filecite | turn135file0 | L3-L3] Therefore its card must be green regardless of the predecessor `manual_review_recommended_flag`.

Use the corrected final decision class as the sole color authority:

```DAX
R26 P03 Decision Tile Background =
SWITCH (
    [R26 P03 Decision Class],
    "AUTHORIZED", "#E8F5E9",
    "REVIEW",     "#FFF4D6",
    "DECLINED",   "#FDECEC",
    "#F3F4F6"
)
```

And for the decision text:

```DAX
R26 P03 Decision Tile Value Color =
SWITCH (
    [R26 P03 Decision Class],
    "AUTHORIZED", "#1B5E20",
    "REVIEW",     "#8A5A00",
    "DECLINED",   "#B71C1C",
    "#374151"
)
```

If you already have established green/amber/red shades elsewhere on P03/P04, use those exact colors instead; the semantic rule is what matters.

Then bind **both** the upper Decision Class card and lower Decision Label card to those same two measures:

**Background → fx → Field value → `R26 P03 Decision Tile Background`**

**Callout/value color → fx → Field value → `R26 P03 Decision Tile Value Color`**

Do not let either visual use `manual_review_recommended_flag`, `verification_disposition`, old `FactFinalDecision`, or funding presence to determine color.

That produces the correct version-aware behavior:

**738 / Baseline:** green → `AUTHORIZED / Approved as requested`  
**738 / Recession Energy:** red → `DECLINED / Evidence decline` because R1 explicitly gives `DECLINE_INSUFFICIENT_EVIDENCE`. [export reference: filecite | turn135file0 | L4-L4]

So I would fix the **color logic now**, and then identify the exact successor date field in `R1FactOperationalSetup` before touching Funding Date. That avoids another legacy-source fallback.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3d7f6aa5-b3f1-4cf4-9088-8f73f82d400a"></a>
## Andrew / user · C109-M00748

C109-M00748 · 2026-09-02T15:58:16.435000-04:00 · active path

Preceding visible parent: [C109-M00747](part-34.md#m-5756448f-56e6-49c3-8c05-12cc94d98677)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 83f29a44-cce7-4e47-adc9-fc39175e5017.png; 8e55808d-1430-4d01-baa9-e7c4c4faea9e.png

<!-- BEGIN_SOURCE_MESSAGE -->
as requested, but didn't the handoff provide a complete mapping...
<!-- END_SOURCE_MESSAGE -->


<a id="m-e632268b-0524-4989-8738-f32b072cf7b3"></a>
## Assistant · C109-M00749

C109-M00749 · 2026-09-02T15:59:36.032479-04:00 · active path

Preceding visible parent: [C109-M00748](part-34.md#m-3d7f6aa5-b3f1-4cf4-9088-8f73f82d400a)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The handoff/repository material did provide much more of this mapping than I was using a moment ago.

The important pieces we can now ground are:

- `R1FactOperationalSetup` is a successor R17-derived object with **130 rows / 33 fields**, keyed to `R1DimApplicationScenario` by `ApplicationScenarioKey`. Its mapped fields explicitly include `setup_authorized_flag`, `setup_review_required_flag`, `no_setup_required_flag`, **`operational_activation_date`**, and `next_reassessment_date`. [export reference: filecite | turn136file2 | L51-L52]
- `R1FactServicingExecution` is likewise part of the same successor operational chain and relates many-to-one to `R1DimApplicationScenario` through `ApplicationScenarioKey`. [export reference: filecite | turn136file7 | L228-L247]
- The R26 handoff specifically instructed us to preserve the unchanged R1 operational facts from `R1FactIntervention` through `R1FactPortfolioPerformance`; the R26 changes were concentrated elsewhere, especially monitoring/M2.11–M2.12. [export reference: filecite | turn136file0 | L11-L15]

So for **P03 Funding date**, we do not need to improvise. The mapped successor field that most naturally corresponds to the date the authorized structure entered the operational lifecycle is:

`R1FactOperationalSetup[operational_activation_date]`

That is materially better than using predecessor `DimAccountAdvance`.

And because `R1FactOperationalSetup` has only **130 rows**, it is clearly not a generic 1,500-row decision table; it is a downstream population representing paths that reached operational setup. [export reference: filecite | turn136file5 | L100-L126] That lines up with what we need for a funding/activation date.

So I would now define the P03 field semantically as:

> **Funding date = `operational_activation_date` from the R1 operational-setup record for the selected ApplicationScenarioKey, displayed only when the R1 final decision class is AUTHORIZED.**

That gives us the corrected version-2 chain:

`R1FactFinalDecision` → whether the path is AUTHORIZED  
`R1FactOperationalSetup` → when that authorized path actually activated

For 738 / Baseline, if an R1 operational-setup row exists, we should expect that activation date to populate even though predecessor `DimAccountAdvance` has no record.

And on the color side, the same mapping principle applies: **decision-card color should follow the R1 final-decision class, not predecessor review/funding state**. The R1 row for 738 / Baseline explicitly says `APPROVE_AS_REQUESTED_AUTHORIZED`, `human_review_required_flag = false`, and all mandatory gates pass. [export reference: filecite | turn135file0 | L3-L3]

So yes: the handoff already gave us enough structure to stop hunting ad hoc across the model. From here I would treat the successor mapping as the authority map and update P03 against that systematically.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2f2f0fa7-ce18-4938-84f6-866c5830eb5a"></a>
## Andrew / user · C109-M00750

C109-M00750 · 2026-09-02T16:02:58.058000-04:00 · alternate branch

Preceding visible parent: [C109-M00749](part-34.md#m-e632268b-0524-4989-8738-f32b072cf7b3)

<!-- BEGIN_SOURCE_MESSAGE -->
thank you.  please re-provide complete P03 instructions using the successor mapping as the authority. please instruct any DAX updates as necessary vs what you previously provided for P03. This has been an entirely inefficient P03 update so far. This is also the second time you've failed to utilize the successor mapping. This also happened after the first handoff from the remediation/correction chat. The handoffs were provided so that you would have everything needed for a successful build and you have repeatedly ignored that and caused expensive circling. Let's make sure we do this right and do not make mistakes or choose inefficient paths.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9579c3e8-c0ba-4025-8a15-e3aeb148c040"></a>
## Assistant · C109-M00751

C109-M00751 · 2026-09-02T16:09:12.784920-04:00 · alternate branch

Preceding visible parent: [C109-M00750](part-34.md#m-2f2f0fa7-ce18-4938-84f6-866c5830eb5a)

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-301bff71-1287-4822-9e4e-e75680cba887"></a>
## Andrew / user · C109-M00752

C109-M00752 · 2026-09-02T16:34:30.074000-04:00 · active path

Preceding visible parent: [C109-M00749](part-34.md#m-e632268b-0524-4989-8738-f32b072cf7b3)

<!-- BEGIN_SOURCE_MESSAGE -->
thank you.  please re-provide complete P03 instructions using the successor mapping as the authority. please instruct any DAX updates as necessary vs what you previously provided for P03. This has been an entirely inefficient P03 update so far. This is also the second time you've failed to utilize the successor mapping. This also happened after the first handoff from the remediation/correction chat. The handoffs were provided so that you would have everything needed for a successful build and you have repeatedly ignored that and caused expensive circling. Let's make sure we do this right and do not make mistakes or choose inefficient paths.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5551d59b-7f23-448a-b2b5-91b709e7cdf2"></a>
## Assistant · C109-M00753

C109-M00753 · 2026-09-02T16:35:38.154196-04:00 · active path

Preceding visible parent: [C109-M00752](part-34.md#m-301bff71-1287-4822-9e4e-e75680cba887)

<!-- BEGIN_SOURCE_MESSAGE -->
You are right to call out the inefficiency. The successor handoff explicitly told us to use the supplied inventories and source-owned chain rather than rediscovering or mixing predecessor objects, and I failed to enforce that boundary consistently on P03. The corrected approach below starts from the successor mapping and treats the old objects only as immutable request/profile context where the R1 successor does not replace them. The governing chain is explicitly **request → candidate search → selected structure → final decision → funding/activation → monitoring/intervention → operational setup/servicing → account certification**, and DAX is allowed to present/aggregate those governed facts but not reconstruct the strategy. [export reference: filecite | turn137file0 | L82-L103]

The most important authority rule for P03 is now:

**R1DimApplicationScenario = decision-time request/profile context; R1FactFinalDecision = corrected final decision + proposed structure + final explanations; R1FactOperationalSetup = successor activation; R1FactDailyMonitoring = lifecycle; R1FactIntervention/R1FactServicingExecution = servicing.** The successor data dictionary explicitly assigns those purposes and grains. [export reference: filecite | turn137file8 | L444-L468]

## Complete P03 successor-authority implementation

1. **First, freeze the authority map before touching visuals.**

   Use these sources and **do not fall back to their predecessor equivalents**:

   | P03 content | Authority |
   |---|---|
   | Merchant/application identity | existing immutable core identity where needed |
   | Scenario, industry, size, relationship, channel | `R1DimApplicationScenario` |
   | Requested economics | `R1DimApplicationScenario` |
   | Decision class/label | `R1FactFinalDecision[governed_final_outcome_code]` |
   | Proposed structure | `R1FactFinalDecision[governed_selected_*]` |
   | Evidence/assessment context | R1 successor measures / R1 objects only |
   | Final recommendation | `R1FactFinalDecision[decision_why_text]` plus source-owned search summary |
   | Funding date | `R1FactOperationalSetup[operational_activation_date]` |
   | Account performance | `R1FactDailyMonitoring` |
   | Monitoring journey | `R1FactDailyMonitoring` |
   | Servicing recommendation | `R1FactIntervention` |
   | Operational setup | `R1FactOperationalSetup` |
   | Servicing execution | `R1FactServicingExecution` |

   `R1FactFinalDecision` is one row per `ApplicationScenarioKey`; `R1FactOperationalSetup`, `R1FactIntervention`, and `R1FactServicingExecution` are also successor objects at that grain, while monitoring is `ApplicationScenarioKey × monitoring_day_index`. [export reference: filecite | turn137file6 | L294-L353]

   **Do not use on P03 for successor-state displays:**
   - `FactApplicationScenario`
   - `FactFinalDecision`
   - `DimAccountAdvance`
   - `FactBookingActivation`
   - other predecessor M2 facts

   Merchant 000738 is now our regression case demonstrating why.

2. **Merchant request — finish the clean request row.**

   Final visible order:

   **Applied | Requested | Use | Channel | Remittance | Payback multiple | Payoff days | Repayment**

   Remove `Application`; one application per merchant makes it redundant in this portfolio.

   Bind the economic fields to:

   - Requested → `R1DimApplicationScenario[requested_amount]`
   - Channel → `R1DimApplicationScenario[channel_type]`
   - Remittance → `R1DimApplicationScenario[requested_remittance_rate]`
   - Payback multiple → `R1DimApplicationScenario[requested_payback_multiple]`
   - Payoff days → `R1DimApplicationScenario[requested_horizon_days]`
   - Repayment → `R1DimApplicationScenario[requested_total_repayment_amount]`

   These are explicitly source-owned Request fields in the successor metadata. [export reference: filecite | turn138file0 | L39-L52]

   Keep **Applied** and **Use** from the immutable application source already used on P03 if R1 does not supply them. Those facts were not changed by the Module 2 remediation.

   Format:
   - Requested `$#,0.00`
   - Remittance `0.00%`
   - Payback multiple `0.00`
   - Payoff days `0`
   - Repayment `$#,0.00`

   Keep the existing Merchant-request alt text, updated to:

   > Application request details for the selected merchant and scenario, including application date, requested amount, use, channel, remittance rate, requested payback multiple, requested payoff period, and requested repayment.

3. **Replace Decision Class and Decision Label with exact-key R1 measures.**

   We already removed the predecessor fallback, but I want to make these **ApplicationScenarioKey-explicit** so there is no ambiguity from relationship context.

   Full replacement for Decision Class:

```DAX
R26 P03 Decision Class =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
VAR _Outcome =
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_final_outcome_code]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
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
```

   Full replacement for Decision Label:

```DAX
R26 P03 Decision Label =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
VAR _Outcome =
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_final_outcome_code]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
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
```

   Do **not** put any `COALESCE` fallback to `FactFinalDecision`, `FactApplicationScenario`, or `R1DimApplicationScenario[governed_final_outcome_code]` back into these measures.

4. **Replace the decision-card colors so they follow the same R1 final decision.**

   This fixes the 000738 yellow/green inconsistency.

```DAX
R26 P03 Decision Tile Background =
SWITCH (
    [R26 P03 Decision Class],
    "AUTHORIZED", "#2E7D32",
    "REVIEW",     "#C58A00",
    "DECLINED",   "#C62828",
    "#D9D9D9"
)
```

```DAX
R26 P03 Decision Tile Value Color =
SWITCH (
    [R26 P03 Decision Class],
    "AUTHORIZED", "#FFFFFF",
    "REVIEW",     "#FFFFFF",
    "DECLINED",   "#FFFFFF",
    "#374151"
)
```

   Apply both the upper Class card and lower Label card to these measures:

   **Format visual → Background → fx → Field value → `R26 P03 Decision Tile Background`**

   and, if value color is conditional:

   **Value/Callout value → Color → fx → Field value → `R26 P03 Decision Tile Value Color`**

   Keep **Uniform padding = 0**, which solved your label truncation.

5. **Proposed structure — rebuild entirely from R1FactFinalDecision.**

   Keep the heading:

   **Proposed structure**

   Final visible columns:

   **Amount | Remittance | Payback multiple | Horizon days | Repayment | Funding date**

   Replace any current proposed-structure measures that use R1Dim or legacy fields with these full replacements:

```DAX
R26 P03 Selected Structure Amount =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_selected_funding_amount]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

```DAX
R26 P03 Selected Remittance Rate =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_selected_remittance_rate]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

```DAX
R26 P03 Selected Payback Multiple =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_selected_payback_multiple]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

```DAX
R26 P03 Selected Horizon Days =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_selected_horizon_days]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

```DAX
R26 P03 Selected Total Repayment =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[governed_selected_total_repayment_amount]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

   This is aligned directly with the handoff definition that `R1FactFinalDecision` owns the **governed final decision and selected structure**. [export reference: filecite | turn137file8 | L448-L457]

   Format:
   - Amount `$#,0.00`
   - Remittance `0.00%`
   - Payback `0.00`
   - Horizon `0`
   - Repayment `$#,0.00`

6. **Replace Funding date with R1 operational activation.**

   This is the key correction from the 000738 investigation.

   `R1FactOperationalSetup` explicitly contains `operational_activation_date`, is successor R17 evidence, is keyed by `ApplicationScenarioKey`, and has 130 rows—the funded/operational population. [export reference: filecite | turn136file2 | L51-L52]

   Full replacement:

```DAX
R26 P03 Funding Date =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
VAR _Authorized =
    [R26 P03 Decision Class] = "AUTHORIZED"
VAR _ActivationDate =
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactOperationalSetup'[operational_activation_date]
            ),
            TREATAS (
                { _Key },
                'R1FactOperationalSetup'[ApplicationScenarioKey]
            )
        )
    )
RETURN
    IF (
        _Authorized,
        _ActivationDate,
        BLANK ()
    )
```

   Use this measure in the sixth column.

   Do **not** use:
   - `DimAccountAdvance`
   - predecessor booking activation
   - a calculated date based on decision date
   - fallback dates

   Executive label can remain **Funding date** even though the physical source is operational activation.

7. **Replace Funded Lifecycle Available with the successor operational population.**

   This should not be inferred from the old account table.

```DAX
R26 P03 Funded Lifecycle Available =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
VAR _OperationalRows =
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            COUNTROWS (
                'R1FactOperationalSetup'
            ),
            TREATAS (
                { _Key },
                'R1FactOperationalSetup'[ApplicationScenarioKey]
            )
        )
    )
RETURN
    IF (
        COALESCE ( _OperationalRows, 0 ) > 0,
        1,
        0
    )
```

   That becomes the single control for whether P03 should expose downstream funded-account lifecycle content.

8. **Finish Proposed structure alt text.**

   Full replacement:

```DAX
R26 P03 Proposed Structure Alt Text =
VAR _Amount =
    [R26 P03 Selected Structure Amount]
VAR _FundingDate =
    [R26 P03 Funding Date]
RETURN
    IF (
        ISBLANK ( _Amount ),
        "No proposed structure is available for the selected merchant and scenario.",
        "Proposed structure for the selected merchant and scenario: amount "
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
            & " days, and repayment "
            & FORMAT (
                [R26 P03 Selected Total Repayment],
                "$#,0.00"
            )
            & IF (
                NOT ISBLANK ( _FundingDate ),
                ". Funding date "
                    & FORMAT ( _FundingDate, "mmmm d, yyyy" )
                    & ".",
                ". No funding date is present for this decision."
            )
    )
```

   Bind through:

   **Format visual → General → Alt text → fx → Field value → `R26 P03 Proposed Structure Alt Text`**

9. **Narrative section — freeze the three-block architecture but clean its authority.**

   Final headings:

   **Merchant operating evidence**  
   **Risk & economics assessment**  
   **Recommendation**

   Do not add a fourth Structure Search block.

   For the first two blocks, keep your existing detailed `R26 P03 Evidence Narrative` and `R26 P03 Underwriting Narrative` **only because they were designed from R1 successor decision-time facts**. They must not contain references to `FactApplicationScenario` or old `FactFinalDecision`.

   For **Recommendation**, replace any legacy narrative measure with an exact R1 final-decision version:

```DAX
R26 P03 Decision Narrative =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[decision_why_text]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

   Then use `R26 P03 Decision Narrative` in the visible **Recommendation** block.

   This is the specific correction that prevents the predecessor 000738 “manual authorization” story from surviving after R1 changed the final outcome.

   For candidate-search context, use it as a **tooltip on Recommendation**, not as another visible block. Keep your existing `R26 P03 Candidate Search Summary` there. This keeps the page architecture clean:

   **Evidence → Assessment → Recommendation**

   while still making governed search depth available to an analyst.

10. **Account performance — keep the R26 successor implementation; remove all legacy fields.**

   Use:

   - X-axis → `R1FactDailyMonitoring[monitoring_date]`
   - Primary Y → `R26 P03 Remaining Receivable`
   - Secondary Y → `R26 P03 Remittance Pace`

   Tooltip:

   - `R26 P03 Monitoring Status Display`
   - `R26 P03 Remitted To Date`
   - `R26 P03 Cumulative Shortfall`
   - `R26 P03 Operational Alert Families`
   - `R26 P03 Raw Alert Conditions`

   Keep the subtitle:

   - funded lifecycle → **Funded synthetic account • deterministic synthetic-forward**
   - no lifecycle → **No funded-account lifecycle for this application-scenario**

   `R1FactDailyMonitoring` is the successor daily lifecycle fact; R26 expanded it to 47 columns but preserved its role and grain. [export reference: filecite | turn137file6 | L316-L334]

   Do not use any fields from old `FactAccountDaily` or `FactMonitoringEndpoint`.

11. **Monitoring journey — keep the successor-only version.**

   X-axis:

   `R1FactDailyMonitoring[monitoring_date]`

   Y-axis:

   `R26 P03 Monitoring Status Rank`

   Y-axis range:

   `0` to `5`

   Visible hierarchy:

   - 5 Dormant / no remittance
   - 4 Severe shortfall
   - 3 Underperforming
   - 2 Watch
   - 1 Current
   - 0 Paid off

   Tooltip:

   - Monitoring status
   - Remaining receivable
   - Remittance pace
   - Operational alert families
   - Raw alert conditions

   Keep `R26 P03 Monitoring Journey Subtitle` and its alt-text measure.

   Do not use the deprecated pre-R26 diagnostic/watch measures on the production P03 page.

12. **Servicing & intervention — use the R1 successor operational chain only.**

   Final visible columns:

   **Intervention | Action | Queue | Exposure | Reason**

   Use the measures already created:

   - `R26 P03 Intervention Display`
   - `R26 P03 Servicing Action Display`
   - `R26 P03 Servicing Queue Display`
   - `R26 P03 Intervention Exposure`
   - `R26 P03 Intervention Reason Display`

   These should resolve respectively from:

   - recommendation → `R1FactIntervention`
   - operational setup → `R1FactOperationalSetup`
   - execution → `R1FactServicingExecution`

   Do not rebind this block to old `FactIntervention` or `FactServicingExecution`.

   `R1FactOperationalSetup` and `R1FactServicingExecution` both have explicit `ApplicationScenarioKey` relationships to `R1DimApplicationScenario`, so these are the intended successor joins. [export reference: filecite | turn136file7 | L228-L247]

   Correct behavior:
   - funded/active path → servicing state as applicable
   - funded/closed path → e.g. `No further action / No action — closed / Closed / $0.00 / Paid off`
   - non-funded path → **blank**, not a fabricated “No action”

13. **Update the footer identity completely.**

   Replace the stale P03 footer with the same identity pattern already frozen on P01/P02:

   **Run:** `M1_V0_2_BASELINE_BUILD`  
   **Source release:** `Module 2 / G3 v2.1.0-rc2`  
   **Model version:** `PBI_R26_PARALLEL_REFINEMENT_C1_20260902`  
   **Observed-source cutoff:** `2026-07-23`

   Temporal boundary:

   > **Temporal boundary:** Decision and proposed-structure evidence is fixed at the 2026-07-23 source snapshot. Funded-account lifecycle evidence is deterministic synthetic-forward through 2026-11-22.

   Interpretation boundary:

   > **Interpretation boundary:** Synthetic decision and lifecycle evidence; review or decline paths do not imply funding or account creation.

14. **Interactions — make them deterministic and simple.**

   Merchant and Scenario slicers should **Filter** every dynamic P03 component:

   - merchant profile
   - Merchant request
   - decision tile
   - Proposed structure
   - all three narrative blocks
   - Account performance
   - Monitoring journey
   - Servicing & intervention

   Do not let charts cross-filter or cross-highlight other P03 visuals. Slicers establish the application-scenario context; visuals should present that context rather than create new one.

15. **Final physical regression set before freezing P03.**

   Do not randomly click merchants. Use deliberately selected outcome cases.

   At minimum, validate:

   - `000738 / Baseline`
     - **AUTHORIZED**
     - **Approved as requested**
     - green tile
     - requested economics = proposed economics
     - Recommendation = R1 authorization narrative
     - Funding date from `R1FactOperationalSetup[operational_activation_date]`
     - funded lifecycle populated

   - `000738 / Recession Energy`
     - **DECLINED**
     - **Evidence decline**
     - red tile
     - no proposed structure
     - no funding date
     - evidence-availability narrative
     - no funded lifecycle

   - one clean `COUNTEROFFER_AUTHORIZED`
   - one `COUNTEROFFER_REVIEW_REQUIRED`
   - one `MANUAL_UNDERWRITING_REVIEW_REQUIRED`
   - one `DECLINE_NO_FEASIBLE_STRUCTURE`
   - one `DECLINE_POLICY_HARD_STOP`

   We already have the full 1,500-row outcome extract, so **I will select those canonical evidence merchants from that file rather than making you run another broad query**.

The important non-regression rule from this point forward is: **P03 successor-state visuals may not use predecessor Module 2 facts merely because those tables remain present in the semantic model.** The handoff intentionally preserved both the old report-facing model and the R1 successor objects; the successor mapping exists precisely to prevent version mixing. The handoff even states that the inventories are supplied and should be used instead of manually rediscovering objects. [export reference: filecite | turn137file0 | L31-L55]

If you follow the sequence above, the next physical checkpoint should be **000738 / Baseline first**. That one case will simultaneously validate the corrected decision authority, color authority, narrative authority, proposed-structure authority, activation date, and downstream lifecycle boundary.
<!-- END_SOURCE_MESSAGE -->


<a id="m-59ab4286-899c-4609-adbf-869c6e0972f0"></a>
## Andrew / user · C109-M00754

C109-M00754 · 2026-09-02T18:47:49.243000-04:00 · active path

Preceding visible parent: [C109-M00753](part-34.md#m-5551d59b-7f23-448a-b2b5-91b709e7cdf2)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 6909c76a-813f-4666-9485-f171cdb395f3.png

<!-- BEGIN_SOURCE_MESSAGE -->
funding date is flawed, and I wonder if it's related to activation date. when i add activation date, two records gets linked. one with a date and one without:
<!-- END_SOURCE_MESSAGE -->


<a id="m-eefdfb5e-3b6b-42ba-a2c1-673d3133f038"></a>
## Assistant · C109-M00755

C109-M00755 · 2026-09-02T18:47:58.581859-04:00 · active path

Preceding visible parent: [C109-M00754](part-34.md#m-59ab4286-899c-4609-adbf-869c6e0972f0)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The screenshot tells us the current Funding Date measure is failing for a specific reason: **`R1FactOperationalSetup[operational_activation_date]` is not resolving to a single value in the current P03 context.**

That is why the measure is blank. When you add the raw `operational_activation_date` column to the table, Power BI splits the visual into two contexts—one with a blank date and one with `7/24/2026`—and suddenly the measure can resolve on the dated row.

So **do not change the measure again yet**, and do not leave the raw activation-date field in the production visual. We first need to determine whether:

- `R1FactOperationalSetup` physically has two records for 738/Baseline, or
- the P03 slicer/filter context is allowing another application-scenario row into the visual.

The successor contract says `R1FactOperationalSetup` is intended at `ApplicationScenarioKey` grain and relates to `R1DimApplicationScenario` on that exact key. [export reference: filecite | turn137file6 | L336-L353] That means two values for the selected application-scenario require explanation rather than another DAX workaround.

### Run this one DAX Studio diagnostic

Paste this exactly:

```DAX
EVALUATE

FILTER (
    SELECTCOLUMNS (
        'R1FactOperationalSetup',

        "ApplicationScenarioKey",
            'R1FactOperationalSetup'[ApplicationScenarioKey],

        "Merchant Application",
            'R1FactOperationalSetup'[merchant_application_id],

        "Merchant",
            'R1FactOperationalSetup'[merchant_id],

        "Scenario",
            'R1FactOperationalSetup'[scenario_code],

        "Synthetic Account",
            'R1FactOperationalSetup'[synthetic_account_id],

        "Synthetic Advance",
            'R1FactOperationalSetup'[synthetic_advance_id],

        "Source Strategy Outcome",
            'R1FactOperationalSetup'[source_strategy_outcome_code],

        "Source Servicing Action",
            'R1FactOperationalSetup'[source_servicing_action_code],

        "Setup Outcome",
            'R1FactOperationalSetup'[operational_setup_outcome_code],

        "Setup Action",
            'R1FactOperationalSetup'[operational_setup_action_code],

        "Account Setup Status",
            'R1FactOperationalSetup'[account_setup_status_code],

        "Setup Authorized",
            'R1FactOperationalSetup'[setup_authorized_flag],

        "Setup Review Required",
            'R1FactOperationalSetup'[setup_review_required_flag],

        "No Setup Required",
            'R1FactOperationalSetup'[no_setup_required_flag],

        "Activation Date",
            'R1FactOperationalSetup'[operational_activation_date],

        "Next Reassessment",
            'R1FactOperationalSetup'[next_reassessment_date],

        "R1 Source Boundary",
            'R1FactOperationalSetup'[R1SourceBoundary]
    ),

    [Merchant Application]
        = "MSBF_POP_0001_M000738_A01"
)

ORDER BY
    [Scenario],
    [Activation Date]
```

Return the result exactly as shown.

### What I expect this to tell us

There are two materially different possibilities.

**A. One Baseline row + one Recession Energy row**

Then the physical successor table is fine. The problem is **P03 scenario isolation**: the old Scenario slicer is not properly filtering `R1FactOperationalSetup`, which would also explain why adding the raw date produces two rows.

If that is the result, we will fix the P03 successor measures so every R1 object is explicitly keyed to the exact selected `ApplicationScenarioKey`. That is a model/display-context issue.

**B. Two Baseline rows for the same `ApplicationScenarioKey`**

Then we have something different: the operational-setup table contains multiple physical states for what the catalog describes as application-scenario grain. We would need to understand their setup statuses before defining “Funding date.” In that case, `SELECTEDVALUE` is correctly refusing to choose between them.

### One immediate cleanup

For now, remove the raw:

`R1FactOperationalSetup[operational_activation_date]`

from the **Proposed structure** table again.

Leave only our `R26 P03 Funding Date` measure. It will remain blank temporarily for 738, which is preferable to showing two rows.

Also, I can already see one other item in your screenshot that we should **not fix piecemeal yet**: your Recommendation still says:

> “A reduced structure was identified, but governance requires manual authorization…”

That is predecessor/remediation leakage for 738/Baseline, because the R1 final-decision source says the requested structure was authorized without a counteroffer. We will correct Recommendation from the same exact `ApplicationScenarioKey` authority once this diagnostic establishes whether the shared root cause is scenario/key isolation.

So the next action is only the diagnostic above. No more visual changes until we see those rows.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c6175762-df24-4641-8cfc-8b22d32daafb"></a>
## Andrew / user · C109-M00756

C109-M00756 · 2026-09-02T18:49:56.734000-04:00 · active path

Preceding visible parent: [C109-M00755](part-34.md#m-eefdfb5e-3b6b-42ba-a2c1-673d3133f038)

<!-- BEGIN_SOURCE_MESSAGE -->
[ApplicationScenarioKey]	[Merchant Application]	[Merchant]	[Scenario]	[Synthetic Account]	[Synthetic Advance]	[Source Strategy Outcome]	[Source Servicing Action]	[Setup Outcome]	[Setup Action]	[Account Setup Status]	[Setup Authorized]	[Setup Review Required]	[No Setup Required]	[Activation Date]	[Next Reassessment]	[R1 Source Boundary]
1|5|MSBF_POP_0001_M000738_A01	MSBF_POP_0001_M000738_A01	MSBF_POP_0001_M000738	BASELINE	MSBF_ACCT_0D774156345F8F6CA079	MSBF_ADV_299BEA5F5E18435185A9	CLOSED_NO_FURTHER_ACTION	NO_ACTION_CLOSED	NO_OPERATIONAL_SETUP_REQUIRED	CLOSE_WITHOUT_SETUP	NOT_REQUIRED	f	f	t			R17
<!-- END_SOURCE_MESSAGE -->


<a id="m-5d97106a-bd5c-4d1e-b028-3095f0dfc102"></a>
## Assistant · C109-M00757

C109-M00757 · 2026-09-02T18:51:00.598354-04:00 · active path

Preceding visible parent: [C109-M00756](part-34.md#m-c6175762-df24-4641-8cfc-8b22d32daafb)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. This diagnostic resolves the ambiguity cleanly:

**738 / Baseline has exactly one `R1FactOperationalSetup` row, and its `operational_activation_date` is blank because this row is `NO_OPERATIONAL_SETUP_REQUIRED / CLOSE_WITHOUT_SETUP / NOT_REQUIRED`.** So my prior mapping of P03 **Funding date → `R1FactOperationalSetup[operational_activation_date]` was wrong.** That field is a later **M2.7 operational-setup activation date**, not the original funding date. The M2.7 schema itself requires `operational_activation_date` only when an operational setup blueprint is ready; it must be null when setup is not required. [export reference: filecite | turn139file2 | L41-L49] [export reference: filecite | turn139file2 | L82-L96]

The proper funding-date source is upstream in the funded lifecycle chain. The accepted M2.5 monitoring source explicitly carries `funding_date`, `portfolio_activation_date`, `monitoring_start_date`, and funded terms from the M2.4 activation source. [export reference: filecite | turn141file0 | L11-L35] The M2.4 contract also defines `funding_date` separately from booking, portfolio activation, and monitoring start, with validated date ordering. [export reference: filecite | turn141file3 | L337-L344]

So we should now define P03 Funding date from the **R1 funded-lifecycle evidence**, not M2.7.

### Next efficient step

Check whether `R1FactDailyMonitoring` in your current model exposes a `funding_date` column. The raw R17 M2.5 source definitely contains it; the only question is whether the curated Power BI table retained it. [export reference: filecite | turn141file1 | L125-L150]

In the Data pane:

1. Expand **R1FactDailyMonitoring**.
2. Search within its fields for:
   - `funding_date`
   - `portfolio_activation_date`
   - `monitoring_start_date`
3. Tell me whether `funding_date` is present.

If it **is present**, the final measure should be:

```DAX
R26 P03 Funding Date =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        [R26 P03 Decision Class] = "AUTHORIZED"
            && NOT ISBLANK ( _Key ),
        CALCULATE (
            MIN (
                'R1FactDailyMonitoring'[funding_date]
            ),
            TREATAS (
                { _Key },
                'R1FactDailyMonitoring'[ApplicationScenarioKey]
            ),
            REMOVEFILTERS (
                'R1FactDailyMonitoring'[monitoring_date]
            )
        )
    )
```

That is semantically correct because the funded monitoring population is already the successor-funded cohort; P01 itself uses the presence of an `ApplicationScenarioKey` in `R1FactDailyMonitoring` as the funded-path definition. [export reference: filecite | turn140file1 | L136-L180]

If `funding_date` is **not exposed** in the curated table, we should not infer it from `monitoring_date` or M2.7 activation. We would instead add that already-source-owned field from the exact R17 M2.5 source into `R1FactDailyMonitoring` Power Query. That would be a bounded semantic exposure change, not reconstructed logic.

Also: your result proves there was **not** a duplicate-row problem in `R1FactOperationalSetup`. The two rows you saw in the visual occurred because adding the raw activation-date field changed the visual grain/context, not because 738 physically has two setup records.

So the correction is now precise:

**Funding date authority = M2.4 funding date carried into the R1 funded lifecycle / M2.5 source.**  
**Operational activation date = M2.7 servicing/setup activation and must not be used as funding date.**

That distinction should now stay fixed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-1fb17a48-1cb3-4d34-bedb-d0ca9b17449c"></a>
## Andrew / user · C109-M00758

C109-M00758 · 2026-09-02T18:53:38.158000-04:00 · active path

Preceding visible parent: [C109-M00757](part-34.md#m-5d97106a-bd5c-4d1e-b028-3095f0dfc102)

**Editorial record note:** 2 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 0a841554-bab4-40d3-b1d5-1c78557cdd23.png; d2272181-7517-4276-80c5-a2254c81d544.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-1fdf120e-22a4-4cc4-88be-b795eced4608"></a>
## Assistant · C109-M00759

C109-M00759 · 2026-09-02T18:54:17.125513-04:00 · active path

Preceding visible parent: [C109-M00758](part-34.md#m-1fb17a48-1cb3-4d34-bedb-d0ca9b17449c)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct — your screenshots confirm `R1FactDailyMonitoring` does **not** expose `funding_date`. The successor catalog confirms that the curated R1 monitoring table intentionally retained 36 fields, and `funding_date` is not among them. [export reference: filecite | turn143file3 | L109-L110]

So we should **not** try to solve Funding date with DAX against the current semantic model, and we should **not** use `operational_activation_date` as a substitute.

The source hierarchy is now clear:

- M2.4 owns the actual **booking / funding / portfolio activation dates**. `funding_date` is a distinct physical field. [export reference: filecite | turn141file2 | L211-L259]
- M2.5 consumes that funded population and also physically carries `funding_date`. [export reference: filecite | turn141file0 | L11-L35]
- But the curated `R1FactDailyMonitoring` projection omitted it.
- M2.7 `operational_activation_date` is a later servicing/setup concept and can legitimately be null for a funded account when no operational setup is required. [export reference: filecite | turn139file2 | L82-L96]

### What I recommend for P03 now

**Do not add another DAX workaround.**

For the current P03 refinement, I would temporarily remove the **Funding date** column from `Proposed structure`.

Why? Because the correct successor funding date exists physically upstream, but it is **not currently exposed through any of the approved R1 semantic objects we have identified**. Creating an inferred value would violate the source-owned-chain rule.

Also, I do **not** recommend adding `funding_date` directly into `R1FactDailyMonitoring` right now. R26's physical checkpoint is explicitly **47 columns** after adding the 11 monitoring-calibration fields to the original 36. Adding a 48th column would alter that audited model/source identity and unnecessarily reopen the R26 monitoring rebase.

So the efficient, governed treatment is:

> **Remove Funding date from the visible P03 Proposed structure table for this candidate.**

The table becomes:

**Amount | Remittance | Payback multiple | Horizon days | Repayment**

That is still complete for the purpose of explaining the proposed/authorized economics.

### Why this is preferable to creating a new lookup table

We could technically add another hidden Power Query lookup against the M2.4/M2.5 raw source, but that would:

- add another semantic object,
- change model inventory,
- require relationship and refresh validation,
- create an additional R22/R26 candidate delta,
- and solve only one presentation field.

That is disproportionate to the executive value of displaying a funding date on P03.

If later we decide Funding date is materially important, the right future implementation is a **controlled successor-semantic exposure of the M2.4 funding/activation facts**, not a P03-specific workaround.

### One correction to the earlier P03 instructions

Please supersede these prior instructions:

- **delete `R26 P03 Funding Date` from the model** once no other visual/measure depends on it;
- remove Funding date from `R26 P03 Proposed Structure Alt Text`;
- Proposed structure should have **five columns**, not six;
- do not use `R1FactOperationalSetup[operational_activation_date]` anywhere as a funding-date proxy.

Use this alt text instead:

```DAX
R26 P03 Proposed Structure Alt Text =
VAR _Amount =
    [R26 P03 Selected Structure Amount]
RETURN
    IF (
        ISBLANK ( _Amount ),
        "No proposed structure is available for the selected merchant and scenario.",
        "Proposed structure for the selected merchant and scenario: amount "
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
            & " days, and repayment "
            & FORMAT (
                [R26 P03 Selected Total Repayment],
                "$#,0.00"
            )
            & "."
    )
```

One additional point from this investigation: **funded lifecycle availability should continue to come from membership in the R1 monitoring/funded population**, not from M2.7 operational setup status. P01 already uses `R1FactDailyMonitoring[ApplicationScenarioKey]` as the funded-path population. [export reference: filecite | turn140file1 | L136-L180]

So I would also revise the earlier `R26 P03 Funded Lifecycle Available` measure to use `R1FactDailyMonitoring`, not `R1FactOperationalSetup`:

```DAX
R26 P03 Funded Lifecycle Available =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
VAR _MonitoringRows =
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            COUNTROWS (
                'R1FactDailyMonitoring'
            ),
            TREATAS (
                { _Key },
                'R1FactDailyMonitoring'[ApplicationScenarioKey]
            ),
            REMOVEFILTERS (
                'R1FactDailyMonitoring'[monitoring_date]
            )
        )
    )
RETURN
    IF (
        COALESCE ( _MonitoringRows, 0 ) > 0,
        1,
        0
    )
```

That is the important correction from this discovery:

**Decision authority → `R1FactFinalDecision`**  
**Funded lifecycle membership → `R1FactDailyMonitoring`**  
**Operational servicing/setup → `R1FactOperationalSetup`**  
**Funding date → physically exists upstream but is not exposed in the current curated R1 semantic model; therefore do not fabricate it.**

I would make those two corrections—remove Funding date and replace Funded Lifecycle Available—before proceeding with the rest of P03.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d9d96724-20ec-4750-b25b-217fd6a6b452"></a>
## Andrew / user · C109-M00760

C109-M00760 · 2026-09-02T19:14:12.289000-04:00 · active path

Preceding visible parent: [C109-M00759](part-34.md#m-1fdf120e-22a4-4cc4-88be-b795eced4608)

<!-- BEGIN_SOURCE_MESSAGE -->
from our remediation/correction chat: Yes. I found the issue, and it is a **carrier/source-layer omission, not a missing funding date**.

For newly authorized R1 paths such as application **738**, the Power BI chat should **not look to the old/pre-R1 M2.4/public activation population**. In the predecessor strategy, Baseline 738 was only `COUNTEROFFER_REVIEW_REQUIRED`, so it correctly had no booking/funding record there.  After the R1 corrections, that same Baseline application became `APPROVE_AS_REQUESTED_AUTHORIZED` for the requested **$25,000 / 60-day** structure. 

### Exact answer for application 738

For:

```
```

```
ApplicationScenarioKey
1|5|MSBF_POP_0001_M000738_A01

Scenario
BASELINE
```

the lifecycle dates are:

```
```

```
Application as-of date          2026-07-23
Booking date                    2026-07-24
Funding date                    2026-07-25
Portfolio activation date       2026-07-25
Monitoring start date           2026-07-25
First expected remittance       2026-07-26
```

This follows the governed R1 M2.4 timing:

```
```

```
booking lag             +1 day
funding lag             +2 days
first remittance lag    +3 days
monitoring start lag    +2 days
```

Those exact lag values are physically governed in M2.4.  And the generation SQL explicitly calculates funding as `as_of_date + funding_lag_days`, first expected remittance as `as_of_date + first_remittance_lag_days`, etc. 

So **738 Baseline funded on July 25, 2026**.

For the same merchant application under:

```
```

```
1|6|MSBF_POP_0001_M000738_A01
RECESSION_ENERGY
```

there is **no funding date**, because that R1 scenario remains a decline. Do not let a merchant-level lookup propagate the Baseline funding date into the Recession Energy row.

## Why Power BI is having difficulty

The current successor carrier is rich in R4 decision facts and R26 monitoring facts, but the curated Power BI monitoring table does **not carry** **`funding_date`**.

That date exists upstream in the R1 activation layer. In fact, the R17/R26 M2.5 source construction explicitly consumes:

```
```

```
funding_date
portfolio_activation_date
monitoring_start_date
first_expected_remittance_date
```

from the R1 M2.4 activated advance/portfolio objects. 

So the date wasn't lost in the strategy. **We omitted the lifecycle-date fields from the Power BI carrier projection.**

## What I recommend the Power BI chat do

Do **not** solve this with a one-off DAX inference such as:

```
```

```
Funding Date = First Monitoring Date - 1
```

Although that gives the right answer under the current M2.4 policy, it makes Power BI reconstruct source-owned lifecycle semantics.

Instead, the R26 integration candidate should add a small **source-owned funded-lifecycle object at** **`ApplicationScenarioKey`** **grain**, something like:

```
```

```
R1FactFundedLifecycle
```

with:

```
```

```
ApplicationScenarioKey
scenario_id
scenario_code
merchant_application_id

synthetic_account_id
synthetic_advance_id

booking_date
funding_date
portfolio_activation_date
monitoring_start_date
first_expected_remittance_date

funded_amount
collection_horizon_days

R1SourceBoundary
R1SourceArtifactSha256
R1AuthorityState
```

Its authoritative source should be the exact R1 M2.4 objects retained in the immutable R6 lineage:

```
```

```
msbf_m2.application_booking_funding_activation_latest
msbf_m2.synthetic_advance_funding
msbf_m2.initial_portfolio_activation
```

M2.5 itself already selects the accepted M2.4 activated population and carries the advance funding date forward.  

### Important grain rule

The lifecycle table must be keyed by:

```
```

```
ApplicationScenarioKey
```

**not** by merchant/application alone.

That matters precisely for 738:

```
```

```
738 + BASELINE           funded 2026-07-25
738 + RECESSION_ENERGY   not funded / BLANK
```

## Paste this to the Power BI chat

> **Funding-date source correction:** Do not use the predecessor M2.4/public activation population to obtain lifecycle dates for newly authorized R1 paths. Those paths did not have predecessor funding records. The accepted R1 M2.4 R6 activation layer is the lifecycle-date authority consumed by R17/R26 M2.5.
>
> For `1|5|MSBF_POP_0001_M000738_A01` (Baseline), R4 now has `APPROVE_AS_REQUESTED_AUTHORIZED`, selected funding `$25,000`, horizon `60`. Its application as-of date is `2026-07-23`. Governed M2.4 lags are booking +1, funding +2, first expected remittance +3, monitoring start +2; therefore exact lifecycle dates are booking `2026-07-24`, funding/activation/monitoring start `2026-07-25`, first expected remittance `2026-07-26`. The Recession Energy 738 path is not funded and must remain blank.
>
> Treat the absence of `funding_date` from the current R26 Power BI carrier as an **integration-carrier omission**, not as missing source authority. Add a source-owned `ApplicationScenarioKey`-grain funded-lifecycle table/fields from the exact R1 M2.4 activation objects. Do not reconstruct funding dates in report DAX and do not join at merchant-only grain. Preserve this addition in the R26 Power BI integration delta for the bounded integration audit.

I would have the Power BI chat make this correction **across all 130 funded scenario paths**, not just patch 738. That gives P02/P04/P06 a proper lifecycle-date authority and prevents the same problem from resurfacing on every path newly funded under R1.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c47b9a9b-892f-4b92-82f1-973e76da448d"></a>
## Assistant · C109-M00761

C109-M00761 · 2026-09-02T19:14:38.208745-04:00 · active path

Preceding visible parent: [C109-M00760](part-34.md#m-d9d96724-20ec-4750-b25b-217fd6a6b452)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. This materially supersedes my prior recommendation to remove Funding date. The remediation/correction chat has now given us the missing authority boundary and the correct integration design.

The right conclusion is:

**Funding date is valid and should remain on P03. The defect is that the R26 Power BI carrier omitted the corrected R1 funded-lifecycle projection.** We should repair the carrier/model once for all 130 funded application-scenario paths, not patch merchant 738 and not alter the audited 47-column R26 monitoring table.

That is also consistent with the original handoff’s source-owned chain: final decision → funding/activation → monitoring/intervention. [export reference: filecite | turn140file0 | L82-L103]

## Corrected implementation plan

### 1. Do not modify `R1FactDailyMonitoring`

Leave it at the R26-certified:

**15,600 rows / 47 columns**

Do not add `funding_date` as a 48th column. R26 explicitly changed that table from 36 to 47 columns through the eleven monitoring fields. [export reference: filecite | turn145file7 | L184-L205]

Instead, add the missing bounded lifecycle object:

**`R1FactFundedLifecycle`**

at exactly:

**one row per funded `ApplicationScenarioKey`**

Expected population:

**130 rows**

This is the cleanest architecture.

---

### 2. Source it from the R1 M2.4 lifecycle authority, not predecessor M2.4

This distinction is critical.

Do **not** use the old core:

- `FactBookingActivation`
- `DimAccountAdvance`
- predecessor `application_booking_funding_activation_latest`

because newly authorized R1 paths such as 738 did not exist as funded paths in that predecessor state.

The lifecycle source must correspond to the **R1-remediated M2.4 population feeding R17 M2.5**.

The underlying M2.4 contract contains the exact source-owned fields we need:

- `booking_date`
- `funding_date`
- `portfolio_activation_date`
- `monitoring_start_date`
- `first_expected_remittance_date`
- `funded_amount`
- synthetic account/advance identity

and explicitly distinguishes all of these dates. [export reference: filecite | turn141file2 | L211-L259]

The downstream M2.5 construction already consumes and preserves `funding_date` and the other activation dates from that accepted M2.4 population, so we are exposing existing source truth—not calculating new lifecycle semantics. [export reference: filecite | turn141file0 | L11-L35]

---

### 3. Physical shape of `R1FactFundedLifecycle`

I would use exactly this compact schema:

```text
module1_run_id
scenario_id
scenario_code
merchant_application_id
merchant_id
population_id

synthetic_account_id
synthetic_advance_id

booking_date
funding_date
portfolio_activation_date
monitoring_start_date
first_expected_remittance_date

funded_amount
collection_horizon_days

ApplicationKey
RunScenarioKey
ApplicationScenarioKey
AccountKey
AdvanceKey

R1SourceBoundary
R1SourceArtifactSha256
R1AuthorityState
```

No monitoring metrics. No decision reconstruction. No policy logic.

This object answers one narrow question:

> **What funded lifecycle was physically established for this R1 application-scenario?**

---

### 4. Do not derive the 130 rows from report DAX

We can use source data that already carries these values, but the transformation should occur **once in the carrier/integration layer**, not independently in each measure.

Since the existing raw R17 M2.5 source physically contains `funding_date` and related lifecycle fields but the curated projection omitted them, there are two defensible ways to construct the new carrier object:

**Preferred:** export the exact funded lifecycle from the retained R1 M2.4 authority.

**Acceptable if it is the exact R17 source copy of those M2.4 values:** produce a one-row-per-`ApplicationScenarioKey` lifecycle projection from the R17 source that already carries the M2.4 dates.

Either way, the resulting 130-row table must reconcile exactly to the 130 funded keys already represented by `R1FactDailyMonitoring`.

We should **not manually calculate**:

`funding_date = as_of_date + 2`

even though that happens to be the current governed lag.

---

## 5. Relationship in Power BI

After `R1FactFundedLifecycle` is loaded, create:

```text
R1DimApplicationScenario[ApplicationScenarioKey]
        1
        ↓
        *
R1FactFundedLifecycle[ApplicationScenarioKey]
```

Settings:

- Cardinality: **One to many**
- Cross-filter direction: **Single**
- Active: **Yes**

Do not relate it by merchant ID.

Do not relate it by application ID alone.

Merchant 738 proves why scenario identity is indispensable:

```text
1|5|...738...   Baseline          funded
1|6|...738...   Recession Energy  not funded
```

---

## 6. Replace `R26 P03 Funded Lifecycle Available`

My most recent monitoring-population version is still usable conceptually, but once we deliberately add the lifecycle authority, the cleaner definition should use that table directly.

Full replacement:

```DAX
R26 P03 Funded Lifecycle Available =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
VAR _LifecycleRows =
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            COUNTROWS (
                'R1FactFundedLifecycle'
            ),
            TREATAS (
                { _Key },
                'R1FactFundedLifecycle'[ApplicationScenarioKey]
            )
        )
    )
RETURN
    IF (
        COALESCE ( _LifecycleRows, 0 ) = 1,
        1,
        0
    )
```

Because the lifecycle table is supposed to be unique at application-scenario grain, I prefer `= 1` rather than `> 0`. A duplicate should not silently pass.

---

## 7. Replace Funding Date with the actual lifecycle field

Full replacement:

```DAX
R26 P03 Funding Date =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        [R26 P03 Funded Lifecycle Available] = 1
            && NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFundedLifecycle'[funding_date]
            ),
            TREATAS (
                { _Key },
                'R1FactFundedLifecycle'[ApplicationScenarioKey]
            )
        )
    )
```

Notice the improvement from our earlier rule.

We no longer say merely:

> AUTHORIZED → date.

We say:

> **A physical R1 funded-lifecycle row exists → display its source-owned funding date.**

That is stronger because it distinguishes final decision from actual funded lifecycle using their proper source layers.

---

## 8. Keep Funding date in Proposed structure

Final P03 table:

**Amount | Remittance | Payback multiple | Horizon days | Repayment | Funding date**

Expected 738 behavior:

**738 / Baseline**

```text
AUTHORIZED
Approved as requested

Amount               $25,000.00
Remittance                13.40%
Payback multiple             1.21
Horizon days                  60
Repayment              $30,209.08
Funding date           7/25/2026
```

**738 / Recession Energy**

```text
DECLINED
Evidence decline

Proposed structure      blank
Funding date            blank
```

There must be no merchant-level leakage from Baseline into Recession Energy.

---

## 9. Restore Funding date to Proposed-structure alt text

Use:

```DAX
R26 P03 Proposed Structure Alt Text =
VAR _Amount =
    [R26 P03 Selected Structure Amount]
VAR _FundingDate =
    [R26 P03 Funding Date]
RETURN
    IF (
        ISBLANK ( _Amount ),
        "No proposed structure is available for the selected merchant and scenario.",
        "Proposed structure for the selected merchant and scenario: amount "
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
            & " days, and repayment "
            & FORMAT (
                [R26 P03 Selected Total Repayment],
                "$#,0.00"
            )
            & IF (
                NOT ISBLANK ( _FundingDate ),
                ". Funding date "
                    & FORMAT ( _FundingDate, "mmmm d, yyyy" )
                    & ".",
                ". This proposed structure does not have a funded lifecycle."
            )
    )
```

---

## 10. Keep the decision-card correction

Nothing in the remediation answer changes our decision-tile conclusion.

Final decision authority remains:

**`R1FactFinalDecision[governed_final_outcome_code]`**

For 738 / Baseline that successor row is `APPROVE_AS_REQUESTED_AUTHORIZED`; the R1 decision row explicitly says no human review and that all mandatory gates pass. [export reference: filecite | turn135file0 | L3-L3]

So the decision card must use:

```DAX
R26 P03 Decision Tile Background =
SWITCH (
    [R26 P03 Decision Class],
    "AUTHORIZED", "#2E7D32",
    "REVIEW",     "#C58A00",
    "DECLINED",   "#C62828",
    "#D9D9D9"
)
```

The old M1/manual-review recommendation cannot control the final decision tile.

---

## 11. Recommendation remains an R1 final-decision narrative

This correction also confirms that the current visible 738 Recommendation:

> “A reduced structure was identified, but governance requires manual authorization…”

is wrong for the R1 successor page.

Use only:

```DAX
R26 P03 Decision Narrative =
VAR _Key =
    SELECTEDVALUE (
        'R1DimApplicationScenario'[ApplicationScenarioKey]
    )
RETURN
    IF (
        NOT ISBLANK ( _Key ),
        CALCULATE (
            SELECTEDVALUE (
                'R1FactFinalDecision'[decision_why_text]
            ),
            TREATAS (
                { _Key },
                'R1FactFinalDecision'[ApplicationScenarioKey]
            )
        )
    )
```

For 738 / Baseline the R1 source narrative is the authorization-as-requested story, not the predecessor manual-review story. [export reference: filecite | turn135file0 | L3-L3]

---

## 12. What changes in the R26 integration inventory

This is not an R26 monitoring-source mutation.

Record it as a bounded additive integration delta:

```text
New semantic object:
R1FactFundedLifecycle

Rows:
130

Grain:
ApplicationScenarioKey

Authority:
Exact R1 M2.4 lifecycle facts consumed by R17/R26 downstream chain

Purpose:
Expose omitted source-owned funded lifecycle identity and dates

R1FactDailyMonitoring:
UNCHANGED — 15,600 rows / 47 columns

Decision logic:
UNCHANGED

Monitoring policy:
UNCHANGED

R26 certification:
UNCHANGED

Publication:
NOT AUTHORIZED
```

This is precisely the kind of **version-separated Power BI integration delta** contemplated by the R26 acceptance boundary: R26 technical acceptance does not itself update Power BI; the integration candidate must be built separately and reviewed. [export reference: filecite | turn136file12 | L417-L426]

### The next efficient move

I would **not continue formatting P03 yet**. The next action should be to construct and load `R1FactFundedLifecycle` for all 130 funded application-scenario paths, validate its uniqueness and 738 dates, and only then return to the P03 visual.

Once that table physically exists, the rest of the P03 corrections become straightforward instead of continuing to work around an incomplete carrier.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b3123996-5855-4301-9422-adadde1f55a7"></a>
## Andrew / user · C109-M00762

C109-M00762 · 2026-09-02T19:19:00.186000-04:00 · active path

Preceding visible parent: [C109-M00761](part-34.md#m-c47b9a9b-892f-4b92-82f1-973e76da448d)

<!-- BEGIN_SOURCE_MESSAGE -->
your instructions are appreciated, but I need a bit more detail on how to do some of the steps. please be explicit.
<!-- END_SOURCE_MESSAGE -->
