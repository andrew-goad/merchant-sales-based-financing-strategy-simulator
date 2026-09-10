# R8 exact visible PowerPoint text

All text is extracted from native text objects, not OCR.


## Page 1

MSBF / MERCHANT FINANCE MASTERCLASS
I READ THE MERCHANT
Understanding the Mechanics
Behind Merchant POS Lending
01
A merchant-finance masterclass: connect business evidence, the request, the decision and the account.
THE FINANCED PARTY IS THE MERCHANT BUSINESS
Evidence
Structure
Authority
Lifecycle
Merchant
Requests an advance.
Carries the obligation.
WHAT THE BUSINESS BRINGS
Sales & settlement
Deposits & liquidity
Existing obligations
Resilience & usable evidence
WHAT THE BUSINESS REQUESTS
Advance amount
Remittance rate
Payback multiple
Repayment horizon
Evidence &
capacity
Risk &
economics
Structure
search
Final
authority
ONLY THE AUTHORIZED, FUNDED PATH CONTINUES
Funding
Remittance
Monitoring
Portfolio insight
Learn the interaction: merchant ability × requested structure → governed decision → accountable lifecycle.
TRY IT
Why is a strong sales total not enough to approve an advance?
ANSWER
Sales must support the requested burden after
obligations, liquidity, risk, economics and authority tests.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S13, S18 | 01 / 23
KEY


## Page 2

MSBF / MERCHANT FINANCE MASTERCLASS
I READ THE MERCHANT
Read the merchant—not just the sales total
02
Seven evidence families perform different jobs. Context is not permission, and revenue is not capacity.
Merchant
evidence
What is observed?
What can it support?
BUSINESS CONTEXT
Industry · size · relationship
→ Margin assumption & context risk
SALES & SETTLEMENT
Level · trend · variability · gaps
→ Operating cash & resilience
LIQUIDITY
Balance · negative days · NSF
→ Cushion & signs of cash stress
EXISTING OBLIGATIONS
Fixed + sales-linked · stacking
→ Cash already committed
VERIFICATION & CONTINUITY
Usable history · conflicts · outages
→ Assessability & judgment gates
RISK & ECONOMICS
Comparative risk · costs · loss
→ Credit tiers & required hurdle
RESILIENCE
Revenue + liquidity + burden +
continuity + confidence
Size and relationship are not standalone vetoes here. Trace the decision role each field actually plays.
TRY IT
Similar sales, different supportable amounts: which drivers could explain the difference?
ANSWER
Obligations and modeled margin alter residual cash;
liquidity, evidence, risk and request terms also matter.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S03, S05, S06, S27 | 02 / 23


## Page 3

MSBF / MERCHANT FINANCE MASTERCLASS
I READ THE MERCHANT
Sales tell a pattern—not only a total
03
Average sales feed cash generation. Their pattern feeds the source revenue-resilience component.
Start with level
30-day average eligible
sales → modeled cash,
obligations and remittance
burden
Zero sales is a value.
An outage can remove usable
evidence.
40%
Trend
30-day average / 90-day average − 1
Growth after source scaling
25%
Stability
Daily standard deviation / daily mean
Lower variability helps the component
20%
Activity
Zero-sales days / defined window
Inactivity is assessed separately
15%
Concentration
Largest 30-day share within 180 days
Dependence on one period matters
Normalize → clip each component to [0,1] → apply weights → × 100
This is one resilience component, not the final integrated risk score. Windows and evidence availability still govern.
TRY IT
Can four raw percentages be added to reproduce the revenue score?
ANSWER
No. Scale and clip each feature first. Then apply 40% /
25% / 20% / 15%; missing inputs can block it.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S02, S05, S01 | 03 / 23


## Page 4

MSBF / MERCHANT FINANCE MASTERCLASS
I READ THE MERCHANT
Build capacity from cash and commitments
04
Merchant 098 / Baseline. Every amount below belongs to a stated input, operation or output.
098
SYNTHETIC MERCHANT 098
Cash after
commitments
BASELINE
START WITH SOURCE INPUTS
Eligible sales / day
$423.27
Policy operating margin
30%
Existing obligations / day
$4.19
Observed average balance
$1,717.45
CASH GENERATION MINUS TOTAL DAILY BURDEN
C = $423.27 × 30%
$126.98 / day
D = $4.19 existing + $72.75 new
$76.94 / day
Residual: $126.98 − $76.94 = $50.04 / day
PROJECT LIQUIDITY — DO NOT ADD THE ADVANCE PRINCIPAL
$1,717.45 + (30 × $50.04) = $3,218.65
Coverage = C / D
$126.98 / $76.94 = 1.6504×
Buffer days = projected buffer / D
$3,218.65 / $76.94 = 41.8332 days
30% is this industry policy assumption—not a measured profit margin. Source operations round to cents.
TRY IT
Why is $1,717.45 observed balance different from the $3,218.65 projected buffer?
ANSWER
The model adds 30 days of residual cash. The projection is
not an observed balance or an advance deposit.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S03, S04 | 04 / 23


