# MSBF - Campaign Scale 750 - 2,500 - 25,000 Part 2

Part 04 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-03.md)
[Next part](part-05.md)

<a id="m-44adea30-6a24-47aa-82eb-4d2c847bdc62"></a>
## Andrew / user · C132-M00062

C132-M00062 · 2026-09-12T14:58:38.360000-04:00 · active path

Preceding visible parent: [C132-M00061](part-03.md#m-28751cdb-005e-4341-a03f-a96f7ee4aa2c)

<!-- BEGIN_SOURCE_MESSAGE -->
# MSBF CAMPAIGN SCALE PART 2 — HYBRID CERTIFICATION & REUSABLE CAMPAIGN RUNTIME DIRECTIVE

## Workstream continuation

Continue:

```text
MSBF Campaign Scale Part 2 — 750 Certification & Fresh 2,500 Campaign Execution
```

This is the governing owner clarification for the next engineering leap.

It supplements the existing Part 2 handoff, successful Reference A/B evidence, parameterized-scale clarification, and established engineering boundaries.

Do not restart the workstream.

Do not reopen the accepted v2.1.0 publication, Power BI, visual/publication work, historical audit acceptance, or the retired R4/R5/R6 PostgreSQL restore-wrapper path.

Reference Environment R1 remains the read-only comparison baseline.

---

# 1. Ultimate product objective

Do not lose sight of the ultimate objective while solving the immediate certification problem.

The final Campaign Scale capability should provide a technically capable future user with a simple, efficient, trustworthy end-to-end way to run synthetic MSBF campaigns.

The intended eventual user experience is approximately:

```text
Clone / download repository
        ↓
one-time environment setup
        ↓
choose campaign configuration
        ↓
choose population size
        ↓
choose or accept deterministic seed/date
        ↓
run campaign
        ↓
automatic validation / controls
        ↓
review campaign results
        ↓
optional deeper evidence / Power BI analysis
```

The user should not need to understand:

```text
R1–R6 harness history
Route-B restore debugging
historical database names
development clone/resume sequencing
audit-carrier chronology
checkpoint recovery mechanics
manual PostgreSQL lifecycle troubleshooting
```

in order to run a normal campaign.

Those may remain available as engineering/audit history, but they are not the desired public execution experience.

---

# 2. Governing architectural principle

Certification is a qualification of the reusable campaign runtime, not a substitute for building it.

Do not create a one-off 750 certification mechanism that proves equivalence but cannot become the normal campaign runner.

The preferred architecture is:

```text
Reusable Campaign Runtime
        │
        ├── CS_0750_ACCEPTED_FIDELITY
        │       validation / known-answer mode
        │
        ├── CS_2500_PERFORMANCE_SHAKEDOWN
        │       fresh-population scale mode
        │
        ├── CS_25000_FULL_CAMPAIGN
        │       large validation profile
        │
        └── future parameterized population sizes
```

The 750 certification should qualify this common runtime.

The 2,500 shakedown should use the same runtime.

Do not build separate bespoke engines for 750 and 2,500.

---

# 3. Owner decision — hybrid 750 certification

The prior Fresh 750 objective became too close to proving complete greenfield platform reconstruction from an empty database.

That is not required for the immediate certification question.

The governing 750 question is:

> Does the reusable campaign runtime execute the published MSBF logic correctly, such that when it is supplied the certified accepted 750 campaign inputs and governing configuration it reproduces the accepted reference behavior with zero semantic differences across the sealed certification surfaces?

Adopt the hybrid certification approach to answer that question.

This relaxes unnecessary greenfield reconstruction requirements.

It does NOT relax MSBF business logic, output accuracy, lineage, controls, reconciliation, or comparison rigor.

---

# 4. Meaning of “fresh” for the hybrid certification

For the 750 certification gate, “fresh” means:

```text
new isolated subject execution
+
reusable campaign runtime
+
published/locked MSBF logic
+
certified accepted campaign inputs
+
accepted non-outcome platform scaffolding where necessary
+
newly generated downstream campaign outputs
```

It does NOT require:

```text
an absolutely empty PostgreSQL database
rebuilding every schema/support object from first principles
recreating every historical development database
reproducing historical clone/resume orchestration
reconstructing accepted static configuration merely for purity
proving nonsemantic PostgreSQL internals
```

Those may be separate deployment-engineering objectives.

They are not prerequisites for proving that the campaign runtime faithfully executes MSBF logic.

---

# 5. Fundamental reuse rule

Use this rule:

> Inputs and non-outcome platform scaffolding may be reused when explicitly identified and certified. Outputs being tested may not be reused as inputs to manufacture equality.

Permitted reuse may include, where justified:

```text
schemas
functions
views
static lookup/reference tables
control definitions
accepted support objects
hashing utilities
policy/configuration files
source-certification machinery
certified campaign input surfaces
certified predecessor/input surfaces at the formally selected replay boundary
```

Do not hydrate the subject with downstream outputs that the certification is intended to reproduce.

Depending on the selected replay boundary, prohibited reuse may include:

```text
R4 outputs
M2.4 outputs
M2.5–M2.12 outputs
booking/funding results
monitoring outcomes
intervention outcomes
servicing outcomes
reconciliation results
G3 results
downstream campaign hashes generated by those stages
```

The distinction is:

```text
CERTIFIED INPUT → permissible input

OUTPUT BEING TESTED → must be generated by subject runtime
```

---

# 6. Existing Reference A/B gate is closed

Do not rerun Reference A/B merely to continue this work.

Successful owner return:

```text
CS_PART2_REF_AB_20260912T160049Z_9cc1eef1_RETURN.zip

SHA-256:
e2a533794dac75b9452ebcb291d1cb8b7a580e09e5078db04e0845a773c1852f
```

It established:

```text
Reference Environment R1 binding        PASS
Native six-file Module A export          PASS
Module A input contract                  PASS
Module A retained-input parity           PASS
R4 output parity                         20 / 20 BYTE-EXACT PASS
Observed-scope nonmutation               PASS
```

Treat this as accepted baseline evidence.

Do not spend additional engineering cycles reproving it unless a new defect specifically invalidates it.

---

# 7. Select a practical replay boundary

Select and document the strongest practical accepted input boundary that supports the certification objective without unnecessarily reconstructing historical infrastructure.

At minimum bind, as applicable:

```text
population identity
campaign configuration
deterministic parameters
business/as-of date
module1_run_id / lineage
application/scenario surfaces
verification surfaces
feature/evidence surfaces
candidate/search inputs
required predecessor surfaces
policy/configuration identities
```

The replay-boundary record must identify:

```text
what is reused
why it is an input rather than an output being tested
its source authority
its hash/identity
its grain/cardinality
its lineage role
```

---

# 8. Reusable campaign runtime architecture

The next engineering delivery should move toward a durable runtime with clearly separated layers.

## Layer A — Environment/setup

Responsible for:

```text
PostgreSQL prerequisites
database connection
subject creation
required schemas/support objects
static configuration installation
environment validation
```

This should eventually be a one-time or infrequent setup step.

Do not make normal campaign execution responsible for debugging PostgreSQL installation or historical restore mechanics.

## Layer B — Campaign input generation/loading

Responsible for:

```text
population_size
campaign profile
scenario configuration
seed
business date
population generation or certified-input loading
input cardinality validation
lineage establishment
```

The same interface should support:

```text
certified 750 replay inputs
```

and later:

```text
fresh parameterized 2,500 inputs
```

without changing the downstream business engine.

## Layer C — MSBF campaign execution

Responsible for the published logic:

```text
Module 1 / qualified input processing as applicable
strategy
candidate structures
capacity/economics
recommendation
authorization
final decision
booking/funding
monitoring
intervention
servicing
reconciliation
M2.11/M2.12
G3/source certification
```

Do not fork this logic merely because one run is a certification profile.

## Layer D — Validation/evidence

Responsible for:

```text
input validation
stage controls
lineage validation
cardinality checks
financial/control reconciliation
certification comparison when enabled
manifests
checksums
logs
return package
```

Certification-specific comparisons should be an optional validation mode around the common runtime.

They should not become the runtime itself.

## Layer E — Results/learning

Responsible for:

```text
human-readable campaign summary
result exports
control results
performance/resource statistics
optional Power BI handoff
optional deep engineering evidence
```

A normal future user should not need to inspect audit-level evidence unless desired.

---

# 9. Campaign configuration should be explicit

Design toward a simple configuration contract such as:

```text
campaign_profile
population_size
seed
business_date
scenario_set
output_directory
validation_mode
```

Conceptually:

```text
campaign_profile = CS_0750_ACCEPTED_FIDELITY
population_size  = 750
validation_mode  = reference_certification
```

versus:

```text
campaign_profile = CS_2500_PERFORMANCE_SHAKEDOWN
population_size  = 2500
validation_mode  = standard_campaign
```

The actual implementation may differ, but preserve this separation of configuration from business logic.

---

# 10. Validation profiles are not product limits

Retain:

```text
CS_0750_ACCEPTED_FIDELITY
CS_2500_PERFORMANCE_SHAKEDOWN
CS_25000_FULL_CAMPAIGN
```

as validation-profile labels.

They are not the only intended valid population sizes.

Long-term:

> Campaign scale is a runtime parameter, not a software limitation.

Design toward arbitrary parameterized synthetic population sizes subject to actual resource and validation constraints.

Do not claim arbitrary-size end-to-end support until demonstrated.

---

# 11. Hybrid 750 certification mode

For the 750 validation profile, use:

```text
certified accepted inputs
        ↓
new isolated subject
        ↓
COMMON REUSABLE CAMPAIGN RUNTIME
        ↓
new downstream outputs
        ↓
certification comparator
        ↓
accepted Reference R1 surfaces
```

The certification comparator should be external to, or cleanly separated from, the business calculations.

A successful certification should demonstrate that the same runtime intended for future campaigns faithfully reproduces the known accepted result.

---

# 12. Comparison contract

Before 750 subject execution, create and seal a physical comparison contract.

Include:

```text
surface_id
stage
reference source/query
subject source/query
grain
business key or multiplicity rule
compared columns
lineage columns
expected cardinality rule
comparison method
allowed normalization
normalization rationale
stop severity
```

Cover the downstream lifecycle supported by the selected replay boundary, including as applicable:

```text
strategy/R4
capacity/economics
candidate structures
recommendation
authorization
final decisions
booking/funding
monitoring
intervention
servicing
reconciliation
financial/control aggregates
M2.11/M2.12
G3/source certification
```

Seal before execution:

```text
FULL_750_HYBRID_COMPARISON_CONTRACT.json
FULL_750_HYBRID_COMPARISON_CONTRACT.sha256
```

The certification runtime must refuse to proceed if its contract hash has changed.

Do not widen comparison rules after observing differences.

---

# 13. Runtime metadata normalization

Only predeclared nonsemantic runtime metadata may be normalized.

Examples where justified:

```text
execution timestamps
durations
database OIDs
subject database/cluster names
filesystem paths
transient logs
process identifiers
runtime-specific identifiers proven nonsemantic
```

Do not normalize business-semantic information:

```text
inputs
configuration
policy
business lineage
features
verification
economics
candidate structures
recommendations
authorization
decisions
booking/funding
monitoring
servicing
reconciliation
financial/control results
source-certification semantics
```

---

# 14. Trustworthiness requirements

The eventual campaign runtime must be trustworthy without requiring a user to manually audit every intermediate table.

Build toward automatic fail-closed controls for:

```text
configuration validity
input cardinalities
required source availability
lineage completeness
key uniqueness/multiplicity
stage completion
financial reconciliation
control reconciliation
source certification
unexpected nulls or missing surfaces
unexpected duplicate rows
invalid stage ordering
partial execution
```

A campaign should not silently produce a “successful” output when a material control failed.

The user-facing result should clearly distinguish:

```text
CAMPAIGN PASS
CAMPAIGN PASS WITH NONMATERIAL OBSERVATIONS
CAMPAIGN FAIL / STOPPED
```

with detailed evidence available underneath.

---

# 15. Efficiency requirements

Do not optimize only for evidentiary rigor while ignoring usability and runtime efficiency.

Capture:

```text
stage elapsed time
total elapsed time
row volumes
database growth
disk usage
peak/meaningful resource observations where practical
output-package size
```

Use the 750 certification and 2,500 shakedown to identify avoidable bottlenecks before 25,000.

Do not weaken business logic or controls for performance.

---

# 16. Subject isolation and storage

Reference R1 remains:

```text
127.0.0.1:55432
database = msbf_restore_test
READ-ONLY COMPARISON BASELINE
```

Do not write into it.

Campaign subjects must be separate.

Use D: for substantial runtime work.

Owner storage convention:

```text
Delivered packages:
D:\MSBF_ARCHIVE

Campaign runtime:
D:\MSBF_CAMPAIGNS
```

C: is capacity constrained.

Do not intentionally place substantial PostgreSQL data, campaign workspaces, evidence packages, outputs, or temporary campaign files on C:.

---

# 17. PostgreSQL lifecycle separation

Do not embed historical restore-debugging complexity into the reusable campaign runtime.

Preferred eventual public architecture:

```text
SETUP
    ↓
working PostgreSQL environment exists
    ↓
RUN CAMPAIGN
```

If automated environment setup is ultimately useful, provide it as a separate setup capability.

Do not force normal users through historical cluster-recovery mechanics.

---

# 18. Next engineering leap

The next delivery should make the largest controlled leap toward BOTH:

```text
hybrid 750 certification
```

and:

```text
reusable end-to-end campaign runtime
```

Prioritize:

```text
1. Select and document replay boundary.

2. Inventory reused input/platform surfaces.

3. Prove no tested downstream outputs are being hydrated.

4. Define the reusable campaign configuration/interface.

5. Build subject creation/setup around D:.

6. Adapt the published MSBF execution chain into the common runtime.

7. Integrate downstream R4 → M2.4 → M2.12 → G3 execution.

8. Build automatic stage/control validation.

9. Populate and seal the hybrid 750 comparison contract.

10. Add campaign timing/resource evidence.

11. Run extensive offline/static/negative readiness testing.

12. If readiness passes, package ONE owner-run 750 certification runtime.
```

Do not create another sequence of tiny owner diagnostics when source inspection and offline engineering can resolve the issue first.

---

# 19. Owner-run experience target

The next owner interaction should ideally be:

```text
1. Save one ZIP to D:\MSBF_ARCHIVE.

2. Paste one PowerShell block.

3. Enter PostgreSQL password if required.

4. Runtime creates an isolated subject.

5. Runtime loads/generates configured inputs.

6. Runtime executes the campaign.

7. Runtime validates controls automatically.

8. In 750 certification mode, runtime compares against Reference R1.

9. Runtime produces one RETURN.zip.

10. Owner uploads RETURN.zip.
```

The PowerShell block must begin:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'
```

Do not require the owner to manually execute individual SQL programs or manage intermediate databases unless a genuinely exceptional infrastructure failure occurs.

---

# 20. Successful 750 conclusion

The desired certification statement is:

> The reusable MSBF campaign runtime was independently executed against the certified accepted 750 campaign inputs and governing configuration and reproduced the accepted reference outputs with zero semantic differences across the sealed certification surfaces.

That establishes logical non-regression of the reusable campaign process.

It does not claim a complete greenfield platform rebuild.

---

# 21. Transition to 2,500

A successful 750 hybrid certification should qualify the **same runtime** for the next validation profile.

Then:

```text
COMMON REUSABLE CAMPAIGN RUNTIME
        +
CS_2500_PERFORMANCE_SHAKEDOWN
        +
fresh deterministic 2,500 population
        ↓
2,500 campaign
```

The 2,500 profile remains:

```text
merchants                  2,500
application_scenario_rows  5,000
verification_rows          15,000
feature_rows               5,000
base_history_rows          450,000
scenario_history_rows      900,000
```

These are input/cardinality bindings.

Candidate structures, decisions, funding, monitoring, servicing and other endogenous outcomes must emerge from the new population.

Do not scale the 750 outcomes arithmetically and call them expected results.

---

# 22. Public-user trajectory

While private engineering evidence may remain detailed, continuously ask:

> Could this eventually become a clear repository workflow that another technically capable user can understand and run without knowing the development history?

Do not prematurely rewrite public documentation during this phase.

But avoid architectural choices that would make the eventual simple public workflow unnecessarily difficult.

The long-term experience should converge toward something conceptually as simple as:

```text
setup
run --population-size 2500 --seed <seed>
review
```

with MSBF logic, controls, evidence, and trustworthy failure handling underneath.

---

# 23. Stop/escalation rule

Historical orchestration complexity alone is not a reason to stop.

First separate reusable computational logic from historical clone/resume mechanics.

Stop before changing:

```text
capacity methodology
evidence sufficiency rules
risk/economic logic
pricing or structure-search logic
counteroffer policy
recommendation/authorization boundaries
funding/booking semantics
monitoring logic
intervention logic
servicing logic
reconciliation tolerances
M2.11/M2.12 acceptance semantics
G3/source-certification semantics
sealed comparison rules after execution begins
```

Do not weaken a business or control rule merely to make the reusable runtime easier to construct.

Permitted engineering changes include, when documented and regression-tested:

```text
environment/connection configuration
subject database naming
D:-resident storage paths
campaign/run identifiers
population size
deterministic seed
business date when deliberately configured
source-path/hash rebasing
logging/evidence paths
performance instrumentation
packaging
nonsemantic adapters
deterministic serialization
runtime orchestration
safe checkpoint/restart mechanics
```

A historical implementation may be reorganized into reusable runtime components as long as the underlying accepted business semantics remain unchanged.

---

# 24. Definition of an end-to-end campaign runtime

For this workstream, “end-to-end” should describe the user experience after required one-time environment setup.

A normal campaign run should not require the user to manually assemble the campaign from individual historical stages.

The desired runtime responsibility is:

```text
validate environment
        ↓
read campaign configuration
        ↓
create / prepare isolated subject
        ↓
load or generate campaign inputs
        ↓
validate input contracts
        ↓
execute MSBF campaign stages in required order
        ↓
run automatic controls and reconciliation
        ↓
produce campaign results
        ↓
produce human-readable status
        ↓
package detailed evidence
```

A future user should not need to:

```text
manually create stage databases
manually copy tables between databases
choose historical predecessor snapshots
run individual SQL files in sequence
rename historical objects
know which old wrapper produced which stage
manually calculate campaign hashes
manually inspect hundreds of controls to determine PASS/FAIL
```

Those responsibilities belong inside the governed runtime.

“End-to-end” does NOT mean that every run must reinstall PostgreSQL or reconstruct accepted static platform components from first principles.

Separate:

```text
SETUP
```

from:

```text
CAMPAIGN EXECUTION
```

so that repeated campaign runs are fast and operationally simple.

---

# 25. Reproducibility and provenance standard

Every campaign run should automatically record enough provenance to explain exactly what was executed.

At minimum, produce a run manifest containing:

```text
runtime/version identity
published source identity
campaign profile
population size
seed
business date
scenario configuration
policy/configuration hashes
certified-input or generated-input hashes
subject database identity
stage execution statuses
stage start/end times
comparison-contract identity when applicable
result/evidence hashes
final campaign disposition
```

A user should be able to retain a campaign return and later answer:

```text
What code ran?
What configuration ran?
What population ran?
What deterministic inputs were used?
What stages completed?
What controls passed or failed?
What outputs were produced?
Can the run be reproduced?
```

without reconstructing the answer from terminal history.

For deterministic validation profiles, rerunning the same governed inputs should reproduce the same semantic campaign result.

---

# 26. Failure handling must remain simple and trustworthy

The reusable runtime must fail closed on material errors.

A partial campaign must not be labeled successful.

When a material failure occurs:

```text
stop further dependent execution
preserve completed evidence
record the first material failure
record dependent stages as NOT RUN / BLOCKED
retain enough state for diagnosis
produce a RETURN package
do not silently repair business-semantic differences
```

Where safe restart or resume capability is implemented, it must be governed and deterministic.

A user should not have to guess whether a failed run left valid results.

The runtime should provide a clear final disposition such as:

```text
CAMPAIGN_PASS

CAMPAIGN_PASS_WITH_NONMATERIAL_OBSERVATIONS

CAMPAIGN_STOPPED_CONTROL_FAILURE

CAMPAIGN_STOPPED_INFRASTRUCTURE_FAILURE
```

The distinction between infrastructure failure and business/control failure should remain explicit.

---

# 27. Hybrid 750 execution-ready acceptance criteria

Do not issue the owner-run 750 certification package merely because individual components work in isolation.

The package is execution-ready only when all of the following are physically satisfied:

```text
replay boundary documented                         PASS

reused input/platform inventory complete           PASS

tested-output hydration prohibition                PASS

reference R1 remains read-only                     PASS

separate D:-resident subject architecture           PASS

common reusable campaign runtime assembled          PASS

published business logic unchanged                  PASS

R4 → downstream execution path integrated           PASS

automatic stage/control validation implemented      PASS

comparison registry populated                       PASS

comparison contract sealed                          PASS

normalization list predeclared                      PASS

runtime provenance manifest implemented             PASS

timing/resource evidence implemented                PASS

fail-closed return packaging implemented            PASS

negative/adversarial readiness tests                PASS

no known material execution blocker                 PASS
```

If these conditions are satisfied, issue one owner-run package.

If they are not satisfied, do not issue another owner diagnostic merely to discover something that can be established through source inspection or offline testing.

---

# 28. Hybrid 750 certification acceptance rule

The 750 certification should use the common reusable campaign runtime.

Certification-specific behavior may include:

```text
loading certified accepted replay inputs
binding Reference R1
executing the sealed comparison contract
producing detailed zero-difference evidence
```

The underlying campaign calculations should remain the same calculations intended for normal future campaigns.

A successful certification requires:

```text
certified accepted replay inputs            PASS

governing configuration identity             PASS

subject isolation                            PASS

published runtime execution                  PASS

required campaign stages complete            PASS

automatic controls/reconciliation            PASS

sealed comparison surfaces evaluated         PASS

unexpected semantic differences              0

post-hoc comparison-rule changes              0

tested downstream outputs reused as inputs    0
```

The preferred successful disposition is conceptually:

```text
HYBRID_750_LOGIC_REPLAY_CERTIFIED
```

with the precise final label determined by the implementation.

The governing conclusion is:

> The reusable MSBF campaign runtime was independently executed against the certified accepted 750 campaign inputs and governing configuration and reproduced the accepted reference outputs with zero semantic differences across the sealed certification surfaces.

This is sufficient to establish logical non-regression for the reusable campaign process.

It does not assert complete greenfield platform reconstruction.

---

# 29. Same-runtime requirement for 2,500

After successful hybrid 750 certification, do not create a new 2,500 business engine.

The next run should use:

```text
same environment/setup architecture
same campaign configuration interface
same campaign orchestration
same published MSBF business logic
same validation framework
same evidence framework
same results packaging
```

with differences limited to configuration appropriate for the new campaign:

```text
campaign_profile
population_size
seed
campaign/run identity
fresh generated population
validation mode
```

Conceptually:

```text
750:
COMMON_RUNTIME
+ certified replay inputs
+ reference-certification validation

2,500:
COMMON_RUNTIME
+ fresh generated inputs
+ standard campaign validation
```

That continuity is part of what the 750 gate is intended to establish.

---

# 30. 2,500 trust standard

The 2,500 campaign is not required to reproduce 750 business-result counts.

Instead, establish that:

```text
fresh population generation completed correctly
input/cardinality contracts passed
lineage is complete
all required stages executed
business logic is the certified common runtime
internal controls passed
financial reconciliation passed
source certification passed
campaign outputs emerged endogenously
no retained expected outputs were injected
resource/performance evidence was captured
```

Data-dependent outputs must be observed rather than predicted by scaling the 750 reference.

This includes:

```text
candidate structures
recommended structures
authorized structures
final decisions
funded paths
monitoring rows
intervention rows
servicing rows
reconciliation outcomes
portfolio aggregates
```

The 2,500 shakedown should therefore test both:

```text
functional trustworthiness
```

and:

```text
operational scalability
```

of the same runtime certified at 750.

---

# 31. 25,000 readiness

Do not treat successful 750 certification alone as sufficient evidence for 25,000 readiness.

Use the 2,500 run to collect:

```text
stage timings
total elapsed time
database growth
disk usage
row volumes
large-table behavior
evidence-package growth
failure/recovery behavior
material bottlenecks
```

Then make an evidence-based 25,000 readiness decision.

A 25,000 run should use the same reusable runtime architecture, not another campaign-specific implementation.

---

# 32. Public usability is a design constraint now, not a later cleanup task

Do not postpone all usability concerns until after technical validation.

Public documentation and final polish may come later, but runtime architecture should already support a simple future interface.

When choosing between two equally trustworthy technical approaches, prefer the one that better supports:

```text
simple setup
few user decisions
explicit configuration
one-command execution
automatic validation
clear failure messages
predictable output locations
portable evidence
repeatable runs
straightforward scaling
```

Avoid unnecessary dependencies on:

```text
historical path names
hardcoded historical database names
developer-specific directories
manual stage selection
conversation-specific instructions
hidden retained state
one-off certification-only orchestration
```

The internal engineering implementation may remain sophisticated.

The public interaction should not expose that complexity unnecessarily.

---

# 33. Public runtime trajectory

The long-term repository should converge toward a small number of obvious operations.

Conceptually:

```text
msbf setup

msbf run \
  --population-size 2500 \
  --seed <seed> \
  --business-date <date>

msbf review <run-id>
```

This syntax is illustrative, not a requirement to build a particular CLI immediately.

The governing requirement is that the underlying architecture can eventually support an experience of comparable simplicity without rewriting the MSBF engine again.

Certification mode could conceptually become:

```text
msbf run \
  --profile CS_0750_ACCEPTED_FIDELITY \
  --validation reference-certification
```

while an ordinary campaign might become:

```text
msbf run \
  --population-size 63578 \
  --seed <seed>
```

once arbitrary-size execution is actually qualified.

Do not claim such arbitrary-size support before physical validation establishes it.

---

# 34. Engineering evidence versus user-facing results

Preserve comprehensive private engineering evidence.

Do not require ordinary users to consume all of it.

A future campaign run should ideally produce two evidence levels:

## User-facing summary

For example:

```text
Campaign ID
Profile
Population size
Seed
Business date
Status
Stages passed
Material observations
Key portfolio outcomes
Elapsed time
Output location
```

## Engineering/audit evidence

For example:

```text
source manifests
input hashes
stage logs
control results
lineage evidence
comparison results
SQL/query evidence
checksums
resource observations
detailed reconciliation
```

The existence of deep evidence strengthens trustworthiness.

The requirement to manually interpret deep evidence should not be part of normal usability.

---

# 35. Next delivery standard

The next engineering delivery should aim to be:

```text
MSBF HYBRID 750 CERTIFICATION
+
REUSABLE CAMPAIGN RUNTIME R1
```

not merely:

```text
another validation harness
```

The preferred deliverable should contain:

```text
reusable campaign runtime
campaign configuration/profile definitions
subject setup/preparation logic
certified-input loader
future fresh-input generation interface
published execution components
automatic stage controls
sealed 750 comparison contract
reference-certification mode
standard-campaign mode architecture
results/evidence packager
timing/resource capture
negative/adversarial tests
source/provenance register
owner run block
technical engineering report
```

The owner should ideally need to perform only:

```text
save package
run one command/block
provide password if required
upload RETURN package
```

---

# 36. Delivery outcome rule

The next engineering effort must end in one of two honest states.

## Outcome A — execution ready

```text
DELIVERY_STATUS = EXECUTION_READY

COMMON_RUNTIME_READY = true
HYBRID_750_READY = true
COMPARISON_CONTRACT_SEALED = true
OWNER_ACTION = RUN_HYBRID_750_CERTIFICATION
```

Then provide the owner-run package and one PowerShell block.

## Outcome B — engineering blocker remains

```text
DELIVERY_STATUS = BLOCKED_BEFORE_OWNER_EXECUTION
```

Then provide:

```text
all completed engineering work
exact remaining blocker
specific missing source authority or dependency
why it cannot safely be inferred
minimum evidence/change needed to close it
```

Do not ask the owner to run another diagnostic unless owner-machine execution is genuinely required to resolve that blocker.

---

# 37. Governing success hierarchy

Use this hierarchy when making engineering tradeoffs:

```text
1. Preserve designed MSBF business semantics.

2. Preserve trustworthy controls, lineage and reconciliation.

3. Produce correct and reproducible campaign results.

4. Build one reusable end-to-end campaign runtime.

5. Keep campaign execution simple for future users.

6. Make scale a configuration concern rather than a new engineering project.

7. Preserve deep evidence without forcing users to manage engineering complexity.

8. Avoid unnecessary historical or infrastructure reconstruction that does not strengthen the relevant assurance conclusion.
```

Do not trade items 1–3 for convenience.

Do not unnecessarily sacrifice items 4–7 merely to satisfy an ultra-conservative test whose incremental assurance is immaterial to the intended use.

---

# 38. Final governing principle

Do not solve the moon to prove a bottle rocket.

But also do not certify a bottle rocket that only the original engineers know how to launch.

The target is:

```text
simple enough for future users
+
rigorous enough to trust
+
faithful to designed MSBF logic
+
reproducible enough to validate
+
parameterized enough to scale
```

The hybrid 750 certification is valuable because it should prove that the **reusable runtime itself** faithfully executes the accepted MSBF logic.

The 2,500 run should then prove that the same runtime can execute a genuinely new population at larger scale.

The 25,000 profile should test larger-scale readiness of that same architecture.

The ultimate Campaign Scale deliverable should therefore converge toward:

```text
ONE REUSABLE MSBF CAMPAIGN RUNTIME
        +
PARAMETERIZED CAMPAIGN CONFIGURATION
        +
AUTOMATIC TRUSTWORTHY CONTROLS
        +
OPTIONAL CERTIFICATION / DEEP-EVIDENCE MODES
```

with a normal user experience approaching:

```text
setup
run
review
```

That is the standard the next engineering leap should optimize toward.



<!-- END_SOURCE_MESSAGE -->


<a id="m-4ccac595-0bd0-4bc3-a24f-b634dd252e63"></a>
## Assistant · C132-M00063

C132-M00063 · 2026-09-12T14:58:57.647553-04:00 · active path

Preceding visible parent: [C132-M00062](part-04.md#m-44adea30-6a24-47aa-82eb-4d2c847bdc62)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll build against this directive, checking retained sources and the replay boundary first, then integrating and testing the reusable runtime before deciding whether it is execution-ready.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e1763eb4-3ac9-42e0-94fb-09f208051f94"></a>
## Assistant · C132-M00064

C132-M00064 · 2026-09-12T15:02:03.971935-04:00 · active path

Preceding visible parent: [C132-M00063](part-04.md#m-4ccac595-0bd0-4bc3-a24f-b634dd252e63)

<!-- BEGIN_SOURCE_MESSAGE -->
The baseline evidence matches its recorded hashes. I’m tracing the R4-to-M2.4 handoff to ensure certified inputs are reused without hydrating downstream results under test.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a6c2fb10-e2c5-481c-af16-0a52961b0180"></a>
## Assistant · C132-M00065

C132-M00065 · 2026-09-12T15:11:08.308054-04:00 · active path

Preceding visible parent: [C132-M00064](part-04.md#m-e1763eb4-3ac9-42e0-94fb-09f208051f94)

<!-- BEGIN_SOURCE_MESSAGE -->
The accepted compatibility CSV can serve as the declared M2.4 input boundary, but its generation cannot be claimed as replayed logic. The runner will make that scope explicit.
<!-- END_SOURCE_MESSAGE -->


<a id="m-48362256-3b68-47d9-8f64-b109e5d810a5"></a>
## Assistant · C132-M00066

C132-M00066 · 2026-09-12T15:54:32.869798-04:00 · active path

Preceding visible parent: [C132-M00065](part-04.md#m-a6c2fb10-e2c5-481c-af16-0a52961b0180)

<!-- BEGIN_SOURCE_MESSAGE -->
## Built: Hybrid 750 Runtime Qualification R1

There is now an **executable package with the downstream runtime, sealed comparison contracts, retained source components, and runnable tests**—not another construction checkpoint.

**Download the runtime package (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912.zip`; referenced bytes not established here)** — 37,038,998 bytes.

