# Understanding the Mechanics Behind Merchant POS Lending
## Merchant-finance masterclass | 22 lessons + closing synthesis | R8

**Same MSBF world. The camera is in the classroom.** This guide accompanies the source-grounded visual-pedagogical revision of R6. The operating merchant requests the advance. Merchant evidence and request terms jointly determine what can be assessed, supported and authorized; only the actual funded path enters the account lifecycle.

The four acts are **Read the Merchant (1–6)**, **Read the Request (7–10)**, **Search & Decide (11–15)** and **Follow the Account (16–22)**. Page 23 adds a closing synthesis; the 22 lesson bodies are retained. Every page has a visible left-hand question and a separated right-hand answer. Pause at the question before reading the answer. The explanations below retain the deeper R6 teaching detail, while the figure-reading instructions and exercise wording match R7.

### Meaning carried by the visuals

Teal denotes observed/derived evidence; navy denotes request structure and logic; gold marks policy, authority and required boundaries; blue denotes funded lifecycle and monitoring; rust marks adverse observations or binding constraints. Text labels remain present so color is never the only cue. Full-page dark act transitions provide visual rhythm, not a claim that every shape's background is a new data category.

### What the material claims

Source-method formulas and policy thresholds describe the supplied MSBF implementation. Case displays use actual deterministic synthetic exported records. Hypothetical one-factor sensitivity and simplified remittance exercises are explicitly labeled. They are not production advice, legal classifications, commercial offers, forecasts or complete engine replacements. Source reading and arithmetic checks are not an engine, database, Power BI or cohort replay.

Source IDs in the preserved lesson footers retain their R7 meaning. The [read-only code map](READ_ONLY_CODE_MAP.md) retains the source field and method directions. The [upstream reference index](../source/UPSTREAM_REFERENCE_INDEX.json) identifies the exact R7 deck and companions used for this amendment; it is not a substitute for the separately retained implementation source registry. R8 adds no new technical inputs, thresholds or results and does not re-perform the earlier source qualification. Private source carriers are not redistributed.

## 01. Understanding the Mechanics Behind Merchant POS Lending

**Objective:** Follow the complete system, then open the evidence behind each decision.

**Poster connection:** The two proof posters become the syllabus

**Sources:** S01, S13, S18 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The business is the financed party. Read merchant evidence and request terms together, then follow the permitted path into the account. The page-local four-color key distinguishes evidence, structure, authority and lifecycle. The business-evidence card is teal. The unused constraint marker is removed from this cover; rust retains its adverse/constraint meaning on later pages where it is used. There is no shopper-led borrowing path.

This casebook expands the two proof posters rather than treating them as validated executable rules. It teaches the accepted MSBF synthetic implementation and identifies educational simplifications explicitly. Merchant POS financing here refers to financing the operating business, not consumer checkout installments. POS means point of sale. The merchant-and-request diagram shows conceptual flows, not a legal classification of a contract or a deployed payment integration. Each later page identifies an input, its interpretation, an applicable rule and an example. The four acts support a beginner-to-expert path. The source and code companion provides definitions, exact export keys and line locators; it is not an execution runbook. The established classroom visual style is retained, while the rejected fourteen-page treatment is superseded for instructional depth, not silently deleted.

### Think, then check

**Try it:** Why is a strong sales total not enough to approve an advance?

**Visible answer:** Sales must support the requested burden after obligations, liquidity, risk, economics and authority tests.

**Expanded reasoning:** Sales must be usable and translated into operating cash, existing obligations, proposed repayment burden, liquidity, risk and economics. Authority then determines whether the evaluated structure may be funded.


## 02. Read the merchant—not just the sales total

**Objective:** Separate business context, evidence reliability, repayment capacity and lender economics.

**Poster connection:** Decision poster / inputs

**Sources:** S01, S03, S05, S06, S27 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The spokes show associations, not a sequence of independent vetoes. Read each input family alongside the decision function it supplies. Context, reliability, cash support and economics are different jobs.

The actual R4 application-scenario source preserves merchant industry, size, relationship, confidence, verification, fraud, continuity, usable sales, balance, NSF, obligations, capacity, resilience, risk and economics. These fields play different roles. Size and relationship are not invented standalone vetoes. Industry enters the accepted M1.10 operating-margin profile and M1.12 context-risk component. Acquisition-source cost/attribution is not a substitute for credit quality or the separate M1.14 economic calculation. Source confidence is not calibrated probability of default. NSF denotes a non-sufficient-funds event in the synthetic source evidence. The deck will show actual numeric paths, not attribute causality from correlations across merchants. A changed single variable is discussed only in a clearly labeled controlled illustration unless the accepted source supplies the comparison.

### Think, then check

**Try it:** Similar sales, different supportable amounts: which drivers could explain the difference?

**Visible answer:** Obligations and modeled margin alter residual cash; liquidity, evidence, risk and request terms also matter.

**Expanded reasoning:** Existing obligations and modeled operating margin can change residual capacity; liquidity, sales stability, evidence availability, risk and the requested terms also matter. There is no single sufficient driver.


## 03. Sales tell a pattern—not only a total

**Objective:** Trace level, trend, variability, inactivity and concentration into the revenue-resilience component.

**Poster connection:** Decision poster / cash-flow inputs

**Sources:** S02, S05, S01 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Begin with sales level, then inspect four normalized pattern components. The weights are not raw merchant percentages. The result shown is the revenue-resilience component, not the final integrated risk score.