## Page 5

MSBF / MERCHANT FINANCE MASTERCLASS
I READ THE MERCHANT
Before judging performance, establish evidence
05
An available record is not the same as an available decision-critical feature.
738
SYNTHETIC MERCHANT 738
Missing is not zero
MATCHED ALTERNATIVE SCENARIOS
SIX SYNTHETIC CHECK FAMILIES
Entity / KYB
Beneficial owner
Bank-account match
Processor match
Fraud screen
Sanctions
These labels do not claim a live
provider connection.
BASELINE
30 / 30 usable days
$4,154.96 / day available
$25,000 authorized
RECESSION ENERGY
28 / 30 usable days
Eligible-sales feature unavailable
Capacity, risk & economics withheld.
Outcome: evidence decline.
Required: 30 usable days. Stress has two disconnected outage days.
Count display only—not the historical position of those outages.
A broad COMPLETE or REVIEW label does not replace the specific availability and binding-reason records.
TRY IT
Can a smaller request repair 738’s missing eligible-sales feature?
ANSWER
No. Revised terms cannot supply missing observations.
Required evidence must exist before dependent tests.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S11, S13, S15, S27 | 05 / 23


## Page 6

MSBF / MERCHANT FINANCE MASTERCLASS
I READ THE MERCHANT
Risk and economics answer different questions
06
A high contribution cannot cancel an adverse capacity, evidence or authority test.
M1.12 / COMPARATIVE RISK
1
Operating resilience
2
Capacity / burden
3
Liquidity
4
Source confidence
5
Verification / fraud
6
Processor continuity
7
Industry / relationship context
Weighted components + explicit floors
→ synthetic risk proxy and tier
M1.13–M1.14 / ECONOMIC BRIDGE
Comparative loss = weighted exposure
× synthetic risk proxy × LGD
Contribution = finance revenue − non-loss costs
− comparative loss − risk-capital charge
Non-loss costs: processing, acquisition, funding, servicing and operations. LGD is
modeled loss share after recovery.
CASE 098 / BASELINE REQUEST
$654.26 > $230.79
Contribution exceeds the required hurdle.
Hurdle = $5,200 × 18% × 90 / 365
Strict risk / resilience tier ≤2; review ≤3. Synthetic risk is not calibrated PD; contribution is not profit or APR.
TRY IT
Does clearing the economic hurdle compensate for a capacity failure?
ANSWER
No. Capacity and economics are separate required tests.
Strong contribution cannot waive another gate.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S05, S06, S07, S08, S01, S09 | 06 / 23


## Page 7

MSBF / MERCHANT FINANCE MASTERCLASS
II READ THE REQUEST
Read the request as four linked parameters
07
The total, the sales share and the timing benchmark do different jobs. Actual collection is a separate ledger.
CASE 098 / BASELINE
ADVANCE
$5,200
Capital requested
PAYBACK
1.259198×
T = round(A × m, 2)
REMITTANCE
10.9032%
Share of eligible sales
HORIZON
90 days
Assessment timing
Repayment target: $6,547.83 | Horizon demand: $72.75 / day
SEPARATE DAILY ILLUSTRATION / RATE = 10% / BALANCE SHOWN BEFORE COLLECTION
ELIGIBLE SALES
10% SHARE
REMAINING BALANCE
ILLUSTRATIVE REMITTANCE
$2,000
$200
$5,000
$200 — share binds
$2,000
$200
$80
$80 — balance caps collection
Assessment burden uses the larger test. Daily collection uses the smaller of sales share and remaining balance.
TRY IT
At $1,500 eligible sales and a $100 balance, what is a 10% remittance?
ANSWER
$100. The share is $150, but min($150, $100) = $100. All
assumptions belong to this illustration.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S03, S17 | 07 / 23


## Page 8