Engineering report (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912_ENGINEERING_REPORT.md`; referenced bytes not established here) · Validation record (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912_VALIDATION.json`; referenced bytes not established here) · SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912.zip.sha256`; referenced bytes not established here) · PowerShell run block (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912_RUN_BLOCK.txt`; referenced bytes not established here)

**It is ready for a scoped first owner qualification attempt. It is not yet the completed public end-to-end campaign product.**

## The selected replay boundary

I used the directive’s permission to select a practical accepted input boundary:

```text
Certified accepted R4 analytical inputs
+
Certified M2.3 compatibility inputs
+
Accepted platform scaffolding
        ↓
NEW isolated subject database
        ↓
M2.4 booking/funding/activation
        ↓
M2.5–M2.10 / Wave A
        ↓
M2.11–M2.12 / G3-v2
        ↓
Sealed reference comparison
```

**This package does not newly execute R4 or regenerate the R4-to-M2.3 compatibility surface.** It carries the earlier successful Reference A/B evidence and explicitly treats those surfaces as inputs. Your successful A/B return remains bound by its recorded SHA-256. [export reference: filecite | turn12file2 | L105-L109]

That boundary matters because the retained M2.4 integration consumes an accepted compatibility CSV. Rather than invent its producing semantics or restart the greenfield reconstruction, this runtime certifies the CSV as an input and regenerates the downstream outputs.