The revenue resilience expression in accepted M1.11 applies four clipped transforms to sales growth, daily coefficient of variation, zero-sales-day rate and largest 30-day concentration within 180 days. Weights are exactly 0.40, 0.25, 0.20 and 0.15. This is one of five resilience components, not the entire final risk score. M1.11 then combines revenue, liquidity, burden, continuity and confidence using its resolved component weights and persists component evidence. The input windows and availability requirements are governed by M1.9. A defined zero-sales day is a valid value, while an outage can remove a day from usable evidence. Raw POS, settlement and deposits are separate source families; do not assume sales equal settled funds or that all deposits are free cash. The displayed formulas are readable field definitions; exact code handles windows, floors, missing values and precision.

### Think, then check

**Try it:** Can four raw percentages be added to reproduce the revenue score?

**Visible answer:** No. Scale and clip each feature first. Then apply 40% / 25% / 20% / 15%; missing inputs can block it.

**Expanded reasoning:** No. Each feature is scaled and clamped to the source’s 0–1 component range before its weight is applied; the weighted sum is multiplied by 100. Missing required features block the dependent computation.


## 04. Build capacity from cash and commitments

**Objective:** Reproduce merchant 098’s Baseline calculation before interpreting any tier.

**Poster connection:** Decision poster / liquidity and obligations

**Sources:** S01, S03, S04 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Reproduce each operation from the source-input column. The navy block identifies which financing-burden test binds. The lower bridge changes an observed balance into a modeled buffer; it does not add advance principal.

Accepted M1.10 computes operating_cash=round(avg_daily_eligible_sales_30d×industry_operating_cash_margin,2). Existing obligations include fixed daily payment amounts and source sales-linked obligations applied to scenario sales. New financing burden is max(round(S×r,2),round(T/H,2)), total burden adds existing payments, residual=C−D and post buffer=current buffer+30×residual under the resolved projection days. Coverage uses max(D,1) as denominator and burden-to-sales uses max(S,1); the worked record is well above both floors. Buffer days=post buffer/max(D,1). Industry margins are synthetic policy parameters, not empirical margins: restaurant 15%, retail 16%, professional services 30%, construction 18%, transport 17%, energy 20%, healthcare 24%, ecommerce 22%. Merchant 098 Baseline demonstrates every input and operation directly. Do not add advance principal to the liquidity formula: that is not what this source implementation does.

### Think, then check

**Try it:** Why is $1,717.45 observed balance different from the $3,218.65 projected buffer?

**Visible answer:** The model adds 30 days of residual cash. The projection is not an observed balance or an advance deposit.

**Expanded reasoning:** The model adds 30 days of residual operating cash to the current balance. The projection is a modeled assessment, not an observed bank balance and not an automatic deposit of the requested advance.


## 05. Before judging performance, establish evidence

**Objective:** A complete-looking record can still lack the feature required for the decision.

**Poster connection:** Decision poster / verification and source quality

**Sources:** S01, S11, S13, S15, S27 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Compare usable-day counts before comparing performance. The missing two cells are count symbols, not claimed outage dates. The source-specific missing feature controls the stress decline, not a generic REVIEW label.

The final source narrative identifies 28 usable POS days versus 30 required and two disconnected processor-outage days for merchant 738 Recession Energy. Its headline feature-completeness label is COMPLETE in the application source, so the specific feature-availability record matters more than that broad label. Source confidence remains HIGH and verification_disposition is REVIEW in both scenarios; R4’s refined human-review classification records no binding human-judgment gate for this merchant. The controlling stress reason is evidence availability, not processor WATCH alone or generic verification REVIEW. The source six verification checks are BANK_ACCOUNT_MATCH, BENEFICIAL_OWNER, FRAUD_SCREEN, KYB_ENTITY, PROCESSOR_MATCH and SANCTIONS. KYB means know-your-business in the label; this portfolio does not claim a live verification provider or actual sanctions screening. Specific source conflicts can require review; actual hard-stop reasons remain separate.

### Think, then check

**Try it:** Can a smaller request repair 738’s missing eligible-sales feature?

**Visible answer:** No. Revised terms cannot supply missing observations. Required evidence must exist before dependent tests.

**Expanded reasoning:** No. Changing the structure does not supply the two missing usable observations. Source availability must be sufficient before dependent calculations can support a decision.


## 06. Risk and economics answer different questions

**Objective:** A financially attractive request can still fail capacity—or need judgment before authorization.

**Poster connection:** Decision poster / risk and unit economics

**Sources:** S05, S06, S07, S08, S01, S09 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The left panel identifies risk inputs. The right panel identifies costs, loss, capital charge and the economic hurdle. Neither panel replaces the separate capacity or authority tests.

M1.12 preserves seven components listed here; the synthetic proxy includes policy floors and scenario non-improvement. M1.13 schedule-adjusted comparative loss equals path_weighted_ead_amount×synthetic_merchant_risk_proxy×final_lgd_input_rate, rounded to cents. LGD is the modeled loss-given-default input, with industry/recovery assumptions and bounds; this is comparative synthetic evidence, not CECL. M1.14 non-loss costs explicitly include processor, partner acquisition, funding, servicing and operating costs. Risk-capital charge is an additional deduction, and must not be omitted from the contribution explanation. Hurdle contribution is funded amount×18%×term/365 under this resolved profile. Merchant 098 Baseline source contribution 654.26 and annualized return 0.51026688 pass. The simple displayed hurdle rounds to 230.79. The source annualized return uses contribution/funding×365/horizon; it is not a consumer APR calculation or a promise of profitability. Risk and economic calculations are recalculated for candidate structures through the accepted methods, rather than merely carrying requested-structure results into every alternative.

### Think, then check

**Try it:** Does clearing the economic hurdle compensate for a capacity failure?

