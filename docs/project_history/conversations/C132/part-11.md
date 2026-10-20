# MSBF - Campaign Scale 750 - 2,500 - 25,000 Part 2

Part 11 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-10.md)
[Next part](part-12.md)

<a id="m-a3845a25-4199-41d2-8a7b-01dc76b4fbd2"></a>
## Assistant · C132-M00239

C132-M00239 · 2026-09-13T17:36:28.092358-04:00 · active path

Preceding visible parent: [C132-M00238](part-10.md#m-f45e246f-7c19-42a6-9ef3-fb2dbd10bd13)

<!-- BEGIN_SOURCE_MESSAGE -->
This failure is informative but not a benchmark result: the 750 reference contains the accepted **data**, but not the original M1.4 helper functions needed by POS31. I’m correcting the test so it uses a **disposable clone of the 750 reference**, installs the exact published M1.4 functions there, then benchmarks without touching `msbf_restore_test`.
<!-- END_SOURCE_MESSAGE -->


<a id="m-be987e3b-69cb-4305-a97f-c05fa640cfc9"></a>
## Assistant · C132-M00240

C132-M00240 · 2026-09-13T17:36:53.257317-04:00 · active path

Preceding visible parent: [C132-M00239](part-11.md#m-a3845a25-4199-41d2-8a7b-01dc76b4fbd2)

<!-- BEGIN_SOURCE_MESSAGE -->
One additional clue from your failed benchmark is potentially important: the reference table has 135,000 physical rows, but PostgreSQL's statistics view reports **zero live tuples and no ANALYZE history**. That does not by itself prove bad planner statistics, but it is enough that the corrected disposable-clone benchmark should measure **before and after ANALYZE** using the exact same POS31 query.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ee00b1d5-b666-4db3-8077-992db90c24ac"></a>
## Assistant · C132-M00241

C132-M00241 · 2026-09-13T17:37:54.829728-04:00 · active path

Preceding visible parent: [C132-M00240](part-11.md#m-be987e3b-69cb-4305-a97f-c05fa640cfc9)

<!-- BEGIN_SOURCE_MESSAGE -->
That R1 benchmark did **not** test performance; it stopped because `msbf_restore_test` preserves the accepted 750 data but does not retain the published M1.4 helper functions needed for POS31.

I corrected the experiment rather than modifying the reference database.

### Corrected 750 benchmark R2

Download benchmark R2 (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R2_20260913.zip`; referenced bytes not established here)

SHA-256 (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R2_20260913.zip.sha256`; referenced bytes not established here)

Validation record (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R2_20260913_VALIDATION.json`; referenced bytes not established here)

SHA-256:

```text
694b9e3c8d8c86a599b9dc228204511fa95713af0ec856ced2ad07ae92a02f07
```

R2 does this:

```text
msbf_restore_test
        ↓
new disposable 750 clone
        ↓
install exact published M1.4 helper functions
        ↓
POS31 benchmark
        ↓
blueprint-generation benchmark
        ↓
ANALYZE disposable clone
        ↓
repeat the exact same two benchmarks
```

The five helper definitions come directly from the published Program 25 source; `msbf_restore_test` itself is never modified.

### One finding from R1 is already interesting

You physically had:

```text
135,000 POS rows
```

but PostgreSQL reported:

```text
n_live_tup       0
last_analyze     NULL
last_autoanalyze NULL
analyze_count    0
```

That **does not yet prove** the planner had unusable statistics, because planner statistics also live in `pg_class`/`pg_stats`, which R1 didn't capture properly.

R2 now captures those explicitly and then performs a controlled:

```text
before ANALYZE
vs.
after ANALYZE
```

comparison.

That could be very important. If POS31 is dramatically faster after `ANALYZE`, we will have identified a major Campaign Scale performance problem immediately.

### Run it

Extract R2 somewhere convenient on D:, then run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

& 'D:\<where-you-extracted-it>\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R2.ps1'
```

Each heavy benchmark has a **10-minute ceiling**. A timeout is itself a valid result, so this cannot turn into another two-hour wait.

At the end it creates:

```text
BENCHMARK_SUMMARY.txt
01_INSTALL_HELPERS.log
02_DIAGNOSTICS_BEFORE.log
03_A1_POS31_BEFORE_ANALYZE.log
04_B1_BLUEPRINT_BEFORE_ANALYZE.log
05_ANALYZE.log
06_A2_POS31_AFTER_ANALYZE.log
07_B2_BLUEPRINT_AFTER_ANALYZE.log
```

Paste the summary and logs back here. This test should finally tell us whether we're dealing with **population scaling, planner/statistics behavior, or a broader runtime/environment regression**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-85a1ead4-1baa-4d0e-8fad-923fd9e2e79e"></a>
## Andrew / user · C132-M00242

C132-M00242 · 2026-09-13T17:44:21.851000-04:00 · active path

Preceding visible parent: [C132-M00241](part-11.md#m-ee00b1d5-b666-4db3-8077-992db90c24ac)

**Editorial record note:** Attachment references: 01_INSTALL_HELPERS.log

<!-- BEGIN_SOURCE_MESSAGE -->
127.0.0.1:55432 - accepting connections

============================================================
MSBF M1.4 CONTROLLED 750 BENCHMARK R2
============================================================
Reference source: msbf_restore_test
Disposable clone: msbf_bench750_20260913t214011z
Output:           D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R2_20260913T214011Z

The reference database will remain unchanged.
The benchmark clone will be preserved after the test.


--- Install exact published M1.4 helper functions ---
psql:D:/MSBF_CAMPAIGNS/BENCHMARKS/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R2/01_INSTALL_EXACT_PUBLISHED_M1_4_HELPERS.sql:164: ERROR:  function msbf_ctl.deterministic_uniform(text, text) does not exist
LINE 57:         msbf_ctl.deterministic_uniform(m.merchant_id,ctx.det...
                 ^
HINT:  No function matches the given name and argument types. You might need to add explicit type casts.
Install exact published M1.4 helper functions exit code: 3
Exception: D:\MSBF_CAMPAIGNS\BENCHMARKS\MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R2\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R2.ps1:89
Line |
  89 |  … de -ne 0) { throw "Helper installation failed in disposable clone." } …
     |                ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Helper installation failed in disposable clone.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f5ed7d53-23ed-485f-b54a-1febf58ae1ab"></a>
## Assistant · C132-M00243

C132-M00243 · 2026-09-13T17:44:23.671183-04:00 · active path

Preceding visible parent: [C132-M00242](part-11.md#m-85a1ead4-1baa-4d0e-8fad-923fd9e2e79e)

<!-- BEGIN_SOURCE_MESSAGE -->
This second stop is again **before any timing benchmark**. The clone lacks two lower-level deterministic helper functions (`msbf_ctl.deterministic_uniform` / `deterministic_normal`) that Program 25 depends on. I’m resolving those exact published dependencies now so the next benchmark is self-contained rather than discovering them one at a time.
<!-- END_SOURCE_MESSAGE -->


<a id="m-349f4993-ea57-404d-9bfe-9ef3be59253e"></a>
## Assistant · C132-M00244

C132-M00244 · 2026-09-13T17:44:34.125527-04:00 · active path

Preceding visible parent: [C132-M00243](part-11.md#m-f5ed7d53-23ed-485f-b54a-1febf58ae1ab)

<!-- BEGIN_SOURCE_MESSAGE -->
I found the exact missing dependencies in the published G0 physical schema: `msbf_ctl.deterministic_uniform(text,text)` and `msbf_ctl.deterministic_normal(text,text)`. Those are the only external functions used by the five M1.4 helpers we are installing. I’ll add those exact two definitions ahead of the M1.4 helpers and reseal the benchmark so this dependency chain is complete.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0d1d8ee1-71db-42e8-87f2-bd059602361a"></a>
## Assistant · C132-M00245

C132-M00245 · 2026-09-13T17:44:50.204518-04:00 · active path

Preceding visible parent: [C132-M00244](part-11.md#m-349f4993-ea57-404d-9bfe-9ef3be59253e)

<!-- BEGIN_SOURCE_MESSAGE -->
The dependency audit is now closed: the five published M1.4 helper definitions call **only** those two G0 deterministic functions outside their own M1.4 set. There are no further hidden function dependencies to discover one-by-one.
<!-- END_SOURCE_MESSAGE -->


<a id="m-ebf432df-e991-4872-bc30-b9d4c61ee9a3"></a>
## Assistant · C132-M00246

C132-M00246 · 2026-09-13T17:45:39.463468-04:00 · active path

Preceding visible parent: [C132-M00245](part-11.md#m-0d1d8ee1-71db-42e8-87f2-bd059602361a)

<!-- BEGIN_SOURCE_MESSAGE -->
That R2 stop was still **before any performance benchmark**. It failed because the disposable clone lacked the two G0 deterministic primitives that the published M1.4 profile function calls: `msbf_ctl.deterministic_uniform()` and `deterministic_normal()`. Your log shows the failure occurred while compiling `m1_4_merchant_operating_profile()`. [export reference: filecite | turn63file0 | L86-L104] Those two functions are defined in the published G0 physical schema. [export reference: filecite | turn64file0 | L20-L29]

I have now closed the dependency chain completely: **2 exact G0 deterministic functions + 5 exact M1.4 helper functions = 7/7**, with no unresolved external MSBF function calls.

### Corrected benchmark R3

Download benchmark R3 (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3_20260913.zip`; referenced bytes not established here)

SHA-256 (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3_20260913.zip.sha256`; referenced bytes not established here)

Validation record (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3_20260913_VALIDATION.json`; referenced bytes not established here)

PowerShell launcher (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3_20260913/RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3.ps1`; referenced bytes not established here)

SHA-256:

```text
13b36c71ad3dbd384dd2361df209e513e5f10e913a8b2743a50c4b937aa18ebf
```

R3 creates a **new disposable 750 clone**, installs the exact seven-function dependency set there, and then measures:

```text
POS31 before ANALYZE
blueprint before ANALYZE
        ↓
targeted ANALYZE
        ↓
POS31 after ANALYZE
blueprint after ANALYZE
```

Each heavy statement has a **10-minute ceiling**, so we will not repeat the multi-hour wait.

The failed R2 clone can simply remain preserved for now; don't reuse it.

After extracting R3, run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

& 'D:\<where-you-extracted-R3>\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3.ps1'
```

This one should finally produce the comparison we need.
<!-- END_SOURCE_MESSAGE -->


<a id="m-2dbb92ae-5873-4374-bc8f-c9dffe8239ba"></a>
## Andrew / user · C132-M00247

C132-M00247 · 2026-09-13T17:49:45.288000-04:00 · active path

Preceding visible parent: [C132-M00246](part-11.md#m-ebf432df-e991-4872-bc30-b9d4c61ee9a3)

**Editorial record note:** Attachment references: 01_INSTALL_DEPENDENCIES.log

<!-- BEGIN_SOURCE_MESSAGE -->
127.0.0.1:55432 - accepting connections

============================================================
MSBF M1.4 CONTROLLED 750 BENCHMARK R3
============================================================
Reference source: msbf_restore_test
Disposable clone: msbf_bench750_r3_20260913t214746z
Output:           D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R3_20260913T214746Z

Exact G0 deterministic helpers + exact M1.4 helpers will be
installed into the disposable clone only.
Reference database remains unchanged.


--- Install exact published dependency-closed helper set ---
Install exact published dependency-closed helper set exit code: 0
Exception: D:\MSBF_CAMPAIGNS\BENCHMARKS\MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R3.ps1:80
Line |
  80 |  if ($Install -ne 0) { throw "Dependency installation failed." }
     |                        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Dependency installation failed.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b7df07ca-b352-4477-a2fc-8c5ec39d590f"></a>
## Assistant · C132-M00248

C132-M00248 · 2026-09-13T17:49:49.774014-04:00 · active path

Preceding visible parent: [C132-M00247](part-11.md#m-2dbb92ae-5873-4374-bc8f-c9dffe8239ba)

<!-- BEGIN_SOURCE_MESSAGE -->
The benchmark SQL actually **installed successfully**. The failure is in my PowerShell harness: `Invoke-Step` captured `psql`’s normal stdout along with the numeric exit code, so `$Install` became an array rather than integer `0`, and the subsequent `if ($Install -ne 0)` falsely threw. The log shows the dependency functions compiling successfully. 

I’m fixing that launcher-only defect now; no SQL benchmark logic needs to change.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3a7f39dd-9153-4822-943e-261b3ec017be"></a>
## Assistant · C132-M00249

C132-M00249 · 2026-09-13T17:50:19.800480-04:00 · active path

Preceding visible parent: [C132-M00248](part-11.md#m-b7df07ca-b352-4477-a2fc-8c5ec39d590f)

<!-- BEGIN_SOURCE_MESSAGE -->
The R3 benchmark still did **not** reach the timing test. Its SQL installation actually succeeded; the failure was only a PowerShell return-value bug. Normal `psql` output was being captured together with exit code `0`, so the launcher falsely treated a successful step as failed. The log shows the published deterministic functions were created successfully. [export reference: filecite | turn65file0 | L1-L16]

I fixed only that harness behavior. **No benchmark SQL, published functions, ANALYZE logic, timeouts, or database safety controls changed.**

### Corrected benchmark R4

Download benchmark R4 (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R4_20260913.zip`; referenced bytes not established here)

SHA-256 (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R4_20260913.zip.sha256`; referenced bytes not established here)

Validation record (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R4_20260913_VALIDATION.json`; referenced bytes not established here)

PowerShell launcher (historical reference: `sandbox:[session]/MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R4_20260913/RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R4.ps1`; referenced bytes not established here)

SHA-256:

```text
99d0917699f7626139a6da22f2a9b3b8bdae10c187d35f68f73307e19f28c75d
```

Extract R4 to a fresh folder and run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

& 'D:\<where-you-extracted-R4>\RUN_MSBF_M1_4_750_PERFORMANCE_BENCHMARK_R4.ps1'
```

The prior R3 disposable clone can simply remain preserved; R4 creates a new one. This should finally proceed into the actual **750 POS31 / blueprint before-and-after-ANALYZE timing test**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cc0d45b2-5cc4-4e2d-889e-ff37436b8f7b"></a>
## Andrew / user · C132-M00250

C132-M00250 · 2026-09-13T17:58:04.455000-04:00 · active path

Preceding visible parent: [C132-M00249](part-11.md#m-3a7f39dd-9153-4822-943e-261b3ec017be)

<!-- BEGIN_SOURCE_MESSAGE -->
127.0.0.1:55432 - accepting connections

============================================================
MSBF M1.4 CONTROLLED 750 BENCHMARK R4
============================================================
Reference source: msbf_restore_test
Disposable clone: msbf_bench750_r4_20260913t215311z
Output:           D:\MSBF_CAMPAIGNS\BENCHMARKS\M1_4_750_R4_20260913T215311Z

Exact G0 deterministic helpers + exact M1.4 helpers will be
installed into the disposable clone only.
Reference database remains unchanged.


--- Install exact published dependency-closed helper set ---
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
CREATE FUNCTION
Install exact published dependency-closed helper set exit code: 0

--- Diagnostics before ANALYZE ---
Timing is on.
           database_name           | server_version |                           data_directory                            | work_mem | jit | max_parallel_workers | max_parallel_workers_per_gather | effective_cache_size | effective_io_concurrency | random_page_cost | seq_page_cost
-----------------------------------+----------------+---------------------------------------------------------------------+----------+-----+----------------------+---------------------------------+----------------------+--------------------------+------------------+---------------
 msbf_bench750_r4_20260913t215311z | 17.9           | D:/MSBF_CAMPAIGNS/pg_clusters/msbf_cs_ref750_routeb_20260912_012713 | 4MB      | on  | 8                    | 2                               | 4GB                  | 0                        | 4                | 1
(1 row)

Time: 2.170 ms
 run_id | population_id | merchants | pos_rows | dates
--------+---------------+-----------+----------+-------
      1 | MSBF_POP_0001 |       750 |   135000 |   180
(1 row)

Time: 300.316 ms
 schemaname |            relname             | planner_reltuples | relpages | n_live_tup | n_dead_tup | last_analyze | last_autoanalyze | analyze_count | autoanalyze_count | pg_stats_columns
------------+--------------------------------+-------------------+----------+------------+------------+--------------+------------------+---------------+-------------------+------------------
 msbf_ctl   | run_parameter_snapshot         |              1203 |       52 |          0 |          0 |              |                  |             0 |                 0 |                7
 msbf_ctl   | run_registry                   |                 3 |        1 |          0 |          0 |              |                  |             0 |                 0 |                0
 msbf_m1    | merchant_industry_assignment   |               750 |       10 |          0 |          0 |              |                  |             0 |                 0 |                7
 msbf_m1    | merchant_master                |               750 |       20 |          0 |          0 |              |                  |             0 |                 0 |               14
 msbf_m1    | merchant_pos_daily_base        |            135000 |     4056 |          0 |          0 |              |                  |             0 |                 0 |               21
 msbf_m1    | merchant_relationship_snapshot |               750 |       22 |          0 |          0 |              |                  |             0 |                 0 |               15
 msbf_m1    | partner_channel                |                 5 |        1 |          0 |          0 |              |                  |             0 |                 0 |                0
 msbf_m1    | population_registry            |                 1 |        1 |          0 |          0 |              |                  |             0 |                 0 |                0
 msbf_m1    | processor_account              |               750 |       20 |          0 |          0 |              |                  |             0 |                 0 |               13
(9 rows)

Time: 41.363 ms
Diagnostics before ANALYZE exit code: 0

--- A1 - POS31 before ANALYZE ---
Timing is on.
SET
Time: 0.560 ms
SET
Time: 0.119 ms
   marker    |          observed_at
-------------+-------------------------------
 POS31_BEGIN | 2026-09-13 17:54:41.559922-04
(1 row)

Time: 1.166 ms                  ok it is here now and the cursor at the bottom is blinking. am i supposed to press something? sometimes you had me press a 'q' i believe. or a spacebar.
<!-- END_SOURCE_MESSAGE -->


<a id="m-64ec45fa-ab92-404a-ada0-5f98ac6f938a"></a>
## Assistant · C132-M00251

C132-M00251 · 2026-09-13T17:58:08.833938-04:00 · active path

Preceding visible parent: [C132-M00250](part-11.md#m-cc0d45b2-5cc4-4e2d-889e-ff37436b8f7b)

<!-- BEGIN_SOURCE_MESSAGE -->
No—**do not press anything.**

The blinking cursor means **POS31 is actively running**. In this benchmark I explicitly disabled the pager with `-P pager=off`, so there is no `q` or spacebar interaction needed.

You are currently here:

```text
POS31_BEGIN | 2026-09-13 17:54:41...
```

Immediately after that, PostgreSQL is executing:

```sql
EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS, SUMMARY, TIMING OFF)
...
```

`EXPLAIN ANALYZE` does not print the plan until the underlying query finishes. So the quiet screen is expected.

Also, this particular benchmark has a **10-minute statement timeout**. One of two things will happen automatically:

- it finishes and prints the execution plan/timing; or
- at 10 minutes PostgreSQL cancels it with a statement-timeout error.

So **leave that PowerShell window untouched**. This is now the real 750 test we wanted.
<!-- END_SOURCE_MESSAGE -->


<a id="m-c277d6e6-3dfb-4f4b-82bc-9b54709ad4bf"></a>
## Andrew / user · C132-M00252

C132-M00252 · 2026-09-13T18:09:29.239000-04:00 · active path

Preceding visible parent: [C132-M00251](part-11.md#m-64ec45fa-ab92-404a-ada0-5f98ac6f938a)

**Editorial record note:** Attachment references: Pasted text(20260913-220925).txt

<!-- BEGIN_SOURCE_MESSAGE -->
what we have so far? thoughts so far? 
<!-- END_SOURCE_MESSAGE -->


<a id="m-9246938c-255d-46db-a523-e0da371ec8ae"></a>
## Assistant · C132-M00253

C132-M00253 · 2026-09-13T18:09:31.559060-04:00 · active path

Preceding visible parent: [C132-M00252](part-11.md#m-c277d6e6-3dfb-4f4b-82bc-9b54709ad4bf)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes — we already have a **major finding**, even before A2 finishes.

Your core suspicion is substantially confirmed: **the current Campaign Scale/PostgreSQL execution environment is slow even at the original 750 population.** The 750 benchmark produced exactly the kind of result you predicted.

At 750, using the accepted 135,000-row population, POS31 took **426.24 seconds = 7:06**, and materializing the M1.4 blueprint took **394.58 seconds = 6:34**. [export reference: filecite | turn66file0 | L67-L104] [export reference: filecite | turn66file0 | L127-L150]

That immediately changes the diagnosis.

The comparison now looks like this:

| Workload | 750 | 2,500 |
|---|---:|---:|
| M1.4 blueprint | **6.58 min** | **69.74 min** |
| POS31 validation | **7.10 min** | **>109.95 min unfinished** |
| Population ratio | 1× | 3.33× |

So even the **original-size 750 workload is already taking many minutes in this environment**.

That means the explanation cannot simply be:

> “2,500 merchants is larger than 750.”

You were right to reject that.

There are actually **two problems** visible now.

First, there is a **baseline environment/execution regression**. If your historical DBeaver execution of these exact M1.4 programs was seconds or low minutes, whereas the present 750 execution is 6½–7 minutes, something about the current PostgreSQL environment/session/storage/execution path is materially less efficient.

Second, on top of that baseline regression, there is also a **nonlinear scale problem**. The blueprint increased from 6.58 minutes at 750 to 69.74 minutes at 2,500:

```text
data increase:       3.33×
runtime increase:   ~10.6×
```

POS31 is even worse:

```text
750:       7.10 min
2,500:   >109.95 min

runtime increase: >15.5×
```

So this is not an either/or. We appear to have:

```text
1. Current environment is already much slower at 750
                        +
2. M1.4 scales very badly from 750 → 2,500
```

## The execution plan gives us some strong clues

One of the biggest findings is here:

```text
Function Scan on m1_4_expected_pos_snapshot
estimated rows = 1,000
actual rows    = 135,000
```

and the same for the actual snapshot. [export reference: filecite | turn66file0 | L86-L97]

That's a **135× cardinality underestimate** at 750.

At 2,500, if PostgreSQL is still assuming roughly 1,000 rows while actually receiving 450,000, the error becomes roughly:

```text
450×
```

That is exactly the sort of misestimation that can produce catastrophic plans as scale increases.

And notice what ANALYZE cannot directly fix: these are **set-returning SQL functions**. The planner is assigning the function scan an estimate of 1,000 rows. Updating table statistics does not necessarily teach PostgreSQL that this function returns 135,000 or 450,000 rows.

That makes the current A2 result particularly interesting. If A2 remains around seven minutes after ANALYZE, we'll have demonstrated that ordinary table statistics were **not the primary problem**.

## There's also substantial disk/temp activity

POS31 at 750 reported:

```text
temp read    = 36,116 blocks
temp written = 36,136 blocks
```

with both 135k-row sorts going to external disk:

```text
expected:
external merge
Disk: 13,504 kB

actual:
external sort
Disk: 14,016 kB
```

[export reference: filecite | turn66file0 | L69-L97]

The session is running with only:

```text
work_mem = 4 MB
```

on the D:-resident cluster. [export reference: filecite | turn66file0 | L27-L30]

That's important.

At just 135,000 rows, PostgreSQL is already spilling these sorts to disk. At 450,000 rows, the spill will be substantially larger.

And the M1.4 blueprint itself generated substantial temp traffic:

```text
temp read    = 32,375 blocks
temp written = 32,375 blocks
```

while producing only 135,000 final rows. [export reference: filecite | turn66file0 | L127-L142]

That's roughly **253 MB of temp reads and 253 MB of temp writes** at the 750 population, just for that blueprint evaluation.

On an HDD, that absolutely can matter.

But I still would **not** declare HDD the sole culprit, because six-plus minutes to produce 135k rows is excessive enough that the query architecture/planning deserves scrutiny too.

## The pre-ANALYZE statistics result is subtler than it first appeared

Earlier we saw:

```text
n_live_tup = 0
last_analyze = NULL
```

That looked suspicious.

But this better diagnostic tells us the planner actually already knew approximate physical cardinalities:

```text
merchant_master           planner_reltuples = 750
merchant_pos_daily_base   planner_reltuples = 135000
...
```

and `pg_stats` entries existed for most important tables. [export reference: filecite | turn66file0 | L39-L50]

So I no longer think “the tables were completely unanalyzed” is likely to be the primary explanation.

ANALYZE correctly refreshed the visible statistics counters afterward, but the underlying cardinality estimates were already pretty reasonable for the physical tables. [export reference: filecite | turn66file0 | L189-L200]

The **bad estimate is at the function boundary**, not principally the physical tables.

That's a much more important finding.

## And the DBeaver question is now unavoidable

This test gets us exactly where you wanted to go.

We have now established:

```text
CURRENT environment
PostgreSQL 17.9
D: data directory
psql
750 merchants
135k rows

POS31 = 7:06
Blueprint = 6:34
```

If you remember the original DBeaver scripts doing this materially faster, we should now perform the cleanest possible experiment:

> Run the same 750 benchmark query in **DBeaver against `msbf_bench750_r4_...` on port 55432**.

Not the historical database.

Not another population.

Not regenerated data.

Same exact disposable database, same exact PostgreSQL server, same exact D: storage, same functions, same 750 rows.

Then:

```text
psql vs DBeaver
```

is literally the only major variable left at the client/session level.

However, before doing that, I want the currently running **A2 after-ANALYZE POS31** to finish. That gives us another very valuable controlled result.

If A2 is still approximately 7 minutes, my current working diagnosis would become:

> **Campaign Scale is exposing an inefficient PostgreSQL physical execution design around M1.4 SQL set-returning functions, function cardinality estimation, temp materialization/spilling, and possibly HDD/session resource configuration. The 2,500 population magnifies it severely, but did not create it.**

And that is materially different from where we were a few hours ago.

Your proposed 750 test was exactly the right challenge. It has already disproven the simplistic “3.33× more data explains this” theory.
<!-- END_SOURCE_MESSAGE -->


<a id="m-23ebc16e-4944-4b0e-af2d-6240514e9c89"></a>
## Andrew / user · C132-M00254

C132-M00254 · 2026-09-13T18:50:50.148000-04:00 · active path

Preceding visible parent: [C132-M00253](part-11.md#m-9246938c-255d-46db-a523-e0da371ec8ae)

**Editorial record note:** Attachment references: Pasted text(20260913-224911).txt; BENCHMARK_SUMMARY.txt

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-ce75b178-2b8b-404c-a2ae-2228bf1b6361"></a>
## Assistant · C132-M00255

C132-M00255 · 2026-09-13T18:50:56.828130-04:00 · active path

Preceding visible parent: [C132-M00254](part-11.md#m-23ebc16e-4944-4b0e-af2d-6240514e9c89)

<!-- BEGIN_SOURCE_MESSAGE -->
We have a decisive result now. The 750 benchmark completed end-to-end, and **ANALYZE did not fix the problem**: POS31 actually moved from 7:06 to 8:23, while blueprint time stayed essentially flat at ~6:35. That rules out stale table statistics as the main cause.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3a1acff3-44e6-4793-94e9-f1ec39f23bd9"></a>
## Assistant · C132-M00256

C132-M00256 · 2026-09-13T18:50:56.828130-04:00 · active path

Preceding visible parent: [C132-M00255](part-11.md#m-ce75b178-2b8b-404c-a2ae-2228bf1b6361)

<!-- BEGIN_SOURCE_MESSAGE -->
We have a much firmer diagnosis now.

The 750 benchmark completed successfully, the reference database remained untouched, and all four benchmark phases completed. [export reference: filecite | turn67file1 | L1-L10]

| Test | Before ANALYZE | After ANALYZE | Effect |
|---|---:|---:|---:|
| POS31 deterministic reproduction | **7:06** | **8:23** | ~18% slower |
| M1.4 blueprint, 135k rows | **6:34.6** | **6:36.2** | essentially unchanged |
| 2,500 blueprint from R4 | **69.7 min** | — | ~10.6× slower than 750 |
| 2,500 POS31 from R4 | **>109.9 min unfinished** | — | >15.5× slower than 750 |

The first major conclusion is that **stale table statistics are not the primary cause**. ANALYZE populated the table statistics correctly—135,000 live POS rows, 750 merchant rows, etc.—but the runtime did not improve. POS31 actually got slower and blueprint execution stayed virtually identical. [export reference: filecite | turn67file0 | L189-L200] [export reference: filecite | turn67file0 | L217-L261] [export reference: filecite | turn67file0 | L277-L301]

The second major conclusion is even more important: **your original objection was correct. This is not simply a 750-versus-2,500 problem.** The current stack is already unacceptably slow at the original 750 population. Producing only 135,000 deterministic POS rows takes roughly 6½ minutes in the current environment. [export reference: filecite | turn67file0 | L127-L150]

There is then an additional nonlinear scaling problem from 750 to 2,500. A 3.33× increase in population produced approximately a 10.6× increase in blueprint runtime and more than a 15.5× increase in POS31 runtime. So we're looking at **two layers of inefficiency**:

```text
Current environment / execution path is already slow at 750
                         +
M1.4 becomes disproportionately worse as population increases
```

### The strongest technical clue

ANALYZE did **nothing** to this:

```text
Function Scan on m1_4_expected_pos_snapshot
estimated rows = 1,000
actual rows    = 135,000

Function Scan on m1_4_actual_pos_snapshot
estimated rows = 1,000
actual rows    = 135,000
```

The exact same 1,000-row estimate remained after ANALYZE. [export reference: filecite | turn67file0 | L236-L247]

That's because the problem is at the **set-returning function boundary**, not the underlying table statistics. PostgreSQL is planning as though these functions return about 1,000 rows when they actually return 135,000. At 2,500, the actual result becomes 450,000 while that function estimate can remain around 1,000.

That's a 135× estimation error at 750 and potentially a ~450× error at 2,500.

That is now one of my leading explanations for the nonlinear cliff.

### The other major clue: temp-disk spilling

At 750, POS31 has:

```text
work_mem = 4 MB
```

[export reference: filecite | turn67file0 | L27-L30]

Both sides spill their sorts to disk:

```text
expected sort:
external merge
13,504 KB disk

actual sort:
external sort
14,016 KB disk
```

and the entire POS31 execution incurred:

```text
temp read    = 36,116 × 8 KB ≈ 282 MB
temp written = 36,136 × 8 KB ≈ 282 MB
```

So roughly **half a gigabyte of aggregate temp I/O** just for this 135k-row validation. [export reference: filecite | turn67file0 | L217-L247]

The blueprint itself is even more revealing:

```text
temp read    = 32,375 × 8 KB ≈ 253 MB
temp written = 32,375 × 8 KB ≈ 253 MB
```

That is another ~506 MB of aggregate temp I/O merely to produce 135,000 rows. [export reference: filecite | turn67file0 | L277-L292]

And all of that is happening on the D:-resident HDD cluster.

So I now think the likely mechanism is some combination of:

1. **M1.4 functions being opaque to the planner**, causing gross cardinality underestimation.
2. **Only 4 MB `work_mem`**, causing substantial sort/materialization spill.
3. **D: HDD temp/data I/O**, magnifying those spills.
4. The M1.4 blueprint's inherently expensive deterministic calculations and self-join.
5. The same blueprint being regenerated repeatedly by validation.
6. Those effects becoming nonlinear as 135k becomes 450k.

Notice what's *not* high on my list anymore: ANALYZE.

### Now we answer your DBeaver question directly

We still have **not proven that DBeaver itself is faster**.

What we've proven is:

> The current PostgreSQL/D:-cluster/psql execution path is slow even at 750.

The cleanest next experiment is therefore exactly what you originally proposed, but now we have the perfect subject:

```text
Database:
msbf_bench750_r4_20260913t215311z

Server:
127.0.0.1

Port:
55432

Same 750 population
Same 135,000 rows
Same exact helper functions
Same PostgreSQL 17.9
Same D: cluster
```

Open **DBeaver**, connect to that exact database, and execute the exact benchmark `03_PHASE_A_POS31.sql` and `04_PHASE_B_BLUEPRINT.sql`.

That gives us:

```text
psql      POS31 = 7:06
DBeaver   POS31 = ?

psql      blueprint = 6:35
DBeaver   blueprint = ?
```

This is now a near-perfect A/B test.

If DBeaver also takes ~6–8 minutes, then **DBeaver itself is exonerated**. The difference between your historical fast executions and today is PostgreSQL configuration/storage/query execution—not the SQL client.

If DBeaver suddenly executes these in seconds or a minute or two, then we immediately compare DBeaver's effective session settings against psql. That would be an exceptionally useful finding.

### One experiment I want immediately after DBeaver

Regardless of the DBeaver result, I also want to rerun this same disposable 750 clone with:

```sql
SET work_mem = '64MB';
SET jit = off;
```

Those are particularly interesting because later MSBF Module 1 programs explicitly adopted settings in that neighborhood along with performance-oriented materialization. We now have physical evidence suggesting why.

If changing only those session settings takes:

```text
POS31:     7:06 → e.g. 1:30
blueprint: 6:35 → e.g. 1:00
```

we'll know a substantial portion of Campaign Scale's problem is environmental/session configuration rather than business logic.

And after that, I want to expose the **internal execution plan of `m1_4_daily_pos_blueprint()`**. Right now PostgreSQL's outer plan just tells us:

```text
Function Scan
actual rows = 135000
Execution Time = 396 seconds
```

It doesn't tell us which internal CTE/join/calculation consumed those 396 seconds. [export reference: filecite | turn67file0 | L277-L290]

That internal plan is where I suspect we'll find the true hotspot.

So, at this point I would **not resume the 2,500 campaign**. We have sufficient evidence that there is a real performance defect/inefficiency to characterize first. Continuing 68 stages under these conditions would waste hours and obscure the engineering problem.

The 750 experiment was absolutely worth doing. It has already eliminated the simplistic scaling explanation and narrowed the problem substantially.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a63a7d49-4673-4356-ba99-3ed2f46559e6"></a>
## Andrew / user · C132-M00257

C132-M00257 · 2026-09-13T18:55:42.803000-04:00 · active path

Preceding visible parent: [C132-M00256](part-11.md#m-3a1acff3-44e6-4793-94e9-f1ec39f23bd9)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: d8750954-e663-420f-8e42-53082e30e75f.png

<!-- BEGIN_SOURCE_MESSAGE -->
i see: how to get dbeaver to see Database: msbf_bench750_r4_20260913t215311z  
<!-- END_SOURCE_MESSAGE -->


<a id="m-32c56c44-6ca5-48b4-b4d8-11f3685b48d8"></a>
## Assistant · C132-M00258

C132-M00258 · 2026-09-13T18:55:47.006192-04:00 · active path

Preceding visible parent: [C132-M00257](part-11.md#m-a63a7d49-4673-4356-ba99-3ed2f46559e6)

<!-- BEGIN_SOURCE_MESSAGE -->
Yes. Your screenshot shows DBeaver connected to **`localhost:5432`**, while our benchmark database is on the separate Campaign Scale PostgreSQL instance at **`127.0.0.1:55432`**. That's why it doesn't appear in that database list.

Create a **second PostgreSQL connection** in DBeaver:

1. **Database → New Database Connection → PostgreSQL**
2. Enter:
   - **Host:** `127.0.0.1`
   - **Port:** `55432`
   - **Database:** `msbf_bench750_r4_20260913t215311z`
   - **Username:** `postgres`
   - **Password:** your normal PostgreSQL password
3. Click **Test Connection**.
4. If successful, click **Finish**.

I recommend naming the connection something unmistakable like:

```text
MSBF Campaign Scale Benchmark - 55432
```

Do **not** modify your existing `metro2_lab localhost:5432` connection. We specifically want DBeaver connected to **55432**, because that preserves every server/storage/database variable from the psql benchmark.

Once you see:

```text
MSBF Campaign Scale Benchmark - 55432
    └── msbf_bench750_r4_20260913t215311z
```

stop there and tell me. I'll give you the **single exact DBeaver benchmark script** to run so we're comparing apples-to-apples with the 7:06 POS31 / 6:35 blueprint measurements.
<!-- END_SOURCE_MESSAGE -->


<a id="m-be8678d5-ee9d-44db-8506-5ffacf84549a"></a>
## Andrew / user · C132-M00259

C132-M00259 · 2026-09-13T18:58:11.788000-04:00 · active path

Preceding visible parent: [C132-M00258](part-11.md#m-32c56c44-6ca5-48b4-b4d8-11f3685b48d8)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 1aa4f7f9-87e4-4cbd-a1c5-5cf37879baca.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-4ee996fd-e55b-449c-bc89-15224a2e9dd2"></a>
## Assistant · C132-M00260

C132-M00260 · 2026-09-13T18:58:16.177997-04:00 · active path

Preceding visible parent: [C132-M00259](part-11.md#m-be8678d5-ee9d-44db-8506-5ffacf84549a)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. That is exactly the connection we want:

```text
Database: msbf_bench750_r4_20260913t215311z
Host:     127.0.0.1
Port:     55432
```

Now we can perform the **true DBeaver-vs-psql A/B test**.

Open a **new SQL Editor specifically on this connection/database** and run this first:

```sql
SELECT
    current_database() AS database_name,
    inet_server_addr() AS server_address,
    inet_server_port() AS server_port,
    current_setting('work_mem') AS work_mem,
    current_setting('jit') AS jit,
    current_setting('max_parallel_workers_per_gather') AS max_parallel_workers_per_gather;
```

We want it to confirm:

```text
database_name = msbf_bench750_r4_20260913t215311z
server_port   = 55432
work_mem      = 4MB
jit           = on
max_parallel_workers_per_gather = 2
```

Then we'll run **the exact POS31 workload from the psql benchmark unchanged** in DBeaver and time it.

Importantly, don't change DBeaver preferences, `work_mem`, JIT, parallelism, autocommit, or anything else yet. We want to see how your ordinary DBeaver session behaves **as-is** against the exact database where psql measured:

```text
POS31:     7:06 before ANALYZE / 8:23 after
Blueprint: 6:35
```

Once you paste the six values from that small query, I'll give you the exact DBeaver POS31 benchmark statement.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e645946c-c21c-4bbe-94a3-5fe59cd84798"></a>
## Andrew / user · C132-M00261

C132-M00261 · 2026-09-13T18:59:23.209000-04:00 · active path

Preceding visible parent: [C132-M00260](part-11.md#m-4ee996fd-e55b-449c-bc89-15224a2e9dd2)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: af858e14-0eef-41ba-b106-d417548953a1.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-85ec8aa6-8433-4107-afce-976715901a82"></a>
## Assistant · C132-M00262

C132-M00262 · 2026-09-13T18:59:29.044078-04:00 · active path

Preceding visible parent: [C132-M00261](part-11.md#m-e645946c-c21c-4bbe-94a3-5fe59cd84798)

<!-- BEGIN_SOURCE_MESSAGE -->
Perfect. The DBeaver session is matched to the psql benchmark environment:

```text
Database:                        msbf_bench750_r4_20260913t215311z
Server:                          127.0.0.1
Port:                            55432
work_mem:                        4MB
jit:                             on
max_parallel_workers_per_gather: 2
```

So now run this **exact POS31 benchmark in DBeaver**, unchanged:

```sql
SET statement_timeout = '10min';
SET lock_timeout = '10s';

SELECT
    'DBEAVER_POS31_BEGIN' AS marker,
    clock_timestamp() AS observed_at;

EXPLAIN (ANALYZE, BUFFERS, WAL, SETTINGS, SUMMARY, TIMING OFF)
SELECT COUNT(*) AS mismatches
FROM msbf_m1.m1_4_expected_pos_snapshot(
       (
           SELECT run_id
           FROM msbf_ctl.run_registry
           WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
             AND run_version = 1
       )
     ) e
FULL JOIN msbf_m1.m1_4_actual_pos_snapshot(
       (
           SELECT run_id
           FROM msbf_ctl.run_registry
           WHERE run_code = 'M1_V0_2_BASELINE_BUILD'
             AND run_version = 1
       )
     ) a
USING (entity_key)
WHERE e.row_hash IS DISTINCT FROM a.row_hash;

SELECT
    'DBEAVER_POS31_END' AS marker,
    clock_timestamp() AS observed_at;
```

Use normal **Execute SQL Script** in DBeaver.

Do **not** change any settings first.

The comparison target is the same database after ANALYZE:

```text
psql POS31:
8 minutes 23.4 seconds
```

So the outcome will be highly informative:

- **DBeaver ≈ 7–9 minutes:** DBeaver itself is not the reason your historical runs were faster.
- **DBeaver dramatically faster, e.g. seconds/1–2 minutes:** we have proven a client/session execution difference worth isolating immediately.
- **DBeaver also very slow:** the historical-vs-current difference lies elsewhere—most likely database/storage/configuration or a materially different historical execution context.

You don't need to press anything while it runs. When it finishes, send me the query plan/output and elapsed time.
<!-- END_SOURCE_MESSAGE -->


<a id="m-0598e0a7-a78d-40a3-bf43-1626e06fb6f7"></a>
## Andrew / user · C132-M00263

C132-M00263 · 2026-09-13T19:12:11.351000-04:00 · active path

Preceding visible parent: [C132-M00262](part-11.md#m-85ec8aa6-8433-4107-afce-976715901a82)

**Editorial record note:** 4 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 07d98590-83f0-427e-a2ae-dc378f3bc938.png; f89a1e22-111b-4e40-9240-bab57208768e.png; f11cb9f3-3d2d-4e18-ad89-ce51313c3319.png; c3667993-25c9-44a7-b898-126faee7a878.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-f4a3517f-9167-48d2-aff0-180b5d22b16b"></a>
## Assistant · C132-M00264

C132-M00264 · 2026-09-13T19:12:13.616511-04:00 · active path

Preceding visible parent: [C132-M00263](part-11.md#m-0598e0a7-a78d-40a3-bf43-1626e06fb6f7)

<!-- BEGIN_SOURCE_MESSAGE -->
This is an excellent result because it eliminates a major branch of the investigation.

## DBeaver is not the explanation

Your DBeaver execution took:

- **DBeaver Statistics:** 6m 18s
- PostgreSQL `Execution Time`: **378,429 ms = 6m 18.4s**
- Start/end timestamps: approximately **19:00:08 → 19:06:27**

Compare that with our `psql` runs on the exact same database:

| Execution | POS31 |
|---|---:|
| psql, before ANALYZE | 7m 06s |
| psql, after ANALYZE | 8m 23s |
| **DBeaver, after ANALYZE** | **6m 18s** |

DBeaver was somewhat faster, but **not remotely enough to explain your historical experience**. We're talking minutes versus minutes—not historical seconds/low minutes versus today's hours.

Even better, DBeaver produced essentially the **same execution plan**:

```text
Merge Full Join
135,000 rows compared

Expected:
estimated 1,000
actual 135,000
external merge
13,504 KB disk

Actual:
estimated 1,000
actual 135,000
external sort
14,016 KB disk

temp read=36,116
temp written=36,136
```

So:

> **DBeaver does not have some hidden fast/parallel execution mechanism that Campaign Scale failed to reproduce.**

That hypothesis is now effectively closed.

## This points us back toward the PostgreSQL environment

We've held constant:

```text
same computer
same PostgreSQL server process
same PostgreSQL 17.9
same database
same 750 population
same 135,000 rows
same published functions
same SQL
same work_mem
same JIT setting
same parallel setting
same D: storage
```

and changed only:

```text
psql ↔ DBeaver
```

Result:

```text
psql:    ~7–8 minutes
DBeaver: ~6 minutes
```

That's close enough that the **client isn't our material problem**.

That leaves the really interesting historical comparison:

```text
ORIGINAL ENVIRONMENT
DBeaver
localhost:5432
msbf_strategy
750 population
apparently fast

versus

CURRENT ENVIRONMENT
DBeaver
127.0.0.1:55432
D:-resident Campaign Scale cluster
750 population
~6 minutes
```

And your screenshot from earlier is valuable because we know that your original DBeaver environment still exists:

```text
metro2_lab localhost:5432
    ...
    msbf_strategy
```

### I think our next A/B test is obvious

We should **stop testing clients**.

We should compare the two PostgreSQL environments:

```text
OLD / ORIGINAL
localhost:5432
msbf_strategy

CURRENT
127.0.0.1:55432
msbf_bench750_r4_...
```

Specifically:

**server settings, data-directory/storage location, effective PostgreSQL configuration, and the same M1.4 workload where possible.**

The first thing I want to know is where the old `5432` server's data directory lives and what its relevant performance settings are.

If we discover:

```text
Original 5432:
data_directory = C:\...\SSD...
work_mem = 64MB
jit = off
effective_io_concurrency = ...
...
```

versus:

```text
Campaign 55432:
data_directory = D:\...\HDD
work_mem = 4MB
jit = on
effective_io_concurrency = 0
...
```

then suddenly your historical experience makes considerably more sense.

## But we already know one current inefficiency is real

Irrespective of the old environment, **4 MB `work_mem` is causing disk spills at only 135,000 rows**.

DBeaver confirmed it independently.

Both 135k-row sides of POS31 are being externally sorted to disk, and the operation performs roughly:

```text
~282 MB temp reads
~282 MB temp writes
```

That is not desirable for a routine 135k-row validation workload.

And the blueprint itself generates another ~500 MB aggregate temp I/O.

At 450k rows on an HDD, that can become very expensive.

So I would now run **two controlled tests**, but we can do them efficiently rather than another sprawling diagnostic campaign:

1. **Compare original 5432 vs current 55432 environment settings/storage.**
2. On our disposable 750 clone, rerun POS31 and blueprint with the later-MSBF-style session configuration:

```sql
SET work_mem = '64MB';
SET jit = off;
```

No business logic changes. No SQL calculation changes. No control changes. Just execution configuration.

That second test could be extremely revealing. If the 6:18 DBeaver POS31 suddenly becomes, say, 1–2 minutes, we have identified a major piece of the solution immediately.

And because this is a disposable benchmark clone, there is no risk to the accepted reference or campaign qualification.

**I would do the old-vs-new environment comparison first**, because it may tell us exactly which settings your historically fast DBeaver environment was using rather than guessing at 64 MB/JIT. Then we'll reproduce those settings on the disposable clone and measure the effect.
<!-- END_SOURCE_MESSAGE -->


<a id="m-f9a1ef5d-51ba-478b-95d1-934ebccfed5b"></a>
## Andrew / user · C132-M00265

C132-M00265 · 2026-09-13T19:20:51.317000-04:00 · active path

Preceding visible parent: [C132-M00264](part-11.md#m-f4a3517f-9167-48d2-aff0-180b5d22b16b)

**Editorial record note:** 1 non-text part(s) referenced; image bytes are not included in this transcript. Attachment references: 6976005e-8fa8-4eb3-9e67-adf6680afa79.png

<!-- BEGIN_SOURCE_MESSAGE -->
[No text body in export; see attachment/non-text note above.]
<!-- END_SOURCE_MESSAGE -->


<a id="m-a79c4504-7a18-45d2-b89b-c28e69e67800"></a>
## Assistant · C132-M00266

C132-M00266 · 2026-09-13T19:20:53.256935-04:00 · active path

Preceding visible parent: [C132-M00265](part-11.md#m-f9a1ef5d-51ba-478b-95d1-934ebccfed5b)

<!-- BEGIN_SOURCE_MESSAGE -->
Excellent. That eliminates another major hypothesis.

Your original `msbf_strategy` environment on port **5432** shows the same key session settings:

```text
Original msbf_strategy        Current Campaign Scale
------------------------      -----------------------
work_mem = 4MB                work_mem = 4MB
jit = on                      jit = on
parallel/gather = 2           parallel/gather = 2
```

So the historical speed was **not because DBeaver gave the old database 64 MB work_mem, disabled JIT, or forced more parallelism**.

That leaves a much narrower set of material differences.

The most important one to check now is **physical storage and PostgreSQL server configuration**. Your current Campaign Scale server is definitely:

```text
D:\MSBF_CAMPAIGNS\pg_clusters\...
```

on the HDD. We need to determine where the original 5432 `msbf_strategy` server actually stores its data, plus a few server-level settings that can differ despite the session settings we just compared.

Run this **one query in DBeaver against the original `msbf_strategy` database on port 5432**:

```sql
SELECT
    current_database() AS database_name,
    inet_server_addr() AS server_address,
    inet_server_port() AS server_port,
    current_setting('data_directory') AS data_directory,
    current_setting('server_version') AS server_version,
    current_setting('shared_buffers') AS shared_buffers,
    current_setting('effective_cache_size') AS effective_cache_size,
    current_setting('effective_io_concurrency') AS effective_io_concurrency,
    current_setting('random_page_cost') AS random_page_cost,
    current_setting('seq_page_cost') AS seq_page_cost,
    current_setting('temp_tablespaces') AS temp_tablespaces,
    current_setting('max_parallel_workers') AS max_parallel_workers,
    current_setting('max_parallel_workers_per_gather') AS max_parallel_workers_per_gather,
    current_setting('work_mem') AS work_mem,
    current_setting('jit') AS jit;
```

This is the highest-value next check.

If `data_directory` comes back on **C:**, then we have a very significant experimental difference:

```text
Historical accepted development
750
DBeaver
PostgreSQL 17
C: SSD

versus

Current benchmark
750
DBeaver
PostgreSQL 17.9
D: HDD
```

Given that we have now physically observed **hundreds of MB of PostgreSQL temp I/O during a single 750 M1.4 evaluation**, SSD versus HDD could matter considerably.

If the old server is also on D:, then storage largely drops out and we continue narrowing.

Either way, we're making good progress: **DBeaver itself, parallelism, work_mem, JIT, and simple 750→2,500 scaling are no longer credible standalone explanations.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-48c3ea5d-b9ea-4831-9897-6cffd715b1d4"></a>
## Andrew / user · C132-M00267

C132-M00267 · 2026-09-13T19:22:53.398000-04:00 · active path

Preceding visible parent: [C132-M00266](part-11.md#m-a79c4504-7a18-45d2-b89b-c28e69e67800)

<!-- BEGIN_SOURCE_MESSAGE -->
msbf_strategy	127.0.0.1	5432	C:/Program Files/PostgreSQL/17/data	17.9	128MB	4GB	0	4	1		8	2	4MB	on
<!-- END_SOURCE_MESSAGE -->


<a id="m-107efd0e-6f92-4263-bed9-5978326840af"></a>
## Assistant · C132-M00268

C132-M00268 · 2026-09-13T19:22:57.539601-04:00 · active path

Preceding visible parent: [C132-M00267](part-11.md#m-48c3ea5d-b9ea-4831-9897-6cffd715b1d4)

<!-- BEGIN_SOURCE_MESSAGE -->
That is a **very important result**. The old and current PostgreSQL environments are essentially identical on the settings we checked.

The comparison is now:

| Setting | Original `msbf_strategy` | Campaign Scale |
|---|---:|---:|
| PostgreSQL | 17.9 | 17.9 |
| `work_mem` | 4 MB | 4 MB |
| JIT | on | on |
| parallel workers | 8 | 8 |
| workers/gather | 2 | 2 |
| `shared_buffers` | 128 MB | 128 MB |
| `effective_cache_size` | 4 GB | 4 GB |
| `effective_io_concurrency` | 0 | 0 |
| `random_page_cost` | 4 | 4 |
| `seq_page_cost` | 1 | 1 |
| **data directory** | **C: SSD** | **D: HDD** |

So the major known environmental difference is now:

> **Original execution: PostgreSQL data + temp I/O on the C: SSD.  
> Campaign Scale: PostgreSQL data + temp I/O on the D: HDD.**

And that matters much more than I initially gave it credit for because our 750 execution plan proved that M1.4 is **extremely temp-I/O intensive**.

At only 750 merchants, POS31 did roughly:

```text
~282 MB temp reads
~282 MB temp writes
```

and the blueprint itself did roughly:

```text
~253 MB temp reads
~253 MB temp writes
```

So a single validation/generation sequence is pushing on the order of **~1 GB of aggregate PostgreSQL temp I/O**, despite the final table only being 135,000 rows. [export reference: filecite | turn67file0 | L217-L247] [export reference: filecite | turn67file0 | L277-L292]

That is exactly the kind of workload where an SSD/HDD difference can become enormous, especially because it is not necessarily one clean sequential read/write. Sort runs, temp files, repeated materialization, and merge operations create latency-sensitive filesystem activity.

## We now have a very strong hypothesis

The likely chain is:

```text
Published M1.4 physical execution
        ↓
4 MB work_mem
        ↓
large intermediate sets spill to temp
        ↓
original environment:
temp/data files on SSD → tolerable

Campaign Scale environment:
temp/data files on HDD → painfully slow
        ↓
2,500 amplifies the same problem dramatically
```

That would reconcile something that previously seemed impossible:

> “How can the same 750 code I remember running quickly now take 6–8 minutes?”

Because we're no longer running the same **physical execution environment**, even though we're running the same logical SQL.

### And then 2,500 makes it worse nonlinearly

This still doesn't mean HDD explains **everything**.

The function cardinality problem remains real:

```text
estimated = 1,000
actual at 750 = 135,000
actual at 2,500 = 450,000
```

and the repeated blueprint recomputation remains real.

So I now suspect:

```text
HDD instead of SSD
      +
very low work_mem for these intermediate sets
      +
set-returning-function/cardinality blindness
      +
repeated blueprint computation
      =
current extreme runtime
```

The HDD could be the **big reason the original 750 felt fast while today's 750 feels slow**, while the query architecture explains why going from 750 to 2,500 gets disproportionately worse.

## We can now prove the SSD hypothesis directly

And we do not need to build anything complicated.

The next experiment should be the **same POS31 workload against the original `msbf_strategy` database on port 5432**, using DBeaver.

First, run this quick guard query there:

```sql
SELECT
    r.run_id,
    r.population_id,
    (SELECT COUNT(*)
       FROM msbf_m1.merchant_master m
      WHERE m.population_id = r.population_id) AS merchants,
    (SELECT COUNT(*)
       FROM msbf_m1.merchant_pos_daily_base p
      WHERE p.generated_by_run_id = r.run_id) AS pos_rows,
    to_regprocedure('msbf_m1.m1_4_expected_pos_snapshot(bigint)') AS expected_function,
    to_regprocedure('msbf_m1.m1_4_actual_pos_snapshot(bigint)') AS actual_function
FROM msbf_ctl.run_registry r
WHERE r.run_code = 'M1_V0_2_BASELINE_BUILD'
  AND r.run_version = 1;
```

Ideally it returns:

```text
merchants = 750
pos_rows  = 135000
expected_function = m1_4_expected_pos_snapshot(bigint)
actual_function   = m1_4_actual_pos_snapshot(bigint)
```

If it does, we have the best benchmark yet:

```text
SAME:
PostgreSQL 17.9
DBeaver
same settings
same M1.4 functions
750 merchants
135k POS rows

DIFFERENT:
C: SSD vs D: HDD
```

Then run the exact POS31 benchmark there.

If the C:-resident `msbf_strategy` does it in, say:

```text
30 sec
60 sec
2 min
```

while the D:-resident clone takes **6:18–8:23**, we'll have direct physical evidence that **moving Campaign Scale PostgreSQL to the HDD created a major performance regression**.

At that point I would seriously reconsider our storage architecture. We moved the campaign database to D: because C: only had about 5.5 GB free, which was sensible for capacity. But the right architecture may instead be something like:

```text
C: SSD
    PostgreSQL working/temp-heavy execution

D: HDD
    large retained artifacts
    archives
    backups
    exports
    return packages
```

or another arrangement that gives PostgreSQL fast working storage without consuming C: irresponsibly.

We're now very close to proving whether that is the dominant historical difference.
<!-- END_SOURCE_MESSAGE -->