A passing result would therefore establish:

> **The source-locked post-R4 downstream runtime reproduced accepted M2.4–M2.12/G3 outputs from certified post-R4/M2.3 inputs under the sealed comparison contract.**

It would **not** establish that the compatibility-producing adapter or fresh-population provider had been qualified.

## What the single invocation does

The runner binds the package, publication, reference environment, and certified inputs; creates a separate database on the existing D:-resident cluster; installs schema-only scaffolding; loads only permitted inputs; executes the downstream chain; compares outputs; checks reference/source stability; and produces one return package.

The input/output separation is explicit:

| Control | Implemented scope |
|---|---|
| Reference table inventory | All **300 ordinary tables** classified |
| Permitted input loading | **183 explicitly allowlisted relations** |
| Tested output tables | **83 tables required to be empty before replay** |
| Relational comparisons | **85 surfaces**, including the selected control/gate rows |
| Curated Wave A comparison | **9 files** |
| G3 comparison | **6 CSV files plus 10 declared identity fields** |

Seven immediate boundary surfaces are compared against retained certified files before subject creation. All imported input relations are subsequently roundtrip-compared before business execution.

The subject is created from `template0`; **the reference database is not cloned, and no checkpoint backup is restored**. The runtime does not start, stop, or restart PostgreSQL.