**Visible answer:** No. Capacity and economics are separate required tests. Strong contribution cannot waive another gate.

**Expanded reasoning:** No. The economic hurdle and capacity are separate required tests. Strong contribution cannot waive insufficient capacity, unavailable evidence or a binding authority condition.


## 07. Read the request as four linked parameters

**Objective:** Distinguish the repayment target, sales share, assessment horizon and actual daily remittance.

**Poster connection:** Decision poster / requested structure

**Sources:** S01, S03, S17 · **Scope:** SOURCE CASE + LABELED ARITHMETIC

**Read the visual:** Read the four actual source terms first. The two lower rows are a separate 10% daily illustration, with every opening balance specified. The $80 cap is now part of a complete row, not an unexplained sidebar.

The source terms for merchant 098 Baseline are amount 5200, remittance 0.109032, payback 1.259198 and horizon 90. Their target repayment is 6547.83. M1.10 assesses financing burden using the larger of rate-based and horizon-required amounts; this is not the same as actual M2.5 daily remittance. Retained M2.5 calculates raw daily remittance=round(eligible sales×rate,2), caps it by remaining receivable, and caps cumulative remittance at total repayment. R26 changes the expected pace benchmark, not those physical remittance amounts. The lower worksheet deliberately uses independent hypothetical daily records with rate 10% to teach the cap; balances before collection are provided in every row. It does not say a real contract universally has no payment obligation on zero sales. No fees, delays, returns or other contractual provisions are inferred from this example. The earlier unexplained $80 sidebar is replaced by an explicit row with a fully specified state.

### Think, then check

**Try it:** At $1,500 eligible sales and a $100 balance, what is a 10% remittance?

**Visible answer:** $100. The share is $150, but min($150, $100) = $100. All assumptions belong to this illustration.

**Expanded reasoning:** $150 is the calculated share. min($150,$100)=$100; the balance becomes zero in this simplified example. All assumptions are explicit on this page.


## 08. Change one term. Find the binding burden.

**Objective:** The larger of sales-share demand and horizon demand controls this assessment—not always the amount.

**Poster connection:** Decision poster / structure mechanics

**Sources:** S01, S03 · **Scope:** ILLUSTRATIVE ONE-FACTOR LAB USING SOURCE INPUTS

**Read the visual:** Each row changes only one selected term against fixed source merchant inputs. The paired bars share dollars-per-day units. The navy bar is the max assessment result, not the actual daily collection.

This page uses source merchant 098 Baseline sales, margin and existing obligations as fixed numerical inputs, then creates clearly labeled one-factor illustrations. The payback multiple stays 1.259198. Requested target 6547.83 over 90 yields 72.75; over 60 yields 109.13. At 2500, target 3148.00 over 90 yields 34.98, while the 10.9032% sales leg remains 46.15. At 8%, the rate leg is 33.86; at 20%,84.65. These values explain the max operator in accepted M1.10. The assessment demand is not the actual daily remittance ledger and is not an alternative-scenario simulation. Other credit, risk, liquidity, economics and term-boundary tests are deliberately held outside this small lab; no approval result is asserted. Source amounts are rounded to cents at the indicated operations. A change in horizon also changes cost and economic annualization in the complete method, so this isolated burden exercise does not claim a globally optimal structure.

### Think, then check

**Try it:** Why does reducing the remittance rate to 8% leave N unchanged?

**Visible answer:** The $72.75 horizon leg still exceeds the $33.86 sales-share leg. The larger amount governs.

**Expanded reasoning:** The horizon leg remains 72.75, above the reduced rate leg 33.86. The max operation still selects 72.75. A lower rate is not automatically lower assessed burden.


## 09. Fit the structure inside the capacity boundary

**Objective:** Apply the composite test: one strong metric cannot cancel a failing one.

**Poster connection:** Decision poster / capacity × request

**Sources:** S03, S04, S10, S12 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Read strict and review columns as composite requirements. The 082 example below has a large modeled liquidity buffer but still fails requested coverage and cash support. A good cell cannot cancel a failed test.

These are the actual R4 gate export thresholds: strict coverage≥1.25, total burden≤0.22, buffer≥15, residual≥0 and capacity tier≤2; review coverage≥1, burden≤0.30, buffer≥5 and tier≤3. Accepted M1.10 tier 1 has stricter coverage 1.50, burden 0.15, buffer 30 and stacking<3; tier 2 can still pass without meeting the tier 1 stacking condition. Review tier 3 does not add a separate residual minimum in the R4 gate map; do not invent one. Source floors protect denominator calculations. Merchant 082 Baseline requested structure has total burden 1673.07, operating cash 1201.20, coverage 0.717962, residual−471.87, total-sales burden 0.33427838 and 127.8328 buffer days. Risk and economics can be favorable while this composite fails. A review-eligible structure does not establish final authorization: human-judgment and other gates are checked later.

### Think, then check

**Try it:** Does a large bank balance prove merchant 082’s request is affordable?

**Visible answer:** No. Requested residual cash is −$471.87/day; coverage and burden fail despite a large buffer.

**Expanded reasoning:** No. Merchant 082 has a strong projected buffer but negative residual cash and insufficient payment coverage at the requested terms. The composite capacity gate fails.


## 10. What can revised terms fix—and what can’t they?

**Objective:** Read the specific reason and remediability class before searching or escalating.

**Poster connection:** Decision poster / eligibility gates

**Sources:** S09, S10, S11, S13 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The five lanes classify kinds of conditions, not universal execution priority. The 738 strip demonstrates why specific availability and human-judgment records matter more than a broad REVIEW label.

