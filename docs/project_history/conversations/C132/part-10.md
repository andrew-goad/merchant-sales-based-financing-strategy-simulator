# MSBF - Campaign Scale 750 - 2,500 - 25,000 Part 2

Part 10 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-09.md)
[Next part](part-11.md)

<a id="m-10f4d1e9-33e4-4b84-8e35-cdccbaf66b8e"></a>
## Andrew / user · C132-M00209

C132-M00209 · 2026-09-13T17:08:40.015000-04:00 · active path

Preceding visible parent: [C132-M00208](part-09.md#m-39adbfea-08b8-4917-b7d4-6e316425e4e9)

<!-- BEGIN_SOURCE_MESSAGE -->
what is different versus when i ran this in dbeaver? dbeaver did not take this long. far from it. let's discuss each thing that could be different could contribute to longer run times. for one, obviously 750->2,500.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6f2286fb-5f3a-4ef9-b33a-83edda1b423c"></a>
## Assistant · C132-M00210

C132-M00210 · 2026-09-13T17:08:41.824146-04:00 · active path

Preceding visible parent: [C132-M00209](part-10.md#m-10f4d1e9-33e4-4b84-8e35-cdccbaf66b8e)

<!-- BEGIN_SOURCE_MESSAGE -->
The biggest difference is probably **not DBeaver versus Python**; it is the **execution context around PostgreSQL**. I’ll separate factors that can genuinely multiply runtime from ones that are mostly cosmetic, and rank them by likely impact.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e57b2cec-01e8-4be2-a4b8-ce6174716056"></a>
## Assistant · C132-M00211

C132-M00211 · 2026-09-13T17:09:17.540126-04:00 · active path

Preceding visible parent: [C132-M00210](part-10.md#m-6f2286fb-5f3a-4ef9-b33a-83edda1b423c)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. The **750 → 2,500 increase is only the first explanation**, and by itself it probably does **not** explain a jump from “reasonably quick in DBeaver” to individual scripts taking roughly an hour.

The important distinction is that **DBeaver versus `psql` is probably near the bottom of the list**. Both ultimately send SQL to PostgreSQL. The big differences are population scale, query design, session/planner settings, storage/cache state, and how the fresh campaign is being executed.

Here is how I would rank the possibilities.

| Factor | Likely impact | Why it matters here |
|---|---|---|
| **1. 750 → 2,500 population** | **Very high** | 3.33× merchants means M1.4 POS history grows from **135,000 → 450,000 rows**. Similar multiplication happens throughout histories and scenarios. |
| **2. Published validation recomputes expensive blueprints repeatedly** | **Very high** | The current POS31 control independently calls the expected and actual snapshot functions and FULL JOINs them. POS32 then calls both functions **again** to calculate set hashes. [export reference: filecite | turn54file0 | L22-L38] |
| **3. The original M1.4 design was not optimized for this scale** | **Very high** | Later published M1.7 explicitly says its performance design was **“learned from M1.6”** and instructs later stages to materialize expected/actual snapshots once and never rebuild wide upstream blueprints. [export reference: filecite | turn54file2 | L99-L111] |
| **4. Crossing memory/planner thresholds can make 3.33× data cost far more than 3.33× time** | **High** | Sorts, joins, hashes, aggregates, and function evaluations can change execution plans or spill once data no longer fits comfortably in memory/cache. |
| **5. Current session settings may differ from your DBeaver sessions** | **Potentially high** | `work_mem`, JIT, parallelism, planner flags, and related GUCs can materially change execution time. M1.4 validation itself does **not** set these explicitly. [export reference: filecite | turn56file0 | L12-L40] |
| **6. Storage location / I/O characteristics** | **Potentially high overall** | The current PostgreSQL cluster lives on the large D: drive. If the original `msbf_strategy` cluster you used in DBeaver was on the SSD, history generation/indexing could be much faster there. Current POS31 itself, however, is showing CPU-running rather than an I/O wait. |
| **7. Fresh database vs mature/warm database** | **Moderate** | The old development database may have had warm OS/PostgreSQL cache, mature statistics, and repeatedly accessed objects. This fresh subject begins relatively cold. |
| **8. Statistics / ANALYZE differences** | **Moderate to high** | Planner estimates affect join strategies dramatically. A freshly populated 450k-row table with different stats can get a much worse plan than the original 135k-row accepted table. |
| **9. Parallel execution differences** | **Potentially high** | One environment may permit useful parallel scans/joins while the current function/plan may effectively run largely on one backend/core. Your current observation `ACTIVE - CPU/RUNNING` is consistent with CPU computation, but does not tell us how many workers are assisting. |
| **10. Controller/evidence overhead** | **Low to moderate** | Campaign Scale adds receipts, source checks, frozen-context validation, exports, etc., but that cannot explain a single SQL statement consuming 40+ minutes. |
| **11. `psql` versus DBeaver itself** | **Low** | For the literal SQL scripts we're running, client choice should not produce an order-of-magnitude difference unless it also changes session settings or transaction behavior. |

### 1. Scale is definitely real — but the cost may be superlinear

Your original published M1.4 generation target was:

```text
750 merchants × 180 days = 135,000 rows
```

The execution guide confirms exactly that. [export reference: filecite | turn57file1 | L61-L71]

Now:

```text
2,500 × 180 = 450,000 rows
```

That's **3.333×**.

If everything were simple sequential scans, I would expect something vaguely around 3.3× runtime.

But POS31 is not simply scanning one table. It does:

```sql
expected_snapshot(...)
FULL JOIN
actual_snapshot(...)
USING(entity_key)
```

and compares their row hashes. [export reference: filecite | turn55file2 | L25-L32]

So PostgreSQL must potentially:

1. regenerate 450,000 expected rows;
2. construct/hash their entity keys and row hashes;
3. read/reconstruct 450,000 actual rows;
4. join two 450,000-row sets;
5. compare them;
6. count discrepancies.

And then POS32 immediately regenerates expected and actual again for ordered set hashing. [export reference: filecite | turn55file2 | L34-L41]

That is much more than “scan 3.33× more rows.”

---

## 2. I think we have now found an important historical design clue

This may be the biggest explanation.

M1.4 validation creates `_m1_4_blueprint` as a materialized temporary table at the beginning. [export reference: filecite | turn55file1 | L8-L18]

But POS31 does **not simply compare against that already-materialized blueprint**. It calls:

```text
m1_4_expected_pos_snapshot(...)
m1_4_actual_pos_snapshot(...)
```

again.

Then POS32 invokes those functions **again**.

So there is published validation logic that may perform repeated expensive deterministic reconstruction.

And by M1.7, your own published code explicitly says:

> performance design learned from M1.6

and then specifies:

- read accepted physical histories directly;
- materialize bounded aggregations;
- **never rebuild M1.4/M1.5/M1.6 wide blueprints**;
- **materialize expected and actual canonical snapshots exactly once**. [export reference: filecite | turn54file2 | L99-L105]

That is extremely informative.

It says the project itself had already learned, during later Module 1 development, that repeated upstream regeneration was a performance problem.

At **750**, the M1.4/M1.6 design may have been perfectly tolerable.

At **2,500**, that same mathematically valid design can become painfully expensive.

That would explain why you remember DBeaver as nowhere near this slow without implying that anything is malfunctioning now.

---

## 3. The fixed memory budget may be interacting badly with the larger population

This is another major candidate.

Later modules explicitly specify values such as:

```text
work_mem = 64MB
jit = off
```

M1.14's accepted run configuration does exactly that. [export reference: filecite | turn54file6 | L362-L378]

M1.7 also sets:

```sql
SET LOCAL work_mem='64MB';
SET LOCAL jit=off;
SET LOCAL lock_timeout='10s';
SET LOCAL statement_timeout='15min';
```

[export reference: filecite | turn54file2 | L107-L111]

But the published M1.4 validation begins simply with:

```sql
BEGIN;
```

and does **not** establish those performance settings itself. [export reference: filecite | turn56file0 | L12-L40]

Therefore M1.4 depends more heavily on server/session defaults.

That creates two possibilities:

**Your old DBeaver connection may have had different effective settings**, intentionally or because of earlier development work.

Or the **PostgreSQL 17 cluster being used now has different defaults** than the original `msbf_strategy` connection.

Relevant differences could include:

```text
work_mem
jit
max_parallel_workers_per_gather
max_parallel_workers
effective_cache_size
random_page_cost
effective_io_concurrency
maintenance_work_mem
```

I'm **not suggesting we change any of those mid-run**. That would compromise the qualification comparison.

But after this run, we should compare them.

---

## 4. There may be a plan cliff

This is why 3.33× rows can sometimes produce 10×, 20×, or more runtime.

Imagine at 135k rows PostgreSQL chooses a hash join whose working set fits comfortably in memory.

At 450k rows, one of several things can happen:

```text
135k
→ compact hash/sort
→ memory resident
→ fast
```

versus

```text
450k
→ larger hash/sort
→ different cardinality estimate
→ different plan / batching / repeated function work
→ much slower
```

Even if the data volume only increased 3.33×, the execution regime can change.

Our live query showed:

```text
ACTIVE - CPU/RUNNING
blocking_pids = {}
```

That means it is not presently sitting behind a lock.

That actually increases my suspicion of **expensive repeated computation or an inefficient plan**, rather than infrastructure failure.

---

## 5. DBeaver may have been running against a much more favorable database state

Your original M1.4 procedure explicitly used the same continuously built `msbf_strategy` database from G0/G1/M1.2/M1.3. [export reference: filecite | turn57file1 | L21-L35]

That environment had been developed interactively.

Potential advantages:

- heavily reused tables already cached;
- indexes repeatedly traversed and cached;
- statistics already established;
- potentially prior `ANALYZE`;
- database files potentially on faster storage;
- no fresh database-copy overhead;
- previous queries might have warmed both PostgreSQL shared buffers and Windows file cache.

Current Campaign Scale creates a **new isolated subject** specifically so we know we're testing fresh execution.

That's much cleaner validation.

It can also be slower.

---

## 6. D: HDD versus SSD could matter considerably — but not for everything we're seeing

This is one item I want to verify after the run rather than assume.

We deliberately moved large Campaign Scale storage to D: because C: was capacity constrained.

If your historical PostgreSQL `msbf_strategy` database lived on the C: SSD, then:

```text
old:
SSD + 135k rows

current:
HDD + 450k rows
```

is a substantial hardware change.

For generation, indexes, temporary files, large sorts and sequential reads, that can matter enormously.

**However**, your live POS31 query had:

```text
wait_event_type = NULL
diagnosis = ACTIVE - CPU/RUNNING
```

so at the instant we observed it PostgreSQL was not reporting a disk I/O wait.

Thus HDD is probably **not the primary explanation for POS31's current 40+ minute stretch**.

It may still have contributed heavily to source 028's generation time.

---

## 7. We are doing exactly the same validation, but against much more data

This is worth emphasizing.

Campaign Scale did not add POS31.

The published M1.4 code defines POS31 as:

```text
M1_4_POS_31_ROW_REPRODUCTION
Row-level deterministic reproduction
```

and explicitly regenerates expected and actual snapshots. [export reference: filecite | turn54file0 | L22-L29]

At 750, that meant comparing:

```text
135,000 expected
vs.
135,000 actual
```

Now:

```text
450,000 expected
vs.
450,000 actual
```

But because expected generation itself builds deterministic daily-history logic, this isn't merely a 900k-row equality test.

The computation inside those functions matters.

---

## 8. The current controller is not causing the SQL to take an hour

This distinction is important.

Campaign Scale adds:

- source binding checks;
- checkpoint checks;
- process receipts;
- timing;
- evidence capture;
- postflight;
- return packaging.

Those create some overhead.

But when `pg_stat_activity` tells us **one PostgreSQL statement itself has been active for 41 minutes**, Python and the controller aren't the reason for those 41 minutes.

PostgreSQL is inside the published SQL logic.

So the performance problem we are observing is primarily **inside the database workload**, not the Campaign Scale orchestration layer.

---

## 9. DBeaver versus psql is probably almost irrelevant

This is the tempting explanation, but I put it near last.

The project's own documentation explicitly supports either:

```text
DBeaver or psql
```

for PostgreSQL execution. [export reference: filecite | turn57file1 | L27-L35]

Once the SQL reaches PostgreSQL, DBeaver isn't executing your joins; PostgreSQL is.

There can be differences from:

- session configuration;
- JDBC prepared-statement behavior;
- transaction/autocommit handling;
- fetch behavior for huge result sets.

But this validation script uses literal SQL and performs its costly work inside PostgreSQL.

So I would **not** conclude:

> psql is slower than DBeaver.

Rather:

> the current PostgreSQL execution context is materially different from the original 750 environment.

---

# What I presently think is happening

My working attribution would be approximately:

**Primary causes**

1. **3.33× population/history size**
2. **published M1.4 validation repeatedly rebuilds deterministic snapshots**
3. **that design crosses a performance threshold at 2,500**

**Potential amplifiers**

4. different memory/planner/parallel settings
5. fresh statistics/cache state
6. D:-resident database versus possibly faster historical storage

**Minor**

7. Campaign Scale evidence/controller overhead

**Probably negligible**

8. psql versus DBeaver itself

And the later code gives us strong corroboration that the project had already recognized this general class of issue: M1.7 explicitly changed the architecture to **materialize once and avoid rebuilding wide upstream blueprints**. [export reference: filecite | turn54file2 | L99-L105]

## This is actually valuable Campaign Scale evidence

I would not alter anything during this run.

But afterward, we should do a focused **performance attribution** using actual plans/timings and determine whether a future publication can preserve:

**logic → controls → validation → evidence → interpretation**

while eliminating redundant recomputation.

For example, if POS31 and POS32 can both consume **one governed, materialized expected snapshot and one governed actual snapshot**, rather than regenerating each independently, that may preserve the exact same control objectives and evidence while reducing runtime dramatically.

That would be precisely the kind of later publication improvement you described: **not deleting controls, but removing duplicated computation underneath them.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-57222344-9bad-4a8a-9281-e6ef9446aebf"></a>
## Andrew / user · C132-M00212

C132-M00212 · 2026-09-13T17:10:33.240000-04:00 · active path

Preceding visible parent: [C132-M00211](part-10.md#m-e57b2cec-01e8-4be2-a4b8-ce6174716056)

<!-- BEGIN_SOURCE_MESSAGE -->
the individual scripts in dbeaver (which is how i ran the initial 750 cohort) were quite fast actually.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3ec6cf4e-4c31-4139-82f4-9ed4cde52fd5"></a>
## Assistant · C132-M00213

C132-M00213 · 2026-09-13T17:10:35.117719-04:00 · active path

Preceding visible parent: [C132-M00212](part-10.md#m-57222344-9bad-4a8a-9281-e6ef9446aebf)

<!-- BEGIN_SOURCE_MESSAGE -->
That materially changes the diagnosis. If the original 750 scripts were typically **seconds to a few minutes**, then a 3.33× population increase should not plausibly turn the same M1.4 generation/validation scripts into **60–70 minute** executions by itself. I’m checking the retained execution history for any old timings/environment differences so we can separate scale from a genuine performance regression.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d08c1dbc-6eb9-434d-a794-ef2a087b3e21"></a>
## Assistant · C132-M00214

C132-M00214 · 2026-09-13T17:10:50.547259-04:00 · active path

Preceding visible parent: [C132-M00213](part-10.md#m-3ec6cf4e-4c31-4139-82f4-9ed4cde52fd5)

<!-- BEGIN_SOURCE_MESSAGE -->
That makes me more suspicious of **algorithmic scaling**, not just hardware or client differences. If the 750 scripts were genuinely fast, then the current ~60–70 minute M1.4 scripts imply something closer to a **superlinear path**—for example, a per-merchant/per-day calculation repeatedly rescanning the merchant population or parameter tables. I’m checking the published M1.4 generator for that pattern.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2c931351-b059-420b-a8d0-f705c08aefef"></a>
## Assistant · C132-M00215

C132-M00215 · 2026-09-13T17:11:11.083521-04:00 · active path

Preceding visible parent: [C132-M00214](part-10.md#m-d08c1dbc-6eb9-434d-a794-ef2a087b3e21)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — that changes my assessment substantially.

If the original 750 scripts were **quite fast individually**, then I would no longer treat what we are seeing as an expected consequence of 750 → 2,500. A 3.33× population increase should not ordinarily turn fast scripts into **60–70 minute scripts**. We are seeing a real **scaling/performance cliff** somewhere.

And we can narrow it more than before.

The original M1.4 generator creates 135,000 daily rows at 750 merchants; the current run creates 450,000. That is only **3.33× the row count**. The original project also already ran successfully on PostgreSQL 17.9, so PostgreSQL-version difference is not a good explanation. [export reference: filecite | turn57file1 | L21-L35]

### What I now think is most likely

**1. The published M1.4 SQL contains operations whose computational cost scales much worse than the output row count.**

The blueprint builds the merchant × date grid, calculates multiple deterministic random/hash-derived values per merchant-day, and then performs a self-join of the calculated daily history to itself to obtain delayed settlement amounts:

```sql
FROM eligible curr
LEFT JOIN eligible prior
  ON prior.merchant_id = curr.merchant_id
 AND prior.processor_account_id = curr.processor_account_id
 AND prior.observation_date =
       (curr.observation_date-curr.settlement_delay_days)::date
```

[export reference: filecite | turn61file0 | L208-L220]

That is not necessarily bad SQL at 135k rows. But if PostgreSQL chooses an unfavorable plan at 450k rows—especially a nested-loop-like plan rather than an efficient hash/merge strategy—the runtime can jump far more than 3.33×.

A useful rule of thumb:

```text
Linear scaling:
750 → 2,500 ≈ 3.33× runtime

N log N:
≈ 3.5–4× runtime

Quadratic-ish / repeated nested work:
(2500 / 750)^2 ≈ 11.1× runtime
```

So if Program 25 took, say, **5–6 minutes originally**, an ~11× path lands remarkably close to the **~69 minutes** we just observed.

That is now one of my leading hypotheses.

---

**2. POS31 may be getting a very bad execution plan.**

The current validation doesn't merely inspect the materialized `_m1_4_blueprint`.

It executes:

```sql
m1_4_expected_pos_snapshot(...)
FULL JOIN
m1_4_actual_pos_snapshot(...)
```

[export reference: filecite | turn54file0 | L22-L29]

The expected snapshot calls the entire `m1_4_daily_pos_blueprint()` again. [export reference: filecite | turn59file0 | L28-L44]

So PostgreSQL is rebuilding that whole 450k-row deterministic history—including the settlement self-join—and simultaneously comparing it against physical history.

Then POS32 invokes both expected and actual snapshot functions **again** to calculate the portfolio hash. [export reference: filecite | turn54file0 | L31-L38]

At 750 this apparently wasn't painful. At 2,500 it plainly is.

---

**3. We may have crossed a PostgreSQL planner/memory threshold.**

This is different from simply having more records.

At 135k rows PostgreSQL might choose:

```text
hash join
everything fits comfortably
minimal batching/spilling
```

At 450k it might choose:

```text
different join strategy
larger sort/hash
more batches
or even a poor nested-loop plan
```

The current live query being:

```text
ACTIVE - CPU/RUNNING
blocking_pids = {}
```

is entirely compatible with an **inefficient CPU-heavy execution plan**. It is not waiting on another process.

This is probably one of the first things I would investigate after we preserve this run.

---

**4. The original database may have had materially better statistics than this fresh campaign database.**

This is now higher on my list.

Your original DBeaver work occurred against a continuously developed `msbf_strategy` database. The fresh campaign is working in a newly copied/generated subject.

PostgreSQL's planner depends heavily on statistics. If the original database had better `ANALYZE` state and the fresh 450k-row tables do not yet have equally representative statistics, PostgreSQL can seriously misestimate join cardinalities.

That can turn:

```text
correct hash/merge plan
```

into:

```text
awful nested-loop plan
```

without changing one line of business logic.

That would produce exactly the kind of disproportionate degradation we're seeing.

---

**5. Session/resource settings may differ from the original execution.**

M1.4's positive-validation script does not establish its own `work_mem`, JIT or similar performance settings; it begins directly with `BEGIN`. [export reference: filecite | turn56file0 | L12-L40]

Later Module 1 code explicitly learned to do things differently. M1.7 says its performance design was **“learned from M1.6”** and specifically says:

- use bounded materialized aggregations;
- do not rebuild prior wide blueprints;
- **materialize expected and actual canonical snapshots exactly once**;
- disable JIT and bound the execution settings. [export reference: filecite | turn54file2 | L99-L111]

That is a very strong historical clue that performance problems had already been encountered during original development.

Your DBeaver connection may also have inherited different server/session settings than this `psql` connection. The client itself is not the important part; the effective PostgreSQL settings are.

---

**6. Storage could still amplify it, but I no longer think it explains the result by itself.**

The current isolated PostgreSQL cluster lives on D:.

If original `msbf_strategy` lived on faster SSD storage, that could hurt:

- generation;
- temp writes;
- indexes;
- sorts;
- hashes;
- checkpoint copies.

But POS31 was observed as **CPU-running**, not waiting on PostgreSQL I/O. So even if disk contributes, there is clearly more going on.

---

### What I now think is *not* the explanation

I would put these quite low:

**`psql` versus DBeaver.** PostgreSQL executes the SQL either way. The project documentation itself permits both DBeaver and `psql`. [export reference: filecite | turn57file1 | L27-L35]

**Campaign Scale's Python orchestration.** It adds receipts and checks, but the live backend showed one PostgreSQL statement itself consuming 41+ minutes. Python cannot account for that.

**Simply having 3.33× more rows.** That contributes, unquestionably, but given your recollection of the original execution speed, it isn't remotely enough by itself.

## The emerging diagnosis

I would phrase it now as:

> **Campaign Scale has exposed a latent scale-sensitive performance characteristic in the published Module 1 SQL that was not visible at the original 750 cohort.**

That doesn't mean the published logic is wrong.

In fact, this is exactly what a 2,500 shakedown is supposed to discover.

And importantly, it may be possible to improve performance **without sacrificing your control architecture at all**.

For example:

```text
Current M1.4 validation

materialize blueprint once
      ↓
controls 1–30
      ↓
POS31 regenerates entire expected blueprint
      ↓
POS32 regenerates entire expected blueprint again
      ↓
additional controls
```

could potentially become, in a later governed publication:

```text
materialize expected canonical snapshot once
materialize actual canonical snapshot once
      ↓
POS31 compares those
      ↓
POS32 hashes those same independently derived snapshots
      ↓
all control conclusions preserved
```

That is not deleting a control. It is eliminating redundant computation underneath independent control assertions.

### One thing I would *not* do now

I would **not change anything in this running qualification**.

This run is giving us extremely valuable baseline performance evidence.

Once it completes—or if a published statement timeout legitimately stops it—I think the next technical task should be a **focused execution-plan/performance attribution**, not guesswork:

```text
Program 25 generation
Program 26 POS31
Program 26 POS32

750 accepted structure
vs.
2,500 fresh structure

EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
effective server/session settings
table statistics
temp spill
parallelism
join algorithms
function call/recomputation counts
```

Then we'll know whether the real culprit is **quadratic scaling, planner misestimation, repeated blueprint reconstruction, memory spill, storage, or some combination**.

Given what you've now told me about the original DBeaver execution, I expect we'll find a concrete and fixable performance issue rather than conclude “2,500 just takes this long.”
<!-- END_SOURCE_MESSAGE -->


<a id="m-e3f84ac9-3e29-4b34-9738-4d8a68327283"></a>
## Andrew / user · C132-M00216

C132-M00216 · 2026-09-13T17:13:56.761000-04:00 · active path

Preceding visible parent: [C132-M00215](part-10.md#m-2c931351-b059-420b-a8d0-f705c08aefef)

<!-- BEGIN_SOURCE_MESSAGE -->
is it a D drive (HDD) vs C drive (SSD)? how is the current process running?
<!-- END_SOURCE_MESSAGE -->


<a id="m-9da63df0-d8db-4c67-a6dc-39fa1ed3e998"></a>
## Assistant · C132-M00217

C132-M00217 · 2026-09-13T17:14:00.503931-04:00 · active path

Preceding visible parent: [C132-M00216](part-10.md#m-e3f84ac9-3e29-4b34-9738-4d8a68327283)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — the **database itself is currently running from the D: drive**, while the executables are on C:.

The layout is essentially:

```text
C: SSD
├─ C:\Python314\python.exe
└─ C:\Program Files\PostgreSQL\17\bin\
   ├─ postgres.exe
   ├─ psql.exe
   └─ pg_ctl.exe

D: HDD
└─ D:\MSBF_CAMPAIGNS\
   ├─ pg_clusters\msbf_cs_ref750_routeb_20260912_012713\
   │   └─ actual PostgreSQL database files
   ├─ PART2_RETURNS\
   ├─ temp\
   └─ tools\
```

So PostgreSQL **code executes from the C: SSD**, but when it reads/writes database tables, indexes, WAL, temp spill files, etc., the persistent database storage is on the **D: HDD**.

### Is that causing the current slowness?

For the **specific query we checked**, probably **not primarily**.

Your live PostgreSQL status was:

```text
state           = active
wait_event_type = NULL
blocking_pids   = {}
diagnosis       = ACTIVE - CPU/RUNNING
```

That means PostgreSQL was actively executing CPU work, rather than sitting in an operating-system disk wait.

The current statement was the expensive:

```text
M1_4_POS_31_ROW_REPRODUCTION
```

which regenerates the expected 450,000-row deterministic history and compares it with the actual history.

So at that moment the machine was effectively doing:

```text
Python controller
       ↓
psql client
       ↓
PostgreSQL backend
       ↓
CPU-heavy SQL computation
       ↓
regenerate/hash/join 450k expected
against 450k actual
```

The Python controller itself is basically waiting for PostgreSQL to finish. It is **not** doing the heavy calculation.

### Where the HDD probably does matter

The HDD can materially slow portions such as:

- initial 450,000-row history generation;
- writing the history table;
- creating indexes;
- large sorts/hash operations that spill to disk;
- PostgreSQL temporary files;
- checkpoint/database copying;
- later 900,000-row scenario-history stages;
- large exports.

So it could explain **part** of why Program 25 (`source_028`) took ~69 minutes.

But it does **not adequately explain** the 40+ minute POS31 computation we observed because that backend was reporting CPU-running, not I/O-waiting.

### There is another important hardware detail

Even though the SQL is CPU-bound, PostgreSQL is probably executing much of this particular operation on **one backend/core**.

`state = active` tells us the backend is working, but our status query did not show parallel workers. If the deterministic functions / SQL structure prevent useful parallelism, then you could have:

```text
modern multicore CPU
      ↓
one PostgreSQL backend doing most of the work
      ↓
one core heavily used
while much of the CPU sits available
```

That could produce exactly the behavior you're seeing.

So my current ranking is:

1. **Repeated deterministic blueprint computation / query-plan scaling** — likely largest issue.
2. **Potential lack of parallel execution** — potentially very significant.
3. **Planner/statistics/memory differences at 450k rows** — potentially significant.
4. **D: HDD instead of SSD** — definitely a contributing factor for data-intensive stages.
5. **psql vs DBeaver** — likely negligible.

And importantly, **the run currently appears to be actually working, not stalled**. It completed `source_028`, advanced into `source_029`, and the PostgreSQL backend we inspected was actively executing without blocking.

After this run, I would specifically compare the old `msbf_strategy` storage location and PostgreSQL settings against this D:-resident cluster. If the original database was on C: SSD, that gives us a clean hardware variable to quantify—but I don't think moving to SSD alone would explain or cure the extreme POS31 runtime.
<!-- END_SOURCE_MESSAGE -->


<a id="m-810ef960-f78a-4eff-bda2-50a9b1cc8a04"></a>
## Andrew / user · C132-M00218

C132-M00218 · 2026-09-13T17:15:57.554000-04:00 · active path

Preceding visible parent: [C132-M00217](part-10.md#m-9da63df0-d8db-4c67-a6dc-39fa1ed3e998)

<!-- BEGIN_SOURCE_MESSAGE -->
but the deterministic controls were also in dbeaver run, so i'm not sure why that would be any different - please explain that one to me again.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c5e32ddb-1f68-4042-8ebc-8a83a1fff519"></a>
## Assistant · C132-M00219

C132-M00219 · 2026-09-13T17:15:59.106574-04:00 · active path

Preceding visible parent: [C132-M00218](part-10.md#m-810ef960-f78a-4eff-bda2-50a9b1cc8a04)

<!-- BEGIN_SOURCE_MESSAGE -->
You’re right to push on that. The deterministic controls themselves are **not different**. The important point is that **the same control can cost radically more when run against a larger dataset or under a different PostgreSQL execution plan**.

For M1.4, the published DBeaver run and the current campaign run both execute the same control logic. For example, POS31 still does this:

```sql
expected_snapshot(...)
FULL JOIN
actual_snapshot(...)
```

and checks for row-hash mismatches. That control existed in the original published code. [export reference: filecite | turn54file0 | L22-L29]

What changed is the amount and shape of work underneath it.

At 750 merchants, M1.4 had:

```text
750 × 180 days = 135,000 daily rows
```

The published execution guide confirms that original grain. [export reference: filecite | turn57file1 | L61-L71]

Now it has:

```text
2,500 × 180 days = 450,000 daily rows
```

So when POS31 calls `m1_4_expected_pos_snapshot()`, PostgreSQL is not merely reading a stored 450k-row file. That function calls `m1_4_daily_pos_blueprint()` again, which regenerates the entire deterministic daily-history calculation. [export reference: filecite | turn59file0 | L28-L44]

That blueprint includes:

- merchant/profile joins;
- merchant × date expansion;
- many deterministic hash/random-derived calculations per merchant-day;
- sales/seasonality/volatility computations;
- a self-join of daily history to itself for settlement timing. [export reference: filecite | turn61file0 | L83-L124] [export reference: filecite | turn61file0 | L180-L220]

So the **control is identical**, but the function it invokes now has to regenerate a much larger analytical structure.

The second issue is execution planning. PostgreSQL does not guarantee that 3.33× more rows means 3.33× more runtime. The same SQL can get a different join plan, different sort/hash behavior, different batching, or different parallelism once the dataset crosses a threshold. That is the part I mean by a “performance cliff.”

A simple example:

```text
750 cohort:
135k rows
→ hash join fits comfortably
→ fast
```

versus:

```text
2,500 cohort:
450k rows
→ larger intermediate sets
→ planner chooses a less favorable path
→ repeated deterministic reconstruction becomes very expensive
```

Nothing about the **control objective** changed.

There is also repeated work inside the original published validation. The script materializes `_m1_4_blueprint` once at the start, but POS31 later invokes the expected-snapshot function again instead of simply reusing that materialized result. [export reference: filecite | turn56file0 | L34-L40] Then POS32 invokes expected and actual snapshots again for the set-hash test. [export reference: filecite | turn55file2 | L25-L41]

That repeated computation existed in DBeaver too. It just may have been cheap enough at 750 that you barely noticed it.

So the distinction is:

```text
Same published control
Same published logic
Same validation objective

BUT

3.33× more rows
+ much larger intermediate work
+ possible planner/memory/parallelism threshold changes
+ repeated blueprint regeneration
= potentially far more than 3.33× runtime
```

And your recollection that DBeaver was **very fast** is exactly why I do **not** think “the controls are expensive by nature” is a sufficient explanation. I think Campaign Scale has exposed a scale-sensitive execution problem in how some of those controls are physically computed.

That is why, after this run, I’d want to compare the actual execution plans of POS31/POS32 at 750 versus 2,500. That will tell us whether the culprit is a join-plan change, loss of parallelism, memory spill, repeated function execution, or some combination—not a difference in the controls themselves.
<!-- END_SOURCE_MESSAGE -->


<a id="m-db989f3f-628b-4f7b-a5d7-9da710642f07"></a>
## Andrew / user · C132-M00220

C132-M00220 · 2026-09-13T17:17:19.036000-04:00 · active path

Preceding visible parent: [C132-M00219](part-10.md#m-c5e32ddb-1f68-4042-8ebc-8a83a1fff519)

<!-- BEGIN_SOURCE_MESSAGE -->
it's hard to believe that a ~3.5x times larger dataset (450k rows) would take hours when initial codes took seconds/minutes. that is just hard to comprehend.
<!-- END_SOURCE_MESSAGE -->


<a id="m-feac18f5-b3ce-42f0-a22b-92471e9fe71e"></a>
## Assistant · C132-M00221

C132-M00221 · 2026-09-13T17:17:21.110043-04:00 · active path

Preceding visible parent: [C132-M00220](part-10.md#m-db989f3f-628b-4f7b-a5d7-9da710642f07)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree with your skepticism. **A ~3.3–3.5× increase in row count, by itself, does not plausibly explain going from seconds/minutes to roughly an hour per script.** Something else is amplifying the cost.

If the original 750 execution was, say, 1–3 minutes and the same logical stage is now taking 60–70 minutes, we're looking at an order-of-magnitude performance change—not normal linear scaling.

The important distinction is:

```text
750 → 2,500 merchants
135k → 450k M1.4 rows
≈ 3.33× data
```

A reasonably scalable implementation should therefore land somewhere in the neighborhood of a few times slower, perhaps somewhat worse because of larger sorts/hashes. It should not naturally become **30×, 50×, or 100× slower**.

So I think Campaign Scale has exposed a **performance cliff**.

The most plausible causes are these, in roughly this order:

1. **PostgreSQL chose a fundamentally worse execution plan at 450k rows.** The same SQL can be very fast at 135k rows and catastrophically slow at 450k if the planner switches join strategy, underestimates cardinality, or performs repeated nested work. This is probably the first thing I want to prove or rule out.

2. **Repeated blueprint reconstruction is interacting badly with the larger plan.** POS31 regenerates the expected deterministic history and joins it to the actual history. POS32 then regenerates those snapshots again for hashing. That happened at 750 too, but if each reconstruction has crossed a planning threshold, the repetition magnifies the problem. [export reference: filecite | turn55file2 | L25-L41]

3. **Statistics may be poor in the fresh subject.** Your original `msbf_strategy` database had been built and exercised interactively. The new campaign subject is fresh. If PostgreSQL's statistics are inaccurate or incomplete after inserting 450k rows, the validation query can choose a terrible plan even though the SQL is identical.

4. **Parallelism may not be happening.** We saw one active PostgreSQL backend doing CPU work. If these SQL functions are effectively serial, one core may be grinding through expensive deterministic calculations while most of the machine remains underused.

5. **The D: HDD may amplify some stages.** It could substantially hurt generation, sorts, temp spill, indexing, and checkpoint operations if your original database was on the C: SSD. But the POS31 snapshot we inspected was `ACTIVE - CPU/RUNNING`, not waiting on I/O, so HDD alone cannot explain that particular 40+ minute query.

6. **Different PostgreSQL/session settings could contribute.** M1.4 validation does not explicitly set things such as `work_mem`, JIT, or parallel settings. Later Module 1 stages explicitly introduced performance-oriented settings and materialization patterns, which is evidence the project itself encountered this kind of issue during development. [export reference: filecite | turn54file2 | L99-L111]

What I **do not** believe anymore is:

> “Well, it's 3.5× larger, so an hour is reasonable.”

No. Given your original experience, that explanation is inadequate.

A simplified illustration:

```text
Healthy scaling

750:
135k rows → 2 min

2,500:
450k rows → perhaps 6–10 min
```

What we're seeing is more like:

```text
750:
fast

2,500:
60+ min
```

That signals a different execution regime, not simply more rows.

And we have a particularly interesting clue in the published M1.4 code. The deterministic blueprint itself contains a self-join of calculated daily history for settlement timing. [export reference: filecite | turn61file0 | L208-L220] If PostgreSQL handles that efficiently, fine. If the planner starts executing that portion inefficiently at the larger cardinality, the cost can explode.

So after this qualification run, I think we should **stop speculating and measure it directly**. A focused `EXPLAIN (ANALYZE, BUFFERS, SETTINGS)` on the expensive M1.4 paths can tell us:

```text
Was it a nested-loop explosion?
Did a hash/sort spill?
Were row estimates badly wrong?
Was parallelism absent?
How many times was the blueprint evaluated?
How much was CPU versus disk?
Were temp files written?
What indexes were actually used?
```

That should give us a concrete explanation.

And importantly, the likely solution does **not** have to compromise your controls. We may discover that the exact same control conclusions can be obtained with better physical execution—better statistics, better indexing, materializing a governed snapshot once, or eliminating redundant recomputation—while retaining the full logic/control/validation/evidence chain.

So your instinct is right: **450k rows is not “big data” in PostgreSQL terms. Hours at this scale strongly suggests an inefficient execution path that deserves investigation.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-f021726d-b592-46cf-84ad-87991f9c8b92"></a>
## Andrew / user · C132-M00222

C132-M00222 · 2026-09-13T17:20:54.776000-04:00 · active path

Preceding visible parent: [C132-M00221](part-10.md#m-feac18f5-b3ce-42f0-a22b-92471e9fe71e)

<!-- BEGIN_SOURCE_MESSAGE -->
i think we have to ask how does dbeaver run it? does dbeaver force parallelism? what are you doing different than dbeaver? it cannot be 750 vs 2.5k. i do not believe that at all. and we could prove it. let's run a fresh 750 test run. using the process. instead of building new data now. just trim the current run to only process a third of the data and let's see if it is taking hours still. i guarantee it will also be slow and I guarantee there is something in the campaign scale that is materially inefficient vs dbeaver process and we need to uncover it.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d1bbd760-bb46-4676-b776-09cb252f5246"></a>
## Assistant · C132-M00223

C132-M00223 · 2026-09-13T17:20:56.610709-04:00 · active path

Preceding visible parent: [C132-M00222](part-10.md#m-f021726d-b592-46cf-84ad-87991f9c8b92)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree with the experiment, with one important control: **do not trim or mutate the currently running 2,500 subject.** We should create a separate, disposable 750 benchmark subject so the comparison isolates population size while holding the runtime, PostgreSQL cluster, D: storage, and controller constant.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e107e7ac-f7b6-4033-8fe0-ba316db00614"></a>
## Assistant · C132-M00224

C132-M00224 · 2026-09-13T17:21:11.969594-04:00 · active path

Preceding visible parent: [C132-M00223](part-10.md#m-d1bbd760-bb46-4676-b776-09cb252f5246)

<!-- BEGIN_SOURCE_MESSAGE -->
I agree with the experiment, and we can make it cleaner than “trim the current run.” **DBeaver does not force PostgreSQL parallelism**, and the current POS31 statement is an `INSERT … SELECT`; PostgreSQL does not generate a parallel plan for a query that writes data, regardless of whether DBeaver or `psql` submitted it. 

So parallelism is unlikely to explain the DBeaver-vs-current gap for the exact control we are watching.
<!-- END_SOURCE_MESSAGE -->


<a id="m-fe677a03-4463-4ad9-8bb6-e17a435a33db"></a>
## Assistant · C132-M00225

C132-M00225 · 2026-09-13T17:21:11.969594-04:00 · active path

Preceding visible parent: [C132-M00224](part-10.md#m-e107e7ac-f7b6-4033-8fe0-ba316db00614)

<!-- BEGIN_SOURCE_MESSAGE -->
I think your proposed experiment is the right way to settle this.

And one point is now clear: **DBeaver does not normally “force parallelism.”** Its standard **Execute SQL Script** mode parses the script and executes statements consecutively through the PostgreSQL driver. It has a separate special mode for executing statements concurrently, but that is not ordinary script execution. [export reference: cite | turn641848search1 | turn641848search26]

More importantly, the exact POS31 statement we're watching is an `INSERT … SELECT`. PostgreSQL says a query that writes data does **not** get a parallel query plan, with limited exceptions such as `CREATE TABLE AS`. So DBeaver could not have magically parallelized POS31 while `psql` runs it serially. [export reference: cite | turn641848search0 | turn641848search24]

So I agree: we need an empirical 750 control.

### The clean experiment

I would **not trim or mutate the currently running 2,500 subject**. That would compromise the qualification and create a hybrid dataset.

Instead, after the current R4 run finishes—or if it stops naturally—we should use the already-existing **750 Reference R1 database on this exact same PostgreSQL 17.9 D:-resident cluster**:

```text
msbf_restore_test
```

and execute the exact expensive M1.4 validation computation there.

That gives us an unusually clean experiment:

```text
750 benchmark
-------------------------
same computer
same PostgreSQL 17.9
same D: HDD cluster
same postgres.exe
same psql client
same published M1.4 functions
same 180-day history
same POS31 control logic

only major difference:
750 merchants / 135k rows
vs.
2,500 merchants / 450k rows
```

We do **not** need to regenerate another 750 population to answer the performance question.

And we can run the benchmark inside a transaction using only temporary objects and `ROLLBACK`, so Reference R1 remains unchanged.

### The result will be decisive

There are three outcomes.

**A. 750 takes seconds/minutes under `psql` on the current D: cluster.**

Then you are right that the runtime environment is fundamentally capable of running this code quickly, and we've proven a **750 → 2,500 execution-plan/scaling cliff**.

Example:

```text
Reference 750 POS31 = 45 sec
Current 2500 POS31 = 45 min
```

That is a ~60× runtime increase for 3.33× data. That would demand execution-plan investigation.

**B. 750 also takes 30–60 minutes under `psql` on this D: cluster.**

Then population size is essentially exonerated.

We would have proven:

```text
Original DBeaver / original environment:
750 = fast

Current psql / D:-cluster environment:
750 = very slow
```

Then we investigate:

- C: SSD versus D: HDD;
- PostgreSQL cluster configuration;
- effective session settings;
- statistics;
- JIT;
- memory;
- client/JDBC initialization settings;
- planner cost parameters;
- differences between the original `msbf_strategy` cluster and this isolated Campaign Scale cluster.

And at that point I would be very interested in running the **same exact 750 benchmark in DBeaver against the current D:-resident `msbf_restore_test` database**.

That would isolate the client/session variable completely:

```text
same database
same 750 rows
same D: drive
same PostgreSQL server
same SQL

psql vs DBeaver
```

If DBeaver suddenly runs it in 30 seconds while psql takes 40 minutes, then we have a very concrete session/protocol/configuration difference to find.

**C. Both psql and DBeaver are slow against the current 750 reference.**

Then the culprit is almost certainly **the current PostgreSQL cluster/storage/configuration**, not Campaign Scale population logic.

### One thing I would change from your proposed test

I wouldn't literally “process one-third of the current 2,500 data.”

That sounds equivalent, but it isn't as scientifically clean.

If we filter a 2,500 blueprint to 750 merchants, PostgreSQL might still generate all 2,500 rows internally before applying the filter. Then we'd think we tested 750 when we actually paid much of the 2,500 computational cost.

Using the genuine 750 Reference R1 avoids that ambiguity entirely.

### And we should capture the actual execution plan

The 750 benchmark shouldn't just give us elapsed time. It should capture:

```sql
EXPLAIN (ANALYZE, BUFFERS, SETTINGS, WAL, SUMMARY)
```

for the POS31 computation.

Then once the 2,500 run is finished, we can obtain the corresponding 2,500 plan.

That comparison will answer questions like:

```text
750                       2,500
------------------        ------------------
Hash Join                 Nested Loop?
0 temp spill              20 GB temp spill?
correct row estimates     estimates off 100×?
2 sec blueprint           35 min blueprint?
index used                sequential/repeated scan?
JIT off/on                JIT difference?
```

No speculation.

### One more strong clue

Your published M1.4 generator itself is structurally the same code used originally. It produces the merchant × date grid and performs the settlement self-join. [export reference: filecite | turn61file0 | L83-L124] [export reference: filecite | turn61file0 | L208-L220]

And your original execution guide explicitly allows either **DBeaver or psql** for the accepted stage. [export reference: filecite | turn57file1 | L27-L35]

So I agree with your underlying premise:

> **We should not accept “2,500 is bigger” as the explanation until a controlled 750 benchmark proves it.**

The current R4 run should continue untouched because running another CPU-heavy benchmark simultaneously would contaminate both timings.

As soon as R4 finishes or stops, the very next action I recommend is the **750 Reference R1 POS31 benchmark on the same D:-resident PostgreSQL cluster**. That single test will tell us which branch of the investigation to follow.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ecc1fecb-a6a7-40e1-9c36-3e9a2bdb4aba"></a>
## Andrew / user · C132-M00226

C132-M00226 · 2026-09-13T17:23:29.979000-04:00 · active path

Preceding visible parent: [C132-M00225](part-10.md#m-fe677a03-4463-4ad9-8bb6-e17a435a33db)

<!-- BEGIN_SOURCE_MESSAGE -->
prepare the test
<!-- END_SOURCE_MESSAGE -->


<a id="m-7a44889c-a4f2-490f-99f3-19a9b62ea3ff"></a>
## Assistant · C132-M00227

C132-M00227 · 2026-09-13T17:23:31.917996-04:00 · active path

Preceding visible parent: [C132-M00226](part-10.md#m-ecc1fecb-a6a7-40e1-9c36-3e9a2bdb4aba)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll make this a **controlled 750 benchmark**, not a partial rerun: same PostgreSQL cluster, same D: storage, same published M1.4 functions, no persistent writes, and it will refuse to run while the 2,500 qualification is still active.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7e872698-8409-4a8e-bfd0-69b05cb1b348"></a>
## Assistant · C132-M00228

C132-M00228 · 2026-09-13T17:23:31.917996-04:00 · active path

Preceding visible parent: [C132-M00227](part-10.md#m-7a44889c-a4f2-490f-99f3-19a9b62ea3ff)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m preparing a **two-part 750 benchmark** against `msbf_restore_test`: (A) the exact POS31 reproduction query that is slow now, and (B) full M1.4 blueprint materialization into a temporary table. Each has a 15-minute ceiling and leaves the reference database unchanged.
<!-- END_SOURCE_MESSAGE -->


<a id="m-eaa582ab-6380-487b-a628-f6f0191e7ad1"></a>
## Assistant · C132-M00229

C132-M00229 · 2026-09-13T17:25:45.104290-04:00 · active path

Preceding visible parent: [C132-M00228](part-10.md#m-7e872698-8409-4a8e-bfd0-69b05cb1b348)

<!-- BEGIN_SOURCE_MESSAGE -->
Prepared.

### 750 controlled performance benchmark

**Download the benchmark package** (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913.zip`; referenced bytes not established here)

PowerShell launcher (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913/RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1.ps1`; referenced bytes not established here)

Exact SQL benchmark (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913.sql`; referenced bytes not established here)

README (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913/README.md`; referenced bytes not established here)

SHA-256 (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913.zip.sha256`; referenced bytes not established here)

SHA-256:

```text
e5d30ce222f0b7d80ff112485cd364f2b45b372d1dfee1846514c87909e79402
```

### What it tests

It uses the genuine accepted **750 reference** `msbf_restore_test` on the **same PostgreSQL 17.9 D:-resident cluster** and measures two things:

1. **Exact POS31 deterministic reproduction computation** — the same published control currently taking an extreme amount of time at 2,500.
2. **Full M1.4 deterministic blueprint materialization** — the computational heart of the generation stage.

It also records the relevant PostgreSQL session settings, table statistics, indexes, buffers, WAL, execution plan, and execution time.

### Safety

It will **refuse to run while the current 2,500 qualification is active**, so we do not contaminate either timing.

It also:

- runs only against `msbf_restore_test`;
- verifies **750 merchants / 135,000 POS rows / 180 dates / M1.4 gate PASS**;
- creates only TEMP objects;
- performs no persistent MSBF DML;
- wraps everything in a transaction and rolls it back;
- gives each benchmark statement a **15-minute ceiling**.

The original M1.4 published execution target was indeed 135,000 rows for 750 merchants across 180 days. [export reference: filecite | turn57file1 | L61-L71]

### How we'll interpret it

If the 750 benchmark runs in seconds/minutes while the 2,500 query takes ~60 minutes, we have strong evidence of a **severe scale/planner cliff**.

If the same 750 workload is also extremely slow under this `psql`/D:-cluster environment, then population size is largely exonerated. The next test becomes very clean: run the **exact same SQL file in DBeaver against the exact same `msbf_restore_test` database**.

That will isolate:

```text
same SQL
same 750 data
same PostgreSQL server
same D: storage

psql vs DBeaver/session
```

Do **not** run this benchmark until the current R4 qualification finishes or stops.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b9a052b6-7a39-4574-b895-cc2dfd10df12"></a>
## Andrew / user · C132-M00230

C132-M00230 · 2026-09-13T17:28:32.463000-04:00 · active path

Preceding visible parent: [C132-M00229](part-10.md#m-eaa582ab-6380-487b-a628-f6f0191e7ad1)

<!-- BEGIN_SOURCE_MESSAGE -->
until the current R4 qualification finishes...it is still on the same M1 core 3/68 process I called out before and currently at 6570 seconds elapsed. i am not waiting for that to complete.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3b05b54e-ea8c-4273-9313-6cee2c0e4d73"></a>
## Assistant · C132-M00231

C132-M00231 · 2026-09-13T17:28:34.272657-04:00 · active path

Preceding visible parent: [C132-M00230](part-10.md#m-b9a052b6-7a39-4574-b895-cc2dfd10df12)

<!-- BEGIN_SOURCE_MESSAGE -->
Agreed. At **6,570 seconds (~109.5 minutes)** on M1 core 3/68, I would stop the R4 qualification and run the controlled 750 benchmark instead.

In the **original R4 PowerShell window**, press:

```text
Ctrl+C
```

**once**, then let the qualification tool finish its stop handling and produce a `_RETURN.zip` if possible. Do not close the window immediately.

This is a reasonable interruption point because `source_029` is the published **M1.4 positive-validation script**, which runs inside an explicit transaction beginning with `BEGIN`; interrupting the active statement should abort that transaction rather than leave a partially accepted M1.4 validation state. [export reference: filecite | turn56file0 | L12-L32]

After the Python qualification process has exited, run the 750 benchmark. Do **not** run it concurrently with R4, because CPU contention would make the comparison useless.

The test we want is now very clean:

```text
Current 2,500:
same cluster / D: drive / psql
M1.4 POS31 > 1 hour

versus

Reference 750:
same cluster / D: drive / psql
same published POS31 computation
```

If the 750 benchmark is also very slow, that strongly points away from population size and toward the current PostgreSQL environment/session/execution path.

If 750 is fast, then we have directly demonstrated a severe scaling/planner cliff.

Once R4 stops, paste the stop output here, then run the benchmark package I prepared.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a5dc050e-de62-440c-95ff-db69d03a1541"></a>
## Andrew / user · C132-M00232

C132-M00232 · 2026-09-13T17:29:19.929000-04:00 · active path

Preceding visible parent: [C132-M00231](part-10.md#m-3b05b54e-ea8c-4273-9313-6cee2c0e4d73)

**Editorial record note:** Attachment references: LEAP3_R4_NATIVE_20260913T182750Z_b28da63f_RETURN.zip.sha256; LEAP3_R4_NATIVE_20260913T182750Z_b28da63f_RETURN.zip.validation.json; LEAP3_R4_NATIVE_20260913T182750Z_b28da63f_RETURN.zip

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-99e67a61-457c-4071-b99b-1026baeb6a92"></a>
## Assistant · C132-M00233

C132-M00233 · 2026-09-13T17:29:22.471581-04:00 · active path

Preceding visible parent: [C132-M00232](part-10.md#m-a5dc050e-de62-440c-95ff-db69d03a1541)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll inspect the stopped R4 return to confirm exactly where it was interrupted and whether the 750 benchmark can now proceed cleanly.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7fea5b9b-8d48-407a-8885-716131d586da"></a>
## Assistant · C132-M00234

C132-M00234 · 2026-09-13T17:29:54.845157-04:00 · active path

Preceding visible parent: [C132-M00233](part-10.md#m-99e67a61-457c-4071-b99b-1026baeb6a92)

<!-- BEGIN_SOURCE_MESSAGE -->
The R4 return confirms the interruption was clean enough for the benchmark: `source_028` completed in **4,184.4 seconds (~69.7 min)**, `source_029` was interrupted after **6,597.0 seconds (~110.0 min)**, and no later source ran. The isolated R4 subject should now be preserved and left untouched.
<!-- END_SOURCE_MESSAGE -->


<a id="m-7c5dadd4-12f3-43f0-a26e-83ada8994865"></a>
## Assistant · C132-M00235

C132-M00235 · 2026-09-13T17:30:14.605680-04:00 · active path

Preceding visible parent: [C132-M00234](part-10.md#m-7fea5b9b-8d48-407a-8885-716131d586da)

<!-- BEGIN_SOURCE_MESSAGE -->
The R4 return confirms the stop exactly as intended: status is `M1_CONTINUATION_STOPPED`, with a valid return ZIP/CRC. [export reference: filecite | turn62file0 | L2-L6]

I inspected the return package in detail. The useful measured evidence is:

```text
source_028 — M1.4 generation
COMPLETED
Elapsed: 4,184.391 sec = 69.74 minutes

source_029 — M1.4 positive validation
INTERRUPTED by Ctrl+C
Elapsed: 6,597.014 sec = 109.95 minutes

Completed source IDs:
027, 028

Later sources:
NOT EXECUTED
```

So we now have a very strong 2,500 benchmark baseline:

```text
M1.4 generation     ~69.7 minutes
M1.4 validation     >109.9 minutes, unfinished
```

The new R4 subject was created, but it is isolated and should simply remain preserved. Do not resume or modify it.

## Proceed with the 750 benchmark now

The R4 Python qualification process has exited, so the benchmark's concurrency guard should now allow execution.

Use the benchmark package already prepared:

Download 750 benchmark (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913.zip`; referenced bytes not established here)

Extract it somewhere on D:, for example:

```text
D:\MSBF_CAMPAIGNS\BENCHMARKS\MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1
```

Then run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

& 'D:\MSBF_CAMPAIGNS\BENCHMARKS\MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1.ps1'
```

The benchmark will test the accepted 750 `msbf_restore_test` on the **same PostgreSQL server, same D: cluster, same machine, same `psql` client, and same published M1.4 functions**.

That makes the comparison unusually clean.

### The threshold for a meaningful finding is huge

If 750 POS31 takes:

```text
30 seconds
2 minutes
5 minutes
```

while 2,500 took **>110 minutes unfinished**, then 3.33× population clearly does **not** explain the degradation. We will have demonstrated a severe execution-plan/scaling cliff.

If 750 also takes something like:

```text
30–60+ minutes
```

then your hypothesis becomes much stronger: **the current Campaign Scale PostgreSQL execution environment behaves materially differently from your original DBeaver execution**, even at the original population size.

And then the next experiment is straightforward: run the exact same 750 SQL against the exact same `msbf_restore_test` database from DBeaver. That isolates client/session behavior with essentially every other variable held constant.

This benchmark is the right next move.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0ba83767-0901-4ea7-abf4-3bb975ee592f"></a>
## Andrew / user · C132-M00236

C132-M00236 · 2026-09-13T17:35:23.163000-04:00 · active path

Preceding visible parent: [C132-M00235](part-10.md#m-7c5dadd4-12f3-43f0-a26e-83ada8994865)

<!-- BEGIN_SOURCE_MESSAGE -->

============================================================
MSBF M1.4 750 PERFORMANCE BENCHMARK
============================================================
Database: msbf_restore_test
Output:   D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R1_20260913T213507Z

Phase A: exact POS31 expected-vs-actual deterministic reproduction
Phase B: full M1.4 expected-blueprint materialization to TEMP

No persistent MSBF data will be changed.

psql: error: connection to server at "127.0.0.1", port 55432 failed: Connection refused (0x0000274D/10061)
        Is the server running on that host and accepting TCP/IP connections?

============================================================
BENCHMARK STOPPED / TIMED OUT
============================================================
Output log:
  D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R1_20260913T213507Z\M1_4_750_BENCHMARK_OUTPUT.txt

Metadata:
  D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R1_20260913T213507Z\M1_4_750_BENCHMARK_METADATA.txt

Paste the benchmark output back into ChatGPT.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2a5a125f-e6b2-45b7-a876-23962eaaff97"></a>
## Assistant · C132-M00237

C132-M00237 · 2026-09-13T17:35:27.406582-04:00 · active path

Preceding visible parent: [C132-M00236](part-10.md#m-0ba83767-0901-4ea7-abf4-3bb975ee592f)

<!-- BEGIN_SOURCE_MESSAGE -->
This benchmark never reached PostgreSQL at all. The `connection refused` happened before Phase A, so **no benchmark SQL executed and no reference data was touched**.

Most likely the PostgreSQL cluster stopped when we interrupted the long R4 console process. That is an infrastructure condition, not a benchmark result.

Run this **single block** in PowerShell. It safely checks the exact known MSBF cluster, starts it only if it is confirmed stopped, waits for readiness, and then reruns the 750 benchmark.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$PgBin = 'C:\Program Files\PostgreSQL\17\bin'
$Data = 'D:\MSBF_CAMPAIGNS\pg_clusters\msbf_cs_ref750_routeb_20260912_012713'
$LogDir = 'D:\MSBF_CAMPAIGNS\pg_logs'
$Port = 55432

$Benchmark = 'D:\MSBF_CAMPAIGNS\BENCHMARKS\MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1.ps1'

$PgIsReady = Join-Path $PgBin 'pg_isready.exe'
$PgCtl = Join-Path $PgBin 'pg_ctl.exe'

Write-Host "`nChecking PostgreSQL endpoint 127.0.0.1:$Port ..."

& $PgIsReady -h 127.0.0.1 -p $Port
$ReadyCode = $LASTEXITCODE

if ($ReadyCode -ne 0) {

    Write-Host "Endpoint unavailable. Checking configured MSBF cluster state..."

    & $PgCtl status -D $Data
    $StatusCode = $LASTEXITCODE

    if ($StatusCode -eq 0) {
        throw "Configured PostgreSQL cluster reports RUNNING but 127.0.0.1:$Port is unavailable. Stop here; do not start a second copy."
    }

    if ($StatusCode -ne 3) {
        throw "Could not establish that the configured cluster is safely stopped. pg_ctl status exit code: $StatusCode"
    }

    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    $ServerLog = Join-Path $LogDir ("benchmark_pg_start_" + [DateTime]::UtcNow.ToString("yyyyMMdd'T'HHmmss'Z'") + ".log")

    Write-Host "Configured cluster is stopped. Starting it safely..."

    & $PgCtl start `
        -D $Data `
        -l $ServerLog `
        -W `
        -o "-p $Port -h 127.0.0.1"

    if ($LASTEXITCODE -ne 0) {
        throw "PostgreSQL start failed. See: $ServerLog"
    }

    $Ready = $false

    for ($i = 1; $i -le 30; $i++) {
        Start-Sleep -Seconds 1

        & $PgIsReady -h 127.0.0.1 -p $Port *> $null

        if ($LASTEXITCODE -eq 0) {
            $Ready = $true
            break
        }
    }

    if (-not $Ready) {
        throw "PostgreSQL did not become ready on 127.0.0.1:$Port."
    }
}

Write-Host "`nPostgreSQL is accepting connections."

if (-not (Test-Path -LiteralPath $Benchmark -PathType Leaf)) {
    throw "Benchmark launcher not found: $Benchmark"
}

Write-Host "`nStarting controlled 750 benchmark..."
& $Benchmark
```

If your benchmark launcher is extracted somewhere else, change **only** this line:

```powershell
$Benchmark = '...\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1.ps1'
```

Once it starts successfully, the result we care about is the elapsed time and execution plan for **Phase A POS31**. If that 750 test completes quickly, we'll have very strong evidence that the current 2,500 path hit a severe scaling/planner cliff rather than merely being “3.3× bigger.”
<!-- END_SOURCE_MESSAGE -->


<a id="m-f45e246f-7c19-42a6-9ef3-fb2dbd10bd13"></a>
## Andrew / user · C132-M00238

C132-M00238 · 2026-09-13T17:36:25.101000-04:00 · active path

Preceding visible parent: [C132-M00237](part-10.md#m-2a5a125f-e6b2-45b7-a876-23962eaaff97)

<!-- BEGIN_SOURCE_MESSAGE -->

Checking PostgreSQL endpoint 127.0.0.1:55432 ...
127.0.0.1:55432 - no response
Endpoint unavailable. Checking configured MSBF cluster state...
pg_ctl: no server running
Configured cluster is stopped. Starting it safely...
server starting

PostgreSQL is accepting connections.

Starting controlled 750 benchmark...

============================================================
MSBF M1.4 750 PERFORMANCE BENCHMARK
============================================================
Database: msbf_restore_test
Output:   D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R1_20260913T213606Z

Phase A: exact POS31 expected-vs-actual deterministic reproduction
Phase B: full M1.4 expected-blueprint materialization to TEMP

No persistent MSBF data will be changed.

BEGIN
SET
SET
DO
SELECT 1
      section      |   database_name   | server_version |                           data_directory                            | run_id | population_id | merchants | pos_rows
-------------------+-------------------+----------------+---------------------------------------------------------------------+--------+---------------+-----------+----------
 BENCHMARK_CONTEXT | msbf_restore_test | 17.9           | D:/MSBF_CAMPAIGNS/pg_clusters/msbf_cs_ref750_routeb_20260912_012713 |      1 | MSBF_POP_0001 |       750 |   135000
(1 row)

     section      |              name               | setting | unit |       source
------------------+---------------------------------+---------+------+--------------------
 SESSION_SETTINGS | effective_cache_size            | 524288  | 8kB  | default
 SESSION_SETTINGS | effective_io_concurrency        | 0       |      | default
 SESSION_SETTINGS | jit                             | on      |      | default
 SESSION_SETTINGS | maintenance_work_mem            | 65536   | kB   | default
 SESSION_SETTINGS | max_parallel_workers            | 8       |      | default
 SESSION_SETTINGS | max_parallel_workers_per_gather | 2       |      | default
 SESSION_SETTINGS | min_parallel_index_scan_size    | 64      | 8kB  | default
 SESSION_SETTINGS | min_parallel_table_scan_size    | 1024    | 8kB  | default
 SESSION_SETTINGS | random_page_cost                | 4       |      | default
 SESSION_SETTINGS | seq_page_cost                   | 1       |      | default
 SESSION_SETTINGS | shared_buffers                  | 16384   | 8kB  | configuration file
 SESSION_SETTINGS | temp_file_limit                 | -1      | kB   | default
 SESSION_SETTINGS | work_mem                        | 4096    | kB   | default
(13 rows)

   section   | schemaname |         relname         | n_live_tup | n_dead_tup | last_analyze | last_autoanalyze | analyze_count | autoanalyze_count
-------------+------------+-------------------------+------------+------------+--------------+------------------+---------------+-------------------
 TABLE_STATS | msbf_m1    | merchant_pos_daily_base |          0 |          0 |              |                  |             0 |                 0
(1 row)

 section |      indexname      |                                                                          indexdef
---------+---------------------+-------------------------------------------------------------------------------------------------------------------------------------------------------------
 INDEXES | r1b_pk_1054ac0250fd | CREATE UNIQUE INDEX r1b_pk_1054ac0250fd ON msbf_m1.merchant_pos_daily_base USING btree (population_id, merchant_id, processor_account_id, observation_date)
(1 row)

      benchmark_marker       |          observed_at
-----------------------------+-------------------------------
 PHASE_A_POS31_EXPLAIN_BEGIN | 2026-09-13 17:36:07.736425-04
(1 row)

psql:D:/MSBF_CAMPAIGNS/BENCHMARKS/M1_4_750_R1_20260913T213606Z/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R1_20260913.sql:108: ERROR:  function msbf_m1.m1_4_expected_pos_snapshot(bigint) does not exist
LINE 3: FROM msbf_m1.m1_4_expected_pos_snapshot((SELECT run_id FROM ...
             ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.

============================================================
BENCHMARK STOPPED / TIMED OUT
============================================================
Output log:
  D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R1_20260913T213606Z\M1_4_750_BENCHMARK_OUTPUT.txt

Metadata:
  D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R1_20260913T213606Z\M1_4_750_BENCHMARK_METADATA.txt

Paste the benchmark output back into ChatGPT.
<!-- END_SOURCE_MESSAGE -->