The detailed implementation and limitations are recorded in the engineering report (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912_ENGINEERING_REPORT.md`; referenced bytes not established here).

## What physically passed here

| Check | Result | Important limitation |
|---|---|---|
| Recovered publication byte locks | **2,884/2,884 PASS** | Current owner Git binding is checked during your run |
| Wave A source transformations | **12/12 match accepted hashes** | SQL text was transformed and checked—not executed in PostgreSQL here |
| Retained Python G3 calculation | **Exact accepted simulation/source identity** | Real computation using retained component-test inputs |
| Offline qualification suite | **108 passed; zero failures or errors** | Includes explicitly mocked process/control-flow tests |
| Clean extraction of the final ZIP | **108 tests passed again** | Package and contract identities remained unchanged |
| Archive and manifests | **PASS — 159 files, 157 manifest entries** | Artifact integrity, not native campaign acceptance |

**Native Windows/PostgreSQL execution of this package has not occurred.** Your invocation will be the first integrated native qualification attempt. The offline tests do not substitute for that result.

The tests specifically challenge prohibited output loading, reference-target protection, missing and duplicate comparison populations, exact numeric handling, failed stage handling, and postflight failures. A successful comparison cannot grant certification when postflight fails.

## What remains open for the ultimate product

This delivery implements reusable downstream orchestration, input-loading controls, validation, comparison, timing, summaries, and return packaging. It does **not** complete the generated-input side of the public workflow.

The remaining product work is the **R4-to-compatibility producing adapter, the fresh-population input provider, and population-aware qualification of retained source/validation bindings**. The current retained components still contain known-answer counts and evidence identities appropriate to this 750 boundary.

Accordingly, **the 2,500 profile is intentionally blocked**, with no fallback to retained 750 inputs. A successful downstream return will be useful qualification evidence, but it will not automatically unlock an unimplemented fresh-input provider. These gaps are recorded in the package rather than hidden behind a general “runtime ready” flag.

## Run the scoped 750 qualification

Save the ZIP here:

```text
D:\MSBF_ARCHIVE\MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912.zip
```

The existing Reference R1 server must be available at `127.0.0.1:55432`. **Do not restore or restart it merely to prepare for this command.** The runner checks the endpoint and stops if it is unavailable.

Paste this block into PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_HYBRID750_RUNTIME_QUALIFICATION_R1_20260912.zip'
$ExpectedSHA256 = '68f8db976c832b793c8625c16e4eea7fa9e393edc344c113da7ff42738a0f499'
$Python = 'C:\Python314\python.exe'
$PgBin = 'C:\Program Files\PostgreSQL\17\bin'

if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) {
    throw "Package not found: $Zip"
}

$ObservedSHA256 = (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant()
if ($ObservedSHA256 -ne $ExpectedSHA256) {
    throw 'Package SHA-256 mismatch. Nothing has been executed.'
}

if (-not (Test-Path -LiteralPath $Python -PathType Leaf)) {
    throw "Python not found: $Python"
}

foreach ($Binary in @('psql.exe', 'pg_dump.exe', 'createdb.exe')) {
    if (-not (Test-Path -LiteralPath (Join-Path $PgBin $Binary) -PathType Leaf)) {
        throw "Required PostgreSQL binary not found: $Binary"
    }
}

$Stamp = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
$ToolRoot = 'D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_' + $Stamp
$ScratchRoot = 'D:\MSBF_CAMPAIGNS\temp\HYBRID750_LAUNCH_' + $Stamp

if (Test-Path -LiteralPath $ToolRoot) {
    throw "Extraction destination already exists: $ToolRoot"
}

New-Item -ItemType Directory -Path $ScratchRoot -Force | Out-Null
$OldTemp = $env:TEMP
$OldTmp = $env:TMP
$RunExitCode = $null

try {
    $env:TEMP = $ScratchRoot
    $env:TMP = $ScratchRoot

    Expand-Archive -LiteralPath $Zip -DestinationPath $ToolRoot

    & $Python -B (Join-Path $ToolRoot 'msbf.py') run `
        --profile 'CS_0750_ACCEPTED_FIDELITY' `
        --repo 'D:\x\m' `
        --pg-bin $PgBin `
        --user 'postgres' `
        --out-root 'D:\MSBF_CAMPAIGNS\PART2_RETURNS'

    $RunExitCode = $LASTEXITCODE
}
finally {
    $env:TEMP = $OldTemp
    $env:TMP = $OldTmp
}

