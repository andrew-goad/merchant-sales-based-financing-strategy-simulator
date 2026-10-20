# PostgreSQL M1.14 Execution

Part 01 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Next part](part-02.md)

<a id="m-3f1b6498-9e77-4b2f-b8dd-1c1ba01e7cf7"></a>
## Andrew / user · C072-M00001

C072-M00001 · 2026-07-27T00:39:48.983000-04:00 · active path

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: MSBF_Project_v0_2_M1_14_READY_FOR_EXECUTION_Windows(1).zip; MSBF_M1_14_v0_2(1).zip; MSBF_M1_14_v0_2.zip(1).sha256; MSBF_Project_v0_2_M1_14_READY_FOR_EXECUTION_Windows.zip(1).sha256; MSBF_New_Chat_Handoff_Package(1).zip; MSBF_New_Chat_Handoff_Package.zip(1).sha256; MSBF_Project_Transition_Handoff_M1_14(1).md; Enterprise_Merchant_Sales_Based_Financing_Platform(2)(1)(1).png; From_First_Advance_to_Intelligent_Portfolio (1).pdf; M1_14_EXECUTION_ORDER(1)(1).csv; M1_14_PACKAGE_VALIDATION_REPORT(1).md; M1_14_EXECUTION_AND_VALIDATION_GUIDE(1)(1).md; M1_13_LIVE_EXECUTION_EVIDENCE_REVIEW_AND_SIGNOFF(1).md; Ultimate-Guide-for-Banks-2024(1).pdf; Creating a successful risk management framework(1).pdf

<!-- BEGIN_SOURCE_MESSAGE -->
I am continuing a governed PostgreSQL project called the Merchant Sales-Based Financing Strategy Simulator.

Please first read the attached `MSBF_Project_Transition_Handoff_M1_14.md` in full and inspect the attached canonical repository `MSBF_Project_v0_2_M1_14_READY_FOR_EXECUTION_Windows.zip`. Treat those files—not conversational inference—as the source of truth.

CURRENT CANONICAL STATE
- Database: PostgreSQL 15, database name `msbf_strategy`, executed through DBeaver.
- Governed run: `M1_V0_2_BASELINE_BUILD`, run version 1.
- Current accepted database status: `M1_13_ACCEPTED`.
- M1.13 is formally accepted.
- M1.14 — Unit Economics & Risk-Adjusted Contribution Foundations is built and statically validated but has not yet been live-executed or accepted.
- Do not rebuild M1.14 and do not rerun any accepted module.

IMMEDIATE OBJECTIVE
Help me execute, validate, remediate if necessary, and formally accept M1.14 using the existing programs 100 through 107 in the attached repository.

Normal sequence:
100 schema and policy extension
101 preflight
102 generation
103 positive validation
104 negative controls
105 acceptance finalizer
106 master report
107 detailed report

Contingency programs 100A and 102A are not part of the normal sequence. Use them only for their documented recovery purposes.

EXECUTION RULES
- Use Execute SQL Script in DBeaver.
- Stop at the first PostgreSQL error.
- Never tell me to use Retry, Skip, or Skip All.
- Use `ROLLBACK;` after a failed transactional program.
- Never delete accepted business rows or manually reset run status unless a fail-closed governed recovery explicitly requires it.
- Preserve successful committed generation and fix only the affected stage onward.
- Structured CSV exports are sufficient evidence; execution logs are optional unless diagnosing a defect.
- If I say “batch 1 of 2, intake only,” acknowledge receipt and perform no substantive analysis until batch 2 arrives.

DEFECT-RESPONSE STANDARD
If execution exposes a defect:
1. classify it as generation, validation, reporting, performance, or evidence-export;
2. inspect all downstream scripts for the same defect class;
3. produce one consolidated version-aligned hotfix from the point of failure onward;
4. include a fail-closed recovery check;
5. preserve the original failure as audit evidence;
6. do not weaken a valid control merely to obtain a pass;
7. provide corrected clean-build source replacements for the final repository;
8. do not require unnecessary reruns of accepted or already committed stages.

NON-NEGOTIABLE SQL STANDARDS
- Consume accepted persisted outputs; do not regenerate upstream blueprints.
- Materialize expensive intermediates once, index them, and ANALYZE before large downstream joins.
- Prefer window functions to large self-joins when semantically equivalent.
- Use explicit CTAS and INSERT projections; avoid broad `alias.*` in joined projections.
- Resolve scenarios from accepted physical scenario panels and governed scenario sets, not global scenario-code uniqueness.
- Cast expected values to physical target types before hashing.
- Independently reconstruct hashes from persisted physical fields.
- Ensure visible composites reconcile to persisted visible components.
- Respect COMPLETE/PARTIAL/BLOCKED evidence gates in identity validation.
- Use `bool_or`/`bool_and`, not unsupported Boolean max/min aggregates.
- Attach `FILTER` to aggregate expressions before scalar wrappers or casts.
- Use session-scoped `ON COMMIT PRESERVE ROWS` tables for filterable user-facing DBeaver results.
- Invoke validation helper functions with `PERFORM`, not standalone `SELECT`.
- Preserve professional file headers, purpose/input/output/boundary comments, execution phases, CTE labels, and report-section descriptions.
- When changing comments or formatting only, perform a semantic logic-equivalence comparison before replacing accepted source.

ACCEPTANCE PROCESS
When I provide the complete evidence:
- review all positive and negative controls, counts, hashes, stage boundaries, master report, detailed reports, deterministic-mismatch output, and blocking-error output;
- determine acceptance honestly;
- if accepted, issue formal M1.14 sign-off, add the evidence and acceptance records, update project status, create the accepted standalone M1.14 ZIP, create the complete M1.14 full-project ZIP, generate manifests and SHA-256 files, and authorize M1.15;
- if not accepted, produce one consolidated hotfix rather than a sequence of narrow patches.

ROADMAP AFTER M1.14
- M1.15 — Latest Output, Archive, Comparison & Consumption Contract.
- M1.16 — End-to-End QA, Evidence & G2 Contract Acceptance.
- Then begin Module 2 strategy and offer decisioning.

Before answering technical questions, inspect the relevant source files in the attached repository. Keep responses direct, exact, and operational. Do not rebuild work that is already accepted or already packaged.
<!-- END_SOURCE_MESSAGE -->


<a id="m-958b399d-02bd-481e-85dc-f2fe1560ae73"></a>
## Assistant · C072-M00002

C072-M00002 · 2026-07-27T00:46:14.336162-04:00 · active path

