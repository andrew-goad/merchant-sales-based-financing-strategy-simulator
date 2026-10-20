# MSBF - Campaign Scale 750 - 2,500 - 25,000 Part 2

Part 05 · [Conversation index](README.md) · [History home](../../README.md)

> Historical dialogue: commands and approvals below describe past events. They are not current execution or publication instructions. Attachment references do not establish recovered bytes.

[Previous part](part-04.md)
[Next part](part-06.md)

<a id="m-8e3fc7ba-a3e3-451a-89d0-206f1bb1b6d6"></a>
## Assistant · C132-M00073

C132-M00073 · 2026-09-12T17:20:07.659573-04:00 · active path

Preceding visible parent: [C132-M00072](part-04.md#m-12c2942c-9c9b-4655-be41-0fa21b0ccd12)

<!-- BEGIN_SOURCE_MESSAGE -->
This narrows it down considerably. **PID 5064 is alive, but it is not currently talking to PostgreSQL and has no child process.** That means it is either doing Python-side file/hash/comparison/packaging work, waiting on disk I/O, or genuinely wedged inside Python.

Also, my previous CPU test had a flaw: `$p1` was a live process object, so its CPU value could update before subtraction. The raw values you saw went from `777.734375` to `777.84375`, which is actually about **0.109 seconds of CPU in 30 seconds**—very little activity, but not absolute zero.

Before interrupting it, run this more reliable diagnostic. It snapshots numeric CPU and Windows I/O counters, then checks exactly what phase evidence exists.

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$PidToWatch = 5064
$RunRoot = 'D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc'

function Get-HybridSnapshot {
    $p = Get-Process -Id $PidToWatch -ErrorAction Stop
    $c = Get-CimInstance Win32_Process -Filter "ProcessId=$PidToWatch"

    [pscustomobject]@{
        Time             = Get-Date
        PID              = $PidToWatch
        CPUSeconds       = [double]$p.CPU
        WorkingMB        = [math]::Round($p.WorkingSet64 / 1MB, 1)
        ReadOps          = [uint64]$c.ReadOperationCount
        WriteOps         = [uint64]$c.WriteOperationCount
        ReadMB           = [math]::Round(([uint64]$c.ReadTransferCount) / 1MB, 2)
        WrittenMB        = [math]::Round(([uint64]$c.WriteTransferCount) / 1MB, 2)
    }
}

Write-Host "`n=== SNAPSHOT 1 ==="
$a = Get-HybridSnapshot
$a | Format-List

Start-Sleep -Seconds 30

Write-Host "`n=== SNAPSHOT 2 ==="
$b = Get-HybridSnapshot
$b | Format-List

Write-Host "`n=== 30-SECOND DELTAS ==="
[pscustomobject]@{
    CPUSecondsDelta = [math]::Round($b.CPUSeconds - $a.CPUSeconds, 3)
    ReadOpsDelta    = $b.ReadOps - $a.ReadOps
    WriteOpsDelta   = $b.WriteOps - $a.WriteOps
    ReadMBDelta     = [math]::Round($b.ReadMB - $a.ReadMB, 2)
    WrittenMBDelta  = [math]::Round($b.WrittenMB - $a.WrittenMB, 2)
} | Format-List

Write-Host "`n=== PHASE / EVIDENCE FILES ==="
@(
    'evidence\PACKAGE_BINDING.json',
    'evidence\BEFORE_source_binding.json',
    'evidence\BEFORE_reference_binding.json',
    'evidence\STORAGE_PREFLIGHT.json',
    'evidence\REFERENCE_SNAPSHOT_BEFORE.json',
    'evidence\SUBJECT_CREATION.json',
    'evidence\NO_OUTPUT_HYDRATION.json',
    'evidence\CERTIFIED_INPUT_ROUNDTRIP.json',
    'evidence\BOUNDARY_CONTROLS.json',
    'evidence\STAGES.json',
    'evidence\WAVE_A_RESULT.json',
    'evidence\G3_RESULT.json',
    'evidence\CERTIFICATION_COMPARISON.json',
    'evidence\AFTER_reference_binding.json',
    'evidence\REFERENCE_NONMUTATION_OBSERVATION.json',
    'CAMPAIGN_SUMMARY.json',
    'RUN_RECEIPT.json',
    'RETURN_MANIFEST.csv',
    'RETURN_SHA256SUMS.txt'
) | ForEach-Object {
    $p = Join-Path $RunRoot $_
    [pscustomobject]@{
        Exists = Test-Path -LiteralPath $p
        Bytes  = if (Test-Path -LiteralPath $p) { (Get-Item $p).Length } else { $null }
        File   = $_
    }
} | Format-Table -AutoSize

Write-Host "`n=== LAST 10 COMPLETED NATIVE COMMAND RECEIPTS ==="
Get-ChildItem "$RunRoot\logs\*.process.json" -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object -Last 10 |
    ForEach-Object {
        $j = Get-Content $_.FullName -Raw | ConvertFrom-Json
        [pscustomobject]@{
            Receipt = $_.Name
            Label   = $j.label
            Exit    = $j.exit_code
            Seconds = $j.elapsed_seconds
        }
    } | Format-Table -AutoSize

Write-Host "`n=== RETURN ZIP STATUS ==="
Get-ChildItem 'D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_*_RETURN.zip' `
    -ErrorAction SilentlyContinue |
    Select-Object Length, CreationTime, LastWriteTime, FullName |
    Format-List
```

This will tell us exactly where it stopped progressing.

### How to read it

If **I/O counters are increasing materially**, particularly `ReadMBDelta` or `WrittenMBDelta`, leave it alone. It is probably hashing, comparing, or packaging against the HDD.

If `CERTIFICATION_COMPARISON.json` and `CAMPAIGN_SUMMARY.json` exist and a `_RETURN.zip` is growing, it is in the final packaging stage. Definitely let that finish.

If `REFERENCE_SNAPSHOT_BEFORE.json` exists but `SUBJECT_CREATION.json` does not, it has not begun the subject replay yet.

If `SUBJECT_CREATION.json` and `BOUNDARY_CONTROLS.json` exist, it successfully crossed into the isolated subject.

If `STAGES.json`, `WAVE_A_RESULT.json`, or `G3_RESULT.json` exist, we can tell precisely how far downstream it got.

If **CPU delta is near zero, all I/O deltas are zero, no child process exists, no PostgreSQL session exists, and the same phase files remain unchanged**, then I would classify PID 5064 as likely hung and we can make a controlled decision about interrupting it.

One other important point: the `LastWriteTime` values you showed are **not reliable as runtime-progress timestamps** for `source_snapshot`. The runner uses `shutil.copy2()`, which deliberately preserves the source file modification times. So those apparent `7:50 PM` timestamps do not mean the runtime was actively writing then. That explains the odd timestamp mismatch we were seeing.

**Do not Ctrl+C yet. Paste the output of this block.** It should let us identify the exact phase and whether the HDD is still doing useful work.
<!-- END_SOURCE_MESSAGE -->


<a id="m-bf0a047d-1925-46c0-bd6e-a9c1010282bd"></a>
## Andrew / user · C132-M00074

C132-M00074 · 2026-09-12T17:22:57.558000-04:00 · active path

Preceding visible parent: [C132-M00073](part-05.md#m-8e3fc7ba-a3e3-451a-89d0-206f1bb1b6d6)

<!-- BEGIN_SOURCE_MESSAGE -->
=== SNAPSHOT 1 ===

Time       : 9/12/2026 5:22:09 PM
PID        : 5064
CPUSeconds : 778.765625
WorkingMB  : 51.6
ReadOps    : 16639322
WriteOps   : 5827224
ReadMB     : 57236.07
WrittenMB  : 23361.06


=== SNAPSHOT 2 ===

Time       : 9/12/2026 5:22:39 PM
PID        : 5064
CPUSeconds : 778.828125
WorkingMB  : 51.6
ReadOps    : 16642102
WriteOps   : 5827224
ReadMB     : 57246.93
WrittenMB  : 23361.06


=== 30-SECOND DELTAS ===

CPUSecondsDelta : 0.062
ReadOpsDelta    : 2780
WriteOpsDelta   : 0
ReadMBDelta     : 10.86
WrittenMBDelta  : 0


=== PHASE / EVIDENCE FILES ===

Exists Bytes File
------ ----- ----
  True  2182 evidence\PACKAGE_BINDING.json
  True   659 evidence\BEFORE_source_binding.json
  True   559 evidence\BEFORE_reference_binding.json
  True   281 evidence\STORAGE_PREFLIGHT.json
  True 48515 evidence\REFERENCE_SNAPSHOT_BEFORE.json
  True   438 evidence\SUBJECT_CREATION.json
  True 12865 evidence\NO_OUTPUT_HYDRATION.json
 False       evidence\CERTIFIED_INPUT_ROUNDTRIP.json
 False       evidence\BOUNDARY_CONTROLS.json
 False       evidence\STAGES.json
 False       evidence\WAVE_A_RESULT.json
 False       evidence\G3_RESULT.json
 False       evidence\CERTIFICATION_COMPARISON.json
 False       evidence\AFTER_reference_binding.json
 False       evidence\REFERENCE_NONMUTATION_OBSERVATION.json
 False       CAMPAIGN_SUMMARY.json
 False       RUN_RECEIPT.json
 False       RETURN_MANIFEST.csv
 False       RETURN_SHA256SUMS.txt


=== LAST 10 COMPLETED NATIVE COMMAND RECEIPTS ===

Receipt                                     Label                    Exit Seconds
-------                                     -----                    ---- -------
00022_read_only_snapshot.process.json       read_only_snapshot          0  217.58
00023_read_scalar.process.json              read_scalar                 0    0.42
00024_read_scalar.process.json              read_scalar                 0    0.22
00025_create_new_subject.process.json       create_new_subject          0    2.49
00026_read_scalar.process.json              read_scalar                 0    0.33
00027_install_schema_pre_data.process.json  install_schema_pre_data     0    2.42
00028_load_certified_inputs.process.json    load_certified_inputs       0  325.89
00029_install_schema_post_data.process.json install_schema_post_data    0   34.90
00030_read_scalar.process.json              read_scalar                 0    0.65
00031_read_only_snapshot.process.json       read_only_snapshot          0  185.68


=== RETURN ZIP STATUS ===
<!-- END_SOURCE_MESSAGE -->


<a id="m-53ea238d-ab18-4a18-ace5-a682b624e7db"></a>
## Assistant · C132-M00075

C132-M00075 · 2026-09-12T17:23:02.847812-04:00 · active path

Preceding visible parent: [C132-M00074](part-05.md#m-bf0a047d-1925-46c0-bd6e-a9c1010282bd)

<!-- BEGIN_SOURCE_MESSAGE -->
This looks **active, not hung**. The process read another ~10.9 MB in 30 seconds, and it has already created the subject, loaded certified inputs, installed post-data schema, and taken the post-load snapshot. I’m checking the runner sequence now so I can tell you exactly what it is doing next and whether that phase is expected to be read-heavy and write-light.
<!-- END_SOURCE_MESSAGE -->


<a id="m-89c5a90d-ab7b-4c6f-bbe8-5cf86f613cc5"></a>
## Assistant · C132-M00076

C132-M00076 · 2026-09-12T17:23:23.328318-04:00 · active path

Preceding visible parent: [C132-M00075](part-05.md#m-53ea238d-ab18-4a18-ace5-a682b624e7db)

<!-- BEGIN_SOURCE_MESSAGE -->
This is **still running and appears to be doing useful work**, not hung.

The strongest evidence is the 30-second I/O delta:

```text
ReadOpsDelta   = 2,780
ReadMBDelta    = 10.86 MB
WriteOpsDelta  = 0
CPUSecondsDelta ≈ 0.06
```

That pattern is exactly what I would expect from the current phase: **Python is reading the exported reference and subject input files and comparing them**, not issuing SQL.

The runtime sequence confirms where you are:

```text
subject created                         PASS
certified inputs loaded                 PASS
post-data schema installed              PASS
post-load read-only snapshot            PASS
NO_OUTPUT_HYDRATION                     PASS

CURRENT STEP:
CERTIFIED INPUT ROUNDTRIP COMPARISON
```

The next evidence file is:

```text
evidence\CERTIFIED_INPUT_ROUNDTRIP.json
```

and it does not get written until **all imported input relations have finished exact comparison**.

The comparator is relatively expensive. For each relation it:

1. reads the reference CSV;
2. reads the subject CSV;
3. parses every row as JSON;
4. canonicalizes every field;
5. loads row representations into a temporary SQLite database;
6. checks multiplicities and keys;
7. calculates semantic hashes;
8. deletes the scratch SQLite file;
9. moves to the next relation.

So the combination of:

```text
low CPU
continuous reads
no PostgreSQL connection
no child process
no final evidence file yet
```

is normal for this particular phase, especially on the HDD.

### We can now monitor actual progress much better

Run this in the second PowerShell window:

```powershell
$RunRoot = 'D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc'

Write-Host "`n=== INPUT ROUNDTRIP PROGRESS ==="

$ReferenceDir = Join-Path $RunRoot 'reference_before\inputs'
$SubjectDir   = Join-Path $RunRoot 'subject_loaded_inputs'
$TempDir      = Join-Path $RunRoot 'temp'

$ReferenceFiles = @(
    Get-ChildItem $ReferenceDir -File -Filter '*.csv' -ErrorAction SilentlyContinue
)

$SubjectFiles = @(
    Get-ChildItem $SubjectDir -File -Filter '*.csv' -ErrorAction SilentlyContinue
)

[pscustomobject]@{
    ReferenceInputFiles = $ReferenceFiles.Count
    ReferenceInputGB    = [math]::Round(
        (($ReferenceFiles | Measure-Object Length -Sum).Sum / 1GB), 3
    )
    SubjectInputFiles   = $SubjectFiles.Count
    SubjectInputGB      = [math]::Round(
        (($SubjectFiles | Measure-Object Length -Sum).Sum / 1GB), 3
    )
    RoundtripReceipt    = Test-Path (
        Join-Path $RunRoot 'evidence\CERTIFIED_INPUT_ROUNDTRIP.json'
    )
} | Format-List

Write-Host "`n=== CURRENT COMPARATOR SCRATCH ==="

Get-ChildItem $TempDir -File -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object LastWriteTime, Length, Name |
    Format-Table -AutoSize

Write-Host "`n=== 10 LARGEST INPUT FILES ==="

$ReferenceFiles |
    Sort-Object Length -Descending |
    Select-Object -First 10 `
        @{N='GB';E={[math]::Round($_.Length / 1GB,3)}},
        Name |
    Format-Table -AutoSize
```

The **temp folder is especially useful**. The comparator uses scratch files named approximately:

```text
input_0.sqlite
input_1.sqlite
input_2.sqlite
...
```

Only one should generally exist at a time because it removes each scratch database after finishing that relation.

So if you see, for example:

```text
input_117.sqlite
```

we know it has reached approximately relation 118 of the input list.

That is a much better progress indicator than CPU percentage.

### One thing I would not do

I would **not interrupt this run** based on the evidence so far.

It has already successfully completed the expensive 325.89-second input load and 185.68-second post-load snapshot, and Python is demonstrably still issuing disk reads.

The next major milestones should be:

```text
CERTIFIED_INPUT_ROUNDTRIP.json
BOUNDARY_CONTROLS.json

then terminal:
4/7 Executing retained M2.4, Wave A and G3 calculations...
```

Once you see that `4/7` line, this file-comparison phase is finished and PostgreSQL activity should return.

Run the progress block above and paste the output—especially the comparator scratch filename and the reference/subject file counts. That should tell us whether it is 10%, 50%, or nearly finished with this phase.
<!-- END_SOURCE_MESSAGE -->


<a id="m-cff0ea7f-3ee7-4cdf-99e9-67924aa23aed"></a>
## Andrew / user · C132-M00077

C132-M00077 · 2026-09-12T17:24:13.986000-04:00 · active path

Preceding visible parent: [C132-M00076](part-05.md#m-89c5a90d-ab7b-4c6f-bbe8-5cf86f613cc5)

<!-- BEGIN_SOURCE_MESSAGE -->
=== INPUT ROUNDTRIP PROGRESS ===

ReferenceInputFiles : 183
ReferenceInputGB    : 2.527
SubjectInputFiles   : 183
SubjectInputGB      : 2.527
RoundtripReceipt    : False


=== CURRENT COMPARATOR SCRATCH ===

LastWriteTime            Length Name
-------------            ------ ----
9/12/2026 4:50:30 PM 3956826112 input_62.sqlite


=== 10 LARGEST INPUT FILES ===

  GB Name
  -- ----
0.58 msbf_m1.application_ead_path_value.csv
0.45 msbf_m1.merchant_pos_daily_scenario.csv
0.29 msbf_m1.merchant_deposit_daily_scenario.csv
0.21 msbf_m12r1d.pbi_fact_decision_gate.csv
0.10 msbf_m1.unit_economics_component_value.csv
0.09 msbf_m1.merchant_pos_daily_base.csv
0.07 msbf_m1.integrated_risk_component_value.csv
0.06 msbf_m1.merchant_deposit_daily_base.csv
0.06 msbf_m12r1d.pbi_fact_offer_candidate.csv
0.05 msbf_m1.application_unit_economics_snapshot.csv
<!-- END_SOURCE_MESSAGE -->


<a id="m-8afd4c47-a51a-4bfd-aed9-8a9f2c083e2f"></a>
## Assistant · C132-M00078

C132-M00078 · 2026-09-12T17:24:18.211286-04:00 · active path

Preceding visible parent: [C132-M00077](part-05.md#m-cff0ea7f-3ee7-4cdf-99e9-67924aa23aed)

<!-- BEGIN_SOURCE_MESSAGE -->
That gives us a real progress marker: the comparator is on **input 63 of 183**, so about one-third through by relation count. I’m checking whether its ordering is size-heavy early or late so we can interpret that percentage more meaningfully.
<!-- END_SOURCE_MESSAGE -->


<a id="m-4f2fdbc7-adb0-4ed7-a451-7134848ef70b"></a>
## Assistant · C132-M00079

C132-M00079 · 2026-09-12T17:24:32.804516-04:00 · active path

Preceding visible parent: [C132-M00078](part-05.md#m-8afd4c47-a51a-4bfd-aed9-8a9f2c083e2f)

<!-- BEGIN_SOURCE_MESSAGE -->
This is actually reassuring. We now know **exactly what it is doing**, and I would **not interrupt it**.

`input_62.sqlite` corresponds to:

```text
msbf_m1.application_ead_path_value.csv
```

That is the **largest certified input file in the entire 183-file set**:

```text
CSV size:        ~0.58 GB
SQLite scratch:  ~3.96 GB
Position:        63rd of 183 inputs
```

So the runtime has completed the first 62 comparisons and is currently grinding through the single largest relation. That explains the unusual combination you observed:

```text
Python alive             YES
PostgreSQL session       NO
child process            NO
CPU                       very low
disk READ activity        continuing
disk WRITE activity       zero
scratch SQLite            ~3.96 GB
```

The comparator has already built that large SQLite scratch database. It is now doing read-heavy equality/key/multiplicity/hash checks against it. On your HDD, that can be dominated by random reads rather than CPU.

Your measured:

```text
2,780 read operations / 30 sec
10.86 MB read / 30 sec
```

is evidence that it is **actively reading the comparison database**. It is not sitting completely idle.

### Progress interpretation

By relation count:

```text
Completed:       62
Current:         63
Total:           183

Position ≈ 34%
```

But that understates progress in one important way: **you are currently on the largest relation in the entire input set**. Relation 62 is unusually expensive.

After this one, the immediate sequence goes to:

```text
63  application_exposure_recovery_loss_snapshot
64  application_integrated_risk_proxy_snapshot
65  application_liquidity_capacity_snapshot
66  application_module1_archive
67  application_module1_latest
68  application_module1_scenario_comparison
69  application_obligation_snapshot
...
```

Those are substantially smaller than `application_ead_path_value`.

There are some other large files later—such as the merchant POS/deposit histories—but the current relation is the largest individual input.

## Best live progress monitor

You can leave the first PowerShell untouched and run this in the second window. It does nothing but report the current comparator scratch file every 60 seconds:

```powershell
$RunRoot = 'D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc'
$PidToWatch = 5064

for ($i = 1; $i -le 30; $i++) {

    $Scratch = Get-ChildItem "$RunRoot\temp\input_*.sqlite" `
        -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    $Proc = Get-Process -Id $PidToWatch -ErrorAction SilentlyContinue

    $RoundtripDone = Test-Path `
        "$RunRoot\evidence\CERTIFIED_INPUT_ROUNDTRIP.json"

    [pscustomobject]@{
        Time          = Get-Date
        PythonAlive   = ($null -ne $Proc)
        CPUSeconds    = if ($Proc) {[math]::Round($Proc.CPU,1)} else {$null}
        CurrentInput  = if ($Scratch) {$Scratch.BaseName} else {'none'}
        ScratchGB     = if ($Scratch) {[math]::Round($Scratch.Length / 1GB,2)} else {$null}
        RoundtripDone = $RoundtripDone
    } | Format-Table -AutoSize

    if ($RoundtripDone -or -not $Proc) {
        break
    }

    Start-Sleep -Seconds 60
}
```

The key event we want to see is:

```text
input_62
    ↓
input_63
```

That proves the largest comparison finished.

Eventually the scratch input files will finish and this should appear:

```text
evidence\CERTIFIED_INPUT_ROUNDTRIP.json
```

Then the runtime advances to boundary controls and subsequently back into database execution.

### One storage observation

The 3.96 GB scratch database is on:

```text
D:\MSBF_CAMPAIGNS\...
```

which is exactly what we wanted given the roughly 5.53 GB remaining on C:. So this run is also confirming that the D:-resident temporary-work design is working correctly.

**Current disposition: ACTIVE — LARGE INPUT COMPARISON IN PROGRESS.**

I would leave PID 5064 running. Nothing you've shown indicates a hang.
<!-- END_SOURCE_MESSAGE -->


<a id="m-9e3be298-aa27-4666-8cac-f07f8c59b7b6"></a>
## Andrew / user · C132-M00080

C132-M00080 · 2026-09-12T17:38:05.424000-04:00 · active path

Preceding visible parent: [C132-M00079](part-05.md#m-4f2fdbc7-adb0-4ed7-a451-7134848ef70b)

<!-- BEGIN_SOURCE_MESSAGE -->
Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:25:36 PM        True     780.00 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:26:37 PM        True     780.20 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:27:37 PM        True     780.30 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:28:37 PM        True     780.40 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:29:37 PM        True     780.60 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:30:37 PM        True     780.70 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:31:37 PM        True     780.90 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:32:37 PM        True     781.00 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:33:37 PM        True     781.10 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:34:37 PM        True     781.30 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:35:37 PM        True     781.40 input_62          3.69         False


Time                 PythonAlive CPUSeconds CurrentInput ScratchGB RoundtripDone
----                 ----------- ---------- ------------ --------- -------------
9/12/2026 5:36:37 PM        True     781.50 input_62          3.69         False
<!-- END_SOURCE_MESSAGE -->


<a id="m-77545c2a-73b6-42bd-850e-326456c46af4"></a>
## Assistant · C132-M00081

C132-M00081 · 2026-09-12T17:38:09.241657-04:00 · active path

Preceding visible parent: [C132-M00080](part-05.md#m-9e3be298-aa27-4666-8cac-f07f8c59b7b6)

<!-- BEGIN_SOURCE_MESSAGE -->
This still does **not prove a hang**, but it does justify closer scrutiny.

Over roughly 11 minutes:

```text
Python CPU: 780.0 → 781.5 seconds
Scratch:    input_62.sqlite throughout
Size:       ~3.69 GB throughout
```

The static scratch size is expected while SQLite is reading it. The more important question is whether the process is **still performing disk reads**. Earlier it was reading about 10.9 MB every 30 seconds. If that continues, the comparator is alive but extremely I/O-bound on this large SQLite comparison.

Run this stronger 60-second check:

```powershell
$PidToWatch = 5064

function Get-IO {
    $p = Get-CimInstance Win32_Process -Filter "ProcessId=$PidToWatch"
    [pscustomobject]@{
        Time       = Get-Date
        ReadOps    = [uint64]$p.ReadOperationCount
        WriteOps   = [uint64]$p.WriteOperationCount
        ReadBytes  = [uint64]$p.ReadTransferCount
        WriteBytes = [uint64]$p.WriteTransferCount
    }
}

$a = Get-IO
Start-Sleep -Seconds 60
$b = Get-IO

[pscustomobject]@{
    Seconds       = 60
    ReadOpsDelta  = $b.ReadOps - $a.ReadOps
    ReadMBDelta   = [math]::Round(($b.ReadBytes - $a.ReadBytes) / 1MB, 2)
    WriteOpsDelta = $b.WriteOps - $a.WriteOps
    WriteMBDelta  = [math]::Round(($b.WriteBytes - $a.WriteBytes) / 1MB, 2)
} | Format-List
```

### My decision rule now

If you get something like:

```text
ReadOpsDelta > 0
ReadMBDelta  materially > 0
```

then **leave it running**. It is still traversing `input_62.sqlite`, even though progress is painfully slow.

If instead you get:

```text
ReadOpsDelta  = 0
ReadMBDelta   = 0
WriteOpsDelta = 0
WriteMBDelta  = 0
```

for a full minute, while:

```text
PythonAlive = True
no child process
no PostgreSQL session
input_62.sqlite unchanged
```

then I would consider it genuinely suspicious.

There is also a broader engineering finding here regardless of whether it finishes: **this comparator is too inefficient for the eventual reusable campaign runtime.** A 0.58-GB CSV expanding into a ~3.7-GB temporary SQLite database and then spending this long on one of 183 inputs is not consistent with the simple, efficient future-user experience we just made a governing requirement.

So I would separate two questions:

```text
Current run:
Is it still progressing?        → determine from I/O counters

Runtime architecture:
Is this comparison approach acceptable long term?
                               → probably NO; it needs optimization
```

Do **not** interrupt PID 5064 yet. Give me the 60-second I/O delta first.
<!-- END_SOURCE_MESSAGE -->


<a id="m-86471027-0b3e-49be-9910-34fea0dd604e"></a>
## Andrew / user · C132-M00082

C132-M00082 · 2026-09-12T17:40:48.076000-04:00 · active path

Preceding visible parent: [C132-M00081](part-05.md#m-77545c2a-73b6-42bd-850e-326456c46af4)

<!-- BEGIN_SOURCE_MESSAGE -->
Seconds       : 60
ReadOpsDelta  : 6058
ReadMBDelta   : 23.66
WriteOpsDelta : 0
WriteMBDelta  : 0
<!-- END_SOURCE_MESSAGE -->


<a id="m-82bdce3f-bca5-40a6-b3be-e8b71792339e"></a>
## Assistant · C132-M00083

C132-M00083 · 2026-09-12T17:40:52.367430-04:00 · active path

Preceding visible parent: [C132-M00082](part-05.md#m-86471027-0b3e-49be-9910-34fea0dd604e)

<!-- BEGIN_SOURCE_MESSAGE -->
That confirms it: **the process is still actively progressing**.

Over 60 seconds it performed:

```text
ReadOpsDelta  = 6,058
ReadMBDelta   = 23.66 MB
WriteOpsDelta = 0
```

So `input_62.sqlite` is not frozen. Python is continuously reading from it. Given the current phase, that is consistent with the comparator scanning/querying the large scratch database.

My recommendation is:

> **Leave the current run alone. Do not interrupt it.**

The current state is best classified as:

```text
ACTIVE
I/O-BOUND
LARGE INPUT COMPARISON IN PROGRESS
NOT HUNG
```

The larger engineering finding remains important, though: this comparison method is too slow and storage-heavy for the eventual reusable campaign runtime. A ~0.58 GB CSV expanding into a ~3.7 GB SQLite scratch file and taking this long on one relation is acceptable as a first qualification mechanism, but **not** as the final user-facing architecture.

For this run, however, it is doing exactly what it was designed to do. The next clear progress milestone is when the scratch file changes from:

```text
input_62.sqlite
```

to:

```text
input_63.sqlite
```

or later, and ultimately when:

```text
evidence\CERTIFIED_INPUT_ROUNDTRIP.json
```

appears.

You can keep the 60-second monitor running. There is no need to send every interval unless one of these happens:

- the current input number advances;
- `RoundtripDone` becomes `True`;
- Python exits;
- disk reads drop to zero for several consecutive checks;
- a new error appears in the first PowerShell window.

At this point, **the right move is to let it continue**.
<!-- END_SOURCE_MESSAGE -->


<a id="m-23aad692-54f2-436a-a7de-ab5f10446bc3"></a>
## Andrew / user · C132-M00084

C132-M00084 · 2026-09-12T17:47:11.394000-04:00 · active path

Preceding visible parent: [C132-M00083](part-05.md#m-82bdce3f-bca5-40a6-b3be-e8b71792339e)

<!-- BEGIN_SOURCE_MESSAGE -->
how will we adapt for the go-forward user interface? is this something users will have to do everytime? above all, accuracy, but user ease and efficiency are also top priorities.
<!-- END_SOURCE_MESSAGE -->


<a id="m-65959296-10a1-46a5-b3bc-e831ca8a9f36"></a>
## Assistant · C132-M00085

C132-M00085 · 2026-09-12T17:47:15.412726-04:00 · active path

Preceding visible parent: [C132-M00084](part-05.md#m-23aad692-54f2-436a-a7de-ab5f10446bc3)

<!-- BEGIN_SOURCE_MESSAGE -->
No. **Users should not have to do this every time.** What you are watching now is qualification instrumentation, not the intended steady-state user experience.

The architecture should deliberately separate three modes:

| Mode | Purpose | Expected user burden |
|---|---|---|
| **Certification mode** | Prove the runtime matches accepted reference behavior | Heavy comparison/evidence allowed |
| **Standard campaign mode** | Run normal campaigns accurately and efficiently | Simple, mostly automated |
| **Deep audit mode** | Investigate or independently validate a run | Optional, evidence-heavy |

The mistake would be to make the current 183-file, multi-gigabyte SQLite comparison path part of every normal campaign. That would satisfy rigor at the expense of usability and scale.

For go-forward users, I would target something like:

```text
msbf setup
```

once, then:

```text
msbf run --population-size 2500 --seed 12345 --business-date 2026-07-23
```

and finally:

```text
msbf review <run-id>
```

Underneath, the runtime should still do the important controls automatically: configuration validation, source availability, row/cardinality checks, lineage checks, stage completion, financial/control reconciliation, G3/source certification, and fail-closed handling. Those are **accuracy controls** and should stay in every run.

What should *not* happen every time is full known-answer certification against Reference R1. That belongs mainly in the 750 certification profile, release qualification, or explicit `--validation reference-certification` mode.

For ordinary campaigns, the runtime should instead validate internal correctness and consistency. Think:

```text
normal run
    → generate/load inputs
    → validate contracts
    → execute MSBF logic
    → validate lineage
    → reconcile financial/control totals
    → certify stage completion
    → produce results
```

rather than:

```text
normal run
    → compare 183 tables row-by-row to an old campaign
```

That second pattern only makes sense for regression certification.

There is also a clear performance lesson from this first qualification run. The current comparator is accurate, but it is inefficient. For future certification runs I would replace the “CSV → temporary SQLite → row multiset comparison” path for large surfaces with a more scalable hierarchy:

```text
1. exact cardinality
2. key/multiplicity validation
3. canonical aggregate fingerprints
4. partitioned semantic hashes
5. targeted row-level drilldown only on mismatching partitions
```

That preserves rigor while avoiding a 0.58 GB file turning into a ~3.7 GB scratch database and spending a long time on one table.

For especially large deterministic tables, a partitioned hash scheme is better:

```text
business-key range / hash bucket
    → row count
    → semantic hash
```

If every bucket matches, we have very strong evidence of equality. If one bucket differs, only that partition gets expanded into detailed row comparison.

That is much closer to how I would design a reusable validation engine.

The public-facing result should also be much simpler than the current engineering return. A normal user should see something like:

```text
Campaign: MSBF_20260912_001
Population: 2,500
Seed: 12345
Status: PASS

Inputs validated: PASS
MSBF stages completed: PASS
Lineage: PASS
Financial reconciliation: PASS
Source certification: PASS

Elapsed time: 18m 42s
Results: D:\MSBF_CAMPAIGNS\runs\MSBF_20260912_001
```

Then detailed logs, hashes, SQL evidence, and manifests sit underneath for anyone who wants them.

So I would preserve this principle going forward:

> **Accuracy controls are always on. Heavy reference-certification controls are optional by mode.**

And I would make efficiency a formal runtime requirement alongside correctness. The same engine should support:

```text
validation_mode = standard
validation_mode = reference_certification
validation_mode = deep_audit
```

without changing the MSBF business logic itself.

The current 750 run is helping us qualify the logic **and** exposing exactly where the validation framework needs optimization before we call the runtime user-ready. That is useful evidence, not the final UX.
<!-- END_SOURCE_MESSAGE -->


<a id="m-3d18920b-da10-4b15-974f-1d099de45234"></a>
## Andrew / user · C132-M00086

C132-M00086 · 2026-09-12T17:53:17.630000-04:00 · active path

Preceding visible parent: [C132-M00085](part-05.md#m-65959296-10a1-46a5-b3bc-e831ca8a9f36)

<!-- BEGIN_SOURCE_MESSAGE -->
unfortunately, my computer tried to restart and closed my powershell...now what to do?
<!-- END_SOURCE_MESSAGE -->


<a id="m-bad60c75-45f5-442a-9854-95f96de1965c"></a>
## Assistant · C132-M00087

C132-M00087 · 2026-09-12T17:53:24.331297-04:00 · active path

Preceding visible parent: [C132-M00086](part-05.md#m-3d18920b-da10-4b15-974f-1d099de45234)

<!-- BEGIN_SOURCE_MESSAGE -->
First, **do not delete the existing run workspace and do not rerun the package yet**. Because PowerShell closed unexpectedly, we need to determine whether the underlying Python process survived and, if not, preserve the interrupted run before deciding whether to resume or restart.

Open a new PowerShell window and run this read-only check:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$RunRoot = 'D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T195609Z_2d929bcc'

Write-Host "`n=== HYBRID750 PYTHON PROCESS ==="
Get-CimInstance Win32_Process |
    Where-Object {
        $_.Name -match '^python.*\.exe$' -and
        $_.CommandLine -match 'HYBRID750|msbf\.py'
    } |
    Select-Object ProcessId, ParentProcessId, CreationDate, CommandLine |
    Format-List

Write-Host "`n=== RETURN / RECEIPT STATUS ==="
@(
    'evidence\CERTIFIED_INPUT_ROUNDTRIP.json',
    'evidence\BOUNDARY_CONTROLS.json',
    'evidence\STAGES.json',
    'evidence\WAVE_A_RESULT.json',
    'evidence\G3_RESULT.json',
    'evidence\CERTIFICATION_COMPARISON.json',
    'CAMPAIGN_SUMMARY.json',
    'RUN_RECEIPT.json',
    'RETURN_MANIFEST.csv',
    'RETURN_SHA256SUMS.txt'
) | ForEach-Object {
    $p = Join-Path $RunRoot $_
    [pscustomobject]@{
        Exists = Test-Path -LiteralPath $p
        Bytes  = if (Test-Path -LiteralPath $p) { (Get-Item $p).Length } else { $null }
        File   = $_
    }
} | Format-Table -AutoSize

Write-Host "`n=== COMPARATOR SCRATCH ==="
Get-ChildItem "$RunRoot\temp\input_*.sqlite" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object LastWriteTime,
        @{N='GB';E={[math]::Round($_.Length / 1GB,2)}},
        Name |
    Format-Table -AutoSize

Write-Host "`n=== LAST 15 PROCESS RECEIPTS ==="
Get-ChildItem "$RunRoot\logs\*.process.json" -ErrorAction SilentlyContinue |
    Sort-Object Name |
    Select-Object -Last 15 |
    ForEach-Object {
        $j = Get-Content $_.FullName -Raw | ConvertFrom-Json
        [pscustomobject]@{
            Receipt = $_.Name
            Label   = $j.label
            Exit    = $j.exit_code
            Seconds = $j.elapsed_seconds
        }
    } | Format-Table -AutoSize

Write-Host "`n=== EXISTING RETURN ZIP ==="
Get-ChildItem 'D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_*_RETURN.zip' `
    -ErrorAction SilentlyContinue |
    Select-Object Length, CreationTime, LastWriteTime, FullName |
    Format-List
```

There are three likely cases.

If the Python process is **still present**, then closing PowerShell did not kill the actual runtime. In that case, leave it alone and we can reconnect observationally just as before.

If the Python process is **gone** and there is already a `_RETURN.zip` or `RUN_RECEIPT.json`, the runtime may have handled the termination cleanly enough to produce evidence. We inspect that return and do **not** rerun yet.

If Python is gone and there is **no return package**, then the run was externally interrupted. Based on where it was immediately before interruption, it had already completed:

```text
subject creation
certified input loading
schema installation
post-load subject snapshot
no-output-hydration validation
```

and was in the 183-relation `CERTIFIED_INPUT_ROUNDTRIP` comparison, around `input_62.sqlite`.

That means the interruption did **not** occur during M2.4/Wave A/G3 business execution. So this is an infrastructure interruption, not a logical failure of MSBF.

### Important

Do **not** manually resume from `input_62.sqlite`. That scratch SQLite database is temporary comparison state, not a governed campaign checkpoint.

Also do not:

```text
delete the subject database
delete the run directory
delete input_62.sqlite
rerun the existing command immediately
restore Reference R1
restart the old R4/R5/R6 wrappers
```

If the process died without producing a return, my likely recommendation will be to preserve this run as an **externally interrupted qualification attempt** and start a clean second qualification run with a new run ID. But I want to see the exact state first, because the runtime may have survived the PowerShell closure.

Paste the output of that block.
<!-- END_SOURCE_MESSAGE -->


<a id="m-e8a03174-9c8d-4e42-b827-21231f737598"></a>
## Andrew / user · C132-M00088

C132-M00088 · 2026-09-12T17:54:32.238000-04:00 · active path

Preceding visible parent: [C132-M00087](part-05.md#m-bad60c75-45f5-442a-9854-95f96de1965c)

<!-- BEGIN_SOURCE_MESSAGE -->
=== HYBRID750 PYTHON PROCESS ===

=== RETURN / RECEIPT STATUS ===

Exists Bytes File
------ ----- ----
 False       evidence\CERTIFIED_INPUT_ROUNDTRIP.json
 False       evidence\BOUNDARY_CONTROLS.json
 False       evidence\STAGES.json
 False       evidence\WAVE_A_RESULT.json
 False       evidence\G3_RESULT.json
 False       evidence\CERTIFICATION_COMPARISON.json
 False       CAMPAIGN_SUMMARY.json
 False       RUN_RECEIPT.json
 False       RETURN_MANIFEST.csv
 False       RETURN_SHA256SUMS.txt


=== COMPARATOR SCRATCH ===

LastWriteTime          GB Name
-------------          -- ----
9/12/2026 4:50:30 PM 3.69 input_62.sqlite


=== LAST 15 PROCESS RECEIPTS ===

Receipt                                     Label                    Exit Seconds
-------                                     -----                    ---- -------
00017_read_scalar.process.json              read_scalar                 0    0.15
00018_read_scalar.process.json              read_scalar                 0   44.23
00019_read_scalar.process.json              read_scalar                 0    1.44
00020_schema_pre-data.process.json          schema_pre-data             0    1.31
00021_schema_post-data.process.json         schema_post-data            0    0.95
00022_read_only_snapshot.process.json       read_only_snapshot          0  217.58
00023_read_scalar.process.json              read_scalar                 0    0.42
00024_read_scalar.process.json              read_scalar                 0    0.22
00025_create_new_subject.process.json       create_new_subject          0    2.49
00026_read_scalar.process.json              read_scalar                 0    0.33
00027_install_schema_pre_data.process.json  install_schema_pre_data     0    2.42
00028_load_certified_inputs.process.json    load_certified_inputs       0  325.89
00029_install_schema_post_data.process.json install_schema_post_data    0   34.90
00030_read_scalar.process.json              read_scalar                 0    0.65
00031_read_only_snapshot.process.json       read_only_snapshot          0  185.68


=== EXISTING RETURN ZIP ===
<!-- END_SOURCE_MESSAGE -->


<a id="m-f0c139ae-bb9c-4778-9f0d-4b0986bc6271"></a>
## Assistant · C132-M00089

C132-M00089 · 2026-09-12T17:54:36.085301-04:00 · active path

Preceding visible parent: [C132-M00088](part-05.md#m-e8a03174-9c8d-4e42-b827-21231f737598)

<!-- BEGIN_SOURCE_MESSAGE -->
The run is definitively dead, and it died **before any M2.4/Wave A/G3 business execution**. I would preserve this as an infrastructure interruption and avoid rerunning R1 unchanged; the 183-file SQLite comparator is now a proven usability/performance defect.
<!-- END_SOURCE_MESSAGE -->


<a id="m-d882430d-c3bd-4370-afb9-aa65afad1011"></a>
## Assistant · C132-M00090

C132-M00090 · 2026-09-12T17:54:53.755228-04:00 · active path

Preceding visible parent: [C132-M00089](part-05.md#m-f0c139ae-bb9c-4778-9f0d-4b0986bc6271)

<!-- BEGIN_SOURCE_MESSAGE -->
This confirms the clean boundary: **R1 was externally interrupted during input certification, before any downstream business stage ran.** I’m going to treat R1 as preserved evidence and replace the slow comparator rather than make you repeat the same multi-hour path unchanged.
<!-- END_SOURCE_MESSAGE -->


<a id="m-5f0c33f9-e8f1-41b7-868c-a10a3427f0c8"></a>
## Assistant · C132-M00091

C132-M00091 · 2026-09-12T17:55:27.179210-04:00 · active path

Preceding visible parent: [C132-M00090](part-05.md#m-d882430d-c3bd-4370-afb9-aa65afad1011)

<!-- BEGIN_SOURCE_MESSAGE -->
I’m going to make the interruption productive: R2 will use **byte-exact fast paths first**, fall back to the existing semantic comparator only when bytes differ, and emit per-relation progress receipts. That preserves accuracy while removing the worst multi-gigabyte SQLite behavior from ordinary equality cases.
<!-- END_SOURCE_MESSAGE -->


<a id="m-6e52fa24-884a-49a9-be42-50829c692235"></a>
## Assistant · C132-M00092

C132-M00092 · 2026-09-12T17:58:27.436046-04:00 · active path

Preceding visible parent: [C132-M00091](part-05.md#m-5f0c33f9-e8f1-41b7-868c-a10a3427f0c8)

<!-- BEGIN_SOURCE_MESSAGE -->
We now have a clean disposition and a better path forward.

The interrupted R1 run should be classified as:

```text
EXTERNALLY_INTERRUPTED
phase = CERTIFIED_INPUT_ROUNDTRIP
subject_created = YES
certified_inputs_loaded = YES
tested_outputs_hydrated = NO
M2.4 executed = NO
Wave A executed = NO
G3 executed = NO
certification_result = NOT REACHED
```

So this was **not** an MSBF logic failure. It was an operating-system interruption during a validation phase.

More importantly, I do **not** recommend rerunning R1 unchanged. The interruption exposed a real engineering defect in the qualification UX: byte-identical files were being expanded into multi-gigabyte SQLite scratch databases before equality was established.

I corrected that in R2.

## R2 change

The comparison engine now uses this hierarchy:

```text
reference file + subject file
        ↓
same size?
        ↓
same SHA-256?
        ↓ YES
validate schema + keys
        ↓
BYTE_EXACT PASS
        ↓
NO SQLite scratch database
```

Only when the files are **not byte-identical** does it fall back to the original exact semantic comparator.

That is safe because byte equality is stronger than semantic equality. I did not change:

```text
MSBF business logic
replay boundary
certified-input allowlist
tested-output inventory
comparison contract
normalization rules
R4/M2.4/Wave A/G3 semantics
```

I also added visible per-input progress receipts so you will see:

```text
input roundtrip 1/183: ...
input roundtrip 2/183: ...
...
```

rather than wondering what the runtime is doing.

The regression suite is now **111/111 PASS**, including tests proving that the fast path still rejects null keys, duplicate keys, and illegal key exclusions.

### R2 package

Download R2 runtime (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912.zip`; referenced bytes not established here)

SHA-256 sidecar (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912.zip.sha256`; referenced bytes not established here)

Validation record (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912_VALIDATION.json`; referenced bytes not established here)

PowerShell run block (historical reference: `sandbox:[session]/MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912_RUN_BLOCK.txt`; referenced bytes not established here)

Package identity:

```text
MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912.zip

Bytes:
37,040,435

SHA-256:
dd56a4144e730030b15469411139aa080301c39bce02c299b2d904538e82fe48
```

## What to do with the interrupted R1 workspace

Leave these intact for now:

```text
D:\MSBF_CAMPAIGNS\PART2_RETURNS\
HYBRID750_20260912T195609Z_2d929bcc

and its subject database
```

Do **not** manually resume `input_62.sqlite`, and do not delete the R1 subject yet.

R2 will create a brand-new subject and run cleanly. Once R2 reaches a valid return, we can retire the interrupted R1 subject/workspace in a controlled cleanup step.

## Run R2

Save the ZIP under:

```text
D:\MSBF_ARCHIVE\
MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912.zip
```

Then run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912.zip'
$ExpectedSHA256 = 'dd56a4144e730030b15469411139aa080301c39bce02c299b2d904538e82fe48'
$Python = 'C:\Python314\python.exe'
$PgBin = 'C:\Program Files\PostgreSQL\17\bin'

if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) {
    throw "Package not found: $Zip"
}

$ObservedSHA256 = (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant()

if ($ObservedSHA256 -ne $ExpectedSHA256) {
    throw "Package SHA-256 mismatch. Nothing has been executed."
}

$Stamp = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
$ToolRoot = 'D:\MSBF_CAMPAIGNS\tools\HYBRID750_R2_' + $Stamp
$ScratchRoot = 'D:\MSBF_CAMPAIGNS\temp\HYBRID750_R2_LAUNCH_' + $Stamp

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
    Write-Warning 'Stopped. Retain the emitted RETURN.zip or error. Do not restore, edit the sealed contract, or advance to 2,500.'
}
```

One expectation change: **the input-certification phase should now be dramatically more efficient when the loaded subject inputs are byte-identical to the reference exports**. If any file differs at the byte level, R2 will automatically fall back to the slower semantic comparison for that file rather than compromising accuracy.

This is also the direction I want for the eventual user-facing runtime: **cheap deterministic checks first, expensive forensic comparison only when needed.**
<!-- END_SOURCE_MESSAGE -->


<a id="m-4aa0edcf-9771-4f62-ac8e-429c54a200fa"></a>
## Andrew / user · C132-M00093

C132-M00093 · 2026-09-12T18:06:26.900000-04:00 · active path

Preceding visible parent: [C132-M00092](part-05.md#m-6e52fa24-884a-49a9-be42-50829c692235)

**Editorial record note:** Attachment references: HYBRID750_20260912T220528Z_88d7672b_RETURN.zip.validation.json; HYBRID750_20260912T220528Z_88d7672b_RETURN.zip

<!-- BEGIN_SOURCE_MESSAGE -->
D:\MSBF_CAMPAIGNS\tools\HYBRID750_R2_20260912_180519_b9a2d03a\runtime\driver.py:221: SyntaxWarning: 'return' in a 'finally' block
  return 2
PostgreSQL password (not logged; Enter uses local trust/pgpass):
1/7 Binding package, published sources and certified input environment.
STOP: read_scalar exited 2; see D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T220528Z_88d7672b\logs\00010_read_scalar.stderr.log
6/7 Preserving evidence and checking the reference/source observations.
7/7 Writing return package; subject and local source snapshots are retained.

CAMPAIGN_STOPPED
RETURN PACKAGE: D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T220528Z_88d7672b_RETURN.zip
SHA256: aa449a7aaf445ce5f37ba2b104e399a61717673bf41f2ce0ffaaec885a382dd0
Scope: post-R4 accepted inputs through M2.4–M2.12/G3. No greenfield or fresh-2,500 certification.
WARNING: Stopped. Retain the emitted RETURN.zip or error. Do not restore, edit the sealed contract, or advance to 2,500.
<!-- END_SOURCE_MESSAGE -->


<a id="m-43727315-b72a-473f-815d-346046f3ebee"></a>
## Assistant · C132-M00094

C132-M00094 · 2026-09-12T18:06:29.146563-04:00 · active path

Preceding visible parent: [C132-M00093](part-05.md#m-4aa0edcf-9771-4f62-ac8e-429c54a200fa)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll inspect the stopped R2 return directly, identify the exact `read_scalar` failure, and determine whether this is an environment/binding issue or a defect in the new runtime package.
<!-- END_SOURCE_MESSAGE -->


<a id="m-a32f5549-2ce4-449a-9043-270e116e4d1d"></a>
## Assistant · C132-M00095

C132-M00095 · 2026-09-12T18:06:39.204631-04:00 · active path

Preceding visible parent: [C132-M00094](part-05.md#m-43727315-b72a-473f-815d-346046f3ebee)

<!-- BEGIN_SOURCE_MESSAGE -->
This one is straightforward. **R2 did not reach the new comparator or any campaign logic.** It stopped because Reference Environment R1 was not running after the computer restart.

The uploaded return is intact and explicitly records `CAMPAIGN_STOPPED`; its SHA-256 matches the terminal output. [export reference: filecite | turn12file0 | L2-L6]

The exact failure was:

```text
connection to server at "127.0.0.1", port 55432 failed:
Connection refused
```

And the return confirms:

```text
last_phase                = PACKAGE_BIND
subject_created           = false
subject_creation_attempted= false
M2.4 / Wave A / G3        = NOT RUN
failure_category          = INFRASTRUCTURE
```

So there is **no logical failure and no partial R2 subject to reconcile**. The restart simply killed the manually started isolated PostgreSQL process. That reference cluster is not a Windows auto-start service.

The `SyntaxWarning: 'return' in a 'finally' block` is a separate code-quality issue. It did **not** cause this stop. I want it cleaned up in a later runtime revision, but it does not justify changing the sealed comparison contract or blocking this rerun.

### 1. Start the existing Reference R1 cluster again

Run this in PowerShell:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$PgBin = 'C:\Program Files\PostgreSQL\17\bin'
$Data  = 'D:\MSBF_CAMPAIGNS\pg_clusters\msbf_cs_ref750_routeb_20260912_012713'
$LogDir = 'D:\MSBF_CAMPAIGNS\pg_logs'

New-Item -ItemType Directory -Force -Path $LogDir | Out-Null

$PgCtl     = Join-Path $PgBin 'pg_ctl.exe'
$PgIsReady = Join-Path $PgBin 'pg_isready.exe'

Write-Host "`nChecking Reference Environment R1..."
& $PgIsReady -h 127.0.0.1 -p 55432 -d msbf_restore_test

if ($LASTEXITCODE -ne 0) {

    & $PgCtl status -D $Data
    $StatusCode = $LASTEXITCODE

    if ($StatusCode -eq 0) {
        throw @'
STOP: pg_ctl reports the cluster is already running, but
127.0.0.1:55432 is unavailable.

Do not start a second copy or delete postmaster.pid.
'@
    }

    $StartLog = Join-Path $LogDir (
        'msbf_cs_ref750_routeb_start_' +
        (Get-Date -Format 'yyyyMMdd_HHmmss') +
        '.log'
    )

    Write-Host "Starting existing Reference R1..."
    Write-Host "Server log: $StartLog"

    & $PgCtl start `
        -D $Data `
        -l $StartLog `
        -W `
        -o "-p 55432 -h 127.0.0.1"

    if ($LASTEXITCODE -ne 0) {
        throw "Could not trigger PostgreSQL startup. Review $StartLog"
    }

    $Ready = $false

    for ($i = 1; $i -le 90; $i++) {
        Start-Sleep -Seconds 2

        & $PgIsReady `
            -h 127.0.0.1 `
            -p 55432 `
            -d msbf_restore_test *> $null

        if ($LASTEXITCODE -eq 0) {
            $Ready = $true
            break
        }
    }

    if (-not $Ready) {
        if (Test-Path $StartLog) {
            Get-Content $StartLog -Tail 80
        }
        throw 'Reference R1 did not become ready. Do not restore or rerun old wrappers.'
    }
}

Write-Host "`nFinal readiness:"
& $PgIsReady -h 127.0.0.1 -p 55432 -d msbf_restore_test

if ($LASTEXITCODE -ne 0) {
    throw 'Reference Environment R1 is unavailable.'
}

Write-Host "`nREFERENCE ENVIRONMENT R1 IS READY."
```

You should end with:

```text
127.0.0.1:55432 - accepting connections

REFERENCE ENVIRONMENT R1 IS READY.
```

### 2. Then rerun the same R2 package

There is **no need for R3 just because of this failure**. R2 never got far enough to test its changed comparator.

Use the same R2 package and hash:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$ErrorActionPreference = 'Stop'

$Zip = 'D:\MSBF_ARCHIVE\MSBF_HYBRID750_RUNTIME_QUALIFICATION_R2_20260912.zip'
$ExpectedSHA256 = 'dd56a4144e730030b15469411139aa080301c39bce02c299b2d904538e82fe48'
$Python = 'C:\Python314\python.exe'
$PgBin = 'C:\Program Files\PostgreSQL\17\bin'

if (-not (Test-Path -LiteralPath $Zip -PathType Leaf)) {
    throw "Package not found: $Zip"
}

$ObservedSHA256 = (Get-FileHash -LiteralPath $Zip -Algorithm SHA256).Hash.ToLowerInvariant()

if ($ObservedSHA256 -ne $ExpectedSHA256) {
    throw "Package SHA-256 mismatch. Nothing has been executed."
}

$Stamp = (Get-Date -Format 'yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8)
$ToolRoot = 'D:\MSBF_CAMPAIGNS\tools\HYBRID750_R2_' + $Stamp
$ScratchRoot = 'D:\MSBF_CAMPAIGNS\temp\HYBRID750_R2_LAUNCH_' + $Stamp

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
    Write-Warning 'Stopped. Retain the emitted RETURN.zip or error. Do not restore, edit the sealed contract, or advance to 2,500.'
}
```

### Disposition of this stopped return

Keep it. Its classification is useful:

```text
HYBRID750_20260912T220528Z_88d7672b

RESULT:
CAMPAIGN_STOPPED

FAILURE CATEGORY:
INFRASTRUCTURE

ROOT CAUSE:
Reference Environment R1 unavailable after machine restart

PUBLICATION BINDING:
PASS

SUBJECT CREATED:
NO

BUSINESS LOGIC EXECUTED:
NO

CERTIFICATION RESULT:
NOT REACHED
```

The bigger product lesson is also clear: **the final reusable user experience cannot depend on users remembering to manually restart this special reference cluster after Windows restarts.** Reference-certification mode should eventually perform a clean prerequisite check and give a concise actionable message—or setup should provide an easy managed start command. Standard future campaign mode should be even simpler.

For now, though, **start Reference R1 and rerun R2 unchanged**. This return did not invalidate R2.
<!-- END_SOURCE_MESSAGE -->


<a id="m-aeaee07c-b35a-4958-9e86-93f9de23e0f7"></a>
## Andrew / user · C132-M00096

C132-M00096 · 2026-09-12T20:40:22.043000-04:00 · active path

Preceding visible parent: [C132-M00095](part-05.md#m-a32f5549-2ce4-449a-9043-270e116e4d1d)

**Editorial record note:** Attachment references: HYBRID750_20260912T235231Z_7e43009e_RETURN.zip; HYBRID750_20260912T235231Z_7e43009e_RETURN.zip.validation.json

<!-- BEGIN_SOURCE_MESSAGE -->
D:\MSBF_CAMPAIGNS\tools\HYBRID750_R2_20260912_195228_c331c810\runtime\driver.py:221: SyntaxWarning: 'return' in a 'finally' block
  return 2
PostgreSQL password (not logged; Enter uses local trust/pgpass):
1/7 Binding package, published sources and certified input environment.
2/7 Exporting schema-only scaffolding and certified boundary inputs; reference stays read-only.
  read_only_snapshot: running (30 seconds elapsed)
  read_only_snapshot: running (60 seconds elapsed)
  read_only_snapshot: running (90 seconds elapsed)
  read_only_snapshot: running (120 seconds elapsed)
3/7 Creating separate template0 subject on D: and loading only allowed inputs.
  load_certified_inputs: running (30 seconds elapsed)
  load_certified_inputs: running (60 seconds elapsed)
  load_certified_inputs: running (90 seconds elapsed)
  load_certified_inputs: running (120 seconds elapsed)
  load_certified_inputs: running (150 seconds elapsed)
  load_certified_inputs: running (180 seconds elapsed)
  load_certified_inputs: running (210 seconds elapsed)
  load_certified_inputs: running (240 seconds elapsed)
  install_schema_post_data: running (30 seconds elapsed)
  read_only_snapshot: running (30 seconds elapsed)
  read_only_snapshot: running (60 seconds elapsed)
  read_only_snapshot: running (90 seconds elapsed)
  read_only_snapshot: running (120 seconds elapsed)
  read_only_snapshot: running (150 seconds elapsed)
    input roundtrip 1/183: msbf_ctl.acceptance_gate_result
    input roundtrip 2/183: msbf_ctl.comparison_registry
    input roundtrip 3/183: msbf_ctl.contract_registry
    input roundtrip 4/183: msbf_ctl.data_segregation_profile
    input roundtrip 5/183: msbf_ctl.disclosure_requirement
    input roundtrip 6/183: msbf_ctl.experiment_cell
    input roundtrip 7/183: msbf_ctl.experiment_registry
    input roundtrip 8/183: msbf_ctl.financial_crime_profile
    input roundtrip 9/183: msbf_ctl.jurisdiction_profile
    input roundtrip 10/183: msbf_ctl.m1_15_consumption_contract_registry
    input roundtrip 11/183: msbf_ctl.m1_16_acquisition_contract_registry
    input roundtrip 12/183: msbf_ctl.m1_17_end_to_end_evidence_snapshot
    input roundtrip 13/183: msbf_ctl.m1_17_g2_bundle_archive
    input roundtrip 14/183: msbf_ctl.m1_17_g2_bundle_latest
    input roundtrip 15/183: msbf_ctl.m1_17_g2_bundle_registry
    input roundtrip 16/183: msbf_ctl.m1_17_hash_chain_snapshot
    input roundtrip 17/183: msbf_ctl.m1_17_policy_profile
    input roundtrip 18/183: msbf_ctl.m2_1_policy_profile
    input roundtrip 19/183: msbf_ctl.m2_1_strategy_contract_registry
    input roundtrip 20/183: msbf_ctl.m2_2_policy_profile
    input roundtrip 21/183: msbf_ctl.m2_2_pricing_structure_contract_registry
    input roundtrip 22/183: msbf_ctl.m2_3_final_decision_contract_registry
    input roundtrip 23/183: msbf_ctl.m2_3_policy_profile
    input roundtrip 24/183: msbf_ctl.m2_4_policy_profile
    input roundtrip 25/183: msbf_ctl.operating_model_profile
    input roundtrip 26/183: msbf_ctl.parameter_definition
    input roundtrip 27/183: msbf_ctl.parameter_set
    input roundtrip 28/183: msbf_ctl.parameter_value
    input roundtrip 29/183: msbf_ctl.payment_data_scope_profile
    input roundtrip 30/183: msbf_ctl.permission_requirement
    input roundtrip 31/183: msbf_ctl.policy_profile
    input roundtrip 32/183: msbf_ctl.product_legal_structure_profile
    input roundtrip 33/183: msbf_ctl.profile_resolution_error
    input roundtrip 34/183: msbf_ctl.reason_code_catalog
    input roundtrip 35/183: msbf_ctl.record_retention_profile
    input roundtrip 36/183: msbf_ctl.regulatory_requirement
    input roundtrip 37/183: msbf_ctl.reporting_requirement
    input roundtrip 38/183: msbf_ctl.risk_appetite_limit
    input roundtrip 39/183: msbf_ctl.run_evidence
    input roundtrip 40/183: msbf_ctl.run_parameter_snapshot
    input roundtrip 41/183: msbf_ctl.run_profile_snapshot
    input roundtrip 42/183: msbf_ctl.run_registry
    input roundtrip 43/183: msbf_ctl.run_source_snapshot
    input roundtrip 44/183: msbf_ctl.scenario_registry
    input roundtrip 45/183: msbf_ctl.scenario_set
    input roundtrip 46/183: msbf_ctl.source_contract
    input roundtrip 47/183: msbf_ctl.source_reference
    input roundtrip 48/183: msbf_ctl.strategy_profile
    input roundtrip 49/183: msbf_ctl.third_party_relationship_profile
    input roundtrip 50/183: msbf_ctl.unsupported_feature_catalog
    input roundtrip 51/183: msbf_m1.acquisition_campaign_funnel_stage
    input roundtrip 52/183: msbf_m1.acquisition_cost_ledger
    input roundtrip 53/183: msbf_m1.acquisition_marketing_campaign
    input roundtrip 54/183: msbf_m1.acquisition_source_profile
    input roundtrip 55/183: msbf_m1.application_acquisition_attribution_snapshot
    input roundtrip 56/183: msbf_m1.application_acquisition_contract_archive
    input roundtrip 57/183: msbf_m1.application_acquisition_contract_latest
    input roundtrip 58/183: msbf_m1.application_acquisition_cost_component_value
    input roundtrip 59/183: msbf_m1.application_acquisition_cost_snapshot
    input roundtrip 60/183: msbf_m1.application_acquisition_touchpoint
    input roundtrip 61/183: msbf_m1.application_business_credit_snapshot
    input roundtrip 62/183: msbf_m1.application_cashflow_feature_snapshot
    input roundtrip 63/183: msbf_m1.application_ead_path_value
    input roundtrip 64/183: msbf_m1.application_exposure_recovery_loss_snapshot
    input roundtrip 65/183: msbf_m1.application_integrated_risk_proxy_snapshot
    input roundtrip 66/183: msbf_m1.application_liquidity_capacity_snapshot
    input roundtrip 67/183: msbf_m1.application_module1_archive
    input roundtrip 68/183: msbf_m1.application_module1_latest
    input roundtrip 69/183: msbf_m1.application_module1_scenario_comparison
    input roundtrip 70/183: msbf_m1.application_obligation_snapshot
    input roundtrip 71/183: msbf_m1.application_operating_resilience_snapshot
    input roundtrip 72/183: msbf_m1.application_owner_credit_snapshot
    input roundtrip 73/183: msbf_m1.application_unit_economics_snapshot
    input roundtrip 74/183: msbf_m1.application_verification_fraud_snapshot
    input roundtrip 75/183: msbf_m1.cashflow_feature_value
    input roundtrip 76/183: msbf_m1.collateral_availability_snapshot
    input roundtrip 77/183: msbf_m1.ead_path_snapshot
    input roundtrip 78/183: msbf_m1.feature_definition
    input roundtrip 79/183: msbf_m1.feature_value
    input roundtrip 80/183: msbf_m1.guarantee_availability_snapshot
    input roundtrip 81/183: msbf_m1.integrated_risk_component_value
    input roundtrip 82/183: msbf_m1.merchant_application
    input roundtrip 83/183: msbf_m1.merchant_deposit_daily_base
    input roundtrip 84/183: msbf_m1.merchant_deposit_daily_scenario
    input roundtrip 85/183: msbf_m1.merchant_feature_snapshot
    input roundtrip 86/183: msbf_m1.merchant_industry_assignment
    input roundtrip 87/183: msbf_m1.merchant_master
    input roundtrip 88/183: msbf_m1.merchant_owner_guarantor
    input roundtrip 89/183: msbf_m1.merchant_pos_daily_base
    input roundtrip 90/183: msbf_m1.merchant_pos_daily_scenario
    input roundtrip 91/183: msbf_m1.merchant_relationship_snapshot
    input roundtrip 92/183: msbf_m1.merchant_risk_snapshot
    input roundtrip 93/183: msbf_m1.module1_archive
    input roundtrip 94/183: msbf_m1.module1_latest
    input roundtrip 95/183: msbf_m1.operating_resilience_component_value
    input roundtrip 96/183: msbf_m1.partner_channel
    input roundtrip 97/183: msbf_m1.population_registry
    input roundtrip 98/183: msbf_m1.processor_account
    input roundtrip 99/183: msbf_m1.risk_component_detail
    input roundtrip 100/183: msbf_m1.source_snapshot
    input roundtrip 101/183: msbf_m1.unit_economics_component_value
    input roundtrip 102/183: msbf_m1.verification_result
    input roundtrip 103/183: msbf_m12r1a.decision_gate_result
    input roundtrip 104/183: msbf_m12r1a.feature_availability_explanation
    input roundtrip 105/183: msbf_m12r1a.final_decision_lineage
    input roundtrip 106/183: msbf_m12r1a.gate_rule
    input roundtrip 107/183: msbf_m12r1a.offer_candidate
    input roundtrip 108/183: msbf_m12r1a.strategy_parameter
    input roundtrip 109/183: msbf_m12r1a.strategy_parameter_set
    input roundtrip 110/183: msbf_m12r1b_p2a_r2.candidate_capacity_evaluation
    input roundtrip 111/183: msbf_m12r1b_p2a_r2.candidate_term
    input roundtrip 112/183: msbf_m12r1b_p2b.candidate_downstream_result
    input roundtrip 113/183: msbf_m12r1b_p2b.candidate_replay_map
    input roundtrip 114/183: msbf_m12r1b_p2b.candidate_support_classification
    input roundtrip 115/183: msbf_m12r1b_p2b.replay_capacity_calculation
    input roundtrip 116/183: msbf_m12r1b_p2b.replay_control
    input roundtrip 117/183: msbf_m12r1b_p2b.requested_structure_reproduction
    input roundtrip 118/183: msbf_m12r1b_p2b.source_snapshot_map
    input roundtrip 119/183: msbf_m12r1b_p2c_supp.candidate_capacity_evaluation
    input roundtrip 120/183: msbf_m12r1b_p2c_supp.candidate_downstream_result
    input roundtrip 121/183: msbf_m12r1b_p2c_supp.candidate_replay_map
    input roundtrip 122/183: msbf_m12r1b_p2c_supp.candidate_support_classification
    input roundtrip 123/183: msbf_m12r1b_p2c_supp.candidate_term
    input roundtrip 124/183: msbf_m12r1b_p2c_supp.replay_capacity_calculation
    input roundtrip 125/183: msbf_m12r1b_p2c_supp.replay_control
    input roundtrip 126/183: msbf_m12r1b_p2c_supp.requested_structure_reproduction
    input roundtrip 127/183: msbf_m12r1b_p2c_supp.source_snapshot_map
    input roundtrip 128/183: msbf_m12r1c.pbi_fact_application_scenario
    input roundtrip 129/183: msbf_m12r1c.pbi_fact_decision_gate
    input roundtrip 130/183: msbf_m12r1c.pbi_fact_feature_availability
    input roundtrip 131/183: msbf_m12r1c.pbi_fact_final_decision
    input roundtrip 132/183: msbf_m12r1c.pbi_fact_offer_candidate
    input roundtrip 133/183: msbf_m12r1c.runtime_metadata
    input roundtrip 134/183: msbf_m12r1d.pbi_fact_application_scenario
    input roundtrip 135/183: msbf_m12r1d.pbi_fact_decision_critical_feature_availability
    input roundtrip 136/183: msbf_m12r1d.pbi_fact_decision_gate
    input roundtrip 137/183: msbf_m12r1d.pbi_fact_final_decision
    input roundtrip 138/183: msbf_m12r1d.pbi_fact_no_feasible_structure_proof
    input roundtrip 139/183: msbf_m12r1d.pbi_fact_offer_candidate
    input roundtrip 140/183: msbf_m12r1d.runtime_metadata
    input roundtrip 141/183: msbf_m12r1e.application_final_offer_decision_compatibility
    input roundtrip 142/183: msbf_m12r1e.source_integration_registry
    input roundtrip 143/183: msbf_m2.application_eligibility_routing_archive
    input roundtrip 144/183: msbf_m2.application_eligibility_routing_latest
    input roundtrip 145/183: msbf_m2.application_eligibility_routing_snapshot
    input roundtrip 146/183: msbf_m2.application_final_decision_source_snapshot
    input roundtrip 147/183: msbf_m2.application_final_offer_decision_archive
    input roundtrip 148/183: msbf_m2.application_final_offer_decision_latest
    input roundtrip 149/183: msbf_m2.application_final_offer_decision_snapshot
    input roundtrip 150/183: msbf_m2.application_policy_gate_result
    input roundtrip 151/183: msbf_m2.application_pricing_structure_archive
    input roundtrip 152/183: msbf_m2.application_pricing_structure_candidate
    input roundtrip 153/183: msbf_m2.application_pricing_structure_latest
    input roundtrip 154/183: msbf_m2.application_pricing_structure_snapshot
    input roundtrip 155/183: msbf_m2.application_request_structure_archive
    input roundtrip 156/183: msbf_m2.application_request_structure_latest
    input roundtrip 157/183: msbf_m2.application_request_structure_snapshot
    input roundtrip 158/183: msbf_m2.booking_funding_activation_outcome_definition
    input roundtrip 159/183: msbf_m2.booking_funding_reason_definition
    input roundtrip 160/183: msbf_m2.external_notice_control_definition
    input roundtrip 161/183: msbf_m2.final_decision_outcome_definition
    input roundtrip 162/183: msbf_m2.final_decision_reason_definition
    input roundtrip 163/183: msbf_m2.policy_gate_definition
    input roundtrip 164/183: msbf_m2.pricing_structure_candidate_template
    input roundtrip 165/183: msbf_m2.pricing_structure_disposition_definition
    input roundtrip 166/183: msbf_m2.pricing_structure_reason_definition
    input roundtrip 167/183: msbf_m2.reason_code_definition
    input roundtrip 168/183: msbf_m2.routing_outcome_definition
    input roundtrip 169/183: msbf_ref.acceptance_gate_catalog
    input roundtrip 170/183: msbf_ref.acquisition_attribution_method
    input roundtrip 171/183: msbf_ref.acquisition_cost_basis
    input roundtrip 172/183: msbf_ref.acquisition_cost_component
    input roundtrip 173/183: msbf_ref.acquisition_cost_timing
    input roundtrip 174/183: msbf_ref.acquisition_funnel_stage
    input roundtrip 175/183: msbf_ref.acquisition_legacy_overlap_policy
    input roundtrip 176/183: msbf_ref.acquisition_source_family
    input roundtrip 177/183: msbf_ref.cashflow_archetype
    input roundtrip 178/183: msbf_ref.feature_family
    input roundtrip 179/183: msbf_ref.geography_region
    input roundtrip 180/183: msbf_ref.industry
    input roundtrip 181/183: msbf_ref.risk_component_code
    input roundtrip 182/183: msbf_ref.source_code
    input roundtrip 183/183: msbf_ref.verification_check_code
4/7 Executing retained M2.4, Wave A and G3 calculations on the subject.
  Executing M2.5 subject stage.
  stage_psql_M2_5: running (30 seconds elapsed)
  Executing M2.6 subject stage.
  Executing M2.7 subject stage.
  Executing M2.8 subject stage.
  Executing M2.9 subject stage.
  Executing M2.10 subject stage.
5/7 Comparing newly generated outputs against the sealed contract.
STOP: Sealed hybrid comparison found differences; no rules were widened
6/7 Preserving evidence and checking the reference/source observations.
  read_scalar: running (30 seconds elapsed)
  read_scalar: running (60 seconds elapsed)
  read_scalar: running (90 seconds elapsed)
  read_only_snapshot: running (30 seconds elapsed)
  read_only_snapshot: running (60 seconds elapsed)
  read_only_snapshot: running (90 seconds elapsed)
  read_only_snapshot: running (120 seconds elapsed)
  read_only_snapshot: running (150 seconds elapsed)
  read_only_snapshot: running (180 seconds elapsed)
  read_only_snapshot: running (210 seconds elapsed)
  read_only_snapshot: running (240 seconds elapsed)
7/7 Writing return package; subject and local source snapshots are retained.

CAMPAIGN_STOPPED
RETURN PACKAGE: D:\MSBF_CAMPAIGNS\PART2_RETURNS\HYBRID750_20260912T235231Z_7e43009e_RETURN.zip
SHA256: 0d8b8cae6f859863753fc2428ce8daeacdf1aad569c5be4eba014aa9a6090143
Scope: post-R4 accepted inputs through M2.4–M2.12/G3. No greenfield or fresh-2,500 certification.
WARNING: Stopped. Retain the emitted RETURN.zip or error. Do not restore, edit the sealed contract, or advance to 2,500.
<!-- END_SOURCE_MESSAGE -->


<a id="m-33c67db1-cc5e-4fcf-a50c-136fb59b1535"></a>
## Assistant · C132-M00097

C132-M00097 · 2026-09-12T20:40:42.388795-04:00 · active path

Preceding visible parent: [C132-M00096](part-05.md#m-aeaee07c-b35a-4958-9e86-93f9de23e0f7)

<!-- BEGIN_SOURCE_MESSAGE -->
I’ll inspect the comparison failures and retained evidence, separating genuine MSBF differences from lineage, runtime metadata, or comparison defects before recommending any changes or rerun.
<!-- END_SOURCE_MESSAGE -->


<a id="m-b9fa97b6-09ef-4f46-a831-3c9c73bcd5a7"></a>
## Assistant · C132-M00098

C132-M00098 · 2026-09-12T20:43:47.712307-04:00 · active path

Preceding visible parent: [C132-M00097](part-05.md#m-33c67db1-cc5e-4fcf-a50c-136fb59b1535)

<!-- BEGIN_SOURCE_MESSAGE -->
The failure is isolated: 84/85 relational surfaces passed, plus all Wave A and G3 comparisons. Only M2.4 `reviewed_at` differs; substantive fields and acceptance hash match.
<!-- END_SOURCE_MESSAGE -->
