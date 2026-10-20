# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 18 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-17.md)
[Next part](part-19.md)

<a id="m-4cc94bb2-0534-40e5-9a82-72f451fa5e1e"></a>
## Assistant · C109-M00479

C109-M00479 · 2026-08-27T12:50:29.891733-04:00 · active path

Preceding visible parent: [C109-M00478](part-17.md#m-8201fece-242c-47c2-9f38-8dcdef225aa3)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — and your proposed layout is exactly how I would do it. **Do not create a separate titled “Decision profile” block.** Make it visually read as the second row of the existing **Merchant request** section.

I dug into the actual governed decision chain before recommending the fields. The documentation materially changes our initial conceptual list.

The critical finding is that M2.1 explicitly governs **12 gates**: contract evidence, data confidence, verification, fraud, processor, capacity, affordability, resilience, risk, economics, hard stop, and acquisition evidence. A failing gate routes to decline; blocked evidence routes to insufficient evidence if no failure exists; review gates route to manual review; and only an all-pass row becomes eligible for offer design. [export reference: filecite | turn54file6 | L542-L568]

Then M2.2 performs structure/pricing work, and M2.3 consumes the accepted M2.1 eligibility/routing, accepted M2.2 requested/pricing structures, selected-candidate lineage/reasons, and matched scenario evidence to authorize the final outcome. [export reference: filecite | turn53file5 | L408-L428]

So we **can** make P03 explain underwriting rather than merely display some correlated risk metrics.

## What I would show

Given your available width, I would target **seven columns** in the second row:

**Eligibility | Capacity | Affordability | Resilience | Risk | Economics | Decision reason**

That is better than my original conceptual list.

Why no separate Exposure/Loss columns initially? Because those concepts are already incorporated into the governed affordability/risk/economics/structure process, and we have limited space. More importantly, the project explicitly warns that these concepts are analytically separate and that no one measure should be treated as a proxy for another. [export reference: filecite | turn53file4 | L357-L377]

The last column — **Decision reason** — is especially important. It connects the metrics/gates to the outcome instead of forcing an interviewer to infer causality.

### The intended P03 top section becomes

```text
Merchant request
Application | Applied | Requested | Use | Channel | Remittance | Payoff days | Repayment
A01         | ...     | ...       | ... | ...     | ...        | ...         | ...

Eligibility | Capacity | Affordability | Resilience | Risk | Economics | Decision reason
Eligible    | Pass     | Pass          | Pass       | Pass | Pass      | Final offer ready
```

Then immediately below:

**APPROVED / Final offer**

and beside/below that:

**Funded terms**

That is an extremely compact underwriting narrative.

## Why Decision reason matters

The final-decision contract itself defines the outcomes precisely:

- **Final offer** — structure ready and synthetic final offer authorized.
- **Counteroffer review** — a counteroffer foundation exists, but manual authorization remains required.
- **Evidence decline** — governed evidence is insufficient.
- **Policy decline** — governed policy constraints prohibit a structure. [export reference: filecite | turn53file1 | L96-L101]

And the reason mapping preserves the upstream lineage: accepted M2.2 pricing structure → final offer; M2.2 policy decline → policy decline; M2.2 insufficient evidence → evidence decline. [export reference: filecite | turn53file0 | L49-L63]

That is exactly what we want P03 to expose.

### One nuance about counteroffers

We should continue calling the P03 outcome **Counteroffer review**, not simply Counteroffer. The governing documentation explicitly says this is **not an issued customer counteroffer**; it is a foundation requiring manual authorization. [export reference: filecite | turn53file3 | L273-L291]

That's an important interview-quality distinction.

---

# Before we create a single DAX object

Now we need to map those seven concepts to the **physical semantic model you actually have in Power BI**.

I don't want to repeat the mistake of guessing field names or creating unnecessary measures.

Please expand and send me screenshots of the fields in these visible/hidden tables, if they exist:

1. **`FactApplicationScenario`**
2. **`FactFinalDecision`**
3. Any table with **Eligibility** in its name.
4. Any table with **Pricing**, **Structure**, or **Candidate** in its name.

From your earlier Fields screenshot, I know `FactApplicationScenario` and `FactFinalDecision` exist. Start with **`FactApplicationScenario`** — expand it and send me the complete field list.

I suspect that table may already contain much of the application/scenario underwriting profile we need.

Once we inspect the physical fields, I'll map each proposed P03 column to its **actual governed source**, explicitly tell you **COLUMN vs MEASURE**, and we'll build the one-row second table directly beneath Merchant request.

And if the semantic model doesn't expose one of these seven concepts cleanly, we **won't manufacture it** just to fill the row. That's the discipline that will make this enhancement credible in an interview. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e6187ef3-67f9-4484-bc9e-ffc52c6d5f62"></a>
## Andrew / user · C109-M00480

C109-M00480 · 2026-08-27T12:51:50.930000-04:00 · active path

Preceding visible parent: [C109-M00479](part-18.md#m-4cc94bb2-0534-40e5-9a82-72f451fa5e1e)

<!-- BEGIN_SOURCE_MESSAGE -->
So you are recommending just a Pass or Not for each of those columns? Instead of the underlying economics?
<!-- END_SOURCE_MESSAGE -->


<a id="m-50ddbf2b-fa49-4eb4-8e41-e276c9bfbfe5"></a>
## Assistant · C109-M00481

C109-M00481 · 2026-08-27T12:52:00.714413-04:00 · active path

Preceding visible parent: [C109-M00480](part-18.md#m-e6187ef3-67f9-4484-bc9e-ffc52c6d5f62)

<!-- BEGIN_SOURCE_MESSAGE -->
No — I would **not** reduce the entire row to Pass/Fail. That would throw away the most interesting part of the underwriting story.

I would use a **hybrid design**:

- show the **underlying decision metric/value** where the model exposes a meaningful quantitative measure;
- show a **governed status/tier** where the concept is inherently categorical;
- use the **decision reason** to connect those inputs to the final outcome.

For example, instead of:

**Capacity = Pass**

I would much rather show something like:

**Capacity = $X residual capacity**  
or  
**Affordability = Y% PTI**

if those are the actual governed inputs.

Likewise:

- **Resilience** → actual resilience tier/score if available
- **Risk** → integrated risk tier/proxy
- **Economics** → actual contribution / unit-economic metric if used at that stage
- **Eligibility** → this one may appropriately be `Eligible / Review / Blocked / Decline`
- **Decision reason** → plain-English governed reason

That gives the interviewer something concrete to discuss.

The ideal row is therefore more like:

| Eligibility | Capacity | Affordability | Resilience | Risk | Economics | Decision reason |
|---|---:|---:|---|---|---:|---|
| Eligible | $42.6K residual | 8.4% PTI | Strong | Tier 2 | $1.8K contribution | Final offer ready |

For a decline, maybe:

| Eligibility | Capacity | Affordability | Resilience | Risk | Economics | Decision reason |
|---|---:|---:|---|---|---:|---|
| Decline | $9.3K residual | 17.8% PTI | Moderate | Tier 4 | $420 contribution | Policy constraint |

The exact fields depend on what the semantic model actually exposes, and we should not invent numbers or use descriptive metrics that were not truly part of the decision chain.

So the design principle is:

> **Show the actual governed input first; show Pass/Fail only when the gate status itself is the meaningful decision evidence.**

That is a much stronger interview story because you can say, “Here are the actual underwriting inputs, and here is how the policy layer interpreted them.”

Next I would inspect `FactApplicationScenario` and the eligibility/pricing facts specifically looking for those **underlying quantitative fields**, not just gate flags.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9d792d31-c12e-4bb1-af4e-bf0c96a2c2e3"></a>
## Andrew / user · C109-M00482

C109-M00482 · 2026-08-27T12:52:53.343000-04:00 · active path

Preceding visible parent: [C109-M00481](part-18.md#m-50ddbf2b-fa49-4eb4-8e41-e276c9bfbfe5)

<!-- BEGIN_SOURCE_MESSAGE -->
what about showing the underlying economics but then have an interpretation column that calls out the fail reason(s)
<!-- END_SOURCE_MESSAGE -->


<a id="m-d1561500-652c-4108-a24b-37cf682c4829"></a>
## Assistant · C109-M00483

C109-M00483 · 2026-08-27T12:53:04.826280-04:00 · active path

Preceding visible parent: [C109-M00482](part-18.md#m-9d792d31-c12e-4bb1-af4e-bf0c96a2c2e3)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I think that is the better design.

Instead of spending several columns on separate Pass/Fail gate states, use the row to show the **actual underwriting economics/risk inputs**, then add one compact **Interpretation** column that explains which governed condition actually drove the outcome.

That gives you both sides of the story:

> **What did the applicant look like quantitatively?**  
> **How did policy interpret those values?**

For example, the row could become:

| Capacity | Affordability | Resilience | Risk | Expected loss | Economics | Interpretation |
|---|---:|---|---|---|---:|---|
| $42.6K residual | 8.4% PTI | Strong | Tier 2 | 3.1% | $1.8K contribution | All eligibility gates satisfied; final offer authorized |

For a decline:

| Capacity | Affordability | Resilience | Risk | Expected loss | Economics | Interpretation |
|---|---:|---|---|---|---:|---|
| $8.7K residual | 19.2% PTI | Moderate | Tier 4 | 8.7% | $390 contribution | Policy decline — affordability/risk threshold exceeded |

And for insufficient evidence:

> `Insufficient evidence — required verification/data-confidence gate blocked decisioning.`

That is much more useful in an interview because you can explain the **actual credit/economic profile** first and then point to the governed policy interpretation.

The documentation supports that architecture. M2.1 evaluates separate gates for capacity, affordability, resilience, risk, economics, evidence, fraud, processor continuity and other controls; failures, blocked evidence and review states then follow explicit routing precedence. [export reference: filecite | turn54file6 | L547-L568] The project also explicitly warns that these analytical concepts are distinct and shouldn't be substituted for one another. [export reference: filecite | turn53file4 | L357-L377]

I would therefore revise the planned second Merchant Request row to something like:

**Capacity | Affordability | Resilience | Risk | Expected loss | Economics | Interpretation**

I particularly like **Expected loss** here because it gives the risk metric some economic consequence rather than showing only a risk tier. The Module 2 decision logic explicitly uses requested Expected Loss, PTI, risk and exposure constraints in routing/structure decisions. [export reference: filecite | turn54file7 | L605-L633]

The **Interpretation** field should not be free-form commentary we invent in DAX. It should be built from the governed eligibility/pricing/final-decision reason fields so that it can say things such as:

- `Eligible — all gates passed`
- `Counteroffer review — reduced structure requires authorization`
- `Policy decline — <governed primary reason>`
- `Evidence decline — <governed blocked-evidence reason>`

That distinction is important: the quantitative columns explain the profile; **Interpretation explains the actual decision logic**.

So yes — I prefer this substantially over seven Pass/Fail columns.

Next, let's inspect the physical semantic fields and identify the best actual measures for those six quantitative/profile columns plus the governed reason field. Start with `FactApplicationScenario`, and then we'll trace into the M2.1/M2.2 facts only where needed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-089ff5f9-9f73-44aa-abec-ca4b100839a6"></a>
## Andrew / user · C109-M00484

C109-M00484 · 2026-08-27T12:53:59.140000-04:00 · active path

Preceding visible parent: [C109-M00483](part-18.md#m-d1561500-652c-4108-a24b-37cf682c4829)

<!-- BEGIN_SOURCE_MESSAGE -->
and we do not need to restate policy decline etc in that interpretation because we have that green/yellow/red card doing that - Just say "affordability/risk threshold exceeded"
<!-- END_SOURCE_MESSAGE -->


<a id="m-21aec657-3ebf-4c58-9b4d-2a83b1c02750"></a>
## Assistant · C109-M00485

C109-M00485 · 2026-08-27T12:54:01.235424-04:00 · active path

Preceding visible parent: [C109-M00484](part-18.md#m-089ff5f9-9f73-44aa-abec-ca4b100839a6)

<!-- BEGIN_SOURCE_MESSAGE -->
Exactly. **The Interpretation field should explain the driver, not repeat the disposition.**

The decision cards already answer:

**What happened?**  
`APPROVED` / `REVIEW` / `DECLINED`  
`Final offer` / `Counteroffer review` / `Policy decline` / `Evidence decline`

The new underwriting row should answer:

**Why?**

So good Interpretation values would be things like:

- `All eligibility gates satisfied`
- `Affordability threshold exceeded`
- `Risk threshold exceeded`
- `Affordability / risk thresholds exceeded`
- `Required evidence insufficient`
- `Reduced structure requires review`
- `Hard-stop policy condition triggered`
- `Processor continuity evidence insufficient`

That creates a clean division of responsibility:

**Underlying metrics** → what the merchant/application looked like  
**Interpretation** → what mattered in policy  
**Decision card** → what the resulting disposition was

I would therefore target this second row:

**Capacity | Affordability | Resilience | Risk | Expected loss | Economics | Interpretation**

And importantly, **Interpretation must come from the actual governed gate/reason evidence**, not from us looking at the numbers and inventing an explanation afterward. M2.1 already preserves a primary reason and reason array for every routed application, and the gate/routing hierarchy explicitly distinguishes failure, blocked evidence, review and all-pass outcomes. [export reference: filecite | turn54file6 | L547-L568]

That's exactly the architecture I would want in an interview: the user can see the numbers and the governed explanation side-by-side without redundant decision labeling.

Now we should inspect the physical semantic tables to identify the actual fields for those seven columns.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2743411e-d0b2-4046-8db4-735876024cd5"></a>
## Andrew / user · C109-M00486

C109-M00486 · 2026-08-27T12:55:28.527000-04:00 · active path

Preceding visible parent: [C109-M00485](part-18.md#m-21aec657-3ebf-4c58-9b4d-2a83b1c02750)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 21486ea8-076d-43fa-888c-fc3b7f4abead.png

<!-- BEGIN_SOURCE_MESSAGE -->
which tables do you want to see (Note, DimAccountAdvance is not shown in this screenshot, but also exists)
<!-- END_SOURCE_MESSAGE -->


<a id="m-55c0a9a0-70d3-40f0-972e-2b652a13a36d"></a>
## Assistant · C109-M00487

C109-M00487 · 2026-08-27T12:55:55.081127-04:00 · active path

Preceding visible parent: [C109-M00486](part-18.md#m-2743411e-d0b2-4046-8db4-735876024cd5)

<!-- BEGIN_SOURCE_MESSAGE -->
From this semantic model, I want to inspect **four tables first**, in this order. We may not need anything beyond them.

1. **`FactApplicationScenario` — first and most important.** This is the most likely application × scenario bridge back to the accepted Module 1 underwriting evidence. Please send the **complete field list**.

2. **`FactFinalDecision` — second.** We already use its final outcome, but I want to see whether it exposes the upstream pricing disposition, reason codes, authorization flags, or other explanatory lineage. The final-decision contract is explicitly downstream of M2.1/M2.2 rather than the place where the underlying risk metrics originate. [export reference: filecite | turn53file5 | L408-L428]

3. **`FactBookingActivation` — third.** Only because the approved/funded structure may contain useful final economics or approved-structure fields. We will **not** use it to explain declines if those values only exist after approval.

4. **`DimApplication` — fourth.** We already know it contains requested terms, but I want the complete field inventory because some requested affordability/economic inputs may already be there.

### Hold these for now

I do **not** need yet:

- `FactAccountDaily`
- `FactMonitoringEndpoint`
- `FactIntervention`
- `FactServicingExecution`
- `FactPaymentException`
- `DimAccountAdvance`

Those are downstream performance/servicing facts and should not explain an origination decision that predates them.

Likewise, `FactPortfolioKPIEndpoint`, `FactPortfolioPerformance...`, reconciliation/certification/governance facts aren't where I'd expect application-level underwriting drivers.

### What we're specifically hunting for

Across those first four tables, I want actual fields corresponding to:

**Capacity** — ideally residual capacity / cash-flow capacity  
**Affordability** — preferably requested PTI or the actual governed affordability metric  
**Resilience** — score/tier/archetype used by M2.1  
**Risk** — integrated risk tier/proxy used by M2.1  
**Expected loss** — requested-exposure EL amount/rate/tier  
**Economics** — contribution/unit-economic metric actually consumed by eligibility/pricing  
**Interpretation** — M2.1/M2.2 primary governed reason or reason lineage

That is grounded in the actual decision architecture: M2.1 has distinct capacity, affordability, resilience, risk and economics gates, while its routing preserves primary/reason-array evidence. [export reference: filecite | turn54file6 | L547-L568] M2.2 then performs structure/pricing and M2.3 authorizes the final outcome. [export reference: filecite | turn53file5 | L410-L428]

One thing I **don't** see in your model is an obvious dedicated `FactEligibility` or `FactPricingStructure`. That means the semantic build may have intentionally consolidated the useful upstream evidence into `FactApplicationScenario` and `FactFinalDecision`. If so, excellent—we won't expose more tables unnecessarily.

**Send `FactApplicationScenario` first.** Once I see its full field list, I'll tell you whether we already have most of the seven-column row or need to continue to `FactFinalDecision`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4a5e9662-ca2e-4287-9830-a714220919e9"></a>
## Andrew / user · C109-M00488

C109-M00488 · 2026-08-27T12:57:53.517000-04:00 · active path

Preceding visible parent: [C109-M00487](part-18.md#m-55c0a9a0-70d3-40f0-972e-2b652a13a36d)

**Editorial record note:** Attachment references: Pasted text(20260827-165737).txt

<!-- BEGIN_SOURCE_MESSAGE -->
FactApplicationScenario: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-7e2734ef-50ff-4138-9013-98163ab86a92"></a>
## Assistant · C109-M00489

C109-M00489 · 2026-08-27T12:58:23.902024-04:00 · active path

Preceding visible parent: [C109-M00488](part-18.md#m-4a5e9662-ca2e-4287-9830-a714220919e9)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **`FactApplicationScenario` is exactly the table we needed**, and it substantially answers the question already.

The most important discovery is that this table contains not just status flags, but the **actual underwriting economics and risk drivers** we wanted for the new P03 row. The field structure includes capacity, affordability, resilience, integrated risk, loss, economics, evidence status, and governed reason fields in one application × scenario fact. [export reference: filecite | turn55file0 | L1-L1]

More importantly, those fields are genuinely populated for applications with usable evidence. For example, one BASELINE record has `affordability_status = MARGINAL`, payment coverage of `1.163935`, residual operating cash flow of `$194.14`, resilience score `83.10`, integrated risk score `17.73`, comparative loss amount `$60.17`, risk-adjusted contribution `$805.24`, and annualized risk-adjusted return of `77.75%`. [export reference: filecite | turn56file2 | L35-L36] Another record shows the opposite pattern: `UNAFFORDABLE`, negative residual cash flow, moderate risk, a below-hurdle economic result, and `BELOW_ECONOMIC_HURDLE` as the primary contract reason. [export reference: filecite | turn56file4 | L59-L60]

That means I would now **change our proposed P03 enhancement slightly**. I would not create seven generic PASS/FAIL columns. I would expose the actual economics and then finish with one plain-English interpretation, exactly as you suggested.

My preferred compact row is:

| Capacity | Affordability | Resilience | Risk | Expected loss | Economics | Interpretation |
|---|---|---|---|---|---|---|
| Residual cash flow | Payment coverage | Resilience score/tier | Risk score/tier | Comparative loss rate | Risk-adjusted contribution / return | Governed driver translated to executive language |

That gives an interviewer or executive an actual underwriting story rather than a collection of opaque statuses.

For the physical fields, I would initially use:

- **Capacity:** `residual_daily_operating_cash_flow`
- **Affordability:** `sales_linked_payment_coverage_ratio`
- **Resilience:** `operating_resilience_score` — potentially accompanied by `resilience_tier`
- **Risk:** `integrated_risk_score` — potentially accompanied by `integrated_risk_tier`
- **Expected loss:** `schedule_adjusted_comparative_loss_rate`
- **Economics:** `risk_adjusted_contribution_amount`; if space permits, pair it with `annualized_risk_adjusted_return_rate`
- **Interpretation:** derived from `primary_contract_reason_code`, potentially supplemented by the secondary reason array when necessary.

The reason I prefer those over fields such as `capacity_tier`, `affordability_status`, or `economic_status` is that **the decision card already tells the user what happened**. This new row should answer **why**. A user learns considerably more from `Residual cash flow: -$336` and `Payment coverage: 0.91x` than from `Capacity: 4` and `Affordability: UNAFFORDABLE`. We can preserve the governed statuses in tooltips if useful.

There is also strong evidence that the final interpretation can be made meaningfully specific. The table contains reason arrays such as `NEGATIVE_RESIDUAL_CASH_FLOW`, `CAPACITY_BURDEN_RISK`, `OPERATING_DISRUPTION`, `RECOVERY_SOURCE_CONFLICT`, `NEGATIVE_RISK_ADJUSTED_CONTRIBUTION`, and `BELOW_ECONOMIC_HURDLE`. [export reference: filecite | turn56file5 | L71-L72] So instead of duplicating your red card with “Policy decline,” we can produce exactly the kind of language we discussed:

**Affordability / capacity threshold exceeded**

or

**Economic hurdle not met**

or

**Evidence insufficient for decision**

or, where multiple factors legitimately matter,

**Capacity and economic thresholds exceeded**

One important nuance surfaced too: some records are evidence-blocked. In those cases, the numerical drivers may legitimately be blank because the governed pipeline did not have sufficient evidence to calculate them; the table explicitly carries `BLOCKED`, `INSUFFICIENT_EVIDENCE`, hard-stop flags, and reasons such as `CRITICAL_SOURCE_UNAVAILABLE`. [export reference: filecite | turn56file0 | L11-L12] We should **not substitute zeros** for those values. The interpretation should instead say something like **“Insufficient evidence for underwriting assessment.”** That is much more defensible.

So we have enough here to design the P03 enhancement, but I still want to inspect **`FactFinalDecision` next before we write any DAX**. Not because we need more metrics — `FactApplicationScenario` already gives us those — but because I want to make sure the interpretation follows the actual final decision lineage and that we do not accidentally present an upstream contract reason as though it were the final M2 decision reason.

**Send `FactFinalDecision` next.** After that, I expect we can lock the exact seven fields and start building the row immediately.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d1b1636f-5475-4233-9108-352f8e87538b"></a>
## Andrew / user · C109-M00490

C109-M00490 · 2026-08-27T12:59:38.765000-04:00 · active path

Preceding visible parent: [C109-M00489](part-18.md#m-7e2734ef-50ff-4138-9013-98163ab86a92)

**Editorial record note:** Attachment references: Pasted text(20260827-165923).txt

<!-- BEGIN_SOURCE_MESSAGE -->
FactFinalDecision:
<!-- END_SOURCE_MESSAGE -->


<a id="m-499983ab-6544-4a88-8ec4-f007ee788822"></a>
## Assistant · C109-M00491

C109-M00491 · 2026-08-27T13:00:01.293048-04:00 · active path

Preceding visible parent: [C109-M00490](part-18.md#m-d1b1636f-5475-4233-9108-352f8e87538b)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **`FactFinalDecision` resolves the remaining ambiguity**, and I would now lock the design.

The key finding is that `FactFinalDecision` is a true terminal decision layer. It explicitly carries the source pricing disposition, final decision outcome, rank, authorization/review/decline flags, final offer economics, authorization evidence status, and final decision reason codes. [export reference: filecite | turn58file1 | L24-L25] That means we should not make `FactApplicationScenario.primary_contract_reason_code` masquerade as the final decision reason. The two tables are doing different jobs:

**`FactApplicationScenario` = why the application looks the way it does economically/risk-wise.**  
**`FactFinalDecision` = what M2 ultimately authorized and under what decision class.**

That separation is exactly what we want on P03.

A very good example is the BASELINE population. `FactFinalDecision` can end in at least four materially different states:

| Final state | Final outcome | Final reason |
|---|---|---|
| Final offer | `FINAL_OFFER_AUTHORIZED` | `M2_3_FINAL_OFFER_READY` |
| Counteroffer review | `COUNTEROFFER_REVIEW_REQUIRED` | `M2_3_COUNTEROFFER_REVIEW_REQUIRED` |
| Evidence decline | `DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED` | `M2_3_INSUFFICIENT_EVIDENCE` |
| Policy decline | `DECLINE_POLICY_AUTHORIZED` | `M2_3_POLICY_DECLINE` |

Those are not theoretical. We have actual BASELINE rows for all of them. For example, merchant M000084 has an authorized $5,000 final offer with a 10.6541% remittance rate, 1.205832 payback multiple and 90-day collection horizon. [export reference: filecite | turn58file9 | L128-L129] Other BASELINE records are explicitly counteroffer-review cases, with both `counteroffer_review_required_flag = True` and `manual_review_required_flag = True`. [export reference: filecite | turn58file5 | L75-L77] And evidence-deficient cases terminate as authorized declines with `M2_3_INSUFFICIENT_EVIDENCE`, rather than being mislabeled as economic or credit declines. [export reference: filecite | turn58file12 | L166-L168]

That is important for our executive language.

## I would now lock the P03 row as follows

| Display | Governing source | Physical field / logic |
|---|---|---|
| **Capacity** | `FactApplicationScenario` | `residual_daily_operating_cash_flow` |
| **Coverage** | `FactApplicationScenario` | `sales_linked_payment_coverage_ratio` |
| **Resilience** | `FactApplicationScenario` | `operating_resilience_score` + tier |
| **Risk** | `FactApplicationScenario` | `integrated_risk_score` + tier |
| **Expected Loss** | `FactApplicationScenario` | `schedule_adjusted_comparative_loss_rate` |
| **Economics** | `FactApplicationScenario` | `risk_adjusted_contribution_amount`, optionally annualized return |
| **Decision Readout** | **both tables** | terminal M2 outcome from `FactFinalDecision` + diagnostic driver from `FactApplicationScenario` |

The last column is the refinement I was waiting for.

I would **not** call it simply “Interpretation” anymore. I think **`DECISION READOUT`** is stronger and clearer because it tells the viewer that this is an explanation of the actual governed decision, not generic commentary.

The readout should operate hierarchically:

**1. First respect the terminal M2 decision.**

If final decision is insufficient evidence:

> **Insufficient evidence — underwriting assessment cannot be completed**

Do not show a guessed capacity/economic cause.

If final decision is policy decline:

> **Policy decline — [dominant governed driver]**

If counteroffer:

> **Counteroffer review — [dominant constraint]**

If final offer:

> **Offer authorized — economics and risk within decision boundary**

That distinction matters because `FactFinalDecision` demonstrates that a policy decline is a deliberate terminal state with `decline_authorized_flag = True`, while an authorized offer has `final_offer_authorized_flag = True`, populated offer terms and authorization evidence. [export reference: filecite | turn58file10 | L140-L142] [export reference: filecite | turn58file15 | L205-L207]

**2. Only then use `FactApplicationScenario` to explain the driver.**

For example, if M2 says `DECLINE_POLICY_AUTHORIZED` and M1/M2 application economics show negative residual cash flow plus an affordability breach, the visible wording can be:

> **Policy decline — capacity / affordability threshold exceeded**

If the economics show the principal issue is return:

> **Policy decline — economic hurdle not met**

If it is risk-adjusted contribution:

> **Policy decline — negative risk-adjusted contribution**

If counteroffer is required and capacity is weak:

> **Counteroffer review — proposed structure exceeds sustainable capacity**

That is materially better than exposing `M2_3_POLICY_DECLINE` to the user. That code should remain traceable behind the visual, but it doesn't explain anything to an executive.

### One other strong confirmation

`FactFinalDecision` also shows why **we should not use its offer fields as the six diagnostic metrics**. Those fields are terminal structure outputs. An authorized offer includes amount, remittance rate, payback multiple, horizon, repayment, finance charge and implied payoff metrics. [export reference: filecite | turn58file14 | L192-L194] But a policy decline or evidence decline correctly has those fields blank because there is no structure to book. So the existing red/green decision area can own the actual final offer/result, while this new row owns the analytical explanation.

That gives P03 a very clean narrative:

**What did we decide?**  
→ Existing final-decision card.

**What would we offer?**  
→ Existing offer/structure content where applicable.

**Why did the model/policy reach that decision?**  
→ New Capacity → Coverage → Resilience → Risk → Loss → Economics → Decision Readout row.

And there is a nice scenario-story benefit. The same merchant can be `STRUCTURE_READY / FINAL_OFFER_AUTHORIZED` under BASELINE and become `NO_STRUCTURE_POLICY_DECLINE / DECLINE_POLICY_AUTHORIZED` under `RECESSION_ENERGY`; the table explicitly supports that scenario-dependent transition. For M000087, BASELINE has a $4,400 authorized offer, while the recession-energy record terminates as a policy decline. [export reference: filecite | turn58file9 | L129-L129] [export reference: filecite | turn57file0 | L2-L8] That makes the row especially valuable because the user will actually see **which underlying economics deteriorated when the scenario changes**, rather than merely watching the decision card turn red.

So I don't think we need another fact table before construction. **`FactApplicationScenario` + `FactFinalDecision` give us the complete governed story for this enhancement.**

My next move would be to write the **exact DAX measures for these seven positions**, using the current ApplicationKey/RunScenarioKey filter context and explicit blocked/evidence handling, and then give you the precise P03 construction sequence.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c8e022fb-27a1-4c1f-b052-4c6753a767d8"></a>
## Andrew / user · C109-M00492

C109-M00492 · 2026-08-27T13:01:07.071000-04:00 · active path

Preceding visible parent: [C109-M00491](part-18.md#m-499983ab-6544-4a88-8ec4-f007ee788822)

<!-- BEGIN_SOURCE_MESSAGE -->
write the **exact DAX measures for these seven positions**, using the current ApplicationKey/RunScenarioKey filter context and explicit blocked/evidence handling, and then give you the precise P03 construction sequence.  
<!-- END_SOURCE_MESSAGE -->


<a id="m-74d22144-77c5-4ff3-be02-1e79c23cca7a"></a>
## Assistant · C109-M00493

C109-M00493 · 2026-08-27T13:03:35.570080-04:00 · active path

Preceding visible parent: [C109-M00492](part-18.md#m-c8e022fb-27a1-4c1f-b052-4c6753a767d8)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. I would build this as **seven P03-specific display measures**, rather than altering the existing portfolio measures. The existing semantic design defines `[Expected Loss Rate]` and `[Risk Adjusted Contribution]` as aggregation measures across application-scenario populations; P03 needs a **single application + single scenario diagnostic readout with evidence suppression**, which is a different presentation contract. [export reference: filecite | turn67file0 | L27-L31]

The model already has active single-direction relationships from `DimApplication[ApplicationKey]` and `DimScenario[RunScenarioKey]` into both `FactApplicationScenario` and `FactFinalDecision`, and those relationships were explicitly designed so scenario-sensitive facts are filtered by `RunScenarioKey`. [export reference: filecite | turn66file11 | L927-L938] The physical relationship testing also established filter propagation for those exact keys. [export reference: filecite | turn66file6 | L442-L490] So the measures below deliberately read the **current `ApplicationKey` + `RunScenarioKey` context** and refuse to synthesize a value when that context is not singular.

The source evidence also makes the blocking rules clear: `FactApplicationScenario` separately carries `capacity_evidence_status`, `operating_resilience_evidence_status`, `integrated_risk_evidence_status`, `loss_evidence_status`, `unit_economics_evidence_status`, and `contract_evidence_status`. [export reference: filecite | turn64file0 | L12-L13] When evidence is blocked, downstream outputs can legitimately be null; M1.14 explicitly defines `BLOCKED` economics as a state in which contribution/return/surplus cannot support favorable conclusions. [export reference: filecite | turn68file0 | L43-L49]

## 1. `P03 Capacity Display`

This is the **residual daily operating cash flow**. It should not show a number when capacity evidence is blocked, even though some blocked records can retain intermediate diagnostic values in the physical row. That distinction is important. [export reference: filecite | turn64file0 | L13-L15]

```DAX
P03 Capacity Display =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )
VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ValidContext =
    NOT ISBLANK ( _ApplicationKey )
        && NOT ISBLANK ( _RunScenarioKey )

VAR _RowCount =
    CALCULATE (
        COUNTROWS ( 'FactApplicationScenario' ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _EvidenceStatus =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[capacity_evidence_status] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Value =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[residual_daily_operating_cash_flow] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

RETURN
    SWITCH (
        TRUE (),
        NOT _ValidContext, "SELECT APPLICATION",
        _RowCount <> 1, "EVIDENCE UNAVAILABLE",
        _EvidenceStatus = "BLOCKED", "INSUFFICIENT EVIDENCE",
        ISBLANK ( _Value ), "NOT AVAILABLE",
        FORMAT ( _Value, "$#,0;($#,0);$0" ) & " / DAY"
    )
```

The economic meaning is well supported: the underlying capacity engine defines residual daily operating cash flow as estimated daily operating cash flow minus total daily obligation burden. [export reference: filecite | turn63file4 | L119-L122]

---

## 2. `P03 Coverage Display`

This is the sales-linked payment coverage ratio. The engine defines it as operating cash flow divided by total obligation burden. [export reference: filecite | turn63file4 | L119-L121]

```DAX
P03 Coverage Display =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )
VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ValidContext =
    NOT ISBLANK ( _ApplicationKey )
        && NOT ISBLANK ( _RunScenarioKey )

VAR _RowCount =
    CALCULATE (
        COUNTROWS ( 'FactApplicationScenario' ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _EvidenceStatus =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[capacity_evidence_status] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Value =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[sales_linked_payment_coverage_ratio] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

RETURN
    SWITCH (
        TRUE (),
        NOT _ValidContext, "SELECT APPLICATION",
        _RowCount <> 1, "EVIDENCE UNAVAILABLE",
        _EvidenceStatus = "BLOCKED", "INSUFFICIENT EVIDENCE",
        ISBLANK ( _Value ), "NOT AVAILABLE",
        FORMAT ( _Value, "0.00x" )
    )
```

This card will give us intuitive values such as `1.16x`, `1.52x`, or `0.50x`; the underlying application population actually contains that range and ties it to `AFFORDABLE`, `MARGINAL`, and `UNAFFORDABLE` states. [export reference: filecite | turn65file3 | L47-L47] [export reference: filecite | turn65file1 | L22-L23]

---

## 3. `P03 Resilience Display`

For this one I strongly prefer **score + governed tier**, because the tier makes a raw 0–100 score immediately intelligible.

```DAX
P03 Resilience Display =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )
VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ValidContext =
    NOT ISBLANK ( _ApplicationKey )
        && NOT ISBLANK ( _RunScenarioKey )

VAR _RowCount =
    CALCULATE (
        COUNTROWS ( 'FactApplicationScenario' ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _EvidenceStatus =
    CALCULATE (
        SELECTEDVALUE (
            'FactApplicationScenario'[operating_resilience_evidence_status]
        ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Score =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[operating_resilience_score] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Tier =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[resilience_tier] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

RETURN
    SWITCH (
        TRUE (),
        NOT _ValidContext, "SELECT APPLICATION",
        _RowCount <> 1, "EVIDENCE UNAVAILABLE",
        _EvidenceStatus = "BLOCKED", "INSUFFICIENT EVIDENCE",
        ISBLANK ( _Score ), "NOT AVAILABLE",
        FORMAT ( _Score, "0.0" )
            & IF (
                NOT ISBLANK ( _Tier ),
                "  ·  TIER " & FORMAT ( _Tier, "0" ),
                ""
            )
    )
```

The source explicitly supplies both `operating_resilience_score` and `resilience_tier`, rather than requiring us to invent bands in Power BI. [export reference: filecite | turn63file13 | L452-L454]

---

## 4. `P03 Risk Display`

Same principle: use the governed score and governed tier; do **not** create our own Power BI risk band.

```DAX
P03 Risk Display =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )
VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ValidContext =
    NOT ISBLANK ( _ApplicationKey )
        && NOT ISBLANK ( _RunScenarioKey )

VAR _RowCount =
    CALCULATE (
        COUNTROWS ( 'FactApplicationScenario' ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _EvidenceStatus =
    CALCULATE (
        SELECTEDVALUE (
            'FactApplicationScenario'[integrated_risk_evidence_status]
        ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Score =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[integrated_risk_score] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Tier =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[integrated_risk_tier] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

RETURN
    SWITCH (
        TRUE (),
        NOT _ValidContext, "SELECT APPLICATION",
        _RowCount <> 1, "EVIDENCE UNAVAILABLE",
        _EvidenceStatus = "BLOCKED", "INSUFFICIENT EVIDENCE",
        ISBLANK ( _Score ), "NOT AVAILABLE",
        FORMAT ( _Score, "0.0" )
            & IF (
                NOT ISBLANK ( _Tier ),
                "  ·  TIER " & FORMAT ( _Tier, "0" ),
                ""
            )
    )
```

Again, both fields physically exist in the integrated consumption row. [export reference: filecite | turn63file6 | L160-L166] Actual examples show, for instance, a risk score around `14.39` with tier `1 / LOW_RISK` and another around `29.82` with tier `2 / MODERATE_RISK`; we therefore should preserve the accepted tier rather than reverse-engineer one. [export reference: filecite | turn65file3 | L47-L47] [export reference: filecite | turn65file1 | L22-L23]

---

## 5. `P03 Expected Loss Display`

I would use the **loss rate**, not the dollar loss, in this strip. Dollar expected loss is heavily influenced by requested exposure; the rate is much more useful beside Risk and Resilience.

Crucially, `PARTIAL` is legitimate evidence—not the same as blocked. The source population contains many usable comparative-loss rates with `loss_evidence_status = PARTIAL`. [export reference: filecite | turn65file3 | L47-L47]

```DAX
P03 Expected Loss Display =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )
VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ValidContext =
    NOT ISBLANK ( _ApplicationKey )
        && NOT ISBLANK ( _RunScenarioKey )

VAR _RowCount =
    CALCULATE (
        COUNTROWS ( 'FactApplicationScenario' ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _EvidenceStatus =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[loss_evidence_status] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Value =
    CALCULATE (
        SELECTEDVALUE (
            'FactApplicationScenario'[schedule_adjusted_comparative_loss_rate]
        ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

RETURN
    SWITCH (
        TRUE (),
        NOT _ValidContext, "SELECT APPLICATION",
        _RowCount <> 1, "EVIDENCE UNAVAILABLE",
        _EvidenceStatus = "BLOCKED", "INSUFFICIENT EVIDENCE",
        ISBLANK ( _Value ), "NOT AVAILABLE",
        FORMAT ( _Value, "0.00%" )
            & IF ( _EvidenceStatus = "PARTIAL", "  ·  PARTIAL", "" )
    )
```

That preserves the existing semantic boundary: Expected Loss is a **synthetic comparative loss measure, not CECL or a calibrated production loss estimate**. [export reference: filecite | turn67file0 | L27-L29]

---

## 6. `P03 Economics Display`

For the strip, I would display:

**risk-adjusted contribution + annualized risk-adjusted return**

Example:

**`$459 · 26.1% ANN.`**

That tells a much richer story than contribution alone.

```DAX
P03 Economics Display =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )
VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ValidContext =
    NOT ISBLANK ( _ApplicationKey )
        && NOT ISBLANK ( _RunScenarioKey )

VAR _RowCount =
    CALCULATE (
        COUNTROWS ( 'FactApplicationScenario' ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _EvidenceStatus =
    CALCULATE (
        SELECTEDVALUE (
            'FactApplicationScenario'[unit_economics_evidence_status]
        ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Contribution =
    CALCULATE (
        SELECTEDVALUE (
            'FactApplicationScenario'[risk_adjusted_contribution_amount]
        ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _AnnualizedReturn =
    CALCULATE (
        SELECTEDVALUE (
            'FactApplicationScenario'[annualized_risk_adjusted_return_rate]
        ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

RETURN
    SWITCH (
        TRUE (),
        NOT _ValidContext, "SELECT APPLICATION",
        _RowCount <> 1, "EVIDENCE UNAVAILABLE",
        _EvidenceStatus = "BLOCKED", "INSUFFICIENT EVIDENCE",
        ISBLANK ( _Contribution ), "NOT AVAILABLE",
        FORMAT ( _Contribution, "$#,0;($#,0);$0" )
            & IF (
                NOT ISBLANK ( _AnnualizedReturn ),
                "  ·  "
                    & FORMAT ( _AnnualizedReturn, "0.0%" )
                    & " ANN.",
                ""
            )
            & IF ( _EvidenceStatus = "PARTIAL", "  ·  PARTIAL", "" )
    )
```

This handling is directly aligned to M1.14: risk-adjusted contribution and annualized return are accepted governed economics outputs, but blocked comparative-loss evidence requires those downstream economics to remain unusable/null. [export reference: filecite | turn68file0 | L19-L34] [export reference: filecite | turn68file0 | L43-L49]

---

# 7. `P03 Decision Readout`

This is the important one.

`FactFinalDecision` is authoritative for **what happened**. The source contains `final_decision_outcome_code`, authorization/review/decline flags, final-offer fields, authorization evidence status, and `primary_decision_reason_code`. [export reference: filecite | turn60file0 | L12-L13]

`FactApplicationScenario` is then used only to make the decision understandable.

```DAX
P03 Decision Readout =
VAR _ApplicationKey =
    SELECTEDVALUE ( 'DimApplication'[ApplicationKey] )
VAR _RunScenarioKey =
    SELECTEDVALUE ( 'DimScenario'[RunScenarioKey] )

VAR _ValidContext =
    NOT ISBLANK ( _ApplicationKey )
        && NOT ISBLANK ( _RunScenarioKey )

VAR _DecisionRowCount =
    CALCULATE (
        COUNTROWS ( 'FactFinalDecision' ),
        TREATAS ( { _ApplicationKey }, 'FactFinalDecision'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactFinalDecision'[RunScenarioKey] )
    )

VAR _ApplicationScenarioRowCount =
    CALCULATE (
        COUNTROWS ( 'FactApplicationScenario' ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _FinalOutcome =
    CALCULATE (
        SELECTEDVALUE ( 'FactFinalDecision'[final_decision_outcome_code] ),
        TREATAS ( { _ApplicationKey }, 'FactFinalDecision'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactFinalDecision'[RunScenarioKey] )
    )

VAR _DecisionReason =
    CALCULATE (
        SELECTEDVALUE ( 'FactFinalDecision'[primary_decision_reason_code] ),
        TREATAS ( { _ApplicationKey }, 'FactFinalDecision'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactFinalDecision'[RunScenarioKey] )
    )

VAR _ContractEvidence =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[contract_evidence_status] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _Affordability =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[affordability_status] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _ResidualCashFlow =
    CALCULATE (
        SELECTEDVALUE (
            'FactApplicationScenario'[residual_daily_operating_cash_flow]
        ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _EconomicStatus =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[economic_status] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _RiskTier =
    CALCULATE (
        SELECTEDVALUE ( 'FactApplicationScenario'[integrated_risk_tier] ),
        TREATAS ( { _ApplicationKey }, 'FactApplicationScenario'[ApplicationKey] ),
        TREATAS ( { _RunScenarioKey }, 'FactApplicationScenario'[RunScenarioKey] )
    )

VAR _CapacityConstraint =
    _Affordability = "UNAFFORDABLE"
        || (
            NOT ISBLANK ( _ResidualCashFlow )
                && _ResidualCashFlow < 0
        )

VAR _EconomicConstraint =
    _EconomicStatus = "BELOW_HURDLE"

VAR _NegativeContribution =
    _EconomicStatus = "NEGATIVE_CONTRIBUTION"

VAR _ElevatedRisk =
    NOT ISBLANK ( _RiskTier )
        && _RiskTier >= 4

RETURN
    SWITCH (
        TRUE (),

        NOT _ValidContext,
            "Select one application and one scenario",

        _DecisionRowCount <> 1,
            "Final decision evidence unavailable",

        _ApplicationScenarioRowCount <> 1,
            "Decision available — diagnostic evidence unavailable",

        _FinalOutcome = "DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED"
            || _DecisionReason = "M2_3_INSUFFICIENT_EVIDENCE"
            || _ContractEvidence = "BLOCKED",
            "Insufficient evidence — underwriting assessment cannot be completed",

        _FinalOutcome = "FINAL_OFFER_AUTHORIZED",
            "Offer authorized — economics and risk within decision boundary",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _CapacityConstraint,
            "Counteroffer review — proposed structure exceeds sustainable capacity",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _NegativeContribution,
            "Counteroffer review — structure produces negative risk-adjusted contribution",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _EconomicConstraint,
            "Counteroffer review — economic hurdle requires restructuring",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED"
            && _ElevatedRisk,
            "Counteroffer review — elevated integrated risk requires restructuring",

        _FinalOutcome = "COUNTEROFFER_REVIEW_REQUIRED",
            "Counteroffer review — governed structure requires review",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _CapacityConstraint,
            "Policy decline — capacity / affordability threshold exceeded",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _NegativeContribution,
            "Policy decline — negative risk-adjusted contribution",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _EconomicConstraint,
            "Policy decline — economic hurdle not met",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED"
            && _ElevatedRisk,
            "Policy decline — elevated integrated risk",

        _FinalOutcome = "DECLINE_POLICY_AUTHORIZED",
            "Policy decline — governed policy boundary not met",

        "Governed decision requires review"
    )
```

Notice what I **did not** do: I did not turn `primary_contract_reason_code` into the final decision. `FactFinalDecision` remains the terminal authority. The physical data explicitly distinguishes `FINAL_OFFER_AUTHORIZED`, `COUNTEROFFER_REVIEW_REQUIRED`, `DECLINE_POLICY_AUTHORIZED`, and `DECLINE_INSUFFICIENT_EVIDENCE_AUTHORIZED`. [export reference: filecite | turn58file9 | L127-L129] [export reference: filecite | turn58file5 | L75-L77]

I also intentionally put the authorized-offer branch **before** diagnostic weaknesses. A merchant may have some weaker diagnostic dimensions and still have a governed final offer. We must not let a presentation heuristic silently overrule M2.3.

---

# Precise P03 construction sequence

I would now build this **directly**, without another audit round first. We have enough evidence to test it ourselves quickly.

### Step 1 — Create the seven measures

In Power BI Desktop:

**Modeling → New measure**

Create these in the same central measure table that currently holds the PBI measures:

1. `P03 Capacity Display`
2. `P03 Coverage Display`
3. `P03 Resilience Display`
4. `P03 Risk Display`
5. `P03 Expected Loss Display`
6. `P03 Economics Display`
7. `P03 Decision Readout`

Do **not** modify `[Expected Loss]`, `[Expected Loss Rate]`, or `[Risk Adjusted Contribution]`. Those remain the accepted portfolio-level measures defined by the semantic design. [export reference: filecite | turn67file0 | L27-L31]

### Step 2 — Smoke-test before touching the page

On a temporary blank development page, add:

- one slicer using `DimApplication[ApplicationKey]`
- one slicer using the existing scenario field from `DimScenario`
- seven simple cards

Bind one measure to each card.

First confirm that selecting a single application and changing BASELINE ↔ RECESSION_ENERGY changes the measures. We already know the physical model has **750 application/scenario rows per scenario and 1,500 rows in each of these two facts**, so a single application + scenario should resolve exactly one row. [export reference: filecite | turn66file12 | L987-L1010]

### Step 3 — Test an ordinary supported record

Use a record with nonblocked capacity/risk/resilience evidence.

Expected behavior should resemble:

**CAPACITY**  
`$48 / DAY`

**COVERAGE**  
`1.16x`

**RESILIENCE**  
`84.2 · TIER 1`

**RISK**  
`14.4 · TIER 1`

**EXPECTED LOSS**  
`3.85% · PARTIAL`

**ECONOMICS**  
`$459 · 26.1% ANN. · PARTIAL`

Those are representative of actual physical combinations in `FactApplicationScenario`, not invented ranges. [export reference: filecite | turn65file3 | L47-L47]

### Step 4 — Test a blocked record

Select one of the records with `capacity_evidence_status = BLOCKED`, `operating_resilience_evidence_status = BLOCKED`, `integrated_risk_evidence_status = BLOCKED`, `loss_evidence_status = BLOCKED`, and `unit_economics_evidence_status = BLOCKED`.

The first six cards should read:

**`INSUFFICIENT EVIDENCE`**

—not `0`, not blank, not an apparently valid score.

The source contains exactly this sort of record, where the evidence states are blocked and the contract status is `INSUFFICIENT_EVIDENCE`. [export reference: filecite | turn64file0 | L13-L16]

Decision Readout should say:

**Insufficient evidence — underwriting assessment cannot be completed**

### Step 5 — Test scenario sensitivity

Use the same application under both BASELINE and RECESSION_ENERGY.

We need to confirm that changing only scenario changes these six diagnostics and the decision where appropriate. The semantic model deliberately has separate active `RunScenarioKey` relationships into both facts. [export reference: filecite | turn66file13 | L1055-L1058]

This is especially important because our actual final-decision data shows merchants that are authorized under one scenario and declined under another.

### Step 6 — Move to P03

Once those three tests pass, return to **P03**.

Do **not** disturb the existing main decision/offer area.

Insert a new analytical strip **immediately beneath the principal decision/offer section and above the deeper performance/servicing content**. Conceptually, that gives the page:

**Application identity / selection**  
↓  
**Final governed decision**  
↓  
**WHY — diagnostic strip**  
↓  
**Downstream performance / operational detail**

That is the correct narrative hierarchy.

### Step 7 — Build six compact metric cells + one wider readout cell

I would not make all seven equal width.

Use approximately:

**Capacity | Coverage | Resilience | Risk | Expected Loss | Economics | Decision Readout**

with the first six approximately equal and **Decision Readout about 2–2.5× wider**.

The reason is simple: the first six communicate with one number plus a small qualifier; the seventh is an explanatory sentence.

### Step 8 — Use Card (new) visuals for the first six

For each:

- Category label = ON
- Callout value = the P03 display measure
- Reference labels = OFF initially
- Background = consistent with current P03 surface
- Border = subtle/current design standard
- Shadow = match existing P03
- Visual title = OFF
- Interaction = inherit current Application and Scenario slicers

Labels:

**CAPACITY**  
**COVERAGE**  
**RESILIENCE**  
**RISK**  
**EXPECTED LOSS**  
**ECONOMICS**

I would use uppercase labels because this is a compact underwriting diagnostic strip, not another KPI header hierarchy.

### Step 9 — Decision Readout gets a dedicated wide card

Use a card/text-compatible visual with:

**DECISION READOUT**

as the category label and `[P03 Decision Readout]` as the primary text.

Allow wrapping.

Keep the font smaller than the six metric callouts, because the semantic hierarchy should be:

**numbers first → interpretation second.**

### Step 10 — Do not add red/green logic yet

This is important.

I would **first get the data behaving correctly**.

Do not spend time designing elaborate thresholds or six separate conditional-format rules before we see the page working. Several of these metrics already have governed tiers/statuses in the source, and we should use those instead of inventing new PBI classifications. `FactApplicationScenario` already carries capacity tier/status, resilience tier/status, risk tier/status, economics tier/status, and the separate evidence-state fields. [export reference: filecite | turn63file6 | L158-L188]

Once we physically see the row, we can decide in minutes whether restrained accenting improves it.

### Step 11 — Four QA selections before styling

Before making it beautiful, deliberately find:

1. **Final offer authorized**
2. **Counteroffer review**
3. **Policy decline**
4. **Insufficient evidence decline**

For each one, toggle BASELINE and RECESSION_ENERGY where both exist.

We want to prove:

- no cross-scenario bleed;
- no blocked metric presented as valid;
- `PARTIAL` evidence remains visible rather than suppressed;
- final offer readout never gets overridden by a diagnostic heuristic;
- policy decline gets a sensible driver;
- insufficient evidence stays evidence-based and does not invent a credit/economic explanation.

That last item is especially important because the physical final-decision contract expressly distinguishes an authorized evidence decline from an authorized policy decline. [export reference: filecite | turn60file0 | L12-L16]

### Step 12 — Then tune the visual treatment

Once the data passes, I would expect us to make only small visual decisions:

**Capacity:** dollar/day  
**Coverage:** `x` multiple  
**Resilience:** score + tier  
**Risk:** score + tier  
**Expected Loss:** rate + evidence qualifier where partial  
**Economics:** contribution + annualized return + evidence qualifier  
**Decision Readout:** plain-English governed explanation

That gives us exactly the story we wanted:

> **Can the merchant carry it? → How much coverage exists? → How resilient are operations? → How much risk exists? → What loss burden follows? → Do the economics work? → What did that mean for the actual governed decision?**

I would build **exactly this version first**. It is sufficiently bounded that we should be able to tell almost immediately, from a handful of application selections, whether any wording or layout needs adjustment before spending time polishing it. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-a578a956-1653-485f-ac89-039154d3d188"></a>
## Andrew / user · C109-M00494

C109-M00494 · 2026-08-27T13:51:17.951000-04:00 · active path

Preceding visible parent: [C109-M00493](part-18.md#m-74d22144-77c5-4ff3-be02-1e79c23cca7a)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 9028a896-8b9e-44d7-9514-fa6f03d4d327.png

<!-- BEGIN_SOURCE_MESSAGE -->
I think I have space for a table - not a card - here is what I was thinking - notice the second duplicate merchant request (non-titled) table. That would be where we could place this.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e220d4ab-d520-4084-828f-5647b0bfb8ff"></a>
## Assistant · C109-M00495

C109-M00495 · 2026-08-27T13:51:23.336623-04:00 · active path

Preceding visible parent: [C109-M00494](part-18.md#m-a578a956-1653-485f-ac89-039154d3d188)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — **this is better than the card-strip approach for P03**.

Looking at the actual page, the duplicated untitled `Merchant request` table is almost exactly the footprint I would use. You already have a strong left-to-right/top-to-bottom narrative, and putting a second **single-row underwriting table directly beneath Merchant request** keeps the reasoning physically attached to the request/decision rather than turning it into another dashboard element.

I would make that second row:

| Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation |
|---|---:|---:|---:|---:|---:|---|
| $XX/day | 1.XXx | XX.X · T# | XX.X · T# | X.XX% | $XXX · XX.X% | Affordability / risk threshold exceeded |

That is cleaner than seven cards for this page.

A few important refinements:

**First, do not title it.** I agree with your instinct. Visually, it should read as an extension of `Merchant request` — essentially, “here is the request, and directly beneath it are the underwriting characteristics evaluated against that request.” Adding a heading like *Decision profile* would cost vertical space and make it feel like a separate module.

**Second, I would shorten the metric names.** In this narrow footprint I would use exactly:

`Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation`

That keeps the headers legible and preserves width for the final interpretation column.

**Third, the Interpretation column should be much wider than the others.** It should not repeat `APPROVED`, `POLICY DECLINE`, `COUNTEROFFER`, etc. The colored decision block immediately below already owns the outcome. This column answers only **why**. So examples should be compact phrases such as:

- `Within governed thresholds`
- `Affordability threshold exceeded`
- `Affordability / risk threshold exceeded`
- `Economic hurdle not met`
- `Negative risk-adjusted contribution`
- `Insufficient underwriting evidence`
- `Capacity constraint; restructuring required`

That division of labor is much stronger:

**table = underlying evidence and driver**  
**green/yellow/red block = governed outcome**

I would also slightly change the six numeric outputs from the earlier display-measure design. Because this is now a **table**, not cards, we do not need measures returning long strings like `INSUFFICIENT EVIDENCE`. We can make the row more elegant by keeping the metric cells concise and concentrating explanatory text in Interpretation.

For example, on a blocked record:

| Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation |
|---|---:|---:|---:|---:|---:|---|
| — | — | — | — | — | — | Insufficient underwriting evidence |

For a supported decline:

| Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation |
|---|---:|---:|---:|---:|---:|---|
| ($213)/day | 0.50x | 70.1 · T2 | 29.8 · T2 | 10.30% | ($183) · (19.9%) | Affordability / economics threshold exceeded |

And for an approval:

| Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation |
|---|---:|---:|---:|---:|---:|---|
| $66/day | 1.52x | 80.5 · T1 | 15.6 · T1 | 4.99% | $287 · 34.9% | Within governed thresholds |

That is substantially more interview-friendly because someone can point to one row and ask you, **“Why did this merchant get approved?”** and you can literally walk across the underwriting dimensions before pointing to the green decision box.

### I would revise the DAX architecture slightly

Rather than the seven long text measures I gave you previously, I now recommend:

- six **numeric/display measures**, each blank when its governing evidence is blocked;
- one **Interpretation** text measure.

That gives Power BI much better formatting control in the table and lets us use `—` for blanks through the visual/formatting rather than embedding prose into every measure.

The row should sit **exactly where your duplicate table is now**. I would also reduce the vertical gap between that row and the green `APPROVED` box slightly. The intended visual reading becomes:

**Merchant request**  
`Application | Applied | Requested | Use | Channel | Remittance | Payoff days | Repayment`

**Underwriting evidence**  
`Capacity | Coverage | Resilience | Risk | Expected loss | Economics | Interpretation`

**APPROVED — Final offer**

**Funded terms**

That is a very strong underwriting narrative and fits the current P03 page without disturbing the monitoring/performance story below.

One other design point from your screenshot: **do not make this table taller than the current duplicate row.** Keep it to one record, column headers + one value row, with no totals and no vertical scrollbar. If Interpretation wraps to two lines, slightly widen that column rather than increasing the entire table height much.

So I would pivot from my prior construction recommendation: **keep the measures, but build the presentation as this single-row table.** This fits P03 considerably better than seven cards. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-e80e0d49-b4d9-4eeb-b3c2-6054dbd090a4"></a>
## Andrew / user · C109-M00496

C109-M00496 · 2026-08-27T13:52:31.157000-04:00 · active path

Preceding visible parent: [C109-M00495](part-18.md#m-e220d4ab-d520-4084-828f-5647b0bfb8ff)

<!-- BEGIN_SOURCE_MESSAGE -->
ok - give me the variables / order / names for that table.
<!-- END_SOURCE_MESSAGE -->