if ($null -ne $RunExitCode -and $RunExitCode -ne 0) {
    Write-Warning 'Stopped. Retain the emitted RETURN.zip or error. Do not restore, retry, edit the sealed contract, or advance to 2,500.'
}
```

The runtime prompts for the PostgreSQL password without recording it. Enter uses existing trust/pgpass authentication.

## Interpreting the return

The maximum successful disposition is deliberately specific:

```text
POST_R4_HYBRID750_REPLAY_CERTIFIED
```

It requires the selected downstream stages, sealed comparisons, and postflight observations to pass. It preserves:

```text
R4 execution                  PRIOR A/B EVIDENCE CARRIED
Compatibility generation      NOT QUALIFIED BY THIS RUN
Fresh-population provider     NOT QUALIFIED
Full public end-to-end product NOT COMPLETE
Fresh 2,500                   HOLD
25,000 readiness              NOT ESTABLISHED
Independent Audit acceptance  NOT GRANTED
```

The return includes actual runtime/contract snapshots, executed SQL, generated and reference-comparison outputs, controls, differences, logs, and performance observations. Large duplicate input/postflight dumps remain in the D: workspace with an explicit hash-and-omission register; they are not silently discarded.

**Run the block once and attach the emitted `HYBRID750_*_RETURN.zip` from `D:\MSBF_CAMPAIGNS\PART2_RETURNS`, including a stopped return.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-1aef471d-0e25-46f0-967f-5b50ef90455f"></a>
## Andrew / user · C132-M00067

C132-M00067 · 2026-09-12T17:16:05.444000-04:00 · active path

Preceding visible parent: [C132-M00066](part-04.md#m-48362256-3b68-47d9-8f64-b109e5d810a5)

<!-- BEGIN_SOURCE_MESSAGE -->
been stuck at this part for a bit. is there a way to confirm it's still running, using a powershell command in another powershell?
<!-- END_SOURCE_MESSAGE -->


<a id="m-ace15098-3b45-45c1-b2be-0518ed1e0f24"></a>
## Assistant · C132-M00068

C132-M00068 · 2026-09-12T17:16:08.171478-04:00 · active path

Preceding visible parent: [C132-M00067](part-04.md#m-1aef471d-0e25-46f0-967f-5b50ef90455f)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. **Do not interrupt the first PowerShell window.** Open a second PowerShell window and use read-only observations to determine whether the hybrid runtime is still active.

Start with this:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

Write-Host "`n=== PYTHON PROCESSES ==="
Get-CimInstance Win32_Process |
    Where-Object {
        $_.Name -match '^python.*\.exe$' -and
        $_.CommandLine -match 'HYBRID750|msbf\.py'
    } |
    Select-Object ProcessId, ParentProcessId, CreationDate, CommandLine |
    Format-List