MSBF / MERCHANT FINANCE MASTERCLASS
II READ THE REQUEST
Change one term. Find the binding burden.
08
A lower amount or rate does not guarantee a lower assessment burden: the other leg can remain binding.
Hold fixed: S = $423.27/day · m = 1.259198 · margin = 30% · existing = $4.19/day
N = max[round(S × r, 2), round(round(A × m, 2) / H, 2)]
CONTROLLED VARIANTS — NOT R26 CANDIDATE RESULTS
CHANGE
AMOUNT
RATE
DAYS
N / DAY
Source request
$5,200
10.9032%
90
$72.75
Shorter horizon
$5,200
10.9032%
60
$109.13
Lower amount
$2,500
10.9032%
90
$46.15
Lower rate
$5,200
8.0000%
90
$72.75
Higher rate
$5,200
20.0000%
90
$84.65
TWO DEMANDS / $ PER DAY
Sales-share leg
Horizon leg
46.15
72.75
46.15
109.13
46.15
34.98
33.86
72.75
84.65
72.75
Follow the max operator. Changing a nonbinding leg can leave assessed burden unchanged.
TRY IT
Why does reducing the remittance rate to 8% leave N unchanged?
ANSWER
The $72.75 horizon leg still exceeds the $33.86
sales-share leg. The larger amount governs.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S03 | 08 / 23


## Page 9

MSBF / MERCHANT FINANCE MASTERCLASS
II READ THE REQUEST
Fit the structure inside the capacity boundary
09
The frontier is a composite test—not an average in which a strong buffer offsets weak coverage.
SOURCE CAPACITY GATES / AMOUNTS AND RATIOS ARE NOT INTERCHANGEABLE
DIMENSION
STRICT FRONTIER
REVIEW FRONTIER
WHAT IT PROTECTS
Coverage: cash / burden
≥ 1.25×
≥ 1.00×
Cash generation against commitments
Total burden / sales
≤ 22%
≤ 30%
Share of sales committed
Projected buffer / burden
≥ 15 days
≥ 5 days
Liquidity relative to commitments
Residual cash
≥ $0
Composite tier governs
No extra standalone tier-3 floor
Capacity tier
≤ 2
≤ 3
The conditions work together
082
SYNTHETIC MERCHANT 082
Large buffer, failed
request
BASELINE
127.8328
Buffer days / passes
0.7180×
Coverage / fails
33.4278%
Burden / fails
Stacking <3 is a tier-1 condition—not an independent universal veto for otherwise valid tier-2/3 paths.
TRY IT
Does a large bank balance prove merchant 082’s request is affordable?
ANSWER
No. Requested residual cash is −$471.87/day; coverage
and burden fail despite a large buffer.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S03, S04, S10, S12 | 09 / 23


## Page 10

MSBF / MERCHANT FINANCE MASTERCLASS
II READ THE REQUEST
What can revised terms fix—and what can’t they?
10
Read the specific condition before deciding whether to search, review, preserve an advisory or stop.
EVIDENCE
Missing required feature
Evidence decline
Do not zero-fill
HARD STOP
Non-remediable prohibition
Policy decline
Terms cannot waive it
STRUCTURE
Capacity / economics FAIL or REVIEW
Governed search
Recalculate alternatives
JUDGMENT
Conflict · MEDIUM confidence · fraud tier 3
Disrupted / unavailable continuity
Review can remain
Keep the binding review gate
ADVISORY
Processor WATCH or selected warnings
Critical evidence remains usable
Specific rule controls
Retain—not automatic decline
738 has verification REVIEW in both scenarios—but no binding human-judgment gate. The stress feature gap controls.
Human conditions are source-defined. A generic REVIEW label is not executable decision logic.
TRY IT
Why does 738’s broad verification REVIEW label not explain its stress evidence decline?
ANSWER
Its refined human gate is NONE. Stress separately lacks
30 usable POS days; that specific evidence failure binds.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S09, S10, S11, S13 | 10 / 23


## Page 11