R4 policy specifies human_review_conditions exactly: SPECIFIC_VERIFICATION_OR_SOURCE_CONFLICT, MEDIUM_DATA_CONFIDENCE, FRAUD_TIER_3, PROCESSOR_CONTINUITY_DISRUPTED_OR_UNAVAILABLE. Advisory treatments include partial-source and source-quality warnings when critical evidence is available, processor continuity WATCH, and noncredit acquisition evidence review. Thus a blanket claim that any REVIEW/partial label forces manual underwriting would be wrong. The gate export records hard nonremediable, structure-remediable, human-judgment and advisory classes separately. Merchant 738 is the concrete case: its verification_disposition is REVIEW, but HUMAN_JUDGMENT=NONE; Baseline authorizes, stress declines because required eligible-sales evidence is unavailable. This page is a classification of governing conditions, not invented priority code for every possible simultaneous failure. The source final decision and its binding reasons resolve combined conditions.

### Think, then check

**Try it:** Why does 738’s broad verification REVIEW label not explain its stress evidence decline?

**Visible answer:** Its refined human gate is NONE. Stress separately lacks 30 usable POS days; that specific evidence failure binds.

**Expanded reasoning:** The refined human classification finds no binding human-judgment gate for 738. The stress path separately lacks the required 30 usable POS days. The specific evidence failure—not the broad REVIEW label—controls.


## 11. Search a governed set—not an unlimited menu

**Objective:** Re-evaluate exact candidate structures, then preserve both feasibility and authority.

**Poster connection:** Decision poster / structure search

**Sources:** S09, S10, S12, S13 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The process feeds both strict and review frontiers. Amount, horizon, economics and repayment protections apply before preference. The final authority and matched-scenario boundary can change the eligible selection.

The accepted R4 policy is DUAL_FRONTIER_AUTHORITY_FIRST. Both strict and review possibilities are retained, with exact candidate selection ranks and selected flags in the source output. The strict frontier requires the strict capacity, resilience and risk conditions and no remaining human-judgment authority block; review eligibility preserves its defined less restrictive boundary and identified review requirements. Both require the economic hurdle, minimum amount and supported horizon. Automatic total-repayment increase is 0%; review maximum 2%; the source has a one-cent rounding tolerance. These are total repayment protections, not APR limits. R26 carries these strategy outputs forward. The source set retains generator outputs and method bindings, not an independently packaged original R4 generator; this teaching description is grounded in policy, method code and gate/candidate evidence, not a claim that a complete search runner was rebuilt here. The matched stress floor can change a preferred candidate or remove all eligible candidates; page 15 shows actual cases.

### Think, then check

**Try it:** Can higher modeled return admit a candidate below the 40% amount floor?

**Visible answer:** No. Policy admissibility and feasibility come before preference. The objective cannot waive a boundary.

**Expanded reasoning:** No. Feasibility and policy boundaries precede preference. An attractive objective score does not admit an ineligible candidate.


## 12. Candidate lab: where the boundary moves

**Objective:** Merchant 082 / Baseline. Compare actual candidate inputs and gates to see where feasibility changes.

**Poster connection:** Decision poster / structure search

**Sources:** S01, S12, S13 · **Scope:** ACTUAL SYNTHETIC CANDIDATES · DISPLAY ROUNDED

**Read the visual:** Compare source candidate rows, not invented choices. The rust 0.9991 value is deliberately not rounded to 1.00. The selected row is identified by source flags, not by the highest isolated return.

The five candidates share remittance 0.130606, payback 1.255266 and horizon 60. Source IDs and exact candidate keys are in SELECTED_CASE_EVIDENCE.json. The 53800 candidate has coverage 0.71796159 and burden 0.33427838. The 31300 candidate has 0.99905185 and 0.24022681 and fails capacity. The 31200 selected candidate has coverage 1.00000000, burden 0.23999904, buffer 189.8346 days and passes the review capacity boundary. The 31100 candidate remains review eligible but is not selected. At these lower amounts, rate-based burden dominates horizon demand, explaining the plateau. The 2500 row has minimum_ratio_pass_flag=false:2500/53800<0.40 despite coverage 1. The page deliberately preserves exact source statuses instead of imposing an illustrative preference order. Ratios are display-rounded; the 31300 row is shown 0.9991, not rounded up to 1.00. The source candidate ranking and final decision—not the highest isolated metric—identify the selected row. This is the reader’s first complete multi-gate comparison lab, connecting amount constraints, capacity and review authority.

### Think, then check

**Try it:** Why does the $2,500 candidate fail despite 1.00× coverage?

**Visible answer:** It is 4.65% of the $53,800 request—below the 40% floor ($21,520). Passing capacity cannot override it.

**Expanded reasoning:** It is only 4.65% of the 53800 request, below the 40% minimum amount 21520. A satisfactory capacity metric does not override a separate admissibility gate.


## 13. A supportable structure still needs authority

**Objective:** Merchant 082 / Baseline. Read the selected terms, credit boundary and judgment gate separately.

**Poster connection:** Decision poster / decision circuit

**Sources:** S01, S09, S10, S11, S12, S13 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Read selected terms, credit boundaries and the explicit judgment reason separately. The gold aggregate bridge shows supportable includes review. Neither selected amount nor positive economics proves funding.