Write-Host "`n=== POSTGRES ACTIVITY ==="
& 'C:\Program Files\PostgreSQL\17\bin\psql.exe' `
    -h 127.0.0.1 -p 55432 -U postgres -d postgres `
    -X -P pager=off `
    -c "SELECT pid, datname, usename, state, wait_event_type, wait_event, now()-query_start AS query_age, left(query,180) AS query FROM pg_stat_activity WHERE pid <> pg_backend_pid() ORDER BY query_start NULLS LAST;"

Write-Host "`n=== RECENT HYBRID750 FILE ACTIVITY ==="
Get-ChildItem 'D:\MSBF_CAMPAIGNS' -Recurse -File -ErrorAction SilentlyContinue |
    Where-Object {
        $_.FullName -match 'HYBRID750' -and
        $_.LastWriteTime -gt (Get-Date).AddHours(-4)
    } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 25 LastWriteTime, Length, FullName |
    Format-Table -AutoSize
```

It may ask for the PostgreSQL password. That's fine.

### What to look for

If you see a Python process whose command line contains something like:

```text
msbf.py run --profile CS_0750_ACCEPTED_FIDELITY
```

then the parent runtime is **still alive**.

The PostgreSQL section is even more useful. Look for a subject database with a name related to `HYBRID750` or the current run. Its state may be:

```text
active
```

which means PostgreSQL is executing a query, or:

```text
idle
```

which can still be perfectly normal if Python is processing files between SQL stages.

A `wait_event` also does **not** automatically indicate a hang. PostgreSQL may legitimately be waiting on client I/O, disk I/O, locks, or another operation.

The file section tells us whether evidence/log/output files have recently changed. Recent timestamps are additional evidence of forward progress.

## Even better: check whether the process is consuming CPU

If the Python process exists, run this twice about 30 seconds apart:

```powershell
Get-Process python* -ErrorAction SilentlyContinue |
    Select-Object Id, ProcessName, CPU, StartTime, WorkingSet64