MSBF / MERCHANT FINANCE MASTERCLASS
III SEARCH & DECIDE
Search a governed set—not an unlimited menu
11
M2.2 constructs and tests. M2.3 selects under authority and matched-scenario constraints.
Enter
remediable path
Construct
exact terms
Recalculate
all required tests
STRICT FRONTIER
Strict credit limits + economic hurdle
+ no remaining human-authority block
REVIEW FRONTIER
Review-eligible limits + economic hurdle
+ identified review requirements
Authority-first selection → preserve the matched-stress floor → retain the final decision record
40%
Min. amount / request
Max. reduction: 60%
30 / 60 / 90
Supported horizons
in days
0% / 2%
Repayment increase:
automatic / review
6,519
Reportable structures
—not approvals
Repayment guardrails use total target—not APR—with a $0.01 source rounding tolerance. Both frontiers require economics.
TRY IT
Can higher modeled return admit a candidate below the 40% amount floor?
ANSWER
No. Policy admissibility and feasibility come before
preference. The objective cannot waive a boundary.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S09, S10, S12, S13 | 11 / 23


## Page 12

MSBF / MERCHANT FINANCE MASTERCLASS
III SEARCH & DECIDE
Candidate lab: where the boundary moves
12
Merchant 082 / Baseline. Compare actual exported candidates—not a hypothetical search result.
CASE 082 / BASELINE
Sales $5,005.02/day · Existing payments $547.51/day
All rows: 13.0606% remittance · 1.255266× payback · 60 days
AMOUNT
COVERAGE
BURDEN / SALES
SOURCE STATUS
BINDING EXPLANATION
$53,800
0.7180×
33.4278%
INFEASIBLE
Requested capacity fails
$31,300
0.9991×
24.0227%
INFEASIBLE
Still below 1.00× review coverage
$31,200
1.0000×
23.9999%
REVIEW ELIGIBLE
Selected—but capacity + judgment review remain
$31,100
1.0000×
23.9999%
REVIEW ELIGIBLE
Not selected; same burden plateau
$2,500
1.0000×
23.9999%
INFEASIBLE
Below the $21,520 minimum amount
$31,300 → $31,200 crosses review feasibility.
It does not cross into automatic authority.
At lower amounts, the sales-share leg binds. Further principal
reduction need not reduce burden.
Do not round 0.9991× up to 1.00×. The actual boundary, selected flags and final authority govern.
TRY IT
Why does the $2,500 candidate fail despite 1.00× coverage?
ANSWER
It is 4.65% of the $53,800 request—below the 40% floor
($21,520). Passing capacity cannot override it.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S12, S13 | 12 / 23


## Page 13

MSBF / MERCHANT FINANCE MASTERCLASS
III SEARCH & DECIDE
A supportable structure still needs authority
13
Merchant 082 / Baseline. Two distinct reasons keep the selected alternative on a review path.
082
BASELINE CASE
$31,200
selected alternative
from a $53,800 request
13.0606% remittance
60 days
$39,164.30 target
COUNTEROFFER REVIEW REQUIRED
DIAGNOSE BOTH GATES — NOT ONLY THE FAVORABLE BUFFER
GATE 1 / CAPACITY
Review—not strict
Coverage 1.0000× < 1.25×
Burden 23.9999% > 22%
Capacity tier 3 > 2
Buffer 189.8346 days is strong
GATE 2 / HUMAN JUDGMENT
MEDIUM confidence
The source explicitly requires review.
Raising coverage alone does not remove
this condition.
BASELINE SUPPORTABILITY IS NOT THE AUTHORIZATION RATE
103 authorized
197 reviewable
300 supportable paths = 103 authorized + 197 reviewable
Supportable does not mean funded, accepted by the merchant, or automatically authorized.
TRY IT
Would raising coverage to 1.25× remove every reason for review?
ANSWER
Not necessarily. MEDIUM_DATA_CONFIDENCE remains,
and every other strict condition must still pass.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S09, S10, S11, S12, S13 | 13 / 23


## Page 14

MSBF / MERCHANT FINANCE MASTERCLASS
III SEARCH & DECIDE
Seven outcomes—and the reason behind each
14
Read the driver pattern as well as the label. The source final record resolves combined conditions.
AUTHORIZED
130 paths
115
As requested
Requested structure satisfies governing tests
and authority.
15
Counteroffer
A permissible alternative satisfies tests and
final authority.
REVIEW
250 paths
212
Counteroffer review
A selected alternative exists; a binding review
gate remains.
38
Manual underwriting
The source classification still requires
underwriting judgment.
DECLINE
1,120 paths
234
Insufficient evidence
Required inputs cannot support the
dependent assessment.
652
No feasible structure
No eligible final structure remains after search
and governance.
234
Policy hard stop
A non-remediable condition controls despite
revised terms.
130 + 250 + 1,120 = 1,500 application-scenario paths. Pooled taxonomy counts are not 1,500 merchants.
TRY IT
Can “no feasible structure” follow an independent review candidate?
ANSWER
Yes. For 082 stress, the matched-stress floor leaves no
eligible final candidate. Independent support is not final
authority.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S09, S10, S13, S18 | 14 / 23