The selected 31200 candidate remains COUNTEROFFER_REVIEW_REQUIRED. The exact final binding codes are HUMAN_JUDGMENT|R1_CAPACITY_COMPOSITE; human_review_reason_codes=MEDIUM_DATA_CONFIDENCE. Its computed economics is positive and above the required hurdle, but this cannot waive capacity or human review. Capacity tier 3, coverage 1.00 and 23.9999% total burden are within review bounds but outside strict tier 2 boundaries. The exceptionally high 189.8346 buffer days illustrate why one favorable metric is not enough. The selected repayment target 39164.30 is 31200×1.255266, rounded to cents. The slide’s question is a conceptual conditional, not a rerun or a claim that a modified candidate exists in the accepted cohort. The Baseline totals 300 supportable,103 authorized and 197 reviewable explain the aggregate consequence of keeping feasible/review paths distinct. Supportable does not mean the merchant has accepted terms; this is the system’s modeled structure support and authorization, not customer uptake.

### Think, then check

**Try it:** Would raising coverage to 1.25× remove every reason for review?

**Visible answer:** Not necessarily. MEDIUM_DATA_CONFIDENCE remains, and every other strict condition must still pass.

**Expanded reasoning:** Not necessarily. The explicit MEDIUM_DATA_CONFIDENCE human-judgment gate remains, and all other strict conditions still apply. Passing one credit test is not sufficient for automatic authority.


## 14. Seven outcomes—and the reason behind each

**Objective:** Preserve the reason for the result; a decision record is not the same object as a funded account.

**Poster connection:** Decision poster / decision circuit

**Sources:** S09, S10, S13, S18 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Use the seven driver/outcome panels as explanations of source categories, not newly written executable priority code. The three totals partition 1,500 alternative-scenario paths.

Counts are freshly read fromgoverned_final_outcome_code: APPROVE_AS_REQUESTED_AUTHORIZED 115; COUNTEROFFER_AUTHORIZED 15; COUNTEROFFER_REVIEW_REQUIRED 212; MANUAL_UNDERWRITING_REVIEW_REQUIRED 38; DECLINE_INSUFFICIENT_EVIDENCE 234; DECLINE_NO_FEASIBLE_STRUCTURE 652; DECLINE_POLICY_HARD_STOP 234. They sum 1500. Friendly labels are shortened for readability; exact codes are retained in the code map and source evidence. The causal descriptions summarize the source-defined categories; they are not invented executable priority code. A no-feasible result includes the absence of an eligible structure after governing matched-scenario constraints, not only failure of an initial numeric capacity screen. Review/decline records do not establish physical funding. Only source-funded paths enter account monitoring. The source population has 130 authorized paths and 130 funded paths; this equality is an observed cohort fact, not a universal rule that authorization guarantees funding.

### Think, then check

**Try it:** Can “no feasible structure” follow an independent review candidate?

**Visible answer:** Yes. For 082 stress, the matched-stress floor leaves no eligible final candidate. Independent support is not final authority.

**Expanded reasoning:** Yes. Merchant 082 stress has an independent review candidate but no eligible candidate after the matched-stress structure floor. Final governed eligibility—not independent feasibility alone—controls.


## 15. The preferred candidate is not always the final one

**Objective:** Merchant 098 / Recession Energy. Higher standalone economics does not override matched-scenario governance.

**Poster connection:** Decision poster / governed selection

**Sources:** S01, S12, S13, S15 · **Scope:** ACTUAL MATCHED-SCENARIO CASES · NOT PROFILE SIMULATIONS

**Read the visual:** The left table compares the requested-state evidence, with final amount included separately. The right compares two actual $2,500 stress candidates. Read the matched floor before treating locally preferred return as final authority.

Merchant 098’s stress requested structure has 6.5393 post-financing buffer days, so it does not meet the 15-day strict boundary even though coverage 1.505719 exceeds 1.25. Reducing the amount to 2500 changes horizon demand; the sales-share leg becomes controlling and recomputed capacity becomes strict. The independent preferred 2500 candidate has rate 0.106851, multiple 1.284382, annualized modeled contribution 0.32313044. The governed selected 2500 candidate has rate 0.109032, multiple 1.259198, annualized contribution 0.23817467. The latter matches the Baseline requested remittance and payback terms. Its exact floor basis is BASELINE_TERM_NONIMPROVEMENT_RESELECTION and binding code STRESS_STRUCTURE_FLOOR. The output is COUNTEROFFER_AUTHORIZED. These are modeled contribution measures, not APR or audited profit. Negative observed liquidity−664.17 is preserved; selected-structure projected liquidity is distinct. Merchant 082 stress has independent 28900 review support but final DECLINE_NO_FEASIBLE_STRUCTURE with BASELINE_TERM_NONIMPROVEMENT_NO_ELIGIBLE_CANDIDATE. Merchant 738 stress is an evidence decline before dependent assessments. These matched source scenarios are not time-sequential events, randomized causal tests or M2.11 profile-driven decision changes.

### Think, then check

**Try it:** Why can’t 082 stress or 738 stress simply copy 098’s lower amount?

**Visible answer:** 082 loses eligible candidates under the stress floor. 738 lacks required evidence. Neither is repaired by copying a term.

**Expanded reasoning:** Merchant 082 stress loses all eligible candidates under the matched-stress floor. Merchant 738 stress lacks critical POS evidence. Neither condition can be cured by copying merchant 098’s lower amount.


## 16. Follow the exact path into the account

**Objective:** A merchant identifier is not enough. Funding membership is application- and scenario-specific.

**Poster connection:** Lifecycle poster / booking & activation

**Sources:** S13, S14, S18, S19 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The upper counts change grain from decisions to funded paths to account-days. The paired key rows show why run, scenario and application must travel together. Authorization and booked membership are distinct.

