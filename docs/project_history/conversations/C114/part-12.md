# MSBF — Module 1/2 Strategy Correction, Remediation & Republishing Part 2

Part 12 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-11.md)

<a id="m-9a23b78d-f422-4641-a4ed-430613879446"></a>
## Assistant · C114-M00153

C114-M00153 · 2026-09-03T01:26:22.750410-04:00 · active path

Preceding visible parent: [C114-M00152](part-11.md#m-45db2046-5786-4c3d-94b9-64e5fd3cecec)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The Power BI feedback had a point on essentially all nine items. Importantly, these were **presentation-layer defects, not authority/data/strategy defects**. The clean 2 / 0 / 1,500 QA result is strong evidence that the semantic architecture, lifecycle linkage, scenario isolation, and outcome logic were already working correctly. The remaining issues were systematic wording problems in the visible measures. [export reference: filecite | turn65file0 | L352-L512]

I changed the DAX in these specific ways:

- **Relationship-stage grammar:** the old construction built `"This is a " + relationship + size...`, which produced phrases such as **“This is a established returning…”**. I replaced that with explicit natural-language branches: “new…”, “developing…”, “returning … with strong prior performance…”, and “returning … with mixed prior performance…”. The prior construction is visible in the original measure. [export reference: filecite | turn65file0 | L383-L449]
- **Negative observed liquidity:** negative average available liquidity now renders as **“negative at $170”**, using `ABS()` for the displayed dollar amount, instead of `-$170`.
- **NSF wording:** zero now becomes **“No NSF events were observed”**, rather than “0 NSF events.”
- **Zero negative-balance rate:** `0.0%` is suppressed and becomes **“no negative-balance days were observed.”** Positive percentages are retained because they are informative.
- **Business-facing process language:** straight-through approvals now say **“no revised terms or additional review were needed”** instead of the more internal **“no alternative search or manual review was needed.”** The original internal wording was indeed embedded in the approval branch. [export reference: filecite | turn65file0 | L837-L846]
- **Modeled liquidity distinction:** selected-structure liquidity is now explicitly called **“modeled post-financing liquidity,”** distinguishing it from observed pre-decision liquidity.
- **Straight-through approval language:** I removed **“strongest supportable path”** from the approval narrative. The revised decision says the requested terms **“were supportable based on the merchant’s demonstrated capacity and remained within the approved risk, repayment-cost, and economic guardrails.”** The prior phrase appeared in every approval because it was hard-coded into that branch. [export reference: filecite | turn65file0 | L948-L956]
- **Candidate-search detail remains where it belongs:** actual counteroffers, review paths, and no-feasible outcomes retain candidate counts and governed-search explanations. That information is valuable there because alternative evaluation actually occurred. [export reference: filecite | turn65file0 | L847-L896]
- **Technical rationale was left untouched:** `evidence_why_text`, `underwriting_why_text`, and `decision_why_text` still flow directly into their technical-rationale measures without paraphrasing. [export reference: filecite | turn66file0 | L13-L49]

I also agreed with the merchant 749 example conceptually. The distinction it exposed is useful: **observed liquidity** can legitimately be slightly negative while the selected financing structure still produces positive **modeled post-financing liquidity**. Those should not read as if they are the same metric. The updated prose makes that distinction explicit.

So I would characterize the Power BI feedback as a good final editorial review. It did **not** reveal a need to revisit R26, candidate logic, lifecycle facts, or the P03 semantic design. It identified repeatable wording defects that were appropriate to fix centrally in DAX rather than merchant by merchant. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-2c637601-5281-491d-b5a0-a4a711c6fca2"></a>
## Andrew / user · C114-M00154

C114-M00154 · 2026-09-03T07:06:59.801000-04:00 · active path

Preceding visible parent: [C114-M00153](part-12.md#m-9a23b78d-f422-4641-a4ed-430613879446)

**Editorial record note:** Attachment references: MSBF_R26_P03_VISIBLE_NARRATIVE_WORDING_PATCH_R2_20260903(2).dax

<!-- BEGIN_SOURCE_MESSAGE -->
The power bi chat asked for one more minor correction. Please update the attached file (the queries you most recently returned) after factoring in this final power bi feedback: This is now a **clean substantive P03 narrative result**. Your screenshots confirm the corrected QA sequence after the editorial patch:

- **Result 1:** exactly **2 rows** for the 738 Baseline/Recession Energy pair, both `PASS`. 
- **Result 2:** **0 rows**. 
- **Result 3:** **1,500 rows**, and the QA-status filter contains only `PASS`. 

The full inventory also confirms the improved 738 and 749 wording, including correct funding behavior and the revised business-facing approval language. 

The 749 page looks materially better. In particular, observed negative liquidity now reads naturally, the selected structure is explicitly described using **modeled post-financing liquidity**, and the Decision is concise without the old “independent scenario” or “strongest supportable path” language. The same editorial corrections are appearing consistently across the approval population. 

### One small wording defect remains

I would fix **one last systematic presentation issue before freezing the narratives**. There are **12** review cases producing constructions like:

> “A potentially supportable $31,200 alternative was identified, **but the evidence is usable but not strong enough** for straight-through authorization before terms can be authorized.”

The underlying helper itself returns:

> `the evidence is usable but not strong enough for straight-through authorization`

which is fine in isolation. 

The problem is that the Decision measure prepends another **“but”** and appends **“before terms can be authorized”**, producing awkward duplication. The same helper is also inserted after “because” in the Structure Assessment, where it reads correctly. 

So I would **not change the helper**. We should make one narrow change to `R26 P03 Decision Narrative` so review sentences are grammatically assembled around the helper.

For these medium-confidence cases, the target should be:

> **Counteroffer review required. A potentially supportable $31,200 alternative was identified. The evidence is usable but not strong enough for straight-through authorization, so specialist review is required before terms can be authorized. No funding has occurred.**

That is materially cleaner.

There are no remaining instances of the two larger editorial defects we were specifically targeting—`“This is a established returning”` and `“strongest supportable path”` both return zero matches in the new 1,500-row inventory.  

### My disposition

I would record the current state as:

```
```

```
P03 successor authority              PASS
Funded-lifecycle integration         PASS
738 scenario isolation               PASS
Narrative semantic QA                PASS — 2 / 0 / 1,500
Visible editorial R2                 PASS with one minor wording correction
Technical rationale                  PRESERVED
P03 layout                           ACCEPTABLE / substantially complete
P03 freeze                           PENDING final review-wording correction + evidence
```

After that very small correction, I would **stop rewriting the narratives**. The next work should be the final P03 controls: representative seven-outcome visual checks, Technical rationale tooltip, updated C2 footer/identity, alt text, save/close/reopen, and evidence captures. Then P03 can be frozen and we can move to P04.
<!-- END_SOURCE_MESSAGE -->