## Page 15

MSBF / MERCHANT FINANCE MASTERCLASS
III SEARCH & DECIDE
The preferred candidate is not always the final one
15
Merchant 098 / Recession Energy. Governance can select a lower modeled return within the same amount.
CASE 098 / MATCHED SCENARIOS
SOURCE MEASURE
BASELINE
STRESS
Sales / day
$423.27
$386.18
Observed balance
$1,717.45
−$664.17
Coverage
1.6504×
1.5057×
Buffer days
41.8332
6.5393
Final amount
$5,200
$2,500
The stress request misses the strict 15-day buffer boundary. The
selected smaller structure is recalculated.
TWO ACTUAL $2,500 STRESS CANDIDATES / 90 DAYS
TERM / RESULT
INDEPENDENT
GOVERNED
Remittance
10.6851%
10.9032%
Payback
1.284382×
1.259198×
Modeled annual return
32.3130%
23.8175%
Role
Preferred locally
Final selected
The final preserves Baseline remittance and payback terms.
Recomputed: coverage 2.5022×, burden 11.9892%, buffer 30.7199
days.
Same rules, different constraints: 098 reselection | 082 no floor-eligible candidate | 738 missing evidence
Matched scenarios are alternatives—not time events or M2.11 profile changes. Modeled return is not APR or profit.
TRY IT
Why can’t 082 stress or 738 stress simply copy 098’s lower amount?
ANSWER
082 loses eligible candidates under the stress floor. 738
lacks required evidence. Neither is repaired by copying a
term.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S01, S12, S13, S15 | 15 / 23


## Page 16

MSBF / MERCHANT FINANCE MASTERCLASS
IV FOLLOW THE ACCOUNT
Follow the exact path into the account
16
A merchant identifier is not enough. Funding membership belongs to an application and a scenario.
DECISION RECORD → FUNDED MEMBERSHIP → ACCOUNT-DAY EVIDENCE
1,500
Decision paths
Application × scenario
130
Funded paths
103 Baseline + 27 Recession Energy
15,600
Monitoring account-days
130 funded paths × 120 days
CASE 738 / KEY LAB
RUN | SCENARIO | APPLICATION
FINAL DECISION
FUNDED MEMBERSHIP
1 | 5 | …M000738_A01
Baseline: $25,000 authorized
AccountKey + AdvanceKey exist
1 | 6 | …M000738_A01
Stress: evidence decline
No account / no funded match
Keys are abbreviated here. The full run / scenario / application identities are retained in the source-reading guide.
Authorization is not a universal guarantee of booking. This synthetic population has 130 of each; funded membership is the proof.
TRY IT
What happens when the stress-declined 738 path is joined only on merchant ID?
ANSWER
The Baseline account could leak into the stress path. Use
the complete run / scenario / application key.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S13, S14, S18, S19 | 16 / 23


## Page 17

MSBF / MERCHANT FINANCE MASTERCLASS
IV FOLLOW THE ACCOUNT
What does active monitoring actually watch?
17
All active families require an unpaid path. Families can overlap; a signal is not permission to act.
INPUT → SOURCE TEST → OPERATIONAL MEANING
PACE
Cumulative remittance / capped
expectation
Watch <90%: day ≥21. Adverse <75% / <50%: day ≥30.
Three consecutive eligible breaches.
Behind the selected structure’s expected trajectory.
NO REMITTANCE
Days since positive remittance
Day ≥14 and ≥7 days without positive remittance.
At ≥14 such days, dormant status can govern.
Collections have stopped—not merely slowed.
SALES DORMANCY
Consecutive zero-sales days
Day ≥14 and zero-sales streak ≥10.
Underlying sales activity has stopped.
LIQUIDITY
Balance · NSF events · negative flag
Day ≥7 AND any of: balance <0; NSF >0; negative flag.
Cash stress can arise before pace seasoning.
HORIZON
Elapsed day · selected horizon · unpaid
balance
Day ≥14; day > selected horizon; balance >0.
Repayment timing has overrun. The balance remains.
The selected structure sets the benchmark. Payments, sales, liquidity and elapsed time supply the changing observations.
TRY IT
Can day-8 liquidity create a watch signal before pace becomes eligible?
ANSWER
Yes. Liquidity starts at day 7 under its own conditions. The
21/30/3 rule applies to pace—not all signals.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S16, S17, S19 | 17 / 23