Preceding visible parent: [C072-M00001](part-01.md#m-3f1b6498-9e77-4b2f-b8dd-1c1ba01e7cf7)

<!-- BEGIN_SOURCE_MESSAGE -->
## Canonical baseline confirmed

I have read the transition handoff in full and inspected the canonical repository rather than relying on prior conversational context.

Repository verification completed:

- **Canonical archive:** `MSBF_Project_v0_2_M1_14_READY_FOR_EXECUTION_Windows.zip`
- **Recomputed SHA-256:**  
  `4c99a53bfd0be331ee319762dd875ae82245598d2913e6383b38771e1b747c83`
- The recomputed hash matches the supplied checksum and the canonical checkpoint documented in the handoff.
- ZIP integrity testing completed with **no compressed-data errors**.
- The archive contains **1,616 entries**.
- The embedded M1.14 package contains **47 files**.
- All 47 embedded M1.14 files are byte-for-byte identical to the standalone `MSBF_M1_14_v0_2.zip`.
- The repository’s own M1.14 static-validation program completed with **PASS**:
  - 10 controlled SQL files
  - 82 positive validations
  - 7 negative controls
  - 20 detailed-report result sets
  - 74 snapshot columns
  - 14 component columns
  - no unsupported Boolean aggregates
  - no aggregate-`FILTER` defects
  - no destructive M1.14 business deletes
  - no standalone helper-function result tabs

Static validation does not establish live PostgreSQL acceptance; it confirms that this is the correct, internally consistent execution package. [export reference: filecite | turn1file13]

The governing baseline is therefore frozen as:

```text
Database                         msbf_strategy
PostgreSQL version               15
Governed run                     M1_V0_2_BASELINE_BUILD
Run version                      1
Required current run status      M1_13_ACCEPTED
M1.13                            Formally accepted
M1.14                            Built and statically validated
M1.14 live execution             Not yet completed
M1.14 formal acceptance          Not yet granted
```

M1.13’s formal sign-off confirms the accepted predecessor gate and the preserved combined M1.13 hash:

```text
11dca65763f4062ad9002244ee6452f9
```

[export reference: filecite | turn1file9]

I will not rebuild M1.14, rerun an accepted predecessor module, use 100A or 102A in the normal sequence, or authorize acceptance without the complete live evidence specified in the handoff. [export reference: filecite | turn1file1]

# Next controlled action: Program 100 only

From the extracted canonical repository, open:

```text
16_M1_14/sql/
100_msbf_m1_14_schema_policy_extension_v0_2.sql
```

In DBeaver:

1. Confirm the active connection is the PostgreSQL database:

   ```text
   msbf_strategy
   ```

2. Open the complete Program 100 file from the canonical extracted repository.
3. Use **Execute SQL Script** for the entire file.
4. Do not execute only the highlighted statement.
5. Do not run Program 100A.
6. Stop at the first PostgreSQL error.

A successful Program 100 execution must return one checkpoint row equivalent to:

```text
unit_economics_table_exists       true
component_table_exists            true
lineage_view_exists               true
snapshot_columns                  74
component_columns                 14
active_features                   14
policy_status                     APPROVED
methodology_version               M1_14_METHOD_V1
schema_policy_extension_status    PASS
```

These are the repository-defined Program 100 acceptance criteria. [export reference: filecite | turn1file0]

## Failure handling for Program 100

If PostgreSQL raises an error before the script’s transaction commits:

```sql
ROLLBACK;
```

Then preserve and provide:

- the complete PostgreSQL error text;
- SQLSTATE, when shown;
- the reported line or character position;
- the last successful DBeaver message;
- whether `COMMIT` appeared before the error.

Do not select **Retry**, **Skip**, or **Skip All**. Do not delete rows, reset the governed run status, or rerun earlier modules.

If the script reaches `COMMIT` but the final checkpoint query fails or reports anything other than `PASS`, do **not** rerun Program 100. Preserve the committed state and provide the exact error or checkpoint row for diagnosis.

After Program 100 succeeds, send its single result row. Program 101 will then be the next authorized execution step; it will live-confirm the required `M1_13_ACCEPTED` baseline, accepted predecessor identities, scenario scope, target emptiness, stage boundaries, and overall `preflight_status = PASS`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dd017052-59ae-457e-a871-cbc5d277d362"></a>
## Andrew / user · C072-M00003

C072-M00003 · 2026-07-27T00:50:40.163000-04:00 · active path

Preceding visible parent: [C072-M00002](part-01.md#m-958b399d-02bd-481e-85dc-f2fe1560ae73)

<!-- BEGIN_SOURCE_MESSAGE -->
Have you dug into the strategy, code, and evidence from prior modules as well as the plan for future modules? how well versed are you on the project as a whole? Also, how well versed are you on the process we've been following?
<!-- END_SOURCE_MESSAGE -->


<a id="m-e22f314b-e3d4-4f03-8d9a-5fb0141af97d"></a>
## Assistant · C072-M00004

C072-M00004 · 2026-07-27T01:02:24.327874-04:00 · active path

Preceding visible parent: [C072-M00003](part-01.md#m-dd017052-59ae-457e-a871-cbc5d277d362)

<!-- BEGIN_SOURCE_MESSAGE -->
# Yes—with a precise qualification

I am now **well versed in the project as an integrated enterprise platform**, not merely familiar with the immediate M1.14 execution sequence.

My first response emphasized the next operational action, Program 100. That was appropriate operationally, but it did not demonstrate the breadth of the review I had performed. At that point, I had read the transition handoff, verified the canonical archive and hashes, reviewed the M1.13 sign-off, and inspected the M1.14 package. I had **not** line-by-line re-audited every historical SQL revision and every prior evidence export.

I have since expanded the review across the repository’s design, current canonical source, validation histories, accepted evidence, recovery patterns, and forward architecture. I will not claim that I have memorized every line among the repository’s 1,616 entries, but I understand the project’s architecture, business logic, module lineage, control philosophy, accepted evidence chain, defect history, and operating process at a high level of detail.

## Current depth of understanding

| Area | Current depth | Important boundary |
|---|---|---|
| Enterprise strategy and architecture | **Very high** | I understand the four-module target architecture, shared control plane, evidence layer, learning loop, and one-/three-/five-plus-year progression. |
| Module 1 lineage, M1.2–M1.14 | **Very high** | I understand what each stage owns, its grain, accepted outputs, stage boundary, hashes, and important correction history. |
| M1.14 source, programs 100–107 | **Very high** | I have inspected the normal programs, their dependencies, transactions, outputs, validation controls, reports, and contingency scripts. |
| Governance and execution process | **Very high** | I understand the safe-state, evidence, defect-remediation, acceptance, versioning, and packaging workflow. |
| Every historical SQL revision | **Strong but intentionally not exhaustive** | Superseded source is audit history, not the operating baseline. I will inspect a historical revision when a defect or design question makes it relevant. |
| M1.15, M1.16, and Module 2 onward | **High at architecture and contract level** | Those stages are planned, not yet implemented. I will not pretend that unbuilt SQL or final parameters already exist. |
| Live database state | **Not independently queried** | The accepted evidence establishes M1.13; Program 101 must still confirm the live database prerequisite before generation. Static review cannot substitute for PostgreSQL execution. [export reference: filecite | turn0file2] |

# What I understand about the project as a whole

## 1. The strategic thesis

This is not simply a synthetic underwriting model or a collection of SQL exercises. It is an enterprise merchant-financing learning system.

The strategic progression is:

```text
Controlled launch
→ daily evidence
→ governed portfolio action
→ renewal and relationship development
→ strategy comparison
→ adaptive portfolio intelligence
```

The project deliberately starts with control, evidence, and learning rather than immediate scale. The eight-page strategy brief frames the first advance as the beginning of a learning system and connects daily sales evidence, early warning, portfolio action, renewal, relationship growth, and future strategy optimization. [export reference: filecite | turn0file1]

The platform’s analytical separation is fundamental:

```text
Source confidence
≠ verification and fraud
≠ processor continuity
≠ cash-flow behavior
≠ obligations and capacity
≠ operating resilience
≠ integrated risk proxy
≠ exposure and recovery
≠ comparative loss
≠ unit economics
≠ final offer and decision strategy
```

That separation prevents favorable evidence in one dimension from silently compensating for missing or blocked evidence in another.

## 2. The completed Module 1 chain

I understand the accepted progression and why the ordering matters:

```text
G0   Physical foundation
G1   Governed run control
M1.2 Deterministic merchant population
M1.3 Application and requested sales-linked structure
M1.4 Daily POS, settlement, and merchant ecosystem
M1.5 Deposit and liquidity history
M1.6 Matched baseline and stress overlays
M1.7 Source quality and data confidence
M1.8 Verification, fraud, and processor continuity
M1.9 As-of cash-flow features
M1.10 Obligations, liquidity, and residual capacity
M1.11 Cash-flow archetypes and operating resilience
M1.12 Merchant risk components and integrated risk proxy
M1.13 Exposure, recovery, and comparative loss
M1.14 Unit economics and risk-adjusted contribution
M1.15 Final latest/archive/comparison/consumption contract
M1.16 End-to-end QA and G2 acceptance
```

Each stage consumes accepted persisted outputs and adds one conceptually bounded layer. M1.14 is not permitted to create final pricing or an approval decision because those belong to Module 2.

## 3. The accepted evidence chain

I have reviewed the accepted counts and hashes, including the final M1.13 evidence:

```text
93,720 contractual-receivable/EAD path rows
1,500 exposure/recovery/loss snapshots
95,220 canonical entities
82 / 82 positive validations
7 / 7 negative controls
0 deterministic mismatches
```

The accepted M1.13 combined hash is:

```text
11dca65763f4062ad9002244ee6452f9
```

I also understand the substantive limitation carried into M1.14: no merchant had supported collateral or guarantee recovery evidence in this synthetic campaign. M1.13 therefore ended with 902 `PARTIAL` and 598 `BLOCKED` snapshots, rather than fabricating recovery support. [export reference: filecite | turn0file4]

That matters directly to M1.14: a `BLOCKED` comparative-loss record must not receive a manufactured after-loss contribution, risk-adjusted return, economic surplus, or favorable hurdle conclusion.

# How deeply I understand M1.14

I have reviewed the actual source structure, not only the execution guide.

## Input lineage

Program 102 consumes:

- accepted M1.13 exposure and schedule-adjusted comparative-loss evidence;
- accepted M1.10 capacity lineage;
- M1.3 requested funding, total repayment, finance charge, and payoff horizon;
- M1.2 partner-channel acquisition-cost evidence;
- the accepted physical `BASELINE` and `RECESSION_ENERGY` scenario panel.

It materializes the 1,500 matched scenario/application inputs once, creates a unique index, and runs `ANALYZE` before calculating the economics.

## Economic construction

The code separately calculates:

```text
Gross finance revenue
Processor/payment cost
Partner acquisition cost
Funding cost on path-weighted EAD
Servicing cost
Operating cost
Total non-loss cost
Contribution before comparative loss
Accepted M1.13 comparative-loss burden
Contribution after comparative loss
Synthetic risk-capital charge
Risk-adjusted contribution
Hurdle-required contribution
Economic surplus
```

The approved synthetic assumptions include, among others:

```text
Processor cost rate               0.006
Default partner cost rate         0.030
Annual funding cost               0.090
Capital allocation rate           0.120
Annual cost of capital            0.150
Annual return hurdle              0.180
```

Those are governed demonstration assumptions, not accounting, treasury-transfer-pricing, production-pricing, or regulatory-capital values.

## Evidence and stress behavior

The code applies three evidence states:

- `COMPLETE`
- `PARTIAL`
- `BLOCKED`

It independently calculates the economics and then applies the governed adverse-scenario interpretation:

- stress risk-adjusted contribution cannot improve over the matched baseline;
- stress annualized risk-adjusted return cannot improve;
- stress economic tier cannot improve;
- the underlying independent values remain visible for diagnosis.

## Determinism

Program 102:

1. creates target-typed expected snapshot rows;
2. creates 14 target-typed long-form component rows per snapshot;
3. hashes the target-typed expected records;
4. persists 1,500 snapshots and 21,000 components;
5. indexes and analyzes the persisted outputs;
6. reconstructs actual hashes from physical fields;
7. compares 22,500 canonical entities;
8. refuses to commit unless the mismatch count is zero.

Validation then reads the persisted outputs; it does not rebuild the economic blueprint.

## Control framework

I understand the 82 positive-control groups:

- governance and accepted upstream identities;
- cardinality and unique grains;
- revenue and non-loss cost identities;
- comparative loss, contribution, capital, return, hurdle, and surplus;
- evidence status, tier, routing, and matched-stress interpretation;
- wide-to-long component reconciliation;
- independent hashes and stage boundaries.

The seven negative controls intentionally prove rejection of:

- disabled generation;
- an invalid processor cost rate;
- invalid tier ordering;
- an unapproved policy;
- an unapproved stress scenario;
- prerequisite run-status drift;
- a post-generation rerun attempt.

The normal sequence and required outputs are exactly those in the execution guide. [export reference: filecite | turn0file3]

# How well I understand the prior defect history

I have not treated prior defects as incidental errors. They are now part of the engineering standard.

Examples:

- **M1.6:** expensive regeneration and a large self-join led to the permanent rules to consume accepted histories, materialize expensive stages once, use window functions where equivalent, and index and analyze before downstream joins.
- **M1.9:** the project learned not to assume scenario codes are globally unique; not to use broad `alias.*` in joined CTAS projections; to cast expected numerics to the physical target scale before hashing; to attach `FILTER` to the aggregate rather than a scalar wrapper; and to reconcile visible composites to persisted visible inputs.
- **M1.10:** the population identity had to come from the actual accepted population registry rather than an assumed evidence code; intended whole-table temporary updates were explicitly bounded to avoid DBeaver safety warnings.
- **M1.11:** the initial 313 composite findings were correctly decomposed into 237 non-blocked rounding differences and 76 intentionally blocked rows. A proposed remediation failed closed before any write because its precondition was wrong. The final remediation changed only the 237 supported composites and preserved the 76 blocked values as null.
- **M1.12:** generation, validation, and acceptance were valid; only the twentieth detailed-report query used the wrong primary-key column. The correction therefore began at reporting and did not rerun accepted generation.
- **M1.13:** PostgreSQL rejected `max(boolean)` before persistence. Recovery confirmed zero M1.13 business or evidence rows, and the consolidated correction used `bool_or(boolean)` without weakening the control or rerunning accepted predecessors.

That history is summarized in the handoff and preserved in the repository’s validation histories and source-history folders. [export reference: filecite | turn0file0]

# How well I understand the process we have been following

I understand it as a governed release and acceptance process, not merely a script-running routine.

## Normal module lifecycle

```text
Architecture and boundary
→ schema and policy
→ parameter and field dictionaries
→ preflight
→ deterministic generation
→ persisted physical reconciliation
→ positive validation
→ negative controls
→ acceptance finalizer
→ master report
→ detailed evidence
→ human evidence review
→ formal sign-off
→ accepted standalone package
→ updated full-project repository
→ manifests and SHA-256
→ authorization of next stage
```

## Execution discipline

I understand the practical DBeaver rules:

- execute the complete program with **Execute SQL Script**;
- stop at the first PostgreSQL error;
- never use Retry, Skip, or Skip All;
- issue `ROLLBACK;` after a failed transactional program;
- distinguish a pre-commit failure from a post-commit reporting failure;
- preserve committed generation;
- do not manually reset status or delete accepted business rows;
- retain filterable session-scoped result tables with `ON COMMIT PRESERVE ROWS`;
- use structured CSV evidence as the normal evidence package.

## Recovery discipline

For M1.14 specifically:

- **100A** is authorized only after Program 102 fails or is cancelled before commit, followed by `ROLLBACK;`. It verifies that the database remains at `M1_13_ACCEPTED` with zero M1.14 business, evidence, and gate rows.
- **102A** is authorized only when Program 102 committed successfully but the DBeaver result tab was lost. It reconstructs the checkpoint without changing business rows, evidence, hashes, or status.
- A validation or reporting defect after committed generation must not cause Program 102 to be rerun.

## Evidence-review discipline

I understand the two-batch protocol. When you say:

> batch 1 of 2, intake only

I should record receipt and perform no substantive evaluation until the second batch arrives.

Once the evidence is complete, acceptance requires review of:

- positive and negative controls;
- stage transitions;
- row counts and grains;
- stored and independently reconstructed hashes;
- matched baseline/stress behavior;
- wide/long component reconciliation;
- master report;
- all 20 detailed-report result sets;
- zero-row deterministic-mismatch output;
- zero-row blocking-error output.

Acceptance cannot be inferred merely because Programs 100–105 ran without a visible error.

# Future-module understanding

I understand the forward plan at the correct level of maturity.

## M1.15

This will create the governed Module 1 consumption layer:

- one latest scenario-aware row per application;
- immutable archive rows by run and scenario;
- matched baseline-versus-stress comparisons;
- end-to-end lineage;
- contract versioning and field dictionary;
- Power BI-ready consumption views;
- no approval, counteroffer, price, or decline.

## M1.16

This will close Module 1 through:

- full-population reconciliation;
- deterministic rerun evidence;
- cross-module hash-chain preservation;
- scenario completeness;
- latest/archive reconciliation;
- final contract validation;
- formal G2 acceptance.

## Module 2

The approved architecture then moves from evidence to governed offer strategy:

```text
Accepted M1 contract
→ eligibility and hard policy gates
→ segmentation and experiment assignment
→ candidate amount/remittance/horizon/price grid
→ collateral, guarantee, and covenant packages
→ offer-specific risk, EAD, LGD, and loss
→ acceptance elasticity and adverse selection
→ contribution and candidate ranking
→ regulatory applicability and compliance package
→ approve / counteroffer / review / decline
→ portfolio allocation and concentration controls
→ booking contract
→ matched strategy comparison
```

Modules 3 and 4 subsequently cover daily booked-account management, dynamic lines, renewal, loss mitigation, stress propagation, portfolio limits, strategy robustness, and capacity allocation.

The important qualification is that these are governed charters and contracts, not yet finalized implementation code. The final Module 2 physical design should consume the accepted G2 contract rather than reaching backward into Module 1 stage tables.

# Bottom-line assessment

I am sufficiently versed to:

- guide the M1.14 execution safely;
- interpret its outputs in the context of prior accepted modules;
- distinguish a real control failure from an execution, reporting, or evidence-export defect;
- preserve the latest safe committed state;
- audit downstream scripts for the same defect class;
- produce a consolidated, version-aligned correction when necessary;
- conduct the final acceptance review and package the accepted repository;
- proceed into M1.15 without violating the broader architecture.

I will still open the exact canonical source before answering any program-specific technical question. That is not a knowledge gap; it is the project’s correct source-of-truth discipline.
<!-- END_SOURCE_MESSAGE -->


<a id="m-044f168a-9888-4c95-a673-89ddfb7657eb"></a>
## Andrew / user · C072-M00005

C072-M00005 · 2026-07-27T12:19:59.036000-04:00 · active path

Preceding visible parent: [C072-M00004](part-01.md#m-e22f314b-e3d4-4f03-8d9a-5fb0141af97d)

<!-- BEGIN_SOURCE_MESSAGE -->
I'm continuing work using our parallel chat until that runs out of memory. I will pass along progress.

That said, I'd like to use this chat to discuss a feature that I wonder if we've thought about - marketing costs. I just had an interview with EXL Service for a separate Sr Credit Risk Analyst role and we walked through a case study that involved a new credit card product. They mentioned during the interview that one key cost is how the customer comes to the bank. Whether they click a Google link, respond to a flyer, via a relationship, etc and associated costs they have to pay depending on the channel that customers used to apply for the product. Is this something currently in our strategy, and if not, ideas on how we'd update our current strategy to include that. Do not update strategy yet, just research and discuss.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a4b7825b-7c39-4239-a8d5-20c091615ff9"></a>
## Assistant · C072-M00006

C072-M00006 · 2026-07-27T12:40:05.076818-04:00 · active path

Preceding visible parent: [C072-M00005](part-01.md#m-044f168a-9888-4c95-a673-89ddfb7657eb)

<!-- BEGIN_SOURCE_MESSAGE -->
Understood. I will treat this thread as the research and architecture discussion track while you continue live execution in the parallel chat.

# Finding: the concept is present, but only at a coarse level

Your interview did **not** uncover a complete omission. It uncovered that our current abstraction is one level too broad.

The project presently has:

1. **Marketing/conduct controls** in the regulatory architecture.
2. **Acquisition-channel identity** at the merchant and application level.
3. **A governed partner/channel acquisition-cost component** in M1.14.
4. **Planned channel segmentation and acquisition-cost treatment** in Module 2.

What it does **not** yet have is a genuine **marketing attribution and customer-acquisition-cost system** that distinguishes a Google click, direct-mail response, relationship referral, broker lead, processor referral, organic inquiry, and other acquisition paths.

So the precise assessment is:

> **We currently model channel-related acquisition cost, but we do not yet model the full acquisition funnel, campaign attribution, or fully loaded merchant CAC.**

M1.14’s documented fourteen-component economics already includes partner acquisition cost, but M1.14 remains built rather than live accepted. [export reference: filecite | turn0file0]

# What the canonical project already contains

I re-inspected the relevant canonical SQL in M1.2, M1.3, M1.14, and the future Module 2 charter.

## Existing channel structure

M1.2 created five deterministic partner/acquisition channels:

| Existing source channel | Application-channel mapping | Accepted M1.2 merchants | Synthetic acquisition-cost rate |
|---|---|---:|---:|
| Processor Direct | `PROCESSOR_EMBEDDED` | 255 | 1.00% |
| Bank Relationship | `RELATIONSHIP_MANAGER` | 135 | 0.75% |
| Digital Direct | `DIGITAL_DIRECT` | 150 | 1.80% |
| Strategic Partner | `STRATEGIC_PARTNER` | 120 | 2.50% |
| Broker Network | `BROKER_REFERRAL` | 90 | 4.50% |
| **Total / weighted design rate** |  | **750** | **1.775%** |

These are governed **synthetic assumptions**, not asserted market benchmarks.

M1.3 then carries the partner channel onto the application and uses it in parts of the synthetic requested-structure logic. For example, bank-relationship applications receive modestly more favorable synthetic remittance/payback positioning, while broker-network applications receive modestly more burdensome positioning. That is intended to represent relationship and sourcing differentiation, not a final credit decision.

The exact sources inspected were:

- `04_M1_2/sql/11_msbf_m1_2_deterministic_merchant_population_v0_2.sql`
- `05_M1_3/sql/18_msbf_m1_3_application_request_generation_v0_2.sql`
- `16_M1_14/sql/102_msbf_m1_14_unit_economics_generation_v0_2.sql`
- `16_M1_14/sql/103_msbf_m1_14_unit_economics_validation_v0_2.sql`
- `16_M1_14/tests/107_MSBF_M1_14_Unit_Economics_Detail_Report_v0_2.sql`

They are contained in the canonical repository (historical reference: `sandbox:[session]/MSBF_Project_v0_2_M1_14_READY_FOR_EXECUTION_Windows(1`; referenced bytes not established here).zip).

## Existing M1.14 acquisition-cost calculation

M1.14 calculates:

```text
Partner Acquisition Cost
=
Requested Funding Amount
×
Governed Partner Acquisition Cost Rate
```

Its controls include:

```text
Supported channel rate when available
Default rate                         3.00%
Maximum governed rate               8.00%
Evidence status                     SUPPORTED or DEFAULT_PARAMETER
```

The amount is classified as **synthetic conditional-if-booked economics**. It is not a posted accounting expense or an actual vendor invoice.

The acquisition cost is then included in:

```text
Processor Payment Cost
+ Partner Acquisition Cost
+ Funding Cost
+ Servicing Cost
+ Operating Cost
=
Total Non-Loss Cost
```

It consequently reduces contribution before comparative loss, contribution after loss, risk-adjusted contribution, and economic surplus.

M1.14 also has:

- a dedicated long-form `PARTNER_ACQUISITION_COST` component;
- positive validation `M1_14_POS_33_PARTNER_COST_IDENTITY`;
- an acquisition-rate support and cap control;
- detailed reporting by channel and evidence status;
- partner-channel reporting of revenue, total non-loss cost, risk-adjusted contribution, return, and hurdle passes.

That is a credible **version-one channel-cost foundation**.

## Existing Module 2 strategy treatment

The future Module 2 charter already calls for:

```text
M2.4 — Merchant, risk, cash-flow, relationship,
       industry, and channel segmentation
```

Its expected booked contribution formula already subtracts:

```text
Partner / Broker / Acquisition Cost
```

alongside funding, servicing, payment, loss, capital, and incentive costs.

Therefore, acquisition source was anticipated as both an economics input and a strategy segmentation dimension. The gap is the detail and evidence supporting that input.

# Why this is not yet the same feature discussed in your interview

The current field is most naturally interpreted as a **partner commission or coarse acquisition-cost proxy**. It works reasonably well for a broker or strategic partner paid as a percentage of funded volume.

It is much less suitable for Google Ads, direct mail, or an existing relationship:

| Source example | Natural cost basis | Why one percentage-of-funding rate is insufficient |
|---|---|---|
| Google or Bing paid search | Cost per click, lead, application, or conversion | The bank pays for unsuccessful clicks and abandoned applications too. |
| Direct-mail flyer | Printing, list, postage, and campaign cost per piece | Most recipients never respond, so funded accounts must absorb nonresponse cost. |
| Broker or ISO | Per lead, per funded account, or percentage of funded amount | The existing percentage model may fit, but actual contracts can vary. |
| Strategic partner | Fixed fee, revenue share, funded-volume fee, or hybrid | Contract terms may include minimums, tiers, or performance bonuses. |
| Bank relationship or RM | Internal labor and allocated relationship cost | External media spend may be low, but the channel is not costless on a fully loaded basis. |
| Organic/direct traffic | SEO, content, brand, and platform allocation | Zero marginal click cost does not necessarily mean zero acquisition cost. |

The CFPB’s 2024 consumer-finance circular describes digital intermediary compensation using fee-per-click, per-application, per-conversion, per-offer, per-sale, and per-lead arrangements. That circular is consumer-focused and is not a legal classification for this merchant-financing product, but it illustrates why acquisition costs require multiple cost bases rather than one percentage assumption. [export reference: cite | turn589228view2]

OCC credit-card and retail-lending materials similarly distinguish direct, internet, mail, and third-party acquisition channels. The credit-card profit procedures call for fully loaded income and expense reporting, explicit review of marketing expense, cost accounting by product, segment, channel, and account, and profitability comparisons across channels. Again, that is a banking design and supervisory benchmark rather than a direct merchant-financing rule, but it closely matches the issue raised in your interview. [export reference: cite | turn589228view0 | turn589228view1 | turn470801view3]

# The most important gaps

## 1. No true top-of-funnel population

The simulator begins with 750 merchants and 750 submitted applications. It does not presently represent:

```text
Marketing impressions
→ clicks or responses
→ leads
→ application starts
→ submitted applications
→ approvals or counteroffers
→ accepted offers
→ funded merchants
```

Without those earlier stages, it cannot calculate true cost per funded merchant because it does not allocate the cost of people or businesses who clicked, responded, abandoned, were declined, or rejected the offer.

## 2. No granular source or campaign attribution

`DIGITAL_DIRECT` does not distinguish:

- paid search;
- organic search;
- paid social;
- display;
- affiliate;
- email;
- bank website;
- app or online banking cross-sell;
- processor portal;
- comparison site;
- retargeting.

Likewise, `BANK_RELATIONSHIP` does not distinguish branch, treasury-management relationship, merchant-services relationship, relationship manager, existing deposit customer, or prior financing customer.

## 3. No separation of cost types

The present partner acquisition cost can unintentionally combine several economically different items:

```text
Paid media spend
Lead-purchase expense
Broker or partner commission
Relationship-manager sales expense
Customer acquisition incentive
Origination and verification expense
Allocated campaign overhead
```

These should not all be placed into one component. They have different owners, cost bases, accounting treatment, timing, and strategy implications.

M1.14 already has operating and servicing costs, while Module 2 separately anticipates incentive or retention cost. A future design would need explicit boundaries to avoid double counting.

## 4. No marginal-versus-fully-loaded view

For channel optimization, management may want **marginal CAC**: the incremental cost of acquiring one additional merchant.

For product and enterprise profitability, Finance may want **fully loaded CAC**, including allocated staff, technology, agency, creative, and campaign overhead.

Both are useful, but they answer different questions.

## 5. No relationship-lifetime treatment

The first advance should normally bear the original acquisition cost. A later renewal should not automatically incur the same full CAC again.

A renewal might instead incur:

- a small remarketing cost;
- relationship-management expense;
- renewal incentive;
- servicing or re-underwriting cost.

This distinction is particularly important because our strategy treats the first advance as the beginning of a merchant relationship, not the end of an isolated transaction. The approved strategy brief emphasizes renewal, relationship growth, and a continuous evidence-and-learning cycle. [export reference: filecite | turn0file1]

## 6. No channel-quality feedback loop

The cheapest source is not necessarily the best source.

A channel can differ in:

- submission and funding conversion;
- verification quality;
- fraud and misrepresentation;
- manual-review burden;
- merchant risk mix;
- expected loss;
- early repayment performance;
- renewal rate;
- relationship value;
- complaints and conduct risk.

OCC’s credit-card procedures specifically contemplate monitoring application volume, approval, booking, applicant quality, and credit performance by third-party originator. That supports treating source channel as both an economics and performance dimension rather than merely a cost field. [export reference: cite | turn589228view0]

# What the industry material suggests

The EXL paper already gives us two important conceptual anchors:

- POS application flows are embedded in a purchase journey with multiple entry points.
- Strategy should consider customer lifetime value rather than evaluating only the individual transaction.

Although that white paper concerns consumer POS lending, those principles transfer well to merchant acquisition: we should understand both where the merchant entered and what the resulting relationship became. [export reference: filecite | turn0file6]

The ChargeAfter architecture on page 14 places **Merchant Marketing** and consumer promotional offers outside—but connected to—the core underwriting and servicing platform. That is a useful architectural signal: marketing is an enablement layer with its own evidence and operating model, not simply another credit-risk field. [export reference: filecite | turn0file5]

For this merchant-financing product, marketing-source governance also matters independently of economics. The FTC identifies marketers, ISOs, brokers, and lead generators as participants across the small-business financing process and advises providers to vet, contractually govern, monitor, audit, and respond to complaints involving those agents. FTC staff has also specifically discussed MCA providers’ reliance on brokers and lead generators paid commissions for leads. [export reference: cite | turn589228view3 | turn589228view4]

# Recommended future architecture

I would **preserve the existing M1.14 component** and add a parallel, more precise acquisition-economics capability later. Renaming or overloading the accepted `partner_acquisition_cost` field would weaken its lineage.

A sound future taxonomy would be:

```text
Partner / Broker Acquisition Cost
+ Paid Media Cost
+ Lead Purchase Cost
+ Direct-Mail / Event Cost
+ Internal Sales or RM Acquisition Cost
+ Acquisition Incentive
+ Allocated Campaign Overhead
=
Total Merchant Acquisition Cost
```

The future platform should retain both:

```text
Direct Attributable Acquisition Cost
Fully Loaded Acquisition Cost
```

## Conceptual data layers

| Proposed layer | Purpose |
|---|---|
| `acquisition_channel` | Defines channel family, platform, partner, owned/paid/relationship status, third-party status, and permitted cost basis. |
| `marketing_campaign` | Defines product, offer, audience, geography, budget, creative, effective dates, and approvals. |
| `acquisition_touchpoint` | Records first, last, primary, and assisted interactions before application. |
| `acquisition_funnel_event` | Records impression, click, lead, application start, submission, approval, acceptance, and funding events. |
| `acquisition_cost_ledger` | Records fixed and variable costs, vendor or internal source, cost basis, amount, date, and supporting evidence. |
| `application_acquisition_attribution_snapshot` | Resolves each application to first-touch, last-touch, primary, and weighted attribution. |
| `merchant_acquisition_economics_snapshot` | Produces marginal CAC, fully loaded CAC, payback, contribution net of CAC, and relationship-LTV economics. |

Because this project already uses the word **campaign** for governed simulation and comparison campaigns, a marketing object should be called `marketing_campaign_id` or `acquisition_campaign_id`, not merely `campaign_id`.

## Evidence treatment

The acquisition capability should follow the project’s existing evidence principles:

```text
COMPLETE
Source, campaign, cost basis, amount, and attribution are supported.

PARTIAL
Source is known, but part of the cost is allocated or governed-default.

BLOCKED
Source, attribution, or material acquisition cost cannot be supported.
```

Unknown acquisition expense should not be silently converted to zero.

## Core metrics

The useful metrics would extend well beyond a single CAC number:

```text
Cost per click or response
Cost per qualified lead
Cost per submitted application
Cost per approved application
Cost per funded merchant
Submission-to-funding conversion
Funded dollars per acquisition dollar
Risk-adjusted contribution per acquired merchant
Risk-adjusted contribution per acquisition dollar
CAC payback period
First-advance contribution net of CAC
Expected merchant lifetime contribution / CAC
Fraud, loss, review, and complaint rates by channel
Renewal rate and relationship value by original source
```

# Scenario treatment

There should be a distinction between **observed** and **prospective** acquisition costs.

For an application that has already arrived, its acquisition cost is effectively sunk. It should normally remain the same in the matched `BASELINE` and `RECESSION_ENERGY` views. That is consistent with M1.14’s current design.

In a future strategy simulation, however, we could vary:

- channel mix;
- search or lead-auction prices;
- campaign budgets;
- response and application rates;
- partner commission schedules;
- conversion rates;
- channel-specific merchant quality;
- economic conditions affecting advertising competition.

That would allow the simulator to answer a much more valuable question:

> Should the firm spend the next acquisition dollar on processor-embedded merchants, bank relationships, paid digital leads, strategic partners, or brokers—and what risk-adjusted relationship value is expected from each?

# Where this should fit in the roadmap

I would not reopen M1.2, M1.3, or the currently executing M1.14 build.

The clean path is:

```text
M1.14
Complete and accept the current channel-cost foundation.

M1.15
Expose the existing partner channel, channel-cost evidence,
rate, and amount through the final consumption contract.
Do not turn M1.15 into a marketing-event generator.

M1.16
Document campaign-level attribution and full-funnel CAC
as a known future-development boundary, not a defect.

Module 2 foundation
Introduce governed acquisition-source, attribution, and
cost evidence before offer ranking and channel segmentation.

Later portfolio-learning cycle
Measure actual channel conversion, risk, contribution,
renewal, and LTV; then optimize acquisition budget and mix.
```

If full-funnel CAC were later determined to be indispensable to the G2 contract, it should be introduced through an explicitly authorized, bounded pre-G2 stage—not silently inserted into M1.15 or retrofitted into accepted modules.

# Overall assessment

This is a **meaningful enhancement**, but not evidence that the current strategy is fundamentally incomplete.

The project already recognizes:

- acquisition channel;
- different synthetic channel economics;
- relationship versus broker sourcing;
- partner acquisition cost in unit economics;
- channel diagnostics;
- future channel segmentation and expected contribution.

The interview identified the next level of maturity:

> **Move from a channel-rate proxy to governed acquisition attribution, full-funnel CAC, and lifetime channel economics.**

That enhancement would materially strengthen the platform because it connects Credit Risk, Finance, Marketing, Sales, Partner Management, Compliance, and relationship strategy in one traceable decision system. No canonical artifact should change based on this discussion yet.
<!-- END_SOURCE_MESSAGE -->


<a id="m-dd8d52c5-10cb-492b-9d4d-d32cb6e66d24"></a>
## Andrew / user · C072-M00007

C072-M00007 · 2026-07-27T12:46:40.117000-04:00 · active path

Preceding visible parent: [C072-M00006](part-01.md#m-a4b7825b-7c39-4239-a8d5-20c091615ff9)

<!-- BEGIN_SOURCE_MESSAGE -->
I should note that M1.14 was tested, evidenced, and approved. The other chat is almost done building M1.15.  Can we adjust and perform this update in a M1.16?
<!-- END_SOURCE_MESSAGE -->


<a id="m-cf0d0fcf-8b4c-48d5-aa9c-76bcc0879efb"></a>
## Assistant · C072-M00008

C072-M00008 · 2026-07-27T12:52:57.761916-04:00 · active path

Preceding visible parent: [C072-M00007](part-01.md#m-dd8d52c5-10cb-492b-9d4d-d32cb6e66d24)

<!-- BEGIN_SOURCE_MESSAGE -->
# Yes—but M1.16 should become a new feature module, not remain the QA module

I will now treat the current canonical state as:

```text
M1.14 — ACCEPTED
M1.15 — IN DEVELOPMENT / NEARING COMPLETION
```

The older transition handoff is therefore historical with respect to status.

The cleanest roadmap adjustment is:

| Stage | Revised purpose |
|---|---|
| **M1.15** | Latest Output, Archive, Comparison & Consumption Contract — complete the current build without reopening M1.14 |
| **M1.16** | **Acquisition Source, Marketing Attribution & Merchant Acquisition Cost Foundations** |
| **M1.17** | End-to-End QA, Evidence & G2 Contract Acceptance |
| **Module 2** | Use acquisition evidence in offer economics, expected booked contribution, channel segmentation, and strategy comparison |

The existing roadmap assigned end-to-end QA and G2 acceptance to M1.16. I would move that work to M1.17 rather than combine new business-data generation with the supposedly independent final QA gate. [export reference: filecite | turn2file0]

That separation preserves the process we have followed:

```text
Build the feature
→ validate and accept the feature
→ independently validate the full Module 1 contract
→ grant G2
```

It would be poor governance to introduce new acquisition logic and simultaneously use the same module to certify the entire contract as complete.

# Why M1.16 is the right insertion point

The acquisition feature belongs before Module 2 because Module 2 will need the information to evaluate:

- channel-specific economics;
- conditional contribution;
- expected booked contribution;
- broker and partner costs;
- marketing spend already incurred;
- channel mix;
- application quality by source;
- eventual CAC payback and relationship value.

The EXL paper specifically characterizes POS application flows as having multiple entry points and recommends evaluating risk-reward through customer lifetime value rather than only the isolated transaction. [export reference: filecite | turn2file6]

The broader industry architecture also places merchant marketing as an enablement capability connected to—but distinct from—the core banking and underwriting components. That supports creating a governed acquisition layer rather than burying marketing cost inside the credit-risk proxy or one generic operating-cost field. See the architecture diagram on page 14. [export reference: filecite | turn2file5]

This also fits the platform’s existing strategic thesis: the first advance begins a relationship and a learning cycle; it is not merely a one-time application decision. [export reference: filecite | turn2file1]

# What M1.16 should own

M1.16 should create the **acquisition evidence foundation**, not marketing optimization.

Its business question should be approximately:

> Through what governed source, channel, partner, campaign, and interaction path did each merchant application arrive, what acquisition costs were incurred or would become payable, how reliable is that evidence, and what acquisition information should be passed to strategy and portfolio economics?

## Candidate logical outputs

The exact physical names should be finalized only after inspecting the completed M1.15 source, but the logical structure should resemble:

| Logical output | Grain | Purpose |
|---|---|---|
| `acquisition_source_profile` | One row per governed acquisition source | Maps existing partner channels to paid, organic, embedded, relationship, broker, and partner sources |
| `marketing_campaign` | One row per governed campaign | Stores channel, platform, audience, dates, budget, product, campaign status, and approved cost basis |
| `campaign_funnel_snapshot` | Campaign × funnel stage | Stores impressions, clicks/responses, leads, application starts, and submitted applications |
| `acquisition_cost_ledger` | Campaign/source × cost item | Stores paid media, direct mail, lead, internal sales, campaign overhead, incentive, and partner costs |
| `application_acquisition_attribution` | One row per application | Stores primary, first-touch, last-touch, assisted, partner, and campaign attribution |
| `application_acquisition_cost_snapshot` | One row per application | Stores attributed incurred cost, conditional cost, fully loaded cost evidence, and support status |
| `application_acquisition_cost_component_value` | Application × cost component | Long-form transparent cost components |
| Versioned contract extension | Application or application × scenario | Makes the accepted evidence consumable by Module 2 |

I would avoid one physical record per advertising impression or web click. Campaign-level funnel aggregates plus application-level attribution are sufficient for this simulator and avoid manufacturing an unnecessarily large event population.

# The most important design distinction: when the cost is incurred

The feature should not combine every acquisition cost into one undifferentiated number.

There are at least two economically different classes.

## 1. Pre-application or already-incurred acquisition costs

These are incurred whether the application is approved or funded:

```text
Paid-search spend
Direct-mail printing and postage
Purchased lead fees
Event or outbound campaign expense
Internal relationship-manager acquisition effort
Agency and creative expense
Allocated campaign overhead
```

These costs should not be multiplied by approval or funding probability later. The organization has already incurred them.

## 2. Conditional-on-booking acquisition costs

These become payable only when the merchant funds or meets another contractual condition:

```text
Broker commission
Partner success fee
Processor revenue share
Percentage of funded amount
Funded-account incentive
```

These belong within conditional-if-booked economics.

That distinction produces the correct future Module 2 identity:

```text
Expected Net Contribution After Acquisition
=
Probability of Funding
× Conditional Booked Contribution
− Attributed Pre-Application Acquisition Cost
```

Where applicable, conditional partner or broker fees are already included inside conditional booked contribution.

This is materially better than:

```text
Probability of Funding
× (Contribution − All Marketing Costs)
```

because the second formulation incorrectly probability-weights marketing costs that have already been spent.

# How M1.14 should be preserved

M1.14 must remain accepted and immutable.

Its existing:

```text
partner_acquisition_cost_rate
partner_acquisition_cost_amount
```

should not be renamed, overwritten, or recomputed.

M1.16 should treat that accepted amount as a **conditional partner/channel acquisition-cost proxy** and retain full lineage to it.

The new acquisition layer should separately identify:

```text
M1.14 partner/channel cost
Pre-application paid-media cost
Lead-purchase cost
Direct-mail or event cost
Internal sales/RM cost
Campaign-overhead allocation
Acquisition incentive
Any overlap adjustment
```

A future total can then be expressed transparently:

```text
Total Acquisition Cost Evidence
=
Accepted M1.14 Partner/Channel Cost
+ Attributed Pre-Application Marketing Cost
+ Internal Acquisition Cost
+ Allocated Campaign Overhead
+ Other Non-Overlapping Acquisition Cost
− Identified Overlap
```

## Double-counting control

This is essential because some existing M1.14 channel rates may function as broad synthetic channel-cost proxies, especially for `DIGITAL_DIRECT` and `BANK_RELATIONSHIP`, rather than literal vendor commissions.

M1.16 should therefore include fields such as:

```text
legacy_m1_14_cost_scope_code
included_in_m1_14_flag
cost_overlap_status
overlap_adjustment_amount
incremental_acquisition_cost_amount
```

The original M1.14 amount remains visible. M1.16 determines whether a new component is additive, overlapping, or a replacement in the enhanced view.

# What we can calculate in M1.16—and what we cannot

M1.16 can credibly calculate:

```text
Cost per impression
Cost per click or response
Cost per lead
Cost per application start
Cost per submitted application
Attributed acquisition cost per application
Direct attributable acquisition cost
Fully loaded application-stage acquisition cost
Channel and campaign conversion through submission
Application risk and economic mix by acquisition source
```

It should **not** claim to calculate:

```text
True cost per approved merchant
True cost per accepted offer
True cost per funded merchant
Realized CAC payback
Realized merchant lifetime value
Optimal marketing budget allocation
Optimal channel mix
```

Those require Module 2 decisions and, for realized measures, booked-account performance from later modules.

A funded-account CAC denominator does not yet exist in Module 1. Using an assumed approval rate merely to manufacture that metric would weaken the otherwise strong stage boundary.

# Recommended channel taxonomy

The current five partner channels should remain the parent structure:

```text
PROCESSOR_DIRECT
BANK_RELATIONSHIP
DIGITAL_DIRECT
STRATEGIC_PARTNER
BROKER_NETWORK
```

M1.16 can add a subordinate acquisition-source taxonomy, for example:

| Existing parent channel | Potential acquisition sources |
|---|---|
| Processor Direct | Processor portal, embedded dashboard, processor outreach |
| Bank Relationship | Relationship manager, branch/business banker, treasury management, existing deposit relationship |
| Digital Direct | Paid search, organic search, paid social, display, email, bank website |
| Strategic Partner | Association referral, software-platform referral, merchant-services partner |
| Broker Network | Purchased lead, broker referral, ISO referral |
| Additional direct outreach | Direct mail, event, outbound call, targeted email |

This preserves accepted M1.2 and M1.3 lineage rather than replacing it with a competing channel taxonomy.

# Attribution should remain transparent

For the first implementation, I recommend storing multiple attribution views but using one governed primary method:

```text
first_touch_source
last_touch_source
primary_attributed_source
primary_campaign_id
assisted_touch_count
attribution_method_code
attribution_confidence_status
```

A practical primary method could be:

```text
Governed primary source
→ otherwise last known non-direct source
→ otherwise accepted parent partner channel
→ otherwise BLOCKED
```

We should not claim sophisticated multi-touch attribution without the data to support it. The architecture can retain weighted-attribution fields for future use, but the initial method should remain deterministic and explainable.

# Evidence treatment

M1.16 should retain the project’s established evidence grammar:

```text
COMPLETE
Campaign, source, cost basis, cost amount, attribution,
and application linkage are all supported.

PARTIAL
The primary source is supported, but some cost is allocated,
estimated, or governed-default.

BLOCKED
The source, attribution, or material acquisition-cost basis
cannot be reliably established.
```

Important controls:

- unknown cost is not zero cost;
- organic is not automatically free;
- relationship acquisition is not automatically free;
- paid media cost is not conditional on approval;
- broker commission is not automatically incurred at application;
- a blocked acquisition record cannot be presented as low-cost acquisition.

# Scenario treatment

For the current 750 applications, acquisition source and spend occurred before the Module 1 baseline-versus-stress comparison. Therefore:

```text
Application acquisition attribution
and incurred marketing cost
should normally be scenario-invariant.
```

M1.16 can retain one application-level acquisition record and project it into both scenario rows through the integrated consumption contract.

Controls should prove that:

```text
BASELINE acquisition cost
=
RECESSION_ENERGY acquisition cost
```

for the same application, unless a future governed marketing scenario explicitly changes prospective channel economics.

Future portfolio simulation may vary:

- channel mix;
- media auction cost;
- response rates;
- lead prices;
- partner commissions;
- application quality by source.

That prospective optimization belongs later, not in the historical matched application scenarios.

# How M1.15 should be handled

The current M1.15 build should continue. There is no reason to rebuild M1.14 or discard M1.15 work.

The preferred treatment is:

1. Complete and accept M1.15 as the current consumption-contract baseline.
2. Preserve its physical latest and archive rows.
3. Let M1.16 publish either:
   - a versioned acquisition companion contract; and
   - a new integrated consumption view/version that combines M1.15 with M1.16.
4. Complete full reconciliation and G2 acceptance in M1.17.

For example:

```text
M1.15 contract       M1_APPLICATION_RISK_CONTRACT_V1_0
M1.16 extension      M1_ACQUISITION_ECONOMICS_CONTRACT_V1_0
Integrated contract  M1_APPLICATION_RISK_CONTRACT_V1_1
```

The specific version notation should follow whatever contract registry the nearly completed M1.15 actually implements.

The best physical pattern is likely **companion tables plus a new versioned integrated view**, rather than adding columns to already accepted M1.15 rows. That preserves immutability and makes the change auditable.

# M1.16 validation and acceptance expectations

A complete governed module should include controls for:

| Control family | Required proof |
|---|---|
| Population | Every accepted application has exactly one acquisition-attribution disposition |
| Lineage | Parent partner channel reconciles to accepted M1.2/M1.3 evidence |
| Temporal integrity | Campaigns and touchpoints do not occur after the application as-of date |
| Funnel integrity | Impressions ≥ responses/clicks ≥ leads ≥ starts ≥ submissions |
| Campaign cost | Cost ledger totals reconcile to campaign budget/spend |
| Allocation | Application-level allocations reconcile to allocable campaign costs |
| Cost timing | Incurred and conditional costs are not mixed |
| Double counting | M1.14 partner cost is not counted twice |
| Evidence gates | COMPLETE/PARTIAL/BLOCKED treatment is honored |
| Scenario treatment | Acquisition evidence is invariant across matched scenarios |
| Economics lineage | No accepted M1.14 amount is overwritten |
| Stage boundary | No approval, price, counteroffer, funding, or optimization output is created |
| Determinism | Expected and physical hashes reconcile independently |
| Consumption contract | M1.15 plus M1.16 extension reconciles at the required grain |

Negative controls should deliberately reject:

- duplicate primary attribution;
- a campaign occurring after the application;
- an unapproved acquisition source;
- an unsupported cost basis;
- inverted funnel counts;
- an allocation exceeding campaign spend;
- double-counted M1.14 partner cost;
- a funded-CAC claim without a funded population;
- an attempted acquisition-cost improvement in only one matched scenario.

# Final roadmap decision

**Yes, this should become M1.16.**

The recommended revised roadmap is:

```text
M1.14 — Unit Economics & Risk-Adjusted Contribution
         ACCEPTED

M1.15 — Latest Output, Archive, Comparison & Consumption Contract
         Complete current build and accept

M1.16 — Acquisition Source, Marketing Attribution
         & Merchant Acquisition Cost Foundations
         New governed enhancement

M1.17 — End-to-End QA, Evidence
         & G2 Contract Acceptance

Module 2 — Offer, Pricing, Decisioning,
           Expected Booked Contribution,
           and Channel-Aware Strategy
```

This is not a correction to M1.14. It is a new, properly bounded capability discovered before the G2 gate. That is exactly when an architecture should absorb it.

The actual M1.16 DDL and contract integration should be based on the completed M1.15 repository from the parallel chat—not the older M1.14-ready archive currently attached here.
<!-- END_SOURCE_MESSAGE -->
