# MSBF - Power BI Executive Portfolio Intelligence Part 2

Part 15 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-14.md)
[Next part](part-16.md)

<a id="m-87d53874-a81e-4147-8581-17806e203640"></a>
## Assistant · C109-M00397

C109-M00397 · 2026-08-27T05:03:43.604165-04:00 · active path

Preceding visible parent: [C109-M00396](part-14.md#m-70a79c4f-1185-47da-88de-5e5b6d1285d8)

<!-- BEGIN_SOURCE_MESSAGE -->
That confirms the conclusion cleanly.

The current page should **not** be called “Merchant Relationship 360.” At Module 2, the governed application population is effectively **one merchant → zero or one application**, so the page is tracing a single application/account path, not a longitudinal relationship history across multiple application cycles.

I would rename the page:

**Merchant Application & Account Journey**

Subtitle:

**Follow one synthetic merchant application from request and decision through funding, performance, monitoring and servicing.**

That matches the actual current-model boundary and the visuals we built. It also preserves a clear future distinction:

- **Current P03 — Merchant Application & Account Journey:** one application, one decision path, one resulting account lifecycle if funded.
- **Future Merchant Relationship 360:** one merchant across multiple applications, advances, renewals, closures, repeat borrowing, relationship evolution, and eventually cumulative relationship economics.

Your earlier build-chat clarification also explains why the current merchant attributes such as `Prior advances` and `Prior funded` should be treated as **historical profile/context variables used in the current decision**, not as navigable prior accounts represented elsewhere in this build.

I would preserve the current Merchant slicer architecture exactly as you suggested, though. Today it resolves to one application; later the model can naturally evolve to:

`Merchant → Applications → Decisions → Advances/Accounts → Daily performance → Servicing`

without requiring the entire report concept to be redesigned.

One other consequence: our original roadmap had **Merchant Relationship 360** and **Application & Account Journey** as separate pages. I would now treat the page we just built as the latter and **defer Merchant Relationship 360 rather than build another current-wave page that would mostly duplicate this one**. That is a useful scope correction for the authorized wave, and we should document it when we return to Audit. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-892fa84d-45bb-4961-ae09-8a589abd0b09"></a>
## Andrew / user · C109-M00398

C109-M00398 · 2026-08-27T05:06:22.475000-04:00 · active path

Preceding visible parent: [C109-M00397](part-15.md#m-87d53874-a81e-4147-8581-17806e203640)

<!-- BEGIN_SOURCE_MESSAGE -->
Tab name suggestion?
<!-- END_SOURCE_MESSAGE -->


<a id="m-dfb344f7-5371-43de-9594-3735f13bfeb7"></a>
## Assistant · C109-M00399

C109-M00399 · 2026-08-27T05:06:25.854030-04:00 · active path

Preceding visible parent: [C109-M00398](part-15.md#m-892fa84d-45bb-4961-ae09-8a589abd0b09)

<!-- BEGIN_SOURCE_MESSAGE -->
I recommend:

**`P03 - Application Journey`**

It is concise enough for the Power BI tab bar while the page title can carry the fuller, precise name:

**Merchant Application & Account Journey**

I prefer `Application Journey` over `Account Journey` because every selected application has a journey, including **REVIEW** and **DECLINED** applications that never become funded accounts.

So:

**Tab:** `P03 - Application Journey`  
**Page title:** `Merchant Application & Account Journey`  
**Subtitle:** `Follow one synthetic merchant application from request and decision through funding, performance, monitoring and servicing.`

That feels like the cleanest naming hierarchy.
<!-- END_SOURCE_MESSAGE -->


<a id="m-be7e502a-4fd3-4be9-92ab-4b8347927a2a"></a>
## Andrew / user · C109-M00400

C109-M00400 · 2026-08-27T05:08:38.941000-04:00 · active path

Preceding visible parent: [C109-M00399](part-15.md#m-dfb344f7-5371-43de-9594-3735f13bfeb7)

<!-- BEGIN_SOURCE_MESSAGE -->
now we need to finalize: 1) Alt text ; 2) Tooltips ; 3) Tab Order ; 4) Confirm footnote
<!-- END_SOURCE_MESSAGE -->


<a id="m-f730fa49-126a-40ec-866a-2e4aa4a59f07"></a>
## Assistant · C109-M00401

C109-M00401 · 2026-08-27T05:08:42.183336-04:00 · active path