R1FactFundedLifecycle.csv is the funded membership source. It has 130 uniqueApplicationScenarioKey values and suppliesAccountKey, AdvanceKey, funded amount, funding date, activation date and first expected remittance date. R1FactDailyMonitoring has 120 distinct monitoring days per funded key, totaling 15600. The display abbreviates application IDs; full 738 keys are 1|5|MSBF_POP_0001_M000738_A01 and 1|6|MSBF_POP_0001_M000738_A01. Source final outcomes are Baseline APPROVE_AS_REQUESTED_AUTHORIZED and stress DECLINE_INSUFFICIENT_EVIDENCE. No physical stress account exists. The observed equality of 130 authorized and 130 funded paths is not a universal guarantee that a favorable decision is always booked. The primary educational invariant is funded keys must be a subset of appropriately authorized keys. These are synthetic account and advance records, not live transfer events or issued commercial contracts.

### Think, then check

**Try it:** What happens when the stress-declined 738 path is joined only on merchant ID?

**Visible answer:** The Baseline account could leak into the stress path. Use the complete run / scenario / application key.

**Expanded reasoning:** It could attach the Baseline funded account to the stress path and fabricate a lifecycle where no funded match exists. Preserve the complete run/scenario/application key.


## 17. What does active monitoring actually watch?

**Objective:** Five families describe different account problems. Timing and remaining balance determine eligibility.

**Poster connection:** Lifecycle poster / daily monitoring logic

**Sources:** S16, S17, S19 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Read family, observed input, source condition and operational meaning together. Unpaid membership applies to all rows. Timing is family-specific; 21/30/3 is not a universal waiting rule.

This table translates the exact R26 family/status logic, not general industry monitoring rules. All active family flags require an unpaid path. Pace WATCH requires monitoring_day_index≥21 and three consecutive eligible days with cumulative pace ratio<0.90. Underperformance requiresday≥30 and ratio<0.75 for three eligible consecutive days; severe pace requires<0.50. No-remittance requiresday≥14 with days_since_positive_remittance≥7; the dormant/no-remittance status uses≥14. Sales dormancy requiresday≥14 and zero_sales_day_streak≥10. Liquidity requiresday≥7 and any of available_balance_amount<0, nsf_event_count>0 ornegative_balance_flag=true. Horizon usesday≥14, day greater than selected expected horizon and a nonzero receivable. The source retains earlier hard triggers while changing pace seasoning. Watch is not automatically the actionable-adverse attention metric, but M2.6 can still route watch cases for outreach. Primary family is a separate precedence code, not an assertion that other active families vanished. The full code and source line locators are in the code map.

### Think, then check

**Try it:** Can day-8 liquidity create a watch signal before pace becomes eligible?

**Visible answer:** Yes. Liquidity starts at day 7 under its own conditions. The 21/30/3 rule applies to pace—not all signals.

**Expanded reasoning:** Yes. Liquidity has its own day 7 eligibility and negative-balance/NSF conditions. The 21/30/3 seasoning applies to pace, not to every monitoring family.


## 18. Pace is a benchmark plus persistence

**Objective:** Use the selected repayment and horizon—not a generic sales average—to define expected progress.

**Poster connection:** Lifecycle poster / pace mechanics

**Sources:** S16, S17, S19 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Reproduce the day-32 benchmark and ratio, then inspect the eligible-day ruler. The source status also needs the required persistence and precedence. The literal three-line policy excerpt is only a fragment.

Merchant 749 selected repayment is 21451.04 and horizon 90. Expected cumulative repayment at day 32 ismin(round(21451.04/90*32,2),21451.04)=7627.04. Actual cumulative remittance 5109.42 gives ratio 0.66990864, matching the source display; the source status is UNDERPERFORMING. The ratio alone is not proof of persistence—the underlying eligible-day window must be checked. On day 7, ratio 0.53806918 is not yet pace eligible and the source status is CURRENT. On day 23, pace WATCH; on day 32,UNDERPERFORMING. Earliest possible Watch qualification is 21,22,23; earliest possible adverse is 30,31,32, assuming every relevant eligible-day breach and other source conditions hold. Expected cumulative is capped atT; after day 90 the denominator no longer rises. M2.5 actual remittance is the sales-based amount capped by remaining receivable. R26 changes the benchmark and pace state logic while preserving physical remittance/exposure. The ruler is an eligibility explanation, not a promise that all accounts transition on those dates.

### Think, then check

**Try it:** Why can 66.99% qualify on day 32 while a poor earlier ratio did not?

**Visible answer:** Adverse pace needs three eligible breaches from day 30. Earlier ratios earn no persistence credit; other rules still apply.

**Expanded reasoning:** The ratio must satisfy the threshold for three consecutive eligible days. Adverse pace begins earning persistence at day 30. Earlier values do not count; other status conditions and precedence still apply.


## 19. One account. Several signals. One governed status.

**Objective:** Merchant 749 / Baseline: the pace ratio can improve while a horizon overrun keeps the account severe.

**Poster connection:** Lifecycle poster / signals → families → status

**Sources:** S16, S19 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Read the six snapshots as one source account, not six hypothetical merchants. Raw flags, active families and overall status answer different questions. Horizon can control severity while pace improves.

All six timeline rows are read fromR 1FactDailyMonitoring, not a constructed hypothetical path. At day 7, one raw shortfall flag but zero operational families and CURRENT. Day 23:two raw flags,one PACE family,WATCH. Day 32:three raw flags,one PACE family,UNDERPERFORMING. Day 90:three/one PACE,UNDERPERFORMING. Day 91:three/two HORIZON primary,SEVERE_SHORTFALL. Day 120:four raw,three operational families—PACE,LIQUIDITY,HORIZON—with HORIZON primary and SEVERE_SHORTFALL. The pace family itself is WATCH at day 120. Final source status precedence ispaid off, dormant/no remittance, severe, underperforming, watch, current, with additional matched-stress nonimprovement governance where applicable. Primary family precedence is HORIZON,LIQUIDITY,SALES_DORMANCY,NO_REMITTANCE,PACE. Those are different categorical purposes. Ratios are rounded to two decimal percentages; exact values remain in the selected evidence companion. A family can be active while another determines the final status.