```

Wait 30 seconds:

```powershell
Start-Sleep -Seconds 30

Get-Process python* -ErrorAction SilentlyContinue |
    Select-Object Id, ProcessName, CPU, StartTime, WorkingSet64
```

If the `CPU` value increases, Python is actively doing work.

For PostgreSQL:

```powershell
Get-Process postgres -ErrorAction SilentlyContinue |
    Select-Object Id, CPU, WorkingSet64, StartTime |
    Sort-Object CPU -Descending
```

Again, increasing CPU is useful evidence, although **no CPU increase does not prove a hang**—a process can be waiting legitimately.

### Don't do these yet

Do **not** use:

```text
Stop-Process
taskkill
Ctrl+C in the running window
pg_ctl stop
DROP DATABASE
restart PostgreSQL
```

The runtime was specifically designed to collect evidence and produce a return even on a controlled failure. Interrupting it could turn a diagnosable slow stage into an incomplete run.

**Paste me the output from the first three-section diagnostic block.** From the Python process, PostgreSQL activity, and recent file timestamps, I should be able to tell you whether it is progressing, legitimately waiting, or likely stuck.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cf25ed1f-741b-420d-b235-15c787675f73"></a>
## Andrew / user · C132-M00069

C132-M00069 · 2026-09-12T17:17:49.392000-04:00 · active path

Preceding visible parent: [C132-M00068](part-04.md#m-ace15098-3b45-45c1-b2be-0518ed1e0f24)

<!-- BEGIN_SOURCE_MESSAGE -->
=== PYTHON PROCESSES ===

ProcessId       : 5064
ParentProcessId : 8984
CreationDate    : 9/12/2026 3:56:04 PM
CommandLine     : "C:\Python314\python.exe" -B D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\msbf.py run --profile CS_0750_ACCEPTED_FIDELITY --repo D:\x\m --pg-bin "C:\Program Files\PostgreSQL\17\bin" --user postgres
                  --out-root D:\MSBF_CAMPAIGNS\PART2_RETURNS


=== POSTGRES ACTIVITY ===
  pid  | datname | usename  | state | wait_event_type |     wait_event      | query_age | query
-------+---------+----------+-------+-----------------+---------------------+-----------+-------
 15872 |         |          |       | Activity        | AutovacuumMain      |           |
  7592 |         | postgres |       | Activity        | LogicalLauncherMain |           |
 22268 |         |          |       | Activity        | CheckpointerMain    |           |
 18476 |         |          |       | Activity        | BgwriterMain        |           |
  6464 |         |          |       | Activity        | WalWriterMain       |           |
(5 rows)


=== RECENT HYBRID750 FILE ACTIVITY ===

LastWriteTime        Length FullName
-------------        ------ --------
9/12/2026 7:50:42 PM   1780 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\SEAL.json
9/12/2026 7:50:42 PM   1687 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\READINESS.json
9/12/2026 7:50:42 PM     76 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\contracts\SEAL.json.sha256
9/12/2026 7:50:42 PM   1780 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\contracts\SEAL.json
9/12/2026 7:50:42 PM     91 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\COMPARISON_CONTRACT.json.sha256
9/12/2026 7:50:42 PM     91 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\contracts\COMPARISON_CONTRACT.json.sha256
9/12/2026 7:50:42 PM   1687 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\contracts\READINESS.json
9/12/2026 7:50:42 PM  11101 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\ENGINEERING_REPORT.md
9/12/2026 7:50:42 PM  17880 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\MANIFEST.csv
9/12/2026 7:50:42 PM     76 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\SEAL.json.sha256
9/12/2026 7:50:42 PM  17227 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\SHA256SUMS.txt
9/12/2026 7:48:40 PM    506 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\review\OFFLINE_TEST_RESULT.json
9/12/2026 7:48:40 PM    136 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\review\STATIC_PARSE_RESULT.json
9/12/2026 7:48:38 PM  10720 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\review\OFFLINE_TESTS.stderr.log
9/12/2026 7:48:18 PM      0 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\review\OFFLINE_TESTS.stdout.log
9/12/2026 7:47:02 PM   4625 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\README.md
9/12/2026 7:47:02 PM   3239 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\docs\REPLAY_BOUNDARY.md
9/12/2026 7:47:02 PM   1670 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\REMAINING_PRODUCT_GAPS.json
9/12/2026 7:47:02 PM   1692 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\docs\FAILURE_AND_RETENTION.md
9/12/2026 7:47:02 PM   2061 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\docs\COMMON_RUNTIME_AND_INPUT_PROVIDER.md
9/12/2026 7:47:02 PM 497304 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\contracts\COMPARISON_CONTRACT.json
9/12/2026 7:47:02 PM   2006 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\EXECUTION_PLAN.json
9/12/2026 7:47:02 PM 497304 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\COMPARISON_CONTRACT.json
9/12/2026 7:47:02 PM   2006 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\contracts\EXECUTION_PLAN.json
9/12/2026 7:47:02 PM   1670 D:\MSBF_CAMPAIGNS\tools\HYBRID750_R1_20260912_155602_4ba39256\contracts\REMAINING_PRODUCT_GAPS.json
<!-- END_SOURCE_MESSAGE -->


<a id="m-b1899598-8030-42ad-9709-b670bc853a3f"></a>
## Assistant · C132-M00070

C132-M00070 · 2026-09-12T17:17:53.515552-04:00 · active path

Preceding visible parent: [C132-M00069](part-04.md#m-cf25ed1f-741b-420d-b235-15c787675f73)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Based on what you captured, **the main runtime is still alive**, but at that instant it was **not executing anything in PostgreSQL**.

Three facts matter:

- Python PID **5064** is still running and has the correct `msbf.py run --profile CS_0750_ACCEPTED_FIDELITY` command.
- PostgreSQL has **no campaign client session at the moment**—only its normal background processes.
- The runtime has written substantive evidence through the contract-sealing/readiness phase, including `SEAL.json`, `READINESS.json`, and the 497 KB comparison contract.

So this does **not** look like the PostgreSQL server hanging. The question is whether Python is actively doing file-side/offline work or is stuck waiting on a subprocess.

Run this in the second PowerShell window. It is entirely observational:

```powershell
$PidToWatch = 5064