Preceding visible parent: [C109-M00400](part-15.md#m-be7e502a-4fd3-4be9-92ab-4b8347927a2a)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. This is the right point to do the **P03 presentation/accessibility closeout** before broader UAT. Based on the final structure we have built, I would finalize it as follows.

### 1. Alt text

Add alt text to the **substantive analytical visuals**, not decorative text boxes, separators, slicers, or static labels.

Use these:

| Visual | Recommended alt text |
|---|---|
| **Decision** | `Decision outcome for the selected merchant application and scenario, showing approved, review, or declined status and the specific decision outcome.` |
| **Merchant request** | `Application request details for the selected merchant and scenario, including application date, requested amount, use, channel, remittance rate, expected payoff period, and requested repayment.` |
| **Funded terms** | `Funded terms for the selected merchant application and scenario when funding was authorized, including funded amount, funding date, remittance rate, payback multiple, collection horizon, and total repayment.` |
| **Receivable trajectory** | `Remaining receivable balance across the funded account lifecycle for the selected merchant application and scenario.` |
| **Remittance performance** | `Cumulative remittance pace across the funded account lifecycle for the selected merchant application and scenario, compared with the 100 percent expected pace reference.` |
| **Monitoring journey** | `Monitoring status across the funded account lifecycle for the selected merchant application and scenario, ranging from paid off through current, watch, underperforming, and severe shortfall.` |
| **Monitoring exceptions** | `Elevated monitoring observations for the selected funded account and scenario, showing date, status, daily and cumulative shortfall, cumulative pace, and days since the last positive remittance.` |
| **Servicing & intervention** | `Governed servicing and intervention outcome for the selected funded account and scenario, including intervention, action, queue, recommended-action exposure, and primary intervention reason.` |

For the **left merchant-profile cards**, I would not individually alt-text every small card. They are simple contextual values and individually describing all of them would make screen-reader navigation worse rather than better.

---

### 2. Tooltips

We should distinguish charts from tables/cards.

For the three charts, I recommend:

**Receivable trajectory**
- Date
- Receivable balance
- Monitoring status
- Cumulative pace

**Remittance performance**
- Date
- Cumulative pace
- Monitoring status
- Daily shortfall
- Days since positive remittance

**Monitoring journey**
- Date
- Monitoring status
- Monitoring reason
- Cumulative pace

You already created the text measures needed for Monitoring journey.

For **Decision, Merchant request, Funded terms, Monitoring exceptions, and Servicing & intervention**, I would **not add elaborate custom tooltips**. The values are already directly visible. Native hover behavior is sufficient unless something is truncated.

One important principle: don't make a tooltip merely repeat every value already visible in a table.

---

### 3. Tab order

Go to:

**View → Selection → Tab order**

Then establish a logical reading sequence rather than accepting Power BI's construction order.

I recommend:

1. **Merchant slicer**
2. **Scenario slicer**
3. **Decision**
4. **Merchant request**
5. **Funded terms**
6. **Receivable trajectory**
7. **Remittance performance**
8. **Monitoring journey**
9. **Monitoring exceptions**
10. **Servicing & intervention**

For the merchant-profile cards, there are two defensible approaches. Given that they provide useful contextual information, I would put them **after the slicers and before Decision**, in their natural top-to-bottom order:

`Merchant → Industry → Size tier → Annual sales → Relationship stage → Relationship quality → Prior advances → Prior funded`

So the complete reading flow becomes:

**Controls → merchant context → decision/application/funding → financial lifecycle → monitoring lifecycle → exceptions/intervention.**

Decorative shapes, lines, titles, subtitles and footer text should be removed from tab order where Power BI allows it.

---

### 4. Footnote

The existing P02-derived language definitely needs to be replaced because this is no longer a fixed-cohort page.

I recommend the final P03 footer read:

> **Temporal boundary:** Lifecycle dates after 2026-07-23 reflect governed deterministic-synthetic forward monitoring through 2026-11-22, not additional realized source history; **Interpretation boundary:** Deterministic synthetic evidence.

That is accurate for the page we've constructed.

I would **not** mention “merchant relationship” or imply multiple applications in the footer. The page title/subtitle now correctly establish that this is one application/account journey.

One subtlety: because declined/review applications have no downstream funded lifecycle, the wording says **“Lifecycle dates after…”**, rather than implying every application necessarily has lifecycle observations.

### Final page identity

I would freeze the textual identity as:

**Tab:** `P03 - Application Journey`

**Title:** `Merchant Application & Account Journey`

**Subtitle:** `Follow one synthetic merchant application from request and decision through funding, performance, monitoring and servicing.`

**Footer:** the temporal/interpretation boundary above.

Once those four items are done, I would consider **presentation construction complete** and move directly into a short multi-merchant/scenario UAT rather than adding more visuals. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-16fcf72d-a5a6-4611-b514-4db026305dbc"></a>
## Andrew / user · C109-M00402

C109-M00402 · 2026-08-27T05:09:46.461000-04:00 · active path

Preceding visible parent: [C109-M00401](part-15.md#m-f730fa49-126a-40ec-866a-2e4aa4a59f07)

<!-- BEGIN_SOURCE_MESSAGE -->
For decision - we have two cards remember - what should the alt text be in both
<!-- END_SOURCE_MESSAGE -->


<a id="m-1951d0a3-cdd4-4eef-98c3-f4fd548cb364"></a>
## Assistant · C109-M00403

C109-M00403 · 2026-08-27T05:09:49.826762-04:00 · active path

Preceding visible parent: [C109-M00402](part-15.md#m-16fcf72d-a5a6-4611-b514-4db026305dbc)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. Since **Decision is implemented as two separate card visuals**, each should have its own alt text describing exactly what that card communicates.

For the large colored status card:

**`P03 Decision Display` — APPROVED / REVIEW / DECLINED**
> `Decision status for the selected merchant application and scenario, showing Approved, Review, or Declined.`

For the smaller detail card:

**`P03 Decision Detail` — Final offer / Counteroffer review / Evidence decline / Policy decline**
> `Specific decision outcome for the selected merchant application and scenario, such as final offer, counteroffer review, evidence decline, or policy decline.`

I prefer this over giving both cards identical alt text. The first communicates the **high-level disposition**, while the second communicates the **specific outcome**, matching what the sighted user gets from the two-level visual hierarchy.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7d7d7346-a4f1-4f72-a8a9-ca728e9e80b9"></a>
## Andrew / user · C109-M00404

C109-M00404 · 2026-08-27T05:14:05.109000-04:00 · active path

Preceding visible parent: [C109-M00403](part-15.md#m-1951d0a3-cdd4-4eef-98c3-f4fd548cb364)

<!-- BEGIN_SOURCE_MESSAGE -->
the left merchant profile is a multi card and requires only one alt text.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4088ad9b-8cde-49dc-94ac-5bfbbc37573c"></a>
## Assistant · C109-M00405

C109-M00405 · 2026-08-27T05:14:08.617285-04:00 · active path

Preceding visible parent: [C109-M00404](part-15.md#m-7d7d7346-a4f1-4f72-a8a9-ca728e9e80b9)

<!-- BEGIN_SOURCE_MESSAGE -->
Correct. Since the entire left Merchant Profile is **one multi-card visual**, it should have **one consolidated alt text**, not separate descriptions for each displayed field.

I recommend:

> **Merchant profile for the selected application, showing merchant ID, industry, size tier, annual sales band, relationship stage, relationship quality, prior advance count, and prior funded amount.**

That accurately describes the visual without trying to narrate the dynamically selected values.

So P03's alt-text inventory should be **9 visual objects total**:

1. Merchant Profile multi-card
2. Decision Status card
3. Decision Detail card
4. Merchant Request
5. Funded Terms
6. Receivable Trajectory
7. Remittance Performance
8. Monitoring Journey
9. Monitoring Exceptions
10. Servicing & Intervention

Correction: **10 total**—the two Decision cards make the count ten.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d3d80ea0-1702-4bec-b856-b7acdceedc31"></a>
## Andrew / user · C109-M00406

C109-M00406 · 2026-08-27T05:14:34.677000-04:00 · active path

Preceding visible parent: [C109-M00405](part-15.md#m-4088ad9b-8cde-49dc-94ac-5bfbbc37573c)

<!-- BEGIN_SOURCE_MESSAGE -->
what about the title alt text
<!-- END_SOURCE_MESSAGE -->


<a id="m-b9e56ac5-4fb4-4da0-a856-2e7b42830dab"></a>
## Assistant · C109-M00407

C109-M00407 · 2026-08-27T05:14:37.928783-04:00 · active path

Preceding visible parent: [C109-M00406](part-15.md#m-d3d80ea0-1702-4bec-b856-b7acdceedc31)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **The page-title text box should also have alt text**, especially because Audit previously caught stale title alt text on P01/P02.

For the P03 title/subtitle object, I recommend:

> **Merchant Application & Account Journey. Follow one synthetic merchant application from request and decision through funding, performance, monitoring and servicing.**

That should match the visible title/subtitle closely. I would **not add extra analytical explanation** to the title alt text; its purpose is to convey the same page identity a sighted user receives.

So P03 now has **11 alt-text objects**:

1. Title/subtitle
2. Merchant Profile
3. Decision Status
4. Decision Detail
5. Merchant Request
6. Funded Terms
7. Receivable Trajectory
8. Remittance Performance
9. Monitoring Journey
10. Monitoring Exceptions
11. Servicing & Intervention

The footer is static explanatory text and does **not** need separate alt text; its actual text should remain available to the screen reader.
<!-- END_SOURCE_MESSAGE -->


<a id="m-766f8aee-9591-4498-85dc-a4040bcb177a"></a>
## Andrew / user · C109-M00408

C109-M00408 · 2026-08-27T05:37:42.829000-04:00 · active path

Preceding visible parent: [C109-M00407](part-15.md#m-b9e56ac5-4fb4-4da0-a856-2e7b42830dab)

**Editorial record note:** 6 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 5ba81e0f-8995-4663-868d-ed284c61cd7e.png; ec8ae4cd-e511-4400-886d-8d59ca15bd48.png; 4e64e707-493b-46ad-a902-99e9171aa9bd.png; 8cdc120c-66f4-4be9-af7a-b0660f8ba70b.png; e9cbd422-7e54-49fa-8282-9cafaca2e0af.png; 2d8bfcbc-36e7-4604-9a59-46c7fc2dd354.png

<!-- BEGIN_SOURCE_MESSAGE -->
final review: 
<!-- END_SOURCE_MESSAGE -->


<a id="m-9af45f08-f370-45ea-adf0-b9df82c67625"></a>
## Assistant · C109-M00409

C109-M00409 · 2026-08-27T05:37:46.725667-04:00 · active path

Preceding visible parent: [C109-M00408](part-15.md#m-766f8aee-9591-4498-85dc-a4040bcb177a)

<!-- BEGIN_SOURCE_MESSAGE -->
This is ready for closeout. Across the six UAT states, the page is behaving coherently and the renamed **Merchant Application & Account Journey** is a substantially better description of what the model actually supports.

The strongest validation is that the page now handles fundamentally different paths correctly: funded/paid-off merchant 000749, funded/severe-shortfall merchant 000312, counteroffer review, evidence decline, policy decline with prior relationship history, and a scenario-dependent change for 000749 from Baseline approval to Recession Energy review. The blank downstream lifecycle for non-funded paths reads naturally because the decision card explains why the journey stops.

I have only **three final changes/checks** before calling P03 complete:

1. **Remove the Total row from `Monitoring exceptions`.** This is the one visible item I would definitely change. Summing daily shortfall across exception dates may have a mathematical interpretation, but `Cumulative shortfall`, `Pace`, and `Days since remittance` do not form a coherent table total. In the screenshots, `112.19%` and `6` under Total are especially misleading. Turn **Totals/Grand total = Off** for this visual.

2. **Tooltips:** your three lifecycle charts should carry the useful contextual fields we established. Receivable Trajectory should expose Date, receivable balance, monitoring status, and cumulative pace; Remittance Performance should expose Date, cumulative pace, monitoring status, daily shortfall, and days since positive remittance; Monitoring Journey should expose Date, monitoring status, monitoring reason, and cumulative pace. The tables/cards do not need redundant custom tooltip work.

3. **Tab order:** verify the final order after all the recent construction. I would use: Merchant slicer → Scenario slicer → Merchant Profile → Merchant Request → Decision Status → Decision Detail → Funded Terms → Receivable Trajectory → Monitoring Journey → Remittance Performance → Monitoring Exceptions → Servicing & Intervention. The precise ordering of Receivable versus Monitoring isn't critical; what matters is that navigation follows the visible analytical story and doesn't wander through decorative objects.

### Footnote: confirmed

I would retain exactly what you now show:

> **Temporal boundary:** Lifecycle dates after 2026-07-23 reflect governed deterministic-synthetic forward monitoring through 2026-11-22, not additional realized source history; **Interpretation boundary:** Deterministic synthetic evidence

That is materially accurate and avoids the obsolete P01/P02 cohort wording.

The provenance line immediately above it also remains appropriate:

**Run | Source release | Model version | Observed-source cutoff**

### One thing I would *not* change

Don't try to make the empty charts disappear for REVIEW/DECLINED applications. Their fixed framework actually helps: the user sees the decision stopping the journey, while the empty funded/performance sections make the absence of a funded account visually obvious. The colored decision card supplies the explanation.

And the 000311 case is particularly valuable: **RETURNING GOOD, Tier 1, three prior advances, $38.1K prior funded — yet Policy decline on this application.** That demonstrates why the merchant context rail belongs on an application-level page even though we correctly rejected the “Relationship 360” title.

So: **turn off Monitoring Exceptions totals, verify tooltips and tab order, and I would freeze P03.** I don't see another substantive visual or design change that improves this page enough to justify additional construction.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8d763fec-1b7a-488a-a6f8-9e98d2397658"></a>
## Andrew / user · C109-M00410

C109-M00410 · 2026-08-27T05:40:50.976000-04:00 · active path

Preceding visible parent: [C109-M00409](part-15.md#m-9af45f08-f370-45ea-adf0-b9df82c67625)

<!-- BEGIN_SOURCE_MESSAGE -->
done. let's freeze P03 and capture evidence. what are the next steps then? can we begin crafting P04? and knowing the additional context from our build about where we stand at the end of Module 2, how does that change our current and future build plans?
<!-- END_SOURCE_MESSAGE -->


<a id="m-639540e2-540b-43a9-83c6-f9d1d87bdfcb"></a>
## Assistant · C109-M00411

C109-M00411 · 2026-08-27T05:40:54.411728-04:00 · active path

Preceding visible parent: [C109-M00410](part-15.md#m-8d763fec-1b7a-488a-a6f8-9e98d2397658)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. P03 should now be **frozen as the accepted construction candidate**, evidence captured, and then we should move directly into P04 rather than returning to Audit. The governing audit authorization explicitly permits one coherent current-model-supported wave and says to return **once at wave freeze**, not page-by-page. [export reference: memcite]

The Module 2 discovery does, however, change what I think P04–P07 should be.

### Immediate closeout for P03

Capture a small, representative evidence set rather than documenting every merchant permutation. I would preserve: the final page at **000749 / Baseline** showing the complete funded/paid-off journey; **000312 / Baseline** showing the severe-shortfall/intervention path; one **REVIEW** path; one **DECLINED** path; and **000749 / Recession Energy** showing that scenario selection can change the application outcome. Also capture the final Selection/Tab Order pane and representative alt-text/tooltips if those aren't already evidenced.

Then save the PBIP/project and record the P03 delta: newly exposed `FactAccountDaily` and `FactIntervention`, report-owned measures/calculated presentation columns, page construction, and the deliberate rename from the originally contemplated Merchant Relationship 360 to **Application & Account Journey**. That last point is worth documenting explicitly because it is an evidence-driven scope correction, not an abandoned feature.

## Yes, begin P04 immediately

But I would **not automatically build the next page under our old page numbering/concept sequence**.

Our original authorized current-model wave was:

- Merchant Relationship 360
- Application & Account Journey
- Servicing & Exceptions
- Risk, Economics & Concentration
- Governance & Reconciliation

Physical construction has now demonstrated that the first two are **not independently supported experiences at the end of Module 2**. P03 consumed the useful merchant context and the complete singular application/account journey in one page.

So I recommend that **P04 become Servicing & Exceptions**.

That means the current report roadmap becomes:

| Page | Revised experience | Status |
|---|---|---|
| P01 | Cohort Command Center | Frozen/accepted |
| P02 | Cohort Lifecycle | Frozen/accepted |
| P03 | Application Journey | **Freeze now** |
| P04 | Servicing & Exceptions | **Build next** |
| P05 | Risk, Economics & Concentration | Current-wave candidate |
| P06 | Governance & Reconciliation | Current-wave candidate |

I would **not create an empty placeholder P04 called Merchant Relationship 360** merely to preserve an obsolete numbering plan. The page numbers are presentation metadata; Audit expressly gave us discretion over page names and tab order within the accepted boundary. [export reference: memcite]

### What P04 should now accomplish

P03 showed us servicing at the **single-account level**. P04 should zoom back out and answer the operational-management question:

> **Where does the portfolio require attention, what is driving that attention, how severe is it, and what governed action/review path follows?**

The current Module 2 model is actually well positioned for this. Year 1 explicitly calls for daily remittance reconciliation, early-warning statuses, explicit exception/manual-review governance, and basic account-management actions. [export reference: filecite | turn46file0 | L42-L52] It also defines performance measures around interruption, shortfall, payoff slippage, workout entry, default/recovery and related monitoring. [export reference: filecite | turn46file0 | L158-L167]

So P04 can be a very strong **operational portfolio triage page** without pretending we have longitudinal multi-application merchant relationships.

I would envision its story at a high level as:

**Workload now → severity and drivers → exposure requiring attention → intervention/queue → account drill-down**

And P03 becomes the natural drill target: find a problematic account on P04, then investigate its full application/account journey on P03.

That is a much stronger report architecture than the original abstract roadmap.

## How the Module 2 discovery changes the future roadmap

The biggest change is that we should now distinguish **three analytical generations** rather than treating every desirable page as something the current model ought to support.

**End-of-Module-2 / current wave:** exploit the current single-application population deeply. P03 Application Journey, P04 Servicing & Exceptions, P05 Risk/Economics/Concentration, and P06 Governance/Reconciliation are appropriate. These are essentially different lenses over the governed launch population.

**Module 3 / longitudinal portfolio expansion:** this is where we should introduce additional application generations and genuine relationship history. A merchant can return, reapply, receive another advance, renew, be declined after prior successful borrowing, move between relationship stages, accumulate multiple closed/current accounts, and generate treatment histories. That is where **Merchant Relationship 360** becomes real rather than cosmetic. This is consistent with the roadmap's Years 2–3 emphasis on differentiating new, repeat, renewed and previously distressed merchants, prequalified renewals, treatment effectiveness, and merchant lifetime/relationship value. [export reference: filecite | turn46file0 | L206-L220] [export reference: filecite | turn47file0 | L18-L49]

**Later strategic maturity:** true relationship optimization belongs even farther out. The roadmap explicitly says Years 3–5 transform the portfolio from reactive application decisioning into proactive merchant-relationship and capital management, including relationship-level profitability/value, broader facilities, retention offers and cross-product opportunities. [export reference: filecite | turn47file0 | L64-L97]

That gives us a much cleaner destination for several pages we had already envisioned:

- **Merchant Relationship 360** → defer to Module 3 longitudinal population.
- **Cohort Comparison** → defer until multiple governed cohorts/vintages actually exist.
- **Current Portfolio Command Center** → defer until there is a replenishing multi-cohort portfolio with a governed calendar-date boundary.
- **Portfolio Focus & Next-Month Action** → still requires an accepted recommendation methodology.
- **Strategy & Scenario Laboratory** → still requires the matched strategy/scenario method.

And importantly, those deferred pages become **better**, not merely later. Merchant Relationship 360 eventually shows multiple applications and advances. Cohort Comparison compares genuine vintages. Current Portfolio Command Center shows a living book with originations, payoffs, repeat borrowing and changing composition rather than pretending one static launch cohort is a replenishing portfolio.

### This also clarifies the portfolio narrative

There is now a compelling progression in the GitHub project itself:

**Module 1/2:** Can we build and govern a launch population, make decisions, fund accounts, monitor daily performance, identify deterioration and execute controlled servicing?

**Module 3:** What happens when the business becomes longitudinal—new cohorts enter, merchants return, accounts open and close, renewals occur, losses season, and the portfolio evolves through calendar time?

**Later strategy:** How do we optimize merchant relationships, capital, pricing and strategy across that accumulated history?

That is substantially more credible than trying to make the current 750 single-application merchants simulate every future maturity state. The enterprise roadmap itself says advancement is determined by capability/evidence gates, **not simply calendar passage**. [export reference: filecite | turn47file0 | L187-L189]

So my recommended sequence is: **freeze/evidence P03 now → begin P04 Servicing & Exceptions immediately → then P05 Risk, Economics & Concentration → P06 Governance & Reconciliation → freeze the coherent current-model wave → return once to Independent Audit.**

And before drawing P04, I would do exactly what worked so well on P03: **inspect the physical servicing/exception tables first, then let the available grains tell us what the page should become.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-e85cba94-1161-4880-8316-2bf1fc95eb5d"></a>
## Andrew / user · C109-M00412

C109-M00412 · 2026-08-27T05:43:10.871000-04:00 · active path

Preceding visible parent: [C109-M00411](part-15.md#m-639540e2-540b-43a9-83c6-f9d1d87bdfcb)

<!-- BEGIN_SOURCE_MESSAGE -->
I actually like that simplified current roadmap for where we stand at end of Module 2. I think we can only squeeze so much juice out of the lemon at this point. we will have more to work with once our module 3 and campaign chats progress.
<!-- END_SOURCE_MESSAGE -->


<a id="m-49681769-3c1d-4990-9604-3636fcaddc0f"></a>
## Assistant · C109-M00413

C109-M00413 · 2026-08-27T05:43:14.156011-04:00 · active path

Preceding visible parent: [C109-M00412](part-15.md#m-e85cba94-1161-4880-8316-2bf1fc95eb5d)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree. The simplified roadmap is stronger precisely because it respects what **Module 2 actually proves** instead of trying to manufacture additional report depth from a finite synthetic population.

At this point we have extracted the most useful perspectives from the current model:

**P01 — Cohort Command Center**  
Executive point-in-time view of the fixed launch cohort.

**P02 — Cohort Lifecycle**  
Longitudinal view of how that fixed cohort performs through time.

**P03 — Application Journey**  
Application-level trace from merchant context and request through decision, funding, account performance, monitoring and intervention.

**P04 — Servicing & Exceptions**  
Portfolio-level operational triage: where attention is required, why, against what exposure, and through what governed intervention path.

**P05 — Risk, Economics & Concentration**  
Portfolio segmentation: where risk, economic value and concentrations reside across the current population.

**P06 — Governance & Reconciliation**  
Evidence/control layer: whether results trace, reconcile and remain within their governed boundaries.

That's a coherent **end-of-Module-2 Power BI product**. Each page answers a genuinely different management question.

More importantly, stopping there avoids creating pages that look sophisticated but are analytically repetitive. The roadmap itself anticipates richer capabilities only as observed performance, repeat/renewal behavior, merchant-health treatment, and relationship value mature. [export reference: filecite | turn46file0 | L206-L220] [export reference: filecite | turn47file0 | L18-L49]

Then Module 3 and the campaign-scale work can give us the raw material for the next Power BI generation: multiple vintages, replenishing portfolio populations, repeat applications, multiple advances per merchant, opening and closing accounts, renewals, more mature losses/recoveries, and longer histories. At that point **Cohort Comparison, Current Portfolio Command Center, and Merchant Relationship 360** become genuinely new analytical products rather than alternative presentations of today's 750 applications.

I would therefore treat **P06 as the natural stopping point for the current report generation**. Once P04–P06 are built and UAT'd, we freeze the whole report-depth wave, return once to Audit, and pursue the publication/release gate. Meanwhile, later modules can expand the underlying analytical universe before we add the next family of pages.

That gives us a useful design discipline going forward:

> **Build a new page when new data/grain/method supports a new management question—not merely because another dashboard can be made.**

For now, P03 is frozen. **Next is P04 — Servicing & Exceptions**, and I would start exactly as we did with P03: inspect the physical servicing, intervention, monitoring, alert, exposure and exception structures first, then design the page around what the model actually contains. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-7b2e6f7f-ddff-4a36-a99a-b9bc253dc3b4"></a>
## Andrew / user · C109-M00414

C109-M00414 · 2026-08-27T05:58:43.798000-04:00 · active path

Preceding visible parent: [C109-M00413](part-15.md#m-49681769-3c1d-4990-9604-3636fcaddc0f)

**Editorial record note:** Attachment references: P03_Evidence_Capture.zip

<!-- BEGIN_SOURCE_MESSAGE -->
P03 evidence capture attached. help me craft powershell commands to tackle: Then save the PBIP/project and record the P03 delta: newly exposed `FactAccountDaily` and `FactIntervention`, report-owned measures/calculated presentation columns, page construction, and the deliberate rename from the originally contemplated Merchant Relationship 360 to **Application & Account Journey**. That last point is worth documenting explicitly because it is an evidence-driven scope correction, not an abandoned feature.     NOTE: I've saved the PBIP/project.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5be69f90-ee1f-4a89-8d99-2a8c6bed3779"></a>
## Assistant · C109-M00415

C109-M00415 · 2026-08-27T05:59:36.212247-04:00 · active path

Preceding visible parent: [C109-M00414](part-15.md#m-7b2e6f7f-ddff-4a36-a99a-b9bc253dc3b4)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Since the PBIP/project is already saved, the next task is to create a **P03 freeze record** around that saved physical state—not alter the model further.

I inspected the attached evidence ZIP. It contains **10 P03 screenshots**, covering merchants 001, 012, 312, 738, and 749 across Baseline/Recession Energy, including dedicated captures for tab order, alt text, and tooltips. That is a strong representative UAT set for the freeze.

I would do this in PowerShell in four steps: preserve the screenshots, fingerprint the saved project, capture the P03 semantic/report delta, and write a concise freeze note.

### 1. Start the PowerShell session and establish paths

Use your existing project root:

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\project"
$FreezeRoot  = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\evidence\P03_FREEZE"
$EvidenceZip = "C:\PATH\TO\P03_Evidence_Capture.zip"

New-Item -ItemType Directory -Force -Path $FreezeRoot | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\screenshots" | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\delta" | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\manifests" | Out-Null
```

Change only `$EvidenceZip` to wherever you saved the ZIP locally.

### 2. Preserve and hash the P03 screenshot evidence

```powershell
Copy-Item $EvidenceZip "$FreezeRoot\P03_Evidence_Capture.zip" -Force

Expand-Archive `
    -Path "$FreezeRoot\P03_Evidence_Capture.zip" `
    -DestinationPath "$FreezeRoot\screenshots" `
    -Force

Get-FileHash "$FreezeRoot\P03_Evidence_Capture.zip" -Algorithm SHA256 |
    Select-Object Path, Hash |
    Export-Csv "$FreezeRoot\manifests\P03_EVIDENCE_ZIP_SHA256.csv" -NoTypeInformation

Get-ChildItem "$FreezeRoot\screenshots" -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash $_.FullName -Algorithm SHA256
        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($FreezeRoot.Length + 1)
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLower()
        }
    } |
    Export-Csv "$FreezeRoot\manifests\P03_SCREENSHOT_MANIFEST.csv" -NoTypeInformation
```

Then confirm the population:

```powershell
Get-ChildItem "$FreezeRoot\screenshots" -Recurse -File |
    Select-Object Name, Length
```

You should see your 10 captures.

### 3. Fingerprint the saved PBIP project

This gives us the exact physical state at the P03 freeze:

```powershell
Get-ChildItem $ProjectRoot -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash $_.FullName -Algorithm SHA256
        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($ProjectRoot.Length + 1)
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLower()
        }
    } |
    Export-Csv "$FreezeRoot\manifests\P03_PROJECT_FILE_MANIFEST.csv" -NoTypeInformation
```

Create a deterministic aggregate project-root hash from that manifest:

```powershell
$ManifestText = Get-Content "$FreezeRoot\manifests\P03_PROJECT_FILE_MANIFEST.csv" -Raw
$Bytes = [System.Text.Encoding]::UTF8.GetBytes($ManifestText)
$Hash  = [System.Security.Cryptography.SHA256]::Create().ComputeHash($Bytes)
$RootHash = ([System.BitConverter]::ToString($Hash)).Replace("-", "").ToLower()

"Project manifest root SHA-256: $RootHash" |
    Set-Content "$FreezeRoot\manifests\P03_PROJECT_ROOT_SHA256.txt"

Get-Content "$FreezeRoot\manifests\P03_PROJECT_ROOT_SHA256.txt"
```

That gives us a reproducible identity for the **saved post-P03 project state**.

### 4. Capture the actual P03 delta from the physical PBIP

First, capture every project occurrence relevant to P03 and the two newly exposed facts:

```powershell
$Patterns = @(
    "P03",
    "Application Journey",
    "Merchant Application & Account Journey",
    "Merchant Relationship 360",
    "FactAccountDaily",
    "FactIntervention"
)

Get-ChildItem $ProjectRoot -Recurse -File |
    Where-Object {
        $_.Extension -in ".tmdl", ".json", ".pbir", ".bim", ".pbip"
    } |
    Select-String -Pattern $Patterns -SimpleMatch |
    Select-Object Path, LineNumber, Line |
    Export-Csv "$FreezeRoot\delta\P03_PHYSICAL_DELTA_REFERENCES.csv" -NoTypeInformation
```

That gives Audit a machine-readable trail showing where P03, the exposed facts, and the renamed experience physically occur.

I would also produce a human-readable copy:

```powershell
Get-ChildItem $ProjectRoot -Recurse -File |
    Where-Object {
        $_.Extension -in ".tmdl", ".json", ".pbir", ".bim", ".pbip"
    } |
    Select-String -Pattern $Patterns -SimpleMatch |
    Format-Table Path, LineNumber, Line -AutoSize |
    Out-String -Width 4096 |
    Set-Content "$FreezeRoot\delta\P03_PHYSICAL_DELTA_REFERENCES.txt"
```

### 5. Create the P03 freeze/delta note

This is the part I particularly want preserved for Audit. Run:

```powershell
@'
# P03 — Application Journey Construction Freeze

## Freeze status

P03 construction is frozen following physical Power BI construction and representative UAT.

Final tab name:

P03 - Application Journey

Final page title:

Merchant Application & Account Journey

Final page purpose:

Follow one synthetic merchant application from request and decision through funding, performance, monitoring and servicing.

## Evidence-driven scope correction

The experience was originally contemplated as Merchant Relationship 360.

Physical construction and source/model inspection established that the current end-of-Module-2 governed population does not yet contain longitudinal multiple-application merchant histories. The current application population represents distinct merchants, with the operative application-level relationship effectively one merchant to zero or one application.

Merchant-level attributes such as prior advance count, prior funded amount, relationship stage and relationship quality therefore provide prior-relationship context for the current application but do not constitute navigable prior application/account histories in the current governed population.

Accordingly, the constructed page was deliberately reframed as Application Journey rather than overstating the current model as a longitudinal Merchant Relationship 360 experience.

This is an evidence-driven scope correction, not an abandoned report capability. A true Merchant Relationship 360 remains a future longitudinal-product experience once later modules introduce multiple applications, advances, renewals, closures and repeat merchant cycles.

## Physical construction delta

P03 introduced or used the following report-owned presentation changes within the accepted source/model boundary:

- FactAccountDaily made visible for report construction.
- FactIntervention made visible for report construction.
- No source or Power Query business transformation was introduced through those visibility changes.
- No accepted governed-measure formula was overwritten.
- Report-owned explicit measures were added where required because implicit measures are discouraged in the semantic model.
- Report-owned calculated presentation columns were added for readable application, decision, servicing and intervention labels.
- Merchant selector presentation was simplified to the merchant numeric suffix.
- Decision outcome was elevated into a two-level conditionally formatted status/detail presentation.
- Merchant request and funded terms were separated to distinguish requested structure from funded structure.
- Daily receivable, remittance and monitoring lifecycle experiences were constructed from the governed daily-account population.
- Monitoring exceptions and servicing/intervention experiences were constructed from their appropriate physical grains.
- Accessibility alt text, analytical tooltips and logical tab order were completed.
- The page temporal and interpretation boundary was updated to application/account-lifecycle semantics.

## Final analytical contract

The page presents one selected synthetic merchant application under one selected scenario.

The page may show:

1. merchant relationship context;
2. current application request;
3. governed decision outcome;
4. funded terms when an advance is funded;
5. receivable trajectory;
6. remittance performance;
7. monitoring-state journey;
8. monitoring exceptions; and
9. servicing/intervention outcome.

Review or declined applications appropriately have no funded-account lifecycle.

## Temporal boundary

Lifecycle dates after 2026-07-23 reflect governed deterministic-synthetic forward monitoring through 2026-11-22, not additional realized source history.

Interpretation boundary: Deterministic synthetic evidence.

## Evidence population

Representative P03 screenshots are retained in the accompanying P03 evidence package and include:

- funded / paid-off paths;
- funded / adverse-monitoring and intervention paths;
- counteroffer-review paths;
- evidence-decline paths;
- policy-decline paths;
- Baseline and Recession Energy scenario behavior;
- accessibility alt-text evidence;
- tooltip evidence; and
- tab-order evidence.

## Next construction authority

P03 is frozen. Continue the authorized current-model report-depth wave with P04 — Servicing & Exceptions. Do not reopen P03 absent a material defect, hard-stop condition or later coherent-wave remediation need.
'@ | Set-Content "$FreezeRoot\P03_CONSTRUCTION_FREEZE_AND_DELTA.md"
```

Then inspect it:

```powershell
Get-Content "$FreezeRoot\P03_CONSTRUCTION_FREEZE_AND_DELTA.md"
```

### 6. Final freeze inventory

Finally:

```powershell
Get-ChildItem $FreezeRoot -Recurse -File |
    Sort-Object FullName |
    Select-Object `
        @{N="RelativePath";E={$_.FullName.Substring($FreezeRoot.Length + 1)}},
        Length |
    Export-Csv "$FreezeRoot\P03_FREEZE_INVENTORY.csv" -NoTypeInformation

Get-ChildItem $FreezeRoot -Recurse -File |
    Select-Object FullName, Length
```

At that point I would regard **P03 as formally frozen for this construction wave**.

One note on the delta language: I intentionally characterize exposing `FactAccountDaily` and `FactIntervention` as **visibility/presentation changes**, not new semantic methods. That is the accurate description of what we did, and it keeps the Audit submission aligned with the streamlined operating model.

After you run these commands, **do not package the entire audit submission yet**. We should preserve this P03 freeze evidence, then begin **P04 — Servicing & Exceptions**. P03–P06 will ultimately be bundled into one coherent next-wave freeze and returned to Audit once, which is exactly the cadence Audit authorized. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-de5603ca-ec10-450c-a3df-fac3c66f0f7a"></a>
## Andrew / user · C109-M00416

C109-M00416 · 2026-08-27T06:13:50.082000-04:00 · active path

Preceding visible parent: [C109-M00415](part-15.md#m-5be69f90-ee1f-4a89-8d99-2a8c6bed3779)

<!-- BEGIN_SOURCE_MESSAGE -->
I saved P03_Evidence_Capture.zip to C:\MSBF - please update all powershell commands
<!-- END_SOURCE_MESSAGE -->


<a id="m-2b42d90b-0519-44dd-9fd7-06374110c335"></a>
## Assistant · C109-M00417

C109-M00417 · 2026-08-27T06:13:53.396168-04:00 · active path

Preceding visible parent: [C109-M00416](part-15.md#m-de5603ca-ec10-450c-a3df-fac3c66f0f7a)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. With the evidence ZIP at `C:\MSBF\P03_Evidence_Capture.zip`, use the following updated sequence. I also tightened two things from my prior commands: the freeze directory is kept **outside the PBIP project tree**, so its own evidence cannot contaminate the project manifest, and the project-root calculation uses a canonical `relative-path|bytes|sha256` stream rather than hashing the CSV serialization.

### 1. Initialize the session and paths

```powershell
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$ProjectRoot = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\project"
$FreezeRoot  = "C:\MSBF\PBI_WP3_P01_CONSTRUCTION_R1\evidence\P03_FREEZE"
$EvidenceZip = "C:\MSBF\P03_Evidence_Capture.zip"

New-Item -ItemType Directory -Force -Path $FreezeRoot | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\screenshots" | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\delta" | Out-Null
New-Item -ItemType Directory -Force -Path "$FreezeRoot\manifests" | Out-Null

Write-Host "Project:  $ProjectRoot"
Write-Host "Evidence: $EvidenceZip"
Write-Host "Freeze:   $FreezeRoot"
```

Verify both controlling inputs exist:

```powershell
if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    throw "Project root not found: $ProjectRoot"
}

if (-not (Test-Path -LiteralPath $EvidenceZip)) {
    throw "Evidence ZIP not found: $EvidenceZip"
}

Write-Host "Inputs verified." -ForegroundColor Green
```

---

## 2. Preserve and extract the P03 evidence package

```powershell
Copy-Item `
    -LiteralPath $EvidenceZip `
    -Destination "$FreezeRoot\P03_Evidence_Capture.zip" `
    -Force

if (Test-Path -LiteralPath "$FreezeRoot\screenshots") {
    Remove-Item "$FreezeRoot\screenshots" -Recurse -Force
}

New-Item -ItemType Directory -Force -Path "$FreezeRoot\screenshots" | Out-Null

Expand-Archive `
    -LiteralPath "$FreezeRoot\P03_Evidence_Capture.zip" `
    -DestinationPath "$FreezeRoot\screenshots" `
    -Force
```

Hash the original evidence carrier:

```powershell
Get-FileHash `
    -LiteralPath "$FreezeRoot\P03_Evidence_Capture.zip" `
    -Algorithm SHA256 |
    Select-Object `
        @{N="Path";E={$_.Path}},
        @{N="SHA256";E={$_.Hash.ToLowerInvariant()}} |
    Export-Csv `
        "$FreezeRoot\manifests\P03_EVIDENCE_ZIP_SHA256.csv" `
        -NoTypeInformation
```

Create the screenshot manifest:

```powershell
Get-ChildItem "$FreezeRoot\screenshots" -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256

        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($FreezeRoot.Length + 1)
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLowerInvariant()
        }
    } |
    Export-Csv `
        "$FreezeRoot\manifests\P03_SCREENSHOT_MANIFEST.csv" `
        -NoTypeInformation
```

Check what was extracted:

```powershell
Get-ChildItem "$FreezeRoot\screenshots" -Recurse -File |
    Select-Object Name, Length |
    Format-Table -AutoSize
```

---

## 3. Fingerprint the exact saved PBIP/project

```powershell
$ProjectManifest = Get-ChildItem $ProjectRoot -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256

        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($ProjectRoot.Length + 1).Replace("\","/")
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLowerInvariant()
        }
    }

$ProjectManifest |
    Export-Csv `
        "$FreezeRoot\manifests\P03_PROJECT_FILE_MANIFEST.csv" `
        -NoTypeInformation
```

Now create the canonical project-manifest root:

```powershell
$CanonicalLines = $ProjectManifest | ForEach-Object {
    "$($_.RelativePath)|$($_.Bytes)|$($_.SHA256)"
}

$CanonicalText = ($CanonicalLines -join "`n") + "`n"

[System.IO.File]::WriteAllText(
    "$FreezeRoot\manifests\P03_PROJECT_MANIFEST_CANONICAL.txt",
    $CanonicalText,
    [System.Text.UTF8Encoding]::new($false)
)

$RootHash = (
    Get-FileHash `
        -LiteralPath "$FreezeRoot\manifests\P03_PROJECT_MANIFEST_CANONICAL.txt" `
        -Algorithm SHA256
).Hash.ToLowerInvariant()

"Project manifest root SHA-256: $RootHash" |
    Set-Content `
        "$FreezeRoot\manifests\P03_PROJECT_ROOT_SHA256.txt" `
        -Encoding UTF8

Get-Content "$FreezeRoot\manifests\P03_PROJECT_ROOT_SHA256.txt"
```

That `$RootHash` is the identifier I want us to retain as the **P03 frozen-project identity**.

---

## 4. Capture physical references to the P03 delta

Use:

```powershell
$Patterns = @(
    "P03",
    "Application Journey",
    "Merchant Application & Account Journey",
    "Merchant Relationship 360",
    "FactAccountDaily",
    "FactIntervention"
)

$DeltaRefs = Get-ChildItem $ProjectRoot -Recurse -File |
    Where-Object {
        $_.Extension -in ".tmdl", ".json", ".pbir", ".bim", ".pbip"
    } |
    Select-String -Pattern $Patterns -SimpleMatch

$DeltaRefs |
    Select-Object Path, LineNumber, Line |
    Export-Csv `
        "$FreezeRoot\delta\P03_PHYSICAL_DELTA_REFERENCES.csv" `
        -NoTypeInformation

$DeltaRefs |
    Format-Table Path, LineNumber, Line -AutoSize |
    Out-String -Width 4096 |
    Set-Content `
        "$FreezeRoot\delta\P03_PHYSICAL_DELTA_REFERENCES.txt" `
        -Encoding UTF8
```

Quickly inspect it:

```powershell
Get-Content "$FreezeRoot\delta\P03_PHYSICAL_DELTA_REFERENCES.txt"
```

Don't worry if `Merchant Relationship 360` produces no current report-definition hit. We **want** the final physical report to say `Merchant Application & Account Journey`; the former name belongs in the documented scope-correction record.

---

## 5. Create the P03 freeze and delta record

```powershell
@'
# P03 — Application Journey Construction Freeze

## Freeze status

P03 construction is frozen following physical Power BI construction and representative UAT.

Final tab name:

P03 - Application Journey

Final page title:

Merchant Application & Account Journey

Final page purpose:

Follow one synthetic merchant application from request and decision through funding, performance, monitoring and servicing.

## Evidence-driven scope correction

The experience was originally contemplated as Merchant Relationship 360.

Physical construction and source/model inspection established that the current end-of-Module-2 governed population does not yet contain longitudinal multiple-application merchant histories. The current application population represents distinct merchants, with the operative application-level relationship effectively one merchant to zero or one application.

Merchant-level attributes such as prior advance count, prior funded amount, relationship stage and relationship quality therefore provide prior-relationship context for the current application but do not constitute navigable prior application/account histories in the current governed population.

Accordingly, the constructed page was deliberately reframed as Application Journey rather than overstating the current model as a longitudinal Merchant Relationship 360 experience.

This is an evidence-driven scope correction, not an abandoned report capability. A true Merchant Relationship 360 remains a future longitudinal-product experience once later modules introduce multiple applications, advances, renewals, closures and repeat merchant cycles.

## Physical construction delta

P03 introduced or used the following report-owned presentation changes within the accepted source/model boundary:

- FactAccountDaily was made visible for report construction.
- FactIntervention was made visible for report construction.
- No source or Power Query business transformation was introduced through those visibility changes.
- No accepted governed-measure formula was overwritten.
- Report-owned explicit measures were added where required because implicit measures are discouraged in the semantic model.
- Report-owned calculated presentation columns were added for readable merchant, application, decision, servicing and intervention presentation.
- Merchant selector presentation was simplified to the merchant numeric suffix.
- Decision outcome was elevated into a two-level conditionally formatted status/detail presentation.
- Merchant request and funded terms were separated to distinguish requested structure from funded structure.
- Daily receivable, remittance and monitoring lifecycle experiences were constructed from the governed daily-account population.
- Monitoring exceptions and servicing/intervention experiences were constructed from their appropriate physical grains.
- Accessibility alt text, analytical tooltips and logical tab order were completed.
- The page temporal and interpretation boundary was updated to application/account-lifecycle semantics.

## Final analytical contract

The page presents one selected synthetic merchant application under one selected scenario.

The page may show:

1. merchant relationship context;
2. current application request;
3. governed decision outcome;
4. funded terms when an advance is funded;
5. receivable trajectory;
6. remittance performance;
7. monitoring-state journey;
8. monitoring exceptions; and
9. servicing/intervention outcome.

Review or declined applications appropriately have no funded-account lifecycle.

## Temporal boundary

Lifecycle dates after 2026-07-23 reflect governed deterministic-synthetic forward monitoring through 2026-11-22, not additional realized source history.

Interpretation boundary: Deterministic synthetic evidence.

## Evidence population

Representative P03 screenshots are retained in the accompanying P03 evidence package and include:

- funded / paid-off paths;
- funded / adverse-monitoring and intervention paths;
- counteroffer-review paths;
- evidence-decline paths;
- policy-decline paths;
- Baseline and Recession Energy scenario behavior;
- accessibility alt-text evidence;
- tooltip evidence; and
- tab-order evidence.

## Next construction state

P03 is frozen as the current construction candidate.

Continue the authorized current-model report-depth wave with P04 — Servicing & Exceptions. Do not reopen P03 absent a material defect, hard-stop condition or later coherent-wave remediation need.
'@ |
    Set-Content `
        "$FreezeRoot\P03_CONSTRUCTION_FREEZE_AND_DELTA.md" `
        -Encoding UTF8
```

Inspect it:

```powershell
Get-Content "$FreezeRoot\P03_CONSTRUCTION_FREEZE_AND_DELTA.md"
```

---

## 6. Record the project root inside the freeze note

Rather than manually copying the hash, append it:

```powershell
@"

## Frozen physical project identity

Project root:

$ProjectRoot

Project manifest root SHA-256:

$RootHash
"@ |
    Add-Content `
        "$FreezeRoot\P03_CONSTRUCTION_FREEZE_AND_DELTA.md" `
        -Encoding UTF8
```

---

## 7. Build the final P03 freeze inventory

Do this **last**, after all other freeze files have been created:

```powershell
$FreezeInventory = Get-ChildItem $FreezeRoot -Recurse -File |
    Where-Object {
        $_.FullName -ne "$FreezeRoot\P03_FREEZE_INVENTORY.csv"
    } |
    Sort-Object FullName |
    ForEach-Object {
        $h = Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256

        [PSCustomObject]@{
            RelativePath = $_.FullName.Substring($FreezeRoot.Length + 1).Replace("\","/")
            Bytes        = $_.Length
            SHA256       = $h.Hash.ToLowerInvariant()
        }
    }

$FreezeInventory |
    Export-Csv `
        "$FreezeRoot\P03_FREEZE_INVENTORY.csv" `
        -NoTypeInformation
```

And inspect the final package:

```powershell
Get-ChildItem $FreezeRoot -Recurse -File |
    Sort-Object FullName |
    Select-Object FullName, Length |
    Format-Table -AutoSize
```

Finally, run:

```powershell
Write-Host ""
Write-Host "P03 FREEZE COMPLETE" -ForegroundColor Green
Write-Host "Project manifest root: $RootHash"
Write-Host "Freeze evidence root: $FreezeRoot"
Write-Host ""
```

At that point, **leave `P03_FREEZE` untouched**. We don't need to ZIP it yet. It becomes the frozen P03 evidence component that will eventually sit inside the combined P03–P06 current-wave audit package.

Then we can move directly into **P04 — Servicing & Exceptions**, starting with physical inspection of the Module 2 servicing/exception structures rather than designing the page abstractly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-8daf0c6d-7486-4eb4-87fe-707c1a620dcd"></a>
## Andrew / user · C109-M00418

C109-M00418 · 2026-08-27T06:21:50.141000-04:00 · active path

Preceding visible parent: [C109-M00417](part-15.md#m-2b42d90b-0519-44dd-9fd7-06374110c335)

<!-- BEGIN_SOURCE_MESSAGE -->
done. proceed with P04 - Servicing & Exceptions
<!-- END_SOURCE_MESSAGE -->


<a id="m-ad2c73bb-19ef-4d3e-8d1e-950c81043f29"></a>
## Assistant · C109-M00419

C109-M00419 · 2026-08-27T06:22:19.129802-04:00 · active path

Preceding visible parent: [C109-M00418](part-15.md#m-8daf0c6d-7486-4eb4-87fe-707c1a620dcd)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. We can begin P04 now, and the physical inspection gives us a much sharper design than the old abstract roadmap.

The page should keep the title **`P04 - Servicing & Exceptions`** and answer one operational question:

> **Where is attention required, why is it required, how old is the issue, and what exposure is associated with it?**

That is exactly the previously documented page contract. [export reference: filecite | turn48file2 | L153-L175]

The model supports four distinct operational layers we should exploit rather than collapse together: daily monitoring/alerts from `FactAccountDaily`; intervention strategy from `FactIntervention`; actual synthetic servicing execution/payment/lifecycle evidence from the M2.8 population; and payment exceptions plus reassessment timing from `FactPaymentException` and `FactOperationalActivation`. The semantic design explicitly includes separate date roles for exception origination/resolution and operational activation. [export reference: filecite | turn49file1 | L30-L40]

There is also an important population constraint: M2.8 contains only **59 accepted servicing-execution account rows**, of which **57 require no processing, one has temporary processing active, and one is on servicing-review hold**. The seven synthetic payment events are concentrated in the temporary-processing case. [export reference: filecite | turn49file3 | L118-L160] So we should build this as a **portfolio operational workbench**, not pretend there is a huge production collections queue.

## Proposed P04 page structure

I would organize the page in four bands:

**Top — Portfolio servicing posture**  
Scenario slicer plus Observation date slicer. Unlike P03, the date is important here because P04 is fundamentally an **as-of operational page**. Then four or five KPIs: Accounts requiring attention, exposure requiring attention, active alerts, unresolved exceptions, and stale reassessments.

**Middle-left — Where attention sits**  
A queue/status distribution showing things such as No servicing required / Active reassessment / Governance review hold or the corresponding accepted servicing queue families. M2.10 explicitly defines servicing queues including active reassessment and governance-review hold. [export reference: filecite | turn49file4 | L199-L218]

**Middle-right — Why attention is required**  
A monitoring-severity / reason view: Watch, Underperforming, Severe shortfall, active alerts, remittance deterioration, etc. This should distinguish **performance deterioration** from **operational workload**.

**Bottom — Actionable account workbench**  
A table containing Merchant/Application, status, queue, exposure, reason, exception age/reassessment date, and governed intervention/action. That is where a user identifies an account and then can use P03 to inspect the complete application journey.

This preserves the original workbench boundary: **review and investigation, not an autonomous action engine.** [export reference: filecite | turn48file8 | L580-L602]

### First construction step: establish the page and slicers

Duplicate P03 or create a fresh page if you prefer; I recommend a **fresh blank page** because the geometry/story is different.

Set:

**Tab:** `P04 - Servicing & Exceptions`

**Title:** `Servicing & Exceptions`

**Subtitle:** `Identify accounts requiring operational attention, understand the drivers, and quantify the associated exposure.`

For slicers, start with only:

1. **Scenario** — single select, no Select All.
2. **Observation date** — Between slicer initially.

Do **not** add Merchant, Industry or Acquisition slicers yet. This page is meant to surface the portfolio workload rather than require the user to know where to look first. We can add optional segmentation later if the physical layout earns it.

### Then make three hidden tables visible if necessary

You have already exposed:

- `FactAccountDaily`
- `FactIntervention`

Now check the Fields pane for:

- `FactPaymentException`
- `FactOperationalActivation`

If either is hidden, **unhide it**.

Also look for the servicing-execution fact. Based on the accepted model, there should be a fact associated with M2.8 servicing execution, plus `FactPaymentEvent` and `FactLifecycleTransition`; the semantic model definitely contains the latter two. [export reference: filecite | turn49file1 | L32-L40]

Do not create any measures yet.

### What I want from you next

After establishing the title/slicers, tell me exactly which of these are visible in your Fields pane:

`FactPaymentException`  
`FactOperationalActivation`  
`FactPaymentEvent`  
`FactLifecycleTransition`

and any fact table whose name contains **Servicing**, **Execution**, **PortfolioPerformance**, or **Certification**.

Once we know the actual Power BI table names, we'll build the **top KPI strip first**, starting with the simplest and most important metric: **Accounts requiring attention**. This time we'll construct each KPI from its proper grain instead of approximating it from whatever visible measure happens to exist. [export reference: memcite]
<!-- END_SOURCE_MESSAGE -->


<a id="m-3c595d19-a5e1-4df0-aef2-7c12bb086163"></a>
## Andrew / user · C109-M00420

C109-M00420 · 2026-08-27T08:09:54.088000-04:00 · active path

Preceding visible parent: [C109-M00419](part-15.md#m-ad2c73bb-19ef-4d3e-8d1e-950c81043f29)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 0b6493a5-1e8d-4b45-8f25-04cad091b87c.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-b4cf0714-b1db-4466-81b5-c33147946379"></a>
## Assistant · C109-M00421

C109-M00421 · 2026-08-27T08:10:00.550244-04:00 · active path

Preceding visible parent: [C109-M00420](part-15.md#m-3c595d19-a5e1-4df0-aef2-7c12bb086163)

<!-- BEGIN_SOURCE_MESSAGE -->
Great — this tells us a lot, and we have enough to proceed without guessing.

From your Fields pane:

- `FactPaymentException` is already visible.
- `FactServicingExecution` exists and is hidden.
- `FactServicingQueueEndpoint` exists and is hidden.
- `FactMonitoringEndpoint` exists and is hidden.
- `FactPortfolioPerformance...` exists and is hidden.
- `FactAccountCertification` / `FactAccountReconciliation` also exist and are hidden.
- I do **not** see `FactOperationalActivation`, `FactPaymentEvent`, or `FactLifecycleTransition` in the current semantic surface, so we should not design P04 around fields that are not actually exposed here.

For P04, I recommend unhiding only these two next:

```text
FactServicingExecution
FactServicingQueueEndpoint
```

Leave the others hidden for now. `FactMonitoringEndpoint` and `FactPortfolioPerformance...` may become useful, but I want to see whether the two servicing facts already give us the operational posture cleanly before widening the surface further.

The reason is straightforward: the accepted servicing layer has a very small but meaningful execution population—57 no-processing paths, one temporary-processing path, and one servicing-review hold—and the queue layer distinguishes no servicing required, active reassessment, and governance review hold. [export reference: filecite | turn49file3 | L118-L160] [export reference: filecite | turn49file4 | L199-L218]

### Then create the P04 shell

Use:

**Tab:** `P04 - Servicing & Exceptions`

**Title:** `Servicing & Exceptions`

**Subtitle:** `Identify accounts requiring operational attention, understand the drivers, and quantify the associated exposure.`

Add only these slicers initially:

- `Scenario`
- `Observation date`

Keep Scenario single-select.

### First KPI: Accounts requiring attention

Before I give you the DAX, expand `FactServicingQueueEndpoint` and show me its field list.

I specifically want to see whether it contains things like:

```text
servicing_queue_code
open_servicing_flag
servicing_burden_units
ending_exposure
account/application key
```

or similar.

That endpoint fact is likely the cleanest source for the top KPI strip, and I would rather build **Accounts requiring attention**, **Exposure requiring attention**, and **Servicing burden** from the accepted queue grain than reconstruct them indirectly from daily monitoring.

So next:

1. Unhide `FactServicingExecution`.
2. Unhide `FactServicingQueueEndpoint`.
3. Expand `FactServicingQueueEndpoint`.
4. Send me a screenshot of its fields.

Then we’ll build the KPI strip from the actual physical grain.
<!-- END_SOURCE_MESSAGE -->


<a id="m-616c58e6-4a3f-4076-8a23-285c323b320c"></a>
## Andrew / user · C109-M00422

C109-M00422 · 2026-08-27T08:11:49.407000-04:00 · active path

Preceding visible parent: [C109-M00421](part-15.md#m-b4cf0714-b1db-4466-81b5-c33147946379)

<!-- BEGIN_SOURCE_MESSAGE -->
Ingest these tables first to aid construction. first FactPaymentException :

| module1\_run\_id scenario\_id scenario\_code merchant\_application\_id synthetic\_account\_id synthetic\_exception\_case\_id originating\_event\_sequence originating\_event\_date resolving\_event\_sequence resolving\_event\_date exception\_amount exception\_status\_code resolution\_action\_code exception\_open\_days unresolved\_exception\_flag real\_funds\_moved\_flag external\_system\_called\_flag originating\_event\_row\_hash resolving\_event\_row\_hash row\_hash created\_at ApplicationKey RunScenarioKey ApplicationScenarioKey AccountKey PaymentExceptionKey  |   |          |                               |                                  |                                 |   |           |   |           |       |                     |                              |   |       |       |       |                                  |                                  |                                  |          |                                  |      |                                     |                                     |                                                                      |
| -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | - | -------- | ----------------------------- | -------------------------------- | ------------------------------- | - | --------- | - | --------- | ----- | ------------------- | ---------------------------- | - | ----- | ----- | ----- | -------------------------------- | -------------------------------- | -------------------------------- | -------- | -------------------------------- | ---- | ----------------------------------- | ----------------------------------- | -------------------------------------------------------------------- |
| 1                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | 5 | BASELINE | MSBF\_POP\_0001\_M000312\_A01 | MSBF\_ACCT\_E12C6C7D70D2E4F87411 | MSBF\_EXC\_D4C9BBB21BB4AB79F655 | 4 | 7/27/2026 | 5 | 7/28/2026 | 27.75 | RESOLVED\_BY\_RETRY | RESOLVE\_RETURN\_WITH\_RETRY | 1 | False | False | False | bba7327c5475b9df0979e3efc39fb4dd | 75c8ffb20e6f71b511c3f00400165a9b | d2106a2a1ac04c0db49d9edcc0401158 | 8/3/2026 | 1\|MSBF\_POP\_0001\_M000312\_A01 | 1\|5 | 1\|5\|MSBF\_POP\_0001\_M000312\_A01 | 1\|5\|MSBF\_POP\_0001\_M000312\_A01 | 1\|5\|MSBF\_POP\_0001\_M000312\_A01\|MSBF\_EXC\_D4C9BBB21BB4AB79F655 |
<!-- END_SOURCE_MESSAGE -->


<a id="m-ea0fcbb8-23b3-4139-bfef-d14a8a36f947"></a>
## Assistant · C109-M00423

C109-M00423 · 2026-08-27T08:11:53.653239-04:00 · active path

Preceding visible parent: [C109-M00422](part-15.md#m-616c58e6-4a3f-4076-8a23-285c323b320c)

<!-- BEGIN_SOURCE_MESSAGE -->
Ingested. `FactPaymentException` is very clean, and it tells us something important for P04: **payment exceptions are currently an event/case layer, not a broad active backlog population.**

From the supplied table, the grain is effectively one row per synthetic payment-exception case, scenario-qualified through `ApplicationScenarioKey` and account-qualified through `AccountKey`. The table carries both the originating and resolving event/date, so it can support **exception age, resolution status, amount, and lifecycle state** without us reconstructing those concepts from daily monitoring.

For the supplied row, Merchant/Application `M000312_A01` under Baseline generated a **$27.75** exception on **7/27/2026**, resolved by retry on **7/28/2026**, with `exception_open_days = 1` and `unresolved_exception_flag = False`. Both `real_funds_moved_flag` and `external_system_called_flag` are False, which is an important synthetic/non-production boundary for any P04 wording.

For construction, I would treat these as the useful business fields:

```text
merchant_application_id
synthetic_account_id
synthetic_exception_case_id
originating_event_date
resolving_event_date
exception_amount
exception_status_code
resolution_action_code
exception_open_days
unresolved_exception_flag
AccountKey
```

The technical hash/key fields remain useful for lineage but should not appear on the report surface.

This also suggests the eventual **Exceptions** component of P04 should distinguish:

- **Open exceptions** — `unresolved_exception_flag = TRUE`
- **Resolved exceptions** — retained as history/context
- **Exception exposure/amount**
- **Age/open days**
- **Resolution action**

But with the current supplied population, we should not make “unresolved exceptions” a dominant visual unless other rows establish an actual open population. If this is the full fact population and all cases are resolved, a KPI of `0 unresolved exceptions` is truthful but probably secondary.

One modeling note for later: because the table has both `originating_event_date` and `resolving_event_date`, the **origin date should remain the primary timeline** for exception incidence; resolution date is a second role and should only be activated explicitly when we need resolution timing.

I have this table mapped. Send the next table—ideally **`FactServicingExecution`** next, because that should establish the actual servicing workload/execution grain we want to anchor P04 around.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3bc43e39-f119-44c1-a7e9-d738a2e7dfbe"></a>
## Andrew / user · C109-M00424

C109-M00424 · 2026-08-27T08:13:32.185000-04:00 · active path

Preceding visible parent: [C109-M00423](part-15.md#m-ea0fcbb8-23b3-4139-bfef-d14a8a36f947)

**Editorial record note:** Attachment references: Pasted markdown(20260827-121324).md

<!-- BEGIN_SOURCE_MESSAGE -->
factservicingexecution : 
<!-- END_SOURCE_MESSAGE -->