## Page 18

MSBF / MERCHANT FINANCE MASTERCLASS
IV FOLLOW THE ACCOUNT
Pace is a benchmark plus persistence
18
Merchant 749 / Baseline. Separate actual cash collected from the expected repayment benchmark.
749
SYNTHETIC MERCHANT 749
Actual vs expected pace
BASELINE
EXACT POLICY FRAGMENT
'pace_watch_eligibility_day': 21,
'pace_adverse_eligibility_day': 30,
'pace_persistence_days': 3,
r26_policy.py · lines 9–11
This fragment is not the complete status
model.
ACTUAL CASE / SELECTED TARGET $21,451.04 / HORIZON 90 DAYS
Expected(d) = min[round(T / H × d, 2), T]
Day 32: expected = $7,627.04
Actual cumulative remittance = $5,109.42
Pace = $5,109.42 / $7,627.04 = 66.99%
EARLIEST PACE-ONLY QUALIFICATION / NOT AUTOMATIC
Watch
21
22
23
<90% on each eligible day
Adverse
30
31
32
<75% / <50% on each eligible day
Expected cumulative repayment caps at T. R26 changes interpretation—not the retained physical remittance amounts.
TRY IT
Why can 66.99% qualify on day 32 while a poor earlier ratio did not?
ANSWER
Adverse pace needs three eligible breaches from day 30.
Earlier ratios earn no persistence credit; other rules still
apply.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S16, S17, S19 | 18 / 23


## Page 19

MSBF / MERCHANT FINANCE MASTERCLASS
IV FOLLOW THE ACCOUNT
One account. Several signals. One governed status.
19
Merchant 749 / Baseline. Improving pace does not erase an unpaid horizon overrun.
ACTUAL SELECTED OBSERVATIONS — NOT A MANDATORY STATUS STAIRCASE
DAY 7
53.81%
Cumulative pace
CURRENT
1 raw / 0 families
DAY 23
64.12%
Cumulative pace
WATCH
2 raw / 1 family
DAY 32
66.99%
Cumulative pace
UNDERPERFORMING
3 raw / 1 family
DAY 90
59.96%
Cumulative pace
UNDERPERFORMING
3 raw / 1 family
DAY 91
61.07%
Cumulative pace
SEVERE SHORTFALL
3 raw / 2 families
DAY 120
78.09%
Cumulative pace
SEVERE SHORTFALL
4 raw / 3 families
DAY 120 / WHY THE STATUS STAYS SEVERE
PACE: Watch-level family
LIQUIDITY: also active
HORIZON: 90 days exceeded; $4,699.37 unpaid
TWO DIFFERENT PRECEDENCE RULES
Status: paid off → dormant → severe → underperforming → watch →
current
Primary family: horizon → liquidity → sales dormancy → no remittance →
pace
Primary family is a label of precedence—not proof that every other active family disappeared.
TRY IT
At day 120, why does 78.09% pace not make the account merely Watch?
ANSWER
The unpaid 90-day horizon has been exceeded. Horizon
severity governs; pace and liquidity signals still remain.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S16, S19 | 19 / 23


## Page 20

MSBF / MERCHANT FINANCE MASTERCLASS
IV FOLLOW THE ACCOUNT
A recommendation is not permission to execute
20
The retained M2.6 branch is narrower than its captured context. Only the stated conditions select the route.
ACTUAL RETAINED ROUTING BRANCH
1
Paid off?
→ Closed / no further action
2
Else: severe + open_rank = 1?
→ Temporary remittance review
3
Else: Watch / adverse / dormant?
→ Targeted outreach review
4
Else
→ Continue standard monitoring
open_rank: unpaid exposure descending, then advance ID.
Other captured variables are not automatically extra branches.
OBSERVED ROUTES → SETUP → EXECUTION
126
Closed / no further action
Paid-off state
1
Temporary remittance review
Permitted active servicing
3
Targeted outreach review
Setup / processing held
CASE 749 / PROOF OF THE ACTIVE PATH
Setup authorized = true → Processing authorized = true
Execution outcome + payment events prove processing.
The source ownership chain is not a manufactured calendar of real events. Reaching a horizon does not forgive a receivable.
TRY IT
Does a targeted-outreach recommendation prove that an action happened?
ANSWER
No. The three outreach paths remain held. Read setup
permission, processing permission and the execution
result separately.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S20, S21, S22, S23, S25 | 20 / 23