Write-Host "`n=== MAIN PYTHON — SAMPLE 1 ==="
$p1 = Get-Process -Id $PidToWatch -ErrorAction Stop
[pscustomobject]@{
    Time       = Get-Date
    PID        = $p1.Id
    CPUSeconds = $p1.CPU
    WorkingMB  = [math]::Round($p1.WorkingSet64 / 1MB, 1)
    Threads    = $p1.Threads.Count
    Responding = $p1.Responding
} | Format-List

Write-Host "`n=== CHILD PROCESSES ==="
Get-CimInstance Win32_Process |
    Where-Object { $_.ParentProcessId -eq $PidToWatch } |
    Select-Object ProcessId, ParentProcessId, Name, CreationDate, CommandLine |
    Format-List

Write-Host "`nWaiting 30 seconds..."
Start-Sleep -Seconds 30

Write-Host "`n=== MAIN PYTHON — SAMPLE 2 ==="
$p2 = Get-Process -Id $PidToWatch -ErrorAction Stop
[pscustomobject]@{
    Time       = Get-Date
    PID        = $p2.Id
    CPUSeconds = $p2.CPU
    CPUChange  = [math]::Round($p2.CPU - $p1.CPU, 3)
    WorkingMB  = [math]::Round($p2.WorkingSet64 / 1MB, 1)
    Threads    = $p2.Threads.Count
    Responding = $p2.Responding
} | Format-List

Write-Host "`n=== CHILD PROCESSES AFTER 30 SEC ==="
Get-CimInstance Win32_Process |
    Where-Object { $_.ParentProcessId -eq $PidToWatch } |
    Select-Object ProcessId, ParentProcessId, Name, CreationDate, CommandLine |
    Format-List

Write-Host "`n=== 20 MOST RECENT RUN FILES ==="
$RunRoot = 'D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc'

Get-ChildItem $RunRoot -Recurse -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 20 LastWriteTime, Length, FullName |
    Format-Table -AutoSize
```

### How I'll interpret it

If you get:

```text
CPUChange > 0
```

especially materially above zero, the Python process is actively computing.

If Python has a **child process**, its command line is extremely useful. For example, it may show `pg_dump.exe`, `psql.exe`, another Python invocation, compression, hashing, or a test process that the parent is waiting for.

If:

```text
CPUChange = 0
no child process
no files changing
```

for repeated observations, then I would become suspicious that the runner is stuck in a wait/sleep condition rather than merely taking a long time.

One thing in your output is already encouraging: the runtime got considerably beyond initial startup. It physically created the run workspace:

```text
D:\MSBF_CAMPAIGNS\PART2_RETURNS\
HYBRID750_20260912T195609Z_2d929bcc
```

and reached the point where the **sealed contract and readiness artifacts exist**. So this is not a launch failure.

Also, **do not Ctrl+C yet**. There is enough evidence of successful progression that we should first determine what PID 5064 is doing.

Paste the output of this 30-second block. From the CPU delta, child process, and newest files, I can tell you much more precisely whether it is progressing or actually wedged.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9b005f5c-d5ff-46ed-9f89-103c66f26ce8"></a>
## Andrew / user · C132-M00071

C132-M00071 · 2026-09-12T17:19:25.484000-04:00 · active path

Preceding visible parent: [C132-M00070](part-04.md#m-b1899598-8030-42ad-9709-b670bc853a3f)

<!-- BEGIN_SOURCE_MESSAGE -->
=== MAIN PYTHON — SAMPLE 1 ===

Time       : 9/12/2026 5:18:34 PM
PID        : 5064
CPUSeconds : 777.734375
WorkingMB  : 51.6
Threads    : 1
Responding : True


=== CHILD PROCESSES ===

Waiting 30 seconds...

=== MAIN PYTHON — SAMPLE 2 ===

Time       : 9/12/2026 5:19:04 PM
PID        : 5064
CPUSeconds : 777.84375
CPUChange  : 0
WorkingMB  : 51.6
Threads    : 1
Responding : True


=== CHILD PROCESSES AFTER 30 SEC ===

=== 20 MOST RECENT RUN FILES ===

LastWriteTime        Length FullName
-------------        ------ --------
9/12/2026 7:50:42 PM     76 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\SEAL.json.sha256
9/12/2026 7:50:42 PM   1780 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\SEAL.json
9/12/2026 7:50:42 PM   1687 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\READINESS.json
9/12/2026 7:50:42 PM     91 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\COMPARISON_CONTRACT.json.sha256
9/12/2026 7:47:02 PM 497304 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\COMPARISON_CONTRACT.json
9/12/2026 7:47:02 PM   2006 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\EXECUTION_PLAN.json
9/12/2026 7:47:02 PM   1670 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\REMAINING_PRODUCT_GAPS.json
9/12/2026 7:47:00 PM   4282 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\contracts.py
9/12/2026 7:47:00 PM    621 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\OWNER_SCOPE.json
9/12/2026 7:42:16 PM  20768 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\driver.py
9/12/2026 7:42:16 PM   9677 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\backend.py
9/12/2026 7:37:32 PM  14221 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\orchestration.py
9/12/2026 7:35:44 PM   3516 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\input_binding.py
9/12/2026 7:33:10 PM   4885 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\integrity.py
9/12/2026 7:26:24 PM   5627 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\compare.py
9/12/2026 7:26:22 PM  39041 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\BOUNDARY_BINDINGS.json
9/12/2026 7:26:22 PM  15275 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\REFERENCE_AB_FINGERPRINT.sql
9/12/2026 7:23:24 PM   1790 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\msbf.py
9/12/2026 7:18:58 PM   2924 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\contracts\SCAFFOLD_QUERIES.json
9/12/2026 7:11:22 PM     73 D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc\source_snapshot\runtime\__init__.py
<!-- END_SOURCE_MESSAGE -->


<a id="m-12c2942c-9c9b-4655-be41-0fa21b0ccd12"></a>
## Assistant · C132-M00072

C132-M00072 · 2026-09-12T17:19:29.429138-04:00 · active path

Preceding visible parent: [C132-M00071](part-04.md#m-9b005f5c-d5ff-46ed-9f89-103c66f26ce8)

<!-- BEGIN_SOURCE_MESSAGE -->
That sample suggests the process is alive but likely **waiting rather than doing useful work**. One correction: my prior CPU-delta command had a PowerShell object-snapshot flaw, so the reported `CPUChange = 0` is not reliable by itself. I’ll inspect the runtime flow around the sealed-contract stage and give you a safer live check before recommending any interruption.
<!-- END_SOURCE_MESSAGE -->