### Think, then check

**Try it:** At day 120, why does 78.09% pace not make the account merely Watch?

**Visible answer:** The unpaid 90-day horizon has been exceeded. Horizon severity governs; pace and liquidity signals still remain.

**Expanded reasoning:** The 90-day horizon has been exceeded with 4699.37 still outstanding. Horizon severity wins even though the pace family is Watch. Liquidity is also active. The primary-family label does not erase other families.


## 20. A recommendation is not permission to execute

**Objective:** The retained M2.6 method selects a route; M2.7 setup and M2.8 execution retain separate authority.

**Poster connection:** Lifecycle poster / intervention & setup

**Sources:** S20, S21, S22, S23, S25 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The left branch uses only its stated fields and unpaid-exposure rank. The right shows actual routes and separate permission/results. It is not a mandatory escalation staircase or a manufactured event calendar.

The retained M2.6 generation method captures monitoring status, paid-off flag, remaining receivable, trailing 7/30remittance, zero-sales streak, current liquidity/NSF and recent alert counts. Its actual CASE routing is narrower than that field list: paid_off; otherwise SEVERE_SHORTFALL with open_rank=1; otherwise the listed adverse/watch/dormant states; otherwise standard monitoring. open_rank is the ordered unpaid population rank by remaining_receivable_amount DESC with synthetic_advance_id as tie-breaker. Do not pretend every captured contextual variable independently changes the recommendation, or relabel the rule a production-tested optimization. Current source outputs are 126 CLOSED_NO_FURTHER_ACTION,3 TARGETED_MERCHANT_OUTREACH_REVIEW and 1 TEMPORARY_REMITTANCE_ADJUSTMENT_REVIEW. The accepted retained-method terminal-state correction is preserved bywave_a_strategy_r9.py; original base-generation count assertions are historical, not current 130 population evidence. Merchant 749 hasM 2.7 TEMPORARY_PAYMENT_ADJUSTMENT_SETUP_READY, setup_authorized_flag=true andM 2.8 SIMULATED_TEMPORARY_PAYMENT_PROCESSING_ACTIVE with processing_authorized_flag=true. Three outreach rows are held. The stage sequence is a source-ownership explanation, not a claim that every reported operational date follows the monitoring endpoint chronologically. Reaching a horizon does not forgive a receivable.

### Think, then check

**Try it:** Does a targeted-outreach recommendation prove that an action happened?

**Visible answer:** No. The three outreach paths remain held. Read setup permission, processing permission and the execution result separately.

**Expanded reasoning:** No. The three targeted-outreach paths remain on review hold. Read setup authorization, processing authorization and the execution result separately; a recommendation alone does not prove action.


## 21. Reconcile the event—and the receivable

**Objective:** Merchant 749 / Baseline: resolving a return is not the same as paying off the account.

**Poster connection:** Lifecycle poster / reconciliation & proof

**Sources:** S19, S23, S24, S26 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** Use two ledgers: remove the returned amount before adding its retry, then reconcile the receivable separately. The portfolio bridge includes three review-hold balances as well as 749.

Actual source merchant 749 has 7 payment events:5 settled,1 returned and 1 retried. Scheduled 1762.25 minus returned 251.75 plus retry 251.75 equals net processed 1762.25; the returned amount must first be removed before the successful retry is added. The accepted cent-rounding correction inwave_a_strategy_r13.py retains exact money reconciliation rather than using tolerance to hide a residual. At the M2.5 endpoint merchant 749’s remaining receivable is 4699.37; permitted subsequent-stage processing 1762.25 leaves 2937.12. Three other Baseline review-hold paths retain 3123.91 together; final portfolio exposure 6061.03 equals 7823.28−1762.25. Merchant 749’s portfolio state is ACTIVE_RECONCILED with exception_incident_flag=true and exception_resolved_flag=true. These are stage-owned values, not contradictory readings of one identical observation and not measured credit-loss reduction. The staging chronology is explanatory ownership, not a manufactured calendar of real payment events. Source flags and certified output preserve the difference between resolved processing and outstanding credit exposure.

### Think, then check

**Try it:** Can zero unresolved exceptions coexist with a $6,061.03 receivable?

**Visible answer:** Yes. Reconciliation establishes agreement of events and balances. Payoff is a different question: is the receivable zero?

**Expanded reasoning:** Yes. Event reconciliation asks whether processing and balances agree. Payoff asks whether the receivable is zero. The source has a resolved return/retry and remaining exposure, including three held paths.


## 22. Turn a portfolio number back into an explanation

**Objective:** A useful analyst can trace the population, driver, rule, decision and account evidence behind a chart.

**Poster connection:** Lifecycle poster / certified portfolio intelligence

**Sources:** S13, S18, S23, S24 · **Scope:** MSBF SOURCE EVIDENCE

**Read the visual:** The equal-length bars each represent 750 application-scenario paths. Read authorization against all applications and payoff against funded membership. Then use the 082 and 749 investigations to trace the number back to source.