## Page 21

MSBF / MERCHANT FINANCE MASTERCLASS
IV FOLLOW THE ACCOUNT
Reconcile the event—and the receivable
21
Merchant 749 / Baseline. A settled retry can resolve processing without paying off the account.
QUESTION 1 / DOES THE EVENT LEDGER RECONCILE?
SCHEDULED
$1,762.25
LESS RETURNED
−$251.75
PLUS SETTLED RETRY
+$251.75
NET PROCESSED
$1,762.25
7 source events = 5 settled + 1 returned + 1 retry. Do not add the retry twice: net is not $2,014.00.
QUESTION 2 / WHAT RECEIVABLE REMAINS AT EACH STAGE?
749 / M2.5 RECEIVABLE → AFTER M2.8
$4,699.37 − $1,762.25
= $2,937.12 still outstanding
FULL BASELINE PORTFOLIO BRIDGE
M2.5 $7,823.28 − $1,762.25
= M2.10 $6,061.03
$3,123.91 in three review holds
+ $2,937.12 active / reconciled
Stage-owned balances are not contradictory views of one state—and their bridge is not a measured loss reduction.
TRY IT
Can zero unresolved exceptions coexist with a $6,061.03 receivable?
ANSWER
Yes. Reconciliation establishes agreement of events and
balances. Payoff is a different question: is the receivable
zero?
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S19, S23, S24, S26 | 21 / 23


## Page 22

MSBF / MERCHANT FINANCE MASTERCLASS
IV FOLLOW THE ACCOUNT
Turn a portfolio number back into an explanation
22
Name the population, driver, rule and proof. Then show someone else how to trace the result.
BASELINE
103 / 750 = 13.7% authorized
300 supportable = 103 authorized + 197 review
Synthetic funding $1,385,300 | Paid off / funded 99 / 103
RECESSION ENERGY
27 / 750 = 3.6% authorized
80 supportable = 27 authorized + 53 review
Synthetic funding $344,200 | Paid off / funded 27 / 27
Each bar = 750 paths: teal authorized · gold review · pale declined.
TWO READ-ONLY INVESTIGATIONS — FOLLOW THE EVIDENCE, NOT THE CHART ALONE
082
SYNTHETIC MERCHANT 082
Why is $31,200 selected but not funded?
BASELINE / CANDIDATE → BINDING REVIEW GATES → FUNDED KEY
749
SYNTHETIC MERCHANT 749
Why does a resolved return leave exposure?
BASELINE / EXECUTION → ACCOUNT CERTIFICATION → BALANCE
Question + key
Driver + rule
Source proof
Certified insight
27/27 stress payoff is a selected-subset result—not proof stress improved performance. Power BI consumes source facts.
TRY IT
Which denominator answers authorization—and which answers payoff?
ANSWER
Authorization uses all 750 paths in the named scenario.
Payoff uses its funded subset: 103 or 27.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Evidence S13, S18, S23, S24 | 22 / 23


## Page 23

MSBF / MERCHANT FINANCE MASTERCLASS
TAKE THE REASONING WITH YOU
Understand the business.
Explain the decision.
23
Connect what is known, what is requested, what is permitted, and what happens next.
I  READ THE MERCHANT
Sales start
the question.
Usable evidence, cash flow
and existing obligations
shape capacity.
II  READ THE REQUEST
Terms work
together.
Evaluate amount, remittance,
payback and horizon as
one financing structure.
III  SEARCH & DECIDE
Support is not
authority.
A permissible alternative
must still clear its final
credit and judgment gates.
IV  FOLLOW THE ACCOUNT
Funding starts
a new question.
Monitor before acting.
Reconcile events and balances.
Explain what remains.
Do not stop at the outcome. Teach the reason behind it.
FINAL TRY IT
Choose one merchant case. Explain its outcome
without saying “because the model said so.”
ANSWER / TEACH-BACK CHECK
Name the inputs, the binding rule, the
permitted action and the account evidence.
Start with the merchant. Test the structure. Respect authority. Follow the account.
Andrew R. Goad · Synthetic MSBF · Non-production · No real funds
Teaching synthesis of lessons 01–22 | 23 / 23