This capstone reconnects business teaching to inspectable artifacts. Baseline 103 authorizations/750=13.7%; supportable 300 includes 197 review. Stress 27/750=3.6%; supportable 80 includes 53 review. Payoff uses a different selected denominator:99 of 103 and 27 of 27. The two funding amounts are alternative scenarios, not one live book. M2.9 certifies account state; M2.10 owns the portfolio endpoint; M2.11 contains bounded terms/account-treatment profile comparisons without high-level outcome migration in acceptedR 26; M2.12 certifies source consumption under G3-v2. Power BIP 01–P04 consume those facts; no autonomous strategy learning or unbuilt challenger is asserted. Investigation 1 starts with merchant 082 Baseline candidate and final binding gates and checks lack of physical funded membership. Investigation 2 starts with merchant 749 permitted execution and follows net processed amount, exception flags and certified exposure. The companion includes actual field names and literal monitoring-policy lines plus clearly labeled educational pseudocode. This is a read-only source learning path, not a database-run procedure. Final executable distribution binding and Windows qualification remain in the separate runbook gate.

### Think, then check

**Try it:** Which denominator answers authorization—and which answers payoff?

**Visible answer:** Authorization uses all 750 paths in the named scenario. Payoff uses its funded subset: 103 or 27.

**Expanded reasoning:** Approval uses all 750 application-scenario paths within the named scenario. Payoff uses that scenario’s funded subset 103 or 27. The selected subset and alternative-scenario scope must stay explicit.


## 23. Closing synthesis — Understand the business. Explain the decision.

**Purpose:** Finish the learning journey without removing Page 22's technical capstone. This is an editorial synthesis of Lessons 1–22, not another source calculation or a new financing capability.

**Read the visual:** Four columns revisit the four acts. The cover asks the learner to connect merchant evidence and the request; this page asks the learner to explain that connection to someone else. Its darker composition closes the course rather than starting another technical exhibit.

### Four ideas to retain

**Read the merchant.** Sales start the question. Usable evidence, cash flow and existing obligations shape capacity.

**Read the request.** Terms work together. Evaluate amount, remittance, payback and horizon as one financing structure.

**Search and decide.** Support is not authority. A permissible alternative must still clear its final credit and judgment gates.

**Follow the account.** Funding starts a new question. Monitor before acting, reconcile events and balances, and explain what remains.

### Final teach-back

**Final Try It:** Choose one merchant case. Explain its outcome without saying “because the model said so.”

**Visible answer / teach-back check:** Name the inputs, the binding rule, the permitted action and the account evidence.

**Expanded instructor guidance:** A learner can use 738 to explain why unavailable POS evidence is not repaired by changing terms; 082 to explain why a selected review-eligible alternative is not funded approval; 098 to explain the role of matched-scenario constraints; or 749 to explain why resolving a payment exception does not eliminate the receivable. Each is a recap of its source-bound lesson, not a new simulation or a claim about a real merchant. Where no funded account exists, identifying that absence is the correct account-evidence result.

**Closing thought:** Do not stop at the outcome. Teach the reason behind it.

**Carry-forward method:** Start with the merchant. Test the structure. Respect authority. Follow the account.


## Glossary: the terms behind the calculations

| Term | Meaning in this casebook |
|---|---|
| POS | Point of sale; the merchant's sales evidence, not a shopper installment loan. |
| Eligible sales | The sales observations permitted for a particular source feature or remittance calculation. |
| Settlement | Cash transfer associated with sales processing; not interchangeable with free operating cash. |
| Operating margin | Source industry policy assumption applied to eligible sales to model operating cash. |
| Fixed vs sales-linked obligation | A stated payment amount versus a payment amount calculated from a share of sales. |
| Stacking | The modeled depth/count of existing financing commitments. It enters the source calculations and tiers, not an invented universal veto. |
| Payment coverage | Modeled operating cash divided by total existing plus proposed daily burden. |
| Liquidity buffer | Cash-balance evidence or its source-defined projection; distinguish the observed starting buffer from the modeled post-financing one. |
| NSF | An insufficient-funds event in the source evidence. |
| KYB | Business/entity verification; the synthetic check does not claim a live provider connection. |
| CV | Coefficient of variation: standard deviation divided by mean, here applied to daily sales. |
| Comparative risk proxy | Source-defined synthetic risk measure; not a production-calibrated default probability. |
| EAD / weighted exposure | Exposure used in the source loss calculation; path-weighted exposure reflects the modeled receivable through time. |
| LGD | Source-modeled loss share after recovery. |
| Contribution | Source revenue after its defined non-loss costs, comparative loss and risk-capital charge; not audited profit. |
| Payback multiple | Multiplier linking advance amount and total repayment target; it is not an annualized percentage rate. |
| Remittance rate | Share applied to eligible sales in the modeled collection rule; separate from the payback multiple. |
| Horizon | Selected repayment/assessment timing; reaching it does not forgive a balance. |
| Strict frontier | Candidate set meeting the source strict credit/economic/admissibility and authority requirements. |
| Review frontier | Candidate set meeting the source review-eligible requirements, with explicit review gates preserved. |
| Stress floor | Matched-scenario constraint applied to source routes and structure dimensions; not a guarantee of generic monotonicity under any input change. |
| Grain | What one record represents: candidate, application-scenario, account, or account-day. |
| Raw flag / family / status | Condition indicator / grouped operational meaning / governed account classification. These are different counts and objects. |
| Setup authorization | Permission/configuration boundary before servicing execution. |
| Reconciliation | Agreement among source, events and balances—not proof that the receivable is zero. |
| Scenario vs profile | Alternative evidence environment versus bounded preference/account-treatment comparison. Accepted R26 profiles do not change high-level outcomes. |


## Continuing the portfolio

The accepted architecture and pitch remain separate experiences. The accepted cohort provides deeper analytical exhibits. This R7 masterclass awaits owner review; it does not supersede a public release. Runbook qualification, history closure, integration and hosted/Windows verification remain separate gates.
